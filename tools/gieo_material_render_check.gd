extends RefCounted
## GPU invariants for every Fortune x Jackpot combination on real existing faces.
func run(parent: Node) -> Dictionary:
	var viewport := SubViewport.new()
	viewport.size = Vector2i(52 * 57, 3 * 79)
	viewport.transparent_bg = true
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	parent.add_child(viewport)
	var faces: Array[TextureRect] = []
	var originals: Array[Image] = []
	var index_prints: Array[Image] = []
	for row in 3:
		var path: String = ["res://cards/ace_of_spades.png", "res://cards/seven_of_hearts.png", "res://cards/king_of_clubs.png"][row]
		var texture := load(path) as Texture2D
		originals.append(texture.get_image())
		index_prints.append(GieoCardFX.index_print(texture).get_image())
		for fortune in range(-6, 7):
			for bits in 4:
				var column := (fortune + 6) * 4 + bits
				var face := TextureRect.new()
				face.texture = texture
				face.position = Vector2(column * 57, row * 79)
				face.size = Vector2(57, 79)
				face.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
				GieoCardFX.apply_state(face, fortune, bits & 1 != 0, bits & 2 != 0)
				if face.material != null:
					face.material.set_shader_parameter("freeze_motion", true)
					face.material.set_shader_parameter("sample_time", 0.0)
				viewport.add_child(face)
				faces.append(face)
	await RenderingServer.frame_post_draw
	await RenderingServer.frame_post_draw
	var first := viewport.get_texture().get_image()
	first.save_png("res://.godot/fortune-validation/fortune-all-states.png")
	var alpha_errors := 0
	var ink_errors := 0
	var normal_errors := 0
	var coverage: Array[int] = []
	for column in 52: coverage.append(0)
	for row in 3:
		for column in 52:
			var bits := column % 4
			for y in 79:
				for x in 57:
					var source := originals[row].get_pixel(x, y)
					var target := first.get_pixel(column * 57 + x, row * 79 + y)
					if absf(source.a - target.a) > 0.01: alpha_errors += 1
					if source.a < 0.99: continue
					var delta := _color_delta(source, target)
					if column == 24 and delta > 0.02: normal_errors += 1
					if bits < 2 and index_prints[row].get_pixel(x,y).g < 0.5 and minf(source.r, minf(source.g, source.b)) < 0.60 and delta > 0.025: ink_errors += 1
					if row == 0 and minf(source.r,minf(source.g,source.b)) > 0.95 and delta > 0.12: coverage[column] += 1
	for face in faces:
		if face.material != null: face.material.set_shader_parameter("sample_time", 12.0)
	await RenderingServer.frame_post_draw
	await RenderingServer.frame_post_draw
	var later := viewport.get_texture().get_image()
	# At Fortune zero, Negative is exactly the moving Liquid photograph inverted.
	var inverse_errors := 0
	var inverse_samples := 0
	for rendered in [first, later]:
		for row in 3:
			for y in range(24, 55):
				for x in range(13, 44):
					var flowing: Color = rendered.get_pixel(25*57+x,row*79+y)
					var inverted: Color = rendered.get_pixel(26*57+x,row*79+y)
					var expected := Color(0.93-flowing.r*0.92,0.97-flowing.g*0.92,1.0-flowing.b*0.92)
					inverse_samples += 1
					if _color_delta(inverted,expected) > 0.012: inverse_errors += 1
	var dynamic_failures := 0
	var negative_dynamic_failures := 0
	var negative_variants_checked := 0
	for column in 52:
		var fortune := int(column / 4) - 6
		var bits := column % 4
		if fortune <= 0 and bits == 0: continue # Unmodified paper and matte Ink are static; every jackpot moves.
		if bits == 2: negative_variants_checked += 1
		var changes := 0
		for y in 79:
			for x in 57:
				if _color_delta(first.get_pixel(column*57+x,y), later.get_pixel(column*57+x,y)) > 0.012: changes += 1
		if changes < 12:
			dynamic_failures += 1
			if bits == 2: negative_dynamic_failures += 1
	# Tattoo coverage must grow at each magnitude; full coverage exceeds half the face.
	var coverage_errors := 0
	for sign_value in [-1, 1]:
		var previous := 0
		for magnitude in range(1, 7):
			var column: int = (sign_value * magnitude + 6) * 4
			if coverage[column] <= previous: coverage_errors += 1
			previous = coverage[column]
		if previous < 1600: coverage_errors += 1
	for face in faces:
		if face.material != null: face.material.set_shader_parameter("freeze_motion", false)
	await RenderingServer.frame_post_draw
	await RenderingServer.frame_post_draw
	var auto_first := viewport.get_texture().get_image()
	await parent.get_tree().create_timer(0.65).timeout
	await RenderingServer.frame_post_draw
	var auto_later := viewport.get_texture().get_image()
	var automatic_pixels := _changed_pixels(auto_first, auto_later)
	for face in faces:
		if face.material != null: face.material.set_shader_parameter("freeze_motion", true)
	await RenderingServer.frame_post_draw
	await RenderingServer.frame_post_draw
	var frozen_first := viewport.get_texture().get_image()
	await parent.get_tree().create_timer(0.1).timeout
	await RenderingServer.frame_post_draw
	var frozen_changes := _changed_pixels(frozen_first, viewport.get_texture().get_image())
	var result := {"variants": 156, "alpha_errors": alpha_errors, "ink_errors": ink_errors, "normal_errors": normal_errors,
		"dynamic_failures": dynamic_failures, "negative_dynamic_failures": negative_dynamic_failures,
		"negative_variants_checked": negative_variants_checked, "inverse_errors": inverse_errors, "inverse_samples": inverse_samples,
		"coverage_errors": coverage_errors, "coverage": coverage,
		"automatic_pixels": automatic_pixels, "frozen_changes": frozen_changes}
	result["passed"] = alpha_errors == 0 and ink_errors == 0 and normal_errors == 0 and dynamic_failures == 0 and inverse_errors == 0 and coverage_errors == 0 and automatic_pixels > 200 and frozen_changes == 0
	viewport.queue_free()
	var indices := await _check_indices(parent)
	result.merge(indices)
	result["passed"] = result.passed and indices.index_contrast_errors == 0 and indices.index_red_errors == 0 and indices.corner_surface_errors == 0 and indices.corner_motion_errors == 0 and indices.missing_indices == 0
	return result

func _check_indices(parent: Node) -> Dictionary:
	# All 52 physical identities at the smallest production table size, including 10.
	const SIZE := Vector2i(49, 68)
	const TREATMENTS := [[0,true,false],[0,false,true],[0,true,true],[6,false,false],[-6,false,false],[6,true,true],[-6,true,true],[6,false,true]]
	var viewport := SubViewport.new()
	viewport.size = Vector2i(13*SIZE.x, 32*SIZE.y)
	viewport.transparent_bg = true
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	parent.add_child(viewport)
	var faces: Array[TextureRect] = []
	var masks: Array[Image] = []
	var sources: Array[Image] = []
	for suit in DeckManager.SUITS:
		for rank in DeckManager.RANKS:
			var card := CardData.new("index_%s_%s" % [suit,rank],rank,DeckManager.RANKS.find(rank)+1,suit,1)
			var texture := load(card.texture_path()) as Texture2D
			masks.append(GieoCardFX.index_print(texture).get_image())
			sources.append(texture.get_image())
			for treatment in TREATMENTS.size():
				var face := TextureRect.new()
				face.texture = texture
				face.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
				face.size = SIZE
				face.position = Vector2((faces.size()%13)*SIZE.x,floori(faces.size()/13.0)*SIZE.y)
				GieoCardFX.apply_state(face,TREATMENTS[treatment][0],TREATMENTS[treatment][1],TREATMENTS[treatment][2])
				face.material.set_shader_parameter("freeze_motion",true)
				face.material.set_shader_parameter("sample_time",0.0)
				viewport.add_child(face)
				faces.append(face)
	await RenderingServer.frame_post_draw
	await RenderingServer.frame_post_draw
	var first := viewport.get_texture().get_image()
	var contrast_errors := 0
	var red_errors := 0
	var surface_errors := 0
	var motion_errors := 0
	var missing := 0
	var glyph_samples := 0
	var details: Array[String] = []
	for sample in [0.0,1.5,12.0]:
		for face in faces: face.material.set_shader_parameter("sample_time",sample)
		await RenderingServer.frame_post_draw
		await RenderingServer.frame_post_draw
		var rendered := viewport.get_texture().get_image()
		for index in faces.size():
			var mask := masks[int(index/TREATMENTS.size())]
			var source := sources[int(index/TREATMENTS.size())]
			var origin := Vector2i(faces[index].position)
			var glyph_count := [0,0]
			var paper_count := [0,0]
			var treated_count := [0,0]
			var moving_count := [0,0]
			var treatment: Array = TREATMENTS[index%TREATMENTS.size()]
			for y in SIZE.y:
				for x in SIZE.x:
					var point := Vector2i(x,y)
					var uv := (Vector2(point)+Vector2(0.5,0.5))/Vector2(SIZE)
					var source_point := Vector2i(uv*Vector2(source.get_size()))
					var channel := mask.get_pixelv(source_point)
					var pixel := rendered.get_pixelv(origin+point)
					var side := 0 if y < SIZE.y/2 else 1
					if channel.r > 0.5:
						glyph_count[side] += 1
						glyph_samples += 1
						if channel.b > 0.5 and pixel.r < pixel.g+0.10: red_errors += 1
						var contrast := 1.0
						for dy in range(-2,3):
							for dx in range(-2,3):
								var neighbor := point+Vector2i(dx,dy)
								if neighbor.x < 0 or neighbor.y < 0 or neighbor.x >= SIZE.x or neighbor.y >= SIZE.y: continue
								var mask_point := Vector2i((Vector2(neighbor)+Vector2(0.5,0.5))*Vector2(source.get_size())/Vector2(SIZE))
								var border := mask.get_pixelv(mask_point)
								if border.r > 0.5 or border.g < 0.5: continue
								contrast = maxf(contrast,_contrast(pixel,rendered.get_pixelv(origin+neighbor)))
						if contrast < 3.0:
							contrast_errors += 1
							if details.size() < 8: details.append("face=%d state=%d time=%.1f glyph=%s contrast=%.2f" % [index/8,index%8,sample,point,contrast])
					elif channel.g < 0.5:
						# Paper between the original glyph strokes must carry the material.
						var label_uv := uv if side == 0 else Vector2.ONE-uv
						if label_uv.x < 0.027 or label_uv.x > 0.245 or label_uv.y < 0.038 or label_uv.y > 0.31: continue
						var original := source.get_pixelv(source_point)
						if original.a < 0.99 or minf(original.r,minf(original.g,original.b)) < 0.95: continue
						paper_count[side] += 1
						if _color_delta(original,pixel) > 0.04: treated_count[side] += 1
						if _color_delta(first.get_pixelv(origin+point),pixel) > 0.012: moving_count[side] += 1
			for side in 2:
				if glyph_count[side] < 20: missing += 1
				if treated_count[side] < paper_count[side]*0.70: surface_errors += 1
				if sample == 12.0 and (treatment[1] or treatment[2]) and moving_count[side] < 3: motion_errors += 1
	viewport.queue_free()
	return {"index_variants":faces.size(),"index_times":3,"index_glyph_samples":glyph_samples,"index_contrast_errors":contrast_errors,"index_red_errors":red_errors,"corner_surface_errors":surface_errors,"corner_motion_errors":motion_errors,"missing_indices":missing,"index_error_details":details}

func _contrast(a: Color, b: Color) -> float:
	var x := _luminance(a)
	var y := _luminance(b)
	return (maxf(x,y)+0.05)/(minf(x,y)+0.05)

func _luminance(color: Color) -> float:
	var linear := color.srgb_to_linear()
	return linear.r*0.2126+linear.g*0.7152+linear.b*0.0722

func _changed_pixels(first: Image, later: Image) -> int:
	var changed := 0
	for y in first.get_height():
		for x in first.get_width():
			if _color_delta(first.get_pixel(x,y),later.get_pixel(x,y)) > 0.012: changed += 1
	return changed

func _color_delta(a: Color, b: Color) -> float:
	return maxf(absf(a.r-b.r),maxf(absf(a.g-b.g),absf(a.b-b.b)))
