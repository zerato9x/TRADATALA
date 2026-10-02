extends SceneTree

const SAVE := "user://music-resume-scene.save"
var failures: Array[String] = []
var scene: MatchUI

func _initialize() -> void:
	call_deferred("_run")

func check(value: bool, message: String) -> void:
	if not value:
		failures.append(message)

func _run() -> void:
	root.size = Vector2i(1280, 720)
	var reading := OS.get_cmdline_user_args().has("--resume-only")
	var settings := root.get_node("GameSettings")
	settings.set_music_system("playing_tracks" if reading else "authored_dj")
	scene = load("res://scenes/match.tscn").instantiate()
	root.add_child(scene)
	current_scene = scene
	scene.run_save = RunSave.new(SAVE)
	scene.drink_manager.progress.save_path = ""
	for frame in 3:
		await process_frame
	var title := scene.get_node_or_null("TitleScreen")
	if title:
		title.queue_free()
	if reading:
		var saved := scene.run_save.load_run()
		check(not saved.is_empty(), "fresh process reads saved run")
		if saved.is_empty():
			await _finish()
			return
		scene.front_end.show_home()
		check(not scene.front_end.saved.is_empty(), "Continue needs no new music selection")
		# A new-run choice must not replace the saved authored transport.
		scene.front_end.show_setup()
		scene.front_end.draft.music_system = "playing_tracks"
		scene.front_end.show_home()
		scene.front_end.resume_requested.emit()
		var restored := scene._music_checkpoint()
		check(scene.game_started and scene.deal.current_phase == 2, "fresh Continue restores Morning Phase 2")
		check(restored.system == saved.music.system and restored.controller.dj, "Continue restores saved mode despite new-run choice")
		check(restored.conductor == saved.music.conductor, "Continue retains conductor period and release flags")
		for key in ["state", "track", "cue", "pending", "loop_mode", "loop_begin", "loop_end", "rewind_boundary"]:
			check(restored.controller.transport[key] == saved.music.controller.transport[key], "fresh transport retains " + key)
		check(absf(restored.controller.transport.position - saved.music.controller.transport.position) < 0.1, "fresh process resumes same position")
		check(scene.music_controller.music_paused and scene.music_controller.full_mix_player.stream_paused, "fresh process remains paused")
		check(scene.deal.physical_card_accounting_is_valid(), "resume retains all 52 physical identities")
		check(scene.deal.hand.map(func(card): return card.unique_id) == saved.deal.hand.map(func(card): return card.unique_id), "resume retains exact hand")
		check(scene.deal.deck.draw_pile.map(func(card): return card.unique_id) == saved.deal.deck.draw_pile.map(func(card): return card.unique_id), "resume retains future draws")
		if DisplayServer.get_name() != "headless":
			var deadline := Time.get_ticks_msec() + 3_000
			while scene.interaction_locked and Time.get_ticks_msec() < deadline:
				await process_frame
			check(not scene.interaction_locked, "resumed rendered deal becomes actionable")
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png("res://.godot/fix-2026-09-29/music-resumed.png")
		check(scene.gameplay_music.on_new_phom(2, 1), "resumed Morning conductor still routes Phase 2 cleanup")
		check(not scene.gameplay_music.on_new_phom(2, 1), "first-meld route remains once-only")
		var released := scene._music_checkpoint()
		check(scene._resume_saved_run(scene.run_save.capture(scene.campaign, scene.deal, true, released)), "already-routed checkpoint resumes")
		check(not scene.gameplay_music.on_new_phom(2, 1), "resume preserves already-committed first-meld flag")
		# Explicit switching now starts DJ immediately at the live round state.
		scene._on_music_system_selected(0)
		scene._on_music_system_selected(1)
		check(scene.music_controller.dj_mode and scene.gameplay_music.active, "mid-round DJ selection activates the authored route")
		check(scene.gameplay_music.active_period == "morning" and scene.music_controller.music_director.current_cue_id == "cat_1_bars_018_019", "explicit switch enters the live Phase 2 cue")
		var switched := scene.run_save.capture(scene.campaign, scene.deal, true, scene._music_checkpoint())
		check(scene._resume_saved_run(switched), "switched DJ checkpoint resumes")
		check(scene.settings.music_system == "authored_dj" and scene.music_controller.dj_mode, "resume retains the switched DJ transport")
		var legacy := scene.run_save.capture(scene.campaign, scene.deal)
		legacy.erase("music")
		check(scene._resume_saved_run(legacy), "legacy save still restores gameplay")
		check(not scene.music_controller.dj_mode, "legacy checkpoint never invents an authored position")
	else:
		scene.game_started = true
		scene.run_seed_input = "MUSIC-RESUME"
		scene._start_campaign()
		check(scene.drink_manager.select_for_event(0, DrinkCatalog.TRA_DA).ok, "choose tea")
		scene.event_manager.complete_interaction("choose_drink")
		scene.campaign.complete_current_event()
		var cards: Array[CardData] = []
		for card in scene.deal.hand:
			if card.rank_index == 9:
				cards.append(card)
		check(scene.deal.create_meld(cards).ok, "legal Morning Set")
		for turn in 4:
			check(scene.deal.discard_card(scene.deal.hand[0]).ok, "legal mandatory discard")
			if scene.deal.tra_da_extra_discard_pending:
				check(scene.deal.end_turn_without_tra_da_extra().ok, "optional tea discard skipped")
		check(scene.deal.settle_phase().ok, "settle phase one")
		check(scene.deal.choose_phase_two(false).ok, "choose DUMP")
		scene.music_controller.set_music_paused(true)
		# Flush also captures transport changes with no gameplay action.
		scene._flush_run_save()
		var saved := scene.run_save.load_run()
		check(not saved.is_empty() and saved.has("music"), "disk save includes music checkpoint")
		check(saved.music.controller.transport.state == "TRAVELING_FORWARD", "disk save retains authored travel rather than skipping to target")
		check(saved.music.conductor.period == "morning", "disk save retains conductor authority")
	print("MUSIC_RESUME_SCENE_MODE: ", "fresh-read" if reading else "write")
	await _finish()

func _finish() -> void:
	scene.queue_free()
	await create_timer(0.25).timeout
	for failure in failures:
		push_error(failure)
	print("MUSIC_RESUME_SCENE: %d failures" % failures.size())
	quit(0 if failures.is_empty() else 1)
