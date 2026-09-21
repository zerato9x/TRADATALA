class_name CampaignOnboarding
extends RefCounted
## Run-scoped knowledge; never performs actions, payments or scoring.
const SEED := 20092026
const MORNING_IDS: Array[String] = ["standard_9_spades", "standard_9_hearts", "standard_9_diamonds", "standard_4_clubs", "standard_5_clubs", "standard_2_hearts", "standard_7_spades", "standard_j_diamonds", "standard_k_clubs", "standard_a_spades", "standard_9_clubs", "standard_6_clubs", "standard_3_hearts"]
var learned: Dictionary = {}
var dismissed: Dictionary = {}

func reset() -> void:
	learned.clear()
	dismissed.clear()

func mark(id: String) -> void:
	learned[id] = true

func observe(result: Dictionary, deal: DealState) -> void:
	if not result.get("ok", false):
		return
	var action := String(result.get("action", ""))
	mark(action)
	if not result.get("drawn", []).is_empty():
		mark("draw")
	if action in ["new_meld", "extension"]:
		var meld := deal.get_meld(int(result.get("meld_id", -1)))
		if meld != null:
			mark("set" if meld.meld_type == MeldRules.TYPE_SET else "run")
	if action in ["keep", "dump"]:
		mark("phase_choice")
	if action == "phase_settlement":
		mark("last_call")
		mark("deadwood")
	if deal.current_phase == 2:
		mark("phase_two")

func opening_ids(period: String, cards: Array[CardData], equipped: Array[String] = []) -> Array[String]:
	if period == "morning":
		return MORNING_IDS.duplicate()
	var ids: Array[String] = []
	if period == "noon":
		# Bring a real changed/shiny physical card and matching ranks into play.
		for card in cards:
			if card.shiny or not card.gieo_properties.is_empty() or card.unique_id != "standard_%s_%s" % [card.rank.to_lower(), card.suit.to_lower()]:
				ids.append(card.unique_id)
				for other in cards:
					if other.unique_id != card.unique_id and other.rank_index == card.rank_index and ids.size() < 3:
						ids.append(other.unique_id)
				break
		for id in MORNING_IDS:
			if not ids.has(id):
				ids.append(id)
		if ids[0] == MORNING_IDS[0] and not equipped.is_empty():
			var relic: String = equipped[0]
			var preferred: Array[String] = []
			if relic in ["comb", "sunglasses"]:
				preferred = ["standard_4_clubs", "standard_5_clubs", "standard_6_clubs", "standard_7_clubs"]
			elif relic == "lipstick":
				preferred = ["standard_4_hearts", "standard_5_hearts", "standard_6_hearts", "standard_7_hearts"]
			elif relic in ["hard_candy", "buttons"]:
				preferred = ["standard_9_spades", "standard_9_hearts", "standard_9_diamonds", "standard_9_clubs"]
			for index in range(preferred.size() - 1, -1, -1):
				ids.erase(preferred[index])
				ids.push_front(preferred[index])
	return ids
