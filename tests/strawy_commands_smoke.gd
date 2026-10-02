extends SceneTree
var ui: MatchUI
var checks := 0
var failures: Array[String] = []

func _initialize() -> void: call_deferred("_run")
func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok: failures.append(message); push_error(message)

func prepare(ids: Array[String]) -> void:
	ui.strawy.close()
	ui.deal.start_deal(789)
	var all: Array[CardData] = ui.deal.hand.duplicate()
	all.append_array(ui.deal.deck.draw_pile)
	ui.deal.hand.clear()
	ui.deal.deck.draw_pile.clear()
	for c in all:
		if ids.has(c.unique_id): ui.deal.hand.append(c)
		else: ui.deal.deck.draw_pile.append(c)
	ui.deal.hand.sort_custom(func(a,b): return a.unique_id < b.unique_id)
	ui.deal.set_current_drink(DrinkCatalog.TRA_DA)
	ui.interaction_locked = false
	ui._sync_all()

func helper_tap(emulated: bool = false, mouse_only: bool = false) -> void:
	await process_frame
	var point := ui.strawy.hit.get_global_transform_with_canvas() * (ui.strawy.hit.size * 0.5)
	if not mouse_only:
		for down in [true,false]:
			var touch := InputEventScreenTouch.new()
			touch.position = point
			touch.pressed = down
			root.push_input(touch,true)
	if emulated or mouse_only:
		for down in [true,false]:
			var mouse := InputEventMouseButton.new()
			mouse.device = 0 if mouse_only else -1
			mouse.position = point
			mouse.button_index = MOUSE_BUTTON_LEFT
			mouse.pressed = down
			root.push_input(mouse,true)

func native_command(button_name: String) -> void:
	ui.strawy.open_help()
	await process_frame
	await process_frame
	var button: Button = ui.strawy.box.find_child(button_name,true,false)
	var point := button.get_global_transform_with_canvas() * (button.size * 0.5)
	for down in [true,false]:
		var touch := InputEventScreenTouch.new()
		touch.position = point
		touch.pressed = down
		root.push_input(touch,true)
	for down in [true,false]:
		var mouse := InputEventMouseButton.new()
		mouse.device = -1
		mouse.position = point
		mouse.button_index = MOUSE_BUTTON_LEFT
		mouse.pressed = down
		root.push_input(mouse,true)

func _run() -> void:
	root.get_node("GameSettings").set_music_system("playing_tracks")
	ui = load("res://scenes/match.tscn").instantiate()
	root.add_child(ui)
	current_scene = ui
	await create_timer(0.3).timeout
	ui.run_save = RunSave.new("user://strawy-commands.save")
	ui.drink_manager.progress.save_path = ""
	var title := ui.get_node_or_null("TitleScreen")
	if title: title.queue_free()
	ui.game_started = true
	ui.game_layer.position = Vector2.ZERO
	ui.menu_layer.hide()
	ui._start_campaign()
	ui.current_campaign_event = null
	ui.event_table.hide()
	prepare(["standard_7_spades","standard_7_hearts","standard_7_diamonds","standard_k_clubs"])
	await native_command("StrawyPlay")
	await create_timer(0.2).timeout
	check(ui.deal.melds.size() == 1 and ui.deal.action_counts.new_meld == 1,"one request commits one Meld")
	# Keep the last seven as the only loose extension, retaining a discard card.
	var set: MeldState = ui.deal.melds[0]
	for c in ui.deal.deck.draw_pile.duplicate():
		if c.unique_id == "standard_7_clubs":
			ui.deal.deck.draw_pile.erase(c)
			ui.deal.hand.append(c)
	ui._sync_all()
	var seven: CardData
	for c in ui.deal.hand:
		if c.rank_index == 7: seven = c
	check(seven != null and ui.deal.hand_advice().play.action == HandAdvisor.ACTION_EXTENSION,"current recommendation is an Extend")
	var journal_before := ui.deal.wallet.journal.size()
	await native_command("StrawyPlay")
	await create_timer(0.2).timeout
	check(ui.deal.action_counts.get("extension",0) == 1 and set.cards.size() == 4,"one request commits one Extend")
	check(ui.deal.wallet.journal.size() > journal_before,"helper Extend uses ordinary wallet scoring")
	check(ui.deal.physical_card_accounting_is_valid(),"Meld and Extend retain physical cards")
	await create_timer(1.0).timeout
	prepare(["standard_7_spades","standard_7_hearts","standard_k_clubs"])
	ui.strawy._command("discard")
	await create_timer(0.2).timeout
	check(ui.deal.tra_da_extra_discard_pending,"mandatory discard leaves Trà Đá choice pending")
	check(ui.deal.hand_advice().extra_action == "skip","strong retained pair recommends Skip")
	var history := ui.deal.discard_history.size()
	ui.strawy._command("discard")
	await create_timer(0.2).timeout
	check(not ui.deal.tra_da_extra_discard_pending and ui.deal.discard_history.size() == history and ui.deal.hand.size() == 10,"separate helper request skips without inventing a discard")
	await create_timer(0.5).timeout
	prepare(["standard_7_spades","standard_7_hearts","standard_k_clubs","standard_q_clubs"])
	ui.strawy._command("discard")
	await create_timer(0.2).timeout
	check(ui.deal.hand_advice().extra_action == "discard","loose face card recommends extra discard")
	history = ui.deal.discard_history.size()
	ui.strawy._command("discard")
	await create_timer(0.2).timeout
	check(ui.deal.discard_history.size() == history+1 and ui.deal.discard_count == 1 and not ui.deal.tra_da_extra_discard_pending,"separate request performs exactly one optional discard")
	check(ui.deal.physical_card_accounting_is_valid(),"Trà Đá actions retain all physical cards")
	await create_timer(0.5).timeout
	prepare(["standard_7_spades","standard_7_hearts","standard_k_clubs"])
	var expected_id: String = ui.deal.hand_advice().discard_id
	await process_frame # Let the preceding fixture's deferred autosave finish.
	var preview_snapshot := var_to_str(ui.deal.snapshot_state())
	var preview_rng: int = ui.deal.deck._rng.state
	var save_before := FileAccess.get_file_as_bytes(ui.run_save.path)
	await helper_tap(true)
	await helper_tap(true)
	check(ui.strawy.quick_action == "discard" and ui.selected_card_ids.keys() == [expected_id],"double native tap selects exactly the recommended physical discard")
	check(ui.hand_views[expected_id].selected and not ui.strawy.box.visible and ui.strawy.tour.is_empty(),"double tap highlights the card without a menu or tour")
	check(var_to_str(ui.deal.snapshot_state()) == preview_snapshot and ui.deal.deck._rng.state == preview_rng,"double tap preview cannot commit cards, wallet, or RNG")
	check(FileAccess.get_file_as_bytes(ui.run_save.path) == save_before,"preview does not write a save")
	await create_timer(0.4).timeout
	check(ui.strawy.quick_action == "discard" and not ui.strawy.box.visible,"pending single-click timer cannot replace the preview")
	history = ui.deal.discard_history.size()
	await helper_tap(true)
	await create_timer(0.2).timeout
	check(ui.deal.discard_history.size() == history+1 and ui.deal.discard_history.back().card.unique_id == expected_id,"next native tap confirms the previewed card exactly once despite emulated mouse")
	check(ui.strawy.quick_action.is_empty(),"confirmation consumes the pending action")
	await helper_tap(true)
	await helper_tap(true)
	check(ui.strawy.quick_action == "skip" and ui.selected_card_ids.is_empty(),"Trà Đá preview recommends Skip without selecting another discard")
	history = ui.deal.discard_history.size()
	await helper_tap(true)
	await create_timer(0.2).timeout
	check(not ui.deal.tra_da_extra_discard_pending and ui.deal.discard_history.size() == history,"next tap confirms Skip once")
	prepare(["standard_7_spades","standard_7_hearts","standard_k_clubs","standard_q_clubs"])
	await helper_tap(false,true)
	await helper_tap(false,true)
	check(ui.strawy.quick_action == "discard","ordinary double mouse click also previews a discard")
	history = ui.deal.discard_history.size()
	await helper_tap(false,true)
	await create_timer(0.2).timeout
	check(ui.deal.discard_history.size() == history+1,"ordinary next mouse click confirms once")
	await helper_tap(false,true)
	await helper_tap(false,true)
	check(ui.strawy.quick_action == "discard","Trà Đá recomputes the optional extra discard preview")
	history = ui.deal.discard_history.size()
	await helper_tap(false,true)
	await create_timer(0.2).timeout
	check(ui.deal.discard_history.size() == history+1 and not ui.deal.tra_da_extra_discard_pending,"next mouse click performs only the optional discard")
	prepare(["standard_7_spades","standard_7_hearts","standard_k_clubs"])
	await helper_tap(true)
	await helper_tap(true)
	ui.selected_card_ids.clear()
	ui.selected_card_ids["standard_7_hearts"] = true
	preview_snapshot = var_to_str(ui.deal.snapshot_state())
	await helper_tap(true)
	await create_timer(0.4).timeout
	check(var_to_str(ui.deal.snapshot_state()) == preview_snapshot,"changing the player's selection cancels the pending discard")
	ui.strawy.close()
	await helper_tap(true)
	await helper_tap(true)
	ui.deal.zodiac_boss.locked_ids.append(ui.strawy.quick_card_id)
	preview_snapshot = var_to_str(ui.deal.snapshot_state())
	await helper_tap(true)
	await create_timer(0.4).timeout
	check(var_to_str(ui.deal.snapshot_state()) == preview_snapshot,"a newly locked preview cannot be confirmed")
	ui.deal.zodiac_boss.locked_ids.clear()
	ui.strawy.close()
	await helper_tap(true)
	await helper_tap(true)
	ui.menu_layer.show()
	await process_frame
	check(not ui.strawy.actor.is_visible_in_tree() and ui.strawy.quick_action.is_empty(),"opening a menu hides Strawy and cancels pending confirmation")
	ui.menu_layer.hide()
	await process_frame
	await helper_tap(true)
	await create_timer(0.4).timeout
	check(ui.strawy.box.visible and ui.strawy.actions.get_child_count() <= 4,"single tap opens at most three contextual actions")
	check(ui.strawy.box.find_child("StrawyDiscard",true,false) == null,"ordinary discard uses the preview gesture, not another menu command")
	ui.strawy.close()
	await helper_tap(true)
	await helper_tap(true)
	preview_snapshot = var_to_str(ui.deal.snapshot_state())
	var helper_point := ui.strawy.hit.get_global_transform_with_canvas() * (ui.strawy.hit.size * 0.5)
	var touch_down := InputEventScreenTouch.new()
	touch_down.position = helper_point
	touch_down.pressed = true
	root.push_input(touch_down,true)
	var drag := InputEventScreenDrag.new()
	drag.position = helper_point + Vector2(40,0)
	root.push_input(drag,true)
	var touch_up := InputEventScreenTouch.new()
	touch_up.position = helper_point
	root.push_input(touch_up,true)
	check(var_to_str(ui.deal.snapshot_state()) == preview_snapshot,"a drag cannot confirm the highlighted discard")
	ui.strawy.close()
	ui.strawy.open_help()
	ui.deal.state = DealState.STATE_PHASE_CHOICE
	var before := var_to_str(ui.deal.snapshot_state())
	ui.strawy._command("play")
	ui.strawy._command("discard")
	check(var_to_str(ui.deal.snapshot_state()) == before,"stale phase-boundary commands cannot commit")
	ui.deal.state = DealState.STATE_FINAL_COMMIT_WINDOW
	before = var_to_str(ui.deal.snapshot_state())
	ui.strawy._command("discard")
	await helper_tap(true)
	await helper_tap(true)
	check(var_to_str(ui.deal.snapshot_state()) == before,"Last Call rejects helper discards")
	check(ui.strawy.quick_action.is_empty(),"Last Call cannot arm a discard")
	ui.drink_targeting_active = true
	check(not ui.strawy.can_play_cards(),"Drink targeting blocks helper commands")
	ui.drink_targeting_active = false
	ui.interaction_locked = true
	check(not ui.strawy.can_play_cards(),"required transitions block helper commands")
	ui.interaction_locked = false
	ui.strawy.close()
	await create_timer(0.4).timeout
	var save := ui.run_save.load_run()
	check(not save.is_empty() and save.deal.wallet_balance_vnd == ui.deal.wallet.balance_vnd,"normal autosave records helper wallet results")
	print("STRAWY_COMMANDS_SMOKE checks=%d failures=%d" % [checks,failures.size()])
	ui.queue_free()
	await process_frame
	quit(0 if failures.is_empty() else 1)
