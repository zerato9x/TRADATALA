class_name DrinkShop
extends VBoxContainer

signal drink_inspected(drink_id: String)
signal order_requested(drink_id: String)

const GLASS := preload("res://assets/drinks/glass_empty.png")
const COLORS := {"basic": Color("b5d490"), "caffeine": Color("c69871"), "energy": Color("f4bd67"), "sugar": Color("a1d5df")}
var selected_id: String = ""
var _manager: DrinkManager
var _completed: bool = false
var _buttons: Dictionary = {}
var _goal_label: Label
@onready var shelf: GridContainer = %Shelf
@onready var confirm: Button = %Confirm
@onready var price: Label = %Price


func configure(manager: DrinkManager, completed: bool) -> void:
	_manager = manager
	_completed = completed
	confirm.text = tr("DRINK_ORDER")
	price.text = tr("DRINK_TEST_PRICE") if manager.test_all_drinks_available else ""
	confirm.pressed.connect(_order)
	var group := ButtonGroup.new()
	var category_rows := {}
	for category in [DrinkCatalog.CATEGORY_BASIC, DrinkCatalog.CATEGORY_CAFFEINE, DrinkCatalog.CATEGORY_ENERGY, DrinkCatalog.CATEGORY_SUGAR]:
		var section := VBoxContainer.new()
		section.name = "Class_" + category
		section.add_theme_constant_override("separation", 2)
		var heading := Label.new()
		heading.text = tr("DRINK_CLASS_" + category.to_upper())
		heading.add_theme_font_size_override("font_size", 13)
		heading.add_theme_color_override("font_color", COLORS[category])
		heading.add_theme_color_override("font_shadow_color", Color.BLACK)
		heading.add_theme_constant_override("shadow_offset_y", 2)
		section.add_child(heading)
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 8)
		section.add_child(row)
		shelf.add_child(section)
		category_rows[category] = row
	for drink_id in manager.available_drink_ids():
		var button := Button.new()
		button.name = "Drink_" + drink_id
		button.custom_minimum_size = Vector2(80, 112)
		button.toggle_mode = true
		button.button_group = group
		button.tooltip_text = DrinkCatalog.display_name(drink_id)
		if DemoBuild.enabled() and manager.progress != null:
			button.tooltip_text += "\n" + manager.progress.goal_text(drink_id)
		button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		button.add_theme_stylebox_override("normal", StyleBoxEmpty.new())
		var hover := StyleBoxFlat.new()
		hover.bg_color = Color(0.6, 0.8, 1.0, 0.12)
		hover.corner_radius_top_left = 12
		hover.corner_radius_top_right = 12
		hover.corner_radius_bottom_left = 12
		hover.corner_radius_bottom_right = 12
		button.add_theme_stylebox_override("hover", hover)
		var selected := hover.duplicate() as StyleBoxFlat
		selected.border_width_bottom = 3
		selected.border_color = Color("8fe7ff")
		button.add_theme_stylebox_override("pressed", selected)
		button.add_theme_stylebox_override("hover_pressed", selected)
		var column := VBoxContainer.new()
		column.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		column.offset_top = 4
		column.offset_bottom = -4
		column.mouse_filter = Control.MOUSE_FILTER_IGNORE
		if not manager.is_unlocked(drink_id):
			column.modulate = Color(0.42, 0.42, 0.42, 0.8)
		button.add_child(column)
		var glass := TextureRect.new()
		glass.custom_minimum_size = Vector2(0, 72)
		glass.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		glass.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		glass.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		var basic_path := "res://assets/drinks/%s_full.png" % drink_id
		glass.texture = load(basic_path) if ResourceLoader.exists(basic_path) else preload("res://assets/drinks/tra_da_full.png")
		glass.modulate = Color.WHITE if DrinkCatalog.basic_ids().has(drink_id) else COLORS.get(DrinkCatalog.category(drink_id), Color.WHITE)
		if not manager.is_unlocked(drink_id):
			var shader := Shader.new()
			shader.code = "shader_type canvas_item; void fragment() { vec4 c = texture(TEXTURE, UV); float g = dot(c.rgb, vec3(0.299, 0.587, 0.114)); COLOR *= vec4(vec3(g), c.a); }"
			var grey := ShaderMaterial.new()
			grey.shader = shader
			glass.material = grey
			glass.modulate = Color.WHITE
		glass.mouse_filter = Control.MOUSE_FILTER_IGNORE
		column.add_child(glass)
		var label := Label.new()
		label.text = DrinkCatalog.display_name(drink_id)
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		label.custom_minimum_size.x = 78
		label.add_theme_font_size_override("font_size", 12)
		label.add_theme_color_override("font_shadow_color", Color.BLACK)
		label.add_theme_constant_override("shadow_offset_y", 2)
		label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		column.add_child(label)
		button.pressed.connect(inspect_drink.bind(drink_id))
		(category_rows[DrinkCatalog.category(drink_id)] as HBoxContainer).add_child(button)
		_buttons[drink_id] = button
	if DemoBuild.enabled():
		_goal_label = Label.new()
		_goal_label.name = "UnlockProgress"
		_goal_label.custom_minimum_size = Vector2(650, 32)
		_goal_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_goal_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_goal_label.add_theme_font_size_override("font_size", 13)
		_goal_label.text = tr("DRINK_UNLOCK_HINT")
		add_child(_goal_label)
		move_child(_goal_label, shelf.get_index() + 1)
		confirm.custom_minimum_size.y = 32
	if completed:
		selected_id = manager.active_drink_id
		(_buttons[selected_id] as Button).button_pressed = true
		confirm.text = tr("EVENT_INTERACT_DONE")
		confirm.disabled = true


func inspect_drink(drink_id: String) -> void:
	selected_id = drink_id
	(_buttons[drink_id] as Button).button_pressed = true
	confirm.disabled = _completed or not _manager.can_order(drink_id)
	if _goal_label != null:
		_goal_label.text = _manager.progress.goal_text(drink_id) if _manager.progress != null else ""
		confirm.text = tr("DRINK_ORDER") if _manager.is_unlocked(drink_id) else tr("DRINK_LOCKED")
	if not _manager.test_all_drinks_available:
		price.text = VndWallet.format_vnd(_manager.price_for(drink_id))
	drink_inspected.emit(drink_id)


func _order() -> void:
	if _completed or selected_id.is_empty() or not _manager.can_order(selected_id):
		return
	confirm.disabled = true
	order_requested.emit(selected_id)
