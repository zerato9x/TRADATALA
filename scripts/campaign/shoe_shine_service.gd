class_name ShoeShineService
extends RefCounted
## Starter-only, permanent identity work on at most two committed physical IDs.
signal changed()
signal transformation_committed(receipt: Dictionary)

var wallet: VndWallet
var visit_started := false
var selected_card_ids: Array[String] = []
var rank_rerolls := 0
var suit_rerolls := 0
var next_rank_cost_vnd := 5_000
var next_suit_cost_vnd := 2_500
var price_curve: Dictionary = ShoeShineConfig.SERVICES.duplicate(true)
var last_reroll: Dictionary = {}
var _rng := RandomNumberGenerator.new()
var _deck: Array[CardData] = []
var _day_index := -1
var _event_slot := -1
var _mutating := false
var _campaign_ref: WeakRef

func _init(p_wallet: VndWallet) -> void:
	wallet = p_wallet

func bind_campaign(campaign: CampaignManager) -> void:
	_campaign_ref = weakref(campaign)

func reset_run() -> void:
	visit_started = false
	selected_card_ids = []
	rank_rerolls = 0
	suit_rerolls = 0
	last_reroll = {}
	price_curve = ShoeShineConfig.SERVICES.duplicate(true)
	_day_index = -1
	_event_slot = -1
	_deck = []
	_reset_prices()

func begin_day(index: int, deck: Array[CardData], target_vnd: int = 250_000) -> void:
	bind_deck(deck)
	if _day_index == index: return
	_day_index = index
	_event_slot = -1
	visit_started = false
	selected_card_ids = []
	rank_rerolls = 0
	suit_rerolls = 0
	last_reroll = {}
	price_curve = ShoeShineConfig.SERVICES.duplicate(true)
	_reset_prices(target_vnd)

func begin_event(slot: int) -> void:
	_event_slot = slot
	if slot == EventManager.EventSlot.STARTER and not visit_started and _day_index >= 0:
		visit_started = true
		changed.emit()

func end_event() -> void:
	_event_slot = -1

func bind_deck(deck: Array[CardData]) -> void:
	_deck = deck
	# Never prune committed IDs: a missing card must not free a third slot.

func cards() -> Array[CardData]:
	return _deck.duplicate()

func card_for_id(id: String) -> CardData:
	var found: CardData
	for card in _deck:
		if card.unique_id != id: continue
		if found != null: return null # Ambiguous physical identity is ineligible.
		found = card
	return found

func selected_cards() -> Array[CardData]:
	var selected: Array[CardData] = []
	for id in selected_card_ids:
		var card := card_for_id(id)
		if card != null: selected.append(card)
	return selected

func is_active() -> bool:
	if not visit_started or _day_index < 0 or _event_slot != EventManager.EventSlot.STARTER: return false
	if _campaign_ref == null: return true
	var campaign: CampaignManager = _campaign_ref.get_ref()
	return campaign != null and campaign.current_phase == CampaignManager.CampaignPhase.STARTER_EVENT and campaign.current_day_index == _day_index and not campaign.run_failed and not campaign.campaign_complete

func eligible_cards() -> Array[CardData]:
	var eligible: Array[CardData] = []
	if not is_active() or _mutating or selected_card_ids.size() >= ShoeShineConfig.MAX_SELECTED_CARDS: return eligible
	for card in _deck:
		if not selected_card_ids.has(card.unique_id) and not card.transformation_locked and card_for_id(card.unique_id) == card:
			eligible.append(card)
	return eligible

func choose_card(id: String) -> Dictionary:
	if not is_active() or _mutating: return _failure("SHOE_ERROR_CLOSED")
	if selected_card_ids.has(id): return _failure("SHOE_ERROR_SELECTED")
	if selected_card_ids.size() >= ShoeShineConfig.MAX_SELECTED_CARDS: return _failure("SHOE_ERROR_FULL")
	var card := card_for_id(id)
	if card == null: return _failure("SHOE_ERROR_MISSING")
	if card.transformation_locked: return _failure("SHOE_ERROR_SEALED")
	selected_card_ids.append(id)
	changed.emit()
	return {"ok": true, "card_id": id}

func rank_cost() -> int:
	return next_rank_cost_vnd

func suit_cost() -> int:
	return next_suit_cost_vnd

func reroll_error(id: String, kind: String) -> String:
	if _mutating or not is_active(): return "SHOE_ERROR_CLOSED"
	if kind not in ["rank", "suit"]: return "SHOE_ERROR_MUTATION"
	if not selected_card_ids.has(id): return "SHOE_ERROR_UNSELECTED"
	var card := card_for_id(id)
	if card == null: return "SHOE_ERROR_MISSING"
	if card.transformation_locked: return "SHOE_ERROR_SEALED"
	if card.rank not in DeckManager.RANKS or card.suit not in DeckManager.SUITS: return "SHOE_ERROR_MUTATION"
	if wallet == null or wallet.balance_vnd < (rank_cost() if kind == "rank" else suit_cost()): return "SHOE_ERROR_FUNDS"
	return ""

func can_reroll(id: String, kind: String) -> bool:
	return reroll_error(id, kind).is_empty()

func reroll_rank(id: String) -> Dictionary:
	return _reroll(id, "rank")

func reroll_suit(id: String) -> Dictionary:
	return _reroll(id, "suit")

func _reroll(id: String, kind: String) -> Dictionary:
	var error := reroll_error(id, kind)
	if not error.is_empty(): return _failure(error)
	var card := card_for_id(id)
	var before := card.persuasion_fingerprint()
	var revision_before := card.mutation_revision
	var rng_before := _rng.state
	var cost := rank_cost() if kind == "rank" else suit_cost()
	var receipt := {}
	_mutating = true
	# Card and wallet observers see one completed transaction, including counts/RNG.
	var blocked := card.is_blocking_signals()
	card.set_block_signals(true)
	var paid := wallet.try_spend_and_commit(cost, "shoe_reroll_" + kind, func() -> bool:
		var pool := DeckManager.RANKS.duplicate() if kind == "rank" else DeckManager.SUITS.duplicate()
		pool.erase(card.rank if kind == "rank" else card.suit)
		var outcome: String = pool[_rng.randi_range(0, pool.size() - 1)]
		if kind == "rank":
			card.apply_rank(outcome, DeckManager.RANKS.find(outcome) + 1)
			if card.rank != outcome or card.rank_index != DeckManager.RANKS.find(outcome) + 1 or card.base_value != card.rank_index: return false
		else:
			card.apply_suit(outcome)
			if card.suit != outcome: return false
		if kind == "rank":
			rank_rerolls += 1
			next_rank_cost_vnd = ShoeShineConfig.next_cost(cost, kind, price_curve)
		else:
			suit_rerolls += 1
			next_suit_cost_vnd = ShoeShineConfig.next_cost(cost, kind, price_curve)
		receipt.merge({"ok": true, "card_id": id, "kind": kind, "cost_vnd": cost,
			"before": before, "after": card.persuasion_fingerprint(),
			"rank_rerolls": rank_rerolls, "suit_rerolls": suit_rerolls})
		last_reroll = receipt.duplicate(true)
		return true)
	if not paid:
		# Defensive rollback for a rejected CardData mutation; no debit is journaled.
		_rng.state = rng_before
		card.rank = before.rank
		card.rank_index = before.rank_index
		card.base_value = before.base_value
		card.suit = before.suit
		card.mutation_revision = revision_before
	card.set_block_signals(blocked)
	if paid:
		if not blocked: card.permanent_changed.emit(id, card.mutation_revision, kind)
		transformation_committed.emit(receipt.duplicate(true))
		changed.emit()
	_mutating = false
	return receipt if paid else _failure("SHOE_ERROR_MUTATION")

func _reset_prices(target_vnd: int = 250_000) -> void:
	next_rank_cost_vnd = ShoeShineConfig.initial_cost("rank", target_vnd, price_curve)
	next_suit_cost_vnd = ShoeShineConfig.initial_cost("suit", target_vnd, price_curve)

func _failure(key: String) -> Dictionary:
	return {"ok": false, "error": key}

func set_seed_value(value: int) -> void:
	_rng.seed = value

# Extends the V3 envelope; all new fields are optional for older saves.
const RUN_SAVE_FIELDS_V3 := ["visit_started", "selected_card_ids", "rank_rerolls", "suit_rerolls",
	"next_rank_cost_vnd", "next_suit_cost_vnd", "price_curve", "last_reroll", "_day_index", "_event_slot"]
const RUN_SNAPSHOT_FIELDS := preload("res://scripts/campaign/run_snapshot_fields.gd")

func run_snapshot() -> Dictionary:
	return RUN_SNAPSHOT_FIELDS.fields(self, RUN_SAVE_FIELDS_V3)

func restore_run_snapshot(data: Dictionary) -> void:
	reset_run()
	RUN_SNAPSHOT_FIELDS.apply_fields(self, data, RUN_SAVE_FIELDS_V3)
	# Legacy polish/tips are not identity rerolls. Keep card state, start at zero.
	if not data.has("visit_started"):
		visit_started = _event_slot == EventManager.EventSlot.STARTER and _day_index >= 0
	if not data.has("next_rank_cost_vnd"):
		next_rank_cost_vnd = ShoeShineConfig.initial_cost("rank", wallet.day_target_vnd, price_curve)
		for _i in rank_rerolls: next_rank_cost_vnd = ShoeShineConfig.next_cost(next_rank_cost_vnd, "rank", price_curve)
	if not data.has("next_suit_cost_vnd"):
		next_suit_cost_vnd = ShoeShineConfig.initial_cost("suit", wallet.day_target_vnd, price_curve)
		for _i in suit_rerolls: next_suit_cost_vnd = ShoeShineConfig.next_cost(next_suit_cost_vnd, "suit", price_curve)

func run_rng_state() -> int:
	return _rng.state

func restore_run_rng(state_value: int) -> void:
	_rng.state = state_value