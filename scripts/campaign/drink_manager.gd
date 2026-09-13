class_name DrinkManager
extends RefCounted

signal drink_selected(drink_id: String, period: String, price_vnd: int)
signal drink_cleared()

# Mechanics test override; zero is provisional, not a balanced final price.
const TEST_ALL_DRINKS_AVAILABLE := true
const TEST_PRICE_VND := 0
var test_all_drinks_available: bool = TEST_ALL_DRINKS_AVAILABLE

const PRICES_VND := {
	DrinkCatalog.TRA_DA: 0,
	DrinkCatalog.NUOC_VOI: 10_000,
	DrinkCatalog.NHAN_TRAN: 15_000,
	DrinkCatalog.SAM_DUA: 20_000,
}

var wallet: VndWallet
var morning_drink_id: String = DrinkCatalog.NONE
var afternoon_drink_id: String = DrinkCatalog.NONE
var active_drink_id: String = DrinkCatalog.NONE


func _init(p_wallet: VndWallet = null) -> void:
	wallet = p_wallet if p_wallet != null else VndWallet.new()


func available_drink_ids() -> Array[String]:
	if test_all_drinks_available:
		return DrinkCatalog.all_ids()
	return DrinkCatalog.basic_ids()


func price_for(drink_id: String) -> int:
	if test_all_drinks_available:
		return TEST_PRICE_VND
	return int(PRICES_VND.get(drink_id, 0))


func can_afford(drink_id: String) -> bool:
	var price := price_for(drink_id)
	return price <= 0 or wallet.balance_vnd >= price


func select_for_event(event_slot: int, drink_id: String) -> Dictionary:
	if event_slot not in [EventManager.EventSlot.STARTER, EventManager.EventSlot.NOON]:
		return {"ok": false, "message": "This event does not choose a Drink."}
	if not available_drink_ids().has(drink_id):
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
		return {"ok": false, "message": "Not enough VND.", "price_vnd": price}
	if price > 0:
		wallet.apply_vnd(-price, "drink_purchase")
	if period == "morning":
		morning_drink_id = drink_id
	else:
		afternoon_drink_id = drink_id
	active_drink_id = drink_id
	drink_selected.emit(drink_id, period, price)
	return {"ok": true, "drink_id": drink_id, "period": period, "price_vnd": price}


func clear_day() -> void:
	morning_drink_id = DrinkCatalog.NONE
	afternoon_drink_id = DrinkCatalog.NONE
	active_drink_id = DrinkCatalog.NONE
	drink_cleared.emit()
