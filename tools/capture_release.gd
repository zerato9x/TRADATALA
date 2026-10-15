extends SceneTree
## Release photography: real MatchUI, staged deterministic encounters, isolated profile.
var scene: MatchUI
var captures: Array[Dictionary] = []
var output := "res://docs/releases/v1.1/screenshots"
const BOSSES := ["rooster", "cat", "dog", "monkey", "pig", "ox", "horse", "goat", "rat", "tiger", "snake"]

func _initialize() -> void: call_deferred("_run")

func pause(seconds: float = 0.6) -> void:
	await create_timer(seconds).timeout
	await process_frame

func capture(filename: String, caption: String, stage: String) -> void:
	scene.money_presentation.request_fast_forward()
	await pause(2.1)
	await RenderingServer.frame_post_draw
	var image := root.get_texture().get_image()
	var error := image.save_png(output + "/" + filename + ".png")
	if error != OK:
		push_error("Screenshot write failed: " + filename)
		quit(1)
		return
	captures.append({"file": filename + ".png", "caption": caption, "stage": stage,
		"locale": TranslationServer.get_locale(), "width": image.get_width(), "height": image.get_height(),
		"boss": scene.deal.zodiac_boss.id if stage == "evening" else scene.campaign.zodiac.active_id()})
	print("CAPTURE PASS " + filename)

func click(control: Control) -> void:
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

func prepare_noon(id: String) -> void:
	scene.zodiac_table.close_conversation()
	var day := 0
	for index in ZodiacCatalog.PAIRS.size():
		if id in ZodiacCatalog.PAIRS[index]: day = index
	var chosen := ""
	for index in 200:
		scene.campaign.run_seed = "TRADATALA-1.1-PRESS-%d" % index
		if ZodiacCatalog.select(scene.campaign.seed_for("zodiac_selection", day), day) == id:
			chosen = scene.campaign.run_seed
			break
	if chosen.is_empty():
		push_error("Unable to stage Zodiac " + id)
		quit(1)
		return
	scene.run_seed_input = chosen
	scene._start_campaign()
	await pause()
	scene.event_table.unfocus_npc()
	scene.campaign.current_day_index = day
	scene.campaign.zodiac.begin_day(day, scene.campaign.seed_for("zodiac_selection", day))
	scene.campaign._enter_phase(CampaignManager.CampaignPhase.NOON_EVENT)
	await pause(1.3)
	scene.event_table.unfocus_npc()

func evening(id: String) -> void:
	scene.zodiac_table.close_conversation()
	scene.event_table.unfocus_npc()
	scene.current_campaign_event = null
	scene.campaign.current_phase = CampaignManager.CampaignPhase.EVENING_DEAL
	scene.campaign.campaign_phase_changed.emit(scene.campaign.current_phase)
	scene.deal.wallet.reset(253000)
	scene.deal.start_tutorial_deal()
	scene.deal.set_current_drink(DrinkCatalog.TRA_DA)
	scene.deal.zodiac_boss.configure(id, 2, 14281)
	scene.deal.zodiac_boss.begin_phase(scene.deal)
	scene.deal.zodiac_boss.begin_turn(1, scene.deal.hand, scene.deal)
	scene.modal_overlay.hide()
	scene.score_overlay.hide()
	scene.interactions.locked = false
	scene.interactions.selected_ids.clear()
	scene.card_table.set_hand_interaction_enabled(true)
	scene.event_table.table_state = EventTableController.TABLE_STATE_DEAL
	scene.event_table._finish_event_exit()
	scene.money_playback.displayed_balance = scene.deal.wallet.balance_vnd
	scene.money_playback.queued_balance = scene.money_playback.displayed_balance
	scene._sync_all()
	await pause(1.4)

	# Use a real legal Meld where available, then capture the committed table.
	var recommendation := scene.deal.queries.recommend_action()
	if recommendation.action == HandAdvisor.ACTION_NEW_MELD and not recommendation.get("use_drink", false):
		var result := scene.deal.create_meld(recommendation.cards)
		if result.get("ok", false):
			scene._sync_all(result)
			scene.money_presentation.request_fast_forward()
			await pause(0.6)

func _run() -> void:
	if DisplayServer.get_name() == "headless":
		push_error("Release photography requires a renderer")
		quit(1)
		return
	root.size = Vector2i(1920, 1080)
	DirAccess.make_dir_recursive_absolute(output)
	var settings := root.get_node("GameSettings")
	settings.set_locale("en")
	settings.set_music_system("playing_tracks")
	settings.set_strawy_enabled(false)
	settings.set_tutorial_enabled(false)
	scene = load("res://scenes/match.tscn").instantiate() as MatchUI
	root.add_child(scene)
	current_scene = scene
	await pause(1.5)
	scene.session.restoring = true
	scene.session.save_files.suspended = true
	scene.session.run_save = RunSave.new("user://release-photography.save")
	scene.drink_manager.progress.save_path = ""
	scene.campaign.zodiac.progress = ZodiacProgress.new("")
	scene.front_end.show_home()
	await capture("01-home-en", "Welcome back to the sidewalk table.", "home")
	scene.game_started = true
	scene.menu_layer.hide()
	scene.game_layer.position = Vector2.ZERO
	scene.game_layer.show()
	for id: String in ["cat", "rooster", "monkey", "snake"]:
		await prepare_noon(id)
		if id == "cat":
			await capture("02-noon-table-en", "A Zodiac visitor joins the Noon event table.", "noon-overview")
		await click(scene.event_table._npc_layers.zodiac.button)
		await capture("03-conversation-" + id + "-en", "An authored conversation with " + ZodiacCatalog.display_name(id) + ".", "conversation")
		if id == "cat":
			settings.set_locale("vi")
			scene.zodiac_table._build_conversation()
			await capture("04-conversation-cat-vi", "Vietnamese dialogue and choices with Cat.", "conversation")
			settings.set_locale("en")
	for id: String in BOSSES:
		await prepare_noon(id)
		await evening(id)
		await capture("05-evening-" + id + "-en", "Evening at the table with " + ZodiacCatalog.display_name(id) + ".", "evening")
	GameGlossary.open_zodiac(scene, "snake")
	await capture("06-handbook-snake-en", "The Handbook explains each Zodiac's complete rules.", "handbook")
	var book := root.get_node_or_null("GameGlossary")
	if book != null: book.queue_free()
	await pause()
	scene.menu_layer.show()
	scene.front_end.show_collections()
	scene.front_end.collection_tab = "zodiac"
	scene.front_end.selected_collection = "cat"
	scene.front_end._render_collections()
	await capture("07-zodiac-collection-en", "Zodiac relationships, history and Emblem progression.", "collection")
	var manifest := {"version": ProjectSettings.get_setting("application/config/version"), "renderer": RenderingServer.get_current_rendering_method(),
		"capture_method": "Actual game framebuffer. Deterministic scenes staged through campaign and Deal APIs in an isolated profile; no image retouching.",
		"evening_fixture": "Normal-tier bosses, tutorial opening hand, VND253,000 opening wallet, Tra Da, and one legal Meld committed where the boss permits. These are staged gameplay screenshots, not a chronological player run.",
		"captures": captures}
	var file := FileAccess.open(output + "/captions.json", FileAccess.WRITE)
	file.store_string(JSON.stringify(manifest, "\t"))
	file.close()
	scene.music.controller._stop_all_mix_players()
	scene.music.controller.music_director.stop()
	scene.queue_free()
	await pause(0.3)
	print("RELEASE_PHOTOGRAPHY PASS captures=%d" % captures.size())
	quit(0)
