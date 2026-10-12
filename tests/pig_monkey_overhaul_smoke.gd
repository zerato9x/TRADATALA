extends "res://tests/dog_monkey_presentation_smoke.gd"
## Real actions, payouts, pointer receipts, restoration and rendered boss lanes.

func flight_count() -> int:
	var fx = scene.zodiac_boss_hud.fight_fx
	return fx.flights.size() + (0 if fx.flight_kind.is_empty() else 1)

func guide_contract(label: String, guide: Control) -> void:
	check(guide.is_visible_in_tree(), label + " mechanic lane visible")
	check(scene.zodiac_boss_hud.panel.get_global_rect().encloses(guide.get_global_rect()), label + " guidance belongs to one compact boss card")
	check(guide.get_global_rect().end.y <= scene.meld_scroll.get_global_rect().position.y, label + " guidance clears Melds")
	for control: Control in [scene.campaign_money_hud.panel, scene.draw_pile_visual, scene.discard_pile_visual, scene.hand_layer, scene.meld_scroll]:
		check(not guide.get_global_rect().intersects(control.get_global_rect()), label + " clears " + control.name)
	check(guide.mouse_filter == Control.MOUSE_FILTER_IGNORE, label + " preserves pointer input")
	check(scene.deal.physical_card_accounting_is_valid(), label + " preserves physical cards")

func motion_capture(label: String) -> void:
	if not rendered or "--capture-motion" not in OS.get_cmdline_user_args(): return
	var directory := "res://.godot/pig-monkey-overhaul/motion/" + label
	DirAccess.make_dir_recursive_absolute(directory)
	for i in 18:
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png(directory + "/%02d.png" % i)
		await create_timer(0.04).timeout

func _run() -> void:
	rendered = DisplayServer.get_name() != "headless"
	capture_dir = "res://.godot/pig-monkey-overhaul/screens"
	root.size = Vector2i(1280, 720)
	scene = load("res://scenes/match.tscn").instantiate() as MatchUI
	root.add_child(scene)
	current_scene = scene
	await frames()
	scene.session.restoring = true
	scene.session.run_save = RunSave.new("user://pig-monkey-overhaul.save")
	scene.drink_manager.progress.save_path = ""
	scene.campaign.zodiac.progress = ZodiacProgress.new("")
	scene.campaign.run_seed = "pig-monkey-overhaul"
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
	var fx = hud.fight_fx
	for locale in ["en", "vi"]:
		scene.settings.set_locale(locale)
		for level in [1, 2, 3]:
			await fixture("pig", level)
			var guide = hud.mechanic_guide
			check(guide.pig_vault.visible and guide.pig_vault.held_vnd == 0, "Pig starts with an empty vault")
			check(flight_count() == 0, "Pig arrival cannot manufacture an income flight")
			var state_before := scene.deal.zodiac_boss.snapshot()
			for _i in 4: hud.refresh()
			check(state_before == scene.deal.zodiac_boss.snapshot(), "Pig visuals cannot alter the ledger or RNG")
			for extent in [Vector2i(1280, 720), Vector2i(960, 620), Vector2i(1920, 1080)]:
				root.size = extent
				await frames(5)
				guide_contract("Pig %s %d %s" % [locale, level, extent], guide)
				check(guide.body.get_content_height() + guide.body.position.y <= guide.pig_terms.position.y, "Pig amounts and terms do not overlap")
				check(guide.pig_terms.get_minimum_size().y + guide.pig_terms.position.y < guide.meter.position.y, "Pig terms clear target rail")
			root.size = Vector2i(1280, 720)
			await frames()
			var first := scene.deal.create_meld(scene.deal.hand.slice(0, 3))
			check(first.ok and not first.boss_events.is_empty(), "real Pig Meld generates boss events")
			scene._sync_all(first)
			check(flight_count() == first.boss_events.size(), "Pig flight count matches committed events")
			scene._sync_all(first)
			check(flight_count() == first.boss_events.size(), "repeated sync does not duplicate coins")
			await frames()
			check(fx.flight_amount == first.boss_events[0].amount_vnd, "flight amount is the real siphon")
			check(guide.pig_vault.held_vnd == scene.deal.zodiac_boss.data.pool_vnd, "vault projects actual held money")
			check(guide.pig_vault.target_met == (level == 1), "Pig easier target unlocks on the real first income")
			if level == 2:
				check(hud.state_label.text.contains("13.500") and guide.body.get_parsed_text().contains("45.000"), "gross progress and held money stay distinct")
				await capture("pig-%s-siphon" % locale)
				if locale == "en": await motion_capture("pig-siphon")
			await create_timer(2.5).timeout
			if level != 1:
				var second := scene.deal.create_meld(scene.deal.hand.slice(0, 3))
				scene._sync_all(second)
				check(second.boss_events.any(func(event: Dictionary): return event.action == "pig_return"), "target crossing produces a real return")
				check(flight_count() == second.boss_events.size(), "final siphon and full return both animate")
				await create_timer(1.25).timeout
				var return_deadline := Time.get_ticks_msec() + 2500
				while fx.flight_kind != "pig_return" and Time.get_ticks_msec() < return_deadline: await process_frame
				check(fx.flight_kind == "pig_return", "Pig return flows after the final siphon")
				if level == 2:
					await capture("pig-%s-return" % locale)
					if locale == "en": await motion_capture("pig-return")
			check(scene.deal.zodiac_boss.data.target_met and guide.pig_vault.target_met and guide.pig_vault.held_vnd == 0, "unlock cannot leave imaginary held money")
			await create_timer(1.3).timeout
			check(flight_count() == 0 and not fx.transfer_label.visible, "money flight cleans up")
			var saved := scene.deal.snapshot_state()
			scene.deal.restore_snapshot(saved)
			scene._sync_all()
			check(flight_count() == 0 and guide.pig_vault.target_met, "restored Pig ledger renders without replaying income")
		await fixture("pig", 3)
		var bank_before := scene.deal.wallet.balance_vnd
		scene.deal.zodiac_boss.settle(scene.deal)
		var loss_events := scene.deal.zodiac_boss.take_events()
		scene._sync_all({"ok": true, "action": "settlement", "boss_events": loss_events})
		await frames()
		check(fx.flight_kind == "pig_bank_loss" and fx.flight_amount == bank_before / 2, "hard Pig animates the actual settled bank loss")
		check(scene.deal.wallet.balance_vnd == bank_before - fx.flight_amount, "collection display agrees with wallet")
		await capture("pig-%s-failed-target" % locale)
		for level in [1, 2]:
			await fixture("monkey", level)
			var fresh = hud.fresh_guide
			check(fresh.active and fresh.available_actions.size() == 2 and fx.cue_actions.size() == 2, "Fresh begins with both scoring actions")
			for extent in [Vector2i(1280, 720), Vector2i(960, 620), Vector2i(1920, 1080)]:
				root.size = extent
				await frames(5)
				guide_contract("Fresh %s %d %s" % [locale, level, extent], fresh)
				check(fresh.row.get_combined_minimum_size().x <= fresh.size.x, "Fresh action names and shortcuts fit")
			root.size = Vector2i(1280, 720)
			var first := scene.deal.create_meld(scene.deal.hand.slice(0, 3))
			scene._sync_all(first)
			if level == 1:
				var repeat := scene.deal.create_meld(scene.deal.hand.slice(0, 3))
				scene._sync_all(repeat)
			check(fresh.available_actions == ["extension"] and fx.cue_actions == ["extension"], "actual paid cap points only to Extend")
			await capture("monkey-%s-fresh-switch" % locale)
			var miss_cards: Array[CardData] = []
			for suit in ["Hearts", "Diamonds", "Spades"]: miss_cards.append(extra_card("2", suit))
			var bank := scene.deal.wallet.balance_vnd
			var miss := scene.deal.create_meld(miss_cards)
			scene._sync_all(miss)
			check(miss.ok and miss.context.final_points == 0 and scene.deal.wallet.balance_vnd == bank, "Fresh miss remains legal and pays zero")
			check(fresh.hint.text.contains("0 VNĐ") and fx._miss_action == "new_meld", "miss warns on the actual attempted action")
			var discarded := scene.deal.discard_card(scene.deal.hand[-1])
			scene._sync_all(discarded)
			check(fresh.available_actions == ["extension"], "discard cannot fabricate a Fresh reset")
			var added: Array[CardData] = [extra_card("7", "Hearts")]
			var switched := scene.deal.extend_meld(first.meld_id, added)
			scene._sync_all(switched)
			check(switched.ok and switched.context.final_points > 0 and fresh._last == "extension" and fresh._count == 1, "paid Extension moves the real Fresh track")
			var before := scene.deal.zodiac_boss.snapshot()
			for _i in 3: hud.refresh()
			check(before == scene.deal.zodiac_boss.snapshot(), "Fresh cues cannot modify eligibility")
			scene.deal.current_phase = 2
			scene.deal.zodiac_boss.begin_phase(scene.deal)
			scene._sync_all()
			check(fresh._count == 0 and fresh.available_actions.size() == 2, "real phase reset clears Fresh beats")
		await fixture("monkey", 3)
		scene.deal.zodiac_boss.data.sequence = ["extension", "new_meld", "discard"]
		scene._sync_all()
		await frames()
		check(not hud.fresh_guide.active and fx.cue_actions == ["extension"], "Dance uses its required action only")
		var miss := scene.deal.create_meld(scene.deal.hand.slice(0, 3))
		scene._sync_all(miss)
		check(hud.dance_guide.hint.text.contains("0 VNĐ") and not hud.dance_guide.has_node("CompletedDanceStep"), "Dance miss cannot invent completion")
		await capture("monkey-%s-dance-miss" % locale)
		var added: Array[CardData] = [extra_card("7", "Hearts")]
		var extended := scene.deal.extend_meld(miss.meld_id, added)
		scene._sync_all(extended)
		check(hud.dance_guide.has_node("CompletedDanceStep") and fx.cue_actions == ["new_meld"], "conductor and table cue move on paid action")
		await capture("monkey-%s-dance-step" % locale)
		if locale == "en": await motion_capture("monkey-step")
		await create_timer(0.6).timeout
		var matched := scene.deal.create_meld(scene.deal.hand.slice(0, 3))
		scene._sync_all(matched)
		check(fx.cue_actions == ["discard"], "discard step highlights discard rather than a scoring action")
		await create_timer(0.6).timeout
		matched = scene.deal.discard_card(scene.deal.hand[-1])
		scene._sync_all(matched)
		check(scene.deal.zodiac_boss.data.sequence_index == 0 and hud.dance_guide.hint.text.contains("✓"), "committed discard completes and wraps the loop")
		await capture("monkey-%s-dance-loop" % locale)
		if locale == "en": await motion_capture("monkey-loop")
		for extent in [Vector2i(1280, 720), Vector2i(960, 620), Vector2i(1920, 1080)]:
			root.size = extent
			await frames(5)
			guide_contract("Dance %s %s" % [locale, extent], hud.dance_guide)
			check_guide("Dance %s %s" % [locale, extent])
			if extent == Vector2i(960, 620): await capture("monkey-%s-small" % locale)
		root.size = Vector2i(1280, 720)
		await fixture("pig", 2)
		for card in scene.deal.hand.slice(0, 3): scene._on_card_pressed(card)
		await click(scene.ha_button)
		var deadline := Time.get_ticks_msec() + 5000
		while not scene.score_overlay.visible and Time.get_ticks_msec() < deadline: await process_frame
		check(scene.score_overlay.visible and flight_count() > 0, "pointer Pig Meld enters the real money receipt")
		await frames()
		var held_time: float = fx.flight_time
		await create_timer(0.1).timeout
		check(not fx.is_visible_in_tree() and fx.flight_time == held_time, "Pig choreography waits through the receipt")
		scene.money_presentation.request_fast_forward()
		while scene.money_playback.running and Time.get_ticks_msec() < deadline: await process_frame
		await frames()
		check(fx.is_visible_in_tree() and flight_count() > 0, "Pig choreography resumes after receipt")
		var before := scene.deal.zodiac_boss.snapshot()
		scene.modal_overlay.show()
		await frames()
		check(not fx.is_visible_in_tree() and flight_count() == 0, "modal clears flights and action cues")
		scene.modal_overlay.hide()
		await frames()
		check(before == scene.deal.zodiac_boss.snapshot() and flight_count() == 0, "return from modal cannot replay money")
	await fixture("dragon", 2)
	check(not hud.mechanic_guide.pig_footer.visible and not hud.mechanic_guide.pig_vault.visible, "another active mechanic lane cannot inherit Pig's footer")
	check(hud.mechanic_guide.get_global_rect().encloses(hud.mechanic_guide.meter.get_global_rect()), "boss switch keeps the next mechanic's target rail inside its lane")
	await fixture("dog", 2)
	check(not fx.visible and not hud.fresh_guide.active and not hud.mechanic_guide.active, "boss switch clears pair-specific visuals")
	check(hud.panel.size.y <= 36 and hud.panel.get_global_rect().end.y < scene.meld_scroll.global_position.y, "boss switch returns unused body space to the Meld lane")
	scene.menu_layer.show()
	await frames()
	check(not hud.visible, "menu clears boss choreography")
	print("PIG_MONKEY_OVERHAUL_SMOKE checks=%d failures=%d rendered=%s" % [checks, failures.size(), rendered])
	scene.queue_free()
	await frames()
	quit(0 if failures.is_empty() else 1)
