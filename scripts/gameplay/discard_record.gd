class_name DiscardRecord
extends RefCounted

const KIND_MANDATORY := "mandatory"
const KIND_DRINK_EXTRA := "drink_extra"
const KIND_DUMP := "dump"

var card: CardData
var phase: int
var discard_number: int
var kind: String = KIND_MANDATORY


func _init(p_card: CardData = null, p_phase: int = 1, p_discard_number: int = 0, p_kind: String = KIND_MANDATORY) -> void:
	card = p_card
	phase = p_phase
	discard_number = p_discard_number
	kind = p_kind


func short_label() -> String:
	return "%s #%d" % [card.short_label() if card != null else "?", discard_number]

const KIND_BOSS_FORCED := "boss_forced"

# Object-table fields in run envelopes V1-V3, including shared CardData references.
const RUN_SAVE_FIELDS_V3 := ["card", "phase", "discard_number", "kind"]
const RUN_SNAPSHOT_FIELDS := preload("res://scripts/campaign/run_snapshot_fields.gd")

func run_value_snapshot() -> Dictionary:
	return RUN_SNAPSHOT_FIELDS.fields(self, RUN_SAVE_FIELDS_V3)

func restore_run_value(data: Dictionary) -> void:
	RUN_SNAPSHOT_FIELDS.apply_fields(self, data, RUN_SAVE_FIELDS_V3)

func target_key() -> String:
	return "%d:%d:%s" % [phase, discard_number, card.unique_id]
