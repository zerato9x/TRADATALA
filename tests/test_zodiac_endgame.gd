@tool
extends McpTestSuite
const Analysis := preload("res://scripts/zodiac/dragon_analysis.gd")

func suite_name() -> String: return "zodiac_endgame"

func _deal(id: String, level: int = 2) -> DealState:
	var deal := DealState.new()
	deal.start_tutorial_deal()
	deal.zodiac_boss.configure(id, level, 3009)
	deal.zodiac_boss.begin_phase(deal)
	return deal

func _campaign(deal: DealState) -> CampaignManager:
	var campaign := CampaignManager.new(deal.wallet)
	campaign.zodiac.bind(campaign, deal)
	campaign.start_campaign(true, "zodiac-full-runtime")
	return campaign

func _disk_copy(deal: DealState, campaign: CampaignManager) -> Array:
	var save := RunSave.new("user://zodiac-all-bosses.save")
	assert_true(save.save_run(campaign, deal))
	var copy := DealState.new()
	var owner := CampaignManager.new(copy.wallet)
	owner.zodiac.bind(owner, copy)
	assert_true(save.restore(save.load_run(), owner, copy))
	assert_eq(copy.zodiac_boss.snapshot(), deal.zodiac_boss.snapshot())
	assert_true(copy.physical_card_accounting_is_valid())
	for suffix in ["", ".bak", ".tmp"]: DirAccess.remove_absolute(save.path + suffix)
	return [copy, owner]

func _history() -> Array:
	var deal := _deal("")
	deal.create_meld(deal.hand.slice(0, 3))
	deal.create_meld(deal.hand.slice(0, 3))
	var cards: Array[CardData] = []
	for suit in ["Spades", "Hearts", "Diamonds"]:
		var card := deal._take_tutorial_card("3", suit)
		deal.hand.append(card)
		cards.append(card)
	deal.create_meld(cards)
	return deal.action_history.duplicate(true)

func test_dragon_classifier_uses_successful_real_telemetry_and_all_target_tiers() -> void:
	var history := _history()
	assert_eq(history[0].meld_type, "run")
	assert_eq(history[0].card_ids.size(), 3)
	assert_eq(history[0].ranks, [4, 5, 6])
	assert_eq(history[0].suits, ["Hearts", "Hearts", "Hearts"])
	assert_eq(history[0].theoretical_score, 45)
	assert_eq(history[0].earned_vnd, 45_000)
	history.append({"action": "extension", "meld_type": "run", "points": 1000, "earned_vnd": 0})
	history.append({"action": "new_meld", "meld_type": "run", "points": 1000})
	for level in [1, 2, 3]:
		var result := Analysis.analyze(history, level)
		assert_eq(result.tactic, "new_meld:set")
		assert_eq(result.average_vnd, 54_000)
		assert_eq(result.sample_count, 2)
		assert_eq(result.target_vnd, [43_200, 54_000, 64_800][level - 1])
		assert_false(result.legacy_fallback)
	assert_true(Analysis.analyze([], 2).legacy_fallback)
	assert_eq(Analysis.analyze([], 2).average_vnd, 0)

func test_dragon_tactic_restriction_target_and_first_ending() -> void:
	for level in [1, 2, 3]:
		var deal := _deal("dragon", level)
		deal.zodiac_boss.data.analysis = Analysis.analyze(_history(), level)
		var wrong := deal.create_meld(deal.hand.slice(0, 3))
		assert_true(wrong.ok)
		assert_eq(wrong.context.final_points, 0)
		assert_eq(wrong.context.suppression_reason, "dragon_tactic_required")
		assert_eq(deal.state, DealState.STATE_ACTIVE)
		assert_eq(deal.zodiac_boss.data.progress_vnd, 0)
		var right := deal.create_meld(deal.hand.slice(0, 3))
		assert_gt(right.context.final_points, 0)
		assert_eq(deal.zodiac_boss.data.progress_vnd, 81_000)
		deal.zodiac_boss.settle(deal)
		assert_true(deal.zodiac_boss.data.victory)
		assert_eq(deal.zodiac_boss.presentation().ending, "RỒNG RẮN LÊN MÂY")
		assert_true(deal.physical_card_accounting_is_valid())

func test_every_boss_and_tier_disk_roundtrip_preserves_future_rng_and_card_zones() -> void:
	for id: String in ZodiacBossRule.RULES:
		for level in [1, 2, 3]:
			var deal := _deal(id, level)
			var campaign := _campaign(deal)
			deal.zodiac_boss.begin_turn(1, deal.hand, deal)
			var copy: DealState = _disk_copy(deal, campaign)[0]
			assert_eq(copy.zodiac_boss.difficulty, level)
			assert_false(copy.zodiac_boss.snapshot().has("hard"))
			var deck_rng := deal.deck._rng.state
			deal.zodiac_boss.begin_turn(2, deal.hand, deal)
			copy.zodiac_boss.begin_turn(2, copy.hand, copy)
			assert_eq(deal.zodiac_boss.snapshot(), copy.zodiac_boss.snapshot())
			assert_eq(deal.hand.map(func(card: CardData): return card.unique_id), copy.hand.map(func(card: CardData): return card.unique_id))
			assert_eq(deal.deck._rng.state, deck_rng)
			assert_true(deal.physical_card_accounting_is_valid())
			assert_true(copy.physical_card_accounting_is_valid())

func test_dragon_one_modifier_per_turn_save_restore_and_expiration() -> void:
	for level in [1, 2, 3]:
		var deal := _deal("dragon", level)
		var campaign := _campaign(deal)
		deal.zodiac_boss.data.analysis = Analysis.analyze(_history(), level)
		deal.zodiac_boss.begin_turn(1, deal.hand, deal)
		var copy: DealState = _disk_copy(deal, campaign)[0]
		for _turn in 8:
			for current: DealState in [deal, copy]:
				current.zodiac_boss.before_refill(current)
				assert_eq(current.zodiac_boss.data.modifier_id, "")
				assert_true(current.zodiac_boss.locked_ids.is_empty())
				current.deck.refill(current.hand, DealState.ACTIVE_HAND_TARGET)
				current.zodiac_boss.begin_turn(1, current.hand, current)
				assert_true(current.zodiac_boss.data.modifier_id in ["rooster", "cat", "dog", "monkey", "pig", "ox", "horse", "goat", "rat", "tiger", "snake"])
				assert_true(current.physical_card_accounting_is_valid())
			assert_eq(deal.zodiac_boss.snapshot(), copy.zodiac_boss.snapshot())
			assert_eq(deal.deck._rng.state, copy.deck._rng.state)

func test_post_snake_choice_save_restore_continuation_and_endless_debt() -> void:
	var deal := _deal("snake", 1)
	var campaign := _campaign(deal)
	campaign.current_day_index = 5
	campaign.zodiac.begin_day(5, 17)
	campaign.current_phase = CampaignManager.CampaignPhase.EVENING_DEAL
	deal.zodiac_boss.configure("snake", 1, 17)
	deal.state = DealState.STATE_DEAL_OVER
	assert_true(campaign.complete_deal())
	assert_eq(campaign.current_phase, CampaignManager.CampaignPhase.ZODIAC_ENDGAME_CHOICE)
	var restored: CampaignManager = _disk_copy(deal, campaign)[1]
	assert_eq(restored.current_phase, CampaignManager.CampaignPhase.ZODIAC_ENDGAME_CHOICE)
	assert_eq(restored.zodiac.endgame, campaign.zodiac.endgame)
	assert_true(restored.choose_zodiac_endgame(true))
	assert_eq(restored.current_phase, CampaignManager.CampaignPhase.DRAGON_DEAL)
	assert_eq(restored.zodiac.deal.zodiac_boss.id, "dragon")
	assert_false(restored.choose_zodiac_endgame(true))
	assert_true(campaign.choose_zodiac_endgame(false))
	assert_eq(campaign.current_phase, CampaignManager.CampaignPhase.MONEY_REQUIREMENT_CHECK)
	campaign.wallet.reset(50_000_000)
	assert_true(campaign.collect_day_debt())
	assert_eq(campaign.current_day_index, 6)
	assert_eq(campaign.zodiac.active_id(), "")
	campaign._finish_day()
	assert_true(campaign.collect_day_debt())
	assert_true(campaign.continue_endless())
	assert_eq(campaign.current_day_index, 7)
	assert_gt(campaign.daily_requirement(), 16_000_000)
	assert_true(campaign.zodiac.active_id() in ["rooster", "cat"])

func test_schedule_all_pairs_snake_only_and_legacy_unfinished_day_preserved() -> void:
	for seed in 30:
		for day in 6:
			assert_true(ZodiacCatalog.select(seed, day) in ZodiacCatalog.pair_for_day(day))
		assert_eq(ZodiacCatalog.select(seed, 5, "dragon"), "snake")
		assert_eq(ZodiacCatalog.select(seed, 6), "")
	var service := ZodiacService.new()
	service.restore({"daily": {"day": 1, "id": "", "slot": -1}})
	assert_eq(service.active_id(), "")
	assert_true(service.endgame.is_empty())


func test_dragon_goat_curated_rank_is_compatible_with_historical_tactic() -> void:
	var mechanic := preload("res://scripts/zodiac/rules/goat.gd").new()
	for level in [1, 2, 3]:
		var deal := _deal("dragon", level)
		deal.zodiac_boss.data.analysis = Analysis.analyze(_history(), level)
		var state := {}
		mechanic.dragon_begin(deal.zodiac_boss, deal, state)
		assert_eq(state.expected_rank, 9)
		assert_true(state.get("parity_required", false) if level == 3 else not state.get("parity_required", false))
		var context := deal.scoring.preview_new_meld(deal.hand.slice(3, 6), MeldRules.TYPE_SET, 1)
		assert_eq(mechanic.dragon_payout(deal.zodiac_boss, context, -1, state, false), {})
		deal.discard_count = 1
		mechanic.dragon_begin(deal.zodiac_boss, deal, state)
		assert_eq(state.expected_rank, 9)
		assert_false(state.parity_required)
		assert_eq(mechanic.dragon_payout(deal.zodiac_boss, context, -1, state, false), {})
		assert_eq(deal.deck._rng.seed, 0)

func test_all_boss_names_rules_and_authoritative_state_are_localized_and_pure() -> void:
	var old_locale := TranslationServer.get_locale()
	for id: String in ZodiacBossRule.RULES:
		for level in [1, 2, 3]:
			var deal := _deal(id, level)
			deal.current_phase = 2
			deal.zodiac_boss.begin_phase(deal)
			deal.zodiac_boss.begin_turn(2, deal.hand, deal)
			var before := deal.zodiac_boss.snapshot()
			var en := ""
			for locale in ["en", "vi"]:
				TranslationServer.set_locale(locale)
				var presentation := deal.zodiac_boss.presentation()
				assert_eq(presentation.difficulty, level)
				assert_false(presentation.rule.is_empty())
				assert_false(presentation.skill.is_empty())
				assert_false(ZodiacCatalog.state_text(presentation, deal).is_empty())
				if locale == "en": en = presentation.rule
				else: assert_ne(presentation.rule, en)
			assert_eq(before, deal.zodiac_boss.snapshot())
	TranslationServer.set_locale(old_locale)


class MusicController:
	extends RefCounted
	var cues: Array[String] = []
	func start_dj_track(_track: String, cue: String) -> bool: cues.append(cue); return true
	func request_dj_cue(cue: String) -> bool: cues.append(cue); return true
	func release_dj_to_end() -> bool: return true

func test_dragon_authored_music_routes_and_resume_checkpoint_are_valid() -> void:
	for set_id in ["cat", "dog"]:
		var controller := MusicController.new()
		var conductor := GameplayMusicConductor.new(controller)
		assert_true(conductor.start_at_state(set_id, "dragon", 1))
		assert_eq(controller.cues[-1], conductor.cue_for_role(&"evening_phase_1"))
		assert_true(conductor.on_deal_phase_started(2))
		assert_eq(controller.cues[-1], conductor.cue_for_role(&"evening_phase_2"))
		assert_true(conductor.on_new_phom(2, 1))
		assert_eq(controller.cues[-1], conductor.cue_for_role(&"evening_phase_2_cleanup"))
		var restored := GameplayMusicConductor.new(controller)
		assert_true(restored.restore_snapshot(conductor.snapshot_state()))
		assert_eq(restored.active_period, "dragon")
		assert_true(restored.on_deal_resolved())


func test_disk_restore_mouse_owned_meld_and_mid_borrow_physical_zones() -> void:
	var deal := _deal("rat", 2)
	var campaign := _campaign(deal)
	var top: Array[CardData] = []
	for suit in ["Hearts", "Diamonds"]: top.append(deal._take_tutorial_card("J", suit))
	for i in range(top.size() - 1, -1, -1): deal.deck.draw_pile.append(top[i])
	deal.boss_discard_card(deal.hand[-1], "fixture")
	deal.zodiac_boss.after_discard(deal, deal.discard_history[-1])
	var copy: DealState = _disk_copy(deal, campaign)[0]
	assert_eq(copy.boss_melds.size(), 1)
	assert_eq(copy.boss_melds[0].cards.map(func(c): return c.unique_id), deal.boss_melds[0].cards.map(func(c): return c.unique_id))
	assert_true(copy.melds.is_empty())
	var borrowed := deal.borrow_for_boss(3)
	copy = _disk_copy(deal, campaign)[0]
	assert_eq(copy.boss_borrowed_cards.size(), borrowed.size())
	assert_eq(copy.boss_borrowed_cards.map(func(c): return c.unique_id), borrowed.map(func(c): return c.unique_id))
	copy.return_boss_borrow(copy.boss_borrowed_cards.duplicate(), 123)
	deal.return_boss_borrow(borrowed, 123)
	assert_eq(copy.deck.draw_pile.map(func(c): return c.unique_id), deal.deck.draw_pile.map(func(c): return c.unique_id))
	assert_true(copy.physical_card_accounting_is_valid())
