@tool
extends McpTestSuite

func suite_name() -> String:
	return "hang_rong_shop"

func _fixture(seed_text: String = "shop-tests") -> Dictionary:
	var deal := DealState.new()
	var events := EventManager.new()
	CampaignNpcCatalog.register_initial_npcs(events)
	var campaign := CampaignManager.new(deal.wallet, events)
	campaign.drink_manager.progress = DrinkProgress.new("")
	campaign.bind_deal(deal)
	campaign.start_campaign(true, seed_text)
	deal.start_deal(campaign.seed_for("deal"))
	campaign._enter_phase(CampaignManager.CampaignPhase.MORNING_EVENT)
	deal.wallet.apply_vnd(10_000_000, "fixture")
	return {"campaign": campaign, "deal": deal, "shop": campaign.relic_shop}

func _ids(cards: Array[CardData]) -> Array:
	return cards.map(func(card: CardData): return card.unique_id)

func _stock(shop: RelicShop) -> Array:
	return shop.card_stock.map(func(card: CardData): return card.permanent_snapshot())

func test_visit_has_deterministic_stock_and_dedicated_card_rng() -> void:
	var a := _fixture()
	var b := _fixture()
	var shop: RelicShop = a.shop
	assert_eq(shop.offers, b.shop.offers)
	assert_eq(_stock(shop), _stock(b.shop))
	assert_eq(shop.offers.size(), 3)
	assert_eq(shop.card_stock.size(), 3)
	assert_eq(shop.price(), 12_500)
	assert_eq(shop.card_price(), 5_000)
	assert_eq(shop.removal_price(), 7_500)
	var old_stock := _stock(shop)
	var old_relics := shop.offers.duplicate()
	var rng := shop.run_rng_state()
	shop.begin_visit(shop.visit_id, 999, 99_000_000)
	assert_eq(_stock(shop), old_stock)
	assert_eq(shop.offers, old_relics)
	assert_eq(shop.run_rng_state(), rng)
	a.deal.wallet.apply_vnd(100_000_000, "fixture")
	assert_eq(shop.removal_price(), 7_500, "Pruning price never depends on the wallet")
	var streams := [a.campaign.gieo_que.run_rng_state(), a.campaign.lottery.run_rng_state(), a.campaign.shoe_shine.run_rng_state(), a.deal.deck._rng.state]
	assert_true(shop.buy(shop.offers[0]))
	assert_true(shop.buy_card(shop.card_stock[0].unique_id) != null)
	assert_true(shop.pay_removal())
	assert_eq([a.campaign.gieo_que.run_rng_state(), a.campaign.lottery.run_rng_state(), a.campaign.shoe_shine.run_rng_state(), a.deal.deck._rng.state], streams)
	assert_eq(shop.run_rng_state(), rng)
	assert_ne(_stock(_fixture("other-shop").shop), old_stock)

func test_relics_sell_individually_and_activate_beyond_four() -> void:
	var f := _fixture()
	var shop: RelicShop = f.shop
	for id in ["hair_clip", "comb", "sunflower_seeds", "lipstick", "hard_candy"]:
		f.deal.relics.acquire(id)
	shop.begin_visit("another-visit", 1234, 250_000)
	var stock := shop.offers.duplicate()
	var starting = f.deal.wallet.balance_vnd
	for index in stock.size():
		assert_true(shop.buy(stock[index]))
		assert_eq(shop.offers, stock.slice(index + 1))
		assert_true(f.deal.relics.equipped.has(stock[index]))
		assert_false(shop.buy(stock[index]))
	assert_eq(f.deal.wallet.balance_vnd, starting - stock.size() * shop.price())
	assert_eq(f.deal.relics.equipped.size(), 8)
	assert_eq(f.deal.relics.inventory, f.deal.relics.equipped)
	assert_eq(shop.relic_stock, stock)
	shop.begin_visit(shop.visit_id, 1, 1)
	assert_true(shop.offers.is_empty(), "Reopening sold stock never refills it")

func test_wallet_observers_see_complete_relic_and_card_transactions() -> void:
	var f := _fixture()
	var shop: RelicShop = f.shop
	var observations := []
	var first := shop.offers[0]
	var second := shop.offers[1]
	var callback := func(_before: int, _after: int, _delta: int, reason: String):
		if reason.begins_with("relic_purchase:"):
			observations.append(f.deal.relics.inventory.has(first) and f.deal.relics.equipped.has(first) and not shop.offers.has(first))
			observations.append(not shop.buy(second))
		elif reason.begins_with("card_purchase:"):
			var id := reason.trim_prefix("card_purchase:")
			observations.append(f.campaign.gieo_que.owned_card(id) != null and shop.sold_cards.has(shop.card_stock[0].unique_id) and f.deal.physical_card_locations().has(id))
			observations.append(shop.buy_card(shop.card_stock[1].unique_id) == null)
		var captured := RunSave.new().capture(f.campaign, f.deal)
		observations.append(RunSave.new().valid_snapshot(captured))
	f.deal.wallet.balance_changed.connect(callback)
	assert_true(shop.buy(first))
	assert_true(shop.buy_card(shop.card_stock[0].unique_id) != null)
	f.deal.wallet.balance_changed.disconnect(callback)
	assert_eq(observations.size(), 6)
	assert_true(observations.all(func(ok): return ok))
	assert_eq(f.deal.wallet.journal.filter(func(entry): return entry.reason.begins_with("card_purchase:")).size(), 1)
	assert_eq(f.deal.wallet.journal.filter(func(entry): return entry.reason.begins_with("relic_purchase:")).size(), 1)

func test_clean_duplicate_cards_draw_and_form_sets_larger_than_four() -> void:
	var f := _fixture()
	var shop: RelicShop = f.shop
	var purchased: Array[CardData] = []
	for offer in shop.card_stock:
		offer.rank = "9"
		offer.rank_index = 9
		offer.suit = "Spades"
		var card := shop.buy_card(offer.unique_id)
		assert_true(card != null)
		assert_eq(card.permanent_property_ids(), [])
		assert_eq(card.fortune, 0)
		assert_false(card.transformation_locked)
		assert_false(card.shiny)
		assert_false(card.unique_id == offer.unique_id)
		purchased.append(card)
	assert_eq(f.campaign.gieo_que.persistent_deck.size(), 55)
	assert_eq(_ids(purchased).size(), 3)
	assert_ne(purchased[0].unique_id, purchased[2].unique_id)
	assert_ne(purchased[0].unique_id, purchased[1].unique_id)
	assert_ne(purchased[1].unique_id, purchased[2].unique_id)
	assert_eq(shop.available_cards().size(), 0)
	assert_true(shop.buy_card(shop.card_stock[0].unique_id) == null)
	assert_true(f.deal.physical_card_accounting().valid)
	f.deal.start_deal(42)
	var all := _ids(f.deal.hand) + _ids(f.deal.deck.draw_pile)
	for card in purchased:
		assert_true(all.has(card.unique_id))
		assert_eq(all.count(card.unique_id), 1)
		assert_true(f.campaign.gieo_que.eligible_cards().has(card))
		assert_true(f.campaign.shoe_shine.cards().has(card))
	var cards: Array[CardData] = purchased.duplicate()
	cards.append(f.campaign.gieo_que.owned_card("standard_9_spades"))
	cards.append(f.campaign.gieo_que.owned_card("standard_9_hearts"))
	cards.append(f.campaign.gieo_que.owned_card("standard_9_clubs"))
	f.deal.hand.assign(cards)
	f.deal.hand.append(CardData.new("spare", "K", 13, "Hearts", 13))
	var created: Dictionary = f.deal.create_meld(cards.slice(0, 5))
	assert_true(created.ok, "A five-card Set may contain repeated suits")
	assert_true(f.deal.extend_meld(created.meld_id, cards.slice(5, 6)).ok)
	assert_eq(f.deal.melds[0].cards.size(), 6)

func test_failed_payment_or_addition_never_changes_stock_or_ownership() -> void:
	var f := _fixture()
	var shop: RelicShop = f.shop
	f.deal.wallet.reset(0)
	var relics := shop.offers.duplicate()
	var cards := _stock(shop)
	var count = f.campaign.gieo_que.persistent_deck.size()
	var entries = f.deal.wallet.journal.size()
	assert_false(shop.buy(shop.offers[0]))
	assert_true(shop.buy_card(shop.card_stock[0].unique_id) == null)
	assert_false(shop.pay_removal())
	assert_eq(shop.offers, relics)
	assert_eq(_stock(shop), cards)
	assert_eq(shop.sold_cards, [])
	assert_eq(f.campaign.gieo_que.persistent_deck.size(), count)
	assert_eq(f.deal.wallet.journal.size(), entries)
	f.deal.wallet.apply_vnd(100_000, "fixture")
	entries = f.deal.wallet.journal.size()
	f.campaign.gieo_que.state = GieoQueService.STATE_TARGET_SELECTION
	assert_true(shop.buy_card(shop.card_stock[0].unique_id) == null)
	assert_false(shop.pay_removal())
	assert_eq(f.deal.wallet.journal.size(), entries)
	f.campaign.gieo_que.state = GieoQueService.STATE_READY
	f.campaign.current_phase = CampaignManager.CampaignPhase.NOON_DEAL
	assert_true(shop.buy_card(shop.card_stock[0].unique_id) == null)
	assert_false(shop.buy(shop.offers[0]))
	assert_false(shop.pay_removal())

func test_remove_exact_transformed_sealed_card_from_every_live_owner() -> void:
	var f := _fixture()
	var shop: RelicShop = f.shop
	var owner: GieoQueService = f.campaign.gieo_que
	var target := owner.persistent_deck[0]
	var other := owner.persistent_deck[1]
	target.fortune = -4
	target.liquid = true
	target.negative = true
	target.shiny = true
	target.transformation_locked = true
	owner.resolved_targets.assign([target])
	owner.last_transformations.assign([{"card": target, "before": {}, "after": target.permanent_snapshot()}])
	var unchanged := other.permanent_snapshot()
	var before = f.deal.wallet.balance_vnd
	assert_true(shop.pay_removal())
	assert_eq(f.deal.wallet.balance_vnd, before - 7_500)
	assert_false(shop.pay_removal())
	assert_false(shop.choose_removal("foreign"))
	assert_true(shop.removal_pending)
	assert_true(shop.choose_removal(target.unique_id), "Sealed/transformed cards may be removed whole")
	var journal_count = f.deal.wallet.journal.size()
	assert_true(shop.confirm_removal())
	assert_false(shop.confirm_removal())
	assert_eq(f.deal.wallet.journal.size(), journal_count, "Confirmation does not charge twice")
	assert_false(shop.removal_pending)
	assert_eq(shop.removals, 1)
	assert_eq(shop.removal_price(), 11_500)
	assert_true(owner.owned_card(target.unique_id) == null)
	assert_false(_ids(owner.eligible_cards()).has(target.unique_id))
	assert_false(_ids(owner.resolved_targets).has(target.unique_id))
	assert_true(owner.last_transformations.is_empty())
	assert_false(_ids(f.campaign.shoe_shine.cards()).has(target.unique_id))
	assert_false(_ids(f.campaign.zodiac._watched_cards).has(target.unique_id))
	assert_false(_ids(f.deal.campaign_deck_cards).has(target.unique_id))
	assert_false(f.deal.physical_card_locations().has(target.unique_id))
	assert_true(f.deal.physical_card_accounting().valid)
	assert_eq(other.permanent_snapshot(), unchanged)
	f.deal.start_deal(314)
	assert_false((_ids(f.deal.hand) + _ids(f.deal.deck.draw_pile)).has(target.unique_id))

func test_paid_removal_survives_target_changes_and_cannot_leave_event() -> void:
	var f := _fixture()
	var shop: RelicShop = f.shop
	var target: CardData = f.campaign.gieo_que.persistent_deck[0]
	assert_true(shop.pay_removal())
	assert_false(f.campaign.complete_current_event())
	assert_true(shop.choose_removal(target.unique_id))
	target.adjust_fortune(1)
	assert_false(shop.confirm_removal(), "Changed card requires a fresh selection")
	assert_true(shop.removal_pending)
	assert_eq(shop.removals, 0)
	var count = f.deal.wallet.journal.size()
	assert_true(shop.choose_removal(target.unique_id))
	assert_true(shop.confirm_removal())
	assert_eq(f.deal.wallet.journal.size(), count)
	shop.begin_visit("later-visit", 15, 250_000)
	assert_eq(shop.removal_price(), 11_500)
	assert_true(shop.pay_removal())
	assert_true(shop.choose_removal(f.campaign.gieo_que.persistent_deck[0].unique_id))
	assert_true(shop.confirm_removal())
	assert_eq(shop.removals, 2)
	assert_eq(shop.removal_price(), 17_000)

func test_only_runtime_minimum_blocks_pruning_and_small_deck_refills() -> void:
	var f := _fixture()
	var owner: GieoQueService = f.campaign.gieo_que
	owner.persistent_deck.resize(DealState.MIN_CAMPAIGN_CARDS + 1)
	f.campaign.synchronize_run_deck()
	assert_true(f.shop.pay_removal())
	assert_true(f.shop.choose_removal(owner.persistent_deck[-1].unique_id))
	assert_true(f.shop.confirm_removal())
	assert_eq(owner.persistent_deck.size(), 17)
	var before = f.deal.wallet.balance_vnd
	assert_false(f.shop.pay_removal())
	assert_eq(f.deal.wallet.balance_vnd, before)
	assert_true(RunSave.new().valid_snapshot(RunSave.new().capture(f.campaign, f.deal)))
	var deal: DealState = f.deal
	deal.start_deal(15)
	assert_eq(deal.hand.size(), 10)
	for phase in [1, 2]:
		for turn in 4:
			assert_true(deal.discard_card(deal.hand[0]).ok)
			assert_eq(deal.hand.size(), 10 if turn < 3 else 9)
		assert_true(deal.settle_phase().ok)
		if phase == 1: assert_true(deal.choose_phase_two(false).ok)
	assert_true(deal.physical_card_accounting().valid)

func test_file_roundtrip_preserves_paid_ticket_sold_stock_and_owned_ids() -> void:
	var f := _fixture()
	var shop: RelicShop = f.shop
	var relic := shop.offers[0]
	var card := shop.buy_card(shop.card_stock[0].unique_id)
	assert_true(shop.buy(relic))
	var target: CardData = f.campaign.gieo_que.persistent_deck[0]
	target.fortune = 3
	target.liquid = true
	assert_true(shop.pay_removal())
	assert_true(shop.choose_removal(target.unique_id))
	var save := RunSave.new("user://shop-unit-roundtrip.save")
	assert_true(save.save_run(f.campaign, f.deal))
	var loaded := save.load_run()
	assert_false(loaded.is_empty(), save.error)
	var restored := _fixture("other")
	assert_true(save.restore(loaded, restored.campaign, restored.deal))
	var resumed: RelicShop = restored.shop
	assert_eq(resumed.offers, shop.offers)
	assert_eq(_stock(resumed), _stock(shop))
	assert_eq(resumed.sold_cards, shop.sold_cards)
	assert_eq(resumed.run_rng_state(), shop.run_rng_state())
	assert_eq(resumed.removal_paid_vnd, 7_500)
	assert_true(resumed.removal_pending)
	assert_eq(resumed.removal_target_id, target.unique_id)
	assert_true(restored.campaign.gieo_que.owned_card(card.unique_id) != null)
	assert_eq(restored.deal.wallet.balance_vnd, f.deal.wallet.balance_vnd)
	var balance = restored.deal.wallet.balance_vnd
	assert_true(resumed.confirm_removal())
	assert_eq(restored.deal.wallet.balance_vnd, balance)
	assert_eq(resumed.removals, 1)
	assert_false(resumed.buy(relic))
	assert_true(resumed.buy_card(resumed.card_stock[0].unique_id) == null)
	assert_true(save.save_run(restored.campaign, restored.deal))
	assert_true(save.restore(save.load_run(), f.campaign, f.deal))
	assert_true(f.campaign.gieo_que.owned_card(target.unique_id) == null)
	assert_false(_ids(f.campaign.shoe_shine.cards()).has(target.unique_id))
	assert_true(f.deal.physical_card_accounting().valid)

func test_legacy_save_keeps_card_properties_stock_and_all_relics() -> void:
	var f := _fixture()
	for id: String in RelicCatalog.DEFINITIONS: f.deal.relics.acquire(id)
	var transformed: CardData = f.campaign.gieo_que.persistent_deck[0]
	transformed.fortune = -6
	transformed.liquid = true
	transformed.negative = true
	transformed.transformation_locked = true
	var snapshot := RunSave.new().capture(f.campaign, f.deal)
	snapshot.deal.relics.equipped = ["hair_clip", "comb", "buttons", "rubber_band"]
	snapshot.shop = {"offers": f.shop.offers.duplicate(), "visit_id": f.shop.visit_id, "purchased": false, "rerolls": 2, "target_vnd": 250_000}
	var original_rng: int = snapshot.shop_rng
	var restored := _fixture("different")
	assert_true(RunSave.new().restore(snapshot, restored.campaign, restored.deal))
	assert_eq(restored.deal.relics.inventory.size(), 10)
	assert_eq(restored.deal.relics.equipped.size(), 10)
	assert_eq(restored.campaign.gieo_que.persistent_deck[0].permanent_snapshot(), transformed.permanent_snapshot())
	assert_eq(restored.shop.offers, snapshot.shop.offers)
	assert_eq(restored.shop.run_rng_state(), original_rng)
	assert_eq(restored.shop.card_stock.size(), 3)
	var cards := _stock(restored.shop)
	restored.shop.begin_visit(restored.shop.visit_id, 99, 1)
	assert_eq(_stock(restored.shop), cards)
	assert_eq(restored.shop.removals, 0)

func test_removal_purges_completed_deal_card_snapshots() -> void:
	var f := _fixture()
	var deal: DealState = f.deal
	for phase in [1, 2]:
		for _turn in 4: deal.discard_card(deal.hand[0])
		assert_true(deal.settle_phase().ok)
		if phase == 1: assert_true(deal.choose_phase_two(false).ok)
	var removed_id := deal.hand[0].unique_id
	var before_ids: Array = _ids(deal.last_phase_resolution.remaining_hand)
	assert_true(before_ids.has(removed_id))
	assert_true(f.shop.pay_removal())
	assert_true(f.shop.choose_removal(removed_id))
	assert_true(f.shop.confirm_removal())
	assert_false(_ids(deal.last_phase_resolution.remaining_hand).has(removed_id))
	for settlement in deal.settlements:
		assert_false(_ids(settlement.remaining_hand).has(removed_id))
	var save := RunSave.new("user://completed-deal-removal.save")
	assert_true(save.save_run(f.campaign, deal))
	var loaded := save.load_run()
	assert_false(loaded.is_empty(), save.error)
	assert_false(loaded.deal.last_phase_resolution.remaining_hand.map(func(card): return card.unique_id).has(removed_id))
	assert_true(deal.physical_card_accounting().valid)

func test_boss_lab_resets_temporary_shop_and_restores_real_paid_ticket() -> void:
	var f := _fixture()
	# The production lab requires detached progression providers.
	f.campaign.zodiac.progress.path = ""
	f.campaign.difficulty_progress.path = ""
	var shop: RelicShop = f.shop
	var target: CardData = f.campaign.gieo_que.persistent_deck[0]
	assert_true(shop.pay_removal())
	assert_true(shop.choose_removal(target.unique_id))
	var stock := _stock(shop)
	var save := RunSave.new("user://shop-boss-lab-return.save")
	assert_true(save.save_run(f.campaign, f.deal))
	var saved := save.load_run()
	assert_true(BossDebugSession.prepare(f.campaign, f.deal, {"boss": "rooster"}), "Detached Boss Lab fixture starts")
	assert_false(shop.removal_pending, "The isolated lab has no real-run commitment")
	assert_eq(shop.removals, 0)
	assert_true(shop.card_stock.is_empty())
	assert_true(save.restore(saved, f.campaign, f.deal))
	assert_true(shop.removal_pending, "Returning restores the real paid ticket")
	assert_eq(shop.removal_target_id, target.unique_id)
	assert_eq(_stock(shop), stock)
	assert_true(shop.confirm_removal())
