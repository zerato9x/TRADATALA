extends Control
## Read-only presentation of committed accounting. Never mutates the wallet.
signal continued()
signal endless_requested()
var endless_button: Button
const INK := Color("24354c")
const MUTED := Color("687182")
const PAPER := Color("f1e8d2")
const GREEN := Color("367453")
const RED := Color("aa493f")
var primary: Button
var rows: VBoxContainer
var title_label: Label
var net_label: Label
var portrait: TextureRect
var _body: VBoxContainer
var _summary: HBoxContainer
var _tabs: HBoxContainer
var _scroll: ScrollContainer
var _footer: Label
var _report: Dictionary
var _page_animation: Tween
var _animation: Tween
var _leaving := false
var _page := "overview"
var _mode := ""
var _sound: AudioStreamPlayer

func words(en: String, vi: String) -> String:
	return vi if TranslationServer.get_locale().begins_with("vi") else en

func _label(text: String, font_size: int = 20, color: Color = INK) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return label

func _panel(parent: Node, color: Color = PAPER) -> VBoxContainer:
	var panel := PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var style := PresentationTheme.panel_style(color, Color("acb6bb"), 1, 5, 4)
	style.content_margin_left = 20
	style.content_margin_right = 20
	style.content_margin_top = 14
	style.content_margin_bottom = 14
	panel.add_theme_stylebox_override("panel", style)
	parent.add_child(panel)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 8)
	panel.add_child(box)
	return box

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	theme = PresentationTheme.create_game_theme()
	mouse_filter = Control.MOUSE_FILTER_STOP
	var shade := ColorRect.new()
	shade.color = Color("142c50f5")
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(shade)
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side in ["left", "right"]:
		margin.add_theme_constant_override("margin_" + side, 38)
	for side in ["top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 24)
	add_child(margin)
	_body = VBoxContainer.new()
	_body.add_theme_constant_override("separation", 14)
	margin.add_child(_body)
	var brand := _label("TRÀ ĐÁ TÁ LẢ   /   " + words("THE TABLE'S ACCOUNTS", "SỔ THU CHI"), 14, PresentationTheme.MUTED)
	_body.add_child(brand)
	title_label = _label("", 28, PresentationTheme.INK)
	_body.add_child(title_label)
	_summary = HBoxContainer.new()
	_summary.add_theme_constant_override("separation", 14)
	_body.add_child(_summary)
	_tabs = HBoxContainer.new()
	_tabs.add_theme_constant_override("separation", 10)
	_body.add_child(_tabs)
	_scroll = ScrollContainer.new()
	_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_body.add_child(_scroll)
	rows = VBoxContainer.new()
	rows.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	rows.add_theme_constant_override("separation", 12)
	_scroll.add_child(rows)
	var footer := HBoxContainer.new()
	footer.add_theme_constant_override("separation", 24)
	_body.add_child(footer)
	_footer = _label("", 16, PresentationTheme.MUTED)
	_footer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	footer.add_child(_footer)
	endless_button = Button.new()
	endless_button.custom_minimum_size = Vector2(220, 50)
	PresentationTheme.configure_button(endless_button, "tea")
	endless_button.add_theme_font_size_override("font_size", 16)
	endless_button.pressed.connect(_endless)
	footer.add_child(endless_button)
	endless_button.hide()
	primary = Button.new()
	primary.custom_minimum_size = Vector2(280, 50)
	PresentationTheme.configure_button(primary, "gold")
	primary.add_theme_font_size_override("font_size", 18)
	primary.pressed.connect(_continue)
	footer.add_child(primary)
	portrait = TextureRect.new()
	portrait.texture = preload("res://assets/environment/npcs/doino.png")
	portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_sound = AudioStreamPlayer.new()
	_sound.stream = preload("res://assets/audio/sfx/card_place.mp3")
	_sound.bus = "Sound"
	_sound.volume_db = -14
	add_child(_sound)
	visible = false

func _clear(node: Node) -> void:
	for child in node.get_children():
		node.remove_child(child)
		child.queue_free()

func _continue() -> void:
	if _leaving or not visible:
		return
	_leaving = true
	primary.disabled = true
	if _animation and _animation.is_running():
		_animation.kill()
	# The controller owns transitions and all payments, including reentrant signals.
	_animation = create_tween()
	_animation.tween_property(_body, "modulate:a", 0.0, 0.14)
	_animation.tween_callback(func(): continued.emit())

func line(label: String, value: String, color: Color = INK, parent: Node = null) -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 24)
	var name_label := _label(label, 17, color)
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(name_label)
	var amount := _label(value, 18, color)
	amount.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	amount.autowrap_mode = TextServer.AUTOWRAP_OFF
	row.add_child(amount)
	(parent if parent != null else rows).add_child(row)

func _stat(label: String, amount: int, color: Color) -> Label:
	var box := _panel(_summary)
	box.add_child(_label(label, 14, MUTED))
	var value := _label(VndWallet.format_vnd(amount, true), 32, color)
	value.autowrap_mode = TextServer.AUTOWRAP_OFF
	box.add_child(value)
	return value

func show_report(report: Dictionary, mode: String, heading: String, button_text: String) -> void:
	if _animation and _animation.is_running():
		_animation.kill()
	_report = report.duplicate(true)
	_mode = mode
	_leaving = false
	primary.disabled = false
	# The portrait is reused across collection reports, independently of old panels.
	if portrait.get_parent():
		portrait.get_parent().remove_child(portrait)
	_clear(_summary)
	title_label.text = heading
	net_label = _stat(words("NET CHANGE", "THAY ĐỔI RÒNG"), int(report.net_vnd), GREEN if int(report.net_vnd) >= 0 else RED)
	_stat(words("EARNED", "THU VÀO"), int(report.income_vnd), GREEN)
	_stat(words("SPENT / LOST", "CHI / MẤT"), -int(report.expense_vnd), RED)
	_clear(_tabs)
	var pages := ["chronicle", "overview", "cards", "ledger"] if mode == "outcome" else ["overview", "cards", "ledger"]
	for page in pages:
		var tab := Button.new()
		tab.name = page
		tab.text = {"chronicle": words("RUN SCROLL", "CUỘN THÀNH TÍCH"), "overview": words("SUMMARY", "TỔNG KẾT"), "cards": words("SCORING CARDS", "BÀI GHI ĐIỂM"), "ledger": words("TRANSACTIONS", "GIAO DỊCH")}[page]
		tab.custom_minimum_size = Vector2(180, 36)
		tab.toggle_mode = true
		PresentationTheme.configure_button(tab)
		tab.pressed.connect(func(): _show_page(page))
		_tabs.add_child(tab)
	primary.text = button_text
	_footer.text = words("Wallet", "Ví") + "   " + VndWallet.format_vnd(int(report.opening_vnd)) + "   →   " + VndWallet.format_vnd(int(report.closing_vnd))
	endless_button.visible = bool(report.get("can_endless", false))
	endless_button.disabled = false
	endless_button.text = words("CONTINUE · ENDLESS", "TIẾP TỤC · VÔ TẬN")
	_show_page("chronicle" if mode == "outcome" else "overview")
	visible = true
	primary.grab_focus()
	_body.modulate.a = 0.0
	_animation = create_tween().set_parallel(true)
	_animation.tween_property(_body, "modulate:a", 1.0, 0.28)
	_animation.tween_method(func(value: float): net_label.text = VndWallet.format_vnd(roundi(value), true), 0.0, float(report.net_vnd), 0.65).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	_sound.play()

func _show_page(page: String) -> void:
	if _page_animation and _page_animation.is_running():
		_page_animation.kill()
	_page = page
	if portrait.get_parent():
		portrait.get_parent().remove_child(portrait)
	portrait.visible = false
	_clear(rows)
	_scroll.scroll_vertical = 0
	for tab: Button in _tabs.get_children():
		tab.set_pressed_no_signal(String(tab.name) == page)
	match page:
		"chronicle": _chronicle()
		"overview": _overview()
		"cards": _cards()
		"ledger": _ledger()
	# Fade newly laid-out content without moving container-owned coordinates.
	rows.modulate.a = 0.0
	_page_animation = create_tween()
	_page_animation.tween_property(rows, "modulate:a", 1.0, 0.2)

func _overview() -> void:
	if _report.has("due_vnd"):
		var collector := HBoxContainer.new()
		collector.add_theme_constant_override("separation", 20)
		rows.add_child(collector)
		portrait.custom_minimum_size = Vector2(120, 145)
		collector.add_child(portrait)
		portrait.visible = _mode == "collection"
		var debt := _panel(collector)
		debt.add_child(_label(words("ĐÒI NỢ · TONIGHT'S COLLECTION", "ĐÒI NỢ · THU NỢ TỐI NAY"), 20))
		line(words("Amount due", "Nợ phải trả"), VndWallet.format_vnd(int(_report.due_vnd)), INK, debt)
		var shortfall := int(_report.get("shortfall_vnd", 0))
		line(words("Shortfall", "Còn thiếu") if shortfall > 0 else words("Wallet after payment", "Ví sau khi trả nợ"), VndWallet.format_vnd(shortfall if shortfall > 0 else int(_report.closing_vnd) - int(_report.due_vnd)), RED if shortfall > 0 else GREEN, debt)
	var columns := HBoxContainer.new()
	columns.add_theme_constant_override("separation", 14)
	rows.add_child(columns)
	var earnings := _panel(columns)
	earnings.add_child(_label(words("AT THE TABLE", "TRÊN BÀN BÀI"), 20))
	var categories: Dictionary = _report.get("categories", {})
	if categories.is_empty():
		earnings.add_child(_label(words("No money changed hands.", "Chưa có thu chi."), 17, MUTED))
	for reason: String in categories:
		var amount := int(categories[reason])
		line(reason_name(reason), VndWallet.format_vnd(amount, true), GREEN if amount >= 0 else RED, earnings)
	var activity := _panel(columns)
	activity.add_child(_label(words("YOUR PLAY", "VÁN BÀI CỦA BẠN"), 20))
	var counts: Dictionary = _report.get("counts", {})
	var shown := 0
	for key: String in counts:
		if int(counts[key]) > 0:
			line(reason_name(key), str(counts[key]), INK, activity)
			shown += 1
	if shown == 0:
		activity.add_child(_label(words("No recorded actions.", "Chưa có lượt chơi."), 17, MUTED))
	for phase: Dictionary in _report.get("phases", []):
		var box := _panel(rows)
		line(words("PHASE ", "PHA ") + str(phase.phase), VndWallet.format_vnd(int(phase.net_vnd), true), INK, box)
		box.add_child(_label("Ù: %s   /   Ù khan: %s   /   Móm: %s" % [words("Yes", "Có") if phase.get("u", false) else "—", phase.get("u_khan_count", 0), words("Yes", "Có") if phase.get("mom", false) else "—"], 16, MUTED))

func _cards() -> void:
	var actions: Array = _report.get("actions", [])
	var found := false
	for action: Dictionary in actions:
		var hits: Array = []
		var passes: Array = action.get("passes", [])
		for scoring_pass: Dictionary in passes:
			hits.append_array(scoring_pass.get("hits", []))
		if passes.is_empty():
			hits.append_array(action.get("hits", []))
		if hits.is_empty():
			continue
		found = true
		var box := _panel(rows)
		var deal_prefix := words("Deal ", "Ván ") + str(action.deal_number) + " / " if action.has("deal_number") else ""
		line(deal_prefix + words("Phase ", "Pha ") + str(action.get("phase", 1)) + " · " + reason_name(str(action.action)), str(action.get("points", 0)) + words(" points", " điểm"), INK, box)
		var inspection := _label(words("Select a card to inspect its properties.", "Chọn lá bài để xem thuộc tính."), 15, MUTED)
		box.add_child(inspection)
		var flow := HFlowContainer.new()
		flow.add_theme_constant_override("h_separation", 12)
		flow.add_theme_constant_override("v_separation", 12)
		box.add_child(flow)
		var grouped: Dictionary = {}
		for hit: Dictionary in hits:
			var id := str(hit.get("card_id", ""))
			if id.is_empty():
				line(words("Meld adjustment", "Điều chỉnh phỏm"), str(hit.points) + words(" points", " điểm"), MUTED, box)
				continue
			if not grouped.has(id):
				grouped[id] = {"hit": hit, "points": 0, "triggers": 0}
			grouped[id].points += int(hit.points)
			grouped[id].triggers += 1
		for id: String in grouped:
			var data: Dictionary = grouped[id]
			var tile := VBoxContainer.new()
			tile.custom_minimum_size.x = 116
			flow.add_child(tile)
			var face := TextureRect.new()
			face.custom_minimum_size = Vector2(116, 126)
			face.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			face.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			var path := str(data.hit.get("texture_path", ""))
			if ResourceLoader.exists(path):
				face.texture = load(path)
			var inspect := Button.new()
			inspect.custom_minimum_size = Vector2(116, 126)
			inspect.flat = true
			inspect.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
			inspect.add_theme_stylebox_override("focus", PresentationTheme.panel_style(Color.TRANSPARENT, PresentationTheme.GOLD, 2))
			tile.add_child(inspect)
			inspect.add_child(face)
			face.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
			var caption := _label(str(data.points) + words(" pts", " điểm"), 22)
			caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			tile.add_child(caption)
			var triggers := _label(str(data.triggers) + words(" trigger" if int(data.triggers) == 1 else " triggers", " kích hoạt"), 13, MUTED)
			triggers.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			tile.add_child(triggers)
			var properties: PackedStringArray = []
			for property_id: String in data.hit.get("properties", []):
				properties.append(tr(CardData.gieo_property_label_key(property_id)))
			if data.hit.get("shiny", false):
				properties.append(words("Polished", "Đã đánh bóng"))
			var description := str(data.hit.get("label", "")) + " · " + (", ".join(properties) if not properties.is_empty() else words("Standard card", "Bài thường"))
			inspect.tooltip_text = description
			inspect.pressed.connect(func(): inspection.text = description)
			face.mouse_filter = Control.MOUSE_FILTER_IGNORE
			face.pivot_offset = Vector2(58, 63)
			face.scale = Vector2(0.92, 0.92)
			var arrival := face.create_tween()
			arrival.tween_interval(minf(flow.get_child_count() * 0.045, 0.35))
			arrival.tween_property(face, "scale", Vector2.ONE, 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		if not passes.is_empty():
			box.add_child(_label(words("Scoring breakdown · included above", "Chi tiết tính điểm · đã gồm ở trên"), 15, MUTED))
			for scoring_pass: Dictionary in passes:
				line(reason_name(str(scoring_pass.origin)), str(scoring_pass.points) + words(" points", " điểm"), INK, box)
		for bonus: Dictionary in action.get("relics", []):
			line(words("Relic bonus · ", "Thưởng di vật · ") + _relic_name(str(bonus.id)), "+" + str(bonus.points) + words(" points", " điểm"), GREEN, box)
	if not found:
		var empty := _panel(rows)
		empty.add_child(_label(words("No scoring cards in this report", "Chưa có bài ghi điểm trong báo cáo này"), 24))
		empty.add_child(_label(words("Cards appear here after a meld or extension scores. Your complete money history is in Transactions.", "Bài sẽ hiện ở đây sau khi hạ hoặc nối phỏm ghi điểm. Xem toàn bộ thu chi trong Giao dịch."), 18, MUTED))

func _ledger() -> void:
	var box := _panel(rows)
	line(words("TRANSACTION", "GIAO DỊCH"), words("CHANGE   /   WALLET", "THAY ĐỔI   /   SỐ DƯ"), MUTED, box)
	for entry: Dictionary in _report.get("entries", []):
		line(reason_name(str(entry.reason)), VndWallet.format_vnd(int(entry.amount_vnd), true) + "   /   " + VndWallet.format_vnd(int(entry.after_vnd)), GREEN if int(entry.amount_vnd) >= 0 else RED, box)
	if _report.get("entries", []).is_empty():
		box.add_child(_label(words("No transactions yet.", "Chưa có giao dịch."), 18, MUTED))

func _exit_tree() -> void:
	# May be detached when leaving a non-collection screen.
	if is_instance_valid(portrait) and portrait.get_parent() == null:
		portrait.free()
func reason_name(reason: String) -> String:
	var names := {
		"originating": ["Initial scoring", "Tính điểm ban đầu"],
		"new_meld": ["New melds", "Phỏm mới"], "extension": ["Extensions", "Nối phỏm"],
		"deadwood": ["Deadwood", "Bài rác"], "daily_debt": ["Debt collected", "Đã trả nợ"],
		"relic_reroll": ["Shop rerolls", "Đổi hàng"], "drink_purchase": ["Drinks", "Đồ uống"], "gieo_que_cast": ["Gieo Quẻ", "Gieo Quẻ"],
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
		"exhaustion": ["Exhaustion", "Cạn bài"], "exhaustions": ["Exhaustions", "Cạn bài"], "discard": ["Discards", "Lượt đánh bài"],
		"deals": ["Deals completed", "Ván hoàn thành"], "days": ["Days completed", "Ngày hoàn thành"]}
	if reason.begins_with("relic_purchase:"):
		return words("Bought relic · ", "Mua di vật · ") + _relic_name(reason.trim_prefix("relic_purchase:"))
	if reason.begins_with("relic:"):
		return words("Relic · ", "Di vật · ") + _relic_name(reason.trim_prefix("relic:"))
	var pair: Array = names.get(reason, [reason.capitalize(), reason.capitalize()])
	return words(pair[0], pair[1])


func _relic_name(id: String) -> String:
	return words(id.capitalize(), str(RelicCatalog.DEFINITIONS.get(id, {}).get("name", id.capitalize())))


func _endless() -> void:
	if _leaving or not visible:
		return
	_leaving = true
	primary.disabled = true
	endless_button.disabled = true
	if _animation and _animation.is_running():
		_animation.kill()
	_animation = create_tween()
	_animation.tween_property(_body, "modulate:a", 0.0, 0.14)
	_animation.tween_callback(func(): endless_requested.emit())


func _chronicle() -> void:
	var hero := _panel(rows)
	hero.add_child(_label(words("THE WEEK IS YOURS", "BẠN ĐÃ CHINH PHỤC TUẦN NÀY") if _report.get("won", false) else words("EVERY RUN TELLS A STORY", "MỖI VÁN ĐỀU CÓ MỘT CÂU CHUYỆN"), 28))
	var seed_row := HBoxContainer.new()
	hero.add_child(seed_row)
	var seed_text := _label(words("SEED · ", "HẠT GIỐNG · ") + str(_report.get("seed", "")), 16, MUTED)
	seed_text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	seed_row.add_child(seed_text)
	var copy := Button.new()
	copy.text = words("COPY SEED", "CHÉP HẠT GIỐNG")
	PresentationTheme.configure_button(copy)
	copy.pressed.connect(func(): DisplayServer.clipboard_set(str(_report.get("seed", ""))))
	seed_row.add_child(copy)
	var days: Array = _report.get("days", [])
	var paid := 0
	for day: Dictionary in days:
		if day.get("paid", false):
			paid += int(day.get("due_vnd", 0))
	line(words("Debt repaid", "Nợ đã trả"), VndWallet.format_vnd(paid), GREEN, hero)
	line(words("Deals completed", "Ván hoàn thành"), str(_report.get("counts", {}).get("deals", 0)), INK, hero)
	line(words("Days survived", "Ngày vượt qua"), str(_report.get("counts", {}).get("days", 0)), INK, hero)
	if _report.get("can_endless", false):
		hero.add_child(_label(words("Sunday is paid. Keep your deck, relics and wallet. Endless begins at VNĐ24,000,000 and grows 50% per day.", "Đã trả nợ Chủ nhật. Giữ bộ bài, di vật và ví tiền. Vô tận bắt đầu với nợ VNĐ24.000.000, tăng 50% mỗi ngày."), 17, GREEN))
	var card_totals := {}
	var best_action := 0
	for action: Dictionary in _report.get("actions", []):
		best_action = maxi(best_action, int(action.get("points", 0)))
		for scoring_pass: Dictionary in action.get("passes", []):
			for hit: Dictionary in scoring_pass.get("hits", []):
				var id := str(hit.get("card_id", ""))
				if id.is_empty():
					continue
				if not card_totals.has(id):
					card_totals[id] = {"id": id, "texture": hit.get("texture_path", ""), "points": 0, "triggers": 0}
				card_totals[id].points += int(hit.points)
				card_totals[id].triggers += 1
	var ranked: Array = card_totals.values()
	ranked.sort_custom(func(a: Dictionary, b: Dictionary): return int(a.points) > int(b.points) if a.points != b.points else str(a.id) < str(b.id))
	var awards := _panel(rows)
	awards.add_child(_label(words("THE MVPs · YOUR HARDEST-WORKING CARDS", "NHỮNG LÁ BÀI XUẤT SẮC NHẤT"), 22))
	awards.add_child(_label(words("Card contributions across this run, including retriggers. Shared adjustments and relic bonuses are counted separately.", "Tổng đóng góp của bài, gồm kích hoạt lại. Điều chỉnh chung và thưởng di vật được tính riêng."), 15, MUTED))
	var podium := HBoxContainer.new()
	podium.add_theme_constant_override("separation", 18)
	awards.add_child(podium)
	for index in mini(3, ranked.size()):
		var card: Dictionary = ranked[index]
		var tile := _panel(podium, Color("e5dbc1"))
		tile.add_child(_label([words("MVP", "XUẤT SẮC NHẤT"), words("SECOND", "HẠNG NHÌ"), words("THIRD", "HẠNG BA")][index], 16, MUTED))
		var face := TextureRect.new()
		face.custom_minimum_size = Vector2(100, 140)
		face.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		face.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		if ResourceLoader.exists(str(card.texture)):
			face.texture = load(str(card.texture))
		tile.add_child(face)
		var points := _label(str(card.points) + words(" pts", " điểm"), 24, GREEN)
		points.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		tile.add_child(points)
		var triggers := _label(str(card.triggers) + words(" scoring trigger" if int(card.triggers) == 1 else " scoring triggers", " lượt ghi điểm"), 14, MUTED)
		triggers.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		tile.add_child(triggers)
	if ranked.is_empty():
		awards.add_child(_label(words("No scored cards recorded this run.", "Chưa có bài ghi điểm trong lượt chơi này."), 18, MUTED))
	line(words("Strongest play", "Lượt đánh mạnh nhất"), str(best_action) + words(" points", " điểm"), INK, awards)
	var records := _panel(rows)
	records.add_child(_label(words("THE WHOLE JOURNEY", "TOÀN BỘ HÀNH TRÌNH"), 22))
	for index in days.size():
		var day: Dictionary = days[index]
		line(words("Day ", "Ngày ") + str(index + 1) + (words(" · PAID", " · ĐÃ TRẢ") if day.get("paid", false) else words(" · SHORTFALL", " · THIẾU NỢ")), VndWallet.format_vnd(int(day.get("due_vnd", 0))), INK if day.get("paid", false) else RED, records)
		line(words("Earned / spent", "Thu / chi"), VndWallet.format_vnd(int(day.get("income_vnd", 0))) + " / " + VndWallet.format_vnd(int(day.get("expense_vnd", 0))), MUTED, records)
	var drinks := {}
	for activity: Dictionary in _report.get("activities", []):
		if activity.get("action", "") == "drink_selected":
			drinks[activity.id] = int(drinks.get(activity.id, 0)) + 1
	if not drinks.is_empty():
		var drinks_box := _panel(rows)
		drinks_box.add_child(_label(words("YOUR DRINKS", "ĐỒ UỐNG ĐÃ CHỌN"), 22))
		for id: String in drinks:
			line(DrinkCatalog.display_name(id), str(drinks[id]), INK, drinks_box)
	var totals := _panel(rows)
	totals.add_child(_label(words("EVERY TRIGGER COUNTS", "MỖI LƯỢT ĐỀU ĐÁNG GIÁ"), 22))
	for key: String in _report.get("counts", {}):
		line(reason_name(key), str(_report.counts[key]), INK, totals)
	for reason: String in _report.get("categories", {}):
		if reason.begins_with("relic:"):
			line(reason_name(reason), VndWallet.format_vnd(int(_report.categories[reason]), true), GREEN, totals)
