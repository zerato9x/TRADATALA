extends SceneTree

var failures: Array[String] = []

func _initialize() -> void:
	call_deferred("_run")

func _check(ok: bool, message: String) -> void:
	if not ok: failures.append(message)

func _run() -> void:
	await _check_moving_card_input()
	var scene := load("res://scenes/match.tscn").instantiate() as MatchUI
	root.add_child(scene)
	current_scene = scene
	await process_frame
	# Dismiss the opening title before testing menu pointer targets.
	await _click(scene.get_node("TitleScreen/TitleDisc") as Control)
	await create_timer(0.5).timeout
	await _click(scene.how_to_play_button)
	_check(scene.menu_page == &"how_to_play", "viewport click opens How to Play")
	await _click(scene.how_to_play_back_button)
	_check(scene.menu_page == &"home", "viewport click activates How to Play Back")
	await _click(scene.options_button)
	_check(scene.menu_page == &"options", "viewport click opens Options")
	await _click(scene.options_back_button)
	_check(scene.menu_page == &"home", "viewport click activates Options Back")
	await scene._on_play_pressed()
	await create_timer(0.5).timeout
	scene.event_table.focus_npc(EventTableController.NPC_TRA_DA)
	await create_timer(0.5).timeout
	var shop := scene.campaign_participants.get_child(0) as DrinkShop
	_check(shop != null and shop._buttons.size() == 12 and shop.shelf.get_child_count() == 4, "Starter groups twelve Drinks into four classes")
	await _hover(shop._buttons[DrinkCatalog.STING] as Control)
	_check(shop.selected_id.is_empty(), "hovering a drink does not inspect or select it")
	_check(not (shop._buttons[DrinkCatalog.STING] as Button).button_pressed, "hovering a drink does not mark it selected")
	await _click(shop._buttons[DrinkCatalog.TRA_DA] as Control)
	_check(shop.selected_id == DrinkCatalog.TRA_DA, "clicking a drink tile selects Tra Da")
	_check(scene.drink_manager.active_drink_id == DrinkCatalog.NONE and not scene.current_campaign_event.can_exit, "clicking a drink tile does not buy it or unlock continuation")
	await _hover(shop._buttons[DrinkCatalog.STING] as Control)
	_check(shop.selected_id == DrinkCatalog.TRA_DA, "hovering another drink does not replace the selected drink")
	_check((shop._buttons[DrinkCatalog.TRA_DA] as Button).button_pressed, "the selected drink stays visibly selected after hover")
	await _click(shop._buttons[DrinkCatalog.STING] as Control)
	_check(shop.selected_id == DrinkCatalog.STING, "clicking a drink tile selects Sting")
	_check(scene.drink_manager.active_drink_id == DrinkCatalog.NONE and not scene.current_campaign_event.can_exit, "clicking another drink tile still does not buy it")
	await _click(scene.event_table.back_button)
	_check(scene.event_table.focused_npc_id.is_empty(), "viewport click activates Back beneath the left NPC hit area")
	await create_timer(0.5).timeout
	scene.event_table.focus_npc(EventTableController.NPC_TRA_DA)
	await create_timer(0.5).timeout
	shop = scene.campaign_participants.get_child(0) as DrinkShop
	_check(shop != null, "returning to the NPC reopens the Drink shop")
	_check(scene.event_table.conversation.get_rect().end.y <= 270, "first opening never expands speech over the table")
	for locale_name in ["vi", "en"]:
		TranslationServer.set_locale(locale_name)
		for id in DrinkCatalog.all_ids():
			shop.inspect_drink(id)
			_check(scene.event_table.conversation.speech.text.contains(DrinkCatalog.display_name(id)), "inspection explains " + id)
			_check(not scene.current_campaign_event.can_exit, "inspection never spends or commits")
			_check(not DrinkCatalog.effect_text(id).begins_with("DRINK_EFFECT_"), "effect is localized " + id)
			await process_frame
			_check(scene.event_table.conversation.get_rect().end.y < scene.event_table.content_panel.position.y + 4, "speech does not overlap the drinks")
			_check(scene.event_table.conversation.speech.get_content_height() <= scene.event_table.conversation.speech.size.y, "every explanation fits the speech area")
	for size in [Vector2i(1280, 720), Vector2i(1920, 1080)]:
		root.size = size
		await process_frame
		for button: Control in shop._buttons.values():
			_check(scene.get_global_rect().encloses(button.get_global_rect()), "every Drink remains inside the viewport")
			_check(button.get_global_rect().end.x <= (scene.get_global_transform() * Vector2(880, 0)).x, "Drinks stay left of Cô Trà Đá's sprite")
			_check(button.get_global_rect().end.y <= (scene.get_global_transform() * Vector2(620, 620)).y, "Drinks stay on the table")
	root.size = Vector2i(1280, 720)
	TranslationServer.set_locale("vi")
	shop.inspect_drink(DrinkCatalog.BAC_XIU)
	await _hover(shop._buttons[DrinkCatalog.STING] as Control)
	_check(shop.selected_id == DrinkCatalog.BAC_XIU, "hovering after selection keeps the selected drink for the Order button")
	scene.get_node("ActionLegend/Shade").visible = false
	await create_timer(2.2).timeout
	if DisplayServer.get_name() != "headless":
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://docs/images/drink_shop_testing.png")
	shop.confirm.pressed.emit()
	await process_frame
	_check(scene.drink_manager.active_drink_id == DrinkCatalog.BAC_XIU, "order commits selected Drink")
	_check(scene.current_campaign_event.can_exit, "order unlocks campaign continuation")
	scene.event_table.unfocus_npc()
	_check(not scene.event_table.conversation.visible, "Back dismisses the conversation")
	scene.event_table.focus_npc(EventTableController.NPC_DANH_GIAY)
	_check(scene.event_table.conversation.visible, "other NPCs use the shared conversation")
	_check(scene.event_table.conversation.speech.get_parsed_text().contains("em"), "Đánh Giày speaks as a kid")
	scene.event_table.conversation.get_node("Lines/Responses/SmallTalk").pressed.emit()
	_check(scene.event_table.conversation.speech.get_parsed_text().contains("quả bóng"), "the kid has age-appropriate small talk")
	var legend := scene.get_node("ActionLegend")
	legend.get_node("Toggle").pressed.emit()
	_check(legend.get_node("Shade").visible, "action vocabulary is accessible from the question mark")
	_check(legend.get_node("Shade/Panel/Content/Words").text.contains("[color=#"), "action legend contains semantic colors")
	if DisplayServer.get_name() != "headless":
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://docs/images/action_vocabulary.png")
	legend.get_node("Shade/Panel/Content/Close").pressed.emit()
	scene.event_table.unfocus_npc()
	scene._on_campaign_continue_pressed()
	await create_timer(0.5).timeout
	scene.interaction_locked = false
	scene.deal.set_current_drink(DrinkCatalog.STING)
	scene.deal.state = DealState.STATE_FINAL_COMMIT_WINDOW
	scene.deal.hand = [CardData.new("pair_a", "8", 8, "Spades", 8), CardData.new("pair_b", "8", 8, "Hearts", 8)]
	scene._sync_all()
	scene._on_drink_pressed()
	_check(scene.drink_targeting_active, "Sting arms blue targeting")
	_check(scene.drink_table_texture.texture.resource_path.ends_with("_full.png"), "unused testing Drink has a filled glass")
	_check(not scene.hint_button.disabled and scene.ha_button.disabled, "targeting exposes Cancel and disables incomplete confirmation")
	await _click(scene.hand_views[scene.deal.hand[0].unique_id])
	scene._on_hint_pressed()
	_check(not scene.drink_targeting_active and scene.deal.current_drink_has_charge(), "Cancel leaves the charge available")
	_check(scene.pending_drink_card_ids.is_empty(), "Cancel clears pending targets")
	scene._on_drink_pressed()
	var pair_cards: Array[CardData] = scene.deal.hand.duplicate()
	var money_job_before_pair := scene.next_money_job_id
	await _click(scene.hand_views[pair_cards[0].unique_id])
	_check(scene.pending_drink_card_ids.has(pair_cards[0].unique_id), "first Pair card is selected")
	_check((scene.hand_views[pair_cards[0].unique_id] as PlayingCardView).drag_enabled, "drink targeting retains dragging")
	await _click(scene.hand_views[pair_cards[1].unique_id])
	_check(scene.next_money_job_id == money_job_before_pair + 1, "second Pair click commits and queues exactly one payout")
	await scene._wait_for_money_job(money_job_before_pair)
	_check(scene.deal.melds.size() == 1 and scene.deal.melds[0].pair_created, "Pair commits without a second cup click")
	_check(scene.drink_table_texture.texture.resource_path.ends_with("_half.png"), "spent testing Drink visibly changes its fill")
	scene.interaction_locked = false
	scene.deal.set_current_drink(DrinkCatalog.NAU_DA)
	scene._sync_all()
	scene.selected_meld_id = -1
	scene._on_drink_pressed()
	var recovered_view := scene.meld_views[scene.deal.melds[0].meld_id] as MeldView
	await _click(recovered_view._card_views[scene.deal.melds[0].cards[0].unique_id])
	_check(scene.deal.melds.is_empty() and scene.deal.hand.size() == 2, "Nâu đá targets the whole Meld in one click")
	for drink_id in [DrinkCatalog.NHAN_TRAN, DrinkCatalog.DEN_DA]:
		scene.deal.set_current_drink(drink_id)
		var incoming := CardData.new("swap_" + drink_id, "K", 13, "Clubs", 13)
		var outgoing := scene.deal.hand[0]
		var kind := DiscardRecord.KIND_DUMP if drink_id == DrinkCatalog.DEN_DA else DiscardRecord.KIND_MANDATORY
		var record := DiscardRecord.new(incoming, 1, 1, kind)
		scene.deal.discard_history = [record]
		scene.deal.deck.discard_pile.clear()
		scene.deal.recyclable_spent_cards.clear()
		scene.deal.deck.discard_pile.append(incoming)

		scene._sync_all()
		if kind == DiscardRecord.KIND_DUMP:
			var history_cards := scene.discard_history_row.get_children().filter(func(child: Node) -> bool: return child.has_meta("action_target_card_id"))
			_check(history_cards.is_empty(), "Den Da DUMP target stays out of the mandatory discard history")
		scene._on_drink_pressed()
		await _click(scene.hand_views[outgoing.unique_id])
		_check(scene.discard_archive_overlay.visible, "hand selection opens a readable swap picker for " + drink_id)
		scene._hide_discard_archive()
		_check(scene.pending_drink_card_ids.has(outgoing.unique_id) and scene.deal.current_drink_has_charge(), "closing picker preserves the hand target without spending")
		scene._on_discard_archive_pressed()
		var grid: GridContainer = scene.discard_archive_suit_grids["Clubs"]
		_check(grid.get_child_count() == 1, "swap picker contains the legal live target")
		await _click(grid.get_child(0))
		await create_timer(0.5).timeout
		_check(scene.deal.hand.has(incoming) and not scene.deal.hand.has(outgoing), "viewport target click swaps " + drink_id)
		_check(not scene.drink_targeting_active and not scene.discard_archive_overlay.visible, "swap closes picker and targeting")
	scene.deal.set_current_drink(DrinkCatalog.C2_ICED_TEA)
	scene.deal.hand = [CardData.new("c2_a", "3", 3, "Spades", 3), CardData.new("c2_b", "4", 4, "Hearts", 4), CardData.new("c2_c", "5", 5, "Clubs", 5), CardData.new("c2_bad", "9", 9, "Clubs", 9)]
	scene._sync_all()
	scene._on_drink_pressed()
	await _click(scene.hand_views["c2_bad"])
	_check(scene.pending_drink_card_ids.is_empty(), "unusable C2 card does not trap selection in an invalid state")
	for card_id in ["c2_a", "c2_c", "c2_b"]:
		await _click(scene.hand_views[card_id])
	_check(not scene.ha_button.disabled, "C2 accepts selecting endpoints before the middle")
	if DisplayServer.get_name() != "headless":
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://docs/images/drink_targeting.png")
	await _click(scene.hand_views["c2_b"])
	_check(scene.ha_button.disabled, "deselecting a necessary C2 card disables confirmation")
	await _click(scene.hand_views["c2_b"])
	scene._on_ha_pressed()
	_check(scene.deal.c2_used and scene.deal.melds[-1].run_compatibility == "any", "explicit confirmation creates the selected mixed-suit C2 run")
	scene.deal.set_current_drink(DrinkCatalog.NUOC_VOI)
	var removable: Array[CardData] = []
	for rank in range(2, 6): removable.append(CardData.new("voi_%d" % rank, str(rank), rank, "Spades", rank))
	scene.deal.melds = [MeldState.new(88, MeldRules.TYPE_RUN, removable)]
	scene._sync_all()
	scene._on_drink_pressed()
	var voi_view := scene.meld_views[88] as MeldView
	await _click(voi_view._card_views["voi_3"])
	_check(not scene.deal.nuoc_voi_used_phases.has(1), "illegal interior Run card leaves Nước vối available")
	await _click(voi_view._card_views["voi_2"])
	await create_timer(0.25).timeout
	_check(scene.deal.melds[0].cards.size() == 3 and scene.deal.hand.any(func(card: CardData) -> bool: return card.unique_id == "voi_2"), "viewport click returns the legal Nước vối endpoint")
	scene.deal.set_current_drink(DrinkCatalog.BAC_XIU)
	scene._sync_all()
	scene._on_drink_pressed()
	await _click(scene.hand_views[scene.deal.hand[0].unique_id])
	_check(scene.pending_drink_card_ids.size() == 1, "Bạc xỉu selects a loose card through viewport input")
	scene._on_hint_pressed()
	_check(not scene.deal.sam_dua_used, "cancelling Bạc xỉu leaves preservation available")
	scene._on_drink_pressed()
	scene._on_drink_pressed()
	_check(scene.deal.sam_dua_used and scene.deal.sam_dua_preserved_cards.is_empty(), "Bạc xỉu can confirm zero preserved cards")
	scene.deal.set_current_drink(DrinkCatalog.NONE)
	scene.deal.current_phase = 1
	scene.deal.state = DealState.STATE_FINAL_COMMIT_WINDOW
	var discarded_ids: Array[String] = []
	for card in scene.deal.hand: discarded_ids.append(card.unique_id)
	var settlement := scene.deal.settle_phase()
	scene._show_phase_choice(settlement["phase_resolution"])
	await create_timer(0.8).timeout
	_check(scene.deal.current_phase == 2 and not scene.modal_overlay.visible, "normal transition automatically DUMPs without KEEP UI")
	for card_id in discarded_ids:
		_check(scene.deal.deck.discard_pile.any(func(card: CardData) -> bool: return card.unique_id == card_id), "normal loose cards enter the discard pile")
		_check(not scene.deal.recyclable_spent_cards.any(func(card: CardData) -> bool: return card.unique_id == card_id), "phase DUMPs do not enter recyclable spent cards")
	scene.deal.set_current_drink(DrinkCatalog.DEN_DA)
	scene._sync_all()
	var mandatory_history_count := scene.deal.discard_history_for_phase(1).size() + scene.deal.discard_history_for_phase(2).size()
	var visible_history_cards := scene.discard_history_row.get_children().filter(func(child: Node) -> bool: return child.has_meta("action_target_card_id"))
	_check(visible_history_cards.size() == mandatory_history_count, "Den Da keeps between-phase DUMPs out of the four-per-phase history strip")
	scene.queue_free()
	await process_frame
	if failures.is_empty(): print("DRINK_SHOP_SMOKE: PASS twelve-drinks inspect-order bilingual targets layouts")
	else:
		for failure in failures: print("DRINK_SHOP_SMOKE_FAIL: " + failure)
	quit(0 if failures.is_empty() else 1)


func _check_moving_card_input() -> void:
	var view := PlayingCardView.new()
	root.add_child(view)
	view.set_card(CardData.new("input_probe", "3", 3, "Spades", 3))
	var counts := [0, 0]
	view.card_pressed.connect(func(_card: CardData) -> void: counts[0] += 1)
	view.card_drag_started.connect(func(_card: CardData, _point: Vector2) -> void: counts[1] += 1)
	var point := Vector2(40, 60)
	var press := InputEventMouseButton.new()
	press.button_index = MOUSE_BUTTON_LEFT
	press.pressed = true
	press.position = point
	view._gui_input(press)
	view.position.y -= 24
	var motion := InputEventMouseMotion.new()
	motion.position = view.get_global_transform().affine_inverse() * point
	view._gui_input(motion)
	var release := InputEventMouseButton.new()
	release.button_index = MOUSE_BUTTON_LEFT
	release.position = motion.position
	view._gui_input(release)
	_check(counts == [1, 0], "card animation under a stationary pointer cannot turn a click into a drag")
	press.position = motion.position
	view._gui_input(press)
	motion.position.x += 20
	view._gui_input(motion)
	_check(counts[1] == 1, "ordinary cards retain intentional drag interaction")
	view.queue_free()
	await process_frame


func _click(control: Control) -> void:
	await create_timer(0.25).timeout
	var point := control.get_global_transform_with_canvas() * (control.size * 0.5)
	var motion := InputEventMouseMotion.new()
	motion.position = point
	root.push_input(motion, true)
	await create_timer(0.25).timeout
	point = control.get_global_transform_with_canvas() * (control.size * 0.5)
	var press := InputEventMouseButton.new()
	press.position = point
	press.button_index = MOUSE_BUTTON_LEFT
	press.pressed = true
	root.push_input(press, true)
	# A small hand movement must still select while targeting a Drink.
	motion = InputEventMouseMotion.new()
	motion.position = point + Vector2(10, 0)
	motion.button_mask = MOUSE_BUTTON_MASK_LEFT
	root.push_input(motion, true)
	var release := InputEventMouseButton.new()
	release.position = motion.position
	release.button_index = MOUSE_BUTTON_LEFT
	root.push_input(release, true)
	await process_frame

func _hover(control: Control) -> void:
	var motion := InputEventMouseMotion.new()
	motion.position = control.get_global_transform_with_canvas() * (control.size * 0.5)
	root.push_input(motion, true)
	await process_frame
