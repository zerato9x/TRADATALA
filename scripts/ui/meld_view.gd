class_name MeldView
extends PanelContainer

signal meld_pressed(meld_id: int)
signal meld_card_pressed(meld_id: int, card: CardData)

var meld_id: int = -1
var _title: Label
var _cards_row: HBoxContainer
var _score: Label
var _hint: Label
var _card_views: Dictionary = {}
var _card_beat_tweens: Dictionary = {}


func _ready() -> void:
	custom_minimum_size = Vector2(178, 136)
	size_flags_vertical = Control.SIZE_SHRINK_CENTER
	mouse_filter = Control.MOUSE_FILTER_STOP
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	_build_content()
	gui_input.connect(_on_gui_input)


func set_meld(
	meld: MeldState,
	is_selected: bool,
	extension_is_legal: bool,
	drink_selection_enabled: bool = false,
	drink_removable_card_ids: Dictionary = {},
	selected_drink_card_id: String = ""
) -> void:
	meld_id = meld.meld_id
	if _title == null:
		return
	_title.text = "%s  %02d" % [tr("MELD_RUN") if meld.meld_type == MeldRules.TYPE_RUN else tr("MELD_SET"), meld.meld_id]
	_score.text = tr("MELD_POINTS") % [meld.scored_points, VndWallet.format_vnd(VndWallet.points_to_vnd(meld.scored_points))]
	_hint.text = tr("MELD_READY_EXTEND") if extension_is_legal else (tr("MELD_SELECTED") if is_selected else tr("MELD_SELECT_EXTEND"))
	_hint.add_theme_color_override("font_color", PresentationTheme.TEA if extension_is_legal else (PresentationTheme.GOLD if is_selected else PresentationTheme.MUTED))
	var border := PresentationTheme.TEA if extension_is_legal else (PresentationTheme.GOLD if is_selected else Color("#8d5b30"))
	var background := Color("#2d251eee") if is_selected else Color("#19130fe8")
	add_theme_stylebox_override("panel", PresentationTheme.panel_style(background, border, 2 if is_selected or extension_is_legal else 1, 2, 4))
	_sync_cards(meld.cards, drink_selection_enabled, drink_removable_card_ids, selected_drink_card_id)
	tooltip_text = tr("MELD_TOOLTIP") % (tr("MELD_RUN") if meld.meld_type == MeldRules.TYPE_RUN else tr("MELD_SET"))


func play_card_beat_pulse(card_id: String, strength: float) -> void:
	var texture := _card_views.get(card_id) as TextureRect
	if texture == null or not texture.is_visible_in_tree():
		return
	var previous := _card_beat_tweens.get(card_id) as Tween
	if previous != null and previous.is_valid():
		previous.kill()
	var pulse_strength := clampf(strength, 0.2, 1.0)
	texture.pivot_offset = texture.size * 0.5
	texture.scale = Vector2.ONE
	var peak := Vector2(
		1.0 + lerpf(0.025, 0.065, pulse_strength),
		1.0 + lerpf(0.055, 0.13, pulse_strength)
	)
	var tween := create_tween()
	_card_beat_tweens[card_id] = tween
	tween.tween_property(texture, "scale", peak, 0.075).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(texture, "scale", Vector2.ONE, 0.19).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)


func _sync_cards(
	cards: Array[CardData],
	drink_selection_enabled: bool,
	drink_removable_card_ids: Dictionary,
	selected_drink_card_id: String
) -> void:
	var active_card_ids := {}
	for card in cards:
		active_card_ids[card.unique_id] = true
	for existing_id in _card_views.keys():
		if active_card_ids.has(existing_id):
			continue
		var stale_texture := _card_views[existing_id] as TextureRect
		if stale_texture != null:
			_cards_row.remove_child(stale_texture)
			stale_texture.queue_free()
		var stale_tween := _card_beat_tweens.get(existing_id) as Tween
		if stale_tween != null and stale_tween.is_valid():
			stale_tween.kill()
		_card_beat_tweens.erase(existing_id)
		_card_views.erase(existing_id)
	for index in range(cards.size()):
		var card := cards[index]
		var texture := _card_views.get(card.unique_id) as TextureRect
		if texture == null:
			texture = TextureRect.new()
			texture.custom_minimum_size = Vector2(49, 68)
			texture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			texture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			texture.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
			texture.mouse_filter = Control.MOUSE_FILTER_STOP
			texture.gui_input.connect(_on_card_gui_input.bind(card))
			_cards_row.add_child(texture)
			_card_views[card.unique_id] = texture
		var texture_path := card.texture_path()
		if texture.texture == null or texture.texture.resource_path != texture_path:
			texture.texture = load(texture_path) as Texture2D
		if texture.get_index() != index:
			_cards_row.move_child(texture, index)
		texture.mouse_filter = Control.MOUSE_FILTER_STOP if drink_selection_enabled else Control.MOUSE_FILTER_IGNORE
		texture.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND if drink_selection_enabled else Control.CURSOR_ARROW
		texture.modulate = Color("#fff1b8") if card.unique_id == selected_drink_card_id else Color.WHITE
		if drink_selection_enabled:
			texture.tooltip_text = tr("DRINK_NUOC_VOI_CARD_VALID") if drink_removable_card_ids.has(card.unique_id) else tr("DRINK_NUOC_VOI_CARD_INVALID")
		else:
			texture.tooltip_text = ""


func _build_content() -> void:
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 11)
	margin.add_theme_constant_override("margin_top", 9)
	margin.add_theme_constant_override("margin_right", 11)
	margin.add_theme_constant_override("margin_bottom", 8)
	add_child(margin)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 4)
	margin.add_child(column)
	var title_row := HBoxContainer.new()
	column.add_child(title_row)
	_title = Label.new()
	_title.add_theme_font_size_override("font_size", 13)
	_title.add_theme_color_override("font_color", PresentationTheme.GOLD)
	_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_row.add_child(_title)
	_hint = Label.new()
	_hint.add_theme_font_size_override("font_size", 9)
	title_row.add_child(_hint)
	_cards_row = HBoxContainer.new()
	_cards_row.add_theme_constant_override("separation", -8)
	_cards_row.alignment = BoxContainer.ALIGNMENT_CENTER
	_cards_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	column.add_child(_cards_row)
	_score = Label.new()
	_score.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_score.add_theme_font_size_override("font_size", 11)
	_score.add_theme_color_override("font_color", PresentationTheme.INK)
	column.add_child(_score)


func _on_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		accept_event()
		meld_pressed.emit(meld_id)


func _on_card_gui_input(event: InputEvent, card: CardData) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		accept_event()
		meld_card_pressed.emit(meld_id, card)
