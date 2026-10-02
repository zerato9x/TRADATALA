extends "res://scripts/zodiac/zodiac_mechanic.gd"

func legality(rule, action: String, phase: int, _meld_id: int, _cards: Array[CardData]) -> String:
	if rule.difficulty == ZodiacCatalog.UNPLEASED and phase == 2 and action == "new_meld":
		return ZodiacCatalog.words("CHỐT SỔ! Phase 2 permits Extensions only.", "CHỐT SỔ! Hiệp 2 chỉ được nối Phỏm.")
	return ""

func payout(rule, context: ScoringContext, _meld_id: int, _commit: bool) -> Dictionary:
	if context.phase == 1 and rule.register_closed and context.action_type in ["new_meld", "extension"]:
		return {"percent": 0, "reason": "rooster_register_closed"}
	return {}

func dragon_begin(_rule, _deal, state: Dictionary) -> void:
	state["actions"] = 0

func dragon_payout(rule, _context: ScoringContext, _meld_id: int, state: Dictionary, commit: bool) -> Dictionary:
	var closed := int(state.get("actions", 0)) >= int(ZodiacCatalog.tuning("rooster", "dragon_paid_actions", rule.difficulty))
	if commit: state.actions += 1
	return {"percent": 0, "reason": "dragon_rooster_register_closed"} if closed else {}
