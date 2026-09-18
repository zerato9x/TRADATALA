class_name ScoringContext
extends RefCounted

var action_type: String = ""
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
var retrigger_source_id: String = ""
var retrigger_property: String = ""
var base_extension_score: int = 0
var theoretical_score: int = 0
var final_points: int = 0
var phase: int = 1
var is_last_call: bool = false


func qualifying_gold(card: CardData) -> Array[String]:
	var result: Array[String] = []
	var newly_committed := action_type == "new_meld" or (action_type == "extension" and added_cards.has(card))
	for property_id: String in GieoQueService.GOLD_PROPERTIES:
		if not card.has_gieo_property(property_id):
			continue
		var qualifies := false
		match property_id:
			GieoQueService.PROPERTY_GOLD_MAKING_PHOM:
				qualifies = action_type == "new_meld"
			GieoQueService.PROPERTY_GOLD_EXTEND:
				qualifies = action_type == "extension" and newly_committed
			GieoQueService.PROPERTY_GOLD_SET:
				qualifies = meld_type == MeldRules.TYPE_SET
			GieoQueService.PROPERTY_GOLD_RUN:
				qualifies = meld_type == MeldRules.TYPE_RUN
			GieoQueService.PROPERTY_GOLD_BIG_PHOM:
				qualifies = cards.size() >= 4
			GieoQueService.PROPERTY_GOLD_LAST_CALL:
				qualifies = is_last_call and newly_committed
		if qualifies:
			result.append(property_id)
	return result


func value_equation() -> String:
	var values: Array[String] = []
	for card in cards:
		values.append(str(card.score_value()))
		for _property in qualifying_gold(card):
			values.append(str(card.score_value()))
	return " + ".join(values)
