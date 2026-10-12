class_name ShoeShineConfig
extends RefCounted
## Quotes are locked to the Starter visit, never to the player's wallet.
const MAX_SELECTED_CARDS := 2
const FIRST_DAY_INDEX := 1 # Tuesday; Monday is onboarding.
const PRICE_VERSION := 2
const MAX_COST_VND := 4_000_000_000_000_000
const SERVICES := {
	"rank": {"base_vnd": 25_000, "target_percent": 10, "growth": 2},
	"suit": {"base_vnd": 15_000, "target_percent": 5, "growth": 2},
}

static func initial_cost(kind: String, target_vnd: int, curve: Dictionary = SERVICES) -> int:
	var rule: Dictionary = curve[kind]
	var scaled := int((clampi(target_vnd, 0, MAX_COST_VND) * int(rule.target_percent) + 49_999) / 50_000) * 500
	return mini(MAX_COST_VND, maxi(int(rule.base_vnd), scaled))

static func next_cost(current_vnd: int, kind: String, curve: Dictionary) -> int:
	var growth := maxi(2, int(curve[kind].growth))
	if current_vnd > MAX_COST_VND / growth: return MAX_COST_VND
	return mini(MAX_COST_VND, current_vnd * growth)
