class_name VndWallet
extends RefCounted

signal balance_changed(previous_vnd: int, current_vnd: int, delta_vnd: int, reason: String)

const VND_PER_POINT := 1000

var balance_vnd: int = 0
var vnd_per_point: int = VND_PER_POINT


func reset(amount_vnd: int = 0) -> void:
	var previous := balance_vnd
	balance_vnd = amount_vnd
	balance_changed.emit(previous, balance_vnd, balance_vnd - previous, "reset")


func apply_points(points: int, reason: String = "score") -> int:
	return apply_vnd(points_to_vnd(points, vnd_per_point), reason)


func apply_vnd(amount_vnd: int, reason: String = "adjustment") -> int:
	var previous := balance_vnd
	balance_vnd += amount_vnd
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
	return "%s₫%s" % [sign_text, grouped]
