class_name MeldRules
extends RefCounted
## Legality resolves represented identities. Printed rank/suit and payout stay physical.
const TYPE_INVALID := "invalid"
const TYPE_SET := "set"
const TYPE_RUN := "run"

static func classify(cards: Array[CardData]) -> String:
	if is_set(cards): return TYPE_SET
	if is_run(cards): return TYPE_RUN
	return TYPE_INVALID

static func physical_cards_valid(cards: Array[CardData], minimum: int) -> bool:
	if cards.size() < minimum: return false
	var ids := {}
	for card in cards:
		if card == null or card.unique_id.is_empty() or ids.has(card.unique_id): return false
		if card.rank_index < 1 or card.rank_index > 13 or card.suit not in DeckManager.SUITS: return false
		ids[card.unique_id] = true
	return true

static func set_identity(cards: Array[CardData], minimum: int = 3) -> int:
	if not physical_cards_valid(cards, minimum): return 0
	# Rank options are contiguous. Intersect their bounds without allocating
	# thirteen candidate lists for every selection in the hand advisor.
	var low := 1
	var high := 13
	for card in cards:
		if card.is_glitch(): continue
		low = maxi(low, maxi(card.rank_index - 1, 1) if card.negative else card.rank_index)
		high = mini(high, mini(card.rank_index + 1, 13) if card.negative else card.rank_index)
		if low > high: return 0
	# Prefer a stored rank when multiple representations are legal.
	for card in cards:
		if card.rank_index >= low and card.rank_index <= high: return card.rank_index
	return low

static func is_set(cards: Array[CardData]) -> bool:
	return set_identity(cards) != 0

static func is_run(cards: Array[CardData]) -> bool:
	return not run_identities(cards, "same").is_empty()

static func is_compatible_run(cards: Array[CardData], compatibility: String) -> bool:
	return not run_identities(cards, compatibility).is_empty()

# Polynomial bipartite matching: one distinct rank slot per physical card.
# A Negative/Glitch card cannot fill two slots, including when duplicates exist.
static func run_identities(cards: Array[CardData], compatibility: String = "same") -> Dictionary:
	if not physical_cards_valid(cards, 3) or cards.size() > 13 or compatibility not in ["same", "any", "red", "black"]: return {}
	var first_start := 1
	var last_start := 14 - cards.size()
	var fixed_ranks := {}
	var flexible := false
	for card in cards:
		flexible = flexible or card.negative
		if card.is_glitch(): continue
		var low := maxi(card.rank_index - 1, 1) if card.negative else card.rank_index
		var high := mini(card.rank_index + 1, 13) if card.negative else card.rank_index
		first_start = maxi(first_start, low - cards.size() + 1)
		last_start = mini(last_start, high)
		if not card.negative:
			if fixed_ranks.has(card.rank_index): return {}
			fixed_ranks[card.rank_index] = true
	if first_start > last_start: return {}
	# Ordinary runs have one possible identity per card, so no matching is needed.
	if not flexible:
		var identities := {}
		for card in cards:
			if not card.can_represent(card.rank_index, cards[0].suit if compatibility == "same" else compatibility): return {}
			identities[card.unique_id] = {"rank": card.rank_index, "suit": card.suit}
		return identities
	var families: Array[String] = []
	families.assign(DeckManager.SUITS if compatibility == "same" else [compatibility])
	for family in families:
		if not cards.all(func(card: CardData): return card.can_represent(card.rank_index, family)): continue
		for start in range(first_start, last_start + 1):
			var owners := {}
			var legal := true
			for index in cards.size():
				if not _assign_run_card(index, cards, start, family, owners, {}):
					legal = false
					break
			if legal:
				var identities := {}
				for value: int in owners:
					var card := cards[int(owners[value])]
					var represented_suit := family
					if family in ["any", "red", "black"]:
						for suit in card.meld_suit_options():
							if family == "any" or (family == "red" and suit in ["Hearts", "Diamonds"]) or (family == "black" and suit in ["Spades", "Clubs"]):
								represented_suit = suit
								break
					identities[card.unique_id] = {"rank": value, "suit": represented_suit}
				return identities
	return {}

static func _assign_run_card(index: int, cards: Array[CardData], start: int, family: String, owners: Dictionary, visited: Dictionary, slot_count: int = -1) -> bool:
	if slot_count < 0: slot_count = cards.size()
	# The actual rank gets first preference, but backtracking can move it when needed.
	var ranks := cards[index].meld_rank_options()
	if ranks.has(cards[index].rank_index):
		ranks.erase(cards[index].rank_index)
		ranks.push_front(cards[index].rank_index)
	for value in ranks:
		if value < start or value >= start + slot_count or visited.has(value) or not cards[index].can_represent(value, family): continue
		visited[value] = true
		if not owners.has(value) or _assign_run_card(int(owners[value]), cards, start, family, owners, visited, slot_count):
			owners[value] = index
			return true
	return false

# Find a run while preserving every already-selected physical card. Augmenting
# paths may move a selected card to another rank, but never replace its identity.
static func complete_run(cards: Array[CardData], required: Array[CardData], low: int, high: int, family: String = "any") -> Array[CardData]:
	var result: Array[CardData] = []
	var count := high - low + 1
	if low < 1 or high > 13 or count < 3 or count > cards.size() or required.size() > count or not physical_cards_valid(cards, 3): return result
	var owners := {}
	var selected := {}
	for card in required:
		var index := cards.find(card)
		if index < 0 or selected.has(card.unique_id): return result
		selected[card.unique_id] = true
		if not _assign_run_card(index, cards, low, family, owners, {}, count): return result
	for index in cards.size():
		if owners.size() == count: break
		if not selected.has(cards[index].unique_id): _assign_run_card(index, cards, low, family, owners, {}, count)
	if owners.size() != count: return result
	for rank in range(low, high + 1): result.append(cards[int(owners[rank])])
	return result

static func can_extend(meld_cards: Array[CardData], additions: Array[CardData], meld_type: String) -> bool:
	if additions.is_empty(): return false
	var combined: Array[CardData] = meld_cards.duplicate()
	combined.append_array(additions)
	return is_set(combined) if meld_type == TYPE_SET else is_run(combined) if meld_type == TYPE_RUN else false

static func sorted_for_display(cards: Array[CardData], meld_type: String, compatibility: String = "same") -> Array[CardData]:
	var sorted_cards: Array[CardData] = cards.duplicate()
	if meld_type == TYPE_RUN:
		var identities := run_identities(cards, compatibility)
		sorted_cards.sort_custom(func(left: CardData, right: CardData):
			var left_rank: int = identities.get(left.unique_id, {}).get("rank", left.rank_index)
			var right_rank: int = identities.get(right.unique_id, {}).get("rank", right.rank_index)
			return left_rank < right_rank if left_rank != right_rank else left.unique_id < right.unique_id)
	else:
		sorted_cards.sort_custom(func(left: CardData, right: CardData): return left.suit < right.suit if left.suit != right.suit else left.unique_id < right.unique_id)
	return sorted_cards

# Shared by U khan, advice and Zodiac burden. This observes legal identities too.
static func near_meld_ids(cards: Array[CardData]) -> Dictionary:
	var ids := {}
	for left_index in cards.size():
		for right_index in range(left_index + 1, cards.size()):
			var left := cards[left_index]
			var right := cards[right_index]
			var near := false
			for value in left.meld_rank_options():
				if right.can_represent(value): near = true; break
				for suit in left.meld_suit_options():
					for offset in [-2, -1, 1, 2]:
						if right.can_represent(value + offset, suit): near = true; break
			if near:
				ids[left.unique_id] = true
				ids[right.unique_id] = true
	return ids

static func has_near_meld(cards: Array[CardData]) -> bool:
	return not near_meld_ids(cards).is_empty()
