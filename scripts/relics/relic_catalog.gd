class_name RelicCatalog
extends RefCounted

# Temporary first-pass balance; values belong here, never in handlers.
const DEFINITIONS := {
	"hair_clip": {"name": "Kẹp Tóc", "event": "new_meld", "type": "set", "points": 30, "asset": "hairclip", "effect": "RELIC_EFFECT_HAIR_CLIP"},
	"comb": {"name": "Lược", "event": "new_meld", "type": "run", "points": 8, "per_card": true, "asset": "comb", "effect": "RELIC_EFFECT_COMB"},
	"rubber_band": {"name": "Dây Thun", "event": "extension", "points": 20, "asset": "rubberband", "effect": "RELIC_EFFECT_RUBBER_BAND"},
	"chewing_gum": {"name": "Kẹo Cao Su", "event": "extension", "points": 10, "escalating": true, "asset": "gum", "effect": "RELIC_EFFECT_CHEWING_GUM"},
	"sunflower_seeds": {"name": "Hạt Hướng Dương", "event": "new_meld", "points": 5, "per_card": true, "asset": "sunflowerseeds", "effect": "RELIC_EFFECT_SUNFLOWER_SEEDS"},
	"toothpicks": {"name": "Que Tăm", "event": "new_meld", "exact": 3, "points": 20, "asset": "toothpick", "effect": "RELIC_EFFECT_TOOTHPICKS"},
	"hard_candy": {"name": "Kẹo Cứng", "event": "new_meld", "minimum": 4, "points": 50, "asset": "hardcandy", "effect": "RELIC_EFFECT_HARD_CANDY"},
	"sunglasses": {"name": "Kính Râm", "event": "new_meld", "suits": ["Spades", "Clubs"], "points": 40, "asset": "sunglasses", "effect": "RELIC_EFFECT_SUNGLASSES"},
	"lipstick": {"name": "Son Môi", "event": "new_meld", "suits": ["Hearts", "Diamonds"], "points": 40, "asset": "lipstick", "effect": "RELIC_EFFECT_LIPSTICK"},
	"buttons": {"name": "Cúc Áo", "event": "new_meld", "type": "set", "exact": 4, "points": 75, "asset": "buttons", "effect": "RELIC_EFFECT_BUTTONS"},
}

static func effect(id: String) -> String:
	var definition: Dictionary = DEFINITIONS[id]
	return TranslationServer.translate(StringName(definition.effect)) % int(definition.points)

static func icon_path(id: String) -> String:
	return "res://assets/relics/basic_%s.png" % DEFINITIONS[id].asset
