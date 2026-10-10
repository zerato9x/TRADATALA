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
var memories: Dictionary = {}
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
		memories = file.get_value("zodiac", "memories", {})

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
	var previous_tier := int(history.relationship_tier)
	if disposition == "PLEASED":
		history["ever_pleased"] = true
		history["pleased_outcomes"] = int(history.get("pleased_outcomes", 0)) + 1
		if int(history.relationship_tier) == STRANGER:
			history.relationship_tier = FAMILIAR
			history["familiar_transitions"] = int(history.get("familiar_transitions", 0)) + 1
			seen["relationship:" + id + ":FAMILIAR"] = true
	else: history["ever_pleased"] = bool(history.get("ever_pleased", false))
	# Further tiers require concrete, varied commitments. A good answer alone cannot buy them.
	if disposition != "UNPLEASED":
		for step: Dictionary in ZodiacCatalog.persuasion_config(id).get("progression", []):
			if previous_tier != int(step.from): continue
			var distinct := 0
			for promise_id: String in step.promises:
				if int(history.get("promise_kept:" + promise_id, 0)) > 0: distinct += 1
			if int(history.get("promises_kept", 0)) < int(step.kept) or distinct < int(step.distinct): continue
			history.relationship_tier = int(step.to)
			history["kindred_transitions"] = int(history.get("kindred_transitions", 0)) + 1
			seen["relationship:" + id + ":KINDRED"] = true
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

func memory(id: String, topic: String) -> Dictionary:
	return memories.get(id, {}).get(topic, {}).duplicate(true)

func remember(id: String, event_id: String, topic: String, details: Dictionary) -> bool:
	if seen.has(event_id): return false
	seen[event_id] = true
	var history: Dictionary = records.get(id, {})
	var revision := int(history.get("memory_revision", 0)) + 1
	history["memory_revision"] = revision
	records[id] = history
	var entry := details.duplicate(true)
	entry["revision"] = revision
	entry["event_id"] = event_id
	var topics: Dictionary = memories.get(id, {})
	topics[topic] = entry
	memories[id] = topics
	save()
	return true

func eligible(id: String) -> bool:
	if not ZodiacCatalog.DEFINITIONS.has(id): return false
	var history := record(id)
	var legacy_eligible := true
	for key in ZodiacCatalog.DEFINITIONS[id].unlock:
		if int(history.get(key, 0)) < int(ZodiacCatalog.DEFINITIONS[id].unlock[key]): legacy_eligible = false
	if legacy_eligible: return true
	var requirements: Dictionary = ZodiacCatalog.persuasion_config(id).get("emblem_unlock", {})
	if requirements.is_empty(): return false
	for key in requirements:
		var value := promise_kinds(id) if key == "promise_kinds" else int(history.get(key, 0))
		if value < int(requirements[key]): return false
	return true

func promise_kinds(id: String) -> int:
	var kept := {}
	for step: Dictionary in ZodiacCatalog.persuasion_config(id).get("progression", []):
		for promise_id: String in step.promises:
			if int(records.get(id, {}).get("promise_kept:" + promise_id, 0)) > 0: kept[promise_id] = true
	return kept.size()

func snapshot() -> Dictionary:
	return {"records": records.duplicate(true), "seen": seen.duplicate(), "memories": memories.duplicate(true)}

func merge(data: Dictionary) -> void:
	for id in data.get("records", {}):
		var history: Dictionary = records.get(id, {})
		for key in data.records[id]:
			var value: Variant = data.records[id][key]
			history[key] = bool(history.get(key, false)) or value if value is bool else maxi(int(history.get(key, 0)), int(value))
		records[id] = history
	seen.merge(data.get("seen", {}))
	for id in data.get("memories", {}):
		var topics: Dictionary = memories.get(id, {})
		for topic in data.memories[id]:
			var entry: Dictionary = data.memories[id][topic]
			if int(entry.get("revision", 0)) > int(topics.get(topic, {}).get("revision", 0)):
				topics[topic] = entry.duplicate(true)
		memories[id] = topics
	save()

func save() -> void:
	if path.is_empty(): return
	if save_callback.is_valid():
		save_callback.call()
		return
	var file := ConfigFile.new()
	file.set_value("zodiac", "records", records)
	file.set_value("zodiac", "seen", seen)
	file.set_value("zodiac", "memories", memories)
	var result := file.save(path + ".tmp")
	if result == OK and FileAccess.file_exists(path): result = DirAccess.copy_absolute(path, path + ".bak")
	if result == OK: result = DirAccess.rename_absolute(path + ".tmp", path)
	error = "" if result == OK else error_string(result)
	if result != OK: push_warning("Zodiac progression save failed: " + error)
