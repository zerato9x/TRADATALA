@tool
extends McpTestSuite

var _serial: int = 0

func suite_name() -> String:
	return "drink_roster"

func _card(rank: int, suit: String = "Spades") -> CardData:
	_serial += 1
	var label := str(rank)
	if rank == 1: label = "A"
	if rank == 11: label = "J"
	if rank == 12: label = "Q"
	if rank == 13: label = "K"
	return CardData.new("roster_%d" % _serial, label, rank, suit, rank)

func _deal(id: String) -> DealState:
	var deal := DealState.new()
	deal.deck.reset(19)
	deal.set_current_drink(id)
	deal.state = DealState.STATE_FINAL_COMMIT_WINDOW
	return deal

func test_all_twelve_metadata_and_both_test_shops() -> void:
	var ids := DrinkCatalog.all_ids()
	assert_eq(ids.size(), 12)
	var tiers := [0, 1, 1, 1, 2, 2, 2, 2, 3, 2, 3, 3]
	for index in range(ids.size()):
		var definition: Dictionary = DrinkCatalog.DEFINITIONS[ids[index]]
		assert_eq(definition["tier"], tiers[index])
		assert_true(definition.has("category") and definition.has("charge_scope") and definition.has("targeting_mode"))
		assert_true(DrinkCatalog.is_effect_implemented(ids[index]))
		for slot in [EventManager.EventSlot.STARTER, EventManager.EventSlot.NOON]:
			var manager := DrinkManager.new()
			manager.test_all_drinks_available = true
			assert_eq(manager.available_drink_ids().size(), 12)
			assert_true(manager.select_for_event(slot, ids[index])["ok"])
			assert_eq(manager.active_drink_id, ids[index])
			assert_eq(manager.price_for(ids[index]), DrinkManager.TEST_PRICE_VND)
	var manager := DrinkManager.new()
	manager.test_all_drinks_available = true
	manager.select_for_event(EventManager.EventSlot.STARTER, DrinkCatalog.C2_ICED_TEA)
	manager.select_for_event(EventManager.EventSlot.NOON, DrinkCatalog.BO_HUC)
	assert_eq(manager.active_drink_id, DrinkCatalog.BO_HUC)
	manager.test_all_drinks_available = false
	assert_eq(manager.available_drink_ids(), DrinkCatalog.all_ids())

func test_nhan_tran_turn_reset_and_last_call_do_not_grant_bonus_charge() -> void:
	var deal := DealState.new()
	deal.set_current_drink(DrinkCatalog.NHAN_TRAN)
	deal.start_deal(901)
	deal.discard_card(deal.hand[0])
	assert_true(deal.use_nhan_tran(deal.hand[0], deal.latest_mandatory_discard())["ok"])
	assert_false(deal.current_drink_has_charge())
	deal.discard_card(deal.hand[0])
	assert_true(deal.current_drink_has_charge())
	deal.discard_card(deal.hand[0])
	deal.use_nhan_tran(deal.hand[0], deal.latest_mandatory_discard())
	deal.discard_card(deal.hand[0])
	assert_eq(deal.state, DealState.STATE_FINAL_COMMIT_WINDOW)
	assert_false(deal.current_drink_has_charge())
	assert_true(deal.physical_card_accounting_is_valid())

func test_nhan_tran_rejects_extra_dump_and_stale_records() -> void:
	var deal := _deal(DrinkCatalog.NHAN_TRAN)
	deal.hand = [_card(2)]
	for kind in [DiscardRecord.KIND_DRINK_EXTRA, DiscardRecord.KIND_DUMP, DiscardRecord.KIND_MANDATORY]:
		var discarded := _card(5)
		var record := DiscardRecord.new(discarded, 1, 1, kind)
		deal.discard_history.append(record)
		if kind != DiscardRecord.KIND_MANDATORY: deal.deck.discard_pile.append(discarded)
		assert_false(deal.can_use_nhan_tran(deal.hand[0], record))

func test_den_da_swaps_all_live_discard_kinds_and_never_history_only() -> void:
	for kind in [DiscardRecord.KIND_MANDATORY, DiscardRecord.KIND_DRINK_EXTRA, DiscardRecord.KIND_DUMP]:
		var deal := DealState.new()
		deal.start_deal(903)
		deal.set_current_drink(DrinkCatalog.DEN_DA)
		var target := deal.hand.pop_back() as CardData
		if kind == DiscardRecord.KIND_DUMP: deal.move_to_recyclable_spent([target])
		else: deal.deck.discard(target)
		var record := DiscardRecord.new(target, 1, 1, kind)
		deal.discard_history.append(record)
		deal.current_phase = 2
		var outgoing := deal.hand[0]
		assert_true(deal.use_den_da(outgoing, record)["ok"])
		assert_eq(record.card, outgoing)
		assert_true(deal.hand.has(target))
		assert_true(deal.physical_card_accounting_is_valid())
		assert_false(deal.use_den_da(deal.hand[0], record)["ok"])
		deal.discard_card(deal.hand[0])
		assert_true(deal.current_drink_has_charge())
		deal.state = DealState.STATE_FINAL_COMMIT_WINDOW
		assert_true(deal.use_den_da(deal.hand[0], record)["ok"])
		assert_false(deal.current_drink_has_charge())
		deal.den_da_used_this_turn = false
		deal.deck.discard_pile.erase(record.card)
		deal.recyclable_spent_cards.erase(record.card)
		deal.deck.draw_pile.append(record.card)
		assert_false(deal.can_use_den_da(deal.hand[0], record))
		assert_true(deal.physical_card_accounting_is_valid())

func test_nau_da_returns_whole_meld_and_scores_same_cards_again() -> void:
	var deal := _deal(DrinkCatalog.NAU_DA)
	var cards: Array[CardData] = [_card(8), _card(8, "Hearts"), _card(8, "Clubs")]
	deal.hand = cards.duplicate()
	assert_true(deal.create_meld(cards)["ok"])
	var gross := deal.phase_metrics.raw_gross
	var wallet := deal.wallet.balance_vnd
	var id := deal.melds[0].meld_id
	assert_true(deal.use_nau_da(id)["ok"])
	assert_eq(deal.melds.size(), 0)
	assert_eq(deal.hand.size(), cards.size())
	for card in cards: assert_true(deal.hand.has(card))
	assert_eq(deal.wallet.balance_vnd, wallet)
	assert_true(deal.create_meld(cards)["ok"])
	assert_eq(deal.phase_metrics.raw_gross, gross * 2)
	assert_false(deal.use_nau_da(deal.melds[0].meld_id)["ok"])
	deal.current_phase = 2
	assert_true(deal.use_nau_da(deal.melds[0].meld_id)["ok"])

func test_preservation_zero_one_three_five_and_all_settle_before_refill() -> void:
	for count in [0, 1, 3, 5, 9]:
		var deal := DealState.new()
		deal.set_current_drink(DrinkCatalog.BAC_XIU)
		deal.start_deal(906)
		while deal.state == DealState.STATE_ACTIVE: deal.discard_card(deal.hand[0])
		var chosen: Array[CardData] = []
		chosen.assign(deal.hand.slice(0, count))
		var sum := deal.deadwood_points()
		var size_before := deal.hand.size()
		assert_true(deal.select_sam_dua_preserves(chosen)["ok"])
		var result := deal.settle_phase()
		assert_eq(result["phase_resolution"]["deadwood_value_sum"], sum)
		assert_eq(result["phase_resolution"]["deadwood_multiplier"], size_before)
		var transition := deal.choose_phase_two(false)
		assert_eq(transition["preserved"].size(), count)
		assert_eq(transition["dumped"].size(), size_before - count)
		assert_eq(deal.hand.size(), 10)
		for card in chosen: assert_true(deal.hand.has(card))
		assert_true(deal.physical_card_accounting_is_valid())
	var sam := _deal(DrinkCatalog.SAM_DUA)
	sam.hand = [_card(2), _card(3), _card(4), _card(5)]
	assert_false(sam.select_sam_dua_preserves(sam.hand)["ok"])
	assert_true(sam.select_sam_dua_preserves([sam.hand[0], sam.hand[1], sam.hand[2]])["ok"])

func test_normal_transition_requires_dump_and_only_preservation_drinks_may_keep() -> void:
	for id in DrinkCatalog.all_ids():
		var deal := _deal(id)
		deal.hand = [_card(4), _card(5)]
		deal.settle_phase()
		if deal.has_phase_transition_choice():
			assert_true(deal.choose_phase_two(true)["ok"])
		else:
			var old_hand: Array[CardData] = deal.hand.duplicate()
			assert_false(deal.choose_phase_two(true)["ok"])
			var result := deal.choose_phase_two(false)
			assert_true(result["ok"])
			assert_eq(result["dumped"].size(), old_hand.size())

func test_sting_pair_is_explicit_new_phom_with_normal_extension() -> void:
	var deal := _deal(DrinkCatalog.STING)
	var pair: Array[CardData] = [_card(7), _card(7, "Hearts")]
	deal.hand = pair.duplicate()
	assert_false(deal.can_create_meld(pair))
	assert_false(MeldRules.is_set(pair))
	assert_true(deal.create_meld(pair, true)["ok"])
	assert_eq(deal.phase_metrics.new_phom_count, 1)
	assert_true(deal.melds[0].pair_created)
	var extra := _card(7, "Clubs")
	deal.hand.append(extra)
	assert_true(deal.extend_meld(deal.melds[0].meld_id, [extra])["ok"])
	assert_eq(deal.melds[0].cards.size(), 3)
	var second: Array[CardData] = [_card(9), _card(9, "Hearts")]
	deal.hand = second.duplicate()
	assert_false(deal.create_meld(second, true)["ok"])
	assert_false(deal.settle_phase()["phase_resolution"]["mom"])
	deal.choose_phase_two(false)
	deal.state = DealState.STATE_FINAL_COMMIT_WINDOW
	second = [_card(10), _card(10, "Hearts")]
	deal.hand.append_array(second)
	assert_true(deal.create_meld(second, true)["ok"])

func test_bo_huc_resets_normal_turn_but_not_last_call() -> void:
	var deal := _deal(DrinkCatalog.BO_HUC)
	deal.hand = [_card(6), _card(6, "Hearts"), _card(8), _card(8, "Hearts"), _card(3)]
	deal.state = DealState.STATE_ACTIVE
	assert_true(deal.create_meld([deal.hand[0], deal.hand[1]], true)["ok"])
	assert_false(deal.can_create_meld([deal.hand[0], deal.hand[1]], true))
	deal.discard_card(deal.hand[-1])
	assert_true(deal.can_create_meld([deal.hand[0], deal.hand[1]], true))
	assert_true(deal.create_meld([deal.hand[0], deal.hand[1]], true)["ok"])
	deal.discard_count = 3
	deal.hand.append(_card(2))
	deal.discard_card(deal.hand[-1])
	assert_eq(deal.state, DealState.STATE_FINAL_COMMIT_WINDOW)
	assert_false(deal.current_drink_has_charge())

func test_c2_persistent_run_marker_and_one_creation_per_deal() -> void:
	var deal := _deal(DrinkCatalog.C2_ICED_TEA)
	var cards: Array[CardData] = [_card(5), _card(6, "Hearts"), _card(7, "Clubs")]
	deal.hand = cards.duplicate()
	assert_false(deal.can_create_meld(cards))
	assert_true(deal.create_meld(cards, true)["ok"])
	assert_eq(deal.melds[0].run_compatibility, "any")
	var extra := _card(8, "Diamonds")
	deal.hand.append(extra)
	assert_true(deal.extend_meld(deal.melds[0].meld_id, [extra])["ok"])
	deal.hand = [_card(9), _card(10, "Hearts"), _card(11, "Clubs")]
	assert_false(deal.create_meld(deal.hand.duplicate(), true)["ok"])
	deal.set_current_drink(DrinkCatalog.NONE)
	extra = _card(4, "Hearts")
	deal.hand.append(extra)
	assert_true(deal.extend_meld(deal.melds[0].meld_id, [extra])["ok"])

func test_sugar_colors_extend_ordinary_and_marked_runs_only_with_valid_ranks() -> void:
	for id in [DrinkCatalog.MIA_TAC, DrinkCatalog.MIA_SAU_RIENG]:
		var red: bool = id == DrinkCatalog.MIA_TAC
		var first := "Hearts" if red else "Spades"
		var second := "Diamonds" if red else "Clubs"
		var wrong := "Spades" if red else "Hearts"
		var deal := _deal(id)
		deal.hand = [_card(5, first), _card(6, second), _card(7, first)]
		assert_true(deal.create_meld(deal.hand.duplicate())["ok"])
		var meld := deal.melds[0]
		assert_eq(meld.run_compatibility, "red" if red else "black")
		var endpoint := _card(8, second)
		deal.hand.append(endpoint)
		assert_true(deal.extend_meld(meld.meld_id, [endpoint])["ok"])
		var invalid := _card(9, wrong)
		deal.hand.append(invalid)
		assert_false(deal.can_extend_meld(meld.meld_id, [invalid]))
		deal.hand = [_card(2, wrong), _card(3, wrong), _card(4, wrong)]
		assert_true(deal.create_meld(deal.hand.duplicate())["ok"])
		deal.hand = [_card(9, first), _card(10, first), _card(11, first)]
		assert_true(deal.create_meld(deal.hand.duplicate())["ok"])
		endpoint = _card(12, second)
		deal.hand.append(endpoint)
		assert_true(deal.extend_meld(deal.melds[-1].meld_id, [endpoint])["ok"])

func test_special_runs_reject_duplicates_gaps_wrap_and_accept_ace_low() -> void:
	for compatibility in ["any", "red", "black"]:
		var suit := "Spades" if compatibility == "black" else "Hearts"
		assert_false(MeldRules.is_compatible_run([_card(12, suit), _card(13, suit), _card(1, suit)], compatibility))
		assert_false(MeldRules.is_compatible_run([_card(5, suit), _card(5, suit), _card(6, suit)], compatibility))
		assert_false(MeldRules.is_compatible_run([_card(5, suit), _card(7, suit), _card(8, suit)], compatibility))
		assert_true(MeldRules.is_compatible_run([_card(1, suit), _card(2, suit), _card(3, suit)], compatibility))

func test_mutated_same_face_distinct_ids_pair_legal_duplicate_id_rejected() -> void:
	var deal := _deal(DrinkCatalog.STING)
	var left := _card(4)
	var right := _card(9, "Hearts")
	right.apply_rank("4", 4)
	right.apply_suit("Spades")
	deal.hand = [left, right]
	assert_false(deal.can_create_meld([left, left], true))
	assert_true(deal.create_meld([left, right], true)["ok"])
	assert_eq(deal.phase_metrics.raw_gross, ScoringPipeline.new().score_new_meld([left, right], MeldRules.TYPE_SET, 1, 0).final_points)
	assert_eq(deal.melds[0].cards.size(), 2)

func test_all_drinks_keep_ordinary_scoring_without_drink_multiplier() -> void:
	for id in DrinkCatalog.all_ids():
		var deal := _deal(id)
		var cards: Array[CardData] = [_card(3), _card(4), _card(5)]
		deal.hand = cards.duplicate()
		var expected := ScoringPipeline.new().preview_new_meld(cards, MeldRules.TYPE_RUN, 1, 0).final_points
		assert_true(deal.create_meld(cards)["ok"])
		assert_eq(deal.phase_metrics.raw_gross, expected)

func test_pair_uses_existing_gieo_making_phom_and_set_hooks() -> void:
	var deal := _deal(DrinkCatalog.STING)
	var cards: Array[CardData] = [_card(9), _card(9, "Hearts")]
	cards[0].add_gieo_property(GieoQueService.PROPERTY_GOLD_MAKING_PHOM)
	cards[1].add_gieo_property(GieoQueService.PROPERTY_MELD_RETRIGGER)
	deal.hand = cards.duplicate()
	var expected := ScoringPipeline.new().preview_new_meld(cards, MeldRules.TYPE_SET, 1, 0)
	var result := deal.create_meld(cards, true)
	assert_true(result["ok"])
	assert_eq(result["context"].scoring_passes.size(), expected.scoring_passes.size())
	assert_eq(result["context"].final_points, expected.final_points)
	assert_true(expected.scoring_passes.size() > 1)

func test_nau_da_large_hand_has_no_refill_or_exponential_target_search() -> void:
	var deal := _deal(DrinkCatalog.NAU_DA)
	var table_cards: Array[CardData] = []
	for index in range(13): table_cards.append(_card(8))
	deal.melds.append(MeldState.new(1, MeldRules.TYPE_SET, table_cards))
	for index in range(9): deal.hand.append(_card(5))
	assert_true(deal.use_nau_da(1)["ok"])
	assert_eq(deal.hand.size(), 22)
	var stock := deal.deck.draw_pile.size()
	deal.state = DealState.STATE_ACTIVE
	deal.discard_card(deal.hand[0])
	assert_eq(deal.deck.draw_pile.size(), stock)
	assert_eq(deal.hand.size(), 21)
	assert_true(deal._hand_card_combinations().size() < 2000)
	assert_false(deal.legal_action_card_ids()["meld"].is_empty())
	assert_eq(deal.recommend_action()["action"], HandAdvisor.ACTION_NEW_MELD)

func test_c2_large_hand_targets_complete_selected_endpoints() -> void:
	var deal := _deal(DrinkCatalog.C2_ICED_TEA)
	for rank in range(1, 14):
		deal.hand.append(_card(rank, "Hearts" if rank % 2 else "Spades"))
	var ends: Array[CardData] = [deal.hand[2], deal.hand[8]]
	var ids := deal.drink_creation_target_ids(ends)
	assert_eq(ids.size(), 13)
	deal.hand.remove_at(5)
	assert_true(deal.drink_creation_target_ids(ends).is_empty())


func test_pair_targets_only_complete_selected_rank_and_respect_last_card() -> void:
	var deal := _deal(DrinkCatalog.STING)
	deal.hand = [_card(8), _card(8, "Hearts"), _card(3)]
	assert_eq(deal.drink_creation_target_ids([deal.hand[0]]).size(), 2)
	assert_true(deal.drink_creation_target_ids([deal.hand[2]]).is_empty())
	deal.state = DealState.STATE_ACTIVE
	deal.hand.remove_at(2)
	assert_true(deal.drink_creation_target_ids([]).is_empty())
	deal.state = DealState.STATE_FINAL_COMMIT_WINDOW
	assert_eq(deal.drink_creation_target_ids([]).size(), 2)


func test_action_vocabulary_colors_verbs_without_partial_word_matches() -> void:
	var text := ActionVocabulary.colorize("HẠ rồi DUMP; KEEP. Keeping the drawing room tidy.")
	assert_true(text.contains("[color=#8cdd98]HẠ[/color]"))
	assert_true(text.contains("[color=#ffaaa0]DUMP[/color]"))
	assert_true(text.contains("[color=#8fe7ff]KEEP[/color]"))
	assert_true(text.contains("Keeping"))
	assert_true(ActionVocabulary.colorize("giữ và hạ").contains("[color=#8fe7ff]giữ[/color]"))
	assert_eq(ActionVocabulary.ENTRIES.size(), 11)
