class_name EventTableServices
extends Node
## Owns focused service views. Gameplay changes return as intent to the coordinator.
signal wallet_committed()
signal notice(message: String)
signal gieo_impact_requested(kind: StringName)
signal reels_stop_requested()
signal commitment_changed(committed: bool)
signal card_pick_requested(cards: Array[CardData], reason: String, callback: Callable)
signal identity_pick_requested(cards: Array[CardData], reason: String, callback: Callable)
signal identity_feedback_requested(cue: StringName)
signal removal_pick_requested(cards: Array[CardData], reason: String, callback: Callable)
signal drink_order_requested(slot: int, interaction_id: String, drink_id: String)
signal debt_briefing_seen()
signal zodiac_requested()
signal handbook_requested(section: String)

var table: EventTableController
var _campaign_ref: WeakRef
var _deal_ref: WeakRef
var _drink_ref: WeakRef
var campaign: CampaignManager:
	get: return _campaign_ref.get_ref() as CampaignManager
var deal: DealState:
	get: return _deal_ref.get_ref() as DealState
var drink_manager: DrinkManager:
	get: return _drink_ref.get_ref() as DrinkManager

func configure(p_table: EventTableController, p_campaign: CampaignManager, p_deal: DealState, p_drinks: DrinkManager) -> void:
	table = p_table
	_campaign_ref = weakref(p_campaign)
	_deal_ref = weakref(p_deal)
	_drink_ref = weakref(p_drinks)


func present_npc(npc_id: String, event: EventInstance) -> void:
	if DemoBuild.enabled() and npc_id not in [EventTableController.NPC_TRA_DA, EventTableController.NPC_DOI_NO]:
		return
	table.clear_service_views()
	_restore_event_content_frame()
	table.continue_button.visible = false
	table.content_panel.position = Vector2(350, 305)
	table.content_panel.size = Vector2(580, 360)
	table.back_button.disabled = false
	if npc_id == EventTableController.NPC_ZODIAC:
		zodiac_requested.emit()
		return
	var participant: NPCDefinition
	if event != null:
		for candidate in event.participants:
			if candidate.id == npc_id:
				participant = candidate
				break
	if npc_id == EventTableController.NPC_DOI_NO:
		_build_debt_ledger()
	elif npc_id == EventTableController.NPC_THAY_BOI and participant != null:
		_build_gieo_que_service()
	elif npc_id in [EventTableController.NPC_DANH_GIAY, EventTableController.NPC_LOTTO] and participant != null:
		_build_misc_npc_service(npc_id)
	elif npc_id == EventTableController.NPC_HANG_RONG:
		table.continue_button.visible = false
		table.content_panel.position = Vector2(145, 251)
		table.content_panel.size = Vector2(740, 427)
		for side in ["left", "top", "right", "bottom"]:
			(table.content_panel.get_child(0) as MarginContainer).add_theme_constant_override("margin_" + side, 0)
		table.content_panel.add_theme_stylebox_override("panel", StyleBoxEmpty.new())
		var panel := preload("res://scripts/ui/relic_table_shop.gd").new()
		table.participants_container.add_child(panel)
		panel.dialogue_requested.connect(table.say)
		panel.removal_pick_requested.connect(removal_pick_requested.emit)
		panel.configure(deal.relics, campaign.relic_shop)
		panel.wallet_changed.connect(wallet_committed.emit)
	elif npc_id == EventTableController.NPC_TRA_DA and participant != null:
		_build_drink_service(event)
	else:
		_build_event_placeholder(npc_id, event)
	table.say(tr("NPC_GREETING_" + npc_id.to_upper()))
	if npc_id == EventTableController.NPC_TRA_DA and event != null:
		for interaction in event.interactions:
			if interaction.action_type == "choose_drink" and interaction.completed:
				table.say(tr("DRINK_RECEIPT") % DrinkCatalog.display_name(drink_manager.active_drink_id))


func _build_misc_npc_service(npc_id: String) -> void:
	table.continue_button.visible = false
	var service_rect: Rect2 = EventTableController.MISC_SERVICE_RECTS[npc_id]
	table.content_panel.position = service_rect.position
	table.content_panel.size = service_rect.size
	table.content_panel.add_theme_stylebox_override("panel", PresentationTheme.panel_style(Color("#102338c8"), PresentationTheme.GOLD_DARK, 1, 4))
	var margin := table.content_panel.get_child(0) as MarginContainer
	for side in ["left", "top", "right", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 0)
	if npc_id == EventTableController.NPC_DANH_GIAY:
		table.content_panel.add_theme_stylebox_override("panel", StyleBoxEmpty.new())
		var bench := ShoeShinePanel.new()
		table.participants_container.add_child(bench)
		bench.wallet_changed.connect(wallet_committed.emit)
		bench.dialogue_requested.connect(table.say)
		bench.card_pick_requested.connect(identity_pick_requested.emit)
		bench.feedback_requested.connect(identity_feedback_requested.emit)
		bench.configure(campaign.shoe_shine)
	else:
		var panel := MiscNpcPanel.new()
		table.participants_container.add_child(panel)
		panel.wallet_changed.connect(wallet_committed.emit)
		panel.dialogue_requested.connect(table.say)
		panel.configure_lottery(campaign.lottery)


func _build_gieo_que_service() -> void:
	# Keep the event header and wallet readable above the full-height cabinet.
	table.content_panel.position = Vector2(380, 120)
	table.content_panel.size = Vector2(870, 600)
	table.continue_button.visible = false
	table.content_panel.add_theme_stylebox_override("panel", StyleBoxEmpty.new())
	var content_margin := table.content_panel.get_child(0) as MarginContainer
	if content_margin != null:
		for constant_name in [&"margin_left", &"margin_top", &"margin_right", &"margin_bottom"]:
			content_margin.add_theme_constant_override(constant_name, 0)
	var panel := preload("res://scripts/ui/gieo_que_panel.gd").new() as GieoQuePanel
	table.participants_container.add_child(panel)
	panel.configure(campaign.gieo_que)
	panel.wallet_changed.connect(wallet_committed.emit)
	panel.feedback_requested.connect(notice.emit)
	panel.impact_requested.connect(gieo_impact_requested.emit)
	panel.tree_exiting.connect(reels_stop_requested.emit)
	panel.commitment_changed.connect(commitment_changed.emit)
	panel.card_pick_requested.connect(card_pick_requested.emit)
	var committed := campaign.gieo_que.state not in [GieoQueService.STATE_READY, GieoQueService.STATE_COMPLETE]
	commitment_changed.emit(committed)


func _restore_event_content_frame() -> void:
	if table == null or table.content_panel == null:
		return
	var style := PresentationTheme.panel_style(Color("#102338c8"), Color("#8d5b30"), 1, 3, 3)
	style.content_margin_left = 22
	style.content_margin_top = 18
	style.content_margin_right = 22
	style.content_margin_bottom = 18
	table.content_panel.add_theme_stylebox_override("panel", style)
	var content_margin := table.content_panel.get_child(0) as MarginContainer
	if content_margin != null:
		content_margin.add_theme_constant_override("margin_left", 16)
		content_margin.add_theme_constant_override("margin_top", 14)
		content_margin.add_theme_constant_override("margin_right", 16)
		content_margin.add_theme_constant_override("margin_bottom", 14)


func _build_event_placeholder(npc_id: String, event: EventInstance) -> void:
	var title := Label.new()
	title.text = table.npc_display_name(npc_id)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 26)
	title.add_theme_color_override("font_color", PresentationTheme.GOLD)
	table.participants_container.add_child(title)
	var system_label := Label.new()
	var system_key := _event_placeholder_key(npc_id, event)
	var system_name := tr(system_key)
	system_label.text = system_name
	system_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	system_label.add_theme_font_size_override("font_size", 16)
	system_label.add_theme_color_override("font_color", PresentationTheme.TEA)
	table.participants_container.add_child(system_label)
	var note := Label.new()
	note.text = tr("EVENT_PLACEHOLDER_NOTE")
	note.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	note.add_theme_color_override("font_color", PresentationTheme.MUTED)
	table.participants_container.add_child(note)
	var cards := HBoxContainer.new()
	cards.alignment = BoxContainer.ALIGNMENT_CENTER
	cards.add_theme_constant_override("separation", 12)
	table.participants_container.add_child(cards)
	for index in range(3):
		var card := Button.new()
		card.custom_minimum_size = Vector2(148, 110)
		card.text = "%s\n%02d" % [system_label.text, index + 1]
		card.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		card.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		PresentationTheme.configure_button(card, "neutral")
		card.pressed.connect(_on_event_placeholder_pressed.bind(system_key))
		cards.add_child(card)


func _event_placeholder_key(npc_id: String, event: EventInstance) -> String:
	match npc_id:
		EventTableController.NPC_THAY_BOI:
			return "EVENT_PLACEHOLDER_THAY_BOI"
		EventTableController.NPC_HANG_RONG:
			return "EVENT_PLACEHOLDER_HANG_RONG"
		EventTableController.NPC_DANH_GIAY:
			return "EVENT_PLACEHOLDER_DANH_GIAY"
		EventTableController.NPC_LOTTO:
			return "EVENT_PLACEHOLDER_LOTTO_RESULT" if event != null and event.slot == EventManager.EventSlot.AFTERNOON else "EVENT_PLACEHOLDER_LOTTO_CHOICE"
		_:
			return "EVENT_PLACEHOLDER_GENERIC"


func _on_event_placeholder_pressed(system_key: String) -> void:
	notice.emit(tr("EVENT_PLACEHOLDER_READY") % tr(system_key))


func _build_drink_choices(parent: VBoxContainer, event: EventInstance, interaction: EventInteraction) -> void:
	var shop := preload("res://scenes/ui/drink_shop.tscn").instantiate() as DrinkShop
	parent.add_child(shop)
	shop.configure(drink_manager, interaction.completed)
	shop.drink_inspected.connect(func(id: String) -> void: table.say(DrinkCatalog.display_name(id) + " · " + QuickInfo.drink(id)))
	shop.order_requested.connect(func(id: String) -> void: drink_order_requested.emit(event.slot, interaction.id, id))


func _build_debt_ledger() -> void:
	table.continue_button.visible = false
	table.content_panel.position = Vector2(145, 285)
	table.content_panel.size = Vector2(700, 370)
	var heading := Label.new()
	heading.text = tr("DEBT_INTRO_REQUIRED")
	PresentationTheme.style_text(heading, &"body", 18)
	table.participants_container.add_child(heading)
	var amount := Label.new()
	amount.name = "DebtAmountDue"
	amount.text = VndWallet.format_vnd(campaign.daily_requirement())
	PresentationTheme.style_text(amount, &"debt", 38)
	table.participants_container.add_child(amount)
	var line := RichTextLabel.new()
	line.bbcode_enabled = true
	line.fit_content = true
	line.scroll_active = false
	line.custom_minimum_size = Vector2(640, 90)
	line.text = tr("DEBT_INTRO_EXPLANATION") % PresentationTheme.emphasis(tr("PERIOD_EVENING"), &"warning")
	PresentationTheme.style_text(line, &"body", 18)
	table.participants_container.add_child(line)
	var remaining := Label.new()
	remaining.text = tr("DEBT_INTRO_SHORTFALL") % VndWallet.format_vnd(maxi(campaign.daily_requirement() - deal.wallet.balance_vnd, 0))
	PresentationTheme.style_text(remaining, &"debt", 20)
	table.participants_container.add_child(remaining)
	var guide := Button.new()
	guide.text = GameGlossary.words("ABOUT DEBT", "VỀ KHOẢN NỢ")
	guide.pressed.connect(func(): handbook_requested.emit("campaign"))
	table.participants_container.add_child(guide)
	PresentationTheme.configure_button(guide)
	table.back_button.text = tr("DEBT_INTRO_ACKNOWLEDGE")
	debt_briefing_seen.emit()


func _build_drink_service(event: EventInstance) -> void:
	table.content_panel.position = Vector2(145, 245 if DemoBuild.enabled() else 270)
	table.content_panel.size = Vector2(730, 355)
	table.content_panel.add_theme_stylebox_override("panel", StyleBoxEmpty.new())
	for interaction in event.interactions:
		if interaction.participant_id == EventTableController.NPC_TRA_DA and interaction.action_type == "choose_drink":
			_build_drink_choices(table.participants_container, event, interaction)
