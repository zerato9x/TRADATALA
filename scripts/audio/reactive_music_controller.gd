class_name ReactiveMusicController
extends Node

signal beat_detected(strength: float)
signal bass_energy_changed(energy: float)
signal band_pulse(band_index: int, strength: float)
signal band_energy_changed(band_index: int, energy: float)

const CURRENT_MIX_PATH := "res://assets/audio/day_1_morning.wav"
const MUSIC_BUS := &"Music"

var full_mix_player: AudioStreamPlayer
var beat_detector: MusicBeatDetector
var stem_players: Dictionary = {}

@export_group("Runtime Diagnostics")
@export var audio_driver_name: String = ""
@export var playback_position_seconds: float = 0.0
@export var stream_length_seconds: float = 0.0
@export var music_bus_peak_db: float = -200.0
@export var music_bus_muted: bool = false
@export var master_bus_muted: bool = false


func _ready() -> void:
	audio_driver_name = AudioServer.get_driver_name()
	_ensure_music_bus()
	full_mix_player = _create_stem_player(&"full_mix")
	beat_detector = MusicBeatDetector.new()
	beat_detector.name = "BeatDetector"
	beat_detector.bus_name = MUSIC_BUS
	beat_detector.beat_detected.connect(beat_detected.emit)
	beat_detector.bass_energy_changed.connect(bass_energy_changed.emit)
	beat_detector.band_pulse.connect(band_pulse.emit)
	beat_detector.band_energy_changed.connect(band_energy_changed.emit)
	add_child(beat_detector)
	call_deferred("_start_current_mix")


func _process(_delta: float) -> void:
	if full_mix_player != null and full_mix_player.stream != null:
		playback_position_seconds = full_mix_player.get_playback_position()
		stream_length_seconds = full_mix_player.stream.get_length()
	var music_bus_index := AudioServer.get_bus_index(MUSIC_BUS)
	if music_bus_index >= 0:
		music_bus_peak_db = AudioServer.get_bus_peak_volume_left_db(music_bus_index, 0)
		music_bus_muted = AudioServer.is_bus_mute(music_bus_index)
	var master_bus_index := AudioServer.get_bus_index(&"Master")
	if master_bus_index >= 0:
		master_bus_muted = AudioServer.is_bus_mute(master_bus_index)


func _ensure_music_bus() -> void:
	var bus_index := AudioServer.get_bus_index(MUSIC_BUS)
	if bus_index < 0:
		AudioServer.add_bus()
		bus_index = AudioServer.bus_count - 1
		AudioServer.set_bus_name(bus_index, MUSIC_BUS)
		AudioServer.set_bus_send(bus_index, &"Master")
	var has_analyzer := AudioServer.get_bus_effect_count(bus_index) > 0 \
		and AudioServer.get_bus_effect(bus_index, 0) is AudioEffectSpectrumAnalyzer
	if has_analyzer:
		return
	var analyzer := AudioEffectSpectrumAnalyzer.new()
	analyzer.resource_name = "Music Spectrum"
	analyzer.buffer_length = 2.0
	analyzer.fft_size = AudioEffectSpectrumAnalyzer.FFT_SIZE_1024
	AudioServer.add_bus_effect(bus_index, analyzer, 0)


func _create_stem_player(stem_id: StringName) -> AudioStreamPlayer:
	var player := AudioStreamPlayer.new()
	player.name = String(stem_id).to_pascal_case()
	player.bus = MUSIC_BUS
	player.finished.connect(_on_stem_finished.bind(stem_id))
	stem_players[stem_id] = player
	add_child(player)
	return player


func _start_current_mix() -> void:
	var source := load(CURRENT_MIX_PATH) as AudioStream
	if source == null:
		push_warning("Reactive music mix is missing: %s" % CURRENT_MIX_PATH)
		return
	if source is AudioStreamWAV:
		var looping_wav := source.duplicate() as AudioStreamWAV
		if looping_wav.loop_end <= looping_wav.loop_begin:
			looping_wav.loop_begin = 0
			looping_wav.loop_end = maxi(1, int(round(looping_wav.get_length() * looping_wav.mix_rate)))
		looping_wav.loop_mode = AudioStreamWAV.LOOP_FORWARD
		source = looping_wav
	full_mix_player.stream = source
	full_mix_player.play()


func set_stem_volume_db(stem_id: StringName, volume_db: float) -> void:
	## Kept as the stable control point for the later instrument-stem mix.
	var player := stem_players.get(stem_id) as AudioStreamPlayer
	if player != null:
		player.volume_db = volume_db


func _on_stem_finished(stem_id: StringName) -> void:
	## Non-WAV stems still loop cleanly through the same controller.
	var player := stem_players.get(stem_id) as AudioStreamPlayer
	if player != null and player.stream != null:
		player.play()
