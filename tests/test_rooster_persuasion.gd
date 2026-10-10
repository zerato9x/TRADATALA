@tool
extends McpTestSuite
const FLOW := preload("res://tests/zodiac_test_flow.gd")

func suite_name() -> String:
	return "rooster_persuasion"

func _campaign(familiar: bool = false) -> CampaignManager:
	var deal := DealState.new()
	var events := EventManager.new()
	CampaignNpcCatalog.register_initial_npcs(events)
	var campaign := CampaignManager.new(deal.wallet, events)
	campaign.zodiac.bind(campaign, deal)
	campaign.relic_shop.runtime = deal.relics
	campaign.zodiac.progress = ZodiacProgress.new("")
	if familiar: campaign.zodiac.progress.record_disposition("rooster", "fixture:familiar", "PLEASED")
	var seed_text := ""
	for index in 100:
		campaign.run_seed = "ROOSTER-PERSUASION-%d" % index
		if ZodiacCatalog.select(campaign.seed_for("zodiac_selection", 0), 0) == "rooster":
			seed_text = campaign.run_seed
			break
	campaign.start_campaign(true, seed_text)
	assert_eq(campaign.zodiac.active_id(), "rooster")
	campaign._enter_phase(CampaignManager.CampaignPhase.NOON_EVENT)
	return campaign

func _node(campaign: CampaignManager, id: String) -> void:
	for node: Dictionary in ZodiacCatalog.persuasion_nodes("rooster"):
		if node.id != id: continue
		assert_true(campaign.zodiac.persuasion._eligible(node))
		var visit := campaign.zodiac.persuasion.state()
		visit.plan = [node]
		visit.cursor = 0
		campaign.zodiac.persuasion._open_node()
		return
	assert_true(false, "Missing Rooster content " + id)

func _terms(campaign: CampaignManager, id: String = "rooster.t1plus.before_bell") -> void:
	_node(campaign, id)
	assert_true(campaign.zodiac.answer_question("B").ok)
	assert_true(campaign.zodiac.continue_conversation())
	assert_true(campaign.zodiac.has_open_demand())

func _accept(campaign: CampaignManager, id: String = "rooster.t1plus.before_bell") -> Dictionary:
	_terms(campaign, id)
	assert_true(campaign.zodiac.respond("ACCEPT").pending)
	assert_true(campaign.zodiac.continue_conversation())
	return campaign.zodiac.daily.promises[-1]

func _afternoon(campaign: CampaignManager) -> void:
	campaign._enter_phase(CampaignManager.CampaignPhase.AFTERNOON_DEAL)
	campaign.zodiac.deal.start_tutorial_deal()

func _judge(campaign: CampaignManager) -> void:
	campaign.zodiac.finish_daytime_deal("afternoon")
	campaign._enter_phase(CampaignManager.CampaignPhase.AFTERNOON_EVENT)

func _phase_two(deal: DealState) -> void:
	deal.set_current_drink(DrinkCatalog.BAC_XIU)
	while deal.state == DealState.STATE_ACTIVE:
		var card: CardData = deal.hand.filter(func(item: CardData): return not (item.rank == "7" and item.suit == "Hearts"))[-1]
		assert_true(deal.discard_card(card).ok)
	assert_eq(deal.state, DealState.STATE_FINAL_COMMIT_WINDOW)
	assert_true(deal.settle_phase().ok)
	assert_true(deal.select_sam_dua_preserves(deal.hand).ok)
	assert_true(deal.choose_phase_two(false).ok)
	assert_eq(deal.current_phase, 2)

func test_authored_roster_bilingual_contracts_and_inherited_kindred_nodes() -> void:
	var nodes := ZodiacCatalog.persuasion_nodes("rooster")
	assert_eq(nodes.size(), 12)
	var seen := {}
	for node: Dictionary in nodes:
		assert_false(seen.has(node.id))
		seen[node.id] = true
		assert_eq(node.answers.map(func(answer: Dictionary): return answer.id), ["A", "B", "C"])
		for answer: Dictionary in node.answers:
			assert_true(not answer.en.is_empty() and not answer.vi.is_empty())
			assert_true(int(answer.delta) in [-1, 0, 1])
			assert_false(answer.has("traits"))
		if node.has("promise"):
			assert_eq(node.promise.target_kind, "ACTION")
			assert_eq(node.promise.polarity, "DO")
			assert_true(node.responses.has("COUNTER_REFUSE"))
			assert_eq(node.responses.REFUSE.delta, 0)
			assert_eq(node.responses.HAGGLE.delta, 0)
			assert_true(node.outcomes.has("FULFILLED") and node.outcomes.has("BROKEN"))
	assert_eq(ZodiacCatalog.persuasion_nodes("cat").size(), 12)
	assert_true(ZodiacCatalog.persuasion_nodes("dog").is_empty())

func test_fresh_noon_is_seeded_authored_and_blocks_event_completion() -> void:
	var first := _campaign()
	var second := _campaign()
	assert_true(first.zodiac.uses_persuasion())
	assert_true(first.zodiac.negotiation().is_empty())
	assert_eq(first.zodiac.persuasion.state().plan, second.zodiac.persuasion.state().plan)
	assert_eq(first.zodiac._rng.state, second.zodiac._rng.state)
	assert_eq(first.zodiac.persuasion.state().plan.size(), 3)
	assert_false(first.complete_current_event())
	var rng := first.zodiac._rng.state
	first.zodiac.quote()
	first.zodiac.enter_event(EventManager.EventSlot.NOON)
	assert_eq(first.zodiac._rng.state, rng)
	assert_true(FLOW.finish_noon(first.zodiac))
	assert_eq(first.zodiac.persuasion.state().patience, 5)
	first._enter_phase(CampaignManager.CampaignPhase.AFTERNOON_EVENT)
	assert_eq(first.zodiac.progress.relationship_tier("rooster"), ZodiacProgress.FAMILIAR)

func test_action_terms_need_no_card_target_and_do_not_mutate_resources() -> void:
	var campaign := _campaign(true)
	var before := campaign.wallet.balance_vnd
	var cards := campaign.gieo_que.persistent_deck.map(func(card: CardData): return card.permanent_snapshot())
	var promise := _accept(campaign)
	assert_true(promise.target_ids.is_empty() and promise.relic_id.is_empty())
	assert_false(promise.started or promise.matched)
	assert_eq(campaign.wallet.balance_vnd, before)
	assert_eq(campaign.gieo_que.persistent_deck.map(func(card: CardData): return card.permanent_snapshot()), cards)
	assert_false(campaign.zodiac.respond("ACCEPT").ok)
	assert_eq(campaign.zodiac.daily.promises.size(), 1)

func test_counteroffer_freezes_new_deadline_and_requires_confirmation() -> void:
	var campaign := _campaign(true)
	_terms(campaign)
	var service := campaign.zodiac
	var token := service.offer_token()
	var before := campaign.wallet.balance_vnd
	var patience := int(service.persuasion.state().patience)
	assert_true(service.respond("HAGGLE", [], token).requires_confirmation)
	assert_eq(service.current_demand().id, "rooster.first_meld")
	assert_eq(service.current_demand().deal_phase, 1)
	assert_true(service.daily.promises.is_empty())
	assert_eq(service.persuasion.state().patience, patience)
	assert_false(service.respond("ACCEPT", [], token).ok)
	var rng := service._rng.state
	assert_false(service.respond("HAGGLE").ok)
	assert_eq(service._rng.state, rng)
	assert_eq(campaign.wallet.balance_vnd, before)
	assert_true(service.respond("ACCEPT").pending)
	assert_eq(service.daily.promises[0].semantic_id, "rooster.first_meld")
	assert_true(service.daily.promises[0].memory_details.counteroffer)
	assert_true(service.daily.promises[0].accepted_terms.en.contains("Phase 1"))

func test_counteroffer_refusal_records_exact_terms_without_patience_tax() -> void:
	var campaign := _campaign(true)
	_terms(campaign, "rooster.t1plus.first_job")
	assert_true(campaign.zodiac.respond("HAGGLE").ok)
	var patience := int(campaign.zodiac.persuasion.state().patience)
	assert_true(campaign.zodiac.respond("REFUSE").ok)
	assert_eq(campaign.zodiac.persuasion.state().patience, patience)
	assert_true(campaign.zodiac.daily.promises.is_empty())
	var entry := campaign.zodiac.progress.memory("rooster", "rooster.extension")
	assert_eq(entry.result, "REFUSED")
	assert_true(entry.counteroffer)
	assert_true(entry.commitment_en.contains("either Phase"))
	assert_true(campaign.zodiac.quote().speech.contains("can't commit to that either"))
	assert_true(campaign.zodiac.progress.memory("rooster", "rooster.first_meld").is_empty())

func test_positive_score_observed_from_real_commit_and_judged_once() -> void:
	var campaign := _campaign(true)
	var promise := _accept(campaign)
	_afternoon(campaign)
	var patience := int(campaign.zodiac.persuasion.state().patience)
	var deal := campaign.zodiac.deal
	var result := deal.create_meld(deal.hand.slice(0, 3))
	assert_true(result.ok and result.context.final_points > 0)
	assert_true(promise.matched)
	assert_eq(campaign.zodiac.persuasion.state().patience, patience)
	assert_true(campaign.zodiac.progress.memory("rooster", "rooster.early_score").is_empty())
	var observations: Dictionary = promise.observations.duplicate(true)
	campaign.zodiac._observe_action(result)
	assert_eq(promise.observations, observations)
	_judge(campaign)
	assert_eq(campaign.zodiac.progress.memory("rooster", "rooster.early_score").result, "FULFILLED")
	assert_eq(campaign.zodiac.progress.record("rooster").promises_kept, 1)
	assert_eq(campaign.zodiac.mood(), "PLEASED")
	campaign.zodiac.enter_event(EventManager.EventSlot.AFTERNOON)
	assert_eq(campaign.zodiac.progress.record("rooster").promises_kept, 1)

func test_first_mandatory_discard_closes_early_score_even_if_later_paid() -> void:
	var campaign := _campaign(true)
	var promise := _accept(campaign)
	_afternoon(campaign)
	var deal := campaign.zodiac.deal
	assert_true(deal.discard_card(deal.hand[-1]).ok)
	assert_true(promise.broken and not promise.matched)
	assert_true(deal.create_meld(deal.hand.slice(0, 3)).context.final_points > 0)
	assert_false(promise.matched)
	_judge(campaign)
	assert_eq(campaign.zodiac.progress.memory("rooster", "rooster.early_score").result, "BROKEN")
	assert_eq(campaign.zodiac.progress.record("rooster").promises_broken, 1)
	assert_eq(campaign.zodiac.mood(), "NORMAL")

func test_zero_points_do_not_count_as_early_score_and_phase_two_cannot_rescue() -> void:
	var campaign := _campaign(true)
	var promise := _accept(campaign)
	_afternoon(campaign)
	var deal := campaign.zodiac.deal
	# Force a real suppression receipt; theoretical points alone must not fulfill.
	deal.zodiac_boss.configure("rooster", ZodiacCatalog.UNPLEASED, 1)
	deal.zodiac_boss.mandatory_discard(1, 1)
	var result := deal.create_meld(deal.hand.slice(0, 3))
	assert_true(result.ok)
	assert_eq(result.context.final_points, 0)
	assert_false(promise.matched)
	deal.zodiac_boss.configure() # Restore the normal Afternoon rules after the zero receipt.
	_phase_two(deal)
	assert_true(deal.create_meld(deal.hand.slice(0, 3)).ok)
	assert_false(promise.matched)
	_judge(campaign)
	assert_eq(campaign.zodiac.progress.memory("rooster", "rooster.early_score").result, "BROKEN")

func test_optional_discard_does_not_close_early_score_deadline() -> void:
	var campaign := _campaign(true)
	var promise := _accept(campaign)
	_afternoon(campaign)
	var deal := campaign.zodiac.deal
	deal.set_current_drink(DrinkCatalog.TRA_DA)
	deal.tra_da_extra_discard_pending = true
	assert_eq(deal.discard_card(deal.hand[-1]).discard_kind, DiscardRecord.KIND_DRINK_EXTRA)
	assert_eq(deal.discard_count, 0)
	assert_false(promise.broken)
	assert_true(deal.create_meld(deal.hand.slice(0, 3)).ok)
	assert_true(promise.matched)
	_judge(campaign)
	assert_eq(campaign.zodiac.progress.record("rooster").promises_kept, 1)

func test_new_meld_promise_does_not_accept_phase_two_meld() -> void:
	var campaign := _campaign(true)
	var promise := _accept(campaign, "rooster.t1plus.first_job")
	_afternoon(campaign)
	var deal := campaign.zodiac.deal
	_phase_two(deal)
	assert_true(deal.create_meld(deal.hand.slice(0, 3)).ok)
	assert_false(promise.matched)
	_judge(campaign)
	assert_eq(campaign.zodiac.progress.memory("rooster", "rooster.first_meld").result, "BROKEN")

func test_extension_promise_accepts_real_phase_two_extension_and_ignores_failure() -> void:
	var campaign := _campaign(true)
	var promise := _accept(campaign, "rooster.t1plus.finish_work")
	_afternoon(campaign)
	var deal := campaign.zodiac.deal
	assert_false(deal.extend_meld(-1, deal.hand.slice(0, 1)).ok)
	assert_false(promise.matched)
	assert_true(deal.create_meld(deal.hand.slice(0, 3)).ok)
	_phase_two(deal)
	var card: CardData = deal.hand.filter(func(item: CardData): return item.rank == "7" and item.suit == "Hearts")[0]
	assert_true(deal.extend_meld(deal.melds[0].meld_id, [card]).ok)
	assert_true(promise.matched)
	assert_true(deal.physical_card_accounting_is_valid())
	_judge(campaign)
	assert_eq(campaign.zodiac.progress.memory("rooster", "rooster.extension").result, "FULFILLED")

func test_missing_action_is_broken_and_other_periods_do_not_fulfill() -> void:
	var campaign := _campaign(true)
	var promise := _accept(campaign, "rooster.t1plus.first_job")
	campaign._enter_phase(CampaignManager.CampaignPhase.MORNING_DEAL)
	var deal := campaign.zodiac.deal
	deal.start_tutorial_deal()
	assert_true(deal.create_meld(deal.hand.slice(0, 3)).ok)
	assert_false(promise.started or promise.matched)
	_afternoon(campaign)
	campaign.zodiac.begin_run_restore()
	assert_true(deal.create_meld(deal.hand.slice(0, 3)).ok)
	campaign.zodiac.finish_run_restore()
	assert_false(promise.matched)
	_judge(campaign)
	assert_eq(campaign.zodiac.progress.memory("rooster", "rooster.first_meld").result, "BROKEN")

func test_judgement_waits_for_completed_deal_and_persists_mid_commit() -> void:
	var campaign := _campaign(true)
	var promise := _accept(campaign)
	_afternoon(campaign)
	var deal := campaign.zodiac.deal
	assert_true(deal.create_meld(deal.hand.slice(0, 3)).ok)
	campaign.zodiac.persuasion.judge()
	assert_false(campaign.zodiac.persuasion.state().judged)
	assert_false(promise.outcome_applied)
	var save := RunSave.new("user://rooster_core.save")
	assert_true(save.save_run(campaign, deal))
	var loaded := _campaign()
	assert_true(save.restore(save.load_run(), loaded, loaded.zodiac.deal))
	assert_true(loaded.zodiac.uses_persuasion())
	assert_true(loaded.zodiac.daily.promises[0].matched)
	assert_eq(loaded.zodiac._rng.state, campaign.zodiac._rng.state)
	_judge(loaded)
	assert_eq(loaded.zodiac.progress.record("rooster").promises_kept, 1)
	for suffix in ["", ".bak", ".tmp"]: DirAccess.remove_absolute(save.path + suffix)

func test_kindred_requires_varied_kept_commitments_and_good_return() -> void:
	var progress := ZodiacProgress.new("")
	progress.record_disposition("rooster", "familiar", "PLEASED")
	progress.commit("rooster", "repeat", {"promises_kept": 3, "promise_kept:rooster.early_score": 3})
	progress.record_disposition("rooster", "same-kind", "NORMAL")
	assert_eq(progress.relationship_tier("rooster"), ZodiacProgress.FAMILIAR)
	progress.commit("rooster", "varied", {"promises_kept": 1, "promise_kept:rooster.extension": 1})
	progress.record_disposition("rooster", "bad-return", "UNPLEASED")
	assert_eq(progress.relationship_tier("rooster"), ZodiacProgress.FAMILIAR)
	progress.record_disposition("rooster", "good-return", "NORMAL")
	assert_eq(progress.relationship_tier("rooster"), ZodiacProgress.KINDRED)
	assert_eq(progress.promise_kinds("rooster"), 2)
	assert_eq(progress.record("rooster").kindred_transitions, 1)
	progress.record_disposition("rooster", "good-return", "NORMAL")
	assert_eq(progress.record("rooster").kindred_transitions, 1)

func test_memory_nodes_require_real_topic_and_freeze_the_recalled_result() -> void:
	var campaign := _campaign(true)
	var service := campaign.zodiac
	service.progress.records.rooster.relationship_tier = ZodiacProgress.KINDRED
	var memory_node: Dictionary = ZodiacCatalog.persuasion_nodes("rooster").filter(func(node: Dictionary): return node.id == "rooster.t2.bell_memory")[0]
	assert_false(service.persuasion._eligible(memory_node))
	var details := {"result": "BROKEN", "node_id": "rooster.t1plus.before_bell", "target_id": "", "target_label": "", "relic_id": "", "counteroffer": false,
		"commitment_en": ZodiacCatalog.ROOSTER_PERSUASION.EARLY_SCORE.en, "commitment_vi": ZodiacCatalog.ROOSTER_PERSUASION.EARLY_SCORE.vi}
	service.progress.remember("rooster", "memory:broken", "rooster.early_score", details)
	assert_true(service.persuasion._eligible(memory_node))
	_node(campaign, memory_node.id)
	var frozen: Dictionary = service.persuasion.state().node.duplicate(true)
	details.result = "FULFILLED"
	service.progress.remember("rooster", "memory:kept", "rooster.early_score", details)
	assert_eq(service.persuasion.state().node, frozen)
	assert_true(service.quote().speech.contains("The discard came first"))
	var checkpoint := service.snapshot()
	service.restore(checkpoint)
	assert_eq(service.persuasion.state().node, frozen)
	assert_eq(service.progress.memory("rooster", "rooster.early_score").result, "FULFILLED")

func test_last_chance_recovers_once_then_second_zero_ends_visit() -> void:
	var campaign := _campaign()
	var engine := campaign.zodiac.persuasion
	engine.apply_patience(-3)
	assert_eq(engine.state().stage, "last_chance")
	assert_true(engine.resolve_last_chance("C"))
	assert_eq(engine.state().patience, 1)
	assert_true(engine.state().last_chance_consumed)
	engine.apply_patience(-1)
	assert_true(engine.state().interaction_locked)
	assert_false(engine.resolve_last_chance("A"))
	assert_false(campaign.zodiac.answer_question("A").ok)
	campaign._enter_phase(CampaignManager.CampaignPhase.AFTERNOON_EVENT)
	assert_eq(campaign.zodiac.mood(), "UNPLEASED")

func test_v3_saved_demand_finishes_original_terms_and_pre_noon_upgrades() -> void:
	var campaign := _campaign()
	var service := campaign.zodiac
	service.daily.erase("persuasion")
	service.daily["legacy_negotiation"] = true
	service._begin_negotiation()
	service.debug_offer(ZodiacDemand.make("PAY", "ANY", "PLAYER_CHOOSES", 1, "", 5000))
	var old := service.snapshot()
	old.version = 3
	old.daily.erase("legacy_negotiation")
	var loaded := _campaign()
	loaded.zodiac.restore(old)
	assert_false(loaded.zodiac.uses_persuasion())
	assert_eq(loaded.zodiac.current_demand(), service.current_demand())
	var before := loaded.wallet.balance_vnd
	assert_true(loaded.zodiac.respond("ACCEPT").ok)
	assert_eq(loaded.wallet.balance_vnd, before - 5000)
	assert_false(loaded.zodiac.respond("ACCEPT", [], service.offer_token()).ok)
	assert_eq(loaded.wallet.balance_vnd, before - 5000)
	old.daily.erase("negotiation")
	old.daily.promises = []
	loaded.zodiac.restore(old)
	assert_true(loaded.zodiac.uses_persuasion())
	loaded.zodiac.enter_event(EventManager.EventSlot.NOON)
	assert_true(loaded.zodiac.has_open_question())

func test_new_emblem_route_requires_kindred_refusal_victory_and_reencounter() -> void:
	var campaign := _campaign(true)
	var progress := campaign.zodiac.progress
	progress.commit("rooster", "story", {"promises_kept": 3, "promise_kept:rooster.early_score": 2, "promise_kept:rooster.extension": 1, "pleased_victories": 1})
	progress.record_disposition("rooster", "kindred", "NORMAL")
	assert_false(progress.eligible("rooster"))
	progress.commit("rooster", "honest-no", {"promises_refused": 1})
	assert_true(progress.eligible("rooster"))
	assert_false(campaign.zodiac.complete_scene())
	campaign.zodiac.begin_day(0, campaign.seed_for("zodiac_selection", 0))
	assert_true(progress.record("rooster").special_scene_unlocked)
	assert_true(campaign.zodiac.complete_scene())
	assert_false(campaign.zodiac.complete_scene())
	assert_true(progress.owns("rooster"))
	var legacy := ZodiacProgress.new("")
	legacy.commit("rooster", "old-earned", {"requests_resolved": 4, "requests_refused_successfully": 1, "pleased_victories": 1})
	assert_true(legacy.eligible("rooster"))
