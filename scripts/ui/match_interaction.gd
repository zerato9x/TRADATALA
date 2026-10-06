class_name MatchInteraction
extends RefCounted

signal selection_changed()
## Shared selection and target policy. Views submit physical intent through MatchUI.
var _deal_ref: WeakRef
var selected_ids: Dictionary = {}
var selected_meld_id := -1
var drink_ids: Dictionary = {}
var drink_targeting := false
var drink_meld_id := -1
var drink_meld_card_id := ""
var drink_discard_key := ""
var locked := false
var drag_payload: Variant

func configure(deal: DealState) -> void:
	_deal_ref = weakref(deal)

func _deal() -> DealState:
	return _deal_ref.get_ref() as DealState

func select(cards: Array[CardData], meld_id: int = -1) -> bool:
	var ids := {}
	for card in cards:
		if card == null or not _deal().hand.has(card) or ids.has(card.unique_id): return false
		ids[card.unique_id] = true
	selected_ids = ids
	selected_meld_id = meld_id
	selection_changed.emit()
	return true

func toggle(card: CardData) -> bool:
	if locked or card == null or not _deal().hand.has(card): return false
	if selected_ids.has(card.unique_id): selected_ids.erase(card.unique_id)
	else: selected_ids[card.unique_id] = true
	selection_changed.emit()
	return true

func reset_drink_targets() -> void:
	drink_targeting = false
	drink_ids.clear()
	drink_meld_id = -1
	drink_meld_card_id = ""
	drink_discard_key = ""

func execute_drink(kind: String, cards: Array[CardData] = [], meld_id: int = -1, record: DiscardRecord = null) -> Dictionary:
	var deal := _deal()
	match kind:
		"swap":
			if cards.size() != 1: return {"ok": false}
			return deal.use_den_da(cards[0], record) if deal.current_drink_id == DrinkCatalog.DEN_DA else deal.use_nhan_tran(cards[0], record)
		"recover": return deal.use_nau_da(meld_id)
		"recover_card": return deal.use_nuoc_voi(meld_id, cards[0] if cards.size() == 1 else null)
		"preserve": return deal.select_sam_dua_preserves(cards)
		"create": return deal.create_meld(cards, true)
	return {"ok": false}

const DROP_TARGET_NONE := &"none"
const DROP_TARGET_HAND := &"hand"
const DROP_TARGET_TABLE := &"table"
const DROP_TARGET_MELD := &"meld"
const DROP_TARGET_DISCARD := &"discard"
const DRAG_ACTION_NONE := &"none"
const DRAG_ACTION_REORDER := &"reorder"
const DRAG_ACTION_CREATE_MELD := &"create_meld"
const DRAG_ACTION_EXTEND_MELD := &"extend_meld"
const DRAG_ACTION_DISCARD := &"discard"
const CARD_DRAG_PAYLOAD_SCRIPT := preload("res://scripts/ui/card_drag_payload.gd")

func selected_cards() -> Array[CardData]:
	var selected: Array[CardData] = []
	for card in _deal().hand:
		if selected_ids.has(card.unique_id):
			selected.append(card)
	return selected


func pending_drink_cards() -> Array[CardData]:
	var cards: Array[CardData] = []
	for card in _deal().hand:
		if drink_ids.has(card.unique_id):
			cards.append(card)
	return cards


func drink_drop_is_valid(cards: Array[CardData], target: Dictionary) -> bool:
	if locked or cards.is_empty() or not _deal().current_drink_has_charge():
		return false
	var kind: StringName = target.get("kind", &"")
	if kind == &"drink_discard" and cards.size() == 1:
		var record := target.get("record") as DiscardRecord
		return _deal().can_use_nhan_tran(cards[0], record) or _deal().can_use_den_da(cards[0], record)
	if kind != &"drink" and not (drink_targeting and kind == DROP_TARGET_TABLE):
		return false
	if _deal().current_drink_id in [DrinkCatalog.NHAN_TRAN, DrinkCatalog.DEN_DA]:
		return cards.size() == 1 and _deal().hand.has(cards[0]) and not _deal().drink_mandatory_discard_targets().is_empty()
	if _deal().has_preservation_drink():
		if cards.size() > _deal().preservation_limit():
			return false
		for card in cards:
			if not _deal().hand.has(card): return false
		return true
	return _deal().can_create_meld(cards, true)

func card_drag_action(payload, target: Dictionary) -> StringName:
	if payload == null:
		return DRAG_ACTION_NONE
	var target_kind: StringName = target.get("kind", DROP_TARGET_NONE)
	if payload.source_zone == CARD_DRAG_PAYLOAD_SCRIPT.SOURCE_HAND:
		match target_kind:
			DROP_TARGET_HAND:
				return DRAG_ACTION_REORDER
			DROP_TARGET_TABLE:
				return DRAG_ACTION_CREATE_MELD
			DROP_TARGET_MELD:
				return DRAG_ACTION_EXTEND_MELD
			DROP_TARGET_DISCARD:
				return DRAG_ACTION_DISCARD
	return DRAG_ACTION_NONE


func cards_for_drop_target(payload, target: Dictionary) -> Array[CardData]:
	var cards: Array[CardData] = []
	if payload == null:
		return cards
	var anchor := payload.anchor_card() as CardData
	if drink_drop_is_valid(payload.cards, target):
		cards.append_array(payload.cards)
		return cards
	if drink_targeting and target.get("kind") != DROP_TARGET_HAND:
		return cards
	var action := card_drag_action(payload, target)
	match action:
		DRAG_ACTION_REORDER:
			if anchor != null:
				cards.append(anchor)
		DRAG_ACTION_DISCARD:
			if _deal().state == DealState.STATE_ACTIVE and anchor != null and _deal().hand.has(anchor):
				cards.append(anchor)
		DRAG_ACTION_CREATE_MELD:
			if (_deal().can_create_meld(payload.cards) or (_deal().can_create_meld(payload.cards, true))):
				cards.append_array(payload.cards)
		DRAG_ACTION_EXTEND_MELD:
			var meld_id := int(target.get("meld_id", -1))
			if _deal().can_extend_meld(meld_id, payload.cards):
				cards.append_array(payload.cards)
			elif anchor != null and _deal().can_extend_meld(meld_id, [anchor] as Array[CardData]):
				cards.append(anchor)
	return cards



func begin_drink(cards: Array[CardData]) -> bool:
	var ids := {}
	for card in cards:
		if card == null or not _deal().hand.has(card) or ids.has(card.unique_id): return false
		ids[card.unique_id] = true
	drink_targeting = true
	if not cards.is_empty(): drink_ids = ids
	return true

func drink_hand_eligible_card_ids() -> Dictionary:
	var deal := _deal()
	var eligible := {}
	if not drink_preview_active():
		return eligible
	if deal.current_drink_id in [DrinkCatalog.STING, DrinkCatalog.BO_HUC, DrinkCatalog.C2_ICED_TEA]:
		return deal.drink_creation_target_ids(pending_drink_cards())
	var discard_targets := deal.drink_mandatory_discard_targets()
	for card in deal.hand:
		var card_is_eligible := false
		match deal.current_drink_id:
			DrinkCatalog.NHAN_TRAN, DrinkCatalog.DEN_DA:
				for record in discard_targets:
					if (drink_discard_key.is_empty() or drink_discard_key == record.target_key()) and deal.queries.drink_swap_opportunities(card).any(func(op): return op.record == record):
						card_is_eligible = true
						break
			DrinkCatalog.SAM_DUA, DrinkCatalog.BAC_XIU:
				card_is_eligible = deal.current_drink_has_charge() and (drink_targeting or deal.state == DealState.STATE_FINAL_COMMIT_WINDOW) and not deal.zodiac_boss.is_locked(card)
		if card_is_eligible:
			eligible[card.unique_id] = true
	return eligible

func drink_preview_active() -> bool:
	return _deal().current_drink_has_charge() and not locked

func drink_swap_opportunities() -> Array[Dictionary]:
	if not drink_preview_active(): return []
	var cards := pending_drink_cards() if drink_targeting else selected_cards()
	return _deal().queries.drink_swap_opportunities(cards[0] if cards.size() == 1 else null)

func reconcile_meld_targets() -> void:
	if _deal().melds.is_empty():
		selected_meld_id = -1
		drink_meld_id = -1
		drink_meld_card_id = ""
		return
	if selected_meld_id >= 0 and _deal().get_meld(selected_meld_id) == null: selected_meld_id = -1
	if drink_meld_id >= 0 and _deal().get_meld(drink_meld_id) == null:
		drink_meld_id = -1
		drink_meld_card_id = ""
