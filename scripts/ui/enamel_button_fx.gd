extends Control
## Edge-only polish: the Button keeps its geometry, focus, input and caption.
var accent := Color("f5bf42")
var _button: Button
var _hover := 0.0
var _target := 0.0

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	focus_mode = Control.FOCUS_NONE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_button = get_parent() as Button
	_button.mouse_entered.connect(_refresh)
	_button.mouse_exited.connect(_refresh)
	_button.focus_entered.connect(_refresh)
	_button.focus_exited.connect(_refresh)
	_button.button_down.connect(queue_redraw)
	_button.button_up.connect(queue_redraw)
	resized.connect(queue_redraw)
	visibility_changed.connect(_refresh)
	set_process(false)

func _refresh() -> void:
	if not is_visible_in_tree():
		_hover = 0.0
		_target = 0.0
		set_process(false)
		return
	_target = 1.0 if not _button.disabled and (_button.is_hovered() or _button.has_focus()) else 0.0
	set_process(true)

func _process(delta: float) -> void:
	if not is_visible_in_tree(): return
	if _button.disabled: _target = 0.0
	_hover = move_toward(_hover, _target, delta * 7.0)
	queue_redraw()
	if is_equal_approx(_hover, _target): set_process(false)

func _draw() -> void:
	if _button == null or _button.disabled or size.x < 24: return
	var down := _button.is_pressed()
	var inset := 3.0 if down else 2.0
	draw_line(Vector2(5, inset), Vector2(size.x - 5, inset), Color(1, 0.95, 0.79, 0.12 + _hover * 0.16), 1)
	draw_line(Vector2(4, size.y - 4), Vector2(size.x - 4, size.y - 4), Color(0.015, 0.025, 0.025, 0.4), 1)
	if _hover > 0.01:
		var length := lerpf(5, minf(40, size.x * 0.22), _hover)
		draw_line(Vector2(7, size.y - 7), Vector2(7 + length, size.y - 7), Color(accent, _hover * 0.8), 2)
