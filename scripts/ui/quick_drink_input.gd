extends Node
## Pointer gestures share the same DealState validators as click actions.
var ui: MatchUI
var source: Dictionary = {}
var press_position := Vector2.ZERO
var dragging := false
var preview: TextureRect

func _ready() -> void:
	ui = get_parent() as MatchUI

func _input(event: InputEvent) -> void:
	if ui == null:
		return
	if get_tree().root.has_node("GameGlossary") or not ui.game_started or ui.tutorial_active or ui.interaction_locked or ui.menu_layer.visible or ui.modal_overlay.visible:
		cancel()
		return
	if event is InputEventKey and event.is_action_pressed(&"ui_cancel") and not source.is_empty():
		cancel()
		get_viewport().set_input_as_handled()
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed and ui.active_drag_payload == null and ui.deal.current_drink_has_charge():
			source = _source_at(event.position)
			if not source.is_empty():
				press_position = event.position
				get_viewport().set_input_as_handled()
		elif not event.pressed and not source.is_empty():
			var pending := source.duplicate()
			var was_dragging := dragging
			cancel(false)
			get_viewport().set_input_as_handled()
			if was_dragging:
				_drop(pending, event.position)
			else:
				_click(pending)
	elif event is InputEventMouseMotion and not source.is_empty():
		if not dragging and event.position.distance_to(press_position) >= PlayingCardView.DRAG_THRESHOLD:
			dragging = true
			_begin_preview()
		if dragging:
			preview.position = ui._drag_layer_local_position(event.position) - preview.size * 0.5
		get_viewport().set_input_as_handled()

func _source_at(point: Vector2) -> Dictionary:
	var record := ui._drink_record_at(point)
	if record != null:
		return {"kind": "discard", "record": record, "archive": ui.discard_archive_overlay.visible}
	if ui.discard_archive_overlay.visible:
		return {}
	if ui._control_hit(ui.drink_table_button, point) and not ui.drink_table_button.disabled:
		return {"kind": "cup"}
	if ui.deal.current_drink_id in [DrinkCatalog.NUOC_VOI, DrinkCatalog.NAU_DA]:
		for meld in ui.deal.melds:
			var view := ui.meld_views.get(meld.meld_id) as MeldView
			if not ui._control_hit(view, point): continue
			for card in meld.cards:
				if ui._control_hit(view.get_scoring_card_control(card.unique_id), point):
					return {"kind": "meld", "meld_id": meld.meld_id, "card": card}
			return {"kind": "meld", "meld_id": meld.meld_id, "card": meld.cards[0]}
	return {}

func _begin_preview() -> void:
	if source.get("archive", false):
		ui._hide_discard_archive()
	preview = TextureRect.new()
	preview.name = "DrinkDragPreview"
	preview.mouse_filter = Control.MOUSE_FILTER_IGNORE
	preview.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	preview.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	preview.size = Vector2(72, 100)
	preview.modulate.a = 0.85
	preview.z_index = 20
	if source["kind"] == "cup":
		preview.texture = ui.drink_table_texture.texture
		preview.modulate = ui.drink_table_texture.modulate
		for card_id in ui._drink_hand_eligible_card_ids():
			var view := ui.hand_views.get(card_id) as Control
			if view != null: ui._add_card_drag_target_overlay(view.get_global_rect(), CardActionOutline.DRINK_HIGHLIGHT)
		for meld in ui.deal.melds:
			var view := ui.meld_views.get(meld.meld_id) as MeldView
			if view == null: continue
			for card in meld.cards:
				if ui.deal.can_use_nuoc_voi(meld.meld_id, card) or ui.deal.can_use_nau_da(meld.meld_id):
					ui._add_card_drag_target_overlay(view.card_global_rect(card.unique_id), CardActionOutline.DRINK_HIGHLIGHT)
	else:
		var card: CardData = source["record"].card if source["kind"] == "discard" else source.get("card") as CardData
		if card != null: preview.texture = load(card.texture_path()) as Texture2D
		ui._add_card_drag_target_overlay(ui.hand_layer.get_global_rect(), CardActionOutline.DRINK_HIGHLIGHT)
	ui.particle_layer.add_child(preview)
	ui.ui_feedback.play(&"press", 0.7)

func cancel(restore_archive: bool = true) -> void:
	var reopen := restore_archive and dragging and bool(source.get("archive", false))
	source.clear()
	if dragging:
		ui._clear_card_drag_target_overlays()
	dragging = false
	if is_instance_valid(preview): preview.queue_free()
	preview = null
	if reopen and ui.is_inside_tree() and not ui.menu_layer.visible:
		ui._show_discard_archive()

func _click(from: Dictionary) -> void:
	match from["kind"]:
		"cup": ui._on_drink_pressed()
		"discard":
			ui.drink_targeting_active = true
			# Reuse a selected loose card if the player chose it first.
			var cards := ui._selected_cards()
			if cards.size() == 1:
				ui.pending_drink_card_ids.clear()
				ui.pending_drink_card_ids[cards[0].unique_id] = true
			ui._on_drink_discard_targeted(from["record"])
		"meld":
			if ui.drink_targeting_active and from.has("card"):
				ui._on_meld_card_pressed(int(from["meld_id"]), from["card"])
			else:
				ui._on_meld_pressed(int(from["meld_id"]))

func _hand_card_at(point: Vector2) -> CardData:
	var chosen: CardData
	var highest := -999
	for card in ui.deal.hand:
		var view := ui.hand_views.get(card.unique_id) as PlayingCardView
		if ui._control_hit(view, point) and view.z_index >= highest:
			highest = view.z_index
			chosen = card
	return chosen

func _drop(from: Dictionary, point: Vector2) -> void:
	if not ui.deal.current_drink_has_charge(): return
	if from["kind"] == "meld":
		if ui._control_hit(ui.hand_layer, point) or ui._control_hit(ui.drink_table_button, point):
			var id := int(from["meld_id"])
			if ui.deal.can_use_nau_da(id):
				ui._finish_drink_use(ui.deal.use_nau_da(id))
				return
			var card := from.get("card") as CardData
			if ui.deal.can_use_nuoc_voi(id, card):
				ui._finish_drink_use(ui.deal.use_nuoc_voi(id, card))
				return
	elif from["kind"] == "discard":
		var card := _hand_card_at(point)
		if card != null and ui._try_drink_card_drop([card] as Array[CardData], {"kind": &"drink_discard", "record": from["record"]}):
			return
	elif from["kind"] == "cup":
		var target := _source_at(point)
		if target.get("kind") == "meld":
			var id := int(target["meld_id"])
			if ui.deal.can_use_nau_da(id):
				ui._finish_drink_use(ui.deal.use_nau_da(id))
				return
			var card := target.get("card") as CardData
			if ui.deal.can_use_nuoc_voi(id, card):
				ui._finish_drink_use(ui.deal.use_nuoc_voi(id, card))
				return
		if target.get("kind") == "discard":
			_click(target)
			return
		var card := _hand_card_at(point)
		if card != null:
			var cards: Array[CardData] = ui._pending_drink_cards() if ui.drink_targeting_active else ui._selected_cards()
			if not cards.has(card): cards = [card]
			if ui._commit_selected_drink(cards): return
			if ui.deal.drink_creation_target_ids([]).has(card.unique_id):
				ui.drink_targeting_active = true
				ui.pending_drink_card_ids.clear()
				ui.pending_drink_card_ids[card.unique_id] = true
				ui._sync_all()
				return
	ui.ui_feedback.play(&"reject")
	if from.get("archive", false): ui._show_discard_archive()

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_WINDOW_FOCUS_OUT and ui != null:
		cancel()
