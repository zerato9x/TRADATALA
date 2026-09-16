class_name MusicAntiFatigue
extends Node

## A gradual low-pass descent after four held loops; release restores full range.
## The authored stream and MusicDirector transport are intentionally unaware of
## these filters; this node only changes the existing Music bus at runtime.

signal state_changed(next_state: StringName)

const STATE_FULL: StringName = &"FULL"
const STATE_DARK: StringName = &"DARK"
const LOOP_PASSES_BEFORE_VARIATION := 4
const FULL_HIGH_PASS_HZ := 20.0
const FULL_LOW_PASS_HZ := 20_000.0
const DARK_HIGH_PASS_HZ := 20.0
const DARK_LOW_PASS_HZ := 4_000.0

@export var enabled := true
@export var debug_logging := false
@export_range(0.0, 60.0, 0.5) var transition_seconds := 16.0

var bus_name: StringName = &"Music"
var current_cue_id := ""
var loop_pass_count := 0
var current_state: StringName = STATE_FULL

var high_pass_filter: AudioEffectHighPassFilter
var low_pass_filter: AudioEffectLowPassFilter

var _current_high_pass_hz := FULL_HIGH_PASS_HZ
var _current_low_pass_hz := FULL_LOW_PASS_HZ
var _target_high_pass_hz := FULL_HIGH_PASS_HZ
var _target_low_pass_hz := FULL_LOW_PASS_HZ
var _transition_start_high_pass_hz := FULL_HIGH_PASS_HZ
var _transition_start_low_pass_hz := FULL_LOW_PASS_HZ
var _transition_elapsed := 0.0
var _transition_duration := 0.0


func _ready() -> void:
	if enabled:
		_ensure_filter_effects()
	_apply_filter_cutoffs()


func _process(delta: float) -> void:
	if _transition_duration <= 0.0:
		return
	_transition_elapsed = minf(
		_transition_elapsed + maxf(delta, 0.0),
		_transition_duration
	)
	var ratio := _transition_elapsed / _transition_duration
	_current_high_pass_hz = lerpf(_transition_start_high_pass_hz, _target_high_pass_hz, ratio)
	_current_low_pass_hz = exp(lerpf(log(_transition_start_low_pass_hz), log(_target_low_pass_hz), smoothstep(0.0, 1.0, ratio)))
	_apply_filter_cutoffs()
	if ratio >= 1.0:
		_transition_duration = 0.0
		_current_high_pass_hz = _target_high_pass_hz
		_current_low_pass_hz = _target_low_pass_hz


func _exit_tree() -> void:
	_remove_filter_effect(high_pass_filter)
	_remove_filter_effect(low_pass_filter)
	high_pass_filter = null
	low_pass_filter = null


func cue_started(cue_id: String) -> void:
	current_cue_id = cue_id
	loop_pass_count = 0
	_set_state(STATE_FULL, false)


func loop_completed(cue_id: String) -> void:
	if not enabled or current_cue_id.is_empty() or cue_id != current_cue_id:
		return
	loop_pass_count += 1
	# Four full wraps, then one continuous descent. Later wraps never restart it.
	if loop_pass_count == LOOP_PASSES_BEFORE_VARIATION:
		_set_state(STATE_DARK, false)

func prepare_for_cue_change() -> void:
	current_cue_id = ""
	loop_pass_count = 0
	_set_state(STATE_FULL, false)


func reset_variation(smooth := true) -> void:
	current_cue_id = ""
	loop_pass_count = 0
	_set_state(STATE_FULL, not smooth)


func set_enabled(value: bool) -> void:
	enabled = value
	if enabled:
		_ensure_filter_effects()
		_apply_filter_cutoffs()
	else:
		reset_variation(false)
		_remove_filter_effect(high_pass_filter)
		_remove_filter_effect(low_pass_filter)
		high_pass_filter = null
		low_pass_filter = null


func _set_state(next_state: StringName, immediate: bool) -> void:
	if not _has_state(next_state):
		next_state = STATE_FULL
	var targets := _targets_for_state(next_state)
	_target_high_pass_hz = float(targets["high_pass_hz"])
	_target_low_pass_hz = float(targets["low_pass_hz"])
	var previous_state := current_state
	current_state = next_state
	if immediate or transition_seconds <= 0.0:
		_transition_duration = 0.0
		_current_high_pass_hz = _target_high_pass_hz
		_current_low_pass_hz = _target_low_pass_hz
		_apply_filter_cutoffs()
	else:
		_transition_start_high_pass_hz = _current_high_pass_hz
		_transition_start_low_pass_hz = _current_low_pass_hz
		_transition_elapsed = 0.0
		_transition_duration = transition_seconds
	if previous_state != current_state:
		state_changed.emit(current_state)


func _targets_for_state(state: StringName) -> Dictionary:
	match state:
		STATE_DARK:
			return {"high_pass_hz": DARK_HIGH_PASS_HZ, "low_pass_hz": DARK_LOW_PASS_HZ}
		_:
			return {"high_pass_hz": FULL_HIGH_PASS_HZ, "low_pass_hz": FULL_LOW_PASS_HZ}


func _has_state(state: StringName) -> bool:
	return state in [STATE_FULL, STATE_DARK]


func _log_pass(pass_number: int, state: StringName) -> void:
	if not debug_logging:
		return
	print("[Music AntiFatigue] cue=%s pass=%d state=%s" % [current_cue_id, pass_number, state])


func _ensure_filter_effects() -> void:
	if high_pass_filter != null and low_pass_filter != null:
		return
	var bus_index := AudioServer.get_bus_index(bus_name)
	if bus_index < 0:
		return
	high_pass_filter = AudioEffectHighPassFilter.new()
	high_pass_filter.resource_name = "Music Anti-Fatigue High Pass"
	low_pass_filter = AudioEffectLowPassFilter.new()
	low_pass_filter.resource_name = "Music Anti-Fatigue Low Pass"
	AudioServer.add_bus_effect(bus_index, high_pass_filter)
	AudioServer.add_bus_effect(bus_index, low_pass_filter)


func _apply_filter_cutoffs() -> void:
	if high_pass_filter != null:
		high_pass_filter.cutoff_hz = _current_high_pass_hz
	if low_pass_filter != null:
		low_pass_filter.cutoff_hz = _current_low_pass_hz


func _remove_filter_effect(effect: AudioEffect) -> void:
	if effect == null:
		return
	var bus_index := AudioServer.get_bus_index(bus_name)
	if bus_index < 0:
		return
	for effect_index in range(AudioServer.get_bus_effect_count(bus_index)):
		if AudioServer.get_bus_effect(bus_index, effect_index) == effect:
			AudioServer.remove_bus_effect(bus_index, effect_index)
			return
