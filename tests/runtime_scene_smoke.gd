extends SceneTree

const CardActionOutlineScript := preload("res://scripts/ui/card_action_outline.gd")
const CardDragPayloadScript := preload("res://scripts/ui/card_drag_payload.gd")

var _failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var packed := load("res://scenes/match.tscn") as PackedScene
	_check(packed != null, "main scene loads")
	if packed == null:
		_finish()
		return
	var root_settings = root.get_node_or_null("GameSettings")
	_check(root_settings != null, "GameSettings autoload exists before MatchUI startup")
	if root_settings != null:
		root_settings.set_locale("en")
		root_settings.set_music_system("playing_tracks")
	var startup_probe := packed.instantiate() as MatchUI
	root.add_child(startup_probe)
	await process_frame
	await process_frame
	await process_frame
	_check((startup_probe.front_end.home_body.find_child("NewRun", true, false) as Button).text == "NEW RUN", "persisted English locale is applied during MatchUI startup")
	_check(startup_probe.event_table != null and startup_probe.event_table.continue_button.text == "CONTINUE" and startup_probe.event_table.back_button.text == "← BACK", "persisted English locale reaches event-table controls during startup")
	startup_probe.queue_free()
	await process_frame
	if root_settings != null:
		root_settings.set_locale("vi")
	var scene := packed.instantiate() as MatchUI
	root.add_child(scene)
	scene.session.run_save = RunSave.new("user://runtime-front-%d.save" % Time.get_ticks_usec())
	scene.front_end.show_home()
	current_scene = scene
	await process_frame
	await process_frame
	await process_frame
	var menu := scene.get_node_or_null("MainMenu") as Control
	var game_layer := scene.get_node_or_null("GameLayer") as Control
	var background := scene.get_node_or_null("SidewalkTableBackground") as TextureRect
	var background_position_before := background.global_position if background != null else Vector2.INF
	_check(menu != null and menu.visible, "main menu is visible before play")
	var settings = scene.settings
	var front := scene.front_end
	_check(front.page == "home" and front.pages.home.is_visible_in_tree(), "visible front end opens on Home")
	_check(scene.get_node_or_null("MainMenu/MenuCenter") == null, "retired menu is removed from the live scene")
	_check(front.logo_words.size() == 4, "TRADATALA logo has four reactive word units")
	var logo_text := ""
	for label: Label in front.logo_words: logo_text += label.text
	_check(logo_text == "TRADATALA", "reactive logo preserves the exact title")
	_check((front.home_body.find_child("NewRun", true, false) as Button).text == "VÁN MỚI", "Vietnamese New Run action is visible")
	var handbook_button := front.home_body.find_child("Handbook", true, false) as Button
	_check(handbook_button.text == "SỔ TAY" and handbook_button.is_visible_in_tree(), "localized Handbook navigation is visible")
	handbook_button.pressed.emit()
	var handbook := root.get_node_or_null("GameGlossary")
	_check(handbook != null, "visible navigation opens the shared Handbook")
	var play_section := _button_with_text(handbook, "CHƠI")
	var scoring_section := _button_with_text(handbook, "ĐIỂM")
	_check(play_section != null and scoring_section != null, "Handbook exposes play and scoring references")
	play_section.pressed.emit()
	_check(_button_with_text(handbook, "SET / BỘ") != null, "play reference includes physical Set rules")
	scoring_section.pressed.emit()
	var meld_reference := _button_with_text(handbook, scene.tr("HOW_SCORE_MELD_TITLE"))
	_check(meld_reference != null, "scoring reference includes Meld scoring")
	meld_reference.pressed.emit()
	var reference_body := handbook.find_children("*", "RichTextLabel", true, false)[0] as RichTextLabel
	_check(reference_body.get_parsed_text().contains("45"), "shared reference preserves the Meld formula example")
	(handbook.find_child("CloseHandbook", true, false) as Button).pressed.emit()
	await process_frame
	_check(root.get_node_or_null("GameGlossary") == null and front.page == "home", "Handbook Back preserves Home")
	(front.home_body.find_child("Settings", true, false) as Button).pressed.emit()
	_check(front.page == "settings" and front.pages.settings.is_visible_in_tree(), "Settings opens through visible navigation")
	var music_slider := front.settings_page.find_child("MusicVolume", true, false) as HSlider
	var sound_slider := front.settings_page.find_child("SoundVolume", true, false) as HSlider
	var language_selector := front.settings_page.find_child("Language", true, false) as OptionButton
	_check(is_equal_approx(music_slider.value, settings.music_volume_percent), "visible Music slider reflects persisted volume")
	_check(is_equal_approx(sound_slider.value, settings.sound_volume_percent), "visible Sound slider reflects persisted volume")
	_check(language_selector.item_count == 2 and language_selector.selected == 0, "visible language selector offers Vietnamese and English")
	_check(AudioServer.get_bus_index(&"Sound") >= 0, "dedicated Sound bus exists")
	music_slider.value = 35.0
	var music_volume_index := AudioServer.get_bus_index(&"Music")
	_check(is_equal_approx(settings.music_volume_percent, 35.0) and is_equal_approx(AudioServer.get_bus_volume_db(music_volume_index), linear_to_db(0.35)), "visible Music slider updates the Music bus")
	sound_slider.value = 0.0
	var sound_bus_index := AudioServer.get_bus_index(&"Sound")
	_check(is_equal_approx(settings.sound_volume_percent, 0.0) and AudioServer.is_bus_mute(sound_bus_index), "visible Sound slider mutes at zero")
	music_slider.value = 100.0
	sound_slider.value = 100.0
	language_selector.item_selected.emit(1)
	await process_frame
	await process_frame
	_check(TranslationServer.get_locale() == "en" and front.title_label.text == "SETTINGS", "English selection refreshes the visible Settings page")
	(front.footer.find_child("FrontBack", true, false) as Button).pressed.emit()
	_check((front.home_body.find_child("NewRun", true, false) as Button).text == "NEW RUN", "returning Home shows localized New Run navigation")
	_check((front.home_body.find_child("Handbook", true, false) as Button).text == "HANDBOOK", "returning Home shows localized Handbook navigation")
	(front.home_body.find_child("Settings", true, false) as Button).pressed.emit()
	_check(scene.event_table.continue_button.text == "CONTINUE" and scene.event_table.back_button.text == "← BACK", "English selection refreshes event-table navigation")
	_check((scene.event_table.get_node("TraDaAuntieName") as Label).text == "ICED TEA AUNTIE", "English selection refreshes NPC labels")
	_check(scene.hint_button.text == "HINT  [G]" and (scene.header_caption_labels["VndPerPointStat"] as Label).text == "VNĐ / POINT", "English selection refreshes gameplay controls and the point caption")
	(front.settings_page.find_child("Language", true, false) as OptionButton).item_selected.emit(0)
	await process_frame
	await process_frame
	_check(TranslationServer.get_locale() == "vi" and front.title_label.text == "TÙY CHỌN", "Vietnamese selection restores the visible Settings page")
	var saved_settings := ConfigFile.new()
	_check(saved_settings.load(settings.SETTINGS_PATH) == OK and String(saved_settings.get_value("localization", "locale", "")) == "vi", "preferences persist to the player settings file")
	(front.footer.find_child("FrontBack", true, false) as Button).pressed.emit()
	_check(front.page == "home" and (front.home_body.find_child("NewRun", true, false) as Button).text == "VÁN MỚI", "Settings Back returns to localized Home")
	(front.home_body.find_child("Music", true, false) as Button).pressed.emit()
	await process_frame
	_check(front.music_player.is_visible_in_tree(), "visible navigation opens the music player")
	_check(front.music_player.cover.texture.resource_path == "res://assets/audio/covers/main.png", "opening player uses the supplied Main cover")
	_check(front.music_player.track_title.text == ReactiveMusicController.display_title_for_theme(&"main"), "player reports the authoritative title")
	_check(front.music_player.system_selector.item_count == 2 and front.music_player.track_list.item_count == 26, "music player exposes both systems and all Playlist tracks")
	_check(scene.music.controller != null, "reactive music controller exists")
	_check(scene.music.controller.full_mix_player != null and scene.music.controller.full_mix_player.stream != null, "current full mix is loaded")
	_check(scene.music.controller.mix_players.size() == 2, "music queue owns two playback decks for preloaded boundary transitions")
	_check(scene.music.controller.current_mix_path == "res://assets/audio/ost/main_1.wav", "the game opens on Main 1")
	var current_mix := scene.music.controller.full_mix_player.stream as AudioStreamWAV
	_check(current_mix != null and current_mix.loop_mode == AudioStreamWAV.LOOP_DISABLED, "files do not self-loop because the two-deck queue owns every boundary")
	_check(scene.music.controller.full_mix_player != null and scene.music.controller.full_mix_player.bus == &"Music", "current mix routes through the Music bus")
	scene.front_end.music_player.play_pause.pressed.emit()
	_check(scene.music.controller.music_paused and scene.front_end.music_player.play_pause.text == scene.tr("MUSIC_PLAYER_PLAY"), "the menu player pauses both music decks and offers Resume")
	scene.front_end.music_player.play_pause.pressed.emit()
	_check(not scene.music.controller.music_paused, "the menu player resumes playback")
	_check(scene.front_end.music_player.track_list.item_count == 26, "the tracklist exposes all thirteen themes and both sides")
	scene.front_end.music_player.system_selector.select(0)
	scene.front_end.music_player.system_selector.item_selected.emit(0)
	_check(settings.music_system == settings.MUSIC_SYSTEM_PLAYING_TRACKS and not scene.front_end.music_player.track_list.disabled, "Playing Tracks enables the original jukebox")
	scene.front_end.music_player.shuffle.pressed.emit()
	_check(scene.music.controller.shuffle_enabled and scene.front_end.music_player.shuffle.text == scene.tr("MUSIC_PLAYER_SHUFFLE_ON"), "Shuffle toggles independently from campaign state")
	scene.front_end.music_player.repeat.pressed.emit()
	_check(scene.music.controller.repeat_mode == ReactiveMusicController.REPEAT_ALL, "Repeat cycles from Off to All")
	scene.front_end.music_player.repeat.pressed.emit()
	_check(scene.music.controller.repeat_mode == ReactiveMusicController.REPEAT_ONE, "Repeat cycles from All to One")
	scene.front_end.music_player.repeat.pressed.emit()
	_check(scene.music.controller.repeat_mode == ReactiveMusicController.REPEAT_OFF, "Repeat cycles from One back to Off")
	scene.front_end.music_player.track_list.item_selected.emit(3)
	var expected_selected_mix := "res://assets/audio/ost/mouse_2.wav"
	var track_transition_wait_frames := 0
	while (scene.music.controller.current_mix_path != expected_selected_mix or scene.music.controller.transition_in_progress) and track_transition_wait_frames < 120:
		await process_frame
		track_transition_wait_frames += 1
	_check(scene.music.controller.current_mix_path == expected_selected_mix, "selecting the tracklist crossfades directly to the chosen file; actual=%s" % scene.music.controller.current_mix_path)
	_check(scene.front_end.music_player.cover.texture.resource_path == "res://assets/audio/covers/mouse.png", "track selection updates the album cover")
	scene.front_end.music_player.system_selector.select(1)
	scene.front_end.music_player.system_selector.item_selected.emit(1)
	scene.front_end.music_player.track_list.select(1)
	scene.front_end.music_player.track_list.item_selected.emit(1)
	_check(settings.music_system == settings.MUSIC_SYSTEM_AUTHORED_DJ and settings.authored_music_set == "cat" and scene.music.controller.dj_mode, "menu immediately plays the selected CAT authored set")
	_check(scene.front_end.music_player.track_list.item_count == 2 and not scene.front_end.music_player.track_list.disabled, "Authored DJ reuses the chooser for DOG and CAT")
	_check(not scene.front_end.music_player.shuffle.visible and not scene.front_end.music_player.repeat.visible, "DJ hides Playlist-only controls")
	var saved_music_policy := ConfigFile.new()
	_check(saved_music_policy.load(settings.SETTINGS_PATH) == OK and String(saved_music_policy.get_value("music", "system", "")) == settings.MUSIC_SYSTEM_AUTHORED_DJ and String(saved_music_policy.get_value("music", "authored_set", "")) == "cat", "selected music system and authored set persist for later playtests")
	_check(AudioServer.get_bus_index(&"Music") >= 0, "Music bus exists")
	_check(music_volume_index >= 0 and AudioServer.get_bus_effect_count(music_volume_index) > 0 and AudioServer.get_bus_effect(music_volume_index, 0) is AudioEffectSpectrumAnalyzer, "Music bus carries a spectrum analyzer")
	scene.music.controller.beat_detector.set_process(false)
	front.show_home()
	front.pulse_values = [0.0, 0.0, 0.0, 0.0]
	scene.music.controller.band_pulse.emit(2, 1.0)
	await process_frame
	_check(front.logo_words[2].scale.y > 1.01, "visible TA word reacts to its music band")
	_check(front.logo_words[0].scale.is_equal_approx(Vector2.ONE) and front.logo_words[1].scale.is_equal_approx(Vector2.ONE) and front.logo_words[3].scale.is_equal_approx(Vector2.ONE), "TA pulse leaves other visible words at rest")
	_check(game_layer != null and game_layer.position.x > 0.0, "game layer begins parked beyond the right screen edge")
	(front.home_body.find_child("NewRun", true, false) as Button).pressed.emit()
	await process_frame
	_check(scene.front_end.page == "setup", "New Game opens run setup")
	if scene.front_end.page != "setup":
		_finish()
		return
	scene.front_end.draft.seed = "release-runtime-smoke"
	scene.front_end._start_pressed()
	await create_timer(0.82).timeout
	_check(scene.game_started and not menu.visible, "play hides the menu after its exit transition")
	_check(scene.music.controller.dj_mode and scene.music.controller.current_mix_path == "res://assets/audio/ost/cat_1.wav", "starting a CAT playtest hands playback to CAT_1")
	_check(scene.music.controller.music_director.current_cue_id == "cat_1_bars_001_002" and scene.music.controller.music_director.state == MusicDirector.STATE_HOLDING_CUE, "Starter Event holds approved CAT_1 bars 1-2")
	_check(is_equal_approx(game_layer.position.x, 0.0), "game layer slides fully into place")
	_check(background != null and background.global_position.is_equal_approx(background_position_before), "background remains fixed while UI layers transition")
	_check(scene.campaign.current_phase == CampaignManager.CampaignPhase.STARTER_EVENT, "New Game starts the Monday Starter Event before any Deal")
	_check(scene.event_table.visible and scene.current_campaign_event != null, "generic campaign Event UI opens above the existing Deal table")
	_check(scene.current_campaign_event.participants.any(func(npc: NPCDefinition): return npc.id == CampaignNpcCatalog.TRA_DA_AUNTIE), "Cô Trà Đá is a guaranteed Starter Event participant alongside the optional services")
	_check(not scene.current_campaign_event.can_exit and scene.event_table.continue_button.disabled, "mandatory Drink selection blocks Event exit")
	_check(scene.event_table.table_state == EventTableController.TABLE_STATE_EVENT, "event-table controller owns the active presentation state")
	_check(scene.event_table.focused_npc_id == EventTableController.NPC_DOI_NO, "Starter opens the debt encounter")
	scene.event_table.unfocus_npc()
	await create_timer(0.6).timeout
	_check(not scene.event_table._npc_layers.doi_no.overlay.visible and not scene.event_table._npc_layers.doi_no.sprite.visible, "collector leaves without a tabletop representation")
	_check(scene.event_table.event_deck.visible and scene.event_table.event_deck.position.x < 350.0 and scene.event_table.event_deck_count.text.contains(str(scene.campaign.gieo_que.persistent_deck.size())), "Event overview puts the persistent Deck on the left side of the table with its exact count")
	var lotto_selector := scene.event_table.get_node("LottoSelect") as Button
	var right_focus := scene.event_table._sprite_focus_position(&"right", Vector2(300, 590))
	var lotto_focus := scene.event_table._sprite_focus_position(&"top_right", Vector2(300, 590))
	_check(lotto_selector.size.x >= 210.0 and lotto_selector.size.y >= 48.0, "lottery NPC has an explicit touch-sized name target")
	_check(lotto_focus.is_equal_approx(right_focus), "top-right NPC focused sprite uses the same right-side presentation position as a right NPC")
	scene.event_table.focus_deck()
	await create_timer(EventTableController.TRANSITION_SECONDS + 0.05).timeout
	var starter_left_overlay := scene.event_table.get_node("DanhGiayOverlay") as TextureRect
	var starter_right_overlay := scene.event_table.get_node("TraDaAuntieOverlay") as TextureRect
	_check(scene.event_table.deck_focused and scene.event_table.day_label.get_parent().position.y < 20.0, "selecting the Event Deck uses the standard focus transition and moves the money header to the top")
	_check(starter_left_overlay.modulate.a < 0.5 and starter_right_overlay.modulate.a < 0.5, "selecting the Event Deck dims the other Event participants")
	_check(scene.deck_screen.visible and scene.deck_screen._cards.size() == 52 and not scene.pile_archive.overlay.visible, "Event Deck opens the shared full-screen browser with all physical cards")
	scene.deck_screen.close()
	await create_timer(EventTableController.TRANSITION_SECONDS + 0.05).timeout
	_check(starter_left_overlay.visible and starter_right_overlay.visible, "Starter Event composes Đánh Giày at left and Cô Trà Đá at right from frame-registered overlays")
	var starter_tea_selector := scene.event_table.get_node("TraDaAuntieSelect") as Button
	_check(not starter_tea_selector.disabled, "the visible Cô Trà Đá overlay exposes a focused click target")
	starter_tea_selector.pressed.emit()
	await create_timer(EventTableController.TRANSITION_SECONDS + 0.05).timeout
	_check(scene.event_table.focused_npc_id == EventTableController.NPC_TRA_DA and (scene.event_table.get_node("TraDaAuntieFocused") as TextureRect).visible, "selecting Cô Trà Đá slides her standalone sprite onto the table")
	_check(scene.event_table.content_panel.visible and scene.event_table.day_label.get_parent().position.y < 20.0, "NPC focus moves the wallet header upward and opens table content")
	var starter_drink_button := scene.event_table.find_child("Drink_tra_da", true, false) as Button
	_check(starter_drink_button != null and not starter_drink_button.disabled, "free Trà đá is purchasable in the Starter Event")
	starter_drink_button.pressed.emit()
	await process_frame
	_check(not scene.current_campaign_event.can_exit, "inspecting a Drink does not silently purchase it")
	_check(scene.event_table.conversation.speech.text.contains("Trà đá"), "Cô Trà Đá explains the inspected Drink")
	var order_button := scene.event_table.find_child("Confirm", true, false) as Button
	_check(order_button != null and not order_button.disabled, "inspected Drink exposes an explicit order response")
	order_button.pressed.emit()
	await process_frame
	_check(not scene.event_table.continue_button.visible, "Continue stays hidden after ordering tea")
	_check(scene.current_campaign_event.can_exit and not scene.event_table.continue_button.disabled, "selecting a Drink completes Cô Trà Đá's mandatory interaction")
	_check(scene.drink_manager.morning_drink_id == DrinkCatalog.TRA_DA and scene.deal.wallet.balance_vnd == CampaignConfig.STARTING_WALLET_VND, "Starter Drink is assigned to Morning/Noon without inventing a charge for free Trà đá")
	scene.event_table.back_button.pressed.emit()
	await create_timer(EventTableController.TRANSITION_SECONDS + 0.05).timeout
	_check(scene.event_table.focused_npc_id.is_empty() and not scene.event_table.content_panel.visible, "Back clears focused NPC content and restores the event overview")
	_check(scene.event_table.continue_button.visible, "Continue returns on the table overview")
	var starter_shoe_selector := scene.event_table.get_node("DanhGiaySelect") as Button
	starter_shoe_selector.pressed.emit()
	await create_timer(EventTableController.TRANSITION_SECONDS + 0.05).timeout
	_check(scene.event_table.focused_npc_id == EventTableController.NPC_DANH_GIAY and scene.event_table.participants_container.get_child(0) is ShoeShinePanel, "shoe-shine focus opens the implemented service panel")
	scene.event_table.back_button.pressed.emit()
	await create_timer(EventTableController.TRANSITION_SECONDS + 0.05).timeout
	for npc_id in scene.event_table._npc_layers:
		scene.event_table.focus_npc(npc_id)
		_check(not scene.event_table.continue_button.visible, "Continue hidden for " + npc_id)
		scene.event_table.back_button.disabled = false
		scene.event_table.unfocus_npc()
	scene.event_table.focus_deck()
	_check(not scene.event_table.continue_button.visible, "Continue hidden in deck inspection")
	scene.event_table.unfocus_npc()
	scene.event_table.continue_button.pressed.emit()
	await create_timer(EventTableController.TRANSITION_SECONDS * 2.0 + 0.08).timeout
	_check(scene.campaign.current_phase == CampaignManager.CampaignPhase.MORNING_DEAL and not scene.event_table.visible, "continuing the Starter Event hands off to the existing Morning Deal")
	_check(not scene.interactions.locked and scene.event_table.table_state == EventTableController.TABLE_STATE_DEAL, "Deal input unlocks only after the gameplay presentation returns")
	_check(scene.music.controller.music_director.pending_cue_id == "cat_1_bars_009_012" and scene.music.controller.music_director.state == MusicDirector.STATE_TRAVELING_FORWARD, "Morning Deal releases CAT_1 through authored audio toward its Phase 1 cue")
	_check(scene.deal.hand.size() == DealState.ACTIVE_HAND_TARGET, "opening hand refills to 10")
	_check(scene.card_table.hand_views.size() == DealState.ACTIVE_HAND_TARGET, "ten interactive card views are rendered")
	_check(scene.deal.deck.draw_pile.size() == 42, "draw pile count reflects opening draw")
	_check(scene.card_sfx_players.size() == 4, "card manipulation owns independent choose, place, draw, and shuffle players")
	for card_sfx_player in scene.card_sfx_players.values():
		_check((card_sfx_player as AudioStreamPlayer).bus == "Sound", "every card manipulation player routes through the Sound bus")
	_check(int(scene.card_sfx_play_counts[scene.CARD_SFX_SHUFFLE]) == 1 and (scene.card_sfx_players[scene.CARD_SFX_SHUFFLE] as AudioStreamPlayer).stream.resource_path == "res://assets/audio/sfx/card_shuffle.wav", "starting the visible Deal plays the supplied shuffle sound once")
	_check(int(scene.card_sfx_play_counts[scene.CARD_SFX_DRAW]) == 1 and (scene.card_sfx_players[scene.CARD_SFX_DRAW] as AudioStreamPlayer).stream.resource_path == "res://assets/audio/sfx/card_draw.wav", "dealing the opening hand plays the supplied draw sound once")
	_check(scene.ha_button.disabled, "HẠ begins disabled without a legal selection")
	_check(scene.extend_button.disabled, "EXTEND begins disabled without a target")
	_check(scene.discard_button.disabled, "DISCARD begins disabled without one selected card")
	_check(scene.settle_button.disabled, "CHỐT begins disabled before the final commit window")
	_check(not scene.hint_button.disabled, "GỢI Ý is available during an active turn")
	_check(scene.get_node_or_null("GameLayer/TableSurface/MeldScroll") != null, "table Meld region exists")
	_check(scene.get_node_or_null("GameLayer/TableSurface/MeldProbabilityPanel") == null, "no probability panel obstructs the table")
	_check(scene.get_node_or_null("GameLayer/TableSurface/PhaseClock") == null, "redundant center phase bar is removed")
	_check(scene.get_node_or_null("GameLayer/LooseHand/CardFan") != null, "loose-hand presentation region exists")
	var has_floating_hand_label := false
	var has_game_identity_copy := false
	for gameplay_label in game_layer.find_children("*", "Label", true, false):
		if gameplay_label.text == "BÀI TRÊN TAY":
			has_floating_hand_label = true
		if gameplay_label.text.contains("TRADATALA") or gameplay_label.text.contains("BÀN VỈA HÈ SỐ 07") or gameplay_label.text.contains("SOLO PHỎM"):
			has_game_identity_copy = true
	_check(not has_floating_hand_label, "floating BÀI TRÊN TAY label is removed")
	_check(not has_game_identity_copy, "game name and description copy are absent from the gameplay HUD")
	_check(scene.get_node_or_null("GameLayer/ActionDock") != null, "action dock exists")
	_check(scene.get_node_or_null("GameLayer/Header/HeaderRow/MenuButton") == scene.menu_button, "top-left HUD exposes the Menu button")
	_check(scene.menu_button.size.x <= 72.0 and scene.menu_button.size.y <= 54.0, "Menu remains clickable without dominating the compact header")
	var discard_history_hud := scene.get_node_or_null("GameLayer/TableSurface/DiscardHistoryHUD") as PanelContainer
	_check(discard_history_hud != null and scene.get_node_or_null("GameLayer/Header/HeaderRow/DiscardHistoryHUD") == null, "phase-grouped discard history is relocated below the table Phom")
	_check(discard_history_hud != null and is_equal_approx(discard_history_hud.get_global_rect().get_center().x, scene.table_surface.get_global_rect().get_center().x) and discard_history_hud.position.y >= 270.0, "discard history is centered below the Phom region")
	_check(scene.discard_history_row != null and scene.discard_history_row.get_children().filter(func(slot: Node): return slot.has_meta("turn_number")).size() == 8, "turn register begins with eight persistent card slots")
	_check(scene.get_node_or_null("GameLayer/Header/HeaderRow/IdentityPanel") == null, "game title and description panel is removed from gameplay")
	var income_panel := scene.campaign_money_hud.income_panel as PanelContainer
	_check(income_panel != null and income_panel.is_visible_in_tree() and income_panel.size.y <= 72.0, "Income remains in the compact top status strip")
	var vnd_per_point_panel := scene.campaign_money_hud.rate_panel as PanelContainer
	_check(income_panel != null and income_panel.get_global_rect().end.x < scene.campaign_money_hud.panel.get_global_rect().position.x, "Income sits to the left of the persistent wallet")
	_check(scene.vnd_per_point_value != null, "VND-per-point HUD exposes its value label")
	_check(vnd_per_point_panel != null and scene.vnd_per_point_value != null and vnd_per_point_panel.is_ancestor_of(scene.vnd_per_point_value), "VND-per-point value label belongs to its HUD panel")
	_check(scene.vnd_per_point_value != null and scene.vnd_per_point_value.text == VndWallet.format_vnd(scene.deal.vnd_per_point), "VND-per-point HUD matches the economy authority")
	_check(scene.campaign_money_hud.panel.is_visible_in_tree(), "Wallet stays in its persistent top layer")
	var wallet_pile := scene.wallet_pile_anchor
	_check(scene.money_presentation != null and scene.money_presentation.get_parent() == scene.game_layer, "one reusable table-native money presentation layer replaces the old resolve popup")
	_check(scene.score_overlay != null and not scene.score_overlay.visible and scene.score_panel != null, "money ceremony begins hidden while preserving tutorial targeting")
	_check(scene.money_presentation.get_node_or_null("Ceremony/ResolveBackdrop") == null, "resolve feedback is floating text with no opaque backing")
	_check(scene.money_presentation.get_node_or_null("Ceremony/HitFlash") == null, "resolve ceremony has no full-screen hit flash")
	_check(scene.money_presentation.get_node_or_null("Ceremony/ScoreStage/StageShadow") == null, "floating resolve text has no modal panel shadow")
	_check(scene.score_overlay.mouse_filter == Control.MOUSE_FILTER_IGNORE and scene.score_panel.size.x <= 460.0, "floating resolve feedback cannot consume table input")
	scene.money_presentation._position_score_stage(scene.meld_scroll)
	_check(absf(scene.score_panel.get_global_rect().get_center().x - scene.meld_scroll.get_global_rect().get_center().x) < 12.0, "resolve text anchors horizontally over its Meld source")
	_check(is_equal_approx(MoneyPresentation.MONEY_FLIGHT_DURATION, 0.48), "all money resolutions use the shared flight duration")
	scene.money_presentation.sync_wallet(0)
	_check(wallet_pile == scene.wallet_pile_anchor and wallet_pile.get_child_count() == 1, "zero wallet renders an empty cash state without fake banknotes")
	scene.money_presentation.sync_wallet(45_000)
	var wallet_bill := wallet_pile.get_child(0) as Control
	var wallet_bill_texture := wallet_bill.get_child(0) as TextureRect if wallet_bill != null else null
	_check(wallet_bill_texture != null and wallet_bill_texture.size.x <= 70.0 and wallet_bill_texture.size.y <= 31.0, "wallet banknotes obey their pile bounds instead of atlas-native size")
	scene.money_presentation.sync_wallet(-75_000)
	_check(scene.wallet_value.text == VndWallet.format_amount(-75_000) and wallet_pile.get_child_count() == 1 and wallet_pile.get_child(0) is Label, "negative wallet keeps its exact value and renders debt instead of impossible negative bills")
	scene.money_presentation.sync_wallet(987_654_000)
	_check(wallet_pile.get_child_count() <= MoneyPresentation.MAX_WALLET_OBJECTS, "very large wallet pile stays capped")
	scene.money_presentation.sync_wallet(scene.money_playback.displayed_balance)
	_check(MoneyPresentation.denomination_breakdown(2_500_000).size() == 1 and int(MoneyPresentation.denomination_breakdown(2_500_000)[0]["count"]) == 5, "large repeated denominations compress into one logical bill bundle")
	_check(scene.get_node_or_null("GameLayer/Header/HeaderRow/CampaignStat") != null and scene.table_hud_presentation.day.text.contains("THỨ HAI") and scene.campaign_value.text.contains(VndWallet.format_vnd(scene.campaign.daily_requirement())), "campaign day and requirement remain visible during the Deal")
	var campaign_panel := scene.get_node_or_null("GameLayer/Header/HeaderRow/CampaignStat") as PanelContainer
	_check(campaign_panel != null and campaign_panel.get_index() == scene.menu_button.get_index() + 1, "objective panel sits immediately beside Menu")
	_check(campaign_panel != null and campaign_panel.custom_minimum_size.x >= 240.0, "objective panel has room for day, requirement, and period")
	_check(scene.campaign_period_value != null and scene.campaign_period_value.text == scene.tr("PERIOD_MORNING"), "campaign HUD exposes the active Morning period")
	var morning_time_texture := scene.campaign_period_icon.texture as AtlasTexture
	_check(morning_time_texture != null and morning_time_texture.atlas.resource_path == "res://assets/environment/time.png" and morning_time_texture.region == Rect2(0, 0, 48, 48), "Morning uses the first cell of the time atlas")
	var original_campaign_phase := scene.campaign.current_phase
	scene.campaign.current_phase = CampaignManager.CampaignPhase.NOON_DEAL
	scene._refresh_stats()
	var noon_time_texture := scene.campaign_period_icon.texture as AtlasTexture
	_check(scene.campaign_period_value.text == scene.tr("PERIOD_NOON") and noon_time_texture != null and noon_time_texture.region == Rect2(48, 0, 48, 48), "Noon uses the second cell of the time atlas")
	scene.campaign.current_phase = CampaignManager.CampaignPhase.AFTERNOON_DEAL
	scene._refresh_stats()
	var afternoon_time_texture := scene.campaign_period_icon.texture as AtlasTexture
	_check(scene.campaign_period_value.text == scene.tr("PERIOD_AFTERNOON") and afternoon_time_texture != null and afternoon_time_texture.region == Rect2(96, 0, 48, 48), "Afternoon uses the third cell of the time atlas")
	scene.campaign.current_phase = original_campaign_phase
	scene._refresh_stats()
	_check(scene.get_node_or_null("GameLayer/Header/HeaderRow/PhaseStat") == null and scene.get_node_or_null("GameLayer/Header/HeaderRow/TurnStat") == null, "Phase and Turn stat cards are removed")
	_check(scene.get_node_or_null("GameLayer/UtilityRail/DrinkArea") == null, "the redundant right-side Drink UI is removed")
	var relic_area := scene.get_node_or_null("GameLayer/UtilityRail/RelicsArea") as Control
	var loose_hand := scene.get_node_or_null("GameLayer/LooseHand") as Control
	_check(relic_area != null and loose_hand != null, "removing the Drink panel preserves the passive Relic rail and hand surface")
	_check(scene.get_node_or_null("GameLayer/ActionDock/MarginContainer/HBoxContainer/ContextDivider") != null and scene.get_node_or_null("GameLayer/ActionDock/MarginContainer/HBoxContainer/ActionDivider") != null, "bottom dock visibly separates context, utility, and core actions")
	_check(scene.get_node_or_null("GameLayer/TableSurface/DrinkProps/ActiveDrink") == scene.drink_table_button, "active Drink has a clickable in-world table prop")
	_check(scene.drink_table_texture != null and scene.drink_table_texture.texture != null and scene.drink_table_texture.texture.resource_path == "res://assets/drinks/tra_da_full.png", "unused starter Drink shows its full sprite")
	_check(scene.drink_table_button.position.is_equal_approx((scene.drink_table_button.get_parent() as Control).size + Vector2(-183, -8)), "Drink occupies the fixed slot on the table beside the hand: %s / %s" % [scene.drink_table_button.position, (scene.drink_table_button.get_parent() as Control).size])
	_check(scene.drink_table_button.size.is_equal_approx(Vector2(112, 178)) and scene.drink_table_texture.size.is_equal_approx(Vector2(112, 144)), "the clickable Drink uses the sprite plus its separate nameplate footprint (button=%s; sprite=%s)" % [scene.drink_table_button.size, scene.drink_table_texture.size])
	_check(scene.drink_charge_outline.get_parent() == scene.drink_table_button and scene.drink_charge_outline.size == Vector2(112, 144), "the blue charge outline wraps the Drink sprite itself")
	_check(scene.drink_name_label.get_parent() == scene.drink_table_button and scene.drink_name_label.position.y >= scene.drink_table_texture.position.y + scene.drink_table_texture.size.y, "the bordered Drink name sits below the sprite")
	_check(loose_hand.get_global_rect().end.x <= scene.drink_table_button.get_global_rect().position.x, "the Drink sprite sits fully to the right of the hand interaction surface")
	scene.campaign.current_phase = CampaignManager.CampaignPhase.NOON_DEAL
	scene._sync_drink_table_visual()
	_check(scene.drink_table_texture.texture != null and scene.drink_table_texture.texture.resource_path == "res://assets/drinks/tra_da_full.png", "the noon Deal does not falsely mark an available Drink spent")
	scene.campaign.current_phase = CampaignManager.CampaignPhase.MORNING_DEAL
	scene._sync_drink_table_visual()
	scene.drink_manager.afternoon_drink_id = DrinkCatalog.SAM_DUA
	scene._sync_drink_table_visual()
	_check(scene.get_node_or_null("GameLayer/TableSurface/DrinkProps/EmptyDrinkProp") == null, "retired cup prop is entirely removed")
	scene.drink_manager.afternoon_drink_id = DrinkCatalog.NONE
	scene._sync_drink_table_visual()
	_check(scene.drink_name_label != null and scene.drink_name_label.text == "TRÀ ĐÁ", "free Trà đá is the visible starter Drink")
	_check(scene.drink_table_button.disabled, "Trà đá stays unavailable until the current Phase has a mandatory discard")
	_check(not scene.drink_charge_outline.visible and not scene.drink_charge_outline.is_processing(), "Trà đá has no blue charge cue before a mandatory discard exists")
	_check(scene.drink_table_button.tooltip_text.contains(QuickInfo.drink(DrinkCatalog.TRA_DA)), "Trà đá tooltip shows its short optional-discard effect")
	_check(scene.get_node_or_null("GameLayer/TableSurface/DiscardHistoryTray") == null, "persistent discard tray is replaced by the pile archive")
	_check(scene.pile_archive.overlay != null and not scene.pile_archive.overlay.visible, "discard archive begins closed")
	var draw_archive_button := scene.get_node_or_null("GameLayer/TableSurface/DrawPile/OpenDrawArchive") as Button
	_check(draw_archive_button != null, "draw pile exposes a remaining-deck click target")
	var archive_button := scene.get_node_or_null("GameLayer/TableSurface/DiscardPile/OpenDiscardArchive") as Button
	_check(archive_button != null, "discard pile exposes an archive click target")
	var relic_grid := scene.get_node_or_null("GameLayer/UtilityRail/RelicsArea/RelicScroll/RelicGrid") as GridContainer
	_check(relic_grid != null and relic_grid.columns == 1 and relic_grid.get_child_count() == scene.deal.relics.inventory.size(), "right-edge icon list reflects actual owned relics without empty slots")
	_check(background != null, "official sidewalk-table background exists")
	_check(background != null and background.texture != null and background.texture.resource_path == "res://assets/environment/sidewalk_table.png", "official background asset is active")
	_check(scene.theme != null and scene.theme.default_font != null and scene.theme.default_font.resource_path == PresentationTheme.OFFICIAL_FONT_PATH, "DFVN Pexel Grotesk is the official UI font")
	var opening_hand_ids: Array[String] = []
	for opening_card in scene.deal.hand:
		opening_hand_ids.append(opening_card.unique_id)
	scene.menu_button.pressed.emit()
	_check(menu.visible and scene.interactions.locked, "Menu button opens the minimal menu and pauses table interaction")
	await scene._close_menu_to_game()
	_check(not menu.visible and not scene.interactions.locked, "Escape-style resume closes the menu and restores table interaction")
	var resumed_hand_ids: Array[String] = []
	for resumed_card in scene.deal.hand:
		resumed_hand_ids.append(resumed_card.unique_id)
	_check(resumed_hand_ids == opening_hand_ids, "resuming from Menu preserves the current deal")
	draw_archive_button.pressed.emit()
	_check(scene.pile_archive.overlay.visible and scene.pile_archive.mode == "draw", "clicking the draw pile opens the remaining-deck viewer")
	_check(scene.pile_archive.title_label.text == "BỘ BÀI CÒN LẠI" and scene.pile_archive.count_label.text.begins_with("42 LÁ"), "remaining-deck viewer reports all 42 drawable cards")
	var visible_draw_cards := 0
	for suit in DeckManager.SUITS:
		visible_draw_cards += scene.pile_archive.grids[suit].get_child_count()
	_check(visible_draw_cards == 42, "remaining-deck viewer renders every drawable card by suit")
	var clubs_title := scene.pile_archive.suit_titles["Clubs"] as Control
	var clubs_icon: TextureRect = null
	if clubs_title != null:
		clubs_icon = clubs_title.get_node_or_null("Icon") as TextureRect
	_check(clubs_icon != null and clubs_icon.texture != null and clubs_icon.texture.resource_path == "res://cards/symbol_club.png", "archive suit headings use the supplied suit symbol assets")
	scene.pile_archive.close_button.pressed.emit()
	_check(not scene.pile_archive.overlay.visible, "remaining-deck viewer closes back to the table")
	var first_card: CardData = scene.deal.hand[0]
	var first_view: PlayingCardView = scene.card_table.hand_views[first_card.unique_id]
	var chance_badge := first_view.get_node_or_null("MeldChance") as Control
	_check(chance_badge != null and not chance_badge.visible, "meld probability stays hidden until its card is hovered")
	var meld_symbol: TextureRect = null
	if chance_badge != null:
		meld_symbol = chance_badge.get_node_or_null("Content/MeldSymbol") as TextureRect
	_check(meld_symbol != null and meld_symbol.texture != null and meld_symbol.texture.resource_path == "res://cards/symbol_meld.png", "meld probability badge uses the supplied straw-hat symbol asset")
	settings.set_locale("en")
	await process_frame
	_check(first_view.tooltip_text.contains("Fortune 0") and first_view.tooltip_text.contains(first_view.card.rank) and not first_view.tooltip_text.contains("Vận") and first_view.tooltip_text.length() < 100, "English card hover keeps physical identity and signed Fortune concise")
	settings.set_locale("vi")
	await process_frame
	first_view._on_mouse_entered()
	_check(chance_badge != null and chance_badge.visible and (meld_symbol.visible or not (chance_badge.get_node("Content/Value") as Label).text.is_empty()), "hover reveals the card's meld probability or ready icon")
	await _capture("runtime-meld-badge")
	var probability_discard_count := scene.deal.discard_count
	scene.deal.discard_count = DealState.DISCARDS_PER_PHASE - 1
	scene.card_table.sync_probabilities()
	_check(chance_badge != null and (chance_badge.get_node("Content/Value") as Label).text != "0%", "last mandatory discard keeps a future-draw probability instead of forcing 0%")
	scene.deal.discard_count = probability_discard_count
	scene.card_table.sync_probabilities()
	var choose_sfx_count := int(scene.card_sfx_play_counts[scene.CARD_SFX_CHOOSE])
	scene._on_card_pressed(first_card)
	_check(int(scene.card_sfx_play_counts[scene.CARD_SFX_CHOOSE]) == choose_sfx_count + 1 and (scene.card_sfx_players[scene.CARD_SFX_CHOOSE] as AudioStreamPlayer).stream.resource_path == "res://assets/audio/sfx/card_choose.wav", "selecting a card plays card_choose exactly once")
	scene._on_card_pressed(first_card)
	_check(int(scene.card_sfx_play_counts[scene.CARD_SFX_CHOOSE]) == choose_sfx_count + 1, "deselecting a card does not replay card_choose")
	scene._on_card_pressed(first_card)
	first_view._on_mouse_exited()
	_check(first_view.z_index == 100, "clicked card stays above the hand panel after hover exit")
	_check(first_view.get_node_or_null("SelectionGlow") == null, "card selection does not add a competing outline overlay")
	_check(scene.status_label.text == tr("STATUS_ONE_SELECTED"), "one-card guidance is the concise selected-card label")
	_check(chance_badge != null and not chance_badge.visible, "meld probability hides again after hover exit")
	_check(chance_badge != null and chance_badge.position.x >= 0 and chance_badge.position.x + chance_badge.size.x <= PlayingCardView.CARD_SIZE.x, "chance badge stays inside the card face")
	for card in scene.deal.hand:
		_check(ResourceLoader.exists(card.texture_path()), "face texture exists for %s" % card.unique_id)
		var card_view: PlayingCardView = scene.card_table.hand_views[card.unique_id]
		var card_badge := card_view.get_node_or_null("MeldChance") as Control
		_check(card_badge != null and not card_badge.visible, "non-hovered meld chance stays hidden for %s" % card.unique_id)
	var action_outline := first_view.get_node_or_null("BeatVisual/ActionOutline")
	_check(action_outline != null, "each loose card has an animated action outline")
	_check(action_outline != null and action_outline.get_parent() == first_view._beat_visual, "action outline shares the card's beat transform")
	first_view.set_action_cues(true, false)
	_check(action_outline != null and action_outline.visible and action_outline.cue_mode() == CardActionOutlineScript.CUE_MELD and action_outline.is_processing(), "meldable cards animate with the green cue")
	first_view.set_action_cues(false, true)
	_check(action_outline != null and action_outline.visible and action_outline.cue_mode() == CardActionOutlineScript.CUE_EXTEND, "extendable cards animate with the yellow cue")
	first_view.set_action_cues(false, false)
	_check(action_outline != null and not action_outline.visible and not action_outline.is_processing(), "non-actionable cards do not carry an outline")
	first_view.set_drink_preserved(true)
	_check(action_outline != null and action_outline.visible and action_outline.cue_mode() == CardActionOutlineScript.CUE_DRINK and action_outline.is_processing(), "Drink-marked cards use the reusable animated blue action outline")
	first_view.set_action_cues(true, true, true, true)
	_check(action_outline.cue_mode() == CardActionOutlineScript.CUE_ALL, "green, orange, and blue eligibility coexist in one animated multicolor outline")
	first_view.set_action_cues(true, false, true)
	_check(action_outline.cue_mode() == (CardActionOutlineScript.CUE_MELD | CardActionOutlineScript.CUE_DRINK), "green and blue eligibility coexist without covering the card face")
	action_outline.scale = Vector2.ONE
	action_outline.play_target_pulse(1.0)
	_check(action_outline._pulse_tween == null and action_outline.scale == Vector2.ONE, "eligibility outlines never bounce independently of their cards")
	first_view.set_drink_preserved(false)
	_check(action_outline.cue_mode() == CardActionOutlineScript.CUE_MELD, "clearing a Drink cue preserves the card's green action state")
	first_view.set_action_cues(false, false)
	_check(not action_outline.visible and not action_outline.is_processing(), "clearing the final action cue hides the reusable outline")
	var input_test_view := PlayingCardView.new()
	root.add_child(input_test_view)
	input_test_view.set_card(CardData.new("drag_input_8_clubs", "8", 8, "Clubs", 8))
	var input_clicks := [0]
	var input_drags := [0]
	input_test_view.card_pressed.connect(func(_card: CardData) -> void: input_clicks[0] += 1)
	input_test_view.card_drag_started.connect(func(_card: CardData, _position: Vector2) -> void: input_drags[0] += 1)
	var input_press := InputEventMouseButton.new()
	input_press.button_index = MOUSE_BUTTON_LEFT
	input_press.pressed = true
	input_press.position = Vector2(20, 20)
	var input_release := InputEventMouseButton.new()
	input_release.button_index = MOUSE_BUTTON_LEFT
	input_release.pressed = false
	input_release.position = Vector2(20, 20)
	input_test_view._gui_input(input_press)
	input_test_view._gui_input(input_release)
	_check(input_clicks[0] == 1 and input_drags[0] == 0, "a press and release remains a normal card click")
	var input_drag_motion := InputEventMouseMotion.new()
	input_drag_motion.position = Vector2(40, 20)
	input_test_view._gui_input(input_press)
	input_test_view._gui_input(input_drag_motion)
	input_test_view._gui_input(input_release)
	_check(input_clicks[0] == 1 and input_drags[0] == 1, "crossing the drag threshold starts one drag without also clicking the card")
	input_test_view.queue_free()
	var archive_cards: Array[CardData] = [
		CardData.new("archive_2_spades", "2", 2, "Spades", 2),
		CardData.new("archive_k_spades", "K", 13, "Spades", 13),
		CardData.new("archive_4_hearts", "4", 4, "Hearts", 4),
		CardData.new("archive_7_diamonds", "7", 7, "Diamonds", 7),
		CardData.new("archive_9_clubs", "9", 9, "Clubs", 9),
	]
	scene.deal.deck.discard_pile.append_array(archive_cards)
	archive_button.pressed.emit()
	_check(scene.pile_archive.overlay.visible, "clicking the discard pile opens the archive")
	_check(scene.pile_archive.mode == "discard" and scene.pile_archive.title_label.text == "CHỒNG BÀI BỎ", "shared pile viewer switches to discard mode")
	_check(scene.pile_archive.count_label.text.begins_with("5 LÁ"), "discard archive reports every card in the pile")
	_check(scene.pile_archive.grids["Spades"].get_child_count() == 2, "discard archive groups both Spades together")
	_check(scene.pile_archive.grids["Hearts"].get_child_count() == 1, "discard archive groups Hearts")
	_check(scene.pile_archive.grids["Diamonds"].get_child_count() == 1, "discard archive groups Diamonds")
	_check(scene.pile_archive.grids["Clubs"].get_child_count() == 1, "discard archive groups Clubs")
	scene.pile_archive.close_button.pressed.emit()
	_check(not scene.pile_archive.overlay.visible, "discard archive close action restores the table")
	scene.deal.deck.discard_pile.clear()
	scene.card_table.sync_piles()
	scene.interactions.selected_ids.clear()
	for _replace_index in range(3):
		scene.deal.hand.pop_back()
	var nhan_pair_low := CardData.new("cue_5_spades", "5", 5, "Spades", 5)
	var nhan_pair_high := CardData.new("cue_6_spades", "6", 6, "Spades", 6)
	var nhan_mandatory := CardData.new("cue_7_spades", "7", 7, "Spades", 7)
	scene.deal.hand.append_array([nhan_pair_low, nhan_pair_high, nhan_mandatory] as Array[CardData])
	scene.deal.set_current_drink(DrinkCatalog.NHAN_TRAN)
	scene._sync_all()
	var nhan_cue_count := scene.drink_cue_play_count
	_check(scene.deal.discard_card(nhan_mandatory).get("ok", false), "the scene can create a mandatory discard for Drink targeting")
	scene._sync_all()
	_check(scene.drink_cue_play_count == nhan_cue_count + 1, "a discard that completes a hand Meld triggers Nhân trần's glass cue")
	var nhan_record := scene.deal.latest_mandatory_discard()
	var nhan_loose: CardData = scene.deal.hand[1]
	var nhan_draw_before := scene.deal.deck.draw_pile.size()
	var nhan_hand_size := scene.deal.hand.size()
	scene.drink_table_button.pressed.emit()
	await process_frame
	_check(scene.interactions.drink_targeting, "Nhân trần arms its two-target swap mode")
	var nhan_hand_outline := (scene.card_table.hand_views.get(nhan_loose.unique_id) as PlayingCardView).get_node_or_null("BeatVisual/ActionOutline") as Control
	_check(nhan_hand_outline != null and (nhan_hand_outline.cue_mode() & CardActionOutlineScript.CUE_DRINK) != 0, "Nhân trần marks loose hand cards blue")
	scene._on_card_pressed(nhan_loose)
	_check(scene.interactions.drink_ids.has(nhan_loose.unique_id), "Nhân trần keeps the loose-card target pending")
	_check(scene.interactions.drink_discard_key.is_empty(), "Nhân trần waits for a mandatory-discard target")
	scene.target_drink_discard(nhan_record)
	await create_timer(0.45).timeout
	_check(scene.deal.hand.size() == nhan_hand_size, "Nhân trần swaps without changing hand size")
	_check(scene.deal.deck.draw_pile.size() == nhan_draw_before, "Nhân trần never refills or draws")
	_check(scene.deal.discard_count == 1 and nhan_record.card == nhan_loose, "Nhân trần changes the selected mandatory-discard slot without adding a discard")
	_check(scene.deal.nhan_tran_used_this_phase, "Nhân trần spends once for the whole Phase")
	scene.deal.set_current_drink(DrinkCatalog.TRA_DA)
	scene._sync_all()
	_check(scene.drink_cue_player != null and scene.drink_cue_player.bus == "Sound", "Drink cues use a dedicated player on the Sound bus")
	_check(scene.drink_table_button.disabled, "passive Trà đá does not expose the obsolete swap-target button")
	var tra_cue_count := scene.drink_cue_play_count
	var tra_draw_before := scene.deal.deck.draw_pile.size()
	var tra_mandatory := scene.deal.discard_card(scene.deal.hand[0])
	scene._sync_all(tra_mandatory)
	_check(not scene.settle_button.disabled and scene.settle_button.text == scene.tr("ACTION_END_TURN"), "Trà đá offers End Turn instead of requiring its optional extra discard")
	_check(tra_mandatory.get("extra_discard_pending", false), "Trà đá keeps the turn open after its mandatory discard")
	_check(scene.deal.tra_da_extra_discard_pending and scene.deal.state == DealState.STATE_ACTIVE, "Trà đá records that one extra discard is still owed")
	_check(scene.drink_cue_play_count == tra_cue_count + 1 and scene.drink_cue_player.playing, "the first Trà đá discard plays exactly one glass-clink cue")
	_check(scene.drink_cue_player.stream.resource_path == "res://assets/audio/sfx/drinks/tra_da.wav", "the reactive cue uses the supplied Objects recording for this drink")
	_check(scene.drink_charge_outline.visible, "the active Trà đá opportunity also receives the blue Drink outline")
	scene._sync_all()
	_check(scene.drink_cue_play_count == tra_cue_count + 1, "repeated UI synchronization does not replay an already-active cue")
	var tra_extra := scene.deal.discard_card(scene.deal.hand[0])
	scene._sync_all(tra_extra)
	_check(tra_extra.get("discard_kind", "") == DiscardRecord.KIND_DRINK_EXTRA, "Trà đá's second discard has separate Drink provenance")
	_check(not scene.deal.tra_da_extra_discard_pending and scene.deal.deck.draw_pile.size() == tra_draw_before - 2, "the extra discard ends the turn and refills both missing cards")
	_check(scene.deal.discard_count == 2 and scene.deal.discard_history_for_phase(scene.deal.current_phase).size() == 2, "Trà đá's extra discard does not advance the Phase counter")
	scene.deal.deck.discard_pile.clear()
	scene.card_table.sync_piles()
	scene.deal.discard_history.clear()
	scene.deal.discard_count = 0
	scene.deal.state = DealState.STATE_ACTIVE
	scene.interactions.selected_ids.clear()
	var stable_meld := MeldState.new(77, MeldRules.TYPE_RUN, [
		CardData.new("smoke_3_spades", "3", 3, "Spades", 3),
		CardData.new("smoke_4_spades", "4", 4, "Spades", 4),
		CardData.new("smoke_5_spades", "5", 5, "Spades", 5),
	] as Array[CardData])
	scene.deal.melds.append(stable_meld)
	scene.card_table.sync_melds()
	await create_timer(0.22).timeout
	var stable_view := scene.card_table.meld_views.get(stable_meld.meld_id) as MeldView
	var stable_view_id := stable_view.get_instance_id() if stable_view != null else 0
	var stable_face_id := stable_view._cards_row.get_child(0).get_instance_id() if stable_view != null else 0
	scene._on_card_pressed(first_card)
	_check(scene.card_table.meld_views[stable_meld.meld_id].get_instance_id() == stable_view_id, "card selection preserves the existing Meld panel instance")
	_check(stable_view._cards_row.get_child(0).get_instance_id() == stable_face_id, "card selection preserves table Meld face instances")
	_check(stable_view.modulate.is_equal_approx(Color.WHITE) and stable_view.scale.is_equal_approx(Vector2.ONE), "card selection does not replay the Meld intro animation")
	scene.select_meld(stable_meld.meld_id)
	_check(scene.card_table.meld_views[stable_meld.meld_id].get_instance_id() == stable_view_id, "Meld targeting preserves the existing panel instance")
	stable_meld.extend([CardData.new("smoke_2_spades", "2", 2, "Spades", 2)] as Array[CardData])
	scene.card_table.sync_melds()
	_check(scene.card_table.meld_views[stable_meld.meld_id].get_instance_id() == stable_view_id, "extending a Meld updates its existing panel")
	_check(stable_view._card_views["smoke_3_spades"].get_instance_id() == stable_face_id, "extending a Meld preserves its existing card-face instances")
	_check(stable_view._cards_row.get_child_count() == 4, "extending a Meld adds only the new card face")
	scene.deal.set_current_drink(DrinkCatalog.NAU_DA)
	scene._sync_all()
	var idle_nau_outline := stable_view._card_drink_outlines.get(stable_meld.cards[0].unique_id) as Control
	_check(idle_nau_outline != null and idle_nau_outline.visible and not scene.interactions.drink_targeting and not scene.drink_hover_active, "unused caffeine highlights table targets without hovering or arming the Drink")
	var nuoc_cue_count := scene.drink_cue_play_count
	var previous_cue_stream_index := scene.drink_cue_stream_index
	scene.deal.set_current_drink(DrinkCatalog.NUOC_VOI)
	stable_meld.scored_points = ScoringPipeline.meld_value(stable_meld.cards)
	scene._sync_all()
	_check(scene.drink_cue_play_count == nuoc_cue_count + 1 and scene.drink_cue_stream_index != previous_cue_stream_index, "Nước vối's removable Meld card triggers the next non-repeating glass cue")
	_check(scene.drink_table_button.tooltip_text.contains(QuickInfo.drink(DrinkCatalog.NUOC_VOI)), "switching Drinks refreshes the short clickable sprite tooltip")
	var idle_nuoc_outline := stable_view._card_drink_outlines.get(stable_meld.cards[0].unique_id) as Control
	_check(idle_nuoc_outline != null and idle_nuoc_outline.visible, "unused Nuoc voi highlights legal table targets without Drink hover or targeting")
	var removable_endpoint: CardData = stable_meld.cards[0]
	scene.select_meld_card(stable_meld.meld_id, removable_endpoint)
	_check(scene.interactions.drink_meld_card_id.is_empty(), "Nước vối ignores table-card targeting until the Drink is clicked first")
	scene.drink_table_button.pressed.emit()
	await process_frame
	_check(scene.interactions.drink_targeting, "clicking charged Nước vối arms its card-targeting mode without spending it")
	scene.select_meld_card(stable_meld.meld_id, removable_endpoint)
	_check(scene.interactions.drink_meld_card_id == removable_endpoint.unique_id, "after arming Nước vối, clicking a legal table card selects it")
	var table_drink_outline := stable_view._card_drink_outlines.get(removable_endpoint.unique_id) as Control
	_check(table_drink_outline != null and table_drink_outline.visible and table_drink_outline.cue_mode() == CardActionOutlineScript.CUE_DRINK, "the armed Nước vối target receives the blue gradient before resolution")
	await create_timer(0.2).timeout
	_check(stable_meld.cards.size() == 3 and scene.deal.hand.has(removable_endpoint), "clicking the armed Nước vối target returns it to the loose hand")
	_check(scene.deal.nuoc_voi_used_phases.has(scene.deal.current_phase), "Nước vối becomes spent for the current Phase")
	_check(not scene.drink_charge_outline.visible and not scene.drink_charge_outline.is_processing(), "Nước vối blue charge outline disappears immediately after use")
	_check(scene.drink_table_texture.texture != null and scene.drink_table_texture.texture.resource_path == "res://assets/drinks/nuoc_voi_half.png", "spent Nuoc voi changes its table prop from full to half-full")
	scene.deal.set_current_drink(DrinkCatalog.TRA_DA)
	scene.deal.melds.clear()
	scene.interactions.selected_ids.clear()
	scene.card_table.sync_melds()
	_check(scene.card_table.meld_views.is_empty(), "removed Meld panels leave the keyed view registry")
	for _turn in range(DealState.DISCARDS_PER_PHASE):
		scene.deal.discard_card(scene.deal.hand[0])
		scene.deal.discard_card(scene.deal.hand[0])
	scene._sync_all()
	_check(scene.deal.state == DealState.STATE_FINAL_COMMIT_WINDOW, "fourth discard enters LAST CALL without auto-settlement")
	_check(not scene.settle_button.disabled, "CHỐT becomes available during LAST CALL")
	_check(scene.discard_button.disabled, "additional discard remains blocked during LAST CALL")
	var sam_cue_count := scene.drink_cue_play_count
	scene.deal.set_current_drink(DrinkCatalog.SAM_DUA)
	scene._sync_all()
	_check(scene.drink_cue_play_count == sam_cue_count + 1, "entering Sâm dứa's Phase 1 preserve window triggers one glass cue")
	_check(scene.drink_charge_outline.visible, "unused Sâm dứa charge shows the blue Drink-sprite outline")
	var pre_arm_card: CardData = scene.deal.hand[0]
	scene._on_card_pressed(pre_arm_card)
	var pre_arm_outline := (scene.card_table.hand_views.get(pre_arm_card.unique_id) as PlayingCardView).get_node_or_null("BeatVisual/ActionOutline") as Control
	_check((pre_arm_outline.cue_mode() & CardActionOutlineScript.CUE_DRINK) != 0 and scene.interactions.drink_ids.is_empty(), "unused Sam dua keeps eligible cards blue while ordinary clicks leave Drink targeting unarmed")
	scene.interactions.selected_ids.clear()
	scene._sync_all()
	scene.drink_table_button.pressed.emit()
	await process_frame
	_check(scene.interactions.drink_targeting, "clicking Sâm dứa first arms its multi-card targeting mode")
	for eligible_card in scene.deal.hand:
		var eligible_outline := (scene.card_table.hand_views.get(eligible_card.unique_id) as PlayingCardView).get_node_or_null("BeatVisual/ActionOutline") as Control
		_check((eligible_outline.cue_mode() & CardActionOutlineScript.CUE_DRINK) != 0, "arming a Drink exposes every currently eligible loose-card target")
	scene._on_card_pressed(scene.deal.hand[0])
	scene._on_card_pressed(scene.deal.hand[1])
	scene._on_card_pressed(scene.deal.hand[2])
	_check(scene.interactions.drink_ids.size() == 3 and scene.deal.sam_dua_preserved_cards.is_empty(), "the first three post-arm card clicks remain a pending Sâm dứa selection")
	for pending_card in scene.interactions.pending_drink_cards():
		var pending_view := scene.card_table.hand_views.get(pending_card.unique_id) as PlayingCardView
		var pending_outline := pending_view.get_node_or_null("BeatVisual/ActionOutline") as Control
		_check(pending_outline.visible and (pending_outline.cue_mode() & CardActionOutlineScript.CUE_DRINK) != 0, "each pending Sâm dứa card immediately receives the blue gradient")
	scene.drink_table_button.pressed.emit()
	await process_frame
	_check(scene.deal.sam_dua_preserved_cards.size() == 3, "clicking Sâm dứa during Phase 1 LAST CALL marks up to three selected loose cards for DUMP")
	_check(scene.drink_table_button.tooltip_text.contains(tr("DRINK_SAM_DUA_SELECTED") % 3), "Sâm dứa tooltip reports the marked preservation count")
	_check(scene.drink_charge_outline.visible, "Sâm dứa stays available to edit marked cards before settlement")
	for preserved_card in scene.deal.sam_dua_preserved_cards:
		var preserved_view := scene.card_table.hand_views.get(preserved_card.unique_id) as PlayingCardView
		var preserved_outline: Control = preserved_view.get_node_or_null("BeatVisual/ActionOutline") if preserved_view != null else null
		_check(preserved_outline != null and preserved_outline.visible and (preserved_outline.cue_mode() & CardActionOutlineScript.CUE_DRINK) != 0, "each Sâm dứa preservation card keeps the blue stay outline")
	scene.deal.set_current_drink(DrinkCatalog.TRA_DA)
	scene.deal.sam_dua_preserved_cards.clear()
	scene.interactions.selected_ids.clear()
	scene._sync_all()
	_check(scene.discard_history_row.get_child_count() == 10, "turn register retains both phase markers and eight slots after four discards")
	_check((scene.discard_history_row.get_child(0) as Label).text == "P1", "center-table discard history labels the owning phase")
	_check(scene.card_table.discard_history_target_outlines.size() == 4, "each mandatory discard remains an independently addressable action target")
	for discard_target in scene.discard_history_row.get_children().slice(1, 5):
		_check(discard_target.has_meta("action_target_card_id") and discard_target.get_node_or_null("ActionOutline") != null and discard_target.mouse_filter == Control.MOUSE_FILTER_IGNORE, "mandatory discard target stays passive until its Drink is armed")
	var latest_discard_target_key: String = scene.deal.latest_mandatory_discard().target_key()
	_check(scene.drink_table_button.disabled, "Tra Da stays disabled during LAST CALL")
	var latest_discard_outline := scene.card_table.discard_history_target_outlines[latest_discard_target_key] as Control
	_check(latest_discard_outline.cue_mode() == CardActionOutlineScript.CUE_NONE, "mandatory discard targets stay passive when Tra Da is unavailable")
	for target_key in scene.card_table.discard_history_target_outlines:
		if target_key == latest_discard_target_key:
			continue
		var non_target_outline := scene.card_table.discard_history_target_outlines[target_key] as Control
		_check(non_target_outline.cue_mode() == CardActionOutlineScript.CUE_NONE, "older mandatory discards stay outside the unavailable Drink scope")
	scene._cancel_drink_targeting()
	scene.deal.discard_history.append(DiscardRecord.new(CardData.new("smoke_p2_discard", "A", 1, "Hearts", 1), 2, 1))
	scene.card_table.sync_discard_history()
	_check(scene.discard_history_row.get_child_count() == 10 and (scene.discard_history_row.get_child(5) as Label).text == "P2" and scene.discard_history_row.get_node("Phase2Turn1").get_meta("turn_filled"), "turn register fills Phase 2 in place and restarts its turn order")
	archive_button.pressed.emit()
	_check(scene.pile_archive.overlay.visible and scene.pile_archive.count_label.text.begins_with("8 LÁ"), "pile archive includes all four mandatory and four Trà đá extra discards")
	scene.pile_archive.close_button.pressed.emit()

	var beat_meld_cards: Array[CardData] = [
		CardData.new("beat_3_spades", "3", 3, "Spades", 3),
		CardData.new("beat_4_spades", "4", 4, "Spades", 4),
		CardData.new("beat_5_spades", "5", 5, "Spades", 5),
		CardData.new("beat_q_hearts", "Q", 12, "Hearts", 12),
	]
	scene.deal.hand.clear()
	scene.deal.hand.append_array(beat_meld_cards)
	scene.deal.melds.clear()
	scene.interactions.selected_ids.clear()
	scene.interactions.selected_meld_id = -1
	scene._sync_all()
	await create_timer(0.22).timeout
	_check(scene.card_table.reactive_hand_cards_by_band[0].is_empty() and scene.card_table.reactive_hand_cards_by_band[1].is_empty() and scene.card_table.reactive_hand_cards_by_band[2].is_empty() and scene.card_table.reactive_hand_cards_by_band[3].is_empty(), "legal loose Meld cards stay still until the player selects one")
	scene._on_card_pressed(beat_meld_cards[0])
	_check(scene.card_table.reactive_hand_cards_by_band[0].size() == 1 and scene.card_table.reactive_hand_cards_by_band[1].size() == 1 and scene.card_table.reactive_hand_cards_by_band[2].size() == 1 and scene.card_table.reactive_hand_cards_by_band[3].is_empty(), "selecting one legal Meld card maps that Meld left-to-right across frequency bands")
	var beat_hand_views: Array[PlayingCardView] = []
	for beat_card: CardData in beat_meld_cards.slice(0, 3):
		var beat_view := scene.card_table.hand_views[beat_card.unique_id] as PlayingCardView
		beat_view._beat_visual.scale = Vector2.ONE
		beat_hand_views.append(beat_view)
	scene._on_music_band_pulse(1, 1.0)
	await create_timer(0.06).timeout
	_check(beat_hand_views[1]._beat_visual.scale.y > 1.01, "second loose Meld card pulses on its assigned DA frequency band")
	_check(beat_hand_views[0]._beat_visual.scale.is_equal_approx(Vector2.ONE) and beat_hand_views[2]._beat_visual.scale.is_equal_approx(Vector2.ONE), "DA pulse leaves differently assigned loose Meld cards still")

	var extension_card := CardData.new("beat_6_clubs", "6", 6, "Clubs", 6)
	var extension_filler := CardData.new("beat_q_diamonds", "Q", 12, "Diamonds", 12)
	var beat_table_meld := MeldState.new(88, MeldRules.TYPE_RUN, [
		CardData.new("beat_3_clubs", "3", 3, "Clubs", 3),
		CardData.new("beat_4_clubs", "4", 4, "Clubs", 4),
		CardData.new("beat_5_clubs", "5", 5, "Clubs", 5),
	] as Array[CardData])
	scene.deal.hand.clear()
	scene.deal.hand.append_array([extension_card, extension_filler] as Array[CardData])
	scene.deal.melds.clear()
	scene.deal.melds.append(beat_table_meld)
	scene.interactions.selected_ids.clear()
	scene.interactions.selected_meld_id = -1
	scene._sync_all()
	await create_timer(0.22).timeout
	_check(scene.card_table.reactive_hand_cards_by_band[0].is_empty(), "an extendable hand card stays still before a table Meld is selected")
	scene.select_meld(beat_table_meld.meld_id)
	_check(scene.card_table.reactive_hand_cards_by_band[0].size() == 1 and scene.card_table.reactive_hand_cards_by_band[0][0] == scene.card_table.hand_views[extension_card.unique_id], "selecting a table Meld makes its extendable hand card reactive")
	scene.select_meld(beat_table_meld.meld_id)
	_check(scene.card_table.reactive_hand_cards_by_band[0].is_empty(), "deselecting the table Meld stops the extendable hand-card cue")
	scene._on_card_pressed(extension_card)
	_check(scene.card_table.reactive_meld_cards_by_band[0].size() == 1 and scene.card_table.reactive_meld_cards_by_band[1].size() == 1 and scene.card_table.reactive_meld_cards_by_band[2].size() == 1, "selected legal extension maps the target Meld cards left-to-right across frequency bands")
	var beat_meld_view := scene.card_table.meld_views[beat_table_meld.meld_id] as MeldView
	var beat_table_textures: Array[TextureRect] = []
	for table_card: CardData in beat_table_meld.cards:
		var table_texture := beat_meld_view._card_views[table_card.unique_id] as TextureRect
		table_texture.scale = Vector2.ONE
		beat_table_textures.append(table_texture)
	scene._on_music_band_pulse(2, 1.0)
	await create_timer(0.06).timeout
	_check(beat_table_textures[2].scale.y > 1.01, "third target-Meld card pulses on its assigned TA frequency band")
	_check(beat_table_textures[0].scale.is_equal_approx(Vector2.ONE) and beat_table_textures[1].scale.is_equal_approx(Vector2.ONE), "TA pulse leaves differently assigned target-Meld cards still")

	var drag_run: Array[CardData] = [
		CardData.new("drag_3_hearts", "3", 3, "Hearts", 3),
		CardData.new("drag_4_hearts", "4", 4, "Hearts", 4),
		CardData.new("drag_5_hearts", "5", 5, "Hearts", 5),
	]
	var drag_extension := CardData.new("drag_6_hearts", "6", 6, "Hearts", 6)
	var drag_discard := CardData.new("drag_k_clubs", "K", 13, "Clubs", 13)
	scene.deal.set_current_drink(DrinkCatalog.NONE)
	scene.deal.hand.clear()
	scene.deal.hand.append_array(drag_run)
	scene.deal.hand.append_array([drag_extension, drag_discard] as Array[CardData])
	scene.deal.melds.clear()
	scene.deal.state = DealState.STATE_ACTIVE
	scene.deal.discard_count = 0
	scene.interactions.selected_ids.clear()
	for drag_card in drag_run:
		scene.interactions.selected_ids[drag_card.unique_id] = true
	scene.interactions.selected_meld_id = -1
	scene.interactions.locked = false
	scene._sync_all()
	await process_frame
	var original_last_id := scene.deal.hand[-1].unique_id
	var reordered := scene._reorder_hand_card(drag_discard, scene.hand_layer.get_global_rect().position.x)
	_check(reordered and scene.deal.hand[0] == drag_discard and original_last_id == drag_discard.unique_id, "dropping within the hand reorders the dragged card without changing gameplay state")
	var run_source := scene.card_table.hand_views[drag_run[0].unique_id] as PlayingCardView
	scene._on_card_drag_started(drag_run[0], run_source.get_global_rect().get_center(), run_source)
	_check(scene.interactions.drag_payload != null and scene.interactions.drag_payload.source_zone == CardDragPayloadScript.SOURCE_HAND and scene.interactions.drag_payload.cards.size() == 3, "dragging one selected Meld card carries the full selected group from the hand source")
	_check(scene.card_table.drag_preview != null and not scene.card_table.drag_target_overlays.is_empty(), "an active drag shows a card preview and legal drop-target feedback")
	var future_table_payload = CardDragPayloadScript.new(
		CardDragPayloadScript.SOURCE_TABLE_MELD,
		99,
		drag_run[0].unique_id,
		[drag_run[0]] as Array[CardData]
	)
	_check(scene.interactions.card_drag_action(future_table_payload, {"kind": MatchInteraction.DROP_TARGET_HAND, "meld_id": -1}) == MatchInteraction.DRAG_ACTION_NONE, "table-Meld drag sources are represented but remain disabled until the future verb is balanced")
	var place_sfx_count := int(scene.card_sfx_play_counts[scene.CARD_SFX_PLACE])
	var table_drop_position := scene.table_surface.get_global_rect().get_center()
	_check(scene.card_table.drop_target_at(table_drop_position)["kind"] == MatchInteraction.DROP_TARGET_TABLE, "the open table resolves as the new-Meld drop target")
	scene._finish_card_drag(table_drop_position)
	_check(await _wait_for_interaction_unlock(scene), "dragging selected cards to the table completes the Meld action")
	await process_frame
	_check(not scene.interactions.locked and scene.score_overlay.visible, "Meld money continues floating while the next player interaction is already enabled")
	_check(scene.deal.melds.size() == 1 and scene.deal.melds[0].cards.size() == 3, "the table drop commits the selected three-card Meld")
	_check(int(scene.card_sfx_play_counts[scene.CARD_SFX_PLACE]) == place_sfx_count + 1 and (scene.card_sfx_players[scene.CARD_SFX_PLACE] as AudioStreamPlayer).stream.resource_path.begins_with("res://assets/audio/sfx/card_place"), "creating a Phỏm plays one supplied placement variant")
	var first_place_index := scene.card_place_stream_index
	var created_meld_id: int = scene.deal.melds[0].meld_id
	var extension_source := scene.card_table.hand_views[drag_extension.unique_id] as PlayingCardView
	var created_meld_view := scene.card_table.meld_views[created_meld_id] as MeldView
	scene._on_card_drag_started(drag_extension, extension_source.get_global_rect().get_center(), extension_source)
	_check(scene.card_table.drop_target_at(created_meld_view.get_global_rect().get_center())["kind"] == MatchInteraction.DROP_TARGET_MELD, "an existing Meld resolves as an extension drop target")
	scene._finish_card_drag(created_meld_view.get_global_rect().get_center())
	_check(await _wait_for_scene_unlock(scene), "dragging a compatible loose card onto a Meld completes the extension action")
	_check(scene.deal.melds[0].cards.size() == 4 and scene.deal.melds[0].cards.has(drag_extension), "the Meld drop commits the dragged extension card")
	_check(int(scene.card_sfx_play_counts[scene.CARD_SFX_PLACE]) == place_sfx_count + 2 and scene.card_place_stream_index != first_place_index, "extending a Phỏm advances to a non-repeating placement variant")
	var second_place_index := scene.card_place_stream_index
	var discard_source := scene.card_table.hand_views[drag_discard.unique_id] as PlayingCardView
	scene._on_card_drag_started(drag_discard, discard_source.get_global_rect().get_center(), discard_source)
	var discard_drop_position := scene.discard_pile_visual.get_global_rect().get_center()
	_check(scene.card_table.drop_target_at(discard_drop_position)["kind"] == MatchInteraction.DROP_TARGET_DISCARD, "the discard pile resolves as the discard drop target")
	var draw_sfx_count := int(scene.card_sfx_play_counts[scene.CARD_SFX_DRAW])
	scene._finish_card_drag(discard_drop_position)
	_check(await _wait_for_scene_unlock(scene), "dragging one card to the discard pile completes the discard action")
	_check(not scene.deal.deck.discard_pile.is_empty() and scene.deal.deck.discard_pile[-1] == drag_discard, "the discard drop commits only the dragged card")
	_check(int(scene.card_sfx_play_counts[scene.CARD_SFX_PLACE]) == place_sfx_count + 3 and scene.card_place_stream_index != second_place_index, "discarding advances to the third placement variant")
	_check(int(scene.card_sfx_play_counts[scene.CARD_SFX_DRAW]) == draw_sfx_count + 1, "the post-discard refill plays card_draw once")
	scene._show_campaign_outcome(true)
	_check(scene.resolve_receipt.visible and scene.resolve_receipt.title_label.text == scene.tr("CAMPAIGN_VICTORY") and not scene.resolve_receipt.primary.disabled, "campaign victory opens the accounting receipt and offers a new run")
	scene._show_campaign_outcome(false)
	_check(scene.resolve_receipt.visible and scene.resolve_receipt.title_label.text == scene.tr("CAMPAIGN_FAILURE") and int(scene.resolve_receipt._report.get("closing_vnd", 0)) == scene.deal.wallet.balance_vnd, "campaign failure reports the final wallet on the accounting receipt")
	scene.music.select_system(0)
	scene.campaign.campaign_started.emit()
	_check(not scene.music.conductor.active and not scene.music.controller.dj_mode, "starting a Playing Tracks run leaves gameplay cues inactive and returns authority to the jukebox")
	for active_view in scene.card_table.hand_views.values():
		if active_view is PlayingCardView:
			active_view.set_action_cues(false, false)
	for active_meld_view in scene.card_table.meld_views.values():
		if active_meld_view is MeldView:
			active_meld_view.set_process(false)
	scene.music.controller._stop_all_mix_players()
	scene.music.controller.music_director.stop()
	await create_timer(0.2).timeout
	scene.queue_free()
	# Allow the audio mixer to release stopped playback before process teardown.
	await create_timer(0.2).timeout
	for autoload_name in ["GameSettings", "_mcp_game_helper"]:
		var autoload_node := root.get_node_or_null(autoload_name)
		if autoload_node != null:
			autoload_node.queue_free()
	await process_frame
	_finish()


func _wait_for_scene_unlock(scene: MatchUI, timeout_msec: int = 6000) -> bool:
	var deadline := Time.get_ticks_msec() + timeout_msec
	while Time.get_ticks_msec() < deadline:
		if not scene.interactions.locked and not scene.score_overlay.visible:
			return true
		await process_frame
	return false


func _wait_for_interaction_unlock(scene: MatchUI, timeout_msec: int = 2000) -> bool:
	var deadline := Time.get_ticks_msec() + timeout_msec
	while Time.get_ticks_msec() < deadline:
		if not scene.interactions.locked:
			return true
		await process_frame
	return false


func _check(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)


func _capture(file: String) -> void:
	if DisplayServer.get_name() == "headless":
		return
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://.godot/" + file + ".png")


func _finish() -> void:
	if _failures.is_empty():
		print("TRADATALA_SCENE_SMOKE passed")
		quit(0)
	else:
		for failure in _failures:
			print("SCENE_SMOKE_FAIL: %s" % failure)
		quit(1)


func _button_with_text(scope: Node, text: String) -> Button:
	for button: Button in scope.find_children("*", "Button", true, false):
		if button.text == text: return button
	return null
