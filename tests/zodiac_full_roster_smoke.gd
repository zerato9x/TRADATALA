extends SceneTree
## Fresh-process full-roster UI coverage; profiles and run saves are isolated.
var failures: Array[String] = []
var checks := 0
var scene: MatchUI

func _initialize() -> void: call_deferred("_run")
func _check(ok: bool, message: String) -> void:
	checks += 1
	if not ok: failures.append(message); push_error(message)
func _frames(count: int = 3) -> void:
	for _i in count: await process_frame
func _capture(label: String) -> void:
	if DisplayServer.get_name() == "headless": return
	await RenderingServer.frame_post_draw
	DirAccess.make_dir_recursive_absolute("res://.godot/zodiac-validation/screens")
	root.get_texture().get_image().save_png("res://.godot/zodiac-validation/screens/%s.png" % label)
func _click(control: Control) -> void:
	await _frames()
	var point := control.get_global_transform_with_canvas() * (control.size * 0.5)
	for pressed in [true, false]:
		var event := InputEventMouseButton.new()
		event.button_index = MOUSE_BUTTON_LEFT
		event.position = point
		event.global_position = point
		event.pressed = pressed
		root.push_input(event, true)
		await process_frame

func _fixture(id: String, level: int, phase: int = 2) -> void:
	scene.current_campaign_event = null
	scene.campaign.current_phase = CampaignManager.CampaignPhase.DRAGON_DEAL if id == "dragon" else CampaignManager.CampaignPhase.EVENING_DEAL
	scene.deal.start_tutorial_deal()
	scene.deal.current_phase = phase
	scene.deal.zodiac_boss.configure(id, level, 14281)
	scene.deal.zodiac_boss.begin_phase(scene.deal)
	if id == "dragon": scene.deal.zodiac_boss.data.analysis = {"action": "new_meld", "meld_type": "set", "tactic": "new_meld:set", "average_vnd": 54000, "target_vnd": 54000, "legacy_fallback": false}
	scene.deal.zodiac_boss.begin_turn(phase, scene.deal.hand, scene.deal)
	scene.deal.zodiac_boss.take_events()
	scene.modal_overlay.hide()
	scene.interactions.locked = false
	scene.interactions.selected_ids.clear()
	scene.interactions.selected_meld_id = -1
	scene.card_table.set_hand_interaction_enabled(true)
	scene.money_playback.displayed_balance = scene.deal.wallet.balance_vnd
	scene.money_playback.queued_balance = scene.money_playback.displayed_balance
	scene._sync_all()

func _run() -> void:
	root.size = Vector2i(1280, 720)
	scene = load("res://scenes/match.tscn").instantiate() as MatchUI
	root.add_child(scene)
	current_scene = scene
	await _frames()
	scene.session.restoring = true
	scene.drink_manager.progress.save_path = ""
	scene.campaign.zodiac.progress = ZodiacProgress.new("")
	scene.session.run_save = RunSave.new("user://zodiac-roster-smoke.save")
	scene.campaign.run_seed = "zodiac-roster-smoke"
	scene.campaign.gieo_que.reset_campaign()
	scene.game_started = true
	scene.menu_layer.hide()
	scene.game_layer.position = Vector2.ZERO
	scene.game_layer.show()
	scene.event_table.table_state = EventTableController.TABLE_STATE_DEAL
	scene.event_table._finish_event_exit()
	var hud: Control = scene.zodiac_boss_hud
	for id: String in ZodiacBossRule.RULES:
		for level in [1, 2, 3]:
			_fixture(id, level)
			var before := scene.deal.zodiac_boss.snapshot()
			for locale in ["en", "vi"]:
				TranslationServer.set_locale(locale)
				scene._on_locale_changed(locale)
				hud.refresh()
				await _frames()
				_check(hud.visible, "boss HUD visible: %s %d %s" % [id, level, locale])
				_check(hud.title.text.contains(ZodiacCatalog.display_name(id)), "localized name: " + id)
				_check(hud.details.text == ZodiacCatalog.rule_text(id, level), "authoritative localized rule: " + id)
				_check(not hud.state_label.text.is_empty(), "state exposed: " + id)
				_check(Rect2(Vector2.ZERO, Vector2(root.size)).encloses(hud.panel.get_global_rect()), "HUD fits viewport: " + id)
				_check(not hud.panel.get_global_rect().intersects(scene.draw_pile_visual.get_global_rect()), "HUD clears draw pile: " + id)
				_check(not hud.panel.get_global_rect().intersects(scene.discard_pile_visual.get_global_rect()), "HUD clears discard pile: " + id)
				_check(not hud.panel.get_global_rect().intersects(scene.hand_layer.get_global_rect()), "HUD clears hand: " + id)
				_check(load(ZodiacCatalog.DEFINITIONS[id].sprite) is Texture2D, "roster asset exists: " + id)
				if level == 3: await _capture("boss_%s_%s" % [id, locale])
			_check(before == scene.deal.zodiac_boss.snapshot(), "UI queries do not reroll " + id)
			_check(scene.deal.physical_card_accounting_is_valid(), "UI preserves physical zones: " + id)
	for viewport_size in [Vector2i(1920, 1080), Vector2i(1280, 720)]:
		root.size = viewport_size
		await _frames()
		_check(Rect2(Vector2.ZERO, Vector2(root.size)).encloses(hud.panel.get_global_rect()), "boss HUD fits alternate viewport")
		_check(not hud.panel.get_global_rect().intersects(scene.draw_pile_visual.get_global_rect()), "boss HUD clears scaled draw pile")
	# Pointer-driven rules open the current Handbook above the table.
	_fixture("dragon", 3)
	await _click(hud.detail_button)
	var book := root.get_node_or_null("GameGlossary") as GameGlossary
	_check(book != null and book._entries[0].body.contains(ZodiacCatalog.rule_text("dragon", 3)), "Pointer opens the complete boss rule in Handbook")
	await _frames()
	_check(book != null and book.layer > 850, "Handbook rules stay above game overlays")
	await _capture("dragon_rule_expanded_vi")
	if book != null: book.queue_free()
	await _frames()
	# Boss receipts observe committed entries and queue the exact net balance.
	_fixture("pig", 2, 1)
	scene.deal.zodiac_boss.data.target_vnd = 100000
	var journal_before := scene.deal.wallet.journal.size()
	var result := scene.deal.create_meld(scene.deal.hand.slice(0, 3))
	scene._sync_all(result)
	scene.money_feedback.queue_scoring(result.context)
	_check(scene.money_playback.queued_balance == scene.deal.wallet.balance_vnd, "Pig queue matches committed siphoned payout")
	_check(scene.deal.wallet.journal.size() == journal_before + 2, "presentation never mutates wallet")
	scene.money_presentation.request_fast_forward()
	await scene.money_playback.wait_for(scene.money_playback.next_job_id - 1)
	_check(scene.money_playback.displayed_balance == scene.deal.wallet.balance_vnd, "Pig displayed balance reaches real net")
	await _frames()
	for meld_view: Control in scene.card_table.meld_views.values():
		_check(not hud.panel.get_global_rect().intersects(meld_view.get_global_rect()), "HUD clears actual player Meld")
	await _capture("pig_player_meld")
	# A suppressed play must still queue automatic boss deductions.
	_fixture("monkey", 2, 1)
	scene.deal.zodiac_boss.data.last_paid_action = "new_meld"
	scene.deal.zodiac_boss.data.repeat_count = 1
	scene.deal.boss_adjust_wallet(-7000, "zodiac:rat:meld")
	result = scene.deal.create_meld(scene.deal.hand.slice(0, 3))
	scene.money_feedback.queue_scoring(result.context)
	_check(scene.money_playback.queued_balance == scene.deal.wallet.balance_vnd, "zero-paid action still presents boss deduction")
	scene.money_presentation.request_fast_forward()
	await scene.money_playback.wait_for(scene.money_playback.next_job_id - 1)
	# Mouse-owned faces are separate from player Melds.
	_fixture("rat", 2, 1)
	var discarded := scene.deal.hand[-1]
	scene.deal.boss_discard_card(discarded, "fixture")
	var top: Array[CardData] = []
	for suit in ["Hearts", "Diamonds"]: top.append(scene.deal._take_tutorial_card("J", suit))
	for i in range(top.size() - 1, -1, -1): scene.deal.deck.draw_pile.append(top[i])
	scene.deal.zodiac_boss.after_discard(scene.deal, scene.deal.discard_history[-1])
	hud.refresh()
	await _frames()
	_check(hud.opponent_cards.visible and hud.opponent_cards.get_child_count() == 1, "Mouse-owned actual faces displayed")
	_check(scene.deal.melds.is_empty(), "Mouse faces do not become player Melds")
	await _capture("mouse_owned_meld")
	# Empty hand ending is a usable action, including Tiger removing a whole Rank.
	_fixture("tiger", 2, 1)
	var remaining: Array[CardData] = scene.deal.hand.duplicate()
	scene.deal.hand.clear()
	scene.deal.move_to_recyclable_spent(remaining)
	scene._sync_all()
	_check(not scene.discard_button.disabled, "empty hand can end without selecting a fake card")
	_check(scene.discard_button.text.contains("TRỐNG"), "empty-hand action localized")
	await _click(scene.discard_button)
	await _frames()
	_check(scene.deal.discard_count == 1 and not scene.deal.hand.is_empty(), "empty-hand pointer action starts next turn")
	scene.money_presentation.request_fast_forward()
	scene._show_banner("ZODIAC ACTION")
	await _frames(18)
	_check(not hud.panel.get_global_rect().intersects(scene.banner_panel.get_global_rect()), "action banner clears authoritative boss state")
	# Real post-Snake completion shows choice; save/resume returns to the choice.
	_fixture("snake", 1, 1)
	scene.campaign.current_day_index = 5
	scene.campaign.zodiac.begin_day(5, 1)
	scene.deal.state = DealState.STATE_DEAL_OVER
	scene.campaign.complete_deal()
	await _frames()
	_check(scene.modal_mode == "zodiac_endgame" and scene.modal_overlay.visible, "post-Snake choice modal visible")
	_check(scene.modal_primary.text == "ĐỐI MẶT THÌN", "Dragon choice localized")
	await _capture("post_snake_choice_vi")
	var saved := scene.session.run_save.capture(scene.campaign, scene.deal)
	_check(scene.session.resume(saved), "choice save resumes")
	_check(scene.modal_mode == "zodiac_endgame", "resumed choice has same actions")
	scene.session.restoring = true
	await _click(scene.modal_primary)
	await _frames(45)
	_check(scene.campaign.current_phase == CampaignManager.CampaignPhase.DRAGON_DEAL, "Dragon pointer choice starts encounter")
	_check(scene.deal.zodiac_boss.id == "dragon", "Dragon configured through real campaign service")
	_check(scene.zodiac_boss_hud.visible, "Dragon rule HUD appears after choice")
	await _capture("dragon_started_vi")
	# Continuing instead routes through debt collection and retains seven-day flow.
	scene.modal_overlay.hide()
	scene.campaign.zodiac.endgame.status = "choice"
	scene.campaign.current_phase = CampaignManager.CampaignPhase.ZODIAC_ENDGAME_CHOICE
	scene._show_zodiac_endgame_choice()
	await _frames()
	await _click(scene.modal_secondary)
	_check(scene.campaign.current_phase == CampaignManager.CampaignPhase.MONEY_REQUIREMENT_CHECK, "continue choice enters ordinary collection")
	_check(scene.deal.physical_card_accounting_is_valid(), "endgame hand remains physically valid")
	for suffix in ["", ".bak", ".tmp"]: DirAccess.remove_absolute(scene.session.run_save.path + suffix)
	scene.queue_free()
	await _frames()
	print("ZODIAC_FULL_ROSTER_SMOKE checks=%d failures=%d" % [checks, failures.size()])
	quit(0 if failures.is_empty() else 1)
