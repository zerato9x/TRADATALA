extends SceneTree
var checks := 0
var failures: Array[String] = []

func _initialize() -> void:
	call_deferred("_run")

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok: failures.append(message)

func streams(campaign: CampaignManager, deal: DealState) -> Array:
	return [campaign.gieo_que.run_rng_state(), campaign.lottery.run_rng_state(),
		campaign.relic_shop.run_rng_state(), campaign.zodiac._rng.state, deal.deck._rng.state]

func _run() -> void:
	var deal := DealState.new()
	var events := EventManager.new()
	CampaignNpcCatalog.register_initial_npcs(events)
	var campaign := CampaignManager.new(deal.wallet, events)
	campaign.drink_manager.progress = DrinkProgress.new("")
	campaign.bind_deal(deal)
	var save := RunSave.new("user://shoe-fresh-process.save")
	if OS.get_cmdline_user_args().has("--read"):
		var data := save.load_run()
		check(not data.is_empty(), "fresh process reads complete run envelope")
		if data.is_empty():
			finish()
			return
		check(save.restore(data, campaign, deal), "fresh process restores card owners")
		var file := FileAccess.open("user://shoe-fresh-expected.bin", FileAccess.READ)
		var expected: Dictionary = file.get_var(false)
		file.close()
		var shoe := campaign.shoe_shine
		check(shoe.visit_started and shoe.is_active(), "Starter visit resumes")
		check(shoe.run_snapshot() == expected.service, "selected IDs, counts, price curve and receipt resume")
		check(shoe.selected_card_ids.size() == 2, "selected card count resumes")
		check(shoe.run_rng_state() == expected.rng, "dedicated RNG resumes")
		check(deal.wallet.balance_vnd == expected.wallet, "resume creates no duplicate payment")
		check(deal.wallet.journal.size() == expected.entries, "resume creates no duplicate ledger entry")
		check(streams(campaign, deal) == expected.streams, "all unrelated RNG streams resume")
		check(campaign.gieo_que.persistent_deck.map(func(card): return card.run_value_snapshot()) == expected.cards, "every committed identity and property resumes")
		var id: String = shoe.selected_card_ids[0]
		check(shoe.card_for_id(id) == campaign.gieo_que.persistent_deck[0], "bench resolves the canonical physical object")
		check(not shoe.choose_card(campaign.gieo_que.persistent_deck[2].unique_id).ok, "fresh process cannot select a third card")
		shoe.begin_event(EventManager.EventSlot.STARTER)
		check(shoe.run_rng_state() == expected.rng, "reopen does not reroll a result")
		check(shoe.reroll_rank(id) == expected.next_rank, "exact next Rank result reproduces")
		check(shoe.reroll_suit(id) == expected.next_suit, "exact next Suit result reproduces")
		check(streams(campaign, deal) == expected.streams, "resumed rerolls consume only their own RNG")
		check(save.save_run(campaign, deal), "new committed identity persists")
		deal.start_deal(campaign.seed_for("deal", 8))
		var found: CardData
		for card in deal.hand + deal.deck.draw_pile:
			if card.unique_id == id: found = card
		check(found != null and found.permanent_snapshot() == shoe.card_for_id(id).permanent_snapshot(), "future Deal copies the current identity")
		check(deal.physical_card_accounting().valid, "physical deck remains complete")
	else:
		campaign.start_campaign(true, "SHOE-FRESH-PROCESS")
		deal.start_deal(campaign.seed_for("deal"))
		deal.wallet.reset(2_000_000)
		var shoe := campaign.shoe_shine
		var card := campaign.gieo_que.persistent_deck[0]
		card.fortune = -5
		card.liquid = true
		card.negative = true
		card.enhancements.assign(["future_saved_metadata"])
		check(shoe.choose_card(card.unique_id).ok, "first exact physical card commits")
		check(shoe.choose_card(campaign.gieo_que.persistent_deck[1].unique_id).ok, "second exact physical card commits")
		var unrelated := streams(campaign, deal)
		for _i in 3: check(shoe.reroll_rank(card.unique_id).ok, "repeated Rank payment commits")
		for _i in 2: check(shoe.reroll_suit(card.unique_id).ok, "repeated Suit payment commits")
		check(streams(campaign, deal) == unrelated, "writer does not consume unrelated RNG")
		var expected := {"service": shoe.run_snapshot().duplicate(true), "rng": shoe.run_rng_state(),
			"wallet": deal.wallet.balance_vnd, "entries": deal.wallet.journal.size(),
			"cards": campaign.gieo_que.persistent_deck.map(func(c): return c.run_value_snapshot().duplicate(true)),
			"streams": unrelated}
		check(save.save_run(campaign, deal), "write saves committed mutations before quit")
		expected.next_rank = shoe.reroll_rank(card.unique_id)
		expected.next_suit = shoe.reroll_suit(card.unique_id)
		var file := FileAccess.open("user://shoe-fresh-expected.bin", FileAccess.WRITE)
		file.store_var(expected, false)
		file.close()
	finish()

func finish() -> void:
	for message in failures: print("SHOE_SHINE_RESUME_FAIL " + message)
	print("SHOE_SHINE_RESUME_SMOKE checks=%d failures=%d" % [checks, failures.size()])
	quit(0 if failures.is_empty() else 1)