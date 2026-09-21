extends RefCounted
const PATH := "user://difficulty_progress.cfg"
const MAX_LEVEL := 28
var path: String
var unlocked := 1
func _init(save_path: String = PATH) -> void:
	path = save_path
	var file := ConfigFile.new()
	if not path.is_empty() and file.load(path) == OK:
		unlocked = clampi(int(file.get_value("difficulty", "unlocked", 1)), 1, MAX_LEVEL)
func complete_week(level: int) -> void:
	if level < 1 or level > unlocked: return
	unlocked = maxi(unlocked, mini(level + 1, MAX_LEVEL))
	if path.is_empty(): return
	var file := ConfigFile.new()
	file.set_value("difficulty", "unlocked", unlocked)
	var result := file.save(path)
	if result != OK: push_warning("Could not save difficulty unlock: %s" % error_string(result))
