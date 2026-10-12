extends Control
## Animates committed forced discards; physical cards and turns stay in DealState.
var host: Control
var flights: Array[Dictionary] = []
var effect_time := 0.0
var effect_kind := ""
var _seen := {}
var _identity := ""
var _paused := false
var _snake := false
var caption: Label

func configure(owner: Control) -> void:
	host = owner
	name = "SnakeFightFX"
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	z_index = 5
	caption = Label.new()
	caption.set_meta("zodiac_id", "snake")
	caption.mouse_filter = Control.MOUSE_FILTER_IGNORE
	caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	caption.add_theme_font_size_override("font_size", 15)
	caption.add_theme_color_override("font_color", PresentationTheme.zodiac_color("snake"))
	caption.add_theme_constant_override("outline_size", 3)
	caption.add_theme_color_override("font_outline_color", Color("0b1a12"))
	add_child(caption)
	caption.hide()

func sync(state: Dictionary, identity: String) -> void:
	_snake = state.get("id", "") == "snake"
	if identity != _identity or not _snake:
		clear_effects()
		_seen.clear()
		_identity = identity

func pause_effects(value: bool) -> void:
	_paused = value

func clear_effects() -> void:
	for flight in flights:
		if is_instance_valid(flight.face): flight.face.queue_free()
	flights.clear()
	effect_kind = ""
	effect_time = 0
	if caption != null: caption.hide()
	queue_redraw()

func _source(id: String, meld_id: int) -> Vector2:
	var meld: MeldView = host.card_table.meld_views.get(meld_id)
	if is_instance_valid(meld):
		var card := meld.get_scoring_card_control(id)
		if is_instance_valid(card): return card.get_global_rect().get_center() - global_position
	var card: Control = host.card_table.hand_views.get(id)
	if is_instance_valid(card): return card.get_global_rect().get_center() - global_position
	return host.hand_layer.get_global_rect().get_center() - global_position

func present_events(events: Array, stamp: String) -> void:
	if not _snake: return
	var key := stamp + JSON.stringify(events)
	if _seen.has(key): return
	_seen[key] = true
	var transfers: Array[Dictionary] = []
	var meld_id := -1
	for event: Dictionary in events:
		var action: String = event.get("action", "")
		if event.get("source", "") not in ["snake", "snake_charm"]: continue
		if action == "boss_discard_meld":
			meld_id = int(event.meld_id)
			transfers.append_array(event.transfers)
		elif action == "boss_discard": transfers.append(event)
	if transfers.is_empty(): return
	clear_effects()
	effect_kind = "meld_discard" if meld_id >= 0 else "card_discard"
	caption.text = ZodiacCatalog.words("MELD #%d · DISCARDED", "PHỎM #%d · ĐÃ BỎ") % meld_id if meld_id >= 0 else ""
	var center: Vector2 = host.meld_scroll.get_global_rect().get_center() - global_position
	center.y = host.meld_scroll.get_global_rect().position.y - global_position.y + 80
	var meld_count := transfers.filter(func(transfer: Dictionary): return int(transfer.get("meld_id", -1)) == meld_id).size() if meld_id >= 0 else 0
	var meld_index := 0
	var seen_cards := {}
	for transfer: Dictionary in transfers:
		var id: String = transfer.card_id
		if seen_cards.has(id): continue
		seen_cards[id] = true
		var face := TextureRect.new()
		face.name = "SnakeDiscard_" + id
		face.texture = load(String(transfer.texture_path))
		face.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		face.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		face.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		face.size = Vector2(72, 100)
		face.pivot_offset = face.size * 0.5
		face.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(face)
		var charm := ColorRect.new()
		charm.mouse_filter = Control.MOUSE_FILTER_IGNORE
		charm.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		var ink := ShaderMaterial.new()
		ink.shader = preload("res://shaders/snake_command.gdshader")
		ink.set_shader_parameter("strike", 1.0)
		charm.material = ink
		face.add_child(charm)
		var source := _source(id, int(transfer.get("meld_id", -1)))
		var stage := source
		var card_meld_id := int(transfer.get("meld_id", -1))
		if meld_id >= 0 and card_meld_id == meld_id:
			stage = center + Vector2((meld_count - 1) * -28 + meld_index * 56, 0)
			meld_index += 1
		flights.append({"card_id": id, "meld_id": card_meld_id, "face": face, "source": source, "stage": stage})
		face.position = source - face.size * 0.5
	caption.position = center + Vector2(-180, -76)
	caption.size = Vector2(360, 24)
	caption.visible = meld_id >= 0
	queue_redraw()

func _process(delta: float) -> void:
	if not visible or _paused or effect_kind.is_empty(): return
	effect_time += delta
	var poison := clampf(effect_time / 0.25, 0, 1)
	var release := clampf((effect_time - 0.45) / 0.65, 0, 1)
	var eased := release * release * (3 - 2 * release)
	var destination: Vector2 = host.discard_pile_visual.get_global_rect().get_center() - global_position
	for index in flights.size():
		var flight: Dictionary = flights[index]
		var start: Vector2 = flight.source.lerp(flight.stage, poison)
		var position: Vector2 = start.lerp(destination, eased)
		position.y -= sin(release * PI) * (55 + index * 6)
		flight.face.position = position - flight.face.size * 0.5
		flight.face.scale = Vector2.ONE * lerpf(1.0, 0.72, release)
		flight.face.rotation = sin(effect_time * 13 + index) * 0.018 + release * 0.12
		flight.face.modulate.a = 1.0 - clampf((release - 0.84) / 0.16, 0, 1)
	caption.modulate.a = 1.0 - release
	queue_redraw()
	if effect_time >= 1.1: clear_effects()

func _draw() -> void:
	if effect_kind.is_empty(): return
	for flight in flights:
		if not is_instance_valid(flight.face): continue
		var center: Vector2 = flight.face.position + flight.face.size * 0.5
		var points := PackedVector2Array()
		for step in 36:
			var angle := step / 35.0 * TAU * 1.2 + effect_time * 4
			points.append(center + Vector2(cos(angle) * 42, sin(angle) * 57))
		var alpha := (1 - clampf((effect_time - 0.4) / 0.6, 0, 1)) * 0.68
		draw_polyline(points, Color(0.18, 0.91, 0.44, alpha * 0.3), 7, true)
		draw_polyline(points, Color(0.58, 1.0, 0.42, alpha), 2, true)
