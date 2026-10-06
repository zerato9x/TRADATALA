class_name PlayingCardView
extends Control

signal card_pressed(card: CardData)
signal card_drag_started(card: CardData, global_position: Vector2)

const CARD_SIZE := Vector2(86, 119)
const DRAG_THRESHOLD := 12.0
const CardActionOutlineScript := preload("res://scripts/ui/card_action_outline.gd")
const CardSymbolArtScript := preload("res://scripts/ui/card_symbol_art.gd")
static var _keyboard_navigation := false

var card: CardData
var selected: bool = false
var base_position := Vector2.ZERO
var base_rotation: float = 0.0
var _hovered := false
var _stack_order: int = 0
var _shadow: Panel
var _action_outline: Control
var _beat_visual: Control
var _texture: TextureRect
var _meld_chance_badge: Panel
var _meld_chance_value: Label
var _meld_chance_icon: TextureRect
var _motion_tween: Tween
var _feedback_tween: Tween
var _beat_tween: Tween
var _interaction_enabled: bool = true
var _chance_tooltip: String = ""
var _can_meld: bool = false
var _can_extend: bool = false
var _can_drink: bool = false
var _drink_emphasized: bool = false
var _press_active: bool = false
var _dragging: bool = false
var _press_position := Vector2.ZERO
var drag_enabled: bool = true
var zodiac_locked := false
var _zodiac_lock: Panel
var _zodiac_smoke: ColorRect
var _zodiac_cue: Control
var _zodiac_tip := ""
var _focus_inspection: Control
var _pose_initialized := false
var _pose_position := Vector2.ZERO
var _pose_rotation := 0.0
var _pose_scale := Vector2.ONE
var _pose_modulate := Color.WHITE

func set_zodiac_hint(hint: Dictionary) -> void:
	_zodiac_tip = String(hint.get("detail", ""))
	if not hint.is_empty() and _zodiac_cue == null:
		_zodiac_cue = preload("res://scripts/ui/zodiac_hand_cue.gd").new()
		add_child(_zodiac_cue)
	if _zodiac_cue != null: _zodiac_cue.sync(hint)
	_refresh_tooltip()

func set_zodiac_locked(value: bool) -> void:
	zodiac_locked = value
	if not value and _zodiac_lock == null: return
	if _zodiac_lock == null:
		_zodiac_smoke = preload("res://scripts/ui/zodiac_card_fx.gd").aura(self, CARD_SIZE, Color("bc78ff"), float(absi(card.unique_id.hash()) % 1000) * 0.01)
		_zodiac_smoke.name = "CatLockSmoke"
		_zodiac_lock = Panel.new()
		_zodiac_lock.name = "CatLock"
		_zodiac_lock.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		_zodiac_lock.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_zodiac_lock.add_theme_stylebox_override("panel", PresentationTheme.panel_style(Color(0.12, 0.04, 0.24, 0.10), Color("bc8dff"), 3, 4, 0))
		add_child(_zodiac_lock)
		var label := Label.new()
		label.position = Vector2(5, 48)
		label.size = Vector2(76, 24)
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.text = ZodiacCatalog.words("LOCKED", "BỊ KHÓA")
		label.add_theme_font_size_override("font_size", 13)
		label.add_theme_color_override("font_color", Color("bc8dff"))
		label.add_theme_color_override("font_shadow_color", Color.BLACK)
		label.add_theme_stylebox_override("normal", PresentationTheme.panel_style(Color("27123df2"), Color("bc8dff"), 1, 2))
		label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_zodiac_lock.add_child(label)
	_zodiac_lock.visible = value
	_zodiac_smoke.visible = value
	(_zodiac_lock.get_child(0) as Label).text = ZodiacCatalog.words("LOCKED", "BỊ KHÓA")


func _ready() -> void:
	custom_minimum_size = CARD_SIZE
	size = CARD_SIZE
	pivot_offset = CARD_SIZE * 0.5
	mouse_filter = Control.MOUSE_FILTER_STOP
	focus_mode = Control.FOCUS_ALL
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_build_visuals()
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	focus_entered.connect(_on_focus_entered)
	focus_exited.connect(_hide_focus_inspection)
	tree_exiting.connect(_hide_focus_inspection)
	visibility_changed.connect(_on_visibility_changed)
	_apply_card_texture()


func _process(_delta: float) -> void:
	# Hiding a layer or moving a card under the pointer need not emit mouse_exited.
	if _hovered and not _press_active and get_viewport().gui_get_hovered_control() != self:
		_on_mouse_exited()
	if is_instance_valid(_focus_inspection): _position_focus_inspection()
	if _texture != null and card != null:
		var phase := float(absi(card.unique_id.hash()) % 10000) * 0.01
		_texture.pivot_offset = CARD_SIZE * 0.5
		_texture.rotation = deg_to_rad(0.8) * sin(Time.get_ticks_msec() * 0.001 * (0.7 + fmod(phase, 0.6)) + phase)


func set_card(value: CardData) -> void:
	card = value
	_refresh_tooltip()
	_apply_card_texture()
	if is_inside_tree() and has_focus() and _keyboard_navigation: _show_focus_inspection()


func set_meld_chance(probability: float, is_ready: bool, target_label: String, needed_text: String, draw_count: int) -> void:
	if _meld_chance_badge == null:
		return
	var percent := clampi(int(round(probability * 100.0)), 0, 100)
	if is_ready:
		_meld_chance_value.text = ""
		_meld_chance_icon.visible = true
		_meld_chance_badge.add_theme_stylebox_override("panel", PresentationTheme.panel_style(Color("#3d702df2"), PresentationTheme.TEA, 1, 2, 2))
		_chance_tooltip = tr("PROBABILITY_READY") % target_label
	else:
		_meld_chance_value.text = "%d%%" % percent
		_meld_chance_icon.visible = false
		var active := probability > 0.0
		_meld_chance_value.add_theme_color_override("font_color", Color("#fff1c5") if active else Color("#a99d88"))
		_meld_chance_badge.add_theme_stylebox_override("panel", PresentationTheme.panel_style(
			Color("#9a641ff2") if active else Color("#26231fe8"),
			PresentationTheme.GOLD if active else Color("#51483b"), 1, 2, 2
		))
		_chance_tooltip = tr("PROBABILITY_DRAW") % [target_label, probability * 100.0, draw_count, needed_text]
	_refresh_probability_visibility()
	_refresh_tooltip()


func set_action_cues(can_meld: bool, can_extend: bool, can_drink: bool = false, drink_emphasized: bool = false) -> void:
	_can_meld = can_meld
	_can_extend = can_extend
	_can_drink = can_drink
	_drink_emphasized = drink_emphasized
	_refresh_action_outline()


func set_drink_preserved(value: bool) -> void:
	_can_drink = value
	_drink_emphasized = value
	_refresh_action_outline()


func pulse_action_eligibility(strength: float = 0.6) -> void:
	if _action_outline != null and _can_drink:
		_action_outline.play_target_pulse(strength)


func play_beat_pulse(strength: float) -> void:
	if _beat_visual == null or not is_visible_in_tree():
		return
	if _beat_tween != null and _beat_tween.is_valid():
		_beat_tween.kill()
	var pulse_strength := clampf(strength, 0.2, 1.0)
	_beat_visual.pivot_offset = CARD_SIZE * 0.5
	_beat_visual.scale = Vector2.ONE
	var peak := Vector2(
		1.0 + lerpf(0.025, 0.065, pulse_strength),
		1.0 + lerpf(0.055, 0.13, pulse_strength)
	)
	_beat_tween = create_tween()
	_beat_tween.tween_property(_beat_visual, "scale", peak, 0.075).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_beat_tween.tween_property(_beat_visual, "scale", Vector2.ONE, 0.19).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)


func set_selected(value: bool, animate: bool = true) -> void:
	if selected == value: return
	selected = value
	_refresh_z_index()
	_update_pose(animate)


func set_stack_order(value: int) -> void:
	_stack_order = value
	_refresh_z_index()


func set_interaction_enabled(enabled: bool) -> void:
	if _interaction_enabled == enabled: return
	_interaction_enabled = enabled
	mouse_filter = Control.MOUSE_FILTER_STOP if enabled else Control.MOUSE_FILTER_IGNORE
	focus_mode = Control.FOCUS_ALL if enabled else Control.FOCUS_NONE
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND if enabled else Control.CURSOR_ARROW
	_refresh_probability_visibility()
	_refresh_action_outline()
	_refresh_tooltip()
	if not enabled:
		clear_transient_interaction()


func finish_drag_interaction() -> void:
	_press_active = false
	_dragging = false
	_hide_focus_inspection()
	_hovered = _interaction_enabled and is_visible_in_tree() and get_viewport().gui_get_hovered_control() == self
	_refresh_probability_visibility()
	_refresh_z_index()
	_update_pose(true)


func layout_to(target_position: Vector2, target_rotation: float, animate: bool = true) -> void:
	base_position = target_position
	base_rotation = target_rotation
	_update_pose(animate)


func layout_in_hand(target_position: Vector2, target_rotation: float, is_selected: bool, animate: bool = true) -> void:
	selected = is_selected
	_refresh_z_index()
	layout_to(target_position, target_rotation, animate)


func spawn_from(local_origin: Vector2) -> void:
	_pose_initialized = false
	position = local_origin - CARD_SIZE * 0.5
	rotation = -0.16
	scale = Vector2(0.76, 0.76)
	modulate = Color(1, 1, 1, 0)


func play_reject() -> void:
	if _feedback_tween != null and _feedback_tween.is_running():
		_feedback_tween.kill()
	var origin := position
	_feedback_tween = create_tween()
	_feedback_tween.tween_property(self, "position", origin + Vector2(-7, 0), 0.045)
	_feedback_tween.tween_property(self, "position", origin + Vector2(7, 0), 0.07)
	_feedback_tween.tween_property(self, "position", origin, 0.045)


func _build_visuals() -> void:
	_beat_visual = Control.new()
	_beat_visual.name = "BeatVisual"
	_beat_visual.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_beat_visual.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_beat_visual.pivot_offset = CARD_SIZE * 0.5
	add_child(_beat_visual)

	_shadow = Panel.new()
	_shadow.name = "Shadow"
	_shadow.position = Vector2(5, 7)
	_shadow.size = CARD_SIZE
	_shadow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_shadow.add_theme_stylebox_override("panel", PresentationTheme.panel_style(Color("#050302a8"), Color.TRANSPARENT, 0, 2, 4))
	_beat_visual.add_child(_shadow)

	_action_outline = CardActionOutlineScript.new()
	_action_outline.name = "ActionOutline"
	_action_outline.position = Vector2(-8, -8)
	_action_outline.size = CARD_SIZE + Vector2(16, 16)
	_action_outline.visible = false
	_beat_visual.add_child(_action_outline)

	_texture = TextureRect.new()
	_texture.name = "Face"
	_texture.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_texture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_texture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_texture.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_texture.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_beat_visual.add_child(_texture)

	_meld_chance_badge = Panel.new()
	_meld_chance_badge.name = "MeldChance"
	_meld_chance_badge.position = Vector2(48, 4)
	_meld_chance_badge.size = Vector2(34, 19)
	_meld_chance_badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_meld_chance_badge.visible = false
	_meld_chance_badge.add_theme_stylebox_override("panel", PresentationTheme.panel_style(Color("#26231fe8"), Color("#51483b"), 1, 2, 2))
	var chance_content := CenterContainer.new()
	chance_content.name = "Content"
	chance_content.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	chance_content.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_meld_chance_badge.add_child(chance_content)
	_meld_chance_icon = CardSymbolArtScript.create_meld_icon(Vector2(15, 15), Color.WHITE)
	_meld_chance_icon.name = "MeldSymbol"
	_meld_chance_icon.visible = false
	chance_content.add_child(_meld_chance_icon)
	_meld_chance_value = Label.new()
	_meld_chance_value.name = "Value"
	_meld_chance_value.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_meld_chance_value.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_meld_chance_value.add_theme_font_size_override("font_size", 9)
	_meld_chance_value.mouse_filter = Control.MOUSE_FILTER_IGNORE
	chance_content.add_child(_meld_chance_value)
	add_child(_meld_chance_badge)

	var sheen := ColorRect.new()
	sheen.name = "Sheen"
	sheen.position = Vector2(5, 4)
	sheen.size = Vector2(CARD_SIZE.x - 10, 2)
	sheen.color = Color(1, 1, 1, 0.23)
	sheen.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_beat_visual.add_child(sheen)


func _apply_card_texture() -> void:
	if _texture == null or card == null:
		return
	_texture.texture = load(card.texture_path()) as Texture2D
	GieoCardFX.attach_texture(_texture, card)


func _refresh_tooltip() -> void:
	if not _interaction_enabled or card == null:
		tooltip_text = ""
		return
	tooltip_text = card.inspection_text()
	if card.shiny: tooltip_text += " · " + ZodiacCatalog.words("Shiny", "Sáng bóng")
	if zodiac_locked: tooltip_text += "\n" + ZodiacCatalog.words("Locked", "Bị khóa")


func _make_custom_tooltip(_for_text: String) -> Object:
	return CardInspection.tooltip(card) if card != null else null


func _get_tooltip(_at_position: Vector2) -> String:
	return "" if _dragging or not _interaction_enabled or is_instance_valid(_focus_inspection) else tooltip_text


func _on_focus_entered() -> void:
	if _keyboard_navigation: _show_focus_inspection()


func _show_focus_inspection() -> void:
	_hide_focus_inspection()
	if card == null or not _interaction_enabled: return
	_focus_inspection = CardInspection.tooltip(card)
	_focus_inspection.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_focus_inspection.z_index = 4090
	_focus_inspection.top_level = true
	add_child(_focus_inspection)
	_position_focus_inspection()


func _position_focus_inspection() -> void:
	var dimensions := _focus_inspection.get_combined_minimum_size()
	var transform := get_global_transform()
	var rect := Rect2(transform * Vector2.ZERO, Vector2.ZERO)
	for corner in [Vector2(size.x, 0), size, Vector2(0, size.y)]: rect = rect.expand(transform * corner)
	var viewport := get_viewport_rect().size
	var y := rect.position.y - dimensions.y - 12.0
	if y < 8.0: y = rect.end.y + 12.0
	_focus_inspection.global_position = Vector2(
		clampf(rect.get_center().x - dimensions.x * 0.5, 8.0, maxf(8.0, viewport.x - dimensions.x - 8.0)),
		clampf(y, 8.0, maxf(8.0, viewport.y - dimensions.y - 8.0)))
	_focus_inspection.size = dimensions


func _hide_focus_inspection() -> void:
	if is_instance_valid(_focus_inspection):
		_focus_inspection.hide()
		_focus_inspection.queue_free()
	_focus_inspection = null


func _input(event: InputEvent) -> void:
	# GUI relayout emits zero-travel mouse motion. It does not change input mode.
	var pointer_motion: bool = event is InputEventMouseMotion and (not event.relative.is_zero_approx() or not event.screen_relative.is_zero_approx())
	if pointer_motion or event is InputEventMouseButton or event is InputEventScreenTouch or event is InputEventScreenDrag:
		_keyboard_navigation = false
		_hide_focus_inspection()
	elif event is InputEventKey or event is InputEventJoypadButton or event is InputEventJoypadMotion:
		if event.is_action_pressed("ui_focus_next") or event.is_action_pressed("ui_focus_prev") or event.is_action_pressed("ui_up") or event.is_action_pressed("ui_down") or event.is_action_pressed("ui_left") or event.is_action_pressed("ui_right") or event.is_action_pressed("ui_accept"):
			_keyboard_navigation = true
			if has_focus() and not is_instance_valid(_focus_inspection): _show_focus_inspection()
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and not event.pressed and _press_active and not _dragging:
		_cancel_unreleased_press.call_deferred()


func _cancel_unreleased_press() -> void:
	# GUI delivery runs after _input; a release outside the card cancels the press.
	if _press_active and not _dragging: finish_drag_interaction()


func _on_visibility_changed() -> void:
	if is_node_ready() and not is_visible_in_tree(): clear_transient_interaction()


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_WINDOW_FOCUS_OUT and is_node_ready():
		_keyboard_navigation = false
		clear_transient_interaction()


func clear_transient_interaction() -> void:
	_hide_focus_inspection()
	if has_focus(): release_focus()
	_hovered = false
	_press_active = false
	_dragging = false
	_refresh_probability_visibility()
	_refresh_z_index()
	_update_pose(true)


func _gui_input(event: InputEvent) -> void:
	if not _interaction_enabled or zodiac_locked or card == null:
		return
	if event.is_action_pressed("ui_accept") and not event.is_echo():
		accept_event()
		card_pressed.emit(card)
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		accept_event()
		if event.pressed:
			_press_active = true
			_dragging = false
			_press_position = get_global_transform() * event.position
		elif _press_active:
			var was_dragging := _dragging
			_press_active = false
			_dragging = false
			if not was_dragging and Rect2(Vector2.ZERO, size).has_point(event.position):
				card_pressed.emit(card)
			_refresh_z_index()
			_update_pose(true)
	elif event is InputEventMouseMotion and _press_active:
		# Hover and selection animate the Control underneath a stationary pointer.
		# Measure pointer travel in canvas coordinates, never moving card coordinates.
		if drag_enabled and not _dragging and (get_global_transform() * event.position).distance_to(_press_position) >= DRAG_THRESHOLD:
			_dragging = true
			_hovered = false
			_hide_focus_inspection()
			_refresh_probability_visibility()
			_refresh_z_index()
			_update_pose(true)
			card_drag_started.emit(card, get_global_mouse_position())
	elif event is InputEventMouseMotion and _hovered:
		var horizontal := clampf((event.position.x / CARD_SIZE.x) - 0.5, -0.5, 0.5)
		rotation = base_rotation + horizontal * 0.045


func _on_mouse_entered() -> void:
	if not _interaction_enabled or not is_visible_in_tree() or _dragging: return
	_hovered = true
	_refresh_probability_visibility()
	_refresh_z_index()
	_update_pose(true)


func _on_mouse_exited() -> void:
	_hovered = false
	_refresh_probability_visibility()
	_refresh_z_index()
	_update_pose(true)


func _refresh_probability_visibility() -> void:
	if _meld_chance_badge != null:
		_meld_chance_badge.visible = _hovered and _interaction_enabled and not _chance_tooltip.is_empty()


func _refresh_action_outline() -> void:
	if _action_outline != null:
		_action_outline.set_cues(
			_can_meld and _interaction_enabled,
			_can_extend and _interaction_enabled,
			_can_drink,
			_drink_emphasized
		)


func _refresh_z_index() -> void:
	z_index = _stack_order + (100 if selected else 0) + (200 if _hovered else 0) + (400 if _dragging else 0)


func _update_pose(animate: bool) -> void:
	if not is_inside_tree():
		return
	var lift := 0.0
	if selected:
		lift -= 24.0
	if _hovered:
		lift -= 9.0
	var target_position := base_position + Vector2(0, lift)
	var target_scale := Vector2.ONE * (1.07 if _hovered else (1.035 if selected else 1.0))
	var target_rotation := base_rotation if not _hovered else rotation
	var target_modulate := Color(1, 1, 1, 0.42) if _dragging else Color.WHITE
	if animate and _pose_initialized and _pose_position.is_equal_approx(target_position) and is_equal_approx(_pose_rotation, target_rotation) and _pose_scale.is_equal_approx(target_scale) and _pose_modulate.is_equal_approx(target_modulate): return
	_pose_initialized = true
	_pose_position = target_position
	_pose_rotation = target_rotation
	_pose_scale = target_scale
	_pose_modulate = target_modulate
	if _motion_tween != null and _motion_tween.is_running():
		_motion_tween.kill()
	if not animate:
		position = target_position
		rotation = target_rotation
		scale = target_scale
		modulate = target_modulate
		return
	_motion_tween = create_tween().set_parallel(true)
	_motion_tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_motion_tween.tween_property(self, "position", target_position, 0.18)
	_motion_tween.tween_property(self, "rotation", target_rotation, 0.18)
	_motion_tween.tween_property(self, "scale", target_scale, 0.18)
	_motion_tween.tween_property(self, "modulate", target_modulate, 0.14)
