class_name CardTablePresentation
extends Node
## Owns keyed card views and their visual lifecycles. Commands return as intent.
signal card_pressed(card: CardData)
signal card_drag_started(card: CardData, point: Vector2, source: PlayingCardView)
signal meld_pressed(meld_id: int)
signal meld_card_pressed(meld_id: int, card: CardData)
signal discard_pressed(record: DiscardRecord)
const CARD_SIZE := PlayingCardView.CARD_SIZE
const MUSIC_BAND_COUNT := 4
const CARD_ACTION_OUTLINE_SCRIPT := preload("res://scripts/ui/card_action_outline.gd")
const DROP_TARGET_NONE := MatchInteraction.DROP_TARGET_NONE
const DROP_TARGET_HAND := MatchInteraction.DROP_TARGET_HAND
const DROP_TARGET_TABLE := MatchInteraction.DROP_TARGET_TABLE
const DROP_TARGET_MELD := MatchInteraction.DROP_TARGET_MELD
const DROP_TARGET_DISCARD := MatchInteraction.DROP_TARGET_DISCARD
var particle_layer: Control
var table_surface: Control
var discard_pile_visual: Control
var drink_table_button: Button
var active_drag_source: PlayingCardView
var drag_preview: Control
var drag_target_overlays: Array[Control] = []
var _active := false
var _deal_ref: WeakRef
var deal: DealState:
	get: return _deal_ref.get_ref() as DealState
var interactions: MatchInteraction
var hand_views: Dictionary = {}
var meld_views: Dictionary = {}
var discard_history_target_outlines: Dictionary = {}
var discard_history_target_holders: Dictionary = {}
var reactive_hand_cards_by_band: Dictionary = {}
var reactive_meld_cards_by_band: Dictionary = {}
var hand_layer: Control
var draw_pile_visual: Control
var meld_row: HBoxContainer
var empty_meld_label: Label
var draw_count: Label
var discard_count_label: Label
var discard_texture: TextureRect
var discard_history_row: HBoxContainer
var discard_history_title: Label

func configure(owner_deal: DealState, owner_interactions: MatchInteraction, views: Dictionary) -> void:
	_active = true
	_deal_ref = weakref(owner_deal)
	interactions = owner_interactions
	hand_layer = views.hand_layer
	draw_pile_visual = views.draw_pile_visual
	meld_row = views.meld_row
	empty_meld_label = views.empty_meld_label
	draw_count = views.draw_count
	discard_count_label = views.discard_count_label
	discard_texture = views.discard_texture
	discard_history_row = views.discard_history_row
	discard_history_title = views.discard_history_title
	particle_layer = views.particle_layer
	table_surface = views.table_surface
	discard_pile_visual = views.discard_pile_visual
	drink_table_button = views.drink_table_button

func play_beat_pulse(band: int, strength: float, emphasize_drink: bool) -> void:
	if not _active: return
	for hand_view in reactive_hand_cards_by_band.get(band, []):
		if is_instance_valid(hand_view): hand_view.play_beat_pulse(strength)
	for assignment: Dictionary in reactive_meld_cards_by_band.get(band, []):
		var view := assignment.get("view") as MeldView
		if is_instance_valid(view): view.play_card_beat_pulse(String(assignment.get("card_id", "")), strength)
	if emphasize_drink: pulse_drink_targets(strength)

func _exit_tree() -> void:
	_active = false
	clear_drag_visuals()
	for view: PlayingCardView in hand_views.values():
		if not is_instance_valid(view): continue
		view.set_interaction_enabled(false)
		view.card_pressed.disconnect(card_pressed.emit)
		view.card_drag_started.disconnect(card_drag_started.emit.bind(view))
	for view: MeldView in meld_views.values():
		if not is_instance_valid(view): continue
		view.meld_pressed.disconnect(meld_pressed.emit)
		view.meld_card_pressed.disconnect(meld_card_pressed.emit)
	for holder: Control in discard_history_target_holders.values():
		if not is_instance_valid(holder): continue
		holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
		for connection: Dictionary in holder.gui_input.get_connections():
			var callback: Callable = connection.callable
			if callback.get_object() == self: holder.gui_input.disconnect(callback)
	hand_views.clear()
	meld_views.clear()
	discard_history_target_outlines.clear()
	discard_history_target_holders.clear()
	reactive_hand_cards_by_band.clear()
	reactive_meld_cards_by_band.clear()


func sync_hand(animated_cards: Array[CardData]) -> void:
	if not _active: return
	var active_ids := {}
	var animated_ids := {}
	for card in animated_cards:
		animated_ids[card.unique_id] = true
	for card in deal.hand:
		active_ids[card.unique_id] = true
		var view := hand_views.get(card.unique_id) as PlayingCardView
		var is_new := view == null
		if is_new:
			view = PlayingCardView.new()
			hand_layer.add_child(view)
			view.card_pressed.connect(card_pressed.emit)
			view.card_drag_started.connect(card_drag_started.emit.bind(view))
			hand_views[card.unique_id] = view
		view.set_card(card)
		view.set_zodiac_locked(deal.zodiac_boss.is_locked(card))
		view.set_zodiac_hint(preload("res://scripts/ui/zodiac_presentation.gd").hand_hint(deal.zodiac_boss, card, deal.hand))
		if is_new and animated_ids.has(card.unique_id):
			var origin := draw_pile_visual.get_global_rect().get_center() - hand_layer.global_position
			view.spawn_from(origin)
	for existing_id in hand_views.keys():
		if not active_ids.has(existing_id):
			var old_view: PlayingCardView = hand_views[existing_id]
			old_view.set_interaction_enabled(false)
			old_view.hide()
			old_view.queue_free()
			hand_views.erase(existing_id)
	layout_hand(true)


func sync_probabilities() -> void:
	if not _active: return
	var draw_pool := deal.queries.probability_draw_pool()
	var draw_number := deal.queries.probability_draw_horizon()
	var best_by_card := MeldProbabilityAdvisor.best_new_meld_chance_by_card(deal.hand, draw_pool, draw_number)
	for card in deal.hand:
		var view: PlayingCardView = hand_views.get(card.unique_id)
		if view == null:
			continue
		var candidate: Dictionary = best_by_card.get(card.unique_id, {})
		if candidate.is_empty():
			view.set_meld_chance(0.0, false, tr("PROBABILITY_NO_TARGET"), "—", draw_number)
			continue
		var needed_text := "—" if candidate["needed_labels"].is_empty() else " / ".join(candidate["needed_labels"])
		view.set_meld_chance(
			float(candidate["probability"]),
			bool(candidate["ready"]),
			AdvisoryText.localized_label(candidate),
			needed_text,
			draw_number
		)


func sync_action_outlines() -> Dictionary:
	if not _active: return {}
	var actionable := deal.queries.legal_action_card_ids()
	var meld_card_ids: Dictionary = actionable["meld"]
	var extension_card_ids: Dictionary = actionable["extend"]
	var drink_eligible_card_ids := interactions.drink_hand_eligible_card_ids()
	for card in deal.hand:
		var view: PlayingCardView = hand_views.get(card.unique_id)
		if view != null:
			var drink_marked := deal.sam_dua_preserved_cards.has(card) or interactions.drink_ids.has(card.unique_id)
			var drink_eligible := drink_eligible_card_ids.has(card.unique_id)
			if deal.current_drink_id in [DrinkCatalog.NHAN_TRAN, DrinkCatalog.DEN_DA]: drink_marked = drink_marked and drink_eligible
			view.set_action_cues(
				meld_card_ids.has(card.unique_id),
				extension_card_ids.has(card.unique_id),
				drink_marked or drink_eligible,
				drink_marked or (interactions.drink_targeting and drink_eligible)
			)
	return actionable


func layout_hand(animate: bool) -> void:
	if not _active: return
	if hand_layer == null or hand_layer.size.x <= 0:
		return
	var count := deal.hand.size()
	if count == 0:
		return
	var spacing := 0.0
	if count > 1:
		spacing = minf(76.0, maxf((hand_layer.size.x - CARD_SIZE.x - 34.0) / float(count - 1), 1.0))
	var total_width := CARD_SIZE.x + spacing * float(count - 1)
	var start_x := (hand_layer.size.x - total_width) * 0.5
	for index in range(count):
		var card := deal.hand[index]
		var view: PlayingCardView = hand_views[card.unique_id]
		var normalized := 0.0 if count == 1 else (float(index) / float(count - 1) - 0.5) * 2.0
		var arc_y := 9.0 + normalized * normalized * 14.0
		view.set_stack_order(index)
		view.drag_enabled = true
		view.layout_in_hand(Vector2(start_x + spacing * index, arc_y), normalized * 0.055,
			interactions.drink_ids.has(card.unique_id) if interactions.drink_targeting else interactions.selected_ids.has(card.unique_id), animate)


func sync_melds() -> void:
	if not _active: return
	empty_meld_label.visible = deal.melds.is_empty()
	var active_meld_ids := {}
	for meld in deal.melds:
		active_meld_ids[meld.meld_id] = true
	for existing_id in meld_views.keys():
		if active_meld_ids.has(existing_id):
			continue
		var stale_view := meld_views[existing_id] as MeldView
		if stale_view != null:
			meld_row.remove_child(stale_view)
			stale_view.queue_free()
		meld_views.erase(existing_id)
	interactions.reconcile_meld_targets()
	if deal.melds.is_empty(): return
	var selected_cards := interactions.selected_cards()
	for index in range(deal.melds.size()):
		var meld := deal.melds[index]
		var view: MeldView = meld_views.get(meld.meld_id)
		var is_new := view == null
		if is_new:
			view = MeldView.new()
			meld_row.add_child(view)
			meld_views[meld.meld_id] = view
			view.meld_pressed.connect(meld_pressed.emit)
			view.meld_card_pressed.connect(meld_card_pressed.emit)
		elif view.get_index() != index:
			meld_row.move_child(view, index)
		var legal := deal.can_extend_meld(meld.meld_id, selected_cards)
		var drink_highlight_enabled := interactions.drink_preview_active() and deal.current_drink_id in [DrinkCatalog.NUOC_VOI, DrinkCatalog.NAU_DA] and deal.current_drink_has_charge() and deal.state in [DealState.STATE_ACTIVE, DealState.STATE_FINAL_COMMIT_WINDOW]
		var drink_selection_enabled := interactions.drink_targeting and drink_highlight_enabled
		var removable_card_ids := {}
		if drink_highlight_enabled:
			for table_card in meld.cards:
				if deal.can_use_nuoc_voi(meld.meld_id, table_card) or deal.can_use_nau_da(meld.meld_id):
					removable_card_ids[table_card.unique_id] = true
		view.set_meld(
			meld,
			meld.meld_id == interactions.selected_meld_id,
			legal,
			drink_highlight_enabled,
			drink_selection_enabled,
			removable_card_ids,
			interactions.drink_meld_card_id if interactions.drink_meld_id == meld.meld_id else "",
			deal.vnd_per_point,
			deal.current_drink_id == DrinkCatalog.NAU_DA
		)
		view.set_boss_payout_suppressed(deal.zodiac_boss.suppresses(deal.current_phase))
		var boss_effect: Dictionary = preload("res://scripts/ui/zodiac_presentation.gd").effective(deal.zodiac_boss)
		view.set_dog_loyal(boss_effect.get("id", "") == "dog" and meld.meld_id == int(boss_effect.get("loyal_meld_id", -1)))
		if not is_new:
			continue
		view.modulate = Color(1, 1, 1, 0)
		view.scale = Vector2(0.94, 0.94)
		var tween := view.create_tween().set_parallel(true)
		tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tween.tween_property(view, "modulate", Color.WHITE, 0.18)
		tween.tween_property(view, "scale", Vector2.ONE, 0.2)


func sync_piles() -> void:
	if not _active: return
	draw_count.text = tr("PILE_COUNT") % deal.deck.draw_pile.size()
	discard_count_label.text = tr("PILE_COUNT") % deal.deck.discard_pile.size()
	if deal.deck.discard_pile.is_empty():
		discard_texture.texture = load("res://cards/red_backing.png") as Texture2D
		GieoCardFX.apply_state(discard_texture, 0, false, false)
		discard_texture.modulate = Color(1, 1, 1, 0.12)
	else:
		discard_texture.texture = load(deal.deck.discard_pile[-1].texture_path()) as Texture2D
		GieoCardFX.attach_texture(discard_texture, deal.deck.discard_pile[-1])
		discard_texture.modulate = Color.WHITE
	var claws := discard_texture.get_node_or_null("TigerClaws") as ColorRect
	var effect: Dictionary = preload("res://scripts/ui/zodiac_presentation.gd").effective(deal.zodiac_boss)
	var snatched: bool = effect.get("id", "") == "tiger" and not deal.deck.discard_pile.is_empty() and deal.deck.discard_pile[-1].unique_id in effect.get("removed_ids", [])
	if snatched and claws == null:
		claws = ColorRect.new()
		claws.name = "TigerClaws"
		claws.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		claws.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var ink := ShaderMaterial.new()
		ink.shader = preload("res://shaders/tiger_claws.gdshader")
		claws.material = ink
		discard_texture.add_child(claws)
	if claws != null: claws.visible = snatched


func sync_discard_history() -> void:
	if not _active: return
	discard_history_target_outlines.clear()
	discard_history_target_holders.clear()
	for child in discard_history_row.get_children():
		discard_history_row.remove_child(child)
		child.queue_free()
	discard_history_title.text = ZodiacCatalog.words("TURNS · PHASE %d", "LƯỢT · HIỆP %d") % deal.current_phase
	if deal.zodiac_boss.id == "rooster":
		var deadline := int(ZodiacCatalog.tuning("rooster", "discard_deadline", deal.zodiac_boss.difficulty))
		discard_history_title.text += ZodiacCatalog.words(" · CLOSE AFTER DISCARD %d", " · CHỐT SAU LẦN BỎ %d") % deadline
	for phase_number in [1, 2]:
		var records := deal.discard_history_for_phase(phase_number)
		var phase_label := Label.new()
		phase_label.text = tr("HUD_PHASE_SHORT") % phase_number
		phase_label.custom_minimum_size = Vector2(16, 58)
		phase_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		phase_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		phase_label.add_theme_font_size_override("font_size", 10)
		phase_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		phase_label.add_theme_color_override("font_color", PresentationTheme.GOLD if phase_number == deal.current_phase else PresentationTheme.MUTED)
		discard_history_row.add_child(phase_label)
		var by_number := {}
		for record in records:
			by_number[record.discard_number] = record
		var count := deal.phase_discard_limit(phase_number)
		for number in range(1, count + 1):
			var record := by_number.get(number) as DiscardRecord
			var holder := _build_discard_thumbnail(record) if record != null else _build_empty_turn_slot()
			holder.name = "Phase%dTurn%d" % [phase_number, number]
			holder.set_meta("turn_phase", phase_number)
			holder.set_meta("turn_number", number)
			holder.set_meta("turn_filled", record != null)
			var modifier: String = preload("res://scripts/ui/zodiac_card_fx.gd").turn_modifier(deal.zodiac_boss, phase_number, number)
			holder.set_meta("turn_modifier", modifier)
			var active: bool = phase_number == deal.current_phase and number == deal.discard_count + 1 and deal.state == DealState.STATE_ACTIVE
			holder.set_meta("turn_active", active)
			var frame := Panel.new()
			frame.name = "TurnFrame"
			frame.position = Vector2(-2, -2)
			frame.size = Vector2(44, 62)
			frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
			var accent := PresentationTheme.RED if not modifier.is_empty() else PresentationTheme.GOLD if active else Color("61778f")
			frame.add_theme_stylebox_override("panel", PresentationTheme.panel_style(Color.TRANSPARENT, Color(accent, 0.9 if active or not modifier.is_empty() else 0.3), 1, 3))
			holder.add_child(frame)
			if not modifier.is_empty():
				var aura: ColorRect = preload("res://scripts/ui/zodiac_card_fx.gd").aura(holder, Vector2(40, 58), Color("ff574f"), float(number), 9)
				aura.name = "RoosterRegisterAura"
				holder.move_child(aura, 0)
				holder.tooltip_text += "\n" + (ZodiacCatalog.words("Register closes after this discard.", "Chốt sổ sau lần bỏ này.") if modifier == "closing" else ZodiacCatalog.words("Register closed: legal scoring pays 0 VNĐ in Phase 1.", "Sổ đã đóng: ghi điểm hợp lệ trả 0 VNĐ trong Hiệp 1."))
			var badge: Label = holder.get_node("TurnNumber")
			badge.text = str(number) + (" ×" if modifier == "closing" else " · 0" if modifier == "closed" else "")
			badge.add_theme_color_override("font_color", Color("ffb4aa") if not modifier.is_empty() else PresentationTheme.INK)
			if active:
				var current := Label.new()
				current.name = "CurrentTurn"
				current.set_anchors_preset(Control.PRESET_TOP_WIDE)
				current.offset_bottom = 13
				current.text = ZodiacCatalog.words("NOW", "HIỆN TẠI")
				current.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
				current.mouse_filter = Control.MOUSE_FILTER_IGNORE
				current.add_theme_font_size_override("font_size", 8)
				current.add_theme_color_override("font_color", PresentationTheme.GOLD)
				current.add_theme_stylebox_override("normal", PresentationTheme.panel_style(Color("101722df")))
				holder.add_child(current)
			discard_history_row.add_child(holder)
	sync_discard_targets()


func sync_discard_targets() -> void:
	if not _active: return
	var target_keys := {}
	for opportunity in interactions.drink_swap_opportunities():
		target_keys[opportunity.record.target_key()] = true
	set_discard_eligibility(target_keys, interactions.drink_targeting)


func set_discard_eligibility(target_keys: Dictionary, emphasized: bool = false) -> void:
	if not _active: return
	for target_key in discard_history_target_outlines:
		var outline := discard_history_target_outlines[target_key] as Control
		if outline != null:
			var eligible: bool = target_keys.has(target_key)
			var selected: bool = interactions.drink_discard_key == target_key
			outline.set_cues(false, false, eligible, emphasized and eligible)
			var holder := discard_history_target_holders.get(target_key) as Control
			if holder != null:
				holder.mouse_filter = Control.MOUSE_FILTER_STOP if eligible or selected else Control.MOUSE_FILTER_IGNORE
				holder.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND if eligible or selected else Control.CURSOR_ARROW
				holder.tooltip_text = tr("DRINK_DISCARD_TARGET_VALID") if eligible or selected else String(holder.get_meta("default_tooltip", ""))


func pulse_drink_targets(strength: float = 0.6) -> void:
	if not _active: return
	var hand_ids := interactions.drink_hand_eligible_card_ids()
	for card_id in hand_ids:
		var view := hand_views.get(card_id) as PlayingCardView
		if view != null:
			view.pulse_action_eligibility(strength)
	for meld_view_value in meld_views.values():
		var meld_view := meld_view_value as MeldView
		if meld_view != null:
			meld_view.pulse_drink_targets(strength)
	for outline_value in discard_history_target_outlines.values():
		var outline := outline_value as Control
		if outline != null and (outline.cue_mode() & CardActionOutline.CUE_DRINK) != 0:
			outline.play_target_pulse(strength)


func sync_reactive_targets() -> void:
	if not _active: return
	_reactive_assignments_clear()
	var selected := interactions.selected_cards()
	var targets := deal.queries.legal_action_targets_for_selection(selected, interactions.selected_meld_id)
	var hand_card_ids: Dictionary = targets.get("hand", {})
	var hand_assignment_index := 0
	for card in deal.hand:
		if not hand_card_ids.has(card.unique_id):
			continue
		var view := hand_views.get(card.unique_id) as PlayingCardView
		if view != null:
			reactive_hand_cards_by_band[hand_assignment_index % MUSIC_BAND_COUNT].append(view)
			hand_assignment_index += 1

	var table_meld_ids: Dictionary = targets.get("melds", {})
	for meld in deal.melds:
		if not table_meld_ids.has(meld.meld_id) and meld.cards.size() < (13 if meld.meld_type == MeldRules.TYPE_RUN else 12):
			continue
		var view := meld_views.get(meld.meld_id) as MeldView
		if view == null:
			continue
		for card_index in range(meld.cards.size()):
			var card: CardData = meld.cards[card_index]
			reactive_meld_cards_by_band[card_index % MUSIC_BAND_COUNT].append({
				"view": view,
				"card_id": card.unique_id,
			})


func _build_empty_turn_slot() -> Control:
	var holder := Control.new()
	holder.custom_minimum_size = Vector2(40, 58)
	holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var face := TextureRect.new()
	face.name = "TurnCard"
	face.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	face.texture = preload("res://cards/grey_backing.png")
	face.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	face.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	face.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	face.modulate = Color(0.2, 0.23, 0.29, 0.78)
	face.mouse_filter = Control.MOUSE_FILTER_IGNORE
	holder.add_child(face)
	var badge := _turn_number_badge()
	holder.add_child(badge)
	return holder


func _turn_number_badge() -> Label:
	var badge := Label.new()
	badge.name = "TurnNumber"
	badge.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	badge.offset_top = -16
	badge.offset_bottom = 0
	badge.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	badge.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	badge.add_theme_font_size_override("font_size", 11)
	badge.add_theme_stylebox_override("normal", PresentationTheme.panel_style(Color("101722d9"), Color.TRANSPARENT, 0, 2))
	badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return badge


func _build_discard_thumbnail(record: DiscardRecord) -> Control:
	var holder := Control.new()
	holder.custom_minimum_size = Vector2(40, 58)
	holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	holder.mouse_default_cursor_shape = Control.CURSOR_ARROW
	holder.tooltip_text = tr("HUD_DISCARD_TOOLTIP") % [record.phase, record.discard_number, record.card.short_label()]
	var gieo_descriptions := record.card.fortune_descriptions()
	if not gieo_descriptions.is_empty():
		holder.tooltip_text += "\n\nGIEO QUẺ\n" + "\n".join(gieo_descriptions)
	holder.set_meta("default_tooltip", holder.tooltip_text)
	holder.set_meta("action_target_kind", "mandatory_discard")
	holder.set_meta("action_target_card_id", record.card.unique_id)
	holder.gui_input.connect(_on_discard_history_gui_input.bind(record, holder))
	var texture := TextureRect.new()
	texture.name = "TurnCard"
	texture.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	texture.texture = load(record.card.texture_path()) as Texture2D
	GieoCardFX.attach_texture(texture, record.card)
	texture.add_child(preload("res://scripts/ui/passive_card_sway.gd").new())
	texture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	texture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	texture.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	texture.mouse_filter = Control.MOUSE_FILTER_IGNORE
	holder.add_child(texture)
	var outline := CARD_ACTION_OUTLINE_SCRIPT.new()
	outline.name = "ActionOutline"
	outline.position = Vector2(-4, -4)
	outline.size = Vector2(48, 66)
	outline.visible = false
	holder.add_child(outline)
	discard_history_target_outlines[record.target_key()] = outline
	var badge := _turn_number_badge()
	badge.text = str(record.discard_number)
	holder.add_child(badge)
	discard_history_target_holders[record.target_key()] = holder
	return holder


func _on_discard_history_gui_input(event: InputEvent, record: DiscardRecord, holder: Control) -> void:
	if not interactions.drink_targeting:
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		holder.accept_event()
		discard_pressed.emit(record)


func _reactive_assignments_clear() -> void:
	reactive_hand_cards_by_band.clear()
	reactive_meld_cards_by_band.clear()
	for band_index in range(MUSIC_BAND_COUNT):
		reactive_hand_cards_by_band[band_index] = []
		reactive_meld_cards_by_band[band_index] = []

func begin_drag(payload, source: PlayingCardView) -> void:
	if not _active: return
	clear_drag_visuals()
	active_drag_source = source
	_build_card_drag_preview(payload)
	_refresh_card_drag_targets(payload)

func update_drag(point: Vector2) -> void:
	if not _active or drag_preview == null or particle_layer == null: return
	drag_preview.position = drag_layer_local_position(point) - CARD_SIZE * 0.5

func clear_drag_visuals() -> PlayingCardView:
	var source := active_drag_source
	active_drag_source = null
	clear_drag_target_overlays()
	if is_instance_valid(drag_preview):
		drag_preview.hide()
		drag_preview.queue_free()
	drag_preview = null
	if is_instance_valid(source):
		source.finish_drag_interaction()
		return source
	return null

func drink_record_at(point: Vector2) -> DiscardRecord:
	if not _active or not deal.current_drink_has_charge(): return null
	for record in deal.drink_mandatory_discard_targets():
		var holder := discard_history_target_holders.get(record.target_key()) as Control
		if InputHitTest.contains(holder, point): return record
	return null

func drop_target_at(global_position: Vector2, record: DiscardRecord = null) -> Dictionary:
	if not _active: return {"kind": DROP_TARGET_NONE, "meld_id": -1}
	if InputHitTest.contains(drink_table_button, global_position):
		return {"kind": &"drink"}
	if record == null: record = drink_record_at(global_position)
	if record != null:
		return {"kind": &"drink_discard", "record": record}
	if discard_pile_visual != null and discard_pile_visual.get_global_rect().has_point(global_position):
		return {"kind": DROP_TARGET_DISCARD, "meld_id": -1}
	for meld in deal.melds:
		var meld_view := meld_views.get(meld.meld_id) as MeldView
		if meld_view != null and meld_view.get_global_rect().has_point(global_position):
			return {"kind": DROP_TARGET_MELD, "meld_id": meld.meld_id}
	if hand_layer != null and hand_layer.get_global_rect().grow(28.0).has_point(global_position):
		return {"kind": DROP_TARGET_HAND, "meld_id": -1}
	if table_surface != null and table_surface.get_global_rect().has_point(global_position):
		if draw_pile_visual == null or not draw_pile_visual.get_global_rect().has_point(global_position):
			return {"kind": DROP_TARGET_TABLE, "meld_id": -1}
	return {"kind": DROP_TARGET_NONE, "meld_id": -1}


func _build_card_drag_preview(payload) -> void:
	if particle_layer == null:
		return
	drag_preview = Control.new()
	drag_preview.name = "CardDragPreview"
	drag_preview.mouse_filter = Control.MOUSE_FILTER_IGNORE
	drag_preview.z_index = 10
	particle_layer.add_child(drag_preview)
	var shown_count := mini(payload.cards.size(), 4)
	for index in range(shown_count):
		var card: CardData = payload.cards[index]
		var texture := TextureRect.new()
		texture.position = Vector2(index * 9.0, -index * 4.0)
		texture.size = CARD_SIZE
		texture.texture = load(card.texture_path()) as Texture2D
		GieoCardFX.attach_texture(texture, card)
		texture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		texture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		texture.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		texture.mouse_filter = Control.MOUSE_FILTER_IGNORE
		texture.modulate = Color(1, 1, 1, 0.9)
		drag_preview.add_child(texture)
	if payload.cards.size() > 1:
		var count_badge := Label.new()
		count_badge.position = Vector2(CARD_SIZE.x - 8, -12)
		count_badge.size = Vector2(30, 24)
		count_badge.text = "×%d" % payload.cards.size()
		count_badge.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		count_badge.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		count_badge.add_theme_font_size_override("font_size", 12)
		count_badge.add_theme_color_override("font_color", Color.WHITE)
		count_badge.add_theme_stylebox_override("normal", PresentationTheme.panel_style(Color("#17120ff2"), PresentationTheme.TEA, 2, 2, 2))
		count_badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
		drag_preview.add_child(count_badge)


func _refresh_card_drag_targets(payload) -> void:
	clear_drag_target_overlays()
	if particle_layer == null:
		return
	var table_target := {"kind": DROP_TARGET_TABLE, "meld_id": -1}
	if not interactions.cards_for_drop_target(payload, table_target).is_empty():
		add_drag_target_overlay(table_surface.get_global_rect(), PresentationTheme.TEA)
	if interactions.drink_drop_is_valid(payload.cards, {"kind": &"drink"}):
		add_drag_target_overlay(drink_table_button.get_global_rect(), CardActionOutline.DRINK_HIGHLIGHT)
	for opportunity in deal.queries.drink_swap_opportunities(payload.cards[0] if payload.cards.size() == 1 else null):
		var record: DiscardRecord = opportunity.record
		if interactions.drink_drop_is_valid(payload.cards, {"kind": &"drink_discard", "record": record}):
			var holder := discard_history_target_holders.get(record.target_key()) as Control
			if holder != null:
				add_drag_target_overlay(holder.get_global_rect(), CardActionOutline.DRINK_HIGHLIGHT)
	add_drag_target_overlay(hand_layer.get_global_rect().grow(18.0), Color("#70a7df"))
	var discard_target := {"kind": DROP_TARGET_DISCARD, "meld_id": -1}
	if not interactions.cards_for_drop_target(payload, discard_target).is_empty():
		add_drag_target_overlay(discard_pile_visual.get_global_rect(), PresentationTheme.RED)
	for meld in deal.melds:
		var target := {"kind": DROP_TARGET_MELD, "meld_id": meld.meld_id}
		if interactions.cards_for_drop_target(payload, target).is_empty():
			continue
		var meld_view := meld_views.get(meld.meld_id) as MeldView
		if meld_view != null:
			add_drag_target_overlay(meld_view.get_global_rect(), PresentationTheme.GOLD)


func add_drag_target_overlay(global_rect: Rect2, color: Color) -> void:
	if not _active: return
	var overlay := Panel.new()
	overlay.name = "CardDropTarget"
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.position = drag_layer_local_position(global_rect.position)
	overlay.size = drag_layer_local_position(global_rect.end) - overlay.position
	var fill := color
	fill.a = 0.13
	var border := color
	border.a = 0.9
	overlay.add_theme_stylebox_override("panel", PresentationTheme.panel_style(fill, border, 3, 3, 5))
	particle_layer.add_child(overlay)
	drag_target_overlays.append(overlay)


func drag_layer_local_position(global_position: Vector2) -> Vector2:
	return particle_layer.get_global_transform_with_canvas().affine_inverse() * global_position


func clear_drag_target_overlays() -> void:
	for overlay in drag_target_overlays:
		if is_instance_valid(overlay):
			overlay.hide()
			overlay.queue_free()
	drag_target_overlays.clear()


func set_hand_interaction_enabled(enabled: bool) -> void:
	if not _active: return
	for value in hand_views.values():
		var view := value as PlayingCardView
		if view != null:
			view.set_interaction_enabled(enabled)
	if not enabled and interactions.drag_payload != null:
		clear_drag_visuals()
		interactions.drag_payload = null
		layout_hand(true)
