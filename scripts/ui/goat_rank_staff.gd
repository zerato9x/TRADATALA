extends Control
## A complete, wrapping rank melody; the displayed next note comes from Zodiac.
const MINT := Color("9ce5d7")
var ranks: Array[Label] = []
var expected_rank := 0
var accepted: Array[int] = []
var waiting := false
var _parity := -1
var _clock := 0.0
var _played: Array[int] = []
var _celebration := 0.0
var _miss := 0.0
var _paused := false

func _ready() -> void:
	name = "GoatRankStaff"
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	for rank in DeckManager.RANKS:
		var label := Label.new()
		label.text = rank
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		label.add_theme_font_size_override("font_size", 14)
		label.add_theme_color_override("font_shadow_color", Color("15221e"))
		label.add_theme_constant_override("shadow_offset_y", 1)
		add_child(label)
		ranks.append(label)

func sync(state: Dictionary) -> void:
	expected_rank = int(state.get("expected_rank", 0))
	accepted = preload("res://scripts/zodiac/rules/goat.gd").accepted_ranks(expected_rank)
	_parity = int(state.turn_number) % 2 if int(state.difficulty) == ZodiacCatalog.UNPLEASED else -1
	waiting = false
	for i in ranks.size():
		var eligible := (expected_rank == 0 or i + 1 in accepted) and (_parity < 0 or (i + 1) % 2 == _parity)
		ranks[i].add_theme_color_override("font_color", MINT if eligible else PresentationTheme.WARNING if waiting and i + 1 == expected_rank else PresentationTheme.MUTED)
		ranks[i].modulate.a = 1 if eligible or i + 1 in accepted else 0.45
	queue_redraw()

func fit_width(width: float) -> void:
	size = Vector2(width, 34)
	var cell := width / 13
	for i in ranks.size():
		ranks[i].position = Vector2(i * cell, 6)
		ranks[i].size = Vector2(cell, 20)
		ranks[i].add_theme_font_size_override("font_size", 12 if cell < 26 else 14)

func celebrate(notes: Array[int]) -> void:
	_played = notes.duplicate()
	_celebration = 1.0
	_miss = 0.0

func miss() -> void:
	_miss = 1.0
	_celebration = 0.0
	_played.clear()

func clear_effects() -> void:
	_played.clear()
	_celebration = 0
	_miss = 0
	queue_redraw()

func pause_effects(paused: bool) -> void:
	_paused = paused

func _process(delta: float) -> void:
	if not is_visible_in_tree() or _paused: return
	_clock += delta
	_celebration = move_toward(_celebration, 0, delta * 1.4)
	_miss = move_toward(_miss, 0, delta * 1.8)
	if _celebration <= 0: _played.clear()
	queue_redraw()

func _draw() -> void:
	var cell := size.x / 13
	for staff_line in 3:
		draw_line(Vector2(0, 8 + staff_line * 9), Vector2(size.x, 8 + staff_line * 9), Color(MINT, 0.1), 1, true)
	for i in 13:
		var center := Vector2((i + 0.5) * cell, 17)
		var active := i + 1 in accepted
		var played := i + 1 in _played
		if active:
			var color := PresentationTheme.WARNING if _parity >= 0 and (i + 1) % 2 != _parity else MINT
			if _miss > 0: color = color.lerp(PresentationTheme.DANGER, _miss)
			draw_rect(Rect2(center - Vector2(cell * 0.45, 15), Vector2(cell * 0.9, 30)), Color("172c29dd"))
			draw_rect(Rect2(center - Vector2(cell * 0.45, 15), Vector2(cell * 0.9, 30)), color, false, 1)
			draw_circle(center + Vector2(0, 15), 2 + sin(_clock * 3) * 0.5, color)
		elif played:
			draw_arc(center, 12 + (1 - _celebration) * 5, 0, TAU, 24, Color(MINT, _celebration), 1, true)
		if played:
			var note := center + Vector2(0, -6 - (1 - _celebration) * 10)
			draw_circle(note, 2.5, Color(MINT, _celebration))
			draw_line(note + Vector2(2, 0), note + Vector2(2, -9), Color(MINT, _celebration), 1, true)
	# The open loop at the end teaches K → A without inventing a timed beat.
	draw_arc(Vector2(size.x - 15, 17), 14, -PI * 0.3, PI * 0.3, 12, Color(MINT, 0.5), 1, true)
