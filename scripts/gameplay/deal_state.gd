class_name DealState
extends RefCounted

signal state_changed(result: Dictionary)
signal new_phom_scored(context: ScoringContext)
signal extension_scored(context: ScoringContext)
signal phase_about_to_settle(context: Dictionary)
signal deadwood_calculated(context: Dictionary)
signal deal_about_to_resolve(context: Dictionary)
signal u_triggered(context: Dictionary)
signal meld_exhaustion_triggered(meld: MeldState, context: Dictionary)
signal exhaustion_triggered(context: Dictionary)

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

var action_counts: Dictionary = {}
var action_history: Array[Dictionary] = []
var deal_journal_cursor := 0

var deck := DeckManager.new()
var scoring := ScoringPipeline.new()
var wallet := VndWallet.new()
var relics := RelicRuntime.new()
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
var den_da_used_this_turn: bool = false
var nau_da_used_phases: Dictionary = {}
var pair_used_this_turn: bool = false
var pair_used_phases: Dictionary = {}
var c2_used: bool = false
var nuoc_voi_used_phases: Dictionary = {}
var sam_dua_preserved_cards: Array[CardData] = []
var sam_dua_used: bool = false
var recyclable_spent_cards: Array[CardData] = []
var exhaustion_count: int = 0

var _next_meld_id: int = 1
var _turn_started_with_ten: bool = false
var _turn_committed_card_count: int = 0
var _expected_deal_card_ids: Dictionary = {}
var campaign_deck_cards: Array[CardData] = []


func _init() -> void:
	state_changed.connect(_count_action)
	deck.draw_requested_while_empty.connect(_on_draw_requested_while_empty)


func start_deal(shuffle_seed: int = -1, reset_wallet: bool = false, opening_ids: Array[String] = []) -> Dictionary:
	if reset_wallet:
		wallet.reset()
	action_counts.clear()
	action_history.clear()
	deal_journal_cursor = wallet.journal.size()
	if campaign_deck_cards.is_empty():
		deck.reset(shuffle_seed)
	else:
		deck.reset_from_campaign_cards(campaign_deck_cards, shuffle_seed)
	# Reorder only existing physical deal copies before the ordinary draw path.
	var opening: Array[CardData] = []
	for id in opening_ids:
		for card in deck.draw_pile:
			if card.unique_id == id:
				opening.append(card)
				deck.draw_pile.erase(card)
				break
	for index in range(opening.size() - 1, -1, -1):
		deck.draw_pile.append(opening[index])
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
	action_counts.clear()
	action_history.clear()
	deal_journal_cursor = wallet.journal.size()
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


func snapshot_state() -> Dictionary:
	var metric_snapshot := {
		"raw_gross": phase_metrics.raw_gross,
		"deadwood_total": phase_metrics.deadwood_total,
		"new_phom_count": phase_metrics.new_phom_count,
		"extension_count": phase_metrics.extension_count,
		"u": phase_metrics.u,
		"u_bonus_paid": phase_metrics.u_bonus_paid,
		"u_khan_count": phase_metrics.u_khan_count,
		"missed_discards": phase_metrics.missed_discards,
	}
	return {
		"action_counts": action_counts.duplicate(true),
		"action_history": action_history.duplicate(true),
		"deal_journal_cursor": deal_journal_cursor,
		"wallet_journal": wallet.journal.duplicate(true),
		"wallet_journal_opening": wallet.journal_opening_vnd,
		"deck": deck.snapshot_state(),
		"relics": relics.snapshot(),
		"hand": hand.duplicate(),
		"melds": melds.duplicate(),
		"discard_history": discard_history.duplicate(),
		"settlements": settlements.duplicate(),
		"phase_metrics": metric_snapshot,
		"current_phase": current_phase,
		"discard_count": discard_count,
		"phase_earnings_points": phase_earnings_points,
		"phase_new_meld_count": phase_new_meld_count,
		"state": state,
		"last_phase_resolution": last_phase_resolution.duplicate(true),
		"current_drink_id": current_drink_id,
		"tra_da_used_this_turn": tra_da_used_this_turn,
		"tra_da_extra_discard_pending": tra_da_extra_discard_pending,
		"nhan_tran_used_this_phase": nhan_tran_used_this_phase,
		"den_da_used_this_turn": den_da_used_this_turn,
		"nau_da_used_phases": nau_da_used_phases.duplicate(),
		"pair_used_this_turn": pair_used_this_turn,
		"pair_used_phases": pair_used_phases.duplicate(),
		"c2_used": c2_used,
		"nuoc_voi_used_phases": nuoc_voi_used_phases.duplicate(),
		"sam_dua_preserved_cards": sam_dua_preserved_cards.duplicate(),
		"sam_dua_used": sam_dua_used,
		"recyclable_spent_cards": recyclable_spent_cards.duplicate(),
		"exhaustion_count": exhaustion_count,
		"next_meld_id": _next_meld_id,
		"turn_started_with_ten": _turn_started_with_ten,
		"turn_committed_card_count": _turn_committed_card_count,
		"expected_deal_card_ids": _expected_deal_card_ids.duplicate(),
		"campaign_deck_cards": campaign_deck_cards.duplicate(),
		"wallet_balance_vnd": wallet.balance_vnd,
		"wallet_vnd_per_point": wallet.vnd_per_point,
	}


func restore_snapshot(snapshot: Dictionary) -> void:
	if snapshot.is_empty():
		return
	deck.restore_snapshot(snapshot.get("deck", {}) as Dictionary)
	relics.restore(snapshot.get("relics", {}))
	_restore_card_array(hand, snapshot.get("hand", []))
	_restore_meld_array(snapshot.get("melds", []))
	_restore_discard_array(snapshot.get("discard_history", []))
	_restore_settlement_array(snapshot.get("settlements", []))
	_restore_card_array(sam_dua_preserved_cards, snapshot.get("sam_dua_preserved_cards", []))
	_restore_card_array(recyclable_spent_cards, snapshot.get("recyclable_spent_cards", []))
	_restore_card_array(campaign_deck_cards, snapshot.get("campaign_deck_cards", []))
	var metric_snapshot := snapshot.get("phase_metrics", {}) as Dictionary
	phase_metrics.raw_gross = int(metric_snapshot.get("raw_gross", 0))
	phase_metrics.deadwood_total = int(metric_snapshot.get("deadwood_total", 0))
	phase_metrics.new_phom_count = int(metric_snapshot.get("new_phom_count", 0))
	phase_metrics.extension_count = int(metric_snapshot.get("extension_count", 0))
	phase_metrics.u = bool(metric_snapshot.get("u", false))
	phase_metrics.u_bonus_paid = bool(metric_snapshot.get("u_bonus_paid", false))
	phase_metrics.u_khan_count = int(metric_snapshot.get("u_khan_count", 0))
	phase_metrics.missed_discards = int(metric_snapshot.get("missed_discards", 0))
	current_phase = int(snapshot.get("current_phase", 1))
	discard_count = int(snapshot.get("discard_count", 0))
	phase_earnings_points = int(snapshot.get("phase_earnings_points", 0))
	phase_new_meld_count = int(snapshot.get("phase_new_meld_count", 0))
	state = String(snapshot.get("state", STATE_ACTIVE))
	last_phase_resolution = (snapshot.get("last_phase_resolution", {}) as Dictionary).duplicate(true)
	current_drink_id = String(snapshot.get("current_drink_id", DrinkCatalog.NONE))
	tra_da_used_this_turn = bool(snapshot.get("tra_da_used_this_turn", false))
	tra_da_extra_discard_pending = bool(snapshot.get("tra_da_extra_discard_pending", false))
	nhan_tran_used_this_phase = bool(snapshot.get("nhan_tran_used_this_phase", false))
	den_da_used_this_turn = bool(snapshot.get("den_da_used_this_turn", false))
	nau_da_used_phases = (snapshot.get("nau_da_used_phases", {}) as Dictionary).duplicate()
	pair_used_this_turn = bool(snapshot.get("pair_used_this_turn", false))
	pair_used_phases = (snapshot.get("pair_used_phases", {}) as Dictionary).duplicate()
	c2_used = bool(snapshot.get("c2_used", false))
	nuoc_voi_used_phases = (snapshot.get("nuoc_voi_used_phases", {}) as Dictionary).duplicate()
	sam_dua_used = bool(snapshot.get("sam_dua_used", false))
	exhaustion_count = int(snapshot.get("exhaustion_count", 0))
	_next_meld_id = int(snapshot.get("next_meld_id", 1))
	_turn_started_with_ten = bool(snapshot.get("turn_started_with_ten", false))
	_turn_committed_card_count = int(snapshot.get("turn_committed_card_count", 0))
	_expected_deal_card_ids = (snapshot.get("expected_deal_card_ids", {}) as Dictionary).duplicate()
	wallet.vnd_per_point = int(snapshot.get("wallet_vnd_per_point", VndWallet.VND_PER_POINT))
	wallet.reset(int(snapshot.get("wallet_balance_vnd", 0)))
	wallet.journal.assign(snapshot.get("wallet_journal", []))
	wallet.journal_opening_vnd = int(snapshot.get("wallet_journal_opening", wallet.balance_vnd))
	action_history.assign(snapshot.get("action_history", []))
	action_counts = snapshot.get("action_counts", {}).duplicate(true)
	deal_journal_cursor = int(snapshot.get("deal_journal_cursor", 0))


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


func set_campaign_deck(cards: Array[CardData]) -> void:
	campaign_deck_cards.clear()
	campaign_deck_cards.append_array(cards)


func exhaustion_status() -> Dictionary:
	return {
		"stock_count": deck.draw_pile.size(),
		"recyclable_spent_count": recyclable_spent_cards.size(),
		"discard_archive_count": deck.discard_pile.size(),
		"loose_hand_count": hand.size(),
		"table_card_count": _table_card_count(),
		"exhaustion_count": exhaustion_count,
	}


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


func can_use_den_da(card: CardData, record: DiscardRecord) -> bool:
	return current_drink_id == DrinkCatalog.DEN_DA and _card_actions_available() and not den_da_used_this_turn and card != null and hand.has(card) and record != null and discard_history.has(record) and (_discard_pile_index(record.card) >= 0 or recyclable_spent_cards.has(record.card))


func use_den_da(card: CardData, record: DiscardRecord) -> Dictionary:
	if not can_use_den_da(card, record):
		return _failure("Choose a loose card and a card still in this Deal's discards.")
	var recovered := record.card
	var index := _discard_pile_index(recovered)
	if index >= 0:
		deck.discard_pile[index] = card
	else:
		recyclable_spent_cards[recyclable_spent_cards.find(recovered)] = card
	hand.erase(card)
	hand.append(recovered)
	record.card = card
	den_da_used_this_turn = true
	var result := {"ok": true, "action": "den_da_swap", "discarded": card, "recovered": recovered}
	state_changed.emit(result)
	return result


func can_use_nau_da(meld_id: int) -> bool:
	return current_drink_id == DrinkCatalog.NAU_DA and _card_actions_available() and not nau_da_used_phases.has(current_phase) and get_meld(meld_id) != null


func use_nau_da(meld_id: int) -> Dictionary:
	if not can_use_nau_da(meld_id):
		return _failure("Choose a whole table Meld; Nâu đá is once per Phase.")
	var meld := get_meld(meld_id)
	var returned: Array[CardData] = meld.cards.duplicate()
	melds.erase(meld)
	hand.append_array(returned)
	nau_da_used_phases[current_phase] = true
	var result := {"ok": true, "action": "nau_da_return", "meld_id": meld_id, "returned": returned}
	state_changed.emit(result)
	return result


func has_phase_transition_choice() -> bool:
	return current_drink_id in [DrinkCatalog.SAM_DUA, DrinkCatalog.BAC_XIU]


func preservation_limit() -> int:
	return hand.size() if current_drink_id == DrinkCatalog.BAC_XIU else 3


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
	if meld.meld_type == MeldRules.TYPE_RUN:
		return MeldRules.is_compatible_run(remaining, meld.run_compatibility)
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
	if not has_phase_transition_choice():
		return _failure("Sâm dứa is not the active Drink.")
	if current_phase != 1 or state not in [STATE_FINAL_COMMIT_WINDOW, STATE_PHASE_CHOICE]:
		return _failure("Sâm dứa is prepared during the Phase 1 to Phase 2 transition.")
	if sam_dua_used:
		return _failure("Sâm dứa has already been used this Deal.")
	if cards.size() > preservation_limit():
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
		DrinkCatalog.DEN_DA:
			return not den_da_used_this_turn and _card_actions_available()
		DrinkCatalog.NAU_DA:
			return not nau_da_used_phases.has(current_phase) and _card_actions_available()
		DrinkCatalog.STING:
			return not pair_used_phases.has(current_phase) and _card_actions_available()
		DrinkCatalog.BO_HUC:
			return not pair_used_this_turn and _card_actions_available()
		DrinkCatalog.C2_ICED_TEA:
			return not c2_used and _card_actions_available()
		DrinkCatalog.NUOC_VOI:
			return current_phase in [1, 2] and not nuoc_voi_used_phases.has(current_phase) and _card_actions_available()
		DrinkCatalog.SAM_DUA, DrinkCatalog.BAC_XIU:
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


func create_meld(selected_cards: Array[CardData], use_drink: bool = false) -> Dictionary:
	var guard := _validate_commit_selection(selected_cards)
	if not guard.is_empty():
		return _failure(guard)
	var permission := meld_creation_rule(selected_cards, use_drink)
	var meld_type: String = permission.get("type", MeldRules.TYPE_INVALID)
	if meld_type == MeldRules.TYPE_INVALID:
		return _failure("Selected cards are not a Set or Run.")
	_remove_from_hand(selected_cards)
	var meld := MeldState.new(_next_meld_id, meld_type, selected_cards)
	meld.run_compatibility = permission.get("compatibility", "same")
	meld.pair_created = permission.get("pair", false)
	if meld.pair_created:
		pair_used_this_turn = true
		pair_used_phases[current_phase] = true
	if permission.get("c2", false):
		c2_used = true
	_next_meld_id += 1
	var context := scoring.score_new_meld(meld.cards, meld.meld_type, current_phase, phase_metrics.new_phom_count, state == STATE_FINAL_COMMIT_WINDOW)
	meld.scored_points = ScoringPipeline.meld_value(meld.cards)
	melds.append(meld)
	phase_metrics.new_phom_count += 1
	phase_new_meld_count = phase_metrics.new_phom_count
	if state == STATE_ACTIVE:
		_turn_committed_card_count += selected_cards.size()
	_apply_scoring_passes(context)
	_apply_relic_bonuses(context, meld.meld_id)
	new_phom_scored.emit(context)
	var result := {
		"ok": true,
		"action": "new_meld",
		"meld_id": meld.meld_id,
		"context": context,
		"scoring_passes": context.scoring_passes,
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
	if not can_extend_meld(meld_id, selected_cards):
		return _failure("Those cards do not legally extend the chosen Meld.")
	var old_score := ScoringPipeline.meld_value(meld.cards)
	var banked_score := meld.scored_points
	_remove_from_hand(selected_cards)
	if state == STATE_ACTIVE:
		_turn_committed_card_count += selected_cards.size()
	var additions: Array[CardData] = []
	additions.append_array(selected_cards)
	if meld.meld_type == MeldRules.TYPE_RUN and not meld.can_extend(selected_cards):
		meld.run_compatibility = "red" if current_drink_id == DrinkCatalog.MIA_TAC else "black"
	meld.extend(selected_cards)
	var context := scoring.score_extension(meld.cards, meld.meld_type, old_score, current_phase, additions, state == STATE_FINAL_COMMIT_WINDOW)
	meld.scored_points = maxi(banked_score, context.theoretical_score)
	phase_metrics.extension_count += 1
	_apply_scoring_passes(context)
	_apply_relic_bonuses(context, meld.meld_id)
	extension_scored.emit(context)
	var result := {
		"ok": true,
		"action": "extension",
		"meld_id": meld.meld_id,
		"context": context,
		"scoring_passes": context.scoring_passes,
	}
	state_changed.emit(result)
	return result


func discard_card(card: CardData) -> Dictionary:
	if state != STATE_ACTIVE:
		return _failure("Discarding is unavailable right now.")
	if card == null or not hand.has(card):
		return _failure("Choose one loose card to discard.")
	var is_tra_da_extra := current_drink_id == DrinkCatalog.TRA_DA and tra_da_extra_discard_pending
	var completed_u := not is_tra_da_extra and _turn_started_with_ten and _turn_committed_card_count == 9 and hand.size() == 1
	hand.erase(card)
	deck.discard(card)
	if is_tra_da_extra:
		tra_da_extra_discard_pending = false
		tra_da_used_this_turn = true
		discard_history.append(DiscardRecord.new(card, current_phase, discard_count, DiscardRecord.KIND_DRINK_EXTRA))
	else:
		discard_count += 1
		discard_history.append(DiscardRecord.new(card, current_phase, discard_count, DiscardRecord.KIND_MANDATORY))
		if current_drink_id == DrinkCatalog.TRA_DA and not hand.is_empty():
			tra_da_extra_discard_pending = true
	var u_triggered_now := completed_u
	if u_triggered_now:
		phase_metrics.u = true
		var u_bonus := current_deal_earnings_points()
		_record_phase_points(u_bonus, "u_bonus")
		phase_metrics.u_bonus_paid = true
		u_triggered.emit({
			"phase": current_phase,
			"card": card,
			"payout": u_bonus,
			"deal_earnings": u_bonus,
			"gross_multiplier": gross_payout_multiplier(),
		})
	var result := {
		"ok": true,
		"action": "discard",
		"card": card,
		"drawn": [] as Array[CardData],
		"u_triggered": u_triggered_now,
		"discard_kind": DiscardRecord.KIND_DRINK_EXTRA if is_tra_da_extra else DiscardRecord.KIND_MANDATORY,
	}
	if tra_da_extra_discard_pending:
		result["extra_discard_pending"] = true
	elif discard_count >= DISCARDS_PER_PHASE:
		state = STATE_FINAL_COMMIT_WINDOW
		result["final_commit_window"] = true
	else:
		result["turn_resolution"] = _deduct_turn_deadwood()
		result["drawn"] = _begin_active_turn()
	state_changed.emit(result)
	return result


func end_turn_without_tra_da_extra() -> Dictionary:
	if current_drink_id != DrinkCatalog.TRA_DA or state != STATE_ACTIVE or not tra_da_extra_discard_pending:
		return _failure("Tra Da has no optional extra discard to skip.")
	tra_da_extra_discard_pending = false
	var result := {
		"ok": true,
		"action": "tra_da_extra_skipped",
		"drawn": [] as Array[CardData],
	}
	if discard_count >= DISCARDS_PER_PHASE:
		state = STATE_FINAL_COMMIT_WINDOW
		result["final_commit_window"] = true
	else:
		result["turn_resolution"] = _deduct_turn_deadwood()
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
	if keep_hand and not has_phase_transition_choice():
		return _failure("KEEP requires Sâm dứa or Bạc xỉu; normal Phase transitions DUMP.")
	var dumped: Array[CardData] = []
	var preserved: Array[CardData] = []
	if not keep_hand:
		if has_phase_transition_choice():
			for card in sam_dua_preserved_cards:
				if hand.has(card) and preserved.size() < preservation_limit():
					preserved.append(card)
		for card in hand:
			if not preserved.has(card):
				dumped.append(card)
		hand.clear()
		hand.append_array(preserved)
		deck.discard_many(dumped)
		for card in dumped:
			discard_history.append(DiscardRecord.new(card, current_phase, discard_history.size() + 1, DiscardRecord.KIND_DUMP))
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


func can_create_meld(selected_cards: Array[CardData], use_drink: bool = false) -> bool:
	return _card_actions_available() and _validate_commit_selection(selected_cards).is_empty() and meld_creation_rule(selected_cards, use_drink).get("type", MeldRules.TYPE_INVALID) != MeldRules.TYPE_INVALID


func meld_creation_rule(cards: Array[CardData], use_drink: bool = false) -> Dictionary:
	if use_drink and not current_drink_has_charge():
		return {"type": MeldRules.TYPE_INVALID}
	if use_drink and current_drink_has_charge():
		if current_drink_id in [DrinkCatalog.STING, DrinkCatalog.BO_HUC] and cards.size() == 2 and cards[0].rank == cards[1].rank:
			return {"type": MeldRules.TYPE_SET, "pair": true}
		if current_drink_id == DrinkCatalog.C2_ICED_TEA and MeldRules.is_compatible_run(cards, "any"):
			return {"type": MeldRules.TYPE_RUN, "compatibility": "any", "c2": true}
		return {"type": MeldRules.TYPE_INVALID}
	var normal := MeldRules.classify(cards)
	if normal != MeldRules.TYPE_INVALID:
		return {"type": normal}
	var compatibility := "red" if current_drink_id == DrinkCatalog.MIA_TAC else "black" if current_drink_id == DrinkCatalog.MIA_SAU_RIENG else "same"
	if compatibility != "same" and MeldRules.is_compatible_run(cards, compatibility):
		return {"type": MeldRules.TYPE_RUN, "compatibility": compatibility}
	return {"type": MeldRules.TYPE_INVALID}


func drink_creation_target_ids(selected: Array[CardData]) -> Dictionary:
	var ids := {}
	if not current_drink_has_charge():
		return ids
	# Test completion for each candidate, including gaps between selected run ends.
	# This stays bounded by thirteen ranks even after whole-Meld recovery grows a hand.
	for candidate in hand:
		var required: Array[CardData] = selected.duplicate()
		if not required.has(candidate):
			required.append(candidate)
		if current_drink_id in [DrinkCatalog.STING, DrinkCatalog.BO_HUC]:
			if required.size() > 2:
				continue
			for partner in hand:
				var pair: Array[CardData] = required.duplicate()
				if not pair.has(partner):
					pair.append(partner)
				if can_create_meld(pair, true):
					ids[candidate.unique_id] = true
					break
		elif current_drink_id == DrinkCatalog.C2_ICED_TEA:
			for low in range(1, 12):
				for high in range(low + 2, 14):
					var run: Array[CardData] = required.duplicate()
					var fits := true
					for card in required:
						if not hand.has(card) or card.rank_index < low or card.rank_index > high:
							fits = false
					if not fits:
						continue
					for rank_value in range(low, high + 1):
						if run.any(func(card: CardData) -> bool: return card.rank_index == rank_value):
							continue
						for card in hand:
							if card.rank_index == rank_value:
								run.append(card)
								break
					if run.size() == high - low + 1 and can_create_meld(run, true):
						ids[candidate.unique_id] = true
						break
				if ids.has(candidate.unique_id):
					break
	return ids


func can_extend_meld(meld_id: int, selected_cards: Array[CardData]) -> bool:
	if not _card_actions_available() or not _validate_commit_selection(selected_cards).is_empty():
		return false
	var meld := get_meld(meld_id)
	if meld == null:
		return false
	if meld.can_extend(selected_cards):
		return true
	if meld.meld_type != MeldRules.TYPE_RUN or current_drink_id not in [DrinkCatalog.MIA_TAC, DrinkCatalog.MIA_SAU_RIENG]:
		return false
	var combined: Array[CardData] = meld.cards.duplicate()
	combined.append_array(selected_cards)
	return MeldRules.is_compatible_run(combined, "red" if current_drink_id == DrinkCatalog.MIA_TAC else "black")


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
	for combination in _hand_card_combinations(selected_cards):
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


func probability_draw_pool() -> Array[CardData]:
	var cards: Array[CardData] = []
	cards.append_array(deck.draw_pile)
	cards.append_array(deck.discard_pile)
	cards.append_array(recyclable_spent_cards)
	for meld in melds:
		cards.append_array(meld.cards)
	return cards


func probability_draw_horizon() -> int:
	var projected_hand_size := hand.size()
	if state == STATE_ACTIVE:
		projected_hand_size = maxi(projected_hand_size - 1, 0)
	var refill_gap := maxi(ACTIVE_HAND_TARGET - projected_hand_size, 0)
	var later_refills_this_phase := maxi(DISCARDS_PER_PHASE - discard_count - 2, 0)
	var next_phase_refills := DISCARDS_PER_PHASE - 1 if current_phase == 1 else 0
	return mini(refill_gap + later_refills_this_phase + next_phase_refills, probability_draw_pool().size())


func _hand_card_combinations(required: Array[CardData] = []) -> Array:
	var combinations: Array = []
	# Whole-meld recovery can exceed ten cards. Never allocate 2^hand_size
	# subsets for those hands. Minimal witnesses cover target cues; include
	# the selection and full rank groups for larger commitments.
	if hand.size() > 12:
		var by_rank := {}
		for a in range(hand.size()):
			combinations.append([hand[a]] as Array[CardData])
			var expanded: Array[CardData] = required.duplicate()
			if not expanded.has(hand[a]): expanded.append(hand[a])
			combinations.append(expanded)
			if not by_rank.has(hand[a].rank): by_rank[hand[a].rank] = [] as Array[CardData]
			by_rank[hand[a].rank].append(hand[a])
			for b in range(a + 1, hand.size()):
				combinations.append([hand[a], hand[b]] as Array[CardData])
				for c in range(b + 1, hand.size()):
					combinations.append([hand[a], hand[b], hand[c]] as Array[CardData])
		for group in by_rank.values(): combinations.append(group)
		if not required.is_empty(): combinations.append(required.duplicate())
		return combinations
	for mask in range(1, 1 << hand.size()):
		var cards: Array[CardData] = []
		for index in range(hand.size()):
			if mask & (1 << index):
				cards.append(hand[index])
		combinations.append(cards)
	return combinations


func recommend_action() -> Dictionary:
	var best := {"action": HandAdvisor.ACTION_NONE, "cards": [] as Array[CardData], "estimated_points": -1}
	var candidates := _hand_card_combinations()
	for cards: Array[CardData] in candidates:
		if can_create_meld(cards):
			var kind: String = meld_creation_rule(cards)["type"]
			var points := scoring.preview_new_meld(cards, kind, current_phase, phase_new_meld_count, state == STATE_FINAL_COMMIT_WINDOW).final_points
			if points > int(best["estimated_points"]):
				best = {"action": HandAdvisor.ACTION_NEW_MELD, "cards": cards, "meld_type": kind, "meld_id": -1, "estimated_points": points}
	if best["action"] != HandAdvisor.ACTION_NONE: return best
	for meld in melds:
		for cards: Array[CardData] in candidates:
			if can_extend_meld(meld.meld_id, cards):
				var points := HandAdvisor.estimate_extension_points(meld, cards, scoring, current_phase, state == STATE_FINAL_COMMIT_WINDOW)
				if points > int(best["estimated_points"]):
					best = {"action": HandAdvisor.ACTION_EXTENSION, "cards": cards, "meld_type": meld.meld_type, "meld_id": meld.meld_id, "estimated_points": points}
	return best


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


func gross_payout_multiplier() -> int:
	return 1


func current_deal_earnings_points() -> int:
	var total := phase_metrics.raw_gross - phase_metrics.deadwood_total
	for settlement in settlements:
		if settlement.phase < current_phase:
			total += settlement.net
	return total


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
			for record in discard_history_for_phase(current_phase):
				if _discard_pile_index(record.card) >= 0:
					targets.append(record)
		DrinkCatalog.DEN_DA:
			targets.append_array(live_discard_records())
	return targets


func live_discard_records() -> Array[DiscardRecord]:
	var records: Array[DiscardRecord] = []
	var seen := {}
	for record in discard_history:
		if not seen.has(record.card.unique_id) and (_discard_pile_index(record.card) >= 0 or recyclable_spent_cards.has(record.card)):
			seen[record.card.unique_id] = true
			records.append(record)
	return records


func _on_draw_requested_while_empty(requested_count: int, drawn_count: int) -> void:
	_resolve_exhaustion(requested_count, drawn_count)


func _resolve_exhaustion(requested_count: int, drawn_count: int) -> Dictionary:
	var event_index := exhaustion_count + 1
	var meld_snapshot: Array[MeldState] = []
	meld_snapshot.append_array(melds)
	var meld_trigger_contexts: Array[Dictionary] = []
	var exhaustion_scoring_contexts: Array[ScoringContext] = []
	var exhaustion_scoring_passes: Array[ScoringContext] = []
	for meld in meld_snapshot:
		var meld_context := meld.resolve_exhaustion(event_index)
		var scoring_context := scoring.score_meld_trigger(meld.cards, meld.meld_type, current_phase)
		_apply_scoring_passes(scoring_context)
		meld_context["scoring_context"] = scoring_context
		meld_context["scoring_passes"] = scoring_context.scoring_passes
		meld_context["final_points"] = scoring_context.final_points
		exhaustion_scoring_contexts.append(scoring_context)
		for scoring_pass: ScoringContext in scoring_context.scoring_passes:
			exhaustion_scoring_passes.append(scoring_pass)
		meld_trigger_contexts.append(meld_context)
		meld_exhaustion_triggered.emit(meld, meld_context)
	var locked_ids := {}
	for record in discard_history:
		if record.kind == DiscardRecord.KIND_MANDATORY:
			locked_ids[record.card.unique_id] = true
	var locked_discards: Array[CardData] = []
	var recycled_cards: Array[CardData] = []
	for card in deck.discard_pile:
		if locked_ids.has(card.unique_id):
			locked_discards.append(card)
		else:
			recycled_cards.append(card)
	recycled_cards.append_array(recyclable_spent_cards)
	for meld in melds:
		recycled_cards.append_array(meld.cards)
	var recycled_card_ids: Array[String] = []
	for card in recycled_cards:
		recycled_card_ids.append(card.unique_id)
	deck.discard_pile.assign(locked_discards)
	recyclable_spent_cards.clear()
	discard_history = discard_history.filter(func(record: DiscardRecord) -> bool: return record.kind == DiscardRecord.KIND_MANDATORY)
	melds.clear()
	deck.replace_draw_pile(recycled_cards)
	exhaustion_count = event_index
	var context := exhaustion_status()
	context["action"] = "exhaustion"
	context["requested_count"] = requested_count
	context["drawn_before_exhaustion"] = drawn_count
	context["remaining_draw_count"] = requested_count - drawn_count
	context["recycled_count"] = recycled_cards.size()
	context["recycled_card_ids"] = recycled_card_ids
	var shuffled_card_ids: Array[String] = []
	for card in deck.draw_pile:
		shuffled_card_ids.append(card.unique_id)
	context["shuffled_card_ids"] = shuffled_card_ids
	context["triggered_meld_ids"] = meld_trigger_contexts.map(func(value: Dictionary) -> int: return int(value["meld_id"]))
	context["meld_triggers"] = meld_trigger_contexts
	context["scoring_contexts"] = exhaustion_scoring_contexts
	context["scoring_passes"] = exhaustion_scoring_passes
	exhaustion_triggered.emit(context)
	state_changed.emit({"ok": true, "action": "exhaustion", "exhaustion": context})
	print("[DealState] exhaustion index=%d requested=%d drawn=%d remaining=%d recycled=%d melds=%d" % [
		event_index,
		requested_count,
		drawn_count,
		requested_count - drawn_count,
		recycled_cards.size(),
		meld_trigger_contexts.size(),
	])
	return {"ok": true, "action": "exhaustion", "exhaustion": context}


func _begin_active_turn() -> Array[CardData]:
	nhan_tran_used_this_phase = false # Compatibility field; cadence is now TURN.
	den_da_used_this_turn = false
	pair_used_this_turn = false
	tra_da_used_this_turn = false
	tra_da_extra_discard_pending = false
	var all_drawn: Array[CardData] = []
	all_drawn.append_array(deck.refill(hand, ACTIVE_HAND_TARGET))
	while hand.size() == ACTIVE_HAND_TARGET and not _has_near_meld(hand):
		var payout := 0
		for card in hand:
			payout += card.score_value()
		payout *= 10
		phase_metrics.u_khan_count += 1
		var gross_multiplier := gross_payout_multiplier()
		_record_phase_points(payout, "u_khan")
		var replaced: Array[CardData] = []
		replaced.append_array(hand)
		u_triggered.emit({
			"phase": current_phase,
			"u_khan": true,
			"payout": payout * gross_multiplier,
			"base_payout": payout,
			"gross_multiplier": gross_multiplier,
			"hand": replaced,
		})
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
		"gross_multiplier": 1,
		"hand": hand,
	}
	phase_about_to_settle.emit(settle_context)
	var raw_gross: int = settle_context.get("raw_gross", phase_metrics.raw_gross)
	var gross_after_u: int = raw_gross
	var u_bonus_paid_early := phase_metrics.u_bonus_paid

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
	var turn_deadwood: int = maxi(int(deadwood_context.get("deadwood", 0)), 0)
	if turn_deadwood > 0:
		wallet.apply_points(-turn_deadwood, "deadwood")
	phase_metrics.deadwood_total += turn_deadwood
	var deadwood_total := phase_metrics.deadwood_total
	var settlement := PhaseSettlement.new()
	settlement.phase = current_phase
	settlement.raw_gross = raw_gross
	settlement.gross_after_u = gross_after_u
	settlement.deadwood_value_sum = maxi(int(deadwood_context.get("value_sum", deadwood_value_sum)), 0)
	settlement.deadwood_multiplier = maxi(int(deadwood_context.get("multiplier", deadwood_multiplier)), 0)
	settlement.deadwood = deadwood_total
	settlement.turn_deadwood = turn_deadwood
	settlement.net = gross_after_u - deadwood_total
	settlement.new_phom_count = phase_metrics.new_phom_count
	settlement.extension_count = phase_metrics.extension_count
	settlement.mom = is_mom
	settlement.u = phase_metrics.u
	settlement.u_bonus_paid_early = u_bonus_paid_early
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
	if state != STATE_FINAL_COMMIT_WINDOW and selected_cards.size() > hand.size() - 1:
		return "Keep at least one loose card for the mandatory discard."
	return ""


func _card_actions_available() -> bool:
	return state == STATE_ACTIVE or state == STATE_FINAL_COMMIT_WINDOW


func _record_phase_points(points: int, reason: String) -> void:
	phase_metrics.raw_gross += points
	if points != 0:
		wallet.apply_points(points * gross_payout_multiplier(), reason)
	phase_earnings_points = phase_metrics.raw_gross * gross_payout_multiplier() - phase_metrics.deadwood_total


func _deduct_turn_deadwood() -> Dictionary:
	var value_sum := deadwood_points()
	var context := {
		"phase": current_phase,
		"turn": discard_count,
		"cards": hand.duplicate(),
		"value_sum": value_sum,
		"multiplier": 1,
		"deadwood": value_sum,
		"mom": false,
	}
	deadwood_calculated.emit(context)
	var turn_deadwood := maxi(int(context.get("deadwood", value_sum)), 0)
	var wallet_before_vnd := wallet.balance_vnd
	if turn_deadwood > 0:
		wallet.apply_points(-turn_deadwood, "deadwood")
	phase_metrics.deadwood_total += turn_deadwood
	phase_earnings_points = phase_metrics.raw_gross * gross_payout_multiplier() - phase_metrics.deadwood_total
	context["deadwood"] = turn_deadwood
	context["wallet_before_vnd"] = wallet_before_vnd
	context["wallet_after_vnd"] = wallet.balance_vnd
	context["deadwood_total"] = phase_metrics.deadwood_total
	return context


func _apply_scoring_passes(context: ScoringContext) -> void:
	for scoring_pass: ScoringContext in context.scoring_passes:
		action_counts["card_triggers"] = int(action_counts.get("card_triggers", 0)) + scoring_pass.presentation_hits.size()
		if scoring_pass.trigger_index > 0:
			action_counts["retriggers"] = int(action_counts.get("retriggers", 0)) + 1
		var reason := scoring_pass.action_type if scoring_pass.trigger_index == 0 else String(scoring_pass.trigger_origin)
		_record_phase_points(scoring_pass.final_points, reason)


func _apply_relic_bonuses(context: ScoringContext, meld_id: int) -> void:
	context.relic_bonuses = relics.resolve(context, meld_id)
	for bonus in context.relic_bonuses:
		_record_phase_points(int(bonus.points), "relic:" + String(bonus.id))


func _reset_exhaustion_state() -> void:
	recyclable_spent_cards.clear()
	exhaustion_count = 0
	_expected_deal_card_ids.clear()


func _restore_card_array(target: Array[CardData], values: Variant) -> void:
	target.clear()
	if not (values is Array):
		return
	for value in values:
		if value is CardData:
			target.append(value)


func _restore_meld_array(values: Variant) -> void:
	melds.clear()
	if not (values is Array):
		return
	for value in values:
		if value is MeldState:
			melds.append(value)


func _restore_discard_array(values: Variant) -> void:
	discard_history.clear()
	if not (values is Array):
		return
	for value in values:
		if value is DiscardRecord:
			discard_history.append(value)


func _restore_settlement_array(values: Variant) -> void:
	settlements.clear()
	if not (values is Array):
		return
	for value in values:
		if value is PhaseSettlement:
			settlements.append(value)


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
	relics.phase_started()
	phase_metrics.reset()
	phase_earnings_points = 0
	phase_new_meld_count = 0
	nhan_tran_used_this_phase = false
	_turn_started_with_ten = false
	_turn_committed_card_count = 0


func _reset_drink_usage() -> void:
	den_da_used_this_turn = false
	nau_da_used_phases.clear()
	pair_used_this_turn = false
	pair_used_phases.clear()
	c2_used = false
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


func _count_action(result: Dictionary) -> void:
	if not result.get("ok", false):
		return
	var action := String(result.get("action", ""))
	if action in ["start_deal", "start_tutorial_deal"]:
		action_counts["cards_drawn"] = hand.size()
		return
	action_counts["cards_drawn"] = int(action_counts.get("cards_drawn", 0)) + result.get("drawn", []).size()
	action_counts[action] = int(action_counts.get(action, 0)) + 1
	var event := {"action": action, "phase": current_phase, "turn": discard_count, "wallet_vnd": wallet.balance_vnd}
	var context := result.get("context") as ScoringContext
	if context != null:
		event["points"] = context.final_points
		event["hits"] = context.presentation_hits.duplicate(true)
		event["relics"] = context.relic_bonuses.duplicate(true)
		event["passes"] = []
		for scoring_pass in context.scoring_passes:
			event.passes.append({"origin": scoring_pass.trigger_origin, "points": scoring_pass.final_points, "hits": scoring_pass.presentation_hits.duplicate(true)})
		for bonus in context.relic_bonuses:
			action_counts["relic_triggers"] = int(action_counts.get("relic_triggers", 0)) + 1

	if action == "exhaustion":
		event["points"] = 0
		event["passes"] = []
		for exhausted_context: ScoringContext in result.get("exhaustion", {}).get("scoring_contexts", []):
			event.points += exhausted_context.final_points
			for scoring_pass: ScoringContext in exhausted_context.scoring_passes:
				event.passes.append({"origin": scoring_pass.trigger_origin, "points": scoring_pass.final_points, "hits": scoring_pass.presentation_hits.duplicate(true)})
	action_history.append(event)


func accounting_report() -> Dictionary:
	var report := wallet.report(deal_journal_cursor)
	report["counts"] = action_counts.duplicate(true)
	report.counts["exhaustions"] = exhaustion_count
	var phases: Array[Dictionary] = []
	for settlement in settlements:
		var phase := settlement.to_dictionary()
		phase["net_vnd"] = VndWallet.points_to_vnd(settlement.net, vnd_per_point)
		phases.append(phase)
		for key in ["u", "u_khan_count", "mom"]:
			report.counts[key] = int(report.counts.get(key, 0)) + int(phase.get(key, 0))
	report["phases"] = phases
	report["actions"] = action_history.duplicate(true)
	return report
