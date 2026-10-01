extends SceneTree

var failures: Array[String] = []
var checks := 0

func _initialize() -> void:
	call_deferred("_run")

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures.append(message)
		push_error(message)

func settle() -> void:
	for frame in 5: await process_frame

func _run() -> void:
	var scene: MatchUI = load("res://scenes/match.tscn").instantiate()
	root.add_child(scene)
	current_scene = scene
	await settle()
	scene.run_save = RunSave.new("user://ui-polish-%d.save" % Time.get_ticks_usec())
	var original_locale: String = scene.settings.locale_code
	var original_wallet := scene.deal.wallet.balance_vnd
	var front := scene.front_end
	for locale in ["en", "vi"]:
		scene.settings.set_locale(locale)
		await settle()
		for extent in [Vector2i(1280, 720), Vector2i(960, 540), Vector2i(1920, 1080)]:
			root.size = extent
			await settle()
			front.show_home()
			await settle()
			var logo: Control = front.get_node("SafeArea/Frame/Header/Logo")
			check(front.get_global_rect().encloses(logo.get_global_rect()), "%s %s title fits" % [locale, extent])
			for button: Button in front.home_body.find_children("*", "Button", true, false):
				check(button.get_global_rect().size.y >= 44, "%s home target height" % locale)
				check(front.get_global_rect().encloses(button.get_global_rect()), "%s home button fits" % locale)
			front.show_setup()
			front.customizing = true
			front._render_setup()
			await settle()
			var start: Button = front.footer.get_child(front.footer.get_child_count() - 1)
			check(front.get_global_rect().encloses(start.get_global_rect()), "%s %s start remains accessible" % [locale, extent])
			check(front.get_node("SafeArea/Frame/Main").get_global_rect().end.y <= front.footer.get_global_rect().position.y, "setup scroll cannot overlap actions")
			front._show_page("settings")
			await settle()
			for label: Label in front.settings_page.find_children("*", "Label", true, false):
				if label.text.ends_with("%"):
					check(label.size.x >= label.get_minimum_size().x, "%s volume fits one line" % locale)
			front.show_collections()
			await settle()
			var list := front.collection_body.find_child("CollectionListScroll", true, false) as ScrollContainer
			check(list != null and list.size.y > 0, "collection has its own usable scroll area")
			list.scroll_vertical = 9999
			await settle()
			check(list.scroll_vertical > 0, "last collection items remain reachable")
			var items := list.get_child(0)
			var last := items.get_child(items.get_child_count() - 1) as Button
			last.pressed.emit()
			await settle()
			var selected := front.collection_body.find_child("Collection_" + front.selected_collection, true, false) as Button
			var rebuilt_list := front.collection_body.find_child("CollectionListScroll", true, false) as ScrollContainer
			check(selected.has_focus(), "collection selection retains keyboard focus")
			check(rebuilt_list.get_global_rect().encloses(selected.get_global_rect()), "selected collection item stays visible")
			for card_count in [52, 13]:
				var cards := scene.deal.deck.draw_pile.slice(0, card_count)
				scene.deck_screen.open_deck(cards, "DECK", "")
				await settle()
				check(scene.deck_screen._grid.get_minimum_size().x <= scene.deck_screen._scroll.size.x, "%s %s deck columns fit" % [locale, extent])
				check(not scene.deck_screen._purpose.visible, "deck browsing has no subtitle row")
				scene.deck_screen.close()
	check(scene.deal.wallet.balance_vnd == original_wallet, "navigation leaves the wallet unchanged")
	scene.settings.set_locale(original_locale)
	scene.music_controller._stop_all_mix_players()
	scene.music_controller.music_director.stop()
	scene.queue_free()
	await process_frame
	print("UI_POLISH_LAYOUT_SMOKE checks=%d failed=%d" % [checks, failures.size()])
	quit(0 if failures.is_empty() else 1)
