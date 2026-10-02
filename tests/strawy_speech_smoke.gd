extends SceneTree
var ui: MatchUI
var checks := 0
var failures: Array[String] = []

func _initialize() -> void: call_deferred("_run")

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok: failures.append(message); push_error(message)

func capture(label: String) -> void:
	if DisplayServer.get_name() == "headless": return
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://.godot/strawy-speech-%s-%s%s.png" % [label, ui.settings.locale_code, "-large" if "--large" in OS.get_cmdline_user_args() else ""])

func finish_text(native: bool) -> void:
	await process_frame
	await process_frame
	var point := ui.strawy.copy.get_global_transform_with_canvas() * (ui.strawy.copy.size * 0.5)
	if native:
		for down in [true, false]:
			var touch := InputEventScreenTouch.new()
			touch.position = point
			touch.pressed = down
			root.push_input(touch, true)
	for down in [true, false]:
		var mouse := InputEventMouseButton.new()
		mouse.position = point
		mouse.device = -1 if native else 0
		mouse.button_index = MOUSE_BUTTON_LEFT
		mouse.pressed = down
		root.push_input(mouse, true)

func check_speech(locale: String) -> void:
	ui.settings.set_locale(locale)
	ui.strawy.open_help()
	var before := var_to_str(ui.deal.snapshot_state())
	var text := ui.strawy.copy.text
	check(ui.strawy.copy.visible_characters == 0, "requested text begins hidden " + locale)
	check(text.contains(GameGlossary.words("choose a Drink", "gọi nước")), "first-day help explains the next action " + locale)
	await create_timer(0.15).timeout
	var size := ui.strawy.box.size
	var button_position := (ui.strawy.actions.get_child(1) as Control).position
	check(ui.strawy.copy.visible_characters > 0 and ui.strawy.copy.visible_characters < ui.strawy.copy.get_total_character_count(), "letters reveal gradually " + locale)
	await capture("partial")
	await finish_text(true)
	check(ui.strawy.copy.visible_characters == -1 and ui.strawy.copy.text == text and ui.strawy.box.visible, "native tap plus emulated mouse finishes the text without closing " + locale)
	await process_frame
	check(ui.strawy.box.size == size, "speech keeps its full layout while revealing " + locale)
	check((ui.strawy.actions.get_child(1) as Control).position == button_position, "response buttons stay still while text reveals " + locale)
	var last_button := ui.strawy.actions.get_child(-1) as Control
	check(last_button.get_global_rect().end.y <= ui.strawy.scroll.get_global_rect().end.y, "brief help shows all responses without clipping %s: button=%s scroll=%s label=%s minimum=%s font=%s spacing=%s" % [locale, last_button.get_global_rect(), ui.strawy.scroll.get_global_rect(), ui.strawy.copy.size, ui.strawy.copy.custom_minimum_size, ui.strawy.copy.get_theme_font_size("font_size"), ui.strawy.copy.get_theme_constant("line_spacing")])
	await capture("help")
	ui.strawy.open_help()
	await finish_text(false)
	check(ui.strawy.copy.visible_characters == -1, "ordinary mouse can finish the text " + locale)
	ui.settings.set_locale("vi" if locale == "en" else "en")
	check(ui.strawy.copy.visible_characters == 0 and ui.strawy.copy.text != text, "changing language replaces and restarts speech")
	ui.settings.set_locale(locale)
	check(ui.strawy.copy.text == text and ui.strawy.copy.visible_characters == 0, "rapid replacements cannot finish newer speech early")
	ui.strawy.start_tour()
	check(ui.strawy.tour.size() > 1 and ui.strawy.copy.visible_characters == 0, "tour explanations also use typewriter text " + locale)
	for step in ui.strawy.tour:
		check(step.text.length() > 35, "NPC tour describes the service rather than only naming it " + locale)
	var old_target: Control = ui.strawy.tour[0].control
	var next := ui.strawy.actions.get_child(1) as Button
	next.pressed.emit()
	check(ui.strawy.tour_index == 1 and ui.strawy.copy.text.begins_with("2/") and ui.strawy.copy.visible_characters == 0, "Next immediately replaces unfinished text with the next explanation " + locale)
	check(ui.strawy.pointer.targets[0] != old_target and ui.event_table.focused_npc_id.is_empty(), "advancing a tour points without opening a service " + locale)
	await create_timer(2.1).timeout
	check(ui.strawy.copy.visible_characters == -1, "typewriter completes promptly " + locale)
	await capture("tour")
	check(var_to_str(ui.deal.snapshot_state()) == before, "help and typing leave cards, wallet and RNG unchanged " + locale)
	for npc in EventTableController.NPC_DATA:
		check(ui.strawy._npc_guidance(npc).length() > ui.event_table.npc_display_name(npc).length() + 25, "every visitor has brief service guidance " + locale)
	ui.strawy.open_help()
	ui.strawy.close()
	await create_timer(0.15).timeout
	check(not ui.strawy.box.visible and ui.strawy.speech_reveal == null and ui.strawy.copy.visible_characters == -1, "dismissal cancels unfinished speech " + locale)
	ui.strawy._offer_choice()
	check(ui.strawy.copy.visible_characters == 0 and not (ui.strawy.actions.get_child(1) as Button).disabled, "post-tutorial choice animates while answers remain usable " + locale)
	ui.strawy.close()
	ui.strawy.open_help()
	ui.settings.set_strawy_enabled(false)
	check(not ui.strawy.surface.visible and ui.strawy.speech_reveal == null, "disabling Strawy cancels his typewriter " + locale)
	ui.settings.set_strawy_enabled(true)

func check_deal_speech(locale: String) -> void:
	ui.settings.set_locale(locale)
	ui.selected_card_ids.clear()
	ui.strawy.open_help()
	check(ui.strawy.copy.text.contains(GameGlossary.words("Select them and HẠ", "Chọn rồi HẠ")), "Deal tutorial explains how to play the ready Set " + locale)
	await finish_text(true)
	await capture("deal")
	ui.strawy.start_tour()
	var before := var_to_str(ui.deal.snapshot_state())
	var play: Dictionary = ui.deal.hand_advice().play
	check(play.action == HandAdvisor.ACTION_NEW_MELD and ui.strawy.copy.text.contains("HẠ"), "Deal tour explains the scoring action " + locale)
	for card: CardData in play.cards:
		check(ui.strawy.copy.text.contains(card.short_label()), "tour identifies every recommended card " + locale)
	await finish_text(true)
	await capture("deal-tour")
	check(var_to_str(ui.deal.snapshot_state()) == before, "explanations and text taps never play recommended cards " + locale)
	ui.strawy.close()
	ui.selected_card_ids[ui.deal.hand[0].unique_id] = true
	ui.strawy.open_help()
	ui.strawy._explain_cards()
	check(ui.strawy.copy.visible_characters == 0 and ui.strawy.copy.text.contains(ui.deal.hand[0].short_label()), "requested card details also animate " + locale)
	ui.strawy.close()

func _run() -> void:
	root.size = Vector2i(1920, 1080) if "--large" in OS.get_cmdline_user_args() else Vector2i(1280, 720)
	root.get_node("GameSettings").set_music_system("playing_tracks")
	ui = load("res://scenes/match.tscn").instantiate()
	root.add_child(ui)
	current_scene = ui
	await create_timer(0.3).timeout
	ui.run_save = RunSave.new("user://strawy-speech.save")
	ui.drink_manager.progress.save_path = ""
	var title := ui.get_node_or_null("TitleScreen")
	if title: title.queue_free()
	ui.game_started = true
	ui.game_layer.position = Vector2.ZERO
	ui.menu_layer.hide()
	ui._start_campaign()
	ui.event_table.unfocus_npc()
	await create_timer(0.4).timeout
	var locales: Array[String] = ["en", "vi"]
	if "--en" in OS.get_cmdline_user_args(): locales = ["en"]
	elif "--vi" in OS.get_cmdline_user_args(): locales = ["vi"]
	for locale in locales: await check_speech(locale)
	ui.campaign._enter_phase(CampaignManager.CampaignPhase.MORNING_DEAL)
	await create_timer(0.5).timeout
	for locale in locales: await check_deal_speech(locale)
	print("STRAWY_SPEECH_SMOKE checks=%d failures=%d" % [checks, failures.size()])
	ui.queue_free()
	await create_timer(0.4).timeout
	quit(0 if failures.is_empty() else 1)
