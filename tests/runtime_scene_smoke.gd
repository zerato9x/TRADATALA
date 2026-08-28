extends SceneTree

const CardActionOutlineScript := preload("res://scripts/ui/card_action_outline.gd")

var _failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var packed := load("res://scenes/match.tscn") as PackedScene
	_check(packed != null, "main scene loads")
	if packed == null:
		_finish()
		return
	var scene := packed.instantiate() as MatchUI
	root.add_child(scene)
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
	var logo := scene.get_node_or_null("MainMenu/MenuCenter/MenuContent/Logo") as HBoxContainer
	_check(logo != null and logo.get_child_count() == 4, "TRADATALA logo is split into four reactive word units")
	var logo_text := ""
	if logo != null:
		for child in logo.get_children():
			if child is Label:
				logo_text += child.text
	_check(logo_text == "TRADATALA", "reactive logo units preserve the exact TRADATALA title")
	var menu_home := scene.get_node_or_null("MainMenu/MenuCenter/MenuContent/HomePanel") as VBoxContainer
	var how_panel := scene.get_node_or_null("MainMenu/MenuCenter/MenuContent/HowToPlayPanel") as PanelContainer
	var options_panel := scene.get_node_or_null("MainMenu/MenuCenter/MenuContent/OptionsPanel") as PanelContainer
	_check(menu_home != null and menu_home.visible, "main menu opens on its compact action list")
	_check(scene.play_button != null and scene.play_button.text == "VÁN MỚI", "Vietnamese New Game action exists on the main menu")
	_check(scene.how_to_play_button != null and scene.how_to_play_button.text == "CÁCH CHƠI", "main menu exposes the localized How to Play section")
	_check(scene.tutorial_button != null and scene.tutorial_button.text == "TẬP CHƠI", "main menu exposes a separate playable Tutorial")
	_check(scene.tutorial_button.get_parent() == scene.how_to_play_button.get_parent() and scene.tutorial_button.position.x > scene.how_to_play_button.position.x, "Tutorial sits beside How to Play")
	_check(scene.options_button != null and scene.options_button.text == "TÙY CHỌN", "main menu exposes the localized Options section")
	_check(how_panel != null and not how_panel.visible and options_panel != null and not options_panel.visible, "secondary menu sections begin hidden")
	scene.how_to_play_button.pressed.emit()
	_check(how_panel.visible and not menu_home.visible, "How to Play opens as its own menu section")
	var cards_tab := scene.how_tab_pages.get(&"cards") as Control
	var phases_tab := scene.how_tab_pages.get(&"phases") as Control
	var scoring_tab := scene.how_tab_pages.get(&"scoring") as Control
	_check(scene.how_tab_buttons.size() == 3 and cards_tab.visible and not phases_tab.visible and not scoring_tab.visible, "How to Play opens on Cards and Melds with three available tabs")
	var tutorial_cards := cards_tab.find_children("*", "TextureRect", true, false)
	_check(tutorial_cards.size() == 12, "How to Play demonstrates Run, Set, Extend, and Discard with twelve real card images")
	var how_intro := cards_tab.find_child("Intro", true, false) as Label
	_check(how_intro != null and how_intro.text == "Chọn bài. Hạ Phỏm hoặc Ghép. Rồi bỏ 1 lá.", "How to Play uses a short Vietnamese core-loop instruction")
	(scene.how_tab_buttons[&"phases"] as Button).pressed.emit()
	_check(phases_tab.visible and not cards_tab.visible and scene.how_to_play_tab == &"phases", "Phases and Turns tab replaces the card reference in place")
	var phases_intro := phases_tab.find_child("PhasesIntro", true, false) as Label
	_check(phases_intro != null and phases_intro.text.contains("2 Giai đoạn") and phases_intro.text.contains("4 lần bỏ bài"), "Phases tab explains the two-Phase and four-turn structure")
	(scene.how_tab_buttons[&"scoring"] as Button).pressed.emit()
	_check(scoring_tab.visible and not phases_tab.visible and scene.how_to_play_tab == &"scoring", "Scoring tab replaces the Phase reference in place")
	var scoring_labels := scoring_tab.find_children("*", "Label", true, false)
	var has_meld_formula := false
	var has_extend_delta := false
	var has_phase_net := false
	for scoring_label in scoring_labels:
		has_meld_formula = has_meld_formula or scoring_label.text.contains("(4+5+6) × 3 = 45")
		has_extend_delta = has_extend_delta or scoring_label.text.contains("+43 điểm")
		has_phase_net = has_phase_net or scoring_label.text.contains("Gross − bài rời = Net")
	_check(has_meld_formula and has_extend_delta and has_phase_net, "Scoring tab exposes Meld, Extend delta, and Phase net formulas")
	_check(scene.how_scoring_topic_buttons.size() == 2 and scene.how_scoring_topic == &"basic", "Scoring opens on Basic with a separate Special Outcomes view")
	(scene.how_scoring_topic_buttons[&"special"] as Button).pressed.emit()
	var special_page := scene.how_scoring_topic_pages[&"special"] as Control
	var special_labels := special_page.find_children("*", "Label", true, false)
	var has_mom_rule := false
	var has_u_rule := false
	var has_u_khan_rule := false
	for special_label in special_labels:
		has_mom_rule = has_mom_rule or (special_label.text.contains("0 Phỏm MỚI") and special_label.text.contains("Ghép không cứu Móm"))
		has_u_rule = has_u_rule or (special_label.text.contains("dùng đúng 9") and special_label.text.contains("Gross ×2"))
		has_u_khan_rule = has_u_khan_rule or (special_label.text.contains("cách nhau 1–2 số") and special_label.text.contains("×10"))
	_check(special_page.visible and has_mom_rule and has_u_rule and has_u_khan_rule, "Special Outcomes explains Móm, Ù, and the ×10 Ù Khan authority")
	scene.how_to_play_back_button.pressed.emit()
	_check(menu_home.visible and not how_panel.visible, "How to Play Back returns to the main actions")
	scene.options_button.pressed.emit()
	_check(options_panel.visible and not menu_home.visible, "Options owns the audio and language controls")
	_check(scene.music_slider != null and is_equal_approx(scene.music_slider.value, settings.music_volume_percent), "Music slider reflects the persisted Music volume")
	_check(scene.sound_slider != null and is_equal_approx(scene.sound_slider.value, settings.sound_volume_percent), "Sound slider reflects the persisted Sound volume")
	_check(scene.language_selector != null and scene.language_selector.item_count == 2 and scene.language_selector.selected == 0, "language selector offers Vietnamese and English with Vietnamese as default")
	_check(AudioServer.get_bus_index(&"Sound") >= 0, "dedicated Sound bus exists for current and future effects")
	scene.music_slider.value = 35.0
	var music_volume_index := AudioServer.get_bus_index(&"Music")
	_check(is_equal_approx(settings.music_volume_percent, 35.0) and is_equal_approx(AudioServer.get_bus_volume_db(music_volume_index), linear_to_db(0.35)), "Music slider changes the Music bus volume")
	scene.sound_slider.value = 0.0
	var sound_bus_index := AudioServer.get_bus_index(&"Sound")
	_check(is_equal_approx(settings.sound_volume_percent, 0.0) and AudioServer.is_bus_mute(sound_bus_index), "Sound slider mutes the Sound bus at zero")
	scene.music_slider.value = 100.0
	scene.sound_slider.value = 100.0
	scene.language_selector.item_selected.emit(1)
	await process_frame
	_check(TranslationServer.get_locale() == "en" and scene.play_button.text == "NEW GAME", "English selection localizes the menu immediately")
	_check(scene.how_to_play_button.text == "HOW TO PLAY" and scene.tutorial_button.text == "TUTORIAL" and scene.options_button.text == "OPTIONS", "English selection refreshes main-menu navigation")
	_check((scene.how_tab_buttons[&"cards"] as Button).text == "CARDS & MELDS" and (scene.how_tab_buttons[&"phases"] as Button).text == "PHASES & TURNS" and (scene.how_tab_buttons[&"scoring"] as Button).text == "SCORING", "English selection refreshes all How to Play tabs")
	_check((scene.how_scoring_topic_buttons[&"basic"] as Button).text == "BASIC SCORING" and (scene.how_scoring_topic_buttons[&"special"] as Button).text == "SPECIAL OUTCOMES", "English selection refreshes both Scoring topics")
	_check(scene.music_settings_label.text == "MUSIC" and scene.sound_settings_label.text == "SOUND" and scene.hint_button.text == "HINT  [G]", "English selection refreshes Options and gameplay controls")
	_check(how_intro != null and how_intro.text == "Pick cards. Meld or Extend. Then discard 1.", "English selection refreshes the visual tutorial copy while it is hidden")
	scene.language_selector.item_selected.emit(0)
	await process_frame
	_check(TranslationServer.get_locale() == "vi" and scene.play_button.text == "VÁN MỚI", "Vietnamese selection restores the interface immediately")
	var saved_settings := ConfigFile.new()
	_check(saved_settings.load(settings.SETTINGS_PATH) == OK and String(saved_settings.get_value("localization", "locale", "")) == "vi", "audio and language preferences persist to the player settings file")
	scene.options_back_button.pressed.emit()
	_check(menu_home.visible and not options_panel.visible, "Options Back returns to the main actions")
	_check(scene.music_controller != null, "reactive music controller exists")
	_check(scene.music_controller.full_mix_player != null and scene.music_controller.full_mix_player.stream != null, "current full mix is loaded")
	var current_mix := scene.music_controller.full_mix_player.stream as AudioStreamWAV
	_check(current_mix != null and current_mix.loop_mode == AudioStreamWAV.LOOP_FORWARD, "current full mix loops continuously")
	_check(current_mix != null and current_mix.loop_end > current_mix.loop_begin, "current full mix has a non-zero loop range")
	_check(scene.music_controller.full_mix_player != null and scene.music_controller.full_mix_player.bus == &"Music", "current mix routes through the Music bus")
	_check(AudioServer.get_bus_index(&"Music") >= 0, "Music bus exists")
	_check(music_volume_index >= 0 and AudioServer.get_bus_effect_count(music_volume_index) > 0 and AudioServer.get_bus_effect(music_volume_index, 0) is AudioEffectSpectrumAnalyzer, "Music bus carries a spectrum analyzer")
	scene.music_controller.beat_detector.set_process(false)
	for active_tween in scene.logo_bounce_tweens.values():
		if active_tween is Tween and active_tween.is_valid():
			active_tween.kill()
	scene.logo_bounce_tweens.clear()
	for segment in scene.logo_segments:
		segment.scale = Vector2.ONE
		segment.rotation = 0.0
	scene._on_music_band_pulse(2, 1.0)
	await create_timer(0.06).timeout
	_check(scene.logo_segments[2].scale.y > 1.01, "TA reacts to its assigned frequency band")
	_check(scene.logo_segments[0].scale.is_equal_approx(Vector2.ONE) and scene.logo_segments[1].scale.is_equal_approx(Vector2.ONE) and scene.logo_segments[3].scale.is_equal_approx(Vector2.ONE), "a TA-band pulse does not animate TRA, DA, or LA")
	_check(game_layer != null and game_layer.position.x > 0.0, "game layer begins parked beyond the right screen edge")
	scene.play_button.pressed.emit()
	await create_timer(0.82).timeout
	_check(scene.game_started and not menu.visible, "play hides the menu after its exit transition")
	_check(is_equal_approx(game_layer.position.x, 0.0), "game layer slides fully into place")
	_check(background != null and background.global_position.is_equal_approx(background_position_before), "background remains fixed while UI layers transition")
	_check(scene.deal.hand.size() == DealState.ACTIVE_HAND_TARGET, "opening hand refills to 10")
	_check(scene.hand_views.size() == DealState.ACTIVE_HAND_TARGET, "ten interactive card views are rendered")
	_check(scene.deal.deck.draw_pile.size() == 42, "draw pile count reflects opening draw")
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
	_check(scene.get_node_or_null("GameLayer/Header/HeaderRow/DiscardHistoryHUD") != null, "phase-grouped discard history is relocated into the top-left HUD")
	_check(scene.discard_history_row != null and scene.discard_history_row.get_child_count() == 1, "discard history HUD begins with its empty state")
	_check(scene.get_node_or_null("GameLayer/Header/HeaderRow/IdentityPanel") == null, "game title and description panel is removed from gameplay")
	_check(scene.get_node_or_null("GameLayer/Header/HeaderRow/IncomeStat") != null, "Income remains in the top stat row")
	_check(scene.get_node_or_null("GameLayer/Header/HeaderRow/WalletStat") != null, "Wallet remains in the top stat row")
	_check(scene.get_node_or_null("GameLayer/Header/HeaderRow/PhaseStat") == null and scene.get_node_or_null("GameLayer/Header/HeaderRow/TurnStat") == null, "Phase and Turn stat cards are removed")
	_check(scene.get_node_or_null("GameLayer/UtilityRail/DrinkArea/DrinkSlot") != null, "Drink slot exists")
	_check(scene.drink_name_label != null and scene.drink_name_label.text == "TRÀ ĐÁ", "free Trà đá is the visible starter Drink")
	_check(scene.get_node_or_null("GameLayer/TableSurface/DiscardHistoryTray") == null, "persistent discard tray is replaced by the pile archive")
	_check(scene.discard_archive_overlay != null and not scene.discard_archive_overlay.visible, "discard archive begins closed")
	var draw_archive_button := scene.get_node_or_null("GameLayer/TableSurface/DrawPile/OpenDrawArchive") as Button
	_check(draw_archive_button != null, "draw pile exposes a remaining-deck click target")
	var archive_button := scene.get_node_or_null("GameLayer/TableSurface/DiscardPile/OpenDiscardArchive") as Button
	_check(archive_button != null, "discard pile exposes an archive click target")
	var relic_grid := scene.get_node_or_null("GameLayer/UtilityRail/RelicsArea/RelicScroll/RelicGrid") as GridContainer
	_check(relic_grid != null and relic_grid.get_child_count() == MatchUI.INITIAL_RELIC_SLOT_COUNT, "four expandable Relic slots exist")
	_check(background != null, "official sidewalk-table background exists")
	_check(background != null and background.texture != null and background.texture.resource_path == "res://assets/environment/sidewalk_table.png", "official background asset is active")
	_check(scene.theme != null and scene.theme.default_font != null and scene.theme.default_font.resource_path == PresentationTheme.OFFICIAL_FONT_PATH, "DFVN Pexel Grotesk is the official UI font")
	var opening_hand_ids: Array[String] = []
	for opening_card in scene.deal.hand:
		opening_hand_ids.append(opening_card.unique_id)
	scene.menu_button.pressed.emit()
	_check(menu.visible and scene.interaction_locked, "Menu button opens the minimal menu and pauses table interaction")
	await scene._close_menu_to_game()
	_check(not menu.visible and not scene.interaction_locked, "Escape-style resume closes the menu and restores table interaction")
	var resumed_hand_ids: Array[String] = []
	for resumed_card in scene.deal.hand:
		resumed_hand_ids.append(resumed_card.unique_id)
	_check(resumed_hand_ids == opening_hand_ids, "resuming from Menu preserves the current deal")
	draw_archive_button.pressed.emit()
	_check(scene.discard_archive_overlay.visible and scene.pile_archive_mode == "draw", "clicking the draw pile opens the remaining-deck viewer")
	_check(scene.pile_archive_title.text == "BỘ BÀI CÒN LẠI" and scene.discard_archive_count.text.begins_with("42 LÁ"), "remaining-deck viewer reports all 42 drawable cards")
	var visible_draw_cards := 0
	for suit in DeckManager.SUITS:
		visible_draw_cards += scene.discard_archive_suit_grids[suit].get_child_count()
	_check(visible_draw_cards == 42, "remaining-deck viewer renders every drawable card by suit")
	scene.discard_archive_close.pressed.emit()
	_check(not scene.discard_archive_overlay.visible, "remaining-deck viewer closes back to the table")
	var first_card: CardData = scene.deal.hand[0]
	var first_view: PlayingCardView = scene.hand_views[first_card.unique_id]
	var chance_badge := first_view.get_node_or_null("MeldChance") as Label
	_check(chance_badge != null and not chance_badge.visible, "meld probability stays hidden until its card is hovered")
	first_view._on_mouse_entered()
	_check(chance_badge != null and chance_badge.visible and not chance_badge.text.is_empty(), "hover reveals the card's meld probability")
	scene._on_card_pressed(first_card)
	first_view._on_mouse_exited()
	_check(first_view.z_index == 100, "clicked card stays above the hand panel after hover exit")
	_check(first_view.get_node_or_null("SelectionGlow") == null, "card selection does not add a competing outline overlay")
	_check(not scene.status_label.text.begins_with("1 "), "selected-card guidance omits the selected-count number")
	_check(chance_badge != null and not chance_badge.visible, "meld probability hides again after hover exit")
	_check(chance_badge != null and chance_badge.position.x >= 0 and chance_badge.position.x + chance_badge.size.x <= PlayingCardView.CARD_SIZE.x, "chance badge stays inside the card face")
	for card in scene.deal.hand:
		_check(ResourceLoader.exists(card.texture_path()), "face texture exists for %s" % card.unique_id)
		var card_view: PlayingCardView = scene.hand_views[card.unique_id]
		var card_badge := card_view.get_node_or_null("MeldChance") as Label
		_check(card_badge != null and not card_badge.visible, "non-hovered meld chance stays hidden for %s" % card.unique_id)
	var action_outline := first_view.get_node_or_null("ActionOutline")
	_check(action_outline != null, "each loose card has an animated action outline")
	first_view.set_action_cues(true, false)
	_check(action_outline != null and action_outline.visible and action_outline.cue_mode() == CardActionOutlineScript.CUE_MELD and action_outline.is_processing(), "meldable cards animate with the green cue")
	first_view.set_action_cues(false, true)
	_check(action_outline != null and action_outline.visible and action_outline.cue_mode() == CardActionOutlineScript.CUE_EXTEND, "extendable cards animate with the yellow cue")
	first_view.set_action_cues(false, false)
	_check(action_outline != null and not action_outline.visible and not action_outline.is_processing(), "non-actionable cards do not carry an outline")
	var archive_cards: Array[CardData] = [
		CardData.new("archive_2_spades", "2", 2, "Spades", 2),
		CardData.new("archive_k_spades", "K", 13, "Spades", 13),
		CardData.new("archive_4_hearts", "4", 4, "Hearts", 4),
		CardData.new("archive_7_diamonds", "7", 7, "Diamonds", 7),
		CardData.new("archive_9_clubs", "9", 9, "Clubs", 9),
	]
	scene.deal.deck.discard_pile.append_array(archive_cards)
	archive_button.pressed.emit()
	_check(scene.discard_archive_overlay.visible, "clicking the discard pile opens the archive")
	_check(scene.pile_archive_mode == "discard" and scene.pile_archive_title.text == "CHỒNG BÀI BỎ", "shared pile viewer switches to discard mode")
	_check(scene.discard_archive_count.text.begins_with("5 LÁ"), "discard archive reports every card in the pile")
	_check(scene.discard_archive_suit_grids["Spades"].get_child_count() == 2, "discard archive groups both Spades together")
	_check(scene.discard_archive_suit_grids["Hearts"].get_child_count() == 1, "discard archive groups Hearts")
	_check(scene.discard_archive_suit_grids["Diamonds"].get_child_count() == 1, "discard archive groups Diamonds")
	_check(scene.discard_archive_suit_grids["Clubs"].get_child_count() == 1, "discard archive groups Clubs")
	scene.discard_archive_close.pressed.emit()
	_check(not scene.discard_archive_overlay.visible, "discard archive close action restores the table")
	scene.deal.deck.discard_pile.clear()
	scene._sync_piles()
	scene.selected_card_ids.clear()
	var stable_meld := MeldState.new(77, MeldRules.TYPE_RUN, [
		CardData.new("smoke_3_spades", "3", 3, "Spades", 3),
		CardData.new("smoke_4_spades", "4", 4, "Spades", 4),
		CardData.new("smoke_5_spades", "5", 5, "Spades", 5),
	] as Array[CardData])
	scene.deal.melds.append(stable_meld)
	scene._sync_melds()
	await create_timer(0.22).timeout
	var stable_view := scene.meld_views.get(stable_meld.meld_id) as MeldView
	var stable_view_id := stable_view.get_instance_id() if stable_view != null else 0
	var stable_face_id := stable_view._cards_row.get_child(0).get_instance_id() if stable_view != null else 0
	scene._on_card_pressed(first_card)
	_check(scene.meld_views[stable_meld.meld_id].get_instance_id() == stable_view_id, "card selection preserves the existing Meld panel instance")
	_check(stable_view._cards_row.get_child(0).get_instance_id() == stable_face_id, "card selection preserves table Meld face instances")
	_check(stable_view.modulate.is_equal_approx(Color.WHITE) and stable_view.scale.is_equal_approx(Vector2.ONE), "card selection does not replay the Meld intro animation")
	scene._on_meld_pressed(stable_meld.meld_id)
	_check(scene.meld_views[stable_meld.meld_id].get_instance_id() == stable_view_id, "Meld targeting preserves the existing panel instance")
	stable_meld.extend([CardData.new("smoke_2_spades", "2", 2, "Spades", 2)] as Array[CardData])
	scene._sync_melds()
	_check(scene.meld_views[stable_meld.meld_id].get_instance_id() == stable_view_id, "extending a Meld updates its existing panel")
	_check(stable_view._card_views["smoke_3_spades"].get_instance_id() == stable_face_id, "extending a Meld preserves its existing card-face instances")
	_check(stable_view._cards_row.get_child_count() == 4, "extending a Meld adds only the new card face")
	scene.deal.melds.clear()
	scene.selected_card_ids.clear()
	scene._sync_melds()
	_check(scene.meld_views.is_empty(), "removed Meld panels leave the keyed view registry")
	for _turn in range(DealState.DISCARDS_PER_PHASE):
		scene.deal.discard_card(scene.deal.hand[0])
	scene._sync_all()
	_check(scene.deal.state == DealState.STATE_FINAL_COMMIT_WINDOW, "fourth discard enters LAST CALL without auto-settlement")
	_check(not scene.settle_button.disabled, "CHỐT becomes available during LAST CALL")
	_check(scene.discard_button.disabled, "additional discard remains blocked during LAST CALL")
	_check(scene.discard_history_row.get_child_count() == 5, "top-left discard history shows its phase marker and all four discards")
	_check((scene.discard_history_row.get_child(0) as Label).text == "P1", "top-left discard history labels the owning phase")
	scene.deal.discard_history.append(DiscardRecord.new(CardData.new("smoke_p2_discard", "A", 1, "Hearts", 1), 2, 1))
	scene._sync_discard_history()
	_check(scene.discard_history_row.get_child_count() == 7 and (scene.discard_history_row.get_child(5) as Label).text == "P2", "top-left discard history separates Phase 2 and restarts its turn order")
	archive_button.pressed.emit()
	_check(scene.discard_archive_overlay.visible and scene.discard_archive_count.text.begins_with("4 LÁ"), "pile archive includes all four live discards")
	scene.discard_archive_close.pressed.emit()

	var beat_meld_cards: Array[CardData] = [
		CardData.new("beat_3_spades", "3", 3, "Spades", 3),
		CardData.new("beat_4_spades", "4", 4, "Spades", 4),
		CardData.new("beat_5_spades", "5", 5, "Spades", 5),
		CardData.new("beat_q_hearts", "Q", 12, "Hearts", 12),
	]
	scene.deal.hand.clear()
	scene.deal.hand.append_array(beat_meld_cards)
	scene.deal.melds.clear()
	scene.selected_card_ids.clear()
	scene.selected_meld_id = -1
	scene._sync_all()
	await create_timer(0.22).timeout
	_check(scene.reactive_hand_cards_by_band[0].size() == 1 and scene.reactive_hand_cards_by_band[1].size() == 1 and scene.reactive_hand_cards_by_band[2].size() == 1 and scene.reactive_hand_cards_by_band[3].is_empty(), "legal loose Meld cards map left-to-right across independent frequency bands")
	var beat_hand_views: Array[PlayingCardView] = []
	for beat_card: CardData in beat_meld_cards.slice(0, 3):
		var beat_view := scene.hand_views[beat_card.unique_id] as PlayingCardView
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
	scene.selected_card_ids.clear()
	scene.selected_card_ids[extension_card.unique_id] = true
	scene._sync_all()
	await create_timer(0.22).timeout
	_check(scene.reactive_meld_cards_by_band[0].size() == 1 and scene.reactive_meld_cards_by_band[1].size() == 1 and scene.reactive_meld_cards_by_band[2].size() == 1, "selected legal extension maps the target Meld cards left-to-right across frequency bands")
	var beat_meld_view := scene.meld_views[beat_table_meld.meld_id] as MeldView
	var beat_table_textures: Array[TextureRect] = []
	for table_card: CardData in beat_table_meld.cards:
		var table_texture := beat_meld_view._card_views[table_card.unique_id] as TextureRect
		table_texture.scale = Vector2.ONE
		beat_table_textures.append(table_texture)
	scene._on_music_band_pulse(2, 1.0)
	await create_timer(0.06).timeout
	_check(beat_table_textures[2].scale.y > 1.01, "third target-Meld card pulses on its assigned TA frequency band")
	_check(beat_table_textures[0].scale.is_equal_approx(Vector2.ONE) and beat_table_textures[1].scale.is_equal_approx(Vector2.ONE), "TA pulse leaves differently assigned target-Meld cards still")
	for active_tween in scene.logo_bounce_tweens.values():
		if active_tween is Tween and active_tween.is_valid():
			active_tween.kill()
	for active_view in scene.hand_views.values():
		if active_view is PlayingCardView:
			active_view.set_action_cues(false, false)
	for active_meld_view in scene.meld_views.values():
		if active_meld_view is MeldView:
			active_meld_view.set_process(false)
	scene.queue_free()
	await process_frame
	for autoload_name in ["GameSettings", "_mcp_game_helper"]:
		var autoload_node := root.get_node_or_null(autoload_name)
		if autoload_node != null:
			autoload_node.queue_free()
	await process_frame
	_finish()


func _check(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)


func _finish() -> void:
	if _failures.is_empty():
		print("TRADATALA_SCENE_SMOKE passed")
		quit(0)
	else:
		for failure in _failures:
			print("SCENE_SMOKE_FAIL: %s" % failure)
		quit(1)

