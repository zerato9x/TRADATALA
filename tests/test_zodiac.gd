@tool
extends McpTestSuite

func suite_name() -> String:
	return "zodiac"

func _campaign(id: String = "rooster") -> CampaignManager:
	var deal := DealState.new()
	var campaign := CampaignManager.new(deal.wallet)
	campaign.zodiac.bind(campaign, deal)
	campaign.relic_shop.runtime = deal.relics
	campaign.zodiac.progress.commit(id, "fixture", {}, ["emblem_unlocked"])
	campaign.zodiac.choose_emblem(0, id)
	campaign.start_campaign(true, "zodiac-tests")
	# These fixtures exercise the saved demand grammar. Fresh Rooster has its own suite.
	if id == "rooster": campaign.zodiac.daily["legacy_negotiation"] = true
	return campaign

func _event(campaign: CampaignManager, slot: int) -> void:
	var phases := [CampaignManager.CampaignPhase.STARTER_EVENT, CampaignManager.CampaignPhase.MORNING_EVENT, CampaignManager.CampaignPhase.NOON_EVENT, CampaignManager.CampaignPhase.AFTERNOON_EVENT]
	campaign._enter_phase(phases[slot])

func _tutorial(id: String, mood: String) -> DealState:
	var deal := DealState.new()
	deal.start_tutorial_deal()
	deal.zodiac_boss.configure(id, mood, 5678)
	return deal

func test_seeded_pairs_and_unfinished_pairs() -> void:
	var seen := {}
	for seed_value in 100:
		var id := ZodiacCatalog.select(seed_value, 0)
		assert_eq(id, ZodiacCatalog.select(seed_value, 0))
		assert_true(id in ["rooster", "cat"])
		seen[id] = true
	assert_eq(seen.size(), 2)
	assert_true(ZodiacCatalog.select(5, 1) in ["dog", "monkey"])
	assert_eq(ZodiacCatalog.select(5, 5), "snake")
	assert_eq(ZodiacCatalog.select(5, 6), "")
	assert_eq(ZodiacCatalog.PAIRS.size(), 6)

func test_emblem_authority_and_no_selection_rng_side_effect() -> void:
	var campaign := CampaignManager.new()
	assert_false(campaign.zodiac.choose_emblem(0, "cat"))
	campaign.zodiac.progress.commit("cat", "test", {}, ["emblem_unlocked"])
	assert_false(campaign.zodiac.choose_emblem(1, "cat"))
	assert_true(campaign.zodiac.choose_emblem(0, "cat"))
	campaign.start_campaign(true, "fixed")
	assert_eq(campaign.zodiac.active_id(), "cat")
	assert_false(campaign.zodiac.choose_emblem(0, "rooster"))
	var normal := CampaignManager.new()
	normal.start_campaign(true, "fixed")
	assert_eq(campaign.seed_for("deal", 0), normal.seed_for("deal", 0))
	assert_eq(campaign.gieo_que._rng.state, normal.gieo_que._rng.state)

func _noon(id: String = "rooster") -> CampaignManager:
	var campaign := _campaign(id)
	_event(campaign, EventManager.EventSlot.NOON)
	return campaign

func _finish_noon(campaign: CampaignManager) -> void:
	assert_true(preload("res://tests/zodiac_test_flow.gd").finish_noon(campaign.zodiac))

func test_noon_afternoon_only_configured_chain_and_safe_inert_profiles() -> void:
	var campaign := _campaign()
	assert_false(campaign.zodiac.visitor_available(EventManager.EventSlot.STARTER))
	assert_false(campaign.zodiac.respond("ACCEPT").ok)
	_event(campaign, EventManager.EventSlot.MORNING)
	assert_false(campaign.zodiac.visitor_available(EventManager.EventSlot.MORNING))
	_event(campaign, EventManager.EventSlot.NOON)
	assert_true(campaign.zodiac.visitor_available(EventManager.EventSlot.NOON))
	assert_true(campaign.zodiac.has_open_demand())
	assert_true(int(campaign.zodiac.negotiation().demand_count) in range(2, 5))
	assert_false(campaign.complete_current_event())
	var count: int = campaign.zodiac.negotiation().demand_count
	_finish_noon(campaign)
	assert_eq(campaign.zodiac.negotiation().resolved_demand_count, count)
	assert_eq(campaign.zodiac.negotiation().refusal_count, count)
	assert_false(campaign.zodiac.visitor_available(EventManager.EventSlot.NOON))
	assert_eq(campaign.zodiac.mood(), "PLEASED")
	_event(campaign, EventManager.EventSlot.AFTERNOON)
	assert_true(campaign.zodiac.visitor_available(EventManager.EventSlot.AFTERNOON))
	assert_false(campaign.zodiac.respond("ACCEPT").ok)
	campaign.zodiac.daily.id = "dog"
	campaign.zodiac.daily.erase("negotiation")
	_event(campaign, EventManager.EventSlot.NOON)
	assert_false(campaign.zodiac.has_open_demand())
	assert_true(campaign.zodiac.quote().demand.is_empty())
	assert_true(ZodiacCatalog.negotiation_profile("dog").is_empty())
	campaign.zodiac.daily.successes = 0
	assert_eq(campaign.zodiac.mood(), "NORMAL")

func test_accept_pay_journal_idempotence_and_no_hidden_haggle_cost() -> void:
	var campaign := _noon()
	var service := campaign.zodiac
	service.debug_offer(ZodiacDemand.make("PAY", "ANY", "PLAYER_CHOOSES", 1, "", 5000))
	var token := service.offer_token()
	var before := campaign.wallet.balance_vnd
	var haggle := service.respond("HAGGLE", [], token)
	assert_true(haggle.requires_confirmation)
	assert_eq(service.current_demand().resource_amount, 2500)
	assert_eq(campaign.wallet.balance_vnd, before)
	assert_false(service.respond("ACCEPT", [], token).ok)
	assert_eq(service.negotiation().resolved_demand_count, 0)
	token = service.offer_token()
	assert_true(service.respond("ACCEPT", [], token).resolved_successfully)
	assert_eq(campaign.wallet.balance_vnd, before - 2500)
	assert_eq(campaign.wallet.journal[-1].reason, "zodiac_request:rooster")
	assert_false(service.respond("ACCEPT", [], token).ok)
	assert_eq(campaign.wallet.balance_vnd, before - 2500)
	assert_eq(service.progress.record("rooster").counteroffers_accepted, 1)

func test_card_legality_and_current_persistent_queries() -> void:
	var cards := DeckManager.new().build_standard_deck()
	var plain := cards[0]
	assert_false(ZodiacDemand.legal(plain, ZodiacDemand.make("REMOVE_PROPERTY")))
	assert_false(ZodiacDemand.legal(plain, ZodiacDemand.make("RESET")))
	plain.adjust_fortune(2)
	plain.add_jackpot(CardData.JACKPOT_LIQUID)
	assert_true(ZodiacDemand.legal(plain, ZodiacDemand.make("RESET")))
	plain.apply_rank("K", 13)
	plain.apply_suit("Hearts")
	assert_true(CardTargetQuery.transformed_rank(plain))
	assert_true(CardTargetQuery.transformed_suit(plain))
	assert_true(CardTargetQuery.pool(cards, "TRANSFORMED_ANY").has(plain))
	assert_true(CardTargetQuery.pool(cards, "TRANSFORMED_RANK").has(plain))
	assert_true(CardTargetQuery.pool(cards, "TRANSFORMED_SUIT").has(plain))
	assert_true(CardTargetQuery.pool(cards, "HAS_GOLD_PROPERTY").has(plain))
	assert_eq(CardTargetQuery.pool(cards, "HIGHEST_PROPERTY_COUNT"), [plain])
	assert_false(CardTargetQuery.with_suit(cards, "Spades").has(plain))
	assert_true(CardTargetQuery.with_rank(cards, 13).has(plain))
	plain.transformation_locked = true
	assert_false(ZodiacDemand.legal(plain, ZodiacDemand.make("SEAL")))
	assert_false(ZodiacDemand.legal(plain, ZodiacDemand.make("SET_RANK", "ANY", "PLAYER_CHOOSES", 1, "2")))
	assert_false(ZodiacDemand.legal(plain, ZodiacDemand.make("SET_SUIT", "ANY", "PLAYER_CHOOSES", 1, "Clubs")))

func test_all_card_verbs_preserve_ids_and_atomic_invalid_selection() -> void:
	for verb in ZodiacDemand.CARD_VERBS:
		var campaign := _noon()
		var service := campaign.zodiac
		var card: CardData = campaign.gieo_que.persistent_deck[0]
		var id := card.unique_id
		card.apply_rank("K", 13)
		card.adjust_fortune(2)
		card.add_jackpot(CardData.JACKPOT_LIQUID)
		var destination := "2" if verb == "SET_RANK" else "Hearts" if verb == "SET_SUIT" else ""
		assert_false(service.debug_offer(ZodiacDemand.make(verb, "ANY", "PLAYER_CHOOSES", 1, destination)).is_empty())
		assert_false(service.respond("ACCEPT", "not_owned").ok)
		assert_true(service.respond("ACCEPT", id).ok)
		assert_eq(campaign.gieo_que.persistent_deck.size(), 52)
		assert_eq(card.unique_id, id)
		match verb:
			"RESET": assert_eq(card.rank, "A"); assert_false(card.has_fortune_properties())
			"REMOVE_PROPERTY": assert_eq(card.fortune, 2); assert_false(card.liquid)
			"SEAL":
				card.apply_rank("2", 2)
				assert_eq(card.rank, "K")
				assert_true(card.copy_for_deal().transformation_locked)
			"SET_RANK": assert_eq(card.rank, "2")
			"SET_SUIT": assert_eq(card.suit, "Hearts")
	var campaign := _noon()
	var service := campaign.zodiac
	var cards := campaign.gieo_que.persistent_deck
	service.debug_offer(ZodiacDemand.make("SEAL", "SAME_SUIT_2", "PLAYER_CHOOSES", 2))
	var first := cards[0]
	var different: CardData
	for card in cards:
		if card.suit != first.suit: different = card; break
	assert_false(service.respond("ACCEPT", [first.unique_id, different.unique_id]).ok)
	assert_false(first.transformation_locked)
	assert_false(different.transformation_locked)
	assert_false(service.respond("ACCEPT", [first.unique_id, first.unique_id]).ok)

func test_target_authority_offers_groups_and_exact_fallbacks() -> void:
	var campaign := _noon()
	var service := campaign.zodiac
	var deck := campaign.gieo_que.persistent_deck
	var first: CardData = deck[0]
	service.debug_offer(ZodiacDemand.make("SEAL", "CHOOSE_ONE", "PLAYER_CHOOSES"))
	assert_true(service.selectable_cards().has(first))
	assert_true(service.can_accept([first.unique_id]))
	var offer := service.debug_offer(ZodiacDemand.make("SEAL", "OFFER_THREE", "PLAYER_CHOOSES"))
	assert_eq(offer.offered_ids.size(), 3)
	var outside: CardData
	for card in deck:
		if card.unique_id not in offer.offered_ids: outside = card; break
	assert_false(service.can_accept([outside.unique_id]))
	assert_true(service.can_accept([offer.offered_ids[0]]))
	for authority in ["ZODIAC_CHOOSES", "RANDOM"]:
		offer = service.debug_offer(ZodiacDemand.make("SEAL", "OFFER_THREE", authority))
		assert_eq(offer.offered_ids.size(), 3)
		assert_true(offer.target_ids[0] in offer.offered_ids)
		assert_true(service.can_accept())
	for rule in ["SAME_SUIT_2", "SAME_SUIT_3", "CONSECUTIVE_2", "CONSECUTIVE_3"]:
		var quantity := int(rule.right(1))
		offer = service.debug_offer(ZodiacDemand.make("SEAL", rule, "RANDOM", quantity))
		assert_eq(offer.target_ids.size(), quantity)
		assert_true(ZodiacDemand.selection_valid(deck, offer, offer.target_ids))
		offer = service.debug_offer(ZodiacDemand.make("SEAL", rule, "PLAYER_CHOOSES", quantity))
		var selected: Array[String] = []
		for _index in quantity:
			var available := service.selectable_cards(selected)
			assert_false(available.is_empty())
			selected.append(available[0].unique_id)
		assert_true(service.can_accept(selected))
	var rng := RandomNumberGenerator.new()
	rng.seed = 317
	var sparse: Array[CardData] = [deck[0], deck[14]]
	offer = ZodiacDemand.prepare(ZodiacDemand.make("SEAL", "SAME_SUIT_2", "ZODIAC_CHOOSES", 2), sparse, rng)
	assert_eq(offer.targeting, "ANY")
	assert_eq(offer.quantity, 2)
	assert_true(ZodiacDemand.prepare(ZodiacDemand.make("SEAL", "ANY", "RANDOM", 3), sparse, rng).is_empty())
	for card in deck: card.transformation_locked = true
	assert_true(service.debug_offer(ZodiacDemand.make("SET_RANK", "ANY", "PLAYER_CHOOSES", 1, "2")).is_empty())

func test_haggle_changes_severity_quantity_authority_and_favorite_relic() -> void:
	var campaign := _noon()
	var service := campaign.zodiac
	var card: CardData = campaign.gieo_que.persistent_deck[0]
	card.adjust_fortune(2)
	service.debug_offer(ZodiacDemand.make("RESET", "HAS_GIEO_PROPERTY", "ZODIAC_CHOOSES"))
	var original_ids: Array = service.current_demand().target_ids.duplicate()
	var before := card.permanent_snapshot()
	assert_true(service.respond("HAGGLE").requires_confirmation)
	assert_eq(service.current_demand().verb, "REMOVE_PROPERTY")
	assert_eq(service.current_demand().target_ids, original_ids)
	assert_eq(card.permanent_snapshot(), before)
	service.debug_offer(ZodiacDemand.make("SEAL", "SAME_SUIT_3", "ZODIAC_CHOOSES", 3))
	assert_true(service.respond("HAGGLE").requires_confirmation)
	assert_eq(service.current_demand().quantity, 2)
	assert_eq(service.current_demand().targeting, "SAME_SUIT_2")
	service.debug_offer(ZodiacDemand.make("SET_RANK", "ANY", "ZODIAC_CHOOSES", 1, "2"))
	assert_true(service.respond("HAGGLE").requires_confirmation)
	assert_eq(service.current_demand().authority, "PLAYER_CHOOSES")
	assert_false(service.respond("HAGGLE").ok)
	var relics := campaign.relic_shop.runtime
	relics.acquire("toothpicks")
	relics.equip("toothpicks")
	relics.acquire("comb")
	assert_true(service._favorite("toothpicks"))
	var substitute := service.counteroffer_for(service.current_demand(), "favorite_relic")
	assert_eq(substitute.verb, "GIFT_RELIC")
	service.negotiation().counteroffer = substitute
	assert_true(relics.inventory.has("toothpicks"))
	assert_true(service.respond("ACCEPT").resolved_successfully)
	assert_false(relics.inventory.has("toothpicks"))
	assert_false(relics.equipped.has("toothpicks"))
	assert_true(relics.inventory.has("comb"))
	assert_eq(service.progress.record("rooster").favorite_relics_gifted, 1)

func test_do_promise_waits_for_afternoon_even_when_outcome_is_known() -> void:
	for success in [true, false]:
		var campaign := _noon()
		var service := campaign.zodiac
		service.debug_offer(ZodiacDemand.make("PROMISE", "ANY", "PLAYER_CHOOSES", 1, "", 0, {"condition": "early_score"}))
		assert_true(service.respond("ACCEPT").pending)
		_finish_noon(campaign)
		var before: int = service.negotiation().resolved_demand_count
		campaign._enter_phase(CampaignManager.CampaignPhase.AFTERNOON_DEAL)
		var deal := service.deal
		deal.start_tutorial_deal()
		if success: deal.create_meld(deal.hand.slice(0, 3))
		else: deal.discard_card(deal.hand[-1])
		assert_eq(service.daily.promises.size(), 1)
		assert_eq(service.negotiation().resolved_demand_count, before)
		service.finish_daytime_deal("afternoon")
		_event(campaign, EventManager.EventSlot.AFTERNOON)
		assert_true(service.daily.promises.is_empty())
		assert_eq(service.daily.last_result.resolved_successfully, success)
		assert_eq(service.negotiation().resolved_demand_count, before + 1)
		_event(campaign, EventManager.EventSlot.AFTERNOON)
		assert_eq(service.negotiation().resolved_demand_count, before + 1)

func test_dont_promise_and_wallet_floor_track_the_next_deal_only() -> void:
	for condition in ["dont_action", "wallet_floor"]:
		for success in [true, false]:
			var campaign := _noon()
			var service := campaign.zodiac
			service.debug_offer(ZodiacDemand.make("PROMISE", "ANY", "PLAYER_CHOOSES", 1, "", 5000, {"condition": condition, "action": "new_meld"}))
			assert_true(service.respond("ACCEPT").pending)
			_finish_noon(campaign)
			# Other periods cannot break a NEXT DEAL promise.
			campaign.current_phase = CampaignManager.CampaignPhase.NOON_DEAL
			service.deal.start_tutorial_deal()
			service.deal.create_meld(service.deal.hand.slice(0, 3))
			campaign._enter_phase(CampaignManager.CampaignPhase.AFTERNOON_DEAL)
			service.deal.start_tutorial_deal()
			if not success:
				if condition == "dont_action": service.deal.create_meld(service.deal.hand.slice(0, 3))
				else:
					campaign.wallet.apply_vnd(-campaign.wallet.balance_vnd, "deadwood")
					campaign.wallet.apply_vnd(25000, "later_gain")
			assert_eq(service.daily.promises.size(), 1)
			service.finish_daytime_deal("afternoon")
			_event(campaign, EventManager.EventSlot.AFTERNOON)
			assert_eq(service.daily.last_result.resolved_successfully, success)

func test_seeded_generation_save_counteroffer_and_future_demands() -> void:
	var campaign := _noon()
	var other := _noon()
	assert_eq(campaign.zodiac.current_demand(), other.zodiac.current_demand())
	campaign.zodiac.debug_offer(ZodiacDemand.make("SEAL", "SAME_SUIT_3", "ZODIAC_CHOOSES", 3))
	campaign.zodiac.respond("HAGGLE")
	var save := RunSave.new("user://test_zodiac_negotiation.save")
	assert_true(save.save_run(campaign, campaign.zodiac.deal))
	var copy := CampaignManager.new()
	var copy_deal := DealState.new()
	copy.wallet = copy_deal.wallet
	copy.zodiac.bind(copy, copy_deal)
	assert_true(save.restore(save.load_run(), copy, copy_deal))
	assert_eq(copy.zodiac.current_demand(), campaign.zodiac.current_demand())
	assert_eq(copy.zodiac._rng.state, campaign.zodiac._rng.state)
	assert_true(copy.zodiac.respond("REFUSE").ok)
	assert_true(campaign.zodiac.respond("REFUSE").ok)
	assert_eq(copy.zodiac.current_demand(), campaign.zodiac.current_demand())
	var mutated: CardData = copy.gieo_que.persistent_deck[0]
	copy.zodiac.debug_offer(ZodiacDemand.make("SET_RANK", "ANY", "PLAYER_CHOOSES", 1, "K"))
	copy.zodiac.respond("ACCEPT", mutated.unique_id)
	assert_true(save.save_run(copy, copy_deal))
	assert_true(save.restore(save.load_run(), other, other.zodiac.deal))
	assert_eq(other.gieo_que.persistent_deck[0].unique_id, mutated.unique_id)
	assert_eq(other.gieo_que.persistent_deck[0].rank, "K")
	for suffix in ["", ".bak", ".tmp"]: DirAccess.remove_absolute(save.path + suffix)

func test_pending_promise_save_and_legacy_migration() -> void:
	var campaign := _noon()
	var service := campaign.zodiac
	service.debug_offer(ZodiacDemand.make("PROMISE", "ANY", "PLAYER_CHOOSES", 1, "", 5000, {"condition": "wallet_floor"}))
	service.respond("ACCEPT")
	_finish_noon(campaign)
	campaign._enter_phase(CampaignManager.CampaignPhase.AFTERNOON_DEAL)
	campaign.wallet.apply_vnd(-campaign.wallet.balance_vnd, "deadwood")
	var save := RunSave.new("user://test_zodiac_promise.save")
	assert_true(save.save_run(campaign, service.deal))
	var copy := _campaign()
	assert_true(save.restore(save.load_run(), copy, copy.zodiac.deal))
	copy.zodiac.finish_daytime_deal("afternoon")
	_event(copy, EventManager.EventSlot.AFTERNOON)
	assert_false(copy.zodiac.daily.last_result.resolved_successfully)
	for suffix in ["", ".bak", ".tmp"]: DirAccess.remove_absolute(save.path + suffix)
	service.restore({"daily": {"id": "cat", "day": 0, "slot": 1, "successes": 1,
		"promises": [{"slot": 1, "kind": "restraint", "phase": CampaignManager.CampaignPhase.NOON_DEAL}],
		"requests": {1: {"status": "promised"}}, "boss_finished": false}})
	campaign.wallet.reset(25000)
	_event(campaign, EventManager.EventSlot.AFTERNOON)
	assert_true(service.daily.last_result.resolved_successfully)
	assert_true(service.daily.promises.is_empty())

func test_real_assets_replace_all_placeholders() -> void:
	for id: String in ZodiacCatalog.DEFINITIONS:
		assert_eq(ZodiacCatalog.DEFINITIONS[id].sprite, ZodiacCatalog.sprite_path(id))
		assert_true(ResourceLoader.exists(ZodiacCatalog.sprite_path(id)))
		if id != "dragon": assert_true(ResourceLoader.exists(ZodiacCatalog.sprite_path(id, true)))
		var stem := "rat" if id == "rat" else id
		assert_false(FileAccess.file_exists("res://assets/zodiacboss/" + stem + ".svg"))

func test_legacy_resolved_noon_and_scheduled_skip_are_not_recharged() -> void:
	var campaign := _noon()
	var service := campaign.zodiac
	service.restore({"daily": {"id": "rooster", "day": 0, "slot": 2, "successes": 2, "promises": [],
		"requests": {0: {"status": "success"}, 2: {"status": "success"}}, "skip_phase": CampaignManager.CampaignPhase.AFTERNOON_DEAL, "skipped": [], "boss_finished": false}})
	var before := campaign.wallet.balance_vnd
	_event(campaign, EventManager.EventSlot.NOON)
	assert_false(service.has_open_demand())
	assert_false(service.respond("ACCEPT").ok)
	assert_eq(campaign.wallet.balance_vnd, before)
	assert_true(service.consume_skip(CampaignManager.CampaignPhase.AFTERNOON_DEAL))
	service.negotiation().status = "active"
	service.daily.skip_phase = CampaignManager.CampaignPhase.AFTERNOON_DEAL
	assert_true(service.debug_offer(ZodiacDemand.make("PROMISE", "ANY", "PLAYER_CHOOSES", 1, "", 0, {"condition": "early_score"})).is_empty())

func test_rooster_all_deadlines_and_extra_discards_do_not_count() -> void:
	for mood in ["PLEASED", "NEUTRAL", "UNPLEASED"]:
		var deal := _tutorial("rooster", mood)
		deal.set_current_drink(DrinkCatalog.TRA_DA)
		var deadline: int = ZodiacCatalog.DEFINITIONS.rooster.deadlines[mood]
		for count in range(1, deadline + 1):
			assert_false(deal.zodiac_boss.register_closed)
			deal.discard_card(deal.hand[-1])
			assert_eq(deal.zodiac_boss.register_closed, count == deadline)
			deal.discard_card(deal.hand[-1])
			assert_eq(deal.discard_count, count)

func test_rooster_closed_meld_and_extension_move_cards_without_payout() -> void:
	var deal := _tutorial("rooster", "UNPLEASED")
	deal.relics.acquire("sunflower_seeds")
	deal.relics.equip("sunflower_seeds")
	deal.zodiac_boss.mandatory_discard(1, 1)
	var before := deal.wallet.balance_vnd
	var result := deal.create_meld(deal.hand.slice(0, 3))
	assert_true(result.ok)
	assert_eq(deal.melds.size(), 1)
	assert_eq(deal.hand.size(), 7)
	assert_eq(deal.wallet.balance_vnd, before)
	assert_eq(result.context.final_points, 0)
	assert_eq(result.context.suppression_reason, "rooster_register_closed")
	assert_true(result.context.relic_bonuses.is_empty())
	assert_eq(deal.phase_metrics.new_phom_count, 1)
	# The authored tutorial's next draw is the legal 7H extension.
	deal.discard_card(deal.hand[-1])
	var extension: CardData
	for card in deal.hand:
		if card.rank == "7" and card.suit == "Hearts": extension = card
	before = deal.wallet.balance_vnd
	assert_true(deal.extend_meld(deal.melds[0].meld_id, [extension]).ok)
	assert_eq(deal.wallet.balance_vnd, before)
	assert_eq(deal.melds[0].cards.size(), 4)
	assert_true(deal.physical_card_accounting_is_valid())

func test_rooster_phase_two_restores_scoring() -> void:
	var deal := _tutorial("rooster", "NORMAL")
	deal.zodiac_boss.mandatory_discard(1, 1)
	deal.current_phase = 2
	var before := deal.wallet.balance_vnd
	assert_true(deal.create_meld(deal.hand.slice(0, 3)).ok)
	assert_gt(deal.wallet.balance_vnd, before)

func test_cat_inactive_phase_one_and_all_phase_two_counts() -> void:
	for mood in ["PLEASED", "NEUTRAL", "UNPLEASED"]:
		var deal := _tutorial("cat", mood)
		var deck_rng := deal.deck._rng.state
		deal.zodiac_boss.begin_turn(1, deal.hand)
		assert_true(deal.zodiac_boss.locked_ids.is_empty())
		deal.zodiac_boss.begin_turn(2, deal.hand)
		assert_eq(deal.zodiac_boss.locked_ids.size(), ZodiacCatalog.DEFINITIONS.cat.locks[mood])
		assert_eq(deal.deck._rng.state, deck_rng)

func test_cat_locks_block_all_hand_actions_including_extra_discard() -> void:
	var deal := _tutorial("cat", "UNPLEASED")
	var card := deal.hand[0]
	deal.zodiac_boss.locked_ids = [card.unique_id]
	assert_false(deal.can_create_meld(deal.hand.slice(0, 3)))
	assert_false(deal.create_meld(deal.hand.slice(0, 3)).ok)
	assert_false(deal.discard_card(card).ok)
	deal.set_current_drink(DrinkCatalog.TRA_DA)
	deal.tra_da_extra_discard_pending = true
	assert_false(deal.discard_card(card).ok)
	var record := DiscardRecord.new(deal.hand[-1], 1, 1, DiscardRecord.KIND_MANDATORY)
	deal.discard_history.append(record)
	deal.deck.discard_pile.append(record.card)
	deal.set_current_drink(DrinkCatalog.NHAN_TRAN)
	assert_false(deal.can_use_nhan_tran(card, record))
	deal.set_current_drink(DrinkCatalog.DEN_DA)
	assert_false(deal.can_use_den_da(card, record))
	assert_true(deal.hand.has(card))
	assert_gt(deal.deadwood_points(), 0)

func test_cat_keeps_unlocked_mandatory_discard_available() -> void:
	var deal := _tutorial("cat", "UNPLEASED")
	deal.hand.resize(4)
	deal.zodiac_boss.locked_ids = [deal.hand[3].unique_id]
	assert_false(deal.create_meld(deal.hand.slice(0, 3)).ok)
	deal.state = DealState.STATE_FINAL_COMMIT_WINDOW
	assert_true(deal.create_meld(deal.hand.slice(0, 3)).ok)

func test_cat_clear_and_reroll_restores_exact_rng_sequence() -> void:
	var deal := _tutorial("cat", "NEUTRAL")
	deal.current_phase = 2
	deal.zodiac_boss.begin_turn(2, deal.hand)
	var snapshot := deal.snapshot_state()
	var restored := DealState.new()
	restored.restore_snapshot(snapshot)
	assert_eq(restored.zodiac_boss.snapshot(), deal.zodiac_boss.snapshot())
	var initial := deal.zodiac_boss.locked_ids.duplicate()
	deal.zodiac_boss.begin_turn(2, deal.hand)
	restored.zodiac_boss.begin_turn(2, restored.hand)
	assert_eq(restored.zodiac_boss.snapshot(), deal.zodiac_boss.snapshot())
	assert_ne(initial, deal.zodiac_boss.locked_ids)
	assert_eq(deal.zodiac_boss.locked_ids.size(), 2)

func test_run_save_roundtrip_preserves_requests_skips_boss_rng() -> void:
	var campaign := _campaign("cat")
	campaign.zodiac.respond("HAGGLE")
	var deal := campaign.zodiac.deal
	deal.set_campaign_deck(campaign.gieo_que.persistent_deck)
	deal.start_deal(17)
	deal.zodiac_boss.configure("cat", "NEUTRAL", 22)
	deal.current_phase = 2
	deal.zodiac_boss.begin_turn(2, deal.hand)
	var save := RunSave.new("user://test_zodiac_run.save")
	assert_true(save.save_run(campaign, deal))
	var other := CampaignManager.new()
	var other_deal := DealState.new()
	other.wallet = other_deal.wallet
	other.zodiac.bind(other, other_deal)
	assert_true(save.restore(save.load_run(), other, other_deal))
	assert_eq(other.zodiac.daily, campaign.zodiac.daily)
	assert_eq(other_deal.zodiac_boss.snapshot(), deal.zodiac_boss.snapshot())
	for suffix in ["", ".bak", ".tmp"]: DirAccess.remove_absolute(save.path + suffix)

func test_explicit_scene_conditions_reencounter_and_permanent_emblem() -> void:
	var progress := ZodiacProgress.new("")
	assert_false(progress.eligible("rooster"))
	progress.commit("rooster", "history", {"requests_resolved": 4, "requests_refused_successfully": 1, "pleased_victories": 1})
	assert_true(progress.eligible("rooster"))
	assert_false(progress.owns("rooster"))
	var campaign := CampaignManager.new()
	campaign.zodiac.progress = progress
	campaign.zodiac.run_id = "scene-run"
	var seed_value := 0
	while ZodiacCatalog.select(seed_value, 0) != "rooster": seed_value += 1
	campaign.zodiac.begin_day(0, seed_value)
	assert_true(progress.record("rooster").special_scene_unlocked)
	assert_true(campaign.zodiac.complete_scene())
	assert_true(progress.owns("rooster"))
	assert_false(campaign.zodiac.complete_scene())
	campaign.zodiac.reset_run()
	assert_true(progress.owns("rooster"))
	assert_true(progress.record("rooster").special_scene_completed)

func test_progress_disk_roundtrip_and_replay_never_degrade_or_double_count() -> void:
	var path := "user://test_zodiac_progress.cfg"
	for suffix in ["", ".bak", ".tmp"]: DirAccess.remove_absolute(path + suffix)
	var progress := ZodiacProgress.new(path)
	progress.commit("cat", "a", {"requests_resolved": 2}, ["emblem_unlocked"])
	var old := progress.snapshot()
	progress.commit("cat", "b", {"requests_resolved": 1})
	progress.merge(old)
	progress.commit("cat", "a", {"requests_resolved": 20})
	var restored := ZodiacProgress.new(path)
	assert_eq(restored.record("cat").requests_resolved, 3)
	assert_true(restored.owns("cat"))
	for suffix in ["", ".bak", ".tmp"]: DirAccess.remove_absolute(path + suffix)

func test_full_day_disposition_configures_current_evening_boss() -> void:
	for id in ["rooster", "cat"]:
		var campaign := _noon(id)
		var deal := campaign.zodiac.deal
		_finish_noon(campaign)
		_event(campaign, EventManager.EventSlot.AFTERNOON)
		campaign._enter_phase(CampaignManager.CampaignPhase.EVENING_DEAL)
		assert_eq(deal.zodiac_boss.id, id)
		assert_eq(deal.zodiac_boss.difficulty, ZodiacCatalog.PLEASED)
		deal.set_campaign_deck(campaign.gieo_que.persistent_deck)
		deal.set_current_drink(DrinkCatalog.NONE)
		deal.start_deal(4128)
		for _action in 20:
			if deal.state == DealState.STATE_DEAL_OVER: break
			if deal.state == DealState.STATE_ACTIVE:
				var unlocked := deal.hand.filter(func(card: CardData): return not deal.zodiac_boss.is_locked(card))
				assert_true(deal.discard_card(unlocked[-1]).ok)
			elif deal.state == DealState.STATE_FINAL_COMMIT_WINDOW: deal.settle_phase()
			elif deal.state == DealState.STATE_PHASE_CHOICE: deal.choose_phase_two(false)
		assert_eq(deal.state, DealState.STATE_DEAL_OVER)
		assert_true(deal.physical_card_accounting_is_valid())
		campaign.complete_deal()
		assert_eq(campaign.zodiac.progress.record(id).pleased_victories, 1)
		if id == "rooster": assert_eq(campaign.zodiac.progress.record(id).perfect_request_days, 1)
		campaign.zodiac.finish_boss()
		assert_eq(campaign.zodiac.progress.record(id).pleased_victories, 1)

func test_difficulty_migration_and_unpleased_legality_hooks() -> void:
	var rule := ZodiacBossRule.new()
	rule.restore({"id": "cat", "disposition": "NEUTRAL", "rng": 123})
	assert_eq(rule.difficulty, ZodiacCatalog.NORMAL)
	assert_eq(rule.disposition, "NORMAL")
	assert_eq(rule.snapshot().difficulty, 2)
	for level in [1, 2, 3]:
		var deal := _tutorial("rooster", ZodiacCatalog.difficulty_name(level))
		deal.current_phase = 2
		assert_eq(deal.can_create_meld(deal.hand.slice(0, 3)), level != 3)
		assert_eq(deal.create_meld(deal.hand.slice(0, 3)).ok, level != 3)
		deal = _tutorial("cat", ZodiacCatalog.difficulty_name(level))
		var made := deal.create_meld(deal.hand.slice(0, 3))
		assert_true(made.ok)
		var extra := deal._take_tutorial_card("7", "Hearts")
		deal.hand.append(extra)
		assert_eq(deal.can_extend_meld(made.meld_id, [extra]), level != 3)
		assert_eq(deal.extend_meld(made.meld_id, [extra]).ok, level != 3)
		assert_true(deal.physical_card_accounting_is_valid())
