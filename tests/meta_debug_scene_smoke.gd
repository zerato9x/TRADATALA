extends SceneTree
## Production menu paths, sandbox isolation, and independent-process resume.
var scene: MatchUI
var checks := 0
var failures: Array[String] = []

func _initialize() -> void: call_deferred("_run")

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok: failures.append(message); push_error(message)

func frames(count: int = 3) -> void:
	for _i in count: await process_frame

func click(control: Control) -> void:
	await frames()
	var point := control.get_global_transform_with_canvas() * (control.size * 0.5)
	for pressed in [true, false]:
		var event := InputEventMouseButton.new()
		event.button_index = MOUSE_BUTTON_LEFT
		event.position = point
		event.global_position = point
		event.pressed = pressed
		root.push_input(event, true)
		await process_frame

func choose(id: String, value: String) -> void:
	var dropdown := scene.front_end.pages.boss_lab.find_child(id, true, false) as OptionButton
	check(dropdown != null, "debug control exists: " + id)
	for index in dropdown.item_count:
		if String(dropdown.get_item_metadata(index)) == value:
			dropdown.select(index)
			dropdown.item_selected.emit(index)
			await frames()
			return
	check(false, "debug choice exists: " + value)

func ready_to_play() -> void:
	var deadline := Time.get_ticks_msec() + 3500
	while scene.interaction_locked and Time.get_ticks_msec() < deadline: await process_frame
	check(not scene.interaction_locked, "debug encounter releases actual gameplay input")

func capture(label: String) -> void:
	if DisplayServer.get_name() == "headless": return
	await create_timer(0.25).timeout
	await RenderingServer.frame_post_draw
	DirAccess.make_dir_recursive_absolute("res://.godot/meta-debug-validation/screens")
	root.get_texture().get_image().save_png("res://.godot/meta-debug-validation/screens/%s.png" % label)

func _run() -> void:
	root.size = Vector2i(1280, 720)
	scene = load("res://scenes/match.tscn").instantiate() as MatchUI
	root.add_child(scene)
	current_scene = scene
	await frames()
	if "--resume-only" in OS.get_cmdline_user_args():
		await _resume()
	else:
		await _write()
	scene.queue_free()
	await process_frame
	print("META_DEBUG_SCENE_SMOKE checks=%d failures=%d mode=%s" % [checks, failures.size(), "fresh-read" if "--resume-only" in OS.get_cmdline_user_args() else "write"])
	quit(0 if failures.is_empty() else 1)

func _write() -> void:
	var front := scene.front_end
	check(scene.save_files.active_slot == 1, "default permanent file is File 1")
	check(scene.run_save.path == scene.save_files.run_path(1), "normal checkpoint uses its profile path")
	var file_nav := front.pages.home.find_child("SaveFiles", true, false) as Button
	await click(file_nav)
	check(front.page == "files", "real Save Files navigation opens")
	check(front.pages.files.find_children("SaveFile_*", "Button", true, false).size() == 3, "three profile buttons are available")
	await capture("save_files_en")
	front.show_home()
	front.show_setup()
	front.draft.seed = "REAL-SAVE-PRESERVED"
	front.start_requested.emit(front.draft.copy())
	await create_timer(1.1).timeout
	check(scene.game_started, "normal run starts before sandbox")
	scene.drink_manager.progress.add_progress("melds", 5)
	scene.campaign.difficulty_progress.complete_week(1)
	scene.campaign.zodiac.progress.commit("cat", "real-cat", {}, ["emblem_unlocked"])
	scene.campaign.deal_reports.append({"details": {"actions": [{"action": "extension", "meld_type": "run", "points": 25, "earned_vnd": 70_000}]}})
	scene._flush_run_save()
	var original := scene.run_save.load_run()
	var normal_path := scene.run_save.path
	var tutorial_done: bool = scene.settings.tutorial_completed
	scene._open_boss_lab()
	await frames()
	check(front.page == "boss_lab" and scene.menu_layer.visible, "F9 route can open the lab from a normal run")
	check(front.footer.get_global_rect().end.y <= root.size.y, "debug start footer fits 720p")
	await choose("Boss", "snake")
	await choose("BossDifficulty", "3")
	await choose("BossPhase", "2")
	await choose("BossDrink", DrinkCatalog.NUOC_VOI)
	await capture("boss_lab_snake_en")
	await click(front.footer.find_child("StartBossTest", true, false) as Button)
	await ready_to_play()
	check(scene.boss_debug_active and scene.save_files.suspended, "boss sandbox detaches permanent saves")
	check(scene.deal.zodiac_boss.id == "snake" and scene.deal.zodiac_boss.difficulty == 3, "selected Snake and tier reached real game")
	check(scene.deal.current_phase == 2 and scene.deal.current_drink_id == DrinkCatalog.NUOC_VOI, "phase and drink applied")
	check(scene.deal.physical_card_accounting_is_valid(), "debug opening uses all 52 real cards")
	check(scene.run_save.path == BossDebugSession.SAVE_PATH and scene.run_save.path != normal_path, "debug checkpoint path is separate")
	check(not scene.boss_debug_toolbar.get_global_rect().intersects(scene.zodiac_boss_hud.panel.get_global_rect()), "debug controls stay clear of boss rule HUD")
	var normal_bytes := FileAccess.get_file_as_bytes(normal_path)
	var meta_bytes := FileAccess.get_file_as_bytes(scene.save_files.meta_path())
	var state := scene.deal.zodiac_boss.snapshot()
	var ids := scene.deal.hand.map(func(card): return card.unique_id)
	scene.campaign.zodiac.progress.commit("dragon", "debug-win", {"pleased_victories": 99}, ["emblem_unlocked", "ending_rong_ran_len_may"])
	scene.drink_manager.progress.add_progress("runs", 10)
	scene.campaign.difficulty_progress.complete_week(1)
	scene._flush_run_save()
	await create_timer(0.15).timeout
	check(FileAccess.get_file_as_bytes(normal_path) == normal_bytes, "debug saves never rewrite normal run")
	check(FileAccess.get_file_as_bytes(scene.save_files.meta_path()) == meta_bytes, "debug achievements never rewrite permanent file")
	check(scene.settings.tutorial_completed == tutorial_done, "late-week boss testing cannot complete real tutorial")
	check(not scene.strawy.surface.visible, "tutorial helper does not open in sandbox")
	await capture("boss_debug_snake_en")
	scene._replay_boss_debug()
	await ready_to_play()
	check(scene.deal.zodiac_boss.snapshot() == state, "Replay repeats exact seeded boss state")
	check(scene.deal.hand.map(func(card): return card.unique_id) == ids, "Replay repeats physical opening")
	for boss: String in ZodiacBossRule.RULES:
		for tier in [1, 2, 3]:
			check(scene._start_boss_debug({"boss": boss, "difficulty": tier, "phase": 2, "seed": "UI-ALL-BOSSES"}), "actual UI starts %s tier %d" % [boss, tier])
			scene.event_table._finish_event_exit()
			await frames(1)
			check(scene.deal.zodiac_boss.id == boss and scene.deal.zodiac_boss.difficulty == tier, "actual selected runtime %s %d" % [boss, tier])
			check(scene.deal.physical_card_accounting_is_valid(), "actual UI physical zones %s %d" % [boss, tier])
			for locale in ["en", "vi"]:
				TranslationServer.set_locale(locale)
				scene._on_locale_changed(locale)
				await frames(2)
				check(not scene.boss_debug_toolbar.get_global_rect().intersects(scene.zodiac_boss_hud.panel.get_global_rect()), "localized debug controls fit %s %d %s" % [boss, tier, locale])
	check(FileAccess.get_file_as_bytes(scene.save_files.meta_path()) == meta_bytes, "all 36 encounters preserve permanent file")
	scene._leave_boss_debug()
	await frames()
	check(not scene.boss_debug_active and not scene.save_files.suspended and front.page == "home", "Exit returns to normal profile Home")
	check(scene.drink_manager.progress.is_unlocked(DrinkCatalog.NUOC_VOI) and scene.campaign.zodiac.progress.owns("cat"), "normal unlocks retained after sandbox")
	check(not scene.campaign.zodiac.progress.owns("dragon") and scene.campaign.difficulty_progress.unlocked == 2, "debug unlocks did not leak into normal providers")
	check(front.saved.campaign.run_seed == original.campaign.run_seed, "Home still offers original normal run")
	check(not scene._resume_saved_run(RunSave.new(BossDebugSession.SAVE_PATH).load_run()), "normal Continue rejects a sandbox checkpoint")
	front.show_save_files()
	await click(front.pages.files.find_child("SaveFile_2", true, false) as Button)
	check(scene.save_files.active_slot == 2 and scene.campaign.difficulty_progress.unlocked == 1, "real profile button loads independent File 2")
	check(not scene.drink_manager.progress.is_unlocked(DrinkCatalog.NUOC_VOI), "File 2 starts without File 1 drink unlocks")
	check(scene._start_boss_debug({"boss": "dragon", "dragon_tactic": "history"}), "Dragon can test a newly selected file before Continue")
	await ready_to_play()
	check(scene._debug_history.is_empty() and scene.deal.zodiac_boss.data.analysis.legacy_fallback, "Dragon never inherits another file's action history")
	scene._leave_boss_debug()
	front.show_save_files()
	var name := front.pages.files.find_child("SaveFileName", true, false) as LineEdit
	name.text = "Tester Two"
	await click(front.pages.files.find_child("SaveFileRename", true, false) as Button)
	check(scene.save_files.data.name == "Tester Two", "rename button persists active file name")
	TranslationServer.set_locale("vi")
	scene._on_locale_changed("vi")
	front.show_save_files()
	await frames()
	await capture("save_files_vi")
	front.show_home()
	front.show_setup()
	front.draft.seed = "SECOND-PROFILE"
	front.start_requested.emit(front.draft.copy())
	await create_timer(1.1).timeout
	scene.drink_manager.progress.add_progress("runs", 10)
	scene._flush_run_save()
	scene._open_boss_lab()
	front.boss_options = BossDebugSession.normalize({"boss": "dragon", "difficulty": 3, "phase": 2, "seed": "FRESH-DEBUG", "dragon_tactic": "new_meld:set", "dragon_average_vnd": 80_000})
	front.show_boss_lab()
	await frames()
	await capture("boss_lab_dragon_vi")
	await click(front.footer.find_child("StartBossTest", true, false) as Button)
	await ready_to_play()
	check(scene.deal.zodiac_boss.data.analysis.target_vnd == 96_000, "explicit debug Dragon target respects difficulty")
	scene._flush_run_save()
	scene._leave_boss_debug()
	check(scene.run_save.load_run().campaign.run_seed == "SECOND-PROFILE", "normal File 2 run retained beside debug checkpoint")
	check(RunSave.new(scene.save_files.run_path(1)).load_run().campaign.run_seed == "REAL-SAVE-PRESERVED", "File 1 run retained after switching profiles")

func _resume() -> void:
	check(scene.save_files.active_slot == 2, "fresh process reloads last selected File 2")
	check(scene.save_files.data.name == "Tester Two", "fresh process reloads profile name")
	check(scene.drink_manager.progress.is_unlocked(DrinkCatalog.C2_ICED_TEA), "fresh process restores permanent unlock")
	check(scene.front_end.saved.campaign.run_seed == "SECOND-PROFILE", "fresh Home discovers selected normal checkpoint")
	var checkpoint := RunSave.new(BossDebugSession.SAVE_PATH).load_run()
	var ids: Array = checkpoint.deal.hand.map(func(card): return card.unique_id)
	scene.front_end.show_boss_lab()
	await click(scene.front_end.footer.find_child("ResumeBossTest", true, false) as Button)
	await ready_to_play()
	check(scene.boss_debug_active and scene.deal.zodiac_boss.id == "dragon", "real Resume Test button restores sandbox")
	check(scene.deal.zodiac_boss.difficulty == 3 and scene.deal.current_phase == 2, "fresh debug difficulty and phase retained")
	check(scene.campaign.debug_context.options.seed == "FRESH-DEBUG", "fresh debug seed retained")
	check(scene.deal.hand.map(func(card): return card.unique_id) == ids, "fresh debug physical hand is exact")
	check(scene.deal.zodiac_boss.rng.state == int(checkpoint.deal.zodiac_boss.rng), "fresh boss RNG resumes exactly")
	check(scene.deal.physical_card_accounting_is_valid(), "fresh debug card zones are valid")
	scene._leave_boss_debug()
	await frames()
	await click(scene.front_end.home_body.get_child(0) as Button)
	await frames()
	check(not scene.boss_debug_active and scene.campaign.run_seed == "SECOND-PROFILE", "normal Continue returns to File 2 after debug resume")
