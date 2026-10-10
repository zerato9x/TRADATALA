extends Control
## An illustrated still life assembled from shipped art. No game state or RNG.
const FACES := [preload("res://cards/four_of_hearts.png"), preload("res://cards/five_of_hearts.png"), preload("res://cards/six_of_hearts.png")]
const TEA := preload("res://assets/drinks/tra_da_full.png")
const BILL := preload("res://assets/money/bill_10k.png")
const SUITS := [preload("res://cards/symbol_spade.png"), preload("res://cards/symbol_heart.png"), preload("res://cards/symbol_club.png"), preload("res://cards/symbol_diamond.png")]
var body: VBoxContainer
var _board := Rect2()
var _clock := 0.0
var _tick := 0.0
var _entered := false
var _entrance: Tween
var _styles: Dictionary = {}

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_styles = {
		"shadow": PresentationTheme.panel_style(Color("070d12ba"), Color.TRANSPARENT, 0, 9),
		"board": PresentationTheme.panel_style(Color("112e30f5"), Color("bd9560"), 3, 8, 6),
		"keyline": PresentationTheme.panel_style(Color.TRANSPARENT, Color("58746a"), 1, 4),
		"card": PresentationTheme.panel_style(Color("02091188"), Color.TRANSPARENT, 0, 4, 3),
		"sleeve_shadow": PresentationTheme.panel_style(Color("06101999"), Color.TRANSPARENT, 0, 2, 4),
		"sleeve": PresentationTheme.panel_style(Color("d2b27c"), Color("6d4737"), 2, 2),
	}
	visibility_changed.connect(_visibility_changed)
	resized.connect(queue_redraw)
	_visibility_changed()

func _visibility_changed() -> void:
	set_process(is_visible_in_tree())
	if is_visible_in_tree() and not _entered:
		_entered = true
		modulate.a = 0.0
		_entrance = create_tween()
		_entrance.tween_property(self, "modulate:a", 1.0, 0.45)

func _process(delta: float) -> void:
	if not is_visible_in_tree() or not is_instance_valid(body): return
	_clock += delta
	_tick += delta
	# Only this small decorative layer redraws, capped at 30 Hz.
	if _tick < 1.0 / 30.0: return
	_tick = 0.0
	var first: Control
	var last: Control
	for child in body.get_children():
		if child is Control and child.visible:
			if first == null: first = child
			last = child
	if first != null:
		var top := first.global_position.y - global_position.y
		var bottom := last.global_position.y + last.size.y - global_position.y
		_board = Rect2(Vector2(body.global_position.x - global_position.x - 24, top - 26), Vector2(body.size.x + 48, bottom - top + 50))
	queue_redraw()

func _draw() -> void:
	if not _board.has_area(): return
	var rule_y := 164.0 if size.y >= 650 else 124.0
	for direction in [-1, 1]:
		draw_line(Vector2(size.x * 0.5 + direction * 66, rule_y + 7), Vector2(size.x * 0.5 + direction * 188, rule_y + 7), Color("d4b17080"), 1)
	for i in 4:
		draw_texture_rect(SUITS[i], Rect2(size.x * 0.5 - 43 + i * 24, rule_y, 14, 14), false, Color("edcd88"))
	var prop_scale := clampf((size.x - _board.size.x) / 690.0, 0.5, 1.0)
	var cy := _board.get_center().y
	_cards(Vector2(_board.position.x - 103 * prop_scale, cy + 48), prop_scale)
	_record(Vector2(_board.end.x + 113 * prop_scale, cy - 98 * prop_scale), prop_scale)
	_drink(Vector2(_board.end.x + 98 * prop_scale, cy + 131 * prop_scale), prop_scale)
	# A thick enamel sign, nested keyline and four exposed brass screws.
	draw_style_box(_styles.shadow, Rect2(_board.position + Vector2(0, 11), _board.size))
	draw_style_box(_styles.board, _board)
	draw_style_box(_styles.keyline, _board.grow(-8))
	draw_line(_board.position + Vector2(14, 4), Vector2(_board.end.x - 14, _board.position.y + 4), Color("f8df9c70"), 1)
	for x in [_board.position.x + 13, _board.end.x - 13]:
		for y in [_board.position.y + 13, _board.end.y - 13]:
			draw_circle(Vector2(x, y + 1), 3, Color("070e12"))
			draw_circle(Vector2(x, y), 2, Color("bd9560"))
			draw_line(Vector2(x - 1, y), Vector2(x + 1, y), Color("473b27"), 1)
	# Small cuts in the paint, deliberately fixed instead of random noise.
	for i in 7:
		var p := _board.position + Vector2(33 + i * 51, _board.size.y - 4)
		draw_line(p, p + Vector2(5 + i % 3, 0), Color("0a1e25"), 2)

func _cards(center: Vector2, zoom: float) -> void:
	draw_set_transform(center + Vector2(-10, -108) * zoom, -0.18, Vector2.ONE * zoom)
	draw_texture_rect(BILL, Rect2(-58, -28, 116, 56), false, Color("d0c5a4"))
	for i in 3:
		var offset := Vector2((i - 1) * 35, abs(i - 1) * 9)
		draw_set_transform(center + offset * zoom, deg_to_rad(-21 + i * 16), Vector2.ONE * zoom)
		var card := Rect2(-47, -67, 94, 134)
		draw_style_box(_styles.card, Rect2(card.position + Vector2(4, 8), card.size))
		draw_texture_rect(FACES[i], card, false, Color("fff1d4"))
	draw_set_transform(Vector2.ZERO)

func _record(center: Vector2, zoom: float) -> void:
	draw_set_transform(center, -0.14, Vector2.ONE * zoom)
	draw_style_box(_styles.sleeve_shadow, Rect2(-60, -54, 132, 132))
	draw_style_box(_styles.sleeve, Rect2(-65, -63, 130, 130))
	draw_rect(Rect2(-57, -55, 114, 114), Color("8c4836"))
	draw_line(Vector2(-57, 51), Vector2(57, -42), Color("e6c889"), 8)
	draw_circle(Vector2(8, 0), 55, Color("101c24"))
	for radius in [29, 35, 41, 47, 51]:
		draw_arc(Vector2(8, 0), radius, 0, TAU, 64, Color("314148"), 1)
	draw_circle(Vector2(8, 0), 18, Color("dbab4f"))
	draw_circle(Vector2(8, 0), 4, Color("182d32"))
	var turn := _clock * 0.32
	draw_arc(Vector2(8, 0), 44, turn, turn + 0.75, 14, Color("b0c4c333"), 3)
	draw_set_transform(Vector2.ZERO)

func _drink(center: Vector2, zoom: float) -> void:
	draw_set_transform(center, 0, Vector2.ONE * zoom)
	# Elliptical condensation ring sits at the sprite's actual contact point.
	draw_set_transform(center + Vector2(0, 4), 0, Vector2(1, 0.36) * zoom)
	draw_circle(Vector2.ZERO, 49, Color("050f2270"))
	draw_arc(Vector2.ZERO, 51, 0.2, 5.4, 48, Color("c7d5b93a"), 3)
	draw_set_transform(center, 0, Vector2.ONE * zoom)
	draw_texture_rect(TEA, Rect2(-70, -194, 175, 225), false)
	# Cold tea: small highlights on the wet glass, no inexplicable hot steam.
	for i in 3:
		var sparkle := (sin(_clock * 1.3 + i * 1.9) + 1.0) * 0.12
		draw_rect(Rect2(-16 + i * 13, -71 - i * 12, 2, 3), Color(1, 0.98, 0.82, sparkle))
	draw_set_transform(Vector2.ZERO)
