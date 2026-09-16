extends Control

var notes: Array[Control] = []
var origin := Vector2.ZERO
var hud: Control
var hud_color := Color.WHITE
var travel := 0.0
var age := 0.0
var radius := 100.0
var closing := false
var motion: Tween
var pulses: Dictionary = {}
var extra_hud: Dictionary = {}


func begin(presentation: MoneyPresentation, balance: int, game_hud: Control) -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	z_index = 1000
	hud = game_hud
	hud_color = hud.modulate
	# The help legend lives in a separate canvas above the table HUD.
	var legend := get_parent().get_node_or_null("ActionLegend")
	if legend != null:
		for item in legend.get_children():
			if item is Control:
				extra_hud[item] = item.modulate
	origin = get_global_transform().affine_inverse() * presentation.wallet_pile_anchor.get_global_rect().get_center()
	var wealth := log(1.0 + maxi(balance, 0) / 1000.0)
	radius = minf(minf(size.x, size.y) * 0.38, 50.0 + wealth * 23.0)
	var breakdown := MoneyPresentation.denomination_breakdown(balance)
	var logical_total := 0
	for entry in breakdown:
		logical_total += int(entry["count"])
	var budget := mini(160, logical_total)
	for entry in breakdown:
		var copies := mini(int(entry["count"]), maxi(1, roundi(float(budget) * int(entry["count"]) / maxi(logical_total, 1))))
		for index in copies:
			var count := int(entry["count"]) / copies + (1 if index < int(entry["count"]) % copies else 0)
			var note := presentation._new_bill_stack(int(entry["denomination"]), count, Vector2(88, 39))
			note.pivot_offset = note.size * 0.5
			add_child(note)
			notes.append(note)
	motion = create_tween().set_parallel(true)
	motion.tween_property(self, "travel", 1.0, 0.85).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	motion.tween_property(hud, "modulate:a", 0.0, 0.5)
	for item in extra_hud:
		motion.tween_property(item, "modulate:a", 0.0, 0.5)


func _process(delta: float) -> void:
	age += delta
	for index in notes.size():
		var fraction := float(index + 1) / maxi(notes.size(), 1)
		var angle := fraction * TAU * clampf(0.9 + notes.size() / 45.0, 1.0, 3.6) + age * 0.22
		var target := size * 0.5 + Vector2(cos(angle), sin(angle)) * radius * sqrt(fraction)
		notes[index].position = origin.lerp(target, travel) - notes[index].size * 0.5
		notes[index].rotation = travel * (angle + PI * 0.5 + sin(age * 1.3 + index) * 0.10)


func pulse(band: int, strength: float) -> void:
	if closing or band < 0 or band >= 4 or band >= notes.size():
		return
	var previous := pulses.get(band) as Tween
	if previous != null and previous.is_valid():
		previous.kill()
	var tween := create_tween().set_parallel(true)
	pulses[band] = tween
	for index in notes.size():
		if index % 4 != band:
			continue
		var note := notes[index]
		note.scale = Vector2.ONE
		var peak := Vector2(1.0 + 0.065 * strength, 1.0 + 0.20 * strength)
		tween.tween_property(note, "scale", peak, 0.075).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tween.tween_property(note, "scale", Vector2.ONE, 0.19).set_delay(0.075).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)


func dismiss() -> void:
	if closing:
		return
	closing = true
	if motion != null and motion.is_valid():
		motion.kill()
	motion = create_tween().set_parallel(true)
	motion.tween_property(self, "travel", 0.0, 0.45).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	motion.tween_property(hud, "modulate", hud_color, 0.45)
	for item in extra_hud:
		if is_instance_valid(item):
			motion.tween_property(item, "modulate", extra_hud[item], 0.45)
	motion.chain().tween_callback(queue_free)


func _exit_tree() -> void:
	if is_instance_valid(hud):
		hud.modulate = hud_color
	for item in extra_hud:
		if is_instance_valid(item):
			item.modulate = extra_hud[item]
