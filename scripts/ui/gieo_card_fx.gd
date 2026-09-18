class_name GieoCardFX
extends RefCounted

## Persistent printing treatment on the existing face; no overlay, input or score hooks.
const SHADER := preload("res://shaders/gieo_card.gdshader")
const PROPERTIES := ["GOLD_MAKING_PHOM", "GOLD_SET", "GOLD_EXTEND", "GOLD_RUN", "GOLD_BIG_PHOM", "GOLD_LAST_CALL", "MELD_RETRIGGER"]

static func attach_texture(face: TextureRect, card: CardData) -> void:
	apply_properties(face, card.gieo_properties, card.shiny)

static func apply_properties(face: TextureRect, properties: Array, shiny: bool = false) -> void:
	var strengths := Vector4.ZERO
	for i in 4:
		strengths[i] = 1.0 if properties.has(PROPERTIES[i]) else 0.0
	var accents := Vector3(1.0 if properties.has(PROPERTIES[4]) else 0.0, 1.0 if properties.has(PROPERTIES[5]) else 0.0, 1.0 if properties.has(PROPERTIES[6]) else 0.0)
	if strengths == Vector4.ZERO and accents == Vector3.ZERO and not shiny:
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
	mat.set_shader_parameter("polished", shiny)
	mat.set_shader_parameter("strengths", strengths)
	mat.set_shader_parameter("accents", accents)
	face.material = mat
