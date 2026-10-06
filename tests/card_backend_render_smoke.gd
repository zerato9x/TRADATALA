extends SceneTree
## Check white card paper after GPU sampling, including the rotating hand faces.
var failures: Array[String] = []

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	if DisplayServer.get_name() == "headless":
		push_error("Card backend smoke requires a rendered window; omit --headless.")
		quit(1)
		return
	root.size = Vector2i(1280, 720)
	var background := ColorRect.new()
	background.color = Color("203f77")
	background.size = Vector2(1280, 720)
	root.add_child(background)
	var views: Array[PlayingCardView] = []
	var sources: Array[Image] = []
	for suit in DeckManager.SUITS:
		for rank in DeckManager.RANKS:
			var index := views.size()
			var card := CardData.new("render_%d" % index, rank, DeckManager.RANKS.find(rank) + 1, suit, 1)
			var view := PlayingCardView.new()
			root.add_child(view)
			view.set_card(card)
			view.layout_to(Vector2(24 + (index % 13) * 94, 26 + (index / 13) * 158), (float(index % 7) - 3.0) * 0.025, false)
			views.append(view)
			var source := Image.new()
			source.load_png_from_buffer(FileAccess.get_file_as_bytes(card.texture_path()))
			sources.append(source)
	var checks := 0
	for treatment in ["plain", "polished", "gold", "liquid"]:
		for view in views:
			view.card.shiny = treatment == "polished"
			view.card.fortune = 6 if treatment == "gold" else 0
			view.card.liquid = treatment == "liquid"
			view.card.negative = false
			view.set_card(view.card)
		for sample in [0.0, 1.5, 12.0]:
			for view in views:
				if view._texture.material != null:
					view._texture.material.set_shader_parameter("freeze_motion", true)
					view._texture.material.set_shader_parameter("sample_time", sample)
			await process_frame
			await RenderingServer.frame_post_draw
			var rendered := root.get_texture().get_image()
			var dark_paper := 0
			for index in views.size():
				var source := sources[index]
				var face := views[index]._texture
				for y in range(3, source.get_height() - 3, 3):
					for x in range(3, source.get_width() - 3, 3):
						var white := true
						for dy in range(-1, 2):
							for dx in range(-1, 2):
								var ink := source.get_pixel(x + dx, y + dy)
								white = white and minf(ink.r, minf(ink.g, ink.b)) > 0.95 and ink.a > 0.95
						if not white: continue
						var uv := Vector2((x + 0.5) / source.get_width(), (y + 0.5) / source.get_height())
						var point := face.get_global_transform_with_canvas() * (uv * face.size)
						var pixel := rendered.get_pixel(int(point.x), int(point.y))
						checks += 1
						if maxf(pixel.r, maxf(pixel.g, pixel.b)) < 0.15: dark_paper += 1
			if dark_paper > 0:
				failures.append("%s time %.1f: %d black paper samples" % [treatment, sample, dark_paper])
			rendered.save_png("res://.godot/card-backend-%s-%s.png" % [treatment, str(sample)])
	print("CARD_BACKEND_RENDER_SMOKE checks=%d failures=%d %s" % [checks, failures.size(), failures])
	quit(0 if failures.is_empty() else 1)
