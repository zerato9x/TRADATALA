extends "res://tests/boss_presentation_smoke.gd"
## Rendered shelf navigation, descendant input, text bounds and read-only progress.

func _run() -> void:
	rendered = DisplayServer.get_name() != "headless"
	capture_dir = "res://.godot/validation/refinement-2026-10-13/screens"
	scene = load("res://scenes/match.tscn").instantiate() as MatchUI
	root.add_child(scene)
	current_scene = scene
	await frames()
	scene.session.restoring = true
	scene.session.run_save = RunSave.new("user://collection-refinement.save")
	scene.drink_manager.progress.save_path = ""
	scene.campaign.zodiac.progress = ZodiacProgress.new("")
	var front := scene.front_end
	var wallet := scene.deal.wallet.balance_vnd
	var hand := scene.deal.hand.duplicate()
	for locale in ["en", "vi"]:
		scene.settings.set_locale(locale)
		await frames()
		for extent in [Vector2i(1280, 720), Vector2i(960, 540), Vector2i(1920, 1080)]:
			root.size = extent
			await frames(5)
			var label := "%s-%dx%d" % [locale, extent.x, extent.y]
			front.show_home()
			front.show_setup()
			await frames(5)
			check(front.setup_body.find_children("DebtDay*", "PanelContainer", true, false).size() == 7, label + " seven debt rows")
			await capture(label + "-setup")
			for category in ["drinks", "zodiac"]:
				front.collection_tab = category
				front.selected_collection = ""
				front._render_collections()
				await create_timer(0.3).timeout
				var list := front.collection_body.find_child("CollectionListScroll", true, false) as ScrollContainer
				var grid := list.get_child(0) as GridContainer
				check(grid.get_minimum_size().x <= list.size.x, label + category + " shelf fits width")
				for tile: Button in grid.get_children():
					check(not tile.accessibility_name.is_empty(), label + tile.name + " accessible name")
					for copy: Label in tile.find_children("*", "Label", true, false):
						check(tile.get_global_rect().encloses(copy.get_global_rect()), label + tile.name + " caption stays inside tile")
				var target := grid.get_child(1) as Button
				var expected := String(target.name).trim_prefix("Collection_")
				await click(target.find_child("Thumbnail", true, false))
				await frames(5)
				check(front.selected_collection == expected, label + category + " thumbnail click selects")
				list = front.collection_body.find_child("CollectionListScroll", true, false)
				grid = list.get_child(0)
				var last := grid.get_child(grid.get_child_count() - 1) as Button
				expected = String(last.name).trim_prefix("Collection_")
				last.grab_focus()
				await frames(5)
				check(list.get_global_rect().encloses(last.get_global_rect()), label + category + " focus scrolls to last item")
				var accept := InputEventAction.new()
				accept.action = &"ui_accept"
				accept.pressed = true
				root.push_input(accept, true)
				accept = InputEventAction.new()
				accept.action = &"ui_accept"
				accept.pressed = false
				root.push_input(accept, true)
				await frames(5)
				check(front.selected_collection == expected, label + category + " keyboard selects last item")
				var selected := front.collection_body.find_child("Collection_" + expected, true, false) as Button
				check(selected.has_focus(), label + category + " selection retains focus")
				front.selected_collection = DrinkCatalog.TRA_DA if category == "drinks" else "rooster"
				front._render_collections()
				await frames(5)
				var display := front.collection_body.find_child("CollectionDisplay", true, false) as Control
				check(display.mouse_filter == Control.MOUSE_FILTER_IGNORE and not display.is_processing(), label + category + " decoration is static and passes input")
				await capture(label + "-" + category)
	check(scene.deal.wallet.balance_vnd == wallet and scene.deal.hand == hand, "browsing does not change wallet or cards")
	print("COLLECTION_REFINEMENT_SMOKE checks=%d failures=%d" % [checks, failures.size()])
	scene.music.controller._stop_all_mix_players()
	scene.music.controller.music_director.stop()
	scene.queue_free()
	await create_timer(0.3).timeout
	quit(0 if failures.is_empty() else 1)
