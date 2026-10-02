extends "res://scripts/zodiac/zodiac_mechanic.gd"
const Tactics := preload("res://scripts/zodiac/zodiac_tactics.gd")

func configure(rule) -> void:
	rule.data["removed_ids"] = []

func _snatch(rule, deal, dragon_safe: bool) -> Array:
	var pool: Array[CardData] = deal.hand.filter(func(card: CardData): return not rule.is_locked(card))
	if pool.is_empty(): return []
	var target: CardData = pool[0]
	if rule.difficulty == ZodiacCatalog.UNPLEASED:
		for card in Tactics.valuable_cards(deal):
			if pool.has(card): target = card; break
	else:
		pool.sort_custom(func(a: CardData, b: CardData): return a.rank_index > b.rank_index if a.rank_index != b.rank_index else a.unique_id < b.unique_id)
		target = pool[0]
	var removed := []
	for card in pool:
		if card.rank != target.rank: continue
		if dragon_safe and deal.hand.size() <= 1: break
		if deal.boss_discard_card(card, "tiger").get("ok", false): removed.append(card.unique_id)
		if rule.difficulty == ZodiacCatalog.PLEASED: break
	return removed

func begin_turn(rule, _phase: int, _hand: Array[CardData], deal) -> void:
	if deal != null: rule.data.removed_ids = _snatch(rule, deal, false)

func payout(rule, context: ScoringContext, _meld_id: int, _commit: bool) -> Dictionary:
	if rule.difficulty == ZodiacCatalog.UNPLEASED and context.action_type == ScoringPipeline.ACTION_EXHAUSTION_MELD:
		return {"percent": 0, "reason": "tiger_exhaustion_bonus_disabled"}
	return {}

func dragon_begin(rule, deal, state: Dictionary) -> void:
	state["removed_ids"] = _snatch(rule, deal, true)

# Dragon-safe Tiger has only the immediate snatch, no persistent exhaustion rule.
