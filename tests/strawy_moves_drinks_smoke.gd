extends SceneTree
var ui: MatchUI
var checks := 0
var failures: Array[String] = []

func _initialize() -> void: call_deferred("_run")
func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok: failures.append(message); push_error(message)

func prepare(ids: Array[String], drink: String = DrinkCatalog.NONE) -> void:
	await finish_presentations()
	ui.strawy.close()
	ui.money_presentation.hide_ceremony()
	ui.reset_transient_presentation()
	ui.current_campaign_event = null
	ui.event_table.enter_deal()
	await create_timer(0.85).timeout
	ui.deal.start_deal(791)
	var all: Array[CardData] = ui.deal.hand.duplicate()
	all.append_array(ui.deal.deck.draw_pile)
	ui.deal.hand.clear()
	ui.deal.deck.draw_pile.clear()
	for card in all:
		if ids.has(card.unique_id): ui.deal.hand.append(card)
		else: ui.deal.deck.draw_pile.append(card)
	ui.deal.set_current_drink(drink)
	ui.interactions.locked = false
	ui._sync_all()
	await create_timer(0.2).timeout

func finish_presentations() -> void:
	var deadline := Time.get_ticks_msec() + 8000
	while ui.money_playback.running and Time.get_ticks_msec() < deadline:
		ui.money_presentation.request_fast_forward()
		await process_frame
	if ui.money_playback.running: check(false, "money presentation completes before resetting the test fixture")
	await process_frame

func take(id: String) -> CardData:
	for card in ui.deal.deck.draw_pile:
		if card.unique_id == id:
			ui.deal.deck.draw_pile.erase(card)
			return card
	return null

func tap(control: Control, native: bool = false) -> void:
	await process_frame
	var point := control.get_global_transform_with_canvas() * (control.size * 0.5)
	var motion := InputEventMouseMotion.new()
	motion.position = point
	root.push_input(motion, true)
	if native:
		for down in [true, false]:
			var touch := InputEventScreenTouch.new()
			touch.position = point
			touch.pressed = down
			root.push_input(touch, true)
	for down in [true, false]:
		var mouse := InputEventMouseButton.new()
		mouse.device = -1 if native else 0
		mouse.position = point
		mouse.button_index = MOUSE_BUTTON_LEFT
		mouse.pressed = down
		root.push_input(mouse, true)

func preview(expected: String, native: bool = false) -> void:
	await process_frame
	var before := var_to_str(ui.deal.snapshot_state())
	var rng_before := ui.deal.deck._rng.state
	var save_before := FileAccess.get_file_as_bytes(ui.session.run_save.path)
	await tap(ui.strawy.hit, native)
	await tap(ui.strawy.hit, native)
	check(ui.strawy.quick_action == expected, "double click previews " + expected)
	check(ui.strawy.box.visible and not ui.strawy.copy.text.is_empty(), "preview speaks from Strawy")
	check(var_to_str(ui.deal.snapshot_state()) == before and ui.deal.deck._rng.state == rng_before, "preview leaves authoritative state and RNG unchanged")
	check(FileAccess.get_file_as_bytes(ui.session.run_save.path) == save_before, "preview leaves the save unchanged")
	await create_timer(0.35).timeout
	check(ui.strawy.quick_action == expected, "single-click timer cannot replace preview")

func capture(label: String) -> void:
	await process_frame
	await process_frame
	check(ui.get_viewport_rect().encloses(ui.hint_button.get_global_rect()) and ui.get_viewport_rect().encloses(ui.settle_button.get_global_rect()), "Hint and settlement fit the action bar")
	if ui.strawy.box.visible:
		check(ui.get_viewport_rect().encloses(ui.strawy.box.get_global_rect()), "Strawy bubble fits the viewport")
	if "--capture" in OS.get_cmdline_user_args():
		ui.strawy._finish_speech()
		await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://.godot/strawy-overhaul-%s-%s-%d.png" % [label, ui.settings.locale_code, root.size.x])

func _run() -> void:
	root.size = Vector2i(1920, 1080) if "--large" in OS.get_cmdline_user_args() else Vector2i(1280, 720)
	ui = load("res://scenes/match.tscn").instantiate()
	root.add_child(ui)
	current_scene = ui
	await create_timer(0.4).timeout
	ui.settings.set_music_system("playing_tracks")
	ui.settings.set_locale("vi" if "--vi" in OS.get_cmdline_user_args() else "en")
	ui.settings.set_strawy_enabled(true)
	ui.settings.set_tutorial_enabled(false)
	ui.session.run_save = RunSave.new("user://moves-%d.save" % Time.get_ticks_usec())
	ui.drink_manager.progress.save_path = ""
	ui.game_started = true
	ui.game_layer.position = Vector2.ZERO
	ui.menu_layer.hide()
	ui._start_campaign()
	await prepare(["standard_7_spades", "standard_7_hearts", "standard_7_diamonds", "standard_k_clubs"])
	check(ui.hint_button.visible and not ui.hint_button.disabled, "Hint remains available alongside Strawy")
	ui.settings.set_strawy_enabled(false)
	var hint_before := var_to_str(ui.deal.snapshot_state())
	var hint_rng := ui.deal.deck._rng.state
	var hint_save := FileAccess.get_file_as_bytes(ui.session.run_save.path)
	await tap(ui.hint_button)
	check(ui.interactions.selected_ids.size() == 3 and ui.interactions.selected_meld_id == -1, "one Hint click selects the ready Meld even with Strawy hidden")
	check(var_to_str(ui.deal.snapshot_state()) == hint_before and ui.deal.deck._rng.state == hint_rng and FileAccess.get_file_as_bytes(ui.session.run_save.path) == hint_save, "Hint selects without changing gameplay, RNG, or save")
	check(ui.strawy.quick_action.is_empty() and not ui.strawy.box.visible, "Hint does not open a Strawy confirmation")
	ui.settings.set_strawy_enabled(true)
	await preview("play", true)
	check(ui.interactions.selected_ids.size() == 3, "meld preview selects three physical cards")
	await tap(ui.hint_button)
	check(ui.strawy.quick_action.is_empty() and not ui.strawy.box.visible and ui.interactions.selected_ids.size() == 3 and ui.deal.melds.is_empty(), "Hint replaces a pending Strawy preview with selection only")
	await preview("play", true)
	await capture("meld-preview")
	await tap(ui.strawy.hit, true)
	await create_timer(0.2).timeout
	check(ui.deal.melds.size() == 1 and ui.deal.action_counts.new_meld == 1, "third native tap commits one Meld despite emulated mouse")
	var meld := ui.deal.melds[0]
	await finish_presentations()
	ui.deal.hand.append(take("standard_7_clubs"))
	ui._sync_all()
	await tap(ui.hint_button)
	check(ui.interactions.selected_meld_id == meld.meld_id and ui.interactions.selected_ids.keys() == ["standard_7_clubs"], "one Hint click selects an Extend and its table Meld")
	check(meld.cards.size() == 3 and ui.deal.action_counts.get("extension", 0) == 0, "Hint does not commit the suggested Extend")
	ui.interactions.selected_ids.clear()
	ui.interactions.selected_meld_id = -1
	ui._refresh_actions()
	for down in [true, false]:
		var key := InputEventKey.new()
		key.physical_keycode = KEY_G
		key.pressed = down
		root.push_input(key, true)
	await process_frame
	check(ui.interactions.selected_meld_id == meld.meld_id and ui.interactions.selected_ids.keys() == ["standard_7_clubs"] and ui.strawy.quick_action.is_empty(), "G shortcut performs the same quick Extend selection")
	await preview("play")
	check(ui.interactions.selected_meld_id == meld.meld_id and ui.interactions.selected_ids.size() == 1, "extension preview selects the table Meld and additions")
	await tap(ui.strawy.hit)
	await create_timer(0.2).timeout
	check(meld.cards.size() == 4 and ui.deal.action_counts.extension == 1, "third mouse click commits one Extend")
	check(ui.deal.physical_card_accounting_is_valid(), "helper meld and extension conserve all cards")
	await prepare(["standard_7_spades", "standard_7_hearts", "standard_k_clubs"], DrinkCatalog.STING)
	await preview("play")
	check(ui.strawy.quick_plan.play.use_drink, "coach previews drink-only pair permission")
	await tap(ui.strawy.hit)
	await create_timer(0.2).timeout
	check(ui.deal.melds.size() == 1 and ui.deal.pair_used_phases.has(1), "third click uses Sting once through normal scoring")
	for drink in [DrinkCatalog.NHAN_TRAN, DrinkCatalog.DEN_DA]:
		await prepare(["standard_5_spades", "standard_6_spades", "standard_q_hearts", "standard_k_clubs"], drink)
		var useful := take("standard_7_spades")
		var irrelevant := take("standard_2_diamonds")
		var good := DiscardRecord.new(useful, 1, 1)
		var bad := DiscardRecord.new(irrelevant, 1, 2)
		ui.deal.deck.discard_pile.append_array([useful, irrelevant])
		ui.deal.discard_history.append_array([good, bad])
		ui._sync_all()
		var good_outline: Control = ui.card_table.discard_history_target_outlines[good.target_key()]
		var bad_outline: Control = ui.card_table.discard_history_target_outlines[bad.target_key()]
		check((good_outline.cue_mode() & CardActionOutline.CUE_DRINK) != 0 and bad_outline.cue_mode() == CardActionOutline.CUE_NONE, drink + " outlines only useful discards")
		ui.interactions.selected_ids["standard_5_spades"] = true
		ui._sync_all()
		good_outline = ui.card_table.discard_history_target_outlines[good.target_key()]
		check(good_outline.cue_mode() == CardActionOutline.CUE_NONE, "losing a Meld witness clears the discard outline")
		ui.interactions.drink_targeting = true
		ui.interactions.drink_ids["standard_5_spades"] = true
		ui._sync_all()
		var witness_outline: Control = ui.card_table.hand_views["standard_5_spades"].get_node("BeatVisual/ActionOutline")
		check((witness_outline.cue_mode() & CardActionOutline.CUE_DRINK) == 0, "arming an unhelpful swap never adds a blue hand cue")
		ui._cancel_drink_targeting()
		ui.interactions.selected_ids.clear()
		ui._sync_all()
		await preview("swap")
		await tap(ui.strawy.hit)
		await create_timer(0.2).timeout
		check(ui.deal.hand.has(useful) and not ui.deal.current_drink_has_charge(), "third click performs one useful swap")
		check(ui.deal.physical_card_accounting_is_valid(), "helper swap conserves all physical cards")
		await preview("play")
		await tap(ui.strawy.hit)
		await create_timer(0.2).timeout
		check(ui.deal.melds.size() == 1, "separate triple click plays the recovered Meld")
	await prepare(["standard_3_spades", "standard_4_spades", "standard_5_spades", "standard_k_hearts"], DrinkCatalog.NAU_DA)
	var run: Array[CardData] = ui.deal.hand.filter(func(c): return c.suit == "Spades")
	ui.deal.create_meld(run)
	ui._sync_all()
	await preview("recover")
	await tap(ui.strawy.hit)
	await create_timer(0.2).timeout
	check(ui.deal.melds.is_empty() and ui.deal.hand.size() == 4, "helper recovers a whole Meld for another scoring play")
	await preview("play")
	await tap(ui.strawy.hit)
	await create_timer(0.2).timeout
	check(ui.deal.action_counts.new_meld == 2, "recovered Meld scores through normal authority")
	# Marks are editable during active play and survive the actual save codec.
	for drink in [DrinkCatalog.SAM_DUA, DrinkCatalog.BAC_XIU]:
		await prepare(["standard_2_spades", "standard_4_hearts", "standard_6_diamonds", "standard_k_clubs"], drink)
		check(ui.interactions.drink_hand_eligible_card_ids().is_empty(), "keep drink does not outline the whole idle hand during ordinary play")
		var chosen := ui.deal.hand[0]
		ui.interactions.selected_ids[chosen.unique_id] = true
		ui._refresh_actions()
		ui.activate_drink()
		check(ui.deal.sam_dua_preserved_cards == [chosen] and ui.deal.current_drink_has_charge(), "mark during play without exhausting editing")
		ui.session.flush()
		var restored := DealState.new()
		var restored_campaign := CampaignManager.new()
		check(ui.session.run_save.restore(ui.session.run_save.load_run(), restored_campaign, restored), "real save codec restores preservation state")
		check(restored.sam_dua_preserved_cards.size() == 1 and restored.sam_dua_preserved_cards[0].unique_id == chosen.unique_id, "save preserves the exact marked card")
		ui.deal.state = DealState.STATE_FINAL_COMMIT_WINDOW
		ui._sync_all()
		check(ui.settle_button.tooltip_text.contains(chosen.short_label()) and not ui.settle_button.disabled, "carryover information leaves settlement available immediately")
		var kept_outline: Control = ui.card_table.hand_views[chosen.unique_id].get_node("BeatVisual/ActionOutline")
		check((kept_outline.cue_mode() & CardActionOutline.CUE_DRINK) != 0, "phase-end blue cue identifies the marked card")
		check(ui.interactions.drink_hand_eligible_card_ids().size() == ui.deal.hand.size(), "phase end cues offer the remaining keepable cards")
		await capture("carryover-cues")
		var discarded_ids := ui.deal.hand.filter(func(c): return c != chosen).map(func(c): return c.unique_id)
		await tap(ui.settle_button)
		check(ui.deal.state == DealState.STATE_PHASE_CHOICE or ui.deal.current_phase == 2, "one settlement click commits despite keep-card cues")
		ui.money_presentation.request_fast_forward()
		var deadline := Time.get_ticks_msec() + 15000
		while ui.deal.current_phase != 2 and Time.get_ticks_msec() < deadline:
			ui.money_presentation.request_fast_forward()
			await process_frame
		check(ui.deal.current_phase == 2 and not ui.modal_overlay.visible, "settlement transitions automatically without a keep/dump prompt")
		check(ui.deal.hand.has(chosen) and ui.deal.hand.size() == 10, "only marked cards carry before refill")
		for id in discarded_ids: check(ui.deal.deck.discard_pile.any(func(c): return c.unique_id == id), "unmarked card enters discards")
		check(ui.deal.physical_card_accounting_is_valid(), "automatic transition conserves physical cards")
	await prepare(["standard_2_spades", "standard_k_clubs"])
	ui.interactions.selected_ids[ui.deal.hand[0].unique_id] = true
	ui._refresh_actions()
	await tap(ui.hint_button)
	check(ui.interactions.selected_ids.is_empty() and ui.interactions.selected_meld_id == -1 and ui.deal.discard_history.is_empty() and ui.strawy.quick_action.is_empty(), "Hint with no Meld or Extend clears selection without suggesting or committing a discard")
	ui.interactions.selected_ids[ui.deal.hand[0].unique_id] = true
	ui._refresh_actions()
	await tap(ui.discard_button)
	check(ui.deal.discard_history.size() == 1, "one ordinary discard click commits immediately")
	await create_timer(0.2).timeout
	check(ui.deal.discard_history.size() == 1, "one ordinary discard click commits only once")
	await prepare(["standard_2_spades", "standard_k_clubs"], DrinkCatalog.TRA_DA)
	ui.interactions.selected_ids[ui.deal.hand[0].unique_id] = true
	ui._refresh_actions()
	await tap(ui.discard_button)
	await process_frame
	check(ui.deal.tra_da_extra_discard_pending and not ui.settle_button.disabled, "Trà Đá opens the ordinary optional extra discard")
	await tap(ui.settle_button)
	check(not ui.deal.tra_da_extra_discard_pending and ui.deal.discard_history.size() == 1, "one End Turn click skips the optional discard immediately")
	await prepare(["standard_2_spades", "standard_k_clubs"])
	await preview("discard")
	check(ui.deal.discard_history.is_empty(), "Strawy alone previews a discard before committing")
	await tap(ui.strawy.hit)
	check(ui.deal.discard_history.size() == 1, "Strawy third click confirms exactly one discard")
	await finish_presentations()
	ui.queue_free()
	await process_frame
	print("STRAWY_MOVES_DRINKS_SMOKE checks=%d failures=%d" % [checks, failures.size()])
	quit(0 if failures.is_empty() else 1)
