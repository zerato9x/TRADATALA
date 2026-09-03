class_name DealState
extends RefCounted

signal state_changed(result: Dictionary)
signal new_phom_scored(context: ScoringContext)
signal extension_scored(context: ScoringContext)
signal phase_about_to_settle(context: Dictionary)
signal deadwood_calculated(context: Dictionary)
signal deal_about_to_resolve(context: Dictionary)
signal u_triggered(context: Dictionary)
signal first_exhaustion(context: Dictionary)
signal true_exhaustion(context: Dictionary)
signal exhaustion_discard_scored(context: ScoringContext)

const RESTING_HAND_SIZE := 9
const ACTIVE_HAND_TARGET := 10
const DISCARDS_PER_PHASE := 4

const TUTORIAL_HAND_SPECS := [
	["4", "Hearts"], ["5", "Hearts"], ["6", "Hearts"],
	["9", "Spades"], ["9", "Hearts"], ["9", "Diamonds"],
	["Q", "Diamonds"], ["K", "Spades"], ["2", "Clubs"], ["J", "Clubs"],
]
const TUTORIAL_DRAW_SPECS := [
	["7", "Hearts"], ["3", "Spades"], ["8", "Diamonds"], ["K", "Clubs"],
]

const STATE_ACTIVE := "active"
const STATE_FINAL_COMMIT_WINDOW := "final_commit_window"
const STATE_PHASE_CHOICE := "phase_choice"
const STATE_DEAL_OVER := "deal_over"

var deck := DeckManager.new()
var scoring := ScoringPipeline.new()
var wallet := VndWallet.new()
var vnd_per_point: int:
	get:
		return wallet.vnd_per_point
	set(value):
		wallet.vnd_per_point = value
var hand: Array[CardData] = []
var melds: Array[MeldState] = []
var discard_history: Array[DiscardRecord] = []
var settlements: Array[PhaseSettlement] = []
var phase_metrics := PhaseMetrics.new()

var current_phase: int = 1
var discard_count: int = 0
var phase_earnings_points: int = 0
var phase_new_meld_count: int = 0
var state: String = STATE_ACTIVE
var last_phase_resolution: Dictionary = {}
var current_drink_id: String = DrinkCatalog.NONE
var tra_da_used_this_turn: bool = false
var tra_da_extra_discard_pending: bool = false
var nhan_tran_used_this_phase: bool = false
var nuoc_voi_used_phases: Dictionary = {}
var sam_dua_preserved_cards: Array[CardData] = []
var sam_dua_used: bool = false
var recyclable_spent_cards: Array[CardData] = []
var recycle_used: bool = false
var true_exhaustion_active: bool = false

var _next_meld_id: int = 1
var _turn_started_with_ten: bool = false
var _turn_committed_card_count: int = 0
var _expected_deal_card_ids: Dictionary = {}


func _init() -> void:
	deck.stock_emptied.connect(_on_draw_stock_emptied)


func start_deal(shuffle_seed: int = -1, reset_wallet: bool = false) -> Dictionary:
	if reset_wallet:
		wallet.reset()
	deck.reset(shuffle_seed)
	_reset_exhaustion_state()
	_capture_expected_deal_card_ids()
	hand.clear()
	melds.clear()
	discard_history.clear()
	settlements.clear()
	current_phase = 1
	discard_count = 0
	state = STATE_ACTIVE
	last_phase_resolution.clear()
	_next_meld_id = 1
	_reset_drink_usage()
	_reset_phase_metrics()
	var resting_cards := deck.draw(RESTING_HAND_SIZE)
	hand.append_array(resting_cards)
	var turn_drawn := _begin_active_turn()
	var result := {
		"ok": true,
		"action": "start_deal",
		"shuffled": true,
		"resting_cards": resting_cards,
		"drawn": turn_drawn,
	}
	state_changed.emit(result)
	return result


func start_tutorial_deal() -> Dictionary:
	deck.reset(0)
	_reset_exhaustion_state()
	_capture_expected_deal_card_ids()
	hand.clear()
	melds.clear()
	discard_history.clear()
	settlements.clear()
	current_phase = 1
	discard_count = 0
	state = STATE_ACTIVE
	last_phase_resolution.clear()
	_next_meld_id = 1
	_reset_drink_usage()
	_reset_phase_metrics()
	for spec in TUTORIAL_HAND_SPECS:
		hand.append(_take_tutorial_card(String(spec[0]), String(spec[1])))
	var tutorial_draws: Array[CardData] = []
	for spec in TUTORIAL_DRAW_SPECS:
		tutorial_draws.append(_take_tutorial_card(String(spec[0]), String(spec[1])))
	for index in range(tutorial_draws.size() - 1, -1, -1):
		deck.draw_pile.append(tutorial_draws[index])
	_turn_started_with_ten = true
	_turn_committed_card_count = 0
	var result := {
		"ok": true,
		"action": "start_tutorial_deal",
		"shuffled": true,
		"drawn": hand.duplicate(),
	}
	state_changed.emit(result)
	return result


func set_current_drink(drink_id: String) -> Dictionary:
	if not DrinkCatalog.is_known(drink_id):
		return _failure("Unknown Drink ID: %s" % drink_id)
	current_drink_id = drink_id
	var result := {
		"ok": true,
		"action": "drink_selected",
		"drink_id": drink_id,
		"effect_implemented": DrinkCatalog.is_effect_implemented(drink_id),
	}
	state_changed.emit(result)
	return result


func exhaustion_status() -> Dictionary:
	return {
		"stock_count": deck.draw_pile.size(),
		"recyclable_spent_count": recyclable_spent_cards.size(),
		"discard_archive_count": deck.discard_pile.size(),
		"loose_hand_count": hand.size(),
		"table_card_count": _table_card_count(),
		"recycle_used": recycle_used,
		"true_exhaustion_active": true_exhaustion_active,
	}


func evaluate_exhaustion() -> Dictionary:
	if not deck.draw_pile.is_empty():
		return {"ok": true, "action": "stock_not_empty", "exhaustion": exhaustion_status()}
	return _resolve_empty_stock()


func move_to_recyclable_spent(cards: Array[CardData]) -> void:
	var existing_ids := {}
	for existing in recyclable_spent_cards:
		existing_ids[existing.unique_id] = true
	for card in cards:
		if card == null:
			continue
		if existing_ids.has(card.unique_id):
			push_error("Duplicate physical card sent to recyclable spent state: %s" % card.unique_id)
			continue
		if physical_card_locations().has(card.unique_id):
			push_error("Physical card must be detached before entering recyclable spent state: %s" % card.unique_id)
			continue
		recyclable_spent_cards.append(card)
		existing_ids[card.unique_id] = true


func physical_card_locations() -> Dictionary:
	var locations: Dictionary = {}
	_append_physical_zone(locations, "stock", deck.draw_pile)
	_append_physical_zone(locations, "loose_hand", hand)
	_append_physical_zone(locations, "discard_archive", deck.discard_pile)
	_append_physical_zone(locations, "recyclable_spent", recyclable_spent_cards)
	for meld in melds:
		_append_physical_zone(locations, "meld_%d" % meld.meld_id, meld.cards)
	return locations


func physical_card_accounting() -> Dictionary:
	var locations := physical_card_locations()
	var duplicate_ids: Array[String] = []
	for card_id in locations:
		var zones: Array = locations[card_id]
		if zones.size() > 1:
			duplicate_ids.append(String(card_id))
	var missing_ids: Array[String] = []
	var unexpected_ids: Array[String] = []
	for expected_id in _expected_deal_card_ids:
		if not locations.has(expected_id):
			missing_ids.append(String(expected_id))
	for card_id in locations:
		if not _expected_deal_card_ids.is_empty() and not _expected_deal_card_ids.has(card_id):
			unexpected_ids.append(String(card_id))
	var expected_known := not _expected_deal_card_ids.is_empty()
	var valid := duplicate_ids.is_empty() and missing_ids.is_empty() and unexpected_ids.is_empty()
	if expected_known:
		valid = valid and locations.size() == _expected_deal_card_ids.size()
	return {
		"valid": valid,
		"total_cards": _total_physical_card_count(locations),
		"unique_ids": locations.size(),
		"duplicate_ids": duplicate_ids,
		"missing_ids": missing_ids,
		"unexpected_ids": unexpected_ids,
		"expected_count": _expected_deal_card_ids.size(),
	}


func physical_card_accounting_is_valid() -> bool:
	return bool(physical_card_accounting().get("valid", false))


func can_use_nhan_tran(card: CardData, record: DiscardRecord) -> bool:
	if current_drink_id != DrinkCatalog.NHAN_TRAN or not _card_actions_available() or nhan_tran_used_this_phase:
		return false
	if card == null or not hand.has(card) or record == null:
		return false
	if record.kind != DiscardRecord.KIND_MANDATORY or record.phase != current_phase:
		return false
	if not discard_history.has(record) or _discard_pile_index(record.card) < 0:
		return false
	return true


func use_nhan_tran(card: CardData, record: DiscardRecord) -> Dictionary:
	if not can_use_nhan_tran(card, record):
		return _failure("Select one loose card and one mandatory discard from this Phase.")
	var recovered := _swap_mandatory_discard(record, card)
	nhan_tran_used_this_phase = true
	var result := {
		"ok": true,
		"action": "nhan_tran_swap",
		"discarded": card,
		"recovered": recovered,
		"discard_record": record,
	}
	state_changed.emit(result)
	return result


func can_use_nuoc_voi(meld_id: int, card: CardData) -> bool:
	if current_drink_id != DrinkCatalog.NUOC_VOI or not _card_actions_available():
		return false
	if nuoc_voi_used_phases.has(current_phase):
		return false
	var meld := get_meld(meld_id)
	if meld == null or card == null or not meld.cards.has(card) or meld.cards.size() <= 3:
		return false
	if meld.meld_type == MeldRules.TYPE_RUN and card != meld.cards[0] and card != meld.cards[-1]:
		return false
	var remaining: Array[CardData] = []
	for existing in meld.cards:
		if existing != card:
			remaining.append(existing)
	return remaining.size() >= 3 and MeldRules.classify(remaining) == meld.meld_type


func use_nuoc_voi(meld_id: int, card: CardData) -> Dictionary:
	if not can_use_nuoc_voi(meld_id, card):
		return _failure("Choose a removable Meld card; Runs allow endpoints only and at least three cards must remain.")
	var meld := get_meld(meld_id)
	meld.cards.erase(card)
	meld.cards = MeldRules.sorted_for_display(meld.cards, meld.meld_type)
	hand.append(card)
	nuoc_voi_used_phases[current_phase] = true
	var result := {
		"ok": true,
		"action": "nuoc_voi_return",
		"meld_id": meld_id,
		"card": card,
	}
	state_changed.emit(result)
	return result


func select_sam_dua_preserves(cards: Array[CardData]) -> Dictionary:
	if current_drink_id != DrinkCatalog.SAM_DUA:
		return _failure("Sâm dứa is not the active Drink.")
	if current_phase != 1 or state not in [STATE_FINAL_COMMIT_WINDOW, STATE_PHASE_CHOICE]:
		return _failure("Sâm dứa is prepared during the Phase 1 to Phase 2 transition.")
	if sam_dua_used:
		return _failure("Sâm dứa has already been used this Deal.")
	if cards.size() > 3:
		return _failure("Sâm dứa can preserve at most three loose cards.")
	var seen_ids := {}
	for card in cards:
		if card == null or not hand.has(card) or seen_ids.has(card.unique_id):
			return _failure("Sâm dứa can preserve only distinct loose hand cards.")
		seen_ids[card.unique_id] = true
	sam_dua_preserved_cards.clear()
	sam_dua_preserved_cards.append_array(cards)
	sam_dua_used = true
	var result := {
		"ok": true,
		"action": "sam_dua_selected",
		"preserved": sam_dua_preserved_cards.duplicate(),
	}
	state_changed.emit(result)
	return result


func current_drink_has_charge() -> bool:
	match current_drink_id:
		DrinkCatalog.TRA_DA:
			return false
		DrinkCatalog.NHAN_TRAN:
			return not nhan_tran_used_this_phase and _card_actions_available() and not discard_history_for_phase(current_phase).is_empty()
		DrinkCatalog.NUOC_VOI:
			return current_phase in [1, 2] and not nuoc_voi_used_phases.has(current_phase) and _card_actions_available()
		DrinkCatalog.SAM_DUA:
			return not sam_dua_used and current_phase == 1 and state in [STATE_FINAL_COMMIT_WINDOW, STATE_PHASE_CHOICE]
	return false


func drink_cue_trigger() -> Dictionary:
	var trigger_id := DrinkCatalog.cue_trigger(current_drink_id)
	match current_drink_id:
		DrinkCatalog.TRA_DA:
			return {"active": tra_da_extra_discard_pending and state == STATE_ACTIVE, "drink_id": current_drink_id, "trigger_id": trigger_id}
		DrinkCatalog.NHAN_TRAN:
			var records := nhan_tran_meld_opportunity_records()
			return {"active": not records.is_empty(), "drink_id": current_drink_id, "trigger_id": trigger_id, "records": records}
		DrinkCatalog.NUOC_VOI:
			var targets := nuoc_voi_targets()
			return {"active": not targets.is_empty(), "drink_id": current_drink_id, "trigger_id": trigger_id, "targets": targets}
		DrinkCatalog.SAM_DUA:
			var active := not sam_dua_used and current_phase == 1 and state == STATE_FINAL_COMMIT_WINDOW and not hand.is_empty()
			return {"active": active, "drink_id": current_drink_id, "trigger_id": trigger_id}
	return {"active": false, "drink_id": current_drink_id, "trigger_id": trigger_id}


func nhan_tran_meld_opportunity_records() -> Array[DiscardRecord]:
	var records: Array[DiscardRecord] = []
	if current_drink_id != DrinkCatalog.NHAN_TRAN or nhan_tran_used_this_phase or not _card_actions_available():
		return records
	for record in discard_history_for_phase(current_phase):
		if _discard_pile_index(record.card) >= 0 and _card_completes_hand_meld(record.card):
			records.append(record)
	return records


func nuoc_voi_targets() -> Array[Dictionary]:
	var targets: Array[Dictionary] = []
	for meld in melds:
		for card in meld.cards:
			if can_use_nuoc_voi(meld.meld_id, card):
				targets.append({"meld_id": meld.meld_id, "card": card})
	return targets


func create_meld(selected_cards: Array[CardData]) -> Dictionary:
	var guard := _validate_commit_selection(selected_cards)
	if not guard.is_empty():
		return _failure(guard)
	var meld_type := MeldRules.classify(selected_cards)
	if meld_type == MeldRules.TYPE_INVALID:
		return _failure("Selected cards are not a Set or Run.")
	_remove_from_hand(selected_cards)
	var meld := MeldState.new(_next_meld_id, meld_type, selected_cards)
	_next_meld_id += 1
	var context := scoring.score_new_meld(meld.cards, meld.meld_type, current_phase, phase_metrics.new_phom_count)
	meld.scored_points = ScoringPipeline.meld_value(meld.cards)
	melds.append(meld)
	phase_metrics.new_phom_count += 1
	phase_new_meld_count = phase_metrics.new_phom_count
	if state == STATE_ACTIVE:
		_turn_committed_card_count += selected_cards.size()
	_record_phase_points(context.final_points, "new_meld")
	new_phom_scored.emit(context)
	var result := {
		"ok": true,
		"action": "new_meld",
		"meld_id": meld.meld_id,
		"context": context,
	}
	state_changed.emit(result)
	return result


func extend_meld(meld_id: int, selected_cards: Array[CardData]) -> Dictionary:
	var guard := _validate_commit_selection(selected_cards)
	if not guard.is_empty():
		return _failure(guard)
	var meld := get_meld(meld_id)
	if meld == null:
		return _failure("Choose a table Meld to extend.")
	if not meld.can_extend(selected_cards):
		return _failure("Those cards do not legally extend the chosen Meld.")
	var old_score := ScoringPipeline.meld_value(meld.cards)
	var banked_score := meld.scored_points
	_remove_from_hand(selected_cards)
	if state == STATE_ACTIVE:
		_turn_committed_card_count += selected_cards.size()
	var additions: Array[CardData] = []
	additions.append_array(selected_cards)
	meld.extend(selected_cards)
	var context := scoring.score_extension(meld.cards, meld.meld_type, old_score, current_phase, additions)
	meld.scored_points = maxi(banked_score, context.theoretical_score)
	phase_metrics.extension_count += 1
	_record_phase_points(context.final_points, "extension")
	extension_scored.emit(context)
	var result := {
		"ok": true,
		"action": "extension",
		"meld_id": meld.meld_id,
		"context": context,
	}
	state_changed.emit(result)
	return result


func discard_card(card: CardData) -> Dictionary:
	if state != STATE_ACTIVE:
		return _failure("Discarding is unavailable right now.")
	if card == null or not hand.has(card):
		return _failure("Choose one loose card to discard.")
	if deck.draw_pile.is_empty():
		_resolve_empty_stock()
	if current_drink_id == DrinkCatalog.TRA_DA and not tra_da_extra_discard_pending and hand.size() < 2:
		return _failure("Trà đá requires two loose cards so both discards can be completed.")
	var is_tra_da_extra := current_drink_id == DrinkCatalog.TRA_DA and tra_da_extra_discard_pending
	var completed_u := not is_tra_da_extra and _turn_started_with_ten and _turn_committed_card_count == 9 and hand.size() == 1
	hand.erase(card)
	deck.discard(card)
	var exhaustion_score_context: ScoringContext = _score_true_exhaustion_discard(card)
	if is_tra_da_extra:
		tra_da_extra_discard_pending = false
		tra_da_used_this_turn = true
		discard_history.append(DiscardRecord.new(card, current_phase, discard_count, DiscardRecord.KIND_DRINK_EXTRA))
	else:
		discard_count += 1
		discard_history.append(DiscardRecord.new(card, current_phase, discard_count, DiscardRecord.KIND_MANDATORY))
		if current_drink_id == DrinkCatalog.TRA_DA:
			tra_da_extra_discard_pending = true
	if completed_u:
		phase_metrics.u = true
		u_triggered.emit({"phase": current_phase, "card": card})
	var result := {
		"ok": true,
		"action": "discard",
		"card": card,
		"drawn": [] as Array[CardData],
		"u_triggered": completed_u,
		"discard_kind": DiscardRecord.KIND_DRINK_EXTRA if is_tra_da_extra else DiscardRecord.KIND_MANDATORY,
	}
	if exhaustion_score_context != null:
		result["exhaustion_score_context"] = exhaustion_score_context
	if tra_da_extra_discard_pending:
		result["extra_discard_pending"] = true
	elif discard_count >= DISCARDS_PER_PHASE:
		state = STATE_FINAL_COMMIT_WINDOW
		result["final_commit_window"] = true
	else:
		result["drawn"] = _begin_active_turn()
	state_changed.emit(result)
	return result


func settle_phase() -> Dictionary:
	if state != STATE_FINAL_COMMIT_WINDOW:
		return _failure("Phase settlement is only available during the final commit window.")
	var resolution := _finish_phase()
	var result := {
		"ok": true,
		"action": "phase_settlement",
		"phase_resolution": resolution,
	}
	state_changed.emit(result)
	return result


func choose_phase_two(keep_hand: bool) -> Dictionary:
	if state != STATE_PHASE_CHOICE or current_phase != 1:
		return _failure("KEEP / DUMP is only available between Phases.")
	var dumped: Array[CardData] = []
	var preserved: Array[CardData] = []
	if not keep_hand:
		if current_drink_id == DrinkCatalog.SAM_DUA:
			for card in sam_dua_preserved_cards:
				if hand.has(card) and preserved.size() < 3:
					preserved.append(card)
		for card in hand:
			if not preserved.has(card):
				dumped.append(card)
		hand.clear()
		hand.append_array(preserved)
		move_to_recyclable_spent(dumped)
	current_phase = 2
	discard_count = 0
	_reset_phase_metrics()
	state = STATE_ACTIVE
	var drawn := _begin_active_turn()
	var result := {
		"ok": true,
		"action": "keep" if keep_hand else "dump",
		"dumped": dumped,
		"preserved": preserved,
		"drawn": drawn,
	}
	sam_dua_preserved_cards.clear()
	state_changed.emit(result)
	return result


func get_meld(meld_id: int) -> MeldState:
	for meld in melds:
		if meld.meld_id == meld_id:
			return meld
	return null


func can_create_meld(selected_cards: Array[CardData]) -> bool:
	return _card_actions_available() and _validate_commit_selection(selected_cards).is_empty() and MeldRules.classify(selected_cards) != MeldRules.TYPE_INVALID


func can_extend_meld(meld_id: int, selected_cards: Array[CardData]) -> bool:
	if not _card_actions_available() or not _validate_commit_selection(selected_cards).is_empty():
		return false
	var meld := get_meld(meld_id)
	return meld != null and meld.can_extend(selected_cards)


func legal_action_card_ids() -> Dictionary:
	var meld_card_ids := {}
	var extension_card_ids := {}
	if not _card_actions_available():
		return {"meld": meld_card_ids, "extend": extension_card_ids}
	for combination in _hand_card_combinations():
		var cards: Array[CardData] = combination
		if cards.size() >= 3 and can_create_meld(cards):
			for card in cards:
				meld_card_ids[card.unique_id] = true
		for meld in melds:
			if can_extend_meld(meld.meld_id, cards):
				for card in cards:
					extension_card_ids[card.unique_id] = true
				break
	return {"meld": meld_card_ids, "extend": extension_card_ids}


func legal_action_targets_for_selection(selected_cards: Array[CardData], selected_meld_id: int = -1) -> Dictionary:
	var hand_card_ids := {}
	var table_meld_ids := {}
	if not _card_actions_available() or (selected_cards.is_empty() and selected_meld_id < 0):
		return {"hand": hand_card_ids, "melds": table_meld_ids}
	var selected_ids := {}
	for card in selected_cards:
		selected_ids[card.unique_id] = true
	for combination in _hand_card_combinations():
		var cards: Array[CardData] = combination
		if not selected_ids.is_empty() and cards.size() >= 3 and _cards_include_ids(cards, selected_ids) and can_create_meld(cards):
			for card in cards:
				hand_card_ids[card.unique_id] = true
		if selected_meld_id >= 0 and can_extend_meld(selected_meld_id, cards):
			for card in cards:
				hand_card_ids[card.unique_id] = true
	if not selected_cards.is_empty():
		for meld in melds:
			if can_extend_meld(meld.meld_id, selected_cards):
				table_meld_ids[meld.meld_id] = true
	return {"hand": hand_card_ids, "melds": table_meld_ids}


func _hand_card_combinations() -> Array:
	var combinations: Array = []
	for mask in range(1, 1 << hand.size()):
		var cards: Array[CardData] = []
		for index in range(hand.size()):
			if mask & (1 << index):
				cards.append(hand[index])
		combinations.append(cards)
	return combinations


func _cards_include_ids(cards: Array[CardData], required_ids: Dictionary) -> bool:
	var remaining := required_ids.duplicate()
	for card in cards:
		remaining.erase(card.unique_id)
	return remaining.is_empty()


func _card_completes_hand_meld(discard_card: CardData) -> bool:
	if discard_card == null:
		return false
	for first_index in range(hand.size()):
		for second_index in range(first_index + 1, hand.size()):
			var candidate: Array[CardData] = [hand[first_index], hand[second_index], discard_card]
			if MeldRules.classify(candidate) != MeldRules.TYPE_INVALID:
				return true
	return false


func deadwood_points() -> int:
	return ScoringPipeline.deadwood_points(hand)


func discard_history_for_phase(phase: int) -> Array[DiscardRecord]:
	var records: Array[DiscardRecord] = []
	for record in discard_history:
		if record.kind == DiscardRecord.KIND_MANDATORY and record.phase == phase:
			records.append(record)
	return records


func latest_mandatory_discard(phase: int = -1) -> DiscardRecord:
	var target_phase := current_phase if phase < 0 else phase
	var records := discard_history_for_phase(target_phase)
	return records[-1] if not records.is_empty() else null


func drink_mandatory_discard_targets() -> Array[DiscardRecord]:
	var targets: Array[DiscardRecord] = []
	if not current_drink_has_charge():
		return targets
	match current_drink_id:
		DrinkCatalog.NHAN_TRAN:
			targets.append_array(discard_history_for_phase(current_phase))
	return targets


func _on_draw_stock_emptied() -> void:
	_resolve_empty_stock()


func _resolve_empty_stock() -> Dictionary:
	if not deck.draw_pile.is_empty():
		return {"ok": true, "action": "stock_not_empty", "exhaustion": exhaustion_status()}
	if true_exhaustion_active:
		return {"ok": true, "action": "true_exhaustion_already_active", "exhaustion": exhaustion_status()}
	var before := exhaustion_status()
	var eligible: Array[CardData] = []
	eligible.append_array(recyclable_spent_cards)
	if not recycle_used and not eligible.is_empty():
		var recycled_card_ids: Array[String] = []
		for card in eligible:
			recycled_card_ids.append(card.unique_id)
		recyclable_spent_cards.clear()
		recycle_used = true
		deck.replace_draw_pile(eligible)
		var first_context := exhaustion_status()
		first_context["action"] = "first_exhaustion"
		first_context["stock_before"] = int(before["stock_count"])
		first_context["recycled_count"] = eligible.size()
		first_context["recycled_card_ids"] = recycled_card_ids
		first_context["eligible_spent_count_at_trigger"] = eligible.size()
		first_exhaustion.emit(first_context)
		state_changed.emit({"ok": true, "action": "first_exhaustion", "exhaustion": first_context})
		_log_exhaustion_transition(first_context)
		return {"ok": true, "action": "first_exhaustion", "exhaustion": first_context}
	return _activate_true_exhaustion(before)


func _activate_true_exhaustion(before: Dictionary) -> Dictionary:
	true_exhaustion_active = true
	var context := exhaustion_status()
	context["action"] = "true_exhaustion"
	context["stock_before"] = int(before.get("stock_count", 0))
	context["eligible_spent_count_at_trigger"] = int(before.get("recyclable_spent_count", 0))
	true_exhaustion.emit(context)
	state_changed.emit({"ok": true, "action": "true_exhaustion", "exhaustion": context})
	_log_exhaustion_transition(context)
	return {"ok": true, "action": "true_exhaustion", "exhaustion": context}


func _log_exhaustion_transition(context: Dictionary) -> void:
	print("[DealState] %s stock=%d spent=%d archive=%d loose=%d table=%d recycle_used=%s true_exhaustion_active=%s recycled=%d" % [
		String(context.get("action", "")),
		int(context.get("stock_count", 0)),
		int(context.get("recyclable_spent_count", 0)),
		int(context.get("discard_archive_count", 0)),
		int(context.get("loose_hand_count", 0)),
		int(context.get("table_card_count", 0)),
		str(context.get("recycle_used", false)),
		str(context.get("true_exhaustion_active", false)),
		int(context.get("recycled_count", 0)),
	])


func _begin_active_turn() -> Array[CardData]:
	tra_da_used_this_turn = false
	tra_da_extra_discard_pending = false
	var all_drawn: Array[CardData] = []
	all_drawn.append_array(deck.refill(hand, ACTIVE_HAND_TARGET))
	if deck.draw_pile.is_empty():
		_resolve_empty_stock()
	while hand.size() == ACTIVE_HAND_TARGET and not _has_near_meld(hand):
		var payout := 0
		for card in hand:
			payout += card.score_value()
		payout *= 10
		phase_metrics.u_khan_count += 1
		_record_phase_points(payout, "u_khan")
		var replaced: Array[CardData] = []
		replaced.append_array(hand)
		u_triggered.emit({"phase": current_phase, "u_khan": true, "payout": payout, "hand": replaced})
		hand.clear()
		move_to_recyclable_spent(replaced)
		var replacement := deck.refill(hand, ACTIVE_HAND_TARGET)
		all_drawn.append_array(replacement)
		if replacement.size() < ACTIVE_HAND_TARGET:
			break
	_turn_started_with_ten = hand.size() == ACTIVE_HAND_TARGET
	_turn_committed_card_count = 0
	return all_drawn


func _take_tutorial_card(rank: String, suit: String) -> CardData:
	for card in deck.draw_pile:
		if card.rank == rank and card.suit == suit:
			deck.draw_pile.erase(card)
			return card
	push_error("Tutorial card is missing from the standard deck: %s of %s" % [rank, suit])
	return null


func _finish_phase() -> Dictionary:
	var settle_context := {
		"phase": current_phase,
		"raw_gross": phase_metrics.raw_gross,
		"gross_multiplier": 2 if phase_metrics.u else 1,
		"hand": hand,
	}
	phase_about_to_settle.emit(settle_context)
	var raw_gross: int = settle_context.get("raw_gross", phase_metrics.raw_gross)
	var gross_after_u: int = raw_gross * int(settle_context.get("gross_multiplier", 1))
	var gross_adjustment := gross_after_u - phase_metrics.raw_gross
	if gross_adjustment != 0:
		wallet.apply_points(gross_adjustment, "phase_gross_resolution")
	var is_mom := phase_metrics.new_phom_count == 0
	var deadwood_value_sum := deadwood_points()
	var deadwood_multiplier := hand.size() if is_mom else 1
	var deadwood_context := {
		"phase": current_phase,
		"cards": hand,
		"value_sum": deadwood_value_sum,
		"multiplier": deadwood_multiplier,
		"deadwood": deadwood_value_sum * deadwood_multiplier,
		"mom": is_mom,
	}
	deadwood_calculated.emit(deadwood_context)
	var deadwood: int = maxi(int(deadwood_context.get("deadwood", 0)), 0)
	if deadwood > 0:
		wallet.apply_points(-deadwood, "deadwood")
	var settlement := PhaseSettlement.new()
	settlement.phase = current_phase
	settlement.raw_gross = raw_gross
	settlement.gross_after_u = gross_after_u
	settlement.deadwood_value_sum = maxi(int(deadwood_context.get("value_sum", deadwood_value_sum)), 0)
	settlement.deadwood_multiplier = maxi(int(deadwood_context.get("multiplier", deadwood_multiplier)), 0)
	settlement.deadwood = deadwood
	settlement.net = gross_after_u - deadwood
	settlement.new_phom_count = phase_metrics.new_phom_count
	settlement.extension_count = phase_metrics.extension_count
	settlement.mom = is_mom
	settlement.u = phase_metrics.u
	settlement.u_khan_count = phase_metrics.u_khan_count
	settlement.remaining_hand.append_array(hand)
	settlements.append(settlement)
	phase_earnings_points = settlement.net
	if current_phase == 1:
		state = STATE_PHASE_CHOICE
	else:
		_resolve_deal()
		state = STATE_DEAL_OVER
	last_phase_resolution = settlement.to_dictionary()
	return last_phase_resolution


func _resolve_deal() -> void:
	var deal_context := {"settlements": settlements}
	deal_about_to_resolve.emit(deal_context)


func _validate_loose_selection(selected_cards: Array[CardData]) -> String:
	if not _card_actions_available():
		return "Card actions are unavailable right now."
	if selected_cards.is_empty():
		return "Select loose cards first."
	var seen_ids := {}
	for card in selected_cards:
		if card == null or not hand.has(card):
			return "Selection contains a card outside the loose hand."
		if seen_ids.has(card.unique_id):
			return "The same card cannot be selected twice."
		seen_ids[card.unique_id] = true
	return ""


func _validate_commit_selection(selected_cards: Array[CardData]) -> String:
	var guard := _validate_loose_selection(selected_cards)
	if not guard.is_empty():
		return guard
	var required_discards := 1
	if state == STATE_ACTIVE and current_drink_id == DrinkCatalog.TRA_DA:
		required_discards = 1 if tra_da_extra_discard_pending else 2
	if state != STATE_FINAL_COMMIT_WINDOW and selected_cards.size() > hand.size() - required_discards:
		return "Keep at least two loose cards for Trà đá's discards." if required_discards == 2 else "Keep at least one loose card for the mandatory discard."
	return ""


func _card_actions_available() -> bool:
	return state == STATE_ACTIVE or state == STATE_FINAL_COMMIT_WINDOW


func _record_phase_points(points: int, reason: String) -> void:
	phase_metrics.raw_gross += points
	phase_earnings_points = phase_metrics.raw_gross
	if points != 0:
		wallet.apply_points(points, reason)


func _score_true_exhaustion_discard(card: CardData) -> ScoringContext:
	if not true_exhaustion_active or card == null:
		return null
	var context := scoring.score_true_exhaustion_discard(card, current_phase)
	if context == null:
		return null
	_record_phase_points(context.final_points, context.action_type)
	exhaustion_discard_scored.emit(context)
	return context


func _reset_exhaustion_state() -> void:
	recyclable_spent_cards.clear()
	recycle_used = false
	true_exhaustion_active = false
	_expected_deal_card_ids.clear()


func _capture_expected_deal_card_ids() -> void:
	_expected_deal_card_ids.clear()
	for card in deck.draw_pile:
		_expected_deal_card_ids[card.unique_id] = true


func _append_physical_zone(locations: Dictionary, zone: String, cards: Array[CardData]) -> void:
	for card in cards:
		if card == null:
			continue
		var card_id := String(card.unique_id)
		var zones: Array = locations.get(card_id, [])
		zones.append(zone)
		locations[card_id] = zones


func _total_physical_card_count(locations: Dictionary) -> int:
	var total := 0
	for card_id in locations:
		total += (locations[card_id] as Array).size()
	return total


func _table_card_count() -> int:
	var total := 0
	for meld in melds:
		total += meld.cards.size()
	return total


func _reset_phase_metrics() -> void:
	phase_metrics.reset()
	phase_earnings_points = 0
	phase_new_meld_count = 0
	nhan_tran_used_this_phase = false
	_turn_started_with_ten = false
	_turn_committed_card_count = 0


func _reset_drink_usage() -> void:
	tra_da_used_this_turn = false
	tra_da_extra_discard_pending = false
	nhan_tran_used_this_phase = false
	nuoc_voi_used_phases.clear()
	sam_dua_preserved_cards.clear()
	sam_dua_used = false


func _remove_from_hand(cards: Array[CardData]) -> void:
	for card in cards:
		hand.erase(card)


func _discard_pile_index(card: CardData) -> int:
	for index in range(deck.discard_pile.size()):
		if deck.discard_pile[index] == card:
			return index
	return -1


func _swap_mandatory_discard(record: DiscardRecord, hand_card: CardData) -> CardData:
	var discard_index := _discard_pile_index(record.card)
	var recovered := record.card
	deck.discard_pile[discard_index] = hand_card
	hand.erase(hand_card)
	hand.append(recovered)
	record.card = hand_card
	return recovered


func _failure(message: String) -> Dictionary:
	return {"ok": false, "message": message}


static func _has_near_meld(cards: Array[CardData]) -> bool:
	for left_index in range(cards.size()):
		for right_index in range(left_index + 1, cards.size()):
			var left := cards[left_index]
			var right := cards[right_index]
			if left.rank == right.rank:
				return true
			if left.suit == right.suit and absi(left.rank_index - right.rank_index) in [1, 2]:
				return true
	return false
