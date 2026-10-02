extends "res://scripts/zodiac/zodiac_mechanic.gd"

func begin_turn(rule, phase: int, hand: Array[CardData], _deal) -> void:
	if phase == 2: _lock(rule, hand, int(ZodiacCatalog.tuning("cat", "lock_count", rule.difficulty)))

func _lock(rule, hand: Array[CardData], count: int) -> void:
	var pool := hand.duplicate()
	for _i in mini(count, pool.size()):
		var index: int = rule.rng.randi_range(0, pool.size() - 1)
		rule.locked_ids.append(pool[index].unique_id)
		pool.remove_at(index)

func legality(rule, action: String, phase: int, _meld_id: int, _cards: Array[CardData]) -> String:
	if rule.difficulty == ZodiacCatalog.UNPLEASED and phase == 1 and action == "extension":
		return ZodiacCatalog.words("RÌNH MỒI: Phase 1 permits new Melds only.", "RÌNH MỒI: Hiệp 1 chỉ được tạo Phỏm mới.")
	return ""

func dragon_begin(rule, deal, _state: Dictionary) -> void:
	_lock(rule, deal.hand, mini(int(ZodiacCatalog.tuning("cat", "lock_count", rule.difficulty)), maxi(deal.hand.size() - 1, 0)))
