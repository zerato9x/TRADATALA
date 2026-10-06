extends SceneTree
var scene: MatchUI
var checks := 0
var failures: Array[String] = []
var focuses := 0

func _initialize() -> void:
	call_deferred("_run")

func check(ok: bool, text: String) -> void:
	checks += 1
	if not ok: failures.append(text); push_error(text)

func pause(seconds: float = 0.4) -> void:
	await create_timer(seconds).timeout

func touch(point: Vector2, down: bool, index: int = 0) -> void:
	var event := InputEventScreenTouch.new()
	event.position = point
	event.pressed = down
	event.index = index
	root.push_input(event, true)

func tap(control: Control, emulated: bool = false) -> void:
	await process_frame
	var point := control.get_global_transform_with_canvas() * (control.size * 0.5)
	touch(point, true)
	touch(point, false)
	if emulated:
		for down in [true, false]:
			var mouse := InputEventMouseButton.new()
			mouse.device = -1
			mouse.position = point
			mouse.button_index = MOUSE_BUTTON_LEFT
			mouse.pressed = down
			root.push_input(mouse, true)
	await process_frame

func mouse_click(control: Control) -> void:
	await process_frame
	await mouse_at(control.get_global_transform_with_canvas() * (control.size * 0.5))

func mouse_at(point: Vector2) -> void:
	for down in [true, false]:
		var e := InputEventMouseButton.new()
		e.position = point
		e.button_index = MOUSE_BUTTON_LEFT
		e.pressed = down
		root.push_input(e, true)
	await process_frame

func capture(label: String) -> void:
	if DisplayServer.get_name() != "headless":
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://.godot/strawy-%s%s.png" % [label, "-large" if "--large" in OS.get_cmdline_user_args() else ""])

func overview() -> void:
	if root.has_node("LotteryReceipt"): root.get_node("LotteryReceipt").queue_free()
	await process_frame
	scene.event_table.back_button.disabled = false
	scene.event_table.unfocus_npc()
	await pause()

func silhouette_point(target: NpcTapTarget, id: String) -> Vector2:
	for y in range(80, 600, 10):
		for x in range(8, 1270, 10):
			var point := target.get_global_transform_with_canvas() * Vector2(x,y)
			if target.hits_global(point) and scene.event_table._npc_at(point) == id: return point
	return Vector2(-100,-100)

func _run() -> void:
	root.size = Vector2i(1920,1080) if "--large" in OS.get_cmdline_user_args() else Vector2i(1280,720)
	scene = load("res://scenes/match.tscn").instantiate()
	root.add_child(scene)
	current_scene = scene
	await pause(0.7)
	scene.session.run_save = RunSave.new("user://strawy-%d.save" % Time.get_ticks_usec())
	scene.drink_manager.progress.save_path = ""
	scene.settings.set_music_system("playing_tracks")
	scene.settings.set_locale("vi" if "--vi" in OS.get_cmdline_user_args() else "en")
	check(not scene.strawy.actor.is_visible_in_tree(), "Strawy stays out of Home")
	check(not scene.strawy.box.visible, "no unrequested speech")
	check(scene.strawy.hats.size() == 8 and scene.strawy.expressions.size() == 16, "all supplied poses and expressions load")
	await capture("home" + ("-vi" if "--vi" in OS.get_cmdline_user_args() else "-en"))
	scene.strawy.open_help()
	scene.strawy.start_tour()
	check(not scene.strawy.box.visible and scene.strawy.tour.is_empty(), "hidden helper cannot open a menu or tour")
	scene.front_end._show_page("settings")
	await pause(0.3)
	check(scene.front_end.find_child("ShowStrawy",true,false) != null and scene.front_end.find_child("Tutorial",true,false) != null and scene.front_end.find_child("FirstSeed",true,false) != null, "independent helper, tutorial, and seed settings controls")
	await capture("settings" + ("-vi" if "--vi" in OS.get_cmdline_user_args() else "-en"))
	check(not scene.strawy.actor.is_visible_in_tree() and scene.front_end.footer.get_node_or_null("StrawyDockSpace") == null, "Settings has no helper or reserved helper space")
	scene.front_end.show_home()
	scene.session.restoring = true
	await scene._on_play_pressed()
	scene.session.restoring = false
	await pause(3)
	scene.event_table.npc_focused.connect(func(_id): focuses += 1)
	await overview()
	check(scene.strawy.actor.is_visible_in_tree(), "Strawy appears during the campaign")
	if DisplayServer.get_name() != "headless":
		for i in 8:
			scene.strawy.pose = i
			scene.strawy.expression = i * 2
			scene.strawy.reaction_until = scene.strawy.clock + 0.3
			await process_frame
			await capture("pose-%d" % i)
	await tap(scene.strawy.hit, true)
	await pause()
	check(scene.strawy.box.visible, "single native tap opens the small menu exactly once")
	check(scene.strawy.actions.get_child_count() <= 4, "helper menu has at most three relevant actions")
	scene.strawy.close()
	await tap(scene.strawy.hit)
	await tap(scene.strawy.hit)
	await pause(0.6)
	check(not scene.strawy.tour.is_empty(), "Event double tap starts a pointing tour")
	scene.strawy.close()
	await pause()
	var corner := scene.strawy.hit.get_global_rect().get_center()
	touch(corner,true)
	touch(corner+Vector2(50,0),true,1)
	touch(corner,false)
	touch(corner+Vector2(50,0),false,1)
	await pause()
	check(not scene.strawy.box.visible, "second finger cancels helper tap")
	if scene.zodiac_table.badge.is_visible_in_tree():
		await tap(scene.zodiac_table.badge,true)
		check(scene.zodiac_table.shade.visible and scene.event_table.focused_npc_id.is_empty(),"native touch on the Zodiac visitor cannot select an NPC underneath")
		scene.zodiac_table.close_conversation()
	check(not scene.strawy.actor.get_global_rect().intersects(scene.game_layer.get_node("ActionDock").get_global_rect()), "action dock clears Strawy")
	for slot in [0,1,2,3]:
		if slot > 0:
			var phases := [CampaignManager.CampaignPhase.MORNING_EVENT,CampaignManager.CampaignPhase.NOON_EVENT,CampaignManager.CampaignPhase.AFTERNOON_EVENT]
			scene.campaign._enter_phase(phases[slot-1])
			await pause(0.6)
			await overview()
		for id in EventTableController.EVENT_ROSTERS[slot]:
			var button: Button = scene.event_table._npc_layers[id]["button"]
			check(button.visible and button.size.y >= 48, "visible touch label " + id)
			var before := focuses
			await tap(button, true)
			check(scene.event_table.focused_npc_id == id and focuses == before + 1, "native plus emulated touch activates once " + id)
			await tap(button,true)
			check(scene.event_table.focused_npc_id == id and focuses == before+1,"repeated tap cannot refocus or activate a hidden selector " + id)
			if id == EventTableController.NPC_THAY_BOI:
				await pause(0.4)
				await capture("npc" + ("-vi" if "--vi" in OS.get_cmdline_user_args() else "-en"))
			await overview()
			var target: NpcTapTarget = scene.event_table._npc_layers[id]["character_target"]
			var point := silhouette_point(target,id)
			check(point.x >= 0, "character has a silhouette target " + id)
			touch(point,true)
			touch(point,false)
			await process_frame
			check(scene.event_table.focused_npc_id == id, "character touch selects correct NPC " + id)
			await overview()
			await mouse_at(point)
			check(scene.event_table.focused_npc_id == id,"mouse character target selects correct NPC " + id)
			await overview()
			await mouse_click(button)
			check(scene.event_table.focused_npc_id == id, "mouse label selects correct NPC " + id)
			await overview()
		var overlap_checks := 0
		for y in range(80,600,24):
			for x in range(8,1270,24):
				var world := scene.event_table.get_global_transform_with_canvas() * Vector2(x,y)
				var hits: Array[String] = []
				var label_hit := false
				for id in scene.event_table._npc_layers:
					if scene.event_table._npc_layers[id].button.hits_global(world): label_hit = true
					if scene.event_table._npc_layers[id].character_target.hits_global(world): hits.append(id)
				if hits.size() < 2 or label_hit: continue
				hits.sort_custom(func(a,b): return scene.event_table._npc_layers[a].overlay.get_index() > scene.event_table._npc_layers[b].overlay.get_index())
				check(scene.event_table._npc_at(world) == hits[0],"overlap selects the visibly frontmost character")
				overlap_checks += 1
				if overlap_checks >= 3: break
			if overlap_checks >= 3: break
	await capture("event" + ("-vi" if "--vi" in OS.get_cmdline_user_args() else "-en"))
	var gap := scene.event_table.get_global_transform_with_canvas() * Vector2(860,260)
	touch(gap,true)
	touch(gap,false)
	check(scene.event_table.focused_npc_id.is_empty(),"transparent gap inside the old broad Lottery rectangle does not select an NPC")
	var label: Control = scene.event_table._npc_layers.lotto.button
	var point := label.get_global_rect().get_center()
	var press := InputEventMouseButton.new()
	press.position = point
	press.button_index = MOUSE_BUTTON_LEFT
	press.pressed = true
	root.push_input(press,true)
	var motion := InputEventMouseMotion.new()
	motion.position = point+Vector2(30,0)
	motion.relative = Vector2(30,0)
	motion.button_mask = MOUSE_BUTTON_MASK_LEFT
	root.push_input(motion,true)
	var release := InputEventMouseButton.new()
	release.position = point
	release.button_index = MOUSE_BUTTON_LEFT
	release.pressed = false
	root.push_input(release,true)
	check(scene.event_table.focused_npc_id.is_empty(),"mouse drag cancels name-button activation")
	touch(point,true)
	var drag := InputEventScreenDrag.new()
	drag.index = 0
	drag.position = point + Vector2(30,0)
	root.push_input(drag,true)
	touch(point,false)
	check(scene.event_table.focused_npc_id.is_empty(), "drag cancels activation even on return")
	touch(point,true)
	touch(point+Vector2(0,100),false)
	check(scene.event_table.focused_npc_id.is_empty(), "outside release cancels")
	touch(point,true)
	var cancelled := InputEventScreenTouch.new()
	cancelled.index = 0
	cancelled.position = point
	cancelled.pressed = false
	cancelled.canceled = true
	root.push_input(cancelled,true)
	check(scene.event_table.focused_npc_id.is_empty(), "OS-canceled touch cannot activate")
	touch(point,true)
	touch(point+Vector2(40,0),true,1)
	touch(point,false)
	touch(point+Vector2(40,0),false,1)
	check(scene.event_table.focused_npc_id.is_empty(), "second finger cancels selection")
	touch(point,true)
	scene.event_table._notification(Control.NOTIFICATION_WM_WINDOW_FOCUS_OUT)
	touch(point,false)
	check(scene.event_table.focused_npc_id.is_empty(), "interrupted touch cancels selection")
	for id in scene.event_table._npc_layers:
		var button: Control = scene.event_table._npc_layers[id].button
		if not button.visible: continue
		for other_id in scene.event_table._npc_layers:
			var other: Control = scene.event_table._npc_layers[other_id].button
			if other_id != id and other.visible: check(not button.get_global_rect().intersects(other.get_global_rect()), "NPC name targets do not overlap")
	await overview()
	scene.strawy.open_help()
	await tap(label)
	check(scene.event_table.focused_npc_id.is_empty(), "Strawy menu blocks NPC selection")
	scene.strawy.close()
	scene.campaign._enter_phase(CampaignManager.CampaignPhase.STARTER_EVENT)
	await pause()
	await overview()
	scene._on_campaign_drink_pressed(0,"choose_drink",DrinkCatalog.TRA_DA)
	scene.campaign.complete_current_event()
	await pause(0.8)
	check(scene.current_campaign_event == null and not scene.interactions.locked, "real Deal accepts helper actions")
	var displayed_odds := MeldProbabilityAdvisor.best_new_meld_chance_by_card(scene.deal.hand,scene.deal.queries.probability_draw_pool(),scene.deal.queries.probability_draw_horizon())
	var ready_card: CardData
	var chance_card: CardData
	for c in scene.deal.hand:
		var view: PlayingCardView = scene.card_table.hand_views[c.unique_id]
		check(not view._meld_chance_badge.visible and view.get_node_or_null("PlayableLabel") == null and view.get_node_or_null("MeldChance/KeepDetails") == null,"idle card has no badge, text label, or advice hit target")
		view._on_mouse_entered()
		var candidate: Dictionary = displayed_odds.get(c.unique_id,{})
		var ready: bool = candidate.get("ready",false)
		if ready:
			check(view._meld_chance_icon.visible and view._meld_chance_value.text.is_empty(),"ready card shows only the straw symbol on hover")
			ready_card = c
		else:
			check(not view._meld_chance_icon.visible and view._meld_chance_value.text == "%d%%" % roundi(candidate.get("probability",0.0) * 100.0),"hover percentage uses the original meld odds")
			chance_card = c
		view._on_mouse_exited()
	await capture("deal-ready" + ("-vi" if "--vi" in OS.get_cmdline_user_args() else "-en"))
	if ready_card != null:
		scene.card_table.hand_views[ready_card.unique_id]._on_mouse_entered()
		await pause(0.25)
		await capture("odds-ready" + ("-vi" if "--vi" in OS.get_cmdline_user_args() else "-en"))
		scene.card_table.hand_views[ready_card.unique_id]._on_mouse_exited()
	if chance_card != null:
		scene.card_table.hand_views[chance_card.unique_id]._on_mouse_entered()
		await pause(0.25)
		await capture("odds-percent" + ("-vi" if "--vi" in OS.get_cmdline_user_args() else "-en"))
		scene.card_table.hand_views[chance_card.unique_id]._on_mouse_exited()
	scene.strawy.open_help()
	await pause()
	check(scene.strawy.actions.get_child_count() <= 4 and scene.strawy.box.size.y < 340,"Deal menu is compact and contains only relevant actions")
	await capture("menu" + ("-vi" if "--vi" in OS.get_cmdline_user_args() else "-en"))
	scene.strawy.close()
	await tap(scene.strawy.hit,true)
	await tap(scene.strawy.hit,true)
	check(not scene.strawy.quick_action.is_empty() and scene.strawy.box.visible and scene.strawy.actions.get_child_count() == 1,"Deal double tap previews a legal move with a speech bubble")
	await capture("discard-preview" + ("-vi" if "--vi" in OS.get_cmdline_user_args() else "-en"))
	scene.strawy.close()
	var detail_card: CardData = scene.deal.hand[0]
	scene.interactions.selected_ids.clear()
	scene.interactions.selected_ids[detail_card.unique_id] = true
	scene.strawy.open_help()
	await process_frame
	await tap(scene.strawy.box.find_child("StrawyCardInfo",true,false),true)
	check(scene.strawy.box.visible and scene.strawy.copy.text.contains(detail_card.short_label()), "Strawy's requested card-info action opens details once")
	scene.strawy.close()
	scene.deal.zodiac_boss.locked_ids.append(detail_card.unique_id)
	scene._sync_all()
	scene.strawy.explain_card(detail_card)
	(scene.strawy.actions.get_child(-1) as Button).pressed.emit()
	await process_frame
	var card_book := root.get_node_or_null("GameGlossary") as GameGlossary
	check(card_book != null and card_book._entries[0].body.contains(GameGlossary.words("Locked", "khóa")), "Requested locked-card detail is available in Handbook")
	if card_book != null: card_book.queue_free()
	await process_frame
	scene.strawy.close()
	scene.deal.zodiac_boss.locked_ids.erase(detail_card.unique_id)
	scene._sync_all()
	var before_meld: int = scene.deal.action_counts.get("new_meld",0)
	scene.strawy._command("play")
	await pause()
	check(scene.deal.action_counts.get("new_meld",0) == before_meld+1, "one helper request performs one real meld")
	for card in scene.deal.hand:
		var view: PlayingCardView = scene.card_table.hand_views[card.unique_id]
		check(not view._meld_chance_badge.visible and not view._meld_chance_value.text.contains(GameGlossary.words("KEEP","GIỮ")), "card odds stay hidden and omit Keep scores " + card.unique_id)
	var discard_before := scene.deal.discard_history.size()
	scene.strawy._command("discard")
	await pause()
	check(scene.deal.discard_history.size() == discard_before+1, "one helper request performs one real discard")
	check(scene.deal.tra_da_extra_discard_pending, "extra discard is left to a separate request")
	check(scene.deal.physical_card_accounting_is_valid(), "helper retains physical identities")
	var saved := scene.session.run_save.load_run()
	check(not saved.is_empty() and saved.deal.discard_history.size() == scene.deal.discard_history.size() and saved.deal.wallet_balance_vnd == scene.deal.wallet.balance_vnd, "helper commits through ordinary autosave and wallet flow")
	await capture("deal" + ("-vi" if "--vi" in OS.get_cmdline_user_args() else "-en"))
	scene.interactions.selected_ids[scene.deal.hand[0].unique_id] = true
	scene.strawy.open_help()
	scene.strawy._explain_cards()
	check(scene.strawy.copy.text.contains(scene.deal.hand[0].short_label()) and scene.strawy.copy.text.contains("100"), "touch-accessible selected card Keep details")
	await capture("help" + ("-vi" if "--vi" in OS.get_cmdline_user_args() else "-en"))
	scene.strawy.close()
	scene.strawy.start_tour()
	var tour_snapshot := var_to_str(scene.deal.snapshot_state())
	await pause(0.7)
	check(not scene.strawy.tour.is_empty() and scene.strawy.box.visible, "tour stays open through queued money feedback")
	check(var_to_str(scene.deal.snapshot_state()) == tour_snapshot, "pointing never activates a card action")
	await capture("tour" + ("-vi" if "--vi" in OS.get_cmdline_user_args() else "-en"))
	scene.strawy.close()
	GameGlossary.open(scene,"core")
	await pause()
	check(scene.strawy.actor.is_visible_in_tree(), "Strawy remains above Handbook")
	check(not scene.strawy.can_play_cards(), "Handbook prevents gameplay commands")
	await capture("handbook" + ("-vi" if "--vi" in OS.get_cmdline_user_args() else "-en"))
	var unchanged := var_to_str(scene.deal.snapshot_state())
	scene.strawy._command("discard")
	check(var_to_str(scene.deal.snapshot_state()) == unchanged, "unavailable helper command cannot mutate state")
	scene.strawy.start_tour()
	check(scene.strawy.tour[0].control == root.get_node("GameGlossary")._search, "tour targets the topmost Handbook")
	scene.strawy.close()
	root.get_node("GameGlossary").queue_free()
	await process_frame
	scene.deck_screen.open_deck(scene.campaign.gieo_que.persistent_deck,GameGlossary.words("Your deck","Bộ bài của bạn"),"")
	await pause()
	check(scene.deck_screen.visible and not scene.strawy.can_play_cards(), "deck inspection blocks helper commands")
	check(scene.deck_screen._back.text == GameGlossary.words("Back","Về bàn"), "deck navigation follows the current locale")
	await capture("deck" + ("-vi" if "--vi" in OS.get_cmdline_user_args() else "-en"))
	scene.deck_screen.close()
	scene._ensure_resolve_receipt()
	scene.resolve_receipt.show_report(scene.deal.accounting_report(),"deal",GameGlossary.words("DEAL RESULTS","KẾT QUẢ VÁN"),GameGlossary.words("CONTINUE","TIẾP TỤC"))
	await pause(0.8)
	check(scene.strawy.actor.is_visible_in_tree() and not scene.strawy.can_play_cards(), "results keep Strawy visible and block card actions")
	await capture("results" + ("-vi" if "--vi" in OS.get_cmdline_user_args() else "-en"))
	print("STRAWY_SCENE_SMOKE checks=%d failures=%d" % [checks,failures.size()])
	quit(0 if failures.is_empty() else 1)
