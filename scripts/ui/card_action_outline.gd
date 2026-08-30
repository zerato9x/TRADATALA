class_name CardActionOutline
extends Control

const CUE_NONE := 0
const CUE_MELD := 1
const CUE_EXTEND := 2
const CUE_BOTH := 3
const CUE_DRINK := 4

const MELD_BASE := Color("#1f7d43")
const MELD_HIGHLIGHT := Color("#a8ff9a")
const EXTEND_BASE := Color("#b87516")
const EXTEND_HIGHLIGHT := Color("#fff08a")
const DRINK_BASE := Color("#1764b8")
const DRINK_HIGHLIGHT := Color("#8fe7ff")

var _cue_mode: int = CUE_NONE
var _phase: float = 0.0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_process(false)


func set_cues(can_meld: bool, can_extend: bool) -> void:
	var next_mode := CUE_NONE
	if can_meld:
		next_mode |= CUE_MELD
	if can_extend:
		next_mode |= CUE_EXTEND
	_set_cue_mode(next_mode)


func set_drink_cue(active: bool) -> void:
	_set_cue_mode(CUE_DRINK if active else CUE_NONE)


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
		glow.a = 0.22
		color.a = 0.96
		glow_colors.append(glow)
		core_colors.append(color)
	draw_polyline_colors(path, glow_colors, 7.0, true)
	draw_polyline_colors(path, core_colors, 2.6, true)


func _gradient_color(ratio: float, wave: float) -> Color:
	if _cue_mode == CUE_MELD:
		return MELD_BASE.lerp(MELD_HIGHLIGHT, 0.18 + wave * 0.82)
	if _cue_mode == CUE_EXTEND:
		return EXTEND_BASE.lerp(EXTEND_HIGHLIGHT, 0.18 + wave * 0.82)
	if _cue_mode == CUE_DRINK:
		return DRINK_BASE.lerp(DRINK_HIGHLIGHT, 0.18 + wave * 0.82)
	var semantic_wave := sin((ratio * 2.0 - _phase * 0.7) * TAU) * 0.5 + 0.5
	semantic_wave = semantic_wave * semantic_wave * (3.0 - 2.0 * semantic_wave)
	var green := MELD_BASE.lerp(MELD_HIGHLIGHT, 0.25 + wave * 0.75)
	var yellow := EXTEND_BASE.lerp(EXTEND_HIGHLIGHT, 0.25 + wave * 0.75)
	return green.lerp(yellow, semantic_wave)


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
