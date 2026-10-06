extends SceneTree

var failures: Array[String] = []
var scene: MatchUI

func _initialize() -> void:
	call_deferred("_run")

func check(value: bool, message: String) -> void:
	if not value:
		failures.append(message)
		push_error(message)

func click(control: Control) -> void:
	var point := control.get_global_transform_with_canvas() * (control.size * 0.5)
	for pressed in [true, false]:
		var event := InputEventMouseButton.new()
		event.position = point
		event.button_index = MOUSE_BUTTON_LEFT
		event.pressed = pressed
		root.push_input(event, true)
	await process_frame

func capture(file: String) -> void:
	if DisplayServer.get_name() != "headless":
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://.godot/" + file + ".png")

func check_layout(npc_id: String) -> void:
	var table := scene.event_table
	var sprite := table._npc_layers[npc_id]["sprite"] as TextureRect
	var speech_rect := table.conversation.get_global_rect()
	var service_rect := table.content_panel.get_global_rect()
	check(not speech_rect.intersects(sprite.get_global_rect()), npc_id + ": chatbox never covers the character")
	check(not service_rect.intersects(sprite.get_global_rect()), npc_id + ": service never covers the character")
	check(not speech_rect.intersects(service_rect), npc_id + ": dialogue and service remain separate")
	check(is_equal_approx(speech_rect.position.x, service_rect.position.x), npc_id + ": dialogue aligns with service left edge")
	check(is_equal_approx(speech_rect.end.x, service_rect.end.x), npc_id + ": dialogue aligns with service right edge")
	check(table.conversation.speech.get_content_height() <= table.conversation.speech.size.y, npc_id + ": all dialogue is readable")
	check(scene.get_global_rect().encloses(service_rect), npc_id + ": full service remains within viewport")
	check(not (table._npc_layers[npc_id]["name_tag"] as Label).visible, npc_id + ": no duplicate label over sprite")
	for button in table.conversation.get_node("Lines/Responses").get_children():
		check(speech_rect.encloses(button.get_global_rect()), npc_id + ": response controls fit dialogue")


func check_localized_layout(npc_id: String) -> void:
	for locale_name in ["en", "vi"]:
		TranslationServer.set_locale(locale_name)
		scene.event_services.present_npc(npc_id, scene.current_campaign_event)
		for line_key in ["NPC_GREETING_" + npc_id.to_upper(), "NPC_CHAT_" + npc_id.to_upper()]:
			scene.event_table.say(tr(line_key))
			await create_timer(0.1).timeout
			check_layout(npc_id)
		for window_size in [Vector2i(1280, 720), Vector2i(1920, 1080)]:
			root.size = window_size
			await process_frame
			await process_frame
			check_layout(npc_id)
		root.size = Vector2i(1280, 720)
		await process_frame
		scene.event_table.say(tr("NPC_GREETING_" + npc_id.to_upper()))
		await create_timer(1.5).timeout
		await capture("misc_layout_" + npc_id + "_" + locale_name)


func _run() -> void:
	scene = load("res://scenes/match.tscn").instantiate()
	root.add_child(scene)
	current_scene = scene
	await process_frame
	# Find a deterministic draw with an actually offered Special ticket.
	var probe := LotteryService.new(VndWallet.new())
	for seed_value in 100:
		probe.reset_run()
		probe.set_seed_value(seed_value)
		probe.begin_day(0)
		probe.begin_event(EventManager.EventSlot.MORNING)
		var encountered := false
		for ticket in probe.offered_tickets():
			if int(ticket.number) == probe.special_number():
				encountered = true
		if encountered:
			scene.campaign.lottery.set_seed_value(seed_value)
			break
	await scene._on_play_pressed()
	scene.campaign.wallet.reset(2_000_000)
	scene.event_services.wallet_committed.emit()
	await create_timer(0.6).timeout
	scene.event_table.focus_npc(EventTableController.NPC_DANH_GIAY)
	await create_timer(0.5).timeout
	var bench := scene.event_table.participants_container.get_child(0) as ShoeShinePanel
	check(bench != null, "identity workbench replaces placeholder")
	var cards := scene.campaign.gieo_que.persistent_deck
	bench._choose_card(cards[0].unique_id)
	check(scene.campaign.shoe_shine.selected_card_ids.size() == 1, "player commits one physical card")
	var before_work := scene.campaign.wallet.balance_vnd
	var rank_quote := scene.campaign.shoe_shine.rank_cost()
	await click(bench._slots[0].rank)
	await create_timer(0.6).timeout
	check(scene.campaign.wallet.balance_vnd == before_work - rank_quote, "identity work charges authoritative wallet")
	check(bench._slots[0].face.texture.resource_path == cards[0].texture_path(), "result shows actual changed identity")
	check(scene.get_global_rect().encloses(bench.get_global_rect()), "identity bench fits viewport")
	check_layout(EventTableController.NPC_DANH_GIAY)
	await capture("misc_shoe")
	for locale_name in ["en", "vi"]:
		TranslationServer.set_locale(locale_name)
		bench._refresh()
		await process_frame
		check(not bench._count.text.begins_with("SHOE_"), "selection copy translated")
	await check_localized_layout(EventTableController.NPC_DANH_GIAY)
	await click(scene.event_table.back_button)
	await create_timer(0.4).timeout
	check(scene.event_table.focused_npc_id.is_empty(), "Back leaves shoe service")
	scene.event_manager.complete_interaction("choose_drink")
	scene._on_campaign_continue_pressed()
	scene.campaign.complete_deal()
	await create_timer(0.5).timeout
	scene.event_table.focus_npc(EventTableController.NPC_LOTTO)
	await create_timer(0.5).timeout
	var panel := scene.event_table.participants_container.get_child(0) as MiscNpcPanel
	check(panel != null and panel.lottery != null, "lottery service replaces placeholder")
	var offers := scene.campaign.lottery.offered_tickets()
	var chosen: Dictionary = offers[0]
	for ticket in offers:
		if int(ticket.number) == scene.campaign.lottery.special_number():
			chosen = ticket
	var button := panel.find_child("Ticket_" + String(chosen.id).replace(":", "_"), true, false) as Button
	var before := scene.campaign.wallet.balance_vnd
	await click(button)
	check(scene.campaign.wallet.balance_vnd == before - int(chosen.stake_vnd), "physical ticket click charges authoritative wallet")
	check(scene.campaign.lottery.purchased_tickets().size() == 1, "ticket purchased once")
	await create_timer(1.0).timeout
	check(scene.get_global_rect().encloses(panel.get_global_rect()), "lottery panel fits viewport")
	check_layout(EventTableController.NPC_LOTTO)
	await capture("misc_lottery")
	await check_localized_layout(EventTableController.NPC_LOTTO)
	await click(scene.event_table.back_button)
	await create_timer(0.4).timeout
	scene.event_table.focus_npc(EventTableController.NPC_LOTTO)
	await process_frame
	check(scene.campaign.lottery.purchased_tickets()[0].id == chosen.id, "reopening retains purchased ticket")
	check(scene.campaign.lottery.revealed_results().is_empty(), "panel cannot reveal draw early")
	var before_payout := scene.campaign.wallet.balance_vnd
	# Current campaign reveals the draw at the Afternoon Event; offers are random.
	scene.campaign._enter_phase(CampaignManager.CampaignPhase.AFTERNOON_EVENT)
	await create_timer(0.5).timeout
	var receipt := scene.campaign.lottery.last_receipt
	check(not receipt.is_empty(), "Afternoon settles the purchased ticket")
	var expected_payout := 0
	for prize in MiscServiceConfig.PRIZES:
		if receipt.draw[prize.id].has(chosen.number):
			expected_payout = LotteryService.payout_vnd(int(chosen.stake_vnd), prize)
			break
	check(int(receipt.tickets[0].payout_vnd) == expected_payout, "ticket payout matches the authoritative draw")
	check(scene.campaign.wallet.balance_vnd == before_payout + expected_payout, "real payout reaches wallet once")
	var result_view := root.get_node_or_null("LotteryReceipt")
	check(result_view != null, "Afternoon settlement creates result receipt")
	await create_timer(0.9).timeout
	if result_view != null:
		var receipt_host := result_view.find_child("LotteryHost", true, false) as TextureRect
		var receipt_text := result_view.find_child("ResultText", true, false) as PanelContainer
		check(receipt_host != null and receipt_host.get_global_rect().size.y >= 600, "result gives lottery host full-height side presence")
		check(receipt_text != null and (receipt_text.get_theme_stylebox("panel") as StyleBoxFlat).bg_color.a < 0.95, "result uses translucent text backing")
		check(result_view.find_child("DrawnNumbers", true, false).get_child_count() == MiscServiceConfig.PRIZES.size(), "all drawn prize tiers remain visible")
	await capture("misc_lottery_result")
	if result_view != null:
		await click(result_view.find_child("CloseReceipt", true, false) as Button)
		check(root.get_node_or_null("LotteryReceipt") == null, "receipt closes by physical click")
	check(scene.campaign.lottery.settle_day().is_empty(), "reopening cannot settle twice")
	var plain := CardData.new("plain", "K", 13, "Spades", 13)
	var reused := TextureRect.new()
	var polished_card := CardData.new("legacy_polish", "K", 13, "Spades", 13)
	polished_card.shiny = true
	GieoCardFX.attach_texture(reused, polished_card)
	check(reused.material != null, "polished material applied")
	GieoCardFX.attach_texture(reused, plain)
	check(reused.material == null, "reused plain face clears polish")
	reused.free()
	scene.queue_free()
	# Allow the audio mixer to release stopped playback before process teardown.
	await create_timer(0.2).timeout
	print("MISC_NPC_SCENE_SMOKE ", "PASS" if failures.is_empty() else "FAIL " + str(failures))
	quit(0 if failures.is_empty() else 1)
