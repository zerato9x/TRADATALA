extends Control
signal expanded_changed()
## The opponent's visible table. Every face and receipt comes from DealState.
var host: Control
var kind := ""
var terms: Label
var receipt: Label
var collection: HBoxContainer
var scroll: ScrollContainer
var drawer: PanelContainer
var drawer_title: Label
var faces: Dictionary = {}
var _content_key := ""
var _state: Dictionary = {}
var _accent := Color.WHITE
var _pulse := 0.0
var _paused := false
var expanded := false
var expand_button: Button
var _full_receipt := ""
var _last_loss := 0
var _compact_receipt := ""

func set_expanded(value: bool) -> void:
	expanded = value and kind == "rat"
	_layout()
	expanded_changed.emit()

func configure(owner: Control) -> void:
	host = owner
	name = "OpponentTable"
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	expand_button = Button.new()
	expand_button.name = "ExpandRatMelds"
	expand_button.custom_minimum_size = Vector2(80, 20)
	PresentationTheme.configure_button(expand_button)
	expand_button.add_theme_font_size_override("font_size", 11)
	expand_button.pressed.connect(func(): set_expanded(not expanded))
	terms = _label(12)
	terms.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	add_child(terms)
	receipt = _label(12)
	receipt.name = "CommittedBossReceipt"
	receipt.autowrap_mode = TextServer.AUTOWRAP_OFF
	add_child(receipt)
	drawer = PanelContainer.new()
	drawer.name = "RatMeldDrawer"
	drawer.mouse_filter = Control.MOUSE_FILTER_PASS
	add_child(drawer)
	var drawer_body := VBoxContainer.new()
	drawer_body.add_theme_constant_override("separation", 3)
	drawer.add_child(drawer_body)
	drawer_title = _label(12)
	drawer_body.add_child(drawer_title)
	scroll = ScrollContainer.new()
	scroll.name = "VisibleBossMelds"
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.mouse_filter = Control.MOUSE_FILTER_STOP
	scroll.follow_focus = true
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	drawer_body.add_child(scroll)
	collection = HBoxContainer.new()
	collection.add_theme_constant_override("separation", 14)
	collection.mouse_filter = Control.MOUSE_FILTER_PASS
	scroll.add_child(collection)
	resized.connect(_layout)
	hide()

func _label(pixels: int) -> Label:
	var label := Label.new()
	label.add_theme_font_size_override("font_size", pixels)
	label.add_theme_color_override("font_color", PresentationTheme.INK)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return label

func sync(state: Dictionary) -> void:
	var next_kind: String = state.get("id", "")
	if kind != next_kind: expanded = false
	kind = next_kind
	expand_button.visible = kind == "rat"
	visible = kind in ["rat", "tiger"]
	receipt.visible = visible
	if not visible:
		drawer.hide()
		_content_key = ""
		_pulse = 0
		return
	_state = state.duplicate(true)
	_accent = PresentationTheme.zodiac_color(kind)
	var style := preload("res://scripts/ui/table_hud_presentation.gd").glass(_accent, 0.9)
	style.content_margin_left = 10
	style.content_margin_right = 10
	style.content_margin_top = 8
	style.content_margin_bottom = 8
	drawer.add_theme_stylebox_override("panel", style)
	var last: Dictionary = state.get("hostile_result", {})
	_last_loss = absi(int(last.get("amount_vnd", 0)))
	if kind == "rat":
		terms.text = ZodiacCatalog.words("Discard → borrows up to %d cards", "Bỏ bài → mượn tối đa %d lá") % int(ZodiacCatalog.tuning("rat", "borrow_limit", state.difficulty))
		terms.text += "\n" + (ZodiacCatalog.words("This + previous Phase", "Hiệp này + Hiệp trước") if int(state.difficulty) == ZodiacCatalog.UNPLEASED else ZodiacCatalog.words("This Phase", "Hiệp này")) + " · " + ZodiacCatalog.words("Exhaustion: no bonus", "Cạn bài: không thưởng")
		var action: String = last.get("action", "")
		if action in ["boss_meld", "boss_extension"]:
			receipt.text = (ZodiacCatalog.words("YOUR MELD #%d", "PHỎM CỦA BẠN #%d") if action == "boss_extension" else ZodiacCatalog.words("RAT MELD #%d", "PHỎM CỦA TÝ #%d")) % int(last.meld_id)
			receipt.text += "  ·  −" + VndWallet.format_vnd(absi(int(last.amount_vnd)))
		elif action == "mouse_borrow_returned":
			receipt.text = ZodiacCatalog.words("No play · no deduction", "Không hạ được · không trừ tiền")
		else: receipt.text = ZodiacCatalog.words("Its payout comes out of your wallet", "Tiền thưởng của Tý trừ vào ví bạn")
		if last.has("returned_count"):
			receipt.text += "\n" + ZodiacCatalog.words("%d borrowed · %d returned", "Mượn %d · trả %d") % [int(last.borrowed_count), int(last.returned_count)]
	else:
		terms.text = ZodiacCatalog.words("Turn start → ", "Đầu lượt → ")
		terms.text += ZodiacCatalog.words("one highest card", "một lá cao nhất") if int(state.difficulty) == ZodiacCatalog.PLEASED else ZodiacCatalog.words("all highest-rank copies", "mọi lá cùng hạng cao nhất") if int(state.difficulty) == ZodiacCatalog.NORMAL else ZodiacCatalog.words("most valuable rank", "hạng có lợi nhất")
		terms.text += "\n" + ZodiacCatalog.words("Exhaustion: no bonus", "Cạn bài: không thưởng")
		receipt.text = ZodiacCatalog.words("%d snatched → discard pile · Your turn", "Vồ %d lá → chồng bỏ · Đến lượt bạn") % state.get("removed_ids", []).size()
	_full_receipt = receipt.text
	receipt.tooltip_text = _full_receipt
	terms.hide()
	_compact_receipt = ("−" + VndWallet.format_vnd(_last_loss) if _last_loss > 0 else "—") if kind == "rat" else ZodiacCatalog.words("Snatched %d · Your turn", "Vồ %d lá · Đến lượt bạn") % state.get("removed_ids", []).size()
	receipt.text = _compact_receipt
	expand_button.text = ZodiacCatalog.words("MELDS %d", "PHỎM %d") % host.deal.boss_melds.size()
	receipt.add_theme_color_override("font_color", _accent)
	var key := kind + TranslationServer.get_locale() + JSON.stringify(state.get("removed_ids", []))
	for meld: MeldState in host.deal.boss_melds:
		key += ":%d:" % meld.meld_id
		for card in meld.cards: key += card.unique_id + card.texture_path()
	if key != _content_key:
		_content_key = key
		_rebuild()
	_layout()

func _rebuild() -> void:
	faces.clear()
	for child in collection.get_children():
		collection.remove_child(child)
		child.queue_free()
	if kind == "rat":
		for meld: MeldState in host.deal.boss_melds:
			_add_group(ZodiacCatalog.words("RAT #%d", "PHỎM TÝ #%d") % meld.meld_id, meld.cards)
	if kind == "rat" and collection.get_child_count() == 0:
		var empty := _label(14)
		empty.name = "NoOwnedMelds"
		empty.text = ZodiacCatalog.words("No Rat melds yet", "Tý chưa có Phỏm")
		empty.add_theme_color_override("font_color", PresentationTheme.MUTED)
		empty.custom_minimum_size.y = 56
		collection.add_child(empty)

func _add_group(caption: String, cards: Array[CardData]) -> void:
	var group := VBoxContainer.new()
	group.add_theme_constant_override("separation", 1)
	collection.add_child(group)
	var label := Button.new()
	label.add_theme_font_size_override("font_size", 10)
	for state_name in ["normal", "hover", "pressed", "focus"]: label.add_theme_stylebox_override(state_name, StyleBoxEmpty.new())
	label.text = caption
	label.add_theme_color_override("font_color", _accent)
	label.tooltip_text = ZodiacCatalog.words("Select this table Meld to extend", "Chọn Phỏm trên bàn để nối")
	var meld_id := int(caption.get_slice("#", 1))
	label.pressed.connect(func():
		host.select_meld(meld_id)
		var table_view := host.card_table.meld_views.get(meld_id) as Control
		if table_view != null: host.meld_scroll.ensure_control_visible(table_view))
	group.add_child(label)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 3)
	group.add_child(row)
	for card in cards:
		var face := TextureRect.new()
		face.name = "Owned_" + card.unique_id.validate_node_name()
		face.texture = load(card.texture_path())
		face.custom_minimum_size = Vector2(32, 45)
		face.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		face.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		face.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		face.mouse_filter = Control.MOUSE_FILTER_PASS
		face.tooltip_text = card.short_label()
		row.add_child(face)
		faces[card.unique_id] = face
		var ink := ColorRect.new()
		ink.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		ink.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var material := ShaderMaterial.new()
		material.shader = preload("res://shaders/rat_stolen_meld.gdshader") if kind == "rat" else preload("res://shaders/tiger_claws.gdshader")
		ink.material = material
		face.add_child(ink)

func _layout() -> void:
	if terms == null: return
	custom_minimum_size = Vector2.ZERO
	receipt.text = _compact_receipt
	drawer.visible = kind == "rat" and expanded
	scroll.visible = drawer.visible
	if kind == "rat":
		expand_button.text = (ZodiacCatalog.words("HIDE MELDS", "THU PHỎM") if expanded else ZodiacCatalog.words("MELDS %d", "PHỎM %d") % host.deal.boss_melds.size()) + (" ▴" if expanded else " ▾")
		drawer_title.text = ZodiacCatalog.words("RAT'S MELDS · %d", "PHỎM CỦA TÝ · %d") % host.deal.boss_melds.size()

func fit_drawer(rect: Rect2) -> void:
	if drawer == null: return
	drawer.position = rect.position - global_position
	drawer.size = rect.size

func card_target(id: String) -> Vector2:
	if not expanded: return expand_button.get_global_rect().get_center()
	var face := faces.get(id) as Control
	if face != null and scroll.get_global_rect().encloses(face.get_global_rect()): return face.get_global_rect().get_center()
	return scroll.get_global_rect().get_center()

func reveal_cards(ids: Array) -> void:
	if ids.is_empty(): return
	var face := faces.get(ids[-1]) as Control
	if face != null:
		# Focus the actual destination, including collections wider than the viewport.
		scroll.ensure_control_visible(face)
	_pulse = 1.0

func pause_effects(value: bool) -> void:
	_paused = value

func _process(delta: float) -> void:
	if not is_visible_in_tree() or _paused: return
	if kind == "tiger":
		if host.card_table.hand_staged:
			receipt.text = ZodiacCatalog.words("Tiger swipes %d", "Dần vồ %d lá") % _state.get("removed_ids", []).size() if host.zodiac_boss_hud.hunt_fx._swipe_started else ZodiacCatalog.words("FULL HAND", "ĐỦ BÀI")
		else: receipt.text = _compact_receipt
	_pulse = move_toward(_pulse, 0, delta * 1.4)
	expand_button.modulate = Color.WHITE.lerp(_accent, _pulse * 0.65)
