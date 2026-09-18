extends SceneTree
var failures: Array[String] = []
var scene: MatchUI
func _initialize() -> void:
	call_deferred("_run")
func check(value: bool, message: String) -> void:
	if not value:
		failures.append(message)
func pause() -> void:
	await create_timer(0.85).timeout
func capture(path: String) -> void:
	if DisplayServer.get_name() != "headless":
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png(path.replace(".png", "-en.png") if OS.get_cmdline_user_args().has("--english") else path)
func click(button: Button) -> void:
	var point := button.get_global_transform_with_canvas() * (button.size * 0.5)
	for down in [true, false]:
		var event := InputEventMouseButton.new()
		event.position = point
		event.button_index = MOUSE_BUTTON_LEFT
		event.pressed = down
		root.push_input(event, true)
	await create_timer(0.2).timeout
func _run() -> void:
	root.size = Vector2i(1280, 720)
	scene = load("res://scenes/match.tscn").instantiate()
	if OS.get_cmdline_user_args().has("--large"):
		root.size = Vector2i(1920, 1080)
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
	scene.deal.start_tutorial_deal()
	var meld_cards: Array[CardData] = []
	for card in scene.deal.hand:
		if card.rank_index == 9:
			meld_cards.append(card)
	check(scene.deal.create_meld(meld_cards).ok, "real meld records card evidence")
	scene.deal.wallet.apply_vnd(1_500_000, "new_meld")
	scene.deal.wallet.apply_vnd(-110_000, "deadwood")
	scene.deal.wallet.apply_vnd(40_000, "relic:comb")
	scene._show_deal_over({})
	await pause()
	check(scene.resolve_receipt.visible, "deal receipt visible")
	check(scene.resolve_receipt.primary.get_global_rect().end.y <= root.size.y, "continue fits viewport")
	await capture("res://.godot/resolve-deal.png")
	var receipt = scene.resolve_receipt
	var balance := scene.deal.wallet.balance_vnd
	await click(receipt._tabs.get_node("cards"))
	await pause()
	check(receipt.rows.find_children("*", "TextureRect", true, false).size() == 3, "three real scoring card faces")
	var face := receipt.rows.find_children("*", "TextureRect", true, false)[0] as TextureRect
	await click(face.get_parent())
	check(receipt.rows.find_children("*", "Label", true, false).any(func(label): return " · " in label.text and ("Standard card" in label.text or "Bài thường" in label.text)), "card click reveals properties")
	await capture("res://.godot/resolve-cards.png")
	await click(receipt._tabs.get_node("ledger"))
	await pause()
	check(receipt._page == "ledger", "pointer opens transactions")
	check(scene.deal.wallet.balance_vnd == balance, "browsing never pays")
	await capture("res://.godot/resolve-ledger.png")
	await click(scene.resolve_receipt.primary)
	check(scene.campaign.deal_reports.size() == 1, "pointer advances exactly one deal")
	scene.campaign.campaign_days[0]["required_vnd"] = 250_000
	scene.campaign._finish_day()
	await pause()
	check(scene.resolve_mode == "collection", "collector blocks progression")
	check(scene.resolve_receipt.portrait.visible, "collector portrait visible")
	check(not scene.resolve_receipt._report.get("actions", []).is_empty(), "collection retains scoring history")
	check(scene.resolve_receipt._scroll.size.y > 180, "details retain readable space")
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
