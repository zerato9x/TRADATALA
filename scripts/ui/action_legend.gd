extends CanvasLayer

func _ready() -> void:
	%Toggle.pressed.connect(_toggle)
	%Close.pressed.connect(func() -> void: %Shade.visible = false)
	%Toggle.tooltip_text = tr("VERB_LEGEND_TITLE")

func _process(_delta: float) -> void:
	var menu: Control = get_parent().get("menu_layer")
	if menu == null: return
	%Toggle.visible = not menu.visible
	if menu.visible and %Shade.visible: %Shade.visible = false

func _toggle() -> void:
	%Shade.visible = not %Shade.visible
	%Title.text = tr("VERB_LEGEND_TITLE")
	%Words.text = ActionVocabulary.legend()
	%Close.text = tr("EVENT_BACK")

func _unhandled_key_input(event: InputEvent) -> void:
	if %Shade.visible:
		if event.is_action_pressed("ui_cancel"): %Shade.visible = false
		get_viewport().set_input_as_handled()
