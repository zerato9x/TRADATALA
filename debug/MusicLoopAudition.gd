extends Control

var player: MusicDirector
var track_option: OptionButton
var set_option: OptionButton
var candidate_list: ItemList
var detail_label: Label
var live_label: Label
var error_label: Label
var cue_name_edit: LineEdit
var cue_notes_edit: LineEdit
var selected_track_id := ""
var selected_candidate_id := ""


func _ready() -> void:
	player = $MusicDirector
	_build_ui()
	player.error_occurred.connect(_show_error)
	_populate_tracks()


func _process(_delta: float) -> void:
	if live_label != null:
		live_label.text = "Track: %s | State: %s | Cue: %s | Pending: %s | Position: %.2f / %.2f" % [player.current_track_id if not player.current_track_id.is_empty() else "-", String(player.state), player.current_cue_id if not player.current_cue_id.is_empty() else "-", player.pending_cue_id if not player.pending_cue_id.is_empty() else "-", player.current_playback_position, player.stream_length_seconds]


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
	root.add_theme_constant_override("separation", 8)
	margin.add_child(root)
	var title := Label.new()
	title.text = "TRADATALA // MUSICDIRECTOR DJ LAB"
	title.add_theme_font_size_override("font_size", 22)
	title.add_theme_color_override("font_color", Color("f3c45d"))
	root.add_child(title)
	var note := Label.new()
	note.text = "Find cues. Test cues. Approve cues. Let gameplay release the beat."
	note.add_theme_color_override("font_color", Color("a8b0bd"))
	root.add_child(note)
	var selectors := HBoxContainer.new()
	root.add_child(selectors)
	track_option = OptionButton.new()
	track_option.custom_minimum_size = Vector2(260, 34)
	track_option.item_selected.connect(_on_track_selected)
	selectors.add_child(track_option)
	set_option = OptionButton.new()
	set_option.add_item("Distinct audition set")
	set_option.add_item("Every candidate")
	set_option.add_item("Approved cues")
	set_option.item_selected.connect(_on_set_selected)
	selectors.add_child(set_option)
	var buttons := HBoxContainer.new()
	root.add_child(buttons)
	_add_button(buttons, "Audition Loop", _on_audition)
	_add_button(buttons, "Audition + 2-Bar Lead-In", _on_audition_context)
	_add_button(buttons, "Play Source From Start", _on_play_source)
	_add_button(buttons, "Hold Approved Cue", _on_hold_approved)
	_add_button(buttons, "Release / Next Cue", _on_next_cue)
	_add_button(buttons, "Reprise Previous", _on_reprise)
	_add_button(buttons, "Release To End", _on_release)
	_add_button(buttons, "Stop", _on_stop)
	var review_row := HBoxContainer.new()
	root.add_child(review_row)
	cue_name_edit = LineEdit.new()
	cue_name_edit.placeholder_text = "Cue name (optional)"
	cue_name_edit.custom_minimum_size = Vector2(240, 34)
	review_row.add_child(cue_name_edit)
	cue_notes_edit = LineEdit.new()
	cue_notes_edit.placeholder_text = "Listening notes (optional)"
	cue_notes_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	review_row.add_child(cue_notes_edit)
	_add_button(review_row, "Approve", _on_approve)
	_add_button(review_row, "Reject", _on_reject)
	_add_button(review_row, "Clear Review", _on_clear_review)
	candidate_list = ItemList.new()
	candidate_list.size_flags_vertical = Control.SIZE_EXPAND_FILL
	candidate_list.custom_minimum_size = Vector2(0, 360)
	candidate_list.item_selected.connect(_on_candidate_selected)
	root.add_child(candidate_list)
	detail_label = Label.new()
	detail_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	detail_label.custom_minimum_size = Vector2(0, 100)
	detail_label.add_theme_color_override("font_color", Color("d7dce4"))
	root.add_child(detail_label)
	live_label = Label.new()
	live_label.add_theme_color_override("font_color", Color("f3c45d"))
	root.add_child(live_label)
	error_label = Label.new()
	error_label.add_theme_color_override("font_color", Color("ff8e8e"))
	root.add_child(error_label)


func _add_button(parent: Container, label: String, callback: Callable) -> void:
	var button := Button.new()
	button.text = label
	button.pressed.connect(callback)
	parent.add_child(button)


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
	selected_track_id = track_option.get_item_text(index)
	selected_candidate_id = ""
	_populate_candidates()


func _on_set_selected(_index: int) -> void:
	_populate_candidates()


func _populate_candidates() -> void:
	candidate_list.clear()
	var candidates := player.get_approved_cues(selected_track_id) if set_option.selected == 2 else player.get_candidates(selected_track_id, set_option.selected == 0)
	for candidate in candidates:
		var candidate_id := String(candidate.get("candidate_id", ""))
		var status := String(player.get_manual_status(selected_track_id, candidate_id))
		candidate_list.add_item("[%s] #%d | %s | %s | score %.3f | repeat %.3f | seam %.3f" % [status, int(candidate.get("machine_rank", 0)), String(candidate.get("display_name", "candidate")), String(candidate.get("machine_hint", "exploratory")), float(candidate.get("score", 0.0)), float(candidate.get("repetition_similarity", 0.0)), float(candidate.get("seam_similarity", 0.0))])
		candidate_list.set_item_metadata(candidate_list.item_count - 1, candidate_id)
	if candidate_list.item_count > 0:
		candidate_list.select(0)
		_on_candidate_selected(0)
	else:
		detail_label.text = "No candidates available."


func _on_candidate_selected(index: int) -> void:
	if index < 0 or index >= candidate_list.item_count:
		return
	selected_candidate_id = String(candidate_list.get_item_metadata(index))
	var candidate := player.get_candidate(selected_track_id, selected_candidate_id)
	var decision := player.cue_catalog.get_decision(selected_track_id, selected_candidate_id)
	cue_name_edit.text = String(decision.get("cue_name", ""))
	cue_notes_edit.text = String(decision.get("notes", ""))
	detail_label.text = "%s\n%.2f -> %.2f seconds | bars %d-%d | %d bars\nmanual status: %s | hint: %s | jump %.4f | level delta %.2f dB\nNo gameplay role is inferred; approval only means the cue survived listening QA." % [selected_candidate_id, float(candidate.get("start_seconds", 0.0)), float(candidate.get("end_seconds", 0.0)), int(candidate.get("bar_start", 0)) + 1, int(candidate.get("bar_end", 0)), int(candidate.get("bar_count", 0)), String(player.get_manual_status(selected_track_id, selected_candidate_id)), String(candidate.get("machine_hint", "exploratory")), float(candidate.get("boundary_jump", 0.0)), float(candidate.get("boundary_rms_delta_db", 0.0))]
	error_label.text = ""


func _on_audition() -> void:
	player.audition_candidate(selected_track_id, selected_candidate_id)


func _on_audition_context() -> void:
	player.audition_candidate(selected_track_id, selected_candidate_id, 2)


func _on_play_source() -> void:
	player.play_track_from_start(selected_track_id)


func _on_hold_approved() -> void:
	player.hold_cue(selected_track_id, selected_candidate_id)


func _on_next_cue() -> void:
	player.release_to_next_cue()


func _on_reprise() -> void:
	player.reprise_previous_cue()


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
	if player.set_manual_decision(selected_track_id, selected_candidate_id, status, cue_name_edit.text, cue_notes_edit.text):
		var keep_id := selected_candidate_id
		_populate_candidates()
		for item_index in range(candidate_list.item_count):
			if String(candidate_list.get_item_metadata(item_index)) == keep_id:
				candidate_list.select(item_index)
				_on_candidate_selected(item_index)
				break


func _on_stop() -> void:
	player.stop()


func _show_error(message: String) -> void:
	if error_label != null:
		error_label.text = "ERROR: " + message
