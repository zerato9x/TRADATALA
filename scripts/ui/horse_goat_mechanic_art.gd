extends Control
## Hoof stamps for Horse, a musical note for Goat. Read-only boss artwork.
var kind := ""
var pair_count := 0
var next_rank := 0
var waiting := false
var _clock := 0.0
var _impact := 0.0

func _ready() -> void:
	name = "HorseGoatMechanicArt"
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	size = Vector2(78, 82)

func sync(state: Dictionary) -> void:
	kind = String(state.get("id", ""))
	pair_count = int(state.get("pair_count", 0))
	next_rank = int(state.get("expected_rank", 0))
	waiting = false
	queue_redraw()

func react() -> void:
	_impact = 1.0

func clear_effects() -> void:
	_impact = 0.0

func _process(delta: float) -> void:
	if not is_visible_in_tree(): return
	_clock += delta
	_impact = move_toward(_impact, 0, delta * 2)
	queue_redraw()

func _draw() -> void:
	if kind == "horse":
		var blue := PresentationTheme.zodiac_color("horse")
		for i in 5:
			var x := fmod(_clock * (20 + pair_count * 10) + i * 17, 72)
			var y := 18.0 + i * 12
			draw_line(Vector2(x - 12, y), Vector2(x, y), Color(blue, 0.18), 1, true)
		for hoof in 2:
			var center := Vector2(24 + hoof * 29, 27 + hoof * 26)
			center.y -= sin((1 - _impact) * PI) * _impact * 5
			var complete := hoof < pair_count
			var ink := blue if complete else blue.darkened(0.55)
			draw_arc(center, 16, 0, PI, 26, Color("101e32"), 9, true)
			draw_arc(center, 16, 0, PI, 26, ink, 3, true)
			for side in [-1, 1]:
				draw_line(center + Vector2(side * 16, 0), center + Vector2(side * 16, -13), ink, 3, true)
				draw_line(center + Vector2(side * 16, -13), center + Vector2(side * 10, -13), ink, 3, true)
			for stud in 5:
				var point := center + Vector2.from_angle((stud + 0.5) * PI / 5) * 16
				draw_circle(point, 1.5, Color("effaff") if complete else Color("44627d"))
			if complete: draw_circle(center + Vector2(0, 6), 3, blue)
			if complete and _impact > 0:
				draw_arc(center, 19 + (1 - _impact) * 10, 0, TAU, 32, Color(blue, _impact * 0.65), 1, true)
	elif kind == "goat":
		var mint := PresentationTheme.WARNING if waiting else PresentationTheme.zodiac_color("goat")
		for line in 4:
			draw_line(Vector2(3, 24 + line * 9), Vector2(74, 24 + line * 9), Color(mint, 0.22), 1, true)
		var bob := sin(_clock * 2.5) * 1.5 - _impact * 4
		var note := Vector2(17, 47 + bob)
		draw_circle(note, 6, mint)
		draw_line(note + Vector2(5, 0), note + Vector2(5, -29), mint, 2, true)
		draw_polyline(PackedVector2Array([note + Vector2(5, -29), note + Vector2(13, -22), note + Vector2(11, -15)]), mint, 2, true)
		for offset in 3:
			var text := DeckManager.RANKS[(next_rank - 1 + offset) % 13] if next_rank > 0 else "?"
			draw_string(PresentationTheme.official_font(), Vector2(31 + offset * 16, 49 + bob), text, HORIZONTAL_ALIGNMENT_CENTER, 16, 17, mint)
		if waiting:
			draw_arc(Vector2(48, 39), 25, 0, TAU, 36, Color(mint, 0.35), 1, true)
		else:
			for spark in 4:
				var angle := _clock * 0.4 + spark * TAU / 4
				var point := Vector2(40, 39) + Vector2.from_angle(angle) * Vector2(34, 29)
				draw_circle(point, 1.5, Color(mint, 0.45))
