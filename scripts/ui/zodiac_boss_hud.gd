extends Control
## Boss presence and speech observe committed state; gameplay stays in Zodiac.
var host: Control
var panel: PanelContainer
var title: Label
var skill: Label
var state_label: Label
var _header_spacer: Control
var feedback: Label
var details: Label
var detail_button: Button
var opponent_cards: VBoxContainer
var details_panel: PanelContainer
var full_state: Label
var feedback_panel: PanelContainer
var promise_panel: PanelContainer
var promise_label: Label
var evening_overlay: TextureRect
var _boss_key := ""
var _phase_seen := -1
var _turn_seen := -1
var _closed_seen := false
var _locks_seen := ""
var _action_seen := ""
var _speech_time := 0.0
var _speech_duration := 0.0
var _speech_queue: Array[Dictionary] = []
var _speech_key := ""
var _speaker: Label
var _promise_details: Button
var _meld_right_offset := 0.0
var _meld_top_offset := 0.0
var dance_guide: Control
var fresh_guide: Control
var fight_fx: Control
var pair_fight_fx: Control
var _fresh_ink: ShaderMaterial
var mechanic_guide: Control
var hunt_board: Control
var hunt_fx: Control
var snake_fx: Control
var mechanic_slot: Control
var guidance: Label
const PRESENTATION_SIZE := Vector2(340, 34)
const BossView := preload("res://scripts/ui/zodiac_presentation.gd")

func _label(font_size: int) -> Label:
	var label := Label.new()
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", PresentationTheme.INK)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return label

func _glass(accent: Color, opacity: float = 0.76) -> StyleBoxFlat:
	var style := preload("res://scripts/ui/table_hud_presentation.gd").glass(accent, opacity)
	style.content_margin_left = 10
	style.content_margin_right = 10
	style.content_margin_top = 6
	style.content_margin_bottom = 6
	return style

func configure(owner: Control) -> void:
	host = owner
	_meld_right_offset = host.meld_scroll.offset_right
	_meld_top_offset = host.meld_scroll.offset_top
	name = "ZodiacBossHUD"
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	z_index = 90
	# Supplied table overlays keep their native framing; Dragon has a portrait.
	evening_overlay = TextureRect.new()
	evening_overlay.name = "EveningZodiacOverlay"
	evening_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	evening_overlay.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	evening_overlay.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	evening_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(evening_overlay)
	dance_guide = preload("res://scripts/ui/monkey_dance_guide.gd").new()
	add_child(dance_guide)
	fresh_guide = preload("res://scripts/ui/monkey_fresh_guide.gd").new()
	add_child(fresh_guide)
	mechanic_guide = preload("res://scripts/ui/zodiac_mechanic_guide.gd").new()
	add_child(mechanic_guide)
	mechanic_guide.configure(host)
	fight_fx = preload("res://scripts/ui/pig_monkey_fight_fx.gd").new()
	add_child(fight_fx)
	fight_fx.configure(host, self)
	pair_fight_fx = preload("res://scripts/ui/horse_goat_fight_fx.gd").new()
	add_child(pair_fight_fx)
	pair_fight_fx.configure(host, self)
	_fresh_ink = ShaderMaterial.new()
	_fresh_ink.shader = preload("res://shaders/monkey_rhythm_text.gdshader")
	panel = PanelContainer.new()
	panel.name = "BossPresentation"
	panel.custom_minimum_size = PRESENTATION_SIZE
	panel.size = panel.custom_minimum_size
	panel.mouse_filter = Control.MOUSE_FILTER_PASS
	add_child(panel)
	var panel_body := VBoxContainer.new()
	panel_body.add_theme_constant_override("separation", 2)
	panel.add_child(panel_body)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)
	panel_body.add_child(row)
	title = _label(14)
	title.name = "BossName"
	title.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	title.autowrap_mode = TextServer.AUTOWRAP_OFF
	title.max_lines_visible = 1
	title.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	row.add_child(title)
	skill = _label(11)
	skill.name = "BossSkill"
	skill.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	skill.max_lines_visible = 1
	skill.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	skill.add_theme_color_override("font_color", PresentationTheme.MUTED)
	row.add_child(skill)
	detail_button = Button.new()
	detail_button.name = "BossRuleDetails"
	detail_button.custom_minimum_size = Vector2(28, 22)
	PresentationTheme.configure_button(detail_button)
	detail_button.add_theme_font_size_override("font_size", 16)
	detail_button.pressed.connect(_toggle_details)
	row.add_child(detail_button)
	mechanic_slot = Control.new()
	mechanic_slot.name = "BossMechanic"
	mechanic_slot.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel_body.add_child(mechanic_slot)
	state_label = _label(16)
	state_label.name = "BossState"
	state_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	state_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	state_label.max_lines_visible = 1
	row.add_child(state_label)
	row.move_child(state_label, detail_button.get_index())
	_header_spacer = Control.new()
	_header_spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_header_spacer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(_header_spacer)
	row.move_child(_header_spacer, detail_button.get_index())
	guidance = _label(12)
	guidance.name = "BossGuidance"
	guidance.position.y = 30
	guidance.size = Vector2(420, 46)
	mechanic_slot.add_child(guidance)
	for guide: Control in [dance_guide, fresh_guide, mechanic_guide]:
		guide.reparent(mechanic_slot)
	hunt_board = preload("res://scripts/ui/rat_tiger_board.gd").new()
	mechanic_slot.add_child(hunt_board)
	hunt_board.configure(host)
	hunt_board.receipt.reparent(row)
	hunt_board.receipt.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.move_child(hunt_board.receipt, detail_button.get_index())
	row.add_child(hunt_board.expand_button)
	row.move_child(hunt_board.expand_button, detail_button.get_index())
	hunt_board.expanded_changed.connect(_layout)
	hunt_fx = preload("res://scripts/ui/rat_tiger_fight_fx.gd").new()
	add_child(hunt_fx)
	hunt_fx.configure(host, self)
	snake_fx = preload("res://scripts/ui/snake_fight_fx.gd").new()
	add_child(snake_fx)
	snake_fx.configure(host)
	details_panel = PanelContainer.new()
	details_panel.name = "ExpandedBossRule"
	details_panel.custom_minimum_size = Vector2(320, 230)
	details_panel.size = Vector2(320, 230)
	details_panel.add_theme_stylebox_override("panel", _glass(PresentationTheme.SPEAKER, 0.95))
	add_child(details_panel)
	var rule_layout := VBoxContainer.new()
	rule_layout.add_theme_constant_override("separation", 6)
	details_panel.add_child(rule_layout)
	var scroll := ScrollContainer.new()
	scroll.name = "RuleScroll"
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	rule_layout.add_child(scroll)
	var full_body := VBoxContainer.new()
	full_body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	full_body.add_theme_constant_override("separation", 10)
	scroll.add_child(full_body)
	full_state = _label(14)
	full_state.name = "CompleteBossState"
	full_body.add_child(full_state)
	details = _label(14)
	details.name = "BossRuleDescription"
	full_body.add_child(details)
	opponent_cards = VBoxContainer.new()
	opponent_cards.name = "RatOwnedMelds"
	full_body.add_child(opponent_cards)
	var close := Button.new()
	close.name = "CloseBossRule"
	close.custom_minimum_size.y = 32
	close.pressed.connect(_toggle_details)
	PresentationTheme.configure_button(close)
	rule_layout.add_child(close)
	details_panel.hide()
	details.hide()
	feedback_panel = PanelContainer.new()
	feedback_panel.name = "BossSpeech"
	feedback_panel.custom_minimum_size = Vector2(316, 90)
	feedback_panel.size = feedback_panel.custom_minimum_size
	feedback_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(feedback_panel)
	var speech_body := VBoxContainer.new()
	speech_body.mouse_filter = Control.MOUSE_FILTER_IGNORE
	speech_body.add_theme_constant_override("separation", 2)
	feedback_panel.add_child(speech_body)
	_speaker = _label(12)
	speech_body.add_child(_speaker)
	feedback = _label(16)
	feedback.name = "BossFeedback"
	feedback.set_meta("manual_text_reveal", true)
	speech_body.add_child(feedback)
	feedback_panel.hide()
	promise_panel = PanelContainer.new()
	promise_panel.name = "ZodiacPromiseReminder"
	promise_panel.custom_minimum_size = Vector2(220, 52)
	promise_panel.size = promise_panel.custom_minimum_size
	promise_panel.mouse_filter = Control.MOUSE_FILTER_PASS
	promise_panel.add_theme_stylebox_override("panel", _glass(PresentationTheme.GOLD_DARK))
	add_child(promise_panel)
	var promise_row := HBoxContainer.new()
	promise_row.add_theme_constant_override("separation", 6)
	promise_panel.add_child(promise_row)
	promise_label = _label(12)
	promise_label.name = "PromiseTerms"
	promise_label.custom_minimum_size.x = 156
	promise_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	promise_label.max_lines_visible = 2
	promise_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	promise_row.add_child(promise_label)
	_promise_details = Button.new()
	_promise_details.custom_minimum_size = Vector2(28, 30)
	_promise_details.pressed.connect(_toggle_details)
	PresentationTheme.configure_button(_promise_details)
	_promise_details.add_theme_font_size_override("font_size", 16)
	promise_row.add_child(_promise_details)
	promise_panel.hide()
	host.campaign.zodiac.changed.connect(refresh)
	host.campaign.campaign_phase_changed.connect(func(_phase: int): refresh.call_deferred())
	refresh()

func _available() -> bool:
	return host != null and host.game_started and not host.menu_layer.visible and host.current_campaign_event == null and CampaignManager.DEAL_PHASE_TO_PERIOD.has(host.campaign.current_phase) and (not host.deal.zodiac_boss.id.is_empty() or not host.campaign.zodiac.promise_reminder().is_empty())

func _blocked() -> bool:
	return _presence_blocked() or host.score_overlay.visible

func _presence_blocked() -> bool:
	# Money's ceremony is a transparent, input-free part of the table.
	# Keep the opponent present while cards score; dialogs still clear the art.
	return host.get_tree().root.has_node("GameGlossary") or host.modal_overlay.visible or host.pile_archive.overlay.visible or (is_instance_valid(host.deck_screen) and host.deck_screen.visible) or (is_instance_valid(host.resolve_receipt) and host.resolve_receipt.visible)

func _process(delta: float) -> void:
	if host == null: return
	if visible != _available(): refresh()
	if not visible: return
	_layout()
	var blocked := _blocked()
	dance_guide.visible = panel.visible and host.deal.zodiac_boss.id == "monkey" and not host.deal.zodiac_boss.data.get("sequence", []).is_empty() and not blocked and not details_panel.visible
	dance_guide.pause_effects(host.score_overlay.visible)
	fresh_guide.visible = panel.visible and fresh_guide.active and not blocked and not details_panel.visible
	fresh_guide.pause_effects(host.score_overlay.visible)
	mechanic_guide.visible = mechanic_guide.active and not blocked and not details_panel.visible
	mechanic_guide.pause_effects(host.score_overlay.visible)
	fight_fx.visible = panel.visible and host.deal.zodiac_boss.id in ["pig", "monkey"] and not blocked and not details_panel.visible
	fight_fx.pause_effects(host.score_overlay.visible)
	pair_fight_fx.visible = panel.visible and host.deal.zodiac_boss.id in ["horse", "goat"] and not blocked and not details_panel.visible
	pair_fight_fx.pause_effects(host.score_overlay.visible)
	hunt_fx.visible = panel.visible and host.deal.zodiac_boss.id in ["rat", "tiger"] and not blocked and not details_panel.visible
	hunt_fx.pause_effects(host.score_overlay.visible)
	snake_fx.visible = panel.visible and host.deal.zodiac_boss.id == "snake" and not blocked and not details_panel.visible
	snake_fx.pause_effects(host.score_overlay.visible)
	hunt_board.visible = panel.visible and host.deal.zodiac_boss.id in ["rat", "tiger"] and not blocked and not details_panel.visible
	hunt_board.pause_effects(blocked)
	evening_overlay.visible = panel.visible and not _presence_blocked() and evening_overlay.texture != null
	if blocked:
		if _presence_blocked():
			dance_guide.clear_effects()
			fresh_guide.clear_effects()
			fight_fx.clear_effects()
			pair_fight_fx.clear_effects()
			hunt_fx.clear_effects()
			snake_fx.clear_effects()
			mechanic_guide.clear_pair_effects()
		_close_details()
		feedback_panel.hide()
		_speech_queue.clear()
		_speech_time = 0
		return
	if _speech_time > 0:
		_speech_time = maxf(0, _speech_time - delta)
		var elapsed := _speech_duration - _speech_time
		var pop := clampf(elapsed / 0.2, 0, 1)
		feedback_panel.scale = Vector2.ONE * lerpf(0.9, 1.0, 1.0 - pow(1.0 - pop, 3.0))
		feedback_panel.modulate.a = minf(pop, clampf(_speech_time / 0.3, 0, 1))
		if _speech_time <= 0: feedback_panel.hide()
	elif not _speech_queue.is_empty():
		_start_speech(_speech_queue.pop_front())

func _input(event: InputEvent) -> void:
	if visible and hunt_board.expanded and not _presence_blocked() and event.is_action_pressed("ui_cancel"):
		hunt_board.set_expanded(false)
		hunt_board.expand_button.grab_focus()
		get_viewport().set_input_as_handled()
		return
	if visible and details_panel.visible and event.is_action_pressed("ui_cancel"):
		_close_details()
		(_promise_details if promise_panel.visible else detail_button).grab_focus()
		get_viewport().set_input_as_handled()

func _toggle_details() -> void:
	_close_details()
	feedback_panel.hide()
	_speech_queue.clear()
	_speech_time = 0
	var id: String = host.deal.zodiac_boss.id
	var heading := ZodiacCatalog.display_name(id) if not id.is_empty() else ZodiacCatalog.words("Promises", "Cam kết")
	var copy: String = full_state.get_meta("semantic_source_text", full_state.text) + "\n\n" + details.get_meta("semantic_source_text", details.text)
	for meld: MeldState in host.deal.boss_melds:
		var cards: Array[String] = []
		for card in meld.cards: cards.append(card.short_label())
		copy += "\n\n#%d · %s" % [meld.meld_id, " · ".join(cards)]
	GameGlossary.open_entry(host, heading, copy, "zodiac")

func _close_details() -> void:
	details_panel.hide()
	details.hide()

func _layout() -> void:
	var day_hud: Control = host.get_node("GameLayer/Header/HeaderRow/CampaignStat")
	panel.position = day_hud.global_position - global_position + Vector2(0, day_hud.size.y + 8)
	var id: String = host.deal.zodiac_boss.id
	var panel_width := 340.0
	if id == "rat": panel_width = 320
	elif id == "monkey": panel_width = 400 if dance_guide.visible else 300
	elif id in ["pig", "horse", "goat"]: panel_width = 350
	elif id == "snake": panel_width = 390
	elif id == "dragon": panel_width = 400
	var body_width := panel_width - 20
	for guide: Control in [mechanic_guide, dance_guide, fresh_guide]:
		guide.position = Vector2.ZERO
		guide.fit_width(body_width)
	var body_height := 0.0
	if mechanic_guide.active: body_height = mechanic_guide.lane_height
	elif fresh_guide.active: body_height = fresh_guide.lane_height
	elif not host.deal.zodiac_boss.data.get("sequence", []).is_empty() and id == "monkey": body_height = dance_guide.lane_height
	mechanic_slot.custom_minimum_size.y = body_height
	panel.custom_minimum_size = Vector2(panel_width, 34 + body_height)
	panel.size = panel.custom_minimum_size
	hunt_board.position = Vector2.ZERO
	hunt_board.size = Vector2.ZERO
	if host.deal.zodiac_boss.id == "dragon":
		# A portrait cannot safely use the full-table overlay's covered stretch.
		var relics: Control = host.get_node("GameLayer/UtilityRail/RelicsArea")
		evening_overlay.position = Vector2(host.size.x - 154, relics.get_global_rect().end.y + 16) - global_position
		evening_overlay.size = Vector2(128, 160)
	promise_panel.position = panel.position
	promise_panel.size = Vector2(220, 52)
	var money: Control = host.campaign_money_hud.panel
	var money_rect := money.get_global_rect()
	var width := clampf(money_rect.size.x, 316, 390)
	feedback_panel.position = Vector2(clampf(money_rect.end.x - width - global_position.x, 8, host.size.x - width - 8), money_rect.end.y - global_position.y + 12)
	# Reserve the speech lane so scrolled Meld cards never sit underneath it.
	var meld_parent: Control = host.meld_scroll.get_parent()
	host.meld_scroll.offset_right = minf(_meld_right_offset, feedback_panel.global_position.x - 8 - meld_parent.global_position.x - meld_parent.size.x) if panel.visible else _meld_right_offset
	# The optional Rat overview expands beside the compact header; actual melds
	# remain selectable on the normal table, with the same extension controls.
	var drawer_left := panel.get_global_rect().end.x + 12
	hunt_board.fit_drawer(Rect2(Vector2(drawer_left, panel.global_position.y), Vector2(maxf(260, money_rect.position.x - drawer_left - 14), 106)))
	var occupied_bottom := maxf(panel.get_global_rect().end.y, hunt_board.drawer.get_global_rect().end.y if hunt_board.expanded else 0)
	host.meld_scroll.offset_top = maxf(_meld_top_offset, occupied_bottom + 8 - meld_parent.global_position.y) if panel.visible else _meld_top_offset
	var available_height: float = host.discard_pile_visual.global_position.y - feedback_panel.global_position.y - 12
	var pixels := 16
	while pixels > 12 and feedback.get_theme_font("font").get_multiline_string_size(feedback.text, HORIZONTAL_ALIGNMENT_LEFT, width - 20, pixels).y + 30 > available_height:
		pixels -= 1
	feedback.add_theme_font_size_override("font_size", pixels)
	feedback_panel.size = Vector2(width, maxf(90, feedback_panel.get_combined_minimum_size().y))
	feedback_panel.pivot_offset = Vector2(width, 0)
	details_panel.position = panel.position + Vector2(0, 54)
	details_panel.size = Vector2(320, minf(270, host.hand_layer.get_parent().position.y - details_panel.position.y - 16))

func refresh() -> void:
	if host == null: return
	visible = _available()
	if not visible:
		host.meld_scroll.offset_right = _meld_right_offset
		host.meld_scroll.offset_top = _meld_top_offset
		dance_guide.sync({}, "")
		fresh_guide.sync({}, "")
		fight_fx.sync({}, "")
		pair_fight_fx.sync({}, "")
		hunt_fx.sync({}, "")
		snake_fx.sync({}, "")
		hunt_board.sync({})
		mechanic_guide.sync({})
		_close_details()
		feedback_panel.hide()
		_speech_queue.clear()
		_speech_time = 0
		return
	var reminder: String = host.campaign.zodiac.promise_reminder()
	promise_panel.visible = not reminder.is_empty()
	panel.visible = not host.deal.zodiac_boss.id.is_empty()
	if promise_panel.visible:
		promise_label.text = ZodiacCatalog.words("PROMISE · ", "CAM KẾT · ") + ZodiacCatalog.display_name(host.campaign.zodiac.active_id())
		for promise: Dictionary in host.campaign.zodiac.daily.get("promises", []):
			if promise.get("engine", "") != "persuasion" or promise.get("outcome_applied", false): continue
			if promise.accepted_terms.get("interaction", "") in ["deal_action", "card_play", "wallet_floor"]:
				promise_label.text = ZodiacCatalog.display_name(host.campaign.zodiac.active_id()) + " · " + (ZodiacCatalog.words("Done", "Đã làm") if promise.get("matched", false) else ZodiacCatalog.words("Missed", "Quá hạn") if promise.broken else ZodiacCatalog.words("Pending", "Chưa làm"))
			if promise.accepted_terms.get("interaction", "") == "wallet_floor" and promise.broken: promise_label.text = ZodiacCatalog.display_name(host.campaign.zodiac.active_id()) + " · " + ZodiacCatalog.words("Broken", "Thất hứa")
			promise_label.text += "\n" + QuickInfo.promise_status(promise, host.campaign.gieo_que.persistent_deck)
			break
		promise_panel.tooltip_text = ZodiacCatalog.words("Handbook", "Sổ tay")
		promise_panel.visible = not panel.visible
	if not panel.visible:
		dance_guide.sync({}, "")
		fresh_guide.sync({}, "")
		fight_fx.sync({}, "")
		pair_fight_fx.sync({}, "")
		hunt_fx.sync({}, "")
		snake_fx.sync({}, "")
		hunt_board.sync({})
		mechanic_guide.sync({})
		evening_overlay.hide()
		full_state.text = ZodiacCatalog.words("PROMISE · ", "CAM KẾT · ") + ZodiacCatalog.display_name(host.campaign.zodiac.active_id())
		details.text = reminder
		_promise_details.text = "×" if details_panel.visible else "?"
		_promise_details.tooltip_text = ZodiacCatalog.words("Handbook", "Sổ tay")
		(details_panel.find_child("CloseBossRule", true, false) as Button).text = ZodiacCatalog.words("Back to the table · Esc", "Về bàn · Esc")
		if not promise_panel.visible: _close_details()
		_layout()
		return
	var state: Dictionary = host.deal.zodiac_boss.presentation()
	var key := "%s:%d:%s:%d:%s" % [host.campaign.run_seed, host.campaign.current_day_index, state.id, state.difficulty, TranslationServer.get_locale()]
	var accent: Color = BossView.accent(state.id)
	if key != _boss_key:
		_boss_key = key
		hunt_board.set_expanded(false)
		_phase_seen = -1
		_turn_seen = -1
		_closed_seen = false
		_locks_seen = ""
		_action_seen = ""
		_speech_key = ""
		_speech_queue.clear()
		_speech_time = 0
		feedback_panel.hide()
		_close_details()
		var overlay_path := ZodiacCatalog.sprite_path(state.id, true)
		evening_overlay.texture = load(overlay_path) if ResourceLoader.exists(overlay_path) else null
		evening_overlay.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT if state.id == "dragon" else Control.PRESET_FULL_RECT)
		evening_overlay.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED if state.id == "dragon" else TextureRect.STRETCH_KEEP_ASPECT_COVERED
		# Live counters show the requirement; arrival explanations live in the Handbook.
	var panel_style := _glass(accent, 0.68)
	panel_style.content_margin_top = 3
	panel_style.content_margin_bottom = 3
	panel.add_theme_stylebox_override("panel", panel_style)
	feedback_panel.add_theme_stylebox_override("panel", _glass(accent, 0.84))
	title.add_theme_color_override("font_color", accent)
	_speaker.add_theme_color_override("font_color", accent)
	title.text = ZodiacCatalog.display_name(state.id)
	title.custom_minimum_size.x = ceilf(title.get_theme_font("font").get_string_size(title.text, HORIZONTAL_ALIGNMENT_LEFT, -1, title.get_theme_font_size("font_size")).x)
	title.set_meta("zodiac_id", String(state.id))
	_speaker.set_meta("zodiac_id", String(state.id))
	_speaker.text = ZodiacCatalog.display_name(state.id)
	skill.hide()
	full_state.text = state.skill + "\n" + ZodiacCatalog.state_text(state, host.deal)
	if state.id == "dragon": full_state.text += "\n" + ZodiacCatalog.modifier_text(state, host.deal)
	state_label.text = BossView.compact(state, host.deal)
	state_label.tooltip_text = ZodiacCatalog.words("Handbook", "Sổ tay")
	state_label.material = null
	state_label.add_theme_font_size_override("font_size", 13)
	state_label.add_theme_color_override("font_color", PresentationTheme.INK)
	dance_guide.sync(state, key + ":%d" % host.deal.current_phase)
	fresh_guide.sync(state, key + ":%d" % host.deal.current_phase)
	mechanic_guide.sync(state, key)
	fight_fx.sync(state, key + (":%d" % host.deal.current_phase if state.id == "monkey" else ""))
	pair_fight_fx.sync(state, key + ":%d" % host.deal.current_phase)
	hunt_board.sync(state)
	hunt_fx.sync(state, key + ":%d" % host.deal.current_phase)
	snake_fx.sync(state, key + ":%d" % host.deal.current_phase)
	var guided: bool = mechanic_guide.active or fresh_guide.active or dance_guide.visible or hunt_board.visible
	state_label.visible = not guided or state.id == "snake"
	_header_spacer.visible = not state_label.visible and not hunt_board.receipt.visible
	guidance.hide()
	guidance.text = ""
	if state.id == "monkey":
		if state.sequence.is_empty():
			var cap := int(ZodiacCatalog.tuning("monkey", "allowed_repeats", state.difficulty))
			var count := int(state.repeat_count)
			var action_name := ZodiacCatalog.action_label(state.last_paid_action) if not String(state.last_paid_action).is_empty() else "—"
			state_label.text = "FRESH! · %s %d/%d" % [action_name, count, cap]
			state_label.add_theme_font_size_override("font_size", 12)
			state_label.add_theme_color_override("font_color", Color("ffb878") if count >= cap else accent)
			_fresh_ink.set_shader_parameter("urgency", 1.0 if count >= cap else 0.0)
			state_label.material = _fresh_ink
			state_label.tooltip_text = ZodiacCatalog.words("Handbook", "Sổ tay")
		else:
			state_label.text = ZodiacCatalog.words("DANCE BABY! · %d/%d", "DANCE BABY! · %d/%d") % [int(state.sequence_index) + 1, state.sequence.size()]
	else: state_label.tooltip_text = ZodiacCatalog.words("Handbook", "Sổ tay")
	if state.id == "rooster" and host.deal.current_phase == 1 and not state.register_closed:
		var remaining: int = maxi(int(ZodiacCatalog.tuning("rooster", "discard_deadline", state.difficulty)) - host.deal.discard_count, 0)
		state_label.text = ZodiacCatalog.words("Closes in %d", "Đóng sổ sau %d") % remaining
	# Keep the current requirement readable at the shared presentation width.
	var badge_pixels := state_label.get_theme_font_size("font_size")
	while badge_pixels > 12 and state_label.get_theme_font("font").get_string_size(state_label.text, HORIZONTAL_ALIGNMENT_LEFT, -1, badge_pixels).x > PRESENTATION_SIZE.x - 20:
		badge_pixels -= 1
	state_label.add_theme_font_size_override("font_size", badge_pixels)
	panel.tooltip_text = ZodiacCatalog.display_name(state.id) + "\n" + state_label.text
	details.text = state.rule
	detail_button.text = "×" if details_panel.visible else "?"
	detail_button.tooltip_text = ZodiacCatalog.words("Handbook", "Sổ tay")
	(details_panel.find_child("CloseBossRule", true, false) as Button).text = ZodiacCatalog.words("Back to the table · Esc", "Về bàn · Esc")
	_sync_opponent_cards()
	_layout()
	evening_overlay.visible = not _presence_blocked() and evening_overlay.texture != null

func _sync_opponent_cards() -> void:
	for child in opponent_cards.get_children():
		opponent_cards.remove_child(child)
		child.queue_free()
	opponent_cards.visible = not host.deal.boss_melds.is_empty()
	for meld: MeldState in host.deal.boss_melds:
		var group := VBoxContainer.new()
		opponent_cards.add_child(group)
		var caption := _label(11)
		caption.text = ZodiacCatalog.words("RAT #%d", "PHỎM TÝ #%d") % meld.meld_id
		group.add_child(caption)
		var faces := GridContainer.new()
		faces.name = "StolenCardFaces"
		faces.columns = 7
		faces.add_theme_constant_override("h_separation", 4)
		faces.add_theme_constant_override("v_separation", 4)
		group.add_child(faces)
		for card in meld.cards:
			var face := TextureRect.new()
			face.texture = load(card.texture_path())
			face.custom_minimum_size = Vector2(36, 50)
			face.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			face.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			face.tooltip_text = card.short_label()
			faces.add_child(face)
			var stitch := ColorRect.new()
			stitch.name = "RatStolenMeld"
			stitch.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
			stitch.mouse_filter = Control.MOUSE_FILTER_IGNORE
			var ink := ShaderMaterial.new()
			ink.shader = preload("res://shaders/rat_stolen_meld.gdshader")
			stitch.material = ink
			face.add_child(stitch)

func _queue_speech(line: String, key: String, urgent: bool = false) -> void:
	if line.is_empty() or key == _speech_key or not visible or _blocked() or details_panel.visible: return
	for item in _speech_queue:
		if item.key == key: return
	var item := {"line": line, "key": key}
	if urgent:
		_speech_queue.clear()
		_start_speech(item)
	elif _speech_time <= 0:
		_start_speech(item)
	else:
		if _speech_queue.size() >= 2: _speech_queue.pop_front()
		_speech_queue.append(item)

func _start_speech(item: Dictionary) -> void:
	_speech_key = item.key
	feedback.text = "“" + String(item.line) + "”"
	feedback_panel.tooltip_text = item.line
	# Pop first, then type; keep a complete paragraph on screen before fading.
	TextReveal.reveal(feedback, 0.2)
	_speech_duration = 0.2 + TextReveal.duration(feedback) + clampf(String(item.line).length() * 0.035, 3.0, 7.0)
	_speech_time = _speech_duration
	feedback_panel.modulate.a = 0
	feedback_panel.scale = Vector2.ONE * 0.9
	feedback_panel.show()

func present_action(result: Dictionary) -> void:
	if not visible or not panel.visible: return
	dance_guide.present_action(result)
	fresh_guide.present_action(result)
	fight_fx.present_action(result)
	pair_fight_fx.present_action(result)
	var rule: ZodiacBossRule = host.deal.zodiac_boss
	var phase: int = host.deal.current_phase
	var locks := ",".join(rule.locked_ids)
	if rule.id == "rooster":
		if rule.register_closed and not _closed_seen:
			_queue_speech(ZodiacCatalog.words("Ledger shut. Legal plays pay 0 VNĐ.", "Khép sổ. Nước hợp lệ trả 0 VNĐ."), "closed:%d" % phase, true)
		elif phase == 2 and _phase_seen != 2:
			_queue_speech(ZodiacCatalog.words("Phase 2. Extensions only.", "Hiệp 2. Chỉ nối Phỏm thôi.") if rule.difficulty == ZodiacCatalog.UNPLEASED else ZodiacCatalog.words("Fresh page. Show me what you've got.", "Trang mới. Cho tôi xem bạn làm được gì."), "phase2", true)
	elif rule.id == "cat" and phase == 2 and (locks != _locks_seen or rule.turn_serial != _turn_seen):
		_queue_speech(ZodiacCatalog.words("These %d stay with me until the next turn.", "%d lá này ở với tôi đến Lượt sau.") % rule.locked_ids.size() if not locks.is_empty() else ZodiacCatalog.words("Nothing to keep this turn. Lucky you.", "Lượt này chẳng có gì để giữ. Bạn may đấy."), "locks:%d:%s" % [rule.turn_serial, locks], true)
	_closed_seen = rule.register_closed
	_locks_seen = locks
	_phase_seen = phase
	_turn_seen = rule.turn_serial
	var action: String = result.get("action", "")
	var context := result.get("context") as ScoringContext
	var action_key := "%s:%d:%d:%d" % [action, phase, rule.turn_serial, context.get_instance_id() if context != null else 0]
	if action.is_empty() or action_key == _action_seen: return
	_action_seen = action_key
	if context != null and not context.suppression_reason.is_empty():
		present_suppression(context)
	elif rule.id == "rooster" and action == "discard" and not rule.register_closed and phase == 1:
		var left: int = int(ZodiacCatalog.tuning("rooster", "discard_deadline", rule.difficulty)) - host.deal.discard_count
		if left == 1: _queue_speech(ZodiacCatalog.words("One discard left. Mind the clock.", "Còn một lần bỏ. Để ý đồng hồ nhé."), "last-discard", true)
	elif context != null and int(result.get("earned_vnd", 0)) > 0:
		if rule.id == "cat": _queue_speech(ZodiacCatalog.words("Mm. You meant that one.", "Ừm. Nước ấy có chủ đích đấy."), "paid:" + action_key)
		elif rule.id == "rooster": _queue_speech(ZodiacCatalog.words("Entered. I do notice the good work.", "Đã ghi. Việc tốt tôi có thấy đấy."), "paid:" + action_key)
		elif rule.id == "dog" and int(result.get("meld_id", -1)) == int(rule.data.loyal_meld_id):
			_queue_speech(ZodiacCatalog.words("Our first Meld. I'll stand by it.", "Phỏm đầu của mình. Tôi theo đến cùng."), "paid:" + action_key)
		elif rule.id == "monkey" and rule.difficulty != ZodiacCatalog.UNPLEASED:
			if int(rule.data.repeat_count) >= int(ZodiacCatalog.tuning("monkey", "allowed_repeats", rule.difficulty)):
				_queue_speech(ZodiacCatalog.words("Ha! Now surprise me with ", "Ha! Giờ gây bất ngờ bằng ") + ZodiacCatalog.action_label("extension" if action == "new_meld" else "new_meld") + ".", "fresh:" + action_key, true)
		elif rule.id == "monkey":
			_queue_speech(ZodiacCatalog.words("There you go! Next: ", "Đúng rồi! Tiếp: ") + ZodiacCatalog.action_label(String(rule.presentation().required_action)) + ".", "dance:" + action_key, true)

func react_locked_card(card: CardData) -> void:
	if host.deal.zodiac_boss.is_locked(card):
		_queue_speech(ZodiacCatalog.words("This one's comfortable here. Until next turn.", "Lá này ở đây thoải mái rồi. Đến Lượt sau nhé."), "touch-lock:%d:%s" % [host.deal.zodiac_boss.turn_serial, card.unique_id], true)

func present_suppression(context: ScoringContext) -> void:
	_queue_speech(ZodiacCatalog.feedback(context.suppression_reason) + ZodiacCatalog.words(" · this play pays 0 VNĐ.", " · lần đánh này trả 0 VNĐ."), "payout:%d" % context.get_instance_id(), true)

func present_events(events: Array) -> void:
	fight_fx.present_events(events, _boss_key + _action_seen)
	hunt_fx.present_events(events, _boss_key + ":%d:%d" % [host.deal.current_phase, host.deal.zodiac_boss.turn_serial])
	snake_fx.present_events(events, _boss_key + ":%d:%d" % [host.deal.current_phase, host.deal.zodiac_boss.turn_serial])
	for event: Dictionary in events:
		var action: String = event.get("action", "")
		if action == "boss_discard" and event.get("source", "") == "tiger" and hunt_fx.hand_staging: continue
		var line := ""
		match action:
			"boss_discard":
				if event.get("source", "") not in ["snake", "snake_charm"]: line = ZodiacCatalog.words("Snatched: ", "Ta lấy lá ") + String(event.get("label", ""))
			"boss_meld", "boss_extension": line = ZodiacCatalog.words("Found a use for it. That costs you ", "Tìm được cách dùng rồi. Bạn mất ") + VndWallet.format_vnd(absi(int(event.get("amount_vnd", 0))))
			"pig_siphon": line = ZodiacCatalog.words("A little set aside: ", "Để dành một ít: ") + VndWallet.format_vnd(int(event.amount_vnd))
			"pig_return": line = ZodiacCatalog.words("Target met! Every coin in the pool comes back.", "Đủ mục tiêu! Cả quỹ trả lại nhé.")
			"pig_bank_loss": line = ZodiacCatalog.words("Short of the target. The bill still stands.", "Chưa đủ mục tiêu. Hóa đơn vẫn còn.")
			"snake_disobeyed": line = ZodiacCatalog.words("A different tune. Your turn continues.", "Giai điệu khác rồi. Lượt bạn vẫn tiếp.")
			"snake_obeyed": line = ZodiacCatalog.words("Exactly the note. Your turn continues.", "Đúng nốt ấy. Lượt bạn vẫn tiếp.")
			"horse_grace": line = ZodiacCatalog.words("I'll wait this once. No grace left this Phase.", "Tôi chờ lần này. Hiệp này hết lượt nương tay.")
			"dragon_modifier": line = ZodiacCatalog.words("This turn: ", "Lượt này: ") + ZodiacCatalog.display_name(event.get("id", ""))
			"horse_forced_discard": line = ZodiacCatalog.words("You lost the stride. I'll choose the discard.", "Bạn lỡ nhịp rồi. Tôi chọn lá bỏ.")
		if not line.is_empty(): _queue_speech(line, "%s:%d:%d" % [action, host.deal.current_phase, host.deal.zodiac_boss.turn_serial], true)
