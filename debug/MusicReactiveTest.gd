extends Control

## Engineering-only audition surface for MusicDirector.
## This scene owns selection and presentation; all playback state transitions
## remain in res://audio_system/MusicDirector.gd.

var director

var track_option: OptionButton
var section_option: OptionButton
var candidate_list: ItemList
var candidate_detail_label: Label
var timeline_label: Label
var live_debug_label: Label
var status_label: Label
var error_label: Label

var _selected_track_id: String = ""
var _selected_section_index: int = 0
var _selected_candidate_rank: int = 1
var _section_candidate_ranks: Dictionary = {}
var _refresh_clock: float = 0.0


func _ready() -> void:
	director = $MusicDirector
	_build_ui()
	director.track_loaded.connect(_on_director_track_loaded)
	director.state_changed.connect(_on_director_state_changed)
	director.loop_entered.connect(_on_director_loop_entered)
	director.loop_released.connect(_on_director_loop_released)
	director.error_occurred.connect(_on_director_error)
	_populate_tracks()
	_refresh_all()


func _process(delta: float) -> void:
	_refresh_clock += delta
	if _refresh_clock < 0.1:
		return
	_refresh_clock = 0.0
	_refresh_live_debug()


func _build_ui() -> void:
	var background := ColorRect.new()
	background.color = Color("11151b")
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(background)

	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 18)
	margin.add_theme_constant_override("margin_top", 16)
	margin.add_theme_constant_override("margin_right", 18)
	margin.add_theme_constant_override("margin_bottom", 16)
	add_child(margin)

	var root_column := VBoxContainer.new()
	root_column.add_theme_constant_override("separation", 8)
	margin.add_child(root_column)

	var title := Label.new()
	title.text = "TRADATALA // REACTIVE OST LOOP TESTER"
	title.add_theme_color_override("font_color", Color("f3c45d"))
	title.add_theme_font_size_override("font_size", 22)
	root_column.add_child(title)

	var subtitle := Label.new()
	subtitle.text = "JSON-driven source timeline test. No WAV files are edited or duplicated."
	subtitle.add_theme_color_override("font_color", Color("a8b0bd"))
	root_column.add_child(subtitle)

	var selectors := HBoxContainer.new()
	selectors.add_theme_constant_override("separation", 10)
	root_column.add_child(selectors)
	_add_labelled_control(selectors, "TRACK", _make_track_option())
	_add_labelled_control(selectors, "SECTION", _make_section_option())

	var transport := HBoxContainer.new()
	transport.add_theme_constant_override("separation", 6)
	root_column.add_child(transport)
	_add_button(transport, "Play From Start", _on_play_from_start)
	_add_button(transport, "Stop", _on_stop)
	_add_button(transport, "Previous Section", _on_previous_section)
	_add_button(transport, "Next Section", _on_next_section)
	_add_button(transport, "Request Selected Section", _on_request_selected_section)
	_add_button(transport, "Release Loop", _on_release_loop)
	_add_button(transport, "Finish Track", _on_finish_track)

	var body := HSplitContainer.new()
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_theme_constant_override("separation", 12)
	root_column.add_child(body)

	var candidate_column := VBoxContainer.new()
	candidate_column.custom_minimum_size = Vector2(570, 0)
	candidate_column.add_theme_constant_override("separation", 6)
	body.add_child(candidate_column)
	var candidate_heading := Label.new()
	candidate_heading.text = "AUTOMATICALLY SAFE LOOP CANDIDATES (listening QA still required)"
	candidate_heading.add_theme_color_override("font_color", Color("f3c45d"))
	candidate_column.add_child(candidate_heading)
	candidate_list = ItemList.new()
	candidate_list.custom_minimum_size = Vector2(0, 210)
	candidate_list.size_flags_vertical = Control.SIZE_EXPAND_FILL
	candidate_list.select_mode = ItemList.SELECT_SINGLE
	candidate_list.item_selected.connect(_on_candidate_selected)
	candidate_column.add_child(candidate_list)
	candidate_detail_label = Label.new()
	candidate_detail_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	candidate_detail_label.custom_minimum_size = Vector2(0, 126)
	candidate_detail_label.add_theme_color_override("font_color", Color("d7dce4"))
	candidate_column.add_child(candidate_detail_label)

	var info_column := VBoxContainer.new()
	info_column.add_theme_constant_override("separation", 6)
	body.add_child(info_column)
	var live_heading := Label.new()
	live_heading.text = "LIVE STATE"
	live_heading.add_theme_color_override("font_color", Color("f3c45d"))
	info_column.add_child(live_heading)
	live_debug_label = Label.new()
	live_debug_label.custom_minimum_size = Vector2(0, 150)
	live_debug_label.add_theme_color_override("font_color", Color("d7dce4"))
	info_column.add_child(live_debug_label)
	var timeline_heading := Label.new()
	timeline_heading.text = "SECTION TIMELINE"
	timeline_heading.add_theme_color_override("font_color", Color("f3c45d"))
	info_column.add_child(timeline_heading)
	timeline_label = Label.new()
	timeline_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	timeline_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	timeline_label.add_theme_color_override("font_color", Color("c4ccd7"))
	info_column.add_child(timeline_label)

	status_label = Label.new()
	status_label.add_theme_color_override("font_color", Color("a8b0bd"))
	root_column.add_child(status_label)
	error_label = Label.new()
	error_label.add_theme_color_override("font_color", Color("ff8e8e"))
	error_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	root_column.add_child(error_label)


func _make_track_option() -> OptionButton:
	track_option = OptionButton.new()
	track_option.custom_minimum_size = Vector2(260, 34)
	track_option.item_selected.connect(_on_track_selected)
	return track_option


func _make_section_option() -> OptionButton:
	section_option = OptionButton.new()
	section_option.custom_minimum_size = Vector2(350, 34)
	section_option.item_selected.connect(_on_section_selected)
	return section_option


func _add_labelled_control(parent: Container, label_text: String, control: Control) -> void:
	var group := VBoxContainer.new()
	group.add_theme_constant_override("separation", 2)
	parent.add_child(group)
	var label := Label.new()
	label.text = label_text
	label.add_theme_font_size_override("font_size", 10)
	label.add_theme_color_override("font_color", Color("f3c45d"))
	group.add_child(label)
	group.add_child(control)


func _add_button(parent: Container, text: String, callback: Callable) -> void:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(0, 34)
	button.pressed.connect(callback)
	parent.add_child(button)


func _populate_tracks() -> void:
	track_option.clear()
	var track_ids: Array[String] = director.get_track_ids()
	for track_id in track_ids:
		track_option.add_item(track_id)
	if track_ids.is_empty():
		_selected_track_id = ""
		_set_error_text("No tracks are available in ost_structure.json")
		return
	var default_index: int = track_ids.find("tiger_2")
	if default_index < 0:
		default_index = 0
	track_option.select(default_index)
	_on_track_selected(default_index)


func _on_track_selected(index: int) -> void:
	if index < 0 or index >= track_option.item_count:
		return
	_selected_track_id = track_option.get_item_text(index)
	director.stop()
	_selected_section_index = 0
	_selected_candidate_rank = 1
	_section_candidate_ranks.clear()
	_populate_sections()
	_clear_error_text()
	_refresh_all()


func _populate_sections() -> void:
	section_option.clear()
	var section_count: int = director.get_section_count(_selected_track_id)
	for section_index in range(section_count):
		var section: Dictionary = director.get_section(_selected_track_id, section_index)
		var section_id := String(section.get("section_id", "section_%d" % (section_index + 1)))
		var display_name := String(section.get("display_name", section_id))
		var stable_start := float(section.get("stable_start_seconds", 0.0))
		var stable_end := float(section.get("stable_end_seconds", 0.0))
		section_option.add_item("%d | %s | %.2f -> %.2f" % [section_index + 1, display_name, stable_start, stable_end])
	if section_count == 0:
		_selected_section_index = -1
		candidate_list.clear()
		candidate_detail_label.text = "Selected track has no structural sections."
		return
	_selected_section_index = clampi(_selected_section_index, 0, section_count - 1)
	if director.get_candidate_count(_selected_track_id, _selected_section_index) == 0:
		for candidate_section_index in range(section_count):
			if director.get_candidate_count(_selected_track_id, candidate_section_index) > 0:
				_selected_section_index = candidate_section_index
				break
	section_option.select(_selected_section_index)
	_populate_candidates()


func _on_section_selected(index: int) -> void:
	_selected_section_index = index
	_selected_candidate_rank = int(_section_candidate_ranks.get(index, 1))
	_populate_candidates()
	_refresh_all()


func _populate_candidates() -> void:
	candidate_list.clear()
	if _selected_section_index < 0:
		candidate_detail_label.text = "No section selected."
		return
	var candidate_count: int = director.get_candidate_count(_selected_track_id, _selected_section_index)
	if candidate_count <= 0:
		var section: Dictionary = director.get_section(_selected_track_id, _selected_section_index)
		candidate_detail_label.text = "No candidate passed the automatic loop gates. Rejected candidates: %d. This state is not runtime-ready." % int(section.get("rejected_candidate_count", 0))
		return
	_selected_candidate_rank = clampi(_selected_candidate_rank, 1, candidate_count)
	_section_candidate_ranks[_selected_section_index] = _selected_candidate_rank
	for rank in range(1, candidate_count + 1):
		var candidate: Dictionary = director.get_candidate(_selected_track_id, _selected_section_index, rank)
		var godot_loop: Dictionary = candidate.get("godot", {}) if candidate.get("godot", {}) is Dictionary else {}
		candidate_list.add_item(
			"Rank %d | %.2f -> %.2f | %d bars | score %.3f | repeat %.3f | seam %.3f | jump %.3f | level %.2fdB"
			% [
				rank,
				float(godot_loop.get("loop_begin_seconds", candidate.get("start_seconds", 0.0))),
				float(godot_loop.get("loop_end_seconds", candidate.get("end_seconds", 0.0))),
				int(candidate.get("bar_count", 0)),
				float(candidate.get("score", 0.0)),
				float(candidate.get("repetition_similarity", 0.0)),
				float(candidate.get("seam_similarity", 0.0)),
				float(candidate.get("boundary_jump", 0.0)),
				float(candidate.get("boundary_rms_delta_db", 0.0)),
			]
		)
		candidate_list.set_item_metadata(candidate_list.item_count - 1, rank)
	if candidate_list.item_count > 0:
		candidate_list.select(_selected_candidate_rank - 1)
		_refresh_candidate_detail()


func _on_candidate_selected(item_index: int) -> void:
	if item_index < 0 or item_index >= candidate_list.item_count:
		return
	_selected_candidate_rank = int(candidate_list.get_item_metadata(item_index))
	_section_candidate_ranks[_selected_section_index] = _selected_candidate_rank
	if director.current_track_id == _selected_track_id:
		director.set_candidate_rank(_selected_section_index, _selected_candidate_rank)
	_refresh_candidate_detail()
	_refresh_timeline()
	_refresh_live_debug()


func _on_play_from_start() -> void:
	if _selected_track_id.is_empty():
		return
	if not director.play_track(_selected_track_id):
		return
	_request_selected_section()


func _on_stop() -> void:
	director.stop()
	_refresh_all()


func _on_previous_section() -> void:
	if director.get_section_count(_selected_track_id) <= 0:
		return
	_selected_section_index = maxi(0, _selected_section_index - 1)
	section_option.select(_selected_section_index)
	_selected_candidate_rank = int(_section_candidate_ranks.get(_selected_section_index, 1))
	_populate_candidates()
	_refresh_all()


func _on_next_section() -> void:
	var section_count: int = director.get_section_count(_selected_track_id)
	if section_count <= 0:
		return
	_selected_section_index = mini(section_count - 1, _selected_section_index + 1)
	section_option.select(_selected_section_index)
	_selected_candidate_rank = int(_section_candidate_ranks.get(_selected_section_index, 1))
	_populate_candidates()
	_refresh_all()


func _on_request_selected_section() -> void:
	_request_selected_section()


func _request_selected_section() -> void:
	if _selected_section_index < 0:
		_set_error_text("No structural section is selected.")
		return
	if director.get_candidate_count(_selected_track_id, _selected_section_index) <= 0:
		_set_error_text("Selected loop state has no automatically safe candidate and cannot be requested.")
		return
	if director.current_track_id != _selected_track_id or director.audio_player == null or not director.audio_player.playing:
		if not director.play_track(_selected_track_id):
			return
	if not director.set_candidate_rank(_selected_section_index, _selected_candidate_rank):
		return
	director.request_phase(_selected_section_index)
	_refresh_all()


func _on_release_loop() -> void:
	director.release_loop()
	_refresh_all()


func _on_finish_track() -> void:
	director.finish_track()
	_refresh_all()


func _on_director_track_loaded(_track_id: String) -> void:
	_clear_error_text()
	_refresh_all()


func _on_director_state_changed(_next_state: StringName) -> void:
	_refresh_all()


func _on_director_loop_entered(_section_index: int, _rank: int, _loop_start: float, _loop_end: float) -> void:
	_clear_error_text()
	_refresh_all()


func _on_director_loop_released(_section_index: int) -> void:
	_refresh_all()


func _on_director_error(message: String) -> void:
	_set_error_text(message)
	_refresh_all()


func _refresh_all() -> void:
	_refresh_candidate_detail()
	_refresh_timeline()
	_refresh_live_debug()
	if status_label == null:
		return
	status_label.text = "Catalog: %s | Selected track: %s | Selected section: %s" % [
		"loaded" if director.catalog_is_loaded else "not loaded",
		_selected_track_id if not _selected_track_id.is_empty() else "-",
		str(_selected_section_index + 1) if _selected_section_index >= 0 else "-",
	]


func _refresh_candidate_detail() -> void:
	if candidate_detail_label == null:
		return
	if _selected_section_index < 0:
		candidate_detail_label.text = "No section selected."
		return
	var section: Dictionary = director.get_section(_selected_track_id, _selected_section_index)
	if section.is_empty():
		candidate_detail_label.text = "Section data unavailable."
		return
	var candidate: Dictionary = director.get_candidate(_selected_track_id, _selected_section_index, _selected_candidate_rank)
	var detail := "SECTION %d: %s\nstable: %.2f -> %.2f\n" % [
		_selected_section_index + 1,
		String(section.get("display_name", section.get("section_id", "<unnamed>"))),
		float(section.get("stable_start_seconds", 0.0)),
		float(section.get("stable_end_seconds", 0.0)),
	]
	if candidate.is_empty():
		candidate_detail_label.text = detail + "selected loop: none (state is not runtime-ready)"
		return
	var godot_loop: Dictionary = candidate.get("godot", {}) if candidate.get("godot", {}) is Dictionary else {}
	detail += "selected loop: %.2f -> %.2f\n" % [
		float(godot_loop.get("loop_begin_seconds", candidate.get("start_seconds", 0.0))),
		float(godot_loop.get("loop_end_seconds", candidate.get("end_seconds", 0.0))),
	]
	detail += "bars: %d | score: %.3f | seam_similarity: %.3f\n" % [
		int(candidate.get("bar_count", 0)),
		float(candidate.get("score", 0.0)),
		float(candidate.get("seam_similarity", 0.0)),
	]
	detail += "internal_stability: %.3f | repetition_similarity: %.3f\n" % [
		float(candidate.get("internal_stability", 0.0)),
		float(candidate.get("repetition_similarity", 0.0)),
	]
	detail += "boundary_jump: %.3f | boundary_level_delta: %.2fdB\nmanual listening required: yes" % [
		float(candidate.get("boundary_jump", 0.0)),
		float(candidate.get("boundary_rms_delta_db", 0.0)),
	]
	candidate_detail_label.text = detail


func _refresh_timeline() -> void:
	if timeline_label == null:
		return
	var sections: Array = director.get_track(_selected_track_id).get("sections", [])
	if sections.is_empty():
		timeline_label.text = "No structural sections."
		return
	var lines: Array[String] = []
	for section_index in range(sections.size()):
		var section: Dictionary = sections[section_index]
		var rank := int(_section_candidate_ranks.get(section_index, 1))
		var candidate: Dictionary = director.get_candidate(_selected_track_id, section_index, rank)
		var line := "SECTION %d: %s\nstable: %.2f -> %.2f\n" % [
			section_index + 1,
			String(section.get("display_name", section.get("section_id", "<unnamed>"))),
			float(section.get("stable_start_seconds", 0.0)),
			float(section.get("stable_end_seconds", 0.0)),
		]
		if candidate.is_empty():
			line += "selected loop: none | rejected: %d | NOT READY" % int(section.get("rejected_candidate_count", 0))
		else:
			var godot_loop: Dictionary = candidate.get("godot", {}) if candidate.get("godot", {}) is Dictionary else {}
			line += "selected loop (rank %d): %.2f -> %.2f" % [
				rank,
				float(godot_loop.get("loop_begin_seconds", candidate.get("start_seconds", 0.0))),
				float(godot_loop.get("loop_end_seconds", candidate.get("end_seconds", 0.0))),
			]
		lines.append(line)
	timeline_label.text = "\n\n".join(lines)


func _refresh_live_debug() -> void:
	if live_debug_label == null:
		return
	var current_section_text := str(director.current_section_index + 1) if director.current_section_index >= 0 else "-"
	var pending_section_text := str(director.pending_section_index + 1) if director.pending_section_index >= 0 else "-"
	var current_rank_text := str(director.current_candidate_rank) if director.current_candidate_rank >= 0 else "-"
	var loop_text := "-"
	if director.current_loop_start >= 0.0 and director.current_loop_end > director.current_loop_start:
		loop_text = "%.2f -> %.2f" % [director.current_loop_start, director.current_loop_end]
	live_debug_label.text = "Track: %s\nPlayback: %.2f / %.2f\nState: %s\nCurrent section: %s\nCurrent loop rank: %s\nCurrent loop: %s\nPending section: %s\nPending rank: %s\nBPM: %.2f\nApprox. bar: %s" % [
		director.current_track_id if not director.current_track_id.is_empty() else "-",
		director.current_playback_position,
		director.stream_length_seconds,
		String(director.state),
		current_section_text,
		current_rank_text,
		loop_text,
		pending_section_text,
		str(director.pending_candidate_rank) if director.pending_candidate_rank >= 0 else "-",
		float(director.get_track(director.current_track_id).get("tempo_bpm", 0.0)),
		str(director.approximate_bar_index()) if director.approximate_bar_index() > 0 else "-",
	]


func _set_error_text(message: String) -> void:
	if error_label != null:
		error_label.text = "ERROR: " + message


func _clear_error_text() -> void:
	if error_label != null:
		error_label.text = ""
