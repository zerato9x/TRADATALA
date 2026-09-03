class_name MoneyPresentation
extends Control

signal impact_requested(intensity: float, positive: bool)

const BILL_ATLAS := preload("res://assets/environment/vnd_bills.png")
const DENOMINATIONS: Array[int] = [500_000, 200_000, 100_000, 50_000, 20_000, 10_000, 5_000, 2_000, 1_000]
const MAX_TRANSACTION_OBJECTS := 8
const MAX_WALLET_OBJECTS := 9
const CELL_SIZE := Vector2(1448.0 / 3.0, 1086.0 / 3.0)
const DENOMINATION_CELLS := {
	1_000: Vector2i(0, 0),
	2_000: Vector2i(1, 0),
	20_000: Vector2i(2, 0),
	10_000: Vector2i(0, 1),
	5_000: Vector2i(1, 1),
	50_000: Vector2i(2, 1),
	100_000: Vector2i(0, 2),
	200_000: Vector2i(1, 2),
	500_000: Vector2i(2, 2),
}

var ceremony: Control
var score_panel: Control
var title_label: Label
var line_a_label: Label
var line_b_label: Label
var payout_label: Label
var bill_layer: Control
var hit_flash: ColorRect

var wallet_label: Label
var wallet_pile_anchor: Control
var presentation_active := false
var peak_transaction_object_count := 0

var _atlas_textures: Dictionary = {}
var _rng := RandomNumberGenerator.new()


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


func present_transaction(event: Dictionary) -> void:
	presentation_active = true
	ceremony.visible = true
	_reset_ceremony()
	var positive := String(event.get("direction", "gain")) != "loss"
	var intensity := clampf(float(event.get("intensity", 1.0)), 0.45, 2.0)
	var compact := bool(event.get("compact", false))
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
		await _pop_label(title_label, 0.035 if compact else 0.11, 1.0 + 0.04 * intensity)
	if not steps.is_empty():
		_set_label_text(line_a_label, String(steps[0]), Color("#f8edd0"))
		await _pop_label(line_a_label, 0.035 if compact else 0.12, 1.02 + 0.05 * intensity)
	if steps.size() > 1:
		_set_label_text(line_b_label, String(steps[1]), Color("#f5bf42"))
		await _pop_label(line_b_label, 0.032 if compact else 0.11, 1.06 + 0.06 * intensity)
	_set_label_text(payout_label, payout, Color("#79d94c") if positive else Color("#ff625e"))
	await _pop_label(payout_label, 0.045 if compact else 0.14, 1.12 + 0.08 * intensity)
	_flash_impact(Color("#79d94c") if positive else Color("#ff4d4d"), intensity)
	impact_requested.emit(intensity, positive)
	await _move_money(amount_vnd, positive, source, destination, start_wallet_vnd, target_wallet_vnd, intensity, compact)
	await get_tree().create_timer(0.04 if compact else 0.16).timeout
	await _fade_ceremony(0.06 if compact else 0.14)
	sync_wallet(target_wallet_vnd)
	presentation_active = false


func present_phase(event: Dictionary) -> void:
	presentation_active = true
	ceremony.visible = true
	_reset_ceremony()
	var is_mom := bool(event.get("mom", false))
	var has_u := bool(event.get("u", false))
	var start_wallet_vnd := int(event.get("start_wallet_vnd", 0))
	var target_wallet_vnd := int(event.get("target_wallet_vnd", start_wallet_vnd))
	var raw_gross_vnd := int(event.get("raw_gross_vnd", 0))
	var gross_vnd := int(event.get("gross_vnd", raw_gross_vnd))
	var deadwood_vnd := absi(int(event.get("deadwood_vnd", 0)))
	var net_vnd := int(event.get("net_vnd", 0))
	var source := event.get("source_control") as Control
	var phase := int(event.get("phase", 1))
	var title := String(event.get("title", "MÓM!" if is_mom else "P%d" % phase))

	_set_label_text(title_label, title, Color("#ff625e") if is_mom else Color("#f5bf42"))
	await _pop_label(title_label, 0.10, 1.1 if is_mom else 1.04)
	if is_mom:
		_set_label_text(line_a_label, str(int(event.get("deadwood_value_sum", 0))), Color("#f8edd0"))
		await _pop_label(line_a_label, 0.14, 1.12)
		_set_label_text(line_b_label, "× %d" % int(event.get("deadwood_multiplier", 1)), Color("#ff9f43"))
		await _pop_label(line_b_label, 0.14, 1.18)
		_set_label_text(payout_label, VndWallet.format_vnd(-deadwood_vnd), Color("#ff625e"))
		await _pop_label(payout_label, 0.17, 1.28)
		_flash_impact(Color("#ff3d38"), 1.65)
		impact_requested.emit(1.65, false)
		await _move_money(deadwood_vnd, false, source, source, start_wallet_vnd, target_wallet_vnd, 1.65, false)
	else:
		var shown_gross_vnd := raw_gross_vnd if has_u else gross_vnd
		_set_label_text(line_a_label, VndWallet.format_vnd(shown_gross_vnd, true), Color("#79d94c"))
		await _pop_label(line_a_label, 0.12, 1.08)
		var running_wallet := start_wallet_vnd
		if has_u:
			_set_label_text(line_b_label, "Ù  ×2", Color("#f5bf42"))
			await _pop_label(line_b_label, 0.16, 1.28)
			_set_label_text(line_a_label, VndWallet.format_vnd(gross_vnd, true), Color("#79d94c"))
			await _replace_label(line_a_label, 0.12, 1.22)
			var u_adjustment_vnd := maxi(gross_vnd - raw_gross_vnd, 0)
			if u_adjustment_vnd > 0:
				var u_target := running_wallet + u_adjustment_vnd
				_flash_impact(Color("#f5bf42"), 1.55)
				impact_requested.emit(1.55, true)
				await _move_money(u_adjustment_vnd, true, source, wallet_pile_anchor, running_wallet, u_target, 1.55, false)
				running_wallet = u_target
		if deadwood_vnd > 0:
			_set_label_text(line_b_label, VndWallet.format_vnd(-deadwood_vnd), Color("#ff625e"))
			await _replace_label(line_b_label, 0.11, 1.14)
			impact_requested.emit(1.0, false)
			await _move_money(deadwood_vnd, false, source, source, running_wallet, target_wallet_vnd, 1.0, false)
		_set_label_text(payout_label, "= %s" % VndWallet.format_vnd(net_vnd, true), Color("#79d94c") if net_vnd >= 0 else Color("#ff625e"))
		await _pop_label(payout_label, 0.16, 1.2)
	await get_tree().create_timer(0.18 if not is_mom else 0.24).timeout
	await _fade_ceremony(0.14)
	sync_wallet(target_wallet_vnd)
	presentation_active = false


func show_static(title: String, line_a: String, line_b: String, payout: String, negative := false) -> void:
	ceremony.visible = true
	_reset_ceremony()
	_set_label_text(title_label, title, Color("#ff625e") if negative else Color("#f5bf42"))
	_set_label_text(line_a_label, line_a, Color("#f8edd0"))
	_set_label_text(line_b_label, line_b, Color("#f5bf42"))
	_set_label_text(payout_label, payout, Color("#ff625e") if negative else Color("#79d94c"))
	for label in [title_label, line_a_label, line_b_label, payout_label]:
		label.modulate = Color.WHITE
		label.scale = Vector2.ONE


func hide_ceremony() -> void:
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

	hit_flash = ColorRect.new()
	hit_flash.name = "HitFlash"
	hit_flash.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	hit_flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hit_flash.modulate = Color(1, 1, 1, 0)
	ceremony.add_child(hit_flash)

	bill_layer = Control.new()
	bill_layer.name = "TransactionBills"
	bill_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bill_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ceremony.add_child(bill_layer)

	score_panel = Control.new()
	score_panel.name = "ScoreStage"
	score_panel.set_anchors_preset(Control.PRESET_CENTER)
	score_panel.position = Vector2(-330, -150)
	score_panel.size = Vector2(660, 280)
	score_panel.pivot_offset = score_panel.size * 0.5
	score_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	score_panel.set_meta("match_binding", "score_panel")
	ceremony.add_child(score_panel)

	var shadow := ColorRect.new()
	shadow.name = "StageShadow"
	shadow.position = Vector2(58, 32)
	shadow.size = Vector2(544, 214)
	shadow.color = Color(0.02, 0.025, 0.04, 0.0)
	shadow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	score_panel.add_child(shadow)

	title_label = _new_stage_label("ScoreTitle", Vector2(45, 18), Vector2(570, 42), 18)
	title_label.set_meta("match_binding", "score_title")
	line_a_label = _new_stage_label("ScoreLineA", Vector2(25, 64), Vector2(610, 58), 36)
	line_a_label.set_meta("match_binding", "score_line_a")
	line_b_label = _new_stage_label("ScoreLineB", Vector2(25, 119), Vector2(610, 54), 34)
	line_b_label.set_meta("match_binding", "score_line_b")
	payout_label = _new_stage_label("ScorePayout", Vector2(15, 173), Vector2(630, 78), 48)
	payout_label.set_meta("match_binding", "score_payout")


func _new_stage_label(label_name: String, label_position: Vector2, label_size: Vector2, font_size: int) -> Label:
	var label := Label.new()
	label.name = label_name
	label.position = label_position
	label.size = label_size
	label.pivot_offset = label_size * 0.5
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_outline_color", Color(0.02, 0.02, 0.03, 0.96))
	label.add_theme_constant_override("outline_size", 8 if font_size >= 34 else 5)
	score_panel.add_child(label)
	return label


func _reset_ceremony() -> void:
	for child in bill_layer.get_children():
		bill_layer.remove_child(child)
		child.queue_free()
	hit_flash.modulate = Color(1, 1, 1, 0)
	for label in [title_label, line_a_label, line_b_label, payout_label]:
		label.text = ""
		label.modulate = Color(1, 1, 1, 0)
		label.scale = Vector2(0.7, 0.7)
	score_panel.modulate = Color.WHITE
	score_panel.scale = Vector2.ONE


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


func _flash_impact(color: Color, intensity: float) -> void:
	hit_flash.color = Color(color.r, color.g, color.b, 0.12 * intensity)
	hit_flash.modulate = Color.WHITE
	var tween := create_tween()
	tween.tween_property(hit_flash, "modulate:a", 0.0, 0.18).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	var start_y := score_panel.position.y
	var stage_tween := create_tween()
	stage_tween.tween_property(score_panel, "position:y", start_y + 3.0 * intensity, 0.035)
	stage_tween.tween_property(score_panel, "position:y", start_y, 0.09)


func _move_money(amount_vnd: int, positive: bool, source: Control, destination: Control, start_wallet_vnd: int, target_wallet_vnd: int, intensity: float, compact: bool) -> void:
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
		var pop_delay := index * (0.015 if compact else 0.025)
		pop.tween_property(bill, "modulate", Color.WHITE, 0.06 if compact else 0.09).set_delay(pop_delay)
		pop.tween_property(bill, "scale", Vector2.ONE * (1.08 + 0.04 * intensity), 0.07 if compact else 0.14).set_delay(pop_delay).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	await get_tree().create_timer((0.075 + object_count * 0.015) if compact else (0.14 + object_count * 0.025)).timeout
	var flight_duration := (0.20 + 0.025 * intensity) if compact else (0.42 + 0.045 * intensity)
	var wallet_tween := create_tween()
	wallet_tween.tween_method(_set_wallet_number, float(start_wallet_vnd), float(target_wallet_vnd), flight_duration).set_delay(flight_duration * 0.32)
	for index in bill_nodes.size():
		var bill := bill_nodes[index]
		var start := bill.position
		var end := to - bill.size * 0.5 + Vector2(_rng.randf_range(-18.0, 18.0), _rng.randf_range(-10.0, 10.0))
		var arc_height := (62.0 + 18.0 * intensity) * (-1.0 if positive else 1.0)
		var curve_control := (start + end) * 0.5 + Vector2(_rng.randf_range(-28.0, 28.0), arc_height)
		var travel := create_tween().set_parallel(true)
		var delay := index * (0.015 if compact else 0.04)
		travel.tween_method(_set_bill_curve_position.bind(bill, start, curve_control, end), 0.0, 1.0, flight_duration).set_delay(delay).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
		travel.tween_property(bill, "rotation", bill.rotation + deg_to_rad(_rng.randf_range(-22.0, 22.0)), flight_duration).set_delay(delay)
		travel.tween_property(bill, "scale", Vector2(0.64, 0.64), flight_duration).set_delay(delay).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		var fade_duration := 0.06 if compact else 0.08
		travel.tween_property(bill, "modulate:a", 0.0, fade_duration).set_delay(delay + flight_duration - fade_duration)
		travel.chain().tween_callback(bill.queue_free)
	await get_tree().create_timer(flight_duration + bill_nodes.size() * (0.015 if compact else 0.04)).timeout
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
		wallet_label.add_theme_color_override("font_color", Color("#79d94c") if positive else Color("#ff625e"))
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
		debt.add_theme_color_override("font_color", Color("#ff625e") if balance_vnd < 0 else Color(0.55, 0.57, 0.62, 0.7))
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


func _texture_for(denomination: int) -> AtlasTexture:
	var cached := _atlas_textures.get(denomination) as AtlasTexture
	if cached != null:
		return cached
	var cell: Vector2i = DENOMINATION_CELLS.get(denomination, Vector2i.ZERO)
	var texture := AtlasTexture.new()
	texture.atlas = BILL_ATLAS
	texture.region = Rect2(Vector2(cell) * CELL_SIZE, CELL_SIZE)
	_atlas_textures[denomination] = texture
	return texture


func _control_center(control: Control) -> Vector2:
	if control == null or not is_instance_valid(control):
		return Vector2.ZERO
	return control.get_global_rect().get_center() - global_position
