extends VBoxContainer
signal wallet_changed()
var runtime: RelicRuntime
var shop: RelicShop
var selected := ""
var _objects: HBoxContainer
var _detail: RichTextLabel
var _buy: Button
var _refresh_pending := false
var _tiles: Dictionary = {}

func configure(value: RelicRuntime, service: RelicShop) -> void:
	runtime = value
	shop = service
	add_theme_constant_override("separation", 12)
	shop.changed.connect(_queue_refresh)
	runtime.inventory_changed.connect(_queue_refresh)
	_refresh()

func _queue_refresh() -> void:
	if _refresh_pending:
		return
	_refresh_pending = true
	_refresh.call_deferred()

func _refresh() -> void:
	_refresh_pending = false
	for child in get_children():
		remove_child(child)
		child.queue_free()
	_tiles.clear()
	var heading := Label.new()
	heading.text = GameGlossary.words("HÀNG RONG · PICK SOMETHING UP", "HÀNG RONG · CẦM LÊN XEM NÀO")
	PresentationTheme.style_text(heading, &"speaker", 23)
	add_child(heading)
	_objects = HBoxContainer.new()
	_objects.add_theme_constant_override("separation", 22)
	add_child(_objects)
	for id in shop.offers:
		var tile := Button.new()
		tile.name = "Inspect_" + id
		tile.custom_minimum_size = Vector2(208, 174)
		tile.flat = true
		tile.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		_objects.add_child(tile)
		_tiles[id] = tile
		var icon := TextureRect.new()
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.texture = load(RelicCatalog.icon_path(id))
		icon.position = Vector2(44, 2)
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.size = Vector2(120, 112)
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		icon.pivot_offset = icon.size * 0.5
		icon.rotation = [-0.1, 0.08, -0.04][_tiles.size() - 1]
		tile.add_child(icon)
		var tag := RichTextLabel.new()
		tag.bbcode_enabled = true
		tag.scroll_active = false
		tag.position = Vector2(0, 118)
		tag.size = Vector2(208, 54)
		tag.text = "[center]" + str(RelicCatalog.DEFINITIONS[id].name) + "\n" + PresentationTheme.emphasis(VndWallet.format_vnd(-shop.price()), &"cost") + "[/center]"
		PresentationTheme.style_text(tag, &"body", 18)
		tag.add_theme_stylebox_override("normal", PresentationTheme.panel_style(PresentationTheme.PANEL))
		tag.mouse_filter = Control.MOUSE_FILTER_IGNORE
		tile.add_child(tag)
		tile.pressed.connect(func(): selected = id; _inspect())
		tile.mouse_entered.connect(func(): icon.create_tween().tween_property(icon, "scale", Vector2(1.12, 1.12), 0.14))
		tile.mouse_exited.connect(func(): icon.create_tween().tween_property(icon, "scale", Vector2.ONE, 0.14))
	_detail = RichTextLabel.new()
	_detail.bbcode_enabled = true
	_detail.fit_content = true
	_detail.scroll_active = false
	_detail.custom_minimum_size = Vector2(680, 68)
	_detail.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	PresentationTheme.style_text(_detail, &"body", 18)
	_detail.add_theme_stylebox_override("normal", PresentationTheme.panel_style(PresentationTheme.PANEL))
	add_child(_detail)
	var actions := HBoxContainer.new()
	add_child(actions)
	_buy = Button.new()
	_buy.name = "BuyRelic"
	_buy.custom_minimum_size = Vector2(240, 42)
	PresentationTheme.configure_button(_buy, "gold")
	_buy.pressed.connect(_purchase)
	actions.add_child(_buy)
	var reroll := Button.new()
	reroll.name = "RerollRelics"
	reroll.text = GameGlossary.words("REROLL · ", "ĐỔI HÀNG · ") + VndWallet.format_vnd(-shop.reroll_price())
	reroll.disabled = shop.purchased or shop.offers.is_empty() or shop.wallet.balance_vnd < shop.reroll_price()
	reroll.pressed.connect(func():
		if shop.reroll(): wallet_changed.emit()
	)
	actions.add_child(reroll)
	PresentationTheme.configure_button(reroll)
	var guide := Button.new()
	guide.text = GameGlossary.words("RELIC GUIDE", "SỔ DI VẬT")
	guide.pressed.connect(func(): GameGlossary.open(self, "relics"))
	actions.add_child(guide)
	PresentationTheme.configure_button(guide)
	var inventory := HFlowContainer.new()
	add_child(inventory)
	for id in runtime.inventory:
		var equip := Button.new()
		equip.name = "Equip_" + id
		var equipped := runtime.equipped.has(id)
		equip.text = ("✓ " if equipped else "+ ") + str(RelicCatalog.DEFINITIONS[id].name)
		equip.tooltip_text = RelicCatalog.effect(id)
		equip.disabled = not equipped and runtime.equipped.size() >= RelicRuntime.MAX_EQUIPPED
		equip.pressed.connect(func():
			if runtime.equipped.has(id): runtime.remove(id)
			else: runtime.equip(id)
		)
		inventory.add_child(equip)
	_inspect()

func _inspect() -> void:
	var valid := shop.offers.has(selected)
	_buy.disabled = not valid or shop.wallet.balance_vnd < shop.price()
	_buy.text = GameGlossary.words("BUY · ", "MUA · ") + VndWallet.format_vnd(-shop.price())
	_detail.text = (str(RelicCatalog.DEFINITIONS[selected].name) + " · " + RelicCatalog.effect(selected)) if valid else GameGlossary.words("Select an object to inspect it. One purchase per visit.", "Chọn một món để xem. Mỗi lần ghé mua một món.")
	if shop.purchased:
		_detail.text = GameGlossary.words("Purchased. The remaining offers have left; your collection stays with you.", "Đã mua. Các món còn lại rời đi; bộ sưu tập vẫn ở bên bạn.")
	_detail.text += "\n" + GameGlossary.words("EQUIPPED %d / 4 · ", "ĐANG DÙNG %d / 4 · ") % runtime.equipped.size() + (GameGlossary.words("Purchase equips automatically.", "Mua tự trang bị vào ô trống.") if runtime.equipped.size() < 4 else GameGlossary.words("Full: purchase goes to inventory. Remove a relic to equip it.", "Đầy: mua vào bộ sưu tập. Tháo một món để trang bị."))
	_detail.text = ActionVocabulary.colorize(_detail.text)
	for id: String in _tiles:
		_tiles[id].modulate = Color.WHITE if id == selected or not valid else Color(0.7, 0.7, 0.7)

func _purchase() -> void:
	if not shop.offers.has(selected):
		return
	var id := selected
	var origin: Vector2 = _tiles[id].global_position + Vector2(50, 10)
	if not shop.buy(id):
		return
	wallet_changed.emit()
	var layer := CanvasLayer.new()
	layer.layer = 246
	get_tree().root.add_child(layer)
	var icon := TextureRect.new()
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.texture = load(RelicCatalog.icon_path(id))
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.size = Vector2(110, 110)
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	icon.position = origin
	layer.add_child(icon)
	var tween := icon.create_tween().set_parallel(true)
	tween.tween_property(icon, "position", Vector2(1010, 108), 0.65).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(icon, "scale", Vector2(0.45, 0.45), 0.65)
	tween.chain().tween_callback(layer.queue_free)
