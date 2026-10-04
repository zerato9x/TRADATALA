extends "res://tests/boss_presentation_smoke.gd"
## Pair-specific runtime evidence: committed actions, restore, input and rendering.

func extra_card(rank: String, suit: String) -> CardData:
	for card in scene.deal.hand:
		if card.rank == rank and card.suit == suit: return card
	var card := scene.deal._take_tutorial_card(rank, suit)
	scene.deal.hand.append(card)
	return card

func check_guide(label: String) -> void:
	var hud = scene.zodiac_boss_hud
	var guide = hud.dance_guide
	check(guide.is_visible_in_tree(), label + " full sequence is visible")
	check(guide.steps.size() == 3, label + " all three actions shown")
	check(guide.row.get_combined_minimum_size().x <= guide.size.x, label + " full localized sequence fits")
	check(guide.get_global_rect().end.y <= scene.meld_scroll.get_global_rect().position.y, label + " text sits above Melds")
	for surface: Control in [hud.panel, scene.campaign_money_hud.panel, scene.draw_pile_visual, scene.discard_pile_visual, scene.hand_layer, scene.meld_scroll]:
		check(not guide.get_global_rect().intersects(surface.get_global_rect()), label + " text clears " + surface.name)
	check(guide.mouse_filter == Control.MOUSE_FILTER_IGNORE and guide.steps.all(func(step: Label): return step.mouse_filter == Control.MOUSE_FILTER_IGNORE), label + " guide passes pointer input")
	check(guide.get_children().all(func(child: Node): return not child is PanelContainer and not child is Panel), label + " no frame or background")
	check(guide.steps[int(scene.deal.zodiac_boss.data.sequence_index)].material is ShaderMaterial, label + " current action has glyph shader")
	for i in guide.steps.size():
		check(guide.steps[i].text.contains(ZodiacCatalog.action_label(scene.deal.zodiac_boss.data.sequence[i]).to_upper()), label + " sequence order follows boss " + str(i))

func _run() -> void:
	rendered = DisplayServer.get_name() != "headless"
	capture_dir = "res://.godot/dog-monkey-presentation/screens"
	root.size = Vector2i(1280, 720)
	scene = load("res://scenes/match.tscn").instantiate() as MatchUI
	root.add_child(scene)
	current_scene = scene
	await frames()
	scene.get_node("TitleScreen").queue_free()
	scene._restoring_run = true
	scene.run_save = RunSave.new("user://dog-monkey-presentation.save")
	scene.drink_manager.progress.save_path = ""
	scene.campaign.zodiac.progress = ZodiacProgress.new("")
	scene.campaign.run_seed = "dog-monkey-presentation"
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
	var hud = scene.zodiac_boss_hud
	for locale in ["en", "vi"]:
		scene.settings.set_locale(locale)
		for level in [1, 2, 3]:
			await fixture("dog", level)
			var result := scene.deal.create_meld(scene.deal.hand.slice(0, 3))
			check(result.ok, "Dog first Meld commits")
			scene._sync_all(result)
			await frames()
			var loyal: MeldView = scene.meld_views[result.meld_id]
			check(loyal.has_node("DogLoyalGuard") and loyal.get_node("DogLoyalGuard").visible, "Dog highlights authoritative loyal Meld")
			check(loyal.get_node("DogLoyalGuard").material is ShaderMaterial and loyal.get_node("DogLoyalGuard").mouse_filter == Control.MOUSE_FILTER_IGNORE, "Dog guard is a separate input-free shader")
			check(hud.evening_overlay.texture.resource_path == ZodiacCatalog.sprite_path("dog", true), "Dog uses supplied overlay")
			check(not hud.dance_guide.visible and hud.state_label.material == null, "Dog does not borrow Monkey effects")
			var other := scene.deal.create_meld(scene.deal.hand.slice(0, 3))
			check(other.ok == (level != 3), "Dog keeps severity legality")
			if other.ok:
				scene._sync_all(other)
				check(not scene.meld_views[other.meld_id].has_node("DogLoyalGuard"), "non-loyal Meld gets no green effect")
			var added: Array[CardData] = [extra_card("7", "Hearts")]
			scene._sync_all()
			scene._on_card_pressed(added[0])
			check(loyal._hint.text == scene.tr("MELD_READY_EXTEND"), "green loyalty preserves legal Extension hint")
			var extended := scene.deal.extend_meld(result.meld_id, added)
			check(extended.ok and extended.context.final_points > 0, "Dog loyal Extension still scores")
			scene._sync_all(extended)
			check(loyal.get_node("DogLoyalGuard").visible, "loyal guard follows Extensions")
			await capture("dog-%s-tier%d-loyal" % [locale, level])
			var before := scene.deal.zodiac_boss.snapshot()
			for _i in 3: scene._sync_all()
			check(before == scene.deal.zodiac_boss.snapshot(), "Dog presentation never changes policy or RNG")
			var saved := scene.deal.snapshot_state()
			scene.deal.restore_snapshot(saved)
			scene._sync_all()
			check(loyal.get_node("DogLoyalGuard").visible, "Dog restored loyalty renders immediately")
			scene.deal.current_phase = 2
			scene.deal.zodiac_boss.begin_phase(scene.deal)
			scene._sync_all()
			check(not loyal.get_node("DogLoyalGuard").visible, "phase reset removes stale loyal effect")
			check(scene.deal.physical_card_accounting_is_valid(), "Dog visuals preserve physical cards")
		for level in [1, 2]:
			await fixture("monkey", level)
			check(hud.panel.is_ancestor_of(hud.state_label) and hud.state_label.text.contains("FRESH!") and hud.state_label.text.contains("0/%d" % level_to_cap(level)), "Fresh starts in top-left boss window")
			check(hud.state_label.material is ShaderMaterial and not hud.dance_guide.visible, "Fresh shader belongs to counter only")
			var first := scene.deal.create_meld(scene.deal.hand.slice(0, 3))
			scene._sync_all(first)
			check(hud.state_label.text.contains("1/%d" % level_to_cap(level)), "Fresh shows first paid action")
			var second := scene.deal.create_meld(scene.deal.hand.slice(0, 3))
			scene._sync_all(second)
			check(hud.state_label.text.contains("%d/%d" % [level_to_cap(level), level_to_cap(level)]), "Fresh respects severity cap and unpaid miss")
			check(second.context.final_points > 0 if level == 1 else second.context.final_points == 0, "Fresh payouts retain rules")
			var count: int = scene.deal.zodiac_boss.data.repeat_count
			var discarded := scene.deal.discard_card(scene.deal.hand[-1])
			scene._sync_all(discarded)
			check(scene.deal.zodiac_boss.data.repeat_count == count and hud.state_label.text.contains("%d/%d" % [count, level_to_cap(level)]), "discard does not invent a Fresh reset")
			var added: Array[CardData] = [extra_card("7", "Hearts")]
			var switched := scene.deal.extend_meld(first.meld_id, added)
			scene._sync_all(switched)
			check(switched.ok and hud.state_label.text.contains(ZodiacCatalog.action_label("extension")) and hud.state_label.text.contains("1/%d" % level_to_cap(level)), "Fresh switches to actual paid Extension")
			check(hud.state_label.get_theme_font("font").get_string_size(hud.state_label.text, HORIZONTAL_ALIGNMENT_LEFT, -1, hud.state_label.get_theme_font_size("font_size")).x <= hud.state_label.size.x, "Fresh counter fits without truncation in " + locale)
			await capture("monkey-%s-tier%d-fresh" % [locale, level])
			scene.deal.current_phase = 2
			scene.deal.zodiac_boss.begin_phase(scene.deal)
			scene._sync_all()
			check(hud.state_label.text.contains("0/%d" % level_to_cap(level)), "Fresh phase reset appears immediately")
		await fixture("monkey", 3)
		# Deterministic fixture exercises a miss, then all three correct actions.
		scene.deal.zodiac_boss.data.sequence = ["extension", "new_meld", "discard"]
		scene._sync_all()
		await frames()
		var guide = hud.dance_guide
		check_guide(locale)
		var original_top: float = hud._meld_top_offset
		var miss := scene.deal.create_meld(scene.deal.hand.slice(0, 3))
		scene._sync_all(miss)
		check(miss.ok and miss.context.final_points == 0 and scene.deal.zodiac_boss.data.sequence_index == 0, "Dance miss remains legal and cannot advance")
		check(not guide.has_node("CompletedDanceStep"), "Dance miss cannot celebrate")
		var added: Array[CardData] = [extra_card("7", "Hearts")]
		scene._sync_all()
		var matched := scene.deal.extend_meld(miss.meld_id, added)
		scene._sync_all(matched)
		check(matched.ok and scene.deal.zodiac_boss.data.sequence_index == 1, "paid Extension advances Dance")
		check(guide.has_node("CompletedDanceStep") and guide.get_node("CompletedDanceStep/MonkeyStepBurst").material is ShaderMaterial, "correct action animates with text-local burst")
		await frames()
		check(guide.steps[1].material is ShaderMaterial and guide.steps[0].material == null, "shader moves to next required action")
		await capture("monkey-%s-dance-completed" % locale)
		await create_timer(0.6).timeout
		check(not guide.has_node("CompletedDanceStep") and guide._tweens.is_empty(), "completion cleans up animation")
		matched = scene.deal.create_meld(scene.deal.hand.slice(0, 3))
		scene._sync_all(matched)
		check(matched.ok and scene.deal.zodiac_boss.data.sequence_index == 2, "paid Meld advances Dance")
		await create_timer(0.6).timeout
		matched = scene.deal.discard_card(scene.deal.hand[-1])
		scene._sync_all(matched)
		check(matched.ok and scene.deal.zodiac_boss.data.sequence_index == 0 and guide.has_node("CompletedDanceStep"), "required discard celebrates and wraps sequence")
		await create_timer(0.6).timeout
		var snapshot := scene.deal.snapshot_state()
		scene.deal.restore_snapshot(snapshot)
		scene._sync_all()
		var before := scene.deal.zodiac_boss.snapshot()
		for _i in 3: scene._sync_all(); hud.refresh()
		check(before == scene.deal.zodiac_boss.snapshot() and not guide.has_node("CompletedDanceStep"), "refresh and restore cannot reroll or fabricate completion")
		check(scene.deal.physical_card_accounting_is_valid(), "Dance preserves all physical cards")
		for viewport in [Vector2i(1280, 720), Vector2i(960, 620), Vector2i(1920, 1080), Vector2i(2548, 1368)]:
			root.size = viewport
			await frames(5)
			check_guide("%s %s" % [locale, viewport])
			layout_contract("Dance %s %s" % [locale, viewport])
			await capture("monkey-%s-dance-%dx%d" % [locale, viewport.x, viewport.y])
		root.size = Vector2i(1280, 720)
		await click(hud.detail_button)
		check(hud.details_panel.visible and hud.details.text == ZodiacCatalog.rule_text("monkey", 3), "Monkey rule drawer still works")
		check(not guide.visible, "rule inspection clears floating sequence")
		hud._close_details()
		scene.modal_overlay.show()
		await frames()
		check(not guide.visible and guide._effects.is_empty(), "modal clears guide and effects")
		scene.modal_overlay.hide()
		await frames()
		check(guide.visible, "return to table restores actual required action")
		scene.menu_layer.show()
		await frames()
		check(not hud.visible and scene.meld_scroll.offset_top == original_top, "menu clears guide and restores Meld geometry")
		scene.menu_layer.hide()
		await fixture("dog", 2)
		check(not guide.visible and scene.meld_scroll.offset_top == original_top and hud.state_label.material == null, "boss switch clears Monkey effects and lane")
		# Pointer input goes through the real scoring queue, including its overlay.
		await fixture("monkey", 3)
		scene.deal.zodiac_boss.data.sequence = ["new_meld", "extension", "discard"]
		scene._sync_all()
		for card in scene.deal.hand.slice(0, 3): scene._on_card_pressed(card)
		check(not scene.ha_button.disabled, "Dance guide preserves legal Meld button")
		await click(scene.ha_button)
		check(scene.deal.zodiac_boss.data.sequence_index == 1, "pointer Meld advances actual Dance rule")
		check(guide.has_node("CompletedDanceStep"), "pointer scoring starts completion animation")
		var deadline := Time.get_ticks_msec() + 4000
		while not scene.money_presentation.presentation_active and Time.get_ticks_msec() < deadline: await process_frame
		check(scene.money_presentation.presentation_active and scene.score_overlay.visible, "pointer Meld reaches real money ceremony")
		await frames()
		check(not guide.is_visible_in_tree() and guide.steps[1].material is ShaderMaterial, "receipt clears floating text while preserving actual next action")
		check(guide.has_node("CompletedDanceStep") and guide._tweens.all(func(tween: Tween): return not tween.is_running()), "completion pauses through real money receipt")
		var policy_before := scene.deal.zodiac_boss.snapshot()
		scene.money_presentation.request_fast_forward()
		while scene.money_queue_running and Time.get_ticks_msec() < deadline: await process_frame
		check(not scene.money_queue_running and policy_before == scene.deal.zodiac_boss.snapshot(), "money completion preserves Monkey state")
		await frames()
		check(guide.is_visible_in_tree() and guide.has_node("CompletedDanceStep"), "completion resumes on return to table")
		if rendered:
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png(capture_dir + "/monkey-%s-dance-pointer-burst.png" % locale)
		await create_timer(0.6).timeout
		check(guide.steps.all(func(step: Label): return step.self_modulate.a == 1.0), "completion restores all persistent sequence text")
		# Cancel an effect during a modal: the underlying text must return too.
		var pointer_added: Array[CardData] = [extra_card("7", "Hearts")]
		var extension := scene.deal.extend_meld(scene.deal.melds[0].meld_id, pointer_added)
		scene._sync_all(extension)
		check(guide.has_node("CompletedDanceStep"), "next committed Extension starts another effect")
		scene.modal_overlay.show()
		await frames()
		check(guide.steps.all(func(step: Label): return step.self_modulate.a == 1.0) and guide._effects.is_empty(), "cancelled completion restores underlying labels")
		scene.modal_overlay.hide()
	await fixture("", 2)
	check(not hud.visible and scene.meld_scroll.offset_top == hud._meld_top_offset, "ordinary table retains geometry")
	scene.queue_free()
	await create_timer(0.25).timeout
	print("DOG_MONKEY_PRESENTATION_SMOKE checks=%d failures=%d rendered=%s" % [checks, failures.size(), rendered])
	quit(0 if failures.is_empty() else 1)

func level_to_cap(level: int) -> int:
	return int(ZodiacCatalog.tuning("monkey", "allowed_repeats", level))
