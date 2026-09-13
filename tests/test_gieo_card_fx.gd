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

func test_material_is_per_face_reused_and_normal_card_restores_original() -> void:
	var a := TextureRect.new()
	var b := TextureRect.new()
	var original := CanvasItemMaterial.new()
	a.material = original
	GieoCardFX.apply_properties(a, [])
	assert_eq(a.material, original)
	GieoCardFX.apply_properties(a, GieoCardFX.PROPERTIES)
	var first := a.material
	GieoCardFX.apply_properties(a, ["RUN_RETRIGGER"])
	GieoCardFX.apply_properties(b, ["RUN_RETRIGGER"])
	assert_eq(a.material, first)
	assert_true(a.material != b.material)
	assert_eq((a.material as ShaderMaterial).shader, (b.material as ShaderMaterial).shader)
	assert_eq(a.material.get_shader_parameter("strengths"), Vector4(0, 0, 0, 1))
	GieoCardFX.apply_properties(a, [])
	assert_eq(a.material, original)
	a.free()
	b.free()

func test_hand_keeps_face_input_dimensions_and_all_four_without_extra_layers() -> void:
	var view := PlayingCardView.new()
	var data := CardData.new("fx", "A", 1, "Spades", 1)
	data.gieo_properties.assign(GieoCardFX.PROPERTIES)
	view.set_card(data)
	Engine.get_main_loop().root.add_child(view)
	var face := view.get_node("BeatVisual/Face") as TextureRect
	assert_eq(view.size, PlayingCardView.CARD_SIZE)
	assert_eq(view.mouse_filter, Control.MOUSE_FILTER_STOP)
	assert_eq(face.material.get_shader_parameter("strengths"), Vector4.ONE)
	assert_eq(face.get_child_count(), 0)
	assert_eq(view.get_node("BeatVisual").get_child_count(), 4)
	view.set_card(CardData.new("plain", "A", 1, "Spades", 1))
	assert_true(face.material == null)
	view.free()

func test_meld_keeps_existing_texture_and_drink_outline() -> void:
	var data := CardData.new("table_fx", "A", 1, "Spades", 1)
	data.add_gieo_property("SET_RETRIGGER")
	var view := MeldView.new()
	Engine.get_main_loop().root.add_child(view)
	view.set_meld(MeldState.new(1, MeldRules.TYPE_SET, [data]), false, false)
	var face: TextureRect = view._card_views[data.unique_id]
	assert_eq(face.custom_minimum_size, Vector2(49, 68))
	assert_eq(face.mouse_filter, Control.MOUSE_FILTER_IGNORE)
	assert_eq(face.material.get_shader_parameter("strengths"), Vector4(0, 1, 0, 0))
	assert_eq(face.get_child_count(), 1)
	assert_true(face.get_node("ActionOutline").material == null)
	view.free()

func test_gieo_snapshot_and_picker_show_persistent_material_without_changing_targets() -> void:
	var panel := GieoQuePanel.new()
	var data := CardData.new("picker_fx", "A", 1, "Spades", 1)
	data.add_gieo_property("MAKING_PHOM_RETRIGGER")
	var snapshot := panel._snapshot_card(data.permanent_snapshot(), "AFTER")
	var art: TextureRect = snapshot.get_meta("card_art")
	assert_eq(art.material.get_shader_parameter("strengths"), Vector4(1, 0, 0, 0))
	var parent := VBoxContainer.new()
	panel._build_card_picker(parent, [data], false)
	var button := parent.get_child(0).get_child(0).get_child(0) as Button
	var picker_art := button.get_node("PickerCardArt") as TextureRect
	assert_eq(button.custom_minimum_size, panel.CARD_THUMB_SIZE)
	assert_eq(picker_art.mouse_filter, Control.MOUSE_FILTER_IGNORE)
	assert_true(button.pressed.is_connected(panel._on_target_pressed.bind(data.unique_id)))
	assert_eq(picker_art.material.get_shader_parameter("strengths"), Vector4(1, 0, 0, 0))
	parent.free()
	snapshot.free()
	panel.free()
