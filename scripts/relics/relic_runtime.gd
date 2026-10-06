class_name RelicRuntime
extends RefCounted

signal inventory_changed()
## Every owned relic is active. "equipped" remains a save/API compatibility mirror.
var shop_wallet: VndWallet
var inventory: Array[String] = []
var equipped: Array[String] = []
var extension_counts: Dictionary = {}
var _purchasing := false

func price_for(id: String) -> int:
	if inventory.has(id) or shop_wallet == null: return 0
	return shop_wallet.scaled_cost(50_000, 5)

func purchase_and_equip(id: String) -> bool:
	if _purchasing or not RelicCatalog.DEFINITIONS.has(id) or shop_wallet == null: return false
	if inventory.has(id): return true
	var cost := price_for(id)
	if shop_wallet.balance_vnd < cost: return false
	_purchasing = true
	acquire(id, false)
	shop_wallet.apply_vnd(-cost, "relic_purchase:" + id)
	inventory_changed.emit()
	_purchasing = false
	return true

func acquire(id: String, notify: bool = true) -> bool:
	if not RelicCatalog.DEFINITIONS.has(id): return false
	var added := not inventory.has(id)
	if added: inventory.append(id)
	if not equipped.has(id): equipped.append(id)
	if added and notify: inventory_changed.emit()
	return true

func equip(id: String) -> bool:
	if not inventory.has(id): return false
	if not equipped.has(id):
		equipped.append(id)
		inventory_changed.emit()
	return true

func gift(id: String) -> bool:
	if not inventory.has(id): return false
	inventory.erase(id)
	equipped.erase(id)
	inventory_changed.emit()
	return true

func reset_run() -> void:
	inventory.clear()
	equipped.clear()
	phase_started()
	inventory_changed.emit()

func phase_started() -> void:
	extension_counts.clear()

func snapshot() -> Dictionary:
	return {"inventory": inventory.duplicate(), "equipped": equipped.duplicate(), "extensions": extension_counts.duplicate()}

func restore(data: Dictionary) -> void:
	inventory.assign(data.get("inventory", []))
	# Formerly unequipped owned relics join the active list, in existing order.
	equipped.assign(inventory)
	extension_counts = data.get("extensions", {}).duplicate()
	inventory_changed.emit()

# Once per committed action, after normal scoring. Never per scoring pass.
func resolve(context: ScoringContext, meld_id: int) -> Array[Dictionary]:
	var bonuses: Array[Dictionary] = []
	if context.action_type not in ["new_meld", "extension"]:
		return bonuses
	if context.action_type == "extension":
		extension_counts[meld_id] = int(extension_counts.get(meld_id, 0)) + 1
	for id in equipped:
		var definition: Dictionary = RelicCatalog.DEFINITIONS[id]
		if definition.event != context.action_type:
			continue
		if definition.has("type") and definition.type != context.meld_type:
			continue
		if definition.has("exact") and context.cards.size() != int(definition.exact):
			continue
		if context.cards.size() < int(definition.get("minimum", 1)):
			continue
		var matches := true
		for card in context.cards:
			if definition.has("suits") and not definition.suits.has(card.suit):
				matches = false
		if not matches:
			continue
		var extension_count := int(extension_counts.get(meld_id, 1))
		bonuses.append({"id": id, "name": definition.name,
			"rate_percent": RelicCatalog.rate_bonus(id, context.cards.size(), extension_count), "meld_id": meld_id})
	return bonuses
