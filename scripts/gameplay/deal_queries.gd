class_name DealQueries
extends RefCounted
## Read-only enumeration and advisory caches, tied to one physical deal.
## A weak reference avoids a DealState / query-owner reference cycle.
var _swap_cue_signature: int = 0
var _swap_cue_cache: Array[Dictionary] = []
var _reference: WeakRef
var _advice_signature: int = 0
var _advice_cache: Dictionary = {}
var _legal_actions_signature: int = 0
var _legal_actions_cached := false
var _legal_action_ids: Dictionary = {}
var _legal_hand_bits: Dictionary = {}
var _legal_meld_masks := PackedInt32Array()
var _legal_extension_ids: Dictionary = {}

func _init(deal: DealState) -> void:
	_reference = weakref(deal)

func _state() -> DealState:
	return _reference.get_ref() as DealState

func invalidate() -> void:
	_advice_cache.clear()
	_swap_cue_signature = 0
	_swap_cue_cache.clear()
	_legal_actions_cached = false

func hand_advice() -> Dictionary:
	var fingerprint := HandAdvice.signature(_state())
	if _advice_cache.is_empty() or fingerprint != _advice_signature:
		_advice_cache = HandAdvice.analyze(_state())
		_advice_signature = fingerprint
	return _advice_cache.duplicate(true)


func legal_action_card_ids() -> Dictionary:
	_ensure_legal_action_options()
	# Presentation callers may merge/replace these dictionaries for tutorial cues.
	return _legal_action_ids.duplicate(true)


func _legal_action_fingerprint() -> int:
	var hand_state: Array = []
	for card in _state().hand:
		hand_state.append(_legal_card_identity(card))
	var table_state: Array = []
	for meld in _state().melds:
		var cards: Array = []
		for card in meld.cards: cards.append(_legal_card_identity(card))
		table_state.append([meld.meld_id, meld.meld_type, meld.run_compatibility, cards])
	# Include object identity: restore can replace CardData while preserving IDs.
	# Boss policy stays authoritative, including future card-dependent legality.
	return hash([hand_state, table_state, _state().state, _state().current_phase, _state().current_drink_id, _state().zodiac_boss.snapshot()])


func _legal_card_identity(card: CardData) -> Array:
	return [card.get_instance_id(), card.permanent_snapshot(), card.base_value, card.enhancements, card.shiny]


func _ensure_legal_action_options() -> void:
	var fingerprint := _legal_action_fingerprint()
	if _legal_actions_cached and fingerprint == _legal_actions_signature: return
	_legal_actions_signature = fingerprint
	_legal_actions_cached = true
	_legal_hand_bits.clear()
	_legal_meld_masks.clear()
	_legal_extension_ids.clear()
	var identity_shapes := {}
	for index in _state().hand.size():
		var card := _state().hand[index]
		_legal_hand_bits[card.unique_id] = 1 << index if _state().hand.size() <= 12 else 0
		var bounds := _legal_identity_bounds([card] as Array[CardData])
		identity_shapes[card.unique_id] = bounds[0] | (bounds[2] << 13)
	var structural_melds := {}
	var structural_extensions := {}
	var table_ids := {}
	var table_masks := {}
	var extension_masks := {}
	var meld_mask := 0
	var extension_mask := 0
	var unlocked_mask := 0
	var locked_mask := 0
	var physical_hand_valid := _state().hand.size() <= 12 and MeldRules.physical_cards_valid(_state().hand, 1)
	for card in _state().hand:
		if _state().zodiac_boss.is_locked(card): locked_mask |= int(_legal_hand_bits[card.unique_id])
		else: unlocked_mask |= int(_legal_hand_bits[card.unique_id])
	for meld in _state().melds:
		structural_extensions[meld.meld_id] = {}
		table_ids[meld.meld_id] = {}
		table_masks[meld.meld_id] = 0
		extension_masks[meld.meld_id] = 0
		for card in meld.cards:
			table_ids[meld.meld_id][card.unique_id] = true
			table_masks[meld.meld_id] |= int(_legal_hand_bits.get(card.unique_id, 0))
	var meld_card_ids := {}
	var extension_card_ids := {}
	_legal_action_ids = {"meld": meld_card_ids, "extend": extension_card_ids}
	if not _state().card_actions_available():
		return
	for combination in _legal_action_candidates():
		var cards: Array[CardData] = combination
		var pattern := PackedInt32Array()
		var mask := 0
		for card in cards:
			pattern.append(identity_shapes[card.unique_id])
			mask |= int(_legal_hand_bits[card.unique_id])
		# Candidates are subsets of this already-validated physical hand. The
		# same lock/discard guard can use masks without rewalking every card.
		if physical_hand_valid:
			if (mask & locked_mask) != 0 or (_state().state != DealState.STATE_FINAL_COMMIT_WINDOW and (mask & unlocked_mask) == unlocked_mask): continue
		elif not _state().commit_selection_error(cards).is_empty() or not MeldRules.physical_cards_valid(cards, 1): continue
		pattern.sort()
		var shape_key := pattern
		if not structural_melds.has(shape_key):
			structural_melds[shape_key] = cards.size() >= 3 and _state().meld_creation_rule(cards).get("type", MeldRules.TYPE_INVALID) != MeldRules.TYPE_INVALID
		if structural_melds[shape_key] and _state().zodiac_boss.legality("new_meld", _state().current_phase, -1, cards).is_empty():
			_legal_meld_masks.append(mask)
			if _state().hand.size() <= 12: meld_mask |= mask
			else:
				for card in cards: meld_card_ids[card.unique_id] = true
		for meld in _state().melds:
			# Equal represented identities share matching work, while physical IDs,
			# locked cards, mandatory discards and boss guards remain per selection.
			if _state().hand.size() <= 12:
				if (mask & int(table_masks[meld.meld_id])) != 0: continue
			elif cards.any(func(card: CardData): return table_ids[meld.meld_id].has(card.unique_id)): continue
			var shapes: Dictionary = structural_extensions[meld.meld_id]
			if not shapes.has(shape_key): shapes[shape_key] = _state().can_extend_meld_shape(meld, cards)
			if shapes[shape_key] and _state().zodiac_boss.legality("extension", _state().current_phase, meld.meld_id, cards).is_empty():
				if _state().hand.size() <= 12:
					extension_mask |= mask
					extension_masks[meld.meld_id] |= mask
				else:
					for card in cards: extension_card_ids[card.unique_id] = true
	if _state().hand.size() <= 12:
		for id in _legal_hand_bits:
			var bit: int = _legal_hand_bits[id]
			if meld_mask & bit: meld_card_ids[id] = true
			if extension_mask & bit: extension_card_ids[id] = true
		for meld_id in extension_masks:
			var ids := {}
			for id in _legal_hand_bits:
				if int(extension_masks[meld_id]) & int(_legal_hand_bits[id]): ids[id] = true
			_legal_extension_ids[meld_id] = ids


func _legal_action_candidates() -> Array:
	if _state().hand.size() > 12: return hand_combinations()
	# Necessary identity bounds prune impossible subsets before expensive matching.
	# Every survivor still goes through the physical guard and authoritative rules.
	var total := 1 << _state().hand.size()
	var counts := PackedInt32Array()
	var rank_unions := PackedInt32Array()
	var rank_intersections := PackedInt32Array()
	var suit_intersections := PackedInt32Array()
	counts.resize(total)
	rank_unions.resize(total)
	rank_intersections.resize(total)
	suit_intersections.resize(total)
	rank_intersections[0] = (1 << 13) - 1
	suit_intersections[0] = 63
	for index in _state().hand.size():
		var shape := _legal_identity_bounds([_state().hand[index]] as Array[CardData])
		var bit := 1 << index
		for previous in bit:
			var mask := previous | bit
			counts[mask] = counts[previous] + 1
			rank_unions[mask] = rank_unions[previous] | shape[0]
			rank_intersections[mask] = rank_intersections[previous] & shape[1]
			suit_intersections[mask] = suit_intersections[previous] & shape[2]
	var tables: Array = []
	for meld in _state().melds: tables.append([meld, _legal_identity_bounds(meld.cards)])
	var passive_family := "red" if _state().current_drink_id == DrinkCatalog.MIA_TAC else "black" if _state().current_drink_id == DrinkCatalog.MIA_SAU_RIENG else "same"
	var candidates: Array = []
	for mask in range(1, total):
		var possible := counts[mask] >= 3 and (rank_intersections[mask] != 0 or _possible_run_bounds(rank_unions[mask], suit_intersections[mask], counts[mask], "same") or (passive_family != "same" and _possible_run_bounds(rank_unions[mask], suit_intersections[mask], counts[mask], passive_family)))
		if not possible:
			for row in tables:
				var meld: MeldState = row[0]
				var bounds: PackedInt32Array = row[1]
				if meld.meld_type == MeldRules.TYPE_SET:
					possible = (rank_intersections[mask] & bounds[1]) != 0
				elif meld.meld_type == MeldRules.TYPE_RUN:
					var ranks := rank_unions[mask] | bounds[0]
					var suits := suit_intersections[mask] & bounds[2]
					var count := counts[mask] + meld.cards.size()
					possible = _possible_run_bounds(ranks, suits, count, meld.run_compatibility) or (passive_family != "same" and _possible_run_bounds(ranks, suits, count, passive_family))
				if possible: break
		if possible:
			var cards: Array[CardData] = []
			for index in _state().hand.size():
				if mask & (1 << index): cards.append(_state().hand[index])
			candidates.append(cards)
	return candidates


func _legal_identity_bounds(cards: Array[CardData]) -> PackedInt32Array:
	var rank_union := 0
	var rank_intersection := (1 << 13) - 1
	var suit_intersection := 63
	for card in cards:
		var ranks := 0
		var suits := 0
		for rank in card.meld_rank_options(): ranks |= 1 << (rank - 1)
		for suit in card.meld_suit_options():
			suits |= (1 << DeckManager.SUITS.find(suit)) | (16 if suit in ["Hearts", "Diamonds"] else 32)
		rank_union |= ranks
		rank_intersection &= ranks
		suit_intersection &= suits
	return PackedInt32Array([rank_union, rank_intersection, suit_intersection])


func _possible_run_bounds(ranks: int, suits: int, count: int, family: String) -> bool:
	if count < 3 or count > 13: return false
	if family == "same" and (suits & 15) == 0: return false
	if family == "red" and (suits & 16) == 0: return false
	if family == "black" and (suits & 32) == 0: return false
	var window := (1 << count) - 1
	for low in range(14 - count):
		if (ranks & (window << low)) == (window << low): return true
	return false


func legal_action_targets_for_selection(selected_cards: Array[CardData], selected_meld_id: int = -1) -> Dictionary:
	var hand_card_ids := {}
	var table_meld_ids := {}
	if not _state().card_actions_available() or (selected_cards.is_empty() and selected_meld_id < 0):
		return {"hand": hand_card_ids, "melds": table_meld_ids}
	_ensure_legal_action_options()
	var selected_ids := {}
	for card in selected_cards:
		selected_ids[card.unique_id] = true
	if _state().hand.size() <= 12:
		var required_mask := 0
		var present := true
		for id in selected_ids:
			present = present and _legal_hand_bits.has(id)
			required_mask |= int(_legal_hand_bits.get(id, 0))
		var result_mask := 0
		if present and not selected_ids.is_empty():
			for mask in _legal_meld_masks:
				if (mask & required_mask) == required_mask: result_mask |= mask
		for id in _legal_hand_bits:
			if result_mask & int(_legal_hand_bits[id]): hand_card_ids[id] = true
		hand_card_ids.merge(_legal_extension_ids.get(selected_meld_id, {}))
	else:
		# Large recovered hands include selection-specific bounded witnesses.
		for cards: Array[CardData] in hand_combinations(selected_cards):
			if not selected_ids.is_empty() and cards.size() >= 3 and _cards_include_ids(cards, selected_ids) and _state().can_create_meld(cards):
				for card in cards: hand_card_ids[card.unique_id] = true
			if selected_meld_id >= 0 and _state().can_extend_meld(selected_meld_id, cards):
				for card in cards:
					hand_card_ids[card.unique_id] = true
	if not selected_cards.is_empty():
		for meld in _state().melds:
			if _state().can_extend_meld(meld.meld_id, selected_cards):
				table_meld_ids[meld.meld_id] = true
	return {"hand": hand_card_ids, "melds": table_meld_ids}


func probability_draw_pool() -> Array[CardData]:
	var cards: Array[CardData] = []
	cards.append_array(_state().deck.draw_pile)
	cards.append_array(_state().deck.discard_pile)
	cards.append_array(_state().recyclable_spent_cards)
	for meld in _state().melds:
		cards.append_array(meld.cards)
	for meld in _state().boss_melds: cards.append_array(meld.cards)
	return cards


func probability_draw_horizon() -> int:
	var projected_hand_size := _state().hand.size()
	if _state().state == DealState.STATE_ACTIVE:
		projected_hand_size = maxi(projected_hand_size - 1, 0)
	var refill_gap := maxi(DealState.ACTIVE_HAND_TARGET - projected_hand_size, 0)
	var later_refills_this_phase := maxi(_state().phase_discard_limit() - _state().discard_count - 2, 0)
	var next_phase_refills := _state().phase_discard_limit(2) - 1 if _state().current_phase == 1 else 0
	return mini(refill_gap + later_refills_this_phase + next_phase_refills, probability_draw_pool().size())


func hand_combinations(required: Array[CardData] = []) -> Array:
	var combinations: Array = []
	# Whole-meld recovery can exceed ten cards. Never allocate 2^hand_size
	# subsets for those hands. Minimal witnesses cover target cues; include
	# the selection and full rank groups for larger commitments.
	if _state().hand.size() > 12:
		var by_rank := {}
		for a in range(_state().hand.size()):
			combinations.append([_state().hand[a]] as Array[CardData])
			var expanded: Array[CardData] = required.duplicate()
			if not expanded.has(_state().hand[a]): expanded.append(_state().hand[a])
			combinations.append(expanded)
			if not by_rank.has(_state().hand[a].rank): by_rank[_state().hand[a].rank] = [] as Array[CardData]
			by_rank[_state().hand[a].rank].append(_state().hand[a])
			for b in range(a + 1, _state().hand.size()):
				combinations.append([_state().hand[a], _state().hand[b]] as Array[CardData])
				for c in range(b + 1, _state().hand.size()):
					combinations.append([_state().hand[a], _state().hand[b], _state().hand[c]] as Array[CardData])
		for group in by_rank.values(): combinations.append(group)
		if not required.is_empty(): combinations.append(required.duplicate())
		return combinations
	for mask in range(1, 1 << _state().hand.size()):
		var cards: Array[CardData] = []
		for index in range(_state().hand.size()):
			if mask & (1 << index):
				cards.append(_state().hand[index])
		combinations.append(cards)
	return combinations


func recommend_action() -> Dictionary:
	var best := {"action": HandAdvisor.ACTION_NONE, "cards": [] as Array[CardData], "estimated_points": -1}
	var candidates := hand_combinations()
	for cards: Array[CardData] in candidates:
		var use_drink := not _state().can_create_meld(cards) and _state().can_create_meld(cards, true)
		if _state().can_create_meld(cards) or use_drink:
			var kind: String = _state().meld_creation_rule(cards, use_drink)["type"]
			var points: int = _state().preview_new_meld_payout(cards, kind, _state().state == DealState.STATE_FINAL_COMMIT_WINDOW).points
			if points > int(best["estimated_points"]):
				best = {"action": HandAdvisor.ACTION_NEW_MELD, "cards": cards, "meld_type": kind, "meld_id": -1, "estimated_points": points, "use_drink": use_drink}
	if best["action"] != HandAdvisor.ACTION_NONE: return best
	for meld in _state().melds:
		for cards: Array[CardData] in candidates:
			if _state().can_extend_meld(meld.meld_id, cards):
				var points: int = _state().preview_extension_payout(meld, cards, _state().state == DealState.STATE_FINAL_COMMIT_WINDOW).points
				if points > int(best["estimated_points"]):
					best = {"action": HandAdvisor.ACTION_EXTENSION, "cards": cards, "meld_type": meld.meld_type, "meld_id": meld.meld_id, "estimated_points": points}
	return best


func _cards_include_ids(cards: Array[CardData], required_ids: Dictionary) -> bool:
	var remaining := required_ids.duplicate()
	for card in cards:
		remaining.erase(card.unique_id)
	return remaining.is_empty()



func drink_swap_opportunities(outgoing: CardData = null) -> Array[Dictionary]:
	var deal := _state()
	# Detached analysis includes the outgoing card and all ordinary boss guards.
	if deal.current_drink_id not in [DrinkCatalog.NHAN_TRAN, DrinkCatalog.DEN_DA] or not deal.current_drink_has_charge(): return []
	var signature := HandAdvice.signature(deal)
	if signature != _swap_cue_signature:
		_swap_cue_signature = signature
		_swap_cue_cache.clear()
		var probe := DealState.new()
		probe.restore_snapshot(deal.snapshot_state())
		for record in deal.drink_mandatory_discard_targets():
			for card in deal.hand:
				if not (deal.can_use_nhan_tran(card, record) or deal.can_use_den_da(card, record)): continue
				probe.hand.assign(deal.hand)
				probe.hand.erase(card)
				probe.hand.append(record.card)
				for cards: Array[CardData] in probe.queries.hand_combinations([record.card] as Array[CardData]):
					if not cards.has(record.card): continue
					var play := {"action": HandAdvisor.ACTION_NONE}
					if probe.can_create_meld(cards):
						play = {"action": HandAdvisor.ACTION_NEW_MELD, "cards": cards, "meld_id": -1}
					else:
						for meld in probe.melds:
							if probe.can_extend_meld(meld.meld_id, cards):
								play = {"action": HandAdvisor.ACTION_EXTENSION, "cards": cards, "meld_id": meld.meld_id}
								break
					if play.action != HandAdvisor.ACTION_NONE:
						_swap_cue_cache.append({"card": card, "record": record, "play": play})
						break
	var matches: Array[Dictionary] = []
	for opportunity in _swap_cue_cache:
		if outgoing == null or opportunity.card == outgoing: matches.append(opportunity)
	return matches
