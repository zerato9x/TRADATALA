extends Control

# Every subset, grouped as normal/singles, pairs, triples, all four.
const COMBINATION_BITS := [0, 1, 2, 4, 8, 3, 5, 9, 6, 10, 12, 7, 11, 13, 14, 15]
const SHORT_NAMES := ["M", "S", "E", "R"]
var faces: Array[TextureRect] = []
var cards: Array[PlayingCardView] = []
var freeze_button: CheckButton
var time_slider: HSlider
var inspector: PanelContainer
var inspector_row: HBoxContainer
var inspector_title: Label
var current_uniforms := {"freeze_motion": false, "sample_time": 0.0, "motion_speed": 0.65}

func _ready() -> void:
	var background := ColorRect.new()
	background.color = Color("22252c")
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(background)
	_label("GIEO QUẺ / PERMANENT MARKS", Vector2(24, 14), 22, Color("f1dbab"))
	_label("M  SEAL     S  FRAME     E  CUTS     R  LIQUID", Vector2(530, 20), 15, Color("bed4e1"))
	_build_controls()
	for index in 16:
		var bits: int = COMBINATION_BITS[index]
		var origin := Vector2(24 + (index % 4) * 307, 106 + floori(float(index) / 4.0) * 152)
		var title := Button.new()
		title.text = _combination_name(bits) + "   ↗"
		title.position = origin
		title.size = Vector2(260, 24)
		title.flat = true
		title.alignment = HORIZONTAL_ALIGNMENT_LEFT
		title.add_theme_font_size_override("font_size", 13)
		title.tooltip_text = "Inspect enlarged material"
		title.pressed.connect(_inspect.bind(bits))
		add_child(title)
		_add_face(_data(bits, "A", 1, "Spades"), origin + Vector2(4, 31), Vector2(57, 79), self)
		_add_face(_data(bits, "K", 13, "Clubs"), origin + Vector2(72, 31), Vector2(57, 79), self)
		var view := PlayingCardView.new()
		view.set_card(_data(bits, "7", 7, "Hearts"))
		add_child(view)
		view.layout_to(origin + Vector2(149, 27), 0, false)
		cards.append(view)
		faces.append(view.get_node("BeatVisual/Face") as TextureRect)
		_label("57 × 79", origin + Vector2(28, 115), 10, Color("98a9b9"))
	_build_inspector()

func _build_controls() -> void:
	var controls := HBoxContainer.new()
	controls.position = Vector2(24, 57)
	controls.add_theme_constant_override("separation", 15)
	add_child(controls)
	freeze_button = CheckButton.new()
	freeze_button.text = "Freeze"
	freeze_button.toggled.connect(func(value: bool) -> void: set_uniform("freeze_motion", value))
	controls.add_child(freeze_button)
	time_slider = HSlider.new()
	time_slider.editable = false
	time_slider.custom_minimum_size = Vector2(140, 28)
	time_slider.max_value = 40
	time_slider.step = 0.1
	time_slider.tooltip_text = "Scrub material time while frozen"
	time_slider.value_changed.connect(func(value: float) -> void: set_uniform("sample_time", value))
	controls.add_child(time_slider)
	var speed_label := Label.new()
	speed_label.text = "Speed"
	controls.add_child(speed_label)
	var speed := HSlider.new()
	speed.custom_minimum_size = Vector2(100, 28)
	speed.min_value = 0.1
	speed.max_value = 1.5
	speed.step = 0.05
	speed.value = 0.65
	speed.value_changed.connect(func(value: float) -> void: set_uniform("motion_speed", value))
	controls.add_child(speed)
	var cues := CheckButton.new()
	cues.text = "Eligibility"
	cues.toggled.connect(func(value: bool) -> void:
		for card in cards:
			card.set_action_cues(value, value, value))
	controls.add_child(cues)
	var selected := CheckButton.new()
	selected.text = "Selected"
	selected.toggled.connect(func(value: bool) -> void:
		for card in cards:
			card.set_selected(value))
	controls.add_child(selected)
	var note := Label.new()
	note.text = "48 cards / all 16 states / click a heading to enlarge"
	note.add_theme_font_size_override("font_size", 12)
	controls.add_child(note)

func _combination_name(bits: int) -> String:
	if bits == 0:
		return "ORDINARY"
	if bits == 15:
		return "ALL FOUR / M + S + E + R"
	var names: Array[String] = []
	for i in 4:
		if bits & (1 << i):
			names.append(SHORT_NAMES[i])
	return " + ".join(names)

func _data(bits: int, rank: String, value: int, suit: String) -> CardData:
	var card := CardData.new("mark_%s_%d" % [rank, bits], rank, value, suit, value)
	for i in 4:
		if bits & (1 << i):
			card.add_gieo_property(GieoCardFX.PROPERTIES[i])
	return card

func _add_face(card: CardData, position_value: Vector2, dimensions: Vector2, parent: Node) -> TextureRect:
	var face := TextureRect.new()
	face.texture = load(card.texture_path()) as Texture2D
	face.position = position_value
	face.size = dimensions
	face.custom_minimum_size = dimensions
	face.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	face.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	face.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	face.mouse_filter = Control.MOUSE_FILTER_IGNORE
	GieoCardFX.attach_texture(face, card)
	if face.material != null:
		for parameter in current_uniforms:
			face.material.set_shader_parameter(parameter, current_uniforms[parameter])
	parent.add_child(face)
	faces.append(face)
	return face

func set_uniform(parameter: String, value: Variant) -> void:
	current_uniforms[parameter] = value
	if parameter == "freeze_motion":
		freeze_button.set_pressed_no_signal(bool(value))
		time_slider.editable = bool(value)
	for face in faces:
		if is_instance_valid(face) and face.material is ShaderMaterial:
			face.material.set_shader_parameter(parameter, value)

func _build_inspector() -> void:
	inspector = PanelContainer.new()
	inspector.position = Vector2(298, 169)
	inspector.size = Vector2(665, 409)
	inspector.z_index = 1000
	inspector.add_theme_stylebox_override("panel", PresentationTheme.panel_style(Color("#171c25"), Color("#dfbc73"), 2, 12, 20))
	add_child(inspector)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 18)
	inspector.add_child(column)
	inspector_title = Label.new()
	column.add_child(inspector_title)
	inspector_row = HBoxContainer.new()
	inspector_row.add_theme_constant_override("separation", 24)
	inspector_row.alignment = BoxContainer.ALIGNMENT_CENTER
	column.add_child(inspector_row)
	var close := Button.new()
	close.text = "CLOSE / back to native-size comparison"
	close.pressed.connect(inspector.hide)
	column.add_child(close)
	inspector.hide()

func _inspect(bits: int) -> void:
	for child in inspector_row.get_children():
		faces.erase(child)
		inspector_row.remove_child(child)
		child.queue_free()
	inspector_title.text = _combination_name(bits) + " / 3× inspection"
	_add_face(_data(bits, "A", 1, "Spades"), Vector2.ZERO, Vector2(171, 237), inspector_row)
	_add_face(_data(bits, "7", 7, "Hearts"), Vector2.ZERO, Vector2(171, 237), inspector_row)
	_add_face(_data(bits, "K", 13, "Clubs"), Vector2.ZERO, Vector2(171, 237), inspector_row)
	inspector.show()

func _label(text_value: String, position_value: Vector2, font_size: int, color: Color) -> void:
	var label := Label.new()
	label.text = text_value
	label.position = position_value
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(label)
