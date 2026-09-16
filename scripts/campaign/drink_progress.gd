class_name DrinkProgress
extends RefCounted

signal drink_unlocked(drink_id: String)
signal progress_changed()

const SAVE_PATH := "user://demo_drink_progress.cfg"
# metric, target, percentage of current day's requirement
const GOALS := {
	DrinkCatalog.TRA_DA: ["", 0, 0],
	DrinkCatalog.NUOC_VOI: ["melds", 5, 1],
	DrinkCatalog.NHAN_TRAN: ["morning_deals", 1, 1],
	DrinkCatalog.SAM_DUA: ["mondays", 1, 2],
	DrinkCatalog.DEN_DA: ["nhan_tran_swaps", 10, 3],
	DrinkCatalog.NAU_DA: ["nuoc_voi_returns", 5, 4],
	DrinkCatalog.BAC_XIU: ["sam_dua_preserved", 15, 3],
	DrinkCatalog.STING: ["sets", 10, 3],
	DrinkCatalog.BO_HUC: ["sting_pairs", 10, 5],
	DrinkCatalog.C2_ICED_TEA: ["runs", 10, 3],
	DrinkCatalog.MIA_TAC: ["red_runs", 15, 4],
	DrinkCatalog.MIA_SAU_RIENG: ["black_runs", 15, 4],
}
var counters: Dictionary = {}
var save_path: String
var _seen_melds: Dictionary = {}


func _init(path: String = SAVE_PATH) -> void:
	save_path = path
	if path.is_empty():
		return
	var config := ConfigFile.new()
	if config.load(path) != OK:
		return
	for goal: Array in GOALS.values():
		var metric := String(goal[0])
		if metric.is_empty():
			continue
		counters[metric] = clampi(int(config.get_value("progress", metric, 0)), 0, int(goal[1]))


func is_unlocked(drink_id: String) -> bool:
	if not GOALS.has(drink_id):
		return false
	var goal: Array = GOALS[drink_id]
	return int(counters.get(goal[0], 0)) >= int(goal[1])


func goal_text(drink_id: String) -> String:
	if not GOALS.has(drink_id):
		return ""
	var goal: Array = GOALS[drink_id]
	if is_unlocked(drink_id):
		return TranslationServer.translate("DRINK_UNLOCKED")
	return "%s · %d/%d" % [
		TranslationServer.translate("DRINK_GOAL_" + String(goal[0]).to_upper()),
		int(counters.get(goal[0], 0)), int(goal[1]),
	]


func add_progress(metric: String, amount: int = 1) -> void:
	if amount <= 0:
		return
	var newly_unlocked: Array[String] = []
	var changed := false
	for drink_id: String in GOALS:
		var goal: Array = GOALS[drink_id]
		if goal[0] != metric or is_unlocked(drink_id):
			continue
		counters[metric] = mini(int(goal[1]), int(counters.get(metric, 0)) + amount)
		changed = true
		if is_unlocked(drink_id):
			newly_unlocked.append(drink_id)
	if not changed:
		return
	_save()
	progress_changed.emit()
	for drink_id in newly_unlocked:
		drink_unlocked.emit(drink_id)


func begin_deal() -> void:
	_seen_melds.clear()


func record_action(deal: DealState, result: Dictionary) -> void:
	if not result.get("ok", false):
		return
	match String(result.get("action", "")):
		"new_meld":
			var meld_id := int(result.get("meld_id", -1))
			if _seen_melds.has(meld_id):
				return
			var meld := deal.get_meld(meld_id)
			if meld == null:
				return
			_seen_melds[meld_id] = true
			add_progress("melds")
			if meld.meld_type == MeldRules.TYPE_SET:
				if not meld.pair_created:
					add_progress("sets")
				elif deal.current_drink_id == DrinkCatalog.STING:
					add_progress("sting_pairs")
			elif meld.meld_type == MeldRules.TYPE_RUN:
				add_progress("runs")
				var red := true
				var black := true
				for card in meld.cards:
					red = red and card.suit in ["Hearts", "Diamonds"]
					black = black and card.suit in ["Spades", "Clubs"]
				if red:
					add_progress("red_runs")
				if black:
					add_progress("black_runs")
		"nhan_tran_swap":
			add_progress("nhan_tran_swaps")
		"nuoc_voi_return":
			add_progress("nuoc_voi_returns")
		"dump":
			if deal.current_drink_id == DrinkCatalog.SAM_DUA:
				add_progress("sam_dua_preserved", result.get("preserved", []).size())


func _save() -> void:
	if save_path.is_empty():
		return
	var config := ConfigFile.new()
	for metric: String in counters:
		config.set_value("progress", metric, counters[metric])
	var error := config.save(save_path + ".tmp")
	if error == OK:
		error = DirAccess.rename_absolute(save_path + ".tmp", save_path)
	if error != OK:
		push_warning("Could not save drink unlocks: %s" % error_string(error))
