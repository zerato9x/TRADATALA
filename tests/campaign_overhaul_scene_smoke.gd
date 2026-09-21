extends SceneTree
var failures: Array[String] = []
var scene: MatchUI

func _initialize() -> void:
	call_deferred("_run")

func check(value: bool, message: String) -> void:
	if not value: failures.append(message)

func pause(seconds: float = 0.55) -> void:
	await create_timer(seconds).timeout

func capture(label: String) -> void:
	if DisplayServer.get_name() != "headless":
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://.godot/overhaul-" + ("en-" if OS.get_cmdline_user_args().has("--english") else "vi-") + label + ".png")

func click(button: Button) -> void:
	var point := button.get_global_transform_with_canvas() * (button.size * 0.5)
	for down in [true, false]:
		var event := InputEventMouseButton.new()
		event.position = point
		event.button_index = MOUSE_BUTTON_LEFT
		event.pressed = down
		root.push_input(event, true)
	await pause(0.2)

func _run() -> void:
	root.size = Vector2i(1280, 720)
	if OS.get_cmdline_user_args().has("--large"):
		root.size = Vector2i(1920, 1080)
	scene = load("res://scenes/match.tscn").instantiate()
	root.add_child(scene)
	current_scene = scene
	scene.run_save = RunSave.new("user://overhaul-scene-test.save")
	scene.drink_manager.progress.save_path = ""
	await pause()
	var title := scene.get_node_or_null("TitleScreen")
	if title: title.queue_free()
	TranslationServer.set_locale("vi" if not OS.get_cmdline_user_args().has("--english") else "en")
	scene._refresh_localized_ui()
	scene.run_seed_input = "MONDAY-OVERHAUL"
	await scene._on_play_pressed()
	await pause(3.0)
	check(not scene.tutorial_active, "campaign has no standalone tutorial")
	check(scene.event_table.focused_npc_id == "doi_no", "collector opens Starter Event")
	check(scene.campaign_money_hud.panel.is_visible_in_tree(), "single top wallet remains visible in event")
	check(not scene.event_table.overview.cash_anchor.is_visible_in_tree(), "table cash is hidden during collector focus")
	await capture("starter-debt")
	scene.event_table.unfocus_npc()
	await pause()
	check(not scene.event_table._npc_layers.doi_no.overlay.visible, "no tabletop collector after acknowledgement")
	check(not scene.event_table._npc_layers.doi_no.sprite.visible, "collector completes exit")
	check(not scene.event_table._npc_layers.doi_no.button.visible, "collector never becomes a table service")
	check(not scene.campaign_money_hud.panel.is_visible_in_tree(), "overview uses its table wallet without a duplicate HUD")
	check(scene.event_table.money_label.is_visible_in_tree(), "overview balance remains visible")
	if not DemoBuild.enabled():
		scene.event_table.focus_npc("danh_giay")
		await pause()
		var shoe := scene.campaign_participants.get_child(0)
		await click(shoe._polish_button)
		check(scene.campaign.shoe_shine.last_polished_ids.size() == 2, "pointer polishes two physical cards")
		check(scene.campaign_money_hud.last_transfer.reason == "shoe_polish", "shoe payment flies from common wallet")
		await capture("polish")
		scene.event_table.unfocus_npc()
		await pause()
	scene.event_table.focus_npc("tra_da_auntie")
	await pause()
	await capture("drink-shop")
	scene._on_campaign_drink_pressed(0, "choose_drink", DrinkCatalog.TRA_DA)
	scene.event_table.unfocus_npc()
	await pause()
	await click(scene.campaign_continue_button)
	await pause()
	check(scene.deal.hand.filter(func(card): return card.rank_index == 9).size() == 3, "real Morning starts with curated Set")
	check(scene.deal.physical_card_accounting_is_valid(), "52 identities retained")
	await capture("morning")
	var cards: Array[CardData] = []
	for card in scene.deal.hand:
		if card.rank_index == 9: cards.append(card)
	for card in cards: scene._on_card_pressed(card)
	await scene._on_ha_pressed()
	await pause()
	check(scene.campaign.onboarding.learned.has("new_meld"), "real action learns Hạ")
	check(scene.campaign_coach.current_id != "new_meld", "learned Hạ hint retires")
	var saved_hand := scene.deal.hand.map(func(card): return card.unique_id)
	scene._on_tutorial_pressed()
	await pause()
	check(root.get_node_or_null("GameGlossary") != null, "former tutorial opens handbook")
	check(scene.deal.hand.map(func(card): return card.unique_id) == saved_hand, "handbook preserves live hand")
	await capture("glossary")
	root.get_node("GameGlossary").queue_free()
	# Complete the real rules loop, freely choosing legal actions.
	_play_deal()
	scene._show_deal_over({})
	await pause()
	await capture("deal-receipt")
	await click(scene.resolve_receipt.primary)
	await pause()
	check(scene.campaign.current_phase == CampaignManager.CampaignPhase.MORNING_EVENT, "Morning resolves into event")
	if not DemoBuild.enabled():
		scene.event_table.focus_npc("hang_rong")
		await pause()
		var shop = scene.campaign_participants.get_child(0)
		check(shop._tiles.size() == 3, "three physical table relic offers")
		var first: Button = shop._tiles.values()[0]
		await click(first)
		await capture("relics")
		check(not shop.selected.is_empty(), "pointer selects relic without buying")
		if not shop._buy.disabled:
			await click(shop._buy)
			check(not scene.deal.relics.inventory.is_empty(), "pointer purchase enters inventory")
			check(scene.campaign_money_hud.last_transfer.reason.begins_with("relic_purchase:"), "relic payment uses common wallet")
		scene.event_table.unfocus_npc()
		await pause()
		scene.event_table.focus_npc("thay_boi")
		await pause()
		await capture("gieo-cabinet")
		var gieo = scene.campaign_participants.get_child(0)
		var guides := gieo.find_children("GieoGuide", "Button", true, false)
		check(guides.size() == 1, "permanent Gieo guide exists")
		if not guides.is_empty(): await click(guides[0])
		await capture("gieo-guide")
		var glossary := root.get_node_or_null("GameGlossary")
		check(glossary != null, "guide pointer opens Gieo reference")
		if glossary: glossary.queue_free()
		scene.event_table.unfocus_npc()
		await pause()
		scene.event_table.focus_npc("lotto")
		await pause()
		var lottery_panel := scene.campaign_participants.get_child(0)
		var buy_all: Button = lottery_panel.get_node("BuyAll")
		await capture("lottery-buy")
		if not buy_all.disabled:
			await click(buy_all)
			check(not scene.campaign.lottery.purchased_tickets().is_empty(), "pointer Buy All buys tickets")
		scene.event_table.unfocus_npc()
		await pause()
	scene._on_campaign_continue_pressed()
	await pause()
	_play_deal()
	scene._show_deal_over({})
	await pause()
	await click(scene.resolve_receipt.primary)
	await pause()
	scene._on_campaign_drink_pressed(2, "choose_drink", DrinkCatalog.TRA_DA)
	scene._on_campaign_continue_pressed()
	await pause()
	_play_deal()
	scene._show_deal_over({})
	await pause()
	await click(scene.resolve_receipt.primary)
	await pause(1.5)
	check(scene.campaign.current_phase == CampaignManager.CampaignPhase.AFTERNOON_EVENT, "results before Evening")
	await capture("lottery-results")
	var lotto_receipt := root.get_node_or_null("LotteryReceipt")
	if lotto_receipt:
		var close := lotto_receipt.find_child("CloseReceipt", true, false)
		await click(close)
	if not DemoBuild.enabled():
		check(not scene.campaign.lottery.revealed_results().is_empty(), "draw committed before Evening")
	scene.event_table.unfocus_npc()
	await pause()
	scene._on_campaign_continue_pressed()
	await pause()
	_play_deal()
	scene._show_deal_over({})
	await pause()
	await click(scene.resolve_receipt.primary)
	await pause(2.8)
	check(scene.resolve_mode == "collection", "evening reaches explicit collection")
	await capture("collection")
	var before := scene.deal.wallet.balance_vnd
	var due := scene.campaign.daily_requirement()
	await click(scene.resolve_receipt.primary)
	# A second click during departure cannot charge again.
	scene._on_receipt_continue()
	await pause(1.5)
	if before >= due:
		check(scene.campaign.current_day_index == 1, "real Monday reaches Tuesday")
		check(scene.deal.wallet.balance_vnd == before - due, "debt pays once")
		check(scene.campaign_money_hud.last_transfer.reason == "daily_debt", "debt uses common wallet flight")
		check(scene.campaign_money_hud.last_transfer.committed_balance == before - due, "flight starts after committed payment")
		check(scene.deal.wallet.journal.filter(func(entry): return entry.reason == "daily_debt").size() == 1, "repeated continuation journals one payment")
		check(scene.campaign_participants.get_node("DebtAmountDue").text == VndWallet.format_vnd(scene.campaign.daily_requirement()), "next briefing shows current authoritative debt")
		check(not scene._collection_departing, "departure releases UI gate")
		scene.event_table.unfocus_npc()
		await pause()
		scene._on_campaign_drink_pressed(0, "choose_drink", DrinkCatalog.TRA_DA)
		scene.event_table.unfocus_npc()
		await pause()
		scene._on_campaign_continue_pressed()
		await pause()
		check(scene.campaign.current_phase == CampaignManager.CampaignPhase.MORNING_DEAL, "Tuesday Morning deal starts")
		check(scene.current_campaign_event == null and scene.deal.state != DealState.STATE_DEAL_OVER, "Tuesday deal is playable")
		check(scene.deal.physical_card_accounting_is_valid(), "Tuesday preserves all card identities")
		_play_deal()
		check(scene.deal.state == DealState.STATE_DEAL_OVER, "Tuesday Morning completes")
	else:
		check(scene.campaign.run_failed, "insufficient earnings remain a real loss")
	print("MONDAY_WALLET before_collection=%d due=%d" % [before, due])
	await capture("tuesday-or-outcome")
	scene.queue_free()
	await process_frame
	for failure in failures: push_error(failure)
	print("CAMPAIGN_OVERHAUL_SCENE: %d failures" % failures.size())
	quit(0 if failures.is_empty() else 1)

func _play_deal() -> void:
	var d := scene.deal
	var safety := 0
	while d.state != DealState.STATE_DEAL_OVER and safety < 100:
		safety += 1
		if d.state == DealState.STATE_PHASE_CHOICE:
			d.choose_phase_two(false)
			continue
		var action := d.recommend_action()
		if action.action == HandAdvisor.ACTION_NEW_MELD:
			d.create_meld(action.cards)
		elif action.action == HandAdvisor.ACTION_EXTENSION:
			d.extend_meld(action.meld_id, action.cards)
		elif d.state == DealState.STATE_FINAL_COMMIT_WINDOW:
			d.settle_phase()
		elif d.tra_da_extra_discard_pending:
			d.end_turn_without_tra_da_extra()
		elif not d.hand.is_empty():
			d.discard_card(d.hand[-1])
	check(safety < 100, "legal actions complete Deal")
	check(d.physical_card_accounting_is_valid(), "physical identity after Deal")
