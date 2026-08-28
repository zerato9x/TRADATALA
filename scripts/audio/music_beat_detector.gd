class_name MusicBeatDetector
extends Node

signal beat_detected(strength: float)
signal bass_energy_changed(energy: float)
signal band_pulse(band_index: int, strength: float)
signal band_energy_changed(band_index: int, energy: float)

const BAND_COUNT := 4
const BAND_NAMES := ["TRA", "DA", "TA", "LA"]
const BAND_RANGES_HZ := [
	Vector2(45.0, 160.0),
	Vector2(160.0, 500.0),
	Vector2(500.0, 2000.0),
	Vector2(2000.0, 8000.0),
]
const SILENCE_DB := -60.0
const LOUD_DB := -6.0
const FAST_ATTACK_SECONDS := 0.025
const FAST_RELEASE_SECONDS := 0.09
const SLOW_ENVELOPE_SECONDS := 0.45

@export var bus_name: StringName = &"Music"
@export var analyzer_effect_index: int = 0
@export_group("Detection")
@export_range(0.0, 1.0, 0.001) var relative_onset: float = 0.16
@export_range(0.05, 1.0, 0.01) var band_cooldown_seconds: float = 0.16
@export var minimum_band_energies := PackedFloat32Array([0.16, 0.14, 0.12, 0.10])
@export var minimum_band_onsets := PackedFloat32Array([0.055, 0.050, 0.045, 0.040])

@export_group("Runtime Diagnostics")
@export var analyzer_ready: bool = false
@export var current_band_energies := PackedFloat32Array([0.0, 0.0, 0.0, 0.0])
@export var band_pulse_counts := PackedInt32Array([0, 0, 0, 0])
@export var current_bass_energy: float = 0.0
@export var detected_beat_count: int = 0

var _fast_envelopes := PackedFloat32Array([0.0, 0.0, 0.0, 0.0])
var _slow_envelopes := PackedFloat32Array([0.0, 0.0, 0.0, 0.0])
var _cooldowns := PackedFloat32Array([0.0, 0.0, 0.0, 0.0])
var _analyzer: AudioEffectSpectrumAnalyzerInstance


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_acquire_analyzer()


func _process(delta: float) -> void:
	if _analyzer == null:
		_acquire_analyzer()
		return
	for band_index in range(BAND_COUNT):
		var frequency_range: Vector2 = BAND_RANGES_HZ[band_index]
		var magnitude := _analyzer.get_magnitude_for_frequency_range(
			frequency_range.x,
			frequency_range.y,
			AudioEffectSpectrumAnalyzerInstance.MAGNITUDE_MAX
		)
		var linear_energy := (magnitude.x + magnitude.y) * 0.5
		process_band_energy_sample(band_index, _normalized_energy(linear_energy), delta)


func process_energy_sample(energy: float, delta: float) -> bool:
	## Compatibility entry point for focused bass/onset tests and consumers.
	return process_band_energy_sample(0, energy, delta)


func process_band_energy_sample(band_index: int, energy: float, delta: float) -> bool:
	## Public so every band can be verified without an audio device.
	if band_index < 0 or band_index >= BAND_COUNT:
		return false
	var band_energy := clampf(energy, 0.0, 1.0)
	current_band_energies[band_index] = band_energy
	if band_index == 0:
		current_bass_energy = band_energy
	_cooldowns[band_index] = maxf(0.0, _cooldowns[band_index] - delta)

	var fast_seconds := FAST_ATTACK_SECONDS if band_energy > _fast_envelopes[band_index] else FAST_RELEASE_SECONDS
	_fast_envelopes[band_index] = lerpf(
		_fast_envelopes[band_index],
		band_energy,
		_smoothing_weight(delta, fast_seconds)
	)
	_slow_envelopes[band_index] = lerpf(
		_slow_envelopes[band_index],
		band_energy,
		_smoothing_weight(delta, SLOW_ENVELOPE_SECONDS)
	)
	band_energy_changed.emit(band_index, band_energy)
	if band_index == 0:
		bass_energy_changed.emit(band_energy)

	var minimum_energy := _band_setting(minimum_band_energies, band_index, 0.12)
	var minimum_onset := _band_setting(minimum_band_onsets, band_index, 0.045)
	var onset := maxf(0.0, _fast_envelopes[band_index] - _slow_envelopes[band_index])
	var threshold := maxf(minimum_onset, _slow_envelopes[band_index] * relative_onset)
	if _cooldowns[band_index] > 0.0 or band_energy < minimum_energy or onset < threshold:
		return false

	_cooldowns[band_index] = band_cooldown_seconds
	var onset_strength := inverse_lerp(threshold, threshold + 0.28, onset)
	var energy_strength := inverse_lerp(minimum_energy, 0.85, band_energy)
	var strength := clampf(maxf(onset_strength, energy_strength * 0.72), 0.2, 1.0)
	band_pulse_counts[band_index] += 1
	detected_beat_count += 1
	band_pulse.emit(band_index, strength)
	if band_index == 0:
		beat_detected.emit(strength)
	return true


func reset() -> void:
	current_band_energies = PackedFloat32Array([0.0, 0.0, 0.0, 0.0])
	band_pulse_counts = PackedInt32Array([0, 0, 0, 0])
	_fast_envelopes = PackedFloat32Array([0.0, 0.0, 0.0, 0.0])
	_slow_envelopes = PackedFloat32Array([0.0, 0.0, 0.0, 0.0])
	_cooldowns = PackedFloat32Array([0.0, 0.0, 0.0, 0.0])
	current_bass_energy = 0.0
	detected_beat_count = 0


func analyzer_available() -> bool:
	return _analyzer != null


func _acquire_analyzer() -> void:
	var bus_index := AudioServer.get_bus_index(bus_name)
	if bus_index < 0 or analyzer_effect_index >= AudioServer.get_bus_effect_count(bus_index):
		_analyzer = null
		analyzer_ready = false
		return
	_analyzer = AudioServer.get_bus_effect_instance(bus_index, analyzer_effect_index) as AudioEffectSpectrumAnalyzerInstance
	analyzer_ready = _analyzer != null


func _normalized_energy(linear_energy: float) -> float:
	var decibels := linear_to_db(maxf(linear_energy, 0.000001))
	return clampf(inverse_lerp(SILENCE_DB, LOUD_DB, decibels), 0.0, 1.0)


func _smoothing_weight(delta: float, seconds: float) -> float:
	return 1.0 - exp(-delta / maxf(seconds, 0.0001))


func _band_setting(settings: PackedFloat32Array, band_index: int, fallback: float) -> float:
	return settings[band_index] if band_index < settings.size() else fallback
