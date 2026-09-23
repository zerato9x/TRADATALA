extends SceneTree

var failures: Array[String] = []

func _initialize() -> void:
	call_deferred("_run")

func check(ok: bool, message: String) -> void:
	if not ok:
		failures.append(message)
		push_error(message)

func _run() -> void:
	root.size = Vector2i(1280, 720)
	var canvas := Control.new()
	canvas.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_child(canvas)
	var bg := ColorRect.new()
	bg.color = Color("203f77")
	bg.size = Vector2(1280, 720)
	canvas.add_child(bg)
	var faces: Array[TextureRect] = []
	for row in 2:
		var caption := Label.new()
		caption.position = Vector2(24, 12 + row * 300)
		caption.text = "ORIGINAL" if row == 0 else "CLEAN / SẠCH BÓNG"
		caption.add_theme_font_override("font", PresentationTheme.official_font())
		canvas.add_child(caption)
		for column in 6:
			var face := TextureRect.new()
			face.texture = load("res://cards/" + ["ace_of_spades", "seven_of_hearts", "king_of_clubs"][column % 3] + ".png")
			face.position = Vector2(24 + column * 154, 50 + row * 300)
			face.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			face.stretch_mode = TextureRect.STRETCH_SCALE
			face.size = Vector2(114, 158) if column < 3 else Vector2(142, 197)
			face.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
			canvas.add_child(face)
			GieoCardFX.apply_properties(face, [] if column < 3 else GieoCardFX.PROPERTIES, row == 1)
			if face.material != null:
				face.material.set_shader_parameter("freeze_motion", true)
				face.material.set_shader_parameter("sample_time", 0.0)
			faces.append(face)
	await RenderingServer.frame_post_draw
	await RenderingServer.frame_post_draw
	var first := root.get_texture().get_image()
	first.save_png("res://.godot/polished-card-comparison.png")
	for column in 6:
		var face := faces[column]
		var changed := 0
		var ink_changed := 0
		for y in int(face.size.y):
			for x in int(face.size.x):
				var a := first.get_pixel(int(face.position.x) + x, int(face.position.y) + y)
				var b := first.get_pixel(int(face.position.x) + x, int(face.position.y) + y + 300)
				var delta := maxf(absf(a.r - b.r), maxf(absf(a.g - b.g), absf(a.b - b.b)))
				if delta > 0.08: changed += 1
				if column < 3 and minf(a.r, minf(a.g, a.b)) < 0.60 and delta > 0.025: ink_changed += 1
		check(changed > int(face.size.x * face.size.y * 0.04), "Polish remains visible between sweeps, variant %d" % column)
		check(ink_changed == 0, "Polish preserves printed ink, variant %d" % column)
	for face in faces:
		if face.material != null:
			face.material.set_shader_parameter("sample_time", 1.5)
	await RenderingServer.frame_post_draw
	await RenderingServer.frame_post_draw
	var later := root.get_texture().get_image()
	var moving := 0
	for y in range(350, 508):
		for x in range(24, 138):
			var a := first.get_pixel(x, y)
			var b := later.get_pixel(x, y)
			if maxf(absf(a.r - b.r), maxf(absf(a.g - b.g), absf(a.b - b.b))) > 0.08: moving += 1
	check(moving > 200, "Polish reflection visibly travels across the card")
	print("POLISHED_CARD_RENDER: ", "PASS" if failures.is_empty() else str(failures))
	quit(0 if failures.is_empty() else 1)
