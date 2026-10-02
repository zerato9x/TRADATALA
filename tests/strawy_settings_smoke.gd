extends SceneTree
var failures: Array[String] = []
var checks := 0

func _initialize() -> void:
	call_deferred("_run")

func check(ok: bool, text: String) -> void:
	checks += 1
	if not ok: failures.append(text); push_error(text)

func capture(label: String) -> void:
	if DisplayServer.get_name() == "headless": return
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://.godot/%s-%s%s.png" % [label,"vi" if "--vi" in OS.get_cmdline_user_args() else "en","-large" if "--large" in OS.get_cmdline_user_args() else ""])

func tap_choice(ui: MatchUI, name: String) -> void:
	await process_frame
	await process_frame
	var button: Button = ui.strawy.box.find_child(name,true,false)
	var point := button.get_global_transform_with_canvas() * (button.size * 0.5)
	for down in [true,false]:
		var touch := InputEventScreenTouch.new()
		touch.position = point
		touch.pressed = down
		root.push_input(touch,true)
	for down in [true,false]:
		var mouse := InputEventMouseButton.new()
		mouse.device = -1
		mouse.position = point
		mouse.button_index = MOUSE_BUTTON_LEFT
		mouse.pressed = down
		root.push_input(mouse,true)

func check_helper_preference(ui: MatchUI) -> void:
	ui._restoring_run = false
	ui.interaction_locked = false
	ui.strawy.window_focused = true
	var before := var_to_str(ui.deal.snapshot_state())
	ui.strawy._prepare_discard()
	check(not ui.strawy.quick_action.is_empty(),"fixture has a pending discard preview")
	ui.front_end._render_settings()
	var toggle: CheckButton = ui.front_end.find_child("ShowStrawy",true,false)
	check(toggle != null and toggle.button_pressed,"Settings exposes the enabled-by-default helper")
	toggle.button_pressed = false
	check(not ui.settings.strawy_enabled and not ui.strawy.surface.visible and ui.strawy.quick_action.is_empty(),"Settings disables the helper immediately and cancels its preview")
	ui.strawy.open_help()
	ui.strawy._command("discard")
	check(not ui.strawy.box.visible and not ui.strawy.can_play_cards() and var_to_str(ui.deal.snapshot_state()) == before,"disabled helper cannot open help or commit a card action")
	toggle.button_pressed = true
	ui.strawy.open_help()
	toggle.button_pressed = false
	check(not ui.strawy.box.visible and not ui.strawy.blocker.visible,"disabling Strawy releases his open menu and input blocker")
	toggle.button_pressed = true
	ui.strawy.start_tour()
	toggle.button_pressed = false
	check(ui.strawy.tour.is_empty() and not ui.strawy.surface.visible,"disabling Strawy stops an active tour")
	toggle.button_pressed = true
	check(ui.strawy.surface.visible and ui.settings.strawy_choice_made,"the player can restore Strawy immediately")
	ui.settings.set_tutorial_enabled(true)
	ui.campaign.day_finished.emit(ui.campaign.current_day())
	await process_frame
	check(ui.settings.tutorial_completed and not ui.strawy.choice_open,"an explicit Settings choice prevents a redundant post-tutorial question")
	# Model a player who has not chosen a helper preference yet.
	ui.settings.strawy_choice_made = false
	ui.settings.tutorial_completed = false
	GameGlossary.open(ui,"campaign")
	ui.campaign.day_finished.emit(ui.campaign.current_day())
	await process_frame
	check(ui.settings.tutorial_completed and not ui.strawy.choice_open,"completion waits for an obstructing Handbook to close")
	root.get_node("GameGlossary").queue_free()
	await process_frame
	await process_frame
	check(ui.strawy.choice_open and ui.strawy.actions.get_child_count() == 3,"tutorial completion offers exactly Keep Strawy and Turn off")
	before = var_to_str(ui.deal.snapshot_state())
	ui.strawy._command("discard")
	check(var_to_str(ui.deal.snapshot_state()) == before and ui.strawy.choice_open,"post-tutorial choice cannot play cards underneath")
	await capture("strawy-choice")
	await tap_choice(ui,"StrawyKeep")
	await process_frame
	check(ui.settings.strawy_enabled and ui.settings.strawy_choice_made and not ui.strawy.choice_open,"native Keep choice persists once despite emulated mouse")
	ui.campaign.day_finished.emit(ui.campaign.current_day())
	await process_frame
	check(not ui.strawy.choice_open,"tutorial completion never asks again after a choice")
	ui.settings.strawy_choice_made = false
	await process_frame
	await process_frame
	var tab := InputEventKey.new()
	tab.keycode = KEY_TAB
	tab.pressed = true
	root.push_input(tab,true)
	check(root.gui_get_focus_owner() == ui.strawy.box.find_child("StrawyTurnOff",true,false),"keyboard focus stays within the two tutorial choices")
	for down in [true,false]:
		var enter := InputEventKey.new()
		enter.keycode = KEY_ENTER
		enter.pressed = down
		root.push_input(enter,true)
	check(not ui.settings.strawy_enabled and not ui.strawy.choice_open,"Enter confirms the focused Turn off choice")
	ui.settings.set_strawy_enabled(true)
	ui.settings.strawy_choice_made = false
	await process_frame
	await process_frame
	await tap_choice(ui,"StrawyTurnOff")
	await process_frame
	check(not ui.settings.strawy_enabled and ui.settings.strawy_choice_made and not ui.strawy.surface.visible and not ui.strawy.blocker.visible,"native Turn off choice hides Strawy and releases input once")
	check(var_to_str(ui.deal.snapshot_state()) == before,"both helper choices preserve the real hand, wallet, and RNG")
	await capture("strawy-disabled")
	ui.menu_layer.show()
	ui.front_end._render_settings()
	ui.front_end._show_page("settings")
	await process_frame
	await process_frame
	check(not (ui.front_end.find_child("ShowStrawy",true,false) as CheckButton).button_pressed,"Settings reflects the post-tutorial Turn off choice")
	await capture("settings-strawy")
	ui.menu_layer.hide()
	# Older settings have no helper key. They retain the enabled default.
	var legacy := ConfigFile.new()
	legacy.set_value("help","tutorial",false)
	legacy.set_value("help","first_seed",true)
	legacy.save(ui.settings.SETTINGS_PATH)
	ui.settings._load_preferences()
	check(ui.settings.strawy_enabled and not ui.settings.strawy_choice_made and not ui.settings.tutorial_completed,"legacy settings default to visible Strawy and an unanswered choice")
	ui.settings.set_strawy_enabled(false)
	ui.settings.mark_tutorial_completed()

func _run() -> void:
	root.size = Vector2i(1920,1080) if "--large" in OS.get_cmdline_user_args() else Vector2i(1280,720)
	var ui: MatchUI = load("res://scenes/match.tscn").instantiate()
	root.add_child(ui)
	current_scene = ui
	await create_timer(0.3).timeout
	ui.settings.set_music_system("playing_tracks")
	if "--resume-only" not in OS.get_cmdline_user_args(): ui.settings.set_locale("vi" if "--vi" in OS.get_cmdline_user_args() else "en")
	ui.run_save = RunSave.new("user://strawy-settings.save")
	ui.drink_manager.progress.save_path = ""
	ui._restoring_run = true
	if "--resume-only" in OS.get_cmdline_user_args():
		check(not ui.settings.tutorial_enabled and ui.settings.first_seed_enabled, "settings loaded in fresh process")
		check(not ui.settings.strawy_enabled and ui.settings.strawy_choice_made and ui.settings.tutorial_completed,"helper preference and answered tutorial question survive a fresh process")
		var saved := ui.run_save.load_run()
		check(not saved.is_empty() and ui._resume_saved_run(saved), "saved run resumes in fresh process")
		await create_timer(0.8).timeout
		check(not ui.campaign.onboarding.first_seed_enabled, "resume retains run's policy despite changed preference")
		check(not ui.strawy.actor.is_visible_in_tree() and not ui.strawy.choice_open,"resume keeps the helper disabled and does not ask again")
	else:
		var title := ui.get_node_or_null("TitleScreen")
		if title: title.queue_free()
		ui.game_started = true
		ui.game_layer.position = Vector2.ZERO
		ui.menu_layer.hide()
		for tutorial in [true,false]:
			for first_seed in [true,false]:
				ui.settings.set_tutorial_enabled(tutorial)
				ui.settings.set_first_seed_enabled(first_seed)
				ui.settings.tutorial_enabled = not tutorial
				ui.settings.first_seed_enabled = not first_seed
				ui.settings._load_preferences()
				check(ui.settings.tutorial_enabled == tutorial and ui.settings.first_seed_enabled == first_seed, "preferences persist independently")
				ui.run_seed_input = "STRAWY-MATRIX"
				ui._start_campaign()
				ui.campaign._enter_phase(CampaignManager.CampaignPhase.MORNING_DEAL)
				await create_timer(0.8).timeout
				check(ui.campaign.onboarding.first_seed_enabled == first_seed, "new run captures First Seed policy")
				var expected := DealState.new()
				expected.set_campaign_deck(ui.campaign.gieo_que.persistent_deck)
				var opening: Array[String] = []
				if first_seed: opening.assign(ui.campaign.onboarding.opening_ids("morning",ui.campaign.gieo_que.persistent_deck))
				expected.start_deal(CampaignOnboarding.SEED if first_seed else ui.campaign.seed_for("deal",0),false,opening)
				check(ui.deal.hand.map(func(c): return c.unique_id) == expected.hand.map(func(c): return c.unique_id), "correct curated or run-seeded hand")
				check(not ui.strawy.box.visible and not ui.campaign_coach.box.visible, "tutorial has no unrequested speech")
				if tutorial:
					var hint: Array[String] = ui.campaign_coach._hint()
					check(ui.strawy._context_copy() == GameGlossary.words(hint[1],hint[2]), "requested tutorial includes what to do with the real hand")
		await check_helper_preference(ui)
		ui.settings.set_tutorial_enabled(false)
		ui.settings.set_first_seed_enabled(true)
		check(not ui.campaign.onboarding.first_seed_enabled, "changing preference does not change current run")
		check(ui.run_save.save_run(ui.campaign,ui.deal), "save run policy for fresh-process read")
	print("STRAWY_SETTINGS_SMOKE checks=%d failures=%d" % [checks,failures.size()])
	ui.queue_free()
	await create_timer(0.4).timeout
	quit(0 if failures.is_empty() else 1)
