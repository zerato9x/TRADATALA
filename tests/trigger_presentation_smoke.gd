extends SceneTree

var failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var scene := (load("res://scenes/match.tscn") as PackedScene).instantiate() as MatchUI
	root.add_child(scene)
	current_scene = scene
	await process_frame
	scene.game_started = true
	scene.game_layer.position = Vector2.ZERO
	scene.menu_layer.hide()
	scene.deal.start_tutorial_deal()
	scene.interaction_locked = false
	var cards: Array[CardData] = []
	for suit in ["Clubs", "Hearts", "Spades"]:
		cards.append(CardData.new("receipt_" + suit, "K", 13, suit, 13))
	cards[0].add_gieo_property(GieoQueService.PROPERTY_MAKING_PHOM_RETRIGGER)
	cards[0].add_gieo_property(GieoQueService.PROPERTY_SET_RETRIGGER)
	scene.deal.melds.append(MeldState.new(81, MeldRules.TYPE_SET, cards))
	scene._sync_all()
	await process_frame
	var context := scene.deal.scoring.preview_new_meld(cards, MeldRules.TYPE_SET, 1)
	var wallet_before := scene.deal.wallet.balance_vnd
	var started := Time.get_ticks_msec()
	scene._queue_scoring(context, scene.meld_views[81])
	await process_frame
	_check(not scene.interaction_locked, "receipt does not lock input")
	_check(scene.money_presentation.presentation_active, "receipt starts")
	var triggered_face: Control = scene.meld_views[81].get_scoring_card_control(cards[0].unique_id)
	await create_timer(0.03).timeout
	_check(absf(triggered_face.rotation) > 0.01, "physical scoring card visibly shakes")
	_check(is_zero_approx(scene.money_presentation._scoring_face.rotation), "receipt remains still when the table card shakes")
	var next_face: Control = scene.meld_views[81].get_scoring_card_control(cards[1].unique_id)
	_check(is_zero_approx(next_face.rotation), "other cards stay still until their trigger")
	_check(scene.money_presentation.line_b_label.scale == Vector2.ONE * 0.78, "score text stays steady during the card shake")
	for label: Label in [scene.money_presentation.title_label, scene.money_presentation.line_a_label, scene.money_presentation.line_b_label, scene.money_presentation.payout_label]:
		_check(label.mouse_filter == Control.MOUSE_FILTER_IGNORE, "receipt label ignores pointer input")
	await _drain(scene)
	_check(Time.get_ticks_msec() - started < 4500, "small echo receipt stays brisk")
	_check(absf(triggered_face.rotation) < 0.001, "card shake restores original rotation")
	_check(scene.money_presentation._scoring_shakes.is_empty(), "completed shakes leave no stale state")
	_check(scene.deal.wallet.balance_vnd == wallet_before, "presentation never pays the wallet")
	_check(scene.displayed_wallet_vnd == scene.money_queue_wallet_vnd, "display converges to receipt total")
	# Exiting a tutorial during a receipt must not resurrect its wallet number.
	scene._queue_scoring(context, scene.meld_views[81])
	await process_frame
	scene.money_presentation.hide_ceremony()
	scene._reset_tutorial_ui_state()
	scene.displayed_wallet_vnd = 123000
	scene.money_queue_wallet_vnd = 123000
	scene.money_presentation.sync_wallet(123000)
	await create_timer(0.6).timeout
	_check(scene.displayed_wallet_vnd == 123000, "cancelled queue cannot overwrite new balance")
	_check(not scene.money_presentation.presentation_active, "cancelled receipt stays stopped")
	# Run a fresh receipt immediately after cancellation, with the proper layout.
	scene._queue_scoring(context, scene.meld_views[81])
	await _drain(scene)
	_check(scene.money_presentation.line_a_label.position == Vector2(10, 31), "receipt restores shared layout")
	var visual := scene._capture_exhaustion_visual(scene.deal.melds[-1], scene.meld_views[81])
	var exhaustion := scene.deal.scoring.score_meld_trigger(cards, MeldRules.TYPE_SET, 1)
	scene.deal.melds.clear()
	scene._sync_melds()
	await process_frame
	scene._queue_scoring(exhaustion, visual["anchor"], visual)
	await _drain(scene)
	_check(not is_instance_valid(visual["anchor"]), "exhaustion releases its snapshot anchor")
	for card in visual["cards"]:
		_check(not is_instance_valid(card), "exhaustion returns and releases every ghost")
	_check(scene.money_presentation.peak_transaction_object_count <= 8, "bill population stays capped")
	_check(scene.deal.wallet.balance_vnd == wallet_before, "exhaustion presentation does not pay twice")
	var full_run: Array[CardData] = []
	for rank_index in DeckManager.RANKS.size():
		full_run.append(CardData.new("perfected_visual_%d" % rank_index, DeckManager.RANKS[rank_index], rank_index + 1, DeckManager.SUITS[rank_index % 4], rank_index + 1))
	var complete_meld := MeldState.new(99, MeldRules.TYPE_RUN, full_run)
	complete_meld.run_compatibility = "any"
	scene.deal.melds.append(complete_meld)
	scene._sync_all()
	await process_frame
	var completed_extension := scene.deal.scoring.preview_extension(full_run, MeldRules.TYPE_RUN, 936, 1, [full_run[-1]])
	scene._queue_scoring(completed_extension, scene.meld_views[99])
	var replay_seen := false
	var deadline := Time.get_ticks_msec() + 10000
	while scene.money_queue_running and Time.get_ticks_msec() < deadline:
		if scene.money_presentation.title_label.text.ends_with("2"):
			replay_seen = true
		await process_frame
	_check(replay_seen, "completed mixed-suit RUN visibly plays its second scoring pass")
	_check(not scene.money_queue_running, "perfected RUN replay completes")
	_check(scene.deal.wallet.balance_vnd == wallet_before, "perfected RUN presentation does not pay twice")
	scene.music_controller._stop_all_mix_players()
	scene.music_controller.music_director.stop()
	await create_timer(0.2).timeout
	scene.queue_free()
	await process_frame
	print("TRADATALA_TRIGGER_PRESENTATION_SMOKE %s" % ("passed" if failures.is_empty() else "FAILED"))
	for failure in failures:
		print("FAIL: " + failure)
	quit(0 if failures.is_empty() else 1)


func _drain(scene: MatchUI) -> void:
	var deadline := Time.get_ticks_msec() + 7000
	while scene.money_queue_running and Time.get_ticks_msec() < deadline:
		await process_frame
	_check(not scene.money_queue_running, "receipt queue drains within deadline")


func _check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
