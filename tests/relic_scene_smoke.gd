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
	var suffix := "-vi" if OS.get_cmdline_user_args().has("--vietnamese") else "-en"
	root.get_texture().get_image().save_png("res://.godot/" + file.trim_suffix(".png") + suffix + ".png")

func _run() -> void:
	TranslationServer.set_locale("vi" if OS.get_cmdline_user_args().has("--vietnamese") else "en")
	root.size = Vector2i(1280, 720)
	scene = load("res://scenes/match.tscn").instantiate()
	root.add_child(scene)
	current_scene = scene
	await _pause(0.15)
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
	var panel := scene.event_table.participants_container.get_child(0)
	_check(panel.is_visible_in_tree(), "Hang Rong opens a visible table shop")
	_check(scene.deal.relics.equipped.size() == 10, "all ten owned relics are active")
	_check(scene.relic_grid.get_child_count() == 10, "all ten relic icons exist in the right-edge list")
	_check(panel.find_children("Equip_*", "Button", true, false).is_empty(), "shop needs no equipment management")
	_check(scene.relic_grid.columns == 1, "relics use one vertical icon list")
	scene.event_table.unfocus_npc()
	await _pause(0.2)
	_check(scene.event_table.overview.relic_buttons.size() == 10, "every owned relic occupies the event table tray")
	await _capture("relic_selector.png")
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
		_check(slot.tooltip_text.contains("VNĐ/PTS"), "equipped relic tooltip explains rate")
	var job_id := scene.money_feedback.queue_scoring(result.context)
	var job: Dictionary = scene.money_playback.jobs.back()
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
	var shook: Dictionary = {}
	var saw_rate := false
	var saw_rate_receipt := false
	var saw_named_payout := false
	var receipt_above_cards := false
	var captured_receipt := false
	var deadline := Time.get_ticks_msec() + 16000
	var captured := false
	while not scene.money_playback.completed.has(job_id) and Time.get_ticks_msec() < deadline:
		if scene.vnd_per_point_value.text != VndWallet.format_vnd(scene.deal.vnd_per_point):
			saw_rate = true
		if scene.money_presentation.line_a_label.text.contains("VNĐ/PTS"):
			saw_rate_receipt = true
			receipt_above_cards = receipt_above_cards or scene.money_presentation.score_panel.global_position.y < scene.meld_scroll.global_position.y
			for hit: Dictionary in hits:
				if hit.kind == "relic" and scene.money_presentation.line_b_label.text.begins_with(String(hit.label)):
					saw_named_payout = true
			if not captured_receipt:
				captured_receipt = true
				await _capture("relic_rate_receipt.png")
		for slot: RelicSlot in scene.relic_grid.get_children():
			if slot.outline.cue_mode() == CardActionOutline.CUE_DRINK:
				pulsed[slot.relic_id] = true
				if absf(slot.rotation) > 0.001:
					shook[slot.relic_id] = true
				if not captured:
					captured = true
					await _capture("relic_trigger.png")
		await process_frame
	_check(scene.money_playback.completed.has(job_id), "money playback completes")
	_check(pulsed.size() == 4, "every triggering relic receives the shared outline cue")
	_check(shook.size() == 4, "every triggering relic uses the scoring card shake")
	_check(saw_rate, "rate HUD shows an action-only relic boost")
	_check(saw_rate_receipt, "receipt explains VNĐ/PTS boost")
	_check(saw_named_payout, "above-card payout names the triggering relic")
	_check(receipt_above_cards, "relic money receipt stays above the cards")
	_check(scene.vnd_per_point_value.text == VndWallet.format_vnd(scene.deal.vnd_per_point), "rate HUD returns to base after scoring")
	_check(scene.deal.wallet.balance_vnd == wallet_after_commit, "presentation never changes wallet authority")
	_check(scene.money_playback.displayed_balance == wallet_after_commit, "displayed wallet reconciles all relic payouts")
	await _capture("relic_hud.png")
	scene.queue_free()
	await process_frame
	_finish()

func _finish() -> void:
	for failure in failures:
		print("RELIC_SMOKE_FAIL: " + failure)
	print("TRADATALA_RELIC_SMOKE " + ("passed" if failures.is_empty() else "failed"))
	quit(0 if failures.is_empty() else 1)
