extends Control
## Presentation only: the receipt/controller retain payment and progression.
const ENGINE_START_SECONDS := 1.25
var _motion: Tween
var _engine: AudioStreamPlayer
var _destination: TextureRect

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_engine = AudioStreamPlayer.new()
	_engine.stream = preload("res://assets/audio/sfx/bike_sound.mp3")
	_engine.bus = "Sound"
	add_child(_engine)
	hide()

func play(destination: TextureRect) -> void:
	stop()
	_destination = destination
	destination.modulate.a = 0.0
	show()
	var rider := TextureRect.new()
	rider.texture = destination.texture
	rider.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	rider.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	rider.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rider.size = destination.size
	rider.pivot_offset = rider.size * Vector2(0.5, 0.85)
	add_child(rider)
	var parked := destination.global_position - global_position
	rider.position = Vector2(size.x + rider.size.x, parked.y + 35.0)
	rider.rotation = 0.06
	_engine.volume_db = -18.0
	# Skip the quiet lead-in so the rev coincides with the rider entering.
	_engine.play(ENGINE_START_SECONDS)
	_motion = create_tween().set_parallel(true)
	_motion.tween_property(rider, "position", parked, 0.85).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	_motion.tween_property(rider, "rotation", 0.0, 0.85)
	_motion.tween_property(_engine, "volume_db", -12.0, 0.45)
	_motion.chain().tween_property(_engine, "volume_db", -40.0, 0.2)
	_motion.chain().tween_callback(stop)

func stop() -> void:
	if is_instance_valid(_destination):
		_destination.modulate.a = 1.0
	_destination = null
	if _motion:
		_motion.kill()
		_motion = null
	if is_instance_valid(_engine):
		_engine.stop()
	for child in get_children():
		if child is TextureRect:
			remove_child(child)
			child.queue_free()
	hide()

func _exit_tree() -> void:
	stop()
	if is_instance_valid(_engine):
		_engine.stream = null
