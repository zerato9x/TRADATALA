class_name NpcConversation
extends PanelContainer

signal response_selected(response_id: String)

@onready var speaker: Label = %Speaker
@onready var speech: RichTextLabel = %Speech
var _reveal: Tween


func _ready() -> void:
	speech.set_meta("manual_text_reveal", true)
	%SmallTalk.pressed.connect(func() -> void: response_selected.emit("small_talk"))
	%Leave.pressed.connect(func() -> void: response_selected.emit("leave"))


func show_responses(enabled: bool, can_leave: bool = true) -> void:
	%Responses.visible = enabled
	%SmallTalk.text = tr("NPC_ASK_BUSINESS")
	%Leave.text = tr("NPC_LEAVE")
	%Leave.disabled = not can_leave


func say(speaker_name: String, line: String) -> void:
	var formatted := PresentationTheme.emphasize_money(ActionVocabulary.colorize(line))
	if visible and speaker.text == speaker_name and speech.text == formatted:
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
