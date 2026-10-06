class_name InputHitTest
extends RefCounted
## Tests pointer positions in canvas coordinates, including clipped ancestors.
static func contains(control: Control, point: Vector2) -> bool:
	if not is_instance_valid(control) or not control.is_visible_in_tree():
		return false
	if not Rect2(Vector2.ZERO, control.size).has_point(control.get_global_transform_with_canvas().affine_inverse() * point):
		return false
	var ancestor := control.get_parent()
	while ancestor != null:
		if ancestor is Control and ancestor.clip_contents:
			if not Rect2(Vector2.ZERO, ancestor.size).has_point(ancestor.get_global_transform_with_canvas().affine_inverse() * point):
				return false
		ancestor = ancestor.get_parent()
	return true
