extends Control
## A static felt sorting tray under the existing archive controls.
var _felt: StyleBoxFlat

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_felt = PresentationTheme.panel_style(Color("183c3e"), Color("638375"), 1, 3)
	resized.connect(queue_redraw)

func _draw() -> void:
	draw_style_box(_felt, Rect2(Vector2(9, 9), size - Vector2(18, 18)))
	# A stitched inset and a few fixed wear marks, without noise or idle animation.
	draw_rect(Rect2(Vector2(14, 14), size - Vector2(28, 28)), Color("99aa8630"), false, 1)
	for x in [5.0, size.x - 5.0]:
		for y in [6.0, size.y - 6.0]:
			draw_circle(Vector2(x, y + 1), 2.5, Color("081015"))
			draw_circle(Vector2(x, y), 1.8, Color("bf9d69"))
			draw_line(Vector2(x - 1, y), Vector2(x + 1, y), Color("55432e"), 1)
	for index in 9:
		var x := 36.0 + index * (size.x - 72) / 9.0
		draw_line(Vector2(x, size.y - 5), Vector2(x + 8, size.y - 5), Color("bc956d38"), 1)
