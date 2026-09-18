class_name RelicSelector
extends VBoxContainer

signal wallet_changed()

var runtime: RelicRuntime
var status: Label
var buttons: Dictionary = {}

func configure(value: RelicRuntime) -> void:
	runtime = value
	name = "RelicSelector"
	status = Label.new()
	status.add_theme_color_override("font_color", PresentationTheme.GOLD)
	add_child(status)
	var note := Label.new()
	note.text = tr("RELIC_SELECTOR_NOTE")
	note.add_theme_font_size_override("font_size", 13)
	add_child(note)
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size.y = 230
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	add_child(scroll)
	var list := VBoxContainer.new()
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(list)
	for id: String in RelicCatalog.DEFINITIONS:
		var row := HBoxContainer.new()
		list.add_child(row)
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
		button.custom_minimum_size.x = 70
		PresentationTheme.configure_button(button)
		row.add_child(button)
		buttons[id] = button
		button.pressed.connect(_toggle.bind(id))
	runtime.inventory_changed.connect(_refresh)
	_refresh()

func _toggle(id: String) -> void:
	if runtime.equipped.has(id):
		runtime.remove(id)
	else:
		if runtime.purchase_and_equip(id):
			wallet_changed.emit()

func _refresh() -> void:
	status.text = "HÀNG RONG  •  %d / 4" % runtime.equipped.size()
	for id: String in buttons:
		var button: Button = buttons[id]
		var equipped := runtime.equipped.has(id)
		button.text = tr("RELIC_REMOVE") if equipped else tr("RELIC_EQUIP")
		var price := runtime.price_for(id)
		if price > 0:
			button.text = VndWallet.format_vnd(price)
		button.disabled = not equipped and (runtime.equipped.size() >= RelicRuntime.MAX_EQUIPPED or (runtime.shop_wallet != null and runtime.shop_wallet.balance_vnd < price))
		button.tooltip_text = tr("RELIC_FULL") if button.disabled else RelicCatalog.effect(id)
