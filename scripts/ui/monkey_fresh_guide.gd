extends Control
## Two scoring tracks. All eligibility comes from Monkey's paid-action state.
const GOLD := Color("ffe078")
const ACTIONS := ["new_meld", "extension"]
var active := false
var lane_height := 78.0
var caption: Label
var hint: Label
var row: HBoxContainer
var choices: Array[Label] = []
var available_actions: Array[String] = []
var _identity := ""
var _last := ""
var _count := 0
var _cap := 1
var _clock := 0.0
var _flash := 0.0
var _flash_action := ""
var _miss := false
var _notice_time := 0.0
var _normal_hint := ""
var _action_stamp := 0
var _paused := false

func _ready() -> void:
	name = "MonkeyFreshGuide"
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	caption = _label(12)
	caption.name = "FreshNextAction"
	add_child(caption)
	row = HBoxContainer.new()
	row.position.y = 19
	row.add_theme_constant_override("separation", 34)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(row)
	for action in ACTIONS:
		var choice := _label(18)
		choice.name = "FreshMeld" if action == "new_meld" else "FreshExtend"
		row.add_child(choice)
		choices.append(choice)
	hint = _label(12)
	hint.name = "FreshFeedback"
	hint.position.y = 58
	add_child(hint)
	hide()

func _label(pixels: int) -> Label:
	var label := Label.new()
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.add_theme_font_size_override("font_size", pixels)
	label.add_theme_color_override("font_shadow_color", Color("171017"))
	label.add_theme_constant_override("shadow_offset_y", 2)
	return label

func sync(state: Dictionary, identity: String) -> void:
	active = state.get("id", "") == "monkey" and state.get("sequence", []).is_empty()
	visible = active
	if not active:
		clear_effects()
		_identity = ""
		return
	if _identity != identity:
		clear_effects()
		_identity = identity
		_action_stamp = 0
	_last = String(state.get("last_paid_action", ""))
	_count = int(state.get("repeat_count", 0))
	_cap = int(ZodiacCatalog.tuning("monkey", "allowed_repeats", state.difficulty))
	available_actions.clear()
	for i in ACTIONS.size():
		var allowed: bool = ACTIONS[i] != _last or _count < _cap
		if allowed: available_actions.append(ACTIONS[i])
		choices[i].text = ZodiacCatalog.action_label(ACTIONS[i]).to_upper() + (" [H]" if i == 0 else " [E]")
		choices[i].add_theme_color_override("font_color", GOLD if allowed else PresentationTheme.DANGER)
		choices[i].modulate.a = 1.0 if allowed else 0.7
	caption.text = ZodiacCatalog.words("CHAIN %d/%d", "CHUỖI %d/%d") % [_count, _cap]
	caption.add_theme_color_override("font_color", GOLD)
	_normal_hint = ""
	if _notice_time <= 0: hint.text = _normal_hint
	queue_redraw()

func fit_width(width: float) -> void:
	var pixels := 18
	while pixels > 12:
		var needed := 34.0
		for choice in choices:
			needed += choice.get_theme_font("font").get_string_size(choice.text, HORIZONTAL_ALIGNMENT_LEFT, -1, pixels).x
		if needed <= width: break
		pixels -= 1
	for choice in choices: choice.add_theme_font_size_override("font_size", pixels)
	row.size = Vector2(width, 26)
	hint.size.x = width
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	caption.size.x = width
	caption.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hint.add_theme_font_size_override("font_size", 11)
	hint.hide()
	lane_height = 55
	size = Vector2(width, lane_height)

func present_action(result: Dictionary) -> void:
	if not active or not result.get("ok", false): return
	var context := result.get("context") as ScoringContext
	if context == null or context.get_instance_id() == _action_stamp: return
	_action_stamp = context.get_instance_id()
	if context.action_type not in ACTIONS: return
	_miss = context.suppression_reason == "monkey_rhythm_miss"
	if not _miss and context.final_points <= 0: return
	_flash_action = context.action_type
	_flash = 1.0
	_notice_time = 1.6
	hint.text = ZodiacCatalog.words("0 VNĐ · switch action to score", "0 VNĐ · đổi hành động để ghi điểm") if _miss else ZodiacCatalog.words("FRESH ✓ · paid action recorded", "FRESH ✓ · đã ghi hành động trả thưởng")
	hint.add_theme_color_override("font_color", PresentationTheme.DANGER if _miss else PresentationTheme.MONEY_GAIN)

func clear_effects() -> void:
	_flash = 0.0
	_notice_time = 0.0
	for choice in choices:
		choice.position.y = 0
		choice.scale = Vector2.ONE
	if hint != null:
		hint.text = _normal_hint
		hint.add_theme_color_override("font_color", PresentationTheme.MUTED)

func pause_effects(paused: bool) -> void:
	_paused = paused

func _process(delta: float) -> void:
	if not is_visible_in_tree() or _paused: return
	_clock += delta
	_flash = move_toward(_flash, 0, delta * 2.2)
	_notice_time = maxf(_notice_time - delta, 0)
	if _notice_time <= 0:
		hint.text = _normal_hint
		hint.add_theme_color_override("font_color", PresentationTheme.MUTED)
	for i in choices.size():
		var amount := _flash if ACTIONS[i] == _flash_action else 0.0
		choices[i].position.y = sin((1.0 - amount) * PI) * -4.0 if not _miss else sin(_clock * 36) * amount * 2
	queue_redraw()

func _draw() -> void:
	for i in choices.size():
		var center := row.position + choices[i].position + Vector2(choices[i].size.x * 0.5, 31)
		var used := _count if ACTIONS[i] == _last else 0
		var allowed: bool = ACTIONS[i] in available_actions
		var color := GOLD if allowed else PresentationTheme.DANGER
		for beat in _cap:
			var point := center + Vector2((beat - (_cap - 1) * 0.5) * 15, 0)
			draw_circle(point, 4, color.darkened(0.75))
			draw_arc(point, 4, 0, TAU, 16, color, 1, true)
			if beat < used: draw_circle(point, 2.5, color)
		if not allowed:
			draw_line(center + Vector2(-14, -3), center + Vector2(14, 3), color, 1.5, true)
		elif used == 0:
			var pulse := 0.5 + 0.5 * sin(_clock * 3)
			draw_arc(center, 11 + pulse * 2, PI * 0.1, PI * 0.9, 16, Color(color, 0.25 + pulse * 0.25), 1, true)
