@tool
extends McpTestSuite

func suite_name() -> String:
	return "gieo_card_material"

func test_outline_palette_handles_cues_being_cleared() -> void:
	var outline := CardActionOutline.new()
	outline.set_cues(true, true, true)
	assert_true(outline._gradient_color(0.4, 0.5).a > 0.0)
	outline.set_cues(false, false, false)
	assert_eq(outline._gradient_color(0.4, 0.5), Color.TRANSPARENT)
	outline.free()

func test_material_is_per_face_reused_and_normal_restores_original() -> void:
	var a := TextureRect.new()
	var b := TextureRect.new()
	var original := CanvasItemMaterial.new()
	a.material = original
	GieoCardFX.apply_state(a, 0, false, false)
	assert_eq(a.material, original)
	GieoCardFX.apply_state(a, 6, true, true)
	var first := a.material
	GieoCardFX.apply_state(a, -3, false, true)
	GieoCardFX.apply_state(b, -3, false, true)
	assert_eq(a.material, first)
	assert_true(a.material != b.material)
	assert_eq((a.material as ShaderMaterial).shader, (b.material as ShaderMaterial).shader)
	assert_eq(a.material.get_shader_parameter("fortune"), -3.0)
	GieoCardFX.apply_state(a, 0, false, false)
	assert_eq(a.material, original)
	a.free()
	b.free()

func test_hand_keeps_face_input_dimensions_and_combined_state_without_extra_layers() -> void:
	var view := PlayingCardView.new()
	var data := CardData.new("fx", "A", 1, "Spades", 1)
	data.fortune = 6
	data.liquid = true
	data.negative = true
	view.set_card(data)
	Engine.get_main_loop().root.add_child(view)
	var face := view.get_node("BeatVisual/Face") as TextureRect
	assert_eq(view.size, PlayingCardView.CARD_SIZE)
	assert_eq(view.mouse_filter, Control.MOUSE_FILTER_STOP)
	assert_eq(face.material.get_shader_parameter("fortune"), 6.0)
	assert_eq(face.material.get_shader_parameter("liquid_amount"), 1.0)
	assert_eq(face.material.get_shader_parameter("negative_amount"), 1.0)
	assert_eq(face.get_child_count(), 0)
	assert_eq(view.get_node("BeatVisual").get_child_count(), 4)
	assert_true(view.tooltip_text.contains("+6"))
	view.set_card(CardData.new("plain", "A", 1, "Spades", 1))
	assert_true(face.material == null)
	view.free()

func test_meld_keeps_texture_drink_outline_and_fortune() -> void:
	var data := CardData.new("table_fx", "A", 1, "Spades", 1)
	data.fortune = -6
	var view := MeldView.new()
	Engine.get_main_loop().root.add_child(view)
	view.set_meld(MeldState.new(1, MeldRules.TYPE_SET, [data]), false, false)
	var face: TextureRect = view._card_views[data.unique_id]
	assert_eq(face.custom_minimum_size, Vector2(49, 68))
	assert_eq(face.mouse_filter, Control.MOUSE_FILTER_IGNORE)
	assert_eq(face.get_node("SwayFace").material.get_shader_parameter("fortune"), -6.0)
	assert_eq(face.get_child_count(), 2)
	assert_true(face.get_node("ActionOutline").material == null)
	view.free()

func test_keyboard_inspection_exposes_exact_signed_fortune_without_a_face_badge() -> void:
	var view := PlayingCardView.new()
	var data := CardData.new("keyboard","8",8,"Hearts",8)
	data.fortune = -6
	data.liquid = true
	data.negative = true
	view.set_card(data)
	Engine.get_main_loop().root.add_child(view)
	view._show_focus_inspection()
	assert_true(view._focus_inspection != null)
	assert_eq((view._focus_inspection.find_child("SignedFortune",true,false) as Label).text,"-6")
	assert_eq(view.get_node("BeatVisual/Face").get_child_count(),0)
	view._hide_focus_inspection()
	assert_true(view._focus_inspection == null)
	view.free()

func test_snapshot_and_picker_show_persistent_state_and_exact_fortune() -> void:
	var panel := GieoQuePanel.new()
	var data := CardData.new("picker_fx", "A", 1, "Spades", 1)
	data.fortune = -3
	data.negative = true
	var parent := HBoxContainer.new()
	panel._build_transformation_row(parent, {"before": data.permanent_snapshot(), "after": data.permanent_snapshot()}, false)
	var row := parent.get_child(0) as Control
	var art: TextureRect = row.get_meta("card_art")
	assert_eq(art.material.get_shader_parameter("fortune"), -3.0)
	assert_true(row.tooltip_text.contains("-3"))
	var picker := VBoxContainer.new()
	panel._build_card_picker(picker, [data], false)
	var button := picker.get_child(0).get_child(0).get_child(0) as Button
	var picker_art := button.get_node("PickerCardArt") as TextureRect
	assert_eq(button.custom_minimum_size, panel.CARD_THUMB_SIZE)
	assert_eq(picker_art.mouse_filter, Control.MOUSE_FILTER_IGNORE)
	assert_true(button.pressed.is_connected(panel._on_target_pressed.bind(data.unique_id)))
	assert_eq(picker_art.material.get_shader_parameter("negative_amount"), 1.0)
	picker.free()
	parent.free()
	panel.free()

func test_all_fortunes_and_jackpot_combinations_have_independent_channels() -> void:
	var face := TextureRect.new()
	for fortune in range(-6, 7):
		for bits in 4:
			GieoCardFX.apply_state(face, fortune, bits & 1 != 0, bits & 2 != 0)
			if fortune == 0 and bits == 0:
				assert_true(face.material == null)
				continue
			assert_eq(face.material.get_shader_parameter("fortune"), float(fortune))
			assert_eq(face.material.get_shader_parameter("liquid_amount"), 1.0 if bits & 1 else 0.0)
			assert_eq(face.material.get_shader_parameter("negative_amount"), 1.0 if bits & 2 else 0.0)
	GieoCardFX.apply_state(face, 0, false, false)
	assert_true(face.material == null)
	face.free()

func test_live_snapshot_and_score_receipt_share_physical_animation_identity() -> void:
	var card := CardData.new("same_physical_card", "K", 13, "Hearts", 13)
	card.fortune = -6
	card.liquid = true
	card.negative = true
	var live := TextureRect.new()
	var snapshot := TextureRect.new()
	var receipt := TextureRect.new()
	GieoCardFX.attach_texture(live, card)
	GieoCardFX.apply_snapshot(snapshot, card.permanent_snapshot())
	GieoCardFX.apply_snapshot(receipt, ScoringPipeline.new()._card_hit(card, 13, ""))
	for face in [snapshot, receipt]:
		assert_eq(face.get_meta("physical_id"), card.unique_id)
		assert_eq(face.material.get_shader_parameter("identity_phase"), live.material.get_shader_parameter("identity_phase"))
		assert_eq(face.texture_filter, CanvasItem.TEXTURE_FILTER_NEAREST)
		assert_true(face.material != live.material)
	live.free()
	snapshot.free()
	receipt.free()
