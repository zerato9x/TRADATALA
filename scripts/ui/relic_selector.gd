class_name RelicSelector
extends VBoxContainer
signal wallet_changed()
var runtime: RelicRuntime
var shop: RelicShop
var status: Label
var buttons: Dictionary = {}
var reroll_button: Button
var _list: VBoxContainer
var _refresh_pending := false

func words(en: String, vi: String) -> String:
	return vi if TranslationServer.get_locale().begins_with("vi") else en

func configure(value: RelicRuntime, p_shop: RelicShop = null) -> void:
	runtime = value
	shop = p_shop
	name = "RelicSelector"
	status = Label.new()
	status.add_theme_color_override("font_color", PresentationTheme.GOLD)
	add_child(status)
	var note := Label.new()
	note.text = words("Choose one. The other offers leave when you buy.\nReroll before buying; owned relics stay in your collection.", "Chọn một. Hai món còn lại rời đi khi mua.\nĐổi hàng trước khi mua; di vật đã mua vẫn thuộc về bạn.")
	note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	note.add_theme_font_size_override("font_size", 13)
	add_child(note)
	reroll_button = Button.new()
	PresentationTheme.configure_button(reroll_button)
	reroll_button.pressed.connect(_reroll)
	add_child(reroll_button)
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size.y = 170
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	add_child(scroll)
	_list = VBoxContainer.new()
	_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(_list)
	runtime.inventory_changed.connect(_queue_refresh)
	if shop != null:
		shop.changed.connect(_queue_refresh)
	_refresh()

func _queue_refresh() -> void:
	if _refresh_pending:
		return
	_refresh_pending = true
	_refresh.call_deferred()

func _refresh() -> void:
	_refresh_pending = false
	status.text = words("HÀNG RONG · EQUIPPED %d / 4", "HÀNG RONG · ĐANG DÙNG %d / 4") % runtime.equipped.size()
	for child in _list.get_children():
		_list.remove_child(child)
		child.queue_free()
	buttons.clear()
	reroll_button.visible = shop != null
	if shop != null:
		reroll_button.text = words("REROLL · ", "ĐỔI HÀNG · ") + VndWallet.format_vnd(shop.reroll_price())
		reroll_button.disabled = shop.purchased or shop.offers.is_empty() or shop.wallet.balance_vnd < shop.reroll_price()
		if shop.purchased or shop.offers.is_empty():
			var sold := Label.new()
			sold.text = words("Visit complete. New offers next visit.", "Đã hết lượt mua. Hẹn gặp lần sau.")
			_list.add_child(sold)
		for id in shop.offers:
			_add_item(id, false)
	if not runtime.inventory.is_empty():
		var title := Label.new()
		title.text = words("YOUR COLLECTION · FREE TO EQUIP", "BỘ SƯU TẬP · TRANG BỊ MIỄN PHÍ")
		title.add_theme_font_size_override("font_size", 13)
		_list.add_child(title)
		for id in runtime.inventory:
			_add_item(id, true)

func _add_item(id: String, owned: bool) -> void:
	var row := HBoxContainer.new()
	_list.add_child(row)
	var icon := TextureRect.new()
	icon.texture = load(RelicCatalog.icon_path(id))
	icon.custom_minimum_size = Vector2(46, 46)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	row.add_child(icon)
	var label := Label.new()
	label.text = String(RelicCatalog.DEFINITIONS[id].name) + "\n" + RelicCatalog.effect(id)
	label.add_theme_font_size_override("font_size", 13)
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	row.add_child(label)
	var button := Button.new()
	button.name = id
	button.custom_minimum_size.x = 110
	PresentationTheme.configure_button(button)
	row.add_child(button)
	buttons[id] = button
	var equipped := runtime.equipped.has(id)
	button.text = (tr("RELIC_REMOVE") if equipped else tr("RELIC_EQUIP")) if owned else VndWallet.format_vnd(shop.price())
	button.disabled = (not equipped and runtime.equipped.size() >= RelicRuntime.MAX_EQUIPPED) if owned else shop.wallet.balance_vnd < shop.price()
	button.pressed.connect(_toggle.bind(id))

func _toggle(id: String) -> void:
	if runtime.equipped.has(id):
		runtime.remove(id)
	elif runtime.inventory.has(id):
		runtime.equip(id)
	elif shop != null:
		shop.buy(id)
	wallet_changed.emit()

func _reroll() -> void:
	if shop != null and shop.reroll():
		wallet_changed.emit()
