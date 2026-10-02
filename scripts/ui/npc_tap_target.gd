class_name NpcTapTarget
extends Button
## Mouse release activation with silhouette hit testing. Native touch is owned
## once by EventTableController, avoiding touch/emulated-mouse double activation.
var hit_texture: Texture2D:
	set(value):
		if hit_texture == value: return
		hit_texture = value
		if is_node_ready(): _rebuild_mask()
var mask: BitMap
var can_activate: Callable
var _pressed_at := Vector2.ZERO
var _mouse_down := false
var _cancelled := false

func _ready() -> void:
	button_mask = 0
	_rebuild_mask()

func _rebuild_mask() -> void:
	mask = null
	if hit_texture != null:
		var image := hit_texture.get_image()
		var factor := minf(320.0 / image.get_width(), 320.0 / image.get_height())
		image.resize(maxi(1, roundi(image.get_width() * factor)), maxi(1, roundi(image.get_height() * factor)), Image.INTERPOLATE_NEAREST)
		mask = BitMap.new()
		mask.create_from_image_alpha(image, 0.12)
		mask.grow_mask(3, Rect2i(Vector2i.ZERO, mask.get_size()))

func available() -> bool:
	return is_visible_in_tree() and not disabled and (not can_activate.is_valid() or can_activate.call())

func _has_point(point: Vector2) -> bool:
	if not Rect2(Vector2.ZERO, size).has_point(point): return false
	if mask == null: return true
	var factor := maxf(size.x / mask.get_size().x, size.y / mask.get_size().y)
	var pixel := Vector2i((point - (size - Vector2(mask.get_size()) * factor) * 0.5) / factor)
	return Rect2i(Vector2i.ZERO, mask.get_size()).has_point(pixel) and mask.get_bitv(pixel)

func hits_global(point: Vector2) -> bool:
	return available() and _has_point(get_global_transform_with_canvas().affine_inverse() * point)

func cancel_pointer() -> void:
	_mouse_down = false
	_cancelled = true

func _gui_input(event: InputEvent) -> void:
	if not available(): cancel_pointer(); return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		accept_event()
		if event.device == -1: return
		if event.pressed:
			_mouse_down = true
			_cancelled = false
			_pressed_at = get_global_transform_with_canvas() * event.position
		elif _mouse_down:
			_mouse_down = false
			if not _cancelled and _has_point(event.position): pressed.emit()
	elif event is InputEventMouseMotion and _mouse_down:
		if (get_global_transform_with_canvas() * event.position).distance_to(_pressed_at) > 12: _cancelled = true

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_WINDOW_FOCUS_OUT: cancel_pointer()
