class_name EventTableController
extends Control

signal npc_focused(npc_id: String)
signal focus_cleared()
signal deal_presentation_ready()

const TABLE_STATE_DEAL := &"deal"
const TABLE_STATE_EVENT := &"event"
const TRANSITION_SECONDS := 0.34

const NPC_DANH_GIAY := "danh_giay"
const NPC_TRA_DA := "tra_da_auntie"
const NPC_THAY_BOI := "thay_boi"
const NPC_HANG_RONG := "hang_rong"
const NPC_LOTTO := "lotto"

const EVENT_ROSTERS := {
	0: [NPC_DANH_GIAY, NPC_TRA_DA],
	1: [NPC_THAY_BOI, NPC_HANG_RONG, NPC_LOTTO],
	2: [NPC_THAY_BOI, NPC_TRA_DA],
	3: [NPC_THAY_BOI, NPC_HANG_RONG, NPC_LOTTO],
}
const NPC_DATA := {
	NPC_DANH_GIAY: {
		"name": "ĐÁNH GIÀY",
		"slot": &"left",
		"overlay": preload("res://assets/environment/npcs/danhgiay_overlay.png"),
		"sprite": preload("res://assets/environment/npcs/danhgiay.png"),
	},
	NPC_TRA_DA: {
		"name": "CÔ TRÀ ĐÁ",
		"slot": &"right",
		"overlay": preload("res://assets/environment/npcs/trada_overlay.png"),
		"sprite": preload("res://assets/environment/npcs/trada.png"),
	},
	NPC_THAY_BOI: {
		"name": "THẦY BÓI",
		"slot": &"left",
		"overlay": preload("res://assets/environment/npcs/thayboi_overlay.png"),
		"sprite": preload("res://assets/environment/npcs/thayboi.png"),
	},
	NPC_HANG_RONG: {
		"name": "HÀNG RONG",
		"slot": &"right",
		"overlay": preload("res://assets/environment/npcs/hangrong_overlay.png"),
		"sprite": preload("res://assets/environment/npcs/hangrong.png"),
	},
	NPC_LOTTO: {
		"name": "VÉ SỐ",
		"slot": &"top",
		"overlay": preload("res://assets/environment/npcs/lode_overlay.png"),
		"sprite": preload("res://assets/environment/npcs/lode.png"),
	},
}

var table_state: StringName = TABLE_STATE_DEAL
var focused_npc_id: String = ""
var current_event_slot: int = -1
var day_label: Label
var period_label: Label
var money_label: Label
var participants_container: VBoxContainer
var continue_button: Button
var back_button: Button
var content_panel: PanelContainer

var _deal_nodes: Array[Control] = []
var _deal_home: Dictionary = {}
var _npc_layers: Dictionary = {}
var _transition: Tween
var _money_pulse: Tween


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	z_index = 190
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_build_markers()
	_build_header()
	_build_content()
	_build_continue()
	_build_npc_layers()
	visible = false


func configure_deal_nodes(nodes: Array[Control]) -> void:
	_deal_nodes = nodes
	_deal_home.clear()
	for node in _deal_nodes:
		if node == null:
			continue
		_deal_home[node] = {
			"position": node.position,
			"scale": node.scale,
			"modulate": node.modulate,
		}


func enter_event(event_slot: int, day_text: String, period_text: String, money_text: String) -> void:
	var already_showing := table_state == TABLE_STATE_EVENT and visible
	current_event_slot = event_slot
	day_label.text = day_text.to_upper()
	period_label.text = period_text.to_upper()
	money_label.text = money_text
	continue_button.text = "TIẾP TỤC"
	if already_showing:
		return
	table_state = TABLE_STATE_EVENT
	focused_npc_id = ""
	visible = true
	modulate = Color.WHITE
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_clear_content()
	_set_header_focused(false, false)
	_show_roster(event_slot)
	_animate_deal_out()
	_animate_npcs_in()
	_start_money_pulse()


func enter_deal() -> void:
	if table_state == TABLE_STATE_DEAL and not visible:
		deal_presentation_ready.emit()
		return
	table_state = TABLE_STATE_DEAL
	_stop_money_pulse()
	_clear_content()
	focused_npc_id = ""
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	for npc_id in _npc_layers:
		var layer: Dictionary = _npc_layers[npc_id]
		(layer["button"] as Button).disabled = true
	if _transition != null and _transition.is_valid():
		_transition.kill()
	_transition = create_tween().set_parallel(true)
	_transition.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	for npc_id in _npc_layers:
		var layer: Dictionary = _npc_layers[npc_id]
		var overlay := layer["overlay"] as TextureRect
		if not overlay.visible:
			continue
		_transition.tween_property(overlay, "position", _overlay_out_offset(StringName(layer["slot"])), TRANSITION_SECONDS)
		_transition.tween_property(overlay, "modulate:a", 0.0, TRANSITION_SECONDS * 0.8)
	_transition.tween_property(self, "modulate:a", 0.0, TRANSITION_SECONDS)
	_transition.chain().tween_callback(_finish_event_exit)


func set_continue_enabled(enabled: bool) -> void:
	continue_button.disabled = not enabled


func focus_npc(npc_id: String) -> void:
	if table_state != TABLE_STATE_EVENT or not _npc_layers.has(npc_id) or focused_npc_id == npc_id:
		return
	focused_npc_id = npc_id
	_set_header_focused(true)
	content_panel.visible = true
	back_button.visible = true
	var tween := create_tween().set_parallel(true)
	tween.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	for candidate_id in _npc_layers:
		var layer: Dictionary = _npc_layers[candidate_id]
		var overlay := layer["overlay"] as TextureRect
		var button := layer["button"] as Button
		var name_tag := layer["name_tag"] as Label
		var sprite := layer["sprite"] as TextureRect
		button.disabled = true
		name_tag.visible = candidate_id == npc_id
		if candidate_id == npc_id:
			tween.tween_property(overlay, "modulate:a", 0.0, 0.18)
			sprite.visible = true
			sprite.modulate.a = 0.0
			sprite.position = _sprite_out_position(StringName(layer["slot"]), sprite.size)
			tween.tween_property(sprite, "position", _sprite_focus_position(StringName(layer["slot"]), sprite.size), TRANSITION_SECONDS)
			tween.tween_property(sprite, "modulate:a", 1.0, 0.2)
		elif overlay.visible:
			tween.tween_property(overlay, "modulate", Color(0.42, 0.46, 0.5, 0.38), 0.22)
	npc_focused.emit(npc_id)


func unfocus_npc() -> void:
	if focused_npc_id.is_empty():
		return
	var previous := focused_npc_id
	focused_npc_id = ""
	_clear_content()
	_set_header_focused(false)
	var tween := create_tween().set_parallel(true)
	tween.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	for npc_id in _npc_layers:
		var layer: Dictionary = _npc_layers[npc_id]
		var overlay := layer["overlay"] as TextureRect
		var button := layer["button"] as Button
		var name_tag := layer["name_tag"] as Label
		var sprite := layer["sprite"] as TextureRect
		name_tag.visible = false
		if npc_id == previous and sprite.visible:
			tween.tween_property(sprite, "position", _sprite_out_position(StringName(layer["slot"]), sprite.size), TRANSITION_SECONDS)
			tween.tween_property(sprite, "modulate:a", 0.0, 0.18)
			tween.chain().tween_callback(func() -> void: sprite.visible = false)
		if overlay.visible:
			tween.tween_property(overlay, "modulate", Color.WHITE, 0.24)
			button.disabled = false
	focus_cleared.emit()


func event_money_feedback(value_text: String) -> void:
	money_label.text = value_text
	var pulse := create_tween()
	pulse.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	pulse.tween_property(money_label, "scale", Vector2(1.12, 1.12), 0.12)
	pulse.tween_property(money_label, "scale", Vector2.ONE, 0.18)


func show_outcome(kicker: String, title: String, wallet_text: String) -> void:
	table_state = TABLE_STATE_EVENT
	current_event_slot = -1
	focused_npc_id = ""
	visible = true
	modulate = Color.WHITE
	_hide_all_npcs()
	_clear_content()
	period_label.text = kicker
	day_label.text = title
	money_label.text = wallet_text
	_set_header_focused(false, false)
	content_panel.visible = true
	back_button.visible = false
	_animate_deal_out()
	_stop_money_pulse()


func clear_content() -> void:
	_clear_content()


func npc_display_name(npc_id: String) -> String:
	if not NPC_DATA.has(npc_id):
		return npc_id
	return String((NPC_DATA[npc_id] as Dictionary)["name"])


func _build_markers() -> void:
	var specs := {
		"NPC_Left_Rest": Vector2(0, 0),
		"NPC_Left_Focus": Vector2(20, 70),
		"NPC_Right_Rest": Vector2(0, 0),
		"NPC_Right_Focus": Vector2(820, 70),
		"NPC_Top_Rest": Vector2(0, 0),
		"NPC_Top_Focus": Vector2(390, -25),
		"EventHeader_Center": Vector2(640, 280),
		"EventHeader_Top": Vector2(640, 78),
		"EventTableContentAnchor": Vector2(640, 390),
	}
	var marker_root := Node2D.new()
	marker_root.name = "PositionMarkers"
	add_child(marker_root)
	for marker_name in specs:
		var marker := Marker2D.new()
		marker.name = marker_name
		marker.position = specs[marker_name]
		marker_root.add_child(marker)


func _build_header() -> void:
	var header := Control.new()
	header.name = "EventHeader"
	header.size = Vector2(520, 180)
	header.pivot_offset = header.size * 0.5
	header.position = Vector2(380, 190)
	header.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(header)
	period_label = Label.new()
	period_label.name = "EventPeriod"
	period_label.position = Vector2(0, 4)
	period_label.size = Vector2(520, 30)
	period_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	period_label.add_theme_font_size_override("font_size", 18)
	period_label.add_theme_color_override("font_color", Color("#e8d6a1"))
	period_label.set_meta("match_binding", "campaign_event_kicker")
	header.add_child(period_label)
	day_label = Label.new()
	day_label.name = "EventDay"
	day_label.position = Vector2(0, 34)
	day_label.size = Vector2(520, 38)
	day_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	day_label.add_theme_font_size_override("font_size", 25)
	day_label.add_theme_color_override("font_color", Color("#fff1c6"))
	day_label.set_meta("match_binding", "campaign_event_title")
	header.add_child(day_label)
	money_label = Label.new()
	money_label.name = "EventMoney"
	money_label.position = Vector2(0, 82)
	money_label.size = Vector2(520, 68)
	money_label.pivot_offset = money_label.size * 0.5
	money_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	money_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	money_label.add_theme_font_size_override("font_size", 43)
	money_label.add_theme_color_override("font_color", Color("#f6c442"))
	money_label.add_theme_color_override("font_shadow_color", Color(0.02, 0.03, 0.05, 0.75))
	money_label.add_theme_constant_override("shadow_offset_x", 3)
	money_label.add_theme_constant_override("shadow_offset_y", 4)
	money_label.set_meta("match_binding", "campaign_event_wallet")
	header.add_child(money_label)


func _build_content() -> void:
	content_panel = PanelContainer.new()
	content_panel.name = "EventTableContent"
	content_panel.position = Vector2(350, 205)
	content_panel.size = Vector2(580, 360)
	content_panel.visible = false
	content_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.025, 0.075, 0.11, 0.82)
	style.border_color = Color(0.94, 0.73, 0.25, 0.78)
	style.set_border_width_all(2)
	style.set_corner_radius_all(12)
	style.content_margin_left = 22
	style.content_margin_top = 18
	style.content_margin_right = 22
	style.content_margin_bottom = 18
	content_panel.add_theme_stylebox_override("panel", style)
	add_child(content_panel)
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 16)
	margin.add_theme_constant_override("margin_top", 14)
	margin.add_theme_constant_override("margin_right", 16)
	margin.add_theme_constant_override("margin_bottom", 14)
	content_panel.add_child(margin)
	participants_container = VBoxContainer.new()
	participants_container.name = "EventTableContentItems"
	participants_container.add_theme_constant_override("separation", 10)
	participants_container.set_meta("match_binding", "campaign_participants")
	margin.add_child(participants_container)
	back_button = Button.new()
	back_button.name = "EventBack"
	back_button.text = "← TRỞ LẠI"
	back_button.position = Vector2(24, 90)
	back_button.size = Vector2(132, 42)
	back_button.visible = false
	back_button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	back_button.pressed.connect(unfocus_npc)
	add_child(back_button)


func _build_continue() -> void:
	continue_button = Button.new()
	continue_button.name = "EventContinue"
	continue_button.text = "TIẾP TỤC"
	continue_button.position = Vector2(520, 642)
	continue_button.size = Vector2(240, 54)
	continue_button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	continue_button.set_meta("match_binding", "campaign_continue_button")
	add_child(continue_button)


func _build_npc_layers() -> void:
	for npc_id in NPC_DATA:
		var data: Dictionary = NPC_DATA[npc_id]
		var slot := StringName(data["slot"])
		var overlay := TextureRect.new()
		overlay.name = "%sOverlay" % npc_id.to_pascal_case()
		overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		overlay.texture = data["overlay"]
		overlay.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		overlay.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		overlay.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
		overlay.visible = false
		add_child(overlay)
		move_child(overlay, 1)
		var sprite_texture := data["sprite"] as Texture2D
		var sprite := TextureRect.new()
		sprite.name = "%sFocused" % npc_id.to_pascal_case()
		var target_height := 650.0 if slot != &"top" else 590.0
		var ratio := target_height / sprite_texture.get_height()
		sprite.size = sprite_texture.get_size() * ratio
		sprite.texture = sprite_texture
		sprite.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		sprite.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		sprite.mouse_filter = Control.MOUSE_FILTER_IGNORE
		sprite.visible = false
		add_child(sprite)
		move_child(sprite, 2)
		var button := Button.new()
		button.name = "%sSelect" % npc_id.to_pascal_case()
		button.flat = true
		button.focus_mode = Control.FOCUS_NONE
		button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		button.position = _slot_hit_rect(slot).position
		button.size = _slot_hit_rect(slot).size
		button.visible = false
		button.pressed.connect(focus_npc.bind(npc_id))
		add_child(button)
		var name_tag := Label.new()
		name_tag.name = "%sName" % npc_id.to_pascal_case()
		name_tag.text = String(data["name"])
		name_tag.position = _slot_name_position(slot)
		name_tag.size = Vector2(210, 34)
		name_tag.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		name_tag.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		name_tag.add_theme_font_size_override("font_size", 14)
		name_tag.add_theme_color_override("font_color", Color("#fff0bd"))
		name_tag.visible = false
		name_tag.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(name_tag)
		button.mouse_entered.connect(func() -> void: if focused_npc_id.is_empty(): name_tag.visible = true)
		button.mouse_exited.connect(func() -> void: if focused_npc_id.is_empty(): name_tag.visible = false)
		_npc_layers[npc_id] = {
			"slot": slot,
			"overlay": overlay,
			"sprite": sprite,
			"button": button,
			"name_tag": name_tag,
		}


func _show_roster(event_slot: int) -> void:
	_hide_all_npcs()
	for npc_id in EVENT_ROSTERS.get(event_slot, []):
		var layer: Dictionary = _npc_layers[npc_id]
		var overlay := layer["overlay"] as TextureRect
		var button := layer["button"] as Button
		overlay.visible = true
		overlay.modulate = Color.WHITE
		overlay.position = _overlay_out_offset(StringName(layer["slot"]))
		button.visible = true
		button.disabled = true


func _hide_all_npcs() -> void:
	for npc_id in _npc_layers:
		var layer: Dictionary = _npc_layers[npc_id]
		(layer["overlay"] as TextureRect).visible = false
		(layer["sprite"] as TextureRect).visible = false
		(layer["button"] as Button).visible = false
		(layer["name_tag"] as Label).visible = false


func _animate_npcs_in() -> void:
	var tween := create_tween().set_parallel(true)
	tween.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	for npc_id in _npc_layers:
		var layer: Dictionary = _npc_layers[npc_id]
		var overlay := layer["overlay"] as TextureRect
		if not overlay.visible:
			continue
		tween.tween_property(overlay, "position", Vector2.ZERO, TRANSITION_SECONDS)
	tween.chain().tween_callback(_enable_roster_buttons)


func _enable_roster_buttons() -> void:
	if table_state != TABLE_STATE_EVENT or not focused_npc_id.is_empty():
		return
	for npc_id in _npc_layers:
		var layer: Dictionary = _npc_layers[npc_id]
		var button := layer["button"] as Button
		button.disabled = not (layer["overlay"] as TextureRect).visible


func _animate_deal_out() -> void:
	if _transition != null and _transition.is_valid():
		_transition.kill()
	_transition = create_tween().set_parallel(true)
	_transition.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	for node in _deal_nodes:
		if node == null or not _deal_home.has(node):
			continue
		node.visible = true
		var home: Dictionary = _deal_home[node]
		var target := Vector2(home["position"]) + _deal_exit_offset(node.name)
		_transition.tween_property(node, "position", target, TRANSITION_SECONDS)
		_transition.tween_property(node, "modulate:a", 0.0, TRANSITION_SECONDS * 0.78)
	_transition.chain().tween_callback(_finish_deal_exit)


func _finish_deal_exit() -> void:
	if table_state != TABLE_STATE_EVENT:
		return
	for node in _deal_nodes:
		if node != null:
			node.visible = false


func _finish_event_exit() -> void:
	if table_state != TABLE_STATE_DEAL:
		return
	visible = false
	modulate = Color.WHITE
	_hide_all_npcs()
	for node in _deal_nodes:
		if node == null or not _deal_home.has(node):
			continue
		var home: Dictionary = _deal_home[node]
		node.visible = true
		node.position = Vector2(home["position"]) + _deal_exit_offset(node.name)
		node.scale = Vector2(home["scale"])
		node.modulate = Color(home["modulate"])
		node.modulate.a = 0.0
	var tween := create_tween().set_parallel(true)
	tween.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	for node in _deal_nodes:
		if node == null or not _deal_home.has(node):
			continue
		var home: Dictionary = _deal_home[node]
		tween.tween_property(node, "position", Vector2(home["position"]), TRANSITION_SECONDS)
		tween.tween_property(node, "modulate", Color(home["modulate"]), TRANSITION_SECONDS)
	tween.chain().tween_callback(func() -> void: deal_presentation_ready.emit())


func _set_header_focused(focused: bool, animate: bool = true) -> void:
	var header := day_label.get_parent() as Control
	var target_position := Vector2(380, -2) if focused else Vector2(380, 190)
	var target_scale := Vector2(0.78, 0.78) if focused else Vector2.ONE
	if not animate:
		header.position = target_position
		header.scale = target_scale
		return
	var tween := create_tween().set_parallel(true)
	tween.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(header, "position", target_position, 0.28)
	tween.tween_property(header, "scale", target_scale, 0.28)


func _clear_content() -> void:
	content_panel.visible = false
	back_button.visible = false
	for child in participants_container.get_children():
		participants_container.remove_child(child)
		child.queue_free()


func _start_money_pulse() -> void:
	_stop_money_pulse()
	money_label.scale = Vector2.ONE
	_money_pulse = create_tween().set_loops()
	_money_pulse.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_money_pulse.tween_property(money_label, "scale", Vector2(1.035, 1.035), 0.55)
	_money_pulse.tween_property(money_label, "scale", Vector2.ONE, 0.55)
	_money_pulse.tween_interval(0.45)


func _stop_money_pulse() -> void:
	if _money_pulse != null and _money_pulse.is_valid():
		_money_pulse.kill()
	money_label.scale = Vector2.ONE


func _slot_hit_rect(slot: StringName) -> Rect2:
	match slot:
		&"left":
			return Rect2(0, 72, 280, 570)
		&"right":
			return Rect2(1000, 72, 280, 570)
		_:
			return Rect2(430, 0, 420, 190)


func _slot_name_position(slot: StringName) -> Vector2:
	match slot:
		&"left":
			return Vector2(22, 612)
		&"right":
			return Vector2(1048, 612)
		_:
			return Vector2(535, 18)


func _overlay_out_offset(slot: StringName) -> Vector2:
	match slot:
		&"left":
			return Vector2(-90, 0)
		&"right":
			return Vector2(90, 0)
		_:
			return Vector2(0, -90)


func _sprite_focus_position(slot: StringName, sprite_size: Vector2) -> Vector2:
	match slot:
		&"left":
			return Vector2(-sprite_size.x * 0.10, 70)
		&"right":
			return Vector2(1280 - sprite_size.x * 0.90, 70)
		_:
			return Vector2(640 - sprite_size.x * 0.5, -55)


func _sprite_out_position(slot: StringName, sprite_size: Vector2) -> Vector2:
	var focus := _sprite_focus_position(slot, sprite_size)
	match slot:
		&"left":
			return focus + Vector2(-180, 35)
		&"right":
			return focus + Vector2(180, 35)
		_:
			return focus + Vector2(0, -180)


func _deal_exit_offset(node_name: String) -> Vector2:
	match node_name:
		"Header":
			return Vector2(0, -100)
		"TableSurface":
			return Vector2(0, -170)
		"LooseHand":
			return Vector2(0, 250)
		"UtilityRail":
			return Vector2(180, 0)
		"ActionDock":
			return Vector2(0, 110)
	return Vector2(0, 90)
