class_name RunSave
extends RefCounted
## Versioned, atomic, object-free on disk. Only whitelisted value classes are reconstructed.
const VERSION := 3
const MAX_FILE_BYTES := 64 * 1024 * 1024
const MAX_OBJECTS := 100_000
# These archives contain only committed value snapshots, never live Objects.
# Keep them in native Variant containers instead of allocating a recursive
# key/value wrapper for every old scoring hit on every autosave.
const VALUE_ARCHIVES := ["campaign/deal_reports", "campaign/day_reports", "campaign/activities", "campaign/collection_report", "deal/wallet_journal", "deal/action_history"]
const PATH := "user://run_v1.save"
const TYPES := {
	"CardData": preload("res://scripts/cards/card_data.gd"),
	"MeldState": preload("res://scripts/melds/meld_state.gd"),
	"DiscardRecord": preload("res://scripts/gameplay/discard_record.gd"),
	"PhaseSettlement": preload("res://scripts/gameplay/phase_settlement.gd"),
	"ScoringContext": preload("res://scripts/scoring/scoring_context.gd"),
}
var path: String
var error := ""
var recovered_backup := false
# Per-instance limits also let boundary tests use small fixtures.
var max_file_bytes := MAX_FILE_BYTES
var max_objects := MAX_OBJECTS
var _ids: Dictionary = {}
var _records: Array = []
var _objects: Array = []

func _init(save_path: String = "") -> void:
	path = save_path if not save_path.is_empty() else ("user://demo_run_v1.save" if DemoBuild.enabled() else PATH)

func capture(campaign: CampaignManager, deal: DealState, copy_history: bool = true, music: Dictionary = {}) -> Dictionary:
	var event := campaign.event_manager.current_event
	return {
		"music": music,
		"zodiac": campaign.zodiac.snapshot(),
		"onboarding": campaign.onboarding.run_snapshot(),
		"campaign": campaign.run_snapshot(), "deal": deal.snapshot_state(copy_history),
		"drinks": campaign.drink_manager.run_snapshot(),
		"progress": campaign.drink_manager.progress.run_snapshot() if campaign.drink_manager.progress != null else {},
		"gieo": campaign.gieo_que.run_snapshot(), "gieo_rng": campaign.gieo_que.run_rng_state(),
		"lottery": campaign.lottery.run_snapshot(), "lottery_rng": campaign.lottery.run_rng_state(),
		"shoe": campaign.shoe_shine.run_snapshot(), "shoe_rng": campaign.shoe_shine.run_rng_state(),
		"shop": campaign.relic_shop.run_snapshot(), "shop_rng": campaign.relic_shop.run_rng_state(),
		"event": {"slot": event.slot, "context": event.context, "completed": event.completed_interactions} if event != null else {},
	}

func restore(data: Dictionary, campaign: CampaignManager, deal: DealState) -> bool:
	if not valid_snapshot(data):
		return false
	campaign.zodiac.begin_run_restore()
	campaign.debug_context = data.campaign.get("debug_context", {}).duplicate(true)
	campaign.difficulty = int(data.campaign.get("difficulty", 1))
	campaign.restore_run_snapshot(data.campaign)
	campaign.zodiac.restore(data.get("zodiac", {}))
	campaign.onboarding.restore_run_snapshot(data.get("onboarding", {}))
	deal.restore_snapshot(data.deal)
	deal.wallet.economy_scaling = true
	deal.wallet.day_target_vnd = campaign.daily_requirement()
	campaign.drink_manager.restore_run_snapshot(data.drinks)
	campaign.gieo_que.restore_run_snapshot(data.gieo)
	campaign.lottery.restore_run_snapshot(data.lottery)
	campaign.shoe_shine.restore_run_snapshot(data.shoe)
	campaign.relic_shop.restore_run_snapshot(data.shop)
	campaign.gieo_que.restore_run_rng(data.gieo_rng)
	campaign.lottery.restore_run_rng(data.lottery_rng)
	campaign.shoe_shine.restore_run_rng(data.shoe_rng)
	campaign.relic_shop.restore_run_rng(data.shop_rng)
	campaign.relic_shop.runtime = deal.relics
	deal.relics.shop_wallet = deal.wallet
	campaign.bind_deal(deal)
	campaign.synchronize_run_deck(false)
	if campaign.drink_manager.progress != null:
		campaign.drink_manager.progress.restore_run_snapshot(data.get("progress", {}))
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
	campaign.zodiac.finish_run_restore()
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
	if int(c.get("current_phase", -1)) not in range(CampaignManager.CampaignPhase.DRAGON_DEAL + 1):
		return false
	var cards: Variant = data.gieo.get("persistent_deck", [])
	if not cards is Array or cards.size() < DealState.MIN_CAMPAIGN_CARDS: return false
	var ids := {}
	for card in cards:
		if not card is CardData or card.unique_id.is_empty() or ids.has(card.unique_id): return false
		ids[card.unique_id] = true
	return data.deal.get("hand") is Array and data.deal.get("deck") is Dictionary

func save_run(campaign: CampaignManager, deal: DealState, music: Dictionary = {}) -> bool:
	# Synchronous serialization finishes before gameplay can mutate the arrays.
	return write_snapshot(capture(campaign, deal, false, music))

func write_snapshot(data: Dictionary) -> bool:
	error = ""
	_ids.clear()
	_records.clear()
	var root: Variant = _encode(data)
	if not error.is_empty():
		return false
	if _records.size() > max_objects:
		error = "Save exceeds the supported object limit"
		return false
	var payload := {"root": root, "objects": _records}
	var bytes := var_to_bytes(payload)
	var envelope := {"version": VERSION, "payload": bytes, "sha256": payload_digest(bytes)}
	var file := FileAccess.open(path + ".tmp", FileAccess.WRITE)
	if file == null:
		error = error_string(FileAccess.get_open_error())
		return false
	file.store_var(envelope, false)
	file.flush()
	var write_error := file.get_error()
	var file_bytes := file.get_length()
	file.close()
	if write_error != OK:
		error = error_string(write_error)
		return false
	if file_bytes > max_file_bytes:
		error = "Save exceeds the supported file size limit"
		DirAccess.remove_absolute(path + ".tmp")
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
	if file == null or file.get_length() > max_file_bytes or file.get_length() < 8:
		error = "Invalid save file"
		return {}
	var envelope: Variant = file.get_var(false)
	file.close()
	if not envelope is Dictionary or int(envelope.get("version", -1)) not in [1, 2, VERSION] or not envelope.get("payload") is PackedByteArray:
		error = "Unsupported or damaged save"
		return {}
	if payload_digest(envelope.payload) != envelope.get("sha256", ""):
		error = "Save checksum mismatch"
		return {}
	var payload: Variant = bytes_to_var(envelope.payload)
	if not payload is Dictionary or not payload.get("objects") is Array or payload.objects.size() > max_objects:
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
		var decoded: Variant = _decode(payload.objects[index].fields)
		if not decoded is Dictionary or not error.is_empty():
			return {}
		value.restore_run_value(decoded)
	var result: Variant = _decode(payload.get("root"))
	if not result is Dictionary or not error.is_empty() or not valid_snapshot(result):
		error = "Incomplete save"
		return {}
	return result

static func payload_digest(bytes: PackedByteArray) -> String:
	var hashing := HashingContext.new()
	hashing.start(HashingContext.HASH_SHA256)
	hashing.update(bytes)
	return hashing.finish().hex_encode()

func _encode(value: Variant, field_path: String = "") -> Variant:
	if field_path in VALUE_ARCHIVES:
		return {"plain": value}
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
			_records[_ids[instance]].fields = _encode(value.run_value_snapshot())
		return {"ref": _ids[instance]}
	if value is Array:
		var items := []
		for item: Variant in value:
			items.append(_encode(item))
		return {"array": items}
	if value is Dictionary:
		var pairs := []
		for key: Variant in value:
			pairs.append([_encode(key), _encode(value[key], str(key) if field_path.is_empty() else field_path + "/" + str(key))])
		return {"dict": pairs}
	return value

func _decode(value: Variant) -> Variant:
	if not value is Dictionary:
		return value
	if value.has("plain"):
		return value.plain
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
