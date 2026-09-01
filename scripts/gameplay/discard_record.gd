class_name DiscardRecord
extends RefCounted

const KIND_MANDATORY := "mandatory"

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
