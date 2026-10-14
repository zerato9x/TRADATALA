extends RefCounted
## Read-only collection furniture. Original sprites, labels and Button input remain authoritative.

static func tile(button: Button, caption: String, status: String, texture: Texture2D, tint: Color, selected: bool) -> void:
	button.text = ""
	button.tooltip_text = caption + " · " + status
	button.accessibility_name = caption + ", " + status
	button.custom_minimum_size = Vector2(112, 174)
	var margin := MarginContainer.new()
	margin.name = "TileContent"
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 8)
	button.add_child(margin)
	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 4)
	margin.add_child(content)
	var art := TextureRect.new()
	art.name = "Thumbnail"
	art.texture = texture
	art.modulate = tint
	art.custom_minimum_size.y = 78
	art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	art.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	content.add_child(art)
	var title := Label.new()
	title.text = caption
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	title.add_theme_font_size_override("font_size", 16)
	title.custom_minimum_size.y = 44
	title.max_lines_visible = 2
	title.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	content.add_child(title)
	var state := Label.new()
	state.text = status
	state.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	state.add_theme_font_size_override("font_size", 12)
	state.set_meta("text_role", &"muted")
	content.add_child(state)
	if selected: PresentationTheme.paper_labels(content)
	_pass_input(margin)

static func stage(parent: VBoxContainer, sprite: TextureRect, accent: Color) -> void:
	var display := preload("res://scripts/ui/collection_stage.gd").new()
	display.name = "CollectionDisplay"
	display.accent = accent
	display.custom_minimum_size.y = 208
	parent.add_child(display)
	sprite.reparent(display)
	sprite.custom_minimum_size = Vector2.ZERO
	sprite.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	sprite.offset_top = 12
	sprite.offset_bottom = -24
	sprite.offset_left = 30
	sprite.offset_right = -30
	_pass_input(display)

static func progress_row(parent: VBoxContainer, caption: Label, current: int, required: int, accent: Color) -> void:
	var row := VBoxContainer.new()
	row.add_theme_constant_override("separation", 5)
	parent.add_child(row)
	row.add_child(caption)
	var meter := ProgressBar.new()
	meter.name = "RequirementProgress"
	meter.custom_minimum_size.y = 4
	meter.show_percentage = false
	meter.max_value = maxi(1, required)
	meter.value = current
	meter.mouse_filter = Control.MOUSE_FILTER_IGNORE
	meter.add_theme_stylebox_override("background", PresentationTheme.panel_style(Color("ffffff16")))
	meter.add_theme_stylebox_override("fill", PresentationTheme.panel_style(accent))
	row.add_child(meter)

static func receipt_row(row: HBoxContainer, index: int) -> void:
	var parent := row.get_parent()
	var panel := PanelContainer.new()
	panel.name = "DebtDay%d" % index
	var style := PresentationTheme.panel_style(Color("cfb47740") if index == 6 else Color.TRANSPARENT)
	style.border_color = Color("80550b35")
	style.border_width_bottom = 1
	style.content_margin_left = 8
	style.content_margin_right = 8
	style.content_margin_top = 4
	style.content_margin_bottom = 5
	panel.add_theme_stylebox_override("panel", style)
	parent.add_child(panel)
	row.reparent(panel)

static func _pass_input(control: Control) -> void:
	control.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for child in control.get_children():
		if child is Control: _pass_input(child)
