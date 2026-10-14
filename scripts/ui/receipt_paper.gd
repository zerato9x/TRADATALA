extends PanelContainer
## A single sheet on the table. The receipt owns all text and accounting.

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var sheet := PresentationTheme.panel_style(Color("eee0bd"), Color("9e855c"), 1, 3, 12)
	sheet.shadow_offset = Vector2(4, 10)
	sheet.shadow_color = Color("03090dc9")
	sheet.content_margin_left = 18
	sheet.content_margin_right = 18
	sheet.content_margin_top = 20
	sheet.content_margin_bottom = 14
	add_theme_stylebox_override("panel", sheet)
	resized.connect(queue_redraw)

func _draw() -> void:
	# Fixed printing imperfections, without consuming randomness or ticking every frame.
	for i in 22:
		var y := 31.0 + i * 29.0
		if y > size.y - 15: break
		draw_line(Vector2(10, y), Vector2(size.x - 10, y), Color("80550b09"), 1)
	for x in range(14, int(size.x) - 10, 13):
		draw_line(Vector2(x, size.y - 6), Vector2(x + 5, size.y - 6), Color("8b704349"), 1)
	# Two staples and a fine printer rule keep the paper recognisable at small sizes.
	for x in [size.x * 0.24, size.x * 0.76]:
		draw_line(Vector2(x - 9, 9), Vector2(x + 9, 9), Color("776b55"), 3)
		draw_line(Vector2(x - 9, 8), Vector2(x + 9, 8), Color("e9e7d7"), 1)
