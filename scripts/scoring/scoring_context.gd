class_name ScoringContext
extends RefCounted

var action_type: String = ""
var meld_type: String = ""
var cards: Array[CardData] = []
var old_meld_score: int = 0
var card_value_sum: int = 0
var base_score: int = 0
var local_mult: int = 1
var flat_adjustment_points: int = 0
var retrigger_count: int = 0
var theoretical_score: int = 0
var final_points: int = 0
var phase: int = 1


func value_equation() -> String:
	var values: Array[String] = []
	for card in cards:
		values.append(str(card.score_value()))
	return " + ".join(values)

