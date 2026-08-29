class_name CampaignManager
extends RefCounted

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

var current_day_index: int = -1
var current_phase: int = CampaignPhase.DAY_START
var campaign_complete: bool = false
var run_failed: bool = false
var campaign_days: Array[Dictionary] = []
var event_manager: EventManager
var drink_manager: DrinkManager
var wallet: VndWallet
var active_deal_wallet_before_vnd: int = 0


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


func start_campaign(reset_wallet: bool = true) -> void:
	if reset_wallet:
		wallet.reset()
	drink_manager.clear_day()
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
	deal_finished.emit(result)
	_advance_from_current_phase()
	return true


func complete_current_event() -> bool:
	if not EVENT_PHASE_TO_SLOT.has(current_phase) or event_manager.current_event == null:
		return false
	var finished := event_manager.current_event
	if not event_manager.finish_current_event():
		return false
	event_finished.emit(finished)
	_advance_from_current_phase()
	return true


func _begin_current_day() -> void:
	_set_phase(CampaignPhase.DAY_START)
	day_started.emit(current_day())
	_enter_phase(CampaignPhase.STARTER_EVENT)


func _enter_phase(phase: int) -> void:
	_set_phase(phase)
	if EVENT_PHASE_TO_SLOT.has(phase):
		var event := event_manager.build_event(int(EVENT_PHASE_TO_SLOT[phase]), {
			"day": current_day().duplicate(true),
			"day_index": current_day_index,
			"wallet_vnd": wallet.balance_vnd,
		})
		event_started.emit(event)
	elif DEAL_PHASE_TO_PERIOD.has(phase):
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
	drink_manager.clear_day()
	day_finished.emit(current_day())
	_set_phase(CampaignPhase.MONEY_REQUIREMENT_CHECK)
	if wallet.balance_vnd < daily_requirement():
		run_failed = true
		_set_phase(CampaignPhase.CAMPAIGN_FAILURE)
		requirement_failed.emit(current_day())
		campaign_lost.emit()
		return
	requirement_passed.emit(current_day())
	_set_phase(CampaignPhase.DAY_COMPLETE)
	if current_day_index == campaign_days.size() - 1:
		campaign_complete = true
		_set_phase(CampaignPhase.CAMPAIGN_VICTORY)
		campaign_won.emit()
		return
	current_day_index += 1
	_begin_current_day()


func _set_phase(phase: int) -> void:
	current_phase = phase
	campaign_phase_changed.emit(phase)
