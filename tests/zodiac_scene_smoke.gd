extends SceneTree
## Rendered integration smoke. Never writes the player's run or permanent profile.
var failures: Array[String] = []
var checks := 0

func _initialize() -> void:
	call_deferred("_run")

func _check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures.append(message)
		push_error(message)

func _frames(count: int = 3) -> void:
	for _i in count: await process_frame

func _click(control: Control) -> void:
	var point := control.get_global_rect().get_center()
	for pressed in [true, false]:
		var event := InputEventMouseButton.new()
		event.button_index = MOUSE_BUTTON_LEFT
		event.position = point
		event.global_position = point
		event.pressed = pressed
		Input.parse_input_event(event)
		await process_frame

func _run() -> void:
	root.size = Vector2i(1280, 720)
	var scene := load("res://scenes/match.tscn").instantiate() as MatchUI
	root.add_child(scene)
	current_scene = scene
	await _frames()
	scene._restoring_run = true
	scene.drink_manager.progress.save_path = ""
	scene.campaign.zodiac.progress = ZodiacProgress.new("")
	scene.run_save = RunSave.new("user://zodiac_smoke_unused.save")
	scene.game_started = true
	scene.menu_layer.hide()
	scene.game_layer.position = Vector2.ZERO
	scene.game_layer.show()
	var title := scene.get_node_or_null("TitleScreen")
	if title != null: title.hide()
	var service := scene.campaign.zodiac
	service.progress.commit("cat", "smoke", {}, ["emblem_unlocked"])
	service.choose_emblem(0, "cat")
	scene.run_seed_input = "zodiac-ui-smoke"
	scene._start_campaign()
	await _frames(40)
	scene.event_table.unfocus_npc()
	var table: Control = scene.zodiac_table
	table.refresh()
	_check(table.visible, "Zodiac table appears in campaign")
	_check(table.portrait.texture != null and table.portrait.texture.resource_path == ZodiacCatalog.DEFINITIONS[service.active_id()].sprite, "boss sprite loaded")
	_check(table.portrait.material is ShaderMaterial, "animal has animated spirit shader")
	var start_y: float = table.portrait.position.y
	await _frames(12)
	_check(not is_equal_approx(table.portrait.position.y, start_y), "animal floats at the blue chair")
	await _capture("zodiac_idle")
	for locale in ["en", "vi"]:
		TranslationServer.set_locale(locale)
		if locale == "en": await _click(table.badge)
		else: table.open_conversation()
		await _frames()
		_check(table.shade.visible, "request can open during an event: " + locale)
		_check(table.mechanics.text.contains("5.000") if locale == "vi" else table.mechanics.text.contains("5,000"), "cost is explicit: " + locale)
		_check(table.choices.get_child_count() == 4, "two core responses, one encounter option, and history rendered")
		_check(not table.badge.get_global_rect().intersects(scene.event_table.back_button.get_global_rect()), "animal hitbox clears EVENT Back: " + locale)
		_check(table.shade.get_global_rect().encloses(table.body.get_global_rect()), "conversation body fits viewport: " + locale)
		await _capture("zodiac_request_" + locale)
	# Genuine response button -> service -> wallet/history -> presentation.
	await _click(table.choices.get_child(1))
	await _frames()
	_check(int(service.daily.successes) == 1, "UI refusal commits interpreted success")
	_check(scene.deal.wallet.balance_vnd == 25000, "UI refusal keeps wallet intact")
	await _click(table.close_button)
	_check(not table.shade.visible and is_equal_approx(scene.event_table.modulate.a, 1.0), "closing conversation restores EVENT table visibility")
	# Longer promises and card/relic selectors must not push actions out of the panel.
	for slot in [1, 2, 3]:
		var event_phases := [CampaignManager.CampaignPhase.STARTER_EVENT, CampaignManager.CampaignPhase.MORNING_EVENT, CampaignManager.CampaignPhase.NOON_EVENT, CampaignManager.CampaignPhase.AFTERNOON_EVENT]
		scene.campaign._enter_phase(event_phases[slot])
		await _frames(30)
		table.open_conversation()
		await _frames()
		_check(table.body.get_global_rect().encloses(table.choices.get_global_rect()), "response buttons fit event " + str(slot))
		_check(table.shade.get_global_rect().encloses(table.close_button.get_global_rect()), "close remains onscreen in event " + str(slot))
		if slot == 2:
			(table.card_select_button as Button).pressed.emit()
			await _frames()
			_check(scene.deck_screen.visible and scene.deck_screen._cards.size() == 52, "zodiac uses shared physical deck")
			var first_card: CardData = scene.campaign.gieo_que.persistent_deck[0]
			scene.deck_screen._inspect(first_card)
			_check(scene.deck_screen._selected == first_card, "deck inspection shows chosen physical card")
			scene.deck_screen._choose()
			await _frames()
			_check(table.selected_card_id == first_card.unique_id and not scene.deck_screen.visible, "zodiac receives shared deck selection")
			await _capture("zodiac_card_cost")
		table._close_conversation()
	table._close_conversation()
	# Route through the authored noon-event handoff before entering the closing track.
	scene.campaign._enter_phase(CampaignManager.CampaignPhase.NOON_EVENT)
	scene.campaign._enter_phase(CampaignManager.CampaignPhase.EVENING_DEAL)
	await _frames(60)
	_check(scene.deal.zodiac_boss.id == "cat", "evening request configures selected Cat")
	_check(scene.deal.zodiac_boss.locked_ids.is_empty(), "Cat Phase 1 inactive")
	# Play ordinary mandatory discards and settlement, including optional tea handling.
	while scene.deal.state == DealState.STATE_ACTIVE:
		if scene.deal.tra_da_extra_discard_pending: scene.deal.end_turn_without_tra_da_extra()
		else: scene.deal.discard_card(scene.deal.hand[-1])
	scene.deal.settle_phase()
	if scene.deal.state == DealState.STATE_PHASE_CHOICE: scene.deal.choose_phase_two(false)
	scene._sync_all()
	table.refresh()
	await _frames()
	_check(scene.deal.current_phase == 2, "real Phase 2 transition")
	_check(scene.deal.zodiac_boss.locked_ids.size() == 2, "neutral Cat locks two cards")
	var lock_views := 0
	for view: PlayingCardView in scene.hand_views.values():
		if view.zodiac_locked:
			lock_views += 1
			_check(view.get_node("CatLock").visible, "lock treatment visible without hiding card face")
	_check(lock_views == 2, "exactly two card lock views")
	var saved := scene.run_save.capture(scene.campaign, scene.deal)
	var locks: Array = scene.deal.zodiac_boss.locked_ids.duplicate()
	_check(scene.run_save.restore(saved, scene.campaign, scene.deal), "mid-boss checkpoint restores")
	scene._sync_all()
	_check(scene.deal.zodiac_boss.locked_ids == locks, "restoring presentation does not reroll locks")
	await _capture("zodiac_cat_locks")
	# Special-scene presentation reaches permanent unlock only on its final page.
	service.progress.records.cat.erase("emblem_unlocked")
	service.progress.commit("cat", "scene-ready", {}, ["special_scene_unlocked"])
	scene.campaign._enter_phase(CampaignManager.CampaignPhase.AFTERNOON_EVENT)
	await _frames(40)
	table.open_conversation()
	table.scene_page = 0
	table._show_scene()
	_check(not service.progress.owns("cat"), "opening scene does not grant emblem")
	for _i in 3: table.choices.get_child(0).pressed.emit()
	_check(service.progress.owns("cat"), "last scene choice grants permanent emblem")
	_check(service.progress.record("cat").special_scene_completed, "scene completion recorded")
	# Rooster closed-register presentation and both language layouts.
	service.daily.id = "rooster"
	scene.campaign._enter_phase(CampaignManager.CampaignPhase.EVENING_DEAL)
	await _frames(50)
	scene.deal.zodiac_boss.mandatory_discard(1, 4)
	table.refresh()
	_check(not table.visible, "Zodiac visitor stays on EVENT screens only")
	_check(scene.deal.zodiac_boss.register_closed, "Rooster register closes in the deal")
	await _capture("zodiac_rooster_closed")
	scene.campaign._enter_phase(CampaignManager.CampaignPhase.AFTERNOON_EVENT)
	await _frames(30)
	scene.event_table.unfocus_npc()
	table.refresh()
	for viewport_size in [Vector2i(1280, 720), Vector2i(1920, 1080)]:
		root.size = viewport_size
		await _frames()
		_check(Rect2(Vector2.ZERO, Vector2(root.size)).encloses(table.badge.get_global_rect()), "badge stays onscreen at " + str(viewport_size))
	scene.queue_free()
	await _frames()
	print("ZODIAC_SCENE_SMOKE checks=%d failures=%d" % [checks, failures.size()])
	quit(0 if failures.is_empty() else 1)

func _capture(label: String) -> void:
	if DisplayServer.get_name() == "headless": return
	await RenderingServer.frame_post_draw
	DirAccess.make_dir_recursive_absolute("res://.godot/zodiac_validation")
	root.get_texture().get_image().save_png("res://.godot/zodiac_validation/%s.png" % label)
