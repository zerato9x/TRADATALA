extends SceneTree

const LOOP_PATH := "res://assets/audio/ost/ost_loops.json"
const TIMING_PATH := "res://assets/audio/ost/ost_timing.json"
const EXPECTED_LENGTHS := [2, 4, 8, 12, 16, 24, 32]

var failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var loops := _load_json(LOOP_PATH)
	var timing := _load_json(TIMING_PATH)
	_check(loops.get("schema", "") == "tradatala.ost_loops.v1", "fresh loop schema")
	_check(loops.get("analysis_policy", "") == "exhaustive_bar_aligned_windows_no_role_labels_no_automatic_rejection", "exhaustive neutral policy")
	_check(loops.get("whole_track_loop_allowed", true) == false, "whole-track fallback disabled")
	var tracks: Dictionary = loops.get("tracks", {})
	var timing_tracks: Dictionary = timing.get("tracks", {})
	_check(tracks.size() == 26, "exactly the original 26 tracks")
	_check(timing_tracks.size() == 26, "timing input has exactly 26 tracks")
	_check(not tracks.has("pig_3") and not timing_tracks.has("pig_3"), "V2 pig_3 is absent")
	for track_id_value in tracks.keys():
		var track_id := String(track_id_value)
		var track: Dictionary = tracks[track_id_value]
		var bars: Array = track.get("bars", [])
		var candidates: Array = track.get("loop_candidates", [])
		var expected_count := 0
		for length in EXPECTED_LENGTHS:
			expected_count += maxi(0, bars.size() - length + 1)
		_check(int(track.get("candidate_count", -1)) == expected_count, "%s retains every phrase window" % track_id)
		_check(candidates.size() == expected_count, "%s candidate array is exhaustive" % track_id)
		_check(track.get("role_labels_assigned", true) == false, "%s has no inferred narrative roles" % track_id)
		var ids: Dictionary = {}
		for candidate_value in candidates:
			var candidate: Dictionary = candidate_value
			var candidate_id := String(candidate.get("candidate_id", ""))
			ids[candidate_id] = true
			var start_bar := int(candidate.get("bar_start", -1))
			var end_bar := int(candidate.get("bar_end", -1))
			_check(start_bar >= 0 and start_bar < end_bar and end_bar <= bars.size(), "%s %s stays on the complete-bar grid" % [track_id, candidate_id])
			_check(EXPECTED_LENGTHS.has(int(candidate.get("bar_count", 0))), "%s %s uses an allowed phrase length" % [track_id, candidate_id])
			_check(candidate.get("manual_status", "") == "unreviewed", "%s %s starts unreviewed" % [track_id, candidate_id])
			_check(candidate.get("manual_listening_required", false) == true, "%s %s requires listening" % [track_id, candidate_id])
			_check(not candidate.has("loop_allowed") and not candidate.has("quality_gate_pass"), "%s %s is not automatically accepted or rejected" % [track_id, candidate_id])
			_check(candidate.get("whole_track", true) == false, "%s %s is not a whole-track loop" % [track_id, candidate_id])
		var distinct_ids: Array = track.get("distinct_candidate_ids", [])
		_check(not distinct_ids.is_empty() and distinct_ids.size() <= 64, "%s has a bounded distinct audition set" % track_id)
		for candidate_id_value in distinct_ids:
			_check(ids.has(String(candidate_id_value)), "%s distinct candidate exists in exhaustive set" % track_id)
		var stream := load(String(track.get("project_path", ""))) as AudioStreamWAV
		_check(stream != null, "%s source WAV loads" % track_id)
	_finish()


func _load_json(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		failures.append("missing JSON: %s" % path)
		return {}
	var file := FileAccess.open(path, FileAccess.READ)
	var parsed = JSON.parse_string(file.get_as_text()) if file != null else null
	if not parsed is Dictionary:
		failures.append("invalid JSON: %s" % path)
		return {}
	return parsed


func _check(condition: bool, label: String) -> void:
	if not condition:
		failures.append(label)


func _finish() -> void:
	if failures.is_empty():
		print("OST_LOOP_CATALOG_SMOKE: PASS tracks=26 exhaustive=true roles=none")
		quit(0)
		return
	for failure in failures:
		print("OST_LOOP_CATALOG_SMOKE_FAIL: %s" % failure)
	quit(1)
