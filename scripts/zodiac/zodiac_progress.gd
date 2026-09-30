class_name ZodiacProgress
extends RefCounted
## Concrete, monotonic history. Event IDs make replaying an old run save idempotent.
const PATH := "user://zodiac_progress_v1.cfg"
var path: String
var records: Dictionary = {}
var seen: Dictionary = {}
var error := ""

func _init(save_path: String = PATH) -> void:
	path = save_path
	if path.is_empty(): return
	var file := ConfigFile.new()
	var result := file.load(path)
	if result != OK: result = file.load(path + ".bak")
	if result == OK:
		records = file.get_value("zodiac", "records", {})
		seen = file.get_value("zodiac", "seen", {})

func record(id: String) -> Dictionary:
	return records.get(id, {}).duplicate(true)

func commit(id: String, event_id: String, increments: Dictionary = {}, flags: Array = []) -> void:
	if seen.has(event_id): return
	seen[event_id] = true
	var history: Dictionary = records.get(id, {})
	for key in increments:
		history[key] = int(history.get(key, 0)) + maxi(0, int(increments[key]))
	for key in flags: history[key] = true
	records[id] = history
	save()

func owns(id: String) -> bool:
	return bool(records.get(id, {}).get("emblem_unlocked", false))

func eligible(id: String) -> bool:
	if not ZodiacCatalog.DEFINITIONS.has(id): return false
	var history := record(id)
	for key in ZodiacCatalog.DEFINITIONS[id].unlock:
		if int(history.get(key, 0)) < int(ZodiacCatalog.DEFINITIONS[id].unlock[key]): return false
	return true

func snapshot() -> Dictionary:
	return {"records": records.duplicate(true), "seen": seen.duplicate()}

func merge(data: Dictionary) -> void:
	for id in data.get("records", {}):
		var history: Dictionary = records.get(id, {})
		for key in data.records[id]:
			var value: Variant = data.records[id][key]
			history[key] = bool(history.get(key, false)) or value if value is bool else maxi(int(history.get(key, 0)), int(value))
		records[id] = history
	seen.merge(data.get("seen", {}))
	save()

func save() -> void:
	if path.is_empty(): return
	var file := ConfigFile.new()
	file.set_value("zodiac", "records", records)
	file.set_value("zodiac", "seen", seen)
	var result := file.save(path + ".tmp")
	if result == OK and FileAccess.file_exists(path): result = DirAccess.copy_absolute(path, path + ".bak")
	if result == OK: result = DirAccess.rename_absolute(path + ".tmp", path)
	error = "" if result == OK else error_string(result)
	if result != OK: push_warning("Zodiac progression save failed: " + error)
