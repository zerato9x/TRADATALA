extends SceneTree

var failures: Array[String] = []
var checks := 0


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	# Exercise the actual campaign bindings, not just a detached panel rebuild.
	Engine.time_scale = 30.0
	var scene := load("res://scenes/match.tscn").instantiate() as MatchUI
	root.add_child(scene)
	current_scene = scene
	await process_frame
	await scene._on_play_pressed()
	scene.campaign._enter_phase(CampaignManager.CampaignPhase.MORNING_EVENT)
	scene.event_table.focus_npc(EventTableController.NPC_THAY_BOI)
	await create_timer(0.5).timeout
	var panel := scene.campaign_participants.get_child(0) as GieoQuePanel
	_check(panel != null, "campaign opens Gieo panel")
	var service := panel.service
	var npc := scene.event_table.get_node("ThayBoiFocused") as Control
	var npc_viewport := Rect2(Vector2.ZERO, Vector2(1280, 720))
	var npc_layout_wait_frames := 0
	while not npc_viewport.encloses(npc.get_global_rect()) and npc_layout_wait_frames < 60:
		await process_frame
		npc_layout_wait_frames += 1
	_check(npc_viewport.encloses(npc.get_global_rect()), "fortune teller fits inside campaign viewport; rect=%s" % npc.get_global_rect())
	for frame in range(8):
		panel._set_lever_frame(frame)
		var atlas := panel._lever_image.texture as AtlasTexture
		_check(Rect2(Vector2.ZERO, atlas.atlas.get_size()).encloses(atlas.region), "lever frame %d stays inside atlas" % frame)
	service.wallet.reset(1_000_000)
	panel._lever_button.pressed.emit()
	_check(panel._busy and scene.event_table.back_button.disabled, "pull locks campaign navigation immediately")
	panel._on_cast_pressed(false)
	_check(service.paid_cast_count_today == 0, "double pull cannot charge twice")
	await _wait_idle(panel)
	_check(panel.presentation_state == GieoQuePanel.PresentationState.SHOWING_RESULT, "full lever and both trigram animations finish")
	_check(panel.displayed_reel_values() == service.current_result["lines"], "six rendered lines match charged result")
	_check(panel._decision_row.is_visible_in_tree(), "decisions become visible after reveal")
	await panel._on_cast_pressed(true)
	_check(service.paid_cast_count_today == 1 and service.wallet.balance_vnd == 990_000, "animated reroll charges once")
	panel._on_refuse_pressed()
	_check(not scene.event_table.back_button.disabled, "refuse unlocks campaign Back")
	panel.hide()
	var accept := InputEventAction.new()
	accept.action = "ui_accept"
	accept.pressed = true
	panel._unhandled_input(accept)
	_check(service.state == GieoQueService.STATE_READY, "hidden screen cannot cast with keyboard")
	panel.show()
	# Every effect and targeting composition, including both jackpots.
	for bits in range(64):
		service.reset_campaign()
		var lines: Array[String] = []
		for bit in range(6):
			lines.append("D" if bits & (1 << bit) else "A")
		service.cast(lines)
		panel._rebuild()
		await panel._on_accept_pressed()
		if service.state == GieoQueService.STATE_DESTINATION_SELECTION:
			var rank: bool = String(service.current_result.get("jackpot", "")) == GieoQueService.JACKPOT_THUAN_DUONG or service.current_result["effect"] == GieoQueService.EFFECT_CHOOSE_RANK
			await panel._on_destination_pressed("K" if rank else "Hearts")
		if service.state == GieoQueService.STATE_TARGET_SELECTION:
			var cards: Array[CardData] = service.resolved_targets if not service.resolved_targets.is_empty() else service.persistent_deck
			await panel._on_target_pressed(cards[0].unique_id)
		_check(service.state == GieoQueService.STATE_COMPLETE and not panel.is_interaction_locked(), "composition %d completes and unlocks" % bits)
		_check(not scene.event_table.back_button.disabled, "composition %d releases campaign Back" % bits)
		_check(service.last_transformations.size() >= 1 and service.persistent_deck.size() == 52, "composition %d preserves physical deck" % bits)
		var rows := panel._find_controls_with_meta(panel, &"gieo_transform_row")
		_check(rows.size() == service.last_transformations.size(), "composition %d keeps final card changes inspectable" % bits)
		for row in rows:
			_check((row.get_meta("after_card") as Control).modulate.a == 1.0, "final transformed card is visible")
	service.wallet.reset(0)
	panel._rebuild()
	_check(not service.can_afford_pull(), "paid pull unavailable with empty wallet")
	scene.event_table.unfocus_npc()
	await process_frame
	_check(scene.event_table.continue_button.visible, "leaving restores campaign Continue")
	Engine.time_scale = 1.0
	scene.queue_free()
	await process_frame
	print("GIEO_QUE_SCREEN_SMOKE checks=%d failures=%d" % [checks, failures.size()])
	for failure in failures:
		printerr("FAIL: " + failure)
	quit(0 if failures.is_empty() else 1)


func _wait_idle(panel: GieoQuePanel) -> void:
	var deadline := Time.get_ticks_msec() + 15_000
	while panel._busy and Time.get_ticks_msec() < deadline:
		await process_frame
	_check(not panel._busy, "animation finishes before watchdog")


func _check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures.append(message)
