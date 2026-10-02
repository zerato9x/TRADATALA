class_name ZodiacBossRule
extends RefCounted
## Deal-owned dispatcher. Boss policy and isolated randomness stay in Zodiac.
const RULES := {
	"rooster": preload("res://scripts/zodiac/rules/rooster.gd"),
	"cat": preload("res://scripts/zodiac/rules/cat.gd"),
	"dog": preload("res://scripts/zodiac/rules/dog.gd"),
	"monkey": preload("res://scripts/zodiac/rules/monkey.gd"),
	"pig": preload("res://scripts/zodiac/rules/pig.gd"),
	"ox": preload("res://scripts/zodiac/rules/ox.gd"),
	"horse": preload("res://scripts/zodiac/rules/horse.gd"),
	"goat": preload("res://scripts/zodiac/rules/goat.gd"),
	"rat": preload("res://scripts/zodiac/rules/rat.gd"),
	"tiger": preload("res://scripts/zodiac/rules/tiger.gd"),
	"snake": preload("res://scripts/zodiac/rules/snake.gd"),
	"dragon": preload("res://scripts/zodiac/rules/dragon.gd"),
}
var id := ""
var difficulty := ZodiacCatalog.UNPLEASED
# Legacy string access remains available to old saves and presentation callers.
var disposition: String:
	get: return ZodiacCatalog.difficulty_name(difficulty)
	set(value): difficulty = ZodiacCatalog.difficulty_value(value)
var register_closed := false
var locked_ids: Array[String] = []
var turn_serial := 0
var phase := 1
var rng := RandomNumberGenerator.new()
var data: Dictionary = {}
var events: Array[Dictionary] = []
var _mechanic: RefCounted

func configure(zodiac_id: String = "", severity: Variant = "UNPLEASED", seed_value: int = 0) -> void:
	id = "rat" if zodiac_id == "mouse" else zodiac_id
	difficulty = ZodiacCatalog.difficulty_value(severity)
	register_closed = false
	locked_ids.clear()
	turn_serial = 0
	phase = 1
	data.clear()
	events.clear()
	rng.seed = seed_value
	_load_mechanic()
	if _mechanic != null: _mechanic.configure(self)

func _load_mechanic() -> void:
	_mechanic = RULES[id].new() if RULES.has(id) else null

func begin_phase(deal) -> void:
	phase = deal.current_phase
	locked_ids.clear()
	if phase == 1: register_closed = false
	if _mechanic != null: _mechanic.begin_phase(self, deal)

func begin_turn(current_phase: int, hand: Array[CardData], deal = null) -> void:
	phase = current_phase
	turn_serial += 1
	locked_ids.clear()
	if _mechanic != null: _mechanic.begin_turn(self, current_phase, hand, deal)

func mandatory_discard(current_phase: int, count: int) -> void:
	if id == "rooster" and current_phase == 1:
		register_closed = count >= int(ZodiacCatalog.tuning(id, "discard_deadline", difficulty))

func suppresses(current_phase: int) -> bool:
	return id == "rooster" and current_phase == 1 and register_closed

func is_locked(card: CardData) -> bool:
	return card != null and locked_ids.has(card.unique_id)

func legality(action: String, current_phase: int, meld_id: int = -1, cards: Array[CardData] = []) -> String:
	return _mechanic.legality(self, action, current_phase, meld_id, cards) if _mechanic != null else ""

func payout_policy(context: ScoringContext, meld_id: int, commit: bool = false) -> Dictionary:
	return _mechanic.payout(self, context, meld_id, commit) if _mechanic != null else {}

func apply_payout(context: ScoringContext, meld_id: int) -> void:
	var policy := payout_policy(context, meld_id, true)
	var percent := clampi(int(policy.get("percent", 100)), 0, 100)
	if percent == 100: return
	context.suppression_reason = String(policy.get("reason", "zodiac_payout")) if percent == 0 else ""
	context.final_points = 0
	for scoring_pass: ScoringContext in context.scoring_passes:
		scoring_pass.final_points = int(scoring_pass.final_points * percent / 100.0)
		scoring_pass.suppression_reason = context.suppression_reason
		if percent == 0:
			scoring_pass.presentation_hits.clear()
		else:
			var accounted := 0
			for hit: Dictionary in scoring_pass.presentation_hits:
				hit.points = int(int(hit.points) * percent / 100.0)
				accounted += int(hit.points)
			if accounted != scoring_pass.final_points:
				scoring_pass.presentation_hits.append({"kind": "modifier", "card_id": "", "points": scoring_pass.final_points - accounted})
		context.final_points += scoring_pass.final_points
	data["last_feedback"] = String(policy.get("reason", ""))

func after_action(deal, result: Dictionary) -> void:
	if _mechanic != null: _mechanic.after_action(self, deal, result)

func after_discard(deal, record: DiscardRecord) -> void:
	if _mechanic != null: _mechanic.after_discard(self, deal, record)

func income(deal, amount: int, reason: String) -> void:
	if _mechanic != null and amount > 0: _mechanic.income(self, deal, amount, reason)

func deadwood(deal, context: Dictionary) -> void:
	if _mechanic != null: _mechanic.deadwood(self, deal, context)

func turn_discard(deal, requested: CardData) -> CardData:
	return _mechanic.turn_discard(self, deal, requested) if _mechanic != null else requested

func phase_limit(current_phase: int, ordinary: int) -> int:
	return _mechanic.phase_limit(self, current_phase, ordinary) if _mechanic != null else ordinary

func settle(deal) -> void:
	if data.get("settled", false): return
	data["settled"] = true
	if _mechanic != null: _mechanic.settle(self, deal)

func presentation() -> Dictionary:
	var result := {"id": id, "difficulty": difficulty, "disposition": disposition,
		"skill": ZodiacCatalog.skill_name(id, difficulty), "rule": ZodiacCatalog.rule_text(id, difficulty) if not id.is_empty() else "",
		"locked_ids": locked_ids.duplicate(), "register_closed": register_closed, "turn_serial": turn_serial}
	result.merge(data.duplicate(true))
	if _mechanic != null: result.merge(_mechanic.presentation(self), true)
	return result

func take_events() -> Array[Dictionary]:
	var result := events.duplicate(true)
	events.clear()
	return result

func snapshot() -> Dictionary:
	return {"id": id, "difficulty": difficulty, "disposition": disposition, "register_closed": register_closed,
		"locked_ids": locked_ids.duplicate(), "turn_serial": turn_serial, "phase": phase, "rng": rng.state,
		"data": data.duplicate(true), "events": events.duplicate(true)}

func restore(saved: Dictionary) -> void:
	configure(saved.get("id", ""), saved.get("difficulty", saved.get("disposition", "UNPLEASED")))
	register_closed = saved.get("register_closed", false)
	locked_ids.assign(saved.get("locked_ids", []))
	turn_serial = saved.get("turn_serial", 0)
	phase = saved.get("phase", 1)
	data.merge(saved.get("data", {}).duplicate(true), true)
	events.assign(saved.get("events", []))
	rng.state = saved.get("rng", 0)

func before_refill(deal) -> void:
	if _mechanic != null: _mechanic.before_refill(self, deal)
