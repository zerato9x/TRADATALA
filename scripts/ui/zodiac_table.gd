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
var scene_page := -1
var _last_telegraph := ""

func _process(_delta: float) -> void:
	if host == null: return
	var should_show: bool = host.game_started and not host.tutorial_active and not service.active_id().is_empty() and not host.menu_layer.visible
	if visible != should_show: refresh()
	portrait.visible = host.current_campaign_event == null or host.event_table.focused_npc_id.is_empty()

func configure(match_host: Control) -> void:
	host = match_host
	service = host.campaign.zodiac
	name = "ZodiacTable"
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	z_index = 210
	badge = Button.new()
	badge.name = "ZodiacStatus"
	badge.position = Vector2(16, 78)
	badge.size = Vector2(260, 54)
	badge.add_theme_font_size_override("font_size", 14)
	PresentationTheme.configure_button(badge, "tea")
	badge.pressed.connect(open_conversation)
	add_child(badge)
	portrait = TextureRect.new()
	portrait.position = Vector2(8, 305)
	portrait.size = Vector2(140, 185)
	portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(portrait)
	shade = ColorRect.new()
	shade.name = "ZodiacConversation"
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.color = Color(0.025, 0.035, 0.03, 0.87)
	shade.hide()
	add_child(shade)
	var panel := PanelContainer.new()
	panel.position = Vector2(100, 85)
	panel.size = Vector2(1080, 580)
	var style := PresentationTheme.panel_style(PresentationTheme.PANEL, PresentationTheme.GOLD_DARK, 2, 8, 12)
	for side in ["left", "right", "top", "bottom"]: style.set("content_margin_" + side, 18.0)
	panel.add_theme_stylebox_override("panel", style)
	shade.add_child(panel)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 24)
	panel.add_child(row)
	character = TextureRect.new()
	character.name = "Character"
	character.custom_minimum_size = Vector2(230, 400)
	character.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	character.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	character.mouse_filter = Control.MOUSE_FILTER_IGNORE
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
	mechanics = _label(17)
	status = _label(16)
	status.add_theme_color_override("font_color", PresentationTheme.GOLD)
	targets = OptionButton.new()
	targets.name = "CostTarget"
	targets.item_selected.connect(func(_index): _update_card_cost())
	body.add_child(targets)
	alterations = OptionButton.new()
	alterations.name = "CardCost"
	body.add_child(alterations)
	choices = GridContainer.new()
	choices.columns = 2
	choices.add_theme_constant_override("h_separation", 12)
	choices.add_theme_constant_override("v_separation", 8)
	body.add_child(choices)
	var close := Button.new()
	close_button = close
	close.name = "CloseConversation"
	close.text = ZodiacCatalog.words("Back to the table", "Về bàn")
	close.custom_minimum_size.y = 40
	close.pressed.connect(func(): shade.hide(); scene_page = -1)
	body.add_child(close)
	service.changed.connect(refresh)
	host.deal.state_changed.connect(func(_result): refresh())
	host.campaign.campaign_phase_changed.connect(func(_phase): shade.hide(); refresh.call_deferred())
	refresh()

func _label(font_size: int) -> Label:
	var label := Label.new()
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size", font_size)
	copy_body.add_child(label)
	return label

func refresh() -> void:
	var id := service.active_id()
	visible = host.game_started and not host.tutorial_active and not id.is_empty() and not host.menu_layer.visible
	if not visible: return
	close_button.text = ZodiacCatalog.words("Back to the table", "Về bàn")
	portrait.visible = host.current_campaign_event == null or host.event_table.focused_npc_id.is_empty()
	var boss: ZodiacBossRule = host.deal.zodiac_boss
	var is_evening: bool = host.campaign.current_phase == CampaignManager.CampaignPhase.EVENING_DEAL
	var state_text := ZodiacCatalog.disposition_label(service.mood())
	if is_evening:
		if id == "rooster":
			state_text = ZodiacCatalog.words("PHASE 2 · NORMAL SCORING", "HIỆP 2 · TÍNH ĐIỂM THƯỜNG") if host.deal.current_phase == 2 else ZodiacCatalog.words("REGISTER CLOSED", "ĐÃ ĐÓNG SỔ") if boss.register_closed else ZodiacCatalog.words("REGISTER OPEN", "ĐANG MỞ SỔ")
		else:
			state_text = ZodiacCatalog.words("WATCHING", "ĐANG QUAN SÁT") if host.deal.current_phase == 1 else ZodiacCatalog.words("THE STALK · %d LOCKED", "RÌNH MỒI · KHÓA %d LÁ") % boss.locked_ids.size()
	badge.text = ZodiacCatalog.display_name(id) + "\n" + state_text
	badge.tooltip_text = ZodiacCatalog.rule_text(id, service.mood())
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
	if service.active_id().is_empty() or (host.interaction_locked and host.current_campaign_event == null) or host.modal_overlay.visible or host.score_overlay.visible: return
	if host.campaign.gieo_que.state not in [GieoQueService.STATE_READY, GieoQueService.STATE_COMPLETE]: return
	if host.active_drag_payload != null: return
	scene_page = -1
	shade.show()
	_build_conversation()

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
	var history := service.progress.record(id)
	dialogue.text = ZodiacCatalog.display_name(id) + "\n“" + String(quote.get("speech", "")) + "”"
	mechanics.text = ZodiacCatalog.rule_text(id, service.mood())
	status.text = ZodiacCatalog.words("Resolved today: %d/4 · %s\nHistory: %d resolved · %d time spent · Emblem: %s", "Hôm nay: %d/4 · %s\nLịch sử: %d hoàn thành · %d lần dành thời gian · Huy hiệu: %s") % [int(service.daily.successes), ZodiacCatalog.disposition_label(service.mood()), int(history.get("requests_resolved", 0)), int(history.get("spend_time_count", 0)), ZodiacCatalog.words("owned", "đã có") if service.progress.owns(id) else ZodiacCatalog.words("locked", "chưa có")]
	for promise: Dictionary in service.daily.promises:
		status.text += "\n" + ZodiacCatalog.words("ACTIVE PROMISE: ", "CAM KẾT ĐANG GIỮ: ") + (ZodiacCatalog.words("score before the next Deal's first discard", "ghi điểm trước lần bỏ đầu Ván kế") if promise.kind == "early_score" else ZodiacCatalog.words("keep 5,000 VNĐ until Afternoon", "giữ 5.000 VNĐ tới Buổi chiều"))
	targets.hide()
	alterations.hide()
	var event_active := CampaignManager.EVENT_PHASE_TO_SLOT.has(host.campaign.current_phase)
	if event_active and quote.get("status", "") == "offered":
		mechanics.text = quote.contract + "\n" + mechanics.text
		if quote.kind in ["alter", "gift"]:
			targets.clear()
			if quote.kind == "alter":
				for card: CardData in host.campaign.gieo_que.persistent_deck:
					var identity := card.unique_id.split("_")
					var original := CardData.new("", identity[1].to_upper(), 0, identity[2].capitalize(), 0).short_label()
					var label := card.short_label()
					if original != label: label += " · " + ZodiacCatalog.words("original ", "gốc ") + original
					label += " · %d " % card.gieo_properties.size() + ZodiacCatalog.words("properties", "thuộc tính")
					if card.transformation_locked: label += ZodiacCatalog.words(" [SEALED]", " [ĐÃ KHÓA]")
					targets.add_item(label)
					targets.set_item_metadata(targets.item_count - 1, card.unique_id)
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
		_button(ZodiacCatalog.words("Accept the stated cost / promise", "Đồng ý chi phí / cam kết"), _respond.bind("ACCEPT"))
		if quote.kind == "gift" and targets.item_count == 0: choices.get_child(0).disabled = true
		_button(ZodiacCatalog.words("Refuse · no cost", "Từ chối · miễn phí"), _respond.bind("REFUSE"))
		if quote.kind == "pay": _button(ZodiacCatalog.words("Counteroffer · 2,500 VNĐ", "Đề nghị khác · 2.500 VNĐ"), _respond.bind("COUNTEROFFER"))
		_button(ZodiacCatalog.words("Bargain · no payment", "Mặc cả · không trả tiền"), _respond.bind("BARGAIN"))
		if quote.can_time:
			_button(ZodiacCatalog.words("Stay · skip next Deal, earn nothing", "Ở lại · bỏ Ván kế, không có tiền"), _respond.bind("SPEND_TIME"))
	else:
		var last: Dictionary = service.daily.last_result
		if not last.is_empty():
			dialogue.text += "\n" + (ZodiacCatalog.words("“You made your choice. I respect it.”", "“Bạn đã chọn. Tôi tôn trọng điều đó.”") if last.resolved_successfully else ZodiacCatalog.words("“That was an answer. It wasn't what I hoped to see.”", "“Cũng là một câu trả lời. Nhưng chưa phải điều tôi muốn thấy.”"))
	if event_active and history.get("special_scene_unlocked", false) and not service.progress.owns(id):
		_button(ZodiacCatalog.words("A private moment…", "Một khoảnh khắc riêng…"), func(): scene_page = 0; _show_scene())
	_button(ZodiacCatalog.words("History & Emblems", "Lịch sử & Huy hiệu"), _show_history)

func _update_card_cost() -> void:
	if not alterations.visible or targets.item_count == 0: return
	var id := String(targets.get_item_metadata(targets.selected))
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
	var target := String(targets.get_item_metadata(targets.selected)) if targets.visible and targets.item_count > 0 else ""
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
