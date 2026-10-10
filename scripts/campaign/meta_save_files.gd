class_name MetaSaveFiles
extends RefCounted
## One permanent profile per file; run checkpoints remain separate from unlocks.
const VERSION := 1
const SLOT_COUNT := 3
const MAX_FILE_BYTES := 16 * 1024 * 1024
const Difficulty := preload("res://scripts/campaign/difficulty_progress.gd")
var root: String
var legacy_root: String
var active_slot := 1
var data: Dictionary = {}
var error := ""
var recovered_backup := false
var suspended := false
var _campaign: WeakRef
var _damaged := false
var _json_error := false
var max_file_bytes := MAX_FILE_BYTES

func _init(directory: String = "", migration_root: String = "user://") -> void:
	root = directory.trim_suffix("/") if not directory.is_empty() else "user://save_files/" + ("demo" if DemoBuild.enabled() else "full")
	legacy_root = migration_root
	var selected := _read_selection(root + "/active.cfg")
	if selected < 1: selected = _read_selection(root + "/active.cfg.bak")
	active_slot = selected if selected > 0 else 1
	_load_slot(active_slot)

func meta_path(slot: int = -1) -> String:
	return "%s/file_%d.meta.save" % [root, active_slot if slot < 0 else slot]

func run_path(slot: int = -1) -> String:
	return "%s/file_%d.run.save" % [root, active_slot if slot < 0 else slot]

func _fresh(slot: int) -> Dictionary:
	return {"slot": slot, "name": "", "created_at": int(Time.get_unix_time_from_system()), "saved_at": 0,
		"difficulty_unlocked": 1, "drink_counters": {}, "zodiac": {"records": {}, "seen": {}}, "run_summary": {}}

func _load_slot(slot: int) -> bool:
	error = ""
	recovered_backup = false
	_damaged = false
	var loaded := _read(meta_path(slot), slot)
	if loaded.is_empty() and FileAccess.file_exists(meta_path(slot) + ".bak"):
		loaded = _read(meta_path(slot) + ".bak", slot)
		recovered_backup = not loaded.is_empty()
	if not loaded.is_empty():
		if int(loaded.slot) != slot:
			error = "Save file identity does not match its slot."
			_damaged = true
			data = _fresh(slot)
			return false
		data = loaded
		return true
	if FileAccess.file_exists(meta_path(slot)) or FileAccess.file_exists(meta_path(slot) + ".bak"):
		_damaged = true
		if error.is_empty(): error = "Permanent progress could not be recovered."
		data = _fresh(slot)
		return false
	data = _fresh(slot)
	if slot == 1 and not legacy_root.is_empty():
		_import_legacy()
		if not error.is_empty(): return false
	return _write(data, false)

func attach(campaign: RefCounted) -> void:
	_campaign = weakref(campaign)
	var drinks := DrinkProgress.new("")
	drinks.counters = data.get("drink_counters", {}).duplicate(true)
	drinks.save_path = meta_path()
	drinks.save_callback = _persist_attached
	campaign.drink_manager.progress = drinks
	var zodiac := ZodiacProgress.new("")
	zodiac.records = data.get("zodiac", {}).get("records", {}).duplicate(true)
	zodiac.seen = data.get("zodiac", {}).get("seen", {}).duplicate()
	zodiac.memories = data.get("zodiac", {}).get("memories", {}).duplicate(true)
	zodiac.path = meta_path()
	zodiac.save_callback = _persist_attached
	campaign.zodiac.progress = zodiac
	var difficulty = Difficulty.new("")
	difficulty.unlocked = int(data.get("difficulty_unlocked", 1))
	difficulty.path = meta_path()
	difficulty.save_callback = _persist_attached
	campaign.difficulty_progress = difficulty

func _persist_attached() -> bool:
	if suspended: return true
	var campaign: RefCounted = _campaign.get_ref() if _campaign != null else null
	if campaign == null: return false
	var next := data.duplicate(true)
	next.drink_counters = campaign.drink_manager.progress.counters.duplicate(true)
	next.zodiac = campaign.zodiac.progress.snapshot()
	next.difficulty_unlocked = campaign.difficulty_progress.unlocked
	# Retain the last real run summary when the player is at the title screen.
	if not campaign.run_seed.is_empty() and campaign.current_day_index >= 0:
		next.run_summary = {"seed": campaign.run_seed, "day": campaign.current_day_index + 1, "difficulty": campaign.difficulty,
			"wallet_vnd": campaign.wallet.balance_vnd, "endless": campaign.endless, "complete": campaign.campaign_complete, "failed": campaign.run_failed}
	return _write(next, recovered_backup)

func save() -> bool:
	return _persist_attached()

func select(slot: int, campaign: RefCounted) -> bool:
	if suspended or slot < 1 or slot > SLOT_COUNT: return false
	if slot == active_slot: return not _damaged
	if not _damaged and not save(): return false
	var old := {"slot": active_slot, "data": data, "error": error, "backup": recovered_backup, "damaged": _damaged}
	if not _load_slot(slot):
		var failure := error
		active_slot = old.slot; data = old.data; recovered_backup = old.backup; _damaged = old.damaged
		error = failure
		return false
	active_slot = slot
	if not _save_selection():
		active_slot = old.slot; data = old.data; recovered_backup = old.backup; _damaged = old.damaged
		return false
	attach(campaign)
	return true

func rename_file(name: String) -> bool:
	if suspended: return false
	var next := data.duplicate(true)
	next.name = name.strip_edges().left(40)
	return _write(next, recovered_backup)

func summaries() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	var previous_error := error
	for slot in range(1, SLOT_COUNT + 1):
		var item := data.duplicate(true) if slot == active_slot else _read(meta_path(slot), slot)
		var exists := FileAccess.file_exists(meta_path(slot)) or FileAccess.file_exists(meta_path(slot) + ".bak")
		var backup := recovered_backup if slot == active_slot else false
		if item.is_empty() and FileAccess.file_exists(meta_path(slot) + ".bak"):
			item = _read(meta_path(slot) + ".bak", slot)
			backup = not item.is_empty()
		var damaged := _damaged if slot == active_slot else exists and item.is_empty()
		if item.is_empty(): item = _fresh(slot)
		item["exists"] = exists
		item["damaged"] = damaged
		item["backup"] = backup
		item["active"] = slot == active_slot
		item["has_run"] = FileAccess.file_exists(run_path(slot)) or FileAccess.file_exists(run_path(slot) + ".bak")
		result.append(item)
	error = previous_error
	return result

func _save_selection() -> bool:
	var file := ConfigFile.new()
	file.set_value("files", "active", active_slot)
	var path := root + "/active.cfg"
	var status := file.save(path + ".tmp")
	if status == OK and _read_selection(path) > 0: status = DirAccess.copy_absolute(path, path + ".bak")
	if status == OK: status = DirAccess.rename_absolute(path + ".tmp", path)
	if status != OK: error = error_string(status)
	return status == OK

func _write(next: Dictionary, keep_backup: bool) -> bool:
	if _damaged or suspended: return false
	if not _valid(next): error = "Invalid permanent progress."; return false
	var status := DirAccess.make_dir_recursive_absolute(root)
	if status != OK: error = error_string(status); return false
	next.saved_at = int(Time.get_unix_time_from_system())
	var payload := JSON.stringify(_pack_json(next))
	var bytes := payload.to_utf8_buffer()
	var envelope := JSON.stringify({"version": VERSION, "payload": payload, "sha256": RunSave.payload_digest(bytes)})
	if envelope.to_utf8_buffer().size() > max_file_bytes: error = "Permanent progress exceeds the save limit."; return false
	var destination := meta_path(int(next.slot))
	var file := FileAccess.open(destination + ".tmp", FileAccess.WRITE)
	if file == null: error = error_string(FileAccess.get_open_error()); return false
	file.store_string(envelope)
	file.flush()
	status = file.get_error()
	file.close()
	if status == OK and FileAccess.file_exists(destination) and not keep_backup:
		status = DirAccess.copy_absolute(destination, destination + ".bak")
	if status == OK: status = DirAccess.rename_absolute(destination + ".tmp", destination)
	if status != OK: error = error_string(status); return false
	data = next
	error = ""
	recovered_backup = false
	return true

func _read(source: String, expected_slot: int = -1) -> Dictionary:
	if not FileAccess.file_exists(source): return {}
	var file := FileAccess.open(source, FileAccess.READ)
	if file == null: error = error_string(FileAccess.get_open_error()); return {}
	if file.get_length() > max_file_bytes or file.get_length() < 8:
		file.close(); error = "Invalid permanent save size."; return {}
	var text := file.get_as_text()
	file.close()
	var parser := JSON.new()
	if parser.parse(text) != OK: error = "Damaged permanent save."; return {}
	var envelope: Variant = parser.data
	if not envelope is Dictionary or typeof(envelope.get("version")) not in [TYPE_INT, TYPE_FLOAT] or envelope.version != VERSION or not envelope.get("payload") is String:
		error = "Unsupported or damaged permanent save."; return {}
	if RunSave.payload_digest(envelope.payload.to_utf8_buffer()) != envelope.get("sha256", ""):
		error = "Permanent save checksum mismatch."; return {}
	if parser.parse(envelope.payload) != OK: error = "Invalid permanent save payload."; return {}
	_json_error = false
	var contents: Variant = _unpack_json(parser.data)
	if _json_error or not contents is Dictionary or not _valid(contents): error = "Invalid permanent save data."; return {}
	if expected_slot > 0 and int(contents.slot) != expected_slot:
		error = "Save file identity does not match its slot."; return {}
	error = ""
	return contents

func _valid(value: Dictionary) -> bool:
	if not value.get("slot") is int or int(value.slot) not in range(1, SLOT_COUNT + 1): return false
	if not value.get("name") is String or value.name.length() > 40: return false
	if not value.get("difficulty_unlocked") is int or int(value.difficulty_unlocked) not in range(1, Difficulty.MAX_LEVEL + 1): return false
	if not value.get("drink_counters") is Dictionary or not value.get("zodiac") is Dictionary or not value.get("run_summary", {}) is Dictionary: return false
	for metric in value.drink_counters:
		if not _text_key(metric) or not value.drink_counters[metric] is int or int(value.drink_counters[metric]) < 0: return false
	for key in ["records", "seen"]:
		if not value.zodiac.get(key) is Dictionary: return false
	for id in value.zodiac.records:
		if not _text_key(id) or not value.zodiac.records[id] is Dictionary: return false
		for key in value.zodiac.records[id]:
			var entry: Variant = value.zodiac.records[id][key]
			if not _text_key(key) or not (entry is bool or entry is int) or (entry is int and entry < 0): return false
	for key in value.zodiac.seen:
		if not _text_key(key) or not value.zodiac.seen[key] is bool: return false
	if not value.zodiac.get("memories", {}) is Dictionary: return false
	for id in value.zodiac.get("memories", {}):
		if not _text_key(id) or not value.zodiac.memories[id] is Dictionary: return false
		for topic in value.zodiac.memories[id]:
			var entry: Variant = value.zodiac.memories[id][topic]
			if not _text_key(topic) or not entry is Dictionary: return false
			if not entry.get("revision") is int or int(entry.revision) < 1: return false
			if entry.get("result", "") not in ["FULFILLED", "BROKEN", "REFUSED"]: return false
			for key in ["event_id", "node_id", "target_id", "target_label", "relic_id"]:
				if not entry.get(key) is String: return false
			if not entry.get("counteroffer") is bool: return false
			if entry.has("commitment_en") or entry.has("commitment_vi"):
				if not entry.get("commitment_en") is String or not entry.get("commitment_vi") is String: return false
	return _plain(value, 0)

func _text_key(value: Variant) -> bool:
	return value is String or value is StringName

func _plain(value: Variant, depth: int) -> bool:
	if depth > 12: return false
	if value is Dictionary:
		for key in value:
			if not _text_key(key) or not _plain(value[key], depth + 1): return false
		return true
	return value == null or value is String or value is int or value is bool

func _import_legacy() -> void:
	var prefix := legacy_root.trim_suffix("/") + "/"
	var drinks := DrinkProgress.new(prefix + "demo_drink_progress.cfg")
	var difficulty = Difficulty.new(prefix + "difficulty_progress.cfg")
	var zodiac := ZodiacProgress.new(prefix + "zodiac_progress_v1.cfg")
	data.drink_counters = drinks.counters.duplicate(true)
	data.difficulty_unlocked = difficulty.unlocked
	data.zodiac = zodiac.snapshot()
	var old_run := prefix + ("demo_run_v1.save" if DemoBuild.enabled() else "run_v1.save")
	DirAccess.make_dir_recursive_absolute(root)
	for suffix in ["", ".bak"]:
		if FileAccess.file_exists(old_run + suffix) and not FileAccess.file_exists(run_path(1) + suffix):
			var status := DirAccess.copy_absolute(old_run + suffix, run_path(1) + suffix)
			if status != OK: error = "Legacy run import: " + error_string(status); return
	data["legacy_imported"] = true


# JSON is safe to parse even when interrupted or damaged. Integer tags retain the
# exact 64-bit values which JSON's floating-point number parser cannot preserve.
func _pack_json(value: Variant) -> Variant:
	if value is int: return {"__int64": str(value)}
	if value is Dictionary:
		var result := {}
		for key in value: result[String(key)] = _pack_json(value[key])
		return result
	return value

func _unpack_json(value: Variant, depth: int = 0) -> Variant:
	if depth > 14: _json_error = true; return null
	if value is Dictionary:
		if value.size() == 1 and value.get("__int64") is String:
			var text: String = value.__int64
			if not text.is_valid_int() or str(text.to_int()) != text: _json_error = true; return null
			return text.to_int()
		var result := {}
		for key in value: result[key] = _unpack_json(value[key], depth + 1)
		return result
	return value

func usable() -> bool:
	return not _damaged


func _read_selection(path: String) -> int:
	if not FileAccess.file_exists(path): return -1
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null: return -1
	if file.get_length() > 4096: file.close(); return -1
	var text := file.get_as_text()
	file.close()
	if not text.contains("[files]"): return -1
	for line: String in text.split("\n"):
		if not line.begins_with("active="): continue
		var number := line.trim_prefix("active=").strip_edges()
		if not number.is_valid_int(): return -1
		var slot := number.to_int()
		return slot if slot in range(1, SLOT_COUNT + 1) else -1
	return -1
