extends "res://scripts/zodiac/zodiac_mechanic.gd"

func configure(rule) -> void:
	rule.data.merge({"required_action": "", "pair_count": 0, "pair_grace": 0, "last_turn_forced": false})

func begin_phase(rule, _deal) -> void:
	rule.data.pair_grace = int(ZodiacCatalog.tuning("horse", "incomplete_grace", rule.difficulty))
	_reset_turn(rule.data)

func _reset_turn(state: Dictionary) -> void:
	state.required_action = ""
	state.pair_count = 0
	state.last_turn_forced = false

func begin_turn(rule, _phase: int, _hand: Array[CardData], _deal) -> void:
	_reset_turn(rule.data)

func _action(rule, state: Dictionary, result: Dictionary) -> void:
	var action := String(result.get("action", ""))
	if action not in ["new_meld", "extension"]: return
	if String(state.required_action).is_empty(): state.required_action = action
	if state.required_action == action: state.pair_count = mini(int(state.pair_count) + 1, int(ZodiacCatalog.tuning("horse", "matching_actions", rule.difficulty)))

func after_action(rule, _deal, result: Dictionary) -> void:
	_action(rule, rule.data, result)

func _choose(rule, deal, requested: CardData, state: Dictionary) -> CardData:
	state.last_turn_forced = false
	if int(state.pair_count) >= int(ZodiacCatalog.tuning("horse", "matching_actions", rule.difficulty)): return requested
	if int(state.get("pair_grace", 0)) > 0:
		state.pair_grace -= 1
		rule.events.append({"action": "horse_grace", "remaining": state.pair_grace})
		return requested
	var pool: Array[CardData] = deal.hand.filter(func(card: CardData): return not rule.is_locked(card))
	if pool.is_empty(): return null
	var chosen: CardData = pool[rule.rng.randi_range(0, pool.size() - 1)]
	state.last_turn_forced = true
	rule.events.append({"action": "horse_forced_discard", "card_id": chosen.unique_id, "replaces_mandatory": true})
	return chosen

func turn_discard(rule, deal, requested: CardData) -> CardData:
	return _choose(rule, deal, requested, rule.data)

func phase_limit(rule, _phase: int, ordinary: int) -> int:
	return int(ZodiacCatalog.tuning("horse", "phase_turn_limit", rule.difficulty)) if rule.difficulty == ZodiacCatalog.UNPLEASED else ordinary

func dragon_begin(rule, _deal, state: Dictionary) -> void:
	state.merge({"required_action": "", "pair_count": 0, "last_turn_forced": false, "pair_grace": int(ZodiacCatalog.tuning("horse", "incomplete_grace", rule.difficulty))})

func dragon_after(rule, _deal, result: Dictionary, state: Dictionary) -> void:
	_action(rule, state, result)

func dragon_turn_discard(rule, deal, requested: CardData, state: Dictionary) -> CardData:
	return _choose(rule, deal, requested, state)
