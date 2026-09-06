class_name GieoQuePanel
extends VBoxContainer

signal wallet_changed()
signal feedback_requested(message: String)
signal impact_requested(kind: StringName)
signal commitment_changed(committed: bool)

enum PresentationState {
	IDLE,
	PULLING_LEVER,
	SPINNING,
	REVEALING_UPPER,
	REVEALING_LOWER,
	SHOWING_RESULT,
	CHOOSING_RESULT_INPUT,
	RESOLVING_TRANSFORMATION,
	COMPLETE,
}

const SLOT_TEXTURE := preload("res://assets/ui/gieo_que/slot_machine.png")
const LEVER_TEXTURE := preload("res://assets/ui/gieo_que/lever.png")
const CARD_THUMB_SIZE := Vector2(54, 75)
const STAGE_SIZE := Vector2(840, 600)
const LEVER_COLUMNS := 4
const LEVER_ROWS := 2
const LEVER_FRAME_SIZE := Vector2(543, 362)
const REEL_Y := [104.0, 153.0, 201.0, 258.0, 304.0, 352.0]

var service: GieoQueService
var presentation_state: PresentationState = PresentationState.IDLE

var _busy := false
var _stage: Control
var _lever_button: Button
var _lever_image: TextureRect
var _reels: Array[Dictionary] = []
var _upper_panel: PanelContainer
var _lower_panel: PanelContainer
var _upper_label: Label
var _lower_label: Label
var _upper_detail: Label
var _lower_detail: Label
var _active_oracle_panel: PanelContainer
var _result_parts: Array[Control] = []
var _decision_row: Control


func configure(p_service: GieoQueService) -> void:
	service = p_service
	name = "GieoQuePanel"
	custom_minimum_size = STAGE_SIZE
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	size_flags_vertical = Control.SIZE_EXPAND_FILL
	add_theme_constant_override("separation", 0)
	_rebuild()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept") and presentation_state == PresentationState.IDLE and not _busy:
		get_viewport().set_input_as_handled()
		_on_cast_pressed(false)


func is_interaction_locked() -> bool:
	return _busy or presentation_state not in [PresentationState.IDLE, PresentationState.COMPLETE]


func displayed_reel_values() -> Array[String]:
	var values: Array[String] = []
	for reel in _reels:
		values.append(String(reel.get("value", "")))
	return values


func _rebuild() -> void:
	_clear()
	if service == null:
		return
	match service.state:
		GieoQueService.STATE_READY:
			_set_presentation_state(PresentationState.IDLE)
			_build_machine(service.current_result.get("lines", []) as Array, true)
		GieoQueService.STATE_RESULT:
			_set_presentation_state(PresentationState.SHOWING_RESULT)
			_build_machine(service.current_result.get("lines", []) as Array, false)
			_add_result_panel(false)
			_add_decisions(false)
		GieoQueService.STATE_DESTINATION_SELECTION:
			_set_presentation_state(PresentationState.CHOOSING_RESULT_INPUT)
			_build_destination_selection()
		GieoQueService.STATE_TARGET_SELECTION:
			_set_presentation_state(PresentationState.CHOOSING_RESULT_INPUT)
			_build_target_selection()
		GieoQueService.STATE_TARGET_REVEAL:
			_set_presentation_state(PresentationState.RESOLVING_TRANSFORMATION)
			_build_target_reveal()
		GieoQueService.STATE_TRANSFORM:
			_set_presentation_state(PresentationState.RESOLVING_TRANSFORMATION)
			_build_transform()
		GieoQueService.STATE_COMPLETE:
			_set_presentation_state(PresentationState.COMPLETE)
			_build_complete()


func _set_presentation_state(next_state: PresentationState) -> void:
	presentation_state = next_state
	commitment_changed.emit(is_interaction_locked())


func _build_machine(lines: Array, is_ready: bool) -> void:
	_stage = Control.new()
	_stage.name = "OracleMachineStage"
	_stage.custom_minimum_size = STAGE_SIZE
	_stage.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_stage.size_flags_vertical = Control.SIZE_EXPAND_FILL
	add_child(_stage)

	var machine_art := TextureRect.new()
	machine_art.name = "SlotMachineArt"
	machine_art.position = Vector2(220, 0)
	machine_art.size = Vector2(600, 580)
	machine_art.texture = SLOT_TEXTURE
	machine_art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	machine_art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	machine_art.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	machine_art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_stage.add_child(machine_art)

	var title := _label(tr("GIEO_TITLE"), 30, Color("#fff0bd"), HORIZONTAL_ALIGNMENT_CENTER)
	title.name = "OracleTitle"
	title.position = Vector2(395, 15)
	title.size = Vector2(250, 44)
	title.add_theme_color_override("font_shadow_color", Color(0.08, 0.03, 0.01, 0.95))
	title.add_theme_constant_override("shadow_offset_x", 2)
	title.add_theme_constant_override("shadow_offset_y", 3)
	_stage.add_child(title)

	_reels.clear()
	for index in range(6):
		var value := String(lines[index]) if index < lines.size() else ""
		_build_reel(index, value)

	_build_lever(is_ready)
	_build_oracle_panels(is_ready)


func _build_reel(index: int, value: String) -> void:
	var reel := Control.new()
	reel.name = "OracleReel%d" % (index + 1)
	reel.position = Vector2(394, REEL_Y[index])
	reel.size = Vector2(230, 42)
	reel.pivot_offset = reel.size * 0.5
	reel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_stage.add_child(reel)

	var content := Control.new()
	content.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	content.mouse_filter = Control.MOUSE_FILTER_IGNORE
	reel.add_child(content)
	var left := ColorRect.new()
	left.name = "LineLeft"
	left.color = Color("#24170c")
	left.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content.add_child(left)
	var right := ColorRect.new()
	right.name = "LineRight"
	right.color = Color("#24170c")
	right.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content.add_child(right)

	var value_label := _label("", 12, Color("#d7e6f5"), HORIZONTAL_ALIGNMENT_RIGHT)
	value_label.position = Vector2(0, 5)
	value_label.size = Vector2(62, 30)
	content.add_child(value_label)

	_reels.append({"panel": reel, "left": left, "right": right, "label": value_label, "value": ""})
	_set_reel_value(index, value)
	if value.is_empty():
		reel.modulate.a = 0.0


func _build_lever(is_ready: bool) -> void:
	_lever_button = Button.new()
	_lever_button.name = "OracleLever"
	_lever_button.position = Vector2(625, 165)
	_lever_button.size = Vector2(170, 294)
	_lever_button.flat = true
	_lever_button.clip_contents = false
	_lever_button.focus_mode = Control.FOCUS_ALL
	_lever_button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	_lever_button.disabled = not is_ready or not service.can_afford_pull()
	_lever_button.tooltip_text = tr("GIEO_PULL_LEVER")
	_lever_button.pressed.connect(_on_cast_pressed.bind(false))
	_stage.add_child(_lever_button)

	_lever_image = TextureRect.new()
	_lever_image.position = Vector2(-112, -14)
	_lever_image.size = Vector2(450, 300)
	_lever_image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_lever_image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_lever_image.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	_lever_image.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_lever_button.add_child(_lever_image)
	_set_lever_frame(0)


func _build_oracle_panels(is_ready: bool) -> void:
	var upper := _create_oracle_frame("OracleUpperPanel", Vector2(50, 92), tr("GIEO_UPPER_TRIGRAM"), tr("GIEO_FIRST_THREE"))
	_upper_panel = upper["panel"] as PanelContainer
	_upper_label = upper["label"] as Label
	_upper_detail = upper["detail"] as Label
	var lower := _create_oracle_frame("OracleLowerPanel", Vector2(50, 266), tr("GIEO_LOWER_TRIGRAM"), tr("GIEO_LAST_THREE"))
	_lower_panel = lower["panel"] as PanelContainer
	_lower_label = lower["label"] as Label
	_lower_detail = lower["detail"] as Label
	_active_oracle_panel = _upper_panel
	_upper_panel.modulate.a = 1.0
	_lower_panel.modulate.a = 1.0
	if not is_ready:
		_lower_label.modulate.a = 0.38
		_lower_detail.modulate.a = 0.38
	if is_ready and not service.can_afford_pull():
		_upper_detail.text = tr("GIEO_NOT_ENOUGH")
		_upper_detail.add_theme_color_override("font_color", PresentationTheme.RED)


func _create_oracle_frame(node_name: String, position_value: Vector2, title_text: String, detail_text: String) -> Dictionary:
	var panel := PanelContainer.new()
	panel.name = node_name
	panel.position = position_value
	panel.size = Vector2(184, 148)
	panel.pivot_offset = panel.size * 0.5
	panel.add_theme_stylebox_override("panel", PresentationTheme.panel_style(Color("#071a2de8"), Color("#b9822f"), 1, 9, 5))
	_stage.add_child(panel)
	var box := VBoxContainer.new()
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 7)
	panel.add_child(box)
	var title := _label(title_text, 19, PresentationTheme.GOLD, HORIZONTAL_ALIGNMENT_CENTER)
	title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(title)
	var detail := _label(detail_text, 12, Color("#fff0bd"), HORIZONTAL_ALIGNMENT_CENTER)
	detail.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(detail)
	return {"panel": panel, "label": title, "detail": detail}


func _set_reel_value(index: int, value: String) -> void:
	if index < 0 or index >= _reels.size():
		return
	var reel: Dictionary = _reels[index]
	var left := reel["left"] as ColorRect
	var right := reel["right"] as ColorRect
	var label := reel["label"] as Label
	if value == GieoQueService.LINE_DUONG:
		left.position = Vector2(65, 16)
		left.size = Vector2(140, 9)
		right.visible = false
		label.text = tr("GIEO_DUONG")
		label.add_theme_color_override("font_color", PresentationTheme.GOLD)
	elif value == GieoQueService.LINE_AM:
		left.position = Vector2(65, 16)
		left.size = Vector2(60, 9)
		right.position = Vector2(145, 16)
		right.size = Vector2(60, 9)
		right.visible = true
		label.text = tr("GIEO_AM")
		label.add_theme_color_override("font_color", Color("#8fc7ed"))
	else:
		left.position = Vector2(105, 18)
		left.size = Vector2(80, 5)
		right.visible = false
		label.text = ""
		label.add_theme_color_override("font_color", PresentationTheme.MUTED)
	reel["value"] = value
	_reels[index] = reel


func _on_cast_pressed(is_reroll: bool) -> void:
	if _busy or service == null:
		return
	_busy = true
	_set_presentation_state(PresentationState.PULLING_LEVER)
	var result := service.reroll() if is_reroll else service.cast()
	if not result.get("ok", false):
		_busy = false
		feedback_requested.emit(String(result.get("message", "Cast failed.")))
		_rebuild()
		return
	wallet_changed.emit()
	_clear()
	_build_machine([], false)
	await _play_cast_animation()


func _play_cast_animation() -> void:
	impact_requested.emit(&"lever")
	for frame in [1, 2, 3]:
		_set_lever_frame(frame)
		await get_tree().create_timer(0.09).timeout
	_set_lever_frame(4)
	impact_requested.emit(&"lever_clunk")
	_set_presentation_state(PresentationState.SPINNING)
	for frame in [5, 6, 7, 0]:
		await get_tree().create_timer(0.085).timeout
		_set_lever_frame(frame)
	await get_tree().create_timer(0.72).timeout

	await _activate_oracle_group(true, false)
	for index in range(3):
		await _reveal_line(index)
	_set_presentation_state(PresentationState.REVEALING_UPPER)
	impact_requested.emit(&"upper_reveal")
	await get_tree().create_timer(0.62).timeout

	await _activate_oracle_group(false, true)
	for index in range(3, 6):
		await _reveal_line(index)
	_set_presentation_state(PresentationState.REVEALING_LOWER)
	impact_requested.emit(&"lower_reveal")
	await get_tree().create_timer(0.68).timeout
	await _settle_all_lines()
	await _fade_oracle_text()

	_set_presentation_state(PresentationState.SHOWING_RESULT)
	_add_result_panel(true)
	_add_decisions(true)
	await _animate_result_reveal()
	_busy = false
	commitment_changed.emit(true)


func _reveal_line(index: int) -> void:
	var final_lines := service.current_result.get("lines", []) as Array
	if index >= final_lines.size():
		return
	_set_reel_value(index, String(final_lines[index]))
	var line := _reels[index]["panel"] as Control
	line.modulate = Color(1.35, 1.16, 0.72, 0.0)
	line.scale = Vector2(0.97, 1.0)
	var reveal := create_tween().set_parallel(true)
	reveal.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	reveal.tween_property(line, "modulate", Color.WHITE, 0.34)
	reveal.tween_property(line, "scale", Vector2.ONE, 0.34)
	await reveal.finished
	impact_requested.emit(&"reel_stop")
	await _pulse_oracle_phase()
	await get_tree().create_timer(0.42).timeout
	var soften := create_tween()
	soften.tween_property(line, "modulate:a", 0.2, 0.26).set_trans(Tween.TRANS_SINE)
	await soften.finished
	await get_tree().create_timer(0.12).timeout


func _activate_oracle_group(upper: bool, transition: bool) -> void:
	if _upper_panel == null or _lower_panel == null:
		return
	_active_oracle_panel = _upper_panel if upper else _lower_panel
	var active_labels: Array[Label] = [_upper_label, _upper_detail] if upper else [_lower_label, _lower_detail]
	var resting_labels: Array[Label] = [_lower_label, _lower_detail] if upper else [_upper_label, _upper_detail]
	if transition:
		var fade_out := create_tween()
		fade_out.set_parallel(true)
		for label in resting_labels:
			fade_out.tween_property(label, "modulate:a", 0.38, 0.22)
		await fade_out.finished
	var fade_in := create_tween().set_parallel(true)
	for label in active_labels:
		fade_in.tween_property(label, "modulate:a", 1.0, 0.28)
	await fade_in.finished


func _pulse_oracle_phase() -> void:
	if _active_oracle_panel == null:
		return
	var pulse := create_tween()
	pulse.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	pulse.tween_property(_active_oracle_panel, "scale", Vector2(1.045, 1.045), 0.15)
	pulse.tween_property(_active_oracle_panel, "scale", Vector2.ONE, 0.22)
	await pulse.finished


func _settle_all_lines() -> void:
	var settle := create_tween().set_parallel(true)
	for reel in _reels:
		settle.tween_property(reel["panel"] as Control, "modulate", Color.WHITE, 0.32)
	await settle.finished


func _fade_oracle_text() -> void:
	if _upper_label == null or _lower_label == null:
		return
	var fade := create_tween().set_parallel(true)
	for label in [_upper_label, _upper_detail, _lower_label, _lower_detail]:
		fade.tween_property(label, "modulate:a", 0.0, 0.32)
	await fade.finished


func _add_result_panel(animated: bool) -> void:
	if _upper_panel == null or _lower_panel == null:
		_build_oracle_panels(false)
	_upper_panel.name = "ResolvedOracleUpperPanel"
	_lower_panel.name = "ResolvedOracleLowerPanel"
	_upper_label.text = tr("GIEO_CHANGE").to_upper()
	_upper_detail.text = tr(service.effect_label_key())
	_upper_detail.add_theme_color_override("font_color", PresentationTheme.GOLD)
	_lower_label.text = tr("GIEO_TARGET").to_upper()
	_lower_detail.text = tr(service.targeting_label_key())
	_lower_detail.add_theme_color_override("font_color", Color("#9ed0ff"))
	_result_parts = [_upper_label, _upper_detail, _lower_label, _lower_detail]
	if animated:
		for part in _result_parts:
			part.modulate.a = 0.0
	else:
		for part in _result_parts:
			part.modulate.a = 1.0


func _result_value_block(caption: String, value: String, color: Color) -> Control:
	var row := VBoxContainer.new()
	row.add_theme_constant_override("separation", 1)
	var caption_label := _label(caption.to_upper(), 10, Color("#e5c778"), HORIZONTAL_ALIGNMENT_CENTER)
	row.add_child(caption_label)
	var value_label := _label(value, 14, color, HORIZONTAL_ALIGNMENT_CENTER)
	value_label.custom_minimum_size = Vector2(170, 38)
	value_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	row.add_child(value_label)
	return row


func _add_decisions(animated: bool) -> void:
	var decisions := VBoxContainer.new()
	decisions.name = "OracleDecisions"
	decisions.position = Vector2(49, 420)
	decisions.size = Vector2(186, 174)
	decisions.alignment = BoxContainer.ALIGNMENT_CENTER
	decisions.add_theme_constant_override("separation", 7)
	_stage.add_child(decisions)
	var accept := _button(tr("GIEO_ACCEPT"), "tea", Vector2(186, 48))
	accept.pressed.connect(_on_accept_pressed)
	decisions.add_child(accept)
	var reroll := _button(_trf("GIEO_REROLL", VndWallet.format_vnd(service.current_pull_cost())), "gold", Vector2(186, 54))
	reroll.disabled = not service.can_afford_pull()
	reroll.pressed.connect(_on_cast_pressed.bind(true))
	decisions.add_child(reroll)
	var refuse := _button(tr("GIEO_REFUSE"), "danger", Vector2(186, 48))
	refuse.pressed.connect(_on_refuse_pressed)
	decisions.add_child(refuse)
	_decision_row = decisions
	if animated:
		decisions.modulate.a = 0.0
		decisions.mouse_filter = Control.MOUSE_FILTER_IGNORE


func _animate_result_reveal() -> void:
	impact_requested.emit(&"result_reveal")
	for part in _result_parts:
		var tween := create_tween()
		tween.tween_property(part, "modulate:a", 1.0, 0.12)
		await tween.finished
	if _decision_row != null:
		var buttons_tween := create_tween()
		buttons_tween.tween_property(_decision_row, "modulate:a", 1.0, 0.18)
		await buttons_tween.finished
		_decision_row.mouse_filter = Control.MOUSE_FILTER_STOP


func _build_destination_selection() -> void:
	var jackpot := String(service.current_result.get("jackpot", ""))
	var chooses_rank := jackpot == GieoQueService.JACKPOT_THUAN_DUONG or String(service.current_result.get("effect", "")) == GieoQueService.EFFECT_CHOOSE_RANK
	var box := _build_flow_shell(tr("GIEO_CHOOSE_RANK") if chooses_rank else tr("GIEO_CHOOSE_SUIT_NEW"))
	_build_compact_result(box)
	var instruction := _label(tr("GIEO_CHOOSE_RANK") if chooses_rank else tr("GIEO_CHOOSE_SUIT_NEW"), 18, PresentationTheme.GOLD, HORIZONTAL_ALIGNMENT_CENTER)
	box.add_child(instruction)
	var choices := GridContainer.new()
	choices.columns = 7 if chooses_rank else 4
	choices.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	choices.add_theme_constant_override("h_separation", 7)
	choices.add_theme_constant_override("v_separation", 7)
	box.add_child(choices)
	var values: Array[String] = DeckManager.RANKS if chooses_rank else DeckManager.SUITS
	for value in values:
		var button := _button(value.to_upper() if chooses_rank else _suit_label(value), "gold", Vector2(76 if chooses_rank else 130, 46))
		button.pressed.connect(_on_destination_pressed.bind(value))
		choices.add_child(button)


func _build_target_selection() -> void:
	var box := _build_flow_shell(tr("GIEO_CHOOSE_TARGET"))
	var offered_only := not service.resolved_targets.is_empty()
	var instruction := _label(tr("GIEO_CHOOSE_OFFER") if offered_only else tr("GIEO_CHOOSE_DECK_CARD"), 16, PresentationTheme.GOLD, HORIZONTAL_ALIGNMENT_CENTER)
	box.add_child(instruction)
	var cards: Array[CardData] = service.resolved_targets if offered_only else service.persistent_deck
	_build_card_picker(box, cards, offered_only)
	var locked := _label(tr("GIEO_COMMITTED_LOCK"), 10, PresentationTheme.RED.lightened(0.2), HORIZONTAL_ALIGNMENT_CENTER)
	box.add_child(locked)


func _build_target_reveal() -> void:
	var box := _build_flow_shell(tr("GIEO_TARGETS_REVEALED"))
	var title := _label(tr("GIEO_PRESENT_TARGETS"), 15, Color("#fff0bd"), HORIZONTAL_ALIGNMENT_CENTER)
	box.add_child(title)
	_build_card_picker(box, service.resolved_targets, true, false)
	var seal := _label(tr("GIEO_SEALING"), 13, PresentationTheme.TEA, HORIZONTAL_ALIGNMENT_CENTER)
	box.add_child(seal)


func _build_transform() -> void:
	var box := _build_flow_shell(tr("GIEO_FATE_REWRITTEN"))
	for transformation in service.last_transformations:
		_build_transformation_row(box, transformation)


func _build_complete() -> void:
	var box := _build_flow_shell(tr("GIEO_FATE_SEALED"))
	var summary := _label(_trf("GIEO_COMPLETE_SUMMARY", service.last_transformations.size()), 16, PresentationTheme.TEA, HORIZONTAL_ALIGNMENT_CENTER)
	summary.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(summary)
	var again := _button(_trf("GIEO_CAST_AGAIN", VndWallet.format_vnd(service.current_pull_cost())), "gold", Vector2(0, 52))
	again.disabled = not service.can_afford_pull()
	again.pressed.connect(_on_cast_pressed.bind(false))
	box.add_child(again)


func _build_flow_shell(title_text: String) -> VBoxContainer:
	var stage := Control.new()
	_stage = stage
	stage.custom_minimum_size = STAGE_SIZE
	stage.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	stage.size_flags_vertical = Control.SIZE_EXPAND_FILL
	add_child(stage)
	var lacquer := ColorRect.new()
	lacquer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	lacquer.color = Color("#071a2ded")
	lacquer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stage.add_child(lacquer)
	var art := TextureRect.new()
	art.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	art.texture = SLOT_TEXTURE
	art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	art.modulate = Color(0.35, 0.45, 0.58, 0.22)
	art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stage.add_child(art)
	var panel := PanelContainer.new()
	panel.position = Vector2(24, 18)
	panel.size = Vector2(732, 469)
	panel.add_theme_stylebox_override("panel", PresentationTheme.panel_style(Color("#08192bf2"), PresentationTheme.GOLD, 2, 9, 6))
	stage.add_child(panel)
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 18)
	margin.add_theme_constant_override("margin_top", 12)
	margin.add_theme_constant_override("margin_right", 18)
	margin.add_theme_constant_override("margin_bottom", 12)
	panel.add_child(margin)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 8)
	margin.add_child(box)
	var title := _label(title_text, 22, PresentationTheme.GOLD, HORIZONTAL_ALIGNMENT_CENTER)
	box.add_child(title)
	return box


func _build_compact_result(parent: VBoxContainer) -> void:
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 24)
	row.add_child(_result_value_block(tr("GIEO_CHANGE"), tr(service.effect_label_key()), PresentationTheme.GOLD))
	row.add_child(_result_value_block(tr("GIEO_TARGET"), tr(service.targeting_label_key()), Color("#9ed0ff")))
	parent.add_child(row)


func _build_transformation_row(parent: VBoxContainer, transformation: Dictionary) -> void:
	var row := HBoxContainer.new()
	row.name = "TransformationRow"
	row.set_meta("gieo_transform_row", true)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 13)
	parent.add_child(row)
	var before: Dictionary = transformation["before"]
	var after: Dictionary = transformation["after"]
	var before_card := _snapshot_card(before, tr("GIEO_BEFORE"))
	var after_card := _snapshot_card(after, tr("GIEO_PERMANENT"))
	after_card.modulate = Color(1.45, 1.2, 0.55, 0.0)
	row.add_child(before_card)
	row.add_child(_label("➜", 26, PresentationTheme.GOLD, HORIZONTAL_ALIGNMENT_CENTER))
	row.add_child(after_card)
	row.set_meta("before_card", before_card)
	row.set_meta("after_card", after_card)


func _snapshot_card(snapshot: Dictionary, caption: String) -> Control:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(250, 88)
	panel.add_theme_stylebox_override("panel", PresentationTheme.panel_style(Color("#f4ead8f2"), PresentationTheme.GOLD, 2, 6, 3))
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 8)
	panel.add_child(row)
	var rank := String(snapshot.get("rank", "?"))
	var suit := String(snapshot.get("suit", "?"))
	var card_art := TextureRect.new()
	card_art.name = "SnapshotCardArt"
	var texture_path := _snapshot_texture_path(rank, suit)
	panel.set_meta("card_texture_path", texture_path)
	card_art.custom_minimum_size = Vector2(48, 67)
	card_art.texture = load(texture_path) as Texture2D
	card_art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	card_art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	card_art.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	card_art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.set_meta("card_art", card_art)
	row.add_child(card_art)
	var text := Label.new()
	var properties: Array = snapshot.get("gieo_properties", [])
	var readable_properties: Array[String] = []
	for property_id in properties:
		readable_properties.append(_property_label(String(property_id)))
	text.text = "%s\n%s · %s%s" % [caption, rank, _suit_label(suit), "\n" + " · ".join(readable_properties) if not readable_properties.is_empty() else ""]
	text.custom_minimum_size.x = 172
	text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	text.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	text.add_theme_color_override("font_color", Color("#24170c"))
	row.add_child(text)
	return panel


func _snapshot_texture_path(rank: String, suit: String) -> String:
	var rank_file := String(CardData.RANK_FILE_NAMES.get(rank, rank.to_lower()))
	var suit_file: String = {
		"S": "spades", "H": "hearts", "D": "diamonds", "C": "clubs",
	}.get(suit.to_upper(), suit.to_lower())
	return "res://cards/%s_of_%s.png" % [rank_file, suit_file]


func _animate_transform() -> void:
	if not is_inside_tree() or service == null or service.state != GieoQueService.STATE_TRANSFORM:
		return
	await get_tree().create_timer(0.55).timeout
	for row in _find_controls_with_meta(self, &"gieo_transform_row"):
		var before_card := row.get_meta("before_card") as Control
		var after_card := row.get_meta("after_card") as Control
		var tween := create_tween().set_parallel(true)
		tween.tween_property(before_card, "modulate:a", 0.0, 0.16)
		tween.tween_property(before_card, "scale", Vector2(0.86, 1.08), 0.16)
		tween.tween_property(after_card, "modulate", Color.WHITE, 0.22).set_delay(0.08)
		tween.tween_property(after_card, "scale", Vector2(1.08, 1.08), 0.14).set_delay(0.08)
		tween.chain().tween_property(after_card, "scale", Vector2.ONE, 0.13)
		impact_requested.emit(&"transform_card")
		await get_tree().create_timer(0.22).timeout
	await get_tree().create_timer(0.65).timeout


func _find_controls_with_meta(root: Node, key: StringName) -> Array[Control]:
	var found: Array[Control] = []
	for child in root.get_children():
		if child is Control and child.has_meta(key):
			found.append(child as Control)
		found.append_array(_find_controls_with_meta(child, key))
	return found


func _build_card_picker(parent: VBoxContainer, cards: Array[CardData], large: bool, interactive: bool = true) -> void:
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(0, 285 if not large else 190)
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	parent.add_child(scroll)
	var grid := GridContainer.new()
	grid.columns = 8 if not large else maxi(cards.size(), 1)
	grid.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	grid.add_theme_constant_override("h_separation", 8)
	grid.add_theme_constant_override("v_separation", 8)
	scroll.add_child(grid)
	for card in cards:
		var button := Button.new()
		button.custom_minimum_size = Vector2(82, 116) if large else CARD_THUMB_SIZE
		button.icon = load(card.texture_path()) as Texture2D
		button.expand_icon = true
		button.tooltip_text = "%s\n%s" % [card.short_label(), "\n".join(card.gieo_property_descriptions())]
		button.disabled = not interactive
		PresentationTheme.configure_button(button, "gold" if large else "neutral")
		if interactive:
			button.pressed.connect(_on_target_pressed.bind(card.unique_id))
		grid.add_child(button)


func _on_accept_pressed() -> void:
	if _busy or presentation_state != PresentationState.SHOWING_RESULT:
		return
	_busy = true
	var result := service.accept()
	if not result.get("ok", false):
		_busy = false
		feedback_requested.emit(String(result.get("message", "Accept failed.")))
		return
	impact_requested.emit(&"accept")
	_set_presentation_state(PresentationState.CHOOSING_RESULT_INPUT if service.state in [GieoQueService.STATE_DESTINATION_SELECTION, GieoQueService.STATE_TARGET_SELECTION] else PresentationState.RESOLVING_TRANSFORMATION)
	await _continue_committed_flow()
	_busy = false


func _on_destination_pressed(destination: String) -> void:
	if _busy:
		return
	_busy = true
	var result := service.choose_destination(destination)
	if not result.get("ok", false):
		_busy = false
		feedback_requested.emit(String(result.get("message", "Destination failed.")))
		return
	impact_requested.emit(&"choose")
	await _continue_committed_flow()
	_busy = false


func _continue_committed_flow() -> void:
	_rebuild()
	if service.state != GieoQueService.STATE_TARGET_REVEAL:
		return
	await get_tree().create_timer(0.62).timeout
	var result := service.apply_resolved_targets()
	if not result.get("ok", false):
		feedback_requested.emit(String(result.get("message", "Transformation failed.")))
		return
	impact_requested.emit(&"transform")
	_rebuild()
	await _finish_transform_presentation()


func _on_target_pressed(card_id: String) -> void:
	if _busy:
		return
	_busy = true
	var result := service.choose_target(card_id)
	if not result.get("ok", false):
		_busy = false
		feedback_requested.emit(String(result.get("message", "Target failed.")))
		return
	impact_requested.emit(&"transform")
	_rebuild()
	await _finish_transform_presentation()
	_busy = false


func _finish_transform_presentation() -> void:
	await _animate_transform()
	if service.state != GieoQueService.STATE_TRANSFORM:
		return
	service.finish_transformation()
	_busy = false
	_rebuild()


func _on_refuse_pressed() -> void:
	if _busy or presentation_state != PresentationState.SHOWING_RESULT:
		return
	var result := service.refuse()
	if not result.get("ok", false):
		feedback_requested.emit(String(result.get("message", "Refuse failed.")))
		return
	impact_requested.emit(&"refuse")
	_rebuild()


func _set_lever_frame(frame: int) -> void:
	if _lever_image == null:
		return
	var column := posmod(frame, LEVER_COLUMNS)
	var row := clampi(floori(float(frame) / float(LEVER_COLUMNS)), 0, LEVER_ROWS - 1)
	_lever_image.texture = _atlas_region(LEVER_TEXTURE, Rect2(Vector2(column, row) * LEVER_FRAME_SIZE, LEVER_FRAME_SIZE))


func _atlas_region(texture: Texture2D, region: Rect2) -> AtlasTexture:
	var atlas := AtlasTexture.new()
	atlas.atlas = texture
	atlas.region = region
	return atlas


func _label(text_value: String, font_size: int, color: Color, horizontal_alignment_value: HorizontalAlignment) -> Label:
	var label := Label.new()
	label.text = text_value
	label.horizontal_alignment = horizontal_alignment_value
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return label


func _trf(key: String, values: Variant) -> String:
	var template := tr(key)
	if not template.contains("%"):
		return template
	if values is Array:
		return template % (values as Array)
	return template % values


func _property_label(property_id: String) -> String:
	match property_id:
		GieoQueService.PROPERTY_SET_RETRIGGER:
			return tr("GIEO_PROPERTY_SET")
		GieoQueService.PROPERTY_MAKING_PHOM_RETRIGGER:
			return tr("GIEO_PROPERTY_MAKING")
		GieoQueService.PROPERTY_EXTEND_RETRIGGER:
			return tr("GIEO_PROPERTY_EXTEND")
		GieoQueService.PROPERTY_RUN_RETRIGGER:
			return tr("GIEO_PROPERTY_RUN")
	return property_id.replace("_", " ")


func _suit_label(suit: String) -> String:
	match suit:
		"Spades":
			return tr("SUIT_SPADES")
		"Hearts":
			return tr("SUIT_HEARTS")
		"Diamonds":
			return tr("SUIT_DIAMONDS")
		"Clubs":
			return tr("SUIT_CLUBS")
	return suit.to_upper()


func _button(text_value: String, tone: String, minimum: Vector2) -> Button:
	var button := Button.new()
	button.text = text_value
	button.custom_minimum_size = minimum
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	PresentationTheme.configure_button(button, tone)
	return button


func _clear() -> void:
	_stage = null
	_lever_button = null
	_lever_image = null
	_upper_panel = null
	_lower_panel = null
	_upper_label = null
	_lower_label = null
	_upper_detail = null
	_lower_detail = null
	_active_oracle_panel = null
	_result_parts.clear()
	_decision_row = null
	_reels.clear()
	for child in get_children():
		var was_inside_tree := child.is_inside_tree()
		remove_child(child)
		if was_inside_tree:
			child.queue_free()
		else:
			child.free()
