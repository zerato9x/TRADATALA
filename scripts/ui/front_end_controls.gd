extends RefCounted
## Native form controls retain input, signals and accessibility behavior.

static func slider(control: HSlider) -> void:
	control.custom_minimum_size = Vector2(180, 44)
	control.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	var track := PresentationTheme.panel_style(Color("091d21"), Color("52746d"), 1, 3)
	track.content_margin_top = 4
	track.content_margin_bottom = 4
	control.add_theme_stylebox_override("slider", track)
	control.add_theme_stylebox_override("grabber_area", PresentationTheme.panel_style(Color("b79552"), Color.TRANSPARENT, 0, 3))
	control.add_theme_stylebox_override("grabber_area_highlight", PresentationTheme.panel_style(PresentationTheme.GOLD, Color.TRANSPARENT, 0, 3))
	for state in ["grabber", "grabber_highlight", "grabber_disabled"]:
		control.add_theme_icon_override(state, preload("res://assets/ui/controls/slider-knob.svg"))

static func toggle(control: CheckButton) -> void:
	PresentationTheme.configure_button(control)
	control.custom_minimum_size.y = 54
	control.add_theme_font_size_override("font_size", 17)
	control.add_theme_constant_override("h_separation", 16)
	control.add_theme_icon_override("checked", preload("res://assets/ui/controls/switch-on.svg"))
	control.add_theme_icon_override("unchecked", preload("res://assets/ui/controls/switch-off.svg"))
	control.add_theme_stylebox_override("pressed", PresentationTheme.enamel_style(Color("284c3d"), Color("8ba681")))
	control.add_theme_stylebox_override("hover_pressed", PresentationTheme.enamel_style(Color("35664b"), Color("a1c985")))

static func file_card(body: VBoxContainer, active: bool, damaged: bool) -> void:
	var panel := body.get_parent().get_parent() as PanelContainer
	var accent := PresentationTheme.DANGER if damaged else PresentationTheme.MONEY_GAIN if active else Color("ae9569")
	var surface := PresentationTheme.panel_style(Color("193e36") if active else Color("142d30f5"), accent, 1, 4, 6)
	surface.border_width_top = 4
	surface.border_width_bottom = 3
	panel.add_theme_stylebox_override("panel", surface)

static func stat(body: VBoxContainer, caption: Label, value: Label) -> void:
	var panel := PanelContainer.new()
	var surface := PresentationTheme.panel_style(Color("061b1f45"))
	surface.content_margin_left = 8
	surface.content_margin_right = 8
	surface.content_margin_top = 2
	surface.content_margin_bottom = 2
	panel.add_theme_stylebox_override("panel", surface)
	body.add_child(panel)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	panel.add_child(row)
	caption.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	caption.set_meta("text_role", &"muted")
	row.add_child(caption)
	value.autowrap_mode = TextServer.AUTOWRAP_OFF
	value.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	value.set_meta("text_role", &"number")
	row.add_child(value)
