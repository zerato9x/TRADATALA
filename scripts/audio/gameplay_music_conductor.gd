class_name GameplayMusicConductor
extends RefCounted

signal route_action(action: StringName, cue_id: String)

const DEFAULT_PLAN_PATH := "res://assets/audio/ost/ost_gameplay_plans.json"
const PERIOD_MORNING := "morning"
const PERIOD_NOON := "noon"
const PERIOD_AFTERNOON := "afternoon"
const PERIOD_EVENING := "evening"
const DAILY_SET_SEQUENCE: Array[String] = ["cat", "dog"]

var controller: Object
var plan_path := DEFAULT_PLAN_PATH
var active_track_id := ""
var active_set_id := ""
var opening_track_id := ""
var closing_track_id := ""
var active_period := ""
var cue_roles: Dictionary = {}
var active := false
var morning_first_phom_released := false
var noon_first_phom_released := false
var boss_first_phom_released := false
var last_error := ""


func _init(music_controller: Object = null) -> void:
	controller = music_controller


static func set_for_day(day_index: int) -> String:
	return DAILY_SET_SEQUENCE[posmod(day_index, DAILY_SET_SEQUENCE.size())]


func start_campaign(set_id := "cat") -> bool:
	if controller == null:
		return _fail("Gameplay music controller is unavailable")
	if not _load_set(set_id):
		return false
	active_period = ""
	active = true
	morning_first_phom_released = false
	noon_first_phom_released = false
	boss_first_phom_released = false
	if not _start_track_at_role(opening_track_id, &"starter_event"):
		active = false
		return false
	return true


func stop_campaign() -> void:
	active = false
	active_period = ""
	active_track_id = ""
	active_set_id = ""
	opening_track_id = ""
	closing_track_id = ""
	cue_roles.clear()


func on_event_started(period: String) -> bool:
	if not active:
		return false
	active_period = "%s_event" % period
	if period == PERIOD_NOON:
		boss_first_phom_released = false
		return _start_track_at_role(closing_track_id, &"noon_event")
	if period == PERIOD_AFTERNOON:
		return active_track_id == closing_track_id and _request_role(&"afternoon_event")
	return true


func on_deal_started(period: String) -> bool:
	if not active:
		return false
	active_period = period
	if period == PERIOD_MORNING:
		morning_first_phom_released = false
		return _request_role(&"morning_deal_phase_1")
	if period == PERIOD_NOON:
		noon_first_phom_released = false
		return _request_role(&"noon_deal_phase_1")
	if period == PERIOD_AFTERNOON:
		return _request_role(&"afternoon_phase_1")
	if period == PERIOD_EVENING:
		boss_first_phom_released = false
		return _request_role(&"evening_phase_1")
	return true


func on_deal_phase_started(phase: int) -> bool:
	if not active or phase != 2:
		return false
	if active_period == PERIOD_MORNING:
		return _request_role(&"morning_deal_phase_2")
	if active_period == PERIOD_NOON:
		return _request_role(&"noon_deal_phase_2")
	if active_period == PERIOD_AFTERNOON:
		return _request_role(&"afternoon_phase_2")
	if active_period == PERIOD_EVENING:
		return _request_role(&"evening_phase_2")
	return true


func on_new_phom(phase: int, phase_new_phom_count: int) -> bool:
	if not active or phase != 2 or phase_new_phom_count < 1:
		return false
	if active_period == PERIOD_MORNING:
		if morning_first_phom_released or cue_for_role(&"morning_deal_phase_2_cleanup").is_empty():
			return false
		var morning_routed := _request_role(&"morning_deal_phase_2_cleanup")
		if morning_routed:
			morning_first_phom_released = true
		return morning_routed
	if active_period == PERIOD_NOON:
		if noon_first_phom_released:
			return false
		var noon_routed := _request_role(&"noon_deal_final")
		if noon_routed:
			noon_first_phom_released = true
		return noon_routed
	if active_period == PERIOD_EVENING:
		if boss_first_phom_released:
			return false
		var boss_routed := _request_role(&"evening_phase_2_cleanup")
		if boss_routed:
			boss_first_phom_released = true
		return boss_routed
	return false


func on_deal_resolved() -> bool:
	if not active:
		return false
	if active_period == PERIOD_MORNING:
		return _request_role(&"morning_event_sustain")
	if active_period == PERIOD_NOON:
		return _release_authored_audio()
	if active_period == PERIOD_AFTERNOON:
		return true
	if active_period == PERIOD_EVENING:
		return _release_authored_audio()
	return true


func cue_for_role(role: StringName) -> String:
	return String(cue_roles.get(String(role), ""))


func _request_role(role: StringName) -> bool:
	var cue_id := cue_for_role(role)
	if cue_id.is_empty():
		return _fail("Gameplay music role is missing: %s" % role)
	if not bool(controller.call("request_dj_cue", cue_id)):
		return _fail("Could not route gameplay music to %s" % cue_id)
	route_action.emit(&"request", cue_id)
	return true


func _start_track_at_role(track_id: String, role: StringName) -> bool:
	if not _load_plan(track_id):
		return false
	var cue_id := cue_for_role(role)
	if cue_id.is_empty() or not bool(controller.call("start_dj_track", track_id, cue_id)):
		return _fail("Could not start gameplay DJ route at %s / %s" % [track_id, cue_id])
	active_track_id = track_id
	route_action.emit(&"hold", cue_id)
	return true


func _release_authored_audio() -> bool:
	if not bool(controller.call("release_dj_to_end")):
		return _fail("Could not release gameplay music to authored audio")
	route_action.emit(&"release", "")
	return true


func _load_plan(track_id: String) -> bool:
	var parsed := _load_plan_document()
	if parsed.is_empty():
		return false
	var plans: Dictionary = parsed.get("plans", {})
	var track_plan: Dictionary = plans.get(track_id, {})
	var roles: Dictionary = track_plan.get("cue_roles", {})
	if roles.is_empty():
		return _fail("Gameplay music plan has no cue roles for %s" % track_id)
	cue_roles = roles.duplicate(true)
	last_error = ""
	return true


func _load_set(set_id: String) -> bool:
	var parsed := _load_plan_document()
	if parsed.is_empty():
		return false
	var sets: Dictionary = parsed.get("sets", {})
	var set_plan: Dictionary = sets.get(set_id, {})
	var opening := String(set_plan.get("opening_track", ""))
	var closing := String(set_plan.get("closing_track", ""))
	if opening.is_empty() or closing.is_empty():
		return _fail("Gameplay music set is missing or incomplete: %s" % set_id)
	active_set_id = set_id
	opening_track_id = opening
	closing_track_id = closing
	last_error = ""
	return true


func _load_plan_document() -> Dictionary:
	if not FileAccess.file_exists(plan_path):
		_fail("Gameplay music plan is missing: %s" % plan_path)
		return {}
	var file := FileAccess.open(plan_path, FileAccess.READ)
	if file == null:
		_fail("Could not open gameplay music plan: %s" % plan_path)
		return {}
	var parsed = JSON.parse_string(file.get_as_text())
	if not parsed is Dictionary:
		_fail("Gameplay music plan is invalid JSON: %s" % plan_path)
		return {}
	return parsed


func _fail(message: String) -> bool:
	last_error = message
	push_warning(message)
	return false
