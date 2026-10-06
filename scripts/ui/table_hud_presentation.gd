extends Node
## Coordinates the read-only day/objective display and the table's glass surfaces.
var host: MatchUI
var day: Label
var goal: Label
var progress: ProgressBar
var history: PanelContainer

static func glass(accent: Color = Color("94774d"), opacity: float = 0.72) -> StyleBoxFlat:
	return PresentationTheme.panel_style(Color(0.055, 0.08, 0.12, opacity), Color(accent, 0.7), 1, 5, 2)

func configure(owner: MatchUI) -> void:
	host = owner
	name = "TableHUDPresentation"
	var stat := host.get_node("GameLayer/Header/HeaderRow/CampaignStat") as PanelContainer
	stat.custom_minimum_size = Vector2(250, 54)
	stat.add_theme_stylebox_override("panel", glass(PresentationTheme.GOLD_DARK))
	var column := host.campaign_value.get_parent() as VBoxContainer
	column.add_theme_constant_override("separation", 2)
	# Reuse the period icon and live values, with one clear day/period heading.
	day = host.header_caption_labels["CampaignStat"]
	var heading := HBoxContainer.new()
	heading.name = "DayAndPeriod"
	heading.add_theme_constant_override("separation", 8)
	column.add_child(heading)
	column.move_child(heading, 0)
	day.reparent(heading)
	day.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	day.autowrap_mode = TextServer.AUTOWRAP_OFF
	day.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	PresentationTheme.style_text(day, &"body", 14)
	host.campaign_period_value.reparent(heading)
	host.campaign_period_value.custom_minimum_size.x = 64
	host.campaign_period_value.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	PresentationTheme.style_text(host.campaign_period_value, &"muted", 12)
	host.campaign_period_icon.custom_minimum_size = Vector2(36, 36)
	goal = host.campaign_value
	PresentationTheme.style_text(goal, &"number", 13)
	progress = ProgressBar.new()
	progress.name = "DailyObjectiveProgress"
	progress.custom_minimum_size = Vector2(0, 3)
	progress.show_percentage = false
	progress.mouse_filter = Control.MOUSE_FILTER_IGNORE
	progress.add_theme_stylebox_override("background", PresentationTheme.panel_style(Color("ffffff18")))
	progress.add_theme_stylebox_override("fill", PresentationTheme.panel_style(Color("d8b772b0")))
	column.add_child(progress)
	for panel: PanelContainer in [host.campaign_money_hud.rate_panel, host.campaign_money_hud.income_panel, host.campaign_money_hud.panel]:
		panel.add_theme_stylebox_override("panel", glass())
	var dock := host.get_node("GameLayer/ActionDock") as Panel
	dock.add_theme_stylebox_override("panel", glass())
	# Notices sit in the left seat margin, away from cards and the turn register.
	host.banner_panel.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
	host.banner_panel.custom_minimum_size = Vector2(148, 0)
	host.banner_panel.size = Vector2(148, 48)
	var notice_style := glass(Color("6985a0"), 0.78)
	notice_style.content_margin_left = 8
	notice_style.content_margin_right = 8
	notice_style.content_margin_top = 6
	notice_style.content_margin_bottom = 6
	host.banner_panel.add_theme_stylebox_override("panel", notice_style)
	host.banner_label.custom_minimum_size.x = 130
	host.banner_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	host.banner_label.max_lines_visible = 6
	host.banner_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	host.banner_label.add_theme_font_size_override("font_size", 12)
	# Keep hover, selection, keyboard focus and disabled cues opaque and legible.
	for button: Button in [host.menu_button, host.hint_button, host.sort_button, host.ha_button, host.extend_button, host.discard_button, host.settle_button]:
		for state in ["normal", "hover", "pressed", "disabled"]:
			var style := button.get_theme_stylebox(state).duplicate() as StyleBoxFlat
			if style == null: continue
			style.bg_color.a = 0.76 if state == "normal" else 0.68 if state == "disabled" else 0.94
			style.shadow_size = 1
			button.add_theme_stylebox_override(state, style)
	for caption: Label in host.pile_caption_labels.values():
		caption.add_theme_stylebox_override("normal", glass())
	for count: Label in [host.draw_count, host.discard_count_label, host.drink_name_label]:
		count.add_theme_stylebox_override("normal", glass())
	host.empty_meld_label.modulate.a = 0.6
	history = host.get_node("GameLayer/TableSurface/DiscardHistoryHUD")
	history.add_theme_stylebox_override("panel", glass(Color("6985a0"), 0.6))
	history.mouse_filter = Control.MOUSE_FILTER_IGNORE
	host.discard_history_title.add_theme_font_size_override("font_size", 10)
	host.discard_history_title.add_theme_color_override("font_color", PresentationTheme.MUTED)
	host.discard_history_row.add_theme_constant_override("separation", 7)
	host.get_viewport().size_changed.connect(_layout.call_deferred)
	_layout.call_deferred()
	refresh()

func refresh() -> void:
	if host.campaign == null: return
	day.text = CampaignText.day_name(host.campaign) if not host.campaign.current_day().is_empty() else "—"
	goal.text = ZodiacCatalog.words("Goal ", "Mục tiêu ") + VndWallet.format_vnd(host.campaign.daily_requirement()) if not host.campaign.current_day().is_empty() else "—"
	progress.value = clampf(float(host.deal.wallet.balance_vnd) / maxf(host.campaign.daily_requirement(), 1) * 100.0, 0, 100)
	goal.tooltip_text = "%s / %s" % [VndWallet.format_vnd(host.deal.wallet.balance_vnd), VndWallet.format_vnd(host.campaign.daily_requirement())]

func _layout() -> void:
	if not is_instance_valid(history): return
	var width := minf(448, host.table_surface.size.x - 32)
	history.offset_left = -width * 0.5
	history.offset_right = width * 0.5
	# Leave a gap above the hand at shorter window heights as well.
	var hand_top: float = host.hand_layer.get_parent().position.y
	history.offset_top = minf(296, hand_top - host.table_surface.position.y - 98)
	history.offset_bottom = history.offset_top + 88
	# Melds get their own space above the strip rather than extending behind it.
	host.meld_scroll.offset_bottom = history.offset_top - 10 - host.table_surface.size.y
	host.empty_meld_label.offset_bottom = host.meld_scroll.offset_bottom
