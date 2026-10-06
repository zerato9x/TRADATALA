extends SceneTree
var failures: Array[String] = []
var scene: MatchUI
const SAVE := "user://progression_scene_test.save"
func _initialize() -> void:
	call_deferred("_run")
func check(value: bool, message: String) -> void:
	if not value:
		failures.append(message)
func pause(seconds: float = 0.8) -> void:
	await create_timer(seconds).timeout
func capture(label: String) -> void:
	if DisplayServer.get_name() != "headless":
		await RenderingServer.frame_post_draw
		var suffix := "-en" if OS.get_cmdline_user_args().has("--english") else ""
		root.get_texture().get_image().save_png("res://.godot/progression-%s%s.png" % [label, suffix])
func click(button: Button) -> void:
	var point := button.get_global_transform_with_canvas() * (button.size * 0.5)
	for down in [true, false]:
		var event := InputEventMouseButton.new()
		event.position = point
		event.button_index = MOUSE_BUTTON_LEFT
		event.pressed = down
		root.push_input(event, true)
	await pause(0.3)
func make_scene() -> void:
	scene = load("res://scenes/match.tscn").instantiate()
	root.add_child(scene)
	current_scene = scene
	await pause(0.1)
	if OS.get_cmdline_user_args().has("--english"):
		TranslationServer.set_locale("en")
	scene.session.run_save = RunSave.new(SAVE)
	# Isolate the achievement profile too; these are test runs.
	scene.drink_manager.progress.save_path = ""
func _run() -> void:
	root.size = Vector2i(1280, 720)
	if OS.get_cmdline_user_args().has("--english"):
		root.size = Vector2i(1920, 1080)
		TranslationServer.set_locale("en")
	if OS.get_cmdline_user_args().has("--resume-only"):
		await make_scene()
		scene.front_end.show_home()
		await pause()
		check(not scene.front_end.saved.is_empty(), "fresh process detects save")
		scene.front_end.resume_requested.emit()
		await pause()
		check(scene.game_started and scene.campaign.endless, "fresh process restores endless")
		check(scene.campaign.current_day_index == 7 and scene.campaign.run_seed == "SIDEWALK-2026", "fresh process restores day and seed")
		check(scene.campaign.event_manager.current_event != null, "fresh process restores starter event")
		for failure in failures:
			push_error(failure)
		print("FRESH_PROCESS_RESUME: " + ("PASS" if failures.is_empty() else "FAIL"))
		scene.queue_free()
		await pause(0.25)
		quit(0 if failures.is_empty() else 1)
		return
	for suffix in ["", ".bak", ".tmp"]:
		if FileAccess.file_exists(SAVE + suffix):
			DirAccess.remove_absolute(SAVE + suffix)
	await make_scene()
	scene.front_end.show_setup()
	await pause()
	scene.front_end.draft.seed = "SIDEWALK-2026"
	var start_button := scene.front_end.footer.get_child(scene.front_end.footer.get_child_count() - 1) as Button
	check(start_button.get_global_rect().end.y <= root.size.y, "seeded start button fits")
	await capture("seed-menu")
	await click(start_button)
	await pause(1.0)
	check(scene.campaign.run_seed == "SIDEWALK-2026", "pointer starts requested seed")
	check(scene.drink_manager.available_drink_ids() == [DrinkCatalog.TRA_DA], "day one starter only tea")
	check(scene.drink_manager.select_for_event(0, DrinkCatalog.TRA_DA).ok, "starter tea can be chosen")
	scene.event_manager.complete_interaction("choose_drink")
	scene.campaign.complete_current_event()
	await pause(1.0)
	scene.deal.discard_card(scene.deal.hand[0])
	scene._sync_all()
	await pause()
	var hand := scene.deal.hand.map(func(card): return card.unique_id)
	var stock := scene.deal.deck.draw_pile.map(func(card): return card.unique_id)
	var saved := scene.session.run_save.load_run()
	check(not saved.is_empty(), "committed action autosaved to disk")
	scene.queue_free()
	await pause(0.2)
	await make_scene()
	scene.front_end.show_home()
	await pause(0.2)
	scene.front_end.resume_requested.emit()
	await pause(1.0)
	check(scene.game_started, "Continue button resumes disk save")
	check(scene.deal.hand.map(func(card): return card.unique_id) == hand, "resume preserves exact hand")
	check(scene.deal.deck.draw_pile.map(func(card): return card.unique_id) == stock, "resume preserves future draws")
	check(scene.deal.discard_count == 1, "resume preserves turn")
	check(not scene.interactions.locked, "resumed deal is actionable")
	await capture("resumed-deal")
	scene.deal.wallet.apply_vnd(50_000_000, "fixture")
	scene.campaign._enter_phase(CampaignManager.CampaignPhase.MORNING_EVENT)
	await pause()
	scene.event_table.focus_npc(EventTableController.NPC_HANG_RONG)
	await pause()
	var panel = scene.event_table.participants_container.get_child(0)
	var shop := scene.campaign.relic_shop
	check(shop.offers.size() == RelicShop.STOCK_SIZE and shop.card_stock.size() == RelicShop.CARD_STOCK_SIZE, "live shop has seeded relic and physical card stock")
	check(panel._tiles.size() == shop.offers.size() + shop.card_stock.size() + 1 and panel._tiles.has("remove"), "live shop presents every offer plus permanent removal")
	check(panel.find_child("RerollRelics", true, false) == null, "visit stock has no obsolete reroll control")
	await capture("relic-offer")
	var old := shop.offers.duplicate()
	var chosen: String = old[0]
	await click(panel._tiles[chosen])
	check(not shop.purchased, "inspect never purchases")
	await click(panel._buy)
	check(shop.purchased, "pointer buys one relic")
	check(scene.deal.relics.inventory.has(chosen), "bought relic is owned")
	old.erase(chosen)
	check(shop.offers == old, "purchase retains every unbought offer")
	scene.event_table.unfocus_npc()
	await pause()
	scene.event_table.focus_npc(EventTableController.NPC_HANG_RONG)
	await pause()
	panel = scene.event_table.participants_container.get_child(0)
	check(shop.offers == old and not shop.offers.has(chosen), "reopening the visit preserves sold and unsold stock")
	await capture("relic-purchased")
	# Populate the victory scroll with a real scoring action and the week ledger.
	scene.deal.start_tutorial_deal()
	var cards: Array[CardData] = []
	for card in scene.deal.hand:
		if card.rank_index == 9:
			cards.append(card)
	scene.deal.create_meld(cards)
	scene.campaign.deal_reports.append({"day_id": "sunday", "details": scene.deal.accounting_report()})
	scene.campaign.current_day_index = 6
	scene.campaign.event_manager.current_event = null
	scene.deal.wallet.apply_vnd(50_000_000, "fixture")
	scene.campaign._finish_day()
	await pause()
	check(scene.campaign.collect_day_debt(), "Sunday debt is collected")
	await pause()
	check(scene.resolve_receipt.endless_button.visible, "victory offers endless")
	check(scene.resolve_receipt._page == "chronicle", "victory opens run scroll")
	check(scene.resolve_receipt.rows.find_children("*", "TextureRect", true, false).size() == 3, "victory shows three MVP cards")
	await capture("victory-scroll")
	scene.resolve_receipt._scroll.scroll_vertical = 235
	await pause(0.2)
	await capture("victory-mvps")
	scene.resolve_receipt._scroll.scroll_vertical = 2000
	await pause(0.2)
	await capture("victory-stats")
	await click(scene.resolve_receipt.endless_button)
	await pause()
	check(scene.campaign.endless and scene.campaign.current_day_index == 7, "pointer enters endless day eight")
	check(scene.campaign.daily_requirement() == 24_000_000, "endless goal appears")
	check(scene.campaign.run_seed == "SIDEWALK-2026", "endless retains seed")
	check(scene.event_table.focused_npc_id == "doi_no", "new endless day presents its collector briefing")
	check("8" in scene.event_table.day_label.text, "endless day number visible")
	await capture("endless")
	# Presentation fixtures use the existing authority to enter the loss route.
	scene.session.run_save = RunSave.new("user://failure_presentation_test.save")
	scene.deal.wallet.apply_vnd(-scene.deal.wallet.balance_vnd, "shortfall_fixture")
	scene.campaign._finish_day()
	await pause(1.2)
	await capture("shortfall")
	await click(scene.resolve_receipt.primary)
	await pause()
	check(scene.campaign.run_failed, "unpayable debt reaches failure")
	await capture("failure")
	for failure in failures:
		push_error(failure)
	print("PROGRESSION_SCENE_SMOKE: " + ("PASS" if failures.is_empty() else "FAIL"))
	scene.queue_free()
	await pause(0.25)
	quit(0 if failures.is_empty() else 1)
