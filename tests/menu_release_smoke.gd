extends SceneTree

var failures: Array[String] = []

func _initialize() -> void: call_deferred("_run")
func check(value: bool, message: String) -> void:
	if not value: failures.append(message)

func click(button: Button) -> void:
	var point := button.get_global_transform_with_canvas() * (button.size * 0.5)
	for down in [true, false]:
		var event := InputEventMouseButton.new()
		event.button_index = MOUSE_BUTTON_LEFT
		event.pressed = down
		event.position = point
		root.push_input(event, true)
	await create_timer(0.15).timeout

func _run() -> void:
	root.size = Vector2i(1280, 720)
	var scene: MatchUI = load("res://scenes/match.tscn").instantiate()
	root.add_child(scene)
	current_scene = scene
	await process_frame
	scene.session.run_save = RunSave.new("user://menu-release-%d.save" % Time.get_ticks_usec())
	scene.drink_manager.progress.save_path = ""
	scene.campaign.difficulty_progress = preload("res://scripts/campaign/difficulty_progress.gd").new("")
	var front := scene.front_end
	front.show_home()
	check(front.page == "home", "front end opens directly")
	front.show_setup()
	check(front.draft.difficulty == 1, "level one is selected")
	front._change_difficulty(1)
	check(front.draft.difficulty == 1, "next level is visibly locked")
	await process_frame
	await click(front.footer.get_child(front.footer.get_child_count() - 1))
	await create_timer(1.0).timeout
	check(scene.game_started and scene.campaign.difficulty == 1, "pointer starts the first run")
	scene.campaign.current_day_index = 6
	scene.campaign.current_phase = CampaignManager.CampaignPhase.MONEY_REQUIREMENT_CHECK
	scene.deal.wallet.reset(16_000_000)
	scene.campaign.collect_day_debt()
	await create_timer(0.3).timeout
	check(scene.campaign.difficulty_progress.unlocked == 2, "Sunday unlocks difficulty two")
	scene._on_receipt_continue()
	await create_timer(0.1).timeout
	check(not scene.game_started and scene.menu_layer.visible, "completed week returns to Home")
	front.show_setup()
	front._change_difficulty(1)
	check(front.draft.difficulty == 2, "unlocked level is selectable")
	front.draft.music_system = "playing_tracks"
	front._start_pressed()
	check(front.confirming, "saved run requires confirmation")
	front._start_pressed()
	await create_timer(1.0).timeout
	check(scene.campaign.difficulty == 2 and scene.campaign.daily_requirement() == 500_000, "chosen difficulty sets debt")
	check(scene.settings.music_system == "playing_tracks", "music choice applies")
	for message in failures: push_error(message)
	print("MENU_RELEASE_SMOKE failures=%d" % failures.size())
	scene.queue_free()
	await process_frame
	quit(0 if failures.is_empty() else 1)
