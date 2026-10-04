extends Control
const SHADERS := {"ox": preload("res://shaders/ox_burden.gdshader"), "goat": preload("res://shaders/goat_note.gdshader"), "snake": preload("res://shaders/snake_command.gdshader")}
var surface: ColorRect
var caption: Label
var _kind := ""

func _ready() -> void:
	name = "ZodiacHandCue"
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	surface = ColorRect.new()
	surface.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	surface.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(surface)
	caption = Label.new()
	caption.position = Vector2(5, 94)
	caption.size = Vector2(76, 18)
	caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	caption.add_theme_font_size_override("font_size", 12)
	caption.add_theme_color_override("font_shadow_color", Color.BLACK)
	caption.add_theme_constant_override("outline_size", 2)
	caption.add_theme_color_override("font_outline_color", Color("161917"))
	caption.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(caption)
	hide()

func sync(hint: Dictionary) -> void:
	visible = not hint.is_empty()
	if not visible: return
	var kind: String = hint.kind
	if kind != _kind:
		_kind = kind
		var ink := ShaderMaterial.new()
		ink.shader = SHADERS[kind]
		surface.material = ink
	(surface.material as ShaderMaterial).set_shader_parameter("strength", hint.strength)
	caption.text = hint.caption
	caption.add_theme_color_override("font_color", preload("res://scripts/ui/zodiac_presentation.gd").accent(kind))
