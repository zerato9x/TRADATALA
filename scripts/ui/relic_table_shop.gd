class_name RelicTableShop
extends Control
## Table objects send purchase/removal intent to the persistent shop authority.
signal wallet_changed()
signal dialogue_requested(line: String)
signal removal_pick_requested(cards: Array[CardData], reason: String, callback: Callable)

const STAGE := Vector2(740, 427)
var runtime: RelicRuntime
var shop: RelicShop
var selected := ""
var _tiles: Dictionary = {}
var _icons: Dictionary = {}
var _price_labels: Array[Label] = []
var _detail: RichTextLabel
var _buy: Button
var _refresh_pending := false

func configure(p_runtime: RelicRuntime, p_shop: RelicShop) -> void:
	runtime = p_runtime
	shop = p_shop
	custom_minimum_size = STAGE
	size = STAGE
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	shop.changed.connect(_queue_refresh)
	runtime.inventory_changed.connect(_queue_refresh)
	shop.wallet.balance_changed.connect(_on_wallet_changed)
	_refresh()

func _exit_tree() -> void:
	if shop != null and shop.changed.is_connected(_queue_refresh): shop.changed.disconnect(_queue_refresh)
	if runtime != null and runtime.inventory_changed.is_connected(_queue_refresh): runtime.inventory_changed.disconnect(_queue_refresh)
	if shop != null and shop.wallet != null and shop.wallet.balance_changed.is_connected(_on_wallet_changed): shop.wallet.balance_changed.disconnect(_on_wallet_changed)

func _on_wallet_changed(_before: int, _after: int, _delta: int, _reason: String) -> void:
	_queue_refresh()

func _queue_refresh() -> void:
	if _refresh_pending: return
	_refresh_pending = true
	call_deferred("_refresh")

func _refresh() -> void:
	_refresh_pending = false
	for child in get_children():
		remove_child(child)
		child.queue_free()
	_tiles.clear()
	_icons.clear()
	_price_labels.clear()
	_label_at(GameGlossary.words("RELICS", "BẢO VẬT"), Vector2.ZERO, Vector2(170, 22), 18, PresentationTheme.GOLD)
	_label_at(GameGlossary.words("VND/PTS bonuses · Always active", "Tăng VND/PTS · Luôn có hiệu lực"), Vector2(178, 0), Vector2(375, 22), 16, PresentationTheme.TEA)
	for index in shop.relic_stock.size():
		_build_relic(shop.relic_stock[index], index)
	if shop.relic_stock.is_empty():
		_label_at(GameGlossary.words("No relics left this visit.", "Chuyến này hết bảo vật rồi."), Vector2(0, 75), Vector2(552, 80), 20, PresentationTheme.MUTED)
	_label_at(GameGlossary.words("CARDS · ADD TO YOUR DECK", "BÀI · THÊM VÀO BỘ BÀI"), Vector2(0, 183), Vector2(552, 25), 18, PresentationTheme.GOLD)
	for index in shop.card_stock.size():
		_build_card(shop.card_stock[index], index)
	_build_removal()
	_detail = RichTextLabel.new()
	_detail.name = "ShopSelection"
	_detail.position = Vector2(0, 357)
	_detail.size = Vector2(740, 28)
	_detail.bbcode_enabled = true
	_detail.scroll_active = false
	_detail.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_detail.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	PresentationTheme.style_text(_detail, &"body", 17)
	add_child(_detail)
	_buy = Button.new()
	_buy.name = "ConfirmShopAction"
	_buy.position = Vector2(0, 389)
	_buy.size = Vector2(552, 38)
	PresentationTheme.configure_button(_buy, "gold")
	_buy.add_theme_font_size_override("font_size", 18)
	_buy.pressed.connect(_purchase)
	add_child(_buy)
	var guide := Button.new()
	guide.name = "ShopHandbook"
	guide.text = GameGlossary.words("Handbook", "Sổ tay")
	guide.position = Vector2(574, 389)
	guide.size = Vector2(150, 38)
	PresentationTheme.configure_button(guide)
	guide.add_theme_font_size_override("font_size", 17)
	guide.pressed.connect(func(): GameGlossary.open(self, "relics"))
	add_child(guide)
	if shop.removal_pending: selected = "remove"
	_inspect()

func _label_at(value: String, point: Vector2, dimensions: Vector2, pixels: int, color: Color, parent: Node = null) -> Label:
	var label := Label.new()
	label.text = value
	label.position = point
	label.size = dimensions
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	PresentationTheme.style_text(label, &"body", pixels)
	label.add_theme_color_override("font_color", color)
	(parent if parent != null else self).add_child(label)
	return label

func _tile(id: String, point: Vector2, dimensions: Vector2, tooltip: String) -> Button:
	var tile := Button.new()
	tile.name = "Inspect_" + id.validate_node_name()
	tile.position = point
	tile.size = dimensions
	tile.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	tile.tooltip_text = tooltip
	add_child(tile)
	_tiles[id] = tile
	tile.pressed.connect(_select_offer.bind(id))
	tile.mouse_entered.connect(_hover_object.bind(id, true))
	tile.mouse_exited.connect(_hover_object.bind(id, false))
	return tile

func _art(texture: Texture2D, point: Vector2, dimensions: Vector2, parent: Node, angle: float = 0.0) -> TextureRect:
	var art := TextureRect.new()
	art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	art.texture = texture
	art.position = point
	art.size = dimensions
	art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	art.pivot_offset = dimensions * 0.5
	art.rotation = angle
	art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(art)
	return art

func _tag(parent: Node, point: Vector2, value: String) -> void:
	var paper := PanelContainer.new()
	paper.name = "PriceTag"
	paper.position = point
	paper.size = Vector2(148, 28)
	paper.mouse_filter = Control.MOUSE_FILTER_IGNORE
	paper.add_theme_stylebox_override("panel", PresentationTheme.panel_style(Color("#f4e5bc"), Color("#aa8750"), 1, 2, 0))
	parent.add_child(paper)
	var label := Label.new()
	label.name = "Price"
	label.text = value
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.set_meta("text_surface", &"paper")
	PresentationTheme.style_text(label, &"body", 18)
	label.set_meta("text_role", &"cost")
	label.add_theme_color_override("font_color", PresentationTheme.PAPER_COST)
	paper.add_child(label)
	_price_labels.append(label)

func _build_relic(id: String, index: int) -> void:
	var tile := _tile(id, Vector2(index * 184, 24), Vector2(174, 155), RelicCatalog.display_name(id) + "\n" + RelicCatalog.effect(id))
	var texture: Texture2D = load(RelicCatalog.icon_path(id))
	var angle: float = [-0.07, 0.055, -0.03][index % 3]
	var shadow := _art(texture, Vector2(42, 5), Vector2(90, 63), tile, angle)
	shadow.modulate = Color(0, 0, 0, 0.4)
	var icon := _art(texture, Vector2(40, 0), Vector2(90, 63), tile, angle)
	icon.name = "RelicObject"
	icon.set_meta("rest_y", 0.0)
	_icons[id] = icon
	_label_at(RelicCatalog.display_name(id), Vector2(0, 63), Vector2(174, 23), 18, PresentationTheme.INK, tile).horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label_at(_offer_trigger(id), Vector2(0, 87), Vector2(174, 22), 16, PresentationTheme.TEA, tile).horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label_at(_offer_rate_text(id), Vector2(0, 108), Vector2(174, 22), 16, PresentationTheme.GOLD, tile).horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var sold := not shop.offers.has(id)
	_tag(tile, Vector2(13, 130), GameGlossary.words("SOLD", "ĐÃ BÁN") if sold else VndWallet.format_vnd(shop.price()))
	if sold: icon.modulate.a = 0.32

func _build_card(card: CardData, index: int) -> void:
	var id := card.unique_id
	var tile := _tile(id, Vector2(index * 184, 208), Vector2(174, 144), card.short_label() + "\n" + GameGlossary.words("One ordinary physical card added permanently. Duplicate ranks and suits are legal.", "Thêm vĩnh viễn một lá bài thật bình thường. Được trùng hạng và chất."))
	var icon := _art(load(card.texture_path()), Vector2(44, 0), Vector2(86, 119), tile, [-0.035, 0.025, -0.02][index % 3])
	icon.name = "CardObject"
	icon.set_meta("rest_y", 0.0)
	_icons[id] = icon
	var sold := shop.sold_cards.has(id)
	_tag(tile, Vector2(13, 116), GameGlossary.words("SOLD", "ĐÃ BÁN") if sold else VndWallet.format_vnd(shop.card_price()))
	if sold: icon.modulate.a = 0.28

func _build_removal() -> void:
	_label_at(GameGlossary.words("CARD REMOVAL", "BỎ MỘT LÁ BÀI"), Vector2(574, 0), Vector2(166, 22), 18, PresentationTheme.GOLD)
	var tile := _tile("remove", Vector2(574, 24), Vector2(150, 328), GameGlossary.words("Pay, choose an owned card, then confirm permanent removal. All its properties disappear with it.", "Trả tiền, chọn một lá đang sở hữu rồi xác nhận bỏ vĩnh viễn. Mọi thuộc tính mất cùng lá đó."))
	var target := shop.removal_target()
	if shop.removal_pending and target != null:
		var preview := PlayingCardView.new()
		preview.position = Vector2(32, 31)
		preview.drag_enabled = false
		tile.add_child(preview)
		preview.set_card(target)
		preview.mouse_filter = Control.MOUSE_FILTER_IGNORE
		preview.focus_mode = Control.FOCUS_NONE
		_label_at(target.short_label(), Vector2(0, 161), Vector2(150, 25), 18, PresentationTheme.INK, tile).horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_label_at(GameGlossary.words("ALL PROPERTIES\nLOST", "MẤT MỌI\nTHUỘC TÍNH"), Vector2(0, 197), Vector2(150, 50), 16, PresentationTheme.MONEY_COST, tile).autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	else:
		var paper := PanelContainer.new()
		paper.position = Vector2(7, 43)
		paper.size = Vector2(136, 140)
		paper.rotation = -0.055
		paper.mouse_filter = Control.MOUSE_FILTER_IGNORE
		paper.add_theme_stylebox_override("panel", PresentationTheme.panel_style(Color("#f4e5bc"), Color("#aa8750"), 2, 4, 8))
		tile.add_child(paper)
		var slip := Label.new()
		slip.text = GameGlossary.words("REMOVE\n1 CARD", "BỎ\n1 LÁ BÀI")
		slip.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		slip.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		slip.set_meta("text_surface", &"paper")
		PresentationTheme.style_text(slip, &"body", 24)
		slip.add_theme_color_override("font_color", Color("#36271b"))
		slip.mouse_filter = Control.MOUSE_FILTER_IGNORE
		paper.add_child(slip)
		_label_at(GameGlossary.words("PERMANENT", "VĨNH VIỄN"), Vector2(0, 199), Vector2(150, 26), 18, PresentationTheme.MONEY_COST, tile).horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_label_at(GameGlossary.words("Pay → Choose\n→ Confirm", "Trả → Chọn\n→ Xác nhận"), Vector2(0, 231), Vector2(150, 44), 16, PresentationTheme.INK, tile).horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_tag(tile, Vector2(1, 250 if target != null else 289), (GameGlossary.words("PAID", "ĐÃ TRẢ") if shop.removal_pending else VndWallet.format_vnd(shop.removal_price())))
	if shop.removal_pending and target != null:
		var choose := Button.new()
		choose.name = "ChooseAnotherRemoval"
		choose.text = GameGlossary.words("Change card", "Chọn lá khác")
		choose.position = Vector2(574, 323)
		choose.size = Vector2(150, 30)
		PresentationTheme.configure_button(choose)
		choose.pressed.connect(_open_removal_picker)
		add_child(choose)

func _hover_object(id: String, hovered: bool) -> void:
	var icon: TextureRect = _icons.get(id)
	if icon == null: return
	var previous: Tween = icon.get_meta("hover_tween") if icon.has_meta("hover_tween") else null
	if previous != null and previous.is_valid(): previous.kill()
	var tween := icon.create_tween().set_parallel(true)
	icon.set_meta("hover_tween", tween)
	tween.tween_property(icon, "scale", Vector2.ONE * (1.06 if hovered else 1.0), 0.14)
	tween.tween_property(icon, "position:y", float(icon.get_meta("rest_y")) - (3.0 if hovered else 0.0), 0.14)

func _offer_trigger(id: String) -> String:
	var definition: Dictionary = RelicCatalog.DEFINITIONS[id]
	if definition.get("escalating", false): return GameGlossary.words("SAME MELD · EXTEND", "CÙNG PHỎM · NỐI")
	if definition.event == "extension": return GameGlossary.words("EACH EXTENSION", "MỖI LẦN NỐI")
	if definition.get("type", "") == "set":
		return GameGlossary.words("NEW 4-CARD SET", "SET MỚI ĐÚNG 4 LÁ") if definition.get("exact", 0) == 4 else GameGlossary.words("NEW SET", "SET MỚI")
	if definition.get("type", "") == "run": return GameGlossary.words("NEW RUN", "RUN MỚI")
	if definition.get("exact", 0) == 3: return GameGlossary.words("NEW 3-CARD MELD", "PHỎM MỚI ĐÚNG 3")
	if definition.get("minimum", 0) == 4: return GameGlossary.words("NEW 4+ CARD MELD", "PHỎM MỚI TỪ 4 LÁ")
	if definition.has("suits"):
		return GameGlossary.words("NEW BLACK MELD", "PHỎM MỚI TOÀN ĐEN") if definition.suits.has("Spades") else GameGlossary.words("NEW RED MELD", "PHỎM MỚI TOÀN ĐỎ")
	return GameGlossary.words("NEW MELD", "PHỎM MỚI")

func _offer_rate_text(id: String) -> String:
	var definition: Dictionary = RelicCatalog.DEFINITIONS[id]
	var amount := int(definition.percent)
	if definition.get("per_card", false): return GameGlossary.words("+%d%% / CARD", "+%d%% / LÁ") % amount
	if definition.get("escalating", false): return GameGlossary.words("+%d%% × EXTEND #", "+%d%% × LẦN NỐI") % amount
	return "+%d%% VND/PTS" % amount

func _select_offer(id: String) -> void:
	if selected == id or not _tiles.has(id): return
	selected = id
	_inspect()
	if RelicCatalog.DEFINITIONS.has(id):
		dialogue_requested.emit(RelicCatalog.display_name(id) + ". " + RelicCatalog.effect(id) + " " + GameGlossary.words("Once bought, it's always active. You can buy the other items too.", "Mua xong là luôn có hiệu lực. Con vẫn mua các món khác được nhé."))
	elif id == "remove":
		dialogue_requested.emit(GameGlossary.words("Pay %s, choose one card from your deck, then confirm. The whole card and all its properties disappear permanently. Each completed removal raises the next price.", "Trả %s, chọn một lá trong bộ bài rồi xác nhận. Cả lá và mọi thuộc tính mất vĩnh viễn. Mỗi lần bỏ xong, lần tiếp theo đắt hơn.") % VndWallet.format_vnd(shop.removal_price()))
	else:
		var card := shop.card_offer(id)
		if card != null: dialogue_requested.emit(card.short_label() + ". " + GameGlossary.words("Buy this ordinary card for %s. It joins your deck permanently, with its own physical identity. Matching ranks and suits are allowed, so it can grow your Sets or fill your Runs.", "Mua lá bình thường này với giá %s. Lá vào bộ bài vĩnh viễn, là một lá thật riêng. Được trùng hạng và chất, giúp tăng Set hoặc ghép đủ Run.") % VndWallet.format_vnd(shop.card_price()))

func _inspect() -> void:
	var cost := shop.price() if RelicCatalog.DEFINITIONS.has(selected) else shop.card_price()
	var available := shop.offers.has(selected) if RelicCatalog.DEFINITIONS.has(selected) else (shop.card_offer(selected) != null and not shop.sold_cards.has(selected))
	_buy.disabled = true
	_buy.text = GameGlossary.words("SELECT AN OBJECT", "CHỌN MỘT MÓN")
	_detail.text = GameGlossary.words("Select an object. Auntie explains; BUY confirms.", "Chọn món để cô giải thích. Nhấn MUA để xác nhận.")
	if selected == "remove":
		cost = shop.removal_price()
		var target := shop.removal_target()
		if shop.removal_pending:
			_buy.disabled = false
			_buy.text = (GameGlossary.words("REMOVE %s PERMANENTLY", "BỎ VĨNH VIỄN %s") % target.short_label()) if target != null else GameGlossary.words("CHOOSE A CARD · ALREADY PAID", "CHỌN LÁ BÀI · ĐÃ TRẢ TIỀN")
			_detail.text = GameGlossary.words("All properties disappear with this exact card. No refund or transfer.", "Mọi thuộc tính mất cùng đúng lá này. Không hoàn tiền hay chuyển thuộc tính.") if target != null else GameGlossary.words("Paid %s · Choose one card, then confirm removal.", "Đã trả %s · Chọn một lá rồi xác nhận bỏ.") % VndWallet.format_vnd(shop.removal_paid_vnd)
		else:
			_buy.disabled = not shop.can_remove() or shop.wallet.balance_vnd < cost
			_buy.text = GameGlossary.words("PAY FOR REMOVAL · ", "TRẢ TIỀN BỎ BÀI · ") + VndWallet.format_vnd(cost)
			_detail.text = GameGlossary.words("Pay → Choose one owned card → Confirm permanent removal", "Trả tiền → Chọn một lá đang sở hữu → Xác nhận bỏ vĩnh viễn")
			if not shop.can_remove(): _detail.text = GameGlossary.words("Your deck needs at least %d cards for normal refills.", "Bộ bài cần ít nhất %d lá để bốc đủ trong ván.") % DealState.MIN_CAMPAIGN_CARDS
	elif not selected.is_empty() and _tiles.has(selected):
		var caption := RelicCatalog.display_name(selected) if RelicCatalog.DEFINITIONS.has(selected) else shop.card_offer(selected).short_label()
		_buy.text = GameGlossary.words("BUY ", "MUA ") + caption + " · " + VndWallet.format_vnd(cost)
		_buy.disabled = not available or shop.wallet.balance_vnd < cost
		_detail.text = caption + " · " + (GameGlossary.words("Always active after purchase", "Mua xong luôn có hiệu lực") if RelicCatalog.DEFINITIONS.has(selected) else GameGlossary.words("Adds 1 ordinary card permanently", "Thêm vĩnh viễn 1 lá bình thường"))
		if not available:
			_buy.text = GameGlossary.words("SOLD", "ĐÃ BÁN")
			_detail.text = caption + " · " + GameGlossary.words("Sold · Other items are still available", "Đã bán · Vẫn mua các món khác được")
	if not selected.is_empty() and (available or selected == "remove" and shop.can_remove()) and not shop.removal_pending and shop.wallet.balance_vnd < cost:
		_detail.text = PresentationTheme.emphasis(GameGlossary.words("Need %s more", "Cần thêm %s") % VndWallet.format_vnd(cost - shop.wallet.balance_vnd), &"cost")
	for id: String in _tiles:
		var tile: Button = _tiles[id]
		tile.add_theme_stylebox_override("normal", _object_style(id == selected, false))
		tile.add_theme_stylebox_override("hover", _object_style(id == selected, true))
		tile.add_theme_stylebox_override("pressed", _object_style(true, true))
		tile.add_theme_stylebox_override("focus", _object_style(false, true))

func _object_style(active: bool, hovered: bool) -> StyleBox:
	if not active and not hovered: return StyleBoxEmpty.new()
	return PresentationTheme.panel_style(Color(1, 0.85, 0.35, 0.045), PresentationTheme.GOLD if active else Color(1, 0.9, 0.5, 0.45), 2 if active else 1, 8, 0)

func _purchase() -> void:
	if selected == "remove":
		if not shop.removal_pending:
			if not shop.pay_removal(): return
			wallet_changed.emit()
			_open_removal_picker()
		elif shop.removal_target() == null:
			_open_removal_picker()
		else:
			var target := shop.removal_target()
			if shop.confirm_removal():
				dialogue_requested.emit(target.short_label() + ". " + GameGlossary.words("Removed from your deck, with all its properties. Next removal: %s.", "Đã bỏ khỏi bộ bài, cùng mọi thuộc tính. Lần bỏ tiếp theo: %s.") % VndWallet.format_vnd(shop.removal_price()))
			else:
				dialogue_requested.emit(GameGlossary.words("That card changed or is unavailable. Choose your card again; your payment is still valid.", "Lá đó đã đổi hoặc không còn. Chọn lại nhé; tiền đã trả vẫn có hiệu lực."))
				_open_removal_picker()
		return
	if RelicCatalog.DEFINITIONS.has(selected):
		var id := selected
		if not shop.buy(id): return
		wallet_changed.emit()
		dialogue_requested.emit(RelicCatalog.display_name(id) + ". " + GameGlossary.words("Sold! It's active for the rest of your run. The other goods stay on the table.", "Mua xong! Có hiệu lực suốt lượt chơi. Các món còn lại vẫn trên bàn nhé."))
	else:
		var acquired := shop.buy_card(selected)
		if acquired == null: return
		wallet_changed.emit()
		dialogue_requested.emit(acquired.short_label() + ". " + GameGlossary.words("Added to your deck. Auntie leaves the other goods on the table.", "Đã thêm vào bộ bài. Các món khác vẫn trên bàn nhé."))

func _open_removal_picker() -> void:
	if not shop.removal_pending: return
	removal_pick_requested.emit(shop.owned_cards(), GameGlossary.words("Choose the whole physical card to remove. All its properties will disappear. Final confirmation follows.", "Chọn đúng lá bài thật cần bỏ. Mọi thuộc tính của lá sẽ mất. Sau đó còn bước xác nhận."), _chosen_removal)

func _chosen_removal(card_id: String) -> void:
	if not shop.choose_removal(card_id): return
	var card := shop.removal_target()
	dialogue_requested.emit(card.short_label() + ". " + GameGlossary.words("This exact card and all its properties will disappear. Press REMOVE PERMANENTLY to confirm, or choose another card.", "Đúng lá này cùng mọi thuộc tính sẽ mất. Nhấn BỎ VĨNH VIỄN để xác nhận, hoặc chọn lá khác."))
