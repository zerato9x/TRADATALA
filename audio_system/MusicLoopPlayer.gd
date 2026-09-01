class_name MusicLoopPlayer
extends Node

signal catalog_loaded(track_count: int)
signal candidate_started(track_id: String, candidate_id: String)
signal loop_released(candidate_id: String)
signal error_occurred(message: String)

const CATALOG_PATH := "res://assets/audio/ost/ost_loops.json"

@export var catalog_path: String = CATALOG_PATH
@export var bus_name: StringName = &"Music"

var audio_player: AudioStreamPlayer
var runtime_stream: AudioStreamWAV
var catalog: Dictionary = {}
var tracks: Dictionary = {}
var catalog_is_loaded := false
var current_track_id := ""
var current_candidate_id := ""
var current_playback_position := 0.0
var stream_length_seconds := 0.0
var last_error := ""


func _ready() -> void:
	_ensure_player()
	load_catalog()


func _process(_delta: float) -> void:
	if audio_player != null and audio_player.playing:
		current_playback_position = audio_player.get_playback_position() + AudioServer.get_time_since_last_mix()
		if stream_length_seconds > 0.0:
			current_playback_position = fposmod(current_playback_position, stream_length_seconds)


func _exit_tree() -> void:
	stop()


func load_catalog(path: String = "") -> bool:
	if not path.is_empty():
		catalog_path = path
	if not FileAccess.file_exists(catalog_path):
		return _fail("Loop catalog is missing: %s" % catalog_path)
	var file := FileAccess.open(catalog_path, FileAccess.READ)
	if file == null:
		return _fail("Loop catalog cannot be opened: %s" % catalog_path)
	var parsed = JSON.parse_string(file.get_as_text())
	if not parsed is Dictionary:
		return _fail("Loop catalog root is not an object")
	if parsed.get("schema", "") != "tradatala.ost_loops.v1":
		return _fail("Unsupported loop catalog schema: %s" % String(parsed.get("schema", "<missing>")))
	var parsed_tracks = parsed.get("tracks", {})
	if not parsed_tracks is Dictionary or parsed_tracks.is_empty():
		return _fail("Loop catalog contains no tracks")
	catalog = parsed
	tracks = parsed_tracks
	catalog_is_loaded = true
	last_error = ""
	catalog_loaded.emit(tracks.size())
	return true


func get_track_ids() -> Array[String]:
	var result: Array[String] = []
	for value in tracks.keys():
		result.append(String(value))
	result.sort()
	return result


func get_track(track_id: String) -> Dictionary:
	var value = tracks.get(track_id, {})
	return value if value is Dictionary else {}


func get_candidates(track_id: String, distinct_only := true) -> Array[Dictionary]:
	var track := get_track(track_id)
	var raw = track.get("loop_candidates", [])
	if not raw is Array:
		return []
	var by_id: Dictionary = {}
	var all: Array[Dictionary] = []
	for value in raw:
		if not value is Dictionary:
			continue
		var candidate: Dictionary = value
		all.append(candidate)
		by_id[String(candidate.get("candidate_id", ""))] = candidate
	if not distinct_only:
		return all
	var result: Array[Dictionary] = []
	for id_value in track.get("distinct_candidate_ids", []):
		var candidate_id := String(id_value)
		if by_id.has(candidate_id):
			result.append(by_id[candidate_id])
	return result


func get_candidate(track_id: String, candidate_id: String) -> Dictionary:
	for candidate in get_candidates(track_id, false):
		if String(candidate.get("candidate_id", "")) == candidate_id:
			return candidate
	return {}


func play_track_from_start(track_id: String) -> bool:
	if not _load_track_stream(track_id):
		return false
	runtime_stream.loop_mode = AudioStreamWAV.LOOP_DISABLED
	current_candidate_id = ""
	audio_player.play(0.0)
	return true


func audition_candidate(track_id: String, candidate_id: String, lead_in_bars := 0) -> bool:
	var candidate := get_candidate(track_id, candidate_id)
	if candidate.is_empty():
		return _fail("Unknown loop candidate: %s / %s" % [track_id, candidate_id])
	if not _load_track_stream(track_id):
		return false
	var begin_sample := int(candidate.get("start_sample", -1))
	var end_sample := int(candidate.get("end_sample", -1))
	if begin_sample < 0 or end_sample <= begin_sample or end_sample > int(get_track(track_id).get("frame_count", 0)):
		return _fail("Candidate sample bounds are invalid: %s" % candidate_id)
	runtime_stream.loop_begin = begin_sample
	runtime_stream.loop_end = end_sample
	runtime_stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	current_candidate_id = candidate_id
	var start_seconds := float(candidate.get("start_seconds", 0.0))
	if lead_in_bars > 0:
		var lead_bar := maxi(0, int(candidate.get("bar_start", 0)) - lead_in_bars)
		var bars: Array = get_track(track_id).get("bars", [])
		if lead_bar < bars.size():
			start_seconds = float(bars[lead_bar].get("start_seconds", start_seconds))
	audio_player.play(start_seconds)
	candidate_started.emit(track_id, candidate_id)
	return true


func release_loop() -> bool:
	if runtime_stream == null or current_candidate_id.is_empty():
		return _fail("No candidate loop is active")
	var released_id := current_candidate_id
	runtime_stream.loop_mode = AudioStreamWAV.LOOP_DISABLED
	current_candidate_id = ""
	loop_released.emit(released_id)
	return true


func stop() -> void:
	if audio_player != null:
		audio_player.stop()
		audio_player.stream = null
	runtime_stream = null
	current_track_id = ""
	current_candidate_id = ""
	current_playback_position = 0.0
	stream_length_seconds = 0.0


func _load_track_stream(track_id: String) -> bool:
	if audio_player != null:
		audio_player.stop()
		audio_player.stream = null
	runtime_stream = null
	var track := get_track(track_id)
	if track.is_empty():
		return _fail("Unknown track: %s" % track_id)
	var project_path := String(track.get("project_path", ""))
	if project_path.is_empty() or not ResourceLoader.exists(project_path):
		return _fail("Track WAV is unavailable: %s" % project_path)
	var source := load(project_path) as AudioStreamWAV
	if source == null:
		return _fail("Track is not an AudioStreamWAV: %s" % project_path)
	runtime_stream = source.duplicate(true) as AudioStreamWAV
	runtime_stream.loop_mode = AudioStreamWAV.LOOP_DISABLED
	audio_player.stream = runtime_stream
	current_track_id = track_id
	stream_length_seconds = runtime_stream.get_length()
	last_error = ""
	return true


func _ensure_player() -> void:
	if audio_player != null:
		return
	audio_player = AudioStreamPlayer.new()
	audio_player.name = "LoopAuditionPlayer"
	audio_player.bus = bus_name
	add_child(audio_player)


func _fail(message: String) -> bool:
	last_error = message
	error_occurred.emit(message)
	return false
