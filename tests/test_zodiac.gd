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
	assert_eq(ZodiacCatalog.select(5, 1), "")
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

func test_accept_pay_is_wallet_journaled_and_idempotent() -> void:
	var campaign := _campaign()
	var before := campaign.wallet.balance_vnd
	var result := campaign.zodiac.respond("ACCEPT")
	assert_true(result.resolved_successfully)
	assert_eq(campaign.wallet.balance_vnd, before - 5000)
	assert_eq(campaign.wallet.journal[-1].reason, "zodiac_request:rooster")
	assert_false(campaign.zodiac.respond("ACCEPT").ok)
	assert_eq(campaign.wallet.balance_vnd, before - 5000)
	assert_eq(campaign.zodiac.progress.record("rooster").requests_resolved, 1)

func test_respected_refusal_has_no_cost_and_no_affection() -> void:
	var campaign := _campaign()
	var before := campaign.wallet.balance_vnd
	assert_true(campaign.zodiac.respond("REFUSE").resolved_successfully)
	assert_eq(campaign.wallet.balance_vnd, before)
	assert_eq(campaign.zodiac.mood(), "NEUTRAL")
	var history := campaign.zodiac.progress.record("rooster")
	assert_eq(history.requests_refused_successfully, 1)
	assert_false(history.has("affection"))
	campaign.start_campaign(true, "another-run")
	assert_eq(campaign.zodiac.progress.record("rooster").requests_resolved, history.requests_resolved)
	assert_eq(campaign.zodiac.progress.record("rooster").requests_refused_successfully, history.requests_refused_successfully)

func test_failed_bargain_and_character_specific_acceptance() -> void:
	var campaign := _campaign()
	assert_false(campaign.zodiac.respond("BARGAIN").resolved_successfully)
	assert_eq(campaign.zodiac.mood(), "UNPLEASED")
	var cat := _campaign("cat")
	assert_false(cat.zodiac.respond("ACCEPT").resolved_successfully)
	assert_eq(cat.wallet.balance_vnd, 20000)

func test_cat_counteroffer_and_unaffordable_pay() -> void:
	var campaign := _campaign("cat")
	assert_true(campaign.zodiac.respond("COUNTEROFFER").resolved_successfully)
	assert_eq(campaign.wallet.balance_vnd, 22500)
	assert_eq(campaign.zodiac.progress.record("cat").counteroffers_accepted, 1)
	var poor := _campaign()
	poor.wallet.reset(1000)
	assert_false(poor.zodiac.respond("ACCEPT").ok)
	assert_eq(poor.zodiac.quote().status, "offered")
	assert_eq(poor.wallet.balance_vnd, 1000)
	poor.wallet.reset(-1000)
	assert_true(poor.zodiac.respond("REFUSE").ok)
	assert_eq(poor.wallet.balance_vnd, -1000)

func test_card_costs_preserve_52_ids_and_seal_transformations() -> void:
	for operation in ["remove_property", "reset", "seal"]:
		var campaign := _campaign()
		_event(campaign, 2)
		var card: CardData = campaign.gieo_que.persistent_deck[0]
		var id := card.unique_id
		card.apply_rank("K", 13)
		card.add_gieo_property("GOLD_SET")
		assert_true(campaign.zodiac.respond("ACCEPT", id, operation).ok)
		assert_eq(campaign.gieo_que.persistent_deck.size(), 52)
		assert_eq(card.unique_id, id)
		if operation == "reset": assert_eq(card.rank, "A")
		if operation == "remove_property": assert_true(card.gieo_properties.is_empty())
		if operation == "seal":
			card.apply_rank("2", 2)
			assert_eq(card.rank, "K")
			assert_false(card.add_gieo_property("GOLD_RUN"))
			assert_true(card.copy_for_deal().transformation_locked)

func test_relic_gift_removes_owned_and_equipped_only_target() -> void:
	var campaign := _campaign("cat")
	var relics := campaign.relic_shop.runtime
	relics.acquire("hair_clip")
	relics.equip("hair_clip")
	relics.acquire("comb")
	_event(campaign, 3)
	assert_true(campaign.zodiac.respond("ACCEPT", "hair_clip").resolved_successfully)
	assert_false(relics.inventory.has("hair_clip"))
	assert_false(relics.equipped.has("hair_clip"))
	assert_true(relics.inventory.has("comb"))
	assert_eq(campaign.zodiac.progress.record("cat").favorite_relics_gifted, 1)

func test_spend_time_skips_exactly_one_normal_deal_no_money() -> void:
	var campaign := _campaign()
	var before := campaign.wallet.balance_vnd
	assert_true(campaign.zodiac.respond("SPEND_TIME").ok)
	# Complete any mandatory starter interactions normally before exiting.
	for interaction in campaign.event_manager.current_event.interactions:
		campaign.event_manager.current_event.complete_interaction(interaction.id)
	assert_true(campaign.complete_current_event())
	assert_eq(campaign.current_phase, CampaignManager.CampaignPhase.MORNING_EVENT)
	assert_eq(campaign.wallet.balance_vnd, before)
	assert_true(campaign.deal_reports.is_empty())
	assert_eq(campaign.zodiac.daily.skipped, [CampaignManager.CampaignPhase.MORNING_DEAL])
	assert_false(campaign.zodiac.consume_skip(CampaignManager.CampaignPhase.MORNING_DEAL))
	_event(campaign, 3)
	assert_false(campaign.zodiac.respond("SPEND_TIME").ok)
	assert_false(campaign.zodiac.consume_skip(CampaignManager.CampaignPhase.EVENING_DEAL))

func test_do_promise_observes_real_score_or_first_discard() -> void:
	for success in [true, false]:
		var campaign := _campaign()
		_event(campaign, 1)
		assert_true(campaign.zodiac.respond("ACCEPT").pending)
		campaign.current_phase = CampaignManager.CampaignPhase.NOON_DEAL
		var deal := campaign.zodiac.deal
		deal.start_tutorial_deal()
		if success: deal.create_meld(deal.hand.slice(0, 3))
		else: deal.discard_card(deal.hand[-1])
		assert_true(campaign.zodiac.daily.promises.is_empty())
		assert_eq(campaign.zodiac.daily.last_result.resolved_successfully, success)

func test_dont_promise_tracks_wallet_and_afternoon_deadline() -> void:
	for success in [true, false]:
		var campaign := _campaign("cat")
		_event(campaign, 1)
		assert_true(campaign.zodiac.respond("ACCEPT").pending)
		if not success: campaign.wallet.apply_vnd(-22000, "deadwood")
		_event(campaign, 3)
		assert_true(campaign.zodiac.daily.promises.is_empty())
		assert_eq(campaign.zodiac.daily.last_result.resolved_successfully, success)

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
	deal.zodiac_boss.mandatory_discard(1, 1)
	var before := deal.wallet.balance_vnd
	var result := deal.create_meld(deal.hand.slice(0, 3))
	assert_true(result.ok)
	assert_eq(deal.melds.size(), 1)
	assert_eq(deal.hand.size(), 7)
	assert_eq(deal.wallet.balance_vnd, before)
	assert_eq(result.context.final_points, 0)
	assert_eq(result.context.suppression_reason, "rooster_register_closed")
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
	var deal := _tutorial("rooster", "UNPLEASED")
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
	campaign.zodiac.respond("SPEND_TIME")
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

func test_full_day_both_bosses_skip_and_victory_history() -> void:
	for id in ["rooster", "cat"]:
		var campaign := _campaign(id)
		var deal := campaign.zodiac.deal
		var start := func(_day: Dictionary, period: String, _drink: String):
			deal.set_campaign_deck(campaign.gieo_que.persistent_deck)
			deal.set_current_drink(DrinkCatalog.NONE)
			deal.start_deal(campaign.seed_for("deal", ["morning", "noon", "afternoon", "evening"].find(period)))
		campaign.deal_requested.connect(start)
		var transitions := 0
		while campaign.current_phase != CampaignManager.CampaignPhase.MONEY_REQUIREMENT_CHECK and transitions < 15:
			transitions += 1
			if CampaignManager.EVENT_PHASE_TO_SLOT.has(campaign.current_phase):
				var slot: int = CampaignManager.EVENT_PHASE_TO_SLOT[campaign.current_phase]
				assert_true(campaign.zodiac.respond("SPEND_TIME" if slot == 1 else "REFUSE").ok)
				for interaction in campaign.event_manager.current_event.interactions:
					campaign.event_manager.current_event.complete_interaction(interaction.id)
				assert_true(campaign.complete_current_event())
			else:
				for _action in 15:
					if deal.state == DealState.STATE_DEAL_OVER: break
					if deal.state == DealState.STATE_ACTIVE:
						var unlocked := deal.hand.filter(func(card: CardData): return not deal.zodiac_boss.is_locked(card))
						assert_true(not unlocked.is_empty())
						assert_true(deal.discard_card(unlocked[-1]).ok)
					elif deal.state == DealState.STATE_FINAL_COMMIT_WINDOW: deal.settle_phase()
					elif deal.state == DealState.STATE_PHASE_CHOICE: deal.choose_phase_two(false)
				assert_eq(deal.state, DealState.STATE_DEAL_OVER)
				assert_true(deal.physical_card_accounting_is_valid())
				campaign.complete_deal()
		assert_eq(campaign.current_phase, CampaignManager.CampaignPhase.MONEY_REQUIREMENT_CHECK)
		assert_eq(campaign.deal_reports.size(), 3)
		assert_eq(campaign.zodiac.daily.skipped, [CampaignManager.CampaignPhase.NOON_DEAL])
		var history := campaign.zodiac.progress.record(id)
		assert_eq(history.pleased_victories, 1)
		assert_eq(history.perfect_request_days, 1)
		campaign.zodiac.finish_boss()
		assert_eq(campaign.zodiac.progress.record(id).pleased_victories, 1)
		campaign.deal_requested.disconnect(start)
