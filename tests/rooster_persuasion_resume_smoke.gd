extends SceneTree
## Separate Godot processes prove saved dialogue, action evidence and permanent history.
const EXPECTED := "user://rooster_expected.values"
const CASES := ["question", "reaction", "counteroffer", "accepted", "matched", "missed", "judged", "kindred_memory", "last_chance", "legacy_demand"]
var checks := 0
var failures: Array[String] = []

func _initialize() -> void:
	call_deferred("_run")

func _check(ok: bool, message: String) -> void:
	checks += 1
	if not ok: failures.append(message); push_error(message)

func _fixture(familiar: bool = true, files: MetaSaveFiles = null, start: bool = true) -> CampaignManager:
	var deal := DealState.new()
	var campaign := CampaignManager.new(deal.wallet)
	campaign.zodiac.bind(campaign, deal)
	campaign.relic_shop.runtime = deal.relics
	campaign.zodiac.progress = ZodiacProgress.new("")
	if files != null: files.attach(campaign)
	if not start: return campaign
	if familiar: campaign.zodiac.progress.record_disposition("rooster", "resume:familiar", "PLEASED")
	var seed_text := ""
	for index in 100:
		campaign.run_seed = "ROOSTER-RESUME-%d" % index
		if ZodiacCatalog.select(campaign.seed_for("zodiac_selection", 0), 0) == "rooster":
			seed_text = campaign.run_seed
			break
	campaign.start_campaign(true, seed_text)
	campaign._enter_phase(CampaignManager.CampaignPhase.NOON_EVENT)
	return campaign

func _node(service: ZodiacService, id: String) -> void:
	for node: Dictionary in ZodiacCatalog.persuasion_nodes("rooster"):
		if node.id != id: continue
		service.persuasion.state().plan = [node]
		service.persuasion.state().cursor = 0
		service.persuasion._open_node()
		return

func _terms(service: ZodiacService) -> void:
	_node(service, "rooster.t1plus.before_bell")
	service.answer_question("B")
	service.continue_conversation()

func _accept(service: ZodiacService) -> void:
	_terms(service)
	service.respond("ACCEPT")
	service.continue_conversation()

func _afternoon(campaign: CampaignManager, missed: bool = false) -> void:
	campaign._enter_phase(CampaignManager.CampaignPhase.AFTERNOON_DEAL)
	var deal := campaign.zodiac.deal
	deal.start_tutorial_deal()
	if missed: deal.discard_card(deal.hand[-1])
	deal.create_meld(deal.hand.slice(0, 3))

func _finish(campaign: CampaignManager) -> void:
	var deal := campaign.zodiac.deal
	for _step in 24:
		match deal.state:
			DealState.STATE_ACTIVE: deal.discard_card(deal.hand[-1])
			DealState.STATE_FINAL_COMMIT_WINDOW: deal.settle_phase()
			DealState.STATE_PHASE_CHOICE: deal.choose_phase_two(false)
			DealState.STATE_DEAL_OVER: break
	_check(deal.state == DealState.STATE_DEAL_OVER and deal.physical_card_accounting_is_valid(), "complete real Afternoon Deal")
	_check(campaign.complete_deal(), "campaign publishes real completed Afternoon Deal")

func _kindred(service: ZodiacService) -> void:
	service.progress.commit("rooster", "resume:varied", {"promises_kept": 3, "promise_kept:rooster.first_meld": 2, "promise_kept:rooster.extension": 1})
	service.progress.record_disposition("rooster", "resume:kindred", "NORMAL")

func _record(service: ZodiacService) -> Dictionary:
	return {"daily": service.daily.duplicate(true), "rng": service._rng.state, "quote": service.quote(),
		"conversation": service.conversation_history.duplicate(), "progress": service.progress.snapshot(), "mood": service.mood()}

func _run() -> void:
	var writing := "--write" in OS.get_cmdline_user_args()
	var expected := {}
	if not writing:
		var source := FileAccess.open(EXPECTED, FileAccess.READ)
		if source == null:
			_check(false, "fresh-process expected values exist")
			quit(1)
			return
		expected = source.get_var(false)
		source.close()
	for case: String in CASES:
		var campaign := _fixture(case not in ["question", "reaction"], null, writing)
		var service := campaign.zodiac
		var save := RunSave.new("user://rooster_%s.save" % case)
		if writing:
			match case:
				"reaction": service.answer_question("A")
				"counteroffer":
					_terms(service)
					service.respond("HAGGLE")
				"accepted": _accept(service)
				"matched", "missed", "judged", "kindred_memory":
					_accept(service)
					_afternoon(campaign, case in ["missed", "kindred_memory"])
					if case in ["judged", "kindred_memory"]: _finish(campaign)
					if case == "kindred_memory":
						_kindred(service)
						campaign.start_campaign(true, campaign.run_seed)
						campaign._enter_phase(CampaignManager.CampaignPhase.NOON_EVENT)
						_node(service, "rooster.t2.bell_memory")
				"last_chance": service.persuasion.apply_patience(-3)
				"legacy_demand":
					service.daily.erase("persuasion")
					service.daily["legacy_negotiation"] = true
					service._begin_negotiation()
					service.debug_offer(ZodiacDemand.make("PAY", "ANY", "PLAYER_CHOOSES", 1, "", 5000))
			expected[case] = _record(service)
			_check(save.save_run(campaign, service.deal), "write " + case)
		else:
			_check(save.restore(save.load_run(), campaign, service.deal), "restore " + case)
			_check(_record(service) == expected[case], "exact dialogue, evidence, patience, permanent memory and RNG " + case)
			match case:
				"question":
					_check(service.has_open_question() and service.persuasion.state().patience == 3, "Question did not reroll")
				"reaction":
					_check(not service.answer_question("A").ok, "reaction cannot replay answer delta")
				"counteroffer":
					_check(service.current_demand().id == "rooster.first_meld" and not service.persuasion.can_haggle(), "saved alternate deadline is frozen")
					var token := service.offer_token()
					_check(service.respond("ACCEPT", [], token).pending, "explicit resumed counteroffer confirmation")
					_check(not service.respond("ACCEPT", [], token).ok and service.daily.promises.size() == 1, "duplicate cannot reserve twice")
				"accepted":
					_check(not service.daily.promises[0].matched and not service.daily.promises[0].started, "acceptance is not fulfillment")
				"matched", "missed":
					_check(service.daily.promises[0].matched == (case == "matched"), "saved real action evidence " + case)
					_finish(campaign)
					_check(service.daily.promises.is_empty() and service.daily.last_result.resolved_successfully == (case == "matched"), "settle saved action evidence " + case)
					var before := _record(service)
					service.enter_event(EventManager.EventSlot.AFTERNOON)
					_check(_record(service) == before, "judge once " + case)
				"judged":
					var before := _record(service)
					service.enter_event(EventManager.EventSlot.AFTERNOON)
					_check(_record(service) == before, "resolved checkpoint cannot replay")
				"kindred_memory":
					_check(service.progress.relationship_tier("rooster") == ZodiacProgress.KINDRED, "Kindred survives New Run and fresh process")
					_check(service.persuasion.state().node.bound_memory.result == "BROKEN" and service.quote().speech.contains("The discard came first"), "recall real missed deadline")
				"last_chance":
					var token := service.offer_token()
					_check(service.persuasion.resolve_last_chance("C", token), "plain no recovers")
					_check(not service.persuasion.resolve_last_chance("C", token) and service.persuasion.state().patience == 1, "one recovery only")
				"legacy_demand":
					var before := campaign.wallet.balance_vnd
					var token := service.offer_token()
					_check(not service.uses_persuasion() and service.respond("ACCEPT", [], token).ok, "saved demand uses original engine")
					_check(campaign.wallet.balance_vnd == before - 5000 and not service.respond("ACCEPT", [], token).ok, "original paid terms commit once")
			for suffix in ["", ".bak", ".tmp"]: DirAccess.remove_absolute(save.path + suffix)
	var files := MetaSaveFiles.new("user://rooster_profiles", "")
	var profile := _fixture(true, files)
	if writing:
		_accept(profile.zodiac)
		_afternoon(profile)
		_finish(profile)
		_kindred(profile.zodiac)
		expected["profile"] = profile.zodiac.progress.snapshot()
		_check(files.error.is_empty(), "permanent profile saved with bilingual commitment memory")
		var destination := FileAccess.open(EXPECTED, FileAccess.WRITE)
		destination.store_var(expected, false)
		destination.close()
	else:
		_check(profile.zodiac.progress.snapshot().memories == expected.profile.memories, "permanent memory loaded from disk independently of run")
		_check(profile.zodiac.progress.relationship_tier("rooster") == ZodiacProgress.KINDRED, "permanent relationship loaded from disk")
		_check(files.select(2, profile) and profile.zodiac.progress.memory("rooster", "rooster.early_score").is_empty(), "File 2 does not inherit File 1 memory")
		_check(files.select(1, profile) and profile.zodiac.progress.snapshot().memories == expected.profile.memories, "switch back restores File 1 memory")
		DirAccess.remove_absolute(EXPECTED)
	print("ROOSTER_PERSUASION_RESUME_%s checks=%d failures=%d" % ["WRITE" if writing else "READ", checks, failures.size()])
	for failure in failures: print("ROOSTER_RESUME_FAIL " + failure)
	quit(0 if failures.is_empty() else 1)
