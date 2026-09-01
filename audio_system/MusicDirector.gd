class_name MusicDirector
extends Node

signal catalogs_loaded(track_count: int)
signal candidate_audition_started(track_id: String, candidate_id: String, lead_in_bars: int)
signal cue_held(track_id: String, cue_id: String)
signal cue_requested(from_cue_id: String, to_cue_id: String)
signal authored_transition_started(from_cue_id: String, to_cue_id: String)
signal reprise_started(from_cue_id: String, to_cue_id: String)
signal source_released(track_id: String)
signal source_finished(track_id: String)
signal state_changed(next_state: StringName)
signal error_occurred(message: String)

const STATE_STOPPED: StringName = &"STOPPED"
const STATE_PLAYING_SOURCE: StringName = &"PLAYING_SOURCE"
const STATE_AUDITIONING_CUE: StringName = &"AUDITIONING_CUE"
const STATE_HOLDING_CUE: StringName = &"HOLDING_CUE"
const STATE_TRAVELING_FORWARD: StringName = &"TRAVELING_FORWARD"
const STATE_REWIND_PENDING: StringName = &"REWIND_PENDING"
const STATE_RELEASED_TO_END: StringName = &"RELEASED_TO_END"
const POSITION_EPSILON_SECONDS := 0.03

@export var loop_catalog_path := MusicCueCatalog.LOOP_CATALOG_PATH
@export var cue_catalog_path := MusicCueCatalog.CUE_CATALOG_PATH
@export var bus_name: StringName = &"Music"

var cue_catalog := MusicCueCatalog.new()
var audio_player: AudioStreamPlayer
var runtime_stream: AudioStreamWAV
var catalogs_are_loaded := false
var current_track_id := ""
var current_cue_id := ""
var pending_cue_id := ""
var state: StringName = STATE_STOPPED
var current_playback_position := 0.0
var stream_length_seconds := 0.0
var last_error := ""
var _rewind_boundary_end := -1.0
var _last_playback_position := 0.0


func _ready() -> void:
	_ensure_player()
	load_catalogs()


func _process(_delta: float) -> void:
	if audio_player == null or not audio_player.playing:
		return
	current_playback_position = _read_position()
	match state:
		STATE_AUDITIONING_CUE, STATE_TRAVELING_FORWARD:
			_catch_pending_cue_if_reached()
		STATE_REWIND_PENDING:
			var crossed_boundary := _rewind_boundary_end >= 0.0 \
				and current_playback_position + POSITION_EPSILON_SECONDS >= _rewind_boundary_end
			var wrapped_unexpectedly := current_playback_position + 0.25 < _last_playback_position
			if crossed_boundary or wrapped_unexpectedly:
				_jump_and_hold(pending_cue_id)
	_last_playback_position = current_playback_position


func _exit_tree() -> void:
	stop()


func load_catalogs() -> bool:
	catalogs_are_loaded = false
	if not cue_catalog.load_catalogs(loop_catalog_path, cue_catalog_path):
		return _fail(cue_catalog.last_error)
	catalogs_are_loaded = true
	last_error = ""
	catalogs_loaded.emit(cue_catalog.get_track_ids().size())
	return true


func get_track_ids() -> Array[String]:
	return cue_catalog.get_track_ids()


func get_track(track_id: String) -> Dictionary:
	return cue_catalog.get_track(track_id)


func get_candidates(track_id: String, distinct_only := true) -> Array[Dictionary]:
	return cue_catalog.get_candidates(track_id, distinct_only)


func get_candidate(track_id: String, candidate_id: String) -> Dictionary:
	return cue_catalog.get_candidate(track_id, candidate_id)


func get_approved_cues(track_id: String) -> Array[Dictionary]:
	return cue_catalog.get_approved_cues(track_id)


func get_manual_status(track_id: String, candidate_id: String) -> StringName:
	return cue_catalog.get_manual_status(track_id, candidate_id)


func set_manual_decision(track_id: String, candidate_id: String, status: StringName, cue_name := "", notes := "") -> bool:
	if not cue_catalog.set_manual_decision(track_id, candidate_id, status, cue_name, notes):
		return _fail(cue_catalog.last_error)
	if not cue_catalog.save_cues():
		return _fail(cue_catalog.last_error)
	last_error = ""
	return true


func play_track_from_start(track_id: String) -> bool:
	if not _load_track(track_id):
		return false
	runtime_stream.loop_mode = AudioStreamWAV.LOOP_DISABLED
	_clear_transport_targets()
	audio_player.play(0.0)
	_last_playback_position = 0.0
	_set_state(STATE_PLAYING_SOURCE)
	return true


func audition_candidate(track_id: String, candidate_id: String, lead_in_bars := 0) -> bool:
	var candidate := cue_catalog.get_candidate(track_id, candidate_id)
	if candidate.is_empty():
		return _fail("Unknown candidate: %s / %s" % [track_id, candidate_id])
	if not _load_track(track_id) or not _configure_loop(candidate):
		return false
	var start_seconds := float(candidate.get("start_seconds", 0.0))
	if lead_in_bars > 0:
		var lead_bar := maxi(0, int(candidate.get("bar_start", 0)) - lead_in_bars)
		var bars: Array = cue_catalog.get_track(track_id).get("bars", [])
		if lead_bar < bars.size():
			start_seconds = float(bars[lead_bar].get("start_seconds", start_seconds))
	current_cue_id = candidate_id if lead_in_bars == 0 else ""
	pending_cue_id = "" if lead_in_bars == 0 else candidate_id
	_rewind_boundary_end = -1.0
	audio_player.play(start_seconds)
	current_playback_position = start_seconds
	_last_playback_position = start_seconds
	_set_state(STATE_HOLDING_CUE if lead_in_bars == 0 else STATE_AUDITIONING_CUE)
	candidate_audition_started.emit(track_id, candidate_id, lead_in_bars)
	return true


func hold_cue(track_id: String, cue_id: String) -> bool:
	if cue_catalog.get_manual_status(track_id, cue_id) != &"approved":
		return _fail("Cue is not manually approved: %s / %s" % [track_id, cue_id])
	if not _load_track(track_id):
		return false
	return _jump_and_hold(cue_id)


func request_cue(cue_id: String) -> bool:
	if current_track_id.is_empty() or runtime_stream == null:
		return _fail("No track is active")
	if cue_catalog.get_manual_status(current_track_id, cue_id) != &"approved":
		return _fail("Cue is not manually approved: %s" % cue_id)
	var target := cue_catalog.get_candidate(current_track_id, cue_id)
	if target.is_empty():
		return _fail("Cue does not exist in current track: %s" % cue_id)
	if cue_id == current_cue_id and state == STATE_HOLDING_CUE:
		last_error = ""
		return true

	var from_cue := current_cue_id
	var target_start := float(target.get("start_seconds", 0.0))
	var target_end := float(target.get("end_seconds", target_start))
	var current := cue_catalog.get_candidate(current_track_id, current_cue_id)
	if state == STATE_HOLDING_CUE and not current.is_empty():
		var current_start := float(current.get("start_seconds", current_playback_position))
		var current_end := float(current.get("end_seconds", current_playback_position))
		if target_start + POSITION_EPSILON_SECONDS >= current_end:
			cue_requested.emit(from_cue, cue_id)
			return _travel_forward_to_cue(target)
		if target_start > current_start + POSITION_EPSILON_SECONDS \
				and target_end > current_end + POSITION_EPSILON_SECONDS:
			cue_requested.emit(from_cue, cue_id)
			return _travel_forward_to_cue(target)
		if target_start < current_start - POSITION_EPSILON_SECONDS:
			cue_requested.emit(from_cue, cue_id)
			runtime_stream.loop_mode = AudioStreamWAV.LOOP_DISABLED
			pending_cue_id = cue_id
			_rewind_boundary_end = current_end
			_set_state(STATE_REWIND_PENDING)
			reprise_started.emit(from_cue, cue_id)
			last_error = ""
			return true
		return _fail("Cue overlaps the current hold without extending it forward; use jump_to_cue: %s" % cue_id)

	cue_requested.emit(from_cue, cue_id)
	if target_start > current_playback_position + POSITION_EPSILON_SECONDS:
		return _travel_forward_to_cue(target)
	return _jump_and_hold(cue_id)


func release_to_next_cue() -> bool:
	if current_track_id.is_empty():
		return _fail("No track is active")
	if state in [STATE_TRAVELING_FORWARD, STATE_REWIND_PENDING, STATE_AUDITIONING_CUE]:
		return _fail("A cue move is already in progress")
	var current := cue_catalog.get_candidate(current_track_id, current_cue_id)
	var earliest_start := current_playback_position + POSITION_EPSILON_SECONDS
	if state == STATE_HOLDING_CUE and not current.is_empty():
		earliest_start = float(current.get("end_seconds", earliest_start)) - POSITION_EPSILON_SECONDS
	for cue in cue_catalog.get_approved_cues(current_track_id):
		if float(cue.get("start_seconds", -1.0)) >= earliest_start:
			return request_cue(String(cue.get("candidate_id", "")))
	return release_to_end()


func reprise_previous_cue() -> bool:
	if current_track_id.is_empty() or current_cue_id.is_empty():
		return _fail("No current cue to reprise from")
	var current := cue_catalog.get_candidate(current_track_id, current_cue_id)
	var current_start := float(current.get("start_seconds", current_playback_position))
	var previous_id := ""
	for cue in cue_catalog.get_approved_cues(current_track_id):
		if float(cue.get("start_seconds", 0.0)) >= current_start - POSITION_EPSILON_SECONDS:
			break
		previous_id = String(cue.get("candidate_id", ""))
	if previous_id.is_empty():
		return _fail("No earlier approved cue exists")
	return request_cue(previous_id)


func jump_to_cue(cue_id: String) -> bool:
	if current_track_id.is_empty():
		return _fail("No track is active")
	if cue_catalog.get_manual_status(current_track_id, cue_id) != &"approved":
		return _fail("Cue is not manually approved: %s" % cue_id)
	return _jump_and_hold(cue_id)


func release_to_end() -> bool:
	if runtime_stream == null:
		return _fail("No track is active")
	runtime_stream.loop_mode = AudioStreamWAV.LOOP_DISABLED
	current_cue_id = ""
	pending_cue_id = ""
	_rewind_boundary_end = -1.0
	_set_state(STATE_RELEASED_TO_END)
	last_error = ""
	source_released.emit(current_track_id)
	return true


func stop() -> void:
	if audio_player != null:
		audio_player.stop()
		audio_player.stream = null
	runtime_stream = null
	current_track_id = ""
	_clear_transport_targets()
	current_playback_position = 0.0
	stream_length_seconds = 0.0
	_last_playback_position = 0.0
	_set_state(STATE_STOPPED)


func _travel_forward_to_cue(target: Dictionary) -> bool:
	if not _configure_loop(target):
		return false
	pending_cue_id = String(target.get("candidate_id", ""))
	_rewind_boundary_end = -1.0
	_set_state(STATE_TRAVELING_FORWARD)
	authored_transition_started.emit(current_cue_id, pending_cue_id)
	last_error = ""
	return true


func _catch_pending_cue_if_reached() -> void:
	var target := cue_catalog.get_candidate(current_track_id, pending_cue_id)
	if target.is_empty():
		_fail("Pending cue disappeared from the catalog: %s" % pending_cue_id)
		return
	if current_playback_position + POSITION_EPSILON_SECONDS < float(target.get("start_seconds", 0.0)):
		return
	current_cue_id = pending_cue_id
	pending_cue_id = ""
	_set_state(STATE_HOLDING_CUE)
	cue_held.emit(current_track_id, current_cue_id)


func _jump_and_hold(cue_id: String) -> bool:
	var cue := cue_catalog.get_candidate(current_track_id, cue_id)
	if cue.is_empty() or not _configure_loop(cue):
		return _fail("Cannot hold missing cue: %s" % cue_id)
	current_cue_id = cue_id
	pending_cue_id = ""
	_rewind_boundary_end = -1.0
	var cue_start := float(cue.get("start_seconds", 0.0))
	audio_player.play(cue_start)
	current_playback_position = cue_start
	_last_playback_position = cue_start
	_set_state(STATE_HOLDING_CUE)
	last_error = ""
	cue_held.emit(current_track_id, cue_id)
	return true


func _configure_loop(cue: Dictionary) -> bool:
	if runtime_stream == null:
		return _fail("Runtime stream is unavailable")
	var begin_sample := int(cue.get("start_sample", -1))
	var end_sample := int(cue.get("end_sample", -1))
	var frame_count := int(cue_catalog.get_track(current_track_id).get("frame_count", 0))
	if begin_sample < 0 or end_sample <= begin_sample or end_sample > frame_count:
		return _fail("Cue has invalid sample bounds: %s" % String(cue.get("candidate_id", "<unknown>")))
	runtime_stream.loop_begin = begin_sample
	runtime_stream.loop_end = end_sample
	runtime_stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	return true


func _load_track(track_id: String) -> bool:
	if audio_player != null:
		audio_player.stop()
		audio_player.stream = null
	runtime_stream = null
	var track := cue_catalog.get_track(track_id)
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
	current_playback_position = 0.0
	last_error = ""
	return true


func _read_position() -> float:
	var value := audio_player.get_playback_position() + AudioServer.get_time_since_last_mix()
	return clampf(value, 0.0, stream_length_seconds) if stream_length_seconds > 0.0 else maxf(0.0, value)


func _ensure_player() -> void:
	if audio_player != null:
		return
	audio_player = AudioStreamPlayer.new()
	audio_player.name = "MusicDJPlayer"
	audio_player.bus = bus_name
	audio_player.finished.connect(_on_audio_finished)
	add_child(audio_player)


func _on_audio_finished() -> void:
	var finished_track_id := current_track_id
	stop()
	source_finished.emit(finished_track_id)


func _clear_transport_targets() -> void:
	current_cue_id = ""
	pending_cue_id = ""
	_rewind_boundary_end = -1.0


func _set_state(next_state: StringName) -> void:
	if state == next_state:
		return
	state = next_state
	state_changed.emit(state)


func _fail(message: String) -> bool:
	last_error = message
	error_occurred.emit(message)
	return false
