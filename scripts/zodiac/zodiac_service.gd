class_name ZodiacService
extends RefCounted
## Campaign-owned negotiation/progression. UI passes intentions, never costs or outcomes.
signal changed()
var progress := ZodiacProgress.new("")
var daily: Dictionary = {}
var forced: Dictionary = {}
var run_id := ""
var _campaign_ref: WeakRef
var campaign: RefCounted:
	get: return _campaign_ref.get_ref() if _campaign_ref != null else null
var deal: DealState
var _committing := false

func bind(owner_campaign: RefCounted, owner_deal: DealState) -> void:
	_campaign_ref = weakref(owner_campaign)
	deal = owner_deal
	if not deal.state_changed.is_connected(_observe_action): deal.state_changed.connect(_observe_action)
	if not deal.wallet.balance_changed.is_connected(_observe_wallet): deal.wallet.balance_changed.connect(_observe_wallet)

func reset_run() -> void:
	daily.clear()
	run_id = "%s:%s" % [Time.get_unix_time_from_system(), Time.get_ticks_usec()]

func choose_emblem(day: int, id: String) -> bool:
	# A choice is for a future day only; it cannot reroll a day already encountered.
	if campaign != null and not daily.is_empty() and day <= int(daily.day): return false
	if id.is_empty(): forced.erase(day)
	elif progress.owns(id) and id in ZodiacCatalog.pair_for_day(day): forced[day] = id
	else: return false
	changed.emit()
	return true

func prefer_emblem(id: String = "") -> bool:
	if not id.is_empty() and (not ZodiacCatalog.DEFINITIONS.has(id) or not progress.owns(id)): return false
	if id.is_empty(): forced.erase("pair:0")
	else: forced["pair:0"] = id
	changed.emit()
	return true

func begin_day(day: int, seed_value: int) -> void:
	var force: String = forced.get(day, forced.get("pair:%d" % ZodiacCatalog.DAY_PAIRS[posmod(day, ZodiacCatalog.DAY_PAIRS.size())], ""))
	if not progress.owns(force): force = ""
	var id := "" if DemoBuild.enabled() else ZodiacCatalog.select(seed_value, day, force)
	daily = {"day": day, "id": id, "forced": force, "successes": 0, "slot": -1, "requests": {}, "promises": [], "skip_phase": -1, "skipped": [], "boss_finished": false, "last_result": {}}
	if id.is_empty(): return
	# Prerequisites earned today are evaluated on a subsequent encounter only.
	if progress.eligible(id) and not progress.owns(id):
		progress.commit(id, _key("scene_available"), {}, ["special_scene_unlocked"])
	progress.commit(id, _key("encounter"), {"encounters": 1})
	changed.emit()

func active_id() -> String:
	return daily.get("id", "")

func mood() -> String:
	return ZodiacCatalog.disposition(active_id(), int(daily.get("successes", 0))) if not active_id().is_empty() else "UNPLEASED"

func _key(suffix: String) -> String:
	return "%s:%s:%s:%s" % [run_id, daily.get("day", -1), active_id(), suffix]

func enter_event(slot: int) -> void:
	if active_id().is_empty(): return
	daily.slot = slot
	if slot == 3:
		for promise: Dictionary in daily.promises.duplicate():
			if promise.kind == "restraint": _resolve_promise(promise, true)
	if not daily.requests.has(slot):
		daily.requests[slot] = {"status": "offered"}
		progress.commit(active_id(), _key("seen:%d" % slot), {"requests_seen": 1})
	changed.emit()

func request_kind() -> String:
	match int(daily.get("slot", -1)):
		0: return "pay"
		1: return "early_score" if active_id() == "rooster" else "restraint"
		2: return "alter"
		3: return "gift"
	return ""

func quote() -> Dictionary:
	if active_id().is_empty(): return {}
	var kind := request_kind()
	var text := ""
	var speech := ""
	match kind:
		"pay":
			speech = ZodiacCatalog.words("You came early. Sit with me a moment. Can you spare 5,000 VNĐ?", "Đến sớm thế. Ngồi với tôi một lát đi. Có thể để lại 5.000 VNĐ không?") if active_id() == "rooster" else ZodiacCatalog.words("You look worried about that money. If I asked for 5,000 VNĐ, what would you say?", "Nhìn bạn giữ tiền kỹ ghê. Nếu tôi xin 5.000 VNĐ, bạn sẽ nói sao?")
			text = ZodiacCatalog.words("Accept: pay 5,000 VNĐ now. Counteroffer: pay 2,500 VNĐ. Refuse/Bargain: free.", "Đồng ý: trả ngay 5.000 VNĐ. Đề nghị khác: 2.500 VNĐ. Từ chối/Mặc cả: miễn phí.")
		"early_score":
			speech = ZodiacCatalog.words("Next Deal, try making a meld before you throw anything away. Think you can?", "Ván tới, thử hạ một Phỏm trước khi bỏ bài nhé. Làm được không?")
			text = ZodiacCatalog.words("Promise: score a Meld or Extension before the first mandatory discard of the next Deal.", "Cam kết: ghi điểm tạo/nối Phỏm trước lần bỏ bài bắt buộc đầu tiên ở Ván kế.")
		"restraint":
			speech = ZodiacCatalog.words("I want to see if you can keep 5,000 VNĐ untouched until this afternoon.", "Tôi muốn xem bạn có giữ nguyên 5.000 VNĐ đến chiều được không.")
			text = ZodiacCatalog.words("Promise: keep at least 5,000 VNĐ until the Afternoon event. Every wallet change counts, including deadwood.", "Cam kết: luôn giữ ít nhất 5.000 VNĐ tới sự kiện Buổi chiều. Tính mọi thay đổi tiền, kể cả bài rác.")
		"alter":
			speech = ZodiacCatalog.words("Show me a card you've grown fond of. I want to see what you're willing to change.", "Cho tôi xem lá bạn quý nhất đi. Tôi muốn biết bạn dám đổi điều gì.") if active_id() == "rooster" else ZodiacCatalog.words("There must be a card you keep coming back to. Let me see it.", "Chắc có một lá bạn cứ muốn giữ mãi. Cho tôi xem nhé.")
			text = ZodiacCatalog.words("Choose a physical card: remove its last property, reset it, or seal it against transformations for this run. No card leaves the deck.", "Chọn lá bài: bỏ thuộc tính cuối, hoàn nguyên, hoặc khóa biến đổi tới hết lượt chơi. Bộ bài không mất lá nào.")
		"gift":
			speech = ZodiacCatalog.words("Before we play, would you leave me one of your relics? Only if you can part with it.", "Trước khi chơi, bạn tặng tôi một món di vật được không? Nếu bạn thấy tiếc thì thôi.") if active_id() == "rooster" else ZodiacCatalog.words("That relic caught my eye. Would you let me keep it?", "Tôi thích món di vật ấy. Bạn để lại cho tôi được không?")
			text = ZodiacCatalog.words("Gift: the selected owned Relic leaves this run, including its equipped effect. Refusing costs nothing.", "Tặng: mất Di vật đã chọn trong lượt chơi này, kể cả hiệu ứng đang đeo. Từ chối không tốn gì.")
	return {"kind": kind, "speech": speech, "contract": text, "status": daily.requests.get(daily.slot, {}).get("status", "unavailable"), "can_time": int(daily.slot) in [0, 1, 2]}

func respond(response: String, target: String = "", alteration: String = "reset") -> Dictionary:
	if _committing or campaign == null or active_id().is_empty(): return {"ok": false}
	if not CampaignManager.EVENT_PHASE_TO_SLOT.has(campaign.current_phase): return {"ok": false}
	var slot := int(daily.slot)
	if int(CampaignManager.EVENT_PHASE_TO_SLOT[campaign.current_phase]) != slot: return {"ok": false}
	var request: Dictionary = daily.requests.get(slot, {})
	if request.get("status", "") != "offered": return {"ok": false}
	if response not in ["ACCEPT", "REFUSE", "COUNTEROFFER", "BARGAIN", "SPEND_TIME"]: return {"ok": false}
	var kind := request_kind()
	if response == "COUNTEROFFER" and kind != "pay": return {"ok": false}
	var price := 5000 if response == "ACCEPT" and kind == "pay" else 2500 if response == "COUNTEROFFER" else 0
	if price > 0 and campaign.wallet.balance_vnd < price: return {"ok": false, "error": "funds"}
	if response == "SPEND_TIME" and (slot not in [0, 1, 2] or int(daily.skip_phase) != -1): return {"ok": false}
	if response == "ACCEPT" and kind == "restraint" and campaign.wallet.balance_vnd < 5000: return {"ok": false, "error": "funds"}
	var card: CardData
	if response == "ACCEPT" and kind == "alter":
		if campaign.gieo_que.state not in [GieoQueService.STATE_READY, GieoQueService.STATE_COMPLETE]: return {"ok": false}
		for candidate: CardData in campaign.gieo_que.persistent_deck:
			if candidate.unique_id == target: card = candidate
		if card == null or alteration not in ["remove_property", "reset", "seal"]: return {"ok": false}
		if alteration == "remove_property" and card.gieo_properties.is_empty(): return {"ok": false}
		if alteration == "seal" and card.transformation_locked: return {"ok": false}
		if alteration == "reset" and not card.has_permanent_changes(): return {"ok": false}
	if response == "ACCEPT" and kind == "gift" and not campaign.relic_shop.runtime.inventory.has(target): return {"ok": false}
	_committing = true
	request.status = "resolved" # Lock before wallet/inventory signals can re-enter.
	if price > 0: campaign.wallet.apply_vnd(-price, "zodiac_request:" + active_id())
	var counters := {}
	if response == "REFUSE": counters.requests_refused = 1
	if response == "ACCEPT" and kind == "alter": card.alter_for_zodiac(alteration)
	if response == "ACCEPT" and kind == "gift":
		campaign.relic_shop.runtime.gift(target)
		counters.relics_gifted = 1
		if _favorite(target): counters.favorite_relics_gifted = 1
	if response == "SPEND_TIME":
		daily.skip_phase = int(CampaignManager.NEXT_PHASE[campaign.current_phase])
		counters.spend_time_count = 1
	if response == "ACCEPT" and kind in ["early_score", "restraint"]:
		request.status = "promised"
		daily.promises.append({"slot": slot, "kind": kind, "phase": int(CampaignManager.NEXT_PHASE[campaign.current_phase])})
		_committing = false
		changed.emit()
		return {"ok": true, "pending": true}
	var success := _interpret(kind, response)
	var result := _finish_request(slot, success, response, counters)
	_committing = false
	return result

func _interpret(kind: String, response: String) -> bool:
	# Character interpretation stays here; clients never receive this table.
	if response == "BARGAIN": return false
	if response == "SPEND_TIME": return true
	if response == "REFUSE": return kind in ["pay", "alter", "gift"]
	if response == "COUNTEROFFER": return active_id() == "cat"
	if active_id() == "cat" and kind in ["pay", "alter"]: return false
	return true

func _favorite(relic_id: String) -> bool:
	var definition: Dictionary = ZodiacCatalog.DEFINITIONS[active_id()]
	if relic_id in definition.favorites: return true
	for tag in RelicCatalog.flavor_tags(relic_id):
		if tag in definition.favorite_tags: return true
	return false

func _finish_request(slot: int, success: bool, resolution: String, increments: Dictionary = {}) -> Dictionary:
	var request: Dictionary = daily.requests[slot]
	request.status = "success" if success else "failed"
	if success:
		daily.successes += 1
		increments.requests_resolved = 1
		if resolution == "REFUSE": increments.requests_refused_successfully = 1
		if resolution == "COUNTEROFFER": increments.counteroffers_accepted = 1
	else: increments.requests_failed = 1
	var result := {"ok": true, "resolved_successfully": success, "resolution_type": resolution, "memory_tags": [active_id(), request.status, resolution], "counter_increments": increments.duplicate(), "follow_up": ""}
	request.result = result
	daily.last_result = result
	progress.commit(active_id(), _key("request:%d" % slot), increments)
	changed.emit()
	return result

func _resolve_promise(promise: Dictionary, success: bool) -> void:
	daily.promises.erase(promise)
	_finish_request(int(promise.slot), success, "PROMISE_KEPT" if success else "PROMISE_BROKEN", {"restraint_kept" if promise.kind == "restraint" else "early_scores": 1} if success else {})

func _observe_wallet(_previous: int, current: int, _delta: int, _reason: String) -> void:
	if active_id().is_empty(): return
	for promise: Dictionary in daily.promises.duplicate():
		if promise.kind == "restraint" and current < 5000: _resolve_promise(promise, false)

func _observe_action(result: Dictionary) -> void:
	if active_id().is_empty() or campaign == null: return
	for promise: Dictionary in daily.promises.duplicate():
		if promise.kind != "early_score" or int(promise.phase) != campaign.current_phase: continue
		if result.get("action", "") in ["new_meld", "extension"] and deal.discard_count == 0:
			var context: ScoringContext = result.context
			if context.final_points > 0: _resolve_promise(promise, true)
		elif deal.discard_count > 0: _resolve_promise(promise, false)

func consume_skip(phase: int) -> bool:
	if active_id().is_empty() or phase == CampaignManager.CampaignPhase.EVENING_DEAL or int(daily.skip_phase) != phase: return false
	daily.skip_phase = -1
	daily.skipped.append(phase)
	changed.emit()
	return true

func prepare_deal(period: String) -> void:
	if deal == null: return
	deal.zodiac_boss.configure(active_id() if period == "evening" else "", mood(), campaign.seed_for("zodiac_boss", campaign.current_day_index))

func finish_boss() -> void:
	if active_id().is_empty() or daily.boss_finished: return
	if deal == null or deal.state != DealState.STATE_DEAL_OVER or deal.zodiac_boss.id != active_id(): return
	daily.boss_finished = true
	# This solo game's victory contract is completing both Phases of the boss Deal.
	var counters := {mood().to_lower() + "_victories": 1}
	if int(daily.successes) == 4: counters.perfect_request_days = 1
	progress.commit(active_id(), _key("boss"), counters)
	changed.emit()

func complete_scene() -> bool:
	if active_id().is_empty() or not bool(progress.record(active_id()).get("special_scene_unlocked", false)) or progress.owns(active_id()): return false
	progress.commit(active_id(), "emblem:" + active_id(), {}, ["special_scene_completed", "emblem_unlocked"])
	changed.emit()
	return true

func snapshot() -> Dictionary:
	return {"daily": daily.duplicate(true), "forced": forced.duplicate(), "run_id": run_id, "progress": progress.snapshot()}

func restore(data: Dictionary) -> void:
	daily = data.get("daily", {}).duplicate(true)
	forced = data.get("forced", {}).duplicate()
	run_id = data.get("run_id", "")
	progress.merge(data.get("progress", {}))
