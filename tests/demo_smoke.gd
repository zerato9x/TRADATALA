extends SceneTree
var failures: Array[String] = []
var checks := 0
var serial := 0

func _initialize() -> void:
	call_deferred("run")

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures.append(message)
		push_error(message)

func card(rank: int, suit := "Hearts") -> CardData:
	serial += 1
	return CardData.new("unlock_%d" % serial, str(rank), rank, suit, rank)

func run() -> void:
	check(DemoBuild.enabled(), "demo feature enabled")
	var progress := DrinkProgress.new("")
	for id: String in DrinkProgress.GOALS:
		check(progress.is_unlocked(id) == (id == DrinkCatalog.TRA_DA), "fresh lock: " + id)
	for id: String in DrinkProgress.GOALS:
		var goal: Array = DrinkProgress.GOALS[id]
		if int(goal[1]) == 0:
			continue
		progress.add_progress(goal[0], int(goal[1]) - 1)
		check(not progress.is_unlocked(id), "below threshold: " + id)
		progress.add_progress(goal[0])
		check(progress.is_unlocked(id), "threshold unlock: " + id)
		progress.add_progress(goal[0], 100)
		check(progress.counters[goal[0]] == goal[1], "progress capped: " + id)
	var save_path := "user://unlock-smoke-%d.cfg" % Time.get_ticks_usec()
	var saved := DrinkProgress.new(save_path)
	saved.add_progress("melds", 2)
	saved.add_progress("melds", 3)
	var restored := DrinkProgress.new(save_path)
	check(restored.is_unlocked(DrinkCatalog.NUOC_VOI), "progress persists after repeated saves and reload")
	DirAccess.remove_absolute(save_path)

	var action_progress := DrinkProgress.new("")
	var deal := DealState.new()
	deal.deck.reset(19)
	deal.state = DealState.STATE_FINAL_COMMIT_WINDOW
	deal.hand = [card(3), card(4), card(5), card(6), card(9, "Clubs")]
	var action_callback := func(result: Dictionary): action_progress.record_action(deal, result)
	deal.state_changed.connect(action_callback)
	var result := deal.create_meld([deal.hand[0], deal.hand[1], deal.hand[2]])
	check(result.ok, "real run creation succeeds")
	check(action_progress.counters.get("red_runs", 0) == 1, "real run increments red goal")
	action_progress.record_action(deal, result)
	check(action_progress.counters.get("red_runs", 0) == 1, "same meld cannot count twice")
	deal.extend_meld(result.meld_id, [deal.hand[0]])
	check(action_progress.counters.get("runs", 0) == 1, "extension does not count as new run")
	deal.set_current_drink(DrinkCatalog.NUOC_VOI)
	var meld := deal.get_meld(result.meld_id)
	deal.use_nuoc_voi(meld.meld_id, meld.cards[-1])
	check(action_progress.counters.get("nuoc_voi_returns", 0) == 1, "successful card recovery counts")
	deal.use_nuoc_voi(meld.meld_id, meld.cards[-1])
	check(action_progress.counters.get("nuoc_voi_returns", 0) == 1, "failed recovery does not count")
	deal.set_current_drink(DrinkCatalog.STING)
	deal.hand = [card(7), card(7, "Spades"), card(10)]
	deal.create_meld([deal.hand[0], deal.hand[1]], true)
	check(action_progress.counters.get("sting_pairs", 0) == 1, "Sting pair counts toward Bo Huc")
	check(action_progress.counters.get("sets", 0) == 0, "pair does not count toward natural set goal")
	deal.set_current_drink(DrinkCatalog.SAM_DUA)
	deal.current_phase = 1
	deal.state = DealState.STATE_PHASE_CHOICE
	deal.hand = [card(2), card(8), card(9)]
	deal.select_sam_dua_preserves([deal.hand[0], deal.hand[1]])
	check(action_progress.counters.get("sam_dua_preserved", 0) == 0, "selecting preserves does not grant progress")
	deal.choose_phase_two(false)
	check(action_progress.counters.get("sam_dua_preserved", 0) == 2, "actual DUMP preserves count")
	deal.current_phase = 1
	deal.state = DealState.STATE_PHASE_CHOICE
	deal.sam_dua_used = false
	deal.select_sam_dua_preserves([deal.hand[0]])
	deal.choose_phase_two(true)
	check(action_progress.counters.get("sam_dua_preserved", 0) == 2, "KEEP does not grant preserve progress")

	deal.state_changed.disconnect(action_callback)
	var events := EventManager.new()
	CampaignNpcCatalog.register_initial_npcs(events)
	check(events.npc_definitions.size() == 1, "only drink seller registered")
	var manager := DrinkManager.new()
	manager.progress = DrinkProgress.new("")
	manager.test_all_drinks_available = true
	manager.begin_event(0)
	check(not manager.select_for_event(0, DrinkCatalog.BO_HUC).ok, "test override cannot bypass demo locks")
	check(manager.empty_glasses.is_empty(), "rejected purchase creates no glass")
	manager.progress = progress
	for day in range(7):
		manager.day_target_vnd = 250_000 * (1 << day)
		for id: String in DrinkProgress.GOALS:
			check(manager.price_for(id) == int(manager.day_target_vnd * int(DrinkProgress.GOALS[id][2]) / 100), "scaled price day %d: %s" % [day, id])
	manager.day_target_vnd = 250_000
	check(not manager.select_for_event(0, DrinkCatalog.NUOC_VOI).ok, "unaffordable purchase rejected")
	manager.wallet.apply_vnd(50_000, "test")
	check(manager.select_for_event(0, DrinkCatalog.NUOC_VOI).ok, "unlocked affordable drink bought")
	check(manager.wallet.balance_vnd == 47_500, "exact Monday price deducted")
	check(not manager.select_for_event(0, DrinkCatalog.NUOC_VOI).ok, "one purchase per event")
	check(manager.wallet.balance_vnd == 47_500, "duplicate purchase cannot charge twice")
	manager.begin_event(1)
	check(manager.empty_glasses.is_empty(), "visiting optional shop does not retire drink")
	manager.select_for_event(1, DrinkCatalog.TRA_DA)
	check(manager.empty_glasses.size() == 1, "replacement adds one empty")
	manager.begin_event(2)
	check(manager.empty_glasses.size() == 2, "noon expiry adds one empty")
	manager.select_for_event(2, DrinkCatalog.TRA_DA)
	check(manager.empty_glasses.size() == 2, "buying after expiry does not duplicate empty")
	manager.clear_day()
	check(manager.empty_glasses.size() == 3, "day end adds final expired glass")
	manager.clear_day()
	check(manager.empty_glasses.size() == 3, "repeated clearing is idempotent")
	manager.begin_event(0)
	check(manager.empty_glasses.size() == 3, "next day retains glasses")
	manager.reset_run()
	check(manager.empty_glasses.is_empty(), "new run clears glasses")
	check(manager.progress.is_unlocked(DrinkCatalog.BO_HUC), "new run keeps unlocks")

	var campaign := CampaignManager.new(null, events)
	campaign.drink_manager.progress = DrinkProgress.new("")
	campaign.start_campaign()
	var deals := 0
	var event_count := 0
	var guard := 0
	while not campaign.campaign_complete and not campaign.run_failed and guard < 100:
		guard += 1
		if CampaignManager.EVENT_PHASE_TO_SLOT.has(campaign.current_phase):
			var event := events.current_event
			event_count += 1
			check(event.participants.size() == 1 and event.interactions.size() == 1, "seller in every event")
			check(event.can_exit == (event.slot in [1, 3]), "replacement visits optional")
			check(campaign.drink_manager.select_for_event(event.slot, DrinkCatalog.TRA_DA).ok, "purchase available each event")
			events.complete_interaction(event.interactions[0].id)
			campaign.complete_current_event()
		elif campaign.current_phase == CampaignManager.CampaignPhase.MONEY_REQUIREMENT_CHECK:
			campaign.collect_day_debt()
		else:
			campaign.wallet.apply_vnd(campaign.daily_requirement(), "test")
			campaign.complete_deal()
			deals += 1
	check(campaign.campaign_complete and deals == 28 and event_count == 28, "28 events and deals through Sunday")
	check(campaign.drink_manager.empty_glasses.size() == 28, "all 28 servings remain as glasses")
	campaign.start_campaign()
	check(campaign.drink_manager.empty_glasses.is_empty(), "campaign reset clears glasses")
	for i in range(8):
		if CampaignManager.EVENT_PHASE_TO_SLOT.has(campaign.current_phase):
			for interaction in events.current_event.interactions:
				events.complete_interaction(interaction.id)
			campaign.complete_current_event()
		else:
			campaign.complete_deal()
	check(campaign.current_phase == CampaignManager.CampaignPhase.MONEY_REQUIREMENT_CHECK, "Monday waits for collection")
	campaign.collect_day_debt()
	check(campaign.run_failed, "Monday zero-wallet failure")

	root.get_node("GameSettings").set_music_system("authored_dj")
	var ui := load("res://scenes/match.tscn").instantiate() as MatchUI
	root.add_child(ui)
	await process_frame
	ui.drink_manager.progress = DrinkProgress.new("")
	ui._start_campaign()
	await create_timer(0.7).timeout
	check(not ui.relic_title_label.get_parent().visible, "relic panel hidden")
	ui.event_table.focus_npc(EventTableController.NPC_TRA_DA)
	await create_timer(0.5).timeout
	var shops := ui.campaign_participants.find_children("*", "DrinkShop", true, false)
	check(shops.size() == 1, "drink shop exists")
	if shops.size() == 1:
		var shop := shops[0] as DrinkShop
		check(shop._buttons.size() == 12, "shop shows all twelve drinks")
		shop.inspect_drink(DrinkCatalog.NUOC_VOI)
		check(shop.confirm.disabled and shop._goal_label.text.contains("0/5"), "locked drink explains progress and blocks purchase")
		shop.inspect_drink(DrinkCatalog.TRA_DA)
		check(not shop.confirm.disabled, "free starter drink order enabled")
	check(ui.music_controller.playlist.size() == 26, "full jukebox")
	check(ui.gameplay_music.active_set_id == "cat", "Cat authored default")
	ui._on_music_system_selected(0)
	check(not ui.gameplay_music.active, "jukebox switch stops authored routing")
	ui._on_campaign_day_started({})
	check(ui.settings.music_system == "playing_tracks", "jukebox mode survives day change")
	ui.campaign.current_phase = CampaignManager.CampaignPhase.MORNING_DEAL
	ui.tutorial_active = true
	ui._on_demo_progress_action({"ok": true, "action": "nhan_tran_swap"})
	check(ui.drink_manager.progress.counters.is_empty(), "tutorial grants no progress")
	ui.tutorial_active = false
	ui._on_demo_progress_action({"ok": true, "action": "nhan_tran_swap"})
	check(ui.drink_manager.progress.counters.get("nhan_tran_swaps") == 1, "campaign action hook records progress")
	ui.drink_manager.empty_glasses.assign([DrinkCatalog.TRA_DA, DrinkCatalog.NUOC_VOI])
	ui.deal.set_current_drink(DrinkCatalog.TRA_DA)
	ui._sync_drink_table_visual()
	ui._sync_drink_table_visual()
	check(ui.game_layer.get_node_or_null("EmptyGlasses") == null, "retired drinks never create accumulated cup visuals")
	check(ui.get_node_or_null("GameLayer/TableSurface/DrinkProps/EmptyDrinkProp") == null, "old drink cup is entirely removed")
	check(ui.drink_table_button.visible and ui.drink_table_texture.texture != null, "active drink remains visible")
	ui.drink_manager.clear_day()
	ui._sync_drink_table_visual()
	check(ui.game_layer.get_node_or_null("EmptyGlasses") == null, "day changes do not restore cup clutter")
	ui.drink_manager.reset_run()
	ui._sync_drink_table_visual()
	check(ui.game_layer.get_node_or_null("EmptyGlasses") == null, "new runs do not restore cup clutter")
	ui.settings.set_music_system("authored_dj")
	ui.queue_free()
	await process_frame
	print("DEMO_SMOKE: %s checks=%d failures=%d" % ["PASS" if failures.is_empty() else "FAIL", checks, failures.size()])
	quit(0 if failures.is_empty() else 1)
