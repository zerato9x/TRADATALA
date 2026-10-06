extends "res://tests/boss_presentation_smoke.gd"
## Mixed text, real pointer input, contextual Handbook and bilingual responsive screens.
func _run() -> void:
	rendered = DisplayServer.get_name() != "headless"
	capture_dir = "res://.godot/text-readability/screens"
	root.size = Vector2i(1280, 720)
	scene = load("res://scenes/match.tscn").instantiate() as MatchUI
	root.add_child(scene)
	current_scene = scene
	# Free watched forms before their deferred styling callback is delivered.
	for form in [LineEdit.new(), TextEdit.new(), PopupMenu.new()]:
		scene.add_child(form)
		form.free()
	var live_form := LineEdit.new()
	scene.add_child(live_form)
	await frames()
	check(live_form.has_meta("semantic_role"), "Deferred form styling survives freed siblings and styles live controls")
	live_form.queue_free()
	scene.session.restoring = true
	scene.session.run_save = RunSave.new("user://text-readability.save")
	scene.drink_manager.progress.save_path = ""
	scene.campaign.zodiac.progress = ZodiacProgress.new("")
	scene.campaign.current_day_index = 0
	scene.campaign.difficulty_progress.unlocked = 2
	scene.campaign.select_difficulty(2)
	scene.game_started = true
	scene.menu_layer.hide()
	scene.game_layer.position = Vector2.ZERO
	scene.game_layer.show()
	scene.event_table.table_state = EventTableController.TABLE_STATE_DEAL
	scene.event_table._finish_event_exit()
	var source := Label.new()
	source.text = "Discard 9H · −20.000 VNĐ"
	source.size = Vector2(400, 30)
	source.position = Vector2(260, 260)
	scene.add_child(source)
	await frames()
	var caption := source.get_node_or_null("SemanticCaption") as RichTextLabel
	check(caption != null and caption.text.contains("symbol_heart.png"), "Live mixed Label uses an existing suit image")
	check(source.text == "Discard 9H · −20.000 VNĐ", "Original Label text stays available to its owner")
	check(caption.mouse_filter == Control.MOUSE_FILTER_IGNORE, "Color and icon captions cannot steal pointer input")
	source.visible_characters = 5
	await frames()
	check(caption.visible_characters == 5, "Typewriter timing is preserved")
	source.text = "Back"
	await frames()
	check(not caption.visible and source.get_theme_color("font_color").a > 0, "Plain text restores native rendering")
	source.queue_free()
	var paper_copy := Label.new()
	paper_copy.text = "+250 PTS · −500 VNĐ"
	paper_copy.size = Vector2(400, 30)
	paper_copy.add_theme_color_override("font_color", PresentationTheme.PAPER_INK)
	scene.add_child(paper_copy)
	await frames()
	var paper_caption := paper_copy.get_node("SemanticCaption") as RichTextLabel
	check(paper_caption.get_theme_color("default_color") == PresentationTheme.PAPER_INK and paper_caption.text.contains(PresentationTheme.PAPER_COST.to_html(false)) and paper_caption.text.contains(PresentationTheme.PAPER_GAIN.to_html(false)), "Paper panels use dark readable versions of the same semantic colors")
	paper_copy.queue_free()
	var button := Button.new()
	button.text = "Choose QD"
	button.position = Vector2(260, 260)
	button.size = Vector2(220, 48)
	PresentationTheme.configure_button(button)
	var presses := [0]
	button.pressed.connect(func(): presses[0] += 1)
	scene.add_child(button)
	await click(button)
	check(presses[0] == 1, "Rank-and-suit button keeps physical pointer input")
	check(button.get_node("SemanticCaption").text.contains("symbol_diamond.png"), "Button captions also use rank + suit")
	button.queue_free()
	for locale in ["en", "vi"]:
		scene.settings.set_locale(locale)
		for viewport in [Vector2i(1280, 720), Vector2i(960, 620)]:
			root.size = viewport
			await fixture("pig", 2)
			var hud = scene.zodiac_boss_hud
			check(hud.mechanic_guide.body.get_parsed_text().length() <= 95, "Pig guide is a short counter in " + locale)
			check(not hud.feedback_panel.visible, "No automatic arrival paragraph")
			check(hud.title.text == ZodiacCatalog.display_name("pig"), "Boss header is just its name")
			var before := scene.deal.snapshot_state()
			await capture("table-%s-%d" % [locale, viewport.x])
			await click(hud.detail_button)
			var book := root.get_node_or_null("GameGlossary") as GameGlossary
			check(book != null and book.layer > 850, "Details open in Handbook above game overlays")
			if book != null:
				check(book._entries[0].body.contains(ZodiacCatalog.rule_text("pig", 2)), "Full boss rule remains in Handbook")
				check(book._entries.filter(func(entry): return entry.section == "zodiac").size() == 12, "All Zodiac rules are discoverable in Handbook")
				await capture("handbook-%s-%d" % [locale, viewport.x])
				book.queue_free()
				await frames()
			check(before == scene.deal.snapshot_state(), "Presentation and Handbook do not change committed state")
			scene.deck_screen.open_deck(scene.deal.hand, "DECK", "")
			scene.deck_screen._inspect(scene.deal.hand[0])
			await frames()
			var badges := scene.deck_screen._detail.find_children("CardInfo_*", "HBoxContainer", false, false)
			check(badges.size() == 1, "Deck details have one large rank/suit badge")
			check(not scene.deck_screen._purpose.visible, "Browsing has no explanatory paragraph")
			await capture("deck-%s-%d" % [locale, viewport.x])
			await click(scene.deck_screen._detail.get_node("CardHandbook"))
			book = root.get_node_or_null("GameGlossary") as GameGlossary
			check(book != null, "Card Handbook link is clickable over the open deck")
			if book != null: book.queue_free()
			await frames()
			scene.deck_screen.close()
			scene.deal.set_current_drink(DrinkCatalog.NONE)
			check(scene.end_action_copy("settle").get_slice_count("\n") <= 2, "Strawy phase preview uses at most two lines")
			scene.deal.state = DealState.STATE_FINAL_COMMIT_WINDOW
			scene._refresh_actions()
			check(scene.settle_button.tooltip_text == scene._end_action_detail("settle"), "Nonblocking settlement tooltip retains full consequences")
			scene.strawy.open_help()
			check(scene.strawy.copy.text.length() < 60, "Strawy starts with a short action hint")
			TextReveal.finish(scene.strawy.copy)
			await capture("strawy-%s-%d" % [locale, viewport.x])
			scene.strawy.close()
	root.size = Vector2i(1280, 720)
	scene.drink_manager.test_all_drinks_available = true
	scene.run_seed_input = "TEXT-READABILITY-EVENTS"
	scene._start_campaign()
	await create_timer(0.7).timeout
	for locale in ["en", "vi"]:
		scene.settings.set_locale(locale)
		scene.event_table.unfocus_npc()
		scene.campaign._enter_phase(CampaignManager.CampaignPhase.STARTER_EVENT)
		await create_timer(0.5).timeout
		scene.event_table.focus_npc(EventTableController.NPC_TRA_DA)
		await create_timer(0.5).timeout
		var shop := scene.event_table.participants_container.get_child(0) as DrinkShop
		shop.inspect_drink(DrinkCatalog.NHAN_TRAN)
		TextReveal.finish(scene.event_table.conversation.speech)
		await frames()
		check(scene.event_table.conversation.get_rect().end.y < scene.event_table.content_panel.position.y, "Compact NPC speech clears the drink shop")
		await capture("drinks-" + locale)
		await click(shop.find_child("DrinkHandbook", true, false))
		var book := root.get_node_or_null("GameGlossary") as GameGlossary
		check(book != null and book._entries[0].body.contains(DrinkCatalog.effect_text(DrinkCatalog.NHAN_TRAN)), "Drink Handbook retains the complete selected effect")
		if book != null: book.queue_free()
		await frames()
		scene.event_table.unfocus_npc()
		scene.campaign._enter_phase(CampaignManager.CampaignPhase.MORNING_EVENT)
		await create_timer(0.5).timeout
		scene.event_table.focus_npc(EventTableController.NPC_HANG_RONG)
		await create_timer(0.5).timeout
		TextReveal.finish(scene.event_table.conversation.speech)
		await capture("relics-" + locale)
		scene.event_table.unfocus_npc()
	scene.menu_layer.show()
	scene.front_end.show_collections()
	await frames()
	await capture("collections")
	scene.menu_layer.hide()
	var receipt_layer := CanvasLayer.new()
	receipt_layer.layer = 860
	root.add_child(receipt_layer)
	var receipt = load("res://scripts/ui/resolve_receipt.gd").new()
	receipt_layer.add_child(receipt)
	var receipt_deal := DealState.new()
	receipt_deal.start_tutorial_deal()
	var scoring_cards: Array[CardData] = []
	for card in receipt_deal.hand:
		if card.rank_index == 9: scoring_cards.append(card)
	receipt_deal.create_meld(scoring_cards)
	receipt.show_report(receipt_deal.accounting_report(), "deal", "PTS / VNĐ", "CONTINUE")
	receipt._show_page("cards")
	await create_timer(0.7).timeout
	await capture("receipt")
	var paper_labels: Array = receipt.rows.find_children("*", "Label", true, false).filter(func(label): return label.get_meta("text_surface", "") == &"paper")
	check(not paper_labels.is_empty() and paper_labels.all(func(label):
		var ink: Color = label.get_theme_color("font_color")
		if ink.a < 0.05: ink = label.get_node("SemanticCaption").get_theme_color("default_color")
		return (Color("f1e8d2").srgb_to_linear().get_luminance() + 0.05) / (ink.srgb_to_linear().get_luminance() + 0.05) >= 4.5), "Rendered scoring receipt retains readable paper contrast")
	receipt_layer.queue_free()
	for failure in failures: print("TEXT_READABILITY_FAIL " + failure)
	print("TEXT_READABILITY_SMOKE checks=%d failures=%d" % [checks, failures.size()])
	scene.music.controller._stop_all_mix_players()
	scene.music.controller.music_director.stop()
	scene.queue_free()
	await frames()
	quit(0 if failures.is_empty() else 1)
