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
const TABLE_STATE_RESOLUTION := &"resolution"
const TRANSITION_SECONDS := 0.34
const EVENT_DECK_REST_POSITION := Vector2(292, 398)
const EVENT_DECK_FOCUS_POSITION := Vector2(72, 272)
const SERVICE_BUTTON_SIZE := Vector2(210, 48)
const SERVICE_BUTTON_GAP := 12.0
const SERVICE_ROW_Y := 578.0

const NPC_DANH_GIAY := "danh_giay"
const NPC_TRA_DA := "tra_da_auntie"
const NPC_THAY_BOI := "thay_boi"
const NPC_HANG_RONG := "hang_rong"
const NPC_LOTTO := "lotto"
const NPC_DOI_NO := "doi_no"
const NPC_ZODIAC := "zodiac"

# Dialogue and service share a column beside the full focused character.
const MISC_SERVICE_RECTS := {
	NPC_DANH_GIAY: Rect2(460, 284, 700, 400),
	NPC_LOTTO: Rect2(145, 284, 700, 400),
}

const EVENT_ROSTERS := {
	0: [NPC_DANH_GIAY, NPC_TRA_DA],
	1: [NPC_THAY_BOI, NPC_HANG_RONG, NPC_LOTTO],
	2: [NPC_THAY_BOI, NPC_TRA_DA],
	3: [NPC_THAY_BOI, NPC_HANG_RONG],
}
const NPC_DATA := {
	NPC_ZODIAC: {
		"name_key": "", "slot": &"top_right",
		"overlay": preload("res://assets/zodiacboss/rooster_overlay.png"),
		"sprite": preload("res://assets/zodiacboss/rooster.png"),
	},
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
var continue_hint: Label
var _required_npc_id := ""
var _required_reason := ""
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
var input_obstructed: Callable
var input_point_obstructed: Callable
var _touch_ids: Dictionary = {}
var _touch_index := -1
var _touch_start := Vector2.ZERO
var _touch_npc := ""
var _touch_cancelled := false
var _suppress_mouse_until := 0
var _native_sequence := false
var zodiac_id := ""
var _zodiac_present := false

func set_zodiac_visitor(id: String, present: bool) -> void:
	if not _npc_layers.has(NPC_ZODIAC): return
	var layer: Dictionary = _npc_layers[NPC_ZODIAC]
	if id != zodiac_id and ZodiacCatalog.DEFINITIONS.has(id):
		(layer.overlay as TextureRect).texture = load(ZodiacCatalog.sprite_path(id, true))
		(layer.sprite as TextureRect).texture = load(ZodiacCatalog.sprite_path(id))
		(layer.character_target as NpcTapTarget).hit_texture = layer.overlay.texture
		(layer.sprite as TextureRect).size = Vector2(450, 590)
		(layer.sprite as TextureRect).pivot_offset = Vector2(225, 295)
	zodiac_id = id
	_zodiac_present = present and not id.is_empty() and not DemoBuild.enabled()
	(layer.name_tag as Label).text = npc_display_name(NPC_ZODIAC)
	(layer.button as Button).tooltip_text = npc_display_name(NPC_ZODIAC)
	if table_state != TABLE_STATE_EVENT or current_event_slot not in [EventManager.EventSlot.NOON, EventManager.EventSlot.AFTERNOON]: return
	if not focused_npc_id.is_empty() or deck_focused: return
	(layer.overlay as Control).visible = _zodiac_present
	(layer.button as Button).visible = _zodiac_present
	(layer.button as Button).disabled = not _zodiac_present
	(layer.button as Control).mouse_filter = Control.MOUSE_FILTER_STOP if _zodiac_present else Control.MOUSE_FILTER_IGNORE
	(layer.name_tag as Control).visible = _zodiac_present
	(layer.character_target as Control).visible = _zodiac_present
	_layout_roster_buttons()

func roster_interactive() -> bool:
	return is_visible_in_tree() and table_state == TABLE_STATE_EVENT and focused_npc_id.is_empty() and not deck_focused and not overview.expanded and (not input_obstructed.is_valid() or not input_obstructed.call())

func cancel_pointer() -> void:
	_touch_index = -1
	_touch_npc = ""
	_touch_cancelled = true
	for layer: Dictionary in _npc_layers.values():
		(layer["button"] as NpcTapTarget).cancel_pointer()
		(layer["character_target"] as NpcTapTarget).cancel_pointer()

func _npc_at(point: Vector2) -> String:
	if not roster_interactive(): return ""
	if input_point_obstructed.is_valid() and input_point_obstructed.call(point): return ""
	# Labels are unambiguous. Silhouettes follow the visible drawing order.
	for id in _npc_layers:
		if (_npc_layers[id]["button"] as NpcTapTarget).hits_global(point): return id
	var ids := _npc_layers.keys()
	ids.sort_custom(func(a,b): return _npc_layers[a]["overlay"].get_index() > _npc_layers[b]["overlay"].get_index())
	for id in ids:
		if (_npc_layers[id]["character_target"] as NpcTapTarget).hits_global(point): return id
	return ""

func request_npc_focus(npc_id: String) -> void:
	if roster_interactive() and _npc_layers.has(npc_id) and (_npc_layers[npc_id]["button"] as NpcTapTarget).available():
		focus_npc(npc_id)

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.device == -1 and Time.get_ticks_msec() < _suppress_mouse_until:
		get_viewport().set_input_as_handled()
		return
	if event is InputEventScreenTouch:
		if event.pressed:
			_touch_ids[event.index] = true
			if _touch_ids.size() > 1:
				cancel_pointer()
				if _native_sequence: get_viewport().set_input_as_handled()
				return
			var id := _npc_at(event.position)
			if not id.is_empty():
				_native_sequence = true
				_suppress_mouse_until = Time.get_ticks_msec() + 800
				cancel_pointer()
				_touch_index = event.index
				_touch_npc = id
				_touch_start = event.position
				_touch_cancelled = false
				get_viewport().set_input_as_handled()
		else:
			_touch_ids.erase(event.index)
			if _native_sequence:
				get_viewport().set_input_as_handled()
				_suppress_mouse_until = Time.get_ticks_msec() + 800
				if _touch_ids.is_empty(): _native_sequence = false
			if event.index == _touch_index:
				_suppress_mouse_until = Time.get_ticks_msec() + 800
				var id := _touch_npc
				var activate: bool = not event.canceled and not _touch_cancelled and _npc_at(event.position) == id
				cancel_pointer()
				get_viewport().set_input_as_handled()
				if activate: focus_npc(id)
	elif event is InputEventScreenDrag and event.index == _touch_index:
		if event.position.distance_to(_touch_start) > 12: _touch_cancelled = true
		get_viewport().set_input_as_handled()

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_WINDOW_FOCUS_OUT:
		cancel_pointer()
		_touch_ids.clear()
		_native_sequence = false


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

func _process(_delta: float) -> void:
	if _touch_index >= 0 and not roster_interactive(): cancel_pointer()
	if continue_hint != null:
		continue_hint.visible = visible and continue_button.visible and continue_button.disabled and not _required_reason.is_empty()
	if not _required_npc_id.is_empty() and _npc_layers.has(_required_npc_id):
		var marker := _npc_layers[_required_npc_id]["name_tag"] as Label
		marker.visible = visible and table_state == TABLE_STATE_EVENT and focused_npc_id.is_empty() and not deck_focused
		marker.modulate.a = 0.8 + 0.2 * sin(Time.get_ticks_msec() * 0.006)


func configure_deal_nodes(nodes: Array[Control]) -> void:
	_deal_nodes = nodes
	_deal_home.clear()
	for node in _deal_nodes:
		if node == null:
			continue
		_deal_home[node] = {
			"position": node.position,
			"offsets": Vector4(node.offset_left, node.offset_top, node.offset_right, node.offset_bottom),
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
	cancel_pointer()
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


func set_continue_enabled(enabled: bool, reason: String = "", required_npc_id: String = "") -> void:
	var previous_reason := _required_reason
	continue_button.disabled = not enabled
	_required_reason = reason if not enabled else ""
	_required_npc_id = required_npc_id if not enabled else ""
	continue_button.tooltip_text = _required_reason
	continue_hint.text = _required_reason
	if not _required_reason.is_empty() and _required_reason != previous_reason:
		continue_hint.pivot_offset = continue_hint.size * 0.5
		continue_hint.modulate.a = 0.0
		continue_hint.scale = Vector2(0.96, 0.96)
		var pop := create_tween().set_parallel(true)
		pop.tween_property(continue_hint, "modulate:a", 1.0, 0.2)
		pop.tween_property(continue_hint, "scale", Vector2.ONE, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	for npc_id in _npc_layers:
		var npc_layer: Dictionary = _npc_layers[npc_id]
		(npc_layer["button"] as Button).tooltip_text = npc_display_name(String(npc_id))
		(npc_layer["name_tag"] as Label).text = npc_display_name(String(npc_id))
		if focused_npc_id.is_empty():
			(npc_layer["name_tag"] as Label).visible = (npc_layer["overlay"] as Control).visible
	if not _required_npc_id.is_empty() and _npc_layers.has(_required_npc_id):
		var layer: Dictionary = _npc_layers[_required_npc_id]
		(layer["button"] as Button).tooltip_text = _required_reason
		(layer["name_tag"] as Label).text = "↓ " + npc_display_name(_required_npc_id)


func refresh_localized_ui() -> void:
	continue_button.text = tr("EVENT_CONTINUE")
	back_button.text = tr("EVENT_BACK")
	if menu_button != null: menu_button.text = tr("HUD_MENU")
	for npc_id in _npc_layers:
		var layer: Dictionary = _npc_layers[npc_id]
		(layer["name_tag"] as Label).text = npc_display_name(String(npc_id))


func focus_npc(npc_id: String) -> void:
	cancel_pointer()
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
		button.hide()
		(layer["character_target"] as Control).hide()
		name_tag.visible = candidate_id == npc_id and npc_id not in [NPC_THAY_BOI, NPC_DANH_GIAY, NPC_LOTTO, NPC_DOI_NO, NPC_ZODIAC]
		if candidate_id == npc_id:
			tween.tween_property(overlay, "modulate:a", 0.0, 0.18)
			sprite.visible = true
			sprite.modulate.a = 0.0
			sprite.position = _sprite_out_position(StringName(layer["slot"]), sprite.size)
			var focus_position := Vector2(0, 95) if npc_id == NPC_THAY_BOI else Vector2(855, 140) if npc_id == NPC_DOI_NO else Vector2(1280 - sprite.size.x * 0.90, 160) if npc_id == NPC_HANG_RONG else _sprite_focus_position(StringName(layer["slot"]), sprite.size)
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
	cancel_pointer()
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
		button.hide()
		(layer["character_target"] as Control).hide()
		if overlay.visible:
			tween.tween_property(overlay, "modulate", Color(0.42, 0.46, 0.5, 0.38), 0.22)
	deck_inspect_requested.emit()


func unfocus_npc() -> void:
	cancel_pointer()
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
			button.show()
			(layer["character_target"] as Control).show()
			name_tag.show()
	focus_cleared.emit()


func event_money_feedback(value_text: String) -> void:
	money_label.text = value_text
	var pulse := create_tween()
	pulse.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	pulse.tween_property(money_label, "scale", Vector2(1.12, 1.12), 0.12)
	pulse.tween_property(money_label, "scale", Vector2.ONE, 0.18)


## Receipt/outcome presentation owns the stage until the next event or deal.
func enter_resolution(animate_cards: bool = false) -> void:
	table_state = TABLE_STATE_RESOLUTION
	if _transition != null and _transition.is_valid():
		_transition.kill()
	_hide_all_npcs()
	_clear_content()
	_stop_money_pulse()
	focused_npc_id = ""
	deck_focused = false
	hide()
	if animate_cards:
		_animate_deal_out()


func clear_service_views() -> void:
	for child in participants_container.get_children():
		participants_container.remove_child(child)
		child.queue_free()


func npc_display_name(npc_id: String) -> String:
	if npc_id == NPC_ZODIAC: return ZodiacCatalog.display_name(zodiac_id) if not zodiac_id.is_empty() else ZodiacCatalog.words("ZODIAC", "CON GIÁP")
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
	var style := PresentationTheme.panel_style(Color("#102338c8"), Color("#8d5b30"), 1, 3, 3)
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
	continue_button.position = Vector2(520, 656)
	continue_button.size = Vector2(240, 48)
	continue_button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	continue_button.set_meta("match_binding", "campaign_continue_button")
	PresentationTheme.configure_button(continue_button, "gold")
	add_child(continue_button)
	continue_hint = Label.new()
	continue_hint.name = "ContinueRequirement"
	continue_hint.position = Vector2(370, 628)
	continue_hint.size = Vector2(540, 24)
	continue_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	continue_hint.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	continue_hint.add_theme_font_size_override("font_size", 16)
	continue_hint.add_theme_color_override("font_color", PresentationTheme.WARNING)
	continue_hint.add_theme_color_override("font_shadow_color", Color.BLACK)
	continue_hint.add_theme_constant_override("shadow_offset_x", 1)
	continue_hint.add_theme_constant_override("shadow_offset_y", 2)
	continue_hint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	continue_hint.visible = false
	add_child(continue_hint)


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
		elif npc_id == NPC_HANG_RONG:
			# Keep her baskets clear of the removal slip and its confirmation.
			target_height = 520.0
		var ratio := target_height / sprite_texture.get_height()
		sprite.size = sprite_texture.get_size() * ratio
		sprite.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		sprite.texture = sprite_texture
		sprite.size = sprite_texture.get_size() * ratio
		if npc_id == NPC_DOI_NO: sprite.size = Vector2(420, 545)
		sprite.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		sprite.mouse_filter = Control.MOUSE_FILTER_IGNORE
		sprite.material = ShaderMaterial.new()
		(sprite.material as ShaderMaterial).shader = preload("res://shaders/zodiac_spirit.gdshader") if npc_id == NPC_ZODIAC else preload("res://shaders/npc_focus.gdshader")
		sprite.visible = false
		add_child(sprite)
		move_child(sprite, 2)
		var character_target := NpcTapTarget.new()
		character_target.name = "%sCharacterTap" % npc_id.to_pascal_case()
		character_target.hit_texture = data["overlay"]
		character_target.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		character_target.flat = true
		for state in ["normal","hover","pressed","disabled","focus"]:
			character_target.add_theme_stylebox_override(state,StyleBoxEmpty.new())
		character_target.focus_mode = Control.FOCUS_NONE
		character_target.can_activate = roster_interactive
		character_target.pressed.connect(request_npc_focus.bind(npc_id))
		character_target.hide()
		add_child(character_target)
		var button := NpcTapTarget.new()
		button.name = "%sSelect" % npc_id.to_pascal_case()
		button.flat = false
		button.focus_mode = Control.FOCUS_ALL
		button.can_activate = roster_interactive
		button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		button.size = SERVICE_BUTTON_SIZE
		button.z_index = 20 # Names stay above every character's silhouette target.
		PresentationTheme.configure_button(button, "tea")
		button.tooltip_text = npc_display_name(npc_id)
		button.visible = false
		button.pressed.connect(request_npc_focus.bind(npc_id))
		add_child(button)
		var name_tag := Label.new()
		name_tag.name = "%sName" % npc_id.to_pascal_case()
		name_tag.text = npc_display_name(npc_id)
		name_tag.position = button.position
		name_tag.z_index = 21
		name_tag.size = SERVICE_BUTTON_SIZE
		name_tag.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		name_tag.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		name_tag.add_theme_font_size_override("font_size", 14)
		name_tag.add_theme_color_override("font_color", Color("#fff0bd"))
		name_tag.visible = false
		name_tag.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(name_tag)
		_npc_layers[npc_id] = {
			"slot": slot,
			"overlay": overlay,
			"sprite": sprite,
			"button": button,
			"character_target": character_target,
			"name_tag": name_tag,
		}
	for layer in _npc_layers.values():
		(layer["character_target"] as Control).z_index = (layer["overlay"] as Control).get_index()


func _show_roster(event_slot: int) -> void:
	cancel_pointer()
	_hide_all_npcs()
	var roster: Array = [NPC_TRA_DA] if DemoBuild.enabled() else EVENT_ROSTERS.get(event_slot, []).duplicate()
	if _zodiac_present and event_slot in [EventManager.EventSlot.NOON, EventManager.EventSlot.AFTERNOON]: roster.append(NPC_ZODIAC)
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
		(layer["name_tag"] as Control).show()
		(layer["character_target"] as Control).hide()
		button.disabled = true
		button.mouse_filter = Control.MOUSE_FILTER_IGNORE

	_layout_roster_buttons()


func _layout_roster_buttons() -> void:
	# Follow the artwork from left to right, keeping every visitor in one row.
	var visitors: Array[String] = []
	for slot in [&"left", &"top_right", &"right"]:
		for npc_id in _npc_layers:
			var layer: Dictionary = _npc_layers[npc_id]
			if layer.slot == slot and (layer.overlay as Control).visible:
				visitors.append(String(npc_id))
	var width := visitors.size() * SERVICE_BUTTON_SIZE.x + maxi(0, visitors.size() - 1) * SERVICE_BUTTON_GAP
	var left := (1280.0 - width) * 0.5
	for index in visitors.size():
		var layer: Dictionary = _npc_layers[visitors[index]]
		var point := Vector2(left + index * (SERVICE_BUTTON_SIZE.x + SERVICE_BUTTON_GAP), SERVICE_ROW_Y)
		(layer.button as Control).position = point
		(layer.name_tag as Control).position = point


func _hide_all_npcs() -> void:
	cancel_pointer()
	if collector_arrival != null: collector_arrival.stop()
	if _focus_motion != null: _focus_motion.kill()
	for npc_id in _npc_layers:
		var layer: Dictionary = _npc_layers[npc_id]
		(layer["overlay"] as TextureRect).visible = false
		(layer["sprite"] as TextureRect).visible = false
		(layer["button"] as Button).visible = false
		(layer["character_target"] as Control).hide()
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
	if table_state != TABLE_STATE_EVENT or not focused_npc_id.is_empty() or deck_focused:
		return
	for npc_id in _npc_layers:
		var layer: Dictionary = _npc_layers[npc_id]
		var button := layer["button"] as Button
		button.disabled = not (layer["overlay"] as TextureRect).visible
		button.mouse_filter = Control.MOUSE_FILTER_IGNORE if button.disabled else Control.MOUSE_FILTER_STOP
		(layer["character_target"] as Control).visible = not button.disabled


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
		_tween_deal_offset(_transition, node, home, _deal_exit_offset(node.name))
		_transition.tween_property(node, "modulate:a", 0.0, TRANSITION_SECONDS * 0.78)
	_transition.chain().tween_callback(_finish_deal_exit)


func _finish_deal_exit() -> void:
	if table_state not in [TABLE_STATE_EVENT, TABLE_STATE_RESOLUTION]:
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
		_set_deal_offset(_deal_exit_offset(node.name), node, home.offsets)
		node.scale = Vector2(home["scale"])
		node.modulate = Color(home["modulate"])
		node.modulate.a = 0.0
	var tween := create_tween().set_parallel(true)
	tween.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	for node in _deal_nodes:
		if node == null or not _deal_home.has(node):
			continue
		var home: Dictionary = _deal_home[node]
		_tween_deal_offset(tween, node, home, Vector2.ZERO)
		tween.tween_property(node, "modulate", Color(home["modulate"]), TRANSITION_SECONDS)
	tween.chain().tween_callback(func() -> void: deal_presentation_ready.emit())


func _tween_deal_offset(tween: Tween, node: Control, home: Dictionary, target: Vector2) -> void:
	# Animate the authored offsets, so the anchors still respond during a resize.
	var offsets: Vector4 = home.offsets
	var current := Vector2(node.offset_left - offsets.x, node.offset_top - offsets.y)
	tween.tween_method(_set_deal_offset.bind(node, offsets), current, target, TRANSITION_SECONDS)


func _set_deal_offset(displacement: Vector2, node: Control, offsets: Vector4) -> void:
	if not is_instance_valid(node): return
	node.offset_left = offsets.x + displacement.x
	node.offset_top = offsets.y + displacement.y
	node.offset_right = offsets.z + displacement.x
	node.offset_bottom = offsets.w + displacement.y


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
	clear_service_views()


func say(line: String) -> void:
	if focused_npc_id.is_empty():
		return
	var misc_service := MISC_SERVICE_RECTS.has(focused_npc_id)
	conversation.speech.custom_minimum_size.y = 36
	if misc_service:
		var service_rect: Rect2 = MISC_SERVICE_RECTS[focused_npc_id]
		conversation.position = Vector2(service_rect.position.x, 140)
	else:
		conversation.position = Vector2(165, 510) if focused_npc_id == NPC_THAY_BOI else Vector2(165, 140)
	conversation.say(npc_display_name(focused_npc_id), line, focused_npc_id == NPC_HANG_RONG)
	conversation.handbook.visible = focused_npc_id not in [NPC_TRA_DA, NPC_THAY_BOI, NPC_HANG_RONG]
	conversation.show_responses(focused_npc_id not in [NPC_TRA_DA, NPC_DOI_NO, NPC_HANG_RONG], not back_button.disabled)
	var speech_size := Vector2(340, 176) if focused_npc_id == NPC_THAY_BOI else Vector2(710, 124 if focused_npc_id in [NPC_TRA_DA, NPC_DOI_NO] else 110 if focused_npc_id == NPC_HANG_RONG else 160)
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

func npc_anchor(npc_id: String, fallback: Vector2) -> Vector2:
	var layer: Dictionary = _npc_layers.get(npc_id, {})
	var sprite := layer.get("sprite") as Control
	return sprite.get_global_rect().get_center() if sprite != null and sprite.is_visible_in_tree() else fallback

func zodiac_views() -> Dictionary:
	var layer: Dictionary = _npc_layers[NPC_ZODIAC]
	return {"button": layer.button, "portrait": layer.overlay, "character": layer.sprite, "nameplate": layer.name_tag}

func guidance_targets() -> Array[Dictionary]:
	var targets: Array[Dictionary] = []
	if _npc_layers.has(_required_npc_id):
		targets.append({"id": _required_npc_id, "button": _npc_layers[_required_npc_id].button})
	for id in _npc_layers:
		if id != _required_npc_id: targets.append({"id": id, "button": _npc_layers[id].button})
	return targets
