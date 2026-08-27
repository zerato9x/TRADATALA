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

static var _official_font: Font


static func official_font() -> Font:
	if _official_font == null:
		_official_font = load(OFFICIAL_FONT_PATH) as Font
	return _official_font


static func create_game_theme() -> Theme:
	var game_theme := Theme.new()
	game_theme.default_font = official_font()
	game_theme.default_font_size = 14
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
	button.add_theme_color_override("font_disabled_color", Color("#776e5d"))
	button.add_theme_font_size_override("font_size", 13)
	button.focus_mode = Control.FOCUS_ALL
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND

