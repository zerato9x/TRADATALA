class_name EventInstance
extends RefCounted

var slot: int = -1
var context: Dictionary = {}
var participants: Array[NPCDefinition] = []
var interactions: Array[EventInteraction] = []
var completed_interactions: Array[String] = []
var can_exit: bool = false


func _init(p_slot: int = -1, p_context: Dictionary = {}) -> void:
	slot = p_slot
	context = p_context.duplicate(true)
	update_can_exit()


func interaction_by_id(interaction_id: String) -> EventInteraction:
	for interaction in interactions:
		if interaction.id == interaction_id:
			return interaction
	return null


func complete_interaction(interaction_id: String) -> bool:
	var interaction := interaction_by_id(interaction_id)
	if interaction == null:
		return false
	interaction.complete()
	if not completed_interactions.has(interaction_id):
		completed_interactions.append(interaction_id)
	update_can_exit()
	return true


func mandatory_interactions() -> Array[EventInteraction]:
	var mandatory: Array[EventInteraction] = []
	for interaction in interactions:
		if interaction.mandatory:
			mandatory.append(interaction)
	return mandatory


func update_can_exit() -> void:
	can_exit = true
	for interaction in interactions:
		if interaction.mandatory and not interaction.completed:
			can_exit = false
			return
