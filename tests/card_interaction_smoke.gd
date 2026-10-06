extends SceneTree

var failures: Array[String] = []
var checks := 0
var presses := 0
var last_pointer := Vector2.ZERO

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	root.size = Vector2i(1280, 720)
	var surface := Control.new()
	surface.size = Vector2(1152, 648)
	root.add_child(surface)
	var first := PlayingCardView.new()
	first.name = "First"
	first.set_card(CardData.new("pointer_first", "10", 10, "Spades", 10))
	surface.add_child(first)
	first.layout_to(Vector2(260, 400), -0.055, false)
	var second := PlayingCardView.new()
	second.name = "Second"
	var ink_card := CardData.new("pointer_second", "8", 8, "Hearts", 8)
	ink_card.fortune = -6
	ink_card.negative = true
	second.set_card(ink_card)
	surface.add_child(second)
	second.layout_to(Vector2(500, 400), 0.055, false)
	first.focus_next = first.get_path_to(second)
	second.focus_previous = second.get_path_to(first)
	first.card_pressed.connect(func(_card): presses += 1)
	second.card_pressed.connect(func(_card): presses += 1)
	await process_frame
	_motion(_center(first))
	await process_frame
	_check(root.gui_get_hovered_control() == first, "actual GUI pointer reaches the card")
	_check(first._hovered, "pointer enters hover pose")
	_button(_center(first), true)
	_button(_center(first), false)
	await process_frame
	_check(presses == 1, "one complete mouse click selects once")
	_check(first.has_focus(), "mouse click can retain navigation focus")
	_check(not is_instance_valid(first._focus_inspection), "mouse focus never opens a second inspection")
	_motion(Vector2(100, 100))
	await create_timer(0.23).timeout
	_check(not first._hovered and not first._press_active, "moving away clears hover and press")
	_check(first.position.is_equal_approx(first.base_position), "unselected card returns to its resting height")
	_check(not is_instance_valid(first._focus_inspection), "clicked inspection cannot remain stuck")
	# Keyboard navigation owns its inspection, with pointer hover suppressed.
	_key(KEY_TAB, true)
	_key(KEY_TAB, false)
	await process_frame
	_check(second.has_focus(), "Tab moves focus to the next physical card")
	_check(is_instance_valid(second._focus_inspection), "keyboard focus opens one inspection")
	if is_instance_valid(second._focus_inspection):
		_check((second._focus_inspection.find_child("SignedFortune", true, false) as Label).text == "-6", "keyboard inspection reports exact signed Fortune")
		_check(_passive(second._focus_inspection), "inspection descendants pass all pointer input")
		_check(second._get_tooltip(Vector2.ZERO).is_empty(), "keyboard inspection suppresses the native hover tooltip")
		var before := second._focus_inspection.global_position
		second.layout_to(Vector2(540, 350), -0.08, false)
		await process_frame
		_check(second._focus_inspection.global_position != before, "inspection follows card layout changes")
		_check(root.get_visible_rect().encloses(second._focus_inspection.get_global_rect()), "inspection stays inside the viewport")
	_key(KEY_ENTER, true)
	_key(KEY_ENTER, false)
	await process_frame
	_check(presses == 2, "keyboard confirmation selects exactly once")
	_motion(Vector2(160, 100))
	await process_frame
	_check(not is_instance_valid(second._focus_inspection), "switching to pointer input dismisses keyboard inspection")
	# A release elsewhere cancels a press without selecting the card.
	first.drag_enabled = false
	_motion(_center(first))
	_button(_center(first), true)
	_motion(Vector2(100, 100))
	_button(Vector2(100, 100), false)
	await process_frame
	_check(not first._press_active, "release outside clears the pressed state")
	_check(presses == 2, "release outside does not select a card")
	# Modal disable, parent hide, and loss of window focus clear transient state.
	_key(KEY_TAB, true)
	_key(KEY_TAB, false)
	await process_frame
	second.set_interaction_enabled(false)
	_check(second.focus_mode == Control.FOCUS_NONE and not second.has_focus(), "disabled cards leave the focus chain")
	_check(not is_instance_valid(second._focus_inspection), "modal disable closes inspection immediately")
	second.set_interaction_enabled(true)
	_motion(_center(first))
	_button(_center(first), true)
	surface.hide()
	_check(not first._press_active and not first._hovered, "hiding the hand clears an in-progress press and hover")
	surface.show()
	first._show_focus_inspection()
	first._press_active = true
	first.notification(Node.NOTIFICATION_WM_WINDOW_FOCUS_OUT)
	_check(not first._press_active and not first._hovered and not is_instance_valid(first._focus_inspection), "window focus loss clears transient card input")
	# Repeating an unchanged layout must preserve an active animation.
	first.layout_in_hand(Vector2(260, 400), -0.055, true, true)
	var tween := first._motion_tween
	var moving_from := first.position
	first.layout_in_hand(Vector2(260, 400), -0.055, true, true)
	_check(first._motion_tween == tween, "unchanged layout does not restart the card tween")
	_check(first.position == moving_from, "selection starts from the current pose without snapping")
	_motion(Vector2(100, 100))
	await create_timer(0.23).timeout
	_check(absf(first.position.y - (first.base_position.y - 24)) < 0.1, "selected card keeps its selection lift after hover ends")
	surface.queue_free()
	await process_frame
	await _match_input_checks()
	for failure in failures: print("FAIL: ", failure)
	print("TRADATALA_CARD_INTERACTION_SMOKE checks=%d failures=%d" % [checks, failures.size()])
	quit(0 if failures.is_empty() else 1)

func _match_input_checks() -> void:
	var scene := (load("res://scenes/match.tscn") as PackedScene).instantiate() as MatchUI
	root.add_child(scene)
	current_scene = scene
	await process_frame
	scene.session.run_save = RunSave.new("user://card_interaction_smoke.json")
	scene.game_started = true
	scene.game_layer.position = Vector2.ZERO
	scene.menu_layer.hide()
	scene.deal.start_tutorial_deal()
	scene.deal.hand[0].fortune = 6
	scene.deal.hand[1].fortune = -6
	scene.deal.hand[1].negative = true
	scene.interactions.locked = false
	scene._sync_all()
	scene.card_table.set_hand_interaction_enabled(true)
	await create_timer(0.3).timeout
	var source: PlayingCardView = scene.card_table.hand_views[scene.deal.hand[0].unique_id]
	var inventory := CardTargetQuery.physical_ids(scene.deal.hand)
	_motion(_center(source))
	await process_frame
	_check(root.gui_get_hovered_control() == source, "actual table hand receives pointer input")
	_button(_center(source), true)
	_motion(_center(source) + Vector2(30, -20))
	_check(scene.interactions.drag_payload != null, "physical pointer travel starts the table drag")
	_check(source._get_tooltip(Vector2.ZERO).is_empty(), "dragged card cannot open an inspection")
	_button(Vector2(15, 170), false)
	await process_frame
	_check(scene.interactions.drag_payload == null and scene.card_table.drag_preview == null, "release outside cancels drag preview and payload")
	_check(not source._press_active and not source._dragging, "outside drop clears the source gesture")
	_check(CardTargetQuery.physical_ids(scene.deal.hand) == inventory, "cancelled drag preserves every physical card")
	_motion(_center(source))
	_button(_center(source), true)
	_motion(_center(source) + Vector2(30, -20))
	_check(scene.interactions.drag_payload != null, "second drag can start after cancellation")
	scene.notification(Node.NOTIFICATION_WM_WINDOW_FOCUS_OUT)
	_check(scene.interactions.drag_payload == null and scene.card_table.drag_preview == null, "window focus loss also cancels table drag state")
	_check(not source._hovered and not source._press_active and not source._dragging, "window focus loss restores the source card")
	_motion(Vector2(15, 170))
	await create_timer(0.22).timeout
	_motion(_center(source))
	_button(_center(source), true)
	_button(_center(source), false)
	await process_frame
	_check(scene.interactions.selected_ids.has(source.card.unique_id), "real table click still selects after drag cancellation")
	_check(not is_instance_valid(source._focus_inspection), "real table mouse selection has no pinned inspection")
	await create_timer(0.62).timeout
	_check(_visible_inspections(root) <= 1, "hover never displays duplicate Fortune inspections")
	if "--capture" in OS.get_cmdline_user_args():
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://.godot/input-fixes/interaction.png")
	_motion(Vector2(15, 170))
	await process_frame
	_check(_visible_inspections(root) == 0, "leaving the table card removes every inspection")
	scene.card_table.set_hand_interaction_enabled(false)
	_check(not source.has_focus() and source.focus_mode == Control.FOCUS_NONE, "table modal disables keyboard focus on the hand")
	var detached := scene.card_table
	var hand_count := scene.hand_layer.get_child_count()
	var meld_count := scene.meld_row.get_child_count()
	var domain_before := scene.deal.snapshot_state()
	scene.remove_child(detached)
	# Native hover exit can arrive as the enclosing scene is being removed.
	scene._on_drink_hover_ended()
	detached.sync_hand([])
	detached.sync_melds()
	_check(detached.hand_views.is_empty() and detached.meld_views.is_empty(), "detached card owner releases its view registries")
	_check(scene.hand_layer.get_child_count() == hand_count and scene.meld_row.get_child_count() == meld_count, "late hover and sync cannot rebuild views after their owner exits")
	_check(scene.deal.snapshot_state() == domain_before, "visual owner exit preserves the physical deal snapshot")
	detached.queue_free()
	scene.queue_free()
	await process_frame

func _visible_inspections(node: Node) -> int:
	var count := 1 if node is Control and node.name == "CardFortuneTooltip" and node.is_visible_in_tree() else 0
	for child in node.get_children(true): count += _visible_inspections(child)
	return count

func _center(control: Control) -> Vector2:
	return control.get_global_transform_with_canvas() * (control.size * 0.5)

func _motion(point: Vector2) -> void:
	# A rendered viewport receives native idle motion too. Keep its OS cursor in
	# the same position as injected pointer input so that it cannot undo the test.
	if DisplayServer.get_name() != "headless": Input.warp_mouse(point)
	var event := InputEventMouseMotion.new()
	event.position = point
	event.global_position = point
	event.relative = point - last_pointer
	event.screen_relative = event.relative
	last_pointer = point
	root.push_input(event, true)

func _button(point: Vector2, pressed: bool) -> void:
	var event := InputEventMouseButton.new()
	event.position = point
	event.global_position = point
	event.button_index = MOUSE_BUTTON_LEFT
	event.pressed = pressed
	root.push_input(event, true)

func _key(key: Key, pressed: bool) -> void:
	var event := InputEventKey.new()
	event.keycode = key
	event.pressed = pressed
	root.push_input(event, true)

func _passive(node: Node) -> bool:
	if node is Control and (node.mouse_filter != Control.MOUSE_FILTER_IGNORE or node.focus_mode != Control.FOCUS_NONE): return false
	for child in node.get_children():
		if not _passive(child): return false
	return true

func _check(ok: bool, message: String) -> void:
	checks += 1
	if not ok: failures.append(message)
