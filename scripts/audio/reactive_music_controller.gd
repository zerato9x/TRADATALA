class_name ReactiveMusicController
extends Node

signal beat_detected(strength: float)
signal bass_energy_changed(energy: float)
signal band_pulse(band_index: int, strength: float)
signal band_energy_changed(band_index: int, energy: float)
signal mix_started(mix_path: String, theme_id: StringName, variant: int)
signal pause_changed(paused: bool)
signal playback_options_changed()

const MUSIC_BUS := &"Music"
const OST_ROOT := "res://assets/audio/ost"
const TRANSITION_OVERLAP_SECONDS := 0.1
const SILENCE_DB := -60.0
const REPEAT_OFF := &"off"
const REPEAT_ALL := &"all"
const REPEAT_ONE := &"one"
const THEME_ORDER: Array[StringName] = [
	&"main", &"mouse", &"ox", &"tiger", &"cat", &"dragon", &"snake",
	&"horse", &"goat", &"monkey", &"rooster", &"dog", &"pig",
]
const THEME_TITLES := {
	&"main": "CAI LUONG x VONG CO FUNK",
	&"mouse": "NAM BO x JAZZ FUNK",
	&"ox": "TAY NGUYEN x AFRO FUNK",
	&"tiger": "CHAM x HARD FUNK",
	&"cat": "CA TRU x DEEP FUNK",
	&"dragon": "TAY-NUNG-THAI x P-FUNK",
	&"snake": "KHEN H'MONG x PSYCHEDELIC FUNK",
	&"horse": "TAY NGUYEN x GO-GO",
	&"goat": "CA HUE x BOOGIE",
	&"monkey": "NAM BO x NEW ORLEANS FUNK",
	&"rooster": "CA TRU x ELECTRO FUNK",
	&"dog": "TAY-NUNG-THAI x SOUL FUNK",
	&"pig": "XOAN x DISCO FUNK",
}

var full_mix_player: AudioStreamPlayer
var beat_detector: MusicBeatDetector
var music_director: MusicDirector
var stem_players: Dictionary = {}
var mix_players: Array[AudioStreamPlayer] = []
var playlist: Array[Dictionary] = []
var active_mix_index: int = 0
var current_track_index: int = 0
var queued_track_index: int = -1
var transition_in_progress: bool = false
var transition_tween: Tween
var music_paused: bool = false
var shuffle_enabled: bool = false
var repeat_mode: StringName = REPEAT_OFF
var music_rng := RandomNumberGenerator.new()
var dj_mode := false

var current_theme_id: StringName = &"main"
var current_variant: int = 1
var current_mix_path: String = ""

@export_group("Runtime Diagnostics")
@export var audio_driver_name: String = ""
@export var playback_position_seconds: float = 0.0
@export var stream_length_seconds: float = 0.0
@export var music_bus_peak_db: float = -200.0
@export var music_bus_muted: bool = false
@export var master_bus_muted: bool = false


func _ready() -> void:
	audio_driver_name = AudioServer.get_driver_name()
	music_rng.randomize()
	_build_playlist()
	_ensure_music_bus()
	mix_players.append(_create_mix_player("FullMixA", 0))
	mix_players.append(_create_mix_player("FullMixB", 1))
	full_mix_player = mix_players[active_mix_index]
	stem_players[&"full_mix"] = full_mix_player
	beat_detector = MusicBeatDetector.new()
	beat_detector.name = "BeatDetector"
	beat_detector.bus_name = MUSIC_BUS
	beat_detector.beat_detected.connect(beat_detected.emit)
	beat_detector.bass_energy_changed.connect(bass_energy_changed.emit)
	beat_detector.band_pulse.connect(band_pulse.emit)
	beat_detector.band_energy_changed.connect(band_energy_changed.emit)
	add_child(beat_detector)
	music_director = MusicDirector.new()
	music_director.name = "MusicDirector"
	music_director.bus_name = MUSIC_BUS
	add_child(music_director)
	call_deferred("play_track", 0, false)


func _process(_delta: float) -> void:
	if dj_mode and music_director != null:
		playback_position_seconds = music_director.current_playback_position
		stream_length_seconds = music_director.stream_length_seconds
	elif full_mix_player != null and full_mix_player.stream != null:
		playback_position_seconds = full_mix_player.get_playback_position()
		stream_length_seconds = full_mix_player.stream.get_length()
		if not transition_in_progress and full_mix_player.playing:
			var remaining := stream_length_seconds - playback_position_seconds
			if remaining <= TRANSITION_OVERLAP_SECONDS:
				_begin_boundary_transition()
	var music_bus_index := AudioServer.get_bus_index(MUSIC_BUS)
	if music_bus_index >= 0:
		music_bus_peak_db = AudioServer.get_bus_peak_volume_left_db(music_bus_index, 0)
		music_bus_muted = AudioServer.is_bus_mute(music_bus_index)
	var master_bus_index := AudioServer.get_bus_index(&"Master")
	if master_bus_index >= 0:
		master_bus_muted = AudioServer.is_bus_mute(master_bus_index)


func _exit_tree() -> void:
	if beat_detector != null:
		beat_detector.set_process(false)
	if transition_tween != null and transition_tween.is_valid():
		transition_tween.kill()
	for player in mix_players:
		player.stop()
		player.stream = null
	if music_director != null:
		music_director.stop()
	stem_players.clear()


func _build_playlist() -> void:
	playlist.clear()
	for theme_id in THEME_ORDER:
		for variant in [1, 2]:
			playlist.append({
				"path": mix_path_for_theme(theme_id, variant),
				"theme_id": theme_id,
				"variant": variant,
			})


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


func _create_mix_player(player_name: String, player_index: int) -> AudioStreamPlayer:
	var player := AudioStreamPlayer.new()
	player.name = player_name
	player.bus = MUSIC_BUS
	player.finished.connect(_on_mix_finished.bind(player_index))
	add_child(player)
	return player


static func display_title_for_theme(theme_id: StringName) -> String:
	return String(THEME_TITLES.get(theme_id, String(theme_id).to_upper()))


static func mix_path_for_theme(theme_id: StringName, variant: int) -> String:
	return "%s/%s_%d.wav" % [OST_ROOT, theme_id, clampi(variant, 1, 2)]


func track_label(track_index: int) -> String:
	if track_index < 0 or track_index >= playlist.size():
		return ""
	var track := playlist[track_index]
	return "%s - SIDE %d" % [String(track["theme_id"]).to_upper(), int(track["variant"])]


func next_mix_request() -> Dictionary:
	if dj_mode:
		return {}
	var next_index := _ensure_next_track_index()
	return playlist[next_index].duplicate() if next_index >= 0 else {}


func play_track(track_index: int, crossfade: bool = true) -> void:
	if track_index < 0 or track_index >= playlist.size():
		return
	if dj_mode:
		dj_mode = false
		music_director.stop()
	queued_track_index = -1
	if crossfade and full_mix_player != null and full_mix_player.playing:
		_begin_transition_to(track_index)
	else:
		_play_initial_track(track_index)


func set_shuffle_enabled(enabled: bool) -> void:
	if shuffle_enabled == enabled:
		return
	shuffle_enabled = enabled
	queued_track_index = -1
	playback_options_changed.emit()


func toggle_shuffle() -> void:
	set_shuffle_enabled(not shuffle_enabled)


func cycle_repeat_mode() -> void:
	match repeat_mode:
		REPEAT_OFF:
			repeat_mode = REPEAT_ALL
		REPEAT_ALL:
			repeat_mode = REPEAT_ONE
		_:
			repeat_mode = REPEAT_OFF
	queued_track_index = -1
	playback_options_changed.emit()


func set_music_paused(paused: bool) -> void:
	if music_paused == paused:
		return
	music_paused = paused
	for player in mix_players:
		player.stream_paused = paused
	if music_director != null and music_director.audio_player != null:
		music_director.audio_player.stream_paused = paused
	pause_changed.emit(paused)


func start_dj_track(track_id: String, cue_id: String) -> bool:
	if music_director == null or not music_director.hold_cue(track_id, cue_id):
		return false
	_stop_all_mix_players()
	dj_mode = true
	queued_track_index = -1
	full_mix_player = music_director.audio_player
	stem_players[&"full_mix"] = full_mix_player
	full_mix_player.stream_paused = music_paused
	_apply_dj_track_metadata(track_id)
	return true


func request_dj_cue(cue_id: String) -> bool:
	return dj_mode and music_director != null and music_director.request_cue(cue_id)


func release_dj_to_end() -> bool:
	return dj_mode and music_director != null and music_director.release_to_end()


func _apply_dj_track_metadata(track_id: String) -> void:
	var track := music_director.get_track(track_id)
	current_mix_path = String(track.get("project_path", ""))
	var separator := track_id.rfind("_")
	if separator > 0:
		current_theme_id = StringName(track_id.left(separator))
		current_variant = maxi(1, int(track_id.substr(separator + 1)))
	for track_index in playlist.size():
		if String(playlist[track_index].get("path", "")) == current_mix_path:
			current_track_index = track_index
			break
	playback_position_seconds = music_director.current_playback_position
	stream_length_seconds = music_director.stream_length_seconds
	mix_started.emit(current_mix_path, current_theme_id, current_variant)


func toggle_music_paused() -> void:
	set_music_paused(not music_paused)


func _next_track_index() -> int:
	if playlist.is_empty():
		return -1
	if repeat_mode == REPEAT_ONE:
		return current_track_index
	if shuffle_enabled:
		if playlist.size() == 1:
			return 0
		var next_index := music_rng.randi_range(0, playlist.size() - 2)
		return next_index + 1 if next_index >= current_track_index else next_index
	var next_index := current_track_index + 1
	if next_index < playlist.size():
		return next_index
	return 0 if repeat_mode == REPEAT_ALL else -1


func _ensure_next_track_index() -> int:
	if queued_track_index < 0:
		queued_track_index = _next_track_index()
	return queued_track_index


func _play_initial_track(track_index: int) -> void:
	_stop_all_mix_players()
	active_mix_index = 0
	var player := mix_players[active_mix_index]
	var request := playlist[track_index]
	var source := load(String(request["path"])) as AudioStream
	if source == null:
		push_warning("Music track is missing: %s" % request["path"])
		return
	player.stream = source
	player.volume_db = 0.0
	player.play()
	_apply_active_track(player, track_index)


func _begin_boundary_transition() -> void:
	var next_index := _ensure_next_track_index()
	if next_index >= 0:
		_begin_transition_to(next_index)


func _begin_transition_to(track_index: int) -> void:
	if transition_in_progress or track_index < 0 or track_index >= playlist.size():
		return
	var request := playlist[track_index]
	var next_index := 1 - active_mix_index
	var incoming := mix_players[next_index]
	var source := load(String(request["path"])) as AudioStream
	if source == null:
		push_warning("Music track is missing: %s" % request["path"])
		return
	incoming.stop()
	incoming.stream = source
	incoming.volume_db = SILENCE_DB
	incoming.play()
	incoming.stream_paused = music_paused
	transition_in_progress = true
	var outgoing_index := active_mix_index
	var outgoing := mix_players[outgoing_index]
	transition_tween = create_tween().set_parallel(true)
	transition_tween.tween_property(outgoing, "volume_db", SILENCE_DB, TRANSITION_OVERLAP_SECONDS)
	transition_tween.tween_property(incoming, "volume_db", 0.0, TRANSITION_OVERLAP_SECONDS)
	transition_tween.finished.connect(
		_complete_transition.bind(outgoing_index, next_index, track_index), CONNECT_ONE_SHOT
	)


func _complete_transition(outgoing_index: int, next_index: int, track_index: int) -> void:
	var outgoing := mix_players[outgoing_index]
	outgoing.stop()
	outgoing.stream = null
	outgoing.volume_db = 0.0
	active_mix_index = next_index
	_apply_active_track(mix_players[next_index], track_index)
	transition_in_progress = false
	transition_tween = null


func _on_mix_finished(player_index: int) -> void:
	if dj_mode or player_index != active_mix_index or transition_in_progress:
		return
	var next_index := _ensure_next_track_index()
	if next_index < 0:
		playback_position_seconds = stream_length_seconds
		return
	_play_initial_track(next_index)


func _apply_active_track(player: AudioStreamPlayer, track_index: int) -> void:
	var request := playlist[track_index]
	queued_track_index = -1
	full_mix_player = player
	stem_players[&"full_mix"] = player
	current_track_index = track_index
	current_theme_id = request["theme_id"]
	current_variant = int(request["variant"])
	current_mix_path = String(request["path"])
	playback_position_seconds = 0.0
	stream_length_seconds = player.stream.get_length() if player.stream != null else 0.0
	player.stream_paused = music_paused
	mix_started.emit(current_mix_path, current_theme_id, current_variant)


func _stop_all_mix_players() -> void:
	if transition_tween != null and transition_tween.is_valid():
		transition_tween.kill()
	transition_tween = null
	transition_in_progress = false
	for player in mix_players:
		player.stop()
		player.stream = null
		player.volume_db = 0.0


func set_stem_volume_db(stem_id: StringName, volume_db: float) -> void:
	var player := stem_players.get(stem_id) as AudioStreamPlayer
	if player != null:
		player.volume_db = volume_db
