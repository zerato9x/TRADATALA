class_name ZodiacPersuasion
extends RefCounted
## One content interpreter. All durable values live in ZodiacService.daily.
## This engine observes authorities; it never changes cards, Relics, or money.
var _rng: RandomNumberGenerator
var _owner: WeakRef
var service: RefCounted:
	get: return _owner.get_ref() if _owner != null else null

func bind(owner: RefCounted, rng: RandomNumberGenerator) -> void:
	_owner = weakref(owner)
	_rng = rng

func state() -> Dictionary:
	return service.daily.get("persuasion", {})

func begin() -> void:
	if not state().is_empty(): return
	service.daily.persuasion = {"version": 1, "status": "active", "stage": "question", "patience": 3,
		"relationship_at_start": service.progress.relationship_tier(service.active_id()),
		"plan": [], "cursor": 0, "revision": 0, "node": {}, "terms": {}, "counteroffer": {},
		"dialogue": [], "next_stage": "", "next_node_id": "", "history": [], "outcomes": [], "committed": {}, "selection": [],
		"last_chance_consumed": false, "interaction_locked": false, "final_disposition": "", "judged": false}
	var special := ZodiacCatalog.persuasion_special(service.active_id(), service.progress.record(service.active_id()))
	var eligible: Array[Dictionary] = []
	for node: Dictionary in ZodiacCatalog.persuasion_nodes(service.active_id()):
		if _eligible(node): eligible.append(node)
	if not special.is_empty() and _eligible(special):
		state().plan = [special]
	else:
		var highest := 0
		for node in eligible: highest = maxi(highest, ZodiacCatalog.persuasion_content_rank(node.content_tier))
		eligible = eligible.filter(func(node: Dictionary): return ZodiacCatalog.persuasion_content_rank(node.content_tier) == highest)
		for index in range(eligible.size() - 1, 0, -1):
			var swap: int = _rng.randi_range(0, index)
			var temporary: Dictionary = eligible[index]
			eligible[index] = eligible[swap]
			eligible[swap] = temporary
		var previous: String = service.conversation_history.get(service.active_id(), "")
		if eligible.size() > 1 and eligible[0].id == previous:
			var temporary: Dictionary = eligible[0]
			eligible[0] = eligible[1]
			eligible[1] = temporary
		var limits: Dictionary = ZodiacCatalog.persuasion_config(service.active_id()).get("visit_limits", {})
		var limit := int(limits.get(str(eligible[0].content_tier), 1)) if not eligible.is_empty() else 0
		state().plan = eligible.slice(0, mini(eligible.size(), limit))
	_open_node()

func _eligible(node: Dictionary) -> bool:
	var required_tier := ZodiacProgress.FAMILIAR if ZodiacCatalog.persuasion_content_rank(node.get("content_tier", "1")) > 2 else ZodiacProgress.STRANGER
	if service.progress.relationship_tier(service.active_id()) < int(node.get("relationship_required", required_tier)): return false
	var history: Dictionary = service.progress.record(service.active_id())
	if node.get("once_only", false) and history.get("content:" + String(node.id), false): return false
	for flag: String in node.get("requirements", {}).get("history", {}):
		if int(history.get(flag, 0)) < int(node.requirements.history[flag]): return false
	if node.has("memory_key"):
		var remembered: Dictionary = service.progress.memory(service.active_id(), node.memory_key)
		if not node.get("prompts", {}).has(remembered.get("result", "")): return false
	var terms: Dictionary = node.get("promise", {})
	if terms.is_empty(): return true
	if terms.get("target_kind", "") == "ACTION": return _action_terms_valid(terms)
	var pool := _target_pool(terms)
	return pool.size() >= (3 if node.get("initial_authority", "") == "OFFER_THREE_PLAYER_CHOOSES" else 1)

func _target_pool(terms: Dictionary) -> Array:
	if terms.get("target_kind", "") == "RELIC":
		var owned: Array = service.campaign.relic_shop.runtime.inventory.duplicate()
		owned.sort()
		return owned.filter(func(id: String): return RelicCatalog.DEFINITIONS.has(id))
	return CardTargetQuery.pool(service.campaign.gieo_que.persistent_deck, terms.get("targeting", "ANY"))

func _open_node() -> void:
	var visit := state()
	if int(visit.cursor) >= visit.plan.size():
		visit.node = {}
		visit.terms = {}
		visit.counteroffer = {}
		visit.stage = "complete"
		visit.status = "awaiting_afternoon" if not service.daily.promises.is_empty() else "complete"
		return
	visit.node = visit.plan[visit.cursor].duplicate(true)
	if visit.node.has("memory_key"):
		# Bind once. Refreshing or resuming cannot rewrite the recalled event.
		var remembered: Dictionary = service.progress.memory(service.active_id(), visit.node.memory_key)
		visit.node["bound_memory"] = remembered
		visit.node["prompt"] = visit.node.get("prompts", {}).get(remembered.get("result", ""), []).duplicate(true)
		for line: Dictionary in visit.node.prompt:
			line.en = String(line.en).replace("{target}", ZodiacCatalog.memory_target(remembered, "en"))
			line.vi = String(line.vi).replace("{target}", ZodiacCatalog.memory_target(remembered, "vi"))
		if visit.node.has("answers_by_result"):
			visit.node["answers"] = visit.node.answers_by_result.get(remembered.get("result", ""), []).duplicate(true)
	visit.stage = "question"
	visit.dialogue = visit.node.get("prompt", []).duplicate(true)
	visit.terms = {}
	visit.counteroffer = {}
	visit.selection = []
	visit.next_node_id = ""
	if visit.node.has("promise"):
		visit.terms = visit.node.promise.duplicate(true)
		visit.terms["target_ids"] = []
		visit.terms["relic_id"] = ""
		visit.terms["offered_ids"] = []
		visit.terms["authority"] = "PLAYER_COMMITS"
		if visit.terms.get("target_kind", "") == "ACTION":
			service.conversation_history[service.active_id()] = visit.node.id
			return
		var pool := _target_pool(visit.terms)
		# Requirements were checked before selection. Never substitute different terms.
		if pool.is_empty():
			visit.cursor += 1
			_open_node()
			return
		var target: Variant = pool[_rng.randi_range(0, pool.size() - 1)]
		visit.terms["target_ids"] = [target.unique_id] if target is CardData else []
		visit.terms["relic_id"] = target if target is String else ""
		visit.terms["offered_ids"] = []
		visit.terms["authority"] = "ZODIAC_CHOOSES"
		if visit.node.get("initial_authority", "") == "OFFER_THREE_PLAYER_CHOOSES":
			visit.terms.authority = "OFFER_THREE_PLAYER_CHOOSES"
			visit.terms.offered_ids = CardTargetQuery.physical_ids(CardTargetQuery.random_cards(pool, 3, _rng))
			visit.terms.target_ids = []
	service.conversation_history[service.active_id()] = visit.node.id

func token() -> String:
	return service.record_key("persuasion:%d:%d:%s" % [int(state().get("cursor", 0)), int(state().get("revision", 0)), state().get("stage", "")])

func _can_interact(expected: String = "") -> bool:
	return (not service.response_locked() and service.campaign != null
		and service.campaign.current_phase == CampaignManager.CampaignPhase.NOON_EVENT
		and int(service.daily.get("slot", -1)) == EventManager.EventSlot.NOON
		and service.campaign.gieo_que.state in [GieoQueService.STATE_READY, GieoQueService.STATE_COMPLETE]
		and not state().get("interaction_locked", false) and not state().get("judged", false)
		and (expected.is_empty() or expected == token()))

func has_interaction() -> bool:
	return state().get("stage", "") in ["question", "reaction", "terms", "counteroffer", "last_chance", "last_chance_pending"] and not state().get("interaction_locked", false) and not state().get("judged", false)

func has_question() -> bool:
	return state().get("stage", "") == "question" and has_interaction()

func has_terms() -> bool:
	return state().get("stage", "") in ["terms", "counteroffer"] and has_interaction()

func terms() -> Dictionary:
	return state().get("counteroffer", {}) if not state().get("counteroffer", {}).is_empty() else state().get("terms", {})

func answer(answer_id: String, expected: String = "") -> Dictionary:
	if not _can_interact(expected) or not has_question(): return {"ok": false, "error": "stale_or_closed_question"}
	for choice: Dictionary in state().node.get("answers", []):
		if choice.id != answer_id: continue
		if not service.begin_commit(): return {"ok": false, "error": "interaction_busy"}
		var visit := state()
		var before := int(visit.patience)
		visit.dialogue = [{"speaker": "player", "en": choice.en, "vi": choice.vi}]
		visit.dialogue.append_array(choice.get("reaction", []).duplicate(true))
		visit.dialogue.append_array(visit.node.get("followup", []).duplicate(true))
		visit.next_node_id = choice.get("followup_node", visit.node.get("followup_node", ""))
		visit.next_stage = "terms" if visit.node.has("promise") else "advance"
		visit.stage = "reaction"
		visit.revision += 1
		apply_patience(int(choice.delta))
		var result := {"ok": true, "kind": "QUESTION", "node_id": visit.node.id, "answer_id": answer_id,
			"authored_delta": int(choice.delta), "patience_before": before, "patience_after": visit.patience,
			"dialogue": visit.dialogue.duplicate(true), "reaction": choice.get("reaction", []).duplicate(true)}
		visit.history.append(result.duplicate(true))
		service.daily.last_result = result
		service.progress.commit(service.active_id(), token() + ":answered", {"questions_answered": 1}, ["content:" + String(visit.node.id)])
		service.finish_commit()
		service.changed.emit()
		return result
	return {"ok": false, "error": "unknown_answer"}

func continue_dialogue(expected: String = "") -> bool:
	if not _can_interact(expected) or state().get("stage", "") != "reaction": return false
	state().revision += 1
	if state().next_stage == "terms":
		state().stage = "terms"
		state().dialogue = state().node.get("followup", []).duplicate(true)
	else: _advance_node()
	service.changed.emit()
	return true

func _advance_node() -> void:
	var visit := state()
	var next_id: String = visit.get("next_node_id", "")
	# Linked nodes remain authored and obey the same requirements as random nodes.
	if not next_id.is_empty():
		for node: Dictionary in ZodiacCatalog.persuasion_nodes(service.active_id()):
			if node.id != next_id or not _eligible(node): continue
			for index in range(visit.plan.size() - 1, int(visit.cursor), -1):
				if visit.plan[index].id == next_id: visit.plan.remove_at(index)
			visit.plan.insert(int(visit.cursor) + 1, node.duplicate(true))
			break
	visit.cursor += 1
	_open_node()

func apply_patience(delta: int) -> void:
	if state().is_empty() or state().get("interaction_locked", false) or state().get("judged", false): return
	state().patience = clampi(int(state().patience) + delta, 0, 5)
	if int(state().patience) > 0: return
	if state().get("stage", "") in ["last_chance", "last_chance_pending"]: return
	if state().last_chance_consumed:
		_lock_interaction()
		return
	state().last_chance_consumed = true
	state()["suspended_stage"] = state().stage
	state()["recovery_node"] = ZodiacCatalog.persuasion_config(service.active_id()).get("last_chance", {}).duplicate(true)
	state().stage = "last_chance_pending" if state().recovery_node.is_empty() else "last_chance"
	state().status = state().stage

func resolve_last_chance(answer_id: String, expected: String = "") -> bool:
	if not _can_interact(expected) or state().get("stage", "") != "last_chance": return false
	for choice: Dictionary in state().get("recovery_node", {}).get("answers", []):
		if choice.get("id", "") != answer_id or not choice.has("recovery_success"): continue
		if not service.begin_commit(): return false
		state().dialogue = [{"speaker": "player", "en": choice.en, "vi": choice.vi}]
		state().dialogue.append_array(choice.get("reaction", []).duplicate(true))
		_complete_last_chance(bool(choice.recovery_success))
		state().history.append({"kind": "LAST_CHANCE", "answer_id": answer_id, "recovered": bool(choice.recovery_success), "dialogue": state().dialogue.duplicate(true)})
		service.progress.commit(service.active_id(), token() + ":recovery", {"last_chances_recovered" if choice.recovery_success else "last_chances_declined": 1})
		service.finish_commit()
		service.changed.emit()
		return true
	return false

func _complete_last_chance(success: bool) -> void:
	state().revision += 1
	if success:
		state().patience = 1
		state().stage = state().get("suspended_stage", "reaction")
		state().status = "active"
	else: _lock_interaction()

func end_pending_recovery(expected: String = "") -> bool:
	# Explicit player exit while authoring is absent. Never fabricate a recovery result.
	if not _can_interact(expected) or state().get("stage", "") != "last_chance_pending": return false
	state()["recovery_unavailable"] = true
	_lock_interaction()
	service.changed.emit()
	return true

func _lock_interaction() -> void:
	state().interaction_locked = true
	state().stage = "locked"
	state().status = "locked"
	state().final_disposition = "UNPLEASED"

func can_accept(ids: Array = []) -> bool:
	if not has_terms() or not _terms_valid(terms()): return false
	if terms().get("authority", "") == "OFFER_THREE_PLAYER_CHOOSES":
		return ids.size() == 1 and ids[0] in terms().offered_ids and not CardTargetQuery.resolve_ids(service.campaign.gieo_que.persistent_deck, ids).is_empty()
	return true

func _terms_valid(offer: Dictionary) -> bool:
	if offer.is_empty(): return false
	if offer.get("target_kind", "") == "ACTION": return _action_terms_valid(offer)
	if offer.target_kind == "RELIC": return offer.get("relic_id", "") in service.campaign.relic_shop.runtime.inventory
	var pool := _target_pool(offer)
	var ids: Array = offer.offered_ids if offer.get("authority", "") == "OFFER_THREE_PLAYER_CHOOSES" else offer.target_ids
	return not ids.is_empty() and CardTargetQuery.resolve_ids(pool, ids).size() == ids.size()

func _action_terms_valid(offer: Dictionary) -> bool:
	if offer.get("interaction", "") != "deal_action" or offer.get("polarity", "") != "DO" or offer.get("window", "") != "NEXT_DEAL": return false
	if offer.get("condition", "") == "early_score": return int(offer.get("deal_phase", 0)) == 1
	return offer.get("condition", "") == "do_action" and offer.get("action", "") in ["new_meld", "extension"] and int(offer.get("deal_phase", -1)) in [0, 1, 2]

func can_haggle() -> bool:
	return has_terms() and state().counteroffer.is_empty() and terms().get("authority", "") != "OFFER_THREE_PLAYER_CHOOSES" and not _counter_pool().is_empty()

func _counter_pool() -> Array:
	var strategy: String = state().get("node", {}).get("responses", {}).get("HAGGLE", {}).get("strategy", "")
	if strategy == "ALTERNATE_ACTION":
		var alternative: Dictionary = state().node.responses.HAGGLE.get("terms", {})
		return [alternative] if _action_terms_valid(alternative) else []
	var pool := _target_pool(terms())
	match strategy:
		"OFFER_THREE": return pool if pool.size() >= 3 else []
		"OTHER_RELIC": return pool.filter(func(id: String): return id != terms().relic_id)
		"OTHER_TRANSFORMED_CARD": return pool.filter(func(card: CardData): return card.unique_id not in terms().target_ids)
	return []

func respond(response: String, ids: Array = [], expected: String = "") -> Dictionary:
	if not _can_interact(expected) or not has_terms() or response not in ["ACCEPT", "REFUSE", "HAGGLE"]: return {"ok": false, "error": "stale_or_closed_offer"}
	if response == "HAGGLE": return _haggle()
	if response == "ACCEPT" and not can_accept(ids): return {"ok": false, "error": "invalid_target_or_resource"}
	if not service.begin_commit(): return {"ok": false, "error": "interaction_busy"}
	var visit := state()
	var offer := terms().duplicate(true)
	var counter: bool = not visit.counteroffer.is_empty()
	if response == "ACCEPT" and offer.authority == "OFFER_THREE_PLAYER_CHOOSES": offer.target_ids = ids.duplicate()
	var response_key := "COUNTER_ACCEPT" if counter and response == "ACCEPT" and visit.node.responses.has("COUNTER_ACCEPT") else response
	if counter and response == "REFUSE" and visit.node.responses.has("COUNTER_REFUSE"): response_key = "COUNTER_REFUSE"
	var authored: Dictionary = visit.node.responses[response_key]
	var result := {"ok": true, "kind": "PROMISE", "node_id": visit.node.id, "response": response,
		"terms": offer, "counteroffer_accepted": counter and response == "ACCEPT", "pending": response == "ACCEPT",
		"dialogue": authored.dialogue.duplicate(true), "authored_delta": int(authored.delta)}
	if response == "ACCEPT":
		var promise_id: String = service.record_key("promise:%s:%d" % [offer.id, int(visit.cursor)])
		if visit.committed.has(promise_id):
			service.finish_commit()
			return {"ok": false, "error": "already_committed"}
		visit.committed[promise_id] = true
		var promise := {"engine": "persuasion", "id": promise_id, "semantic_id": offer.id, "node_id": visit.node.id,
			"zodiac": service.active_id(), "accepted_terms": offer.duplicate(true), "target_ids": offer.target_ids.duplicate(),
			"relic_id": offer.relic_id, "window": offer.window, "phase": CampaignManager.CampaignPhase.AFTERNOON_DEAL,
			"judgement_slot": EventManager.EventSlot.AFTERNOON, "accepted_day": service.daily.day,
			"memory_details": _memory_details(offer, visit.node.id, "", counter),
			"status": "pending", "started": offer.window == "ZODIAC_RETURN", "completed": false, "broken": false, "matched": false,
			"observations": {}, "outcome_applied": false, "outcomes": visit.node.outcomes.duplicate(true), "baseline": {}}
		if offer.target_kind == "CARD":
			var card: CardData = CardTargetQuery.resolve_ids(service.campaign.gieo_que.persistent_deck, offer.target_ids)[0]
			promise.baseline = card.persuasion_fingerprint()
		service.daily.promises.append(promise)
		result["promise_id"] = promise_id
		if counter: visit.counteroffer = offer.duplicate(true)
	else:
		var refusal_id: String = service.record_key("refusal:%s:%d" % [offer.id, int(visit.cursor)])
		service.progress.commit(service.active_id(), refusal_id, {"promises_refused": 1})
		service.progress.remember(service.active_id(), refusal_id + ":memory", offer.id, _memory_details(offer, visit.node.id, "REFUSED", counter))
	visit.dialogue = authored.dialogue.duplicate(true)
	visit.next_stage = "advance"
	visit.stage = "reaction"
	visit.revision += 1
	apply_patience(int(authored.delta))
	visit.history.append(result.duplicate(true))
	service.daily.last_result = result
	service.finish_commit()
	service.changed.emit()
	return result

func _memory_details(offer: Dictionary, node_id: String, result: String, counter: bool) -> Dictionary:
	var card_id: String = offer.get("target_ids", [])[0] if not offer.get("target_ids", []).is_empty() else ""
	var cards := CardTargetQuery.resolve_ids(service.campaign.gieo_que.persistent_deck, [card_id])
	var label: String = cards[0].short_label() if not cards.is_empty() else "that card"
	var details := {"result": result, "node_id": node_id, "target_id": card_id, "target_label": label,
		"relic_id": String(offer.get("relic_id", "")), "counteroffer": counter}
	if offer.get("target_kind", "") == "ACTION":
		details.target_label = ""
		details["commitment_en"] = String(offer.get("en", ""))
		details["commitment_vi"] = String(offer.get("vi", ""))
	return details

func _haggle() -> Dictionary:
	if not can_haggle(): return {"ok": false, "error": "no_counteroffer"}
	var pool := _counter_pool()
	var counter := terms().duplicate(true)
	var strategy: String = state().node.responses.HAGGLE.strategy
	if strategy == "ALTERNATE_ACTION":
		counter = pool[0].duplicate(true)
		counter.merge({"target_ids": [], "relic_id": "", "offered_ids": [], "authority": "PLAYER_COMMITS"})
	elif strategy == "OFFER_THREE":
		counter.authority = "OFFER_THREE_PLAYER_CHOOSES"
		counter.offered_ids = CardTargetQuery.physical_ids(CardTargetQuery.random_cards(pool, 3, _rng))
		counter.target_ids = []
	else:
		# Cat picks another owned target, from a saved small valid set.
		var candidates: Array = pool.slice(0, mini(3, pool.size()))
		var target: Variant = candidates[_rng.randi_range(0, candidates.size() - 1)]
		counter.target_ids = [target.unique_id] if target is CardData else []
		counter.relic_id = target if target is String else ""
		counter["candidate_ids"] = candidates.map(func(item: Variant): return item.unique_id if item is CardData else item)
	state().counteroffer = counter
	state().selection = []
	state().stage = "counteroffer"
	state().dialogue = state().node.responses.HAGGLE.dialogue.duplicate(true)
	state().revision += 1
	service.changed.emit()
	return {"ok": true, "counteroffer": counter.duplicate(true), "requires_confirmation": true}

func select_card(card_id: String, expected: String = "") -> bool:
	if not _can_interact(expected) or not has_terms() or terms().get("authority", "") != "OFFER_THREE_PLAYER_CHOOSES": return false
	if card_id not in terms().offered_ids: return false
	state().selection = [card_id]
	service.changed.emit()
	return true

func start_deal(period: String) -> void:
	if period != "afternoon": return
	for promise: Dictionary in service.daily.get("promises", []):
		if promise.get("engine", "") != "persuasion" or promise.get("outcome_applied", false): continue
		promise.started = true
		promise["deal_started"] = true

func finish_deal(period: String) -> void:
	if period != "afternoon": return
	for promise: Dictionary in service.daily.get("promises", []):
		if promise.get("engine", "") == "persuasion" and promise.get("deal_started", false): promise.completed = true

func observe_action(result: Dictionary, event_id: String) -> void:
	if service.is_restoring() or service.campaign == null or service.deal == null or not result.get("ok", false): return
	if service.campaign.current_phase != CampaignManager.CampaignPhase.AFTERNOON_DEAL: return
	for promise: Dictionary in service.daily.get("promises", []):
		if promise.get("engine", "") != "persuasion" or not promise.get("deal_started", false) or promise.get("completed", false) or promise.get("outcome_applied", false): continue
		var offer: Dictionary = promise.accepted_terms
		if offer.get("interaction", "") != "deal_action" or promise.observations.has(event_id): continue
		var action: String = result.get("action", "")
		var phase: int = service.deal.current_phase
		var context: ScoringContext = result.get("context")
		var matches := false
		if offer.condition == "early_score":
			matches = phase == 1 and service.deal.discard_count == 0 and action in ["new_meld", "extension"] and context != null and context.final_points > 0
			if not promise.get("matched", false) and (phase > 1 or (action == "discard" and result.get("discard_kind", "") == DiscardRecord.KIND_MANDATORY)):
				promise.broken = true
		elif action == offer.action and context != null:
			matches = int(offer.deal_phase) == 0 or phase == int(offer.deal_phase)
		if not matches and not promise.broken: continue
		promise.observations[event_id] = {"action": action, "phase": phase, "mandatory_discards": service.deal.discard_count, "matched": matches}
		if matches and not promise.broken: promise.matched = true
		service.changed.emit()

func observe_cards(ids: Array, event_id: String, interaction: String) -> void:
	if service.is_restoring(): return
	for promise: Dictionary in service.daily.get("promises", []):
		if promise.get("engine", "") != "persuasion" or not promise.get("started", false) or promise.get("outcome_applied", false): continue
		if promise.accepted_terms.interaction != interaction: continue
		if promise.window == "NEXT_DEAL" and (promise.completed or service.campaign.current_phase != int(promise.phase)): continue
		if not ids.any(func(id: String): return id in promise.target_ids) or promise.observations.has(event_id): continue
		promise.observations[event_id] = {"interaction": interaction, "target_ids": ids.duplicate()}
		promise.broken = true
		service.changed.emit()

func observe_inventory() -> void:
	if service.is_restoring() or service.campaign == null: return
	for promise: Dictionary in service.daily.get("promises", []):
		if promise.get("engine", "") != "persuasion" or promise.get("outcome_applied", false): continue
		if promise.accepted_terms.interaction == "relic_loss" and promise.relic_id not in service.campaign.relic_shop.runtime.inventory:
			if not promise.broken:
				promise.broken = true
				promise.observations["ownership_lost:" + String(promise.relic_id)] = {"interaction": "relic_loss"}
				service.changed.emit()

func judge() -> void:
	if state().is_empty() or state().get("judged", false): return
	observe_inventory()
	for promise: Dictionary in service.daily.get("promises", []).duplicate():
		if promise.get("engine", "") != "persuasion" or promise.get("outcome_applied", false): continue
		if not promise.get("completed", false): continue
		if promise.accepted_terms.interaction == "card_alter":
			var cards := CardTargetQuery.resolve_ids(service.campaign.gieo_que.persistent_deck, promise.target_ids)
			if cards.is_empty() or cards[0].persuasion_fingerprint() != promise.baseline: promise.broken = true
		var success: bool = not bool(promise.broken) and (promise.accepted_terms.get("interaction", "") != "deal_action" or bool(promise.get("matched", false)))
		var authored: Dictionary = promise.outcomes["FULFILLED" if success else "BROKEN"]
		# Settle once, before emitting observers or writing permanent history.
		promise.outcome_applied = true
		promise.status = "fulfilled" if success else "broken"
		apply_patience(int(authored.delta))
		var result := {"ok": true, "kind": "PROMISE_OUTCOME", "id": promise.id, "node_id": promise.node_id,
			"resolved_successfully": success, "terms": promise.accepted_terms.duplicate(true),
			"dialogue": authored.dialogue.duplicate(true), "authored_delta": int(authored.delta), "pending": false}
		state().outcomes.append(result)
		service.daily.last_result = result
		var semantic_id: String = promise.get("semantic_id", promise.accepted_terms.id)
		var increments := {"promises_kept" if success else "promises_broken": 1}
		increments[("promise_kept:" if success else "promise_broken:") + semantic_id] = 1
		service.progress.commit(service.active_id(), String(promise.id) + ":judged", increments)
		var remembered: Dictionary = promise.get("memory_details", _memory_details(promise.accepted_terms, promise.node_id, "", false)).duplicate(true)
		remembered.result = "FULFILLED" if success else "BROKEN"
		service.progress.remember(service.active_id(), String(promise.id) + ":memory", semantic_id, remembered)
		service.daily.promises.erase(promise)
	if service.daily.get("promises", []).any(func(promise: Dictionary): return promise.get("engine", "") == "persuasion" and not promise.get("outcome_applied", false)): return
	state().judged = true
	state().final_disposition = "UNPLEASED" if state().interaction_locked else ZodiacCatalog.patience_disposition(int(state().patience))
	state().status = "judged"
	state().stage = "judged"
	service.progress.record_disposition(service.active_id(), service.record_key("persuasion_judgement"), state().final_disposition)

func reminder() -> String:
	var lines: Array[String] = []
	for promise: Dictionary in service.daily.get("promises", []):
		if promise.get("engine", "") != "persuasion" or promise.get("outcome_applied", false): continue
		var line := describe_terms(promise.accepted_terms)
		if promise.accepted_terms.get("interaction", "") == "deal_action":
			line += "\n" + (ZodiacCatalog.words("Done · judged on return", "Đã làm · xét khi gặp lại") if promise.get("matched", false) else ZodiacCatalog.words("Deadline missed", "Đã quá hạn") if promise.broken else ZodiacCatalog.words("Pending", "Chưa hoàn thành"))
		lines.append(line)
	return "\n".join(lines)

func describe_terms(offer: Dictionary) -> String:
	if offer.is_empty(): return ""
	var text := ZodiacCatalog.localized(offer)
	if offer.get("target_kind", "") == "ACTION": return text
	var names: Array[String] = []
	if offer.target_kind == "RELIC": names.append(RelicCatalog.display_name(offer.relic_id))
	else:
		var ids: Array = offer.target_ids if not offer.target_ids.is_empty() else offer.offered_ids
		for card in CardTargetQuery.resolve_ids(service.campaign.gieo_que.persistent_deck, ids): names.append(card.short_label())
	return text + ("\n" + ZodiacCatalog.words("Target: ", "Đối tượng: ") + ", ".join(names) if not names.is_empty() else "")

func quote() -> Dictionary:
	var visit := state()
	var stage: String = visit.get("stage", "")
	var sequence: Array = visit.get("dialogue", []).duplicate(true)
	if stage == "judged":
		sequence.clear()
		for result: Dictionary in visit.outcomes: sequence.append_array(result.dialogue)
	elif stage == "last_chance": sequence.append_array(visit.get("recovery_node", {}).get("prompt", []))
	var answers: Array[Dictionary] = []
	if has_question():
		for choice: Dictionary in visit.node.answers: answers.append({"id": choice.id, "text": ZodiacCatalog.localized(choice)})
	elif stage == "last_chance":
		for choice: Dictionary in visit.get("recovery_node", {}).get("answers", []): answers.append({"id": choice.id, "text": ZodiacCatalog.localized(choice)})
	return {"kind": "QUESTION" if has_question() else "PROMISE" if has_terms() else "REACTION", "stage": stage,
		"speech": ZodiacCatalog.dialogue_text(sequence, service.active_id()), "dialogue": sequence,
		"contract": describe_terms(terms()) if has_terms() else "", "demand": terms().duplicate(true),
		"answers": answers, "status": stage, "can_haggle": can_haggle(), "can_time": false}
