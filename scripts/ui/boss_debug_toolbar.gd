extends PanelContainer
## Visible reminder and replay controls while the isolated boss sandbox is active.
var host: MatchUI
var caption: Label
var localized_buttons: Array[Dictionary] = []

func configure(owner: MatchUI) -> void:
	host = owner
	name = "BossDebugToolbar"
	position = Vector2(348, 8)
	custom_minimum_size = Vector2(156, 54)
	add_theme_stylebox_override("panel", PresentationTheme.panel_style(Color("#172334f5"), Color("#f5bf42"), 2, 4, 6))
	var body := VBoxContainer.new()
	body.add_theme_constant_override("separation", 2)
	add_child(body)
	caption = Label.new()
	caption.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	caption.add_theme_font_size_override("font_size", 10)
	body.add_child(caption)
	var buttons := HBoxContainer.new()
	body.add_child(buttons)
	for spec in [["Replay", "Chơi lại", host.replay_boss_debug], ["Lab", "Chọn", host.open_boss_lab], ["Exit", "Thoát", host.leave_boss_debug]]:
		var button := Button.new()
		button.text = GameGlossary.words(spec[0], spec[1])
		button.custom_minimum_size = Vector2(48, 26)
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		PresentationTheme.configure_button(button)
		button.add_theme_font_size_override("font_size", 10)
		button.pressed.connect(spec[2])
		buttons.add_child(button)
		localized_buttons.append({"button": button, "en": spec[0], "vi": spec[1]})
	hide()

func _process(_delta: float) -> void:
	if host == null: return
	visible = host.session.debug_active and host.game_started and not host.menu_layer.visible
	if not visible: return
	for item: Dictionary in localized_buttons: item.button.text = GameGlossary.words(item.en, item.vi)
	var options: Dictionary = host.campaign.debug_context.get("options", {})
	caption.text = GameGlossary.words("DEBUG · %s · P%d", "THỬ · %s · H%d") % [ZodiacCatalog.display_name(options.get("boss", "")), host.deal.current_phase]
	tooltip_text = GameGlossary.words("DEBUG SANDBOX · %s · %s", "THỬ NGHIỆM · %s · %s") % [ZodiacCatalog.display_name(options.get("boss", "")), ZodiacCatalog.disposition_label(ZodiacCatalog.difficulty_name(host.deal.zodiac_boss.difficulty))]
	# Keep the sandbox reminder in the header; a wrapped caption used to extend
	# downward over the compact boss panel after it moved below DAY.
	var day: Control = host.get_node("GameLayer/Header/HeaderRow/CampaignStat")
	position = Vector2(day.get_global_rect().end.x + 8, day.global_position.y) - get_parent().global_position
	size = get_combined_minimum_size()
