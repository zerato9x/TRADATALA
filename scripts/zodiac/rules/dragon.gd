extends "res://scripts/zodiac/zodiac_mechanic.gd"
const Analysis := preload("res://scripts/zodiac/dragon_analysis.gd")
const MODIFIERS := {
	"rooster": preload("res://scripts/zodiac/rules/rooster.gd"), "cat": preload("res://scripts/zodiac/rules/cat.gd"),
	"dog": preload("res://scripts/zodiac/rules/dog.gd"), "monkey": preload("res://scripts/zodiac/rules/monkey.gd"),
	"pig": preload("res://scripts/zodiac/rules/pig.gd"), "ox": preload("res://scripts/zodiac/rules/ox.gd"),
	"horse": preload("res://scripts/zodiac/rules/horse.gd"), "goat": preload("res://scripts/zodiac/rules/goat.gd"),
	"rat": preload("res://scripts/zodiac/rules/rat.gd"), "tiger": preload("res://scripts/zodiac/rules/tiger.gd"),
	"snake": preload("res://scripts/zodiac/rules/snake.gd"),
}
var _selected := ""
var _curated: RefCounted

func _modifier(rule) -> RefCounted:
	var id: String = rule.data.get("modifier_id", "")
	if not MODIFIERS.has(id): return null
	if id != _selected or _curated == null:
		_selected = id
		_curated = MODIFIERS[id].new()
	return _curated

func configure(rule) -> void:
	rule.data.merge({"analysis": Analysis.analyze([], rule.difficulty), "progress_vnd": 0, "target_met": false, "victory": false, "modifier_id": "", "modifier": {}})

func begin_phase(rule, _deal) -> void:
	rule.data.modifier_id = ""
	rule.data.modifier = {}

func before_refill(rule, _deal) -> void:
	rule.data.modifier_id = ""
	rule.data.modifier = {}
	rule.locked_ids.clear()

func begin_turn(rule, _phase: int, _hand: Array[CardData], deal) -> void:
	if deal == null: return
	var choices: Array = MODIFIERS.keys()
	rule.data.modifier_id = choices[rule.rng.randi_range(0, choices.size() - 1)]
	rule.data.modifier = {}
	rule.data.erase("hostile_result")
	_modifier(rule).dragon_begin(rule, deal, rule.data.modifier)
	rule.events.append({"action": "dragon_modifier", "id": rule.data.modifier_id, "difficulty": rule.difficulty, "state": rule.data.modifier.duplicate(true)})

func payout(rule, context: ScoringContext, meld_id: int, commit: bool) -> Dictionary:
	var analysis: Dictionary = rule.data.analysis
	if context.action_type != analysis.action or context.meld_type != analysis.meld_type:
		return {"percent": 0, "reason": "dragon_tactic_required"}
	var modifier := _modifier(rule)
	return modifier.dragon_payout(rule, context, meld_id, rule.data.modifier, commit) if modifier != null else {}

func after_action(rule, deal, result: Dictionary) -> void:
	var context: ScoringContext = result.get("context")
	if context != null and context.final_points > 0 and context.action_type == rule.data.analysis.action and context.meld_type == rule.data.analysis.meld_type:
		rule.data.progress_vnd += maxi(int(result.get("earned_vnd", 0)), 0)
		rule.data.target_met = int(rule.data.progress_vnd) >= int(rule.data.analysis.target_vnd)
	var modifier := _modifier(rule)
	if modifier != null: modifier.dragon_after(rule, deal, result, rule.data.modifier)

func after_discard(rule, deal, record: DiscardRecord) -> void:
	var modifier := _modifier(rule)
	if modifier != null: modifier.dragon_discard(rule, deal, record, rule.data.modifier)

func income(rule, deal, amount: int, reason: String) -> void:
	var modifier := _modifier(rule)
	if modifier != null: modifier.dragon_income(rule, deal, amount, reason, rule.data.modifier)

func deadwood(rule, deal, context: Dictionary) -> void:
	var modifier := _modifier(rule)
	if modifier != null: modifier.dragon_deadwood(rule, deal, context, rule.data.modifier)

func turn_discard(rule, deal, requested: CardData) -> CardData:
	var modifier := _modifier(rule)
	return modifier.dragon_turn_discard(rule, deal, requested, rule.data.modifier) if modifier != null else requested

func settle(rule, _deal) -> void:
	rule.data.victory = int(rule.data.progress_vnd) >= int(rule.data.analysis.target_vnd)

func presentation(rule) -> Dictionary:
	return {"target_vnd": rule.data.analysis.target_vnd, "tactic": rule.data.analysis.tactic, "average_vnd": rule.data.analysis.average_vnd, "ending": "RỒNG RẮN LÊN MÂY" if rule.data.victory else ""}
