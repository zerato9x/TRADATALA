extends SceneTree
## Every run-state pair is written and read by different Godot processes.
const FLOW := preload("res://tests/horse_goat_test_flow.gd")
const EXPECTED := "user://horse_goat_expected.values"
const CASES := ["question", "reaction", "counteroffer", "accepted", "partial", "matched", "judged", "broken",
	"card_offer", "selection", "card_accepted", "recall", "last_chance", "legacy_noon",
	"side_offer", "side_accepted", "side_evidence", "side_judged", "card_matched", "card_missed"]
var checks := 0
var failures: Array[String] = []

func _initialize() -> void:
	call_deferred("_run")

func _check(ok: bool, message: String) -> void:
	checks += 1
	if not ok: failures.append(message); push_error(message)

func _action_node(id: String) -> String:
	return id + ".t1plus." + ("pair" if id == "horse" else "notes")

func _card_node(id: String) -> String:
	return id + ".t1plus." + "card"

func _topic(id: String) -> String:
	return id + "." + ("pair" if id == "horse" else "notes")

func _kindred(service: ZodiacService) -> void:
	var id := service.active_id()
	var topics: Array = ZodiacCatalog.persuasion_config(id).progression[0].promises
	service.progress.commit(id, "resume:varied:" + id,
		{"promises_kept": 2, "promise_kept:" + topics[0]: 1, "promise_kept:" + topics[1]: 1})
	service.progress.record_disposition(id, "resume:kindred:" + id, "NORMAL")

func _chosen_deal(owner: CampaignManager, chosen: String, mismatch: bool = false) -> void:
	FLOW.chosen_deal(owner, chosen, mismatch)

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
	for id: String in ["horse", "goat"]:
		for case: String in CASES:
			var key := id + "_" + case
			var owner := FLOW.campaign(id, case not in ["question", "reaction"], writing)
			var service := owner.zodiac
			var save := RunSave.new("user://horse_goat_%s.save" % key)
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
						_check(FLOW.first(owner).ok, "real first scoring action " + key)
						if case in ["matched", "judged", "recall"]:
							_check(FLOW.next(owner).ok, "real next committed action " + key)
						if case in ["judged", "broken", "recall"]: _check(FLOW.finish(owner), "complete actual two-Phase Deal " + key)
						if case == "recall":
							_kindred(service)
							var seed_text := owner.run_seed
							owner.start_campaign(true, seed_text)
							owner.current_day_index = 3
							service.begin_day(3, owner.seed_for("zodiac_selection", 3))
							owner._enter_phase(CampaignManager.CampaignPhase.NOON_EVENT)
							FLOW.node(owner, id + ".t2." + ("pair_memory" if id == "horse" else "notes_memory"))
					"card_offer", "selection", "card_accepted":
						FLOW.terms(owner, _card_node(id))
						if case != "card_offer": service.persuasion.select_card(service.current_demand().offered_ids[0])
						if case == "card_accepted":
							service.respond("ACCEPT", service.persuasion.state().selection)
							service.continue_conversation()
					"side_offer", "side_accepted", "side_evidence", "side_judged":
						FLOW.terms(owner, id + ".t1plus." + ("pace" if id == "horse" else "run"))
						if case != "side_offer":
							service.respond("ACCEPT")
							service.continue_conversation()
						if case in ["side_evidence", "side_judged"]:
							FLOW.afternoon(owner)
							FLOW.meld(owner)
							if id == "horse":
								_check(service.deal.discard_card(FLOW.cards(service.deal.hand, [["K", "Clubs"]])[0]).ok, "same-Turn deadline actually closes " + key)
								_check(FLOW.extension(owner).ok, "later Extension cannot repair " + key)
							else:
								_check(service.daily.promises[0].matched, "real consecutive phrase " + key)
							if case == "side_judged": _check(FLOW.finish(owner), "actual side commitment return " + key)
					"card_matched", "card_missed":
						FLOW.terms(owner, _card_node(id))
						var chosen: String = service.current_demand().offered_ids[0]
						service.respond("ACCEPT", [chosen])
						service.continue_conversation()
						_chosen_deal(owner, chosen, case == "card_missed" and id == "goat")
						if case == "card_matched":
							_check(FLOW.chosen_play(owner, chosen), "chosen physical card actual committed play " + key)
						else:
							var wrong: Array[CardData] = service.deal.hand.slice(1, 4) if id == "horse" else service.deal.hand.slice(0, 3)
							_check(service.deal.create_meld(wrong).ok, "wrong action or no adjacent new rank " + key)
							_check(not service.daily.promises[0].matched, "choice unmet before save " + key)
					"last_chance": service.persuasion.apply_patience(-3)
					"legacy_noon":
						var old := service.snapshot()
						old.version = 6
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
						_check(service.current_demand().condition == ("same_turn_actions" if id == "horse" else "distinct_ranks") and not service.persuasion.can_haggle(), "saved alternate terms " + key)
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
						_check(service.has_open_demand() and service.current_demand().get("same_turn", service.current_demand().get("rank_count")) == (true if id == "horse" else 3), "exact side terms " + key)
					"side_accepted":
						_check(not service.daily.promises[0].matched and not service.daily.promises[0].outcome_applied, "side acceptance is not fulfillment " + key)
					"side_evidence":
						var pending: Dictionary = service.daily.promises[0]
						_check(pending.broken if id == "horse" else pending.matched, "same-Turn breach or committed rank phrase persisted " + key)
						_check(FLOW.finish(owner), "finish resumed side Deal " + key)
						_check(service.progress.memory(id, id + "." + ("pace" if id == "horse" else "run")).result == ("BROKEN" if id == "horse" else "FULFILLED"), "settle actual side evidence " + key)
					"side_judged":
						var before := _record(owner)
						service.enter_event(EventManager.EventSlot.AFTERNOON)
						_check(_record(owner) == before, "side outcome cannot replay " + key)
					"card_matched", "card_missed":
						_check(service.daily.promises[0].matched == (case == "card_matched"), "saved exact physical evidence " + key)
						_check(FLOW.finish(owner), "finish resumed chosen-card Deal " + key)
						_check(service.progress.memory(id, id + ".card").result == ("FULFILLED" if case == "card_matched" else "BROKEN"), "resumed card judgment " + key)
					"legacy_noon":
						_check(not service.uses_persuasion() and service.mood() == "NORMAL", "old empty visit stays unchanged " + key)
				for suffix in ["", ".bak", ".tmp"]: DirAccess.remove_absolute(save.path + suffix)
	var files := MetaSaveFiles.new("user://horse_goat_profiles", "")
	if writing:
		for id: String in ["horse", "goat"]:
			var owner := FLOW.campaign(id, true, true, files)
			FLOW.accept(owner, _action_node(id))
			FLOW.afternoon(owner)
			FLOW.first(owner)
			FLOW.next(owner)
			_check(FLOW.finish(owner), "permanent profile actual Deal " + id)
			_kindred(owner.zodiac)
			expected["profile"] = owner.zodiac.progress.snapshot()
			_check(files.error.is_empty(), "permanent profile saved " + id)
		var destination := FileAccess.open(EXPECTED, FileAccess.WRITE)
		destination.store_var(expected, false)
		destination.close()
	else:
		var owner := FLOW.campaign("horse", false, false, files)
		_check(owner.zodiac.progress.snapshot().memories == expected.profile.memories, "both permanent memories loaded independently of run saves")
		for id: String in ["horse", "goat"]:
			_check(owner.zodiac.progress.relationship_tier(id) == ZodiacProgress.KINDRED, "permanent Kindred " + id)
		_check(files.select(2, owner) and owner.zodiac.progress.memories.is_empty(), "File 2 has no File 1 memories")
		_check(files.select(1, owner) and owner.zodiac.progress.snapshot().memories == expected.profile.memories, "File 1 restores both characters")
		DirAccess.remove_absolute(EXPECTED)
	print("HORSE_GOAT_PERSUASION_RESUME_%s checks=%d failures=%d" % ["WRITE" if writing else "READ", checks, failures.size()])
	for failure in failures: print("HORSE_GOAT_RESUME_FAIL " + failure)
	quit(0 if failures.is_empty() else 1)
