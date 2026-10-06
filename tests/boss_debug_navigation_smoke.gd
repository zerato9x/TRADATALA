extends SceneTree

var scene: MatchUI
var failures: Array[String] = []
var checks := 0

func _initialize() -> void: call_deferred("_run")

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok: failures.append(message)

func key(code: Key) -> void:
	for pressed in [true, false]:
		var event := InputEventKey.new()
		event.keycode = code
		event.physical_keycode = code
		event.pressed = pressed
		root.push_input(event, true)
	await process_frame
func click(control: Control) -> void:
	await process_frame
	var point := control.get_global_transform_with_canvas() * (control.size * 0.5)
	if DisplayServer.get_name() != "headless": Input.warp_mouse(root.get_final_transform() * point)
	var motion := InputEventMouseMotion.new()
	motion.position = point
	motion.global_position = point
	root.push_input(motion, true)
	await process_frame
	for pressed in [true, false]:
		var event := InputEventMouseButton.new()
		event.position = point
		event.global_position = point
		event.button_index = MOUSE_BUTTON_LEFT
		event.pressed = pressed
		root.push_input(event, true)
	await process_frame

func ready_to_play() -> void:
	var deadline := Time.get_ticks_msec() + 3500
	while scene.interactions.locked and Time.get_ticks_msec() < deadline: await process_frame

func capture(label: String) -> void:
	if DisplayServer.get_name() == "headless": return
	await create_timer(0.25).timeout
	await RenderingServer.frame_post_draw
	var args := OS.get_cmdline_user_args()
	var variant := ("wide" if "--wide" in args else "base") + ("-vi" if "--vi" in args else "-en")
	DirAccess.make_dir_recursive_absolute("res://.godot/boss-debug-audit/screens")
	root.get_texture().get_image().save_png("res://.godot/boss-debug-audit/screens/%s-%s.png" % [variant, label])
func _run() -> void:
	root.size = Vector2i(2548, 1368) if "--wide" in OS.get_cmdline_user_args() else Vector2i(1280, 720)
	scene = load("res://scenes/match.tscn").instantiate() as MatchUI
	root.add_child(scene)
	current_scene = scene
	await process_frame
	scene.settings.set_locale("vi" if "--vi" in OS.get_cmdline_user_args() else "en")
	await key(KEY_F9)
	check(scene.menu_layer.visible and scene.front_end.page == "boss_lab", "F9 opens Boss Lab from startup")
	var choice := scene.front_end.boss_lab_body.find_child("Boss", true, false) as OptionButton
	await click(choice)
	check(choice.get_popup().visible, "pointer opens the actual boss dropdown")
	# Select through the OptionButton signal; surrounding controls use pointer input.
	choice.get_popup().hide()
	choice.select(choice.item_count - 1)
	choice.item_selected.emit(choice.item_count - 1)
	await process_frame
	check(scene.front_end.boss_options.boss == "dragon", "dropdown selection sets the requested boss")
	await capture("boss-lab")
	await click(scene.front_end.footer.find_child("StartBossTest", true, false))
	await ready_to_play()
	check(scene.session.debug_active and scene.interaction_snapshot().can_play, "Start Test from startup reaches a playable encounter")
	check(scene.deal.zodiac_boss.id == "dragon", "Start Test applies the dropdown selection")
	await capture("boss-start")
	var before_ids: Array = scene.deal.hand.map(func(card): return card.unique_id)
	var before_boss := scene.deal.zodiac_boss.snapshot()
	await click(scene.boss_debug_toolbar.localized_buttons[0].button)
	await ready_to_play()
	check(scene.deal.hand.map(func(card): return card.unique_id) == before_ids and scene.deal.zodiac_boss.snapshot() == before_boss, "toolbar Replay repeats the seeded encounter")
	await click(scene.boss_debug_toolbar.localized_buttons[1].button)
	check(scene.front_end.page == "boss_lab" and scene.menu_layer.visible, "toolbar Boss Lab opens")
	await scene._close_menu_to_game()

	scene.deck_screen.open_deck(scene.deal.deck.draw_pile, "DECK", "")
	await key(KEY_F9)
	check(not scene.deck_screen.visible, "F9 dismisses the deck browser covering Boss Lab")
	await click(scene.front_end.footer.find_child("StartBossTest", true, false))
	await ready_to_play()
	check(scene.interaction_snapshot().can_play, "debug start cannot retain the previous deck input blocker")
	scene.deck_screen.close()
	GameGlossary.open(scene)
	await process_frame
	await key(KEY_F9)
	check(not root.has_node("GameGlossary"), "F9 dismisses the Handbook covering Boss Lab")
	var glossary := root.get_node_or_null("GameGlossary")
	if glossary: glossary.queue_free()
	await process_frame
	await scene._close_menu_to_game()

	# A receipt canvas is suspended without destroying its report or controls.
	scene._ensure_resolve_receipt()
	scene.resolve_mode = "outcome"
	scene.interactions.locked = true
	var report := {"net_vnd": 0, "income_vnd": 0, "expense_vnd": 0, "opening_vnd": 1_000_000, "closing_vnd": 1_000_000}
	scene.resolve_receipt.show_report(report, "outcome", "RESULT", "CONTINUE")
	await key(KEY_F9)
	check(not (scene.resolve_receipt.get_parent() as CanvasLayer).visible, "F9 suspends the receipt canvas above Boss Lab")
	check(scene.resolve_receipt._report == report, "suspending a receipt preserves its report")
	await click(scene.front_end.footer.find_child("FrontBack", true, false))
	check(scene.front_end.page == "home", "Boss Lab Back reaches the home menu")
	await click(scene.front_end.home_body.get_child(0))
	await create_timer(0.25).timeout
	check((scene.resolve_receipt.get_parent() as CanvasLayer).visible and scene.resolve_receipt._report == report, "Back to Game restores the exact receipt")
	scene.resolve_receipt.hide()
	scene.resolve_mode = ""
	scene.interactions.locked = false

	var source_view: PlayingCardView = scene.card_table.hand_views[scene.deal.hand.front().unique_id]
	scene._on_card_drag_started(source_view.card, source_view.get_global_rect().get_center(), source_view)
	check(scene.interactions.drag_payload != null, "fixture starts a real card drag")
	await key(KEY_F9)
	check(scene.interactions.drag_payload == null and scene.card_table.drag_preview == null, "F9 cancels the drag before lab input")
	await scene._close_menu_to_game()

	# A delayed recovery can finish while the lab temporarily owns input.
	check(scene.start_boss_debug({"boss": "dragon", "drink": DrinkCatalog.NUOC_VOI, "seed": "RECOVERY-TRANSITION"}), "start a recovery-capable boss fixture")
	await ready_to_play()
	var run_cards: Array[CardData] = []
	for card in scene.deal.hand:
		if card.suit == "Clubs" and card.rank_index in [4, 5, 6, 7]: run_cards.append(card)
	var meld_result := scene.deal.create_meld(run_cards)
	check(meld_result.get("ok", false), "fixture makes a legal four-card Run")
	var recovering := run_cards[0]
	var recovering_meld := int(meld_result.get("meld_id", -1))
	check(scene.deal.can_use_nuoc_voi(recovering_meld, recovering), "fixture recovery is legal")
	scene._sync_all()
	scene.recover_drink_card(recovering_meld, recovering)
	await key(KEY_F9)
	await create_timer(0.25).timeout
	check(scene.interactions.locked and scene.deal.hand.has(recovering), "recovery finishes with table input locked behind the lab")
	await scene._close_menu_to_game()
	check(scene.interaction_snapshot().can_play and scene.deal.physical_card_accounting_is_valid(), "closing the lab after recovery releases the same valid encounter")
	# Open the lab during the actual event-to-deal entry animation.
	scene.event_table.table_state = EventTableController.TABLE_STATE_EVENT
	scene.event_table.show()
	check(scene.start_boss_debug({"boss": "rooster", "seed": "ENTRY-TRANSITION"}), "start a boss through the entry animation")
	await key(KEY_F9)
	await create_timer(1.0).timeout
	check(scene.interactions.locked, "entry completion keeps table input locked behind Boss Lab")
	await scene._close_menu_to_game()
	check(scene.interaction_snapshot().can_play, "closing the lab after entry completion releases gameplay")
	scene.modal_overlay.show()
	scene.interactions.locked = true
	await key(KEY_F9)
	check(not scene.modal_overlay.visible, "F9 temporarily hides a deal modal")
	check(scene.resume_boss_debug(), "saved debug encounter resumes from a deal modal")
	await ready_to_play()
	await click(scene.menu_button)
	await scene._close_menu_to_game()
	check(not scene.modal_overlay.visible and scene.interaction_snapshot().can_play, "resuming debug never resurrects the replaced deal modal")
	scene.modal_overlay.hide()
	scene.interactions.locked = false
	# Real mandatory discards reach the phase settlement window.
	for _turn in 4:
		check(scene.deal.discard_card(scene.deal.hand.back()).get("ok", false), "settlement fixture discards legally")
	scene._sync_all()
	scene._refresh_actions()
	check(not scene.settle_button.disabled, "settlement fixture reaches a legal phase end")
	scene._on_settle_pressed()
	check(scene.start_boss_debug({"boss": "dragon", "seed": "REPLACEMENT"}), "replace a settling encounter")
	await ready_to_play()
	await create_timer(0.3).timeout
	check(not scene.modal_overlay.visible and scene.deal.current_phase == 1 and scene.interaction_snapshot().can_play, "old settlement completion cannot overlay the replacement boss")
	check(scene.deal.physical_card_accounting_is_valid(), "replacement retains physical card accounting")
	await click(scene.boss_debug_toolbar.localized_buttons[2].button)
	check(not scene.session.debug_active and scene.front_end.page == "home", "toolbar Exit returns to the normal profile")
	# A normal replacement run must retire a receipt suspended by the lab.
	scene.game_started = true
	scene.menu_layer.hide()
	scene.game_layer.position = Vector2.ZERO
	scene.run_seed_input = "NORMAL-BEFORE-LAB"
	scene._start_campaign()
	scene.resolve_mode = "outcome"
	scene.interactions.locked = true
	scene.resolve_receipt.show_report(report, "outcome", "RESULT", "CONTINUE")
	await key(KEY_F9)
	scene.front_end.go_back()
	await process_frame
	await click(scene.front_end.home_body.find_child("NewRun", true, false))
	scene.front_end.draft.seed = "NORMAL-AFTER-LAB"
	scene.front_end._start_pressed()
	if scene.front_end.confirming: scene.front_end._start_pressed()
	await create_timer(1.0).timeout
	check(scene.campaign.run_seed == "NORMAL-AFTER-LAB", "New Run works after leaving the lab")
	check(not scene._boss_lab_hidden_receipt and not scene._boss_lab_hidden_modal, "New Run clears suspended lab presentation state")
	scene.resolve_receipt.show_report(report, "outcome", "NEW RESULT", "CONTINUE")
	check((scene.resolve_receipt.get_parent() as CanvasLayer).visible, "new normal run receipts cannot remain invisible")
	scene.resolve_receipt.hide()
	if DisplayServer.get_name() != "headless":
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://.godot/boss-debug-audit/navigation-final.png")
	for failure in failures: print("FAIL: ", failure)
	print("BOSS_DEBUG_NAVIGATION_SMOKE checks=%d failures=%d" % [checks, failures.size()])
	scene.queue_free()
	await process_frame
	quit(0 if failures.is_empty() else 1)
