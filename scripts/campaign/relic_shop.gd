class_name RelicShop
extends RefCounted
## Hàng Rong's persistent visit. Wallet, deck and relic owners commit before signals.
signal changed()

const STOCK_SIZE := 3
const CARD_STOCK_SIZE := 3
const PRICE_RULES := {"relic_percent": 5.0, "card_percent": 2.0, "removal_percent": 3.0, "removal_growth": 1.5}
const MAX_PRICE := 9_000_000_000_000_000

var runtime: RelicRuntime
var wallet: VndWallet
var offers: Array[String] = []
var relic_stock: Array[String] = []
var card_stock: Array[CardData] = []
var sold_cards: Array[String] = []
var visit_id := ""
var visit_seed := 0
var purchased := false
var rerolls := 0
var target_vnd := 250_000
var removals := 0
var removal_pending := false
var removal_paid_vnd := 0
var removal_target_id := ""
var removal_target_state: Dictionary = {}
var card_serial := 0
var _mutating := false
var _legacy_card_stock := false
var _rng := RandomNumberGenerator.new()
var _campaign_ref: WeakRef

func _init(p_wallet: VndWallet = null, p_runtime: RelicRuntime = null) -> void:
	wallet = p_wallet
	runtime = p_runtime

func bind_campaign(campaign: CampaignManager) -> void:
	_campaign_ref = weakref(campaign)

func _campaign() -> CampaignManager:
	return _campaign_ref.get_ref() as CampaignManager if _campaign_ref != null else null

func _owner() -> GieoQueService:
	var campaign := _campaign()
	return campaign.gieo_que if campaign != null else null

func _can_trade() -> bool:
	var campaign := _campaign()
	if campaign == null: return true
	return campaign.current_phase in [CampaignManager.CampaignPhase.MORNING_EVENT, CampaignManager.CampaignPhase.AFTERNOON_EVENT] and campaign.event_manager.current_event != null and campaign.gieo_que.state in [GieoQueService.STATE_READY, GieoQueService.STATE_COMPLETE]

func reset_run() -> void:
	offers.clear()
	relic_stock.clear()
	card_stock.clear()
	sold_cards.clear()
	visit_id = ""
	purchased = false
	rerolls = 0
	removals = 0
	card_serial = 0
	_clear_removal()

func begin_visit(id: String, seed_value: int, goal: int) -> void:
	if visit_id == id or removal_pending or _mutating: return
	visit_id = id
	visit_seed = seed_value
	target_vnd = goal
	purchased = false
	rerolls = 0
	sold_cards.clear()
	_rng.seed = seed_value
	_roll(false)
	_generate_cards(seed_value)
	changed.emit()

func _priced(percent: float) -> int:
	return _round_price(float(target_vnd) * percent / 100.0)

func _round_price(amount: float) -> int:
	return mini(MAX_PRICE, maxi(500, int(ceil(minf(amount, float(MAX_PRICE)) / 500.0)) * 500))

func price() -> int:
	return _priced(PRICE_RULES.relic_percent)

func card_price() -> int:
	return _priced(PRICE_RULES.card_percent)

func removal_price() -> int:
	var amount := float(_priced(PRICE_RULES.removal_percent))
	for _use in mini(removals, 128):
		amount = minf(amount * PRICE_RULES.removal_growth, float(MAX_PRICE))
	return _round_price(amount)

func reroll_price() -> int:
	return _round_price(float(_priced(2.0)) * (rerolls + 1))

func buy(id: String) -> bool:
	if _mutating or not _can_trade() or runtime == null or wallet == null or not offers.has(id) or runtime.inventory.has(id) or not RelicCatalog.DEFINITIONS.has(id) or wallet.balance_vnd < price(): return false
	_mutating = true
	# Silent grant prevents a synchronous save observer from seeing unpaid ownership.
	if not runtime.acquire(id, false):
		_mutating = false
		return false
	offers.erase(id)
	purchased = true
	wallet.apply_vnd(-price(), "relic_purchase:" + id)
	runtime.inventory_changed.emit()
	changed.emit()
	_mutating = false
	return true

func available_cards() -> Array[CardData]:
	return card_stock.filter(func(card: CardData): return not sold_cards.has(card.unique_id))

func card_offer(id: String) -> CardData:
	for card in card_stock:
		if card.unique_id == id: return card
	return null

func buy_card(offer_id: String) -> CardData:
	var card := card_offer(offer_id)
	var owner := _owner()
	if _mutating or not _can_trade() or owner == null or card == null or sold_cards.has(offer_id) or wallet == null or wallet.balance_vnd < card_price(): return null
	# Identity allocation is run-wide and independent of rank/suit or any RNG.
	var serial := card_serial + 1
	while owner.owned_card("hang_rong_%d" % serial) != null: serial += 1
	var acquired := CardData.new("hang_rong_%d" % serial, card.rank, card.rank_index, card.suit, card.rank_index)
	_mutating = true
	if not owner.add_owned_card(acquired):
		_mutating = false
		return null
	card_serial = serial
	sold_cards.append(offer_id)
	purchased = true
	_campaign().synchronize_run_deck()
	wallet.apply_vnd(-card_price(), "card_purchase:" + acquired.unique_id)
	changed.emit()
	_mutating = false
	return acquired

func owned_cards() -> Array[CardData]:
	return _owner().persistent_deck.duplicate() if _owner() != null else []

func can_remove() -> bool:
	var owner := _owner()
	return owner != null and owner.persistent_deck.size() > DealState.MIN_CAMPAIGN_CARDS and _can_trade()

func pay_removal() -> bool:
	if _mutating or removal_pending or not can_remove() or wallet == null or wallet.balance_vnd < removal_price(): return false
	_mutating = true
	removal_pending = true
	removal_paid_vnd = removal_price()
	removal_target_id = ""
	removal_target_state.clear()
	purchased = true
	wallet.apply_vnd(-removal_paid_vnd, "card_removal:pay")
	changed.emit()
	_mutating = false
	return true

func choose_removal(id: String) -> bool:
	if _mutating or not removal_pending or not can_remove(): return false
	var card := _owner().owned_card(id)
	if card == null: return false
	_mutating = true
	removal_target_id = id
	removal_target_state = card.permanent_snapshot().duplicate(true)
	changed.emit()
	_mutating = false
	return true

func removal_target() -> CardData:
	return _owner().owned_card(removal_target_id) if _owner() != null else null

func confirm_removal() -> bool:
	var card := removal_target()
	if _mutating or not removal_pending or not can_remove() or card == null or card.permanent_snapshot() != removal_target_state: return false
	_mutating = true
	if not _owner().remove_owned_card(card.unique_id):
		_mutating = false
		return false
	removals += 1
	_clear_removal()
	_campaign().synchronize_run_deck()
	changed.emit()
	_mutating = false
	return true

func _clear_removal() -> void:
	removal_pending = false
	removal_paid_vnd = 0
	removal_target_id = ""
	removal_target_state.clear()

func reroll() -> bool:
	if _mutating or not _can_trade() or purchased or removal_pending or wallet == null or offers.is_empty() or wallet.balance_vnd < reroll_price(): return false
	var cost := reroll_price()
	_mutating = true
	rerolls += 1
	_roll(false)
	wallet.apply_vnd(-cost, "relic_reroll")
	changed.emit()
	_mutating = false
	return true

func _roll(notify: bool = true) -> void:
	var pool: Array[String] = []
	for id: String in RelicCatalog.DEFINITIONS:
		if runtime == null or not runtime.inventory.has(id): pool.append(id)
	var fresh := pool.filter(func(id): return not offers.has(id))
	if fresh.size() >= mini(STOCK_SIZE, pool.size()): pool.assign(fresh)
	offers.clear()
	while not pool.is_empty() and offers.size() < STOCK_SIZE:
		var index := _rng.randi_range(0, pool.size() - 1)
		offers.append(pool[index])
		pool.remove_at(index)
	relic_stock.assign(offers)
	if notify: changed.emit()

func _generate_cards(seed_value: int) -> void:
	var card_rng := RandomNumberGenerator.new()
	card_rng.seed = ("hang-rong-cards|%s|%d" % [visit_id, seed_value]).sha256_text().substr(0, 8).hex_to_int()
	card_stock.clear()
	for index in CARD_STOCK_SIZE:
		var rank_index := card_rng.randi_range(1, DeckManager.RANKS.size())
		var suit := DeckManager.SUITS[card_rng.randi_range(0, DeckManager.SUITS.size() - 1)]
		card_stock.append(CardData.new("offer_%s_%d" % [visit_id.sha256_text().substr(0, 12), index], DeckManager.RANKS[rank_index - 1], rank_index, suit, rank_index))

# Additive V3 fields retain compatibility with earlier run envelopes.
const RUN_SAVE_FIELDS_V3 := ["offers", "relic_stock", "card_stock", "sold_cards", "visit_id", "visit_seed", "purchased", "rerolls", "target_vnd", "removals", "removal_pending", "removal_paid_vnd", "removal_target_id", "removal_target_state", "card_serial"]
const RUN_SNAPSHOT_FIELDS := preload("res://scripts/campaign/run_snapshot_fields.gd")

func run_snapshot() -> Dictionary:
	return RUN_SNAPSHOT_FIELDS.fields(self, RUN_SAVE_FIELDS_V3)

func restore_run_snapshot(data: Dictionary) -> void:
	reset_run()
	RUN_SNAPSHOT_FIELDS.apply_fields(self, data, RUN_SAVE_FIELDS_V3)
	if not data.has("relic_stock"): relic_stock.assign(offers)
	_legacy_card_stock = not data.has("card_stock") and not visit_id.is_empty()

func run_rng_state() -> int:
	return _rng.state

func restore_run_rng(value: int) -> void:
	_rng.state = value
	# Upgrade a legacy visit once, without rerolling relics or spending any stream.
	if _legacy_card_stock:
		_generate_cards(value)
		_legacy_card_stock = false
