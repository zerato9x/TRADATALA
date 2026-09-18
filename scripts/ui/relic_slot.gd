class_name RelicSlot
extends PanelContainer

var relic_id := ""
var outline: CardActionOutline
var pulse: Tween

func configure(id: String, index: int) -> void:
	relic_id = id
	custom_minimum_size = Vector2(52, 78)
	mouse_filter = Control.MOUSE_FILTER_STOP
	add_theme_stylebox_override("panel", PresentationTheme.panel_style(PresentationTheme.PANEL_LIGHT, PresentationTheme.GOLD_DARK, 1))
	var column := VBoxContainer.new()
	column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(column)
	var icon := TextureRect.new()
	icon.custom_minimum_size = Vector2(48, 48)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_child(icon)
	var label := Label.new()
	label.add_theme_font_size_override("font_size", 10)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.custom_minimum_size.x = 48
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_child(label)
	if id.is_empty():
		label.text = str(index + 1)
	else:
		icon.texture = load(RelicCatalog.icon_path(id))
		label.text = RelicCatalog.DEFINITIONS[id].name
		tooltip_text = label.text + "\n" + RelicCatalog.effect(id)
	outline = CardActionOutline.new()
	add_child(outline)
	outline.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

func trigger() -> void:
	if pulse != null and pulse.is_valid():
		pulse.kill()
	outline.set_drink_cue(true)
	modulate = Color(1.3, 1.2, 1.0)
	pulse = create_tween()
	pulse.tween_property(self, "modulate", Color.WHITE, 0.6)
	pulse.tween_callback(outline.set_drink_cue.bind(false))
