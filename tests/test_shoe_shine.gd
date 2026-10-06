@tool
extends McpTestSuite

class RefusingCard extends CardData:
	func apply_rank(_rank: String, _index: int) -> void: pass
	func apply_suit(_suit: String) -> void: pass

func suite_name() -> String:
	return "shoe_shine"

func fixture(seed_text: String = "SHOE-IDENTITY") -> Dictionary:
	var deal := DealState.new()
	var events := EventManager.new()
	CampaignNpcCatalog.register_initial_npcs(events)
	var campaign := CampaignManager.new(deal.wallet, events)
	campaign.drink_manager.progress = DrinkProgress.new("")
	campaign.bind_deal(deal)
	campaign.start_campaign(true, seed_text)
	deal.start_deal(campaign.seed_for("deal"))
	deal.wallet.reset(1_000_000_000)
	return {"campaign": campaign, "deal": deal, "shoe": campaign.shoe_shine,
		"cards": campaign.gieo_que.persistent_deck, "wallet": deal.wallet}

func test_roster_and_authority_are_starter_only() -> void:
	var f := fixture()
	for slot in range(4):
		var event: EventInstance = f.campaign.event_manager.build_event(slot)
		assert_eq(event.participants.any(func(npc): return npc.id == "danh_giay"), slot == EventManager.EventSlot.STARTER)
	assert_true(f.shoe.choose_card(f.cards[0].unique_id).ok)
	for phase in [CampaignManager.CampaignPhase.MORNING_DEAL, CampaignManager.CampaignPhase.MORNING_EVENT, CampaignManager.CampaignPhase.NOON_EVENT, CampaignManager.CampaignPhase.AFTERNOON_EVENT, CampaignManager.CampaignPhase.EVENING_DEAL]:
		f.campaign.current_phase = phase
		f.shoe.begin_event(EventManager.EventSlot.STARTER)
		assert_false(f.shoe.is_active(), "A stale panel cannot bypass the campaign phase.")
		assert_false(f.shoe.reroll_rank(f.cards[0].unique_id).ok)
		assert_false(f.shoe.reroll_suit(f.cards[0].unique_id).ok)
		assert_false(f.shoe.choose_card(f.cards[1].unique_id).ok)

func test_one_card_is_enough_without_selecting_second() -> void:
	var f := fixture()
	var id: String = f.cards[7].unique_id
	assert_true(f.shoe.choose_card(id).ok)
	assert_true(f.shoe.reroll_rank(id).ok)
	assert_true(f.shoe.reroll_suit(id).ok)
	assert_eq(f.shoe.selected_card_ids, [id])
	assert_eq(f.shoe.selected_cards()[0], f.cards[7])

func test_two_ids_are_irrevocable_and_third_is_rejected() -> void:
	var f := fixture()
	var a: String = f.cards[0].unique_id
	var b: String = f.cards[1].unique_id
	assert_true(f.shoe.choose_card(a).ok)
	assert_false(f.shoe.choose_card(a).ok)
	assert_true(f.shoe.choose_card(b).ok)
	assert_false(f.shoe.choose_card(f.cards[2].unique_id).ok)
	f.shoe.begin_event(EventManager.EventSlot.STARTER)
	f.shoe.bind_deck(f.cards)
	assert_eq(f.shoe.selected_card_ids, [a, b])
	assert_true(f.shoe.eligible_cards().is_empty())
	assert_false(f.shoe.reroll_rank(f.cards[2].unique_id).ok)

func test_reopen_does_not_spend_rng_or_reset_selection_or_prices() -> void:
	var f := fixture()
	var id: String = f.cards[0].unique_id
	f.shoe.choose_card(id)
	f.shoe.reroll_rank(id)
	var state: Dictionary = f.shoe.run_snapshot().duplicate(true)
	var rng: int = f.shoe.run_rng_state()
	for _i in 5:
		f.shoe.begin_day(0, f.cards, 9_000_000)
		f.shoe.begin_event(EventManager.EventSlot.STARTER)
		assert_eq(f.shoe.run_snapshot(), state)
		assert_eq(f.shoe.run_rng_state(), rng)

func test_same_printing_still_selects_distinct_physical_cards() -> void:
	var f := fixture()
	f.cards[1].apply_rank(f.cards[0].rank, f.cards[0].rank_index)
	f.cards[1].apply_suit(f.cards[0].suit)
	assert_true(f.shoe.choose_card(f.cards[0].unique_id).ok)
	assert_true(f.shoe.choose_card(f.cards[1].unique_id).ok)
	assert_ne(f.shoe.selected_card_ids[0], f.shoe.selected_card_ids[1])

func test_rank_changes_canonical_rank_value_and_charges_once() -> void:
	var f := fixture()
	var card: CardData = f.cards[6]
	f.shoe.choose_card(card.unique_id)
	var before := card.persuasion_fingerprint()
	var balance: int = f.wallet.balance_vnd
	assert_true(f.shoe.reroll_rank(card.unique_id).ok)
	assert_ne(card.rank, before.rank)
	assert_eq(card.suit, before.suit)
	assert_eq(card.rank_index, DeckManager.RANKS.find(card.rank) + 1)
	assert_eq(card.base_value, card.rank_index)
	assert_eq(f.wallet.balance_vnd, balance - 5_000)
	assert_eq(f.wallet.journal[-1].reason, "shoe_reroll_rank")

func test_suit_changes_only_canonical_suit() -> void:
	var f := fixture()
	var card: CardData = f.cards[6]
	f.shoe.choose_card(card.unique_id)
	var before := card.persuasion_fingerprint()
	assert_true(f.shoe.reroll_suit(card.unique_id).ok)
	assert_ne(card.suit, before.suit)
	assert_eq(card.rank, before.rank)
	assert_eq(card.rank_index, before.rank_index)
	assert_eq(card.base_value, before.base_value)
	assert_eq(f.wallet.journal[-1].amount_vnd, -2_500)

func test_repeated_rank_changes_and_escalates_independently() -> void:
	var f := fixture()
	var card: CardData = f.cards[0]
	f.shoe.choose_card(card.unique_id)
	var price := 5_000
	for index in 12:
		var before := card.rank
		assert_eq(f.shoe.rank_cost(), price)
		assert_eq(f.shoe.suit_cost(), 2_500)
		assert_true(f.shoe.reroll_rank(card.unique_id).ok)
		assert_ne(card.rank, before)
		assert_eq(f.shoe.rank_rerolls, index + 1)
		price *= 2

func test_repeated_suit_changes_and_escalates_independently() -> void:
	var f := fixture()
	var card: CardData = f.cards[0]
	f.shoe.choose_card(card.unique_id)
	var price := 2_500
	for index in 12:
		var before := card.suit
		assert_eq(f.shoe.suit_cost(), price)
		assert_eq(f.shoe.rank_cost(), 5_000)
		assert_true(f.shoe.reroll_suit(card.unique_id).ok)
		assert_ne(card.suit, before)
		assert_eq(f.shoe.suit_rerolls, index + 1)
		price *= 2

func test_two_cards_share_curves_and_wallet_never_sets_prices() -> void:
	var f := fixture()
	f.shoe.choose_card(f.cards[0].unique_id)
	f.shoe.choose_card(f.cards[1].unique_id)
	f.wallet.economy_scaling = true
	for balance in [0, 25_000, 1_000_000_000]:
		f.wallet.reset(balance)
		assert_eq([f.shoe.rank_cost(), f.shoe.suit_cost()], [5_000, 2_500])
	f.shoe.reroll_rank(f.cards[0].unique_id)
	assert_eq(f.shoe.reroll_rank(f.cards[1].unique_id).cost_vnd, 10_000)
	assert_eq(f.shoe.rank_cost(), 20_000)
	assert_eq(f.shoe.suit_cost(), 2_500)

func test_new_day_resets_visit_without_resetting_card_or_metadata() -> void:
	var f := fixture()
	var card: CardData = f.cards[0]
	card.fortune = 3
	card.liquid = true
	card.shiny = true
	f.shoe.choose_card(card.unique_id)
	f.shoe.reroll_rank(card.unique_id)
	var before := card.persuasion_fingerprint()
	f.shoe.begin_day(1, f.cards, 500_000)
	assert_false(f.shoe.visit_started)
	assert_true(f.shoe.selected_card_ids.is_empty())
	assert_eq([f.shoe.rank_rerolls, f.shoe.suit_rerolls], [0, 0])
	assert_eq([f.shoe.rank_cost(), f.shoe.suit_cost()], [10_000, 5_000])
	assert_eq(card.persuasion_fingerprint(), before)

func test_insufficient_funds_changes_nothing_and_exact_balance_can_pay() -> void:
	var f := fixture()
	var card: CardData = f.cards[0]
	f.shoe.choose_card(card.unique_id)
	f.wallet.reset(4_999)
	var before := card.persuasion_fingerprint()
	var rng: int = f.shoe.run_rng_state()
	assert_false(f.shoe.reroll_rank(card.unique_id).ok)
	assert_eq(card.persuasion_fingerprint(), before)
	assert_eq(f.shoe.run_rng_state(), rng)
	assert_eq(f.wallet.balance_vnd, 4_999)
	assert_true(f.wallet.journal.is_empty())
	assert_eq(f.shoe.rank_rerolls, 0)
	f.wallet.reset(5_000)
	assert_true(f.shoe.reroll_rank(card.unique_id).ok)
	assert_eq(f.wallet.balance_vnd, 0)

func test_rejected_mutation_rolls_back_payment_rng_and_revision() -> void:
	var f := fixture()
	var original: CardData = f.cards[0]
	var card := RefusingCard.new(original.unique_id, original.rank, original.rank_index, original.suit, original.base_value)
	f.cards[0] = card
	f.shoe.choose_card(card.unique_id)
	var before := card.persuasion_fingerprint()
	var state: Dictionary = f.shoe.run_snapshot().duplicate(true)
	var rng: int = f.shoe.run_rng_state()
	var balance: int = f.wallet.balance_vnd
	var entries: int = f.wallet.journal.size()
	assert_false(f.shoe.reroll_rank(card.unique_id).ok)
	assert_false(f.shoe.reroll_suit(card.unique_id).ok)
	assert_eq(card.persuasion_fingerprint(), before)
	assert_eq(card.mutation_revision, 0)
	assert_eq(f.shoe.run_snapshot(), state)
	assert_eq(f.shoe.run_rng_state(), rng)
	assert_eq(f.wallet.balance_vnd, balance)
	assert_eq(f.wallet.journal.size(), entries)

func test_observers_see_complete_commit_and_cannot_reenter_payment() -> void:
	var f := fixture()
	var card: CardData = f.cards[0]
	f.shoe.choose_card(card.unique_id)
	var calls := [0]
	var listener := func(_a: int, _b: int, _delta: int, reason: String):
		if reason != "shoe_reroll_rank": return
		calls[0] += 1
		assert_eq(f.shoe.rank_rerolls, 1)
		assert_eq(f.shoe.rank_cost(), 10_000)
		assert_eq(f.shoe.last_reroll.after, card.persuasion_fingerprint())
		assert_false(f.shoe.reroll_rank(card.unique_id).ok)
		assert_false(f.shoe.choose_card(f.cards[1].unique_id).ok)
	f.wallet.balance_changed.connect(listener)
	assert_true(f.shoe.reroll_rank(card.unique_id).ok)
	f.wallet.balance_changed.disconnect(listener)
	assert_eq(calls[0], 1)
	assert_eq(f.wallet.journal.size(), 1)

func test_gold_black_ink_liquid_negative_glitch_and_future_metadata_preserved() -> void:
	for properties in [[4, false, false], [-5, false, false], [3, true, false], [-2, false, true], [6, true, true]]:
		var f := fixture()
		var card: CardData = f.cards[0]
		card.fortune = properties[0]
		card.liquid = properties[1]
		card.negative = properties[2]
		card.shiny = true
		card.enhancements.assign(["future_compatible_property", "seal_annotation"])
		card.value_modifiers.assign([5, -2])
		var before := card.persuasion_fingerprint()
		var physical_ids: Array = f.cards.map(func(c): return c.unique_id)
		f.shoe.choose_card(card.unique_id)
		assert_true(f.shoe.reroll_rank(card.unique_id).ok)
		assert_true(f.shoe.reroll_suit(card.unique_id).ok)
		var after := card.persuasion_fingerprint()
		for key in ["rank", "rank_index", "base_value", "suit"]:
			before.erase(key)
			after.erase(key)
		assert_eq(after, before)
		assert_eq(f.cards.map(func(c): return c.unique_id), physical_ids)
		assert_eq(f.shoe.card_for_id(card.unique_id), card)

func test_seals_refuse_selection_and_work_without_spending() -> void:
	var f := fixture()
	var card: CardData = f.cards[0]
	card.transformation_locked = true
	assert_false(f.shoe.choose_card(card.unique_id).ok)
	card.transformation_locked = false
	f.shoe.choose_card(card.unique_id)
	card.transformation_locked = true
	var before := card.persuasion_fingerprint()
	var balance: int = f.wallet.balance_vnd
	var rng: int = f.shoe.run_rng_state()
	assert_false(f.shoe.reroll_rank(card.unique_id).ok)
	assert_false(f.shoe.reroll_suit(card.unique_id).ok)
	assert_eq(card.persuasion_fingerprint(), before)
	assert_eq(f.wallet.balance_vnd, balance)
	assert_eq(f.shoe.run_rng_state(), rng)

func test_negative_derives_from_current_q_black_identity() -> void:
	var f := fixture()
	var card: CardData = f.cards[20]
	card.negative = true
	assert_eq(card.meld_rank_options(), [7, 8, 9])
	assert_eq(card.meld_suit_options(), ["Hearts", "Diamonds"])
	var seed_value := -1
	for candidate in 500:
		var probe := RandomNumberGenerator.new()
		probe.seed = candidate
		var ranks := DeckManager.RANKS.duplicate()
		ranks.erase("8")
		if ranks[probe.randi_range(0, 11)] == "Q" and probe.randi_range(0, 2) == 0:
			seed_value = candidate
			break
	assert_true(seed_value >= 0)
	f.shoe.set_seed_value(seed_value)
	f.shoe.choose_card(card.unique_id)
	assert_true(f.shoe.reroll_rank(card.unique_id).ok)
	assert_true(f.shoe.reroll_suit(card.unique_id).ok)
	assert_eq([card.rank, card.suit], ["Q", "Spades"])
	assert_eq(card.meld_rank_options(), [11, 12, 13])
	assert_eq(card.meld_suit_options(), ["Spades", "Clubs"])
	assert_false(card.can_represent(8, "Hearts"))
	assert_true(card.can_represent(11, "Clubs"))

func test_glitch_remains_any_rank_any_suit() -> void:
	var f := fixture()
	var card: CardData = f.cards[0]
	card.liquid = true
	card.negative = true
	f.shoe.choose_card(card.unique_id)
	f.shoe.reroll_rank(card.unique_id)
	f.shoe.reroll_suit(card.unique_id)
	assert_true(card.is_glitch())
	for rank in range(1, 14):
		for suit in DeckManager.SUITS: assert_true(card.can_represent(rank, suit))
	assert_eq(card.meld_rank_options().size(), 13)
	assert_eq(card.meld_suit_options(), DeckManager.SUITS)

func test_seeded_rerolls_do_not_contaminate_other_streams() -> void:
	var a := fixture()
	var b := fixture()
	var streams: Array = [a.deal.deck._rng.state, a.campaign.gieo_que.run_rng_state(),
		a.campaign.lottery.run_rng_state(), a.campaign.relic_shop.run_rng_state(), a.campaign.zodiac._rng.state]
	for f in [a, b]: f.shoe.choose_card(f.cards[0].unique_id)
	for _i in 8:
		assert_eq(a.shoe.reroll_rank(a.cards[0].unique_id), b.shoe.reroll_rank(b.cards[0].unique_id))
		assert_eq(a.shoe.reroll_suit(a.cards[0].unique_id), b.shoe.reroll_suit(b.cards[0].unique_id))
	assert_eq([a.deal.deck._rng.state, a.campaign.gieo_que.run_rng_state(),
		a.campaign.lottery.run_rng_state(), a.campaign.relic_shop.run_rng_state(), a.campaign.zodiac._rng.state], streams)

func test_file_resume_keeps_ids_prices_metadata_and_exact_next_outcomes() -> void:
	var f := fixture()
	var id: String = f.cards[0].unique_id
	f.cards[0].fortune = -4
	f.cards[0].liquid = true
	f.cards[0].negative = true
	f.cards[0].enhancements.assign(["saved_future_mark"])
	f.shoe.choose_card(id)
	f.shoe.choose_card(f.cards[1].unique_id)
	for _i in 3: f.shoe.reroll_rank(id)
	for _i in 2: f.shoe.reroll_suit(id)
	var state: Dictionary = f.shoe.run_snapshot().duplicate(true)
	var balance: int = f.wallet.balance_vnd
	var card_state: Dictionary = f.cards[0].run_value_snapshot().duplicate(true)
	var save := RunSave.new("user://shoe-identity-test.save")
	assert_true(save.save_run(f.campaign, f.deal), save.error)
	var expected_rank: Dictionary = f.shoe.reroll_rank(id)
	var expected_suit: Dictionary = f.shoe.reroll_suit(id)
	var resumed := fixture("OTHER-SEED")
	assert_true(save.restore(save.load_run(), resumed.campaign, resumed.deal))
	assert_eq(resumed.shoe.run_snapshot(), state)
	assert_eq(resumed.wallet.balance_vnd, balance)
	assert_eq(resumed.shoe.card_for_id(id).run_value_snapshot(), card_state)
	assert_true(resumed.shoe.card_for_id(id) == resumed.campaign.gieo_que.persistent_deck[0])
	assert_false(resumed.shoe.choose_card(resumed.campaign.gieo_que.persistent_deck[2].unique_id).ok)
	assert_eq(resumed.shoe.reroll_rank(id), expected_rank)
	assert_eq(resumed.shoe.reroll_suit(id), expected_suit)

func test_legacy_save_ignores_polish_counts_and_preserves_new_printing() -> void:
	var f := fixture()
	var id: String = f.cards[0].unique_id
	f.shoe.choose_card(id)
	f.shoe.reroll_rank(id)
	var save := RunSave.new("user://shoe-legacy-test.save")
	assert_true(save.save_run(f.campaign, f.deal))
	var data := save.load_run()
	var identity: Dictionary = data.gieo.persistent_deck[0].permanent_snapshot()
	data.shoe = {"_day_index": 0, "_event_slot": EventManager.EventSlot.STARTER,
		"polish_count_today": 9, "tip_count_today": 8, "_tips_vnd": 200_000, "last_polished_ids": [id]}
	assert_true(save.restore(data, f.campaign, f.deal))
	assert_true(f.shoe.is_active())
	assert_true(f.shoe.visit_started)
	assert_true(f.shoe.selected_card_ids.is_empty())
	assert_eq([f.shoe.rank_rerolls, f.shoe.suit_rerolls], [0, 0])
	assert_eq([f.shoe.rank_cost(), f.shoe.suit_cost()], [5_000, 2_500])
	assert_eq(f.shoe.card_for_id(id).permanent_snapshot(), identity)
	assert_eq(f.shoe.cards().size(), 52)

func test_no_hard_reroll_limit_and_price_saturates_safely() -> void:
	var f := fixture()
	f.wallet.reset(1_000_000_000_000_000_000)
	var id: String = f.cards[0].unique_id
	f.shoe.choose_card(id)
	for _i in 60: assert_true(f.shoe.reroll_rank(id).ok)
	assert_eq(f.shoe.rank_rerolls, 60)
	assert_eq(f.shoe.rank_cost(), ShoeShineConfig.MAX_COST_VND)
	assert_eq(f.shoe.suit_cost(), 2_500)

func test_reset_and_restore_never_clear_bound_canonical_deck() -> void:
	var f := fixture()
	var ids: Array = f.cards.map(func(card): return card.unique_id)
	f.shoe.reset_run()
	assert_eq(f.campaign.gieo_que.persistent_deck.map(func(card): return card.unique_id), ids)
	f.shoe.bind_deck(f.cards)
	f.shoe.restore_run_snapshot({})
	assert_eq(f.campaign.gieo_que.persistent_deck.map(func(card): return card.unique_id), ids)