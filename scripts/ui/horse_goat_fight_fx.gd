extends Control
## Table choreography observes committed actions. It never chooses a card or scores.
var host: Control
var hud: Control
var cue_actions: Array[String] = []
var effect_kind := ""
var effect_time := 0.0
var effect_card_id := ""
var played_notes: Array[int] = []
var forced_card: TextureRect
var _state: Dictionary = {}
var _before: Dictionary = {}
var _identity := ""
var _action_stamp := ""
var _source := Vector2.ZERO
var _meld_id := -1
var _clock := 0.0
var _paused := false

func configure(owner: Control, boss_hud: Control) -> void:
	host = owner
	hud = boss_hud
	name = "HorseGoatFightFX"
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	forced_card = TextureRect.new()
	forced_card.name = "HorseForcedCard"
	forced_card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	forced_card.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	forced_card.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	forced_card.size = Vector2(48, 67)
	forced_card.pivot_offset = forced_card.size * 0.5
	add_child(forced_card)
	forced_card.hide()

func sync(state: Dictionary, identity: String) -> void:
	var id: String = state.get("id", "")
	if identity != _identity or id not in ["horse", "goat"]:
		clear_effects()
		_identity = identity
		_action_stamp = ""
		_state.clear()
		_before.clear()
	if state != _state: _before = _state.duplicate(true)
	_state = state.duplicate(true)
	cue_actions.clear()
	if id == "horse":
		if int(state.pair_count) >= int(ZodiacCatalog.tuning("horse", "matching_actions", state.difficulty)):
			cue_actions.append("discard")
		elif not String(state.required_action).is_empty():
			cue_actions.append(String(state.required_action))
		else: cue_actions.assign(["new_meld", "extension"])
	elif id == "goat":
		cue_actions.assign(["new_meld", "extension"])
	if id in ["horse", "goat"] and host.deal.state == DealState.STATE_FINAL_COMMIT_WINDOW:
		if cue_actions == ["discard"]:
			cue_actions.assign(["settle"] if id == "goat" else ["new_meld", "extension", "settle"])
		else: cue_actions.append("settle")
	queue_redraw()

func clear_effects() -> void:
	effect_kind = ""
	effect_time = 0
	effect_card_id = ""
	played_notes.clear()
	if forced_card != null: forced_card.hide()
	queue_redraw()

func pause_effects(paused: bool) -> void:
	_paused = paused

func present_action(result: Dictionary) -> void:
	if not result.get("ok", false) or _state.get("id", "") not in ["horse", "goat"]: return
	var action: String = result.get("action", "")
	var context := result.get("context") as ScoringContext
	var card := result.get("card") as CardData
	var stamp := "%s:%d:%d:%s" % [action, context.get_instance_id() if context != null else 0, host.deal.zodiac_boss.turn_serial, card.unique_id if card != null else ""]
	if action.is_empty() or stamp == _action_stamp: return
	_action_stamp = stamp
	if _state.id == "horse": _horse_action(result, context, card)
	elif context != null: _goat_action(result, context)

func _horse_action(result: Dictionary, context: ScoringContext, card: CardData) -> void:
	var blue := PresentationTheme.zodiac_color("horse")
	if context != null and context.action_type in ["new_meld", "extension"]:
		var matching := context.action_type == String(_state.required_action)
		hud.mechanic_guide.pair_reaction(ZodiacCatalog.words("Hoofbeat %d/2", "Nhịp vó %d/2") % int(_state.pair_count) if matching else ZodiacCatalog.words("Pair unchanged · next: ", "Cặp chưa tăng · tiếp: ") + ZodiacCatalog.action_label(_state.required_action), blue if matching else PresentationTheme.WARNING)
		effect_kind = "horse_stamp" if matching else "horse_mixed"
		effect_time = 0
		return
	if result.get("action", "") != "discard" or result.get("discard_kind", "") != DiscardRecord.KIND_MANDATORY or card == null: return
	var forced := false
	var grace := false
	for event: Dictionary in result.get("boss_events", []):
		if event.get("dragon_modifier", false): continue
		forced = forced or event.get("action", "") == "horse_forced_discard"
		grace = grace or event.get("action", "") == "horse_grace"
	if forced and result.get("forced_discard", false):
		effect_kind = "horse_forced"
		effect_card_id = card.unique_id
		var view := host.card_table.hand_views.get(card.unique_id) as Control
		_source = view.get_global_rect().get_center() - global_position if view != null else host.hand_layer.get_global_rect().get_center() - global_position
		forced_card.texture = load(card.texture_path())
		forced_card.show()
		hud.mechanic_guide.pair_reaction(ZodiacCatalog.words("Horse chose ", "Ngọ chọn ") + card.short_label(), PresentationTheme.WARNING)
	elif grace:
		effect_kind = "horse_grace"
		hud.mechanic_guide.pair_reaction(ZodiacCatalog.words("Grace used · your discard kept", "Đã dùng ân hạn · giữ lá bạn chọn"), blue)
	elif int(_before.get("pair_count", 0)) >= int(ZodiacCatalog.tuning("horse", "matching_actions", _state.difficulty)):
		effect_kind = "horse_protected"
		hud.mechanic_guide.pair_reaction(ZodiacCatalog.words("Pair complete · your discard kept ✓", "Đủ cặp · giữ lá bạn chọn ✓"), blue)
	else: return
	effect_time = 0

func _goat_action(result: Dictionary, context: ScoringContext) -> void:
	_meld_id = int(result.get("meld_id", -1))
	played_notes.clear()
	if context.suppression_reason == "goat_rank_miss":
		effect_kind = "goat_miss"
		hud.mechanic_guide.goat_staff.miss()
		hud.mechanic_guide.pair_reaction(ZodiacCatalog.words("Wrong melody · 0 VNĐ · next rank unchanged", "Sai hạng · 0 VNĐ · hạng tiếp chưa đổi"), PresentationTheme.DANGER)
	elif context.final_points > 0:
		var committed: Array[CardData] = context.added_cards if context.action_type == "extension" else context.cards
		for note: CardData in committed:
			if note.rank_index not in played_notes: played_notes.append(note.rank_index)
		played_notes.sort()
		effect_kind = "goat_notes"
		hud.mechanic_guide.goat_staff.celebrate(played_notes)
		var used_grace := int(_before.get("rhythm_grace", 0)) > int(_state.rhythm_grace)
		hud.mechanic_guide.pair_reaction((ZodiacCatalog.words("Grace used · next: ", "Đã dùng ân hạn · tiếp: ") if used_grace else ZodiacCatalog.words("Melody paid · next: ", "Đúng nhịp · tiếp: ")) + ZodiacCatalog.rank_window_text(int(_state.expected_rank)), PresentationTheme.zodiac_color("goat"))
	else: return
	effect_time = 0

func _process(delta: float) -> void:
	if _paused or not is_visible_in_tree(): return
	_clock += delta
	if not effect_kind.is_empty():
		effect_time += delta
		if effect_kind == "horse_forced":
			var p := clampf(effect_time / 1.15, 0, 1)
			var destination: Vector2 = host.discard_pile_visual.get_global_rect().get_center() - global_position
			forced_card.position = _arc_point(_source, destination, p) - forced_card.size * 0.5
			forced_card.rotation = sin(p * PI) * -0.35
			forced_card.modulate.a = minf(p * 8, (1 - p) * 6)
		if effect_time >= 1.4: clear_effects()
	queue_redraw()

func _arc_point(source: Vector2, destination: Vector2, p: float) -> Vector2:
	return source.lerp(destination, p) + Vector2(0, -sin(p * PI) * 48)

func _draw() -> void:
	if host == null or _state.get("id", "") not in ["horse", "goat"]: return
	var color := PresentationTheme.zodiac_color(_state.id)
	for action in cue_actions: _draw_cue(action, color)
	if effect_kind.is_empty(): return
	var p := clampf(effect_time / 1.4, 0, 1)
	var guide := hud.mechanic_guide as Control
	if effect_kind == "horse_forced":
		var destination: Vector2 = host.discard_pile_visual.get_global_rect().get_center() - global_position
		for streak in 7:
			var t := clampf((effect_time - streak * 0.04) / 1.15, 0, 1)
			var point := _arc_point(_source, destination, t)
			var previous := _arc_point(_source, destination, maxf(t - 0.07, 0))
			draw_line(previous + Vector2(0, streak * 4 - 12), point + Vector2(0, streak * 4 - 12), Color(color, (1 - p) * 0.5), 2, true)
		draw_arc(destination, 18 + p * 24, 0, TAU, 32, Color(PresentationTheme.WARNING, (1 - p) * 0.6), 2, true)
	elif effect_kind.begins_with("horse"):
		var point: Vector2 = guide.pair_art.get_global_rect().get_center() - global_position
		for wave in 3:
			draw_arc(point, 16 + p * 36 + wave * 5, 0, TAU, 36, Color(color, (1 - p) * 0.3), 1.5, true)
	elif effect_kind.begins_with("goat"):
		var staff: Control = guide.goat_staff
		var view := host.card_table.meld_views.get(_meld_id) as Control
		if view == null: return
		var source := view.get_global_rect().get_center() - global_position
		if effect_kind == "goat_miss":
			draw_arc(source, 18 + p * 32, 0, TAU, 32, Color(PresentationTheme.DANGER, (1 - p) * 0.6), 2, true)
		else:
			for i in played_notes.size():
				var destination := staff.global_position - global_position + Vector2((played_notes[i] - 0.5) * staff.size.x / 13, 17)
				var t := clampf((effect_time - i * 0.07) / 0.85, 0, 1)
				if t <= 0 or t >= 1: continue
				var point := _arc_point(source, destination, t)
				var previous := _arc_point(source, destination, maxf(t - 0.05, 0))
				draw_line(previous, point, Color(color, 0.5), 2, true)
				draw_circle(point, 4, color)
				draw_line(point + Vector2(3, 0), point + Vector2(3, -15), color, 2, true)
				draw_line(point + Vector2(3, -15), point + Vector2(9, -11), color, 2, true)

func _draw_cue(action: String, color: Color) -> void:
	var button: Button = host.ha_button if action == "new_meld" else host.extend_button if action == "extension" else host.settle_button if action == "settle" else host.discard_button
	if not button.is_visible_in_tree(): return
	var rect := button.get_global_rect().grow(3)
	rect.position -= global_position
	var ink := Color(color, 0.3 if button.disabled else 0.65 + sin(_clock * 3) * 0.25)
	for point in [rect.position, Vector2(rect.end.x, rect.position.y), rect.end, Vector2(rect.position.x, rect.end.y)]:
		var sx := 1 if point.x == rect.position.x else -1
		var sy := 1 if point.y == rect.position.y else -1
		draw_line(point, point + Vector2(sx * 9, 0), ink, 2, true)
		draw_line(point, point + Vector2(0, sy * 9), ink, 2, true)
