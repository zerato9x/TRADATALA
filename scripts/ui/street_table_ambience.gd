extends ColorRect
## Ambient street light follows campaign time; it never reads or writes game RNG.
var period := -1
var _transition: Tween

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	material = material.duplicate()
	set_process(false)

func sync_phase(phase: int, immediate: bool = false) -> void:
	var next := 0
	match phase:
		CampaignManager.CampaignPhase.NOON_DEAL, CampaignManager.CampaignPhase.NOON_EVENT: next = 1
		CampaignManager.CampaignPhase.AFTERNOON_DEAL, CampaignManager.CampaignPhase.AFTERNOON_EVENT: next = 2
		CampaignManager.CampaignPhase.EVENING_DEAL, CampaignManager.CampaignPhase.DAY_END, CampaignManager.CampaignPhase.MONEY_REQUIREMENT_CHECK, CampaignManager.CampaignPhase.DAY_COMPLETE, CampaignManager.CampaignPhase.CAMPAIGN_VICTORY, CampaignManager.CampaignPhase.CAMPAIGN_FAILURE, CampaignManager.CampaignPhase.ZODIAC_ENDGAME_CHOICE, CampaignManager.CampaignPhase.DRAGON_DEAL: next = 3
	if next == period: return
	var first := period < 0
	period = next
	if _transition != null and _transition.is_valid(): _transition.kill()
	if immediate or first:
		material.set_shader_parameter("time_of_day", float(period))
		return
	_transition = create_tween()
	_transition.tween_property(material, "shader_parameter/time_of_day", float(period), 1.2).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
