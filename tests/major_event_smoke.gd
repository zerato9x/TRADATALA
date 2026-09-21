extends SceneTree

var failures: Array[String] = []

func _initialize() -> void:
	call_deferred("_run")

func check(ok: bool, message: String) -> void:
	if not ok:
		failures.append(message)

func _run() -> void:
	var scene := (load("res://scenes/match.tscn") as PackedScene).instantiate() as MatchUI
	root.add_child(scene)
	current_scene = scene
	await process_frame
	scene.game_started = true
	scene.game_layer.position = Vector2.ZERO
	scene.menu_layer.hide()
	scene.deal.start_tutorial_deal()
	scene._sync_all()
	var presenter := scene.money_presentation
	var balance := scene.deal.wallet.balance_vnd
	for reason in ["u", "u_khan", "exhaustion"]:
		var event := {"reason": reason, "title": {"u": "Ù!", "u_khan": "Ù KHAN!", "exhaustion": "EXHAUSTION"}[reason],
			"steps": ["VNĐ120.000", "×2"] if reason == "u" else (["12", "×10"] if reason == "u_khan" else ["Cash out table melds"]),
			"payout": "+VNĐ120.000", "amount_vnd": 120000,
			"start_wallet_vnd": 120000, "target_wallet_vnd": 240000}
		var sound_count := int(scene.ui_feedback.play_counts.get(&"jackpot", 0))
		presenter.present_transaction(event)
		await create_timer(0.65).timeout
		check(presenter.presentation_active, reason + " is active")
		check(int(scene.ui_feedback.play_counts.get(&"jackpot", 0)) == sound_count + 1, reason + " plays jackpot once")
		check(presenter.bill_layer.get_child_count() == 36, reason + " has bounded bill burst")
		check(presenter.payout_label.modulate.a == 1.0, reason + " payout visible")
		check(presenter.score_panel.position.distance_to((presenter.size - presenter.score_panel.size) * 0.5) < 1, reason + " is centered")
		if "--capture" in OS.get_cmdline_user_args():
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png("res://.godot/major_event_" + reason + ".png")
		while presenter.presentation_active:
			await process_frame
		check(presenter.wallet_label.text == VndWallet.format_amount(240000), reason + " wallet display reaches target")
		check(scene.deal.wallet.balance_vnd == balance, reason + " does not pay twice")
		check(presenter._major_nodes.is_empty(), reason + " cleanup")
	# Exercise real exhaustion signal aggregation, scoring totals and ghost recycling.
	var cards: Array[CardData] = []
	for suit in ["Hearts", "Clubs", "Spades"]:
		cards.append(CardData.new("major_" + suit, "K", 13, suit, 13))
	scene.deal.melds.append(MeldState.new(818, MeldRules.TYPE_SET, cards))
	scene._sync_all()
	var wallet_before := scene.deal.wallet.balance_vnd
	scene.money_queue_wallet_vnd = wallet_before
	scene.deal._resolve_exhaustion(1, 0)
	var wallet_after := scene.deal.wallet.balance_vnd
	scene._sync_all()
	scene._drain_pending_exhaustion_presentations()
	while scene.money_queue_running:
		await process_frame
	check(wallet_after > wallet_before, "exhaustion actually paid meld income")
	check(scene.displayed_wallet_vnd == wallet_after, "exhaustion queue matches paid authority")
	check(scene.deal.wallet.balance_vnd == wallet_after, "exhaustion queue never pays twice")
	check(scene.pending_exhaustion_presentations.is_empty(), "exhaustion queue drained")
	presenter.present_transaction({"reason": "u", "title": "Ù!", "amount_vnd": 100000, "target_wallet_vnd": 999000})
	await create_timer(0.2).timeout
	presenter.hide_ceremony()
	presenter.sync_wallet(123000)
	await create_timer(2.5).timeout
	check(presenter.wallet_label.text == VndWallet.format_amount(123000), "cancel cannot overwrite restored wallet")
	check(not presenter.presentation_active, "cancel stays stopped")
	check(not scene.ui_feedback.players[&"jackpot"].playing, "cancel stops jackpot cue")
	print("MAJOR_EVENT_SMOKE: " + ("PASS" if failures.is_empty() else str(failures)))
	scene.queue_free()
	await create_timer(0.2).timeout
	quit(0 if failures.is_empty() else 1)
