@tool
extends McpTestSuite

const FLOW := preload("res://tests/zodiac_test_flow.gd")

func suite_name() -> String:
	return "cat_persuasion"

func _campaign(familiar: bool = false) -> CampaignManager:
	var deal := DealState.new()
	var events := EventManager.new()
	CampaignNpcCatalog.register_initial_npcs(events)
	var campaign := CampaignManager.new(deal.wallet, events)
	campaign.zodiac.bind(campaign, deal)
	campaign.relic_shop.runtime = deal.relics
	campaign.zodiac.progress = ZodiacProgress.new("")
	if familiar: campaign.zodiac.progress.record_disposition("cat", "fixture:pleased", "PLEASED")
	var seed_text := ""
	for index in 50:
		campaign.run_seed = "CAT-PERSUASION-%d" % index
		if ZodiacCatalog.select(campaign.seed_for("zodiac_selection", 0), 0) == "cat": seed_text = campaign.run_seed; break
	campaign.start_campaign(true, seed_text)
	assert_eq(campaign.zodiac.active_id(), "cat")
	campaign._enter_phase(CampaignManager.CampaignPhase.NOON_EVENT)
	return campaign

func _node(campaign: CampaignManager, id: String) -> void:
	for node: Dictionary in ZodiacCatalog.persuasion_nodes("cat"):
		if node.id != id: continue
		assert_true(campaign.zodiac.persuasion._eligible(node))
		var state := campaign.zodiac.persuasion.state()
		state.plan = [node]
		state.cursor = 0
		campaign.zodiac.persuasion._open_node()
		return
	assert_true(false, "missing authored node " + id)

func _terms(campaign: CampaignManager, id: String, answer: String = "B") -> void:
	_node(campaign, id)
	assert_true(campaign.zodiac.answer_question(answer).ok)
	assert_true(campaign.zodiac.continue_conversation())
	assert_true(campaign.zodiac.has_open_demand())

func _accept_card(campaign: CampaignManager, interaction: String, target: String) -> Dictionary:
	var id := "cat.t1plus.leave_it_alone" if interaction == "card_use" else "cat.t1plus.dont_change_it"
	_terms(campaign, id)
	campaign.zodiac.persuasion.state().terms.target_ids = [target]
	assert_true(campaign.zodiac.respond("ACCEPT").pending)
	assert_true(campaign.zodiac.continue_conversation())
	return campaign.zodiac.daily.promises[0]

func _afternoon(campaign: CampaignManager) -> void:
	campaign._enter_phase(CampaignManager.CampaignPhase.AFTERNOON_DEAL)
	campaign.zodiac.deal.start_tutorial_deal()

func _judge(campaign: CampaignManager) -> void:
	campaign.zodiac.finish_daytime_deal("afternoon")
	campaign._enter_phase(CampaignManager.CampaignPhase.AFTERNOON_EVENT)

func _cleanup(path: String) -> void:
	for suffix in ["", ".bak", ".tmp"]: DirAccess.remove_absolute(path + suffix)

func test_patience_start_clamps_and_all_dispositions() -> void:
	var campaign := _campaign()
	var visit := campaign.zodiac.persuasion.state()
	assert_eq(visit.patience, 3)
	assert_eq(campaign.zodiac.mood(), "NORMAL")
	campaign.zodiac.persuasion.apply_patience(100)
	assert_eq(visit.patience, 5)
	campaign.zodiac.persuasion.apply_patience(-100)
	assert_eq(visit.patience, 0)
	for value in range(6):
		assert_eq(ZodiacCatalog.patience_disposition(value), ["UNPLEASED", "UNPLEASED", "NORMAL", "NORMAL", "PLEASED", "PLEASED"][value])

func _collect_lines(value: Variant, lines: Dictionary) -> void:
	if value is Dictionary:
		if value.has("speaker") and value.get("speaker", "") != "direction": lines[value.en] = int(lines.get(value.en, 0)) + 1
		elif value.has("reaction") and value.has("delta") and value.has("en"): lines[value.en] = int(lines.get(value.en, 0)) + 1
		for key in value: _collect_lines(value[key], lines)
	elif value is Array:
		for item in value: _collect_lines(item, lines)

func test_exact_authored_dialogue_answer_order_deltas_and_no_traits() -> void:
	var nodes := ZodiacCatalog.persuasion_nodes("cat")
	assert_eq(nodes.size(), 6)
	var deltas := [[0, 1, -1], [1, 0, -1], [1, 0, -1], [0, 1, -1], [-1, 0, 1], [0, 1, -1]]
	for index in nodes.size():
		assert_eq(nodes[index].answers.map(func(answer: Dictionary): return answer.id), ["A", "B", "C"])
		assert_eq(nodes[index].answers.map(func(answer: Dictionary): return answer.delta), deltas[index])
		for answer: Dictionary in nodes[index].answers:
			assert_true(int(answer.delta) in [-1, 0, 1])
			assert_false(answer.has("traits"))
			assert_false(answer.has("tags"))
			assert_true(not answer.vi.is_empty())
	var authored := FileAccess.get_file_as_string("res://docs/authoring/CAT_TIER_1_AUTHORITY.txt")
	var regex := RegEx.new()
	regex.compile("\\*\\*(?:CAT|PLAYER):\\*\\*\\s*“([^”]*)”")
	var expected := {}
	for found in regex.search_all(authored):
		var text: String = found.get_string(1)
		expected[text] = int(expected.get(text, 0)) + 1
	var loaded := {}
	_collect_lines(nodes, loaded)
	assert_eq(loaded, expected, "Every spoken line is verbatim, including repeated lines and speaker exchanges")
	for node: Dictionary in nodes:
		if node.has("promise"): assert_true(authored.contains(node.promise.en))

func test_every_answer_has_its_exact_delta_and_reaction_once() -> void:
	for node: Dictionary in ZodiacCatalog.persuasion_nodes("cat"):
		if node.content_tier != "1": continue
		for answer: Dictionary in node.answers:
			var campaign := _campaign()
			_node(campaign, node.id)
			var token := campaign.zodiac.offer_token()
			var result := campaign.zodiac.answer_question(answer.id, token)
			assert_eq(result.authored_delta, answer.delta)
			assert_eq(result.reaction, answer.reaction)
			assert_eq(result.patience_after, 3 + int(answer.delta))
			assert_eq(campaign.zodiac.persuasion.state().stage, "reaction")
			assert_false(campaign.zodiac.answer_question(answer.id, token).ok)
			assert_eq(campaign.zodiac.persuasion.state().patience, 3 + int(answer.delta))

func test_optional_followup_node_is_saved_and_checks_requirements() -> void:
	var campaign := _campaign()
	_node(campaign, "cat.t1.favorite_card")
	campaign.zodiac.persuasion.state().node["followup_node"] = "cat.t1.keeping_things"
	assert_true(campaign.zodiac.answer_question("B").ok)
	var save := RunSave.new("user://cat_followup.save")
	assert_true(save.save_run(campaign, campaign.zodiac.deal))
	assert_true(save.restore(save.load_run(), campaign, campaign.zodiac.deal))
	_cleanup(save.path)
	assert_eq(campaign.zodiac.persuasion.state().next_node_id, "cat.t1.keeping_things")
	assert_true(campaign.zodiac.continue_conversation())
	assert_eq(campaign.zodiac.persuasion.state().node.id, "cat.t1.keeping_things")
	assert_eq(campaign.zodiac.persuasion.state().patience, 4)
	var invalid := _campaign()
	_node(invalid, "cat.t1.favorite_card")
	invalid.zodiac.persuasion.state().node["followup_node"] = "cat.t1plus.keep_it"
	assert_true(invalid.zodiac.answer_question("B").ok)
	assert_true(invalid.zodiac.continue_conversation())
	assert_eq(invalid.zodiac.persuasion.state().stage, "complete")
	assert_true(invalid.zodiac.daily.promises.is_empty())

func test_stranger_only_surface_questions_and_future_familiar_unlock() -> void:
	var campaign := _campaign()
	var service := campaign.zodiac
	assert_true(service.progress.record("cat").first_meeting)
	assert_eq(service.progress.relationship_tier("cat"), ZodiacProgress.STRANGER)
	assert_eq(service.persuasion.state().plan.size(), 3)
	for node: Dictionary in service.persuasion.state().plan: assert_eq(node.content_tier, "1")
	assert_true(FLOW.finish_noon(service))
	assert_eq(service.progress.relationship_tier("cat"), ZodiacProgress.STRANGER)
	campaign._enter_phase(CampaignManager.CampaignPhase.AFTERNOON_EVENT)
	assert_eq(service.progress.relationship_tier("cat"), ZodiacProgress.FAMILIAR)
	assert_true(service.progress.record("cat").ever_pleased)
	assert_eq(service.progress.record("cat").familiar_transitions, 1)
	var history := service.progress.snapshot()
	campaign._enter_phase(CampaignManager.CampaignPhase.AFTERNOON_EVENT)
	assert_eq(service.progress.snapshot(), history)
	campaign.start_campaign(true, campaign.run_seed)
	campaign._enter_phase(CampaignManager.CampaignPhase.NOON_EVENT)
	assert_eq(service.progress.relationship_tier("cat"), ZodiacProgress.FAMILIAR)
	assert_eq(service.persuasion.state().plan.size(), 1)
	assert_eq(service.persuasion.state().node.content_tier, "1+")

func test_permanent_profile_disk_and_old_checkpoint_are_monotonic() -> void:
	var root_path := "user://cat_relationship_profiles"
	var files := MetaSaveFiles.new(root_path, "")
	var campaign := _campaign()
	files.attach(campaign)
	campaign.zodiac.progress.meet("cat", "met")
	var old := campaign.zodiac.progress.snapshot()
	assert_true(campaign.zodiac.progress.record_disposition("cat", "valid:judgement", "PLEASED"))
	var restored := MetaSaveFiles.new(root_path, "")
	var copy := CampaignManager.new()
	restored.attach(copy)
	assert_eq(copy.zodiac.progress.relationship_tier("cat"), ZodiacProgress.FAMILIAR)
	copy.zodiac.progress.merge(old)
	assert_false(copy.zodiac.progress.record_disposition("cat", "valid:judgement", "PLEASED"))
	assert_eq(copy.zodiac.progress.record("cat").familiar_transitions, 1)
	copy.zodiac.reset_run()
	assert_eq(copy.zodiac.progress.relationship_tier("cat"), ZodiacProgress.FAMILIAR)
	for slot in range(1, 4): _cleanup(files.meta_path(slot))
	_cleanup(root_path + "/active.cfg")
	DirAccess.remove_absolute(root_path)

func test_invalid_relic_and_transformed_requirements_are_never_selected() -> void:
	for _index in 20:
		var campaign := _campaign(true)
		assert_eq(campaign.zodiac.persuasion.state().node.id, "cat.t1plus.leave_it_alone")
		for node: Dictionary in ZodiacCatalog.persuasion_nodes("cat"):
			if node.id == "cat.t1plus.keep_it" or node.id == "cat.t1plus.dont_change_it": assert_false(campaign.zodiac.persuasion._eligible(node))

	# Gieo property changes also qualify, even when rank/suit stayed printed.
	var campaign := _campaign(true)
	var card: CardData = campaign.gieo_que.persistent_deck[0]
	assert_true(card.add_gieo_property("GOLD_SET"))
	assert_false(CardTargetQuery.transformed_rank(card))
	assert_false(CardTargetQuery.transformed_suit(card))
	_terms(campaign, "cat.t1plus.dont_change_it")
	assert_eq(campaign.zodiac.current_demand().target_ids, [card.unique_id])
	assert_true(campaign.zodiac.respond("ACCEPT").ok)
	card.alter_for_zodiac("remove_property")
	assert_true(campaign.zodiac.daily.promises[0].broken)

func test_accept_stores_exact_terms_and_refuse_has_no_gameplay_cost() -> void:
	for response in ["ACCEPT", "REFUSE"]:
		var campaign := _campaign(true)
		_terms(campaign, "cat.t1plus.leave_it_alone")
		var service := campaign.zodiac
		var offer := service.current_demand().duplicate(true)
		var wallet := campaign.wallet.balance_vnd
		var cards := campaign.gieo_que.persistent_deck.map(func(card: CardData): return card.persuasion_fingerprint())
		var token := service.offer_token()
		assert_true(service.respond(response, [], token).ok)
		assert_false(service.respond(response, [], token).ok)
		assert_eq(campaign.wallet.balance_vnd, wallet)
		assert_eq(campaign.gieo_que.persistent_deck.map(func(card: CardData): return card.persuasion_fingerprint()), cards)
		assert_eq(service.persuasion.state().patience, 4)
		assert_eq(service.daily.promises.size(), 1 if response == "ACCEPT" else 0)
		if response == "ACCEPT":
			assert_eq(service.daily.promises[0].accepted_terms, offer)
			assert_eq(service.daily.promises[0].target_ids, offer.target_ids)
			assert_eq(service.daily.promises[0].status, "pending")

func test_haggle_offer_three_requires_a_saved_selection_and_acceptance() -> void:
	var campaign := _campaign(true)
	_terms(campaign, "cat.t1plus.leave_it_alone")
	var service := campaign.zodiac
	var original := service.current_demand().duplicate(true)
	var token := service.offer_token()
	assert_true(service.respond("HAGGLE", [], token).requires_confirmation)
	assert_eq(service.current_demand().offered_ids.size(), 3)
	assert_eq(service.daily.promises.size(), 0)
	assert_false(service.respond("ACCEPT", [], token).ok)
	assert_false(service.can_accept())
	assert_false(service.respond("HAGGLE").ok)
	var chosen: String = service.current_demand().offered_ids[1]
	assert_true(service.persuasion.select_card(chosen, service.offer_token()))
	assert_true(service.can_accept([chosen]))
	assert_true(service.respond("ACCEPT", [chosen]).pending)
	assert_eq(service.daily.promises[0].target_ids, [chosen])
	assert_eq(service.daily.last_result.dialogue[0].en, "Interesting.")
	assert_eq(service.daily.promises[0].accepted_terms.en, original.en)
	var card: CardData = CardTargetQuery.resolve_ids(campaign.gieo_que.persistent_deck, [chosen])[0]
	assert_eq(service.promise_reminder().get_slice("\n", 1), "Target: " + card.short_label())

func test_haggle_relic_is_another_owned_relic_and_missing_alternative_is_disabled() -> void:
	var campaign := _campaign(true)
	var runtime := campaign.relic_shop.runtime
	runtime.acquire("comb")
	_terms(campaign, "cat.t1plus.keep_it", "C")
	assert_false(campaign.zodiac.persuasion.can_haggle())
	assert_false(campaign.zodiac.respond("HAGGLE").ok)
	runtime.acquire("hair_clip")
	var original: String = campaign.zodiac.current_demand().relic_id
	assert_true(campaign.zodiac.respond("HAGGLE").requires_confirmation)
	var counter := campaign.zodiac.current_demand().duplicate(true)
	assert_true(counter.relic_id in runtime.inventory)
	assert_ne(counter.relic_id, original)
	assert_eq(campaign.zodiac.daily.promises.size(), 0)
	assert_true(campaign.zodiac.respond("ACCEPT").pending)
	assert_eq(campaign.zodiac.daily.promises[0].relic_id, counter.relic_id)

func test_haggle_transformed_requires_another_transformed_physical_card() -> void:
	var campaign := _campaign(true)
	var cards := campaign.gieo_que.persistent_deck
	cards[0].apply_rank("K", 13)
	_terms(campaign, "cat.t1plus.dont_change_it")
	assert_false(campaign.zodiac.persuasion.can_haggle())
	cards[1].apply_suit("Hearts")
	var original: Array = campaign.zodiac.current_demand().target_ids.duplicate()
	assert_true(campaign.zodiac.respond("HAGGLE").requires_confirmation)
	assert_ne(campaign.zodiac.current_demand().target_ids, original)
	var target := CardTargetQuery.resolve_ids(cards, campaign.zodiac.current_demand().target_ids)[0]
	assert_true(CardTargetQuery.transformed_rank(target) or CardTargetQuery.transformed_suit(target))
	assert_eq(campaign.zodiac.daily.promises.size(), 0)

func test_untouched_promise_success_and_real_meld_failure() -> void:
	for failure in [true, false]:
		var campaign := _campaign(true)
		var target := "standard_4_hearts" if failure else "standard_a_clubs"
		var promise := _accept_card(campaign, "card_use", target)
		assert_false(promise.started)
		_afternoon(campaign)
		assert_true(promise.started)
		assert_false(promise.broken, "dealing/drawing is not a player interaction")
		assert_true(campaign.zodiac.deal.create_meld(campaign.zodiac.deal.hand.slice(0, 3)).ok)
		assert_eq(promise.broken, failure)
		assert_eq(campaign.zodiac.persuasion.state().patience, 4)
		_judge(campaign)
		assert_eq(campaign.zodiac.daily.last_result.resolved_successfully, not failure)
		assert_eq(campaign.zodiac.persuasion.state().patience, 3 if failure else 5)
		assert_eq(campaign.zodiac.daily.last_result.dialogue[0].en, "There." if failure else "You really didn’t.")

func test_untouched_promise_discard_extra_drink_swap_and_preserve() -> void:
	for action in ["discard", "extra", "swap", "preserve"]:
		var campaign := _campaign(true)
		var target := "standard_j_clubs"
		var promise := _accept_card(campaign, "card_use", target)
		_afternoon(campaign)
		var deal := campaign.zodiac.deal
		var card := CardTargetQuery.resolve_ids(deal.hand, [target])[0]
		match action:
			"discard": assert_true(deal.discard_card(card).ok)
			"extra":
				deal.set_current_drink(DrinkCatalog.TRA_DA)
				assert_true(deal.discard_card(deal.hand[0]).ok)
				assert_true(deal.discard_card(card).ok)
			"swap":
				deal.set_current_drink(DrinkCatalog.NHAN_TRAN)
				assert_true(deal.discard_card(deal.hand[0]).ok)
				assert_true(deal.use_nhan_tran(card, deal.discard_history[0]).ok)
			"preserve":
				deal.set_current_drink(DrinkCatalog.SAM_DUA)
				deal.state = DealState.STATE_PHASE_CHOICE
				assert_true(deal.select_sam_dua_preserves([card]).ok)
		assert_true(promise.broken, action)
		_judge(campaign)
		assert_false(campaign.zodiac.daily.last_result.resolved_successfully)

func test_existing_meld_cards_do_not_count_as_new_extension_interactions() -> void:
	var campaign := _campaign(true)
	var promise := _accept_card(campaign, "card_use", "standard_4_hearts")
	_afternoon(campaign)
	var deal := campaign.zodiac.deal
	deal.create_meld(deal.hand.slice(0, 3))
	# An accepted promise would already be broken by making this Meld. Clear only
	# the fixture observation to isolate the subsequent Extension's committed IDs.
	promise.broken = false
	promise.observations.clear()
	deal.discard_card(deal.hand[-1])
	var card := CardTargetQuery.resolve_ids(deal.hand, ["standard_7_hearts"])[0]
	var result := deal.extend_meld(deal.melds[0].meld_id, [card])
	assert_true(result.ok)
	assert_eq(result.committed_card_ids, [card.unique_id])
	assert_false(promise.broken)

func test_relic_loss_is_monotonic_even_after_reacquisition_and_unequip_is_safe() -> void:
	for failure in [true, false]:
		var campaign := _campaign(true)
		var runtime := campaign.relic_shop.runtime
		runtime.acquire("comb")
		runtime.equip("comb")
		_terms(campaign, "cat.t1plus.keep_it", "C")
		campaign.zodiac.respond("ACCEPT")
		campaign.zodiac.continue_conversation()
		var promise: Dictionary = campaign.zodiac.daily.promises[0]
		assert_true(promise.started, "until-return window begins at acceptance")
		runtime.remove("comb")
		assert_false(promise.broken, "unequipping does not lose ownership")
		if failure:
			assert_true(runtime.gift("comb"))
			runtime.acquire("comb")
			assert_true(promise.broken)
		_afternoon(campaign)
		_judge(campaign)
		assert_eq(campaign.zodiac.daily.last_result.resolved_successfully, not failure)
		assert_eq(campaign.zodiac.daily.last_result.dialogue[0].en, "Oh." if failure else "Still there.")

func test_protected_card_catches_mutate_then_revert_before_the_deal_and_reset() -> void:
	for operation in ["rank_and_revert", "reset", "property", "seal"]:
		var campaign := _campaign(true)
		var card: CardData = campaign.gieo_que.persistent_deck[0]
		card.apply_rank("K", 13)
		var promise := _accept_card(campaign, "card_alter", card.unique_id)
		match operation:
			"rank_and_revert": card.apply_rank("2", 2); card.apply_rank("K", 13)
			"reset": card.alter_for_zodiac("reset")
			"property": card.add_gieo_property("GOLD_SET")
			"seal": card.alter_for_zodiac("seal")
		assert_true(promise.broken, operation)
		_afternoon(campaign)
		_judge(campaign)
		assert_false(campaign.zodiac.daily.last_result.resolved_successfully)
		assert_eq(campaign.zodiac.daily.last_result.dialogue[0].en, "You changed it.")

func test_protected_card_gieo_authority_and_unchanged_success() -> void:
	for failure in [true, false]:
		var campaign := _campaign(true)
		var card: CardData = campaign.gieo_que.persistent_deck[0]
		card.apply_rank("K", 13)
		var promise := _accept_card(campaign, "card_alter", card.unique_id)
		if failure:
			campaign.gieo_que.state = GieoQueService.STATE_TARGET_REVEAL
			campaign.gieo_que.resolved_targets = [card]
			campaign.gieo_que.current_result = {"effect": GieoQueService.EFFECT_ADD_GOLD_SET}
			campaign.gieo_que.resolved_destination = "GOLD_SET"
			assert_true(campaign.gieo_que.apply_resolved_targets().ok)
			campaign.gieo_que.finish_transformation()
		assert_eq(promise.broken, failure)
		_afternoon(campaign)
		_judge(campaign)
		assert_eq(campaign.zodiac.daily.last_result.resolved_successfully, not failure)
		assert_eq(campaign.zodiac.daily.last_result.dialogue[0].en, "You changed it." if failure else "See?")

func test_next_deal_only_ignores_noon_and_afternoon_service_use_after_completion() -> void:
	var campaign := _campaign(true)
	var promise := _accept_card(campaign, "card_use", "standard_4_hearts")
	campaign.zodiac.deal.start_tutorial_deal()
	campaign.zodiac.deal.create_meld(campaign.zodiac.deal.hand.slice(0, 3))
	assert_false(promise.broken)
	_afternoon(campaign)
	campaign.zodiac.finish_daytime_deal("afternoon")
	campaign.current_phase = CampaignManager.CampaignPhase.AFTERNOON_EVENT
	campaign.zodiac.deal.create_meld(campaign.zodiac.deal.hand.slice(0, 3))
	assert_false(promise.broken)

func test_question_reaction_counteroffer_and_selected_card_disk_restore() -> void:
	for stage in ["question", "reaction", "counteroffer", "selection"]:
		var campaign := _campaign(stage in ["counteroffer", "selection"])
		var service := campaign.zodiac
		if stage in ["counteroffer", "selection"]:
			_terms(campaign, "cat.t1plus.leave_it_alone")
			service.respond("HAGGLE")
			if stage == "selection": service.persuasion.select_card(service.current_demand().offered_ids[1])
		elif stage == "reaction": service.answer_question("A")
		var expected := service.snapshot()
		var save := RunSave.new("user://cat_" + stage + ".save")
		assert_true(save.save_run(campaign, service.deal))
		var copy := _campaign()
		assert_true(save.restore(save.load_run(), copy, copy.zodiac.deal))
		assert_eq(copy.zodiac.daily, expected.daily)
		assert_eq(copy.zodiac._rng.state, expected.rng_state)
		assert_eq(copy.zodiac.conversation_history, expected.conversation_history)
		assert_eq(copy.zodiac.quote(), service.quote())
		_cleanup(save.path)

func test_pending_and_judged_promise_disk_restore_never_replay_delta() -> void:
	var campaign := _campaign(true)
	_accept_card(campaign, "card_use", "standard_4_hearts")
	_afternoon(campaign)
	campaign.zodiac.deal.create_meld(campaign.zodiac.deal.hand.slice(0, 3))
	var save := RunSave.new("user://cat_promise_disk.save")
	assert_true(save.save_run(campaign, campaign.zodiac.deal))
	var copy := _campaign()
	assert_true(save.restore(save.load_run(), copy, copy.zodiac.deal))
	assert_true(copy.zodiac.daily.promises[0].broken)
	_judge(copy)
	var expected := copy.zodiac.snapshot()
	assert_true(save.save_run(copy, copy.zodiac.deal))
	assert_true(save.restore(save.load_run(), campaign, campaign.zodiac.deal))
	campaign._enter_phase(CampaignManager.CampaignPhase.AFTERNOON_EVENT)
	assert_eq(campaign.zodiac.daily, expected.daily)
	assert_eq(campaign.zodiac._rng.state, expected.rng_state)
	assert_eq(campaign.zodiac.persuasion.state().patience, 3)
	_cleanup(save.path)

func test_restore_does_not_falsely_break_relic_and_rebinds_card_observers() -> void:
	var campaign := _campaign(true)
	campaign.relic_shop.runtime.acquire("comb")
	_terms(campaign, "cat.t1plus.keep_it", "C")
	campaign.zodiac.respond("ACCEPT")
	var save := RunSave.new("user://cat_rebind.save")
	assert_true(save.save_run(campaign, campaign.zodiac.deal))
	var copy := _campaign(true)
	assert_true(save.restore(save.load_run(), copy, copy.zodiac.deal))
	assert_false(copy.zodiac.daily.promises[0].broken)
	copy.relic_shop.runtime.gift("comb")
	assert_true(copy.zodiac.daily.promises[0].broken)
	campaign = _campaign(true)
	campaign.gieo_que.persistent_deck[0].apply_rank("K", 13)
	_accept_card(campaign, "card_alter", campaign.gieo_que.persistent_deck[0].unique_id)
	assert_true(save.save_run(campaign, campaign.zodiac.deal))
	assert_true(save.restore(save.load_run(), copy, copy.zodiac.deal))
	copy.gieo_que.persistent_deck[0].apply_rank("2", 2)
	assert_true(copy.zodiac.daily.promises[0].broken)
	_cleanup(save.path)

func test_last_chance_is_once_pending_without_prose_and_hook_restores_one() -> void:
	var campaign := _campaign()
	var engine := campaign.zodiac.persuasion
	engine.apply_patience(-3)
	assert_eq(engine.state().stage, "last_chance_pending")
	assert_true(engine.state().last_chance_consumed)
	assert_false(engine.state().interaction_locked)
	assert_false(campaign.zodiac.answer_question("B").ok)
	assert_false(campaign.zodiac.respond("ACCEPT").ok)
	assert_false(engine.resolve_last_chance("A"))
	assert_true(engine.state().recovery_node.is_empty())
	var save := RunSave.new("user://cat_last_chance.save")
	assert_true(save.save_run(campaign, campaign.zodiac.deal))
	var copy := _campaign()
	assert_true(save.restore(save.load_run(), copy, copy.zodiac.deal))
	assert_eq(copy.zodiac.persuasion.state(), engine.state())
	# Exercise the generic authored hook using test-only outcomes; Cat has none.
	engine._complete_last_chance(true)
	assert_eq(engine.state().patience, 1)
	assert_eq(campaign.zodiac.mood(), "UNPLEASED")
	engine.apply_patience(-1)
	assert_true(engine.state().interaction_locked)
	assert_eq(engine.state().stage, "locked")
	assert_eq(engine.state().final_disposition, "UNPLEASED")
	assert_true(copy.zodiac.persuasion.end_pending_recovery())
	assert_true(copy.zodiac.persuasion.state().recovery_unavailable)
	_cleanup(save.path)

func test_actual_three_negative_answers_trigger_last_chance_without_softlock() -> void:
	var campaign := _campaign()
	for _index in 3:
		assert_true(campaign.zodiac.answer_question("C").ok)
		if campaign.zodiac.persuasion.state().stage == "reaction": campaign.zodiac.continue_conversation()
	assert_eq(campaign.zodiac.persuasion.state().patience, 0)
	assert_eq(campaign.zodiac.persuasion.state().stage, "last_chance_pending")
	assert_false(campaign.complete_current_event())
	assert_true(campaign.zodiac.persuasion.end_pending_recovery())
	assert_false(campaign.zodiac.has_open_interaction())

func test_selection_does_not_perturb_deck_gieo_boss_or_other_streams() -> void:
	var campaign := _campaign(true)
	var service := campaign.zodiac
	var before := [service.deal.deck._rng.state, campaign.gieo_que._rng.state, service.deal.zodiac_boss.rng.state,
		campaign.lottery._rng.state, campaign.relic_shop._rng.state, campaign.shoe_shine._rng.state]
	_terms(campaign, "cat.t1plus.leave_it_alone")
	service.respond("HAGGLE")
	assert_eq([service.deal.deck._rng.state, campaign.gieo_que._rng.state, service.deal.zodiac_boss.rng.state,
		campaign.lottery._rng.state, campaign.relic_shop._rng.state, campaign.shoe_shine._rng.state], before)
	var clone := _campaign(true)
	_terms(clone, "cat.t1plus.leave_it_alone")
	clone.zodiac.respond("HAGGLE")
	assert_eq(clone.zodiac.current_demand(), service.current_demand())
	assert_eq(clone.zodiac._rng.state, service._rng.state)

func test_final_patience_is_existing_cat_evening_difficulty_and_stalk_counts() -> void:
	for patience in range(6):
		var campaign := _campaign()
		assert_true(FLOW.finish_noon(campaign.zodiac))
		campaign.zodiac.persuasion.state().patience = patience
		campaign._enter_phase(CampaignManager.CampaignPhase.AFTERNOON_EVENT)
		campaign._enter_phase(CampaignManager.CampaignPhase.EVENING_DEAL)
		var deal := campaign.zodiac.deal
		assert_eq(deal.zodiac_boss.id, "cat")
		assert_eq(deal.zodiac_boss.difficulty, ZodiacCatalog.difficulty_value(ZodiacCatalog.patience_disposition(patience)))
		deal.set_campaign_deck(campaign.gieo_que.persistent_deck)
		deal.start_deal(12)
		deal.zodiac_boss.begin_turn(2, deal.hand)
		assert_eq(deal.zodiac_boss.locked_ids.size(), 1 if patience >= 4 else 2 if patience >= 2 else 3)

func test_no_unauthored_cat_special_or_early_emblem_scene() -> void:
	var campaign := _campaign()
	assert_true(ZodiacCatalog.persuasion_config("cat").last_chance.is_empty())
	assert_true(ZodiacCatalog.persuasion_special("cat", {"ending": true}).is_empty())
	assert_false(campaign.zodiac.complete_scene())
	assert_true(ZodiacCatalog.negotiation_profile("cat").is_empty())
	assert_false(campaign.zodiac.debug_offer(ZodiacDemand.make("PAY", "ANY", "PLAYER_CHOOSES", 1, "", 5000)).has("id"))

func test_old_started_cat_save_finishes_its_original_cost_without_new_engine() -> void:
	var campaign := _campaign()
	var service := campaign.zodiac
	var old := {"version": 2, "run_id": "old-cat", "daily": {"id": "cat", "day": 0, "slot": 2, "successes": 0,
		"promises": [], "requests": {}, "skip_phase": -1, "skipped": [], "boss_finished": false}}
	old.daily["negotiation"] = service._new_negotiation_state(1)
	var demand := ZodiacDemand.make("PAY", "ANY", "PLAYER_CHOOSES", 1, "", 5000)
	demand["id"] = "0:0"
	old.daily.negotiation.current_demand = demand
	service.restore(old)
	assert_false(service.uses_persuasion())
	var before := campaign.wallet.balance_vnd
	var token := service.offer_token()
	assert_true(service.respond("ACCEPT", [], token).ok)
	assert_eq(campaign.wallet.balance_vnd, before - 5000)
	assert_false(service.respond("ACCEPT", [], token).ok)
	service.begin_day(7, 12)
	service.daily.id = "cat"
	assert_true(service.uses_persuasion())
