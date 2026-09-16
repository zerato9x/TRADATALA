extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var packed := load("res://scenes/match.tscn") as PackedScene
	var scene := packed.instantiate()
	root.add_child(scene)
	await process_frame
	var title := scene.get_node("TitleScreen/TitleDisc") as Control
	assert(title != null and title.visible, "Opening title is visible")
	await create_timer(2.2).timeout
	if "--capture-title" in OS.get_cmdline_user_args():
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://.godot/title_disc_preview.png")
	var click := InputEventMouseButton.new()
	click.button_index = MOUSE_BUTTON_LEFT
	click.pressed = true
	click.position = Vector2(640, 360)
	root.push_input(click, true)
	assert(title.leaving, "Click anywhere dismisses the title")
	await create_timer(0.6).timeout
	assert(not is_instance_valid(title), "Title retires after its fade")
	assert(scene.menu_layer.visible and not scene.game_started, "Continue opens menu without starting a game")
	var keyboard_title := load("res://scripts/ui/title_disc.gd").new() as Control
	scene.get_node("TitleScreen").add_child(keyboard_title)
	keyboard_title.owner = scene
	await process_frame
	var key := InputEventKey.new()
	key.keycode = KEY_SPACE
	key.pressed = true
	root.push_input(key, true)
	assert(keyboard_title.leaving, "Keyboard can continue")
	await create_timer(0.6).timeout
	scene.queue_free()
	await process_frame
	print("TITLE_DISC_SMOKE passed")
	quit()