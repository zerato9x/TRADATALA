class_name MatchUI
extends Control

const CARD_SIZE := PlayingCardView.CARD_SIZE

var deal := DealState.new()
var selected_card_ids: Dictionary = {}
var selected_meld_id: int = -1
var hand_views: Dictionary = {}
var displayed_wallet_vnd: int = 0
var interaction_locked: bool = false
var sort_mode: int = 0
var modal_mode: String = ""

var phase_value: Label
var turn_value: Label
var earnings_value: Label
var wallet_value: Label
var phase_clock: Label
var draw_count: Label
var discard_count_label: Label
var discard_texture: TextureRect
var hand_count: Label
var selection_label: Label
var status_label: Label
var hand_layer: Control
var meld_scroll: ScrollContainer
var meld_row: HBoxContainer
var empty_meld_label: Label
var draw_pile_visual: Control
var discard_pile_visual: Control
var ha_button: Button
var extend_button: Button
var discard_button: Button
var sort_button: Button
var particle_layer: Control

var score_overlay: Control
var score_panel: Panel
var score_title: Label
var score_line_a: Label
var score_line_b: Label
var score_payout: Label

var modal_overlay: Control
var modal_title: Label
var modal_kicker: Label
var modal_body: Label
var modal_detail: Label
var modal_primary: Button
var modal_secondary: Button

var banner_panel: PanelContainer
var banner_label: Label


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	custom_minimum_size = Vector2(960, 620)
	_build_interface()
	get_viewport().size_changed.connect(_on_viewport_size_changed)
	var result := deal.start_deal(-1, true)
	displayed_wallet_vnd = deal.wallet.balance_vnd
	_sync_all(result, true)
	_show_banner("VÁN MỚI  •  CHỌN BÀI, HẠ PHỎM, RỒI BỎ 1 LÁ")


func _build_interface() -> void:
	var background := CafeTableBackground.new()
	add_child(background)

	_build_header()
	_build_table()
	_build_hand()
	_build_action_dock()
	_build_effect_layers()


func _build_header() -> void:
	var header := Panel.new()
	header.name = "Header"
	header.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	header.offset_left = 18
	header.offset_top = 17
	header.offset_right = -18
	header.offset_bottom = 91
	header.add_theme_stylebox_override("panel", PresentationTheme.panel_style(Color("#0b201dde"), Color("#315347"), 1, 14, 6))
	add_child(header)

	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 18)
	margin.add_theme_constant_override("margin_top", 10)
	margin.add_theme_constant_override("margin_right", 12)
	margin.add_theme_constant_override("margin_bottom", 10)
	header.add_child(margin)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 9)
	margin.add_child(row)

	var identity := VBoxContainer.new()
	identity.custom_minimum_size = Vector2(330, 0)
	identity.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	identity.add_theme_constant_override("separation", -2)
	row.add_child(identity)
	var title := Label.new()
	title.text = "TRÀ ĐÁ TÁ LẢ"
	title.add_theme_font_size_override("font_size", 25)
	title.add_theme_color_override("font_color", PresentationTheme.INK)
	identity.add_child(title)
	var subtitle := Label.new()
	subtitle.text = "SOLO PHỎM  •  MỘT BÀN, HAI PHASE, BỐN LƯỢT"
	subtitle.add_theme_font_size_override("font_size", 10)
	subtitle.add_theme_color_override("font_color", PresentationTheme.GOLD)
	identity.add_child(subtitle)

	phase_value = _add_header_stat(row, "PHASE", 112)
	turn_value = _add_header_stat(row, "DISCARD CLOCK", 132)
	earnings_value = _add_header_stat(row, "PHASE EARNINGS", 164)
	wallet_value = _add_header_stat(row, "VÍ VND", 205, true)


func _add_header_stat(parent: Container, caption: String, minimum_width: float, emphasize: bool = false) -> Label:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(minimum_width, 52)
	panel.add_theme_stylebox_override("panel", PresentationTheme.panel_style(Color("#152f29d9"), Color("#294a40"), 1, 9, 0))
	parent.add_child(panel)
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 11)
	margin.add_theme_constant_override("margin_top", 6)
	margin.add_theme_constant_override("margin_right", 11)
	margin.add_theme_constant_override("margin_bottom", 5)
	panel.add_child(margin)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", -2)
	margin.add_child(column)
	var caption_label := Label.new()
	caption_label.text = caption
	caption_label.add_theme_font_size_override("font_size", 9)
	caption_label.add_theme_color_override("font_color", PresentationTheme.MUTED)
	column.add_child(caption_label)
	var value := Label.new()
	value.add_theme_font_size_override("font_size", 19 if emphasize else 16)
	value.add_theme_color_override("font_color", PresentationTheme.GOLD if emphasize else PresentationTheme.INK)
	value.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	column.add_child(value)
	return value


func _build_table() -> void:
	var table := Panel.new()
	table.name = "TableSurface"
	table.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	table.offset_left = 18
	table.offset_top = 102
	table.offset_right = -18
	table.offset_bottom = -252
	table.add_theme_stylebox_override("panel", PresentationTheme.panel_style(Color("#0c2924b8"), Color("#386353"), 1, 16, 7))
	add_child(table)

	phase_clock = Label.new()
	phase_clock.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	phase_clock.offset_left = 150
	phase_clock.offset_top = 12
	phase_clock.offset_right = -150
	phase_clock.offset_bottom = 38
	phase_clock.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	phase_clock.add_theme_font_size_override("font_size", 12)
	phase_clock.add_theme_color_override("font_color", PresentationTheme.GOLD)
	table.add_child(phase_clock)

	draw_pile_visual = _build_pile(table, true)
	discard_pile_visual = _build_pile(table, false)

	meld_scroll = ScrollContainer.new()
	meld_scroll.name = "MeldScroll"
	meld_scroll.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	meld_scroll.offset_left = 142
	meld_scroll.offset_top = 44
	meld_scroll.offset_right = -142
	meld_scroll.offset_bottom = -18
	meld_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	meld_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	table.add_child(meld_scroll)
	meld_row = HBoxContainer.new()
	meld_row.name = "MeldRow"
	meld_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	meld_row.size_flags_vertical = Control.SIZE_EXPAND_FILL
	meld_row.alignment = BoxContainer.ALIGNMENT_CENTER
	meld_row.add_theme_constant_override("separation", 12)
	meld_scroll.add_child(meld_row)

	empty_meld_label = Label.new()
	empty_meld_label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	empty_meld_label.offset_left = 165
	empty_meld_label.offset_top = 72
	empty_meld_label.offset_right = -165
	empty_meld_label.offset_bottom = -28
	empty_meld_label.text = "BÀN PHỎM ĐANG TRỐNG\n\nChọn ít nhất 3 lá tạo thành Bộ hoặc Sảnh, rồi nhấn HẠ."
	empty_meld_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	empty_meld_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	empty_meld_label.add_theme_font_size_override("font_size", 13)
	empty_meld_label.add_theme_color_override("font_color", Color("#78978a"))
	empty_meld_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	table.add_child(empty_meld_label)


func _build_pile(parent: Control, is_draw_pile: bool) -> Control:
	var pile := Control.new()
	pile.name = "DrawPile" if is_draw_pile else "DiscardPile"
	pile.set_anchors_preset(Control.PRESET_CENTER_LEFT if is_draw_pile else Control.PRESET_CENTER_RIGHT)
	pile.size = Vector2(112, 192)
	pile.position = Vector2(18, -92) if is_draw_pile else Vector2(-130, -92)
	parent.add_child(pile)

	var caption := Label.new()
	caption.position = Vector2(0, 0)
	caption.size = Vector2(112, 21)
	caption.text = "NỌC • DRAW" if is_draw_pile else "RÁC • DISCARD"
	caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	caption.add_theme_font_size_override("font_size", 10)
	caption.add_theme_color_override("font_color", PresentationTheme.MUTED)
	pile.add_child(caption)

	for depth in range(3, 0, -1):
		var backing := TextureRect.new()
		backing.position = Vector2(13 + depth * 2, 26 - depth * 2)
		backing.size = CARD_SIZE
		backing.texture = load("res://cards/red_backing.png") as Texture2D
		backing.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		backing.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		backing.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		backing.mouse_filter = Control.MOUSE_FILTER_IGNORE
		backing.modulate = Color.WHITE if is_draw_pile else Color(1, 1, 1, 0.12)
		pile.add_child(backing)
		if not is_draw_pile and depth == 1:
			discard_texture = backing

	var badge := Label.new()
	badge.position = Vector2(28, 150)
	badge.size = Vector2(58, 28)
	badge.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	badge.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	badge.add_theme_font_size_override("font_size", 12)
	badge.add_theme_color_override("font_color", PresentationTheme.INK)
	badge.add_theme_stylebox_override("normal", PresentationTheme.panel_style(Color("#071613e6"), Color("#476d5e"), 1, 12, 2))
	pile.add_child(badge)
	if is_draw_pile:
		draw_count = badge
	else:
		discard_count_label = badge
	return pile


func _build_hand() -> void:
	var hand_panel := Panel.new()
	hand_panel.name = "LooseHand"
	hand_panel.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	hand_panel.offset_left = 18
	hand_panel.offset_top = -242
	hand_panel.offset_right = -18
	hand_panel.offset_bottom = -82
	hand_panel.add_theme_stylebox_override("panel", PresentationTheme.panel_style(Color("#0b211de8"), Color("#31594b"), 1, 14, 5))
	add_child(hand_panel)

	var label_row := HBoxContainer.new()
	label_row.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	label_row.offset_left = 15
	label_row.offset_top = 7
	label_row.offset_right = -15
	label_row.offset_bottom = 27
	hand_panel.add_child(label_row)
	hand_count = Label.new()
	hand_count.add_theme_font_size_override("font_size", 11)
	hand_count.add_theme_color_override("font_color", PresentationTheme.GOLD)
	hand_count.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label_row.add_child(hand_count)
	selection_label = Label.new()
	selection_label.add_theme_font_size_override("font_size", 11)
	selection_label.add_theme_color_override("font_color", PresentationTheme.TEA)
	label_row.add_child(selection_label)

	hand_layer = Control.new()
	hand_layer.name = "CardFan"
	hand_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	hand_layer.offset_left = 10
	hand_layer.offset_top = 27
	hand_layer.offset_right = -10
	hand_layer.offset_bottom = 4
	hand_layer.clip_contents = false
	hand_panel.add_child(hand_layer)


func _build_action_dock() -> void:
	var dock := Panel.new()
	dock.name = "ActionDock"
	dock.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	dock.offset_left = 18
	dock.offset_top = -72
	dock.offset_right = -18
	dock.offset_bottom = -14
	dock.add_theme_stylebox_override("panel", PresentationTheme.panel_style(Color("#0b1b18f2"), Color("#315246"), 1, 13, 6))
	add_child(dock)

	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 14)
	margin.add_theme_constant_override("margin_top", 8)
	margin.add_theme_constant_override("margin_right", 9)
	margin.add_theme_constant_override("margin_bottom", 8)
	dock.add_child(margin)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	margin.add_child(row)
	status_label = Label.new()
	status_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	status_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	status_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	status_label.add_theme_font_size_override("font_size", 12)
	status_label.add_theme_color_override("font_color", PresentationTheme.MUTED)
	row.add_child(status_label)

	sort_button = _make_action_button(row, "SẮP BÀI  [S]", "neutral", 104)
	sort_button.tooltip_text = "Cycle between rank and suit sorting."
	sort_button.pressed.connect(_on_sort_pressed)
	ha_button = _make_action_button(row, "HẠ  [H]", "tea", 108)
	ha_button.tooltip_text = "Commit the selected cards as a new Set or Run."
	ha_button.pressed.connect(_on_ha_pressed)
	extend_button = _make_action_button(row, "EXTEND  [E]", "gold", 116)
	extend_button.tooltip_text = "Add selected cards to the targeted table Meld."
	extend_button.pressed.connect(_on_extend_pressed)
	discard_button = _make_action_button(row, "DISCARD  [D]", "danger", 120)
	discard_button.tooltip_text = "Discard exactly one loose card and end the turn."
	discard_button.pressed.connect(_on_discard_pressed)


func _make_action_button(parent: Container, text_value: String, tone: String, width: float) -> Button:
	var button := Button.new()
	button.text = text_value
	button.custom_minimum_size = Vector2(width, 40)
	PresentationTheme.configure_button(button, tone)
	parent.add_child(button)
	return button


func _build_effect_layers() -> void:
	particle_layer = Control.new()
	particle_layer.name = "MotionEffects"
	particle_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	particle_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	particle_layer.z_index = 100
	add_child(particle_layer)

	_build_score_overlay()
	_build_banner()
	_build_modal()


func _build_score_overlay() -> void:
	score_overlay = Control.new()
	score_overlay.name = "ScoreFeedback"
	score_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	score_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	score_overlay.z_index = 120
	score_overlay.visible = false
	add_child(score_overlay)

	score_panel = Panel.new()
	score_panel.set_anchors_preset(Control.PRESET_CENTER)
	score_panel.position = Vector2(-270, -112)
	score_panel.size = Vector2(540, 224)
	score_panel.pivot_offset = score_panel.size * 0.5
	score_panel.add_theme_stylebox_override("panel", PresentationTheme.panel_style(Color("#0b1d19f7"), PresentationTheme.GOLD, 2, 18, 12))
	score_overlay.add_child(score_panel)

	var accent := ColorRect.new()
	accent.position = Vector2(18, 16)
	accent.size = Vector2(4, 192)
	accent.color = PresentationTheme.GOLD
	accent.mouse_filter = Control.MOUSE_FILTER_IGNORE
	score_panel.add_child(accent)
	score_title = _score_label(score_panel, Vector2(38, 18), Vector2(482, 31), 13, PresentationTheme.GOLD)
	score_line_a = _score_label(score_panel, Vector2(38, 57), Vector2(482, 41), 20, PresentationTheme.INK)
	score_line_b = _score_label(score_panel, Vector2(38, 100), Vector2(482, 41), 20, PresentationTheme.INK)
	score_payout = _score_label(score_panel, Vector2(38, 151), Vector2(482, 52), 28, PresentationTheme.TEA)


func _score_label(parent: Control, at: Vector2, label_size: Vector2, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.position = at
	label.size = label_size
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	parent.add_child(label)
	return label


func _build_banner() -> void:
	banner_panel = PanelContainer.new()
	banner_panel.name = "TurnBanner"
	banner_panel.set_anchors_preset(Control.PRESET_CENTER_TOP)
	banner_panel.position = Vector2(-250, 103)
	banner_panel.size = Vector2(500, 38)
	banner_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	banner_panel.z_index = 140
	banner_panel.modulate = Color(1, 1, 1, 0)
	banner_panel.add_theme_stylebox_override("panel", PresentationTheme.panel_style(Color("#132d27f4"), PresentationTheme.GOLD_DARK, 1, 16, 6))
	add_child(banner_panel)
	banner_label = Label.new()
	banner_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	banner_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	banner_label.add_theme_font_size_override("font_size", 11)
	banner_label.add_theme_color_override("font_color", PresentationTheme.INK)
	banner_panel.add_child(banner_label)


func _build_modal() -> void:
	modal_overlay = Control.new()
	modal_overlay.name = "DecisionOverlay"
	modal_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	modal_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	modal_overlay.z_index = 200
	modal_overlay.visible = false
	add_child(modal_overlay)
	var dim := ColorRect.new()
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.color = Color("#020907c7")
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	modal_overlay.add_child(dim)
	var panel := Panel.new()
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.position = Vector2(-310, -205)
	panel.size = Vector2(620, 410)
	panel.add_theme_stylebox_override("panel", PresentationTheme.panel_style(Color("#102a24ff"), PresentationTheme.GOLD, 2, 20, 16))
	modal_overlay.add_child(panel)
	var column := VBoxContainer.new()
	column.position = Vector2(38, 30)
	column.size = Vector2(544, 350)
	column.add_theme_constant_override("separation", 10)
	panel.add_child(column)
	modal_kicker = Label.new()
	modal_kicker.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	modal_kicker.add_theme_font_size_override("font_size", 11)
	modal_kicker.add_theme_color_override("font_color", PresentationTheme.GOLD)
	column.add_child(modal_kicker)
	modal_title = Label.new()
	modal_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	modal_title.add_theme_font_size_override("font_size", 31)
	modal_title.add_theme_color_override("font_color", PresentationTheme.INK)
	column.add_child(modal_title)
	modal_body = Label.new()
	modal_body.custom_minimum_size = Vector2(0, 82)
	modal_body.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	modal_body.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	modal_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	modal_body.add_theme_font_size_override("font_size", 15)
	modal_body.add_theme_color_override("font_color", PresentationTheme.MUTED)
	column.add_child(modal_body)
	modal_detail = Label.new()
	modal_detail.custom_minimum_size = Vector2(0, 60)
	modal_detail.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	modal_detail.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	modal_detail.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	modal_detail.add_theme_font_size_override("font_size", 12)
	modal_detail.add_theme_color_override("font_color", PresentationTheme.TEA)
	column.add_child(modal_detail)
	var buttons := HBoxContainer.new()
	buttons.alignment = BoxContainer.ALIGNMENT_CENTER
	buttons.add_theme_constant_override("separation", 14)
	column.add_child(buttons)
	modal_primary = _make_action_button(buttons, "KEEP", "tea", 206)
	modal_primary.custom_minimum_size.y = 52
	modal_primary.pressed.connect(_on_modal_primary_pressed)
	modal_secondary = _make_action_button(buttons, "DUMP", "danger", 206)
	modal_secondary.custom_minimum_size.y = 52
	modal_secondary.pressed.connect(_on_modal_secondary_pressed)


func _sync_all(result: Dictionary = {}, animate_all_cards: bool = false) -> void:
	var animated_cards := _cards_from_result(result)
	if animate_all_cards:
		animated_cards.clear()
		animated_cards.append_array(deal.hand)
	_sync_hand(animated_cards)
	_sync_melds()
	_sync_piles()
	_refresh_stats()
	_refresh_actions()


func _sync_hand(animated_cards: Array[CardData]) -> void:
	var active_ids := {}
	var animated_ids := {}
	for card in animated_cards:
		animated_ids[card.unique_id] = true
	for card in deal.hand:
		active_ids[card.unique_id] = true
		if not hand_views.has(card.unique_id):
			var view := PlayingCardView.new()
			hand_layer.add_child(view)
			view.set_card(card)
			view.card_pressed.connect(_on_card_pressed)
			hand_views[card.unique_id] = view
			if animated_ids.has(card.unique_id):
				var origin := draw_pile_visual.get_global_rect().get_center() - hand_layer.global_position
				view.spawn_from(origin)
	for existing_id in hand_views.keys():
		if not active_ids.has(existing_id):
			var old_view: PlayingCardView = hand_views[existing_id]
			old_view.queue_free()
			hand_views.erase(existing_id)
	_layout_hand(true)


func _layout_hand(animate: bool) -> void:
	if hand_layer == null or hand_layer.size.x <= 0:
		return
	var count := deal.hand.size()
	if count == 0:
		return
	var spacing := 0.0
	if count > 1:
		spacing = minf(76.0, maxf((hand_layer.size.x - CARD_SIZE.x - 34.0) / float(count - 1), 28.0))
	var total_width := CARD_SIZE.x + spacing * float(count - 1)
	var start_x := (hand_layer.size.x - total_width) * 0.5
	for index in range(count):
		var card := deal.hand[index]
		var view: PlayingCardView = hand_views[card.unique_id]
		var normalized := 0.0 if count == 1 else (float(index) / float(count - 1) - 0.5) * 2.0
		var arc_y := 9.0 + normalized * normalized * 14.0
		view.z_index = index + (100 if selected_card_ids.has(card.unique_id) else 0)
		view.set_selected(selected_card_ids.has(card.unique_id), false)
		view.layout_to(Vector2(start_x + spacing * index, arc_y), normalized * 0.055, animate)


func _sync_melds() -> void:
	for child in meld_row.get_children():
		child.queue_free()
	empty_meld_label.visible = deal.melds.is_empty()
	if deal.melds.is_empty():
		selected_meld_id = -1
		return
	if selected_meld_id >= 0 and deal.get_meld(selected_meld_id) == null:
		selected_meld_id = -1
	var selected_cards := _selected_cards()
	for meld in deal.melds:
		var view := MeldView.new()
		meld_row.add_child(view)
		var legal := deal.can_extend_meld(meld.meld_id, selected_cards)
		view.set_meld(meld, meld.meld_id == selected_meld_id, legal)
		view.meld_pressed.connect(_on_meld_pressed)
		view.modulate = Color(1, 1, 1, 0)
		view.scale = Vector2(0.94, 0.94)
		var tween := view.create_tween().set_parallel(true)
		tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tween.tween_property(view, "modulate", Color.WHITE, 0.18)
		tween.tween_property(view, "scale", Vector2.ONE, 0.2)


func _sync_piles() -> void:
	draw_count.text = "%d LÁ" % deal.deck.draw_pile.size()
	discard_count_label.text = "%d LÁ" % deal.deck.discard_pile.size()
	if deal.deck.discard_pile.is_empty():
		discard_texture.texture = load("res://cards/red_backing.png") as Texture2D
		discard_texture.modulate = Color(1, 1, 1, 0.12)
	else:
		discard_texture.texture = load(deal.deck.discard_pile[-1].texture_path()) as Texture2D
		discard_texture.modulate = Color.WHITE


func _refresh_stats() -> void:
	phase_value.text = "%d / 2" % deal.current_phase
	turn_value.text = "%d / %d" % [deal.discard_count, DealState.DISCARDS_PER_PHASE]
	earnings_value.text = VndWallet.format_vnd(VndWallet.points_to_vnd(deal.phase_earnings_points), true)
	wallet_value.text = VndWallet.format_vnd(displayed_wallet_vnd)
	phase_clock.text = "PHASE %d   •   DISCARD %d OF %d   •   NEW MELDS %d" % [deal.current_phase, deal.discard_count, DealState.DISCARDS_PER_PHASE, deal.phase_new_meld_count]
	hand_count.text = "BÀI RỜI  •  %d LÁ  •  ACTIVE TARGET %d" % [deal.hand.size(), DealState.ACTIVE_HAND_TARGET]
	var selected := _selected_cards()
	var selected_sum := 0
	for card in selected:
		selected_sum += card.score_value()
	selection_label.text = "%d CHỌN  •  Σ %d" % [selected.size(), selected_sum]


func _refresh_actions() -> void:
	var selected := _selected_cards()
	var active := deal.state == DealState.STATE_ACTIVE and not interaction_locked
	ha_button.disabled = not active or not deal.can_create_meld(selected)
	extend_button.disabled = not active or selected_meld_id < 0 or not deal.can_extend_meld(selected_meld_id, selected)
	discard_button.disabled = not active or selected.size() != 1
	sort_button.disabled = not active or deal.hand.size() < 2
	if interaction_locked:
		status_label.text = "ĐANG GIẢI QUYẾT…"
		status_label.add_theme_color_override("font_color", PresentationTheme.MUTED)
		return
	if deal.state == DealState.STATE_PHASE_CHOICE:
		status_label.text = "PHASE 1 ĐÃ KHÉP LẠI  •  CHỌN KEEP HOẶC DUMP"
		return
	if deal.state == DealState.STATE_DEAL_OVER:
		status_label.text = "VÁN ĐÃ KẾT THÚC"
		return
	if selected.is_empty():
		status_label.text = "CHỌN BÀI  •  HẠ BỘ/SẢNH  •  HOẶC CHỌN 1 LÁ ĐỂ DISCARD"
		status_label.add_theme_color_override("font_color", PresentationTheme.MUTED)
	elif deal.can_create_meld(selected):
		var kind := MeldRules.classify(selected)
		status_label.text = "%s HỢP LỆ  •  NHẤN HẠ ĐỂ GHI ĐIỂM" % ("SẢNH" if kind == MeldRules.TYPE_RUN else "BỘ")
		status_label.add_theme_color_override("font_color", PresentationTheme.TEA)
	elif selected_meld_id >= 0 and deal.can_extend_meld(selected_meld_id, selected):
		status_label.text = "GHÉP HỢP LỆ VÀO PHỎM %02d  •  NHẤN EXTEND" % selected_meld_id
		status_label.add_theme_color_override("font_color", PresentationTheme.GOLD)
	elif selected.size() == 1:
		status_label.text = "1 LÁ ĐÃ CHỌN  •  DISCARD, HOẶC CHỌN THÊM ĐỂ TẠO PHỎM"
		status_label.add_theme_color_override("font_color", PresentationTheme.INK)
	else:
		status_label.text = "CHƯA THÀNH BỘ/SẢNH  •  ĐIỀU CHỈNH LỰA CHỌN"
		status_label.add_theme_color_override("font_color", PresentationTheme.RED)


func _on_card_pressed(card: CardData) -> void:
	if interaction_locked or deal.state != DealState.STATE_ACTIVE:
		return
	if selected_card_ids.has(card.unique_id):
		selected_card_ids.erase(card.unique_id)
	else:
		selected_card_ids[card.unique_id] = true
	_layout_hand(true)
	_sync_melds()
	_refresh_stats()
	_refresh_actions()


func _on_meld_pressed(meld_id: int) -> void:
	if interaction_locked or deal.state != DealState.STATE_ACTIVE:
		return
	selected_meld_id = -1 if selected_meld_id == meld_id else meld_id
	_sync_melds()
	_refresh_actions()


func _on_ha_pressed() -> void:
	if ha_button.disabled:
		return
	var selected := _selected_cards()
	interaction_locked = true
	_refresh_actions()
	await _fly_cards(selected, meld_scroll.get_global_rect().get_center())
	var result := deal.create_meld(selected)
	if not result.get("ok", false):
		_reject_action(result.get("message", "Hạ failed."))
		return
	selected_card_ids.clear()
	selected_meld_id = result["meld_id"]
	_sync_all(result)
	await _show_scoring(result["context"])
	interaction_locked = false
	_refresh_actions()


func _on_extend_pressed() -> void:
	if extend_button.disabled:
		return
	var selected := _selected_cards()
	interaction_locked = true
	_refresh_actions()
	await _fly_cards(selected, meld_scroll.get_global_rect().get_center())
	var result := deal.extend_meld(selected_meld_id, selected)
	if not result.get("ok", false):
		_reject_action(result.get("message", "Extension failed."))
		return
	selected_card_ids.clear()
	_sync_all(result)
	await _show_scoring(result["context"])
	interaction_locked = false
	_refresh_actions()


func _on_discard_pressed() -> void:
	if discard_button.disabled:
		return
	var selected := _selected_cards()
	var card := selected[0]
	interaction_locked = true
	_refresh_actions()
	await _fly_cards(selected, discard_texture.get_global_rect().get_center())
	var result := deal.discard_card(card)
	if not result.get("ok", false):
		_reject_action(result.get("message", "Discard failed."))
		return
	selected_card_ids.clear()
	_sync_all(result)
	if result.has("phase_resolution"):
		var resolution: Dictionary = result["phase_resolution"]
		await _show_phase_resolution(resolution)
		if resolution["phase"] == 1:
			_show_phase_choice(resolution)
		else:
			_show_deal_over(resolution)
	else:
		var drawn: Array[CardData] = _cards_from_result(result)
		_show_banner("RÚT %d LÁ  •  DISCARD %d / %d" % [drawn.size(), deal.discard_count, DealState.DISCARDS_PER_PHASE])
		interaction_locked = false
		_refresh_actions()


func _on_sort_pressed() -> void:
	if sort_button.disabled:
		return
	sort_mode = (sort_mode + 1) % 2
	if sort_mode == 0:
		deal.hand.sort_custom(func(left: CardData, right: CardData) -> bool:
			if left.rank_index == right.rank_index:
				return DeckManager.SUITS.find(left.suit) < DeckManager.SUITS.find(right.suit)
			return left.rank_index < right.rank_index
		)
		sort_button.text = "SẮP: SỐ  [S]"
	else:
		deal.hand.sort_custom(func(left: CardData, right: CardData) -> bool:
			var left_suit := DeckManager.SUITS.find(left.suit)
			var right_suit := DeckManager.SUITS.find(right.suit)
			if left_suit == right_suit:
				return left.rank_index < right.rank_index
			return left_suit < right_suit
		)
		sort_button.text = "SẮP: CHẤT  [S]"
	_layout_hand(true)


func _show_scoring(context: ScoringContext) -> void:
	var kind := "SẢNH" if context.meld_type == MeldRules.TYPE_RUN else "BỘ"
	if context.action_type == "new_meld":
		score_title.text = "HẠ THÀNH CÔNG  •  %s  •  PHASE %d" % [kind, context.phase]
		score_line_a.text = "%s   →   %d" % [context.value_equation(), context.card_value_sum]
		score_line_b.text = "%d × %d   →   %d ĐIỂM" % [context.base_score, context.local_mult, context.theoretical_score]
		score_payout.text = "%d × ₫1.000   →   %s" % [context.final_points, VndWallet.format_vnd(VndWallet.points_to_vnd(context.final_points), true)]
	else:
		score_title.text = "EXTEND THÀNH CÔNG  •  %s  •  PHASE %d" % [kind, context.phase]
		score_line_a.text = "ĐIỂM CŨ  %d   →   ĐIỂM MỚI  %d" % [context.old_meld_score, context.theoretical_score]
		score_line_b.text = "%d − %d   →   +%d ĐIỂM" % [context.theoretical_score, context.old_meld_score, context.final_points]
		score_payout.text = "PHẦN TĂNG   →   %s" % VndWallet.format_vnd(VndWallet.points_to_vnd(context.final_points), true)
	await _play_score_panel(deal.wallet.balance_vnd, context.final_points >= 0)


func _show_phase_resolution(resolution: Dictionary) -> void:
	var is_mom: bool = resolution["mom"]
	var phase_number: int = resolution["phase"]
	score_title.text = "PHASE %d SETTLEMENT" % phase_number
	if is_mom:
		score_line_a.text = "MÓM  •  KHÔNG CÓ PHỎM MỚI TRONG PHASE"
		score_line_a.add_theme_color_override("font_color", PresentationTheme.RED)
		score_line_b.text = "HOÀN TRẢ ĐIỂM DƯƠNG   →   −%d ĐIỂM" % resolution["forfeit_points"]
	else:
		score_line_a.text = "KHÔNG MÓM  •  ĐÃ HẠ %d PHỎM MỚI" % deal.phase_new_meld_count
		score_line_a.add_theme_color_override("font_color", PresentationTheme.TEA)
		score_line_b.text = "PHASE EARNINGS ĐƯỢC GIỮ LẠI"
	if phase_number == 2:
		var deadwood: int = resolution["deadwood_points"]
		score_payout.text = "DEADWOOD   →   %s" % VndWallet.format_vnd(-VndWallet.points_to_vnd(deadwood))
	else:
		score_payout.text = "CHUẨN BỊ QUYẾT ĐỊNH KEEP / DUMP"
	await _play_score_panel(deal.wallet.balance_vnd, not is_mom)
	score_line_a.add_theme_color_override("font_color", PresentationTheme.INK)


func _play_score_panel(target_wallet: int, positive: bool) -> void:
	score_overlay.visible = true
	score_panel.scale = Vector2(0.84, 0.84)
	score_panel.modulate = Color(1, 1, 1, 0)
	for label in [score_line_a, score_line_b, score_payout]:
		label.modulate = Color(1, 1, 1, 0)
	var intro := create_tween().set_parallel(true)
	intro.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	intro.tween_property(score_panel, "scale", Vector2.ONE, 0.24)
	intro.tween_property(score_panel, "modulate", Color.WHITE, 0.14)
	await intro.finished
	await _reveal_score_label(score_line_a)
	await _reveal_score_label(score_line_b)
	await _reveal_score_label(score_payout)
	await _animate_wallet_to(target_wallet, 0.52)
	_spawn_money_float(target_wallet - displayed_wallet_vnd, positive)
	await get_tree().create_timer(0.34).timeout
	var outro := create_tween().set_parallel(true)
	outro.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	outro.tween_property(score_panel, "scale", Vector2(1.04, 1.04), 0.14)
	outro.tween_property(score_panel, "modulate", Color(1, 1, 1, 0), 0.14)
	await outro.finished
	score_overlay.visible = false


func _reveal_score_label(label: Label) -> void:
	label.position.x -= 13
	var target_x := label.position.x + 13
	var tween := create_tween().set_parallel(true)
	tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(label, "position:x", target_x, 0.16)
	tween.tween_property(label, "modulate", Color.WHITE, 0.12)
	await tween.finished
	await get_tree().create_timer(0.08).timeout


func _animate_wallet_to(target: int, duration: float) -> void:
	if displayed_wallet_vnd == target:
		_refresh_stats()
		return
	var tween := create_tween()
	tween.set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)
	tween.tween_method(_set_displayed_wallet, float(displayed_wallet_vnd), float(target), duration)
	await tween.finished
	_set_displayed_wallet(float(target))


func _set_displayed_wallet(value: float) -> void:
	displayed_wallet_vnd = int(round(value))
	wallet_value.text = VndWallet.format_vnd(displayed_wallet_vnd)


func _spawn_money_float(_delta_vnd: int, positive: bool) -> void:
	var label := Label.new()
	label.text = VndWallet.format_vnd(deal.wallet.balance_vnd)
	label.position = wallet_value.global_position - particle_layer.global_position + Vector2(0, 14)
	label.add_theme_font_size_override("font_size", 17)
	label.add_theme_color_override("font_color", PresentationTheme.TEA if positive else PresentationTheme.RED)
	particle_layer.add_child(label)
	var tween := create_tween().set_parallel(true)
	tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(label, "position:y", label.position.y - 42, 0.72)
	tween.tween_property(label, "modulate", Color(1, 1, 1, 0), 0.72).set_delay(0.16)
	tween.chain().tween_callback(label.queue_free)


func _show_phase_choice(resolution: Dictionary) -> void:
	interaction_locked = false
	modal_mode = "phase_choice"
	modal_kicker.text = "PHASE 1 COMPLETE  •  %s" % ("MÓM" if resolution["mom"] else "SAFE")
	modal_title.text = "GIỮ BÀI HAY ĐỔI BÀN?"
	modal_body.text = "KEEP mang toàn bộ %d lá bài rời sang Phase 2.\nDUMP bỏ cả tay và rút một tay mới — không có mulligan chọn lọc." % deal.hand.size()
	modal_detail.text = "Các Phỏm đã Hạ vẫn nằm trên bàn và có thể EXTEND trong Phase 2.\nChỉ một Phỏm MỚI mới tránh được Móm Phase 2."
	modal_primary.text = "KEEP  [K]\nGIỮ %d LÁ" % deal.hand.size()
	modal_secondary.text = "DUMP  [X]\nĐỔI TOÀN BỘ"
	modal_secondary.visible = true
	_show_modal()
	_refresh_actions()


func _show_deal_over(resolution: Dictionary) -> void:
	interaction_locked = false
	modal_mode = "deal_over"
	modal_kicker.text = "DEAL COMPLETE  •  PHASE 2 %s" % ("MÓM" if resolution["mom"] else "SAFE")
	modal_title.text = VndWallet.format_vnd(deal.wallet.balance_vnd)
	modal_body.text = "Ví cuối ván sau khi giải quyết Móm và Deadwood.\nBạn đã Hạ %d Phỏm trên bàn." % deal.melds.size()
	modal_detail.text = "DEADWOOD: %d ĐIỂM  •  %d LÁ CÒN LẠI\nVán mới giữ nguyên Ví VND và chia bộ bài mới." % [resolution["deadwood_points"], deal.hand.size()]
	modal_primary.text = "CHIA VÁN MỚI  [R]"
	modal_secondary.visible = false
	_show_modal()
	_refresh_actions()


func _show_modal() -> void:
	_set_hand_interaction_enabled(false)
	modal_overlay.visible = true
	modal_overlay.modulate = Color(1, 1, 1, 0)
	var panel: Panel = modal_title.get_parent().get_parent()
	panel.scale = Vector2(0.95, 0.95)
	panel.pivot_offset = panel.size * 0.5
	var tween := create_tween().set_parallel(true)
	tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(modal_overlay, "modulate", Color.WHITE, 0.18)
	tween.tween_property(panel, "scale", Vector2.ONE, 0.22)


func _on_modal_primary_pressed() -> void:
	if modal_mode == "phase_choice":
		_begin_phase_two(true)
	elif modal_mode == "deal_over":
		_start_new_deal()


func _on_modal_secondary_pressed() -> void:
	if modal_mode == "phase_choice":
		_begin_phase_two(false)


func _begin_phase_two(keep_hand: bool) -> void:
	if interaction_locked:
		return
	interaction_locked = true
	modal_overlay.visible = false
	_set_hand_interaction_enabled(true)
	if not keep_hand:
		await _fly_cards(deal.hand, discard_texture.get_global_rect().get_center())
	var result := deal.choose_phase_two(keep_hand)
	if not result.get("ok", false):
		_reject_action(result.get("message", "Phase transition failed."))
		return
	selected_card_ids.clear()
	selected_meld_id = -1
	_sync_all(result)
	_show_banner("PHASE 2  •  %s  •  HẠ ÍT NHẤT 1 PHỎM MỚI" % ("KEEP" if keep_hand else "DUMP"))
	interaction_locked = false
	_refresh_actions()


func _start_new_deal() -> void:
	if interaction_locked:
		return
	interaction_locked = true
	modal_overlay.visible = false
	_set_hand_interaction_enabled(true)
	selected_card_ids.clear()
	selected_meld_id = -1
	var result := deal.start_deal(-1, false)
	displayed_wallet_vnd = deal.wallet.balance_vnd
	_sync_all(result, true)
	_show_banner("VÁN MỚI  •  VÍ VND ĐƯỢC GIỮ NGUYÊN")
	interaction_locked = false
	_refresh_actions()


func _fly_cards(cards: Array[CardData], target_global: Vector2) -> void:
	if cards.is_empty():
		return
	var target_local := target_global - particle_layer.global_position
	var tween := create_tween().set_parallel(true)
	for index in range(cards.size()):
		var card := cards[index]
		if not hand_views.has(card.unique_id):
			continue
		var source: PlayingCardView = hand_views[card.unique_id]
		var ghost := TextureRect.new()
		ghost.texture = load(card.texture_path()) as Texture2D
		ghost.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		ghost.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		ghost.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		ghost.position = source.global_position - particle_layer.global_position
		ghost.size = CARD_SIZE
		ghost.pivot_offset = CARD_SIZE * 0.5
		ghost.rotation = source.rotation
		particle_layer.add_child(ghost)
		var delay := index * 0.035
		tween.tween_property(ghost, "position", target_local - CARD_SIZE * 0.36 + Vector2(index * 5, 0), 0.25).set_delay(delay).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		tween.tween_property(ghost, "scale", Vector2(0.72, 0.72), 0.25).set_delay(delay)
		tween.tween_property(ghost, "rotation", 0.02 * (index - cards.size() * 0.5), 0.25).set_delay(delay)
		tween.tween_property(ghost, "modulate", Color(1, 1, 1, 0), 0.09).set_delay(delay + 0.2)
		tween.tween_callback(ghost.queue_free).set_delay(delay + 0.3)
	await tween.finished


func _show_banner(message: String) -> void:
	banner_label.text = message
	banner_panel.position.y = 94
	banner_panel.modulate = Color(1, 1, 1, 0)
	var tween := create_tween()
	tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(banner_panel, "modulate", Color.WHITE, 0.14)
	tween.parallel().tween_property(banner_panel, "position:y", 104, 0.2)
	tween.tween_interval(1.25)
	tween.set_ease(Tween.EASE_IN)
	tween.tween_property(banner_panel, "modulate", Color(1, 1, 1, 0), 0.22)


func _reject_action(message: String) -> void:
	interaction_locked = false
	status_label.text = message.to_upper()
	status_label.add_theme_color_override("font_color", PresentationTheme.RED)
	for card in _selected_cards():
		if hand_views.has(card.unique_id):
			hand_views[card.unique_id].play_reject()
	_refresh_actions()


func _selected_cards() -> Array[CardData]:
	var selected: Array[CardData] = []
	for card in deal.hand:
		if selected_card_ids.has(card.unique_id):
			selected.append(card)
	return selected


func _set_hand_interaction_enabled(enabled: bool) -> void:
	for value in hand_views.values():
		var view := value as PlayingCardView
		if view != null:
			view.set_interaction_enabled(enabled)


func _cards_from_result(result: Dictionary) -> Array[CardData]:
	var cards: Array[CardData] = []
	for key in ["resting_cards", "drawn"]:
		if result.has(key):
			for value in result[key]:
				if value is CardData:
					cards.append(value)
	return cards


func _on_viewport_size_changed() -> void:
	_layout_hand(false)


func _unhandled_key_input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed or event.echo:
		return
	if modal_overlay.visible:
		if modal_mode == "phase_choice" and event.keycode == KEY_K:
			_begin_phase_two(true)
		elif modal_mode == "phase_choice" and event.keycode == KEY_X:
			_begin_phase_two(false)
		elif modal_mode == "deal_over" and event.keycode == KEY_R:
			_start_new_deal()
		return
	match event.keycode:
		KEY_H:
			if not ha_button.disabled:
				_on_ha_pressed()
		KEY_E:
			if not extend_button.disabled:
				_on_extend_pressed()
		KEY_D:
			if not discard_button.disabled:
				_on_discard_pressed()
		KEY_S:
			if not sort_button.disabled:
				_on_sort_pressed()
		KEY_ESCAPE:
			selected_card_ids.clear()
			selected_meld_id = -1
			_sync_all()
