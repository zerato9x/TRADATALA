extends SceneTree

var failures: Array[String] = []
var checks := 0

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var args := OS.get_cmdline_user_args()
	root.size = Vector2i(2548, 1368) if "--wide" in args else Vector2i(1280, 720)
	var scene := load("res://scenes/match.tscn").instantiate() as MatchUI
	root.add_child(scene)
	current_scene = scene
	await process_frame
	scene.session.run_save = RunSave.new("user://menu-deal-smoke.json")
	scene.settings.set_locale("vi" if "--vi" in args else "en")
	scene.music.controller._stop_all_mix_players()
	scene.music.controller.music_director.stop()
	scene.front_end.set_process(false)
	scene.game_started = true
	scene.game_layer.position = Vector2.ZERO
	scene.menu_layer.hide()
	scene.deal.start_tutorial_deal()
	# Populate the turn register and leave a live hand and drink on the table.
	_check(scene.deal.discard_card(scene.deal.hand.back()).get("ok", false), "fixture discard succeeds")
	scene.interactions.locked = false
	scene._sync_all()
	scene.card_table.set_hand_interaction_enabled(true)
	await create_timer(0.4).timeout
	var before := scene.deal.snapshot_state()
	await _click(scene.menu_button)
	await create_timer(0.25).timeout
	_check(scene.menu_layer.visible and scene.front_end.page == "home", "pointer opens Home from the deal")
	_check(scene.interactions.locked, "menu locks deal actions")
	for view: PlayingCardView in scene.card_table.hand_views.values():
		_check(view.focus_mode == Control.FOCUS_NONE, "menu removes hand keyboard focus")
	_check(scene.menu_layer.z_index > scene.hand_layer.get_parent().z_index, "menu draws above the hand")
	_check(scene.menu_layer.z_index > scene.table_hud_presentation.history.z_index, "menu draws above the turn register")
	if "--capture" in args:
		await RenderingServer.frame_post_draw
		var over_deal := root.get_texture().get_image()
		var label := ("wide" if "--wide" in args else "base") + ("-vi" if "--vi" in args else "-en")
		over_deal.save_png("res://.godot/menu-deal-%s.png" % label)
		# The opaque menu backdrop must completely cover the deal underneath.
		scene.game_layer.hide()
		await process_frame
		await RenderingServer.frame_post_draw
		var without_deal := root.get_texture().get_image()
		_check(over_deal.get_data() == without_deal.get_data(), "rendered menu completely covers the active deal")
		scene.game_layer.show()
	var settings_button := scene.front_end.home_body.find_child("Settings", true, false) as Button
	await _click(settings_button)
	await process_frame
	_check(scene.front_end.page == "settings", "pointer reaches Settings above the deal")
	scene.front_end.go_back()
	await process_frame
	await process_frame
	var return_button := scene.front_end.home_body.get_child(0) as Button
	await _click(return_button)
	await create_timer(0.25).timeout
	_check(not scene.menu_layer.visible and not scene.interactions.locked, "Back to Game restores deal input")
	_check(scene.deal.snapshot_state() == before, "menu navigation preserves the entire deal snapshot")
	_check(scene.deal.physical_card_accounting_is_valid(), "resumed deal preserves physical card accounting")
	var card_view: PlayingCardView = scene.card_table.hand_views[scene.deal.hand.front().unique_id]
	await _click(card_view)
	await process_frame
	_check(scene.interactions.selected_ids.has(card_view.card.unique_id), "resumed hand accepts pointer selection")
	await _click(scene.menu_button)
	await create_timer(0.25).timeout
	_key(KEY_ESCAPE)
	await create_timer(0.25).timeout
	_check(not scene.menu_layer.visible and not scene.interactions.locked, "Escape closes a reopened menu")
	_check(scene.deal.snapshot_state() == before, "repeated menu use preserves the deal")
	for failure in failures: print("FAIL: ", failure)
	print("MENU_DEAL_SMOKE checks=%d failures=%d" % [checks, failures.size()])
	scene.queue_free()
	await process_frame
	quit(0 if failures.is_empty() else 1)

func _click(control: Control) -> void:
	var point := control.get_global_transform_with_canvas() * (control.size * 0.5)
	if DisplayServer.get_name() != "headless": Input.warp_mouse(root.get_final_transform() * point)
	var motion := InputEventMouseMotion.new()
	motion.position = point
	motion.global_position = point
	root.push_input(motion, true)
	await process_frame
	for pressed in [true, false]:
		var event := InputEventMouseButton.new()
		event.position = point
		event.global_position = point
		event.button_index = MOUSE_BUTTON_LEFT
		event.pressed = pressed
		root.push_input(event, true)

func _key(key: Key) -> void:
	for pressed in [true, false]:
		var event := InputEventKey.new()
		event.keycode = key
		event.physical_keycode = key
		event.pressed = pressed
		root.push_input(event, true)

func _check(ok: bool, message: String) -> void:
	checks += 1
	if not ok: failures.append(message)
