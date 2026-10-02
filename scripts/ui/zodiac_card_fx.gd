extends RefCounted
## Presentation only. One material per physical card; no shared shader state.
const AURA := preload("res://shaders/zodiac_card_aura.gdshader")
const CAT := Color("bc78ff")
const ROOSTER := Color("ff574f")

static func aura(parent: Control, card_size: Vector2, tint: Color, seed_value: float = 0.0, padding: float = 18.0) -> ColorRect:
	var surface := ColorRect.new()
	surface.name = "ZodiacAura"
	surface.position = Vector2.ONE * -padding
	surface.size = card_size + Vector2.ONE * padding * 2.0
	surface.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var ink := ShaderMaterial.new()
	ink.shader = AURA
	ink.set_shader_parameter("aura_color", tint)
	ink.set_shader_parameter("seed", seed_value)
	ink.set_shader_parameter("card_half_size", card_size / surface.size * 0.5)
	surface.material = ink
	parent.add_child(surface)
	return surface

static func turn_modifier(rule: ZodiacBossRule, phase: int, number: int) -> String:
	if rule.id != "rooster" or phase != 1: return ""
	var deadline := int(ZodiacCatalog.tuning("rooster", "discard_deadline", rule.difficulty))
	return "closing" if number == deadline else "closed" if number > deadline else ""
