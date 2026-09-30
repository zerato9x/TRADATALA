class_name ZodiacBossRule
extends RefCounted
## Deal-owned rule state. Its RNG never touches the deck or campaign streams.
var id := ""
var disposition := "UNPLEASED"
var register_closed := false
var locked_ids: Array[String] = []
var turn_serial := 0
var rng := RandomNumberGenerator.new()

func configure(zodiac_id: String = "", mood: String = "UNPLEASED", seed_value: int = 0) -> void:
	id = zodiac_id
	disposition = mood
	register_closed = false
	locked_ids.clear()
	turn_serial = 0
	rng.seed = seed_value

func begin_turn(phase: int, hand: Array[CardData]) -> void:
	turn_serial += 1
	locked_ids.clear()
	if id != "cat" or phase != 2: return
	var pool := hand.duplicate()
	var count := mini(int(ZodiacCatalog.DEFINITIONS.cat.locks[disposition]), pool.size())
	for _i in count:
		var index := rng.randi_range(0, pool.size() - 1)
		locked_ids.append(pool[index].unique_id)
		pool.remove_at(index)

func mandatory_discard(phase: int, count: int) -> void:
	if id == "rooster" and phase == 1:
		register_closed = count >= int(ZodiacCatalog.DEFINITIONS.rooster.deadlines[disposition])

func suppresses(phase: int) -> bool:
	return id == "rooster" and phase == 1 and register_closed

func is_locked(card: CardData) -> bool:
	return card != null and locked_ids.has(card.unique_id)

func snapshot() -> Dictionary:
	return {"id": id, "disposition": disposition, "register_closed": register_closed, "locked_ids": locked_ids.duplicate(), "turn_serial": turn_serial, "rng": rng.state}

func restore(data: Dictionary) -> void:
	id = data.get("id", "")
	disposition = data.get("disposition", "UNPLEASED")
	register_closed = data.get("register_closed", false)
	locked_ids.assign(data.get("locked_ids", []))
	turn_serial = data.get("turn_serial", 0)
	rng.state = data.get("rng", 0)
