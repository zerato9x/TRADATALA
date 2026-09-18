extends SceneTree
var failures: Array[String] = []
var checks := 0
func _initialize() -> void:
	call_deferred("_run")
func _check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures.append(message)
		push_error(message)
func _run() -> void:
	var scene := load("res://scenes/match.tscn").instantiate() as MatchUI
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
		cards.append(CardData.new("polish_" + suit, "K", 13, suit, 13))
	scene.deal.melds.append(MeldState.new(812, MeldRules.TYPE_SET, cards))
	scene._sync_all()
	var feedback := scene.ui_feedback
	var receipt := scene.money_presentation
	_check(receipt.impact_requested.is_connected(feedback.money_impact), "payout audio is connected")
	for cue in UIFeedback.CUES:
		var player: AudioStreamPlayer = feedback.players[cue]
		_check(player.stream != null and player.stream.get_length() > 0.0, "valid audio: " + String(cue))
		_check(player.bus == &"Sound" and player.max_polyphony == 1, "bounded Sound routing: " + String(cue))
	feedback.play(&"gain")
	var count := int(feedback.play_counts.get(&"gain", 0))
	for index in range(20):
		feedback.play(&"gain")
	_check(int(feedback.play_counts[&"gain"]) == count, "rapid reward cues are rate limited")
	await create_timer(0.5).timeout
	_check(not (feedback.players[&"gain"] as AudioStreamPlayer).playing, "reward tail stops")
	var button := Button.new()
	button.text = "Feedback test"
	button.position = Vector2(20, 400)
	button.size = Vector2(160, 40)
	scene.add_child(button)
	await process_frame
	await process_frame
	count = int(feedback.play_counts.get(&"press", 0))
	var pointer := button.get_global_transform_with_canvas() * (button.size * 0.5)
	for pressed in [true, false]:
		var click := InputEventMouseButton.new()
		click.button_index = MOUSE_BUTTON_LEFT
		click.position = pointer
		click.pressed = pressed
		root.push_input(click, true)
	_check(int(feedback.play_counts.get(&"press", 0)) == count + 1, "new buttons receive real pointer feedback")
	button.disabled = true
	count = int(feedback.play_counts.get(&"hover", 0))
	button.mouse_entered.emit()
	_check(int(feedback.play_counts.get(&"hover", 0)) == count, "disabled buttons stay silent")
	button.queue_free()
	# Gieo rebuilds may create and immediately free controls in one frame.
	for index in range(50):
		var transient := Button.new()
		scene.add_child(transient)
		transient.free()
	await process_frame
	scene._on_gieo_impact_requested(&"lever_clunk")
	_check((feedback.players[&"reels"] as AudioStreamPlayer).playing, "slot reels start")
	scene._on_gieo_impact_requested(&"result_reveal")
	_check(not (feedback.players[&"reels"] as AudioStreamPlayer).playing, "slot reels stop at result")
	scene._show_banner("First")
	var old_tween := scene._banner_tween
	scene._show_banner("Latest")
	_check(not old_tween.is_valid(), "new notifications cancel the previous fade")
	_check(scene.banner_label.text == "Latest", "latest notification remains visible")
	scene._banner_tween.kill()
	scene.banner_panel.modulate.a = 0.0
	var wallet_before := scene.deal.wallet.balance_vnd
	for locale in ["en", "vi"]:
		scene.settings.set_locale(locale)
		for key in ["SCORE_MELD_REPLAY", "SCORE_FLOW_REPLAY", "SCORE_ECHO_REPLAY", "SCORE_FLOW", "SCORE_ECHO", "SCORE_PASS", "DRINK_LOCKED", "DRINK_UNLOCK_NOTICE", "DRINK_UNLOCK_HINT"]:
			_check(TranslationServer.translate(key) != key, locale + " has readable " + key)
		receipt.present_scoring({"title": TranslationServer.translate("MELD_ACTION"), "start_wallet_vnd": wallet_before, "target_wallet_vnd": wallet_before, "source_control": scene.meld_views[812], "hits": [{"kind": "card", "pass": 1, "amount_vnd": 39000}, {"kind": "meld_retrigger", "pass": 2, "amount_vnd": 0}]})
		var deadline := Time.get_ticks_msec() + 3000
		while receipt.line_a_label.text != TranslationServer.translate("SCORE_MELD_REPLAY") and Time.get_ticks_msec() < deadline:
			await process_frame
		_check(receipt.line_a_label.text == TranslationServer.translate("SCORE_MELD_REPLAY"), "localized replay on screen: " + locale)
		_check(receipt.line_b_label.text.is_empty(), "replay does not display placeholder punctuation")
		_check(not receipt.title_label.text.contains("SCORE_"), "heading has no internal key")
		_check(receipt.line_a_label.get_theme_font("font") == PresentationTheme.official_font(), "receipt uses game typeface")
		if "--capture" in OS.get_cmdline_user_args():
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png("res://.godot/ui_refinement_" + locale + ".png")
		while receipt.presentation_active:
			await process_frame
	_check(scene.deal.wallet.balance_vnd == wallet_before, "feedback cannot mutate wallet authority")
	scene.queue_free()
	await process_frame
	print("UI_REFINEMENT_SMOKE checks=%d failed=%d" % [checks, failures.size()])
	quit(0 if failures.is_empty() else 1)
