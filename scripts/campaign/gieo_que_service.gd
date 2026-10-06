class_name GieoQueService
extends RefCounted
## Owns the reading, isolated RNG, physical targets, price and permanent mutation.
signal state_changed(state: StringName, payload: Dictionary)
signal pull_charged(price_vnd: int, free_pull: bool)
signal transformation_completed(transformations: Array[Dictionary])

const LINE_POSITIVE := "P"
const LINE_NEGATIVE := "N"
const STATE_READY := &"ready"
const STATE_RESULT := &"result"
const STATE_TARGET_SELECTION := &"target_selection"
const STATE_TARGET_REVEAL := &"target_reveal"
const STATE_TRANSFORM := &"transform"
const STATE_COMPLETE := &"complete"
const TARGET_RANDOM_ONE := "random_one"
const TARGET_CONSECUTIVE_3 := "consecutive_3"
const TARGET_RANDOM_SAME_SUIT_3 := "random_same_suit_3"
const JACKPOT_THUAN_DUONG := "thuan_duong"
const JACKPOT_THUAN_AM := "thuan_am"
const BASE_COST_VND := 10_000
const DAY_LINEAR_STEP_VND := 5_000
const PAID_GROWTH_FACTOR := 2
const FIRST_TRIGRAM_FORTUNE := {"PPP": 3, "PPN": 2, "PNP": 2, "PNN": 1, "NPP": -1, "NPN": -2, "NNP": -2, "NNN": -3}
const SECOND_TRIGRAM_TARGETS := {
	"PPP": TARGET_CONSECUTIVE_3, "PPN": TARGET_RANDOM_ONE, "PNP": TARGET_RANDOM_ONE,
	"PNN": TARGET_RANDOM_ONE, "NPP": TARGET_RANDOM_ONE, "NPN": TARGET_RANDOM_ONE,
	"NNP": TARGET_RANDOM_ONE, "NNN": TARGET_RANDOM_SAME_SUIT_3,
}
const TARGET_LABEL_KEYS := {TARGET_RANDOM_ONE: "GIEO_TARGET_RANDOM_ONE", TARGET_CONSECUTIVE_3: "GIEO_TARGET_CONSECUTIVE_3", TARGET_RANDOM_SAME_SUIT_3: "GIEO_TARGET_SAME_SUIT_3"}

var wallet: VndWallet
var persistent_deck: Array[CardData] = []
var state: StringName = STATE_READY
var current_day_index: int = 0
var free_cast_used_today: bool = false
var paid_cast_count_today: int = 0
var current_result: Dictionary = {}
var resolved_targets: Array[CardData] = []
var last_transformations: Array[Dictionary] = []
var _rng := RandomNumberGenerator.new()
var _casting := false

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
	return wallet.scaled_cost(BASE_COST_VND, 4)

func current_pull_cost() -> int:
	if not free_cast_used_today: return 0
	# Keep saved long-running campaigns within signed 64-bit economy arithmetic.
	var price := daily_base_cost()
	for _paid in mini(paid_cast_count_today, 63):
		if price > 4_611_686_018_427_387_903: return 9_223_372_036_854_775_807
		price *= PAID_GROWTH_FACTOR
	return price

func can_afford_pull() -> bool:
	return current_pull_cost() <= 0 or wallet.balance_vnd >= current_pull_cost()

func owned_card(id: String) -> CardData:
	for card in persistent_deck:
		if card.unique_id == id: return card
	return null

func add_owned_card(card: CardData) -> bool:
	if _casting or state not in [STATE_READY, STATE_COMPLETE] or card == null or card.unique_id.is_empty() or owned_card(card.unique_id) != null: return false
	if card.rank_index not in range(1, 14) or card.rank != DeckManager.RANKS[card.rank_index - 1] or card.suit not in DeckManager.SUITS: return false
	persistent_deck.append(card)
	return true

func remove_owned_card(id: String) -> bool:
	if _casting or state not in [STATE_READY, STATE_COMPLETE] or persistent_deck.size() <= DealState.MIN_CAMPAIGN_CARDS: return false
	var card := owned_card(id)
	if card == null: return false
	persistent_deck.erase(card)
	resolved_targets.assign(resolved_targets.filter(func(target: CardData): return target.unique_id != id))
	last_transformations.assign(last_transformations.filter(func(change: Dictionary): return not change.get("card") is CardData or (change.get("card") as CardData).unique_id != id))
	return true

func eligible_cards() -> Array[CardData]:
	return persistent_deck.filter(func(card: CardData): return not card.transformation_locked)

func cast(forced_lines: Array[String] = []) -> Dictionary:
	if _casting: return _failure("This reading is already being charged.")
	if state not in [STATE_READY, STATE_RESULT, STATE_COMPLETE]: return _failure("A committed cast must finish before another reading.")
	if eligible_cards().is_empty(): return _failure("Every card is sealed against transformations this run.")
	if not forced_lines.is_empty() and (forced_lines.size() != 6 or not forced_lines.all(func(line: String): return line in [LINE_POSITIVE, LINE_NEGATIVE])):
		return _failure("A reading needs exactly six P/N lines.")
	var price := current_pull_cost()
	if price > 0 and wallet.balance_vnd < price: return _failure("Not enough VNĐ for this cast.")
	var free_pull := not free_cast_used_today
	_casting = true
	var lines: Array[String] = forced_lines.duplicate()
	if lines.is_empty():
		for _line_index in 6: lines.append(LINE_POSITIVE if _rng.randi_range(0, 1) == 1 else LINE_NEGATIVE)
	current_result = reading_for_lines(lines)
	current_result.merge({"price_vnd": price, "free_pull": free_pull})
	resolved_targets.clear()
	last_transformations.clear()
	if free_pull: free_cast_used_today = true
	else: paid_cast_count_today += 1
	# Wallet observers (including saves) see the charged reading and counters as
	# one committed state, and cannot re-enter payment or acceptance mid-charge.
	state = STATE_RESULT
	if price > 0: wallet.apply_vnd(-price, "gieo_que_cast")
	_set_state(STATE_RESULT, current_result)
	# Charge notification observes the complete save-safe reading.
	pull_charged.emit(price, free_pull)
	_casting = false
	return {"ok": true, "result": current_result.duplicate(true), "price_vnd": price, "free_pull": free_pull}

static func reading_for_lines(lines: Array[String]) -> Dictionary:
	var first := "".join(lines.slice(0, 3))
	var second := "".join(lines.slice(3, 6))
	var jackpot := JACKPOT_THUAN_DUONG if first == "PPP" and second == "PPP" else JACKPOT_THUAN_AM if first == "NNN" and second == "NNN" else ""
	return {"lines": lines.duplicate(), "first_trigram": first, "second_trigram": second,
		"fortune_delta": int(FIRST_TRIGRAM_FORTUNE[first]), "targeting": String(SECOND_TRIGRAM_TARGETS[second]), "jackpot": jackpot}

func reroll(forced_lines: Array[String] = []) -> Dictionary:
	if state != STATE_RESULT: return _failure("Reroll is available only before accepting a cast.")
	return cast(forced_lines)

func refuse() -> Dictionary:
	if _casting: return _failure("The reading is still being charged.")
	if state != STATE_RESULT: return _failure("Refuse is available only before accepting a cast.")
	_clear_operation()
	_set_state(STATE_READY)
	return {"ok": true}

func accept() -> Dictionary:
	if _casting: return _failure("The reading is still being charged.")
	if state != STATE_RESULT: return _failure("Accept is available only on the revealed quẻ.")
	return _resolve_targeting_after_accept()

func choose_target(card_id: String) -> Dictionary:
	if state != STATE_TARGET_SELECTION: return _failure("No card target is being selected.")
	for card in eligible_cards():
		if card.unique_id == card_id:
			resolved_targets = [card]
			return apply_resolved_targets()
	return _failure("Choose one eligible physical card.")

func apply_resolved_targets() -> Dictionary:
	if state not in [STATE_TARGET_REVEAL, STATE_TARGET_SELECTION]: return _failure("Targets have not been resolved yet.")
	if resolved_targets.is_empty(): return _failure("The cast has no physical card target.")
	# Validate the whole batch before touching any card.
	var ids := {}
	for card in resolved_targets:
		if card not in persistent_deck or card.transformation_locked or ids.has(card.unique_id): return _failure("The physical target is unavailable.")
		ids[card.unique_id] = true
	last_transformations.clear()
	for card in resolved_targets:
		var before := card.permanent_snapshot()
		card.adjust_fortune(int(current_result.fortune_delta))
		match String(current_result.get("jackpot", "")):
			JACKPOT_THUAN_DUONG: card.add_jackpot(CardData.JACKPOT_LIQUID)
			JACKPOT_THUAN_AM: card.add_jackpot(CardData.JACKPOT_NEGATIVE)
		last_transformations.append({"card": card, "before": before, "after": card.permanent_snapshot()})
	_set_state(STATE_TRANSFORM, {"transformations": last_transformations})
	transformation_completed.emit(last_transformations)
	return {"ok": true, "transformations": last_transformations}

func finish_transformation() -> Dictionary:
	if state != STATE_TRANSFORM: return _failure("No transformation presentation is active.")
	_set_state(STATE_COMPLETE, {"transformations": last_transformations})
	return {"ok": true}

func effect_label() -> String:
	var delta := int(current_result.get("fortune_delta", 0))
	var text := TranslationServer.translate("CARD_FORTUNE") + " %+d" % delta
	match String(current_result.get("jackpot", "")):
		JACKPOT_THUAN_DUONG: return "THUẦN DƯƠNG · " + text + " · " + TranslationServer.translate("GIEO_PROPERTY_LIQUID")
		JACKPOT_THUAN_AM: return "THUẦN ÂM · " + text + " · " + TranslationServer.translate("CARD_NEGATIVE")
	return text

func targeting_label_key() -> String:
	if not String(current_result.get("jackpot", "")).is_empty(): return "GIEO_TARGET_CHOOSE_ONE_EXACT"
	return String(TARGET_LABEL_KEYS.get(String(current_result.get("targeting", "")), ""))

func targeting_label() -> String:
	return TranslationServer.translate(targeting_label_key())

func _resolve_targeting_after_accept() -> Dictionary:
	var source := eligible_cards()
	if source.is_empty(): return _failure("Every card is sealed against transformations this run.")
	if not String(current_result.get("jackpot", "")).is_empty():
		resolved_targets.clear()
		_set_state(STATE_TARGET_SELECTION)
	else:
		match String(current_result.get("targeting", "")):
			TARGET_RANDOM_ONE: resolved_targets = CardTargetQuery.random_cards(source, 1, _rng)
			TARGET_CONSECUTIVE_3: resolved_targets = CardTargetQuery.random_consecutive(source, 3, _rng)
			TARGET_RANDOM_SAME_SUIT_3: resolved_targets = CardTargetQuery.random_same_suit(source, 3, _rng)
			_: return _failure("Unknown targeting rule.")
		# Zodiac seals/identity changes can strand a pattern in an otherwise full deck.
		# Never silently change a promised trio into an unrelated single card.
		if resolved_targets.is_empty(): return _failure("No unsealed cards fit this pattern. Reroll or refuse this reading.")
		_set_state(STATE_TARGET_REVEAL, {"targets": resolved_targets})
	return {"ok": true, "state": state, "targets": resolved_targets}

func migrate_pending_reading() -> void:
	if current_result.is_empty() or current_result.has("fortune_delta"): return
	var old_result := current_result.duplicate(true)
	var lines: Array[String] = []
	for line: String in old_result.get("lines", []): lines.append("P" if line == "D" else "N")
	if lines.size() != 6:
		_clear_operation()
		state = STATE_READY
		return
	current_result = reading_for_lines(lines)
	current_result.merge({"price_vnd": old_result.get("price_vnd", 0), "free_pull": old_result.get("free_pull", false)})
	for transformation in last_transformations:
		for key in ["before", "after"]:
			transformation[key] = CardData.from_permanent_snapshot(transformation[key]).permanent_snapshot()
	# Already-applied transformations must never be applied twice.
	if state in [STATE_TRANSFORM, STATE_COMPLETE, STATE_RESULT]: return
	resolved_targets.clear()
	state = STATE_RESULT
	_resolve_targeting_after_accept()

func _clear_operation() -> void:
	current_result.clear()
	resolved_targets.clear()
	last_transformations.clear()

func _set_state(next_state: StringName, payload: Dictionary = {}) -> void:
	state = next_state
	state_changed.emit(state, payload)

func _failure(message: String) -> Dictionary:
	return {"ok": false, "message": message}

# Stable fields of the existing V3 run envelope. Change this schema explicitly.
const RUN_SAVE_FIELDS_V3 := ["persistent_deck", "state", "current_day_index", "free_cast_used_today", "paid_cast_count_today", "current_result", "resolved_targets", "last_transformations"]
const RUN_SNAPSHOT_FIELDS := preload("res://scripts/campaign/run_snapshot_fields.gd")

func run_snapshot() -> Dictionary:
	return RUN_SNAPSHOT_FIELDS.fields(self, RUN_SAVE_FIELDS_V3)

func restore_run_snapshot(data: Dictionary) -> void:
	RUN_SNAPSHOT_FIELDS.apply_fields(self, data, RUN_SAVE_FIELDS_V3)

func run_rng_state() -> int:
	return _rng.state

func restore_run_rng(state_value: int) -> void:
	_rng.state = state_value
	migrate_pending_reading()
