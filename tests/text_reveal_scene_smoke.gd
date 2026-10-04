extends SceneTree
var checks := 0
var failures: Array[String] = []
var scene: MatchUI

func _initialize() -> void: call_deferred("_run")
func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok: failures.append(message); push_error(message)
func frames(count: int = 3) -> void:
	for _i in count: await process_frame
func capture(label: String) -> void:
	if DisplayServer.get_name() == "headless": return
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://.godot/typewriter-%s.png" % label)

func _run() -> void:
	root.size = Vector2i(1280, 720)
	scene = load("res://scenes/match.tscn").instantiate() as MatchUI
	root.add_child(scene)
	current_scene = scene
	await frames()
	var fixture := VBoxContainer.new()
	root.add_child(fixture)
	fixture.position = Vector2(20, 200)
	var label := Label.new()
	label.text = "A complete paragraph keeps the same layout while letters appear."
	fixture.add_child(label)
	var rich := RichTextLabel.new()
	rich.set_meta("conversation_text", true)
	rich.bbcode_enabled = true
	rich.fit_content = true
	rich.text = "[color=gold]Xin chào[/color] · [b]250.000 VNĐ[/b]"
	fixture.add_child(rich)
	var button := Button.new()
	button.text = "Continue to the next conversation"
	fixture.add_child(button)
	await frames()
	var bounds := fixture.size
	check(label.visible_characters == -1, "ordinary labels remain immediate")
	check(rich.visible_characters >= 0 and rich.visible_characters < rich.get_total_character_count(), "conversational rich text types parsed characters")
	check(not button.has_node("TypewriterCaption"), "button captions remain native and immediate")
	for copy in [scene.zodiac_table.dialogue, scene.zodiac_table.contract_label, scene.zodiac_table.status, scene.zodiac_table.mechanics]:
		check(copy.has_meta("conversation_text"), "Zodiac conversation paragraphs opt into reveal")
	check(not scene.zodiac_boss_hud.title.has_meta("conversation_text") and not scene.wallet_value.has_meta("conversation_text"), "boss badge and wallet stay immediate")
	await create_timer(0.2).timeout
	check(fixture.size == bounds and button.text == "Continue to the next conversation", "full text layout and button contracts remain stable")
	var input := InputEventKey.new()
	input.keycode = KEY_ENTER
	input.pressed = true
	root.push_input(input, true)
	check(label.visible_characters == -1 and rich.visible_characters == -1, "confirm finishes visible labels")
	check(not button.has_node("TypewriterCaption") and button.get_theme_color("font_color").a > 0, "dialogue skip does not modify buttons")
	fixture.hide()
	await frames()
	fixture.show()
	await frames()
	check(rich.visible_characters >= 0 and label.visible_characters == -1, "reopening replays only conversational text")
	rich.text = "A replacement paragraph that must reveal instead of inherit completed text."
	await frames()
	check(rich.visible_characters < rich.get_total_character_count(), "replacement conversation reveals")
	button.text = "A freshly replaced caption"
	await frames()
	button.add_theme_color_override("font_color", Color.RED)
	await frames()
	button.text = ""
	await frames()
	check(not button.has_node("TypewriterCaption") and button.get_theme_color("font_color") == Color.RED, "button restyling is untouched")
	label.text = "100000"
	for index in 30:
		label.text = str(100000 + index)
		await process_frame
	check(label.visible_characters == -1, "money updates remain immediate")
	fixture.queue_free()
	var npc: NpcConversation = load("res://scenes/ui/npc_conversation.tscn").instantiate()
	root.add_child(npc)
	npc.say("Trà Đá", "Xin chào. Một ly trà đá giá 2.000 VNĐ. Ngồi xuống rồi hãy chọn nước.")
	check(npc.speech.visible_characters == 0, "NPC starts at zero")
	await create_timer(0.15).timeout
	check(npc.speech.visible_characters > 0 and npc.speech.visible_characters < npc.speech.get_total_character_count(), "NPC speech advances gradually")
	var progress := npc.speech.visible_characters
	npc.say("Trà Đá", "Xin chào. Một ly trà đá giá 2.000 VNĐ. Ngồi xuống rồi hãy chọn nước.")
	check(npc.speech.visible_characters == progress, "identical NPC refresh does not restart")
	npc.say("Trà Đá", "Another sentence replaces the old one without a stale tween completing it.")
	check(npc.speech.visible_characters == 0, "replacement cancels old reveal")
	TextReveal.finish(npc.speech)
	await create_timer(0.15).timeout
	check(npc.speech.visible_characters == -1, "finishing cancels the tween permanently")
	npc.queue_free()
	scene.get_node("TitleScreen").queue_free()
	scene._restoring_run = true
	scene.run_save = RunSave.new("user://typewriter-fixture.save")
	scene.drink_manager.progress.save_path = ""
	scene.campaign.zodiac.progress = ZodiacProgress.new("")
	scene.game_started = true
	scene.game_layer.position = Vector2.ZERO
	scene.game_layer.show()
	scene.menu_layer.hide()
	scene.event_table.table_state = EventTableController.TABLE_STATE_DEAL
	scene.event_table._finish_event_exit()
	scene.current_campaign_event = null
	scene.campaign.current_phase = CampaignManager.CampaignPhase.EVENING_DEAL
	scene.deal.start_tutorial_deal()
	scene.deal.zodiac_boss.configure("cat", 2, 14281)
	scene.deal.zodiac_boss.begin_phase(scene.deal)
	scene.modal_overlay.hide()
	scene.score_overlay.hide()
	scene._sync_all()
	await frames()
	var hud = scene.zodiac_boss_hud
	var before := var_to_str(scene.deal.snapshot_state())
	for locale in ["en", "vi"]:
		scene.settings.set_locale(locale)
		for extent in [Vector2i(1280, 720), Vector2i(960, 620), Vector2i(1920, 1080)]:
			root.size = extent
			await frames(5)
			hud._start_speech({"key": str(extent) + locale, "line": ZodiacCatalog.words("These two cards stay with me until the next turn. Choose your discard carefully.", "Hai lá này ở với ta tới lượt kế. Chọn lá bỏ cho cẩn thận.")})
			check(hud.feedback.visible_characters == 0 and hud.feedback_panel.scale.x < 1, "boss pops before text " + locale)
			await create_timer(0.12).timeout
			check(hud.feedback.visible_characters == 0, "pop precedes typing " + locale)
			await create_timer(0.25).timeout
			check(hud.feedback.visible_characters > 0 and hud.feedback.visible_characters < hud.feedback.get_total_character_count(), "boss speech types " + locale)
			await capture("boss-partial-%s-%d" % [locale, extent.x])
			check(not hud.has_node("EveningBossPortrait"), "corner sprite removed")
			check(hud.feedback_panel.position.y >= scene.campaign_money_hud.panel.get_global_rect().end.y, "speech below wallet")
			var screen_rect: Rect2 = root.get_final_transform() * hud.feedback_panel.get_global_transform_with_canvas() * Rect2(Vector2.ZERO, hud.feedback_panel.size)
			check(Rect2(Vector2.ZERO, Vector2(extent)).encloses(screen_rect), "speech within viewport %s: speech=%s" % [extent, screen_rect])
			for surface in [scene.hand_layer, scene.meld_scroll, scene.draw_pile_visual, scene.discard_pile_visual]:
				check(not hud.feedback_panel.get_global_rect().intersects(surface.get_global_rect()), "speech clears %s %s: speech=%s surface=%s" % [surface.name, extent, hud.feedback_panel.get_global_rect(), surface.get_global_rect()])
			await create_timer(1.1).timeout
			check(hud.feedback.visible_characters == -1 and hud.feedback_panel.visible, "complete line remains readable")
			await capture("boss-complete-%s-%d" % [locale, extent.x])
	check(var_to_str(scene.deal.snapshot_state()) == before, "presentation preserves committed gameplay")
	scene.menu_layer.show()
	await frames()
	check(scene.meld_scroll.offset_right == hud._meld_right_offset, "normal Meld width returns when boss HUD hides")
	scene.queue_free()
	await frames()
	print("TEXT_REVEAL_SCENE_SMOKE checks=%d failures=%d" % [checks, failures.size()])
	quit(0 if failures.is_empty() else 1)
