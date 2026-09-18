@tool
extends McpTestSuite

func suite_name() -> String:
	return "relics"

func _cards(count: int, kind: String = "set", suit: String = "Spades") -> Array[CardData]:
	var cards: Array[CardData] = []
	for i in count:
		var rank := 4 + i if kind == "run" else 9
		cards.append(CardData.new("%s_%s_%d" % [kind, suit, i], str(rank), rank, suit, rank))
	return cards

func _deal(ids: Array, cards: Array[CardData]) -> DealState:
	var deal := DealState.new()
	deal.deck.reset(42)
	deal.hand.assign(cards)
	deal.hand.append(CardData.new("spare", "K", 13, "Clubs", 13))
	for id: String in ids:
		deal.relics.acquire(id)
		deal.relics.equip(id)
	return deal

func _bonus(context: ScoringContext, id: String) -> int:
	var total := 0
	for bonus in context.relic_bonuses:
		if bonus.id == id:
			total += int(bonus.points)
	return total

func _creation(id: String, count: int, kind: String = "set", suit: String = "Spades") -> ScoringContext:
	var cards := _cards(count, kind, suit)
	var deal := _deal([id], cards)
	var result := deal.create_meld(cards)
	assert_true(result.ok)
	return result.context

func test_hair_clip_once_with_native_and_gieo_retriggers() -> void:
	var cards := _cards(4)
	cards[0].add_gieo_property(GieoQueService.PROPERTY_MELD_RETRIGGER)
	var deal := _deal(["hair_clip"], cards)
	var context: ScoringContext = deal.create_meld(cards).context
	assert_eq(context.scoring_passes.size(), 3)
	assert_eq(context.relic_bonuses.size(), 1)
	assert_eq(_bonus(context, "hair_clip"), 30)
	assert_eq(_bonus(_creation("hair_clip", 3, "run"), "hair_clip"), 0)

func test_comb_counts_only_new_run_cards() -> void:
	assert_eq(_bonus(_creation("comb", 3, "run"), "comb"), 24)
	assert_eq(_bonus(_creation("comb", 5, "run"), "comb"), 40)
	assert_eq(_bonus(_creation("comb", 4), "comb"), 0)

func test_rubber_band_once_per_extension_with_multiple_passes() -> void:
	var cards := _cards(4)
	cards[0].add_gieo_property(GieoQueService.PROPERTY_MELD_RETRIGGER)
	var deal := _deal(["rubber_band"], cards)
	var created := deal.create_meld(cards.slice(0, 3))
	assert_eq(created.context.relic_bonuses.size(), 0)
	var context: ScoringContext = deal.extend_meld(created.meld_id, [cards[3]]).context
	assert_eq(context.scoring_passes.size(), 3)
	assert_eq(context.relic_bonuses.size(), 1)
	assert_eq(_bonus(context, "rubber_band"), 20)

func test_gum_counts_actions_not_cards_and_tracks_melds_independently() -> void:
	var cards := _cards(7)
	var other := _cards(4, "run", "Hearts")
	var deal := _deal(["chewing_gum"], cards + other)
	var first := deal.create_meld(cards.slice(0, 3))
	var second := deal.create_meld(other.slice(0, 3))
	assert_eq(_bonus(deal.extend_meld(first.meld_id, [cards[3]]).context, "chewing_gum"), 10)
	assert_eq(_bonus(deal.extend_meld(first.meld_id, cards.slice(4, 6)).context, "chewing_gum"), 20)
	assert_eq(_bonus(deal.extend_meld(second.meld_id, [other[3]]).context, "chewing_gum"), 10)
	assert_eq(_bonus(deal.extend_meld(first.meld_id, [cards[6]]).context, "chewing_gum"), 30)

func test_gum_resets_at_phase_boundary() -> void:
	var cards := _cards(5)
	var deal := _deal(["chewing_gum"], cards)
	var created := deal.create_meld(cards.slice(0, 3))
	deal.extend_meld(created.meld_id, [cards[3]])
	deal.state = DealState.STATE_PHASE_CHOICE
	assert_true(deal.choose_phase_two(false).ok)
	deal.hand.assign([cards[4], CardData.new("spare", "K", 13, "Clubs", 13)])
	assert_eq(_bonus(deal.extend_meld(created.meld_id, [cards[4]]).context, "chewing_gum"), 10)

func test_sunflower_pays_per_card_for_sets_and_runs() -> void:
	assert_eq(_bonus(_creation("sunflower_seeds", 3), "sunflower_seeds"), 15)
	assert_eq(_bonus(_creation("sunflower_seeds", 5, "run"), "sunflower_seeds"), 25)

func test_toothpicks_exactly_three_new_cards() -> void:
	assert_eq(_bonus(_creation("toothpicks", 3), "toothpicks"), 20)
	assert_eq(_bonus(_creation("toothpicks", 3, "run"), "toothpicks"), 20)
	assert_eq(_bonus(_creation("toothpicks", 4), "toothpicks"), 0)

func test_hard_candy_new_four_or_more() -> void:
	assert_eq(_bonus(_creation("hard_candy", 3), "hard_candy"), 0)
	assert_eq(_bonus(_creation("hard_candy", 4), "hard_candy"), 50)
	assert_eq(_bonus(_creation("hard_candy", 5, "run"), "hard_candy"), 50)

func test_creation_only_relics_do_not_trigger_on_three_to_four_extension() -> void:
	var cards := _cards(4)
	var deal := _deal(["hair_clip", "hard_candy", "buttons", "toothpicks"], cards)
	var created := deal.create_meld(cards.slice(0, 3))
	assert_eq(deal.extend_meld(created.meld_id, [cards[3]]).context.relic_bonuses.size(), 0)

func test_black_requires_every_card_black() -> void:
	for suit in ["Spades", "Clubs"]:
		assert_eq(_bonus(_creation("sunglasses", 3, "run", suit), "sunglasses"), 40)
	var cards := _cards(3)
	cards[1].suit = "Clubs"
	var deal := _deal(["sunglasses"], cards)
	assert_eq(_bonus(deal.create_meld(cards).context, "sunglasses"), 40)
	cards = _cards(3)
	cards[2].suit = "Hearts"
	deal = _deal(["sunglasses"], cards)
	assert_eq(deal.create_meld(cards).context.relic_bonuses.size(), 0)

func test_red_requires_every_card_red() -> void:
	for suit in ["Hearts", "Diamonds"]:
		assert_eq(_bonus(_creation("lipstick", 3, "run", suit), "lipstick"), 40)
	var cards := _cards(3, "set", "Hearts")
	cards[1].suit = "Diamonds"
	var deal := _deal(["lipstick"], cards)
	assert_eq(_bonus(deal.create_meld(cards).context, "lipstick"), 40)
	cards = _cards(3, "set", "Hearts")
	cards[2].suit = "Clubs"
	deal = _deal(["lipstick"], cards)
	assert_eq(deal.create_meld(cards).context.relic_bonuses.size(), 0)

func test_buttons_only_new_exactly_four_card_set() -> void:
	assert_eq(_bonus(_creation("buttons", 3), "buttons"), 0)
	assert_eq(_bonus(_creation("buttons", 4), "buttons"), 75)
	assert_eq(_bonus(_creation("buttons", 5), "buttons"), 0)
	assert_eq(_bonus(_creation("buttons", 4, "run"), "buttons"), 0)

func test_four_compatible_relics_stack_and_use_wallet_conversion() -> void:
	var cards := _cards(4)
	var deal := _deal(["hair_clip", "buttons", "hard_candy", "sunflower_seeds"], cards)
	var context: ScoringContext = deal.create_meld(cards).context
	assert_eq(context.relic_bonuses.size(), 4)
	var expected := context.final_points + 30 + 75 + 50 + 20
	assert_eq(deal.phase_metrics.raw_gross, expected)
	assert_eq(deal.wallet.balance_vnd, expected * deal.vnd_per_point)
	assert_eq(deal.get_meld(1).scored_points, ScoringPipeline.meld_value(cards))

func test_relics_leave_intrinsic_delta_and_all_passes_unchanged() -> void:
	var cards := _cards(4)
	cards[0].add_gieo_property(GieoQueService.PROPERTY_MELD_RETRIGGER)
	var baseline := _deal([], cards)
	var enhanced := _deal(["hair_clip", "buttons", "rubber_band", "chewing_gum"], cards)
	var plain := baseline.create_meld(cards.slice(0, 3))
	var with_relic := enhanced.create_meld(cards.slice(0, 3))
	assert_eq(plain.context.final_points, with_relic.context.final_points)
	assert_eq(baseline.get_meld(1).scored_points, enhanced.get_meld(1).scored_points)
	var a: ScoringContext = baseline.extend_meld(1, [cards[3]]).context
	var b: ScoringContext = enhanced.extend_meld(1, [cards[3]]).context
	assert_eq(a.base_extension_score, b.base_extension_score)
	assert_eq(a.theoretical_score, b.theoretical_score)
	assert_eq(a.final_points, b.final_points)
	assert_eq(a.scoring_passes.size(), b.scoring_passes.size())
	for index in a.scoring_passes.size():
		assert_eq(a.scoring_passes[index].final_points, b.scoring_passes[index].final_points)
		assert_eq(a.scoring_passes[index].trigger_origin, b.scoring_passes[index].trigger_origin)
		assert_eq(b.scoring_passes[index].relic_bonuses.size(), 0)

func test_inventory_rejects_fifth_unknown_and_duplicate_equipment() -> void:
	var runtime := RelicRuntime.new()
	assert_false(runtime.equip("hair_clip"))
	assert_false(runtime.acquire("unknown"))
	for id: String in RelicCatalog.DEFINITIONS:
		assert_true(runtime.acquire(id))
	for id in ["hair_clip", "comb", "buttons", "rubber_band"]:
		assert_true(runtime.equip(id))
	assert_true(runtime.equip("hair_clip"))
	assert_false(runtime.equip("lipstick"))
	assert_eq(runtime.equipped.size(), 4)
	runtime.remove("comb")
	assert_true(runtime.equip("lipstick"))
	assert_eq(runtime.inventory.size(), 10)

func test_failed_actions_and_previews_do_not_trigger_or_advance_gum() -> void:
	var cards := _cards(4)
	var deal := _deal(["chewing_gum"], cards)
	deal.create_meld(cards.slice(0, 3))
	assert_false(deal.extend_meld(999, [cards[3]]).ok)
	deal.scoring.preview_extension(cards, "set", 81, 1, [cards[3]])
	assert_true(deal.relics.extension_counts.is_empty())
	assert_eq(deal.wallet.balance_vnd, 81 * deal.vnd_per_point)

func test_snapshot_preserves_inventory_and_phase_counters() -> void:
	var cards := _cards(4)
	var deal := _deal(["chewing_gum"], cards)
	deal.create_meld(cards.slice(0, 3))
	deal.extend_meld(1, [cards[3]])
	var snapshot := deal.snapshot_state()
	deal.relics.reset_run()
	deal.restore_snapshot(snapshot)
	assert_eq(deal.relics.equipped, ["chewing_gum"])
	assert_eq(deal.relics.extension_counts.get(1), 1)

func test_next_deal_preserves_equipment_and_resets_extension_counts() -> void:
	var deal := _deal(["chewing_gum"], [])
	deal.relics.extension_counts[1] = 5
	deal.start_deal(42)
	assert_eq(deal.relics.equipped, ["chewing_gum"])
	assert_true(deal.relics.extension_counts.is_empty())

func test_exhaustion_scoring_does_not_award_creation_or_extension_relics() -> void:
	var cards := _cards(4)
	var deal := _deal(["hair_clip", "buttons", "rubber_band", "chewing_gum"], cards)
	var context := deal.scoring.score_meld_trigger(cards, "set", 1)
	assert_true(deal.relics.resolve(context, 1).is_empty())
	assert_true(deal.relics.extension_counts.is_empty())
