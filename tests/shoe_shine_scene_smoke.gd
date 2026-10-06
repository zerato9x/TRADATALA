extends SceneTree
var scene: MatchUI
var failures: Array[String] = []
var checks := 0

func _initialize() -> void:
	call_deferred("_run")

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures.append(message)
		push_error(message)

func click(control: Control) -> void:
	check(control != null and control.is_visible_in_tree(), "physical click has a visible target")
	if control == null: return
	var point := control.get_global_transform_with_canvas() * (control.size * 0.5)
	for pressed in [true, false]:
		var event := InputEventMouseButton.new()
		event.position = point
		event.button_index = MOUSE_BUTTON_LEFT
		event.pressed = pressed
		root.push_input(event, true)
	await process_frame

func pause(seconds: float = 0.2) -> void:
	await create_timer(seconds).timeout

func wait_work(bench: ShoeShinePanel) -> void:
	var deadline := Time.get_ticks_msec() + 2_000
	while is_instance_valid(bench) and bench._working and Time.get_ticks_msec() < deadline:
		await process_frame
	check(not bench._working, "card work settles by a wall-clock deadline")

func capture(label: String) -> void:
	if DisplayServer.get_name() == "headless": return
	await RenderingServer.frame_post_draw
	var path := "res://.godot/shoe-overhaul/" + label + ".png"
	root.get_texture().get_image().save_png(path)

func pick(bench: ShoeShinePanel, slot: int, card: CardData) -> void:
	await click(bench._slots[slot].choose)
	check(scene.deck_screen.visible, "bench opens the existing physical deck picker")
	check(scene.deck_screen._purpose.text == tr("SHOE_PICK_TERMS"), "picker explains irreversible visit commitment")
	var tile := scene.deck_screen.find_child("Card_" + card.unique_id, true, false) as Button
	await click(tile)
	check(scene.deck_screen._selected == card, "physical card art selects the canonical card")
	await click(scene.deck_screen._confirm)
	check(not scene.deck_screen.visible, "confirmation returns to the bench")
	await pause()

func check_layout(bench: ShoeShinePanel) -> void:
	var table := scene.event_table
	var sprite: Control = table._npc_layers.danh_giay.sprite
	var service := table.content_panel.get_global_rect()
	var speech := table.conversation.get_global_rect()
	check(not service.intersects(sprite.get_global_rect()), "bench never covers the NPC")
	check(not speech.intersects(sprite.get_global_rect()), "speech never covers the NPC")
	check(not service.intersects(speech), "speech and workbench stay separate")
	check(scene.get_global_rect().encloses(service), "entire workbench fits the viewport")
	check(service.encloses(bench.get_global_rect()), "workbench stays in its service frame")
	for slot in bench._slots:
		for key in ["rank", "suit"]:
			var button: Button = slot[key]
			check(slot.mat.get_global_rect().encloses(button.get_global_rect()), "reroll tool fits its physical mat")
			check(button.get_combined_minimum_size().x <= button.size.x, "localized reroll price is readable")
		check(slot.mat.get_global_rect().encloses(slot.properties.get_global_rect()), "property line fits its physical mat")

func _run() -> void:
	var locale_name := "vi" if OS.get_cmdline_user_args().has("--vietnamese") else "en"
	var large := OS.get_cmdline_user_args().has("--large")
	root.size = Vector2i(1920, 1080) if large else Vector2i(1280, 720)
	TranslationServer.set_locale(locale_name)
	scene = load("res://scenes/match.tscn").instantiate()
	root.add_child(scene)
	current_scene = scene
	await process_frame
	scene.session.run_save = RunSave.new("user://shoe-bench-scene.save")
	scene.drink_manager.progress.save_path = ""
	scene.run_seed_input = "SHOE-BENCH-RENDER"
	await scene._on_play_pressed()
	await pause(0.8)
	scene.campaign.wallet.reset(1_000_000)
	scene._on_event_wallet_committed()
	scene.event_table.focus_npc("danh_giay")
	await pause(0.6)
	var bench := scene.event_table.participants_container.get_child(0) as ShoeShinePanel
	check(bench != null, "Starter presents the dedicated workbench")
	if bench == null:
		finish()
		return
	check(bench.find_child("Tip", true, false) == null, "no tip or lottery-hint service")
	check(bench.find_child("PolishConfirm", true, false) == null, "no property-granting polish service")
	check(not bench._count.text.contains("SHOE_"), "selection count is translated")
	check_layout(bench)
	await capture("shoe-empty-" + locale_name + ("-large" if large else ""))
	var cards := scene.campaign.gieo_que.persistent_deck
	cards[0].fortune = 3
	cards[0].liquid = true
	cards[1].fortune = -4
	cards[1].negative = true
	await pick(bench, 0, cards[0])
	check(scene.campaign.shoe_shine.selected_card_ids == [cards[0].unique_id], "one committed card is enough")
	scene.session.flush()
	check(scene.session.run_save.load_run().shoe.selected_card_ids == [cards[0].unique_id], "selection autosaves before any payment")
	check(not bench._slots[0].rank.disabled, "one-card Rank tool is enabled")
	check(bench._slots[1].choose.visible, "second card is optional")
	var previous_rank := cards[0].rank
	var before := scene.campaign.wallet.balance_vnd
	await click(bench._slots[0].rank)
	check(cards[0].rank != previous_rank, "new canonical Rank appears immediately")
	check(scene.campaign.wallet.balance_vnd == before - 5_000, "Rank tool charges exact quoted price")
	check(scene.campaign_money_hud.last_transfer.reason == "shoe_reroll_rank", "payment uses the shared money flight")
	check(bench._slots[0].face.texture.resource_path == cards[0].texture_path(), "visible face follows committed identity")
	await wait_work(bench)
	check(scene.campaign.shoe_shine.rank_cost() == 10_000 and scene.campaign.shoe_shine.suit_cost() == 2_500, "Rank escalates independently")
	await pick(bench, 1, cards[1])
	check(scene.campaign.shoe_shine.selected_card_ids.size() == 2, "two physical slots are committed")
	check(not bench._slots[0].choose.visible and not bench._slots[1].choose.visible, "committed cards expose no replacement action")
	check(bench._slots[0].properties.text.contains(tr("CARD_GOLD")), "Gold remains visible")
	check(bench._slots[0].properties.text.contains(tr("GIEO_PROPERTY_LIQUID")), "Liquid remains visible")
	check(bench._slots[1].properties.text.contains(tr("CARD_BLACK_INK")), "Black Ink remains visible")
	check(bench._slots[1].properties.text.contains(tr("CARD_NEGATIVE")), "Negative remains visible")
	var previous_suit := cards[1].suit
	before = scene.campaign.wallet.balance_vnd
	await click(bench._slots[1].suit)
	check(cards[1].suit != previous_suit, "Suit button changes canonical Suit")
	check(scene.campaign.wallet.balance_vnd == before - 2_500, "Suit tool charges its own quoted price")
	await wait_work(bench)
	await click(bench._slots[0].rank)
	await wait_work(bench)
	check(scene.campaign.shoe_shine.rank_rerolls == 2 and scene.campaign.shoe_shine.suit_rerolls == 1, "repeated service counts stay visible")
	check(bench._uses.text == tr("SHOE_USES") % [2, 1], "localized counters match committed service state")
	check_layout(bench)
	await capture("shoe-bench-" + locale_name + ("-large" if large else ""))
	await click(bench._slots[1].suit)
	check(bench._working, "close occurs while the card work animation is still running")
	var state := scene.campaign.shoe_shine.run_snapshot().duplicate(true)
	var rng := scene.campaign.shoe_shine.run_rng_state()
	before = scene.campaign.wallet.balance_vnd
	await click(scene.event_table.back_button)
	await pause(0.5)
	scene.event_table.focus_npc("danh_giay")
	await pause(0.5)
	bench = scene.event_table.participants_container.get_child(0) as ShoeShinePanel
	check(scene.campaign.shoe_shine.run_snapshot() == state, "reopen preserves selection, counts, prices and receipt")
	check(scene.campaign.shoe_shine.run_rng_state() == rng, "reopen does not consume RNG")
	check(scene.campaign.wallet.balance_vnd == before, "reopen never charges again")
	check(not bench._working, "reopen does not replay previous card work")
	check(bench._receipt.visible, "last committed identity remains visible on reopen")
	check(not scene.campaign.shoe_shine.choose_card(cards[2].unique_id).ok, "reopen cannot select a third card")
	scene.campaign.wallet.reset(0)
	await pause()
	check(bench._slots[0].rank.disabled and bench._slots[1].suit.disabled, "insufficient wallet disables paid tools")
	check(bench._slots[0].rank.tooltip_text == tr("SHOE_ERROR_FUNDS"), "localized disabled reason explains the wallet")
	await click(scene.event_table.back_button)
	await pause(0.5)
	scene.event_manager.complete_interaction("choose_drink")
	scene._on_campaign_continue_pressed()
	await pause(0.5)
	check(scene.campaign.current_phase == CampaignManager.CampaignPhase.MORNING_DEAL, "optional workbench permits normal event progression")
	check(not scene.campaign.shoe_shine.is_active(), "service closes once Starter ends")
	var card_copy: CardData
	for card in scene.deal.hand + scene.deal.deck.draw_pile:
		if card.unique_id == cards[0].unique_id: card_copy = card
	check(card_copy != null and card_copy.permanent_snapshot() == cards[0].permanent_snapshot(), "next Deal receives transformed identity and properties")
	check(scene.deal.physical_card_accounting().valid, "deck composition and physical accounting remain valid")
	scene.queue_free()
	await pause(0.2)
	finish()

func finish() -> void:
	for message in failures: print("SHOE_SHINE_SCENE_FAIL " + message)
	print("SHOE_SHINE_SCENE_SMOKE checks=%d failures=%d" % [checks, failures.size()])
	quit(0 if failures.is_empty() else 1)