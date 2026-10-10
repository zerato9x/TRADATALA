extends Control
## The Event Table stages the character. This view sends negotiation intentions.
var host: Control
var service: ZodiacService
var badge: Button
var portrait: TextureRect
var character: TextureRect
var shade: ColorRect
var body: VBoxContainer
var copy_body: VBoxContainer
var copy_scroll: ScrollContainer
var dialogue: Label
var contract_label: Label
var mechanics: Label
var status: Label
var targets: OptionButton
var alterations: OptionButton
var choices: GridContainer
var close_button: Button
var card_select_button: Button
var selected_card_id := ""
var selected_ids: Array[String] = []
var target_preview: HBoxContainer
var detail_button: Button
var memory_button: Button
var history_open := false
var nameplate: Label
var details_open := false
var _clock := 0.0
var _selection_offer_key := ""
var scene_page := -1

func _process(delta: float) -> void:
	if host == null: return
	_clock += delta
	if visible != _event_available(): refresh()
	if shade.visible:
		character.rotation = sin(_clock * 1.25) * 0.012
		character.scale = Vector2.ONE * (1.0 + sin(_clock * 1.6) * 0.012)

func _event_available() -> bool:
	return (host.game_started and not service.active_id().is_empty()
		and not host.menu_layer.visible and host.current_campaign_event != null
		and host.current_campaign_event.slot in [EventManager.EventSlot.NOON, EventManager.EventSlot.AFTERNOON]
		and host.event_table.visible and host.event_table.table_state == EventTableController.TABLE_STATE_EVENT
		and host.event_table.focused_npc_id in ["", EventTableController.NPC_ZODIAC] and not host.event_table.deck_focused)

func configure(match_host: Control) -> void:
	host = match_host
	service = host.campaign.zodiac
	name = "ZodiacTable"
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	z_index = 210
	var views: Dictionary = host.event_table.zodiac_views()
	badge = views.button
	portrait = views.portrait
	character = views.character
	nameplate = views.nameplate
	shade = ColorRect.new()
	shade.name = "ZodiacConversation"
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.color = Color.TRANSPARENT
	shade.mouse_filter = Control.MOUSE_FILTER_STOP
	shade.hide()
	add_child(shade)
	var panel := PanelContainer.new()
	panel.position = Vector2(145, 80)
	panel.size = Vector2(695, 605)
	panel.add_theme_stylebox_override("panel", PresentationTheme.panel_style(Color("#102537e8"), PresentationTheme.GOLD_DARK, 1, 8, 3))
	shade.add_child(panel)
	var margin := MarginContainer.new()
	for side in ["left", "right", "top", "bottom"]: margin.add_theme_constant_override("margin_" + side, 16)
	panel.add_child(margin)
	body = VBoxContainer.new()
	body.name = "ConversationBody"
	body.add_theme_constant_override("separation", 8)
	margin.add_child(body)
	copy_scroll = ScrollContainer.new()
	copy_scroll.name = "DialogueScroll"
	copy_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	copy_scroll.custom_minimum_size.y = 124
	copy_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_child(copy_scroll)
	copy_body = VBoxContainer.new()
	copy_body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	copy_body.add_theme_constant_override("separation", 12)
	copy_scroll.add_child(copy_body)
	dialogue = _label(22)
	contract_label = _label(17)
	contract_label.name = "DemandTerms"
	contract_label.add_theme_color_override("font_color", PresentationTheme.GOLD)
	status = _label(16)
	mechanics = _label(16)
	mechanics.hide()
	for label: Label in [contract_label, status, mechanics]:
		label.remove_meta("conversation_text")
		TextReveal.finish(label)
	target_preview = HBoxContainer.new()
	target_preview.name = "DemandCards"
	target_preview.add_theme_constant_override("separation", 8)
	body.add_child(target_preview)
	card_select_button = Button.new()
	card_select_button.name = "ZodiacChooseCard"
	card_select_button.pressed.connect(_open_card_deck)
	PresentationTheme.configure_button(card_select_button, "gold")
	body.add_child(card_select_button)
	# Retain the history/scene view's simple visibility contract.
	targets = OptionButton.new()
	alterations = OptionButton.new()
	body.add_child(targets)
	body.add_child(alterations)
	targets.hide()
	alterations.hide()
	choices = GridContainer.new()
	choices.columns = 3
	choices.add_theme_constant_override("h_separation", 8)
	choices.add_theme_constant_override("v_separation", 8)
	body.add_child(choices)
	detail_button = Button.new()
	detail_button.name = "ZodiacDetails"
	detail_button.pressed.connect(_open_handbook)
	var detail_row := HBoxContainer.new()
	body.add_child(detail_row)
	detail_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	detail_row.add_child(detail_button)
	memory_button = Button.new()
	memory_button.name = "CatMemory"
	memory_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	memory_button.pressed.connect(_show_history)
	detail_row.add_child(memory_button)
	close_button = Button.new()
	close_button.name = "CloseConversation"
	close_button.custom_minimum_size.y = 40
	close_button.pressed.connect(close_conversation)
	body.add_child(close_button)
	service.changed.connect(refresh)
	host.event_table.focus_cleared.connect(func(): shade.hide(); scene_page = -1; refresh())
	host.campaign.campaign_phase_changed.connect(func(_phase): shade.hide(); scene_page = -1; refresh.call_deferred())
	refresh()

func _label(font_size: int) -> Label:
	var label := Label.new()
	label.set_meta("conversation_text", true)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.add_theme_font_size_override("font_size", font_size)
	copy_body.add_child(label)
	return label

func refresh() -> void:
	var slot: int = host.current_campaign_event.slot if host.current_campaign_event != null else -1
	host.event_table.set_zodiac_visitor(service.active_id(), service.visitor_available(slot))
	visible = _event_available()
	if not visible: shade.hide()
	close_button.text = ZodiacCatalog.words("Back to the table", "Về bàn")
	detail_button.text = ZodiacCatalog.words("Handbook", "Sổ tay")
	PresentationTheme.configure_button(detail_button)
	memory_button.text = ZodiacCatalog.localized(ZodiacCatalog.persuasion_config(service.active_id()).get("memory_button", {"en": "Cat's memory", "vi": "Điều Mão nhớ"}))
	memory_button.visible = service.uses_persuasion()
	PresentationTheme.configure_button(memory_button)
	if shade.visible and scene_page < 0:
		if history_open: _show_history()
		else: _build_conversation()

func open_conversation() -> void:
	if not _event_available() or host.modal_overlay.visible or host.score_overlay.visible: return
	if host.campaign.gieo_que.state not in [GieoQueService.STATE_READY, GieoQueService.STATE_COMPLETE] or host.interactions.drag_payload != null: return
	if host.event_table.focused_npc_id.is_empty():
		host.event_table.focus_npc(EventTableController.NPC_ZODIAC)
		return
	scene_page = -1
	history_open = false
	host.event_table.content_panel.hide()
	host.event_table.conversation.hide()
	shade.show()
	_build_conversation()
	_focus_first_choice.call_deferred()

func close_conversation() -> void:
	shade.hide()
	scene_page = -1
	character.rotation = 0.0
	character.scale = Vector2.ONE
	if host.event_table.focused_npc_id == EventTableController.NPC_ZODIAC: host.event_table.unfocus_npc()
	refresh()

func _clear_choices() -> void:
	copy_scroll.scroll_vertical = 0
	for child in choices.get_children():
		choices.remove_child(child)
		child.queue_free()

func _button(text: String, action: Callable) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(210, 42)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	PresentationTheme.configure_button(button, "tea")
	if action.is_valid(): button.pressed.connect(action)
	choices.add_child(button)
	return button

func _build_conversation() -> void:
	history_open = false
	dialogue.set_meta("conversation_text", true)
	_clear_choices()
	choices.columns = 3
	if service.uses_persuasion():
		_build_persuasion()
		return
	if contract_label.get_parent() != copy_body:
		contract_label.reparent(copy_body)
		copy_body.move_child(contract_label, 1)
		status.reparent(copy_body)
		copy_body.move_child(status, 2)
	copy_scroll.custom_minimum_size.y = 124
	var id := service.active_id()
	var quote := service.quote()
	var demand: Dictionary = quote.get("demand", {})
	var offer_key := "%s:%s" % [demand.get("id", ""), quote.get("status", "")]
	if offer_key != _selection_offer_key:
		selected_ids.clear()
		selected_card_id = ""
		_selection_offer_key = offer_key
	var state := service.negotiation()
	dialogue.text = ZodiacCatalog.display_name(id)
	dialogue.set_meta("zodiac_id", id)
	contract_label.text = QuickInfo.demand(demand)
	contract_label.visible = not contract_label.text.is_empty()
	mechanics.text = ZodiacCatalog.rule_text(id, service.mood())
	mechanics.hide()
	status.text = ZodiacCatalog.disposition_label(service.mood())
	if service.has_open_demand():
		status.text += " · %d/%d" % [int(state.cursor) + 1, int(state.demand_count)]
		if quote.status == "counteroffer": status.text += " · " + ZodiacCatalog.words("Counteroffer", "Đề nghị khác")
	var pending: Array = service.daily.get("promises", [])
	if not pending.is_empty(): status.text += " · " + (ZodiacCatalog.words("%d pending", "%d cam kết") % pending.size())
	var result: Dictionary = service.daily.get("last_result", {})
	if not result.is_empty(): status.text += " · " + (ZodiacCatalog.words("Kept", "Đã giữ") if result.get("resolved_successfully", false) else ZodiacCatalog.words("Broken", "Thất hứa"))
	targets.hide()
	alterations.hide()
	card_select_button.hide()
	_build_target_preview(demand)
	if service.has_open_demand():
		if demand.verb in ZodiacDemand.CARD_VERBS and ZodiacDemand.player_controls(demand):
			card_select_button.show()
			card_select_button.text = ZodiacCatalog.words("Choose cards · %d / %d", "Chọn bài · %d / %d") % [selected_ids.size(), int(demand.quantity)]
			var labels: Array[String] = []
			for card in CardTargetQuery.resolve_ids(host.campaign.gieo_que.persistent_deck, selected_ids): labels.append(card.short_label())
			if not labels.is_empty(): card_select_button.text += " · " + ", ".join(labels)
		var accept := _button(ZodiacCatalog.words("ACCEPT", "ĐỒNG Ý"), _respond.bind("ACCEPT", offer_key))
		accept.disabled = not service.can_accept(selected_ids)
		_button(ZodiacCatalog.words("REFUSE", "TỪ CHỐI"), _respond.bind("REFUSE", offer_key))
		var haggle := _button(ZodiacCatalog.words("HAGGLE", "MẶC CẢ"), _respond.bind("HAGGLE", offer_key))
		haggle.disabled = not quote.can_haggle
		accept.mouse_filter = Control.MOUSE_FILTER_IGNORE if accept.disabled else Control.MOUSE_FILTER_STOP
		haggle.mouse_filter = Control.MOUSE_FILTER_IGNORE if haggle.disabled else Control.MOUSE_FILTER_STOP
	var history := service.progress.record(id)
	if id != "cat" and history.get("special_scene_unlocked", false) and not service.progress.owns(id):
		_button(ZodiacCatalog.words("A private moment…", "Một khoảnh khắc riêng…"), func(): scene_page = 0; _show_scene())
	_button(ZodiacCatalog.words("History & Emblems", "Lịch sử & Huy hiệu"), _show_history)

func _build_persuasion() -> void:
	var quote := service.quote()
	var visit := service.persuasion.state()
	var token := service.offer_token()
	if contract_label.get_parent() != body:
		contract_label.reparent(body)
		body.move_child(contract_label, 1)
		status.reparent(body)
		body.move_child(status, 2)
	# Dialogue scrolls; the visible terms and mood remain beside the controls.
	copy_scroll.custom_minimum_size.y = 64 if service.has_open_demand() else 96
	selected_ids.assign(visit.get("selection", []))
	# Keep the latest authored spoken line. The entire exchange is readable in the Handbook.
	dialogue.text = String(quote.speech).strip_edges().get_slice("\n", String(quote.speech).strip_edges().get_slice_count("\n") - 1)
	dialogue.remove_meta("zodiac_id")
	contract_label.text = QuickInfo.demand(quote.demand)
	contract_label.visible = not contract_label.text.is_empty()
	mechanics.text = ZodiacCatalog.rule_text(service.active_id(), service.mood())
	mechanics.hide()
	var patience := int(visit.get("patience", 3))
	status.text = "%s · %s\n%s %s" % [ZodiacCatalog.relationship_label(service.progress.relationship_tier(service.active_id())),
		ZodiacCatalog.disposition_label(service.mood()), ZodiacCatalog.words("Patience", "Kiên nhẫn"), "●".repeat(patience) + "○".repeat(5 - patience)]
	status.tooltip_text = "%d / 5" % patience
	status.add_theme_color_override("font_color", PresentationTheme.GOLD if patience >= 4 else PresentationTheme.WARNING if patience <= 1 else PresentationTheme.TEA)
	if quote.stage == "counteroffer":
		status.text += " · " + ZodiacCatalog.words("Counteroffer", "Đề nghị khác")
	elif quote.stage == "last_chance_pending":
		status.text += "\n" + ZodiacCatalog.words("Last chance · unavailable", "Cơ hội cuối · chưa có nội dung")
	elif quote.stage == "locked":
		status.text += " · " + ZodiacCatalog.words("Visit ended", "Đã kết thúc")
	if not visit.get("outcomes", []).is_empty():
		var result: Dictionary = visit.outcomes[-1]
		status.text += " · " + (ZodiacCatalog.words("Kept", "Đã giữ") if result.resolved_successfully else ZodiacCatalog.words("Broken", "Thất hứa"))
	if quote.stage == "judged" and service.progress.relationship_tier(service.active_id()) > int(visit.get("relationship_at_start", 1)):
		status.text += " · " + ZodiacCatalog.relationship_label(service.progress.relationship_tier(service.active_id())) + " +"
	targets.hide()
	alterations.hide()
	card_select_button.hide()
	_build_target_preview(quote.demand)
	if service.has_open_question() or quote.stage == "last_chance":
		choices.columns = 1
		for answer: Dictionary in quote.answers:
			var button := _answer_button(answer.id, answer.text)
			button.pressed.connect(_answer.bind(answer.id, token, quote.stage == "last_chance"))
	elif quote.stage == "reaction":
		choices.columns = 1
		_button(ZodiacCatalog.words("Continue", "Tiếp tục"), func(): service.continue_conversation(token); _focus_first_choice.call_deferred())
	elif quote.stage == "last_chance_pending":
		choices.columns = 1
		_button(ZodiacCatalog.words("End today's visit", "Kết thúc lần gặp hôm nay"), func(): service.persuasion.end_pending_recovery(token); _focus_first_choice.call_deferred())
	elif service.has_open_demand():
		if quote.demand.get("authority", "") == "OFFER_THREE_PLAYER_CHOOSES":
			card_select_button.show()
			card_select_button.text = ZodiacCatalog.words("Choose 1 of 3", "Chọn 1 trong 3")
			if not selected_ids.is_empty():
				var cards := CardTargetQuery.resolve_ids(host.campaign.gieo_que.persistent_deck, selected_ids)
				if not cards.is_empty(): card_select_button.text += " · " + cards[0].short_label()
		var accept := _button(ZodiacCatalog.words("ACCEPT", "ĐỒNG Ý"), _respond.bind("ACCEPT", token))
		accept.disabled = not service.can_accept(selected_ids)
		accept.mouse_filter = Control.MOUSE_FILTER_IGNORE if accept.disabled else Control.MOUSE_FILTER_STOP
		_button(ZodiacCatalog.words("REFUSE", "TỪ CHỐI"), _respond.bind("REFUSE", token))
		var haggle := _button(ZodiacCatalog.words("HAGGLE", "MẶC CẢ"), _respond.bind("HAGGLE", token))
		haggle.disabled = not quote.can_haggle
		haggle.mouse_filter = Control.MOUSE_FILTER_IGNORE if haggle.disabled else Control.MOUSE_FILTER_STOP
		haggle.tooltip_text = (ZodiacCatalog.words("You already choose one of the three cards.", "Bạn đã được chọn một trong ba lá.") if quote.demand.get("authority", "") == "OFFER_THREE_PLAYER_CHOOSES" else ZodiacCatalog.words("No valid replacement target is available.", "Không có đối tượng thay thế hợp lệ.")) if haggle.disabled and quote.stage != "counteroffer" else ""
	elif service.active_id() != "cat" and service.progress.record(service.active_id()).get("special_scene_unlocked", false) and not service.progress.owns(service.active_id()):
		choices.columns = 1
		_button(ZodiacCatalog.words("A private moment…", "Một khoảnh khắc riêng…"), func(): scene_page = 0; _show_scene())

func _answer_button(answer_id: String, answer_text: String) -> Button:
	var button := _button("", Callable())
	# Wrapped Label keeps the exact answer readable without truncation.
	button.custom_minimum_size = Vector2(0, 58)
	button.set_meta("answer_id", answer_id)
	button.set_meta("answer_text", answer_text)
	var label := Label.new()
	label.text = answer_id + " · " + answer_text
	label.name = "AnswerText"
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 17)
	label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	label.offset_left = 12
	label.offset_right = -12
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	button.add_child(label)
	return button

func _answer(answer_id: String, token: String, recovery: bool = false) -> void:
	if recovery: service.persuasion.resolve_last_chance(answer_id, token)
	else: service.answer_question(answer_id, token)
	_focus_first_choice.call_deferred()

func _focus_first_choice() -> void:
	if not shade.visible: return
	for child: Button in choices.get_children():
		if not child.disabled: child.grab_focus(); return
	close_button.grab_focus()

func _build_target_preview(demand: Dictionary) -> void:
	for child in target_preview.get_children():
		target_preview.remove_child(child)
		child.queue_free()
	target_preview.hide()
	if service.uses_persuasion():
		if demand.is_empty(): return
		if demand.get("target_kind", "") == "RELIC":
			var face := TextureRect.new()
			face.texture = load(RelicCatalog.icon_path(demand.relic_id))
			face.custom_minimum_size = Vector2(70, 70)
			face.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			face.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			target_preview.add_child(face)
			var caption := Label.new()
			caption.text = RelicCatalog.display_name(demand.relic_id)
			caption.add_theme_font_size_override("font_size", 18)
			target_preview.add_child(caption)
			target_preview.show()
			return
		var ids: Array = demand.target_ids if not demand.target_ids.is_empty() else demand.offered_ids
		_add_card_previews(ids, Vector2(60, 84))
		return
	if demand.get("verb", "") not in ZodiacDemand.CARD_VERBS: return
	var ids: Array = demand.target_ids if not ZodiacDemand.player_controls(demand) else demand.offered_ids if not demand.offered_ids.is_empty() else selected_ids
	_add_card_previews(ids, Vector2(70, 98))

func _add_card_previews(ids: Array, face_size: Vector2) -> void:
	for card in CardTargetQuery.resolve_ids(host.campaign.gieo_que.persistent_deck, ids):
		var view := CardSymbolArt.create_card_badge(card, 26)
		view.custom_minimum_size.x = face_size.x
		view.tooltip_text = card.short_label()
		view.mouse_filter = Control.MOUSE_FILTER_PASS
		target_preview.add_child(view)
	target_preview.visible = not ids.is_empty()

func _open_handbook() -> void:
	var quote := service.quote()
	var copy := String(quote.get("speech", "")) + "\n\n" + String(quote.get("contract", "")) + "\n\n" + ZodiacCatalog.rule_text(service.active_id(), service.mood())
	if service.uses_persuasion():
		for result: Dictionary in service.persuasion.state().get("outcomes", []):
			copy += "\n\n" + (ZodiacCatalog.words("Kept · ", "Đã giữ · ") if result.resolved_successfully else ZodiacCatalog.words("Broken · ", "Thất hứa · ")) + service.persuasion.describe_terms(result.terms)
	else:
		for record: Dictionary in service.negotiation().get("history", []): copy += "\n\n" + ZodiacDemand.describe(record.demand)
	GameGlossary.open_entry(host, ZodiacCatalog.display_name(service.active_id()), copy, "campaign")

func _open_card_deck() -> void:
	var demand := service.current_demand()
	if service.uses_persuasion():
		if demand.get("authority", "") != "OFFER_THREE_PLAYER_CHOOSES": return
		var token := service.offer_token()
		host.deck_screen.open_deck(host.campaign.gieo_que.persistent_deck, ZodiacCatalog.words("Choose a card to leave untouched", "Chọn lá bài sẽ để yên"),
			service.persuasion.describe_terms(demand), service.selectable_cards(),
			func(card_id: String):
				if service.persuasion.select_card(card_id, token): _build_conversation(); _focus_first_choice.call_deferred())
		return
	if demand.get("verb", "") not in ZodiacDemand.CARD_VERBS: return
	if selected_ids.size() >= int(demand.quantity): selected_ids.clear()
	var available := service.selectable_cards(selected_ids)
	var token := service.offer_token()
	host.deck_screen.open_deck(host.campaign.gieo_que.persistent_deck, ZodiacCatalog.words("Choose a demand target", "Chọn bài cho yêu cầu"),
		ZodiacDemand.describe(demand) + "\n" + (ZodiacCatalog.words("Select card %d of %d. Accept confirms the whole cost.", "Chọn lá %d / %d. Đồng ý xác nhận toàn bộ chi phí.") % [selected_ids.size() + 1, int(demand.quantity)]), available,
		func(card_id: String):
			if token != service.offer_token(): return
			selected_card_id = card_id
			selected_ids.append(card_id)
			_build_conversation())

func _respond(response: String, expected_offer: String = "") -> void:
	var result := service.respond(response, selected_ids, expected_offer)
	if not result.get("ok", false):
		status.text = ZodiacCatalog.words("No change made. ", "Chưa thay đổi gì. ") + (ZodiacCatalog.words("No counteroffer is available for these terms.", "Chưa có đề nghị khác cho điều kiện này.") if result.get("error", "") == "no_counteroffer" else ZodiacCatalog.words("Check the selected cards and available resources.", "Kiểm tra bài đã chọn và tài nguyên hiện có."))
	else: _build_conversation()
	_focus_first_choice.call_deferred()

func _show_history() -> void:
	history_open = true
	_clear_choices()
	contract_label.hide()
	card_select_button.hide()
	target_preview.hide()
	mechanics.show()
	targets.hide()
	alterations.hide()
	var id := service.active_id()
	var history := service.progress.record(id)
	if service.uses_persuasion():
		var config := ZodiacCatalog.persuasion_config(id)
		dialogue.remove_meta("conversation_text")
		TextReveal.finish(dialogue)
		dialogue.text = ZodiacCatalog.localized(config.get("memory_title", {"en": "What Cat remembers", "vi": "Điều Mão nhớ"}))
		status.text = ZodiacCatalog.relationship_label(service.progress.relationship_tier(id))
		mechanics.text = ZodiacCatalog.words("Promises kept: %d · Broken: %d · Refused: %d", "Giữ lời: %d · Thất hứa: %d · Từ chối: %d") % [int(history.get("promises_kept", 0)), int(history.get("promises_broken", 0)), int(history.get("promises_refused", 0))]
		for step: Dictionary in config.get("progression", []):
			if service.progress.relationship_tier(id) != int(step.from): continue
			mechanics.text += "\n\n" + (ZodiacCatalog.words("To become %s: keep %d promises across %d kinds, then finish a visit at Normal or Pleased.\nKept: %d / %d · Kinds: %d / %d", "Để thành %s: giữ %d lời hứa thuộc %d loại, rồi kết thúc lần gặp ở Bình thường hoặc Hài lòng.\nGiữ lời: %d / %d · Loại: %d / %d") % [ZodiacCatalog.relationship_label(int(step.to)), int(step.kept), int(step.distinct), mini(int(step.kept), int(history.get("promises_kept", 0))), int(step.kept), mini(int(step.distinct), service.progress.promise_kinds(id)), int(step.distinct)])
		var topics: Dictionary = service.progress.memories.get(id, {})
		if topics.is_empty(): mechanics.text += "\n\n" + ZodiacCatalog.words("No promises to remember yet.", "Chưa có lời hứa nào để nhớ.")
		for topic in topics:
			var entry: Dictionary = topics[topic]
			var result_label: String = {"FULFILLED": ZodiacCatalog.words("Kept", "Đã giữ"), "BROKEN": ZodiacCatalog.words("Broken", "Thất hứa"), "REFUSED": ZodiacCatalog.words("Refused", "Đã từ chối")}.get(entry.result, "")
			var topic_label: String = {"cat.leave_card": ZodiacCatalog.words("Leave it alone", "Để yên nó"), "cat.keep_relic": ZodiacCatalog.words("Keep it", "Giữ nó"), "cat.protect_card": ZodiacCatalog.words("Don't change it", "Đừng đổi nó")}.get(topic, "")
			if config.get("memory_topics", {}).has(topic): topic_label = ZodiacCatalog.localized(config.memory_topics[topic])
			mechanics.text += "\n\n%s · %s\n%s" % [topic_label, result_label, ZodiacCatalog.memory_target(entry)]
		choices.columns = 1
		if not config.get("emblem_unlock", {}).is_empty():
			mechanics.text += "\n\n" + ZodiacCatalog.words("EMBLEM · Kindred, 3 kept promises across 2 kinds, 1 honest refusal, and 1 Pleased boss victory. Meet again to share a private moment.", "HUY HIỆU · Hợp cạ, giữ 3 lời hứa thuộc 2 loại, 1 lần từ chối thẳng và 1 lần thắng boss Hài lòng. Gặp lại để có khoảnh khắc riêng.")
			mechanics.text += "\n" + (ZodiacCatalog.words("Refusals: %d / 1 · Pleased victories: %d / 1", "Từ chối: %d / 1 · Thắng Hài lòng: %d / 1") % [mini(1, int(history.get("promises_refused", 0))), mini(1, int(history.get("pleased_victories", 0)))])
			if service.progress.owns(id):
				_button(ZodiacCatalog.words("Call ", "Gọi ") + ZodiacCatalog.display_name(id), func(): service.prefer_emblem(id); _show_history())
				_button(ZodiacCatalog.words("Use seeded appearance", "Chọn theo hạt giống"), func(): service.prefer_emblem(); _show_history())
		_button(ZodiacCatalog.words("Back", "Trở lại"), _build_conversation)
		return
	dialogue.text = ZodiacCatalog.words("EMBLEM", "HUY HIỆU")
	mechanics.text = ""
	var labels := {"requests_resolved": ZodiacCatalog.words("Requests resolved", "Yêu cầu hoàn thành"), "requests_refused_successfully": ZodiacCatalog.words("Respected refusals", "Từ chối được tôn trọng"), "pleased_victories": ZodiacCatalog.words("Pleased boss victories", "Thắng boss hài lòng"), "restraint_kept": ZodiacCatalog.words("Restraint promises kept", "Cam kết kiềm chế đã giữ")}
	for metric in ZodiacCatalog.DEFINITIONS[id].unlock:
		mechanics.text += "%s: %d / %d\n" % [labels.get(metric, metric), int(history.get(metric, 0)), int(ZodiacCatalog.DEFINITIONS[id].unlock[metric])]
	mechanics.text += ZodiacCatalog.words("Meet these conditions, encounter them again, then complete their special scene. An owned Emblem can call them on a future matching pair day.", "Đủ điều kiện, gặp lại rồi hoàn thành cảnh đặc biệt. Huy hiệu đã có gọi nhân vật vào ngày cặp tương ứng trong tương lai.")
	status.text = ZodiacCatalog.words("Appearance preference applies on future days, including new runs. Today's visitor will not change.", "Lựa chọn áp dụng vào ngày tương lai, kể cả lượt chơi mới. Khách hôm nay không đổi.")
	for zodiac_id: String in ZodiacCatalog.DEFINITIONS:
		if service.progress.owns(zodiac_id):
			_button(ZodiacCatalog.words("Call ", "Gọi ") + ZodiacCatalog.display_name(zodiac_id), func(): service.prefer_emblem(zodiac_id); _show_history())
	_button(ZodiacCatalog.words("Use seeded appearance", "Chọn theo hạt giống"), func(): service.prefer_emblem(); _show_history())
	_button(ZodiacCatalog.words("Back", "Trở lại"), _build_conversation)

func _show_scene() -> void:
	if service.active_id() == "cat": return # No authored Cat Special scene in this slice.
	_clear_choices()
	contract_label.hide()
	card_select_button.hide()
	target_preview.hide()
	targets.hide()
	alterations.hide()
	var id := service.active_id()
	var pages := [
		ZodiacCatalog.words("The street is still asleep. Rooster pulls out a chair before you ask. For once, he leaves his watch face down.", "Phố còn ngủ. Dậu kéo ghế trước khi bạn hỏi. Lần này, anh úp mặt đồng hồ xuống."),
		ZodiacCatalog.words("“You said no when you meant no. And when you promised, you acted. That's rarer than an early sunrise.”", "“Bạn nói không khi muốn nói không. Đã hứa là làm. Còn hiếm hơn một buổi bình minh sớm.”"),
		ZodiacCatalog.words("He slides a small brass rooster across the wood. “Next time, put this on the table. I'll find the time.”", "Anh đẩy con gà bằng đồng nhỏ qua mặt bàn. “Lần tới đặt nó ở đây. Tôi sẽ dành thời gian.”"),
	]
	if id != "rooster":
		pages = [
			ZodiacCatalog.words("The table grows quiet. %s stays behind after the others leave.", "Bàn đã yên. %s ngồi lại khi những người khác đã về.") % ZodiacCatalog.display_name(id),
			ZodiacCatalog.words("“You kept your word, and you learned my rule: %s. I will remember this game.”", "“Bạn giữ lời và hiểu luật của tôi: %s. Tôi sẽ nhớ ván này.”") % ZodiacCatalog.skill_name(id),
			ZodiacCatalog.words("A small Emblem rests beside your glass. “Call me when our day comes. We have another game to play.”", "Huy hiệu nhỏ nằm cạnh ly. “Gọi tôi khi tới ngày của chúng ta. Mình còn một ván nữa.”"),
		]
	dialogue.text = pages[scene_page]
	mechanics.text = ""
	mechanics.hide()
	status.text = "%d / 3" % (scene_page + 1)
	_button(ZodiacCatalog.words("Continue", "Tiếp tục") if scene_page < 2 else ZodiacCatalog.words("Accept the Emblem", "Nhận Huy hiệu"), func():
		if scene_page < 2:
			scene_page += 1
			_show_scene()
		else:
			service.complete_scene()
			scene_page = -1
			_build_conversation())
