class_name RunSetupDraft
extends RefCounted

var difficulty: int = 1
var seed: String = ""
var music_system: String = ""
var emblem_id: String = ""

func copy() -> RunSetupDraft:
	var result := RunSetupDraft.new()
	result.difficulty = difficulty
	result.seed = seed
	result.music_system = music_system
	result.emblem_id = emblem_id
	return result
