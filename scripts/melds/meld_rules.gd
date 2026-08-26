class_name MeldRules
extends RefCounted

const TYPE_INVALID := "invalid"
const TYPE_SET := "set"
const TYPE_RUN := "run"


static func classify(cards: Array[CardData]) -> String:
	if cards.size() < 3:
		return TYPE_INVALID
	if is_set(cards):
		return TYPE_SET
	if is_run(cards):
		return TYPE_RUN
	return TYPE_INVALID


static func is_set(cards: Array[CardData]) -> bool:
	if cards.size() < 3:
		return false
	var expected_rank := cards[0].rank
	for card in cards:
		if card.rank != expected_rank:
			return false
	return true


static func is_run(cards: Array[CardData]) -> bool:
	if cards.size() < 3:
		return false
	var expected_suit := cards[0].suit
	var ranks: Array[int] = []
	for card in cards:
		if card.suit != expected_suit or card.rank_index < 1 or card.rank_index > 13:
			return false
		if ranks.has(card.rank_index):
			return false
		ranks.append(card.rank_index)
	ranks.sort()
	for index in range(1, ranks.size()):
		if ranks[index] != ranks[index - 1] + 1:
			return false
	return true


static func can_extend(meld_cards: Array[CardData], additions: Array[CardData], meld_type: String) -> bool:
	if additions.is_empty():
		return false
	var combined: Array[CardData] = []
	combined.append_array(meld_cards)
	combined.append_array(additions)
	return classify(combined) == meld_type


static func sorted_for_display(cards: Array[CardData], meld_type: String) -> Array[CardData]:
	var sorted_cards: Array[CardData] = []
	sorted_cards.append_array(cards)
	if meld_type == TYPE_RUN:
		sorted_cards.sort_custom(func(left: CardData, right: CardData) -> bool: return left.rank_index < right.rank_index)
	else:
		sorted_cards.sort_custom(func(left: CardData, right: CardData) -> bool: return left.suit < right.suit)
	return sorted_cards

