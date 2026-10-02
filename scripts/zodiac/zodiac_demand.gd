class_name ZodiacDemand
extends RefCounted
## Value-only demand grammar. Prepared offers contain stable IDs, never Cards.
const CARD_VERBS := ["REMOVE_PROPERTY", "RESET", "SEAL", "SET_RANK", "SET_SUIT"]
const AUTHORITIES := ["PLAYER_CHOOSES", "ZODIAC_CHOOSES", "RANDOM", "OFFER_THREE_PLAYER_CHOOSES"]

static func make(verb: String, targeting: String = "ANY", authority: String = "PLAYER_CHOOSES", quantity: int = 1, destination: String = "", amount: int = 0, metadata: Dictionary = {}) -> Dictionary:
	return {"verb": verb, "targeting": targeting, "authority": authority, "quantity": quantity,
		"destination": destination, "resource_amount": amount, "metadata": metadata.duplicate(true), "target_ids": [], "offered_ids": []}

static func legal(card: CardData, demand: Dictionary) -> bool:
	match String(demand.get("verb", "")):
		"REMOVE_PROPERTY": return not card.gieo_properties.is_empty()
		"RESET": return card.has_permanent_changes()
		"SEAL": return not card.transformation_locked
		"SET_RANK": return not card.transformation_locked and String(demand.destination) in DeckManager.RANKS and card.rank != String(demand.destination)
		"SET_SUIT": return not card.transformation_locked and String(demand.destination) in DeckManager.SUITS and card.suit != String(demand.destination)
	return false

static func candidates(deck: Array[CardData], demand: Dictionary) -> Array[CardData]:
	var legal_cards: Array[CardData] = deck.filter(func(card: CardData): return legal(card, demand))
	return CardTargetQuery.pool(legal_cards, String(demand.targeting), int(demand.quantity))

static func player_controls(demand: Dictionary) -> bool:
	return demand.get("authority", "") in ["PLAYER_CHOOSES", "OFFER_THREE_PLAYER_CHOOSES"]

static func prepare(template: Dictionary, deck: Array[CardData], rng: RandomNumberGenerator, allow_fallback: bool = true) -> Dictionary:
	var demand := template.duplicate(true)
	demand.target_ids = []
	demand.offered_ids = []
	if int(demand.get("quantity", 0)) < 1 or demand.get("authority", "") not in AUTHORITIES: return {}
	if demand.verb not in CARD_VERBS: return demand
	var cards := candidates(deck, demand)
	if not CardTargetQuery.can_complete(cards, [], demand.targeting, demand.quantity):
		if not allow_fallback: return {}
		demand.targeting = "ANY"
		cards = candidates(deck, demand)
		if not CardTargetQuery.can_complete(cards, [], demand.targeting, demand.quantity): return {}
	if demand.targeting == "OFFER_THREE" or demand.authority == "OFFER_THREE_PLAYER_CHOOSES":
		if cards.size() < 3 or int(demand.quantity) != 1:
			if not allow_fallback: return {}
			demand.targeting = "ANY"
			demand.authority = "PLAYER_CHOOSES"
		else:
			demand.offered_ids = CardTargetQuery.physical_ids(CardTargetQuery.random_cards(cards, 3, rng))
			cards = CardTargetQuery.resolve_ids(cards, demand.offered_ids)
	if not player_controls(demand):
		var picked: Array[CardData] = []
		if demand.authority == "RANDOM":
			if String(demand.targeting).begins_with("SAME_SUIT_"): picked = CardTargetQuery.random_same_suit(cards, demand.quantity, rng)
			elif String(demand.targeting).begins_with("CONSECUTIVE_"): picked = CardTargetQuery.random_consecutive(cards, demand.quantity, rng)
			else: picked = CardTargetQuery.random_cards(cards, demand.quantity, rng)
		else:
			# Prefer valuable targets, with seeded tie ordering. Every chosen card
			# must leave a complete group available; greed cannot strand an offer.
			cards = CardTargetQuery.shuffled(cards, rng)
			cards.sort_custom(func(a: CardData, b: CardData): return a.gieo_properties.size() > b.gieo_properties.size() if a.gieo_properties.size() != b.gieo_properties.size() else a.rank_index > b.rank_index)
			for card in cards:
				var next: Array[CardData] = picked.duplicate()
				next.append(card)
				if CardTargetQuery.can_complete(cards, next, demand.targeting, demand.quantity): picked = next
				if picked.size() == int(demand.quantity): break
		if picked.size() != int(demand.quantity): return {}
		demand.target_ids = CardTargetQuery.physical_ids(picked)
	return demand

static func selection_valid(deck: Array[CardData], demand: Dictionary, ids: Array) -> bool:
	if ids.size() != int(demand.quantity): return false
	var selected := CardTargetQuery.resolve_ids(deck, ids)
	if selected.size() != ids.size(): return false
	if not demand.offered_ids.is_empty():
		for id in ids:
			if id not in demand.offered_ids: return false
	if not player_controls(demand) and ids != demand.target_ids: return false
	return CardTargetQuery.can_complete(candidates(deck, demand), selected, demand.targeting, demand.quantity)

static func apply(card: CardData, demand: Dictionary) -> Dictionary:
	if not legal(card, demand): return {}
	var before := card.permanent_snapshot()
	match String(demand.verb):
		"REMOVE_PROPERTY": card.alter_for_zodiac("remove_property")
		"RESET": card.alter_for_zodiac("reset")
		"SEAL": card.alter_for_zodiac("seal")
		"SET_RANK": card.apply_rank(demand.destination, DeckManager.RANKS.find(demand.destination) + 1)
		"SET_SUIT": card.apply_suit(demand.destination)
	return {"unique_id": card.unique_id, "before": before, "after": card.permanent_snapshot()}

static func describe(demand: Dictionary) -> String:
	var verb := String(demand.get("verb", ""))
	if verb == "PAY": return ZodiacCatalog.words("Pay %s now.", "Trả ngay %s.") % VndWallet.format_vnd(demand.resource_amount)
	if verb == "GIFT_RELIC": return ZodiacCatalog.words("Give %s away for this run, including its equipped effect.", "Tặng %s trong lượt chơi này, kể cả hiệu ứng đang đeo.") % String(RelicCatalog.DEFINITIONS[demand.metadata.relic_id].name)
	if verb == "PROMISE":
		match String(demand.metadata.get("condition", "")):
			"early_score": return ZodiacCatalog.words("Next Deal: score a Meld or Extension before its first mandatory discard. Result at AFTERNOON.", "Ván kế: ghi điểm Tạo/Nối Phỏm trước lần bỏ bắt buộc đầu tiên. Kiểm tra vào BUỔI CHIỀU.")
			"wallet_floor": return ZodiacCatalog.words("Next Deal: keep at least %s throughout the Deal. Result at AFTERNOON.", "Ván kế: luôn giữ ít nhất %s suốt Ván. Kiểm tra vào BUỔI CHIỀU.") % VndWallet.format_vnd(demand.resource_amount)
			"do_action": return ZodiacCatalog.words("Next Deal: %s at least once. Result at AFTERNOON.", "Ván kế: %s ít nhất một lần. Kiểm tra vào BUỔI CHIỀU.") % ZodiacCatalog.action_label(demand.metadata.action)
			"dont_action": return ZodiacCatalog.words("Next Deal: do not %s. Result at AFTERNOON.", "Ván kế: không %s. Kiểm tra vào BUỔI CHIỀU.") % ZodiacCatalog.action_label(demand.metadata.action)
	var verbs := {"REMOVE_PROPERTY": ZodiacCatalog.words("Remove the last Gieo property", "Bỏ thuộc tính Gieo cuối"), "RESET": ZodiacCatalog.words("Reset to original values (seals remain)", "Hoàn nguyên về lá gốc (vẫn giữ khóa)"), "SEAL": ZodiacCatalog.words("Seal transformations for this run", "Khóa biến đổi hết lượt chơi"), "SET_RANK": ZodiacCatalog.words("Set rank to ", "Đổi hạng thành ") + String(demand.destination), "SET_SUIT": ZodiacCatalog.words("Set suit to ", "Đổi chất thành ") + TranslationServer.translate("SUIT_" + String(demand.destination).to_upper())}
	var rules := {"ANY": ZodiacCatalog.words("any legal cards", "lá hợp lệ bất kỳ"), "CHOOSE_ONE": ZodiacCatalog.words("one legal card", "một lá hợp lệ"), "OFFER_THREE": ZodiacCatalog.words("one of the three shown cards", "một trong ba lá đã đưa"), "RANDOM": ZodiacCatalog.words("random legal cards", "lá hợp lệ ngẫu nhiên"), "SAME_SUIT_2": ZodiacCatalog.words("same current suit", "cùng chất hiện tại"), "SAME_SUIT_3": ZodiacCatalog.words("same current suit", "cùng chất hiện tại"), "CONSECUTIVE_2": ZodiacCatalog.words("consecutive current ranks", "hạng hiện tại liên tiếp"), "CONSECUTIVE_3": ZodiacCatalog.words("consecutive current ranks", "hạng hiện tại liên tiếp"), "HAS_GIEO_PROPERTY": ZodiacCatalog.words("cards with Gieo properties", "lá có thuộc tính Gieo"), "HAS_GOLD_PROPERTY": ZodiacCatalog.words("cards with Gold properties", "lá có thuộc tính Vàng"), "TRANSFORMED_ANY": ZodiacCatalog.words("transformed cards", "lá đã đổi hạng hoặc chất"), "TRANSFORMED_RANK": ZodiacCatalog.words("rank-transformed cards", "lá đã đổi hạng"), "TRANSFORMED_SUIT": ZodiacCatalog.words("suit-transformed cards", "lá đã đổi chất"), "HIGHEST_PROPERTY_COUNT": ZodiacCatalog.words("cards with the most properties", "lá có nhiều thuộc tính nhất")}
	var authority := ZodiacCatalog.words("You choose", "Bạn chọn") if player_controls(demand) else ZodiacCatalog.words("Zodiac chooses (shown below)", "Con Giáp chọn (hiện bên dưới)") if demand.authority == "ZODIAC_CHOOSES" else ZodiacCatalog.words("Random choice (shown below)", "Chọn ngẫu nhiên (hiện bên dưới)")
	return "%s · %d\n%s · %s" % [verbs.get(verb, verb), int(demand.quantity), rules.get(demand.targeting, demand.targeting), authority]
