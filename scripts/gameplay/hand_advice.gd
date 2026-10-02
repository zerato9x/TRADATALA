class_name HandAdvice
extends RefCounted
## Pure counterfactual analysis. Neither pile order nor RNG is consulted.

static func describe(row: Dictionary, last_call: bool = false) -> String:
	var text := GameGlossary.words("Keep %d/100 · relative to this hand. Lower is a better discard.", "Giữ %d/100 · so trong tay này. Thấp hơn là nên bỏ hơn.") % row.get("keep_score", 100)
	if row.get("locked", false): text += "\n" + GameGlossary.words("Locked this turn; Strawy cannot discard it.", "Đang bị khóa; Strawy không thể bỏ lá này.")
	elif row.get("protected", false): text += "\n" + GameGlossary.words("Preserved for a legal Meld/Extend.", "Giữ cho nước Hạ/Ghép hợp lệ.")
	if last_call or row.get("draw_count", 0) == 0:
		text += "\n" + GameGlossary.words("No refill before settlement. Consider your available plays and deadwood.", "Không bù bài trước khi chốt. Xem nước hợp lệ và bài rời.")
	var target: Dictionary = row.get("target", {})
	if not target.is_empty():
		text += "\n" + GameGlossary.words("After this discard: %s · %.3f%% in %d refill cards.", "Sau khi bỏ: %s · %.3f%% trong %d lá bù.") % [MeldProbabilityAdvisor.localized_label(target), row["probability"] * 100.0, row["draw_count"]]
	if not row.get("second_id", "").is_empty():
		text += "\n" + GameGlossary.words("Assumes Trà Đá's extra discard; no refill between the two discards.", "Tính cả lần bỏ thêm của Trà Đá; không bù bài giữa hai lần bỏ.")
	return text

static func signature(deal: DealState) -> int:
	var cards: Array = []
	for pile in [deal.hand, deal.deck.draw_pile, deal.deck.discard_pile, deal.recyclable_spent_cards]:
		var row: Array = []
		for card: CardData in pile:
			row.append([card.unique_id, card.rank_index, card.suit, card.score_value(), card.gieo_properties, card.enhancements, card.shiny])
		row.sort_custom(func(a, b): return a[0] < b[0])
		cards.append(row)
	var table: Array = []
	for meld: MeldState in deal.melds:
		table.append([meld.meld_id, meld.meld_type, meld.run_compatibility, meld.scored_points, meld.cards.map(func(c): return [c.unique_id, c.rank_index, c.suit, c.score_value(), c.gieo_properties, c.enhancements])])
	var locked: Array = deal.zodiac_boss.locked_ids.duplicate()
	locked.sort()
	return hash([cards, table, locked, deal.state, deal.current_phase, deal.discard_count, deal.current_drink_id,
		deal.tra_da_extra_discard_pending, deal.tra_da_used_this_turn, deal.phase_new_meld_count,
		deal.discard_history.map(func(r): return [r.card.unique_id, r.kind]),
		deal.zodiac_boss.snapshot(), deal.boss_melds.map(func(m): return [m.meld_id, m.cards.map(func(c): return c.unique_id)]), deal.relics.snapshot(), TranslationServer.get_locale()])

static func analyze(deal: DealState) -> Dictionary:
	var result := {"play": deal.recommend_action(), "discard_id": "", "extra_action": "none", "by_card": {}, "reasoning": "", "target_odds": 0.0}
	var legal := deal.legal_action_card_ids()
	var protected_ids: Dictionary = legal["meld"].duplicate()
	protected_ids.merge(legal["extend"])
	var choices: Array[Dictionary] = []
	var can_discard := deal.state == DealState.STATE_ACTIVE
	var has_unprotected := deal.hand.any(func(c): return not deal.zodiac_boss.is_locked(c) and not protected_ids.has(c.unique_id))
	for card: CardData in deal.hand:
		var remaining: Array[CardData] = deal.hand.duplicate()
		remaining.erase(card)
		var row := _outcome(deal, remaining, card, null)
		row["card_id"] = card.unique_id
		row["protected"] = protected_ids.has(card.unique_id)
		row["locked"] = deal.zodiac_boss.is_locked(card)
		row["eligible"] = deal.state in [DealState.STATE_ACTIVE, DealState.STATE_FINAL_COMMIT_WINDOW] and not row["locked"] and (not has_unprotected or not row["protected"])
		row["second_id"] = ""
		# The first discard does not refill while the optional Trà Đá choice is open.
		if can_discard and deal.current_drink_id == DrinkCatalog.TRA_DA and not deal.tra_da_extra_discard_pending and not remaining.is_empty():
			var unprotected_second := remaining.any(func(c): return not deal.zodiac_boss.is_locked(c) and not protected_ids.has(c.unique_id))
			for second: CardData in remaining:
				if deal.zodiac_boss.is_locked(second) or (unprotected_second and protected_ids.has(second.unique_id)): continue
				var after: Array[CardData] = remaining.duplicate()
				after.erase(second)
				var pair := _outcome(deal, after, card, second)
				if _better(pair, row) or (not row["second_id"].is_empty() and _equal(pair, row) and second.unique_id < row["second_id"]):
					for key in ["probability", "points", "deadwood", "target", "draw_count", "crosses_exhaustion"]: row[key] = pair[key]
					row["second_id"] = second.unique_id
		result["by_card"][card.unique_id] = row
		if row["eligible"]: choices.append(row)
	choices.sort_custom(func(a, b): return _better(a, b) if not _equal(a, b) else a["card_id"] < b["card_id"])
	var tiers: Array[Dictionary] = []
	for row in choices:
		if tiers.is_empty() or not _equal(tiers.back(), row): tiers.append(row)
		row["tier"] = tiers.size() - 1
	for row in result["by_card"].values():
		row["keep_score"] = 100
		if row["eligible"]:
			row["keep_score"] = 0 if tiers.size() <= 1 else roundi(100.0 * row["tier"] / (tiers.size() - 1))
	if not choices.is_empty():
		result["discard_id"] = choices[0]["card_id"] if can_discard else ""
		result["extra_action"] = "discard" if not choices[0]["second_id"].is_empty() else "skip"
		if deal.tra_da_extra_discard_pending:
			var skip := _outcome(deal, deal.hand, null, null)
			result["extra_action"] = "discard" if _better(choices[0], skip) else "skip"
			result["skip_outcome"] = skip
		result["target_odds"] = choices[0]["probability"]
		result["reasoning"] = describe(choices[0], deal.state == DealState.STATE_FINAL_COMMIT_WINDOW)
		if deal.tra_da_extra_discard_pending and result["extra_action"] == "skip":
			result["target_odds"] = result["skip_outcome"]["probability"]
			result["reasoning"] = GameGlossary.words("Skip the extra discard: retain this hand and refill %d cards. Best target completion: %.3f%%.", "Bỏ qua lần bỏ thêm: giữ tay này và bù %d lá. Tỷ lệ hoàn tất mục tiêu tốt nhất: %.3f%%.") % [result["skip_outcome"]["draw_count"], result["target_odds"] * 100.0]
	return result

static func _better(a: Dictionary, b: Dictionary) -> bool:
	if not _same(a["probability"], b["probability"]): return a["probability"] > b["probability"]
	if not _same(a["points"], b["points"]): return a["points"] > b["points"]
	return a["deadwood"] < b["deadwood"]

static func _equal(a: Dictionary, b: Dictionary) -> bool:
	return _same(a["probability"], b["probability"]) and _same(a["points"], b["points"]) and a["deadwood"] == b["deadwood"]

static func _same(a: float, b: float) -> bool:
	return absf(a-b) <= maxf(1.0,maxf(absf(a),absf(b))) * 1e-12

static func _outcome(deal: DealState, remaining: Array[CardData], first: CardData, second: CardData) -> Dictionary:
	var count := deal.discard_count + (1 if first != null and not deal.tra_da_extra_discard_pending else 0)
	var refill := maxi(10 - remaining.size(), 0) if deal.state == DealState.STATE_ACTIVE and count < deal.phase_discard_limit() else 0
	var guaranteed: Array[CardData] = []
	var pool: Array[CardData] = deal.deck.draw_pile.duplicate()
	var table: Array[MeldState] = deal.melds.duplicate()
	var crosses := refill > pool.size()
	var draws := refill
	if crosses:
		guaranteed.assign(pool)
		draws -= pool.size()
		pool.clear()
		var locked := {}
		for record: DiscardRecord in deal.discard_history:
			if record.kind == DiscardRecord.KIND_MANDATORY: locked[record.card.unique_id] = true
		for card: CardData in deal.deck.discard_pile:
			if not locked.has(card.unique_id): pool.append(card)
		pool.append_array(deal.recyclable_spent_cards)
		for meld: MeldState in table: pool.append_array(meld.cards)
		for meld: MeldState in deal.boss_melds: pool.append_array(meld.cards)
		table.clear() # Exhaustion removes table melds before the new hand is played.
		if first != null and deal.tra_da_extra_discard_pending: pool.append(first)
		if second != null: pool.append(second)
		draws = mini(draws, pool.size())
	var held: Array[CardData] = remaining.duplicate()
	held.append_array(guaranteed)
	if refill == 0: held = held.filter(func(c): return not deal.zodiac_boss.is_locked(c))
	held.sort_custom(func(a, b): return a.unique_id < b.unique_id)
	pool.sort_custom(func(a, b): return a.unique_id < b.unique_id)
	var best := {"probability": 0.0, "points": 0.0, "deadwood": ScoringPipeline.deadwood_points(remaining),
		"target": {}, "draw_count": guaranteed.size() + mini(draws, pool.size()), "crosses_exhaustion": crosses}
	best["register_closed"] = deal.zodiac_boss.suppresses(deal.current_phase) or (deal.zodiac_boss.id == "rooster" and deal.current_phase == 1 and count >= int(ZodiacCatalog.DEFINITIONS.rooster.deadlines[deal.zodiac_boss.disposition]))
	for rank in range(1, 14):
		var owned: Array[CardData] = []
		for c in held:
			if c.rank_index == rank: owned.append(c)
		var groups: Array[Dictionary] = [{"rank": rank, "suit": "", "needed": maxi(3 - owned.size(), 0)}]
		_consider(deal, best, owned, groups, pool, draws, MeldRules.TYPE_SET, null, "PROBABILITY_SET", [DeckManager.RANKS[rank - 1]])
	var families: Array[String] = []
	families.assign(DeckManager.SUITS)
	if deal.current_drink_id == DrinkCatalog.MIA_TAC: families.append("red")
	if deal.current_drink_id == DrinkCatalog.MIA_SAU_RIENG: families.append("black")
	for suit in families:
		for low in range(1, 12):
			var owned: Array[CardData] = []
			var groups: Array[Dictionary] = []
			for rank in range(low, low + 3):
				var match_card: CardData = null
				for c in held:
					if _matches(c, {"rank": rank, "suit": suit}): match_card = c; break
				if match_card != null: owned.append(match_card)
				else: groups.append({"rank": rank, "suit": suit, "needed": 1})
			_consider(deal, best, owned, groups, pool, draws, MeldRules.TYPE_RUN, null, "PROBABILITY_RUN", [DeckManager.RANKS[low-1], DeckManager.RANKS[low+1], MeldProbabilityAdvisor._suit_symbol(suit)])
	for meld: MeldState in table:
		var edges: Array[int] = []
		var suit := ""
		if meld.meld_type == MeldRules.TYPE_SET: edges.append(meld.cards[0].rank_index)
		else:
			var sorted := MeldRules.sorted_for_display(meld.cards, meld.meld_type)
			suit = meld.run_compatibility if meld.run_compatibility != "same" else sorted[0].suit
			if deal.current_drink_id == DrinkCatalog.MIA_TAC: suit = "red"
			elif deal.current_drink_id == DrinkCatalog.MIA_SAU_RIENG: suit = "black"
			if sorted[0].rank_index > 1: edges.append(sorted[0].rank_index - 1)
			if sorted.back().rank_index < 13: edges.append(sorted.back().rank_index + 1)
		for rank in edges:
			var owned: Array[CardData] = []
			for c in held:
				if _matches(c, {"rank": rank, "suit": suit}): owned.append(c); break
			_consider(deal, best, owned, [{"rank": rank, "suit": suit, "needed": 1 if owned.is_empty() else 0}], pool, draws, meld.meld_type, meld, "PROBABILITY_EXTEND_CARD", [meld.meld_id, "%s%s" % [DeckManager.RANKS[rank-1], MeldProbabilityAdvisor._suit_symbol(suit)]])
	return best

static func _matches(card: CardData, group: Dictionary) -> bool:
	var suit: String = group["suit"]
	return card.rank_index == group["rank"] and (suit in ["", "any"] or card.suit == suit or (suit == "red" and card.suit in ["Hearts", "Diamonds"]) or (suit == "black" and card.suit in ["Spades", "Clubs"]))

static func _consider(deal: DealState, best: Dictionary, owned: Array[CardData], groups: Array[Dictionary], pool: Array[CardData], draws: int, kind: String, meld: MeldState, key: String, args: Array) -> void:
	var probability := 1.0
	var counts: Array[int] = []
	var complete: Array[CardData] = owned.duplicate()
	var missing := 0
	for group in groups:
		var available: Array[CardData] = []
		for card in pool:
			if _matches(card, group): available.append(card)
		var needed: int = group["needed"]
		missing += needed
		if needed == 0: continue
		if available.size() < needed: return
		available.sort_custom(func(a, b): return a.score_value() > b.score_value() if a.score_value() != b.score_value() else a.unique_id < b.unique_id)
		counts.append(available.size())
		for i in range(needed): complete.append(available[i])
	if missing > draws: return
	if missing > 0:
		probability = MeldProbabilityAdvisor._probability_at_least(pool.size(), counts[0], draws, missing) if groups.size() == 1 else MeldProbabilityAdvisor._probability_all_groups(pool.size(), counts, draws)
	if probability <= 0.0: return
	# Future ordinary targets do not implicitly spend an active Drink charge.
	var points := 0
	if meld == null:
		if deal.meld_creation_rule(complete).get("type", MeldRules.TYPE_INVALID) != kind: return
		if not deal.zodiac_boss.legality("new_meld", deal.current_phase, -1, complete).is_empty(): return
		points = deal.preview_boss_payout(deal.scoring.preview_new_meld(complete, kind, deal.current_phase, deal.phase_new_meld_count, draws == 0), deal._next_meld_id).points
	else:
		var combined: Array[CardData] = meld.cards.duplicate()
		combined.append_array(complete)
		var compatibility := "red" if deal.current_drink_id == DrinkCatalog.MIA_TAC else "black" if deal.current_drink_id == DrinkCatalog.MIA_SAU_RIENG else meld.run_compatibility
		if not meld.can_extend(complete) and not (kind == MeldRules.TYPE_RUN and MeldRules.is_compatible_run(combined, compatibility)): return
		if not deal.zodiac_boss.legality("extension", deal.current_phase, meld.meld_id, complete).is_empty(): return
		points = deal.preview_boss_payout(deal.scoring.preview_extension(combined, kind, ScoringPipeline.meld_value(meld.cards), deal.current_phase, complete, draws == 0), meld.meld_id).points
	if best["register_closed"]: points = 0
	var projected := {"probability": probability, "points": probability * points, "deadwood": best["deadwood"]}
	if best["target"].is_empty() or _better(projected, best):
		best["probability"] = probability
		best["points"] = projected["points"]
		best["target"] = {"label_key": key, "label_args": args, "probability": probability, "missing_count": missing}
