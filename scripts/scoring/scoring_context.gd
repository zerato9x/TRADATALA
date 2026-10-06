class_name ScoringContext
extends RefCounted

var action_type: String = ""
var suppression_reason: String = ""
var meld_type: String = ""
var cards: Array[CardData] = []
var added_cards: Array[CardData] = []
var old_meld_score: int = 0
var card_value_sum: int = 0
var base_score: int = 0
var local_mult: int = 1
var flat_adjustment_points: int = 0
var retrigger_count: int = 0
var trigger_origin: String = "originating"
var trigger_reason: String = ""
var trigger_index: int = 0
var scoring_passes: Array = []
# Immutable value snapshots for presentation; never used to apply wallet changes.
var presentation_hits: Array[Dictionary] = []
# Separate action receipts, excluded from intrinsic values and scoring passes.
var relic_bonuses: Array[Dictionary] = []
var boss_transactions: Array[Dictionary] = []
var retrigger_source_id: String = ""
var retrigger_property: String = ""
var base_extension_score: int = 0
var theoretical_score: int = 0
var final_points: int = 0
var phase: int = 1
var is_last_call: bool = false


func value_equation() -> String:
	var values: Array[String] = []
	for card in cards:
		values.append("%d×%d" % [card.intrinsic_value(), card.fortune] if card.fortune > 1 else str(card.intrinsic_value()))
	return " + ".join(values)

# Object-table fields in run envelopes V1-V3, including shared CardData references.
const RUN_SAVE_FIELDS_V3 := ["action_type", "suppression_reason", "meld_type", "cards", "added_cards", "old_meld_score", "card_value_sum", "base_score", "local_mult", "flat_adjustment_points", "retrigger_count", "trigger_origin", "trigger_reason", "trigger_index", "scoring_passes", "presentation_hits", "relic_bonuses", "boss_transactions", "retrigger_source_id", "retrigger_property", "base_extension_score", "theoretical_score", "final_points", "phase", "is_last_call"]
const RUN_SNAPSHOT_FIELDS := preload("res://scripts/campaign/run_snapshot_fields.gd")

func run_value_snapshot() -> Dictionary:
	return RUN_SNAPSHOT_FIELDS.fields(self, RUN_SAVE_FIELDS_V3)

func restore_run_value(data: Dictionary) -> void:
	RUN_SNAPSHOT_FIELDS.apply_fields(self, data, RUN_SAVE_FIELDS_V3)
