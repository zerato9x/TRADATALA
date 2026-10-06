class_name CardInspection
extends RefCounted
## Shared, read-only inspection. Exact Fortune is prominent; normal faces stay clean.
static func tooltip(card: CardData) -> Control:
	var panel := PanelContainer.new()
	panel.name = "CardFortuneTooltip"
	panel.add_theme_stylebox_override("panel", PresentationTheme.panel_style(Color("15242df8"), Color("b69559"), 1, 5, 14))
	var column := VBoxContainer.new()
	column.custom_minimum_size.x = 180
	column.add_theme_constant_override("separation", 6)
	panel.add_child(column)
	column.add_child(CardSymbolArt.create_card_badge(card, 24))
	var suit := Label.new()
	suit.text = TranslationServer.translate("SUIT_" + card.suit.to_upper())
	suit.add_theme_font_size_override("font_size", 15)
	suit.add_theme_color_override("font_color", PresentationTheme.MUTED)
	column.add_child(suit)
	var caption := Label.new()
	caption.text = TranslationServer.translate("CARD_FORTUNE")
	caption.add_theme_font_size_override("font_size", 14)
	column.add_child(caption)
	var fortune := Label.new()
	fortune.name = "SignedFortune"
	fortune.text = card.fortune_label()
	fortune.add_theme_font_size_override("font_size", 38)
	fortune.add_theme_color_override("font_color", PresentationTheme.GOLD if card.fortune > 0 else Color("c8dce6") if card.fortune < 0 else PresentationTheme.MUTED)
	column.add_child(fortune)
	if not card.jackpot_state().is_empty():
		var jackpot := Label.new()
		jackpot.text = TranslationServer.translate(CardData.property_label_key(card.jackpot_state()))
		jackpot.add_theme_color_override("font_color", PresentationTheme.SPEAKER)
		column.add_child(jackpot)
	_ignore_input(panel)
	return panel


static func _ignore_input(node: Node) -> void:
	if node is Control:
		node.mouse_filter = Control.MOUSE_FILTER_IGNORE
		node.focus_mode = Control.FOCUS_NONE
	for child in node.get_children(): _ignore_input(child)
