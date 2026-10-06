class_name RelicSlot
extends Button
## One active relic icon; the scroll rail grows with ownership.
var relic_id := ""
var outline: CardActionOutline
var pulse: Tween

func configure(id: String, _index: int) -> void:
	relic_id = id
	name = "Relic_" + id
	custom_minimum_size = Vector2(52, 52)
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	tooltip_text = RelicCatalog.display_name(id) + "\n" + RelicCatalog.effect(id)
	PresentationTheme.configure_button(self)
	add_theme_stylebox_override("normal", PresentationTheme.panel_style(Color("#10233870"), Color("#7a622e90"), 1, 8, 3))
	var icon := TextureRect.new()
	icon.texture = load(RelicCatalog.icon_path(id))
	icon.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	icon.offset_left = 4
	icon.offset_top = 4
	icon.offset_right = -4
	icon.offset_bottom = -4
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(icon)
	outline = CardActionOutline.new()
	outline.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	outline.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(outline)
	pressed.connect(func(): GameGlossary.open_entry(self, RelicCatalog.display_name(id), RelicCatalog.effect(id), "relics"))

func trigger() -> void:
	if pulse != null and pulse.is_valid(): pulse.kill()
	outline.set_drink_cue(true)
	pulse = create_tween()
	pulse.tween_interval(0.6)
	pulse.tween_callback(func(): outline.set_drink_cue(false))
