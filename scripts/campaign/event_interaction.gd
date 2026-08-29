class_name EventInteraction
extends RefCounted

var id: String
var participant_id: String
var action_type: String
var mandatory: bool
var completed: bool = false
var metadata: Dictionary


func _init(
	p_id: String = "",
	p_participant_id: String = "",
	p_action_type: String = "interact",
	p_mandatory: bool = false,
	p_metadata: Dictionary = {}
) -> void:
	id = p_id
	participant_id = p_participant_id
	action_type = p_action_type
	mandatory = p_mandatory
	metadata = p_metadata.duplicate(true)


func complete() -> void:
	completed = true
