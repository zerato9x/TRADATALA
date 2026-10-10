extends "res://tests/cat_persuasion_scene_smoke.gd"
## Real MatchUI, GUI confirmation, action HUD, locales, callbacks and Emblem scene.

func _seed() -> String:
	for index in 100:
		scene.campaign.run_seed = "ROOSTER-UI-%d" % index
		if ZodiacCatalog.select(scene.campaign.seed_for("zodiac_selection", 0), 0) == "rooster": return scene.campaign.run_seed
	return ""

func _set_node(id: String) -> void:
	var engine := scene.campaign.zodiac.persuasion
	for node: Dictionary in ZodiacCatalog.persuasion_nodes("rooster"):
		if node.id != id: continue
		var visit := engine.state()
		visit.plan = [node]
		visit.cursor = 0
		visit.patience = 3
		visit.status = "active"
		visit.judged = false
		visit.interaction_locked = false
		visit.last_chance_consumed = false
		visit.outcomes = []
		engine._open_node()
		scene.zodiac_table._build_conversation()
		return

func _capture(label: String) -> void:
	if DisplayServer.get_name() == "headless": return
	if scene.zodiac_table.shade.visible: await _click(scene.zodiac_table.dialogue)
	await RenderingServer.frame_post_draw
	var directory := "res://.godot/rooster-expansion-2026-10-10/screens"
	DirAccess.make_dir_recursive_absolute(directory)
	var saved := root.get_texture().get_image().save_png(directory + "/" + label + ".png")
	_check(saved == OK, "capture saved " + label)
	if saved != OK: return
	captures.append(label)

func _remember(topic: String, result: String) -> void:
	var progress := scene.campaign.zodiac.progress
	for node: Dictionary in ZodiacCatalog.persuasion_nodes("rooster"):
		if node.get("promise", {}).get("id", "") != topic: continue
		progress.remember("rooster", "ui:%s:%s:%d" % [topic, result, int(progress.record("rooster").get("memory_revision", 0))], topic,
			{"result": result, "node_id": node.id, "target_id": "", "target_label": "", "relic_id": "", "counteroffer": false,
				"commitment_en": node.promise.en, "commitment_vi": node.promise.vi})
		return

func _open_afternoon() -> void:
	await _pause(0.4)
	var receipt := root.get_node_or_null("LotteryReceipt")
	if receipt != null:
		await _click(receipt.find_child("CloseReceipt", true, false))
		await _pause()
	scene.event_table.unfocus_npc()
	await _click(scene.event_table._npc_layers.zodiac.button)
	await _pause(0.3)
	_check(scene.zodiac_table.shade.visible, "real Afternoon visitor opens after the receipt")

func _finish_afternoon() -> void:
	for _step in 24:
		match scene.deal.state:
			DealState.STATE_ACTIVE: scene.deal.discard_card(scene.deal.hand[-1])
			DealState.STATE_FINAL_COMMIT_WINDOW: scene.deal.settle_phase()
			DealState.STATE_PHASE_CHOICE: scene.deal.choose_phase_two(false)
			DealState.STATE_DEAL_OVER: break
	_check(scene.deal.state == DealState.STATE_DEAL_OVER and scene.deal.physical_card_accounting_is_valid(), "real two-Phase Afternoon completes with valid physical cards")
	scene.money_presentation.request_fast_forward()
	_check(scene.campaign.complete_deal(), "campaign completes the real Afternoon Deal")
	await _open_afternoon()

func _run() -> void:
	root.size = Vector2i(1280, 720)
	root.get_node("GameSettings").set_music_system("playing_tracks")
	TranslationServer.set_locale("en")
	scene = load("res://scenes/match.tscn").instantiate() as MatchUI
	root.add_child(scene)
	current_scene = scene
	await _pause(0.5)
	scene.session.restoring = true
	scene.session.save_files.suspended = true
	scene.campaign.zodiac.progress = ZodiacProgress.new("")
	scene.drink_manager.progress.save_path = ""
	scene.session.run_save = RunSave.new("user://rooster_ui.save")
	scene.game_started = true
	scene.menu_layer.hide()
	scene.game_layer.position = Vector2.ZERO
	scene.game_layer.show()
	await _start()
	var service := scene.campaign.zodiac
	var table: Control = scene.zodiac_table
	_check(service.active_id() == "rooster" and service.has_open_question(), "fresh Rooster opens authored Stranger conversation")
	_check(table.memory_button.visible and table.memory_button.text == "Rooster's ledger", "Rooster ledger is visible")
	await _capture("stranger_en")
	await _click(table.memory_button)
	_check(table.history_open and table.mechanics.text.contains("No promises"), "fresh visitor has no invented action history")
	await _click(table.choices.get_child(0))
	for _index in 3:
		await _click(table.choices.get_child(0))
		_check(service.persuasion.state().stage == "reaction", "GUI answer commits once")
		await _click(table.choices.get_child(0))
	_check(not service.has_open_interaction() and service.mood() == "PLEASED", "Stranger conversation finishes Pleased")
	table.close_conversation()
	scene.campaign._enter_phase(CampaignManager.CampaignPhase.AFTERNOON_EVENT)
	await _open_afternoon()
	_check(service.progress.relationship_tier("rooster") == ZodiacProgress.FAMILIAR, "real return unlocks Familiar")
	await _start()
	_check(service.persuasion.state().node.content_tier == "1+", "New Run preserves Familiar and selects action content")
	_set_node("rooster.t1plus.before_bell")
	var blocked_state: Dictionary = service.persuasion.state().duplicate(true)
	await _key(KEY_H)
	await _click(scene.event_table._npc_layers.tra_da_auntie.button)
	_check(service.persuasion.state() == blocked_state and scene.event_table.focused_npc_id == EventTableController.NPC_ZODIAC, "dialogue blocks gameplay and underlying NPC input")
	(table.choices.get_child(1) as Button).grab_focus()
	await _key(KEY_ENTER)
	_check(service.persuasion.state().stage == "reaction", "keyboard chooses authored answer")
	await _click(table.choices.get_child(0))
	_check(table.contract_label.text.contains("before discard #1") and not table.target_preview.visible, "action contract has a visible deadline and no fake card target")
	await _capture("early_score_terms_en")
	var before := scene.deal.wallet.balance_vnd
	await _click(table.choices.get_child(2))
	_check(service.current_demand().id == "rooster.first_meld" and service.daily.promises.is_empty(), "GUI haggle shows new Phase 1 job before acceptance")
	_check(scene.deal.wallet.balance_vnd == before and table.choices.get_child(2).disabled, "haggle is free and cannot reroll")
	await _capture("counteroffer_en")
	await _click(table.detail_button)
	var book := root.get_node_or_null("GameGlossary") as GameGlossary
	_check(book != null and book._entries[0].body.contains("Play at least one new Meld during Phase 1"), "Handbook shows full alternate terms")
	if book != null: await _click(book.find_child("CloseHandbook", true, false))
	await _click(table.choices.get_child(0))
	_check(service.daily.promises.size() == 1 and service.daily.promises[0].semantic_id == "rooster.first_meld", "GUI Accept reserves exactly the displayed action")
	await _click(table.choices.get_child(0))
	table.close_conversation()
	scene.campaign._enter_phase(CampaignManager.CampaignPhase.AFTERNOON_DEAL)
	await _pause(1.2)
	scene.deal.start_tutorial_deal()
	scene._sync_all() # Replace the rendered seeded hand with the authored fixture.
	await _pause(0.5)
	scene.money_presentation.request_fast_forward()
	_check(scene.zodiac_boss_hud.promise_panel.is_visible_in_tree(), "real Afternoon displays action reminder")
	_check(scene.zodiac_boss_hud.promise_label.text.contains("P1: new Meld") and scene.zodiac_boss_hud.promise_label.text.contains("Pending"), "compact reminder identifies action, phase and pending status")
	await _capture("afternoon_pending_en")
	_check(scene.set_card_selection(scene.deal.hand.slice(0, 3)), "select a real legal scoring play")
	await _pause(0.2)
	_check(not scene.ha_button.disabled, "real Meld control enabled")
	await _click(scene.ha_button)
	_check(service.daily.promises[0].matched and scene.deal.melds.size() == 1, "real GUI Meld fulfills the saved action")
	scene.money_presentation.request_fast_forward()
	await _pause(0.6)
	_check(scene.zodiac_boss_hud.promise_label.text.contains("Done"), "committed fulfillment updates the compact reminder")
	await _capture("afternoon_done_en")
	for locale in ["en", "vi"]:
		TranslationServer.set_locale(locale)
		for offer in [ZodiacCatalog.ROOSTER_PERSUASION.EARLY_SCORE, ZodiacCatalog.ROOSTER_PERSUASION.FIRST_MELD, ZodiacCatalog.ROOSTER_PERSUASION.EXTENSION]:
			# Exercise every authored compact reminder in the narrow 720p HUD.
			var original: Dictionary = service.daily.promises[0].accepted_terms
			service.daily.promises[0].accepted_terms = offer
			scene.zodiac_boss_hud.refresh()
			await process_frame
			var label: Label = scene.zodiac_boss_hud.promise_label
			var font_height := label.get_theme_font("font").get_height(label.get_theme_font_size("font_size"))
			_check(label.get_line_count() * font_height <= label.size.y + 1, "full compact action reminder fits " + String(offer.id) + " " + locale)
			await _capture("hud_%s_%s" % [offer.id, locale])
			service.daily.promises[0].accepted_terms = original
	TranslationServer.set_locale("en")
	scene.zodiac_boss_hud.refresh()
	await _finish_afternoon()
	_check(service.daily.promises.is_empty() and service.progress.memory("rooster", "rooster.first_meld").result == "FULFILLED", "real Afternoon publishes the exact kept commitment")
	await _capture("kept_return_en")
	service.progress.commit("rooster", "ui:kindred", {"promises_kept": 2, "promise_kept:rooster.early_score": 2})
	service.progress.record_disposition("rooster", "ui:kindred-return", "NORMAL")
	await _start()
	_check(service.progress.relationship_tier("rooster") == ZodiacProgress.KINDRED and service.persuasion.state().node.content_tier == "2", "permanent Kindred content selected on next run")
	for locale in ["en", "vi"]:
		TranslationServer.set_locale(locale)
		for viewport_size in [Vector2i(1280, 720), Vector2i(1920, 1080)]:
			root.size = viewport_size
			await _pause()
			for node: Dictionary in ZodiacCatalog.persuasion_nodes("rooster"):
				for result: String in (["FULFILLED", "BROKEN", "REFUSED"] if node.has("memory_key") else [""]):
					if node.has("memory_key"): _remember(node.memory_key, result)
					_set_node(node.id)
					await _fit_question(locale)
					if node.has("memory_key"):
						_check(service.persuasion.state().node.bound_memory.result == result, "specific actual topic result selects callback")
					await _capture("%s_%s_%s_%d" % [node.id, result, locale, viewport_size.x])
					if node.has("promise"):
						await _click(table.choices.get_child(1))
						await _click(table.choices.get_child(0))
						_check(table.contract_label.visible and not table.choices.get_child(0).disabled, "localized action can be accepted without a card")
						_check(table.body.get_global_rect().encloses(table.choices.get_global_rect()), "contract buttons fit " + locale)
						await _click(table.choices.get_child(2))
						_check(service.persuasion.state().stage == "counteroffer" and not service.persuasion.can_haggle(), "one confirmed alternate action")
						await _capture("%s_counter_%s_%d" % [node.id, locale, viewport_size.x])
						await _click(table.choices.get_child(1))
						await _click(table.choices.get_child(0))
	root.size = Vector2i(1280, 720)
	TranslationServer.set_locale("en")
	table.refresh()
	await _click(table.memory_button)
	_check(table.history_open and table.dialogue.text == "What Rooster remembers" and table.mechanics.text.contains("Extension"), "ledger lists real localized commitment terms")
	await _capture("ledger_en")
	await _click(table.choices.get_child(0))
	service.progress = ZodiacProgress.new("")
	await _start()
	for _index in 3:
		await _click(table.choices.get_child(2))
		if service.persuasion.state().stage == "reaction": await _click(table.choices.get_child(0))
	_check(service.persuasion.state().stage == "last_chance", "three empty answers reach authored Last Chance")
	await _fit_question("en")
	await _capture("last_chance_en")
	await _click(table.choices.get_child(2))
	_check(service.persuasion.state().patience == 1 and service.persuasion.state().last_chance_consumed, "honest refusal recovers once through GUI")
	service.persuasion.apply_patience(-1)
	table.refresh()
	_check(service.persuasion.state().interaction_locked, "second zero ends visit")
	service.progress.record_disposition("rooster", "ui:scene-familiar", "PLEASED")
	service.progress.commit("rooster", "ui:scene-eligible", {"promises_kept": 3, "promise_kept:rooster.early_score": 2, "promise_kept:rooster.extension": 1, "promises_refused": 1, "pleased_victories": 1})
	service.progress.record_disposition("rooster", "ui:scene-kindred", "NORMAL")
	await _start()
	_check(service.progress.record("rooster").special_scene_unlocked, "story route unlocks existing private scene on reencounter")
	_check(preload("res://tests/zodiac_test_flow.gd").finish_noon(service), "finish questions before private scene")
	table.refresh()
	_check(table.choices.get_child_count() == 1, "private scene is reachable from authored conversation")
	await _click(table.choices.get_child(0))
	await _capture("private_moment_en")
	for _page in 3: await _click(table.choices.get_child(0))
	_check(service.progress.owns("rooster"), "real private scene grants Emblem exactly once")
	await _click(table.memory_button)
	_check(table.choices.get_child_count() == 3, "owned Emblem exposes future appearance preference from ledger")
	await _click(table.choices.get_child(0))
	_check(service.forced.get("pair:0", "") == "rooster", "ledger can call Rooster on a future matching day")
	print("ROOSTER_PERSUASION_SCENE_SMOKE checks=%d failures=%d captures=%d" % [checks, failures.size(), captures.size()])
	for failure in failures: print("ROOSTER_SCENE_FAIL " + failure)
	scene.queue_free()
	await process_frame
	quit(0 if failures.is_empty() else 1)
