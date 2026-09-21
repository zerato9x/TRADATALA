extends SceneTree
var failures: Array[String] = []
func _initialize() -> void: call_deferred("_run")
func check(value: bool, message: String) -> void:
	if not value: failures.append(message)
func click(button: Control) -> void:
	var point := button.get_global_transform_with_canvas() * (button.size * 0.5)
	for down in [true, false]:
		var event := InputEventMouseButton.new()
		event.button_index = MOUSE_BUTTON_LEFT
		event.pressed = down
		event.position = point
		root.push_input(event, true)
	await create_timer(0.15).timeout
func capture(name: String) -> void:
	if DisplayServer.get_name() == "headless": return
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://.godot/menu-" + name + ("-wide" if "--wide" in OS.get_cmdline_user_args() else "") + ".png")
func _run() -> void:
	root.size = Vector2i(2548, 1368) if "--wide" in OS.get_cmdline_user_args() else Vector2i(1280, 720)
	var defaults = preload("res://scripts/settings/game_settings.gd").new()
	check(defaults.locale_code == "en", "fresh settings default to English")
	defaults.free()
	var scene: MatchUI = load("res://scenes/match.tscn").instantiate()
	root.add_child(scene)
	current_scene = scene
	await create_timer(0.1).timeout
	scene.settings.set_locale("vi" if "--vietnamese" in OS.get_cmdline_user_args() else "en")
	scene.drink_manager.progress.save_path = ""
	scene.run_save = RunSave.new("user://menu-release.save")
	scene.campaign.difficulty_progress = preload("res://scripts/campaign/difficulty_progress.gd").new("")
	var title = scene.get_node("TitleScreen/TitleDisc")
	await click(title)
	await create_timer(0.9).timeout
	check(title.opened and not scene.game_started, "continue unfolds title without starting")
	await click(scene.how_to_play_button)
	check(root.has_node("GameGlossary"), "single handbook opens by pointer")
	GameGlossary.open(scene, "relics")
	await process_frame
	var book = root.get_node("GameGlossary")
	check(book._list.get_child_count() == RelicCatalog.DEFINITIONS.size(), "all relics listed")
	for button in book._list.get_children(): check(button.icon != null, "relic uses catalog sprite")
	await capture("relic-handbook")
	book.queue_free()
	await process_frame
	await click(scene.play_button)
	var run = scene._run_menu
	check(run.start_button.disabled and run.resume_button.disabled, "music choice required before play")
	check(run.difficulty_selector.is_item_disabled(1), "next difficulty is visibly locked")
	run.music_choice.select(1)
	run.music_choice.item_selected.emit(1)
	check(not run.start_button.disabled, "playlist choice enables new game")
	await capture("run-setup")
	await click(run.start_button)
	await create_timer(1.2).timeout
	check(scene.game_started and scene.settings.music_system == "playing_tracks", "new run applies chosen playlist")
	scene.campaign.current_day_index = 6
	scene.campaign.current_phase = CampaignManager.CampaignPhase.MONEY_REQUIREMENT_CHECK
	scene.deal.wallet.reset(16_000_000)
	scene.campaign.collect_day_debt()
	await create_timer(0.3).timeout
	check(scene.campaign.difficulty_progress.unlocked == 2, "Sunday unlocks difficulty two")
	check(scene.resolve_receipt._report.can_endless, "victory offers Endless")
	scene._on_receipt_continue()
	await create_timer(0.1).timeout
	check(not scene.game_started and scene.menu_layer.visible, "outcome exits to menu without restarting")
	await click(scene.play_button)
	run = scene._run_menu
	check(not run.difficulty_selector.is_item_disabled(1), "next level is selectable after exit")
	run.difficulty_selector.select(1)
	run.difficulty_selector.item_selected.emit(1)
	run.music_choice.select(2)
	run.music_choice.item_selected.emit(2)
	await click(run.start_button)
	await create_timer(1.0).timeout
	check(scene.campaign.difficulty == 2 and scene.campaign.daily_requirement() == 500_000, "chosen difficulty controls actual debt")
	check(scene.settings.music_system == "authored_dj", "authored DJ choice applies")
	scene.queue_free()
	await create_timer(0.25).timeout
	for message in failures: push_error(message)
	print("MENU_RELEASE_SMOKE failures=%d" % failures.size())
	quit(0 if failures.is_empty() else 1)
