class_name MusicArrangementCatalog
extends RefCounted

const DEFAULT_PATH := "res://assets/audio/ost/ost_arrangements.json"
const SCHEMA := "tradatala.ost_arrangements.v1"
const LOOP_CATALOG_PATH := "res://assets/audio/ost/ost_loops.json"

var catalog_path := DEFAULT_PATH
var catalog: Dictionary = {}
var last_error := ""


func load_catalog(path: String = "") -> bool:
	if not path.is_empty():
		catalog_path = path
	if not FileAccess.file_exists(catalog_path):
		catalog = _empty_catalog()
		last_error = ""
		return true
	var file := FileAccess.open(catalog_path, FileAccess.READ)
	if file == null:
		return _fail("Arrangement catalog cannot be opened: %s" % catalog_path)
	var parsed = JSON.parse_string(file.get_as_text())
	if not parsed is Dictionary:
		return _fail("Arrangement catalog root is not an object: %s" % catalog_path)
	if parsed.get("schema", "") != SCHEMA:
		return _fail("Unsupported arrangement catalog schema: %s" % String(parsed.get("schema", "<missing>")))
	var tracks = parsed.get("tracks", {})
	if not tracks is Dictionary:
		return _fail("Arrangement catalog tracks must be an object")
	catalog = parsed
	last_error = ""
	return true


func get_sections(track_id: String) -> Array[Dictionary]:
	var tracks: Dictionary = catalog.get("tracks", {})
	var track_value = tracks.get(track_id, {})
	if not track_value is Dictionary:
		return [] as Array[Dictionary]
	var raw_sections = (track_value as Dictionary).get("sections", [])
	if not raw_sections is Array:
		return [] as Array[Dictionary]
	var sections: Array[Dictionary] = []
	for value in raw_sections:
		if value is Dictionary:
			sections.append((value as Dictionary).duplicate(true))
	return sections


func set_sections(track_id: String, sections: Array[Dictionary]) -> void:
	if catalog.is_empty():
		catalog = _empty_catalog()
	var tracks: Dictionary = catalog.get("tracks", {})
	tracks[track_id] = {"sections": sections.duplicate(true)}
	catalog["tracks"] = tracks


func save_catalog(path: String = "") -> bool:
	var target := catalog_path if path.is_empty() else path
	if catalog.is_empty():
		catalog = _empty_catalog()
	var file := FileAccess.open(target, FileAccess.WRITE)
	if file == null:
		return _fail("Arrangement catalog cannot be written: %s" % target)
	file.store_string(JSON.stringify(catalog, "  ") + "\n")
	last_error = ""
	return true


func _empty_catalog() -> Dictionary:
	return {
		"schema": SCHEMA,
		"source_loop_catalog": LOOP_CATALOG_PATH,
		"policy": "manual_section_arrangement",
		"tracks": {},
	}


func _fail(message: String) -> bool:
	last_error = message
	return false
