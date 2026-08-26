class_name MeldView
extends PanelContainer

signal meld_pressed(meld_id: int)

var meld_id: int = -1
var _title: Label
var _cards_row: HBoxContainer
var _score: Label
var _hint: Label


func _ready() -> void:
	custom_minimum_size = Vector2(190, 146)
	size_flags_vertical = Control.SIZE_SHRINK_CENTER
	mouse_filter = Control.MOUSE_FILTER_STOP
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	_build_content()
	gui_input.connect(_on_gui_input)


func set_meld(meld: MeldState, is_selected: bool, extension_is_legal: bool) -> void:
	meld_id = meld.meld_id
	if _title == null:
		return
	_title.text = "%s  %02d" % ["SẢNH" if meld.meld_type == MeldRules.TYPE_RUN else "BỘ", meld.meld_id]
	_score.text = "%d ĐIỂM  •  %s" % [meld.scored_points, VndWallet.format_vnd(VndWallet.points_to_vnd(meld.scored_points))]
	_hint.text = "SẴN SÀNG GHÉP" if extension_is_legal else ("ĐANG CHỌN" if is_selected else "CHỌN ĐỂ GHÉP")
	_hint.add_theme_color_override("font_color", PresentationTheme.TEA if extension_is_legal else (PresentationTheme.GOLD if is_selected else PresentationTheme.MUTED))
	var border := PresentationTheme.TEA if extension_is_legal else (PresentationTheme.GOLD if is_selected else Color("#35594f"))
	var background := Color("#174338f2") if is_selected else Color("#102b25e8")
	add_theme_stylebox_override("panel", PresentationTheme.panel_style(background, border, 2 if is_selected or extension_is_legal else 1, 12, 4))
	for child in _cards_row.get_children():
		child.queue_free()
	for card in meld.cards:
		var texture := TextureRect.new()
		texture.custom_minimum_size = Vector2(49, 68)
		texture.texture = load(card.texture_path()) as Texture2D
		texture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		texture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		texture.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		texture.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_cards_row.add_child(texture)
	tooltip_text = "Click to target this %s for EXTEND." % ("Run" if meld.meld_type == MeldRules.TYPE_RUN else "Set")


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
