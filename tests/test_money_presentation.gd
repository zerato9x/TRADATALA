@tool
extends McpTestSuite


func suite_name() -> String:
	return "money_presentation"


func test_denominations_have_individual_bill_textures() -> void:
	assert_eq(MoneyPresentation.DENOMINATIONS.size(), 9)
	assert_eq(MoneyPresentation.DENOMINATION_TEXTURES.size(), 9)
	for denomination in MoneyPresentation.DENOMINATIONS:
		assert_true(MoneyPresentation.DENOMINATION_TEXTURES.has(denomination))
		var texture := MoneyPresentation.DENOMINATION_TEXTURES.get(denomination) as Texture2D
		assert_true(texture != null)
		assert_true(texture.resource_path.begins_with("res://assets/money/bill_"))


func test_greedy_breakdown_is_largest_first_and_exact() -> void:
	var breakdown := MoneyPresentation.denomination_breakdown(387_000)
	var expected := [200_000, 100_000, 50_000, 20_000, 10_000, 5_000, 2_000]
	assert_eq(breakdown.size(), expected.size())
	var reconstructed := 0
	for index in breakdown.size():
		assert_eq(int(breakdown[index]["denomination"]), expected[index])
		reconstructed += int(breakdown[index]["denomination"]) * int(breakdown[index]["count"])
	assert_eq(reconstructed, 387_000)


func test_repeated_notes_are_one_logical_bundle() -> void:
	var breakdown := MoneyPresentation.denomination_breakdown(2_500_000)
	assert_eq(breakdown.size(), 1)
	assert_eq(int(breakdown[0]["denomination"]), 500_000)
	assert_eq(int(breakdown[0]["count"]), 5)


func test_negative_and_zero_wallets_create_no_cash_objects() -> void:
	var presentation := MoneyPresentation.new()
	assert_eq(presentation.wallet_visual_object_count(0), 0)
	assert_eq(presentation.wallet_visual_object_count(-75_000), 0)
	assert_true(presentation.wallet_visual_object_count(987_654_000) <= MoneyPresentation.MAX_WALLET_OBJECTS)
	presentation.free()


func test_money_resolution_uses_one_shared_flight_speed() -> void:
	assert_eq(MoneyPresentation.MONEY_FLIGHT_DURATION, 0.48)
	assert_true(MoneyPresentation.MONEY_FLIGHT_DURATION > 0.20)


func test_card_echo_precedes_next_physical_card_and_receipts_conserve_score() -> void:
	var cards: Array[CardData] = [
		CardData.new("king_a", "K", 13, "Hearts", 13),
		CardData.new("king_b", "K", 13, "Clubs", 13),
		CardData.new("king_c", "K", 13, "Spades", 13),
	]
	cards[0].add_gieo_property(GieoQueService.PROPERTY_GOLD_MAKING_PHOM)
	cards[0].add_gieo_property(GieoQueService.PROPERTY_MELD_RETRIGGER)
	cards[1].add_gieo_property(GieoQueService.PROPERTY_MELD_RETRIGGER)
	var context := ScoringPipeline.new().preview_new_meld(cards, MeldRules.TYPE_SET, 1)
	assert_eq(context.final_points, 468)
	assert_eq(context.scoring_passes.size(), 3)
	assert_eq(context.scoring_passes[1].retrigger_source_id, "king_a")
	assert_eq(context.scoring_passes[2].retrigger_source_id, "king_b")
	for scoring_pass: ScoringContext in context.scoring_passes:
		var hits := scoring_pass.presentation_hits
		assert_eq(hits.size(), 4)
		assert_eq(hits[0]["card_id"], "king_a")
		assert_eq(hits[1]["card_id"], "king_a")
		assert_eq(hits[1]["kind"], "card_retrigger")
		assert_eq(hits[1]["points"], 39)
		assert_eq(hits[2]["card_id"], "king_b")
		_assert_receipt_total(scoring_pass)
	cards[0].apply_rank("A", 1)
	assert_eq(context.scoring_passes[0].presentation_hits[0]["points"], 39)


func test_extension_flow_is_card_scoped_then_full_run_replay() -> void:
	var cards: Array[CardData] = []
	for rank in range(4, 8):
		cards.append(CardData.new("run_%d" % rank, str(rank), rank, "Clubs", rank))
	cards[-1].add_gieo_property(GieoQueService.PROPERTY_GOLD_EXTEND)
	cards[0].add_gieo_property(GieoQueService.PROPERTY_MELD_RETRIGGER)
	var context := ScoringPipeline.new().preview_extension(cards, MeldRules.TYPE_RUN, 45, 1, [cards[-1]])
	assert_eq(context.final_points, 187)
	assert_eq(context.scoring_passes.size(), 2)
	var hits: Array = context.scoring_passes[0].presentation_hits
	assert_eq(hits.size(), 3)
	assert_eq(hits[0]["card_id"], "run_7")
	assert_eq(hits[1]["card_id"], "run_7")
	assert_eq(hits[1]["property"], GieoQueService.PROPERTY_GOLD_EXTEND)
	assert_eq(hits[2]["kind"], "meld_delta")
	assert_eq(hits[2]["points"], 15)
	assert_eq(context.scoring_passes[1].presentation_hits.size(), 5)
	assert_eq(context.scoring_passes[1].retrigger_source_id, "run_4")
	for scoring_pass: ScoringContext in context.scoring_passes:
		_assert_receipt_total(scoring_pass)


func test_exhaustion_native_and_gieo_passes_do_not_reapply_making_echo() -> void:
	var cards: Array[CardData] = []
	for suit in ["Clubs", "Hearts", "Spades", "Diamonds"]:
		cards.append(CardData.new(suit, "K", 13, suit, 13))
	cards[0].add_gieo_property(GieoQueService.PROPERTY_GOLD_MAKING_PHOM)
	cards[0].add_gieo_property(GieoQueService.PROPERTY_MELD_RETRIGGER)
	var context := ScoringPipeline.new().score_meld_trigger(cards, MeldRules.TYPE_SET, 1)
	assert_eq(context.final_points, 624)
	assert_eq(context.scoring_passes.size(), 3)
	assert_eq(context.scoring_passes[1].trigger_origin, ScoringPipeline.TRIGGER_NATIVE_RETRIGGER)
	assert_eq(context.scoring_passes[2].retrigger_source_id, "Clubs")
	for scoring_pass: ScoringContext in context.scoring_passes:
		assert_eq(scoring_pass.presentation_hits.size(), 4)
		_assert_receipt_total(scoring_pass)


func test_receipt_adjustment_preserves_modifier_and_clamped_extension_totals() -> void:
	var cards: Array[CardData] = [
		CardData.new("a", "4", 4, "Clubs", 4),
		CardData.new("b", "5", 5, "Clubs", 5),
		CardData.new("c", "6", 6, "Clubs", 6),
	]
	var pipeline := ScoringPipeline.new()
	pipeline.add_modifier(func(context: ScoringContext): context.flat_adjustment_points = -200)
	var context := pipeline.preview_new_meld(cards, MeldRules.TYPE_RUN, 1)
	assert_eq(context.final_points, 0)
	_assert_receipt_total(context.scoring_passes[0])
	context = pipeline.preview_extension(cards, MeldRules.TYPE_RUN, 90, 1, [cards[-1]])
	assert_eq(context.final_points, 0)
	_assert_receipt_total(context.scoring_passes[0])


func test_scoring_accelerates_only_after_cards_have_triggered() -> void:
	for index in 3:
		assert_eq(MoneyPresentation.scoring_hit_interval(index), 0.36)
	var previous := MoneyPresentation.scoring_hit_interval(2)
	for index in range(3, 60):
		var interval := MoneyPresentation.scoring_hit_interval(index)
		assert_true(interval <= previous)
		assert_true(interval >= 0.045)
		previous = interval
	assert_true(MoneyPresentation.scoring_hit_interval(10) < 0.20)
	assert_eq(MoneyPresentation.scoring_hit_interval(1000), 0.045)

func _assert_receipt_total(context: ScoringContext) -> void:
	var points := 0
	for hit in context.presentation_hits:
		points += int(hit["points"])
	assert_eq(points, context.final_points)


func test_export_font_covers_currency_and_negative_sign() -> void:
	var font := PresentationTheme.official_font()
	assert_true(font.has_char(0x20ab))
	assert_true(font.has_char(0x2d))
	assert_true(font.has_char(0x2212))
	assert_eq(VndWallet.format_vnd(-12000), "−12.000 VNĐ")
