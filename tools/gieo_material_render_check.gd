extends RefCounted

var changed_pixel_counts: Array[int] = []

## GPU guardrails, not a pixel-perfect appearance test. Run from the live preview:
## await load("res://tools/gieo_material_render_check.gd").new().run(get_tree().current_scene)
func run(parent: Node) -> Dictionary:
	var viewport := SubViewport.new()
	viewport.size = Vector2i(7296, 237)
	viewport.transparent_bg = true
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	parent.add_child(viewport)
	var faces: Array[TextureRect] = []
	var originals: Array[Image] = []
	for row in 3:
		var path: String = ["res://cards/ace_of_spades.png", "res://cards/seven_of_hearts.png", "res://cards/king_of_clubs.png"][row]
		var texture := load(path) as Texture2D
		originals.append(texture.get_image())
		for column in 128:
			var face := TextureRect.new()
			face.texture = texture
			face.position = Vector2(column * 57, row * 79)
			face.size = Vector2(57, 79)
			face.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
			var properties: Array[String] = []
			for index in 7:
				if column & (1 << index):
					properties.append(GieoCardFX.PROPERTIES[index])
			GieoCardFX.apply_properties(face, properties)
			if face.material != null:
				face.material.set_shader_parameter("freeze_motion", true)
			viewport.add_child(face)
			faces.append(face)
	await RenderingServer.frame_post_draw
	await RenderingServer.frame_post_draw
	var first := viewport.get_texture().get_image()
	var alpha_errors := 0
	var ink_errors := 0
	var normal_errors := 0
	var ink_samples := 0
	for row in 3:
		for column in 128:
			for y in 79:
				for x in 57:
					var source := originals[row].get_pixel(x, y)
					var target := first.get_pixel(column * 57 + x, row * 79 + y)
					if absf(source.a - target.a) > 0.01:
						alpha_errors += 1
					if source.a < 0.99:
						continue
					var delta := maxf(absf(source.r - target.r), maxf(absf(source.g - target.g), absf(source.b - target.b)))
					if column == 0 and delta > 0.02:
						normal_errors += 1
					if minf(source.r, minf(source.g, source.b)) < 0.65:
						ink_samples += 1
						if delta > 0.02:
							ink_errors += 1
	for face in faces:
		if face.material != null:
			face.material.set_shader_parameter("sample_time", 12.0)
	await RenderingServer.frame_post_draw
	await RenderingServer.frame_post_draw
	var later := viewport.get_texture().get_image()
	var moving_variants := 0
	for column in range(1, 128):
		var changes := 0
		for y in 79:
			for x in 57:
				if _color_delta(first.get_pixel(column * 57 + x, y), later.get_pixel(column * 57 + x, y)) > 0.004:
					changes += 1
		if changes > 20:
			moving_variants += 1
	var result := {"alpha_errors": alpha_errors, "ink_errors": ink_errors, "normal_errors": normal_errors, "ink_samples": ink_samples, "moving_variants": moving_variants, "variants": 384}
	# Each ingredient must leave visible pixels even inside every larger combination.
	var visible_ingredients := 0
	for row in 3:
		for bits in range(1, 128):
			for ingredient in 7:
				if not (bits & (1 << ingredient)):
					continue
				var without := bits & ~(1 << ingredient)
				var changed_pixels := 0
				for y in 79:
					for x in 57:
						var a := first.get_pixel(bits * 57 + x, row * 79 + y)
						var b := first.get_pixel(without * 57 + x, row * 79 + y)
						if maxf(absf(a.r - b.r), maxf(absf(a.g - b.g), absf(a.b - b.b))) > 0.02:
							changed_pixels += 1
				if changed_pixels > 15:
					visible_ingredients += 1
	result["visible_ingredients"] = visible_ingredients
	# Scrubbing proves the formula responds, not that automatic TIME advances.
	for face in faces:
		if face.material != null:
			face.material.set_shader_parameter("freeze_motion", false)
	await RenderingServer.frame_post_draw
	await RenderingServer.frame_post_draw
	var auto_first := viewport.get_texture().get_image()
	await parent.get_tree().create_timer(2.0).timeout
	await RenderingServer.frame_post_draw
	var auto_later := viewport.get_texture().get_image()
	var automatic_variants := _changed_variants(auto_first, auto_later)
	result["automatic_changed_pixels"] = changed_pixel_counts.duplicate()
	for face in faces:
		if face.material != null:
			face.material.set_shader_parameter("freeze_motion", true)
	await RenderingServer.frame_post_draw
	await RenderingServer.frame_post_draw
	var frozen_first := viewport.get_texture().get_image()
	await parent.get_tree().create_timer(0.3).timeout
	await RenderingServer.frame_post_draw
	var frozen_later := viewport.get_texture().get_image()
	var frozen_changes := _changed_variants(frozen_first, frozen_later)
	result["automatic_variants"] = automatic_variants
	result["frozen_changes"] = frozen_changes
	result["passed"] = alpha_errors == 0 and ink_errors == 0 and normal_errors == 0 and moving_variants == 127 and automatic_variants == 127 and frozen_changes == 0 and visible_ingredients == 1344
	viewport.queue_free()
	return result

func _changed_variants(first: Image, later: Image) -> int:
	var changed := 0
	changed_pixel_counts.clear()
	for column in range(1, 128):
		var pixels := 0
		for y in 79:
			for x in 57:
				if _color_delta(first.get_pixel(column * 57 + x, y), later.get_pixel(column * 57 + x, y)) > 0.004:
					pixels += 1
		changed_pixel_counts.append(pixels)
		if pixels > 20:
			changed += 1
	return changed

func _color_delta(a: Color, b: Color) -> float:
	return maxf(absf(a.r - b.r), maxf(absf(a.g - b.g), absf(a.b - b.b)))
