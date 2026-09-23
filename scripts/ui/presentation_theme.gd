class_name PresentationTheme
extends RefCounted

const OFFICIAL_FONT_PATH := "res://assets/DFVN Pexel Grotesk.ttf"
const UNIVERSAL_FRAME_STYLE := preload("res://assets/ui/frames/universal_frame.tres")

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
const SEMANTIC_COLORS := {
	&"body": INK, &"muted": MUTED, &"gain": MONEY_GAIN,
	&"cost": MONEY_COST, &"wallet": WALLET, &"debt": DEBT,
	&"number": WALLET, &"card": ACTION, &"action": ACTION,
	&"success": MONEY_GAIN, &"warning": WARNING, &"danger": DANGER,
	&"speaker": SPEAKER, &"mechanic": SPEAKER, &"jackpot": WALLET,
}

static func semantic_color(role: StringName) -> Color:
	return SEMANTIC_COLORS.get(role, INK)

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
	var tooltip_style := panel_style(PANEL_SOLID, GOLD_DARK, 1, 3, 3)
	tooltip_style.content_margin_left = 12
	tooltip_style.content_margin_right = 12
	tooltip_style.content_margin_top = 8
	tooltip_style.content_margin_bottom = 8
	game_theme.set_stylebox("panel", "TooltipPanel", tooltip_style)
	game_theme.set_color("font_color", "TooltipLabel", INK)
	game_theme.set_font_size("font_size", "TooltipLabel", 14)
	return game_theme


static func universal_frame_style() -> StyleBoxTexture:
	# Duplicate the shared resource so callers can tune margins without changing every frame.
	return UNIVERSAL_FRAME_STYLE.duplicate() as StyleBoxTexture


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
	var base := Color("#263853")
	var hover := Color("#34527a")
	var border := Color("#6e8fb5")
	var font_color := INK
	if tone == "gold":
		base = Color("#9a641f")
		hover = Color("#bf8428")
		border = GOLD
		font_color = Color("#fff1c5")
	elif tone == "tea":
		base = Color("#3d702d")
		hover = Color("#57933a")
		border = TEA
	elif tone == "danger":
		base = Color("#71372e")
		hover = Color("#99493c")
		border = RED
	button.add_theme_stylebox_override("normal", panel_style(base, border, 2, 2, 3))
	button.add_theme_stylebox_override("hover", panel_style(hover, border.lightened(0.15), 2, 2, 4))
	button.add_theme_stylebox_override("pressed", panel_style(base.darkened(0.18), border, 2, 2, 0))
	button.add_theme_stylebox_override("disabled", panel_style(Color("#26231f"), Color("#51483b"), 1, 2, 0))
	button.add_theme_stylebox_override("focus", panel_style(Color.TRANSPARENT, GOLD, 2, 2, 0))
	button.add_theme_color_override("font_color", font_color)
	button.add_theme_color_override("font_hover_color", Color.WHITE)
	button.add_theme_color_override("font_pressed_color", Color.WHITE)
	button.add_theme_color_override("font_disabled_color", MUTED)
	button.add_theme_font_size_override("font_size", 16)
	button.focus_mode = Control.FOCUS_ALL
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND

