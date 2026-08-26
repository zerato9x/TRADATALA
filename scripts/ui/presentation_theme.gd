class_name PresentationTheme
extends RefCounted

const INK := Color("#f5eddc")
const MUTED := Color("#a8b3a7")
const TABLE_DARK := Color("#071b19")
const TABLE := Color("#0d302a")
const TABLE_LIGHT := Color("#17473a")
const PANEL := Color("#102723e8")
const PANEL_SOLID := Color("#102723")
const PANEL_LIGHT := Color("#193a32")
const GOLD := Color("#f1c56f")
const GOLD_DARK := Color("#8d672b")
const TEA := Color("#6ed8a4")
const RED := Color("#ee6d62")
const SHADOW := Color("#020b09a6")


static func panel_style(
	background: Color = PANEL,
	border: Color = Color.TRANSPARENT,
	border_width: int = 0,
	radius: int = 12,
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
	style.anti_aliasing = true
	if shadow_size > 0:
		style.shadow_color = SHADOW
		style.shadow_size = shadow_size
		style.shadow_offset = Vector2(0, 3)
	return style


static func configure_button(button: Button, tone: String = "neutral") -> void:
	var base := PANEL_LIGHT
	var hover := Color("#245044")
	var border := Color("#3b6257")
	var font_color := INK
	if tone == "gold":
		base = Color("#ad7830")
		hover = Color("#cf9844")
		border = GOLD
		font_color = Color("#fff7df")
	elif tone == "tea":
		base = Color("#267354")
		hover = Color("#32966b")
		border = TEA
	elif tone == "danger":
		base = Color("#71352f")
		hover = Color("#98483f")
		border = RED
	button.add_theme_stylebox_override("normal", panel_style(base, border, 1, 9, 2))
	button.add_theme_stylebox_override("hover", panel_style(hover, border.lightened(0.15), 2, 9, 3))
	button.add_theme_stylebox_override("pressed", panel_style(base.darkened(0.18), border, 1, 9, 0))
	button.add_theme_stylebox_override("disabled", panel_style(Color("#17231f"), Color("#293c35"), 1, 9, 0))
	button.add_theme_stylebox_override("focus", panel_style(Color.TRANSPARENT, GOLD, 2, 9, 0))
	button.add_theme_color_override("font_color", font_color)
	button.add_theme_color_override("font_hover_color", Color.WHITE)
	button.add_theme_color_override("font_pressed_color", Color.WHITE)
	button.add_theme_color_override("font_disabled_color", Color("#65726c"))
	button.add_theme_font_size_override("font_size", 13)
	button.focus_mode = Control.FOCUS_ALL
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND

