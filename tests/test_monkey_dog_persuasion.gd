@tool
extends McpTestSuite
const FLOW := preload("res://tests/monkey_dog_test_flow.gd")
const NOON_FLOW := preload("res://tests/zodiac_test_flow.gd")

func suite_name() -> String:
	return "monkey_dog_persuasion"

func _judge(owner: CampaignManager) -> void:
	owner.zodiac.finish_daytime_deal("afternoon")
	owner._enter_phase(CampaignManager.CampaignPhase.AFTERNOON_EVENT)

func _choose(owner: CampaignManager, node_id: String, specs: Array = FLOW.OPENING.slice(0, 3)) -> String:
	FLOW.terms(owner, node_id)
	var offer := owner.zodiac.current_demand()
	offer.offered_ids = CardTargetQuery.physical_ids(FLOW.cards(owner.gieo_que.persistent_deck, specs))
	var chosen: String = offer.offered_ids[0]
	assert_true(owner.zodiac.persuasion.select_card(chosen))
	assert_false(owner.zodiac.respond("ACCEPT", ["not-offered"]).ok)
	assert_true(owner.zodiac.respond("ACCEPT", [chosen]).pending)
	assert_true(owner.zodiac.continue_conversation())
	return chosen

func test_bilingual_distinct_characters_contracts_and_kindred_content() -> void:
	for id: String in ["monkey", "dog"]:
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

func test_seeded_stranger_visit_blocks_completion_then_earns_familiar_on_return() -> void:
	for id: String in ["monkey", "dog"]:
		var owner := FLOW.campaign(id, false)
		var twin := FLOW.campaign(id, false)
		assert_eq(owner.zodiac.active_id(), id)
		assert_eq(owner.zodiac.persuasion.state().plan, twin.zodiac.persuasion.state().plan)
		assert_eq(owner.zodiac.persuasion.state().plan.size(), 3)
		assert_false(owner.complete_current_event())
		var before := owner.zodiac._rng.state
		owner.zodiac.enter_event(EventManager.EventSlot.NOON)
		owner.zodiac.quote()
		assert_eq(owner.zodiac._rng.state, before)
		assert_true(NOON_FLOW.finish_noon(owner.zodiac))
		assert_eq(owner.zodiac.progress.relationship_tier(id), ZodiacProgress.STRANGER)
		owner._enter_phase(CampaignManager.CampaignPhase.AFTERNOON_EVENT)
		assert_eq(owner.zodiac.progress.relationship_tier(id), ZodiacProgress.FAMILIAR)
		assert_eq(owner.zodiac.difficulty(), ZodiacCatalog.PLEASED)

func test_action_acceptance_and_refusal_are_free_and_acceptance_is_not_fulfillment() -> void:
	for id: String in ["monkey", "dog"]:
		var owner := FLOW.campaign(id)
		var node_id: String = id + ".t1plus." + ("variety" if id == "monkey" else "build")
		var before := owner.wallet.balance_vnd
		var deck := owner.gieo_que.persistent_deck.map(func(c: CardData): return c.permanent_snapshot())
		var promise := FLOW.accept(owner, node_id)
		assert_false(promise.started or promise.matched)
		assert_true(promise.target_ids.is_empty())
		assert_false(owner.zodiac.respond("ACCEPT").ok)
		assert_eq(owner.wallet.balance_vnd, before)
		assert_eq(owner.gieo_que.persistent_deck.map(func(c: CardData): return c.permanent_snapshot()), deck)
		var refused := FLOW.campaign(id)
		FLOW.terms(refused, node_id)
		assert_true(refused.zodiac.respond("REFUSE").ok)
		assert_eq(refused.zodiac.persuasion.state().patience, 3)
		assert_true(refused.zodiac.daily.promises.is_empty())

func test_counteroffer_confirmation_is_explicit_frozen_and_remembers_the_alternative() -> void:
	for id: String in ["monkey", "dog"]:
		var owner := FLOW.campaign(id)
		FLOW.terms(owner, id + ".t1plus." + ("variety" if id == "monkey" else "build"))
		var service := owner.zodiac
		var token := service.offer_token()
		var balance := owner.wallet.balance_vnd
		assert_true(service.respond("HAGGLE", [], token).requires_confirmation)
		assert_eq(service.current_demand().condition, "do_action")
		assert_eq(service.current_demand().action, "extension")
		assert_eq(service.current_demand().deal_phase, 0)
		assert_false(service.respond("ACCEPT", [], token).ok)
		var rng := service._rng.state
		assert_false(service.respond("HAGGLE").ok)
		assert_eq(service._rng.state, rng)
		assert_eq(owner.wallet.balance_vnd, balance)
		assert_true(service.respond("REFUSE").ok)
		var topic: String = "monkey.extension" if id == "monkey" else "dog.build"
		var memory := service.progress.memory(id, topic)
		assert_eq(memory.result, "REFUSED")
		assert_true(memory.counteroffer and memory.commitment_en.contains("either Phase"))

func test_variety_uses_two_real_paid_action_kinds_and_waits_for_completed_afternoon() -> void:
	var owner := FLOW.campaign("monkey")
	var promise := FLOW.accept(owner, "monkey.t1plus.variety")
	FLOW.afternoon(owner)
	assert_true(FLOW.meld(owner).ok)
	assert_false(promise.matched)
	var extension := FLOW.extension(owner)
	assert_true(extension.ok)
	assert_true(promise.matched)
	var observations: Dictionary = promise.observations.duplicate(true)
	owner.zodiac._observe_action(extension)
	assert_eq(promise.observations, observations)
	owner.zodiac.persuasion.judge()
	assert_false(owner.zodiac.persuasion.state().judged)
	assert_true(FLOW.finish(owner))
	assert_eq(owner.zodiac.progress.memory("monkey", "monkey.variety").result, "FULFILLED")
	var count: int = owner.zodiac.progress.record("monkey").promises_kept
	owner.zodiac.enter_event(EventManager.EventSlot.AFTERNOON)
	assert_eq(owner.zodiac.progress.record("monkey").promises_kept, count)

func test_variety_ignores_zero_point_actions_but_allows_reverse_paid_order() -> void:
	var owner := FLOW.campaign("monkey")
	var promise := FLOW.accept(owner, "monkey.t1plus.variety")
	FLOW.afternoon(owner)
	var deal := owner.zodiac.deal
	deal.zodiac_boss.configure("rooster", ZodiacCatalog.UNPLEASED, 1)
	deal.zodiac_boss.mandatory_discard(1, 1)
	assert_eq(FLOW.meld(owner).context.final_points, 0)
	assert_true(promise.get("paid_actions", []).is_empty())
	deal.zodiac_boss.configure()
	assert_true(FLOW.extension(owner).ok)
	assert_eq(promise.paid_actions, ["extension"])
	assert_false(promise.matched)
	assert_true(deal.create_meld(FLOW.cards(deal.hand, FLOW.OPENING.slice(4, 7))).ok)
	assert_true(promise.matched)
	assert_eq(promise.paid_actions, ["extension", "new_meld"])

func test_single_action_kind_and_an_absent_chosen_card_are_broken() -> void:
	var owner := FLOW.campaign("monkey")
	FLOW.accept(owner, "monkey.t1plus.variety")
	FLOW.afternoon(owner)
	assert_true(FLOW.meld(owner).ok)
	_judge(owner)
	assert_eq(owner.zodiac.progress.memory("monkey", "monkey.variety").result, "BROKEN")
	var picked := FLOW.campaign("monkey")
	var chosen := _choose(picked, "monkey.t1plus.pick", [["K", "Clubs"], ["9", "Hearts"], ["7", "Spades"]])
	FLOW.afternoon(picked)
	var card: CardData = CardTargetQuery.resolve_ids(picked.zodiac.deal.hand, [chosen])[0]
	assert_true(picked.zodiac.deal.discard_card(card).ok)
	assert_false(picked.zodiac.daily.promises[0].matched)
	_judge(picked)
	assert_eq(picked.zodiac.progress.memory("monkey", "monkey.pick").result, "BROKEN")

func test_chosen_physical_card_counts_only_when_committed_into_a_meld() -> void:
	var owner := FLOW.campaign("monkey")
	var chosen := _choose(owner, "monkey.t1plus.pick")
	FLOW.afternoon(owner)
	var promise: Dictionary = owner.zodiac.daily.promises[0]
	var cards := FLOW.cards(owner.zodiac.deal.hand, FLOW.OPENING.slice(0, 3))
	assert_false(owner.zodiac.deal.preview_new_meld_payout(cards, MeldRules.TYPE_RUN).is_empty())
	assert_false(promise.matched)
	assert_true(FLOW.meld(owner).ok)
	assert_true(promise.matched)
	_judge(owner)
	assert_eq(owner.zodiac.progress.memory("monkey", "monkey.pick").target_id, chosen)

func test_extension_counts_added_card_and_not_preexisting_cards_in_context() -> void:
	var owner := FLOW.campaign("monkey")
	_choose(owner, "monkey.t1plus.pick")
	FLOW.afternoon(owner)
	owner.zodiac.begin_run_restore()
	assert_true(FLOW.meld(owner).ok)
	owner.zodiac.finish_run_restore()
	assert_true(FLOW.extension(owner).ok)
	assert_false(owner.zodiac.daily.promises[0].matched)
	var other := FLOW.campaign("monkey")
	_choose(other, "monkey.t1plus.pick", [["6", "Hearts"], ["K", "Clubs"], ["9", "Hearts"]])
	FLOW.afternoon(other)
	assert_true(FLOW.meld(other).ok)
	assert_false(other.zodiac.daily.promises[0].matched)
	assert_true(FLOW.extension(other).ok)
	assert_true(other.zodiac.daily.promises[0].matched)

func test_dog_tracks_first_meld_identity_and_rejects_extensions_to_other_melds() -> void:
	var owner := FLOW.campaign("dog")
	var promise := FLOW.accept(owner, "dog.t1plus.build")
	FLOW.afternoon(owner)
	var first := FLOW.meld(owner)
	var second := owner.zodiac.deal.create_meld(FLOW.cards(owner.zodiac.deal.hand, FLOW.OPENING.slice(4, 7)))
	assert_eq(promise.first_meld_id, first.meld_id)
	assert_true(owner.zodiac.deal.extend_meld(second.meld_id, FLOW.cards(owner.zodiac.deal.hand, [["7", "Spades"]])).ok)
	assert_false(promise.matched)
	assert_true(FLOW.extension(owner, first.meld_id).ok)
	assert_true(promise.matched)
	assert_true(owner.zodiac.deal.physical_card_accounting_is_valid())
	_judge(owner)
	assert_eq(owner.zodiac.progress.memory("dog", "dog.build").result, "FULFILLED")

func test_dog_phase_two_cannot_rescue_phase_one_contract() -> void:
	var owner := FLOW.campaign("dog")
	var promise := FLOW.accept(owner, "dog.t1plus.build")
	FLOW.afternoon(owner)
	assert_true(FLOW.meld(owner).ok)
	var deal := owner.zodiac.deal
	deal.set_current_drink(DrinkCatalog.BAC_XIU)
	while deal.state == DealState.STATE_ACTIVE:
		var discard: CardData = deal.hand.filter(func(c: CardData): return c.rank != "6" or c.suit != "Hearts")[-1]
		assert_true(deal.discard_card(discard).ok)
	assert_true(deal.settle_phase().ok)
	assert_true(deal.select_sam_dua_preserves(deal.hand).ok)
	assert_true(deal.choose_phase_two(false).ok)
	assert_eq(deal.current_phase, 2)
	assert_true(FLOW.extension(owner).ok)
	assert_false(promise.matched)
	_judge(owner)
	assert_eq(owner.zodiac.progress.memory("dog", "dog.build").result, "BROKEN")

func test_dog_card_can_be_played_but_permanent_change_and_change_back_still_break() -> void:
	var owner := FLOW.campaign("dog")
	_choose(owner, "dog.t1plus.card")
	FLOW.afternoon(owner)
	assert_true(FLOW.meld(owner).ok)
	assert_false(owner.zodiac.daily.promises[0].broken)
	_judge(owner)
	assert_eq(owner.zodiac.progress.memory("dog", "dog.card").result, "FULFILLED")
	var altered := FLOW.campaign("dog")
	var chosen := _choose(altered, "dog.t1plus.card")
	var card: CardData = CardTargetQuery.resolve_ids(altered.gieo_que.persistent_deck, [chosen])[0]
	var original := card.rank
	var original_index := card.rank_index
	card.apply_rank("Q", 12)
	card.apply_rank(original, original_index)
	assert_true(altered.zodiac.daily.promises[0].broken)
	FLOW.afternoon(altered)
	_judge(altered)
	assert_eq(altered.zodiac.progress.memory("dog", "dog.card").result, "BROKEN")

func test_dog_relic_eligibility_counteroffer_and_loss_regain() -> void:
	var owner := FLOW.campaign("dog")
	var relic_node: Dictionary = ZodiacCatalog.persuasion_nodes("dog").filter(func(n: Dictionary): return n.id == "dog.t1plus.relic")[0]
	assert_false(owner.zodiac.persuasion._eligible(relic_node))
	owner.relic_shop.runtime.acquire("toothpicks")
	owner.relic_shop.runtime.acquire("sunflower_seeds")
	FLOW.terms(owner, "dog.t1plus.relic")
	var original: String = owner.zodiac.current_demand().relic_id
	assert_true(owner.zodiac.respond("HAGGLE").ok)
	var chosen: String = owner.zodiac.current_demand().relic_id
	assert_true(chosen != original)
	assert_true(owner.zodiac.respond("ACCEPT").pending)
	assert_true(owner.relic_shop.runtime.gift(chosen))
	assert_true(owner.relic_shop.runtime.acquire(chosen))
	assert_true(owner.zodiac.daily.promises[0].broken)
	FLOW.afternoon(owner)
	_judge(owner)
	assert_eq(owner.zodiac.progress.memory("dog", "dog.relic").relic_id, chosen)
	assert_eq(owner.zodiac.progress.memory("dog", "dog.relic").result, "BROKEN")

func test_relationship_needs_varied_kept_promises_and_is_separate_for_each_boss() -> void:
	for id: String in ["monkey", "dog"]:
		var progress := ZodiacProgress.new("")
		progress.record_disposition(id, "familiar", "PLEASED")
		var topics: Array = ZodiacCatalog.persuasion_config(id).progression[0].promises
		progress.commit(id, "repeated", {"promises_kept": 3, "promise_kept:" + topics[0]: 3})
		progress.record_disposition(id, "not-enough-variety", "PLEASED")
		assert_eq(progress.relationship_tier(id), ZodiacProgress.FAMILIAR)
		progress.commit(id, "varied", {"promises_kept": 1, "promise_kept:" + topics[1]: 1})
		progress.record_disposition(id, "unpleased", "UNPLEASED")
		assert_eq(progress.relationship_tier(id), ZodiacProgress.FAMILIAR)
		assert_true(progress.record_disposition(id, "kindred", "NORMAL"))
		assert_eq(progress.relationship_tier(id), ZodiacProgress.KINDRED)
		assert_false(progress.record_disposition(id, "kindred", "NORMAL"))
		assert_eq(progress.record(id).kindred_transitions, 1)
		assert_eq(progress.relationship_tier("dog" if id == "monkey" else "monkey"), ZodiacProgress.STRANGER)

func test_recall_requires_real_memory_and_freezes_the_bound_result_across_restore() -> void:
	for id: String in ["monkey", "dog"]:
		var owner := FLOW.campaign(id)
		var node_id: String = id + ".t2." + ("variety_memory" if id == "monkey" else "build_memory")
		var node: Dictionary = ZodiacCatalog.persuasion_nodes(id).filter(func(n: Dictionary): return n.id == node_id)[0]
		assert_false(owner.zodiac.persuasion._eligible(node))
		owner.zodiac.progress.commit(id, "kindred-fixture", {"promises_kept": 3,
			"promise_kept:" + node.promise.id: 2, "promise_kept:" + ZodiacCatalog.persuasion_config(id).progression[0].promises[1]: 1})
		owner.zodiac.progress.record_disposition(id, "kindred-visit", "NORMAL")
		owner.zodiac.progress.remember(id, "past", node.memory_key, {"result": "BROKEN", "target_label": "", "target_id": "", "relic_id": "",
			"node_id": node.id, "counteroffer": false, "commitment_en": node.promise.en, "commitment_vi": node.promise.vi})
		assert_true(owner.zodiac.persuasion._eligible(node))
		FLOW.node(owner, node_id)
		var quote: String = owner.zodiac.quote().speech
		var old := owner.zodiac.snapshot()
		owner.zodiac.progress.remember(id, "newer", node.memory_key, {"result": "FULFILLED", "target_label": "", "node_id": node.id})
		owner.zodiac.restore(old)
		assert_eq(owner.zodiac.quote().speech, quote)
		assert_eq(owner.zodiac.persuasion.state().node.bound_memory.result, "BROKEN")
		assert_eq(owner.zodiac.progress.memory(id, node.memory_key).result, "FULFILLED")
		assert_false(owner.zodiac.quote().speech.contains("{target}"))

func test_authored_last_chance_recovery_is_once_and_second_zero_locks_visit() -> void:
	for id: String in ["monkey", "dog"]:
		var owner := FLOW.campaign(id, false)
		owner.zodiac.persuasion.apply_patience(-3)
		var token := owner.zodiac.offer_token()
		assert_eq(owner.zodiac.persuasion.state().stage, "last_chance")
		assert_true(owner.zodiac.persuasion.resolve_last_chance("B", token))
		assert_eq(owner.zodiac.persuasion.state().patience, 1)
		assert_false(owner.zodiac.persuasion.resolve_last_chance("B", token))
		owner.zodiac.persuasion.apply_patience(-1)
		assert_true(owner.zodiac.persuasion.state().interaction_locked)
		owner._enter_phase(CampaignManager.CampaignPhase.AFTERNOON_EVENT)
		assert_eq(owner.zodiac.mood(), "UNPLEASED")
		var declined := FLOW.campaign(id, false)
		declined.zodiac.persuasion.apply_patience(-3)
		assert_true(declined.zodiac.persuasion.resolve_last_chance("C"))
		assert_false(declined.zodiac.has_open_interaction())

func test_v4_started_empty_visits_preserve_old_mood_while_pre_noon_saves_upgrade() -> void:
	for id: String in ["monkey", "dog"]:
		var owner := FLOW.campaign(id, false)
		var old := owner.zodiac.snapshot()
		old.version = 4
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
		old.daily.slot = EventManager.EventSlot.AFTERNOON
		owner.zodiac.restore(old)
		owner.zodiac.begin_day(1, owner.seed_for("zodiac_selection", 1))
		assert_true(owner.zodiac.uses_persuasion())
		assert_false(owner.zodiac.daily.get("legacy_negotiation", false))

func test_emblem_story_and_legacy_routes_require_reencounter_and_keep_pair_preference() -> void:
	for id: String in ["monkey", "dog"]:
		var owner := FLOW.campaign(id)
		var progress := owner.zodiac.progress
		var topics: Array = ZodiacCatalog.persuasion_config(id).progression[0].promises
		progress.commit(id, "story", {"promises_kept": 3, "promise_kept:" + topics[0]: 2, "promise_kept:" + topics[1]: 1, "pleased_victories": 1})
		progress.record_disposition(id, "kindred", "NORMAL")
		assert_false(progress.eligible(id))
		progress.commit(id, "honest-no", {"promises_refused": 1})
		assert_true(progress.eligible(id))
		assert_false(owner.zodiac.complete_scene())
		owner.zodiac.begin_day(1, owner.seed_for("zodiac_selection", 1))
		assert_true(progress.record(id).special_scene_unlocked)
		assert_true(owner.zodiac.complete_scene())
		assert_false(owner.zodiac.complete_scene())
		assert_true(owner.zodiac.prefer_emblem(id))
		owner.zodiac.begin_day(8, owner.seed_for("zodiac_selection", 8))
		assert_eq(owner.zodiac.active_id(), id)
		var legacy := ZodiacProgress.new("")
		legacy.commit(id, "earned-before-expansion", {"requests_resolved": 4, "pleased_victories": 1})
		assert_true(legacy.eligible(id))
