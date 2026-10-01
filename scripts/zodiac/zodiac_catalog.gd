class_name ZodiacCatalog
extends RefCounted
## Only the first pair is authored. Unauthored pair days remain ordinary Deals.
const PAIRS := [["rooster", "cat"], ["dog", "monkey"], ["pig", "ox"], ["horse", "goat"], ["rat", "tiger"], ["snake", "dragon"]]
const DAY_PAIRS := [0, 1, 2, 3, 4, 5, 0]
const DEFINITIONS := {
	"rooster": {"thresholds": [1, 2], "deadlines": {"PLEASED": 3, "NEUTRAL": 2, "UNPLEASED": 1},
		"favorites": ["toothpicks", "sunflower_seeds"], "favorite_tags": ["practical"],
		"unlock": {"requests_resolved": 4, "requests_refused_successfully": 1, "pleased_victories": 1},
		"sprite": "res://assets/zodiacboss/rooster.png", "emblem": {"id": "rooster", "extensions": {}}},
	"cat": {"thresholds": [1, 2], "locks": {"PLEASED": 1, "NEUTRAL": 2, "UNPLEASED": 3},
		"favorites": ["hair_clip", "sunglasses"], "favorite_tags": ["adornment"],
		"unlock": {"requests_resolved": 4, "restraint_kept": 1, "pleased_victories": 1},
		"sprite": "res://assets/zodiacboss/cat.png", "emblem": {"id": "cat", "extensions": {}}},
}

static func words(en: String, vi: String) -> String:
	return vi if TranslationServer.get_locale().begins_with("vi") else en

static func display_name(id: String) -> String:
	return words("ROOSTER", "DẬU") if id == "rooster" else words("CAT", "MÃO")

static func pair_for_day(day: int) -> Array:
	return PAIRS[DAY_PAIRS[posmod(day, DAY_PAIRS.size())]]

static func select(seed_value: int, day: int, forced: String = "") -> String:
	var pair := pair_for_day(day)
	if forced in pair and DEFINITIONS.has(forced): return forced
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var selected: String = pair[rng.randi_range(0, 1)]
	return selected if DEFINITIONS.has(selected) else ""

static func disposition(id: String, successes: int) -> String:
	var thresholds: Array = DEFINITIONS[id].thresholds
	return "PLEASED" if successes >= int(thresholds[1]) else "NEUTRAL" if successes >= int(thresholds[0]) else "UNPLEASED"

static func disposition_label(value: String) -> String:
	return words(value, {"PLEASED": "HÀI LÒNG", "NEUTRAL": "BÌNH THƯỜNG", "UNPLEASED": "KHÔNG HÀI LÒNG"}.get(value, value))

static func rule_text(id: String, mood: String) -> String:
	if id == "rooster":
		return words("Phase 1: register closes after mandatory discard #%d. Closed Melds/Extensions stay legal but pay nothing. Phase 2 scores normally.", "Hiệp 1: đóng sổ sau lần bỏ bài bắt buộc #%d. Vẫn được tạo/nối Phỏm nhưng không trả thưởng. Hiệp 2 tính điểm bình thường.") % int(DEFINITIONS[id].deadlines[mood])
	return words("Phase 1: watching. Phase 2: %d cards locked after each refill, until the next turn. Locked cards cannot be played, discarded or targeted; they still count as deadwood.", "Hiệp 1: quan sát. Hiệp 2: khóa %d lá sau mỗi lần bốc, tới lượt kế. Không thể đánh, bỏ hay chọn lá bị khóa; vẫn tính điểm bài rác.") % int(DEFINITIONS[id].locks[mood])
