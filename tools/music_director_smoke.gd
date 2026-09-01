extends SceneTree

const TEST_SCENE_PATH := "res://debug/MusicLoopAudition.tscn"
const FIXTURE_PATH := "res://tools/fixtures/music_director_test_cues.json"
const TEMP_CUE_PATH := "user://music_director_smoke_cues.json"
const TRACK_ID := "dog_1"
const FIRST_CUE := "dog_1_bars_001_002"
const OVERLAPPING_CUE := "dog_1_bars_002_003"
const SECOND_CUE := "dog_1_bars_006_007"
const THIRD_CUE := "dog_1_bars_028_029"

var _failures: Array[String] = []
var _scene: Control
var _director: MusicDirector


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	if not _copy_fixture_to_user_data():
		_finish()
		return
	var packed := load(TEST_SCENE_PATH) as PackedScene
	_check(packed != null, "DJ tester scene loads")
	if packed == null:
		_finish()
		return
	_scene = packed.instantiate() as Control
	_director = _scene.get_node("MusicDirector") as MusicDirector
	_director.cue_catalog_path = TEMP_CUE_PATH
	root.add_child(_scene)
	await _advance(3)

	_check(_director.catalogs_are_loaded, "MusicDirector loads loop and cue catalogs")
	_check(_director.get_track_ids().size() == 26, "DJ catalog exposes all 26 original tracks")
	_check(_director.get_approved_cues(TRACK_ID).size() == 3, "fixture exposes a chronological three-cue DJ sequence")
	_check(_scene.track_option != null and _scene.candidate_list != null and _scene.event_log != null, "tester builds discovery, detail, and transport-event surfaces")
	_check(_scene.selected_track_id == TRACK_ID, "tester defaults to dog_1 for repeatable audition")
	_scene.set_option.select(2)
	_scene._on_set_selected(2)
	_check(_scene.candidate_list.item_count == 3, "Approved cue sequence filter shows only approved cues")
	_check(_scene.sequence_label.text.contains("Opening Hook") and _scene.sequence_label.text.contains("Late Hook"), "tester displays the approved cue order")

	var source_stream := load("res://assets/audio/ost/dog_1.wav") as AudioStreamWAV
	var source_loop_mode := source_stream.loop_mode if source_stream != null else -1
	var source_loop_begin := source_stream.loop_begin if source_stream != null else -1
	var source_loop_end := source_stream.loop_end if source_stream != null else -1

	var second := _director.get_candidate(TRACK_ID, SECOND_CUE)
	_check(_director.audition_candidate(TRACK_ID, SECOND_CUE, 2), "candidate can be auditioned with musical lead-in")
	_check(_director.state == MusicDirector.STATE_AUDITIONING_CUE and _director.pending_cue_id == SECOND_CUE, "lead-in audition reports the pending cue honestly")
	_director.audio_player.seek(float(second.get("start_seconds", 0.0)) + 0.05)
	_director._process(0.0)
	_check(_director.state == MusicDirector.STATE_HOLDING_CUE and _director.current_cue_id == SECOND_CUE, "lead-in audition catches and holds the candidate")

	_check(not _director.hold_cue(TRACK_ID, OVERLAPPING_CUE), "rejected cue cannot enter the DJ deck")
	_check(_director.last_error.contains("not manually approved"), "rejected cue failure explains the approval gate")
	_check(_director.hold_cue(TRACK_ID, FIRST_CUE), "approved opening cue can be held indefinitely")
	var first := _director.get_candidate(TRACK_ID, FIRST_CUE)
	_check(_director.runtime_stream.loop_mode == AudioStreamWAV.LOOP_FORWARD, "holding a cue enables the runtime WAV loop")
	_check(_director.runtime_stream.loop_begin == int(first.get("start_sample", -1)) and _director.runtime_stream.loop_end == int(first.get("end_sample", -1)), "hold uses catalog sample boundaries exactly")

	_check(_director.set_manual_decision(TRACK_ID, OVERLAPPING_CUE, &"approved", "Overlap Test", "Smoke-only approval"), "tester decisions save to the writable cue catalog")
	var persisted := _read_json(TEMP_CUE_PATH)
	_check(persisted.get("tracks", {}).get(TRACK_ID, {}).get("decisions", {}).get(OVERLAPPING_CUE, {}).get("status", "") == "approved", "approval persists to JSON")
	_check(not _director.request_cue(OVERLAPPING_CUE), "overlapping cue is rejected as an authored forward transition")
	_check(_director.last_error.contains("overlaps"), "overlap rejection recommends an explicit hard jump")
	_check(_director.set_manual_decision(TRACK_ID, OVERLAPPING_CUE, &"rejected", "Rejected Overlap", "Restored fixture status"), "review status can be corrected after testing")

	_check(_director.release_to_next_cue(), "release requests the next reachable approved cue")
	_check(_director.state == MusicDirector.STATE_TRAVELING_FORWARD and _director.pending_cue_id == SECOND_CUE, "forward move releases into authored source audio")
	_check(_director.runtime_stream.loop_begin == int(second.get("start_sample", -1)), "forward move arms the target loop without jumping to it")
	_director.audio_player.seek(float(second.get("start_seconds", 0.0)) + 0.05)
	_director._process(0.0)
	_check(_director.state == MusicDirector.STATE_HOLDING_CUE and _director.current_cue_id == SECOND_CUE, "MusicDirector catches and holds the next cue")

	_check(_director.release_to_next_cue(), "second release requests the late approved cue")
	var third := _director.get_candidate(TRACK_ID, THIRD_CUE)
	_director.audio_player.seek(float(third.get("start_seconds", 0.0)) + 0.05)
	_director._process(0.0)
	_check(_director.current_cue_id == THIRD_CUE and _director.state == MusicDirector.STATE_HOLDING_CUE, "late cue is caught after original authored transition audio")

	_check(_director.reprise_previous_cue(), "reprise queues the previous approved cue")
	_check(_director.state == MusicDirector.STATE_REWIND_PENDING and _director.pending_cue_id == SECOND_CUE, "reprise waits for the current loop boundary")
	_check(_director.runtime_stream.loop_mode == AudioStreamWAV.LOOP_DISABLED, "reprise releases the current loop before rewinding")
	_director.audio_player.seek(float(third.get("end_seconds", 0.0)) + 0.05)
	_director._process(0.0)
	_check(_director.state == MusicDirector.STATE_HOLDING_CUE and _director.current_cue_id == SECOND_CUE, "reprise jumps back and re-enters the earlier cue after the boundary")

	_check(_director.jump_to_cue(THIRD_CUE), "explicit DJ hard jump can target any approved cue")
	_check(_director.current_cue_id == THIRD_CUE, "hard jump lands on the selected approved cue")
	_check(_director.release_to_end(), "final release returns to the original authored ending")
	_check(_director.state == MusicDirector.STATE_RELEASED_TO_END and _director.runtime_stream.loop_mode == AudioStreamWAV.LOOP_DISABLED, "release-to-end clears loop transport")

	_check(source_stream != null and source_stream.loop_mode == source_loop_mode, "imported WAV loop mode remains unchanged")
	_check(source_stream != null and source_stream.loop_begin == source_loop_begin and source_stream.loop_end == source_loop_end, "imported WAV cue points remain unchanged")
	_director._on_audio_finished()
	_check(_director.state == MusicDirector.STATE_STOPPED and _director.current_track_id.is_empty(), "natural source ending returns MusicDirector to STOPPED")

	await _advance(2)
	_scene.queue_free()
	await _advance(2)
	_finish()


func _copy_fixture_to_user_data() -> bool:
	var source := FileAccess.open(FIXTURE_PATH, FileAccess.READ)
	if source == null:
		_failures.append("fixture cue catalog opens")
		return false
	var target := FileAccess.open(TEMP_CUE_PATH, FileAccess.WRITE)
	if target == null:
		_failures.append("writable cue catalog opens")
		return false
	target.store_string(source.get_as_text())
	return true


func _read_json(path: String) -> Dictionary:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {}
	var parsed = JSON.parse_string(file.get_as_text())
	return parsed if parsed is Dictionary else {}


func _advance(frame_count: int) -> void:
	for _frame in range(frame_count):
		await process_frame


func _check(condition: bool, label: String) -> void:
	if not condition:
		_failures.append(label)


func _finish() -> void:
	var absolute_temp_path := ProjectSettings.globalize_path(TEMP_CUE_PATH)
	if FileAccess.file_exists(TEMP_CUE_PATH):
		DirAccess.remove_absolute(absolute_temp_path)
	if _failures.is_empty():
		print("MUSIC_DIRECTOR_SMOKE: PASS audition approval hold release catch reprise jump finish")
		quit(0)
		return
	for failure in _failures:
		print("MUSIC_DIRECTOR_SMOKE_FAIL: %s" % failure)
	quit(1)
