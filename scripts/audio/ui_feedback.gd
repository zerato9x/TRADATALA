class_name UIFeedback
extends Node
## Bounded, scene-owned feedback. All cues obey the existing Sound slider.
const CUES := {
	&"drink_tra_da": [preload("res://assets/audio/sfx/drinks/tra_da.wav"), -14.0, 1.0, 0.10, 1.2],
	&"drink_nuoc_voi": [preload("res://assets/audio/sfx/drinks/nuoc_voi.wav"), -14.0, 1.0, 0.10, 1.2],
	&"drink_nhan_tran": [preload("res://assets/audio/sfx/drinks/nhan_tran.wav"), -14.0, 1.0, 0.10, 1.2],
	&"drink_sam_dua": [preload("res://assets/audio/sfx/drinks/sam_dua.wav"), -14.0, 1.0, 0.10, 1.2],
	&"drink_den_da": [preload("res://assets/audio/sfx/drinks/den_da.wav"), -14.0, 1.0, 0.10, 1.2],
	&"drink_nau_da": [preload("res://assets/audio/sfx/drinks/nau_da.wav"), -14.0, 1.0, 0.10, 1.2],
	&"drink_bac_xiu": [preload("res://assets/audio/sfx/drinks/bac_xiu.wav"), -14.0, 1.0, 0.10, 1.2],
	&"drink_sting": [preload("res://assets/audio/sfx/drinks/sting.wav"), -14.0, 1.0, 0.10, 1.2],
	&"drink_bo_huc": [preload("res://assets/audio/sfx/drinks/bo_huc.wav"), -14.0, 1.0, 0.10, 1.2],
	&"drink_c2_iced_tea": [preload("res://assets/audio/sfx/drinks/c2_iced_tea.wav"), -14.0, 1.0, 0.10, 1.2],
	&"drink_mia_tac": [preload("res://assets/audio/sfx/drinks/mia_tac.wav"), -14.0, 1.0, 0.10, 1.2],
	&"drink_mia_sau_rieng": [preload("res://assets/audio/sfx/drinks/mia_sau_rieng.wav"), -14.0, 1.0, 0.10, 1.2],
	&"hover": [preload("res://assets/audio/sfx/feedback/tap.wav"), -27.0, 1.18, 0.09, 0.12],
	&"press": [preload("res://assets/audio/sfx/feedback/tap.wav"), -19.0, 1.0, 0.07, 0.24],
	&"gain": [preload("res://assets/audio/sfx/feedback/reward.wav"), -20.0, 1.0, 0.09, 0.38],
	&"loss": [preload("res://assets/audio/sfx/feedback/tap.wav"), -16.0, 0.75, 0.12, 0.32],
	&"reject": [preload("res://assets/audio/sfx/feedback/tap.wav"), -16.0, 0.65, 0.18, 0.28],
	&"transition": [preload("res://assets/audio/sfx/feedback/transition.wav"), -23.0, 1.15, 0.18, 0.42],
	&"drink": [preload("res://assets/audio/sfx/feedback/drink.wav"), -12.0, 1.0, 0.20, 0.85],
	&"lever": [preload("res://assets/audio/sfx/feedback/lever.mp3"), -14.0, 1.0, 0.20, 0.65],
	&"reels": [preload("res://assets/audio/sfx/feedback/reels.mp3"), -21.0, 1.0, 0.20, 2.4],
	&"reel_stop": [preload("res://assets/audio/sfx/feedback/tap.wav"), -15.0, 0.9, 0.08, 0.22],
	&"jackpot": [preload("res://assets/audio/sfx/feedback/jackpot.mp3"), -17.0, 1.0, 0.50, 2.5],
}
var players: Dictionary = {}
var play_counts: Dictionary = {}
var _last_play: Dictionary = {}
var _remaining: Dictionary = {}

func _ready() -> void:
	for cue in CUES:
		var player := AudioStreamPlayer.new()
		player.name = String(cue).to_pascal_case()
		player.stream = CUES[cue][0]
		player.bus = &"Sound"
		player.max_polyphony = 1
		add_child(player)
		players[cue] = player
	_bind_tree(get_parent())
	get_tree().node_added.connect(_on_node_added)

func _on_node_added(node: Node) -> void:
	if node is BaseButton:
		_bind_button(node)

func _bind_tree(node: Node) -> void:
	if node is BaseButton:
		_bind_button(node)
	for child in node.get_children():
		_bind_tree(child)

func _bind_button(node: Node) -> void:
	if not is_instance_valid(node) or not get_parent().is_ancestor_of(node):
		return
	var button := node as BaseButton
	if button.has_meta("ui_feedback_bound"):
		return
	button.set_meta("ui_feedback_bound", true)
	button.mouse_entered.connect(_button_cue.bind(button, &"hover"))
	button.pressed.connect(_button_cue.bind(button, &"press"))

func _button_cue(button: BaseButton, cue: StringName) -> void:
	if button.is_visible_in_tree() and not button.disabled:
		play(cue)

func play(cue: StringName, strength: float = 1.0) -> void:
	if not players.has(cue):
		return
	var spec: Array = CUES[cue]
	var now := Time.get_ticks_msec()
	if now - int(_last_play.get(cue, -10000)) < int(float(spec[3]) * 1000.0):
		return
	_last_play[cue] = now
	var player: AudioStreamPlayer = players[cue]
	player.volume_db = float(spec[1]) + linear_to_db(clampf(strength, 0.5, 1.25))
	player.pitch_scale = float(spec[2])
	player.play()
	_remaining[cue] = float(spec[4])
	play_counts[cue] = int(play_counts.get(cue, 0)) + 1

func stop(cue: StringName) -> void:
	if players.has(cue):
		(players[cue] as AudioStreamPlayer).stop()
	_remaining.erase(cue)

func _process(delta: float) -> void:
	for cue in _remaining.keys():
		_remaining[cue] -= delta
		var remaining := float(_remaining[cue])
		if remaining <= 0.0:
			stop(cue)
		elif remaining < 0.08:
			(players[cue] as AudioStreamPlayer).volume_db -= delta * 240.0

func money_impact(intensity: float, positive: bool) -> void:
	play(&"gain" if positive else &"loss", intensity)

func play_drink(drink_id: String, strength: float = 1.0) -> void:
	play(StringName("drink_" + drink_id), strength)

func _exit_tree() -> void:
	for player: AudioStreamPlayer in players.values():
		player.stop()
		player.stream = null
	players.clear()
	_remaining.clear()
