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
	add_child(body)
	caption = Label.new()
	caption.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	caption.add_theme_font_size_override("font_size", 10)
	body.add_child(caption)
	var buttons := HBoxContainer.new()
	body.add_child(buttons)
	for spec in [["Replay", "Chơi lại", host.replay_boss_debug], ["Boss Lab", "Chọn", host.open_boss_lab], ["Exit", "Thoát", host.leave_boss_debug]]:
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
	caption.text = GameGlossary.words("DEBUG SANDBOX · %s\nPhase %d · %s", "THỬ NGHIỆM · %s\nHiệp %d · %s") % [ZodiacCatalog.display_name(options.get("boss", "")), host.deal.current_phase, ZodiacCatalog.disposition_label(ZodiacCatalog.difficulty_name(host.deal.zodiac_boss.difficulty))]
