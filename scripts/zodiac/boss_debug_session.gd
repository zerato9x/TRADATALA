class_name BossDebugSession
extends RefCounted
## Explicit developer fixtures using the real deal, boss rules, and card zones.
const OPENING_IDS: Array[String] = ["standard_9_spades", "standard_9_hearts", "standard_9_diamonds", "standard_4_clubs", "standard_5_clubs", "standard_6_clubs", "standard_9_clubs", "standard_7_clubs", "standard_j_diamonds", "standard_a_spades"]
const SAVE_PATH := "user://debug_boss_run_v1.save"
const Difficulty := preload("res://scripts/campaign/difficulty_progress.gd")

static func available() -> bool:
	return not DemoBuild.enabled() and (OS.is_debug_build() or "--debug-bosses" in OS.get_cmdline_user_args())

static func normalize(input: Dictionary) -> Dictionary:
	var boss := String(input.get("boss", "rooster"))
	if boss == "mouse": boss = "rat"
	if not ZodiacBossRule.RULES.has(boss): return {}
	var drink := String(input.get("drink", DrinkCatalog.NONE))
	if drink != DrinkCatalog.NONE and not DrinkCatalog.is_known(drink): return {}
	var tactic := String(input.get("dragon_tactic", "history"))
	if tactic not in ["history", "new_meld:set", "new_meld:run", "extension:set", "extension:run"]: return {}
	return {"boss": boss, "difficulty": clampi(int(input.get("difficulty", 2)), 1, 3),
		"phase": clampi(int(input.get("phase", 1)), 1, 2), "seed": String(input.get("seed", "BOSS-LAB")).strip_edges().left(64),
		"opening": "curated" if input.get("opening", "curated") == "curated" else "seeded",
		"drink": drink, "wallet_vnd": clampi(int(input.get("wallet_vnd", 1_000_000)), 0, 1_000_000_000),
		"dragon_tactic": tactic, "dragon_average_vnd": clampi(int(input.get("dragon_average_vnd", 50_000)), 1, 1_000_000_000)}

static func day_for(boss: String) -> int:
	for day in ZodiacCatalog.PAIRS.size():
		if boss in ZodiacCatalog.PAIRS[day]: return day
	return 5

static func prepare(campaign: CampaignManager, deal: DealState, input: Dictionary, history: Array = []) -> bool:
	# Only detached, in-memory progression providers may enter this fixture.
	if campaign.drink_manager.progress == null or not campaign.drink_manager.progress.save_path.is_empty() or not campaign.zodiac.progress.path.is_empty() or not campaign.difficulty_progress.path.is_empty(): return false
	var options := normalize(input)
	if options.is_empty(): return false
	if options.seed.is_empty(): options.seed = "BOSS-LAB"
	campaign.debug_context = {"active": true, "options": options.duplicate(true), "finished": false}
	campaign.run_seed = options.seed
	campaign.difficulty = 1
	campaign.campaign_days = CampaignConfig.day_definitions(1)
	campaign._base_day_count = campaign.campaign_days.size()
	campaign.current_day_index = day_for(options.boss)
	campaign.current_phase = CampaignManager.CampaignPhase.DRAGON_DEAL if options.boss == "dragon" else CampaignManager.CampaignPhase.EVENING_DEAL
	campaign.campaign_complete = false
	campaign.run_failed = false
	campaign.endless = false
	campaign._collecting = false
	campaign.activities.clear()
	campaign.deal_reports.clear()
	campaign.day_reports.clear()
	campaign.collection_report.clear()
	campaign.onboarding.reset()
	campaign.onboarding.first_seed_enabled = false
	campaign.zodiac.reset_run()
	campaign.zodiac.forced.clear()
	campaign.zodiac.daily = {"day": campaign.current_day_index, "id": options.boss, "forced": "", "successes": 3 - options.difficulty,
		"slot": 3, "requests": {}, "promises": [], "skip_phase": -1, "skipped": [], "boss_finished": false, "last_result": {}}
	campaign.drink_manager.reset_run()
	campaign.drink_manager.day_index = campaign.current_day_index
	campaign.drink_manager.day_target_vnd = campaign.daily_requirement()
	campaign.drink_manager.active_drink_id = options.drink
	campaign.gieo_que.set_seed_value(campaign.seed_for("gieo"))
	campaign.gieo_que.reset_campaign()
	campaign.gieo_que.begin_day(campaign.current_day_index)
	campaign.lottery.reset_run()
	campaign.lottery.set_seed_value(campaign.seed_for("lottery"))
	campaign.shoe_shine.reset_run()
	campaign.shoe_shine.set_seed_value(campaign.seed_for("polish"))
	campaign.event_manager.current_event = null
	campaign.relic_shop.offers.clear()
	campaign.relic_shop.visit_id = ""
	campaign.relic_shop.purchased = false
	campaign.relic_shop.rerolls = 0
	deal.relics.reset_run()
	deal.wallet.reset(int(options.wallet_vnd))
	deal.wallet.economy_scaling = true
	deal.wallet.day_target_vnd = campaign.daily_requirement()
	deal.zodiac_boss.configure()
	deal.set_campaign_deck(campaign.gieo_que.persistent_deck)
	var opening: Array[String] = []
	if options.opening == "curated":
		# Seeded stock with a known real Set, Run, and both Extension cards.
		opening = OPENING_IDS.duplicate()
	deal.set_current_drink(options.drink)
	deal.start_deal(campaign.seed_for("debug_deal", campaign.current_day_index), false, opening)
	deal.current_phase = options.phase
	deal.discard_count = 0
	deal.phase_metrics = PhaseMetrics.new()
	deal.phase_new_meld_count = 0
	deal.zodiac_boss.configure(options.boss, options.difficulty, campaign.seed_for("debug_boss:" + options.boss))
	deal.zodiac_boss.begin_phase(deal)
	if options.boss == "dragon":
		var analysis := preload("res://scripts/zodiac/dragon_analysis.gd").analyze(history, options.difficulty)
		if options.dragon_tactic != "history":
			analysis = {"tactic": options.dragon_tactic, "action": options.dragon_tactic.get_slice(":", 0), "meld_type": options.dragon_tactic.get_slice(":", 1),
				"average_vnd": options.dragon_average_vnd, "target_vnd": maxi(1, int(options.dragon_average_vnd * int(ZodiacCatalog.tuning("dragon", "target_percent", options.difficulty)) / 100.0)),
				"sample_count": 0, "legacy_fallback": false, "debug_override": true}
		deal.zodiac_boss.data.analysis = analysis
		campaign.zodiac.endgame = {"status": "active", "day": campaign.current_day_index, "difficulty": options.difficulty, "analysis": analysis.duplicate(true)}
	deal.zodiac_boss.begin_turn(deal.current_phase, deal.hand, deal)
	campaign.day_cursor = deal.wallet.journal.size()
	campaign.deal_cursor = campaign.day_cursor
	campaign.day_activity_cursor = 0
	campaign.active_deal_wallet_before_vnd = deal.wallet.balance_vnd
	return deal.physical_card_accounting_is_valid()
