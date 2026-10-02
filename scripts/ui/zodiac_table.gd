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
	return (host.game_started and not host.tutorial_active and not service.active_id().is_empty()
		and not host.menu_layer.visible and host.current_campaign_event != null
		and host.current_campaign_event.slot in [EventManager.EventSlot.NOON, EventManager.EventSlot.AFTERNOON]
		and host.event_table.visible and host.event_table.table_state == EventTableController.TABLE_STATE_EVENT
		and host.event_table.focused_npc_id in ["", EventTableController.NPC_ZODIAC] and not host.event_table.deck_focused)

func _event_overview_available() -> bool:
	return _event_available() and host.event_table.focused_npc_id.is_empty()

func configure(match_host: Control) -> void:
	host = match_host
	service = host.campaign.zodiac
	name = "ZodiacTable"
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	z_index = 210
	var layer: Dictionary = host.event_table._npc_layers[EventTableController.NPC_ZODIAC]
	badge = layer.button
	portrait = layer.overlay
	character = layer.sprite
	nameplate = layer.name_tag
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
	detail_button.pressed.connect(func(): details_open = not details_open; mechanics.visible = details_open)
	body.add_child(detail_button)
	close_button = Button.new()
	close_button.name = "CloseConversation"
	close_button.custom_minimum_size.y = 40
	close_button.pressed.connect(_close_conversation)
	body.add_child(close_button)
	service.changed.connect(func(): refresh(); host._sync_event_continue())
	host.deal.wallet.balance_changed.connect(func(_before: int, _after: int, _delta: int, reason: String):
		if reason.begins_with("zodiac_request:"): host._on_gieo_wallet_changed.call_deferred())
	host.event_table.focus_cleared.connect(func(): shade.hide(); scene_page = -1; refresh())
	host.campaign.campaign_phase_changed.connect(func(_phase): shade.hide(); scene_page = -1; refresh.call_deferred())
	refresh()

func _label(font_size: int) -> Label:
	var label := Label.new()
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
	detail_button.text = ZodiacCatalog.words("Tonight's boss rule", "Luật boss tối nay")
	if shade.visible and scene_page < 0: _build_conversation()

func open_conversation() -> void:
	if not _event_available() or host.modal_overlay.visible or host.score_overlay.visible: return
	if host.campaign.gieo_que.state not in [GieoQueService.STATE_READY, GieoQueService.STATE_COMPLETE] or host.active_drag_payload != null: return
	if host.event_table.focused_npc_id.is_empty():
		host.event_table.focus_npc(EventTableController.NPC_ZODIAC)
		return
	scene_page = -1
	host.event_table.content_panel.hide()
	host.event_table.conversation.hide()
	shade.show()
	_build_conversation()
	_focus_first_choice.call_deferred()

func _close_conversation() -> void:
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
	dialogue.text = ZodiacCatalog.display_name(id) + "\n“" + String(quote.get("speech", "")) + "”"
	contract_label.text = String(quote.get("contract", ""))
	contract_label.visible = not contract_label.text.is_empty()
	mechanics.text = ZodiacCatalog.rule_text(id, service.mood())
	mechanics.visible = details_open
	status.text = ZodiacCatalog.words("%s · %d pleasing · %d displeasing", "%s · %d vừa ý · %d không vừa ý") % [ZodiacCatalog.disposition_label(service.mood()), int(state.get("successful_responses", 0)), int(state.get("failed_responses", 0))]
	if service.has_open_demand():
		status.text += "\n" + (ZodiacCatalog.words("Demand %d of %d", "Yêu cầu %d / %d") % [int(state.cursor) + 1, int(state.demand_count)])
		if quote.status == "counteroffer": status.text += "\n" + ZodiacCatalog.words("COUNTEROFFER · confirm with Accept. Nothing spent yet.", "ĐỀ NGHỊ KHÁC · bấm Đồng ý để xác nhận. Chưa mất gì.")
	for promise: Dictionary in service.daily.get("promises", []):
		status.text += "\n" + ZodiacCatalog.words("PENDING: ", "ĐANG CAM KẾT: ") + ZodiacDemand.describe(promise.get("demand", ZodiacDemand.make("PROMISE", "ANY", "PLAYER_CHOOSES", 1, "", 5000, {"condition": "wallet_floor"})))
	if not state.get("history", []).is_empty():
		for record: Dictionary in state.history:
			var result: Dictionary = record.result
			var label := ZodiacCatalog.words("Pending", "Chưa kiểm tra") if result.get("pending", false) else ZodiacCatalog.words("Kept", "Đã giữ") if result.get("resolved_successfully", false) else ZodiacCatalog.words("Broken", "Không giữ")
			if int(service.daily.slot) == EventManager.EventSlot.AFTERNOON:
				status.text += "\n%s · %s" % [label, ZodiacDemand.describe(record.demand)]
	if service.has_open_demand() and not service.daily.get("last_result", {}).is_empty():
		var last: Dictionary = service.daily.last_result
		status.text += "\n" + (ZodiacCatalog.words("Last answer: promise reserved.", "Vừa đáp lời: đã nhận cam kết.") if last.get("pending", false) else ZodiacCatalog.words("Last answer: pleasing.", "Vừa đáp lời: vừa ý.") if last.get("resolved_successfully", false) else ZodiacCatalog.words("Last answer: displeasing.", "Vừa đáp lời: không vừa ý."))
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
	dialogue.text = quote.speech
	contract_label.text = quote.contract
	contract_label.visible = not contract_label.text.is_empty()
	mechanics.text = ZodiacCatalog.rule_text(service.active_id(), service.mood())
	mechanics.visible = details_open
	var patience := int(visit.get("patience", 3))
	status.text = "%s · %s\n%s %s" % [ZodiacCatalog.relationship_label(service.progress.relationship_tier(service.active_id())),
		ZodiacCatalog.disposition_label(service.mood()), ZodiacCatalog.words("Patience", "Kiên nhẫn"), "●".repeat(patience) + "○".repeat(5 - patience)]
	status.tooltip_text = "%d / 5" % patience
	status.add_theme_color_override("font_color", PresentationTheme.GOLD if patience >= 4 else PresentationTheme.WARNING if patience <= 1 else PresentationTheme.TEA)
	if quote.stage == "counteroffer":
		status.text += "\n" + ZodiacCatalog.words("COUNTEROFFER · confirm the changed terms with Accept.", "ĐỀ NGHỊ KHÁC · Đồng ý để xác nhận điều kiện mới.")
	elif quote.stage == "last_chance_pending":
		status.text += "\n" + ZodiacCatalog.words("LAST CHANCE · Cat's recovery scene awaits authoring. Normal choices are suspended.", "CƠ HỘI CUỐI · Cảnh phục hồi của Mão chưa được viết. Tạm dừng lựa chọn thường.")
	elif quote.stage == "locked":
		status.text += "\n" + ZodiacCatalog.words("Today's conversation has ended.", "Cuộc trò chuyện hôm nay đã kết thúc.")
	for result: Dictionary in visit.get("outcomes", []):
		status.text += "\n" + (ZodiacCatalog.words("FULFILLED · ", "ĐÃ GIỮ · ") if result.resolved_successfully else ZodiacCatalog.words("BROKEN · ", "THẤT HỨA · ")) + service.persuasion.describe_terms(result.terms)
	if quote.stage == "judged" and service.progress.relationship_tier(service.active_id()) > int(visit.get("relationship_at_start", 1)):
		status.text += "\n" + ZodiacCatalog.words("FAMILIAR unlocked · Tier 1+ on future visits.", "Đã QUEN MẶT · Nội dung 1+ từ lần gặp sau.")
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
			card_select_button.text = ZodiacCatalog.words("Choose one of the three cards", "Chọn một trong ba lá bài")
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
		haggle.tooltip_text = ZodiacCatalog.words("No valid replacement target is available.", "Không có đối tượng thay thế hợp lệ.") if haggle.disabled and quote.stage != "counteroffer" else ""

func _answer_button(answer_id: String, answer_text: String) -> Button:
	var button := _button("", Callable())
	# Wrapped Label keeps the exact answer readable without truncation.
	button.custom_minimum_size = Vector2(0, 58)
	button.set_meta("answer_id", answer_id)
	button.set_meta("answer_text", answer_text)
	var label := Label.new()
	label.text = answer_id + " · " + answer_text
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
		var view := TextureRect.new()
		view.texture = load(card.texture_path())
		view.custom_minimum_size = face_size
		view.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		view.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		view.tooltip_text = "%s · %s\n%s" % [card.short_label(), card.unique_id, "\n".join(card.gieo_property_descriptions())]
		view.mouse_filter = Control.MOUSE_FILTER_PASS
		target_preview.add_child(view)
	target_preview.visible = not ids.is_empty()

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
	_clear_choices()
	contract_label.hide()
	card_select_button.hide()
	target_preview.hide()
	mechanics.show()
	targets.hide()
	alterations.hide()
	var id := service.active_id()
	var history := service.progress.record(id)
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
