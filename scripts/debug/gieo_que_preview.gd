extends Control

@onready var gieo_panel: GieoQuePanel = $GieoQuePanel
@onready var wallet_label: Label = $EventHeader/Wallet
@onready var status_label: Label = $PreviewStatus

var service: GieoQueService
var deck_screen: DeckScreen
var feedback: UIFeedback
var preview_lines: Array[String] = []


func _ready() -> void:
	service = GieoQueService.new()
	service.wallet.reset(355_000)
	gieo_panel.configure(service)
	deck_screen = DeckScreen.new()
	add_child(deck_screen)
	gieo_panel.card_pick_requested.connect(func(cards: Array[CardData], reason: String, callback: Callable): deck_screen.open_deck(service.persistent_deck, "GIEO QUẺ", reason, cards, callback))
	feedback = UIFeedback.new()
	add_child(feedback)
	gieo_panel.impact_requested.connect(_on_impact)
	var presets := OptionButton.new()
	presets.name = "PreviewReading"
	presets.position = Vector2(20, 680)
	presets.size = Vector2(300, 32)
	for label in ["LIVE RNG", "THUẦN DƯƠNG / +3 LIQUID", "THUẦN ÂM / -3 NEGATIVE", "+2 / 3 CONSECUTIVE", "-3 / 1 CARD"]: presets.add_item(label)
	presets.item_selected.connect(func(index: int):
		var patterns := ["", "PPPPPP", "NNNNNN", "PPNPPP", "NNNPPN"]
		preview_lines.clear()
		for line in String(patterns[index]): preview_lines.append(line))
	add_child(presets)
	var cast := Button.new()
	cast.name = "PreviewCast"
	cast.text = "CAST PREVIEW"
	cast.position = Vector2(326,680)
	cast.size = Vector2(162,32)
	cast.pressed.connect(func():
		if service.state in [GieoQueService.STATE_READY, GieoQueService.STATE_RESULT, GieoQueService.STATE_COMPLETE]:
			gieo_panel.cast(service.state == GieoQueService.STATE_RESULT, preview_lines))
	add_child(cast)
	gieo_panel.wallet_changed.connect(_refresh_wallet)
	gieo_panel.feedback_requested.connect(_show_feedback)
	gieo_panel.commitment_changed.connect(_on_commitment_changed)
	_refresh_wallet()


func _on_impact(kind: StringName) -> void:
	match kind:
		&"lever": feedback.play(&"lever")
		&"lever_clunk": feedback.play(&"reels")
		&"result_reveal": feedback.stop(&"reels"); feedback.play(&"gain")
		&"jackpot": feedback.stop(&"reels"); feedback.play(&"jackpot")
		&"transform_card": feedback.play(&"transition")
		&"reel_stop": feedback.play(&"reel_stop")
		_: feedback.play(&"gain")


func _refresh_wallet() -> void:
	wallet_label.text = VndWallet.format_vnd(service.wallet.balance_vnd)


func _show_feedback(message: String) -> void:
	status_label.text = message


func _on_commitment_changed(committed: bool) -> void:
	status_label.text = "READING IN PROGRESS · SPACE TO QUICKEN" if committed else "PULL THE LEVER"
