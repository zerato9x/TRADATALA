class_name VndWallet
extends RefCounted

signal balance_changed(previous_vnd: int, current_vnd: int, delta_vnd: int, reason: String)

const VND_PER_POINT := 1000

var journal: Array[Dictionary] = []
var journal_opening_vnd: int = 0
var economy_scaling := false
var day_target_vnd := 250_000

var balance_vnd: int = 0
var vnd_per_point: int = VND_PER_POINT


func reset(amount_vnd: int = 0) -> void:
	journal.clear()
	journal_opening_vnd = amount_vnd
	var previous := balance_vnd
	balance_vnd = amount_vnd
	balance_changed.emit(previous, balance_vnd, balance_vnd - previous, "reset")


func apply_points(points: int, reason: String = "score") -> int:
	return apply_vnd(points_to_vnd(points, vnd_per_point), reason)


func apply_vnd(amount_vnd: int, reason: String = "adjustment") -> int:
	var previous := balance_vnd
	balance_vnd += amount_vnd
	journal.append({"reason": reason, "amount_vnd": amount_vnd, "before_vnd": previous, "after_vnd": balance_vnd})
	balance_changed.emit(previous, balance_vnd, amount_vnd, reason)
	return amount_vnd


static func points_to_vnd(points: int, rate_vnd_per_point: int = VND_PER_POINT) -> int:
	return points * rate_vnd_per_point


static func format_vnd(amount_vnd: int, include_sign: bool = false) -> String:
	var sign_text := ""
	if amount_vnd < 0:
		sign_text = "−"
	elif include_sign and amount_vnd > 0:
		sign_text = "+"
	var digits := str(absi(amount_vnd))
	var grouped := ""
	while digits.length() > 3:
		grouped = "." + digits.right(3) + grouped
		digits = digits.left(digits.length() - 3)
	grouped = digits + grouped
	return "%s%s VNĐ" % [sign_text, grouped]


# Numeric-only HUD amount; the adjacent Label owns the VNĐ unit.
static func format_amount(amount_vnd: int, include_sign: bool = false) -> String:
	return format_vnd(amount_vnd, include_sign).trim_suffix(" VNĐ")


# Every committed mutation is journaled before observers run. Summaries never pay.
func report(cursor: int = 0) -> Dictionary:
	var entries := journal.slice(cursor).duplicate(true)
	var opening := journal_opening_vnd if cursor == 0 else int(journal[cursor - 1].after_vnd)
	var income := 0
	var expense := 0
	var categories: Dictionary = {}
	for entry in entries:
		var amount := int(entry.amount_vnd)
		income += maxi(amount, 0)
		expense += maxi(-amount, 0)
		var reason := String(entry.reason)
		categories[reason] = int(categories.get(reason, 0)) + amount
	return {"opening_vnd": opening, "closing_vnd": balance_vnd, "income_vnd": income,
		"expense_vnd": expense, "net_vnd": income - expense, "categories": categories, "entries": entries}


func scaled_cost(base_vnd: int, percent: int = 2) -> int:
	if not economy_scaling or base_vnd <= 0:
		return base_vnd
	# Round up to a 500 dong denomination; prices never become negative.
	var proportional := int(ceil(maxi(day_target_vnd, 0) * percent / 50000.0)) * 500
	return maxi(base_vnd, proportional)


func player_service_cost(base_vnd: int, percent: int, purchases: int, balance: int = -1) -> int:
	# Quote against the player, never the day's debt. Explicit balance supports Buy All.
	var current := balance_vnd if balance < 0 else balance
	var proportional := int(ceil(maxi(current, 0) * percent / 50000.0)) * 500 if economy_scaling else 0
	return maxi(base_vnd, proportional) * (maxi(purchases, 0) + 1)
