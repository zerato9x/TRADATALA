@tool
extends McpTestSuite

func suite_name() -> String: return "zodiac_runtime"

func _deal(id: String, level: int = 2) -> DealState:
	var deal := DealState.new()
	deal.start_tutorial_deal()
	deal.zodiac_boss.configure(id, level, 5678)
	deal.zodiac_boss.begin_phase(deal)
	return deal

func _cards(deal: DealState, specs: Array) -> Array[CardData]:
	var result: Array[CardData] = []
	for spec: Array in specs:
		var found: CardData
		for card in deal.hand:
			if card.rank == spec[0] and card.suit == spec[1]: found = card; break
		if found == null:
			found = deal._take_tutorial_card(spec[0], spec[1])
			deal.hand.append(found)
		result.append(found)
	return result

func _restored(deal: DealState) -> DealState:
	var copy := DealState.new()
	copy.restore_snapshot(deal.snapshot_state())
	assert_eq(copy.zodiac_boss.snapshot(), deal.zodiac_boss.snapshot())
	assert_true(copy.physical_card_accounting_is_valid())
	return copy

func test_dog_all_difficulties_payout_legality_and_phase_reset() -> void:
	for level in [1, 2, 3]:
		var deal := _deal("dog", level)
		var first := deal.create_meld(deal.hand.slice(0, 3))
		assert_true(first.ok)
		assert_eq(deal.zodiac_boss.data.loyal_meld_id, first.meld_id)
		var before := deal.wallet.balance_vnd
		var second := deal.create_meld(deal.hand.slice(0, 3))
		assert_eq(second.ok, level != 3)
		if level != 3:
			assert_eq(deal.wallet.balance_vnd - before, 40_000 if level == 1 else 0)
			assert_true(deal.hand.size() < 7)
		var added := _cards(deal, [["7", "Hearts"]])
		before = deal.wallet.balance_vnd
		assert_true(deal.extend_meld(first.meld_id, added).ok)
		assert_gt(deal.wallet.balance_vnd, before)
		_restored(deal)
		assert_true(deal.discard_card(deal.hand[-1]).ok)
		deal.current_phase = 2
		deal.zodiac_boss.begin_phase(deal)
		assert_eq(deal.zodiac_boss.data.loyal_meld_id, -1)
		assert_true(deal.physical_card_accounting_is_valid())

func test_monkey_repetition_misses_keep_physical_actions_and_turn() -> void:
	for level in [1, 2]:
		var deal := _deal("monkey", level)
		assert_gt(deal.create_meld(deal.hand.slice(0, 3)).context.final_points, 0)
		var second := deal.create_meld(deal.hand.slice(0, 3))
		assert_true(second.ok)
		assert_eq(second.context.final_points, 81 if level == 1 else 0)
		var third := _cards(deal, [["2", "Spades"], ["2", "Hearts"], ["2", "Diamonds"]])
		var before := deal.wallet.balance_vnd
		assert_eq(deal.create_meld(third).context.final_points, 0)
		assert_eq(deal.wallet.balance_vnd, before)
		assert_eq(deal.state, DealState.STATE_ACTIVE)
		assert_eq(deal.discard_count, 0)
		assert_eq(deal.melds.size(), 3)
		_restored(deal)
		deal.current_phase = 2
		deal.zodiac_boss.begin_phase(deal)
		assert_eq(deal.zodiac_boss.data.repeat_count, 0)

func test_monkey_sequence_miss_correct_discard_rng_and_restore() -> void:
	var deal := _deal("monkey", 3)
	assert_eq(deal.zodiac_boss.data.sequence.size(), 3)
	var deck_rng := deal.deck._rng.state
	deal.zodiac_boss.data.sequence = ["extension", "new_meld", "discard"]
	var miss := deal.create_meld(deal.hand.slice(0, 3))
	assert_true(miss.ok)
	assert_eq(miss.context.final_points, 0)
	assert_eq(deal.zodiac_boss.data.sequence_index, 0)
	assert_eq(deal.state, DealState.STATE_ACTIVE)
	var added := _cards(deal, [["7", "Hearts"]])
	assert_gt(deal.extend_meld(miss.meld_id, added).context.final_points, 0)
	assert_eq(deal.zodiac_boss.data.sequence_index, 1)
	assert_eq(deal.deck._rng.state, deck_rng)
	var copy := _restored(deal)
	assert_gt(deal.create_meld(deal.hand.slice(0, 3)).context.final_points, 0)
	assert_gt(copy.create_meld(copy.hand.slice(0, 3)).context.final_points, 0)
	assert_eq(deal.zodiac_boss.data.sequence_index, 2)
	deal.discard_card(deal.hand[-1])
	copy.discard_card(copy.hand[-1])
	assert_eq(deal.zodiac_boss.snapshot(), copy.zodiac_boss.snapshot())
	assert_eq(deal.zodiac_boss.data.sequence_index, 0)
	assert_true(deal.physical_card_accounting_is_valid())


func test_pig_all_tiers_siphon_visible_target_return_and_restore() -> void:
	for level in [1, 2, 3]:
		var deal := _deal("pig", level)
		assert_eq(deal.zodiac_boss.presentation().target_vnd, [40_000, 50_000, 60_000][level - 1])
		deal.create_meld(deal.hand.slice(0, 3))
		assert_eq(deal.zodiac_boss.data.pool_vnd, [0, 13_500, 18_000][level - 1])
		assert_eq(deal.zodiac_boss.data.progress_vnd, 45_000)
		var copy := _restored(deal)
		deal.create_meld(deal.hand.slice(0, 3))
		copy.create_meld(copy.hand.slice(0, 3))
		assert_eq(deal.wallet.balance_vnd, 126_000)
		assert_true(deal.zodiac_boss.data.target_met)
		assert_eq(deal.zodiac_boss.data.pool_vnd, 0)
		assert_eq(deal.wallet.journal, copy.wallet.journal)
		assert_eq(deal.zodiac_boss.snapshot(), copy.zodiac_boss.snapshot())
		deal.zodiac_boss.settle(deal)
		assert_eq(deal.wallet.balance_vnd, 126_000)
		deal.current_phase = 2
		deal.zodiac_boss.begin_phase(deal)
		assert_true(deal.zodiac_boss.data.target_met)

func test_pig_unpleased_bank_loss_only_on_failed_target_once() -> void:
	for level in [1, 2, 3]:
		var deal := _deal("pig", level)
		deal.wallet.reset(200_000)
		deal.zodiac_boss.data.target_vnd = 1_000_000
		deal.create_meld(deal.hand.slice(0, 3))
		var before := deal.wallet.balance_vnd
		deal.zodiac_boss.settle(deal)
		assert_eq(deal.wallet.balance_vnd, int(before / 2.0) if level == 3 else before)
		var after := deal.wallet.balance_vnd
		deal.zodiac_boss.settle(deal)
		assert_eq(deal.wallet.balance_vnd, after)
		assert_eq(deal.wallet.report().net_vnd, after - 200_000)
		_restored(deal)

func test_ox_per_card_doubling_grace_hard_formula_and_removal() -> void:
	for level in [1, 2, 3]:
		var deal := _deal("ox", level)
		var held := deal.hand[0]
		var first := deal._deduct_turn_deadwood()
		assert_eq(first.ox_burden[held.unique_id], [4, 8, 36][level - 1])
		var second := deal._deduct_turn_deadwood()
		assert_eq(second.ox_burden[held.unique_id], [8, 16, 72][level - 1])
		assert_eq(deal.zodiac_boss.data.burden_age[held.unique_id], 2)
		var fresh := _cards(deal, [["A", "Spades"]])[0]
		deal._deduct_turn_deadwood()
		assert_eq(deal.zodiac_boss.data.burden_age[fresh.unique_id], 1)
		var copy := _restored(deal)
		assert_eq(deal._deduct_turn_deadwood().deadwood, copy._deduct_turn_deadwood().deadwood)
		deal.create_meld(deal.hand.slice(0, 3))
		assert_false(deal.zodiac_boss.data.burden_age.has(held.unique_id))
		assert_true(deal.physical_card_accounting_is_valid())
		deal.current_phase = 2
		deal.zodiac_boss.begin_phase(deal)
		assert_true(deal.zodiac_boss.data.burden_age.has(fresh.unique_id))


func test_horse_pair_grace_forced_discard_limits_and_restore() -> void:
	for level in [1, 2, 3]:
		var deal := _deal("horse", level)
		deal.create_meld(deal.hand.slice(0, 3))
		assert_eq(deal.zodiac_boss.presentation().pair_count, 1)
		var before_rng := deal.deck._rng.state
		var copy := _restored(deal)
		var result := deal.discard_card(deal.hand[-1])
		var duplicate := copy.discard_card(copy.hand[-1])
		assert_eq(result.card.unique_id, duplicate.card.unique_id)
		assert_eq(result.forced_discard, level != 1)
		assert_eq(deal.discard_count, 1)
		assert_eq(deal.discard_history.size(), 1)
		assert_eq(deal.deck._rng.state, before_rng)
		assert_eq(deal.zodiac_boss.snapshot(), copy.zodiac_boss.snapshot())
		assert_eq(deal.zodiac_boss.data.pair_count, 0)
		result = deal.discard_card(deal.hand[-1])
		assert_true(result.forced_discard)
		assert_eq(deal.discard_count, 2)
		assert_eq(deal.state, DealState.STATE_FINAL_COMMIT_WINDOW if level == 3 else DealState.STATE_ACTIVE)
		assert_eq(deal.phase_discard_limit(), 2 if level == 3 else 4)
		assert_true(deal.physical_card_accounting_is_valid())
		deal.current_phase = 2
		deal.zodiac_boss.begin_phase(deal)
		assert_eq(deal.zodiac_boss.data.pair_grace, 1 if level == 1 else 0)

func test_horse_completed_pair_keeps_player_discard_and_drink_extra_is_separate() -> void:
	var deal := _deal("horse", 2)
	deal.create_meld(deal.hand.slice(0, 3))
	deal.create_meld(deal.hand.slice(0, 3))
	assert_eq(deal.zodiac_boss.data.pair_count, 2)
	deal.set_current_drink(DrinkCatalog.TRA_DA)
	var requested := deal.hand[-1]
	var result := deal.discard_card(requested)
	assert_eq(result.card, requested)
	assert_false(result.forced_discard)
	assert_true(result.extra_discard_pending)
	assert_eq(deal.discard_count, 1)
	deal.discard_card(deal.hand[-1])
	assert_eq(deal.discard_count, 1)
	assert_eq(deal.discard_history.size(), 2)
	assert_true(deal.physical_card_accounting_is_valid())

func test_goat_committed_rank_progression_grace_parity_and_restore() -> void:
	for level in [1, 2, 3]:
		var deal := _deal("goat", level)
		var made := deal.create_meld(deal.hand.slice(0, 3))
		assert_true(made.ok)
		assert_eq(made.context.final_points, 0 if level == 3 else 45)
		assert_eq(deal.zodiac_boss.data.expected_rank, 0 if level == 3 else 7)
		if level == 3:
			deal.zodiac_boss.data.expected_rank = 7
		var extra := _cards(deal, [["7", "Hearts"]])
		assert_gt(deal.extend_meld(made.meld_id, extra).context.final_points, 0)
		assert_eq(deal.zodiac_boss.data.expected_rank, 10)
		var before := deal.wallet.balance_vnd
		var off_pattern := deal.create_meld(deal.hand.slice(0, 3))
		assert_true(off_pattern.ok)
		assert_eq(deal.wallet.balance_vnd - before, 81_000 if level == 1 else 0)
		assert_eq(deal.discard_count, 0)
		_restored(deal)
		deal.current_phase = 2
		deal.zodiac_boss.begin_phase(deal)
		assert_eq(deal.zodiac_boss.data.expected_rank, 0)
		assert_eq(deal.zodiac_boss.data.rhythm_grace, 1 if level == 1 else 0)
		assert_true(deal.physical_card_accounting_is_valid())


func _top(deal: DealState, specs: Array) -> void:
	var top: Array[CardData] = []
	for spec: Array in specs: top.append(deal._take_tutorial_card(spec[0], spec[1]))
	for i in range(top.size() - 1, -1, -1): deal.deck.draw_pile.append(top[i])

func test_goat_three_rank_windows_accept_each_rank_advance_once_and_preview_safely() -> void:
	for rank in [7, 8, 9]:
		var deal := _deal("goat", 2)
		deal.create_meld(deal.hand.slice(0, 3)) # 4/5/6 opens 7/8/9.
		assert_eq(deal.zodiac_boss.presentation().accepted_ranks, [7, 8, 9])
		var cards := _cards(deal, [[str(rank), "Hearts"], [str(rank), "Clubs"], [str(rank), "Diamonds"]])
		var snapshot := deal.snapshot_state()
		assert_gt(deal.preview_new_meld_payout(cards, MeldRules.TYPE_SET).points, 0)
		assert_eq(deal.snapshot_state(), snapshot)
		assert_gt(deal.create_meld(cards).context.final_points, 0)
		assert_eq(deal.zodiac_boss.presentation().accepted_ranks, [10, 11, 12])
		_restored(deal)
	var run_deal := _deal("goat", 2)
	run_deal.create_meld(run_deal.hand.slice(0, 3))
	var next_run := _cards(run_deal, [["7", "Hearts"], ["8", "Hearts"], ["9", "Hearts"]])
	assert_gt(run_deal.create_meld(next_run).context.final_points, 0)
	assert_eq(run_deal.zodiac_boss.data.expected_rank, 10)
	var outside := _cards(run_deal, [["9", "Clubs"], ["10", "Clubs"], ["J", "Clubs"]])
	assert_eq(run_deal.create_meld(outside).context.final_points, 0)
	assert_eq(run_deal.zodiac_boss.data.expected_rank, 10)

func test_goat_window_wrap_grace_and_hard_parity() -> void:
	for start in [11, 12, 13]:
		var deal := _deal("goat", 2)
		deal.zodiac_boss.data.expected_rank = start
		var window: Array[int] = deal.zodiac_boss.presentation().accepted_ranks
		var rank: String = DeckManager.RANKS[window[-1] - 1]
		var cards := _cards(deal, [[rank, "Hearts"], [rank, "Clubs"], [rank, "Diamonds"]])
		assert_gt(deal.create_meld(cards).context.final_points, 0)
		assert_eq(deal.zodiac_boss.data.expected_rank, (start + 2) % 13 + 1)
		_restored(deal)
	var hard := _deal("goat", 3)
	hard.zodiac_boss.data.expected_rank = 6 # Even start does not block the odd rank inside 6/7/8.
	var sevens := _cards(hard, [["7", "Hearts"], ["7", "Clubs"], ["7", "Diamonds"]])
	assert_gt(hard.create_meld(sevens).context.final_points, 0)
	assert_eq(hard.zodiac_boss.data.expected_rank, 9)
	var tens := _cards(hard, [["10", "Hearts"], ["10", "Clubs"], ["10", "Diamonds"]])
	assert_eq(hard.create_meld(tens).context.final_points, 0)
	assert_eq(hard.zodiac_boss.data.expected_rank, 9)
	var easy := _deal("goat", 1)
	easy.zodiac_boss.data.expected_rank = 2
	assert_gt(easy.create_meld(easy.hand.slice(0, 3)).context.final_points, 0)
	assert_eq(easy.zodiac_boss.data.rhythm_grace, 0)
	assert_eq(easy.zodiac_boss.data.expected_rank, 7)
	assert_eq(easy.create_meld(_cards(easy, [["Q", "Clubs"], ["Q", "Hearts"], ["Q", "Spades"]])).context.final_points, 0)

func test_mouse_all_tiers_hostile_meld_ownership_wallet_and_accounting() -> void:
	for level in [1, 2, 3]:
		var deal := _deal("rat", level)
		_top(deal, [["J", "Hearts"], ["J", "Diamonds"], ["A", "Clubs"], ["3", "Diamonds"]])
		var card := deal.hand[-1]
		deal.boss_discard_card(card, "fixture")
		var deck_rng := deal.deck._rng.state
		deal.zodiac_boss.after_discard(deal, deal.discard_history[-1])
		assert_eq(deal.wallet.balance_vnd, -99_000)
		assert_eq(deal.wallet.journal[-1].reason, "zodiac:rat:meld")
		assert_eq(deal.boss_melds.size(), 1)
		assert_eq(deal.boss_melds[0].cards.size(), 3)
		assert_true(deal.melds.is_empty())
		assert_true(deal.boss_borrowed_cards.is_empty())
		assert_eq(deal.deck._rng.state, deck_rng)
		assert_true(deal.physical_card_accounting_is_valid())
		_restored(deal)
		assert_false(deal.deck.discard_pile.has(card))
		assert_true(deal.discard_history.is_empty())

func test_rat_owned_melds_accept_paid_player_extensions_at_every_difficulty() -> void:
	for level in [1, 2, 3]:
		for suit in ["set", "run"]:
			var deal := _deal("rat", level)
			var originals := _cards(deal, [["J", "Hearts"], ["J", "Diamonds"], ["J", "Clubs"]] if suit == "set" else [["4", "Hearts"], ["5", "Hearts"], ["6", "Hearts"]])
			for card in originals: deal.boss_discard_card(card, "fixture")
			var made := deal.boss_commit_meld(originals, -1, "rat")
			var meld: MeldState = deal.boss_melds[0]
			var additions := _cards(deal, [["J", "Spades"]] if suit == "set" else [["7", "Hearts"], ["8", "Hearts"]])
			# Remove unrelated plays so the adviser must find the boss-owned target.
			for card in deal.hand.duplicate():
				if not additions.has(card): deal.boss_discard_card(card, "fixture")
			var spare := _cards(deal, [["A", "Clubs"]])
			var preview := deal.preview_extension_payout(meld, additions)
			assert_true(deal.can_extend_meld(made.meld_id, additions))
			assert_eq(deal.get_meld(made.meld_id), null)
			assert_eq(deal.get_table_meld(made.meld_id), meld)
			assert_eq(deal.queries.recommend_action().meld_id, made.meld_id)
			assert_true(deal.queries.legal_action_card_ids().extend.has(additions[0].unique_id))
			assert_true(deal.queries.legal_action_targets_for_selection(additions, -1).melds.has(made.meld_id))
			var wallet_before := deal.wallet.balance_vnd
			var value_before := ScoringPipeline.meld_value(meld.cards)
			var result := deal.extend_meld(made.meld_id, additions)
			assert_true(result.ok)
			assert_eq(result.earned_vnd, VndWallet.points_to_vnd(preview.points, deal.vnd_per_point))
			assert_eq(result.context.base_extension_score, ScoringPipeline.meld_value(meld.cards) - value_before)
			assert_eq(result.context.scoring_passes[0].final_points, result.context.base_extension_score)
			assert_eq(deal.wallet.balance_vnd - wallet_before, result.earned_vnd)
			assert_true(deal.melds.is_empty())
			assert_true(deal.boss_melds.has(meld))
			assert_eq(meld.cards.size(), originals.size() + additions.size())
			assert_eq(deal.hand, spare)
			assert_eq(deal.phase_metrics.extension_count, 1)
			assert_false(deal.extend_meld(made.meld_id, additions).ok)
			assert_eq(deal.wallet.balance_vnd - wallet_before, result.earned_vnd)
			var restored := _restored(deal)
			assert_eq(restored.get_table_meld(made.meld_id).cards.size(), meld.cards.size())
			deal.current_drink_id = DrinkCatalog.NAU_DA
			assert_false(deal.can_use_nau_da(made.meld_id))
			deal.current_drink_id = DrinkCatalog.NUOC_VOI
			assert_false(deal.can_use_nuoc_voi(made.meld_id, additions[-1]))
			assert_true(deal.physical_card_accounting_is_valid())

func test_mouse_hostile_extension_enters_player_meld_without_player_scoring() -> void:
	var deal := _deal("rat", 2)
	var made := deal.create_meld(deal.hand.slice(0, 3))
	var extra := _cards(deal, [["7", "Hearts"]])[0]
	_top(deal, [["A", "Clubs"], ["3", "Diamonds"], ["8", "Clubs"]])
	deal.boss_discard_card(extra, "fixture")
	deal.zodiac_boss.after_discard(deal, deal.discard_history[-1])
	assert_eq(deal.zodiac_boss.data.hostile_result.action, "boss_extension")
	assert_eq(deal.wallet.balance_vnd, 2_000)
	assert_eq(deal.melds[0].cards.size(), 4)
	assert_eq(deal.phase_metrics.extension_count, 0)
	assert_true(deal.boss_melds.is_empty())
	assert_false(deal.hand.has(extra))
	assert_true(deal.physical_card_accounting_is_valid())
	_restored(deal)

func test_mouse_failed_borrow_returns_every_card_reshuffles_and_preserves_rng() -> void:
	for level in [1, 2, 3]:
		var deal := _deal("rat", level)
		_top(deal, [["A", "Clubs"], ["3", "Diamonds"], ["8", "Clubs"], ["10", "Diamonds"]])
		deal.boss_discard_card(deal.hand[-1], "fixture")
		var before_order := deal.deck.draw_pile.map(func(card: CardData): return card.unique_id)
		var deck_rng := deal.deck._rng.state
		var copy := _restored(deal)
		deal.zodiac_boss.after_discard(deal, deal.discard_history[-1])
		copy.zodiac_boss.after_discard(copy, copy.discard_history[-1])
		assert_eq(deal.zodiac_boss.data.hostile_result.borrowed_count, level + 1)
		assert_eq(deal.deck.draw_pile.size(), before_order.size())
		assert_ne(deal.deck.draw_pile.map(func(card: CardData): return card.unique_id), before_order)
		assert_eq(deal.deck.draw_pile, copy.deck.draw_pile)
		assert_eq(deal.zodiac_boss.snapshot(), copy.zodiac_boss.snapshot())
		assert_eq(deal.deck._rng.state, deck_rng)
		assert_eq(deal.wallet.balance_vnd, 0)
		assert_true(deal.boss_borrowed_cards.is_empty())
		assert_true(deal.physical_card_accounting_is_valid())

func test_mouse_unpleased_reuses_previous_phase_without_duplicate_cards() -> void:
	for level in [1, 2, 3]:
		var deal := _deal("rat", level)
		for card in _cards(deal, [["J", "Hearts"], ["J", "Diamonds"]]): deal.boss_discard_card(card, "fixture")
		deal.current_phase = 2
		deal.zodiac_boss.begin_phase(deal)
		_top(deal, [["A", "Clubs"], ["3", "Diamonds"], ["8", "Clubs"], ["10", "Diamonds"]])
		var current: CardData
		for card in deal.hand:
			if card.rank == "J": current = card
		deal.boss_discard_card(current, "fixture")
		deal.zodiac_boss.after_discard(deal, deal.discard_history[-1])
		assert_eq(deal.boss_melds.size(), 1 if level == 3 else 0)
		assert_true(deal.physical_card_accounting_is_valid())

func test_tiger_immediate_all_tiers_highest_or_strategic_rank_and_restore() -> void:
	for level in [1, 2, 3]:
		var deal := _deal("tiger", level)
		_cards(deal, [["K", "Clubs"]])
		var deck_rng := deal.deck._rng.state
		var copy := _restored(deal)
		deal.zodiac_boss.begin_turn(1, deal.hand, deal)
		copy.zodiac_boss.begin_turn(1, copy.hand, copy)
		var removed: Array = deal.zodiac_boss.data.removed_ids
		assert_eq(removed.size(), [1, 2, 3][level - 1])
		for id in removed:
			var card: CardData = deal.deck.discard_pile.filter(func(c: CardData): return c.unique_id == id)[0]
			assert_eq(card.rank, "9" if level == 3 else "K")
		assert_eq(deal.discard_count, 0)
		assert_eq(deal.state, DealState.STATE_ACTIVE)
		assert_eq(deal.deck._rng.state, deck_rng)
		assert_eq(deal.zodiac_boss.snapshot(), copy.zodiac_boss.snapshot())
		assert_true(deal.physical_card_accounting_is_valid())
		assert_false(deal.zodiac_boss.presentation().has("prey"))

func test_tiger_all_tiers_suppress_only_exhaustion_bonus_and_recycle_normally() -> void:
	for level in [1, 2, 3]:
		var deal := _deal("tiger", level)
		assert_gt(deal.create_meld(deal.hand.slice(0, 3)).context.final_points, 0)
		var before := deal.wallet.balance_vnd
		var stock: Array[CardData] = deal.deck.draw_pile.duplicate()
		deal.deck.draw_pile.clear()
		deal.move_to_recyclable_spent(stock)
		deal.hand.append_array(deal.deck.draw(1))
		assert_eq(deal.wallet.balance_vnd - before, 0)
		assert_eq(deal.exhaustion_count, 1)
		assert_true(deal.melds.is_empty())
		assert_true(deal.physical_card_accounting_is_valid())


func test_rat_all_tiers_suppress_exhaustion_but_keep_normal_scoring_and_recycling() -> void:
	for level in [1, 2, 3]:
		var deal := _deal("rat", level)
		assert_gt(deal.create_meld(deal.hand.slice(0, 3)).context.final_points, 0)
		var before := deal.wallet.balance_vnd
		var stock: Array[CardData] = deal.deck.draw_pile.duplicate()
		deal.deck.draw_pile.clear()
		deal.move_to_recyclable_spent(stock)
		deal.hand.append_array(deal.deck.draw(1))
		assert_eq(deal.wallet.balance_vnd, before)
		assert_eq(deal.exhaustion_count, 1)
		assert_true(deal.melds.is_empty())
		assert_true(deal.physical_card_accounting_is_valid())
		_restored(deal)

func test_snake_all_tiers_commands_sabotage_continues_turn_and_restore() -> void:
	for level in [1, 2, 3]:
		var deal := _deal("snake", level)
		var copy := _restored(deal)
		var before_rng := deal.deck._rng.state
		var before_hand: Array = deal.hand.map(func(card): return card.unique_id)
		deal.zodiac_boss.begin_turn(1, deal.hand, deal)
		copy.zodiac_boss.begin_turn(1, copy.hand, copy)
		assert_eq(deal.zodiac_boss.data.commands.size(), 1)
		assert_eq(deal.zodiac_boss.data.command_limit, level)
		assert_eq(deal.zodiac_boss.data.commands[0].status, "pending")
		assert_eq(deal.hand.map(func(card): return card.unique_id), before_hand)
		assert_eq(deal.zodiac_boss.snapshot(), copy.zodiac_boss.snapshot())
		assert_eq(deal.discard_count, 0)
		assert_eq(deal.state, DealState.STATE_ACTIVE)
		assert_eq(deal.deck._rng.state, before_rng)
		assert_true(deal.physical_card_accounting_is_valid())
		deal.current_phase = 2
		deal.zodiac_boss.begin_phase(deal)
		assert_true(deal.zodiac_boss.data.commands.is_empty())

func test_snake_charms_resolve_consecutively_before_the_normal_turn_boundary() -> void:
	for level in [1, 2, 3]:
		var deal := _deal("snake", level)
		deal.zodiac_boss.begin_turn(1, deal.hand, deal)
		var stock_rng := deal.deck._rng.state
		for index in level:
			assert_eq(deal.zodiac_boss.data.commands.size(), index + 1)
			assert_eq(deal.zodiac_boss.data.commands.filter(func(command: Dictionary): return command.status == "pending").size(), 1)
			var command: Dictionary = deal.zodiac_boss.data.commands[-1]
			var selected: Array[CardData] = []
			for card in deal.hand:
				if card.unique_id in command.get("suggested_ids", [command.card_id]): selected.append(card)
			assert_false(selected.is_empty())
			var before := deal.zodiac_boss.snapshot()
			assert_false(deal.create_meld([]).ok)
			assert_eq(deal.zodiac_boss.snapshot(), before)
			var result: Dictionary
			if command.action == "discard": result = deal.discard_card(selected[0])
			elif command.action == "extension": result = deal.extend_meld(command.meld_id, selected)
			else: result = deal.create_meld(selected)
			assert_true(result.ok)
			assert_eq(command.status, "fulfilled")
			assert_eq(deal.discard_count, 0)
			assert_eq(deal.zodiac_boss.turn_serial, 1)
			assert_eq(deal.deck._rng.state, stock_rng)
			assert_eq(deal.state, DealState.STATE_ACTIVE)
			assert_true(deal.physical_card_accounting_is_valid())
			_restored(deal)
		assert_true(deal.zodiac_boss.data.commands.all(func(command: Dictionary): return command.status == "fulfilled"))
		assert_true(deal.discard_card(deal.hand[-1]).ok)
		assert_eq(deal.discard_count, 1)
		assert_eq(deal.zodiac_boss.turn_serial, 2)
		assert_eq(deal.zodiac_boss.data.commands.size(), 1)

func test_snake_wrong_discard_is_extra_and_punishes_the_charmed_card() -> void:
	for level in [1, 2, 3]:
		var deal := _deal("snake", level)
		deal.zodiac_boss.begin_turn(1, deal.hand, deal)
		var command: Dictionary = deal.zodiac_boss.data.commands[0]
		var wrong: CardData = deal.hand.filter(func(card: CardData): return card.unique_id != command.card_id)[0]
		var before_stock := deal.deck.draw_pile.size()
		var result := deal.discard_card(wrong)
		assert_true(result.ok and result.turn_continues and result.snake_charmed)
		assert_eq(command.status, "violated")
		assert_eq(deal.deck.discard_pile.size(), 2)
		assert_true(deal.deck.discard_pile.any(func(card: CardData): return card.unique_id == command.card_id))
		assert_eq(deal.deck.draw_pile.size(), before_stock)
		assert_eq(deal.discard_count, 0)
		assert_eq(deal.discard_history.filter(func(record): return record.kind == DiscardRecord.KIND_MANDATORY).size(), 0)
		assert_eq(deal.state, DealState.STATE_ACTIVE)
		assert_true(deal.physical_card_accounting_is_valid())

func test_snake_disobedience_destroys_the_whole_meld_containing_the_charmed_card() -> void:
	for specs in [[["9", "Spades"], ["9", "Hearts"], ["9", "Diamonds"]], [["9", "Spades"], ["9", "Hearts"], ["9", "Diamonds"], ["9", "Clubs"]], [["4", "Hearts"], ["5", "Hearts"], ["6", "Hearts"], ["7", "Hearts"]]]:
		var deal := _deal("snake", 3)
		var cards := _cards(deal, specs)
		deal.zodiac_boss.data.commands = [{"action": "discard", "card_id": cards[0].unique_id, "status": "pending"}]
		var wallet_before := deal.wallet.balance_vnd
		var result := deal.create_meld(cards)
		assert_true(result.ok)
		assert_eq(deal.zodiac_boss.data.commands[0].status, "violated")
		assert_true(deal.melds.is_empty())
		assert_true(cards.all(func(card: CardData): return deal.deck.discard_pile.has(card)))
		assert_eq(deal.deck.discard_pile.size(), cards.size())
		var loss: Dictionary = result.boss_events.filter(func(event: Dictionary): return event.action == "boss_discard_meld")[0]
		assert_eq(loss.card_ids.size(), cards.size())
		assert_eq(deal.wallet.balance_vnd - wallet_before, result.earned_vnd)
		assert_eq(deal.discard_count, 0)
		assert_eq(deal.state, DealState.STATE_ACTIVE)
		assert_true(deal.physical_card_accounting_is_valid())
		_restored(deal)

func test_snake_charmed_existing_meld_is_lost_when_the_drink_command_is_refused() -> void:
	var deal := _deal("snake", 3)
	var first := deal.create_meld(deal.hand.slice(0, 3))
	var owned := deal.get_meld(first.meld_id)
	var cards: Array[CardData] = owned.cards.duplicate()
	deal.set_current_drink(DrinkCatalog.NAU_DA)
	deal.zodiac_boss.begin_turn(1, deal.hand, deal)
	var command: Dictionary = deal.zodiac_boss.data.commands[0]
	assert_eq(command.action_name, "nau_da_return")
	assert_eq(command.meld_id, owned.meld_id)
	var result := deal.create_meld(deal.hand.slice(0, 3))
	assert_true(result.ok)
	assert_eq(command.status, "violated")
	assert_true(deal.get_meld(owned.meld_id) == null)
	assert_eq(deal.melds.size(), 1)
	assert_true(cards.all(func(card: CardData): return deal.deck.discard_pile.has(card)))
	assert_true(deal.current_drink_has_charge())
	assert_eq(deal.discard_count, 0)
	assert_eq(deal.state, DealState.STATE_ACTIVE)
	assert_true(deal.physical_card_accounting_is_valid())

func test_snake_cannot_be_bypassed_by_skipping_tra_da_or_ending_an_empty_hand() -> void:
	var deal := _deal("snake", 1)
	deal.set_current_drink(DrinkCatalog.TRA_DA)
	deal.zodiac_boss.begin_turn(1, deal.hand, deal)
	deal.tra_da_extra_discard_pending = true
	var command: Dictionary = deal.zodiac_boss.data.commands[0]
	var refusal := deal.end_turn_without_tra_da_extra()
	assert_true(refusal.ok and refusal.turn_continues)
	assert_eq(command.status, "violated")
	assert_true(deal.tra_da_extra_discard_pending)
	assert_eq(deal.discard_count, 0)
	assert_eq(deal.state, DealState.STATE_ACTIVE)
	assert_true(deal.physical_card_accounting_is_valid())
	assert_true(deal.end_turn_without_tra_da_extra().ok)
	assert_false(deal.tra_da_extra_discard_pending)
	assert_eq(deal.zodiac_boss.turn_serial, 2)
	deal = _deal("snake", 3)
	var made := deal.create_meld(deal.hand.slice(0, 3))
	var remaining: Array[CardData] = deal.hand.duplicate()
	deal.hand.clear()
	deal.move_to_recyclable_spent(remaining)
	deal.zodiac_boss.data.commands = [{"action": "drink", "action_name": "nau_da_return", "card_id": deal.melds[0].cards[0].unique_id, "meld_id": made.meld_id, "status": "pending"}]
	refusal = deal.end_empty_turn()
	assert_true(refusal.ok and refusal.turn_continues)
	assert_true(deal.melds.is_empty())
	assert_eq(deal.deck.discard_pile.size(), 3)
	assert_eq(deal.discard_count, 0)
	assert_eq(deal.state, DealState.STATE_ACTIVE)
	assert_true(deal.physical_card_accounting_is_valid())

func test_snake_moves_an_ignored_charmed_card_from_spent_to_discard() -> void:
	var deal := _deal("snake", 1)
	var card := deal.hand[-1]
	deal.zodiac_boss.data.commands = [{"action": "discard", "card_id": card.unique_id, "status": "pending"}]
	deal.hand.erase(card)
	deal.move_to_recyclable_spent([card])
	deal.zodiac_boss.after_action(deal, {"ok": true, "action": "sam_dua_selected"})
	assert_false(deal.recyclable_spent_cards.has(card))
	assert_true(deal.deck.discard_pile.has(card))
	assert_eq(deal.discard_count, 0)
	assert_eq(deal.state, DealState.STATE_ACTIVE)
	assert_true(deal.physical_card_accounting_is_valid())

func test_snake_old_queued_save_retains_only_the_first_live_charm() -> void:
	var deal := _deal("snake", 3)
	deal.zodiac_boss.data.commands = [{"action": "discard", "card_id": deal.hand[0].unique_id, "status": "fulfilled"}, {"action": "new_meld", "card_id": deal.hand[3].unique_id, "status": "pending"}, {"action": "discard", "card_id": deal.hand[-1].unique_id, "status": "pending"}]
	var saved := deal.snapshot_state()
	saved.zodiac_boss.data.erase("charm_version")
	var copy := DealState.new()
	copy.restore_snapshot(saved)
	assert_eq(copy.zodiac_boss.data.commands.size(), 2)
	assert_eq(copy.zodiac_boss.data.commands.filter(func(command: Dictionary): return command.status == "pending").size(), 1)
	assert_eq(copy.zodiac_boss.data.command_limit, 3)
	assert_true(copy.physical_card_accounting_is_valid())

func test_snake_obedience_and_disobedience_do_not_skip_or_add_mandatory_discard() -> void:
	for obey in [true, false]:
		var deal := _deal("snake", 3)
		var commanded := deal.hand[3]
		deal.zodiac_boss.data.commands = [{"action": "new_meld", "card_id": commanded.unique_id, "status": "pending"}]
		var result := deal.create_meld(deal.hand.slice(3, 6) if obey else deal.hand.slice(0, 3))
		assert_true(result.ok)
		assert_eq(deal.zodiac_boss.data.commands[0].status, "fulfilled" if obey else "violated")
		assert_eq(deal.deck.discard_pile.has(commanded), not obey)
		assert_eq(deal.state, DealState.STATE_ACTIVE)
		assert_eq(deal.discard_count, 0)
		assert_true(deal.physical_card_accounting_is_valid())
		_restored(deal)

func test_snake_valid_drink_target_command_and_wrong_target_sabotage() -> void:
	var deal := _deal("snake", 3)
	deal.set_current_drink(DrinkCatalog.DEN_DA)
	var discarded := deal.hand[-1]
	deal.boss_discard_card(discarded, "fixture")
	deal.zodiac_boss.begin_turn(1, deal.hand, deal)
	var command: Dictionary = deal.zodiac_boss.data.commands[0]
	assert_eq(command.action, "drink")
	assert_eq(command.action_name, "den_da_swap")
	var target: CardData
	for card in deal.hand:
		if card.unique_id == command.card_id: target = card
	var record: DiscardRecord
	for candidate in deal.discard_history:
		if candidate.card.unique_id == command.discard_card_id: record = candidate
	assert_true(deal.can_use_den_da(target, record))
	assert_true(deal.use_den_da(target, record).ok)
	assert_eq(command.status, "fulfilled")
	assert_eq(deal.state, DealState.STATE_ACTIVE)
	assert_eq(deal.discard_count, 0)
	assert_true(deal.physical_card_accounting_is_valid())


func test_preview_and_helper_are_pure_across_all_bosses_and_tiers() -> void:
	for id: String in ZodiacBossRule.RULES:
		for level in [1, 2, 3]:
			var deal := _deal(id, level)
			deal.zodiac_boss.begin_turn(1, deal.hand, deal)
			var boss_before := deal.zodiac_boss.snapshot()
			var deck_before := deal.deck._rng.state
			var wallet_before := deal.wallet.journal.duplicate(true)
			var cards: Array[CardData] = deal.hand.slice(0, mini(3, deal.hand.size()))
			deal.preview_new_meld_payout(cards, MeldRules.classify(cards))
			deal.queries.recommend_action()
			HandAdvice.analyze(deal)
			assert_eq(deal.zodiac_boss.snapshot(), boss_before)
			assert_eq(deal.deck._rng.state, deck_before)
			assert_eq(deal.wallet.journal, wallet_before)
			assert_true(deal.physical_card_accounting_is_valid())

func test_pig_committed_receipts_expose_siphon_and_return_without_extra_mutation() -> void:
	var deal := _deal("pig", 2)
	deal.zodiac_boss.data.target_vnd = 100_000
	var first := deal.create_meld(deal.hand.slice(0, 3))
	assert_eq(first.context.boss_transactions.size(), 1)
	assert_eq(first.context.boss_transactions[0].amount_vnd, -13_500)
	assert_eq(first.earned_vnd, 31_500)
	assert_eq(first.boss_wallet_entries, first.context.boss_transactions)
	var second := deal.create_meld(deal.hand.slice(0, 3))
	assert_eq(second.context.boss_transactions.size(), 2)
	assert_eq(second.context.boss_transactions[0].amount_vnd, -24_300)
	assert_eq(second.context.boss_transactions[1].amount_vnd, 37_800)
	assert_eq(deal.wallet.balance_vnd, 126_000)
	assert_true(deal._boss_wallet_pending.is_empty())

func test_mouse_drink_discard_response_owned_meld_and_exhaustion_recycles_without_player_bonus() -> void:
	var deal := _deal("rat", 2)
	deal.set_current_drink(DrinkCatalog.DEN_DA)
	var recovered := deal.hand[-2]
	deal.boss_discard_card(recovered, "fixture")
	var record := deal.discard_history[-1]
	var loose := deal.hand[-1]
	_top(deal, [["J", "Hearts"], ["J", "Diamonds"], ["A", "Clubs"]])
	var result := deal.use_den_da(loose, record)
	assert_true(result.ok)
	assert_eq(deal.boss_melds.size(), 1)
	assert_eq(result.boss_wallet_entries.size(), 1)
	assert_eq(result.boss_wallet_entries[0].amount_vnd, -99_000)
	assert_eq(deal.phase_metrics.new_phom_count, 0)
	assert_true(deal.physical_card_accounting_is_valid())
	HandAdvice.signature(deal)
	var copy := _restored(deal)
	for current: DealState in [deal, copy]:
		var before := current.wallet.balance_vnd
		var stock: Array[CardData] = current.deck.draw_pile.duplicate()
		current.deck.draw_pile.clear()
		current.move_to_recyclable_spent(stock)
		current.hand.append_array(current.deck.draw(1))
		assert_eq(current.wallet.balance_vnd, before)
		assert_true(current.boss_melds.is_empty())
		assert_true(current.physical_card_accounting_is_valid())

func test_tiger_empty_hand_can_end_turn_without_fake_physical_discard() -> void:
	for level in [2, 3]:
		var deal := _deal("tiger", level)
		var same: Array[CardData] = []
		var other: Array[CardData] = []
		for card in deal.hand:
			if card.rank == "9": same.append(card)
			else: other.append(card)
		deal.hand.assign(same)
		deal.move_to_recyclable_spent(other)
		deal.zodiac_boss.begin_turn(1, deal.hand, deal)
		assert_true(deal.hand.is_empty())
		var count := deal.discard_history.size()
		var result := deal.end_empty_turn()
		assert_true(result.ok)
		assert_eq(deal.discard_count, 1)
		assert_gt(deal.hand.size(), 0)
		assert_false(deal.end_empty_turn().ok)
		assert_eq(deal.discard_history.filter(func(r): return r.kind == DiscardRecord.KIND_MANDATORY).size(), 0)
		assert_true(deal.discard_history.size() >= count)
		assert_true(deal.physical_card_accounting_is_valid())

func test_snake_wrong_drink_target_sabotages_exact_command_without_ending_turn() -> void:
	var deal := _deal("snake", 3)
	deal.set_current_drink(DrinkCatalog.DEN_DA)
	deal.boss_discard_card(deal.hand[-1], "fixture")
	deal.zodiac_boss.begin_turn(1, deal.hand, deal)
	var command: Dictionary = deal.zodiac_boss.data.commands[0]
	var record: DiscardRecord
	for candidate in deal.discard_history:
		if candidate.card.unique_id == command.discard_card_id: record = candidate
	var wrong: CardData
	for card in deal.hand:
		if card.unique_id != command.card_id and deal.can_use_den_da(card, record): wrong = card; break
	assert_true(wrong != null)
	var result := deal.use_den_da(wrong, record)
	assert_true(result.ok)
	assert_eq(command.status, "violated")
	assert_true(deal.deck.discard_pile.any(func(card): return card.unique_id == command.card_id))
	assert_eq(deal.discard_count, 0)
	assert_eq(deal.state, DealState.STATE_ACTIVE)
	assert_true(deal.physical_card_accounting_is_valid())

func test_ox_drink_returned_card_has_fresh_burden_and_phase_retains_carried_card() -> void:
	var deal := _deal("ox", 2)
	deal._deduct_turn_deadwood()
	var old := deal.hand[-1]
	var made := deal.create_meld(deal.hand.slice(0, 3))
	var extra := _cards(deal, [["7", "Hearts"]])[0]
	deal.extend_meld(made.meld_id, [extra])
	deal.set_current_drink(DrinkCatalog.NUOC_VOI)
	assert_true(deal.use_nuoc_voi(made.meld_id, extra).ok)
	assert_false(deal.zodiac_boss.data.burden_age.has(extra.unique_id))
	deal.current_phase = 2
	deal.zodiac_boss.begin_phase(deal)
	deal._deduct_turn_deadwood()
	assert_eq(deal.zodiac_boss.data.burden_age[old.unique_id], 2)
	assert_eq(deal.zodiac_boss.data.burden_age[extra.unique_id], 1)
	assert_true(deal.physical_card_accounting_is_valid())


func test_mouse_can_use_real_borrowed_cards_in_multi_card_hostile_extension() -> void:
	var deal := _deal("rat", 2)
	var made := deal.create_meld(deal.hand.slice(0, 3))
	var added := _cards(deal, [["7", "Hearts"]])[0]
	_top(deal, [["8", "Hearts"], ["A", "Clubs"], ["10", "Diamonds"]])
	deal.boss_discard_card(added, "fixture")
	var rng := deal.deck._rng.state
	deal.zodiac_boss.after_discard(deal, deal.discard_history[-1])
	assert_eq(deal.zodiac_boss.data.hostile_result.action, "boss_extension")
	assert_eq(deal.zodiac_boss.data.hostile_result.card_ids.size(), 2)
	assert_eq(deal.get_meld(made.meld_id).cards.size(), 5)
	assert_true(deal.boss_borrowed_cards.is_empty())
	assert_eq(deal.phase_metrics.extension_count, 0)
	assert_eq(deal.deck._rng.state, rng)
	assert_true(deal.physical_card_accounting_is_valid())

func test_mouse_can_commit_a_meld_from_borrowed_stock_cards() -> void:
	var deal := _deal("rat", 2)
	_top(deal, [["A", "Clubs"], ["A", "Spades"], ["A", "Diamonds"]])
	deal.boss_discard_card(deal.hand[-1], "fixture")
	deal.zodiac_boss.after_discard(deal, deal.discard_history[-1])
	assert_eq(deal.boss_melds.size(), 1)
	assert_eq(deal.wallet.balance_vnd, -9000)
	assert_true(deal.boss_borrowed_cards.is_empty())
	assert_eq(deal.boss_melds[0].cards.size(), 3)
	assert_true(deal.physical_card_accounting_is_valid())
