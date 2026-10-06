extends SceneTree
## Native pointer checks for the whole Hàng Rong table in EN/VI and two viewports.
var scene: MatchUI
var failures: Array[String] = []
var checks := 0

func _initialize() -> void:
	call_deferred("_run")

func _check(ok: bool, message: String) -> void:
	checks += 1
	if not ok: failures.append(message)

func _pause(seconds: float) -> void:
	var deadline := Time.get_ticks_msec() + int(seconds * 1000)
	while Time.get_ticks_msec() < deadline: await process_frame

func _hover(control: Control) -> void:
	var motion := InputEventMouseMotion.new()
	motion.position = control.get_global_transform_with_canvas() * (control.size * 0.5)
	root.push_input(motion, true)
	await process_frame

func _click(control: Control) -> void:
	var parent := control.get_parent()
	while parent != null:
		if parent is ScrollContainer:
			parent.ensure_control_visible(control)
			await _pause(0.06)
			break
		parent = parent.get_parent()
	await _hover(control)
	var point := control.get_global_transform_with_canvas() * (control.size * 0.5)
	for down in [true, false]:
		var event := InputEventMouseButton.new()
		event.position = point
		event.button_index = MOUSE_BUTTON_LEFT
		event.pressed = down
		root.push_input(event, true)
	await _pause(0.08)

func _panel() -> RelicTableShop:
	return scene.event_table.participants_container.get_child(0) as RelicTableShop

func _capture(suffix: String) -> void:
	if DisplayServer.get_name() == "headless": return
	TextReveal.finish(scene.event_table.conversation.speech)
	scene.money_playback.synchronize(scene.deal.wallet.balance_vnd)
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://.godot/hang-rong-" + suffix + ("-1080p" if OS.get_cmdline_user_args().has("--large") else "-720p") + ".png")

func _run() -> void:
	var locale := "vi" if OS.get_cmdline_user_args().has("--vietnamese") else "en"
	root.size = Vector2i(1920, 1080) if OS.get_cmdline_user_args().has("--large") else Vector2i(1280, 720)
	scene = load("res://scenes/match.tscn").instantiate()
	root.add_child(scene)
	current_scene = scene
	await _pause(0.15)
	scene.session._accepting_saves = false
	scene.session.save_files.suspended = true
	scene.drink_manager.progress.save_path = ""
	TranslationServer.set_locale(locale)
	scene._on_locale_changed(locale)
	scene.run_seed_input = "HANG-RONG-PRESENTATION"
	await scene._on_play_pressed()
	scene.event_table.enter_deal()
	scene.deal.wallet.reset(100_000)
	scene.campaign._enter_phase(CampaignManager.CampaignPhase.MORNING_EVENT)
	await _pause(0.7)
	scene.event_table.focus_npc("hang_rong")
	await _pause(0.3)
	var shop := scene.campaign.relic_shop
	var panel := _panel()
	_check(panel.selected.is_empty(), "opening does not silently select or buy")
	_check(panel._buy.disabled, "confirmation requires selection")
	_check(panel._tiles.size() == 7, "three relics, three concrete cards and one removal service share the table")
	_check(not scene.event_table.conversation.get_node("Lines/Responses").visible, "shop uses Back without redundant conversation buttons")
	var auntie := scene.event_table._npc_layers["hang_rong"].sprite as Control
	_check(auntie.get_global_rect().position.x > panel.get_global_rect().end.x, "Auntie's baskets leave all shop text and prices clear")
	var before := scene.deal.wallet.balance_vnd
	var journal_size := scene.deal.wallet.journal.size()
	var initial := shop.offers.duplicate()
	var first: String = initial[0]
	var second: String = initial[1]
	await _click(panel._tiles[first])
	_check(panel.selected == first, "pointer selects exact relic")
	_check(scene.deal.wallet.balance_vnd == before and scene.deal.wallet.journal.size() == journal_size, "selection cannot spend money")
	_check(scene.event_table.conversation._full_line.contains(RelicCatalog.effect(first)), "Auntie gives full authoritative effect")
	TextReveal.finish(scene.event_table.conversation.speech)
	await _pause(0.06)
	_check(scene.event_table.conversation.speech.get_parsed_text().length() > 40, "effect is rendered beyond the name")
	await _hover(panel._tiles[second])
	_check(panel.selected == first, "hover preserves selected purchase")
	panel._tiles[second].grab_focus()
	await process_frame
	_check(panel.selected == first, "keyboard focus does not purchase or replace selection")
	_check(panel._buy.text.contains(RelicCatalog.display_name(first)), "confirmation names selected relic")
	_check(panel._buy.text.contains(VndWallet.format_vnd(shop.price())), "confirmation shows authoritative price")
	var viewport_rect := root.get_visible_rect()
	for control: Control in [panel, panel._buy, panel._detail]:
		_check(viewport_rect.has_point(control.get_global_transform_with_canvas() * Vector2.ZERO), control.name + " begins inside viewport")
		_check(viewport_rect.has_point(control.get_global_transform_with_canvas() * (control.size - Vector2.ONE)), control.name + " ends inside viewport")
	for icon: TextureRect in panel._icons.values():
		_check(icon.size.x <= 100 and icon.size.y <= 125, "stock art cannot expand into its captions")
	var revealed := scene.event_table.conversation.speech.visible_characters
	await _click(panel._tiles[first])
	_check(scene.event_table.conversation.speech.visible_characters == revealed, "reclick preserves explanation reveal")
	var price := panel._tiles[first].get_node("PriceTag/Price") as Label
	_check(price.text == VndWallet.format_vnd(shop.price()), "paper tag matches relic price")
	_check(price.get_meta("text_surface") == &"paper" and price.get_meta("text_role") == &"cost", "paper cost has explicit readable semantics")
	await _capture(locale + "-selected")
	for id: String in RelicCatalog.DEFINITIONS:
		shop.offers.assign([id])
		shop.relic_stock.assign([id])
		shop.changed.emit()
		await _pause(0.05)
		panel = _panel()
		await _click(panel._tiles[id])
		_check(scene.event_table.conversation._full_line.contains(RelicCatalog.effect(id)), id + " explains its complete effect")
		_check(not panel._offer_trigger(id).is_empty(), id + " has visible trigger")
		_check(panel._tiles[id].get_node("PriceTag/Price").size.x >= 140, id + " has a legible paper tag")
	shop.offers.assign(initial)
	shop.relic_stock.assign(initial)
	shop.changed.emit()
	scene.deal.wallet.reset(shop.price() - 500)
	await _pause(0.08)
	panel = _panel()
	await _click(panel._tiles[first])
	_check(panel._buy.disabled, "unaffordable object remains inspectable but cannot be purchased")
	_check(panel._detail.get_parsed_text().contains(VndWallet.format_vnd(500)), "exact missing amount is shown")
	await _capture(locale + "-unaffordable")
	scene.deal.wallet.reset(100_000)
	var owned := 0
	for id: String in RelicCatalog.DEFINITIONS:
		if not initial.has(id) and owned < 5:
			scene.deal.relics.acquire(id)
			owned += 1
	await _pause(0.08)
	panel = _panel()
	await _click(panel._tiles[first])
	before = scene.deal.wallet.balance_vnd
	journal_size = scene.deal.wallet.journal.size()
	await _hover(panel._tiles[second])
	await _click(panel._buy)
	_check(scene.deal.relics.inventory.has(first) and scene.deal.relics.equipped.has(first), "sixth relic is purchased and immediately active")
	_check(not scene.deal.relics.inventory.has(second), "hovered relic is not bought")
	_check(scene.deal.wallet.balance_vnd == before - shop.price(), "advertised relic cost commits once")
	_check(scene.deal.wallet.journal.size() == journal_size + 1, "one purchase has one payment")
	panel = _panel()
	_check(panel._buy.disabled, "sold selection cannot be bought twice")
	_check(panel._tiles[first].get_node("PriceTag/Price").text == GameGlossary.words("SOLD", "ĐÃ BÁN"), "only purchased object shows SOLD")
	_check(shop.offers.has(second), "other relics remain available")
	await _click(panel._tiles[second])
	await _click(panel._buy)
	_check(scene.deal.relics.equipped.size() == 7, "multiple same-visit relic purchases exceed the old cap")
	_check(shop.offers.size() == 1, "buying two removes only those two offers")
	var offered := shop.card_stock[0]
	var deck_size := scene.campaign.gieo_que.persistent_deck.size()
	panel = _panel()
	await _click(panel._tiles[offered.unique_id])
	_check(panel._buy.text.contains(offered.short_label()), "card confirmation identifies actual rank and suit")
	_check(panel._buy.text.contains(VndWallet.format_vnd(shop.card_price())), "card confirmation shows its own price")
	before = scene.deal.wallet.balance_vnd
	journal_size = scene.deal.wallet.journal.size()
	await _click(panel._buy)
	_check(scene.campaign.gieo_que.persistent_deck.size() == deck_size + 1, "pointer purchase adds one persistent physical card")
	_check(scene.event_table.event_deck_count.text.contains(str(deck_size + 1)), "event table immediately shows the increased deck size")
	_check(scene.deal.wallet.balance_vnd == before - shop.card_price(), "card charges advertised price")
	_check(scene.deal.wallet.journal.size() == journal_size + 1, "card purchase journals once")
	_check(_panel()._tiles[offered.unique_id].get_node("PriceTag/Price").text == GameGlossary.words("SOLD", "ĐÃ BÁN"), "purchased card has a sold tag")
	await _capture(locale + "-sold")
	scene.event_table.unfocus_npc()
	await _pause(0.3)
	scene.event_table.focus_npc("hang_rong")
	await _pause(0.25)
	panel = _panel()
	_check(shop.offers.size() == 1 and shop.sold_cards.has(offered.unique_id), "reopening retains every sold object")
	_check(panel._tiles[offered.unique_id].get_node("PriceTag/Price").text == GameGlossary.words("SOLD", "ĐÃ BÁN"), "sold card tag survives reopening")
	var target := scene.campaign.gieo_que.persistent_deck[0]
	target.fortune = -4
	target.liquid = true
	target.negative = true
	target.transformation_locked = true
	await _click(panel._tiles["remove"])
	_check(panel._buy.text.contains(VndWallet.format_vnd(shop.removal_price())), "service shows its escalating authoritative price")
	before = scene.deal.wallet.balance_vnd
	var removal_cost := shop.removal_price()
	await _click(panel._buy)
	_check(shop.removal_pending and scene.deck_screen.visible, "Pay opens the owned-card picker")
	_check(scene.deal.wallet.balance_vnd == before - removal_cost, "removal payment happens exactly once")
	_check(scene.event_table.continue_button.disabled, "paid removal blocks leaving the event")
	_check(scene.deck_screen._allowed.has(target.unique_id), "sealed transformed card is eligible for whole-card removal")
	_check(scene.deck_screen._purpose.text.contains(GameGlossary.words("properties", "thuộc tính")), "picker visibly communicates property loss")
	await _click(scene.deck_screen._grid.get_node("Card_" + target.unique_id))
	await _capture(locale + "-removal-picker")
	_check(scene.deck_screen._selected == target, "pointer selects exact owned physical card")
	await _click(scene.deck_screen._confirm)
	_check(not scene.deck_screen.visible, "selecting a card returns to table for final confirmation")
	_check(shop.removal_target_id == target.unique_id, "paid selection survives in service state")
	_check(scene.campaign.gieo_que.owned_card(target.unique_id) != null, "selection has not removed card before confirmation")
	_check(scene.deal.wallet.balance_vnd == before - removal_cost, "choosing card cannot charge again")
	await _capture(locale + "-removal-confirm")
	panel = _panel()
	await _click(panel._buy)
	_check(scene.campaign.gieo_que.owned_card(target.unique_id) == null, "final pointer confirmation removes exact physical card")
	_check(not scene.deal.physical_card_locations().has(target.unique_id), "removed card leaves inactive deal ownership too")
	_check(not shop.removal_pending and shop.removals == 1, "confirmation consumes paid ticket once")
	_check(scene.event_table.event_deck_count.text.contains(str(deck_size)), "event table immediately shows the pruned deck size")
	_check(scene.deal.wallet.balance_vnd == before - removal_cost, "confirmation cannot pay twice")
	_check(shop.removal_price() > removal_cost, "next removal visibly costs more")
	for id: String in RelicCatalog.DEFINITIONS: scene.deal.relics.acquire(id)
	scene.event_table.unfocus_npc()
	await _pause(0.25)
	_check(scene.event_table.overview.relic_buttons.size() == 10, "all ten owned relics have physical objects on the event table")
	await _capture(locale + "-event-relics")
	await _click(scene.event_table.continue_button)
	await _pause(0.7)
	_check(scene.relic_grid.columns == 1 and scene.relic_grid.get_child_count() == 10, "all ten active relics use vertical right-edge icons")
	var last := scene.relic_grid.get_child(9) as RelicSlot
	_check(last.tooltip_text.contains(RelicCatalog.effect(last.relic_id)), "last relic remains inspectable beyond four")
	(scene.relic_grid.get_parent() as ScrollContainer).ensure_control_visible(last)
	await _pause(0.08)
	await _capture(locale + "-relic-rail")
	print("SHOP_PRESENTATION_STAGE rail_captured")
	await _click(last)
	print("SHOP_PRESENTATION_STAGE last_icon_clicked")
	_check(root.get_node_or_null("GameGlossary") != null, "last icon pointer opens full effect inspection")
	var book := root.get_node_or_null("GameGlossary")
	if book != null: book.queue_free()
	await process_frame
	print("SHOP_PRESENTATION_STAGE handbook_closed")
	for message in failures: print("SHOP_PRESENTATION_FAIL " + message)
	print("HANG_RONG_PRESENTATION_SMOKE checks=%d failures=%d locale=%s" % [checks, failures.size(), locale])
	scene.queue_free()
	await process_frame
	quit(1 if not failures.is_empty() else 0)
