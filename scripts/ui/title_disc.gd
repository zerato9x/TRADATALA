extends Control

## A typographic record: the two names are the artwork.
const FONT := preload("res://assets/DFVN Pexel Grotesk.ttf")
const INK := Color("#f8edcf")
const BACKGROUND := Color("#101c2d")
var elapsed := 0.0
var leaving := false


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	z_index = 200
	queue_redraw()


func _process(delta: float) -> void:
	# Direct campaign/tutorial starts also retire the opening screen.
	if owner.get("game_started") == true and not leaving:
		queue_free()
		return
	elapsed += delta
	queue_redraw()


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), BACKGROUND)
	var center := Vector2(size.x * 0.5, size.y * 0.46)
	var scale_factor := minf(size.x / 960.0, size.y / 720.0)
	var entrance := smoothstep(0.0, 1.4, elapsed)
	var spin := elapsed * 0.085
	# Concentric type grooves form the disc without a separate image asset.
	_draw_ring("TRADATALA · TRADATALA · ", center, 214.0 * scale_factor, 44, spin, INK, entrance, scale_factor)
	_draw_ring("TRÀ ĐÁ TÁ LẢ · TRÀ ĐÁ TÁ LẢ · ", center, 161.0 * scale_factor, 29, -spin * 0.72, INK, entrance * 0.78, scale_factor)
	_draw_ring("TRADATALA · TRADATALA · ", center, 115.0 * scale_factor, 23, spin * 0.82, INK, entrance * 0.52, scale_factor)
	_draw_ring("TRÀ ĐÁ TÁ LẢ · ", center, 76.0 * scale_factor, 19, -spin * 0.55, INK, entrance * 0.3, scale_factor)
	draw_set_transform(Vector2.ZERO)
	var vietnamese := TranslationServer.get_locale().begins_with("vi")
	var prompt := "NHẤP BẤT KỲ ĐÂU ĐỂ TIẾP TỤC" if vietnamese else "CLICK ANYWHERE TO CONTINUE"
	var font_size := maxi(12, roundi(14.0 * scale_factor))
	var width := FONT.get_string_size(prompt, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
	var opacity := smoothstep(0.8, 2.0, elapsed) * (0.65 + 0.15 * sin(elapsed * 1.8))
	draw_string(FONT, Vector2((size.x - width) * 0.5, size.y * 0.88), prompt, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, Color(INK, opacity))


func _draw_ring(text: String, center: Vector2, radius: float, font_size: int, angle: float, color: Color, opacity: float, scale_factor: float) -> void:
	var pixels := maxi(10, roundi(font_size * scale_factor))
	var step := TAU / text.length()
	for index in text.length():
		var theta := angle + step * index - PI * 0.5
		var glyph := text.substr(index, 1)
		var width := FONT.get_string_size(glyph, HORIZONTAL_ALIGNMENT_LEFT, -1, pixels).x
		draw_set_transform(center + Vector2(cos(theta), sin(theta)) * radius, theta + PI * 0.5)
		draw_string(FONT, Vector2(-width * 0.5, 0), glyph, HORIZONTAL_ALIGNMENT_LEFT, -1, pixels, Color(color, opacity))


func _input(event: InputEvent) -> void:
	if leaving:
		get_viewport().set_input_as_handled()
		return
	var clicked: bool = event is InputEventMouseButton and event.pressed and event.button_index in [MOUSE_BUTTON_LEFT, MOUSE_BUTTON_RIGHT, MOUSE_BUTTON_MIDDLE]
	var keyed: bool = event is InputEventKey and event.pressed and not event.echo
	var touched: bool = event is InputEventScreenTouch and event.pressed
	var controller: bool = event is InputEventJoypadButton and event.pressed
	if not (clicked or keyed or touched or controller):
		return
	get_viewport().set_input_as_handled()
	leaving = true
	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.45).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	tween.tween_callback(queue_free)