extends "res://tests/roster_presentation_smoke.gd"
## Real Deal commits prove the new pair's choreography and authority boundaries.
func fixture(id: String, level: int, phase: int = 1) -> void:
	scene.zodiac_boss_hud.pair_fight_fx.sync({}, "")
	scene.zodiac_boss_hud.mechanic_guide.clear_pair_effects()
	await super.fixture(id, level, phase)

func pair_layout(label: String) -> void:
	table_contract(label)
	var guide = scene.zodiac_boss_hud.mechanic_guide
	check(guide.get_global_rect().encloses(guide.pair_art.get_global_rect()), label + " mechanic artwork fits")
	check(guide.body.position.y + guide.body.get_content_height() < (guide.meter.position.y if guide.meter.visible else guide.goat_staff.position.y), label + " complete instructions clear mechanic rail")
	if guide.pair_footer.visible:
		check(guide.get_global_rect().encloses(guide.pair_footer.get_global_rect()), label + " complete reaction fits")
		check(guide.pair_footer.get_minimum_size().y <= guide.pair_footer.size.y, label + " reaction is not cropped")
	check(guide.mouse_filter == Control.MOUSE_FILTER_IGNORE and scene.zodiac_boss_hud.pair_fight_fx.mouse_filter == Control.MOUSE_FILTER_IGNORE, label + " animations preserve table input")
	if guide.goat_staff.visible:
		check(guide.get_global_rect().encloses(guide.goat_staff.get_global_rect()), label + " all thirteen ranks fit")
		check(guide.goat_staff.ranks.size() == 13, label + " rank melody is complete")

func motion_capture(label: String) -> void:
	if not rendered or "--capture-motion" not in OS.get_cmdline_user_args(): return
	var directory := "res://.godot/horse-goat-overhaul/motion/" + label
	DirAccess.make_dir_recursive_absolute(directory)
	for i in 18:
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png(directory + "/%02d.png" % i)
		await create_timer(0.04).timeout

func capture(label: String) -> void:
	# Keep ambient desktop pointer hover from putting a tooltip over evidence.
	var motion := InputEventMouseMotion.new()
	motion.position = Vector2(8, 300)
	motion.global_position = motion.position
	motion.relative = Vector2(20, 20)
	root.push_input(motion, true)
	await frames()
	await super.capture(label)

func rank_set(rank: String) -> Array[CardData]:
	var cards: Array[CardData] = []
	for suit in ["Clubs", "Diamonds", "Spades"]: cards.append(extra_card(rank, suit))
	return cards

func _run() -> void:
	rendered = DisplayServer.get_name() != "headless"
	capture_dir = "res://.godot/horse-goat-overhaul/screens"
	root.size = Vector2i(1280, 720)
	scene = load("res://scenes/match.tscn").instantiate() as MatchUI
	root.add_child(scene)
	current_scene = scene
	await frames()
	scene.session.restoring = true
	scene.session.run_save = RunSave.new("user://horse-goat-overhaul.save")
	scene.drink_manager.progress.save_path = ""
	scene.campaign.zodiac.progress = ZodiacProgress.new("")
	scene.campaign.run_seed = "horse-goat-overhaul"
	scene.campaign.current_day_index = 0
	scene.campaign.difficulty_progress.unlocked = 2
	scene.campaign.select_difficulty(2)
	scene.campaign.gieo_que.reset_campaign()
	scene.game_started = true
	scene.menu_layer.hide()
	scene.game_layer.position = Vector2.ZERO
	scene.game_layer.show()
	scene.event_table.table_state = EventTableController.TABLE_STATE_DEAL
	scene.event_table._finish_event_exit()
	await create_timer(0.6).timeout
	var hud = scene.zodiac_boss_hud
	var fx = hud.pair_fight_fx
	var guide = hud.mechanic_guide
	for locale in ["en", "vi"]:
		scene.settings.set_locale(locale)
		for level in [1, 2, 3]:
			await fixture("horse", level)
			check(guide.pair_art.kind == "horse" and not guide.goat_staff.visible and fx.cue_actions == ["new_meld", "extension"], "Horse starts with both legal pair choices")
			var before := scene.deal.zodiac_boss.snapshot()
			for _i in 4: scene._sync_all(); hud.refresh()
			check(before == scene.deal.zodiac_boss.snapshot() and fx.effect_kind.is_empty(), "Horse refresh cannot choose a card or fabricate hoofbeats")
			for extent in [Vector2i(1280, 720), Vector2i(960, 620), Vector2i(1920, 1080)]:
				root.size = extent
				await frames(5)
				pair_layout("Horse %s %d %s" % [locale, level, extent])
			root.size = Vector2i(1280, 720)
			await frames()
			var first := scene.deal.create_meld(scene.deal.hand.slice(0, 3))
			scene._sync_all(first)
			check(first.ok and guide.pair_art.pair_count == 1 and fx.cue_actions == ["new_meld"], "first committed Meld chooses the Horse pair")
			check(guide.meter.material.get_shader_parameter("progress") == 0.5, "Horse shader reads exact half pair")
			var seven := extra_card("7", "Hearts")
			scene._sync_all()
			var mixed := scene.deal.extend_meld(first.meld_id, [seven])
			scene._sync_all(mixed)
			check(mixed.ok and mixed.context.final_points > 0 and scene.deal.zodiac_boss.data.pair_count == 1 and fx.effect_kind == "horse_mixed", "mixing types remains legal and paid without completing the pair")
			var second := scene.deal.create_meld(rank_set("9"))
			scene._sync_all(second)
			check(second.ok and guide.pair_art.pair_count == 2 and fx.cue_actions == ["discard"], "two real matching actions protect the discard")
			await capture("horse-%s-complete" % locale)
			if locale == "en" and level == 2: await motion_capture("horse-complete")
			var requested := scene.deal.hand[-1]
			var discard := scene.deal.discard_card(requested)
			scene._sync_all(discard)
			check(discard.ok and discard.card == requested and not discard.forced_discard and fx.effect_kind == "horse_protected", "completed pair celebrates only the actual protected discard")
			check(scene.deal.zodiac_boss.data.pair_count == 0 and guide.pair_art.pair_count == 0, "new Horse turn clears the pair")
			check(scene.deal.phase_discard_limit() == (2 if level == 3 else 4), "hard Horse uses native shortened turn limit")
			await fixture("horse", level)
			if level == 1:
				discard = scene.deal.discard_card(scene.deal.hand[-1])
				scene._sync_all(discard)
				check(discard.boss_events.any(func(event: Dictionary): return event.action == "horse_grace") and fx.effect_kind == "horse_grace" and scene.deal.zodiac_boss.data.pair_grace == 0, "pleased Horse consumes exactly the real grace")
			requested = scene.deal.hand[-1]
			discard = scene.deal.discard_card(requested)
			scene._sync_all(discard)
			check(discard.ok and discard.forced_discard and fx.effect_kind == "horse_forced", "incomplete pair animates native forced discard")
			check(fx.effect_card_id == discard.card.unique_id and fx.forced_card.texture.resource_path == discard.card.texture_path(), "forced flight uses the committed physical card")
			check(discard.boss_events.any(func(event: Dictionary): return event.action == "horse_forced_discard" and event.card_id == fx.effect_card_id), "card flight agrees with boss event")
			var stable := scene.deal.snapshot_state()
			scene._sync_all(discard)
			check(fx.effect_time == 0, "duplicate sync does not advance or restart forced flight")
			await frames()
			check(stable == scene.deal.snapshot_state(), "forced animation cannot reroll or alter zones, wallet or rules")
			await capture("horse-%s-forced" % locale)
			if locale == "en" and level == 2: await motion_capture("horse-forced")
			if level == 2:
				root.size = Vector2i(960, 620)
				await frames(5)
				pair_layout("Horse forced %s small" % locale)
				await capture("horse-%s-small" % locale)
				root.size = Vector2i(1280, 720)
			await create_timer(1.5).timeout
			check(fx.effect_kind.is_empty() and not fx.forced_card.visible, "forced card ghost cleans up")
			check(scene.deal.physical_card_accounting_is_valid(), "Horse effects preserve all physical cards")
		# A genuine pair of extensions also protects the requested discard.
		await fixture("horse", 1)
		var first := scene.deal.create_meld(scene.deal.hand.slice(0, 3))
		scene._sync_all(first)
		scene._sync_all(scene.deal.discard_card(scene.deal.hand[-1]))
		for rank in ["7", "8"]:
			var card := extra_card(rank, "Hearts")
			scene._sync_all()
			scene._sync_all(scene.deal.extend_meld(first.meld_id, [card]))
		check(scene.deal.zodiac_boss.data.required_action == "extension" and guide.pair_art.pair_count == 2, "extension pair counts the correct legal action")
		var discard := scene.deal.discard_card(scene.deal.hand[-1])
		scene._sync_all(discard)
		check(not discard.forced_discard and fx.effect_kind == "horse_protected", "extension pair retains the requested card")
		# Tra Da's extra discard does not spend grace or force another choice.
		await fixture("horse", 2)
		scene.deal.set_current_drink(DrinkCatalog.TRA_DA)
		scene._sync_all(scene.deal.discard_card(scene.deal.hand[-1]))
		fx.clear_effects()
		var requested := scene.deal.hand[-1]
		discard = scene.deal.discard_card(requested)
		scene._sync_all(discard)
		check(discard.discard_kind == DiscardRecord.KIND_DRINK_EXTRA and discard.card == requested and fx.effect_kind.is_empty(), "optional extra discard has no invented Horse punishment")
		await fixture("horse", 3)
		for _i in 2: scene._sync_all(scene.deal.discard_card(scene.deal.hand[-1]))
		check(scene.deal.state == DealState.STATE_FINAL_COMMIT_WINDOW and fx.cue_actions == ["new_meld", "extension", "settle"], "Horse final window guides legal scoring and native settlement")
		check(guide.body.get_parsed_text().contains(ZodiacCatalog.words("FINAL COMMIT", "HẠ CUỐI")), "Horse final window cannot demand a nonexistent discard pair")
		for level in [1, 2, 3]:
			await fixture("goat", level)
			check(guide.goat_staff.visible and guide.goat_staff.expected_rank == 0 and fx.effect_kind.is_empty(), "Goat arrival allows the actual first note without fake melody")
			for extent in [Vector2i(1280, 720), Vector2i(960, 620), Vector2i(1920, 1080)]:
				root.size = extent
				await frames(5)
				pair_layout("Goat %s %d %s" % [locale, level, extent])
			root.size = Vector2i(1280, 720)
			await frames()
			var notes: Array[CardData] = scene.deal.hand.slice(0, 3)
			if level == 3: notes = [extra_card("3", "Hearts"), extra_card("4", "Hearts"), extra_card("5", "Hearts")]
			first = scene.deal.create_meld(notes)
			scene._sync_all(first)
			check(first.ok and first.context.final_points > 0 and fx.effect_kind == "goat_notes", "Goat animates only a paid committed melody")
			check(fx.played_notes == ([3, 4, 5] if level == 3 else [4, 5, 6]), "musical flight depicts unique committed ranks")
			check(guide.goat_staff.expected_rank == (6 if level == 3 else 7), "staff next note reads native payout policy")
			if level == 3:
				check(not guide.goat_staff.waiting and not guide.pair_art.waiting and guide.goat_staff.accepted == [6, 7, 8] and fx.cue_actions == ["new_meld", "extension"], "three-rank window keeps an odd first-rank option on the hard odd turn")
				await capture("goat-%s-parity-wait" % locale)
				if locale == "en": await motion_capture("goat-wait")
				scene._sync_all(scene.deal.discard_card(scene.deal.hand[-1]))
				check(not guide.goat_staff.waiting and fx.cue_actions == ["new_meld", "extension"], "mandatory discard opens actual even turn")
			var next_card := extra_card("6" if level == 3 else "7", "Hearts")
			scene._sync_all()
			var extension := scene.deal.extend_meld(first.meld_id, [next_card])
			scene._sync_all(extension)
			check(extension.ok and extension.context.final_points > 0 and fx.played_notes == [next_card.rank_index], "extension melody includes added cards only")
			check(scene.card_table.meld_views[first.meld_id]._score.text.contains(VndWallet.format_vnd(extension.earned_vnd)), "Goat Meld receipt shows actual last extension payout")
			var saved_next: int = scene.deal.zodiac_boss.data.expected_rank
			var miss := scene.deal.create_meld(rank_set("K"))
			scene._sync_all(miss)
			if level == 1:
				check(miss.context.final_points > 0 and scene.deal.zodiac_boss.data.rhythm_grace == 0 and guide.pair_footer.text.contains(ZodiacCatalog.words("Grace used", "Đã dùng ân hạn")), "Goat celebrates the real single forgiven mistake")
				miss = scene.deal.create_meld(rank_set("2"))
				saved_next = 3
				scene._sync_all(miss)
			check(miss.ok and miss.context.suppression_reason == "goat_rank_miss" and miss.context.final_points == 0, "wrong melody remains legal with native zero payout")
			check(scene.deal.zodiac_boss.data.expected_rank == saved_next and guide.goat_staff.expected_rank == saved_next and fx.played_notes.is_empty() and fx.effect_kind == "goat_miss", "miss cannot advance or animate imaginary played notes")
			check(scene.card_table.meld_views[miss.meld_id]._score.text.contains("0 VNĐ") and not scene.card_table.meld_views[miss.meld_id]._score.text.contains("81.000"), "Goat miss cannot advertise theoretical value as paid money")
			await capture("goat-%s-miss" % locale)
			if level == 2:
				root.size = Vector2i(960, 620)
				await frames(5)
				pair_layout("Goat miss %s small" % locale)
				await capture("goat-%s-small" % locale)
				root.size = Vector2i(1280, 720)
			var stable := scene.deal.snapshot_state()
			for _i in 3: scene._sync_all(); hud.refresh()
			await frames()
			check(stable == scene.deal.snapshot_state(), "Goat refresh cannot alter payouts, RNG or rank progression")
			await create_timer(1.7).timeout
			scene.deal.restore_snapshot(stable)
			scene._sync_all()
			check(fx.effect_kind.is_empty() and guide.goat_staff._played.is_empty(), "restored melody renders state without replaying a success")
			check(scene.card_table.meld_views[miss.meld_id]._score.text.contains("0 VNĐ"), "restored Goat receipt retains recorded zero payout")
		# King wraps to Ace through the real policy, with a visible full staff.
		await fixture("goat", 2)
		first = scene.deal.create_meld(rank_set("K"))
		scene._sync_all(first)
		check(first.context.final_points > 0 and guide.goat_staff.expected_rank == 3 and fx.played_notes == [13], "King/Ace/Two window advances to Three/Four/Five")
		await capture("goat-%s-wrap" % locale)
		if locale == "en": await motion_capture("goat-wrap")
		# Pointer actions use the real receipt; all effects wait and resume.
		await fixture("goat", 2)
		for card in scene.deal.hand.slice(0, 3): scene._on_card_pressed(card)
		await click(scene.ha_button)
		var deadline := Time.get_ticks_msec() + 5000
		while not scene.score_overlay.visible and Time.get_ticks_msec() < deadline: await process_frame
		check(scene.score_overlay.visible and fx.effect_kind == "goat_notes", "pointer Meld commits Goat melody and opens real receipt")
		await frames()
		var held_time: float = fx.effect_time
		var held_notice: float = guide._pair_notice
		await create_timer(0.1).timeout
		check(not fx.is_visible_in_tree() and fx.effect_time == held_time and guide._pair_notice == held_notice, "receipt freezes melody flight and reaction")
		scene.money_presentation.request_fast_forward()
		while scene.money_playback.running and Time.get_ticks_msec() < deadline: await process_frame
		await frames()
		check(fx.is_visible_in_tree() and not fx.effect_kind.is_empty(), "melody resumes after actual receipt")
		await capture("goat-%s-melody" % locale)
		if locale == "en": await motion_capture("goat-melody")
		var policy := scene.deal.zodiac_boss.snapshot()
		scene.modal_overlay.show()
		await frames()
		check(not fx.is_visible_in_tree() and fx.effect_kind.is_empty() and guide._pair_notice == 0 and guide.goat_staff._played.is_empty(), "modal clears transient notes and reactions")
		scene.modal_overlay.hide()
		await frames()
		check(policy == scene.deal.zodiac_boss.snapshot() and fx.effect_kind.is_empty(), "return from modal cannot invent a melody")
		await fixture("goat", 1, 2)
		check(guide.goat_staff.expected_rank == 0 and scene.deal.zodiac_boss.data.rhythm_grace == 1 and fx.effect_kind.is_empty(), "new phase projects actual note and grace reset")
		await fixture("goat", 3)
		first = scene.deal.create_meld([extra_card("3", "Hearts"), extra_card("4", "Hearts"), extra_card("5", "Hearts")])
		scene._sync_all(first)
		for rank in ["6", "7", "8"]:
			scene._sync_all(scene.deal.discard_card(scene.deal.hand[-1]))
			var card := extra_card(rank, "Hearts")
			scene._sync_all(scene.deal.extend_meld(first.meld_id, [card]))
		scene._sync_all(scene.deal.discard_card(scene.deal.hand[-1]))
		check(scene.deal.state == DealState.STATE_FINAL_COMMIT_WINDOW and not guide.goat_staff.waiting and fx.cue_actions == ["new_meld", "extension", "settle"], "Goat final window retains scoring options and settlement")
		await create_timer(1.7).timeout
		check(guide.pair_footer.text.contains(ZodiacCatalog.words("FINAL COMMIT", "HẠ CUỐI")), "Goat final window shows the current state")
		await capture("goat-%s-final-wait" % locale)
	await fixture("pig", 2)
	check(not fx.visible and not guide.pair_art.visible and not guide.goat_staff.visible and not guide.pair_footer.visible and guide.pig_vault.visible, "Pig retains its own vault without Horse or Goat layers")
	await fixture("dragon", 2)
	check(guide.get_global_rect().encloses(guide.meter.get_global_rect()), "boss switch restores generic meter geometry")
	await fixture("dog", 2)
	check(not fx.visible and not guide.active and hud.panel.size.y <= 36 and hud.panel.get_global_rect().end.y < scene.meld_scroll.global_position.y, "boss switch clears pair effects and gives the empty lane back to Melds")
	scene.menu_layer.show()
	await frames()
	check(not hud.visible and fx.effect_kind.is_empty(), "menu clears pair choreography")
	print("HORSE_GOAT_OVERHAUL_SMOKE checks=%d failures=%d rendered=%s" % [checks, failures.size(), rendered])
	scene.queue_free()
	await frames()
	quit(0 if failures.is_empty() else 1)
