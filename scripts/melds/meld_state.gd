class_name MeldState
extends RefCounted

var meld_id: int
var meld_type: String
var cards: Array[CardData] = []
var scored_points: int = 0


func _init(p_meld_id: int = 0, p_meld_type: String = MeldRules.TYPE_INVALID, p_cards: Array[CardData] = []) -> void:
	meld_id = p_meld_id
	meld_type = p_meld_type
	cards.append_array(p_cards)
	cards = MeldRules.sorted_for_display(cards, meld_type)


func can_extend(additions: Array[CardData]) -> bool:
	return MeldRules.can_extend(cards, additions, meld_type)


func extend(additions: Array[CardData]) -> void:
	cards.append_array(additions)
	cards = MeldRules.sorted_for_display(cards, meld_type)

