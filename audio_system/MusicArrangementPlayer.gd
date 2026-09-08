class_name MusicArrangementPlayer
extends Node

signal arrangement_started(track_id: String, section_count: int, duration_seconds: float)
signal arrangement_section_changed(section_index: int, label: String, candidate_id: String)
signal arrangement_finished(track_id: String)
signal error_occurred(message: String)

const STATE_STOPPED: StringName = &"STOPPED"
const STATE_PLAYING: StringName = &"PLAYING_ARRANGEMENT"
const MAX_REPEAT_COUNT := 64

@export var loop_catalog_path := MusicCueCatalog.LOOP_CATALOG_PATH
@export var cue_catalog_path := MusicCueCatalog.CUE_CATALOG_PATH
@export var bus_name: StringName = &"Music"

var cue_catalog := MusicCueCatalog.new()
var audio_player: AudioStreamPlayer
var runtime_stream: AudioStreamWAV
var catalogs_are_loaded := false
var current_track_id := ""
var current_arrangement: Array[Dictionary] = []
var timeline: Array[Dictionary] = []
var current_section_index := -1
var current_playback_position := 0.0
var stream_length_seconds := 0.0
var state: StringName = STATE_STOPPED
var last_error := ""
var arrangement_loop_enabled := true


func _ready() -> void:
	_ensure_player()
	load_catalogs()


func _process(_delta: float) -> void:
	if audio_player == null or not audio_player.playing:
		return
	current_playback_position = audio_player.get_playback_position() + AudioServer.get_time_since_last_mix()
	if stream_length_seconds > 0.0:
		current_playback_position = clampf(current_playback_position, 0.0, stream_length_seconds)
	_update_section_for_position(current_playback_position)


func _exit_tree() -> void:
	stop()


func load_catalogs() -> bool:
	catalogs_are_loaded = false
	if not cue_catalog.load_catalogs(loop_catalog_path, cue_catalog_path):
		return _fail(cue_catalog.last_error)
	catalogs_are_loaded = true
	last_error = ""
	return true


func set_catalog(catalog: MusicCueCatalog) -> void:
	if catalog != null:
		cue_catalog = catalog
		catalogs_are_loaded = true


func get_track_ids() -> Array[String]:
	return cue_catalog.get_track_ids()


func is_playing() -> bool:
	return audio_player != null and audio_player.playing and state == STATE_PLAYING


func get_section_count() -> int:
	return current_arrangement.size()


func get_timeline() -> Array[Dictionary]:
	return timeline.duplicate(true)


func play_arrangement(track_id: String, sections: Array[Dictionary], loop_enabled := true) -> bool:
	var built := build_arrangement(track_id, sections)
	if built.is_empty():
		return false
	stop()
	runtime_stream = built["stream"] as AudioStreamWAV
	audio_player.stream = runtime_stream
	arrangement_loop_enabled = loop_enabled
	if arrangement_loop_enabled:
		runtime_stream.loop_begin = 0
		runtime_stream.loop_end = int(built["total_samples"])
		runtime_stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	else:
		runtime_stream.loop_mode = AudioStreamWAV.LOOP_DISABLED
	current_track_id = track_id
	current_arrangement = sections.duplicate(true)
	timeline = built["timeline"].duplicate(true)
	stream_length_seconds = float(built["duration_seconds"])
	current_playback_position = 0.0
	current_section_index = -1
	last_error = ""
	audio_player.play(0.0)
	_set_state(STATE_PLAYING)
	arrangement_started.emit(current_track_id, current_arrangement.size(), stream_length_seconds)
	_update_section_for_position(0.0)
	return true


func build_arrangement(track_id: String, sections: Array[Dictionary]) -> Dictionary:
	if not catalogs_are_loaded:
		return _fail_result("Music catalogs are not loaded")
	if sections.is_empty():
		return _fail_result("Arrangement has no sections")
	var track := cue_catalog.get_track(track_id)
	if track.is_empty():
		return _fail_result("Unknown arrangement track: %s" % track_id)
	var source_path := String(track.get("project_path", ""))
	if source_path.is_empty() or not FileAccess.file_exists(source_path):
		return _fail_result("Arrangement source WAV is unavailable: %s" % source_path)
	var source_info := _read_pcm_wav(source_path)
	if source_info.is_empty():
		return _fail_result("Arrangement requires an uncompressed PCM 8-bit or 16-bit WAV source: %s" % track_id)
	var source_data: PackedByteArray = source_info["data"]
	var bytes_per_sample: int = int(source_info["bytes_per_sample"])
	var channel_count: int = int(source_info["channels"])
	var frame_bytes := bytes_per_sample * channel_count
	var catalog_frame_count := int(track.get("frame_count", 0))
	var source_frame_count: int = int(source_info["frame_count"])
	if catalog_frame_count <= 0 or source_frame_count < catalog_frame_count:
		return _fail_result("Arrangement source data is shorter than its catalog frame count: %s" % track_id)

	var assembled_data := PackedByteArray()
	var built_timeline: Array[Dictionary] = []
	var total_samples := 0
	for section_index in range(sections.size()):
		var section: Dictionary = sections[section_index]
		var candidate_id := String(section.get("candidate_id", ""))
		var candidate := cue_catalog.get_candidate(track_id, candidate_id)
		if candidate.is_empty():
			return _fail_result("Arrangement section %d references an unknown candidate: %s" % [section_index + 1, candidate_id])
		var start_sample := int(candidate.get("start_sample", -1))
		var end_sample := int(candidate.get("end_sample", -1))
		if start_sample < 0 or end_sample <= start_sample or end_sample > catalog_frame_count:
			return _fail_result("Arrangement section %d has invalid sample bounds: %s" % [section_index + 1, candidate_id])
		var repeat_count := clampi(int(section.get("repeat_count", 1)), 1, MAX_REPEAT_COUNT)
		var section_label := String(section.get("label", "Section %02d" % (section_index + 1))).strip_edges()
		if section_label.is_empty():
			section_label = "Section %02d" % (section_index + 1)
		var start_byte := start_sample * frame_bytes
		var end_byte := end_sample * frame_bytes
		var segment_data: PackedByteArray = source_data.slice(start_byte, end_byte)
		for repeat_index in range(repeat_count):
			var timeline_start := total_samples
			assembled_data.append_array(segment_data)
			total_samples += end_sample - start_sample
			built_timeline.append({
				"section_index": section_index,
				"repeat_index": repeat_index,
				"label": section_label,
				"candidate_id": candidate_id,
				"start_sample": timeline_start,
				"end_sample": total_samples,
				"duration_seconds": float(end_sample - start_sample) / float(source_info["mix_rate"]),
			})
	if assembled_data.is_empty() or total_samples <= 0:
		return _fail_result("Arrangement produced no audio data")
	var assembled_stream := AudioStreamWAV.new()
	assembled_stream.format = int(source_info["format"])
	assembled_stream.stereo = channel_count == 2
	assembled_stream.mix_rate = int(source_info["mix_rate"])
	assembled_stream.data = assembled_data
	assembled_stream.loop_mode = AudioStreamWAV.LOOP_DISABLED
	assembled_stream.loop_begin = 0
	assembled_stream.loop_end = total_samples
	return {
		"stream": assembled_stream,
		"timeline": built_timeline,
		"total_samples": total_samples,
		"duration_seconds": float(total_samples) / float(source_info["mix_rate"]),
	}


func stop() -> void:
	if audio_player != null:
		audio_player.stop()
		audio_player.stream = null
	runtime_stream = null
	current_track_id = ""
	current_arrangement.clear()
	timeline.clear()
	current_section_index = -1
	current_playback_position = 0.0
	stream_length_seconds = 0.0
	_set_state(STATE_STOPPED)


func _update_section_for_position(position_seconds: float) -> void:
	if timeline.is_empty() or stream_length_seconds <= 0.0:
		return
	var sample_position := int(round(position_seconds * float(_mix_rate_for_timeline())))
	var next_index := -1
	for index in range(timeline.size()):
		var span: Dictionary = timeline[index]
		if sample_position >= int(span["start_sample"]) and sample_position < int(span["end_sample"]):
			next_index = index
			break
	if next_index < 0 and sample_position >= int(timeline[-1]["end_sample"]):
		next_index = timeline.size() - 1
	if next_index == current_section_index:
		return
	current_section_index = next_index
	if current_section_index >= 0:
		var active: Dictionary = timeline[current_section_index]
		arrangement_section_changed.emit(int(active["section_index"]), String(active["label"]), String(active["candidate_id"]))


func _mix_rate_for_timeline() -> int:
	return runtime_stream.mix_rate if runtime_stream != null else 48000


func _read_pcm_wav(path: String) -> Dictionary:
	var bytes: PackedByteArray = FileAccess.get_file_as_bytes(path)
	if bytes.size() < 12 or _read_ascii(bytes, 0, 4) != "RIFF" or _read_ascii(bytes, 8, 4) != "WAVE":
		return {}
	var audio_format := 0
	var channel_count := 0
	var mix_rate := 0
	var bits_per_sample := 0
	var data_start := -1
	var data_size := 0
	var cursor := 12
	while cursor + 8 <= bytes.size():
		var chunk_id: String = _read_ascii(bytes, cursor, 4)
		var chunk_size: int = _read_u32_le(bytes, cursor + 4)
		var chunk_start := cursor + 8
		var chunk_end := chunk_start + chunk_size
		if chunk_end > bytes.size():
			return {}
		if chunk_id == "fmt ":
			if chunk_size < 16:
				return {}
			audio_format = _read_u16_le(bytes, chunk_start)
			channel_count = _read_u16_le(bytes, chunk_start + 2)
			mix_rate = _read_u32_le(bytes, chunk_start + 4)
			bits_per_sample = _read_u16_le(bytes, chunk_start + 14)
		elif chunk_id == "data":
			data_start = chunk_start
			data_size = chunk_size
		cursor = chunk_end + (chunk_size % 2)
	if audio_format != 1 or not [1, 2].has(channel_count) or mix_rate <= 0 or not [8, 16].has(bits_per_sample) or data_start < 0 or data_size <= 0:
		return {}
	var bytes_per_sample := bits_per_sample / 8
	var frame_bytes := bytes_per_sample * channel_count
	if frame_bytes <= 0 or data_size % frame_bytes != 0:
		return {}
	var stream_format := AudioStreamWAV.FORMAT_8_BITS if bits_per_sample == 8 else AudioStreamWAV.FORMAT_16_BITS
	return {
		"data": bytes.slice(data_start, data_start + data_size),
		"format": stream_format,
		"channels": channel_count,
		"bytes_per_sample": bytes_per_sample,
		"mix_rate": mix_rate,
		"frame_count": data_size / frame_bytes,
	}


func _read_ascii(bytes: PackedByteArray, offset: int, length: int) -> String:
	var result := ""
	for index in range(length):
		result += String.chr(int(bytes[offset + index]))
	return result


func _read_u16_le(bytes: PackedByteArray, offset: int) -> int:
	return int(bytes[offset]) | (int(bytes[offset + 1]) << 8)


func _read_u32_le(bytes: PackedByteArray, offset: int) -> int:
	return int(bytes[offset]) | (int(bytes[offset + 1]) << 8) | (int(bytes[offset + 2]) << 16) | (int(bytes[offset + 3]) << 24)


func _ensure_player() -> void:
	if audio_player != null:
		return
	audio_player = AudioStreamPlayer.new()
	audio_player.name = "MusicArrangementPlayer"
	audio_player.bus = bus_name
	audio_player.finished.connect(_on_audio_finished)
	add_child(audio_player)


func _on_audio_finished() -> void:
	if state != STATE_PLAYING:
		return
	var finished_track_id := current_track_id
	stop()
	arrangement_finished.emit(finished_track_id)


func _set_state(next_state: StringName) -> void:
	state = next_state


func _fail(message: String) -> bool:
	last_error = message
	error_occurred.emit(message)
	return false


func _fail_result(message: String) -> Dictionary:
	_fail(message)
	return {}
