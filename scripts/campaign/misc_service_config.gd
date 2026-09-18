class_name MiscServiceConfig
extends RefCounted

# Provisional balance; tune here without changing service or UI authority.
const POLISH_COST_VND := 10_000
const TIP_VND := 5_000
const FAVORS := {"lottery_special": {"tips_required_vnd": 20_000}}
const TICKET_STAKE_VND := 10_000
const TICKETS_PER_APPEARANCE := 8
const PRIZES := [
	{"id": "special", "count": 1, "numerator": 80, "denominator": 1, "label": "LOTTO_SPECIAL", "multiplier": "×80"},
	{"id": "first", "count": 1, "numerator": 20, "denominator": 1, "label": "LOTTO_FIRST", "multiplier": "×20"},
	{"id": "second", "count": 2, "numerator": 5, "denominator": 1, "label": "LOTTO_SECOND", "multiplier": "×5"},
	{"id": "third", "count": 3, "numerator": 5, "denominator": 2, "label": "LOTTO_THIRD", "multiplier": "×2.5"},
]
