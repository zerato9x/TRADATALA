extends "res://tests/cat_persuasion_scene_smoke.gd"
## Uses the real MatchUI, conversation buttons and shared DeckScreen.

func _capture(label: String) -> void:
	if DisplayServer.get_name() == "headless": return
	if scene.zodiac_table.shade.visible:
		await _click(scene.zodiac_table.dialogue)
	await RenderingServer.frame_post_draw
	var directory := "res://.godot/cat-expansion-2026-10-10/screens"
	DirAccess.make_dir_recursive_absolute(directory)
	var saved := root.get_texture().get_image().save_png(directory + "/" + label + ".png")
	_check(saved == OK, "capture saved " + label)
	if saved != OK: return
	captures.append(label)

func _remember(result: String) -> void:
	var progress := scene.campaign.zodiac.progress
	for topic in ["cat.leave_card", "cat.keep_relic", "cat.protect_card"]:
		var card: CardData = scene.campaign.gieo_que.persistent_deck[4]
		progress.remember("cat", "scene:%s:%s:%d" % [topic, result, int(progress.record("cat").get("memory_revision", 0))], topic,
			{"result": result, "node_id": "scene:fixture", "target_id": card.unique_id, "target_label": card.short_label(),
			"relic_id": "comb" if topic == "cat.keep_relic" else "", "counteroffer": false})

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
	scene.session.run_save = RunSave.new("user://cat_expansion_ui.save")
	scene.game_started = true
	scene.menu_layer.hide()
	scene.game_layer.position = Vector2.ZERO
	scene.game_layer.show()
	await _start()
	var service := scene.campaign.zodiac
	var table: Control = scene.zodiac_table
	_check(table.memory_button.visible, "Cat memory is accessible without changing the three answer choices")
	await _click(table.memory_button)
	_check(table.history_open and table.mechanics.text.contains("No promises"), "fresh Cat has no fabricated memories")
	await _click(table.choices.get_child(0))
	_check(service.has_open_question() and not table.history_open, "returning from memory keeps the current question")
	service.progress.record_disposition("cat", "scene:familiar", "PLEASED")
	service.progress.commit("cat", "scene:varied", {"promises_kept": 3, "promise_kept:cat.leave_card": 2, "promise_kept:cat.keep_relic": 1})
	service.progress.record_disposition("cat", "scene:kindred", "NORMAL")
	await _start()
	_check(service.progress.relationship_tier("cat") == ZodiacProgress.KINDRED and service.persuasion.state().node.content_tier == "2", "New Run uses permanent Kindred progression")
	for locale in ["en", "vi"]:
		TranslationServer.set_locale(locale)
		for viewport_size in [Vector2i(1280, 720), Vector2i(1920, 1080)]:
			root.size = viewport_size
			await _pause()
			for result in ["FULFILLED", "BROKEN", "REFUSED"]:
				_remember(result)
				for id in ["cat.t2.card_memory", "cat.t2.relic_memory", "cat.t2.change_memory"]:
					_set_node(id)
					await _fit_question(locale)
					_check(service.persuasion.state().node.bound_memory.result == result, "actual remembered outcome selects the authored exchange")
					_check(not table.dialogue.text.contains("{target}"), "remembered physical target is resolved")
					await _capture("%s_%s_%s_%d" % [id, result, locale, viewport_size.x])
			for id in ["cat.t2.boundaries", "cat.t2.sit_here", "cat.t2.your_choice"]:
				_set_node(id)
				await _fit_question(locale)
				await _capture("%s_%s_%d" % [id, locale, viewport_size.x])
			_set_node("cat.t2.your_choice")
			await _click(table.choices.get_child(0))
			await _click(table.choices.get_child(0))
			_check(table.card_select_button.visible and table.target_preview.get_child_count() == 3, "voluntary promise presents three physical cards")
			_check(table.choices.get_child(0).disabled and table.choices.get_child(2).disabled, "Accept waits for choice and Haggle cannot reroll it")
			await _capture("choice_terms_%s_%d" % [locale, viewport_size.x])
			var before := [service._rng.state, scene.deal.zodiac_boss.snapshot(), scene.deal.wallet.balance_vnd, service.persuasion.state().duplicate(true)]
			await _click(table.memory_button)
			await _capture("memory_%s_%d" % [locale, viewport_size.x])
			_check(table.history_open and table.mechanics.text.contains("3"), "permanent memory shows concrete commitments")
			table.refresh()
			_check(table.history_open, "refresh preserves the memory view")
			await _click(table.choices.get_child(0))
			_check([service._rng.state, scene.deal.zodiac_boss.snapshot(), scene.deal.wallet.balance_vnd, service.persuasion.state().duplicate(true)] == before, "memory inspection cannot mutate conversation, money, boss or RNG")
	root.size = Vector2i(1280, 720)
	TranslationServer.set_locale("en")
	# The layout matrix above seeded all branches. Judge a clean real promise below.
	service.progress.memories.clear()
	_set_node("cat.t2.your_choice")
	await _click(table.choices.get_child(0))
	await _click(table.choices.get_child(0))
	await _click(table.card_select_button)
	_check(scene.deck_screen.visible and scene.deck_screen._allowed.size() == 3, "shared browser opens for Cat's voluntary choice")
	var chosen: String = scene.deck_screen._allowed.keys()[2]
	scene.deck_screen._inspect(CardTargetQuery.resolve_ids(scene.campaign.gieo_que.persistent_deck, [chosen])[0])
	await _click(scene.deck_screen._confirm)
	_check(service.persuasion.state().selection == [chosen] and not table.choices.get_child(0).disabled, "GUI choice saves physical identity and enables Accept")
	await _click(table.choices.get_child(0))
	_check(service.daily.promises.size() == 1 and service.daily.promises[0].target_ids == [chosen], "GUI Accept reserves one exact promise")
	await _capture("chosen_promise_en")
	await _click(table.choices.get_child(0))
	table.close_conversation()
	scene.campaign._enter_phase(CampaignManager.CampaignPhase.AFTERNOON_DEAL)
	await _pause(0.5)
	_check(scene.zodiac_boss_hud.promise_label.text.contains(CardTargetQuery.resolve_ids(scene.campaign.gieo_que.persistent_deck, [chosen])[0].short_label()), "real Afternoon reminder identifies chosen card")
	service.finish_daytime_deal("afternoon")
	scene.campaign._enter_phase(CampaignManager.CampaignPhase.AFTERNOON_EVENT)
	await _pause(0.5)
	var receipt := root.get_node_or_null("LotteryReceipt")
	if receipt != null:
		await _click(receipt.find_child("CloseReceipt", true, false))
		await _pause()
	scene.event_table.unfocus_npc()
	await _click(scene.event_table._npc_layers.zodiac.button)
	await _pause()
	_check(table.shade.visible, "Afternoon conversation opens after the lottery receipt")
	_check(service.progress.memory("cat", "cat.leave_card").target_id == chosen, "Afternoon judgement remembers the player's chosen card")
	await _click(table.memory_button)
	await _capture("chosen_card_remembered_en")
	await _click(table.choices.get_child(0))
	service.progress = ZodiacProgress.new("")
	await _start()
	for _index in 3:
		await _click(table.choices.get_child(2))
		if service.persuasion.state().stage == "reaction": await _click(table.choices.get_child(0))
	await _pause()
	_check(service.persuasion.state().stage == "last_chance", "Cat has an authored Last Chance")
	await _fit_question("en")
	await _capture("last_chance_en")
	await _click(table.choices.get_child(0))
	_check(int(service.persuasion.state().patience) == 1 and service.persuasion.state().last_chance_consumed, "GUI recovery restores one Patience once")
	service.persuasion.apply_patience(-1)
	table.refresh()
	_check(service.persuasion.state().interaction_locked, "a second zero ends this visit")
	TranslationServer.set_locale("vi")
	await _start()
	for _index in 3:
		await _click(table.choices.get_child(2))
		if service.persuasion.state().stage == "reaction": await _click(table.choices.get_child(0))
	await _pause()
	await _fit_question("vi")
	await _capture("last_chance_vi")
	await _click(table.choices.get_child(1))
	_check(service.persuasion.state().interaction_locked, "failed Last Chance ends the visit")
	_check(captures.size() >= 50 or DisplayServer.get_name() == "headless", "rendered expansion evidence includes both locales and viewport sizes")
	print("CAT_EXPANSION_SCENE_SMOKE checks=%d failures=%d captures=%d" % [checks, failures.size(), captures.size()])
	for failure in failures: print("CAT_EXPANSION_FAIL " + failure)
	scene.queue_free()
	await process_frame
	quit(0 if failures.is_empty() else 1)
