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
}

var run_seed := ""
var endless := false
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
var activities: Array[Dictionary] = []
var day_activity_cursor := 0


func _init(
	p_wallet: VndWallet = null,
	p_event_manager: EventManager = null,
	p_drink_manager: DrinkManager = null,
	p_days: Array[Dictionary] = []
) -> void:
	wallet = p_wallet if p_wallet != null else VndWallet.new()
	event_manager = p_event_manager if p_event_manager != null else EventManager.new()
	drink_manager = p_drink_manager if p_drink_manager != null else DrinkManager.new(wallet)
	campaign_days = CampaignConfig.day_definitions() if p_days.is_empty() else p_days.duplicate(true)
	_base_day_count = campaign_days.size()
	relic_shop = RelicShop.new(wallet, RelicRuntime.new())
	gieo_que = GieoQueService.new(wallet)
	lottery = LotteryService.new(wallet)
	shoe_shine = ShoeShineService.new(wallet, lottery)
	gieo_que.pull_charged.connect(_record_cast)
	gieo_que.transformation_completed.connect(_record_transformations)
	drink_manager.drink_selected.connect(_record_drink)

func _record_cast(price: int, free: bool) -> void:
	activities.append({"action": "gieo_cast", "price_vnd": price, "free": free})

func _record_transformations(changes: Array[Dictionary]) -> void:
	activities.append({"action": "transformation", "changes": changes.duplicate(true)})

func _record_drink(id: String, period: String, price: int) -> void:
	activities.append({"action": "drink_selected", "id": id, "period": period, "price_vnd": price})



func start_campaign(reset_wallet: bool = true, seed_text: String = "") -> void:
	run_seed = seed_text.strip_edges().left(64)
	if run_seed.is_empty():
		var random := RandomNumberGenerator.new()
		random.randomize()
		run_seed = "%08X" % random.randi()
	endless = false
	campaign_days.resize(_base_day_count)
	relic_shop.visit_id = ""
	relic_shop.offers.clear()
	relic_shop.purchased = false
	gieo_que.set_seed_value(seed_for("gieo"))
	lottery.set_seed_value(seed_for("lottery"))
	shoe_shine.set_seed_value(seed_for("polish"))
	if reset_wallet:
		wallet.reset()
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
	var result := extra_result.duplicate(true)
	result.merge({
		"day_id": String(current_day().get("id", "")),
		"period": String(DEAL_PHASE_TO_PERIOD[current_phase]),
		"wallet_before_vnd": active_deal_wallet_before_vnd,
		"wallet_after_vnd": wallet.balance_vnd,
		"vnd_change": wallet.balance_vnd - active_deal_wallet_before_vnd,
	}, true)
	result["accounting"] = wallet.report(deal_cursor)
	deal_reports.append(result.duplicate(true))
	deal_finished.emit(result)
	_advance_from_current_phase()
	return true


func complete_current_event() -> bool:
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
	day_cursor = wallet.journal.size()
	day_activity_cursor = activities.size()
	_set_phase(CampaignPhase.DAY_START)
	drink_manager.day_index = current_day_index
	drink_manager.day_target_vnd = daily_requirement()
	gieo_que.begin_day(current_day_index)
	lottery.begin_day(current_day_index)
	shoe_shine.begin_day(current_day_index, gieo_que.persistent_deck)
	day_started.emit(current_day())
	_enter_phase(CampaignPhase.STARTER_EVENT)


func _enter_phase(phase: int) -> void:
	_set_phase(phase)
	if EVENT_PHASE_TO_SLOT.has(phase):
		var slot := int(EVENT_PHASE_TO_SLOT[phase])
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
		deal_cursor = wallet.journal.size()
		active_deal_wallet_before_vnd = wallet.balance_vnd
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
	lottery.settle_day()
	drink_manager.clear_day()
	day_finished.emit(current_day())
	_set_phase(CampaignPhase.MONEY_REQUIREMENT_CHECK)
	collection_report = wallet.report(day_cursor)
	collection_report["counts"] = day_counts()
	collection_report["activities"] = activities.slice(day_activity_cursor).duplicate(true)
	collection_report["due_vnd"] = daily_requirement()
	collection_report["paid"] = false
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
	requirement_passed.emit(current_day())
	_set_phase(CampaignPhase.DAY_COMPLETE)
	if endless and current_day_index == campaign_days.size() - 1:
		_append_endless_day()
	if current_day_index == campaign_days.size() - 1:
		campaign_complete = true
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
