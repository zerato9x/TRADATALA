class_name CardActionOutline
extends Control

const CUE_NONE := 0
const CUE_MELD := 1
const CUE_EXTEND := 2
const CUE_BOTH := 3
const CUE_DRINK := 4
const CUE_ALL := CUE_MELD | CUE_EXTEND | CUE_DRINK

const MELD_BASE := Color("#1f7d43")
const MELD_HIGHLIGHT := Color("#a8ff9a")
const EXTEND_BASE := Color("#b87516")
const EXTEND_HIGHLIGHT := Color("#fff08a")
const DRINK_BASE := Color("#1764b8")
const DRINK_HIGHLIGHT := Color("#8fe7ff")

var _cue_mode: int = CUE_NONE
var _phase: float = 0.0
var _emphasized: bool = false
var _pulse_tween: Tween


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_process(false)


func set_cues(can_meld: bool, can_extend: bool, can_drink: bool = false, emphasized: bool = false) -> void:
	var next_mode := CUE_NONE
	if can_meld:
		next_mode |= CUE_MELD
	if can_extend:
		next_mode |= CUE_EXTEND
	if can_drink:
		next_mode |= CUE_DRINK
	_emphasized = emphasized and can_drink
	_set_cue_mode(next_mode)


func set_drink_cue(active: bool) -> void:
	set_cues(false, false, active, active)


func set_emphasized(value: bool) -> void:
	_emphasized = value and (_cue_mode & CUE_DRINK) != 0
	queue_redraw()


func play_target_pulse(strength: float = 0.6) -> void:
	if _cue_mode == CUE_NONE or not is_visible_in_tree():
		return
	if _pulse_tween != null and _pulse_tween.is_valid():
		_pulse_tween.kill()
	var amount := lerpf(0.025, 0.065, clampf(strength, 0.0, 1.0))
	pivot_offset = size * 0.5
	scale = Vector2.ONE
	_pulse_tween = create_tween()
	_pulse_tween.tween_property(self, "scale", Vector2.ONE * (1.0 + amount), 0.08).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_pulse_tween.tween_property(self, "scale", Vector2.ONE, 0.2).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)


func cue_mode() -> int:
	return _cue_mode


func _process(delta: float) -> void:
	_phase = fmod(_phase + delta * 0.34, 1.0)
	queue_redraw()


func _draw() -> void:
	if _cue_mode == CUE_NONE or size.x <= 0.0 or size.y <= 0.0:
		return
	var path := _rounded_rect_path(Rect2(Vector2(4, 4), size - Vector2(8, 8)), 7.0, 8)
	var glow_colors := PackedColorArray()
	var core_colors := PackedColorArray()
	for index in range(path.size()):
		var ratio := float(index) / float(maxi(path.size() - 1, 1))
		var wave := sin((ratio - _phase) * TAU) * 0.5 + 0.5
		wave = wave * wave * (3.0 - 2.0 * wave)
		var color := _gradient_color(ratio, wave)
		var glow := color
		glow.a = 0.34 if _emphasized else 0.22
		color.a = 0.96
		glow_colors.append(glow)
		core_colors.append(color)
	draw_polyline_colors(path, glow_colors, 9.0 if _emphasized else 7.0, true)
	draw_polyline_colors(path, core_colors, 3.4 if _emphasized else 2.6, true)


func _gradient_color(ratio: float, wave: float) -> Color:
	var color_pairs := _active_color_pairs()
	if color_pairs.size() == 1:
		return (color_pairs[0]["base"] as Color).lerp(color_pairs[0]["highlight"] as Color, 0.18 + wave * 0.82)
	var count := float(color_pairs.size())
	var cycle := fposmod(ratio * count - _phase * 0.85, count)
	var first_index := int(floor(cycle)) % color_pairs.size()
	var second_index := (first_index + 1) % color_pairs.size()
	var blend := smoothstep(0.18, 0.82, cycle - floor(cycle))
	var first_pair: Dictionary = color_pairs[first_index]
	var second_pair: Dictionary = color_pairs[second_index]
	var first_color: Color = (first_pair["base"] as Color).lerp(first_pair["highlight"] as Color, 0.24 + wave * 0.76)
	var second_color: Color = (second_pair["base"] as Color).lerp(second_pair["highlight"] as Color, 0.24 + wave * 0.76)
	return first_color.lerp(second_color, blend)


func _active_color_pairs() -> Array[Dictionary]:
	var pairs: Array[Dictionary] = []
	if (_cue_mode & CUE_MELD) != 0:
		pairs.append({"base": MELD_BASE, "highlight": MELD_HIGHLIGHT})
	if (_cue_mode & CUE_EXTEND) != 0:
		pairs.append({"base": EXTEND_BASE, "highlight": EXTEND_HIGHLIGHT})
	if (_cue_mode & CUE_DRINK) != 0:
		pairs.append({"base": DRINK_BASE, "highlight": DRINK_HIGHLIGHT})
	return pairs


func _set_cue_mode(next_mode: int) -> void:
	_cue_mode = next_mode
	visible = _cue_mode != CUE_NONE
	set_process(visible)
	queue_redraw()


func _rounded_rect_path(rect: Rect2, radius: float, segments_per_corner: int) -> PackedVector2Array:
	var points := PackedVector2Array()
	var centers := [
		rect.position + Vector2(radius, radius),
		rect.position + Vector2(rect.size.x - radius, radius),
		rect.position + Vector2(rect.size.x - radius, rect.size.y - radius),
		rect.position + Vector2(radius, rect.size.y - radius),
	]
	var start_angles := [PI, -PI * 0.5, 0.0, PI * 0.5]
	for corner in range(4):
		for step in range(segments_per_corner + 1):
			var angle: float = float(start_angles[corner]) + (PI * 0.5) * (float(step) / float(segments_per_corner))
			points.append(centers[corner] + Vector2(cos(angle), sin(angle)) * radius)
	if not points.is_empty():
		points.append(points[0])
	return points
