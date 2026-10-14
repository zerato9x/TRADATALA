extends Control
## Decorative paper edges. The existing face, archive button and card zones keep ownership.
var count := 0
var layer_count := 0
var _face: TextureRect
var _hovered := false
var _paper: StyleBoxFlat
var _shadow: StyleBoxFlat

func configure(pile: Control, face: TextureRect, button: Button) -> void:
	name = "PileStack"
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_face = face
	position = face.position
	size = face.size
	_paper = PresentationTheme.panel_style(Color("d8d3c1"), Color("766e60"), 1, 3)
	_shadow = PresentationTheme.panel_style(Color("030a1480"), Color.TRANSPARENT, 0, 4, 3)
	pile.add_child(self)
	pile.move_child(self, 0)
	# The authored top face stays in place, with its original texture and property FX.
	for child in pile.get_children():
		if child is TextureRect and child != face: child.hide()
	button.mouse_entered.connect(_set_hover.bind(true))
	button.mouse_exited.connect(_set_hover.bind(false))
	visibility_changed.connect(func():
		if not is_visible_in_tree(): _set_hover(false)
	)

func sync(value: int) -> void:
	value = maxi(value, 0)
	_face.visible = value > 0
	if value == count: return
	count = value
	# Bounded thickness; the adjacent count remains the exact source of quantity.
	layer_count = mini(6, ceili(float(maxi(count - 1, 0)) / 7.0))
	queue_redraw()

func _set_hover(value: bool) -> void:
	if value == _hovered: return
	_hovered = value
	queue_redraw()

func _draw() -> void:
	if _paper == null: return
	var footprint := Rect2(Vector2.ZERO, size)
	if count > 0:
		var depth := Vector2(0.8, 0.9) * layer_count
		draw_style_box(_shadow, Rect2(Vector2(3, 4) + depth, size))
		for index in range(layer_count, 0, -1):
			draw_style_box(_paper, Rect2(Vector2(0.8, 0.9) * index, size))
	else:
		draw_rect(footprint, Color("05131c24"))
	# Small corner marks anchor an empty space and make the existing archive target clear.
	if count == 0 or _hovered:
		var color := Color("e3bd78d9") if _hovered else Color("e5e1c34d")
		var frame := footprint.grow(3)
		for corner in [frame.position, Vector2(frame.end.x, frame.position.y), frame.end, Vector2(frame.position.x, frame.end.y)]:
			var direction := Vector2(1 if corner.x < frame.get_center().x else -1, 1 if corner.y < frame.get_center().y else -1)
			draw_line(corner, corner + Vector2(direction.x * 12, 0), color, 1)
			draw_line(corner, corner + Vector2(0, direction.y * 12), color, 1)
