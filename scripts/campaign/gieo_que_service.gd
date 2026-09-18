class_name GieoQueService
extends RefCounted

signal state_changed(state: StringName, payload: Dictionary)
signal pull_charged(price_vnd: int, free_pull: bool)
signal transformation_completed(transformations: Array[Dictionary])

const LINE_DUONG := "D"
const LINE_AM := "A"

const STATE_READY := &"ready"
const STATE_RESULT := &"result"
const STATE_DESTINATION_SELECTION := &"destination_selection"
const STATE_TARGET_SELECTION := &"target_selection"
const STATE_TARGET_REVEAL := &"target_reveal"
const STATE_TRANSFORM := &"transform"
const STATE_COMPLETE := &"complete"

const EFFECT_ADD_GOLD_SET := "add_gold_set"
const EFFECT_CHOOSE_RANK := "choose_rank"
const EFFECT_ADD_GOLD_MAKING_PHOM := "add_gold_making_phom"
const EFFECT_ADD_GOLD_BIG_PHOM := "add_gold_big_phom"
const EFFECT_ADD_GOLD_LAST_CALL := "add_gold_last_call"
const EFFECT_ADD_GOLD_EXTEND := "add_gold_extend"
const EFFECT_CHOOSE_SUIT := "choose_suit"
const EFFECT_ADD_GOLD_RUN := "add_gold_run"

const TARGET_RANDOM_SAME_SUIT_3 := "random_same_suit_3"
const TARGET_RANDOM_SAME_SUIT_2 := "random_same_suit_2"
const TARGET_CHOOSE_ONE := "choose_one"
const TARGET_OFFER_THREE := "offer_three"
const TARGET_CONSECUTIVE_2 := "consecutive_2"
const TARGET_CONSECUTIVE_3 := "consecutive_3"

const JACKPOT_THUAN_DUONG := "thuan_duong"
const JACKPOT_THUAN_AM := "thuan_am"

const PROPERTY_GOLD_SET := "GOLD_SET"
const PROPERTY_GOLD_MAKING_PHOM := "GOLD_MAKING_PHOM"
const PROPERTY_GOLD_EXTEND := "GOLD_EXTEND"
const PROPERTY_GOLD_RUN := "GOLD_RUN"

const PROPERTY_GOLD_BIG_PHOM := "GOLD_BIG_PHOM"
const PROPERTY_GOLD_LAST_CALL := "GOLD_LAST_CALL"
const PROPERTY_MELD_RETRIGGER := "MELD_RETRIGGER"
const GOLD_PROPERTIES := [PROPERTY_GOLD_MAKING_PHOM, PROPERTY_GOLD_EXTEND, PROPERTY_GOLD_SET, PROPERTY_GOLD_RUN, PROPERTY_GOLD_BIG_PHOM, PROPERTY_GOLD_LAST_CALL]

# First-pass tuning lives in one place until final campaign balance is authored.
const BASE_COST_VND := 10_000
const DAY_LINEAR_STEP_VND := 5_000
const PAID_GROWTH_FACTOR := 2

const FIRST_TRIGRAM_EFFECTS := {
	"DDD": EFFECT_ADD_GOLD_SET,
	"DDA": EFFECT_CHOOSE_RANK,
	"DAD": EFFECT_ADD_GOLD_MAKING_PHOM,
	"DAA": EFFECT_ADD_GOLD_BIG_PHOM,
	"ADD": EFFECT_ADD_GOLD_LAST_CALL,
	"ADA": EFFECT_ADD_GOLD_EXTEND,
	"AAD": EFFECT_CHOOSE_SUIT,
	"AAA": EFFECT_ADD_GOLD_RUN,
}

const SECOND_TRIGRAM_TARGETS := {
	"DDD": TARGET_RANDOM_SAME_SUIT_3,
	"DDA": TARGET_RANDOM_SAME_SUIT_2,
	"DAD": TARGET_CHOOSE_ONE,
	"DAA": TARGET_OFFER_THREE,
	"ADD": TARGET_OFFER_THREE,
	"ADA": TARGET_CHOOSE_ONE,
	"AAD": TARGET_CONSECUTIVE_2,
	"AAA": TARGET_CONSECUTIVE_3,
}

const EFFECT_LABELS := {
	EFFECT_ADD_GOLD_SET: "ADD SET GOLD",
	EFFECT_CHOOSE_RANK: "CHOOSE RANK",
	EFFECT_ADD_GOLD_MAKING_PHOM: "ADD MAKING-PHỎM GOLD",
	EFFECT_ADD_GOLD_BIG_PHOM: "ADD BIG PHỎM GOLD",
	EFFECT_ADD_GOLD_LAST_CALL: "ADD LAST CALL GOLD",
	EFFECT_ADD_GOLD_EXTEND: "ADD EXTEND GOLD",
	EFFECT_CHOOSE_SUIT: "CHOOSE SUIT",
	EFFECT_ADD_GOLD_RUN: "ADD RUN GOLD",
}

const TARGET_LABELS := {
	TARGET_RANDOM_SAME_SUIT_3: "3 RANDOM CARDS OF THE SAME SUIT",
	TARGET_RANDOM_SAME_SUIT_2: "2 RANDOM CARDS OF THE SAME SUIT",
	TARGET_CHOOSE_ONE: "CHOOSE 1 CARD",
	TARGET_OFFER_THREE: "CHOOSE 1 OF 3 RANDOMLY OFFERED CARDS",
	TARGET_CONSECUTIVE_2: "2 RANDOM CARDS WITH CONSECUTIVE RANKS",
	TARGET_CONSECUTIVE_3: "3 RANDOM CARDS WITH CONSECUTIVE RANKS",
}

const EFFECT_LABEL_KEYS := {
	EFFECT_ADD_GOLD_SET: "GIEO_EFFECT_GOLD_SET",
	EFFECT_CHOOSE_RANK: "GIEO_EFFECT_CHOOSE_RANK",
	EFFECT_ADD_GOLD_MAKING_PHOM: "GIEO_EFFECT_GOLD_MAKING_PHOM",
	EFFECT_ADD_GOLD_BIG_PHOM: "GIEO_EFFECT_ADD_GOLD_BIG_PHOM",
	EFFECT_ADD_GOLD_LAST_CALL: "GIEO_EFFECT_ADD_GOLD_LAST_CALL",
	EFFECT_ADD_GOLD_EXTEND: "GIEO_EFFECT_GOLD_EXTEND",
	EFFECT_CHOOSE_SUIT: "GIEO_EFFECT_CHOOSE_SUIT",
	EFFECT_ADD_GOLD_RUN: "GIEO_EFFECT_GOLD_RUN",
}

const TARGET_LABEL_KEYS := {
	TARGET_RANDOM_SAME_SUIT_3: "GIEO_TARGET_SAME_SUIT_3",
	TARGET_RANDOM_SAME_SUIT_2: "GIEO_TARGET_SAME_SUIT_2",
	TARGET_CHOOSE_ONE: "GIEO_TARGET_CHOOSE_ONE",
	TARGET_OFFER_THREE: "GIEO_TARGET_OFFER_THREE",
	TARGET_CONSECUTIVE_2: "GIEO_TARGET_CONSECUTIVE_2",
	TARGET_CONSECUTIVE_3: "GIEO_TARGET_CONSECUTIVE_3",
}

var wallet: VndWallet
var persistent_deck: Array[CardData] = []
var state: StringName = STATE_READY
var current_day_index: int = 0
var free_cast_used_today: bool = false
var paid_cast_count_today: int = 0
var current_result: Dictionary = {}
var resolved_destination: String = ""
var resolved_targets: Array[CardData] = []
var last_transformations: Array[Dictionary] = []
var _rng := RandomNumberGenerator.new()


func _init(p_wallet: VndWallet = null) -> void:
	wallet = p_wallet if p_wallet != null else VndWallet.new()
	_rng.randomize()
	reset_campaign()


func reset_campaign() -> void:
	persistent_deck = DeckManager.new().build_standard_deck()
	current_day_index = 0
	free_cast_used_today = false
	paid_cast_count_today = 0
	_clear_operation()
	_set_state(STATE_READY)


func begin_day(day_index: int) -> void:
	current_day_index = maxi(day_index, 0)
	free_cast_used_today = false
	paid_cast_count_today = 0
	_clear_operation()
	_set_state(STATE_READY)


func set_seed_value(seed_value: int) -> void:
	_rng.seed = seed_value


func daily_base_cost() -> int:
	return BASE_COST_VND + DAY_LINEAR_STEP_VND * current_day_index


func current_pull_cost() -> int:
	if not free_cast_used_today:
		return 0
	return wallet.scaled_cost(daily_base_cost() * int(pow(PAID_GROWTH_FACTOR, paid_cast_count_today)), 5)


func can_afford_pull() -> bool:
	return current_pull_cost() <= 0 or wallet.balance_vnd >= current_pull_cost()


func cast(forced_lines: Array[String] = []) -> Dictionary:
	if state not in [STATE_READY, STATE_RESULT, STATE_COMPLETE]:
		return _failure("A committed cast must finish before another pull.")
	var price := current_pull_cost()
	if price > 0 and wallet.balance_vnd < price:
		return _failure("Not enough VND for this cast.")
	var free_pull := not free_cast_used_today
	if free_pull:
		free_cast_used_today = true
	else:
		wallet.apply_vnd(-price, "gieo_que_cast")
		paid_cast_count_today += 1
	pull_charged.emit(price, free_pull)

	var lines: Array[String] = []
	if forced_lines.size() == 6:
		lines.assign(forced_lines)
	else:
		for _line_index in range(6):
			lines.append(LINE_DUONG if _rng.randi_range(0, 1) == 1 else LINE_AM)
	var first := "".join(lines.slice(0, 3))
	var second := "".join(lines.slice(3, 6))
	var jackpot := ""
	if first == "DDD" and second == "DDD":
		jackpot = JACKPOT_THUAN_DUONG
	elif first == "AAA" and second == "AAA":
		jackpot = JACKPOT_THUAN_AM
	current_result = {
		"lines": lines,
		"first_trigram": first,
		"second_trigram": second,
		"effect": String(FIRST_TRIGRAM_EFFECTS[first]),
		"targeting": String(SECOND_TRIGRAM_TARGETS[second]),
		"jackpot": jackpot,
		"price_vnd": price,
		"free_pull": free_pull,
	}
	resolved_destination = ""
	resolved_targets.clear()
	last_transformations.clear()
	_set_state(STATE_RESULT, current_result)
	return {"ok": true, "result": current_result.duplicate(true), "price_vnd": price, "free_pull": free_pull}


func reroll(forced_lines: Array[String] = []) -> Dictionary:
	if state != STATE_RESULT:
		return _failure("Reroll is available only before accepting a cast.")
	return cast(forced_lines)


func refuse() -> Dictionary:
	if state != STATE_RESULT:
		return _failure("Refuse is available only before accepting a cast.")
	_clear_operation()
	_set_state(STATE_READY)
	return {"ok": true}


func accept() -> Dictionary:
	if state != STATE_RESULT:
		return _failure("Accept is available only on the revealed quẻ.")
	var jackpot := String(current_result.get("jackpot", ""))
	var effect := String(current_result.get("effect", ""))
	if jackpot != "" or effect in [EFFECT_CHOOSE_RANK, EFFECT_CHOOSE_SUIT]:
		_set_state(STATE_DESTINATION_SELECTION, current_result)
		return {"ok": true, "state": state}
	return _resolve_targeting_after_accept()


func choose_destination(destination: String) -> Dictionary:
	if state != STATE_DESTINATION_SELECTION:
		return _failure("No Rank or Suit destination is being selected.")
	var jackpot := String(current_result.get("jackpot", ""))
	var effect := String(current_result.get("effect", ""))
	var chooses_rank := jackpot == JACKPOT_THUAN_DUONG or effect == EFFECT_CHOOSE_RANK
	if chooses_rank:
		if not DeckManager.RANKS.has(destination):
			return _failure("Choose a Rank from A through K.")
	else:
		if not DeckManager.SUITS.has(destination):
			return _failure("Choose one normal Suit.")
	resolved_destination = destination
	return _resolve_targeting_after_accept()


func choose_target(card_id: String) -> Dictionary:
	if state != STATE_TARGET_SELECTION:
		return _failure("No card target is being selected.")
	var legal_targets: Array[CardData] = resolved_targets if not resolved_targets.is_empty() else persistent_deck
	for card in legal_targets:
		if card.unique_id == card_id:
			resolved_targets = [card]
			return apply_resolved_targets()
	return _failure("Choose one of the displayed physical cards.")


func apply_resolved_targets() -> Dictionary:
	if state not in [STATE_TARGET_REVEAL, STATE_TARGET_SELECTION]:
		return _failure("Targets have not been resolved yet.")
	if resolved_targets.is_empty():
		return _failure("The cast has no physical card target.")
	last_transformations.clear()
	for card in resolved_targets:
		var before := card.permanent_snapshot()
		_apply_effect(card)
		last_transformations.append({
			"card": card,
			"before": before,
			"after": card.permanent_snapshot(),
		})
	_set_state(STATE_TRANSFORM, {"transformations": last_transformations})
	transformation_completed.emit(last_transformations)
	return {"ok": true, "transformations": last_transformations}


func finish_transformation() -> Dictionary:
	if state != STATE_TRANSFORM:
		return _failure("No transformation presentation is active.")
	_set_state(STATE_COMPLETE, {"transformations": last_transformations})
	return {"ok": true}


func return_to_ready() -> void:
	if state == STATE_COMPLETE:
		_clear_operation()
		_set_state(STATE_READY)


func effect_label() -> String:
	var jackpot := String(current_result.get("jackpot", ""))
	if jackpot == JACKPOT_THUAN_DUONG:
		return "THUẦN DƯƠNG · CHOOSE RANK + LIQUID"
	if jackpot == JACKPOT_THUAN_AM:
		return "THUẦN ÂM · CHOOSE SUIT + LIQUID"
	return String(EFFECT_LABELS.get(String(current_result.get("effect", "")), ""))


func targeting_label() -> String:
	if not String(current_result.get("jackpot", "")).is_empty():
		return "CHOOSE EXACTLY 1 CARD"
	return String(TARGET_LABELS.get(String(current_result.get("targeting", "")), ""))


func effect_label_key() -> String:
	var jackpot := String(current_result.get("jackpot", ""))
	if jackpot == JACKPOT_THUAN_DUONG:
		return "GIEO_JACKPOT_DUONG"
	if jackpot == JACKPOT_THUAN_AM:
		return "GIEO_JACKPOT_AM"
	return String(EFFECT_LABEL_KEYS.get(String(current_result.get("effect", "")), ""))


func targeting_label_key() -> String:
	if not String(current_result.get("jackpot", "")).is_empty():
		return "GIEO_TARGET_CHOOSE_ONE_EXACT"
	return String(TARGET_LABEL_KEYS.get(String(current_result.get("targeting", "")), ""))


func _resolve_targeting_after_accept() -> Dictionary:
	var jackpot := String(current_result.get("jackpot", ""))
	if not jackpot.is_empty():
		resolved_targets.clear()
		_set_state(STATE_TARGET_SELECTION, {"mode": TARGET_CHOOSE_ONE})
		return {"ok": true, "state": state}
	var targeting := String(current_result.get("targeting", ""))
	match targeting:
		TARGET_CHOOSE_ONE:
			resolved_targets.clear()
			_set_state(STATE_TARGET_SELECTION, {"mode": targeting})
		TARGET_OFFER_THREE:
			resolved_targets = _random_cards(mini(3, persistent_deck.size()))
			_set_state(STATE_TARGET_SELECTION, {"mode": targeting, "targets": resolved_targets})
		TARGET_RANDOM_SAME_SUIT_3:
			resolved_targets = _random_same_suit_group(3)
			_set_state(STATE_TARGET_REVEAL, {"mode": targeting, "targets": resolved_targets})
		TARGET_RANDOM_SAME_SUIT_2:
			resolved_targets = _random_same_suit_group(2)
			_set_state(STATE_TARGET_REVEAL, {"mode": targeting, "targets": resolved_targets})
		TARGET_CONSECUTIVE_3:
			resolved_targets = _random_consecutive_group(3)
			_set_state(STATE_TARGET_REVEAL, {"mode": targeting, "targets": resolved_targets})
		TARGET_CONSECUTIVE_2:
			resolved_targets = _random_consecutive_group(2)
			_set_state(STATE_TARGET_REVEAL, {"mode": targeting, "targets": resolved_targets})
		_:
			return _failure("Unknown targeting rule.")
	return {"ok": true, "state": state, "targets": resolved_targets}


func _apply_effect(card: CardData) -> void:
	var jackpot := String(current_result.get("jackpot", ""))
	if jackpot == JACKPOT_THUAN_DUONG:
		_apply_rank(card, resolved_destination)
		card.add_gieo_property(PROPERTY_MELD_RETRIGGER)
		return
	if jackpot == JACKPOT_THUAN_AM:
		card.apply_suit(resolved_destination)
		card.add_gieo_property(PROPERTY_MELD_RETRIGGER)
		return
	match String(current_result.get("effect", "")):
		EFFECT_CHOOSE_RANK:
			_apply_rank(card, resolved_destination)
		EFFECT_CHOOSE_SUIT:
			card.apply_suit(resolved_destination)
		EFFECT_ADD_GOLD_BIG_PHOM:
			card.add_gieo_property(PROPERTY_GOLD_BIG_PHOM)
		EFFECT_ADD_GOLD_LAST_CALL:
			card.add_gieo_property(PROPERTY_GOLD_LAST_CALL)
		EFFECT_ADD_GOLD_SET:
			card.add_gieo_property(PROPERTY_GOLD_SET)
		EFFECT_ADD_GOLD_MAKING_PHOM:
			card.add_gieo_property(PROPERTY_GOLD_MAKING_PHOM)
		EFFECT_ADD_GOLD_EXTEND:
			card.add_gieo_property(PROPERTY_GOLD_EXTEND)
		EFFECT_ADD_GOLD_RUN:
			card.add_gieo_property(PROPERTY_GOLD_RUN)


func _apply_rank(card: CardData, rank: String) -> void:
	var rank_offset := DeckManager.RANKS.find(rank)
	if rank_offset >= 0:
		card.apply_rank(rank, rank_offset + 1)


func _random_cards(count: int, source: Array[CardData] = []) -> Array[CardData]:
	var pool: Array[CardData] = []
	pool.append_array(persistent_deck if source.is_empty() else source)
	_shuffle_cards(pool)
	var picked: Array[CardData] = []
	for index in range(mini(count, pool.size())):
		picked.append(pool[index])
	return picked


func _random_same_suit_group(requested_count: int) -> Array[CardData]:
	for target_count in range(requested_count, 0, -1):
		var eligible_suits: Array[String] = []
		for suit in DeckManager.SUITS:
			var suit_cards := _cards_with_suit(suit)
			if suit_cards.size() >= target_count:
				eligible_suits.append(suit)
		if not eligible_suits.is_empty():
			var suit := eligible_suits[_rng.randi_range(0, eligible_suits.size() - 1)]
			return _random_cards(target_count, _cards_with_suit(suit))
	return []


func _random_consecutive_group(requested_count: int) -> Array[CardData]:
	for target_count in range(requested_count, 1, -1):
		var starts: Array[int] = []
		for start_rank in range(1, 15 - target_count):
			var valid := true
			for offset in range(target_count):
				if _cards_with_rank_index(start_rank + offset).is_empty():
					valid = false
					break
			if valid:
				starts.append(start_rank)
		if not starts.is_empty():
			var chosen_start := starts[_rng.randi_range(0, starts.size() - 1)]
			var picked: Array[CardData] = []
			for offset in range(target_count):
				var candidates := _cards_with_rank_index(chosen_start + offset)
				picked.append(candidates[_rng.randi_range(0, candidates.size() - 1)])
			return picked
	return _random_cards(1)


func _cards_with_suit(suit: String) -> Array[CardData]:
	var cards: Array[CardData] = []
	for card in persistent_deck:
		if card.suit == suit:
			cards.append(card)
	return cards


func _cards_with_rank_index(rank_index: int) -> Array[CardData]:
	var cards: Array[CardData] = []
	for card in persistent_deck:
		if card.rank_index == rank_index:
			cards.append(card)
	return cards


func _shuffle_cards(cards: Array[CardData]) -> void:
	for index in range(cards.size() - 1, 0, -1):
		var swap_index := _rng.randi_range(0, index)
		var temporary := cards[index]
		cards[index] = cards[swap_index]
		cards[swap_index] = temporary


func _clear_operation() -> void:
	current_result.clear()
	resolved_destination = ""
	resolved_targets.clear()
	last_transformations.clear()


func _set_state(next_state: StringName, payload: Dictionary = {}) -> void:
	state = next_state
	state_changed.emit(state, payload)


func _failure(message: String) -> Dictionary:
	return {"ok": false, "message": message}
