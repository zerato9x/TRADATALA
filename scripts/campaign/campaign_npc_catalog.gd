class_name CampaignNpcCatalog
extends RefCounted

const TRA_DA_AUNTIE := "tra_da_auntie"


static func register_initial_npcs(event_manager: EventManager) -> void:
	var auntie := NPCDefinition.new(
		TRA_DA_AUNTIE,
		"NPC_TRA_DA_AUNTIE",
		[EventManager.EventSlot.STARTER, EventManager.EventSlot.NOON],
		true
	)
	auntie.interaction_specs.append({
		"id": "choose_drink",
		"action_type": "choose_drink",
		"mandatory": true,
		"slots": [EventManager.EventSlot.STARTER, EventManager.EventSlot.NOON],
	})
	event_manager.register_npc(auntie)
