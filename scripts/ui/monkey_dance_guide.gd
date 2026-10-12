extends Control
## Text-only projection of Monkey's committed sequence. Owns no rule state.
const RHYTHM := preload("res://shaders/monkey_rhythm_text.gdshader")
const BURST := preload("res://shaders/monkey_step_burst.gdshader")
const GOLD := Color("ffe078")
var caption: Label
var row: HBoxContainer
var steps: Array[Label] = []
var _identity := ""
var _sequence: Array = []
var _index := 0
var _pending := -1
var _effects: Array[Control] = []
var _tweens: Array[Tween] = []
var lane_height := 76.0
var hint: Label
var _cursor := -1.0
var _clock := 0.0
var _notice_time := 0.0
var _paused := false
var _action_stamp := 0

func _ready() -> void:
	name = "MonkeyDanceGuide"
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	caption = _label(12)
	caption.name = "DanceProgress"
	add_child(caption)
	row = HBoxContainer.new()
	row.position.y = 19
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_theme_constant_override("separation", 10)
	add_child(row)
	hint = _label(12)
	hint.name = "DanceFeedback"
	hint.position.y = 58
	hint.add_theme_color_override("font_color", PresentationTheme.MUTED)
	add_child(hint)
	hide()

func _label(pixels: int) -> Label:
	var label := Label.new()
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.add_theme_font_size_override("font_size", pixels)
	label.add_theme_color_override("font_shadow_color", Color("171017"))
	label.add_theme_constant_override("shadow_offset_x", 1)
	label.add_theme_constant_override("shadow_offset_y", 2)
	return label

func clear_effects() -> void:
	for step in steps: step.self_modulate.a = 1.0
	for tween in _tweens:
		if tween.is_valid(): tween.kill()
	_tweens.clear()
	for effect in _effects:
		if is_instance_valid(effect): effect.queue_free()
	_effects.clear()
	_pending = -1
	_notice_time = 0
	if hint != null:
		hint.text = ""
		hint.add_theme_color_override("font_color", PresentationTheme.MUTED)

func pause_effects(paused: bool) -> void:
	_paused = paused
	# Scoring receipts use the same screen space. Hold the text celebration
	# through the receipt, then finish it when the player returns to the table.
	for tween in _tweens:
		if not tween.is_valid(): continue
		if paused: tween.pause()
		elif not tween.is_running(): tween.play()

func sync(state: Dictionary, identity: String) -> void:
	var sequence: Array = state.get("sequence", []) if state.get("id", "") == "monkey" else []
	visible = not sequence.is_empty()
	if not visible:
		clear_effects()
		_identity = ""
		return
	var index := int(state.sequence_index)
	if identity != _identity or sequence != _sequence:
		clear_effects()
		_identity = identity
		_action_stamp = 0
		_cursor = -1
		_sequence = sequence.duplicate()
		for child in row.get_children():
			row.remove_child(child)
			child.queue_free()
		steps.clear()
		for i in sequence.size():
			if i > 0:
				var arrow := _label(16)
				arrow.text = "→"
				arrow.add_theme_color_override("font_color", PresentationTheme.MUTED)
				row.add_child(arrow)
			var step := _label(18)
			step.name = "DanceStep%d" % i
			step.text = "%d. %s" % [i + 1, ZodiacCatalog.action_label(sequence[i]).to_upper()]
			row.add_child(step)
			steps.append(step)
	elif index != _index:
		_pending = _index
	_index = index
	caption.text = ZodiacCatalog.words("STEP %d/%d", "BƯỚC %d/%d") % [index + 1, sequence.size()]
	caption.add_theme_color_override("font_color", GOLD)
	for i in steps.size():
		var active := i == index
		steps[i].add_theme_color_override("font_color", GOLD if active else Color("8dbfad") if i < index else PresentationTheme.INK)
		steps[i].modulate.a = 1.0 if active else 0.65
		if active:
			if steps[i].material == null:
				var ink := ShaderMaterial.new()
				ink.shader = RHYTHM
				steps[i].material = ink
		else: steps[i].material = null
	queue_redraw()

func fit_width(width: float) -> void:
	# Preserve every action at smaller widths; never ellipsize the required move.
	var pixels := 18
	while pixels > 12:
		var needed := float((_sequence.size() - 1) * 34)
		for step in steps:
			needed += step.get_theme_font("font").get_string_size(step.text, HORIZONTAL_ALIGNMENT_LEFT, -1, pixels).x
		if needed <= width: break
		pixels -= 1
	for step in steps: step.add_theme_font_size_override("font_size", pixels)
	row.size = Vector2(width, 28)
	hint.size.x = width
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hint.add_theme_font_size_override("font_size", 11)
	hint.hide()
	lane_height = 55
	size = Vector2(width, lane_height)

func _process(delta: float) -> void:
	if not is_visible_in_tree() or _paused or steps.is_empty(): return
	_clock += delta
	_notice_time = maxf(_notice_time - delta, 0)
	if _notice_time <= 0:
		hint.text = ""
		hint.add_theme_color_override("font_color", PresentationTheme.MUTED)
	var target := row.position.x + steps[_index].position.x + steps[_index].size.x * 0.5
	_cursor = target if _cursor < 0 else lerpf(_cursor, target, 1 - exp(-delta * 12))
	queue_redraw()

func _draw() -> void:
	if steps.is_empty() or _cursor < 0: return
	# An animated conductor under the words, never a timing window.
	for i in steps.size():
		var x := row.position.x + steps[i].position.x + steps[i].size.x * 0.5
		draw_line(Vector2(x - 16, 48), Vector2(x + 16, 48), Color(GOLD, 0.22), 1, true)
		if i < _index: draw_circle(Vector2(x, 48), 2.5, PresentationTheme.MONEY_GAIN)
	var bob := sin(_clock * 3) * 1.5
	draw_colored_polygon(PackedVector2Array([Vector2(_cursor - 4, 53 + bob), Vector2(_cursor, 47 + bob), Vector2(_cursor + 4, 53 + bob)]), GOLD)
	for beat in 5:
		var height := 2 + (0.5 + 0.5 * sin(_clock * 4 + beat * 1.4)) * 5
		draw_line(Vector2(_cursor - 12 + beat * 6, 45), Vector2(_cursor - 12 + beat * 6, 45 - height), Color(GOLD, 0.55), 1, true)

func present_action(result: Dictionary) -> void:
	if not visible or not result.get("ok", false): return
	var context := result.get("context") as ScoringContext
	if context != null and context.get_instance_id() == _action_stamp: return
	if context != null:
		_action_stamp = context.get_instance_id()
		if context.suppression_reason == "monkey_rhythm_miss":
			hint.text = ZodiacCatalog.words("0 VNĐ · still need ", "0 VNĐ · vẫn cần ") + ZodiacCatalog.action_label(_sequence[_index])
			hint.add_theme_color_override("font_color", PresentationTheme.DANGER)
			_notice_time = 1.6
			return
	if _pending < 0: return
	var completed := _pending
	_pending = -1
	if not result.get("ok", false) or result.get("action", "") != _sequence[completed]: return
	hint.text = ZodiacCatalog.words("LOOP COMPLETE ✓", "ĐỦ CHUỖI ✓") if _index == 0 else ZodiacCatalog.words("STEP %d ✓ · next: ", "BƯỚC %d ✓ · tiếp: ") % (completed + 1) + ZodiacCatalog.action_label(_sequence[_index])
	hint.add_theme_color_override("font_color", PresentationTheme.MONEY_GAIN)
	_notice_time = 1.6
	var source := steps[completed]
	var ghost := _label(source.get_theme_font_size("font_size"))
	ghost.name = "CompletedDanceStep"
	ghost.text = source.text + " ✓"
	ghost.add_theme_color_override("font_color", GOLD)
	ghost.position = row.position + source.position
	ghost.size = source.size + Vector2(22, 0)
	ghost.pivot_offset = ghost.size * 0.5
	source.self_modulate.a = 0.0
	add_child(ghost)
	_effects.append(ghost)
	var burst := ColorRect.new()
	burst.name = "MonkeyStepBurst"
	burst.position = Vector2(-22, -16)
	burst.size = ghost.size + Vector2(44, 32)
	burst.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var ink := ShaderMaterial.new()
	ink.shader = BURST
	ink.set_shader_parameter("surface_size", burst.size)
	burst.material = ink
	ghost.add_child(burst)
	var tween := create_tween().set_parallel(true)
	_tweens.append(tween)
	tween.tween_property(ghost, "position:x", ghost.position.x + 12, 0.48).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(ghost, "scale", Vector2.ONE * 1.12, 0.48)
	tween.tween_property(ghost, "modulate:a", 0.0, 0.3).set_delay(0.18)
	tween.tween_method(func(value: float): ink.set_shader_parameter("progress", value), 0.0, 1.0, 0.48)
	tween.chain().tween_callback(func():
		if is_instance_valid(source): source.self_modulate.a = 1.0
		_effects.erase(ghost)
		_tweens.erase(tween)
		ghost.queue_free())
