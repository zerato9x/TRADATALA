@tool
extends McpTestSuite

const MUSIC_BEAT_DETECTOR_PATH := "res://scripts/audio/music_beat_detector.gd"


func suite_name() -> String:
	return "core_deal"


func suite_setup(_ctx: Dictionary) -> void:
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
	var cards: Array[CardData] = [
		_card("K", "Spades", "a"), _card("K", "Hearts", "b"),
		_card("K", "Diamonds", "c"), _card("K", "Clubs", "d"),
		_card("K", "Spades", "future_duplicate"),
	]
	assert_eq(MeldRules.classify(cards), MeldRules.TYPE_SET)


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


func test_phase_settlement_charges_deadwood_in_both_phases() -> void:
	var deal := _fresh_deal(14)
	_advance_to_last_call(deal)
	deal.wallet.reset()
	deal.phase_metrics.raw_gross = 40
	deal.phase_earnings_points = 40
	deal.wallet.apply_points(40, "test_gross")
	deal.hand.clear()
	deal.hand.append_array([_card("A", "Spades"), _card("4", "Hearts"), _card("K", "Clubs")])
	var result := deal.settle_phase()
	var resolution: Dictionary = result["phase_resolution"]
	assert_eq(resolution["deadwood"], 18)
	assert_eq(resolution["net"], 22)
	assert_eq(deal.wallet.balance_vnd, VndWallet.points_to_vnd(22))


func test_mom_banks_a_strike_without_altering_in_play_money() -> void:
	var deal := _fresh_deal(15)
	_advance_to_last_call(deal)
	deal.wallet.reset()
	deal.phase_metrics.raw_gross = 57
	deal.phase_earnings_points = 57
	deal.wallet.apply_points(57, "extension_score")
	deal.hand.clear()
	var resolution: Dictionary = deal.settle_phase()["phase_resolution"]
	assert_true(resolution["mom"])
	assert_eq(deal.mom_strikes_banked, 1)
	assert_eq(deal.wallet.balance_vnd, VndWallet.points_to_vnd(57))


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
	var expected := ScoringPipeline.deadwood_points(deal.hand) * 9
	deal._begin_active_turn()
	assert_eq(deal.phase_metrics.u_khan_count, 1)
	assert_eq(deal.phase_metrics.raw_gross, expected)
	assert_eq(deal.wallet.balance_vnd, VndWallet.points_to_vnd(expected))
	assert_eq(deal.hand.size(), 10)


func test_tra_da_boosts_only_the_first_new_phom_each_phase() -> void:
	var scoring := ScoringPipeline.new()
	scoring.current_drink_id = DrinkCatalog.TRA_DA
	var cards: Array[CardData] = [_card("7", "Clubs"), _card("8", "Clubs"), _card("9", "Clubs")]
	assert_eq(scoring.preview_new_meld(cards, MeldRules.TYPE_RUN, 1, 0).local_mult, 4)
	assert_eq(scoring.preview_new_meld(cards, MeldRules.TYPE_RUN, 1, 1).local_mult, 3)


func test_nuoc_voi_scales_each_later_new_phom_with_phase_count() -> void:
	var scoring := ScoringPipeline.new()
	scoring.current_drink_id = DrinkCatalog.NUOC_VOI
	var cards: Array[CardData] = [_card("7", "Clubs"), _card("8", "Clubs"), _card("9", "Clubs")]
	assert_eq(scoring.preview_new_meld(cards, MeldRules.TYPE_RUN, 1, 0).local_mult, 3)
	assert_eq(scoring.preview_new_meld(cards, MeldRules.TYPE_RUN, 1, 2).local_mult, 5)


func test_nhan_tran_retriggers_only_added_extension_cards() -> void:
	var scoring := ScoringPipeline.new()
	scoring.current_drink_id = DrinkCatalog.NHAN_TRAN
	var all_cards: Array[CardData] = [_card("6", "Spades"), _card("7", "Spades"), _card("8", "Spades"), _card("9", "Spades")]
	var context := scoring.preview_extension(all_cards, MeldRules.TYPE_RUN, 63, 1, [all_cards[-1]])
	assert_eq(context.base_extension_score, 57)
	assert_eq(context.drink_bonus_points, 36)
	assert_eq(context.final_points, 93)


func test_sam_dua_cancels_one_banked_mom_only_at_final_resolution() -> void:
	var deal := _fresh_deal(22, DrinkCatalog.SAM_DUA)
	_advance_to_last_call(deal)
	deal.hand.clear()
	deal.settle_phase()
	assert_eq(deal.mom_strikes_banked, 1)
	assert_eq(deal.mom_strikes_resolved, 0)
	deal.choose_phase_two(true)
	_advance_to_last_call(deal)
	deal.hand.clear()
	deal.settle_phase()
	assert_eq(deal.mom_strikes_banked, 2)
	assert_eq(deal.mom_strikes_resolved, 1)


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


func test_point_to_vnd_conversion_uses_integer_thousands() -> void:
	assert_eq(VndWallet.points_to_vnd(63), 63000)
	assert_eq(VndWallet.format_vnd(1234567890), "₫1.234.567.890")


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
