class_name PhaseSettlement
extends RefCounted

var phase: int = 1
var raw_gross: int = 0
var gross_after_u: int = 0
var deadwood: int = 0
var net: int = 0
var new_phom_count: int = 0
var extension_count: int = 0
var mom: bool = false
var u: bool = false
var u_khan_count: int = 0
var remaining_hand: Array[CardData] = []


func to_dictionary() -> Dictionary:
	return {
		"phase": phase,
		"raw_gross": raw_gross,
		"gross_after_u": gross_after_u,
		"deadwood": deadwood,
		"deadwood_points": deadwood,
		"net": net,
		"new_phom_count": new_phom_count,
		"extension_count": extension_count,
		"mom": mom,
		"u": u,
		"u_khan_count": u_khan_count,
		"remaining_hand": remaining_hand.duplicate(),
	}
