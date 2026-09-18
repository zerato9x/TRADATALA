class_name MiscNpcPanel
extends VBoxContainer

signal wallet_changed()
signal dialogue_requested(message: String)

var shoe: ShoeShineService
var lottery: LotteryService
var _polish_button: Button
var _count: Label

func configure_shoe(service: ShoeShineService) -> void:
	name = "ShoeShinePanel"
	shoe = service
	add_theme_constant_override("separation", 10)
	_build_shoe()
	call_deferred("_speak_hint")

func configure_lottery(service: LotteryService) -> void:
	name = "LotteryPanel"
	lottery = service
	add_theme_constant_override("separation", 12)
	_build_lottery()

func _clear() -> void:
	for child in get_children():
		remove_child(child)
		child.queue_free()

func _label(text: String, font_size: int = 16) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", PresentationTheme.INK)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	add_child(label)
	return label

func _build_shoe() -> void:
	_clear()
	_label(tr("SHOE_CHOOSE"), 21)
	_label(tr("CARD_SHINY_DESC"), 15)
	var display := HBoxContainer.new()
	display.name = "PolishedCards"
	display.alignment = BoxContainer.ALIGNMENT_CENTER
	display.custom_minimum_size.y = 180
	display.add_theme_constant_override("separation", 24)
	add_child(display)
	for index in 2:
		var holder := PanelContainer.new()
		holder.custom_minimum_size = Vector2(112, 156)
		holder.add_theme_stylebox_override("panel", PresentationTheme.panel_style(Color("#182839"), PresentationTheme.MUTED, 1, 2, 0))
		display.add_child(holder)
		if shoe.last_polished_ids.size() == 2:
			for card in shoe.cards():
				if card.unique_id != shoe.last_polished_ids[index]:
					continue
				var face := TextureRect.new()
				face.name = "Face"
				face.texture = load(card.texture_path())
				face.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
				face.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
				face.mouse_filter = Control.MOUSE_FILTER_IGNORE
				holder.add_child(face)
				GieoCardFX.attach_texture(face, card)
		else:
			var mark := Label.new()
			mark.text = "?"
			mark.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			mark.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			mark.add_theme_font_size_override("font_size", 42)
			holder.add_child(mark)
	_count = _label(tr("SHOE_RANDOM_READY") if shoe.last_polished_ids.is_empty() else tr("SHOE_RANDOM_DONE"), 16)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 14)
	add_child(row)
	_polish_button = Button.new()
	_polish_button.name = "PolishConfirm"
	_polish_button.text = tr("SHOE_POLISH") % VndWallet.format_vnd(shoe.polish_cost())
	_polish_button.custom_minimum_size = Vector2(300, 44)
	row.add_child(_polish_button)
	_polish_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	PresentationTheme.configure_button(_polish_button, "gold")
	_polish_button.pressed.connect(_polish)
	var tip := Button.new()
	tip.name = "Tip"
	tip.text = tr("SHOE_TIP") % VndWallet.format_vnd(shoe.tip_cost())
	tip.custom_minimum_size = Vector2(260, 44)
	tip.disabled = not shoe.can_tip()
	row.add_child(tip)
	tip.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	PresentationTheme.configure_button(tip)
	tip.pressed.connect(_tip)
	_polish_button.disabled = not shoe.can_polish()

func _polish() -> void:
	if not shoe.polish().get("ok", false):
		return
	_build_shoe()
	wallet_changed.emit()
	dialogue_requested.emit(tr("SHOE_DONE"))
func _tip() -> void:
	if not shoe.tip().get("ok", false):
		return
	_build_shoe()
	wallet_changed.emit()
	if not _speak_hint():
		dialogue_requested.emit(tr("SHOE_THANKS"))

func _speak_hint() -> bool:
	if shoe == null:
		return false
	var hint := shoe.special_hint()
	if hint.is_empty():
		return false
	dialogue_requested.emit(tr("SHOE_HINT") % int(hint.number))
	return true

func _build_lottery() -> void:
	_clear()
	var heading := HBoxContainer.new()
	heading.add_theme_constant_override("separation", 16)
	add_child(heading)
	var title := _label(tr("LOTTO_CHOOSE"), 23)
	title.reparent(heading)
	_label(tr("LOTTO_RULES"), 15)
	var grid := GridContainer.new()
	grid.columns = 4
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid.add_theme_constant_override("h_separation", 12)
	grid.add_theme_constant_override("v_separation", 12)
	add_child(grid)
	for ticket: Dictionary in lottery.offered_tickets():
		var button := Button.new()
		button.name = "Ticket_" + String(ticket.id).replace(":", "_")
		button.text = ""
		button.custom_minimum_size = Vector2(142, 105)
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.add_theme_font_size_override("font_size", 27)
		button.add_theme_color_override("font_color", Color("#342315"))
		button.add_theme_color_override("font_hover_color", Color("#342315"))
		button.add_theme_stylebox_override("normal", PresentationTheme.panel_style(Color("#f0dfb6"), Color("#aa643a"), 2, 2, 8))
		button.add_theme_stylebox_override("hover", PresentationTheme.panel_style(Color("#fff3cf"), PresentationTheme.GOLD, 3, 2, 8))
		button.disabled = ticket.purchased or lottery.wallet.balance_vnd < int(ticket.stake_vnd)
		grid.add_child(button)
		var ticket_face := VBoxContainer.new()
		ticket_face.mouse_filter = Control.MOUSE_FILTER_IGNORE
		button.add_child(ticket_face)
		ticket_face.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		ticket_face.offset_top = 6
		var number := Label.new()
		number.text = "%02d" % int(ticket.number)
		number.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		number.add_theme_font_size_override("font_size", 38)
		number.add_theme_color_override("font_color", Color("#342315") if not ticket.purchased else PresentationTheme.MUTED)
		number.mouse_filter = Control.MOUSE_FILTER_IGNORE
		ticket_face.add_child(number)
		var price := Label.new()
		price.text = tr("LOTTO_BOUGHT") if ticket.purchased else VndWallet.format_vnd(int(ticket.stake_vnd))
		price.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		price.add_theme_font_size_override("font_size", 16)
		price.add_theme_color_override("font_color", Color("#704326") if not ticket.purchased else PresentationTheme.MUTED)
		price.mouse_filter = Control.MOUSE_FILTER_IGNORE
		ticket_face.add_child(price)
		button.pressed.connect(_buy.bind(String(ticket.id)))
	var owned: Array[String] = []
	for ticket in lottery.purchased_tickets():
		owned.append("%02d" % int(ticket.number))
	_label(tr("LOTTO_OWNED") % (" · ".join(owned) if not owned.is_empty() else "—"), 16)
	_label(tr("LOTTO_HIERARCHY"), 15)
	if not lottery.last_receipt.is_empty():
		var previous := Button.new()
		previous.name = "PreviousResults"
		previous.text = tr("LOTTO_PREVIOUS")
		heading.add_child(previous)
		PresentationTheme.configure_button(previous)
		previous.pressed.connect(func() -> void: LotteryReceipt.show_receipt(self, lottery.last_receipt))

func _buy(id: String) -> void:
	var result := lottery.purchase(id)
	if not result.get("ok", false):
		return
	_build_lottery()
	wallet_changed.emit()
	dialogue_requested.emit(tr("LOTTO_PURCHASED") % int(result.ticket.number))
