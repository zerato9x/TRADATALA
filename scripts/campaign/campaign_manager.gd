class_name CampaignManager
extends RefCounted

signal collection_requested(report: Dictionary)
signal campaign_started()
signal day_started(day: Dictionary)
signal campaign_phase_changed(phase: int)
signal event_started(event_instance: EventInstance)
signal event_finished(event_instance: EventInstance)
signal deal_requested(day: Dictionary, period: String, drink_id: String)
signal deal_finished(result: Dictionary)
signal day_finished(day: Dictionary)
signal requirement_passed(day: Dictionary)
signal requirement_failed(day: Dictionary)
signal campaign_won()
signal campaign_lost()
signal zodiac_endgame_choice_requested()

enum CampaignPhase {
	DAY_START,
	STARTER_EVENT,
	MORNING_DEAL,
	MORNING_EVENT,
	NOON_DEAL,
	NOON_EVENT,
	AFTERNOON_DEAL,
	AFTERNOON_EVENT,
	EVENING_DEAL,
	DAY_END,
	MONEY_REQUIREMENT_CHECK,
	DAY_COMPLETE,
	CAMPAIGN_VICTORY,
	CAMPAIGN_FAILURE,
	ZODIAC_ENDGAME_CHOICE,
	DRAGON_DEAL,
}

const EVENT_PHASE_TO_SLOT := {
	CampaignPhase.STARTER_EVENT: EventManager.EventSlot.STARTER,
	CampaignPhase.MORNING_EVENT: EventManager.EventSlot.MORNING,
	CampaignPhase.NOON_EVENT: EventManager.EventSlot.NOON,
	CampaignPhase.AFTERNOON_EVENT: EventManager.EventSlot.AFTERNOON,
}
const DEAL_PHASE_TO_PERIOD := {
	CampaignPhase.MORNING_DEAL: "morning",
	CampaignPhase.NOON_DEAL: "noon",
	CampaignPhase.AFTERNOON_DEAL: "afternoon",
	CampaignPhase.EVENING_DEAL: "evening",
	CampaignPhase.DRAGON_DEAL: "dragon",
}
const NEXT_PHASE := {
	CampaignPhase.STARTER_EVENT: CampaignPhase.MORNING_DEAL,
	CampaignPhase.MORNING_DEAL: CampaignPhase.MORNING_EVENT,
	CampaignPhase.MORNING_EVENT: CampaignPhase.NOON_DEAL,
	CampaignPhase.NOON_DEAL: CampaignPhase.NOON_EVENT,
	CampaignPhase.NOON_EVENT: CampaignPhase.AFTERNOON_DEAL,
	CampaignPhase.AFTERNOON_DEAL: CampaignPhase.AFTERNOON_EVENT,
	CampaignPhase.AFTERNOON_EVENT: CampaignPhase.EVENING_DEAL,
	CampaignPhase.EVENING_DEAL: CampaignPhase.DAY_END,
	CampaignPhase.DRAGON_DEAL: CampaignPhase.DAY_END,
}

var run_seed := ""
var debug_context: Dictionary = {}
var onboarding := CampaignOnboarding.new()
var zodiac := ZodiacService.new()
var endless := false
var difficulty := 1
var difficulty_progress = preload("res://scripts/campaign/difficulty_progress.gd").new()
var relic_shop: RelicShop
var _base_day_count := 7
var current_day_index: int = -1
var current_phase: int = CampaignPhase.DAY_START
var campaign_complete: bool = false
var run_failed: bool = false
var campaign_days: Array[Dictionary] = []
var event_manager: EventManager
var drink_manager: DrinkManager
var wallet: VndWallet
var active_deal_wallet_before_vnd: int = 0
var gieo_que: GieoQueService
var lottery: LotteryService
var shoe_shine: ShoeShineService
var deal_cursor := 0
var day_cursor := 0
var deal_reports: Array[Dictionary] = []
var day_reports: Array[Dictionary] = []
var collection_report: Dictionary = {}
var _collecting := false
var _observed_deal: WeakRef
var activities: Array[Dictionary] = []
var day_activity_cursor := 0


func _init(
	p_wallet: VndWallet = null,
	p_event_manager: EventManager = null,
	p_drink_manager: DrinkManager = null,
	p_days: Array[Dictionary] = []
) -> void:
	wallet = p_wallet if p_wallet != null else VndWallet.new()
	zodiac.bind_campaign(self)
	event_manager = p_event_manager if p_event_manager != null else EventManager.new()
	drink_manager = p_drink_manager if p_drink_manager != null else DrinkManager.new(wallet)
	campaign_days = CampaignConfig.day_definitions() if p_days.is_empty() else p_days.duplicate(true)
	_base_day_count = campaign_days.size()
	relic_shop = RelicShop.new(wallet, RelicRuntime.new())
	gieo_que = GieoQueService.new(wallet)
	lottery = LotteryService.new(wallet)
	shoe_shine = ShoeShineService.new(wallet)
	shoe_shine.bind_campaign(self)
	shoe_shine.transformation_committed.connect(_record_identity_transformation)
	relic_shop.bind_campaign(self)
	gieo_que.pull_charged.connect(_record_cast)
	gieo_que.transformation_completed.connect(_record_transformations)
	drink_manager.drink_selected.connect(_record_drink)
	wallet.balance_changed.connect(_observe_wallet)

func _record_cast(price: int, free: bool) -> void:
	onboarding.mark("gieo_cast")
	activities.append({"action": "gieo_cast", "price_vnd": price, "free": free})

func _record_transformations(changes: Array[Dictionary]) -> void:
	onboarding.mark("gieo_transform")
	activities.append({"action": "transformation", "changes": changes.duplicate(true)})

func _record_identity_transformation(receipt: Dictionary) -> void:
	activities.append({"action": "identity_transformation", "card_id": receipt.card_id,
		"kind": receipt.kind, "cost_vnd": receipt.cost_vnd,
		"before": receipt.before.duplicate(true), "after": receipt.after.duplicate(true)})

func _record_drink(id: String, period: String, price: int) -> void:
	onboarding.mark("drink")
	if period == "afternoon": onboarding.mark("noon_drink")
	activities.append({"action": "drink_selected", "id": id, "period": period, "price_vnd": price})



func select_difficulty(level: int) -> bool:
	if level < 1 or level > difficulty_progress.unlocked: return false
	difficulty = level
	campaign_days = CampaignConfig.day_definitions(level)
	_base_day_count = campaign_days.size()
	return true

func start_campaign(reset_wallet: bool = true, seed_text: String = "") -> void:
	debug_context.clear()
	onboarding.reset()
	zodiac.reset_run()
	run_seed = seed_text.strip_edges().left(64)
	if run_seed.is_empty():
		var random := RandomNumberGenerator.new()
		random.randomize()
		run_seed = "%08X" % random.randi()
	endless = false
	campaign_days.resize(_base_day_count)
	relic_shop.reset_run()
	relic_shop.runtime.reset_run()
	gieo_que.set_seed_value(seed_for("gieo"))
	lottery.set_seed_value(seed_for("lottery"))
	shoe_shine.set_seed_value(seed_for("shoe_identity"))
	if reset_wallet:
		wallet.reset(CampaignConfig.STARTING_WALLET_VND)
	wallet.economy_scaling = true
	activities.clear()
	deal_reports.clear()
	day_reports.clear()
	collection_report.clear()
	_collecting = false
	drink_manager.reset_run()
	gieo_que.reset_campaign()
	lottery.reset_run()
	shoe_shine.reset_run()
	synchronize_run_deck(false)
	current_day_index = 0
	campaign_complete = false
	run_failed = false
	campaign_started.emit()
	_begin_current_day()


func current_day() -> Dictionary:
	if current_day_index < 0 or current_day_index >= campaign_days.size():
		return {}
	return campaign_days[current_day_index]


func daily_requirement() -> int:
	return int(current_day().get("required_vnd", 0))


func complete_deal(extra_result: Dictionary = {}) -> bool:
	if not DEAL_PHASE_TO_PERIOD.has(current_phase) or campaign_complete or run_failed:
		return false
	if current_phase == CampaignPhase.EVENING_DEAL and zodiac.deal != null and zodiac.deal.state == DealState.STATE_DEAL_OVER:
		zodiac.finish_boss()
	var result := extra_result.duplicate(true)
	if not result.has("details") and zodiac.deal != null: result["details"] = zodiac.deal.accounting_report()
	result.merge({
		"day_id": String(current_day().get("id", "")),
		"period": String(DEAL_PHASE_TO_PERIOD[current_phase]),
		"wallet_before_vnd": active_deal_wallet_before_vnd,
		"wallet_after_vnd": wallet.balance_vnd,
		"vnd_change": wallet.balance_vnd - active_deal_wallet_before_vnd,
	}, true)
	result["accounting"] = wallet.report(deal_cursor)
	deal_reports.append(result.duplicate(true))
	zodiac.finish_daytime_deal(String(DEAL_PHASE_TO_PERIOD[current_phase]))
	if current_phase == CampaignPhase.DRAGON_DEAL: zodiac.finish_dragon()
	deal_finished.emit(result)
	if current_phase == CampaignPhase.EVENING_DEAL and zodiac.endgame.get("status", "") == "choice":
		_set_phase(CampaignPhase.ZODIAC_ENDGAME_CHOICE)
		zodiac_endgame_choice_requested.emit()
	else:
		_advance_from_current_phase()
	return true


func complete_current_event() -> bool:
	if relic_shop.removal_pending: return false
	if current_phase == CampaignPhase.NOON_EVENT and zodiac.has_open_interaction(): return false
	if gieo_que.state not in [GieoQueService.STATE_READY, GieoQueService.STATE_COMPLETE]:
		return false
	if not EVENT_PHASE_TO_SLOT.has(current_phase) or event_manager.current_event == null:
		return false
	var finished := event_manager.current_event
	if not event_manager.finish_current_event():
		return false
	lottery.end_event()
	shoe_shine.end_event()
	event_finished.emit(finished)
	_advance_from_current_phase()
	return true


func _begin_current_day() -> void:
	wallet.day_target_vnd = daily_requirement()
	day_cursor = wallet.journal.size()
	day_activity_cursor = activities.size()
	_set_phase(CampaignPhase.DAY_START)
	drink_manager.day_index = current_day_index
	drink_manager.day_target_vnd = daily_requirement()
	gieo_que.begin_day(current_day_index)
	# Preserve legacy day-polish expiry outside the identity service.
	for card in gieo_que.persistent_deck: card.shiny = false
	lottery.begin_day(current_day_index)
	shoe_shine.begin_day(current_day_index, gieo_que.persistent_deck, daily_requirement())
	zodiac.begin_day(current_day_index, seed_for("zodiac_selection", current_day_index))
	day_started.emit(current_day())
	_enter_phase(CampaignPhase.STARTER_EVENT)


func _enter_phase(phase: int) -> void:
	_set_phase(phase)
	if EVENT_PHASE_TO_SLOT.has(phase):
		var slot := int(EVENT_PHASE_TO_SLOT[phase])
		zodiac.enter_event(slot)
		drink_manager.begin_event(slot)
		if slot in [EventManager.EventSlot.MORNING, EventManager.EventSlot.AFTERNOON] and not DemoBuild.enabled():
			relic_shop.begin_visit("%d:%d" % [current_day_index, slot], seed_for("relic", current_day_index * 4 + slot), daily_requirement())
		if not DemoBuild.enabled():
			lottery.begin_event(int(EVENT_PHASE_TO_SLOT[phase]))
			shoe_shine.begin_event(int(EVENT_PHASE_TO_SLOT[phase]))
		var event := event_manager.build_event(int(EVENT_PHASE_TO_SLOT[phase]), {
			"day": current_day().duplicate(true),
			"day_index": current_day_index,
			"wallet_vnd": wallet.balance_vnd,
		})
		event_started.emit(event)
	elif DEAL_PHASE_TO_PERIOD.has(phase):
		if zodiac.consume_skip(phase):
			activities.append({"action": "zodiac_spend_time", "day": current_day_index, "period": DEAL_PHASE_TO_PERIOD[phase], "payout_vnd": 0})
			_advance_from_current_phase()
			return
		deal_cursor = wallet.journal.size()
		active_deal_wallet_before_vnd = wallet.balance_vnd
		zodiac.prepare_deal(String(DEAL_PHASE_TO_PERIOD[phase]))
		deal_requested.emit(
			current_day().duplicate(true),
			String(DEAL_PHASE_TO_PERIOD[phase]),
			drink_manager.active_drink_id
		)
	elif phase == CampaignPhase.DAY_END:
		_finish_day()


func _advance_from_current_phase() -> void:
	if NEXT_PHASE.has(current_phase):
		_enter_phase(int(NEXT_PHASE[current_phase]))


func _finish_day() -> void:
	# Lottery is settled at the Afternoon Event before the Evening Deal.
	drink_manager.clear_day()
	day_finished.emit(current_day())
	_set_phase(CampaignPhase.MONEY_REQUIREMENT_CHECK)
	collection_report = wallet.report(day_cursor)
	collection_report["counts"] = day_counts()
	collection_report["activities"] = activities.slice(day_activity_cursor).duplicate(true)
	collection_report["due_vnd"] = daily_requirement()
	collection_report["paid"] = false
	if zodiac.endgame.get("status", "") == "victory" and int(zodiac.endgame.get("day", -1)) == current_day_index:
		collection_report["ending"] = "RỒNG RẮN LÊN MÂY"
	collection_report["shortfall_vnd"] = maxi(daily_requirement() - wallet.balance_vnd, 0)
	collection_requested.emit(collection_report.duplicate(true))


func collect_day_debt() -> bool:
	if current_phase != CampaignPhase.MONEY_REQUIREMENT_CHECK or _collecting:
		return false
	_collecting = true
	var due := daily_requirement()
	if wallet.balance_vnd < due:
		run_failed = true
		day_reports.append(collection_report.duplicate(true))
		_set_phase(CampaignPhase.CAMPAIGN_FAILURE)
		requirement_failed.emit(current_day())
		campaign_lost.emit()
		_collecting = false
		return true
	# Guard is set before the wallet signal: listeners cannot collect twice.
	wallet.apply_vnd(-due, "daily_debt")
	collection_report = wallet.report(day_cursor)
	collection_report["counts"] = day_counts()
	collection_report["due_vnd"] = due
	collection_report["paid"] = true
	collection_report["activities"] = activities.slice(day_activity_cursor).duplicate(true)
	day_reports.append(collection_report.duplicate(true))
	if drink_manager.progress != null and current_day().get("id") == "monday":
		drink_manager.progress.add_progress("mondays")
	requirement_passed.emit(current_day())
	_set_phase(CampaignPhase.DAY_COMPLETE)
	if endless and current_day_index == campaign_days.size() - 1:
		_append_endless_day()
	if current_day_index == campaign_days.size() - 1:
		campaign_complete = true
		if not endless and _base_day_count == 7:
			difficulty_progress.complete_week(difficulty)
		_set_phase(CampaignPhase.CAMPAIGN_VICTORY)
		campaign_won.emit()
	else:
		current_day_index += 1
		_begin_current_day()
	_collecting = false
	return true


func _set_phase(phase: int) -> void:
	current_phase = phase
	campaign_phase_changed.emit(phase)


func day_counts() -> Dictionary:
	var counts: Dictionary = {}
	for result in deal_reports:
		if result.day_id != current_day().get("id", ""):
			continue
		for key in result.get("details", {}).get("counts", {}):
			counts[key] = int(counts.get(key, 0)) + int(result.details.counts[key])
	return counts


func seed_for(stream: String, ordinal: int = 0) -> int:
	return ("tradatala-v1|%s|%s|%d" % [run_seed, stream, ordinal]).sha256_text().left(8).hex_to_int()


func continue_endless() -> bool:
	if not campaign_complete or run_failed or current_phase != CampaignPhase.CAMPAIGN_VICTORY:
		return false
	endless = true
	campaign_complete = false
	_append_endless_day()
	current_day_index += 1
	_begin_current_day()
	return true


func _append_endless_day() -> void:
	var index := campaign_days.size()
	# 50% daily growth after Sunday; saturate before integer overflow.
	var goal := mini(4_000_000_000_000_000, int(ceil(float(campaign_days[-1].required_vnd) * 1.5 / 500.0)) * 500)
	campaign_days.append({"id": "endless_%d" % (index + 1), "name_key": CampaignConfig.DAYS[index % 7].name_key, "required_vnd": goal})


func choose_zodiac_endgame(face_dragon: bool) -> bool:
	if current_phase != CampaignPhase.ZODIAC_ENDGAME_CHOICE or zodiac.endgame.get("status", "") != "choice" or campaign_complete or run_failed: return false
	zodiac.endgame.status = "active" if face_dragon else "continued"
	# Sunday and collection retain the existing seven-day debt/endless progression.
	_enter_phase(CampaignPhase.DRAGON_DEAL if face_dragon else CampaignPhase.DAY_END)
	zodiac.changed.emit()
	return true

# Stable fields of the existing V3 run envelope. Change this schema explicitly.
const RUN_SAVE_FIELDS_V3 := ["debug_context", "difficulty", "run_seed", "endless", "_base_day_count", "current_day_index", "current_phase", "campaign_complete", "run_failed", "campaign_days", "active_deal_wallet_before_vnd", "deal_cursor", "day_cursor", "deal_reports", "day_reports", "collection_report", "activities", "day_activity_cursor"]
const RUN_SNAPSHOT_FIELDS := preload("res://scripts/campaign/run_snapshot_fields.gd")

func run_snapshot() -> Dictionary:
	return RUN_SNAPSHOT_FIELDS.fields(self, RUN_SAVE_FIELDS_V3)

func restore_run_snapshot(data: Dictionary) -> void:
	RUN_SNAPSHOT_FIELDS.apply_fields(self, data, RUN_SAVE_FIELDS_V3)

## Only detached, in-memory progression providers can receive a debug fixture.
func prepare_debug_run(options: Dictionary, day_index: int, phase: int) -> bool:
	if drink_manager.progress == null or not drink_manager.progress.save_path.is_empty() or not zodiac.progress.path.is_empty() or not difficulty_progress.path.is_empty(): return false
	debug_context = {"active": true, "options": options.duplicate(true), "finished": false}
	run_seed = options.seed
	difficulty = 1
	campaign_days = CampaignConfig.day_definitions(1)
	_base_day_count = campaign_days.size()
	current_day_index = day_index
	current_phase = phase
	campaign_complete = false
	run_failed = false
	endless = false
	_collecting = false
	activities.clear()
	deal_reports.clear()
	day_reports.clear()
	collection_report.clear()
	onboarding.reset()
	onboarding.first_seed_enabled = false
	zodiac.reset_run()
	return true

func synchronize_run_deck(reconcile: bool = true) -> void:
	shoe_shine.bind_deck(gieo_que.persistent_deck)
	var observed: DealState = _observed_deal.get_ref() if _observed_deal != null else null
	if observed != null:
		if reconcile: observed.reconcile_campaign_deck(gieo_que.persistent_deck)
		else: observed.set_campaign_deck(gieo_que.persistent_deck)
	zodiac.rebind_observers()

func bind_deal(deal: DealState) -> void:
	relic_shop.runtime = deal.relics
	var previous: DealState = _observed_deal.get_ref() if _observed_deal != null else null
	if previous == deal: return
	if previous != null: previous.state_changed.disconnect(_observe_deal)
	_observed_deal = weakref(deal)
	deal.state_changed.connect(_observe_deal)

func _observe_deal(result: Dictionary) -> void:
	var deal: DealState = _observed_deal.get_ref()
	if deal == null: return
	onboarding.observe(result, deal)
	if current_phase == CampaignPhase.NOON_DEAL and deal.action_counts.get("new_meld", 0) > 0:
		onboarding.mark("noon_consequence")

func _observe_wallet(_before: int, _after: int, _delta: int, reason: String) -> void:
	if reason != "reset": onboarding.mark(reason)
	if reason.begins_with("relic_purchase:"): onboarding.mark("relic_purchase")
