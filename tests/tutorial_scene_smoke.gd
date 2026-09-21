extends SceneTree
# Regression for the retired standalone tutorial: reference cannot replace a Deal.
var failures: Array[String] = []
func _initialize() -> void:
	call_deferred("_run")
func check(value: bool, message: String) -> void:
	if not value: failures.append(message)
func _run() -> void:
	var scene: MatchUI = load("res://scenes/match.tscn").instantiate()
	root.add_child(scene)
	current_scene = scene
	await process_frame
	scene.run_save = RunSave.new("user://handbook-safety-test.save")
	scene.drink_manager.progress.save_path = ""
	scene.game_started = true
	scene.menu_layer.hide()
	scene.game_layer.position = Vector2.ZERO
	scene._start_campaign()
	scene.campaign.event_manager.complete_interaction("choose_drink")
	scene.campaign.complete_current_event()
	await create_timer(1.4).timeout
	scene.deal.set_current_drink(DrinkCatalog.STING)
	scene._sync_all()
	var before := scene.deal.snapshot_state()
	var hand := scene.deal.hand.map(func(card): return card.unique_id)
	for live in [false, true]:
		scene._start_tutorial_deal(live)
		await process_frame
		check(not scene.tutorial_active, "legacy tutorial never activates")
		check(root.get_node_or_null("GameGlossary") != null, "legacy entry opens reference")
		check(scene.deal.hand.map(func(card): return card.unique_id) == hand, "reference preserves hand")
		check(scene.deal.wallet.balance_vnd == before.wallet_balance_vnd, "reference preserves money")
		check(scene.deal.current_drink_id == before.current_drink_id, "reference preserves Drink")
		var point := scene.drink_table_button.get_global_transform_with_canvas() * (scene.drink_table_button.size * 0.5)
		for down in [true, false]:
			var click := InputEventMouseButton.new()
			click.position = point
			click.button_index = MOUSE_BUTTON_LEFT
			click.pressed = down
			root.push_input(click, true)
		check(not scene.drink_targeting_active, "handbook blocks underlying cup shortcut")
		check(scene.deal.current_drink_has_charge(), "handbook cannot consume drink charge")
		root.get_node("GameGlossary").queue_free()
		await process_frame
	check(not scene.tutorial_coach.visible, "old scripted coach stays hidden")
	scene._on_card_pressed(scene.deal.hand[-1])
	check(not scene.selected_card_ids.is_empty(), "onboarding permits arbitrary card selection")
	check(not scene.discard_button.disabled, "legal discard remains actionable before guided Hạ")
	scene.queue_free()
	# Allow the audio mixer to release stopped playback before process teardown.
	await create_timer(0.2).timeout
	for message in failures: push_error(message)
	print("TUTORIAL_REPLACEMENT_SMOKE: %d failures" % failures.size())
	quit(0 if failures.is_empty() else 1)
