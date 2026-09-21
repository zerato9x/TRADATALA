extends Control
## The opening record unfolds into the menu's four beat-reactive words.
const FONT := preload("res://assets/DFVN Pexel Grotesk.ttf")
const INK := Color("#f8edcf")
var elapsed := 0.0
var leaving := false
var opened := false
var unfold := 0.0
var pulses := [0.0, 0.0, 0.0, 0.0]
var menu: Control
var content: Control
var logo: Control

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	_setup.call_deferred()

func _setup() -> void:
	if not is_instance_valid(owner): return
	menu = owner.get_node("MainMenu")
	content = menu.get_node("MenuCenter")
	logo = content.get_node("MenuContent/Logo")
	logo.self_modulate.a = 0.0
	for word in logo.get_children(): word.self_modulate.a = 0.0
	content.modulate.a = 0.0
	content.hide()
	menu.get_node("MenuShade").modulate.a = 0.0
	var music = owner.get_node("ReactiveMusic")
	if music.has_signal("band_pulse"): music.band_pulse.connect(_pulse)

func _pulse(band: int, strength: float) -> void:
	if band >= 0 and band < pulses.size(): pulses[band] = clampf(strength, 0.0, 1.0)

func _process(delta: float) -> void:
	elapsed += delta
	for index in pulses.size(): pulses[index] = move_toward(pulses[index], 0.0, delta * 3.0)
	if is_instance_valid(menu):
		# Direct saved-run/test starts bypass the splash without destroying the menu title.
		if owner.get("game_started") == true and not opened and not leaving:
			unfold = 1.0
			opened = true
			content.show()
			content.modulate.a = 1.0
			mouse_filter = Control.MOUSE_FILTER_IGNORE
		visible = menu.visible
		modulate.a = menu.modulate.a
	queue_redraw()

func _draw() -> void:
	var scale_factor := minf(size.x / 1280.0, size.y / 720.0)
	var center := Vector2(size.x * 0.5, size.y * 0.53)
	var entrance := smoothstep(0.0, 1.0, elapsed)
	var spin := elapsed * 0.085
	var target := Vector2(size.x * 0.5, 90.0 * scale_factor)
	if is_instance_valid(logo): target = logo.get_global_rect().get_center()
	var words := ["TRA", "DA", "TA", "LA"]
	var font_size := maxi(18, roundi(lerpf(44, 60, unfold) * scale_factor))
	var widths: Array[float] = []
	var total := 0.0
	for word in words:
		var width := FONT.get_string_size(word, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
		widths.append(width)
		total += width
	var gap := 22.0 * scale_factor
	total += gap * 3
	var cursor := target.x - total * 0.5
	var glyph_index := 0
	for word_index in words.size():
		var word: String = words[word_index]
		var pulse: float = pulses[word_index]
		var word_center := cursor + widths[word_index] * 0.5
		var glyph_x := cursor
		for glyph in word:
			var width := FONT.get_string_size(glyph, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
			var theta := spin + TAU * glyph_index / 22.0 - PI * 0.5
			var ring_pos := center + Vector2(cos(theta), sin(theta)) * (214.0 + pulse * 7.0) * scale_factor
			var line_pos := Vector2(word_center + (glyph_x + width * 0.5 - word_center) * (1.0 + pulse * 0.08), target.y + font_size * 0.3 - pulse * 10.0 * scale_factor)
			draw_set_transform(ring_pos.lerp(line_pos, unfold), lerp_angle(theta + PI * 0.5, 0.0, unfold), Vector2(1.0, 1.0 + pulse * 0.12))
			draw_string(FONT, Vector2(-width * 0.5, 0), glyph, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, Color(INK, entrance))
			glyph_x += width
			glyph_index += 1
		cursor += widths[word_index] + gap
	if unfold < 1.0:
		var ring_text := "TRADATALA · TRADATALA · "
		for index in range(9, ring_text.length()):
			var theta := spin + TAU * index / 22.0 - PI * 0.5
			var glyph := ring_text.substr(index, 1)
			var width := FONT.get_string_size(glyph, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
			draw_set_transform(center + Vector2(cos(theta), sin(theta)) * 214.0 * scale_factor, theta + PI * 0.5)
			draw_string(FONT, Vector2(-width * 0.5, 0), glyph, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, Color(INK, entrance * (1.0 - unfold)))
		_draw_ring("TRÀ ĐÁ TÁ LẢ · TRÀ ĐÁ TÁ LẢ · ", center, 147.0 * scale_factor, 27, -spin * 0.72, entrance * (1.0 - unfold) * 0.8, scale_factor)
		_draw_ring("TRADATALA · TRADATALA · ", center, 96.0 * scale_factor, 20, spin * 0.82, entrance * (1.0 - unfold) * 0.45, scale_factor)
	draw_set_transform(Vector2.ZERO)
	if not opened:
		var prompt := "NHẤP BẤT KỲ ĐÂU ĐỂ TIẾP TỤC" if TranslationServer.get_locale().begins_with("vi") else "CLICK ANYWHERE TO CONTINUE"
		var pixels := maxi(12, roundi(16.0 * scale_factor))
		var width := FONT.get_string_size(prompt, HORIZONTAL_ALIGNMENT_LEFT, -1, pixels).x
		draw_string(FONT, Vector2((size.x - width) * 0.5, size.y * 0.87), prompt, HORIZONTAL_ALIGNMENT_LEFT, -1, pixels, Color(INK, (1.0 - unfold) * entrance))

func _draw_ring(text: String, center: Vector2, radius: float, font_size: int, angle: float, opacity: float, scale_factor: float) -> void:
	var pixels := maxi(10, roundi(font_size * scale_factor))
	for index in text.length():
		var theta := angle + TAU / text.length() * index - PI * 0.5
		var glyph := text.substr(index, 1)
		var width := FONT.get_string_size(glyph, HORIZONTAL_ALIGNMENT_LEFT, -1, pixels).x
		draw_set_transform(center + Vector2(cos(theta), sin(theta)) * radius, theta + PI * 0.5)
		draw_string(FONT, Vector2(-width * 0.5, 0), glyph, HORIZONTAL_ALIGNMENT_LEFT, -1, pixels, Color(INK, opacity))

func _input(event: InputEvent) -> void:
	if opened or not visible: return
	var clicked: bool = event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT
	var keyed: bool = event is InputEventKey and event.pressed and not event.echo
	var touched: bool = event is InputEventScreenTouch and event.pressed
	var controller: bool = event is InputEventJoypadButton and event.pressed
	if not (clicked or keyed or touched or controller): return
	get_viewport().set_input_as_handled()
	if leaving or not is_instance_valid(content): return
	leaving = true
	content.show()
	var feedback := owner.get_node_or_null("UIFeedback") as UIFeedback
	if feedback != null: feedback.play(&"transition")
	var tween := create_tween()
	tween.tween_property(self, "unfold", 1.0, 0.8).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	tween.parallel().tween_property(content, "modulate:a", 1.0, 0.4).set_delay(0.4)
	tween.parallel().tween_property(menu.get_node("MenuShade"), "modulate:a", 0.65, 0.6)
	tween.tween_callback(func():
		opened = true
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		owner.play_button.grab_focus())

func _exit_tree() -> void:
	if is_instance_valid(content):
		content.show()
		content.modulate.a = 1.0
	if is_instance_valid(logo):
		logo.self_modulate.a = 1.0
		for word in logo.get_children(): word.self_modulate.a = 1.0
