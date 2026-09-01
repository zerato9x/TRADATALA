class_name MusicCueCatalog
extends RefCounted

const LOOP_CATALOG_PATH := "res://assets/audio/ost/ost_loops.json"
const CUE_CATALOG_PATH := "res://assets/audio/ost/ost_cues.json"
const LOOP_SCHEMA := "tradatala.ost_loops.v1"
const CUE_SCHEMA := "tradatala.ost_cues.v1"
const VALID_STATUSES := [&"unreviewed", &"approved", &"rejected"]

var loop_catalog_path := LOOP_CATALOG_PATH
var cue_catalog_path := CUE_CATALOG_PATH
var loop_catalog: Dictionary = {}
var cue_catalog: Dictionary = {}
var tracks: Dictionary = {}
var last_error := ""


func load_catalogs(loop_path := "", cue_path := "") -> bool:
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
		if cue_catalog.get("schema", "") != CUE_SCHEMA:
			return _fail("Unsupported cue catalog schema: %s" % String(cue_catalog.get("schema", "<missing>")))
	else:
		cue_catalog = _empty_cue_catalog()
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
	for candidate in get_candidates(track_id, false):
		if String(candidate.get("candidate_id", "")) == candidate_id:
			return candidate
	return {}


func get_decision(track_id: String, candidate_id: String) -> Dictionary:
	var track_decisions = cue_catalog.get("tracks", {}).get(track_id, {})
	if not track_decisions is Dictionary:
		return {}
	var decision = track_decisions.get("decisions", {}).get(candidate_id, {})
	return decision if decision is Dictionary else {}


func get_manual_status(track_id: String, candidate_id: String) -> StringName:
	return StringName(get_decision(track_id, candidate_id).get("status", "unreviewed"))


func set_manual_decision(track_id: String, candidate_id: String, status: StringName, cue_name := "", notes := "") -> bool:
	if not VALID_STATUSES.has(status):
		return _fail("Invalid cue status: %s" % String(status))
	if get_candidate(track_id, candidate_id).is_empty():
		return _fail("Unknown candidate: %s / %s" % [track_id, candidate_id])
	var cue_tracks: Dictionary = cue_catalog.get("tracks", {})
	if not cue_tracks.has(track_id):
		cue_tracks[track_id] = {"decisions": {}}
	var track_entry: Dictionary = cue_tracks[track_id]
	var decisions: Dictionary = track_entry.get("decisions", {})
	if status == &"unreviewed":
		decisions.erase(candidate_id)
	else:
		decisions[candidate_id] = {
			"status": String(status),
			"cue_name": cue_name.strip_edges(),
			"notes": notes.strip_edges(),
			"updated_at_utc": Time.get_datetime_string_from_system(true),
		}
	track_entry["decisions"] = decisions
	cue_tracks[track_id] = track_entry
	cue_catalog["tracks"] = cue_tracks
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
	var approved: Array[Dictionary] = []
	for candidate in get_candidates(track_id, false):
		var candidate_id := String(candidate.get("candidate_id", ""))
		var decision := get_decision(track_id, candidate_id)
		if decision.get("status", "") != "approved":
			continue
		var cue := candidate.duplicate(true)
		cue["manual_status"] = "approved"
		cue["cue_name"] = String(decision.get("cue_name", ""))
		cue["notes"] = String(decision.get("notes", ""))
		approved.append(cue)
	approved.sort_custom(func(left: Dictionary, right: Dictionary) -> bool:
		var left_bar := int(left.get("bar_start", 0))
		var right_bar := int(right.get("bar_start", 0))
		return left_bar < right_bar if left_bar != right_bar else int(left.get("bar_count", 0)) < int(right.get("bar_count", 0))
	)
	return approved


func _empty_cue_catalog() -> Dictionary:
	return {
		"schema": CUE_SCHEMA,
		"source_loop_catalog": LOOP_CATALOG_PATH,
		"policy": "manual_listening_is_authority",
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
