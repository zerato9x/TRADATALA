@tool
extends McpTestSuite

const MUSIC_BEAT_DETECTOR_PATH := "res://scripts/audio/music_beat_detector.gd"
const SCORING_PIPELINE_PATH := "res://scripts/scoring/scoring_pipeline.gd"
const CARD_DRAG_PAYLOAD_SCRIPT := preload("res://scripts/ui/card_drag_payload.gd")


func suite_name() -> String:
	return "core_deal"


func suite_setup(_ctx: Dictionary) -> void:
	ResourceLoader.load(SCORING_PIPELINE_PATH, "GDScript", ResourceLoader.CACHE_MODE_REPLACE)
	ResourceLoader.load("res://scripts/gameplay/deal_state.gd", "GDScript", ResourceLoader.CACHE_MODE_REPLACE)
	ResourceLoader.load(MUSIC_BEAT_DETECTOR_PATH, "GDScript", ResourceLoader.CACHE_MODE_REPLACE)


func test_standard_deck_has_52_unique_cards() -> void:
	var deck := DeckManager.new()
	var cards := deck.build_standard_deck()
	var ids := {}
	for card in cards:
		ids[card.unique_id] = true
	assert_eq(cards.size(), 52)
	assert_eq(ids.size(), 52)


func test_tutorial_deal_has_a_fixed_run_set_and_extension_draw() -> void:
	var deal := DealState.new()
	var result := deal.start_tutorial_deal()
	assert_true(result.get("ok", false))
	assert_eq(deal.hand.size(), DealState.ACTIVE_HAND_TARGET)
	var by_id := {}
	for card in deal.hand:
		by_id[card.unique_id] = card
	var run_cards: Array[CardData] = [
		by_id["standard_4_hearts"], by_id["standard_5_hearts"], by_id["standard_6_hearts"],
	]
	var set_cards: Array[CardData] = [
		by_id["standard_9_spades"], by_id["standard_9_hearts"], by_id["standard_9_diamonds"],
	]
	assert_true(deal.can_create_meld(run_cards))
	assert_true(deal.can_create_meld(set_cards))
	assert_eq(deal.deck.draw_pile[-1].unique_id, "standard_7_hearts")
	var all_ids := {}
	for card in deal.hand + deal.deck.draw_pile:
		all_ids[card.unique_id] = true
	assert_eq(all_ids.size(), 52)


func test_music_beat_detector_triggers_on_onsets_with_a_cooldown() -> void:
	var detector = _new_music_detector()
	for _sample in range(45):
		assert_false(detector.process_energy_sample(0.08, 1.0 / 60.0))
	assert_true(detector.process_energy_sample(0.9, 1.0 / 60.0))
	assert_false(detector.process_energy_sample(0.9, 1.0 / 60.0))
	for _sample in range(20):
		detector.process_energy_sample(0.04, 1.0 / 60.0)
	assert_true(detector.process_energy_sample(0.9, 1.0 / 60.0))
	detector.free()


func test_music_frequency_bands_map_independently_to_logo_units() -> void:
	var detector = _new_music_detector()
	var constants: Dictionary = detector.get_script().get_script_constant_map()
	assert_eq(constants.get(&"BAND_NAMES", []), ["TRA", "DA", "TA", "LA"])
	assert_eq(constants.get(&"BAND_RANGES_HZ", []).size(), 4)
	for _sample in range(45):
		for band_index in range(int(constants.get(&"BAND_COUNT", 0))):
			assert_false(detector.process_band_energy_sample(band_index, 0.04, 1.0 / 60.0))
	assert_true(detector.process_band_energy_sample(0, 0.9, 1.0 / 60.0))
	assert_true(detector.process_band_energy_sample(1, 0.9, 1.0 / 60.0))
	assert_false(detector.process_band_energy_sample(0, 0.9, 1.0 / 60.0))
	assert_false(detector.process_band_energy_sample(1, 0.9, 1.0 / 60.0))
	assert_eq(detector.band_pulse_counts, PackedInt32Array([1, 1, 0, 0]))
	detector.free()


func test_card_rank_and_mutable_value_are_separate() -> void:
	var card := _card("7", "Hearts")
	card.value_modifiers.append(1)
	assert_eq(card.rank, "7")
	assert_eq(card.score_value(), 8)


func test_set_validation_accepts_duplicate_physical_cards_beyond_four() -> void:
	for card_count in [4, 5, 8, 12]:
		assert_eq(MeldRules.classify(_kings(card_count)), MeldRules.TYPE_SET)


func test_run_validation_is_ace_low_consecutive_and_rejects_duplicates_or_wraps() -> void:
	assert_eq(MeldRules.classify([
		_card("A", "Spades"), _card("2", "Spades"), _card("3", "Spades")
	] as Array[CardData]), MeldRules.TYPE_RUN)
	assert_eq(MeldRules.classify([
		_card("Q", "Clubs"), _card("K", "Clubs"), _card("A", "Clubs")
	] as Array[CardData]), MeldRules.TYPE_INVALID)
	assert_eq(MeldRules.classify([
		_card("7", "Hearts", "a"), _card("7", "Hearts", "b"), _card("8", "Hearts")
	] as Array[CardData]), MeldRules.TYPE_INVALID)


func test_base_new_phom_scoring_uses_value_sum_times_card_count() -> void:
	var cards: Array[CardData] = [_card("7", "Clubs"), _card("8", "Clubs"), _card("9", "Clubs")]
	var context := ScoringPipeline.new().score_new_meld(cards, MeldRules.TYPE_RUN, 1)
	assert_eq(context.card_value_sum, 24)
	assert_eq(context.local_mult, 3)
	assert_eq(context.final_points, 72)


func test_extension_pays_only_intrinsic_score_delta() -> void:
	var all_cards: Array[CardData] = [_card("6", "Spades"), _card("7", "Spades"), _card("8", "Spades"), _card("9", "Spades")]
	var context := ScoringPipeline.new().score_extension(all_cards, MeldRules.TYPE_RUN, 63, 1, [all_cards[-1]])
	assert_eq(context.theoretical_score, 120)
	assert_eq(context.base_extension_score, 57)
	assert_eq(context.final_points, 57)


func test_set_native_retrigger_only_occurs_at_exact_four_card_multiples() -> void:
	for card_count in [3, 4, 5, 6, 7, 8, 9, 11, 12, 16]:
		var context := ScoringPipeline.new().score_new_meld(_kings(card_count), MeldRules.TYPE_SET, 1)
		var expected_retriggers := 1 if card_count % 4 == 0 else 0
		assert_eq(context.retrigger_count, expected_retriggers, "unexpected retrigger count at %d cards" % card_count)
		assert_eq(context.scoring_passes.size(), expected_retriggers + 1)


func test_king_set_milestones_override_extension_delta_with_two_full_passes() -> void:
	var pipeline := ScoringPipeline.new()
	var emitted_passes: Array[ScoringContext] = []
	pipeline.context_scored.connect(func(scoring_pass: ScoringContext) -> void: emitted_passes.append(scoring_pass))
	var four := pipeline.score_new_meld(_kings(4), MeldRules.TYPE_SET, 1)
	assert_eq(four.theoretical_score, 208)
	assert_eq(four.final_points, 416)
	assert_eq(four.scoring_passes.size(), 2)
	assert_eq((four.scoring_passes[0] as ScoringContext).final_points, 208)
	assert_eq((four.scoring_passes[1] as ScoringContext).final_points, 208)
	assert_eq(emitted_passes.size(), 2)
	assert_eq(emitted_passes[0].trigger_origin, ScoringPipeline.TRIGGER_ORIGINATING)
	assert_eq(emitted_passes[1].trigger_origin, ScoringPipeline.TRIGGER_NATIVE_RETRIGGER)
	emitted_passes.clear()
	var five := pipeline.score_extension(_kings(5), MeldRules.TYPE_SET, 208, 1)
	var six := pipeline.score_extension(_kings(6), MeldRules.TYPE_SET, 325, 1)
	var seven := pipeline.score_extension(_kings(7), MeldRules.TYPE_SET, 468, 1)
	var eight := pipeline.score_extension(_kings(8), MeldRules.TYPE_SET, 637, 1)
	var twelve := pipeline.score_extension(_kings(12), MeldRules.TYPE_SET, 1573, 1)
	assert_eq(five.final_points, 117)
	assert_eq(six.final_points, 143)
	assert_eq(seven.final_points, 169)
	assert_eq(eight.final_points, 1664)
	assert_eq(eight.retrigger_count, 1)
	assert_eq(eight.scoring_passes.size(), 2)
	assert_eq(twelve.final_points, 3744)
	assert_eq(twelve.retrigger_count, 1)
	assert_eq(twelve.scoring_passes.size(), 2)


func test_exhaustion_meld_trigger_uses_current_set_milestone_without_recursion() -> void:
	var pipeline := ScoringPipeline.new()
	for card_count in [3, 4, 5, 8, 12]:
		var context := pipeline.score_meld_trigger(_kings(card_count), MeldRules.TYPE_SET, 1)
		var expected_passes := 2 if card_count % 4 == 0 else 1
		assert_eq(context.scoring_passes.size(), expected_passes)
		assert_eq(context.retrigger_count, expected_passes - 1)
		for scoring_pass: ScoringContext in context.scoring_passes:
			assert_true(scoring_pass.scoring_passes.is_empty())
			assert_eq(scoring_pass.retrigger_count, 0)


func test_perfected_run_preserves_x13_and_ordinary_runs_do_not_retrigger() -> void:
	var pipeline := ScoringPipeline.new()
	var ordinary := pipeline.score_new_meld([
		_card("4", "Hearts"), _card("5", "Hearts"), _card("6", "Hearts"),
	] as Array[CardData], MeldRules.TYPE_RUN, 1)
	assert_eq(ordinary.retrigger_count, 0)
	assert_eq(ordinary.scoring_passes.size(), 1)
	var perfected: Array[CardData] = []
	for rank in DeckManager.RANKS:
		perfected.append(_card(rank, "Clubs", "perfected"))
	var context := pipeline.score_new_meld(perfected, MeldRules.TYPE_RUN, 1)
	assert_true(ScoringPipeline.is_perfected_run(perfected, MeldRules.TYPE_RUN))
	assert_eq(context.theoretical_score, 1183)
	assert_eq(context.final_points, 2366)
	assert_eq(context.retrigger_count, 1)
	assert_eq(context.scoring_passes.size(), 2)
	assert_eq((context.scoring_passes[0] as ScoringContext).final_points, 1183)
	assert_eq((context.scoring_passes[1] as ScoringContext).final_points, 1183)


func test_deadwood_is_a_single_simple_value_sum() -> void:
	var cards: Array[CardData] = [
		_card("A", "Spades"), _card("4", "Hearts"), _card("8", "Diamonds"), _card("K", "Clubs"),
	]
	assert_eq(ScoringPipeline.deadwood_points(cards), 26)


func test_fourth_discard_enters_final_commit_window_without_settling() -> void:
	var deal := _fresh_deal(11)
	var final_result := _advance_to_last_call(deal)
	assert_eq(deal.discard_count, 4)
	assert_eq(deal.state, DealState.STATE_FINAL_COMMIT_WINDOW)
	assert_true(final_result.get("final_commit_window", false))
	assert_false(final_result.has("phase_resolution"))
	assert_true(deal.settlements.is_empty())


func test_final_commit_window_allows_hạ_of_the_entire_loose_hand() -> void:
	var deal := _fresh_deal(12)
	_advance_to_last_call(deal)
	var final_set: Array[CardData] = [
		_card("5", "Spades", "last_a"), _card("5", "Hearts", "last_b"), _card("5", "Diamonds", "last_c"),
	]
	deal.hand.clear()
	deal.hand.append_array(final_set)
	var result := deal.create_meld(final_set)
	assert_true(result["ok"])
	assert_true(deal.hand.is_empty())
	assert_eq(deal.state, DealState.STATE_FINAL_COMMIT_WINDOW)


func test_active_turn_hạ_preserves_the_mandatory_discard_card() -> void:
	var deal := _fresh_deal(121)
	var only_cards: Array[CardData] = [
		_card("5", "Spades", "only_a"), _card("5", "Hearts", "only_b"), _card("5", "Diamonds", "only_c"),
	]
	deal.hand.clear()
	deal.hand.append_array(only_cards)
	var result := deal.create_meld(only_cards)
	assert_false(result["ok"])
	assert_contains(result["message"], "mandatory discard")


func test_safe_phase_deadwood_remains_a_simple_value_sum() -> void:
	var deal := _fresh_deal(14)
	_advance_to_last_call(deal)
	deal.wallet.reset()
	deal.phase_metrics.raw_gross = 40
	deal.phase_metrics.new_phom_count = 1
	deal.phase_earnings_points = 40
	deal.phase_new_meld_count = 1
	deal.wallet.apply_points(40, "test_gross")
	deal.hand.clear()
	deal.hand.append_array([_card("A", "Spades"), _card("4", "Hearts"), _card("K", "Clubs")])
	var result := deal.settle_phase()
	var resolution: Dictionary = result["phase_resolution"]
	assert_false(resolution["mom"])
	assert_eq(resolution["deadwood_value_sum"], 18)
	assert_eq(resolution["deadwood_multiplier"], 1)
	assert_eq(resolution["deadwood"], 18)
	assert_eq(resolution["net"], 22)
	assert_eq(deal.wallet.balance_vnd, VndWallet.points_to_vnd(22))


func test_mom_deadwood_uses_value_sum_times_loose_card_count() -> void:
	var deal := _fresh_deal(15)
	_advance_to_last_call(deal)
	deal.wallet.reset()
	deal.phase_metrics.raw_gross = 57
	deal.phase_earnings_points = 57
	deal.wallet.apply_points(57, "extension_score")
	deal.hand.clear()
	deal.hand.append_array([_card("A", "Spades"), _card("4", "Hearts"), _card("K", "Clubs")])
	var resolution: Dictionary = deal.settle_phase()["phase_resolution"]
	assert_true(resolution["mom"])
	assert_eq(resolution["deadwood_value_sum"], 18)
	assert_eq(resolution["deadwood_multiplier"], 3)
	assert_eq(resolution["deadwood"], 54)
	assert_eq(resolution["net"], 3)
	assert_eq(resolution["deadwood"], ScoringPipeline.meld_value(resolution["remaining_hand"]))
	assert_eq(deal.wallet.balance_vnd, VndWallet.points_to_vnd(3))


func test_empty_mom_hand_has_a_zero_deadwood_equation() -> void:
	var deal := DealState.new()
	deal.start_deal(151, true)
	_advance_to_last_call(deal)
	deal.hand.clear()
	var resolution: Dictionary = deal.settle_phase()["phase_resolution"]
	assert_true(resolution["mom"])
	assert_eq(resolution["deadwood_value_sum"], 0)
	assert_eq(resolution["deadwood_multiplier"], 0)
	assert_eq(resolution["deadwood"], 0)


func test_deal_resolution_does_not_apply_a_later_mom_wallet_penalty() -> void:
	var deal := DealState.new()
	deal.wallet.reset(1_000_000)
	deal._resolve_deal()
	assert_eq(deal.wallet.balance_vnd, 1_000_000)


func test_extension_does_not_count_as_a_new_phom_for_mom() -> void:
	var deal := _fresh_deal(16)
	var base_cards: Array[CardData] = [_card("7", "Spades"), _card("7", "Hearts"), _card("7", "Diamonds")]
	var table_meld := MeldState.new(1, MeldRules.TYPE_SET, base_cards)
	table_meld.scored_points = 63
	deal.melds.append(table_meld)
	var extension := _card("7", "Clubs", "extension")
	deal.hand.clear()
	deal.hand.append(extension)
	deal.hand.append_array(deal.deck.draw(9))
	assert_true(deal.extend_meld(1, [extension])["ok"])
	assert_eq(deal.phase_metrics.extension_count, 1)
	assert_eq(deal.phase_new_meld_count, 0)
	_advance_to_last_call(deal)
	deal.hand.clear()
	assert_true(deal.settle_phase()["phase_resolution"]["mom"])


func test_keep_and_dump_happen_only_after_phase_one_settlement() -> void:
	var keep_deal := _fresh_deal(17)
	_advance_to_last_call(keep_deal)
	assert_false(keep_deal.choose_phase_two(true)["ok"])
	keep_deal.settle_phase()
	var kept_ids := _ids(keep_deal.hand)
	assert_true(keep_deal.choose_phase_two(true)["ok"])
	for kept_id in kept_ids:
		assert_true(_hand_has_id(keep_deal.hand, kept_id))

	var dump_deal := _fresh_deal(18)
	_advance_to_last_call(dump_deal)
	dump_deal.settle_phase()
	var dumped_ids := _ids(dump_deal.hand)
	var dump_result := dump_deal.choose_phase_two(false)
	assert_eq(dump_result["dumped"].size(), dumped_ids.size())
	for dumped_id in dumped_ids:
		assert_false(_hand_has_id(dump_deal.hand, dumped_id))


func test_discard_history_keeps_phase_and_number_provenance() -> void:
	var deal := _fresh_deal(19)
	_advance_to_last_call(deal)
	assert_eq(deal.discard_history.size(), 4)
	for index in range(4):
		assert_eq(deal.discard_history[index].phase, 1)
		assert_eq(deal.discard_history[index].discard_number, index + 1)
	deal.settle_phase()
	deal.choose_phase_two(true)
	deal.discard_card(deal.hand[0])
	assert_eq(deal.discard_history[-1].phase, 2)
	assert_eq(deal.discard_history[-1].discard_number, 1)


func test_u_is_phase_scoped_and_doubles_gross_before_deadwood() -> void:
	var deal := _fresh_deal(20)
	deal.hand.clear()
	var set_a: Array[CardData] = [_card("2", "Spades", "a"), _card("2", "Hearts", "a"), _card("2", "Diamonds", "a")]
	var set_b: Array[CardData] = [_card("5", "Spades", "b"), _card("5", "Hearts", "b"), _card("5", "Diamonds", "b")]
	var set_c: Array[CardData] = [_card("9", "Spades", "c"), _card("9", "Hearts", "c"), _card("9", "Diamonds", "c")]
	deal.hand.append_array(set_a + set_b + set_c)
	deal.hand.append(_card("K", "Clubs", "discard"))
	deal.wallet.reset()
	deal.phase_metrics.reset()
	deal.phase_earnings_points = 0
	deal.phase_new_meld_count = 0
	assert_true(deal.create_meld(set_a)["ok"])
	assert_true(deal.create_meld(set_b)["ok"])
	assert_true(deal.create_meld(set_c)["ok"])
	var first_discard := deal.discard_card(deal.hand[0])
	assert_true(first_discard["u_triggered"])
	for _turn in range(3):
		deal.discard_card(deal.hand[0])
	deal.hand.clear()
	var resolution: Dictionary = deal.settle_phase()["phase_resolution"]
	assert_true(resolution["u"])
	assert_eq(resolution["gross_after_u"], resolution["raw_gross"] * 2)
	assert_eq(resolution["net"], resolution["gross_after_u"])


func test_u_khan_uses_the_prototype_near_meld_rule_and_replaces_hand() -> void:
	var deal := _fresh_deal(21)
	deal.hand.clear()
	deal.hand.append_array(_u_khan_hand())
	deal.deck.draw_pile.clear()
	deal.deck.draw_pile.append_array([
		_card("2", "Spades", "replacement_pair_a"), _card("2", "Hearts", "replacement_pair_b"),
		_card("3", "Clubs", "r3"), _card("4", "Diamonds", "r4"), _card("6", "Clubs", "r6"),
		_card("8", "Diamonds", "r8"), _card("10", "Clubs", "r10"), _card("J", "Diamonds", "rj"),
		_card("Q", "Clubs", "rq"), _card("K", "Diamonds", "rk"),
	])
	deal.wallet.reset()
	deal.phase_metrics.reset()
	var expected := ScoringPipeline.deadwood_points(deal.hand) * 10
	var replaced_ids := _ids(deal.hand)
	var exhaustion_events: Array[Dictionary] = []
	deal.exhaustion_triggered.connect(func(context: Dictionary) -> void: exhaustion_events.append(context))
	deal._begin_active_turn()
	assert_eq(deal.phase_metrics.u_khan_count, 1)
	assert_eq(deal.phase_metrics.raw_gross, expected)
	assert_eq(deal.wallet.balance_vnd, VndWallet.points_to_vnd(expected))
	assert_eq(deal.hand.size(), 10)
	assert_true(exhaustion_events.is_empty())
	assert_true(deal.deck.draw_pile.is_empty())
	assert_eq(deal.deck.draw(1).size(), 1)
	assert_eq(exhaustion_events.size(), 1)
	for card_id in replaced_ids:
		assert_true(exhaustion_events[0]["recycled_card_ids"].has(card_id))


func test_fresh_deal_initializes_simplified_exhaustion_state_and_accounts_for_52_cards() -> void:
	var deal := _fresh_deal(301)
	var accounting := deal.physical_card_accounting()
	assert_true(accounting["valid"])
	assert_eq(accounting["total_cards"], 52)
	assert_eq(accounting["unique_ids"], 52)
	assert_eq(deal.exhaustion_count, 0)
	assert_true(deal.recyclable_spent_cards.is_empty())


func test_drawing_the_final_requested_card_does_not_trigger_exhaustion() -> void:
	var deal := _controlled_deal(1, 3, 302)
	var events: Array[Dictionary] = []
	deal.exhaustion_triggered.connect(func(context: Dictionary) -> void: events.append(context))
	var drawn := deal.deck.draw(1)
	assert_eq(drawn.size(), 1)
	assert_true(deal.deck.draw_pile.is_empty())
	assert_true(events.is_empty())
	assert_eq(deal.exhaustion_count, 0)


func test_interrupted_refill_resolves_exhaustion_and_resumes_the_same_request() -> void:
	var deal := _controlled_deal(2, 3, 303)
	var removed_from_hand: Array[CardData] = []
	removed_from_hand.append_array(deal.hand.slice(4))
	deal.hand.resize(4)
	deal.move_to_recyclable_spent(removed_from_hand)
	var recycled_before := deal.deck.discard_pile.size() + deal.recyclable_spent_cards.size()
	var events: Array[Dictionary] = []
	deal.exhaustion_triggered.connect(func(context: Dictionary) -> void: events.append(context))
	var drawn := deal.deck.refill(deal.hand, DealState.ACTIVE_HAND_TARGET)
	assert_eq(drawn.size(), 6)
	assert_eq(deal.hand.size(), DealState.ACTIVE_HAND_TARGET)
	assert_eq(events.size(), 1)
	assert_eq(events[0]["action"], "exhaustion")
	assert_eq(events[0]["requested_count"], 6)
	assert_eq(events[0]["drawn_before_exhaustion"], 2)
	assert_eq(events[0]["remaining_draw_count"], 4)
	assert_eq(events[0]["recycled_count"], recycled_before)
	assert_eq(deal.deck.draw_pile.size(), recycled_before - 4)
	assert_eq(deal.exhaustion_count, 1)
	assert_ne(events[0]["shuffled_card_ids"], events[0]["recycled_card_ids"])
	assert_true(deal.physical_card_accounting_is_valid())


func test_exhaustion_recycles_discard_spent_and_every_table_meld() -> void:
	var deal := _controlled_deal(0, 3, 304)
	var table_cards_a: Array[CardData] = []
	var table_cards_b: Array[CardData] = []
	for _index in range(3):
		table_cards_a.append(deal.deck.discard_pile.pop_back())
	for _index in range(4):
		table_cards_b.append(deal.deck.discard_pile.pop_back())
	var meld_a := MeldState.new(41, MeldRules.TYPE_SET, table_cards_a)
	var meld_b := MeldState.new(42, MeldRules.TYPE_RUN, table_cards_b)
	deal.melds.append_array([meld_a, meld_b] as Array[MeldState])
	var discard_ids := _ids(deal.deck.discard_pile)
	var spent_ids := _ids(deal.recyclable_spent_cards)
	var table_ids := _ids(table_cards_a + table_cards_b)
	var meld_trigger_ids: Array[int] = []
	var meld_a_triggers: Array[Dictionary] = []
	var meld_b_triggers: Array[Dictionary] = []
	meld_a.exhaustion_triggered.connect(func(context: Dictionary) -> void: meld_a_triggers.append(context))
	meld_b.exhaustion_triggered.connect(func(context: Dictionary) -> void: meld_b_triggers.append(context))
	var events: Array[Dictionary] = []
	deal.meld_exhaustion_triggered.connect(func(meld: MeldState, _context: Dictionary) -> void: meld_trigger_ids.append(meld.meld_id))
	deal.exhaustion_triggered.connect(func(context: Dictionary) -> void: events.append(context))
	var drawn := deal.deck.draw(1)
	deal.hand.append_array(drawn)
	assert_eq(drawn.size(), 1)
	assert_eq(meld_trigger_ids, [41, 42])
	assert_eq(meld_a_triggers.size(), 1)
	assert_eq(meld_b_triggers.size(), 1)
	assert_eq(events.size(), 1)
	assert_eq(events[0]["triggered_meld_ids"], [41, 42])
	assert_true(deal.melds.is_empty())
	assert_true(deal.deck.discard_pile.is_empty())
	assert_true(deal.recyclable_spent_cards.is_empty())
	var rebuilt_ids := _ids(deal.deck.draw_pile + drawn)
	var expected_recycled_ids := discard_ids.duplicate()
	expected_recycled_ids.merge(spent_ids)
	expected_recycled_ids.merge(table_ids)
	for card_id in expected_recycled_ids:
		assert_true(rebuilt_ids.has(card_id))
	assert_true(deal.physical_card_accounting_is_valid())


func test_extended_meld_triggers_once_per_exhaustion_event() -> void:
	var deal := _controlled_deal(0, 0, 305)
	var meld_cards: Array[CardData] = []
	for _index in range(6):
		meld_cards.append(deal.deck.discard_pile.pop_back())
	var meld := MeldState.new(77, MeldRules.TYPE_RUN, meld_cards)
	deal.melds.append(meld)
	var trigger_contexts: Array[Dictionary] = []
	deal.meld_exhaustion_triggered.connect(func(_meld: MeldState, context: Dictionary) -> void: trigger_contexts.append(context))
	assert_eq(deal.deck.draw(1).size(), 1)
	assert_eq(trigger_contexts.size(), 1)
	assert_eq(trigger_contexts[0]["meld_id"], 77)
	assert_eq(trigger_contexts[0]["card_count"], 6)


func test_empty_stock_actions_do_not_trigger_until_a_draw_is_requested() -> void:
	var deal := _controlled_deal(0, 0, 306)
	var events: Array[Dictionary] = []
	deal.exhaustion_triggered.connect(func(context: Dictionary) -> void: events.append(context))
	var set_cards: Array[CardData] = [deal.hand[0], deal.hand[1], deal.hand[2]]
	set_cards[1].rank = set_cards[0].rank
	set_cards[1].rank_index = set_cards[0].rank_index
	set_cards[2].rank = set_cards[0].rank
	set_cards[2].rank_index = set_cards[0].rank_index
	assert_true(deal.create_meld(set_cards)["ok"])
	assert_true(events.is_empty())
	deal.discard_count = DealState.DISCARDS_PER_PHASE - 1
	var discard_result := deal.discard_card(deal.hand[0])
	assert_true(discard_result.get("final_commit_window", false))
	assert_true(events.is_empty())
	assert_eq(deal.exhaustion_count, 0)


func test_dumped_cards_wait_in_spent_until_a_refill_requests_exhaustion() -> void:
	var deal := _fresh_deal(310)
	_advance_to_last_call(deal)
	assert_true(deal.settle_phase()["ok"])
	var dumped_hand := deal.hand.duplicate()
	var result := deal.choose_phase_two(false)
	assert_true(result["ok"])
	assert_eq(result["dumped"].size(), dumped_hand.size())
	for card in result["dumped"]:
		assert_true(deal.recyclable_spent_cards.has(card) or deal.deck.draw_pile.has(card) or deal.hand.has(card))
	assert_true(deal.physical_card_accounting_is_valid())

func test_basic_drinks_do_not_modify_new_meld_or_extension_scoring() -> void:
	var meld_cards: Array[CardData] = [_card("6", "Spades"), _card("7", "Spades"), _card("8", "Spades")]
	var extended_cards: Array[CardData] = []
	extended_cards.append_array(meld_cards)
	extended_cards.append(_card("9", "Spades"))
	for drink_id in DrinkCatalog.basic_ids():
		var deal := DealState.new()
		deal.set_current_drink(drink_id)
		var meld_context := deal.scoring.preview_new_meld(meld_cards, MeldRules.TYPE_RUN, 1, 3)
		var extension_context := deal.scoring.preview_extension(extended_cards, MeldRules.TYPE_RUN, 63, 1, [extended_cards[-1]])
		assert_eq(meld_context.local_mult, 3)
		assert_eq(meld_context.final_points, 63)
		assert_eq(extension_context.final_points, 57)


func test_every_basic_drink_declares_a_reactive_cue_trigger() -> void:
	var seen := {}
	for drink_id in DrinkCatalog.basic_ids():
		var trigger_id := DrinkCatalog.cue_trigger(drink_id)
		assert_ne(trigger_id, "")
		assert_false(seen.has(trigger_id))
		seen[trigger_id] = true


func test_tra_da_offers_one_optional_extra_discard() -> void:
	var deal := _fresh_deal(221, DrinkCatalog.TRA_DA)
	assert_false(deal.current_drink_has_charge())
	var draw_before := deal.deck.draw_pile.size()
	var first_discard := deal.hand[0]
	var first_result := deal.discard_card(first_discard)
	assert_true(first_result["ok"])
	assert_true(first_result["extra_discard_pending"])
	assert_eq(first_result["discard_kind"], DiscardRecord.KIND_MANDATORY)
	assert_eq(deal.discard_count, 1)
	assert_eq(deal.hand.size(), DealState.RESTING_HAND_SIZE)
	assert_eq(deal.deck.draw_pile.size(), draw_before)
	assert_true(deal.tra_da_extra_discard_pending)
	assert_true(deal.drink_cue_trigger()["active"])
	var extra_discard := deal.hand[0]
	var extra_result := deal.discard_card(extra_discard)
	assert_true(extra_result["ok"])
	assert_eq(extra_result["discard_kind"], DiscardRecord.KIND_DRINK_EXTRA)
	assert_eq(deal.discard_count, 1)
	assert_eq(deal.discard_history.size(), 2)
	assert_eq(deal.discard_history[0].kind, DiscardRecord.KIND_MANDATORY)
	assert_eq(deal.discard_history[1].kind, DiscardRecord.KIND_DRINK_EXTRA)
	assert_eq(deal.discard_history_for_phase(1).size(), 1)
	assert_eq(deal.hand.size(), DealState.ACTIVE_HAND_TARGET)
	assert_eq(deal.deck.draw_pile.size(), draw_before - 2)
	assert_false(deal.tra_da_extra_discard_pending)
	assert_false(deal.drink_cue_trigger()["active"])


func test_tra_da_can_skip_the_optional_extra_and_start_the_next_turn() -> void:
	var deal := _fresh_deal(224, DrinkCatalog.TRA_DA)
	var draw_before := deal.deck.draw_pile.size()
	var first_result := deal.discard_card(deal.hand[0])
	assert_true(first_result.get("extra_discard_pending", false))
	var end_result := deal.end_turn_without_tra_da_extra()
	assert_true(end_result["ok"])
	assert_eq(end_result["action"], "tra_da_extra_skipped")
	assert_false(deal.tra_da_extra_discard_pending)
	assert_eq(deal.discard_count, 1)
	assert_eq(deal.discard_history.size(), 1)
	assert_eq(deal.hand.size(), DealState.ACTIVE_HAND_TARGET)
	assert_eq(deal.deck.draw_pile.size(), draw_before - 1)


func test_tra_da_finishes_the_phase_after_the_fourth_chosen_extra_discard() -> void:
	var deal := _fresh_deal(225, DrinkCatalog.TRA_DA)
	for turn in range(DealState.DISCARDS_PER_PHASE):
		var mandatory := deal.discard_card(deal.hand[0])
		assert_true(mandatory.get("extra_discard_pending", false))
		assert_eq(deal.state, DealState.STATE_ACTIVE)
		var extra := deal.discard_card(deal.hand[0])
		if turn < DealState.DISCARDS_PER_PHASE - 1:
			assert_false(extra.get("final_commit_window", false))
			assert_eq(deal.state, DealState.STATE_ACTIVE)
		else:
			assert_true(extra.get("final_commit_window", false))
			assert_eq(deal.state, DealState.STATE_FINAL_COMMIT_WINDOW)
	assert_eq(deal.discard_count, DealState.DISCARDS_PER_PHASE)
	assert_eq(deal.discard_history.size(), DealState.DISCARDS_PER_PHASE * 2)
	assert_eq(deal.discard_history_for_phase(1).size(), DealState.DISCARDS_PER_PHASE)


func test_tra_da_optional_discard_does_not_block_the_screenshot_u_extensions() -> void:
	var deal := _fresh_deal(226, DrinkCatalog.TRA_DA)
	var club_run: Array[CardData] = [
		_card("4", "Clubs", "u_run"), _card("5", "Clubs", "u_run"),
		_card("6", "Clubs", "u_run"), _card("7", "Clubs", "u_run"),
		_card("8", "Clubs", "u_run"), _card("9", "Clubs", "u_run"),
		_card("10", "Clubs", "u_run"),
	]
	var two_spades := _card("2", "Spades", "u_extend")
	var six_hearts := _card("6", "Hearts", "u_extend")
	var final_discard := _card("5", "Spades", "u_discard")
	deal.hand.clear()
	deal.hand.append_array(club_run)
	deal.hand.append_array([two_spades, six_hearts, final_discard] as Array[CardData])
	deal.melds.clear()
	deal.melds.append(MeldState.new(1, MeldRules.TYPE_SET, [
		_card("2", "Clubs", "table"), _card("2", "Diamonds", "table"), _card("2", "Hearts", "table"),
	] as Array[CardData]))
	deal.melds.append(MeldState.new(2, MeldRules.TYPE_RUN, [
		_card("3", "Hearts", "table"), _card("4", "Hearts", "table"), _card("5", "Hearts", "table"),
	] as Array[CardData]))
	deal._turn_started_with_ten = true
	deal._turn_committed_card_count = 0
	deal.recyclable_spent_cards.append_array(deal.deck.draw_pile)
	deal.deck.draw_pile.clear()
	var exhaustion_events: Array[Dictionary] = []
	deal.exhaustion_triggered.connect(func(context: Dictionary) -> void: exhaustion_events.append(context))
	assert_true(deal.create_meld(club_run)["ok"])
	assert_true(deal.extend_meld(1, [two_spades] as Array[CardData])["ok"])
	assert_eq(deal.hand.size(), 2)
	assert_true(deal.can_extend_meld(2, [six_hearts] as Array[CardData]))
	assert_true(deal.extend_meld(2, [six_hearts] as Array[CardData])["ok"])
	var result := deal.discard_card(final_discard)
	assert_true(result["ok"])
	assert_true(result["u_triggered"])
	assert_true(deal.phase_metrics.u)
	assert_eq(exhaustion_events.size(), 1)
	assert_eq(deal.exhaustion_count, 1)


func test_nhan_tran_swaps_one_current_phase_mandatory_discard_once_per_phase() -> void:
	var deal := _fresh_deal(222, DrinkCatalog.NHAN_TRAN)
	assert_false(deal.current_drink_has_charge())
	var first_discard := deal.hand[0]
	assert_true(deal.discard_card(first_discard)["ok"])
	var first_record := deal.latest_mandatory_discard()
	var second_discard := deal.hand[0]
	assert_true(deal.discard_card(second_discard)["ok"])
	var second_record := deal.latest_mandatory_discard()
	var draw_before := deal.deck.draw_pile.size()
	var loose := deal.hand[0]
	var hand_size := deal.hand.size()
	assert_true(deal.current_drink_has_charge())
	var result := deal.use_nhan_tran(loose, first_record)
	assert_true(result["ok"])
	assert_eq(result["action"], "nhan_tran_swap")
	assert_false(deal.current_drink_has_charge())
	assert_eq(deal.hand.size(), hand_size)
	assert_eq(deal.discard_count, 2)
	assert_eq(deal.deck.draw_pile.size(), draw_before)
	assert_true(deal.hand.has(first_discard))
	assert_eq(first_record.card, loose)
	assert_eq(second_record.card, second_discard)
	assert_true(deal.recyclable_spent_cards.is_empty())
	assert_true(deal.physical_card_accounting_is_valid())
	assert_false(deal.use_nhan_tran(deal.hand[0], second_record)["ok"])
	while deal.state == DealState.STATE_ACTIVE:
		deal.discard_card(deal.hand[0])
	assert_eq(deal.discard_count, DealState.DISCARDS_PER_PHASE)
	assert_false(deal.current_drink_has_charge())
	assert_true(deal.settle_phase()["ok"])
	assert_true(deal.choose_phase_two(true)["ok"])
	assert_false(deal.current_drink_has_charge())
	assert_true(deal.physical_card_accounting_is_valid())


func test_nhan_tran_rejects_a_mandatory_discard_from_another_phase() -> void:
	var deal := _fresh_deal(223, DrinkCatalog.NHAN_TRAN)
	var phase_one_card := _card("A", "Clubs", "phase_one")
	var phase_two_card := _card("2", "Clubs", "phase_two")
	deal.deck.discard_pile.append(phase_one_card)
	var phase_one_record := DiscardRecord.new(phase_one_card, 1, 1)
	deal.discard_history.append(phase_one_record)
	deal.current_phase = 2
	deal.discard_count = 1
	deal.deck.discard_pile.append(phase_two_card)
	var phase_two_record := DiscardRecord.new(phase_two_card, 2, 1)
	deal.discard_history.append(phase_two_record)
	deal.hand = [_card("K", "Hearts", "loose")]
	assert_true(deal.current_drink_has_charge())
	assert_false(deal.can_use_nhan_tran(deal.hand[0], phase_one_record))
	assert_true(deal.can_use_nhan_tran(deal.hand[0], phase_two_record))


func test_nhan_tran_can_swap_in_the_final_commit_window() -> void:
	var deal := _fresh_deal(224, DrinkCatalog.NHAN_TRAN)
	while deal.state == DealState.STATE_ACTIVE:
		assert_true(deal.discard_card(deal.hand[0])["ok"])
	assert_eq(deal.state, DealState.STATE_FINAL_COMMIT_WINDOW)
	var target := deal.discard_history[0]
	var recovered := deal.discard_history[0].card
	var loose := deal.hand[0]
	var hand_size := deal.hand.size()
	assert_true(deal.current_drink_has_charge())
	var result := deal.use_nhan_tran(loose, target)
	assert_true(result["ok"])
	assert_eq(deal.hand.size(), hand_size)
	assert_true(deal.hand.has(recovered))
	assert_eq(target.card, loose)
	assert_false(deal.current_drink_has_charge())


func test_nhan_tran_cue_only_triggers_when_a_discard_completes_a_hand_meld() -> void:
	var deal := DealState.new()
	deal.set_current_drink(DrinkCatalog.NHAN_TRAN)
	deal.state = DealState.STATE_ACTIVE
	deal.hand = [
		_card("5", "Spades", "cue"), _card("6", "Spades", "cue"),
		_card("K", "Hearts", "cue"),
	] as Array[CardData]
	var irrelevant := _card("Q", "Clubs", "irrelevant")
	var useful := _card("7", "Spades", "useful")
	deal.deck.discard_pile.append(irrelevant)
	deal.discard_history.append(DiscardRecord.new(irrelevant, 1, 1))
	assert_false(deal.drink_cue_trigger()["active"])
	deal.deck.discard_pile.append(useful)
	var useful_record := DiscardRecord.new(useful, 1, 2)
	deal.discard_history.append(useful_record)
	var cue := deal.drink_cue_trigger()
	assert_true(cue["active"])
	assert_eq(cue["trigger_id"], "discard_completes_meld")
	assert_true(cue["records"].has(useful_record))
	deal.use_nhan_tran(deal.hand[-1], useful_record)
	assert_false(deal.drink_cue_trigger()["active"])


func test_nuoc_voi_returns_only_a_legal_meld_card_once_per_phase_without_unscoring() -> void:
	var deal := DealState.new()
	deal.set_current_drink(DrinkCatalog.NUOC_VOI)
	deal.state = DealState.STATE_ACTIVE
	var run_cards: Array[CardData] = [
		_card("5", "Spades", "voi"), _card("6", "Spades", "voi"),
		_card("7", "Spades", "voi"), _card("8", "Spades", "voi"),
	]
	var run := MeldState.new(1, MeldRules.TYPE_RUN, run_cards)
	run.scored_points = ScoringPipeline.meld_value(run_cards)
	deal.melds.append(run)
	deal.hand.append(_card("K", "Hearts", "discard"))
	assert_false(deal.can_use_nuoc_voi(1, run_cards[1]))
	assert_true(deal.can_use_nuoc_voi(1, run_cards[0]))
	assert_true(deal.current_drink_has_charge())
	var cue := deal.drink_cue_trigger()
	assert_true(cue["active"])
	assert_eq(cue["trigger_id"], "removable_meld_card")
	assert_eq(cue["targets"].size(), 2)
	var banked_score := run.scored_points
	assert_true(deal.use_nuoc_voi(1, run_cards[-1])["ok"])
	assert_eq(run.cards.size(), 3)
	assert_eq(run.scored_points, banked_score)
	assert_true(deal.hand.has(run_cards[-1]))
	assert_true(deal.recyclable_spent_cards.is_empty())
	assert_false(deal.current_drink_has_charge())
	assert_false(deal.drink_cue_trigger()["active"])
	assert_false(deal.use_nuoc_voi(1, run_cards[0])["ok"])
	deal.current_phase = 2
	assert_true(deal.current_drink_has_charge())
	deal.current_phase = 1
	var extension := deal.extend_meld(1, [run_cards[-1]] as Array[CardData])
	assert_true(extension["ok"])
	assert_eq(extension["context"].old_meld_score, 54)
	assert_eq(extension["context"].theoretical_score, 104)
	assert_eq(extension["context"].final_points, 50)
	assert_eq(run.scored_points, banked_score)

	var set_deal := DealState.new()
	set_deal.set_current_drink(DrinkCatalog.NUOC_VOI)
	set_deal.state = DealState.STATE_ACTIVE
	var set_cards: Array[CardData] = [
		_card("7", "Spades", "voi_set"), _card("7", "Hearts", "voi_set"),
		_card("7", "Diamonds", "voi_set"), _card("7", "Clubs", "voi_set"),
	]
	set_deal.melds.append(MeldState.new(2, MeldRules.TYPE_SET, set_cards))
	assert_true(set_deal.can_use_nuoc_voi(2, set_cards[1]))


func test_sam_dua_preserves_up_to_three_selected_loose_cards_only_on_dump() -> void:
	var deal := _fresh_deal(223, DrinkCatalog.SAM_DUA)
	_advance_to_last_call(deal)
	var cue := deal.drink_cue_trigger()
	assert_true(cue["active"])
	assert_eq(cue["trigger_id"], "phase_one_redraw_preserve")
	assert_true(deal.settle_phase()["ok"])
	var original_hand := deal.hand.duplicate()
	var chosen: Array[CardData] = [deal.hand[0], deal.hand[1], deal.hand[2]]
	assert_false(deal.select_sam_dua_preserves([deal.hand[0], deal.hand[1], deal.hand[2], deal.hand[3]] as Array[CardData])["ok"])
	assert_true(deal.select_sam_dua_preserves(chosen)["ok"])
	assert_false(deal.current_drink_has_charge())
	assert_false(deal.drink_cue_trigger()["active"])
	assert_false(deal.select_sam_dua_preserves(chosen)["ok"])
	var result := deal.choose_phase_two(false)
	assert_true(result["ok"])
	assert_eq(result["preserved"], chosen)
	assert_eq(result["dumped"].size(), original_hand.size() - chosen.size())
	assert_eq(deal.hand.size(), DealState.ACTIVE_HAND_TARGET)
	for card in chosen:
		assert_true(deal.hand.has(card))
		assert_false(deal.recyclable_spent_cards.has(card))
	for card in result["dumped"]:
		assert_false(deal.hand.has(card))
		assert_true(deal.recyclable_spent_cards.has(card))
	assert_true(deal.physical_card_accounting_is_valid())


func test_sam_dua_does_not_change_mom_deadwood() -> void:
	var deal := _fresh_deal(22, DrinkCatalog.SAM_DUA)
	_advance_to_last_call(deal)
	deal.wallet.reset()
	deal.hand.clear()
	deal.hand.append_array([_card("A", "Spades"), _card("4", "Hearts"), _card("K", "Clubs")])
	var resolution: Dictionary = deal.settle_phase()["phase_resolution"]
	assert_true(resolution["mom"])
	assert_eq(resolution["deadwood_value_sum"], 18)
	assert_eq(resolution["deadwood_multiplier"], 3)
	assert_eq(resolution["deadwood"], 54)
	assert_eq(deal.wallet.balance_vnd, VndWallet.points_to_vnd(-54))


func test_advanced_drink_taxonomy_exists_without_invented_effects() -> void:
	assert_eq(DrinkCatalog.category(DrinkCatalog.DEN_DA), DrinkCatalog.CATEGORY_CAFFEINE)
	assert_eq(DrinkCatalog.category(DrinkCatalog.BO_HUC), DrinkCatalog.CATEGORY_ENERGY)
	assert_eq(DrinkCatalog.category(DrinkCatalog.MIA_TAC), DrinkCatalog.CATEGORY_SUGAR)
	assert_false(DrinkCatalog.is_effect_implemented(DrinkCatalog.BO_HUC))


func test_deadwood_resolution_hook_can_modify_the_controlled_pipeline() -> void:
	var deal := _fresh_deal(23)
	_advance_to_last_call(deal)
	deal.hand.clear()
	deal.hand.append(_card("K", "Spades"))
	deal.deadwood_calculated.connect(func(context: Dictionary) -> void: context["deadwood"] = 0)
	var resolution: Dictionary = deal.settle_phase()["phase_resolution"]
	assert_eq(resolution["deadwood"], 0)


func test_hand_advisor_preserves_discard_normally_but_not_in_last_call() -> void:
	var hand: Array[CardData] = [_card("5", "Spades"), _card("5", "Hearts"), _card("5", "Diamonds")]
	assert_eq(HandAdvisor.recommend(hand, [] as Array[MeldState])["action"], HandAdvisor.ACTION_NONE)
	assert_eq(HandAdvisor.recommend(hand, [] as Array[MeldState], null, 1, 0, false)["action"], HandAdvisor.ACTION_NEW_MELD)


func test_legal_action_card_ids_distinguish_new_melds_extensions_and_both() -> void:
	var deal := DealState.new()
	var six_spades := _card("6", "Spades", "both")
	var six_hearts := _card("6", "Hearts", "meld")
	var six_diamonds := _card("6", "Diamonds", "meld")
	var discard := _card("K", "Clubs", "discard")
	deal.hand = [six_spades, six_hearts, six_diamonds, discard]
	deal.melds = [MeldState.new(1, MeldRules.TYPE_RUN, [
		_card("3", "Spades", "table"), _card("4", "Spades", "table"), _card("5", "Spades", "table"),
	] as Array[CardData])]
	deal.state = DealState.STATE_ACTIVE
	var actionable := deal.legal_action_card_ids()
	assert_true(actionable["meld"].has(six_spades.unique_id))
	assert_true(actionable["extend"].has(six_spades.unique_id))
	assert_true(actionable["meld"].has(six_hearts.unique_id))
	assert_false(actionable["extend"].has(six_hearts.unique_id))
	assert_false(actionable["meld"].has(discard.unique_id))
	assert_false(actionable["extend"].has(discard.unique_id))


func test_legal_action_targets_require_and_follow_the_current_selection() -> void:
	var deal := DealState.new()
	var six_spades := _card("6", "Spades", "both")
	var six_hearts := _card("6", "Hearts", "meld")
	var six_diamonds := _card("6", "Diamonds", "meld")
	var discard := _card("K", "Clubs", "discard")
	deal.hand = [six_spades, six_hearts, six_diamonds, discard]
	deal.melds = [MeldState.new(1, MeldRules.TYPE_RUN, [
		_card("3", "Spades", "table"), _card("4", "Spades", "table"), _card("5", "Spades", "table"),
	] as Array[CardData])]
	deal.state = DealState.STATE_ACTIVE
	var idle_targets := deal.legal_action_targets_for_selection([] as Array[CardData])
	assert_true(idle_targets["hand"].is_empty())
	assert_true(idle_targets["melds"].is_empty())
	var meld_targets := deal.legal_action_targets_for_selection([six_hearts] as Array[CardData])
	assert_eq(meld_targets["hand"].size(), 3)
	assert_true(meld_targets["hand"].has(six_spades.unique_id))
	assert_true(meld_targets["hand"].has(six_hearts.unique_id))
	assert_true(meld_targets["hand"].has(six_diamonds.unique_id))
	assert_true(meld_targets["melds"].is_empty())
	var table_targets := deal.legal_action_targets_for_selection([] as Array[CardData], 1)
	assert_eq(table_targets["hand"].size(), 1)
	assert_true(table_targets["hand"].has(six_spades.unique_id))
	var extension_targets := deal.legal_action_targets_for_selection([six_spades] as Array[CardData])
	assert_true(extension_targets["melds"].has(1))


func test_card_drag_payload_preserves_its_source_for_future_table_card_verbs() -> void:
	var card := _card("8", "Clubs", "drag")
	var payload = CARD_DRAG_PAYLOAD_SCRIPT.new(
		CARD_DRAG_PAYLOAD_SCRIPT.SOURCE_TABLE_MELD,
		12,
		card.unique_id,
		[card] as Array[CardData]
	)
	assert_eq(payload.source_zone, CARD_DRAG_PAYLOAD_SCRIPT.SOURCE_TABLE_MELD)
	assert_eq(payload.source_meld_id, 12)
	assert_eq(payload.anchor_card(), card)


func test_meld_probability_reports_exact_set_outs_for_the_next_refill() -> void:
	var hand: Array[CardData] = [_card("7", "Spades"), _card("7", "Hearts")]
	var draw_pile: Array[CardData] = [
		_card("7", "Diamonds"), _card("7", "Clubs"), _card("A", "Spades"), _card("K", "Hearts"),
	]
	var analysis := MeldProbabilityAdvisor.analyze(hand, draw_pile, [] as Array[MeldState], 1)
	var candidate := _candidate_named(analysis["candidates"], "BỘ 7")
	assert_false(candidate.is_empty())
	assert_eq(candidate["outs"], 2)
	assert_true(absf(float(candidate["probability"]) - 0.5) < 0.00001)


func test_meld_probability_distinguishes_each_run_window() -> void:
	var hand: Array[CardData] = [_card("7", "Spades"), _card("8", "Spades")]
	var draw_pile: Array[CardData] = [
		_card("9", "Spades"), _card("9", "Hearts"), _card("K", "Clubs"), _card("A", "Diamonds"),
	]
	var analysis := MeldProbabilityAdvisor.analyze(hand, draw_pile, [] as Array[MeldState], 1)
	var candidate := _candidate_named(analysis["candidates"], "SẢNH 7–9♠")
	assert_false(candidate.is_empty())
	assert_eq(candidate["needed_labels"], ["9♠"])
	assert_true(absf(float(candidate["probability"]) - 0.25) < 0.00001)


func test_meld_probability_handles_two_distinct_missing_run_cards_without_replacement() -> void:
	var hand: Array[CardData] = [_card("7", "Spades")]
	var draw_pile: Array[CardData] = [
		_card("8", "Spades"), _card("9", "Spades"), _card("K", "Clubs"), _card("A", "Diamonds"),
	]
	var analysis := MeldProbabilityAdvisor.analyze(hand, draw_pile, [] as Array[MeldState], 2)
	var candidate := _candidate_named(analysis["candidates"], "SẢNH 7–9♠")
	assert_true(absf(float(candidate["probability"]) - (1.0 / 6.0)) < 0.00001)


func test_meld_probability_includes_table_extension_outs() -> void:
	var table_cards: Array[CardData] = [_card("7", "Spades"), _card("7", "Hearts"), _card("7", "Diamonds")]
	var meld := MeldState.new(4, MeldRules.TYPE_SET, table_cards)
	var draw_pile: Array[CardData] = [
		_card("7", "Clubs"), _card("9", "Hearts"), _card("K", "Clubs"), _card("A", "Diamonds"),
	]
	var analysis := MeldProbabilityAdvisor.analyze([] as Array[CardData], draw_pile, [meld] as Array[MeldState], 1)
	var candidate := _candidate_named(analysis["candidates"], "GHÉP #04  BỘ 7")
	assert_eq(candidate["meld_id"], 4)
	assert_eq(candidate["outs"], 1)
	assert_true(absf(float(candidate["probability"]) - 0.25) < 0.00001)


func test_meld_probability_marks_an_extension_ready_when_card_is_already_held() -> void:
	var table_cards: Array[CardData] = [_card("6", "Spades"), _card("7", "Spades"), _card("8", "Spades")]
	var meld := MeldState.new(9, MeldRules.TYPE_RUN, table_cards)
	var held_extension := _card("9", "Spades", "held_extension")
	var analysis := MeldProbabilityAdvisor.analyze(
		[held_extension] as Array[CardData],
		[_card("A", "Diamonds")] as Array[CardData],
		[meld] as Array[MeldState],
		1
	)
	var candidate := _candidate_named(analysis["candidates"], "GHÉP #09  9♠")
	assert_true(candidate["ready"])
	assert_eq(candidate["owned_cards"], [held_extension])
	assert_eq(candidate["probability"], 1.0)


func test_best_meld_chance_is_aggregated_per_loose_card() -> void:
	var seven_spades := _card("7", "Spades")
	var seven_hearts := _card("7", "Hearts")
	var hand: Array[CardData] = [seven_spades, seven_hearts, _card("A", "Clubs")]
	var draw_pile: Array[CardData] = [
		_card("7", "Diamonds"), _card("7", "Clubs"), _card("K", "Clubs"), _card("2", "Diamonds"),
	]
	var by_card := MeldProbabilityAdvisor.best_new_meld_chance_by_card(hand, draw_pile, 1)
	assert_eq(by_card[seven_spades.unique_id]["label"], "BỘ 7")
	assert_eq(by_card[seven_hearts.unique_id]["label"], "BỘ 7")
	assert_true(absf(float(by_card[seven_spades.unique_id]["probability"]) - 0.5) < 0.00001)


func test_meld_probability_labels_follow_the_active_locale() -> void:
	var original_locale := TranslationServer.get_locale()
	TranslationServer.set_locale("en")
	var hand: Array[CardData] = [_card("7", "Spades"), _card("7", "Hearts")]
	var draw_pile: Array[CardData] = [_card("7", "Diamonds"), _card("7", "Clubs")]
	var by_card := MeldProbabilityAdvisor.best_new_meld_chance_by_card(hand, draw_pile, 1)
	var candidate: Dictionary = by_card[hand[0].unique_id]
	assert_eq(candidate["label"], "BỘ 7")
	var translated_template := String(TranslationServer.translate(candidate["label_key"]))
	if translated_template == candidate["label_key"]:
		# The editor process resolves its own translation catalog before the
		# project's. Verify the imported project catalog directly in that host.
		var english_translation := ResourceLoader.load("res://locale/ui.en.translation", "Translation") as Translation
		assert_true(english_translation != null)
		if english_translation != null:
			translated_template = String(english_translation.get_message(candidate["label_key"]))
	else:
		assert_eq(MeldProbabilityAdvisor.localized_label(candidate), "SET 7")
	assert_eq(translated_template % candidate["label_args"], "SET 7")
	TranslationServer.set_locale(original_locale)


func test_vnd_per_point_converts_positive_and_negative_point_changes() -> void:
	var wallet := VndWallet.new()
	wallet.vnd_per_point = 2500
	wallet.apply_points(4, "test_gain")
	assert_eq(wallet.balance_vnd, 10000)
	wallet.apply_points(-3, "test_loss")
	assert_eq(wallet.balance_vnd, 2500)


func test_point_to_vnd_conversion_uses_integer_thousands_by_default() -> void:
	assert_eq(VndWallet.points_to_vnd(63), 63000)
	assert_eq(VndWallet.format_vnd(1234567890), "₫1.234.567.890")


func _controlled_deal(stock_count: int, spent_count: int, seed: int) -> DealState:
	var deal := _fresh_deal(seed)
	var all_cards: Array[CardData] = []
	all_cards.append_array(deal.hand)
	all_cards.append_array(deal.deck.draw_pile)
	deal.hand.clear()
	deal.deck.draw_pile.clear()
	deal.deck.discard_pile.clear()
	deal.recyclable_spent_cards.clear()
	deal.melds.clear()
	deal.discard_history.clear()
	deal.current_phase = 1
	deal.discard_count = 0
	deal.state = DealState.STATE_ACTIVE
	deal.phase_metrics.reset()
	deal._turn_started_with_ten = false
	deal._turn_committed_card_count = 0
	deal.hand.append_array(all_cards.slice(0, DealState.ACTIVE_HAND_TARGET))
	var cursor := DealState.ACTIVE_HAND_TARGET
	deal.deck.draw_pile.append_array(all_cards.slice(cursor, cursor + stock_count))
	cursor += stock_count
	deal.recyclable_spent_cards.append_array(all_cards.slice(cursor, cursor + spent_count))
	cursor += spent_count
	deal.deck.discard_pile.append_array(all_cards.slice(cursor))
	return deal


func _fresh_deal(seed: int, drink_id: String = DrinkCatalog.NONE) -> DealState:
	var deal := DealState.new()
	deal.set_current_drink(drink_id)
	deal.start_deal(seed, true)
	return deal


func _advance_to_last_call(deal: DealState) -> Dictionary:
	var result: Dictionary = {}
	while deal.discard_count < DealState.DISCARDS_PER_PHASE:
		result = deal.discard_card(deal.hand[0])
	return result


func _u_khan_hand() -> Array[CardData]:
	return [
		_card("A", "Spades", "uk1"), _card("4", "Spades", "uk2"), _card("7", "Spades", "uk3"),
		_card("10", "Spades", "uk4"), _card("K", "Spades", "uk5"), _card("2", "Hearts", "uk6"),
		_card("5", "Hearts", "uk7"), _card("8", "Hearts", "uk8"), _card("J", "Hearts", "uk9"),
		_card("Q", "Clubs", "uk10"),
	]


func _card(rank: String, suit: String, suffix: String = "") -> CardData:
	var rank_index := DeckManager.RANKS.find(rank) + 1
	return CardData.new("test_%s_%s_%s" % [rank, suit, suffix], rank, rank_index, suit, rank_index)


func _kings(card_count: int) -> Array[CardData]:
	var cards: Array[CardData] = []
	var suits := ["Spades", "Hearts", "Diamonds", "Clubs"]
	for index in range(card_count):
		cards.append(_card("K", suits[index % suits.size()], "copy_%d" % index))
	return cards


func _new_music_detector():
	var detector_script := GDScript.new()
	var source_code := FileAccess.get_file_as_string(MUSIC_BEAT_DETECTOR_PATH)
	source_code = source_code.replace("class_name MusicBeatDetector\r\n", "")
	source_code = source_code.replace("class_name MusicBeatDetector\n", "")
	detector_script.source_code = source_code
	var reload_error: Error = detector_script.reload()
	assert_eq(reload_error, OK, "music detector script reloads from disk")
	return detector_script.new()


func _ids(cards: Array[CardData]) -> Dictionary:
	var ids := {}
	for card in cards:
		ids[card.unique_id] = true
	return ids


func _candidate_named(candidates: Array, label: String) -> Dictionary:
	for candidate_value in candidates:
		var candidate: Dictionary = candidate_value
		if candidate["label"] == label:
			return candidate
	return {}


func _hand_has_id(hand: Array[CardData], unique_id: String) -> bool:
	for card in hand:
		if card.unique_id == unique_id:
			return true
	return false
