class_name DrinkManager
extends RefCounted

signal drink_selected(drink_id: String, period: String, price_vnd: int)
signal drink_cleared()

# Mechanics test override; zero is provisional, not a balanced final price.
const TEST_ALL_DRINKS_AVAILABLE := false
const TEST_PRICE_VND := 0
var test_all_drinks_available: bool = TEST_ALL_DRINKS_AVAILABLE and not DemoBuild.enabled()

const PRICES_VND := {
	DrinkCatalog.TRA_DA: 0,
	DrinkCatalog.NUOC_VOI: 10_000,
	DrinkCatalog.NHAN_TRAN: 15_000,
	DrinkCatalog.SAM_DUA: 20_000,
}

const PRICE_PERCENT := {
	DrinkCatalog.TRA_DA: 0, DrinkCatalog.NUOC_VOI: 2, DrinkCatalog.NHAN_TRAN: 3,
	DrinkCatalog.SAM_DUA: 4, DrinkCatalog.DEN_DA: 5, DrinkCatalog.NAU_DA: 6,
	DrinkCatalog.BAC_XIU: 5, DrinkCatalog.STING: 5, DrinkCatalog.C2_ICED_TEA: 5,
	DrinkCatalog.BO_HUC: 8, DrinkCatalog.MIA_TAC: 8, DrinkCatalog.MIA_SAU_RIENG: 8,
}
var day_index := -1
var progress: DrinkProgress
var day_target_vnd: int = 250_000
var empty_glasses: Array[String] = []
var current_event_slot: int = -1
var event_ordered := false

var wallet: VndWallet
var morning_drink_id: String = DrinkCatalog.NONE
var afternoon_drink_id: String = DrinkCatalog.NONE
var active_drink_id: String = DrinkCatalog.NONE


func _init(p_wallet: VndWallet = null) -> void:
	wallet = p_wallet if p_wallet != null else VndWallet.new()


func available_drink_ids() -> Array[String]:
	if DemoBuild.enabled() or test_all_drinks_available or day_index < 0:
		return DrinkCatalog.all_ids()
	var tier := 0 if day_index == 0 and current_event_slot == EventManager.EventSlot.STARTER else 1
	if day_index >= 2 or (day_index == 1 and current_event_slot == EventManager.EventSlot.NOON):
		tier = 2
	var available: Array[String] = []
	for id: String in DrinkCatalog.all_ids():
		if int(DrinkCatalog.DEFINITIONS[id].tier) <= tier:
			available.append(id)
	if day_index >= 2 and current_event_slot == EventManager.EventSlot.NOON:
		if morning_drink_id == DrinkCatalog.STING:
			available.append(DrinkCatalog.BO_HUC)
		elif morning_drink_id == DrinkCatalog.C2_ICED_TEA:
			available.append_array([DrinkCatalog.MIA_TAC, DrinkCatalog.MIA_SAU_RIENG])
	return available


func price_for(drink_id: String) -> int:
	if DemoBuild.enabled():
		var percent := int(DrinkProgress.GOALS.get(drink_id, ["", 0, 0])[2])
		return wallet.scaled_cost(int(round(float(day_target_vnd) * percent / 50_000.0)) * 500)
	if test_all_drinks_available:
		return TEST_PRICE_VND
	return int(ceil(float(day_target_vnd) * int(PRICE_PERCENT.get(drink_id, 0)) / 50_000.0)) * 500


func is_unlocked(drink_id: String) -> bool:
	if test_all_drinks_available and not DemoBuild.enabled():
		return true
	return progress.is_unlocked(drink_id) if progress != null else DrinkCatalog.is_known(drink_id)


func can_order(drink_id: String) -> bool:
	return not event_ordered and available_drink_ids().has(drink_id) and is_unlocked(drink_id) and can_afford(drink_id)


func can_afford(drink_id: String) -> bool:
	var price := price_for(drink_id)
	return price <= 0 or wallet.balance_vnd >= price


func select_for_event(event_slot: int, drink_id: String) -> Dictionary:
	if DemoBuild.enabled():
		return _select_demo_drink(event_slot, drink_id)
	if day_index >= 0 and event_slot != current_event_slot:
		return {"ok": false, "reason": "wrong_event"}
	if event_slot not in [EventManager.EventSlot.STARTER, EventManager.EventSlot.NOON]:
		return {"ok": false, "message": "This event does not choose a Drink."}
	if not available_drink_ids().has(drink_id) or not is_unlocked(drink_id):
		return {"ok": false, "message": "Drink is not available in the early campaign."}
	var period := "morning" if event_slot == EventManager.EventSlot.STARTER else "afternoon"
	var selected_drink := morning_drink_id if period == "morning" else afternoon_drink_id
	if selected_drink != DrinkCatalog.NONE:
		return {
			"ok": false,
			"reason": "already_selected",
			"message": "A Drink is already selected for this event.",
			"drink_id": selected_drink,
			"period": period,
		}
	var price := price_for(drink_id)
	if not can_afford(drink_id):
		return {"ok": false, "message": "Not enough VNĐ.", "price_vnd": price}
	if period == "morning":
		morning_drink_id = drink_id
	else:
		afternoon_drink_id = drink_id
	active_drink_id = drink_id
	event_ordered = true
	if price > 0:
		wallet.apply_vnd(-price, "drink_purchase")
	drink_selected.emit(drink_id, period, price)
	return {"ok": true, "drink_id": drink_id, "period": period, "price_vnd": price}


func clear_day() -> void:
	if DemoBuild.enabled():
		_retire_drink()
	current_event_slot = -1
	event_ordered = false
	morning_drink_id = DrinkCatalog.NONE
	afternoon_drink_id = DrinkCatalog.NONE
	active_drink_id = DrinkCatalog.NONE
	drink_cleared.emit()


func begin_event(slot: int) -> void:
	current_event_slot = slot
	event_ordered = false
	if DemoBuild.enabled() and slot == EventManager.EventSlot.NOON:
		_retire_drink()


func reset_run() -> void:
	active_drink_id = DrinkCatalog.NONE
	empty_glasses.clear()
	clear_day()


func _retire_drink() -> void:
	if active_drink_id != DrinkCatalog.NONE:
		empty_glasses.append(active_drink_id)
		active_drink_id = DrinkCatalog.NONE
		drink_cleared.emit()


func _select_demo_drink(slot: int, drink_id: String) -> Dictionary:
	if slot != current_event_slot or slot not in [0, 1, 2, 3]:
		return {"ok": false, "reason": "wrong_event"}
	if event_ordered:
		return {"ok": false, "reason": "already_selected"}
	if not can_order(drink_id):
		return {"ok": false, "reason": "locked" if not is_unlocked(drink_id) else "unaffordable"}
	var price := price_for(drink_id)
	if price > 0:
		wallet.apply_vnd(-price, "drink_purchase")
	_retire_drink()
	active_drink_id = drink_id
	event_ordered = true
	if slot in [EventManager.EventSlot.STARTER, EventManager.EventSlot.MORNING]:
		morning_drink_id = drink_id
	else:
		afternoon_drink_id = drink_id
	var period := ["morning", "noon", "afternoon", "evening"][slot] as String
	drink_selected.emit(drink_id, period, price)
	return {"ok": true, "drink_id": drink_id, "period": period, "price_vnd": price}
