@tool
extends McpTestSuite
const FLOW := preload("res://tests/horse_goat_test_flow.gd")
const NOON_FLOW := preload("res://tests/zodiac_test_flow.gd")

func suite_name() -> String: return "horse_goat_persuasion"

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
	for id: String in ["horse", "goat"]:
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
	for id: String in ["horse", "goat"]:
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
	for id: String in ["horse", "goat"]:
		var owner := FLOW.campaign(id)
		var node_id: String = id + ".t1plus." + ("pair" if id == "horse" else "notes")
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
	for id: String in ["horse", "goat"]:
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
		assert_eq(progress.relationship_tier("goat" if id == "horse" else "horse"), ZodiacProgress.STRANGER)


func test_last_chance_recovery_is_once_and_second_zero_locks() -> void:
	for id: String in ["horse", "goat"]:
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


func test_v6_started_visits_remain_legacy_but_pre_noon_and_later_days_upgrade() -> void:
	for id: String in ["horse", "goat"]:
		var owner := FLOW.campaign(id, false)
		var old := owner.zodiac.snapshot()
		old.version = 6
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
		owner.zodiac.begin_day(3, owner.seed_for("zodiac_selection", 3))
		assert_false(owner.zodiac.daily.get("legacy_negotiation", false))



func test_completed_previous_deal_and_setup_controls_cannot_close_a_new_card_deadline() -> void:
	var owner := FLOW.campaign("goat")
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
	for id: String in ["horse", "goat"]:
		var owner := FLOW.campaign(id)
		var progress := owner.zodiac.progress
		var topics: Array = ZodiacCatalog.persuasion_config(id).progression[0].promises
		progress.commit(id, "story", {"promises_kept": 3, "promise_kept:" + topics[0]: 2, "promise_kept:" + topics[1]: 1, "pleased_victories": 1})
		progress.record_disposition(id, "kindred", "NORMAL")
		assert_false(progress.eligible(id))
		progress.commit(id, "honest-no", {"promises_refused": 1})
		assert_true(progress.eligible(id))
		assert_false(owner.zodiac.complete_scene())
		owner.zodiac.begin_day(3, owner.seed_for("zodiac_selection", 3))
		assert_true(owner.zodiac.complete_scene())
		assert_false(owner.zodiac.complete_scene())
		assert_true(owner.zodiac.prefer_emblem(id))
		owner.zodiac.begin_day(10, owner.seed_for("zodiac_selection", 10))
		assert_eq(owner.zodiac.active_id(), id)
		var legacy := ZodiacProgress.new("")
		legacy.commit(id, "legacy", {"requests_resolved": 4, "pleased_victories": 1})
		assert_true(legacy.eligible(id))



func test_same_turn_matching_pairs_count_real_commits_once_and_reset_at_discard() -> void:
	var owner := FLOW.campaign("horse")
	var pending := FLOW.accept(owner, "horse.t1plus.pair")
	FLOW.afternoon(owner)
	var first := FLOW.first(owner)
	assert_true(first.ok)
	owner.zodiac._observe_action(first)
	assert_eq(pending.turn_actions.new_meld, 1)
	assert_true(FLOW.extension(owner).ok)
	assert_false(pending.matched)
	assert_true(owner.zodiac.deal.discard_card(FLOW.cards(owner.zodiac.deal.hand, [["K", "Clubs"]])[0]).ok)
	assert_true(pending.turn_actions.is_empty())
	assert_true(FLOW.next(owner).ok)
	assert_false(pending.matched)
	assert_true(owner.zodiac.deal.create_meld(FLOW.cards(owner.zodiac.deal.hand, [["9", "Hearts"], ["9", "Diamonds"], ["9", "Clubs"]])).get("ok", false) == false)
	assert_eq(pending.turn_actions.new_meld, 1)
	_judge(owner)
	assert_eq(owner.zodiac.progress.memory("horse", "horse.pair").result, "BROKEN")

func test_pair_can_be_kept_by_two_melds_or_two_extensions_and_optional_discards_do_not_reset() -> void:
	var owner := FLOW.campaign("horse")
	var pending := FLOW.accept(owner, "horse.t1plus.pair")
	FLOW.afternoon(owner)
	assert_true(FLOW.first(owner).ok)
	assert_true(FLOW.next(owner).ok)
	assert_true(pending.matched)
	assert_true(FLOW.finish(owner))
	assert_eq(owner.zodiac.progress.memory("horse", "horse.pair").result, "FULFILLED")
	var extensions := FLOW.campaign("horse")
	var pair := FLOW.accept(extensions, "horse.t1plus.pair")
	FLOW.afternoon(extensions)
	var deal := extensions.zodiac.deal
	assert_true(FLOW.meld(extensions).ok)
	assert_true(FLOW.extension(extensions).ok)
	assert_true(deal.extend_meld(deal.melds[0].meld_id, FLOW.cards(deal.hand, [["7", "Hearts"]])).ok)
	assert_true(pair.matched)
	var optional := FLOW.campaign("horse")
	var saved := FLOW.accept(optional, "horse.t1plus.pair")
	FLOW.afternoon(optional)
	optional.zodiac.deal.set_current_drink(DrinkCatalog.TRA_DA)
	assert_true(optional.zodiac.deal.discard_card(FLOW.cards(optional.zodiac.deal.hand, [["K", "Clubs"]])[0]).ok)
	assert_true(optional.zodiac.deal.discard_card(FLOW.cards(optional.zodiac.deal.hand, [["9", "Hearts"]])[0]).ok)
	assert_true(FLOW.first(optional).ok)
	assert_true(FLOW.next(optional).ok)
	assert_true(saved.matched)

func test_explicit_pair_counteroffer_allows_mixed_actions_and_keeps_semantic_identity() -> void:
	var owner := FLOW.campaign("horse")
	FLOW.terms(owner, "horse.t1plus.pair")
	var old_token := owner.zodiac.offer_token()
	assert_true(owner.zodiac.respond("HAGGLE").requires_confirmation)
	assert_false(owner.zodiac.current_demand().same_action)
	assert_eq(owner.zodiac.current_demand().id, "horse.pair")
	assert_false(owner.zodiac.respond("ACCEPT", [], old_token).ok)
	assert_true(owner.zodiac.respond("ACCEPT").pending)
	owner.zodiac.continue_conversation()
	FLOW.afternoon(owner)
	assert_true(FLOW.meld(owner).ok)
	assert_true(FLOW.extension(owner).ok)
	assert_true(owner.zodiac.daily.promises[0].matched)
	assert_true(FLOW.finish(owner))
	assert_eq(owner.zodiac.progress.promise_kinds("horse"), 1)
	assert_false(owner.zodiac.progress.memory("horse", "horse.pair").commitment_en.contains("two new Melds"))

func test_turn_boundary_and_phase_boundary_cannot_be_combined_into_a_pair() -> void:
	var owner := FLOW.campaign("horse")
	var pending := FLOW.accept(owner, "horse.t1plus.pair")
	FLOW.afternoon(owner)
	assert_true(FLOW.meld(owner).ok)
	assert_true(FLOW.phase_two(owner))
	assert_true(FLOW.extension(owner).ok)
	assert_false(pending.matched)
	assert_eq(pending.turn_actions.get("new_meld", 0), 0)
	assert_eq(pending.turn_actions.extension, 1)

func test_first_meld_same_turn_deadline_cannot_be_rescued_by_a_later_turn_or_meld() -> void:
	var owner := FLOW.campaign("horse")
	var pending := FLOW.accept(owner, "horse.t1plus.pace")
	FLOW.afternoon(owner)
	assert_true(FLOW.meld(owner).ok)
	var first: int = pending.first_meld_id
	assert_true(owner.zodiac.deal.discard_card(FLOW.cards(owner.zodiac.deal.hand, [["K", "Clubs"]])[0]).ok)
	assert_true(pending.broken)
	assert_true(FLOW.next(owner).ok)
	assert_eq(pending.first_meld_id, first)
	assert_true(FLOW.extension(owner).ok)
	assert_false(pending.matched)
	_judge(owner)
	assert_eq(owner.zodiac.progress.memory("horse", "horse.pace").result, "BROKEN")

func test_first_meld_extension_matches_in_same_turn_and_counteroffer_extends_deadline() -> void:
	for counter in [false, true]:
		var owner := FLOW.campaign("horse")
		FLOW.terms(owner, "horse.t1plus.pace")
		if counter: assert_true(owner.zodiac.respond("HAGGLE").requires_confirmation)
		assert_true(owner.zodiac.respond("ACCEPT").pending)
		owner.zodiac.continue_conversation()
		FLOW.afternoon(owner)
		assert_true(FLOW.meld(owner).ok)
		if counter: assert_true(owner.zodiac.deal.discard_card(FLOW.cards(owner.zodiac.deal.hand, [["K", "Clubs"]])[0]).ok)
		assert_true(FLOW.extension(owner).ok)
		assert_true(owner.zodiac.daily.promises[0].matched and not owner.zodiac.daily.promises[0].broken)

func test_scored_rank_collection_counts_distinct_new_cards_not_old_extension_ranks() -> void:
	var owner := FLOW.campaign("goat")
	var pending := FLOW.accept(owner, "goat.t1plus.notes")
	FLOW.afternoon(owner)
	var result := FLOW.first(owner)
	assert_true(result.ok)
	assert_eq(pending.scored_ranks, [7])
	owner.zodiac._observe_action(result)
	assert_eq(pending.scored_ranks, [7])
	assert_true(owner.zodiac.deal.extend_meld(result.meld_id, FLOW.cards(owner.zodiac.deal.hand, [["7", "Spades"]])).ok)
	assert_eq(pending.scored_ranks, [7])
	assert_false(pending.matched)
	assert_true(FLOW.next(owner).ok)
	assert_eq(pending.scored_ranks, [3, 4, 5, 7])
	assert_true(pending.matched)
	assert_true(FLOW.finish(owner))
	assert_eq(owner.zodiac.progress.memory("goat", "goat.notes").result, "FULFILLED")

func test_zero_points_and_discarded_ranks_do_not_count_as_scored_notes() -> void:
	var owner := FLOW.campaign("goat")
	var pending := FLOW.accept(owner, "goat.t1plus.notes")
	FLOW.afternoon(owner)
	owner.zodiac.deal.zodiac_boss.configure("rooster", ZodiacCatalog.UNPLEASED, 1)
	owner.zodiac.deal.zodiac_boss.mandatory_discard(1, 1)
	assert_eq(FLOW.meld(owner).context.final_points, 0)
	assert_true(pending.get("scored_ranks", []).is_empty())
	owner.zodiac.deal.zodiac_boss.configure()
	assert_true(FLOW.extension(owner).ok)
	assert_eq(pending.scored_ranks, [6])
	assert_true(owner.zodiac.deal.discard_card(FLOW.cards(owner.zodiac.deal.hand, [["9", "Hearts"]])[0]).ok)
	assert_eq(pending.scored_ranks, [6])

func test_consecutive_phrase_uses_newly_committed_printed_ranks_and_no_wrap() -> void:
	var owner := FLOW.campaign("goat")
	var pending := FLOW.accept(owner, "goat.t1plus.run")
	FLOW.afternoon(owner)
	assert_true(FLOW.first(owner).ok)
	assert_false(pending.matched)
	assert_true(FLOW.next(owner).ok)
	assert_true(pending.matched)
	var single := FLOW.campaign("goat")
	var phrase := FLOW.accept(single, "goat.t1plus.run")
	FLOW.afternoon(single)
	# Start before observation to test the new-card boundary separately.
	single.zodiac.begin_run_restore()
	assert_true(FLOW.meld(single).ok)
	single.zodiac.finish_run_restore()
	var extension := FLOW.extension(single)
	assert_true(extension.ok)
	assert_false(phrase.matched)
	var ranks: Array[int] = single.zodiac.persuasion._committed_ranks("extension", extension.context)
	assert_eq(ranks, [6])
	var wrap := ScoringContext.new()
	wrap.cards = FLOW.cards(single.gieo_que.persistent_deck, [["Q", "Hearts"], ["K", "Hearts"], ["A", "Hearts"]])
	assert_eq(single.zodiac.persuasion._committed_ranks("new_meld", wrap), [1, 12, 13])

func test_two_new_rank_extension_can_fulfill_the_explicit_phrase_counteroffer() -> void:
	var owner := FLOW.campaign("goat")
	FLOW.terms(owner, "goat.t1plus.run")
	assert_true(owner.zodiac.respond("HAGGLE").requires_confirmation)
	assert_eq(owner.zodiac.current_demand().rank_count, 2)
	assert_true(owner.zodiac.respond("ACCEPT").pending)
	owner.zodiac.continue_conversation()
	FLOW.afternoon(owner)
	owner.zodiac.begin_run_restore()
	assert_true(FLOW.meld(owner).ok)
	owner.zodiac.finish_run_restore()
	assert_true(owner.zodiac.deal.extend_meld(owner.zodiac.deal.melds[0].meld_id, FLOW.cards(owner.zodiac.deal.hand, [["6", "Hearts"], ["7", "Hearts"]])).ok)
	assert_true(owner.zodiac.daily.promises[0].matched)

func test_physical_choice_requires_horse_extension_or_goat_new_neighbor() -> void:
	for id: String in ["horse", "goat"]:
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

func test_new_meld_is_not_a_horse_extension_and_old_neighbors_do_not_fulfill_goat() -> void:
	var horse := FLOW.campaign("horse")
	var hchosen := _choose(horse)
	FLOW.chosen_deal(horse, hchosen)
	assert_true(horse.zodiac.deal.create_meld(horse.zodiac.deal.hand.slice(1, 4)).ok)
	assert_false(horse.zodiac.daily.promises[0].matched)
	assert_true(horse.zodiac.deal.extend_meld(horse.zodiac.deal.melds[0].meld_id, horse.zodiac.deal.hand.slice(0, 1)).ok)
	assert_false(horse.zodiac.daily.promises[0].matched)
	var goat := FLOW.campaign("goat")
	_choose(goat, [["6", "Hearts"], ["9", "Hearts"], ["K", "Clubs"]])
	FLOW.afternoon(goat)
	assert_true(FLOW.meld(goat).ok)
	assert_true(FLOW.extension(goat).ok)
	assert_false(goat.zodiac.daily.promises[0].matched)

func test_counteroffer_recall_freezes_exact_terms_while_permanent_memory_can_advance() -> void:
	for id: String in ["horse", "goat"]:
		var owner := FLOW.campaign(id)
		var key: String = "pair" if id == "horse" else "notes"
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
