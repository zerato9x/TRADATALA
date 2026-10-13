extends SceneTree
## Separate writer and reader processes exercise real RunSave and MetaSaveFiles.
const FLOW := preload("res://tests/snake_test_flow.gd")
const EXPECTED := "user://snake_expected.values"
const CASES := ["question", "reaction", "counteroffer", "accepted", "partial", "two_notes", "matched", "judged", "wrong_middle", "incomplete",
	"card_offer", "selection", "card_accepted", "card_partial", "card_matched", "card_wrong",
	"still_offer", "still_partial", "still_broken", "still_judged", "still_counteroffer", "still_phase_two", "recall", "card_recall", "last_chance", "legacy_noon"]
var checks := 0
var failures: Array[String] = []

func _initialize() -> void: call_deferred("_run")
func _check(ok: bool, message: String) -> void:
	checks += 1
	if not ok: failures.append(message); push_error(message)

func _kindred(service: ZodiacService) -> void:
	service.progress.commit("snake", "resume:varied", {"promises_kept": 2, "promise_kept:snake.cadence": 1, "promise_kept:snake.still": 1})
	service.progress.record_disposition("snake", "resume:kindred", "NORMAL")

func _record(owner: CampaignManager) -> Dictionary:
	var service := owner.zodiac
	return {"daily": service.daily.duplicate(true), "rng": service._rng.state, "quote": service.quote(),
		"conversation": service.conversation_history.duplicate(), "progress": service.progress.snapshot(),
		"mood": service.mood(), "wallet": owner.wallet.balance_vnd, "phase": owner.current_phase,
		"uses_persuasion": service.uses_persuasion()}

func _counter(owner: CampaignManager, topic: String) -> void:
	FLOW.terms(owner, "snake.t1plus." + topic)
	_check(owner.zodiac.respond("HAGGLE").requires_confirmation, "explicit counteroffer " + topic)

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
	for case: String in CASES:
		var owner := FLOW.campaign("snake", case not in ["question", "reaction"], writing)
		var service := owner.zodiac
		var save := RunSave.new("user://snake_%s.save" % case)
		if writing:
			match case:
				"reaction": service.answer_question("A")
				"counteroffer": _counter(owner, "cadence")
				"accepted": FLOW.accept(owner, "snake.t1plus.cadence")
				"partial", "two_notes", "matched", "judged", "wrong_middle", "incomplete", "recall":
					FLOW.accept(owner, "snake.t1plus.cadence")
					FLOW.afternoon(owner)
					_check(FLOW.first(owner).ok, "first actual note " + case)
					if case in ["two_notes", "matched", "judged", "recall"]: _check(FLOW.next(owner).ok, "second actual note " + case)
					if case in ["matched", "judged", "recall"]: _check(FLOW.last(owner).ok, "third actual note " + case)
					if case == "wrong_middle": _check(FLOW.last(owner).ok, "wrong second note commits " + case)
					if case in ["judged", "incomplete", "recall"]: _check(FLOW.finish(owner), "actual two-Phase return " + case)
					if case == "recall":
						_kindred(service)
						owner.start_campaign(true, owner.run_seed)
						owner.current_day_index = 5
						service.begin_day(5, owner.seed_for("zodiac_selection", 5))
						owner._enter_phase(CampaignManager.CampaignPhase.NOON_EVENT)
						FLOW.node(owner, "snake.t2.cadence_memory")
				"card_offer", "selection", "card_accepted", "card_partial", "card_matched", "card_wrong":
					FLOW.terms(owner, "snake.t1plus.card")
					var chosen: String = service.current_demand().offered_ids[0]
					if case != "card_offer": service.persuasion.select_card(chosen)
					if case not in ["card_offer", "selection"]:
						service.respond("ACCEPT", [chosen])
						service.continue_conversation()
					if case in ["card_partial", "card_matched", "card_wrong"]:
						FLOW.chosen_deal(owner, chosen)
						if case == "card_wrong": _check(service.deal.create_meld(service.deal.hand.slice(0, 4)).ok, "new Meld is not Extension")
						else: _check(FLOW.chosen_first(owner).ok, "three other physical copies create Meld")
						if case == "card_matched": _check(FLOW.chosen_next(owner, chosen).ok, "chosen exact Extension")
				"still_offer": FLOW.terms(owner, "snake.t1plus.still")
				"still_partial", "still_broken", "still_judged":
					FLOW.accept(owner, "snake.t1plus.still")
					FLOW.afternoon(owner)
					_check(FLOW.first(owner).ok, "actual play during restraint " + case)
					if case == "still_broken": _check(FLOW.recover_meld(owner).ok, "actual forbidden recovery")
					else: _check(FLOW.phase_two(owner), "whole-Deal pause continues past Phase 1 " + case)
					if case == "still_judged": _check(FLOW.finish(owner), "restraint actually judged")
				"still_counteroffer", "still_phase_two":
					_counter(owner, "still")
					if case == "still_phase_two":
						service.respond("ACCEPT")
						service.continue_conversation()
						FLOW.afternoon(owner)
						_check(FLOW.first(owner).ok and FLOW.phase_two(owner), "Phase 1-only deadline met")
				"card_recall":
					FLOW.terms(owner, "snake.t1plus.card")
					var chosen: String = service.current_demand().offered_ids[0]
					service.respond("ACCEPT", [chosen])
					service.continue_conversation()
					FLOW.chosen_deal(owner, chosen)
					_check(FLOW.chosen_first(owner).ok and FLOW.chosen_next(owner, chosen).ok and FLOW.finish(owner), "real card memory for later recall")
					_kindred(service)
					owner.start_campaign(true, owner.run_seed)
					owner.current_day_index = 5
					service.begin_day(5, owner.seed_for("zodiac_selection", 5))
					owner._enter_phase(CampaignManager.CampaignPhase.NOON_EVENT)
					FLOW.node(owner, "snake.t2.card_memory")
				"last_chance": service.persuasion.apply_patience(-3)
				"legacy_noon":
					var old := service.snapshot()
					old.version = 8
					old.daily.erase("persuasion")
					service.restore(old)
			expected[case] = _record(owner)
			_check(save.save_run(owner, service.deal), "write " + case)
		else:
			_check(save.restore(save.load_run(), owner, service.deal), "restore " + case)
			_check(_record(owner) == expected[case], "exact saved terms, sequence, targets, memory and RNG " + case)
			match case:
				"reaction": _check(not service.answer_question("A").ok, "answer cannot replay")
				"counteroffer", "still_counteroffer":
					var token := service.offer_token()
					_check(not service.persuasion.can_haggle(), "counteroffer cannot reroll " + case)
					_check(service.respond("ACCEPT", [], token).pending, "resumed explicit acceptance " + case)
					_check(not service.respond("ACCEPT", [], token).ok and service.daily.promises.size() == 1, "reserve once " + case)
				"accepted": _check(not service.daily.promises[0].started and not service.daily.promises[0].matched, "acceptance is not evidence")
				"partial", "two_notes", "matched":
					var cursor := int(service.daily.promises[0].sequence_cursor)
					_check(cursor == (1 if case == "partial" else 2 if case == "two_notes" else 3), "sequence cursor persisted " + case)
					if cursor == 1: _check(FLOW.next(owner).ok, "resume second note")
					if cursor < 3: _check(FLOW.last(owner).ok, "resume third note")
					_check(FLOW.finish(owner), "finish resumed cadence " + case)
					_check(service.progress.memory("snake", "snake.cadence").result == "FULFILLED", "resumed cadence judgment " + case)
				"wrong_middle":
					_check(service.daily.promises[0].broken and service.daily.promises[0].sequence_cursor == 1, "wrong order stays broken")
					_check(FLOW.next(owner).ok and FLOW.finish(owner), "later Extension cannot repair order")
					_check(service.progress.memory("snake", "snake.cadence").result == "BROKEN", "sticky failure judged")
				"judged", "incomplete", "still_judged":
					var before := _record(owner)
					service.enter_event(EventManager.EventSlot.AFTERNOON)
					_check(_record(owner) == before, "judgment cannot replay " + case)
				"card_offer": _check(not service.can_accept() and service.current_demand().offered_ids.size() == 3, "offer invents no choice")
				"selection":
					var selected: Array = service.persuasion.state().selection
					_check(selected.size() == 1 and service.can_accept(selected), "physical selection persists")
					_check(service.respond("ACCEPT", selected).pending, "explicit chosen-card confirmation")
				"card_accepted": _check(service.daily.promises[0].target_ids.size() == 1 and not service.daily.promises[0].matched, "exact pending obligation")
				"card_partial", "card_matched", "card_wrong":
					_check(service.daily.promises[0].matched == (case == "card_matched"), "physical Extension evidence " + case)
					if case == "card_partial": _check(FLOW.chosen_next(owner, service.daily.promises[0].target_ids[0]).ok, "resume exact chosen Extension")
					_check(FLOW.finish(owner), "complete chosen-card Deal " + case)
					_check(service.progress.memory("snake", "snake.card").result == ("BROKEN" if case == "card_wrong" else "FULFILLED"), "exact card judged " + case)
				"still_offer": _check(service.current_demand().deal_phase == 0 and service.current_demand().polarity == "DONT", "whole-Deal terms preserved")
				"still_partial", "still_broken", "still_phase_two":
					var pending: Dictionary = service.daily.promises[0]
					_check(pending.broken == (case == "still_broken"), "restraint evidence persists " + case)
					if case == "still_partial": _check(not pending.matched, "Phase 1 does not complete whole-Deal restriction")
					if case == "still_phase_two": _check(pending.matched and FLOW.recover_meld(owner).ok and not pending.broken, "saved Phase 1 deadline frees Phase 2")
					_check(FLOW.finish(owner), "finish resumed restraint " + case)
					_check(service.progress.memory("snake", "snake.still").result == ("BROKEN" if case == "still_broken" else "FULFILLED"), "signed restraint judged " + case)
				"recall":
					_check(service.progress.relationship_tier("snake") == ZodiacProgress.KINDRED, "Kindred survives New Run")
					_check(service.persuasion.state().node.bound_memory.result == "FULFILLED" and not service.quote().speech.contains("{target}"), "real bound recall persists")
				"card_recall":
					var remembered: Dictionary = service.persuasion.state().node.bound_memory.duplicate(true)
					_check(remembered.result == "FULFILLED" and service.current_demand().offered_ids.size() == 3, "old memory and three future targets resume")
					_check(service.answer_question("B").ok and service.continue_conversation(), "recall reaches fresh terms")
					var chosen: String = service.current_demand().offered_ids[0]
					_check(not service.can_accept() and service.respond("ACCEPT", [chosen]).pending, "renewal needs explicit physical choice")
					_check(service.persuasion.state().node.bound_memory == remembered and service.daily.promises[0].target_ids == [chosen], "new target cannot rewrite old remembered event")
				"last_chance":
					var token := service.offer_token()
					_check(service.persuasion.resolve_last_chance("B", token), "saved honest recovery")
					_check(not service.persuasion.resolve_last_chance("B", token) and service.persuasion.state().patience == 1, "one recovery only")
				"legacy_noon": _check(not service.uses_persuasion() and service.mood() == "NORMAL", "old started empty visit stays unchanged")
			for suffix in ["", ".bak", ".tmp"]: DirAccess.remove_absolute(save.path + suffix)
	var files := MetaSaveFiles.new("user://snake_profiles", "")
	if writing:
		var owner := FLOW.campaign("snake", true, true, files)
		FLOW.accept(owner, "snake.t1plus.cadence")
		FLOW.afternoon(owner)
		_check(FLOW.cadence(owner) and FLOW.finish(owner), "real permanent profile cadence")
		_kindred(owner.zodiac)
		expected["profile"] = owner.zodiac.progress.snapshot()
		_check(files.error.is_empty(), "plain permanent memory profile saved: " + files.error)
		var destination := FileAccess.open(EXPECTED, FileAccess.WRITE)
		destination.store_var(expected, false)
		destination.close()
	else:
		var owner := FLOW.campaign("snake", false, false, files)
		_check(owner.zodiac.progress.snapshot().memories == expected.profile.memories, "permanent memory loads independently of run save")
		_check(owner.zodiac.progress.relationship_tier("snake") == ZodiacProgress.KINDRED, "permanent Kindred retained")
		_check(files.select(2, owner) and owner.zodiac.progress.memories.is_empty(), "File 2 independent")
		_check(files.select(1, owner) and owner.zodiac.progress.snapshot().memories == expected.profile.memories, "File 1 restores Snake memory")
		DirAccess.remove_absolute(EXPECTED)
	print("SNAKE_PERSUASION_RESUME_%s checks=%d failures=%d" % ["WRITE" if writing else "READ", checks, failures.size()])
	for failure in failures: print("SNAKE_RESUME_FAIL " + failure)
	quit(0 if failures.is_empty() else 1)
