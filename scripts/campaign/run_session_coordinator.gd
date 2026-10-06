class_name RunSessionCoordinator
extends Node
## Owns autosave, profile transitions and isolated Boss Lab domain state.
## Presentation is supplied through explicit callbacks; no root-view access.
signal progress_rebound
signal debug_options_changed(options: Dictionary)

var run_save := RunSave.new()
var save_files: MetaSaveFiles
var restoring := false
var debug_active := false
var debug_history: Array = []
var _pending := false
var _accepting_saves := false
var _subscriptions: Array[Dictionary] = []
var _campaign: CampaignManager
var _deal: DealState
var _can_save: Callable
var _music: Callable
var _reset_view: Callable
var _restore_view: Callable
var _inactive_view: Callable
var _error: Callable
var _banner: Callable
var _regular_save: RunSave
var _regular_progress: Dictionary = {}

func configure(campaign: CampaignManager, deal: DealState, files: MetaSaveFiles, can_save: Callable, music: Callable, reset_view: Callable, restore_view: Callable, inactive_view: Callable, error_view: Callable, banner: Callable) -> void:
	_release_observers()
	_accepting_saves = true
	_campaign = campaign
	_deal = deal
	save_files = files
	_can_save = can_save
	_music = music
	_reset_view = reset_view
	_restore_view = restore_view
	_inactive_view = inactive_view
	_error = error_view
	_banner = banner
	_subscribe(campaign.zodiac.changed, queue_save)
	_subscribe(deal.state_changed, func(_result): queue_save())
	_subscribe(deal.wallet.balance_changed, func(_a, _b, _c, _reason): queue_save())
	_subscribe(deal.relics.inventory_changed, queue_save)
	_subscribe(campaign.campaign_phase_changed, func(_phase): queue_save())
	_subscribe(campaign.event_manager.interaction_completed, func(_event, _interaction): queue_save())
	_subscribe(campaign.gieo_que.state_changed, func(_state, _payload): queue_save())
	_subscribe(campaign.relic_shop.changed, queue_save)
	_subscribe(campaign.shoe_shine.changed, queue_save)

func queue_save() -> void:
	if not _accepting_saves or _pending or restoring or not _can_save.call() or _campaign.run_seed.is_empty(): return
	_pending = true
	flush.call_deferred()

func flush() -> void:
	_pending = false
	if not _accepting_saves or restoring or not _can_save.call() or _campaign.run_seed.is_empty(): return
	if save_files != null and not debug_active and not save_files.save():
		_banner.call(_words("Could not save permanent progress: ", "Không thể lưu tiến trình: ") + save_files.error)
	if not run_save.save_run(_campaign, _deal, _music.call()):
		_banner.call(_words("Could not save: ", "Không thể lưu: ") + run_save.error)

func resume(saved: Dictionary) -> bool:
	if saved.is_empty() or bool(saved.get("campaign", {}).get("debug_context", {}).get("active", false)) != debug_active: return false
	restoring = true
	_reset_view.call()
	if not run_save.restore(saved, _campaign, _deal):
		restoring = false
		return false
	_restore_view.call(saved)
	restoring = false
	queue_save()
	return true

func select_profile(slot: int) -> bool:
	if debug_active: return false
	if _can_save.call() and not run_save.save_run(_campaign, _deal, _music.call()): return false
	if not save_files.select(slot, _campaign): return false
	restoring = true
	_reset_view.call()
	_clear_run()
	run_save = RunSave.new(save_files.run_path())
	progress_rebound.emit()
	_inactive_view.call(false)
	restoring = false
	return true

func enter_debug() -> bool:
	if debug_active: return true
	if not BossDebugSession.available(): return false
	if _can_save.call() and not run_save.save_run(_campaign, _deal, _music.call()):
		_error.call(_words("Could not preserve your run: ", "Không thể giữ ván hiện tại: ") + run_save.error)
		return false
	if not save_files.save():
		_error.call(save_files.error)
		return false
	_regular_save = run_save
	var drinks := _campaign.drink_manager
	_regular_progress = {"drinks": drinks.progress, "difficulty": _campaign.difficulty_progress, "zodiac": _campaign.zodiac.progress, "test_drinks": drinks.test_all_drinks_available}
	debug_history.clear()
	# The selected file is authoritative even before Continue.
	var normal := run_save.load_run()
	for report: Dictionary in normal.get("campaign", {}).get("deal_reports", []): debug_history.append_array(report.get("details", {}).get("actions", []))
	save_files.suspended = true
	debug_active = true
	drinks.progress = DrinkProgress.new("")
	for goal: Array in DrinkProgress.GOALS.values():
		if not String(goal[0]).is_empty(): drinks.progress.counters[goal[0]] = int(goal[1])
	drinks.test_all_drinks_available = true
	_campaign.difficulty_progress = preload("res://scripts/campaign/difficulty_progress.gd").new("")
	_campaign.difficulty_progress.unlocked = 28
	_campaign.zodiac.progress = ZodiacProgress.new("")
	run_save = RunSave.new(BossDebugSession.SAVE_PATH)
	return true

func start_debug(options: Dictionary) -> bool:
	if BossDebugSession.normalize(options).is_empty() or not enter_debug(): return false
	restoring = true
	_reset_view.call()
	if not BossDebugSession.prepare(_campaign, _deal, options, debug_history):
		restoring = false
		return false
	debug_options_changed.emit(_campaign.debug_context.options.duplicate(true))
	var snapshot := run_save.capture(_campaign, _deal, true, _music.call())
	restoring = false
	return resume(snapshot)

func resume_debug() -> bool:
	if not BossDebugSession.available(): return false
	var checkpoint := RunSave.new(BossDebugSession.SAVE_PATH)
	var saved := checkpoint.load_run()
	if saved.is_empty() or not bool(saved.campaign.get("debug_context", {}).get("active", false)): return false
	if not enter_debug(): return false
	run_save = checkpoint
	debug_options_changed.emit(saved.campaign.debug_context.options.duplicate(true))
	return resume(saved)

func replay_debug() -> void:
	if debug_active: start_debug(_campaign.debug_context.get("options", {}).duplicate(true))

func leave_debug() -> void:
	if not debug_active: return
	flush()
	restoring = true
	_reset_view.call()
	var drinks := _campaign.drink_manager
	drinks.progress = _regular_progress.drinks
	drinks.test_all_drinks_available = _regular_progress.test_drinks
	_campaign.difficulty_progress = _regular_progress.difficulty
	_campaign.zodiac.progress = _regular_progress.zodiac
	run_save = _regular_save
	_regular_save = null
	_regular_progress.clear()
	debug_active = false
	_clear_run()
	_inactive_view.call(true)
	save_files.suspended = false
	restoring = false

func _clear_run() -> void:
	_campaign.run_seed = ""
	_campaign.current_day_index = -1
	_campaign.debug_context.clear()
	_campaign.zodiac.daily.clear()
	_campaign.zodiac.endgame.clear()

func _words(en: String, vi: String) -> String:
	return vi if TranslationServer.get_locale().begins_with("vi") else en

func _subscribe(event: Signal, reaction: Callable) -> void:
	event.connect(reaction)
	_subscriptions.append({"event": event, "reaction": reaction})

func _release_observers() -> void:
	for subscription in _subscriptions:
		var event: Signal = subscription.event
		if is_instance_valid(event.get_object()) and event.is_connected(subscription.reaction):
			event.disconnect(subscription.reaction)
	_subscriptions.clear()

func _exit_tree() -> void:
	_accepting_saves = false
	_pending = false
	_release_observers()
