extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _capture(label: String) -> void:
	await RenderingServer.frame_post_draw
	var image := root.get_texture().get_image()
	image.save_png("res://.godot/front-%s.png" % label)

func _run() -> void:
	var args := OS.get_cmdline_user_args()
	var name := "base"
	var size := Vector2i(1280, 720)
	if "--wide" in args:
		name = "wide"
		size = Vector2i(2548, 1368)
	elif "--large" in args:
		name = "large"
		size = Vector2i(1920, 1080)
	elif "--small" in args:
		name = "small"
		size = Vector2i(960, 540)
	root.size = size
	var scene: MatchUI = load("res://scenes/match.tscn").instantiate()
	root.add_child(scene)
	current_scene = scene
	await process_frame
	scene.session.run_save = RunSave.new("user://front-capture-%d.save" % Time.get_ticks_usec())
	var original_locale: String = scene.settings.locale_code
	scene.settings.set_locale("vi" if "--vi" in args else "en")
	name += "-vi" if "--vi" in args else "-en"
	scene.front_end.show_home()
	await create_timer(0.1).timeout
	await _capture(name + "-home")
	scene.front_end.show_setup()
	await create_timer(0.1).timeout
	await _capture(name + "-setup")
	scene.front_end.customizing = true
	scene.front_end._render_setup()
	await create_timer(0.25).timeout
	await _capture(name + "-customize")
	scene.front_end.show_collections()
	await create_timer(0.1).timeout
	await _capture(name + "-collection")
	scene.front_end.collection_tab = "zodiac"
	scene.front_end.selected_collection = "rooster"
	scene.front_end._render_collections()
	await create_timer(0.25).timeout
	await _capture(name + "-zodiac")
	scene.front_end.show_music()
	await create_timer(0.1).timeout
	await _capture(name + "-music")
	scene.front_end.show_settings()
	await create_timer(0.1).timeout
	await _capture(name + "-settings")
	GameGlossary.open(scene)
	await create_timer(0.25).timeout
	await _capture(name + "-handbook")
	root.get_node("GameGlossary").queue_free()
	await process_frame
	scene.deck_screen.open_deck(scene.deal.deck.draw_pile, GameGlossary.words("DECK", "BỘ BÀI"), "")
	await create_timer(0.25).timeout
	await _capture(name + "-deck")
	scene.deck_screen.close()
	scene.game_started = true
	scene.menu_layer.hide()
	scene.game_layer.position = Vector2.ZERO
	scene.deal.start_tutorial_deal()
	scene.interactions.locked = false
	scene._sync_all()
	await create_timer(0.3).timeout
	await _capture(name + "-table")
	scene.settings.set_locale(original_locale)
	scene.music.controller._stop_all_mix_players()
	scene.music.controller.music_director.stop()
	scene.queue_free()
	await process_frame
	quit()
