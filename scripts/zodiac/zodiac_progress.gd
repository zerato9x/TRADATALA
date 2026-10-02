class_name ZodiacProgress
extends RefCounted
## Concrete, monotonic history. Event IDs make replaying an old run save idempotent.
const PATH := "user://zodiac_progress_v1.cfg"
const STRANGER := 1
const FAMILIAR := 2
const KINDRED := 3
const CONFIDANT := 4
const COMPANION := 5
var path: String
var save_callback: Callable
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

func relationship_tier(id: String) -> int:
	return clampi(int(records.get(id, {}).get("relationship_tier", STRANGER)), STRANGER, COMPANION)

func meet(id: String, event_id: String) -> void:
	commit(id, event_id, {"encounters": 1}, ["first_meeting"])
	var history: Dictionary = records.get(id, {})
	if not history.has("relationship_tier"):
		history["relationship_tier"] = STRANGER
		history["ever_pleased"] = false
		records[id] = history
		save()

func record_disposition(id: String, event_id: String, disposition: String) -> bool:
	if disposition not in ["PLEASED", "NORMAL", "UNPLEASED"] or seen.has(event_id): return false
	seen[event_id] = true
	var history: Dictionary = records.get(id, {})
	history["first_meeting"] = true
	history["relationship_tier"] = relationship_tier(id)
	if disposition == "PLEASED":
		history["ever_pleased"] = true
		history["pleased_outcomes"] = int(history.get("pleased_outcomes", 0)) + 1
		if int(history.relationship_tier) == STRANGER:
			history.relationship_tier = FAMILIAR
			history["familiar_transitions"] = int(history.get("familiar_transitions", 0)) + 1
			seen["relationship:" + id + ":FAMILIAR"] = true
	else: history["ever_pleased"] = bool(history.get("ever_pleased", false))
	records[id] = history
	save()
	return true

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
	if save_callback.is_valid():
		save_callback.call()
		return
	var file := ConfigFile.new()
	file.set_value("zodiac", "records", records)
	file.set_value("zodiac", "seen", seen)
	var result := file.save(path + ".tmp")
	if result == OK and FileAccess.file_exists(path): result = DirAccess.copy_absolute(path, path + ".bak")
	if result == OK: result = DirAccess.rename_absolute(path + ".tmp", path)
	error = "" if result == OK else error_string(result)
	if result != OK: push_warning("Zodiac progression save failed: " + error)
