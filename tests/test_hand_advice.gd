@tool
extends McpTestSuite

func suite_name() -> String:
	return "hand_advice"

func card(rank: int, suit: String, id: String = "") -> CardData:
	return CardData.new(id if not id.is_empty() else "%d_%s" % [rank, suit], DeckManager.RANKS[rank-1], rank, suit, rank)

func fixture() -> DealState:
	var deal := DealState.new()
	deal.hand.assign([card(7,"Spades"),card(7,"Hearts"),card(13,"Clubs")])
	deal.deck.draw_pile.assign([card(7,"Diamonds"),card(2,"Clubs"),card(3,"Hearts"),card(4,"Diamonds"),card(5,"Spades"),card(10,"Clubs"),card(11,"Hearts"),card(12,"Diamonds")])
	return deal

func test_shared_scores_choose_lowest_and_preserve_state_and_rng() -> void:
	var d := fixture()
	var before := var_to_str(d.snapshot_state())
	var state := d.deck._rng.state
	var zodiac := d.zodiac_boss.rng.state
	var a := d.queries.hand_advice()
	assert_eq(a.discard_id, "13_Clubs")
	assert_eq(a.by_card[a.discard_id].keep_score, 0)
	assert_eq(var_to_str(d.snapshot_state()), before)
	assert_eq(d.deck._rng.state, state)
	assert_eq(d.zodiac_boss.rng.state, zodiac)
	assert_eq(d.queries.hand_advice(), a)
	d.deck.draw_pile.reverse()
	assert_eq(d.queries.hand_advice(), a)

func test_counterfactual_exact_odds_and_cache_refresh() -> void:
	var d := fixture()
	d.hand.append_array([card(1,"Clubs"),card(3,"Diamonds"),card(5,"Hearts"),card(9,"Clubs"),card(10,"Spades"),card(12,"Hearts"),card(2,"Diamonds")])
	var row: Dictionary = d.queries.hand_advice().by_card["13_Clubs"]
	assert_true(absf(row.probability - 0.125) < 0.00001)
	assert_eq(row.draw_count, 1)
	d.deck.draw_pile.append(card(7,"Clubs"))
	assert_true(d.queries.hand_advice().by_card["13_Clubs"].probability > row.probability)

func test_preserves_playable_cards_and_respects_locks() -> void:
	var d := fixture()
	d.hand.append(card(7,"Clubs"))
	var a := d.queries.hand_advice()
	assert_eq(a.discard_id, "13_Clubs")
	assert_true(a.by_card["7_Clubs"].protected)
	d.zodiac_boss.locked_ids.append("13_Clubs")
	a = d.queries.hand_advice()
	assert_true(a.discard_id != "13_Clubs")
	assert_true(a.by_card["13_Clubs"].locked)

func test_last_call_and_phase_choice_never_offer_a_discard() -> void:
	var d := fixture()
	d.state = DealState.STATE_FINAL_COMMIT_WINDOW
	var a := d.queries.hand_advice()
	assert_eq(a.discard_id, "")
	for row in a.by_card.values(): assert_eq(row.draw_count, 0)
	d.state = DealState.STATE_PHASE_CHOICE
	assert_eq(d.queries.hand_advice().discard_id, "")

func test_tra_da_extra_refill_horizon_and_skip_comparison() -> void:
	var d := fixture()
	d.current_drink_id = DrinkCatalog.TRA_DA
	var a := d.queries.hand_advice()
	assert_true(a.by_card[a.discard_id].draw_count >= 8)
	d.hand.erase(d.hand[2])
	d.deck.draw_pile.assign([card(7,"Diamonds")])
	for rank in range(1,14):
		if rank != 7: d.deck.draw_pile.append(card(rank,"Unknown"))
	d.discard_count = 1
	d.tra_da_extra_discard_pending = true
	a = d.queries.hand_advice()
	assert_eq(a.extra_action, "skip") # Both retained cards complete the same Set.
	d.hand.append(card(13,"Clubs"))
	a = d.queries.hand_advice()
	assert_eq(a.extra_action, "discard")
	assert_eq(a.discard_id, "13_Clubs")

func test_exhaustion_pool_excludes_mandatory_discards() -> void:
	var d := fixture()
	d.deck.draw_pile.clear()
	var locked := card(7,"Diamonds")
	d.deck.discard_pile.assign([locked])
	d.discard_history.append(DiscardRecord.new(locked,1,1,DiscardRecord.KIND_MANDATORY))
	d.recyclable_spent_cards.assign([card(2,"Clubs")])
	var row: Dictionary = d.queries.hand_advice().by_card["13_Clubs"]
	assert_true(row.crosses_exhaustion)
	assert_eq(row.probability, 0.0)
	d.discard_history.clear()
	assert_eq(d.queries.hand_advice().by_card["13_Clubs"].probability, 1.0)

func test_equal_outcomes_share_score_with_stable_identity_tie() -> void:
	var d := DealState.new()
	d.discard_count = 3
	d.hand.assign([card(13,"Clubs","b"),card(13,"Hearts","a")])
	var a := d.queries.hand_advice()
	assert_eq(a.discard_id, "a")
	assert_eq(a.by_card.a.keep_score, a.by_card.b.keep_score)

func test_two_missing_run_cards_use_joint_without_replacement_odds() -> void:
	var d := DealState.new()
	d.hand.assign([card(4,"Clubs"),card(13,"Unknown")])
	for rank in [1,3,8,9,10,11,12]: d.hand.append(card(rank,"Unknown"))
	d.deck.draw_pile.assign([card(5,"Clubs"),card(6,"Clubs"),card(2,"Hearts"),card(7,"Spades")])
	var row: Dictionary = d.queries.hand_advice().by_card["13_Unknown"]
	assert_eq(row.draw_count,2)
	assert_true(absf(row.probability - 1.0/6.0) < 0.000001)

func test_partial_exhaustion_guarantees_remaining_pool_then_samples_recycled_pool() -> void:
	var d := fixture()
	for rank in [1,3,5,8,10,12]: d.hand.append(card(rank,"Unknown"))
	d.deck.draw_pile.assign([card(2,"Clubs")])
	d.recyclable_spent_cards.assign([card(7,"Diamonds"),card(4,"Hearts"),card(6,"Spades"),card(9,"Clubs")])
	var row: Dictionary = d.queries.hand_advice().by_card["13_Clubs"]
	assert_eq(row.draw_count,2)
	assert_true(row.crosses_exhaustion)
	assert_true(absf(row.probability - 0.25) < 0.000001)

func test_playable_extension_is_preserved_and_last_call_respects_locks() -> void:
	var d := DealState.new()
	d.hand.assign([card(7,"Clubs"),card(13,"Clubs")])
	d.melds.append(MeldState.new(1,MeldRules.TYPE_SET,[card(7,"Spades"),card(7,"Hearts"),card(7,"Diamonds")] as Array[CardData]))
	var a := d.queries.hand_advice()
	assert_eq(a.play.action, HandAdvisor.ACTION_EXTENSION)
	assert_eq(a.discard_id,"13_Clubs")
	assert_true(a.by_card["7_Clubs"].protected)
	d.zodiac_boss.locked_ids.append("7_Clubs")
	d.state = DealState.STATE_FINAL_COMMIT_WINDOW
	a = d.queries.hand_advice()
	assert_eq(a.play.action,HandAdvisor.ACTION_NONE)
	assert_eq(a.by_card["13_Clubs"].probability,0.0)

func test_passive_drink_color_run_counts_both_suits_and_recomputes() -> void:
	var d := DealState.new()
	d.hand.assign([card(4,"Hearts"),card(6,"Diamonds"),card(13,"Clubs")])
	for rank in [1,2,8,9,10,11,12]: d.hand.append(card(rank,"Unknown"))
	d.deck.draw_pile.assign([card(5,"Hearts"),card(5,"Diamonds"),card(3,"Spades"),card(7,"Spades")])
	assert_eq(d.queries.hand_advice().by_card["13_Clubs"].probability,0.0)
	d.current_drink_id = DrinkCatalog.MIA_TAC
	assert_true(absf(d.queries.hand_advice().by_card["13_Clubs"].probability - 0.5) < 0.000001)

func test_returned_advice_dictionary_cannot_corrupt_cache() -> void:
	var d := fixture()
	var a := d.queries.hand_advice()
	a.by_card.clear()
	assert_eq(d.queries.hand_advice().by_card.size(),d.hand.size())

func test_rare_but_distinct_completion_odds_do_not_become_a_tie() -> void:
	# One specific three-card target versus two winning combinations in 100 choose 3.
	var low := {"probability": 1.0/161700.0,"points": 0.0,"deadwood": 10}
	var high := {"probability": 2.0/161700.0,"points": 0.0,"deadwood": 20}
	assert_true(HandAdvice._better(high,low))
	assert_false(HandAdvice._equal(high,low))

func test_first_seed_policy_survives_save_and_legacy_defaults() -> void:
	var events := EventManager.new()
	CampaignNpcCatalog.register_initial_npcs(events)
	var c := CampaignManager.new(null,events)
	c.start_campaign(true,"STRAWY")
	c.onboarding.first_seed_enabled = false
	var d := DealState.new()
	d.start_deal(42)
	var save := RunSave.new("user://strawy-unit.save")
	var snapshot := save.capture(c,d)
	c.onboarding.first_seed_enabled = true
	assert_true(save.restore(snapshot,c,d))
	assert_false(c.onboarding.first_seed_enabled)
	snapshot.onboarding.erase("first_seed_enabled")
	assert_true(save.restore(snapshot,c,d))
	assert_true(c.onboarding.first_seed_enabled)

func test_disk_restore_rebinds_primed_advice_to_current_physical_cards() -> void:
	var deal := DealState.new()
	var campaign := CampaignManager.new(deal.wallet)
	campaign.zodiac.bind(campaign, deal)
	campaign.start_campaign(true, "ADVICE-RESTORE")
	deal.set_campaign_deck(campaign.gieo_que.persistent_deck)
	deal.start_deal(991, false, ["standard_7_spades", "standard_7_hearts", "standard_7_clubs", "standard_k_clubs"] as Array[String])
	var original: CardData = deal.queries.hand_advice().play.cards[0]
	var save := RunSave.new("user://advice-cache-regression.save")
	assert_true(save.save_run(campaign, deal))
	assert_true(save.restore(save.load_run(), campaign, deal))
	assert_false(deal.hand.has(original))
	var advice := deal.queries.hand_advice()
	assert_eq(advice, HandAdvice.analyze(deal))
	for selected: CardData in advice.play.cards:
		assert_true(deal.hand.has(selected))
	assert_true(deal.can_create_meld(advice.play.cards))
	assert_true(deal.physical_card_accounting_is_valid())

func test_advice_rebinds_same_value_hand_replacements() -> void:
	var deal := fixture()
	deal.hand.append(card(7, "Clubs"))
	deal.queries.hand_advice()
	for index in deal.hand.size(): deal.hand[index] = deal.hand[index].copy_for_deal()
	for selected: CardData in deal.queries.hand_advice().play.cards:
		assert_true(deal.hand.has(selected))
