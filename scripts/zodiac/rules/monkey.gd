extends "res://scripts/zodiac/zodiac_mechanic.gd"
const ACTIONS := ["new_meld", "extension", "discard"]

func configure(rule) -> void:
	rule.data.merge({"sequence": [], "sequence_index": 0, "last_paid_action": "", "repeat_count": 0})
	if rule.difficulty == ZodiacCatalog.UNPLEASED: _sequence(rule)

func _sequence(rule) -> void:
	var pattern := ACTIONS.duplicate()
	for i in range(pattern.size() - 1, 0, -1):
		var j: int = rule.rng.randi_range(0, i)
		var temporary: String = pattern[i]
		pattern[i] = pattern[j]
		pattern[j] = temporary
	rule.data.sequence = pattern.slice(0, int(ZodiacCatalog.tuning("monkey", "sequence_length", rule.difficulty)))
	rule.data.sequence_index = 0

func begin_phase(rule, _deal) -> void:
	rule.data.last_paid_action = ""
	rule.data.repeat_count = 0
	if rule.difficulty == ZodiacCatalog.UNPLEASED: _sequence(rule)

func _required(state: Dictionary) -> String:
	return String(state.sequence[int(state.sequence_index) % state.sequence.size()]) if not state.get("sequence", []).is_empty() else ""

func payout(rule, context: ScoringContext, _meld_id: int, commit: bool) -> Dictionary:
	if context.action_type not in ["new_meld", "extension"]: return {}
	var correct := true
	if rule.difficulty == ZodiacCatalog.UNPLEASED:
		correct = context.action_type == _required(rule.data)
	else:
		correct = context.action_type != rule.data.last_paid_action or int(rule.data.repeat_count) < int(ZodiacCatalog.tuning("monkey", "allowed_repeats", rule.difficulty))
	if commit and correct and context.final_points > 0:
		if rule.difficulty == ZodiacCatalog.UNPLEASED:
			rule.data.sequence_index = (int(rule.data.sequence_index) + 1) % rule.data.sequence.size()
		else:
			rule.data.repeat_count = int(rule.data.repeat_count) + 1 if rule.data.last_paid_action == context.action_type else 1
			rule.data.last_paid_action = context.action_type
	return {} if correct else {"percent": 0, "reason": "monkey_rhythm_miss"}

func after_action(rule, _deal, result: Dictionary) -> void:
	if rule.difficulty == ZodiacCatalog.UNPLEASED and result.get("action", "") == "discard":
		if _required(rule.data) == "discard": rule.data.sequence_index = (int(rule.data.sequence_index) + 1) % rule.data.sequence.size()

func presentation(rule) -> Dictionary:
	return {"required_action": _required(rule.data), "action_taxonomy": ACTIONS.duplicate()}

func dragon_begin(rule, _deal, state: Dictionary) -> void:
	state["required_action"] = rule.data.analysis.action

func dragon_payout(_rule, context: ScoringContext, _meld_id: int, state: Dictionary, _commit: bool) -> Dictionary:
	return {} if context.action_type == state.required_action else {"percent": 0, "reason": "dragon_monkey_rhythm_miss"}
