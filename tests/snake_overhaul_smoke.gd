extends "res://tests/roster_presentation_smoke.gd"
const Tactics := preload("res://scripts/zodiac/zodiac_tactics.gd")

func fixture(id: String, level: int, phase: int = 1) -> void:
	scene.zodiac_boss_hud.snake_fx.sync({}, "")
	await super.fixture(id, level, phase)
	scene.banner_panel.hide()

func ready_to_play() -> void:
	var deadline := Time.get_ticks_msec() + 12000
	while (scene.money_playback.running or scene.interactions.locked) and Time.get_ticks_msec() < deadline:
		scene.money_presentation.request_fast_forward()
		await frames()
	check(not scene.interactions.locked, "committed charm returns control to the player")

func current_command() -> Dictionary:
	for command: Dictionary in scene.deal.zodiac_boss.data.commands:
		if command.status == "pending": return command
	return {}

func face_ink_contract(face: TextureRect, charmed: bool, label: String) -> void:
	if not rendered: return
	await RenderingServer.frame_post_draw
	var screenshot := root.get_texture().get_image()
	var paper := face.texture.get_image()
	if paper.is_compressed(): paper.decompress()
	var to_image := root.get_final_transform() * face.get_global_transform_with_canvas()
	var samples := 0
	var green := 0
	for x in range(3, 8):
		for y in range(3, 8):
			var uv := Vector2(x, y) * 0.1
			var original := paper.get_pixelv(Vector2i(uv * Vector2(paper.get_size())))
			if minf(original.r, minf(original.g, original.b)) < 0.94: continue
			var pixel := Vector2i(to_image * (face.size * uv))
			if not Rect2i(Vector2i.ZERO, screenshot.get_size()).has_point(pixel): continue
			var color := screenshot.get_pixelv(pixel)
			samples += 1
			if color.g - color.r > 0.08 and color.g - color.b > 0.04: green += 1
	check(samples >= 8, label + " samples the actual visible card paper")
	check(float(green) / maxf(samples, 1) >= 0.7 if charmed else green == 0, label + " visible green ink covers the charmed face only")

func charm_contract(label: String) -> void:
	table_contract(label)
	var hud = scene.zodiac_boss_hud
	check(Rect2(Vector2.ZERO, Vector2(root.size)).encloses(hud.panel.get_global_rect()), label + " boss panel fits the actual Saturday viewport")
	for surface: Control in [scene.draw_pile_visual, scene.discard_pile_visual, scene.hand_layer, scene.meld_scroll]:
		check(not hud.panel.get_global_rect().intersects(surface.get_global_rect()), label + " charm panel clears " + surface.name)
		if hud.feedback_panel.is_visible_in_tree(): check(not hud.feedback_panel.get_global_rect().intersects(surface.get_global_rect()), label + " visible Snake speech clears " + surface.name)
	check(hud.panel.size.y <= 64, label + " one active charm fits a compact body")
	check(hud.mechanic_guide.commands.get_child_count() == 1, label + " only the current charm is shown")
	check(hud.state_label.is_visible_in_tree(), label + " charm progress stays in the shared header")
	for flight in hud.snake_fx.flights:
		check(flight.face.mouse_filter == Control.MOUSE_FILTER_IGNORE, label + " serpent discard ghosts cannot block the next action")

func _run() -> void:
	rendered = DisplayServer.get_name() != "headless"
	capture_dir = "res://.godot/snake-overhaul/screens"
	root.size = Vector2i(1280, 720)
	scene = load("res://scenes/match.tscn").instantiate() as MatchUI
	root.add_child(scene)
	current_scene = scene
	await frames()
	scene.session.restoring = true
	scene.session.run_save = RunSave.new("user://snake-overhaul.save")
	scene.drink_manager.progress.save_path = ""
	scene.campaign.zodiac.progress = ZodiacProgress.new("")
	scene.campaign.run_seed = "snake-overhaul"
	scene.campaign.current_day_index = 5
	scene.campaign.gieo_que.reset_campaign()
	scene.game_started = true
	scene.menu_layer.hide()
	scene.game_layer.position = Vector2.ZERO
	scene.game_layer.show()
	scene.event_table.table_state = EventTableController.TABLE_STATE_DEAL
	scene.event_table._finish_event_exit()
	await create_timer(0.6).timeout
	var hud = scene.zodiac_boss_hud
	var fx = hud.snake_fx
	var command: Dictionary
	for locale in ["en", "vi"]:
		scene.settings.set_locale(locale)
		for level in [1, 2, 3]:
			await fixture("snake", level)
			check(scene.deal.hand.size() == 10 and scene.deal.deck.discard_pile.is_empty(), "Snake reveals her charm without taking cards before input")
			check(scene.deal.zodiac_boss.data.command_limit == level, "difficulty retains its consecutive charm limit")
			command = current_command()
			var cue = scene.card_table.hand_views[command.card_id]._zodiac_cue
			check(cue.visible and cue.surface.material.shader.resource_path.ends_with("snake_command.gdshader"), "the actual charmed card has serpent shader ink")
			check(cue.get_parent() == scene.card_table.hand_views[command.card_id]._texture, "serpent shader follows the actual swaying card face")
			var color: Color = cue.caption.get_node("SemanticCaption").get_theme_color("default_color") if cue.caption.has_node("SemanticCaption") else cue.caption.get_theme_color("font_color")
			check(color.g > color.r, "visible charm caption color is green")
			for extent in [Vector2i(1280, 720), Vector2i(960, 620), Vector2i(1920, 1080)]:
				root.size = extent
				await frames(6)
				charm_contract("Snake %s tier%d %s" % [locale, level, extent])
			root.size = Vector2i(1280, 720)
			await frames(6)
			await face_ink_contract(scene.card_table.hand_views[command.card_id]._texture, true, "charmed hand card")
			var plain: CardData = scene.deal.hand.filter(func(card: CardData): return card.unique_id != command.card_id)[0]
			await face_ink_contract(scene.card_table.hand_views[plain.unique_id]._texture, false, "uncharmed hand card")
			var dragged: CardData = scene.deal.hand.filter(func(card: CardData): return card.unique_id == command.card_id)[0]
			var payload := CardDragPayload.new(CardDragPayload.SOURCE_HAND, -1, dragged.unique_id, [dragged])
			var before_drag := scene.deal.snapshot_state()
			scene.card_table.begin_drag(payload, scene.card_table.hand_views[dragged.unique_id])
			check(scene.card_table.drag_preview.get_child(0).has_node("ZodiacHandCue"), "charmed hand card retains its shader in the drag preview")
			scene.card_table.clear_drag_visuals()
			check(before_drag == scene.deal.snapshot_state(), "dragging charm visuals does not change the commanded target")
			await capture("snake-%s-charmed-hand" % locale)
			for index in level:
				command = current_command()
				check(not command.is_empty(), "the next charm is generated from the committed hand")
				var policy := scene.deal.snapshot_state()
				await click(hud.mechanic_guide.commands.get_child(0))
				check(policy == scene.deal.snapshot_state(), "command selection does not resolve a charm")
				await click(scene.discard_button if command.action == "discard" else scene.extend_button if command.action == "extension" else scene.ha_button)
				await ready_to_play()
				check(scene.deal.zodiac_boss.data.commands[index].status == "fulfilled", "actual pointer action obeys exactly the active charm")
				check(scene.deal.discard_count == 0 and scene.deal.zodiac_boss.turn_serial == 1 and scene.deal.state == DealState.STATE_ACTIVE, "consecutive charm never starts another turn")
				check(scene.deal.physical_card_accounting_is_valid(), "consecutive pointer actions retain unique physical cards")
			check(current_command().is_empty(), "all difficulty charms finish before the normal discard")
			var last: CardData = scene.deal.hand[-1]
			scene._on_card_pressed(last)
			await click(scene.discard_button)
			await ready_to_play()
			check(scene.deal.discard_count == 1 and scene.deal.zodiac_boss.turn_serial == 2, "normal pointer discard ends the turn after the charms")
			check(current_command().status == "pending", "the next turn starts a fresh charm")

		# The player can refuse with a different discard, losing both physical cards.
		await fixture("snake", 3)
		command = current_command()
		var wrong: CardData = scene.deal.hand.filter(func(card: CardData): return card.unique_id != command.card_id)[0]
		scene._on_card_pressed(wrong)
		await click(scene.discard_button)
		await ready_to_play()
		check(scene.deal.deck.discard_pile.size() == 2 and scene.deal.discard_count == 0, "wrong pointer discard punishes the target without ending the turn")
		check(fx.effect_kind == "card_discard" and fx.flights.size() == 2, "both committed cards have serpent discard flights")
		var protected := scene.deal.snapshot_state()
		await capture("snake-%s-card-refusal" % locale)
		await create_timer(1.2).timeout
		check(protected == scene.deal.snapshot_state() and fx.flights.is_empty(), "card discard animation is observational")

		# Refusing a charm by making a Meld containing its card loses the entire Meld.
		await fixture("snake", 3)
		command = current_command()
		var selected: Array[CardData] = []
		for candidate: Array[CardData] in Tactics.meld_candidates(scene.deal.hand):
			if candidate.any(func(card: CardData): return card.unique_id == command.card_id) and scene.deal.can_create_meld(candidate): selected = candidate; break
		check(not selected.is_empty(), "generated charm can be disobeyed through a real Meld")
		scene.set_card_selection(selected)
		await click(scene.ha_button)
		await ready_to_play()
		check(scene.deal.melds.is_empty() and selected.all(func(card: CardData): return scene.deal.deck.discard_pile.has(card)), "wrong pointer Meld discards every card including three-card Melds")
		check(scene.deal.discard_count == 0 and scene.deal.state == DealState.STATE_ACTIVE, "whole-Meld punishment retains the player turn")
		check(fx.effect_kind == "meld_discard" and fx.flights.size() == selected.size(), "whole-Meld loss is presented as a visible group")
		protected = scene.deal.snapshot_state()
		var animation_time: float = fx.effect_time
		scene._sync_all()
		check(fx.effect_time == animation_time, "ordinary refresh does not replay committed sabotage")
		await capture("snake-%s-meld-discard" % locale)
		await create_timer(1.2).timeout
		check(protected == scene.deal.snapshot_state(), "Meld discard animation cannot affect scoring or physical zones")

		# An existing Meld is charmed visibly, survives save/restore, and can be obeyed.
		await fixture("snake", 3)
		scene.deal.zodiac_boss.configure("snake", 3, 14281)
		scene.deal.zodiac_boss.begin_phase(scene.deal)
		var made := scene.deal.create_meld(scene.deal.hand.slice(0, 3))
		scene.deal.set_current_drink(DrinkCatalog.NAU_DA)
		scene.deal.zodiac_boss.begin_turn(1, scene.deal.hand, scene.deal)
		scene._sync_all()
		await frames(8)
		command = current_command()
		check(command.action_name == "nau_da_return" and command.meld_id == made.meld_id, "hard Snake charms the real whole-Meld Drink target")
		var view: MeldView = scene.card_table.meld_views[made.meld_id]
		check(view.get_node("SnakeCharmedMeld").visible, "actual Meld panel has the green serpent guard")
		for face: TextureRect in view._card_views.values():
			check(face.get_node("SwayFace/SnakeCharmCard").visible, "every actual card in the charmed Meld has green shader ink")
			await face_ink_contract(face.get_node("SwayFace"), true, "charmed Meld card")
		var meld_payload := CardDragPayload.new(CardDragPayload.SOURCE_TABLE_MELD, made.meld_id, scene.deal.melds[0].cards[0].unique_id, scene.deal.melds[0].cards)
		scene.card_table._build_card_drag_preview(meld_payload)
		for ghost: Control in scene.card_table.drag_preview.get_children():
			if ghost is TextureRect: check(ghost.has_node("ZodiacHandCue"), "every dragged card in a charmed Meld keeps the serpent shader")
		scene.card_table.clear_drag_visuals()
		protected = scene.deal.snapshot_state()
		scene.deal.restore_snapshot(protected)
		scene._sync_all()
		await frames()
		check(scene.deal.snapshot_state() == protected and view.get_node("SnakeCharmedMeld").visible, "restored charm keeps the same target and shader")
		await capture("snake-%s-charmed-meld" % locale)
		await click(scene.drink_table_button)
		await click(view)
		await ready_to_play()
		check(scene.deal.zodiac_boss.data.commands[0].status == "fulfilled" and scene.deal.get_meld(made.meld_id) == null, "actual Drink and Meld pointer action obeys the whole-Meld charm")
		check(scene.deal.discard_count == 0 and scene.deal.deck.discard_pile.is_empty(), "obeying the recovery charm does not sabotage cards or end the turn")
		check(scene.deal.physical_card_accounting_is_valid(), "Drink charm preserves card accounting")
		# Refusing that same table charm loses the whole existing Meld. The player's
		# extra discard remains visually separate from the three punished Meld cards.
		scene.deal.restore_snapshot(protected)
		scene._sync_all()
		await frames()
		wrong = scene.deal.hand[0]
		scene._on_card_pressed(wrong)
		await click(scene.discard_button)
		await ready_to_play()
		check(scene.deal.get_meld(made.meld_id) == null and scene.deal.deck.discard_pile.size() == 4, "refusing an existing Meld charm visibly discards all three cards plus the extra hand discard")
		check(scene.deal.discard_count == 0 and scene.deal.state == DealState.STATE_ACTIVE, "refusing the table charm leaves the same player turn open")
		check(fx.effect_kind == "meld_discard" and fx.flights.size() == 4, "existing Meld and extra discard both have committed serpent flights")
		for flight: Dictionary in fx.flights:
			if flight.card_id == wrong.unique_id: check(flight.stage == flight.source and flight.meld_id == -1, "the extra hand discard is not presented as part of the punished Meld")
		check(fx.flights.filter(func(flight: Dictionary): return flight.meld_id == made.meld_id).size() == 3, "only the actual table Meld cards coil together")
		check(scene.deal.physical_card_accounting_is_valid(), "whole existing Meld loss preserves unique physical card zones")
		protected = scene.deal.snapshot_state()
		await capture("snake-%s-table-meld-refusal" % locale)
		await create_timer(1.2).timeout
		check(protected == scene.deal.snapshot_state(), "existing Meld punishment animation is observational")
		# An Extension charms the added card; the receiving Meld is still ordinary.
		await fixture("snake", 2)
		scene.deal.zodiac_boss.configure()
		made = scene.deal.create_meld(scene.deal.hand.slice(0, 3))
		var seven := extra_card("7", "Hearts")
		scene.deal.zodiac_boss.configure("snake", 2, 14281)
		scene.deal.zodiac_boss.begin_phase(scene.deal)
		scene.deal.zodiac_boss.begin_turn(1, scene.deal.hand, scene.deal)
		command = current_command()
		var commanded: CardData = scene.deal.hand.filter(func(card: CardData): return card.unique_id == command.card_id)[0]
		scene._sync_all(scene.deal.discard_card(commanded))
		await frames(8)
		command = current_command()
		check(command.action == "extension" and command.card_id == seven.unique_id and command.meld_id == made.meld_id, "real next charm targets the added Extension card")
		view = scene.card_table.meld_views[made.meld_id]
		check(view._snake_guard == null or not view._snake_guard.visible, "an ordinary receiving Meld is not mislabelled as charmed")
		await face_ink_contract(scene.card_table.hand_views[seven.unique_id]._texture, true, "charmed Extension card")
		for face: TextureRect in view._card_views.values():
			await face_ink_contract(face.get_node("SwayFace"), false, "ordinary receiving Meld card")
		scene._on_card_pressed(seven)
		await click(view)
		await click(scene.extend_button)
		await ready_to_play()
		check(current_command().is_empty() and scene.deal.melds[0].cards.has(seven), "real pointer Extension resolves the current charm")
		for face: TextureRect in view._card_views.values():
			check(not face.has_node("SwayFace/SnakeCharmCard") or not face.get_node("SwayFace/SnakeCharmCard").visible, "resolved charm leaves no stale green shader on the Meld")
		# Modal and boss changes clear only transient serpent flights.
		await fixture("snake", 1)
		command = current_command()
		var forced: CardData = scene.deal.hand.filter(func(card: CardData): return card.unique_id == command.card_id)[0]
		var result := scene.deal.discard_card(forced)
		scene._sync_all(result)
		check(not fx.flights.is_empty(), "cleanup fixture has a live forced-discard flight")
		scene.modal_overlay.show()
		await frames()
		check(fx.flights.is_empty(), "modal removes transient serpent ghosts")
		scene.modal_overlay.hide()
		await fixture("tiger", 1)
		check(not fx.visible and fx.flights.is_empty(), "switching bosses clears Snake visuals")
	check(not ZodiacCatalog.DRAGON_ENABLED and not scene.start_boss_debug({"boss": "dragon"}), "Dragon cannot enter through the encounter API")
	scene.queue_free()
	await frames()
	print("SNAKE_OVERHAUL_SMOKE checks=%d failures=%d rendered=%s" % [checks, failures.size(), rendered])
	quit(0 if failures.is_empty() else 1)
