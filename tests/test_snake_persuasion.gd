@tool
extends McpTestSuite
const FLOW := preload("res://tests/snake_test_flow.gd")
const NOON_FLOW := preload("res://tests/zodiac_test_flow.gd")

func suite_name() -> String: return "snake_persuasion"

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
	for id: String in ["snake"]:
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
	for id: String in ["snake"]:
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
	for id: String in ["snake"]:
		var owner := FLOW.campaign(id)
		var node_id: String = id + ".t1plus." + "cadence"
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
	for id: String in ["snake"]:
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
	for id: String in ["snake"]:
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



func test_v8_started_visits_remain_legacy_but_pre_noon_and_later_days_upgrade() -> void:
	for id: String in ["snake"]:
		var owner := FLOW.campaign(id, false)
		var old := owner.zodiac.snapshot()
		old.version = 8
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
		owner.zodiac.begin_day(5, owner.seed_for("zodiac_selection", 5))
		assert_false(owner.zodiac.daily.get("legacy_negotiation", false))




func test_story_emblem_requires_reencounter_and_preserves_legacy_eligibility() -> void:
	for id: String in ["snake"]:
		var owner := FLOW.campaign(id)
		var progress := owner.zodiac.progress
		var topics: Array = ZodiacCatalog.persuasion_config(id).progression[0].promises
		progress.commit(id, "story", {"promises_kept": 3, "promise_kept:" + topics[0]: 2, "promise_kept:" + topics[1]: 1, "pleased_victories": 1})
		progress.record_disposition(id, "kindred", "NORMAL")
		assert_false(progress.eligible(id))
		progress.commit(id, "honest-no", {"promises_refused": 1})
		assert_true(progress.eligible(id))
		assert_false(owner.zodiac.complete_scene())
		owner.zodiac.begin_day(5, owner.seed_for("zodiac_selection", 5))
		assert_true(owner.zodiac.complete_scene())
		assert_false(owner.zodiac.complete_scene())
		assert_true(owner.zodiac.prefer_emblem(id))
		owner.zodiac.begin_day(12, owner.seed_for("zodiac_selection", 12))
		assert_eq(owner.zodiac.active_id(), id)
		var legacy := ZodiacProgress.new("")
		legacy.commit(id, "legacy", {"requests_resolved": 4, "pleased_victories": 1})
		assert_true(legacy.eligible(id))





func test_sequence_uses_first_committed_scoring_actions_and_judges_once() -> void:
	var owner := FLOW.campaign("snake")
	var pending := FLOW.accept(owner, "snake.t1plus.cadence")
	FLOW.afternoon(owner)
	assert_true(FLOW.first(owner).ok)
	assert_eq(pending.sequence_cursor, 1)
	assert_false(pending.matched)
	assert_true(FLOW.next(owner).ok)
	assert_eq(pending.sequence_cursor, 2)
	assert_false(pending.matched)
	assert_true(FLOW.last(owner).ok)
	assert_true(pending.matched)
	assert_true(owner.zodiac.deal.extend_meld(owner.zodiac.deal.melds[0].meld_id, FLOW.cards(owner.zodiac.deal.hand, [["7", "Hearts"]])).ok)
	assert_true(pending.matched and not pending.broken)
	owner.zodiac.persuasion.judge()
	assert_false(owner.zodiac.persuasion.state().judged)
	assert_true(FLOW.finish(owner))
	assert_eq(owner.zodiac.progress.memory("snake", "snake.cadence").result, "FULFILLED")
	var before := owner.zodiac.progress.snapshot()
	owner.zodiac.enter_event(EventManager.EventSlot.AFTERNOON)
	assert_eq(owner.zodiac.progress.snapshot(), before)

func test_sequence_wrong_middle_is_sticky_and_cannot_restart() -> void:
	var owner := FLOW.campaign("snake")
	var pending := FLOW.accept(owner, "snake.t1plus.cadence")
	FLOW.afternoon(owner)
	assert_true(FLOW.first(owner).ok)
	assert_true(FLOW.last(owner).ok)
	assert_true(pending.broken)
	assert_eq(pending.sequence_cursor, 1)
	assert_true(FLOW.next(owner).ok)
	assert_false(pending.matched)
	assert_true(FLOW.finish(owner))
	assert_eq(owner.zodiac.progress.memory("snake", "snake.cadence").result, "BROKEN")

func test_sequence_allows_other_actions_but_failed_previews_and_replays_are_inert() -> void:
	var owner := FLOW.campaign("snake")
	var pending := FLOW.accept(owner, "snake.t1plus.cadence")
	FLOW.afternoon(owner)
	var deal := owner.zodiac.deal
	deal.preview_new_meld_payout(FLOW.cards(deal.hand, FLOW.OPENING.slice(0, 3)), "Run")
	assert_false(deal.create_meld(deal.hand.slice(0, 1)).ok)
	assert_eq(pending.get("sequence_cursor", 0), 0)
	var result := FLOW.first(owner)
	assert_true(result.ok)
	owner.zodiac._observe_action(result)
	assert_eq(pending.sequence_cursor, 1)
	assert_true(deal.discard_card(FLOW.cards(deal.hand, [["K", "Clubs"]])[0]).ok)
	assert_false(pending.broken)
	assert_true(FLOW.next(owner).ok)
	assert_true(FLOW.last(owner).ok)
	assert_true(pending.matched)
	assert_true(FLOW.finish(owner))

func test_shorter_sequence_requires_confirmation_and_keeps_signed_terms() -> void:
	var owner := FLOW.campaign("snake")
	FLOW.terms(owner, "snake.t1plus.cadence")
	var token := owner.zodiac.offer_token()
	assert_true(owner.zodiac.respond("HAGGLE").requires_confirmation)
	assert_false(owner.zodiac.respond("ACCEPT", [], token).ok)
	assert_eq(owner.zodiac.current_demand().sequence, ["new_meld", "extension"])
	assert_false(owner.zodiac.persuasion.can_haggle())
	assert_true(owner.zodiac.respond("ACCEPT").pending)
	owner.zodiac.continue_conversation()
	FLOW.afternoon(owner)
	assert_true(FLOW.first(owner).ok and FLOW.next(owner).ok)
	assert_true(owner.zodiac.daily.promises[0].matched)
	assert_true(FLOW.finish(owner))
	var memory := owner.zodiac.progress.memory("snake", "snake.cadence")
	assert_true(memory.counteroffer)
	assert_true(memory.commitment_en.contains("first two"))

func test_unfinished_sequence_fails_at_actual_deal_close() -> void:
	var owner := FLOW.campaign("snake")
	var pending := FLOW.accept(owner, "snake.t1plus.cadence")
	FLOW.afternoon(owner)
	assert_true(FLOW.first(owner).ok)
	assert_true(FLOW.next(owner).ok)
	assert_true(FLOW.finish(owner))
	assert_false(pending.matched)
	assert_true(pending.broken)
	assert_eq(owner.zodiac.progress.memory("snake", "snake.cadence").result, "BROKEN")

func test_whole_deal_restraint_only_completes_at_phase_two_settlement() -> void:
	var owner := FLOW.campaign("snake")
	var pending := FLOW.accept(owner, "snake.t1plus.still")
	FLOW.afternoon(owner)
	var deal := owner.zodiac.deal
	deal.set_current_drink(DrinkCatalog.NUOC_VOI)
	assert_false(deal.use_nuoc_voi(-1, deal.hand[0]).ok)
	assert_true(FLOW.first(owner).ok)
	assert_false(pending.matched or pending.broken)
	assert_true(FLOW.phase_two(owner))
	assert_false(pending.matched or pending.broken)
	assert_true(FLOW.finish(owner))
	assert_true(pending.matched and not pending.broken)
	assert_eq(owner.zodiac.progress.memory("snake", "snake.still").result, "FULFILLED")

func test_each_successful_recovery_breaks_restraint_even_after_replay() -> void:
	for kind in ["nhan", "den", "nuoc", "nau"]:
		var owner := FLOW.campaign("snake")
		var pending := FLOW.accept(owner, "snake.t1plus.still")
		FLOW.afternoon(owner)
		var result := {}
		if kind in ["nhan", "den"]:
			result = FLOW.recover_discard(owner, DrinkCatalog.NHAN_TRAN if kind == "nhan" else DrinkCatalog.DEN_DA)
		else:
			assert_true(FLOW.first(owner).ok)
			result = FLOW.recover_meld(owner, kind == "nau")
		assert_true(result.ok)
		assert_true(pending.broken)
		var evidence: int = pending.observations.size()
		owner.zodiac._observe_action(result)
		assert_eq(pending.observations.size(), evidence)
		assert_true(FLOW.finish(owner))
		assert_eq(owner.zodiac.progress.memory("snake", "snake.still").result, "BROKEN")

func test_phase_one_restraint_counteroffer_frees_phase_two() -> void:
	var owner := FLOW.campaign("snake")
	FLOW.terms(owner, "snake.t1plus.still")
	assert_true(owner.zodiac.respond("HAGGLE").requires_confirmation)
	assert_eq(owner.zodiac.current_demand().deal_phase, 1)
	assert_true(owner.zodiac.respond("ACCEPT").pending)
	owner.zodiac.continue_conversation()
	FLOW.afternoon(owner)
	var pending: Dictionary = owner.zodiac.daily.promises[0]
	assert_true(FLOW.first(owner).ok)
	assert_true(FLOW.phase_two(owner))
	assert_true(pending.matched and not pending.broken)
	assert_true(FLOW.recover_meld(owner).ok)
	assert_false(pending.broken)
	assert_true(FLOW.finish(owner))
	assert_eq(owner.zodiac.progress.memory("snake", "snake.still").result, "FULFILLED")
	assert_true(owner.zodiac.progress.memory("snake", "snake.still").counteroffer)

func test_phase_one_restraint_cannot_be_repaired_in_phase_two() -> void:
	var owner := FLOW.campaign("snake")
	FLOW.terms(owner, "snake.t1plus.still")
	owner.zodiac.respond("HAGGLE")
	owner.zodiac.respond("ACCEPT")
	owner.zodiac.continue_conversation()
	FLOW.afternoon(owner)
	assert_true(FLOW.recover_discard(owner).ok)
	assert_true(FLOW.finish(owner))
	assert_eq(owner.zodiac.progress.memory("snake", "snake.still").result, "BROKEN")

func test_chosen_physical_card_requires_extension_not_new_meld_or_same_rank_copy() -> void:
	var owner := FLOW.campaign("snake")
	var chosen := _choose(owner)
	FLOW.chosen_deal(owner, chosen)
	assert_true(FLOW.chosen_first(owner).ok)
	assert_false(owner.zodiac.daily.promises[0].matched)
	assert_true(FLOW.chosen_next(owner, chosen).ok)
	assert_true(owner.zodiac.daily.promises[0].matched)
	assert_true(FLOW.finish(owner))
	assert_eq(owner.zodiac.progress.memory("snake", "snake.card").target_id, chosen)
	assert_eq(owner.zodiac.progress.memory("snake", "snake.card").result, "FULFILLED")

func test_chosen_card_new_meld_alone_does_not_fulfill() -> void:
	var owner := FLOW.campaign("snake")
	var chosen := _choose(owner)
	FLOW.chosen_deal(owner, chosen)
	var hand := owner.zodiac.deal.hand
	var group: Array[CardData] = [hand[0], hand[1], hand[3]]
	var other_copy: Array[CardData] = [hand[2]]
	assert_true(owner.zodiac.deal.create_meld(group).ok)
	assert_false(owner.zodiac.daily.promises[0].matched)
	assert_true(owner.zodiac.deal.extend_meld(owner.zodiac.deal.melds[0].meld_id, other_copy).ok)
	assert_false(owner.zodiac.daily.promises[0].matched)
	assert_true(FLOW.finish(owner))
	assert_eq(owner.zodiac.progress.memory("snake", "snake.card").result, "BROKEN")

func test_acceptance_does_not_observe_previous_deal_setup() -> void:
	var owner := FLOW.campaign("snake")
	var pending := FLOW.accept(owner, "snake.t1plus.cadence")
	owner._enter_phase(CampaignManager.CampaignPhase.AFTERNOON_DEAL)
	owner.zodiac._observe_action({"ok": true, "action": "new_meld", "context": ScoringContext.new()})
	assert_eq(pending.get("sequence_cursor", 0), 0)
	assert_false(pending.get("observation_ready", true))
	FLOW.afternoon(owner)
	assert_true(FLOW.cadence(owner))
	assert_true(pending.matched)

func test_three_real_kept_promises_make_kindred_on_return_and_bind_recall() -> void:
	var owner := FLOW.campaign("snake")
	for index in 3:
		if index > 0:
			owner.start_campaign(true, owner.run_seed)
			owner.current_day_index = 5
			owner.zodiac.begin_day(5, owner.seed_for("zodiac_selection", 5))
			owner._enter_phase(CampaignManager.CampaignPhase.NOON_EVENT)
		FLOW.accept(owner, "snake.t1plus." + ("still" if index == 1 else "cadence"))
		FLOW.afternoon(owner)
		assert_true(FLOW.cadence(owner))
		assert_true(FLOW.finish(owner))
	assert_eq(owner.zodiac.progress.relationship_tier("snake"), ZodiacProgress.KINDRED)
	owner.start_campaign(true, owner.run_seed)
	owner.current_day_index = 5
	owner.zodiac.begin_day(5, owner.seed_for("zodiac_selection", 5))
	owner._enter_phase(CampaignManager.CampaignPhase.NOON_EVENT)
	FLOW.node(owner, "snake.t2.cadence_memory")
	var memory: Dictionary = owner.zodiac.persuasion.state().node.bound_memory.duplicate(true)
	assert_eq(memory.result, "FULFILLED")
	assert_false(owner.zodiac.quote().speech.contains("{target}"))
	owner.zodiac.progress.remember("snake", "later:fixture", "snake.cadence", {"result": "REFUSED", "commitment_en": "different", "commitment_vi": "khac"})
	assert_eq(owner.zodiac.persuasion.state().node.bound_memory, memory)
	assert_false(ZodiacCatalog.DRAGON_ENABLED)

func test_kindred_card_renewal_preserves_old_memory_and_offers_three_new_choices() -> void:
	var owner := FLOW.campaign("snake")
	var chosen := _choose(owner)
	FLOW.chosen_deal(owner, chosen)
	assert_true(FLOW.chosen_first(owner).ok and FLOW.chosen_next(owner, chosen).ok)
	assert_true(FLOW.finish(owner))
	owner.zodiac.progress.commit("snake", "fixture:renewal-kindred", {"promises_kept": 2, "promise_kept:snake.cadence": 2})
	owner.zodiac.progress.record_disposition("snake", "fixture:renewal-return", "NORMAL")
	owner.start_campaign(true, owner.run_seed)
	owner.current_day_index = 5
	owner.zodiac.begin_day(5, owner.seed_for("zodiac_selection", 5))
	owner._enter_phase(CampaignManager.CampaignPhase.NOON_EVENT)
	FLOW.node(owner, "snake.t2.card_memory")
	assert_eq(owner.zodiac.persuasion.state().node.bound_memory.target_id, chosen)
	assert_eq(owner.zodiac.current_demand().authority, "OFFER_THREE_PLAYER_CHOOSES")
	assert_eq(owner.zodiac.current_demand().offered_ids.size(), 3)
	assert_true(owner.zodiac.current_demand().target_ids.is_empty())
	assert_true(owner.zodiac.answer_question("B").ok)
	assert_true(owner.zodiac.continue_conversation())
	assert_false(owner.zodiac.can_accept())
	var offer := owner.zodiac.current_demand().duplicate(true)
	var rng := owner.zodiac._rng.state
	owner.zodiac.quote()
	assert_eq(owner.zodiac.current_demand(), offer)
	assert_eq(owner.zodiac._rng.state, rng)
	var next_card: String = offer.offered_ids[0]
	assert_true(owner.zodiac.respond("ACCEPT", [next_card]).pending)
	assert_eq(owner.zodiac.daily.promises[0].target_ids, [next_card])
	assert_eq(owner.zodiac.persuasion.state().node.bound_memory.target_id, chosen)
