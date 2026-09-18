class_name RelicShop
extends RefCounted
## One seeded offer per campaign visit, independent of panel lifetime.
signal changed()
var runtime: RelicRuntime
var wallet: VndWallet
var offers: Array[String] = []
var visit_id := ""
var purchased := false
var rerolls := 0
var _mutating := false
var target_vnd := 250_000
var _rng := RandomNumberGenerator.new()

func _init(p_wallet: VndWallet = null, p_runtime: RelicRuntime = null) -> void:
	wallet = p_wallet
	runtime = p_runtime

func begin_visit(id: String, seed_value: int, goal: int) -> void:
	if id == visit_id:
		return
	visit_id = id
	target_vnd = goal
	purchased = false
	rerolls = 0
	_rng.seed = seed_value
	_roll()

func price() -> int:
	return maxi(500, int(ceil(target_vnd * 0.05 / 500.0)) * 500)

func reroll_price() -> int:
	return maxi(500, int(ceil(target_vnd * 0.02 / 500.0)) * 500) * (rerolls + 1)

func buy(id: String) -> bool:
	if _mutating or runtime == null or wallet == null or purchased or not offers.has(id) or runtime.inventory.has(id) or wallet.balance_vnd < price():
		return false
	# Close the offer before inventory/payment signals can reenter the shop.
	purchased = true
	offers.clear()
	runtime.acquire(id)
	runtime.equip(id)
	wallet.apply_vnd(-price(), "relic_purchase:" + id)
	changed.emit()
	return true

func reroll() -> bool:
	if _mutating or purchased or offers.is_empty() or wallet == null or wallet.balance_vnd < reroll_price():
		return false
	_mutating = true
	var cost := reroll_price()
	rerolls += 1
	_roll(false)
	wallet.apply_vnd(-cost, "relic_reroll")
	_mutating = false
	changed.emit()
	return true

func _roll(notify: bool = true) -> void:
	var pool: Array[String] = []
	for id: String in RelicCatalog.DEFINITIONS:
		if runtime == null or not runtime.inventory.has(id):
			pool.append(id)
	var fresh: Array[String] = []
	for id in pool:
		if not offers.has(id):
			fresh.append(id)
	if fresh.size() >= 3:
		pool = fresh
	offers.clear()
	while not pool.is_empty() and offers.size() < 3:
		var index := _rng.randi_range(0, pool.size() - 1)
		offers.append(pool[index])
		pool.remove_at(index)
	if notify:
		changed.emit()
