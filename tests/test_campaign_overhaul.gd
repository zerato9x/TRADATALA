@tool
extends McpTestSuite

func suite_name() -> String:
	return "campaign_overhaul"

func make_campaign() -> CampaignManager:
	var events := EventManager.new()
	CampaignNpcCatalog.register_initial_npcs(events)
	var campaign := CampaignManager.new(null, events)
	campaign.start_campaign(true, "overhaul")
	return campaign

func test_drink_gieo_and_relic_prices_still_track_day_debt() -> void:
	var c := make_campaign()
	c.current_day_index = 3
	c._begin_current_day()
	c.relic_shop.begin_visit("test", 1, c.daily_requirement())
	c.gieo_que.free_cast_used_today = true
	var quotes: Array = []
	for balance in [0, 20_000, 900_000_000]:
		c.wallet.reset(balance)
		quotes.append([c.drink_manager.price_for(DrinkCatalog.NUOC_VOI), c.gieo_que.current_pull_cost(), c.relic_shop.price(), c.relic_shop.reroll_price()])
	assert_eq(quotes[0], quotes[1])
	assert_eq(quotes[1], quotes[2])
	assert_eq(quotes[0], [40_000, 80_000, 100_000, 40_000])

func test_buy_all_respects_budget_ownership_and_afternoon_closes_draw() -> void:
	var c := make_campaign()
	c.lottery.begin_event(EventManager.EventSlot.MORNING)
	c.wallet.reset(25_000)
	assert_eq(c.lottery.buy_all_quote().count, 1)
	assert_eq(c.lottery.buy_all().cost_vnd, 10_000)
	assert_eq(c.lottery.purchased_tickets().size(), 1)
	assert_false(c.lottery.buy_all().ok)
	assert_eq(c.wallet.balance_vnd, 15_000)
	c._enter_phase(CampaignManager.CampaignPhase.AFTERNOON_EVENT)
	assert_false(c.lottery.revealed_results().is_empty())
	var balance := c.wallet.balance_vnd
	assert_true(c.lottery.settle_day().is_empty())
	assert_false(c.lottery.buy_all().ok)
	assert_eq(c.wallet.balance_vnd, balance)
	assert_true(c.complete_current_event())
	assert_eq(c.current_phase, CampaignManager.CampaignPhase.EVENING_DEAL)

func test_curated_morning_has_real_set_then_extension_without_card_loss() -> void:
	var c := make_campaign()
	var d := DealState.new()
	d.set_campaign_deck(c.gieo_que.persistent_deck)
	d.start_deal(CampaignOnboarding.SEED, false, c.onboarding.opening_ids("morning", c.gieo_que.persistent_deck))
	var set_cards: Array[CardData] = []
	for card in d.hand:
		if card.rank_index == 9: set_cards.append(card)
	assert_eq(set_cards.size(), 3)
	var result := d.create_meld(set_cards)
	assert_true(result.ok)
	c.onboarding.observe(result, d)
	assert_true(c.onboarding.learned.has("new_meld"))
	assert_true(c.onboarding.learned.has("set"))
	assert_true(d.discard_card(d.hand[-1]).ok)
	var extension: Array[CardData] = []
	for card in d.hand:
		if card.unique_id == "standard_9_clubs": extension.append(card)
	assert_eq(extension.size(), 1)
	assert_true(d.extend_meld(1, extension).ok)
	assert_true(d.physical_card_accounting_is_valid())
	assert_eq(c.gieo_que.persistent_deck.size(), 52)

func test_noon_brings_changed_card_and_save_preserves_knowledge() -> void:
	var c := make_campaign()
	var d := DealState.new()
	d.wallet = c.wallet
	d.set_campaign_deck(c.gieo_que.persistent_deck)
	var changed := c.gieo_que.persistent_deck[-1]
	changed.add_gieo_property(GieoQueService.PROPERTY_GOLD_SET)
	d.start_deal(CampaignOnboarding.SEED, false, c.onboarding.opening_ids("noon", c.gieo_que.persistent_deck))
	assert_true(d.hand.any(func(card): return card.unique_id == changed.unique_id and card.has_gieo_property(GieoQueService.PROPERTY_GOLD_SET)))
	c.onboarding.mark("extension")
	c.onboarding.dismissed["starter"] = true
	var save := RunSave.new("user://overhaul-test.save")
	assert_true(save.save_run(c, d))
	var other := make_campaign()
	var other_deal := DealState.new()
	other_deal.wallet = other.wallet
	assert_true(save.restore(save.load_run(), other, other_deal))
	assert_true(other.onboarding.learned.has("extension"))
	assert_true(other.onboarding.dismissed.has("starter"))
	other.start_campaign()
	assert_true(other.onboarding.learned.is_empty())
	assert_true(other.onboarding.dismissed.is_empty())

func test_starter_debt_and_gieo_commitment_guard() -> void:
	var c := make_campaign()
	assert_true(c.event_manager.current_event.participants.any(func(npc): return npc.id == "doi_no"))
	c.event_manager.complete_interaction("choose_drink")
	c.gieo_que.cast(["D", "D", "A", "D", "A", "D"])
	c.gieo_que.accept()
	assert_false(c.complete_current_event())
	assert_eq(c.current_phase, CampaignManager.CampaignPhase.STARTER_EVENT)


func test_player_service_quotes_repeat_daily_and_buy_all_matches_payment() -> void:
	var c := make_campaign()
	c.wallet.reset(1_000_000)
	assert_eq(c.shoe_shine.polish_cost(), 20_000)
	assert_eq(c.shoe_shine.tip_cost(), 10_000)
	assert_true(c.shoe_shine.polish().ok)
	assert_eq(c.wallet.balance_vnd, 980_000)
	assert_eq(c.shoe_shine.polish_cost(), 40_000)
	assert_true(c.shoe_shine.tip().ok)
	assert_eq(c.shoe_shine.tip_cost(), 20_000)
	c.shoe_shine.begin_event(EventManager.EventSlot.STARTER)
	assert_eq(c.shoe_shine.polish_count_today, 1, "reopening cannot reset price")
	c.lottery.begin_event(EventManager.EventSlot.MORNING)
	var first: Dictionary = c.lottery.offered_tickets()[0]
	assert_eq(first.stake_vnd, 10_000)
	assert_true(c.lottery.purchase(first.id).ok)
	assert_eq(c.lottery.purchased_tickets()[0].stake_vnd, 10_000)
	assert_eq(c.lottery.ticket_cost(), 20_000)
	var before := c.wallet.balance_vnd
	var quote := c.lottery.buy_all_quote()
	var result := c.lottery.buy_all()
	assert_eq(result.count, quote.count)
	assert_eq(result.cost_vnd, quote.cost_vnd)
	assert_eq(c.wallet.balance_vnd, before - int(quote.cost_vnd))
	assert_eq(c.lottery.purchased_tickets()[0].stake_vnd, 10_000, "bought stake cannot be repriced")
	c.shoe_shine.begin_day(1, c.gieo_que.persistent_deck)
	c.lottery.begin_day(1)
	assert_eq(c.shoe_shine.polish_count_today, 0)
	assert_eq(c.shoe_shine.tip_count_today, 0)
	assert_eq(c.lottery.purchased_tickets().size(), 0)
	c.wallet.reset(2_000_000)
	assert_eq(c.shoe_shine.polish_cost(), 40_000)
	assert_eq(c.lottery.ticket_cost(), 20_000)

func test_player_service_repeat_counts_resume_and_migrate_old_saves() -> void:
	var deal := DealState.new()
	var events := EventManager.new()
	CampaignNpcCatalog.register_initial_npcs(events)
	var c := CampaignManager.new(deal.wallet, events)
	c.relic_shop.runtime = deal.relics
	c.start_campaign(true, "price-save")
	deal.set_campaign_deck(c.gieo_que.persistent_deck)
	deal.start_deal(c.seed_for("deal"))
	c.wallet.reset(1_000_000)
	c.shoe_shine.polish()
	c.shoe_shine.tip()
	var save := RunSave.new("user://price-save-test.save")
	var data := save.capture(c, deal)
	var polish := c.shoe_shine.polish_cost()
	var tip := c.shoe_shine.tip_cost()
	c.shoe_shine.polish_count_today = 9
	assert_true(save.restore(data, c, deal))
	assert_eq(c.shoe_shine.polish_cost(), polish)
	assert_eq(c.shoe_shine.tip_cost(), tip)
	data.shoe.erase("polish_count_today")
	data.shoe.erase("tip_count_today")
	c.shoe_shine.polish_count_today = 9
	assert_true(save.restore(data, c, deal))
	assert_eq(c.shoe_shine.polish_count_today, 1)
	assert_eq(c.shoe_shine.tip_count_today, 1)
