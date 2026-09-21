@tool
extends McpTestSuite


func suite_name() -> String:
	return "gieo_que"


func test_exact_trigram_tables_and_duplicate_target_meanings() -> void:
	assert_eq(GieoQueService.FIRST_TRIGRAM_EFFECTS, {
		"DDD": GieoQueService.EFFECT_ADD_GOLD_SET,
		"DDA": GieoQueService.EFFECT_CHOOSE_RANK,
		"DAD": GieoQueService.EFFECT_ADD_GOLD_MAKING_PHOM,
		"DAA": GieoQueService.EFFECT_ADD_GOLD_BIG_PHOM,
		"ADD": GieoQueService.EFFECT_ADD_GOLD_LAST_CALL,
		"ADA": GieoQueService.EFFECT_ADD_GOLD_EXTEND,
		"AAD": GieoQueService.EFFECT_CHOOSE_SUIT,
		"AAA": GieoQueService.EFFECT_ADD_GOLD_RUN,
	})
	assert_eq(GieoQueService.SECOND_TRIGRAM_TARGETS, {
		"DDD": GieoQueService.TARGET_RANDOM_SAME_SUIT_3,
		"DDA": GieoQueService.TARGET_RANDOM_SAME_SUIT_2,
		"DAD": GieoQueService.TARGET_CHOOSE_ONE,
		"DAA": GieoQueService.TARGET_OFFER_THREE,
		"ADD": GieoQueService.TARGET_OFFER_THREE,
		"ADA": GieoQueService.TARGET_CHOOSE_ONE,
		"AAD": GieoQueService.TARGET_CONSECUTIVE_2,
		"AAA": GieoQueService.TARGET_CONSECUTIVE_3,
	})
	assert_eq(GieoQueService.SECOND_TRIGRAM_TARGETS["DAD"], GieoQueService.SECOND_TRIGRAM_TARGETS["ADA"])
	assert_eq(GieoQueService.SECOND_TRIGRAM_TARGETS["DAA"], GieoQueService.SECOND_TRIGRAM_TARGETS["ADD"])


func test_campaign_deck_stays_52_and_deals_reuse_permanent_identity_state() -> void:
	var campaign := CampaignManager.new()
	campaign.start_campaign()
	assert_eq(campaign.gieo_que.persistent_deck.size(), 52)
	var transformed := campaign.gieo_que.persistent_deck[0]
	var physical_id := transformed.unique_id
	transformed.apply_rank("K", 13)
	transformed.apply_suit("Hearts")
	transformed.add_gieo_property(GieoQueService.PROPERTY_MELD_RETRIGGER)
	var deal := DealState.new()
	deal.set_campaign_deck(campaign.gieo_que.persistent_deck)
	deal.start_deal(91)
	var in_first_deal := _find_deal_card(deal, physical_id)
	assert_eq(in_first_deal.rank, "K")
	assert_eq(in_first_deal.suit, "Hearts")
	assert_true(in_first_deal.has_gieo_property(GieoQueService.PROPERTY_MELD_RETRIGGER))
	assert_eq(deal.physical_card_accounting()["total_cards"], 52)
	in_first_deal.value_modifiers.append(99)
	deal.start_deal(92)
	var in_later_deal := _find_deal_card(deal, physical_id)
	assert_eq(in_later_deal.rank, "K")
	assert_eq(in_later_deal.suit, "Hearts")
	assert_eq(in_later_deal.score_value(), 13)
	assert_eq(deal.physical_card_accounting()["unique_ids"], 52)
	campaign.start_campaign()
	assert_eq(campaign.gieo_que.persistent_deck.size(), 52)
	var restored := _find_card(campaign.gieo_que.persistent_deck, physical_id)
	assert_eq(restored.rank, "A")
	assert_eq(restored.suit, "Spades")
	assert_true(restored.gieo_properties.is_empty())


func test_cast_has_six_lines_rerolls_every_line_and_has_no_targets_before_accept() -> void:
	var service := GieoQueService.new()
	var first_lines: Array[String] = ["D", "A", "A", "D", "D", "A"]
	var second_lines: Array[String] = ["A", "D", "D", "A", "A", "D"]
	assert_true(service.cast(first_lines)["ok"])
	assert_eq((service.current_result["lines"] as Array).size(), 6)
	assert_true(service.resolved_targets.is_empty())
	assert_false(service.current_result.has("locked_lines"))
	service.wallet.reset(100_000)
	assert_true(service.reroll(second_lines)["ok"])
	assert_eq(service.current_result["lines"], second_lines)
	assert_ne(service.current_result["lines"], first_lines)
	assert_true(service.resolved_targets.is_empty())


func test_slot_machine_panel_preserves_authoritative_result_and_locks_pending_choice() -> void:
	var service := GieoQueService.new()
	var panel := GieoQuePanel.new()
	panel.configure(service)
	assert_eq(panel.presentation_state, GieoQuePanel.PresentationState.IDLE)
	assert_false(panel.is_interaction_locked())
	assert_eq(panel.find_children("OracleReel*", "Control", true, false).size(), 6)
	assert_true(panel.find_child("OracleLever", true, false) is Button)
	assert_true(panel.find_child("OracleUpperPanel", true, false) is PanelContainer)
	assert_true(panel.find_child("OracleLowerPanel", true, false) is PanelContainer)

	var lines: Array[String] = ["D", "A", "D", "A", "D", "A"]
	assert_true(service.cast(lines)["ok"])
	panel._rebuild()
	assert_eq(panel.presentation_state, GieoQuePanel.PresentationState.SHOWING_RESULT)
	assert_true(panel.is_interaction_locked())
	assert_eq(panel.displayed_reel_values(), lines)
	assert_true(panel.find_child("ResolvedOracleUpperPanel", true, false) is PanelContainer)
	assert_true(panel.find_child("ResolvedOracleLowerPanel", true, false) is PanelContainer)
	assert_true(panel.find_child("OracleDecisions", true, false) is HBoxContainer)

	var authoritative_result := service.current_result.duplicate(true)
	for tick in range(20):
		panel._set_reel_value(tick % 6, GieoQueService.LINE_DUONG if tick % 2 == 0 else GieoQueService.LINE_AM)
	assert_eq(service.current_result, authoritative_result)
	panel.free()


func test_big_gold_preserves_rank_and_random_targets_wait_for_accept() -> void:
	var service := GieoQueService.new()
	service.set_seed_value(41)
	assert_true(service.cast(["D", "A", "A", "D", "D", "A"])["ok"])
	assert_false(service.current_result.has("resolved_rank"))
	assert_false(service.current_result.has("resolved_suit"))
	assert_true(service.resolved_targets.is_empty())
	assert_true(service.accept()["ok"])
	assert_eq(service.state, GieoQueService.STATE_TARGET_REVEAL)
	assert_eq(service.resolved_targets.size(), 2)
	service.apply_resolved_targets()
	for transformation in service.last_transformations:
		assert_eq(transformation["after"]["rank"], transformation["before"]["rank"])
		assert_true(transformation["after"]["gieo_properties"].has(GieoQueService.PROPERTY_GOLD_BIG_PHOM))


func test_offer_candidates_are_generated_only_after_accept_and_force_one_choice() -> void:
	var service := GieoQueService.new()
	assert_true(service.cast(["D", "D", "D", "D", "A", "A"])["ok"])
	assert_true(service.resolved_targets.is_empty())
	assert_true(service.accept()["ok"])
	assert_eq(service.state, GieoQueService.STATE_TARGET_SELECTION)
	assert_eq(service.resolved_targets.size(), 3)
	var chosen_id := service.resolved_targets[1].unique_id
	assert_true(service.choose_target(chosen_id)["ok"])
	assert_eq(service.state, GieoQueService.STATE_TRANSFORM)
	service.finish_transformation()
	assert_eq(service.state, GieoQueService.STATE_COMPLETE)
	assert_eq(service.last_transformations.size(), 1)
	assert_eq((service.last_transformations[0]["after"] as Dictionary)["unique_id"], chosen_id)


func test_same_suit_and_consecutive_targets_are_legal_with_fallback() -> void:
	var service := GieoQueService.new()
	service.set_seed_value(7)
	var same_suit := service._random_same_suit_group(3)
	assert_eq(same_suit.size(), 3)
	assert_eq(same_suit[0].suit, same_suit[1].suit)
	assert_eq(same_suit[1].suit, same_suit[2].suit)
	var sequence := service._random_consecutive_group(3)
	assert_eq(sequence.size(), 3)
	var ranks: Array[int] = [sequence[0].rank_index, sequence[1].rank_index, sequence[2].rank_index]
	ranks.sort()
	assert_eq(ranks[1], ranks[0] + 1)
	assert_eq(ranks[2], ranks[1] + 1)
	assert_false(ranks == [1, 12, 13])
	service.persistent_deck = [
		CardData.new("fallback_q", "Q", 12, "Spades", 12),
		CardData.new("fallback_k", "K", 13, "Hearts", 13),
		CardData.new("fallback_a", "A", 1, "Diamonds", 1),
	]
	var fallback := service._random_consecutive_group(3)
	assert_eq(fallback.size(), 2)
	assert_eq(absi(fallback[0].rank_index - fallback[1].rank_index), 1)
	assert_false(fallback.any(func(card: CardData) -> bool: return card.rank_index == 1))
	service.persistent_deck = [CardData.new("single_a", "A", 1, "Clubs", 1)]
	assert_eq(service._random_consecutive_group(3).size(), 1)
	assert_eq(service._random_same_suit_group(3).size(), 1)


func test_accept_locks_reroll_and_refuse_until_transformation_completes() -> void:
	var service := GieoQueService.new()
	service.cast(["D", "D", "A", "D", "A", "D"])
	assert_true(service.accept()["ok"])
	assert_eq(service.state, GieoQueService.STATE_DESTINATION_SELECTION)
	assert_false(service.reroll()["ok"])
	assert_false(service.refuse()["ok"])
	service.choose_destination("7")
	assert_eq(service.state, GieoQueService.STATE_TARGET_SELECTION)
	assert_true(service.choose_target(service.persistent_deck[0].unique_id)["ok"])
	assert_eq(service.state, GieoQueService.STATE_TRANSFORM)
	service.finish_transformation()
	assert_eq(service.state, GieoQueService.STATE_COMPLETE)


func test_jackpots_override_normal_composition_and_apply_exact_properties() -> void:
	var yang := GieoQueService.new()
	yang.cast(["D", "D", "D", "D", "D", "D"])
	assert_eq(yang.current_result["jackpot"], GieoQueService.JACKPOT_THUAN_DUONG)
	yang.accept()
	yang.choose_destination("K")
	var yang_card := yang.persistent_deck[0]
	yang.choose_target(yang_card.unique_id)
	assert_eq(yang_card.rank, "K")
	assert_true(yang_card.has_gieo_property(GieoQueService.PROPERTY_MELD_RETRIGGER))
	assert_eq(yang_card.gieo_properties, [GieoQueService.PROPERTY_MELD_RETRIGGER])
	assert_eq(yang.last_transformations.size(), 1)

	var yin := GieoQueService.new()
	yin.cast(["A", "A", "A", "A", "A", "A"])
	assert_eq(yin.current_result["jackpot"], GieoQueService.JACKPOT_THUAN_AM)
	yin.accept()
	yin.choose_destination("Diamonds")
	var yin_card := yin.persistent_deck[0]
	yin.choose_target(yin_card.unique_id)
	assert_eq(yin_card.suit, "Diamonds")
	assert_true(yin_card.has_gieo_property(GieoQueService.PROPERTY_MELD_RETRIGGER))
	assert_eq(yin_card.gieo_properties, [GieoQueService.PROPERTY_MELD_RETRIGGER])
	assert_eq(yin.last_transformations.size(), 1)


func test_daily_free_pull_and_paid_escalation_reset_by_day() -> void:
	var wallet := VndWallet.new()
	wallet.reset(1_000_000)
	var service := GieoQueService.new(wallet)
	service.begin_day(0)
	assert_eq(service.current_pull_cost(), 0)
	service.cast(["D", "A", "D", "D", "A", "D"])
	assert_true(service.free_cast_used_today)
	assert_eq(wallet.balance_vnd, 1_000_000)
	var first_paid := service.current_pull_cost()
	service.reroll(["A", "D", "A", "D", "A", "D"])
	assert_eq(wallet.balance_vnd, 1_000_000 - first_paid)
	assert_eq(service.paid_cast_count_today, 1)
	assert_eq(service.current_pull_cost(), first_paid * GieoQueService.PAID_GROWTH_FACTOR)
	service.begin_day(1)
	assert_eq(service.current_pull_cost(), 0)
	assert_eq(service.paid_cast_count_today, 0)
	assert_eq(service.daily_base_cost(), GieoQueService.BASE_COST_VND)


func test_free_cast_stays_consumed_across_all_fortune_teller_windows_that_day() -> void:
	var wallet := VndWallet.new()
	wallet.reset(100_000)
	var events := EventManager.new()
	CampaignNpcCatalog.register_initial_npcs(events)
	var campaign := CampaignManager.new(wallet, events, DrinkManager.new(wallet))
	campaign.start_campaign(false)
	campaign.drink_manager.select_for_event(EventManager.EventSlot.STARTER, DrinkCatalog.TRA_DA)
	events.complete_interaction("choose_drink")
	campaign.complete_current_event()
	campaign.complete_deal()
	assert_eq(campaign.current_phase, CampaignManager.CampaignPhase.MORNING_EVENT)
	assert_true(campaign.gieo_que.cast(["D", "A", "D", "D", "A", "D"])["ok"])
	assert_true(campaign.gieo_que.free_cast_used_today)
	var paid_cost := campaign.gieo_que.current_pull_cost()
	campaign.gieo_que.refuse()
	campaign.complete_current_event()
	campaign.complete_deal()
	assert_eq(campaign.current_phase, CampaignManager.CampaignPhase.NOON_EVENT)
	assert_eq(campaign.gieo_que.current_pull_cost(), paid_cost)
	campaign.drink_manager.select_for_event(EventManager.EventSlot.NOON, DrinkCatalog.TRA_DA)
	events.complete_interaction("choose_drink")
	campaign.complete_current_event()
	campaign.complete_deal()
	assert_eq(campaign.current_phase, CampaignManager.CampaignPhase.AFTERNOON_EVENT)
	assert_eq(campaign.gieo_que.current_pull_cost(), paid_cost)


func _find_deal_card(deal: DealState, card_id: String) -> CardData:
	var cards: Array[CardData] = []
	cards.append_array(deal.hand)
	cards.append_array(deal.deck.draw_pile)
	cards.append_array(deal.deck.discard_pile)
	return _find_card(cards, card_id)


func _find_card(cards: Array[CardData], card_id: String) -> CardData:
	for card in cards:
		if card.unique_id == card_id:
			return card
	return null


func _kings(count: int) -> Array[CardData]:
	var cards: Array[CardData] = []
	for i in count:
		cards.append(CardData.new("gold_king_%d" % i, "K", 13, "Spades", 13))
	return cards


func test_gold_stack_uses_current_value_before_physical_count_without_extra_passes() -> void:
	var cards := _kings(3)
	cards[0].value_modifiers.append(2)
	cards[0].gieo_properties.assign(["GOLD_MAKING_PHOM", "GOLD_SET", "GOLD_RUN", "GOLD_BIG_PHOM", "GOLD_EXTEND", "GOLD_LAST_CALL"])
	var context := ScoringPipeline.new().preview_new_meld(cards, MeldRules.TYPE_SET, 1)
	assert_eq(context.card_value_sum, 71) # 15 + 13 + 13 + 15 + 15
	assert_eq(context.theoretical_score, 213)
	assert_eq(context.local_mult, 3)
	assert_eq(context.cards.size(), 3)
	assert_eq(context.scoring_passes.size(), 1)
	assert_eq(context.qualifying_gold(cards[0]), ["GOLD_MAKING_PHOM", "GOLD_SET"])
	assert_eq(context.scoring_passes[0].presentation_hits.size(), 5)


func test_big_gold_and_native_milestone_are_separate() -> void:
	var cards := _kings(4)
	cards[0].gieo_properties.assign(["GOLD_MAKING_PHOM", "GOLD_SET", "GOLD_BIG_PHOM"])
	var context := ScoringPipeline.new().preview_new_meld(cards, MeldRules.TYPE_SET, 1)
	assert_eq(context.card_value_sum, 91)
	assert_eq(context.theoretical_score, 364)
	assert_eq(context.scoring_passes.size(), 2) # Existing native four-card rule.
	assert_eq(context.scoring_passes[1].trigger_origin, ScoringPipeline.TRIGGER_NATIVE_RETRIGGER)
	assert_eq(context.final_points, 728)


func test_extension_conditions_only_belong_to_new_card_and_use_delta() -> void:
	var cards := _kings(5)
	for card in [cards[0], cards[-1]]:
		card.gieo_properties.assign(["GOLD_MAKING_PHOM", "GOLD_EXTEND", "GOLD_LAST_CALL"])
	var scoring := ScoringPipeline.new()
	var normal := scoring.preview_extension(cards, MeldRules.TYPE_SET, 208, 1, [cards[-1]])
	assert_eq(normal.qualifying_gold(cards[0]), [])
	assert_eq(normal.card_value_sum, 78)
	assert_eq(normal.base_extension_score, 182) # (65 + 13) * 5 - 208
	var last := scoring.preview_extension(cards, MeldRules.TYPE_SET, 208, 1, [cards[-1]], true)
	assert_eq(last.qualifying_gold(cards[0]), [])
	assert_eq(last.qualifying_gold(cards[-1]), ["GOLD_EXTEND", "GOLD_LAST_CALL"])
	assert_eq(last.base_extension_score, 247)
	assert_eq(last.scoring_passes.size(), 1)


func test_set_run_and_big_gold_on_every_legitimate_scoring_event() -> void:
	var cards: Array[CardData] = []
	for rank in range(4, 8):
		cards.append(CardData.new(str(rank), str(rank), rank, "Hearts", rank))
	cards[0].gieo_properties.assign(GieoQueService.GOLD_PROPERTIES)
	var scoring := ScoringPipeline.new()
	var context := scoring.preview_extension(cards, MeldRules.TYPE_RUN, 45, 1, [cards[-1]], true)
	assert_eq(context.qualifying_gold(cards[0]), ["GOLD_RUN", "GOLD_BIG_PHOM"])
	assert_eq(context.theoretical_score, 120)
	assert_eq(context.final_points, 75)
	var exhausted := scoring.score_meld_trigger(cards, MeldRules.TYPE_RUN, 1)
	assert_eq(exhausted.qualifying_gold(cards[0]), ["GOLD_RUN", "GOLD_BIG_PHOM"])
	assert_eq(exhausted.final_points, 120)


func test_liquid_scales_without_cap_and_includes_all_gold_without_recursion() -> void:
	for count in range(6):
		var cards := _kings(5)
		cards[0].gieo_properties.assign(["GOLD_MAKING_PHOM", "GOLD_SET", "GOLD_BIG_PHOM"])
		for i in count:
			cards[i].add_gieo_property("MELD_RETRIGGER")
		var context := ScoringPipeline.new().preview_new_meld(cards, MeldRules.TYPE_SET, 1)
		assert_eq(context.theoretical_score, 520)
		assert_eq(context.final_points, 520 * (count + 1))
		assert_eq(context.scoring_passes.size(), count + 1)
		for i in context.scoring_passes.size():
			var scoring_pass: ScoringContext = context.scoring_passes[i]
			assert_eq(scoring_pass.final_points, 520)
			assert_eq(scoring_pass.retrigger_count, 0)
			assert_true(scoring_pass.scoring_passes.is_empty())
			if i > 0:
				assert_eq(scoring_pass.retrigger_source_id, cards[i - 1].unique_id)


func test_old_liquid_cards_wait_for_set_milestone_while_gold_stays_active() -> void:
	var cards := _kings(5)
	cards[0].gieo_properties.assign(["MELD_RETRIGGER", "GOLD_SET"])
	cards[1].add_gieo_property("MELD_RETRIGGER")
	var context := ScoringPipeline.new().preview_extension(cards, MeldRules.TYPE_SET, 208, 1, [cards[-1]])
	assert_eq(context.scoring_passes.size(), 1)
	assert_eq(context.scoring_passes[0].final_points, 182)
	assert_eq(context.final_points, 182)
	var gold_hits := 0
	for hit in context.scoring_passes[0].presentation_hits:
		if hit["card_id"] == cards[0].unique_id and hit["property"] == "GOLD_SET":
			gold_hits += 1
	assert_eq(gold_hits, 1)
	for scoring_pass: ScoringContext in context.scoring_passes:
		var receipt_sum := 0
		for hit in scoring_pass.presentation_hits:
			receipt_sum += int(hit["points"])
		assert_eq(receipt_sum, scoring_pass.final_points)


func test_every_ordinary_cast_cannot_grant_liquid_or_random_destination() -> void:
	for first: String in GieoQueService.FIRST_TRIGRAM_EFFECTS:
		for second: String in GieoQueService.SECOND_TRIGRAM_TARGETS:
			if first == second and first in ["DDD", "AAA"]:
				continue
			var service := GieoQueService.new()
			var lines: Array[String] = []
			for letter in first + second:
				lines.append(letter)
			assert_true(service.cast(lines)["ok"])
			assert_false(service.current_result.has("resolved_rank"))
			assert_false(service.current_result.has("resolved_suit"))
			assert_true(service.resolved_targets.is_empty())
			service.accept()
			if service.state == GieoQueService.STATE_DESTINATION_SELECTION:
				service.choose_destination("K" if first == "DDA" else "Hearts")
			if service.state == GieoQueService.STATE_TARGET_SELECTION:
				var targets := service.resolved_targets if not service.resolved_targets.is_empty() else service.persistent_deck
				service.choose_target(targets[0].unique_id)
			else:
				service.apply_resolved_targets()
			assert_eq(service.state, GieoQueService.STATE_TRANSFORM)
			assert_eq(service.persistent_deck.size(), 52)
			for card in service.persistent_deck:
				assert_false(card.has_gieo_property("MELD_RETRIGGER"))


func test_all_seven_properties_survive_deal_copy_without_value_modifier_leak() -> void:
	var original := _kings(1)[0]
	original.gieo_properties.assign(GieoQueService.GOLD_PROPERTIES)
	original.add_gieo_property("MELD_RETRIGGER")
	assert_false(original.add_gieo_property("MELD_RETRIGGER"))
	original.value_modifiers.append(12)
	var copied := original.copy_for_deal()
	assert_eq(copied.unique_id, original.unique_id)
	assert_eq(copied.gieo_properties.size(), 7)
	assert_eq(copied.score_value(), 13)
	copied.gieo_properties.clear()
	assert_eq(original.gieo_properties.size(), 7)


func test_last_call_is_actual_commit_window_in_both_phases_and_preview() -> void:
	for phase in [1, 2]:
		var deal := DealState.new()
		deal.start_deal(123)
		deal.current_phase = phase
		deal.state = DealState.STATE_FINAL_COMMIT_WINDOW
		deal.hand = _kings(3)
		deal.hand[0].add_gieo_property("GOLD_LAST_CALL")
		assert_eq(deal.recommend_action()["estimated_points"], 156)
		var result := deal.create_meld(deal.hand.duplicate())
		assert_true(result["ok"])
		assert_eq(result["context"].final_points, 156)
		assert_true(result["context"].is_last_call)
