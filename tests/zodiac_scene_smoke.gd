extends SceneTree
## Fresh-process integration, including pointer/touch routing and saved offers.
var failures: Array[String] = []
var checks := 0
var scene: MatchUI

func _initialize() -> void:
	call_deferred("_run")

func _check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures.append(message)
		push_error(message)

func _pause(seconds: float = 0.4) -> void:
	await create_timer(seconds).timeout
	await process_frame

func _click(control: Control) -> void:
	await process_frame
	var point := control.get_global_transform_with_canvas() * (control.size * 0.5)
	for pressed in [true, false]:
		var event := InputEventMouseButton.new()
		event.button_index = MOUSE_BUTTON_LEFT
		event.position = point
		event.global_position = point
		event.pressed = pressed
		root.push_input(event, true)
		await process_frame

func _tap(control: Control) -> void:
	await process_frame
	var point := control.get_global_transform_with_canvas() * (control.size * 0.5)
	await _tap_point(point)

func _tap_point(point: Vector2) -> void:
	for pressed in [true, false]:
		var event := InputEventScreenTouch.new()
		event.index = 0
		event.position = point
		event.pressed = pressed
		root.push_input(event, true)
		await process_frame

func _dismiss_lottery() -> void:
	var receipt := root.get_node_or_null("LotteryReceipt")
	if receipt != null:
		await _click(receipt.find_child("CloseReceipt", true, false))
		await _pause(0.1)

func _capture(label: String) -> void:
	if DisplayServer.get_name() == "headless": return
	await RenderingServer.frame_post_draw
	DirAccess.make_dir_recursive_absolute("res://.godot/negotiation-validation/screens")
	root.get_texture().get_image().save_png("res://.godot/negotiation-validation/screens/%s.png" % label)

func _run() -> void:
	root.size = Vector2i(1280, 720)
	var settings := root.get_node("GameSettings")
	settings.set_music_system("playing_tracks")
	scene = load("res://scenes/match.tscn").instantiate() as MatchUI
	root.add_child(scene)
	current_scene = scene
	await _pause()
	scene.session.restoring = true
	scene.drink_manager.progress.save_path = ""
	scene.campaign.zodiac.progress = ZodiacProgress.new("")
	scene.session.run_save = RunSave.new("user://zodiac_negotiation_smoke.save")
	scene.game_started = true
	scene.menu_layer.hide()
	scene.game_layer.position = Vector2.ZERO
	scene.game_layer.show()
	var service := scene.campaign.zodiac
	service.progress.commit("rooster", "smoke", {}, ["emblem_unlocked"])
	service.choose_emblem(0, "rooster")
	scene.run_seed_input = "zodiac-ui-smoke"
	scene._start_campaign()
	await _pause()
	scene.event_table.unfocus_npc()
	var table: Control = scene.zodiac_table
	var layers := scene.event_table._npc_layers
	_check(not layers.zodiac.overlay.visible and not table.visible, "no Starter Zodiac visitor")
	scene.campaign._enter_phase(CampaignManager.CampaignPhase.MORNING_EVENT)
	await _pause()
	_check(layers.lotto.overlay.visible and layers.lotto.button.visible, "Morning Lottery Uncle keeps top-right slot")
	_check(not layers.zodiac.overlay.visible and not table.visible, "no Morning Zodiac visitor")
	scene.campaign._enter_phase(CampaignManager.CampaignPhase.NOON_EVENT)
	await _pause()
	_check(layers.zodiac.overlay.visible and layers.zodiac.button.visible, "Noon Zodiac is a normal NPC layer")
	_check(not layers.lotto.overlay.visible, "Noon has no Lottery Uncle")
	_check(table.portrait.texture.resource_path == ZodiacCatalog.sprite_path("rooster", true), "supplied overlay is used")
	_check(layers.zodiac.slot == &"top_right", "Zodiac occupies top-right slot")
	_check(not scene.event_table.continue_button.visible or scene.event_table.continue_button.disabled, "open negotiation gates Continue")
	await _capture("noon_cat_overview")
	await _tap(layers.zodiac.button)
	await _pause()
	_check(scene.event_table.focused_npc_id == "zodiac" and table.shade.visible, "native touch focuses Zodiac and opens negotiation")
	_check(table.character.texture.resource_path == ZodiacCatalog.sprite_path("rooster"), "focus uses real character PNG")
	_check(not scene.event_table.continue_button.visible, "focused Zodiac hides Continue")
	_check(table.contract_label.visible and not table.contract_label.text.is_empty(), "actual terms always visible")
	_check(not table.mechanics.visible, "only optional evening details are collapsed")
	for locale in ["en", "vi"]:
		TranslationServer.set_locale(locale)
		service.debug_offer(ZodiacDemand.make("PAY", "ANY", "PLAYER_CHOOSES", 1, "", 5000))
		table._build_conversation()
		await process_frame
		_check(table.contract_label.text.contains(VndWallet.format_vnd(5000)), "explicit localized cost " + locale)
		_check(table.choices.get_child_count() == 4, "Accept Refuse Haggle and history " + locale)
		_check(table.body.get_global_rect().encloses(table.choices.get_global_rect()), "actions fit panel " + locale)
		_check(Rect2(Vector2.ZERO, Vector2(root.size)).encloses(table.close_button.get_global_rect()), "Back fits viewport " + locale)
		var balance := scene.deal.wallet.balance_vnd
		await _click(table.choices.get_child(2))
		_check(table.contract_label.text.contains(VndWallet.format_vnd(2500)), "counteroffer terms revealed " + locale)
		_check(service.current_demand().resource_amount == 2500 and scene.deal.wallet.balance_vnd == balance, "Haggle is a preview, not a debit")
		_check(table.choices.get_child(2).disabled and not table.choices.get_child(0).disabled, "counteroffer waits for confirmation")
		await _capture("noon_counteroffer_" + locale)
	# Preview survives an actual disk save/load.
	var pending := service.current_demand().duplicate(true)
	_check(scene.session.run_save.save_run(scene.campaign, scene.deal), "pending counteroffer saves")
	_check(scene.session.run_save.restore(scene.session.run_save.load_run(), scene.campaign, scene.deal), "pending counteroffer restores")
	table.refresh()
	_check(service.current_demand() == pending and table.shade.visible, "saved counteroffer is unchanged")
	await _click(table.choices.get_child(0))
	_check(scene.deal.wallet.balance_vnd == 22500, "Accept pays confirmed counteroffer once")
	_check(scene.money_playback.displayed_balance == scene.deal.wallet.balance_vnd, "displayed wallet observes committed Zodiac payment")
	# Shared browser selects the exact offer and a multi-card valid group.
	for demand in [ZodiacDemand.make("SEAL", "OFFER_THREE", "PLAYER_CHOOSES"),
			ZodiacDemand.make("SEAL", "SAME_SUIT_2", "PLAYER_CHOOSES", 2)]:
		service.debug_offer(demand)
		table._build_conversation()
		await process_frame
		_check(table.choices.get_child(0).disabled, "card cost waits for physical selection")
		if demand.targeting == "OFFER_THREE": _check(table.target_preview.get_child_count() == 3, "three physical faces revealed")
		for index in int(demand.quantity):
			await _click(table.card_select_button)
			_check(scene.deck_screen.visible and scene.deck_screen._cards.size() == 52, "shared full deck opens")
			_check(scene.deck_screen._allowed.size() == 3 if demand.targeting == "OFFER_THREE" else scene.deck_screen._allowed.size() > 0, "service constrains selectable targets")
			var id: String = scene.deck_screen._allowed.keys()[0]
			var chosen := CardTargetQuery.resolve_ids(scene.campaign.gieo_que.persistent_deck, [id])[0]
			scene.deck_screen._inspect(chosen)
			await process_frame
			await _click(scene.deck_screen._confirm)
			_check(not scene.deck_screen.visible and table.selected_ids.size() == index + 1, "physical selection returns to negotiation")
		_check(not table.choices.get_child(0).disabled, "complete valid group can confirm")
		await _capture("noon_card_selection_" + String(demand.targeting))
		var ids: Array = table.selected_ids.duplicate()
		await _click(table.choices.get_child(0))
		for card in CardTargetQuery.resolve_ids(scene.campaign.gieo_que.persistent_deck, ids):
			_check(card.transformation_locked, "selected physical card sealed")
	service.debug_offer(ZodiacDemand.make("PROMISE", "ANY", "PLAYER_CHOOSES", 1, "", 0, {"condition": "dont_action", "action": "extension"}))
	table._build_conversation()
	await _click(table.choices.get_child(0))
	while service.has_open_demand(): service.respond("REFUSE")
	await _click(table.close_button)
	await _pause()
	_check(not layers.zodiac.overlay.visible and not table.shade.visible, "Zodiac leaves Noon after demands; normal NPCs remain")
	_check(layers.tra_da_auntie.overlay.visible and layers.thay_boi.overlay.visible, "normal Noon flow remains")
	_check(service.daily.promises.size() == 1, "Noon promise pending")
	scene.campaign._enter_phase(CampaignManager.CampaignPhase.AFTERNOON_DEAL)
	await _pause()
	service.finish_daytime_deal("afternoon")
	scene.campaign._enter_phase(CampaignManager.CampaignPhase.AFTERNOON_EVENT)
	await _pause(1.0)
	var receipt := root.get_node_or_null("LotteryReceipt")
	_check(receipt != null and receipt.find_child("LotteryHost", true, false) != null, "Lottery Uncle appears for Afternoon result")
	_check(not layers.lotto.overlay.visible and scene.event_table.focused_npc_id != "lotto", "Lottery Uncle absent from Afternoon event roster")
	await _capture("afternoon_lottery_result")
	await _dismiss_lottery()
	_check(layers.zodiac.overlay.visible and layers.zodiac.button.visible, "Zodiac returns in Afternoon top-right slot")
	_check(service.daily.promises.is_empty() and service.daily.last_result.resolved_successfully, "promise settles at Afternoon")
	await _click(layers.zodiac.button)
	await _pause()
	_check(table.shade.visible and table.status.text.contains("Đã giữ"), "Afternoon conversation shows each promise result")
	await _capture("afternoon_promise_result")
	for viewport_size in [Vector2i(1280, 720), Vector2i(1920, 1080)]:
		root.size = viewport_size
		await _pause(0.1)
		_check(Rect2(Vector2.ZERO, Vector2(root.size)).encloses(table.body.get_global_rect()), "conversation fits scaled viewport")
		_check(not table.close_button.get_global_rect().intersects(scene.event_table.back_button.get_global_rect()), "conversation Back clears EVENT Back")
	await _click(table.close_button)
	await _pause()
	# Every daytime visitor uses supplied artwork and native focus staging.
	for id: String in ZodiacCatalog.DEFINITIONS:
		if id == "dragon": continue
		var previous_id := scene.event_table.zodiac_id
		var previous_mask: BitMap = layers.zodiac.character_target.mask
		service.daily.id = id
		table.refresh()
		await process_frame
		_check(table.portrait.texture.resource_path == ZodiacCatalog.sprite_path(id, true), "real overlay " + id)
		var target := layers.zodiac.character_target as NpcTapTarget
		if id != previous_id: _check(target.mask != previous_mask, "silhouette mask refreshed " + id)
		var point := Vector2(-1, -1)
		var mask_size := target.mask.get_size()
		var factor := maxf(target.size.x / mask_size.x, target.size.y / mask_size.y)
		for y in mask_size.y:
			for x in range(mask_size.x - 1, -1, -1):
				if not target.mask.get_bit(x, y): continue
				var local := (Vector2(x, y) + Vector2.ONE * 0.5) * factor + (target.size - Vector2(mask_size) * factor) * 0.5
				var candidate := target.get_global_transform_with_canvas() * local
				if scene.event_table._npc_at(candidate) == "zodiac": point = candidate; break
			if point.x >= 0: break
		_check(point.x >= 0, "visible animal silhouette is tappable " + id)
		if point.x >= 0: await _tap_point(point)
		await _pause(0.05)
		_check(table.shade.visible and table.character.texture.resource_path == ZodiacCatalog.sprite_path(id), "real focus sprite and touch route " + id)
		table.close_conversation()
		await _pause()
	service.daily.id = "cat"
	scene.campaign._enter_phase(CampaignManager.CampaignPhase.EVENING_DEAL)
	await _pause()
	_check(not table.visible and scene.deal.zodiac_boss.id == "cat", "evening keeps boss service without daytime visitor")
	_check(scene.deal.zodiac_boss.difficulty == service.difficulty(), "final disposition feeds evening boss")
	for suffix in ["", ".bak", ".tmp"]: DirAccess.remove_absolute(scene.session.run_save.path + suffix)
	scene.queue_free()
	await _pause(0.2)
	print("ZODIAC_SCENE_SMOKE checks=%d failures=%d" % [checks, failures.size()])
	quit(0 if failures.is_empty() else 1)
