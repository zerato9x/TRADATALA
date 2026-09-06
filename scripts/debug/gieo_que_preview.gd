extends Control

@onready var gieo_panel: GieoQuePanel = $GieoQuePanel
@onready var wallet_label: Label = $EventHeader/Wallet
@onready var status_label: Label = $PreviewStatus

var service: GieoQueService


func _ready() -> void:
	service = GieoQueService.new()
	service.wallet.reset(355_000)
	gieo_panel.configure(service)
	gieo_panel.wallet_changed.connect(_refresh_wallet)
	gieo_panel.feedback_requested.connect(_show_feedback)
	gieo_panel.commitment_changed.connect(_on_commitment_changed)
	_refresh_wallet()


func _refresh_wallet() -> void:
	wallet_label.text = VndWallet.format_vnd(service.wallet.balance_vnd)


func _show_feedback(message: String) -> void:
	status_label.text = message


func _on_commitment_changed(committed: bool) -> void:
	status_label.text = "ROLL IN PROGRESS" if committed else "CLICK THE LEVER TO TEST"
