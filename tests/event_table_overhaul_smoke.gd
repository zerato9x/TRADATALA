extends SceneTree

var scene: MatchUI
var failures: Array[String] = []
var checks := 0
var last_radius := 0.0

func _initialize() -> void:
	call_deferred("_run")

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures.append(message)
		push_error(message)

func pause(seconds: float) -> void:
	var deadline := Time.get_ticks_msec() + int(seconds * 1000)
	while Time.get_ticks_msec() < deadline:
		await process_frame

func hover(control: Control) -> void:
	var event := InputEventMouseMotion.new()
	event.position = control.get_global_transform_with_canvas() * (control.size * 0.5)
	root.push_input(event, true)
	await process_frame

func click(control: Control) -> void:
	await hover(control)
	for down in [true, false]:
		var event := InputEventMouseButton.new()
		event.position = control.get_global_transform_with_canvas() * (control.size * 0.5)
		event.button_index = MOUSE_BUTTON_LEFT
		event.pressed = down
		root.push_input(event, true)
	await process_frame

func capture(file: String) -> void:
	if DisplayServer.get_name() != "headless":
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://.godot/" + file + ".png")

func _run() -> void:
	root.size = Vector2i(1280, 720)
	scene = load("res://scenes/match.tscn").instantiate()
	root.add_child(scene)
	current_scene = scene
	await pause(0.2)
	var title := scene.get_node_or_null("TitleScreen")
	if title != null:
		title.queue_free()
	scene.drink_manager.progress.save_path = ""
	scene._restoring_run = true
	await scene._on_play_pressed()
	scene.event_table.unfocus_npc()
	await pause(0.4)
	for id in ["hair_clip", "comb", "sunglasses", "chewing_gum"]:
		scene.deal.relics.acquire(id)
		scene.deal.relics.equip(id)
	scene.deal.wallet.reset(2887500)
	scene.displayed_wallet_vnd = scene.deal.wallet.balance_vnd
	scene._refresh_stats()
	await pause(0.7)
	var overview = scene.event_table.overview
	check(overview.is_visible_in_tree(), "event table shows possessions")
	check(not overview.journey_detail.visible and not overview.week.is_visible_in_tree(), "all journey detail is tucked away by default")
	check(overview.relic_buttons[0].size.x >= 120, "relics have physical table scale")
	check(overview.get_node_or_null("JourneyBoard") == null, "no persistent journey board covers the table")
	check(overview.cash_anchor.get_child_count() > 0, "wallet has physical banknote piles")
	var represented := 0
	for bill in overview.cash_anchor.get_children():
		for layer in bill.get_children():
			if layer is TextureRect:
				check(layer.size.x <= bill.size.x + 1, "cash shadow and paper stay within physical bill dimensions")
		represented += int(bill.get_meta("denomination_vnd", 0)) * int(bill.get_meta("logical_count", 0))
	check(represented == 2887000, "table banknotes represent the wallet's whole notes")
	check(overview.equipped.size() == 4, "four actual equipped relics on table")
	await capture("event-table-overview")
	await hover(overview.relic_buttons[0])
	check(overview.inspect_card.is_visible_in_tree(), "pointer hover reveals effect card")
	check(overview.inspect_copy.text.contains(RelicCatalog.effect("hair_clip")), "hover shows authoritative relic effect")
	await capture("event-table-relic-hover")
	for index in overview.relic_buttons.size():
		await hover(overview.relic_buttons[index])
		check(overview.inspect_copy.text.contains(RelicCatalog.effect(overview.equipped[index])), "every equipped item shows its own effect %d" % index)
		check(not overview.inspect_card.get_global_rect().intersects(scene.event_table.money_label.get_global_rect()), "item effect stays clear of wallet total %d" % index)
	await capture("event-table-gum-hover")
	await click(overview.journey_button)
	check(overview.journey_detail.visible, "journey expands on pointer click")
	check(overview.timeline.get_child_count() == 9, "journey includes events, deals and debt collection")
	check(overview.timeline.get_child(1).text.contains(overview.words("DEAL", "VÁN BÀI")), "morning deal is explicitly displayed")
	check(overview.detail_copy.text.contains(tr(EventManager.slot_name_key(0))), "expanded journey locates current event")
	await click(overview.week.get_child(6))
	check(overview.detail_copy.text.contains(VndWallet.format_vnd(16000000)), "future day click previews its debt")
	check(scene.campaign.current_day_index == 0, "journey inspection preserves campaign day")
	await capture("event-table-journey")
	await click(overview.journey_button)
	check(not overview.journey_detail.visible, "journey collapses on pointer click")
	await click(overview.journey_button)
	var escape := InputEventKey.new()
	escape.keycode = KEY_ESCAPE
	escape.physical_keycode = KEY_ESCAPE
	escape.pressed = true
	root.push_input(escape, true)
	await process_frame
	check(not overview.expanded and not scene.menu_layer.visible, "Escape tucks journey away without opening menu")
	await click(scene.event_table.event_deck.get_child(2))
	await pause(0.4)
	check(scene.event_table.deck_focused, "table deck remains pointer actionable")
	check(not overview.visible, "inventory clears space for focused service")
	await capture("event-table-deck")
	await click(scene.event_table.back_button)
	await pause(0.4)
	check(overview.visible and not scene.event_table.deck_focused, "Back restores table possessions")
	for slot in [1, 2, 3]:
		var phases := [CampaignManager.CampaignPhase.MORNING_EVENT, CampaignManager.CampaignPhase.NOON_EVENT, CampaignManager.CampaignPhase.AFTERNOON_EVENT]
		scene.campaign._enter_phase(phases[slot - 1])
		await pause(0.5)
		var result_view := root.get_node_or_null("LotteryReceipt")
		if result_view != null:
			await click(result_view.find_child("CloseReceipt", true, false))
		if not scene.event_table.focused_npc_id.is_empty():
			await click(scene.event_table.back_button)
			await pause(0.4)
		check(overview.event_slot == slot and overview.visible, "table updates current event position %d" % slot)
		await capture("event-table-slot-%d" % slot)
		var npc := "hang_rong" if slot == 1 else "thay_boi" if slot == 2 else "lotto"
		var button := scene.event_table.get_node(npc.to_pascal_case() + "Select") as Button
		await click(button)
		await pause(0.4)
		check(scene.event_table.focused_npc_id == npc and not overview.visible, "NPC pointer focus clears table objects " + npc)
		await click(scene.event_table.back_button)
		await pause(0.4)
		check(overview.visible and scene.event_table.focused_npc_id.is_empty(), "NPC Back restores overview " + npc)
	scene.campaign._enter_phase(CampaignManager.CampaignPhase.STARTER_EVENT)
	await pause(0.4)
	scene.event_table.unfocus_npc()
	await pause(0.4)
	for amount in [1000, 5000, 50000, 250000, 2887500, 288750000, 500000000]:
		scene.deal.wallet.reset(amount)
		scene.displayed_wallet_vnd = amount
		scene._refresh_stats()
		await process_frame
		for index in 3:
			await click(overview.cash_button)
			await pause(0.04)
		check(is_instance_valid(scene.wallet_spiral), "event cash triple click opens easter egg for %d" % amount)
		if not is_instance_valid(scene.wallet_spiral):
			continue
		await pause(0.9)
		var spiral = scene.wallet_spiral
		check(spiral.note_lanes.size() == spiral.notes.size(), "every banknote has a valid ring lane")
		check(spiral.radius > last_radius, "ring radius grows with wealth %d" % amount)
		last_radius = spiral.radius
		var total := 0
		for note in spiral.notes:
			total += int(note.get_meta("denomination_vnd")) * int(note.get_meta("logical_count"))
		check(total == amount - amount % 1000, "easter egg preserves represented money %d" % amount)
		if amount in [5000, 288750000]:
			await capture("event-ring-%d" % amount)
		spiral.dismiss()
		await pause(0.55)
		check(not is_instance_valid(scene.wallet_spiral) and scene.game_layer.modulate.a == 1.0, "ring closes and restores table")
		check(scene.deal.wallet.balance_vnd == amount, "inspection never changes wallet")
	scene.deal.wallet.reset(0)
	scene._refresh_stats()
	await click(overview.cash_button)
	check(not is_instance_valid(scene.wallet_spiral), "empty wallet cannot open easter egg")
	for locale in ["en", "vi"]:
		TranslationServer.set_locale(locale)
		scene._on_locale_changed(locale)
		await process_frame
		check(not overview.objective.text.contains("PERIOD_"), "objective localized in " + locale)
		var empty_copy := overview.cash_anchor.get_child(0) as Label
		check(empty_copy.text == overview.words("No banknotes", "Chưa có tiền giấy"), "empty cash copy follows locale " + locale)
		await click(overview.journey_button)
		await capture("event-table-" + locale)
		await click(overview.journey_button)
	root.size = Vector2i(1920, 1080)
	await pause(0.2)
	await capture("event-table-1080")
	var extended_days := CampaignConfig.day_definitions()
	for index in range(7, 11):
		var day: Dictionary = CampaignConfig.DAYS[index % 7].duplicate()
		day.required_vnd = 32000000 * (1 << (index - 7))
		extended_days.append(day)
	overview.sync(scene.money_presentation, 1000, scene.deal.relics.equipped, 10, 3, 256000000, extended_days)
	check(overview.week.get_child_count() == 7, "endless journey limits visible days to seven")
	check(overview.week.get_child(6).text.contains("11"), "endless journey includes actual current day")
	await click(overview.journey_button)
	await capture("event-table-endless")
	scene.event_table.enter_deal()
	await pause(0.7)
	check(not scene.event_table.visible, "event props exit with table when deal starts")
	print("EVENT_TABLE_OVERHAUL: %d checks, %d failures" % [checks, failures.size()])
	quit(0 if failures.is_empty() else 1)
