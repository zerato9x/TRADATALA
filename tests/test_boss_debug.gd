@tool
extends McpTestSuite

func suite_name() -> String: return "boss_debug"

func _fixture() -> Dictionary:
	var deal := DealState.new()
	var campaign := CampaignManager.new(deal.wallet)
	campaign.drink_manager.progress = DrinkProgress.new("")
	campaign.zodiac.progress = ZodiacProgress.new("")
	campaign.difficulty_progress = preload("res://scripts/campaign/difficulty_progress.gd").new("")
	campaign.zodiac.bind(campaign, deal)
	return {"deal": deal, "campaign": campaign}

func test_every_boss_tier_and_phase_starts_real_valid_deterministic_card_state() -> void:
	for boss: String in ZodiacBossRule.RULES:
		for tier in [1, 2, 3]:
			for phase in [1, 2]:
				var a := _fixture()
				var b := _fixture()
				var options := {"boss": boss, "difficulty": tier, "phase": phase, "seed": "REPEATABLE-BOSS", "opening": "curated"}
				assert_true(BossDebugSession.prepare(a.campaign, a.deal, options))
				assert_true(BossDebugSession.prepare(b.campaign, b.deal, options))
				assert_eq(a.deal.current_phase, phase)
				assert_eq(a.deal.zodiac_boss.id, boss)
				assert_eq(a.deal.zodiac_boss.difficulty, tier)
				assert_eq(a.deal.zodiac_boss.snapshot(), b.deal.zodiac_boss.snapshot())
				assert_eq(a.deal.deck._rng.state, b.deal.deck._rng.state)
				assert_eq(a.deal.hand.map(func(card): return card.unique_id), b.deal.hand.map(func(card): return card.unique_id))
				assert_true(a.deal.physical_card_accounting_is_valid())

func test_curated_opening_contains_actual_melds_and_extensions_and_drink_charge() -> void:
	var a := _fixture()
	assert_true(BossDebugSession.prepare(a.campaign, a.deal, {"boss": "horse", "drink": DrinkCatalog.NUOC_VOI}))
	var sets: Array[CardData] = a.deal.hand.filter(func(card): return card.rank == "9")
	var run: Array[CardData] = a.deal.hand.filter(func(card): return card.suit == "Clubs" and card.rank_index in [4, 5, 6])
	assert_eq(sets.size(), 4)
	assert_eq(run.size(), 3)
	assert_true(a.deal.create_meld(sets.slice(0, 3)).ok)
	assert_true(a.deal.create_meld(run).ok)
	assert_true(a.deal.current_drink_has_charge())
	assert_true(a.deal.physical_card_accounting_is_valid())

func test_dragon_history_is_real_unless_an_explicit_debug_override_is_selected() -> void:
	var a := _fixture()
	var history := [{"action": "extension", "meld_type": "run", "points": 12, "earned_vnd": 40_000}, {"action": "extension", "meld_type": "run", "points": 6, "earned_vnd": 20_000}]
	assert_true(BossDebugSession.prepare(a.campaign, a.deal, {"boss": "dragon", "difficulty": 3}, history))
	assert_eq(a.deal.zodiac_boss.data.analysis.tactic, "extension:run")
	assert_eq(a.deal.zodiac_boss.data.analysis.average_vnd, 30_000)
	assert_eq(a.deal.zodiac_boss.data.analysis.target_vnd, 36_000)
	assert_true(BossDebugSession.prepare(a.campaign, a.deal, {"boss": "dragon", "difficulty": 1, "dragon_tactic": "new_meld:set", "dragon_average_vnd": 100_000}, history))
	assert_eq(a.deal.zodiac_boss.data.analysis.tactic, "new_meld:set")
	assert_eq(a.deal.zodiac_boss.data.analysis.target_vnd, 80_000)
	assert_true(a.deal.zodiac_boss.data.analysis.debug_override)

func test_debug_checkpoint_roundtrip_retains_mode_options_rng_and_real_card_zones() -> void:
	var a := _fixture()
	assert_true(BossDebugSession.prepare(a.campaign, a.deal, {"boss": "snake", "difficulty": 3, "phase": 2, "seed": "SAVE-MY-TEST"}))
	var codec := RunSave.new("user://boss-debug-roundtrip-%d.save" % Time.get_ticks_usec())
	assert_true(codec.save_run(a.campaign, a.deal))
	var saved := codec.load_run()
	var b := _fixture()
	assert_true(codec.restore(saved, b.campaign, b.deal))
	assert_true(b.campaign.debug_context.active)
	assert_eq(b.campaign.debug_context.options.seed, "SAVE-MY-TEST")
	assert_eq(a.deal.zodiac_boss.snapshot(), b.deal.zodiac_boss.snapshot())
	assert_eq(a.deal.deck._rng.state, b.deal.deck._rng.state)
	assert_true(b.deal.physical_card_accounting_is_valid())

func test_normal_new_run_clears_debug_context_and_invalid_options_are_rejected() -> void:
	var a := _fixture()
	assert_false(BossDebugSession.prepare(a.campaign, a.deal, {"boss": "missing"}))
	assert_false(BossDebugSession.prepare(a.campaign, a.deal, {"boss": "cat", "drink": "missing"}))
	assert_true(BossDebugSession.prepare(a.campaign, a.deal, {"boss": "mouse", "difficulty": 99, "phase": 99}))
	assert_eq(a.deal.zodiac_boss.id, "rat")
	assert_eq(a.deal.zodiac_boss.difficulty, 3)
	a.campaign.start_campaign(true, "NORMAL-AGAIN")
	assert_true(a.campaign.debug_context.is_empty())

func test_snake_can_generate_next_turn_commands_with_a_real_meld_on_the_table() -> void:
	for tier in [2, 3]:
		for phase in [1, 2]:
			var fixture := _fixture()
			var deal: DealState = fixture.deal
			assert_true(BossDebugSession.prepare(fixture.campaign, deal, {"boss": "snake", "difficulty": tier, "phase": phase, "seed": "SNAKE-AFTER-MELD"}))
			var run: Array[CardData] = deal.hand.filter(func(card: CardData): return card.suit == "Clubs" and card.rank_index in [4, 5, 6])
			assert_true(deal.create_meld(run).ok)
			assert_eq(deal.melds.size(), 1)
			var result := deal.discard_card(deal.hand[-1])
			assert_true(result.ok)
			assert_eq(deal.discard_count, 1)
			assert_eq(deal.zodiac_boss.turn_serial, 2)
			assert_false(deal.zodiac_boss.data.commands.is_empty())
			assert_eq(deal.state, DealState.STATE_ACTIVE)
			assert_true(deal.physical_card_accounting_is_valid())
