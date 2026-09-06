class_name CampaignNpcCatalog
extends RefCounted

const TRA_DA_AUNTIE := "tra_da_auntie"
const THAY_BOI := "thay_boi"


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
	var fortune_teller := NPCDefinition.new(
		THAY_BOI,
		"NPC_THAY_BOI",
		[EventManager.EventSlot.MORNING, EventManager.EventSlot.NOON, EventManager.EventSlot.AFTERNOON],
		true
	)
	fortune_teller.interaction_specs.append({
		"id": "gieo_que",
		"action_type": "gieo_que",
		"mandatory": false,
	})
	event_manager.register_npc(fortune_teller)
