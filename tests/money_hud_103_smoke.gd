extends SceneTree
var failures: Array[String] = []
func _initialize() -> void:
	call_deferred("_run")
func check(ok: bool, message: String) -> void:
	if not ok: failures.append(message)
func _run() -> void:
	root.size = Vector2i(1280, 720)
	var scene: MatchUI = load("res://scenes/match.tscn").instantiate()
	root.add_child(scene)
	current_scene = scene
	await process_frame
	scene.get_node("TitleScreen").queue_free()
	scene.game_started = true
	scene.game_layer.position = Vector2.ZERO
	scene.menu_layer.hide()
	scene.deal.start_tutorial_deal()
	scene._sync_all()
	var cards: Array[CardData] = []
	for card in scene.deal.hand:
		if card.rank_index == 9: cards.append(card)
	scene.deal.create_meld(cards)
	scene._refresh_stats()
	await create_timer(0.2).timeout
	check(scene.campaign_money_hud.income_panel.is_visible_in_tree(), "income is visible during a Deal")
	check(scene.earnings_value.text == VndWallet.format_amount(scene._points_to_vnd(scene.deal.current_deal_earnings_points()), true), "income shows authoritative current-deal earnings")
	for viewport in [Vector2i(1280, 720), Vector2i(1920, 1080), Vector2i(2548, 1368), Vector2i(1280, 720)]:
		root.size = viewport
		for amount: int in [0, 1234567, -75000, 999999999]:
			scene.money_presentation.sync_wallet(amount)
			await create_timer(0.1).timeout
			check(scene.wallet_value.text == VndWallet.format_amount(amount), "wallet amount has grouped digits without embedded currency")
			for label: Label in [scene.wallet_value, scene.earnings_value]:
				var unit: Label = label.get_parent().get_node("CurrencyUnit")
				check(unit.text == "VNĐ", "unit uses VNĐ")
				check(label.get_theme_font_size("font_size") > unit.get_theme_font_size("font_size"), "number is larger than currency")
				check(label.get_global_rect().end.x <= unit.get_global_rect().position.x, "amount and currency do not overlap")
				check(label.get_theme_font("font").get_string_size(label.text, HORIZONTAL_ALIGNMENT_LEFT, -1, label.get_theme_font_size("font_size")).x <= label.size.x + 1, "amount fits without ellipsis")
			check(scene.campaign_money_hud.income_panel.get_global_rect().end.x < scene.campaign_money_hud.panel.get_global_rect().position.x, "income and wallet do not overlap")
		var hud_controls: Array[Control] = [scene.get_node("GameLayer/Header/HeaderRow/CampaignStat"), scene.campaign_money_hud.rate_panel, scene.campaign_money_hud.income_panel, scene.campaign_money_hud.panel, scene.get_node("ActionLegend/Toggle")]
		for i in hud_controls.size():
			var rect := hud_controls[i].get_global_transform_with_canvas() * Rect2(Vector2.ZERO, hud_controls[i].size)
			check(root.get_visible_rect().encloses(rect), "HUD stays inside viewport at %s: %s" % [viewport, hud_controls[i].name])
			for j in range(i + 1, hud_controls.size()):
				var other := hud_controls[j].get_global_transform_with_canvas() * Rect2(Vector2.ZERO, hud_controls[j].size)
				check(not rect.intersects(other), "HUD panels stay separate at %s: %s / %s" % [viewport, hud_controls[i].name, hud_controls[j].name])
	scene.menu_layer.show()
	await process_frame
	await process_frame
	check(not scene.campaign_money_hud.income_panel.visible and not scene.campaign_money_hud.panel.visible and not scene.campaign_money_hud.rate_panel.visible, "menu hides all money stats")
	scene.queue_free()
	await create_timer(0.15).timeout
	for message in failures: push_error(message)
	print("MONEY_HUD_103 failures=%d" % failures.size())
	quit(0 if failures.is_empty() else 1)