class_name MusicCueCatalog
extends RefCounted

const LOOP_CATALOG_PATH := "res://assets/audio/ost/ost_loops.json"
const CUE_CATALOG_PATH := "res://assets/audio/ost/ost_cues.json"
const LOOP_SCHEMA := "tradatala.ost_loops.v1"
const CUE_SCHEMA := "tradatala.ost_cues.v2"
const VALID_STATUSES := [&"unreviewed", &"approved", &"rejected"]

var loop_catalog_path := LOOP_CATALOG_PATH
var cue_catalog_path := CUE_CATALOG_PATH
var loop_catalog: Dictionary = {}
var cue_catalog: Dictionary = {}
var tracks: Dictionary = {}
var authoring_mode := false
var last_error := ""


func load_runtime(cue_path := "") -> bool:
	if not cue_path.is_empty():
		cue_catalog_path = cue_path
	cue_catalog = _read_json(cue_catalog_path)
	if cue_catalog.is_empty():
		return false
	if cue_catalog.get("schema", "") != CUE_SCHEMA:
		return _fail("Unsupported runtime cue catalog schema: %s" % String(cue_catalog.get("schema", "<missing>")))
	var parsed_tracks = cue_catalog.get("tracks", {})
	if not parsed_tracks is Dictionary:
		return _fail("Cue catalog tracks must be an object")
	tracks = parsed_tracks
	authoring_mode = false
	last_error = ""
	return true


func load_authoring(loop_path := "", cue_path := "") -> bool:
	if not loop_path.is_empty():
		loop_catalog_path = loop_path
	if not cue_path.is_empty():
		cue_catalog_path = cue_path
	loop_catalog = _read_json(loop_catalog_path)
	if loop_catalog.is_empty():
		return false
	if loop_catalog.get("schema", "") != LOOP_SCHEMA:
		return _fail("Unsupported loop catalog schema: %s" % String(loop_catalog.get("schema", "<missing>")))
	var parsed_tracks = loop_catalog.get("tracks", {})
	if not parsed_tracks is Dictionary or parsed_tracks.is_empty():
		return _fail("Loop catalog contains no tracks")
	tracks = parsed_tracks
	if FileAccess.file_exists(cue_catalog_path):
		cue_catalog = _read_json(cue_catalog_path)
		if cue_catalog.is_empty():
			return false
		var schema := String(cue_catalog.get("schema", ""))
		if schema != CUE_SCHEMA:
			# v1 only stored review decisions and never shipped approved cue bounds.
			# Rebuild it into v2 while preserving rejected/listening notes where possible.
			if schema == "tradatala.ost_cues.v1":
				cue_catalog = _migrate_v1(cue_catalog)
			else:
				return _fail("Unsupported cue catalog schema: %s" % schema)
	else:
		cue_catalog = _empty_cue_catalog()
	authoring_mode = true
	last_error = ""
	return true


func get_track_ids() -> Array[String]:
	var result: Array[String] = []
	for value in tracks.keys():
		result.append(String(value))
	result.sort()
	return result


func get_track(track_id: String) -> Dictionary:
	var value = tracks.get(track_id, {})
	return value if value is Dictionary else {}


func get_candidates(track_id: String, distinct_only := true) -> Array[Dictionary]:
	if not authoring_mode:
		return []
	var track := get_track(track_id)
	var raw = track.get("loop_candidates", [])
	if not raw is Array:
		return []
	var all: Array[Dictionary] = []
	var by_id: Dictionary = {}
	for value in raw:
		if value is Dictionary:
			var candidate: Dictionary = value
			all.append(candidate)
			by_id[String(candidate.get("candidate_id", ""))] = candidate
	if not distinct_only:
		return all
	var result: Array[Dictionary] = []
	for candidate_id_value in track.get("distinct_candidate_ids", []):
		var candidate_id := String(candidate_id_value)
		if by_id.has(candidate_id):
			result.append(by_id[candidate_id])
	return result


func get_candidate(track_id: String, candidate_id: String) -> Dictionary:
	if authoring_mode:
		for candidate in get_candidates(track_id, false):
			if String(candidate.get("candidate_id", "")) == candidate_id:
				return candidate
	return get_cue(track_id, candidate_id)


func get_cue(track_id: String, cue_id: String) -> Dictionary:
	var track_entry = cue_catalog.get("tracks", {}).get(track_id, {})
	if not track_entry is Dictionary:
		return {}
	var cues = track_entry.get("cues", {})
	if not cues is Dictionary:
		return {}
	var cue = cues.get(cue_id, {})
	return cue if cue is Dictionary else {}


func get_decision(track_id: String, candidate_id: String) -> Dictionary:
	var cue := get_cue(track_id, candidate_id)
	if not cue.is_empty():
		return {
			"status": "approved",
			"cue_name": String(cue.get("cue_name", "")),
			"notes": String(cue.get("notes", "")),
			"updated_at_utc": String(cue.get("updated_at_utc", "")),
		}
	var track_entry = cue_catalog.get("tracks", {}).get(track_id, {})
	if not track_entry is Dictionary:
		return {}
	var review = track_entry.get("review", {})
	if not review is Dictionary:
		return {}
	var decision = review.get(candidate_id, {})
	return decision if decision is Dictionary else {}


func get_manual_status(track_id: String, candidate_id: String) -> StringName:
	return StringName(get_decision(track_id, candidate_id).get("status", "unreviewed"))


func set_manual_decision(track_id: String, candidate_id: String, status: StringName, cue_name := "", notes := "") -> bool:
	if not authoring_mode:
		return _fail("Cue review is authoring-only")
	if not VALID_STATUSES.has(status):
		return _fail("Invalid cue status: %s" % String(status))
	var candidate := get_candidate(track_id, candidate_id)
	if candidate.is_empty():
		return _fail("Unknown candidate: %s / %s" % [track_id, candidate_id])
	var cue_tracks: Dictionary = cue_catalog.get("tracks", {})
	var track_entry: Dictionary = cue_tracks.get(track_id, {})
	var cues: Dictionary = track_entry.get("cues", {})
	var review: Dictionary = track_entry.get("review", {})

	if status == &"approved":
		var source_track := get_track(track_id)
		track_entry["project_path"] = String(source_track.get("project_path", ""))
		track_entry["frame_count"] = int(source_track.get("frame_count", 0))
		cues[candidate_id] = _snapshot_approved_cue(candidate, cue_name, notes)
		review.erase(candidate_id)
	elif status == &"rejected":
		cues.erase(candidate_id)
		review[candidate_id] = {
			"status": "rejected",
			"cue_name": cue_name.strip_edges(),
			"notes": notes.strip_edges(),
			"updated_at_utc": Time.get_datetime_string_from_system(true),
		}
	else:
		cues.erase(candidate_id)
		review.erase(candidate_id)

	track_entry["cues"] = cues
	track_entry["review"] = review
	cue_tracks[track_id] = track_entry
	cue_catalog["tracks"] = cue_tracks
	_relink_track(track_id)
	return true


func save_cues(path := "") -> bool:
	var target := cue_catalog_path if path.is_empty() else path
	var file := FileAccess.open(target, FileAccess.WRITE)
	if file == null:
		return _fail("Cue catalog cannot be written: %s" % target)
	file.store_string(JSON.stringify(cue_catalog, "  ") + "\n")
	file = null
	last_error = ""
	return true


func get_approved_cues(track_id: String) -> Array[Dictionary]:
	var track_entry = cue_catalog.get("tracks", {}).get(track_id, {})
	if not track_entry is Dictionary:
		return []
	var raw_cues = track_entry.get("cues", {})
	if not raw_cues is Dictionary:
		return []
	var approved: Array[Dictionary] = []
	for cue_value in raw_cues.values():
		if cue_value is Dictionary:
			approved.append(cue_value)
	approved.sort_custom(func(left: Dictionary, right: Dictionary) -> bool:
		return int(left.get("start_sample", 0)) < int(right.get("start_sample", 0))
	)
	return approved


func _snapshot_approved_cue(candidate: Dictionary, cue_name: String, notes: String) -> Dictionary:
	var cue_id := String(candidate.get("candidate_id", ""))
	return {
		"cue_id": cue_id,
		"candidate_id": cue_id,
		"cue_name": cue_name.strip_edges(),
		"notes": notes.strip_edges(),
		"start_sample": int(candidate.get("start_sample", -1)),
		"end_sample": int(candidate.get("end_sample", -1)),
		"start_seconds": float(candidate.get("start_seconds", 0.0)),
		"end_seconds": float(candidate.get("end_seconds", 0.0)),
		"bar_start": int(candidate.get("bar_start", 0)),
		"bar_end": int(candidate.get("bar_end", 0)),
		"bar_count": int(candidate.get("bar_count", 0)),
		"next_cue_id": "",
		"previous_cue_id": "",
		"updated_at_utc": Time.get_datetime_string_from_system(true),
	}


func _relink_track(track_id: String) -> void:
	var cue_tracks: Dictionary = cue_catalog.get("tracks", {})
	var track_entry: Dictionary = cue_tracks.get(track_id, {})
	var cues: Dictionary = track_entry.get("cues", {})
	var ordered: Array[Dictionary] = []
	for value in cues.values():
		if value is Dictionary:
			ordered.append(value)
	ordered.sort_custom(func(left: Dictionary, right: Dictionary) -> bool:
		return int(left.get("start_sample", 0)) < int(right.get("start_sample", 0))
	)
	for index in range(ordered.size()):
		var cue: Dictionary = ordered[index]
		cue["previous_cue_id"] = String(ordered[index - 1].get("cue_id", "")) if index > 0 else ""
		cue["next_cue_id"] = String(ordered[index + 1].get("cue_id", "")) if index + 1 < ordered.size() else ""
		cues[String(cue.get("cue_id", ""))] = cue
	track_entry["cues"] = cues
	cue_tracks[track_id] = track_entry
	cue_catalog["tracks"] = cue_tracks


func _migrate_v1(old_catalog: Dictionary) -> Dictionary:
	var migrated := _empty_cue_catalog()
	var old_tracks = old_catalog.get("tracks", {})
	if not old_tracks is Dictionary:
		return migrated
	var migrated_tracks: Dictionary = migrated["tracks"]
	for track_id_value in old_tracks.keys():
		var track_id := String(track_id_value)
		var old_track = old_tracks.get(track_id, {})
		if not old_track is Dictionary:
			continue
		var decisions = old_track.get("decisions", {})
		if not decisions is Dictionary:
			continue
		var review: Dictionary = {}
		for candidate_id_value in decisions.keys():
			var candidate_id := String(candidate_id_value)
			var decision = decisions.get(candidate_id, {})
			if not decision is Dictionary:
				continue
			var status := String(decision.get("status", "unreviewed"))
			if status == "approved":
				var candidate := get_candidate(track_id, candidate_id)
				if candidate.is_empty():
					continue
				var source_track := get_track(track_id)
				var entry: Dictionary = migrated_tracks.get(track_id, {})
				entry["project_path"] = String(source_track.get("project_path", ""))
				entry["frame_count"] = int(source_track.get("frame_count", 0))
				var cues: Dictionary = entry.get("cues", {})
				cues[candidate_id] = _snapshot_approved_cue(candidate, String(decision.get("cue_name", "")), String(decision.get("notes", "")))
				entry["cues"] = cues
				entry["review"] = entry.get("review", {})
				migrated_tracks[track_id] = entry
			elif status == "rejected":
				review[candidate_id] = decision.duplicate(true)
		if not review.is_empty():
			var entry: Dictionary = migrated_tracks.get(track_id, {})
			entry["cues"] = entry.get("cues", {})
			entry["review"] = review
			migrated_tracks[track_id] = entry
	migrated["tracks"] = migrated_tracks
	cue_catalog = migrated
	for track_id_value in migrated_tracks.keys():
		_relink_track(String(track_id_value))
	return cue_catalog


func _empty_cue_catalog() -> Dictionary:
	return {
		"schema": CUE_SCHEMA,
		"policy": "find_test_approve_then_dj",
		"tracks": {},
	}


func _read_json(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		_fail("Catalog is missing: %s" % path)
		return {}
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		_fail("Catalog cannot be opened: %s" % path)
		return {}
	var parsed = JSON.parse_string(file.get_as_text())
	if not parsed is Dictionary:
		_fail("Catalog root is not an object: %s" % path)
		return {}
	return parsed


func _fail(message: String) -> bool:
	last_error = message
	return false
