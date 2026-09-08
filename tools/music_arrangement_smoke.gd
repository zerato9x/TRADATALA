extends SceneTree

const TEST_SCENE_PATH := "res://debug/MusicLoopAudition.tscn"
const FIXTURE_PATH := "res://tools/fixtures/music_director_test_cues.json"
const TEMP_CUE_PATH := "user://music_arrangement_smoke_cues.json"
const TEMP_ARRANGEMENT_PATH := "user://music_arrangement_smoke_arrangements.json"
const TRACK_ID := "dog_1"

var _failures: Array[String] = []
var _scene: Control
var _director: MusicDirector
var _arranger: MusicArrangementPlayer


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	if not _copy_fixture_to_user_data():
		_finish()
		return
	var packed := load(TEST_SCENE_PATH) as PackedScene
	_check(packed != null, "music tester scene loads with arrangement player")
	if packed == null:
		_finish()
		return
	_scene = packed.instantiate() as Control
	_director = _scene.get_node("MusicDirector") as MusicDirector
	_arranger = _scene.get_node("MusicArrangementPlayer") as MusicArrangementPlayer
	_director.cue_catalog_path = TEMP_CUE_PATH
	_arranger.cue_catalog_path = TEMP_CUE_PATH
	root.add_child(_scene)
	await _advance(3)

	_check(_arranger != null, "arrangement player is present in the tester scene")
	_check(_scene.arrangement_catalog != null, "arrangement catalog is present in the tester")
	_check(_scene.add_section_button != null and _scene.arrangement_list != null and _scene.arrangement_play_button != null, "arrangement editing and transport controls are built")
	_check(_arranger.catalogs_are_loaded, "arrangement player loads the loop and fixture cue catalogs")
	_check(_arranger.get_track_ids().size() == 26, "arrangement player sees all source tracks")

	_scene.arrangement_catalog.load_catalog(TEMP_ARRANGEMENT_PATH)
	_scene._load_arrangement_for_track()
	_scene.set_option.select(1)
	_scene._on_set_selected(1)
	_check(_scene.candidate_list.item_count >= 6, "arrangement can browse every fixture candidate (count=%d)" % _scene.candidate_list.item_count)

	var source_stream := load("res://assets/audio/ost/dog_1.wav") as AudioStreamWAV
	var source_data_size := source_stream.data.size() if source_stream != null else -1
	var source_loop_mode := source_stream.loop_mode if source_stream != null else -1
	var source_loop_begin := source_stream.loop_begin if source_stream != null else -1
	var source_loop_end := source_stream.loop_end if source_stream != null else -1

	_scene.candidate_list.select(0)
	_scene._on_candidate_selected(0)
	var first_candidate_id: String = _scene.selected_candidate_id
	_scene._on_arrangement_add()
	_scene.candidate_list.select(1)
	_scene._on_candidate_selected(1)
	var second_candidate_id: String = _scene.selected_candidate_id
	_scene._on_arrangement_add()
	_check(_scene.arrangement_sections.size() == 2, "selected candidates can be inserted as ordered sections")
	_check(String(_scene.arrangement_sections[0].get("candidate_id", "")) == first_candidate_id and String(_scene.arrangement_sections[1].get("candidate_id", "")) == second_candidate_id, "inserted sections preserve their order")

	_scene.arrangement_list.select(0)
	_scene._on_arrangement_selected(0)
	_scene.section_label_edit.text = "Intro"
	_scene.section_repeat_spin.value = 2
	_scene._on_arrangement_apply()
	_check(String(_scene.arrangement_sections[0].get("label", "")) == "Intro" and int(_scene.arrangement_sections[0].get("repeat_count", 0)) == 2, "sections support custom labels and repeat counts")

	_scene.arrangement_list.select(1)
	_scene._on_arrangement_selected(1)
	_scene._on_arrangement_move_up()
	_check(String(_scene.arrangement_sections[0].get("candidate_id", "")) == second_candidate_id, "sections can be reordered")

	_scene.candidate_list.select(2)
	_scene._on_candidate_selected(2)
	var replacement_candidate_id: String = _scene.selected_candidate_id
	_scene._on_arrangement_replace()
	_check(String(_scene.arrangement_sections[0].get("candidate_id", "")) == replacement_candidate_id, "a section can be replaced with the selected candidate")

	var expected_samples := 0
	for section in _scene.arrangement_sections:
		var candidate: Dictionary = _arranger.cue_catalog.get_candidate(TRACK_ID, String(section.get("candidate_id", "")))
		expected_samples += (int(candidate.get("end_sample", 0)) - int(candidate.get("start_sample", 0))) * clampi(int(section.get("repeat_count", 1)), 1, 64)
	var built := _arranger.build_arrangement(TRACK_ID, _scene.arrangement_sections)
	_check(not built.is_empty(), "arrangement concatenates exact source slices (%s)" % _arranger.last_error)
	var built_stream := built.get("stream") as AudioStreamWAV
	_check(built_stream != null and built_stream.data.size() > 0, "arrangement produces an in-memory WAV stream (%s)" % _arranger.last_error)
	_check(int(built.get("total_samples", 0)) == expected_samples, "arrangement sample length follows candidate bounds and repeats (expected=%d actual=%d)" % [expected_samples, int(built.get("total_samples", 0))])
	_check((built.get("timeline", []) as Array).size() == 3, "repeat counts expand the playback timeline (actual=%d)" % (built.get("timeline", []) as Array).size())

	_scene._on_arrangement_save()
	var persisted := _read_json(TEMP_ARRANGEMENT_PATH)
	var persisted_sections = persisted.get("tracks", {}).get(TRACK_ID, {}).get("sections", [])
	_check(persisted_sections is Array and (persisted_sections as Array).size() == 2, "arrangement saves independently from cue approvals")

	_check(_arranger.play_arrangement(TRACK_ID, _scene.arrangement_sections, true), "arrangement can be played (%s)" % _arranger.last_error)
	_check(_arranger.is_playing() and _arranger.state == MusicArrangementPlayer.STATE_PLAYING, "arrangement transport reports active playback (state=%s)" % String(_arranger.state))
	_check(_arranger.runtime_stream != null and _arranger.runtime_stream.loop_mode == AudioStreamWAV.LOOP_FORWARD, "arrangement loop mode is applied to the assembled stream")
	_arranger.stop()
	_check(_arranger.state == MusicArrangementPlayer.STATE_STOPPED and _arranger.current_track_id.is_empty(), "arrangement stop clears runtime state")

	_check(source_stream != null and source_stream.data.size() == source_data_size, "source WAV bytes remain unchanged")
	_check(source_stream != null and source_stream.loop_mode == source_loop_mode, "source WAV loop mode remains unchanged")
	_check(source_stream != null and source_stream.loop_begin == source_loop_begin and source_stream.loop_end == source_loop_end, "source WAV cue points remain unchanged")

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
	for path in [TEMP_CUE_PATH, TEMP_ARRANGEMENT_PATH]:
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	if _failures.is_empty():
		print("MUSIC_ARRANGEMENT_SMOKE: PASS section-insert-replace-reorder-repeat-save-play-source-preserved")
		quit(0)
		return
	for failure in _failures:
		print("MUSIC_ARRANGEMENT_SMOKE_FAIL: %s" % failure)
	quit(1)
