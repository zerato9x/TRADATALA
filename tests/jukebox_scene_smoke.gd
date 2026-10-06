extends SceneTree

var scene: MatchUI
var failures: Array[String] = []

func _initialize() -> void:
	call_deferred("_run")

func check(value: bool, message: String) -> void:
	if not value:
		failures.append(message)

func capture(label: String, chooser: bool = false) -> void:
	if DisplayServer.get_name() == "headless":
		return
	if chooser:
		scene.front_end.music_player.track_list.show_popup()
	await RenderingServer.frame_post_draw
	if chooser:
		var popup := scene.front_end.music_player.track_list.get_popup()
		check(Rect2(Vector2.ZERO, Vector2(root.size)).encloses(Rect2(Vector2(popup.position), Vector2(popup.size))), "chooser popup fits viewport")
	var language := "vi" if OS.get_cmdline_user_args().has("--vietnamese") else "en"
	root.get_texture().get_image().save_png("res://.godot/jukebox-2026-09-29/%s-%s.png" % [language, label])
	if chooser:
		scene.front_end.music_player.track_list.get_popup().hide()

func select_option(button: OptionButton, index: int) -> void:
	# Exercise the popup's native selection connection, which emits item_selected.
	button.get_popup().index_pressed.emit(index)

func gameplay_bytes() -> PackedByteArray:
	# Freeze actual card/value fields too; raw Variant serialization without full
	# object encoding would compare instance IDs rather than their saved fields.
	var codec := RunSave.new()
	var encoded: Variant = codec._encode(codec.capture(scene.campaign, scene.deal))
	check(codec.error.is_empty(), "gameplay checkpoint encodes")
	return var_to_bytes({"root": encoded, "objects": codec._records})

func wait_ready() -> void:
	var deadline := Time.get_ticks_msec() + 3_000
	while (scene.music.controller.transition_in_progress or scene.menu_transitioning) and Time.get_ticks_msec() < deadline:
		await process_frame
	check(not scene.music.controller.transition_in_progress and not scene.menu_transitioning, "jukebox transition completes")
	await process_frame

func assert_layout() -> void:
	var bounds := Rect2(Vector2.ZERO, Vector2(root.size))
	for control: Control in [scene.front_end.music_player, scene.front_end.music_player.system_selector, scene.front_end.music_player.track_list, scene.front_end.music_player.play_pause]:
		check(bounds.encloses(control.get_global_rect()), "jukebox control fits viewport: " + control.name)
	check(scene.front_end.music_player.get_node_or_null("Margin/Content/Details/AuthoredSetRow") == null, "separate authored-set selector is removed")

func _run() -> void:
	root.size = Vector2i(1920, 1080) if OS.get_cmdline_user_args().has("--large") else Vector2i(1280, 720)
	root.gui_embed_subwindows = true
	var settings := root.get_node("GameSettings")
	settings.set_music_system("playing_tracks")
	settings.set_authored_music_set("cat")
	settings.set_locale("vi" if OS.get_cmdline_user_args().has("--vietnamese") else "en")
	scene = load("res://scenes/match.tscn").instantiate()
	root.add_child(scene)
	current_scene = scene
	scene.session.run_save = RunSave.new("user://jukebox-test.save")
	scene.drink_manager.progress.save_path = ""
	for frame in 3:
		await process_frame
	await process_frame
	scene.front_end.show_music()
	await process_frame
	check(scene.front_end.music_player.track_list.item_count == 26 and not scene.front_end.music_player.track_list.disabled, "Playlist chooser contains all 26 tracks")
	check(scene.front_end.music_player.shuffle.visible and scene.front_end.music_player.repeat.visible, "Playlist offers shuffle/repeat")
	assert_layout()
	await capture("playlist")
	await capture("playlist-chooser", true)
	select_option(scene.front_end.music_player.system_selector, 1)
	check(scene.music.controller.dj_mode and scene.music.conductor.active_set_id == "cat", "choosing DJ immediately starts CAT")
	check(scene.front_end.music_player.track_list.item_count == 2 and scene.front_end.music_player.track_list.selected == 1, "same chooser changes to DOG/CAT and selects actual set")
	check(not scene.front_end.music_player.shuffle.visible and not scene.front_end.music_player.repeat.visible, "DJ hides Playlist-only controls")
	assert_layout()
	await capture("dj-cat")
	await capture("dj-chooser", true)
	select_option(scene.front_end.music_player.track_list, 0)
	check(scene.music.conductor.active_set_id == "dog" and scene.music.controller.current_mix_path.ends_with("dog_2.wav"), "DOG selection immediately plays its authored opening")
	check(scene.front_end.music_player.cover.texture.resource_path.ends_with("dog.png"), "cover reflects actual DOG audio")
	await capture("dj-dog")
	# Reach a real Morning Phase 2, then switch through the actual menu controls.
	scene.game_started = true
	scene.run_seed_input = "JUKEBOX-MORNING"
	scene._start_campaign()
	check(scene.music.conductor.active_set_id == "dog", "new run honors the selected DJ set")
	check(scene.drink_manager.select_for_event(0, DrinkCatalog.TRA_DA).ok, "choose tea")
	scene.event_manager.complete_interaction("choose_drink")
	scene.campaign.complete_current_event()
	var cards: Array[CardData] = []
	for card in scene.deal.hand:
		if card.rank_index == 9:
			cards.append(card)
	check(scene.deal.create_meld(cards).ok, "legal Set")
	for turn in 4:
		check(scene.deal.discard_card(scene.deal.hand[0]).ok, "mandatory discard")
		if scene.deal.tra_da_extra_discard_pending:
			scene.deal.end_turn_without_tra_da_extra()
	check(scene.deal.settle_phase().ok and scene.deal.choose_phase_two(false).ok, "enter real Phase 2")
	var before := gameplay_bytes()
	scene.music.controller.set_music_paused(true)
	select_option(scene.front_end.music_player.system_selector, 0)
	check(not scene.music.controller.dj_mode and scene.front_end.music_player.track_list.item_count == 26, "switching to Playlist restores the full chooser")
	select_option(scene.front_end.music_player.system_selector, 1)
	check(scene.music.controller.dj_mode and scene.music.controller.music_director.current_cue_id == "dog_2_bars_005_008", "mid-round DJ entry uses DOG Morning Phase 2")
	select_option(scene.front_end.music_player.track_list, 1)
	check(scene.music.conductor.active_set_id == "cat" and scene.music.controller.music_director.current_cue_id == "cat_1_bars_018_019", "mid-round CAT selection uses the matching Phase 2 cue")
	check(scene.music.conductor.active_period == "morning" and scene.music.controller.full_mix_player.stream_paused, "switch preserves round authority and pause")
	check(before == gameplay_bytes(), "music choices never mutate gameplay, wallet, history, or RNG")
	var music := scene.music.snapshot()
	check(scene.session.resume(scene.session.run_save.capture(scene.campaign, scene.deal, true, music)), "selected DJ state resumes")
	check(scene.settings.authored_music_set == "cat" and scene.front_end.music_player.track_list.selected == 1, "resume restores selected set and chooser")
	# Enter the late half from Playlist to cover different set/source ordering.
	scene.campaign.current_phase = CampaignManager.CampaignPhase.EVENING_DEAL
	scene.deal.phase_new_meld_count = 1
	select_option(scene.front_end.music_player.system_selector, 0)
	select_option(scene.front_end.music_player.system_selector, 1)
	check(scene.music.controller.music_director.current_track_id == "cat_2" and scene.music.controller.music_director.current_cue_id == "cat_2_bars_048_051", "late entry honors existing first-Phom cleanup")
	check(not scene.music.conductor.on_new_phom(2, 2), "existing first-Phom route cannot retrigger")
	select_option(scene.front_end.music_player.track_list, 0)
	check(scene.music.controller.music_director.current_track_id == "dog_1" and scene.music.controller.music_director.current_cue_id == "dog_1_bars_047_050", "DOG late entry uses its closing source")
	select_option(scene.front_end.music_player.system_selector, 0)
	select_option(scene.front_end.music_player.track_list, 3)
	await wait_ready()
	check(scene.music.controller.current_mix_path.ends_with("mouse_2.wav"), "restored Playlist chooser plays any original track")
	scene.queue_free()
	await create_timer(0.25).timeout
	for failure in failures:
		push_error(failure)
	print("JUKEBOX_SCENE_SMOKE: %d failures" % failures.size())
	quit(0 if failures.is_empty() else 1)
