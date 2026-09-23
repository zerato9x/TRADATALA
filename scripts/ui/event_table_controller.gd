class_name EventTableController
extends Control

signal npc_focused(npc_id: String)
signal focus_cleared()
signal deal_presentation_ready()
signal deck_inspect_requested()
signal cash_clicked()
signal menu_requested()

const TABLE_STATE_DEAL := &"deal"
const TABLE_STATE_EVENT := &"event"
const TRANSITION_SECONDS := 0.34
const EVENT_DECK_REST_POSITION := Vector2(292, 446)
const EVENT_DECK_FOCUS_POSITION := Vector2(72, 272)

const NPC_DANH_GIAY := "danh_giay"
const NPC_TRA_DA := "tra_da_auntie"
const NPC_THAY_BOI := "thay_boi"
const NPC_HANG_RONG := "hang_rong"
const NPC_LOTTO := "lotto"
const NPC_DOI_NO := "doi_no"

# Dialogue and service share a column beside the full focused character.
const MISC_SERVICE_RECTS := {
	NPC_DANH_GIAY: Rect2(460, 284, 700, 400),
	NPC_LOTTO: Rect2(145, 284, 700, 400),
}

const EVENT_ROSTERS := {
	0: [NPC_DANH_GIAY, NPC_TRA_DA],
	1: [NPC_THAY_BOI, NPC_HANG_RONG, NPC_LOTTO],
	2: [NPC_THAY_BOI, NPC_TRA_DA],
	3: [NPC_THAY_BOI, NPC_HANG_RONG, NPC_LOTTO],
}
const NPC_DATA := {
	NPC_DOI_NO: {
		"name_key": "NPC_DOI_NO", "slot": &"top_right",
		"overlay": preload("res://assets/environment/npcs/doino.png"),
		"sprite": preload("res://assets/environment/npcs/doino.png"),
	},
	NPC_DANH_GIAY: {
		"name_key": "NPC_DANH_GIAY",
		"slot": &"left",
		"overlay": preload("res://assets/environment/npcs/danhgiay_overlay.png"),
		"sprite": preload("res://assets/environment/npcs/danhgiay.png"),
	},
	NPC_TRA_DA: {
		"name_key": "NPC_TRA_DA_AUNTIE",
		"slot": &"right",
		"overlay": preload("res://assets/environment/npcs/trada_overlay.png"),
		"sprite": preload("res://assets/environment/npcs/trada.png"),
	},
	NPC_THAY_BOI: {
		"name_key": "NPC_THAY_BOI",
		"slot": &"left",
		"overlay": preload("res://assets/environment/npcs/thayboi_overlay.png"),
		"sprite": preload("res://assets/environment/npcs/thayboi.png"),
	},
	NPC_HANG_RONG: {
		"name_key": "NPC_HANG_RONG",
		"slot": &"right",
		"overlay": preload("res://assets/environment/npcs/hangrong_overlay.png"),
		"sprite": preload("res://assets/environment/npcs/hangrong.png"),
	},
	NPC_LOTTO: {
		"name_key": "NPC_LOTTO",
		"slot": &"top_right",
		"overlay": preload("res://assets/environment/npcs/lode_overlay.png"),
		"sprite": preload("res://assets/environment/npcs/lode.png"),
	},
}

var table_state: StringName = TABLE_STATE_DEAL
var focused_npc_id: String = ""
var deck_focused: bool = false
var current_event_slot: int = -1
var day_label: Label
var period_label: Label
var money_label: Label
var money_row: HBoxContainer
var participants_container: VBoxContainer
var continue_button: Button
var back_button: Button
var content_panel: PanelContainer
var conversation: NpcConversation
var event_deck: Control
var event_deck_count: Label
var overview: Control

var _deal_nodes: Array[Control] = []
var _deal_home: Dictionary = {}
var _npc_layers: Dictionary = {}
var _transition: Tween
var _money_pulse: Tween
var _focus_motion: Tween
var _header_motion: Tween
var collector_arrival: Control
var menu_button: Button


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	z_index = 190
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_build_markers()
	_build_header()
	_build_content()
	_build_continue()
	_build_event_deck()
	_build_npc_layers()
	overview = preload("res://scripts/ui/event_table_overview.gd").new()
	overview.name = "EventTableOverview"
	add_child(overview)
	overview.cash_clicked.connect(func() -> void: cash_clicked.emit())
	conversation = preload("res://scenes/ui/npc_conversation.tscn").instantiate()
	add_child(conversation)
	conversation.position = Vector2(165, 140)
	conversation.size = Vector2(710, 124)
	conversation.visible = false
	conversation.response_selected.connect(_on_conversation_response)
	collector_arrival = preload("res://scripts/ui/debt_collector_arrival.gd").new()
	add_child(collector_arrival)
	menu_button = Button.new()
	menu_button.name = "EventMenu"
	menu_button.position = Vector2(16, 12)
	menu_button.size = Vector2(96, 42)
	menu_button.text = tr("HUD_MENU")
	menu_button.pressed.connect(func(): menu_requested.emit())
	add_child(menu_button)
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


func enter_event(event_slot: int, day_text: String, period_text: String, money_text: String, deck_count: int = 0) -> void:
	var already_showing := table_state == TABLE_STATE_EVENT and visible and current_event_slot == event_slot
	current_event_slot = event_slot
	day_label.text = day_text.to_upper()
	period_label.text = period_text.to_upper()
	money_label.text = money_text
	set_event_deck_count(deck_count)
	event_deck.visible = true
	event_deck.position = EVENT_DECK_REST_POSITION
	event_deck.scale = Vector2.ONE
	event_deck.modulate = Color.WHITE
	continue_button.text = tr("EVENT_CONTINUE")
	continue_button.visible = not already_showing or (focused_npc_id.is_empty() and not deck_focused)
	if already_showing:
		return
	table_state = TABLE_STATE_EVENT
	focused_npc_id = ""
	deck_focused = false
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
	collector_arrival.stop()
	if _focus_motion != null: _focus_motion.kill()
	if table_state == TABLE_STATE_DEAL and not visible:
		deal_presentation_ready.emit()
		return
	table_state = TABLE_STATE_DEAL
	_stop_money_pulse()
	_clear_content()
	focused_npc_id = ""
	deck_focused = false
	event_deck.visible = false
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	for npc_id in _npc_layers:
		var layer: Dictionary = _npc_layers[npc_id]
		var button := layer["button"] as Button
		button.disabled = true
		button.mouse_filter = Control.MOUSE_FILTER_IGNORE
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


func refresh_localized_ui() -> void:
	continue_button.text = tr("EVENT_CONTINUE")
	back_button.text = tr("EVENT_BACK")
	if menu_button != null: menu_button.text = tr("HUD_MENU")
	for npc_id in _npc_layers:
		var layer: Dictionary = _npc_layers[npc_id]
		(layer["name_tag"] as Label).text = npc_display_name(String(npc_id))


func focus_npc(npc_id: String) -> void:
	if DemoBuild.enabled() and npc_id not in [NPC_TRA_DA, NPC_DOI_NO]:
		return
	if table_state != TABLE_STATE_EVENT or not _npc_layers.has(npc_id) or focused_npc_id == npc_id:
		return
	collector_arrival.stop()
	focused_npc_id = npc_id
	continue_button.hide()
	deck_focused = false
	_set_header_focused(true)
	content_panel.visible = true
	event_deck.visible = false
	back_button.visible = true
	back_button.text = tr("EVENT_BACK")
	if _focus_motion != null: _focus_motion.kill()
	_focus_motion = create_tween().set_parallel(true)
	var tween := _focus_motion
	tween.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	for candidate_id in _npc_layers:
		var layer: Dictionary = _npc_layers[candidate_id]
		var overlay := layer["overlay"] as TextureRect
		var button := layer["button"] as Button
		var name_tag := layer["name_tag"] as Label
		var sprite := layer["sprite"] as TextureRect
		button.disabled = true
		button.mouse_filter = Control.MOUSE_FILTER_IGNORE
		name_tag.visible = candidate_id == npc_id and npc_id not in [NPC_THAY_BOI, NPC_DANH_GIAY, NPC_LOTTO, NPC_DOI_NO]
		if candidate_id == npc_id:
			tween.tween_property(overlay, "modulate:a", 0.0, 0.18)
			sprite.visible = true
			sprite.modulate.a = 0.0
			sprite.position = _sprite_out_position(StringName(layer["slot"]), sprite.size)
			var focus_position := Vector2(0, 95) if npc_id == NPC_THAY_BOI else Vector2(855, 140) if npc_id == NPC_DOI_NO else _sprite_focus_position(StringName(layer["slot"]), sprite.size)
			if npc_id == NPC_DOI_NO:
				sprite.position = focus_position
			else:
				tween.tween_property(sprite, "position", focus_position, TRANSITION_SECONDS)
				tween.tween_property(sprite, "modulate:a", 1.0, 0.2)
		else:
			sprite.hide()
		if candidate_id != npc_id and overlay.visible:
			tween.tween_property(overlay, "modulate", Color(0.42, 0.46, 0.5, 0.38), 0.22)
	npc_focused.emit(npc_id)
	if npc_id == NPC_DOI_NO:
		collector_arrival.play(_npc_layers[npc_id].sprite)


func focus_deck() -> void:
	if table_state != TABLE_STATE_EVENT or deck_focused or not focused_npc_id.is_empty():
		return
	collector_arrival.stop()
	deck_focused = true
	continue_button.hide()
	_set_header_focused(true)
	content_panel.visible = true
	back_button.visible = true
	back_button.text = tr("EVENT_BACK")
	if _focus_motion != null: _focus_motion.kill()
	_focus_motion = create_tween().set_parallel(true)
	var tween := _focus_motion
	tween.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(event_deck, "position", EVENT_DECK_FOCUS_POSITION, TRANSITION_SECONDS)
	tween.tween_property(event_deck, "scale", Vector2(1.18, 1.18), TRANSITION_SECONDS)
	for npc_id in _npc_layers:
		var layer: Dictionary = _npc_layers[npc_id]
		var overlay := layer["overlay"] as TextureRect
		var button := layer["button"] as Button
		button.disabled = true
		button.mouse_filter = Control.MOUSE_FILTER_IGNORE
		if overlay.visible:
			tween.tween_property(overlay, "modulate", Color(0.42, 0.46, 0.5, 0.38), 0.22)
	deck_inspect_requested.emit()


func unfocus_npc() -> void:
	if back_button.disabled:
		return
	if focused_npc_id.is_empty() and not deck_focused:
		return
	collector_arrival.stop()
	var previous := focused_npc_id
	var was_deck_focused := deck_focused
	focused_npc_id = ""
	deck_focused = false
	continue_button.visible = true
	event_deck.visible = true
	_clear_content()
	_set_header_focused(false)
	if _focus_motion != null: _focus_motion.kill()
	_focus_motion = create_tween().set_parallel(true)
	var tween := _focus_motion
	tween.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	if was_deck_focused:
		tween.tween_property(event_deck, "position", EVENT_DECK_REST_POSITION, TRANSITION_SECONDS)
		tween.tween_property(event_deck, "scale", Vector2.ONE, TRANSITION_SECONDS)
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
			button.mouse_filter = Control.MOUSE_FILTER_STOP
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
	deck_focused = false
	visible = true
	event_deck.visible = false
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
	overview.hide()


func clear_content() -> void:
	_clear_content()


func npc_display_name(npc_id: String) -> String:
	if not NPC_DATA.has(npc_id):
		return npc_id
	return tr(String((NPC_DATA[npc_id] as Dictionary)["name_key"]))


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
	money_row = HBoxContainer.new()
	money_row.name = "EventMoneyRow"
	money_row.position = Vector2(0, 82)
	money_row.size = Vector2(520, 68)
	money_row.alignment = BoxContainer.ALIGNMENT_CENTER
	money_row.add_theme_constant_override("separation", 10)
	money_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	header.add_child(money_row)
	money_label = Label.new()
	money_label.name = "EventMoney"
	money_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	money_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	money_label.add_theme_font_size_override("font_size", 43)
	money_label.add_theme_color_override("font_color", Color("#f6c442"))
	money_label.add_theme_color_override("font_shadow_color", Color(0.02, 0.03, 0.05, 0.75))
	money_label.add_theme_constant_override("shadow_offset_x", 3)
	money_label.add_theme_constant_override("shadow_offset_y", 4)
	money_label.set_meta("match_binding", "campaign_event_wallet")
	money_row.add_child(money_label)
	var unit := Label.new()
	unit.name = "CurrencyUnit"
	unit.text = "VNĐ"
	unit.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	unit.mouse_filter = Control.MOUSE_FILTER_IGNORE
	PresentationTheme.style_text(unit, &"muted", 18)
	money_row.add_child(unit)
	money_label.show()


func _build_content() -> void:
	content_panel = PanelContainer.new()
	content_panel.name = "EventTableContent"
	content_panel.position = Vector2(350, 205)
	content_panel.size = Vector2(580, 360)
	content_panel.visible = false
	content_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	var style := PresentationTheme.panel_style(Color("#19130ff0"), Color("#8d5b30"), 2, 2, 4)
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
	back_button.text = tr("EVENT_BACK")
	if menu_button != null: menu_button.text = tr("HUD_MENU")
	back_button.position = Vector2(24, 90)
	back_button.size = Vector2(132, 42)
	back_button.visible = false
	back_button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	back_button.pressed.connect(unfocus_npc)
	add_child(back_button)


func _build_continue() -> void:
	continue_button = Button.new()
	continue_button.name = "EventContinue"
	continue_button.text = tr("EVENT_CONTINUE")
	continue_button.position = Vector2(520, 642)
	continue_button.size = Vector2(240, 54)
	continue_button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	continue_button.set_meta("match_binding", "campaign_continue_button")
	add_child(continue_button)


func _build_event_deck() -> void:
	event_deck = Control.new()
	event_deck.name = "EventDeck"
	event_deck.position = EVENT_DECK_REST_POSITION
	event_deck.size = Vector2(112, 174)
	event_deck.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	add_child(event_deck)
	var back := TextureRect.new()
	back.position = Vector2(13, 4)
	back.size = Vector2(86, 119)
	back.texture = preload("res://cards/red_backing.png")
	back.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	back.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	back.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	back.mouse_filter = Control.MOUSE_FILTER_IGNORE
	event_deck.add_child(back)
	event_deck_count = Label.new()
	event_deck_count.position = Vector2(0, 126)
	event_deck_count.size = Vector2(112, 42)
	event_deck_count.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	event_deck_count.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	event_deck_count.add_theme_font_size_override("font_size", 13)
	event_deck_count.add_theme_color_override("font_color", Color("#fff0bd"))
	event_deck_count.mouse_filter = Control.MOUSE_FILTER_IGNORE
	event_deck.add_child(event_deck_count)
	var inspect := Button.new()
	inspect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	inspect.flat = true
	inspect.focus_mode = Control.FOCUS_NONE
	inspect.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	inspect.tooltip_text = tr("PILE_DRAW_TOOLTIP")
	inspect.pressed.connect(focus_deck)
	event_deck.add_child(inspect)


func set_event_deck_count(count: int) -> void:
	if event_deck_count != null:
		event_deck_count.text = "%s\n%s" % [tr("PILE_COUNT") % count, tr("PILE_DRAW")]


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
		var target_height := 650.0 if slot != &"top_right" else 590.0
		if npc_id == NPC_THAY_BOI:
			target_height = 600.0
		var ratio := target_height / sprite_texture.get_height()
		sprite.size = sprite_texture.get_size() * ratio
		sprite.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		sprite.texture = sprite_texture
		sprite.size = sprite_texture.get_size() * ratio
		if npc_id == NPC_DOI_NO: sprite.size = Vector2(420, 545)
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
		name_tag.text = npc_display_name(npc_id)
		name_tag.position = _slot_name_position(slot)
		if npc_id == NPC_DOI_NO: name_tag.position = Vector2(785, 345)
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
	var roster: Array = [NPC_TRA_DA] if DemoBuild.enabled() else EVENT_ROSTERS.get(event_slot, [])
	for npc_id in roster:
		if DemoBuild.enabled() and npc_id not in [NPC_TRA_DA, NPC_DOI_NO]:
			continue
		var layer: Dictionary = _npc_layers[npc_id]
		var overlay := layer["overlay"] as TextureRect
		var button := layer["button"] as Button
		overlay.visible = true
		overlay.modulate = Color.WHITE
		overlay.position = Vector2(1380, 130) if npc_id == NPC_DOI_NO else _overlay_out_offset(StringName(layer["slot"]))
		button.visible = true
		button.disabled = true
		button.mouse_filter = Control.MOUSE_FILTER_IGNORE


func _hide_all_npcs() -> void:
	if collector_arrival != null: collector_arrival.stop()
	if _focus_motion != null: _focus_motion.kill()
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
		button.mouse_filter = Control.MOUSE_FILTER_IGNORE if button.disabled else Control.MOUSE_FILTER_STOP


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
	overview.set_focused(focused)
	money_label.visible = not focused
	money_row.visible = not focused
	if _header_motion != null: _header_motion.kill()
	var header := day_label.get_parent() as Control
	var target_position := Vector2(380, -2) if focused else Vector2(380, 190)
	var target_scale := Vector2(0.78, 0.78) if focused else Vector2.ONE
	if not animate:
		header.position = target_position
		header.scale = target_scale
		return
	_header_motion = create_tween().set_parallel(true)
	var tween := _header_motion
	tween.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(header, "position", target_position, 0.28)
	tween.tween_property(header, "scale", target_scale, 0.28)


func _clear_content() -> void:
	if conversation != null:
		conversation.visible = false
	content_panel.visible = false
	back_button.visible = false
	for child in participants_container.get_children():
		participants_container.remove_child(child)
		child.queue_free()


func say(line: String) -> void:
	if focused_npc_id.is_empty():
		return
	var misc_service := MISC_SERVICE_RECTS.has(focused_npc_id)
	conversation.speech.custom_minimum_size.y = 40 if misc_service or focused_npc_id == NPC_DOI_NO else 60 if focused_npc_id == NPC_HANG_RONG else 80
	if misc_service:
		var service_rect: Rect2 = MISC_SERVICE_RECTS[focused_npc_id]
		conversation.position = Vector2(service_rect.position.x, 140)
	else:
		conversation.position = Vector2(20, 510) if focused_npc_id == NPC_THAY_BOI else Vector2(165, 140)
	conversation.say(npc_display_name(focused_npc_id), line)
	conversation.show_responses(focused_npc_id not in [NPC_TRA_DA, NPC_DOI_NO], not back_button.disabled)
	var speech_size := Vector2(340, 176) if focused_npc_id == NPC_THAY_BOI else Vector2(710, 124 if focused_npc_id in [NPC_TRA_DA, NPC_DOI_NO] else 140 if focused_npc_id == NPC_HANG_RONG else 160)
	if misc_service:
		speech_size = Vector2(700, 124)
	conversation.set_deferred("size", speech_size)


func _on_conversation_response(response_id: String) -> void:
	if response_id == "leave":
		if not back_button.disabled: unfocus_npc()
	elif response_id == "small_talk":
		say(tr("NPC_CHAT_" + focused_npc_id.to_upper()))


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
		&"top_right":
			return Rect2(850, 0, 430, 270)
		_:
			return Rect2(430, 0, 420, 190)


func _slot_name_position(slot: StringName) -> Vector2:
	match slot:
		&"left":
			return Vector2(22, 612)
		&"right":
			return Vector2(1048, 612)
		&"top_right":
			return Vector2(1038, 220)
		_:
			return Vector2(535, 18)


func _overlay_out_offset(slot: StringName) -> Vector2:
	match slot:
		&"left":
			return Vector2(-90, 0)
		&"right":
			return Vector2(90, 0)
		&"top_right":
			return Vector2(90, -45)
		_:
			return Vector2(0, -90)


func _sprite_focus_position(slot: StringName, sprite_size: Vector2) -> Vector2:
	match slot:
		&"left":
			return Vector2(-sprite_size.x * 0.10, 70)
		&"right", &"top_right":
			return Vector2(1280 - sprite_size.x * 0.90, 70)
		_:
			return Vector2(640 - sprite_size.x * 0.5, -55)


func _sprite_out_position(slot: StringName, sprite_size: Vector2) -> Vector2:
	var focus := _sprite_focus_position(slot, sprite_size)
	match slot:
		&"left":
			return focus + Vector2(-180, 35)
		&"right", &"top_right":
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
