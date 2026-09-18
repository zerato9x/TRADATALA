extends SceneTree

var failures: Array[String] = []
var scene: MatchUI

func _initialize() -> void:
	call_deferred("_run")

func _check(value: bool, message: String) -> void:
	if not value:
		failures.append(message)

func _pause(seconds: float) -> void:
	var deadline := Time.get_ticks_msec() + int(seconds * 1000)
	while Time.get_ticks_msec() < deadline:
		await process_frame

func _click(button: Button) -> void:
	var parent := button.get_parent()
	while parent != null:
		if parent is ScrollContainer:
			parent.ensure_control_visible(button)
			await _pause(0.08)
			break
		parent = parent.get_parent()
	var point := button.get_global_transform_with_canvas() * (button.size * 0.5)
	var motion := InputEventMouseMotion.new()
	motion.position = point
	root.push_input(motion, true)
	for down in [true, false]:
		var event := InputEventMouseButton.new()
		event.position = point
		event.button_index = MOUSE_BUTTON_LEFT
		event.pressed = down
		root.push_input(event, true)
	await process_frame

func _capture(file: String) -> void:
	if DisplayServer.get_name() == "headless":
		return
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://.godot/" + file)

func _run() -> void:
	scene = load("res://scenes/match.tscn").instantiate()
	root.add_child(scene)
	current_scene = scene
	await _pause(0.15)
	var title := scene.get_node_or_null("TitleScreen")
	if title != null:
		title.queue_free()
	scene.drink_manager.progress.save_path = ""
	await scene._on_play_pressed()
	scene.event_table.enter_deal()
	await _pause(0.7)
	# This smoke exercises equipment and scoring with a pre-owned collection.
	for id: String in RelicCatalog.DEFINITIONS:
		scene.deal.relics.acquire(id)
	scene.campaign._enter_phase(CampaignManager.CampaignPhase.MORNING_EVENT)
	await _pause(0.7)
	scene.event_table.focus_npc("hang_rong")
	await _pause(0.7)
	var panel := scene.campaign_participants.get_node_or_null("RelicSelector") as RelicSelector
	_check(panel != null and panel.is_visible_in_tree(), "Hàng Rong opens a visible selector")
	if panel == null:
		_finish()
		return
	_check(panel.buttons.size() == 10, "all ten owned relics available")
	var scroll := panel.get_child(3) as ScrollContainer
	for id: String in panel.buttons:
		scroll.ensure_control_visible(panel.buttons[id])
		await _pause(0.08)
		await _click(panel.buttons[id])
		_check(scene.deal.relics.equipped.has(id), id + " pointer equip")
		await _click(panel.buttons[id])
		_check(not scene.deal.relics.equipped.has(id), id + " pointer remove")
	scroll.scroll_vertical = 0
	await _pause(0.08)
	await _click(panel.buttons["hair_clip"])
	_check(scene.deal.relics.equipped.has("hair_clip"), "hair clip pointer equip")
	await _click(panel.buttons["comb"])
	_check(scene.deal.relics.equipped.has("comb"), "comb pointer equip")
	await _click(panel.buttons["rubber_band"])
	_check(scene.deal.relics.equipped.has("rubber_band"), "rubber band pointer equip")
	await _click(panel.buttons["chewing_gum"])
	_check(scene.deal.relics.equipped.has("chewing_gum"), "gum pointer equip")
	_check(panel.buttons["lipstick"].disabled, "fifth relic requires removing one")
	await _capture("relic_selector.png")
	await _click(panel.buttons["comb"])
	_check(not scene.deal.relics.equipped.has("comb"), "pointer remove frees slot")
	await _click(panel.buttons["comb"])
	_check(scene.deal.relics.equipped.has("comb"), "pointer re-equip")
	scene.deal.relics.reset_run()
	for id in ["hair_clip", "sunflower_seeds", "hard_candy", "buttons"]:
		scene.deal.relics.acquire(id)
		scene.deal.relics.equip(id)
	scene._on_campaign_deal_requested(scene.campaign.current_day(), "morning", DrinkCatalog.NONE)
	await _pause(0.8)
	var cards: Array[CardData] = []
	for i in 4:
		cards.append(CardData.new("relic_visual_%d" % i, "9", 9, "Spades", 9))
	scene.deal.hand.assign(cards)
	scene.deal.hand.append(CardData.new("spare", "K", 13, "Hearts", 13))
	var result := scene.deal.create_meld(cards)
	_check(result.ok, "test meld committed")
	scene._sync_all(result)
	_check(scene.relic_grid.get_child_count() == 4, "four HUD slots")
	for slot: RelicSlot in scene.relic_grid.get_children():
		_check(not slot.tooltip_text.is_empty(), "equipped relic tooltip")
	var job_id := scene._queue_scoring(result.context)
	var job: Dictionary = scene.money_jobs.back()
	var hits: Array = job.event.hits
	var relic_count := 0
	var saw_relic := false
	for hit: Dictionary in hits:
		if hit.kind == "relic":
			saw_relic = true
			relic_count += 1
		else:
			_check(not saw_relic, "all normal scoring precedes relic receipts")
	_check(relic_count == 4, "four queued relic receipts")
	var wallet_after_commit := scene.deal.wallet.balance_vnd
	var pulsed: Dictionary = {}
	var deadline := Time.get_ticks_msec() + 16000
	var captured := false
	while not scene.completed_money_jobs.has(job_id) and Time.get_ticks_msec() < deadline:
		for slot: RelicSlot in scene.relic_grid.get_children():
			if slot.outline.cue_mode() == CardActionOutline.CUE_DRINK:
				pulsed[slot.relic_id] = true
				if not captured:
					captured = true
					await _capture("relic_trigger.png")
		await process_frame
	_check(scene.completed_money_jobs.has(job_id), "money playback completes")
	_check(pulsed.size() == 4, "every triggering relic receives the shared outline cue")
	_check(scene.deal.wallet.balance_vnd == wallet_after_commit, "presentation never changes wallet authority")
	_check(scene.displayed_wallet_vnd == wallet_after_commit, "displayed wallet reconciles all relic payouts")
	await _capture("relic_hud.png")
	scene.queue_free()
	await process_frame
	_finish()

func _finish() -> void:
	for failure in failures:
		print("RELIC_SMOKE_FAIL: " + failure)
	print("TRADATALA_RELIC_SMOKE " + ("passed" if failures.is_empty() else "failed"))
	quit(0 if failures.is_empty() else 1)
