extends Control

signal cash_clicked()

const CardSymbolArtScript := preload("res://scripts/ui/card_symbol_art.gd")

var cash_anchor: Control
var cash_button: Button
var relic_buttons: Array[Button] = []
var journey_button: Button
var journey_detail: PanelContainer
var detail_copy: Label
var objective: Label
var progress: ProgressBar
var week: HBoxContainer
var timeline: GridContainer
var inspect_card: PanelContainer
var inspect_copy: Label
var object_tweens: Dictionary = {}
var money: MoneyPresentation
var balance := -9223372036854775807
var equipped: Array[String] = []
var day_index := 0
var event_slot := 0
var target := 0
var days: Array[Dictionary] = []
var expanded := false
var journey_signature := ""
var cash_locale := ""

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_build_journey()
	_build_objects()
	inspect_card = PanelContainer.new()
	inspect_card.name = "TableItemEffect"
	inspect_card.position = Vector2(710, 164)
	inspect_card.size = Vector2(286, 84)
	inspect_card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	inspect_card.z_index = 30
	inspect_card.add_theme_stylebox_override("panel", _panel_style(Color("#152322fa"), Color("#bdac70")))
	inspect_copy = Label.new()
	inspect_copy.custom_minimum_size = Vector2(254, 60)
	inspect_copy.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	inspect_copy.add_theme_font_size_override("font_size", 16)
	inspect_copy.mouse_filter = Control.MOUSE_FILTER_IGNORE
	inspect_card.add_child(inspect_copy)
	add_child(inspect_card)
	inspect_card.hide()

func words(en: String, vi: String) -> String:
	return vi if TranslationServer.get_locale().begins_with("vi") else en

func _panel_style(color: Color, border: Color) -> StyleBoxFlat:
	var style := PresentationTheme.panel_style(color, border, 1)
	style.content_margin_left = 16
	style.content_margin_right = 16
	style.content_margin_top = 12
	style.content_margin_bottom = 12
	return style

func _label(parent: Node, text_value: String, point: Vector2, extent: Vector2, font_size: int = 16) -> Label:
	var label := Label.new()
	label.text = text_value
	label.position = point
	label.size = extent
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", Color("#f0e7cd"))
	parent.add_child(label)
	return label

func _build_journey() -> void:
	journey_button = Button.new()
	journey_button.name = "JourneyToggle"
	journey_button.position = Vector2(465, 140)
	journey_button.size = Vector2(350, 40)
	journey_button.flat = true
	journey_button.add_theme_font_size_override("font_size", 18)
	journey_button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	journey_button.pressed.connect(func() -> void:
		_set_expanded(not expanded)
		_refresh_journey())
	add_child(journey_button)
	journey_detail = PanelContainer.new()
	journey_detail.name = "JourneyDetail"
	journey_detail.position = Vector2(305, 190)
	journey_detail.size = Vector2(670, 418)
	journey_detail.z_index = 25
	journey_detail.add_theme_stylebox_override("panel", _panel_style(Color("#152322fc"), Color("#8b997d")))
	var body := VBoxContainer.new()
	body.add_theme_constant_override("separation", 12)
	journey_detail.add_child(body)
	week = HBoxContainer.new()
	week.add_theme_constant_override("separation", 5)
	body.add_child(week)
	detail_copy = Label.new()
	detail_copy.custom_minimum_size = Vector2(630, 94)
	detail_copy.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	detail_copy.add_theme_font_size_override("font_size", 17)
	body.add_child(detail_copy)
	objective = _label(body, "", Vector2.ZERO, Vector2(630, 30), 16)
	objective.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	objective.custom_minimum_size = Vector2(630, 28)
	progress = ProgressBar.new()
	progress.custom_minimum_size = Vector2(0, 6)
	progress.show_percentage = false
	progress.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for key in ["background", "fill"]:
		var style := StyleBoxFlat.new()
		style.bg_color = Color("#e6c271") if key == "fill" else Color("#354a43")
		progress.add_theme_stylebox_override(key, style)
	body.add_child(progress)
	timeline = GridContainer.new()
	timeline.columns = 3
	timeline.add_theme_constant_override("h_separation", 12)
	timeline.add_theme_constant_override("v_separation", 10)
	body.add_child(timeline)
	add_child(journey_detail)
	journey_detail.hide()

func _set_expanded(value: bool) -> void:
	expanded = value
	journey_detail.visible = value
	if inspect_card != null:
		inspect_card.hide()

func _input(event: InputEvent) -> void:
	if not expanded or not is_visible_in_tree():
		return
	if event is InputEventMouseButton and event.pressed:
		var point: Vector2 = get_global_transform_with_canvas().affine_inverse() * event.position
		if not journey_detail.get_rect().has_point(point) and not journey_button.get_rect().has_point(point):
			_set_expanded(false)
			_refresh_journey()

func _build_objects() -> void:
	cash_anchor = Control.new()
	cash_anchor.name = "EventCashPiles"
	cash_anchor.position = Vector2(425, 385)
	cash_anchor.size = Vector2(270, 194)
	cash_anchor.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(cash_anchor)
	cash_button = Button.new()
	cash_button.name = "EventCashInspect"
	cash_button.position = cash_anchor.position - Vector2(10, 10)
	cash_button.size = cash_anchor.size + Vector2(20, 20)
	cash_button.flat = true
	for state in ["normal", "hover", "pressed", "focus"]:
		cash_button.add_theme_stylebox_override(state, StyleBoxEmpty.new())
	cash_button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	cash_button.pressed.connect(func() -> void: cash_clicked.emit())
	cash_button.mouse_entered.connect(func() -> void:
		cash_anchor.modulate = Color(1.15, 1.15, 1.1)
		_show_effect(words("CASH ON THE TABLE", "TIỀN TRÊN BÀN") + "\n" + VndWallet.format_vnd(balance)))
	cash_button.mouse_exited.connect(func() -> void:
		cash_anchor.modulate = Color.WHITE
		inspect_card.hide())
	add_child(cash_button)
	for index in RelicRuntime.MAX_EQUIPPED:
		var button := Button.new()
		button.name = "TableRelic%d" % index
		button.position = [Vector2(733, 330), Vector2(842, 394), Vector2(711, 498), Vector2(858, 540)][index]
		button.size = Vector2(130, 104)
		button.rotation = deg_to_rad([-13.0, 9.0, -8.0, 16.0][index])
		button.pivot_offset = button.size * 0.5
		button.flat = true
		button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		var icon := TextureRect.new()
		icon.name = "RelicIcon"
		icon.position = Vector2.ZERO
		icon.size = button.size
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var shadow := TextureRect.new()
		shadow.name = "ContactShadow"
		shadow.position = Vector2(3, 6)
		shadow.size = button.size
		shadow.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		shadow.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		shadow.modulate = Color(0, 0, 0, 0.4)
		shadow.mouse_filter = Control.MOUSE_FILTER_IGNORE
		button.add_child(shadow)
		button.add_child(icon)
		for state in ["normal", "hover", "pressed", "focus"]:
			button.add_theme_stylebox_override(state, StyleBoxEmpty.new())
		button.mouse_entered.connect(_inspect_relic.bind(index))
		button.focus_entered.connect(_inspect_relic.bind(index))
		button.pressed.connect(_inspect_relic.bind(index))
		button.mouse_exited.connect(_leave_relic.bind(index))
		button.focus_exited.connect(_leave_relic.bind(index))
		button.visible = not DemoBuild.enabled()
		add_child(button)
		relic_buttons.append(button)

func sync(presentation: MoneyPresentation, amount: int, relics: Array[String], current_day: int, slot: int, requirement: int, campaign_days: Array[Dictionary]) -> void:
	money = presentation
	if day_index != current_day or event_slot != slot:
		_set_expanded(false)
	day_index = current_day
	event_slot = slot
	target = requirement
	days = campaign_days
	if balance != amount or cash_locale != TranslationServer.get_locale():
		cash_locale = TranslationServer.get_locale()
		balance = amount
		_rebuild_cash()
	if equipped != relics:
		inspect_card.hide()
		for button in relic_buttons:
			button.scale = Vector2.ONE
	equipped = relics.duplicate()
	for index in relic_buttons.size():
		var button := relic_buttons[index]
		var icon := button.get_node("RelicIcon") as TextureRect
		var occupied := index < equipped.size()
		icon.texture = load(RelicCatalog.icon_path(equipped[index])) if occupied else null
		(button.get_node("ContactShadow") as TextureRect).texture = icon.texture
		button.visible = occupied and not DemoBuild.enabled()
		button.text = ""
		button.tooltip_text = "" if occupied else words("Empty equipment slot. Visit Hàng Rong to equip an item.", "Ô vật phẩm trống. Ghé Hàng Rong để trang bị.")
	var signature := "%s:%s:%s:%s:%s:%s" % [day_index, event_slot, target, balance, days.size(), TranslationServer.get_locale()]
	if signature != journey_signature:
		journey_signature = signature
		_refresh_journey()

func _rebuild_cash() -> void:
	for child in cash_anchor.get_children():
		cash_anchor.remove_child(child)
		child.queue_free()
	if balance < 1000:
		_label(cash_anchor, words("No banknotes", "Chưa có tiền giấy"), Vector2.ZERO, cash_anchor.size, 17)
		return
	var breakdown := MoneyPresentation.denomination_breakdown(balance)
	for index in breakdown.size():
		var entry: Dictionary = breakdown[index]
		var bill := money._new_bill_stack(int(entry.denomination), int(entry.count), Vector2(155, 68))
		bill.position = Vector2((index % 2) * 89 + (index / 2) * 4, (index / 2) * 29)
		bill.rotation = deg_to_rad(-12 + (index * 7) % 23)
		# A close silhouette anchors the notes to the plastic surface.
		var shadow := TextureRect.new()
		shadow.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		shadow.texture = money._texture_for(int(entry.denomination))
		shadow.position = Vector2(3, 5)
		shadow.size = bill.size
		shadow.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		shadow.modulate = Color(0, 0, 0, 0.45)
		shadow.mouse_filter = Control.MOUSE_FILTER_IGNORE
		bill.add_child(shadow)
		bill.move_child(shadow, 0)
		# Count badges belong to inspection, not to physical paper on the table.
		for child in bill.get_children():
			if child is Label:
				child.hide()
		cash_anchor.add_child(bill)

func _refresh_journey() -> void:
	journey_button.text = words("DAY %d · JOURNEY", "NGÀY %d · HÀNH TRÌNH") % (day_index + 1) + ("  −" if expanded else "  +")
	objective.text = words("Tonight's debt: %s  ·  %s", "Nợ tối nay: %s  ·  %s") % [VndWallet.format_vnd(target), words("READY", "ĐỦ TIỀN") if balance >= target else words("Need ", "Còn thiếu ") + VndWallet.format_vnd(maxi(target - balance, 0))]
	progress.value = clampf(float(balance) / maxi(target, 1) * 100.0, 0, 100)
	for child in week.get_children():
		week.remove_child(child)
		child.queue_free()
	var first_day := clampi(day_index - 3, 0, maxi(days.size() - 7, 0))
	for index in range(first_day, mini(first_day + 7, days.size())):
		var button := Button.new()
		button.custom_minimum_size = Vector2(78, 28)
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.text = ("● " if index == day_index else "") + str(index + 1)
		if index < day_index:
			var completed_icon := CardSymbolArtScript.create_meld_icon(Vector2(14, 14), Color.WHITE)
			completed_icon.position = Vector2(7, 7)
			button.add_child(completed_icon)
		button.tooltip_text = tr(String(days[index].name_key)) + " · " + VndWallet.format_vnd(int(days[index].required_vnd))
		button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		button.pressed.connect(_preview_day.bind(index))
		week.add_child(button)
	_preview_day(day_index, false)
	for child in timeline.get_children():
		timeline.remove_child(child)
		child.queue_free()
	var labels := [
		words("START · EVENT", "MỞ ĐẦU · SỰ KIỆN"),
		words("MORNING · DEAL", "SÁNG · VÁN BÀI"),
		words("MORNING · EVENT", "SÁNG · SỰ KIỆN"),
		words("NOON · DEAL", "TRƯA · VÁN BÀI"),
		words("NOON · EVENT", "TRƯA · SỰ KIỆN"),
		words("AFTERNOON · DEAL", "CHIỀU · VÁN BÀI"),
		words("AFTERNOON · EVENT", "CHIỀU · SỰ KIỆN"),
		words("EVENING · DEAL", "TỐI · VÁN BÀI"),
		words("NIGHT · PAY DEBT", "CUỐI NGÀY · TRẢ NỢ"),
	]
	var current_step := event_slot * 2
	for index in labels.size():
		var step := Label.new()
		step.custom_minimum_size = Vector2(198, 39)
		step.text = "%02d  %s" % [index + 1, labels[index]]
		if index == current_step:
			step.text += "\n" + words("YOU ARE HERE", "BẠN ĐANG Ở ĐÂY")
		step.add_theme_font_size_override("font_size", 13)
		step.add_theme_color_override("font_color", Color("#f6c442") if index == current_step else Color("#c2d4ba") if index < current_step else Color("#7e8e85"))
		timeline.add_child(step)

func _preview_day(index: int, open: bool = true) -> void:
	if index < 0 or index >= days.size():
		return
	if open:
		_set_expanded(true)
		journey_button.text = words("DAY %d · JOURNEY", "NGÀY %d · HÀNH TRÌNH") % (day_index + 1) + "  −"
	var day: Dictionary = days[index]
	detail_copy.text = words("DAY %d · %s", "NGÀY %d · %s") % [index + 1, tr(String(day.name_key)).to_upper()]
	detail_copy.text += "\n" + words("Debt due at night: ", "Nợ phải trả tối nay: ") + VndWallet.format_vnd(int(day.required_vnd))
	detail_copy.text += "\n" + (words("YOU ARE HERE · ", "BẠN ĐANG Ở ĐÂY · ") + tr(EventManager.slot_name_key(event_slot)) if index == day_index else words("Completed day", "Ngày đã qua") if index < day_index else words("Upcoming day", "Ngày sắp tới"))
	if index != day_index:
		detail_copy.text += "\n" + words("TODAY · DAY %d · ", "HÔM NAY · NGÀY %d · ") % (day_index + 1) + tr(EventManager.slot_name_key(event_slot))

func _show_effect(copy: String) -> void:
	inspect_copy.text = copy
	inspect_card.show()

func _inspect_relic(index: int) -> void:
	if index >= equipped.size():
		_show_effect(words("EMPTY SLOT\nVisit Hàng Rong to equip an item.", "Ô TRỐNG\nGhé Hàng Rong để trang bị vật phẩm."))
		return
	var id := equipped[index]
	_lift_relic(index, true)
	_show_effect(String(RelicCatalog.DEFINITIONS[id].name) + "\n" + RelicCatalog.effect(id))

func _leave_relic(index: int) -> void:
	_lift_relic(index, false)
	inspect_card.hide()

func _lift_relic(index: int, lifted: bool) -> void:
	var previous = object_tweens.get(index)
	if previous != null and previous.is_valid():
		previous.kill()
	var tween := create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	object_tweens[index] = tween
	tween.tween_property(relic_buttons[index], "scale", Vector2.ONE * (1.06 if lifted else 1.0), 0.14)

func set_focused(focused: bool) -> void:
	visible = not focused
	if focused:
		expanded = false
		journey_detail.hide()
		inspect_card.hide()
