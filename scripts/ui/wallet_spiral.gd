extends Control

var notes: Array[Control] = []
var origin := Vector2.ZERO
var hud: Control
var hud_color := Color.WHITE
var travel := 0.0
var age := 0.0
var radius := 100.0
var turns := 3.6
var closing := false
var motion: Tween
var pulses: Dictionary = {}
var extra_hud: Dictionary = {}
var dense_ring_count := 0
var dense_ring_radii: Array[float] = []
var note_lanes: Array[Vector2] = []


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
	# Reach beyond the farthest corner so the celebration fills the whole screen,
	# rather than stopping in a circle around the table's center.
	radius = size.length() * 0.58 + 70.0
	turns = clampf(3.8 + wealth * 0.16, 4.6, 6.2)
	var breakdown := MoneyPresentation.denomination_breakdown(balance)
	var logical_total := 0
	for entry in breakdown:
		logical_total += int(entry["count"])
	var budget := mini(240, logical_total)
	for entry in breakdown:
		var copies := mini(int(entry["count"]), maxi(1, roundi(float(budget) * int(entry["count"]) / maxi(logical_total, 1))))
		for index in copies:
			var count := int(entry["count"]) / copies + (1 if index < int(entry["count"]) % copies else 0)
			var note := presentation._new_bill_stack(int(entry["denomination"]), count, Vector2(88, 39))
			note.pivot_offset = note.size * 0.5
			add_child(note)
			notes.append(note)
	_build_note_lanes()
	motion = create_tween().set_parallel(true)
	motion.tween_property(self, "travel", 1.0, 0.85).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	motion.tween_property(hud, "modulate:a", 0.0, 0.5)
	for item in extra_hud:
		motion.tween_property(item, "modulate:a", 0.0, 0.5)


func _process(delta: float) -> void:
	age += delta
	for index in notes.size():
		var lane := note_lanes[index]
		var angle := lane.y + age * 0.22
		var target := size * 0.5 + Vector2(cos(angle), sin(angle)) * lane.x
		notes[index].position = origin.lerp(target, travel) - notes[index].size * 0.5
		notes[index].rotation = travel * (angle + PI * 0.5 + sin(age * 1.3 + index) * 0.10)


func _build_note_lanes() -> void:
	note_lanes.clear()
	dense_ring_radii.clear()
	dense_ring_count = 0
	if notes.size() < 48:
		for index in notes.size():
			var fraction := float(index + 1) / maxi(notes.size(), 1)
			note_lanes.append(Vector2(radius * sqrt(fraction), fraction * TAU * turns))
		return
	# Large wallets become separate circular lanes instead of one compressed coil.
	dense_ring_count = clampi(roundi(sqrt(float(notes.size()) / 5.0)), 4, 8)
	var inner_radius := minf(size.x, size.y) * 0.12
	var total_weight := 0.0
	for ring in dense_ring_count:
		var ring_radius := lerpf(inner_radius, radius, float(ring) / maxi(dense_ring_count - 1, 1))
		dense_ring_radii.append(ring_radius)
		total_weight += ring_radius
	var allocated := 0
	var cumulative_weight := 0.0
	for ring in dense_ring_count:
		cumulative_weight += dense_ring_radii[ring]
		var ring_end := notes.size() if ring == dense_ring_count - 1 else roundi(notes.size() * cumulative_weight / total_weight)
		var ring_notes := maxi(ring_end - allocated, 1)
		var step := TAU / ring_notes
		var stagger := step * 0.5 * (ring % 2)
		for slot in ring_notes:
			note_lanes.append(Vector2(dense_ring_radii[ring], slot * step + stagger))
		allocated = ring_end


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
