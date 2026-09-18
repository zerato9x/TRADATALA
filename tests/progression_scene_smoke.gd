extends SceneTree
var failures: Array[String] = []
var scene: MatchUI
const SAVE := "user://progression_scene_test.save"
func _initialize() -> void:
	call_deferred("_run")
func check(value: bool, message: String) -> void:
	if not value:
		failures.append(message)
func pause(seconds: float = 0.8) -> void:
	await create_timer(seconds).timeout
func capture(label: String) -> void:
	if DisplayServer.get_name() != "headless":
		await RenderingServer.frame_post_draw
		var suffix := "-en" if OS.get_cmdline_user_args().has("--english") else ""
		root.get_texture().get_image().save_png("res://.godot/progression-%s%s.png" % [label, suffix])
func click(button: Button) -> void:
	var point := button.get_global_transform_with_canvas() * (button.size * 0.5)
	for down in [true, false]:
		var event := InputEventMouseButton.new()
		event.position = point
		event.button_index = MOUSE_BUTTON_LEFT
		event.pressed = down
		root.push_input(event, true)
	await pause(0.3)
func make_scene() -> void:
	scene = load("res://scenes/match.tscn").instantiate()
	root.add_child(scene)
	current_scene = scene
	await pause(0.1)
	var title := scene.get_node_or_null("TitleScreen")
	if title != null:
		title.queue_free()
	if OS.get_cmdline_user_args().has("--english"):
		TranslationServer.set_locale("en")
	scene.run_save = RunSave.new(SAVE)
	# Isolate the achievement profile too; these are test runs.
	scene.drink_manager.progress.save_path = ""
func _run() -> void:
	root.size = Vector2i(1280, 720)
	if OS.get_cmdline_user_args().has("--english"):
		root.size = Vector2i(1920, 1080)
		TranslationServer.set_locale("en")
	if OS.get_cmdline_user_args().has("--resume-only"):
		await make_scene()
		scene._show_run_menu()
		await pause()
		check(not scene._run_menu.resume_button.disabled, "fresh process detects save")
		await click(scene._run_menu.resume_button)
		await pause()
		check(scene.game_started and scene.campaign.endless, "fresh process restores endless")
		check(scene.campaign.current_day_index == 7 and scene.campaign.run_seed == "SIDEWALK-2026", "fresh process restores day and seed")
		check(scene.campaign.event_manager.current_event != null, "fresh process restores starter event")
		for failure in failures:
			push_error(failure)
		print("FRESH_PROCESS_RESUME: " + ("PASS" if failures.is_empty() else "FAIL"))
		scene.queue_free()
		await process_frame
		quit(0 if failures.is_empty() else 1)
		return
	for suffix in ["", ".bak", ".tmp"]:
		if FileAccess.file_exists(SAVE + suffix):
			DirAccess.remove_absolute(SAVE + suffix)
	await make_scene()
	scene._show_run_menu()
	await pause()
	scene._run_menu.seed_field.text = "SIDEWALK-2026"
	check(scene._run_menu.start_button.get_global_rect().end.y <= root.size.y, "seeded start button fits")
	await capture("seed-menu")
	await click(scene._run_menu.start_button)
	await pause(1.0)
	check(scene.campaign.run_seed == "SIDEWALK-2026", "pointer starts requested seed")
	check(scene.drink_manager.available_drink_ids() == [DrinkCatalog.TRA_DA], "day one starter only tea")
	check(scene.drink_manager.select_for_event(0, DrinkCatalog.TRA_DA).ok, "starter tea can be chosen")
	scene.event_manager.complete_interaction("choose_drink")
	scene.campaign.complete_current_event()
	await pause(1.0)
	scene.deal.discard_card(scene.deal.hand[0])
	scene._sync_all()
	await pause()
	var hand := scene.deal.hand.map(func(card): return card.unique_id)
	var stock := scene.deal.deck.draw_pile.map(func(card): return card.unique_id)
	var saved := scene.run_save.load_run()
	check(not saved.is_empty(), "committed action autosaved to disk")
	scene.queue_free()
	await pause(0.2)
	await make_scene()
	scene._show_run_menu()
	await pause(0.2)
	await click(scene._run_menu.resume_button)
	await pause(1.0)
	check(scene.game_started, "Continue button resumes disk save")
	check(scene.deal.hand.map(func(card): return card.unique_id) == hand, "resume preserves exact hand")
	check(scene.deal.deck.draw_pile.map(func(card): return card.unique_id) == stock, "resume preserves future draws")
	check(scene.deal.discard_count == 1, "resume preserves turn")
	check(not scene.interaction_locked, "resumed deal is actionable")
	await capture("resumed-deal")
	scene.deal.wallet.apply_vnd(50_000_000, "fixture")
	scene.campaign._enter_phase(CampaignManager.CampaignPhase.MORNING_EVENT)
	await pause()
	scene.event_table.focus_npc(EventTableController.NPC_HANG_RONG)
	await pause()
	var panel := scene.campaign_participants.get_child(0) as RelicSelector
	check(panel.buttons.size() == 3, "live shop shows exactly three offers")
	await capture("relic-offer")
	var old := scene.campaign.relic_shop.offers.duplicate()
	await click(panel.reroll_button)
	await pause(0.2)
	check(scene.campaign.relic_shop.rerolls == 1, "pointer rerolls once")
	check(scene.campaign.relic_shop.offers != old, "reroll replaces offer")
	var chosen := scene.campaign.relic_shop.offers[0]
	await click(panel.buttons[chosen])
	check(scene.campaign.relic_shop.purchased, "pointer buys one relic")
	check(scene.deal.relics.inventory.has(chosen), "bought relic is owned")
	check(scene.campaign.relic_shop.offers.is_empty(), "unchosen offers leave")
	await capture("relic-purchased")
	# Populate the victory scroll with a real scoring action and the week ledger.
	scene.deal.start_tutorial_deal()
	var cards: Array[CardData] = []
	for card in scene.deal.hand:
		if card.rank_index == 9:
			cards.append(card)
	scene.deal.create_meld(cards)
	scene.campaign.deal_reports.append({"day_id": "sunday", "details": scene.deal.accounting_report()})
	scene.campaign.current_day_index = 6
	scene.campaign.event_manager.current_event = null
	scene.deal.wallet.apply_vnd(50_000_000, "fixture")
	scene.campaign._finish_day()
	await pause()
	check(scene.campaign.collect_day_debt(), "Sunday debt is collected")
	await pause()
	check(scene.resolve_receipt.endless_button.visible, "victory offers endless")
	check(scene.resolve_receipt._page == "chronicle", "victory opens run scroll")
	check(scene.resolve_receipt.rows.find_children("*", "TextureRect", true, false).size() == 3, "victory shows three MVP cards")
	await capture("victory-scroll")
	scene.resolve_receipt._scroll.scroll_vertical = 235
	await pause(0.2)
	await capture("victory-mvps")
	scene.resolve_receipt._scroll.scroll_vertical = 2000
	await pause(0.2)
	await capture("victory-stats")
	await click(scene.resolve_receipt.endless_button)
	await pause()
	check(scene.campaign.endless and scene.campaign.current_day_index == 7, "pointer enters endless day eight")
	check(scene.campaign.daily_requirement() == 24_000_000, "endless goal appears")
	check(scene.campaign.run_seed == "SIDEWALK-2026", "endless retains seed")
	check(scene.event_table.focused_npc_id.is_empty(), "new endless event clears old NPC focus")
	check("8" in scene.event_table.day_label.text, "endless day number visible")
	await capture("endless")
	for failure in failures:
		push_error(failure)
	print("PROGRESSION_SCENE_SMOKE: " + ("PASS" if failures.is_empty() else "FAIL"))
	scene.queue_free()
	await process_frame
	quit(0 if failures.is_empty() else 1)
