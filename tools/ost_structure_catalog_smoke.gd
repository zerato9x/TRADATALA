extends SceneTree

const STRUCTURE_PATH := "res://assets/audio/ost/ost_structure.json"
const TIMING_PATH := "res://assets/audio/ost/ost_timing.json"
const AUDIO_SAMPLE_RATE := 48000

var _failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var structure := _load_json(STRUCTURE_PATH)
	var timing := _load_json(TIMING_PATH)
	_check(not structure.is_empty(), "structural catalog opens")
	_check(not timing.is_empty(), "BeatNet timing catalog opens")
	if structure.is_empty() or timing.is_empty():
		_finish()
		return

	_check(structure.get("schema", "") == "tradatala.ost_structure.v2", "structural schema is current")
	_check(structure.get("timing_catalog", "") == TIMING_PATH, "structural catalog points to BeatNet timing catalog")
	_check(structure.get("loop_authority", "") == "section_candidates_only", "section candidates own loop authority")
	_check(structure.get("whole_track_loop_allowed", true) == false, "whole-track looping is disabled")

	var structure_tracks: Dictionary = structure.get("tracks", {})
	var timing_tracks: Dictionary = timing.get("tracks", {})
	_check(structure_tracks.size() == 27, "structural catalog contains all 27 OST tracks")
	_check(structure_tracks.size() == timing_tracks.size(), "structural and timing catalogs contain the same track count")

	for track_id_variant in structure_tracks.keys():
		var track_id := String(track_id_variant)
		var track: Dictionary = structure_tracks[track_id_variant]
		var timing_track: Dictionary = timing_tracks.get(track_id, {})
		_check(not timing_track.is_empty(), "%s has a BeatNet timing entry" % track_id)
		_check(track.get("whole_track_loop_allowed", true) == false, "%s disallows whole-track loops" % track_id)
		_check(int(track.get("sample_rate", 0)) == AUDIO_SAMPLE_RATE, "%s preserves the 48 kHz grid" % track_id)
		_check(int(track.get("beats_per_bar", 0)) > 0, "%s has a positive meter" % track_id)

		var bars: Array = track.get("bars", [])
		var downbeats: Array = timing_track.get("downbeats", [])
		_check(bars.size() >= 1, "%s has complete BeatNet bars" % track_id)
		_check(bars.size() + 1 <= downbeats.size(), "%s bars are closed by BeatNet downbeats" % track_id)
		for bar_variant in bars:
			var bar: Dictionary = bar_variant
			var bar_index := int(bar.get("bar_index", -1))
			if bar_index < 0 or bar_index + 1 >= downbeats.size():
				_check(false, "%s bar %d maps to BeatNet downbeats" % [track_id, bar_index])
				continue
			var expected_start := float(downbeats[bar_index].get("time_seconds", -1.0))
			var expected_end := float(downbeats[bar_index + 1].get("time_seconds", -1.0))
			_check(absf(float(bar["start_seconds"]) - expected_start) < 0.00001, "%s bar %d starts on a BeatNet downbeat" % [track_id, bar_index])
			_check(absf(float(bar["end_seconds"]) - expected_end) < 0.00001, "%s bar %d ends on a BeatNet downbeat" % [track_id, bar_index])
			_check(int(bar["start_sample"]) >= 0 and int(bar["end_sample"]) <= int(track["frame_count"]), "%s bar %d sample bounds are valid" % [track_id, bar_index])

		var sections: Array = track.get("sections", [])
		_check(sections.size() >= 1 and sections.size() <= 8, "%s has one to eight audio-evidenced loop states" % track_id)
		_check(int(track.get("detected_loop_state_count", -1)) == sections.size(), "%s reports its detected state count" % track_id)
		_check(int(track.get("required_loop_state_count", 0)) == 8, "%s records the eight-state gameplay contract" % track_id)
		var counted_safe_states := 0
		for section_variant in sections:
			var section: Dictionary = section_variant
			var stable_start := int(section.get("stable_bar_start", -1))
			var stable_end := int(section.get("stable_bar_end", -1))
			_check(stable_start >= 0 and stable_start < stable_end and stable_end <= bars.size(), "%s %s has a valid stable core" % [track_id, section.get("section_id", "section")])
			_check(section.get("detected_from_audio", false) == true, "%s %s is audio-evidenced" % [track_id, section.get("section_id", "section")])
			_check(section.get("creative_fit", "") == "unknown", "%s %s does not invent creative compliance" % [track_id, section.get("section_id", "section")])
			var candidates: Array = section.get("loop_candidates", [])
			if not candidates.is_empty():
				counted_safe_states += 1
			var expected_rank := 1
			for candidate_variant in candidates:
				var candidate: Dictionary = candidate_variant
				var start_bar := int(candidate.get("bar_start", -1))
				var end_bar := int(candidate.get("bar_end", -1))
				_check(start_bar >= stable_start and start_bar < end_bar and end_bar <= stable_end, "%s candidate stays inside its section" % track_id)
				_check(candidate.get("loop_allowed", false) == true and candidate.get("whole_track", true) == false, "%s candidate has loop-safe flags" % track_id)
				_check(candidate.get("quality_gate_pass", false) == true and candidate.get("quality_failures", []).is_empty(), "%s accepted candidate passed every automatic quality gate" % track_id)
				_check(float(candidate.get("repetition_similarity", 0.0)) >= 0.72, "%s accepted candidate proves a repeated phrase" % track_id)
				_check(candidate.get("manual_listening_required", false) == true, "%s accepted candidate still requires listening QA" % track_id)
				_check(int(candidate.get("rank", 0)) == expected_rank, "%s candidates are independently ranked from 1" % track_id)
				if start_bar >= 0 and start_bar < bars.size() and end_bar > start_bar and end_bar <= bars.size():
					_check(absf(float(candidate["start_seconds"]) - float(bars[start_bar]["start_seconds"])) < 0.00001, "%s candidate starts on a bar boundary" % track_id)
					_check(absf(float(candidate["end_seconds"]) - float(bars[end_bar - 1]["end_seconds"])) < 0.00001, "%s candidate ends on a bar boundary" % track_id)
					_check(int(candidate["start_sample"]) >= 0 and int(candidate["end_sample"]) <= int(track["frame_count"]), "%s candidate sample bounds are valid" % track_id)
					var godot_loop: Dictionary = candidate.get("godot", {})
					_check(godot_loop.get("loop_mode", "") == "forward", "%s candidate exposes Godot forward-loop metadata" % track_id)
					_check(int(godot_loop.get("loop_begin_samples", -1)) == int(candidate["start_sample"]) and int(godot_loop.get("loop_end_samples", -1)) == int(candidate["end_sample"]), "%s candidate exposes Godot sample endpoints" % track_id)
				expected_rank += 1
			var rejected_candidates: Array = section.get("rejected_candidates", [])
			for rejected_variant in rejected_candidates:
				var rejected: Dictionary = rejected_variant
				_check(rejected.get("loop_allowed", true) == false and rejected.get("quality_gate_pass", true) == false, "%s rejected candidate cannot reach runtime" % track_id)
				_check(not rejected.get("quality_failures", []).is_empty(), "%s rejected candidate explains its rejection" % track_id)
		_check(counted_safe_states == int(track.get("safe_loop_state_count", -1)), "%s reports its safe loop-state count" % track_id)

		var transitions: Array = track.get("one_shot_transitions", [])
		_check(transitions.size() > 0, "%s preserves source transition regions" % track_id)
		for transition_variant in transitions:
			var transition: Dictionary = transition_variant
			_check(transition.get("loop_allowed", true) == false, "%s transition is non-loopable" % track_id)
			_check(transition.get("preserves_original_audio", false) == true, "%s transition preserves original audio" % track_id)
			_check(transition.get("source_filename", "") == track.get("source_filename", ""), "%s transition points to its source WAV" % track_id)
			_check(int(transition.get("start_sample", -1)) >= 0 and int(transition.get("end_sample", -1)) <= int(track["frame_count"]), "%s transition sample bounds are valid" % track_id)
		var counted_between_transitions := 0
		for transition_variant in transitions:
			var transition: Dictionary = transition_variant
			if transition.get("kind", "") == "between_sections":
				counted_between_transitions += 1
		_check(counted_between_transitions == int(track.get("between_state_transition_count", -1)), "%s reports its between-state transitions" % track_id)

		var stream := load(String(track.get("project_path", ""))) as AudioStreamWAV
		_check(stream != null, "%s Godot WAV resource loads" % track_id)
		if stream != null:
			_check(stream.mix_rate == AUDIO_SAMPLE_RATE, "%s Godot WAV keeps the catalog sample rate" % track_id)

	var pig_track: Dictionary = structure_tracks.get("pig_3", {})
	var pig_sections: Array = pig_track.get("sections", [])
	var expected_pig_states := ["starter_event", "morning_deal", "morning_event", "noon_deal", "noon_event", "afternoon_deal", "afternoon_event", "evening_deal"]
	_check(pig_sections.size() == 8, "pig_3 exposes the complete eight-state sequence")
	for index in range(mini(pig_sections.size(), expected_pig_states.size())):
		_check(pig_sections[index].get("state_id", "") == expected_pig_states[index], "pig_3 state %d has the required chronological identity" % (index + 1))
	_check(int(pig_track.get("between_state_transition_count", 0)) == 7, "pig_3 preserves seven one-shot state transitions")
	_check(int(pig_track.get("safe_loop_state_count", 0)) == 5, "pig_3 exposes only its five automatically safe loop states")
	_check(pig_track.get("vision_sequence_complete", false) == true, "pig_3 has all eight audio-evidenced states")
	_check(pig_track.get("vision_transport_ready", true) == false, "pig_3 is blocked until all eight states have safe loops")

	_finish()


func _load_json(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		_failures.append("missing JSON: %s" % path)
		return {}
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		_failures.append("cannot open JSON: %s" % path)
		return {}
	var parsed = JSON.parse_string(file.get_as_text())
	if not parsed is Dictionary:
		_failures.append("JSON root is not an object: %s" % path)
		return {}
	return parsed


func _check(condition: bool, label: String) -> void:
	if not condition:
		_failures.append(label)


func _finish() -> void:
	if _failures.is_empty():
		print("OST_STRUCTURE_GODOT_SMOKE: PASS schema=v2 tracks=27 vision=8-states unsafe-candidates=rejected")
		quit(0)
		return
	for failure in _failures:
		print("OST_STRUCTURE_GODOT_SMOKE_FAIL: %s" % failure)
	quit(1)
