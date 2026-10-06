class_name ShoeShinePanel
extends Control
## A physical card bench. It sends IDs/intent to the campaign service only.
signal wallet_changed()
signal dialogue_requested(line: String)
signal card_pick_requested(cards: Array[CardData], reason: String, callback: Callable)
signal feedback_requested(cue: StringName)

const STAGE := Vector2(700, 400)
var shoe: ShoeShineService
var _slots: Array[Dictionary] = []
var _title: Label
var _count: Label
var _uses: Label
var _receipt: HBoxContainer
var _status: Label
var _working := false
var _refresh_pending := false
var _work_tween: Tween

func configure(service: ShoeShineService) -> void:
	name = "ShoeShinePanel"
	shoe = service
	custom_minimum_size = STAGE
	size = STAGE
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_build()
	shoe.changed.connect(_queue_refresh)
	shoe.wallet.balance_changed.connect(_on_wallet_changed)
	_refresh()

func _exit_tree() -> void:
	if _work_tween != null and _work_tween.is_valid(): _work_tween.kill()
	if shoe != null:
		if shoe.changed.is_connected(_queue_refresh): shoe.changed.disconnect(_queue_refresh)
		if shoe.wallet.balance_changed.is_connected(_on_wallet_changed): shoe.wallet.balance_changed.disconnect(_on_wallet_changed)

func _build() -> void:
	_title = _label(self, "", Vector2.ZERO, Vector2(410, 30), 24, PresentationTheme.GOLD)
	_title.name = "BenchTitle"
	_count = _label(self, "", Vector2(415, 4), Vector2(285, 24), 16, PresentationTheme.TEA)
	_count.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_uses = _label(self, "", Vector2(0, 34), Vector2(700, 24), 15, PresentationTheme.MUTED)
	for index in 2: _build_slot(index)
	_receipt = HBoxContainer.new()
	_receipt.name = "IdentityReceipt"
	_receipt.position = Vector2(12, 359)
	_receipt.size = Vector2(676, 36)
	_receipt.alignment = BoxContainer.ALIGNMENT_CENTER
	_receipt.add_theme_constant_override("separation", 12)
	_receipt.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_receipt)
	_status = _label(self, "", Vector2(12, 359), Vector2(676, 36), 17, PresentationTheme.TEA)
	_status.name = "BenchStatus"
	_status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

func _build_slot(index: int) -> void:
	var mat := Panel.new()
	mat.name = "CardMat_%d" % index
	mat.position = Vector2(index * 356, 66)
	mat.size = Vector2(344, 282)
	mat.mouse_filter = Control.MOUSE_FILTER_IGNORE
	mat.add_theme_stylebox_override("panel", PresentationTheme.panel_style(Color("#24322fe6"), Color("#a18a59"), 1, 10, 0))
	add_child(mat)
	var caption := _label(mat, tr("SHOE_SLOT") % (index + 1), Vector2(14, 7), Vector2(310, 24), 14, PresentationTheme.MUTED)
	var stamp := _label(mat, tr("SHOE_COMMITTED"), Vector2(164, 7), Vector2(165, 24), 12, PresentationTheme.TEA)
	stamp.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	var shadow := Panel.new()
	shadow.position = Vector2(26, 40)
	shadow.size = Vector2(113, 160)
	shadow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	shadow.add_theme_stylebox_override("panel", PresentationTheme.panel_style(Color("#050b0aa0"), Color.TRANSPARENT, 0, 4, 0))
	mat.add_child(shadow)
	var art := Control.new()
	art.name = "WorkedCard_%d" % index
	art.position = Vector2(20, 34)
	art.size = Vector2(114, 162)
	art.pivot_offset = art.size * 0.5
	art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	mat.add_child(art)
	var face := TextureRect.new()
	face.name = "Face"
	face.size = art.size
	face.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	face.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	face.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	face.mouse_filter = Control.MOUSE_FILTER_IGNORE
	art.add_child(face)
	var wipe := ColorRect.new()
	wipe.name = "BrushStroke"
	wipe.position = Vector2(-18, 0)
	wipe.size = Vector2(150, 14)
	wipe.rotation = -0.08
	wipe.color = Color("#fff0b766")
	wipe.mouse_filter = Control.MOUSE_FILTER_IGNORE
	wipe.hide()
	art.add_child(wipe)
	var badge := HBoxContainer.new()
	badge.name = "CurrentIdentity"
	badge.position = Vector2(14, 200)
	badge.size = Vector2(125, 31)
	badge.alignment = BoxContainer.ALIGNMENT_CENTER
	badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	mat.add_child(badge)
	var rank := _button(mat, "RerollRank_%d" % index, Vector2(152, 40), Vector2(177, 68), "gold")
	rank.pressed.connect(_reroll.bind(index, "rank"))
	var suit := _button(mat, "RerollSuit_%d" % index, Vector2(152, 120), Vector2(177, 68), "tea")
	suit.pressed.connect(_reroll.bind(index, "suit"))
	var note := _label(mat, tr("SHOE_PERMANENT"), Vector2(145, 201), Vector2(190, 28), 13, PresentationTheme.MUTED)
	note.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var properties := _label(mat, "", Vector2(14, 237), Vector2(315, 31), 14, PresentationTheme.INK)
	properties.name = "CardProperties"
	properties.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var choose := _button(mat, "ChooseCard_%d" % index, Vector2(16, 70), Vector2(312, 94), "neutral")
	choose.pressed.connect(_pick)
	var empty_note := _label(mat, "", Vector2(24, 174), Vector2(296, 75), 16, PresentationTheme.MUTED)
	empty_note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	empty_note.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_slots.append({"mat": mat, "caption": caption, "art": art, "face": face, "wipe": wipe, "shadow": shadow,
		"badge": badge, "rank": rank, "suit": suit, "properties": properties,
		"choose": choose, "empty_note": empty_note, "stamp": stamp, "note": note})

func _label(parent: Node, text: String, point: Vector2, dimensions: Vector2, pixels: int, color: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.position = point
	label.size = dimensions
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	PresentationTheme.style_text(label, &"body", pixels)
	label.add_theme_color_override("font_color", color)
	parent.add_child(label)
	return label

func _button(parent: Node, node_name: String, point: Vector2, dimensions: Vector2, role: String) -> Button:
	var button := Button.new()
	button.name = node_name
	button.position = point
	button.size = dimensions
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	PresentationTheme.configure_button(button, role)
	button.add_theme_font_size_override("font_size", 17)
	parent.add_child(button)
	return button

func _on_wallet_changed(_before: int, _after: int, _delta: int, _reason: String) -> void:
	_queue_refresh()

func _queue_refresh() -> void:
	if _refresh_pending: return
	_refresh_pending = true
	_refresh.call_deferred()

func _refresh() -> void:
	_refresh_pending = false
	_title.text = tr("SHOE_BENCH")
	_count.text = tr("SHOE_SELECTED") % shoe.selected_card_ids.size()
	_uses.text = tr("SHOE_USES") % [shoe.rank_rerolls, shoe.suit_rerolls]
	for index in _slots.size():
		var slot: Dictionary = _slots[index]
		slot.caption.text = tr("SHOE_SLOT") % (index + 1)
		slot.stamp.text = tr("SHOE_COMMITTED")
		slot.note.text = tr("SHOE_PERMANENT")
		var id: String = shoe.selected_card_ids[index] if shoe.selected_card_ids.size() > index else ""
		var card := shoe.card_for_id(id) if not id.is_empty() else null
		var committed := not id.is_empty()
		slot.mat.set_meta("physical_card_id", id)
		for key in ["art", "badge", "shadow", "properties", "rank", "suit", "stamp", "note"]:
			(slot[key] as Control).visible = committed
		slot.choose.visible = not committed
		slot.empty_note.visible = not committed
		slot.choose.text = tr("SHOE_CHOOSE_CARD") if index == 0 else tr("SHOE_ADD_CARD")
		slot.choose.tooltip_text = tr("SHOE_PICK_TERMS")
		slot.choose.disabled = _working or index > shoe.selected_card_ids.size() or shoe.eligible_cards().is_empty()
		slot.empty_note.text = tr("SHOE_PICK_TERMS") if index == 0 else tr("SHOE_SECOND_OPTIONAL")
		for kind in ["rank", "suit"]:
			var button: Button = slot[kind]
			var cost := shoe.rank_cost() if kind == "rank" else shoe.suit_cost()
			button.text = tr("SHOE_REROLL_" + kind.to_upper()) + "\n" + VndWallet.format_vnd(-cost)
			button.disabled = _working or not shoe.can_reroll(id, kind)
			var error := shoe.reroll_error(id, kind)
			button.tooltip_text = tr(error) if not error.is_empty() else tr("SHOE_PRICE_RULE")
		if card == null:
			if committed: slot.properties.text = tr("SHOE_ERROR_MISSING")
			continue
		slot.face.texture = load(card.texture_path())
		GieoCardFX.attach_texture(slot.face, card)
		slot.face.tooltip_text = card.inspection_text()
		for child in slot.badge.get_children():
			slot.badge.remove_child(child)
			child.queue_free()
		slot.badge.add_child(CardSymbolArt.create_card_badge(card, 28))
		var labels: Array[String] = [tr("CARD_FORTUNE") + " " + card.fortune_label()]
		if card.fortune > 0: labels.append(tr("CARD_GOLD"))
		elif card.fortune < 0: labels.append(tr("CARD_BLACK_INK"))
		if not card.jackpot_state().is_empty(): labels.append(tr(CardData.property_label_key(card.jackpot_state())))
		if card.shiny: labels.append(tr("CARD_SHINY"))
		slot.properties.text = " · ".join(labels)
		slot.properties.tooltip_text = card.inspection_text()
	_refresh_receipt()
	_status.visible = shoe.last_reroll.is_empty()
	if _status.visible: _status.text = tr("SHOE_READY") if not shoe.selected_card_ids.is_empty() else tr("SHOE_SELECT_FIRST")

func _refresh_receipt() -> void:
	for child in _receipt.get_children():
		_receipt.remove_child(child)
		child.queue_free()
	_receipt.visible = not shoe.last_reroll.is_empty()
	if not _receipt.visible: return
	var result := shoe.last_reroll
	_receipt.add_child(CardSymbolArt.create_card_badge(CardData.from_permanent_snapshot(result.before), 25))
	var arrow := Label.new()
	arrow.text = "→"
	PresentationTheme.style_text(arrow, &"body", 25)
	_receipt.add_child(arrow)
	_receipt.add_child(CardSymbolArt.create_card_badge(CardData.from_permanent_snapshot(result.after), 25))
	var paid := Label.new()
	paid.text = VndWallet.format_vnd(-int(result.cost_vnd))
	PresentationTheme.style_text(paid, &"cost", 17)
	_receipt.add_child(paid)

func _pick() -> void:
	if _working or shoe.eligible_cards().is_empty(): return
	card_pick_requested.emit(shoe.eligible_cards(), tr("SHOE_PICK_TERMS"), _choose_card)

func _choose_card(id: String) -> void:
	var result := shoe.choose_card(id)
	_refresh()
	if not result.ok:
		_status.text = tr(result.error)
		_status.show()
		return
	feedback_requested.emit(&"transition")
	dialogue_requested.emit(tr("SHOE_CARD_TAKEN"))
	# A chosen slot is immediately permanent for the visit; no swap/reset UI.

func _reroll(index: int, kind: String) -> void:
	if _working or index >= shoe.selected_card_ids.size(): return
	var id := shoe.selected_card_ids[index]
	_working = true
	var result := shoe.reroll_rank(id) if kind == "rank" else shoe.reroll_suit(id)
	_refresh()
	if not result.ok:
		_working = false
		_refresh()
		_status.text = tr(result.error)
		_status.show()
		feedback_requested.emit(&"reject")
		return
	wallet_changed.emit()
	feedback_requested.emit(&"reel_stop")
	dialogue_requested.emit(tr("SHOE_WALLET_EMPTY") if shoe.wallet.balance_vnd < mini(shoe.rank_cost(), shoe.suit_cost()) else tr("SHOE_ONE_MORE"))
	_animate_work(index)

func _animate_work(index: int) -> void:
	var slot: Dictionary = _slots[index]
	var art: Control = slot.art
	var wipe: ColorRect = slot.wipe
	var origin := Vector2(20, 34)
	wipe.position.y = 0
	wipe.show()
	_work_tween = create_tween()
	_work_tween.set_parallel(true)
	_work_tween.tween_property(art, "position", origin + Vector2(-9, -8), 0.10).set_trans(Tween.TRANS_QUAD)
	_work_tween.tween_property(art, "rotation", -0.07, 0.10)
	_work_tween.chain().tween_property(wipe, "position:y", 148.0, 0.20)
	_work_tween.parallel().tween_property(art, "rotation", 0.045, 0.10)
	_work_tween.chain().tween_callback(wipe.hide)
	_work_tween.chain().tween_property(art, "position", origin, 0.16).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_work_tween.parallel().tween_property(art, "rotation", 0.0, 0.16)
	_work_tween.chain().tween_callback(func():
		_working = false
		_refresh()
		feedback_requested.emit(&"gain"))

func _notification(what: int) -> void:
	if what == NOTIFICATION_TRANSLATION_CHANGED and is_node_ready() and shoe != null: _queue_refresh()