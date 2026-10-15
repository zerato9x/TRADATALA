extends "res://tests/boss_presentation_smoke.gd"
## Exercise the public portraits through the real Collections button and Handbook search.
func _run() -> void:
	rendered = DisplayServer.get_name() != "headless"
	capture_dir = "res://.godot/text-refinement/screens"
	root.size = Vector2i(1280, 720)
	scene = load("res://scenes/match.tscn").instantiate() as MatchUI
	root.add_child(scene)
	current_scene = scene
	await frames()
	scene.session.restoring = true
	scene.campaign.zodiac.progress = ZodiacProgress.new("")
	scene.front_end.show_collections()
	for viewport: Vector2i in [Vector2i(1280, 720), Vector2i(960, 720)]:
		root.size = viewport
		for locale: String in ["en", "vi"]:
			scene.settings.set_locale(locale)
			for id: String in ZodiacCatalog.DEFINITIONS:
				scene.front_end.collection_tab = "zodiac"
				scene.front_end.selected_collection = id
				scene.front_end._render_collections()
				await frames(5)
				var matches := scene.front_end.find_children("*", "Button", true, false).filter(func(button: Button): return button.text == ZodiacCatalog.words("ABOUT THIS ZODIAC", "VỀ CON GIÁP NÀY"))
				check(matches.size() == 1, "one portrait button for " + id)
				if matches.size() != 1: continue
				var button: Button = matches[0]
				# The collection page scrolls on narrow screens; bring the new action into view.
				var parent: Node = button.get_parent()
				while parent != null:
					if parent is ScrollContainer: parent.ensure_control_visible(button)
					parent = parent.get_parent()
				await frames(3)
				check(button.is_visible_in_tree(), "portrait action visible " + id)
				await click(button)
				var book := root.get_node_or_null("GameGlossary") as GameGlossary
				check(book != null, "pointer opens portrait " + id + " " + locale)
				if book == null: continue
				await frames(3)
				check(book._entries[0].body.begins_with(ZodiacCatalog.portrait_text(id)), "correct localized portrait " + id)
				check(book._entries[0].title == ZodiacCatalog.display_name(id), "correct localized heading " + id)
				check(book._entries.filter(func(entry: Dictionary): return entry.section == "zodiac" and entry.title == ZodiacCatalog.display_name(id)).size() == 1, "one Handbook entry per Zodiac " + id)
				if id == "dragon":
					check(book._entries[0].body.contains(ZodiacCatalog.words("This encounter is not available yet.", "Hiện chưa thể gặp Con Giáp này.")), "dormant Dragon stays explicit")
				var view := Rect2(Vector2.ZERO, Vector2(root.size))
				var reading_rect: Rect2 = root.get_final_transform() * book._body.get_global_transform_with_canvas() * Rect2(Vector2.ZERO, book._body.size)
				check(view.grow(1).encloses(reading_rect), "portrait reading area fits " + id + " " + str(viewport) + " " + str(reading_rect))
				if id == "rat":
					await capture("rat-portrait-%s-%d" % [locale, viewport.x])
				book.queue_free()
				await frames()
			GameGlossary.open(scene, "zodiac")
			var book := root.get_node("GameGlossary") as GameGlossary
			await frames()
			book._search.text = ZodiacCatalog.display_name("goat")
			book._refresh()
			check(book._body.get_parsed_text().contains(ZodiacCatalog.portrait_text("goat")), "Handbook search finds localized portrait")
			book.queue_free()
			await frames()
	for failure in failures: print("TEXT_EDITORIAL_FAIL " + failure)
	print("TEXT_EDITORIAL_SMOKE checks=%d failures=%d" % [checks, failures.size()])
	scene.music.controller._stop_all_mix_players()
	scene.music.controller.music_director.stop()
	scene.queue_free()
	await frames()
	quit(0 if failures.is_empty() else 1)
