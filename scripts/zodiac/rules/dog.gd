extends "res://scripts/zodiac/zodiac_mechanic.gd"

func configure(rule) -> void:
	rule.data["loyal_meld_id"] = -1

func begin_phase(rule, _deal) -> void:
	rule.data.loyal_meld_id = -1

func legality(rule, action: String, _phase: int, _meld_id: int, _cards: Array[CardData]) -> String:
	if rule.difficulty == ZodiacCatalog.UNPLEASED and action == "new_meld" and int(rule.data.loyal_meld_id) >= 0:
		return ZodiacCatalog.words("MỘT LÒNG MỘT DẠ: your LOYAL Meld is established. Extend it or cycle cards.", "MỘT LÒNG MỘT DẠ: đã có Phỏm TRUNG THÀNH. Hãy nối Phỏm hoặc bỏ bài để bốc tiếp.")
	return ""

func payout(rule, context: ScoringContext, meld_id: int, commit: bool) -> Dictionary:
	if context.action_type not in ["new_meld", "extension"]: return {}
	var loyal := int(rule.data.loyal_meld_id)
	if loyal < 0 and context.action_type == "new_meld":
		loyal = meld_id
		if commit: rule.data.loyal_meld_id = meld_id
	return {} if meld_id == loyal else {"percent": int(ZodiacCatalog.tuning("dog", "other_payout_percent", rule.difficulty)), "reason": "dog_non_loyal"}

func dragon_begin(_rule, _deal, state: Dictionary) -> void:
	state["loyal_meld_id"] = -1

func dragon_payout(rule, context: ScoringContext, meld_id: int, state: Dictionary, commit: bool) -> Dictionary:
	var loyal := int(state.loyal_meld_id)
	# The first scoring action picks this turn's loyal Meld, including Extensions.
	if loyal < 0:
		loyal = meld_id
		if commit: state.loyal_meld_id = meld_id
	return {} if meld_id == loyal else {"percent": int(ZodiacCatalog.tuning("dog", "other_payout_percent", rule.difficulty)), "reason": "dragon_dog_non_loyal"}
