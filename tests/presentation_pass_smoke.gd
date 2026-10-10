extends "res://tests/boss_presentation_smoke.gd"
## Rendered navigation and real game input under the new presentation layers.

func _run() -> void:
	rendered = DisplayServer.get_name() != "headless"
	capture_dir = "res://docs/screenshots/presentation-2026-10-10"
	root.size = Vector2i(1280, 720)
	scene = load("res://scenes/match.tscn").instantiate() as MatchUI
	root.add_child(scene)
	current_scene = scene
	await frames()
	scene.session.restoring = true
	scene.session.run_save = RunSave.new("user://presentation-pass.save")
	scene.drink_manager.progress.save_path = ""
	scene.campaign.zodiac.progress = ZodiacProgress.new("")
	scene.campaign.run_seed = "presentation-pass"
	scene.campaign.current_day_index = 0
	scene.campaign.difficulty_progress.unlocked = 2
	scene.campaign.select_difficulty(2)
	var front := scene.front_end
	var initial_background: Texture2D = scene.get_node("SidewalkTableBackground").texture
	for locale in ["en", "vi"]:
		scene.settings.set_locale(locale)
		for extent in [Vector2i(1280, 720), Vector2i(960, 620), Vector2i(1920, 1080)]:
			root.size = extent
			await frames(5)
			var label := "%s-%dx%d" % [locale, extent.x, extent.y]
			scene.game_started = false
			scene.menu_layer.show()
			front.show_home()
			await create_timer(0.5).timeout
			var before_wallet := scene.deal.wallet.balance_vnd
			var before_hand := scene.deal.hand.duplicate()
			var tableau: Control = front.get_node("MenuTableau")
			check(tableau.is_visible_in_tree() and tableau.mouse_filter == Control.MOUSE_FILTER_IGNORE, label + " home still life passes input")
			check(scene.get_node("TableAmbience").mouse_filter == Control.MOUSE_FILTER_IGNORE, label + " table light passes input")
			for button: Button in front.home_body.find_children("*", "Button", true, false):
				check(front.get_global_rect().encloses(button.get_global_rect()), label + " home button fits: " + button.name)
				check(button.size.y >= 44, label + " home touch target: " + button.name)
				check(button.get_node("EnamelEdges").mouse_filter == Control.MOUSE_FILTER_IGNORE, label + " animated edge passes input")
			await capture(label + "-home")
			await click(front.home_body.get_node("NewRun"))
			await create_timer(0.3).timeout
			check(front.page == "setup" and not tableau.visible, label + " pointer opens setup without decorative occlusion")
			var start: Button = front.footer.get_child(front.footer.get_child_count() - 1)
			check(front.get_global_rect().encloses(start.get_global_rect()), label + " start remains on screen")
			var paper_count := 0
			for copy: Label in front.setup_body.find_children("*", "Label", true, false):
				if copy.get_meta("text_surface", "") == &"paper":
					paper_count += 1
					var rich := copy.get_node_or_null("SemanticCaption") as RichTextLabel
					var ink := rich.get_theme_color("default_color") if rich != null and rich.visible else copy.get_theme_color("font_color")
					check(ink.r < 0.7 and ink.a > 0.0, label + " debt slip uses dark ink")
			check(paper_count >= 15, label + " full week is printed on paper")
			await capture(label + "-setup")
			front.show_music()
			front.show_settings()
			front.show_home()
			await create_timer(0.3).timeout
			check(front.active_page == "home" and is_equal_approx(front.pages.home.modulate.a, 1.0), label + " rapid navigation ends fully visible")
			check(scene.deal.wallet.balance_vnd == before_wallet and scene.deal.hand == before_hand, label + " menu presentation does not mutate the deal")
			scene.game_started = true
			scene.menu_layer.hide()
			scene.game_layer.position = Vector2.ZERO
			scene.game_layer.show()
			scene.event_table.table_state = EventTableController.TABLE_STATE_DEAL
			scene.event_table._finish_event_exit()
			await fixture("rooster", 1)
			scene.deal.set_current_drink(DrinkCatalog.TRA_DA)
			scene._sync_all()
			await create_timer(0.5).timeout
			check(not tableau.is_processing(), label + " hidden menu animation stops")
			var dock := scene.get_node("GameLayer/ActionDock") as Control
			check(scene.drink_table_button.get_global_rect().end.y <= dock.global_position.y, label + " event return keeps drink above the action dock after resize")
			check(is_equal_approx(dock.offset_top, -66.0) and is_equal_approx(dock.offset_bottom, -8.0), label + " event return preserves bottom anchors")
			await click(scene.hint_button)
			check(not scene.interactions.selected_ids.is_empty(), label + " physical hint click still selects cards")
			check(not scene.ha_button.disabled, label + " valid meld becomes actionable")
			await capture(label + "-table")
			var meld_count := scene.deal.melds.size()
			await click(scene.ha_button)
			await frames(8)
			check(scene.deal.melds.size() > meld_count, label + " physical meld click commits the action")
			scene.money_playback.request_fast_forward()
			var wait_frames := 0
			while scene.money_playback.running and wait_frames < 600:
				await process_frame
				wait_frames += 1
			check(not scene.money_playback.running, label + " committed payout presentation completes")
			check(scene.get_node("SidewalkTableBackground").texture == initial_background, label + " original table art retained")
	for message in failures: print(message)
	print("PRESENTATION_PASS_SMOKE checks=%d failures=%d" % [checks, failures.size()])
	scene.music.controller._stop_all_mix_players()
	scene.music.controller.music_director.stop()
	scene.queue_free()
	await create_timer(0.3).timeout
	quit(0 if failures.is_empty() else 1)
