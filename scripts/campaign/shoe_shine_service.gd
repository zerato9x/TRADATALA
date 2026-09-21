class_name ShoeShineService
extends RefCounted

var _rng := RandomNumberGenerator.new()
var last_polished_ids: Array[String] = []
var wallet: VndWallet
var lottery: LotteryService
var _deck: Array[CardData] = []
var _tips_vnd := 0
var polish_count_today := 0
var tip_count_today := 0
var _day_index := -1
var _event_slot := -1
var _favors_given: Dictionary = {}

func _init(p_wallet: VndWallet, p_lottery: LotteryService) -> void:
	_rng.randomize()
	wallet = p_wallet
	lottery = p_lottery

func reset_run() -> void:
	polish_count_today = 0
	tip_count_today = 0
	_tips_vnd = 0
	_day_index = -1
	_event_slot = -1
	_favors_given.clear()
	last_polished_ids.clear()
	_deck.clear()

func begin_day(index: int, deck: Array[CardData]) -> void:
	if _day_index == index:
		return
	_day_index = index
	polish_count_today = 0
	tip_count_today = 0
	last_polished_ids.clear()
	_event_slot = -1
	_deck = deck
	for card in _deck:
		card.shiny = false

func begin_event(slot: int) -> void:
	_event_slot = slot

func end_event() -> void:
	_event_slot = -1

func cards() -> Array[CardData]:
	return _deck.duplicate()

func set_seed_value(value: int) -> void:
	_rng.seed = value

func _eligible_cards() -> Array[CardData]:
	var eligible: Array[CardData] = []
	for card in _deck:
		if not card.shiny:
			eligible.append(card)
	return eligible

func can_polish() -> bool:
	return _event_slot == EventManager.EventSlot.STARTER and wallet.balance_vnd >= polish_cost() and _eligible_cards().size() >= 2

func polish() -> Dictionary:
	if not can_polish():
		return {"ok": false}
	var cost := polish_cost()
	var pool := _eligible_cards()
	last_polished_ids.clear()
	for _i in 2:
		var index := _rng.randi_range(0, pool.size() - 1)
		var card := pool[index]
		pool.remove_at(index)
		card.shiny = true
		last_polished_ids.append(card.unique_id)
	polish_count_today += 1
	wallet.apply_vnd(-cost, "shoe_polish")
	return {"ok": true, "card_ids": last_polished_ids.duplicate()}

func can_tip() -> bool:
	return _event_slot == EventManager.EventSlot.STARTER and wallet.balance_vnd >= tip_cost()

func tip() -> Dictionary:
	if not can_tip():
		return {"ok": false}
	var cost := tip_cost()
	_tips_vnd += cost
	tip_count_today += 1
	wallet.apply_vnd(-cost, "shoe_tip")
	return {"ok": true}

func favor_available(favor_id: String) -> bool:
	return MiscServiceConfig.FAVORS.has(favor_id) and _tips_vnd >= int(MiscServiceConfig.FAVORS[favor_id].tips_required_vnd)

func special_hint() -> Dictionary:
	if _event_slot != EventManager.EventSlot.STARTER or not favor_available("lottery_special") or lottery.day_index != _day_index:
		return {}
	var number := lottery.special_number()
	if number < 0:
		return {}
	_favors_given["lottery_special"] = _day_index
	return {"number": number}


func polish_cost() -> int:
	return wallet.player_service_cost(MiscServiceConfig.POLISH_COST_VND, 2, polish_count_today)

func tip_cost() -> int:
	return wallet.player_service_cost(MiscServiceConfig.TIP_VND, 1, tip_count_today)
