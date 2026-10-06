class_name MatchMusic
extends Node
## Owns music policy and transport checkpoints for one match scene.

signal changed()
signal checkpoint_changed()
signal notice(english: String, vietnamese: String)

const CONDUCTOR := preload("res://scripts/audio/gameplay_music_conductor.gd")

var controller: ReactiveMusicController
var conductor: GameplayMusicConductor
var settings
var _campaign: WeakRef
var _deal: WeakRef
var _game_started: Callable


func configure(game_settings: Node, transport: ReactiveMusicController,
		campaign: CampaignManager, deal: DealState, game_started: Callable) -> void:
	settings = game_settings
	controller = transport
	conductor = CONDUCTOR.new(controller)
	_campaign = weakref(campaign)
	_deal = weakref(deal)
	_game_started = game_started
	controller.mix_started.connect(func(_path, _theme, _variant): _transport_changed())
	controller.pause_changed.connect(func(_paused): _transport_changed())
	controller.playback_options_changed.connect(_transport_changed)
	controller.music_director.state_changed.connect(func(_state): checkpoint_changed.emit())
	controller.music_director.cue_held.connect(func(_track, _cue): checkpoint_changed.emit())
	controller.anti_fatigue.state_changed.connect(func(_state): checkpoint_changed.emit())
	campaign.campaign_started.connect(_on_campaign_started)
	campaign.day_started.connect(_on_day_started)
	deal.new_phom_scored.connect(_on_new_phom)


func initialize_jukebox() -> void:
	if not _game_started.call() and settings.music_system == settings.MUSIC_SYSTEM_AUTHORED_DJ and not controller.dj_mode:
		if not _activate_authored_set():
			settings.set_music_system(settings.MUSIC_SYSTEM_PLAYING_TRACKS)
	changed.emit()


func select_track(index: int) -> void:
	if settings.music_system == settings.MUSIC_SYSTEM_AUTHORED_DJ:
		select_authored_set(index)
		return
	conductor.stop_campaign()
	controller.play_track(index)


func select_system(index: int) -> void:
	if index < 0 or index >= settings.SUPPORTED_MUSIC_SYSTEMS.size():
		return
	var previous_system: String = settings.music_system
	settings.set_music_system(settings.SUPPORTED_MUSIC_SYSTEMS[index])
	if settings.music_system == settings.MUSIC_SYSTEM_PLAYING_TRACKS and controller.dj_mode:
		conductor.stop_campaign()
		controller.play_track(controller.current_track_index, false)
	elif settings.music_system == settings.MUSIC_SYSTEM_AUTHORED_DJ and not controller.dj_mode:
		if not _activate_authored_set():
			settings.set_music_system(previous_system)
	_transport_changed()


func select_authored_set(index: int) -> void:
	if index < 0 or index >= settings.SUPPORTED_AUTHORED_SETS.size():
		return
	var previous_set: String = settings.authored_music_set
	settings.set_authored_music_set(settings.SUPPORTED_AUTHORED_SETS[index])
	if settings.music_system == settings.MUSIC_SYSTEM_AUTHORED_DJ \
			and (not controller.dj_mode or conductor.active_set_id != settings.authored_music_set):
		if not _activate_authored_set():
			settings.set_authored_music_set(previous_set)
	_transport_changed()


func _activate_authored_set() -> bool:
	var campaign := _campaign.get_ref() as CampaignManager
	var deal := _deal.get_ref() as DealState
	var period := "starter_event"
	if _game_started.call() and not campaign.run_seed.is_empty():
		period = String(CampaignManager.DEAL_PHASE_TO_PERIOD.get(campaign.current_phase, ""))
		if period.is_empty():
			match campaign.current_phase:
				CampaignManager.CampaignPhase.DAY_START, CampaignManager.CampaignPhase.STARTER_EVENT: period = "starter_event"
				CampaignManager.CampaignPhase.MORNING_EVENT: period = "morning_event"
				CampaignManager.CampaignPhase.NOON_EVENT: period = "noon_event"
				CampaignManager.CampaignPhase.AFTERNOON_EVENT: period = "afternoon_event"
				_: period = "collection"
	var previous_transport := controller.snapshot_state()
	var next_conductor := CONDUCTOR.new(controller)
	if not next_conductor.start_at_state(settings.authored_music_set, period, deal.current_phase,
			deal.phase_new_meld_count, deal.state == DealState.STATE_DEAL_OVER):
		controller.restore_snapshot(previous_transport)
		notice.emit("Could not start DJ set: " + next_conductor.last_error, "Không thể bắt đầu DJ set: " + next_conductor.last_error)
		return false
	conductor = next_conductor
	return true


func snapshot() -> Dictionary:
	return {"system": settings.music_system, "set": settings.authored_music_set,
		"controller": controller.snapshot_state(), "conductor": conductor.snapshot_state()}


func restore(data: Variant) -> void:
	# Resume must preserve saved transport rather than infer a cue from gameplay.
	if data is Dictionary and data.get("controller") is Dictionary and data.get("conductor") is Dictionary:
		var system := String(data.get("system", ""))
		if system in settings.SUPPORTED_MUSIC_SYSTEMS \
				and controller.restore_snapshot(data.controller) \
				and conductor.restore_snapshot(data.conductor):
			settings.set_music_system(settings.MUSIC_SYSTEM_AUTHORED_DJ if controller.dj_mode else settings.MUSIC_SYSTEM_PLAYING_TRACKS)
			settings.set_authored_music_set(String(data.conductor.get("set", "")) if conductor.active else String(data.get("set", settings.authored_music_set)))
			changed.emit()
			return
	conductor.stop_campaign()
	settings.set_music_system(settings.MUSIC_SYSTEM_PLAYING_TRACKS)
	controller.play_track(controller.current_track_index, false)
	changed.emit()
	notice.emit("This save has no usable music checkpoint. Playlist continues; choose a DJ set to start one.",
		"Bản lưu không có trạng thái nhạc hợp lệ. Tiếp tục danh sách; chọn DJ set để bắt đầu.")


func _on_campaign_started() -> void:
	if settings.music_system != settings.MUSIC_SYSTEM_AUTHORED_DJ:
		conductor.stop_campaign()
		if controller.dj_mode:
			controller.play_track(controller.current_track_index, false)
	changed.emit()


func _on_day_started(_day: Dictionary) -> void:
	if settings.music_system == settings.MUSIC_SYSTEM_AUTHORED_DJ:
		conductor.start_campaign(settings.authored_music_set)
	changed.emit()


func _on_new_phom(_context: ScoringContext) -> void:
	var deal := _deal.get_ref() as DealState
	conductor.on_new_phom(deal.current_phase, deal.phase_new_meld_count)


func _transport_changed() -> void:
	changed.emit()
	checkpoint_changed.emit()
