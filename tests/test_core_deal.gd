@tool
extends McpTestSuite


func suite_name() -> String:
	return "core_deal"


func suite_setup(_ctx: Dictionary) -> void:
	# MCP editor sessions can retain a global-class Script resource after an
	# external write. Replace that cache entry so connected-editor runs execute
	# the same DealState source as a fresh game/headless process.
	ResourceLoader.load(
		"res://scripts/gameplay/deal_state.gd",
		"GDScript",
		ResourceLoader.CACHE_MODE_REPLACE
	)


func test_standard_deck_has_52_unique_cards() -> void:
	var deck := DeckManager.new()
	var cards := deck.build_standard_deck()
	var ids := {}
	for card in cards:
		ids[card.unique_id] = true
	assert_eq(cards.size(), 52)
	assert_eq(ids.size(), 52)


func test_card_rank_and_mutable_value_are_separate() -> void:
	var card := _card("7", "Hearts")
	card.value_modifiers.append(1)
	assert_eq(card.rank, "7")
	assert_eq(card.score_value(), 8)


func test_set_validation_accepts_three_or_more_matching_ranks() -> void:
	var cards: Array[CardData] = [
		_card("K", "Spades", "a"),
		_card("K", "Hearts", "b"),
		_card("K", "Diamonds", "c"),
		_card("K", "Clubs", "d"),
		_card("K", "Spades", "future_duplicate"),
	]
	assert_eq(MeldRules.classify(cards), MeldRules.TYPE_SET)


func test_run_validation_accepts_ace_low_consecutive_suit() -> void:
	var cards: Array[CardData] = [
		_card("A", "Spades"),
		_card("2", "Spades"),
		_card("3", "Spades"),
	]
	assert_eq(MeldRules.classify(cards), MeldRules.TYPE_RUN)


func test_invalid_melds_are_rejected() -> void:
	var mixed_suits: Array[CardData] = [_card("6", "Spades"), _card("7", "Hearts"), _card("8", "Spades")]
	var wrapped_ace: Array[CardData] = [_card("Q", "Clubs"), _card("K", "Clubs"), _card("A", "Clubs")]
	assert_eq(MeldRules.classify(mixed_suits), MeldRules.TYPE_INVALID)
	assert_eq(MeldRules.classify(wrapped_ace), MeldRules.TYPE_INVALID)


func test_three_card_meld_scoring() -> void:
	var cards: Array[CardData] = [_card("K", "Spades"), _card("K", "Hearts"), _card("K", "Diamonds")]
	var context := ScoringPipeline.new().score_new_meld(cards, MeldRules.TYPE_SET, 1)
	assert_eq(context.card_value_sum, 39)
	assert_eq(context.local_mult, 3)
	assert_eq(context.final_points, 117)


func test_four_card_meld_scoring() -> void:
	var cards: Array[CardData] = [_card("6", "Spades"), _card("7", "Spades"), _card("8", "Spades"), _card("9", "Spades")]
	var context := ScoringPipeline.new().score_new_meld(cards, MeldRules.TYPE_RUN, 1)
	assert_eq(context.card_value_sum, 30)
	assert_eq(context.local_mult, 4)
	assert_eq(context.final_points, 120)


func test_extension_pays_only_score_delta() -> void:
	var all_cards: Array[CardData] = [_card("6", "Spades"), _card("7", "Spades"), _card("8", "Spades"), _card("9", "Spades")]
	var context := ScoringPipeline.new().score_extension(all_cards, MeldRules.TYPE_RUN, 63, 1)
	assert_eq(context.theoretical_score, 120)
	assert_eq(context.final_points, 57)


func test_refill_draws_toward_ten() -> void:
	var deck := DeckManager.new()
	deck.reset(42)
	var hand := deck.draw(6)
	var drawn := deck.refill(hand, 10)
	assert_eq(drawn.size(), 4)
	assert_eq(hand.size(), 10)


func test_phase_completes_after_four_discards() -> void:
	var deal := DealState.new()
	deal.start_deal(11, true)
	var final_result: Dictionary = {}
	for _turn in range(4):
		final_result = deal.discard_card(deal.hand[0])
	assert_eq(deal.discard_count, 4)
	assert_eq(deal.state, DealState.STATE_PHASE_CHOICE)
	assert_true(final_result.has("phase_resolution"))


func test_new_meld_avoids_phase_mom() -> void:
	var deal := DealState.new()
	deal.start_deal(12, true)
	var set_cards: Array[CardData] = [
		_card("7", "Spades", "mom_a"),
		_card("7", "Hearts", "mom_b"),
		_card("7", "Diamonds", "mom_c"),
	]
	deal.hand.clear()
	deal.hand.append_array(set_cards)
	deal.hand.append_array(deal.deck.draw(7))
	var meld_result := deal.create_meld(set_cards)
	assert_true(meld_result["ok"])
	var final_result: Dictionary = {}
	for _turn in range(4):
		final_result = deal.discard_card(deal.hand[0])
	assert_false(final_result["phase_resolution"]["mom"])


func test_meld_commit_preserves_a_mandatory_discard_card() -> void:
	var deal := DealState.new()
	deal.start_deal(121, true)
	var only_cards: Array[CardData] = [
		_card("5", "Spades", "last_a"),
		_card("5", "Hearts", "last_b"),
		_card("5", "Diamonds", "last_c"),
	]
	deal.hand.clear()
	deal.hand.append_array(only_cards)
	var result := deal.create_meld(only_cards)
	assert_false(result["ok"])
	assert_contains(result["message"], "mandatory discard")
	assert_eq(deal.hand.size(), 3)


func test_extension_does_not_avoid_phase_mom() -> void:
	var deal := DealState.new()
	deal.start_deal(13, true)
	var base_cards: Array[CardData] = [
		_card("7", "Spades", "base_a"),
		_card("7", "Hearts", "base_b"),
		_card("7", "Diamonds", "base_c"),
	]
	var table_meld := MeldState.new(1, MeldRules.TYPE_SET, base_cards)
	table_meld.scored_points = 63
	deal.melds.append(table_meld)
	var extension := _card("7", "Clubs", "extension")
	deal.hand.clear()
	deal.hand.append(extension)
	deal.hand.append_array(deal.deck.draw(9))
	var extension_result := deal.extend_meld(1, [extension])
	assert_true(extension_result["ok"])
	assert_eq(deal.phase_new_meld_count, 0)
	var final_result: Dictionary = {}
	for _turn in range(4):
		final_result = deal.discard_card(deal.hand[0])
	assert_true(final_result["phase_resolution"]["mom"])
	assert_eq(final_result["phase_resolution"]["forfeit_points"], extension_result["context"].final_points)


func test_keep_carries_entire_loose_hand_into_phase_two() -> void:
	var deal := DealState.new()
	deal.start_deal(14, true)
	for _turn in range(4):
		deal.discard_card(deal.hand[0])
	var kept_ids := {}
	for card in deal.hand:
		kept_ids[card.unique_id] = true
	var result := deal.choose_phase_two(true)
	assert_true(result["ok"])
	assert_eq(deal.current_phase, 2)
	for kept_id in kept_ids:
		assert_true(_hand_has_id(deal.hand, kept_id), "KEEP lost card %s" % kept_id)
	assert_eq(deal.hand.size(), DealState.ACTIVE_HAND_TARGET)


func test_dump_replaces_entire_loose_hand_for_phase_two() -> void:
	var deal := DealState.new()
	deal.start_deal(15, true)
	for _turn in range(4):
		deal.discard_card(deal.hand[0])
	var dumped_ids := {}
	for card in deal.hand:
		dumped_ids[card.unique_id] = true
	var result := deal.choose_phase_two(false)
	assert_true(result["ok"])
	assert_eq(result["dumped"].size(), dumped_ids.size())
	for dumped_id in dumped_ids:
		assert_false(_hand_has_id(deal.hand, dumped_id), "DUMP retained card %s" % dumped_id)
	assert_eq(deal.hand.size(), DealState.ACTIVE_HAND_TARGET)


func test_deadwood_uses_value_sum_times_card_count() -> void:
	var cards: Array[CardData] = [
		_card("K", "Spades", "dw_a"),
		_card("K", "Hearts", "dw_b"),
		_card("Q", "Diamonds", "dw_c"),
		_card("J", "Clubs", "dw_d"),
		_card("6", "Spades", "dw_e"),
	]
	assert_eq(ScoringPipeline.deadwood_points(cards), 275)


func test_point_to_vnd_conversion_uses_integer_thousands() -> void:
	assert_eq(VndWallet.points_to_vnd(63), 63000)
	assert_eq(VndWallet.points_to_vnd(-275), -275000)
	assert_eq(VndWallet.format_vnd(1234567890), "₫1.234.567.890")


func _card(rank: String, suit: String, suffix: String = "") -> CardData:
	var rank_index := DeckManager.RANKS.find(rank) + 1
	var unique_id := "test_%s_%s_%s" % [rank, suit, suffix]
	return CardData.new(unique_id, rank, rank_index, suit, rank_index)


func _hand_has_id(hand: Array[CardData], unique_id: String) -> bool:
	for card in hand:
		if card.unique_id == unique_id:
			return true
	return false
