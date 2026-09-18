class_name MoneyPresentation
extends Control

signal impact_requested(intensity: float, positive: bool)
signal transfer_requested

const DENOMINATIONS: Array[int] = [500_000, 200_000, 100_000, 50_000, 20_000, 10_000, 5_000, 2_000, 1_000]
const DENOMINATION_TEXTURES := {
	500_000: preload("res://assets/money/bill_500k.png"),
	200_000: preload("res://assets/money/bill_200k.png"),
	100_000: preload("res://assets/money/bill_100k.png"),
	50_000: preload("res://assets/money/bill_50k.png"),
	20_000: preload("res://assets/money/bill_20k.png"),
	10_000: preload("res://assets/money/bill_10k.png"),
	5_000: preload("res://assets/money/bill_5k.png"),
	2_000: preload("res://assets/money/bill_2k.png"),
	1_000: preload("res://assets/money/bill_1k.png"),
}
const MAX_TRANSACTION_OBJECTS := 8
const MAX_WALLET_OBJECTS := 9
const MONEY_REVEAL_GAP := 0.025
const MONEY_REVEAL_LEAD_IN := 0.14
const MONEY_FLIGHT_DURATION := 0.48
const MONEY_BILL_STAGGER := 0.04
const MONEY_BILL_FADE_DURATION := 0.08
const MONEY_SETTLE_DELAY := 0.16
const MONEY_CEREMONY_FADE_DURATION := 0.14
var ceremony: Control
var score_panel: Control
var title_label: Label
var line_a_label: Label
var line_b_label: Label
var payout_label: Label
var bill_layer: Control

var wallet_label: Label
var wallet_pile_anchor: Control
var presentation_active := false
var peak_transaction_object_count := 0

var _rng := RandomNumberGenerator.new()
var _scoring_generation := 0
var _scoring_layout: Array[Vector2] = []
var _scoring_face: TextureRect
var _scoring_fade: Tween
var _scoring_shakes: Dictionary = {}
var _stacked_gain := 0
var _major_tweens: Array[Tween] = []
var _major_nodes: Array[Node] = []


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_rng.seed = 0xB17B17
	_build_runtime_ui()


func configure(exact_wallet_label: Label, pile_anchor: Control) -> void:
	wallet_label = exact_wallet_label
	wallet_pile_anchor = pile_anchor


func sync_wallet(balance_vnd: int) -> void:
	if wallet_label != null:
		wallet_label.text = VndWallet.format_vnd(balance_vnd)
	_rebuild_wallet_pile(balance_vnd)


func present_scoring(event: Dictionary) -> void:
	_scoring_generation += 1
	var generation := _scoring_generation
	presentation_active = true
	ceremony.visible = true
	_reset_ceremony()
	var source: Control = event.get("source_control") if is_instance_valid(event.get("source_control")) else null
	_position_score_stage(source, 0.90)
	# Compact receipt above the table; no backdrop or input-catching surface.
	var labels := [title_label, line_a_label, line_b_label, payout_label]
	var old_positions: Array[Vector2] = []
	for label: Label in labels:
		old_positions.append(label.position)
		label.scale = Vector2.ONE * 0.78
	title_label.position.y = 0.0
	line_a_label.position.y = 22.0
	line_b_label.position.y = 45.0
	payout_label.position.y = 69.0
	var face := TextureRect.new()
	face.position = Vector2(20, 22)
	face.size = Vector2(63, 88)
	face.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	face.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	face.mouse_filter = Control.MOUSE_FILTER_IGNORE
	face.visible = false
	_scoring_layout = old_positions
	_scoring_face = face
	var hits: Array = event.get("hits", [])
	var triggered_cards := 0
	_stacked_gain = 0
	var running_wallet := int(event.get("start_wallet_vnd", 0))
	var running_gain := 0
	var locator: Callable = event.get("card_locator", Callable())

	for index in hits.size():
		var hit: Dictionary = hits[index]
		var card_id := String(hit.get("card_id", ""))
		var card_control: Control = locator.call(card_id) if locator.is_valid() and not card_id.is_empty() else null
		var reveal: Callable = event.get("reveal_card", Callable())
		if reveal.is_valid() and is_instance_valid(card_control):
			await reveal.call(card_control)
			if generation != _scoring_generation:
				return
			card_control = locator.call(card_id) if locator.is_valid() else null
			if is_instance_valid(card_control):
				_position_score_stage(card_control, 0.90)
		var property_id := String(hit.get("property", ""))
		var relic_hit := String(hit.get("kind", "")) == "relic"
		if relic_hit:
			var relic_cue: Callable = event.get("relic_cue", Callable())
			if relic_cue.is_valid():
				relic_cue.call(String(hit.relic_id))
		var replay := String(hit.get("kind", "")) == "meld_retrigger"
		var card_trigger := String(hit.get("kind", "")) in ["card", "card_retrigger"]
		var interval := 0.65 if relic_hit else scoring_hit_interval(triggered_cards)
		if replay:
			interval = maxf(0.14, 0.30 - float(hit.get("echo", 0)) * 0.025)
		var flow := property_id == GieoQueService.PROPERTY_MELD_RETRIGGER
		var accent := Color("#79d9cf") if flow else Color("#f5bf42")
		if is_instance_valid(card_control):
			_shake_scoring_card(card_control, accent, interval)
		var texture_path := String(hit.get("texture_path", ""))
		if not texture_path.is_empty():
			face.texture = load(texture_path) as Texture2D
			GieoCardFX.apply_properties(face, hit.get("properties", []), bool(hit.get("shiny", false)))
		if not is_instance_valid(card_control) and (card_trigger or (replay and not card_id.is_empty())):
			if face.get_parent() == null:
				score_panel.add_child(face)
			face.show()
			_shake_scoring_card(face, accent, interval)
		var pass_number := int(hit.get("pass", 1))
		var heading := String(event.get("title", ""))
		if pass_number > 1:
			heading += "  /  " + tr("SCORE_PASS") % pass_number
		_set_label_text(title_label, heading, PresentationTheme.MUTED)
		var cue := String(hit.get("label", ""))
		if replay:
			cue = tr("SCORE_MELD_REPLAY") if not flow else tr("SCORE_LIQUID_ECHO") % int(hit.get("echo", 1))
		elif not property_id.is_empty():
			cue = tr(CardData.gieo_property_label_key(property_id)) + " · " + tr("SCORE_GOLD_AGAIN")
		elif String(hit.get("kind", "")) == "meld_delta":
			cue = tr("SCORE_MELD_DELTA")
		elif String(hit.get("kind", "")) == "modifier":
			cue = tr("SCORE_ADJUSTMENT")
		if relic_hit:
			cue = tr("RELIC_BONUS_RECEIPT") % [hit.label, int(hit.points)]
		_set_label_text(line_a_label, cue if relic_hit or replay or not property_id.is_empty() else "", accent if relic_hit or replay or not property_id.is_empty() else Color("#f8edd0"))
		var amount := int(hit.get("amount_vnd", 0))
		running_wallet += amount
		running_gain += amount
		_set_label_text(line_b_label, VndWallet.format_vnd(amount, true) if not replay else "", accent)
		_set_label_text(payout_label, VndWallet.format_vnd(running_gain, true), PresentationTheme.TEA)
		for label: Label in labels:
			label.modulate = Color.WHITE
		# The displayed wallet receives this resolution only when its stack lands.
		# Cap concurrent bills and audio. Every hit still contributes to the receipt.
		if amount != 0:
			_launch_scoring_bill(amount)
		if index == 0 or replay or index % maxi(1, ceili(0.09 / interval)) == 0:
			impact_requested.emit(0.65 if not replay else 1.0, amount >= 0)
		if card_trigger:
			triggered_cards += 1
		# Wait from this actual hit, never catch up by skipping visible card beats.
		if not await _wait_scoring_tail(interval, generation):
			return
	_fly_scoring_stack()
	if not await _wait_scoring_tail(MONEY_FLIGHT_DURATION, generation):
		return
	_scoring_fade = create_tween()
	_scoring_fade.tween_property(score_panel, "modulate:a", 0.0, 0.10)
	if not await _wait_scoring_tail(0.10, generation):
		return
	_restore_scoring_layout()
	ceremony.visible = false
	sync_wallet(int(event.get("target_wallet_vnd", running_wallet)))
	presentation_active = false


func _wait_scoring_tail(seconds: float, generation: int) -> bool:
	var deadline := Time.get_ticks_msec() + roundi(seconds * 1000.0)
	while Time.get_ticks_msec() < deadline:
		await get_tree().process_frame
		if generation != _scoring_generation:
			return false
	return generation == _scoring_generation


func _restore_scoring_layout() -> void:
	for card_id in _scoring_shakes.keys():
		_finish_scoring_shake(card_id)
	for tween: Tween in [_scoring_fade]:
		if tween != null and tween.is_valid():
			tween.kill()
	_scoring_fade = null
	if is_instance_valid(_scoring_face):
		_scoring_face.queue_free()
	_scoring_face = null
	var labels := [title_label, line_a_label, line_b_label, payout_label]
	for index in _scoring_layout.size():
		labels[index].position = _scoring_layout[index]
	_scoring_layout.clear()


func _shake_scoring_card(face: Control, accent: Color, interval: float) -> void:
	var card_id := face.get_instance_id()
	_finish_scoring_shake(card_id)
	var baseline_rotation := face.rotation
	var baseline_color := face.modulate
	var baseline_pivot := face.pivot_offset
	face.pivot_offset = face.size * 0.5
	face.modulate = baseline_color.lerp(accent, 0.40)
	var duration := minf(0.27, interval * 0.85)
	var angle := deg_to_rad(7.0)
	var tween := face.create_tween()
	_scoring_shakes[card_id] = {
		"face": face, "rotation": baseline_rotation, "pivot": baseline_pivot,
		"color": baseline_color, "tween": tween,
	}
	# Rotation leaves layout and the music-driven scale pulse independent.
	face.rotation = baseline_rotation - angle
	tween.tween_property(face, "rotation", baseline_rotation + angle, duration * 0.25)
	tween.tween_property(face, "rotation", baseline_rotation - angle * 0.55, duration * 0.25)
	tween.tween_property(face, "rotation", baseline_rotation + angle * 0.25, duration * 0.25)
	tween.tween_property(face, "rotation", baseline_rotation, duration * 0.25)
	tween.tween_callback(_finish_scoring_shake.bind(card_id))


func _finish_scoring_shake(card_id: int) -> void:
	if not _scoring_shakes.has(card_id):
		return
	var state: Dictionary = _scoring_shakes[card_id]
	_scoring_shakes.erase(card_id)
	var tween: Tween = state["tween"]
	if tween != null and tween.is_valid():
		tween.kill()
	var face: Control = state["face"] if is_instance_valid(state["face"]) else null
	if face != null:
		face.rotation = state["rotation"]
		face.pivot_offset = state["pivot"]
		face.modulate = state["color"]

func _launch_scoring_bill(amount: int) -> void:
	_stacked_gain += amount
	# Rebuild a bounded, denomination-correct stack from the accumulated receipt.
	for child in bill_layer.get_children():
		bill_layer.remove_child(child)
		child.queue_free()
	var breakdown := denomination_breakdown(absi(_stacked_gain))
	for index in mini(breakdown.size(), MAX_TRANSACTION_OBJECTS):
		var entry: Dictionary = breakdown[index]
		var bill := _new_bill_stack(int(entry["denomination"]), int(entry["count"]), Vector2(48, 21))
		bill_layer.add_child(bill)
		bill.position = score_panel.position + Vector2(185 + index * 8, 132 - index * 2)
	peak_transaction_object_count = maxi(peak_transaction_object_count, bill_layer.get_child_count())


func _fly_scoring_stack() -> void:
	if bill_layer.get_child_count() > 0:
		transfer_requested.emit()
	for bill: Control in bill_layer.get_children():
		var from := bill.position
		var to := _control_center(wallet_pile_anchor)
		if _stacked_gain < 0:
			to = from
			from = _control_center(wallet_pile_anchor)
		var control := (from + to) * 0.5 + Vector2(0, -65)
		var flight := bill.create_tween().set_parallel(true)
		flight.tween_method(_set_bill_curve_position.bind(bill, from, control, to), 0.0, 1.0, MONEY_FLIGHT_DURATION)
		flight.tween_property(bill, "scale", Vector2.ONE * 0.5, MONEY_FLIGHT_DURATION)
		flight.tween_property(bill, "modulate:a", 0.0, 0.08).set_delay(MONEY_FLIGHT_DURATION - 0.08)
		flight.chain().tween_callback(bill.queue_free)

func present_transaction(event: Dictionary) -> void:
	if String(event.get("reason", "")) in ["u", "u_khan", "exhaustion"]:
		await present_major_event(event)
		return
	presentation_active = true
	ceremony.visible = true
	_position_score_stage(event.get("source_control") as Control)
	_reset_ceremony()
	var positive := String(event.get("direction", "gain")) != "loss"
	var intensity := clampf(float(event.get("intensity", 1.0)), 0.45, 2.0)
	var title := String(event.get("title", ""))
	var steps: Array = event.get("steps", [])
	var payout := String(event.get("payout", ""))
	var amount_vnd := absi(int(event.get("amount_vnd", 0)))
	var start_wallet_vnd := int(event.get("start_wallet_vnd", 0))
	var target_wallet_vnd := int(event.get("target_wallet_vnd", start_wallet_vnd))
	var source := event.get("source_control") as Control
	var destination := event.get("destination_control") as Control

	_set_label_text(title_label, title, Color("#f5bf42"))
	if not title.is_empty():
		await _pop_label(title_label, 0.11, 1.0 + 0.04 * intensity)
	if not steps.is_empty():
		_set_label_text(line_a_label, String(steps[0]), Color("#f8edd0"))
		await _pop_label(line_a_label, 0.12, 1.02 + 0.05 * intensity)
	if steps.size() > 1:
		_set_label_text(line_b_label, String(steps[1]), Color("#f5bf42"))
		await _pop_label(line_b_label, 0.11, 1.06 + 0.06 * intensity)
	_set_label_text(payout_label, payout, PresentationTheme.TEA if positive else PresentationTheme.RED)
	await _pop_label(payout_label, 0.14, 1.12 + 0.08 * intensity)
	_nudge_score_panel(intensity)
	impact_requested.emit(intensity, positive)
	await _move_money(amount_vnd, positive, source, destination, start_wallet_vnd, target_wallet_vnd, intensity)
	await get_tree().create_timer(MONEY_SETTLE_DELAY).timeout
	await _fade_ceremony(MONEY_CEREMONY_FADE_DURATION)
	sync_wallet(target_wallet_vnd)
	presentation_active = false


func present_phase(event: Dictionary) -> void:
	presentation_active = true
	ceremony.visible = true
	_position_score_stage(event.get("source_control") as Control)
	_reset_ceremony()
	var is_mom := bool(event.get("mom", false))
	var has_u := bool(event.get("u", false))
	var u_bonus_paid_early := bool(event.get("u_bonus_paid_early", false))
	var start_wallet_vnd := int(event.get("start_wallet_vnd", 0))
	var target_wallet_vnd := int(event.get("target_wallet_vnd", start_wallet_vnd))
	var raw_gross_vnd := int(event.get("raw_gross_vnd", 0))
	var gross_vnd := int(event.get("gross_vnd", raw_gross_vnd))
	var deadwood_vnd := absi(int(event.get("deadwood_vnd", 0)))
	var net_vnd := int(event.get("net_vnd", 0))
	var source := event.get("source_control") as Control
	var phase := int(event.get("phase", 1))
	var title := String(event.get("title", "MÓM!" if is_mom else "P%d" % phase))

	_set_label_text(title_label, title, PresentationTheme.RED if is_mom else Color("#f5bf42"))
	await _pop_label(title_label, 0.10, 1.1 if is_mom else 1.04)
	if is_mom:
		_set_label_text(line_a_label, str(int(event.get("deadwood_value_sum", 0))), Color("#f8edd0"))
		await _pop_label(line_a_label, 0.14, 1.12)
		_set_label_text(line_b_label, "× %d" % int(event.get("deadwood_multiplier", 1)), Color("#ff9f43"))
		await _pop_label(line_b_label, 0.14, 1.18)
		_set_label_text(payout_label, VndWallet.format_vnd(-deadwood_vnd), PresentationTheme.RED)
		await _pop_label(payout_label, 0.17, 1.28)
		_nudge_score_panel(1.65)
		impact_requested.emit(1.65, false)
		await _move_money(deadwood_vnd, false, source, source, start_wallet_vnd, target_wallet_vnd, 1.65)
	else:
		var show_u_multiplier := has_u and not u_bonus_paid_early
		var shown_gross_vnd := raw_gross_vnd if show_u_multiplier else gross_vnd
		_set_label_text(line_a_label, VndWallet.format_vnd(shown_gross_vnd, true), PresentationTheme.TEA)
		await _pop_label(line_a_label, 0.12, 1.08)
		var running_wallet := start_wallet_vnd
		if show_u_multiplier:
			_set_label_text(line_b_label, "Ù  ×2", Color("#f5bf42"))
			await _pop_label(line_b_label, 0.16, 1.28)
			_set_label_text(line_a_label, VndWallet.format_vnd(gross_vnd, true), PresentationTheme.TEA)
			await _replace_label(line_a_label, 0.12, 1.22)
			var u_adjustment_vnd := maxi(gross_vnd - raw_gross_vnd, 0)
			if u_adjustment_vnd > 0:
				var u_target := running_wallet + u_adjustment_vnd
				_nudge_score_panel(1.55)
				impact_requested.emit(1.55, true)
				await _move_money(u_adjustment_vnd, true, source, wallet_pile_anchor, running_wallet, u_target, 1.55)
				running_wallet = u_target
		if deadwood_vnd > 0:
			_set_label_text(line_b_label, VndWallet.format_vnd(-deadwood_vnd), PresentationTheme.RED)
			await _replace_label(line_b_label, 0.11, 1.14)
			_nudge_score_panel(1.0)
			impact_requested.emit(1.0, false)
			await _move_money(deadwood_vnd, false, source, source, running_wallet, target_wallet_vnd, 1.0)
		_set_label_text(payout_label, "= %s" % VndWallet.format_vnd(net_vnd, true), PresentationTheme.TEA if net_vnd >= 0 else PresentationTheme.RED)
		await _pop_label(payout_label, 0.16, 1.2)
	await get_tree().create_timer(MONEY_SETTLE_DELAY if not is_mom else 0.24).timeout
	await _fade_ceremony(MONEY_CEREMONY_FADE_DURATION)
	sync_wallet(target_wallet_vnd)
	presentation_active = false


func show_static(title: String, line_a: String, line_b: String, payout: String, negative := false) -> void:
	ceremony.visible = true
	_reset_ceremony()
	_set_label_text(title_label, title, PresentationTheme.RED if negative else Color("#f5bf42"))
	_set_label_text(line_a_label, line_a, Color("#f8edd0"))
	_set_label_text(line_b_label, line_b, Color("#f5bf42"))
	_set_label_text(payout_label, payout, PresentationTheme.RED if negative else PresentationTheme.TEA)
	for label in [title_label, line_a_label, line_b_label, payout_label]:
		label.modulate = Color.WHITE
		label.scale = Vector2.ONE


func hide_ceremony() -> void:
	_scoring_generation += 1
	_restore_scoring_layout()
	_clear_major_event()
	ceremony.visible = false
	presentation_active = false


static func denomination_breakdown(amount_vnd: int) -> Array[Dictionary]:
	var remaining := absi(amount_vnd)
	var result: Array[Dictionary] = []
	for denomination in DENOMINATIONS:
		var count := remaining / denomination
		if count <= 0:
			continue
		result.append({"denomination": denomination, "count": count})
		remaining %= denomination
	return result


func wallet_visual_object_count(balance_vnd: int) -> int:
	if balance_vnd <= 0:
		return 0
	return mini(denomination_breakdown(balance_vnd).size(), MAX_WALLET_OBJECTS)


func _build_runtime_ui() -> void:
	ceremony = Control.new()
	ceremony.name = "Ceremony"
	ceremony.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	ceremony.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ceremony.visible = false
	ceremony.set_meta("match_binding", "score_overlay")
	add_child(ceremony)

	bill_layer = Control.new()
	bill_layer.name = "TransactionBills"
	bill_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bill_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ceremony.add_child(bill_layer)

	score_panel = Control.new()
	score_panel.name = "ScoreStage"
	score_panel.position = Vector2(300, 90)
	score_panel.size = Vector2(460, 214)
	score_panel.pivot_offset = score_panel.size * 0.5
	score_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	score_panel.set_meta("match_binding", "score_panel")
	ceremony.add_child(score_panel)

	title_label = _new_stage_label("ScoreTitle", Vector2(20, 0), Vector2(420, 34), 16)
	title_label.set_meta("match_binding", "score_title")
	line_a_label = _new_stage_label("ScoreLineA", Vector2(10, 31), Vector2(440, 48), 22)
	line_a_label.set_meta("match_binding", "score_line_a")
	line_b_label = _new_stage_label("ScoreLineB", Vector2(10, 74), Vector2(440, 44), 27)
	line_b_label.set_meta("match_binding", "score_line_b")
	payout_label = _new_stage_label("ScorePayout", Vector2(0, 113), Vector2(460, 72), 42)
	payout_label.set_meta("match_binding", "score_payout")


func _new_stage_label(label_name: String, label_position: Vector2, label_size: Vector2, font_size: int) -> Label:
	var label := Label.new()
	label.name = label_name
	label.position = label_position
	label.size = label_size
	label.pivot_offset = label_size * 0.5
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	label.add_theme_font_override("font", PresentationTheme.official_font())
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_outline_color", Color(0.02, 0.02, 0.03, 0.96))
	label.add_theme_constant_override("outline_size", 3 if font_size >= 34 else 2)
	score_panel.add_child(label)
	return label


func _reset_ceremony() -> void:
	for child in bill_layer.get_children():
		bill_layer.remove_child(child)
		child.queue_free()
	for label in [title_label, line_a_label, line_b_label, payout_label]:
		label.text = ""
		label.modulate = Color(1, 1, 1, 0)
		label.scale = Vector2(0.7, 0.7)
	score_panel.modulate = Color.WHITE
	score_panel.scale = Vector2.ONE


func _position_score_stage(source: Control, clearance: float = 0.70) -> void:
	var source_rect := Rect2(Vector2(size.x * 0.5 - 90.0, size.y * 0.42), Vector2(180, 120))
	if source != null and is_instance_valid(source):
		source_rect = source.get_global_rect()
	var wanted := Vector2(
		source_rect.get_center().x - score_panel.size.x * 0.5,
		source_rect.position.y - score_panel.size.y * clearance
	) - global_position
	score_panel.position = Vector2(
		clampf(wanted.x, 12.0, maxf(12.0, size.x - score_panel.size.x - 12.0)),
		clampf(wanted.y, 54.0, maxf(54.0, size.y - score_panel.size.y - 12.0))
	)


func _set_label_text(label: Label, text_value: String, color: Color) -> void:
	label.text = text_value
	label.add_theme_color_override("font_color", color)


func _pop_label(label: Label, duration: float, peak_scale: float) -> void:
	label.modulate = Color.WHITE
	label.scale = Vector2(0.62, 0.62)
	var tween := create_tween()
	tween.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(label, "scale", Vector2.ONE * peak_scale, duration)
	tween.tween_property(label, "scale", Vector2.ONE, duration * 0.72).set_trans(Tween.TRANS_QUAD)
	await tween.finished


func _replace_label(label: Label, duration: float, peak_scale: float) -> void:
	label.modulate = Color(1, 1, 1, 0)
	label.scale = Vector2(0.7, 0.7)
	await _pop_label(label, duration, peak_scale)


func _fade_ceremony(duration: float) -> void:
	var tween := create_tween().set_parallel(true)
	tween.tween_property(score_panel, "modulate", Color(1, 1, 1, 0), duration)
	tween.tween_property(score_panel, "scale", Vector2(1.04, 1.04), duration)
	await tween.finished
	ceremony.visible = false


func _nudge_score_panel(intensity: float) -> void:
	var start_y := score_panel.position.y
	var stage_tween := create_tween()
	stage_tween.tween_property(score_panel, "position:y", start_y + 3.0 * intensity, 0.035)
	stage_tween.tween_property(score_panel, "position:y", start_y, 0.09)


func _move_money(amount_vnd: int, positive: bool, source: Control, destination: Control, start_wallet_vnd: int, target_wallet_vnd: int, intensity: float) -> void:
	if amount_vnd <= 0:
		_set_wallet_number(target_wallet_vnd)
		return
	var breakdown := denomination_breakdown(amount_vnd)
	var object_count := mini(breakdown.size(), MAX_TRANSACTION_OBJECTS)
	peak_transaction_object_count = maxi(peak_transaction_object_count, object_count)
	var wallet_center := _control_center(wallet_pile_anchor if wallet_pile_anchor != null else wallet_label)
	var source_center := _control_center(source)
	var destination_center := _control_center(destination if destination != null else source)
	if source_center == Vector2.ZERO:
		source_center = Vector2(size.x * 0.5, size.y * 0.48)
	if destination_center == Vector2.ZERO:
		destination_center = source_center
	var from := source_center if positive else wallet_center
	var to := wallet_center if positive else destination_center
	_pulse_source(source if positive else destination, positive, intensity)
	var bill_nodes: Array[Control] = []
	for index in object_count:
		var entry: Dictionary = breakdown[index]
		var bill := _new_bill_stack(int(entry["denomination"]), int(entry["count"]), Vector2(118, 52))
		bill.position = from - bill.size * 0.5 + Vector2(_rng.randf_range(-42.0, 42.0), _rng.randf_range(-22.0, 22.0))
		bill.rotation = deg_to_rad(_rng.randf_range(-9.0, 9.0))
		bill.scale = Vector2(0.38, 0.38)
		bill.modulate = Color(1, 1, 1, 0)
		bill_layer.add_child(bill)
		bill_nodes.append(bill)
		var pop := create_tween().set_parallel(true)
		var pop_delay := index * MONEY_REVEAL_GAP
		pop.tween_property(bill, "modulate", Color.WHITE, 0.09).set_delay(pop_delay)
		pop.tween_property(bill, "scale", Vector2.ONE * (1.08 + 0.04 * intensity), 0.14).set_delay(pop_delay).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	await get_tree().create_timer(MONEY_REVEAL_LEAD_IN + object_count * MONEY_REVEAL_GAP).timeout
	var flight_duration := MONEY_FLIGHT_DURATION
	var wallet_tween := create_tween()
	wallet_tween.tween_method(_set_wallet_number, float(start_wallet_vnd), float(target_wallet_vnd), flight_duration).set_delay(flight_duration * 0.32)
	for index in bill_nodes.size():
		var bill := bill_nodes[index]
		var start := bill.position
		var end := to - bill.size * 0.5 + Vector2(_rng.randf_range(-18.0, 18.0), _rng.randf_range(-10.0, 10.0))
		var arc_height := (62.0 + 18.0 * intensity) * (-1.0 if positive else 1.0)
		var curve_control := (start + end) * 0.5 + Vector2(_rng.randf_range(-28.0, 28.0), arc_height)
		var travel := create_tween().set_parallel(true)
		var delay := index * MONEY_BILL_STAGGER
		travel.tween_method(_set_bill_curve_position.bind(bill, start, curve_control, end), 0.0, 1.0, flight_duration).set_delay(delay).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
		travel.tween_property(bill, "rotation", bill.rotation + deg_to_rad(_rng.randf_range(-22.0, 22.0)), flight_duration).set_delay(delay)
		travel.tween_property(bill, "scale", Vector2(0.64, 0.64), flight_duration).set_delay(delay).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		travel.tween_property(bill, "modulate:a", 0.0, MONEY_BILL_FADE_DURATION).set_delay(delay + flight_duration - MONEY_BILL_FADE_DURATION)
		travel.chain().tween_callback(bill.queue_free)
	await get_tree().create_timer(flight_duration + bill_nodes.size() * MONEY_BILL_STAGGER).timeout
	_set_wallet_number(target_wallet_vnd)
	_wallet_impact(positive, intensity)


func _set_bill_curve_position(progress: float, bill: Control, start: Vector2, curve_control: Vector2, end: Vector2) -> void:
	if not is_instance_valid(bill):
		return
	var inverse := 1.0 - progress
	bill.position = inverse * inverse * start + 2.0 * inverse * progress * curve_control + progress * progress * end


func _pulse_source(source: Control, positive: bool, intensity: float) -> void:
	if source == null or not is_instance_valid(source):
		return
	var original := source.modulate
	source.modulate = original.lerp(Color("#ffe18a") if positive else Color("#ff7770"), 0.34)
	var tween := create_tween()
	tween.tween_property(source, "modulate", original, 0.22 + 0.05 * intensity).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)


func _set_wallet_number(value: float) -> void:
	if wallet_label != null:
		wallet_label.text = VndWallet.format_vnd(roundi(value))


func _wallet_impact(positive: bool, intensity: float) -> void:
	var target := wallet_pile_anchor if wallet_pile_anchor != null else wallet_label
	if target == null:
		return
	var original_scale := target.scale
	var tween := create_tween()
	tween.tween_property(target, "scale", original_scale * (1.0 + 0.12 * intensity), 0.07).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(target, "scale", original_scale, 0.15).set_trans(Tween.TRANS_QUAD)
	if wallet_label != null:
		wallet_label.add_theme_color_override("font_color", PresentationTheme.TEA if positive else PresentationTheme.RED)
		var color_tween := create_tween()
		color_tween.tween_interval(0.16)
		color_tween.tween_callback(wallet_label.remove_theme_color_override.bind("font_color"))


func _rebuild_wallet_pile(balance_vnd: int) -> void:
	if wallet_pile_anchor == null:
		return
	for child in wallet_pile_anchor.get_children():
		wallet_pile_anchor.remove_child(child)
		child.queue_free()
	if balance_vnd <= 0:
		var debt := Label.new()
		debt.text = "−" if balance_vnd < 0 else "—"
		debt.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		debt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		debt.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		debt.add_theme_font_size_override("font_size", 12)
		debt.add_theme_color_override("font_color", PresentationTheme.RED if balance_vnd < 0 else Color(0.55, 0.57, 0.62, 0.7))
		wallet_pile_anchor.add_child(debt)
		return
	var breakdown := denomination_breakdown(balance_vnd)
	var count := mini(breakdown.size(), MAX_WALLET_OBJECTS)
	for index in count:
		var entry: Dictionary = breakdown[index]
		var bill := _new_bill_stack(int(entry["denomination"]), int(entry["count"]), Vector2(68, 29))
		bill.position = Vector2(4.0 + float(index % 4) * 9.0, 7.0 + float(index / 4) * 9.0)
		bill.rotation = deg_to_rad(-7.0 + float((index * 5) % 15))
		wallet_pile_anchor.add_child(bill)


func _new_bill_stack(denomination: int, logical_count: int, bill_size: Vector2) -> Control:
	var stack := Control.new()
	stack.custom_minimum_size = bill_size
	stack.size = bill_size
	stack.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stack.set_meta("denomination_vnd", denomination)
	stack.set_meta("logical_count", logical_count)
	var visible_layers := mini(logical_count, 3)
	for layer_index in visible_layers:
		var note := TextureRect.new()
		note.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		note.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		note.texture = _texture_for(denomination)
		note.position = Vector2(float(layer_index) * 2.0, -float(layer_index) * 2.0)
		note.size = bill_size
		note.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
		note.mouse_filter = Control.MOUSE_FILTER_IGNORE
		stack.add_child(note)
	if logical_count > 1:
		var count_label := Label.new()
		count_label.text = "×%d" % logical_count
		count_label.position = Vector2(bill_size.x - 34, bill_size.y - 17)
		count_label.size = Vector2(34, 17)
		count_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		count_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		count_label.add_theme_font_size_override("font_size", 10)
		count_label.add_theme_color_override("font_color", Color.WHITE)
		count_label.add_theme_color_override("font_outline_color", Color(0.02, 0.02, 0.03, 1))
		count_label.add_theme_constant_override("outline_size", 4)
		stack.add_child(count_label)
	return stack


func _texture_for(denomination: int) -> Texture2D:
	return DENOMINATION_TEXTURES.get(denomination) as Texture2D


func _control_center(control: Control) -> Vector2:
	if control == null or not is_instance_valid(control):
		return Vector2.ZERO
	return control.get_global_rect().get_center() - global_position


# Decorative bills never apply economy changes; authority paid before this runs.
func present_major_event(event: Dictionary) -> void:
	_scoring_generation += 1
	var generation := _scoring_generation
	presentation_active = true
	_reset_ceremony()
	ceremony.show()
	score_panel.position = (size - score_panel.size) * 0.5
	var shade := ColorRect.new()
	shade.name = "MajorEventShade"
	shade.color = Color(0.015, 0.025, 0.025, 0.84)
	shade.size = size
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ceremony.add_child(shade)
	ceremony.move_child(shade, 0)
	var heading := Label.new()
	heading.name = "MajorEventTitle"
	heading.text = String(event.get("title", ""))
	heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	heading.position = Vector2(0, size.y * 0.5 - 125)
	heading.size = Vector2(size.x, 90)
	heading.pivot_offset = heading.size * 0.5
	heading.mouse_filter = Control.MOUSE_FILTER_IGNORE
	heading.add_theme_font_size_override("font_size", 64)
	heading.add_theme_color_override("font_color", Color("f5bf42"))
	heading.add_theme_color_override("font_outline_color", Color("172524"))
	heading.add_theme_font_override("font", PresentationTheme.official_font())
	heading.add_theme_constant_override("outline_size", 4)
	ceremony.add_child(heading)
	_major_nodes.append_array([heading, shade])
	var steps: Array = event.get("steps", [])
	_set_label_text(line_b_label, "  ·  ".join(steps), Color("f8edd0"))
	var positive := int(event.get("amount_vnd", 0)) >= 0
	_set_label_text(payout_label, String(event.get("payout", "")), Color("79d94c") if positive else Color("ff625e"))
	line_b_label.modulate = Color.WHITE
	payout_label.modulate = Color.WHITE
	line_b_label.scale = Vector2.ONE
	payout_label.scale = Vector2.ONE
	line_b_label.position.y = 60
	payout_label.position.y = 104
	var pop := create_tween()
	_major_tweens.append(pop)
	heading.scale = Vector2.ONE * 0.45
	pop.tween_property(heading, "scale", Vector2.ONE, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	impact_requested.emit(1.9, positive)
	var center := size * 0.5
	var target := _control_center(wallet_pile_anchor)
	var amount := absi(int(event.get("amount_vnd", 0)))
	var notes := denomination_breakdown(amount)
	if not notes.is_empty():
		for index in 36:
			var note := _new_bill_stack(int(notes[index % notes.size()]["denomination"]), 1, Vector2(180, 80))
			note.name = "BurstBill"
			note.position = center - note.size * 0.5
			note.scale = Vector2.ONE * 0.15
			note.modulate.a = 0.0
			bill_layer.add_child(note)
			var angle := TAU * float(index) / 13.0
			var spread := center + Vector2(cos(angle) * size.x * 0.40, sin(angle) * size.y * 0.37) - note.size * 0.5
			var delay := float(index) * 0.025
			var burst := note.create_tween().set_parallel(true)
			_major_tweens.append(burst)
			burst.tween_property(note, "modulate:a", 1.0, 0.08).set_delay(delay)
			burst.tween_property(note, "position", spread, 0.42).set_delay(delay).set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)
			burst.tween_property(note, "scale", Vector2.ONE * 1.2, 0.42).set_delay(delay)
			burst.tween_property(note, "rotation", angle + PI, 0.65).set_delay(delay)
			burst.tween_property(note, "position", target - note.size * 0.5, 0.55).set_delay(delay + 0.80).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
			burst.tween_property(note, "scale", Vector2.ONE * 0.25, 0.55).set_delay(delay + 0.80)
			burst.tween_property(note, "modulate:a", 0.0, 0.12).set_delay(delay + 1.23)
			burst.chain().tween_callback(note.queue_free)
	var wallet_tween := create_tween()
	wallet_tween.tween_method(_set_wallet_number, float(event.get("start_wallet_vnd", 0)), float(event.get("target_wallet_vnd", 0)), 1.0).set_delay(0.95)
	_major_tweens.append(wallet_tween)
	if not await _wait_scoring_tail(2.3, generation):
		return
	var fade := create_tween().set_parallel(true)
	_major_tweens.append(fade)
	fade.tween_property(score_panel, "modulate:a", 0.0, 0.18)
	fade.tween_property(heading, "modulate:a", 0.0, 0.18)
	fade.tween_property(shade, "modulate:a", 0.0, 0.18)
	if not await _wait_scoring_tail(0.18, generation):
		return
	_clear_major_event()
	ceremony.hide()
	line_b_label.position.y = 74
	payout_label.position.y = 113
	sync_wallet(int(event.get("target_wallet_vnd", 0)))
	presentation_active = false


static func scoring_hit_interval(triggered_cards: int) -> float:
	return maxf(0.045, 0.36 * pow(0.91, maxi(triggered_cards - 2, 0)))


func _clear_major_event() -> void:
	for tween in _major_tweens:
		if tween != null and tween.is_valid():
			tween.kill()
	_major_tweens.clear()
	for node in _major_nodes:
		if is_instance_valid(node):
			node.queue_free()
	_major_nodes.clear()
	for bill in bill_layer.get_children():
		bill.queue_free()
	line_b_label.position.y = 74
	payout_label.position.y = 113
