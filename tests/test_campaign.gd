@tool
extends McpTestSuite


func suite_name() -> String:
	return "campaign"


func test_campaign_requirements_live_in_config_and_increase_each_day() -> void:
	var days := CampaignConfig.day_definitions()
	assert_eq(days.size(), 7)
	assert_true(CampaignConfig.requirements_are_strictly_increasing(days))
	assert_eq(days[0]["id"], "monday")
	assert_eq(days[-1]["id"], "sunday")


func test_music_player_uses_a_plain_twenty_six_track_playlist() -> void:
	var controller := ReactiveMusicController.new()
	controller._build_playlist()
	assert_eq(controller.playlist.size(), 26)
	assert_eq(controller.playlist[0]["path"], "res://assets/audio/ost/main_1.wav")
	assert_eq(controller.playlist[1]["path"], "res://assets/audio/ost/main_2.wav")
	assert_eq(controller.playlist[-1]["path"], "res://assets/audio/ost/pig_2.wav")
	controller.current_track_index = 0
	assert_eq(controller._next_track_index(), 1)
	controller.set_shuffle_enabled(true)
	var shuffled_request := controller.next_mix_request()
	assert_ne(shuffled_request["path"], controller.playlist[controller.current_track_index]["path"])
	assert_eq(controller.next_mix_request()["path"], shuffled_request["path"])
	controller.set_shuffle_enabled(false)
	controller.current_track_index = controller.playlist.size() - 1
	assert_eq(controller._next_track_index(), -1)
	controller.cycle_repeat_mode()
	assert_eq(controller.repeat_mode, ReactiveMusicController.REPEAT_ALL)
	assert_eq(controller._next_track_index(), 0)
	controller.cycle_repeat_mode()
	assert_eq(controller.repeat_mode, ReactiveMusicController.REPEAT_ONE)
	assert_eq(controller._next_track_index(), controller.current_track_index)
	controller.free()


func test_events_support_empty_multiple_and_mandatory_interactions() -> void:
	var manager := EventManager.new()
	var empty := manager.build_event(EventManager.EventSlot.MORNING)
	assert_true(empty.participants.is_empty())
	assert_true(empty.can_exit)
	assert_true(manager.finish_current_event())

	CampaignNpcCatalog.register_initial_npcs(manager)
	var visitor := NPCDefinition.new(
		"test_visitor",
		"TEST_VISITOR",
		[EventManager.EventSlot.STARTER],
		false
	)
	visitor.appearance_condition = func(_context: Dictionary) -> bool: return true
	visitor.interaction_specs.append({
		"id": "test_tip",
		"action_type": "gain_vnd",
		"mandatory": false,
	})
	manager.register_npc(visitor)
	var event := manager.build_event(EventManager.EventSlot.STARTER)
	assert_eq(event.participants.size(), 2)
	assert_eq(event.interactions.size(), 2)
	assert_false(event.can_exit)
	assert_false(manager.finish_current_event())
	assert_true(manager.complete_interaction("choose_drink"))
	assert_true(event.can_exit)
	assert_true(manager.finish_current_event())


func test_drink_selection_uses_shared_wallet_and_two_deal_periods() -> void:
	var wallet := VndWallet.new()
	wallet.reset(50_000)
	var drinks := DrinkManager.new(wallet)
	var morning := drinks.select_for_event(EventManager.EventSlot.STARTER, DrinkCatalog.NUOC_VOI)
	assert_true(morning["ok"])
	assert_eq(wallet.balance_vnd, 40_000)
	assert_eq(drinks.morning_drink_id, DrinkCatalog.NUOC_VOI)
	assert_eq(drinks.active_drink_id, DrinkCatalog.NUOC_VOI)
	var afternoon := drinks.select_for_event(EventManager.EventSlot.NOON, DrinkCatalog.SAM_DUA)
	assert_true(afternoon["ok"])
	assert_eq(wallet.balance_vnd, 20_000)
	assert_eq(drinks.morning_drink_id, DrinkCatalog.NUOC_VOI)
	assert_eq(drinks.afternoon_drink_id, DrinkCatalog.SAM_DUA)
	drinks.clear_day()
	assert_eq(drinks.morning_drink_id, DrinkCatalog.NONE)
	assert_eq(drinks.afternoon_drink_id, DrinkCatalog.NONE)
	assert_eq(drinks.active_drink_id, DrinkCatalog.NONE)


func test_campaign_completes_28_deals_and_28_event_slots_before_sunday_victory() -> void:
	var wallet := VndWallet.new()
	var events := EventManager.new()
	CampaignNpcCatalog.register_initial_npcs(events)
	var campaign := CampaignManager.new(wallet, events, DrinkManager.new(wallet))
	campaign.start_campaign()
	var deal_count := 0
	var event_count := 0
	var safety := 0
	while not campaign.campaign_complete and not campaign.run_failed and safety < 100:
		safety += 1
		if CampaignManager.EVENT_PHASE_TO_SLOT.has(campaign.current_phase):
			event_count += 1
			var event := events.current_event
			if event.interaction_by_id("choose_drink") != null:
				assert_true(campaign.drink_manager.select_for_event(event.slot, DrinkCatalog.TRA_DA)["ok"])
				assert_true(events.complete_interaction("choose_drink"))
			assert_true(campaign.complete_current_event())
		elif CampaignManager.DEAL_PHASE_TO_PERIOD.has(campaign.current_phase):
			wallet.apply_vnd(100_000, "campaign_test_deal")
			deal_count += 1
			assert_true(campaign.complete_deal())
		else:
			break
	assert_true(campaign.campaign_complete)
	assert_false(campaign.run_failed)
	assert_eq(campaign.current_phase, CampaignManager.CampaignPhase.CAMPAIGN_VICTORY)
	assert_eq(deal_count, 28)
	assert_eq(event_count, 28)
	assert_eq(wallet.balance_vnd, 2_800_000)


func test_campaign_failure_stops_after_evening_deal_without_deducting_requirement() -> void:
	var wallet := VndWallet.new()
	var events := EventManager.new()
	CampaignNpcCatalog.register_initial_npcs(events)
	var days: Array[Dictionary] = [{"id": "monday", "name_key": "DAY_MONDAY", "required_vnd": 1}]
	var campaign := CampaignManager.new(wallet, events, DrinkManager.new(wallet), days)
	campaign.start_campaign()
	var deals := 0
	while not campaign.run_failed:
		if CampaignManager.EVENT_PHASE_TO_SLOT.has(campaign.current_phase):
			var event := events.current_event
			if event.interaction_by_id("choose_drink") != null:
				campaign.drink_manager.select_for_event(event.slot, DrinkCatalog.TRA_DA)
				events.complete_interaction("choose_drink")
			campaign.complete_current_event()
		elif CampaignManager.DEAL_PHASE_TO_PERIOD.has(campaign.current_phase):
			deals += 1
			campaign.complete_deal()
		else:
			break
	assert_true(campaign.run_failed)
	assert_eq(campaign.current_phase, CampaignManager.CampaignPhase.CAMPAIGN_FAILURE)
	assert_eq(deals, 4)
	assert_eq(wallet.balance_vnd, 0)
