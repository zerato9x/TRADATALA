extends SceneTree
## Rendered layout, physical GUI input, modal isolation, and end-to-end Cat flow.
var checks := 0
var failures: Array[String] = []
var scene: MatchUI
var captures: Array[String] = []

func _initialize() -> void:
	call_deferred("_run")

func _check(ok: bool, message: String) -> void:
	checks += 1
	if not ok: failures.append(message); push_error(message)

func _pause(seconds: float = 0.15) -> void:
	await create_timer(seconds).timeout
	await process_frame

func _click(control: Control) -> void:
	await process_frame
	var point := control.get_global_transform_with_canvas() * (control.size * 0.5)
	for pressed in [true, false]:
		var event := InputEventMouseButton.new()
		event.button_index = MOUSE_BUTTON_LEFT
		event.position = point
		event.global_position = point
		event.pressed = pressed
		root.push_input(event, true)
		await process_frame

func _key(code: Key) -> void:
	for pressed in [true, false]:
		var event := InputEventKey.new()
		event.keycode = code
		event.physical_keycode = code
		event.pressed = pressed
		root.push_input(event, true)
		await process_frame

func _capture(label: String) -> void:
	if DisplayServer.get_name() == "headless": return
	await RenderingServer.frame_post_draw
	var directory := "res://.godot/cat-persuasion-validation/screens"
	DirAccess.make_dir_recursive_absolute(directory)
	root.get_texture().get_image().save_png(directory + "/" + label + ".png")
	captures.append(label)

func _seed() -> String:
	for index in 50:
		scene.campaign.run_seed = "CAT-PERSUASION-UI-%d" % index
		if ZodiacCatalog.select(scene.campaign.seed_for("zodiac_selection", 0), 0) == "cat": return scene.campaign.run_seed
	return ""

func _start() -> void:
	scene.zodiac_table.close_conversation()
	scene.run_seed_input = _seed()
	scene._start_campaign()
	await _pause(0.4)
	scene.event_table.unfocus_npc()
	scene.campaign._enter_phase(CampaignManager.CampaignPhase.NOON_EVENT)
	await _pause(0.4)
	await _click(scene.event_table._npc_layers.zodiac.button)
	await _pause(0.4)

func _set_node(id: String) -> void:
	var engine := scene.campaign.zodiac.persuasion
	for node: Dictionary in ZodiacCatalog.persuasion_nodes("cat"):
		if node.id != id: continue
		engine.state().plan = [node]
		engine.state().cursor = 0
		engine.state().patience = 3
		engine.state().status = "active"
		engine.state().judged = false
		engine.state().interaction_locked = false
		engine.state().last_chance_consumed = false
		engine._open_node()
		scene.zodiac_table._build_conversation()
		return

func _fit_question(locale: String) -> void:
	var table: Control = scene.zodiac_table
	await process_frame
	_check(table.choices.get_child_count() == 3, "exactly three authored answers " + locale)
	_check(table.body.get_global_rect().encloses(table.choices.get_global_rect()), "answer rows fit conversation " + locale)
	_check(Rect2(Vector2.ZERO, Vector2(root.size)).encloses(table.body.get_global_rect()), "panel fits viewport " + locale)
	for index in 3:
		var button: Button = table.choices.get_child(index)
		var label: Label = button.get_node("AnswerText")
		var font_height := label.get_theme_font("font").get_height(17)
		_check(label.get_line_count() * font_height <= label.size.y + 1, "full answer text fits row %d %s" % [index, locale])
		_check(not button.disabled and button.focus_mode == Control.FOCUS_ALL, "answer is clickable and keyboard focusable")

func _run() -> void:
	root.size = Vector2i(1280, 720)
	root.get_node("GameSettings").set_music_system("playing_tracks")
	scene = load("res://scenes/match.tscn").instantiate() as MatchUI
	root.add_child(scene)
	current_scene = scene
	await _pause(0.5)
	scene.session.restoring = true
	scene.session.save_files.suspended = true
	scene.campaign.zodiac.progress = ZodiacProgress.new("")
	scene.drink_manager.progress.save_path = ""
	scene.session.run_save = RunSave.new("user://cat_ui.save")
	scene.game_started = true
	scene.menu_layer.hide()
	scene.game_layer.position = Vector2.ZERO
	scene.game_layer.show()
	await _start()
	var service := scene.campaign.zodiac
	var table: Control = scene.zodiac_table
	_check(table.shade.visible and service.has_open_question(), "fresh Cat opens an authored Question")
	_check(service.progress.relationship_tier("cat") == ZodiacProgress.STRANGER, "fresh player meets STRANGER")
	_check(int(service.persuasion.state().patience) == 3, "Noon begins at three Patience")
	for _index in 3:
		var node: Dictionary = service.persuasion.state().node
		var index := 0
		for answer in node.answers:
			if int(answer.delta) == 1: index = node.answers.find(answer)
		var answer: Dictionary = node.answers[index]
		await _click(table.choices.get_child(index))
		_check(service.persuasion.state().stage == "reaction", "click commits the authored answer once")
		await _click(table.detail_button)
		var reaction_book := root.get_node_or_null("GameGlossary") as GameGlossary
		_check(reaction_book != null and reaction_book._entries[0].body.contains(ZodiacCatalog.localized(answer.reaction[0])), "full exact authored Cat reaction stays readable in Handbook")
		if reaction_book != null: await _click(reaction_book.find_child("CloseHandbook", true, false))
		await _click(table.choices.get_child(0))
	_check(not service.has_open_interaction() and service.mood() == "PLEASED", "surface conversation completes PLEASED")
	table.close_conversation()
	scene.campaign._enter_phase(CampaignManager.CampaignPhase.AFTERNOON_EVENT)
	await _pause(0.4)
	var receipt := root.get_node_or_null("LotteryReceipt")
	if receipt != null: receipt.queue_free(); await _pause()
	await _click(scene.event_table._npc_layers.zodiac.button)
	await _pause(0.3)
	_check(service.progress.relationship_tier("cat") == ZodiacProgress.FAMILIAR, "Afternoon judgement permanently unlocks FAMILIAR")
	_check(table.status.text.contains("FAMILIAR") or table.status.text.contains("QUEN MẶT"), "relationship upgrade is visible")
	await _capture("familiar_unlock")
	await _start()
	_check(service.has_open_question() and service.persuasion.state().node.content_tier == "1+", "New Run preserves FAMILIAR and opens Tier 1+")
	scene.deal.relics.acquire("comb")
	scene.deal.relics.acquire("hair_clip")
	scene.campaign.gieo_que.persistent_deck[0].apply_rank("K", 13)
	scene.campaign.gieo_que.persistent_deck[1].apply_suit("Hearts")
	for locale in ["en", "vi"]:
		TranslationServer.set_locale(locale)
		for viewport_size in [Vector2i(1280, 720), Vector2i(1920, 1080)]:
			root.size = viewport_size
			await _pause()
			for node: Dictionary in ZodiacCatalog.CAT_PERSUASION.NODES:
				_set_node(node.id)
				await _fit_question(locale)
				if node.content_tier == "1+":
					await _click(table.choices.get_child(1))
					await _click(table.choices.get_child(0))
					_check(table.contract_label.visible and not table.contract_label.text.is_empty(), "authored Promise terms visible " + node.id)
					_check(table.target_preview.visible, "affected physical card or owned Relic visible")
					_check(table.choices.get_child_count() == 3, "Accept Refuse Haggle visible")
					await process_frame
					_check(table.body.get_global_rect().encloses(table.choices.get_global_rect()), "Promise controls fit " + locale)
					await _capture(node.id + "_" + locale + "_" + str(viewport_size.x))
					var before := scene.deal.wallet.balance_vnd
					await _click(table.choices.get_child(2))
					_check(service.persuasion.state().stage == "counteroffer" and service.daily.promises.is_empty(), "Haggle reveals replacement before commitment")
					_check(scene.deal.wallet.balance_vnd == before, "Haggle does not debit money")
					await _click(table.choices.get_child(1))
					_check(service.daily.promises.is_empty(), "Refuse creates no commitment")
					await _click(table.choices.get_child(0))
				else: await _capture(node.id + "_" + locale + "_" + str(viewport_size.x))
	root.size = Vector2i(1280, 720)
	TranslationServer.set_locale("en")
	_set_node("cat.t1plus.leave_it_alone")
	await process_frame
	# Ordinary game shortcuts and an underlying Event control cannot leak through.
	var before := service.persuasion.state().duplicate(true)
	var phase := scene.campaign.current_phase
	var focus: String = scene.event_table.focused_npc_id
	await _key(KEY_H)
	await _click(scene.event_table._npc_layers.tra_da_auntie.button)
	_check(service.persuasion.state() == before and scene.campaign.current_phase == phase and scene.event_table.focused_npc_id == focus, "conversation blocks gameplay and underlying NPC input")
	var answer_button: Button = table.choices.get_child(1)
	answer_button.grab_focus()
	await _key(KEY_ENTER)
	_check(service.persuasion.state().stage == "reaction", "Enter activates focused authored answer")
	await _click(table.choices.get_child(0))
	await _click(table.choices.get_child(2))
	_check(table.target_preview.get_child_count() == 3, "counteroffer shows exactly three physical faces")
	_check(table.choices.get_child(0).disabled, "counteroffer cannot accept before selection")
	await _click(table.card_select_button)
	_check(scene.deck_screen.visible and scene.deck_screen._allowed.size() == 3, "shared deck browser constrains selection to the three offered cards")
	var id: String = scene.deck_screen._allowed.keys()[0]
	scene.deck_screen._inspect(CardTargetQuery.resolve_ids(scene.campaign.gieo_que.persistent_deck, [id])[0])
	await _click(scene.deck_screen._confirm)
	_check(not scene.deck_screen.visible and service.persuasion.state().selection == [id], "chosen physical identity returns to saved conversation")
	_check(scene.session.run_save.save_run(scene.campaign, scene.deal), "counteroffer and UI selection save")
	_check(scene.session.run_save.restore(scene.session.run_save.load_run(), scene.campaign, scene.deal), "counteroffer and UI selection restore")
	table.refresh()
	_check(table.selected_ids == [id] and not table.choices.get_child(0).disabled, "restored selection enables confirmation")
	await _capture("selected_counteroffer")
	await _click(table.choices.get_child(0))
	_check(service.daily.promises.size() == 1 and service.daily.promises[0].target_ids == [id], "Accept tracks exactly the shown physical card")
	_check(table.dialogue.text.contains("Interesting."), "authored counteroffer acceptance reaction")
	await _click(table.choices.get_child(0))
	table.close_conversation()
	scene.campaign._enter_phase(CampaignManager.CampaignPhase.AFTERNOON_DEAL)
	await _pause(1.2)
	_check(scene.zodiac_boss_hud.promise_panel.is_visible_in_tree(), "readable promise reminder appears during the real Afternoon Deal")
	_check(scene.zodiac_boss_hud.promise_panel.size.y <= 70 and scene.zodiac_boss_hud.promise_label.size.x >= 150 and scene.zodiac_boss_hud.promise_panel.get_global_rect().end.y < scene.draw_pile_visual.get_global_rect().position.y, "promise reminder stays beside the day HUD and clears the table")
	_check(scene.zodiac_boss_hud.promise_label.text.contains(CardTargetQuery.resolve_ids(scene.campaign.gieo_que.persistent_deck, [id])[0].short_label()), "compact reminder identifies the promised card at a glance")
	await _click(scene.zodiac_boss_hud._promise_details)
	var promise_book := root.get_node_or_null("GameGlossary") as GameGlossary
	_check(promise_book != null and promise_book._entries[0].body.contains("Do not interact with the selected card during the next Deal."), "promise Handbook contains exact authored accepted terms")
	if promise_book != null: await _click(promise_book.find_child("CloseHandbook", true, false))
	await _capture("afternoon_promise_reminder")
	var promise: Dictionary = service.daily.promises[0]
	var target := CardTargetQuery.resolve_ids(scene.deal.hand, [id])
	if not target.is_empty(): scene.deal.discard_card(target[0])
	service.finish_daytime_deal("afternoon")
	scene.campaign._enter_phase(CampaignManager.CampaignPhase.AFTERNOON_EVENT)
	await _pause(0.5)
	receipt = root.get_node_or_null("LotteryReceipt")
	if receipt != null: receipt.queue_free(); await _pause()
	await _click(scene.event_table._npc_layers.zodiac.button)
	await _pause(0.4)
	_check(table.shade.visible and not service.persuasion.state().outcomes.is_empty(), "Afternoon presents actual Promise result")
	_check(table.dialogue.text.contains("You touched it.") if promise.broken else table.dialogue.text.contains("You really didn’t."), "Cat's exact authored outcome is shown")
	_check(table.status.text.contains("Broken") if promise.broken else table.status.text.contains("Kept"), "short result and final disposition are explicit")
	await _capture("afternoon_promise_judgement")
	table.close_conversation()
	scene.campaign._enter_phase(CampaignManager.CampaignPhase.EVENING_DEAL)
	await _pause(0.4)
	_check(scene.deal.zodiac_boss.id == "cat" and scene.deal.zodiac_boss.difficulty == service.difficulty(), "real Evening Cat receives final Patience severity")
	_check(not scene.zodiac_boss_hud.promise_panel.visible, "settled reminder clears before Evening")
	await _capture("evening_stalk")
	for suffix in ["", ".bak", ".tmp"]: DirAccess.remove_absolute(scene.session.run_save.path + suffix)
	scene.queue_free()
	await _pause(0.2)
	print("CAT_PERSUASION_SCENE_SMOKE checks=%d failures=%d captures=%d" % [checks, failures.size(), captures.size()])
	quit(0 if failures.is_empty() else 1)
