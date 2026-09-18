class_name RelicRuntime
extends RefCounted

signal inventory_changed()
const MAX_EQUIPPED := 4
var shop_wallet: VndWallet

func price_for(id: String) -> int:
	if inventory.has(id) or shop_wallet == null:
		return 0
	return shop_wallet.scaled_cost(50_000, 5)

func purchase_and_equip(id: String) -> bool:
	if not RelicCatalog.DEFINITIONS.has(id) or equipped.size() >= MAX_EQUIPPED:
		return false
	var price := price_for(id)
	if price > 0 and shop_wallet.balance_vnd < price:
		return false
	# Own and equip before emitting payment; repeat requests cannot buy twice.
	if not inventory.has(id):
		inventory.append(id)
	if not equipped.has(id):
		equipped.append(id)
	if price > 0:
		shop_wallet.apply_vnd(-price, "relic_purchase:" + id)
	inventory_changed.emit()
	return true

var inventory: Array[String] = []
var equipped: Array[String] = []
var extension_counts: Dictionary = {}

func acquire(id: String) -> bool:
	if not RelicCatalog.DEFINITIONS.has(id):
		return false
	if not inventory.has(id):
		inventory.append(id)
		inventory_changed.emit()
	return true

func equip(id: String) -> bool:
	if not inventory.has(id):
		return false
	if equipped.has(id):
		return true
	if equipped.size() >= MAX_EQUIPPED:
		return false
	equipped.append(id)
	inventory_changed.emit()
	return true

func remove(id: String) -> void:
	equipped.erase(id)
	inventory_changed.emit()

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
	equipped.assign(data.get("equipped", []))
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
		var points := int(definition.points)
		if definition.get("per_card", false):
			points *= context.cards.size()
		if definition.get("escalating", false):
			points *= int(extension_counts[meld_id])
		bonuses.append({"id": id, "name": definition.name, "points": points, "meld_id": meld_id})
	return bonuses
