extends Control
## Presentation only. All choices are validated and committed by ZodiacService.
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
var mechanics: Label
var status: Label
var targets: OptionButton
var alterations: OptionButton
var choices: GridContainer
var close_button: Button
var card_select_button: Button
var selected_card_id := ""
var detail_button: Button
var nameplate: Label
var details_open := false
var _clock := 0.0
var _selection_offer_key := ""
var scene_page := -1
var _last_telegraph := ""

func _process(delta: float) -> void:
	if host == null: return
	_clock += delta
	var should_show := _event_overview_available()
	if visible != should_show: refresh()
	portrait.visible = should_show and not shade.visible
	badge.visible = portrait.visible
	nameplate.visible = portrait.visible
	portrait.position.y = -4.0 + sin(_clock * 1.7) * 6.0
	if character != null and shade.visible:
		character.rotation = sin(_clock * 1.25) * 0.012
		character.scale = Vector2.ONE * (1.0 + sin(_clock * 1.6) * 0.012)

func _event_overview_available() -> bool:
	return (host.game_started and not host.tutorial_active and not service.active_id().is_empty()
		and not host.menu_layer.visible and host.current_campaign_event != null
		and host.event_table.visible and host.event_table.table_state == EventTableController.TABLE_STATE_EVENT
		and host.event_table.focused_npc_id.is_empty() and not host.event_table.deck_focused)

func configure(match_host: Control) -> void:
	host = match_host
	service = host.campaign.zodiac
	name = "ZodiacTable"
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	z_index = 210
	badge = Button.new()
	badge.name = "ZodiacStatus"
	badge.position = Vector2(155, 8)
	# The animal's head is clickable; EVENT Back occupies the strip beneath it.
	badge.size = Vector2(172, 78)
	badge.flat = true
	badge.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	badge.pressed.connect(open_conversation)
	add_child(badge)
	portrait = TextureRect.new()
	portrait.position = Vector2(130, -4)
	portrait.size = Vector2(210, 210)
	portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE
	portrait.material = ShaderMaterial.new()
	(portrait.material as ShaderMaterial).shader = preload("res://shaders/zodiac_spirit.gdshader")
	add_child(portrait)
	nameplate = Label.new()
	nameplate.name = "ZodiacNameplate"
	nameplate.position = Vector2(130, 186)
	nameplate.size = Vector2(210, 40)
	nameplate.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	nameplate.add_theme_font_size_override("font_size", 15)
	nameplate.add_theme_color_override("font_color", PresentationTheme.GOLD)
	nameplate.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(nameplate)
	shade = ColorRect.new()
	shade.name = "ZodiacConversation"
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.color = Color(0.015, 0.025, 0.035, 0.48)
	shade.hide()
	add_child(shade)
	var panel := PanelContainer.new()
	panel.position = Vector2(20, 90)
	panel.size = Vector2(1240, 575)
	var style := PresentationTheme.panel_style(Color.TRANSPARENT)
	for side in ["left", "right", "top", "bottom"]: style.set("content_margin_" + side, 8.0)
	panel.add_theme_stylebox_override("panel", style)
	shade.add_child(panel)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 22)
	panel.add_child(row)
	character = TextureRect.new()
	character.name = "Character"
	character.custom_minimum_size = Vector2(350, 540)
	character.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	character.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	character.mouse_filter = Control.MOUSE_FILTER_IGNORE
	character.pivot_offset = Vector2(175, 270)
	character.material = ShaderMaterial.new()
	(character.material as ShaderMaterial).shader = preload("res://shaders/zodiac_spirit.gdshader")
	row.add_child(character)
	body = VBoxContainer.new()
	body.name = "ConversationBody"
	body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.add_theme_constant_override("separation", 12)
	row.add_child(body)
	copy_scroll = ScrollContainer.new()
	copy_scroll.name = "DialogueScroll"
	copy_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	copy_scroll.custom_minimum_size.y = 160
	copy_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_child(copy_scroll)
	copy_body = VBoxContainer.new()
	copy_body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	copy_body.add_theme_constant_override("separation", 12)
	copy_scroll.add_child(copy_body)
	dialogue = _label(23)
	var speech_card := PanelContainer.new()
	speech_card.name = "SpeechCard"
	speech_card.add_theme_stylebox_override("panel", PresentationTheme.panel_style(Color("#102537b8"), PresentationTheme.TEA, 1, 8, 3))
	copy_body.add_child(speech_card)
	dialogue.reparent(speech_card)
	mechanics = _label(17)
	mechanics.visible = false
	status = _label(16)
	status.add_theme_color_override("font_color", PresentationTheme.GOLD)
	targets = OptionButton.new()
	targets.name = "CostTarget"
	targets.item_selected.connect(func(_index): _update_card_cost())
	body.add_child(targets)
	card_select_button = Button.new()
	card_select_button.name = "ZodiacChooseCard"
	card_select_button.pressed.connect(_open_card_deck)
	PresentationTheme.configure_button(card_select_button, "gold")
	body.add_child(card_select_button)
	alterations = OptionButton.new()
	alterations.name = "CardCost"
	body.add_child(alterations)
	choices = GridContainer.new()
	choices.columns = 2
	choices.add_theme_constant_override("h_separation", 12)
	choices.add_theme_constant_override("v_separation", 8)
	body.add_child(choices)
	detail_button = Button.new()
	detail_button.name = "ZodiacDetails"
	detail_button.text = ZodiacCatalog.words("What does this mean?", "Chuyện này nghĩa là gì?")
	detail_button.pressed.connect(func(): details_open = not details_open; mechanics.visible = details_open)
	body.add_child(detail_button)
	var close := Button.new()
	close_button = close
	close.name = "CloseConversation"
	close.text = ZodiacCatalog.words("Back to the table", "Về bàn")
	close.custom_minimum_size.y = 40
	close.pressed.connect(_close_conversation)
	body.add_child(close)
	service.changed.connect(refresh)
	host.deal.state_changed.connect(func(_result): refresh())
	host.campaign.campaign_phase_changed.connect(func(_phase): shade.hide(); host.event_table.modulate.a = 1.0; refresh.call_deferred())
	refresh()

func _label(font_size: int) -> Label:
	var label := Label.new()
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size", font_size)
	copy_body.add_child(label)
	return label

func refresh() -> void:
	var id := service.active_id()
	visible = _event_overview_available()
	if not visible:
		shade.hide()
		host.event_table.modulate.a = 1.0
		return
	close_button.text = ZodiacCatalog.words("Back to the table", "Về bàn")
	portrait.visible = not shade.visible
	badge.visible = portrait.visible
	nameplate.visible = portrait.visible
	var boss: ZodiacBossRule = host.deal.zodiac_boss
	var is_evening: bool = host.campaign.current_phase == CampaignManager.CampaignPhase.EVENING_DEAL
	var state_text := ZodiacCatalog.disposition_label(service.mood())
	if is_evening:
		if id == "rooster":
			state_text = ZodiacCatalog.words("PHASE 2 · NORMAL SCORING", "HIỆP 2 · TÍNH ĐIỂM THƯỜNG") if host.deal.current_phase == 2 else ZodiacCatalog.words("REGISTER CLOSED", "ĐÃ ĐÓNG SỔ") if boss.register_closed else ZodiacCatalog.words("REGISTER OPEN", "ĐANG MỞ SỔ")
		else:
			state_text = ZodiacCatalog.words("WATCHING", "ĐANG QUAN SÁT") if host.deal.current_phase == 1 else ZodiacCatalog.words("THE STALK · %d LOCKED", "RÌNH MỒI · KHÓA %d LÁ") % boss.locked_ids.size()
	badge.text = ""
	nameplate.text = ZodiacCatalog.display_name(id) + "\n" + ZodiacCatalog.disposition_label(service.mood())
	badge.tooltip_text = state_text + "\n" + ZodiacCatalog.rule_text(id, service.mood())
	portrait.texture = load(ZodiacCatalog.DEFINITIONS[id].sprite)
	var telegraph := "%s:%s" % [id, state_text]
	if is_evening and telegraph != _last_telegraph:
		_last_telegraph = telegraph
		host.ui_feedback.play(&"transition")
		var tween := create_tween()
		badge.modulate = Color(1.8, 1.4, 0.8)
		tween.tween_property(badge, "modulate", Color.WHITE, 0.7)
	if shade.visible and scene_page < 0: _build_conversation()

func open_conversation() -> void:
	if not _event_overview_available() or host.modal_overlay.visible or host.score_overlay.visible: return
	if host.campaign.gieo_que.state not in [GieoQueService.STATE_READY, GieoQueService.STATE_COMPLETE]: return
	if host.active_drag_payload != null: return
	scene_page = -1
	shade.show()
	host.event_table.modulate.a = 0.38
	_build_conversation()

func _close_conversation() -> void:
	shade.hide()
	scene_page = -1
	host.event_table.modulate.a = 1.0

func _clear_choices() -> void:
	copy_scroll.scroll_vertical = 0
	for child in choices.get_children():
		choices.remove_child(child)
		child.queue_free()

func _button(text: String, action: Callable) -> void:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(300, 42)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	PresentationTheme.configure_button(button, "tea")
	button.pressed.connect(action)
	choices.add_child(button)

func _build_conversation() -> void:
	_clear_choices()
	var id := service.active_id()
	close_button.text = ZodiacCatalog.words("Back to the table", "Về bàn")
	character.texture = load(ZodiacCatalog.DEFINITIONS[id].sprite)
	var quote := service.quote()
	var offer_key := "%s:%s:%s" % [service.daily.get("day", -1), service.daily.get("slot", -1), quote.get("status", "")]
	if offer_key != _selection_offer_key:
		selected_card_id = ""
		_selection_offer_key = offer_key
	var history := service.progress.record(id)
	dialogue.text = ZodiacCatalog.display_name(id) + "\n“" + String(quote.get("speech", "")) + "”"
	mechanics.text = ZodiacCatalog.rule_text(id, service.mood())
	status.text = ZodiacCatalog.words("You have met %d times today. %s is %s.", "Hôm nay hai người đã nói chuyện %d lần. %s đang %s.") % [service.daily.requests.size(), ZodiacCatalog.display_name(id), ZodiacCatalog.disposition_label(service.mood()).to_lower()]
	for promise: Dictionary in service.daily.promises:
		status.text += "\n" + ZodiacCatalog.words("ACTIVE PROMISE: ", "CAM KẾT ĐANG GIỮ: ") + (ZodiacCatalog.words("score before the next Deal's first discard", "ghi điểm trước lần bỏ đầu Ván kế") if promise.kind == "early_score" else ZodiacCatalog.words("keep 5,000 VNĐ until Afternoon", "giữ 5.000 VNĐ tới Buổi chiều"))
	targets.hide()
	alterations.hide()
	card_select_button.hide()
	var event_active := CampaignManager.EVENT_PHASE_TO_SLOT.has(host.campaign.current_phase)
	if event_active and quote.get("status", "") == "offered":
		mechanics.text = quote.contract + "\n\n" + mechanics.text
		if quote.kind in ["alter", "gift"]:
			targets.clear()
			if quote.kind == "alter":
				card_select_button.show()
				card_select_button.text = ZodiacCatalog.words("Choose a card from your deck", "Chọn lá từ bộ bài") if selected_card_id.is_empty() else ZodiacCatalog.words("Chosen: ", "Đã chọn: ") + _selected_card_label()
				alterations.clear()
				for entry in [["reset", ZodiacCatalog.words("Reset to original card", "Hoàn nguyên lá bài")], ["remove_property", ZodiacCatalog.words("Remove last property", "Bỏ thuộc tính cuối")], ["seal", ZodiacCatalog.words("Seal transformations for this run", "Khóa biến đổi hết lượt chơi")]]:
					alterations.add_item(entry[1])
					alterations.set_item_metadata(alterations.item_count - 1, entry[0])
				alterations.show()
				_update_card_cost()
			else:
				for relic_id: String in host.deal.relics.inventory:
					targets.add_item(RelicCatalog.DEFINITIONS[relic_id].name)
					targets.set_item_metadata(targets.item_count - 1, relic_id)
				targets.show()
		_button(_accept_words(quote.kind), _respond.bind("ACCEPT"))
		if (quote.kind == "gift" and targets.item_count == 0) or (quote.kind == "alter" and selected_card_id.is_empty()): choices.get_child(0).disabled = true
		_button(ZodiacCatalog.words("No, thanks.", "Thôi, cảm ơn nhé."), _respond.bind("REFUSE"))
		var extras: Array[String] = ["BARGAIN"]
		if quote.kind == "pay": extras.append("COUNTEROFFER")
		if quote.can_time: extras.append("SPEND_TIME")
		var rng := RandomNumberGenerator.new()
		rng.seed = hash("%s:%d:%d" % [service.run_id, service.daily.day, service.daily.slot])
		var extra := extras[rng.randi_range(0, extras.size() - 1)]
		_button(_extra_words(extra), _respond.bind(extra))
	else:
		var last: Dictionary = service.daily.last_result
		if not last.is_empty():
			dialogue.text = ZodiacCatalog.display_name(id) + "\n“" + _follow_up_line(last, id) + "”"
	if event_active and history.get("special_scene_unlocked", false) and not service.progress.owns(id):
		_button(ZodiacCatalog.words("A private moment…", "Một khoảnh khắc riêng…"), func(): scene_page = 0; _show_scene())
	_button(ZodiacCatalog.words("History & Emblems", "Lịch sử & Huy hiệu"), _show_history)
	mechanics.visible = details_open
	detail_button.visible = event_active

func _accept_words(kind: String) -> String:
	match kind:
		"pay": return ZodiacCatalog.words("All right. Here is 5,000 VNĐ.", "Được. Đây là 5.000 VNĐ.")
		"early_score": return ZodiacCatalog.words("I'll make a meld before I discard.", "Tôi sẽ hạ Phỏm trước khi bỏ bài.")
		"restraint": return ZodiacCatalog.words("I'll keep 5,000 VNĐ aside.", "Tôi sẽ giữ lại 5.000 VNĐ.")
		"alter": return ZodiacCatalog.words("All right. Change this card.", "Được. Đổi lá này đi.")
		"gift": return ZodiacCatalog.words("You can have this relic.", "Tôi tặng món này.")
	return ZodiacCatalog.words("All right.", "Được thôi.")

func _follow_up_line(result: Dictionary, id: String) -> String:
	var response := String(result.get("resolution_type", ""))
	if response == "REFUSE":
		return ZodiacCatalog.words("You know your mind. I can respect that.", "Bạn biết mình muốn gì. Tôi tôn trọng điều đó.") if id == "cat" else ZodiacCatalog.words("Fair enough. Better a clear no than a promise you can't keep.", "Ừ, nói không rõ ràng còn hơn hứa rồi không làm.")
	if response == "SPEND_TIME":
		return ZodiacCatalog.words("Stay a little longer, then. The cards can wait.", "Vậy ngồi thêm chút nữa đi. Bài để sau cũng được.")
	if response == "COUNTEROFFER":
		return ZodiacCatalog.words("Now we're talking. You don't give in so easily.", "Thế mới là nói chuyện. Bạn đâu dễ nhượng bộ.")
	if result.get("resolved_successfully", false):
		return ZodiacCatalog.words("All right. I'll remember you kept your word.", "Được. Tôi sẽ nhớ là bạn giữ lời.")
	return ZodiacCatalog.words("Hmm. I thought you'd choose differently.", "Ừm. Tôi tưởng bạn sẽ chọn khác.")

func _extra_words(response: String) -> String:
	match response:
		"COUNTEROFFER": return ZodiacCatalog.words("How about 2,500 VNĐ?", "2.500 VNĐ được không?")
		"SPEND_TIME": return ZodiacCatalog.words("Let's sit a little longer. I'll skip the next Deal.", "Ngồi thêm chút nhé. Tôi bỏ Ván kế.")
	return ZodiacCatalog.words("Can we find another way?", "Mình tính cách khác được không?")

func _selected_card_label() -> String:
	for card: CardData in host.campaign.gieo_que.persistent_deck:
		if card.unique_id == selected_card_id: return card.short_label()
	return "?"

func _open_card_deck() -> void:
	var deck: Array[CardData] = host.campaign.gieo_que.persistent_deck
	var available: Array[CardData] = []
	for card in deck:
		if card.has_permanent_changes() or not card.transformation_locked:
			available.append(card)
	host.deck_screen.open_deck(deck, ZodiacCatalog.words("Your deck", "Bộ bài của bạn"),
		ZodiacCatalog.words("Choose the physical card for this request. Inspect its permanent changes before deciding.", "Chọn lá bài thật cho lời đề nghị này. Xem kỹ biến đổi trước khi quyết định."), available,
		func(card_id: String): selected_card_id = card_id; _build_conversation())

func _update_card_cost() -> void:
	if not alterations.visible or selected_card_id.is_empty(): return
	var id := selected_card_id
	for card: CardData in host.campaign.gieo_que.persistent_deck:
		if card.unique_id != id: continue
		alterations.set_item_disabled(0, not card.has_permanent_changes())
		alterations.set_item_disabled(1, card.gieo_properties.is_empty())
		alterations.set_item_disabled(2, card.transformation_locked)
		if alterations.is_item_disabled(alterations.selected):
			for index in alterations.item_count:
				if not alterations.is_item_disabled(index):
					alterations.select(index)
					break

func _respond(response: String) -> void:
	var target := selected_card_id if card_select_button.visible else String(targets.get_item_metadata(targets.selected)) if targets.visible and targets.item_count > 0 else ""
	var alteration := String(alterations.get_item_metadata(alterations.selected)) if alterations.visible else "reset"
	var result := service.respond(response, target, alteration)
	if not result.get("ok", false):
		status.text = ZodiacCatalog.words("Cannot commit: check funds, owned target, or available property. Nothing was spent.", "Chưa thể thực hiện: kiểm tra tiền, vật sở hữu hoặc thuộc tính. Chưa mất tài nguyên.")
	else: _build_conversation()

func _show_history() -> void:
	_clear_choices()
	targets.hide()
	alterations.hide()
	var id := service.active_id()
	var history := service.progress.record(id)
	dialogue.text = ZodiacCatalog.words("An Emblem remembers deeds.", "Huy hiệu ghi nhớ hành động.")
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
	_clear_choices()
	targets.hide()
	alterations.hide()
	var rooster := service.active_id() == "rooster"
	var pages := [
		ZodiacCatalog.words("The street is still asleep. Rooster pulls out a chair before you ask. For once, he leaves his watch face down.", "Phố còn ngủ. Dậu kéo ghế trước khi bạn hỏi. Lần này, anh úp mặt đồng hồ xuống.") if rooster else ZodiacCatalog.words("The last glass has stopped ringing. Cat stays at the table, watching the street empty without asking you for anything.", "Tiếng ly cuối đã lắng. Mão ngồi lại, nhìn phố vắng dần mà không đòi hỏi điều gì."),
		ZodiacCatalog.words("“You said no when you meant no. And when you promised, you acted. That's rarer than an early sunrise.”", "“Bạn nói không khi muốn nói không. Đã hứa là làm. Còn hiếm hơn một buổi bình minh sớm.”") if rooster else ZodiacCatalog.words("“You learned to leave something untouched. Patience isn't obedience. It's knowing what is worth keeping.”", "“Bạn đã biết giữ lại một điều. Kiên nhẫn không phải phục tùng. Là biết điều gì đáng giữ."),
		ZodiacCatalog.words("He slides a small brass rooster across the wood. “Next time, put this on the table. I'll find the time.”", "Anh đẩy con gà bằng đồng nhỏ qua mặt bàn. “Lần tới đặt nó ở đây. Tôi sẽ dành thời gian.”") if rooster else ZodiacCatalog.words("She leaves a small cat-shaped token beside your glass. “When our day comes, set it here. I'll be watching.”", "Cô để huy hiệu hình mèo cạnh ly. “Tới ngày của chúng ta, đặt nó ở đây. Tôi sẽ nhìn thấy.”"),
	]
	dialogue.text = pages[scene_page]
	mechanics.text = ZodiacCatalog.words("The table keeps its own kind of history.", "Chiếc bàn giữ một lịch sử rất riêng.")
	status.text = "%d / 3" % (scene_page + 1)
	_button(ZodiacCatalog.words("Continue", "Tiếp tục") if scene_page < 2 else ZodiacCatalog.words("Accept the Emblem", "Nhận Huy hiệu"), func():
		if scene_page < 2:
			scene_page += 1
			_show_scene()
		else:
			service.complete_scene()
			scene_page = -1
			_build_conversation())
