class_name MeldProbabilityAdvisor
extends RefCounted

const KIND_SET := "set"
const KIND_RUN := "run"
const KIND_EXTENSION := "extension"


static func analyze(
	hand: Array[CardData],
	draw_pile: Array[CardData],
	melds: Array[MeldState],
	draw_count: int
) -> Dictionary:
	var effective_draw_count := clampi(draw_count, 0, draw_pile.size())
	var candidates: Array[Dictionary] = []
	candidates.append_array(_set_candidates(hand, draw_pile, effective_draw_count))
	candidates.append_array(_run_candidates(hand, draw_pile, effective_draw_count))
	candidates.append_array(_extension_candidates(hand, melds, draw_pile, effective_draw_count))
	candidates.sort_custom(_candidate_before)
	return {
		"draw_pile_size": draw_pile.size(),
		"draw_count": effective_draw_count,
		"candidates": candidates,
	}


static func best_new_meld_chance_by_card(
	hand: Array[CardData],
	draw_pile: Array[CardData],
	draw_count: int
) -> Dictionary:
	var result := {}
	var analysis := analyze(hand, draw_pile, [] as Array[MeldState], draw_count)
	for candidate_value in analysis["candidates"]:
		var candidate: Dictionary = candidate_value
		if candidate["kind"] == KIND_EXTENSION:
			continue
		for card: CardData in candidate["owned_cards"]:
			var previous: Dictionary = result.get(card.unique_id, {})
			if previous.is_empty() or _candidate_before(candidate, previous):
				result[card.unique_id] = candidate
	return result


static func _set_candidates(
	hand: Array[CardData],
	draw_pile: Array[CardData],
	draw_count: int
) -> Array[Dictionary]:
	var candidates: Array[Dictionary] = []
	for rank in DeckManager.RANKS:
		var owned: Array[CardData] = []
		for card in hand:
			if card.rank == rank:
				owned.append(card)
		if owned.is_empty():
			continue
		var needed_count := maxi(0, 3 - owned.size())
		var available: Array[CardData] = []
		for card in draw_pile:
			if card.rank == rank:
				available.append(card)
		var probability := 1.0 if needed_count == 0 else _probability_at_least(
			draw_pile.size(), available.size(), draw_count, needed_count
		)
		var needed_labels: Array[String] = []
		if needed_count > 0:
			needed_labels.append("%d × %s" % [needed_count, rank])
		candidates.append(_candidate(
			KIND_SET,
			"BỘ %s" % rank,
			owned,
			needed_labels,
			available.size() if needed_count == 1 else 0,
			needed_count,
			probability,
			"PROBABILITY_SET",
			[rank]
		))
	return candidates


static func _run_candidates(
	hand: Array[CardData],
	draw_pile: Array[CardData],
	draw_count: int
) -> Array[Dictionary]:
	var candidates: Array[Dictionary] = []
	for suit in DeckManager.SUITS:
		for start_rank in range(1, 12):
			var target_ranks := [start_rank, start_rank + 1, start_rank + 2]
			var owned: Array[CardData] = []
			var missing_group_counts: Array[int] = []
			var missing_labels: Array[String] = []
			for rank_index in target_ranks:
				var owned_card := _first_card(hand, suit, rank_index)
				if owned_card != null:
					owned.append(owned_card)
				else:
					missing_group_counts.append(_count_cards(draw_pile, suit, rank_index))
					missing_labels.append(_card_label(suit, rank_index))
			if owned.is_empty():
				continue
			var probability := 1.0 if missing_labels.is_empty() else _probability_all_groups(
				draw_pile.size(), missing_group_counts, draw_count
			)
			var outs := missing_group_counts[0] if missing_group_counts.size() == 1 else 0
			candidates.append(_candidate(
				KIND_RUN,
				"SẢNH %s–%s%s" % [
					DeckManager.RANKS[start_rank - 1],
					DeckManager.RANKS[start_rank + 1],
					_suit_symbol(suit),
				],
				owned,
				missing_labels,
				outs,
				missing_labels.size(),
				probability,
				"PROBABILITY_RUN",
				[
					DeckManager.RANKS[start_rank - 1],
					DeckManager.RANKS[start_rank + 1],
					_suit_symbol(suit),
				]
			))
	return candidates


static func _extension_candidates(
	hand: Array[CardData],
	melds: Array[MeldState],
	draw_pile: Array[CardData],
	draw_count: int
) -> Array[Dictionary]:
	var candidates: Array[Dictionary] = []
	for meld in melds:
		if meld.cards.is_empty():
			continue
		if meld.meld_type == MeldRules.TYPE_SET:
			var rank := meld.cards[0].rank
			var owned: Array[CardData] = []
			for card in hand:
				if card.rank == rank:
					owned.append(card)
			var outs := 0
			for card in draw_pile:
				if card.rank == rank:
					outs += 1
			if owned.is_empty():
				candidates.append(_extension_candidate(
					meld, "GHÉP #%02d  BỘ %s" % [meld.meld_id, rank], owned,
					[rank], outs, 1, _probability_at_least(draw_pile.size(), outs, draw_count, 1),
					"PROBABILITY_EXTEND_SET", [meld.meld_id, rank]
				))
			else:
				candidates.append(_extension_candidate(
					meld, "GHÉP #%02d  BỘ %s" % [meld.meld_id, rank], owned,
					[] as Array[String], 0, 0, 1.0,
					"PROBABILITY_EXTEND_SET", [meld.meld_id, rank]
				))
		elif meld.meld_type == MeldRules.TYPE_RUN:
			var sorted := MeldRules.sorted_for_display(meld.cards, MeldRules.TYPE_RUN)
			var suit := sorted[0].suit
			var edge_ranks: Array[int] = []
			if sorted[0].rank_index > 1:
				edge_ranks.append(sorted[0].rank_index - 1)
			if sorted[-1].rank_index < 13:
				edge_ranks.append(sorted[-1].rank_index + 1)
			for edge_rank in edge_ranks:
				var outs := _count_cards(draw_pile, suit, edge_rank)
				var label := _card_label(suit, edge_rank)
				var owned_card := _first_card(hand, suit, edge_rank)
				var owned: Array[CardData] = []
				if owned_card != null:
					owned.append(owned_card)
				candidates.append(_extension_candidate(
					meld, "GHÉP #%02d  %s" % [meld.meld_id, label], owned,
					([label] as Array[String]) if owned.is_empty() else ([] as Array[String]),
					outs if owned.is_empty() else 0,
					1 if owned.is_empty() else 0,
					_probability_at_least(draw_pile.size(), outs, draw_count, 1) if owned.is_empty() else 1.0,
					"PROBABILITY_EXTEND_CARD", [meld.meld_id, label]
				))
	return candidates


static func _candidate(
	kind: String,
	label: String,
	owned_cards: Array[CardData],
	needed_labels: Array[String],
	outs: int,
	missing_count: int,
	probability: float,
	label_key: String = "",
	label_args: Array = []
) -> Dictionary:
	return {
		"kind": kind,
		"label": label,
		"label_key": label_key,
		"label_args": label_args,
		"owned_cards": owned_cards,
		"needed_labels": needed_labels,
		"outs": outs,
		"missing_count": missing_count,
		"probability": clampf(probability, 0.0, 1.0),
		"ready": missing_count == 0,
		"meld_id": -1,
	}


static func _extension_candidate(
	meld: MeldState,
	label: String,
	owned_cards: Array[CardData],
	needed_labels: Array[String],
	outs: int,
	missing_count: int,
	probability: float,
	label_key: String = "",
	label_args: Array = []
) -> Dictionary:
	var candidate := _candidate(
		KIND_EXTENSION, label, owned_cards, needed_labels, outs, missing_count, probability, label_key, label_args
	)
	candidate["meld_id"] = meld.meld_id
	return candidate


static func _candidate_before(left: Dictionary, right: Dictionary) -> bool:
	if left["ready"] != right["ready"]:
		return left["ready"]
	if not is_equal_approx(left["probability"], right["probability"]):
		return left["probability"] > right["probability"]
	if left["missing_count"] != right["missing_count"]:
		return left["missing_count"] < right["missing_count"]
	return String(left["label"]) < String(right["label"])


static func _probability_at_least(population: int, successes: int, draws: int, needed: int) -> float:
	if needed <= 0:
		return 1.0
	if population <= 0 or successes < needed or draws < needed:
		return 0.0
	draws = mini(draws, population)
	var denominator := _combination(population, draws)
	if denominator <= 0.0:
		return 0.0
	var total := 0.0
	for hits in range(needed, mini(successes, draws) + 1):
		var misses := draws - hits
		if misses > population - successes:
			continue
		total += _combination(successes, hits) * _combination(population - successes, misses)
	return clampf(total / denominator, 0.0, 1.0)


static func _probability_all_groups(population: int, group_counts: Array[int], draws: int) -> float:
	if group_counts.is_empty():
		return 1.0
	if population <= 0 or draws < group_counts.size():
		return 0.0
	for count in group_counts:
		if count <= 0:
			return 0.0
	draws = mini(draws, population)
	var denominator := _combination(population, draws)
	if denominator <= 0.0:
		return 0.0
	var probability := 0.0
	for mask in range(1 << group_counts.size()):
		var excluded := 0
		var bit_count := 0
		for index in range(group_counts.size()):
			if mask & (1 << index):
				excluded += group_counts[index]
				bit_count += 1
		var term := _combination(population - excluded, draws) / denominator
		probability += -term if bit_count % 2 == 1 else term
	return clampf(probability, 0.0, 1.0)


static func _combination(n: int, k: int) -> float:
	if n < 0 or k < 0 or k > n:
		return 0.0
	k = mini(k, n - k)
	var result := 1.0
	for index in range(1, k + 1):
		result *= float(n - k + index) / float(index)
	return result


static func _first_card(cards: Array[CardData], suit: String, rank_index: int) -> CardData:
	for card in cards:
		if card.suit == suit and card.rank_index == rank_index:
			return card
	return null


static func _count_cards(cards: Array[CardData], suit: String, rank_index: int) -> int:
	var count := 0
	for card in cards:
		if card.suit == suit and card.rank_index == rank_index:
			count += 1
	return count


static func _card_label(suit: String, rank_index: int) -> String:
	return "%s%s" % [DeckManager.RANKS[rank_index - 1], _suit_symbol(suit)]


static func localized_label(candidate: Dictionary) -> String:
	var label_key := String(candidate.get("label_key", ""))
	if label_key.is_empty():
		return String(candidate.get("label", ""))
	return String(TranslationServer.translate(label_key)) % candidate.get("label_args", [])


static func _suit_symbol(suit: String) -> String:
	return {"Spades": "♠", "Hearts": "♥", "Diamonds": "♦", "Clubs": "♣"}.get(suit, "?")
