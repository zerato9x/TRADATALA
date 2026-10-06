class_name StrawyController
extends CanvasLayer
## A request-driven local coach. Commands always return through MatchUI.
var host: MatchUI
var surface: Control
var actor: Control
var hit: Button
var hat: TextureRect
var eyes: TextureRect
var box: PanelContainer
var copy: Label
var actions: VBoxContainer
var scroll: ScrollContainer
var pointer: Control
var blocker: Control
var hats: Array[Texture2D] = []
var expressions: Array[Texture2D] = []
var blink: Texture2D
var halfblink: Texture2D
var normal: Texture2D
var eye_anchors: Array[Vector2] = []
var art_scale := 1.0
var clock := 0.0
var blink_clock := 0.0
var expression := 0
var reaction_until := 0.0
var pose := 0
var travel: Tween
var tour: Array[Dictionary] = []
var tour_index := 0
var last_click := -1000
var pending_single := false
var click_generation := 0
var quick_plan: Dictionary = {}
var quick_action := ""
var quick_card_id := ""
var quick_signature := 0
var quick_context := ""
var touch_index := -1
var touch_start := Vector2.ZERO
var touch_cancelled := false
var touch_ids := {}
var native_sequence := false
var suppress_mouse_until := 0
var _trail_clock := 0.0
var _last_context := ""
var choice_open := false
var window_focused := true
var speech_reveal: Tween

func configure(ui: MatchUI) -> void:
	host = ui
	host.action_rejected.connect(_reaction.bind(false))
	layer = 900
	name = "Strawy"
	surface = Control.new()
	surface.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	surface.mouse_filter = Control.MOUSE_FILTER_IGNORE
	surface.theme = PresentationTheme.create_game_theme()
	add_child(surface)
	blocker = Control.new()
	blocker.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	blocker.mouse_filter = Control.MOUSE_FILTER_STOP
	surface.add_child(blocker)
	blocker.hide()
	for i in range(1, 9): hats.append(load("res://assets/ui/strawy/hat_%02d.png" % i))
	for i in range(1, 17): expressions.append(load("res://assets/ui/eye_expressions/eye_expression_%02d.png" % i))
	blink = load("res://assets/ui/strawy/strawy_blink.png")
	halfblink = load("res://assets/ui/strawy/strawy_halfblink.png")
	normal = load("res://assets/ui/strawy/strawy_normal.png")
	var manifest: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://assets/ui/strawy/poses.json"))
	art_scale = 136.0 / manifest["canvas"][0]
	for entry in manifest["poses"]: eye_anchors.append(Vector2(entry["eyes"][0], entry["eyes"][1]))
	actor = Control.new()
	actor.name = "StrawyActor"
	actor.size = Vector2(136, 120)
	actor.pivot_offset = Vector2(68, 98)
	actor.mouse_filter = Control.MOUSE_FILTER_IGNORE
	surface.add_child(actor)
	hat = _art(actor, Vector2.ZERO, Vector2(136, 113), hats[0])
	eyes = _art(actor, Vector2(32, 73), Vector2(72, 52), expressions[0])
	hit = Button.new()
	hit.name = "StrawyAsk"
	hit.flat = true
	for state in ["normal","hover","pressed","disabled","focus"]:
		hit.add_theme_stylebox_override(state,StyleBoxEmpty.new())
	hit.size = actor.size
	_update_tooltip()
	hit.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	hit.pressed.connect(_clicked)
	actor.add_child(hit)
	box = PanelContainer.new()
	box.name = "StrawyHelp"
	box.size = Vector2(320, 0)
	var speech_panel := PresentationTheme.panel_style(Color("102c2bfc"), Color("ddbd7f"), 2, 12, 14)
	for side in ["left", "right", "top", "bottom"]: speech_panel.set("content_margin_" + side, 12.0)
	box.add_theme_stylebox_override("panel", speech_panel)
	surface.add_child(box)
	var content := VBoxContainer.new()
	box.add_child(content)
	var header := HBoxContainer.new()
	content.add_child(header)
	var title := Label.new()
	title.text = "Strawy"
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title)
	var dismiss := Button.new()
	dismiss.name = "StrawyDismiss"
	dismiss.text = "×"
	dismiss.custom_minimum_size = Vector2(44, 44)
	dismiss.pressed.connect(func():
		if choice_open: _answer_choice(host.settings.strawy_enabled)
		else: close())
	PresentationTheme.configure_button(dismiss, "tea")
	header.add_child(dismiss)
	scroll = ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(292, 80)
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	content.add_child(scroll)
	actions = VBoxContainer.new()
	actions.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	actions.add_theme_constant_override("separation", 8)
	scroll.add_child(actions)
	actions.minimum_size_changed.connect(_fit_panel)
	copy = Label.new()
	copy.custom_minimum_size = Vector2(276, 0)
	copy.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	copy.visible_characters_behavior = TextServer.VC_CHARS_AFTER_SHAPING
	copy.add_theme_font_size_override("font_size", 16)
	copy.mouse_filter = Control.MOUSE_FILTER_STOP
	copy.gui_input.connect(_speech_input)
	actions.add_child(copy)
	box.hide()
	pointer = preload("res://scripts/ui/tutorial_spotlight.gd").new()
	surface.add_child(pointer)
	pointer.z_index = -1
	host.deal.state_changed.connect(_react)
	host.campaign.day_finished.connect(func(_day):
		if host.campaign.current_day_index == 0: tutorial_finished())
	host.settings.strawy_enabled_changed.connect(func(_enabled):
		close()
		surface.visible = _in_game())
	host.settings.locale_changed.connect(func(_locale):
		_clear_quick_action()
		_update_tooltip()
		if not tour.is_empty(): close()
		elif box.visible: _populate())
	actor.position = dock()
	surface.visible = _in_game()

func _in_game() -> bool:
	return not host.session.debug_active and host.settings.strawy_enabled and host.game_started and not host.menu_layer.visible and not host.menu_transitioning

func tutorial_finished() -> void:
	if not host.session.debug_active and host.settings.tutorial_enabled: host.settings.mark_tutorial_completed()

func _can_offer_choice() -> bool:
	if not _in_game() or not window_focused or host.session.restoring or host.interactions.locked or host.money_playback.running or host.money_presentation.presentation_active: return false
	if box.visible or not tour.is_empty() or not quick_action.is_empty() or pending_single or host.interactions.drag_payload != null or host.interactions.drink_targeting: return false
	if host.modal_overlay.visible or host.score_overlay.visible or host.pile_archive.overlay.visible or host.deck_screen.visible or host.zodiac_table.shade.visible or host.get_node("ActionLegend/Shade").visible or host.get_tree().root.has_node("GameGlossary") or host.get_tree().root.has_node("LotteryReceipt") or is_instance_valid(host.wallet_spiral) or _receipt_open(): return false
	return host.event_table.focused_npc_id.is_empty() and not host.event_table.deck_focused and not host.event_table.overview.expanded

func _offer_choice() -> void:
	close()
	choice_open = true
	box.show()
	blocker.show()
	host.event_table.cancel_pointer()
	_populate_choice()

func _populate_choice() -> void:
	_clear_buttons()
	_last_context = _context_id()
	_say(words("Tutorial complete. Keep Strawy?", "Xong hướng dẫn. Giữ Strawy không?"))
	var keep := _button("Keep Strawy", "Giữ Strawy", func(): _answer_choice(true))
	keep.name = "StrawyKeep"
	var disable := _button("Turn off", "Tắt Strawy", func(): _answer_choice(false))
	disable.name = "StrawyTurnOff"
	for button in [keep, disable]:
		var other: Button = disable if button == keep else keep
		for property in ["focus_next", "focus_previous", "focus_neighbor_top", "focus_neighbor_bottom", "focus_neighbor_left", "focus_neighbor_right"]:
			button.set(property, other.get_path())
	keep.grab_focus.call_deferred()
	_fit_panel()

func _answer_choice(enabled: bool) -> void:
	if not choice_open: return
	close()
	host.settings.set_strawy_enabled(enabled)

func _update_tooltip() -> void:
	hit.tooltip_text = words("Tap for help · double tap for a move preview · third tap to act", "Chạm để hỏi · chạm hai lần để xem nước đi · chạm lần ba để thực hiện")

static func words(en: String, vi: String) -> String:
	return GameGlossary.words(en, vi)

func _art(parent: Control, point: Vector2, extent: Vector2, texture: Texture2D) -> TextureRect:
	var view := TextureRect.new()
	view.position = point
	view.size = extent
	view.texture = texture
	view.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	view.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	view.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(view)
	return view

func dock() -> Vector2:
	return Vector2(16, maxf(host.get_viewport_rect().size.y - 132, 16))

func _process(delta: float) -> void:
	if host == null: return
	# The request-driven campaign tutorial covers the first real day. This also
	# recovers completion when a legacy or interrupted run resumes after Monday.
	if host.game_started and host.campaign.current_day_index > 0 and host.settings.tutorial_enabled and not host.settings.tutorial_completed: tutorial_finished()
	var shown := _in_game()
	if surface.visible != shown:
		if not shown: close()
		surface.visible = shown
	if not shown: return
	if host.settings.tutorial_completed and not host.settings.strawy_choice_made and host.settings.tutorial_enabled and _can_offer_choice(): _offer_choice()
	if not quick_action.is_empty() and not _quick_action_valid(): close()
	clock += delta
	blink_clock = fmod(clock + 0.6, 4.8)
	if reaction_until < clock:
		expression = 0 if box.visible else 15 if not host.game_started else 0
		pose = 0 if box.visible else 5 if not host.game_started else 0
	hat.texture = hats[pose]
	eyes.texture = blink if blink_clock < 0.09 else halfblink if blink_clock < 0.17 else normal if expression == 0 else expressions[expression]
	actor.rotation = sin(clock * 1.8) * 0.035
	hat.position.y = sin(clock * 2.1) * 2.0
	var gaze := (host.get_viewport().get_mouse_position() - actor.position - actor.size * 0.5).normalized() * 2.0
	eyes.position = eye_anchors[pose] * art_scale - eyes.size * 0.5 + gaze + Vector2(0, sin(clock * 2.1) * 2.0)
	if tour.is_empty() and (travel == null or not travel.is_running()): actor.position = dock()
	box.position = (host.get_viewport_rect().size - box.size) * 0.5 if choice_open else Vector2(164, clampf(host.get_viewport_rect().size.y - box.size.y - 20, 12, 260))
	hit.disabled = choice_open or not tour.is_empty()
	if not tour.is_empty():
		var target := tour[tour_index]["control"] as Control
		if not is_instance_valid(target) or not target.is_visible_in_tree() or _context_id() != _last_context: close()
		else:
			var extent := host.get_viewport_rect().size
			var best_area := INF
			for position in [box.position, Vector2(extent.x-box.size.x-16,box.position.y), Vector2(16,12), Vector2(extent.x-box.size.x-16,12)]:
				var overlap := Rect2(position,box.size).intersection(target.get_global_rect().grow(8))
				var area := overlap.size.x * overlap.size.y
				if area < best_area: best_area = area; box.position = position
	if travel != null and travel.is_running():
		_trail_clock += delta
		if _trail_clock > 0.065:
			_trail_clock = 0
			var spark := _art(surface, actor.position + Vector2(45, 60), Vector2(38, 32), hats[pose])
			spark.modulate = Color(1, 0.85, 0.5, 0.32)
			var fade := create_tween()
			fade.tween_property(spark, "modulate:a", 0.0, 0.32)
			fade.tween_callback(spark.queue_free)
	if box.visible and quick_action.is_empty() and tour.is_empty() and _context_id() != _last_context: _populate()

func _clicked() -> void:
	if not _in_game() or choice_open: return
	click_generation += 1
	if not quick_action.is_empty():
		_confirm_quick_action()
		return
	var now := Time.get_ticks_msec()
	if now - last_click <= 320:
		pending_single = false
		last_click = -1000
		if can_play_cards(): preview_action()
		else: start_tour()
		return
	last_click = now
	pending_single = true
	var clicked_context := _context_id()
	var generation := click_generation
	await get_tree().create_timer(0.33).timeout
	if pending_single and generation == click_generation and _in_game() and _context_id() == clicked_context:
		pending_single = false
		if box.visible: close()
		else: open_help()

func preview_action() -> void:
	if not can_play_cards(): _reaction(false); return
	var plan := HandAdvice.next_action(host.deal, host.deal.queries.hand_advice())
	close()
	if plan.is_empty():
		open_help()
		_say(words("No legal action is available. Check the locked cards and current phase.", "Chưa có nước đi hợp lệ. Xem bài bị khóa và hiệp hiện tại."))
		return
	host.set_card_selection(plan.cards, int(plan.get("meld_id", -1)))
	quick_plan = plan
	quick_action = plan.kind
	quick_card_id = plan.cards[0].unique_id if plan.cards.size() == 1 else ""
	quick_signature = HandAdvice.signature(host.deal)
	quick_context = _context_id()
	_last_context = quick_context
	_clear_buttons()
	box.show()
	blocker.hide()
	_say(_plan_copy(plan) + "\n\n" + words("Tap Strawy once more to confirm this move.", "Chạm Strawy thêm một lần để xác nhận nước đi này."))
	_fit_panel()
	var targets: Array[Control] = []
	for card: CardData in plan.cards:
		var target := host.card_table.hand_views.get(card.unique_id) as Control
		if target != null: targets.append(target)
	var meld_target := host.card_table.meld_views.get(host.interactions.selected_meld_id) as Control
	if meld_target != null: targets.append(meld_target)
	pointer.set_targets(targets)
	pose = 3
	expression = 2
	reaction_until = clock + 0.6

func _plan_copy(plan: Dictionary) -> String:
	var labels: Array[String] = []
	for card: CardData in plan.cards: labels.append(card.short_label())
	var cards := ", ".join(labels)
	match plan.kind:
		"play":
			var verb := words("extend the table Meld", "ghép vào Phỏm trên bàn") if plan.play.action == HandAdvisor.ACTION_EXTENSION else words("make a new Meld", "hạ Phỏm mới")
			var drink := DrinkCatalog.display_name(host.deal.current_drink_id) + ": " if plan.play.get("use_drink", false) else ""
			return drink + words("I'll %s with %s. Estimated payout: %d PTS.", "Tôi sẽ %s bằng %s. Dự tính nhận: %d ĐIỂM.") % [verb, cards, plan.play.estimated_points]
		"swap": return words("I'll use %s to swap %s for %s, which can make a Meld or extend the table. This spends one use.", "Tôi sẽ dùng %s đổi %s lấy %s để có thể hạ hoặc ghép Phỏm. Tốn một lượt dùng.") % [DrinkCatalog.display_name(host.deal.current_drink_id), cards, plan.record.card.short_label()]
		"recover", "recover_card": return words("I'll use %s to return eligible table cards to your hand so they can score again. This spends one use.", "Tôi sẽ dùng %s lấy bài hợp lệ trên bàn về tay để ghi điểm lại. Tốn một lượt dùng.") % DrinkCatalog.display_name(host.deal.current_drink_id)
		"discard": return words("I'll discard %s. ", "Tôi sẽ bỏ %s. ") % cards + AdvisoryText.reasoning(host.deal.queries.hand_advice(), host.deal.state == DealState.STATE_FINAL_COMMIT_WINDOW)
		"empty": return words("I'll end the empty turn and refill if another turn remains.", "Tôi sẽ kết thúc lượt trống và bù bài nếu còn lượt.")
		"skip": return words("I'll skip Trà Đá's extra discard and refill your hand.", "Tôi sẽ bỏ qua lần bỏ thêm của Trà Đá rồi bù bài.")
		"settle": return host.end_action_copy("settle")
	return ""

func _quick_action_valid() -> bool:
	return can_play_cards() and quick_context == _context_id() and quick_signature == HandAdvice.signature(host.deal)

func _clear_quick_action() -> void:
	quick_action = ""
	quick_plan.clear()
	quick_card_id = ""
	if pointer != null and tour.is_empty(): pointer.set_targets([] as Array[Control])

func _confirm_quick_action() -> void:
	var valid := _quick_action_valid()
	var plan := quick_plan.duplicate()
	close()
	if not valid: _reaction(false); return
	host.refresh_interaction_view()
	match plan.kind:
		"play":
			if plan.play.action == HandAdvisor.ACTION_EXTENSION: host.request_card_action("extend")
			else: host.request_card_action("meld")
		"swap": host.swap_drink_card(plan.cards[0], plan.record)
		"recover": host.request_drink_recovery(plan.meld_id)
		"recover_card": host.recover_drink_card(plan.meld_id, plan.card)
		"settle", "skip": host.request_card_action("settle")
		"discard", "empty": host.request_card_action("discard")

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.device == -1 and Time.get_ticks_msec() < suppress_mouse_until:
		get_viewport().set_input_as_handled()
		return
	if not _in_game(): return
	if event is InputEventScreenTouch:
		if actor.get_global_rect().has_point(event.position) or (box.visible and box.get_global_rect().has_point(event.position)):
			suppress_mouse_until = Time.get_ticks_msec() + 800
		if event.pressed:
			touch_ids[event.index] = true
			if touch_ids.size() > 1: touch_cancelled = true
			if touch_ids.size() == 1 and actor.get_global_rect().has_point(event.position) and tour.is_empty():
				native_sequence = true
				touch_index = event.index
				touch_start = event.position
				touch_cancelled = false
				get_viewport().set_input_as_handled()
		else:
			touch_ids.erase(event.index)
			if event.index == touch_index:
				if not event.canceled and not touch_cancelled and actor.get_global_rect().has_point(event.position): _clicked()
				touch_index = -1
				get_viewport().set_input_as_handled()
		if native_sequence:
			get_viewport().set_input_as_handled()
			if touch_ids.is_empty(): native_sequence = false
		if box.visible and not box.get_global_rect().has_point(event.position) and not actor.get_global_rect().has_point(event.position):
			if not quick_action.is_empty(): close()
			else: get_viewport().set_input_as_handled()
	elif event is InputEventScreenDrag and event.index == touch_index:
		if event.position.distance_to(touch_start) > 12: touch_cancelled = true
		get_viewport().set_input_as_handled()
	elif event is InputEventMouseButton and event.device == -1 and actor.get_global_rect().has_point(event.position):
		get_viewport().set_input_as_handled()
	elif box.visible and event is InputEventMouseButton and not box.get_global_rect().has_point(event.position) and not actor.get_global_rect().has_point(event.position):
		if not quick_action.is_empty(): close()
		else: get_viewport().set_input_as_handled()
	elif box.visible and event.is_action_pressed("ui_cancel"):
		if choice_open: _answer_choice(host.settings.strawy_enabled)
		else: close()
		get_viewport().set_input_as_handled()
	elif box.visible and event is InputEventKey:
		if not quick_action.is_empty():
			if event.pressed and not event.echo: close()
			return
		if choice_open:
			for action in ["ui_accept", "ui_focus_next", "ui_focus_prev", "ui_up", "ui_down", "ui_left", "ui_right"]:
				if event.is_action(action): return
		get_viewport().set_input_as_handled()

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_WINDOW_FOCUS_OUT:
		window_focused = false
		touch_cancelled = true
		touch_index = -1
		touch_ids.clear()
		native_sequence = false
		pending_single = false
		if host != null: close()
	elif what == NOTIFICATION_WM_WINDOW_FOCUS_IN:
		window_focused = true

func _context_id() -> String:
	return str([host.game_started, host.menu_layer.visible, host.front_end.page, host.campaign.current_phase, host.campaign.current_day_index, host.deal.state, host.deal.current_phase,
		host.deal.discard_count, host.event_table.focused_npc_id, host.event_table.deck_focused,
		host.deck_screen.visible, host.zodiac_table.shade.visible, host.interactions.selected_ids.keys(), host.interactions.selected_meld_id,
		host.interactions.drink_targeting, host.get_tree().root.has_node("GameGlossary"), host.modal_overlay.visible,
		host.score_overlay.visible and not host.money_presentation.presentation_active, host.pile_archive.overlay.visible, host.get_node("ActionLegend/Shade").visible, host.get_tree().root.has_node("LotteryReceipt"), _receipt_open(), host.settings.tutorial_enabled])

func open_help() -> void:
	if not _in_game() or choice_open: return
	_clear_quick_action()
	if host.interactions.drag_payload != null: host.cancel_card_drag()
	tour.clear()
	pointer.set_targets([] as Array[Control])
	box.show()
	blocker.show()
	_populate()

func close() -> void:
	_finish_speech()
	choice_open = false
	_clear_quick_action()
	pending_single = false
	click_generation += 1
	last_click = -1000
	touch_cancelled = true
	touch_index = -1
	touch_ids.clear()
	native_sequence = false
	box.hide()
	blocker.hide()
	tour.clear()
	pointer.set_targets([] as Array[Control])
	if travel != null: travel.kill()
	travel = create_tween()
	travel.tween_property(actor, "position", dock(), 0.3).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	host.event_table.cancel_pointer()

func _button(en: String, vi: String, callback: Callable, disabled: bool = false) -> Button:
	var button := Button.new()
	button.text = words(en, vi)
	button.custom_minimum_size.y = 44
	button.disabled = disabled
	PresentationTheme.configure_button(button, "tea")
	button.pressed.connect(callback)
	actions.add_child(button)
	return button

func _clear_buttons() -> void:
	for child in actions.get_children():
		if child == copy: continue
		actions.remove_child(child)
		child.queue_free()

func _say(text: String) -> void:
	_finish_speech()
	copy.text = text
	# Reserve the full paragraph before revealing it, so response buttons stay put.
	copy.custom_minimum_size.y = copy.get_theme_font("font").get_multiline_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, 276, 16).y + 8
	scroll.scroll_vertical = 0
	speech_reveal = TextReveal.reveal(copy, 0.0, 75.0)

func _finish_speech() -> void:
	if speech_reveal != null:
		speech_reveal.kill()
		speech_reveal = null
	if copy != null: TextReveal.finish(copy)

func _speech_input(event: InputEvent) -> void:
	if (event is InputEventScreenTouch and not event.pressed and not event.canceled) or (event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and not event.pressed):
		_finish_speech()
		copy.accept_event()

func _populate() -> void:
	if choice_open: _populate_choice(); return
	_clear_buttons()
	_last_context = _context_id()
	_say(_context_copy())
	if can_play_cards():
		var advice := host.deal.queries.hand_advice()
		var play: Dictionary = advice["play"]
		if play["action"] != HandAdvisor.ACTION_NONE:
			var extending: bool = play["action"] == HandAdvisor.ACTION_EXTENSION
			var play_button := _button("Extend" if extending else "Play Meld", "Ghép" if extending else "Hạ Phỏm", func(): _command("play"))
			play_button.name = "StrawyPlay"
		if host.deal.tra_da_extra_discard_pending and advice["extra_action"] == "skip":
			var skip_button := _button("Skip extra discard", "Bỏ qua lần bỏ thêm", func(): _command("discard"))
			skip_button.name = "StrawyDiscard"
		if not host.interactions.selected_ids.is_empty():
			var info_button := _button("Card info", "Xem lá bài", _explain_cards)
			info_button.name = "StrawyCardInfo"
		elif host.deal.current_drink_has_charge() and host.deal.current_drink_id != DrinkCatalog.NONE:
			_button("Drink targets", "Mục tiêu đồ uống", _explain_drink)
		if actions.get_child_count() < 4: _button("Show controls", "Chỉ thao tác", start_tour)
		_button("Handbook", "Sổ tay", func():
			var detail := _context_detail()
			close()
			GameGlossary.open_entry(host, words("Current action", "Hành động hiện tại"), detail, _handbook_section()))
	else:
		_button("Show me", "Chỉ giúp tôi", start_tour)
		if not host.get_tree().root.has_node("GameGlossary"):
			_button("Handbook", "Sổ tay", func():
				close()
				GameGlossary.open(host, _handbook_section()))
	_fit_panel()

func _fit_panel() -> void:
	scroll.custom_minimum_size.y = clampf(actions.get_combined_minimum_size().y + 8, 80, 320)
	box.size = Vector2(320, 0)

func can_play_cards() -> bool:
	return _in_game() and not choice_open and host.interaction_snapshot().can_play

func _receipt_open() -> bool:
	return is_instance_valid(host.resolve_receipt) and host.resolve_receipt.visible

func _handbook_section() -> String:
	if host.zodiac_table.shade.visible: return "campaign"
	if host.interactions.drink_targeting: return "drinks"
	if host.event_table.focused_npc_id == EventTableController.NPC_THAY_BOI: return "gieo"
	if host.event_table.focused_npc_id == "lotto" or host.get_tree().root.has_node("LotteryReceipt"): return "lottery"
	return "npcs" if host.current_campaign_event != null else "core"

func _command(kind: String) -> void:
	if not can_play_cards(): _reaction(false); _populate(); return
	var advice := host.deal.queries.hand_advice()
	close()
	if kind == "play":
		var play: Dictionary = advice["play"]
		if play["action"] == HandAdvisor.ACTION_NONE: _reaction(false); return
		host.set_card_selection(play.cards, int(play.get("meld_id", -1)))
		if play["action"] == HandAdvisor.ACTION_EXTENSION: host.request_card_action("extend")
		else: host.request_card_action("meld")
	elif kind == "discard":
		if host.deal.state != DealState.STATE_ACTIVE: _reaction(false); return
		if host.deal.tra_da_extra_discard_pending and advice["extra_action"] == "skip":
			host.request_card_action("settle")
		else:
			if advice["discard_id"].is_empty(): _reaction(false); return
			host.set_card_selection(host.deal.hand.filter(func(card): return card.unique_id == advice["discard_id"]))
			host.request_card_action("discard")

func _context_copy() -> String:
	if host.get_tree().root.has_node("GameGlossary"): return words("Choose a topic", "Chọn chủ đề")
	if host.zodiac_table.shade.visible: return words("Choose your response", "Chọn câu trả lời")
	if _receipt_open() or host.score_overlay.visible: return words("Results · Continue when ready", "Kết quả · Tiếp tục khi sẵn sàng")
	if host.deck_screen.visible: return words("Select a card", "Chọn lá bài")
	if host.interactions.drink_targeting: return words("Select target · Confirm", "Chọn mục tiêu · Xác nhận")
	if host.modal_overlay.visible: return words("Choose · Confirm", "Chọn · Xác nhận")
	if host.deal.tra_da_extra_discard_pending and host.current_campaign_event == null: return words("Extra discard or Skip", "Bỏ thêm hoặc Bỏ qua")
	if host.current_campaign_event != null: return words("Select a visitor", "Chọn vị khách")
	if host.deal.state == DealState.STATE_FINAL_COMMIT_WINDOW: return words("Last Call · Meld/Extend → Settle", "Chốt Hạ · Hạ/Ghép → Chốt")
	if host.deal.state == DealState.STATE_PHASE_CHOICE: return words("Keep marked cards → Phase 2", "Giữ bài đánh dấu → Hiệp 2")
	return words("Meld / Extend · or Discard", "Hạ / Ghép · hoặc Bỏ bài")

func _context_detail() -> String:
	if host.get_tree().root.has_node("GameGlossary"): return words("Search a rule or choose a topic to read how it works. Close the Handbook to return to your game.", "Tìm luật hoặc chọn chủ đề để xem cách chơi. Đóng Sổ tay để trở lại ván.")
	if host.zodiac_table.shade.visible: return words("Read this visitor's effect, then choose an available service. Check the cost and affected cards before confirming.", "Đọc hiệu ứng của vị khách rồi chọn dịch vụ đang mở. Xem giá và bài bị ảnh hưởng trước khi xác nhận.")
	if host.current_campaign_event == null and host.deal.state == DealState.STATE_PHASE_CHOICE: return words("Phase 2 carries only cards marked with Sâm dứa or Bạc xỉu. The rest are replaced; table Melds stay.", "Hiệp 2 chỉ giữ bài đã đánh dấu bằng Sâm dứa hoặc Bạc xỉu. Phần còn lại được thay; Phỏm trên bàn vẫn giữ.")
	if _receipt_open() or (host.score_overlay.visible and not host.money_presentation.presentation_active): return words("Check your earned points and wallet changes. When you're ready, continue to the next part of the run.", "Xem điểm kiếm được và thay đổi trong ví. Khi sẵn sàng, tiếp tục sang bước kế của ván chơi.")
	if host.modal_overlay.visible: return words("Read the choice and its effect before confirming. The highlighted button carries out that choice.", "Đọc lựa chọn và tác dụng trước khi xác nhận. Nút được chỉ sẽ thực hiện lựa chọn đó.")
	if host.deck_screen.visible: return words("Search by rank or suit, then select a card to inspect its properties. Back returns to the table.", "Tìm theo số hoặc chất rồi chọn lá để xem thuộc tính. Về bàn để tiếp tục.")
	if host.interactions.drink_targeting: return words("Select an eligible card or Meld, then confirm the Drink effect. Cancel if you want to keep the charge.", "Chọn bài hoặc Phỏm hợp lệ rồi xác nhận hiệu ứng đồ uống. Hủy nếu muốn giữ lượt dùng.")
	if host.deal.tra_da_extra_discard_pending and host.current_campaign_event == null:
		return words("Trà Đá lets you discard one more loose card, or Skip. Your hand refills after this choice.", "Trà Đá cho bỏ thêm một lá rời, hoặc Bỏ qua. Tay bài được bù sau lựa chọn này.")
	if host.deal.state == DealState.STATE_FINAL_COMMIT_WINDOW and host.current_campaign_event == null: return words("Last Call: Meld/Extend, then settle. No refill.", "Chốt Hạ: Hạ/Ghép rồi chốt. Không bù bài.")
	if host.settings.tutorial_enabled and host.campaign.current_day_index == 0:
		var hint: Array[String] = preload("res://scripts/ui/campaign_hints.gd").instruction(host.campaign, host.deal, host.current_campaign_event, host.event_table.focused_npc_id, host.resolve_mode)
		if not hint[0].is_empty() and not host.campaign.onboarding.learned.has(hint[0]): return words(hint[1], hint[2])
	if host.current_campaign_event != null:
		var hint: Array[String] = preload("res://scripts/ui/campaign_hints.gd").instruction(host.campaign, host.deal, host.current_campaign_event, host.event_table.focused_npc_id, host.resolve_mode)
		return words(hint[1], hint[2])
	return words("Select three matching ranks or a same-suit sequence, then HẠ to score. Otherwise discard one loose card to end the turn and refill.", "Chọn ba lá cùng số hoặc dãy cùng chất rồi HẠ để ghi điểm. Nếu chưa có, bỏ một lá rời để kết thúc lượt và bù bài.")

func _explain_cards() -> void:
	var advice := host.deal.queries.hand_advice()
	var lines: Array[String] = []
	var full: Array[String] = []
	for card: CardData in host.interactions.selected_cards():
		lines.append("%s · %d PTS · %s %d/100" % [card.short_label(), card.score_value(), words("Keep", "Giữ"), advice["by_card"].get(card.unique_id, {}).get("keep_score", 100)])
		full.append("%s · %d PTS\n%s" % [card.short_label(), card.score_value(), AdvisoryText.describe(advice["by_card"].get(card.unique_id, {}), host.deal.state == DealState.STATE_FINAL_COMMIT_WINDOW)])
	_say("\n".join(lines))
	_button("Handbook", "Sổ tay", func(): GameGlossary.open_entry(host, words("Card info", "Lá bài"), "\n\n".join(full), "cards"))
	_fit_panel()

func explain_card(card: CardData) -> void:
	if card == null or not host.deal.hand.has(card): return
	suppress_mouse_until = Time.get_ticks_msec() + 800
	open_help()
	var row: Dictionary = host.deal.queries.hand_advice()["by_card"].get(card.unique_id, {})
	_say("%s · %d PTS · %s %d/100" % [card.short_label(), card.score_value(), words("Keep", "Giữ"), row.get("keep_score", 100)])
	_button("Handbook", "Sổ tay", func(): GameGlossary.open_entry(host, card.short_label(), AdvisoryText.describe(row, host.deal.state == DealState.STATE_FINAL_COMMIT_WINDOW), "cards"))
	_fit_panel()

func _explain_drink() -> void:
	tour = []
	_add_target(host.drink_table_button, host.drink_tooltip())
	for id in host.interactions.drink_hand_eligible_card_ids():
		_add_target(host.card_table.hand_views.get(id), words("Select this eligible card, then confirm to use the Drink's effect and spend a charge.", "Chọn lá hợp lệ này rồi xác nhận để dùng hiệu ứng đồ uống và tiêu một lượt dùng."))
		if tour.size() >= 3: break
	if tour.size() < 2:
		for meld: MeldState in host.deal.melds:
			if host.deal.can_use_nau_da(meld.meld_id) or not host.deal.nuoc_voi_targets().filter(func(t): return t.get("meld_id", -1) == meld.meld_id).is_empty():
				_add_target(host.card_table.meld_views.get(meld.meld_id), words("Select this Meld's eligible target, then confirm the Drink effect. Check the effect before spending a charge.", "Chọn mục tiêu hợp lệ trong Phỏm này rồi xác nhận hiệu ứng đồ uống. Xem tác dụng trước khi tiêu lượt dùng."))
	if not tour.is_empty(): tour_index = 0; _point()

func _add_target(control: Control, text: String) -> void:
	if control != null and control.is_visible_in_tree(): tour.append({"control": control, "text": text})

func _npc_guidance(npc: String) -> String:
	match npc:
		EventTableController.NPC_DOI_NO:
			return words("Check today's debt and your wallet, then pay to continue.", "Xem nợ hôm nay và ví rồi trả để tiếp tục.") if host.resolve_mode == "collection" else words("Meet Đòi Nợ to check today's debt. Payment is due after the Evening Deal.", "Gặp Đòi Nợ để xem nợ hôm nay. Trả nợ sau ván tối.")
		EventTableController.NPC_DANH_GIAY:
			return words("At Starter, commit one or two cards to Đánh Giày. Reroll their Rank or Suit permanently; each service doubles in price. Your chosen cards stay locked for this visit.", "Ở đầu ngày, chốt một hoặc hai lá với Đánh Giày. Đổi vĩnh viễn số hoặc chất; mỗi dịch vụ tăng gấp đôi riêng. Các lá đã chọn được giữ cho chuyến này.")
		EventTableController.NPC_TRA_DA:
			return words("Choose a glass, read its effect, then Order. This Drink changes how you play the next Deals.", "Chọn ly, đọc hiệu ứng rồi GỌI MÓN. Đồ uống thay đổi cách chơi các ván tiếp theo.")
		EventTableController.NPC_THAY_BOI:
			return words("Pull the lever to reveal a card change. Check the effect and target, then Accept to apply it or Refuse to leave your cards unchanged.", "Kéo cần để xem biến đổi bài. Xem hiệu ứng và mục tiêu rồi Nhận để áp dụng, hoặc Từ chối để giữ bài.")
		EventTableController.NPC_HANG_RONG:
			return words("Inspect a relic's effect and price, then buy one you want. Equipped relics add bonuses to your Deals.", "Xem hiệu ứng và giá di vật rồi mua món bạn muốn. Di vật đang đeo thêm thưởng cho các ván.")
		EventTableController.NPC_LOTTO:
			return words("Compare your tickets with today's draw. Winnings are already in your wallet.", "So vé với kết quả hôm nay. Thưởng đã vào ví.") if host.current_campaign_event != null and host.current_campaign_event.slot == EventManager.EventSlot.AFTERNOON else words("Choose tickets within your budget. Return this afternoon to check the draw and collect any winnings.", "Chọn vé trong khả năng ví. Quay lại chiều nay để dò số và nhận thưởng nếu trúng.")
	return words("Choose this visitor to inspect their services before spending.", "Chọn vị khách này để xem dịch vụ trước khi chi tiền.")

func _button_guidance(button: Button) -> String:
	var detail := button.tooltip_text.strip_edges()
	if detail.is_empty() or detail == button.text:
		detail = _npc_guidance(host.event_table.focused_npc_id) if host.current_campaign_event != null and not host.event_table.focused_npc_id.is_empty() else _context_copy()
	return "%s · %s" % [button.text, detail]

func start_tour() -> void:
	if not _in_game() or choice_open: return
	_clear_quick_action()
	if host.interactions.drag_payload != null: host.cancel_card_drag()
	pending_single = false
	tour.clear()
	var handbook := host.get_tree().root.get_node_or_null("GameGlossary") as GameGlossary
	var receipt := host.get_tree().root.get_node_or_null("LotteryReceipt")
	if handbook != null:
		_add_target(handbook.find_child("HandbookSearch", true, false), words("Search the current Handbook topics.", "Tìm các chủ đề trong Sổ tay."))
		_add_target(handbook.find_child("CloseHandbook", true, false), words("Return to your game here.", "Trở lại ván tại đây."))
	elif receipt != null:
		_add_buttons(receipt)
	elif _receipt_open():
		_add_buttons(host.resolve_receipt)
	elif host.zodiac_table.shade.visible:
		_add_buttons(host.zodiac_table.shade)
	elif host.get_node("ActionLegend/Shade").visible:
		_add_buttons(host.get_node("ActionLegend/Shade"))
	elif host.modal_overlay.visible:
		_add_buttons(host.modal_overlay)
	elif host.score_overlay.visible and not host.money_presentation.presentation_active:
		_add_buttons(host.score_overlay)
	elif host.pile_archive.overlay.visible:
		_add_buttons(host.pile_archive.overlay)
	elif host.deck_screen.visible:
		_add_target(host.deck_screen.find_child("DeckSearch", true, false), words("Search by rank, suit, or original card identity.", "Tìm theo số, chất hoặc lá gốc."))
		_add_target(host.deck_screen.find_child("DeckBack", true, false), words("Return to the table here.", "Về bàn tại đây."))
	elif host.current_campaign_event != null:
		if host.event_table.focused_npc_id.is_empty():
			for target: Dictionary in host.event_table.guidance_targets():
				_add_target(target.button, _npc_guidance(target.id))
				if tour.size() >= 3: break
		else:
			for button in host.event_table.participants_container.find_children("*", "Button", true, false):
				if button.is_visible_in_tree() and not button.disabled: _add_target(button, _button_guidance(button))
				if tour.size() >= 2: break
			_add_target(host.event_table.back_button, words("Return to the other visitors.", "Trở lại để gặp người khác."))
	else:
		var advice := host.deal.queries.hand_advice()
		var play: Dictionary = advice["play"]
		if play["action"] != HandAdvisor.ACTION_NONE:
			var extending: bool = play["action"] == HandAdvisor.ACTION_EXTENSION
			var labels: Array[String] = []
			for card: CardData in play["cards"]: labels.append(card.short_label())
			var instruction := words("Select %s, then HẠ to make a scoring Meld.", "Chọn %s rồi HẠ để tạo Phỏm ghi điểm.") % ", ".join(labels)
			if extending: instruction = words("Select %s and the destination Meld, then GHÉP to add these cards and score.", "Chọn %s và Phỏm muốn ghép rồi GHÉP để thêm bài và ghi điểm.") % ", ".join(labels)
			for card: CardData in play["cards"]:
				_add_target(host.card_table.hand_views.get(card.unique_id), "%s · %s" % [card.short_label(), instruction])
				if tour.size() >= 2: break
			if extending: _add_target(host.card_table.meld_views.get(play.get("meld_id", -1)), words("Choose this table Meld as the destination for the selected card, then GHÉP.", "Chọn Phỏm này làm nơi ghép lá đã chọn rồi GHÉP."))
			_add_target(host.extend_button if extending else host.ha_button, instruction)
		else:
			if host.deal.state == DealState.STATE_FINAL_COMMIT_WINDOW:
				_add_target(host.settle_button, words("Use CHỐT to settle the remaining loose cards as deadwood. Last Call gives no refill, so play any ready Melds first.", "Dùng CHỐT để tính bài rời còn lại thành điểm phạt. Chốt Hạ không bù bài, nên Hạ/Ghép bài sẵn trước."))
			elif host.deal.tra_da_extra_discard_pending and advice["extra_action"] == "skip":
				_add_target(host.settle_button, words("Skip the optional extra discard to keep these cards. Your hand then refills for the next turn.", "Bỏ qua lần bỏ thêm để giữ các lá này. Tay bài sẽ được bù cho lượt tiếp theo."))
			else:
				_add_target(host.card_table.hand_views.get(advice["discard_id"]), words("This is the suggested discard after comparing your next refill. Select it, then BỎ BÀI to end the turn.", "Đây là lá gợi ý bỏ sau khi so lần bù tiếp theo. Chọn lá rồi BỎ BÀI để kết thúc lượt."))
				_add_target(host.discard_button, words("Discard the selected loose card to end your turn. Your hand refills afterward; Trà Đá can offer one extra discard first.", "Bỏ lá rời đã chọn để kết thúc lượt. Tay bài được bù sau đó; Trà Đá có thể cho bỏ thêm một lá trước."))
	if tour.is_empty(): open_help(); return
	box.show()
	blocker.show()
	tour_index = 0
	_point()

func _add_buttons(parent: Node) -> void:
	for button in parent.find_children("*", "Button", true, false):
		if button.is_visible_in_tree() and not button.disabled: _add_target(button, _button_guidance(button))
		if tour.size() >= 3: break

func _point() -> void:
	_last_context = _context_id()
	_clear_buttons()
	var target := tour[tour_index]["control"] as Control
	_say("%d/%d · %s" % [tour_index + 1, tour.size(), tour[tour_index]["text"]])
	_button("Next" if tour_index + 1 < tour.size() else "Done", "Tiếp" if tour_index + 1 < tour.size() else "Xong", func():
		if tour_index + 1 >= tour.size(): close()
		else: tour_index += 1; _point())
	_fit_panel()
	pointer.set_targets([target] as Array[Control])
	var rect := target.get_global_rect()
	var destination := rect.get_center() - Vector2(150, 45)
	destination.x = clampf(destination.x, 8, host.get_viewport_rect().size.x - 144)
	destination.y = clampf(destination.y, 8, host.get_viewport_rect().size.y - 128)
	if travel != null: travel.kill()
	travel = create_tween()
	travel.tween_property(actor, "position", destination, 0.45).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	pose = 4 if destination.x < actor.position.x else 3
	expression = 1 if destination.x < actor.position.x else 2
	reaction_until = clock + 1.0

func _react(result: Dictionary) -> void:
	if not quick_action.is_empty(): close()
	else: _clear_quick_action()
	if result.get("action", "") in ["new_meld", "extension", "discard", "phase_settlement"]:
		_reaction(result.get("ok", false))

func _reaction(success: bool) -> void:
	expression = (expression + 3) % expressions.size() if success else 14
	pose = (pose + 1) % hats.size() if success else 6
	reaction_until = clock + 0.85
	var pop := create_tween()
	pop.tween_property(actor, "scale", Vector2(1.12, 0.9), 0.10)
	pop.tween_property(actor, "scale", Vector2.ONE, 0.22).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
