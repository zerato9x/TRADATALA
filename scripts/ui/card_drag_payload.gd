class_name CardDragPayload
extends RefCounted

const SOURCE_HAND := &"hand"
const SOURCE_TABLE_MELD := &"table_meld"

var source_zone: StringName = SOURCE_HAND
var source_meld_id: int = -1
var anchor_card_id: String = ""
var cards: Array[CardData] = []


func _init(
	value_source_zone: StringName = SOURCE_HAND,
	value_source_meld_id: int = -1,
	value_anchor_card_id: String = "",
	value_cards: Array[CardData] = []
) -> void:
	source_zone = value_source_zone
	source_meld_id = value_source_meld_id
	anchor_card_id = value_anchor_card_id
	cards.append_array(value_cards)


func anchor_card() -> CardData:
	for card in cards:
		if card.unique_id == anchor_card_id:
			return card
	return null
