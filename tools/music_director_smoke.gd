extends SceneTree

const TEST_SCENE_PATH := "res://debug/MusicReactiveTest.tscn"
const TRACK_ID := "tiger_2"
const ANALYZED_TRACK_ID := "pig_3"

var _failures: Array[String] = []
var _scene: Control
var _director


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var packed := load(TEST_SCENE_PATH) as PackedScene
	_check(packed != null, "reactive test scene loads")
	if packed == null:
		_finish()
		return
	_scene = packed.instantiate() as Control
	root.add_child(_scene)
	await _advance(3)
	_director = _scene.get_node("MusicDirector")
	_check(_director.catalog_is_loaded, "MusicDirector loads ost_structure.json")
	_check(_scene._selected_track_id == TRACK_ID, "tester defaults to tiger_2")
	_check(_scene.track_option.item_count == 27, "tester exposes all tracks in the primary catalog")
	_check(_director.get_track_ids().has(ANALYZED_TRACK_ID), "tester exposes the newly analyzed Pig track")
	_check(_director.get_section_count(TRACK_ID) >= 2, "tiger_2 exposes multiple sections")
	_check(_director.get_section_count(ANALYZED_TRACK_ID) == 8, "pig_3 exposes the complete eight-state sequence")
	_check(_director.get_section(ANALYZED_TRACK_ID, 0).get("state_id", "") == "starter_event", "pig_3 begins with Starter Event")
	_check(_director.get_section(ANALYZED_TRACK_ID, 7).get("state_id", "") == "evening_deal", "pig_3 ends its loop states with Evening Deal")
	_check(_director.get_candidate_count(ANALYZED_TRACK_ID, 2) == 0, "unsafe Morning Event candidates are not exposed to runtime")
	_check(not _director.play_track("missing_track"), "missing track fails without crashing")
	_check(_director.last_error.contains("missing"), "missing track reports a clear error")

	var source_stream := load("res://assets/audio/ost/tiger_2.wav") as AudioStreamWAV
	var source_loop_mode := source_stream.loop_mode if source_stream != null else -1
	var source_loop_begin := source_stream.loop_begin if source_stream != null else -1
	var source_loop_end := source_stream.loop_end if source_stream != null else -1

	_scene._on_play_from_start()
	await _advance(3)
	_check(_director.current_track_id == TRACK_ID and _director.audio_player.playing, "tester Play From Start starts tiger_2")
	_check(not _director.set_candidate_rank(0, 999), "invalid candidate rank fails without crashing")
	_check(_director.last_error.contains("does not exist"), "invalid candidate rank reports a clear error")
	_check(_director.set_candidate_rank(0, 1), "valid candidate rank remains selectable after an error")
	var first_candidate: Dictionary = _director.get_candidate(TRACK_ID, 0, 1)
	var second_candidate: Dictionary = _director.get_candidate(TRACK_ID, 1, 1)
	var first_loop: Dictionary = first_candidate.get("godot", {})
	var second_loop: Dictionary = second_candidate.get("godot", {})
	_check(_director.state == _director.STATE_PLAYING_TO_LOOP, "section 1 begins in PLAYING_TO_LOOP")
	var position_before_first_seek: float = _director.current_playback_position
	_director.audio_player.seek(float(first_loop["loop_begin_seconds"]) + 0.05)
	await _advance(3)
	_check(_director.state == _director.STATE_LOOPING, "section 1 enters LOOPING at the JSON loop start")
	_check(_director.current_section_index == 0 and _director.current_candidate_rank == 1, "section 1 becomes the active phase")
	_check(_director.current_loop_start_sample == int(first_loop["loop_begin_samples"]), "section 1 uses JSON loop_begin_samples")
	_check(_director.current_loop_end_sample == int(first_loop["loop_end_samples"]), "section 1 uses JSON loop_end_samples")
	_check(_director.runtime_stream.loop_mode == AudioStreamWAV.LOOP_FORWARD, "runtime copy uses a forward WAV loop")
	_check(absf(_director.current_loop_start - float(first_loop["loop_begin_seconds"])) < 0.00001, "section 1 uses JSON loop_begin_seconds")
	_check(absf(_director.current_loop_end - float(first_loop["loop_end_seconds"])) < 0.00001, "section 1 uses JSON loop_end_seconds")
	_director.audio_player.seek(float(first_loop["loop_end_seconds"]) - 0.05)
	await _advance(10)
	_check(_director.state == _director.STATE_LOOPING and _director.current_playback_position < float(first_loop["loop_end_seconds"]) + 0.25, "section 1 actually wraps inside its selected loop")

	var position_before_phase_request: float = _director.current_playback_position
	_scene._on_next_section()
	_scene._on_request_selected_section()
	_check(_director.pending_section_index == 1, "tester selects section 2 as the next phase")
	_check(_director.state == _director.STATE_RELEASING_TO_NEXT, "next phase starts RELEASE_TO_NEXT")
	_check(_director.runtime_stream.loop_mode == AudioStreamWAV.LOOP_DISABLED, "next phase disables the current runtime loop")
	_check(_director.pending_section_index == 1, "section 2 remains pending")
	_check(_director.current_playback_position >= position_before_phase_request - 0.25, "phase request does not rewind the source timeline")
	_check(position_before_phase_request >= position_before_first_seek - 0.25, "first loop request does not rewind the source timeline")

	_director.audio_player.seek(float(first_loop["loop_end_seconds"]) + 0.05)
	await _advance(3)
	_check(_director.state == _director.STATE_PLAYING_TO_NEXT_LOOP, "release continues toward the next loop")
	_check(_director.current_section_index == -1, "released section is no longer marked active")
	_check(_director.current_playback_position >= float(first_loop["loop_end_seconds"]) - 0.25, "release position remains after the old loop end")
	_check(_director.pending_section_index == 1, "section 2 remains pending after release")

	_director.audio_player.seek(float(second_loop["loop_begin_seconds"]) + 0.05)
	await _advance(3)
	_check(_director.state == _director.STATE_LOOPING, "section 2 enters LOOPING at its JSON loop start")
	_check(_director.current_section_index == 1 and _director.current_candidate_rank == 1, "section 2 becomes the active phase")
	_check(_director.current_loop_start_sample == int(second_loop["loop_begin_samples"]), "section 2 uses JSON loop_begin_samples")
	_check(_director.current_loop_end_sample == int(second_loop["loop_end_samples"]), "section 2 uses JSON loop_end_samples")
	_check(_director.runtime_stream.loop_mode == AudioStreamWAV.LOOP_FORWARD, "section 2 enables the runtime forward loop")
	_director.audio_player.seek(float(second_loop["loop_end_seconds"]) - 0.05)
	await _advance(10)
	_check(_director.state == _director.STATE_LOOPING and _director.current_playback_position < float(second_loop["loop_end_seconds"]) + 0.25, "section 2 actually wraps inside its selected loop")

	_scene._on_finish_track()
	_check(_director.state == _director.STATE_RELEASING_TO_NEXT, "Finish releases the active loop first")
	_check(_director.runtime_stream.loop_mode == AudioStreamWAV.LOOP_DISABLED, "Finish disables the runtime loop")
	_director.audio_player.seek(float(second_loop["loop_end_seconds"]) + 0.05)
	await _advance(3)
	_check(_director.state == _director.STATE_FINISHING, "Finish continues through the source")
	_check(_director.current_section_index == -1 and _director.current_loop_start < 0.0, "final loop is released")
	_check(_director.current_playback_position >= float(second_loop["loop_end_seconds"]) - 0.25, "Finish does not rewind before the final loop end")

	_check(source_stream != null and source_stream.loop_mode == source_loop_mode, "imported source loop mode is unchanged")
	_check(source_stream != null and source_stream.loop_begin == source_loop_begin and source_stream.loop_end == source_loop_end, "imported source loop points are unchanged")

	var analyzed_track_index: int = _director.get_track_ids().find(ANALYZED_TRACK_ID)
	_scene._on_track_selected(analyzed_track_index)
	_check(_scene._selected_section_index == 0, "pig_3 defaults to its first measured section")
	_scene._on_play_from_start()
	await _advance(3)
	_check(_director.current_track_id == ANALYZED_TRACK_ID and _director.audio_player.playing, "tester starts the project-local pig_3 WAV")
	_check(absf(_director.stream_length_seconds - 202.76) < 0.01, "pig_3 project WAV length loads correctly")
	var analyzed_candidate: Dictionary = _director.get_candidate(ANALYZED_TRACK_ID, 0, 1)
	var analyzed_loop: Dictionary = analyzed_candidate.get("godot", {})
	_check(_director.state == _director.STATE_PLAYING_TO_LOOP, "pig_3 begins by playing toward its measured candidate")
	_check(_director.audio_player.stream is AudioStreamWAV, "pig_3 uses an AudioStreamWAV runtime stream")
	_director.audio_player.seek(float(analyzed_loop["loop_begin_seconds"]) + 0.05)
	await _advance(3)
	_check(_director.state == _director.STATE_LOOPING, "pig_3 enters its measured section loop")
	_check(_director.current_loop_start_sample == int(analyzed_loop["loop_begin_samples"]), "pig_3 uses the analyzed loop begin sample")
	_check(_director.current_loop_end_sample == int(analyzed_loop["loop_end_samples"]), "pig_3 uses the analyzed loop end sample")
	_director.audio_player.seek(float(analyzed_loop["loop_end_seconds"]) - 0.05)
	await _advance(10)
	_check(_director.state == _director.STATE_LOOPING and _director.current_playback_position < float(analyzed_loop["loop_end_seconds"]) + 0.25, "pig_3 actually wraps inside its measured loop")

	_director.stop()
	_check(_director.state == _director.STATE_STOPPED, "pig_3 stop returns MusicDirector to STOPPED")
	await _advance(20)
	_scene.queue_free()
	await _advance(2)
	source_stream = null
	first_candidate.clear()
	second_candidate.clear()
	first_loop.clear()
	second_loop.clear()
	analyzed_candidate.clear()
	analyzed_loop.clear()
	_director = null
	_scene = null
	packed = null
	_finish()


func _advance(frame_count: int) -> void:
	for _frame in range(frame_count):
		await process_frame


func _check(condition: bool, label: String) -> void:
	if not condition:
		_failures.append(label)


func _finish() -> void:
	if _failures.is_empty():
		print("MUSIC_DIRECTOR_SMOKE: PASS tiger_2 source-continuation and analyzed pig_3 verified")
		quit(0)
		return
	for failure in _failures:
		print("MUSIC_DIRECTOR_SMOKE_FAIL: %s" % failure)
	quit(1)
