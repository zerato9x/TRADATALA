class_name MatchUI
extends Control

signal tutorial_step_changed(step: StringName)

const CARD_SIZE := PlayingCardView.CARD_SIZE
const INITIAL_RELIC_SLOT_COUNT := 4
const MUSIC_BAND_COUNT := 4
const GAME_SETTINGS_SCRIPT := preload("res://scripts/settings/game_settings.gd")
const TUTORIAL_SPOTLIGHT_SCRIPT := preload("res://scripts/ui/tutorial_spotlight.gd")
const CARD_DRAG_PAYLOAD_SCRIPT := preload("res://scripts/ui/card_drag_payload.gd")
const CARD_ACTION_OUTLINE_SCRIPT := preload("res://scripts/ui/card_action_outline.gd")
const DROP_TARGET_NONE := &"none"
const DROP_TARGET_HAND := &"hand"
const DROP_TARGET_TABLE := &"table"
const DROP_TARGET_MELD := &"meld"
const DROP_TARGET_DISCARD := &"discard"
const DRAG_ACTION_NONE := &"none"
const DRAG_ACTION_REORDER := &"reorder"
const DRAG_ACTION_CREATE_MELD := &"create_meld"
const DRAG_ACTION_EXTEND_MELD := &"extend_meld"
const DRAG_ACTION_DISCARD := &"discard"
const TUTORIAL_SELECT_RUN := &"select_run"
const TUTORIAL_PLAY_RUN := &"play_run"
const TUTORIAL_MELD_SCORE := &"meld_score"
const TUTORIAL_SELECT_DISCARD := &"select_discard"
const TUTORIAL_DISCARD := &"discard"
const TUTORIAL_SELECT_EXTEND := &"select_extend"
const TUTORIAL_SELECT_MELD := &"select_meld"
const TUTORIAL_EXTEND := &"extend"
const TUTORIAL_EXTEND_SCORE := &"extend_score"
const TUTORIAL_SELECT_FINAL_DISCARD := &"select_final_discard"
const TUTORIAL_FINAL_DISCARD := &"final_discard"
const TUTORIAL_MOM := &"mom"
const TUTORIAL_U := &"u"
const TUTORIAL_U_KHAN := &"u_khan"
const TUTORIAL_COMPLETE := &"complete"
const TUTORIAL_RUN_IDS := [&"standard_4_hearts", &"standard_5_hearts", &"standard_6_hearts"]
const TUTORIAL_FIRST_DISCARD_ID := &"standard_q_diamonds"
const TUTORIAL_EXTENSION_ID := &"standard_7_hearts"
const TUTORIAL_FINAL_DISCARD_ID := &"standard_k_spades"

var deal := DealState.new()
var event_manager: EventManager
var drink_manager: DrinkManager
var campaign: CampaignManager
var current_campaign_event: EventInstance
var selected_card_ids: Dictionary = {}
var selected_meld_id: int = -1
var hand_views: Dictionary = {}
var displayed_wallet_vnd: int = 0
var interaction_locked: bool = false
var sort_mode: int = 0
var modal_mode: String = ""
var game_started: bool = false
var menu_transitioning: bool = false
var settings

var game_layer: Control
var menu_layer: Control
var menu_home_panel: VBoxContainer
var how_to_play_panel: PanelContainer
var options_panel: PanelContainer
var play_button: Button
var how_to_play_button: Button
var tutorial_button: Button
var options_button: Button
var how_to_play_back_button: Button
var options_back_button: Button
var menu_button: Button
var music_slider: HSlider
var sound_slider: HSlider
var music_settings_label: Label
var sound_settings_label: Label
var language_settings_label: Label
var music_value_label: Label
var sound_value_label: Label
var language_selector: OptionButton
var menu_page: StringName = &"home"
var menu_localized_controls: Dictionary = {}
var tutorial_active: bool = false
var tutorial_step: StringName = &""
var tutorial_wallet_before: int = 0
var tutorial_meld_id: int = -1
var tutorial_outcome_visible: bool = false
var tutorial_coach: PanelContainer
var tutorial_progress_label: Label
var tutorial_title_label: Label
var tutorial_body_label: Label
var tutorial_exit_button: Button
var tutorial_spotlight: TutorialSpotlight
var how_to_play_tab: StringName = &"cards"
var how_tab_buttons: Dictionary = {}
var how_tab_pages: Dictionary = {}
var how_scoring_topic: StringName = &"basic"
var how_scoring_topic_buttons: Dictionary = {}
var how_scoring_topic_pages: Dictionary = {}
var logo_segments: Array[Label] = []
var logo_bounce_tweens: Dictionary = {}
var reactive_hand_cards_by_band: Dictionary = {}
var reactive_meld_cards_by_band: Dictionary = {}
var music_controller: ReactiveMusicController
var relic_grid: GridContainer
var drink_name_label: Label
var drink_button: Button
var drink_charge_outline: Control
var drink_targeting_active: bool = false
var pending_drink_card_ids: Dictionary = {}
var selected_drink_meld_id: int = -1
var selected_drink_meld_card_id: String = ""

var earnings_value: Label
var wallet_value: Label
var campaign_value: Label
var header_caption_labels: Dictionary = {}
var draw_count: Label
var discard_count_label: Label
var pile_caption_labels: Dictionary = {}
var pile_archive_buttons: Dictionary = {}
var discard_texture: TextureRect
var status_label: Label
var table_surface: Control
var hand_layer: Control
var meld_scroll: ScrollContainer
var meld_row: HBoxContainer
var empty_meld_label: Label
var meld_views: Dictionary = {}
var discard_history_row: HBoxContainer
var discard_history_title: Label
var draw_pile_visual: Control
var discard_pile_visual: Control
var ha_button: Button
var extend_button: Button
var discard_button: Button
var settle_button: Button
var hint_button: Button
var sort_button: Button
var drink_title_label: Label
var relic_title_label: Label
var particle_layer: Control
var active_drag_payload
var active_drag_source: PlayingCardView
var drag_preview: Control
var drag_target_overlays: Array[Control] = []

var discard_archive_overlay: Control
var pile_archive_title: Label
var pile_archive_mode: String = "discard"
var discard_archive_count: Label
var discard_archive_suit_grids: Dictionary = {}
var discard_archive_suit_titles: Dictionary = {}
var discard_archive_close: Button

var score_overlay: Control
var score_panel: Panel
var score_title: Label
var score_line_a: Label
var score_line_b: Label
var score_payout: Label

var modal_overlay: Control
var modal_title: Label
var modal_kicker: Label
var modal_body: Label
var modal_detail: Label
var modal_primary: Button
var modal_secondary: Button

var banner_panel: PanelContainer
var banner_label: Label

var campaign_overlay: Control
var campaign_event_kicker: Label
var campaign_event_title: Label
var campaign_event_wallet: Label
var campaign_participants: VBoxContainer
var campaign_continue_button: Button


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	theme = PresentationTheme.create_game_theme()
	custom_minimum_size = Vector2(960, 620)
	interaction_locked = true
	settings = get_node_or_null("/root/GameSettings")
	if settings == null:
		settings = GAME_SETTINGS_SCRIPT.new()
		settings.name = "GameSettings"
		get_tree().root.add_child(settings)
	_build_interface()
	_build_music()
	settings.locale_changed.connect(_on_locale_changed)
	get_viewport().size_changed.connect(_on_viewport_size_changed)
	var result := deal.start_deal(-1, true)
	displayed_wallet_vnd = deal.wallet.balance_vnd
	event_manager = EventManager.new()
	CampaignNpcCatalog.register_initial_npcs(event_manager)
	drink_manager = DrinkManager.new(deal.wallet)
	campaign = CampaignManager.new(deal.wallet, event_manager, drink_manager)
	campaign.event_started.connect(_on_campaign_event_started)
	campaign.deal_requested.connect(_on_campaign_deal_requested)
	campaign.requirement_passed.connect(_on_campaign_requirement_passed)
	campaign.campaign_won.connect(_on_campaign_won)
	campaign.campaign_lost.connect(_on_campaign_lost)
	_sync_all(result, true)
	_set_hand_interaction_enabled(false)
	_park_game_layer()


func _exit_tree() -> void:
	if campaign == null:
		return
	var connections := [
		[&"event_started", Callable(self, "_on_campaign_event_started")],
		[&"deal_requested", Callable(self, "_on_campaign_deal_requested")],
		[&"requirement_passed", Callable(self, "_on_campaign_requirement_passed")],
		[&"campaign_won", Callable(self, "_on_campaign_won")],
		[&"campaign_lost", Callable(self, "_on_campaign_lost")],
	]
	for connection in connections:
		if campaign.is_connected(connection[0], connection[1]):
			campaign.disconnect(connection[0], connection[1])


func _build_interface() -> void:
	var background := TextureRect.new()
	background.name = "SidewalkTableBackground"
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	background.texture = load("res://assets/environment/sidewalk_table.png") as Texture2D
	background.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	background.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	background.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(background)

	game_layer = Control.new()
	game_layer.name = "GameLayer"
	game_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(game_layer)

	_build_header()
	_build_table()
	_build_hand()
	_build_future_slots()
	_build_action_dock()
	_build_effect_layers()
	_build_main_menu()


func _build_main_menu() -> void:
	menu_layer = Control.new()
	menu_layer.name = "MainMenu"
	menu_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	menu_layer.mouse_filter = Control.MOUSE_FILTER_STOP
	menu_layer.z_index = 500
	add_child(menu_layer)

	var shade := ColorRect.new()
	shade.name = "MenuShade"
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.color = Color("#090704a6")
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	menu_layer.add_child(shade)

	var center := CenterContainer.new()
	center.name = "MenuCenter"
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	menu_layer.add_child(center)

	var column := VBoxContainer.new()
	column.name = "MenuContent"
	column.custom_minimum_size = Vector2(980, 620)
	column.alignment = BoxContainer.ALIGNMENT_CENTER
	column.add_theme_constant_override("separation", 12)
	center.add_child(column)

	var logo := HBoxContainer.new()
	logo.name = "Logo"
	logo.alignment = BoxContainer.ALIGNMENT_CENTER
	logo.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	logo.add_theme_constant_override("separation", -2)
	column.add_child(logo)
	for segment_text in ["TRA", "DA", "TA", "LA"]:
		var segment := Label.new()
		segment.name = segment_text
		segment.text = segment_text
		segment.custom_minimum_size.y = 80
		segment.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		segment.add_theme_font_size_override("font_size", 66)
		segment.add_theme_color_override("font_color", PresentationTheme.GOLD)
		segment.mouse_filter = Control.MOUSE_FILTER_IGNORE
		logo.add_child(segment)
		logo_segments.append(segment)

	menu_home_panel = VBoxContainer.new()
	menu_home_panel.name = "HomePanel"
	menu_home_panel.custom_minimum_size = Vector2(500, 220)
	menu_home_panel.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	menu_home_panel.alignment = BoxContainer.ALIGNMENT_CENTER
	menu_home_panel.add_theme_constant_override("separation", 12)
	column.add_child(menu_home_panel)
	play_button = Button.new()
	play_button.name = "PlayButton"
	_register_menu_text(play_button, "MENU_NEW_GAME")
	play_button.custom_minimum_size = Vector2(500, 54)
	play_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	PresentationTheme.configure_button(play_button, "gold")
	play_button.add_theme_font_size_override("font_size", 18)
	play_button.pressed.connect(_on_play_pressed)
	menu_home_panel.add_child(play_button)

	var learn_row := HBoxContainer.new()
	learn_row.name = "LearnRow"
	learn_row.alignment = BoxContainer.ALIGNMENT_CENTER
	learn_row.add_theme_constant_override("separation", 12)
	menu_home_panel.add_child(learn_row)
	how_to_play_button = _build_menu_navigation_button(learn_row, "HowToPlayButton", "MENU_HOW_TO_PLAY", 244)
	how_to_play_button.pressed.connect(_show_menu_page.bind(&"how_to_play"))
	tutorial_button = _build_menu_navigation_button(learn_row, "TutorialButton", "MENU_TUTORIAL", 244)
	tutorial_button.pressed.connect(_on_tutorial_pressed)
	options_button = _build_menu_navigation_button(menu_home_panel, "OptionsButton", "MENU_OPTIONS", 500)
	options_button.pressed.connect(_show_menu_page.bind(&"options"))

	_build_how_to_play(column)
	_build_menu_settings(column)
	_show_menu_page(&"home")
	call_deferred("_refresh_logo_pivots")


func _build_menu_navigation_button(parent: Container, node_name: String, translation_key: String, width: float = 340.0) -> Button:
	var button := Button.new()
	button.name = node_name
	button.custom_minimum_size = Vector2(width, 48)
	button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_register_menu_text(button, translation_key)
	PresentationTheme.configure_button(button, "neutral")
	button.add_theme_font_size_override("font_size", 16)
	parent.add_child(button)
	return button


func _build_how_to_play(parent: VBoxContainer) -> void:
	how_to_play_panel = PanelContainer.new()
	how_to_play_panel.name = "HowToPlayPanel"
	how_to_play_panel.custom_minimum_size = Vector2(940, 450)
	how_to_play_panel.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	how_to_play_panel.add_theme_stylebox_override("panel", PresentationTheme.panel_style(Color("#17120ff2"), Color("#8d5b30"), 2, 8, 6))
	parent.add_child(how_to_play_panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 22)
	margin.add_theme_constant_override("margin_top", 16)
	margin.add_theme_constant_override("margin_right", 22)
	margin.add_theme_constant_override("margin_bottom", 16)
	how_to_play_panel.add_child(margin)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 8)
	margin.add_child(column)

	var title := _build_menu_copy(column, "HOW_TITLE", 25, PresentationTheme.GOLD)
	title.name = "Title"
	var tabs := HBoxContainer.new()
	tabs.name = "Tabs"
	tabs.alignment = BoxContainer.ALIGNMENT_CENTER
	tabs.add_theme_constant_override("separation", 8)
	column.add_child(tabs)
	var tab_group := ButtonGroup.new()
	_build_how_tab_button(tabs, tab_group, &"cards", "HOW_TAB_CARDS")
	_build_how_tab_button(tabs, tab_group, &"phases", "HOW_TAB_PHASES")
	_build_how_tab_button(tabs, tab_group, &"scoring", "HOW_TAB_SCORING")

	var tab_content := VBoxContainer.new()
	tab_content.name = "TabContent"
	tab_content.custom_minimum_size = Vector2(896, 270)
	tab_content.size_flags_vertical = Control.SIZE_EXPAND_FILL
	column.add_child(tab_content)
	_build_how_cards_tab(tab_content)
	_build_how_phases_tab(tab_content)
	_build_how_scoring_tab(tab_content)
	_show_how_tab(&"cards")

	how_to_play_back_button = _build_menu_back_button(column, "HowToPlayBackButton")
	how_to_play_back_button.pressed.connect(_show_menu_page.bind(&"home"))


func _build_how_tab_button(parent: Container, group: ButtonGroup, tab_id: StringName, translation_key: String) -> void:
	var button := Button.new()
	button.name = "%sTabButton" % String(tab_id).capitalize().replace(" ", "")
	button.custom_minimum_size = Vector2(286, 38)
	button.toggle_mode = true
	button.button_group = group
	_register_menu_text(button, translation_key)
	PresentationTheme.configure_button(button, "neutral")
	button.pressed.connect(_show_how_tab.bind(tab_id))
	parent.add_child(button)
	how_tab_buttons[tab_id] = button


func _build_how_cards_tab(parent: VBoxContainer) -> void:
	var page := VBoxContainer.new()
	page.name = "CardsTab"
	page.add_theme_constant_override("separation", 7)
	parent.add_child(page)
	how_tab_pages[&"cards"] = page
	var intro := _build_menu_copy(page, "HOW_INTRO", 13, PresentationTheme.INK)
	intro.name = "Intro"
	var examples := HBoxContainer.new()
	examples.name = "CardExamples"
	examples.alignment = BoxContainer.ALIGNMENT_CENTER
	examples.add_theme_constant_override("separation", 10)
	page.add_child(examples)
	_build_how_example(examples, "RunExample", "HOW_RUN_TITLE", "HOW_RUN_BODY", [
		["4", 4, "Hearts"], ["5", 5, "Hearts"], ["6", 6, "Hearts"],
	], PresentationTheme.TEA, 214, 218)
	_build_how_example(examples, "SetExample", "HOW_SET_TITLE", "HOW_SET_BODY", [
		["9", 9, "Spades"], ["9", 9, "Hearts"], ["9", 9, "Diamonds"],
	], PresentationTheme.GOLD, 214, 218)
	_build_how_example(examples, "ExtendExample", "HOW_EXTEND_TITLE", "HOW_EXTEND_BODY", [
		["7", 7, "Clubs"], ["8", 8, "Clubs"], ["9", 9, "Clubs"], ["10", 10, "Clubs"],
	], PresentationTheme.TEA, 214, 218)
	_build_how_example(examples, "DiscardExample", "HOW_DISCARD_TITLE", "HOW_DISCARD_BODY", [
		["Q", 12, "Diamonds"], ["BACK", 0, ""],
	], PresentationTheme.RED, 214, 218)


func _build_how_phases_tab(parent: VBoxContainer) -> void:
	var page := VBoxContainer.new()
	page.name = "PhasesTab"
	page.add_theme_constant_override("separation", 7)
	parent.add_child(page)
	how_tab_pages[&"phases"] = page
	var intro := _build_menu_copy(page, "HOW_PHASES_INTRO", 13, PresentationTheme.INK)
	intro.name = "PhasesIntro"
	var examples := HBoxContainer.new()
	examples.name = "PhaseExamples"
	examples.alignment = BoxContainer.ALIGNMENT_CENTER
	examples.add_theme_constant_override("separation", 12)
	page.add_child(examples)
	_build_how_example(examples, "TurnExample", "HOW_TURN_TITLE", "HOW_TURN_BODY", [
		["BACK", 0, ""], ["7", 7, "Hearts"], ["Q", 12, "Diamonds"],
	], PresentationTheme.TEA, 286, 226)
	_build_how_example(examples, "PhaseEndExample", "HOW_PHASE_END_TITLE", "HOW_PHASE_END_BODY", [
		["2", 2, "Clubs"], ["5", 5, "Diamonds"], ["8", 8, "Spades"], ["Q", 12, "Hearts"],
	], PresentationTheme.GOLD, 286, 226)
	_build_how_example(examples, "PhaseChoiceExample", "HOW_PHASE_CHOICE_TITLE", "HOW_PHASE_CHOICE_BODY", [
		["9", 9, "Spades"], ["9", 9, "Hearts"], ["9", 9, "Diamonds"],
	], PresentationTheme.TEA, 286, 226)


func _build_how_scoring_tab(parent: VBoxContainer) -> void:
	var page := VBoxContainer.new()
	page.name = "ScoringTab"
	page.add_theme_constant_override("separation", 6)
	parent.add_child(page)
	how_tab_pages[&"scoring"] = page
	var intro := _build_menu_copy(page, "HOW_SCORING_INTRO", 13, PresentationTheme.INK)
	intro.name = "ScoringIntro"
	var topics := HBoxContainer.new()
	topics.name = "ScoringTopics"
	topics.alignment = BoxContainer.ALIGNMENT_CENTER
	topics.add_theme_constant_override("separation", 8)
	page.add_child(topics)
	var topic_group := ButtonGroup.new()
	_build_how_scoring_topic_button(topics, topic_group, &"basic", "HOW_SCORE_TOPIC_BASIC")
	_build_how_scoring_topic_button(topics, topic_group, &"special", "HOW_SCORE_TOPIC_SPECIAL")

	var topic_content := Control.new()
	topic_content.name = "ScoringTopicContent"
	topic_content.custom_minimum_size = Vector2(896, 226)
	page.add_child(topic_content)
	_build_how_basic_scoring_page(topic_content)
	_build_how_special_scoring_page(topic_content)
	_show_how_scoring_topic(&"basic")


func _build_how_scoring_topic_button(parent: Container, group: ButtonGroup, topic_id: StringName, translation_key: String) -> void:
	var button := Button.new()
	button.name = "%sTopicButton" % String(topic_id).capitalize()
	button.custom_minimum_size = Vector2(216, 30)
	button.toggle_mode = true
	button.button_group = group
	_register_menu_text(button, translation_key)
	PresentationTheme.configure_button(button, "neutral")
	button.add_theme_font_size_override("font_size", 12)
	button.pressed.connect(_show_how_scoring_topic.bind(topic_id))
	parent.add_child(button)
	how_scoring_topic_buttons[topic_id] = button


func _build_how_basic_scoring_page(parent: Control) -> void:
	var examples := HBoxContainer.new()
	examples.name = "BasicScoring"
	examples.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	examples.alignment = BoxContainer.ALIGNMENT_CENTER
	examples.add_theme_constant_override("separation", 12)
	parent.add_child(examples)
	how_scoring_topic_pages[&"basic"] = examples
	_build_how_example(examples, "MeldScoreExample", "HOW_SCORE_MELD_TITLE", "HOW_SCORE_MELD_BODY", [
		["4", 4, "Hearts"], ["5", 5, "Hearts"], ["6", 6, "Hearts"],
	], PresentationTheme.TEA, 286, 226)
	_build_how_example(examples, "ExtendScoreExample", "HOW_SCORE_EXTEND_TITLE", "HOW_SCORE_EXTEND_BODY", [
		["4", 4, "Hearts"], ["5", 5, "Hearts"], ["6", 6, "Hearts"], ["7", 7, "Hearts"],
	], PresentationTheme.GOLD, 286, 226)
	_build_how_example(examples, "PhaseScoreExample", "HOW_SCORE_PHASE_TITLE", "HOW_SCORE_PHASE_BODY", [
		["Q", 12, "Diamonds"], ["K", 13, "Spades"],
	], PresentationTheme.RED, 286, 226)


func _build_how_special_scoring_page(parent: Control) -> void:
	var examples := HBoxContainer.new()
	examples.name = "SpecialOutcomes"
	examples.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	examples.alignment = BoxContainer.ALIGNMENT_CENTER
	examples.add_theme_constant_override("separation", 12)
	parent.add_child(examples)
	how_scoring_topic_pages[&"special"] = examples
	_build_how_example(examples, "MomExample", "HOW_MOM_TITLE", "HOW_MOM_BODY", [
		["Q", 12, "Diamonds"], ["K", 13, "Spades"], ["A", 1, "Clubs"],
	], PresentationTheme.RED, 286, 226)
	_build_how_example(examples, "UExample", "HOW_U_TITLE", "HOW_U_BODY", [
		["2", 2, "Spades"], ["2", 2, "Hearts"], ["2", 2, "Diamonds"], ["5", 5, "Clubs"],
	], PresentationTheme.TEA, 286, 226)
	_build_how_example(examples, "UKhanExample", "HOW_U_KHAN_TITLE", "HOW_U_KHAN_BODY", [
		["2", 2, "Spades"], ["5", 5, "Hearts"], ["8", 8, "Clubs"], ["Q", 12, "Diamonds"],
	], PresentationTheme.GOLD, 286, 226)


func _show_how_scoring_topic(topic_id: StringName) -> void:
	if not how_scoring_topic_pages.has(topic_id):
		return
	how_scoring_topic = topic_id
	for candidate in how_scoring_topic_pages:
		(how_scoring_topic_pages[candidate] as Control).visible = candidate == topic_id
		(how_scoring_topic_buttons[candidate] as Button).set_pressed_no_signal(candidate == topic_id)


func _show_how_tab(tab_id: StringName) -> void:
	if not how_tab_pages.has(tab_id):
		return
	if tab_id == &"scoring":
		_show_how_scoring_topic(&"basic")
	how_to_play_tab = tab_id
	for candidate in how_tab_pages:
		(how_tab_pages[candidate] as Control).visible = candidate == tab_id
		(how_tab_buttons[candidate] as Button).set_pressed_no_signal(candidate == tab_id)


func _build_how_example(
	parent: Container,
	node_name: String,
	title_key: String,
	body_key: String,
	card_specs: Array,
	accent: Color,
	panel_width: float = 214.0,
	panel_height: float = 246.0
) -> void:
	var panel := PanelContainer.new()
	panel.name = node_name
	panel.custom_minimum_size = Vector2(panel_width, panel_height)
	panel.add_theme_stylebox_override("panel", PresentationTheme.panel_style(Color("#231c17f0"), accent.darkened(0.2), 1, 5, 2))
	parent.add_child(panel)
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 8)
	margin.add_theme_constant_override("margin_top", 10)
	margin.add_theme_constant_override("margin_right", 8)
	margin.add_theme_constant_override("margin_bottom", 9)
	panel.add_child(margin)
	var column := VBoxContainer.new()
	column.alignment = BoxContainer.ALIGNMENT_CENTER
	column.add_theme_constant_override("separation", 7)
	margin.add_child(column)
	var title := _build_menu_copy(column, title_key, 15, accent)
	title.custom_minimum_size.y = 22
	var cards := HBoxContainer.new()
	cards.name = "Cards"
	cards.custom_minimum_size.y = 112
	cards.alignment = BoxContainer.ALIGNMENT_CENTER
	cards.add_theme_constant_override("separation", -4 if card_specs.size() >= 4 else 2)
	column.add_child(cards)
	for card_spec in card_specs:
		cards.add_child(_build_tutorial_card(card_spec))
	var body := _build_menu_copy(column, body_key, 11, PresentationTheme.INK)
	body.custom_minimum_size.y = 48
	body.vertical_alignment = VERTICAL_ALIGNMENT_CENTER


func _build_tutorial_card(card_spec: Array) -> TextureRect:
	var card_image := TextureRect.new()
	card_image.custom_minimum_size = Vector2(48, 86)
	card_image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	card_image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	card_image.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	card_image.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if String(card_spec[0]) == "BACK":
		card_image.texture = load("res://cards/red_backing.png") as Texture2D
		return card_image
	var card := CardData.new(
		"tutorial_%s_%s" % [String(card_spec[0]).to_lower(), String(card_spec[2]).to_lower()],
		String(card_spec[0]), int(card_spec[1]), String(card_spec[2]), int(card_spec[1])
	)
	card_image.texture = load(card.texture_path()) as Texture2D
	card_image.tooltip_text = card.short_label()
	return card_image


func _build_menu_copy(parent: Container, translation_key: String, font_size: int, color: Color) -> Label:
	var label := Label.new()
	_register_menu_text(label, translation_key)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(label)
	return label


func _build_menu_settings(parent: VBoxContainer) -> void:
	options_panel = PanelContainer.new()
	options_panel.name = "OptionsPanel"
	options_panel.custom_minimum_size = Vector2(620, 330)
	options_panel.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	options_panel.add_theme_stylebox_override("panel", PresentationTheme.panel_style(Color("#17120ff2"), Color("#8d5b30"), 2, 8, 6))
	parent.add_child(options_panel)
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 20)
	margin.add_theme_constant_override("margin_top", 16)
	margin.add_theme_constant_override("margin_right", 20)
	margin.add_theme_constant_override("margin_bottom", 16)
	options_panel.add_child(margin)
	var rows := VBoxContainer.new()
	rows.add_theme_constant_override("separation", 12)
	margin.add_child(rows)
	var title := _build_menu_copy(rows, "MENU_OPTIONS", 25, PresentationTheme.GOLD)
	title.name = "Title"

	var music_row := HBoxContainer.new()
	music_row.name = "MusicRow"
	music_row.add_theme_constant_override("separation", 12)
	rows.add_child(music_row)
	music_settings_label = _build_settings_label(music_row, "MENU_MUSIC")
	music_slider = _build_volume_slider(music_row, settings.music_volume_percent)
	music_slider.name = "MusicSlider"
	music_value_label = _build_volume_value(music_row, settings.music_volume_percent)
	music_slider.value_changed.connect(_on_music_volume_changed)

	var sound_row := HBoxContainer.new()
	sound_row.name = "SoundRow"
	sound_row.add_theme_constant_override("separation", 12)
	rows.add_child(sound_row)
	sound_settings_label = _build_settings_label(sound_row, "MENU_SOUND")
	sound_slider = _build_volume_slider(sound_row, settings.sound_volume_percent)
	sound_slider.name = "SoundSlider"
	sound_value_label = _build_volume_value(sound_row, settings.sound_volume_percent)
	sound_slider.value_changed.connect(_on_sound_volume_changed)

	var language_row := HBoxContainer.new()
	language_row.name = "LanguageRow"
	language_row.add_theme_constant_override("separation", 12)
	rows.add_child(language_row)
	language_settings_label = _build_settings_label(language_row, "MENU_LANGUAGE")
	language_selector = OptionButton.new()
	language_selector.name = "LanguageSelector"
	language_selector.custom_minimum_size = Vector2(310, 42)
	language_selector.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	PresentationTheme.configure_button(language_selector, "neutral")
	language_row.add_child(language_selector)
	_refresh_language_options()
	language_selector.item_selected.connect(_on_language_selected)
	options_back_button = _build_menu_back_button(rows, "OptionsBackButton")
	options_back_button.pressed.connect(_show_menu_page.bind(&"home"))


func _build_menu_back_button(parent: Container, node_name: String) -> Button:
	var button := Button.new()
	button.name = node_name
	button.custom_minimum_size = Vector2(220, 42)
	button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_register_menu_text(button, "MENU_BACK")
	PresentationTheme.configure_button(button, "neutral")
	parent.add_child(button)
	return button


func _register_menu_text(control: Control, translation_key: String) -> void:
	menu_localized_controls[control] = translation_key
	control.set("text", tr(translation_key))


func _show_menu_page(page: StringName) -> void:
	menu_page = page
	menu_home_panel.visible = page == &"home"
	how_to_play_panel.visible = page == &"how_to_play"
	options_panel.visible = page == &"options"
	if page == &"home":
		play_button.call_deferred("grab_focus")
	elif page == &"how_to_play":
		_show_how_tab(&"cards")
		(how_tab_buttons[&"cards"] as Button).call_deferred("grab_focus")
	else:
		language_selector.call_deferred("grab_focus")


func _build_settings_label(parent: Container, key: String) -> Label:
	var label := Label.new()
	label.text = tr(key)
	label.custom_minimum_size = Vector2(122, 42)
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 13)
	label.add_theme_color_override("font_color", PresentationTheme.INK)
	parent.add_child(label)
	return label


func _build_volume_slider(parent: Container, initial_value: float) -> HSlider:
	var slider := HSlider.new()
	slider.min_value = 0.0
	slider.max_value = 100.0
	slider.step = 1.0
	slider.custom_minimum_size = Vector2(250, 42)
	slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	slider.set_value_no_signal(initial_value)
	parent.add_child(slider)
	return slider


func _build_volume_value(parent: Container, initial_value: float) -> Label:
	var label := Label.new()
	label.text = "%d%%" % roundi(initial_value)
	label.custom_minimum_size = Vector2(54, 42)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 12)
	label.add_theme_color_override("font_color", PresentationTheme.GOLD)
	parent.add_child(label)
	return label


func _on_music_volume_changed(value: float) -> void:
	music_value_label.text = "%d%%" % roundi(value)
	settings.set_music_volume(value)


func _on_sound_volume_changed(value: float) -> void:
	sound_value_label.text = "%d%%" % roundi(value)
	settings.set_sound_volume(value)


func _on_language_selected(index: int) -> void:
	if index < 0 or index >= settings.SUPPORTED_LOCALES.size():
		return
	settings.set_locale(settings.SUPPORTED_LOCALES[index])


func _refresh_language_options() -> void:
	var selected_index: int = int(settings.locale_index())
	language_selector.clear()
	language_selector.add_item(tr("LANG_VI"))
	language_selector.add_item(tr("LANG_EN"))
	language_selector.select(selected_index)


func _on_locale_changed(_locale_code: String) -> void:
	_refresh_localized_ui()


func _refresh_localized_ui() -> void:
	for control in menu_localized_controls:
		if is_instance_valid(control):
			control.set("text", tr(String(menu_localized_controls[control])))
	music_settings_label.text = tr("MENU_MUSIC")
	sound_settings_label.text = tr("MENU_SOUND")
	language_settings_label.text = tr("MENU_LANGUAGE")
	_refresh_language_options()
	menu_button.text = tr("HUD_MENU")
	menu_button.tooltip_text = tr("HUD_MENU_TOOLTIP")
	discard_history_title.text = tr("HUD_DISCARD_HISTORY")
	(header_caption_labels.get("IncomeStat") as Label).text = tr("HUD_INCOME")
	(header_caption_labels.get("WalletStat") as Label).text = tr("HUD_WALLET")
	(header_caption_labels.get("CampaignStat") as Label).text = tr("HUD_CAMPAIGN")
	empty_meld_label.text = tr("TABLE_EMPTY_MELD")
	(pile_caption_labels.get("draw") as Label).text = tr("PILE_DRAW")
	(pile_caption_labels.get("discard") as Label).text = tr("PILE_DISCARD")
	(pile_archive_buttons.get("draw") as Button).tooltip_text = tr("PILE_DRAW_TOOLTIP")
	(pile_archive_buttons.get("discard") as Button).tooltip_text = tr("PILE_DISCARD_TOOLTIP")
	drink_title_label.text = tr("HUD_DRINK")
	relic_title_label.text = tr("HUD_RELICS")
	hint_button.text = tr("ACTION_HINT")
	hint_button.tooltip_text = tr("ACTION_HINT_TOOLTIP")
	sort_button.text = tr("ACTION_SORT_RANK") if sort_mode == 0 else tr("ACTION_SORT_SUIT")
	sort_button.tooltip_text = tr("ACTION_SORT_TOOLTIP")
	ha_button.text = tr("ACTION_MELD")
	ha_button.tooltip_text = tr("ACTION_MELD_TOOLTIP")
	extend_button.text = tr("ACTION_EXTEND")
	extend_button.tooltip_text = tr("ACTION_EXTEND_TOOLTIP")
	discard_button.text = tr("ACTION_DISCARD")
	discard_button.tooltip_text = tr("ACTION_DISCARD_TOOLTIP")
	settle_button.text = tr("ACTION_SETTLE")
	settle_button.tooltip_text = tr("ACTION_SETTLE_TOOLTIP")
	discard_archive_close.text = tr("ARCHIVE_CLOSE")
	if tutorial_active:
		_refresh_tutorial_coach()
	if campaign_overlay.visible and current_campaign_event != null:
		_show_campaign_event(current_campaign_event)
	for suit in DeckManager.SUITS:
		(discard_archive_suit_titles.get(suit) as Label).text = _discard_suit_title(suit)
	_sync_all()


func _build_music() -> void:
	music_controller = ReactiveMusicController.new()
	music_controller.name = "ReactiveMusic"
	music_controller.band_pulse.connect(_on_music_band_pulse)
	add_child(music_controller)


func _refresh_logo_pivots() -> void:
	for segment in logo_segments:
		segment.pivot_offset = segment.size * 0.5


func _on_music_band_pulse(band_index: int, strength: float) -> void:
	if band_index < 0 or band_index >= MUSIC_BAND_COUNT:
		return
	if menu_layer != null and menu_layer.visible:
		_pulse_logo_band(band_index, strength)
		return
	if not game_started or interaction_locked or modal_overlay.visible or score_overlay.visible or discard_archive_overlay.visible:
		return
	var hand_assignments: Array = reactive_hand_cards_by_band.get(band_index, [])
	for assignment_index in range(hand_assignments.size()):
		var hand_view = hand_assignments[assignment_index]
		hand_view.play_beat_pulse(strength)
	var meld_assignments: Array = reactive_meld_cards_by_band.get(band_index, [])
	for assignment_index in range(meld_assignments.size()):
		var assignment: Dictionary = meld_assignments[assignment_index]
		var meld_view := assignment.get("view") as MeldView
		if meld_view != null:
			meld_view.play_card_beat_pulse(String(assignment.get("card_id", "")), strength)


func _pulse_logo_band(band_index: int, strength: float) -> void:
	if band_index >= logo_segments.size():
		return
	var pulse_strength := clampf(strength, 0.2, 1.0)
	var segment := logo_segments[band_index]
	var previous := logo_bounce_tweens.get(band_index) as Tween
	if previous != null and previous.is_valid():
		previous.kill()
	segment.pivot_offset = segment.size * 0.5
	segment.scale = Vector2.ONE
	segment.rotation = 0.0
	var peak_scale := Vector2(
		1.0 + lerpf(0.035, 0.075, pulse_strength),
		1.0 + lerpf(0.07, 0.15, pulse_strength)
	)
	var tilt := deg_to_rad(lerpf(0.35, 1.2, pulse_strength))
	if band_index % 2 == 0:
		tilt = -tilt
	var tween := create_tween()
	logo_bounce_tweens[band_index] = tween
	tween.tween_property(segment, "scale", peak_scale, 0.075).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(segment, "rotation", tilt, 0.075).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(segment, "scale", Vector2.ONE, 0.19).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(segment, "rotation", 0.0, 0.19).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)


func _park_game_layer() -> void:
	if game_layer == null or game_started or menu_transitioning:
		return
	game_layer.position = Vector2(get_viewport_rect().size.x + 80.0, 0)


func _on_play_pressed() -> void:
	if menu_transitioning:
		return
	if game_started:
		menu_transitioning = true
		play_button.disabled = true
		menu_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var close_tween := create_tween()
		close_tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		close_tween.tween_property(menu_layer, "modulate", Color(1, 1, 1, 0), 0.22)
		await close_tween.finished
		menu_layer.visible = false
		menu_layer.position = Vector2.ZERO
		menu_layer.modulate = Color.WHITE
		menu_transitioning = false
		interaction_locked = false
		_set_hand_interaction_enabled(true)
		_start_campaign()
		play_button.disabled = false
		return
	menu_transitioning = true
	play_button.disabled = true
	menu_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var viewport_width := get_viewport_rect().size.x
	var tween := create_tween().set_parallel(true)
	tween.set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_OUT)
	tween.tween_property(game_layer, "position:x", 0.0, 0.72)
	tween.tween_property(menu_layer, "position:x", -viewport_width * 0.34, 0.62)
	tween.tween_property(menu_layer, "modulate", Color(1, 1, 1, 0), 0.48)
	await tween.finished
	menu_layer.visible = false
	game_started = true
	menu_transitioning = false
	_start_campaign()


func _on_tutorial_pressed() -> void:
	if menu_transitioning:
		return
	menu_transitioning = true
	tutorial_button.disabled = true
	menu_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if game_started:
		var close_tween := create_tween()
		close_tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		close_tween.tween_property(menu_layer, "modulate", Color(1, 1, 1, 0), 0.22)
		await close_tween.finished
	else:
		var viewport_width := get_viewport_rect().size.x
		var entrance := create_tween().set_parallel(true)
		entrance.set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_OUT)
		entrance.tween_property(game_layer, "position:x", 0.0, 0.72)
		entrance.tween_property(menu_layer, "position:x", -viewport_width * 0.34, 0.62)
		entrance.tween_property(menu_layer, "modulate", Color(1, 1, 1, 0), 0.48)
		await entrance.finished
	menu_layer.visible = false
	menu_layer.position = Vector2.ZERO
	menu_layer.modulate = Color.WHITE
	game_started = true
	menu_transitioning = false
	tutorial_button.disabled = false
	_start_tutorial_deal()


func _start_tutorial_deal() -> void:
	if tutorial_active:
		_deactivate_tutorial(true)
	tutorial_wallet_before = deal.wallet.balance_vnd
	tutorial_active = true
	tutorial_step = TUTORIAL_SELECT_RUN
	interaction_locked = true
	modal_overlay.visible = false
	selected_card_ids.clear()
	selected_meld_id = -1
	tutorial_meld_id = -1
	var result := deal.start_tutorial_deal()
	displayed_wallet_vnd = deal.wallet.balance_vnd
	_sync_all(result, true)
	tutorial_coach.visible = true
	interaction_locked = false
	_set_hand_interaction_enabled(true)
	_refresh_tutorial_coach()
	_refresh_tutorial_spotlight()
	_refresh_actions()


func _deactivate_tutorial(restore_wallet: bool) -> void:
	if not tutorial_active:
		return
	tutorial_active = false
	tutorial_step = &""
	tutorial_meld_id = -1
	tutorial_outcome_visible = false
	tutorial_coach.visible = false
	tutorial_spotlight.set_targets([] as Array[Control])
	score_overlay.visible = false
	if restore_wallet:
		deal.wallet.reset(tutorial_wallet_before)
		displayed_wallet_vnd = tutorial_wallet_before


func _on_tutorial_exit_pressed() -> void:
	match tutorial_step:
		TUTORIAL_MOM:
			_set_tutorial_step(TUTORIAL_U)
			return
		TUTORIAL_U:
			_set_tutorial_step(TUTORIAL_U_KHAN)
			return
		TUTORIAL_U_KHAN:
			_set_tutorial_step(TUTORIAL_COMPLETE)
			return
	var completed := tutorial_step == TUTORIAL_COMPLETE
	_deactivate_tutorial(true)
	interaction_locked = false
	if completed:
		_start_campaign()
	else:
		_start_new_deal()
		_on_menu_pressed()


func _set_tutorial_step(step: StringName) -> void:
	if not tutorial_active:
		return
	tutorial_step = step
	tutorial_step_changed.emit(step)
	_refresh_tutorial_outcome()
	_refresh_tutorial_coach()
	_refresh_tutorial_spotlight()
	_sync_card_action_outlines()
	_refresh_actions()


func _refresh_tutorial_coach() -> void:
	if not tutorial_active or tutorial_coach == null:
		return
	tutorial_coach.visible = true
	tutorial_exit_button.disabled = interaction_locked
	if tutorial_step == TUTORIAL_COMPLETE:
		tutorial_exit_button.text = tr("TUTORIAL_PLAY_REAL_DEAL")
	elif tutorial_step in [TUTORIAL_MOM, TUTORIAL_U, TUTORIAL_U_KHAN]:
		tutorial_exit_button.text = tr("TUTORIAL_NEXT")
	else:
		tutorial_exit_button.text = tr("TUTORIAL_EXIT")
	match tutorial_step:
		TUTORIAL_SELECT_RUN:
			_set_tutorial_copy(_tutorial_progress(1, "1 / 10"), "TUTORIAL_SELECT_RUN_TITLE", "TUTORIAL_SELECT_RUN_BODY")
		TUTORIAL_PLAY_RUN:
			_set_tutorial_copy(_tutorial_progress(1, "2 / 10"), "TUTORIAL_PLAY_RUN_TITLE", "TUTORIAL_PLAY_RUN_BODY")
		TUTORIAL_MELD_SCORE:
			_set_tutorial_copy(_tutorial_progress(1, "3 / 10"), "TUTORIAL_MELD_SCORE_TITLE", "TUTORIAL_MELD_SCORE_BODY")
		TUTORIAL_SELECT_DISCARD:
			_set_tutorial_copy(_tutorial_progress(1, "4 / 10"), "TUTORIAL_SELECT_DISCARD_TITLE", "TUTORIAL_SELECT_DISCARD_BODY")
		TUTORIAL_DISCARD:
			_set_tutorial_copy(_tutorial_progress(1, "4 / 10"), "TUTORIAL_DISCARD_TITLE", "TUTORIAL_DISCARD_BODY")
		TUTORIAL_SELECT_EXTEND:
			_set_tutorial_copy(_tutorial_progress(2, "5 / 10"), "TUTORIAL_SELECT_EXTEND_TITLE", "TUTORIAL_SELECT_EXTEND_BODY")
		TUTORIAL_SELECT_MELD:
			_set_tutorial_copy(_tutorial_progress(2, "5 / 10"), "TUTORIAL_SELECT_MELD_TITLE", "TUTORIAL_SELECT_MELD_BODY")
		TUTORIAL_EXTEND:
			_set_tutorial_copy(_tutorial_progress(2, "5 / 10"), "TUTORIAL_EXTEND_TITLE", "TUTORIAL_EXTEND_BODY")
		TUTORIAL_EXTEND_SCORE:
			_set_tutorial_copy(_tutorial_progress(2, "6 / 10"), "TUTORIAL_EXTEND_SCORE_TITLE", "TUTORIAL_EXTEND_SCORE_BODY")
		TUTORIAL_SELECT_FINAL_DISCARD:
			_set_tutorial_copy(_tutorial_progress(2, "7 / 10"), "TUTORIAL_SELECT_FINAL_DISCARD_TITLE", "TUTORIAL_SELECT_FINAL_DISCARD_BODY")
		TUTORIAL_FINAL_DISCARD:
			_set_tutorial_copy(_tutorial_progress(2, "7 / 10"), "TUTORIAL_FINAL_DISCARD_TITLE", "TUTORIAL_FINAL_DISCARD_BODY")
		TUTORIAL_MOM:
			_set_tutorial_copy(tr("TUTORIAL_SPECIAL_PROGRESS") % [8, 10], "TUTORIAL_MOM_TITLE", "TUTORIAL_MOM_BODY")
		TUTORIAL_U:
			_set_tutorial_copy(tr("TUTORIAL_SPECIAL_PROGRESS") % [9, 10], "TUTORIAL_U_TITLE", "TUTORIAL_U_BODY")
		TUTORIAL_U_KHAN:
			_set_tutorial_copy(tr("TUTORIAL_SPECIAL_PROGRESS") % [10, 10], "TUTORIAL_U_KHAN_TITLE", "TUTORIAL_U_KHAN_BODY")
		TUTORIAL_COMPLETE:
			_set_tutorial_copy(tr("TUTORIAL_SPECIAL_COMPLETE"), "TUTORIAL_COMPLETE_TITLE", "TUTORIAL_COMPLETE_BODY")


func _refresh_tutorial_outcome() -> void:
	var is_special := tutorial_step in [TUTORIAL_MOM, TUTORIAL_U, TUTORIAL_U_KHAN]
	if not is_special:
		if tutorial_outcome_visible:
			tutorial_outcome_visible = false
			score_overlay.visible = false
		return
	tutorial_outcome_visible = true
	score_overlay.visible = true
	score_panel.scale = Vector2.ONE
	score_panel.modulate = Color.WHITE
	for label in [score_title, score_line_a, score_line_b, score_payout]:
		label.modulate = Color.WHITE
	match tutorial_step:
		TUTORIAL_MOM:
			score_title.text = tr("TUTORIAL_MOM_PANEL_TITLE")
			score_line_a.text = tr("TUTORIAL_MOM_PANEL_LINE_A")
			score_line_b.text = tr("TUTORIAL_MOM_PANEL_LINE_B")
			score_payout.text = tr("TUTORIAL_MOM_PANEL_RESULT")
		TUTORIAL_U:
			score_title.text = tr("TUTORIAL_U_PANEL_TITLE")
			score_line_a.text = tr("TUTORIAL_U_PANEL_LINE_A")
			score_line_b.text = tr("TUTORIAL_U_PANEL_LINE_B")
			score_payout.text = tr("TUTORIAL_U_PANEL_RESULT")
		TUTORIAL_U_KHAN:
			score_title.text = tr("TUTORIAL_U_KHAN_PANEL_TITLE")
			score_line_a.text = tr("TUTORIAL_U_KHAN_PANEL_LINE_A")
			score_line_b.text = tr("TUTORIAL_U_KHAN_PANEL_LINE_B")
			score_payout.text = tr("TUTORIAL_U_KHAN_PANEL_RESULT")


func _set_tutorial_copy(progress: String, title_key: String, body_key: String) -> void:
	tutorial_progress_label.text = progress
	tutorial_title_label.text = tr(title_key)
	tutorial_body_label.text = tr(body_key)


func _tutorial_progress(turn_number: int, step_text: String) -> String:
	return "%s\n%s" % [tr("TUTORIAL_CONTEXT") % [1, turn_number], step_text]


func _refresh_tutorial_spotlight() -> void:
	if not tutorial_active or tutorial_spotlight == null:
		return
	var targets: Array[Control] = []
	match tutorial_step:
		TUTORIAL_SELECT_RUN:
			for card_id in TUTORIAL_RUN_IDS:
				var run_view := hand_views.get(String(card_id)) as Control
				if run_view != null:
					targets.append(run_view)
		TUTORIAL_PLAY_RUN:
			targets.append(ha_button)
		TUTORIAL_MELD_SCORE, TUTORIAL_EXTEND_SCORE, TUTORIAL_MOM, TUTORIAL_U, TUTORIAL_U_KHAN:
			targets.append(score_panel)
		TUTORIAL_SELECT_DISCARD:
			var discard_view := hand_views.get(String(TUTORIAL_FIRST_DISCARD_ID)) as Control
			if discard_view != null:
				targets.append(discard_view)
		TUTORIAL_DISCARD, TUTORIAL_FINAL_DISCARD:
			targets.append(discard_button)
		TUTORIAL_SELECT_EXTEND:
			var extend_card_view := hand_views.get(String(TUTORIAL_EXTENSION_ID)) as Control
			if extend_card_view != null:
				targets.append(extend_card_view)
		TUTORIAL_SELECT_MELD:
			var meld_view := meld_views.get(tutorial_meld_id) as Control
			if meld_view != null:
				targets.append(meld_view)
		TUTORIAL_EXTEND:
			targets.append(extend_button)
		TUTORIAL_SELECT_FINAL_DISCARD:
			var final_discard_view := hand_views.get(String(TUTORIAL_FINAL_DISCARD_ID)) as Control
			if final_discard_view != null:
				targets.append(final_discard_view)
		TUTORIAL_COMPLETE:
			targets.append(tutorial_exit_button)
	tutorial_spotlight.set_targets(targets)


func _on_menu_pressed() -> void:
	if not game_started or menu_transitioning or interaction_locked or modal_overlay.visible or score_overlay.visible or discard_archive_overlay.visible:
		return
	interaction_locked = true
	_set_hand_interaction_enabled(false)
	_show_menu_page(&"home")
	menu_layer.position = Vector2.ZERO
	menu_layer.modulate = Color(1, 1, 1, 0)
	menu_layer.visible = true
	menu_layer.mouse_filter = Control.MOUSE_FILTER_STOP
	play_button.disabled = false
	var tween := create_tween()
	tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(menu_layer, "modulate", Color.WHITE, 0.18)


func _close_menu_to_game() -> void:
	if not game_started or menu_transitioning or not menu_layer.visible:
		return
	menu_transitioning = true
	menu_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var tween := create_tween()
	tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.tween_property(menu_layer, "modulate", Color(1, 1, 1, 0), 0.16)
	await tween.finished
	menu_layer.visible = false
	menu_layer.modulate = Color.WHITE
	menu_transitioning = false
	interaction_locked = false
	_set_hand_interaction_enabled(true)
	_refresh_actions()


func _build_header() -> void:
	var header := Control.new()
	header.name = "Header"
	header.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	header.offset_left = 16
	header.offset_top = 14
	header.offset_right = -16
	header.offset_bottom = 100
	game_layer.add_child(header)

	var row := HBoxContainer.new()
	row.name = "HeaderRow"
	row.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	row.add_theme_constant_override("separation", 10)
	header.add_child(row)

	menu_button = _make_action_button(row, tr("HUD_MENU"), "neutral", 94)
	menu_button.name = "MenuButton"
	menu_button.custom_minimum_size.y = 72
	menu_button.tooltip_text = tr("HUD_MENU_TOOLTIP")
	menu_button.pressed.connect(_on_menu_pressed)

	_build_discard_history_hud(row)

	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(spacer)

	campaign_value = _add_header_stat(row, "HUD_CAMPAIGN", 178, false, "CampaignStat")
	earnings_value = _add_header_stat(row, "HUD_INCOME", 144, false, "IncomeStat")
	wallet_value = _add_header_stat(row, "HUD_WALLET", 178, true, "WalletStat")


func _build_discard_history_hud(parent: Container) -> void:
	var panel := PanelContainer.new()
	panel.name = "DiscardHistoryHUD"
	panel.custom_minimum_size = Vector2(340, 72)
	panel.add_theme_stylebox_override("panel", PresentationTheme.panel_style(Color("#19130ff0"), Color("#8d5b30"), 2, 2, 5))
	parent.add_child(panel)
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 8)
	margin.add_theme_constant_override("margin_top", 5)
	margin.add_theme_constant_override("margin_right", 8)
	margin.add_theme_constant_override("margin_bottom", 5)
	panel.add_child(margin)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 2)
	margin.add_child(column)
	discard_history_title = Label.new()
	discard_history_title.text = tr("HUD_DISCARD_HISTORY")
	discard_history_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	discard_history_title.add_theme_font_size_override("font_size", 9)
	discard_history_title.add_theme_color_override("font_color", PresentationTheme.GOLD)
	column.add_child(discard_history_title)
	var scroll := ScrollContainer.new()
	scroll.name = "DiscardHistoryScroll"
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	column.add_child(scroll)
	discard_history_row = HBoxContainer.new()
	discard_history_row.name = "DiscardHistoryRow"
	discard_history_row.alignment = BoxContainer.ALIGNMENT_CENTER
	discard_history_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	discard_history_row.add_theme_constant_override("separation", 3)
	scroll.add_child(discard_history_row)


func _add_header_stat(parent: Container, caption: String, minimum_width: float, emphasize: bool = false, panel_name: String = "") -> Label:
	var panel := PanelContainer.new()
	panel.name = panel_name
	panel.custom_minimum_size = Vector2(minimum_width, 72)
	panel.add_theme_stylebox_override("panel", PresentationTheme.panel_style(Color("#19130ff0"), Color("#8d5b30"), 2, 2, 4))
	parent.add_child(panel)
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 11)
	margin.add_theme_constant_override("margin_top", 8)
	margin.add_theme_constant_override("margin_right", 11)
	margin.add_theme_constant_override("margin_bottom", 5)
	panel.add_child(margin)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", -2)
	margin.add_child(column)
	var caption_label := Label.new()
	caption_label.text = tr(caption)
	caption_label.add_theme_font_size_override("font_size", 11)
	caption_label.add_theme_color_override("font_color", PresentationTheme.MUTED)
	column.add_child(caption_label)
	header_caption_labels[panel_name] = caption_label
	var value := Label.new()
	value.add_theme_font_size_override("font_size", 19 if emphasize else 17)
	value.add_theme_color_override("font_color", PresentationTheme.GOLD if emphasize else PresentationTheme.INK)
	value.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	column.add_child(value)
	return value


func _build_table() -> void:
	var table := Panel.new()
	table_surface = table
	table.name = "TableSurface"
	table.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	table.offset_left = 72
	table.offset_top = 108
	table.offset_right = -72
	table.offset_bottom = -242
	table.add_theme_stylebox_override("panel", PresentationTheme.panel_style(Color.TRANSPARENT, Color.TRANSPARENT, 0, 0, 0))
	game_layer.add_child(table)

	draw_pile_visual = _build_pile(table, true)
	discard_pile_visual = _build_pile(table, false)

	meld_scroll = ScrollContainer.new()
	meld_scroll.name = "MeldScroll"
	meld_scroll.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	meld_scroll.offset_left = 250
	meld_scroll.offset_top = 10
	meld_scroll.offset_right = -250
	meld_scroll.offset_bottom = -10
	meld_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	meld_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	table.add_child(meld_scroll)
	meld_row = HBoxContainer.new()
	meld_row.name = "MeldRow"
	meld_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	meld_row.size_flags_vertical = Control.SIZE_EXPAND_FILL
	meld_row.alignment = BoxContainer.ALIGNMENT_CENTER
	meld_row.add_theme_constant_override("separation", 12)
	meld_scroll.add_child(meld_row)

	empty_meld_label = Label.new()
	empty_meld_label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	empty_meld_label.offset_left = 260
	empty_meld_label.offset_top = 16
	empty_meld_label.offset_right = -260
	empty_meld_label.offset_bottom = -10
	empty_meld_label.text = tr("TABLE_EMPTY_MELD")
	empty_meld_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	empty_meld_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	empty_meld_label.add_theme_font_size_override("font_size", 14)
	empty_meld_label.add_theme_color_override("font_color", Color("#e5d5a2"))
	empty_meld_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	table.add_child(empty_meld_label)


func _build_pile(parent: Control, is_draw_pile: bool) -> Control:
	var pile := Control.new()
	pile.name = "DrawPile" if is_draw_pile else "DiscardPile"
	pile.set_anchors_preset(Control.PRESET_CENTER_LEFT if is_draw_pile else Control.PRESET_CENTER_RIGHT)
	pile.size = Vector2(112, 192)
	pile.position = Vector2(112, -86) if is_draw_pile else Vector2(-224, -86)
	parent.add_child(pile)

	var caption := Label.new()
	caption.position = Vector2(0, 0)
	caption.size = Vector2(112, 21)
	caption.text = tr("PILE_DRAW") if is_draw_pile else tr("PILE_DISCARD")
	caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	caption.add_theme_font_size_override("font_size", 10)
	caption.add_theme_color_override("font_color", PresentationTheme.INK)
	caption.add_theme_stylebox_override("normal", PresentationTheme.panel_style(Color("#19130feb"), Color("#8d5b30"), 1, 2, 2))
	caption.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pile.add_child(caption)
	pile_caption_labels["draw" if is_draw_pile else "discard"] = caption

	for depth in range(3, 0, -1):
		var backing := TextureRect.new()
		backing.position = Vector2(13 + depth * 2, 26 - depth * 2)
		backing.size = CARD_SIZE
		backing.texture = load("res://cards/red_backing.png") as Texture2D
		backing.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		backing.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		backing.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		backing.mouse_filter = Control.MOUSE_FILTER_IGNORE
		backing.modulate = Color.WHITE if is_draw_pile else Color(1, 1, 1, 0.12)
		pile.add_child(backing)
		if not is_draw_pile and depth == 1:
			discard_texture = backing

	var badge := Label.new()
	badge.position = Vector2(28, 150)
	badge.size = Vector2(58, 28)
	badge.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	badge.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	badge.add_theme_font_size_override("font_size", 12)
	badge.add_theme_color_override("font_color", PresentationTheme.INK)
	badge.add_theme_stylebox_override("normal", PresentationTheme.panel_style(Color("#19130ff2"), PresentationTheme.GOLD_DARK, 2, 2, 2))
	badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pile.add_child(badge)
	if is_draw_pile:
		draw_count = badge
	else:
		discard_count_label = badge
	var archive_button := Button.new()
	archive_button.name = "OpenDrawArchive" if is_draw_pile else "OpenDiscardArchive"
	archive_button.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	archive_button.flat = true
	archive_button.focus_mode = Control.FOCUS_NONE
	archive_button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	archive_button.tooltip_text = tr("PILE_DRAW_TOOLTIP") if is_draw_pile else tr("PILE_DISCARD_TOOLTIP")
	archive_button.pressed.connect(_on_draw_archive_pressed if is_draw_pile else _on_discard_archive_pressed)
	pile.add_child(archive_button)
	pile_archive_buttons["draw" if is_draw_pile else "discard"] = archive_button
	return pile


func _build_hand() -> void:
	var hand_panel := Panel.new()
	hand_panel.name = "LooseHand"
	hand_panel.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	hand_panel.offset_left = 108
	hand_panel.offset_top = -242
	hand_panel.offset_right = -108
	hand_panel.offset_bottom = -70
	hand_panel.add_theme_stylebox_override("panel", PresentationTheme.panel_style(Color.TRANSPARENT, Color.TRANSPARENT, 0, 0, 0))
	game_layer.add_child(hand_panel)

	hand_layer = Control.new()
	hand_layer.name = "CardFan"
	hand_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	hand_layer.offset_left = 10
	hand_layer.offset_top = 6
	hand_layer.offset_right = -10
	hand_layer.offset_bottom = 4
	hand_layer.clip_contents = false
	hand_panel.add_child(hand_layer)


func _build_future_slots() -> void:
	var rail := Control.new()
	rail.name = "UtilityRail"
	rail.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	rail.position = Vector2(-150, 158)
	rail.size = Vector2(134, 348)
	game_layer.add_child(rail)

	var drink_panel := Panel.new()
	drink_panel.name = "DrinkArea"
	drink_panel.position = Vector2.ZERO
	drink_panel.size = Vector2(134, 106)
	drink_panel.add_theme_stylebox_override("panel", PresentationTheme.panel_style(Color("#17120fe8"), Color("#8d5b30"), 2, 2, 4))
	rail.add_child(drink_panel)
	drink_title_label = Label.new()
	drink_title_label.position = Vector2(9, 7)
	drink_title_label.size = Vector2(116, 18)
	drink_title_label.text = tr("HUD_DRINK")
	drink_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	drink_title_label.add_theme_font_size_override("font_size", 12)
	drink_title_label.add_theme_color_override("font_color", PresentationTheme.GOLD)
	drink_panel.add_child(drink_title_label)
	drink_button = Button.new()
	drink_button.name = "DrinkSlot"
	drink_button.position = Vector2(34, 30)
	drink_button.size = Vector2(66, 64)
	drink_button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	drink_button.add_theme_stylebox_override("normal", PresentationTheme.panel_style(Color("#0b0907c0"), Color("#6b5138"), 1, 2, 2))
	drink_button.add_theme_stylebox_override("hover", PresentationTheme.panel_style(Color("#17221ee8"), PresentationTheme.TEA, 2, 2, 2))
	drink_button.add_theme_stylebox_override("pressed", PresentationTheme.panel_style(Color("#0b1714f0"), PresentationTheme.GOLD, 2, 2, 2))
	drink_button.pressed.connect(_on_drink_pressed)
	drink_panel.add_child(drink_button)
	drink_charge_outline = CARD_ACTION_OUTLINE_SCRIPT.new()
	drink_charge_outline.name = "DrinkChargeOutline"
	drink_charge_outline.position = Vector2(-7, -7)
	drink_charge_outline.size = drink_button.size + Vector2(14, 14)
	drink_charge_outline.visible = false
	drink_button.add_child(drink_charge_outline)
	drink_name_label = Label.new()
	drink_name_label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	drink_name_label.text = tr(DrinkCatalog.display_name(deal.current_drink_id)).to_upper()
	drink_name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	drink_name_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	drink_name_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	drink_name_label.add_theme_font_size_override("font_size", 11)
	drink_name_label.add_theme_color_override("font_color", PresentationTheme.TEA)
	drink_name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	drink_button.add_child(drink_name_label)

	var relic_panel := Panel.new()
	relic_panel.name = "RelicsArea"
	relic_panel.position = Vector2(0, 116)
	relic_panel.size = Vector2(134, 232)
	relic_panel.add_theme_stylebox_override("panel", PresentationTheme.panel_style(Color("#17120fe8"), Color("#8d5b30"), 2, 2, 4))
	rail.add_child(relic_panel)
	relic_title_label = Label.new()
	relic_title_label.position = Vector2(9, 7)
	relic_title_label.size = Vector2(116, 18)
	relic_title_label.text = tr("HUD_RELICS")
	relic_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	relic_title_label.add_theme_font_size_override("font_size", 12)
	relic_title_label.add_theme_color_override("font_color", PresentationTheme.GOLD)
	relic_panel.add_child(relic_title_label)
	var relic_scroll := ScrollContainer.new()
	relic_scroll.name = "RelicScroll"
	relic_scroll.position = Vector2(9, 30)
	relic_scroll.size = Vector2(116, 192)
	relic_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	relic_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	relic_panel.add_child(relic_scroll)
	relic_grid = GridContainer.new()
	relic_grid.name = "RelicGrid"
	relic_grid.columns = 2
	relic_grid.add_theme_constant_override("h_separation", 6)
	relic_grid.add_theme_constant_override("v_separation", 6)
	relic_scroll.add_child(relic_grid)
	set_relic_capacity(INITIAL_RELIC_SLOT_COUNT)


func set_relic_capacity(capacity: int) -> void:
	if relic_grid == null:
		return
	for child in relic_grid.get_children():
		relic_grid.remove_child(child)
		child.queue_free()
	for index in range(maxi(1, capacity)):
		var slot := PanelContainer.new()
		slot.name = "RelicSlot%02d" % (index + 1)
		slot.custom_minimum_size = Vector2(52, 78)
		slot.mouse_filter = Control.MOUSE_FILTER_IGNORE
		slot.add_theme_stylebox_override("panel", PresentationTheme.panel_style(Color("#0b0907c0"), Color("#6b5138"), 1, 2, 2))
		relic_grid.add_child(slot)
		var mark := Label.new()
		mark.text = "%d" % (index + 1)
		mark.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		mark.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		mark.add_theme_font_size_override("font_size", 12)
		mark.add_theme_color_override("font_color", Color("#6b5138"))
		mark.mouse_filter = Control.MOUSE_FILTER_IGNORE
		slot.add_child(mark)


func _build_action_dock() -> void:
	var dock := Panel.new()
	dock.name = "ActionDock"
	dock.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	dock.offset_left = 16
	dock.offset_top = -64
	dock.offset_right = -16
	dock.offset_bottom = -10
	dock.add_theme_stylebox_override("panel", PresentationTheme.panel_style(Color("#17120ff2"), Color("#8d5b30"), 2, 2, 5))
	game_layer.add_child(dock)

	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 14)
	margin.add_theme_constant_override("margin_top", 6)
	margin.add_theme_constant_override("margin_right", 9)
	margin.add_theme_constant_override("margin_bottom", 6)
	dock.add_child(margin)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	margin.add_child(row)
	status_label = Label.new()
	status_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	status_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	status_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	status_label.add_theme_font_size_override("font_size", 12)
	status_label.add_theme_color_override("font_color", PresentationTheme.MUTED)
	row.add_child(status_label)

	hint_button = _make_action_button(row, tr("ACTION_HINT"), "gold", 104)
	hint_button.tooltip_text = tr("ACTION_HINT_TOOLTIP")
	hint_button.pressed.connect(_on_hint_pressed)
	sort_button = _make_action_button(row, tr("ACTION_SORT"), "neutral", 104)
	sort_button.tooltip_text = tr("ACTION_SORT_TOOLTIP")
	sort_button.pressed.connect(_on_sort_pressed)
	ha_button = _make_action_button(row, tr("ACTION_MELD"), "tea", 108)
	ha_button.tooltip_text = tr("ACTION_MELD_TOOLTIP")
	ha_button.pressed.connect(_on_ha_pressed)
	extend_button = _make_action_button(row, tr("ACTION_EXTEND"), "gold", 116)
	extend_button.tooltip_text = tr("ACTION_EXTEND_TOOLTIP")
	extend_button.pressed.connect(_on_extend_pressed)
	discard_button = _make_action_button(row, tr("ACTION_DISCARD"), "danger", 120)
	discard_button.tooltip_text = tr("ACTION_DISCARD_TOOLTIP")
	discard_button.pressed.connect(_on_discard_pressed)
	settle_button = _make_action_button(row, tr("ACTION_SETTLE"), "tea", 108)
	settle_button.tooltip_text = tr("ACTION_SETTLE_TOOLTIP")
	settle_button.pressed.connect(_on_settle_pressed)


func _make_action_button(parent: Container, text_value: String, tone: String, width: float) -> Button:
	var button := Button.new()
	button.text = text_value
	button.custom_minimum_size = Vector2(width, 40)
	PresentationTheme.configure_button(button, tone)
	parent.add_child(button)
	return button


func _build_effect_layers() -> void:
	particle_layer = Control.new()
	particle_layer.name = "MotionEffects"
	particle_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	particle_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	particle_layer.z_index = 100
	game_layer.add_child(particle_layer)

	_build_discard_archive()
	_build_score_overlay()
	_build_banner()
	_build_modal()
	_build_campaign_overlay()
	tutorial_spotlight = TUTORIAL_SPOTLIGHT_SCRIPT.new()
	tutorial_spotlight.name = "TutorialSpotlight"
	tutorial_spotlight.z_index = 105
	tutorial_spotlight.visible = false
	game_layer.add_child(tutorial_spotlight)
	_build_tutorial_coach()


func _build_tutorial_coach() -> void:
	tutorial_coach = PanelContainer.new()
	tutorial_coach.name = "TutorialCoach"
	tutorial_coach.set_anchors_preset(Control.PRESET_CENTER_TOP)
	tutorial_coach.position = Vector2(-370, 112)
	tutorial_coach.size = Vector2(740, 106)
	tutorial_coach.mouse_filter = Control.MOUSE_FILTER_STOP
	tutorial_coach.z_index = 110
	tutorial_coach.visible = false
	tutorial_coach.add_theme_stylebox_override("panel", PresentationTheme.panel_style(Color("#102a24f7"), PresentationTheme.TEA, 2, 10, 7))
	game_layer.add_child(tutorial_coach)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 16)
	margin.add_theme_constant_override("margin_top", 10)
	margin.add_theme_constant_override("margin_right", 12)
	margin.add_theme_constant_override("margin_bottom", 10)
	tutorial_coach.add_child(margin)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	margin.add_child(row)
	tutorial_progress_label = Label.new()
	tutorial_progress_label.custom_minimum_size = Vector2(78, 0)
	tutorial_progress_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tutorial_progress_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	tutorial_progress_label.add_theme_font_size_override("font_size", 12)
	tutorial_progress_label.add_theme_color_override("font_color", PresentationTheme.GOLD)
	row.add_child(tutorial_progress_label)
	var copy := VBoxContainer.new()
	copy.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	copy.alignment = BoxContainer.ALIGNMENT_CENTER
	copy.add_theme_constant_override("separation", 3)
	row.add_child(copy)
	tutorial_title_label = Label.new()
	tutorial_title_label.add_theme_font_size_override("font_size", 16)
	tutorial_title_label.add_theme_color_override("font_color", PresentationTheme.INK)
	copy.add_child(tutorial_title_label)
	tutorial_body_label = Label.new()
	tutorial_body_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	tutorial_body_label.add_theme_font_size_override("font_size", 12)
	tutorial_body_label.add_theme_color_override("font_color", PresentationTheme.MUTED)
	copy.add_child(tutorial_body_label)
	tutorial_exit_button = Button.new()
	tutorial_exit_button.custom_minimum_size = Vector2(128, 46)
	PresentationTheme.configure_button(tutorial_exit_button, "neutral")
	tutorial_exit_button.pressed.connect(_on_tutorial_exit_pressed)
	row.add_child(tutorial_exit_button)


func _build_discard_archive() -> void:
	discard_archive_overlay = Control.new()
	discard_archive_overlay.name = "DiscardArchiveOverlay"
	discard_archive_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	discard_archive_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	discard_archive_overlay.z_index = 160
	discard_archive_overlay.visible = false
	game_layer.add_child(discard_archive_overlay)

	var dim := ColorRect.new()
	dim.name = "ArchiveDim"
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.color = Color("#020302b8")
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	dim.gui_input.connect(_on_discard_archive_dim_input)
	discard_archive_overlay.add_child(dim)

	var panel := Panel.new()
	panel.name = "ArchivePanel"
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.position = Vector2(-460, -250)
	panel.size = Vector2(920, 500)
	panel.mouse_filter = Control.MOUSE_FILTER_STOP
	panel.add_theme_stylebox_override("panel", PresentationTheme.panel_style(Color("#14100dfb"), PresentationTheme.GOLD, 2, 16, 10))
	discard_archive_overlay.add_child(panel)

	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 24)
	margin.add_theme_constant_override("margin_top", 20)
	margin.add_theme_constant_override("margin_right", 24)
	margin.add_theme_constant_override("margin_bottom", 20)
	panel.add_child(margin)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 14)
	margin.add_child(column)

	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 12)
	column.add_child(header)
	var title_column := VBoxContainer.new()
	title_column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_column.add_theme_constant_override("separation", -2)
	header.add_child(title_column)
	pile_archive_title = Label.new()
	pile_archive_title.name = "ArchiveTitle"
	pile_archive_title.text = tr("ARCHIVE_DISCARD_TITLE")
	pile_archive_title.add_theme_font_size_override("font_size", 24)
	pile_archive_title.add_theme_color_override("font_color", PresentationTheme.GOLD)
	title_column.add_child(pile_archive_title)
	discard_archive_count = Label.new()
	discard_archive_count.name = "ArchiveCount"
	discard_archive_count.add_theme_font_size_override("font_size", 11)
	discard_archive_count.add_theme_color_override("font_color", PresentationTheme.MUTED)
	title_column.add_child(discard_archive_count)
	discard_archive_close = _make_action_button(header, tr("ARCHIVE_CLOSE"), "danger", 122)
	discard_archive_close.name = "CloseArchive"
	discard_archive_close.pressed.connect(_hide_discard_archive)

	var suits_row := HBoxContainer.new()
	suits_row.name = "SuitColumns"
	suits_row.size_flags_vertical = Control.SIZE_EXPAND_FILL
	suits_row.add_theme_constant_override("separation", 10)
	column.add_child(suits_row)
	for suit in DeckManager.SUITS:
		var suit_panel := PanelContainer.new()
		suit_panel.name = "%sColumn" % suit
		suit_panel.custom_minimum_size = Vector2(210, 0)
		suit_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		suit_panel.add_theme_stylebox_override("panel", PresentationTheme.panel_style(Color("#211a15ed"), _discard_suit_color(suit), 1, 8, 5))
		suits_row.add_child(suit_panel)
		var suit_margin := MarginContainer.new()
		suit_margin.add_theme_constant_override("margin_left", 10)
		suit_margin.add_theme_constant_override("margin_top", 10)
		suit_margin.add_theme_constant_override("margin_right", 10)
		suit_margin.add_theme_constant_override("margin_bottom", 10)
		suit_panel.add_child(suit_margin)
		var suit_column := VBoxContainer.new()
		suit_column.add_theme_constant_override("separation", 8)
		suit_margin.add_child(suit_column)
		var suit_title := Label.new()
		suit_title.text = _discard_suit_title(suit)
		suit_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		suit_title.add_theme_font_size_override("font_size", 14)
		suit_title.add_theme_color_override("font_color", _discard_suit_color(suit))
		suit_column.add_child(suit_title)
		discard_archive_suit_titles[suit] = suit_title
		var scroll := ScrollContainer.new()
		scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
		scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
		scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
		suit_column.add_child(scroll)
		var grid := GridContainer.new()
		grid.name = "%sCards" % suit
		grid.columns = 3
		grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		grid.add_theme_constant_override("h_separation", 4)
		grid.add_theme_constant_override("v_separation", 5)
		scroll.add_child(grid)
		discard_archive_suit_grids[suit] = grid


func _on_draw_archive_pressed() -> void:
	_toggle_pile_archive("draw")


func _on_discard_archive_pressed() -> void:
	_toggle_pile_archive("discard")


func _toggle_pile_archive(mode: String) -> void:
	if discard_archive_overlay.visible and pile_archive_mode == mode:
		_hide_discard_archive()
	else:
		pile_archive_mode = mode
		_show_discard_archive()


func _show_discard_archive() -> void:
	if not game_started or interaction_locked or modal_overlay.visible or score_overlay.visible:
		return
	_sync_pile_archive()
	discard_archive_overlay.visible = true
	discard_archive_overlay.modulate = Color(1, 1, 1, 0)
	var panel := discard_archive_overlay.get_node("ArchivePanel") as Panel
	panel.scale = Vector2(0.97, 0.97)
	panel.pivot_offset = panel.size * 0.5
	var tween := create_tween().set_parallel(true)
	tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(discard_archive_overlay, "modulate", Color.WHITE, 0.14)
	tween.tween_property(panel, "scale", Vector2.ONE, 0.18)
	discard_archive_close.grab_focus()


func _hide_discard_archive() -> void:
	discard_archive_overlay.visible = false
	discard_archive_close.release_focus()


func _on_discard_archive_dim_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		_hide_discard_archive()


func _sync_pile_archive() -> void:
	var source_cards: Array[CardData] = deal.deck.draw_pile if pile_archive_mode == "draw" else deal.deck.discard_pile
	pile_archive_title.text = tr("ARCHIVE_DRAW_TITLE") if pile_archive_mode == "draw" else tr("ARCHIVE_DISCARD_TITLE")
	discard_archive_count.text = tr("ARCHIVE_COUNT") % source_cards.size()
	var cards_by_suit := {}
	for suit in DeckManager.SUITS:
		cards_by_suit[suit] = [] as Array[CardData]
	for card in source_cards:
		if cards_by_suit.has(card.suit):
			cards_by_suit[card.suit].append(card)
	for suit in DeckManager.SUITS:
		var grid: GridContainer = discard_archive_suit_grids[suit]
		for child in grid.get_children():
			grid.remove_child(child)
			child.queue_free()
		var suit_cards: Array[CardData] = cards_by_suit[suit]
		suit_cards.sort_custom(_discard_card_less)
		if suit_cards.is_empty():
			var empty := Label.new()
			empty.custom_minimum_size = Vector2(172, 52)
			empty.text = tr("ARCHIVE_DRAW_EMPTY") if pile_archive_mode == "draw" else tr("ARCHIVE_DISCARD_EMPTY")
			empty.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			empty.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			empty.add_theme_font_size_override("font_size", 10)
			empty.add_theme_color_override("font_color", PresentationTheme.MUTED)
			grid.add_child(empty)
			continue
		for card in suit_cards:
			grid.add_child(_build_discard_archive_card(card))


func _build_discard_archive_card(card: CardData) -> Control:
	var holder := Control.new()
	holder.custom_minimum_size = Vector2(54, 75)
	holder.tooltip_text = tr("CARD_POINTS") % [card.short_label(), card.score_value()]
	var texture := TextureRect.new()
	texture.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	texture.texture = load(card.texture_path()) as Texture2D
	texture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	texture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	texture.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	texture.mouse_filter = Control.MOUSE_FILTER_IGNORE
	holder.add_child(texture)
	return holder


func _discard_card_less(left: CardData, right: CardData) -> bool:
	if left.rank_index != right.rank_index:
		return left.rank_index < right.rank_index
	return left.unique_id < right.unique_id


func _discard_suit_title(suit: String) -> String:
	match suit:
		"Spades": return tr("SUIT_SPADES")
		"Hearts": return tr("SUIT_HEARTS")
		"Diamonds": return tr("SUIT_DIAMONDS")
		_: return tr("SUIT_CLUBS")


func _discard_suit_color(suit: String) -> Color:
	return PresentationTheme.RED if suit in ["Hearts", "Diamonds"] else PresentationTheme.INK


func _build_score_overlay() -> void:
	score_overlay = Control.new()
	score_overlay.name = "ScoreFeedback"
	score_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	score_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	score_overlay.z_index = 120
	score_overlay.visible = false
	game_layer.add_child(score_overlay)

	score_panel = Panel.new()
	score_panel.set_anchors_preset(Control.PRESET_CENTER)
	score_panel.position = Vector2(-270, -112)
	score_panel.size = Vector2(540, 224)
	score_panel.pivot_offset = score_panel.size * 0.5
	score_panel.add_theme_stylebox_override("panel", PresentationTheme.panel_style(Color("#0b1d19f7"), PresentationTheme.GOLD, 2, 18, 12))
	score_overlay.add_child(score_panel)

	var accent := ColorRect.new()
	accent.position = Vector2(18, 16)
	accent.size = Vector2(4, 192)
	accent.color = PresentationTheme.GOLD
	accent.mouse_filter = Control.MOUSE_FILTER_IGNORE
	score_panel.add_child(accent)
	score_title = _score_label(score_panel, Vector2(38, 18), Vector2(482, 31), 13, PresentationTheme.GOLD)
	score_line_a = _score_label(score_panel, Vector2(38, 57), Vector2(482, 41), 20, PresentationTheme.INK)
	score_line_b = _score_label(score_panel, Vector2(38, 100), Vector2(482, 41), 20, PresentationTheme.INK)
	score_payout = _score_label(score_panel, Vector2(38, 151), Vector2(482, 52), 28, PresentationTheme.TEA)


func _score_label(parent: Control, at: Vector2, label_size: Vector2, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.position = at
	label.size = label_size
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	parent.add_child(label)
	return label


func _build_banner() -> void:
	banner_panel = PanelContainer.new()
	banner_panel.name = "TurnBanner"
	banner_panel.set_anchors_preset(Control.PRESET_CENTER_TOP)
	banner_panel.position = Vector2(-250, 103)
	banner_panel.size = Vector2(500, 38)
	banner_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	banner_panel.z_index = 140
	banner_panel.modulate = Color(1, 1, 1, 0)
	banner_panel.add_theme_stylebox_override("panel", PresentationTheme.panel_style(Color("#132d27f4"), PresentationTheme.GOLD_DARK, 1, 16, 6))
	game_layer.add_child(banner_panel)
	banner_label = Label.new()
	banner_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	banner_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	banner_label.add_theme_font_size_override("font_size", 11)
	banner_label.add_theme_color_override("font_color", PresentationTheme.INK)
	banner_panel.add_child(banner_label)


func _build_modal() -> void:
	modal_overlay = Control.new()
	modal_overlay.name = "DecisionOverlay"
	modal_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	modal_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	modal_overlay.z_index = 200
	modal_overlay.visible = false
	game_layer.add_child(modal_overlay)
	var dim := ColorRect.new()
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.color = Color("#020907c7")
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	modal_overlay.add_child(dim)
	var panel := Panel.new()
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.position = Vector2(-310, -205)
	panel.size = Vector2(620, 410)
	panel.add_theme_stylebox_override("panel", PresentationTheme.panel_style(Color("#102a24ff"), PresentationTheme.GOLD, 2, 20, 16))
	modal_overlay.add_child(panel)
	var column := VBoxContainer.new()
	column.position = Vector2(38, 30)
	column.size = Vector2(544, 350)
	column.add_theme_constant_override("separation", 10)
	panel.add_child(column)
	modal_kicker = Label.new()
	modal_kicker.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	modal_kicker.add_theme_font_size_override("font_size", 11)
	modal_kicker.add_theme_color_override("font_color", PresentationTheme.GOLD)
	column.add_child(modal_kicker)
	modal_title = Label.new()
	modal_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	modal_title.add_theme_font_size_override("font_size", 31)
	modal_title.add_theme_color_override("font_color", PresentationTheme.INK)
	column.add_child(modal_title)
	modal_body = Label.new()
	modal_body.custom_minimum_size = Vector2(0, 82)
	modal_body.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	modal_body.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	modal_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	modal_body.add_theme_font_size_override("font_size", 15)
	modal_body.add_theme_color_override("font_color", PresentationTheme.MUTED)
	column.add_child(modal_body)
	modal_detail = Label.new()
	modal_detail.custom_minimum_size = Vector2(0, 60)
	modal_detail.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	modal_detail.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	modal_detail.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	modal_detail.add_theme_font_size_override("font_size", 12)
	modal_detail.add_theme_color_override("font_color", PresentationTheme.TEA)
	column.add_child(modal_detail)
	var buttons := HBoxContainer.new()
	buttons.alignment = BoxContainer.ALIGNMENT_CENTER
	buttons.add_theme_constant_override("separation", 14)
	column.add_child(buttons)
	modal_primary = _make_action_button(buttons, "GIỮ", "tea", 206)
	modal_primary.custom_minimum_size.y = 52
	modal_primary.pressed.connect(_on_modal_primary_pressed)
	modal_secondary = _make_action_button(buttons, "ĐỔI", "danger", 206)
	modal_secondary.custom_minimum_size.y = 52
	modal_secondary.pressed.connect(_on_modal_secondary_pressed)


func _build_campaign_overlay() -> void:
	campaign_overlay = Control.new()
	campaign_overlay.name = "CampaignEventOverlay"
	campaign_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	campaign_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	campaign_overlay.z_index = 190
	campaign_overlay.visible = false
	game_layer.add_child(campaign_overlay)
	var dim := ColorRect.new()
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.color = Color("#090704d9")
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	campaign_overlay.add_child(dim)
	var panel := Panel.new()
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.position = Vector2(-410, -270)
	panel.size = Vector2(820, 540)
	panel.add_theme_stylebox_override("panel", PresentationTheme.panel_style(Color("#17120ffc"), PresentationTheme.GOLD, 2, 18, 12))
	campaign_overlay.add_child(panel)
	var column := VBoxContainer.new()
	column.position = Vector2(34, 26)
	column.size = Vector2(752, 488)
	column.add_theme_constant_override("separation", 10)
	panel.add_child(column)
	campaign_event_kicker = Label.new()
	campaign_event_kicker.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	campaign_event_kicker.add_theme_font_size_override("font_size", 12)
	campaign_event_kicker.add_theme_color_override("font_color", PresentationTheme.GOLD)
	column.add_child(campaign_event_kicker)
	campaign_event_title = Label.new()
	campaign_event_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	campaign_event_title.add_theme_font_size_override("font_size", 30)
	campaign_event_title.add_theme_color_override("font_color", PresentationTheme.INK)
	column.add_child(campaign_event_title)
	campaign_event_wallet = Label.new()
	campaign_event_wallet.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	campaign_event_wallet.add_theme_font_size_override("font_size", 13)
	campaign_event_wallet.add_theme_color_override("font_color", PresentationTheme.TEA)
	column.add_child(campaign_event_wallet)
	var divider := HSeparator.new()
	divider.add_theme_constant_override("separation", 8)
	column.add_child(divider)
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	column.add_child(scroll)
	campaign_participants = VBoxContainer.new()
	campaign_participants.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	campaign_participants.add_theme_constant_override("separation", 10)
	scroll.add_child(campaign_participants)
	campaign_continue_button = Button.new()
	campaign_continue_button.name = "CampaignContinueButton"
	campaign_continue_button.custom_minimum_size = Vector2(280, 48)
	campaign_continue_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	PresentationTheme.configure_button(campaign_continue_button, "tea")
	campaign_continue_button.pressed.connect(_on_campaign_continue_pressed)
	column.add_child(campaign_continue_button)


func _show_campaign_event(event: EventInstance) -> void:
	current_campaign_event = event
	interaction_locked = true
	_set_hand_interaction_enabled(false)
	modal_overlay.visible = false
	campaign_overlay.visible = true
	var day: Dictionary = event.context.get("day", campaign.current_day())
	campaign_event_kicker.text = tr(EventManager.slot_name_key(event.slot))
	campaign_event_title.text = tr(String(day.get("name_key", "")))
	campaign_event_wallet.text = tr("CAMPAIGN_WALLET_REQUIREMENT") % [
		VndWallet.format_vnd(deal.wallet.balance_vnd),
		VndWallet.format_vnd(int(day.get("required_vnd", 0))),
	]
	_clear_campaign_participants()
	if event.participants.is_empty():
		var empty := Label.new()
		empty.text = tr("EVENT_NO_PARTICIPANTS")
		empty.custom_minimum_size.y = 170
		empty.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		empty.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		empty.add_theme_font_size_override("font_size", 16)
		empty.add_theme_color_override("font_color", PresentationTheme.MUTED)
		campaign_participants.add_child(empty)
	else:
		for participant in event.participants:
			_build_campaign_participant(participant, event)
	campaign_continue_button.text = tr("EVENT_CONTINUE")
	campaign_continue_button.disabled = not event.can_exit
	campaign_continue_button.call_deferred("grab_focus")
	_refresh_stats()


func _clear_campaign_participants() -> void:
	for child in campaign_participants.get_children():
		campaign_participants.remove_child(child)
		child.queue_free()


func _build_campaign_participant(participant: NPCDefinition, event: EventInstance) -> void:
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", PresentationTheme.panel_style(Color("#231c17f0"), Color("#8d5b30"), 1, 8, 5))
	campaign_participants.add_child(panel)
	var margin := MarginContainer.new()
	for side in ["left", "top", "right", "bottom"]:
		margin.add_theme_constant_override("margin_%s" % side, 10)
	panel.add_child(margin)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 7)
	margin.add_child(column)
	var name_label := Label.new()
	name_label.text = tr(participant.display_name_key)
	name_label.add_theme_font_size_override("font_size", 19)
	name_label.add_theme_color_override("font_color", PresentationTheme.GOLD)
	column.add_child(name_label)
	for interaction in event.interactions:
		if interaction.participant_id != participant.id:
			continue
		if interaction.action_type == "choose_drink":
			_build_drink_choices(column, event, interaction)
		else:
			var interact_button := Button.new()
			interact_button.text = tr("EVENT_INTERACT_DONE") if interaction.completed else tr("EVENT_INTERACT")
			interact_button.disabled = interaction.completed
			PresentationTheme.configure_button(interact_button, "neutral")
			interact_button.pressed.connect(_on_campaign_interaction_pressed.bind(interaction.id))
			column.add_child(interact_button)


func _build_drink_choices(parent: VBoxContainer, event: EventInstance, interaction: EventInteraction) -> void:
	var instruction := Label.new()
	var period_key := "DRINK_PERIOD_MORNING_NOON" if event.slot == EventManager.EventSlot.STARTER else "DRINK_PERIOD_AFTERNOON_EVENING"
	instruction.text = tr("EVENT_CHOOSE_DRINK") % tr(period_key)
	instruction.add_theme_font_size_override("font_size", 13)
	instruction.add_theme_color_override("font_color", PresentationTheme.MUTED)
	parent.add_child(instruction)
	if interaction.completed:
		var selected := Label.new()
		selected.text = tr("EVENT_DRINK_SELECTED") % tr(DrinkCatalog.display_name(drink_manager.active_drink_id))
		selected.add_theme_font_size_override("font_size", 16)
		selected.add_theme_color_override("font_color", PresentationTheme.TEA)
		parent.add_child(selected)
		return
	var choices := GridContainer.new()
	choices.columns = 4
	choices.add_theme_constant_override("h_separation", 8)
	parent.add_child(choices)
	for drink_id in drink_manager.available_drink_ids():
		var button := Button.new()
		button.name = "Drink_%s" % drink_id
		button.custom_minimum_size = Vector2(174, 60)
		button.text = "%s\n%s" % [
			tr(DrinkCatalog.display_name(drink_id)).to_upper(),
			VndWallet.format_vnd(drink_manager.price_for(drink_id)),
		]
		button.disabled = not drink_manager.can_afford(drink_id)
		PresentationTheme.configure_button(button, "tea" if drink_id == DrinkCatalog.TRA_DA else "neutral")
		button.pressed.connect(_on_campaign_drink_pressed.bind(event.slot, interaction.id, drink_id))
		choices.add_child(button)


func _sync_all(result: Dictionary = {}, animate_all_cards: bool = false) -> void:
	var animated_cards := _cards_from_result(result)
	if animate_all_cards:
		animated_cards.clear()
		animated_cards.append_array(deal.hand)
	_sync_hand(animated_cards)
	_sync_card_probability_badges()
	_sync_card_action_outlines()
	_sync_melds()
	_sync_music_reactive_cards()
	_sync_piles()
	_sync_discard_history()
	if discard_archive_overlay.visible:
		_sync_pile_archive()
	if drink_name_label != null:
		drink_name_label.text = tr(DrinkCatalog.display_name(deal.current_drink_id)).to_upper()
		drink_button.tooltip_text = _drink_tooltip()
		drink_charge_outline.set_drink_cue(deal.current_drink_has_charge())
	_refresh_stats()
	_refresh_actions()


func _sync_hand(animated_cards: Array[CardData]) -> void:
	var active_ids := {}
	var animated_ids := {}
	for card in animated_cards:
		animated_ids[card.unique_id] = true
	for card in deal.hand:
		active_ids[card.unique_id] = true
		if not hand_views.has(card.unique_id):
			var view := PlayingCardView.new()
			hand_layer.add_child(view)
			view.set_card(card)
			view.card_pressed.connect(_on_card_pressed)
			view.card_drag_started.connect(_on_card_drag_started.bind(view))
			hand_views[card.unique_id] = view
			if animated_ids.has(card.unique_id):
				var origin := draw_pile_visual.get_global_rect().get_center() - hand_layer.global_position
				view.spawn_from(origin)
	for existing_id in hand_views.keys():
		if not active_ids.has(existing_id):
			var old_view: PlayingCardView = hand_views[existing_id]
			old_view.queue_free()
			hand_views.erase(existing_id)
	_layout_hand(true)


func _sync_card_probability_badges() -> void:
	var draw_number := 0
	if deal.state == DealState.STATE_ACTIVE and deal.discard_count < DealState.DISCARDS_PER_PHASE - 1:
		var size_after_discard := maxi(deal.hand.size() - 1, 0)
		draw_number = mini(maxi(DealState.ACTIVE_HAND_TARGET - size_after_discard, 0), deal.deck.draw_pile.size())
	var best_by_card := MeldProbabilityAdvisor.best_new_meld_chance_by_card(deal.hand, deal.deck.draw_pile, draw_number)
	for card in deal.hand:
		var view: PlayingCardView = hand_views.get(card.unique_id)
		if view == null:
			continue
		var candidate: Dictionary = best_by_card.get(card.unique_id, {})
		if candidate.is_empty():
			view.set_meld_chance(0.0, false, tr("PROBABILITY_NO_TARGET"), "—", draw_number)
			continue
		var needed_text := "—" if candidate["needed_labels"].is_empty() else " / ".join(candidate["needed_labels"])
		view.set_meld_chance(
			float(candidate["probability"]),
			bool(candidate["ready"]),
			MeldProbabilityAdvisor.localized_label(candidate),
			needed_text,
			draw_number
		)


func _sync_card_action_outlines() -> Dictionary:
	var actionable := deal.legal_action_card_ids()
	var meld_card_ids: Dictionary = actionable["meld"]
	var extension_card_ids: Dictionary = actionable["extend"]
	if tutorial_active:
		meld_card_ids = {}
		extension_card_ids = {}
		if tutorial_step in [TUTORIAL_SELECT_RUN, TUTORIAL_PLAY_RUN]:
			for card_id in TUTORIAL_RUN_IDS:
				meld_card_ids[card_id] = true
		elif tutorial_step in [TUTORIAL_SELECT_EXTEND, TUTORIAL_SELECT_MELD, TUTORIAL_EXTEND]:
			extension_card_ids[TUTORIAL_EXTENSION_ID] = true
		actionable = {"meld": meld_card_ids, "extend": extension_card_ids}
	for card in deal.hand:
		var view: PlayingCardView = hand_views.get(card.unique_id)
		if view != null:
			view.set_action_cues(meld_card_ids.has(card.unique_id), extension_card_ids.has(card.unique_id))
			view.set_drink_preserved(deal.sam_dua_preserved_cards.has(card) or pending_drink_card_ids.has(card.unique_id))
	return actionable


func _sync_music_reactive_cards() -> void:
	_reactive_assignments_clear()
	var selected := _selected_cards()
	var targets := deal.legal_action_targets_for_selection(selected, selected_meld_id)
	var hand_card_ids: Dictionary = targets.get("hand", {})
	var hand_assignment_index := 0
	for card in deal.hand:
		if not hand_card_ids.has(card.unique_id):
			continue
		var view := hand_views.get(card.unique_id) as PlayingCardView
		if view != null:
			reactive_hand_cards_by_band[hand_assignment_index % MUSIC_BAND_COUNT].append(view)
			hand_assignment_index += 1

	var table_meld_ids: Dictionary = targets.get("melds", {})
	for meld in deal.melds:
		if not table_meld_ids.has(meld.meld_id):
			continue
		var view := meld_views.get(meld.meld_id) as MeldView
		if view == null:
			continue
		for card_index in range(meld.cards.size()):
			var card: CardData = meld.cards[card_index]
			reactive_meld_cards_by_band[card_index % MUSIC_BAND_COUNT].append({
				"view": view,
				"card_id": card.unique_id,
			})


func _reactive_assignments_clear() -> void:
	reactive_hand_cards_by_band.clear()
	reactive_meld_cards_by_band.clear()
	for band_index in range(MUSIC_BAND_COUNT):
		reactive_hand_cards_by_band[band_index] = []
		reactive_meld_cards_by_band[band_index] = []


func _layout_hand(animate: bool) -> void:
	if hand_layer == null or hand_layer.size.x <= 0:
		return
	var count := deal.hand.size()
	if count == 0:
		return
	var spacing := 0.0
	if count > 1:
		spacing = minf(76.0, maxf((hand_layer.size.x - CARD_SIZE.x - 34.0) / float(count - 1), 28.0))
	var total_width := CARD_SIZE.x + spacing * float(count - 1)
	var start_x := (hand_layer.size.x - total_width) * 0.5
	for index in range(count):
		var card := deal.hand[index]
		var view: PlayingCardView = hand_views[card.unique_id]
		var normalized := 0.0 if count == 1 else (float(index) / float(count - 1) - 0.5) * 2.0
		var arc_y := 9.0 + normalized * normalized * 14.0
		view.set_stack_order(index)
		view.set_selected(selected_card_ids.has(card.unique_id), false)
		view.layout_to(Vector2(start_x + spacing * index, arc_y), normalized * 0.055, animate)


func _sync_melds() -> void:
	empty_meld_label.visible = deal.melds.is_empty()
	var active_meld_ids := {}
	for meld in deal.melds:
		active_meld_ids[meld.meld_id] = true
	for existing_id in meld_views.keys():
		if active_meld_ids.has(existing_id):
			continue
		var stale_view := meld_views[existing_id] as MeldView
		if stale_view != null:
			meld_row.remove_child(stale_view)
			stale_view.queue_free()
		meld_views.erase(existing_id)
	if deal.melds.is_empty():
		selected_meld_id = -1
		selected_drink_meld_id = -1
		selected_drink_meld_card_id = ""
		return
	if selected_meld_id >= 0 and deal.get_meld(selected_meld_id) == null:
		selected_meld_id = -1
	if selected_drink_meld_id >= 0 and deal.get_meld(selected_drink_meld_id) == null:
		selected_drink_meld_id = -1
		selected_drink_meld_card_id = ""
	var selected_cards := _selected_cards()
	for index in range(deal.melds.size()):
		var meld := deal.melds[index]
		var view: MeldView = meld_views.get(meld.meld_id)
		var is_new := view == null
		if is_new:
			view = MeldView.new()
			meld_row.add_child(view)
			meld_views[meld.meld_id] = view
			view.meld_pressed.connect(_on_meld_pressed)
			view.meld_card_pressed.connect(_on_meld_card_pressed)
		elif view.get_index() != index:
			meld_row.move_child(view, index)
		var legal := deal.can_extend_meld(meld.meld_id, selected_cards)
		var drink_selection_enabled := drink_targeting_active and deal.current_drink_id == DrinkCatalog.NUOC_VOI and deal.state in [DealState.STATE_ACTIVE, DealState.STATE_FINAL_COMMIT_WINDOW] and not deal.nuoc_voi_used_phases.has(deal.current_phase)
		var removable_card_ids := {}
		if drink_selection_enabled:
			for table_card in meld.cards:
				if deal.can_use_nuoc_voi(meld.meld_id, table_card):
					removable_card_ids[table_card.unique_id] = true
		view.set_meld(
			meld,
			meld.meld_id == selected_meld_id,
			legal,
			drink_selection_enabled,
			removable_card_ids,
			selected_drink_meld_card_id if selected_drink_meld_id == meld.meld_id else ""
		)
		if not is_new:
			continue
		view.modulate = Color(1, 1, 1, 0)
		view.scale = Vector2(0.94, 0.94)
		var tween := view.create_tween().set_parallel(true)
		tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tween.tween_property(view, "modulate", Color.WHITE, 0.18)
		tween.tween_property(view, "scale", Vector2.ONE, 0.2)


func _sync_piles() -> void:
	draw_count.text = tr("PILE_COUNT") % deal.deck.draw_pile.size()
	discard_count_label.text = tr("PILE_COUNT") % deal.deck.discard_pile.size()
	if deal.deck.discard_pile.is_empty():
		discard_texture.texture = load("res://cards/red_backing.png") as Texture2D
		discard_texture.modulate = Color(1, 1, 1, 0.12)
	else:
		discard_texture.texture = load(deal.deck.discard_pile[-1].texture_path()) as Texture2D
		discard_texture.modulate = Color.WHITE


func _sync_discard_history() -> void:
	for child in discard_history_row.get_children():
		discard_history_row.remove_child(child)
		child.queue_free()
	if deal.discard_history.is_empty():
		var empty := Label.new()
		empty.text = tr("HUD_NO_DISCARDS")
		empty.add_theme_font_size_override("font_size", 10)
		empty.add_theme_color_override("font_color", PresentationTheme.MUTED)
		discard_history_row.add_child(empty)
		return
	for phase_number in [1, 2]:
		var records := deal.discard_history_for_phase(phase_number)
		if records.is_empty():
			continue
		var phase_label := Label.new()
		phase_label.text = tr("HUD_PHASE_SHORT") % phase_number
		phase_label.custom_minimum_size = Vector2(20, 38)
		phase_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		phase_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		phase_label.add_theme_font_size_override("font_size", 10)
		phase_label.add_theme_color_override("font_color", PresentationTheme.GOLD)
		discard_history_row.add_child(phase_label)
		for record in records:
			discard_history_row.add_child(_build_discard_thumbnail(record))


func _build_discard_thumbnail(record: DiscardRecord) -> Control:
	var holder := Control.new()
	holder.custom_minimum_size = Vector2(27, 38)
	holder.tooltip_text = tr("HUD_DISCARD_TOOLTIP") % [record.phase, record.discard_number, record.card.short_label()]
	var texture := TextureRect.new()
	texture.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	texture.texture = load(record.card.texture_path()) as Texture2D
	texture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	texture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	texture.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	texture.mouse_filter = Control.MOUSE_FILTER_IGNORE
	holder.add_child(texture)
	var badge := Label.new()
	badge.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	badge.position = Vector2(-14, -13)
	badge.size = Vector2(14, 13)
	badge.text = str(record.discard_number)
	badge.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	badge.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	badge.add_theme_font_size_override("font_size", 8)
	badge.add_theme_color_override("font_color", Color.WHITE)
	badge.add_theme_stylebox_override("normal", PresentationTheme.panel_style(Color("#17120ff2"), PresentationTheme.GOLD, 1, 1, 1))
	badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	holder.add_child(badge)
	return holder


func _refresh_stats() -> void:
	earnings_value.text = VndWallet.format_vnd(VndWallet.points_to_vnd(deal.phase_earnings_points), true)
	wallet_value.text = VndWallet.format_vnd(displayed_wallet_vnd)
	if campaign_value != null:
		if campaign == null or campaign.current_day().is_empty():
			campaign_value.text = "—"
		else:
			campaign_value.text = "%s  •  %s" % [
				tr(String(campaign.current_day().get("name_key", ""))),
				VndWallet.format_vnd(campaign.daily_requirement()),
			]


func _refresh_actions() -> void:
	var selected := _selected_cards()
	if drink_button != null:
		drink_button.disabled = tutorial_active or interaction_locked or deal.current_drink_id == DrinkCatalog.NONE or (not drink_targeting_active and not deal.current_drink_has_charge())
	var card_window := deal.state in [DealState.STATE_ACTIVE, DealState.STATE_FINAL_COMMIT_WINDOW] and not interaction_locked
	var active_turn := deal.state == DealState.STATE_ACTIVE and not interaction_locked
	ha_button.disabled = not card_window or not deal.can_create_meld(selected)
	extend_button.disabled = not card_window or selected_meld_id < 0 or not deal.can_extend_meld(selected_meld_id, selected)
	discard_button.disabled = not active_turn or selected.size() != 1
	settle_button.disabled = deal.state != DealState.STATE_FINAL_COMMIT_WINDOW or interaction_locked
	hint_button.disabled = not card_window or deal.hand.is_empty()
	sort_button.disabled = not card_window or deal.hand.size() < 2
	if drink_targeting_active:
		ha_button.disabled = true
		extend_button.disabled = true
		discard_button.disabled = true
		settle_button.disabled = true
		hint_button.disabled = true
		sort_button.disabled = true
	if tutorial_active:
		ha_button.disabled = ha_button.disabled or tutorial_step != TUTORIAL_PLAY_RUN
		extend_button.disabled = extend_button.disabled or tutorial_step != TUTORIAL_EXTEND
		discard_button.disabled = discard_button.disabled or tutorial_step not in [TUTORIAL_DISCARD, TUTORIAL_FINAL_DISCARD]
		settle_button.disabled = true
		hint_button.disabled = true
		tutorial_exit_button.disabled = interaction_locked
	if interaction_locked:
		status_label.text = tr("STATUS_RESOLVING")
		status_label.add_theme_color_override("font_color", PresentationTheme.MUTED)
		return
	if drink_targeting_active:
		status_label.text = tr("STATUS_DRINK_TARGETING_SAM_DUA") % pending_drink_card_ids.size() if deal.current_drink_id == DrinkCatalog.SAM_DUA else tr("STATUS_DRINK_TARGETING_ONE")
		status_label.add_theme_color_override("font_color", CardActionOutline.DRINK_HIGHLIGHT)
		return
	if deal.state == DealState.STATE_PHASE_CHOICE:
		status_label.text = tr("STATUS_PHASE_CHOICE")
		return
	if deal.state == DealState.STATE_DEAL_OVER:
		status_label.text = tr("STATUS_DEAL_OVER")
		return
	if deal.state == DealState.STATE_FINAL_COMMIT_WINDOW and selected.is_empty():
		status_label.text = tr("STATUS_LAST_CALL")
		status_label.add_theme_color_override("font_color", PresentationTheme.GOLD)
		return
	if selected.is_empty():
		status_label.text = tr("STATUS_CHOOSE")
		status_label.add_theme_color_override("font_color", PresentationTheme.MUTED)
	elif deal.can_create_meld(selected):
		var kind := MeldRules.classify(selected)
		var points := HandAdvisor.estimate_new_meld_points(selected, deal.scoring, deal.current_phase, deal.phase_new_meld_count)
		status_label.text = tr("STATUS_VALID_MELD") % [
			tr("MELD_RUN") if kind == MeldRules.TYPE_RUN else tr("MELD_SET"),
			points,
			VndWallet.format_vnd(VndWallet.points_to_vnd(points), true),
		]
		status_label.add_theme_color_override("font_color", PresentationTheme.TEA)
	elif selected_meld_id >= 0 and deal.can_extend_meld(selected_meld_id, selected):
		var points := HandAdvisor.estimate_extension_points(
			deal.get_meld(selected_meld_id), selected, deal.scoring, deal.current_phase
		)
		status_label.text = tr("STATUS_VALID_EXTEND") % [
			selected_meld_id,
			points,
			VndWallet.format_vnd(VndWallet.points_to_vnd(points), true),
		]
		status_label.add_theme_color_override("font_color", PresentationTheme.GOLD)
	elif selected.size() == 1:
		status_label.text = tr("STATUS_ONE_SELECTED")
		status_label.add_theme_color_override("font_color", PresentationTheme.INK)
	else:
		status_label.text = tr("STATUS_INVALID_MELD")
		status_label.add_theme_color_override("font_color", PresentationTheme.RED)


func _input(event: InputEvent) -> void:
	if active_drag_payload == null:
		return
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		get_viewport().set_input_as_handled()
		_cancel_card_drag()
	elif event is InputEventMouseMotion:
		_update_card_drag(event.position)
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
		var drop_position: Vector2 = event.position
		get_viewport().set_input_as_handled()
		_finish_card_drag(drop_position)


func _on_card_drag_started(card: CardData, global_position: Vector2, source: PlayingCardView) -> void:
	if drink_targeting_active or interaction_locked or deal.state not in [DealState.STATE_ACTIVE, DealState.STATE_FINAL_COMMIT_WINDOW]:
		source.finish_drag_interaction()
		return
	var payload_cards: Array[CardData] = [card]
	if selected_card_ids.has(card.unique_id):
		payload_cards = _selected_cards()
	active_drag_payload = CARD_DRAG_PAYLOAD_SCRIPT.new(
		CARD_DRAG_PAYLOAD_SCRIPT.SOURCE_HAND,
		-1,
		card.unique_id,
		payload_cards
	)
	active_drag_source = source
	_build_card_drag_preview(active_drag_payload)
	_refresh_card_drag_targets(active_drag_payload)
	_update_card_drag(global_position)


func _update_card_drag(global_position: Vector2) -> void:
	if drag_preview == null or particle_layer == null:
		return
	drag_preview.position = _drag_layer_local_position(global_position) - CARD_SIZE * 0.5


func _finish_card_drag(global_position: Vector2) -> void:
	var payload = active_drag_payload
	var source := active_drag_source
	var target := _card_drop_target_at(global_position)
	_clear_card_drag_visuals()
	if source != null:
		source.finish_drag_interaction()
	_perform_card_drop(payload, target, global_position, source)


func _card_drop_target_at(global_position: Vector2) -> Dictionary:
	if discard_pile_visual != null and discard_pile_visual.get_global_rect().has_point(global_position):
		return {"kind": DROP_TARGET_DISCARD, "meld_id": -1}
	for meld in deal.melds:
		var meld_view := meld_views.get(meld.meld_id) as MeldView
		if meld_view != null and meld_view.get_global_rect().has_point(global_position):
			return {"kind": DROP_TARGET_MELD, "meld_id": meld.meld_id}
	if hand_layer != null and hand_layer.get_global_rect().grow(28.0).has_point(global_position):
		return {"kind": DROP_TARGET_HAND, "meld_id": -1}
	if table_surface != null and table_surface.get_global_rect().has_point(global_position):
		if draw_pile_visual == null or not draw_pile_visual.get_global_rect().has_point(global_position):
			return {"kind": DROP_TARGET_TABLE, "meld_id": -1}
	return {"kind": DROP_TARGET_NONE, "meld_id": -1}


func _card_drag_action(payload, target: Dictionary) -> StringName:
	if payload == null:
		return DRAG_ACTION_NONE
	var target_kind: StringName = target.get("kind", DROP_TARGET_NONE)
	if payload.source_zone == CARD_DRAG_PAYLOAD_SCRIPT.SOURCE_HAND:
		match target_kind:
			DROP_TARGET_HAND:
				return DRAG_ACTION_REORDER
			DROP_TARGET_TABLE:
				return DRAG_ACTION_CREATE_MELD
			DROP_TARGET_MELD:
				return DRAG_ACTION_EXTEND_MELD
			DROP_TARGET_DISCARD:
				return DRAG_ACTION_DISCARD
	return DRAG_ACTION_NONE


func _cards_for_drop_target(payload, target: Dictionary) -> Array[CardData]:
	var cards: Array[CardData] = []
	if payload == null:
		return cards
	var anchor := payload.anchor_card() as CardData
	var action := _card_drag_action(payload, target)
	match action:
		DRAG_ACTION_REORDER:
			if not tutorial_active and anchor != null:
				cards.append(anchor)
		DRAG_ACTION_DISCARD:
			if deal.state == DealState.STATE_ACTIVE and anchor != null and deal.hand.has(anchor):
				if not tutorial_active or tutorial_step in [TUTORIAL_DISCARD, TUTORIAL_FINAL_DISCARD]:
					cards.append(anchor)
		DRAG_ACTION_CREATE_MELD:
			if (not tutorial_active or tutorial_step == TUTORIAL_PLAY_RUN) and deal.can_create_meld(payload.cards):
				cards.append_array(payload.cards)
		DRAG_ACTION_EXTEND_MELD:
			var meld_id := int(target.get("meld_id", -1))
			if tutorial_active and tutorial_step != TUTORIAL_EXTEND:
				return cards
			if deal.can_extend_meld(meld_id, payload.cards):
				cards.append_array(payload.cards)
			elif anchor != null and deal.can_extend_meld(meld_id, [anchor] as Array[CardData]):
				cards.append(anchor)
	return cards


func _perform_card_drop(payload, target: Dictionary, global_position: Vector2, source: PlayingCardView) -> void:
	if payload == null or interaction_locked:
		_layout_hand(true)
		return
	var target_kind: StringName = target.get("kind", DROP_TARGET_NONE)
	if target_kind == DROP_TARGET_NONE:
		_layout_hand(true)
		return
	var action := _card_drag_action(payload, target)
	var drop_cards := _cards_for_drop_target(payload, target)
	if drop_cards.is_empty():
		if source != null:
			source.play_reject()
		_layout_hand(true)
		return
	match action:
		DRAG_ACTION_REORDER:
			_reorder_hand_card(drop_cards[0], global_position.x)
		DRAG_ACTION_CREATE_MELD:
			_apply_drag_selection(drop_cards, -1)
			_on_ha_pressed()
		DRAG_ACTION_EXTEND_MELD:
			_apply_drag_selection(drop_cards, int(target.get("meld_id", -1)))
			_on_extend_pressed()
		DRAG_ACTION_DISCARD:
			_apply_drag_selection(drop_cards, -1)
			_on_discard_pressed()


func _apply_drag_selection(cards: Array[CardData], meld_id: int) -> void:
	selected_card_ids.clear()
	for card in cards:
		selected_card_ids[card.unique_id] = true
	selected_meld_id = meld_id
	_layout_hand(true)
	_sync_melds()
	_sync_music_reactive_cards()
	_refresh_actions()


func _reorder_hand_card(card: CardData, global_x: float) -> bool:
	if card == null or not deal.hand.has(card):
		return false
	var reordered: Array[CardData] = []
	var insertion_index := 0
	for existing_card in deal.hand:
		if existing_card == card:
			continue
		var existing_view := hand_views.get(existing_card.unique_id) as PlayingCardView
		if existing_view != null and global_x > existing_view.get_global_rect().get_center().x:
			insertion_index += 1
		reordered.append(existing_card)
	insertion_index = clampi(insertion_index, 0, reordered.size())
	reordered.insert(insertion_index, card)
	var changed := reordered != deal.hand
	if changed:
		deal.hand.clear()
		deal.hand.append_array(reordered)
	_layout_hand(true)
	_sync_music_reactive_cards()
	return changed


func _build_card_drag_preview(payload) -> void:
	if particle_layer == null:
		return
	drag_preview = Control.new()
	drag_preview.name = "CardDragPreview"
	drag_preview.mouse_filter = Control.MOUSE_FILTER_IGNORE
	drag_preview.z_index = 10
	particle_layer.add_child(drag_preview)
	var shown_count := mini(payload.cards.size(), 4)
	for index in range(shown_count):
		var card: CardData = payload.cards[index]
		var texture := TextureRect.new()
		texture.position = Vector2(index * 9.0, -index * 4.0)
		texture.size = CARD_SIZE
		texture.texture = load(card.texture_path()) as Texture2D
		texture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		texture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		texture.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		texture.mouse_filter = Control.MOUSE_FILTER_IGNORE
		texture.modulate = Color(1, 1, 1, 0.9)
		drag_preview.add_child(texture)
	if payload.cards.size() > 1:
		var count_badge := Label.new()
		count_badge.position = Vector2(CARD_SIZE.x - 8, -12)
		count_badge.size = Vector2(30, 24)
		count_badge.text = "×%d" % payload.cards.size()
		count_badge.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		count_badge.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		count_badge.add_theme_font_size_override("font_size", 12)
		count_badge.add_theme_color_override("font_color", Color.WHITE)
		count_badge.add_theme_stylebox_override("normal", PresentationTheme.panel_style(Color("#17120ff2"), PresentationTheme.TEA, 2, 2, 2))
		count_badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
		drag_preview.add_child(count_badge)


func _refresh_card_drag_targets(payload) -> void:
	_clear_card_drag_target_overlays()
	if particle_layer == null:
		return
	var table_target := {"kind": DROP_TARGET_TABLE, "meld_id": -1}
	if not _cards_for_drop_target(payload, table_target).is_empty():
		_add_card_drag_target_overlay(table_surface.get_global_rect(), PresentationTheme.TEA)
	if not tutorial_active:
		_add_card_drag_target_overlay(hand_layer.get_global_rect().grow(18.0), Color("#70a7df"))
	var discard_target := {"kind": DROP_TARGET_DISCARD, "meld_id": -1}
	if not _cards_for_drop_target(payload, discard_target).is_empty():
		_add_card_drag_target_overlay(discard_pile_visual.get_global_rect(), PresentationTheme.RED)
	for meld in deal.melds:
		var target := {"kind": DROP_TARGET_MELD, "meld_id": meld.meld_id}
		if _cards_for_drop_target(payload, target).is_empty():
			continue
		var meld_view := meld_views.get(meld.meld_id) as MeldView
		if meld_view != null:
			_add_card_drag_target_overlay(meld_view.get_global_rect(), PresentationTheme.GOLD)


func _add_card_drag_target_overlay(global_rect: Rect2, color: Color) -> void:
	var overlay := Panel.new()
	overlay.name = "CardDropTarget"
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.position = _drag_layer_local_position(global_rect.position)
	overlay.size = _drag_layer_local_position(global_rect.end) - overlay.position
	var fill := color
	fill.a = 0.13
	var border := color
	border.a = 0.9
	overlay.add_theme_stylebox_override("panel", PresentationTheme.panel_style(fill, border, 3, 3, 5))
	particle_layer.add_child(overlay)
	drag_target_overlays.append(overlay)


func _drag_layer_local_position(global_position: Vector2) -> Vector2:
	return particle_layer.get_global_transform_with_canvas().affine_inverse() * global_position


func _clear_card_drag_target_overlays() -> void:
	for overlay in drag_target_overlays:
		if is_instance_valid(overlay):
			overlay.queue_free()
	drag_target_overlays.clear()


func _clear_card_drag_visuals() -> void:
	_clear_card_drag_target_overlays()
	if drag_preview != null:
		drag_preview.queue_free()
	drag_preview = null
	active_drag_payload = null
	active_drag_source = null


func _cancel_card_drag() -> void:
	var source := active_drag_source
	_clear_card_drag_visuals()
	if source != null and is_instance_valid(source):
		source.finish_drag_interaction()
	_layout_hand(true)


func _on_card_pressed(card: CardData) -> void:
	if interaction_locked or deal.state not in [DealState.STATE_ACTIVE, DealState.STATE_FINAL_COMMIT_WINDOW]:
		return
	if drink_targeting_active:
		_on_drink_hand_card_targeted(card)
		return
	if tutorial_active and not _tutorial_card_press_allowed(card):
		var rejected_view := hand_views.get(card.unique_id) as PlayingCardView
		if rejected_view != null:
			rejected_view.play_reject()
		_show_banner(tr("TUTORIAL_FOLLOW_STEP"))
		return
	if selected_card_ids.has(card.unique_id):
		selected_card_ids.erase(card.unique_id)
	else:
		selected_card_ids[card.unique_id] = true
	selected_drink_meld_id = -1
	selected_drink_meld_card_id = ""
	_layout_hand(true)
	_sync_melds()
	_sync_music_reactive_cards()
	_refresh_stats()
	_refresh_actions()
	_advance_tutorial_after_card_selection()


func _tutorial_card_press_allowed(card: CardData) -> bool:
	match tutorial_step:
		TUTORIAL_SELECT_RUN:
			return StringName(card.unique_id) in TUTORIAL_RUN_IDS
		TUTORIAL_SELECT_DISCARD:
			return StringName(card.unique_id) == TUTORIAL_FIRST_DISCARD_ID
		TUTORIAL_SELECT_EXTEND:
			return StringName(card.unique_id) == TUTORIAL_EXTENSION_ID
		TUTORIAL_SELECT_FINAL_DISCARD:
			return StringName(card.unique_id) == TUTORIAL_FINAL_DISCARD_ID
		_:
			return false


func _advance_tutorial_after_card_selection() -> void:
	if not tutorial_active:
		return
	if tutorial_step == TUTORIAL_SELECT_RUN:
		for card_id in TUTORIAL_RUN_IDS:
			if not selected_card_ids.has(String(card_id)):
				return
		_set_tutorial_step(TUTORIAL_PLAY_RUN)
	elif tutorial_step == TUTORIAL_SELECT_DISCARD and selected_card_ids.has(String(TUTORIAL_FIRST_DISCARD_ID)):
		_set_tutorial_step(TUTORIAL_DISCARD)
	elif tutorial_step == TUTORIAL_SELECT_EXTEND and selected_card_ids.has(String(TUTORIAL_EXTENSION_ID)):
		_set_tutorial_step(TUTORIAL_SELECT_MELD)
	elif tutorial_step == TUTORIAL_SELECT_FINAL_DISCARD and selected_card_ids.has(String(TUTORIAL_FINAL_DISCARD_ID)):
		_set_tutorial_step(TUTORIAL_FINAL_DISCARD)


func _on_meld_pressed(meld_id: int) -> void:
	if interaction_locked or deal.state not in [DealState.STATE_ACTIVE, DealState.STATE_FINAL_COMMIT_WINDOW]:
		return
	if drink_targeting_active:
		return
	if tutorial_active and (tutorial_step != TUTORIAL_SELECT_MELD or meld_id != tutorial_meld_id):
		_show_banner(tr("TUTORIAL_FOLLOW_STEP"))
		return
	selected_meld_id = -1 if selected_meld_id == meld_id else meld_id
	selected_drink_meld_id = -1
	selected_drink_meld_card_id = ""
	_sync_melds()
	_sync_music_reactive_cards()
	_refresh_actions()
	if tutorial_active and tutorial_step == TUTORIAL_SELECT_MELD and selected_meld_id == tutorial_meld_id:
		_set_tutorial_step(TUTORIAL_EXTEND)


func _on_meld_card_pressed(meld_id: int, card: CardData) -> void:
	if interaction_locked or not drink_targeting_active or deal.current_drink_id != DrinkCatalog.NUOC_VOI:
		return
	if deal.state not in [DealState.STATE_ACTIVE, DealState.STATE_FINAL_COMMIT_WINDOW]:
		return
	if not deal.can_use_nuoc_voi(meld_id, card):
		_show_banner(tr("DRINK_NUOC_VOI_CARD_INVALID"))
		return
	selected_drink_meld_id = meld_id
	selected_drink_meld_card_id = card.unique_id
	_sync_melds()
	_refresh_actions()
	_resolve_nuoc_voi_target(meld_id, card)


func _on_drink_pressed() -> void:
	if tutorial_active or interaction_locked:
		return
	if drink_targeting_active:
		if deal.current_drink_id == DrinkCatalog.SAM_DUA:
			var preserved := _pending_drink_cards()
			if preserved.is_empty():
				_cancel_drink_targeting()
				return
			_finish_drink_use(deal.select_sam_dua_preserves(preserved))
		else:
			_cancel_drink_targeting()
		return
	if not deal.current_drink_has_charge():
		_reject_action(tr("DRINK_NO_CHARGE"))
		return
	match deal.current_drink_id:
		DrinkCatalog.TRA_DA:
			if deal.deck.discard_pile.is_empty():
				_reject_action(tr("DRINK_TRA_DA_NO_DISCARD"))
				return
		DrinkCatalog.NHAN_TRAN:
			if deal.hand.size() <= 1:
				_reject_action(tr("DRINK_NHAN_TRAN_NEEDS_DISCARD"))
				return
		DrinkCatalog.NUOC_VOI:
			if not _has_nuoc_voi_target():
				_reject_action(tr("DRINK_NUOC_VOI_NO_TARGET"))
				return
		DrinkCatalog.SAM_DUA:
			if deal.current_phase != 1 or deal.state != DealState.STATE_FINAL_COMMIT_WINDOW:
				_reject_action(tr("DRINK_SAM_DUA_WRONG_TIME"))
				return
		_:
			_reject_action(tr("DRINK_NO_BASIC_EFFECT"))
			return
	drink_targeting_active = true
	pending_drink_card_ids.clear()
	selected_card_ids.clear()
	selected_meld_id = -1
	selected_drink_meld_id = -1
	selected_drink_meld_card_id = ""
	_sync_all()
	_show_banner(tr("BANNER_DRINK_TARGET_SAM_DUA") if deal.current_drink_id == DrinkCatalog.SAM_DUA else tr("BANNER_DRINK_TARGET_ONE"))


func _on_drink_hand_card_targeted(card: CardData) -> void:
	if deal.current_drink_id == DrinkCatalog.SAM_DUA:
		if pending_drink_card_ids.has(card.unique_id):
			pending_drink_card_ids.erase(card.unique_id)
		elif pending_drink_card_ids.size() < 2:
			pending_drink_card_ids[card.unique_id] = true
		else:
			var rejected_view := hand_views.get(card.unique_id) as PlayingCardView
			if rejected_view != null:
				rejected_view.play_reject()
			_show_banner(tr("BANNER_DRINK_SAM_DUA_LIMIT"))
			return
		_sync_card_action_outlines()
		_refresh_actions()
		return
	if deal.current_drink_id not in [DrinkCatalog.TRA_DA, DrinkCatalog.NHAN_TRAN]:
		return
	pending_drink_card_ids.clear()
	pending_drink_card_ids[card.unique_id] = true
	_sync_card_action_outlines()
	_resolve_hand_drink_target(card)


func _resolve_hand_drink_target(card: CardData) -> void:
	interaction_locked = true
	_refresh_actions()
	await _fly_cards([card] as Array[CardData], discard_texture.get_global_rect().get_center())
	var result: Dictionary = deal.use_tra_da(card) if deal.current_drink_id == DrinkCatalog.TRA_DA else deal.use_nhan_tran(card)
	_finish_drink_use(result)


func _resolve_nuoc_voi_target(meld_id: int, card: CardData) -> void:
	interaction_locked = true
	_refresh_actions()
	await get_tree().create_timer(0.16).timeout
	_finish_drink_use(deal.use_nuoc_voi(meld_id, card))


func _finish_drink_use(result: Dictionary) -> void:
	if not result.get("ok", false):
		interaction_locked = false
		_cancel_drink_targeting()
		_reject_action(result.get("message", tr("DRINK_USE_FAILED")))
		return
	drink_targeting_active = false
	pending_drink_card_ids.clear()
	selected_card_ids.clear()
	selected_drink_meld_id = -1
	selected_drink_meld_card_id = ""
	interaction_locked = false
	_sync_all(result)
	var banner_key: String = {
		DrinkCatalog.TRA_DA: "BANNER_DRINK_TRA_DA",
		DrinkCatalog.NHAN_TRAN: "BANNER_DRINK_NHAN_TRAN",
		DrinkCatalog.NUOC_VOI: "BANNER_DRINK_NUOC_VOI",
		DrinkCatalog.SAM_DUA: "BANNER_DRINK_SAM_DUA",
	}.get(deal.current_drink_id, "BANNER_DRINK_USED")
	if deal.current_drink_id == DrinkCatalog.SAM_DUA:
		_show_banner(tr(banner_key) % result.get("preserved", []).size())
	else:
		_show_banner(tr(banner_key))


func _cancel_drink_targeting() -> void:
	drink_targeting_active = false
	pending_drink_card_ids.clear()
	selected_drink_meld_id = -1
	selected_drink_meld_card_id = ""
	_sync_all()


func _pending_drink_cards() -> Array[CardData]:
	var cards: Array[CardData] = []
	for card in deal.hand:
		if pending_drink_card_ids.has(card.unique_id):
			cards.append(card)
	return cards


func _has_nuoc_voi_target() -> bool:
	for meld in deal.melds:
		for card in meld.cards:
			if deal.can_use_nuoc_voi(meld.meld_id, card):
				return true
	return false


func _drink_tooltip() -> String:
	var drink_name := tr(DrinkCatalog.display_name(deal.current_drink_id))
	var effect_key: String = {
		DrinkCatalog.TRA_DA: "DRINK_TRA_DA_TOOLTIP",
		DrinkCatalog.NHAN_TRAN: "DRINK_NHAN_TRAN_TOOLTIP",
		DrinkCatalog.NUOC_VOI: "DRINK_NUOC_VOI_TOOLTIP",
		DrinkCatalog.SAM_DUA: "DRINK_SAM_DUA_TOOLTIP",
	}.get(deal.current_drink_id, "DRINK_NO_BASIC_EFFECT")
	var status := ""
	if drink_targeting_active:
		status = "\n\n%s" % (tr("STATUS_DRINK_TARGETING_SAM_DUA") % pending_drink_card_ids.size() if deal.current_drink_id == DrinkCatalog.SAM_DUA else tr("STATUS_DRINK_TARGETING_ONE"))
	elif deal.current_drink_id == DrinkCatalog.TRA_DA and deal.tra_da_used_this_turn:
		status = "\n\n%s" % tr("DRINK_USED_THIS_TURN")
	elif deal.current_drink_id == DrinkCatalog.NHAN_TRAN and deal.nhan_tran_used_this_turn:
		status = "\n\n%s" % tr("DRINK_USED_THIS_TURN")
	elif deal.current_drink_id == DrinkCatalog.NUOC_VOI and deal.nuoc_voi_used_phases.has(deal.current_phase):
		status = "\n\n%s" % tr("DRINK_USED_THIS_PHASE")
	elif deal.current_drink_id == DrinkCatalog.SAM_DUA and deal.sam_dua_used:
		status = "\n\n%s" % (tr("DRINK_SAM_DUA_SELECTED") % deal.sam_dua_preserved_cards.size())
	return "%s\n\n%s%s" % [tr("HUD_CURRENT_DRINK") % drink_name, tr(effect_key), status]


func _on_ha_pressed() -> void:
	if ha_button.disabled:
		return
	var selected := _selected_cards()
	interaction_locked = true
	_refresh_actions()
	await _fly_cards(selected, meld_scroll.get_global_rect().get_center())
	var result := deal.create_meld(selected)
	if not result.get("ok", false):
		_reject_action(result.get("message", "Hạ failed."))
		return
	selected_card_ids.clear()
	selected_meld_id = result["meld_id"]
	if tutorial_active:
		tutorial_meld_id = selected_meld_id
	_sync_all(result)
	if tutorial_active:
		_set_tutorial_step(TUTORIAL_MELD_SCORE)
	await _show_scoring(result["context"])
	interaction_locked = false
	if tutorial_active:
		_set_tutorial_step(TUTORIAL_SELECT_DISCARD)
	else:
		_refresh_actions()


func _on_extend_pressed() -> void:
	if extend_button.disabled:
		return
	var selected := _selected_cards()
	interaction_locked = true
	_refresh_actions()
	await _fly_cards(selected, meld_scroll.get_global_rect().get_center())
	var result := deal.extend_meld(selected_meld_id, selected)
	if not result.get("ok", false):
		_reject_action(result.get("message", "Extension failed."))
		return
	selected_card_ids.clear()
	_sync_all(result)
	if tutorial_active:
		_set_tutorial_step(TUTORIAL_EXTEND_SCORE)
	await _show_scoring(result["context"])
	interaction_locked = false
	if tutorial_active:
		selected_meld_id = -1
		_set_tutorial_step(TUTORIAL_SELECT_FINAL_DISCARD)
	else:
		_refresh_actions()


func _on_discard_pressed() -> void:
	if discard_button.disabled:
		return
	var completed_tutorial_step := tutorial_step
	var selected := _selected_cards()
	var card := selected[0]
	interaction_locked = true
	_refresh_actions()
	await _fly_cards(selected, discard_texture.get_global_rect().get_center())
	var result := deal.discard_card(card)
	if not result.get("ok", false):
		_reject_action(result.get("message", "Discard failed."))
		return
	selected_card_ids.clear()
	_sync_all(result)
	if result.get("final_commit_window", false):
		_show_banner(tr("BANNER_LAST_CALL"))
		interaction_locked = false
		_refresh_actions()
	else:
		var drawn: Array[CardData] = _cards_from_result(result)
		_show_banner(tr("BANNER_DRAW") % [drawn.size(), deal.discard_count, DealState.DISCARDS_PER_PHASE])
		interaction_locked = false
		_refresh_actions()
	if tutorial_active and completed_tutorial_step == TUTORIAL_DISCARD:
		selected_meld_id = -1
		_set_tutorial_step(TUTORIAL_SELECT_EXTEND)
	elif tutorial_active and completed_tutorial_step == TUTORIAL_FINAL_DISCARD:
		_set_tutorial_step(TUTORIAL_MOM)


func _on_settle_pressed() -> void:
	if settle_button.disabled:
		return
	interaction_locked = true
	_refresh_actions()
	var result := deal.settle_phase()
	if not result.get("ok", false):
		_reject_action(result.get("message", "Settlement failed."))
		return
	selected_card_ids.clear()
	selected_meld_id = -1
	_sync_all(result)
	var resolution: Dictionary = result["phase_resolution"]
	await _show_phase_resolution(resolution)
	if resolution["phase"] == 1:
		_show_phase_choice(resolution)
	else:
		_show_deal_over(resolution)


func _on_sort_pressed() -> void:
	if sort_button.disabled:
		return
	sort_mode = (sort_mode + 1) % 2
	if sort_mode == 0:
		deal.hand.sort_custom(func(left: CardData, right: CardData) -> bool:
			if left.rank_index == right.rank_index:
				return DeckManager.SUITS.find(left.suit) < DeckManager.SUITS.find(right.suit)
			return left.rank_index < right.rank_index
		)
		sort_button.text = tr("ACTION_SORT_RANK")
	else:
		deal.hand.sort_custom(func(left: CardData, right: CardData) -> bool:
			var left_suit := DeckManager.SUITS.find(left.suit)
			var right_suit := DeckManager.SUITS.find(right.suit)
			if left_suit == right_suit:
				return left.rank_index < right.rank_index
			return left_suit < right_suit
		)
		sort_button.text = tr("ACTION_SORT_SUIT")
	_layout_hand(true)
	_sync_music_reactive_cards()


func _on_hint_pressed() -> void:
	if hint_button.disabled:
		return
	selected_card_ids.clear()
	selected_meld_id = -1
	var recommendation := HandAdvisor.recommend(
		deal.hand,
		deal.melds,
		deal.scoring,
		deal.current_phase,
		deal.phase_new_meld_count,
		deal.state == DealState.STATE_ACTIVE
	)
	if recommendation["action"] == HandAdvisor.ACTION_NONE:
		_show_banner(tr("BANNER_NO_HINT"))
	else:
		for card: CardData in recommendation["cards"]:
			selected_card_ids[card.unique_id] = true
		if recommendation["action"] == HandAdvisor.ACTION_EXTENSION:
			selected_meld_id = recommendation["meld_id"]
		var verb := tr("MELD_ACTION") if recommendation["action"] == HandAdvisor.ACTION_NEW_MELD else tr("EXTEND_ACTION")
		_show_banner(tr("BANNER_HINT") % [verb, recommendation["estimated_points"]])
	_layout_hand(true)
	_sync_melds()
	_sync_music_reactive_cards()
	_refresh_stats()
	_refresh_actions()


func _show_scoring(context: ScoringContext) -> void:
	var kind := tr("MELD_RUN") if context.meld_type == MeldRules.TYPE_RUN else tr("MELD_SET")
	if context.action_type == "new_meld":
		score_title.text = tr("SCORE_MELD_SUCCESS") % [kind, context.phase]
		score_line_a.text = "%s   →   %d" % [context.value_equation(), context.card_value_sum]
		score_line_b.text = tr("SCORE_POINTS_EQUATION") % [context.base_score, context.local_mult, context.theoretical_score]
		score_payout.text = "%d × ₫1.000   →   %s" % [context.final_points, VndWallet.format_vnd(VndWallet.points_to_vnd(context.final_points), true)]
	else:
		score_title.text = tr("SCORE_EXTEND_SUCCESS") % [kind, context.phase]
		score_line_a.text = tr("SCORE_OLD_NEW") % [context.old_meld_score, context.theoretical_score]
		score_line_b.text = tr("SCORE_DELTA") % [context.theoretical_score, context.old_meld_score, context.final_points]
		score_payout.text = tr("SCORE_INCREASE") % VndWallet.format_vnd(VndWallet.points_to_vnd(context.final_points), true)
	await _play_score_panel(deal.wallet.balance_vnd, context.final_points >= 0)


func _show_phase_resolution(resolution: Dictionary) -> void:
	var is_mom: bool = resolution["mom"]
	var phase_number: int = resolution["phase"]
	var resolved_mom: int = int(resolution.get("mom_strikes_resolved", 0))
	var mom_penalty_percent: int = int(resolution.get("mom_penalty_percent", 0))
	var mom_penalty_vnd: int = int(resolution.get("mom_penalty_vnd", 0))
	score_title.text = tr("SCORE_PHASE_RESULT") % phase_number
	if is_mom:
		score_line_a.text = tr("SCORE_MOM")
		score_line_a.add_theme_color_override("font_color", PresentationTheme.RED)
	else:
		score_line_a.text = tr("SCORE_SAFE") % resolution["new_phom_count"]
		score_line_a.add_theme_color_override("font_color", PresentationTheme.TEA)
	if phase_number == 2 and resolved_mom > 0:
		score_line_b.text = tr("SCORE_MOM_PENALTY") % [
			resolved_mom,
			mom_penalty_percent,
			VndWallet.format_vnd(mom_penalty_vnd),
		]
	elif phase_number == 2 and deal.mom_strikes_banked > 0:
		score_line_b.text = tr("SCORE_MOM_PROTECTED")
	elif is_mom:
		score_line_b.text = tr("SCORE_MOM_BANK") % deal.mom_strikes_banked
	else:
		score_line_b.text = tr("SCORE_GROSS") % [resolution["gross_after_u"], tr("SCORE_U_BONUS") if resolution["u"] else ""]
	var deadwood: int = resolution["deadwood_points"]
	score_payout.text = tr("SCORE_NET") % [resolution["net"], resolution["gross_after_u"], deadwood]
	await _play_score_panel(deal.wallet.balance_vnd, not is_mom and mom_penalty_vnd == 0)
	score_line_a.add_theme_color_override("font_color", PresentationTheme.INK)


func _play_score_panel(target_wallet: int, positive: bool) -> void:
	score_overlay.visible = true
	score_panel.scale = Vector2(0.84, 0.84)
	score_panel.modulate = Color(1, 1, 1, 0)
	for label in [score_line_a, score_line_b, score_payout]:
		label.modulate = Color(1, 1, 1, 0)
	var intro := create_tween().set_parallel(true)
	intro.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	intro.tween_property(score_panel, "scale", Vector2.ONE, 0.24)
	intro.tween_property(score_panel, "modulate", Color.WHITE, 0.14)
	await intro.finished
	await _reveal_score_label(score_line_a)
	await _reveal_score_label(score_line_b)
	await _reveal_score_label(score_payout)
	await _animate_wallet_to(target_wallet, 0.52)
	_spawn_money_float(target_wallet - displayed_wallet_vnd, positive)
	var result_hold := 1.2 if tutorial_active else 0.34
	await get_tree().create_timer(result_hold).timeout
	var outro := create_tween().set_parallel(true)
	outro.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	outro.tween_property(score_panel, "scale", Vector2(1.04, 1.04), 0.14)
	outro.tween_property(score_panel, "modulate", Color(1, 1, 1, 0), 0.14)
	await outro.finished
	score_overlay.visible = false


func _reveal_score_label(label: Label) -> void:
	label.position.x -= 13
	var target_x := label.position.x + 13
	var tween := create_tween().set_parallel(true)
	tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(label, "position:x", target_x, 0.16)
	tween.tween_property(label, "modulate", Color.WHITE, 0.12)
	await tween.finished
	await get_tree().create_timer(0.08).timeout


func _animate_wallet_to(target: int, duration: float) -> void:
	if displayed_wallet_vnd == target:
		_refresh_stats()
		return
	var tween := create_tween()
	tween.set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)
	tween.tween_method(_set_displayed_wallet, float(displayed_wallet_vnd), float(target), duration)
	await tween.finished
	_set_displayed_wallet(float(target))


func _set_displayed_wallet(value: float) -> void:
	displayed_wallet_vnd = int(round(value))
	wallet_value.text = VndWallet.format_vnd(displayed_wallet_vnd)


func _spawn_money_float(_delta_vnd: int, positive: bool) -> void:
	var label := Label.new()
	label.text = VndWallet.format_vnd(deal.wallet.balance_vnd)
	label.position = wallet_value.global_position - particle_layer.global_position + Vector2(0, 14)
	label.add_theme_font_size_override("font_size", 17)
	label.add_theme_color_override("font_color", PresentationTheme.TEA if positive else PresentationTheme.RED)
	particle_layer.add_child(label)
	var tween := create_tween().set_parallel(true)
	tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(label, "position:y", label.position.y - 42, 0.72)
	tween.tween_property(label, "modulate", Color(1, 1, 1, 0), 0.72).set_delay(0.16)
	tween.chain().tween_callback(label.queue_free)


func _show_phase_choice(resolution: Dictionary) -> void:
	interaction_locked = false
	modal_mode = "phase_choice"
	modal_kicker.text = tr("MODAL_PHASE1_KICKER") % (tr("MOM") if resolution["mom"] else tr("SAFE"))
	modal_title.text = tr("MODAL_KEEP_OR_REDRAW")
	if deal.current_drink_id == DrinkCatalog.SAM_DUA:
		modal_body.text = tr("MODAL_PHASE1_BODY_SAM_DUA") % [deal.hand.size(), deal.sam_dua_preserved_cards.size()]
	else:
		modal_body.text = tr("MODAL_PHASE1_BODY") % deal.hand.size()
	modal_detail.text = tr("MODAL_PHASE1_DETAIL")
	modal_primary.text = tr("MODAL_KEEP") % deal.hand.size()
	modal_secondary.text = tr("MODAL_REDRAW_SAM_DUA") % deal.sam_dua_preserved_cards.size() if deal.current_drink_id == DrinkCatalog.SAM_DUA else tr("MODAL_REDRAW")
	modal_secondary.visible = true
	_show_modal()
	_refresh_actions()


func _show_deal_over(resolution: Dictionary) -> void:
	interaction_locked = false
	modal_mode = "campaign_deal_over" if campaign != null and CampaignManager.DEAL_PHASE_TO_PERIOD.has(campaign.current_phase) else "deal_over"
	modal_kicker.text = tr("MODAL_DEAL_KICKER") % (tr("MOM") if resolution["mom"] else tr("SAFE"))
	modal_title.text = VndWallet.format_vnd(deal.wallet.balance_vnd)
	modal_body.text = tr("MODAL_DEAL_BODY") % deal.melds.size()
	modal_detail.text = tr("MODAL_DEAL_DETAIL") % [
		deal.mom_strikes_banked,
		deal.mom_strikes_resolved,
		deal.mom_penalty_percent,
		VndWallet.format_vnd(deal.mom_penalty_vnd),
		resolution["deadwood_points"],
	]
	modal_primary.text = tr("EVENT_CONTINUE") if modal_mode == "campaign_deal_over" else tr("MODAL_NEW_DEAL")
	modal_secondary.visible = false
	_show_modal()
	_refresh_actions()


func _show_modal() -> void:
	if discard_archive_overlay.visible:
		_hide_discard_archive()
	_set_hand_interaction_enabled(false)
	modal_overlay.visible = true
	modal_overlay.modulate = Color(1, 1, 1, 0)
	var panel: Panel = modal_title.get_parent().get_parent()
	panel.scale = Vector2(0.95, 0.95)
	panel.pivot_offset = panel.size * 0.5
	var tween := create_tween().set_parallel(true)
	tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(modal_overlay, "modulate", Color.WHITE, 0.18)
	tween.tween_property(panel, "scale", Vector2.ONE, 0.22)


func _on_modal_primary_pressed() -> void:
	if modal_mode == "phase_choice":
		_begin_phase_two(true)
	elif modal_mode == "campaign_deal_over":
		interaction_locked = true
		modal_overlay.visible = false
		campaign.complete_deal(deal.last_phase_resolution)
	elif modal_mode == "deal_over":
		_start_new_deal()


func _on_modal_secondary_pressed() -> void:
	if modal_mode == "phase_choice":
		_begin_phase_two(false)


func _begin_phase_two(keep_hand: bool) -> void:
	if interaction_locked:
		return
	interaction_locked = true
	modal_overlay.visible = false
	_set_hand_interaction_enabled(true)
	if not keep_hand:
		var cards_to_dump: Array[CardData] = []
		for card in deal.hand:
			if not deal.sam_dua_preserved_cards.has(card):
				cards_to_dump.append(card)
		await _fly_cards(cards_to_dump, discard_texture.get_global_rect().get_center())
	var result := deal.choose_phase_two(keep_hand)
	if not result.get("ok", false):
		_reject_action(result.get("message", "Phase transition failed."))
		return
	selected_card_ids.clear()
	selected_meld_id = -1
	_sync_all(result)
	if not keep_hand and not result.get("preserved", []).is_empty():
		_show_banner(tr("BANNER_PHASE2_SAM_DUA") % result["preserved"].size())
	else:
		_show_banner(tr("BANNER_PHASE2") % (tr("KEEP_HAND") if keep_hand else tr("REDRAW_HAND")))
	interaction_locked = false
	_refresh_actions()


func _start_campaign() -> void:
	if tutorial_active:
		_deactivate_tutorial(true)
	interaction_locked = true
	modal_overlay.visible = false
	campaign_overlay.visible = false
	selected_card_ids.clear()
	selected_meld_id = -1
	displayed_wallet_vnd = 0
	campaign.start_campaign(true)
	_refresh_stats()


func _on_campaign_event_started(event: EventInstance) -> void:
	_show_campaign_event(event)


func _on_campaign_deal_requested(day: Dictionary, period: String, drink_id: String) -> void:
	current_campaign_event = null
	campaign_overlay.visible = false
	interaction_locked = true
	modal_overlay.visible = false
	_set_hand_interaction_enabled(true)
	selected_card_ids.clear()
	selected_meld_id = -1
	var drink_result := deal.set_current_drink(drink_id)
	if not drink_result.get("ok", false):
		deal.set_current_drink(DrinkCatalog.TRA_DA)
	var result := deal.start_deal(-1, false)
	displayed_wallet_vnd = deal.wallet.balance_vnd
	_sync_all(result, true)
	interaction_locked = false
	_set_hand_interaction_enabled(true)
	_refresh_actions()
	_show_banner(tr("CAMPAIGN_DEAL_BANNER") % [
		tr(String(day.get("name_key", ""))),
		tr(_campaign_period_key(period)),
	])


func _on_campaign_drink_pressed(event_slot: int, interaction_id: String, drink_id: String) -> void:
	var result := drink_manager.select_for_event(event_slot, drink_id)
	if not result.get("ok", false):
		_show_banner(tr("EVENT_NOT_ENOUGH_VND"))
		return
	event_manager.complete_interaction(interaction_id)
	displayed_wallet_vnd = deal.wallet.balance_vnd
	_refresh_stats()
	if current_campaign_event != null:
		_show_campaign_event(current_campaign_event)


func _on_campaign_interaction_pressed(interaction_id: String) -> void:
	event_manager.complete_interaction(interaction_id)
	if current_campaign_event != null:
		_show_campaign_event(current_campaign_event)


func _on_campaign_continue_pressed() -> void:
	if campaign.current_phase in [CampaignManager.CampaignPhase.CAMPAIGN_VICTORY, CampaignManager.CampaignPhase.CAMPAIGN_FAILURE]:
		_start_campaign()
		return
	if current_campaign_event == null or not current_campaign_event.can_exit:
		return
	campaign_overlay.visible = false
	current_campaign_event = null
	campaign.complete_current_event()


func _on_campaign_requirement_passed(day: Dictionary) -> void:
	_show_banner(tr("CAMPAIGN_REQUIREMENT_PASSED") % [
		tr(String(day.get("name_key", ""))),
		VndWallet.format_vnd(int(day.get("required_vnd", 0))),
	])


func _on_campaign_won() -> void:
	_show_campaign_outcome(true)


func _on_campaign_lost() -> void:
	_show_campaign_outcome(false)


func _show_campaign_outcome(won: bool) -> void:
	current_campaign_event = null
	interaction_locked = true
	_set_hand_interaction_enabled(false)
	modal_overlay.visible = false
	campaign_overlay.visible = true
	campaign_event_kicker.text = tr("CAMPAIGN_COMPLETE" if won else "CAMPAIGN_ENDED")
	campaign_event_title.text = tr("CAMPAIGN_VICTORY" if won else "CAMPAIGN_FAILURE")
	campaign_event_wallet.text = tr("CAMPAIGN_FINAL_WALLET") % VndWallet.format_vnd(deal.wallet.balance_vnd)
	_clear_campaign_participants()
	var result_label := Label.new()
	result_label.text = tr("CAMPAIGN_VICTORY_BODY") if won else tr("CAMPAIGN_FAILURE_BODY") % VndWallet.format_vnd(campaign.daily_requirement())
	result_label.custom_minimum_size.y = 190
	result_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	result_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	result_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	result_label.add_theme_font_size_override("font_size", 17)
	result_label.add_theme_color_override("font_color", PresentationTheme.TEA if won else PresentationTheme.RED)
	campaign_participants.add_child(result_label)
	campaign_continue_button.text = tr("CAMPAIGN_NEW_RUN")
	campaign_continue_button.disabled = false
	campaign_continue_button.call_deferred("grab_focus")
	_refresh_stats()


func _campaign_period_key(period: String) -> String:
	match period:
		"morning":
			return "PERIOD_MORNING"
		"noon":
			return "PERIOD_NOON"
		"afternoon":
			return "PERIOD_AFTERNOON"
		"evening":
			return "PERIOD_EVENING"
	return ""


func _start_new_deal() -> void:
	if interaction_locked:
		return
	if tutorial_active:
		_deactivate_tutorial(true)
	interaction_locked = true
	modal_overlay.visible = false
	_set_hand_interaction_enabled(true)
	selected_card_ids.clear()
	selected_meld_id = -1
	var result := deal.start_deal(-1, false)
	displayed_wallet_vnd = deal.wallet.balance_vnd
	_sync_all(result, true)
	_show_banner(tr("BANNER_NEW_DEAL_WALLET"))
	interaction_locked = false
	_refresh_actions()


func _fly_cards(cards: Array[CardData], target_global: Vector2) -> void:
	if cards.is_empty():
		return
	var target_local := target_global - particle_layer.global_position
	var tween := create_tween().set_parallel(true)
	for index in range(cards.size()):
		var card := cards[index]
		if not hand_views.has(card.unique_id):
			continue
		var source: PlayingCardView = hand_views[card.unique_id]
		var ghost := TextureRect.new()
		ghost.texture = load(card.texture_path()) as Texture2D
		ghost.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		ghost.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		ghost.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		ghost.position = source.global_position - particle_layer.global_position
		ghost.size = CARD_SIZE
		ghost.pivot_offset = CARD_SIZE * 0.5
		ghost.rotation = source.rotation
		particle_layer.add_child(ghost)
		var delay := index * 0.035
		tween.tween_property(ghost, "position", target_local - CARD_SIZE * 0.36 + Vector2(index * 5, 0), 0.25).set_delay(delay).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		tween.tween_property(ghost, "scale", Vector2(0.72, 0.72), 0.25).set_delay(delay)
		tween.tween_property(ghost, "rotation", 0.02 * (index - cards.size() * 0.5), 0.25).set_delay(delay)
		tween.tween_property(ghost, "modulate", Color(1, 1, 1, 0), 0.09).set_delay(delay + 0.2)
		tween.tween_callback(ghost.queue_free).set_delay(delay + 0.3)
	await tween.finished


func _show_banner(message: String) -> void:
	banner_label.text = message
	banner_panel.position.y = 94
	banner_panel.modulate = Color(1, 1, 1, 0)
	var tween := create_tween()
	tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(banner_panel, "modulate", Color.WHITE, 0.14)
	tween.parallel().tween_property(banner_panel, "position:y", 104, 0.2)
	tween.tween_interval(1.25)
	tween.set_ease(Tween.EASE_IN)
	tween.tween_property(banner_panel, "modulate", Color(1, 1, 1, 0), 0.22)


func _reject_action(message: String) -> void:
	interaction_locked = false
	status_label.text = message.to_upper()
	status_label.add_theme_color_override("font_color", PresentationTheme.RED)
	for card in _selected_cards():
		if hand_views.has(card.unique_id):
			hand_views[card.unique_id].play_reject()
	_refresh_actions()


func _selected_cards() -> Array[CardData]:
	var selected: Array[CardData] = []
	for card in deal.hand:
		if selected_card_ids.has(card.unique_id):
			selected.append(card)
	return selected


func _set_hand_interaction_enabled(enabled: bool) -> void:
	for value in hand_views.values():
		var view := value as PlayingCardView
		if view != null:
			view.set_interaction_enabled(enabled)
	if not enabled and active_drag_payload != null:
		_cancel_card_drag()


func _cards_from_result(result: Dictionary) -> Array[CardData]:
	var cards: Array[CardData] = []
	for key in ["resting_cards", "drawn"]:
		if result.has(key):
			for value in result[key]:
				if value is CardData:
					cards.append(value)
	return cards


func _on_viewport_size_changed() -> void:
	_park_game_layer()
	_layout_hand(false)


func _rewind_tutorial_selection() -> void:
	var rewind_step := tutorial_step
	match tutorial_step:
		TUTORIAL_PLAY_RUN:
			rewind_step = TUTORIAL_SELECT_RUN
		TUTORIAL_DISCARD:
			rewind_step = TUTORIAL_SELECT_DISCARD
		TUTORIAL_SELECT_MELD, TUTORIAL_EXTEND:
			rewind_step = TUTORIAL_SELECT_EXTEND
		TUTORIAL_FINAL_DISCARD:
			rewind_step = TUTORIAL_SELECT_FINAL_DISCARD
		TUTORIAL_SELECT_RUN, TUTORIAL_SELECT_DISCARD, TUTORIAL_SELECT_EXTEND, TUTORIAL_SELECT_FINAL_DISCARD:
			pass
		_:
			return
	selected_card_ids.clear()
	selected_meld_id = -1
	_sync_all()
	if rewind_step != tutorial_step:
		_set_tutorial_step(rewind_step)
	else:
		_refresh_tutorial_spotlight()


func _unhandled_key_input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed or event.echo:
		return
	if menu_layer.visible:
		if event.keycode == KEY_ESCAPE and menu_page != &"home":
			_show_menu_page(&"home")
		elif game_started and event.keycode == KEY_ESCAPE:
			_close_menu_to_game()
		elif menu_page == &"home" and not menu_transitioning and event.keycode in [KEY_ENTER, KEY_KP_ENTER, KEY_SPACE]:
			_on_play_pressed()
		return
	if discard_archive_overlay.visible:
		if event.keycode == KEY_ESCAPE:
			_hide_discard_archive()
		return
	if modal_overlay.visible:
		if modal_mode == "phase_choice" and event.keycode == KEY_K:
			_begin_phase_two(true)
		elif modal_mode == "phase_choice" and event.keycode == KEY_X:
			_begin_phase_two(false)
		elif modal_mode == "deal_over" and event.keycode == KEY_R:
			_start_new_deal()
		return
	if tutorial_active and event.keycode == KEY_ESCAPE:
		_rewind_tutorial_selection()
		return
	match event.keycode:
		KEY_H:
			if not ha_button.disabled:
				_on_ha_pressed()
		KEY_E:
			if not extend_button.disabled:
				_on_extend_pressed()
		KEY_D:
			if not discard_button.disabled:
				_on_discard_pressed()
		KEY_C:
			if not settle_button.disabled:
				_on_settle_pressed()
		KEY_S:
			if not sort_button.disabled:
				_on_sort_pressed()
		KEY_G:
			if not hint_button.disabled:
				_on_hint_pressed()
		KEY_ESCAPE:
			if drink_targeting_active:
				_cancel_drink_targeting()
			else:
				selected_card_ids.clear()
				selected_meld_id = -1
				_sync_all()
