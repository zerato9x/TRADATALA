class_name PhaseMetrics
extends RefCounted

var raw_gross: int = 0
var new_phom_count: int = 0
var extension_count: int = 0
var u: bool = false
var u_khan_count: int = 0
var missed_discards: int = 0


func reset() -> void:
	raw_gross = 0
	new_phom_count = 0
	extension_count = 0
	u = false
	u_khan_count = 0
	missed_discards = 0
