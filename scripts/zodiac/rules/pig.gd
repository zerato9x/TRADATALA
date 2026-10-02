extends "res://scripts/zodiac/zodiac_mechanic.gd"

func configure(rule) -> void:
	var target := int(ZodiacCatalog.tuning("pig", "baseline_target_vnd", rule.difficulty))
	target = int(target * int(ZodiacCatalog.tuning("pig", "target_percent", rule.difficulty)) / 100.0)
	rule.data.merge({"pool_vnd": 0, "target_vnd": target, "progress_vnd": 0, "target_met": false})

func income(rule, deal, amount: int, _reason: String) -> void:
	if rule.data.target_met: return
	rule.data.progress_vnd += amount
	var take := int(amount * int(ZodiacCatalog.tuning("pig", "siphon_percent", rule.difficulty)) / 100.0)
	rule.data.pool_vnd += take
	if take > 0:
		deal.boss_adjust_wallet(-take, "zodiac:pig:siphon")
		rule.events.append({"action": "pig_siphon", "amount_vnd": take, "pool_vnd": rule.data.pool_vnd})
	if int(rule.data.progress_vnd) >= int(rule.data.target_vnd):
		rule.data.target_met = true
		var returned := int(rule.data.pool_vnd)
		rule.data.pool_vnd = 0
		deal.boss_adjust_wallet(returned, "zodiac:pig:return")
		rule.events.append({"action": "pig_return", "amount_vnd": returned})

func settle(rule, deal) -> void:
	if rule.difficulty != ZodiacCatalog.UNPLEASED or rule.data.target_met: return
	var penalty := bank_loss(deal.wallet.balance_vnd, rule.difficulty)
	deal.boss_adjust_wallet(-penalty, "zodiac:pig:failed_target")
	rule.data["bank_loss_vnd"] = penalty
	rule.events.append({"action": "pig_bank_loss", "amount_vnd": penalty})

# Provisional: lose the configured fraction of a positive bank, never deepen debt.
func bank_loss(bank: int, difficulty: int) -> int:
	return int(maxi(bank, 0) * int(ZodiacCatalog.tuning("pig", "bank_loss_percent", difficulty)) / 100.0)

func dragon_begin(_rule, _deal, state: Dictionary) -> void:
	state["siphoned_vnd"] = 0

func dragon_income(rule, deal, amount: int, _reason: String, state: Dictionary) -> void:
	var take := int(amount * int(ZodiacCatalog.tuning("pig", "siphon_percent", rule.difficulty)) / 100.0)
	state.siphoned_vnd += take
	deal.boss_adjust_wallet(-take, "zodiac:dragon:pig_siphon")
	rule.events.append({"action": "pig_siphon", "amount_vnd": take, "dragon_modifier": true})
