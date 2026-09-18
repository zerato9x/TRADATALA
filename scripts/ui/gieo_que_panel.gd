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
const CARD_SYMBOL_ART_SCRIPT := preload("res://scripts/ui/card_symbol_art.gd")
const LEVER_FRAMES := [
	preload("res://assets/ui/gieo_que/lever_1.png"),
	preload("res://assets/ui/gieo_que/lever_2.png"),
	preload("res://assets/ui/gieo_que/lever_3.png"),
	preload("res://assets/ui/gieo_que/lever_4.png"),
	preload("res://assets/ui/gieo_que/lever_5.png"),
]
const CARD_THUMB_SIZE := Vector2(54, 75)
const STAGE_SIZE := Vector2(840, 600)
# Coordinates share the cabinet's native 1182 x 1331 canvas, scaled by 0.45.
const MACHINE_SCALE := 0.45
const MACHINE_ORIGIN := Vector2(260, 0)
const REEL_Y := [110.0, 159.0, 207.0, 268.0, 315.0, 364.0]
const REEL_PITCH := 42.0

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
	if is_visible_in_tree() and event.is_action_pressed("ui_accept") and not event.is_echo() and presentation_state == PresentationState.IDLE and not _busy and service != null and service.can_afford_pull():
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
	machine_art.position = MACHINE_ORIGIN
	machine_art.size = SLOT_TEXTURE.get_size() * MACHINE_SCALE
	machine_art.texture = SLOT_TEXTURE
	machine_art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	machine_art.stretch_mode = TextureRect.STRETCH_SCALE
	machine_art.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	machine_art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_stage.add_child(machine_art)

	var title := _label(tr("GIEO_TITLE"), 30, Color("#fff0bd"), HORIZONTAL_ALIGNMENT_CENTER)
	title.name = "OracleTitle"
	title.position = Vector2(391, 24)
	title.size = Vector2(242, 44)
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
	if is_ready:
		var pull_hint := _label("%s\n%s" % [tr("GIEO_PULL_LEVER"), VndWallet.format_vnd(service.current_pull_cost())], 16, PresentationTheme.GOLD, HORIZONTAL_ALIGNMENT_CENTER)
		pull_hint.name = "OraclePullCost"
		pull_hint.position = Vector2(340, 447)
		pull_hint.size = Vector2(350, 62)
		_stage.add_child(pull_hint)


func _build_reel(index: int, value: String) -> void:
	var reel := Control.new()
	reel.name = "OracleReel%d" % (index + 1)
	reel.position = Vector2(411, REEL_Y[index])
	reel.size = Vector2(198, 38)
	reel.clip_contents = true
	reel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_stage.add_child(reel)
	var symbols: Array[Control] = []
	for slot in range(5):
		var symbol := Control.new()
		symbol.mouse_filter = Control.MOUSE_FILTER_IGNORE
		reel.add_child(symbol)
		for part in range(2):
			var bar := ColorRect.new()
			bar.color = Color("#24170c")
			bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
			symbol.add_child(bar)
		symbols.append(symbol)
	_reels.append({"panel": reel, "symbols": symbols, "value": "", "travel": 0.0})
	_set_reel_value(index, value)

func _build_lever(is_ready: bool) -> void:
	_lever_button = Button.new()
	_lever_button.name = "OracleLever"
	_lever_button.position = Vector2(676, 165)
	_lever_button.size = Vector2(110, 259)
	_lever_button.flat = true
	_lever_button.z_index = 5
	_lever_button.clip_contents = false
	_lever_button.focus_mode = Control.FOCUS_ALL
	_lever_button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	_lever_button.disabled = not is_ready or not service.can_afford_pull()
	_lever_button.tooltip_text = "%s · %s" % [tr("GIEO_PULL_LEVER"), VndWallet.format_vnd(service.current_pull_cost())]
	_lever_button.pressed.connect(_on_cast_pressed.bind(false))
	_stage.add_child(_lever_button)

	_lever_image = TextureRect.new()
	_lever_image.position = Vector2.ZERO
	_lever_image.size = Vector2(297, 359) * 0.72
	_lever_image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_lever_image.stretch_mode = TextureRect.STRETCH_SCALE
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
	_reels[index]["value"] = value
	_set_reel_travel(0.0, index)


func _set_reel_travel(distance: float, index: int) -> void:
	var reel: Dictionary = _reels[index]
	reel["travel"] = distance
	var symbols: Array = reel["symbols"]
	var offset := fposmod(distance, REEL_PITCH * 2.0)
	for slot in range(symbols.size()):
		var symbol := symbols[slot] as Control
		var row := slot - 2
		symbol.position = Vector2(0, row * REEL_PITCH + offset)
		var solid := String(reel["value"]) != GieoQueService.LINE_AM
		if posmod(row, 2) != 0:
			solid = not solid
		var left := symbol.get_child(0) as ColorRect
		var right := symbol.get_child(1) as ColorRect
		left.position = Vector2(29, 15)
		left.size = Vector2(140 if solid else 60, 8)
		right.position = Vector2(109, 15)
		right.size = Vector2(60, 8)
		right.visible = not solid
		symbol.modulate.a = 0.32 if String(reel["value"]).is_empty() else 1.0

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
	for frame in [1, 2, 3, 4]:
		_set_lever_frame(frame)
		await get_tree().create_timer(0.045).timeout
	impact_requested.emit(&"lever_clunk")
	_set_presentation_state(PresentationState.SPINNING)
	var final_lines := service.current_result.get("lines", []) as Array
	var last_spin: Tween
	# Every reel begins together. Each strip travels whole revolutions so its
	# charged result lands exactly at the center, without swapping on the stop.
	for index in range(_reels.size()):
		_set_reel_value(index, String(final_lines[index]))
		var spin := create_tween()
		last_spin = spin
		spin.tween_method(_set_reel_travel.bind(index), 0.0, REEL_PITCH * 2.0, 0.12).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		spin.tween_method(_set_reel_travel.bind(index), REEL_PITCH * 2.0, REEL_PITCH * 2.0 * (10 + index) + 3.0, 0.85 + index * 0.16).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		spin.tween_method(_set_reel_travel.bind(index), REEL_PITCH * 2.0 * (10 + index) + 3.0, REEL_PITCH * 2.0 * (10 + index), 0.09).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		spin.tween_callback(_on_reel_stopped.bind(index))
	for frame in [3, 2, 1, 0]:
		await get_tree().create_timer(0.045).timeout
		_set_lever_frame(frame)
	while last_spin.is_running():
		await get_tree().process_frame
	_set_presentation_state(PresentationState.SHOWING_RESULT)
	_add_result_panel(true)
	_add_decisions(true)
	await _animate_result_reveal()
	_busy = false
	if _decision_row != null:
		(_decision_row.get_child(0) as Button).grab_focus()
	commitment_changed.emit(true)


func _on_reel_stopped(index: int) -> void:
	_set_reel_travel(0.0, index)
	impact_requested.emit(&"reel_stop")
	var reel := _reels[index]["panel"] as Control
	reel.modulate = Color(1.45, 1.22, 0.72)
	var settle := create_tween()
	settle.tween_property(reel, "modulate", Color.WHITE, 0.16)
	if index == 2 or index == 5:
		var upper := index == 2
		_set_presentation_state(PresentationState.REVEALING_UPPER if upper else PresentationState.REVEALING_LOWER)
		impact_requested.emit(&"upper_reveal" if upper else &"lower_reveal")
		var panel := _upper_panel if upper else _lower_panel
		panel.modulate = Color(1.3, 1.15, 0.8)
		var pulse := create_tween()
		pulse.tween_property(panel, "modulate", Color.WHITE, 0.2)

func _add_result_panel(animated: bool) -> void:
	if _upper_panel == null or _lower_panel == null:
		_build_oracle_panels(false)
	_upper_panel.name = "ResolvedOracleUpperPanel"
	_lower_panel.name = "ResolvedOracleLowerPanel"
	_upper_label.text = tr("GIEO_CHANGE").to_upper()
	_upper_detail.text = _effect_text()
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
	var decisions := HBoxContainer.new()
	decisions.name = "OracleDecisions"
	decisions.position = Vector2(316, 449)
	decisions.size = Vector2(418, 66)
	decisions.alignment = BoxContainer.ALIGNMENT_CENTER
	decisions.add_theme_constant_override("separation", 7)
	_stage.add_child(decisions)
	var accept := _button(tr("GIEO_ACCEPT"), "tea", Vector2(120, 62))
	accept.pressed.connect(_on_accept_pressed)
	decisions.add_child(accept)
	var reroll := _button(_trf("GIEO_REROLL", VndWallet.format_vnd(service.current_pull_cost())), "gold", Vector2(160, 62))
	reroll.disabled = not service.can_afford_pull()
	reroll.pressed.connect(_on_cast_pressed.bind(true))
	decisions.add_child(reroll)
	var refuse := _button(tr("GIEO_REFUSE"), "danger", Vector2(120, 62))
	refuse.pressed.connect(_on_refuse_pressed)
	decisions.add_child(refuse)
	_decision_row = decisions
	if animated:
		decisions.modulate.a = 0.0
		decisions.hide()


func _animate_result_reveal() -> void:
	impact_requested.emit(&"result_reveal")
	if not String(service.current_result.get("jackpot", "")).is_empty():
		impact_requested.emit(&"jackpot")
	for part in _result_parts:
		var tween := create_tween()
		tween.tween_property(part, "modulate:a", 1.0, 0.12)
		await tween.finished
	if _decision_row != null:
		_decision_row.show()
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
		if not chooses_rank:
			button.icon = CARD_SYMBOL_ART_SCRIPT.texture_for_suit(value)
			button.expand_icon = true
			button.add_theme_constant_override("icon_max_width", 14)
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
	for transformation in service.last_transformations:
		_build_transformation_row(box, transformation, false)


func _build_flow_shell(title_text: String) -> VBoxContainer:
	var stage := Control.new()
	_stage = stage
	stage.custom_minimum_size = STAGE_SIZE
	stage.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	stage.size_flags_vertical = Control.SIZE_EXPAND_FILL
	add_child(stage)
	var backing := Panel.new()
	backing.position = Vector2(12, 8)
	backing.size = STAGE_SIZE - Vector2(24, 24)
	backing.mouse_filter = Control.MOUSE_FILTER_IGNORE
	backing.add_theme_stylebox_override("panel", PresentationTheme.panel_style(Color("#071a2df5"), Color("#b9822f"), 2, 12, 8))
	stage.add_child(backing)
	var margin := MarginContainer.new()
	margin.position = Vector2(24, 18)
	margin.size = STAGE_SIZE - Vector2(48, 36)
	margin.add_theme_constant_override("margin_left", 18)
	margin.add_theme_constant_override("margin_top", 12)
	margin.add_theme_constant_override("margin_right", 18)
	margin.add_theme_constant_override("margin_bottom", 12)
	stage.add_child(margin)
	var scroll := ScrollContainer.new()
	scroll.name = "OracleFlowScroll"
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	margin.add_child(scroll)
	var box := VBoxContainer.new()
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.add_theme_constant_override("separation", 8)
	scroll.add_child(box)
	var title := _label(title_text, 22, PresentationTheme.GOLD, HORIZONTAL_ALIGNMENT_CENTER)
	box.add_child(title)
	return box


func _build_compact_result(parent: VBoxContainer) -> void:
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 24)
	row.add_child(_result_value_block(tr("GIEO_CHANGE"), _effect_text(), PresentationTheme.GOLD))
	row.add_child(_result_value_block(tr("GIEO_TARGET"), tr(service.targeting_label_key()), Color("#9ed0ff")))
	parent.add_child(row)


func _effect_text() -> String:
	var text := tr(service.effect_label_key())
	return text


func _build_transformation_row(parent: VBoxContainer, transformation: Dictionary, animated: bool = true) -> void:
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
	if animated:
		after_card.modulate = Color(1.45, 1.2, 0.55, 0.0)
	row.add_child(before_card)
	row.add_child(_label("➜", 26, PresentationTheme.GOLD, HORIZONTAL_ALIGNMENT_CENTER))
	row.add_child(after_card)
	row.set_meta("before_card", before_card)
	row.set_meta("after_card", after_card)


func _snapshot_card(snapshot: Dictionary, caption: String) -> Control:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(300, 176)
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
	card_art.custom_minimum_size = Vector2(114, 158)
	card_art.texture = load(texture_path) as Texture2D
	GieoCardFX.apply_properties(card_art, snapshot.get("gieo_properties", []))
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
	text.text = "%s\n%s · %s%s" % [caption, rank, _suit_label(suit), "\n" + "\n".join(readable_properties) if not readable_properties.is_empty() else ""]
	text.custom_minimum_size.x = 172
	text.add_theme_font_size_override("font_size", 13)
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
		var card_art := TextureRect.new()
		card_art.name = "PickerCardArt"
		card_art.texture = load(card.texture_path()) as Texture2D
		card_art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		card_art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		card_art.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		card_art.mouse_filter = Control.MOUSE_FILTER_IGNORE
		button.add_child(card_art)
		card_art.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		card_art.offset_left = 6
		card_art.offset_top = 6
		card_art.offset_right = -6
		card_art.offset_bottom = -6
		GieoCardFX.attach_texture(card_art, card)
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
	if _lever_image != null:
		_lever_image.texture = LEVER_FRAMES[clampi(frame, 0, LEVER_FRAMES.size() - 1)]

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
	var key := CardData.gieo_property_label_key(property_id)
	return tr(key) if not key.is_empty() else property_id.replace("_", " ")


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
