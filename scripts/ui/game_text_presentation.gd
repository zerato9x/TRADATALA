extends Node
## One display policy for every scene and dynamically built text control.
## Label/Button ownership, text, layout, input and typewriter timing stay with their callers.
var controls := preload("res://scripts/ui/visible_text_controls.gd").new()

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	process_priority = 1000
	controls.include_buttons = true
	controls.include_forms = true
	controls.state_factory = _new_state
	controls.form_found.connect(func(reference): _style_form.call_deferred(reference))
	controls.removed.connect(_release_caption)
	add_child(controls)

func _new_state(_control: Control) -> Dictionary:
	return {"source": "", "output": "", "key": [], "renderer": null, "decor": {}}

func _release_caption(source: Control, state: Dictionary) -> void:
	if source.is_queued_for_deletion(): return
	if source is RichTextLabel:
		if source.text == state.output: source.text = state.source
	elif is_instance_valid(state.renderer):
		var renderer: RichTextLabel = state.renderer
		source.remove_child(renderer)
		renderer.queue_free()
		if not state.key.is_empty(): _native(source, state.key[3])
		for item in state.decor: source.add_theme_color_override(item, state.decor[item])

func _style_form(reference: WeakRef) -> void:
	var node: Node = reference.get_ref()
	if not is_instance_valid(node) or not node.is_inside_tree(): return
	node.set_meta("semantic_role", &"body")
	if node is PopupMenu:
		node.theme = PresentationTheme.create_game_theme()
	else:
		node.add_theme_font_override("font", PresentationTheme.official_font())
		node.add_theme_color_override("font_color", PresentationTheme.INK)
		node.add_theme_color_override("font_placeholder_color", PresentationTheme.MUTED)
		node.add_theme_color_override("font_uneditable_color", PresentationTheme.MUTED)

func _process(_delta: float) -> void:
	for state: Dictionary in controls.visible_states():
		var source: Control = state.ref.get_ref()
		if is_instance_valid(source): _sync(source, state)

func _sync(source: Control, state: Dictionary) -> void:
	var rich := source is RichTextLabel
	var copy: String = source.text
	if rich and copy == state.output: copy = state.source
	var existing := source.get_theme_color("default_color" if rich else "font_color")
	if not source.has_meta("text_surface") and (existing in PresentationTheme.PAPER_SEMANTIC_COLORS.values() or existing == Color("24170c")):
		source.set_meta("text_surface", &"paper")
	var paper: bool = source.get_meta("text_surface", &"dark") == &"paper"
	var role := SemanticText.role_for(source, copy)
	var color := PresentationTheme.semantic_color(role, paper)
	if source.has_meta("text_suit"): color = PresentationTheme.suit_color(source.get_meta("text_suit"))
	if source.has_meta("zodiac_id"): color = PresentationTheme.zodiac_color(source.get_meta("zodiac_id"))
	if paper and (source.has_meta("text_suit") or source.has_meta("zodiac_id")): color = color.darkened(0.45)
	var pixels := source.get_theme_font_size("normal_font_size" if rich else "font_size")
	var key: Array = [copy, pixels, role, color, TranslationServer.get_locale(), source.disabled if source is Button else false, source.material]
	if key != state.key:
		state.key = key
		state.source = copy
		source.set_meta("semantic_role", role)
		var output := SemanticText.format(copy, pixels, role, rich and source.bbcode_enabled, paper)
		if source is Button and source.icon != null and SemanticText.SUITS.has(copy.to_lower()): output = copy
		state.output = output
		if rich:
			source.set_meta("semantic_source_text", copy)
			source.bbcode_enabled = true
			source.add_theme_color_override("default_color", color)
			source.text = output
		elif source.material != null or source.has_meta("text_suit") or output == copy or copy.is_empty():
			_native(source, color)
			for item in state.decor: source.add_theme_color_override(item, state.decor[item])
			if is_instance_valid(state.renderer): state.renderer.hide()
		else:
			if not is_instance_valid(state.renderer):
				var renderer := RichTextLabel.new()
				renderer.name = "SemanticCaption"
				renderer.set_meta("semantic_renderer", true)
				renderer.mouse_filter = Control.MOUSE_FILTER_IGNORE
				renderer.focus_mode = Control.FOCUS_NONE
				renderer.bbcode_enabled = true
				renderer.scroll_active = false
				renderer.clip_contents = true
				renderer.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
				renderer.add_theme_stylebox_override("normal", StyleBoxEmpty.new())
				source.add_child(renderer)
				state.renderer = renderer
				for item in ["font_shadow_color", "font_outline_color"]: state.decor[item] = source.get_theme_color(item)
			var renderer: RichTextLabel = state.renderer
			renderer.show()
			renderer.add_theme_font_override("normal_font", source.get_theme_font("font"))
			renderer.add_theme_font_override("bold_font", source.get_theme_font("font"))
			renderer.add_theme_font_size_override("normal_font_size", pixels)
			renderer.add_theme_color_override("default_color", color)
			for item in ["font_shadow_color", "font_outline_color"]:
				if state.decor.get(item, Color.TRANSPARENT).a > 0: renderer.add_theme_color_override(item, state.decor[item])
			for item in ["outline_size", "shadow_offset_x", "shadow_offset_y"]:
				renderer.add_theme_constant_override(item, source.get_theme_constant(item))
			var align: int = source.alignment if source is Button else source.horizontal_alignment
			renderer.text = ("[center]" + output + "[/center]") if align == HORIZONTAL_ALIGNMENT_CENTER else ("[right]" + output + "[/right]") if align == HORIZONTAL_ALIGNMENT_RIGHT else output
			_hide_native_caption(source)
	if not rich and is_instance_valid(state.renderer) and state.renderer.visible:
		var renderer: RichTextLabel = state.renderer
		# Reapply after a caller changes its button state/theme. Backgrounds and icons remain native.
		_hide_native_caption(source)
		var inset := Vector2.ZERO
		var available := source.size
		if source is Button:
			var style := source.get_theme_stylebox("normal")
			inset = style.get_offset()
			available -= style.get_minimum_size()
			if source.icon != null:
				var max_icon := source.get_theme_constant("icon_max_width")
				var icon_width := float(mini(source.icon.get_width(), max_icon) if max_icon > 0 else mini(source.icon.get_width(), int(available.y)) if source.expand_icon else source.icon.get_width()) + source.get_theme_constant("h_separation")
				inset.x += icon_width
				available.x -= icon_width
			renderer.autowrap_mode = source.autowrap_mode
			renderer.modulate.a = 0.5 if source.disabled else 1.0
		else:
			renderer.autowrap_mode = source.autowrap_mode
			renderer.visible_characters = source.visible_characters
			renderer.visible_characters_behavior = source.visible_characters_behavior
			renderer.self_modulate = source.self_modulate
		available = available.max(Vector2.ZERO)
		renderer.size = available
		var height := renderer.get_content_height()
		var vertical: int = VERTICAL_ALIGNMENT_CENTER if source is Button else source.vertical_alignment
		if vertical == VERTICAL_ALIGNMENT_CENTER: inset.y += maxf(0, (available.y - height) * 0.5)
		elif vertical == VERTICAL_ALIGNMENT_BOTTOM: inset.y += maxf(0, available.y - height)
		renderer.position = inset
		renderer.size.y = maxf(0, available.y - inset.y)
	elif not rich:
		_native(source, color)

func _native(source: Control, color: Color) -> void:
	if source.get_theme_color("font_color") != color: source.add_theme_color_override("font_color", color)
	if source is Button:
		for item in ["font_hover_color", "font_pressed_color", "font_hover_pressed_color", "font_focus_color"]:
			if source.get_theme_color(item) != color: source.add_theme_color_override(item, color)
		var muted := PresentationTheme.semantic_color(&"muted", source.get_meta("text_surface", &"dark") == &"paper")
		if source.get_theme_color("font_disabled_color") != muted: source.add_theme_color_override("font_disabled_color", muted)

func _hide_native_caption(source: Control) -> void:
	for item in ["font_color", "font_shadow_color", "font_outline_color"]:
		if source.get_theme_color(item) != Color.TRANSPARENT: source.add_theme_color_override(item, Color.TRANSPARENT)
	if source is Button:
		for item in ["font_hover_color", "font_pressed_color", "font_hover_pressed_color", "font_focus_color", "font_disabled_color"]:
			if source.get_theme_color(item) != Color.TRANSPARENT: source.add_theme_color_override(item, Color.TRANSPARENT)
