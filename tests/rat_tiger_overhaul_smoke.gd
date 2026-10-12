extends "res://tests/roster_presentation_smoke.gd"
## Real commits, all difficulties, bilingual layouts and live event choreography.

func fixture(id: String, level: int, phase: int = 1) -> void:
	scene.zodiac_boss_hud.hunt_fx.sync({}, "")
	scene.zodiac_boss_hud.hunt_board.set_expanded(false)
	await super.fixture(id, level, phase)

func top(specs: Array) -> void:
	var cards: Array[CardData] = []
	for spec in specs: cards.append(scene.deal._take_tutorial_card(spec[0], spec[1]))
	for i in range(cards.size() - 1, -1, -1): scene.deal.deck.draw_pile.append(cards[i])

func board_contract(label: String) -> void:
	var hud = scene.zodiac_boss_hud
	var board = hud.hunt_board
	check(hud.title.size.x >= hud.title.get_theme_font("font").get_string_size(hud.title.text, HORIZONTAL_ALIGNMENT_LEFT, -1, hud.title.get_theme_font_size("font_size")).x, label + " boss identity remains readable")
	check(board.is_visible_in_tree() and not hud.state_label.visible and not hud.mechanic_guide.active, label + " visible table replaces the old badge and duplicate guide")
	check(hud.panel.get_global_rect().encloses(board.get_global_rect()), label + " opponent table fits")
	check(hud.panel.size.y <= 36 and not board.terms.visible, label + " Rat and Tiger use one status row without rule prose")
	check(hud.panel.get_global_rect().encloses(board.receipt.get_global_rect()), label + " transaction fits the compact header")
	if board.terms.visible: check(board.terms.get_minimum_size().y <= board.terms.size.y, label + " terms are not cut off")
	check(board.receipt.get_theme_font("font").get_multiline_string_size(board.receipt.text, HORIZONTAL_ALIGNMENT_LEFT, -1, board.receipt.get_theme_font_size("font_size")).x <= board.receipt.size.x, label + " receipt is readable in full")
	for surface: Control in [scene.draw_pile_visual, scene.discard_pile_visual, scene.hand_layer, scene.meld_scroll, scene.campaign_money_hud.panel]:
		check(not hud.panel.get_global_rect().intersects(surface.get_global_rect()), label + " opponent table clears " + surface.name + " %s vs %s" % [hud.panel.get_global_rect(), surface.get_global_rect()])
		if board.expanded: check(not board.drawer.get_global_rect().intersects(surface.get_global_rect()), label + " Rat collection clears " + surface.name)
	if board.expanded:
		check(board.drawer.get_global_rect().encloses(board.scroll.get_global_rect()), label + " full collection fits its drawer")
		check(not board.drawer.get_global_rect().intersects(hud.panel.get_global_rect()), label + " drawer expands beside the shared card")
	if board.kind == "tiger": check(board.faces.is_empty() and not board.drawer.visible, label + " Tiger uses actual discard cards without an extra collection")
	check(scene.deal.physical_card_accounting_is_valid(), label + " physical card accounting intact")

func motion(label: String) -> void:
	if not rendered or "--capture-motion" not in OS.get_cmdline_user_args(): return
	var directory := "res://.godot/rat-tiger-overhaul/motion/" + label
	DirAccess.make_dir_recursive_absolute(directory)
	var timestamps: Array[int] = []
	var snapshots: Array[Image] = []
	for i in (22 if label == "tiger-swipe" else 18):
		await RenderingServer.frame_post_draw
		timestamps.append(Time.get_ticks_msec())
		snapshots.append(root.get_texture().get_image())
		await create_timer(0.2 if label == "tiger-swipe" else 0.1).timeout
	# PNG compression happens after the sequence so capture does not slow attacks.
	for i in snapshots.size():
		snapshots[i].resize(960, 540, Image.INTERPOLATE_LANCZOS)
		snapshots[i].save_png(directory + "/%02d.png" % i)
	var timings := FileAccess.open(directory + "/timings.json", FileAccess.WRITE)
	timings.store_string(JSON.stringify(timestamps))

func _run() -> void:
	rendered = DisplayServer.get_name() != "headless"
	capture_dir = "res://.godot/rat-tiger-overhaul/screens"
	root.size = Vector2i(1280, 720)
	scene = load("res://scenes/match.tscn").instantiate() as MatchUI
	root.add_child(scene)
	current_scene = scene
	await frames()
	scene.session.restoring = true
	scene.session.run_save = RunSave.new("user://rat-tiger-overhaul.save")
	scene.drink_manager.progress.save_path = ""
	scene.campaign.zodiac.progress = ZodiacProgress.new("")
	scene.campaign.run_seed = "rat-tiger-overhaul"
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
	await create_timer(0.6).timeout
	var hud = scene.zodiac_boss_hud
	var fx = hud.hunt_fx
	for locale in ["en", "vi"]:
		scene.settings.set_locale(locale)
		for level in [1, 2, 3]:
			await fixture("rat", level)
			top([["J", "Hearts"], ["J", "Diamonds"], ["A", "Clubs"], ["3", "Diamonds"]])
			var result := scene.deal.discard_card(scene.deal.hand[-1])
			scene._sync_all(result)
			check(result.ok and fx.effect_kind == "boss_meld", "Rat discard triggers a real owned Meld flight")
			var event: Dictionary = result.boss_events.filter(func(e: Dictionary): return e.action == "boss_meld")[0]
			check(event.transfers.size() == 3 and event.transfers.filter(func(t: Dictionary): return t.origin == "stock").size() == 2, "Rat transfers retain the exact stock/discard origins")
			check(event.amount_vnd == -99_000 and hud.hunt_board.receipt.text.contains("99.000"), "Rat receipt is the committed wallet deduction")
			check(hud.hunt_board.faces.size() == 3 and scene.deal.boss_melds.size() == 1, "all owned physical cards are on the table")
			check(not hud.hunt_board.expanded and not hud.hunt_board.drawer.visible and hud.panel.size.y <= 36, "Rat starts in a single row with optional overview hidden")
			check(event.borrowed_count == level + 1 and event.returned_count == level - 1, "difficulty-specific loans and returns are exact")
			var stable := scene.deal.snapshot_state()
			var count: int = fx.flights.size()
			scene._sync_all(result)
			check(fx.flights.size() == count and fx._queue.is_empty(), "duplicate sync cannot replay the transaction")
			await frames()
			check(stable == scene.deal.snapshot_state(), "choreography cannot change RNG, wallet, cards or rules")
			if level == 2 and locale == "en": await motion("rat-claim")
			await click(hud.hunt_board.expand_button)
			check(hud.hunt_board.expanded and hud.hunt_board.scroll.is_visible_in_tree(), "Melds button expands the actual Rat collection")
			for extent in [Vector2i(1280, 720), Vector2i(960, 620), Vector2i(1920, 1080)]:
				root.size = extent
				await create_timer(0.2).timeout
				await frames(5)
				if locale == "en" and level == 1 and extent == Vector2i(1280, 720): await capture("rat-layout")
				board_contract("Rat %s %d %s" % [locale, level, extent])
				if extent == Vector2i(960, 620) and level == 3: await capture("rat-%s-small" % locale)
			root.size = Vector2i(1280, 720)
			await create_timer(2.0).timeout
			check(fx.effect_kind.is_empty() and fx.flights.is_empty(), "Rat flights clean up")
			scene.deal.restore_snapshot(stable)
			scene._sync_all()
			check(fx.effect_kind.is_empty() and hud.hunt_board.faces.size() == 3, "restore shows owned cards without replaying loss")
			await capture("rat-%s-owned" % locale)
			await click(hud.hunt_board.expand_button)
			await frames()
			check(not hud.hunt_board.expanded and not hud.hunt_board.drawer.visible and hud.panel.size.y <= 36, "collapse hides the overview and gives its lane back to the table")
			await capture("rat-%s-compact" % locale)
			board_contract("Rat compact %s %d" % [locale, level])
			# Actual table selection and Extend button, including the money receipt.
			var owned: MeldState = scene.deal.boss_melds[0]
			var owned_view: MeldView = scene.card_table.meld_views[owned.meld_id]
			check(owned_view.rat_owned and owned_view.get_node("RatOwnedMeld").material is ShaderMaterial, "Rat-owned Meld has an ownership shader on the real table")
			check(owned_view._title.text.begins_with(ZodiacCatalog.words("RAT · ", "TÝ · ")) and PresentationTheme.zodiac_color("rat").b > PresentationTheme.zodiac_color("rat").r, "Rat identity is blue and names ownership")
			var jack := extra_card("J", "Spades")
			scene._sync_all()
			var delta := scene.deal.preview_extension_payout(owned, [jack] as Array[CardData])
			var before_wallet := scene.deal.wallet.balance_vnd
			scene.meld_scroll.ensure_control_visible(owned_view)
			await frames()
			await click(scene.card_table.hand_views[jack.unique_id])
			await click(owned_view)
			check(scene.interactions.selected_meld_id == owned.meld_id and not scene.extend_button.disabled and scene.status_label.text.contains(VndWallet.format_vnd(VndWallet.points_to_vnd(delta.points, scene.deal.vnd_per_point))), "Rat selection retains its target and shows the authoritative Extension preview")
			var drag := CardDragPayload.new(CardDragPayload.SOURCE_HAND, -1, jack.unique_id, [jack] as Array[CardData])
			var target := scene.card_table.drop_target_at(owned_view.get_global_rect().get_center())
			check(target.get("meld_id", -1) == owned.meld_id and scene.interactions.cards_for_drop_target(drag, target) == [jack], "Rat-owned Meld resolves an actual legal drag target")
			await click(scene.extend_button)
			check(owned.cards.has(jack) and scene.deal.boss_melds.has(owned) and scene.deal.melds.is_empty() and not scene.deal.hand.has(jack), "pointer Extend adds the player's card without transferring Rat ownership")
			check(scene.deal.wallet.balance_vnd - before_wallet == VndWallet.points_to_vnd(delta.points, scene.deal.vnd_per_point) and scene.deal.action_history[-1].action == "extension", "pointer Extension pays through the normal delta and milestone pipeline")
			var receipt_deadline := Time.get_ticks_msec() + 12000
			while scene.money_playback.running and Time.get_ticks_msec() < receipt_deadline:
				scene.money_presentation.request_fast_forward()
				await frames()
			check(scene.deal.physical_card_accounting_is_valid() and owned_view.rat_owned, "paid Extension retains physical accounting and ownership effects")
			await capture("rat-%s-player-extension" % locale)
			# Tiger events are grouped into one swipe for all committed copies.
			await fixture("tiger", level)
			hud.present_events(scene.deal.zodiac_boss.take_events())
			check(fx.effect_kind == "tiger_swipe" and fx.flights.size() == [1, 1, 3][level - 1], "Tiger arrival swipes actual removed cards")
			var removed: Array = scene.deal.zodiac_boss.data.removed_ids
			check(fx.flights.all(func(f: Dictionary): return f.card_id in removed and f.ink is ShaderMaterial), "every Tiger slash belongs to a committed removed card")
			check(fx.hand_staging and scene.card_table.hand_views.size() == 10 and scene.interactions.locked, "Tiger presents the full ten-card hand before acting and blocks early input")
			await create_timer(0.65).timeout
			check(removed.all(func(id: String): return scene.card_table.hand_views[id].is_visible_in_tree()) and not fx._swipe_started, "all targeted cards remain visible during the reading hold")
			check(fx.flights.all(func(f: Dictionary): return f.face.modulate.a == 0), "no stolen-card ghost moves before the full hand is shown")
			check(not hud.feedback_panel.visible and not hud.hunt_board.scroll.visible and scene.card_table.discard_count_label.text.contains("0"), "Tiger does not announce or display stolen cards before the swipe")
			await capture("tiger-%s-full-hand" % locale)
			if locale == "en" and level == 3: await motion("tiger-swipe")
			while fx.hand_staging and not fx._swipe_started: await process_frame
			await frames()
			if fx.hand_staging:
				check(hud.hunt_board.receipt.text.contains(ZodiacCatalog.words("Tiger swipes", "Dần vồ")) and not hud.hunt_board.receipt.text.contains(ZodiacCatalog.words("Your turn", "Đến lượt bạn")), "Tiger's attack state does not promise input before the swipe finishes")
			for extent in [Vector2i(1280, 720), Vector2i(960, 620), Vector2i(1920, 1080)]:
				root.size = extent
				await create_timer(0.2).timeout
				await frames(5)
				board_contract("Tiger %s %d %s" % [locale, level, extent])
			root.size = Vector2i(1280, 720)
			await capture("tiger-%s-snatch" % locale)
			# A real next-turn discard generates a new strike, then restores input normally.
			await create_timer(3.6).timeout
			check(not fx.hand_staging and not scene.card_table.hand_staged and not scene.interactions.boss_presentation_locked, "Tiger finishes with committed hand and releases presentation input gate")
			check(hud.hunt_board.receipt.text.contains(ZodiacCatalog.words("Your turn", "Đến lượt bạn")), "Tiger announces the player turn only after input returns")
			result = scene.deal.discard_card(scene.deal.hand[-1])
			scene._sync_all(result)
			check(result.ok and fx.effect_kind == "tiger_swipe", "refill at next turn produces a fresh swipe")
			stable = scene.deal.snapshot_state()
			scene.score_overlay.show()
			await frames()
			var time: float = fx.effect_time
			await create_timer(0.1).timeout
			check(not fx.is_visible_in_tree() and time == fx.effect_time, "money receipt pauses swipe timing")
			scene.score_overlay.hide()
			await create_timer(0.1).timeout
			await frames()
			check(fx.is_visible_in_tree() and fx.effect_time > time, "swipe resumes after receipt")
			scene.modal_overlay.show()
			await frames()
			check(fx.effect_kind.is_empty() and fx.flights.is_empty(), "modal clears ghosts and queued attacks")
			scene.modal_overlay.hide()
			check(stable == scene.deal.snapshot_state(), "modal cleanup cannot affect Tiger outcomes")
		# Rat extends the player's actual Meld, never fabricating an owned Meld.
		await fixture("rat", 2)
		var made := scene.deal.create_meld(scene.deal.hand.slice(0, 3))
		scene._sync_all(made)
		var seven := extra_card("7", "Hearts")
		top([["A", "Clubs"], ["3", "Diamonds"], ["8", "Clubs"]])
		scene._sync_all()
		var result := scene.deal.discard_card(seven)
		scene._sync_all(result)
		check(fx.effect_kind == "boss_extension" and scene.deal.boss_melds.is_empty(), "Rat extension targets player ownership")
		check(hud.hunt_board._full_receipt.contains("#%d" % made.meld_id), "expanded receipt identifies the extended player Meld")
		await frames()
		check(fx._destination(fx.flights[0]) == scene.card_table.meld_views[made.meld_id].get_scoring_card_control(seven.unique_id).get_global_rect().get_center() - fx.global_position, "extension flight lands on the actual added card in the player Meld")
		var view: MeldView = scene.card_table.meld_views[made.meld_id]
		check(view.get_scoring_card_control(seven.unique_id).get_node_or_null("SwayFace/RatAddedCard") != null, "Rat-added card has its own persistent shader")
		check(view._card_views.keys().filter(func(id: String): return id != seven.unique_id).all(func(id: String): return view._card_views[id].get_node_or_null("SwayFace/RatAddedCard") == null), "ordinary player cards do not inherit Rat marks")
		var extension_snapshot := scene.deal.snapshot_state()
		scene.deal.restore_snapshot(extension_snapshot)
		scene._sync_all()
		check(view.get_scoring_card_control(seven.unique_id).get_node("SwayFace/RatAddedCard").visible, "Rat card shader survives restore")
		if locale == "en": await motion("rat-extension")
		await capture("rat-%s-extension" % locale)
		await fixture("rat", 2)
		top([["A", "Clubs"], ["3", "Diamonds"], ["8", "Clubs"]])
		result = scene.deal.discard_card(scene.deal.hand[-1])
		scene._sync_all(result)
		check(fx.effect_kind == "mouse_borrow_returned" and fx.flights.size() == 3, "failed search returns actual loan count")
		check(fx.flights.all(func(f: Dictionary): return f.returning and f.face.texture.resource_path.ends_with("red_backing.png")), "unused stock identities stay concealed")
		await capture("rat-%s-returned" % locale)
		# Collections and full 13-card runs stay reachable through horizontal scrolling.
		await fixture("rat", 2)
		for rank in ["2", "3", "4", "5", "8", "10"]:
			var cards: Array[CardData] = []
			for suit in ["Hearts", "Clubs", "Diamonds"]:
				var card := extra_card(rank, suit)
				scene.deal.boss_discard_card(card, "fixture")
				cards.append(card)
			scene.deal.boss_commit_meld(cards, -1, "rat")
		scene._sync_all()
		await frames()
		check(hud.hunt_board.faces.size() == 18 and hud.hunt_board.collection.get_child_count() == 6, "collection includes every owned Meld")
		await click(hud.hunt_board.expand_button)
		hud.hunt_board.reveal_cards(hud.hunt_board.faces.keys().slice(-1))
		await frames()
		check(hud.hunt_board.scroll.scroll_horizontal > 0, "overflowing Rat collection scrolls to its newest cards")
		await capture("rat-%s-collection" % locale)
		await click(hud.detail_button)
		var book := root.get_node_or_null("GameGlossary") as GameGlossary
		check(book != null and book._entries[0].body.contains("#"), "rule button retains keyboard-accessible inspection")
		if book != null: await click(book.find_child("CloseHandbook", true, false))
		await fixture("rat", 2)
		var long_run: Array[CardData] = []
		for rank in DeckManager.RANKS:
			var card := extra_card(rank, "Hearts")
			scene.deal.boss_discard_card(card, "fixture")
			long_run.append(card)
		scene.deal.boss_commit_meld(long_run, -1, "rat")
		scene._sync_all()
		await click(hud.hunt_board.expand_button)
		check(hud.hunt_board.expanded and hud.hunt_board.scroll.is_visible_in_tree() and hud.hunt_board.faces.size() == 13, "expanded Rat collection retains all thirteen real cards")
		hud.hunt_board.reveal_cards([long_run[-1].unique_id])
		await frames()
		check(hud.hunt_board.scroll.get_global_rect().encloses(hud.hunt_board.faces[long_run[-1].unique_id].get_global_rect()), "last card in a long Rat Meld remains reachable: %s inside %s" % [hud.hunt_board.faces[long_run[-1].unique_id].get_global_rect(), hud.hunt_board.scroll.get_global_rect()])
		await capture("rat-%s-long-run" % locale)
		var escape := InputEventKey.new()
		escape.keycode = KEY_ESCAPE
		escape.physical_keycode = KEY_ESCAPE
		escape.pressed = true
		check(escape.is_action_pressed("ui_cancel"), "Escape fixture matches the actual physical-key binding")
		root.push_input(escape, true)
		await frames()
		escape.pressed = false
		root.push_input(escape, true)
		check(not hud.hunt_board.expanded, "Escape collapses Rat melds")
	await fixture("ox", 2)
	scene.settings.set_locale("en")
	hud.refresh()
	check(hud.title.text == "BUFFALO" and not hud.hunt_board.visible and fx.effect_kind.is_empty(), "Buffalo name and boss-switch cleanup")
	# Real pointer flow includes the deadwood receipt and its input release calls.
	await fixture("tiger", 2)
	scene.deal.zodiac_boss.take_events()
	scene._on_card_pressed(scene.deal.hand[-1])
	await click(scene.discard_button)
	var deadline := Time.get_ticks_msec() + 12000
	while scene.money_playback.running and Time.get_ticks_msec() < deadline:
		scene.money_presentation.request_fast_forward()
		await frames()
	await frames()
	check(fx.hand_staging and scene.card_table.hand_views.size() == 10 and scene.interactions.locked, "pointer discard retains full hand and input gate after real receipt releases its lock")
	var protected := scene.deal.snapshot_state()
	scene._on_card_pressed(scene.deal.hand[0])
	check(scene.interactions.selected_ids.is_empty() and protected == scene.deal.snapshot_state(), "pointer input cannot play through Tiger's staged hand")
	while fx.hand_staging and Time.get_ticks_msec() < deadline: await process_frame
	check(not fx.hand_staging and not scene.interactions.locked and not scene.sort_button.disabled, "actual pointer flow returns normal control after Tiger")
	check(scene.card_table.hand_views.size() == scene.deal.hand.size(), "staged-only cards are removed from the final hand view")
	scene.menu_layer.show()
	await frames()
	check(not hud.visible and fx.flights.is_empty(), "menu clears all attacks")
	print("RAT_TIGER_OVERHAUL_SMOKE checks=%d failures=%d rendered=%s" % [checks, failures.size(), rendered])
	scene.queue_free()
	await frames()
	quit(0 if failures.is_empty() else 1)
