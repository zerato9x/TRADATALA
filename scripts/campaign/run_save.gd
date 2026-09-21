class_name RunSave
extends RefCounted
## Versioned, atomic, object-free on disk. Only whitelisted value classes are reconstructed.
const VERSION := 1
const PATH := "user://run_v1.save"
const TYPES := {
	"CardData": preload("res://scripts/cards/card_data.gd"),
	"MeldState": preload("res://scripts/melds/meld_state.gd"),
	"DiscardRecord": preload("res://scripts/gameplay/discard_record.gd"),
	"PhaseSettlement": preload("res://scripts/gameplay/phase_settlement.gd"),
	"ScoringContext": preload("res://scripts/scoring/scoring_context.gd"),
}
const CAMPAIGN_FIELDS := ["difficulty", "run_seed", "endless", "_base_day_count", "current_day_index", "current_phase", "campaign_complete", "run_failed", "campaign_days", "active_deal_wallet_before_vnd", "deal_cursor", "day_cursor", "deal_reports", "day_reports", "collection_report", "activities", "day_activity_cursor"]
const DRINK_FIELDS := ["day_index", "day_target_vnd", "empty_glasses", "current_event_slot", "event_ordered", "morning_drink_id", "afternoon_drink_id", "active_drink_id"]
const GIEO_FIELDS := ["persistent_deck", "state", "current_day_index", "free_cast_used_today", "paid_cast_count_today", "current_result", "resolved_destination", "resolved_targets", "last_transformations"]
const LOTTERY_FIELDS := ["day_index", "event_slot", "_draw", "_offers", "_tickets", "_settled", "last_receipt"]
const SHOE_FIELDS := ["polish_count_today", "tip_count_today", "last_polished_ids", "_deck", "_tips_vnd", "_day_index", "_event_slot", "_favors_given"]
const SHOP_FIELDS := ["offers", "visit_id", "purchased", "rerolls", "target_vnd"]
var path: String
var error := ""
var recovered_backup := false
var _ids: Dictionary = {}
var _records: Array = []
var _objects: Array = []

func _init(save_path: String = "") -> void:
	path = save_path if not save_path.is_empty() else ("user://demo_run_v1.save" if DemoBuild.enabled() else PATH)

static func fields(object: Object, names: Array) -> Dictionary:
	var data := {}
	for field: String in names:
		data[field] = object.get(field)
	return data

static func apply_fields(object: Object, data: Dictionary, names: Array) -> void:
	for field: String in names:
		if not data.has(field):
			continue
		var existing: Variant = object.get(field)
		if existing is Array:
			existing.assign(data[field])
		else:
			object.set(field, data[field])

func capture(campaign: CampaignManager, deal: DealState) -> Dictionary:
	var event := campaign.event_manager.current_event
	return {
		"onboarding": {"learned": campaign.onboarding.learned.duplicate(), "dismissed": campaign.onboarding.dismissed.duplicate()},
		"campaign": fields(campaign, CAMPAIGN_FIELDS), "deal": deal.snapshot_state(),
		"drinks": fields(campaign.drink_manager, DRINK_FIELDS),
		"progress": {"counters": campaign.drink_manager.progress.counters.duplicate(), "seen": campaign.drink_manager.progress._seen_melds.duplicate()} if campaign.drink_manager.progress != null else {},
		"gieo": fields(campaign.gieo_que, GIEO_FIELDS), "gieo_rng": campaign.gieo_que._rng.state,
		"lottery": fields(campaign.lottery, LOTTERY_FIELDS), "lottery_rng": campaign.lottery._rng.state,
		"shoe": fields(campaign.shoe_shine, SHOE_FIELDS), "shoe_rng": campaign.shoe_shine._rng.state,
		"shop": fields(campaign.relic_shop, SHOP_FIELDS), "shop_rng": campaign.relic_shop._rng.state,
		"event": {"slot": event.slot, "context": event.context, "completed": event.completed_interactions} if event != null else {},
	}

func restore(data: Dictionary, campaign: CampaignManager, deal: DealState) -> bool:
	if not valid_snapshot(data):
		return false
	campaign.difficulty = int(data.campaign.get("difficulty", 1))
	apply_fields(campaign, data.campaign, CAMPAIGN_FIELDS)
	campaign.onboarding.reset()
	campaign.onboarding.learned = data.get("onboarding", {}).get("learned", {}).duplicate()
	campaign.onboarding.dismissed = data.get("onboarding", {}).get("dismissed", {}).duplicate()
	deal.restore_snapshot(data.deal)
	deal.wallet.economy_scaling = true
	deal.wallet.day_target_vnd = campaign.daily_requirement()
	apply_fields(campaign.drink_manager, data.drinks, DRINK_FIELDS)
	apply_fields(campaign.gieo_que, data.gieo, GIEO_FIELDS)
	apply_fields(campaign.lottery, data.lottery, LOTTERY_FIELDS)
	apply_fields(campaign.shoe_shine, data.shoe, SHOE_FIELDS)
	# Older saves lack repeat counts. Recover today's purchases from the journal.
	var today := deal.wallet.journal.slice(campaign.day_cursor)
	if not data.shoe.has("polish_count_today"):
		campaign.shoe_shine.polish_count_today = today.filter(func(entry): return entry.reason == "shoe_polish").size()
	if not data.shoe.has("tip_count_today"):
		campaign.shoe_shine.tip_count_today = today.filter(func(entry): return entry.reason == "shoe_tip").size()
	apply_fields(campaign.relic_shop, data.shop, SHOP_FIELDS)
	campaign.gieo_que._rng.state = data.gieo_rng
	campaign.lottery._rng.state = data.lottery_rng
	campaign.shoe_shine._rng.state = data.shoe_rng
	campaign.relic_shop._rng.state = data.shop_rng
	campaign.relic_shop.runtime = deal.relics
	deal.relics.shop_wallet = deal.wallet
	if campaign.drink_manager.progress != null:
		var progress := campaign.drink_manager.progress
		for metric: String in data.get("progress", {}).get("counters", {}):
			progress.counters[metric] = maxi(int(progress.counters.get(metric, 0)), int(data.progress.counters[metric]))
		progress._seen_melds = data.get("progress", {}).get("seen", {}).duplicate()
		progress._save()
	campaign.event_manager.current_event = null
	if not data.event.is_empty():
		# Rebuild locally without emitting campaign transitions or spending RNG.
		var event := EventInstance.new(int(data.event.slot), data.event.context)
		for definition: NPCDefinition in campaign.event_manager.npc_definitions.values():
			if definition.is_eligible(event.slot, event.context):
				event.participants.append(definition)
				event.interactions.append_array(definition.build_interactions(event.slot))
		for id: String in data.event.completed:
			event.complete_interaction(id)
		event.update_can_exit()
		campaign.event_manager.current_event = event
	return true

func valid_snapshot(data: Dictionary) -> bool:
	for key in ["campaign", "deal", "drinks", "gieo", "lottery", "shoe", "shop", "event"]:
		if not data.get(key) is Dictionary:
			return false
	for key in ["gieo_rng", "lottery_rng", "shoe_rng", "shop_rng"]:
		if not data.get(key) is int:
			return false
	var c: Dictionary = data.campaign
	if not c.get("campaign_days") is Array or c.get("run_seed", "").is_empty():
		return false
	if int(c.get("current_day_index", -1)) < 0 or int(c.current_day_index) >= c.campaign_days.size():
		return false
	if int(c.get("current_phase", -1)) not in range(CampaignManager.CampaignPhase.CAMPAIGN_FAILURE + 1):
		return false
	return data.deal.get("hand") is Array and data.deal.get("deck") is Dictionary and data.gieo.get("persistent_deck", []).size() == 52

func save_run(campaign: CampaignManager, deal: DealState) -> bool:
	return write_snapshot(capture(campaign, deal))

func write_snapshot(data: Dictionary) -> bool:
	error = ""
	_ids.clear()
	_records.clear()
	var root: Variant = _encode(data)
	if not error.is_empty():
		return false
	var payload := {"root": root, "objects": _records}
	var bytes := var_to_bytes(payload)
	var envelope := {"version": VERSION, "payload": bytes, "sha256": _digest(bytes)}
	var file := FileAccess.open(path + ".tmp", FileAccess.WRITE)
	if file == null:
		error = error_string(FileAccess.get_open_error())
		return false
	file.store_var(envelope, false)
	file.flush()
	var write_error := file.get_error()
	file.close()
	if write_error != OK:
		error = error_string(write_error)
		return false
	# Keep the previous complete file. Never replace it with a failed partial write.
	if FileAccess.file_exists(path) and not recovered_backup:
		var backup_error := DirAccess.copy_absolute(path, path + ".bak")
		if backup_error != OK:
			error = error_string(backup_error)
			return false
	var result := DirAccess.rename_absolute(path + ".tmp", path)
	if result != OK:
		error = error_string(result)
	if result == OK:
		recovered_backup = false
	return result == OK

func load_run() -> Dictionary:
	recovered_backup = false
	var data := _read(path)
	if data.is_empty() and FileAccess.file_exists(path + ".bak"):
		data = _read(path + ".bak")
		recovered_backup = not data.is_empty()
	return data

func _read(source: String) -> Dictionary:
	error = ""
	if not FileAccess.file_exists(source):
		return {}
	var file := FileAccess.open(source, FileAccess.READ)
	if file == null or file.get_length() > 64 * 1024 * 1024 or file.get_length() < 8:
		error = "Invalid save file"
		return {}
	var envelope: Variant = file.get_var(false)
	file.close()
	if not envelope is Dictionary or int(envelope.get("version", -1)) != VERSION or not envelope.get("payload") is PackedByteArray:
		error = "Unsupported or damaged save"
		return {}
	if _digest(envelope.payload) != envelope.get("sha256", ""):
		error = "Save checksum mismatch"
		return {}
	var payload: Variant = bytes_to_var(envelope.payload)
	if not payload is Dictionary or not payload.get("objects") is Array or payload.objects.size() > 100_000:
		error = "Invalid save payload"
		return {}
	_objects.clear()
	for record: Dictionary in payload.objects:
		if not TYPES.has(record.get("type", "")):
			error = "Unknown saved value type"
			return {}
		_objects.append(TYPES[record.type].new())
	for index in payload.objects.size():
		var value: Object = _objects[index]
		var names := _field_names(value)
		var decoded: Variant = _decode(payload.objects[index].fields)
		if not decoded is Dictionary or not error.is_empty():
			return {}
		apply_fields(value, decoded, names)
	var result: Variant = _decode(payload.get("root"))
	if not result is Dictionary or not error.is_empty() or not valid_snapshot(result):
		error = "Incomplete save"
		return {}
	return result

static func _digest(bytes: PackedByteArray) -> String:
	var hashing := HashingContext.new()
	hashing.start(HashingContext.HASH_SHA256)
	hashing.update(bytes)
	return hashing.finish().hex_encode()

static func _field_names(value: Object) -> Array:
	var names := []
	for property: Dictionary in value.get_property_list():
		if int(property.usage) & PROPERTY_USAGE_SCRIPT_VARIABLE:
			names.append(String(property.name))
	return names

func _encode(value: Variant) -> Variant:
	if value is Object:
		if value == null:
			return null
		var type_name := ""
		for key: String in TYPES:
			if value.get_script() == TYPES[key]:
				type_name = key
		if type_name.is_empty():
			error = "Unsupported saved value"
			return null
		var instance: int = value.get_instance_id()
		if not _ids.has(instance):
			_ids[instance] = _records.size()
			_records.append({"type": type_name, "fields": {}})
			_records[_ids[instance]].fields = _encode(fields(value, _field_names(value)))
		return {"ref": _ids[instance]}
	if value is Array:
		var items := []
		for item: Variant in value:
			items.append(_encode(item))
		return {"array": items}
	if value is Dictionary:
		var pairs := []
		for key: Variant in value:
			pairs.append([_encode(key), _encode(value[key])])
		return {"dict": pairs}
	return value

func _decode(value: Variant) -> Variant:
	if not value is Dictionary:
		return value
	if value.has("ref"):
		var index := int(value.ref)
		if index < 0 or index >= _objects.size():
			error = "Invalid saved reference"
			return null
		return _objects[index]
	if value.has("array"):
		var array := []
		for item: Variant in value.array:
			array.append(_decode(item))
		return array
	if value.has("dict"):
		var dictionary := {}
		for pair: Array in value.dict:
			dictionary[_decode(pair[0])] = _decode(pair[1])
		return dictionary
	error = "Invalid saved value"
	return null
