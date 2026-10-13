extends SceneTree
## Every run-state pair is written and read by different Godot processes.
const FLOW := preload("res://tests/rat_tiger_test_flow.gd")
const EXPECTED := "user://rat_tiger_expected.values"
const CASES := ["question", "reaction", "counteroffer", "accepted", "partial", "matched", "judged", "broken",
	"card_offer", "selection", "card_accepted", "recall", "last_chance", "legacy_noon",
	"side_offer", "side_accepted", "side_evidence", "side_judged", "card_matched", "card_missed", "card_partial", "primary_closed"]
var checks := 0
var failures: Array[String] = []

func _initialize() -> void:
	call_deferred("_run")

func _check(ok: bool, message: String) -> void:
	checks += 1
	if not ok: failures.append(message); push_error(message)

func _action_node(id: String) -> String:
	return id + ".t1plus." + ("reuse" if id == "rat" else "high")

func _card_node(id: String) -> String:
	return id + ".t1plus." + "card"

func _topic(id: String) -> String:
	return id + "." + ("reuse" if id == "rat" else "high")

func _kindred(service: ZodiacService) -> void:
	var id := service.active_id()
	var topics: Array = ZodiacCatalog.persuasion_config(id).progression[0].promises
	service.progress.commit(id, "resume:varied:" + id,
		{"promises_kept": 2, "promise_kept:" + topics[0]: 1, "promise_kept:" + topics[1]: 1})
	service.progress.record_disposition(id, "resume:kindred:" + id, "NORMAL")

func _chosen_deal(owner: CampaignManager, chosen: String) -> void:
	FLOW.chosen_deal(owner, chosen)

func _record(owner: CampaignManager) -> Dictionary:
	var service := owner.zodiac
	return {"daily": service.daily.duplicate(true), "rng": service._rng.state, "quote": service.quote(),
		"conversation": service.conversation_history.duplicate(), "progress": service.progress.snapshot(),
		"mood": service.mood(), "wallet": owner.wallet.balance_vnd, "phase": owner.current_phase,
		"uses_persuasion": service.uses_persuasion()}

func _run() -> void:
	var writing := "--write" in OS.get_cmdline_user_args()
	var expected := {}
	if not writing:
		var source := FileAccess.open(EXPECTED, FileAccess.READ)
		if source == null:
			_check(false, "fresh-process expectations exist")
			quit(1)
			return
		expected = source.get_var(false)
		source.close()
	for id: String in ["rat", "tiger"]:
		for case: String in CASES:
			var key := id + "_" + case
			var owner := FLOW.campaign(id, case not in ["question", "reaction"], writing)
			var service := owner.zodiac
			var save := RunSave.new("user://rat_tiger_%s.save" % key)
			if writing:
				match case:
					"reaction": service.answer_question("A")
					"counteroffer":
						FLOW.terms(owner, _action_node(id))
						service.respond("HAGGLE")
					"accepted": FLOW.accept(owner, _action_node(id))
					"partial", "matched", "judged", "broken", "recall":
						FLOW.accept(owner, _action_node(id))
						FLOW.afternoon(owner)
						_check(FLOW.first(owner).ok, "real first recovery or lower-rank play " + key)
						if case in ["matched", "judged", "recall"]:
							_check(FLOW.next(owner).ok, "real next committed action " + key)
						if case in ["judged", "broken", "recall"]: _check(FLOW.finish(owner), "complete actual two-Phase Deal " + key)
						if case == "recall":
							_kindred(service)
							var seed_text := owner.run_seed
							owner.start_campaign(true, seed_text)
							owner.current_day_index = 4
							service.begin_day(4, owner.seed_for("zodiac_selection", 4))
							owner._enter_phase(CampaignManager.CampaignPhase.NOON_EVENT)
							FLOW.node(owner, id + ".t2." + ("reuse_memory" if id == "rat" else "high_memory"))
					"card_offer", "selection", "card_accepted":
						FLOW.terms(owner, _card_node(id))
						if case != "card_offer": service.persuasion.select_card(service.current_demand().offered_ids[0])
						if case == "card_accepted":
							service.respond("ACCEPT", service.persuasion.state().selection)
							service.continue_conversation()
					"side_offer", "side_accepted", "side_evidence", "side_judged":
						FLOW.terms(owner, id + ".t1plus." + ("extend" if id == "rat" else "stand"))
						if case != "side_offer":
							service.respond("ACCEPT")
							service.continue_conversation()
						if case in ["side_evidence", "side_judged"]:
							FLOW.afternoon(owner)
							FLOW.meld(owner)
							if id == "rat":
								_check(FLOW.extension(owner).ok, "real first added card " + key)
								if case == "side_judged":
									_check(service.deal.extend_meld(service.deal.melds[0].meld_id, FLOW.cards(service.deal.hand, [["7", "Hearts"]])).ok, "real second added card " + key)
							else:
								_check(service.deal.create_meld(FLOW.cards(service.deal.hand, [["K", "Hearts"], ["K", "Diamonds"], ["K", "Clubs"], ["K", "Spades"]])).ok, "real new four-card group " + key)
							if case == "side_judged": _check(FLOW.finish(owner), "actual side commitment return " + key)
					"card_matched", "card_missed", "card_partial":
						FLOW.terms(owner, _card_node(id))
						var chosen: String = service.current_demand().offered_ids[0]
						service.respond("ACCEPT", [chosen])
						service.continue_conversation()
						_chosen_deal(owner, chosen)
						if case == "card_matched":
							_check(FLOW.chosen_play(owner, chosen), "chosen physical card actual committed play " + key)
						else:
							_check(service.deal.create_meld(service.deal.hand.slice(0, 4 if id == "rat" else 3)).ok, "unfulfilled first card play " + key)
							if case == "card_partial" and id == "rat": _check(FLOW.recover_chosen(owner, chosen).ok, "chosen recovery awaits later play " + key)
							if case == "card_missed" and id == "tiger": _check(service.deal.extend_meld(service.deal.melds[0].meld_id, service.deal.hand.slice(0, 1)).ok, "later size cannot replace new group " + key)
							_check(not service.daily.promises[0].matched, "choice still pending before save " + key)
					"primary_closed":
						FLOW.accept(owner, _action_node(id))
						FLOW.afternoon(owner)
						_check(FLOW.first(owner).ok, "real partial evidence before closing " + key)
						var closing: CardData = FLOW.cards(service.deal.hand, [["3", "Hearts"]] if id == "rat" else [["9", "Hearts"]])[0]
						_check(service.deal.discard_card(closing).ok, "returned card discarded or first deadline closed " + key)
					"last_chance": service.persuasion.apply_patience(-3)
					"legacy_noon":
						var old := service.snapshot()
						old.version = 7
						old.daily.erase("persuasion")
						service.restore(old)
				expected[key] = _record(owner)
				_check(save.save_run(owner, service.deal), "write " + key)
			else:
				_check(save.restore(save.load_run(), owner, service.deal), "restore " + key)
				_check(_record(owner) == expected[key], "exact dialogue, terms, evidence, memory and RNG " + key)
				match case:
					"reaction":
						_check(not service.answer_question("A").ok, "answer cannot replay " + key)
					"counteroffer":
						var token := service.offer_token()
						_check(service.current_demand().condition == ("recover_then_play" if id == "rat" else "opening_high_rank") and not service.persuasion.can_haggle(), "saved alternate terms " + key)
						_check(service.respond("ACCEPT", [], token).pending, "resumed explicit acceptance " + key)
						_check(not service.respond("ACCEPT", [], token).ok and service.daily.promises.size() == 1, "reserve once " + key)
					"accepted":
						_check(not service.daily.promises[0].started and not service.daily.promises[0].matched, "acceptance is not action evidence " + key)
					"partial", "matched":
						_check(service.daily.promises[0].matched == (case == "matched"), "real evidence survives " + key)
						_check(FLOW.finish(owner), "finish resumed actual Deal " + key)
						_check(service.progress.memory(id, _topic(id)).result == ("FULFILLED" if case == "matched" else "BROKEN"), "resumed settlement " + key)
					"judged", "broken":
						var before := _record(owner)
						service.enter_event(EventManager.EventSlot.AFTERNOON)
						_check(_record(owner) == before, "judgment cannot replay " + key)
					"card_offer":
						_check(not service.can_accept() and service.current_demand().offered_ids.size() == 3, "offer resumes without invented choice " + key)
					"selection":
						var chosen: Array = service.persuasion.state().selection
						_check(chosen.size() == 1 and service.can_accept(chosen), "selected physical card survives " + key)
						_check(service.respond("ACCEPT", chosen).pending and service.daily.promises[0].target_ids == chosen, "resumed card confirmation " + key)
					"card_accepted":
						_check(service.daily.promises[0].target_ids.size() == 1 and not service.daily.promises[0].matched, "physical obligation resumes " + key)
					"recall":
						_check(service.progress.relationship_tier(id) == ZodiacProgress.KINDRED, "Kindred survives New Run " + key)
						_check(service.persuasion.state().node.bound_memory.result == "FULFILLED" and not service.quote().speech.contains("{target}"), "real bound recall survives " + key)
					"last_chance":
						var token := service.offer_token()
						_check(service.persuasion.resolve_last_chance("B", token), "saved honest recovery " + key)
						_check(not service.persuasion.resolve_last_chance("B", token) and service.persuasion.state().patience == 1, "recovery once " + key)
					"side_offer":
						_check(service.has_open_demand() and service.current_demand().card_count == (2 if id == "rat" else 4), "exact side terms " + key)
					"side_accepted":
						_check(not service.daily.promises[0].matched and not service.daily.promises[0].outcome_applied, "side acceptance is not fulfillment " + key)
					"side_evidence":
						var pending: Dictionary = service.daily.promises[0]
						_check(pending.extended_ids.size() == 1 and not pending.matched if id == "rat" else pending.matched, "actual added-card or four-card group evidence persisted " + key)
						if id == "rat": _check(service.deal.extend_meld(service.deal.melds[0].meld_id, FLOW.cards(service.deal.hand, [["7", "Hearts"]])).ok, "resume second distinct addition " + key)
						_check(FLOW.finish(owner), "finish resumed side Deal " + key)
						_check(service.progress.memory(id, id + "." + ("extend" if id == "rat" else "stand")).result == "FULFILLED", "settle actual side evidence " + key)
					"side_judged":
						var before := _record(owner)
						service.enter_event(EventManager.EventSlot.AFTERNOON)
						_check(_record(owner) == before, "side outcome cannot replay " + key)
					"card_matched", "card_missed":
						_check(service.daily.promises[0].matched == (case == "card_matched"), "saved exact physical evidence " + key)
						_check(FLOW.finish(owner), "finish resumed chosen-card Deal " + key)
						_check(service.progress.memory(id, id + ".card").result == ("FULFILLED" if case == "card_matched" else "BROKEN"), "resumed card judgment " + key)
					"card_partial":
						var chosen: String = service.daily.promises[0].target_ids[0]
						_check(not service.daily.promises[0].matched, "partial obligation survives " + key)
						if id == "rat":
							_check(chosen in service.daily.promises[0].recovered_ids, "exact physical recovery survives " + key)
							_check(service.deal.extend_meld(service.deal.melds[0].meld_id, CardTargetQuery.resolve_ids(service.deal.hand, [chosen])).ok, "resumed recovered card real Extension " + key)
						else:
							service.deal.set_current_drink(DrinkCatalog.NAU_DA)
							_check(service.deal.use_nau_da(service.deal.melds[0].meld_id).ok, "real recovery of too-small group " + key)
							_check(service.deal.create_meld(FLOW.cards(service.deal.hand, service.deal.hand.filter(func(c: CardData): return c.rank == CardTargetQuery.resolve_ids(service.deal.hand, [chosen])[0].rank).map(func(c: CardData): return [c.rank, c.suit]))).ok, "resumed true four-card creation " + key)
						_check(service.daily.promises[0].matched, "resume supplies missing committed evidence " + key)
						_check(FLOW.finish(owner), "actual partial-card return " + key)
						_check(service.progress.memory(id, id + ".card").result == "FULFILLED", "partial card judged once " + key)
					"primary_closed":
						_check(not service.daily.promises[0].matched, "closed primary stays unmatched " + key)
						if id == "tiger": _check(service.daily.promises[0].broken and service.daily.promises[0].opening_ids.size() == 4, "original targets and missed deadline survive " + key)
						_check(FLOW.finish(owner), "complete closed primary actual Deal " + key)
						_check(service.progress.memory(id, _topic(id)).result == "BROKEN", "closed evidence cannot fulfill on restore " + key)
					"legacy_noon":
						_check(not service.uses_persuasion() and service.mood() == "NORMAL", "old empty visit stays unchanged " + key)
				for suffix in ["", ".bak", ".tmp"]: DirAccess.remove_absolute(save.path + suffix)
	var files := MetaSaveFiles.new("user://rat_tiger_profiles", "")
	if writing:
		for id: String in ["rat", "tiger"]:
			var owner := FLOW.campaign(id, true, true, files)
			FLOW.accept(owner, _action_node(id))
			FLOW.afternoon(owner)
			FLOW.first(owner)
			FLOW.next(owner)
			_check(FLOW.finish(owner), "permanent profile actual Deal " + id)
			_kindred(owner.zodiac)
			expected["profile"] = owner.zodiac.progress.snapshot()
			_check(files.error.is_empty(), "permanent profile saved " + id + ": " + files.error)
		var destination := FileAccess.open(EXPECTED, FileAccess.WRITE)
		destination.store_var(expected, false)
		destination.close()
	else:
		var owner := FLOW.campaign("rat", false, false, files)
		_check(owner.zodiac.progress.snapshot().memories == expected.profile.memories, "both permanent memories loaded independently of run saves")
		for id: String in ["rat", "tiger"]:
			_check(owner.zodiac.progress.relationship_tier(id) == ZodiacProgress.KINDRED, "permanent Kindred " + id)
		_check(files.select(2, owner) and owner.zodiac.progress.memories.is_empty(), "File 2 has no File 1 memories")
		_check(files.select(1, owner) and owner.zodiac.progress.snapshot().memories == expected.profile.memories, "File 1 restores both characters")
		DirAccess.remove_absolute(EXPECTED)
	print("RAT_TIGER_PERSUASION_RESUME_%s checks=%d failures=%d" % ["WRITE" if writing else "READ", checks, failures.size()])
	for failure in failures: print("RAT_TIGER_RESUME_FAIL " + failure)
	quit(0 if failures.is_empty() else 1)
