class_name LotteryReceipt
extends CanvasLayer

static func show_receipt(parent: Node, receipt: Dictionary) -> void:
	var view := LotteryReceipt.new()
	parent.get_tree().root.add_child(view)
	view._build(receipt)

func _build(receipt: Dictionary) -> void:
	layer = 240
	name = "LotteryReceipt"
	var shade := ColorRect.new()
	shade.color = Color(0.04, 0.03, 0.02, 0.88)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(shade)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(760, 550)
	panel.theme = Theme.new()
	panel.theme.default_font = PresentationTheme.official_font()
	panel.add_theme_stylebox_override("panel", PresentationTheme.panel_style(Color("#261d14"), PresentationTheme.GOLD, 2, 4, 24))
	center.add_child(panel)
	var margin := MarginContainer.new()
	for side in ["left", "top", "right", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 20)
	panel.add_child(margin)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 12)
	margin.add_child(box)
	var host := TextureRect.new()
	host.texture = preload("res://assets/environment/npcs/lode.png")
	host.custom_minimum_size = Vector2(90, 95)
	host.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	host.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	host.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(host)
	_add_label(box, tr("LOTTO_RESULTS") % (int(receipt.day_index) + 1), 24)
	for prize in MiscServiceConfig.PRIZES:
		var numbers: Array[String] = []
		for number in receipt.draw[prize.id]:
			numbers.append("%02d" % int(number))
		var label := _add_label(box, "%s  %s     %s" % [tr(prize.label), prize.multiplier, " · ".join(numbers)], 32 if prize.id == "special" else 19)
		if prize.id == "special":
			label.add_theme_color_override("font_color", PresentationTheme.GOLD)
		label.modulate.a = 0.0
		var reveal := label.create_tween()
		reveal.tween_interval(0.2 + MiscServiceConfig.PRIZES.find(prize) * 0.24)
		reveal.tween_property(label, "modulate:a", 1.0, 0.2)
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size.y = 150
	box.add_child(scroll)
	var tickets := VBoxContainer.new()
	tickets.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(tickets)
	for ticket in receipt.tickets:
		var prize_label := tr("LOTTO_NO_PRIZE")
		for prize in MiscServiceConfig.PRIZES:
			if prize.id == ticket.prize:
				prize_label = tr(prize.label) + " " + prize.multiplier
		_add_label(tickets, "%02d — %s   ·   %s → %s" % [int(ticket.number), prize_label, VndWallet.format_vnd(int(ticket.stake_vnd)), VndWallet.format_vnd(int(ticket.payout_vnd), true)], 17)
	var special_win := false
	for ticket in receipt.tickets:
		if ticket.prize == "special":
			special_win = true
	if special_win:
		_add_label(box, tr("LOTTO_SPECIAL") + " ×80!", 38).add_theme_color_override("font_color", PresentationTheme.GOLD)
	_add_label(box, tr("LOTTO_PAID") % VndWallet.format_vnd(int(receipt.total_vnd), true), 32 if special_win else 26).add_theme_color_override("font_color", PresentationTheme.MONEY_GAIN)
	var close := Button.new()
	close.name = "CloseReceipt"
	close.text = tr("EVENT_CONTINUE")
	close.custom_minimum_size.y = 42
	box.add_child(close)
	close.pressed.connect(queue_free)
	close.grab_focus()
	panel.modulate.a = 0.0
	create_tween().tween_property(panel, "modulate:a", 1.0, 0.35)

func _add_label(parent: Node, text: String, font_size: int) -> Label:
	var label := Label.new()
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", PresentationTheme.INK)
	parent.add_child(label)
	return label
