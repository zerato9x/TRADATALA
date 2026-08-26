class_name PlayingCardView
extends Control

signal card_pressed(card: CardData)

const CARD_SIZE := Vector2(86, 119)

var card: CardData
var selected: bool = false
var base_position := Vector2.ZERO
var base_rotation: float = 0.0
var _hovered := false
var _shadow: Panel
var _outline: Panel
var _texture: TextureRect
var _motion_tween: Tween
var _feedback_tween: Tween


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
	tooltip_text = "%s  •  %d điểm" % [card.short_label(), card.score_value()]
	_apply_card_texture()


func set_selected(value: bool, animate: bool = true) -> void:
	selected = value
	if _outline != null:
		_outline.visible = selected
	_update_pose(animate)


func set_interaction_enabled(enabled: bool) -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP if enabled else Control.MOUSE_FILTER_IGNORE
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND if enabled else Control.CURSOR_ARROW
	tooltip_text = "%s  •  %d điểm" % [card.short_label(), card.score_value()] if enabled and card != null else ""
	if not enabled and _hovered:
		_hovered = false
		z_index -= 200
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
	_shadow = Panel.new()
	_shadow.name = "Shadow"
	_shadow.position = Vector2(5, 7)
	_shadow.size = CARD_SIZE
	_shadow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_shadow.add_theme_stylebox_override("panel", PresentationTheme.panel_style(Color("#0207069c"), Color.TRANSPARENT, 0, 6, 4))
	add_child(_shadow)

	_outline = Panel.new()
	_outline.name = "SelectionGlow"
	_outline.position = Vector2(-4, -4)
	_outline.size = CARD_SIZE + Vector2(8, 8)
	_outline.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_outline.add_theme_stylebox_override("panel", PresentationTheme.panel_style(Color("#6ed8a425"), PresentationTheme.TEA, 3, 9, 5))
	_outline.visible = false
	add_child(_outline)

	_texture = TextureRect.new()
	_texture.name = "Face"
	_texture.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_texture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_texture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_texture.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_texture.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	add_child(_texture)

	var sheen := ColorRect.new()
	sheen.name = "Sheen"
	sheen.position = Vector2(5, 4)
	sheen.size = Vector2(CARD_SIZE.x - 10, 2)
	sheen.color = Color(1, 1, 1, 0.23)
	sheen.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(sheen)


func _apply_card_texture() -> void:
	if _texture == null or card == null:
		return
	_texture.texture = load(card.texture_path()) as Texture2D


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		accept_event()
		card_pressed.emit(card)
	elif event is InputEventMouseMotion and _hovered:
		var horizontal := clampf((event.position.x / CARD_SIZE.x) - 0.5, -0.5, 0.5)
		rotation = base_rotation + horizontal * 0.045


func _on_mouse_entered() -> void:
	_hovered = true
	z_index += 200
	_update_pose(true)


func _on_mouse_exited() -> void:
	_hovered = false
	z_index -= 200
	_update_pose(true)


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
	if _motion_tween != null and _motion_tween.is_running():
		_motion_tween.kill()
	if not animate:
		position = target_position
		rotation = target_rotation
		scale = target_scale
		modulate = Color.WHITE
		return
	_motion_tween = create_tween().set_parallel(true)
	_motion_tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_motion_tween.tween_property(self, "position", target_position, 0.18)
	_motion_tween.tween_property(self, "rotation", target_rotation, 0.18)
	_motion_tween.tween_property(self, "scale", target_scale, 0.18)
	_motion_tween.tween_property(self, "modulate", Color.WHITE, 0.14)
