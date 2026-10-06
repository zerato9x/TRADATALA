@tool
extends McpTestSuite

class CountingQueries extends DealQueries:
	var analyses := 0
	func _legal_action_candidates() -> Array:
		analyses += 1
		return super._legal_action_candidates()

func suite_name() -> String:
	return "card_action_cache"

func test_selection_reuses_analysis_and_returns_independent_cues() -> void:
	var deal := DealState.new()
	var queries := CountingQueries.new(deal)
	deal.queries = queries
	deal.start_tutorial_deal()
	var cues := deal.queries.legal_action_card_ids()
	var expected := cues.duplicate(true)
	cues.meld.clear()
	cues.extend["outside_hand"] = true
	assert_eq(deal.queries.legal_action_card_ids(), expected)
	for card in deal.hand:
		deal.queries.legal_action_targets_for_selection([card] as Array[CardData])
	assert_eq(queries.analyses, 1)
	deal.hand[0].negative = true
	deal.queries.legal_action_card_ids()
	assert_eq(queries.analyses, 2)
	deal.zodiac_boss.locked_ids.append(deal.hand[1].unique_id)
	deal.queries.legal_action_card_ids()
	assert_eq(queries.analyses, 3)
	deal.state = DealState.STATE_FINAL_COMMIT_WINDOW
	deal.queries.legal_action_card_ids()
	assert_eq(queries.analyses, 4)
	deal.current_drink_id = DrinkCatalog.MIA_TAC
	deal.queries.legal_action_card_ids()
	assert_eq(queries.analyses, 5)
	var replacement := deal.hand[0].copy_for_deal()
	deal.hand[0] = replacement
	deal.queries.legal_action_targets_for_selection([replacement] as Array[CardData])
	assert_eq(queries.analyses, 6)

func test_cached_options_match_exhaustive_authority_after_mutations() -> void:
	var deal := DealState.new()
	deal.start_tutorial_deal()
	deal.hand.resize(8)
	deal.melds.append(MeldState.new(1, MeldRules.TYPE_RUN, [
		_card("3", "Spades", "table"), _card("4", "Spades", "table"), _card("5", "Spades", "table")
	] as Array[CardData]))
	deal.melds.append(MeldState.new(2, MeldRules.TYPE_RUN, [
		_card("A", "Diamonds", "table"), _card("2", "Hearts", "table"), _card("3", "Diamonds", "table")
	] as Array[CardData]))
	deal.melds[1].run_compatibility = "red"
	for variant in range(8):
		match variant:
			1: deal.hand[0].negative = true
			2: deal.hand[0].liquid = true
			3: deal.current_drink_id = DrinkCatalog.MIA_TAC
			4: deal.zodiac_boss.locked_ids.append(deal.hand[1].unique_id)
			5: deal.zodiac_boss.configure("cat", ZodiacCatalog.UNPLEASED, 99)
			6:
				deal.current_phase = 2
				deal.state = DealState.STATE_FINAL_COMMIT_WINDOW
			7:
				deal.zodiac_boss.configure("dog", ZodiacCatalog.UNPLEASED, 99)
				deal.zodiac_boss.data.loyal_meld_id = 1
		var selected: Array[CardData] = [deal.hand[0], deal.hand[2]]
		var oracle := _exhaustive(deal, selected, 2)
		assert_eq(deal.queries.legal_action_card_ids(), oracle.cues)
		assert_eq(deal.queries.legal_action_targets_for_selection(selected, 2), oracle.targets)
	# Table edits must invalidate even when the hand and selected IDs are unchanged.
	deal.melds[0].cards.append(_card("6", "Spades", "table"))
	assert_eq(deal.queries.legal_action_card_ids(), _exhaustive(deal, [], -1).cues)
	var snapshot := deal.snapshot_state()
	deal.restore_snapshot(snapshot)
	assert_eq(deal.queries.legal_action_card_ids(), _exhaustive(deal, [], -1).cues)

func _exhaustive(deal: DealState, selected: Array[CardData], selected_meld: int) -> Dictionary:
	var cues := {"meld": {}, "extend": {}}
	var targets := {"hand": {}, "melds": {}}
	var required := {}
	for card in selected: required[card.unique_id] = true
	for mask in range(1, 1 << deal.hand.size()):
		var cards: Array[CardData] = []
		for index in deal.hand.size():
			if mask & (1 << index): cards.append(deal.hand[index])
		if deal.can_create_meld(cards):
			for card in cards: cues.meld[card.unique_id] = true
			if not required.is_empty() and selected.all(func(card): return cards.has(card)):
				for card in cards: targets.hand[card.unique_id] = true
		for meld in deal.melds:
			if deal.can_extend_meld(meld.meld_id, cards):
				for card in cards:
					cues.extend[card.unique_id] = true
					if meld.meld_id == selected_meld: targets.hand[card.unique_id] = true
	for meld in deal.melds:
		if deal.can_extend_meld(meld.meld_id, selected): targets.melds[meld.meld_id] = true
	return {"cues": cues, "targets": targets}

func test_pruning_matches_exhaustive_rules_for_flexible_and_color_runs() -> void:
	for seed_value in range(12):
		var deal := DealState.new()
		deal.start_deal(seed_value, true)
		deal.hand.resize(8)
		for index in deal.hand.size():
			deal.hand[index].negative = (index + seed_value) % 3 == 0 or seed_value == 11
			deal.hand[index].liquid = (index + seed_value) % 4 == 0 or seed_value == 11
		deal.current_drink_id = [DrinkCatalog.NONE, DrinkCatalog.MIA_TAC, DrinkCatalog.MIA_SAU_RIENG][seed_value % 3]
		var table: Array[CardData] = []
		for rank in [3, 4, 5]: table.append(_card(str(rank), "Hearts", "random"))
		table[0].negative = seed_value % 2 == 0
		deal.melds.append(MeldState.new(1, MeldRules.TYPE_RUN, table))
		deal.melds[0].run_compatibility = ["same", "any", "red"][seed_value % 3]
		if seed_value % 2 == 1: deal.state = DealState.STATE_FINAL_COMMIT_WINDOW
		var selected: Array[CardData] = [deal.hand[0], deal.hand[3]]
		var oracle := _exhaustive(deal, selected, 1)
		assert_eq(deal.queries.legal_action_card_ids(), oracle.cues)
		assert_eq(deal.queries.legal_action_targets_for_selection(selected, 1), oracle.targets)

func test_passive_color_drinks_preserve_ordinary_runs_of_both_colors() -> void:
	for drink in [DrinkCatalog.MIA_TAC, DrinkCatalog.MIA_SAU_RIENG]:
		var deal := DealState.new()
		deal.current_drink_id = drink
		var ordinary_suit := "Spades" if drink == DrinkCatalog.MIA_TAC else "Hearts"
		var mixed_suits: Array[String] = []
		mixed_suits.assign(["Hearts", "Diamonds", "Hearts"] if drink == DrinkCatalog.MIA_TAC else ["Spades", "Clubs", "Spades"])
		for rank in [3, 4, 5]: deal.hand.append(_card(str(rank), ordinary_suit, "ordinary"))
		for index in 3: deal.hand.append(_card(str(index + 6), mixed_suits[index], "mixed"))
		deal.hand.append(_card("K", "Clubs", "discard"))
		var selected: Array[CardData] = [deal.hand[0]]
		var oracle := _exhaustive(deal, selected, -1)
		assert_eq(deal.queries.legal_action_card_ids(), oracle.cues)
		assert_eq(deal.queries.legal_action_targets_for_selection(selected), oracle.targets)
		assert_eq(oracle.cues.meld.size(), 6)

func _card(rank: String, suit: String, suffix: String) -> CardData:
	var index := DeckManager.RANKS.find(rank) + 1
	return CardData.new("cache_%s_%s_%s" % [rank, suit, suffix], rank, index, suit, index)
