@tool
extends McpTestSuite

func suite_name() -> String:
	return "misc_npc"

func _campaign() -> CampaignManager:
	var events := EventManager.new()
	CampaignNpcCatalog.register_initial_npcs(events)
	var campaign := CampaignManager.new(VndWallet.new(), events)
	campaign.lottery.set_seed_value(1776)
	campaign.start_campaign()
	campaign.wallet.reset(5_000_000)
	campaign.wallet.economy_scaling = false # Disable wallet percentage in these fixtures; repetition still scales.
	return campaign

func test_polish_randomly_selects_two_distinct_cards_with_real_payment() -> void:
	var c := _campaign()
	var twin := _campaign()
	c.shoe_shine.set_seed_value(177)
	twin.shoe_shine.set_seed_value(177)
	var snapshots: Array[Dictionary] = []
	for card in c.gieo_que.persistent_deck:
		snapshots.append(card.permanent_snapshot())
	var before := c.wallet.balance_vnd
	var result := c.shoe_shine.polish()
	assert_true(result.ok)
	assert_eq(result.card_ids.size(), 2)
	assert_ne(result.card_ids[0], result.card_ids[1])
	assert_eq(result.card_ids, twin.shoe_shine.polish().card_ids)
	assert_eq(c.wallet.balance_vnd, before - MiscServiceConfig.POLISH_COST_VND)
	for i in c.gieo_que.persistent_deck.size():
		var card := c.gieo_que.persistent_deck[i]
		assert_eq(card.permanent_snapshot(), snapshots[i])
		assert_eq(card.shiny, result.card_ids.has(card.unique_id))
	var next := c.shoe_shine.polish()
	for id in next.card_ids:
		assert_false(result.card_ids.has(id))
	for card in c.gieo_que.persistent_deck:
		card.shiny = true
	c.gieo_que.persistent_deck[0].shiny = false
	before = c.wallet.balance_vnd
	assert_false(c.shoe_shine.polish().ok)
	assert_eq(c.wallet.balance_vnd, before)

func test_polish_survives_four_deal_copies_and_expires_next_day() -> void:
	var c := _campaign()
	var cards := c.gieo_que.persistent_deck
	var ids: Array = c.shoe_shine.polish().card_ids
	c.shoe_shine.begin_day(0, cards)
	for deal_index in 4:
		var deck := DeckManager.new()
		deck.reset_from_campaign_cards(cards, deal_index)
		var count := 0
		for card in deck.draw_pile:
			if card.shiny:
				count += 1
				assert_true(ids.has(card.unique_id))
				assert_false(cards.has(card))
		assert_eq(count, 2)
	c.shoe_shine.begin_day(1, cards)
	for card in cards:
		assert_false(card.shiny)
		assert_false(card.copy_for_deal().shiny)
	assert_true(c.shoe_shine.last_polished_ids.is_empty())

func _kings() -> Array[CardData]:
	return [CardData.new("k1", "K", 13, "Hearts", 13), CardData.new("k2", "K", 13, "Spades", 13), CardData.new("k3", "K", 13, "Clubs", 13)]

func _assert_hits(context: ScoringContext) -> void:
	var total := 0
	for pass_context: ScoringContext in context.scoring_passes:
		var hit_total := 0
		for hit in pass_context.presentation_hits:
			hit_total += int(hit.points)
		assert_eq(hit_total, pass_context.final_points)
		assert_true(pass_context.scoring_passes.is_empty())
		total += pass_context.final_points
	assert_eq(total, context.final_points)

func test_shiny_adds_only_own_contribution_not_a_meld_pass() -> void:
	var cards := _kings()
	cards[0].shiny = true
	var ctx := ScoringPipeline.new().preview_new_meld(cards, MeldRules.TYPE_SET, 1)
	assert_eq(ctx.final_points, 117 + 39)
	assert_eq(ctx.scoring_passes.size(), 1)
	assert_eq(ctx.retrigger_count, 0)
	_assert_hits(ctx)
	var run: Array[CardData] = [CardData.new("r1", "2", 2, "Clubs", 2), CardData.new("r2", "3", 3, "Clubs", 3), CardData.new("r3", "4", 4, "Clubs", 4)]
	run[1].shiny = true
	var run_ctx := ScoringPipeline.new().preview_new_meld(run, MeldRules.TYPE_RUN, 1)
	assert_eq(run_ctx.final_points, 27 + 9)
	assert_eq(run_ctx.scoring_passes.size(), 1)

func test_shiny_gold_and_liquid_are_finite_and_repeatable() -> void:
	var cards := _kings()
	cards[0].shiny = true
	cards[0].add_gieo_property(GieoQueService.PROPERTY_GOLD_SET)
	cards[0].add_gieo_property(GieoQueService.PROPERTY_MELD_RETRIGGER)
	for _i in 10:
		var ctx := ScoringPipeline.new().preview_new_meld(cards, MeldRules.TYPE_SET, 1)
		assert_eq(ctx.final_points, (156 + 78) * 2)
		assert_eq(ctx.scoring_passes.size(), 2)
		_assert_hits(ctx)

func test_shiny_extension_doubles_only_actual_delta_contribution_then_native_pass() -> void:
	var cards := _kings()
	cards[0].shiny = true
	var addition := CardData.new("k4", "K", 13, "Diamonds", 13)
	addition.shiny = true
	cards.append(addition)
	var ctx := ScoringPipeline.new().preview_extension(cards, MeldRules.TYPE_SET, 117, 1, [addition])
	assert_eq(ctx.scoring_passes.size(), 2)
	assert_eq(ctx.scoring_passes[0].final_points, 91 + 13 + 52)
	assert_eq(ctx.scoring_passes[1].final_points, 208 + 52 + 52)
	_assert_hits(ctx)
	var exhaust := ScoringPipeline.new().score_meld_trigger(cards, MeldRules.TYPE_SET, 1)
	assert_eq(exhaust.final_points, (208 + 104) * 2)
	_assert_hits(exhaust)

func test_tips_persist_across_days_reset_per_run_and_reveal_authoritative_special() -> void:
	var c := _campaign()
	assert_true(c.shoe_shine.special_hint().is_empty())
	var before := c.wallet.balance_vnd
	var threshold := int(MiscServiceConfig.FAVORS.lottery_special.tips_required_vnd)
	var paid := 0
	while not c.shoe_shine.favor_available("lottery_special"):
		paid += c.shoe_shine.tip_cost()
		assert_true(c.shoe_shine.tip().ok)
	assert_true(paid >= threshold)
	assert_eq(c.wallet.balance_vnd, before - paid)
	assert_eq(c.shoe_shine.special_hint().number, c.lottery.special_number())
	c.current_day_index = 1
	c._begin_current_day()
	assert_true(c.shoe_shine.favor_available("lottery_special"))
	assert_eq(c.shoe_shine.special_hint().number, c.lottery.special_number())
	c.start_campaign()
	assert_false(c.shoe_shine.favor_available("lottery_special"))

func test_service_gates_insufficient_money_and_wrong_event() -> void:
	var c := _campaign()
	c.wallet.reset(0)
	assert_false(c.shoe_shine.tip().ok)
	assert_false(c.shoe_shine.can_polish())
	c.wallet.reset(100_000)
	c.shoe_shine.begin_event(EventManager.EventSlot.MORNING)
	assert_false(c.shoe_shine.tip().ok)
	assert_true(c.shoe_shine.special_hint().is_empty())
	c.lottery.begin_event(EventManager.EventSlot.MORNING)
	var id := String(c.lottery.offered_tickets()[0].id)
	c.lottery.end_event()
	assert_false(c.lottery.purchase(id).ok)
	c.lottery.begin_event(EventManager.EventSlot.AFTERNOON)
	assert_false(c.lottery.purchase(id).ok)
	c.wallet.reset(0)
	assert_true(c.lottery.offered_tickets().is_empty())

func test_draw_is_seven_distinct_numbers_with_exact_categories_and_integer_payouts() -> void:
	var wallet := VndWallet.new()
	var lotto := LotteryService.new(wallet)
	lotto.set_seed_value(55)
	for day in 100:
		lotto.begin_day(day)
		assert_true(lotto.revealed_results().is_empty())
		lotto.settle_day()
		var draw := lotto.revealed_results()
		var seen: Array[int] = []
		for prize in MiscServiceConfig.PRIZES:
			assert_eq(draw[prize.id].size(), int(prize.count))
			for number in draw[prize.id]:
				assert_true(number >= 0 and number <= 99)
				assert_false(seen.has(number))
				seen.append(number)
		assert_eq(seen.size(), 7)
	var expected := [800_000, 200_000, 50_000, 25_000]
	for index in 4:
		assert_eq(LotteryService.payout_vnd(10_000, MiscServiceConfig.PRIZES[index]), expected[index])
	assert_eq(LotteryService.payout_vnd(3, MiscServiceConfig.PRIZES[3]), 7)

func test_daily_draw_and_offers_survive_reopen_and_hint_and_change_next_day() -> void:
	var c := _campaign()
	var lotto := c.lottery
	var special := lotto.special_number()
	lotto.begin_event(EventManager.EventSlot.MORNING)
	var offers := lotto.offered_tickets()
	for _i in 4:
		lotto.end_event()
		lotto.begin_day(0)
		lotto.begin_event(EventManager.EventSlot.MORNING)
		assert_eq(lotto.offered_tickets(), offers)
		assert_eq(lotto.special_number(), special)
	lotto.begin_event(EventManager.EventSlot.AFTERNOON)
	assert_eq(lotto.special_number(), special)
	assert_false(lotto.revealed_results().is_empty())
	var old := lotto.last_receipt
	lotto.begin_day(1)
	assert_eq(lotto.day_index, 1)
	assert_true(lotto.revealed_results().is_empty())
	assert_true(lotto.purchased_tickets().is_empty())
	var next := lotto.settle_day()
	assert_ne(next.draw, old.draw)

func test_actual_offered_tickets_pay_each_category_once_and_reopen_cannot_pay_again() -> void:
	var wallet := VndWallet.new()
	var lotto := LotteryService.new(wallet)
	lotto.set_seed_value(123)
	var categories: Dictionary = {}
	for day in 100:
		lotto.begin_day(day)
		wallet.reset(10_000_000)
		for slot in [EventManager.EventSlot.MORNING]:
			lotto.begin_event(slot)
			for offer in lotto.offered_tickets():
				assert_true(lotto.purchase(offer.id).ok)
				assert_false(lotto.purchase(offer.id).ok)
		var before := wallet.balance_vnd
		var receipt := lotto.settle_day()
		var expected := 0
		for ticket in receipt.tickets:
			var matched := 0
			for prize in MiscServiceConfig.PRIZES:
				if receipt.draw[prize.id].has(ticket.number):
					matched += 1
					assert_eq(ticket.prize, prize.id)
					assert_eq(ticket.payout_vnd, LotteryService.payout_vnd(ticket.stake_vnd, prize))
					categories[prize.id] = true
			assert_true(matched <= 1)
			expected += int(ticket.payout_vnd)
		assert_eq(wallet.balance_vnd, before + expected)
		assert_true(lotto.settle_day().is_empty())
		lotto.begin_day(day)
		lotto.begin_event(EventManager.EventSlot.MORNING)
		assert_true(lotto.offered_tickets().is_empty())
		assert_eq(wallet.balance_vnd, before + expected)
	assert_eq(categories.size(), 4)

func test_known_special_must_be_encountered_and_purchased_then_pays_eighty() -> void:
	var c := _campaign()
	while not c.shoe_shine.favor_available("lottery_special"):
		c.shoe_shine.tip()
	var found := false
	for day in 100:
		c.lottery.begin_day(day)
		c.shoe_shine.begin_day(day, c.gieo_que.persistent_deck)
		c.shoe_shine.begin_event(EventManager.EventSlot.STARTER)
		var hint := int(c.shoe_shine.special_hint().number)
		c.lottery.begin_event(EventManager.EventSlot.MORNING)
		assert_false(c.lottery.purchase("%02d" % hint).ok)
		for ticket in c.lottery.offered_tickets():
			if int(ticket.number) == hint:
				assert_true(c.lottery.purchase(ticket.id).ok)
				var before := c.wallet.balance_vnd
				var receipt := c.lottery.settle_day()
				assert_eq(receipt.draw.special[0], hint)
				assert_eq(receipt.tickets[0].prize, "special")
				assert_eq(c.wallet.balance_vnd - before, int(ticket.stake_vnd) * 80)
				found = true
				break
		if found:
			break
	assert_true(found)

func test_campaign_settles_before_daily_requirement_and_closes_service_gates() -> void:
	var c := _campaign()
	c.event_manager.complete_interaction("choose_drink")
	assert_true(c.complete_current_event())
	assert_false(c.shoe_shine.can_tip())
	assert_true(c.lottery.offered_tickets().is_empty())
	c.complete_deal()
	assert_eq(c.lottery.event_slot, EventManager.EventSlot.MORNING)
	c.lottery.purchase(c.lottery.offered_tickets()[0].id)
	c.complete_current_event()
	c.complete_deal()
	c.event_manager.complete_interaction("choose_drink")
	c.complete_current_event()
	c.complete_deal()
	c.complete_current_event()
	c.complete_deal()
	assert_eq(c.current_phase, CampaignManager.CampaignPhase.MONEY_REQUIREMENT_CHECK)
	assert_true(c.collect_day_debt())
	assert_eq(c.current_day_index, 1)
	assert_eq(c.lottery.last_receipt.day_index, 0)
	assert_eq(c.lottery.day_index, 1)
	assert_true(c.lottery.revealed_results().is_empty())


func test_shiny_points_reach_real_deal_wallet() -> void:
	var deal := DealState.new()
	deal.start_tutorial_deal()
	var chosen: Array[CardData] = []
	for card in deal.hand:
		if card.unique_id in ["standard_9_spades", "standard_9_hearts", "standard_9_diamonds"]:
			chosen.append(card)
	chosen[0].shiny = true
	var before := deal.wallet.balance_vnd
	var result := deal.create_meld(chosen)
	assert_true(result.ok)
	assert_eq(result.context.final_points, 81 + 27)
	assert_eq(deal.wallet.balance_vnd - before, VndWallet.points_to_vnd(108))

func test_lottery_settlement_is_reentrant_safe_and_counts_toward_requirement() -> void:
	var c := _campaign()
	var special_ticket: Dictionary = {}
	for seed_value in 100:
		c.lottery.reset_run()
		c.lottery.set_seed_value(seed_value)
		c.lottery.begin_day(0)
		c.lottery.begin_event(EventManager.EventSlot.MORNING)
		for ticket in c.lottery.offered_tickets():
			if int(ticket.number) == c.lottery.special_number():
				special_ticket = ticket
				break
		if not special_ticket.is_empty():
			break
	assert_false(special_ticket.is_empty())
	c.wallet.reset(MiscServiceConfig.TICKET_STAKE_VND)
	assert_true(c.lottery.purchase(special_ticket.id).ok)
	assert_eq(c.wallet.balance_vnd, 0)
	var reenter := func(_before: int, _after: int, _delta: int, reason: String) -> void:
		if reason == "lottery_settlement":
			assert_true(c.lottery.settle_day().is_empty())
	c.wallet.balance_changed.connect(reenter)
	c.campaign_days[0]["required_vnd"] = MiscServiceConfig.TICKET_STAKE_VND * 80
	c.lottery.begin_event(EventManager.EventSlot.AFTERNOON)
	c._finish_day()
	assert_true(c.collect_day_debt())
	assert_false(c.run_failed)
	assert_eq(c.current_day_index, 1)
	assert_eq(c.wallet.balance_vnd, 0)
	c.wallet.balance_changed.disconnect(reenter)
