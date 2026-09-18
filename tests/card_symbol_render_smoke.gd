extends SceneTree

var failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	root.size = Vector2i(1280, 720)
	var background := ColorRect.new()
	background.color = Color("#174d61")
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_child(background)
	var card_view := PlayingCardView.new()
	card_view.position = Vector2(277, 116)
	root.add_child(card_view)
	card_view.set_card(CardData.new("symbol_render_9_clubs", "9", 9, "Clubs", 9))
	card_view.set_meld_chance(1.0, true, "Bộ 9", "", 0)
	card_view._on_mouse_entered()
	card_view.layout_to(Vector2(277, 116), 0.0, false)
	await process_frame
	await process_frame
	var icon := card_view.get_node_or_null("MeldChance/Content/MeldSymbol") as TextureRect
	_check(icon != null, "ready meld badge creates a straw-hat icon")
	_check(icon != null and icon.visible, "ready meld badge displays the icon")
	_check(icon != null and icon.texture != null and icon.texture.resource_path == "res://cards/symbol_meld.png", "ready meld badge uses symbol_meld.png")
	_check(icon != null and icon.material is ShaderMaterial, "ready meld badge tints the source asset through a shader")
	if DisplayServer.get_name() != "headless":
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://.godot/card-symbol-render.png")
	card_view.set_meld_chance(0.25, false, "Bộ 9", "9H", 1)
	_check(not icon.visible and card_view._meld_chance_value.text == "25%", "non-ready cards restore percentage text")
	card_view._on_mouse_exited()
	_check(not card_view._meld_chance_badge.visible, "badge hides after hover exits")
	print("CARD_SYMBOL_RENDER_SMOKE failures=%d" % failures.size())
	quit(0 if failures.is_empty() else 1)


func _check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
