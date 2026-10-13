@tool
extends McpTestSuite
const FLOW := preload("res://tests/pig_ox_test_flow.gd")
const NOON_FLOW := preload("res://tests/zodiac_test_flow.gd")

func suite_name() -> String: return "pig_ox_persuasion"

func _judge(owner: CampaignManager) -> void:
	owner.zodiac.finish_daytime_deal("afternoon")
	owner._enter_phase(CampaignManager.CampaignPhase.AFTERNOON_EVENT)

func _choose(owner: CampaignManager, specs: Array = FLOW.OPENING.slice(0, 3)) -> String:
	FLOW.terms(owner, owner.zodiac.active_id() + ".t1plus.card")
	var offer := owner.zodiac.current_demand()
	offer.offered_ids = CardTargetQuery.physical_ids(FLOW.cards(owner.gieo_que.persistent_deck, specs))
	var chosen: String = offer.offered_ids[0]
	assert_true(owner.zodiac.persuasion.select_card(chosen))
	assert_false(owner.zodiac.respond("ACCEPT", ["not-offered"]).ok)
	assert_true(owner.zodiac.respond("ACCEPT", [chosen]).pending)
	assert_true(owner.zodiac.continue_conversation())
	return chosen

func test_bilingual_authored_rosters_and_character_specific_contracts() -> void:
	for id: String in ["pig", "ox"]:
		var nodes := ZodiacCatalog.persuasion_nodes(id)
		assert_eq(nodes.size(), 12)
		var seen := {}
		for node: Dictionary in nodes:
			assert_false(seen.has(node.id))
			seen[node.id] = true
			assert_eq(node.zodiac, id)
			assert_eq(node.answers.map(func(a: Dictionary): return a.id), ["A", "B", "C"])
			for a: Dictionary in node.answers:
				assert_true(not a.en.is_empty() and not a.vi.is_empty())
				assert_false(a.has("traits"))
			if node.has("memory_key"):
				assert_eq(node.prompts.keys(), ["FULFILLED", "BROKEN", "REFUSED"])
				assert_true(node.has("promise"))
			if node.has("promise"):
				assert_eq(node.responses.REFUSE.delta, 0)
				assert_eq(node.responses.ACCEPT.delta, 0)
				assert_true(node.outcomes.has("FULFILLED") and node.outcomes.has("BROKEN"))
		assert_eq(ZodiacCatalog.persuasion_config(id).private_scene.size(), 3)
		assert_eq(ZodiacCatalog.persuasion_config(id).last_chance.answers.size(), 3)

func test_seeded_stranger_visits_are_stable_and_advance_only_on_return() -> void:
	for id: String in ["pig", "ox"]:
		var owner := FLOW.campaign(id, false)
		var twin := FLOW.campaign(id, false)
		assert_eq(owner.zodiac.active_id(), id)
		assert_eq(owner.zodiac.persuasion.state().plan, twin.zodiac.persuasion.state().plan)
		assert_eq(owner.zodiac.persuasion.state().plan.size(), 3)
		assert_false(owner.complete_current_event())
		var rng := owner.zodiac._rng.state
		owner.zodiac.quote()
		owner.zodiac.enter_event(EventManager.EventSlot.NOON)
		assert_eq(owner.zodiac._rng.state, rng)
		assert_true(NOON_FLOW.finish_noon(owner.zodiac))
		assert_eq(owner.zodiac.progress.relationship_tier(id), ZodiacProgress.STRANGER)
		owner._enter_phase(CampaignManager.CampaignPhase.AFTERNOON_EVENT)
		assert_eq(owner.zodiac.progress.relationship_tier(id), ZodiacProgress.FAMILIAR)
		assert_eq(owner.zodiac.difficulty(), ZodiacCatalog.PLEASED)

func test_acceptance_refusal_and_haggle_do_not_spend_resources() -> void:
	for id: String in ["pig", "ox"]:
		var owner := FLOW.campaign(id)
		var node_id: String = id + ".t1plus." + ("earn" if id == "pig" else "load")
		var before := owner.wallet.balance_vnd
		var cards := owner.gieo_que.persistent_deck.map(func(c: CardData): return c.permanent_snapshot())
		var promise := FLOW.accept(owner, node_id)
		assert_false(promise.started or promise.matched)
		assert_false(owner.zodiac.respond("ACCEPT").ok)
		assert_eq(owner.zodiac.daily.promises.size(), 1)
		assert_eq(owner.wallet.balance_vnd, before)
		assert_eq(owner.gieo_que.persistent_deck.map(func(c: CardData): return c.permanent_snapshot()), cards)
		var refused := FLOW.campaign(id)
		FLOW.terms(refused, node_id)
		assert_true(refused.zodiac.respond("REFUSE").ok)
		assert_true(refused.zodiac.daily.promises.is_empty())
		assert_eq(refused.zodiac.persuasion.state().patience, 3)

func test_amount_counteroffers_are_exact_frozen_and_do_not_invent_a_new_kind() -> void:
	for id: String in ["pig", "ox"]:
		var owner := FLOW.campaign(id)
		FLOW.terms(owner, id + ".t1plus." + ("earn" if id == "pig" else "load"))
		var service := owner.zodiac
		var token := service.offer_token()
		assert_true(service.respond("HAGGLE", [], token).requires_confirmation)
		assert_eq(service.current_demand().id, id + "." + ("earn" if id == "pig" else "load"))
		assert_eq(service.current_demand().get("resource_amount", service.current_demand().get("point_limit")), 25000 if id == "pig" else 60)
		assert_false(service.respond("ACCEPT", [], token).ok)
		var rng := service._rng.state
		assert_false(service.respond("HAGGLE").ok)
		assert_eq(service._rng.state, rng)
		assert_true(service.respond("REFUSE").ok)
		var remembered := service.progress.memory(id, service.current_demand().id)
		assert_true(remembered.counteroffer)
		assert_eq(remembered.result, "REFUSED")
		assert_true(remembered.commitment_en.contains("25.000" if id == "pig" else "60 PTS"))
		assert_eq(service.progress.promise_kinds(id), 0)

func test_income_goal_counts_actual_positive_receipts_once_and_delays_judgment() -> void:
	var owner := FLOW.campaign("pig")
	var promise := FLOW.accept(owner, "pig.t1plus.earn")
	FLOW.afternoon(owner)
	var first := FLOW.meld(owner)
	assert_true(first.ok and first.earned_vnd > 0 and first.earned_vnd < 50000)
	assert_eq(promise.earned_vnd, first.earned_vnd)
	assert_false(promise.matched)
	owner.zodiac._observe_action(first)
	assert_eq(promise.earned_vnd, first.earned_vnd)
	var next := FLOW.extension(owner)
	assert_true(next.ok)
	assert_eq(promise.earned_vnd, first.earned_vnd + next.earned_vnd)
	assert_true(promise.matched)
	owner.zodiac.persuasion.judge()
	assert_false(owner.zodiac.persuasion.state().judged)
	assert_true(FLOW.finish(owner))
	assert_eq(owner.zodiac.progress.memory("pig", "pig.earn").result, "FULFILLED")
	var kept: int = owner.zodiac.progress.record("pig").promises_kept
	owner.zodiac.enter_event(EventManager.EventSlot.AFTERNOON)
	assert_eq(owner.zodiac.progress.record("pig").promises_kept, kept)

func test_gifts_loans_failed_actions_and_other_deals_do_not_fulfill_income_goal() -> void:
	var owner := FLOW.campaign("pig")
	var promise := FLOW.accept(owner, "pig.t1plus.earn")
	owner.wallet.apply_vnd(100000, "gift")
	owner.wallet.apply_vnd(100000, "loan")
	assert_eq(promise.get("earned_vnd", 0), 0)
	owner._enter_phase(CampaignManager.CampaignPhase.MORNING_DEAL)
	owner.zodiac.deal.start_tutorial_deal()
	assert_true(owner.zodiac.deal.create_meld(owner.zodiac.deal.hand.slice(0, 3)).ok)
	assert_false(promise.started or promise.matched)
	FLOW.afternoon(owner)
	assert_false(owner.zodiac.deal.extend_meld(-1, owner.zodiac.deal.hand.slice(0, 1)).ok)
	assert_eq(promise.get("earned_vnd", 0), 0)
	_judge(owner)
	assert_eq(owner.zodiac.progress.memory("pig", "pig.earn").result, "BROKEN")

func test_income_uses_vnd_rate_not_theoretical_points_and_ignores_restoration() -> void:
	var owner := FLOW.campaign("pig")
	var promise := FLOW.accept(owner, "pig.t1plus.earn")
	FLOW.afternoon(owner)
	owner.zodiac.deal.wallet.vnd_per_point = 10
	var result := FLOW.meld(owner)
	assert_true(result.context.final_points > 0)
	assert_eq(promise.earned_vnd, result.earned_vnd)
	assert_false(promise.matched)
	var restored := FLOW.campaign("pig")
	var pending := FLOW.accept(restored, "pig.t1plus.earn")
	FLOW.afternoon(restored)
	restored.zodiac.begin_run_restore()
	assert_true(FLOW.meld(restored).ok)
	restored.zodiac.finish_run_restore()
	assert_eq(pending.get("earned_vnd", 0), 0)
	assert_false(pending.matched)

func test_wallet_floor_eligibility_and_acceptance_use_the_live_balance() -> void:
	var owner := FLOW.campaign("pig")
	var node: Dictionary = ZodiacCatalog.persuasion_nodes("pig").filter(func(n: Dictionary): return n.id == "pig.t1plus.reserve")[0]
	owner.wallet.reset(9999)
	assert_false(owner.zodiac.persuasion._eligible(node))
	owner.wallet.reset(10000)
	assert_true(owner.zodiac.persuasion._eligible(node))
	FLOW.terms(owner, "pig.t1plus.reserve")
	owner.wallet.apply_vnd(-4000, "service")
	assert_false(owner.zodiac.can_accept())
	assert_false(owner.zodiac.respond("ACCEPT").ok)
	assert_true(owner.zodiac.respond("HAGGLE").requires_confirmation)
	assert_eq(owner.zodiac.current_demand().resource_amount, 5000)
	assert_true(owner.zodiac.respond("ACCEPT").pending)
	assert_eq(owner.wallet.balance_vnd, 6000)

func test_wallet_breach_before_deal_persists_after_refund_and_judges_once() -> void:
	var owner := FLOW.campaign("pig")
	var promise := FLOW.accept(owner, "pig.t1plus.reserve")
	assert_true(promise.started)
	owner.wallet.apply_vnd(-20000, "service")
	assert_true(promise.broken)
	var evidence: Dictionary = promise.observations.duplicate(true)
	owner.wallet.apply_vnd(20000, "refund")
	assert_true(promise.broken)
	assert_eq(promise.observations, evidence)
	FLOW.afternoon(owner)
	_judge(owner)
	assert_eq(owner.zodiac.progress.memory("pig", "pig.reserve").result, "BROKEN")

func test_rejected_atomic_wallet_transaction_does_not_break_a_reserve() -> void:
	var owner := FLOW.campaign("pig")
	var promise := FLOW.accept(owner, "pig.t1plus.reserve")
	var balance := owner.wallet.balance_vnd
	var journal: Array = owner.wallet.journal.duplicate(true)
	assert_false(owner.wallet.try_spend_and_commit(20000, "rejected_service", func(): return false))
	assert_eq(owner.wallet.balance_vnd, balance)
	assert_eq(owner.wallet.journal, journal)
	assert_false(promise.broken)
	assert_true(owner.wallet.try_spend_and_commit(20000, "completed_service", func(): return true))
	assert_true(promise.broken)

func test_wallet_floor_kept_through_completed_deal_and_restore_does_not_fabricate_breach() -> void:
	var owner := FLOW.campaign("pig")
	owner.wallet.reset(2000000)
	var promise := FLOW.accept(owner, "pig.t1plus.reserve")
	owner.zodiac.begin_run_restore()
	owner.wallet.reset(0)
	owner.wallet.reset(2000000)
	owner.zodiac.finish_run_restore()
	assert_false(promise.broken)
	FLOW.afternoon(owner)
	assert_true(FLOW.meld(owner).ok)
	assert_true(FLOW.extension(owner).ok)
	assert_true(FLOW.finish(owner))
	assert_eq(owner.zodiac.progress.memory("pig", "pig.reserve").result, "FULFILLED")

func test_pig_chosen_card_requires_actual_income_and_not_an_old_card_in_extension() -> void:
	var owner := FLOW.campaign("pig")
	_choose(owner)
	FLOW.afternoon(owner)
	var deal := owner.zodiac.deal
	deal.zodiac_boss.configure("rooster", ZodiacCatalog.UNPLEASED, 1)
	deal.zodiac_boss.mandatory_discard(1, 1)
	assert_eq(FLOW.meld(owner).earned_vnd, 0)
	assert_false(owner.zodiac.daily.promises[0].matched)
	deal.zodiac_boss.configure()
	assert_true(FLOW.extension(owner).earned_vnd > 0)
	assert_false(owner.zodiac.daily.promises[0].matched)
	_judge(owner)
	assert_eq(owner.zodiac.progress.memory("pig", "pig.card").result, "BROKEN")
	var paid := FLOW.campaign("pig")
	var chosen := _choose(paid, [["6", "Hearts"], ["9", "Hearts"], ["K", "Clubs"]])
	FLOW.afternoon(paid)
	assert_true(FLOW.meld(paid).ok)
	assert_true(FLOW.extension(paid).earned_vnd > 0)
	assert_true(paid.zodiac.daily.promises[0].matched)
	_judge(paid)
	assert_eq(paid.zodiac.progress.memory("pig", "pig.card").target_id, chosen)

func test_buffalo_settlement_uses_final_penalty_instead_of_net_or_prior_turn_cost() -> void:
	var owner := FLOW.campaign("ox")
	var promise := FLOW.accept(owner, "ox.t1plus.load")
	FLOW.afternoon(owner)
	assert_true(FLOW.meld(owner).ok)
	assert_true(FLOW.final_window(owner))
	# A controlled fortune fixture; the real owner calculates and publishes the receipt.
	for card: CardData in owner.zodiac.deal.hand: card.fortune = -1
	assert_false(promise.matched)
	var result := owner.zodiac.deal.settle_phase()
	assert_true(result.ok)
	assert_eq(promise.settlement_penalty, result.phase_resolution.deadwood_penalty)
	assert_eq(promise.settlement_penalty, 0)
	assert_true(result.phase_resolution.turn_deadwood < 0)
	assert_true(promise.matched and not promise.broken)

func test_black_ink_profit_cannot_hide_a_penalty_above_the_accepted_limit() -> void:
	var owner := FLOW.campaign("ox")
	var promise := FLOW.accept(owner, "ox.t1plus.load")
	promise.accepted_terms.point_limit = 5
	FLOW.afternoon(owner)
	assert_true(FLOW.meld(owner).ok)
	assert_true(FLOW.final_window(owner))
	var deal := owner.zodiac.deal
	for card: CardData in deal.hand: card.fortune = -6
	deal.hand[0].fortune = 0
	deal.hand[0].value_modifiers.append(50)
	var result := deal.settle_phase()
	assert_true(result.ok)
	assert_true(result.phase_resolution.deadwood_penalty > 5)
	assert_true(result.phase_resolution.turn_deadwood < result.phase_resolution.deadwood_penalty)
	assert_true(promise.broken and not promise.matched)
	_judge(owner)
	assert_eq(owner.zodiac.progress.memory("ox", "ox.load").result, "BROKEN")

func test_phase_two_cannot_rescue_a_missed_phase_one_card() -> void:
	var owner := FLOW.campaign("ox")
	_choose(owner, [["6", "Hearts"], ["9", "Hearts"], ["K", "Clubs"]])
	FLOW.afternoon(owner)
	assert_true(FLOW.meld(owner).ok)
	assert_true(FLOW.phase_two(owner))
	assert_true(owner.zodiac.daily.promises[0].broken)
	assert_true(FLOW.extension(owner).ok)
	assert_false(owner.zodiac.daily.promises[0].matched)
	_judge(owner)
	assert_eq(owner.zodiac.progress.memory("ox", "ox.card").result, "BROKEN")

func test_chosen_card_can_be_committed_in_the_final_phase_one_window() -> void:
	var owner := FLOW.campaign("ox")
	_choose(owner, [["6", "Hearts"], ["9", "Hearts"], ["K", "Clubs"]])
	FLOW.afternoon(owner)
	assert_true(FLOW.meld(owner).ok)
	assert_true(FLOW.final_window(owner))
	assert_true(FLOW.extension(owner).ok)
	assert_true(owner.zodiac.daily.promises[0].matched)
	assert_true(owner.zodiac.deal.settle_phase().ok)
	assert_false(owner.zodiac.daily.promises[0].broken)

func test_buffalo_second_phase_extension_and_explicit_alternate_deadline() -> void:
	var owner := FLOW.campaign("ox")
	var promise := FLOW.accept(owner, "ox.t1plus.finish")
	FLOW.afternoon(owner)
	assert_true(FLOW.meld(owner).ok)
	assert_true(FLOW.extension(owner).ok)
	assert_false(promise.matched)
	_judge(owner)
	assert_eq(owner.zodiac.progress.memory("ox", "ox.finish").result, "BROKEN")
	var second := FLOW.campaign("ox")
	var pending := FLOW.accept(second, "ox.t1plus.finish")
	FLOW.afternoon(second)
	assert_true(FLOW.meld(second).ok)
	assert_true(FLOW.phase_two(second))
	assert_true(FLOW.extension(second).ok)
	assert_true(pending.matched)
	var alternate := FLOW.campaign("ox")
	FLOW.terms(alternate, "ox.t1plus.finish")
	assert_true(alternate.zodiac.respond("HAGGLE").ok)
	assert_eq(alternate.zodiac.current_demand().deal_phase, 0)
	assert_true(alternate.zodiac.respond("ACCEPT").pending)
	alternate.zodiac.continue_conversation()
	FLOW.afternoon(alternate)
	assert_true(FLOW.meld(alternate).ok)
	assert_true(FLOW.extension(alternate).ok)
	assert_true(alternate.zodiac.daily.promises[0].matched)

func test_progression_requires_variety_and_does_not_cross_character_records() -> void:
	for id: String in ["pig", "ox"]:
		var progress := ZodiacProgress.new("")
		progress.record_disposition(id, "familiar", "PLEASED")
		var topics: Array = ZodiacCatalog.persuasion_config(id).progression[0].promises
		progress.commit(id, "repeated", {"promises_kept": 3, "promise_kept:" + topics[0]: 3})
		progress.record_disposition(id, "still-familiar", "PLEASED")
		assert_eq(progress.relationship_tier(id), ZodiacProgress.FAMILIAR)
		progress.commit(id, "varied", {"promises_kept": 1, "promise_kept:" + topics[1]: 1})
		progress.record_disposition(id, "unpleased", "UNPLEASED")
		assert_eq(progress.relationship_tier(id), ZodiacProgress.FAMILIAR)
		progress.record_disposition(id, "kindred", "NORMAL")
		assert_eq(progress.relationship_tier(id), ZodiacProgress.KINDRED)
		assert_false(progress.record_disposition(id, "kindred", "NORMAL"))
		assert_eq(progress.record(id).kindred_transitions, 1)
		assert_eq(progress.relationship_tier("ox" if id == "pig" else "pig"), ZodiacProgress.STRANGER)

func test_recall_freezes_exact_counteroffer_terms_and_survives_older_checkpoint_merge() -> void:
	for id: String in ["pig", "ox"]:
		var owner := FLOW.campaign(id)
		var topic: String = id + "." + ("earn" if id == "pig" else "load")
		var node_id: String = id + ".t1plus." + ("earn" if id == "pig" else "load")
		var recall_id: String = id + ".t2." + ("earn_memory" if id == "pig" else "load_memory")
		FLOW.terms(owner, node_id)
		assert_true(owner.zodiac.respond("HAGGLE").ok)
		assert_true(owner.zodiac.respond("REFUSE").ok)
		var topics: Array = ZodiacCatalog.persuasion_config(id).progression[0].promises
		owner.zodiac.progress.commit(id, "kindred-fixture", {"promises_kept": 3, "promise_kept:" + topics[0]: 2, "promise_kept:" + topics[1]: 1})
		owner.zodiac.progress.record_disposition(id, "kindred", "NORMAL")
		FLOW.node(owner, recall_id)
		var quote: String = owner.zodiac.quote().speech
		assert_true(quote.contains("25.000" if id == "pig" else "60 PTS"))
		var old := owner.zodiac.snapshot()
		owner.zodiac.progress.remember(id, "newer", topic, {"result": "FULFILLED", "node_id": node_id, "target_label": ""})
		owner.zodiac.restore(old)
		assert_eq(owner.zodiac.quote().speech, quote)
		assert_eq(owner.zodiac.persuasion.state().node.bound_memory.result, "REFUSED")
		assert_eq(owner.zodiac.progress.memory(id, topic).result, "FULFILLED")

func test_last_chance_recovery_is_once_and_second_zero_locks() -> void:
	for id: String in ["pig", "ox"]:
		var owner := FLOW.campaign(id, false)
		owner.zodiac.persuasion.apply_patience(-3)
		var token := owner.zodiac.offer_token()
		assert_true(owner.zodiac.persuasion.resolve_last_chance("B", token))
		assert_eq(owner.zodiac.persuasion.state().patience, 1)
		assert_false(owner.zodiac.persuasion.resolve_last_chance("B", token))
		owner.zodiac.persuasion.apply_patience(-1)
		assert_false(owner.zodiac.has_open_interaction())
		owner._enter_phase(CampaignManager.CampaignPhase.AFTERNOON_EVENT)
		assert_eq(owner.zodiac.mood(), "UNPLEASED")
		var declined := FLOW.campaign(id, false)
		declined.zodiac.persuasion.apply_patience(-3)
		assert_true(declined.zodiac.persuasion.resolve_last_chance("C"))
		assert_true(declined.zodiac.persuasion.state().interaction_locked)

func test_v5_started_visits_remain_legacy_but_pre_noon_and_later_days_upgrade() -> void:
	for id: String in ["pig", "ox"]:
		var owner := FLOW.campaign(id, false)
		var old := owner.zodiac.snapshot()
		old.version = 5
		old.daily.erase("persuasion")
		owner.zodiac.restore(old)
		assert_false(owner.zodiac.uses_persuasion())
		assert_eq(owner.zodiac.mood(), "NORMAL")
		owner.zodiac.enter_event(EventManager.EventSlot.NOON)
		assert_false(owner.zodiac.has_open_interaction())
		old.daily.slot = -1
		owner.zodiac.restore(old)
		assert_true(owner.zodiac.uses_persuasion())
		owner.zodiac.enter_event(EventManager.EventSlot.NOON)
		assert_true(owner.zodiac.has_open_question())
		owner.zodiac.begin_day(2, owner.seed_for("zodiac_selection", 2))
		assert_false(owner.zodiac.daily.get("legacy_negotiation", false))


func test_completed_previous_deal_and_setup_controls_cannot_close_a_new_card_deadline() -> void:
	var owner := FLOW.campaign("ox")
	owner._enter_phase(CampaignManager.CampaignPhase.NOON_DEAL)
	owner.zodiac.deal.start_tutorial_deal()
	assert_true(FLOW.finish(owner))
	assert_eq(owner.zodiac.deal.current_phase, 2)
	assert_eq(owner.current_phase, CampaignManager.CampaignPhase.NOON_EVENT)
	_choose(owner)
	var pending: Dictionary = owner.zodiac.daily.promises[0]
	owner._enter_phase(CampaignManager.CampaignPhase.AFTERNOON_DEAL)
	owner.zodiac.deal.set_current_drink(DrinkCatalog.BAC_XIU)
	assert_false(pending.broken)
	assert_false(pending.observation_ready)
	var opening: Array[String] = []
	for card: CardData in FLOW.cards(owner.gieo_que.persistent_deck, FLOW.OPENING): opening.append(card.unique_id)
	owner.zodiac.deal.start_deal(42, false, opening)
	assert_true(pending.observation_ready)
	assert_true(FLOW.meld(owner).ok)
	assert_true(pending.matched and not pending.broken)

func test_story_emblem_requires_reencounter_and_preserves_legacy_eligibility() -> void:
	for id: String in ["pig", "ox"]:
		var owner := FLOW.campaign(id)
		var progress := owner.zodiac.progress
		var topics: Array = ZodiacCatalog.persuasion_config(id).progression[0].promises
		progress.commit(id, "story", {"promises_kept": 3, "promise_kept:" + topics[0]: 2, "promise_kept:" + topics[1]: 1, "pleased_victories": 1})
		progress.record_disposition(id, "kindred", "NORMAL")
		assert_false(progress.eligible(id))
		progress.commit(id, "honest-no", {"promises_refused": 1})
		assert_true(progress.eligible(id))
		assert_false(owner.zodiac.complete_scene())
		owner.zodiac.begin_day(2, owner.seed_for("zodiac_selection", 2))
		assert_true(owner.zodiac.complete_scene())
		assert_false(owner.zodiac.complete_scene())
		assert_true(owner.zodiac.prefer_emblem(id))
		owner.zodiac.begin_day(9, owner.seed_for("zodiac_selection", 9))
		assert_eq(owner.zodiac.active_id(), id)
		var legacy := ZodiacProgress.new("")
		legacy.commit(id, "legacy", {"requests_resolved": 4, "pleased_victories": 1})
		assert_true(legacy.eligible(id))
