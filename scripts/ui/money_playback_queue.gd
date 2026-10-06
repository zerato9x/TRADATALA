class_name MoneyPlaybackQueue
extends Node
## Plays committed receipts. Wallet mutation remains exclusively in gameplay.
signal balance_presented(balance_vnd: int)
signal job_completed(job_id: int)

var displayed_balance := 0
var queued_balance := 0
var running := false
var generation := 0
var next_job_id := 1
var jobs: Array[Dictionary] = []
var completed: Dictionary = {}
var _presentation: MoneyPresentation
var _return_visual: Callable

func configure(presentation: MoneyPresentation, return_visual: Callable) -> void:
	_presentation = presentation
	_return_visual = return_visual

func reserve(amount_vnd: int) -> int:
	var start := queued_balance
	queued_balance += amount_vnd
	return start

func synchronize(balance_vnd: int) -> void:
	displayed_balance = balance_vnd
	queued_balance = balance_vnd
	_presentation.sync_wallet(balance_vnd)
	balance_presented.emit(balance_vnd)

func cancel() -> void:
	generation += 1
	jobs.clear()
	completed.clear()
	running = false
	queued_balance = displayed_balance
	_presentation.reset_fast_forward()

func enqueue(kind: String, event: Dictionary, recycle_visual: Dictionary = {}) -> int:
	queued_balance = int(event.get("target_wallet_vnd", queued_balance))
	var job_id := next_job_id
	next_job_id += 1
	jobs.append({"id": job_id, "kind": kind, "event": event, "recycle_visual": recycle_visual})
	if not running:
		running = true
		_presentation.reset_fast_forward()
		_drain.call_deferred(generation)
	return job_id

func wait_for(job_id: int) -> void:
	var expected_generation := generation
	while not completed.has(job_id) and expected_generation == generation:
		await get_tree().process_frame
	completed.erase(job_id)

func request_fast_forward() -> bool:
	if not running or _presentation.fast_forward_enabled: return false
	_presentation.request_fast_forward()
	return true

func _exit_tree() -> void:
	# Scene teardown invalidates deferred drains without touching exiting controls.
	generation += 1
	jobs.clear()
	completed.clear()
	running = false

func _drain(expected_generation: int) -> void:
	# A cancelled deferred drain must never consume a newer queue.
	if expected_generation != generation: return
	while not jobs.is_empty():
		var job: Dictionary = jobs.pop_front()
		var event: Dictionary = job.event
		match String(job.kind):
			"scoring": await _presentation.present_scoring(event)
			"phase": await _presentation.present_phase(event)
			_: await _presentation.present_transaction(event)
		if expected_generation != generation: return
		displayed_balance = int(event.get("target_wallet_vnd", displayed_balance))
		balance_presented.emit(displayed_balance)
		for visual: Dictionary in event.get("recycle_visuals", []):
			await _return_visual.call(visual)
			if expected_generation != generation: return
		if not job.recycle_visual.is_empty():
			await _return_visual.call(job.recycle_visual)
			if expected_generation != generation: return
		completed[int(job.id)] = true
		job_completed.emit(int(job.id))
	running = false
	_presentation.reset_fast_forward()
