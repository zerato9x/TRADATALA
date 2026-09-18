extends SceneTree
var failures: Array[String] = []
var scene: MatchUI
func _initialize() -> void:
	call_deferred("_run")
func check(value: bool, message: String) -> void:
	if not value:
		failures.append(message)
func pause() -> void:
	await create_timer(0.35).timeout
func capture(path: String) -> void:
	if DisplayServer.get_name() != "headless":
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png(path)
func click(button: Button) -> void:
	var point := button.get_global_transform_with_canvas() * (button.size * 0.5)
	for down in [true, false]:
		var event := InputEventMouseButton.new()
		event.position = point
		event.button_index = MOUSE_BUTTON_LEFT
		event.pressed = down
		root.push_input(event, true)
	await process_frame
func _run() -> void:
	scene = load("res://scenes/match.tscn").instantiate()
	root.add_child(scene)
	current_scene = scene
	await pause()
	var title := scene.get_node_or_null("TitleScreen")
	if title != null:
		title.queue_free()
	if OS.get_cmdline_user_args().has("--english"):
		TranslationServer.set_locale("en")
	await scene._on_play_pressed()
	scene.campaign.event_manager.complete_interaction("choose_drink")
	scene.campaign.complete_current_event()
	scene.deal.wallet.apply_vnd(1_500_000, "new_meld")
	scene.deal.wallet.apply_vnd(-110_000, "deadwood")
	scene.deal.wallet.apply_vnd(40_000, "relic:comb")
	scene._show_deal_over({})
	await pause()
	check(scene.resolve_receipt.visible, "deal receipt visible")
	check(scene.resolve_receipt.primary.get_global_rect().end.y <= root.size.y, "continue fits viewport")
	await capture("res://.godot/resolve-deal.png")
	await click(scene.resolve_receipt.primary)
	check(scene.campaign.deal_reports.size() == 1, "pointer advances exactly one deal")
	scene.campaign.campaign_days[0]["required_vnd"] = 250_000
	scene.campaign._finish_day()
	await pause()
	check(scene.resolve_mode == "collection", "collector blocks progression")
	check(scene.resolve_receipt.portrait.visible, "collector portrait visible")
	for row in scene.resolve_receipt.rows.get_children():
		if row is HBoxContainer:
			var amount := row.get_child(1) as Label
			check(amount.get_line_count() == 1, "money stays on one readable line")
			check(amount.get_global_rect().end.x <= root.size.x, "money fits viewport")
	await capture("res://.godot/resolve-collection.png")
	var before := scene.deal.wallet.balance_vnd
	await click(scene.resolve_receipt.primary)
	check(scene.deal.wallet.balance_vnd == before - 250_000, "pointer pays exactly once")
	check(scene.campaign.current_day_index == 1, "next day begins after collection")
	scene._show_campaign_outcome(true)
	await pause()
	await capture("res://.godot/resolve-outcome.png")
	check(scene.resolve_receipt.primary.get_global_rect().end.y <= root.size.y, "new run fits viewport")
	await click(scene.resolve_receipt.primary)
	check(scene.campaign.current_day_index == 0 and scene.deal.wallet.journal.is_empty(), "new run clears ledger")
	for failure in failures:
		push_error(failure)
	print("RESOLVE_SCENE_SMOKE: " + ("PASS" if failures.is_empty() else "FAIL"))
	scene.queue_free()
	await process_frame
	quit(0 if failures.is_empty() else 1)
