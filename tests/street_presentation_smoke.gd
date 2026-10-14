extends "res://tests/front_end_forms_smoke.gd"
## Real table renders plus phase interruption and receipt layout/input coverage.

func capture(label: String) -> void:
	if not rendered: return
	await RenderingServer.frame_post_draw
	DirAccess.make_dir_recursive_absolute(capture_dir)
	root.get_texture().get_image().save_png(capture_dir + "/" + label + ".png")

func receipt_layout(label: String) -> void:
	var receipt = scene.resolve_receipt
	var sheet: Rect2 = receipt._paper.get_global_rect()
	check(scene.get_global_rect().encloses(sheet), label + " paper fits canvas")
	check(sheet.encloses(receipt.primary.get_global_rect()), label + " primary action fits paper")
	check(receipt._scroll.size.y > 180, label + " readable scrolling detail space")
	check(not sheet.intersects(scene.campaign_money_hud.panel.get_global_rect()), label + " wallet does not cover receipt")
	check(sheet.encloses(receipt.title_label.get_global_rect()), label + " title fits paper")
	for panel: Control in receipt._summary.get_children():
		check(sheet.encloses(panel.get_global_rect()), label + " money summary fits paper")
		var amount := panel.get_child(0).get_child(1) as Label
		check(amount.get_theme_font("font").get_string_size(amount.text, HORIZONTAL_ALIGNMENT_LEFT, -1, amount.get_theme_font_size("font_size")).x <= amount.size.x, label + " complete amount is visible")
	check(receipt._shade.color.a < 0.65, label + " street remains visible")
	check(receipt.net_label.text == VndWallet.format_vnd(int(receipt._report.net_vnd), true), label + " final net remains exact")
	check(receipt._paper.scale.is_equal_approx(Vector2.ONE), label + " paper settles at exact size")

func _run() -> void:
	rendered = DisplayServer.get_name() != "headless"
	capture_dir = "res://.godot/validation/street-2026-10-13/screens"
	root.size = Vector2i(1280, 720)
	scene = load("res://scenes/match.tscn").instantiate() as MatchUI
	root.add_child(scene)
	current_scene = scene
	await frames(5)
	await scene._on_play_pressed()
	scene.campaign.event_manager.complete_interaction("choose_drink")
	scene.campaign.complete_current_event()
	scene.deal.start_tutorial_deal()
	scene._sync_all()
	await create_timer(1.3).timeout
	var light = scene.get_node("TableAmbience")
	var home_light = scene.front_end.find_child("TableAmbience", true, false)
	check(light.material != home_light.material, "home and table own separate lighting materials")
	check(light.mouse_filter == Control.MOUSE_FILTER_IGNORE, "lighting passes input")
	var before_hand := scene.deal.hand.duplicate()
	var before_wallet := scene.deal.wallet.balance_vnd
	var before_rng := scene.deal.deck._rng.state
	var phases := [CampaignManager.CampaignPhase.MORNING_DEAL, CampaignManager.CampaignPhase.NOON_DEAL, CampaignManager.CampaignPhase.AFTERNOON_DEAL, CampaignManager.CampaignPhase.EVENING_DEAL]
	for period in phases.size():
		scene.campaign.current_phase = phases[period]
		scene.campaign.campaign_phase_changed.emit(phases[period])
		scene._refresh_stats()
		await create_timer(1.3).timeout
		check(is_equal_approx(light.material.get_shader_parameter("time_of_day"), float(period)), "campaign phase lights the street " + str(period))
		await capture(["morning", "noon", "afternoon", "evening"][period])
	check(scene.campaign_period_value.size.x >= scene.campaign_period_value.get_theme_font("font").get_string_size("AFTERNOON", HORIZONTAL_ALIGNMENT_LEFT, -1, scene.campaign_period_value.get_theme_font_size("font_size")).x, "long afternoon period fits without ellipsis")
	# A replaced/restored run must finish at the newest phase, even mid-transition.
	light.sync_phase(CampaignManager.CampaignPhase.MORNING_DEAL)
	await create_timer(0.12).timeout
	light.sync_phase(CampaignManager.CampaignPhase.AFTERNOON_DEAL)
	await create_timer(0.12).timeout
	light.sync_phase(CampaignManager.CampaignPhase.EVENING_DEAL)
	await create_timer(1.3).timeout
	check(is_equal_approx(light.material.get_shader_parameter("time_of_day"), 3.0), "rapid replacement cancels obsolete lighting tween")
	check(is_zero_approx(home_light.material.get_shader_parameter("time_of_day")), "gameplay never changes home lighting")
	check(scene.deal.hand == before_hand and scene.deal.wallet.balance_vnd == before_wallet and scene.deal.deck._rng.state == before_rng, "ambient transitions preserve cards wallet and RNG")
	# Build receipts from committed accounting; the receipt never pays during browsing.
	scene.deal.wallet.apply_vnd(1_500_000, "new_meld")
	scene.deal.wallet.apply_vnd(-110_000, "deadwood")
	var report := scene.deal.accounting_report()
	report["due_vnd"] = 250_000
	report["shortfall_vnd"] = 0
	report["paid"] = false
	scene._on_collection_requested(report)
	before_wallet = scene.deal.wallet.balance_vnd
	for locale in ["en", "vi"]:
		scene.settings.set_locale(locale)
		for extent in [Vector2i(1280, 720), Vector2i(960, 540), Vector2i(1920, 1080)]:
			root.size = extent
			await frames(5)
			var label := "%s-%dx%d" % [locale, extent.x, extent.y]
			scene._on_collection_requested(report)
			await create_timer(1.3).timeout
			await capture(label + "-collection")
			receipt_layout(label + " collection")
			check(scene.resolve_receipt._brand.text.ends_with("SỔ THU CHI" if locale == "vi" else "THE TABLE'S ACCOUNTS"), label + " masthead follows current language")
			check(not scene.resolve_receipt._paper.get_global_rect().intersects(scene.resolve_receipt.portrait.get_global_rect()), label + " collector clears paper: " + str(scene.resolve_receipt._paper.get_global_rect()) + " / " + str(scene.resolve_receipt.portrait.get_global_rect()))
			scene._show_campaign_outcome(true)
			await create_timer(0.75).timeout
			receipt_layout(label + " outcome")
			await capture(label + "-outcome")
			await click(scene.resolve_receipt._tabs.get_node("ledger"))
			check(scene.resolve_receipt._page == "ledger", label + " pointer opens actual ledger tab")
			check(scene.deal.wallet.balance_vnd == before_wallet, label + " browsing receipts cannot pay")
	root.size = Vector2i(1280, 720)
	await frames(5)
	var shortfall := report.duplicate(true)
	shortfall["due_vnd"] = 2_000_000
	shortfall["shortfall_vnd"] = 2_000_000 - int(report.closing_vnd)
	scene._on_collection_requested(shortfall)
	await create_timer(1.3).timeout
	receipt_layout("shortfall")
	await capture("shortfall")
	scene.resolve_receipt.suspend_presentation()
	check(scene.resolve_receipt._paper.scale == Vector2.ONE, "suspension clears entrance transform")
	scene.resolve_receipt.resume_presentation()
	scene.resolve_receipt.hide()
	check(scene.resolve_receipt._report.is_empty(), "hidden paper releases report")
	print("STREET_PRESENTATION_SMOKE: %d checks, %d failures" % [checks, failures.size()])
	scene.queue_free()
	await frames()
	quit(0 if failures.is_empty() else 1)
