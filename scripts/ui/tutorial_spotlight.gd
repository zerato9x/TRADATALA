class_name TutorialSpotlight
extends Control

const DIM_COLOR := Color("#020302b5")
const BORDER_COLOR := Color("#f5bf42")

var target_rect := Rect2()
var targets: Array[Control] = []


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_process(false)


func set_targets(value: Array[Control]) -> void:
	targets.clear()
	for control in value:
		if is_instance_valid(control):
			targets.append(control)
	visible = not targets.is_empty()
	set_process(visible)
	_refresh_target_rect()


func _process(_delta: float) -> void:
	_refresh_target_rect()


func _refresh_target_rect() -> void:
	var combined := Rect2()
	for control in targets:
		if not is_instance_valid(control) or not control.is_visible_in_tree():
			continue
		var global_rect := control.get_global_rect()
		var local_position := get_global_transform_with_canvas().affine_inverse() * global_rect.position
		var local_rect := Rect2(local_position, global_rect.size)
		combined = local_rect if not combined.has_area() else combined.merge(local_rect)
	target_rect = combined.grow(9.0).intersection(Rect2(Vector2.ZERO, size)) if combined.has_area() else Rect2()
	visible = target_rect.has_area()
	queue_redraw()


func _draw() -> void:
	if not target_rect.has_area():
		return
	var full := Rect2(Vector2.ZERO, size)
	var top_height := maxf(target_rect.position.y, 0.0)
	var bottom_y := minf(target_rect.end.y, full.size.y)
	draw_rect(Rect2(0, 0, full.size.x, top_height), DIM_COLOR)
	draw_rect(Rect2(0, bottom_y, full.size.x, maxf(full.size.y - bottom_y, 0.0)), DIM_COLOR)
	draw_rect(Rect2(0, target_rect.position.y, maxf(target_rect.position.x, 0.0), target_rect.size.y), DIM_COLOR)
	draw_rect(Rect2(target_rect.end.x, target_rect.position.y, maxf(full.size.x - target_rect.end.x, 0.0), target_rect.size.y), DIM_COLOR)
	draw_style_box(PresentationTheme.panel_style(Color.TRANSPARENT, BORDER_COLOR, 3, 8, 4), target_rect)
