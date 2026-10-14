extends "res://tests/boss_presentation_smoke.gd"
## Native settings input and permanent-profile navigation in an isolated user profile.

func click(control: Control) -> void:
	await frames()
	var point := control.get_global_transform_with_canvas() * (control.size * 0.5)
	# Deliver one coherent pointer gesture before desktop motion can interleave.
	var motion := InputEventMouseMotion.new()
	motion.position = point
	motion.global_position = point
	root.push_input(motion, true)
	for down in [true, false]:
		var event := InputEventMouseButton.new()
		event.button_index = MOUSE_BUTTON_LEFT
		event.position = point
		event.global_position = point
		event.pressed = down
		root.push_input(event, true)
	await frames()

func key(code: Key) -> void:
	for down in [true, false]:
		var event := InputEventKey.new()
		event.keycode = code
		event.pressed = down
		root.push_input(event, true)
		await process_frame

func _run() -> void:
	rendered = DisplayServer.get_name() != "headless"
	capture_dir = "res://.godot/validation/forms-2026-10-13/screens"
	scene = load("res://scenes/match.tscn").instantiate() as MatchUI
	root.add_child(scene)
	current_scene = scene
	await frames()
	var front := scene.front_end
	var before_hand := scene.deal.hand.duplicate()
	var before_wallet := scene.deal.wallet.balance_vnd
	for locale in ["en", "vi"]:
		scene.settings.set_locale(locale)
		await frames(5)
		for extent in [Vector2i(1280, 720), Vector2i(960, 540), Vector2i(1920, 1080)]:
			root.size = extent
			await frames(5)
			var label := "%s-%dx%d" % [locale, extent.x, extent.y]
			front.show_settings()
			await create_timer(0.3).timeout
			for spec in [["ShowStrawy", "strawy_enabled"], ["Tutorial", "tutorial_enabled"], ["FirstSeed", "first_seed_enabled"]]:
				var toggle := front.settings_page.find_child(spec[0], true, false) as CheckButton
				var initial := bool(scene.settings.get(spec[1]))
				check(front.get_global_rect().encloses(toggle.get_global_rect()), label + spec[0] + " switch fits")
				await click(toggle)
				check(bool(scene.settings.get(spec[1])) != initial and toggle.button_pressed != initial, label + spec[0] + " pointer changes setting once")
				if spec[0] == "FirstSeed" and label == "en-1280x720": await capture("settings-off-state")
				toggle.grab_focus()
				await key(KEY_SPACE)
				check(bool(scene.settings.get(spec[1])) == initial and toggle.button_pressed == initial, label + spec[0] + " keyboard restores setting")
			for id in ["MusicVolume", "SoundVolume"]:
				var slider := front.settings_page.find_child(id, true, false) as HSlider
				slider.value = 40
				slider.grab_focus()
				await key(KEY_RIGHT)
				check(slider.value == 41, label + id + " keyboard adjusts native slider")
				var setting: float = scene.settings.music_volume_percent if id == "MusicVolume" else scene.settings.sound_volume_percent
				check(setting == slider.value, label + id + " volume follows control")
				check(front.get_global_rect().encloses(slider.get_global_rect()) and slider.size.y >= 44, label + id + " usable target fits")
			await capture(label + "-settings")
			front.show_save_files()
			await create_timer(0.3).timeout
			var buttons := front.files_body.find_children("SaveFile_*", "Button", true, false)
			check(buttons.size() == 3, label + " three file choices")
			var bottom := (buttons[0] as Button).get_global_rect().end.y
			for button: Button in buttons:
				check(front.get_global_rect().encloses(button.get_global_rect()), label + button.name + " action visible")
				check(is_equal_approx(button.get_global_rect().end.y, bottom), label + button.name + " action row aligned")
			var active := front.files_body.find_child("SaveFile_%d" % scene.session.save_files.active_slot, true, false) as Button
			check(active.disabled, label + " active file cannot be reloaded")
			var rename_action := front.files_body.find_child("SaveFileRename", true, false) as Button
			check(front.get_node("SafeArea/Frame/Main").get_global_rect().encloses(rename_action.get_global_rect()), label + " rename action fits without scrolling")
			await capture(label + "-files")
	check(scene.deal.hand == before_hand and scene.deal.wallet.balance_vnd == before_wallet, "settings and browsing preserve the current deal")
	root.size = Vector2i(1280, 720)
	await frames(5)
	front.show_save_files()
	await frames(5)
	await click(front.files_body.find_child("SaveFile_2", true, false))
	check(scene.session.save_files.active_slot == 2 and front.page == "home", "actual Create File button activates file two")
	front.show_save_files()
	await frames(5)
	var entry := front.files_body.find_child("SaveFileName", true, false) as LineEdit
	entry.text = "A long player name with forty characters!".left(40)
	var expected := entry.text
	var rename := front.files_body.find_child("SaveFileRename", true, false) as Button
	var scroll := front.pages.files.get_node("Scroll") as ScrollContainer
	rename.grab_focus()
	scroll.ensure_control_visible(rename)
	await frames(5)
	await click(rename)
	check(scene.session.save_files.data.name == expected, "rename action saves full long name")
	front.show_save_files()
	await frames(5)
	var summary := front.files_body.find_child("SaveFileSummary_1", true, false) as VBoxContainer
	var stat_top := (summary.get_child(2) as Control).global_position.y
	for slot in [2, 3]:
		summary = front.files_body.find_child("SaveFileSummary_%d" % slot, true, false)
		check(is_equal_approx((summary.get_child(2) as Control).global_position.y, stat_top), "long names preserve aligned file statistics")
	await capture("long-name-files")
	await click(front.files_body.find_child("SaveFile_1", true, false))
	check(scene.session.save_files.active_slot == 1, "Load File returns to original profile")
	front.show_settings()
	await frames(5)
	var language := front.settings_page.find_child("Language", true, false) as OptionButton
	language.select(1)
	language.item_selected.emit(1)
	await frames(5)
	check(scene.settings.locale_code == "en" and front.page == "settings", "language change rebuilds settings in place")
	print("FRONT_END_FORMS_SMOKE checks=%d failures=%d" % [checks, failures.size()])
	scene.music.controller._stop_all_mix_players()
	scene.music.controller.music_director.stop()
	scene.queue_free()
	await create_timer(0.3).timeout
	quit(0 if failures.is_empty() else 1)
