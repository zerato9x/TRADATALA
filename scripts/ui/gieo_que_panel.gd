class_name GieoQuePanel
extends VBoxContainer

signal wallet_changed()
signal feedback_requested(message: String)
signal impact_requested(kind: StringName)
signal commitment_changed(committed: bool)
signal card_pick_requested(cards: Array[CardData], reason: String, callback: Callable)

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
var _fast_forward := false
var _animation_tweens: Array[Tween] = []


func configure(p_service: GieoQueService) -> void:
	service = p_service
	name = "GieoQuePanel"
	custom_minimum_size = STAGE_SIZE
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	size_flags_vertical = Control.SIZE_EXPAND_FILL
	add_theme_constant_override("separation", 0)
	_rebuild()
	if service.state in [GieoQueService.STATE_TARGET_REVEAL, GieoQueService.STATE_TRANSFORM]:
		call_deferred("_resume_committed_flow")


func _input(event: InputEvent) -> void:
	if not is_visible_in_tree() or not _busy:
		return
	if (event is InputEventKey and event.pressed and not event.echo and event.keycode in [KEY_SPACE, KEY_ENTER]) or (event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT):
		_fast_forward = true
		for tween in _animation_tweens:
			if tween.is_valid(): tween.set_speed_scale(12.0)
		get_viewport().set_input_as_handled()


func _tween() -> Tween:
	var tween := create_tween()
	if _fast_forward: tween.set_speed_scale(12.0)
	_animation_tweens.append(tween)
	return tween


func _pause(seconds: float) -> void:
	var remaining := seconds
	while remaining > 0.0 and is_inside_tree():
		await get_tree().process_frame
		remaining -= get_process_delta_time() * (12.0 if _fast_forward else 1.0)


func _unhandled_input(event: InputEvent) -> void:
	if is_visible_in_tree() and event.is_action_pressed("ui_accept") and not event.is_echo() and presentation_state == PresentationState.IDLE and not _busy and service != null and service.can_afford_pull():
		get_viewport().set_input_as_handled()
		cast(false)


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


func _add_handbook() -> void:
	var guide := Button.new()
	guide.name = "GieoGuide"
	guide.text = GameGlossary.words("Handbook", "Sổ tay")
	PresentationTheme.configure_button(guide)
	guide.position = Vector2(690, 0)
	guide.size = Vector2(165, 38)
	guide.z_index = 100
	guide.top_level = false
	guide.pressed.connect(func(): GameGlossary.open(self, "gieo"))
	# Use the free-positioned stage so the guide never consumes the cabinet layout.
	if is_instance_valid(_stage):
		_stage.add_child(guide)
	else:
		add_child(guide)


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
		var pull_hint := _label("%s\n%s" % [tr("GIEO_PULL_LEVER"), VndWallet.format_vnd(-service.current_pull_cost())], 16, PresentationTheme.GOLD, HORIZONTAL_ALIGNMENT_CENTER)
		pull_hint.name = "OraclePullCost"
		pull_hint.position = Vector2(340, 447)
		pull_hint.size = Vector2(350, 62)
		_stage.add_child(pull_hint)
	_add_handbook()


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
	_lever_button.tooltip_text = "%s · %s" % [tr("GIEO_PULL_LEVER"), VndWallet.format_vnd(-service.current_pull_cost())]
	_lever_button.pressed.connect(cast.bind(false))
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
		_upper_detail.add_theme_color_override("font_color", PresentationTheme.DANGER)


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
		var solid := String(reel["value"]) != GieoQueService.LINE_NEGATIVE
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

func cast(is_reroll: bool, forced_lines: Array[String] = []) -> void:
	if _busy or service == null:
		return
	_busy = true
	_fast_forward = false
	_animation_tweens.clear()
	_set_presentation_state(PresentationState.PULLING_LEVER)
	var result := service.reroll(forced_lines) if is_reroll else service.cast(forced_lines)
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
		await _pause(0.045)
	impact_requested.emit(&"lever_clunk")
	_set_presentation_state(PresentationState.SPINNING)
	var final_lines := service.current_result.get("lines", []) as Array
	var last_spin: Tween
	# Every reel begins together. Each strip travels whole revolutions so its
	# charged result lands exactly at the center, without swapping on the stop.
	for index in range(_reels.size()):
		_set_reel_value(index, String(final_lines[index]))
		var spin := _tween()
		last_spin = spin
		spin.tween_method(_set_reel_travel.bind(index), 0.0, REEL_PITCH * 2.0, 0.12).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		spin.tween_method(_set_reel_travel.bind(index), REEL_PITCH * 2.0, REEL_PITCH * 2.0 * (10 + index) + 3.0, 0.85 + index * 0.16).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		spin.tween_method(_set_reel_travel.bind(index), REEL_PITCH * 2.0 * (10 + index) + 3.0, REEL_PITCH * 2.0 * (10 + index), 0.09).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		spin.tween_callback(_on_reel_stopped.bind(index))
	for frame in [3, 2, 1, 0]:
		await _pause(0.045)
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
	var settle := _tween()
	settle.tween_property(reel, "modulate", Color.WHITE, 0.16)
	if index == 2 or index == 5:
		var upper := index == 2
		_set_presentation_state(PresentationState.REVEALING_UPPER if upper else PresentationState.REVEALING_LOWER)
		impact_requested.emit(&"upper_reveal" if upper else &"lower_reveal")
		var panel := _upper_panel if upper else _lower_panel
		if upper:
			_show_upper_result()
		else:
			_show_lower_result()
		panel.modulate = Color(1.3, 1.15, 0.8)
		var pulse := _tween()
		pulse.tween_property(panel, "modulate", Color.WHITE, 0.2)


func _show_upper_result() -> void:
	_upper_label.text = tr("CARD_FORTUNE").to_upper()
	_upper_detail.text = "%+d" % int(service.current_result.get("fortune_delta", 0))
	_upper_detail.add_theme_font_size_override("font_size", 42)
	_upper_detail.set_meta("text_role", &"gain" if int(service.current_result.get("fortune_delta", 0)) > 0 else &"cost")


func _show_lower_result() -> void:
	_lower_label.text = tr("GIEO_TARGET").to_upper()
	_lower_detail.text = service.targeting_label()
	_lower_detail.add_theme_font_size_override("font_size", 17)
	_lower_label.modulate.a = 1.0
	_lower_detail.modulate.a = 1.0

func _add_result_panel(animated: bool) -> void:
	if _upper_panel == null or _lower_panel == null:
		_build_oracle_panels(false)
	_upper_panel.name = "ResolvedOracleUpperPanel"
	_lower_panel.name = "ResolvedOracleLowerPanel"
	_show_upper_result()
	_show_lower_result()
	var jackpot := String(service.current_result.get("jackpot", ""))
	if not jackpot.is_empty():
		var plaque := _label("%s\n%s" % [GameGlossary.words("JACKPOT", "ĐỘC ĐẮC"), tr(CardData.property_label_key(CardData.JACKPOT_LIQUID if jackpot == GieoQueService.JACKPOT_THUAN_DUONG else CardData.JACKPOT_NEGATIVE))], 22, PresentationTheme.GOLD, HORIZONTAL_ALIGNMENT_CENTER)
		plaque.name = "JackpotPlaque"
		plaque.position = Vector2(27, 14)
		plaque.size = Vector2(230, 64)
		plaque.add_theme_color_override("font_shadow_color", Color("#180e09"))
		plaque.add_theme_constant_override("shadow_offset_y", 2)
		_stage.add_child(plaque)
		if animated:
			plaque.scale = Vector2(0.6, 0.6)
			plaque.pivot_offset = plaque.size * 0.5
			var jackpot_tween := _tween()
			jackpot_tween.tween_property(plaque, "scale", Vector2.ONE, 0.55).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_result_parts = [_upper_label, _upper_detail, _lower_label, _lower_detail]
	if animated:
		for part in _result_parts:
			part.modulate.a = 0.0
	else:
		for part in _result_parts:
			part.modulate.a = 1.0


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
	var reroll := _button(_trf("GIEO_REROLL", VndWallet.format_vnd(-service.current_pull_cost())).replace(" · ", "\n"), "gold", Vector2(160, 62))
	reroll.add_theme_font_size_override("font_size", 15)
	reroll.disabled = not service.can_afford_pull()
	reroll.pressed.connect(cast.bind(true))
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
		_jackpot_flash()
		await _pause(0.35)
	for part in _result_parts:
		var tween := _tween()
		tween.tween_property(part, "modulate:a", 1.0, 0.12)
		await tween.finished
	if _decision_row != null:
		_decision_row.show()
		var buttons_tween := _tween()
		buttons_tween.tween_property(_decision_row, "modulate:a", 1.0, 0.18)
		await buttons_tween.finished
		_decision_row.mouse_filter = Control.MOUSE_FILTER_STOP


func _jackpot_flash() -> void:
	var cabinet := _stage.get_node("SlotMachineArt") as TextureRect
	var pulse := _tween()
	for _beat in 3:
		pulse.tween_property(cabinet,"modulate",Color(1.28,1.18,0.90),0.13)
		pulse.tween_property(cabinet,"modulate",Color.WHITE,0.22)
	for index in 12:
		var glint := Polygon2D.new()
		glint.polygon = PackedVector2Array([Vector2(0,-12),Vector2(2,-2),Vector2(9,0),Vector2(2,2),Vector2(0,12),Vector2(-2,2),Vector2(-9,0),Vector2(-2,-2)])
		glint.color = Color("ffe3a0")
		glint.position = Vector2(295 + (index % 4) * 135, 86 + (index / 4) * 188)
		glint.scale = Vector2.ZERO
		_stage.add_child(glint)
		var shine := _tween()
		shine.tween_interval(index * 0.045)
		shine.tween_property(glint,"scale",Vector2.ONE,0.12).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		shine.tween_property(glint,"scale",Vector2.ZERO,0.32)
		shine.tween_callback(glint.queue_free)


func _build_target_selection() -> void:
	var box := _build_flow_shell(tr("GIEO_CHOOSE_TARGET"))
	var cards := service.eligible_cards()
	var browse := _button(GameGlossary.words("Choose card", "Chọn bài"), "gold", Vector2(0, 54))
	browse.name = "OpenDeckPicker"
	browse.pressed.connect(_request_card_picker.bind(cards))
	box.add_child(browse)
	call_deferred("_request_card_picker", cards)


func _target_reason() -> String:
	return GameGlossary.words("This card will receive: ", "Lá được chọn sẽ nhận: ") + _effect_text() + "\n" + service.targeting_label()


func _request_card_picker(cards: Array[CardData]) -> void:
	if not is_inside_tree() or service.state != GieoQueService.STATE_TARGET_SELECTION: return
	card_pick_requested.emit(cards, _target_reason(), _on_target_pressed)


func _build_target_reveal() -> void:
	var box := _build_flow_shell(tr("GIEO_TARGETS_REVEALED"))
	_build_card_picker(box, service.resolved_targets, true, false)
	var seal := _label(tr("GIEO_SEALING"), 13, PresentationTheme.TEA, HORIZONTAL_ALIGNMENT_CENTER)
	box.add_child(seal)


func _build_transform() -> void:
	var box := _build_flow_shell(tr("GIEO_FATE_REWRITTEN"))
	var cards := _transformation_tray(box)
	for transformation in service.last_transformations:
		_build_transformation_row(cards, transformation)


func _build_complete() -> void:
	var box := _build_flow_shell(tr("GIEO_FATE_SEALED"))
	var cards := _transformation_tray(box)
	for transformation in service.last_transformations:
		_build_transformation_row(cards, transformation, false)
	var again := _button(_trf("GIEO_CAST_AGAIN", VndWallet.format_vnd(-service.current_pull_cost())), "gold", Vector2(0, 52))
	again.name = "CastAgain"
	again.position = Vector2(316, 449)
	again.size = Vector2(418, 60)
	again.disabled = not service.can_afford_pull()
	again.pressed.connect(cast.bind(false))
	_stage.add_child(again)


func _build_flow_shell(title_text: String) -> VBoxContainer:
	_build_machine(service.current_result.get("lines", []) as Array, false)
	_add_result_panel(false)
	for reel in _reels: (reel["panel"] as Control).hide()
	var tray := PanelContainer.new()
	tray.name = "MachineCardTray"
	tray.position = Vector2(291, 92)
	tray.size = Vector2(374, 328)
	tray.add_theme_stylebox_override("panel", PresentationTheme.panel_style(Color("#071522fa"), PresentationTheme.GOLD, 2, 10, 10))
	_stage.add_child(tray)
	var box := VBoxContainer.new()
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 9)
	tray.add_child(box)
	var title := _label(title_text, 19, PresentationTheme.GOLD, HORIZONTAL_ALIGNMENT_CENTER)
	title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(title)
	return box


func _transformation_tray(parent: VBoxContainer) -> HBoxContainer:
	var cards := HBoxContainer.new()
	cards.alignment = BoxContainer.ALIGNMENT_CENTER
	cards.add_theme_constant_override("separation", 12)
	parent.add_child(cards)
	return cards


func _effect_text() -> String:
	return service.effect_label()


func _build_transformation_row(parent: HBoxContainer, transformation: Dictionary, animated: bool = true) -> void:
	var row := VBoxContainer.new()
	row.name = "TransformationRow"
	row.set_meta("gieo_transform_row", true)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 5)
	parent.add_child(row)
	var before: Dictionary = transformation["before"]
	var after: Dictionary = transformation["after"]
	var snapshot := before if animated else after
	var card := CardData.from_permanent_snapshot(snapshot)
	var card_art := TextureRect.new()
	card_art.name = "SnapshotCardArt"
	card_art.custom_minimum_size = Vector2(128, 176) if service != null and service.last_transformations.size() == 1 else Vector2(96, 133)
	card_art.texture = load(card.texture_path()) as Texture2D
	GieoCardFX.apply_snapshot(card_art, snapshot)
	card_art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	card_art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	card_art.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	card_art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.set_meta("card_art", card_art)
	row.set_meta("before", before)
	row.set_meta("after", after)
	row.set_meta("card_texture_path", card.texture_path())
	row.add_child(card_art)
	var fortune := _label(card.fortune_label(), 29, PresentationTheme.GOLD, HORIZONTAL_ALIGNMENT_CENTER)
	fortune.set_meta("text_role", &"gain" if card.fortune >= 0 else &"cost")
	row.set_meta("fortune_label", fortune)
	row.add_child(fortune)
	var state_card := CardData.from_permanent_snapshot(after)
	var property := _label(tr(CardData.property_label_key(state_card.jackpot_state())), 12, PresentationTheme.ACTION, HORIZONTAL_ALIGNMENT_CENTER) if not state_card.jackpot_state().is_empty() else _label("", 12, Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER)
	property.custom_minimum_size = Vector2(96, 24)
	property.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	row.add_child(property)
	row.tooltip_text = state_card.inspection_text()


func _animate_transform() -> void:
	if not is_inside_tree() or service == null or service.state != GieoQueService.STATE_TRANSFORM:
		return
	await _pause(0.35)
	for row in _find_controls_with_meta(self, &"gieo_transform_row"):
		var face := row.get_meta("card_art") as TextureRect
		var after: Dictionary = row.get_meta("after")
		var before: Dictionary = row.get_meta("before")
		var fortune := row.get_meta("fortune_label") as Label
		GieoCardFX.apply_snapshot(face, after)
		var material := face.material as ShaderMaterial
		face.pivot_offset = face.size * 0.5
		var tween := _tween().set_parallel(true)
		if material != null:
			material.set_shader_parameter("previous_fortune", float(before.get("fortune", 0)))
			material.set_shader_parameter("transformation", 0.0)
			tween.tween_method(func(value: float): material.set_shader_parameter("transformation", value), 0.0, 1.0, 1.20).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		tween.tween_method(func(value: float): fortune.text = "%+d" % roundi(value), float(before.get("fortune", 0)), float(after.get("fortune", 0)), 1.20)
		tween.tween_property(face, "scale", Vector2(1.035, 1.035), 0.30).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		tween.chain().tween_property(face, "scale", Vector2.ONE, 0.24).set_trans(Tween.TRANS_SINE)
		impact_requested.emit(&"transform_card")
		await tween.finished
	await _pause(0.5)


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
		button.tooltip_text = card.inspection_text()
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
	_set_presentation_state(PresentationState.CHOOSING_RESULT_INPUT if service.state == GieoQueService.STATE_TARGET_SELECTION else PresentationState.RESOLVING_TRANSFORMATION)
	await _continue_committed_flow()
	_busy = false


func _continue_committed_flow() -> void:
	_rebuild()
	if service.state != GieoQueService.STATE_TARGET_REVEAL:
		return
	await _pause(0.62)
	var result := service.apply_resolved_targets()
	if not result.get("ok", false):
		feedback_requested.emit(String(result.get("message", "Transformation failed.")))
		return
	impact_requested.emit(&"transform")
	_rebuild()
	await _finish_transform_presentation()


func _resume_committed_flow() -> void:
	_busy = true
	if service.state == GieoQueService.STATE_TRANSFORM:
		await _finish_transform_presentation()
	else:
		await _continue_committed_flow()
	_busy = false


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
