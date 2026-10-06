class_name MiscNpcPanel
extends VBoxContainer

signal wallet_changed()
signal dialogue_requested(message: String)

var lottery: LotteryService

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

func _build_lottery() -> void:
	_clear()
	if not lottery.revealed_results().is_empty():
		_label(tr("LOTTO_RESULTS") % (lottery.day_index + 1), 23)
		for prize in MiscServiceConfig.PRIZES:
			var numbers: Array[String] = []
			for number in lottery.revealed_results()[prize.id]:
				numbers.append("%02d" % int(number))
			_label(tr(prize.label) + "  " + prize.multiplier + "   " + " · ".join(numbers), 20)
		_label(tr("LOTTO_PAID") % VndWallet.format_vnd(int(lottery.last_receipt.total_vnd)), 23)
		var review := Button.new()
		review.text = tr("LOTTO_PREVIOUS")
		add_child(review)
		review.pressed.connect(func(): LotteryReceipt.show_receipt(self, lottery.last_receipt))
		return
	var heading := HBoxContainer.new()
	heading.add_theme_constant_override("separation", 16)
	add_child(heading)
	var title := _label(tr("LOTTO_CHOOSE"), 23)
	title.reparent(heading)
	title.tooltip_text = tr("LOTTO_RULES")
	var quote := lottery.buy_all_quote()
	var all := Button.new()
	all.name = "BuyAll"
	all.tooltip_text = GameGlossary.words("Includes increasing daily prices: 1×, 2×, 3×… Each ticket uses the remaining wallet. Winnings use its paid stake.", "Đã tính giá tăng trong ngày: 1×, 2×, 3×… Mỗi vé dựa trên ví còn lại. Thưởng tính theo giá thực trả.")
	all.text = ("MUA TẤT CẢ" if TranslationServer.get_locale().begins_with("vi") else "BUY ALL") + " · %d · %s" % [quote.count, VndWallet.format_vnd(-int(quote.cost_vnd))]
	all.disabled = int(quote.count) == 0
	PresentationTheme.configure_button(all, "gold")
	add_child(all)
	all.pressed.connect(func():
		if lottery.buy_all().get("ok", false):
			_build_lottery()
			wallet_changed.emit()
	)
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
		number.add_theme_color_override("font_color", PresentationTheme.PAPER_INK if not ticket.purchased else PresentationTheme.PAPER_MUTED)
		number.mouse_filter = Control.MOUSE_FILTER_IGNORE
		ticket_face.add_child(number)
		var price := Label.new()
		price.text = tr("LOTTO_BOUGHT") if ticket.purchased else VndWallet.format_vnd(-int(ticket.stake_vnd))
		price.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		price.add_theme_font_size_override("font_size", 16)
		price.add_theme_color_override("font_color", PresentationTheme.PAPER_COST if not ticket.purchased else PresentationTheme.PAPER_MUTED)
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
