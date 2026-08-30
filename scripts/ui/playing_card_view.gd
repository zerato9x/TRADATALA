class_name PlayingCardView
extends Control

signal card_pressed(card: CardData)
signal card_drag_started(card: CardData, global_position: Vector2)

const CARD_SIZE := Vector2(86, 119)
const DRAG_THRESHOLD := 8.0
const CardActionOutlineScript := preload("res://scripts/ui/card_action_outline.gd")

var card: CardData
var selected: bool = false
var base_position := Vector2.ZERO
var base_rotation: float = 0.0
var _hovered := false
var _stack_order: int = 0
var _shadow: Panel
var _drink_outline: Control
var _action_outline: Control
var _beat_visual: Control
var _texture: TextureRect
var _meld_chance_badge: Label
var _motion_tween: Tween
var _feedback_tween: Tween
var _beat_tween: Tween
var _interaction_enabled: bool = true
var _chance_tooltip: String = ""
var _can_meld: bool = false
var _can_extend: bool = false
var _drink_preserved: bool = false
var _press_active: bool = false
var _dragging: bool = false
var _press_position := Vector2.ZERO


func _ready() -> void:
	custom_minimum_size = CARD_SIZE
	size = CARD_SIZE
	pivot_offset = CARD_SIZE * 0.5
	mouse_filter = Control.MOUSE_FILTER_STOP
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_build_visuals()
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	_apply_card_texture()


func set_card(value: CardData) -> void:
	card = value
	_refresh_tooltip()
	_apply_card_texture()


func set_meld_chance(probability: float, is_ready: bool, target_label: String, needed_text: String, draw_count: int) -> void:
	if _meld_chance_badge == null:
		return
	var percent := clampi(int(round(probability * 100.0)), 0, 100)
	if is_ready:
		_meld_chance_badge.text = "✓"
		_meld_chance_badge.add_theme_color_override("font_color", Color.WHITE)
		_meld_chance_badge.add_theme_stylebox_override("normal", PresentationTheme.panel_style(Color("#3d702df2"), PresentationTheme.TEA, 1, 2, 2))
		_chance_tooltip = tr("PROBABILITY_READY") % target_label
	else:
		_meld_chance_badge.text = "%d%%" % percent
		var active := probability > 0.0
		_meld_chance_badge.add_theme_color_override("font_color", Color("#fff1c5") if active else Color("#a99d88"))
		_meld_chance_badge.add_theme_stylebox_override("normal", PresentationTheme.panel_style(
			Color("#9a641ff2") if active else Color("#26231fe8"),
			PresentationTheme.GOLD if active else Color("#51483b"), 1, 2, 2
		))
		_chance_tooltip = tr("PROBABILITY_DRAW") % [target_label, probability * 100.0, draw_count, needed_text]
	_refresh_probability_visibility()
	_refresh_tooltip()


func set_action_cues(can_meld: bool, can_extend: bool) -> void:
	_can_meld = can_meld
	_can_extend = can_extend
	_refresh_action_outline()


func set_drink_preserved(value: bool) -> void:
	_drink_preserved = value
	_refresh_drink_outline()


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
	selected = value
	_refresh_z_index()
	_update_pose(animate)


func set_stack_order(value: int) -> void:
	_stack_order = value
	_refresh_z_index()


func set_interaction_enabled(enabled: bool) -> void:
	_interaction_enabled = enabled
	mouse_filter = Control.MOUSE_FILTER_STOP if enabled else Control.MOUSE_FILTER_IGNORE
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND if enabled else Control.CURSOR_ARROW
	_refresh_probability_visibility()
	_refresh_action_outline()
	_refresh_tooltip()
	if not enabled and _hovered:
		_hovered = false
		_refresh_z_index()
		_update_pose(true)
	if not enabled:
		finish_drag_interaction()


func finish_drag_interaction() -> void:
	_press_active = false
	_dragging = false
	_refresh_z_index()
	_update_pose(true)


func layout_to(target_position: Vector2, target_rotation: float, animate: bool = true) -> void:
	base_position = target_position
	base_rotation = target_rotation
	_update_pose(animate)


func spawn_from(local_origin: Vector2) -> void:
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

	_drink_outline = CardActionOutlineScript.new()
	_drink_outline.name = "DrinkOutline"
	_drink_outline.position = Vector2(-10, -10)
	_drink_outline.size = CARD_SIZE + Vector2(20, 20)
	_drink_outline.visible = false
	_beat_visual.add_child(_drink_outline)

	_action_outline = CardActionOutlineScript.new()
	_action_outline.name = "ActionOutline"
	_action_outline.position = Vector2(-6, -6)
	_action_outline.size = CARD_SIZE + Vector2(12, 12)
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

	_meld_chance_badge = Label.new()
	_meld_chance_badge.name = "MeldChance"
	_meld_chance_badge.position = Vector2(48, 4)
	_meld_chance_badge.size = Vector2(34, 17)
	_meld_chance_badge.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_meld_chance_badge.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_meld_chance_badge.add_theme_font_size_override("font_size", 9)
	_meld_chance_badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_meld_chance_badge.visible = false
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


func _refresh_tooltip() -> void:
	if not _interaction_enabled or card == null:
		tooltip_text = ""
		return
	tooltip_text = tr("CARD_POINTS") % [card.short_label(), card.score_value()]
	if not _chance_tooltip.is_empty():
		tooltip_text += "\n" + _chance_tooltip


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		accept_event()
		if event.pressed:
			_press_active = true
			_dragging = false
			_press_position = event.position
		elif _press_active:
			var was_dragging := _dragging
			_press_active = false
			_dragging = false
			if not was_dragging:
				card_pressed.emit(card)
			_refresh_z_index()
			_update_pose(true)
	elif event is InputEventMouseMotion and _press_active:
		if not _dragging and event.position.distance_to(_press_position) >= DRAG_THRESHOLD:
			_dragging = true
			_refresh_z_index()
			_update_pose(true)
			card_drag_started.emit(card, get_global_mouse_position())
	elif event is InputEventMouseMotion and _hovered:
		var horizontal := clampf((event.position.x / CARD_SIZE.x) - 0.5, -0.5, 0.5)
		rotation = base_rotation + horizontal * 0.045


func _on_mouse_entered() -> void:
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
		_meld_chance_badge.visible = _hovered and _interaction_enabled and not _meld_chance_badge.text.is_empty()


func _refresh_action_outline() -> void:
	if _action_outline != null:
		_action_outline.set_cues(_can_meld and _interaction_enabled, _can_extend and _interaction_enabled)


func _refresh_drink_outline() -> void:
	if _drink_outline != null:
		_drink_outline.set_drink_cue(_drink_preserved)


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
