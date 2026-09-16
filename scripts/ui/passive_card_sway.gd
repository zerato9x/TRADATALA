extends Node

# Stable card faces only. Hand and meld faces have their own independent sway
# layers so this never competes with a scoring shake or a travel tween.
var phase := 0.0
var baseline := 0.0

func _ready() -> void:
	var face := get_parent() as Control
	baseline = face.rotation
	phase = float(absi(str(face.get_instance_id()).hash()) % 10000) * 0.01

func _process(_delta: float) -> void:
	var face := get_parent() as Control
	if not face.is_visible_in_tree():
		return
	face.pivot_offset = face.size * 0.5
	face.rotation = baseline + deg_to_rad(0.8) * sin(Time.get_ticks_msec() * 0.001 * (0.7 + fmod(phase, 0.6)) + phase)