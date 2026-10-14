extends "res://tests/front_end_forms_smoke.gd"
## Count-driven pile depth, real archive clicks and stable physical card identities.

func move_pointer(point: Vector2) -> void:
	var event := InputEventMouseMotion.new()
	event.position = point
	event.global_position = point
	root.push_input(event, true)

func pile_contract(label: String) -> void:
	for spec in [[scene.card_table.draw_stack, scene.draw_pile_visual, scene.draw_count], [scene.card_table.discard_stack, scene.discard_pile_visual, scene.discard_count_label]]:
		var stack = spec[0]
		var pile: Control = spec[1]
		var count_label: Label = spec[2]
		check(stack.mouse_filter == Control.MOUSE_FILTER_IGNORE and stack.focus_mode == Control.FOCUS_NONE, label + " edges never receive input")
		check(not stack.is_processing(), label + " pile decoration has no idle processing")
		check(stack.layer_count <= 6, label + " thickness stays bounded")
		check(pile.get_global_rect().encloses(stack.get_global_rect()), label + " decoration fits original pile target")
		check(stack.get_global_rect().end.y + stack.layer_count * 0.9 < count_label.global_position.y, label + " paper edges clear exact count")
		check(stack._face.visible == (stack.count > 0), label + " no card face remains on an empty pile")
		check(count_label.text == scene.tr("PILE_COUNT") % stack.count, label + " label agrees with shown pile")

func _run() -> void:
	rendered = DisplayServer.get_name() != "headless"
	capture_dir = "res://.godot/validation/piles-2026-10-14/screens"
	root.size = Vector2i(1280, 720)
	scene = load("res://scenes/match.tscn").instantiate() as MatchUI
	root.add_child(scene)
	current_scene = scene
	await frames(5)
	await scene._on_play_pressed()
	scene.campaign.event_manager.complete_interaction("choose_drink")
	scene.campaign.complete_current_event()
	scene.deal.start_tutorial_deal()
	scene._sync_all()
	await create_timer(1.3).timeout
	check(scene.card_table.draw_stack.count == 42 and scene.card_table.discard_stack.count == 0, "opening table uses actual pile counts")
	await capture("opening-piles")
	var view: PlayingCardView = scene.card_table.hand_views[scene.deal.hand[-1].unique_id]
	await click(view)
	move_pointer(Vector2(650, 160))
	await create_timer(0.3).timeout
	check(view.selected and view._shadow.position == Vector2(8, 14), "selected card casts a raised shadow after pointer leaves")
	check(is_equal_approx(view._shadow.modulate.a, 0.7), "lift softens the shadow")
	await capture("selected-card")
	await click(view)
	move_pointer(Vector2(650, 160))
	await create_timer(0.3).timeout
	check(not view.selected and view._shadow.position == Vector2(5, 7) and is_equal_approx(view._shadow.modulate.a, 1.0), "deselection restores resting shadow")
	var card := scene.deal.hand[-1]
	var result := scene.deal.discard_card(card)
	check(result.ok, "real discard commits")
	scene._sync_all(result)
	await create_timer(0.3).timeout
	check(scene.card_table.discard_stack.count == scene.deal.deck.discard_pile.size(), "committed discard changes visible pile count")
	check(scene.discard_texture.texture.resource_path == card.texture_path(), "top face preserves the actual discarded card")
	var snapshot := scene.deal.deck.snapshot_state()
	var before_wallet := scene.deal.wallet.balance_vnd
	var before_hand := scene.deal.hand.duplicate()
	var draw_cards: Array[CardData] = scene.deal.deck.draw_pile.duplicate()
	var discarded: Array[CardData] = scene.deal.deck.discard_pile.duplicate()
	# Redistribute a fixture without duplicating/removing any physical cards.
	for remaining in [draw_cards.size(), 8, 2, 1, 0]:
		scene.deal.deck.draw_pile.assign(draw_cards.slice(0, remaining))
		scene.deal.deck.discard_pile.assign(discarded + draw_cards.slice(remaining))
		var before := scene.deal.deck.snapshot_state()
		scene.card_table.sync_piles()
		await frames()
		check(scene.deal.deck.snapshot_state() == before, "rendering pile counts leaves deck and RNG untouched")
		check(scene.deal.physical_card_accounting_is_valid(), "fixture keeps every physical card")
		check(scene.card_table.draw_stack.count == remaining, "draw edges follow shrinking deck")
		check(scene.card_table.draw_stack.layer_count == 0 if remaining <= 1 else scene.card_table.draw_stack.layer_count > 0, "single and empty piles have no extra paper layers")
		pile_contract("remaining " + str(remaining))
		await capture("remaining-" + str(remaining))
	# A card already being presented in the hand must not also appear in the pile.
	var staged: Array[CardData] = [scene.deal.deck.discard_pile[-1]]
	var full_discard_count := scene.deal.deck.discard_pile.size()
	scene.card_table.stage_hand(staged)
	check(scene.card_table.discard_stack.count == full_discard_count - 1, "staged-hand card is excluded from visible discard depth")
	scene.card_table.finish_staged_hand()
	check(scene.card_table.discard_stack.count == full_discard_count, "staging completion restores visible discard count")
	scene.deal.deck.restore_snapshot(snapshot)
	scene._sync_all()
	await create_timer(0.3).timeout
	for locale in ["en", "vi"]:
		scene.settings.set_locale(locale)
		for extent in [Vector2i(1280, 720), Vector2i(960, 540), Vector2i(1920, 1080)]:
			root.size = extent
			await frames(5)
			var label := "%s-%dx%d" % [locale, extent.x, extent.y]
			pile_contract(label)
			for mode in ["draw", "discard"]:
				await click(scene.pile_archive_buttons[mode])
				check(scene.pile_archive.overlay.visible and scene.pile_archive.mode == mode, label + " pointer opens " + mode + " archive through decoration")
				var archive: Control = scene.pile_archive.overlay.get_node("ArchivePanel")
				check(scene.get_global_rect().encloses(archive.get_global_rect()), label + " sorting tray fits")
				check(archive.get_node("SortingMat").mouse_filter == Control.MOUSE_FILTER_IGNORE, label + " mat passes pointer input")
				for grid: GridContainer in scene.pile_archive.grids.values():
					check(grid.size.x <= grid.get_parent().size.x, label + " cards fit the suit lane")
				for suit: String in scene.pile_archive.suit_titles:
					var title: Label = scene.pile_archive.suit_titles[suit].get_node("Title")
					var caption := title.get_node_or_null("SemanticCaption") as Control
					check(caption == null or not caption.visible, label + " suit heading retains its word beside the original icon")
				await capture(label + "-" + mode + "-archive")
				await click(scene.pile_archive.close_button)
				check(not scene.pile_archive.overlay.visible, label + " archive closes")
			move_pointer(Vector2(650, 160))
			await capture(label + "-piles")
	check(scene.deal.wallet.balance_vnd == before_wallet and scene.deal.hand == before_hand, "presentation and archive navigation preserve wallet and hand")
	check(scene.deal.deck.snapshot_state() == snapshot, "archive browsing preserves physical zones and RNG")
	check(scene.card_table.drop_target_at(scene.discard_pile_visual.get_global_rect().get_center()).kind == MatchInteraction.DROP_TARGET_DISCARD, "discard drop target keeps original bounds")
	check(scene.card_table.drop_target_at(scene.draw_pile_visual.get_global_rect().get_center()).kind == MatchInteraction.DROP_TARGET_NONE, "draw pile does not become a meld target")
	# A full physical deck puts thirteen cards in each suit and needs scrolling.
	var all_cards: Array[CardData] = scene.deal.deck.draw_pile.duplicate()
	all_cards.append_array(scene.deal.deck.discard_pile)
	all_cards.append_array(scene.deal.hand)
	scene.deal.deck.draw_pile.assign(all_cards)
	scene.deal.deck.discard_pile.clear()
	scene.deal.hand.clear()
	scene._sync_all()
	check(scene.deal.physical_card_accounting_is_valid() and all_cards.size() == 52, "full archive fixture retains all physical cards")
	for extent in [Vector2i(1280, 720), Vector2i(960, 540)]:
		root.size = extent
		await frames(5)
		await click(scene.pile_archive_buttons["draw"])
		await create_timer(0.2).timeout
		for grid: GridContainer in scene.pile_archive.grids.values():
			var scroll := grid.get_parent() as ScrollContainer
			check(grid.get_child_count() == 13, "full archive shows every card in the suit")
			check(grid.size.x + scroll.get_v_scroll_bar().size.x <= scroll.size.x, "enlarged cards leave room for the visible scrollbar")
			var point := scroll.get_global_transform_with_canvas() * (scroll.size * 0.5)
			move_pointer(point)
			for step in 8:
				for down in [true, false]:
					var wheel := InputEventMouseButton.new()
					wheel.position = point
					wheel.button_index = MOUSE_BUTTON_WHEEL_DOWN
					wheel.pressed = down
					root.push_input(wheel, true)
			await frames(3)
			var last := grid.get_child(12) as Control
			check(scroll.scroll_vertical > 0 and InputHitTest.contains(last, last.get_global_rect().get_center()), "wheel scrolling reaches the final physical card")
		await capture("full-deck-%dx%d" % [extent.x, extent.y])
		await click(scene.pile_archive.close_button)
	print("PILE_PRESENTATION_SMOKE: %d checks, %d failures" % [checks, failures.size()])
	scene.queue_free()
	await frames()
	quit(0 if failures.is_empty() else 1)
