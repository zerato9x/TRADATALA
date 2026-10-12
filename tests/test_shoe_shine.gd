@tool
extends McpTestSuite

class RefusingCard extends CardData:
	func apply_rank(_rank: String, _index: int) -> void: pass
	func apply_suit(_suit: String) -> void: pass

class OutcomeRelics extends RelicRuntime:
	var targets: Dictionary = {}
	var calls: Array[Dictionary] = []
	func modify_shoe_shine_outcome(card: Dictionary, kind: String, allowed: Array, rolled: String) -> String:
		calls.append({"id": card.unique_id, "kind": kind, "allowed": allowed.duplicate(), "rolled": rolled})
		return targets.get(card.unique_id, rolled)

func suite_name() -> String:
	return "shoe_shine"

func fixture(seed_text: String = "SHOE-PAIR") -> Dictionary:
	var deal := DealState.new()
	var events := EventManager.new()
	CampaignNpcCatalog.register_initial_npcs(events)
	var campaign := CampaignManager.new(deal.wallet, events)
	campaign.drink_manager.progress = DrinkProgress.new("")
	campaign.bind_deal(deal)
	campaign.start_campaign(true, seed_text)
	campaign.current_day_index = 1
	campaign._begin_current_day()
	deal.start_deal(campaign.seed_for("deal"))
	deal.wallet.reset(1_000_000_000)
	return {"campaign": campaign, "deal": deal, "shoe": campaign.shoe_shine,
		"cards": campaign.gieo_que.persistent_deck, "wallet": deal.wallet}

func commit_pair(f: Dictionary) -> void:
	assert_true(f.shoe.choose_card(f.cards[0].unique_id).ok)
	assert_true(f.shoe.choose_card(f.cards[1].unique_id).ok)

func printing(f: Dictionary) -> Array:
	return f.shoe.selected_cards().map(func(card): return card.run_value_snapshot().duplicate(true))

func test_roster_is_tuesday_onward_and_starter_only() -> void:
	var f := fixture()
	for day in range(8):
		for slot in range(4):
			var event: EventInstance = f.campaign.event_manager.build_event(slot, {"day_index": day})
			assert_eq(event.participants.any(func(npc): return npc.id == "danh_giay"), day >= 1 and slot == EventManager.EventSlot.STARTER)
	assert_false(f.campaign.event_manager.build_event(0).participants.any(func(npc): return npc.id == "danh_giay"))
	f.campaign.current_day_index = 0
	f.campaign._begin_current_day()
	assert_false(f.shoe.visit_started)
	assert_false(f.shoe.choose_card(f.cards[0].unique_id).ok)
	assert_false(f.shoe.reroll_rank().ok)
	assert_false(f.shoe.reroll_suit().ok)

func test_stale_ui_cannot_bypass_phase_day_or_failed_run() -> void:
	var f := fixture()
	commit_pair(f)
	for phase in [CampaignManager.CampaignPhase.MORNING_DEAL, CampaignManager.CampaignPhase.MORNING_EVENT, CampaignManager.CampaignPhase.NOON_EVENT, CampaignManager.CampaignPhase.AFTERNOON_EVENT, CampaignManager.CampaignPhase.EVENING_DEAL]:
		f.campaign.current_phase = phase
		f.shoe.begin_event(EventManager.EventSlot.STARTER)
		assert_false(f.shoe.is_active())
		assert_false(f.shoe.reroll_rank().ok)
		assert_false(f.shoe.reroll_suit().ok)
	f.campaign.current_phase = CampaignManager.CampaignPhase.STARTER_EVENT
	f.campaign.current_day_index = 2
	assert_false(f.shoe.is_active())
	f.campaign.current_day_index = 1
	f.campaign.run_failed = true
	assert_false(f.shoe.is_active())

func test_complete_pair_required_before_payment_or_rng() -> void:
	var f := fixture()
	assert_true(f.shoe.choose_card(f.cards[0].unique_id).ok)
	var state: Dictionary = f.shoe.run_snapshot().duplicate(true)
	var rng: int = f.shoe.run_rng_state()
	assert_eq(f.shoe.reroll_rank().error, "SHOE_ERROR_PAIR")
	assert_eq(f.shoe.reroll_suit().error, "SHOE_ERROR_PAIR")
	assert_eq(f.shoe.run_snapshot(), state)
	assert_eq(f.shoe.run_rng_state(), rng)
	assert_true(f.wallet.journal.is_empty())
	assert_true(f.shoe.choose_card(f.cards[1].unique_id).ok)
	assert_true(f.shoe.can_reroll("rank"))
	assert_true(f.shoe.can_reroll("suit"))

func test_pair_is_irrevocable_and_missing_card_does_not_free_a_slot() -> void:
	var f := fixture()
	commit_pair(f)
	var ids: Array = f.shoe.selected_card_ids.duplicate()
	assert_false(f.shoe.choose_card(ids[0]).ok)
	assert_false(f.shoe.choose_card(f.cards[2].unique_id).ok)
	f.shoe.begin_event(EventManager.EventSlot.STARTER)
	f.shoe.bind_deck(f.cards)
	assert_eq(f.shoe.selected_card_ids, ids)
	assert_true(f.shoe.eligible_cards().is_empty())
	f.cards.remove_at(1)
	assert_eq(f.shoe.reroll_rank().error, "SHOE_ERROR_MISSING")
	assert_false(f.shoe.choose_card(f.cards[2].unique_id).ok)
	assert_eq(f.shoe.selected_card_ids, ids)

func test_same_printing_still_selects_distinct_physical_cards() -> void:
	var f := fixture()
	f.cards[1].apply_rank(f.cards[0].rank, f.cards[0].rank_index)
	f.cards[1].apply_suit(f.cards[0].suit)
	commit_pair(f)
	assert_ne(f.shoe.selected_card_ids[0], f.shoe.selected_card_ids[1])

func test_pair_draws_independent_results_and_charges_once() -> void:
	for kind in ["rank", "suit"]:
		var f := fixture()
		commit_pair(f)
		f.shoe.set_seed_value(42)
		var probe := RandomNumberGenerator.new()
		probe.seed = 42
		var before := printing(f)
		var expected: Array[String] = []
		for card in f.shoe.selected_cards():
			var pool := DeckManager.RANKS.duplicate() if kind == "rank" else DeckManager.SUITS.duplicate()
			pool.erase(card.rank if kind == "rank" else card.suit)
			expected.append(pool[probe.randi_range(0, pool.size() - 1)])
		var result: Dictionary = f.shoe.reroll_rank() if kind == "rank" else f.shoe.reroll_suit()
		assert_true(result.ok)
		assert_eq(result.results.size(), 2)
		for i in 2:
			assert_eq(result.results[i].card_id, f.cards[i].unique_id)
			assert_eq(result.results[i].after, f.cards[i].persuasion_fingerprint())
			assert_eq(f.cards[i].rank if kind == "rank" else f.cards[i].suit, expected[i])
			assert_ne(f.cards[i].rank if kind == "rank" else f.cards[i].suit, before[i].rank if kind == "rank" else before[i].suit)
			if kind == "rank":
				assert_eq(f.cards[i].suit, before[i].suit)
				assert_eq(f.cards[i].rank_index, DeckManager.RANKS.find(expected[i]) + 1)
				assert_eq(f.cards[i].base_value, f.cards[i].rank_index)
			else:
				assert_eq(f.cards[i].rank, before[i].rank)
				assert_eq(f.cards[i].rank_index, before[i].rank_index)
				assert_eq(f.cards[i].base_value, before[i].base_value)
		assert_eq(f.shoe.run_rng_state(), probe.state)
		assert_eq(result.cost_vnd, 50_000 if kind == "rank" else 25_000)
		assert_eq(f.wallet.balance_vnd, 1_000_000_000 - int(result.cost_vnd))
		assert_eq(f.wallet.journal.size(), 1)
		assert_eq(f.wallet.journal[0].reason, "shoe_reroll_" + kind)
		assert_eq(f.campaign.activities[-1].changes, result.results)

func test_outcome_relic_hook_receives_each_card_separately() -> void:
	var f := fixture()
	commit_pair(f)
	var relics := OutcomeRelics.new()
	relics.targets = {f.cards[0].unique_id: "K", f.cards[1].unique_id: "Q"}
	f.campaign.relic_shop.runtime = relics
	assert_true(f.shoe.reroll_rank().ok)
	assert_eq([f.cards[0].rank, f.cards[1].rank], ["K", "Q"])
	assert_eq(relics.calls.size(), 2)
	for i in 2:
		assert_eq(relics.calls[i].id, f.cards[i].unique_id)
		assert_eq(relics.calls[i].kind, "rank")
		assert_eq(relics.calls[i].allowed.size(), 12)
	# Independent results may legitimately match each other.
	relics.targets = {f.cards[0].unique_id: "J", f.cards[1].unique_id: "J"}
	assert_true(f.shoe.reroll_rank().ok)
	assert_eq([f.cards[0].rank, f.cards[1].rank], ["J", "J"])
	relics.targets = {f.cards[0].unique_id: "Hearts", f.cards[1].unique_id: "Diamonds"}
	assert_true(f.shoe.reroll_suit().ok)
	assert_eq([f.cards[0].suit, f.cards[1].suit], ["Hearts", "Diamonds"])

func test_invalid_second_relic_result_rolls_back_entire_pair() -> void:
	var f := fixture()
	commit_pair(f)
	var relics := OutcomeRelics.new()
	relics.targets = {f.cards[0].unique_id: "K", f.cards[1].unique_id: "INVALID"}
	f.campaign.relic_shop.runtime = relics
	var before := printing(f)
	var state: Dictionary = f.shoe.run_snapshot().duplicate(true)
	var rng: int = f.shoe.run_rng_state()
	assert_false(f.shoe.reroll_rank().ok)
	assert_eq(printing(f), before)
	assert_eq(f.shoe.run_snapshot(), state)
	assert_eq(f.shoe.run_rng_state(), rng)
	assert_true(f.wallet.journal.is_empty())
	assert_eq(f.wallet.balance_vnd, 1_000_000_000)

func test_prices_scale_by_debt_difficulty_and_round_sensibly() -> void:
	var f := fixture()
	for day in range(1, 7):
		f.campaign.current_day_index = day
		f.campaign._begin_current_day()
		assert_eq(f.shoe.rank_cost(), int(CampaignConfig.DAYS[day].required_vnd) / 10)
		assert_eq(f.shoe.suit_cost(), int(CampaignConfig.DAYS[day].required_vnd) / 20)
	f.campaign.difficulty = 3
	f.campaign.campaign_days = CampaignConfig.day_definitions(3)
	f.campaign.current_day_index = 1
	f.campaign._begin_current_day()
	assert_eq([f.shoe.rank_cost(), f.shoe.suit_cost()], [200_000, 100_000])
	assert_eq(ShoeShineConfig.initial_cost("rank", 500_001), 50_500)
	assert_eq(ShoeShineConfig.initial_cost("suit", 500_001), 25_500)
	assert_eq(ShoeShineConfig.initial_cost("rank", 0), 25_000)
	assert_eq(ShoeShineConfig.initial_cost("suit", 0), 15_000)

func test_service_curves_escalate_independently_once_per_pair() -> void:
	for kind in ["rank", "suit"]:
		var f := fixture()
		commit_pair(f)
		var price := 50_000 if kind == "rank" else 25_000
		for i in 12:
			assert_eq(f.shoe.rank_cost() if kind == "rank" else f.shoe.suit_cost(), price)
			var result: Dictionary = f.shoe.reroll_rank() if kind == "rank" else f.shoe.reroll_suit()
			assert_true(result.ok)
			assert_eq(result.results.size(), 2)
			assert_eq(f.shoe.rank_rerolls if kind == "rank" else f.shoe.suit_rerolls, i + 1)
			assert_eq(f.shoe.suit_cost() if kind == "rank" else f.shoe.rank_cost(), 25_000 if kind == "rank" else 50_000)
			price *= 2

func test_wallet_and_reopening_never_reprice_or_consume_rng() -> void:
	var f := fixture()
	commit_pair(f)
	assert_true(f.shoe.reroll_rank().ok)
	var state: Dictionary = f.shoe.run_snapshot().duplicate(true)
	var rng: int = f.shoe.run_rng_state()
	for balance in [0, 25_000, 1_000_000_000]:
		f.wallet.reset(balance)
		f.shoe.begin_day(1, f.cards, 9_000_000)
		f.shoe.begin_event(EventManager.EventSlot.STARTER)
		assert_eq(f.shoe.run_snapshot(), state)
		assert_eq(f.shoe.run_rng_state(), rng)

func test_new_day_resets_pair_and_quotes_preserving_printing() -> void:
	var f := fixture()
	commit_pair(f)
	assert_true(f.shoe.reroll_rank().ok)
	var before := printing(f)
	f.campaign.current_day_index = 2
	f.campaign._begin_current_day()
	assert_true(f.shoe.selected_card_ids.is_empty())
	assert_eq([f.shoe.rank_rerolls, f.shoe.suit_rerolls], [0, 0])
	assert_eq([f.shoe.rank_cost(), f.shoe.suit_cost()], [100_000, 50_000])
	commit_pair(f)
	assert_eq(printing(f), before)

func test_insufficient_funds_is_inert_and_exact_balance_pays_once() -> void:
	var f := fixture()
	commit_pair(f)
	f.wallet.reset(49_999)
	var before := printing(f)
	var rng: int = f.shoe.run_rng_state()
	assert_eq(f.shoe.reroll_rank().error, "SHOE_ERROR_FUNDS")
	assert_eq(printing(f), before)
	assert_eq(f.shoe.run_rng_state(), rng)
	assert_eq(f.wallet.balance_vnd, 49_999)
	assert_true(f.wallet.journal.is_empty())
	f.wallet.reset(50_000)
	assert_true(f.shoe.reroll_rank().ok)
	assert_eq(f.wallet.balance_vnd, 0)
	assert_eq(f.wallet.journal.size(), 1)

func test_rejected_second_mutation_restores_both_cards_and_signals() -> void:
	var f := fixture()
	var original: CardData = f.cards[1]
	f.cards[1] = RefusingCard.new(original.unique_id, original.rank, original.rank_index, original.suit, original.base_value)
	commit_pair(f)
	var before := printing(f)
	var state: Dictionary = f.shoe.run_snapshot().duplicate(true)
	var rng: int = f.shoe.run_rng_state()
	var signals := [0]
	var listener := func(_id: String, _revision: int, _kind: String): signals[0] += 1
	f.cards[0].permanent_changed.connect(listener)
	assert_false(f.shoe.reroll_rank().ok)
	assert_false(f.shoe.reroll_suit().ok)
	assert_eq(printing(f), before)
	assert_eq(f.shoe.run_snapshot(), state)
	assert_eq(f.shoe.run_rng_state(), rng)
	assert_eq(signals[0], 0)
	assert_eq(f.wallet.balance_vnd, 1_000_000_000)
	assert_true(f.wallet.journal.is_empty())
	f.cards[0].permanent_changed.disconnect(listener)

func test_wallet_observers_see_complete_pair_and_cannot_reenter() -> void:
	var f := fixture()
	commit_pair(f)
	var calls := [0]
	var listener := func(_a: int, _b: int, _delta: int, reason: String):
		if reason != "shoe_reroll_rank": return
		calls[0] += 1
		assert_eq(f.shoe.rank_rerolls, 1)
		assert_eq(f.shoe.rank_cost(), 100_000)
		for i in 2: assert_eq(f.shoe.last_reroll.results[i].after, f.cards[i].persuasion_fingerprint())
		assert_false(f.shoe.reroll_rank().ok)
		assert_false(f.shoe.choose_card(f.cards[2].unique_id).ok)
	f.wallet.balance_changed.connect(listener)
	assert_true(f.shoe.reroll_rank().ok)
	f.wallet.balance_changed.disconnect(listener)
	assert_eq(calls[0], 1)
	assert_eq(f.wallet.journal.size(), 1)

func test_all_permanent_metadata_and_physical_ids_are_preserved() -> void:
	for properties in [[4, false, false], [-5, false, false], [3, true, false], [-2, false, true], [6, true, true]]:
		var f := fixture()
		commit_pair(f)
		var ids: Array = f.cards.map(func(c): return c.unique_id)
		for card in f.shoe.selected_cards():
			card.fortune = properties[0]
			card.liquid = properties[1]
			card.negative = properties[2]
			card.shiny = true
			card.enhancements.assign(["future_property"])
			card.value_modifiers.assign([5, -2])
		var before: Array = f.shoe.selected_cards().map(func(card): return card.persuasion_fingerprint())
		assert_true(f.shoe.reroll_rank().ok)
		assert_true(f.shoe.reroll_suit().ok)
		for i in 2:
			var after: Dictionary = f.cards[i].persuasion_fingerprint()
			for key in ["rank", "rank_index", "base_value", "suit"]:
				before[i].erase(key)
				after.erase(key)
			assert_eq(after, before[i])
			if f.cards[i].is_glitch(): assert_eq(f.cards[i].meld_rank_options().size(), 13)
		assert_eq(f.cards.map(func(c): return c.unique_id), ids)

func test_sealed_second_card_blocks_entire_pair_without_payment() -> void:
	var f := fixture()
	f.cards[1].transformation_locked = true
	assert_false(f.shoe.choose_card(f.cards[1].unique_id).ok)
	f.cards[1].transformation_locked = false
	commit_pair(f)
	f.cards[1].transformation_locked = true
	var rng: int = f.shoe.run_rng_state()
	assert_eq(f.shoe.reroll_rank().error, "SHOE_ERROR_SEALED")
	assert_eq(f.shoe.reroll_suit().error, "SHOE_ERROR_SEALED")
	assert_eq(f.shoe.run_rng_state(), rng)
	assert_true(f.wallet.journal.is_empty())

func test_seeded_pair_results_do_not_contaminate_other_streams() -> void:
	var a := fixture()
	var b := fixture()
	var streams: Array = [a.deal.deck._rng.state, a.campaign.gieo_que.run_rng_state(), a.campaign.lottery.run_rng_state(), a.campaign.relic_shop.run_rng_state(), a.campaign.zodiac._rng.state]
	commit_pair(a)
	commit_pair(b)
	for _i in 8:
		assert_eq(a.shoe.reroll_rank(), b.shoe.reroll_rank())
		assert_eq(a.shoe.reroll_suit(), b.shoe.reroll_suit())
	assert_eq([a.deal.deck._rng.state, a.campaign.gieo_que.run_rng_state(), a.campaign.lottery.run_rng_state(), a.campaign.relic_shop.run_rng_state(), a.campaign.zodiac._rng.state], streams)

func test_file_resume_keeps_pair_quotes_and_exact_next_outcomes() -> void:
	var f := fixture()
	commit_pair(f)
	f.cards[0].fortune = -4
	f.cards[0].liquid = true
	f.cards[1].negative = true
	for _i in 3: assert_true(f.shoe.reroll_rank().ok)
	for _i in 2: assert_true(f.shoe.reroll_suit().ok)
	var state: Dictionary = f.shoe.run_snapshot().duplicate(true)
	var balance: int = f.wallet.balance_vnd
	var save := RunSave.new("user://shoe-pair-test.save")
	assert_true(save.save_run(f.campaign, f.deal), save.error)
	var expected_rank: Dictionary = f.shoe.reroll_rank()
	var expected_suit: Dictionary = f.shoe.reroll_suit()
	var resumed := fixture("OTHER-SEED")
	assert_true(save.restore(save.load_run(), resumed.campaign, resumed.deal))
	assert_eq(resumed.shoe.run_snapshot(), state)
	assert_eq(resumed.wallet.balance_vnd, balance)
	assert_false(resumed.shoe.choose_card(resumed.cards[2].unique_id).ok)
	assert_eq(resumed.shoe.reroll_rank(), expected_rank)
	assert_eq(resumed.shoe.reroll_suit(), expected_suit)

func test_old_quotes_migrate_without_resetting_committed_cards_or_rng() -> void:
	var f := fixture()
	commit_pair(f)
	assert_true(f.shoe.reroll_rank().ok)
	var data: Dictionary = f.shoe.run_snapshot().duplicate(true)
	data.erase("price_version")
	data.next_rank_cost_vnd = 20_000
	data.next_suit_cost_vnd = 5_000
	data.price_curve = {"rank": {"base_vnd": 5_000, "target_percent": 2, "growth": 2}, "suit": {"base_vnd": 2_500, "target_percent": 1, "growth": 2}}
	var rng: int = f.shoe.run_rng_state()
	f.shoe.restore_run_snapshot(data)
	f.shoe.bind_deck(f.cards)
	assert_eq(f.shoe.selected_card_ids, data.selected_card_ids)
	assert_eq(f.shoe.rank_rerolls, 1)
	assert_eq([f.shoe.rank_cost(), f.shoe.suit_cost()], [100_000, 25_000])
	assert_eq(f.shoe.price_curve, ShoeShineConfig.SERVICES)
	assert_eq(f.shoe.run_rng_state(), rng)

func test_partial_selection_resumes_without_unlocking_work() -> void:
	var f := fixture()
	assert_true(f.shoe.choose_card(f.cards[0].unique_id).ok)
	var rng: int = f.shoe.run_rng_state()
	var save := RunSave.new("user://shoe-partial-pair.save")
	assert_true(save.save_run(f.campaign, f.deal))
	var resumed := fixture("OTHER-PARTIAL-SEED")
	assert_true(save.restore(save.load_run(), resumed.campaign, resumed.deal))
	assert_eq(resumed.shoe.selected_card_ids, [f.cards[0].unique_id])
	assert_eq(resumed.shoe.run_rng_state(), rng)
	assert_eq(resumed.shoe.reroll_rank().error, "SHOE_ERROR_PAIR")
	assert_false(resumed.shoe.choose_card(f.cards[0].unique_id).ok)
	assert_true(resumed.shoe.choose_card(resumed.shoe.cards()[1].unique_id).ok)
	assert_true(resumed.shoe.reroll_rank().ok)

func test_old_monday_save_closes_service_but_preserves_card_printing() -> void:
	var f := fixture()
	commit_pair(f)
	assert_true(f.shoe.reroll_rank().ok)
	var before := printing(f)
	var save := RunSave.new("user://shoe-monday-test.save")
	var data := save.capture(f.campaign, f.deal)
	data.campaign.current_day_index = 0
	data.event.context.day_index = 0
	data.event.context.day = CampaignConfig.DAYS[0].duplicate(true)
	data.shoe._day_index = 0
	assert_true(save.restore(data, f.campaign, f.deal))
	assert_false(f.shoe.is_active())
	assert_false(f.shoe.reroll_rank().ok)
	assert_false(f.campaign.event_manager.current_event.participants.any(func(npc): return npc.id == "danh_giay"))
	assert_eq(printing(f), before)

func test_no_hard_reroll_limit_and_saturated_prices_are_safe() -> void:
	var f := fixture()
	commit_pair(f)
	f.wallet.reset(1_000_000_000_000_000_000)
	for _i in 60: assert_true(f.shoe.reroll_rank().ok)
	assert_eq(f.shoe.rank_rerolls, 60)
	assert_eq(f.shoe.rank_cost(), ShoeShineConfig.MAX_COST_VND)
	assert_eq(f.shoe.suit_cost(), 25_000)

func test_reset_and_restore_never_clear_bound_canonical_deck() -> void:
	var f := fixture()
	var ids: Array = f.cards.map(func(card): return card.unique_id)
	f.shoe.reset_run()
	assert_eq(f.campaign.gieo_que.persistent_deck.map(func(card): return card.unique_id), ids)
	f.shoe.bind_deck(f.cards)
	f.shoe.restore_run_snapshot({})
	assert_eq(f.campaign.gieo_que.persistent_deck.map(func(card): return card.unique_id), ids)
