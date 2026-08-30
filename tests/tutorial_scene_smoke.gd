extends SceneTree

var _failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var packed := load("res://scenes/match.tscn") as PackedScene
	var scene := packed.instantiate() as MatchUI
	root.add_child(scene)
	current_scene = scene
	await process_frame
	await process_frame
	await process_frame
	var tutorial_steps_seen := {}
	scene.tutorial_step_changed.connect(func(step: StringName) -> void: tutorial_steps_seen[step] = true)
	scene.game_started = true
	scene.game_layer.position = Vector2.ZERO
	scene.menu_layer.visible = false
	scene._start_tutorial_deal()

	_check(scene.tutorial_active and scene.tutorial_step == MatchUI.TUTORIAL_SELECT_RUN, "tutorial starts at Run selection")
	_check(scene.tutorial_coach.visible and scene.tutorial_progress_label.text == "GĐ 1 • LƯỢT 1\n1 / 10", "tutorial coach presents Phase, Turn, and full lesson progress")
	_check(scene.tutorial_spotlight.visible and scene.tutorial_spotlight.targets.size() == 3, "tutorial shadows the table except for the three target Run cards")
	_check(scene.deal.hand.size() == DealState.ACTIVE_HAND_TARGET, "tutorial starts with ten deterministic cards")

	var wrong_card := _card_by_id(scene, "standard_9_spades")
	scene._on_card_pressed(wrong_card)
	_check(scene.selected_card_ids.is_empty() and scene.tutorial_step == MatchUI.TUTORIAL_SELECT_RUN, "wrong cards are rejected without advancing")
	for card_id in MatchUI.TUTORIAL_RUN_IDS:
		scene._on_card_pressed(_card_by_id(scene, String(card_id)))
	_check(scene.tutorial_step == MatchUI.TUTORIAL_PLAY_RUN and not scene.ha_button.disabled, "selecting 4H-6H advances to the enabled Meld action")
	_send_escape(scene)
	_check(scene.tutorial_step == MatchUI.TUTORIAL_SELECT_RUN and scene.selected_card_ids.is_empty(), "Escape rewinds the Meld action without trapping the tutorial")
	for card_id in MatchUI.TUTORIAL_RUN_IDS:
		scene._on_card_pressed(_card_by_id(scene, String(card_id)))
	_check(scene.tutorial_spotlight.targets.size() == 1 and scene.tutorial_spotlight.targets[0] == scene.ha_button, "Meld step spotlights only the Meld button")
	_check(scene.extend_button.disabled and scene.discard_button.disabled and scene.hint_button.disabled, "unrelated actions stay gated during the tutorial")

	await scene._on_ha_pressed()
	_check(scene.tutorial_step == MatchUI.TUTORIAL_SELECT_DISCARD and scene.tutorial_meld_id > 0, "playing the Run advances to discard selection")
	_check(tutorial_steps_seen.has(MatchUI.TUTORIAL_MELD_SCORE), "tutorial explicitly teaches the new-Meld scoring formula")
	_check(scene.deal.wallet.balance_vnd > scene.tutorial_wallet_before, "tutorial scoring uses the real scoring presentation")

	scene._on_card_pressed(_card_by_id(scene, String(MatchUI.TUTORIAL_FIRST_DISCARD_ID)))
	_check(scene.tutorial_step == MatchUI.TUTORIAL_DISCARD and not scene.discard_button.disabled, "selecting QD enables the first discard")
	await scene._on_discard_pressed()
	_check(scene.tutorial_step == MatchUI.TUTORIAL_SELECT_EXTEND, "first discard advances to the Extend lesson")
	_check(scene.tutorial_progress_label.text.contains("LƯỢT 2"), "tutorial advances the visible Turn counter after discard")
	_check(_card_by_id(scene, String(MatchUI.TUTORIAL_EXTENSION_ID)) != null, "the deterministic refill draws 7H")

	scene._on_card_pressed(_card_by_id(scene, String(MatchUI.TUTORIAL_EXTENSION_ID)))
	_check(scene.tutorial_step == MatchUI.TUTORIAL_SELECT_MELD and scene.selected_meld_id == -1, "7H selection asks the player to target the table Meld")
	_send_escape(scene)
	_check(scene.tutorial_step == MatchUI.TUTORIAL_SELECT_EXTEND and scene.selected_card_ids.is_empty(), "Escape rewinds Meld targeting to the extension-card step")
	scene._on_card_pressed(_card_by_id(scene, String(MatchUI.TUTORIAL_EXTENSION_ID)))
	scene._on_meld_pressed(scene.tutorial_meld_id)
	_check(scene.tutorial_step == MatchUI.TUTORIAL_EXTEND and not scene.extend_button.disabled, "targeting the Run enables Extend")
	await scene._on_extend_pressed()
	_check(scene.tutorial_step == MatchUI.TUTORIAL_SELECT_FINAL_DISCARD, "extending advances to the second discard")
	_check(tutorial_steps_seen.has(MatchUI.TUTORIAL_EXTEND_SCORE), "tutorial explicitly teaches that Extend pays only the score delta")

	scene._on_card_pressed(_card_by_id(scene, String(MatchUI.TUTORIAL_FINAL_DISCARD_ID)))
	_check(scene.tutorial_step == MatchUI.TUTORIAL_FINAL_DISCARD and not scene.discard_button.disabled, "selecting KS enables the second discard")
	await scene._on_discard_pressed()
	_check(scene.tutorial_step == MatchUI.TUTORIAL_MOM and scene.tutorial_exit_button.text == "TIẾP", "core loop advances into the guided Móm lesson")
	_check(scene.tutorial_outcome_visible and scene.score_overlay.visible and scene.score_line_a.text.contains("MÓM") and scene.score_line_b.text.contains("×"), "Móm lesson displays its multiplied deadwood equation")
	_check(scene.tutorial_body_label.text.contains("Phỏm MỚI") and scene.tutorial_body_label.text.contains("Ghép"), "Móm lesson explains that only a new Meld prevents it")
	_check(scene.tutorial_spotlight.targets.size() == 1 and scene.tutorial_spotlight.targets[0] == scene.score_panel, "special outcome lesson spotlights its result panel")

	scene._on_tutorial_exit_pressed()
	_check(scene.tutorial_step == MatchUI.TUTORIAL_U and scene.score_payout.text.contains("×2"), "Next advances to the guided Ù lesson and Phase Gross multiplier")
	_check(scene.tutorial_body_label.text.contains("đúng 9") and scene.tutorial_body_label.text.contains("bỏ lá cuối"), "Ù lesson explains the exact nine-card commit and final discard")
	scene._on_tutorial_exit_pressed()
	_check(scene.tutorial_step == MatchUI.TUTORIAL_U_KHAN and scene.score_line_b.text.contains("×10"), "Next advances to the corrected ×10 Ù Khan lesson")
	_check(scene.tutorial_body_label.text.contains("không có đôi") and scene.tutorial_body_label.text.contains("1–2 số"), "Ù Khan lesson exposes the implemented near-meld condition")
	scene._on_tutorial_exit_pressed()
	_check(scene.tutorial_step == MatchUI.TUTORIAL_COMPLETE and scene.tutorial_exit_button.text == "CHƠI VÁN THẬT", "special lessons complete the tutorial")
	_check(not scene.tutorial_outcome_visible and not scene.score_overlay.visible, "completion clears the special outcome presentation")
	_check(scene.tutorial_spotlight.targets.size() == 1 and scene.tutorial_spotlight.targets[0] == scene.tutorial_exit_button, "completion spotlights the real-deal action")

	scene._on_tutorial_exit_pressed()
	_check(not scene.tutorial_active and not scene.tutorial_coach.visible, "Play a Real Deal closes tutorial mode")
	_check(scene.deal.wallet.balance_vnd == 0 and scene.displayed_wallet_vnd == 0, "tutorial earnings do not leak into the real wallet")

	scene.queue_free()
	await process_frame
	for autoload_name in ["GameSettings", "_mcp_game_helper"]:
		var autoload_node := root.get_node_or_null(autoload_name)
		if autoload_node != null:
			autoload_node.queue_free()
	await process_frame
	_finish()


func _card_by_id(scene: MatchUI, card_id: String) -> CardData:
	for card in scene.deal.hand:
		if card.unique_id == card_id:
			return card
	return null


func _send_escape(scene: MatchUI) -> void:
	var event := InputEventKey.new()
	event.pressed = true
	event.keycode = KEY_ESCAPE
	scene._unhandled_key_input(event)


func _check(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)


func _finish() -> void:
	if _failures.is_empty():
		print("TRADATALA_TUTORIAL_SMOKE passed")
		quit(0)
	else:
		for failure in _failures:
			print("TUTORIAL_SMOKE_FAIL: %s" % failure)
		quit(1)
