class_name PhaseSettlement
extends RefCounted

const UNSET_VND := -9223372036854775807

var phase: int = 1
var raw_gross: int = 0
var gross_after_u: int = 0
var deadwood_value_sum: int = 0
var deadwood_multiplier: int = 1
var deadwood: int = 0
var turn_deadwood: int = 0
var deadwood_penalty: int = 0
var black_ink_profit: int = 0
var net: int = 0
var net_vnd: int = UNSET_VND
var relic_rate_vnd: int = 0
var new_phom_count: int = 0
var extension_count: int = 0
var mom: bool = false
var u: bool = false
var u_bonus_paid_early: bool = false
var u_khan_count: int = 0
var remaining_hand: Array[CardData] = []


func to_dictionary() -> Dictionary:
	return {
		"phase": phase,
		"raw_gross": raw_gross,
		"gross_after_u": gross_after_u,
		"deadwood_value_sum": deadwood_value_sum,
		"deadwood_multiplier": deadwood_multiplier,
		"deadwood": deadwood,
		"deadwood_points": deadwood,
		"turn_deadwood": turn_deadwood,
		"deadwood_penalty": deadwood_penalty,
		"black_ink_profit": black_ink_profit,
		"net": net,
		"net_vnd": net_vnd,
		"relic_rate_vnd": relic_rate_vnd,
		"new_phom_count": new_phom_count,
		"extension_count": extension_count,
		"mom": mom,
		"u": u,
		"u_bonus_paid_early": u_bonus_paid_early,
		"u_khan_count": u_khan_count,
		"remaining_hand": remaining_hand.duplicate(),
	}

# Object-table fields in run envelopes V1-V3, including shared CardData references.
const RUN_SAVE_FIELDS_V3 := ["phase", "raw_gross", "gross_after_u", "deadwood_value_sum", "deadwood_multiplier", "deadwood", "turn_deadwood", "deadwood_penalty", "black_ink_profit", "net", "net_vnd", "relic_rate_vnd", "new_phom_count", "extension_count", "mom", "u", "u_bonus_paid_early", "u_khan_count", "remaining_hand"]
const RUN_SNAPSHOT_FIELDS := preload("res://scripts/campaign/run_snapshot_fields.gd")

func run_value_snapshot() -> Dictionary:
	return RUN_SNAPSHOT_FIELDS.fields(self, RUN_SAVE_FIELDS_V3)

func restore_run_value(data: Dictionary) -> void:
	RUN_SNAPSHOT_FIELDS.apply_fields(self, data, RUN_SAVE_FIELDS_V3)
