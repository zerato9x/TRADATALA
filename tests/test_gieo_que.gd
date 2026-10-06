@tool
extends McpTestSuite

func suite_name() -> String:
	return "gieo_que"

func test_exact_trigram_tables() -> void:
	assert_eq(GieoQueService.FIRST_TRIGRAM_FORTUNE, {"PPP": 3, "PPN": 2, "PNP": 2, "PNN": 1, "NPP": -1, "NPN": -2, "NNP": -2, "NNN": -3})
	for trigram: String in GieoQueService.FIRST_TRIGRAM_FORTUNE:
		assert_eq(GieoQueService.SECOND_TRIGRAM_TARGETS[trigram], "consecutive_3" if trigram == "PPP" else "random_same_suit_3" if trigram == "NNN" else "random_one")

func test_fortune_accumulates_crosses_zero_and_clamps() -> void:
	for example in [[0, 3, 3], [3, 3, 6], [6, 3, 6], [2, -3, -1], [-4, -3, -6], [-6, -3, -6], [-2, 3, 1]]:
		var card := _card(13)
		card.fortune = example[0]
		card.adjust_fortune(example[1])
		assert_eq(card.fortune, example[2])
	var card := _card(8)
	card.fortune = 99
	assert_eq(card.fortune, 6)
	card.fortune = -99
	assert_eq(card.fortune, -6)
	card.transformation_locked = true
	assert_false(card.adjust_fortune(3))
	assert_false(card.add_jackpot(CardData.JACKPOT_LIQUID))

func test_gold_counts_everywhere_and_has_normal_deadwood() -> void:
	for rank in range(1, 14):
		for fortune in range(1, 7):
			var card := _card(rank)
			card.fortune = fortune
			assert_eq(card.score_value(), rank * fortune)
			assert_eq(card.deadwood_value(), rank)
	var cards := _kings(3)
	cards[0].fortune = 6
	var pipeline := ScoringPipeline.new()
	assert_eq(cards[0].score_value(), 78)
	assert_eq(pipeline.preview_new_meld(cards, MeldRules.TYPE_SET, 1).final_points, 312)
	assert_eq(pipeline.score_meld_trigger(cards, MeldRules.TYPE_SET, 1).final_points, 312)
	var fourth := _card(13, "Diamonds", "fourth")
	var expanded: Array[CardData] = cards.duplicate()
	expanded.append(fourth)
	assert_eq(pipeline.preview_extension(expanded, MeldRules.TYPE_SET, 312, 1, [fourth]).final_points, 624)

func test_black_ink_scores_normally_and_deadwood_is_income() -> void:
	var cards := _kings(3)
	cards[0].fortune = -6
	assert_eq(cards[0].score_value(), 13)
	assert_eq(ScoringPipeline.new().preview_new_meld(cards, MeldRules.TYPE_SET, 1).final_points, 117)
	assert_eq(cards[0].deadwood_value(), -78)
	var resolution := ScoringPipeline.deadwood_resolution(cards, 3)
	assert_eq(resolution.deadwood, 78)
	assert_eq(resolution.black_ink_profit, 78)
	assert_eq(resolution.penalty_cards.size(), 2)
	assert_eq(resolution.ink_cards, [cards[0]])

func test_turn_deadwood_commits_separate_cost_and_profit_even_when_net_zero() -> void:
	var deal := DealState.new()
	deal.start_deal(101)
	deal.wallet.reset(100_000)
	deal.hand = [_card(13, "Hearts", "ink"), _card(13, "Clubs", "gold")]
	deal.hand[0].fortune = -1
	deal.hand[1].fortune = 6
	var result := deal._deduct_turn_deadwood()
	assert_eq(result.deadwood, 0)
	assert_eq(result.deadwood_penalty, 13)
	assert_eq(result.black_ink_profit, 13)
	assert_eq(deal.wallet.balance_vnd, 100_000)
	assert_eq(deal.wallet.journal[-2].reason, "deadwood")
	assert_eq(deal.wallet.journal[-1].reason, "black_ink")
	assert_eq(deal.wallet.journal[-1].amount_vnd, VndWallet.points_to_vnd(13))

func test_mom_multiplies_normal_cost_without_multiplying_ink_profit() -> void:
	var deal := DealState.new()
	deal.start_deal(102)
	for _turn in 4: deal.discard_card(deal.hand[0])
	deal.wallet.reset(0)
	deal.phase_metrics.raw_gross = 0
	deal.phase_metrics.deadwood_total = 0
	deal.phase_new_meld_count = 0
	deal.hand = [_card(13, "Hearts", "ink"), _card(4, "Clubs", "normal")]
	deal.hand[0].fortune = -6
	var result: Dictionary = deal.settle_phase().phase_resolution
	assert_true(result.mom)
	assert_eq(result.deadwood_multiplier, 2)
	assert_eq(result.deadwood_penalty, 8)
	assert_eq(result.black_ink_profit, 78)
	assert_eq(result.turn_deadwood, -70)
	assert_eq(deal.wallet.balance_vnd, VndWallet.points_to_vnd(70))

func test_black_ink_profit_obeys_boss_owned_income_hooks() -> void:
	var deal := DealState.new()
	deal.start_deal(103)
	deal.wallet.reset(0)
	deal.zodiac_boss.configure("pig",2,5678)
	deal.zodiac_boss.begin_phase(deal)
	deal.zodiac_boss.data.target_vnd = 1_000_000
	deal.hand = [_card(13,"Hearts","ink")]
	deal.hand[0].fortune = -6
	deal._deduct_turn_deadwood()
	assert_eq(deal.zodiac_boss.data.progress_vnd,78_000)
	assert_eq(deal.zodiac_boss.data.pool_vnd,23_400)
	assert_eq(deal.wallet.balance_vnd,54_600)
	assert_eq(deal.wallet.journal[0].reason,"black_ink")
	assert_eq(deal.wallet.journal[1].reason,"zodiac:pig:siphon")

func test_negative_identity_is_bounded_same_color_and_keeps_printed_value() -> void:
	var card := _card(8)
	card.negative = true
	assert_eq(card.meld_rank_options(), [7, 8, 9])
	assert_eq(card.meld_suit_options(), ["Hearts", "Diamonds"])
	assert_true(card.can_represent(7, "Diamonds"))
	assert_false(card.can_represent(7, "Spades"))
	assert_false(card.can_represent(6, "Hearts"))
	assert_eq(card.score_value(), 8)
	assert_eq(card.rank, "8")
	assert_eq(card.suit, "Hearts")
	for rank in [1, 13]:
		var boundary := _card(rank, "Clubs")
		boundary.negative = true
		assert_eq(boundary.meld_rank_options(), [1, 2] if rank == 1 else [12, 13])
		assert_false(boundary.can_represent(13 if rank == 1 else 1))

func test_negative_glitch_melds_and_extensions_use_distinct_physical_cards() -> void:
	var negative := _card(8, "Hearts", "negative")
	negative.negative = true
	var seven := _card(7, "Diamonds", "seven")
	var nine := _card(9, "Diamonds", "nine")
	assert_true(MeldRules.is_run([seven, negative, nine]))
	assert_eq(MeldRules.run_identities([seven, negative, nine])[negative.unique_id], {"rank": 8, "suit": "Diamonds"})
	assert_true(MeldRules.is_set([seven, negative, _card(7, "Spades", "other")]))
	var glitch := _card(1, "Spades", "glitch")
	glitch.liquid = true
	glitch.negative = true
	assert_eq(glitch.jackpot_state(), "GLITCH")
	assert_eq(glitch.echo_count(), 1)
	assert_eq(glitch.meld_rank_options().size(), 13)
	assert_eq(glitch.meld_suit_options().size(), 4)
	assert_true(MeldRules.is_run([seven, glitch, nine]))
	assert_false(MeldRules.is_run([glitch, glitch, seven]))
	assert_false(MeldRules.is_set([glitch, glitch, seven]))
	assert_true(MeldRules.can_extend([seven, negative, nine], [glitch], MeldRules.TYPE_RUN))
	assert_eq(glitch.rank_index, 1)
	assert_eq(glitch.base_value, 1)

func test_matching_backtracks_and_perfected_run_accepts_wild_identity() -> void:
	var first := _card(2, "Hearts", "flex")
	first.negative = true
	var fixed := _card(2, "Hearts", "fixed")
	var three := _card(3, "Hearts", "three")
	var identities := MeldRules.run_identities([first, fixed, three])
	assert_eq(identities[first.unique_id].rank, 1)
	assert_eq(identities[fixed.unique_id].rank, 2)
	var all: Array[CardData] = []
	for rank in range(1, 14):
		var card := _card(rank, "Hearts", "full_%d" % rank)
		if rank == 8:
			card.apply_rank("A", 1)
			card.liquid = true
			card.negative = true
		all.append(card)
	assert_true(MeldRules.is_run(all))
	assert_true(ScoringPipeline.is_perfected_run(all, MeldRules.TYPE_RUN))
	assert_eq(MeldRules.run_identities(all)["full_8"].rank, 8)

func test_jackpot_flags_coexist_with_fortune_and_echo_is_finite() -> void:
	for fortune in [6, -6, 0]:
		var cards := _kings(3)
		cards[0].fortune = fortune
		cards[0].add_jackpot(CardData.JACKPOT_NEGATIVE)
		cards[0].add_jackpot(CardData.JACKPOT_LIQUID)
		assert_false(cards[0].add_jackpot(CardData.JACKPOT_LIQUID))
		assert_eq(cards[0].fortune, fortune)
		var context := ScoringPipeline.new().preview_new_meld(cards, MeldRules.TYPE_SET, 1)
		assert_eq(context.scoring_passes.size(), 2)
		assert_eq(context.final_points, context.theoretical_score * 2)
		for scoring_pass in context.scoring_passes:
			var sum := 0
			for hit in scoring_pass.presentation_hits: sum += int(hit.points)
			assert_eq(sum, scoring_pass.final_points)

func test_all_64_readings_target_physical_cards_and_preserve_actual_identity() -> void:
	for bits in 64:
		var service := GieoQueService.new()
		service.set_seed_value(910 + bits)
		var lines: Array[String] = []
		for bit in 6: lines.append("P" if bits & (1 << bit) else "N")
		assert_true(service.cast(lines).ok)
		assert_true(service.resolved_targets.is_empty())
		assert_true(service.accept().ok)
		var jackpot: bool = not String(service.current_result.jackpot).is_empty()
		if jackpot:
			assert_eq(service.state, GieoQueService.STATE_TARGET_SELECTION)
			assert_true(service.choose_target(service.persistent_deck[19].unique_id).ok)
		else:
			assert_eq(service.state, GieoQueService.STATE_TARGET_REVEAL)
			assert_eq(service.resolved_targets.size(), 1 if service.current_result.targeting == GieoQueService.TARGET_RANDOM_ONE else 3)
			if service.current_result.targeting == GieoQueService.TARGET_CONSECUTIVE_3:
				var ranks := service.resolved_targets.map(func(c): return c.rank_index)
				ranks.sort()
				assert_eq(ranks, [ranks[0], ranks[0] + 1, ranks[0] + 2])
			if service.current_result.targeting == GieoQueService.TARGET_RANDOM_SAME_SUIT_3:
				assert_true(service.resolved_targets.all(func(c): return c.suit == service.resolved_targets[0].suit))
			assert_true(service.apply_resolved_targets().ok)
		var ids := {}
		for change in service.last_transformations:
			assert_false(ids.has(change.card.unique_id))
			ids[change.card.unique_id] = true
			assert_eq(change.before.rank, change.after.rank)
			assert_eq(change.before.suit, change.after.suit)
			assert_eq(change.card.fortune, service.current_result.fortune_delta)
			assert_eq(change.card.liquid, jackpot and bits == 63)
			assert_eq(change.card.negative, jackpot and bits == 0)
		assert_true(service.finish_transformation().ok)

func test_exact_jackpot_picker_and_opposite_property_produce_glitch() -> void:
	for positive in [true, false]:
		var service := GieoQueService.new()
		var card := service.persistent_deck[31]
		card.add_jackpot(CardData.JACKPOT_NEGATIVE if positive else CardData.JACKPOT_LIQUID)
		assert_true(service.cast(_lines("PPPPPP" if positive else "NNNNNN")).ok)
		assert_true(service.accept().ok)
		assert_false(service.choose_target("not_owned").ok)
		assert_true(service.choose_target(card.unique_id).ok)
		assert_eq(service.resolved_targets, [card])
		assert_eq(card.fortune, 3 if positive else -3)
		assert_true(card.is_glitch())

func test_expanded_duplicates_and_target_query_use_actual_identity() -> void:
	var service := GieoQueService.new()
	for card in service.persistent_deck: card.transformation_locked = true
	var trio: Array[CardData] = [_card(7, "Hearts", "extra_7"), _card(8, "Hearts", "extra_8"), _card(9, "Hearts", "extra_9")]
	trio[1].liquid = true
	trio[1].negative = true
	service.persistent_deck.append_array(trio)
	service.persistent_deck.append(_card(8, "Hearts", "extra_duplicate"))
	assert_true(service.cast(_lines("PPNPPP")).ok)
	assert_true(service.accept().ok)
	assert_eq(service.resolved_targets.size(), 3)
	assert_true(service.apply_resolved_targets().ok)
	assert_eq(service.persistent_deck.size(), 56)
	var impossible := GieoQueService.new()
	for card in impossible.persistent_deck: card.transformation_locked = true
	trio = [_card(1, "Hearts", "one"), _card(7, "Diamonds", "seven"), _card(13, "Clubs", "king")]
	for card in trio: card.liquid = true; card.negative = true
	impossible.persistent_deck.append_array(trio)
	assert_true(impossible.cast(_lines("PPNPPP")).ok)
	assert_false(impossible.accept().ok)
	assert_eq(impossible.state, GieoQueService.STATE_RESULT)
	assert_true(impossible.refuse().ok)

func test_invalid_reading_and_busy_input_cannot_charge_or_double_apply() -> void:
	var service := GieoQueService.new()
	assert_false(service.cast(_lines("PPPXPP")).ok)
	assert_false(service.free_cast_used_today)
	assert_true(service.cast(_lines("PPNPPN")).ok)
	assert_true(service.accept().ok)
	assert_false(service.cast().ok)
	assert_true(service.apply_resolved_targets().ok)
	var card := service.resolved_targets[0]
	var revision := card.mutation_revision
	assert_false(service.apply_resolved_targets().ok)
	assert_eq(card.mutation_revision, revision)
	assert_false(service.refuse().ok)

func test_paid_reading_is_coherent_during_wallet_signals_and_reentry_is_rejected() -> void:
	var service := GieoQueService.new()
	service.wallet.reset(100_000)
	service.cast(_lines("PNPPPN"))
	var observed: Array[Dictionary] = []
	var observer := func(_before:int,_after:int,_delta:int,reason:String):
		if reason != "gieo_que_cast": return
		observed.append({"lines":service.current_result.lines.duplicate(),"state":service.state,"paid":service.paid_cast_count_today,"balance":service.wallet.balance_vnd,"reentry":service.cast().ok,"accept":service.accept().ok})
	service.wallet.balance_changed.connect(observer)
	assert_true(service.reroll(_lines("NPNNNP")).ok)
	service.wallet.balance_changed.disconnect(observer)
	assert_eq(observed.size(),1)
	assert_eq(observed[0].lines,_lines("NPNNNP"))
	assert_eq(observed[0].state,GieoQueService.STATE_RESULT)
	assert_eq(observed[0].paid,1)
	assert_eq(observed[0].balance,90_000)
	assert_false(observed[0].reentry)
	assert_false(observed[0].accept)

func test_daily_free_cast_and_paid_growth_reset_only_on_new_day() -> void:
	var service := GieoQueService.new()
	service.wallet.reset(100_000)
	assert_eq(service.current_pull_cost(), 0)
	assert_true(service.cast(_lines("PNPPPN")).ok)
	assert_eq(service.wallet.balance_vnd, 100_000)
	assert_eq(service.current_pull_cost(), 10_000)
	assert_true(service.reroll(_lines("NPNPPN")).ok)
	assert_eq(service.wallet.balance_vnd, 90_000)
	assert_eq(service.current_pull_cost(), 20_000)
	assert_true(service.refuse().ok)
	assert_eq(service.current_pull_cost(), 20_000)
	service.begin_day(1)
	assert_eq(service.current_pull_cost(), 0)
	assert_eq(service.paid_cast_count_today, 0)

func test_daily_free_reading_stays_consumed_across_morning_noon_afternoon() -> void:
	var campaign := CampaignManager.new()
	campaign.start_campaign(false)
	campaign.wallet.reset(100_000)
	campaign._enter_phase(CampaignManager.CampaignPhase.MORNING_EVENT)
	assert_true(campaign.gieo_que.cast(_lines("PNPPPN")).ok)
	campaign.gieo_que.refuse()
	var cost := campaign.gieo_que.current_pull_cost()
	campaign._enter_phase(CampaignManager.CampaignPhase.NOON_EVENT)
	assert_eq(campaign.gieo_que.current_pull_cost(), cost)
	campaign._enter_phase(CampaignManager.CampaignPhase.AFTERNOON_EVENT)
	assert_eq(campaign.gieo_que.current_pull_cost(), cost)

func test_wild_probability_does_not_count_one_physical_glitch_as_multiple_outs() -> void:
	var held: Array[CardData] = [_card(7,"Hearts","held")]
	var glitch := _card(1,"Spades","wild")
	glitch.liquid = true
	glitch.negative = true
	var pool: Array[CardData] = [glitch,_card(8,"Hearts","eight"),_card(9,"Hearts","nine"),_card(13,"Clubs","miss")]
	var slots: Array[int] = [7,8,9]
	assert_eq(MeldProbabilityAdvisor.completion_probability(held,pool,1,slots,"Hearts"),0.0)
	assert_eq(MeldProbabilityAdvisor.completion_probability(held,pool,2,slots,"Hearts"),0.5)
	var analysis := MeldProbabilityAdvisor.analyze(held,pool,[],2)
	var found := false
	for candidate in analysis.candidates:
		if candidate.label_args == ["7","9","H"]:
			assert_eq(candidate.probability,0.5)
			found = true
	assert_true(found)

func test_negative_glitch_advice_finds_live_legal_play_without_changing_rng() -> void:
	var deal := DealState.new()
	deal.start_deal(609)
	deal.hand = [_card(7,"Diamonds","seven"),_card(8,"Hearts","negative"),_card(9,"Diamonds","nine"),_card(13,"Clubs","discard")]
	deal.hand[1].negative = true
	deal.state = DealState.STATE_FINAL_COMMIT_WINDOW
	var rng_state := deal.deck._rng.state
	var advice := deal.queries.hand_advice()
	assert_eq(advice.play.action,HandAdvisor.ACTION_NEW_MELD)
	assert_eq(deal.deck._rng.state,rng_state)
	assert_eq(advice.play.cards.size(),3)

func test_c2_targets_keep_selected_physical_cards_with_flexible_ranks() -> void:
	var deal := DealState.new()
	deal.start_deal(610)
	deal.current_drink_id = DrinkCatalog.C2_ICED_TEA
	deal.hand = [_card(8,"Hearts","selected"),_card(13,"Spades","glitch"),_card(10,"Clubs","ten"),_card(1,"Diamonds","miss")]
	deal.hand[0].negative = true
	deal.hand[1].liquid = true
	deal.hand[1].negative = true
	var selected: Array[CardData] = [deal.hand[0],deal.hand[2]]
	var targets := deal.drink_creation_target_ids(selected)
	assert_true(targets.has("glitch"))
	assert_false(targets.has("miss"))
	var completion := MeldRules.complete_run(deal.hand, selected, 8, 10)
	assert_eq(completion.size(),3)
	assert_true(completion.has(selected[0]) and completion.has(selected[1]))
	assert_true(completion.has(deal.hand[1]))
	assert_true(deal.can_create_meld(completion,true))
	deal.zodiac_boss.locked_ids.append("glitch")
	assert_false(deal.drink_creation_target_ids(selected).has("glitch"))

func test_deal_copy_keeps_permanent_state_without_temporary_modifier_leak() -> void:
	var original := _card(13)
	original.fortune = -6
	original.liquid = true
	original.negative = true
	original.shiny = true
	original.value_modifiers.append(99)
	var copied := original.copy_for_deal()
	assert_eq(copied.unique_id, original.unique_id)
	assert_eq(copied.fortune, -6)
	assert_true(copied.is_glitch())
	assert_true(copied.shiny)
	assert_eq(copied.score_value(), 13)
	copied.adjust_fortune(3)
	assert_eq(original.fortune, -6)

func test_slot_machine_rebuild_keeps_authoritative_reels_and_card_materials() -> void:
	var service := GieoQueService.new()
	var panel := GieoQuePanel.new()
	panel.configure(service)
	assert_false(panel.is_interaction_locked())
	assert_true(panel.find_child("SlotMachineArt", true, false) is TextureRect)
	assert_true(panel.find_child("OracleLever", true, false) is Button)
	assert_eq(panel._reels.size(), 6)
	var lines := _lines("PNPPNN")
	service.cast(lines)
	panel._rebuild()
	for tick in 40: panel._set_reel_travel(float(tick * 93), tick % 6)
	assert_eq(service.current_result.lines, lines)
	assert_eq(panel.displayed_reel_values(), lines)
	assert_true(panel.is_interaction_locked())
	service.accept()
	service.apply_resolved_targets()
	service.finish_transformation()
	panel._rebuild()
	assert_true(panel.find_child("SlotMachineArt", true, false) is TextureRect)
	assert_eq(panel._find_controls_with_meta(panel, &"gieo_transform_row").size(), service.last_transformations.size())
	assert_false(panel.is_interaction_locked())
	panel.free()

func test_v3_save_keeps_expanded_deck_physical_refs_pending_rng_and_fortunes() -> void:
	var deal := DealState.new()
	var campaign := CampaignManager.new(deal.wallet)
	campaign.start_campaign(false, "fortune-save")
	deal.set_campaign_deck(campaign.gieo_que.persistent_deck)
	deal.start_deal(601)
	var service := campaign.gieo_que
	var extra := _card(8, "Hearts", "expanded_saved")
	extra.fortune = -6
	extra.liquid = true
	extra.negative = true
	service.persistent_deck.append(extra)
	service.wallet.reset(100_000)
	service.cast(_lines("PPPPPP"))
	service.accept()
	var save := RunSave.new("user://fortune_v3_test.save")
	assert_true(save.save_run(campaign, deal), save.error)
	var restored_deal := DealState.new()
	var restored := CampaignManager.new(restored_deal.wallet)
	assert_true(save.restore(save.load_run(), restored, restored_deal), save.error)
	assert_eq(restored.gieo_que.persistent_deck.size(), 53)
	assert_eq(restored.gieo_que._rng.state, service._rng.state)
	assert_eq(restored.gieo_que.current_pull_cost(), service.current_pull_cost())
	assert_true(restored.gieo_que.choose_target(extra.unique_id).ok)
	assert_eq(restored.gieo_que.resolved_targets[0], restored.gieo_que.persistent_deck[-1])
	assert_eq(restored.gieo_que.persistent_deck[-1].fortune, -3)
	assert_true(restored.gieo_que.persistent_deck[-1].is_glitch())
	assert_true(save.save_run(restored, restored_deal), save.error)
	var data := save.load_run()
	assert_eq(data.gieo.last_transformations[0].card, data.gieo.persistent_deck[-1])
	assert_eq(data.gieo.resolved_targets[0], data.gieo.persistent_deck[-1])

func test_v2_save_migration_keeps_rank_suit_shiny_seals_and_physical_id() -> void:
	var deal := DealState.new()
	var campaign := CampaignManager.new(deal.wallet)
	campaign.start_campaign(false, "fortune-legacy")
	deal.start_deal(602)
	var card := campaign.gieo_que.persistent_deck[0]
	card.apply_rank("K", 13)
	card.apply_suit("Hearts")
	card.shiny = true
	card.transformation_locked = true
	var save := RunSave.new("user://fortune_v2_test.save")
	var encoded: Variant = save._encode(save.capture(campaign, deal))
	for record: Dictionary in save._records:
		if record.type != "CardData": continue
		var fields: Dictionary = save._decode(record.fields)
		fields.erase("fortune")
		fields.erase("liquid")
		fields.erase("negative")
		fields["gieo_properties"] = ["GOLD_SET", "MELD_RETRIGGER"] if fields.unique_id == card.unique_id else []
		record.fields = save._encode(fields)
	var bytes := var_to_bytes({"root": encoded, "objects": save._records})
	var file := FileAccess.open(save.path, FileAccess.WRITE)
	file.store_var({"version": 2, "payload": bytes, "sha256": RunSave.payload_digest(bytes)}, false)
	file.close()
	var data := save.load_run()
	assert_false(data.is_empty(), save.error)
	var migrated: CardData = data.gieo.persistent_deck[0]
	assert_eq(migrated.unique_id, card.unique_id)
	assert_eq(migrated.rank, "K")
	assert_eq(migrated.suit, "Hearts")
	assert_eq(migrated.fortune, 2)
	assert_true(migrated.liquid)
	assert_false(migrated.negative)
	assert_true(migrated.shiny)
	assert_true(migrated.transformation_locked)

func test_legacy_pending_reading_never_reapplies_committed_transformation() -> void:
	var service := GieoQueService.new()
	var card := service.persistent_deck[0]
	card.fortune = 2
	card.liquid = true
	service.state = GieoQueService.STATE_TRANSFORM
	service.current_result = {"lines": ["D", "D", "D", "D", "D", "D"], "price_vnd": 10_000, "free_pull": false}
	service.resolved_targets = [card]
	service.last_transformations = [{"card": card, "before": card.permanent_snapshot(), "after": card.permanent_snapshot()}]
	service.migrate_pending_reading()
	assert_eq(card.fortune, 2)
	assert_eq(service.state, GieoQueService.STATE_TRANSFORM)
	assert_eq(service.current_result.fortune_delta, 3)
	assert_eq(service.current_result.price_vnd, 10_000)

func _card(rank: int, suit: String = "Hearts", id: String = "test") -> CardData:
	return CardData.new(id, DeckManager.RANKS[rank - 1], rank, suit, rank)

func _kings(count: int) -> Array[CardData]:
	var cards: Array[CardData] = []
	for index in count: cards.append(_card(13, DeckManager.SUITS[index % 4], "king_%d" % index))
	return cards

func _lines(pattern: String) -> Array[String]:
	var result: Array[String] = []
	for line in pattern: result.append(line)
	return result
