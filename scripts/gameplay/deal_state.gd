class_name DealState
extends RefCounted

signal state_changed(result: Dictionary)

const RESTING_HAND_SIZE := 9
const ACTIVE_HAND_TARGET := 10
const DISCARDS_PER_PHASE := 4

const STATE_ACTIVE := "active"
const STATE_PHASE_CHOICE := "phase_choice"
const STATE_DEAL_OVER := "deal_over"

var deck := DeckManager.new()
var scoring := ScoringPipeline.new()
var wallet := VndWallet.new()
var hand: Array[CardData] = []
var melds: Array[MeldState] = []
var current_phase: int = 1
var discard_count: int = 0
var phase_earnings_points: int = 0
var phase_new_meld_count: int = 0
var state: String = STATE_ACTIVE
var last_phase_resolution: Dictionary = {}
var _next_meld_id: int = 1


func start_deal(shuffle_seed: int = -1, reset_wallet: bool = false) -> Dictionary:
	if reset_wallet:
		wallet.reset()
	deck.reset(shuffle_seed)
	hand.clear()
	melds.clear()
	current_phase = 1
	discard_count = 0
	phase_earnings_points = 0
	phase_new_meld_count = 0
	state = STATE_ACTIVE
	last_phase_resolution.clear()
	_next_meld_id = 1
	var resting_cards := deck.draw(RESTING_HAND_SIZE)
	hand.append_array(resting_cards)
	var turn_drawn := _begin_active_turn()
	var result := {
		"ok": true,
		"action": "start_deal",
		"resting_cards": resting_cards,
		"drawn": turn_drawn,
	}
	state_changed.emit(result)
	return result


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
	var context := scoring.score_new_meld(meld.cards, meld.meld_type, current_phase)
	meld.scored_points = context.theoretical_score
	melds.append(meld)
	phase_new_meld_count += 1
	phase_earnings_points += context.final_points
	wallet.apply_points(context.final_points, "new_meld")
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
	var old_score := meld.scored_points
	_remove_from_hand(selected_cards)
	meld.extend(selected_cards)
	var context := scoring.score_extension(meld.cards, meld.meld_type, old_score, current_phase)
	meld.scored_points = context.theoretical_score
	phase_earnings_points += context.final_points
	wallet.apply_points(context.final_points, "extension")
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
	hand.erase(card)
	deck.discard(card)
	discard_count += 1
	var result := {
		"ok": true,
		"action": "discard",
		"card": card,
		"drawn": [] as Array[CardData],
	}
	if discard_count >= DISCARDS_PER_PHASE:
		result["phase_resolution"] = _finish_phase()
	else:
		result["drawn"] = _begin_active_turn()
	state_changed.emit(result)
	return result


func choose_phase_two(keep_hand: bool) -> Dictionary:
	if state != STATE_PHASE_CHOICE or current_phase != 1:
		return _failure("KEEP / DUMP is only available between Phases.")
	var dumped: Array[CardData] = []
	if not keep_hand:
		dumped.append_array(hand)
		deck.discard_many(hand)
		hand.clear()
	current_phase = 2
	discard_count = 0
	phase_earnings_points = 0
	phase_new_meld_count = 0
	state = STATE_ACTIVE
	var drawn := _begin_active_turn()
	var result := {
		"ok": true,
		"action": "keep" if keep_hand else "dump",
		"dumped": dumped,
		"drawn": drawn,
	}
	state_changed.emit(result)
	return result


func get_meld(meld_id: int) -> MeldState:
	for meld in melds:
		if meld.meld_id == meld_id:
			return meld
	return null


func can_create_meld(selected_cards: Array[CardData]) -> bool:
	return state == STATE_ACTIVE and _validate_commit_selection(selected_cards).is_empty() and MeldRules.classify(selected_cards) != MeldRules.TYPE_INVALID


func can_extend_meld(meld_id: int, selected_cards: Array[CardData]) -> bool:
	if state != STATE_ACTIVE or not _validate_commit_selection(selected_cards).is_empty():
		return false
	var meld := get_meld(meld_id)
	return meld != null and meld.can_extend(selected_cards)


func deadwood_points() -> int:
	return ScoringPipeline.deadwood_points(hand)


func _begin_active_turn() -> Array[CardData]:
	return deck.refill(hand, ACTIVE_HAND_TARGET)


func _finish_phase() -> Dictionary:
	var resolution := {
		"phase": current_phase,
		"mom": phase_new_meld_count == 0,
		"forfeit_points": 0,
		"deadwood_points": 0,
	}
	if resolution["mom"]:
		var forfeit_points := maxi(phase_earnings_points, 0)
		resolution["forfeit_points"] = forfeit_points
		if forfeit_points > 0:
			phase_earnings_points -= forfeit_points
			wallet.apply_points(-forfeit_points, "mom_forfeit")
	if current_phase == 1:
		state = STATE_PHASE_CHOICE
	else:
		var penalty := deadwood_points()
		resolution["deadwood_points"] = penalty
		phase_earnings_points -= penalty
		if penalty > 0:
			wallet.apply_points(-penalty, "deadwood")
		state = STATE_DEAL_OVER
	last_phase_resolution = resolution
	return resolution


func _validate_loose_selection(selected_cards: Array[CardData]) -> String:
	if state != STATE_ACTIVE:
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
	if selected_cards.size() >= hand.size():
		return "Keep at least one loose card for the mandatory discard."
	return ""


func _remove_from_hand(cards: Array[CardData]) -> void:
	for card in cards:
		hand.erase(card)


func _failure(message: String) -> Dictionary:
	return {"ok": false, "message": message}
