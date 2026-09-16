extends SceneTree

var failures: Array[String] = []
var checks := 0

func _initialize() -> void:
	call_deferred("run")

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures.append(message)
		push_error(message)

func click_at(point: Vector2) -> void:
	var motion := InputEventMouseMotion.new()
	motion.position = point
	root.push_input(motion, true)
	for pressed in [true, false]:
		var event := InputEventMouseButton.new()
		event.button_index = MOUSE_BUTTON_LEFT
		event.position = point
		event.pressed = pressed
		root.push_input(event, true)

func run() -> void:
	root.size = Vector2i(1600, 900)
	var scene := (load("res://scenes/match.tscn") as PackedScene).instantiate() as MatchUI
	root.add_child(scene)
	current_scene = scene
	await process_frame
	var title := scene.get_node_or_null("TitleScreen")
	if title != null:
		title.queue_free()
	scene.game_started = true
	scene.game_layer.position = Vector2.ZERO
	scene.menu_layer.hide()
	scene.deal.start_tutorial_deal()
	scene.drink_manager.empty_glasses.resize(28)
	scene.drink_manager.empty_glasses.fill(DrinkCatalog.TRA_DA)
	scene.drink_manager.morning_drink_id = DrinkCatalog.TRA_DA
	scene.drink_manager.afternoon_drink_id = DrinkCatalog.STING
	scene.deal.set_current_drink(DrinkCatalog.STING)
	scene.deal.wallet.reset(2887500)
	scene.displayed_wallet_vnd = 2887500
	scene.money_queue_wallet_vnd = 2887500
	scene.interaction_locked = false
	var complete: Array[CardData] = []
	for rank in range(1, 14):
		var label := "A" if rank == 1 else ("J" if rank == 11 else ("Q" if rank == 12 else ("K" if rank == 13 else str(rank))))
		complete.append(CardData.new("groove_%d" % rank, label, rank, "Hearts", rank))
	scene.deal.melds.append(MeldState.new(81, MeldRules.TYPE_RUN, complete))
	var distant: Array[CardData] = []
	for suit in ["Clubs", "Spades", "Diamonds", "Hearts"]:
		for copy_index in 3:
			distant.append(CardData.new("distant_%s_%d" % [suit, copy_index], "K", 13, suit, 13))
	scene.deal.melds.append(MeldState.new(82, MeldRules.TYPE_SET, distant))
	scene._sync_all()
	await create_timer(0.3).timeout
	check(scene.game_layer.get_node_or_null("EmptyGlasses") == null, "28 retired drinks create no cup pile")
	check(scene.get_node_or_null("GameLayer/TableSurface/DrinkProps/EmptyDrinkProp") == null, "retired cup prop is absent")
	check(scene.drink_table_button.visible, "active drink remains on the table")
	var run_view: MeldView = scene.meld_views[81]
	var assigned := 0
	for band in scene.reactive_meld_cards_by_band.values():
		for entry in band:
			if entry.view == run_view:
				assigned += 1
	check(assigned == 13, "completed run automatically assigns all thirteen cards to beat bands")
	var first := run_view.get_scoring_card_control(complete[0].unique_id)
	var sway := first.get_node("SwayFace") as TextureRect
	var before := sway.rotation
	await create_timer(0.15).timeout
	check(not is_equal_approx(before, sway.rotation), "completed run sways continuously")
	check(absf(sway.rotation) <= deg_to_rad(9.01), "sway stays within its maximum")
	scene._on_music_band_pulse(0, 1.0)
	await create_timer(0.08).timeout
	check(first.scale.y > 1.1, "completed run bounces without selection")
	var hand_view: PlayingCardView = scene.hand_views.values()[0]
	check(absf(hand_view._texture.rotation) <= deg_to_rad(0.81), "hand sway remains tiny")
	var face := (scene.meld_views[82] as MeldView).get_scoring_card_control(distant[-1].unique_id)
	scene.meld_scroll.scroll_horizontal = 0
	await scene._reveal_scoring_card(face)
	check(scene.meld_scroll.scroll_horizontal > 0, "offscreen scoring scrolls the table")
	check(scene.meld_scroll.get_global_rect().encloses(face.get_global_rect()), "target card is fully visible before its payout")
	var context := scene.deal.scoring.preview_new_meld(distant, MeldRules.TYPE_SET, 1)
	var balance := scene.deal.wallet.balance_vnd
	scene._queue_scoring(context, scene.meld_views[82])
	await create_timer(0.45).timeout
	check(scene.wallet_value.text == VndWallet.format_vnd(balance), "wallet waits while score accumulates")
	check(scene.money_presentation.bill_layer.get_child_count() > 0, "earnings form a visible stack")
	var deadline := Time.get_ticks_msec() + 10000
	while scene.money_queue_running and Time.get_ticks_msec() < deadline:
		await process_frame
	check(not scene.money_queue_running, "stack payout completes")
	check(scene.deal.wallet.balance_vnd == balance, "payout animation never mutates authoritative balance")
	var visual := scene._capture_exhaustion_visual(scene.deal.melds[1], scene.meld_views[82])
	scene.deal.melds.remove_at(1)
	scene._sync_melds()
	await process_frame
	var ghost: Control = visual.cards[0]
	check(scene.meld_scroll.is_ancestor_of(ghost), "exhaustion cards stay clipped to the scrollable table")
	scene.meld_scroll.scroll_horizontal = 0
	await scene._reveal_scoring_card(ghost)
	check(scene.meld_scroll.get_global_rect().encloses(ghost.get_global_rect()), "offscreen exhaustion target is revealed")
	await scene._return_exhaustion_visual(visual)
	await process_frame
	check(not is_instance_valid(visual.anchor), "exhaustion snapshot is released after return")
	scene.displayed_wallet_vnd = balance
	scene.money_queue_wallet_vnd = balance
	scene._refresh_stats()
	scene.meld_scroll.scroll_horizontal = 0
	await create_timer(0.2).timeout
	if DisplayServer.get_name() != "headless":
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://.godot/demo-refinements-table.png")
	var point := scene.wallet_pile_anchor.get_global_transform_with_canvas() * (scene.wallet_pile_anchor.size * 0.5)
	for index in 3:
		click_at(point)
		await create_timer(0.05).timeout
	check(is_instance_valid(scene.wallet_spiral), "three physical pointer clicks open the spiral")
	if is_instance_valid(scene.wallet_spiral):
		await create_timer(0.95).timeout
		check(scene.game_layer.modulate.a < 0.01, "spiral fades the gameplay HUD")
		check(scene.get_node("ActionLegend/Toggle").modulate.a < 0.01, "spiral also fades the separate help HUD")
		check(scene.wallet_spiral.notes.size() > 0, "wallet notes fly out")
		var logical_value := 0
		for note in scene.wallet_spiral.notes:
			logical_value += int(note.get_meta("denomination_vnd")) * int(note.get_meta("logical_count"))
		check(logical_value == balance - balance % 1000, "spiral represents all whole banknotes")
		scene._on_music_band_pulse(0, 1.0)
		await create_timer(0.08).timeout
		check(scene.wallet_spiral.notes[0].scale.y > 1.05, "wallet spiral uses the reactive bounce")
		if DisplayServer.get_name() != "headless":
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png("res://.godot/demo-refinements-spiral.png")
		var escape := InputEventKey.new()
		escape.keycode = KEY_ESCAPE
		escape.physical_keycode = KEY_ESCAPE
		escape.pressed = true
		root.push_input(escape, true)
		await create_timer(0.55).timeout
		check(not is_instance_valid(scene.wallet_spiral), "Escape closes the easter egg")
		check(is_equal_approx(scene.game_layer.modulate.a, 1.0), "HUD returns after exit")
	check(scene.deal.wallet.balance_vnd == balance, "wallet easter egg preserves money")
	scene.music_controller._stop_all_mix_players()
	scene.music_controller.music_director.stop()
	await create_timer(0.2).timeout
	scene.queue_free()
	await process_frame
	print("DEMO_REFINEMENTS_SMOKE: %s checks=%d failures=%d" % ["PASS" if failures.is_empty() else "FAIL", checks, failures.size()])
	for failure in failures:
		print("FAIL: " + failure)
	quit(0 if failures.is_empty() else 1)