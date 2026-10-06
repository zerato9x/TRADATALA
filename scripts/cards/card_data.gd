class_name CardData
extends RefCounted

signal permanent_changed(card_id: String, revision: int, operation: String)
var mutation_revision := 0

const RANK_FILE_NAMES := {
	"A": "ace",
	"2": "two",
	"3": "three",
	"4": "four",
	"5": "five",
	"6": "six",
	"7": "seven",
	"8": "eight",
	"9": "nine",
	"10": "ten",
	"J": "jack",
	"Q": "queen",
	"K": "king",
}

var unique_id: String
var rank: String
var rank_index: int
var suit: String
var base_value: int
var value_modifiers: Array[int] = []
var enhancements: Array[String] = []
const FORTUNE_MIN := -6
const FORTUNE_MAX := 6
const JACKPOT_LIQUID := "LIQUID"
const JACKPOT_NEGATIVE := "NEGATIVE"
var fortune: int = 0:
	set(value): fortune = clampi(value, FORTUNE_MIN, FORTUNE_MAX)
var liquid: bool = false
var negative: bool = false
# Separate day-scoped polish; excluded from permanent snapshots.
var shiny: bool = false
var transformation_locked: bool = false


func _init(
	p_unique_id: String = "",
	p_rank: String = "",
	p_rank_index: int = 0,
	p_suit: String = "",
	p_base_value: int = 0
) -> void:
	unique_id = p_unique_id
	rank = p_rank
	rank_index = p_rank_index
	suit = p_suit
	base_value = p_base_value


func score_value() -> int:
	return intrinsic_value() * maxi(fortune, 1)


func intrinsic_value() -> int:
	var total := base_value
	for modifier in value_modifiers:
		total += modifier
	return total


# Deadwood is a signed cost: Black Ink produces income. Gold uses normal value.
func deadwood_value() -> int:
	return intrinsic_value() * (-absi(fortune) if fortune < 0 else 1)


func echo_count() -> int:
	return 1 if liquid else 0


func is_glitch() -> bool:
	return liquid and negative


func jackpot_state() -> String:
	if is_glitch(): return "GLITCH"
	if liquid: return JACKPOT_LIQUID
	if negative: return JACKPOT_NEGATIVE
	return ""


func fortune_label() -> String:
	return "%+d" % fortune if fortune != 0 else "0"


func has_fortune_properties() -> bool:
	return fortune != 0 or liquid or negative


func permanent_property_count() -> int:
	return int(fortune != 0) + int(liquid) + int(negative)


func permanent_property_ids() -> Array[String]:
	var properties: Array[String] = []
	if fortune > 0: properties.append("GOLD")
	elif fortune < 0: properties.append("BLACK_INK")
	if liquid: properties.append(JACKPOT_LIQUID)
	if negative: properties.append(JACKPOT_NEGATIVE)
	return properties


func adjust_fortune(delta: int) -> bool:
	if transformation_locked: return false
	var before := persuasion_fingerprint()
	fortune += delta
	_notify_permanent(before, "fortune")
	return before != persuasion_fingerprint()


func meld_rank_options() -> Array[int]:
	var ranks: Array[int] = []
	if is_glitch():
		for value in range(1, 14): ranks.append(value)
	elif negative:
		for value in range(maxi(rank_index - 1, 1), mini(rank_index + 1, 13) + 1): ranks.append(value)
	else: ranks.append(rank_index)
	return ranks


func meld_suit_options() -> Array[String]:
	var suits: Array[String] = []
	if is_glitch():
		suits.assign(DeckManager.SUITS)
		return suits
	if negative:
		suits.assign(["Hearts", "Diamonds"] if suit in ["Hearts", "Diamonds"] else ["Spades", "Clubs"])
	else: suits.append(suit)
	return suits


func can_represent(value: int, suit_identity: String = "") -> bool:
	if value < 1 or value > 13: return false
	var glitch := is_glitch()
	if not glitch and (absi(value - rank_index) > 1 if negative else value != rank_index): return false
	if suit_identity in ["", "any"]: return true
	var red := suit in ["Hearts", "Diamonds"]
	if suit_identity == "red": return glitch or red
	if suit_identity == "black": return glitch or not red
	if suit_identity not in DeckManager.SUITS: return false
	if glitch: return true
	if negative: return (suit_identity in ["Hearts", "Diamonds"]) == red
	return suit_identity == suit


func apply_rank(p_rank: String, p_rank_index: int) -> void:
	if transformation_locked: return
	var before := persuasion_fingerprint()
	rank = p_rank
	rank_index = p_rank_index
	base_value = p_rank_index
	_notify_permanent(before, "rank")


func apply_suit(p_suit: String) -> void:
	if transformation_locked: return
	var before := persuasion_fingerprint()
	suit = p_suit
	_notify_permanent(before, "suit")


func add_jackpot(property_id: String) -> bool:
	if transformation_locked: return false
	var before := persuasion_fingerprint()
	match property_id:
		JACKPOT_LIQUID: liquid = true
		JACKPOT_NEGATIVE: negative = true
		_: return false
	_notify_permanent(before, "property")
	return before != persuasion_fingerprint()


func permanent_snapshot() -> Dictionary:
	return {
		"unique_id": unique_id,
		"rank": rank,
		"rank_index": rank_index,
		"suit": suit,
		"fortune": fortune,
		"liquid": liquid,
		"negative": negative,
		"transformation_locked": transformation_locked,
	}


func copy_for_deal() -> CardData:
	var deal_copy := CardData.new(unique_id, rank, rank_index, suit, base_value)
	deal_copy.fortune = fortune
	deal_copy.liquid = liquid
	deal_copy.negative = negative
	deal_copy.shiny = shiny
	deal_copy.transformation_locked = transformation_locked
	return deal_copy


func alter_for_zodiac(operation: String) -> void:
	var before := persuasion_fingerprint()
	match operation:
		"remove_property":
			if negative: negative = false
			elif liquid: liquid = false
			else: fortune = 0
		"seal": transformation_locked = true
		"reset":
			# Canonical identity is stable even after rank/suit transformations.
			var identity := unique_id.split("_")
			if identity.size() != 3 or identity[0] != "standard": return
			rank = identity[1].to_upper()
			rank_index = DeckManager.RANKS.find(rank) + 1
			base_value = rank_index
			suit = identity[2].capitalize()
			fortune = 0
			liquid = false
			negative = false
			value_modifiers.clear()
			enhancements.clear()
			shiny = false
	_notify_permanent(before, operation)

func persuasion_fingerprint() -> Dictionary:
	var data := permanent_snapshot()
	data["base_value"] = base_value
	data["value_modifiers"] = value_modifiers.duplicate()
	data["enhancements"] = enhancements.duplicate()
	data["shiny"] = shiny
	return data

func _notify_permanent(before: Dictionary, operation: String) -> void:
	if before == persuasion_fingerprint(): return
	mutation_revision += 1
	permanent_changed.emit(unique_id, mutation_revision, operation)

func has_permanent_changes() -> bool:
	var identity := unique_id.split("_")
	var changed_identity := identity.size() == 3 and identity[0] == "standard" and (rank != identity[1].to_upper() or suit.to_lower() != identity[2])
	return changed_identity or has_fortune_properties() or not value_modifiers.is_empty() or not enhancements.is_empty() or shiny


func fortune_descriptions() -> Array[String]:
	var descriptions: Array[String] = []
	for property_id in permanent_property_ids():
		var key := property_label_key(property_id)
		if not key.is_empty():
			descriptions.append(TranslationServer.translate(key + "_DESC"))
	return descriptions


func texture_path() -> String:
	var rank_file: String = RANK_FILE_NAMES.get(rank, rank.to_lower())
	return "res://cards/%s_of_%s.png" % [rank_file, suit.to_lower()]


func short_label() -> String:
	const SUIT_SYMBOLS := {
		"Spades": "S",
		"Hearts": "H",
		"Diamonds": "D",
		"Clubs": "C",
	}
	return "%s%s" % [rank, SUIT_SYMBOLS.get(suit, "?")]


func inspection_text() -> String:
	var text := "%s · %s\n%s %s" % [rank, TranslationServer.translate("SUIT_" + suit.to_upper()), TranslationServer.translate("CARD_FORTUNE"), fortune_label()]
	if not jackpot_state().is_empty(): text += "\n" + TranslationServer.translate(property_label_key(jackpot_state()))
	if shiny: text += " · " + TranslationServer.translate("CARD_SHINY")
	return text


# Old printing is folded once at the save boundary; old physical ranks/suits survive.
# Each conditional Gold bonus formerly added one contribution. Preserve its potency
# as 1 + number of Gold marks, capped at 6. Liquid keeps its one non-recursive Echo.
func migrate_legacy_state(data: Dictionary) -> void:
	if data.has("fortune"): return
	var gold_count := 0
	for property_id: String in data.get("gieo_properties", []):
		if property_id.begins_with("GOLD_"): gold_count += 1
		elif property_id == "MELD_RETRIGGER": liquid = true
	fortune = mini(gold_count + 1, FORTUNE_MAX) if gold_count > 0 else 0


static func from_permanent_snapshot(data: Dictionary) -> CardData:
	var card := CardData.new(String(data.get("unique_id", "")), String(data.get("rank", "A")), int(data.get("rank_index", 1)), String(data.get("suit", "Spades")), int(data.get("rank_index", 1)))
	card.fortune = int(data.get("fortune", 0))
	card.liquid = bool(data.get("liquid", false))
	card.negative = bool(data.get("negative", false))
	card.transformation_locked = bool(data.get("transformation_locked", false))
	card.migrate_legacy_state(data)
	return card


static func property_label_key(property_id: String) -> String:
	match property_id:
		"GOLD": return "CARD_GOLD"
		"BLACK_INK": return "CARD_BLACK_INK"
		"LIQUID": return "GIEO_PROPERTY_LIQUID"
		"NEGATIVE": return "CARD_NEGATIVE"
		"GLITCH": return "CARD_GLITCH"
		"SHINY": return "CARD_SHINY"
	return ""

# Object-table fields in run envelopes V1-V3, including shared CardData references.
const RUN_SAVE_FIELDS_V3 := ["mutation_revision", "unique_id", "rank", "rank_index", "suit", "base_value", "value_modifiers", "enhancements", "fortune", "liquid", "negative", "shiny", "transformation_locked"]
const RUN_SNAPSHOT_FIELDS := preload("res://scripts/campaign/run_snapshot_fields.gd")

func run_value_snapshot() -> Dictionary:
	return RUN_SNAPSHOT_FIELDS.fields(self, RUN_SAVE_FIELDS_V3)

func restore_run_value(data: Dictionary) -> void:
	RUN_SNAPSHOT_FIELDS.apply_fields(self, data, RUN_SAVE_FIELDS_V3)
	migrate_legacy_state(data)
