extends "res://tests/boss_presentation_smoke.gd"
const View := preload("res://scripts/ui/zodiac_presentation.gd")

func extra_card(rank: String, suit: String) -> CardData:
	for card in scene.deal.hand:
		if card.rank == rank and card.suit == suit: return card
	var card := scene.deal._take_tutorial_card(rank, suit)
	scene.deal.hand.append(card)
	return card

func table_contract(label: String) -> void:
	var hud = scene.zodiac_boss_hud
	check(hud.state_label.get_theme_font("font").get_string_size(hud.state_label.text, HORIZONTAL_ALIGNMENT_LEFT, -1, hud.state_label.get_theme_font_size("font_size")).x <= hud.state_label.size.x + 1, label + " badge state is complete")
	check(hud.panel.get_global_rect().end.x <= hud.mechanic_guide.get_global_rect().position.x or not hud.mechanic_guide.active, label + " guide clears badge")
	if hud.mechanic_guide.active:
		var guide = hud.mechanic_guide
		check(guide.is_visible_in_tree(), label + " mechanic guidance visible")
		check(guide.get_global_rect().end.y <= scene.meld_scroll.get_global_rect().position.y + 1, label + " Melds below guidance")
		check(guide.body.get_content_height() <= guide.lane_height, label + " guide retains complete text")
		for surface: Control in [scene.campaign_money_hud.panel, scene.draw_pile_visual, scene.discard_pile_visual, scene.hand_layer, scene.meld_scroll]:
			check(not guide.get_global_rect().intersects(surface.get_global_rect()), label + " guide clears " + surface.name)
		if guide.commands.visible:
			for command: Button in guide.commands.get_children():
				check(command.get_theme_font("font").get_string_size(command.text, HORIZONTAL_ALIGNMENT_LEFT, -1, command.get_theme_font_size("font_size")).x <= guide.size.x, label + " whole Snake command fits")
	for card in scene.deal.hand:
		var hint: Dictionary = View.hand_hint(scene.deal.zodiac_boss, card, scene.deal.hand)
		var control: PlayingCardView = scene.card_table.hand_views[card.unique_id]
		check(control._zodiac_cue != null and control._zodiac_cue.visible if not hint.is_empty() else control._zodiac_cue == null or not control._zodiac_cue.visible, label + " physical card cue scoped correctly")
		if not hint.is_empty():
			check(control._zodiac_cue.surface.material is ShaderMaterial and control._zodiac_cue.mouse_filter == Control.MOUSE_FILTER_IGNORE, label + " shader keeps physical card input")
	if scene.deal.zodiac_boss.id == "dragon":
		check(scene.campaign_period_value.text == ZodiacCatalog.words("DRAGON", "THÌN") and scene.campaign_period_icon.visible, label + " Dragon endgame is named in header")
		for surface: Control in [scene.campaign_money_hud.panel, scene.draw_pile_visual, scene.discard_pile_visual, scene.hand_layer, scene.meld_scroll, scene.get_node("GameLayer/UtilityRail/RelicsArea"), scene.get_node("GameLayer/ActionDock"), hud.panel, hud.mechanic_guide]:
			check(not hud.evening_overlay.get_global_rect().intersects(surface.get_global_rect()), label + " Dragon portrait clears " + surface.name)
	check(scene.deal.physical_card_accounting_is_valid(), label + " physical zones intact")

func _run() -> void:
	rendered = DisplayServer.get_name() != "headless"
	capture_dir = "res://.godot/roster-ui/screens"
	root.size = Vector2i(1280, 720)
	scene = load("res://scenes/match.tscn").instantiate() as MatchUI
	root.add_child(scene)
	current_scene = scene
	await frames()
	scene.session.restoring = true
	scene.session.run_save = RunSave.new("user://roster-presentation.save")
	scene.drink_manager.progress.save_path = ""
	scene.campaign.zodiac.progress = ZodiacProgress.new("")
	scene.campaign.run_seed = "roster-presentation"
	scene.campaign.current_day_index = 0
	scene.campaign.difficulty_progress.unlocked = 2
	scene.campaign.select_difficulty(2)
	scene.campaign.gieo_que.reset_campaign()
	scene.game_started = true
	scene.menu_layer.hide()
	scene.game_layer.position = Vector2.ZERO
	scene.game_layer.show()
	scene.event_table.table_state = EventTableController.TABLE_STATE_DEAL
	scene.event_table._finish_event_exit()
	var hud = scene.zodiac_boss_hud
	for locale in ["en", "vi"]:
		scene.settings.set_locale(locale)
		for id in ZodiacBossRule.RULES:
			for level in [1, 2, 3]:
				await fixture(id, level, 2 if id == "cat" else 1)
				if id == "dragon": scene.campaign.current_phase = CampaignManager.CampaignPhase.DRAGON_DEAL
				var before := scene.deal.zodiac_boss.snapshot()
				for _i in 3: scene._sync_all(); hud.refresh()
				check(before == scene.deal.zodiac_boss.snapshot(), "%s refresh cannot reroll or mutate" % id)
				for extent in [Vector2i(1280, 720), Vector2i(960, 620), Vector2i(1920, 1080)]:
					root.size = extent
					await frames(5)
					table_contract("%s %s %d %s" % [locale, id, level, extent])
					if extent == Vector2i(1280, 720) and level == 3: await capture("%s-%s" % [id, locale])
				root.size = Vector2i(1280, 720)
		# Pig shows the exact held pool, gross goal and actual return.
		await fixture("pig", 2)
		var first := scene.deal.create_meld(scene.deal.hand.slice(0, 3))
		scene._sync_all(first)
		await frames()
		check(hud.state_label.text.contains("13.500") and hud.mechanic_guide.body.get_parsed_text().contains("45.000"), "Pig pool and gross progress remain visible once each")
		check(is_equal_approx(hud.mechanic_guide.meter.material.get_shader_parameter("progress"), 0.9), "Pig progress shader reads actual goal")
		await capture("pig-%s-held" % locale)
		var second := scene.deal.create_meld(scene.deal.hand.slice(0, 3))
		scene._sync_all(second)
		check(scene.deal.zodiac_boss.data.target_met and scene.deal.zodiac_boss.data.pool_vnd == 0 and hud.state_label.text.contains("0 VNĐ"), "Pig returned pool clears visible amount")
		# Ox previews the authoritative next penalty, including Near-Meld severity.
		await fixture("ox", 3)
		var held := scene.deal.hand[0]
		var old_hint := View.hand_hint(scene.deal.zodiac_boss, held, scene.deal.hand)
		var discarded := scene.deal.discard_card(scene.deal.hand[-1])
		scene._sync_all(discarded)
		await frames()
		var next_hint := View.hand_hint(scene.deal.zodiac_boss, held, scene.deal.hand)
		var actual_points: int = preload("res://scripts/zodiac/rules/ox.gd").new().burden_points(held.score_value(), int(scene.deal.zodiac_boss.data.burden_age[held.unique_id]) + 1, MeldRules.near_meld_ids(scene.deal.hand).has(held.unique_id), 3)
		check(next_hint.caption == "−%d" % actual_points and next_hint.caption != old_hint.caption, "Ox next-card burden uses real formula and ages")
		await capture("ox-%s-carried" % locale)
		var meld_result := scene.deal.create_meld(scene.deal.hand.slice(0, 3))
		scene._sync_all(meld_result)
		check(not scene.card_table.hand_views.has(held.unique_id), "Ox cue leaves hand with committed card")
		# Horse counter follows committed pairs and real phase turn limits.
		await fixture("horse", 3)
		for i in 2:
			meld_result = scene.deal.create_meld(scene.deal.hand.slice(0, 3))
			scene._sync_all(meld_result)
			check(hud.mechanic_guide.body.get_parsed_text().contains("%d/2" % (i + 1)), "Horse actual pair count appears")
		check(scene.discard_history_row.get_children().filter(func(node: Node): return node.has_meta("turn_number")).size() == 4, "Horse hard mode shows two actual turns per Phase")
		await capture("horse-%s-pair" % locale)
		# Goat marks the next committed Rank and never advances on a miss.
		await fixture("goat", 2)
		meld_result = scene.deal.create_meld(scene.deal.hand.slice(0, 3))
		scene._sync_all(meld_result)
		var seven := extra_card("7", "Hearts")
		scene._sync_all()
		check(scene.card_table.hand_views[seven.unique_id]._zodiac_cue.visible and hud.mechanic_guide.body.get_parsed_text().contains("7"), "Goat next Rank visible and attached to physical card")
		var miss := scene.deal.create_meld(scene.deal.hand.slice(0, 3))
		scene._sync_all(miss)
		check(miss.context.final_points == 0 and scene.deal.zodiac_boss.data.expected_rank == 7, "Goat miss cannot fake next note")
		await capture("goat-%s-next-note" % locale)
		# Snake command selection is safe convenience; the table commits the play.
		await fixture("snake", 3)
		var policy := scene.deal.zodiac_boss.snapshot()
		var pending: Button
		for button: Button in hud.mechanic_guide.commands.get_children():
			if not button.disabled: pending = button; break
		check(pending != null, "Snake fixture has a usable pending command")
		if pending != null:
			await click(pending)
			check(policy == scene.deal.zodiac_boss.snapshot() and not scene.interactions.selected_ids.is_empty(), "command pointer selects cards without obeying or mutating rules")
			var selected := scene.interactions.selected_cards()
			meld_result = scene.deal.create_meld(selected)
			check(meld_result.ok, "selected Snake command uses normal Meld API")
			scene._sync_all(meld_result)
			check(scene.deal.zodiac_boss.data.commands.any(func(command: Dictionary): return command.action == "new_meld" and command.status == "fulfilled"), "normal commit fulfills real command")
		await capture("snake-%s-command" % locale)
		# More than two stolen Melds remain reachable in the normal rule drawer.
		await fixture("rat", 2)
		for rank in ["2", "3", "8"]:
			var cards: Array[CardData] = []
			for suit in ["Hearts", "Clubs", "Diamonds"]:
				var card := extra_card(rank, suit)
				scene.deal.boss_discard_card(card, "fixture")
				cards.append(card)
			check(scene.deal.boss_commit_meld(cards, -1, "rat").ok, "authoritative Mouse-owned Meld commits")
		scene._sync_all()
		await frames()
		check(hud.opponent_cards.get_child_count() == 3, "drawer exposes every Mouse Meld")
		check(hud.opponent_cards.get_child(0).find_children("*", "ColorRect", true, false).any(func(node: Node): return node.name == "RatStolenMeld"), "stolen physical cards use Mouse stitch shader")
		await click(hud.detail_button)
		var book := root.get_node_or_null("GameGlossary") as GameGlossary
		check(book != null and (book.find_child("CloseHandbook", true, false) as Button).has_focus(), "rule Handbook receives keyboard focus")
		check(book != null and book._entries[0].body.contains("#"), "Handbook includes every owned Mouse Meld")
		await capture("rat-%s-all-melds" % locale)
		if book != null: await click(book.find_child("CloseHandbook", true, false))
		await fixture("rat", 2)
		var long_run: Array[CardData] = []
		for rank in DeckManager.RANKS:
			var card := extra_card(rank, "Hearts")
			scene.deal.boss_discard_card(card, "fixture")
			long_run.append(card)
		check(scene.deal.boss_commit_meld(long_run, -1, "rat").ok, "Mouse full 13-card run commits normally")
		scene._sync_all()
		await click(hud.detail_button)
		book = root.get_node_or_null("GameGlossary") as GameGlossary
		await frames(5)
		check(book != null and long_run.all(func(card: CardData): return book._entries[0].body.contains(card.short_label())), "all 13 stolen identities remain readable in Handbook")
		check(book != null and book._body.text.get_slice_count("symbol_heart.png") - 1 == 13 and book._body.text.contains("]K[/color]"), "all 13 stolen cards use rank + suit, including the last card")
		await capture("rat-%s-long-run" % locale)
		if book != null: await click(book.find_child("CloseHandbook", true, false))
		# Every Dragon modifier projects its real mechanic onto the affected object.
		for modifier in preload("res://scripts/zodiac/rules/dragon.gd").MODIFIERS:
			await fixture("dragon", 2)
			scene.campaign.current_phase = CampaignManager.CampaignPhase.DRAGON_DEAL
			scene.deal.zodiac_boss.data.analysis = {"action": "new_meld", "meld_type": "set", "tactic": "new_meld:set", "average_vnd": 54000, "target_vnd": 54000}
			scene.deal.zodiac_boss.data.modifier_id = modifier
			scene.deal.zodiac_boss.data.modifier = {}
			ZodiacBossRule.RULES[modifier].new().dragon_begin(scene.deal.zodiac_boss, scene.deal, scene.deal.zodiac_boss.data.modifier)
			scene.deal.zodiac_boss.take_events()
			scene._sync_all()
			await frames()
			check(View.effective(scene.deal.zodiac_boss).id == modifier and hud.mechanic_guide.body.get_parsed_text().contains(ZodiacCatalog.display_name(modifier)), "Dragon exposes actual modifier " + modifier)
			check(hud.evening_overlay.texture != null and hud.evening_overlay.texture.resource_path == ZodiacCatalog.sprite_path("dragon"), "Dragon supplied portrait appears")
			check(hud.mechanic_guide.meter.material.shader.resource_path == "res://shaders/dragon_target.gdshader", "Dragon target uses its own shader")
			var before := scene.deal.zodiac_boss.snapshot()
			for _i in 2: scene._sync_all(); hud.refresh()
			check(before == scene.deal.zodiac_boss.snapshot(), "Dragon UI never rerolls " + modifier)
			table_contract("Dragon %s %s" % [locale, modifier])
			if modifier == "dog":
				var set_cards: Array[CardData] = scene.deal.hand.filter(func(card: CardData): return card.rank == "9")
				meld_result = scene.deal.create_meld(set_cards)
				scene._sync_all(meld_result)
				check(meld_result.ok and scene.card_table.meld_views[meld_result.meld_id].get_node("DogLoyalGuard").visible, "Dragon Dog guard follows curated loyal Meld")
			if modifier in ["snake", "cat", "ox", "dog"]: await capture("dragon-%s-%s" % [locale, modifier])
		for blocker: Control in [scene.modal_overlay, scene.deck_screen, scene.pile_archive.overlay, scene.menu_layer]:
			blocker.show()
			await frames()
			check(not hud.mechanic_guide.is_visible_in_tree(), "overlay clears guide " + blocker.name)
			blocker.hide()
			await frames()
	await fixture("", 2)
	check(not hud.mechanic_guide.visible and scene.meld_scroll.offset_top == hud._meld_top_offset, "daytime clears mechanic guidance and geometry")
	scene.queue_free()
	await create_timer(0.25).timeout
	print("ROSTER_PRESENTATION_SMOKE checks=%d failures=%d rendered=%s" % [checks, failures.size(), rendered])
	quit(0 if failures.is_empty() else 1)
