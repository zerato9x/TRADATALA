class_name EventManager
extends RefCounted

signal event_started(event_instance: EventInstance)
signal interaction_completed(event_instance: EventInstance, interaction: EventInteraction)
signal event_finished(event_instance: EventInstance)

enum EventSlot {
	STARTER,
	MORNING,
	NOON,
	AFTERNOON,
}

var npc_definitions: Dictionary = {}
var current_event: EventInstance


func register_npc(definition: NPCDefinition) -> void:
	if definition != null and not definition.id.is_empty():
		npc_definitions[definition.id] = definition


func unregister_npc(npc_id: String) -> void:
	npc_definitions.erase(npc_id)


func build_event(slot: int, context: Dictionary = {}) -> EventInstance:
	var event := EventInstance.new(slot, context)
	for definition_value in npc_definitions.values():
		var definition := definition_value as NPCDefinition
		if definition == null or not definition.is_eligible(slot, context):
			continue
		event.participants.append(definition)
		event.interactions.append_array(definition.build_interactions(slot))
	event.update_can_exit()
	current_event = event
	event_started.emit(event)
	return event


func complete_interaction(interaction_id: String) -> bool:
	if current_event == null:
		return false
	var interaction := current_event.interaction_by_id(interaction_id)
	if interaction == null or not current_event.complete_interaction(interaction_id):
		return false
	interaction_completed.emit(current_event, interaction)
	return true


func finish_current_event() -> bool:
	if current_event == null or not current_event.can_exit:
		return false
	var finished := current_event
	current_event = null
	event_finished.emit(finished)
	return true


static func slot_name_key(slot: int) -> String:
	match slot:
		EventSlot.STARTER:
			return "EVENT_STARTER"
		EventSlot.MORNING:
			return "EVENT_MORNING"
		EventSlot.NOON:
			return "EVENT_NOON"
		EventSlot.AFTERNOON:
			return "EVENT_AFTERNOON"
	return "EVENT_UNKNOWN"
