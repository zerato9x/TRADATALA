extends "res://scripts/zodiac/zodiac_mechanic.gd"

func configure(rule) -> void:
	rule.data["burden_age"] = {}

func _prune(state: Dictionary, hand: Array[CardData]) -> void:
	var ids := {}
	for card in hand: ids[card.unique_id] = true
	for id in state.burden_age.keys():
		if not ids.has(id): state.burden_age.erase(id)

func after_action(rule, deal, _result: Dictionary) -> void:
	_prune(rule.data, deal.hand)

func after_discard(rule, deal, _record: DiscardRecord) -> void:
	_prune(rule.data, deal.hand)

func begin_phase(rule, deal) -> void:
	_prune(rule.data, deal.hand)

func deadwood(rule, deal, context: Dictionary) -> void:
	_prune(rule.data, deal.hand)
	var near := MeldRules.near_meld_ids(deal.hand)
	var total := 0
	var per_card := {}
	for card: CardData in context.cards:
		if card.fortune < 0: continue
		var age := int(rule.data.burden_age.get(card.unique_id, 0)) + 1
		rule.data.burden_age[card.unique_id] = age
		var points := burden_points(card.intrinsic_value(), age, near.has(card.unique_id), rule.difficulty)
		per_card[card.unique_id] = points
		total += points
	context.value_sum = total
	context.deadwood = total * int(context.multiplier)
	context["ox_burden"] = per_card

# One catalog-owned formula: (value + near-meld add) * 2^(age-grace) * near-meld mult.
func burden_points(value: int, age: int, near: bool, difficulty: int) -> int:
	var grace := int(ZodiacCatalog.tuning("ox", "grace_turns", difficulty))
	var growth := 1 << clampi(age - grace, 0, 30)
	if near and difficulty == ZodiacCatalog.UNPLEASED:
		return (value + int(ZodiacCatalog.tuning("ox", "near_add_points", difficulty))) * growth * int(ZodiacCatalog.tuning("ox", "near_multiplier", difficulty))
	return value * growth

func dragon_begin(rule, _deal, state: Dictionary) -> void:
	state["burden_multiplier"] = int(ZodiacCatalog.tuning("ox", "dragon_multiplier", rule.difficulty))

func dragon_deadwood(_rule, _deal, context: Dictionary, state: Dictionary) -> void:
	context.deadwood *= int(state.burden_multiplier)
	context["dragon_ox_multiplier"] = state.burden_multiplier
