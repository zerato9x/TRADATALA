extends RefCounted
## Bounded, deterministic current-state heuristics; final legality uses MeldRules.
static func meld_candidates(cards: Array[CardData]) -> Array:
	var result: Array = []
	var ranks := {}
	var suits := {}
	for card in cards:
		if not ranks.has(card.rank): ranks[card.rank] = [] as Array[CardData]
		ranks[card.rank].append(card)
		if not suits.has(card.suit): suits[card.suit] = {}
		# Stable best-value representative for duplicate transformed run ranks.
		var previous: CardData = suits[card.suit].get(card.rank_index)
		if previous == null or card.score_value() > previous.score_value() or (card.score_value() == previous.score_value() and card.unique_id < previous.unique_id):
			suits[card.suit][card.rank_index] = card
	for rank in ranks:
		var set_cards: Array[CardData] = ranks[rank]
		if MeldRules.classify(set_cards) == MeldRules.TYPE_SET: result.append(set_cards)
	for suit in suits:
		for low in range(1, 12):
			var run: Array[CardData] = []
			for high in range(low, 14):
				if not suits[suit].has(high): break
				run.append(suits[suit][high])
				if MeldRules.classify(run) == MeldRules.TYPE_RUN: result.append(run.duplicate())
	return result

static func strategic_values(deal) -> Dictionary:
	var values := {}
	var near := MeldRules.near_meld_ids(deal.hand)
	for card: CardData in deal.hand:
		values[card.unique_id] = [(int(ZodiacCatalog.tuning("tiger", "near_weight")) if near.has(card.unique_id) else 0), 0, 0, card.rank_index * int(ZodiacCatalog.tuning("tiger", "rank_weight")), card.score_value()]
	for candidate: Array[CardData] in meld_candidates(deal.hand):
		var score: int = deal.scoring.preview_new_meld(candidate, MeldRules.classify(candidate), deal.current_phase).final_points
		for card in candidate: values[card.unique_id][1] = maxi(int(values[card.unique_id][1]), score * int(ZodiacCatalog.tuning("tiger", "meld_weight")))
	for card: CardData in deal.hand:
		var additions: Array[CardData] = [card]
		var best := 0
		for meld: MeldState in deal.melds:
			if meld.can_extend(additions):
				var combined: Array[CardData] = meld.cards.duplicate()
				combined.append(card)
				best = maxi(best, deal.scoring.preview_extension(combined, meld.meld_type, ScoringPipeline.meld_value(meld.cards), deal.current_phase, additions).final_points)
		values[card.unique_id][2] = best * int(ZodiacCatalog.tuning("tiger", "extension_weight"))
	return values

static func valuable_cards(deal) -> Array[CardData]:
	var values := strategic_values(deal)
	var result: Array[CardData] = deal.hand.duplicate()
	result.sort_custom(func(a: CardData, b: CardData):
		for index in values[a.unique_id].size():
			if values[a.unique_id][index] != values[b.unique_id][index]: return values[a.unique_id][index] > values[b.unique_id][index]
		return a.unique_id < b.unique_id)
	return result


# Enumerate actual contiguous endpoint additions, then ask MeldState/MeldRules
# for final legality. No opponent-specific substitute for the Meld rules.
static func extension_candidates(meld: MeldState, pool: Array[CardData]) -> Array:
	var result: Array = []
	if meld.meld_type == MeldRules.TYPE_SET:
		var additions: Array[CardData] = pool.filter(func(card: CardData): return card.rank == meld.cards[0].rank)
		if meld.can_extend(additions): result.append(additions)
		return result
	var sorted := MeldRules.sorted_for_display(meld.cards, meld.meld_type)
	var by_rank := {}
	for card in pool:
		var compatible: bool = card.suit == sorted[0].suit if meld.run_compatibility == "same" else card.suit in ["Hearts", "Diamonds"] if meld.run_compatibility == "red" else card.suit in ["Spades", "Clubs"]
		if not compatible: continue
		var previous: CardData = by_rank.get(card.rank_index)
		if previous == null or card.score_value() > previous.score_value() or (card.score_value() == previous.score_value() and card.unique_id < previous.unique_id): by_rank[card.rank_index] = card
	var left: Array[CardData] = []
	var right: Array[CardData] = []
	var rank: int = sorted[0].rank_index - 1
	while by_rank.has(rank): left.append(by_rank[rank]); rank -= 1
	rank = sorted[-1].rank_index + 1
	while by_rank.has(rank): right.append(by_rank[rank]); rank += 1
	for low in left.size() + 1:
		for high in right.size() + 1:
			var additions: Array[CardData] = left.slice(0, low)
			additions.append_array(right.slice(0, high))
			if meld.can_extend(additions): result.append(additions)
	return result
