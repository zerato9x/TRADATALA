extends SceneTree

func _initialize() -> void: call_deferred("_run")

func _run() -> void:
	var scene: MatchUI = load("res://scenes/match.tscn").instantiate()
	root.add_child(scene)
	await process_frame
	var title := scene.get_node("TitleScreen/TitleDisc") as Control
	assert(not title.visible, "The opening gate is removed")
	assert(scene.front_end.visible and scene.front_end.page == "home", "Home is ready on launch")
	scene.music_controller.band_pulse.emit(2, 1.0)
	assert(scene.front_end.pulse_values[2] > 0.9, "The third logo word responds to music")
	scene.queue_free()
	await process_frame
	print("TITLE_DISC_SMOKE passed")
	quit()
