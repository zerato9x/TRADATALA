extends Control
## Replays committed transfers only; neither card selection nor wallet mutation lives here.
var host: Control
var hud: Control
var effect_kind := ""
var effect_time := 0.0
var flights: Array[Dictionary] = []
var completed_events := 0
var _queue: Array[Dictionary] = []
var _seen: Dictionary = {}
var _identity := ""
var _kind := ""
var _paused := false
var _duration := 1.5
var _event: Dictionary = {}
var caption: Label
const TIGER_REVEAL_SECONDS := 1.65
var hand_staging := false
var _swipe_started := false
var _tiger_announced := false

func configure(owner: Control, boss_hud: Control) -> void:
	host = owner
	hud = boss_hud
	name = "RatTigerFightFX"
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	z_index = 5
	caption = Label.new()
	caption.add_theme_font_size_override("font_size", 17)
	caption.add_theme_color_override("font_shadow_color", Color.BLACK)
	caption.add_theme_constant_override("shadow_offset_y", 2)
	caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	caption.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(caption)
	caption.hide()

func sync(state: Dictionary, identity: String) -> void:
	_kind = state.get("id", "")
	if identity != _identity or _kind not in ["rat", "tiger"]:
		clear_effects()
		_seen.clear()
		_identity = identity

func pause_effects(value: bool) -> void:
	_paused = value

func clear_effects() -> void:
	_queue.clear()
	_clear_flights()
	effect_kind = ""
	effect_time = 0
	if caption != null: caption.hide()
	queue_redraw()
	_finish_hand_stage()

func _finish_hand_stage() -> void:
	if not hand_staging: return
	hand_staging = false
	host.interactions.boss_presentation_locked = false
	host.card_table.finish_staged_hand()
	host._refresh_actions()
	hud.hunt_board.sync(host.deal.zodiac_boss.presentation())

func _clear_flights() -> void:
	for flight in flights:
		_restore_destination(flight)
		if is_instance_valid(flight.face):
			remove_child(flight.face)
			flight.face.queue_free()
	flights.clear()

func present_events(events: Array, stamp: String) -> void:
	if _kind not in ["rat", "tiger"] or events.is_empty(): return
	var key := stamp + JSON.stringify(events)
	if _seen.has(key): return
	_seen[key] = true
	var strike := {"action": "tiger_swipe", "transfers": [], "hand_before_ids": []}
	for event: Dictionary in events:
		if event.get("dragon_modifier", false): continue
		var action: String = event.get("action", "")
		if _kind == "tiger" and action == "boss_discard" and event.get("source", "") == "tiger":
			var transfer := event.duplicate(true)
			transfer["source_position"] = _source(event.card_id, "hand")
			strike.transfers.append(transfer)
			strike.hand_before_ids = event.get("hand_before_ids", [])
		elif _kind == "rat" and action in ["boss_meld", "boss_extension", "mouse_borrow_returned"]:
			var payload := event.duplicate(true)
			for transfer: Dictionary in payload.get("transfers", []):
				transfer["source_position"] = _source(transfer.card_id, transfer.origin)
			_queue.append(payload)
	if not strike.transfers.is_empty(): _queue.append(strike)
	if effect_kind.is_empty(): _next()

func _source(id: String, origin: String) -> Vector2:
	if origin == "stock": return host.draw_pile_visual.get_global_rect().get_center() - global_position
	var view := host.card_table.hand_views.get(id) as Control
	if view != null: return view.get_global_rect().get_center() - global_position
	if origin == "hand": return host.hand_layer.get_global_rect().get_center() - global_position
	for holder: Control in host.card_table.discard_history_target_holders.values():
		if holder.get_meta("action_target_card_id", "") == id: return holder.get_global_rect().get_center() - global_position
	return host.discard_pile_visual.get_global_rect().get_center() - global_position

func _next() -> void:
	_clear_flights()
	_finish_hand_stage()
	if _queue.is_empty():
		effect_kind = ""
		caption.hide()
		return
	_event = _queue.pop_front()
	effect_kind = _event.action
	effect_time = 0
	_duration = 1.65
	var accent := PresentationTheme.zodiac_color(_kind)
	caption.add_theme_color_override("font_color", accent)
	if effect_kind == "tiger_swipe":
		caption.text = ZodiacCatalog.words("TURN START · FULL HAND", "ĐẦU LƯỢT · ĐỦ BÀI")
		_tiger_announced = false
		hud.feedback_panel.hide()
		hud._speech_time = 0
		hud._speech_queue.clear()
		var full_hand: Array[CardData] = []
		var available: Array[CardData] = host.deal.hand.duplicate()
		available.append_array(host.deal.deck.discard_pile)
		for id in _event.hand_before_ids:
			for card in available:
				if card.unique_id == id: full_hand.append(card); break
		if not full_hand.is_empty():
			hand_staging = true
			_swipe_started = false
			host.interactions.boss_presentation_locked = true
			host.card_table.stage_hand(full_hand)
			host._refresh_actions()
	elif effect_kind == "mouse_borrow_returned":
		caption.text = ZodiacCatalog.words("No meld · %d cards returned", "Không có Phỏm · trả %d lá") % int(_event.get("borrowed_count", 0))
		var count := int(_event.get("borrowed_count", 0))
		for i in count:
			_add_flight({"card_id": "returned_%d" % i, "source_position": hud.hunt_board.card_target("") - global_position}, i, true)
	else:
		caption.text = (ZodiacCatalog.words("RAT MELD", "PHỎM CỦA TÝ") if effect_kind == "boss_meld" else ZodiacCatalog.words("RAT EXTENDS YOUR MELD", "TÝ NỐI PHỎM CỦA BẠN")) + "  −" + VndWallet.format_vnd(absi(int(_event.get("amount_vnd", 0))))
		if effect_kind == "boss_meld": hud.hunt_board.reveal_cards(_event.get("card_ids", []))
		var table_meld := host.card_table.meld_views.get(int(_event.get("meld_id", -1))) as Control
		if table_meld != null: host.meld_scroll.ensure_control_visible(table_meld)
	for i in _event.get("transfers", []).size(): _add_flight(_event.transfers[i], i)
	if effect_kind in ["boss_meld", "boss_extension"]:
		for i in int(_event.get("returned_count", 0)):
			_add_flight({"card_id": "returned_%d" % i, "source_position": hud.hunt_board.card_target("") - global_position}, i, true)
	_duration += maxf(flights.size() - 3, 0) * 0.07
	if effect_kind == "tiger_swipe": _duration += TIGER_REVEAL_SECONDS + 0.65
	caption.show()
	_update_visuals()

func _add_flight(transfer: Dictionary, index: int, returning: bool = false) -> void:
	var face := TextureRect.new()
	face.name = "BossCardFlight"
	face.mouse_filter = Control.MOUSE_FILTER_IGNORE
	face.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	face.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	face.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	var path: String = transfer.get("texture_path", "")
	if returning:
		face.texture = preload("res://cards/red_backing.png")
	elif ResourceLoader.exists(path): face.texture = load(path)
	face.size = Vector2(62, 87) if effect_kind == "tiger_swipe" else Vector2(48, 67)
	face.pivot_offset = face.size * 0.5
	add_child(face)
	var source: Vector2 = transfer.get("source_position", host.hand_layer.get_global_rect().get_center() - global_position)
	if effect_kind == "tiger_swipe" and source.is_equal_approx(host.hand_layer.get_global_rect().get_center() - global_position): source.x += (index - (_event.transfers.size() - 1) * 0.5) * 68
	var flight := {"face": face, "card_id": transfer.card_id, "source": source, "delay": index * 0.075 + (0.45 if returning and effect_kind != "mouse_borrow_returned" else 0.0), "returning": returning}
	if effect_kind == "boss_meld" and not returning:
		var owned := _table_card(transfer.card_id)
		if owned != null: owned.modulate.a = 0.18
	if effect_kind == "tiger_swipe":
		var slash := ColorRect.new()
		slash.mouse_filter = Control.MOUSE_FILTER_IGNORE
		slash.position = Vector2(-24, -24)
		slash.size = face.size + Vector2(48, 48)
		var ink := ShaderMaterial.new()
		ink.shader = preload("res://shaders/tiger_swipe.gdshader")
		slash.material = ink
		face.add_child(slash)
		flight["ink"] = ink
	flights.append(flight)

func _restore_destination(flight: Dictionary) -> void:
	var owned := _table_card(flight.card_id)
	if owned != null: owned.modulate.a = 1.0

func _table_card(card_id: String) -> Control:
	var view := host.card_table.meld_views.get(int(_event.get("meld_id", -1))) as MeldView
	return view.get_scoring_card_control(card_id) if view != null else null

func _destination(flight: Dictionary) -> Vector2:
	if flight.returning: return host.draw_pile_visual.get_global_rect().get_center() - global_position
	if effect_kind == "tiger_swipe": return host.discard_pile_visual.get_global_rect().get_center() - global_position
	if effect_kind in ["boss_meld", "boss_extension"]:
		var card := _table_card(flight.card_id)
		if card != null: return card.get_global_rect().get_center() - global_position
	return hud.hunt_board.card_target(flight.card_id) - global_position

func _process(delta: float) -> void:
	if _paused or not is_visible_in_tree() or effect_kind.is_empty(): return
	effect_time += delta
	if effect_kind == "tiger_swipe" and hand_staging and not _swipe_started and effect_time >= TIGER_REVEAL_SECONDS:
		_swipe_started = true
		caption.text = ZodiacCatalog.words("TIGER SWIPES", "DẦN VỒ BÀI")
		for flight in flights:
			var view := host.card_table.hand_views.get(flight.card_id) as Control
			if view != null:
				flight.source = view.get_global_rect().get_center() - global_position
				view.hide()
	if effect_kind == "tiger_swipe" and not _tiger_announced and effect_time >= TIGER_REVEAL_SECONDS + 0.8:
		_tiger_announced = true
		var labels: Array[String] = []
		for transfer: Dictionary in _event.transfers: labels.append(String(transfer.get("label", "")))
		hud._queue_speech(ZodiacCatalog.words("Snatched: ", "Ta vồ: ") + " · ".join(labels), "tiger:%s:%d" % [_identity, host.deal.zodiac_boss.turn_serial], true)
	_update_visuals()
	if effect_time >= _duration:
		completed_events += 1
		_next()
	queue_redraw()

func _update_visuals() -> void:
	caption.position = Vector2(host.meld_scroll.global_position.x - global_position.x, host.hand_layer.global_position.y - global_position.y - 30)
	caption.size = Vector2(host.meld_scroll.size.x, 24)
	caption.modulate.a = clampf((_duration - effect_time) * 4, 0, 1)
	for flight in flights:
		var t: float = effect_time - flight.delay
		if effect_kind == "tiger_swipe": t -= TIGER_REVEAL_SECONDS
		var p := clampf((t - (0.65 if effect_kind == "tiger_swipe" else 0.35 if flight.returning else 0.15)) / (1.15 if effect_kind == "tiger_swipe" else 0.88), 0, 1)
		var destination := _destination(flight)
		var point: Vector2 = flight.source.lerp(destination, smoothstep(0, 1, p)) + Vector2(0, -sin(p * PI) * 72)
		if flight.returning and t < 0.35:
			var borrow_p := clampf(t / 0.35, 0, 1)
			point = destination.lerp(flight.source, smoothstep(0, 1, borrow_p)) + Vector2(0, -sin(borrow_p * PI) * 40)
		var face: TextureRect = flight.face
		face.position = point - face.size * 0.5
		face.rotation = sin(p * PI) * (0.6 if effect_kind == "tiger_swipe" else -0.2)
		face.modulate.a = minf(clampf(t * 12, 0, 1), clampf((1 - p) * 6, 0, 1))
		if p >= 0.95: _restore_destination(flight)
		if flight.has("ink"): flight.ink.set_shader_parameter("progress", clampf((t - 0.1) / 0.85, 0, 1))

func _draw() -> void:
	if effect_kind.is_empty(): return
	var accent := PresentationTheme.zodiac_color(_kind)
	for flight in flights:
		var t: float = effect_time - flight.delay
		if effect_kind == "tiger_swipe": t -= TIGER_REVEAL_SECONDS
		var destination := _destination(flight)
		if effect_kind == "tiger_swipe" and t > 0.1 and t < 0.82:
			var p := clampf((t - 0.1) / 0.72, 0, 1)
			var center: Vector2 = flight.source + Vector2(92, -64).lerp(Vector2(-44, 46), p)
			var alpha := sin(p * PI)
			draw_circle(center, 18, Color("542315", alpha * 0.85))
			for claw in 4:
				var tip := center + Vector2(-17 + claw * 11, -18 + absf(claw - 1.5) * 4)
				draw_circle(tip, 8, Color(accent, alpha * 0.75))
				draw_line(tip + Vector2(17, -24), tip + Vector2(-12, 16), Color("fff0c7", alpha), 2, true)
			for spark in 7:
				var ray := Vector2.from_angle(spark * TAU / 7 + 0.4)
				draw_line(flight.source + ray * (12 + p * 30), flight.source + ray * (20 + p * 48), Color(accent, alpha * 0.6), 2, true)
		elif t > 0.15 and t < 1.05:
			var face: Control = flight.face
			draw_line(face.position + face.size * 0.5 + Vector2(10, 18), face.position + face.size * 0.5 + Vector2(25, 38), Color(accent, 0.45), 3, true)
		if t > 0.95 and t < 1.4:
			var p := (t - 0.95) / 0.45
			draw_arc(destination, 12 + p * 24, 0, TAU, 32, Color(accent, (1 - p) * 0.75), 2, true)
