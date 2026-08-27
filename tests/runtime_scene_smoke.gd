extends SceneTree

var _failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var packed := load("res://scenes/match.tscn") as PackedScene
	_check(packed != null, "main scene loads")
	if packed == null:
		_finish()
		return
	var scene := packed.instantiate() as MatchUI
	root.add_child(scene)
	current_scene = scene
	await process_frame
	await process_frame
	await process_frame
	var menu := scene.get_node_or_null("MainMenu") as Control
	var game_layer := scene.get_node_or_null("GameLayer") as Control
	var background := scene.get_node_or_null("SidewalkTableBackground") as TextureRect
	var background_position_before := background.global_position if background != null else Vector2.INF
	_check(menu != null and menu.visible, "main menu is visible before play")
	_check(scene.get_node_or_null("MainMenu/MenuPanel") != null, "main menu panel exists")
	_check(scene.get_node_or_null("MainMenu/MenuPanel") != null and scene.play_button != null, "play action exists")
	_check(game_layer != null and game_layer.position.x > 0.0, "game layer begins parked beyond the right screen edge")
	scene.play_button.pressed.emit()
	await create_timer(0.82).timeout
	_check(scene.game_started and not menu.visible, "play hides the menu after its exit transition")
	_check(is_equal_approx(game_layer.position.x, 0.0), "game layer slides fully into place")
	_check(background != null and background.global_position.is_equal_approx(background_position_before), "background remains fixed while UI layers transition")
	_check(scene.deal.hand.size() == DealState.ACTIVE_HAND_TARGET, "opening hand refills to 10")
	_check(scene.hand_views.size() == DealState.ACTIVE_HAND_TARGET, "ten interactive card views are rendered")
	_check(scene.deal.deck.draw_pile.size() == 42, "draw pile count reflects opening draw")
	_check(scene.ha_button.disabled, "HẠ begins disabled without a legal selection")
	_check(scene.extend_button.disabled, "EXTEND begins disabled without a target")
	_check(scene.discard_button.disabled, "DISCARD begins disabled without one selected card")
	_check(scene.settle_button.disabled, "CHỐT begins disabled before the final commit window")
	_check(not scene.hint_button.disabled, "GỢI Ý is available during an active turn")
	_check(scene.get_node_or_null("GameLayer/TableSurface/MeldScroll") != null, "table Meld region exists")
	_check(scene.get_node_or_null("GameLayer/TableSurface/MeldProbabilityPanel") == null, "no probability panel obstructs the table")
	_check(scene.get_node_or_null("GameLayer/LooseHand/CardFan") != null, "loose-hand presentation region exists")
	_check(scene.get_node_or_null("GameLayer/ActionDock") != null, "action dock exists")
	_check(scene.get_node_or_null("GameLayer/UtilityRail/DrinkArea/DrinkSlot") != null, "Drink slot exists")
	_check(scene.drink_name_label != null and scene.drink_name_label.text == "TRÀ ĐÁ", "free Trà đá is the visible starter Drink")
	_check(scene.discard_history_row != null, "full phase-numbered discard tray is visible")
	var relic_grid := scene.get_node_or_null("GameLayer/UtilityRail/RelicsArea/RelicScroll/RelicGrid") as GridContainer
	_check(relic_grid != null and relic_grid.get_child_count() == MatchUI.INITIAL_RELIC_SLOT_COUNT, "four expandable Relic slots exist")
	_check(background != null, "official sidewalk-table background exists")
	_check(background != null and background.texture != null and background.texture.resource_path == "res://assets/environment/sidewalk_table.png", "official background asset is active")
	_check(scene.theme != null and scene.theme.default_font != null and scene.theme.default_font.resource_path == PresentationTheme.OFFICIAL_FONT_PATH, "DFVN Pexel Grotesk is the official UI font")
	var first_card: CardData = scene.deal.hand[0]
	var first_view: PlayingCardView = scene.hand_views[first_card.unique_id]
	first_view._on_mouse_entered()
	scene._on_card_pressed(first_card)
	first_view._on_mouse_exited()
	_check(first_view.z_index == 100, "clicked card stays above the hand panel after hover exit")
	var chance_badge := first_view.get_node_or_null("MeldChance") as Label
	_check(chance_badge != null and chance_badge.visible and not chance_badge.text.is_empty(), "each loose card carries a minimal meld-chance badge")
	_check(chance_badge != null and chance_badge.position.x >= 0 and chance_badge.position.x + chance_badge.size.x <= PlayingCardView.CARD_SIZE.x, "chance badge stays inside the card face")
	for card in scene.deal.hand:
		_check(ResourceLoader.exists(card.texture_path()), "face texture exists for %s" % card.unique_id)
		var card_view: PlayingCardView = scene.hand_views[card.unique_id]
		var card_badge := card_view.get_node_or_null("MeldChance") as Label
		_check(card_badge != null and card_badge.visible, "meld chance badge exists for %s" % card.unique_id)
	scene.selected_card_ids.clear()
	for _turn in range(DealState.DISCARDS_PER_PHASE):
		scene.deal.discard_card(scene.deal.hand[0])
	scene._sync_all()
	_check(scene.deal.state == DealState.STATE_FINAL_COMMIT_WINDOW, "fourth discard enters LAST CALL without auto-settlement")
	_check(not scene.settle_button.disabled, "CHỐT becomes available during LAST CALL")
	_check(scene.discard_button.disabled, "additional discard remains blocked during LAST CALL")
	_check(scene.discard_history_row.get_child_count() == 5, "Phase 1 tray shows its label and all four discarded card faces")
	_check(scene.discard_history_row.get_child(1).get_child_count() >= 1, "discard history renders card-face thumbnails")
	_finish()


func _check(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)


func _finish() -> void:
	if _failures.is_empty():
		print("TRADATALA_SCENE_SMOKE passed")
		quit(0)
	else:
		for failure in _failures:
			print("SCENE_SMOKE_FAIL: %s" % failure)
		quit(1)

