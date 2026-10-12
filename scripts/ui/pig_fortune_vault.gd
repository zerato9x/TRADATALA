extends Control
## A moving vault door and coin stacks, projected from Pig's committed ledger.
const GOLD := Color("ffe099")
const PINK := Color("ffb5ca")
var held_vnd := 0
var target_met := false
var _fill := 0.0
var _fill_goal := 0.0
var _door := 0.0
var _impact := 0.0
var _clock := 0.0
var _coin_lit: StyleBoxFlat

func _ready() -> void:
	name = "PigFortuneVault"
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	size = Vector2(78, 78)
	_coin_lit = _coin_style(true)

func sync(state: Dictionary, immediate: bool = false) -> void:
	held_vnd = int(state.get("pool_vnd", 0))
	target_met = state.get("target_met", false)
	_fill_goal = clampf(float(state.get("progress_vnd", 0)) / maxf(int(state.get("target_vnd", 1)), 1), 0, 1)
	if immediate:
		_fill = _fill_goal
		_door = 1.0 if target_met else 0.0
		_impact = 0.0

func react() -> void:
	_impact = 1.0

func _process(delta: float) -> void:
	if not is_visible_in_tree(): return
	_clock += delta
	_fill = move_toward(_fill, _fill_goal, delta * 1.8)
	_door = move_toward(_door, 1.0 if target_met else 0.0, delta * 1.7)
	_impact = move_toward(_impact, 0.0, delta * 2.0)
	queue_redraw()

func _draw() -> void:
	var center := Vector2(39, 37) + Vector2(sin(_clock * 35) * _impact * 2, -_impact * 2)
	var shell := Rect2(center - Vector2(31, 29), Vector2(62, 58))
	draw_rect(shell.grow(3), Color("160e19d9"))
	draw_rect(shell, Color("392a34"))
	draw_rect(shell, PINK, false, 1.5)
	draw_line(shell.position + Vector2(5, 0), shell.position + Vector2(24, 0), GOLD, 3)
	draw_line(shell.end - Vector2(5, 0), shell.end - Vector2(24, 0), GOLD, 3)
	# Each pile reflects gross progress; only the real held pool lights the coins.
	for stack in 3:
		var layers := clampi(int(ceil(_fill * 5.0)) - stack, 0, 5) if held_vnd > 0 else 0
		for layer in layers:
			var point := center + Vector2(-18 + stack * 18, 18 - layer * 5)
			draw_style_box(_coin_lit, Rect2(point - Vector2(7, 3), Vector2(14, 5)))
	# Hinged door narrows as it opens, revealing the empty vault after repayment.
	var door_width := lerpf(48.0, 5.0, _door)
	var door := Rect2(center + Vector2(-24, -23), Vector2(door_width, 46))
	draw_rect(door, Color("4c3340"))
	draw_rect(door, PINK.lerp(GOLD, _door), false, 1.5)
	if _door < 0.75:
		var hub := door.get_center()
		draw_circle(hub, 13, Color("211823"))
		draw_arc(hub, 13, -PI * 0.5, -PI * 0.5 + TAU * maxf(_fill, 0.015), 40, GOLD, 2, true)
		for spoke in 3:
			var direction := Vector2.from_angle(spoke * TAU / 3 + _door * PI)
			draw_line(hub + direction * 3, hub + direction * 9, PINK, 2, true)
		draw_circle(hub, 3, GOLD)
	else:
		draw_polyline(PackedVector2Array([center + Vector2(-8, 0), center + Vector2(-1, 7), center + Vector2(14, -10)]), PresentationTheme.MONEY_GAIN, 3, true)
	for side in [-1, 1]:
		draw_line(center + Vector2(side * 22, 31), center + Vector2(side * 22, 35), PINK, 3)
	if held_vnd > 0 and not target_met:
		# Coins stack outside the closed door, never implying they are spendable.
		for i in mini(5, maxi(1, int(ceil(_fill * 5)))):
			var point := center + Vector2(22, 27 - i * 4)
			draw_style_box(_coin_lit, Rect2(point - Vector2(8, 2), Vector2(16, 4)))

func _coin_style(lit: bool) -> StyleBoxFlat:
	var coin := StyleBoxFlat.new()
	coin.bg_color = Color("d99c4f") if lit else Color("715557")
	coin.border_color = GOLD if lit else PINK.darkened(0.5)
	coin.set_border_width_all(1)
	coin.set_corner_radius_all(2)
	return coin
