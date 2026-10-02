extends "res://scripts/zodiac/zodiac_mechanic.gd"
const Tactics := preload("res://scripts/zodiac/zodiac_tactics.gd")

func configure(rule) -> void:
	rule.data["hostile_result"] = {}

func after_discard(rule, deal, record: DiscardRecord) -> void:
	_respond(rule, deal, record.card, false)

func after_action(rule, deal, result: Dictionary) -> void:
	if result.get("action", "") in ["nhan_tran_swap", "den_da_swap"]:
		_respond(rule, deal, result.discarded, false)

func _pool(rule, deal, current: CardData, current_only: bool) -> Array[CardData]:
	var result: Array[CardData] = []
	for record: DiscardRecord in deal.discard_history:
		var eligible: bool = record.phase == deal.current_phase or (not current_only and rule.difficulty == ZodiacCatalog.UNPLEASED and record.phase == deal.current_phase - 1) or record.card == current
		if eligible and deal.deck.discard_pile.has(record.card) and not result.has(record.card): result.append(record.card)
	return result

func _respond(rule, deal, current: CardData, current_only: bool) -> void:
	var discarded := _pool(rule, deal, current, current_only)
	if discarded.is_empty(): return
	var borrowed: Array[CardData] = deal.borrow_for_boss(int(ZodiacCatalog.tuning("rat", "borrow_limit", rule.difficulty)))
	var pool: Array[CardData] = discarded.duplicate()
	pool.append_array(borrowed)
	var best_cards: Array[CardData] = []
	var best_meld := -1
	var best_score := -1
	for candidate: Array[CardData] in Tactics.meld_candidates(pool):
		var context: ScoringContext = deal.scoring.preview_new_meld(candidate, MeldRules.classify(candidate), deal.current_phase)
		if context.final_points > best_score:
			best_score = context.final_points
			best_cards = candidate
			best_meld = -1
	for meld: MeldState in deal.melds:
		for additions: Array[CardData] in Tactics.extension_candidates(meld, pool):
			var combined: Array[CardData] = meld.cards.duplicate()
			combined.append_array(additions)
			var context: ScoringContext = deal.scoring.preview_extension(combined, meld.meld_type, ScoringPipeline.meld_value(meld.cards), deal.current_phase, additions)
			if context.final_points > best_score:
				best_score = context.final_points
				best_cards = additions
				best_meld = meld.meld_id

	var unused: Array[CardData] = []
	for card in borrowed:
		if not best_cards.has(card): unused.append(card)
	# Failed borrowing reshuffles with a caller seed; deck RNG remains untouched.
	deal.return_boss_borrow(unused, int(rule.rng.randi()))
	if best_cards.is_empty():
		rule.data.hostile_result = {"action": "mouse_borrow_returned", "borrowed_count": borrowed.size(), "returned_ids": unused.map(func(card: CardData): return card.unique_id)}
	else:
		rule.data.hostile_result = deal.boss_commit_meld(best_cards, best_meld, "rat")
	rule.events.append(rule.data.hostile_result.duplicate(true))

func dragon_discard(rule, deal, record: DiscardRecord, state: Dictionary) -> void:
	_respond(rule, deal, record.card, true)
	state["hostile_result"] = rule.data.get("hostile_result", {}).duplicate(true)
