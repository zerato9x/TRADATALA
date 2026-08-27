class_name HandAdvisor
extends RefCounted

const ACTION_NONE := "none"
const ACTION_NEW_MELD := "new_meld"
const ACTION_EXTENSION := "extension"


static func recommend(
	hand: Array[CardData],
	melds: Array[MeldState],
	scoring: ScoringPipeline = null,
	phase: int = 1,
	phase_new_phom_count: int = 0,
	must_preserve_discard: bool = true
) -> Dictionary:
	# Always prefer a new Meld: besides scoring, it is what prevents Móm.
	var active_scoring := scoring if scoring != null else ScoringPipeline.new()
	var new_meld := _best_new_meld(hand, active_scoring, phase, phase_new_phom_count, must_preserve_discard)
	if not new_meld.is_empty():
		return new_meld
	var extension := _best_extension(hand, melds, active_scoring, phase, must_preserve_discard)
	if not extension.is_empty():
		return extension
	return {
		"action": ACTION_NONE,
		"cards": [] as Array[CardData],
		"estimated_points": 0,
	}


static func estimate_new_meld_points(
	cards: Array[CardData],
	scoring: ScoringPipeline = null,
	phase: int = 1,
	phase_new_phom_count: int = 0
) -> int:
	var meld_type := MeldRules.classify(cards)
	if meld_type == MeldRules.TYPE_INVALID:
		return 0
	var active_scoring := scoring if scoring != null else ScoringPipeline.new()
	return active_scoring.preview_new_meld(cards, meld_type, phase, phase_new_phom_count).final_points


static func estimate_extension_points(
	meld: MeldState,
	additions: Array[CardData],
	scoring: ScoringPipeline = null,
	phase: int = 1
) -> int:
	if meld == null:
		return 0
	var combined: Array[CardData] = []
	combined.append_array(meld.cards)
	combined.append_array(additions)
	var active_scoring := scoring if scoring != null else ScoringPipeline.new()
	return active_scoring.preview_extension(combined, meld.meld_type, ScoringPipeline.meld_value(meld.cards), phase, additions).final_points


static func _best_new_meld(
	hand: Array[CardData],
	scoring: ScoringPipeline,
	phase: int,
	phase_new_phom_count: int,
	must_preserve_discard: bool
) -> Dictionary:
	var best: Dictionary = {}
	var best_points := -1
	for mask in range(1, 1 << hand.size()):
		var cards := _cards_for_mask(hand, mask)
		if cards.size() < 3 or (must_preserve_discard and cards.size() >= hand.size()):
			continue
		var meld_type := MeldRules.classify(cards)
		if meld_type == MeldRules.TYPE_INVALID:
			continue
		var points := estimate_new_meld_points(cards, scoring, phase, phase_new_phom_count)
		if points <= best_points:
			continue
		best_points = points
		best = {
			"action": ACTION_NEW_MELD,
			"cards": cards,
			"meld_type": meld_type,
			"meld_id": -1,
			"estimated_points": points,
		}
	return best


static func _best_extension(
	hand: Array[CardData],
	melds: Array[MeldState],
	scoring: ScoringPipeline,
	phase: int,
	must_preserve_discard: bool
) -> Dictionary:
	var best: Dictionary = {}
	var best_points := -1
	for meld in melds:
		for mask in range(1, 1 << hand.size()):
			var cards := _cards_for_mask(hand, mask)
			if (must_preserve_discard and cards.size() >= hand.size()) or not meld.can_extend(cards):
				continue
			var points := estimate_extension_points(meld, cards, scoring, phase)
			if points <= best_points:
				continue
			best_points = points
			best = {
				"action": ACTION_EXTENSION,
				"cards": cards,
				"meld_type": meld.meld_type,
				"meld_id": meld.meld_id,
				"estimated_points": points,
			}
	return best


static func _cards_for_mask(hand: Array[CardData], mask: int) -> Array[CardData]:
	var cards: Array[CardData] = []
	for index in range(hand.size()):
		if mask & (1 << index):
			cards.append(hand[index])
	return cards
