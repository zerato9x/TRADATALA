extends Control

var player: MusicDirector
var track_option: OptionButton
var set_option: OptionButton
var sort_option: OptionButton
var candidate_list: ItemList
var detail_label: Label
var sequence_label: Label
var live_label: Label
var event_log: RichTextLabel
var error_label: Label
var cue_name_edit: LineEdit
var cue_notes_edit: LineEdit
var audition_button: Button
var lead_in_button: Button
var hold_button: Button
var jump_button: Button
var next_button: Button
var reprise_button: Button
var release_button: Button
var approve_button: Button
var reject_button: Button
var clear_review_button: Button
var selected_track_id := ""
var selected_candidate_id := ""


func _ready() -> void:
	player = $MusicDirector
	_build_ui()
	_connect_director_signals()
	_populate_tracks()


func _process(_delta: float) -> void:
	_refresh_live_state()


func _build_ui() -> void:
	var background := ColorRect.new()
	background.color = Color("11151b")
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(background)

	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side in ["left", "top", "right", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 16)
	add_child(margin)

	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 7)
	margin.add_child(root)

	var title := Label.new()
	title.text = "TRADATALA // MUSICDIRECTOR DJ LAB"
	title.add_theme_font_size_override("font_size", 22)
	title.add_theme_color_override("font_color", Color("f3c45d"))
	root.add_child(title)

	var note := Label.new()
	note.text = "FIND CUES → TEST CUES → APPROVE CUES → HOLD / RELEASE / REPRISE"
	note.add_theme_color_override("font_color", Color("a8b0bd"))
	root.add_child(note)

	var selectors := HBoxContainer.new()
	selectors.add_theme_constant_override("separation", 8)
	root.add_child(selectors)
	track_option = OptionButton.new()
	track_option.custom_minimum_size = Vector2(220, 34)
	track_option.item_selected.connect(_on_track_selected)
	selectors.add_child(track_option)
	set_option = OptionButton.new()
	set_option.custom_minimum_size = Vector2(190, 34)
	set_option.add_item("Audition shortlist")
	set_option.add_item("Every candidate")
	set_option.add_item("Approved cue sequence")
	set_option.item_selected.connect(_on_set_selected)
	selectors.add_child(set_option)
	sort_option = OptionButton.new()
	sort_option.custom_minimum_size = Vector2(210, 34)
	sort_option.add_item("Bars: first → last")
	sort_option.add_item("Bars: last → first")
	sort_option.add_item("Score: high → low")
	sort_option.add_item("Score: low → high")
	sort_option.item_selected.connect(_on_sort_selected)
	selectors.add_child(sort_option)
	sequence_label = Label.new()
	sequence_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sequence_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	sequence_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	sequence_label.add_theme_color_override("font_color", Color("c4ccd7"))
	selectors.add_child(sequence_label)

	var preview_row := HBoxContainer.new()
	preview_row.add_theme_constant_override("separation", 6)
	root.add_child(preview_row)
	audition_button = _add_button(preview_row, "Audition Loop", _on_audition)
	lead_in_button = _add_button(preview_row, "Audition + 2-Bar Lead-In", _on_audition_context)
	_add_button(preview_row, "Play Original From Start", _on_play_source)
	_add_button(preview_row, "Stop", _on_stop)

	var dj_row := HBoxContainer.new()
	dj_row.add_theme_constant_override("separation", 6)
	root.add_child(dj_row)
	var dj_label := Label.new()
	dj_label.text = "DJ DECK"
	dj_label.custom_minimum_size.x = 76
	dj_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	dj_label.add_theme_color_override("font_color", Color("f3c45d"))
	dj_row.add_child(dj_label)
	hold_button = _add_button(dj_row, "Hold Approved Cue", _on_hold_approved)
	next_button = _add_button(dj_row, "Release → Catch Next", _on_next_cue)
	reprise_button = _add_button(dj_row, "Finish Loop → Reprise", _on_reprise)
	jump_button = _add_button(dj_row, "Hard Jump to Selected", _on_jump_approved)
	release_button = _add_button(dj_row, "Release to Original Ending", _on_release)

	var review_row := HBoxContainer.new()
	review_row.add_theme_constant_override("separation", 6)
	root.add_child(review_row)
	var review_label := Label.new()
	review_label.text = "REVIEW"
	review_label.custom_minimum_size.x = 62
	review_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	review_label.add_theme_color_override("font_color", Color("f3c45d"))
	review_row.add_child(review_label)
	approve_button = _add_button(review_row, "Approve", _on_approve)
	reject_button = _add_button(review_row, "Reject", _on_reject)
	clear_review_button = _add_button(review_row, "Clear", _on_clear_review)
	cue_name_edit = LineEdit.new()
	cue_name_edit.placeholder_text = "Cue name (e.g. Hook, Pressure, Reprise)"
	cue_name_edit.custom_minimum_size = Vector2(240, 34)
	review_row.add_child(cue_name_edit)
	cue_notes_edit = LineEdit.new()
	cue_notes_edit.placeholder_text = "Listening notes: seam, vocal pickup, safe release..."
	cue_notes_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	review_row.add_child(cue_notes_edit)

	var body := HSplitContainer.new()
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_theme_constant_override("separation", 10)
	root.add_child(body)

	candidate_list = ItemList.new()
	candidate_list.custom_minimum_size = Vector2(620, 300)
	candidate_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	candidate_list.size_flags_vertical = Control.SIZE_EXPAND_FILL
	candidate_list.select_mode = ItemList.SELECT_SINGLE
	candidate_list.item_selected.connect(_on_candidate_selected)
	candidate_list.item_activated.connect(_on_candidate_activated)
	body.add_child(candidate_list)

	var right_column := VBoxContainer.new()
	right_column.custom_minimum_size = Vector2(360, 0)
	right_column.add_theme_constant_override("separation", 6)
	body.add_child(right_column)
	var detail_heading := Label.new()
	detail_heading.text = "SELECTED CANDIDATE"
	detail_heading.add_theme_color_override("font_color", Color("f3c45d"))
	right_column.add_child(detail_heading)
	detail_label = Label.new()
	detail_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	detail_label.custom_minimum_size = Vector2(420, 132)
	detail_label.add_theme_color_override("font_color", Color("d7dce4"))
	right_column.add_child(detail_label)
	var event_heading := Label.new()
	event_heading.text = "TRANSPORT EVENTS"
	event_heading.add_theme_color_override("font_color", Color("f3c45d"))
	right_column.add_child(event_heading)
	event_log = RichTextLabel.new()
	event_log.bbcode_enabled = true
	event_log.fit_content = false
	event_log.scroll_active = true
	event_log.size_flags_vertical = Control.SIZE_EXPAND_FILL
	event_log.custom_minimum_size = Vector2(420, 120)
	right_column.add_child(event_log)

	live_label = Label.new()
	live_label.add_theme_color_override("font_color", Color("f3c45d"))
	root.add_child(live_label)
	error_label = Label.new()
	error_label.add_theme_color_override("font_color", Color("ff8e8e"))
	error_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	root.add_child(error_label)


func _connect_director_signals() -> void:
	player.candidate_audition_started.connect(func(track_id: String, cue_id: String, lead_in: int) -> void:
		_append_event("AUDITION %s / %s (%d-bar lead-in)" % [track_id, _cue_label(track_id, cue_id), lead_in]))
	player.cue_held.connect(func(track_id: String, cue_id: String) -> void:
		_append_event("HOLD %s / %s" % [track_id, _cue_label(track_id, cue_id)]))
	player.authored_transition_started.connect(func(from_id: String, to_id: String) -> void:
		_append_event("RELEASE authored audio: %s → %s" % [_cue_label(player.current_track_id, from_id), _cue_label(player.current_track_id, to_id)]))
	player.reprise_started.connect(func(from_id: String, to_id: String) -> void:
		_append_event("REPRISE after loop boundary: %s → %s" % [_cue_label(player.current_track_id, from_id), _cue_label(player.current_track_id, to_id)]))
	player.source_released.connect(func(track_id: String) -> void:
		_append_event("RELEASE %s to original ending" % track_id))
	player.source_finished.connect(func(track_id: String) -> void:
		_append_event("FINISHED %s" % track_id))
	player.state_changed.connect(func(_next_state: StringName) -> void:
		_refresh_controls())
	player.error_occurred.connect(_show_error)


func _add_button(parent: Container, label: String, callback: Callable) -> Button:
	var button := Button.new()
	button.text = label
	button.custom_minimum_size.y = 34
	button.pressed.connect(callback)
	parent.add_child(button)
	return button


func _populate_tracks() -> void:
	track_option.clear()
	var ids := player.get_track_ids()
	for track_id in ids:
		track_option.add_item(track_id)
	if ids.is_empty():
		_show_error("No tracks in loop catalog")
		return
	var default_index := ids.find("dog_1")
	track_option.select(default_index if default_index >= 0 else 0)
	_on_track_selected(track_option.selected)


func _on_track_selected(index: int) -> void:
	if index < 0 or index >= track_option.item_count:
		return
	player.stop()
	selected_track_id = track_option.get_item_text(index)
	selected_candidate_id = ""
	_populate_candidates()
	_append_event("TRACK selected: %s" % selected_track_id)


func _on_set_selected(_index: int) -> void:
	_populate_candidates(selected_candidate_id)


func _on_sort_selected(_index: int) -> void:
	_populate_candidates(selected_candidate_id)


func _populate_candidates(preferred_id := "") -> void:
	candidate_list.clear()
	var candidates := player.get_approved_cues(selected_track_id) if set_option.selected == 2 else player.get_candidates(selected_track_id, set_option.selected == 0)
	candidates = _sort_candidates(candidates)
	var preferred_index := -1
	for candidate in candidates:
		var candidate_id := String(candidate.get("candidate_id", ""))
		var status := String(player.get_manual_status(selected_track_id, candidate_id))
		var cue_name := String(player.cue_catalog.get_decision(selected_track_id, candidate_id).get("cue_name", "")).strip_edges()
		var display_name := cue_name if not cue_name.is_empty() else String(candidate.get("display_name", "candidate"))
		candidate_list.add_item("[%s] %s | bars %d-%d | %.2f → %.2f | score %.3f | seam %.3f" % [status, display_name, int(candidate.get("bar_start", 0)) + 1, int(candidate.get("bar_end", 0)), float(candidate.get("start_seconds", 0.0)), float(candidate.get("end_seconds", 0.0)), float(candidate.get("score", 0.0)), float(candidate.get("seam_similarity", 0.0))])
		candidate_list.set_item_metadata(candidate_list.item_count - 1, candidate_id)
		if candidate_id == preferred_id:
			preferred_index = candidate_list.item_count - 1
	if candidate_list.item_count > 0:
		var selected_index := preferred_index if preferred_index >= 0 else 0
		candidate_list.select(selected_index)
		_on_candidate_selected(selected_index)
	else:
		selected_candidate_id = ""
		detail_label.text = "No candidates in this view. Approve listening-tested candidates to build the DJ sequence."
		cue_name_edit.text = ""
		cue_notes_edit.text = ""
	_refresh_sequence()
	_refresh_controls()


func _sort_candidates(candidates: Array[Dictionary]) -> Array[Dictionary]:
	var sorted := candidates.duplicate()
	var sort_mode := sort_option.selected if sort_option != null else 0
	sorted.sort_custom(func(left: Dictionary, right: Dictionary) -> bool:
		if sort_mode >= 2:
			var left_score := float(left.get("score", 0.0))
			var right_score := float(right.get("score", 0.0))
			if not is_equal_approx(left_score, right_score):
				return left_score > right_score if sort_mode == 2 else left_score < right_score
			var score_left_start := int(left.get("bar_start", 0))
			var score_right_start := int(right.get("bar_start", 0))
			if score_left_start != score_right_start:
				return score_left_start < score_right_start
			return String(left.get("candidate_id", "")) < String(right.get("candidate_id", ""))
		var descending := sort_mode == 1
		var left_start := int(left.get("bar_start", 0))
		var right_start := int(right.get("bar_start", 0))
		if left_start != right_start:
			return left_start > right_start if descending else left_start < right_start
		var left_end := int(left.get("bar_end", 0))
		var right_end := int(right.get("bar_end", 0))
		if left_end != right_end:
			return left_end > right_end if descending else left_end < right_end
		var left_id := String(left.get("candidate_id", ""))
		var right_id := String(right.get("candidate_id", ""))
		return left_id > right_id if descending else left_id < right_id
	)
	return sorted


func _on_candidate_selected(index: int) -> void:
	if index < 0 or index >= candidate_list.item_count:
		return
	selected_candidate_id = String(candidate_list.get_item_metadata(index))
	var candidate := player.get_candidate(selected_track_id, selected_candidate_id)
	var decision := player.cue_catalog.get_decision(selected_track_id, selected_candidate_id)
	cue_name_edit.text = String(decision.get("cue_name", ""))
	cue_notes_edit.text = String(decision.get("notes", ""))
	detail_label.text = "%s\n%.2f → %.2f seconds | bars %d-%d | %d bars\nstatus: %s | machine hint: %s\nrepeat %.3f | seam %.3f | jump %.4f | level delta %.2f dB\nApproval is a listening decision; machine rank is only triage." % [selected_candidate_id, float(candidate.get("start_seconds", 0.0)), float(candidate.get("end_seconds", 0.0)), int(candidate.get("bar_start", 0)) + 1, int(candidate.get("bar_end", 0)), int(candidate.get("bar_count", 0)), String(player.get_manual_status(selected_track_id, selected_candidate_id)), String(candidate.get("machine_hint", "exploratory")), float(candidate.get("repetition_similarity", 0.0)), float(candidate.get("seam_similarity", 0.0)), float(candidate.get("boundary_jump", 0.0)), float(candidate.get("boundary_rms_delta_db", 0.0))]
	error_label.text = ""
	_refresh_controls()


func _on_candidate_activated(index: int) -> void:
	_on_candidate_selected(index)
	_on_audition()


func _on_audition() -> void:
	if not selected_candidate_id.is_empty():
		player.audition_candidate(selected_track_id, selected_candidate_id)


func _on_audition_context() -> void:
	if not selected_candidate_id.is_empty():
		player.audition_candidate(selected_track_id, selected_candidate_id, 2)


func _on_play_source() -> void:
	player.play_track_from_start(selected_track_id)


func _on_hold_approved() -> void:
	player.hold_cue(selected_track_id, selected_candidate_id)


func _on_next_cue() -> void:
	player.release_to_next_cue()


func _on_reprise() -> void:
	player.reprise_previous_cue()


func _on_jump_approved() -> void:
	if player.current_track_id != selected_track_id:
		player.hold_cue(selected_track_id, selected_candidate_id)
	else:
		player.jump_to_cue(selected_candidate_id)


func _on_release() -> void:
	player.release_to_end()


func _on_approve() -> void:
	_set_review(&"approved")


func _on_reject() -> void:
	_set_review(&"rejected")


func _on_clear_review() -> void:
	_set_review(&"unreviewed")


func _set_review(status: StringName) -> void:
	if selected_candidate_id.is_empty():
		return
	var keep_id := selected_candidate_id
	if player.set_manual_decision(selected_track_id, keep_id, status, cue_name_edit.text, cue_notes_edit.text):
		_append_event("REVIEW %s: %s" % [String(status).to_upper(), _cue_label(selected_track_id, keep_id)])
		_populate_candidates(keep_id)


func _on_stop() -> void:
	player.stop()
	_append_event("STOP")


func _refresh_sequence() -> void:
	var counts := player.cue_catalog.get_review_counts(selected_track_id)
	var names: Array[String] = []
	for cue in player.get_approved_cues(selected_track_id):
		var cue_id := String(cue.get("candidate_id", ""))
		names.append(_cue_label(selected_track_id, cue_id))
	var sequence := " → ".join(names) if not names.is_empty() else "none"
	sequence_label.text = "Approved %d  •  Rejected %d  •  Unreviewed %d" % [int(counts.get("approved", 0)), int(counts.get("rejected", 0)), int(counts.get("unreviewed", 0))]
	sequence_label.tooltip_text = "Approved sequence: %s" % sequence


func _refresh_live_state() -> void:
	if live_label == null:
		return
	live_label.text = "STATE %s | Track %s | Holding %s | Pending %s | %.2f / %.2f s" % [String(player.state), player.current_track_id if not player.current_track_id.is_empty() else "-", _cue_label(player.current_track_id, player.current_cue_id), _cue_label(player.current_track_id, player.pending_cue_id), player.current_playback_position, player.stream_length_seconds]


func _refresh_controls() -> void:
	if audition_button == null:
		return
	var has_candidate := not selected_candidate_id.is_empty()
	var is_approved := has_candidate and player.get_manual_status(selected_track_id, selected_candidate_id) == &"approved"
	var track_active := player.runtime_stream != null and player.current_track_id == selected_track_id
	var move_in_progress := player.state in [MusicDirector.STATE_AUDITIONING_CUE, MusicDirector.STATE_TRAVELING_FORWARD, MusicDirector.STATE_REWIND_PENDING]
	audition_button.disabled = not has_candidate
	lead_in_button.disabled = not has_candidate
	hold_button.disabled = not is_approved
	jump_button.disabled = not is_approved
	next_button.disabled = not track_active or move_in_progress
	reprise_button.disabled = not track_active or player.current_cue_id.is_empty() or move_in_progress
	release_button.disabled = not track_active
	approve_button.disabled = not has_candidate
	reject_button.disabled = not has_candidate
	clear_review_button.disabled = not has_candidate


func _cue_label(track_id: String, cue_id: String) -> String:
	if cue_id.is_empty():
		return "-"
	var decision := player.cue_catalog.get_decision(track_id, cue_id)
	var cue_name := String(decision.get("cue_name", "")).strip_edges()
	return cue_name if not cue_name.is_empty() else cue_id


func _append_event(message: String) -> void:
	if event_log == null:
		return
	event_log.append_text("• %s\n" % message)
	event_log.scroll_to_line(maxi(0, event_log.get_line_count() - 1))


func _show_error(message: String) -> void:
	if error_label != null:
		error_label.text = "ERROR: " + message
	_append_event("[color=#ff8e8e]ERROR[/color] %s" % message)
