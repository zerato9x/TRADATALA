class_name DeckScreen
extends Control

## One read-only view of physical campaign cards. A caller may supply a commit
## callback; the owning service still validates the chosen physical ID.
signal closed()

var _cards: Array[CardData] = []
var _allowed: Dictionary = {}
var _on_choose: Callable
var _selected: CardData
var _title: Label
var _purpose: Label
var _grid: GridContainer
var _detail: VBoxContainer
var _confirm: Button
var _sort: OptionButton
var _search: LineEdit
var _scroll: ScrollContainer

func _ready() -> void:
	name = "DeckScreen"
	theme = PresentationTheme.create_game_theme()
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	z_index = 300
	var dim := ColorRect.new()
	dim.color = Color(0.015, 0.025, 0.035, 0.96)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(dim)
	var panel := PanelContainer.new()
	panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	panel.offset_left = 28
	panel.offset_top = 20
	panel.offset_right = -28
	panel.offset_bottom = -20
	panel.add_theme_stylebox_override("panel", PresentationTheme.panel_style(Color("#10232b"), PresentationTheme.GOLD_DARK, 2, 10, 8))
	add_child(panel)
	var margin := MarginContainer.new()
	for side in [&"left", &"right", &"top", &"bottom"]:
		margin.add_theme_constant_override("margin_" + side, 16)
	panel.add_child(margin)
	var body := VBoxContainer.new()
	body.add_theme_constant_override("separation", 10)
	margin.add_child(body)
	var top := HBoxContainer.new()
	top.add_theme_constant_override("separation", 12)
	body.add_child(top)
	_title = Label.new()
	_title.add_theme_font_size_override("font_size", 27)
	_title.add_theme_color_override("font_color", PresentationTheme.GOLD)
	_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(_title)
	var back := Button.new()
	back.name = "DeckBack"
	back.text = _words("Back to the table", "Về bàn")
	back.custom_minimum_size = Vector2(170, 44)
	PresentationTheme.configure_button(back, "tea")
	back.pressed.connect(close)
	top.add_child(back)
	_purpose = Label.new()
	_purpose.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_purpose.add_theme_font_size_override("font_size", 16)
	var tools_row := HBoxContainer.new()
	tools_row.add_theme_constant_override("separation", 12)
	body.add_child(tools_row)
	_sort = OptionButton.new()
	_sort.name = "DeckSort"
	for caption in [_words("Suit, then rank", "Chất rồi số"), _words("Rank, then suit", "Số rồi chất"), _words("Changed first", "Lá đã đổi lên trước")]:
		_sort.add_item(caption)
	_sort.item_selected.connect(func(_index: int): _rebuild_cards())
	tools_row.add_child(_sort)
	_search = LineEdit.new()
	_search.name = "DeckSearch"
	_search.placeholder_text = _words("Find a card by rank, suit, or original identity", "Tìm theo số, chất hoặc lá gốc")
	_search.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_search.text_changed.connect(func(_query: String): _rebuild_cards())
	tools_row.add_child(_search)
	var columns := HBoxContainer.new()
	columns.size_flags_vertical = Control.SIZE_EXPAND_FILL
	columns.add_theme_constant_override("separation", 16)
	body.add_child(columns)
	_scroll = ScrollContainer.new()
	_scroll.name = "DeckCardsScroll"
	_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	columns.add_child(_scroll)
	_grid = GridContainer.new()
	_grid.columns = 10
	_grid.add_theme_constant_override("h_separation", 6)
	_grid.add_theme_constant_override("v_separation", 8)
	_scroll.add_child(_grid)
	var detail_panel := PanelContainer.new()
	detail_panel.custom_minimum_size.x = 265
	detail_panel.add_theme_stylebox_override("panel", PresentationTheme.panel_style(Color("#18313a"), PresentationTheme.TEA, 1, 8, 5))
	columns.add_child(detail_panel)
	var detail_scroll := ScrollContainer.new()
	detail_scroll.custom_minimum_size.x = 250
	detail_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	detail_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	detail_panel.add_child(detail_scroll)
	_detail = VBoxContainer.new()
	_detail.custom_minimum_size.x = 238
	_detail.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_detail.add_theme_constant_override("separation", 10)
	detail_scroll.add_child(_detail)
	body.add_child(_purpose)
	_confirm = Button.new()
	_confirm.name = "DeckChoose"
	_confirm.custom_minimum_size.y = 48
	_confirm.text = _words("Choose this card", "Chọn lá này")
	PresentationTheme.configure_button(_confirm, "gold")
	_confirm.pressed.connect(_choose)
	body.add_child(_confirm)
	_scroll.resized.connect(_fit_grid)
	hide()

func _fit_grid() -> void:
	_grid.columns = maxi(1, floori((_scroll.size.x - 12) / 78.0))

func open_deck(cards: Array[CardData], title_text: String, purpose_text: String, allowed_cards: Array[CardData] = [], on_choose: Callable = Callable()) -> void:
	_cards = cards.duplicate()
	_allowed.clear()
	for card in allowed_cards:
		_allowed[card.unique_id] = true
	_on_choose = on_choose
	_selected = null
	_title.text = title_text + "  ·  %d" % _cards.size()
	if on_choose.is_valid() and _allowed.size() < _cards.size():
		_title.text += "  ·  " + (_words("%d offered", "%d lá có thể chọn") % _allowed.size())
	# Selection consequences belong to the picker; browsing needs no tagline.
	_purpose.text = purpose_text if on_choose.is_valid() else ""
	_purpose.visible = on_choose.is_valid() and not purpose_text.is_empty()
	_title.tooltip_text = purpose_text
	_search.clear()
	_sort.select(0)
	_rebuild_cards()
	_show_detail()
	show()
	move_to_front()
	_search.grab_focus()

func close() -> void:
	if not visible: return
	hide()
	_on_choose = Callable()
	closed.emit()

func _unhandled_key_input(event: InputEvent) -> void:
	if visible and event.is_action_pressed(&"ui_cancel"):
		close()
		get_viewport().set_input_as_handled()

func _rebuild_cards() -> void:
	for child in _grid.get_children():
		_grid.remove_child(child)
		child.queue_free()
	var ordered := _cards.duplicate()
	ordered.sort_custom(_less)
	var query := _search.text.strip_edges().to_lower()
	if _selected != null and not _matches_query(_selected, query):
		_selected = null
		_show_detail()
	for card in ordered:
		if not _matches_query(card, query): continue
		var selectable := _on_choose.is_valid() and _allowed.has(card.unique_id)
		var button := Button.new()
		button.name = "Card_" + card.unique_id
		button.custom_minimum_size = Vector2(72, 114)
		var card_state := _card_state(card, selectable)
		button.tooltip_text = card.short_label() + "\n" + card_state[0] + "\n" + "\n".join(card.gieo_property_descriptions())
		button.modulate.a = 1.0 if not _on_choose.is_valid() or selectable else 0.42
		button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		PresentationTheme.configure_button(button, "gold" if card == _selected else "tea" if selectable and _on_choose.is_valid() else "neutral")
		var face := TextureRect.new()
		face.name = "CardArt"
		face.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		face.offset_left = 5
		face.offset_top = 5
		face.offset_right = -5
		face.offset_bottom = -22
		face.texture = load(card.texture_path()) as Texture2D
		face.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		face.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		face.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		face.mouse_filter = Control.MOUSE_FILTER_IGNORE
		button.add_child(face)
		GieoCardFX.attach_texture(face, card)
		var state_tag := Label.new()
		state_tag.name = "CardState"
		state_tag.text = card_state[1]
		state_tag.position = Vector2(2, 94)
		state_tag.size = Vector2(68, 18)
		state_tag.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		state_tag.add_theme_font_size_override("font_size", 11)
		state_tag.add_theme_color_override("font_color", card_state[2])
		state_tag.add_theme_color_override("font_shadow_color", Color.BLACK)
		state_tag.add_theme_constant_override("shadow_offset_x", 1)
		state_tag.add_theme_constant_override("shadow_offset_y", 1)
		state_tag.mouse_filter = Control.MOUSE_FILTER_IGNORE
		button.add_child(state_tag)
		if _on_choose.is_valid() and not selectable:
			var excluded := Label.new()
			excluded.text = "×"
			excluded.position = Vector2(49, 0)
			excluded.size = Vector2(20, 24)
			excluded.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			excluded.add_theme_font_size_override("font_size", 18)
			excluded.mouse_filter = Control.MOUSE_FILTER_IGNORE
			button.add_child(excluded)
		button.pressed.connect(_inspect.bind(card))
		_grid.add_child(button)

func _matches_query(card: CardData, query: String) -> bool:
	return query.is_empty() or (card.short_label() + " " + card.unique_id + " " + card.rank + " " + card.suit).to_lower().contains(query)

func _less(a: CardData, b: CardData) -> bool:
	if _sort.selected == 2 and a.has_permanent_changes() != b.has_permanent_changes():
		return a.has_permanent_changes()
	var first_a := DeckManager.RANKS.find(a.rank) if _sort.selected == 1 else DeckManager.SUITS.find(a.suit)
	var first_b := DeckManager.RANKS.find(b.rank) if _sort.selected == 1 else DeckManager.SUITS.find(b.suit)
	if first_a != first_b: return first_a < first_b
	var second_a := DeckManager.SUITS.find(a.suit) if _sort.selected == 1 else DeckManager.RANKS.find(a.rank)
	var second_b := DeckManager.SUITS.find(b.suit) if _sort.selected == 1 else DeckManager.RANKS.find(b.rank)
	return second_a < second_b if second_a != second_b else a.unique_id < b.unique_id

func _inspect(card: CardData) -> void:
	_selected = card
	_rebuild_cards()
	_show_detail()

func _show_detail() -> void:
	for child in _detail.get_children():
		_detail.remove_child(child)
		child.queue_free()
	_confirm.visible = _on_choose.is_valid()
	_confirm.disabled = _selected == null or not _allowed.has(_selected.unique_id)
	if _selected == null:
		_add_detail(_words("Choose a card to inspect it.", "Chạm vào một lá để xem kỹ."), 18)
		return
	var art := TextureRect.new()
	art.custom_minimum_size = Vector2(190, 260)
	art.texture = load(_selected.texture_path()) as Texture2D
	art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_detail.add_child(art)
	GieoCardFX.attach_texture(art, _selected)
	_add_detail(_selected.short_label(), 23, PresentationTheme.RED if _selected.suit in ["Hearts", "Diamonds"] else PresentationTheme.INK)
	var state := _card_state(_selected, _allowed.has(_selected.unique_id))
	_add_detail(state[0], 16, state[2])
	var original := _selected.unique_id.split("_")
	var original_label := CardData.new("", original[1].to_upper(), 0, original[2].capitalize(), 0).short_label() if original.size() >= 3 else _selected.unique_id
	_add_detail(_words("Original card: ", "Lá gốc: ") + original_label, 14, PresentationTheme.MUTED)
	_add_detail(_words("Score value: ", "Giá trị điểm: ") + str(_selected.score_value()), 15, PresentationTheme.WALLET)
	var properties := _selected.gieo_property_descriptions()
	_add_detail("\n".join(properties) if not properties.is_empty() else _words("No Gieo Quẻ properties yet.", "Chưa có thuộc tính Gieo Quẻ."), 15, PresentationTheme.SPEAKER if not properties.is_empty() else PresentationTheme.MUTED)
	if _selected.transformation_locked: _add_detail(_words("Sealed · no further changes", "Đã khóa · không đổi tiếp"), 14, PresentationTheme.WARNING)
	if _on_choose.is_valid() and not _allowed.has(_selected.unique_id): _add_detail(_words("Unavailable for this choice", "Không thể chọn lần này"), 14, PresentationTheme.DANGER)

func _add_detail(value: String, font_size: int, color: Color = PresentationTheme.INK) -> void:
	var label := Label.new()
	label.text = value
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	_detail.add_child(label)

func _card_state(card: CardData, selectable: bool) -> Array:
	if _on_choose.is_valid() and not selectable:
		return [_words("Outside this offer", "Ngoài lựa chọn"), _words("NO", "KHÔNG"), PresentationTheme.DANGER]
	if card.transformation_locked:
		return [_words("Sealed transformation", "Đã khóa biến đổi"), _words("SEALED", "KHÓA"), PresentationTheme.WARNING]
	if card.has_permanent_changes():
		return [_words("Permanently changed", "Đã biến đổi vĩnh viễn"), _words("CHANGED", "ĐÃ ĐỔI"), PresentationTheme.SPEAKER]
	if _on_choose.is_valid():
		return [_words("Available to choose", "Có thể chọn"), _words("CHOOSE", "CHỌN"), PresentationTheme.TEA]
	return [_words("Original card", "Lá gốc"), _words("ORIGINAL", "LÁ GỐC"), PresentationTheme.MUTED]

func _choose() -> void:
	if _selected == null or not _allowed.has(_selected.unique_id) or not _on_choose.is_valid(): return
	var chosen := _selected.unique_id
	var callback := _on_choose
	close()
	callback.call(chosen)

func _words(en: String, vi: String) -> String:
	return vi if TranslationServer.get_locale().begins_with("vi") else en
