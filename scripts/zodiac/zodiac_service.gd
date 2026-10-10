class_name ZodiacService
extends RefCounted
## Campaign-owned negotiation/progression. UI passes intentions, never costs or outcomes.
signal changed()
var progress := ZodiacProgress.new("")
var daily: Dictionary = {}
var forced: Dictionary = {}
var run_id := ""
var endgame: Dictionary = {}
var _campaign_ref: WeakRef
var campaign: RefCounted:
	get: return _campaign_ref.get_ref() if _campaign_ref != null else null
var deal: DealState
var _committing := false
var _rng := RandomNumberGenerator.new()
var _restoring := false
var conversation_history: Dictionary = {}
var persuasion := ZodiacPersuasion.new()
var _watched_cards: Array[CardData] = []

func _init() -> void:
	persuasion.bind(self, _rng)

func uses_persuasion() -> bool:
	return not ZodiacCatalog.persuasion_config(active_id()).is_empty() and not daily.get("legacy_negotiation", false)

func _negotiation_profile() -> Dictionary:
	return ZodiacCatalog.negotiation_profile(active_id(), bool(daily.get("legacy_negotiation", false)))

func has_open_interaction() -> bool:
	return persuasion.has_interaction() if uses_persuasion() else has_open_demand()

func has_open_question() -> bool:
	return uses_persuasion() and persuasion.has_question()

func answer_question(answer_id: String, expected_offer: String = "") -> Dictionary:
	return persuasion.answer(answer_id, expected_offer) if uses_persuasion() else {"ok": false}

func continue_conversation(expected_offer: String = "") -> bool:
	return uses_persuasion() and persuasion.continue_dialogue(expected_offer)

func promise_reminder() -> String:
	return persuasion.reminder() if uses_persuasion() else ""

func rebind_observers() -> void:
	for card in _watched_cards:
		if card.permanent_changed.is_connected(_observe_card_change): card.permanent_changed.disconnect(_observe_card_change)
	_watched_cards.clear()
	if campaign == null: return
	_watched_cards.assign(campaign.gieo_que.persistent_deck)
	for card in _watched_cards:
		if not card.permanent_changed.is_connected(_observe_card_change): card.permanent_changed.connect(_observe_card_change)
	if not campaign.gieo_que.transformation_completed.is_connected(_observe_transformations): campaign.gieo_que.transformation_completed.connect(_observe_transformations)
	if not campaign.relic_shop.runtime.inventory_changed.is_connected(_observe_inventory): campaign.relic_shop.runtime.inventory_changed.connect(_observe_inventory)

func _observe_card_change(card_id: String, revision: int, operation: String) -> void:
	if uses_persuasion(): persuasion.observe_cards([card_id], record_key("card:%s:%d:%s" % [card_id, revision, operation]), "card_alter")

func _observe_transformations(changes: Array[Dictionary]) -> void:
	if not uses_persuasion(): return
	for change in changes:
		var card: CardData = change.get("card")
		if card != null:
			persuasion.observe_cards([card.unique_id], record_key("gieo:%s:%d" % [card.unique_id, campaign.activities.size()]), "card_alter")

func _observe_inventory() -> void:
	if uses_persuasion(): persuasion.observe_inventory()

func bind_campaign(owner_campaign: RefCounted) -> void:
	_campaign_ref = weakref(owner_campaign)

func response_locked() -> bool:
	return _committing or _restoring

func is_restoring() -> bool:
	return _restoring

func begin_commit() -> bool:
	if response_locked(): return false
	_committing = true
	return true

func finish_commit() -> void:
	_committing = false

func bind(owner_campaign: RefCounted, owner_deal: DealState) -> void:
	bind_campaign(owner_campaign)
	deal = owner_deal
	if not deal.state_changed.is_connected(_observe_action): deal.state_changed.connect(_observe_action)
	if not deal.wallet.balance_changed.is_connected(_observe_wallet): deal.wallet.balance_changed.connect(_observe_wallet)
	rebind_observers()

func reset_run() -> void:
	daily.clear()
	endgame.clear()
	conversation_history.clear()
	run_id = "%s:%s" % [Time.get_unix_time_from_system(), Time.get_ticks_usec()]

func choose_emblem(day: int, id: String) -> bool:
	# A choice is for a future day only; it cannot reroll a day already encountered.
	if campaign != null and not daily.is_empty() and day <= int(daily.day): return false
	if id.is_empty(): forced.erase(day)
	elif progress.owns(id) and id in ZodiacCatalog.pair_for_day(day): forced[day] = id
	else: return false
	changed.emit()
	return true

func prefer_emblem(id: String = "") -> bool:
	if not id.is_empty() and (not ZodiacCatalog.DEFINITIONS.has(id) or not progress.owns(id)): return false
	var pair_index := -1
	for index in ZodiacCatalog.PAIRS.size():
		if id in ZodiacCatalog.PAIRS[index]: pair_index = index
	if not id.is_empty() and pair_index < 0: return false
	for key in forced.keys():
		if key is String and key.begins_with("pair:"): forced.erase(key)
	if not id.is_empty(): forced["pair:%d" % pair_index] = id
	changed.emit()
	return true

func begin_day(day: int, seed_value: int) -> void:
	var force: String = forced.get(day, forced.get("pair:%d" % ZodiacCatalog.DAY_PAIRS[posmod(day, ZodiacCatalog.DAY_PAIRS.size())], ""))
	if not progress.owns(force): force = ""
	var id := "" if DemoBuild.enabled() else ZodiacCatalog.select(seed_value, day, force)
	daily = {"day": day, "id": id, "forced": force, "successes": 0, "slot": -1, "requests": {}, "promises": [], "skip_phase": -1, "skipped": [], "boss_finished": false, "last_result": {}}
	_rng.seed = campaign.seed_for("zodiac_negotiation", day) if campaign != null else seed_value
	if id.is_empty(): return
	# Prerequisites earned today are evaluated on a subsequent encounter only.
	if (not uses_persuasion() or id == "rooster") and progress.eligible(id) and not progress.owns(id):
		progress.commit(id, record_key("scene_available"), {}, ["special_scene_unlocked"])
	progress.meet(id, record_key("encounter"))
	rebind_observers()
	changed.emit()

func active_id() -> String:
	return daily.get("id", "")

func mood() -> String:
	if uses_persuasion():
		var visit := persuasion.state()
		return visit.get("final_disposition", "") if not String(visit.get("final_disposition", "")).is_empty() else ZodiacCatalog.patience_disposition(int(visit.get("patience", 3)))
	if active_id().is_empty(): return "UNPLEASED"
	if _negotiation_profile().is_empty() and negotiation().is_empty() and int(daily.get("successes", 0)) == 0: return "NORMAL"
	return String(negotiation().get("final_disposition", "")) if not String(negotiation().get("final_disposition", "")).is_empty() else _negotiation_mood()

func record_key(suffix: String) -> String:
	return "%s:%s:%s:%s" % [run_id, daily.get("day", -1), active_id(), suffix]

func enter_event(slot: int) -> void:
	if active_id().is_empty(): return
	daily.slot = slot
	if uses_persuasion():
		if slot == EventManager.EventSlot.NOON: persuasion.begin()
		elif slot == EventManager.EventSlot.AFTERNOON: persuasion.judge()
		changed.emit()
		return
	if slot == EventManager.EventSlot.NOON and daily.get("negotiation", {}).is_empty():
		_begin_negotiation()
	elif slot == EventManager.EventSlot.AFTERNOON:
		_settle_promises()
		_finalize_negotiation()
	changed.emit()

func _begin_negotiation() -> void:
	var profile := _negotiation_profile()
	if profile.is_empty(): return
	var bounds: Array = profile.demand_range
	daily.negotiation = _new_negotiation_state(_rng.randi_range(int(bounds[0]), int(bounds[1])))
	_generate_demand()

func _new_negotiation_state(count: int, status: String = "active") -> Dictionary:
	return {"status": status, "demand_count": count,
		"cursor": 0, "resolved_demand_count": 0, "successful_responses": int(daily.get("successes", 0)),
		"failed_responses": 0, "haggle_count": 0, "refusal_count": 0, "streak": 0,
		"current_demand": {}, "counteroffer": {}, "history": [], "final_disposition": ""}

func negotiation() -> Dictionary:
	return daily.get("negotiation", {})

func current_demand() -> Dictionary:
	if uses_persuasion(): return persuasion.terms()
	var state := negotiation()
	return state.get("counteroffer", {}) if not state.get("counteroffer", {}).is_empty() else state.get("current_demand", {})

func has_open_demand() -> bool:
	if uses_persuasion(): return persuasion.has_terms()
	return negotiation().get("status", "") == "active" and not current_demand().is_empty()

func visitor_available(slot: int) -> bool:
	if active_id().is_empty() or slot not in [EventManager.EventSlot.NOON, EventManager.EventSlot.AFTERNOON]: return false
	return slot == EventManager.EventSlot.AFTERNOON or (persuasion.state().is_empty() or persuasion.has_interaction() if uses_persuasion() else negotiation().is_empty() or has_open_demand())

func _generate_demand() -> void:
	var state := negotiation()
	var profile := _negotiation_profile()
	var templates: Array = profile.get("demands", []).duplicate(true)
	# Next-Deal commitments remain pending until the Afternoon EVENT.
	if int(state.cursor) == int(state.demand_count) - 1 and not profile.get("promises", []).is_empty():
		var promises: Array = profile.promises
		var first := _rng.randi_range(0, promises.size() - 1)
		for offset in promises.size():
			var terms: Dictionary = promises[(first + offset) % promises.size()].duplicate(true)
			var promise := ZodiacDemand.make("PROMISE", "ANY", "PLAYER_CHOOSES", 1, "", int(terms.get("resource_amount", 0)), terms)
			if _resource_legal(promise):
				_publish_demand(promise)
				return
	var order: Array[int] = []
	for index in templates.size(): order.append(index)
	for index in range(order.size() - 1, 0, -1):
		var swap := _rng.randi_range(0, index)
		var temporary := order[index]
		order[index] = order[swap]
		order[swap] = temporary
	for index in order:
		var template: Dictionary = templates[index]
		var demand := ZodiacDemand.make(template.verb, template.get("targeting", "ANY"), template.get("authority", profile.preferred_authority),
			int(template.get("quantity", 1)), template.get("destination", ""), int(template.get("resource_amount", 0)), template.get("metadata", {}))
		if not _resource_legal(demand): continue
		var prepared := ZodiacDemand.prepare(demand, campaign.gieo_que.persistent_deck, _rng)
		if not prepared.is_empty():
			_publish_demand(prepared)
			return
	# No legal/affordable cost: safely end instead of presenting an impossible demand.
	state.status = "awaiting_afternoon" if not daily.promises.is_empty() else "complete"
	state.current_demand = {}
	_finalize_negotiation()

func _publish_demand(demand: Dictionary) -> void:
	demand["id"] = "%d:%d" % [int(daily.day), int(negotiation().cursor)]
	negotiation().current_demand = demand
	negotiation().counteroffer = {}
	progress.commit(active_id(), record_key("seen:" + demand.id), {"requests_seen": 1})

func _resource_legal(demand: Dictionary) -> bool:
	match String(demand.verb):
		"PAY": return int(demand.resource_amount) > 0 and campaign.wallet.balance_vnd >= int(demand.resource_amount)
		"GIFT_RELIC": return campaign.relic_shop.runtime.inventory.has(demand.metadata.get("relic_id", ""))
		"PROMISE":
			if int(daily.get("skip_phase", -1)) == CampaignManager.CampaignPhase.AFTERNOON_DEAL: return false
			var condition := String(demand.metadata.get("condition", ""))
			if condition == "wallet_floor": return campaign.wallet.balance_vnd >= int(demand.resource_amount)
			if condition in ["do_action", "dont_action"]: return demand.metadata.get("action", "") in ["new_meld", "extension", "drink", "discard"]
			return condition == "early_score"
	return demand.verb in ZodiacDemand.CARD_VERBS

func request_kind() -> String:
	return String(current_demand().get("verb", "")).to_lower()

func quote() -> Dictionary:
	if uses_persuasion(): return persuasion.quote()
	if active_id().is_empty(): return {}
	var demand := current_demand()
	var state := negotiation()
	var profile := _negotiation_profile()
	var speech := ZodiacCatalog.words("Sit with me a moment. Here is what I ask of you.", "Ngồi với tôi một lát. Đây là điều tôi muốn nhờ bạn.")
	var contract := ""
	if not demand.is_empty():
		if not state.counteroffer.is_empty(): speech = ZodiacCatalog.words("Then how about this? Take a look before you decide.", "Vậy điều này thì sao? Xem kỹ rồi hãy quyết định.")
		contract = ZodiacDemand.describe(demand)
		contract += "\n" + (ZodiacCatalog.words("Accept: commit to the shown promise. ", "Đồng ý: nhận cam kết đã nêu. ") if demand.verb == "PROMISE" else ZodiacCatalog.words("Accept: this exact cost counts as a pleasing response. ", "Đồng ý: chi phí này được tính là đáp lời vừa ý. "))
		contract += ZodiacCatalog.words("Refuse: free, and your refusal is respected.", "Từ chối: miễn phí, lời từ chối được tôn trọng.") if profile.get("refusal_pleasing", false) else ZodiacCatalog.words("Refuse: free, counts as a displeasing response.", "Từ chối: miễn phí, được tính là đáp lời không vừa ý.")
		if demand.verb == "PROMISE": contract += "\n" + ZodiacCatalog.words("Acceptance reserves the promise; only keeping it earns success.", "Đồng ý nhận cam kết; chỉ giữ lời mới tính thành công.")
	elif not profile.is_empty():
		speech = ZodiacCatalog.words("We have our agreement. I will see you this afternoon.", "Mình đã thỏa thuận xong. Chiều gặp lại nhé.") if int(daily.slot) == EventManager.EventSlot.NOON else ZodiacCatalog.words("Now we know how your promises turned out. Shall we play tonight?", "Giờ đã rõ bạn giữ lời ra sao. Tối nay mình chơi nhé?")
	else:
		speech = ZodiacCatalog.words("I am here to watch the table. We will meet again tonight.", "Tôi tới xem bàn thôi. Tối nay mình gặp lại.")
	return {"kind": request_kind(), "speech": speech, "contract": contract, "demand": demand.duplicate(true),
		"status": "counteroffer" if not state.get("counteroffer", {}).is_empty() else "offered" if has_open_demand() else "complete",
		"can_haggle": has_open_demand() and state.get("counteroffer", {}).is_empty(), "can_time": false}

func selectable_cards(selected_ids: Array = []) -> Array[CardData]:
	if uses_persuasion():
		if not persuasion.has_terms() or current_demand().get("authority", "") != "OFFER_THREE_PLAYER_CHOOSES": return []
		return CardTargetQuery.resolve_ids(campaign.gieo_que.persistent_deck, current_demand().offered_ids)
	var demand := current_demand()
	var available: Array[CardData] = []
	if demand.get("verb", "") not in ZodiacDemand.CARD_VERBS or not ZodiacDemand.player_controls(demand): return available
	var pool := ZodiacDemand.candidates(campaign.gieo_que.persistent_deck, demand)
	if not demand.offered_ids.is_empty(): pool = CardTargetQuery.resolve_ids(pool, demand.offered_ids)
	var selected := CardTargetQuery.resolve_ids(pool, selected_ids)
	if selected.size() != selected_ids.size(): return available
	for card in pool:
		if card.unique_id in selected_ids: continue
		var next: Array[CardData] = selected.duplicate()
		next.append(card)
		if CardTargetQuery.can_complete(pool, next, demand.targeting, demand.quantity): available.append(card)
	return available

func can_accept(ids: Array = []) -> bool:
	if uses_persuasion(): return persuasion.can_accept(ids)
	var demand := current_demand()
	if not has_open_demand() or not _resource_legal(demand): return false
	if demand.verb in ZodiacDemand.CARD_VERBS:
		return ZodiacDemand.selection_valid(campaign.gieo_que.persistent_deck, demand, ids if ZodiacDemand.player_controls(demand) else demand.target_ids)
	return true

func offer_token() -> String:
	if uses_persuasion(): return persuasion.token()
	return "%s:%s" % [current_demand().get("id", ""), "counteroffer" if not negotiation().get("counteroffer", {}).is_empty() else "offered"]

func respond(response: String, target: Variant = "", expected_offer: String = "") -> Dictionary:
	if uses_persuasion():
		var ids: Array = target if target is Array else [target] if target is String and not target.is_empty() else []
		return persuasion.respond(response, ids, expected_offer)
	if _committing or campaign == null or not has_open_demand(): return {"ok": false}
	if not expected_offer.is_empty() and expected_offer != offer_token(): return {"ok": false, "error": "stale_offer"}
	if campaign.current_phase != CampaignManager.CampaignPhase.NOON_EVENT or int(daily.slot) != EventManager.EventSlot.NOON: return {"ok": false}
	if campaign.gieo_que.state not in [GieoQueService.STATE_READY, GieoQueService.STATE_COMPLETE]: return {"ok": false}
	if response not in ["ACCEPT", "REFUSE", "HAGGLE"]: return {"ok": false}
	if response == "HAGGLE": return _haggle()
	var demand := current_demand().duplicate(true)
	var ids: Array = target if target is Array else [target] if target is String and not target.is_empty() else []
	if response == "ACCEPT" and not can_accept(ids): return {"ok": false, "error": "invalid_target_or_resource"}
	_committing = true
	negotiation().status = "committing" # Lock before inventory/wallet callbacks.
	var increments := {}
	var changes: Array[Dictionary] = []
	if response == "REFUSE":
		negotiation().refusal_count += 1
		increments.requests_refused = 1
	elif demand.verb in ZodiacDemand.CARD_VERBS:
		if not ZodiacDemand.player_controls(demand): ids = demand.target_ids
		for card in CardTargetQuery.resolve_ids(campaign.gieo_que.persistent_deck, ids):
			changes.append(ZodiacDemand.apply(card, demand))
	elif demand.verb == "PAY":
		campaign.wallet.apply_vnd(-int(demand.resource_amount), "zodiac_request:" + active_id())
	elif demand.verb == "GIFT_RELIC":
		var relic_id := String(demand.metadata.relic_id)
		campaign.relic_shop.runtime.gift(relic_id)
		increments.relics_gifted = 1
		if _favorite(relic_id): increments.favorite_relics_gifted = 1
	elif demand.verb == "PROMISE":
		daily.promises.append({"id": demand.id, "kind": demand.metadata.condition, "demand": demand,
			"phase": CampaignManager.CampaignPhase.AFTERNOON_DEAL, "started": false, "completed": false, "matched": false, "broken": false,
			"resolution": "COUNTEROFFER" if not negotiation().counteroffer.is_empty() else "ACCEPT"})
		var result := {"ok": true, "pending": true, "resolution_type": "PROMISE_ACCEPTED", "demand": demand}
		daily.last_result = result
		_advance_demand(demand, result)
		_committing = false
		changed.emit()
		return result
	var success: bool = response == "ACCEPT" or _negotiation_profile().get("refusal_pleasing", false)
	var resolution := "COUNTEROFFER" if response == "ACCEPT" and not negotiation().counteroffer.is_empty() else response
	var result := _finish_demand(demand, success, resolution, increments, changes)
	_advance_demand(demand, result)
	_committing = false
	changed.emit()
	return result

func _advance_demand(demand: Dictionary, result: Dictionary) -> void:
	var state := negotiation()
	state.history.append({"demand": demand.duplicate(true), "result": result.duplicate(true)})
	state.cursor += 1
	state.current_demand = {}
	state.counteroffer = {}
	state.status = "active"
	if int(state.cursor) < int(state.demand_count): _generate_demand()
	else:
		state.status = "awaiting_afternoon" if not daily.promises.is_empty() else "complete"
		_finalize_negotiation()

func _finish_demand(demand: Dictionary, success: bool, resolution: String, increments: Dictionary = {}, changes: Array[Dictionary] = []) -> Dictionary:
	var state := negotiation()
	state.resolved_demand_count += 1
	if success:
		state.successful_responses += 1
		state.streak += 1
		daily.successes += 1
		increments.requests_resolved = 1
		if resolution == "REFUSE": increments.requests_refused_successfully = 1
		if resolution == "COUNTEROFFER": increments.counteroffers_accepted = 1
	else:
		state.failed_responses += 1
		state.streak = 0
		increments.requests_failed = 1
	var result := {"ok": true, "resolved_successfully": success, "resolution_type": resolution,
		"demand": demand.duplicate(true), "changes": changes, "counter_increments": increments.duplicate(),
		"memory_tags": [active_id(), "success" if success else "failed", resolution]}
	daily.last_result = result
	progress.commit(active_id(), record_key("demand:" + String(demand.id)), increments)
	return result

func counteroffer_for(demand: Dictionary, strategy: String) -> Dictionary:
	var counter := demand.duplicate(true)
	match strategy:
		"severity":
			if demand.verb != "RESET": return {}
			counter.verb = "REMOVE_PROPERTY"
		"quantity":
			if int(demand.quantity) <= 1: return {}
			counter.quantity -= 1
			if String(demand.targeting).begins_with("SAME_SUIT_"): counter.targeting = "SAME_SUIT_%d" % int(counter.quantity) if int(counter.quantity) > 1 else "ANY"
			elif String(demand.targeting).begins_with("CONSECUTIVE_"): counter.targeting = "CONSECUTIVE_%d" % int(counter.quantity) if int(counter.quantity) > 1 else "ANY"
		"authority":
			if ZodiacDemand.player_controls(demand) or demand.verb not in ZodiacDemand.CARD_VERBS: return {}
			counter.authority = "PLAYER_CHOOSES"
			if counter.targeting == "RANDOM": counter.targeting = "ANY"
		"offer_three":
			if demand.verb not in ZodiacDemand.CARD_VERBS or int(demand.quantity) != 1 or demand.authority == "OFFER_THREE_PLAYER_CHOOSES": return {}
			counter.authority = "OFFER_THREE_PLAYER_CHOOSES"
			counter.targeting = "OFFER_THREE"
		"money":
			if demand.verb != "PAY" or int(demand.resource_amount) <= 1: return {}
			counter.resource_amount = maxi(1, int(demand.resource_amount) / 2)
		"favorite_relic":
			var favorites := favorite_relics()
			if favorites.is_empty() or demand.verb == "GIFT_RELIC": return {}
			counter = ZodiacDemand.make("GIFT_RELIC", "ANY", "PLAYER_CHOOSES", 1, "", 0, {"relic_id": favorites[_rng.randi_range(0, favorites.size() - 1)]})
		"promise":
			if demand.verb != "PROMISE": return {}
			match String(demand.metadata.condition):
				"early_score": counter.metadata = {"condition": "do_action", "action": "new_meld"}
				"wallet_floor": counter.resource_amount = maxi(1, int(demand.resource_amount) / 2)
				"do_action":
					if demand.metadata.action != "extension": return {}
					counter.metadata = {"condition": "do_action", "action": "new_meld"}
				"dont_action": counter = ZodiacDemand.make("PAY", "ANY", "PLAYER_CHOOSES", 1, "", 2500)
				_: return {}
		_: return {}
	if not _resource_legal(counter): return {}
	var prepared := ZodiacDemand.prepare(counter, campaign.gieo_que.persistent_deck, _rng, false)
	if not prepared.is_empty():
		prepared["id"] = demand.get("id", "")
		prepared["haggle_strategy"] = strategy
		# Keep an already revealed physical cost when the gentler terms still
		# permit it. A counteroffer never silently swaps a shown valuable card.
		if prepared.verb in ZodiacDemand.CARD_VERBS and not ZodiacDemand.player_controls(prepared) and not demand.get("target_ids", []).is_empty():
			var stable: Array = demand.target_ids.slice(0, int(prepared.quantity))
			var stable_offer := prepared.duplicate(true)
			stable_offer.target_ids = stable
			if ZodiacDemand.selection_valid(campaign.gieo_que.persistent_deck, stable_offer, stable): prepared.target_ids = stable
	return prepared

func _haggle() -> Dictionary:
	var state := negotiation()
	if not state.counteroffer.is_empty(): return {"ok": false, "error": "counteroffer_requires_confirmation"}
	for strategy: String in _negotiation_profile().get("haggle_tendencies", []):
		var counter := counteroffer_for(current_demand(), strategy)
		if counter.is_empty(): continue
		state.counteroffer = counter
		state.haggle_count += 1
		changed.emit()
		return {"ok": true, "counteroffer": counter.duplicate(true), "requires_confirmation": true}
	return {"ok": false, "error": "no_counteroffer"}

func _favorite(relic_id: String) -> bool:
	var definition: Dictionary = ZodiacCatalog.DEFINITIONS.get(active_id(), {})
	if relic_id in definition.get("favorites", []): return true
	for tag in RelicCatalog.flavor_tags(relic_id):
		if tag in definition.get("favorite_tags", []): return true
	return false

func favorite_relics() -> Array[String]:
	var favorites: Array[String] = []
	if campaign != null:
		for id: String in campaign.relic_shop.runtime.inventory:
			if _favorite(id): favorites.append(id)
	favorites.sort()
	return favorites

func _observe_wallet(_previous: int, current: int, _delta: int, _reason: String) -> void:
	if uses_persuasion(): return
	if active_id().is_empty() or campaign == null: return
	for promise: Dictionary in daily.get("promises", []):
		if promise.get("completed", false): continue
		if not promise.has("demand"):
			if promise.kind == "restraint" and current < 5000: promise["broken"] = true
			continue
		if not promise.get("started", false) or int(promise.phase) != campaign.current_phase: continue
		if promise.kind == "wallet_floor" and current < int(promise.demand.resource_amount): promise.broken = true

func _observe_action(result: Dictionary) -> void:
	if uses_persuasion():
		if result.get("ok", false):
			var ids: Array = result.get("committed_card_ids", [])
			var event_id := record_key("deal:%d:%d:%s" % [campaign.current_phase, deal.action_history.size(), result.get("action", "")])
			persuasion.observe_cards(ids, event_id, "card_use")
			persuasion.observe_action(result, event_id)
		return
	if active_id().is_empty() or campaign == null: return
	for promise: Dictionary in daily.get("promises", []):
		if promise.get("completed", false) or int(promise.phase) != campaign.current_phase: continue
		if promise.has("demand") and not promise.get("started", false): continue
		var action := String(result.get("action", ""))
		var used_drink: bool = result.get("used_drink", false) or action in ["den_da_swap", "nau_da_return", "nhan_tran_swap", "nuoc_voi_return", "sam_dua_selected"] or (action == "discard" and result.get("discard_kind", "") == DiscardRecord.KIND_DRINK_EXTRA)
		match String(promise.kind):
			"early_score":
				if action in ["new_meld", "extension"] and deal.discard_count == 0:
					var context: ScoringContext = result.get("context")
					if context != null and context.final_points > 0: promise["matched"] = true
				elif deal.discard_count > 0 and not promise.get("matched", false): promise["broken"] = true
			"do_action", "dont_action":
				if action == String(promise.demand.metadata.action) or (promise.demand.metadata.action == "drink" and used_drink):
					promise.matched = true
					if promise.kind == "dont_action": promise.broken = true

func finish_daytime_deal(period: String) -> void:
	if uses_persuasion():
		persuasion.finish_deal(period)
		return
	if period != "afternoon": return
	for promise: Dictionary in daily.get("promises", []):
		if promise.get("started", false): promise.completed = true

func _settle_promises() -> void:
	if daily.get("promises", []).is_empty(): return
	if negotiation().is_empty():
		daily.negotiation = _new_negotiation_state(daily.promises.size(), "awaiting_afternoon")
		negotiation().cursor = daily.promises.size()
	for promise: Dictionary in daily.promises.duplicate(true):
		var legacy := not promise.has("demand")
		var demand: Dictionary = promise.get("demand", ZodiacDemand.make("PROMISE"))
		if legacy:
			demand["id"] = "legacy:%d" % int(promise.get("slot", 1))
			demand.metadata = {"condition": "wallet_floor" if promise.kind == "restraint" else "early_score"}
		var success := not bool(promise.get("broken", false))
		if legacy: success = success and (campaign.wallet.balance_vnd >= 5000 if promise.kind == "restraint" else bool(promise.get("matched", false)))
		else:
			success = success and promise.get("started", false) and promise.get("completed", false)
			if promise.kind in ["early_score", "do_action"]: success = success and promise.get("matched", false)
		var increments := {}
		if success and demand.metadata.condition == "wallet_floor": increments.restraint_kept = 1
		if success and demand.metadata.condition == "early_score": increments.early_scores = 1
		var result := _finish_demand(demand, success, "PROMISE_KEPT" if success else "PROMISE_BROKEN", increments)
		for record: Dictionary in negotiation().history:
			if record.demand.get("id", "") == demand.id: record.result = result.duplicate(true)
		daily.promises.erase(promise)
	_finalize_negotiation()

func _finalize_negotiation() -> void:
	var state := negotiation()
	if state.is_empty() or not daily.get("promises", []).is_empty() or state.get("status", "") == "active": return
	state.status = "complete"
	state.final_disposition = _negotiation_mood()

func _negotiation_mood() -> String:
	var profile := _negotiation_profile()
	var thresholds: Array = profile.get("thresholds", ZodiacCatalog.DEFINITIONS.get(active_id(), {}).get("thresholds", [1, 2]))
	var successes := int(negotiation().get("successful_responses", daily.get("successes", 0)))
	return "PLEASED" if successes >= int(thresholds[1]) else "NORMAL" if successes >= int(thresholds[0]) else "UNPLEASED"

func debug_offer(template: Dictionary) -> Dictionary:
	if uses_persuasion(): return {}
	if campaign == null or campaign.current_phase != CampaignManager.CampaignPhase.NOON_EVENT or negotiation().is_empty() or _committing: return {}
	var prepared := ZodiacDemand.prepare(template, campaign.gieo_que.persistent_deck, _rng, false) if _resource_legal(template) else {}
	if prepared.is_empty(): return {}
	negotiation().status = "active"
	_publish_demand(prepared)
	changed.emit()
	return prepared.duplicate(true)

func consume_skip(phase: int) -> bool:
	if active_id().is_empty() or phase == CampaignManager.CampaignPhase.EVENING_DEAL or int(daily.skip_phase) != phase: return false
	daily.skip_phase = -1
	daily.skipped.append(phase)
	changed.emit()
	return true

func prepare_deal(period: String) -> void:
	if deal == null: return
	if uses_persuasion(): persuasion.start_deal(period)
	if period == "afternoon" and not uses_persuasion():
		for promise: Dictionary in daily.get("promises", []):
			if promise.get("started", false): continue
			promise["started"] = true
			if promise.kind in ["restraint", "wallet_floor"]:
				promise["broken"] = campaign.wallet.balance_vnd < int(promise.get("demand", {}).get("resource_amount", 5000))
	deal.zodiac_boss.configure("dragon" if period == "dragon" else active_id() if period == "evening" else "", int(endgame.get("difficulty", difficulty())) if period == "dragon" else difficulty(), campaign.seed_for("zodiac_boss_dragon" if period == "dragon" else "zodiac_boss", campaign.current_day_index))
	if period == "dragon":
		var actions: Array = []
		for report: Dictionary in campaign.deal_reports: actions.append_array(report.get("details", {}).get("actions", []))
		deal.zodiac_boss.data.analysis = preload("res://scripts/zodiac/dragon_analysis.gd").analyze(actions, deal.zodiac_boss.difficulty)
		endgame["analysis"] = deal.zodiac_boss.data.analysis.duplicate(true)

func finish_boss() -> void:
	if active_id().is_empty() or daily.boss_finished: return
	if deal == null or deal.state != DealState.STATE_DEAL_OVER or deal.zodiac_boss.id != active_id(): return
	daily.boss_finished = true
	# This solo game's victory contract is completing both Phases of the boss Deal.
	var counters := {mood().to_lower() + "_victories": 1}
	var state := negotiation()
	if not uses_persuasion() and not state.is_empty() and int(state.resolved_demand_count) >= int(state.demand_count) and int(state.failed_responses) == 0: counters.perfect_request_days = 1
	progress.commit(active_id(), record_key("boss"), counters)
	if active_id() == "snake": endgame = {"status": "choice", "day": campaign.current_day_index, "difficulty": deal.zodiac_boss.difficulty}
	changed.emit()

func complete_scene() -> bool:
	if active_id() == "cat": return false # Cat Special/Emblem content has not been authored for this system.
	if active_id().is_empty() or not bool(progress.record(active_id()).get("special_scene_unlocked", false)) or progress.owns(active_id()): return false
	progress.commit(active_id(), "emblem:" + active_id(), {}, ["special_scene_completed", "emblem_unlocked"])
	changed.emit()
	return true

func snapshot() -> Dictionary:
	return {"version": 4, "conversation_history": conversation_history.duplicate(), "daily": daily.duplicate(true), "rng_state": _rng.state, "forced": forced.duplicate(), "run_id": run_id, "endgame": endgame.duplicate(true), "progress": progress.snapshot()}

func restore(data: Dictionary) -> void:
	daily = data.get("daily", {}).duplicate(true)
	conversation_history = data.get("conversation_history", {}).duplicate()
	# Finish already-started legacy costs and promises under their original terms.
	# A pre-Noon old save can enter the new authored engine without replaying anything.
	var previous_engine: bool = (active_id() == "cat" and int(data.get("version", 1)) < 3) or (active_id() == "rooster" and int(data.get("version", 1)) < 4 and daily.get("persuasion", {}).is_empty())
	if previous_engine:
		var legacy_noon_state: Dictionary = daily.get("requests", {}).get(EventManager.EventSlot.NOON, {})
		if not negotiation().is_empty() or not daily.get("promises", []).is_empty() or legacy_noon_state.get("status", "offered") != "offered": daily["legacy_negotiation"] = true
	if negotiation().get("final_disposition", "") == "NEUTRAL": negotiation().final_disposition = "NORMAL"
	forced = data.get("forced", {}).duplicate()
	run_id = data.get("run_id", "")
	endgame = data.get("endgame", {}).duplicate(true)
	if data.has("rng_state"): _rng.state = int(data.rng_state)
	elif campaign != null: _rng.seed = campaign.seed_for("zodiac_negotiation", int(daily.get("day", 0)))
	progress.merge(data.get("progress", {}))
	# A paid/resolved old Noon visit must not turn into a second bill on resume.
	var legacy_noon: Dictionary = daily.get("requests", {}).get(EventManager.EventSlot.NOON, {})
	if int(data.get("version", 1)) < 2 and negotiation().is_empty() and legacy_noon.get("status", "offered") != "offered":
		var resolved := 0
		var failed := 0
		for request: Dictionary in daily.get("requests", {}).values():
			if request.get("status", "") in ["success", "failed"]: resolved += 1
			if request.get("status", "") == "failed": failed += 1
		daily.negotiation = _new_negotiation_state(resolved + daily.get("promises", []).size(), "awaiting_afternoon")
		negotiation().cursor = negotiation().demand_count
		negotiation().resolved_demand_count = resolved
		negotiation().failed_responses = failed
		_finalize_negotiation()


func difficulty() -> int:
	return ZodiacCatalog.difficulty_value(mood())

func finish_dragon() -> void:
	if endgame.get("status", "") != "active" or deal == null or deal.state != DealState.STATE_DEAL_OVER: return
	var won: bool = deal.zodiac_boss.data.get("victory", false)
	endgame.status = "victory" if won else "failed"
	endgame["analysis"] = deal.zodiac_boss.data.get("analysis", {}).duplicate(true)
	if won:
		progress.commit("dragon", record_key("dragon_ending"), {"victories": 1}, ["ending_rong_ran_len_may"])
	changed.emit()

func begin_run_restore() -> void:
	_restoring = true

func finish_run_restore() -> void:
	rebind_observers()
	_restoring = false
