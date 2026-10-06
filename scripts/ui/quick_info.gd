class_name QuickInfo
extends RefCounted
## Short labels for play. Full rules live in the Handbook and owning catalogs.
static func words(en: String, vi: String) -> String:
	return ZodiacCatalog.words(en, vi)

static func first_sentence(copy: String) -> String:
	var first := copy.strip_edges().get_slice("\n", 0)
	var sentence := RegEx.new()
	sentence.compile("[.!?](?:\\s|$)")
	var end := sentence.search(first)
	return first.substr(0, end.get_start() + 1) if end != null else first

static func drink(id: String) -> String:
	match id:
		DrinkCatalog.TRA_DA: return words("+1 optional discard / Turn", "+1 lần bỏ tùy chọn / Lượt")
		DrinkCatalog.NUOC_VOI: return words("Recover 1 Meld card / Phase", "Lấy lại 1 lá Phỏm / Hiệp")
		DrinkCatalog.NHAN_TRAN: return words("Swap 1 card ↔ this Phase's discard / Turn", "Đổi 1 lá ↔ bài bỏ hiệp này / Lượt")
		DrinkCatalog.SAM_DUA: return words("Keep ≤3 cards → Phase 2", "Giữ ≤3 lá → Hiệp 2")
		DrinkCatalog.DEN_DA: return words("Swap 1 card ↔ any discard / Turn", "Đổi 1 lá ↔ bài bỏ bất kỳ / Lượt")
		DrinkCatalog.NAU_DA: return words("Recover 1 whole Meld / Phase", "Lấy lại 1 Phỏm / Hiệp")
		DrinkCatalog.BAC_XIU: return words("Keep any cards → Phase 2", "Giữ bài tùy chọn → Hiệp 2")
		DrinkCatalog.STING: return words("Play 1 pair / Phase", "Hạ 1 đôi / Hiệp")
		DrinkCatalog.BO_HUC: return words("Play 1 pair / Turn", "Hạ 1 đôi / Lượt")
		DrinkCatalog.C2_ICED_TEA: return words("1 mixed-suit Run / Deal", "1 Sảnh khác chất / Ván")
		DrinkCatalog.MIA_TAC: return words("Runs: Hearts + Diamonds", "Sảnh: Cơ + Rô")
		DrinkCatalog.MIA_SAU_RIENG: return words("Runs: Spades + Clubs", "Sảnh: Bích + Tép")
	return ""

static func demand(offer: Dictionary) -> String:
	if offer.is_empty(): return ""
	if offer.has("interaction"):
		var actions := {"card_use": words("Use", "Dùng"), "card_alter": words("Change", "Đổi"), "permanent_change": words("Change", "Đổi"), "card_change": words("Change", "Đổi"), "relic_loss": words("Lose relic", "Mất di vật")}
		var action: String = actions.get(offer.interaction, words("Interact", "Tương tác"))
		if offer.get("polarity", "") == "DONT": action = words("Don't ", "Không ") + action.to_lower()
		return action + " · " + (words("next Deal", "ván kế") if offer.get("window", "") == "NEXT_DEAL" else words("until return", "tới lần gặp sau"))
	var verb: String = offer.get("verb", "")
	if verb == "PAY": return words("Pay ", "Trả ") + VndWallet.format_vnd(-int(offer.resource_amount))
	if verb == "GIFT_RELIC": return words("Give ", "Tặng ") + RelicCatalog.display_name(offer.metadata.relic_id)
	if verb == "PROMISE":
		var meta: Dictionary = offer.get("metadata", {})
		match String(meta.get("condition", "")):
			"early_score": return words("Next Deal: score before discard #1", "Ván kế: ghi điểm trước lần bỏ #1")
			"wallet_floor": return words("Next Deal: wallet ≥ ", "Ván kế: ví ≥ ") + VndWallet.format_vnd(int(offer.resource_amount))
			"do_action": return words("Next Deal: ", "Ván kế: ") + ZodiacCatalog.action_label(meta.action) + " ≥1"
			"dont_action": return words("Next Deal: no ", "Ván kế: không ") + ZodiacCatalog.action_label(meta.action)
	var actions := {"REMOVE_PROPERTY": words("Remove last property", "Bỏ thuộc tính cuối"), "RESET": words("Reset · seals stay", "Hoàn nguyên · giữ khóa"), "SEAL": words("Seal for run", "Khóa hết lượt chơi"), "SET_RANK": words("Rank → ", "Hạng → ") + String(offer.get("destination", "")), "SET_SUIT": words("Suit → ", "Chất → ") + String(offer.get("destination", ""))}
	var groups := {"ANY": "", "CHOOSE_ONE": "", "OFFER_THREE": words("1 of 3", "1 trong 3"), "SAME_SUIT_2": words("Same suit", "Cùng chất"), "SAME_SUIT_3": words("Same suit", "Cùng chất"), "CONSECUTIVE_2": words("Consecutive ranks", "Hạng liên tiếp"), "CONSECUTIVE_3": words("Consecutive ranks", "Hạng liên tiếp"), "HAS_GIEO_PROPERTY": words("With property", "Có thuộc tính"), "HAS_GOLD_PROPERTY": words("With Gold", "Có Vàng"), "TRANSFORMED_ANY": words("Changed cards", "Lá đã đổi"), "TRANSFORMED_RANK": words("Changed rank", "Đã đổi hạng"), "TRANSFORMED_SUIT": words("Changed suit", "Đã đổi chất"), "HIGHEST_PROPERTY_COUNT": words("Most properties", "Nhiều thuộc tính nhất")}
	var line: String = actions.get(verb, verb) + " · " + (words("%d card(s)", "%d lá") % int(offer.get("quantity", 1)))
	var group: String = groups.get(offer.get("targeting", ""), "")
	if not group.is_empty(): line += " · " + group
	return line + "\n" + (words("You choose", "Bạn chọn") if ZodiacDemand.player_controls(offer) else words("Random", "Ngẫu nhiên") if offer.get("authority", "") == "RANDOM" else words("Zodiac chooses", "Con Giáp chọn"))

static func promise(terms: Dictionary, deck: Array[CardData]) -> String:
	var negative: bool = terms.get("polarity", "") == "DONT"
	var action := words("Don't use", "Không dùng") if negative else words("Use", "Dùng")
	if terms.get("interaction", "") == "card_alter": action = words("Don't change", "Không đổi") if negative else words("Change", "Đổi")
	if terms.get("target_kind", "") == "RELIC":
		return (words("Keep", "Giữ") if negative else words("Lose", "Mất")) + " " + RelicCatalog.display_name(terms.get("relic_id", ""))
	var labels: Array[String] = []
	for card in CardTargetQuery.resolve_ids(deck, terms.get("target_ids", [])): labels.append(card.short_label())
	return action + " " + ", ".join(labels)
