class_name NpcConversation
extends PanelContainer

signal response_selected(response_id: String)

@onready var speaker: Label = %Speaker
@onready var speech: RichTextLabel = %Speech
var _reveal: Tween
var _full_line := ""
var handbook: Button


func _ready() -> void:
	speech.set_meta("manual_text_reveal", true)
	speech.custom_minimum_size.y = 36
	custom_minimum_size.y = 88
	var heading := HBoxContainer.new()
	heading.name = "ConversationHeading"
	$Lines.add_child(heading)
	$Lines.move_child(heading, 0)
	speaker.reparent(heading)
	speaker.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var guide := Button.new()
	handbook = guide
	guide.name = "NpcHandbook"
	guide.text = GameGlossary.words("Handbook", "Sổ tay")
	PresentationTheme.configure_button(guide)
	guide.add_theme_font_size_override("font_size", 16)
	guide.custom_minimum_size.y = 28
	guide.pressed.connect(func(): GameGlossary.open_entry(self, speaker.text, _full_line, "npcs"))
	heading.add_child(guide)
	%SmallTalk.pressed.connect(func() -> void: response_selected.emit("small_talk"))
	%Leave.pressed.connect(func() -> void: response_selected.emit("leave"))


func show_responses(enabled: bool, can_leave: bool = true) -> void:
	%Responses.visible = enabled
	%SmallTalk.text = tr("NPC_ASK_BUSINESS")
	%Leave.text = tr("NPC_LEAVE")
	%Leave.disabled = not can_leave


func say(speaker_name: String, line: String, show_full_line: bool = false) -> void:
	_full_line = line
	var formatted := PresentationTheme.emphasize_money(ActionVocabulary.colorize(line if show_full_line else QuickInfo.first_sentence(line)))
	if visible and speaker.text == speaker_name and speech.get_meta("semantic_source_text", speech.text) == formatted:
		return
	speaker.text = speaker_name
	PresentationTheme.style_text(speaker, &"speaker", 20)
	speech.bbcode_enabled = true
	speech.text = formatted
	visible = true
	_reveal = TextReveal.reveal(speech)


func _gui_input(event: InputEvent) -> void:
	if (event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT) or (event is InputEventScreenTouch and event.pressed) or event.is_action_pressed("ui_accept"):
		TextReveal.finish(speech)
		accept_event()
