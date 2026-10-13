extends SceneTree
## Every run-state pair is written and read by different Godot processes.
const FLOW := preload("res://tests/monkey_dog_test_flow.gd")
const EXPECTED := "user://monkey_dog_expected.values"
const CASES := ["question", "reaction", "counteroffer", "accepted", "partial", "matched", "judged", "broken",
	"card_offer", "selection", "card_accepted", "recall", "last_chance", "legacy_noon"]
var checks := 0
var failures: Array[String] = []

func _initialize() -> void:
	call_deferred("_run")

func _check(ok: bool, message: String) -> void:
	checks += 1
	if not ok: failures.append(message); push_error(message)

func _action_node(id: String) -> String:
	return id + ".t1plus." + ("variety" if id == "monkey" else "build")

func _card_node(id: String) -> String:
	return id + ".t1plus." + ("pick" if id == "monkey" else "card")

func _topic(id: String) -> String:
	return id + "." + ("variety" if id == "monkey" else "build")

func _kindred(service: ZodiacService) -> void:
	var id := service.active_id()
	var topics: Array = ZodiacCatalog.persuasion_config(id).progression[0].promises
	service.progress.commit(id, "resume:varied:" + id,
		{"promises_kept": 2, "promise_kept:" + topics[0]: 1, "promise_kept:" + topics[1]: 1})
	service.progress.record_disposition(id, "resume:kindred:" + id, "NORMAL")

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
	for id: String in ["monkey", "dog"]:
		for case: String in CASES:
			var key := id + "_" + case
			var owner := FLOW.campaign(id, case not in ["question", "reaction"], writing)
			var service := owner.zodiac
			var save := RunSave.new("user://monkey_dog_%s.save" % key)
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
						_check(FLOW.meld(owner).ok, "real first Meld " + key)
						if case in ["matched", "judged", "recall"]: _check(FLOW.extension(owner).ok, "real Extension " + key)
						if case in ["judged", "broken", "recall"]: _check(FLOW.finish(owner), "complete actual two-Phase Deal " + key)
						if case == "recall":
							_kindred(service)
							var seed_text := owner.run_seed
							owner.start_campaign(true, seed_text)
							owner.current_day_index = 1
							service.begin_day(1, owner.seed_for("zodiac_selection", 1))
							owner._enter_phase(CampaignManager.CampaignPhase.NOON_EVENT)
							FLOW.node(owner, id + ".t2." + ("variety_memory" if id == "monkey" else "build_memory"))
					"card_offer", "selection", "card_accepted":
						FLOW.terms(owner, _card_node(id))
						if case != "card_offer": service.persuasion.select_card(service.current_demand().offered_ids[0])
						if case == "card_accepted":
							service.respond("ACCEPT", service.persuasion.state().selection)
							service.continue_conversation()
					"last_chance": service.persuasion.apply_patience(-3)
					"legacy_noon":
						service.daily.erase("persuasion")
						service.daily["legacy_negotiation"] = true
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
						_check(service.current_demand().condition == "do_action" and not service.persuasion.can_haggle(), "saved alternate terms " + key)
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
					"legacy_noon":
						_check(not service.uses_persuasion() and service.mood() == "NORMAL", "old empty visit stays unchanged " + key)
				for suffix in ["", ".bak", ".tmp"]: DirAccess.remove_absolute(save.path + suffix)
	var files := MetaSaveFiles.new("user://monkey_dog_profiles", "")
	if writing:
		for id: String in ["monkey", "dog"]:
			var owner := FLOW.campaign(id, true, true, files)
			FLOW.accept(owner, _action_node(id))
			FLOW.afternoon(owner)
			FLOW.meld(owner)
			FLOW.extension(owner)
			_check(FLOW.finish(owner), "permanent profile actual Deal " + id)
			_kindred(owner.zodiac)
			expected["profile"] = owner.zodiac.progress.snapshot()
			_check(files.error.is_empty(), "permanent profile saved " + id)
		var destination := FileAccess.open(EXPECTED, FileAccess.WRITE)
		destination.store_var(expected, false)
		destination.close()
	else:
		var owner := FLOW.campaign("monkey", false, false, files)
		_check(owner.zodiac.progress.snapshot().memories == expected.profile.memories, "both permanent memories loaded independently of run saves")
		for id: String in ["monkey", "dog"]:
			_check(owner.zodiac.progress.relationship_tier(id) == ZodiacProgress.KINDRED, "permanent Kindred " + id)
		_check(files.select(2, owner) and owner.zodiac.progress.memories.is_empty(), "File 2 has no File 1 memories")
		_check(files.select(1, owner) and owner.zodiac.progress.snapshot().memories == expected.profile.memories, "File 1 restores both characters")
		DirAccess.remove_absolute(EXPECTED)
	print("MONKEY_DOG_PERSUASION_RESUME_%s checks=%d failures=%d" % ["WRITE" if writing else "READ", checks, failures.size()])
	for failure in failures: print("MONKEY_DOG_RESUME_FAIL " + failure)
	quit(0 if failures.is_empty() else 1)
