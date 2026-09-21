class_name CampaignNpcCatalog
extends RefCounted

const TRA_DA_AUNTIE := "tra_da_auntie"
const THAY_BOI := "thay_boi"


static func register_initial_npcs(event_manager: EventManager) -> void:
	var collector := NPCDefinition.new("doi_no", "NPC_DOI_NO", [EventManager.EventSlot.STARTER], true)
	collector.interaction_specs.append({"id": "debt_intro", "action_type": "debt_intro", "mandatory": false})
	event_manager.register_npc(collector)
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
	if DemoBuild.enabled():
		auntie.eligible_event_slots = [EventManager.EventSlot.STARTER, EventManager.EventSlot.MORNING, EventManager.EventSlot.NOON, EventManager.EventSlot.AFTERNOON]
		auntie.interaction_specs.append({
			"id": "choose_drink", "action_type": "choose_drink", "mandatory": false,
			"slots": [EventManager.EventSlot.MORNING, EventManager.EventSlot.AFTERNOON],
		})
	event_manager.register_npc(auntie)
	if DemoBuild.enabled():
		return
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
	for spec in [
		["hang_rong", "NPC_HANG_RONG", [EventManager.EventSlot.MORNING, EventManager.EventSlot.AFTERNOON], "relic_shop"],
		["danh_giay", "NPC_DANH_GIAY", [EventManager.EventSlot.STARTER], "polish"],
		["lotto", "NPC_LOTTO", [EventManager.EventSlot.MORNING, EventManager.EventSlot.AFTERNOON], "lottery"],
	]:
		var slots: Array[int] = []
		slots.assign(spec[2])
		var npc := NPCDefinition.new(spec[0], spec[1], slots, true)
		npc.interaction_specs.append({"id": spec[3], "action_type": spec[3], "mandatory": false})
		event_manager.register_npc(npc)
