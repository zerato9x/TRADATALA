class_name PresentationTheme
extends RefCounted

const OFFICIAL_FONT_PATH := "res://assets/DFVN Pexel Grotesk.ttf"

const INK := Color("#f8edcf")
const MUTED := Color("#c6b896")
const TABLE_DARK := Color("#13100d")
const TABLE := Color("#203f77")
const TABLE_LIGHT := Color("#2f66b8")
const PANEL := Color("#1a1512ed")
const PANEL_SOLID := Color("#17120f")
const PANEL_LIGHT := Color("#30251d")
const GOLD := Color("#f5bf42")
const GOLD_DARK := Color("#7c4a25")
const TEA := Color("#79c843")
const RED := Color("#d85b4e")
const SHADOW := Color("#050302bd")

# Meaning, not panel identity. Dark-surface colors; paper variants below.
const MONEY_GAIN := Color("#9be3aa")
const MONEY_COST := Color("#ffaaa0")
const WALLET := Color("#ffe099")
const DEBT := Color("#ffc18c")
const ACTION := Color("#8fe7ff")
const SPEAKER := Color("#d9b6ff")
const WARNING := Color("#ffd080")
const DANGER := Color("#ffaaa0")
const PAPER_INK := Color("#24354c")
const PAPER_MUTED := Color("#515c6d")
const PAPER_GAIN := Color("#286141")
const PAPER_COST := Color("#983b34")
const PAPER_SEMANTIC_COLORS := {&"body": PAPER_INK, &"muted": PAPER_MUTED, &"gain": PAPER_GAIN, &"success": PAPER_GAIN,
	&"cost": PAPER_COST, &"debt": PAPER_COST, &"danger": PAPER_COST, &"wallet": Color("80550b"), &"number": Color("80550b"),
	&"heading": Color("80550b"), &"jackpot": Color("80550b"), &"warning": Color("88571d"),
	&"action": Color("165570"), &"card": Color("165570"), &"speaker": Color("654082"), &"mechanic": Color("654082")}
const SUIT_COLORS := {"Spades": Color("8fcfff"), "Hearts": Color("ff929f"), "Diamonds": Color("ffd477"), "Clubs": Color("8ee0b2")}
const ZODIAC_COLORS := {"rooster": Color("ff8576"), "cat": Color("c294ff"), "dog": Color("80f5a1"), "monkey": Color("ffe078"),
	"pig": Color("ffb5ca"), "ox": Color("deb17a"), "horse": Color("81d6ff"), "goat": Color("9ce5d7"),
	"rat": Color("c4bbef"), "tiger": Color("ff9e55"), "snake": Color("a7ed8e"), "dragon": Color("86e5f0")}
const SEMANTIC_COLORS := {
	&"body": INK, &"muted": MUTED, &"gain": MONEY_GAIN,
	&"cost": MONEY_COST, &"wallet": WALLET, &"debt": DEBT,
	&"number": WALLET, &"card": ACTION, &"action": ACTION,
	&"success": MONEY_GAIN, &"warning": WARNING, &"danger": DANGER,
	&"speaker": SPEAKER, &"mechanic": SPEAKER, &"jackpot": WALLET, &"heading": WALLET,
}

static func semantic_color(role: StringName, paper: bool = false) -> Color:
	return PAPER_SEMANTIC_COLORS.get(role, PAPER_INK) if paper else SEMANTIC_COLORS.get(role, INK)

static func zodiac_color(id: String) -> Color:
	return ZODIAC_COLORS.get(id, SPEAKER)

static func suit_color(suit: String) -> Color:
	return SUIT_COLORS.get(suit, ACTION)

static func style_text(control: Control, role: StringName = &"body", font_size: int = 18) -> void:
	control.set_meta("text_role", role)
	control.add_theme_color_override("default_color" if control is RichTextLabel else "font_color", semantic_color(role))
	control.add_theme_font_size_override("normal_font_size" if control is RichTextLabel else "font_size", font_size)

static func emphasis(text: String, role: StringName) -> String:
	return "[color=#%s][b]%s[/b][/color]" % [semantic_color(role).to_html(false), text.replace("[", "[lb]")]

static func emphasize_money(text: String, role: StringName = &"number") -> String:
	var pattern := RegEx.new()
	pattern.compile("[+−-]?[0-9][0-9.,]* VNĐ")
	var result := ""
	var cursor := 0
	for found in pattern.search_all(text):
		result += text.substr(cursor, found.get_start() - cursor)
		var token := found.get_string()
		var meaning: StringName = &"gain" if token.begins_with("+") else &"cost" if token.begins_with("−") or token.begins_with("-") else role
		result += emphasis(token, meaning)
		cursor = found.get_end()
	return result + text.substr(cursor)

static var _official_font: Font


static func official_font() -> Font:
	if _official_font == null:
		_official_font = load(OFFICIAL_FONT_PATH) as Font
		# Ship the engine font fallback too: browser exports have no system fonts.
		_official_font.fallbacks = [ThemeDB.fallback_font]
	return _official_font


static func create_game_theme() -> Theme:
	var game_theme := Theme.new()
	game_theme.default_font = official_font()
	game_theme.default_font_size = 16
	game_theme.set_color("font_color", "Label", INK)
	game_theme.set_color("default_color", "RichTextLabel", INK)
	game_theme.set_color("font_disabled_color", "Button", MUTED)
	game_theme.set_color("font_color", "Button", ACTION)
	game_theme.set_font_size("normal_font_size", "RichTextLabel", 16)
	# Keep form controls legible on the same dark surfaces as the game panels.
	for control_type in ["LineEdit", "OptionButton"]:
		game_theme.set_color("font_color", control_type, INK)
		game_theme.set_color("font_placeholder_color", control_type, MUTED)
		game_theme.set_color("font_disabled_color", control_type, MUTED)
		game_theme.set_font_size("font_size", control_type, 17)
		for state in ["normal", "hover", "pressed", "read_only", "disabled", "focus"]:
			var color := Color("#142435") if state != "hover" else Color("#263f57")
			var outline := GOLD if state == "focus" else Color("#6884a1")
			var form_style := panel_style(Color.TRANSPARENT if state == "focus" else color, outline, 2 if state == "focus" else 1, 2)
			form_style.content_margin_left = 12
			form_style.content_margin_right = 16
			form_style.content_margin_top = 10
			form_style.content_margin_bottom = 10
			game_theme.set_stylebox(state, control_type, form_style)
	game_theme.set_stylebox("panel", "PopupMenu", panel_style(Color("#142435"), Color("#6884a1"), 1, 2, 4))
	game_theme.set_stylebox("hover", "PopupMenu", panel_style(Color("#34527a")))
	game_theme.set_color("font_color", "PopupMenu", INK)
	game_theme.set_color("font_hover_color", "PopupMenu", Color.WHITE)
	game_theme.set_font_size("font_size", "PopupMenu", 17)
	for bar_type in ["VScrollBar", "HScrollBar"]:
		for state in ["scroll", "grabber", "grabber_highlight", "grabber_pressed"]:
			var fill := Color("#101c29") if state == "scroll" else GOLD if state != "grabber" else Color("#6884a1")
			var bar := panel_style(fill, Color("#b3c8da") if state == "grabber" else Color.TRANSPARENT, 1 if state == "grabber" else 0, 2)
			for side in ["left", "right", "top", "bottom"]:
				bar.set("content_margin_" + side, 5.0)
			game_theme.set_stylebox(state, bar_type, bar)
	var track := panel_style(Color("#263f57"), Color("#6884a1"), 1, 2)
	track.content_margin_top = 4
	track.content_margin_bottom = 4
	game_theme.set_stylebox("slider", "HSlider", track)
	game_theme.set_stylebox("grabber_area", "HSlider", panel_style(TEA))
	game_theme.set_stylebox("grabber_area_highlight", "HSlider", panel_style(GOLD))
	var tooltip_style := panel_style(PANEL_SOLID, GOLD_DARK, 1, 3, 3)
	tooltip_style.content_margin_left = 12
	tooltip_style.content_margin_right = 12
	tooltip_style.content_margin_top = 8
	tooltip_style.content_margin_bottom = 8
	game_theme.set_stylebox("panel", "TooltipPanel", tooltip_style)
	game_theme.set_color("font_color", "TooltipLabel", INK)
	game_theme.set_font_size("font_size", "TooltipLabel", 14)
	return game_theme


static func panel_style(
	background: Color = PANEL,
	border: Color = Color.TRANSPARENT,
	border_width: int = 0,
	radius: int = 3,
	shadow_size: int = 0
) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = background
	style.border_color = border
	style.border_width_left = border_width
	style.border_width_top = border_width
	style.border_width_right = border_width
	style.border_width_bottom = border_width
	style.corner_radius_top_left = radius
	style.corner_radius_top_right = radius
	style.corner_radius_bottom_left = radius
	style.corner_radius_bottom_right = radius
	style.anti_aliasing = false
	if shadow_size > 0:
		style.shadow_color = SHADOW
		style.shadow_size = shadow_size
		style.shadow_offset = Vector2(0, 3)
	return style


static func configure_button(button: Button, tone: String = "neutral") -> void:
	var base := Color("#23494b")
	var hover := Color("#32605c")
	var border := Color("#73938a")
	var font_color := INK
	if tone == "gold":
		base = Color("#e2b35f")
		hover = Color("#f5ce7c")
		border = Color("#ffdda0")
		font_color = PAPER_INK
	elif tone == "tea":
		base = Color("#35664b")
		hover = Color("#448963")
		border = Color("#a1c985")
	elif tone == "danger":
		base = Color("#783f36")
		hover = Color("#a45642")
		border = Color("#d69373")
		font_color = DANGER
	button.set_meta("text_surface", &"paper" if tone == "gold" else &"dark")
	button.set_meta("text_role", &"danger" if tone == "danger" else &"body")
	button.add_theme_stylebox_override("normal", enamel_style(base, border))
	button.add_theme_stylebox_override("hover", enamel_style(hover, border.lightened(0.16)))
	var pressed := enamel_style(base.darkened(0.1), border)
	pressed.shadow_size = 0
	pressed.border_width_top = 3
	pressed.border_width_bottom = 2
	button.add_theme_stylebox_override("pressed", pressed)
	var disabled := enamel_style(Color("#aaa18a") if tone == "gold" else Color("#252f30"), Color("#606457"))
	disabled.shadow_size = 0
	button.add_theme_stylebox_override("disabled", disabled)
	var focus := panel_style(Color.TRANSPARENT, Color("#fff1c2"), 2, 3, 0)
	focus.expand_margin_left = 2
	focus.expand_margin_top = 2
	focus.expand_margin_right = 2
	focus.expand_margin_bottom = 2
	button.add_theme_stylebox_override("focus", focus)
	button.add_theme_color_override("font_color", font_color)
	button.add_theme_color_override("font_hover_color", font_color.lightened(0.12))
	button.add_theme_color_override("font_pressed_color", font_color)
	button.add_theme_color_override("font_disabled_color", MUTED)
	button.add_theme_font_size_override("font_size", 16)
	button.focus_mode = Control.FOCUS_ALL
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	if button.get_node_or_null("EnamelEdges") == null:
		var edges := preload("res://scripts/ui/enamel_button_fx.gd").new()
		edges.name = "EnamelEdges"
		edges.accent = PAPER_INK if tone == "gold" else GOLD
		button.add_child(edges)


static func enamel_style(background: Color, edge: Color) -> StyleBoxFlat:
	var style := panel_style(background, edge, 1, 3, 3)
	style.border_width_bottom = 4
	style.shadow_offset = Vector2(0, 3)
	style.content_margin_left = 10
	style.content_margin_right = 10
	# Compact help and boss controls share this style; their hit boxes must not grow.
	style.content_margin_top = 2
	style.content_margin_bottom = 2
	return style


static func paper_labels(root: Node) -> void:
	if root is Label or root is RichTextLabel:
		root.set_meta("text_surface", &"paper")
	for child in root.get_children(): paper_labels(child)

