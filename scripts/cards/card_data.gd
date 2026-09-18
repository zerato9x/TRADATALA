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
var gieo_properties: Array[String] = []
# Separate day-scoped polish; excluded from permanent snapshots.
var shiny: bool = false


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


func apply_rank(p_rank: String, p_rank_index: int) -> void:
	rank = p_rank
	rank_index = p_rank_index
	base_value = p_rank_index


func apply_suit(p_suit: String) -> void:
	suit = p_suit


func add_gieo_property(property_id: String) -> bool:
	if property_id.is_empty() or gieo_properties.has(property_id):
		return false
	gieo_properties.append(property_id)
	return true


func has_gieo_property(property_id: String) -> bool:
	return gieo_properties.has(property_id)


func permanent_snapshot() -> Dictionary:
	return {
		"unique_id": unique_id,
		"rank": rank,
		"rank_index": rank_index,
		"suit": suit,
		"gieo_properties": gieo_properties.duplicate(),
	}


func copy_for_deal() -> CardData:
	var deal_copy := CardData.new(unique_id, rank, rank_index, suit, base_value)
	deal_copy.gieo_properties.append_array(gieo_properties)
	deal_copy.shiny = shiny
	return deal_copy


func gieo_property_descriptions() -> Array[String]:
	var descriptions: Array[String] = []
	for property_id in gieo_properties:
		var key := gieo_property_label_key(property_id)
		if not key.is_empty():
			descriptions.append(TranslationServer.translate(key + "_DESC"))
	return descriptions


func texture_path() -> String:
	var rank_file: String = RANK_FILE_NAMES.get(rank, rank.to_lower())
	return "res://cards/%s_of_%s.png" % [rank_file, suit.to_lower()]


func short_label() -> String:
	const SUIT_SYMBOLS := {
		"Spades": "S",
		"Hearts": "H",
		"Diamonds": "D",
		"Clubs": "C",
	}
	return "%s%s" % [rank, SUIT_SYMBOLS.get(suit, "?")]


static func gieo_property_label_key(property_id: String) -> String:
	match property_id:
		"GOLD_MAKING_PHOM": return "GIEO_PROPERTY_MAKING"
		"GOLD_EXTEND": return "GIEO_PROPERTY_EXTEND"
		"GOLD_SET": return "GIEO_PROPERTY_SET"
		"GOLD_RUN": return "GIEO_PROPERTY_RUN"
		"GOLD_BIG_PHOM": return "GIEO_PROPERTY_BIG"
		"GOLD_LAST_CALL": return "GIEO_PROPERTY_LAST_CALL"
		"MELD_RETRIGGER": return "GIEO_PROPERTY_LIQUID"
		"SHINY": return "CARD_SHINY"
	return ""
