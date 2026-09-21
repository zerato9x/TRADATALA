class_name NpcConversation
extends PanelContainer

signal response_selected(response_id: String)

@onready var speaker: Label = %Speaker
@onready var speech: RichTextLabel = %Speech
var _reveal: Tween


func _ready() -> void:
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
	if _reveal != null:
		_reveal.kill()
	speaker.text = speaker_name
	PresentationTheme.style_text(speaker, &"speaker", 20)
	speech.bbcode_enabled = true
	speech.text = formatted
	speech.visible_characters = 0
	visible = true
	_reveal = create_tween()
	_reveal.tween_property(speech, "visible_characters", speech.get_total_character_count(), minf(speech.get_total_character_count() / 90.0, 2.0))


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		if _reveal != null:
			_reveal.kill()
		speech.visible_characters = -1
		accept_event()
