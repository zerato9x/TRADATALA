@tool
extends McpTestSuite
const FLOW := preload("res://tests/rat_tiger_test_flow.gd")
const NOON_FLOW := preload("res://tests/zodiac_test_flow.gd")

func suite_name() -> String: return "rat_tiger_persuasion"

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
	for id: String in ["rat", "tiger"]:
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
	for id: String in ["rat", "tiger"]:
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
	for id: String in ["rat", "tiger"]:
		var owner := FLOW.campaign(id)
		var node_id: String = id + ".t1plus." + ("reuse" if id == "rat" else "high")
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



func test_progression_requires_variety_and_does_not_cross_character_records() -> void:
	for id: String in ["rat", "tiger"]:
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
		assert_eq(progress.relationship_tier("tiger" if id == "rat" else "rat"), ZodiacProgress.STRANGER)



func test_last_chance_recovery_is_once_and_second_zero_locks() -> void:
	for id: String in ["rat", "tiger"]:
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



func test_v7_started_visits_remain_legacy_but_pre_noon_and_later_days_upgrade() -> void:
	for id: String in ["rat", "tiger"]:
		var owner := FLOW.campaign(id, false)
		var old := owner.zodiac.snapshot()
		old.version = 7
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
		owner.zodiac.begin_day(4, owner.seed_for("zodiac_selection", 4))
		assert_false(owner.zodiac.daily.get("legacy_negotiation", false))




func test_story_emblem_requires_reencounter_and_preserves_legacy_eligibility() -> void:
	for id: String in ["rat", "tiger"]:
		var owner := FLOW.campaign(id)
		var progress := owner.zodiac.progress
		var topics: Array = ZodiacCatalog.persuasion_config(id).progression[0].promises
		progress.commit(id, "story", {"promises_kept": 3, "promise_kept:" + topics[0]: 2, "promise_kept:" + topics[1]: 1, "pleased_victories": 1})
		progress.record_disposition(id, "kindred", "NORMAL")
		assert_false(progress.eligible(id))
		progress.commit(id, "honest-no", {"promises_refused": 1})
		assert_true(progress.eligible(id))
		assert_false(owner.zodiac.complete_scene())
		owner.zodiac.begin_day(4, owner.seed_for("zodiac_selection", 4))
		assert_true(owner.zodiac.complete_scene())
		assert_false(owner.zodiac.complete_scene())
		assert_true(owner.zodiac.prefer_emblem(id))
		owner.zodiac.begin_day(11, owner.seed_for("zodiac_selection", 11))
		assert_eq(owner.zodiac.active_id(), id)
		var legacy := ZodiacProgress.new("")
		legacy.commit(id, "legacy", {"requests_resolved": 4, "pleased_victories": 1})
		assert_true(legacy.eligible(id))





func test_rat_discard_recovery_requires_the_same_card_in_a_later_play_and_judges_once() -> void:
	var owner := FLOW.campaign("rat")
	var pending := FLOW.accept(owner, "rat.t1plus.reuse")
	FLOW.afternoon(owner)
	var returned := FLOW.recover_discard(owner)
	assert_true(returned.ok)
	assert_eq(pending.recovered_ids, [returned.recovered.unique_id])
	assert_false(pending.matched)
	owner.zodiac._observe_action(returned)
	assert_eq(pending.recovered_ids.size(), 1)
	assert_true(FLOW.meld(owner).ok)
	assert_true(pending.matched)
	owner.zodiac.persuasion.judge()
	assert_false(owner.zodiac.persuasion.state().judged)
	assert_true(FLOW.finish(owner))
	assert_eq(owner.zodiac.progress.memory("rat", "rat.reuse").result, "FULFILLED")
	var kept: int = owner.zodiac.progress.record("rat").promises_kept
	owner.zodiac.enter_event(EventManager.EventSlot.AFTERNOON)
	assert_eq(owner.zodiac.progress.record("rat").promises_kept, kept)

func test_both_discard_swap_drinks_produce_exact_recovery_evidence() -> void:
	for drink: String in [DrinkCatalog.NHAN_TRAN, DrinkCatalog.DEN_DA]:
		var owner := FLOW.campaign("rat")
		var pending := FLOW.accept(owner, "rat.t1plus.reuse")
		FLOW.afternoon(owner)
		var result := FLOW.recover_discard(owner, drink)
		assert_true(result.ok)
		assert_eq(pending.recovered_ids, [result.recovered.unique_id])
		assert_false(result.discarded.unique_id in pending.recovered_ids)
		assert_true(FLOW.meld(owner).ok)
		assert_true(pending.matched)

func test_rat_draws_failed_drinks_and_plays_before_recovery_do_not_fulfill() -> void:
	var owner := FLOW.campaign("rat")
	var pending := FLOW.accept(owner, "rat.t1plus.reuse")
	FLOW.afternoon(owner)
	assert_true(pending.get("recovered_ids", []).is_empty())
	assert_false(owner.zodiac.deal.use_nuoc_voi(-1, owner.zodiac.deal.hand[0]).ok)
	assert_true(FLOW.meld(owner).ok)
	assert_false(pending.matched)
	owner.zodiac.deal.set_current_drink(DrinkCatalog.NAU_DA)
	assert_true(owner.zodiac.deal.use_nau_da(owner.zodiac.deal.melds[0].meld_id).ok)
	assert_true(pending.get("recovered_ids", []).is_empty())
	assert_true(FLOW.meld(owner).ok)
	assert_false(pending.matched)
	_judge(owner)
	assert_eq(owner.zodiac.progress.memory("rat", "rat.reuse").result, "BROKEN")

func test_rat_explicit_counteroffer_allows_both_meld_recovery_drinks() -> void:
	for whole in [false, true]:
		var owner := FLOW.campaign("rat")
		FLOW.terms(owner, "rat.t1plus.reuse")
		var token := owner.zodiac.offer_token()
		assert_true(owner.zodiac.respond("HAGGLE").requires_confirmation)
		assert_eq(owner.zodiac.current_demand().id, "rat.reuse")
		assert_eq(owner.zodiac.current_demand().recovery_source, "any")
		assert_false(owner.zodiac.respond("ACCEPT", [], token).ok)
		assert_true(owner.zodiac.respond("ACCEPT").pending)
		owner.zodiac.continue_conversation()
		FLOW.afternoon(owner)
		var deal := owner.zodiac.deal
		assert_true(deal.create_meld(FLOW.cards(deal.hand, FLOW.OPENING.slice(0, 4))).ok)
		var chosen: String = deal.melds[0].cards[0].unique_id
		assert_true(FLOW.recover_chosen(owner, chosen, whole).ok)
		assert_false(owner.zodiac.daily.promises[0].matched)
		assert_true(FLOW.meld(owner).ok if whole else deal.extend_meld(deal.melds[0].meld_id, CardTargetQuery.resolve_ids(deal.hand, [chosen])).ok)
		assert_true(owner.zodiac.daily.promises[0].matched)
		assert_true(FLOW.finish(owner))
		assert_eq(owner.zodiac.progress.promise_kinds("rat"), 1)

func test_rat_must_play_a_recovered_card_not_another_card_or_old_extension_member() -> void:
	var owner := FLOW.campaign("rat")
	var pending := FLOW.accept(owner, "rat.t1plus.reuse")
	FLOW.afternoon(owner)
	assert_true(FLOW.recover_discard(owner).ok)
	var deal := owner.zodiac.deal
	assert_true(deal.create_meld(FLOW.cards(deal.hand, [["7", "Hearts"], ["7", "Diamonds"], ["7", "Clubs"]])).ok)
	assert_false(pending.matched)
	assert_true(deal.extend_meld(deal.melds[0].meld_id, FLOW.cards(deal.hand, [["7", "Spades"]])).ok)
	assert_false(pending.matched)

func test_extension_goal_counts_distinct_new_physical_cards_once() -> void:
	var owner := FLOW.campaign("rat")
	var pending := FLOW.accept(owner, "rat.t1plus.extend")
	FLOW.afternoon(owner)
	assert_true(FLOW.meld(owner).ok)
	assert_false(pending.matched)
	var result := FLOW.extension(owner)
	assert_true(result.ok)
	assert_eq(pending.extended_ids, result.committed_card_ids)
	owner.zodiac._observe_action(result)
	assert_eq(pending.extended_ids.size(), 1)
	assert_false(pending.matched)
	var deal := owner.zodiac.deal
	deal.set_current_drink(DrinkCatalog.NUOC_VOI)
	var six: CardData = FLOW.cards(deal.melds[0].cards, [["6", "Hearts"]])[0]
	assert_true(deal.use_nuoc_voi(deal.melds[0].meld_id, six).ok)
	assert_true(deal.extend_meld(deal.melds[0].meld_id, [six]).ok)
	assert_eq(pending.extended_ids.size(), 1)
	assert_false(pending.matched)
	assert_true(deal.extend_meld(deal.melds[0].meld_id, FLOW.cards(deal.hand, [["7", "Hearts"]])).ok)
	assert_true(pending.matched)
	assert_eq(pending.extended_ids.size(), 2)

func test_extension_goal_can_cross_phase_boundary_and_has_explicit_smaller_counteroffer() -> void:
	var owner := FLOW.campaign("rat")
	var pending := FLOW.accept(owner, "rat.t1plus.extend")
	FLOW.afternoon(owner)
	assert_true(FLOW.meld(owner).ok)
	assert_true(FLOW.extension(owner).ok)
	assert_true(FLOW.phase_two(owner))
	assert_true(owner.zodiac.deal.extend_meld(owner.zodiac.deal.melds[0].meld_id, FLOW.cards(owner.zodiac.deal.hand, [["7", "Hearts"]])).ok)
	assert_true(pending.matched)
	var counter := FLOW.campaign("rat")
	FLOW.terms(counter, "rat.t1plus.extend")
	assert_true(counter.zodiac.respond("HAGGLE").requires_confirmation)
	assert_eq(counter.zodiac.current_demand().card_count, 1)
	assert_true(counter.zodiac.respond("ACCEPT").pending)
	counter.zodiac.continue_conversation()
	FLOW.afternoon(counter)
	assert_true(FLOW.meld(counter).ok)
	assert_true(FLOW.extension(counter).ok)
	assert_true(counter.zodiac.daily.promises[0].matched)

func test_tiger_binds_all_highest_printed_opening_cards_once_and_commits_one_in_time() -> void:
	var owner := FLOW.campaign("tiger")
	var pending := FLOW.accept(owner, "tiger.t1plus.high")
	assert_false(pending.get("opening_bound", false))
	FLOW.afternoon(owner)
	var ids := CardTargetQuery.physical_ids(FLOW.cards(owner.zodiac.deal.hand, [["K", "Hearts"], ["K", "Diamonds"], ["K", "Clubs"], ["K", "Spades"]]))
	assert_true(pending.opening_bound)
	assert_eq(pending.opening_rank, 13)
	assert_eq(pending.opening_ids, ids)
	assert_eq(pending.memory_details.opening_targets.keys(), ids)
	assert_true(pending.memory_details.commitment_en.contains("Opening targets:"))
	assert_true(FLOW.meld(owner).ok)
	assert_false(pending.matched)
	owner.zodiac._observe_action({"ok": true, "action": "start_deal"})
	assert_eq(pending.opening_ids, ids)
	assert_true(FLOW.next(owner).ok)
	assert_true(pending.matched and not pending.broken)
	assert_true(FLOW.finish(owner))
	assert_eq(owner.zodiac.progress.memory("tiger", "tiger.high").opening_targets.keys(), ids)

func test_tiger_mandatory_discard_closes_the_original_deadline_and_later_draws_do_not_replace_targets() -> void:
	var owner := FLOW.campaign("tiger")
	var pending := FLOW.accept(owner, "tiger.t1plus.high")
	FLOW.afternoon(owner)
	var ids: Array = pending.opening_ids.duplicate()
	owner.zodiac.deal.set_current_drink(DrinkCatalog.BAC_XIU)
	assert_true(owner.zodiac.deal.discard_card(FLOW.cards(owner.zodiac.deal.hand, [["9", "Hearts"]])[0]).ok)
	assert_true(pending.broken)
	assert_eq(pending.opening_ids, ids)
	assert_true(FLOW.next(owner).ok)
	assert_false(pending.matched)
	_judge(owner)
	assert_eq(owner.zodiac.progress.memory("tiger", "tiger.high").result, "BROKEN")

func test_tiger_counteroffer_allows_a_later_turn_but_not_phase_two() -> void:
	for late_phase in [false, true]:
		var owner := FLOW.campaign("tiger")
		FLOW.terms(owner, "tiger.t1plus.high")
		assert_true(owner.zodiac.respond("HAGGLE").requires_confirmation)
		assert_false(owner.zodiac.current_demand().before_first_discard)
		assert_true(owner.zodiac.respond("ACCEPT").pending)
		owner.zodiac.continue_conversation()
		FLOW.afternoon(owner)
		var pending: Dictionary = owner.zodiac.daily.promises[0]
		if late_phase:
			assert_true(FLOW.phase_two(owner))
			assert_true(pending.broken)
		else:
			owner.zodiac.deal.set_current_drink(DrinkCatalog.BAC_XIU)
			assert_true(owner.zodiac.deal.discard_card(FLOW.cards(owner.zodiac.deal.hand, [["9", "Hearts"]])[0]).ok)
			assert_false(pending.broken)
			assert_true(FLOW.next(owner).ok)
			assert_true(pending.matched)

func test_tiger_counts_printed_rank_instead_of_card_value_and_extension_only_counts_added_targets() -> void:
	var owner := FLOW.campaign("tiger")
	FLOW.accept(owner, "tiger.t1plus.high")
	var three: CardData = FLOW.cards(owner.gieo_que.persistent_deck, [["3", "Hearts"]])[0]
	three.value_modifiers.append(20)
	owner._enter_phase(CampaignManager.CampaignPhase.AFTERNOON_DEAL)
	var specs := [["J", "Hearts"], ["Q", "Hearts"], ["K", "Hearts"], ["10", "Hearts"],
		["K", "Diamonds"], ["K", "Clubs"], ["3", "Hearts"], ["4", "Hearts"], ["5", "Hearts"], ["7", "Hearts"]]
	owner.zodiac.deal.start_deal(42, false, CardTargetQuery.physical_ids(FLOW.cards(owner.gieo_que.persistent_deck, specs)))
	var pending: Dictionary = owner.zodiac.daily.promises[0]
	assert_eq(pending.opening_rank, 13)
	assert_false(three.unique_id in pending.opening_ids)
	# The controlled old Run contains KH; the real Extension commits only 10H.
	owner.zodiac.begin_run_restore()
	var high_result := owner.zodiac.deal.create_meld(FLOW.cards(owner.zodiac.deal.hand, specs.slice(0, 3)))
	assert_true(high_result.ok)
	owner.zodiac.finish_run_restore()
	var extension := owner.zodiac.deal.extend_meld(high_result.meld_id, FLOW.cards(owner.zodiac.deal.hand, [["10", "Hearts"]]))
	assert_true(extension.ok)
	assert_true(extension.context.cards.any(func(c: CardData): return c.unique_id in pending.opening_ids))
	assert_false(extension.committed_card_ids.any(func(id: String): return id in pending.opening_ids))
	assert_false(pending.matched)

func test_tiger_new_group_requires_four_cards_at_creation_not_after_extension() -> void:
	var owner := FLOW.campaign("tiger")
	var pending := FLOW.accept(owner, "tiger.t1plus.stand")
	FLOW.afternoon(owner)
	assert_true(FLOW.meld(owner).ok)
	assert_false(pending.matched)
	assert_true(FLOW.extension(owner).ok)
	assert_false(pending.matched)
	assert_true(owner.zodiac.deal.create_meld(FLOW.cards(owner.zodiac.deal.hand, [["K", "Hearts"], ["K", "Diamonds"], ["K", "Clubs"], ["K", "Spades"]])).ok)
	assert_true(pending.matched)
	var counter := FLOW.campaign("tiger")
	FLOW.terms(counter, "tiger.t1plus.stand")
	assert_true(counter.zodiac.respond("HAGGLE").requires_confirmation)
	assert_eq(counter.zodiac.current_demand().card_count, 3)
	assert_true(counter.zodiac.respond("ACCEPT").pending)
	counter.zodiac.continue_conversation()
	FLOW.afternoon(counter)
	assert_true(FLOW.meld(counter).ok)
	assert_true(counter.zodiac.daily.promises[0].matched)

func test_physical_choice_requires_rat_return_then_play_or_tiger_four_card_new_meld() -> void:
	for id: String in ["rat", "tiger"]:
		var owner := FLOW.campaign(id)
		FLOW.terms(owner, id + ".t1plus.card")
		var chosen: String = owner.zodiac.current_demand().offered_ids[0]
		assert_true(owner.zodiac.respond("ACCEPT", [chosen]).pending)
		owner.zodiac.continue_conversation()
		FLOW.chosen_deal(owner, chosen)
		assert_true(FLOW.chosen_play(owner, chosen))
		assert_true(owner.zodiac.daily.promises[0].matched)
		assert_true(FLOW.finish(owner))
		assert_eq(owner.zodiac.progress.memory(id, id + ".card").target_id, chosen)

func test_rat_recovery_is_not_initial_play_and_tiger_three_card_meld_cannot_be_repaired_by_extension() -> void:
	for id: String in ["rat", "tiger"]:
		var owner := FLOW.campaign(id)
		FLOW.terms(owner, id + ".t1plus.card")
		var chosen: String = owner.zodiac.current_demand().offered_ids[0]
		owner.zodiac.respond("ACCEPT", [chosen])
		owner.zodiac.continue_conversation()
		FLOW.chosen_deal(owner, chosen)
		var deal := owner.zodiac.deal
		assert_true(deal.create_meld(deal.hand.slice(0, 4 if id == "rat" else 3)).ok)
		assert_false(owner.zodiac.daily.promises[0].matched)
		if id == "rat":
			assert_true(FLOW.recover_chosen(owner, chosen).ok)
			assert_false(owner.zodiac.daily.promises[0].matched)
		else:
			assert_true(deal.extend_meld(deal.melds[0].meld_id, deal.hand.slice(0, 1)).ok)
			assert_false(owner.zodiac.daily.promises[0].matched)

func test_recovery_and_opening_binding_ignore_other_deals_and_restoration() -> void:
	var rat := FLOW.campaign("rat")
	var pending := FLOW.accept(rat, "rat.t1plus.reuse")
	rat._enter_phase(CampaignManager.CampaignPhase.NOON_DEAL)
	rat.zodiac.deal.start_tutorial_deal()
	assert_true(FLOW.meld(rat).get("ok", false) == false)
	assert_false(pending.started or pending.matched)
	FLOW.afternoon(rat)
	rat.zodiac.begin_run_restore()
	assert_true(FLOW.recover_discard(rat).ok)
	rat.zodiac.finish_run_restore()
	assert_true(pending.get("recovered_ids", []).is_empty())
	assert_true(FLOW.meld(rat).ok)
	assert_false(pending.matched)
	var tiger := FLOW.campaign("tiger")
	var high := FLOW.accept(tiger, "tiger.t1plus.high")
	tiger._enter_phase(CampaignManager.CampaignPhase.AFTERNOON_DEAL)
	tiger.zodiac.deal.set_current_drink(DrinkCatalog.NUOC_VOI)
	assert_false(high.get("opening_bound", false))
	assert_false(high.broken)
	FLOW.afternoon(tiger)
	assert_true(high.opening_bound and high.opening_rank == 13)

func test_counteroffer_recall_freezes_exact_terms_while_permanent_history_advances() -> void:
	for id: String in ["rat", "tiger"]:
		var owner := FLOW.campaign(id)
		var key: String = "reuse" if id == "rat" else "high"
		FLOW.terms(owner, id + ".t1plus." + key)
		assert_true(owner.zodiac.respond("HAGGLE").requires_confirmation)
		var exact: String = owner.zodiac.current_demand().en
		assert_true(owner.zodiac.respond("REFUSE").ok)
		var topics: Array = ZodiacCatalog.persuasion_config(id).progression[0].promises
		owner.zodiac.progress.commit(id, "kindred-fixture", {"promises_kept": 3, "promise_kept:" + topics[0]: 2, "promise_kept:" + topics[1]: 1})
		owner.zodiac.progress.record_disposition(id, "kindred", "NORMAL")
		FLOW.node(owner, id + ".t2." + key + "_memory")
		var quote: String = owner.zodiac.quote().speech
		assert_true(quote.contains(exact))
		var old := owner.zodiac.snapshot()
		owner.zodiac.progress.remember(id, "newer", id + "." + key, {"result": "FULFILLED", "node_id": id + ".t1plus." + key, "target_label": ""})
		owner.zodiac.restore(old)
		assert_eq(owner.zodiac.quote().speech, quote)
		assert_eq(owner.zodiac.persuasion.state().node.bound_memory.result, "REFUSED")
		assert_eq(owner.zodiac.progress.memory(id, id + "." + key).result, "FULFILLED")
