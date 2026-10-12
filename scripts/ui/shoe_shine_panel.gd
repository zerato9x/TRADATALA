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
var _rank_button: Button
var _suit_button: Button
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
	_rank_button = _button(self, "TransformPairRank", Vector2(0, 333), Vector2(344, 64), "gold")
	_rank_button.pressed.connect(_reroll.bind("rank"))
	_suit_button = _button(self, "TransformPairSuit", Vector2(356, 333), Vector2(344, 64), "tea")
	_suit_button.pressed.connect(_reroll.bind("suit"))
	_status = _label(self, "", Vector2(0, 34), Vector2(700, 24), 15, PresentationTheme.TEA)
	_status.name = "BenchStatus"
	_status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

func _build_slot(index: int) -> void:
	var mat := Panel.new()
	mat.name = "CardMat_%d" % index
	mat.position = Vector2(index * 356, 66)
	mat.size = Vector2(344, 258)
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
	var result_title := _label(mat, "", Vector2(145, 62), Vector2(190, 24), 13, PresentationTheme.TEA)
	result_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var receipt := HBoxContainer.new()
	receipt.name = "IdentityReceipt_%d" % index
	receipt.position = Vector2(148, 94)
	receipt.size = Vector2(182, 44)
	receipt.alignment = BoxContainer.ALIGNMENT_CENTER
	receipt.add_theme_constant_override("separation", 8)
	receipt.mouse_filter = Control.MOUSE_FILTER_IGNORE
	mat.add_child(receipt)
	var independent := _label(mat, "", Vector2(145, 150), Vector2(190, 25), 13, PresentationTheme.MUTED)
	independent.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var note := _label(mat, tr("SHOE_PERMANENT"), Vector2(145, 201), Vector2(190, 28), 13, PresentationTheme.MUTED)
	note.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var properties := _label(mat, "", Vector2(14, 235), Vector2(315, 20), 13, PresentationTheme.INK)
	properties.name = "CardProperties"
	properties.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var choose := _button(mat, "ChooseCard_%d" % index, Vector2(16, 70), Vector2(312, 94), "neutral")
	choose.pressed.connect(_pick)
	var empty_note := _label(mat, "", Vector2(24, 174), Vector2(296, 75), 16, PresentationTheme.MUTED)
	empty_note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	empty_note.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_slots.append({"mat": mat, "caption": caption, "art": art, "face": face, "wipe": wipe, "shadow": shadow,
		"badge": badge, "receipt": receipt, "result_title": result_title, "independent": independent, "properties": properties,
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
		for key in ["art", "badge", "shadow", "properties", "stamp", "note", "independent"]:
			(slot[key] as Control).visible = committed
		slot.choose.visible = not committed
		slot.empty_note.visible = not committed
		slot.choose.text = tr("SHOE_CHOOSE_CARD") if index == 0 else tr("SHOE_ADD_CARD")
		slot.choose.tooltip_text = tr("SHOE_PICK_TERMS")
		slot.choose.disabled = _working or index > shoe.selected_card_ids.size() or shoe.eligible_cards().is_empty()
		slot.empty_note.text = tr("SHOE_PICK_TERMS") if index == 0 else tr("SHOE_SECOND_REQUIRED")
		slot.independent.text = tr("SHOE_INDEPENDENT")
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
	for kind in ["rank", "suit"]:
		var button := _rank_button if kind == "rank" else _suit_button
		var cost := shoe.rank_cost() if kind == "rank" else shoe.suit_cost()
		button.text = tr("SHOE_REROLL_" + kind.to_upper()) + "\n" + VndWallet.format_vnd(-cost)
		button.disabled = _working or not shoe.can_reroll(kind)
		var error := shoe.reroll_error(kind)
		button.tooltip_text = tr(error) if not error.is_empty() else tr("SHOE_PRICE_RULE")
	_refresh_receipts()
	_status.visible = shoe.last_reroll.is_empty()
	_uses.visible = not _status.visible
	if _status.visible:
		_status.text = tr("SHOE_READY") if shoe.selected_card_ids.size() == ShoeShineConfig.MAX_SELECTED_CARDS else tr("SHOE_SELECT_FIRST" if shoe.selected_card_ids.is_empty() else "SHOE_ERROR_PAIR")

func _refresh_receipts() -> void:
	# Each mat shows its own outcome, never the other card's receipt.
	var results: Array = shoe.last_reroll.get("results", [])
	if shoe.last_reroll.has("card_id"): results = [shoe.last_reroll] # Older single-card receipts.
	for slot in _slots:
		var receipt: HBoxContainer = slot.receipt
		for child in receipt.get_children():
			receipt.remove_child(child)
			child.queue_free()
		var result: Dictionary = {}
		for candidate in results:
			if candidate.card_id == slot.mat.get_meta("physical_card_id"): result = candidate
		receipt.visible = not result.is_empty()
		slot.result_title.visible = receipt.visible
		if not receipt.visible: continue
		slot.result_title.text = tr("SHOE_RESULT_" + String(shoe.last_reroll.kind).to_upper())
		receipt.set_meta("physical_card_id", result.card_id)
		receipt.add_child(CardSymbolArt.create_card_badge(CardData.from_permanent_snapshot(result.before), 25))
		var arrow := Label.new()
		arrow.text = "→"
		PresentationTheme.style_text(arrow, &"body", 25)
		receipt.add_child(arrow)
		receipt.add_child(CardSymbolArt.create_card_badge(CardData.from_permanent_snapshot(result.after), 25))

func _pick() -> void:
	if _working or shoe.eligible_cards().is_empty(): return
	card_pick_requested.emit(shoe.eligible_cards(), tr("SHOE_PICK_TERMS"), _choose_card)

func _choose_card(id: String) -> void:
	var result := shoe.choose_card(id)
	_refresh()
	if not result.ok:
		_status.text = tr(result.error)
		_status.show()
		_uses.hide()
		return
	feedback_requested.emit(&"transition")
	dialogue_requested.emit(tr("SHOE_READY" if shoe.selected_card_ids.size() == ShoeShineConfig.MAX_SELECTED_CARDS else "SHOE_CARD_TAKEN"))
	# A chosen slot is immediately permanent for the visit; no swap/reset UI.

func _reroll(kind: String) -> void:
	if _working: return
	_working = true
	var result := shoe.reroll_rank() if kind == "rank" else shoe.reroll_suit()
	_refresh()
	if not result.ok:
		_working = false
		_refresh()
		_status.text = tr(result.error)
		_status.show()
		_uses.hide()
		feedback_requested.emit(&"reject")
		return
	wallet_changed.emit()
	feedback_requested.emit(&"reel_stop")
	dialogue_requested.emit(tr("SHOE_WALLET_EMPTY") if shoe.wallet.balance_vnd < mini(shoe.rank_cost(), shoe.suit_cost()) else tr("SHOE_ONE_MORE"))
	_animate_work()

func _animate_work() -> void:
	var origin := Vector2(20, 34)
	_work_tween = create_tween()
	_work_tween.set_parallel(true)
	for slot in _slots:
		var art: Control = slot.art
		var wipe: ColorRect = slot.wipe
		wipe.position.y = 0
		wipe.show()
		_work_tween.tween_property(art, "position", origin + Vector2(-9, -8), 0.10).set_trans(Tween.TRANS_QUAD)
		_work_tween.tween_property(art, "rotation", -0.07, 0.10)
		_work_tween.tween_property(wipe, "position:y", 148.0, 0.20).set_delay(0.10)
		_work_tween.tween_callback(wipe.hide).set_delay(0.30)
		_work_tween.tween_property(art, "position", origin, 0.16).set_delay(0.30).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		_work_tween.tween_property(art, "rotation", 0.0, 0.16).set_delay(0.30)
	_work_tween.chain().tween_callback(func():
		_working = false
		_refresh()
		feedback_requested.emit(&"gain"))

func _notification(what: int) -> void:
	if what == NOTIFICATION_TRANSLATION_CHANGED and is_node_ready() and shoe != null: _queue_refresh()
