extends Control
## Boss presence and speech observe committed state; gameplay stays in Zodiac.
var host: Control
var panel: PanelContainer
var title: Label
var skill: Label
var state_label: Label
var feedback: Label
var details: Label
var detail_button: Button
var opponent_cards: HBoxContainer
var details_panel: PanelContainer
var full_state: Label
var feedback_panel: PanelContainer
var promise_panel: PanelContainer
var promise_label: Label
var portrait: TextureRect
var evening_overlay: TextureRect
var _boss_key := ""
var _phase_seen := -1
var _turn_seen := -1
var _closed_seen := false
var _locks_seen := ""
var _action_seen := ""
var _clock := 0.0
var _reaction := 0.0
var _speech_time := 0.0
var _speech_duration := 0.0
var _speech_queue: Array[Dictionary] = []
var _speech_key := ""
var _speaker: Label
var _promise_details: Button

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
	name = "ZodiacBossHUD"
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	z_index = 90
	# The supplied table overlay remains in its native framing during Evening.
	evening_overlay = TextureRect.new()
	evening_overlay.name = "EveningZodiacOverlay"
	evening_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	evening_overlay.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	evening_overlay.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	evening_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(evening_overlay)
	portrait = TextureRect.new()
	portrait.name = "EveningBossPortrait"
	portrait.size = Vector2(138, 138)
	portrait.pivot_offset = portrait.size * 0.5
	portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var spirit := ShaderMaterial.new()
	spirit.shader = preload("res://shaders/zodiac_spirit.gdshader")
	portrait.material = spirit
	add_child(portrait)
	panel = PanelContainer.new()
	panel.name = "BossRuleCard"
	panel.custom_minimum_size = Vector2(220, 48)
	panel.size = panel.custom_minimum_size
	panel.mouse_filter = Control.MOUSE_FILTER_PASS
	add_child(panel)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)
	panel.add_child(row)
	var body := VBoxContainer.new()
	body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.add_theme_constant_override("separation", 2)
	row.add_child(body)
	title = _label(12)
	title.name = "BossName"
	title.max_lines_visible = 1
	title.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	body.add_child(title)
	state_label = _label(13)
	state_label.name = "BossState"
	state_label.max_lines_visible = 1
	state_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	body.add_child(state_label)
	# Skill remains available to inspection and in the expanded rule.
	skill = _label(15)
	skill.name = "BossSkill"
	body.add_child(skill)
	skill.hide()
	detail_button = Button.new()
	detail_button.name = "BossRuleDetails"
	detail_button.custom_minimum_size = Vector2(28, 30)
	PresentationTheme.configure_button(detail_button)
	detail_button.add_theme_font_size_override("font_size", 16)
	detail_button.pressed.connect(_toggle_details)
	row.add_child(detail_button)
	details_panel = PanelContainer.new()
	details_panel.name = "ExpandedBossRule"
	details_panel.custom_minimum_size = Vector2(320, 230)
	details_panel.size = Vector2(320, 230)
	details_panel.add_theme_stylebox_override("panel", _glass(PresentationTheme.SPEAKER, 0.95))
	add_child(details_panel)
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	details_panel.add_child(scroll)
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
	opponent_cards = HBoxContainer.new()
	opponent_cards.name = "MouseOwnedMelds"
	full_body.add_child(opponent_cards)
	var close := Button.new()
	close.name = "CloseBossRule"
	close.custom_minimum_size.y = 32
	close.pressed.connect(_toggle_details)
	PresentationTheme.configure_button(close)
	full_body.add_child(close)
	details_panel.hide()
	details.hide()
	feedback_panel = PanelContainer.new()
	feedback_panel.name = "BossSpeech"
	feedback_panel.custom_minimum_size = Vector2(278, 62)
	feedback_panel.size = feedback_panel.custom_minimum_size
	feedback_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(feedback_panel)
	var speech_body := VBoxContainer.new()
	speech_body.mouse_filter = Control.MOUSE_FILTER_IGNORE
	speech_body.add_theme_constant_override("separation", 2)
	feedback_panel.add_child(speech_body)
	_speaker = _label(10)
	speech_body.add_child(_speaker)
	feedback = _label(14)
	feedback.name = "BossFeedback"
	feedback.max_lines_visible = 2
	feedback.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
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
	return host != null and host.game_started and not host.tutorial_active and not host.menu_layer.visible and host.current_campaign_event == null and CampaignManager.DEAL_PHASE_TO_PERIOD.has(host.campaign.current_phase) and (not host.deal.zodiac_boss.id.is_empty() or not host.campaign.zodiac.promise_reminder().is_empty())

func _blocked() -> bool:
	return host.modal_overlay.visible or host.score_overlay.visible or host.discard_archive_overlay.visible or (is_instance_valid(host.deck_screen) and host.deck_screen.visible) or (is_instance_valid(host.resolve_receipt) and host.resolve_receipt.visible)

func _process(delta: float) -> void:
	if host == null: return
	if visible != _available(): refresh()
	if not visible: return
	_layout()
	var blocked := _blocked()
	portrait.visible = panel.visible and not blocked
	evening_overlay.visible = portrait.visible and evening_overlay.texture != null
	if blocked:
		_close_details()
		feedback_panel.hide()
		_speech_queue.clear()
		_speech_time = 0
		return
	_clock += delta
	_reaction = maxf(_reaction - delta * 2.0, 0.0)
	portrait.rotation = sin(_clock * 0.9) * 0.012
	portrait.scale = Vector2.ONE * (1.0 + sin(_clock * 1.2) * 0.012 + _reaction * 0.035)
	if _speech_time > 0:
		_speech_time = maxf(0, _speech_time - delta)
		var elapsed := _speech_duration - _speech_time
		feedback_panel.modulate.a = minf(clampf(elapsed / 0.16, 0, 1), clampf(_speech_time / 0.3, 0, 1))
		if _speech_time <= 0: feedback_panel.hide()
	elif not _speech_queue.is_empty():
		_start_speech(_speech_queue.pop_front())

func _input(event: InputEvent) -> void:
	if visible and details_panel.visible and event.is_action_pressed("ui_cancel"):
		_close_details()
		(_promise_details if promise_panel.visible else detail_button).grab_focus()
		get_viewport().set_input_as_handled()

func _toggle_details() -> void:
	if details_panel.visible:
		_close_details()
	else:
		details_panel.show()
		details.show()
		feedback_panel.hide()
		_speech_queue.clear()
		_speech_time = 0
	refresh()

func _close_details() -> void:
	details_panel.hide()
	details.hide()

func _layout() -> void:
	var day_hud: Control = host.get_node("GameLayer/Header/HeaderRow/CampaignStat")
	panel.position = day_hud.global_position - global_position + Vector2(0, day_hud.size.y + 8)
	panel.size = Vector2(220, 48)
	promise_panel.position = panel.position
	promise_panel.size = Vector2(220, 52)
	portrait.position = Vector2(8, panel.position.y + 50)
	feedback_panel.position = Vector2(150, panel.position.y + 50)
	feedback_panel.size = Vector2(278, 62)
	details_panel.position = panel.position + Vector2(0, 54)
	details_panel.size = Vector2(320, minf(270, host.hand_layer.get_parent().position.y - details_panel.position.y - 16))

func refresh() -> void:
	if host == null: return
	visible = _available()
	if not visible:
		_close_details()
		feedback_panel.hide()
		_speech_queue.clear()
		_speech_time = 0
		return
	var reminder: String = host.campaign.zodiac.promise_reminder()
	promise_panel.visible = not reminder.is_empty()
	panel.visible = not host.deal.zodiac_boss.id.is_empty()
	if promise_panel.visible:
		promise_label.text = ZodiacCatalog.words("PROMISE · ", "CAM KẾT · ") + ZodiacCatalog.display_name(host.campaign.zodiac.active_id()) + "\n" + reminder
		promise_panel.tooltip_text = promise_label.text
		promise_panel.visible = not panel.visible
	if not panel.visible:
		portrait.hide()
		evening_overlay.hide()
		full_state.text = ZodiacCatalog.words("PROMISE · ", "CAM KẾT · ") + ZodiacCatalog.display_name(host.campaign.zodiac.active_id())
		details.text = reminder
		_promise_details.text = "×" if details_panel.visible else "?"
		_promise_details.tooltip_text = reminder
		(details_panel.find_child("CloseBossRule", true, false) as Button).text = ZodiacCatalog.words("Back to the table · Esc", "Về bàn · Esc")
		if not promise_panel.visible: _close_details()
		_layout()
		return
	var state: Dictionary = host.deal.zodiac_boss.presentation()
	var key := "%s:%d:%s:%d:%s" % [host.campaign.run_seed, host.campaign.current_day_index, state.id, state.difficulty, TranslationServer.get_locale()]
	var accent := Color("ff8576") if state.id == "rooster" else Color("c294ff") if state.id == "cat" else PresentationTheme.SPEAKER
	if key != _boss_key:
		_boss_key = key
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
		portrait.texture = load(ZodiacCatalog.sprite_path(state.id))
		var overlay_path := ZodiacCatalog.sprite_path(state.id, true)
		evening_overlay.texture = load(overlay_path) if state.id != "dragon" and ResourceLoader.exists(overlay_path) else null
		_queue_speech(_arrival(state), "arrival:" + key)
	panel.add_theme_stylebox_override("panel", _glass(accent, 0.68))
	feedback_panel.add_theme_stylebox_override("panel", _glass(accent, 0.84))
	title.add_theme_color_override("font_color", accent)
	_speaker.add_theme_color_override("font_color", accent)
	title.text = "%s · %s" % [ZodiacCatalog.display_name(state.id), ZodiacCatalog.disposition_label(state.disposition)]
	_speaker.text = ZodiacCatalog.display_name(state.id)
	skill.text = state.skill
	full_state.text = state.skill + "\n" + ZodiacCatalog.state_text(state, host.deal)
	if state.id == "dragon": full_state.text += "\n" + ZodiacCatalog.modifier_text(state, host.deal)
	state_label.text = ZodiacCatalog.state_text(state, host.deal).replace("\n", " · ")
	if state.id == "rooster" and host.deal.current_phase == 1 and not state.register_closed:
		var remaining: int = maxi(int(ZodiacCatalog.tuning("rooster", "discard_deadline", state.difficulty)) - host.deal.discard_count, 0)
		state_label.text = ZodiacCatalog.words("Closes in %d discard(s)", "Đóng sổ sau %d lần bỏ") % remaining
	panel.tooltip_text = full_state.text + "\n\n" + state.rule
	details.text = state.rule
	detail_button.text = "×" if details_panel.visible else "?"
	detail_button.tooltip_text = ZodiacCatalog.words("Close rule", "Đóng luật") if details_panel.visible else state.rule
	(details_panel.find_child("CloseBossRule", true, false) as Button).text = ZodiacCatalog.words("Back to the table · Esc", "Về bàn · Esc")
	_sync_opponent_cards()
	_layout()
	portrait.visible = not _blocked()
	evening_overlay.visible = portrait.visible and evening_overlay.texture != null

func _sync_opponent_cards() -> void:
	for child in opponent_cards.get_children():
		opponent_cards.remove_child(child)
		child.queue_free()
	opponent_cards.visible = not host.deal.boss_melds.is_empty()
	for meld: MeldState in host.deal.boss_melds.slice(-2):
		var group := VBoxContainer.new()
		opponent_cards.add_child(group)
		var caption := _label(11)
		caption.text = ZodiacCatalog.words("MOUSE #%d", "PHỎM TÝ #%d") % meld.meld_id
		group.add_child(caption)
		var faces := HBoxContainer.new()
		faces.add_theme_constant_override("separation", -8)
		group.add_child(faces)
		for card in meld.cards:
			var face := TextureRect.new()
			face.texture = load(card.texture_path())
			face.custom_minimum_size = Vector2(25, 35)
			face.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			face.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			face.tooltip_text = card.short_label()
			faces.add_child(face)

func _arrival(state: Dictionary) -> String:
	match String(state.id):
		"rooster": return ZodiacCatalog.words("Make it count. I close after discard %d.", "Tranh thủ đi. Ta chốt sổ sau lần bỏ thứ %d.") % int(ZodiacCatalog.tuning("rooster", "discard_deadline", state.difficulty))
		"cat": return ZodiacCatalog.words("Play your hand. I'll choose my prey in Phase 2.", "Cứ đánh đi. Hiệp 2, ta sẽ chọn con mồi.")
	return state.skill + " · " + ZodiacCatalog.state_text(state, host.deal).get_slice("\n", 0)

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
	_speech_duration = clampf(2.5 + String(item.line).length() * 0.025, 3.5, 5.5)
	_speech_time = _speech_duration
	feedback_panel.modulate.a = 0
	feedback_panel.show()
	_reaction = 1

func present_action(result: Dictionary) -> void:
	if not visible or not panel.visible: return
	var rule: ZodiacBossRule = host.deal.zodiac_boss
	var phase: int = host.deal.current_phase
	var locks := ",".join(rule.locked_ids)
	if rule.id == "rooster":
		if rule.register_closed and not _closed_seen:
			_queue_speech(ZodiacCatalog.words("Register closed. Legal plays now pay 0 VNĐ.", "Chốt sổ! Bài vẫn hợp lệ, nhưng trả 0 VNĐ."), "closed:%d" % phase, true)
		elif phase == 2 and _phase_seen != 2:
			_queue_speech(ZodiacCatalog.words("Phase 2. Extensions only.", "Hiệp 2. Chỉ nối Phỏm thôi.") if rule.difficulty == ZodiacCatalog.UNPLEASED else ZodiacCatalog.words("A fresh page. Scoring is open again.", "Sang trang mới. Lại được ghi điểm rồi."), "phase2", true)
	elif rule.id == "cat" and phase == 2 and (locks != _locks_seen or rule.turn_serial != _turn_seen):
		_queue_speech(ZodiacCatalog.words("These %d are mine until the next turn.", "%d lá này thuộc về ta tới lượt kế.") % rule.locked_ids.size() if not locks.is_empty() else ZodiacCatalog.words("No prey this turn. Go on.", "Lượt này không có con mồi. Đánh tiếp đi."), "locks:%d:%s" % [rule.turn_serial, locks], true)
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
		if left == 1: _queue_speech(ZodiacCatalog.words("One discard left. Spend it well.", "Còn một lần bỏ. Liệu mà tận dụng."), "last-discard", true)
	elif context != null and int(result.get("earned_vnd", 0)) > 0:
		if rule.id == "cat": _queue_speech(ZodiacCatalog.words("A neat play. I saw that.", "Hạ đẹp đấy. Ta thấy rồi."), "paid:" + action_key)
		elif rule.id == "rooster": _queue_speech(ZodiacCatalog.words("On the books. Keep going.", "Ghi vào sổ rồi. Tiếp đi."), "paid:" + action_key)

func react_locked_card(card: CardData) -> void:
	if host.deal.zodiac_boss.is_locked(card):
		_queue_speech(ZodiacCatalog.words("That card stays with me until the next turn.", "Lá đó ở với ta tới lượt kế."), "touch-lock:%d:%s" % [host.deal.zodiac_boss.turn_serial, card.unique_id], true)

func present_suppression(context: ScoringContext) -> void:
	_queue_speech(ZodiacCatalog.feedback(context.suppression_reason) + ZodiacCatalog.words(" · this play pays 0 VNĐ.", " · lần đánh này trả 0 VNĐ."), "payout:%d" % context.get_instance_id(), true)

func present_events(events: Array) -> void:
	for event: Dictionary in events:
		var action: String = event.get("action", "")
		var line := ""
		match action:
			"boss_discard": line = ZodiacCatalog.words("Snatched: ", "Ta lấy lá ") + String(event.get("label", ""))
			"boss_meld", "boss_extension": line = ZodiacCatalog.words("Mine. That costs you ", "Của ta. Bạn mất ") + VndWallet.format_vnd(absi(int(event.get("amount_vnd", 0))))
			"pig_siphon": line = ZodiacCatalog.words("I'll hold ", "Ta giữ ") + VndWallet.format_vnd(int(event.amount_vnd))
			"pig_return": line = ZodiacCatalog.words("Target met. Your pool is back.", "Đủ mục tiêu. Trả lại cả quỹ.")
			"pig_bank_loss": line = ZodiacCatalog.words("Target missed. Time to collect.", "Chưa đủ mục tiêu. Đến lúc thu tiền.")
			"snake_disobeyed": line = ZodiacCatalog.words("Disobedient. Your turn continues.", "Không tuân lệnh. Lượt vẫn tiếp tục.")
			"horse_forced_discard": line = ZodiacCatalog.words("Too slow. I'll choose your discard.", "Chậm quá. Ta chọn lá bỏ cho bạn.")
		if not line.is_empty(): _queue_speech(line, "%s:%d:%d" % [action, host.deal.current_phase, host.deal.zodiac_boss.turn_serial], true)
