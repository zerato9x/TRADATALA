class_name NPCDefinition
extends RefCounted

var id: String
var display_name_key: String
var eligible_event_slots: Array[int] = []
var guaranteed: bool = false
var appearance_condition: Callable
var interaction_specs: Array[Dictionary] = []


func _init(
	p_id: String = "",
	p_display_name_key: String = "",
	p_slots: Array[int] = [],
	p_guaranteed: bool = false
) -> void:
	id = p_id
	display_name_key = p_display_name_key
	eligible_event_slots.assign(p_slots)
	guaranteed = p_guaranteed


func is_eligible(slot: int, context: Dictionary) -> bool:
	if not eligible_event_slots.has(slot):
		return false
	if guaranteed:
		return true
	return appearance_condition.is_valid() and bool(appearance_condition.call(context))


func build_interactions(slot: int) -> Array[EventInteraction]:
	var built: Array[EventInteraction] = []
	for spec: Dictionary in interaction_specs:
		var slots: Array = spec.get("slots", eligible_event_slots)
		if not slots.has(slot):
			continue
		built.append(EventInteraction.new(
			String(spec.get("id", "%s_interaction" % id)),
			id,
			String(spec.get("action_type", "interact")),
			bool(spec.get("mandatory", false)),
			spec.get("metadata", {}) as Dictionary
		))
	return built
