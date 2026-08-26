class_name CardData
extends RefCounted

const RANK_FILE_NAMES := {
	"A": "ace",
	"2": "two",
	"3": "three",
	"4": "four",
	"5": "five",
	"6": "six",
	"7": "seven",
	"8": "eight",
	"9": "nine",
	"10": "ten",
	"J": "jack",
	"Q": "queen",
	"K": "king",
}

var unique_id: String
var rank: String
var rank_index: int
var suit: String
var base_value: int
var value_modifiers: Array[int] = []
var enhancements: Array[String] = []


func _init(
	p_unique_id: String = "",
	p_rank: String = "",
	p_rank_index: int = 0,
	p_suit: String = "",
	p_base_value: int = 0
) -> void:
	unique_id = p_unique_id
	rank = p_rank
	rank_index = p_rank_index
	suit = p_suit
	base_value = p_base_value


func score_value() -> int:
	var total := base_value
	for modifier in value_modifiers:
		total += modifier
	return total


func texture_path() -> String:
	var rank_file: String = RANK_FILE_NAMES.get(rank, rank.to_lower())
	return "res://cards/%s_of_%s.png" % [rank_file, suit.to_lower()]


func short_label() -> String:
	const SUIT_SYMBOLS := {
		"Spades": "♠",
		"Hearts": "♥",
		"Diamonds": "♦",
		"Clubs": "♣",
	}
	return "%s%s" % [rank, SUIT_SYMBOLS.get(suit, "?")]

