class_name RelicCatalog
extends RefCounted

# Rate boosts are percentages of the base VNĐ/point rate for one committed action.
const DEFINITIONS := {
	"hair_clip": {"name": "Kẹp Tóc", "event": "new_meld", "type": "set", "percent": 30, "asset": "hairclip", "effect": "RELIC_EFFECT_HAIR_CLIP"},
	"comb": {"name": "Lược", "event": "new_meld", "type": "run", "percent": 8, "per_card": true, "asset": "comb", "effect": "RELIC_EFFECT_COMB"},
	"rubber_band": {"name": "Dây Thun", "event": "extension", "percent": 20, "asset": "rubberband", "effect": "RELIC_EFFECT_RUBBER_BAND"},
	"chewing_gum": {"name": "Kẹo Cao Su", "event": "extension", "percent": 10, "escalating": true, "asset": "gum", "effect": "RELIC_EFFECT_CHEWING_GUM"},
	"sunflower_seeds": {"name": "Hạt Hướng Dương", "event": "new_meld", "percent": 5, "per_card": true, "asset": "sunflowerseeds", "effect": "RELIC_EFFECT_SUNFLOWER_SEEDS"},
	"toothpicks": {"name": "Que Tăm", "event": "new_meld", "exact": 3, "percent": 20, "asset": "toothpick", "effect": "RELIC_EFFECT_TOOTHPICKS"},
	"hard_candy": {"name": "Kẹo Cứng", "event": "new_meld", "minimum": 4, "percent": 50, "asset": "hardcandy", "effect": "RELIC_EFFECT_HARD_CANDY"},
	"sunglasses": {"name": "Kính Râm", "event": "new_meld", "suits": ["Spades", "Clubs"], "percent": 40, "asset": "sunglasses", "effect": "RELIC_EFFECT_SUNGLASSES"},
	"lipstick": {"name": "Son Môi", "event": "new_meld", "suits": ["Hearts", "Diamonds"], "percent": 40, "asset": "lipstick", "effect": "RELIC_EFFECT_LIPSTICK"},
	"buttons": {"name": "Cúc Áo", "event": "new_meld", "type": "set", "exact": 4, "percent": 75, "asset": "buttons", "effect": "RELIC_EFFECT_BUTTONS"},
}

static func effect(id: String) -> String:
	var definition: Dictionary = DEFINITIONS[id]
	return TranslationServer.translate(StringName(definition.effect)) % int(definition.percent)

static func rate_bonus(id: String, card_count: int, extension_count: int = 1) -> int:
	var definition: Dictionary = DEFINITIONS[id]
	var percent := int(definition.percent)
	if definition.get("per_card", false):
		percent *= card_count
	if definition.get("escalating", false):
		percent *= extension_count
	return percent

static func flavor_tags(id: String) -> Array:
	return {"hair_clip": ["adornment"], "lipstick": ["adornment"], "sunglasses": ["adornment"], "toothpicks": ["practical"], "rubber_band": ["practical"]}.get(id, [])

static func icon_path(id: String) -> String:
	return "res://assets/relics/basic_%s.png" % DEFINITIONS[id].asset

static func display_name(id: String) -> String:
	return ZodiacCatalog.words(name_in(id, "en"), name_in(id, "vi"))

static func name_in(id: String, locale: String) -> String:
	var english := {"hair_clip": "Hair Clip", "comb": "Comb", "rubber_band": "Rubber Band", "chewing_gum": "Chewing Gum", "sunflower_seeds": "Sunflower Seeds", "toothpicks": "Toothpicks", "hard_candy": "Hard Candy", "sunglasses": "Sunglasses", "lipstick": "Lipstick", "buttons": "Buttons"}
	return DEFINITIONS.get(id, {}).get("name", id) if locale == "vi" else english.get(id, id)
