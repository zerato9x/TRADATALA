extends "res://tests/cat_persuasion_scene_smoke.gd"
## Real MatchUI controls, fixed content matrices, actual Deals and bilingual layout.
const FLOW := preload("res://tests/rat_tiger_test_flow.gd")
const NOON_FLOW := preload("res://tests/zodiac_test_flow.gd")
var boss := "rat"

func _seed() -> String:
	for index in 100:
		scene.campaign.run_seed = "RAT-TIGER-UI-%d" % index
		if ZodiacCatalog.select(scene.campaign.seed_for("zodiac_selection", 4), 4) == boss: return scene.campaign.run_seed
	return ""

func _start() -> void:
	scene.zodiac_table.close_conversation()
	scene.run_seed_input = _seed()
	scene._start_campaign()
	await _pause(0.4)
	scene.event_table.unfocus_npc()
	scene.campaign.current_day_index = 4
	scene.campaign.zodiac.begin_day(4, scene.campaign.seed_for("zodiac_selection", 4))
	scene.campaign._enter_phase(CampaignManager.CampaignPhase.NOON_EVENT)
	await _pause(0.4)
	await _click(scene.event_table._npc_layers.zodiac.button)
	await _pause(0.3)

func _set_node(id: String) -> void:
	var engine := scene.campaign.zodiac.persuasion
	engine.state().patience = 3
	engine.state().status = "active"
	engine.state().judged = false
	engine.state().interaction_locked = false
	engine.state().last_chance_consumed = false
	engine.state().outcomes = []
	engine.state().revision += 1
	FLOW.node(scene.campaign, id)
	scene.zodiac_table._build_conversation()
	await process_frame

func _capture(label: String) -> void:
	if DisplayServer.get_name() == "headless": return
	if scene.zodiac_table.shade.visible: await _click(scene.zodiac_table.dialogue)
	await RenderingServer.frame_post_draw
	var directory := "res://.godot/rat-tiger-expansion-2026-10-13/screens"
	DirAccess.make_dir_recursive_absolute(directory)
	var result := root.get_texture().get_image().save_png(directory + "/" + boss + "_" + label + ".png")
	_check(result == OK, "rendered capture " + boss + " " + label)
	if result == OK: captures.append(boss + "_" + label)

func _record() -> Dictionary:
	var service := scene.campaign.zodiac
	return {"daily": service.daily.duplicate(true), "rng": service._rng.state,
		"wallet": scene.campaign.wallet.balance_vnd, "journal": scene.campaign.wallet.journal.duplicate(true), "progress": service.progress.snapshot()}

func _return() -> void:
	await _pause(0.5)
	var receipt := root.get_node_or_null("LotteryReceipt")
	if receipt != null:
		await _click(receipt.find_child("CloseReceipt", true, false))
		await _pause()
	scene.event_table.unfocus_npc()
	await _click(scene.event_table._npc_layers.zodiac.button)
	await _pause(0.3)
	_check(scene.zodiac_table.shade.visible, "actual Afternoon visitor opens " + boss)

func _finish() -> void:
	scene.money_presentation.request_fast_forward()
	_check(FLOW.finish(scene.campaign), "actual two-Phase Deal completes with physical integrity " + boss)
	await _return()

func _remember(node: Dictionary, result: String) -> void:
	var service := scene.campaign.zodiac
	var card: CardData = scene.campaign.gieo_que.persistent_deck[0]
	var details := {"result": result, "node_id": node.id, "target_id": card.unique_id,
		"target_label": card.short_label(), "relic_id": "toothpicks" if node.promise.target_kind == "RELIC" else "", "counteroffer": false}
	if node.promise.target_kind == "ACTION":
		details["commitment_en"] = node.promise.en
		details["commitment_vi"] = node.promise.vi
	service.progress.remember(boss, "ui:memory:%d" % int(service.progress.record(boss).get("memory_revision", 0)), node.memory_key, details)

func _play_meld(cards: Array[CardData]) -> void:
	_check(scene.set_card_selection(cards), "select actual physical Meld cards " + boss)
	await _pause(0.2)
	_check(not scene.ha_button.disabled, "actual Meld control enabled " + boss)
	await _click(scene.ha_button)
	scene.money_presentation.request_fast_forward()
	await _pause(0.7)

func _hud_fit() -> void:
	for locale in ["en", "vi"]:
		TranslationServer.set_locale(locale)
		scene.zodiac_boss_hud.refresh()
		await process_frame
		var label: Label = scene.zodiac_boss_hud.promise_label
		var height := label.get_theme_font("font").get_height(label.get_theme_font_size("font_size"))
		_check(label.get_line_count() * height <= label.size.y + 1, "compact reminder fits " + boss + " " + locale + " text=" + label.text + " lines=" + str(label.get_line_count()) + " height=" + str(label.size.y))
		_check(Rect2(Vector2.ZERO, Vector2(root.size)).encloses(scene.zodiac_boss_hud.promise_panel.get_global_rect()), "reminder fits viewport " + boss + " " + locale)
	TranslationServer.set_locale("en")
	scene.zodiac_boss_hud.refresh()

func _play_extension(cards: Array[CardData]) -> void:
	_check(scene.set_card_selection(cards), "select actual Extension cards " + boss)
	await _click(scene.card_table.meld_views[scene.deal.melds[0].meld_id])
	await _pause(0.2)
	_check(not scene.extend_button.disabled, "actual Extension control enabled " + boss)
	await _click(scene.extend_button)
	scene.money_presentation.request_fast_forward()
	await _pause(0.7)

func _controlled_afternoon(chosen: String = "") -> void:
	# The actual UI normally starts immediately on this signal. Supply one controlled
	# native start, so opening-hand obligations bind before any synthetic play.
	var callback := Callable(scene, "_on_campaign_deal_requested")
	_check(scene.campaign.deal_requested.is_connected(callback), "normal Deal-request presentation is connected")
	scene.campaign.deal_requested.disconnect(callback)
	scene.current_campaign_event = null
	scene.interactions.locked = true
	scene.modal_overlay.visible = false
	scene.card_table.set_hand_interaction_enabled(false)
	scene.interactions.selected_ids.clear()
	scene.interactions.selected_meld_id = -1
	scene.deal.set_current_drink(DrinkCatalog.TRA_DA)
	if chosen.is_empty():
		FLOW.afternoon(scene.campaign)
	else:
		FLOW.chosen_deal(scene.campaign, chosen)
	scene.campaign.deal_requested.connect(callback)
	scene.money_playback.displayed_balance = scene.deal.wallet.balance_vnd
	scene.money_playback.queued_balance = scene.money_playback.displayed_balance
	scene._sync_all({}, true)
	scene.pending_deal_presentation_unlock = true
	scene.event_table.enter_deal()
	await _pause(1.2)

func _side_commitment() -> void:
	await _start()
	var service := scene.campaign.zodiac
	var table: Control = scene.zodiac_table
	await _set_node(boss + ".t1plus." + ("extend" if boss == "rat" else "stand"))
	await _click(table.choices.get_child(1))
	await _click(table.choices.get_child(0))
	await _click(table.choices.get_child(2))
	_check(service.current_demand().card_count == (1 if boss == "rat" else 3), "GUI side counteroffer states exact smaller group or addition " + boss)
	await _capture("side_counteroffer_en")
	await _click(table.choices.get_child(0))
	await _click(table.choices.get_child(0))
	table.close_conversation()
	await _controlled_afternoon()
	await _play_meld(FLOW.cards(scene.deal.hand, FLOW.OPENING.slice(0, 3)))
	if boss == "rat":
		_check(not service.daily.promises[0].matched, "new Meld is not a newly added Extension card")
		await _play_extension(FLOW.cards(scene.deal.hand, [["6", "Hearts"]]))
	_check(service.daily.promises[0].matched and not service.daily.promises[0].broken, "GUI play meets exact side counteroffer " + boss)
	await _hud_fit()
	await _capture("side_evidence_en")
	await _finish()
	var topic: String = boss + "." + ("extend" if boss == "rat" else "stand")
	_check(service.progress.memory(boss, topic).result == "FULFILLED", "real return judges side commitment " + boss)
	await _click(table.memory_button)
	await _capture("side_memory_en")
	await _click(table.choices.get_child(0))

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
	scene.drink_manager.progress.save_path = ""
	scene.session.run_save = RunSave.new("user://rat_tiger_ui.save")
	scene.game_started = true
	scene.menu_layer.hide()
	scene.game_layer.position = Vector2.ZERO
	scene.game_layer.show()
	for id: String in ["rat", "tiger"]:
		boss = id
		TranslationServer.set_locale("en")
		root.size = Vector2i(1280, 720)
		scene.campaign.zodiac.progress = ZodiacProgress.new("")
		await _start()
		var service := scene.campaign.zodiac
		var table: Control = scene.zodiac_table
		_check(service.active_id() == boss and service.has_open_question(), "fresh Stranger authored visit " + boss)
		_check(table.memory_button.text == ZodiacCatalog.localized(ZodiacCatalog.persuasion_config(boss).memory_button), "individual memory entry " + boss)
		await _capture("stranger_en")
		for _question in 3:
			await _click(table.choices.get_child(0))
			_check(service.persuasion.state().stage == "reaction", "GUI answer commits " + boss)
			await _click(table.choices.get_child(0))
		_check(not service.has_open_interaction(), "Stranger visit completes " + boss)
		table.close_conversation()
		scene.campaign._enter_phase(CampaignManager.CampaignPhase.AFTERNOON_EVENT)
		await _return()
		_check(service.progress.relationship_tier(boss) == ZodiacProgress.FAMILIAR, "actual return awards Familiar " + boss)
		await _start()
		var action_node: String = boss + ".t1plus." + ("reuse" if boss == "rat" else "high")
		var action_topic: String = boss + "." + ("reuse" if boss == "rat" else "high")
		await _set_node(action_node)
		var blocked := _record()
		await _key(KEY_H)
		await _click(scene.event_table._npc_layers.tra_da_auntie.button)
		_check(_record() == blocked and scene.event_table.focused_npc_id == EventTableController.NPC_ZODIAC, "conversation isolates underlying gameplay " + boss)
		(table.choices.get_child(1) as Button).grab_focus()
		await _key(KEY_ENTER)
		_check(service.persuasion.state().stage == "reaction", "keyboard chooses authored answer " + boss)
		await _click(table.choices.get_child(0))
		var untouched := _record()
		await _click(table.memory_button)
		_check(table.history_open, "memory opens " + boss)
		table.refresh()
		_check(table.history_open and _record() == untouched, "memory refresh changes no authority " + boss)
		await _click(table.choices.get_child(0))
		await _click(table.choices.get_child(2))
		_check(service.persuasion.state().stage == "counteroffer" and service.daily.promises.is_empty(), "GUI counteroffer requires confirmation " + boss)
		await _capture("counteroffer_en")
		await _click(table.choices.get_child(1))
		await _click(table.choices.get_child(0))
		await _set_node(action_node)
		await _click(table.choices.get_child(1))
		await _click(table.choices.get_child(0))
		await _click(table.choices.get_child(0))
		_check(service.daily.promises.size() == 1 and not service.daily.promises[0].matched, "GUI accepts obligation without fulfillment " + boss)
		await _click(table.choices.get_child(0))
		table.close_conversation()
		await _controlled_afternoon()
		_check(scene.zodiac_boss_hud.promise_panel.is_visible_in_tree() and scene.zodiac_boss_hud.promise_label.text.contains("Pending"), "compact pending action reminder " + boss)
		await _hud_fit()
		await _capture("action_pending_en")
		if boss == "rat":
			_check(FLOW.recover_discard(scene.campaign).ok, "actual discard and Drink swap recover the physical card")
			scene._sync_all()
			scene.money_presentation.request_fast_forward()
			await _pause(0.7)
			_check(service.daily.promises[0].recovered_ids.size() == 1 and not service.daily.promises[0].matched, "recovery still needs a later committed play")
		else:
			_check(service.daily.promises[0].opening_ids.size() == 4 and service.daily.promises[0].opening_rank == 13, "actual opening binds four physical Kings")
			await _play_meld(FLOW.cards(scene.deal.hand, FLOW.OPENING.slice(0, 3)))
			_check(not service.daily.promises[0].matched, "lower ranks cannot replace the highest opening targets")
		await _hud_fit()
		await _capture("action_partial_en")
		await _play_meld(FLOW.cards(scene.deal.hand, FLOW.OPENING.slice(0, 3) if boss == "rat" else [["K", "Hearts"], ["K", "Diamonds"], ["K", "Clubs"]]))
		_check(service.daily.promises[0].matched and scene.zodiac_boss_hud.promise_label.text.contains("Done"), "GUI Meld completes actual recovered card or opening target " + boss)
		await _hud_fit()
		await _capture("action_done_en")
		await _finish()
		_check(service.progress.memory(boss, action_topic).result == "FULFILLED", "real Afternoon judges kept action " + boss)
		await _start()
		await _set_node(boss + ".t1plus." + "card")
		await _click(table.choices.get_child(1))
		await _click(table.choices.get_child(0))
		_check(table.choices.get_child(0).disabled and not service.persuasion.can_haggle(), "voluntary choice waits for a card and cannot reroll " + boss + " stage=" + String(service.persuasion.state().stage) + " disabled=" + str(table.choices.get_child(0).disabled) + " haggle=" + str(service.persuasion.can_haggle()) + " authority=" + String(service.current_demand().get("authority", "")))
		await _click(table.card_select_button)
		_check(scene.deck_screen.visible and scene.deck_screen._allowed.size() == 3, "shared card browser opens " + boss)
		var chosen: String = scene.deck_screen._allowed.keys()[0]
		var chosen_card: CardData = CardTargetQuery.resolve_ids(scene.campaign.gieo_que.persistent_deck, [chosen])[0]
		scene.deck_screen._inspect(chosen_card)
		await _click(scene.deck_screen._confirm)
		_check(service.persuasion.state().selection == [chosen] and not table.choices.get_child(0).disabled, "real browser choice enables Accept " + boss)
		TranslationServer.set_locale("vi")
		table.refresh()
		await _capture("chosen_terms_vi")
		TranslationServer.set_locale("en")
		table.refresh()
		await _click(table.choices.get_child(0))
		_check(service.daily.promises[0].target_ids == [chosen], "GUI commitment stores only selected physical ID " + boss)
		await _click(table.choices.get_child(0))
		table.close_conversation()
		await _controlled_afternoon(chosen)
		await _play_meld(scene.deal.hand.slice(0, 4))
		if boss == "rat":
			_check(not service.daily.promises[0].matched, "initial card play is not its promised recovery and replay")
			_check(FLOW.recover_chosen(scene.campaign, chosen).ok, "actual Drink returns the chosen card from its Meld")
			scene._sync_all()
			await _pause(0.3)
			_check(chosen in service.daily.promises[0].recovered_ids and not service.daily.promises[0].matched, "only selected physical recovery is ready for its later play")
			await _hud_fit()
			await _capture("chosen_recovered_en")
			await _play_extension(CardTargetQuery.resolve_ids(scene.deal.hand, [chosen]))
		await _hud_fit()
		_check(service.daily.promises[0].matched and not service.daily.promises[0].broken, "chosen card actual play meets its authored rule after the preceding completed Deal " + boss)
		await _finish()
		var card_topic: String = boss + ".card"
		_check(service.progress.memory(boss, card_topic).target_id == chosen and service.progress.memory(boss, card_topic).result == "FULFILLED", "real chosen-card memory " + boss)
		await _click(table.memory_button)
		await _capture("chosen_memory_en")
		await _click(table.choices.get_child(0))
		await _side_commitment()
		service.progress.commit(boss, "ui:third:" + boss, {"promises_kept": 1, "promise_kept:" + action_topic: 1})
		service.progress.record_disposition(boss, "ui:kindred:" + boss, "NORMAL")
		await _start()
		_check(service.progress.relationship_tier(boss) == ZodiacProgress.KINDRED and service.persuasion.state().node.content_tier == "2", "Kindred content enters a later visit " + boss)
		scene.campaign.relic_shop.runtime.acquire("toothpicks")
		scene.campaign.relic_shop.runtime.acquire("sunflower_seeds")
		for viewport_size in [Vector2i(1280, 720), Vector2i(1920, 1080)]:
			root.size = viewport_size
			for locale in ["en", "vi"]:
				TranslationServer.set_locale(locale)
				table.refresh()
				for node: Dictionary in ZodiacCatalog.persuasion_nodes(boss):
					var outcomes: Array = ["FULFILLED", "BROKEN", "REFUSED"] if node.has("memory_key") else [""]
					for outcome: String in outcomes:
						if node.has("memory_key"): _remember(node, outcome)
						await _set_node(node.id)
						await _pause(0.08)
						await _fit_question(locale)
						_check(not service.quote().speech.contains("{target}"), "localized memory target bound " + node.id)
						if node.has("memory_key"):
							_check(not table.target_preview.visible and not table.contract_label.visible, "recall keeps proposed next targets out of the remembered question " + node.id)
							_check(service.persuasion.state().node.bound_memory.result == outcome, "authored recall branch " + node.id + " " + outcome)
						if viewport_size.x == 1280 and locale == "vi" and outcome == "BROKEN" and node.id.ends_with("memory"):
							await _capture(node.id.get_slice(".", 2) + "_broken_vi")
						await _click(table.choices.get_child(0))
						await _click(table.choices.get_child(0))
						if node.has("promise"):
							_check(table.contract_label.visible and table.body.get_global_rect().encloses(table.choices.get_global_rect()), "contract controls fit " + node.id + " " + locale)
							var before := service._rng.state
							var offer: Dictionary = service.current_demand().duplicate(true)
							table.refresh()
							_check(service._rng.state == before and service.current_demand() == offer, "refresh cannot change terms " + node.id)
							await _click(table.choices.get_child(1))
							await _click(table.choices.get_child(0))
		root.size = Vector2i(1280, 720)
		TranslationServer.set_locale("en")
		service.progress = ZodiacProgress.new("")
		await _start()
		for _index in 3:
			await _click(table.choices.get_child(2))
			if service.persuasion.state().stage == "reaction": await _click(table.choices.get_child(0))
		_check(service.persuasion.state().stage == "last_chance", "three actual negative answers trigger Last Chance " + boss)
		await _fit_question("en")
		TranslationServer.set_locale("vi")
		table.refresh()
		await _fit_question("vi")
		await _capture("last_chance_vi")
		await _click(table.choices.get_child(1))
		_check(service.persuasion.state().patience == 1 and service.persuasion.state().last_chance_consumed, "GUI honest recovery occurs once " + boss)
		service.persuasion.apply_patience(-1)
		table.refresh()
		_check(service.persuasion.state().interaction_locked, "second zero locks visit " + boss)
		service.progress.record_disposition(boss, "ui:scene-familiar:" + boss, "PLEASED")
		var topics: Array = ZodiacCatalog.persuasion_config(boss).progression[0].promises
		service.progress.commit(boss, "ui:scene-story:" + boss, {"promises_kept": 3, "promise_kept:" + topics[0]: 2, "promise_kept:" + topics[1]: 1, "promises_refused": 1, "pleased_victories": 1})
		service.progress.record_disposition(boss, "ui:scene-kindred:" + boss, "NORMAL")
		TranslationServer.set_locale("en")
		await _start()
		_check(service.progress.record(boss).special_scene_unlocked, "private scene unlocks on reencounter " + boss)
		_check(NOON_FLOW.finish_noon(service), "finish visit before scene " + boss)
		table.refresh()
		_check(table.choices.get_child_count() == 1, "private scene reachable " + boss)
		await _click(table.choices.get_child(0))
		await _capture("private_moment_en")
		for locale in ["en", "vi"]:
			TranslationServer.set_locale(locale)
			for page in 3:
				table.scene_page = page
				table._show_scene()
				await _pause(0.08)
				_check(table.dialogue.text == ZodiacCatalog.localized(ZodiacCatalog.persuasion_config(boss).private_scene[page]), "individual private scene page " + boss + " " + locale)
		table.scene_page = 0
		table._show_scene()
		for _page in 3: await _click(table.choices.get_child(0))
		_check(service.progress.owns(boss), "GUI private scene grants Emblem " + boss)
		await _click(table.memory_button)
		_check(table.choices.get_child_count() == 3, "memory exposes appearance choice " + boss)
		await _click(table.choices.get_child(0))
		_check(service.forced.get("pair:4", "") == boss and service.active_id() == boss, "future Friday preference preserves current visitor " + boss)
	print("RAT_TIGER_PERSUASION_SCENE_SMOKE checks=%d failures=%d captures=%d" % [checks, failures.size(), captures.size()])
	for failure in failures: print("RAT_TIGER_SCENE_FAIL " + failure)
	scene.queue_free()
	await process_frame
	quit(0 if failures.is_empty() else 1)
