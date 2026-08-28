class_name MatchUI
extends Control

const CARD_SIZE := PlayingCardView.CARD_SIZE
const INITIAL_RELIC_SLOT_COUNT := 4
const MUSIC_BAND_COUNT := 4
const GAME_SETTINGS_SCRIPT := preload("res://scripts/settings/game_settings.gd")

var deal := DealState.new()
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
var play_button: Button
var menu_button: Button
var music_slider: HSlider
var sound_slider: HSlider
var music_settings_label: Label
var sound_settings_label: Label
var language_settings_label: Label
var music_value_label: Label
var sound_value_label: Label
var language_selector: OptionButton
var logo_segments: Array[Label] = []
var logo_bounce_tweens: Dictionary = {}
var reactive_hand_cards_by_band: Dictionary = {}
var reactive_meld_cards_by_band: Dictionary = {}
var music_controller: ReactiveMusicController
var relic_grid: GridContainer
var drink_name_label: Label

var earnings_value: Label
var wallet_value: Label
var header_caption_labels: Dictionary = {}
var draw_count: Label
var discard_count_label: Label
var pile_caption_labels: Dictionary = {}
var pile_archive_buttons: Dictionary = {}
var discard_texture: TextureRect
var status_label: Label
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
	_sync_all(result, true)
	_set_hand_interaction_enabled(false)
	_park_game_layer()


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
	column.custom_minimum_size = Vector2(760, 430)
	column.alignment = BoxContainer.ALIGNMENT_CENTER
	column.add_theme_constant_override("separation", 20)
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
		segment.custom_minimum_size.y = 94
		segment.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		segment.add_theme_font_size_override("font_size", 78)
		segment.add_theme_color_override("font_color", PresentationTheme.GOLD)
		segment.mouse_filter = Control.MOUSE_FILTER_IGNORE
		logo.add_child(segment)
		logo_segments.append(segment)

	_build_menu_settings(column)

	play_button = Button.new()
	play_button.name = "PlayButton"
	play_button.text = tr("MENU_NEW_GAME")
	play_button.custom_minimum_size = Vector2(280, 54)
	play_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	PresentationTheme.configure_button(play_button, "gold")
	play_button.add_theme_font_size_override("font_size", 18)
	play_button.pressed.connect(_on_play_pressed)
	column.add_child(play_button)
	call_deferred("_refresh_logo_pivots")


func _build_menu_settings(parent: VBoxContainer) -> void:
	var panel := PanelContainer.new()
	panel.name = "SettingsPanel"
	panel.custom_minimum_size = Vector2(520, 184)
	panel.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	panel.add_theme_stylebox_override("panel", PresentationTheme.panel_style(Color("#17120ff2"), Color("#8d5b30"), 2, 8, 6))
	parent.add_child(panel)
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 20)
	margin.add_theme_constant_override("margin_top", 16)
	margin.add_theme_constant_override("margin_right", 20)
	margin.add_theme_constant_override("margin_bottom", 16)
	panel.add_child(margin)
	var rows := VBoxContainer.new()
	rows.add_theme_constant_override("separation", 12)
	margin.add_child(rows)

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
	play_button.text = tr("MENU_NEW_GAME")
	music_settings_label.text = tr("MENU_MUSIC")
	sound_settings_label.text = tr("MENU_SOUND")
	language_settings_label.text = tr("MENU_LANGUAGE")
	_refresh_language_options()
	menu_button.text = tr("HUD_MENU")
	menu_button.tooltip_text = tr("HUD_MENU_TOOLTIP")
	discard_history_title.text = tr("HUD_DISCARD_HISTORY")
	(header_caption_labels.get("IncomeStat") as Label).text = tr("HUD_INCOME")
	(header_caption_labels.get("WalletStat") as Label).text = tr("HUD_WALLET")
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
		_start_new_deal()
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
	interaction_locked = false
	_set_hand_interaction_enabled(true)
	_refresh_actions()
	_show_banner(tr("BANNER_NEW_DEAL"))


func _on_menu_pressed() -> void:
	if not game_started or menu_transitioning or interaction_locked or modal_overlay.visible or score_overlay.visible or discard_archive_overlay.visible:
		return
	interaction_locked = true
	_set_hand_interaction_enabled(false)
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
	var drink_slot := Panel.new()
	drink_slot.name = "DrinkSlot"
	drink_slot.position = Vector2(34, 30)
	drink_slot.size = Vector2(66, 64)
	drink_slot.mouse_filter = Control.MOUSE_FILTER_IGNORE
	drink_slot.add_theme_stylebox_override("panel", PresentationTheme.panel_style(Color("#0b0907c0"), Color("#6b5138"), 1, 2, 2))
	drink_panel.add_child(drink_slot)
	drink_name_label = Label.new()
	drink_name_label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	drink_name_label.text = tr(DrinkCatalog.display_name(deal.current_drink_id)).to_upper()
	drink_name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	drink_name_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	drink_name_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	drink_name_label.add_theme_font_size_override("font_size", 11)
	drink_name_label.add_theme_color_override("font_color", PresentationTheme.TEA)
	drink_name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	drink_slot.tooltip_text = tr("HUD_CURRENT_DRINK") % tr(DrinkCatalog.display_name(deal.current_drink_id))
	drink_slot.add_child(drink_name_label)

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


func _sync_all(result: Dictionary = {}, animate_all_cards: bool = false) -> void:
	var animated_cards := _cards_from_result(result)
	if animate_all_cards:
		animated_cards.clear()
		animated_cards.append_array(deal.hand)
	_sync_hand(animated_cards)
	_sync_card_probability_badges()
	var actionable := _sync_card_action_outlines()
	_sync_melds()
	_sync_music_reactive_cards(actionable)
	_sync_piles()
	_sync_discard_history()
	if discard_archive_overlay.visible:
		_sync_pile_archive()
	if drink_name_label != null:
		drink_name_label.text = tr(DrinkCatalog.display_name(deal.current_drink_id)).to_upper()
		drink_name_label.get_parent().tooltip_text = tr("HUD_CURRENT_DRINK") % tr(DrinkCatalog.display_name(deal.current_drink_id))
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
			view.set_meld_chance(0.0, false, "Không có mục tiêu Phỏm", "—", draw_number)
			continue
		var needed_text := "—" if candidate["needed_labels"].is_empty() else " / ".join(candidate["needed_labels"])
		view.set_meld_chance(
			float(candidate["probability"]),
			bool(candidate["ready"]),
			String(candidate["label"]),
			needed_text,
			draw_number
		)


func _sync_card_action_outlines() -> Dictionary:
	var actionable := deal.legal_action_card_ids()
	var meld_card_ids: Dictionary = actionable["meld"]
	var extension_card_ids: Dictionary = actionable["extend"]
	for card in deal.hand:
		var view: PlayingCardView = hand_views.get(card.unique_id)
		if view != null:
			view.set_action_cues(meld_card_ids.has(card.unique_id), extension_card_ids.has(card.unique_id))
	return actionable


func _sync_music_reactive_cards(actionable: Dictionary = {}) -> void:
	_reactive_assignments_clear()
	if actionable.is_empty():
		actionable = deal.legal_action_card_ids()
	var meld_card_ids: Dictionary = actionable.get("meld", {})
	var hand_assignment_index := 0
	for card in deal.hand:
		if not meld_card_ids.has(card.unique_id):
			continue
		var view := hand_views.get(card.unique_id) as PlayingCardView
		if view != null:
			reactive_hand_cards_by_band[hand_assignment_index % MUSIC_BAND_COUNT].append(view)
			hand_assignment_index += 1

	var selected := _selected_cards()
	if selected.is_empty():
		return
	for meld in deal.melds:
		if not deal.can_extend_meld(meld.meld_id, selected):
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
		return
	if selected_meld_id >= 0 and deal.get_meld(selected_meld_id) == null:
		selected_meld_id = -1
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
		elif view.get_index() != index:
			meld_row.move_child(view, index)
		var legal := deal.can_extend_meld(meld.meld_id, selected_cards)
		view.set_meld(meld, meld.meld_id == selected_meld_id, legal)
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


func _refresh_actions() -> void:
	var selected := _selected_cards()
	var card_window := deal.state in [DealState.STATE_ACTIVE, DealState.STATE_FINAL_COMMIT_WINDOW] and not interaction_locked
	var active_turn := deal.state == DealState.STATE_ACTIVE and not interaction_locked
	ha_button.disabled = not card_window or not deal.can_create_meld(selected)
	extend_button.disabled = not card_window or selected_meld_id < 0 or not deal.can_extend_meld(selected_meld_id, selected)
	discard_button.disabled = not active_turn or selected.size() != 1
	settle_button.disabled = deal.state != DealState.STATE_FINAL_COMMIT_WINDOW or interaction_locked
	hint_button.disabled = not card_window or deal.hand.is_empty()
	sort_button.disabled = not card_window or deal.hand.size() < 2
	if interaction_locked:
		status_label.text = tr("STATUS_RESOLVING")
		status_label.add_theme_color_override("font_color", PresentationTheme.MUTED)
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


func _on_card_pressed(card: CardData) -> void:
	if interaction_locked or deal.state not in [DealState.STATE_ACTIVE, DealState.STATE_FINAL_COMMIT_WINDOW]:
		return
	if selected_card_ids.has(card.unique_id):
		selected_card_ids.erase(card.unique_id)
	else:
		selected_card_ids[card.unique_id] = true
	_layout_hand(true)
	_sync_melds()
	_sync_music_reactive_cards()
	_refresh_stats()
	_refresh_actions()


func _on_meld_pressed(meld_id: int) -> void:
	if interaction_locked or deal.state not in [DealState.STATE_ACTIVE, DealState.STATE_FINAL_COMMIT_WINDOW]:
		return
	selected_meld_id = -1 if selected_meld_id == meld_id else meld_id
	_sync_melds()
	_sync_music_reactive_cards()
	_refresh_actions()


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
	_sync_all(result)
	await _show_scoring(result["context"])
	interaction_locked = false
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
	await _show_scoring(result["context"])
	interaction_locked = false
	_refresh_actions()


func _on_discard_pressed() -> void:
	if discard_button.disabled:
		return
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
		if context.drink_bonus_points > 0:
			score_line_b.text = tr("SCORE_DRINK_BONUS") % [context.base_extension_score, context.drink_bonus_points, context.final_points]
		else:
			score_line_b.text = tr("SCORE_DELTA") % [context.theoretical_score, context.old_meld_score, context.final_points]
		score_payout.text = tr("SCORE_INCREASE") % VndWallet.format_vnd(VndWallet.points_to_vnd(context.final_points), true)
	await _play_score_panel(deal.wallet.balance_vnd, context.final_points >= 0)


func _show_phase_resolution(resolution: Dictionary) -> void:
	var is_mom: bool = resolution["mom"]
	var phase_number: int = resolution["phase"]
	score_title.text = tr("SCORE_PHASE_RESULT") % phase_number
	if is_mom:
		score_line_a.text = tr("SCORE_MOM")
		score_line_a.add_theme_color_override("font_color", PresentationTheme.RED)
		score_line_b.text = tr("SCORE_MOM_BANK") % deal.mom_strikes_banked
	else:
		score_line_a.text = tr("SCORE_SAFE") % resolution["new_phom_count"]
		score_line_a.add_theme_color_override("font_color", PresentationTheme.TEA)
		score_line_b.text = tr("SCORE_GROSS") % [resolution["gross_after_u"], tr("SCORE_U_BONUS") if resolution["u"] else ""]
	var deadwood: int = resolution["deadwood_points"]
	score_payout.text = tr("SCORE_NET") % [resolution["net"], resolution["gross_after_u"], deadwood]
	await _play_score_panel(deal.wallet.balance_vnd, not is_mom)
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
	await get_tree().create_timer(0.34).timeout
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
	modal_body.text = tr("MODAL_PHASE1_BODY") % deal.hand.size()
	modal_detail.text = tr("MODAL_PHASE1_DETAIL")
	modal_primary.text = tr("MODAL_KEEP") % deal.hand.size()
	modal_secondary.text = tr("MODAL_REDRAW")
	modal_secondary.visible = true
	_show_modal()
	_refresh_actions()


func _show_deal_over(resolution: Dictionary) -> void:
	interaction_locked = false
	modal_mode = "deal_over"
	modal_kicker.text = tr("MODAL_DEAL_KICKER") % (tr("MOM") if resolution["mom"] else tr("SAFE"))
	modal_title.text = VndWallet.format_vnd(deal.wallet.balance_vnd)
	modal_body.text = tr("MODAL_DEAL_BODY") % deal.melds.size()
	modal_detail.text = tr("MODAL_DEAL_DETAIL") % [deal.mom_strikes_banked, deal.mom_strikes_resolved, resolution["deadwood_points"]]
	modal_primary.text = tr("MODAL_NEW_DEAL")
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
		await _fly_cards(deal.hand, discard_texture.get_global_rect().get_center())
	var result := deal.choose_phase_two(keep_hand)
	if not result.get("ok", false):
		_reject_action(result.get("message", "Phase transition failed."))
		return
	selected_card_ids.clear()
	selected_meld_id = -1
	_sync_all(result)
	_show_banner(tr("BANNER_PHASE2") % (tr("KEEP_HAND") if keep_hand else tr("REDRAW_HAND")))
	interaction_locked = false
	_refresh_actions()


func _start_new_deal() -> void:
	if interaction_locked:
		return
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


func _unhandled_key_input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed or event.echo:
		return
	if menu_layer.visible:
		if game_started and event.keycode == KEY_ESCAPE:
			_close_menu_to_game()
		elif not menu_transitioning and event.keycode in [KEY_ENTER, KEY_KP_ENTER, KEY_SPACE]:
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
			selected_card_ids.clear()
			selected_meld_id = -1
			_sync_all()
