class_name PileArchive
extends Node
## Renders the physical draw/discard piles and returns discard selection intent.
signal discard_selected(record: DiscardRecord)
const CARD_ACTION_OUTLINE_SCRIPT := preload("res://scripts/ui/card_action_outline.gd")
const CARD_SYMBOL_ART_SCRIPT := preload("res://scripts/ui/card_symbol_art.gd")
var _active := false
var _deal_ref: WeakRef
var deal: DealState:
	get: return _deal_ref.get_ref() as DealState
var interactions: MatchInteraction
var overlay: Control
var title_label: Label
var count_label: Label
var close_button: Button
var grids: Dictionary = {}
var suit_titles: Dictionary = {}
var mode := "discard"
var _opening: Tween

func configure(owner_deal: DealState, owner_interactions: MatchInteraction, surface: Control) -> void:
	_active = true
	_deal_ref = weakref(owner_deal)
	interactions = owner_interactions
	overlay = surface
	title_label = overlay.find_child("ArchiveTitle", true, false)
	count_label = overlay.find_child("ArchiveCount", true, false)
	close_button = overlay.find_child("CloseArchive", true, false)
	for suit in DeckManager.SUITS:
		grids[suit] = overlay.find_child(suit + "Cards", true, false)
		suit_titles[suit] = overlay.find_child(suit + "DiscardArchiveSuitTitles", true, false)
	close_button.pressed.connect(close)
	(overlay.find_child("ArchiveDim", true, false) as Control).gui_input.connect(_on_discard_archive_dim_input)

func open() -> void:
	if not _active: return
	sync()
	if _opening != null and _opening.is_valid(): _opening.kill()
	overlay.visible = true
	overlay.modulate = Color(1, 1, 1, 0)
	var panel := overlay.get_node("ArchivePanel") as Panel
	panel.scale = Vector2(0.97, 0.97)
	panel.pivot_offset = panel.size * 0.5
	_opening = create_tween().set_parallel(true)
	_opening.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_opening.tween_property(overlay, "modulate", Color.WHITE, 0.14)
	_opening.tween_property(panel, "scale", Vector2.ONE, 0.18)
	close_button.grab_focus()

func refresh_localized_ui() -> void:
	if not _active: return
	close_button.text = tr("ARCHIVE_CLOSE")
	for suit in DeckManager.SUITS:
		var title_control := suit_titles.get(suit) as Control
		if title_control == null: continue
		var title := title_control.get_node_or_null("Title") as Label
		if title != null: title.text = _discard_suit_title(suit)
		var symbol := title_control.get_node_or_null("Icon") as TextureRect
		if symbol != null: CARD_SYMBOL_ART_SCRIPT.tint_icon(symbol, _discard_suit_color(suit))

func record_at(point: Vector2) -> DiscardRecord:
	if not _active or not overlay.visible or mode != "discard" or not deal.current_drink_has_charge(): return null
	for grid: GridContainer in grids.values():
		for holder: Control in grid.get_children():
			if holder.has_meta("drink_record") and InputHitTest.contains(holder, point):
				return holder.get_meta("drink_record") as DiscardRecord
	return null

func _exit_tree() -> void:
	_active = false
	close_button.pressed.disconnect(close)
	(overlay.find_child("ArchiveDim", true, false) as Control).gui_input.disconnect(_on_discard_archive_dim_input)
	overlay.hide()
	if _opening != null and _opening.is_valid(): _opening.kill()

func sync() -> void:
	if not _active: return
	var source_cards: Array[CardData] = deal.deck.draw_pile if mode == "draw" else deal.deck.discard_pile
	var drink_records: Array = []
	if mode == "discard" and deal.current_drink_id in [DrinkCatalog.NHAN_TRAN, DrinkCatalog.DEN_DA]:
		drink_records = deal.drink_mandatory_discard_targets()
		if interactions.drink_targeting:
			source_cards = []
			for record: DiscardRecord in drink_records:
				source_cards.append(record.card)
	title_label.text = tr("ARCHIVE_DRAW_TITLE") if mode == "draw" else tr("ARCHIVE_DISCARD_TITLE")
	if not drink_records.is_empty():
		title_label.text = tr("DRINK_PICK_DISCARD")
	count_label.text = tr("ARCHIVE_COUNT") % source_cards.size()
	var cards_by_suit := {}
	for suit in DeckManager.SUITS:
		cards_by_suit[suit] = [] as Array[CardData]
	for card in source_cards:
		if cards_by_suit.has(card.suit):
			cards_by_suit[card.suit].append(card)
	for suit in DeckManager.SUITS:
		var grid: GridContainer = grids[suit]
		for child in grid.get_children():
			grid.remove_child(child)
			child.queue_free()
		var suit_cards: Array[CardData] = cards_by_suit[suit]
		suit_cards.sort_custom(_discard_card_less)
		if suit_cards.is_empty():
			var empty := Label.new()
			empty.custom_minimum_size = Vector2(172, 52)
			empty.text = tr("ARCHIVE_DRAW_EMPTY") if mode == "draw" else tr("ARCHIVE_DISCARD_EMPTY")
			empty.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			empty.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			empty.add_theme_font_size_override("font_size", 10)
			empty.add_theme_color_override("font_color", PresentationTheme.MUTED)
			grid.add_child(empty)
			continue
		for card in suit_cards:
			var holder := _build_discard_archive_card(card)
			grid.add_child(holder)
			for record: DiscardRecord in drink_records:
				if record.card == card:
					holder.set_meta("drink_record", record)
					holder.mouse_filter = Control.MOUSE_FILTER_STOP
					holder.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
					holder.gui_input.connect(_on_drink_archive_card_input.bind(record))
					var outline := CARD_ACTION_OUTLINE_SCRIPT.new()
					outline.position = Vector2(-4, -4)
					outline.size = holder.custom_minimum_size + Vector2(8, 8)
					holder.add_child(outline)
					var useful := interactions.drink_swap_opportunities().any(func(op): return op.record == record)
					outline.set_cues(false, false, useful, useful)
					break


func _on_drink_archive_card_input(event: InputEvent, record: DiscardRecord) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		get_viewport().set_input_as_handled()
		close()
		discard_selected.emit(record)


func _build_discard_archive_card(card: CardData) -> Control:
	var holder := Control.new()
	holder.custom_minimum_size = Vector2(54, 75)
	holder.tooltip_text = card.inspection_text()
	var gieo_descriptions := card.fortune_descriptions()
	if not gieo_descriptions.is_empty():
		holder.tooltip_text += "\n\nGIEO QUẺ\n" + "\n".join(gieo_descriptions)
	var texture := TextureRect.new()
	texture.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	texture.texture = load(card.texture_path()) as Texture2D
	GieoCardFX.attach_texture(texture, card)
	texture.add_child(preload("res://scripts/ui/passive_card_sway.gd").new())
	texture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	texture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	texture.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	texture.mouse_filter = Control.MOUSE_FILTER_IGNORE
	holder.add_child(texture)
	return holder


func _discard_card_less(left: CardData, right: CardData) -> bool:
	if left.rank_index != right.rank_index:
		return left.rank_index < right.rank_index
	return left.unique_id < right.unique_id


func _discard_suit_title(suit: String) -> String:
	match suit:
		"Spades": return tr("SUIT_SPADES")
		"Hearts": return tr("SUIT_HEARTS")
		"Diamonds": return tr("SUIT_DIAMONDS")
		_: return tr("SUIT_CLUBS")


func _discard_suit_color(suit: String) -> Color:
	return PresentationTheme.RED if suit in ["Hearts", "Diamonds"] else PresentationTheme.INK


func close() -> void:
	if not _active: return
	if _opening != null and _opening.is_valid(): _opening.kill()
	overlay.visible = false
	close_button.release_focus()


func _on_discard_archive_dim_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		close()
