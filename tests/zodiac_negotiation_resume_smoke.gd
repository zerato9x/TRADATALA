extends SceneTree
## Two independent processes share only this check's isolated save directory.
var checks := 0
var failures: Array[String] = []
const OFFER_PATH := "user://negotiation_offer.save"
const PROMISE_PATH := "user://negotiation_promise.save"
const EXPECTED_PATH := "user://negotiation_expected.values"

func _initialize() -> void:
	call_deferred("_run")

func _check(ok: bool, label: String) -> void:
	checks += 1
	if not ok: failures.append(label); push_error(label)

func _fixture() -> CampaignManager:
	var deal := DealState.new()
	var events := EventManager.new()
	CampaignNpcCatalog.register_initial_npcs(events)
	var campaign := CampaignManager.new(deal.wallet, events)
	campaign.zodiac.bind(campaign, deal)
	campaign.relic_shop.runtime = deal.relics
	campaign.zodiac.progress = ZodiacProgress.new("")
	campaign.zodiac.progress.commit("rooster", "fixture", {}, ["emblem_unlocked"])
	campaign.zodiac.choose_emblem(0, "rooster")
	campaign.start_campaign(true, "ZODIAC-RESUME")
	campaign.zodiac.daily["legacy_negotiation"] = true
	campaign._enter_phase(CampaignManager.CampaignPhase.NOON_EVENT)
	return campaign

func _run() -> void:
	var writing := "--write" in OS.get_cmdline_user_args()
	var campaign := _fixture()
	var service := campaign.zodiac
	var offer_save := RunSave.new(OFFER_PATH)
	var promise_save := RunSave.new(PROMISE_PATH)
	if writing:
		var card: CardData = campaign.gieo_que.persistent_deck[0]
		card.apply_rank("K", 13)
		card.apply_suit("Hearts")
		card.adjust_fortune(2)
		service.debug_offer(ZodiacDemand.make("RESET", "HAS_GOLD_PROPERTY", "ZODIAC_CHOOSES"))
		_check(service.respond("HAGGLE").get("requires_confirmation", false), "counteroffer prepared without mutation")
		var expected := {"current": service.current_demand().duplicate(true), "rng": service._rng.state, "card": card.permanent_snapshot()}
		_check(offer_save.save_run(campaign, service.deal), "offer saved to disk")
		service.respond("REFUSE")
		expected["next"] = service.current_demand().duplicate(true)
		expected["next_rng"] = service._rng.state
		var file := FileAccess.open(EXPECTED_PATH, FileAccess.WRITE)
		file.store_var(expected, false)
		file.close()
		campaign = _fixture()
		service = campaign.zodiac
		service.debug_offer(ZodiacDemand.make("PROMISE", "ANY", "PLAYER_CHOOSES", 1, "", 0, {"condition": "dont_action", "action": "new_meld"}))
		_check(service.respond("ACCEPT").get("pending", false), "next-Deal promise accepted")
		while service.has_open_demand(): service.respond("REFUSE")
		campaign._enter_phase(CampaignManager.CampaignPhase.AFTERNOON_DEAL)
		service.deal.start_tutorial_deal()
		service.deal.create_meld(service.deal.hand.slice(0, 3))
		_check(service.daily.promises.size() == 1 and service.daily.promises[0].broken, "known breach remains pending")
		_check(promise_save.save_run(campaign, service.deal), "mid-Deal promise saved")
	else:
		_check(offer_save.restore(offer_save.load_run(), campaign, service.deal), "offer restored in new process")
		var file := FileAccess.open(EXPECTED_PATH, FileAccess.READ)
		if file == null:
			_check(false, "expected values exist")
		else:
			var expected: Dictionary = file.get_var(false)
			file.close()
			_check(service.current_demand() == expected.current, "counteroffer restored exactly")
			_check(service._rng.state == expected.rng, "negotiation RNG restored exactly")
			_check(campaign.gieo_que.persistent_deck[0].permanent_snapshot() == expected.card, "mutations and physical ID restored")
			_check(service.respond("REFUSE").ok, "restored offer resolves once")
			_check(service.current_demand() == expected.next and service._rng.state == expected.next_rng, "future demand and RNG match original process")
		campaign = _fixture()
		service = campaign.zodiac
		_check(promise_save.restore(promise_save.load_run(), campaign, service.deal), "pending promise restored in new process")
		_check(service.daily.promises.size() == 1 and service.daily.promises[0].broken, "breach observation survived reload")
		service.finish_daytime_deal("afternoon")
		campaign._enter_phase(CampaignManager.CampaignPhase.AFTERNOON_EVENT)
		_check(service.daily.promises.is_empty() and not service.daily.last_result.resolved_successfully, "Afternoon publishes saved breach")
		var resolved: int = service.negotiation().resolved_demand_count
		campaign._enter_phase(CampaignManager.CampaignPhase.AFTERNOON_EVENT)
		_check(service.negotiation().resolved_demand_count == resolved, "reopening does not settle twice")
		for path in [OFFER_PATH, PROMISE_PATH, EXPECTED_PATH]:
			for suffix in ["", ".bak", ".tmp"]: DirAccess.remove_absolute(path + suffix)
	print("ZODIAC_NEGOTIATION_RESUME_%s checks=%d failures=%d" % ["WRITE" if writing else "READ", checks, failures.size()])
	quit(0 if failures.is_empty() else 1)
