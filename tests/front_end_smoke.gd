extends SceneTree

var failures: Array[String] = []

func _initialize() -> void:
	call_deferred("_run")

func check(value: bool, message: String) -> void:
	if not value: failures.append(message)

func _run() -> void:
	root.size = Vector2i(1280, 720)
	var scene: MatchUI = load("res://scenes/match.tscn").instantiate()
	root.add_child(scene)
	current_scene = scene
	await process_frame
	scene.run_save = RunSave.new("user://front-end-smoke-%d.save" % Time.get_ticks_usec())
	scene.drink_manager.progress.save_path = ""
	scene.campaign.difficulty_progress = preload("res://scripts/campaign/difficulty_progress.gd").new("")
	var front := scene.front_end
	front.show_home()
	check(front.page == "home" and front.visible, "home opens directly")
	check(not scene.get_node("TitleScreen/TitleDisc").visible, "opening gate is absent")
	front.show_setup()
	check(front.draft.music_system == scene.settings.music_system, "music inherits settings")
	check(front.draft.difficulty == 1, "fresh setup begins at difficulty one")
	check(front.footer.get_global_rect().end.y <= root.size.y, "start bar fits")
	front._change_difficulty(1)
	check(front.draft.difficulty == 1, "locked difficulty cannot be selected")
	front.customizing = true
	front._render_setup()
	front.draft.seed = "FRONT-END-SEED"
	front.go_back()
	check(not front.customizing and front.draft.seed == "FRONT-END-SEED", "drawer close retains draft")
	front.go_back()
	front.show_setup()
	check(front.draft.seed.is_empty(), "leaving setup discards draft")
	front._start_pressed()
	await create_timer(1.0).timeout
	check(scene.game_started and not scene.campaign.run_seed.is_empty(), "start works without music selection")
	# Capture a live save to exercise Home, replacement, and Continue navigation.
	scene.run_save.save_run(scene.campaign, scene.deal, scene._music_checkpoint())
	front.show_home()
	check(not front.saved.is_empty(), "home discovers saved run")
	front.show_setup()
	front._start_pressed()
	check(front.confirming and not front.busy, "replacement first opens confirmation")
	front.go_back()
	check(not front.confirming and front.page == "setup", "cancel keeps setup")
	front.show_collections()
	check(front.page == "collections" and front.selected_collection == DrinkCatalog.TRA_DA, "drinks collection opens")
	front.collection_tab = "zodiac"
	front._render_collections()
	check(not front.selected_collection.is_empty(), "zodiac progress opens")
	for message in failures: push_error(message)
	print("FRONT_END_SMOKE failures=%d" % failures.size())
	scene.music_controller._stop_all_mix_players()
	scene.music_controller.music_director.stop()
	scene.queue_free()
	await process_frame
	quit(0 if failures.is_empty() else 1)
