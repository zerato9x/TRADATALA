extends SceneTree
## Exercise actual table geometry and texture swaps, including resize/resume.

var scene: MatchUI
var checks := 0
var failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures.append(message)
		push_error(message)


func frames() -> void:
	await process_frame
	await process_frame
	await process_frame


func capture(label: String) -> void:
	if DisplayServer.get_name() == "headless": return
	var motion := InputEventMouseMotion.new()
	motion.position = Vector2(10, 100)
	root.push_input(motion, true)
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://.godot/drink-overhaul/%s.png" % label)


func reset_usage() -> void:
	scene.deal.current_phase = 1
	scene.deal.state = DealState.STATE_ACTIVE
	scene.deal.tra_da_used_this_turn = false
	scene.deal.nhan_tran_used_this_phase = false
	scene.deal.den_da_used_this_turn = false
	scene.deal.pair_used_this_turn = false
	scene.deal.c2_used = false
	scene.deal.nau_da_used_phases.clear()
	scene.deal.pair_used_phases.clear()
	scene.deal.nuoc_voi_used_phases.clear()


func spend(id: String) -> void:
	match id:
		DrinkCatalog.TRA_DA: scene.deal.tra_da_used_this_turn = true
		DrinkCatalog.NHAN_TRAN: scene.deal.nhan_tran_used_this_phase = true
		DrinkCatalog.DEN_DA: scene.deal.den_da_used_this_turn = true
		DrinkCatalog.BO_HUC: scene.deal.pair_used_this_turn = true
		DrinkCatalog.C2_ICED_TEA: scene.deal.c2_used = true
		DrinkCatalog.NAU_DA: scene.deal.nau_da_used_phases[1] = true
		DrinkCatalog.STING: scene.deal.pair_used_phases[1] = true
		DrinkCatalog.NUOC_VOI: scene.deal.nuoc_voi_used_phases[1] = true
		DrinkCatalog.SAM_DUA, DrinkCatalog.BAC_XIU: scene.deal.current_phase = 2


func verify_assets() -> void:
	for id in DrinkCatalog.all_ids():
		for fill in [DrinkPresentation.FULL, DrinkPresentation.HALF, DrinkPresentation.EMPTY]:
			var texture := DrinkPresentation.texture(id, fill)
			check(texture != null, "%s %s artwork loads" % [id, fill])
			if texture == null: continue
			check(texture.resource_path == "res://assets/drinks/%s_%s.png" % [id, fill], "%s %s has its own sprite" % [id, fill])
			check(texture.get_size() == DrinkPresentation.CANVAS_SIZE, "%s %s uses the shared canvas" % [id, fill])
			var image := texture.get_image()
			if image.is_compressed(): image.decompress()
			var contact := image.get_pixelv(Vector2i(DrinkPresentation.CONTACT_POINT))
			check(contact.a > 0.5, "%s %s glass base occupies the shared contact point" % [id, fill])
		check(DrinkPresentation.tint(id) == Color.WHITE, id + " keeps its supplied colors")
	var closed := DrinkPresentation.texture(DrinkCatalog.BO_HUC, DrinkPresentation.FULL).get_image()
	var opened := DrinkPresentation.texture(DrinkCatalog.BO_HUC, DrinkPresentation.HALF).get_image()
	var finished := DrinkPresentation.texture(DrinkCatalog.BO_HUC, DrinkPresentation.EMPTY).get_image()
	check(closed.get_data() != opened.get_data(), "Bo Huc changes from its supplied sealed can to its opened can")
	check(opened.get_data() == finished.get_data(), "Bo Huc finished state reuses the supplied opened can")
	check(DrinkPresentation.texture(DrinkCatalog.NONE) == null, "no Drink has no sprite")
	check(DrinkPresentation.texture("unknown") == null, "unknown art is not disguised as Tra Da")


func verify_table(window_size: Vector2i, label: String) -> void:
	root.size = window_size
	await frames()
	var slot := scene.drink_table_button.get_global_rect()
	var sprite_rect := scene.drink_table_texture.get_global_rect()
	var contact := sprite_rect.position + sprite_rect.size * DrinkPresentation.CONTACT_POINT / DrinkPresentation.CANVAS_SIZE
	var hand := scene.hand_layer.get_parent() as Control
	check(root.get_visible_rect().encloses(slot), label + " Drink slot stays inside the viewport")
	check(hand.get_global_rect().end.x <= slot.position.x, label + " Drink remains beside the hand")
	check(scene.drink_table_button.offset_left == -183.0 and scene.drink_table_button.offset_right == -71.0, label + " shared slot stays 64 pixels left of the previous outside-table placement")
	# The painted tabletop is smaller than its transparent layout Control.
	# Sample the background under the contact point using KEEP_ASPECT_COVERED's
	# scale/crop transform; the old position was on the pavement at this height.
	var background := scene.get_node("SidewalkTableBackground") as TextureRect
	var painted := background.texture.get_image()
	var cover := maxf(background.size.x / painted.get_width(), background.size.y / painted.get_height())
	var origin := background.global_position + (background.size - Vector2(painted.get_size()) * cover) * 0.5
	var source_point := Vector2i((contact - origin) / cover)
	var surface := painted.get_pixelv(source_point)
	check(surface.b > surface.r * 1.4 and surface.b > surface.g * 1.4, label + " vessel contact is on the painted blue tabletop")
	check(slot.end.y <= (scene.get_node("GameLayer/ActionDock") as Control).global_position.y, label + " Drink nameplate stays above the action dock")
	for id in DrinkCatalog.all_ids():
		reset_usage()
		scene.deal.set_current_drink(id)
		var before := scene.deal.snapshot_state()
		scene._sync_drink_table_visual()
		check(before == scene.deal.snapshot_state(), id + " visual refresh does not change gameplay")
		check(scene.drink_table_texture.texture == DrinkPresentation.texture(id), id + " unused table Drink shows full artwork")
		spend(id)
		scene._sync_drink_table_visual()
		var expected := DrinkPresentation.FULL if id in [DrinkCatalog.MIA_TAC, DrinkCatalog.MIA_SAU_RIENG] else DrinkPresentation.HALF
		if id in [DrinkCatalog.C2_ICED_TEA, DrinkCatalog.SAM_DUA, DrinkCatalog.BAC_XIU]: expected = DrinkPresentation.EMPTY
		check(scene.drink_table_texture.texture == DrinkPresentation.texture(id, expected), id + " consumption follows its actual usage window")
		scene.deal.state = DealState.STATE_DEAL_OVER
		scene._sync_drink_table_visual()
		check(scene.drink_table_texture.texture == DrinkPresentation.texture(id, DrinkPresentation.EMPTY), id + " finished Deal shows its own empty vessel")
		check(scene.drink_table_button.get_global_rect() == slot and scene.drink_table_texture.get_global_rect() == sprite_rect, id + " fill changes never move or resize the table slot")
		check(sprite_rect.position + sprite_rect.size * DrinkPresentation.CONTACT_POINT / DrinkPresentation.CANVAS_SIZE == contact, id + " retains the table contact point")
		reset_usage()
		scene._sync_drink_table_visual()
		check(scene.drink_table_texture.texture == DrinkPresentation.texture(id), id + " refreshed usage restores full artwork")
		# Changing the chosen serving and the campaign period must not move it.
		scene.drink_manager.morning_drink_id = DrinkCatalog.TRA_DA
		scene.drink_manager.afternoon_drink_id = id
		scene.campaign.current_phase = CampaignManager.CampaignPhase.EVENING_DEAL
		scene._sync_drink_table_visual()
		check(scene.drink_table_button.get_global_rect() == slot, id + " serving/period change keeps the same slot")
	reset_usage()
	scene.deal.set_current_drink(DrinkCatalog.C2_ICED_TEA)
	scene._sync_all()
	await frames()
	await capture("table-" + label)


func _run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://.godot/drink-overhaul"))
	scene = load("res://scenes/match.tscn").instantiate() as MatchUI
	root.add_child(scene)
	current_scene = scene
	await frames()
	scene.session.run_save = RunSave.new("user://drink-presentation.save")
	scene.settings.set_locale("en")
	scene.game_started = true
	scene.menu_layer.hide()
	scene.game_layer.position = Vector2.ZERO
	scene.deal.start_tutorial_deal()
	scene.interactions.locked = false
	scene._sync_all()
	verify_assets()
	for entry in [[Vector2i(1280, 720), "base"], [Vector2i(960, 620), "small"], [Vector2i(1920, 1080), "large"], [Vector2i(2548, 1368), "wide"]]:
		await verify_table(entry[0], entry[1])
	root.size = Vector2i(1280, 720)
	await frames()
	reset_usage()
	scene.deal.set_current_drink(DrinkCatalog.NUOC_VOI)
	scene.deal.nuoc_voi_used_phases[2] = true
	scene.deal.current_phase = 2
	scene._sync_drink_table_visual()
	check(scene.drink_table_texture.texture == DrinkPresentation.texture(DrinkCatalog.NUOC_VOI, DrinkPresentation.EMPTY), "last phase charge uses empty artwork")
	var saved := scene.deal.snapshot_state()
	scene.deal.set_current_drink(DrinkCatalog.STING)
	scene.deal.restore_snapshot(saved)
	scene._sync_drink_table_visual()
	check(scene.drink_table_texture.texture == DrinkPresentation.texture(DrinkCatalog.NUOC_VOI, DrinkPresentation.EMPTY), "restored usage restores the correct sprite")
	for id in [DrinkCatalog.TRA_DA, DrinkCatalog.STING, DrinkCatalog.BO_HUC]:
		reset_usage()
		scene.deal.set_current_drink(id)
		scene._sync_all()
		await capture(id + "-full")
		spend(id)
		scene._sync_all()
		await capture(id + "-half")
		scene.deal.state = DealState.STATE_DEAL_OVER
		scene._sync_all()
		await capture(id + "-empty")
	scene._start_campaign()
	scene.drink_manager.test_all_drinks_available = true
	scene._show_campaign_event(scene.current_campaign_event)
	scene.event_table.focus_npc(EventTableController.NPC_TRA_DA)
	await create_timer(0.5).timeout
	var shop := scene.event_table.participants_container.get_child(0) as DrinkShop
	check(shop != null, "real event opens the Drink shop")
	if shop != null:
		for id in DrinkCatalog.all_ids():
			var sprite := (shop._buttons[id] as Button).find_child("DrinkSprite", true, false) as TextureRect
			check(sprite != null and sprite.texture == DrinkPresentation.texture(id), id + " shop shows its own full art")
		await capture("shop")
	scene._on_menu_pressed()
	await create_timer(0.25).timeout
	check(scene.menu_layer.is_visible_in_tree(), "collection opens through the real menu")
	scene.front_end.collection_tab = "drinks"
	for id in DrinkCatalog.all_ids():
		scene.front_end.selected_collection = id
		scene.front_end._render_collections()
		var sprite := scene.front_end.pages.collections.find_child("DrinkCollectionSprite", true, false) as TextureRect
		check(sprite != null and sprite.texture == DrinkPresentation.texture(id), id + " collection shows matching art")
	await frames()
	check(scene.front_end.pages.collections.is_visible_in_tree(), "matching collection art is visible")
	scene.front_end.selected_collection = DrinkCatalog.BO_HUC
	scene.front_end._render_collections()
	await frames()
	await capture("collection")
	scene.deal.set_current_drink(DrinkCatalog.NONE)
	scene._sync_drink_table_visual()
	check(not scene.drink_table_button.visible, "no Drink hides the single slot")
	scene.music.controller._stop_all_mix_players()
	scene.music.controller.music_director.stop()
	scene.queue_free()
	await frames()
	print("DRINK_PRESENTATION_SMOKE checks=%d failures=%d" % [checks, failures.size()])
	quit(0 if failures.is_empty() else 1)
