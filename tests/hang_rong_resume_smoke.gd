extends SceneTree
## Separate processes prove sold stock and a paid removal ticket survive a real quit.
var failures: Array[String] = []
var checks := 0

func _initialize() -> void:
	call_deferred("_run")

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok: failures.append(message)

func ids(cards: Array[CardData]) -> Array:
	return cards.map(func(card: CardData): return card.unique_id)

func _run() -> void:
	var deal := DealState.new()
	var events := EventManager.new()
	CampaignNpcCatalog.register_initial_npcs(events)
	var campaign := CampaignManager.new(deal.wallet, events)
	campaign.drink_manager.progress = DrinkProgress.new("")
	campaign.bind_deal(deal)
	var save := RunSave.new("user://hang-rong-fresh.save")
	if OS.get_cmdline_user_args().has("--read"):
		var data := save.load_run()
		check(not data.is_empty(), "fresh process reads committed envelope")
		if data.is_empty():
			_finish()
			return
		check(save.restore(data, campaign, deal), "fresh process restores owners")
		var file := FileAccess.open("user://hang-rong-expected.bin", FileAccess.READ)
		var expected: Dictionary = file.get_var(false)
		file.close()
		var shop := campaign.relic_shop
		check(shop.removal_pending, "paid ticket survives quit")
		check(shop.removal_paid_vnd == expected.paid, "paid amount survives quit")
		check(shop.removal_target_id == expected.target, "exact target survives quit")
		check(deal.wallet.balance_vnd == expected.wallet, "resume charges nothing")
		check(shop.offers == expected.offers, "remaining relic stock is unchanged")
		check(shop.sold_cards == expected.sold_cards, "sold cards stay sold")
		check(shop.card_stock.map(func(card): return card.permanent_snapshot()) == expected.stock, "concrete stock is unchanged")
		check(shop.run_rng_state() == expected.shop_rng, "shop RNG resumes exactly")
		check(campaign.gieo_que.run_rng_state() == expected.gieo_rng, "Gieo RNG is unaffected")
		check(campaign.lottery.run_rng_state() == expected.lottery_rng, "lottery RNG is unaffected")
		check(campaign.shoe_shine.run_rng_state() == expected.shoe_rng, "polish RNG is unaffected")
		check(deal.deck._rng.state == expected.deck_rng, "draw RNG is unaffected")
		check(deal.relics.equipped.size() == 6, "all six owned relics resume active")
		check(not shop.buy(expected.relic), "sold relic cannot duplicate on resume")
		check(shop.buy_card(expected.sold_cards[0]) == null, "sold card cannot duplicate on resume")
		check(shop.removal_target().permanent_snapshot() == expected.target_state, "sealed Glitch/Black Ink target restores exactly")
		var wallet_before := deal.wallet.balance_vnd
		var entries := deal.wallet.journal.size()
		check(shop.confirm_removal(), "paid selection completes after restart")
		check(not shop.confirm_removal(), "removal cannot duplicate")
		check(deal.wallet.balance_vnd == wallet_before and deal.wallet.journal.size() == entries, "confirmation charges nothing")
		check(campaign.gieo_que.owned_card(expected.target) == null, "removed card leaves canonical deck")
		check(not ids(campaign.shoe_shine.cards()).has(expected.target), "removed card leaves NPC pool")
		check(deal.physical_card_accounting().valid, "resumed card graph accounts correctly")
		check(shop.removals == 1 and shop.removal_price() > expected.paid, "run-wide pruning curve resumes")
		check(save.save_run(campaign, deal), "post-removal save commits")
		var remaining := save.load_run()
		var other := DealState.new()
		var next := CampaignManager.new(other.wallet, events)
		next.drink_manager.progress = DrinkProgress.new("")
		check(save.restore(remaining, next, other), "post-removal state reloads")
		check(next.gieo_que.owned_card(expected.target) == null, "removed card does not return after another load")
		other.start_deal(next.seed_for("deal", 7))
		var all_ids := ids(other.hand) + ids(other.deck.draw_pile)
		for id in expected.acquired:
			check(all_ids.count(id) == 1, "purchased card draws as one distinct physical card")
		check(not all_ids.has(expected.target), "removed card is absent from future draws")
		check(other.physical_card_accounting().valid, "future deal accounts for modified deck")
	else:
		campaign.start_campaign(true, "HANG-RONG-FRESH-PROCESS")
		deal.start_deal(campaign.seed_for("deal"))
		campaign._enter_phase(CampaignManager.CampaignPhase.MORNING_EVENT)
		deal.wallet.apply_vnd(1_000_000, "fixture")
		var shop := campaign.relic_shop
		var relic := shop.offers[0]
		for id: String in RelicCatalog.DEFINITIONS:
			if not shop.offers.has(id) and deal.relics.inventory.size() < 5: deal.relics.acquire(id)
		check(shop.buy(relic), "one relic purchased")
		var acquired: Array[String] = []
		for index in 2:
			var card := shop.buy_card(shop.card_stock[index].unique_id)
			check(card != null, "ordinary card purchased")
			if card != null: acquired.append(card.unique_id)
		var target := campaign.gieo_que.persistent_deck[0]
		target.fortune = -4
		target.liquid = true
		target.negative = true
		target.transformation_locked = true
		check(shop.pay_removal(), "removal charged")
		check(shop.choose_removal(target.unique_id), "whole sealed card selected")
		var expected := {
			"wallet": deal.wallet.balance_vnd, "paid": shop.removal_paid_vnd,
			"target": target.unique_id, "target_state": target.permanent_snapshot(),
			"relic": relic, "acquired": acquired,
			"offers": shop.offers.duplicate(), "sold_cards": shop.sold_cards.duplicate(),
			"stock": shop.card_stock.map(func(card): return card.permanent_snapshot()),
			"shop_rng": shop.run_rng_state(), "gieo_rng": campaign.gieo_que.run_rng_state(),
			"lottery_rng": campaign.lottery.run_rng_state(), "shoe_rng": campaign.shoe_shine.run_rng_state(),
			"deck_rng": deal.deck._rng.state,
		}
		var file := FileAccess.open("user://hang-rong-expected.bin", FileAccess.WRITE)
		file.store_var(expected, false)
		file.close()
		check(save.save_run(campaign, deal), "paid ticket and sold stock saved before quitting")
	_finish()

func _finish() -> void:
	for failure in failures: print("HANG_RONG_RESUME_FAIL " + failure)
	print("HANG_RONG_RESUME_SMOKE checks=%d failures=%d" % [checks, failures.size()])
	quit(0 if failures.is_empty() else 1)
