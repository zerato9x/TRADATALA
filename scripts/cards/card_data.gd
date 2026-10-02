class_name CardData
extends RefCounted

signal permanent_changed(card_id: String, revision: int, operation: String)
var mutation_revision := 0

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
var transformation_locked: bool = false


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
	if transformation_locked: return
	var before := persuasion_fingerprint()
	rank = p_rank
	rank_index = p_rank_index
	base_value = p_rank_index
	_notify_permanent(before, "rank")


func apply_suit(p_suit: String) -> void:
	if transformation_locked: return
	var before := persuasion_fingerprint()
	suit = p_suit
	_notify_permanent(before, "suit")


func add_gieo_property(property_id: String) -> bool:
	if transformation_locked: return false
	if property_id.is_empty() or gieo_properties.has(property_id):
		return false
	var before := persuasion_fingerprint()
	gieo_properties.append(property_id)
	_notify_permanent(before, "property")
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
		"transformation_locked": transformation_locked,
	}


func copy_for_deal() -> CardData:
	var deal_copy := CardData.new(unique_id, rank, rank_index, suit, base_value)
	deal_copy.gieo_properties.append_array(gieo_properties)
	deal_copy.shiny = shiny
	deal_copy.transformation_locked = transformation_locked
	return deal_copy


func alter_for_zodiac(operation: String) -> void:
	var before := persuasion_fingerprint()
	match operation:
		"remove_property":
			if not gieo_properties.is_empty(): gieo_properties.pop_back()
		"seal": transformation_locked = true
		"reset":
			# Canonical identity is stable even after rank/suit transformations.
			var identity := unique_id.split("_")
			if identity.size() != 3 or identity[0] != "standard": return
			rank = identity[1].to_upper()
			rank_index = DeckManager.RANKS.find(rank) + 1
			base_value = rank_index
			suit = identity[2].capitalize()
			gieo_properties.clear()
			value_modifiers.clear()
			enhancements.clear()
			shiny = false
	_notify_permanent(before, operation)

func persuasion_fingerprint() -> Dictionary:
	var data := permanent_snapshot()
	data["base_value"] = base_value
	data["value_modifiers"] = value_modifiers.duplicate()
	data["enhancements"] = enhancements.duplicate()
	data["shiny"] = shiny
	return data

func _notify_permanent(before: Dictionary, operation: String) -> void:
	if before == persuasion_fingerprint(): return
	mutation_revision += 1
	permanent_changed.emit(unique_id, mutation_revision, operation)

func has_permanent_changes() -> bool:
	var identity := unique_id.split("_")
	if identity.size() != 3 or identity[0] != "standard": return false
	return rank != identity[1].to_upper() or suit.to_lower() != identity[2] or not gieo_properties.is_empty() or not value_modifiers.is_empty() or not enhancements.is_empty() or shiny


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
