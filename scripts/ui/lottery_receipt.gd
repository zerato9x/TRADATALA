class_name LotteryReceipt
extends CanvasLayer

var _covered_sprite: CanvasItem
var _restore_covered_sprite := false
var _covered_panel: CanvasItem
var _restore_covered_panel := false

static func show_receipt(parent: Node, receipt: Dictionary) -> void:
	var view := LotteryReceipt.new()
	parent.get_tree().root.add_child(view)
	var table := parent.get_tree().root.find_child("LottoFocused", true, false) as CanvasItem
	if table != null:
		view._covered_sprite = table
		view._restore_covered_sprite = table.visible
		table.hide()
	var event_panel := parent.get_tree().root.find_child("EventTableContent", true, false) as CanvasItem
	if event_panel != null:
		view._covered_panel = event_panel
		view._restore_covered_panel = event_panel.visible
		event_panel.hide()
	view._build(receipt)

func _process(_delta: float) -> void:
	if is_instance_valid(_covered_sprite) and _covered_sprite.visible:
		_restore_covered_sprite = true
		_covered_sprite.hide()
	if is_instance_valid(_covered_panel) and _covered_panel.visible:
		_restore_covered_panel = true
		_covered_panel.hide()

func _exit_tree() -> void:
	if _restore_covered_sprite and is_instance_valid(_covered_sprite):
		_covered_sprite.show()
	if _restore_covered_panel and is_instance_valid(_covered_panel):
		_covered_panel.show()

func _build(receipt: Dictionary) -> void:
	layer = 240
	name = "LotteryReceipt"
	var shade := ColorRect.new()
	shade.name = "ReceiptShade"
	shade.color = Color(0.015, 0.025, 0.035, 0.54)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.theme = PresentationTheme.create_game_theme()
	add_child(shade)
	var host := TextureRect.new()
	host.name = "LotteryHost"
	host.texture = preload("res://assets/environment/npcs/lode.png")
	host.position = Vector2(855, 45)
	host.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	host.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	host.custom_minimum_size = Vector2(405, 635)
	host.size = Vector2(405, 635)
	host.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	host.mouse_filter = Control.MOUSE_FILTER_IGNORE
	host.material = ShaderMaterial.new()
	(host.material as ShaderMaterial).shader = preload("res://shaders/npc_focus.gdshader")
	shade.add_child(host)
	host.size = Vector2(405, 635)
	var panel := PanelContainer.new()
	panel.name = "ResultText"
	panel.position = Vector2(45, 92)
	panel.size = Vector2(800, 535)
	panel.add_theme_stylebox_override("panel", PresentationTheme.panel_style(Color("#102338ec"), PresentationTheme.GOLD_DARK, 1, 7, 4))
	shade.add_child(panel)
	var margin := MarginContainer.new()
	for side in ["left", "top", "right", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 20)
	panel.add_child(margin)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 8)
	margin.add_child(box)
	_add_label(box, tr("LOTTO_RESULTS") % (int(receipt.day_index) + 1), 26, PresentationTheme.GOLD)
	var draw := VBoxContainer.new()
	draw.name = "DrawnNumbers"
	draw.add_theme_constant_override("separation", 3)
	box.add_child(draw)
	for prize in MiscServiceConfig.PRIZES:
		var numbers: Array[String] = []
		for number in receipt.draw[prize.id]:
			numbers.append("%02d" % int(number))
		var row := _add_label(draw, "%s  %s    %s" % [tr(prize.label), prize.multiplier, " · ".join(numbers)], 22 if prize.id == "special" else 18,
			PresentationTheme.GOLD if prize.id == "special" else PresentationTheme.INK)
		row.name = "Draw_" + String(prize.id)
		row.tooltip_text = _words("Drawn numbers and prize multiplier", "Số đã xổ và hệ số giải thưởng")
		row.modulate.a = 0.0
		var reveal := row.create_tween()
		reveal.tween_interval(0.16 + MiscServiceConfig.PRIZES.find(prize) * 0.18)
		reveal.tween_property(row, "modulate:a", 1.0, 0.2)
	_add_label(box, _words("YOUR TICKETS", "VÉ CỦA BẠN"), 17, PresentationTheme.ACTION)
	var scroll := ScrollContainer.new()
	scroll.name = "TicketResults"
	scroll.custom_minimum_size.y = 132
	scroll.size_flags_vertical = Control.SIZE_FILL
	box.add_child(scroll)
	var tickets := VBoxContainer.new()
	tickets.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tickets.add_theme_constant_override("separation", 5)
	scroll.add_child(tickets)
	for ticket in receipt.tickets:
		var prize_label := tr("LOTTO_NO_PRIZE")
		for prize in MiscServiceConfig.PRIZES:
			if prize.id == ticket.prize:
				prize_label = tr(prize.label) + " " + prize.multiplier
		var payout := int(ticket.payout_vnd)
		var result := _add_label(tickets, "%02d  ·  %s    %s → %s" % [int(ticket.number), prize_label,
			VndWallet.format_vnd(int(ticket.stake_vnd)), VndWallet.format_vnd(payout, true)], 17,
			PresentationTheme.MONEY_GAIN if payout > 0 else PresentationTheme.MUTED)
		result.tooltip_text = _words("Ticket · result · stake · payout", "Vé · kết quả · tiền cược · tiền nhận")
	var special_win := false
	for ticket in receipt.tickets:
		if ticket.prize == "special": special_win = true
	if special_win:
		var jackpot := _add_label(box, tr("LOTTO_SPECIAL") + " ×80!", 28, PresentationTheme.GOLD)
		jackpot.name = "JackpotCallout"
		jackpot.pivot_offset = Vector2(160, 18)
		var pulse := jackpot.create_tween().set_loops(3)
		pulse.tween_property(jackpot, "scale", Vector2(1.035, 1.035), 0.3)
		pulse.tween_property(jackpot, "scale", Vector2.ONE, 0.3)
	var total := _add_label(box, tr("LOTTO_PAID") % VndWallet.format_vnd(int(receipt.total_vnd), true), 26,
		PresentationTheme.MONEY_GAIN if int(receipt.total_vnd) > 0 else PresentationTheme.WARNING)
	total.name = "WinningTotal"
	var close := Button.new()
	close.name = "CloseReceipt"
	close.text = tr("EVENT_CONTINUE")
	close.custom_minimum_size.y = 44
	PresentationTheme.configure_button(close, "gold")
	box.add_child(close)
	close.pressed.connect(queue_free)
	close.grab_focus()
	panel.modulate.a = 0.0
	panel.position.y += 12
	var entrance := create_tween().set_parallel(true)
	entrance.tween_property(panel, "modulate:a", 1.0, 0.25)
	entrance.tween_property(panel, "position:y", 92.0, 0.25)

func _add_label(parent: Node, value: String, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = value
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	parent.add_child(label)
	return label

func _words(en: String, vi: String) -> String:
	return vi if TranslationServer.get_locale().begins_with("vi") else en
