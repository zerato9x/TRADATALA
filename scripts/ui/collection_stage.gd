extends Control
## Static display plinth: redraw only on resize, with no animation or input surface.
var accent := PresentationTheme.GOLD

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	resized.connect(queue_redraw)

func _draw() -> void:
	var center := size * Vector2(0.5, 0.48)
	var radius := minf(size.y * 0.40, size.x * 0.32)
	draw_circle(center, radius, Color(accent, 0.035))
	draw_arc(center, radius, 0, TAU, 72, Color(accent, 0.18), 1.0, true)
	draw_arc(center, radius + 5, -PI * 0.85, -PI * 0.15, 32, Color(accent, 0.32), 1.0, true)
	var base := Vector2(size.x * 0.5, size.y - 20)
	var half_width := minf(106, size.x * 0.36)
	draw_style_box(PresentationTheme.panel_style(Color("08191be0"), Color(accent, 0.34), 1, 8, 3), Rect2(base - Vector2(half_width, 6), Vector2(half_width * 2, 12)))
	draw_line(Vector2(16, size.y - 1), Vector2(size.x - 16, size.y - 1), Color(accent, 0.22), 1)
