extends SceneTree
var scene: MatchUI
var failures: Array[String] = []
var checks := 0
var serial := 0
func _initialize() -> void:
	call_deferred("_run")
func check(ok: bool, text: String) -> void:
	checks += 1
	if not ok:
		failures.append(text)
		push_error(text)
func card(rank: int, suit: String = "Spades") -> CardData:
	serial += 1
	var label := str(rank)
	if rank == 1: label = "A"
	if rank == 11: label = "J"
	if rank == 12: label = "Q"
	if rank == 13: label = "K"
	return CardData.new("quick_%d" % serial, label, rank, suit, rank)
func prepare(id: String, cards: Array[CardData]) -> void:
	scene.money_presentation.hide_ceremony()
	scene._reset_tutorial_ui_state()
	scene.deal._reset_drink_usage()
	scene.deal.melds.clear()
	scene.deal.discard_history.clear()
	scene.deal.recyclable_spent_cards.clear()
	scene.deal.deck.reset(117)
	scene.deal.hand.assign(cards)
	scene.deal.current_phase = 1
	scene.deal.discard_count = 0
	scene.deal.phase_metrics = PhaseMetrics.new()
	scene.deal.phase_new_meld_count = 0
	scene.deal.set_current_drink(id)
	scene.deal.state = DealState.STATE_FINAL_COMMIT_WINDOW
	scene.deal.wallet.reset(100000)
	scene.displayed_wallet_vnd = 100000
	scene.money_queue_wallet_vnd = 100000
	scene.interaction_locked = false
	scene.game_started = true
	scene.game_layer.position = Vector2.ZERO
	scene.menu_layer.hide()
	scene.campaign_overlay.hide()
	scene._sync_all()
	await create_timer(0.3).timeout
func center(control: Control) -> Vector2:
	return control.get_global_transform_with_canvas() * (control.size * 0.5)
func mouse(point: Vector2, down: bool) -> void:
	var e := InputEventMouseButton.new()
	e.button_index = MOUSE_BUTTON_LEFT
	e.position = point
	e.pressed = down
	root.push_input(e, true)
func motion(point: Vector2, held: bool = false) -> void:
	var e := InputEventMouseMotion.new()
	e.position = point
	e.button_mask = MOUSE_BUTTON_MASK_LEFT if held else 0
	root.push_input(e, true)
func click(control: Control) -> void:
	motion(center(control))
	await create_timer(0.15).timeout
	var point := center(control)
	mouse(point, true)
	mouse(point, false)
	await process_frame
func drag(control: Control, target: Vector2, capture: bool = false) -> void:
	motion(center(control))
	await create_timer(0.15).timeout
	var start := center(control)
	mouse(start, true)
	motion(start + Vector2(20, 0), true)
	await process_frame
	check(scene.active_drag_payload != null or scene.quick_drink_input.dragging, "pointer motion starts a real drag")
	motion(target, true)
	await process_frame
	if capture and "--capture" in OS.get_cmdline_user_args():
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://.godot/drink_quick_drag.png")
	mouse(target, false)
	await process_frame
func wait_action() -> void:
	var deadline := Time.get_ticks_msec() + 4000
	while scene.interaction_locked and Time.get_ticks_msec() < deadline:
		await process_frame
	check(not scene.interaction_locked, "interaction resolves without locking the table")
func count(id: String) -> int:
	return int(scene.ui_feedback.play_counts.get(StringName("drink_" + id), 0))
func _run() -> void:
	scene = load("res://scenes/match.tscn").instantiate() as MatchUI
	root.add_child(scene)
	current_scene = scene
	await process_frame
	scene.game_started = true
	scene.menu_layer.hide()
	await process_frame
	for id in DrinkCatalog.all_ids():
		var cue := StringName("drink_" + id)
		check(scene.ui_feedback.players.has(cue), id + " has Objects audio")
		var player: AudioStreamPlayer = scene.ui_feedback.players[cue]
		check(player.stream.resource_path == "res://assets/audio/sfx/drinks/" + id + ".wav", id + " uses its own supplied recording")
		check(player.stream.get_length() > 0.0 and player.bus == &"Sound", id + " valid Sound-bus stream")
	# Hover is inert; clicking selects/inspects, and the explicit Order button buys once.
	for id in DrinkCatalog.all_ids():
		var manager := DrinkManager.new()
		var shop := load("res://scenes/ui/drink_shop.tscn").instantiate() as DrinkShop
		root.add_child(shop)
		shop.position = Vector2(120, 160)
		shop.configure(manager, false)
		var orders: Array[String] = []
		shop.order_requested.connect(func(value: String) -> void: orders.append(value))
		var button := shop._buttons[id] as Button
		motion(Vector2(10, 10))
		await create_timer(0.12).timeout
		motion(center(button))
		await create_timer(0.12).timeout
		check(shop.selected_id.is_empty() and orders.is_empty(), id + " hover does not inspect")
		await click(button)
		check(shop.selected_id == id and orders.is_empty(), id + " click selects without buying")
		await click(shop.confirm)
		await click(shop.confirm)
		check(orders == [id], id + " Order button commits once")
		shop.queue_free()
		await process_frame
	# Selected groups use their cup with one click; no arming click clears them.
	for id in [DrinkCatalog.STING, DrinkCatalog.BO_HUC, DrinkCatalog.C2_ICED_TEA, DrinkCatalog.SAM_DUA, DrinkCatalog.BAC_XIU]:
		var cards: Array[CardData] = [card(7), card(7, "Hearts")]
		if id == DrinkCatalog.C2_ICED_TEA: cards = [card(5), card(6, "Hearts"), card(7, "Clubs"), card(8, "Diamonds")]
		await prepare(id, cards)
		for value in cards: await click(scene.hand_views[value.unique_id])
		var before := count(id)
		await click(scene.drink_table_button)
		if id in [DrinkCatalog.SAM_DUA, DrinkCatalog.BAC_XIU]:
			check(scene.deal.sam_dua_preserved_cards.size() == cards.size(), id + " selected-first single click preserves")
		else:
			check(scene.deal.melds.size() == 1 and scene.deal.melds[0].cards.size() == cards.size(), id + " selected-first single click creates full group")
		check(count(id) == before + 1, id + " successful use plays once")
		check(not scene.drink_targeting_active, id + " exits targeting after use")
	# Exact pairs auto-commit after two choices; C2 keeps its variable-length group.
	for id in [DrinkCatalog.STING, DrinkCatalog.BO_HUC]:
		var cards: Array[CardData] = [card(8), card(8, "Hearts"), card(4)]
		await prepare(id, cards)
		await click(scene.drink_table_button)
		await click(scene.hand_views[cards[0].unique_id])
		check(scene.pending_drink_card_ids.has(cards[0].unique_id), id + " first choice remains pending")
		await click(scene.hand_views[cards[1].unique_id])
		check(scene.deal.melds.size() == 1, id + " second choice commits without another cup click")
	# Both armed and unarmed groups can drag, including four-card C2 runs.
	for armed in [false, true]:
		var cards: Array[CardData] = [card(5), card(6, "Hearts"), card(7, "Clubs"), card(8, "Diamonds")]
		await prepare(DrinkCatalog.C2_ICED_TEA, cards)
		if armed: await click(scene.drink_table_button)
		for value in cards: await click(scene.hand_views[value.unique_id])
		check((scene.hand_views[cards[0].unique_id] as PlayingCardView).drag_enabled, "C2 targeting never disables card drags")
		await drag(scene.hand_views[cards[0].unique_id], center(scene.drink_table_button), armed)
		check(scene.deal.melds.size() == 1 and scene.deal.melds[0].cards.size() == 4, "C2 group drag commits all four selected cards")
	# Default table drops recognize a drink-only Pair, without wasting C2 on an ordinary run.
	for ordinary in [false, true]:
		var id := DrinkCatalog.C2_ICED_TEA if ordinary else DrinkCatalog.STING
		var cards: Array[CardData] = [card(4), card(5), card(6)]
		if not ordinary: cards = [card(7), card(7, "Hearts")]
		await prepare(id, cards)
		for value in cards: await click(scene.hand_views[value.unique_id])
		check(not scene.ha_button.disabled, "quick meld has an enabled action button")
		await drag(scene.hand_views[cards[0].unique_id], center(scene.table_surface) + Vector2(0, -60))
		await wait_action()
		check(scene.deal.melds.size() == 1, "ordinary table drop accepts the selected group")
		check(not scene.deal.c2_used if ordinary else scene.deal.pair_used_phases.has(1), "table drop spends only a necessary drink permission")
		if not ordinary:
			scene.deal.set_current_drink(DrinkCatalog.NAU_DA)
			scene._sync_all()
			var face := (scene.meld_views[scene.deal.melds[0].meld_id] as MeldView).get_scoring_card_control(cards[0].unique_id)
			await drag(face, center(scene.hand_layer))
			check(scene.deal.melds.is_empty(), "recovery remains usable during a nonblocking payout")
			var deadline := Time.get_ticks_msec() + 6000
			while scene.money_queue_running and Time.get_ticks_msec() < deadline:
				await process_frame
			check(not scene.money_queue_running, "receipt completes after its physical Meld is recovered")
	# Preservation groups can drop on the cup; over-limit drops keep charge and selection.
	for id in [DrinkCatalog.SAM_DUA, DrinkCatalog.BAC_XIU]:
		var cards: Array[CardData] = [card(2), card(4), card(6), card(9)]
		await prepare(id, cards)
		for value in cards: await click(scene.hand_views[value.unique_id])
		await drag(scene.hand_views[cards[0].unique_id], center(scene.drink_table_button))
		if id == DrinkCatalog.SAM_DUA:
			check(not scene.deal.sam_dua_used and scene.selected_card_ids.size() == 4, "Sam dua over-limit drop neither spends nor clears selection")
			await click(scene.hand_views[cards[3].unique_id])
			await drag(scene.hand_views[cards[0].unique_id], center(scene.drink_table_button))
			check(scene.deal.sam_dua_preserved_cards.size() == 3, "Sam dua drag preserves three")
		else:
			check(scene.deal.sam_dua_preserved_cards.size() == 4, "Bac xiu drag preserves unrestricted group")
	# Recovery supports both directions with the exact original validity rules.
	for id in [DrinkCatalog.NUOC_VOI, DrinkCatalog.NAU_DA]:
		for cup_first in [false, true]:
			await prepare(id, [card(12)] as Array[CardData])
			var run: Array[CardData] = [card(3), card(4), card(5), card(6)]
			var meld := MeldState.new(911, MeldRules.TYPE_RUN, run)
			scene.deal.melds.append(meld)
			scene._sync_all()
			await create_timer(0.25).timeout
			var face := (scene.meld_views[911] as MeldView).get_scoring_card_control(run[0].unique_id)
			var before := count(id)
			if cup_first:
				await drag(scene.drink_table_button, center(face))
			else:
				await drag(face, center(scene.hand_layer))
			check(scene.deal.hand.has(run[0]), id + " recovery drag returns target")
			check(scene.deal.melds.is_empty() if id == DrinkCatalog.NAU_DA else meld.cards.size() == 3, id + " recovers correct scope")
			check(count(id) == before + 1, id + " recovery plays once")
	# Both swap drinks support hand -> discard and discard -> hand. Den da includes DUMP.
	for id in [DrinkCatalog.NHAN_TRAN, DrinkCatalog.DEN_DA]:
		for reverse in [false, true]:
			var outgoing := card(9)
			await prepare(id, [outgoing, card(4)] as Array[CardData])
			var incoming := card(11, "Clubs")
			var record := DiscardRecord.new(incoming, 1, 1, DiscardRecord.KIND_DUMP if id == DrinkCatalog.DEN_DA else DiscardRecord.KIND_MANDATORY)
			scene.deal.discard_history.append(record)
			scene.deal.deck.discard_pile = [incoming]
			scene._sync_all()
			await process_frame
			if id == DrinkCatalog.DEN_DA:
				# Select-first cup opens the legal archive without an extra arming click.
				await click(scene.hand_views[outgoing.unique_id])
				await click(scene.drink_table_button)
				check(scene.discard_archive_overlay.visible, "Den da one cup click opens swap picker with selection intact")
				var grid: GridContainer = scene.discard_archive_suit_grids["Clubs"]
				if reverse:
					await drag(grid.get_child(0), center(scene.hand_views[outgoing.unique_id]))
				else:
					await click(grid.get_child(0))
			else:
				var holder: Control = scene.discard_history_target_holders[scene._discard_history_target_key(record)]
				if reverse:
					await drag(holder, center(scene.hand_views[outgoing.unique_id]))
				else:
					await drag(scene.hand_views[outgoing.unique_id], center(holder))
			await wait_action()
			check(scene.deal.hand.has(incoming) and not scene.deal.hand.has(outgoing), id + " swap gesture uses requested cards")
			check(record.card == outgoing, id + " swap retains discard record")
	# Passive drinks retain ordinary dragging and provide audio when their effect is used.
	for id in [DrinkCatalog.MIA_TAC, DrinkCatalog.MIA_SAU_RIENG]:
		var first := "Hearts" if id == DrinkCatalog.MIA_TAC else "Spades"
		var second := "Diamonds" if id == DrinkCatalog.MIA_TAC else "Clubs"
		var cards: Array[CardData] = [card(4, first), card(5, second), card(6, first)]
		await prepare(id, cards)
		var before := count(id)
		for value in cards: await click(scene.hand_views[value.unique_id])
		await drag(scene.hand_views[cards[0].unique_id], center(scene.table_surface) + Vector2(0, -60))
		await wait_action()
		check(scene.deal.melds.size() == 1, id + " normal drag automatically uses passive run permission")
		check(count(id) == before + 1, id + " passive run has sound")
	await prepare(DrinkCatalog.TRA_DA, [card(2), card(3), card(4), card(8)] as Array[CardData])
	scene.deal.state = DealState.STATE_ACTIVE
	scene.deal.tra_da_extra_discard_pending = true
	scene._refresh_actions()
	var before := count(DrinkCatalog.TRA_DA)
	await click(scene.hand_views[scene.deal.hand[-1].unique_id])
	await click(scene.discard_button)
	await wait_action()
	check(count(DrinkCatalog.TRA_DA) == before + 1, "Tra da ordinary extra discard plays its Objects cue")
	# Invalid recovery / Escape cancel / stale charges never mutate or leave a preview.
	await prepare(DrinkCatalog.NUOC_VOI, [card(10)] as Array[CardData])
	var run: Array[CardData] = [card(3), card(4), card(5), card(6)]
	scene.deal.melds.append(MeldState.new(912, MeldRules.TYPE_RUN, run))
	scene._sync_all()
	await create_timer(0.25).timeout
	var middle := (scene.meld_views[912] as MeldView).get_scoring_card_control(run[1].unique_id)
	await drag(middle, center(scene.hand_layer))
	check(scene.deal.melds[0].cards.size() == 4 and scene.deal.current_drink_has_charge(), "invalid middle-of-run recovery leaves cards and charge intact")
	var point := center(scene.drink_table_button)
	mouse(point, true)
	motion(point + Vector2(30, 0), true)
	var escape := InputEventKey.new()
	escape.keycode = KEY_ESCAPE
	escape.pressed = true
	root.push_input(escape, true)
	mouse(point, false)
	check(not scene.quick_drink_input.dragging and scene.quick_drink_input.preview == null, "Escape clears cup drag without consuming charge")
	check(scene.deal.current_drink_has_charge(), "cancelled cup drag keeps charge")
	scene.queue_free()
	await process_frame
	print("DRINK_QUICK_SMOKE checks=%d failed=%d" % [checks, failures.size()])
	quit(0 if failures.is_empty() else 1)
