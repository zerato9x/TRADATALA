@tool
extends McpTestSuite

func suite_name() -> String:
	return "resolve_accounting"

func test_journal_reconciles_every_reason_and_returns_detached_receipts() -> void:
	var wallet := VndWallet.new()
	wallet.reset(100)
	wallet.apply_vnd(900, "new_meld")
	var cursor := wallet.journal.size()
	wallet.apply_vnd(-200, "deadwood")
	wallet.apply_vnd(40, "relic:comb")
	var report := wallet.report()
	assert_eq(report.opening_vnd + report.income_vnd - report.expense_vnd, report.closing_vnd)
	assert_eq(report.net_vnd, 740)
	assert_eq(wallet.report(cursor).net_vnd, -160)
	report.entries.clear()
	assert_eq(wallet.journal.size(), 3)

func test_collection_pauses_pays_once_and_blocks_reentrant_charge() -> void:
	var days: Array[Dictionary] = [{"id": "test", "required_vnd": 1000}]
	var c := CampaignManager.new(null, null, null, days)
	c.start_campaign()
	c.wallet.apply_vnd(1500, "new_meld")
	c._finish_day()
	assert_false(c.campaign_complete)
	assert_eq(c.wallet.balance_vnd, 1500)
	var listener := func(_a: int, _b: int, _d: int, reason: String):
		if reason == "daily_debt":
			assert_false(c.collect_day_debt())
	c.wallet.balance_changed.connect(listener)
	assert_true(c.collect_day_debt())
	assert_true(c.campaign_complete)
	assert_eq(c.wallet.balance_vnd, 500)
	assert_false(c.collect_day_debt())
	assert_eq(c.wallet.report().categories.daily_debt, -1000)
	c.wallet.balance_changed.disconnect(listener)

func test_shortfall_does_not_charge_or_advance_and_restart_clears_history() -> void:
	var days: Array[Dictionary] = [{"id": "test", "required_vnd": 1000}]
	var c := CampaignManager.new(null, null, null, days)
	c.start_campaign()
	c.wallet.apply_vnd(500, "new_meld")
	c._finish_day()
	assert_eq(c.collection_report.shortfall_vnd, 500)
	assert_true(c.collect_day_debt())
	assert_true(c.run_failed)
	assert_eq(c.wallet.balance_vnd, 500)
	c.start_campaign()
	assert_true(c.wallet.journal.is_empty())
	assert_true(c.day_reports.is_empty())

func test_tutorial_restores_wallet_ledger_and_action_counts() -> void:
	var deal := DealState.new()
	deal.start_deal(76)
	deal.wallet.apply_vnd(2000, "new_meld")
	var snapshot := deal.snapshot_state()
	var before := deal.accounting_report()
	deal.start_tutorial_deal()
	deal.wallet.apply_vnd(999999, "tutorial")
	deal.restore_snapshot(snapshot)
	assert_eq(deal.accounting_report(), before)

func test_cost_scaling_preserves_free_choice_and_prices_paid_services() -> void:
	var wallet := VndWallet.new()
	wallet.reset(10_000_000)
	wallet.economy_scaling = true
	assert_eq(wallet.scaled_cost(10_000), 200_000)
	assert_eq(wallet.scaled_cost(0), 0)
	var drinks := DrinkManager.new(wallet)
	assert_eq(drinks.price_for(DrinkCatalog.TRA_DA), 0)
	assert_eq(drinks.price_for(DrinkCatalog.NUOC_VOI), 5_000)
	var quoted := drinks.price_for(DrinkCatalog.NUOC_VOI)
	assert_true(drinks.select_for_event(EventManager.EventSlot.STARTER, DrinkCatalog.NUOC_VOI).ok)
	assert_eq(wallet.balance_vnd, 10_000_000 - quoted)
	assert_false(drinks.select_for_event(EventManager.EventSlot.STARTER, DrinkCatalog.NUOC_VOI).ok)
	assert_eq(wallet.journal.size(), 1)

func test_full_deal_records_real_actions_without_presentation_payments() -> void:
	var deal := DealState.new()
	deal.start_tutorial_deal()
	var cards: Array[CardData] = []
	for card in deal.hand:
		if card.rank_index == 9:
			cards.append(card)
	assert_true(deal.create_meld(cards).ok)
	var report := deal.accounting_report()
	assert_eq(report.counts.new_meld, 1)
	assert_eq(report.counts.card_triggers, 3)
	assert_eq(report.net_vnd, deal.wallet.balance_vnd)
	var before := deal.wallet.balance_vnd
	deal.accounting_report()
	deal.accounting_report()
	assert_eq(deal.wallet.balance_vnd, before)


func test_relic_purchase_uses_real_wallet_and_reequip_is_free() -> void:
	var wallet := VndWallet.new()
	wallet.reset(1_000_000)
	wallet.economy_scaling = true
	var relics := RelicRuntime.new()
	relics.shop_wallet = wallet
	assert_true(relics.purchase_and_equip("comb"))
	assert_eq(wallet.balance_vnd, 950_000)
	relics.remove("comb")
	assert_true(relics.purchase_and_equip("comb"))
	assert_eq(wallet.balance_vnd, 950_000)
	assert_eq(wallet.journal.size(), 1)
	wallet.reset(0)
	assert_false(relics.purchase_and_equip("hair_clip"))
	assert_false(relics.inventory.has("hair_clip"))


func test_two_real_phases_reconcile_all_deadwood_and_mom() -> void:
	var deal := DealState.new()
	deal.start_deal(1776)
	for phase in [1, 2]:
		for turn in 4:
			assert_true(deal.discard_card(deal.hand[0]).ok)
		assert_true(deal.settle_phase().ok)
		if phase == 1:
			assert_true(deal.choose_phase_two(false).ok)
	var report := deal.accounting_report()
	assert_eq(report.phases.size(), 2)
	assert_eq(report.counts.discard, 8)
	assert_eq(report.counts.mom, 2)
	assert_eq(report.net_vnd, report.closing_vnd - report.opening_vnd)
	assert_eq(report.phases[0].net_vnd + report.phases[1].net_vnd, report.net_vnd)
