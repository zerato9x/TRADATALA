class_name TextReveal
extends Node
## Conversational copy only. Full strings stay available to layout and gameplay.
const SPEED := 90.0
var controls := preload("res://scripts/ui/visible_text_controls.gd").new()
var _locale := ""

static func reveal(control: Control, delay: float = 0.0, speed: float = SPEED) -> Tween:
	control.set_meta("manual_text_reveal", true)
	finish(control)
	control.visible_characters_behavior = TextServer.VC_CHARS_AFTER_SHAPING
	control.visible_characters = 0
	var tween := control.create_tween()
	control.set_meta("text_reveal_tween", tween)
	if delay > 0: tween.tween_interval(delay)
	tween.tween_method(func(count: float): control.visible_characters = int(count), 0.0, float(control.get_total_character_count()), duration(control, speed))
	tween.tween_callback(func(): control.visible_characters = -1)
	return tween

static func duration(control: Control, speed: float = SPEED) -> float:
	return clampf(control.get_total_character_count() / speed, 0.01, 2.0)

static func finish(control: Control) -> void:
	if control.has_meta("text_reveal_tween"):
		var tween: Tween = control.get_meta("text_reveal_tween")
		if tween != null and tween.is_valid(): tween.kill()
		control.remove_meta("text_reveal_tween")
	control.visible_characters = -1

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	controls.state_factory = _new_state
	controls.hidden.connect(_hide)
	controls.removed.connect(_hide)
	add_child(controls)

func _new_state(_control: Control) -> Dictionary:
	return {"text": "", "visible": false, "elapsed": 0.0, "active": false}

func _hide(control: Control, state: Dictionary) -> void:
	state.visible = false
	if control.has_meta("manual_text_reveal"): finish(control)
	elif state.active: _complete(control, state)

func _process(delta: float) -> void:
	var locale := TranslationServer.get_locale()
	var locale_changed := locale != _locale
	_locale = locale
	for state: Dictionary in controls.visible_states():
		var control: Control = state.ref.get_ref()
		if not is_instance_valid(control): continue
		if not control.has_meta("conversation_text") or control.has_meta("manual_text_reveal"): continue
		var shown := control.is_visible_in_tree()
		var copy: String = control.text
		if shown and not copy.is_empty() and (copy != state.text or not state.visible or locale_changed):
			state.elapsed = 0.0
			state.active = true
			control.visible_characters_behavior = TextServer.VC_CHARS_AFTER_SHAPING
		state.text = copy
		state.visible = shown
		if not shown or copy.is_empty():
			if state.active: _complete(control, state)
			continue
		if state.active:
			state.elapsed += delta
			control.visible_characters = int(state.elapsed * maxf(SPEED, control.get_total_character_count() / 2.0))
			if control.visible_characters >= control.get_total_character_count(): _complete(control, state)

func _complete(control: Control, state: Dictionary) -> void:
	state.active = false
	control.visible_characters = -1

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.echo: return
	var pressed: bool = (event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT) or (event is InputEventScreenTouch and event.pressed) or event.is_action_pressed("ui_accept")
	if not pressed: return
	for state: Dictionary in controls.visible_states():
		var control: Control = state.ref.get_ref()
		if not is_instance_valid(control) or not control.is_visible_in_tree(): continue
		if control.has_meta("manual_text_reveal"): finish(control)
		elif control.has_meta("conversation_text") and state.active: _complete(control, state)
