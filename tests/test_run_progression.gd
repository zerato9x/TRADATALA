@tool
extends McpTestSuite
func suite_name() -> String:
	return "run_progression"

func make_campaign(deal: DealState) -> CampaignManager:
	var events := EventManager.new()
	CampaignNpcCatalog.register_initial_npcs(events)
	var drinks := DrinkManager.new(deal.wallet)
	drinks.progress = DrinkProgress.new("")
	var c := CampaignManager.new(deal.wallet, events, drinks)
	c.relic_shop.runtime = deal.relics
	c.start_campaign(true, "test-seed")
	deal.set_campaign_deck(c.gieo_que.persistent_deck)
	deal.start_deal(c.seed_for("deal"))
	return c

func test_exact_day_and_branch_gates_independent_of_unlocks() -> void:
	var d := DealState.new()
	var c := make_campaign(d)
	var m := c.drink_manager
	assert_eq(m.available_drink_ids(), [DrinkCatalog.TRA_DA])
	m.begin_event(EventManager.EventSlot.NOON)
	assert_eq(m.available_drink_ids(), DrinkCatalog.basic_ids())
	assert_false(m.can_order(DrinkCatalog.NUOC_VOI))
	m.progress.add_progress("melds", 5)
	d.wallet.apply_vnd(1_000_000, "fixture")
	assert_true(m.can_order(DrinkCatalog.NUOC_VOI))
	m.day_index = 1
	m.begin_event(EventManager.EventSlot.STARTER)
	assert_eq(m.available_drink_ids(), DrinkCatalog.basic_ids())
	m.begin_event(EventManager.EventSlot.NOON)
	assert_true(m.available_drink_ids().has(DrinkCatalog.STING))
	assert_false(m.available_drink_ids().has(DrinkCatalog.BO_HUC))
	m.day_index = 2
	m.begin_event(EventManager.EventSlot.STARTER)
	assert_true(m.available_drink_ids().has(DrinkCatalog.C2_ICED_TEA))
	assert_false(m.available_drink_ids().has(DrinkCatalog.MIA_TAC))
	m.begin_event(EventManager.EventSlot.NOON)
	m.morning_drink_id = DrinkCatalog.DEN_DA
	assert_false(m.available_drink_ids().has(DrinkCatalog.BO_HUC))
	m.morning_drink_id = DrinkCatalog.STING
	assert_true(m.available_drink_ids().has(DrinkCatalog.BO_HUC))
	assert_false(m.available_drink_ids().has(DrinkCatalog.MIA_TAC))
	m.morning_drink_id = DrinkCatalog.C2_ICED_TEA
	assert_false(m.available_drink_ids().has(DrinkCatalog.BO_HUC))
	assert_true(m.available_drink_ids().has(DrinkCatalog.MIA_TAC))
	assert_true(m.available_drink_ids().has(DrinkCatalog.MIA_SAU_RIENG))
	m.clear_day()
	m.begin_event(EventManager.EventSlot.NOON)
	assert_false(m.available_drink_ids().has(DrinkCatalog.MIA_TAC))

func test_goal_prices_and_sunday_debt() -> void:
	var m := DrinkManager.new()
	m.day_target_vnd = 16_000_000
	assert_eq(CampaignConfig.day_definitions()[6].required_vnd, 16_000_000)
	assert_eq(m.price_for(DrinkCatalog.BO_HUC), 1_280_000)
	assert_eq(m.price_for(DrinkCatalog.MIA_TAC), 1_280_000)
	assert_eq(m.price_for(DrinkCatalog.TRA_DA), 0)
	m.wallet.apply_vnd(999_000_000, "fixture")
	assert_eq(m.price_for(DrinkCatalog.BO_HUC), 1_280_000)

func test_seed_streams_match_and_differ_without_cross_service_coupling() -> void:
	var a := DealState.new()
	var b := DealState.new()
	var c := make_campaign(a)
	var d := make_campaign(b)
	assert_eq(a.hand.map(func(card): return card.unique_id), b.hand.map(func(card): return card.unique_id))
	assert_eq(c.lottery.special_number(), d.lottery.special_number())
	assert_eq(c.seed_for("relic", 1), d.seed_for("relic", 1))
	c.gieo_que.cast()
	assert_eq(c.seed_for("deal", 1), d.seed_for("deal", 1))
	d.start_campaign(true, "different-seed")
	assert_ne(c.seed_for("deal", 1), d.seed_for("deal", 1))

func test_relic_offer_is_three_seeded_unique_one_purchase_per_visit() -> void:
	var d := DealState.new()
	var c := make_campaign(d)
	var shop := c.relic_shop
	d.wallet.apply_vnd(1_000_000, "fixture")
	shop.begin_visit("0:1", c.seed_for("relic", 1), 250_000)
	var initial := shop.offers.duplicate()
	assert_eq(initial.size(), 3)
	assert_ne(initial[0], initial[1])
	shop.begin_visit("0:1", 123, 250_000)
	assert_eq(shop.offers, initial)
	var before := d.wallet.balance_vnd
	assert_true(shop.reroll())
	assert_eq(d.wallet.balance_vnd, before - 5_000)
	assert_false(shop.offers.has(initial[0]))
	var bought := shop.offers[0]
	var rejected := shop.offers[1]
	assert_true(shop.buy(bought))
	assert_true(d.relics.inventory.has(bought))
	assert_true(shop.offers.is_empty())
	assert_false(shop.buy(rejected))
	assert_false(shop.reroll())
	shop.begin_visit("0:3", c.seed_for("relic", 3), 250_000)
	assert_eq(shop.offers.size(), 3)
	assert_false(shop.offers.has(bought))

func test_file_roundtrip_preserves_identity_rng_shop_events_and_unlocks() -> void:
	var d := DealState.new()
	var c := make_campaign(d)
	c.event_manager.complete_interaction("choose_drink")
	c.drink_manager.progress.add_progress("melds", 5)
	c.relic_shop.begin_visit("0:1", 456, 250_000)
	d.wallet.apply_vnd(900_000, "fixture")
	d.discard_card(d.hand[0])
	var before := d.accounting_report()
	var save := RunSave.new("user://test_roundtrip.save")
	assert_true(save.save_run(c, d))
	var data := save.load_run()
	assert_false(data.is_empty(), save.error)
	var other := DealState.new()
	var restored := make_campaign(other)
	assert_true(save.restore(data, restored, other))
	assert_eq(other.accounting_report(), before)
	assert_eq(other.deck._rng.state, d.deck._rng.state)
	assert_true(other.discard_history[0].card == other.deck.discard_pile[0])
	assert_true(other.campaign_deck_cards[0] == restored.gieo_que.persistent_deck[0])
	assert_true(restored.shoe_shine.cards()[0] == restored.gieo_que.persistent_deck[0])
	assert_true(restored.event_manager.current_event.can_exit)
	assert_true(restored.drink_manager.progress.is_unlocked(DrinkCatalog.NUOC_VOI))
	assert_eq(restored.relic_shop.offers, c.relic_shop.offers)
	assert_true(c.relic_shop.reroll())
	assert_true(restored.relic_shop.reroll())
	assert_eq(restored.relic_shop.offers, c.relic_shop.offers)
	assert_eq(restored.gieo_que._rng.state, c.gieo_que._rng.state)
	assert_eq(restored.lottery._rng.state, c.lottery._rng.state)
	assert_eq(other.deck.draw()[0].unique_id, d.deck.draw()[0].unique_id)

func test_save_recovers_backup_and_rejects_unsupported_version() -> void:
	var d := DealState.new()
	var c := make_campaign(d)
	var save := RunSave.new("user://test_backup.save")
	assert_true(save.save_run(c, d))
	d.wallet.apply_vnd(999, "second")
	assert_true(save.save_run(c, d))
	var file := FileAccess.open(save.path, FileAccess.WRITE)
	file.store_var({"version": 999})
	file.close()
	var result := save.load_run()
	assert_true(save.recovered_backup)
	assert_eq(result.deal.wallet_balance_vnd, CampaignConfig.STARTING_WALLET_VND)

func test_paid_sunday_waits_for_endless_choice_and_preserves_run() -> void:
	var d := DealState.new()
	var c := make_campaign(d)
	c.current_day_index = 6
	d.wallet.apply_vnd(20_000_000, "fixture")
	c.event_manager.current_event = null
	c._finish_day()
	assert_true(c.collect_day_debt())
	assert_true(c.campaign_complete)
	assert_eq(c.current_day_index, 6)
	assert_eq(d.wallet.balance_vnd, 4_000_000 + CampaignConfig.STARTING_WALLET_VND)
	assert_true(c.continue_endless())
	assert_false(c.continue_endless())
	assert_true(c.endless)
	assert_eq(c.current_day_index, 7)
	assert_eq(c.daily_requirement(), 24_000_000)
	assert_eq(c.run_seed, "test-seed")
	c._finish_day()
	assert_true(c.collect_day_debt())
	assert_true(c.run_failed)
	assert_eq(d.wallet.balance_vnd, 4_000_000 + CampaignConfig.STARTING_WALLET_VND)

func test_pending_collection_roundtrip_does_not_charge_twice() -> void:
	var d := DealState.new()
	var c := make_campaign(d)
	d.wallet.apply_vnd(1_000_000, "fixture")
	c.event_manager.current_event = null
	c._finish_day()
	var save := RunSave.new("user://test_collection.save")
	assert_true(save.save_run(c, d))
	var other := DealState.new()
	var restored := make_campaign(other)
	assert_true(save.restore(save.load_run(), restored, other))
	assert_eq(other.wallet.balance_vnd, 1_000_000 + CampaignConfig.STARTING_WALLET_VND)
	assert_true(restored.collect_day_debt())
	assert_false(restored.collect_day_debt())
	assert_eq(other.wallet.balance_vnd, 750_000 + CampaignConfig.STARTING_WALLET_VND)

func test_save_preserves_melds_properties_phase_choice_and_pending_gieo() -> void:
	var d := DealState.new()
	var c := make_campaign(d)
	d.start_tutorial_deal()
	var cards: Array[CardData] = []
	for card in d.hand:
		if card.rank_index == 9:
			cards.append(card)
	cards[0].shiny = true
	cards[0].value_modifiers.append(7)
	d.relics.acquire("hair_clip")
	d.relics.equip("hair_clip")
	assert_true(d.create_meld(cards).ok, "create meld")
	for i in 4:
		assert_true(d.discard_card(d.hand[0]).ok, "discard")
	assert_true(d.settle_phase().ok, "settle")
	assert_eq(d.state, DealState.STATE_PHASE_CHOICE)
	c.gieo_que.cast(["D", "D", "A", "D", "A", "D"])
	c.gieo_que.accept()
	assert_eq(c.gieo_que.state, GieoQueService.STATE_DESTINATION_SELECTION)
	var save := RunSave.new("user://test_complex.save")
	assert_true(save.save_run(c, d), "save initial: " + save.error)
	var loaded := save.load_run()
	assert_false(loaded.is_empty(), save.error)
	var other := DealState.new()
	var restored := make_campaign(other)
	assert_true(save.restore(loaded, restored, other), "restore")
	assert_eq(other.state, DealState.STATE_PHASE_CHOICE)
	assert_eq(other.melds.size(), 1)
	assert_eq(other.melds[0].cards.map(func(card): return card.unique_id), d.melds[0].cards.map(func(card): return card.unique_id))
	assert_eq(other.melds[0].cards.map(func(card): return card.shiny), d.melds[0].cards.map(func(card): return card.shiny))
	assert_eq(other.settlements.size(), 1)
	assert_eq(other.physical_card_accounting().unique_ids, 52)
	assert_eq(restored.gieo_que.state, GieoQueService.STATE_DESTINATION_SELECTION)
	assert_eq(restored.gieo_que.current_result, c.gieo_que.current_result)
	assert_eq(restored.gieo_que.current_pull_cost(), c.gieo_que.current_pull_cost())
	restored.gieo_que.choose_destination("7")
	restored.gieo_que.choose_target(restored.gieo_que.persistent_deck[0].unique_id)
	assert_true(save.save_run(restored, other), "save reveal: " + save.error)
	var resolved := save.load_run()
	assert_true(resolved.gieo.resolved_targets[0] == resolved.gieo.persistent_deck[0], "target identity")
	assert_true(other.choose_phase_two(false).ok, "restored phase choice")
	assert_true(d.choose_phase_two(false).ok, "original phase choice")
	assert_eq(other.hand.map(func(card): return card.unique_id), d.hand.map(func(card): return card.unique_id))

func test_relic_reroll_resists_wallet_signal_reentry() -> void:
	var d := DealState.new()
	var c := make_campaign(d)
	d.wallet.apply_vnd(1_000_000, "fixture")
	c.relic_shop.begin_visit("0:1", 123, 250_000)
	var listener := func(_a, _b, _delta, reason):
		if reason == "relic_reroll":
			assert_false(c.relic_shop.reroll())
	d.wallet.balance_changed.connect(listener)
	assert_true(c.relic_shop.reroll())
	assert_eq(c.relic_shop.rerolls, 1)
	d.wallet.balance_changed.disconnect(listener)

func test_unlock_profile_survives_a_new_progress_instance() -> void:
	var progress := DrinkProgress.new("user://test_profile.cfg")
	progress.counters.clear()
	progress.add_progress("sting_pairs", 10)
	var loaded := DrinkProgress.new("user://test_profile.cfg")
	assert_true(loaded.is_unlocked(DrinkCatalog.BO_HUC))
	assert_false(loaded.is_unlocked(DrinkCatalog.MIA_TAC))

func test_endless_keeps_advancing_and_restart_returns_to_seven_days() -> void:
	var d := DealState.new()
	var c := make_campaign(d)
	c.current_day_index = 6
	d.wallet.apply_vnd(200_000_000, "fixture")
	c._finish_day()
	c.collect_day_debt()
	assert_true(c.continue_endless())
	for index in [7, 8, 9]:
		assert_eq(c.current_day_index, index)
		c._finish_day()
		assert_true(c.collect_day_debt())
		assert_false(c.campaign_complete)
	assert_eq(c.current_day_index, 10)
	c.start_campaign(true, "restart")
	assert_eq(c.campaign_days.size(), 7)
	assert_false(c.endless)
	assert_eq(c.current_day_index, 0)

func test_exhaustion_card_contributions_are_in_run_mvp_history() -> void:
	var d := DealState.new()
	make_campaign(d)
	d.start_tutorial_deal()
	var cards: Array[CardData] = []
	for card in d.hand:
		if card.rank_index == 9:
			cards.append(card)
	d.create_meld(cards)
	# Move stock to the recyclable zone to exercise a real exhaustion payout.
	d.recyclable_spent_cards.append_array(d.deck.draw_pile)
	d.deck.draw_pile.clear()
	d.deck.draw()
	var event: Dictionary = d.action_history.filter(func(value: Dictionary): return value.action == "exhaustion")[0]
	assert_true(event.points > 0)
	assert_false(event.passes.is_empty())
	var points := 0
	for scoring_pass: Dictionary in event.passes:
		for hit: Dictionary in scoring_pass.hits:
			points += int(hit.points)
	assert_eq(points, event.points)

func test_difficulty_doubles_debts_and_unlocks_only_after_week() -> void:
	var d := DealState.new()
	var c := make_campaign(d)
	c.difficulty_progress = preload("res://scripts/campaign/difficulty_progress.gd").new("")
	assert_false(c.select_difficulty(2))
	assert_true(c.select_difficulty(1))
	c.current_day_index = 6
	c.current_phase = CampaignManager.CampaignPhase.MONEY_REQUIREMENT_CHECK
	d.wallet.reset(16_000_000)
	assert_true(c.collect_day_debt())
	assert_eq(c.difficulty_progress.unlocked, 2)
	assert_true(c.continue_endless())
	assert_eq(c.daily_requirement(), 24_000_000)
	assert_eq(c.difficulty_progress.unlocked, 2)
	assert_true(c.select_difficulty(2))
	c.start_campaign(true, "difficulty-two")
	assert_eq(c.daily_requirement(), 500_000)
	assert_eq(c.campaign_days[6].required_vnd, 32_000_000)
	var save := RunSave.new("user://difficulty_test.save")
	var snapshot := save.capture(c, d)
	var other := make_campaign(DealState.new())
	assert_true(save.restore(snapshot, other, d))
	assert_eq(other.difficulty, 2)
	assert_eq(other.daily_requirement(), 500_000)
	snapshot.campaign.erase("difficulty")
	assert_true(save.restore(snapshot, other, d))
	assert_eq(other.difficulty, 1)

func test_difficulty_profile_survives_new_instance() -> void:
	var progress = preload("res://scripts/campaign/difficulty_progress.gd").new("user://difficulty_test.cfg")
	progress.unlocked = 1
	progress.complete_week(1)
	var restored = preload("res://scripts/campaign/difficulty_progress.gd").new("user://difficulty_test.cfg")
	assert_eq(restored.unlocked, 2)
	restored.complete_week(1)
	assert_eq(restored.unlocked, 2)
	restored.complete_week(3)
	assert_eq(restored.unlocked, 2)

func test_failed_sunday_does_not_unlock_difficulty() -> void:
	var d := DealState.new()
	var c := make_campaign(d)
	c.difficulty_progress = preload("res://scripts/campaign/difficulty_progress.gd").new("")
	c.current_day_index = 6
	c.current_phase = CampaignManager.CampaignPhase.MONEY_REQUIREMENT_CHECK
	d.wallet.reset(0)
	assert_true(c.collect_day_debt())
	assert_true(c.run_failed)
	assert_eq(c.difficulty_progress.unlocked, 1)
	var first := CampaignConfig.day_definitions(1)
	var second := CampaignConfig.day_definitions(2)
	var third := CampaignConfig.day_definitions(3)
	for index in first.size():
		assert_eq(second[index].required_vnd, first[index].required_vnd * 2)
		assert_eq(third[index].required_vnd, second[index].required_vnd * 2)
