extends SceneTree

var failures: Array[String] = []
var controller: ReactiveMusicController

func _initialize() -> void:
	call_deferred("_run")

func check(value: bool, message: String) -> void:
	if not value:
		failures.append(message)

func advance(frames := 3) -> void:
	for frame in frames:
		await process_frame

func roundtrip(label: String) -> void:
	var saved := controller.snapshot_state()
	# A byte roundtrip prevents accidental reliance on live references.
	saved = bytes_to_var(var_to_bytes(saved))
	check(controller.restore_snapshot(saved), label + " restores")
	var restored := controller.snapshot_state()
	check(restored.dj == saved.dj and restored.paused == saved.paused, label + " retains mode/pause")
	check(restored.rng == saved.rng and restored.queued_path == saved.queued_path, label + " retains next-track RNG")
	if saved.dj:
		for key in ["state", "track", "cue", "pending", "loop_mode", "loop_begin", "loop_end", "rewind_boundary"]:
			check(restored.transport[key] == saved.transport[key], label + " retains " + key)
		check(absf(restored.transport.position - saved.transport.position) < 0.1, label + " retains playback position")
		if saved.transport.playing:
			check(controller.music_director.audio_player.stream_paused == bool(saved.paused), label + " retains transport pause")
	else:
		check(restored.track_path == saved.track_path, label + " retains playlist source")
		check(absf(restored.player.position - saved.player.position) < 0.1, label + " retains playlist position")
		check(restored.player.playing == saved.player.playing, label + " retains stopped/playing")
		check(restored.shuffle == saved.shuffle and restored.repeat == saved.repeat, label + " retains options")
	check(controller.anti_fatigue.loop_pass_count == int(saved.anti_fatigue.passes), label + " retains loop count")
	check(is_equal_approx(controller.anti_fatigue._current_low_pass_hz, float(saved.anti_fatigue.low)), label + " retains filter position")
	print("MUSIC_TRANSPORT_CASE ", label)

func _run() -> void:
	controller = ReactiveMusicController.new()
	root.add_child(controller)
	await advance()
	controller.set_music_paused(true)
	controller.anti_fatigue.set_process(false)
	var director := controller.music_director
	var cues := director.get_approved_cues("cat_1")
	check(cues.size() >= 2, "production catalog has a cue sequence")
	if cues.size() < 2:
		_finish()
		return
	var first := String(cues[0].candidate_id)
	var last := String(cues[-1].candidate_id)
	check(controller.start_dj_track("cat_1", first), "start approved production cue")
	for pass_number in 4:
		controller.anti_fatigue.loop_completed(first)
	controller.anti_fatigue._process(8.0)
	roundtrip("held-with-filter-descent")
	check(controller.request_dj_cue(last), "forward request is accepted")
	check(director.state == MusicDirector.STATE_TRAVELING_FORWARD, "forward transition stays pending")
	roundtrip("forward-pending")
	# Catch the saved transition using the actual transport, without a hard jump.
	director.audio_player.stream_paused = false
	director.audio_player.seek(float(cues[-1].start_seconds) + 0.1)
	director._process(0.0)
	check(director.state == MusicDirector.STATE_HOLDING_CUE and director.current_cue_id == last, "restored forward move catches its target")
	director.audio_player.stream_paused = true
	check(controller.request_dj_cue(first), "reprise request is accepted")
	check(director.state == MusicDirector.STATE_REWIND_PENDING, "reprise waits at saved boundary")
	roundtrip("reprise-pending")
	director.audio_player.stream_paused = false
	director.audio_player.seek(float(cues[-1].end_seconds) - 0.01)
	director._process(0.0)
	check(director.state == MusicDirector.STATE_HOLDING_CUE and director.current_cue_id == first, "restored reprise waits for boundary then returns")
	director.audio_player.stream_paused = true
	check(controller.release_dj_to_end(), "release source")
	roundtrip("released-source")
	check(director.play_track_from_start("cat_1"), "play source without a hold")
	director.audio_player.stream_paused = true
	roundtrip("playing-source")
	check(director.audition_candidate("cat_1", last, 2), "audition with lead-in")
	director.audio_player.stream_paused = true
	roundtrip("audition-lead-in")
	controller.set_music_paused(false)
	roundtrip("unpaused-audition")
	controller.set_music_paused(true)
	director.stop()
	roundtrip("finished-authored-source")
	controller.play_track(2, false)
	controller.full_mix_player.seek(42.0)
	controller.set_shuffle_enabled(true)
	controller.repeat_mode = ReactiveMusicController.REPEAT_ALL
	controller.music_rng.seed = 42
	controller.next_mix_request()
	roundtrip("playlist")
	controller._begin_transition_to(3)
	var fade := controller.snapshot_state()
	check(fade.has("fade"), "crossfade checkpoint contains incoming channel")
	check(controller.restore_snapshot(fade), "crossfade checkpoint restores")
	check(controller.transition_in_progress, "crossfade resumes instead of restarting a source")
	var deadline := Time.get_ticks_msec() + 2_000
	while controller.transition_in_progress and Time.get_ticks_msec() < deadline:
		await process_frame
	check(not controller.transition_in_progress and controller.current_track_index == 3, "restored fade completes to the saved destination")
	controller.full_mix_player.stop()
	roundtrip("stopped-playlist")
	var invalid := controller.snapshot_state()
	invalid.player.position = INF
	check(not controller.restore_snapshot(invalid), "invalid positions fail safely")
	_finish()

func _finish() -> void:
	controller.queue_free()
	# Allow the audio mixer to release queued WAV playback resources after stop.
	await create_timer(0.25).timeout
	for failure in failures:
		push_error(failure)
	print("MUSIC_TRANSPORT_SMOKE: %d failures" % failures.size())
	quit(0 if failures.is_empty() else 1)
