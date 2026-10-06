extends SceneTree
## Real committed turns, shader layers, pointer access and responsive table layout.
var failures: Array[String] = []
var checks := 0
var scene: MatchUI
var rendered := false
var capture_dir := "res://.godot/boss-presentation/screens"

func _initialize() -> void: call_deferred("_run")
func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok: failures.append(message); push_error(message)
func frames(count: int = 3) -> void:
	for _i in count: await process_frame
func capture(label: String) -> void:
	if not rendered: return
	# Direct fixture commits do not run the normal money-flight queue.
	# Render the journal's committed balance rather than an unfinished counter.
	scene.money_playback.displayed_balance = scene.deal.wallet.balance_vnd
	scene.money_playback.queued_balance = scene.money_playback.displayed_balance
	scene.money_presentation.sync_wallet(scene.money_playback.displayed_balance)
	scene._refresh_stats()
	await create_timer(0.25).timeout
	await RenderingServer.frame_post_draw
	DirAccess.make_dir_recursive_absolute(capture_dir)
	root.get_texture().get_image().save_png(capture_dir + "/" + label + ".png")
func click(control: Control) -> void:
	await frames()
	var point := control.get_global_transform_with_canvas() * (control.size * 0.5)
	for pressed in [true, false]:
		var event := InputEventMouseButton.new()
		event.button_index = MOUSE_BUTTON_LEFT
		event.position = point
		event.global_position = point
		event.pressed = pressed
		root.push_input(event, true)
		await process_frame
func fixture(id: String, level: int, phase: int = 1) -> void:
	scene.current_campaign_event = null
	scene.campaign.current_phase = CampaignManager.CampaignPhase.EVENING_DEAL
	scene.deal.wallet.reset(253000)
	scene.deal.start_tutorial_deal()
	scene.deal.set_current_drink(DrinkCatalog.NONE)
	scene.deal.current_phase = phase
	scene.deal.zodiac_boss.configure(id, level, 14281)
	scene.deal.zodiac_boss.begin_phase(scene.deal)
	scene.deal.zodiac_boss.begin_turn(phase, scene.deal.hand, scene.deal)
	scene.modal_overlay.hide()
	scene.score_overlay.hide()
	scene.interactions.locked = false
	scene.interactions.selected_ids.clear()
	scene.card_table.set_hand_interaction_enabled(true)
	scene.money_playback.displayed_balance = scene.deal.wallet.balance_vnd
	scene.money_playback.queued_balance = scene.money_playback.displayed_balance
	scene._sync_all()
	await frames()

func layout_contract(label: String) -> void:
	var hud = scene.zodiac_boss_hud
	var strip: Control = scene.get_node("GameLayer/TableSurface/DiscardHistoryHUD")
	var canvas := Rect2(Vector2.ZERO, Vector2(root.size))
	check(canvas.encloses(hud.panel.get_global_rect()), label + " boss badge fits")
	check(canvas.encloses(strip.get_global_rect()), label + " turn register fits")
	check(hud.panel.size.x <= 260 and hud.panel.size.y <= 60, label + " badge stays compact")
	check(hud.panel.get_global_rect().position.x == scene.get_node("GameLayer/Header/HeaderRow/CampaignStat").global_position.x, label + " badge aligns with day HUD")
	for surface: Control in [scene.draw_pile_visual, scene.discard_pile_visual, scene.hand_layer, scene.meld_scroll]:
		check(not hud.panel.get_global_rect().intersects(surface.get_global_rect()), label + " badge clears " + surface.name)
		check(not hud.feedback_panel.get_global_rect().intersects(surface.get_global_rect()), label + " speech clears " + surface.name)
	check(not strip.get_global_rect().intersects(scene.hand_layer.get_global_rect()), label + " turns clear the hand")
	check(not strip.get_global_rect().intersects(scene.meld_scroll.get_global_rect()), label + " turns clear the meld area")
	check(not hud.has_node("EveningBossPortrait"), label + " redundant corner sprite is removed")
	var speech_screen: Rect2 = root.get_final_transform() * hud.feedback_panel.get_global_transform_with_canvas() * Rect2(Vector2.ZERO, hud.feedback_panel.size)
	check(canvas.encloses(speech_screen), label + " speech fits viewport")
	check(hud.feedback_panel.position.y >= scene.campaign_money_hud.panel.get_global_rect().end.y, label + " speech sits below money")
	check(hud.evening_overlay.mouse_filter == Control.MOUSE_FILTER_IGNORE and hud.feedback_panel.mouse_filter == Control.MOUSE_FILTER_IGNORE, label + " decorative presence passes input")
	var slots := scene.discard_history_row.get_children().filter(func(node: Node): return node.has_meta("turn_number"))
	for slot: Control in slots:
		check(strip.get_global_rect().encloses(slot.get_global_rect()), label + " slot visible " + slot.name)
		check(slot.custom_minimum_size.x >= 40 and slot.custom_minimum_size.y >= 56, label + " cards enlarged " + slot.name)
		check(slot.get_node("TurnCard").texture != null, label + " turn is a card " + slot.name)
	var stat: PanelContainer = scene.get_node("GameLayer/Header/HeaderRow/CampaignStat")
	check((stat.get_theme_stylebox("panel") as StyleBoxFlat).bg_color.a < 0.8, label + " day HUD uses glass")
	check((scene.campaign_money_hud.panel.get_theme_stylebox("panel") as StyleBoxFlat).bg_color.a < 0.8, label + " wallet uses glass")
	check(scene.table_hud_presentation.day.text == scene.tr("DAY_MONDAY") and scene.campaign_value.text.contains("500.000") and scene.campaign_period_value.text == scene.tr("PERIOD_EVENING"), label + " canonical day goal and period remain readable")
	check(scene.campaign_period_value.size.x >= scene.campaign_period_value.get_theme_font("font").get_string_size(scene.campaign_period_value.text, HORIZONTAL_ALIGNMENT_LEFT, -1, scene.campaign_period_value.get_theme_font_size("font_size")).x, label + " period text has visible width")
	check(slots.filter(func(slot: Node): return slot.has_node("CurrentTurn")).size() == 1, label + " current turn has a text marker")

func _run() -> void:
	rendered = DisplayServer.get_name() != "headless"
	root.size = Vector2i(1280, 720)
	scene = load("res://scenes/match.tscn").instantiate() as MatchUI
	root.add_child(scene)
	current_scene = scene
	await frames()
	scene.session.restoring = true
	scene.session.run_save = RunSave.new("user://boss-presentation-%d.save" % Time.get_ticks_usec())
	scene.drink_manager.progress.save_path = ""
	scene.campaign.zodiac.progress = ZodiacProgress.new("")
	scene.campaign.run_seed = "boss-presentation"
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
		for level in [1, 2, 3]:
			await fixture("rooster", level)
			var deadline := int(ZodiacCatalog.tuning("rooster", "discard_deadline", level))
			for number in range(1, 5):
				var slot: Control = scene.discard_history_row.get_node("Phase1Turn%d" % number)
				check(slot.get_meta("turn_modifier") == ("closing" if number == deadline else "closed" if number > deadline else ""), "Rooster severity drives actual deadline")
				check(slot.has_node("RoosterRegisterAura") == (number >= deadline), "red aura matches closing register turns")
				if slot.has_node("RoosterRegisterAura"):
					check(slot.get_node("RoosterRegisterAura").material is ShaderMaterial, "Rooster uses a real shader")
				check(not scene.discard_history_row.get_node("Phase2Turn%d" % number).has_node("RoosterRegisterAura"), "Rooster does not suppress Phase 2")
			check(hud.evening_overlay.texture.resource_path == ZodiacCatalog.sprite_path("rooster", true) and hud.evening_overlay.is_visible_in_tree(), "provided Rooster overlay appears during Evening")
			await capture("rooster-%s-tier%d-open" % [locale, level])
			for number in range(1, deadline + 1):
				var result := scene.deal.discard_card(scene.deal.hand[0])
				check(result.ok, "real mandatory discard commits")
				scene._sync_all(result)
				await frames()
				var slot: Control = scene.discard_history_row.get_node("Phase1Turn%d" % number)
				check(slot.get_meta("turn_filled") and slot.has_meta("action_target_card_id"), "existing slot becomes physical discard")
				check(slot.get_node("TurnCard").texture.resource_path == scene.deal.discard_history_for_phase(1)[-1].card.texture_path(), "slot shows committed card face")
			check(scene.deal.zodiac_boss.register_closed, "register closes at real deadline")
			check(hud.feedback_panel.visible and hud.feedback.text.contains("0 VNĐ"), "Rooster announces closure")
			check(scene.deal.physical_card_accounting_is_valid(), "turn effects preserve all physical zones")
			await capture("rooster-%s-tier%d-closed" % [locale, level])
			var legal_set: Array[CardData] = []
			for card in scene.deal.hand:
				if card.rank_index == 9: legal_set.append(card)
			var wallet_before := scene.deal.wallet.balance_vnd
			var suppressed := scene.deal.create_meld(legal_set)
			check(suppressed.ok and suppressed.context.suppression_reason == "rooster_register_closed", "closed register permits a real legal Meld")
			check(scene.deal.wallet.balance_vnd == wallet_before and suppressed.context.final_points == 0, "closed register pays exactly zero")
			scene.money_feedback.queue_scoring(suppressed.context)
			scene._sync_all(suppressed)
			check(hud.feedback.text.contains("0 VNĐ"), "zero payout is explained by the boss")
			check(scene.card_table.meld_views[suppressed.meld_id]._score.text.contains("0 VNĐ") and not scene.card_table.meld_views[suppressed.meld_id]._score.text.contains("81.000"), "Rooster effect corrects the existing Meld payout display")
			check(scene.deal.physical_card_accounting_is_valid(), "zero payout presentation preserves physical zones")
			await capture("rooster-%s-tier%d-zero-payout" % [locale, level])
		await fixture("rooster", 2, 2)
		check(hud.feedback.text.contains(ZodiacCatalog.words("Scoring is open", "Lại được ghi điểm")), "Rooster announces Phase 2 scoring")
		await fixture("cat", 2, 2)
		check(hud.evening_overlay.texture.resource_path == ZodiacCatalog.sprite_path("cat", true) and hud.evening_overlay.is_visible_in_tree(), "Cat is present during Evening")
		var locked: Array[CardData] = []
		var free: CardData
		for card in scene.deal.hand:
			var view: PlayingCardView = scene.card_table.hand_views[card.unique_id]
			if scene.deal.zodiac_boss.is_locked(card):
				locked.append(card)
				check(view.has_node("CatLockSmoke") and view.get_node("CatLockSmoke").material is ShaderMaterial, "locked physical card has purple smoke")
				check(view.get_node("CatLockSmoke").visible and view.get_node("CatLockSmoke").mouse_filter == Control.MOUSE_FILTER_IGNORE, "smoke visible without taking input")
				check(view.get_node("CatLock").visible, "lock label survives shader")
			else:
				free = card
				check(not view.has_node("CatLockSmoke") or not view.get_node("CatLockSmoke").visible, "unlocked card has no smoke")
		check(locked.size() == 2, "Cat NORMAL locks two")
		var before := scene.deal.zodiac_boss.snapshot()
		for _i in 3: scene._sync_all(); hud.refresh()
		check(before == scene.deal.zodiac_boss.snapshot(), "presentation refresh never rerolls Cat")
		check(not scene.deal.discard_card(locked[0]).ok and scene.deal.hand.has(locked[0]), "Cat legality stays authoritative")
		scene._on_card_pressed(locked[0])
		check(hud.feedback.text.contains(ZodiacCatalog.words("stays with me", "ở với ta")), "touching a locked card gets Cat speech")
		scene._on_card_drag_started(locked[0], Vector2.ZERO, scene.card_table.hand_views[locked[0].unique_id])
		check(scene.interactions.drag_payload == null and scene.deal.hand.has(locked[0]), "locked drag reacts without creating a forbidden card payload")
		await capture("cat-%s-lock-smoke" % locale)
		var result := scene.deal.discard_card(free)
		scene._sync_all(result)
		await frames()
		var active_smoke := 0
		for card in scene.deal.hand:
			var view: PlayingCardView = scene.card_table.hand_views[card.unique_id]
			if view.has_node("CatLockSmoke") and view.get_node("CatLockSmoke").visible: active_smoke += 1
		check(active_smoke == scene.deal.zodiac_boss.locked_ids.size(), "next refill clears old smoke and follows new locks")
		check(hud.feedback.text.contains(ZodiacCatalog.words("mine until", "thuộc về ta")), "Cat announces each actual lock turn")
		check(scene.deal.physical_card_accounting_is_valid(), "Cat effects preserve physical zones")
		scene._show_banner(ZodiacCatalog.words("Choose a card to discard.", "Chọn một lá để bỏ."))
		await frames(5)
		var strip: Control = scene.get_node("GameLayer/TableSurface/DiscardHistoryHUD")
		check(not scene.banner_panel.get_global_rect().intersects(strip.get_global_rect()) and not scene.banner_panel.get_global_rect().intersects(scene.hand_layer.get_global_rect()), "table notice clears turns and hand")
		for viewport in [Vector2i(1280, 720), Vector2i(1920, 1080), Vector2i(2548, 1368), Vector2i(960, 620)]:
			root.size = viewport
			await frames(5)
			layout_contract("%s %s" % [locale, viewport])
			await capture("cat-%s-%dx%d" % [locale, viewport.x, viewport.y])
		root.size = Vector2i(1280, 720)
		await frames()
		await click(hud.detail_button)
		var book := root.get_node_or_null("GameGlossary") as GameGlossary
		check(book != null and book._entries[0].body.contains(ZodiacCatalog.rule_text("cat", 2)), "pointer opens complete authoritative rules in Handbook")
		check(not hud.feedback_panel.visible, "speech clears while the player reads the rule")
		await capture("cat-%s-rule-drawer" % locale)
		var escape := InputEventKey.new()
		escape.keycode = KEY_ESCAPE
		escape.physical_keycode = KEY_ESCAPE
		escape.pressed = true
		root.push_input(escape, true)
		await frames()
		check(not root.has_node("GameGlossary"), "Escape closes rule Handbook")
		scene.menu_layer.show()
		await frames()
		check(not hud.visible and not hud.feedback_panel.visible, "menu clears presence and queued speech")
		scene.menu_layer.hide()
		hud.refresh()
		scene.modal_overlay.show()
		await frames()
		check(not hud.evening_overlay.visible and not hud.feedback_panel.visible, "phase modal clears decorative boss layers")
		scene.modal_overlay.hide()
		# Committed Melds remain visible above the enlarged turn register.
		await fixture("cat", 2, 1)
		var run: Array[CardData] = []
		var set_cards: Array[CardData] = []
		for card in scene.deal.hand:
			if card.suit == "Hearts" and card.rank_index in [4, 5, 6]: run.append(card)
			if card.rank_index == 9: set_cards.append(card)
		await create_timer(4.0).timeout
		for group: Array[CardData] in [run, set_cards]:
			var meld_result := scene.deal.create_meld(group)
			check(meld_result.ok, "real Meld fixture commits")
			scene._sync_all(meld_result)
			check(hud.feedback.text.contains(ZodiacCatalog.words("A neat play", "Hạ đẹp")), "Cat reacts to a paid player Meld")
		scene.deal.current_phase = 2
		scene.deal.discard_count = 0
		scene.deal.zodiac_boss.begin_phase(scene.deal)
		var drawn: Array[CardData] = scene.deal._begin_active_turn()
		scene.deal.set_current_drink(DrinkCatalog.TRA_DA)
		scene._sync_all({"drawn": drawn})
		await create_timer(0.3).timeout
		for view: MeldView in scene.card_table.meld_views.values():
			check(not view.get_global_rect().intersects(strip.get_global_rect()), "committed Meld clears turn register")
		check(scene.deal.physical_card_accounting_is_valid(), "filled table preserves physical zones")
		await capture("cat-%s-filled-table" % locale)
	await fixture("", 2)
	check(not hud.visible, "ordinary daytime table has no boss overlay")
	await create_timer(0.6).timeout
	scene.queue_free()
	await create_timer(0.25).timeout
	print("BOSS_PRESENTATION_SMOKE checks=%d failures=%d rendered=%s" % [checks, failures.size(), rendered])
	quit(0 if failures.is_empty() else 1)
