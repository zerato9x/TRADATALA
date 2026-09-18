extends Control
signal continued()
var primary: Button
var rows: VBoxContainer
var title_label: Label
var net_label: Label
var portrait: TextureRect

func words(en: String, vi: String) -> String:
	return vi if TranslationServer.get_locale().begins_with("vi") else en

func _label(text: String, font_size: int = 20, color: Color = Color("e6dfce")) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return label

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	var shade := ColorRect.new()
	shade.color = Color(0.02, 0.03, 0.04, 0.985)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(shade)
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side in ["left", "right"]:
		margin.add_theme_constant_override("margin_" + side, 54)
	for side in ["top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 26)
	add_child(margin)
	var layout := HBoxContainer.new()
	layout.add_theme_constant_override("separation", 36)
	margin.add_child(layout)
	portrait = TextureRect.new()
	portrait.custom_minimum_size.x = 240
	portrait.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	portrait.texture = load("res://assets/environment/npcs/doino.png")
	layout.add_child(portrait)
	var body := VBoxContainer.new()
	body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.size_flags_stretch_ratio = 2.5
	body.add_theme_constant_override("separation", 12)
	layout.add_child(body)
	title_label = _label("", 26)
	body.add_child(title_label)
	net_label = _label("", 42, Color("f5ca65"))
	body.add_child(net_label)
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	body.add_child(scroll)
	rows = VBoxContainer.new()
	rows.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	rows.add_theme_constant_override("separation", 9)
	scroll.add_child(rows)
	primary = Button.new()
	primary.custom_minimum_size.y = 54
	primary.pressed.connect(func(): continued.emit())
	body.add_child(primary)
	visible = false

func line(label: String, value: String, color := Color("e6dfce")) -> void:
	var row := HBoxContainer.new()
	var name_label := _label(label, 18, color)
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(name_label)
	var amount := _label(value, 18, color)
	amount.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	amount.autowrap_mode = TextServer.AUTOWRAP_OFF
	amount.size_flags_horizontal = Control.SIZE_SHRINK_END
	row.add_child(amount)
	rows.add_child(row)

func reason_name(reason: String) -> String:
	var names := {
		"new_meld": ["New melds", "Phỏm mới"], "extension": ["Extensions", "Nối phỏm"],
		"deadwood": ["Deadwood", "Bài rác"], "daily_debt": ["Debt collected", "Đã trả nợ"],
		"drink_purchase": ["Drinks", "Đồ uống"], "gieo_que_cast": ["Gieo Quẻ", "Gieo Quẻ"],
		"shoe_polish": ["Shoe polish", "Đánh giày"], "shoe_tip": ["Tips", "Tiền boa"],
		"lottery_ticket": ["Lottery tickets", "Vé số"], "lottery_settlement": ["Lottery winnings", "Trúng vé số"],
		"u_bonus": ["Ù bonus", "Thưởng Ù"], "u_khan": ["Ù khan", "Ù khan"],
		"native_retrigger": ["Meld retriggers", "Kích hoạt lại phỏm"], "gieo_retrigger": ["Gieo retriggers", "Gieo kích hoạt lại"],
		"u": ["Ù", "Ù"], "u_khan_count": ["Ù khan", "Ù khan"], "mom": ["Móm", "Móm"],
		"cards_drawn": ["Cards drawn", "Bài đã rút"], "phase_settlement": ["Phases settled", "Lượt chốt pha"],
		"keep": ["Hands kept", "Giữ bài"], "dump": ["Hands redrawn", "Đổi bài"],
		"set_milestone": ["SET milestones", "Mốc bộ SET"], "perfected_run": ["Perfected RUN", "Sảnh hoàn hảo"],
		"exhaustion_meld": ["Exhaustion payouts", "Thu từ cạn bài"],
		"new_meld_count": ["Melds", "Phỏm"], "card_triggers": ["Card triggers", "Lượt kích hoạt bài"],
		"retriggers": ["Retriggers", "Lượt kích hoạt lại"], "relic_triggers": ["Relic triggers", "Lượt kích hoạt di vật"],
		"exhaustions": ["Exhaustions", "Cạn bài"], "discard": ["Discards", "Lượt đánh bài"],
		"deals": ["Deals completed", "Ván hoàn thành"], "days": ["Days completed", "Ngày hoàn thành"]}
	if reason.begins_with("relic_purchase:"):
		return words("Bought relic · ", "Mua di vật · ") + reason.trim_prefix("relic_purchase:").capitalize()
	if reason.begins_with("relic:"):
		return words("Relic · ", "Di vật · ") + reason.trim_prefix("relic:").capitalize()
	var pair: Array = names.get(reason, [reason.capitalize(), reason.capitalize()])
	return words(pair[0], pair[1])

func show_report(report: Dictionary, mode: String, heading: String, button_text: String) -> void:
	for child in rows.get_children():
		rows.remove_child(child)
		child.queue_free()
	portrait.visible = mode == "collection"
	title_label.text = heading
	net_label.text = VndWallet.format_vnd(int(report.net_vnd), true)
	line(words("NET CHANGE", "THAY ĐỔI RÒNG"), "")
	line(words("Opening wallet", "Ví ban đầu"), VndWallet.format_vnd(int(report.opening_vnd)))
	line(words("Earned", "Thu vào"), VndWallet.format_vnd(int(report.income_vnd), true), Color("a2d19a"))
	line(words("Spent / lost", "Chi / mất"), VndWallet.format_vnd(-int(report.expense_vnd)), Color("ec9683"))
	line(words("Wallet now", "Ví hiện tại"), VndWallet.format_vnd(int(report.closing_vnd)))
	if report.has("due_vnd"):
		rows.add_child(HSeparator.new())
		var due := int(report.due_vnd)
		line(words("ĐÒI NỢ · Due tonight", "ĐÒI NỢ · Nợ tối nay"), VndWallet.format_vnd(due), Color("f5ca65"))
		line(words("After collection", "Sau khi trả nợ"), VndWallet.format_vnd(int(report.closing_vnd) - due))
		if int(report.get("shortfall_vnd", 0)) > 0:
			line(words("SHORTFALL", "CÒN THIẾU"), VndWallet.format_vnd(int(report.shortfall_vnd)), Color("ec9683"))
	rows.add_child(HSeparator.new())
	for reason: String in report.categories:
		line(reason_name(reason), VndWallet.format_vnd(int(report.categories[reason]), true))
	if report.has("counts"):
		rows.add_child(HSeparator.new())
		for key: String in report.counts:
			line(reason_name(key), str(report.counts[key]))
	if report.has("phases"):
		rows.add_child(HSeparator.new())
		for phase: Dictionary in report.phases:
			line(words("Phase ", "Pha ") + str(phase.phase), VndWallet.format_vnd(int(phase.net_vnd), true))
			line("Ù / Ù khan / Móm", "%s / %s / %s" % [words("Yes", "Có") if phase.get("u", false) else "—", phase.get("u_khan_count", 0), words("Yes", "Có") if phase.get("mom", false) else "—"])
	var details := Button.new()
	details.text = words("ALL TRANSACTIONS · ", "TẤT CẢ GIAO DỊCH · ") + str(report.entries.size())
	rows.add_child(details)
	var detail_rows := VBoxContainer.new()
	detail_rows.visible = false
	rows.add_child(detail_rows)
	for entry: Dictionary in report.entries:
		var label := _label("%s   %s   → %s" % [reason_name(String(entry.reason)), VndWallet.format_vnd(int(entry.amount_vnd), true), VndWallet.format_vnd(int(entry.after_vnd))], 16)
		detail_rows.add_child(label)
	details.pressed.connect(func(): detail_rows.visible = not detail_rows.visible)
	primary.text = button_text
	visible = true
	primary.grab_focus()
	if mode == "collection":
		portrait.modulate.a = 0.0
		var arrival := create_tween()
		arrival.tween_property(portrait, "modulate:a", 1.0, 0.3)
