class_name CafeTableBackground
extends Control


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	queue_redraw()


func _draw() -> void:
	var viewport_size := size
	draw_rect(Rect2(Vector2.ZERO, viewport_size), PresentationTheme.TABLE_DARK)
	# Layered circles create a cheap vignette without a texture dependency.
	var center := viewport_size * Vector2(0.5, 0.46)
	for index in range(14, 0, -1):
		var ratio := float(index) / 14.0
		var radius := maxf(viewport_size.x, viewport_size.y) * ratio * 0.72
		var alpha := 0.013 + (1.0 - ratio) * 0.006
		draw_circle(center, radius, Color(0.16, 0.47, 0.35, alpha))
	# A restrained woven-table pattern keeps empty areas from feeling sterile.
	for x in range(-200, int(viewport_size.x) + 200, 54):
		draw_line(Vector2(x, 96), Vector2(x + 330, viewport_size.y), Color(0.48, 0.72, 0.57, 0.018), 1.0)
	for x in range(-200, int(viewport_size.x) + 200, 54):
		draw_line(Vector2(x, viewport_size.y), Vector2(x + 330, 96), Color(0.01, 0.05, 0.04, 0.07), 1.0)
	# Top lacquer strip and warm café-light pools.
	draw_rect(Rect2(0, 0, viewport_size.x, 7), PresentationTheme.GOLD_DARK)
	draw_circle(Vector2(viewport_size.x * 0.13, 30), 210, Color(0.95, 0.65, 0.25, 0.025))
	draw_circle(Vector2(viewport_size.x * 0.88, 18), 250, Color(0.95, 0.65, 0.25, 0.02))

