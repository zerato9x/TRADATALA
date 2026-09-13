class_name GieoCardFX
extends RefCounted

## Persistent printing treatment on the existing face; no overlay, input or score hooks.
const SHADER := preload("res://shaders/gieo_card.gdshader")
const PROPERTIES := ["MAKING_PHOM_RETRIGGER", "SET_RETRIGGER", "EXTEND_RETRIGGER", "RUN_RETRIGGER"]

static func attach_texture(face: TextureRect, card: CardData) -> void:
	apply_properties(face, card.gieo_properties)

static func apply_properties(face: TextureRect, properties: Array) -> void:
	var strengths := Vector4.ZERO
	for i in 4:
		strengths[i] = 1.0 if properties.has(PROPERTIES[i]) else 0.0
	if strengths == Vector4.ZERO:
		if face.has_meta("gieo_material"):
			face.material = face.get_meta("gieo_original_material") if face.has_meta("gieo_original_material") else null
		return
	var mat: ShaderMaterial
	if face.has_meta("gieo_material"):
		mat = face.get_meta("gieo_material")
	else:
		if face.material != null:
			face.set_meta("gieo_original_material", face.material)
		mat = ShaderMaterial.new()
		mat.shader = SHADER
		face.set_meta("gieo_material", mat)
	mat.set_shader_parameter("strengths", strengths)
	face.material = mat
