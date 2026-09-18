class_name LotteryService
extends RefCounted

signal settled(receipt: Dictionary)

var wallet: VndWallet
var day_index := -1
var event_slot := -1
var _rng := RandomNumberGenerator.new()
var _draw: Dictionary = {}
var _offers: Dictionary = {}
var _tickets: Array[Dictionary] = []
var _settled := false
var last_receipt: Dictionary = {}

func _init(p_wallet: VndWallet) -> void:
	wallet = p_wallet
	_rng.randomize()

func set_seed_value(value: int) -> void:
	_rng.seed = value

func reset_run() -> void:
	day_index = -1
	event_slot = -1
	_draw.clear()
	_offers.clear()
	_tickets.clear()
	last_receipt.clear()
	_settled = false

func begin_day(index: int) -> void:
	if index == day_index:
		return
	day_index = index
	event_slot = -1
	_draw.clear()
	_offers.clear()
	_tickets.clear()
	_settled = false
	var pool := _shuffled_numbers()
	for prize in MiscServiceConfig.PRIZES:
		var numbers: Array[int] = []
		for _i in int(prize.count):
			numbers.append(pool.pop_back())
		_draw[prize.id] = numbers
	for slot in [EventManager.EventSlot.MORNING, EventManager.EventSlot.AFTERNOON]:
		var batch: Array[Dictionary] = []
		var numbers := _shuffled_numbers()
		for i in mini(MiscServiceConfig.TICKETS_PER_APPEARANCE, 100):
			batch.append({"id": "%d:%d:%d" % [index, slot, i], "number": numbers[i],
				"stake_vnd": wallet.scaled_cost(MiscServiceConfig.TICKET_STAKE_VND, 1), "purchased": false})
		_offers[slot] = batch

func begin_event(slot: int) -> void:
	event_slot = slot

func end_event() -> void:
	event_slot = -1

func offered_tickets() -> Array:
	if _settled or not _offers.has(event_slot):
		return []
	return _offers[event_slot].duplicate(true)

func purchased_tickets() -> Array[Dictionary]:
	return _tickets.duplicate(true)

# Information authority for NPC favors; panels never receive the unrevealed draw.
func special_number() -> int:
	return int(_draw.special[0]) if _draw.has("special") else -1

func revealed_results() -> Dictionary:
	return _draw.duplicate(true) if _settled else {}

func purchase(ticket_id: String) -> Dictionary:
	if _settled or not _offers.has(event_slot):
		return {"ok": false}
	for ticket: Dictionary in _offers[event_slot]:
		if ticket.id != ticket_id:
			continue
		var stake := int(ticket.stake_vnd)
		if ticket.purchased or stake <= 0 or wallet.balance_vnd < stake:
			return {"ok": false}
		ticket.purchased = true
		_tickets.append(ticket.duplicate(true))
		wallet.apply_vnd(-stake, "lottery_ticket")
		return {"ok": true, "ticket": ticket.duplicate(true)}
	return {"ok": false}

func settle_day() -> Dictionary:
	if _settled or day_index < 0:
		return {}
	# Commit before wallet signals: reentrant listeners cannot pay twice.
	_settled = true
	event_slot = -1
	var results: Array[Dictionary] = []
	var total := 0
	for ticket in _tickets:
		var result := ticket.duplicate(true)
		result["prize"] = ""
		result["payout_vnd"] = 0
		for prize in MiscServiceConfig.PRIZES:
			if _draw[prize.id].has(ticket.number):
				result.prize = prize.id
				result.payout_vnd = payout_vnd(int(ticket.stake_vnd), prize)
				break
		total += int(result.payout_vnd)
		results.append(result)
	last_receipt = {"day_index": day_index, "draw": _draw.duplicate(true), "tickets": results, "total_vnd": total}
	if total > 0:
		wallet.apply_vnd(total, "lottery_settlement")
	if not results.is_empty():
		settled.emit(last_receipt.duplicate(true))
	return last_receipt.duplicate(true)

static func payout_vnd(stake: int, prize: Dictionary) -> int:
	# Integer VND; an indivisible half dong rounds down. Default stakes divide exactly.
	@warning_ignore("integer_division")
	return stake * int(prize.numerator) / int(prize.denominator)

func _shuffled_numbers() -> Array[int]:
	var numbers: Array[int] = []
	for number in 100:
		numbers.append(number)
	for index in range(99, 0, -1):
		var swap := _rng.randi_range(0, index)
		var old := numbers[index]
		numbers[index] = numbers[swap]
		numbers[swap] = old
	return numbers
