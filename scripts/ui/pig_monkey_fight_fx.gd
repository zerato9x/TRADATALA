extends Control
## Committed-event choreography and action cues. Never a wallet or input owner.
const GOLD := Color("ffe099")
var host: Control
var hud: Control
var flight_kind := ""
var flight_amount := 0
var flight_time := 0.0
var flights: Array[Dictionary] = []
var cue_actions: Array[String] = []
var transfer_label: Label
var _state: Dictionary = {}
var _identity := ""
var _event_stamp := ""
var _action_stamp := 0
var _clock := 0.0
var _miss_action := ""
var _miss_time := 0.0
var _paused := false

func configure(owner: Control, boss_hud: Control) -> void:
	host = owner
	hud = boss_hud
	name = "PigMonkeyFightFX"
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	transfer_label = Label.new()
	transfer_label.name = "PigTransferAmount"
	transfer_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	transfer_label.add_theme_font_size_override("font_size", 14)
	transfer_label.add_theme_color_override("font_shadow_color", Color("150d16"))
	transfer_label.add_theme_constant_override("shadow_offset_x", 1)
	transfer_label.add_theme_constant_override("shadow_offset_y", 2)
	add_child(transfer_label)
	transfer_label.hide()

func sync(state: Dictionary, identity: String) -> void:
	var id: String = state.get("id", "")
	if identity != _identity or id not in ["pig", "monkey"]:
		clear_effects()
		_identity = identity
		_event_stamp = ""
		_action_stamp = 0
	_state = state.duplicate(true)
	cue_actions.clear()
	if id == "monkey":
		if not state.get("sequence", []).is_empty():
			cue_actions.append(String(state.required_action))
		else:
			var cap := int(ZodiacCatalog.tuning("monkey", "allowed_repeats", state.difficulty))
			for action in ["new_meld", "extension"]:
				if action != state.last_paid_action or int(state.repeat_count) < cap:
					cue_actions.append(action)
	queue_redraw()

func clear_effects() -> void:
	flights.clear()
	flight_kind = ""
	flight_time = 0
	_miss_time = 0
	if transfer_label != null: transfer_label.hide()
	if hud != null and hud.mechanic_guide != null:
		hud.mechanic_guide.pig_footer.hide()
	queue_redraw()

func pause_effects(paused: bool) -> void:
	_paused = paused

func present_action(result: Dictionary) -> void:
	if _state.get("id", "") != "monkey" or not result.get("ok", false): return
	var context := result.get("context") as ScoringContext
	if context == null or context.get_instance_id() == _action_stamp: return
	_action_stamp = context.get_instance_id()
	if context.suppression_reason == "monkey_rhythm_miss":
		_miss_action = context.action_type
		_miss_time = 0.8

func present_events(events: Array, stamp: String) -> void:
	if _state.get("id", "") != "pig" or events.is_empty(): return
	var key := stamp + JSON.stringify(events)
	if key == _event_stamp: return
	_event_stamp = key
	for event: Dictionary in events:
		if event.get("action", "") not in ["pig_siphon", "pig_return", "pig_bank_loss"] or event.get("dragon_modifier", false): continue
		if int(event.get("amount_vnd", 0)) <= 0: continue
		flights.append(event.duplicate(true))
	# Receipts can contain multiple payouts; keep the visual queue bounded.
	if flights.size() > 16: flights = flights.slice(-16)

func _process(delta: float) -> void:
	if _paused or not is_visible_in_tree(): return
	_clock += delta
	_miss_time = maxf(_miss_time - delta, 0)
	if flight_kind.is_empty() and not flights.is_empty():
		var event: Dictionary = flights.pop_front()
		flight_kind = String(event.action)
		flight_amount = int(event.amount_vnd)
		flight_time = 0
		hud.mechanic_guide.pig_vault.react()
		var returning := flight_kind == "pig_return"
		transfer_label.text = (ZodiacCatalog.words("RETURN ", "HOÀN ") if returning else ZodiacCatalog.words("HELD ", "GIỮ ") if flight_kind == "pig_siphon" else ZodiacCatalog.words("COLLECTED ", "ĐÃ THU ")) + VndWallet.format_vnd(flight_amount)
		transfer_label.add_theme_color_override("font_color", PresentationTheme.MONEY_GAIN if returning else PresentationTheme.DANGER if flight_kind == "pig_bank_loss" else GOLD)
		transfer_label.show()
	if not flight_kind.is_empty():
		flight_time += delta
		var p := clampf(flight_time / 1.15, 0, 1)
		var footer: Label = hud.mechanic_guide.pig_footer
		footer.hide()
		transfer_label.position = hud.mechanic_guide.pig_terms.global_position - global_position + Vector2(0, -sin(p * PI) * 2)
		transfer_label.modulate.a = minf(p * 8, (1.0 - p) * 5)
		if p >= 1:
			flight_kind = ""
			transfer_label.hide()
			footer.hide()
	queue_redraw()

func _vault_position() -> Vector2:
	return hud.mechanic_guide.pig_vault.get_global_rect().get_center() - global_position

func _draw() -> void:
	if host == null: return
	if _state.get("id", "") == "monkey":
		for action in cue_actions: _draw_action_cue(action, false)
		if _miss_time > 0: _draw_action_cue(_miss_action, true)
	if flight_kind.is_empty(): return
	var returning := flight_kind == "pig_return"
	var loss := flight_kind == "pig_bank_loss"
	var vault := _vault_position()
	var wallet: Vector2 = host.campaign_money_hud.panel.get_global_rect().get_center() - global_position
	var source: Vector2 = vault if returning else wallet
	var destination: Vector2 = wallet if returning else vault
	var color := PresentationTheme.DANGER if loss else PresentationTheme.MONEY_GAIN if returning else GOLD
	# A low-opacity path, arcing only through the header and the boss lane.
	var trail := PackedVector2Array()
	for i in 33:
		trail.append(_flight_point(source, destination, i / 32.0))
	draw_polyline(trail, Color(color, 0.12), 1, true)
	for coin in 9:
		var p := clampf((flight_time - coin * 0.035) / 0.72, 0, 1)
		if p <= 0 or p >= 1: continue
		var point := _flight_point(source, destination, p) + Vector2(0, sin(coin * 2.4) * 4)
		var previous := _flight_point(source, destination, maxf(p - 0.04, 0))
		draw_line(previous, point, Color(color, 0.45), 2, true)
		var radius := 4.0 + sin(p * PI) * 1.5
		draw_circle(point, radius + 2, Color(color, 0.15))
		draw_circle(point, radius, color.darkened(0.3))
		draw_arc(point, radius, 0, TAU, 16, color, 1.3, true)
		draw_line(point + Vector2(0, -2), point + Vector2(0, 2), color, 1, true)
	var arrival := clampf((flight_time - 0.65) / 0.5, 0, 1)
	if arrival > 0 and arrival < 1:
		draw_arc(destination, 10 + arrival * 22, 0, TAU, 32, Color(color, (1 - arrival) * 0.6), 1.5, true)

func _flight_point(source: Vector2, destination: Vector2, progress: float) -> Vector2:
	var point := source.lerp(destination, progress)
	point.y -= sin(progress * PI) * 22
	return point

func _draw_action_cue(action: String, miss: bool) -> void:
	var button: Button = host.ha_button if action == "new_meld" else host.extend_button if action == "extension" else host.discard_button
	if not button.is_visible_in_tree(): return
	var rect := button.get_global_rect().grow(3)
	rect.position -= global_position
	var pulse := 0.5 + 0.5 * sin(_clock * 3)
	var color := PresentationTheme.DANGER if miss else Color(GOLD, 0.45 if button.disabled else 0.7 + pulse * 0.25)
	var corner := 9.0
	for point in [rect.position, Vector2(rect.end.x, rect.position.y), rect.end, Vector2(rect.position.x, rect.end.y)]:
		var sx := 1 if point.x == rect.position.x else -1
		var sy := 1 if point.y == rect.position.y else -1
		draw_line(point, point + Vector2(sx * corner, 0), color, 2, true)
		draw_line(point, point + Vector2(0, sy * corner), color, 2, true)
	if not miss:
		var x := rect.position.x + fmod(_clock * 28, rect.size.x)
		draw_circle(Vector2(x, rect.end.y), 2.5, color)
