extends CanvasLayer
## A single physical wallet; flights observe committed journal events only.
var host: MatchUI
var panel: Control
var income_panel: Control
var rate_panel: Control
var flights: Control
var last_transfer: Dictionary = {}
func configure(ui: MatchUI) -> void:
	host = ui
	layer = 245
	panel = host.wallet_pile_anchor.get_parent().get_parent().get_parent()
	panel.theme = PresentationTheme.create_game_theme()
	_split_currency(host.wallet_value, &"wallet")
	income_panel = host.earnings_value.get_parent().get_parent().get_parent()
	income_panel.theme = panel.theme
	_split_currency(host.earnings_value, &"gain")
	PresentationTheme.style_text(host.header_caption_labels["IncomeStat"], &"muted", 12)
	PresentationTheme.style_text(host.header_caption_labels["WalletStat"], &"muted", 12)
	rate_panel = host.vnd_per_point_value.get_parent().get_parent().get_parent()
	rate_panel.theme = panel.theme
	var bounds := Control.new()
	bounds.name = "HudBounds"
	bounds.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bounds)
	bounds.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var row := HBoxContainer.new()
	row.name = "MoneyStats"
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_theme_constant_override("separation", 12)
	bounds.add_child(row)
	row.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	# Reserve the help button's 44-pixel inset plus a ten-pixel gap.
	row.offset_left = -764
	row.offset_right = -54
	row.offset_top = 6
	row.offset_bottom = 72
	for stat: Control in [rate_panel, income_panel, panel]:
		stat.reparent(row, false)
		stat.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
		stat.size_flags_vertical = Control.SIZE_FILL
	rate_panel.custom_minimum_size.x = 120
	income_panel.custom_minimum_size.x = 250
	panel.custom_minimum_size.x = 316
	flights = Control.new()
	flights.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(flights)
	host.deal.wallet.balance_changed.connect(_on_balance_changed)

func _process(_delta: float) -> void:
	if is_instance_valid(host):
		var event_overview := host.current_campaign_event != null and host.event_table.focused_npc_id.is_empty() and not host.event_table.deck_focused
		panel.visible = host.game_started and not host.menu_layer.visible and not event_overview
		income_panel.visible = panel.visible
		rate_panel.visible = panel.visible
		_fit_amount(host.wallet_value)
		_fit_amount(host.earnings_value)

func _split_currency(value: Label, role: StringName) -> void:
	var column := value.get_parent()
	var row := HBoxContainer.new()
	row.name = "MoneyAmountRow"
	row.add_theme_constant_override("separation", 8)
	column.add_child(row)
	value.reparent(row)
	value.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	value.mouse_filter = Control.MOUSE_FILTER_IGNORE
	PresentationTheme.style_text(value, role, 30)
	var unit := Label.new()
	unit.name = "CurrencyUnit"
	unit.text = "VNĐ"
	unit.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
	unit.mouse_filter = Control.MOUSE_FILTER_IGNORE
	PresentationTheme.style_text(unit, &"muted", 14)
	row.add_child(unit)

func _fit_amount(value: Label) -> void:
	var font := value.get_theme_font("font")
	var pixels := 30
	while pixels > 18 and font.get_string_size(value.text, HORIZONTAL_ALIGNMENT_LEFT, -1, pixels).x > value.size.x:
		pixels -= 1
	if value.get_theme_font_size("font_size") != pixels:
		value.add_theme_font_size_override("font_size", pixels)

func _on_balance_changed(_previous: int, current: int, delta: int, reason: String) -> void:
	if reason == "reset":
		last_transfer.clear()
		for child in flights.get_children(): child.queue_free()
		host.money_presentation.sync_wallet(current)
		host.displayed_wallet_vnd = current
		return
	if delta == 0:
		return
	_present_transfer(delta, reason)
	if last_transfer.get("reason", "") == reason:
		host.displayed_wallet_vnd = current
		host.money_queue_wallet_vnd = current
		host.money_presentation.sync_wallet(current)

func _present_transfer(delta: int, reason: String) -> void:
	var npc := ""
	if reason == "drink_purchase": npc = EventTableController.NPC_TRA_DA
	elif reason.begins_with("relic_purchase:") or reason == "relic_reroll": npc = EventTableController.NPC_HANG_RONG
	elif reason == "gieo_que_cast": npc = EventTableController.NPC_THAY_BOI
	elif reason in ["shoe_polish", "shoe_tip"]: npc = EventTableController.NPC_DANH_GIAY
	elif reason in ["lottery_ticket", "lottery_settlement"]: npc = EventTableController.NPC_LOTTO
	elif reason == "daily_debt": npc = EventTableController.NPC_DOI_NO
	if npc.is_empty():
		return # Gameplay scoring already flies into this same wallet anchor.
	var source := host.wallet_pile_anchor.get_global_rect().get_center()
	var destination := Vector2(1080, 390)
	if host.event_table._npc_layers.has(npc):
		var sprite: Control = host.event_table._npc_layers[npc].sprite
		if sprite.is_visible_in_tree(): destination = sprite.get_global_rect().get_center()
	if reason == "daily_debt" and is_instance_valid(host.resolve_receipt):
		destination = host.resolve_receipt.portrait.get_global_rect().get_center()
	if delta > 0:
		var swap := source
		source = destination
		destination = swap
	last_transfer = {"reason": reason, "from": source, "to": destination, "amount": delta, "committed_balance": host.deal.wallet.balance_vnd, "journal_size": host.deal.wallet.journal.size()}
	var badge := Label.new()
	badge.text = VndWallet.format_vnd(delta, true)
	badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	PresentationTheme.style_text(badge, &"gain" if delta > 0 else &"cost", 24 if absi(delta) >= 100000 else 20)
	badge.add_theme_color_override("font_outline_color", PresentationTheme.PANEL_SOLID)
	badge.add_theme_constant_override("outline_size", 5)
	badge.position = Vector2(clampf(destination.x - 100, 16, 1040), clampf(destination.y - 48, 62, 620))
	flights.add_child(badge)
	var feedback := badge.create_tween()
	feedback.tween_property(badge, "position:y", badge.position.y - 12, 0.65)
	feedback.tween_property(badge, "modulate:a", 0.0, 0.2)
	feedback.tween_callback(badge.queue_free)
	var breakdown := MoneyPresentation.denomination_breakdown(absi(delta))
	for index in mini(breakdown.size(), 8):
		var bill := TextureRect.new()
		bill.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		bill.texture = MoneyPresentation.DENOMINATION_TEXTURES.get(int(breakdown[index].denomination), MoneyPresentation.DENOMINATION_TEXTURES[1000])
		bill.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		bill.size = Vector2(76, 34)
		bill.mouse_filter = Control.MOUSE_FILTER_IGNORE
		flights.add_child(bill)
		bill.position = source - bill.size * 0.5
		var tween := bill.create_tween()
		tween.tween_interval(index * 0.045)
		tween.tween_method(func(t: float):
			bill.position = source.lerp(destination, t) - bill.size * 0.5 + Vector2(0, -sin(t * PI) * 95)
			bill.rotation = sin(t * PI) * 0.18
		, 0.0, 1.0, 0.65)
		tween.tween_property(bill, "modulate:a", 0.0, 0.12)
		tween.tween_callback(bill.queue_free)
