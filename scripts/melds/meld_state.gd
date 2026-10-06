class_name MeldState
extends RefCounted

signal exhaustion_triggered(context: Dictionary)

var meld_id: int
var meld_type: String
var cards: Array[CardData] = []
var scored_points: int = 0
var run_compatibility: String = "same"
var pair_created: bool = false


func _init(p_meld_id: int = 0, p_meld_type: String = MeldRules.TYPE_INVALID, p_cards: Array[CardData] = []) -> void:
	meld_id = p_meld_id
	meld_type = p_meld_type
	cards.append_array(p_cards)
	cards = MeldRules.sorted_for_display(cards, meld_type, run_compatibility)


func can_extend(additions: Array[CardData]) -> bool:
	if meld_type == MeldRules.TYPE_RUN and run_compatibility != "same":
		var combined: Array[CardData] = []
		combined.append_array(cards)
		combined.append_array(additions)
		return not additions.is_empty() and MeldRules.is_compatible_run(combined, run_compatibility)
	return MeldRules.can_extend(cards, additions, meld_type)


func extend(additions: Array[CardData]) -> void:
	cards.append_array(additions)
	cards = MeldRules.sorted_for_display(cards, meld_type, run_compatibility)


func resolve_exhaustion(exhaustion_index: int) -> Dictionary:
	var context := {
		"exhaustion_index": exhaustion_index,
		"meld_id": meld_id,
		"meld_type": meld_type,
		"cards": cards.duplicate(),
		"card_count": cards.size(),
		"scored_points": scored_points,
	}
	exhaustion_triggered.emit(context)
	return context

# Object-table fields in run envelopes V1-V3, including shared CardData references.
const RUN_SAVE_FIELDS_V3 := ["meld_id", "meld_type", "cards", "scored_points", "run_compatibility", "pair_created"]
const RUN_SNAPSHOT_FIELDS := preload("res://scripts/campaign/run_snapshot_fields.gd")

func run_value_snapshot() -> Dictionary:
	return RUN_SNAPSHOT_FIELDS.fields(self, RUN_SAVE_FIELDS_V3)

func restore_run_value(data: Dictionary) -> void:
	RUN_SNAPSHOT_FIELDS.apply_fields(self, data, RUN_SAVE_FIELDS_V3)
