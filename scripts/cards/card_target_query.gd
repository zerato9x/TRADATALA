class_name CardTargetQuery
extends RefCounted
## Physical-card queries shared by campaign services. All values are current,
## persistent values; printed identity is used only to detect transformations.

static func shuffled(source: Array[CardData], rng: RandomNumberGenerator) -> Array[CardData]:
	var cards: Array[CardData] = source.duplicate()
	for index in range(cards.size() - 1, 0, -1):
		var swap := rng.randi_range(0, index)
		var card := cards[index]
		cards[index] = cards[swap]
		cards[swap] = card
	return cards

static func random_cards(source: Array[CardData], count: int, rng: RandomNumberGenerator) -> Array[CardData]:
	return shuffled(source, rng).slice(0, mini(count, source.size()))

static func with_suit(source: Array[CardData], suit: String) -> Array[CardData]:
	return source.filter(func(card: CardData): return card.suit == suit)

static func with_rank(source: Array[CardData], rank_index: int) -> Array[CardData]:
	return source.filter(func(card: CardData): return card.rank_index == rank_index)

static func consecutive_starts(source: Array[CardData], count: int) -> Array[int]:
	var starts: Array[int] = []
	for start in range(1, 15 - count):
		var valid := true
		for offset in count:
			if with_rank(source, start + offset).is_empty():
				valid = false
				break
		if valid: starts.append(start)
	return starts

static func random_same_suit(source: Array[CardData], count: int, rng: RandomNumberGenerator) -> Array[CardData]:
	var suits: Array[String] = []
	for suit in DeckManager.SUITS:
		if with_suit(source, suit).size() >= count: suits.append(suit)
	if suits.is_empty(): return []
	return random_cards(with_suit(source, suits[rng.randi_range(0, suits.size() - 1)]), count, rng)

static func random_consecutive(source: Array[CardData], count: int, rng: RandomNumberGenerator) -> Array[CardData]:
	var starts := consecutive_starts(source, count)
	if starts.is_empty(): return []
	var start := starts[rng.randi_range(0, starts.size() - 1)]
	var picked: Array[CardData] = []
	for offset in count:
		var candidates := with_rank(source, start + offset)
		picked.append(candidates[rng.randi_range(0, candidates.size() - 1)])
	return picked

static func transformed_rank(card: CardData) -> bool:
	var identity := card.unique_id.split("_")
	return identity.size() == 3 and identity[0] == "standard" and card.rank != identity[1].to_upper()

static func transformed_suit(card: CardData) -> bool:
	var identity := card.unique_id.split("_")
	return identity.size() == 3 and identity[0] == "standard" and card.suit.to_lower() != identity[2]

static func pool(source: Array[CardData], rule: String, quantity: int = 1) -> Array[CardData]:
	var cards: Array[CardData] = []
	var highest := 0
	for card in source: highest = maxi(highest, card.permanent_property_count())
	var starts: Array[int] = []
	if rule.begins_with("CONSECUTIVE_"): starts = consecutive_starts(source, quantity)
	for card in source:
		var include := true
		match rule:
			"HAS_GIEO_PROPERTY": include = card.has_fortune_properties()
			"HAS_GOLD_PROPERTY": include = card.fortune > 0
			"TRANSFORMED_ANY": include = transformed_rank(card) or transformed_suit(card)
			"PERMANENTLY_CHANGED": include = card.has_permanent_changes()
			"TRANSFORMED_RANK": include = transformed_rank(card)
			"TRANSFORMED_SUIT": include = transformed_suit(card)
			"HIGHEST_PROPERTY_COUNT": include = card.permanent_property_count() == highest
			"SAME_SUIT_2", "SAME_SUIT_3": include = with_suit(source, card.suit).size() >= quantity
			"CONSECUTIVE_2", "CONSECUTIVE_3": include = starts.any(func(start: int): return card.rank_index >= start and card.rank_index < start + quantity)
			"ANY", "CHOOSE_ONE", "OFFER_THREE", "RANDOM": pass
			_: include = false
		if include: cards.append(card)
	return cards

static func can_complete(source: Array[CardData], selected: Array[CardData], rule: String, quantity: int) -> bool:
	if source.size() < quantity or selected.size() > quantity: return false
	var ids := {}
	for card in selected:
		if card not in source or ids.has(card.unique_id): return false
		ids[card.unique_id] = true
	if rule.begins_with("SAME_SUIT_"):
		for suit in DeckManager.SUITS:
			if with_suit(source, suit).size() >= quantity and selected.all(func(card: CardData): return card.suit == suit): return true
		return false
	if rule.begins_with("CONSECUTIVE_"):
		for start in consecutive_starts(source, quantity):
			var ranks := {}
			var valid := true
			for card in selected:
				if card.rank_index < start or card.rank_index >= start + quantity or ranks.has(card.rank_index): valid = false
				ranks[card.rank_index] = true
			if valid: return true
		return false
	return true

static func resolve_ids(source: Array[CardData], ids: Array) -> Array[CardData]:
	var cards: Array[CardData] = []
	for id: String in ids:
		for card in source:
			if card.unique_id == id:
				cards.append(card)
				break
	return cards

static func physical_ids(cards: Array[CardData]) -> Array[String]:
	var ids: Array[String] = []
	for card in cards: ids.append(card.unique_id)
	return ids
