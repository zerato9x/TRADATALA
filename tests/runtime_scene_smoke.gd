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
		has_mom_rule = has_mom_rule or (special_label.text.contains("0 Phỏm MỚI") and special_label.text.contains("Tổng × Số lá") and special_label.text.contains("mỗi Giai đoạn"))
		has_u_rule = has_u_rule or (special_label.text.contains("dùng đúng 9") and special_label.text.contains("Gross ×2"))
		has_u_khan_rule = has_u_khan_rule or (special_label.text.contains("cách nhau 1–2 số") and special_label.text.contains("×10"))
	_check(special_page.visible and has_mom_rule and has_u_rule and has_u_khan_rule, "Special Outcomes explains multiplied Móm deadwood, Ù, and the ×10 Ù Khan authority")
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
	_check(scene.music_settings_label.text == "MUSIC" and scene.sound_settings_label.text == "SOUND" and scene.hint_button.text == "HINT  [G]" and (scene.header_caption_labels["VndPerPointStat"] as Label).text == "VND / POINT", "English selection refreshes Options, gameplay controls, and the VND-per-point caption")
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
	_check(scene.campaign.current_phase == CampaignManager.CampaignPhase.STARTER_EVENT, "New Game starts the Monday Starter Event before any Deal")
	_check(scene.campaign_overlay.visible and scene.current_campaign_event != null, "generic campaign Event UI opens above the existing Deal table")
	_check(scene.current_campaign_event.participants.size() == 1 and scene.current_campaign_event.participants[0].id == CampaignNpcCatalog.TRA_DA_AUNTIE, "Cô Trà Đá is the guaranteed Starter Event participant")
	_check(not scene.current_campaign_event.can_exit and scene.campaign_continue_button.disabled, "mandatory Drink selection blocks Event exit")
	var starter_drink_button := scene.campaign_overlay.find_child("Drink_tra_da", true, false) as Button
	_check(starter_drink_button != null and not starter_drink_button.disabled, "free Trà đá is purchasable in the Starter Event")
	starter_drink_button.pressed.emit()
	await process_frame
	_check(scene.current_campaign_event.can_exit and not scene.campaign_continue_button.disabled, "selecting a Drink completes Cô Trà Đá's mandatory interaction")
	_check(scene.drink_manager.morning_drink_id == DrinkCatalog.TRA_DA and scene.deal.wallet.balance_vnd == 0, "Starter Drink is assigned to Morning/Noon without inventing a charge for free Trà đá")
	scene.campaign_continue_button.pressed.emit()
	await process_frame
	_check(scene.campaign.current_phase == CampaignManager.CampaignPhase.MORNING_DEAL and not scene.campaign_overlay.visible, "continuing the Starter Event hands off to the existing Morning Deal")
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
	var income_panel := scene.get_node_or_null("GameLayer/Header/HeaderRow/IncomeStat") as PanelContainer
	_check(income_panel != null, "Income remains in the top stat row")
	var vnd_per_point_panel := scene.get_node_or_null("GameLayer/Header/HeaderRow/VndPerPointStat") as PanelContainer
	_check(vnd_per_point_panel != null and income_panel != null and vnd_per_point_panel.get_index() == income_panel.get_index() - 1, "VND-per-point HUD panel sits immediately to the left of Income")
	_check(scene.vnd_per_point_value != null, "VND-per-point HUD exposes its value label")
	_check(vnd_per_point_panel != null and scene.vnd_per_point_value != null and vnd_per_point_panel.is_ancestor_of(scene.vnd_per_point_value), "VND-per-point value label belongs to its HUD panel")
	_check(scene.vnd_per_point_value != null and scene.vnd_per_point_value.text == VndWallet.format_vnd(scene.deal.vnd_per_point), "VND-per-point HUD matches the economy authority")
	_check(scene.get_node_or_null("GameLayer/Header/HeaderRow/WalletStat") != null, "Wallet remains in the top stat row")
	_check(scene.get_node_or_null("GameLayer/Header/HeaderRow/CampaignStat") != null and scene.campaign_value.text.contains("THỨ HAI"), "campaign day and requirement remain visible during the Deal")
	_check(scene.get_node_or_null("GameLayer/Header/HeaderRow/PhaseStat") == null and scene.get_node_or_null("GameLayer/Header/HeaderRow/TurnStat") == null, "Phase and Turn stat cards are removed")
	_check(scene.get_node_or_null("GameLayer/UtilityRail/DrinkArea/DrinkSlot") == scene.drink_button, "Drink slot is a clickable effect button")
	_check(scene.get_node_or_null("GameLayer/TableSurface/DrinkProps/ActiveDrink") == scene.drink_table_button, "active Drink has a clickable in-world table prop")
	_check(scene.get_node_or_null("GameLayer/TableSurface/DrinkProps/EmptyDrinkProp") == scene.empty_drink_prop, "the morning empty-glass prop exists for the noon handoff")
	_check(scene.drink_table_texture != null and scene.drink_table_texture.texture != null and scene.drink_table_texture.texture.resource_path == "res://assets/drinks/tra_da_full.png", "unused starter Drink shows its full sprite")
	_check(scene.empty_drink_prop != null and scene.empty_drink_prop.texture != null and scene.empty_drink_prop.texture.resource_path == "res://assets/drinks/glass_empty.png", "noon handoff uses the shared empty-glass sprite")
	_check(not scene.empty_drink_prop.visible, "morning starts with one active Drink and no phantom empty glass")
	_check(scene.drink_table_button.position == MatchUI.DRINK_TABLE_MORNING_POSITION, "morning Drink occupies the bottom-left table position")
	_check(scene.drink_table_button.size == MatchUI.DRINK_TABLE_PROP_SIZE and scene.drink_table_button.size.y > MatchUI.CARD_SIZE.y, "Drink props use a readable near-card-height table footprint")
	_check(scene.drink_table_button.position.x >= 60.0, "morning Drink is inset from the painted table edge")
	scene.campaign.current_phase = CampaignManager.CampaignPhase.NOON_DEAL
	scene._sync_drink_table_visual()
	_check(scene.drink_table_texture.texture.resource_path == "res://assets/drinks/tra_da_half.png", "the noon Deal shows the carried-over Drink half-empty")
	scene.campaign.current_phase = CampaignManager.CampaignPhase.MORNING_DEAL
	scene._sync_drink_table_visual()
	scene.drink_manager.afternoon_drink_id = DrinkCatalog.SAM_DUA
	scene._sync_drink_table_visual()
	_check(scene.empty_drink_prop.visible, "selecting the noon Drink turns the remembered morning Drink into an empty glass")
	_check(scene.empty_drink_prop.position == MatchUI.DRINK_TABLE_EMPTY_POSITION and scene.drink_table_button.position == MatchUI.DRINK_TABLE_NOON_POSITION, "noon empty and active glasses sit side-by-side in the bottom-left corner")
	_check(scene.empty_drink_prop.size == scene.drink_table_button.size, "empty and active glasses preserve the same physical scale")
	scene.drink_manager.afternoon_drink_id = DrinkCatalog.NONE
	scene._sync_drink_table_visual()
	_check(scene.drink_name_label != null and scene.drink_name_label.text == "TRÀ ĐÁ", "free Trà đá is the visible starter Drink")
	_check(not scene.drink_button.disabled, "active Drink remains clickable after Deal setup")
	_check(scene.drink_charge_outline != null and scene.drink_charge_outline.visible and scene.drink_charge_outline.cue_mode() == CardActionOutlineScript.CUE_DRINK and scene.drink_charge_outline.is_processing(), "unused Drink charge has an animated blue gradient around the right-side Drink box")
	_check(scene.drink_button.tooltip_text.contains("lá bỏ mới nhất") and scene.drink_button.tooltip_text.contains("nhấn Đồ uống"), "Drink tooltip explains how to activate Trà đá and its latest-discard limit")
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
	settings.set_locale("en")
	await process_frame
	var english_probability_copy := first_view.tooltip_text.contains("Need:") or first_view.tooltip_text.contains("Ready to Meld:")
	_check(english_probability_copy and not first_view.tooltip_text.contains("Cần:") and not first_view.tooltip_text.contains("Sẵn sàng"), "English locale translates the live meld-probability guidance (got: %s)" % first_view.tooltip_text.replace("\n", " / "))
	settings.set_locale("vi")
	await process_frame
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
	var action_outline := first_view.get_node_or_null("BeatVisual/ActionOutline")
	_check(action_outline != null, "each loose card has an animated action outline")
	_check(action_outline != null and action_outline.get_parent() == first_view._beat_visual, "action outline shares the card's beat transform")
	first_view.set_action_cues(true, false)
	_check(action_outline != null and action_outline.visible and action_outline.cue_mode() == CardActionOutlineScript.CUE_MELD and action_outline.is_processing(), "meldable cards animate with the green cue")
	first_view.set_action_cues(false, true)
	_check(action_outline != null and action_outline.visible and action_outline.cue_mode() == CardActionOutlineScript.CUE_EXTEND, "extendable cards animate with the yellow cue")
	first_view.set_action_cues(false, false)
	_check(action_outline != null and not action_outline.visible and not action_outline.is_processing(), "non-actionable cards do not carry an outline")
	var drink_outline := first_view.get_node_or_null("BeatVisual/DrinkOutline")
	first_view.set_drink_preserved(true)
	_check(drink_outline != null and drink_outline.visible and drink_outline.cue_mode() == CardActionOutlineScript.CUE_DRINK and drink_outline.is_processing(), "Drink-marked cards carry a separate animated blue gradient outline")
	first_view.set_drink_preserved(false)
	_check(drink_outline != null and not drink_outline.visible and not drink_outline.is_processing(), "clearing a Drink mark removes only the blue outline")
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
	scene.deal.set_current_drink(DrinkCatalog.NHAN_TRAN)
	scene._sync_all()
	var nhan_extra: CardData = scene.deal.hand[1]
	var nhan_mandatory: CardData = scene.deal.hand[2]
	var nhan_draw_before := scene.deal.deck.draw_pile.size()
	scene._on_card_pressed(nhan_extra)
	scene._on_card_pressed(nhan_mandatory)
	_check(not scene.discard_button.disabled, "Nhan Tran enables DISCARD with two selected loose cards")
	await scene._on_discard_pressed()
	_check(scene.deal.discard_count == 1, "the combined Nhan Tran action still counts one mandatory turn discard")
	_check(scene.deal.hand.size() == DealState.ACTIVE_HAND_TARGET, "the combined discard refills the hand back to ten")
	_check(scene.deal.deck.draw_pile.size() == nhan_draw_before - 2, "the combined action draws two cards once after both discards")
	_check(scene.deal.deck.discard_pile.size() >= 2 and scene.deal.deck.discard_pile[-2] == nhan_extra and scene.deal.deck.discard_pile[-1] == nhan_mandatory, "the selected pair reaches the discard pile in extra-then-mandatory order")
	scene.deal.set_current_drink(DrinkCatalog.TRA_DA)
	scene._sync_all()
	scene.deal.deck.discard_pile.clear()
	scene._sync_piles()
	scene.deal.discard_history.clear()
	scene.deal.discard_count = 0
	scene.deal.state = DealState.STATE_ACTIVE
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
	scene.deal.set_current_drink(DrinkCatalog.NUOC_VOI)
	stable_meld.scored_points = ScoringPipeline.meld_value(stable_meld.cards)
	scene._sync_all()
	_check(scene.drink_button.tooltip_text.contains("chọn trực tiếp 1 lá trong Phỏm"), "switching Drinks refreshes the clickable effect tooltip")
	var removable_endpoint: CardData = stable_meld.cards[0]
	scene._on_meld_card_pressed(stable_meld.meld_id, removable_endpoint)
	_check(scene.selected_drink_meld_card_id.is_empty(), "Nước vối ignores table-card targeting until the Drink is clicked first")
	scene.drink_button.pressed.emit()
	await process_frame
	_check(scene.drink_targeting_active, "clicking charged Nước vối arms its card-targeting mode without spending it")
	scene._on_meld_card_pressed(stable_meld.meld_id, removable_endpoint)
	_check(scene.selected_drink_meld_card_id == removable_endpoint.unique_id, "after arming Nước vối, clicking a legal table card selects it")
	var table_drink_outline := stable_view._card_drink_outlines.get(removable_endpoint.unique_id) as Control
	_check(table_drink_outline != null and table_drink_outline.visible and table_drink_outline.cue_mode() == CardActionOutlineScript.CUE_DRINK, "the armed Nước vối target receives the blue gradient before resolution")
	await create_timer(0.2).timeout
	_check(stable_meld.cards.size() == 3 and scene.deal.hand.has(removable_endpoint), "clicking the armed Nước vối target returns it to the loose hand")
	_check(scene.deal.nuoc_voi_used_phases.has(scene.deal.current_phase), "Nước vối becomes spent for the current Phase")
	_check(not scene.drink_charge_outline.visible and not scene.drink_charge_outline.is_processing(), "Nước vối blue charge outline disappears immediately after use")
	_check(scene.drink_table_texture.texture.resource_path == "res://assets/drinks/nuoc_voi_half.png", "spent Nuoc voi changes its table prop from full to half-full")
	scene.deal.set_current_drink(DrinkCatalog.TRA_DA)
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
	scene.deal.set_current_drink(DrinkCatalog.SAM_DUA)
	scene._sync_all()
	_check(scene.drink_charge_outline.visible, "unused Sâm dứa charge shows the blue Drink-box outline")
	var pre_arm_card: CardData = scene.deal.hand[0]
	scene._on_card_pressed(pre_arm_card)
	var pre_arm_outline := (scene.hand_views.get(pre_arm_card.unique_id) as PlayingCardView).get_node_or_null("BeatVisual/DrinkOutline") as Control
	_check(not pre_arm_outline.visible and scene.pending_drink_card_ids.is_empty(), "ordinary card clicks do not become Drink targets before Sâm dứa is armed")
	scene.selected_card_ids.clear()
	scene._sync_all()
	scene.drink_button.pressed.emit()
	await process_frame
	_check(scene.drink_targeting_active, "clicking Sâm dứa first arms its multi-card targeting mode")
	scene._on_card_pressed(scene.deal.hand[0])
	scene._on_card_pressed(scene.deal.hand[1])
	_check(scene.pending_drink_card_ids.size() == 2 and scene.deal.sam_dua_preserved_cards.is_empty(), "the first two post-arm card clicks remain a pending Sâm dứa selection")
	for pending_card in scene._pending_drink_cards():
		var pending_view := scene.hand_views.get(pending_card.unique_id) as PlayingCardView
		var pending_outline := pending_view.get_node_or_null("BeatVisual/DrinkOutline") as Control
		_check(pending_outline.visible and pending_outline.cue_mode() == CardActionOutlineScript.CUE_DRINK, "each pending Sâm dứa card immediately receives the blue gradient")
	scene.drink_button.pressed.emit()
	await process_frame
	_check(scene.deal.sam_dua_preserved_cards.size() == 2, "clicking Sâm dứa during Phase 1 LAST CALL marks up to two selected loose cards for DUMP")
	_check(scene.drink_button.tooltip_text.contains("Đã đánh dấu giữ 2 lá"), "Sâm dứa tooltip reports the marked preservation count")
	_check(not scene.drink_charge_outline.visible, "Sâm dứa blue charge outline disappears after its preservation effect is spent")
	for preserved_card in scene.deal.sam_dua_preserved_cards:
		var preserved_view := scene.hand_views.get(preserved_card.unique_id) as PlayingCardView
		var preserved_outline: Control = preserved_view.get_node_or_null("BeatVisual/DrinkOutline") if preserved_view != null else null
		_check(preserved_outline != null and preserved_outline.visible and preserved_outline.cue_mode() == CardActionOutlineScript.CUE_DRINK, "each Sâm dứa preservation card keeps the blue stay outline")
	scene.deal.set_current_drink(DrinkCatalog.TRA_DA)
	scene.deal.sam_dua_preserved_cards.clear()
	scene.selected_card_ids.clear()
	scene._sync_card_action_outlines()
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
	_check(scene.reactive_hand_cards_by_band[0].is_empty() and scene.reactive_hand_cards_by_band[1].is_empty() and scene.reactive_hand_cards_by_band[2].is_empty() and scene.reactive_hand_cards_by_band[3].is_empty(), "legal loose Meld cards stay still until the player selects one")
	scene._on_card_pressed(beat_meld_cards[0])
	_check(scene.reactive_hand_cards_by_band[0].size() == 1 and scene.reactive_hand_cards_by_band[1].size() == 1 and scene.reactive_hand_cards_by_band[2].size() == 1 and scene.reactive_hand_cards_by_band[3].is_empty(), "selecting one legal Meld card maps that Meld left-to-right across frequency bands")
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
	scene.selected_meld_id = -1
	scene._sync_all()
	await create_timer(0.22).timeout
	_check(scene.reactive_hand_cards_by_band[0].is_empty(), "an extendable hand card stays still before a table Meld is selected")
	scene._on_meld_pressed(beat_table_meld.meld_id)
	_check(scene.reactive_hand_cards_by_band[0].size() == 1 and scene.reactive_hand_cards_by_band[0][0] == scene.hand_views[extension_card.unique_id], "selecting a table Meld makes its extendable hand card reactive")
	scene._on_meld_pressed(beat_table_meld.meld_id)
	_check(scene.reactive_hand_cards_by_band[0].is_empty(), "deselecting the table Meld stops the extendable hand-card cue")
	scene._on_card_pressed(extension_card)
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

	var drag_run: Array[CardData] = [
		CardData.new("drag_3_hearts", "3", 3, "Hearts", 3),
		CardData.new("drag_4_hearts", "4", 4, "Hearts", 4),
		CardData.new("drag_5_hearts", "5", 5, "Hearts", 5),
	]
	var drag_extension := CardData.new("drag_6_hearts", "6", 6, "Hearts", 6)
	var drag_discard := CardData.new("drag_k_clubs", "K", 13, "Clubs", 13)
	scene.deal.hand.clear()
	scene.deal.hand.append_array(drag_run)
	scene.deal.hand.append_array([drag_extension, drag_discard] as Array[CardData])
	scene.deal.melds.clear()
	scene.deal.state = DealState.STATE_ACTIVE
	scene.deal.discard_count = 0
	scene.selected_card_ids.clear()
	for drag_card in drag_run:
		scene.selected_card_ids[drag_card.unique_id] = true
	scene.selected_meld_id = -1
	scene.interaction_locked = false
	scene._sync_all()
	await process_frame
	var original_last_id := scene.deal.hand[-1].unique_id
	var reordered := scene._reorder_hand_card(drag_discard, scene.hand_layer.get_global_rect().position.x)
	_check(reordered and scene.deal.hand[0] == drag_discard and original_last_id == drag_discard.unique_id, "dropping within the hand reorders the dragged card without changing gameplay state")
	var run_source := scene.hand_views[drag_run[0].unique_id] as PlayingCardView
	scene._on_card_drag_started(drag_run[0], run_source.get_global_rect().get_center(), run_source)
	_check(scene.active_drag_payload != null and scene.active_drag_payload.source_zone == CardDragPayloadScript.SOURCE_HAND and scene.active_drag_payload.cards.size() == 3, "dragging one selected Meld card carries the full selected group from the hand source")
	_check(scene.drag_preview != null and not scene.drag_target_overlays.is_empty(), "an active drag shows a card preview and legal drop-target feedback")
	var future_table_payload = CardDragPayloadScript.new(
		CardDragPayloadScript.SOURCE_TABLE_MELD,
		99,
		drag_run[0].unique_id,
		[drag_run[0]] as Array[CardData]
	)
	_check(scene._card_drag_action(future_table_payload, {"kind": scene.DROP_TARGET_HAND, "meld_id": -1}) == scene.DRAG_ACTION_NONE, "table-Meld drag sources are represented but remain disabled until the future verb is balanced")
	var table_drop_position := scene.table_surface.get_global_rect().get_center()
	_check(scene._card_drop_target_at(table_drop_position)["kind"] == scene.DROP_TARGET_TABLE, "the open table resolves as the new-Meld drop target")
	scene._finish_card_drag(table_drop_position)
	_check(await _wait_for_scene_unlock(scene), "dragging selected cards to the table completes the Meld action")
	_check(scene.deal.melds.size() == 1 and scene.deal.melds[0].cards.size() == 3, "the table drop commits the selected three-card Meld")
	var created_meld_id: int = scene.deal.melds[0].meld_id
	var extension_source := scene.hand_views[drag_extension.unique_id] as PlayingCardView
	var created_meld_view := scene.meld_views[created_meld_id] as MeldView
	scene._on_card_drag_started(drag_extension, extension_source.get_global_rect().get_center(), extension_source)
	_check(scene._card_drop_target_at(created_meld_view.get_global_rect().get_center())["kind"] == scene.DROP_TARGET_MELD, "an existing Meld resolves as an extension drop target")
	scene._finish_card_drag(created_meld_view.get_global_rect().get_center())
	_check(await _wait_for_scene_unlock(scene), "dragging a compatible loose card onto a Meld completes the extension action")
	_check(scene.deal.melds[0].cards.size() == 4 and scene.deal.melds[0].cards.has(drag_extension), "the Meld drop commits the dragged extension card")
	var discard_source := scene.hand_views[drag_discard.unique_id] as PlayingCardView
	scene._on_card_drag_started(drag_discard, discard_source.get_global_rect().get_center(), discard_source)
	var discard_drop_position := scene.discard_pile_visual.get_global_rect().get_center()
	_check(scene._card_drop_target_at(discard_drop_position)["kind"] == scene.DROP_TARGET_DISCARD, "the discard pile resolves as the discard drop target")
	scene._finish_card_drag(discard_drop_position)
	_check(await _wait_for_scene_unlock(scene), "dragging one card to the discard pile completes the discard action")
	_check(not scene.deal.deck.discard_pile.is_empty() and scene.deal.deck.discard_pile[-1] == drag_discard, "the discard drop commits only the dragged card")
	scene._show_campaign_outcome(true)
	_check(scene.campaign_overlay.visible and scene.campaign_event_title.text == "CHIẾN THẮNG" and not scene.campaign_continue_button.disabled, "campaign victory uses the generic campaign overlay and offers a new run")
	scene._show_campaign_outcome(false)
	_check(scene.campaign_event_title.text == "CHƯA ĐỦ TIỀN" and scene.campaign_event_wallet.text.contains("Ví cuối"), "campaign failure reports the final wallet on the same outcome surface")
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


func _wait_for_scene_unlock(scene: MatchUI, max_frames: int = 480) -> bool:
	for _frame in range(max_frames):
		if not scene.interaction_locked and not scene.score_overlay.visible:
			return true
		await process_frame
	return false


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

