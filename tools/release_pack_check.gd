extends SceneTree
## Runs against an exported PCK using an external --script path.
const BOSSES := ["rooster", "cat", "dog", "monkey", "pig", "ox", "horse", "goat", "rat", "tiger", "snake"]
var files: Array[String] = []

func _initialize() -> void: call_deferred("_run")
func check(ok: bool, message: String = "release verification") -> bool:
	if not ok:
		push_error(message)
		quit(1)
	return ok

func walk(path: String) -> void:
	for filename in DirAccess.get_files_at(path): files.append(path.path_join(filename))
	for directory in DirAccess.get_directories_at(path): walk(path.path_join(directory))

func _run() -> void:
	print("PACK_PROBE START root=" + ProjectSettings.globalize_path("res://"))
	if not check(ProjectSettings.get_setting("application/config/version") == "1.1", "Wrong release version"): return
	if not check(not ProjectSettings.has_setting("autoload/_mcp_game_helper"), "MCP autoload shipped"): return
	walk("res://")
	print("PACK_PROBE FILES " + str(files.size()))
	for path in files:
		if not check(not path.begins_with("res://tests/") and not path.begins_with("res://tools/") and not path.begins_with("res://docs/") and not path.begins_with("res://addons/") and not path.begins_with("res://debug/") and not path.begins_with("res://build/") and not path.begins_with("res://scenes/debug/"), "Development content shipped: " + path): return
	for id: String in BOSSES:
		if not check(ResourceLoader.exists("res://scripts/zodiac/rules/" + id + ".gd"), "Missing boss rule " + id): return
		var content := "res://scripts/zodiac/content/" + ("cat_tier_1" if id == "cat" else id + "_persuasion") + ".gd"
		if not check(ResourceLoader.exists(content), "Missing authored dialogue " + id): return
	for path in ["res://scripts/campaign/difficulty_progress.gd", "res://scripts/ui/campaign_money_hud.gd", "res://assets/audio/sfx/bike_sound.mp3", "res://default_bus_layout.tres"]:
		if not check(ResourceLoader.exists(path), "Missing release asset " + path): return
	var authored_json := 0
	for file in DirAccess.get_files_at("res://assets/audio/ost"):
		if file.ends_with(".json"): authored_json += 1
	if not check(authored_json == 4, "Wrong authored music JSON count"): return
	print("PACK_PROBE RESOURCES PASS")
	var scene = load("res://scenes/match.tscn").instantiate()
	print("PACK_PROBE SCENE LOADED")
	root.add_child(scene)
	current_scene = scene
	await create_timer(0.5).timeout
	if not check(scene.front_end.page == "home", "Release did not open on Home"): return
	var capture_dir := OS.get_environment("TRADATALA_RELEASE_CAPTURE_DIR")
	if not capture_dir.is_empty() and DisplayServer.get_name() != "headless":
		root.size = Vector2i(1920, 1080)
		await create_timer(1.2).timeout
		await RenderingServer.frame_post_draw
		DirAccess.make_dir_recursive_absolute(capture_dir)
		if not check(root.get_texture().get_image().save_png(capture_dir.path_join("windows-release-home.png")) == OK): return

	if not check(scene.campaign.zodiac != null and scene.session.save_files != null, "Missing release services"): return
	if not OS.has_feature("editor"):
		if not check(scene.front_end.find_child("BossLab", true, false) == null, "Developer Boss Lab shown in release"): return
	scene.front_end.show_setup()
	scene.front_end.draft.seed = "TRADATALA-1.1-RELEASE-CHECK"
	scene.front_end._start_pressed()
	await create_timer(1.0).timeout
	if not check(scene.game_started and not scene.campaign.run_seed.is_empty(), "New run failed"): return
	if not check(scene.deal.physical_card_accounting_is_valid(), "Invalid physical card zones"): return
	scene.event_table.unfocus_npc()
	scene.campaign._enter_phase(scene.campaign.CampaignPhase.NOON_EVENT)
	await create_timer(0.5).timeout
	if not check(scene.campaign.zodiac.active_id() in BOSSES, "No live Zodiac visitor"): return
	if not check(scene.campaign.zodiac.has_open_question(), "No authored Noon encounter"): return
	var boss: String = scene.campaign.zodiac.active_id()
	scene.campaign._enter_phase(scene.campaign.CampaignPhase.EVENING_DEAL)
	await create_timer(0.5).timeout
	if not check(scene.deal.zodiac_boss.id == boss, "Evening boss differs from daytime visitor"): return
	if not check(scene.deal.physical_card_accounting_is_valid(), "Invalid evening physical card zones"): return
	if not check(scene.session.run_save.save_run(scene.campaign, scene.deal, scene.music.snapshot()), "Exported save write failed"): return
	if not check(scene.session.run_save.restore(scene.session.run_save.load_run(), scene.campaign, scene.deal), "Exported save restore failed"): return
	if not check(scene.deal.zodiac_boss.id == boss, "Exported boss did not survive restore"): return
	scene.music.controller._stop_all_mix_players()
	scene.music.controller.music_director.stop()
	scene.queue_free()
	await create_timer(0.4).timeout
	print("RELEASE_PACK_CHECK PASS version=1.1 bosses=%d authored_json=%d files=%d new_run=noon=evening=save_restore=PASS" % [BOSSES.size(), authored_json, files.size()])
	quit(0)
