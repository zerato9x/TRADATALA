class_name MoneyFeedback
extends Node
## Builds visual receipts from committed scoring and wallet facts.
## Geometry and visual effects are supplied through explicit presentation ports.
var _queue: MoneyPlaybackQueue
var _deal_ref: WeakRef
var _hand_source: Control
var _meld_source: Control
var _wallet_anchor: Control
var _card_locator: Callable
var _reveal_card: Callable
var _relic_cue: Callable
var _rate_cue: Callable
var _suppression: Callable
var _pending_u: Array[Dictionary] = []
var _pending_u_khan: Array[Dictionary] = []
var _pending_exhaustion: Array[Dictionary] = []

func configure(deal: DealState, playback: MoneyPlaybackQueue, hand_source: Control,
		meld_source: Control, wallet_anchor: Control, card_locator: Callable,
		reveal_card: Callable, relic_cue: Callable, rate_cue: Callable, suppression: Callable) -> void:
	_deal_ref = weakref(deal)
	_queue = playback
	_hand_source = hand_source
	_meld_source = meld_source
	_wallet_anchor = wallet_anchor
	_card_locator = card_locator
	_reveal_card = reveal_card
	_relic_cue = relic_cue
	_rate_cue = rate_cue
	_suppression = suppression
	deal.u_triggered.connect(_buffer_u)

func _deal() -> DealState:
	return _deal_ref.get_ref() as DealState

func clear_pending() -> void:
	_pending_u.clear()
	_pending_u_khan.clear()
	_pending_exhaustion.clear()

func buffer_exhaustion(context: ScoringContext, visual: Dictionary) -> void:
	_pending_exhaustion.append({"context": context, "visual": visual})

func ensure_exhaustion() -> void:
	if _pending_exhaustion.is_empty(): _pending_exhaustion.append({})

func has_pending_exhaustion() -> bool:
	return not _pending_exhaustion.is_empty()

func queue_scoring(context: ScoringContext, source_override: Control = null, recycle_visual: Dictionary = {}) -> int:
	if not context.suppression_reason.is_empty():
		_suppression.call(context)
		return queue_zodiac_entries(context.boss_transactions)
	var passes: Array = context.scoring_passes if not context.scoring_passes.is_empty() else [context]
	var gross_multiplier := _deal().gross_payout_multiplier()
	var hits: Array[Dictionary] = []
	var liquid_echo := 0
	for scoring_pass: ScoringContext in passes:
		if scoring_pass.trigger_index > 0:
			if scoring_pass.trigger_origin == ScoringPipeline.TRIGGER_GIEO_RETRIGGER:
				liquid_echo += 1
			var replay: Dictionary = {}
			for source_hit in scoring_pass.presentation_hits:
				if source_hit["card_id"] == scoring_pass.retrigger_source_id:
					replay = source_hit.duplicate(true)
					break
			replay.merge({
				"kind": "meld_retrigger", "card_id": scoring_pass.retrigger_source_id,
				"property": scoring_pass.retrigger_property, "points": 0,
				"pass": scoring_pass.trigger_index + 1, "echo": liquid_echo,
			}, true)
			hits.append(replay)
		for hit in scoring_pass.presentation_hits:
			var receipt := hit.duplicate(true)
			receipt["amount_vnd"] = _points_to_vnd(int(hit["points"]) * gross_multiplier)
			receipt["pass"] = scoring_pass.trigger_index + 1
			receipt["echo"] = liquid_echo
			hits.append(receipt)
	var amount_vnd := _points_to_vnd(context.final_points * gross_multiplier)
	for bonus in context.relic_bonuses:
		var relic_vnd := int(bonus.amount_vnd)
		amount_vnd += relic_vnd
		hits.append({"kind": "relic", "relic_id": bonus.id, "label": bonus.name,
			"action_points": bonus.action_points, "base_rate_vnd": bonus.base_rate_vnd,
			"rate_bonus_vnd": bonus.rate_bonus_vnd, "rate_percent": bonus.rate_percent,
			"amount_vnd": relic_vnd})
	var start_wallet := _queue.reserve(amount_vnd)
	var event := {
		"hits": hits, "amount_vnd": amount_vnd,
		"start_wallet_vnd": start_wallet, "target_wallet_vnd": _queue.queued_balance,
		"source_control": source_override if is_instance_valid(source_override) else _meld_source,
		"card_locator": _card_locator, "reveal_card": _reveal_card,
		"relic_cue": _relic_cue,
		"rate_cue": _rate_cue,
		"base_rate_vnd": _deal().vnd_per_point,
		"title": tr("EXTEND_ACTION") if context.action_type == "extension" else tr("MELD_ACTION"),
	}
	var final_job := _queue.enqueue("scoring", event, recycle_visual)
	var boss_job := queue_zodiac_entries(context.boss_transactions)
	return boss_job if boss_job >= 0 else final_job



func show_phase_resolution(resolution: Dictionary, boss_entries: Array = []) -> void:
	var boss_total := 0
	for entry: Dictionary in boss_entries: boss_total += int(entry.amount_vnd)
	var target_wallet := _deal().wallet.balance_vnd - boss_total
	var event := {
		"phase": int(resolution.get("phase", 1)),
		"title": "%s!" % tr("MOM") if bool(resolution.get("mom", false)) else "P%d" % int(resolution.get("phase", 1)),
		"mom": bool(resolution.get("mom", false)),
		"u": bool(resolution.get("u", false)),
		"raw_gross_vnd": _points_to_vnd(int(resolution.get("raw_gross", 0))),
		"gross_vnd": int(resolution.get("net_vnd", _points_to_vnd(int(resolution.get("net", 0))))) + _points_to_vnd(int(resolution.get("deadwood_points", 0))),
		"deadwood_value_sum": int(resolution.get("deadwood_value_sum", 0)),
		"deadwood_multiplier": int(resolution.get("deadwood_multiplier", 1)),
		"deadwood_vnd": _points_to_vnd(int(resolution.get("turn_deadwood", resolution.get("deadwood_points", 0)))),
		"deadwood_total_vnd": _points_to_vnd(int(resolution.get("deadwood_points", 0))),
		"deadwood_penalty_vnd": _points_to_vnd(int(resolution.get("deadwood_penalty", 0))),
		"black_ink_profit_vnd": _points_to_vnd(int(resolution.get("black_ink_profit", 0))),
		"net_vnd": int(resolution.get("net_vnd", _points_to_vnd(int(resolution.get("net", 0))))),
		"u_bonus_paid_early": bool(resolution.get("u_bonus_paid_early", false)),
		"start_wallet_vnd": _queue.queued_balance,
		"target_wallet_vnd": target_wallet,
		"source_control": _hand_source,
	}
	var job_id := _queue.enqueue("phase", event)
	var boss_job := queue_zodiac_entries(boss_entries)
	await _queue.wait_for(boss_job if boss_job >= 0 else job_id)



func show_turn_deadwood(resolution: Dictionary, boss_entries: Array = []) -> void:
	var penalty := int(resolution.get("deadwood_penalty", maxi(int(resolution.get("deadwood", 0)), 0)))
	var profit := int(resolution.get("black_ink_profit", 0))
	for receipt in [{"points": penalty, "gain": false}, {"points": profit, "gain": true}]:
		var amount_vnd := _points_to_vnd(int(receipt.points))
		if amount_vnd <= 0: continue
		var gain := bool(receipt.gain)
		var start_wallet := _queue.queued_balance
		var target_wallet := start_wallet + (amount_vnd if gain else -amount_vnd)
		var event := {
			"direction": "gain" if gain else "loss", "amount_vnd": amount_vnd,
			"start_wallet_vnd": start_wallet, "target_wallet_vnd": target_wallet,
			"source_control": _hand_source, "destination_control": _wallet_anchor if gain else _hand_source,
			"intensity": 1.05,
			"title": tr("BLACK_INK_PROFIT") if gain else tr("TURN_DEADWOOD_TITLE") % int(resolution.get("turn", _deal().discard_count)),
			"steps": [str(receipt.points)] if gain else [str(int(resolution.get("value_sum", penalty))), "× %d" % maxi(int(resolution.get("multiplier", 1)), 1)],
			"payout": VndWallet.format_vnd(amount_vnd if gain else -amount_vnd, true),
			"reason": "black_ink" if gain else "deadwood",
		}
		_queue.enqueue("transaction", event)
	queue_zodiac_entries(boss_entries)



func _buffer_u(context: Dictionary) -> void:
	var queued := context.duplicate(true)
	if not bool(context.get("u_khan", false)):
		_pending_u.append(queued)
		return
	var amount_vnd := _points_to_vnd(int(context.get("payout", 0)))
	queued["amount_vnd"] = amount_vnd
	queued["target_wallet_vnd"] = _deal().wallet.balance_vnd
	queued["start_wallet_vnd"] = _deal().wallet.balance_vnd - amount_vnd
	_pending_u_khan.append(queued)



func drain_u() -> void:
	var generation := _queue.generation
	while generation == _queue.generation and not _pending_u.is_empty():
		var context: Dictionary = _pending_u.pop_front()
		var amount_vnd := int(context.get("payout_vnd", _points_to_vnd(int(context.get("payout", 0)))))
		var deal_earnings_vnd := int(context.get("deal_earnings_vnd", amount_vnd))
		var start_wallet := _queue.queued_balance
		var target_wallet := start_wallet + amount_vnd
		var event := {
			"direction": "gain",
			"amount_vnd": amount_vnd,
			"start_wallet_vnd": start_wallet,
			"target_wallet_vnd": target_wallet,
			"source_control": _hand_source,
			"destination_control": _wallet_anchor,
			"intensity": 1.8,
			"title": "%s!" % tr("HOW_U_TITLE"),
			"steps": [VndWallet.format_vnd(deal_earnings_vnd, true), "×2"],
			"payout": VndWallet.format_vnd(amount_vnd, true),
			"reason": "u",
		}
		var job_id := _queue.enqueue("transaction", event)
		await _queue.wait_for(job_id)



func drain_u_khan() -> void:
	var generation := _queue.generation
	while generation == _queue.generation and not _pending_u_khan.is_empty():
		var context: Dictionary = _pending_u_khan.pop_front()
		var hand_sum := 0
		for card_value in context.get("hand", []):
			var card := card_value as CardData
			if card != null:
				hand_sum += card.score_value()
		var event := {
			"direction": "gain",
			"amount_vnd": int(context.get("amount_vnd", 0)),
			"start_wallet_vnd": int(context.get("start_wallet_vnd", _queue.displayed_balance)),
			"target_wallet_vnd": int(context.get("target_wallet_vnd", _deal().wallet.balance_vnd)),
			"source_control": _hand_source,
			"destination_control": _wallet_anchor,
			"intensity": 2.0,
			"title": "%s!" % tr("HOW_U_KHAN_TITLE"),
			"steps": [str(hand_sum), "×10" if int(context.get("gross_multiplier", 1)) == 1 else "×10  •  Ù ×2"],
			"payout": VndWallet.format_vnd(int(context.get("amount_vnd", 0)), true),
			"reason": "u_khan",
		}
		var job_id := _queue.enqueue("transaction", event)
		await _queue.wait_for(job_id)



func drain_exhaustion() -> void:
	if _pending_exhaustion.is_empty():
		return
	var amount := 0
	var visuals: Array[Dictionary] = []
	while not _pending_exhaustion.is_empty():
		var pending: Dictionary = _pending_exhaustion.pop_front()
		var context := pending.get("context") as ScoringContext
		if context != null:
			amount += _points_to_vnd(context.final_points)
		visuals.append(pending.get("visual", {}))
	var start := _queue.reserve(amount)
	_queue.enqueue("transaction", {
		"reason": "exhaustion", "title": tr("MAJOR_EXHAUSTION_TITLE"),
		"amount_vnd": amount, "start_wallet_vnd": start,
		"target_wallet_vnd": _queue.queued_balance,
		"steps": [tr("MAJOR_EXHAUSTION_BODY")],
		"payout": VndWallet.format_vnd(amount, true),
		"recycle_visuals": visuals,
	})




func queue_zodiac_entries(entries: Array) -> int:
	var last_job := -1
	for entry: Dictionary in entries:
		var amount := int(entry.amount_vnd)
		var start := _queue.reserve(amount)
		last_job = _queue.enqueue("transaction", {"reason": "zodiac", "title": ZodiacCatalog.display_name(_deal().zodiac_boss.id),
			"amount_vnd": amount, "start_wallet_vnd": start, "target_wallet_vnd": _queue.queued_balance,
			"steps": [ZodiacCatalog.skill_name(_deal().zodiac_boss.id, _deal().zodiac_boss.difficulty)], "payout": VndWallet.format_vnd(amount, true)})
	return last_job



func _points_to_vnd(points: int) -> int:
	return VndWallet.points_to_vnd(points, _deal().vnd_per_point)
