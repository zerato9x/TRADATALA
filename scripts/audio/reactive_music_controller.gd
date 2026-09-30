class_name ReactiveMusicController
extends Node

const MUSIC_ANTI_FATIGUE_SCRIPT := preload("res://scripts/audio/music_anti_fatigue.gd")

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
var anti_fatigue: MusicAntiFatigue
var stem_players: Dictionary = {}
var mix_players: Array[AudioStreamPlayer] = []
var playlist: Array[Dictionary] = []
var active_mix_index: int = 0
var current_track_index: int = 0
var queued_track_index: int = -1
var transition_in_progress: bool = false
var transition_tween: Tween
var _transition_track_index := -1
var _transition_duration := TRANSITION_OVERLAP_SECONDS
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
@export var anti_fatigue_enabled: bool = true
@export var anti_fatigue_debug_logging: bool = false


func _ready() -> void:
	audio_driver_name = AudioServer.get_driver_name()
	music_rng.randomize()
	_build_playlist()
	_ensure_music_bus()
	anti_fatigue = MUSIC_ANTI_FATIGUE_SCRIPT.new()
	anti_fatigue.name = "MusicAntiFatigue"
	anti_fatigue.bus_name = MUSIC_BUS
	anti_fatigue.enabled = anti_fatigue_enabled
	anti_fatigue.debug_logging = anti_fatigue_debug_logging
	add_child(anti_fatigue)
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
	music_director.cue_held.connect(_on_dj_cue_held)
	music_director.cue_loop_completed.connect(_on_dj_cue_loop_completed)
	music_director.authored_transition_started.connect(_on_dj_transition_started)
	music_director.reprise_started.connect(_on_dj_transition_started)
	music_director.source_released.connect(_on_dj_source_released)
	music_director.source_finished.connect(_on_dj_source_finished)
	music_director.state_changed.connect(_on_dj_state_changed)
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
	if anti_fatigue != null:
		anti_fatigue.reset_variation(false)
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
	_reset_anti_fatigue(true)
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


func snapshot_state() -> Dictionary:
	var data := {"version": 1, "dj": dj_mode, "paused": music_paused,
		"shuffle": shuffle_enabled, "repeat": String(repeat_mode), "rng": music_rng.state,
		"track_path": current_mix_path,
		"queued_path": String(playlist[queued_track_index].path) if queued_track_index >= 0 else "",
		"anti_fatigue": anti_fatigue.snapshot_state()}
	if dj_mode:
		data["transport"] = music_director.snapshot_state()
	else:
		data["player"] = _player_checkpoint(full_mix_player)
		if transition_in_progress:
			data["fade"] = {"track_path": String(playlist[_transition_track_index].path),
				"player": _player_checkpoint(mix_players[1 - active_mix_index]),
				"remaining": maxf(0.001, _transition_duration - transition_tween.get_total_elapsed_time())}
	return data


func restore_snapshot(data: Dictionary) -> bool:
	if data.get("version") != 1 or not data.get("rng") is int \
			or StringName(data.get("repeat", "")) not in [REPEAT_OFF, REPEAT_ALL, REPEAT_ONE]:
		return false
	var track_index := _index_for_path(String(data.get("track_path", "")))
	if track_index < 0:
		return false
	music_paused = bool(data.get("paused", false))
	shuffle_enabled = bool(data.get("shuffle", false))
	repeat_mode = StringName(data.repeat)
	_stop_all_mix_players()
	music_director.stop()
	dj_mode = bool(data.get("dj", false))
	if dj_mode:
		if not data.get("transport") is Dictionary or not music_director.restore_snapshot(data.transport):
			return false
		full_mix_player = music_director.audio_player
		stem_players[&"full_mix"] = full_mix_player
		# The source may already have finished while the authored route stays active.
		var track_id := String(data.transport.get("track", ""))
		if track_id.is_empty():
			track_id = "%s_%d" % [playlist[track_index].theme_id, playlist[track_index].variant]
		_apply_dj_track_metadata(track_id)
	else:
		_play_initial_track(track_index)
		if not data.get("player") is Dictionary or not _restore_player(full_mix_player, data.player):
			return false
		if data.has("fade"):
			if not data.fade is Dictionary or not data.fade.get("player") is Dictionary:
				return false
			var incoming_index := _index_for_path(String(data.fade.get("track_path", "")))
			var remaining := float(data.fade.get("remaining", -1.0))
			if incoming_index < 0 or not is_finite(remaining) or remaining <= 0.0 or remaining > TRANSITION_OVERLAP_SECONDS:
				return false
			_begin_transition_to(incoming_index, data.fade)
			if not transition_in_progress:
				return false
	queued_track_index = _index_for_path(String(data.get("queued_path", "")))
	music_rng.state = data.rng
	if not data.get("anti_fatigue") is Dictionary or not anti_fatigue.restore_snapshot(data.anti_fatigue):
		return false
	full_mix_player.stream_paused = music_paused
	playback_options_changed.emit()
	pause_changed.emit(music_paused)
	return true


func _index_for_path(path: String) -> int:
	for index in playlist.size():
		if String(playlist[index].path) == path:
			return index
	return -1


func _player_checkpoint(player: AudioStreamPlayer) -> Dictionary:
	return {"position": player.get_playback_position(), "playing": player.has_stream_playback(), "volume": player.volume_db}


func _restore_player(player: AudioStreamPlayer, data: Dictionary) -> bool:
	var position := float(data.get("position", -1.0))
	var volume := float(data.get("volume", 0.0))
	if player.stream == null or not is_finite(position) or position < 0.0 \
			or position > player.stream.get_length() or not is_finite(volume) or volume < SILENCE_DB or volume > 0.0:
		return false
	player.stop()
	player.volume_db = volume
	if bool(data.get("playing", true)):
		player.play(position)
	player.stream_paused = music_paused
	return true


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


func _on_dj_cue_held(_track_id: String, cue_id: String) -> void:
	if anti_fatigue != null:
		anti_fatigue.cue_started(cue_id)


func _on_dj_cue_loop_completed(_track_id: String, cue_id: String) -> void:
	if anti_fatigue != null:
		anti_fatigue.loop_completed(cue_id)


func _on_dj_transition_started(_from_cue_id: String, _to_cue_id: String) -> void:
	if anti_fatigue != null:
		anti_fatigue.prepare_for_cue_change()


func _on_dj_source_released(_track_id: String) -> void:
	if anti_fatigue != null:
		anti_fatigue.reset_variation(true)


func _on_dj_source_finished(_track_id: String) -> void:
	if anti_fatigue != null:
		anti_fatigue.reset_variation(false)


func _on_dj_state_changed(next_state: StringName) -> void:
	if next_state == MusicDirector.STATE_STOPPED and anti_fatigue != null:
		anti_fatigue.reset_variation(false)


func _reset_anti_fatigue(immediate: bool) -> void:
	if anti_fatigue != null:
		anti_fatigue.reset_variation(not immediate)


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


func _begin_transition_to(track_index: int, checkpoint: Dictionary = {}) -> void:
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
	if not checkpoint.is_empty() and not _restore_player(incoming, checkpoint.player):
		incoming.stop()
		return
	transition_in_progress = true
	_transition_track_index = track_index
	var outgoing_index := active_mix_index
	var outgoing := mix_players[outgoing_index]
	transition_tween = create_tween().set_parallel(true)
	var duration := float(checkpoint.get("remaining", TRANSITION_OVERLAP_SECONDS))
	_transition_duration = duration
	transition_tween.tween_property(outgoing, "volume_db", SILENCE_DB, duration)
	transition_tween.tween_property(incoming, "volume_db", 0.0, duration)
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
	_transition_track_index = -1
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
	_transition_track_index = -1
	for player in mix_players:
		player.stop()
		player.stream = null
		player.volume_db = 0.0


func set_stem_volume_db(stem_id: StringName, volume_db: float) -> void:
	var player := stem_players.get(stem_id) as AudioStreamPlayer
	if player != null:
		player.volume_db = volume_db
