extends SceneTree
## Exercise the real money queue, rather than toggling a visibility flag.
var scene: MatchUI
var failures: Array[String] = []
var checks := 0

func _initialize() -> void:
	call_deferred("_run")

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures.append(message)
		push_error(message)

func frames(count: int = 3) -> void:
	for _i in count: await process_frame

func capture(label: String) -> void:
	if DisplayServer.get_name() == "headless": return
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://.godot/boss-money-%s.png" % label)

func _run() -> void:
	root.size = Vector2i(1280, 720)
	scene = load("res://scenes/match.tscn").instantiate() as MatchUI
	root.add_child(scene)
	current_scene = scene
	await frames()
	scene.session.restoring = true
	scene.session.run_save = RunSave.new("user://boss-money-fixture.save")
	scene.drink_manager.progress.save_path = ""
	scene.campaign.zodiac.progress = ZodiacProgress.new("")
	scene.game_started = true
	scene.game_layer.position = Vector2.ZERO
	scene.game_layer.show()
	scene.menu_layer.hide()
	scene.event_table.table_state = EventTableController.TABLE_STATE_DEAL
	scene.event_table._finish_event_exit()
	scene.current_campaign_event = null
	scene.campaign.current_phase = CampaignManager.CampaignPhase.EVENING_DEAL
	scene.deal.start_tutorial_deal()
	scene.deal.zodiac_boss.configure("rooster", 2, 14281)
	scene.deal.zodiac_boss.begin_phase(scene.deal)
	scene.deal.zodiac_boss.begin_turn(1, scene.deal.hand, scene.deal)
	scene.modal_overlay.hide()
	scene.score_overlay.hide()
	scene._sync_all()
	await frames()
	var hud = scene.zodiac_boss_hud
	var opening := scene.deal.wallet.balance_vnd
	var boss_before := scene.deal.zodiac_boss.snapshot()
	for kind in ["scoring", "transaction", "phase"]:
		var event := {"title": "BOSS PRESENCE", "start_wallet_vnd": opening,
			"target_wallet_vnd": opening + 1000, "amount_vnd": 1000,
			"direction": "gain", "steps": ["1", "× 1000"], "payout": "1000 VNĐ",
			"source_control": scene.hand_layer,
			"hits": [{"kind": "card", "label": "CARD", "card_id": scene.deal.hand[0].unique_id,
				"texture_path": scene.deal.hand[0].texture_path(), "amount_vnd": 1000}]}
		scene.money_playback.enqueue(kind, event)
		var deadline := Time.get_ticks_msec() + 3000
		while not scene.money_presentation.presentation_active and Time.get_ticks_msec() < deadline:
			await process_frame
		check(scene.money_presentation.presentation_active and scene.score_overlay.visible, kind + " uses real money ceremony")
		await frames()
		hud.refresh()
		check(not hud.has_node("EveningBossPortrait"), kind + " corner sprite stays removed")
		check(hud.evening_overlay.is_visible_in_tree() and hud.evening_overlay.texture != null, kind + " refresh preserves evening artwork")
		await frames()
		check(hud.evening_overlay.is_visible_in_tree(), kind + " process preserves boss art")
		check(not hud.feedback_panel.visible and not hud.details_panel.visible, kind + " speech and rule drawer stay clear of receipts")
		await capture(kind)
		scene.money_presentation.request_fast_forward()
		while scene.money_playback.running and Time.get_ticks_msec() < deadline:
			await process_frame
		check(not scene.money_playback.running, kind + " queue completes")
		check(scene.money_playback.displayed_balance == opening + 1000, kind + " lands on the displayed wallet target")
		check(hud.evening_overlay.is_visible_in_tree(), kind + " boss remains after money finishes")
	check(scene.deal.wallet.balance_vnd == opening and boss_before == scene.deal.zodiac_boss.snapshot(), "presentation never mutates wallet or boss rules")
	for blocker in [scene.modal_overlay, scene.pile_archive.overlay, scene.deck_screen]:
		blocker.show()
		await frames()
		hud.refresh()
		check(not hud.evening_overlay.visible, blocker.name + " still clears decorative presence")
		blocker.hide()
		await frames()
	check(hud.evening_overlay.is_visible_in_tree(), "return to table restores art")
	scene.queue_free()
	await frames()
	print("BOSS_MONEY_PRESENCE_SMOKE checks=%d failures=%d" % [checks, failures.size()])
	quit(0 if failures.is_empty() else 1)
