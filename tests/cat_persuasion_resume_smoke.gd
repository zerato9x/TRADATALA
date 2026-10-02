extends SceneTree
## Fresh processes restore shown content, chosen identities, and real breaches.
const EXPECTED := "user://cat_persuasion_expected.values"
const CASES := ["question", "reaction", "counteroffer", "untouched", "relic", "altered", "judged"]
var checks := 0
var failures: Array[String] = []

func _initialize() -> void:
	call_deferred("_run")

func _check(ok: bool, message: String) -> void:
	checks += 1
	if not ok: failures.append(message); push_error(message)

func _fixture(familiar: bool) -> CampaignManager:
	var deal := DealState.new()
	var campaign := CampaignManager.new(deal.wallet)
	campaign.zodiac.bind(campaign, deal)
	campaign.relic_shop.runtime = deal.relics
	if familiar: campaign.zodiac.progress.record_disposition("cat", "resume:fixture", "PLEASED")
	var seed_text := ""
	for index in 50:
		campaign.run_seed = "CAT-PERSUASION-RESUME-%d" % index
		if ZodiacCatalog.select(campaign.seed_for("zodiac_selection", 0), 0) == "cat": seed_text = campaign.run_seed; break
	campaign.start_campaign(true, seed_text)
	campaign._enter_phase(CampaignManager.CampaignPhase.NOON_EVENT)
	return campaign

func _node(service: ZodiacService, id: String) -> void:
	for node: Dictionary in ZodiacCatalog.persuasion_nodes("cat"):
		if node.id != id: continue
		service.persuasion.state().plan = [node]
		service.persuasion.state().cursor = 0
		service.persuasion._open_node()
		return

func _record(service: ZodiacService) -> Dictionary:
	return {"daily": service.daily.duplicate(true), "rng": service._rng.state,
		"memory": service.conversation_history.duplicate(), "quote": service.quote(), "mood": service.mood()}

func _run() -> void:
	var writing := "--write" in OS.get_cmdline_user_args()
	var expected := {}
	if not writing:
		var source := FileAccess.open(EXPECTED, FileAccess.READ)
		if source == null: _check(false, "writer evidence exists"); quit(1); return
		expected = source.get_var(false)
		source.close()
	for case: String in CASES:
		var campaign := _fixture(case not in ["question", "reaction"])
		var service := campaign.zodiac
		var save := RunSave.new("user://cat_resume_" + case + ".save")
		if writing:
			if case == "reaction": service.answer_question("A")
			elif case == "counteroffer":
				_node(service, "cat.t1plus.leave_it_alone")
				service.answer_question("B")
				service.continue_conversation()
				service.respond("HAGGLE")
				service.persuasion.select_card(service.current_demand().offered_ids[1])
			elif case in ["untouched", "relic", "altered", "judged"]:
				if case == "relic":
					campaign.relic_shop.runtime.acquire("comb")
					_node(service, "cat.t1plus.keep_it")
					service.answer_question("C")
				elif case == "altered":
					campaign.gieo_que.persistent_deck[0].apply_rank("K", 13)
					_node(service, "cat.t1plus.dont_change_it")
					service.answer_question("B")
				else:
					_node(service, "cat.t1plus.leave_it_alone")
					service.answer_question("B")
				service.continue_conversation()
				if case in ["untouched", "judged"]: service.persuasion.state().terms.target_ids = ["standard_4_hearts"]
				_check(service.respond("ACCEPT").pending, "accept " + case)
				service.continue_conversation()
				if case == "altered":
					campaign.gieo_que.persistent_deck[0].apply_rank("2", 2)
					campaign.gieo_que.persistent_deck[0].apply_rank("K", 13)
				campaign._enter_phase(CampaignManager.CampaignPhase.AFTERNOON_DEAL)
				service.deal.start_tutorial_deal()
				if case in ["untouched", "judged"]: service.deal.create_meld(service.deal.hand.slice(0, 3))
				elif case == "relic": campaign.relic_shop.runtime.gift("comb"); campaign.relic_shop.runtime.acquire("comb")
				if case == "judged":
					service.finish_daytime_deal("afternoon")
					campaign._enter_phase(CampaignManager.CampaignPhase.AFTERNOON_EVENT)
			expected[case] = _record(service)
			_check(save.save_run(campaign, service.deal), "checkpoint written " + case)
		else:
			_check(save.restore(save.load_run(), campaign, service.deal), "checkpoint restored " + case)
			_check(_record(service) == expected[case], "shown state, physical targets and RNG unchanged " + case)
			match case:
				"question":
					_check(service.has_open_question() and int(service.persuasion.state().patience) == 3, "saved Question does not restart/reroll")
				"reaction":
					_check(service.persuasion.state().stage == "reaction" and not service.answer_question("A").ok, "reaction cannot reapply answer delta")
				"counteroffer":
					var ids: Array = service.persuasion.state().selection
					_check(ids.size() == 1 and ids[0] in service.current_demand().offered_ids, "saved physical choice remains in shown three")
					var token := service.offer_token()
					_check(service.respond("ACCEPT", ids, token).pending, "restored visible counteroffer commits")
					_check(not service.respond("ACCEPT", ids, token).ok and service.daily.promises.size() == 1, "duplicate Accept cannot add a second promise")
				"untouched", "relic", "altered":
					_check(service.daily.promises[0].broken, "committed breach survived fresh process " + case)
					service.finish_daytime_deal("afternoon")
					campaign._enter_phase(CampaignManager.CampaignPhase.AFTERNOON_EVENT)
					_check(service.daily.promises.is_empty() and not service.daily.last_result.resolved_successfully, "Cat judges actual saved breach " + case)
					_check(int(service.persuasion.state().patience) == 3, "authored minus one applied exactly once " + case)
					var before := _record(service)
					campaign._enter_phase(CampaignManager.CampaignPhase.AFTERNOON_EVENT)
					_check(_record(service) == before, "reopened judgement is idempotent " + case)
				"judged":
					var before := _record(service)
					campaign._enter_phase(CampaignManager.CampaignPhase.AFTERNOON_EVENT)
					_check(_record(service) == before, "resolved checkpoint does not replay reward/delta")
			for suffix in ["", ".bak", ".tmp"]: DirAccess.remove_absolute(save.path + suffix)
	if writing:
		var destination := FileAccess.open(EXPECTED, FileAccess.WRITE)
		destination.store_var(expected, false)
		destination.close()
	else: DirAccess.remove_absolute(EXPECTED)
	print("CAT_PERSUASION_RESUME_%s checks=%d failures=%d" % ["WRITE" if writing else "READ", checks, failures.size()])
	quit(0 if failures.is_empty() else 1)
