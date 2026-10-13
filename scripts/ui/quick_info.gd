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
	if offer.get("condition", "") == "ordered_scoring": return words("First plays: Meld → Extend", "Hạ đầu: Phỏm → Nối") + (words(" → Meld", " → Phỏm") if offer.sequence.size() == 3 else "")
	if offer.get("condition", "") == "no_recovery": return words("No Drink recovery · ", "Không lấy bài bằng Nước · ") + (words("P1", "H1") if int(offer.deal_phase) == 1 else words("whole Deal", "cả Ván"))
	if offer.has("interaction"):
		if offer.get("condition", "") == "recover_then_play": return words("Next Deal: recover a card, then play it", "Ván tới: lấy lại một lá rồi hạ")
		if offer.get("condition", "") == "extension_cards": return words("Next Deal: Extend ", "Ván tới: Nối ") + str(offer.card_count) + words(" different cards", " lá khác nhau")
		if offer.get("condition", "") == "new_meld_size": return words("Next Deal: new Meld ≥", "Ván tới: Phỏm mới ≥") + str(offer.card_count) + words(" cards", " lá")
		if offer.get("condition", "") == "opening_high_rank": return words("P1: opening high card", "H1: lá cao nhất mở đầu") + (words(" before discard #1", " trước lần bỏ #1") if offer.get("before_first_discard", true) else words(" before settlement", " trước khi chốt"))
		if offer.interaction == "card_play" and offer.get("recover_first", false): return words("Next Deal: recover chosen card, then play it", "Ván tới: lấy lại lá chọn rồi hạ")
		if offer.interaction == "card_play" and int(offer.get("minimum_cards", 0)) > 0: return words("Next Deal: chosen card in new Meld ≥", "Ván tới: lá chọn trong Phỏm mới ≥") + str(offer.minimum_cards)
		if offer.get("condition", "") == "same_turn_actions": return words("One Turn: ", "Một Lượt: ") + (words("2 Melds or 2 Extensions", "2 Phỏm hoặc 2 Nối") if offer.get("same_action", true) else words("2 Meld/Extension actions", "2 nước Phỏm/Nối"))
		if offer.get("condition", "") == "distinct_ranks": return words("Next Deal: score with ", "Ván tới: ghi điểm bằng ") + str(offer.rank_count) + words(" different ranks", " hạng khác nhau")
		if offer.get("condition", "") == "rank_run": return words("One play: ", "Một nước: ") + str(offer.rank_count) + words(" consecutive new ranks", " hạng mới liên tiếp")
		if offer.get("same_turn", false) and offer.get("condition", "") == "extend_first_meld": return words("P1: first Meld + Extension in one Turn", "H1: Phỏm đầu + Nối trong một Lượt")
		if offer.interaction == "card_play" and offer.get("action", "") == "extension": return words("Next Deal: add chosen card through Extension", "Ván tới: thêm lá chọn bằng Nối")
		if offer.interaction == "card_play" and offer.get("adjacent_rank", false): return words("Next Deal: chosen card + adjacent new rank", "Ván tới: lá chọn + hạng mới liền kề")
		if offer.get("condition", "") == "scoring_income": return words("Next Deal: earn ", "Ván tới: kiếm ") + VndWallet.format_vnd(int(offer.resource_amount)) + words(" from Melds/Extensions", " bằng Phỏm/Nối")
		if offer.get("condition", "") == "settlement_deadwood": return words("P1 final Deadwood ≤ ", "Bài rác cuối H1 ≤ ") + str(offer.point_limit) + " PTS"
		if offer.interaction == "wallet_floor": return words("Keep wallet ≥ ", "Giữ ví ≥ ") + VndWallet.format_vnd(int(offer.resource_amount)) + words(" until return", " tới lần gặp sau")
		if offer.interaction == "card_play" and int(offer.get("deal_phase", 0)) == 1: return words("P1: play your chosen card in a Meld", "H1: hạ lá đã chọn vào Phỏm")
		if offer.interaction == "card_play" and offer.get("require_income", false): return words("Next Deal: chosen card in a paying Meld", "Ván tới: hạ lá chọn vào Phỏm trả tiền")
		if offer.interaction == "deal_action" and offer.get("condition", "") == "do_action" and int(offer.get("deal_phase", 0)) == 2: return words("P2: Extension ≥1", "H2: Nối ≥1")
		if offer.get("condition", "") == "action_variety": return words("Next Deal: score with Meld + Extension", "Ván tới: ghi điểm bằng Phỏm + Nối")
		if offer.get("condition", "") == "extend_first_meld": return words("P1: create and extend your first Meld", "H1: tạo rồi Nối Phỏm đầu tiên")
		if offer.interaction == "card_play": return words("Next Deal: play your chosen card in a Meld", "Ván tới: hạ lá đã chọn vào Phỏm")
		if offer.interaction == "deal_action":
			if offer.get("condition", "") == "early_score":
				return words("Next Deal: score in Phase 1 before discard #1", "Ván kế: ghi điểm ở Hiệp 1 trước lần bỏ #1")
			return (words("Phase 1: new Meld ≥1", "Hiệp 1: hạ Phỏm mới ≥1") if offer.get("action", "") == "new_meld" else words("Next Deal: Extension ≥1 · either Phase", "Ván kế: Nối ≥1 · Hiệp nào cũng được"))
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
	if terms.get("condition", "") == "ordered_scoring": return words("Meld → Extend", "Phỏm → Nối") + (words(" → Meld", " → Phỏm") if terms.sequence.size() == 3 else "")
	if terms.get("condition", "") == "no_recovery": return words("No recovery · ", "Không lấy lại · ") + (words("P1", "H1") if int(terms.deal_phase) == 1 else words("P1/P2", "H1/H2"))
	if terms.get("condition", "") == "recover_then_play": return words("Recover → play", "Lấy lại → hạ")
	if terms.get("condition", "") == "extension_cards": return words("Extend cards ≥", "Lá Nối ≥") + str(terms.card_count)
	if terms.get("condition", "") == "new_meld_size": return words("New Meld ≥", "Phỏm mới ≥") + str(terms.card_count)
	if terms.get("condition", "") == "opening_high_rank": return words("Opening high · P1", "Cao nhất mở đầu · H1")
	if terms.get("condition", "") == "same_turn_actions": return words("One Turn: 2 matching plays", "Một Lượt: 2 nước cùng loại") if terms.get("same_action", true) else words("One Turn: 2 plays", "Một Lượt: 2 nước")
	if terms.get("condition", "") == "distinct_ranks": return words("Scoring ranks: ", "Hạng ghi điểm: ") + str(terms.rank_count)
	if terms.get("condition", "") == "rank_run": return words("New ranks in order ≥", "Hạng mới liên tiếp ≥") + str(terms.rank_count)
	if terms.get("condition", "") == "extend_first_meld" and terms.has("same_turn"): return words("P1: first Meld + Extend", "H1: Phỏm đầu + Nối")
	if terms.get("condition", "") == "scoring_income": return words("Meld/Extend: ", "Phỏm/Nối: ") + VndWallet.format_vnd(int(terms.resource_amount))
	if terms.get("condition", "") == "settlement_deadwood": return words("P1 final Deadwood≤", "Bài rác cuối H1≤") + str(terms.point_limit)
	if terms.get("interaction", "") == "wallet_floor": return words("Wallet ≥ ", "Ví ≥ ") + VndWallet.format_vnd(int(terms.resource_amount))
	if terms.get("condition", "") == "do_action" and int(terms.get("deal_phase", 0)) == 2: return words("P2: Extension ≥1", "H2: Nối ≥1")
	if terms.get("condition", "") == "action_variety": return words("Score with Meld + Extension · P1/P2", "Ghi điểm bằng Phỏm + Nối · H1/H2")
	if terms.get("condition", "") == "extend_first_meld": return words("P1: extend your first new Meld", "H1: Nối Phỏm mới đầu tiên")
	if terms.get("interaction", "") == "deal_action":
		if terms.get("condition", "") == "early_score": return words("Score before discard #1", "Điểm trước lần bỏ #1")
		if terms.get("action", "") == "new_meld": return words("P1: new Meld ≥1", "H1: Phỏm mới ≥1")
		return words("Extension ≥1 · P1/P2", "Nối ≥1 · H1/H2")
	var negative: bool = terms.get("polarity", "") == "DONT"
	var action := words("Don't use", "Không dùng") if negative else words("Use", "Dùng")
	if terms.get("interaction", "") == "card_alter": action = words("Don't change", "Không đổi") if negative else words("Change", "Đổi")
	if terms.get("target_kind", "") == "RELIC":
		return (words("Keep", "Giữ") if negative else words("Lose", "Mất")) + " " + RelicCatalog.display_name(terms.get("relic_id", ""))
	var labels: Array[String] = []
	for card in CardTargetQuery.resolve_ids(deck, terms.get("target_ids", [])): labels.append(card.short_label())
	if terms.get("interaction", "") == "card_play": action = words("Play in a Meld:", "Hạ vào Phỏm:")
	if terms.get("interaction", "") == "card_play" and int(terms.get("deal_phase", 0)) == 1: action = words("P1: play in Meld:", "H1: hạ vào Phỏm:")
	if terms.get("interaction", "") == "card_play" and terms.get("require_income", false): action = words("Paying play:", "Nước trả tiền:")
	if terms.get("interaction", "") == "card_play" and terms.get("action", "") == "extension": action = words("Extend:", "Nối:")
	if terms.get("interaction", "") == "card_play" and terms.get("adjacent_rank", false): action = words("With neighbor:", "Cùng lá liền kề:")
	if terms.get("interaction", "") == "card_play" and terms.get("recover_first", false): action = words("Recover/play:", "Lấy lại/hạ:")
	if terms.get("interaction", "") == "card_play" and int(terms.get("minimum_cards", 0)) > 0: action = words("New ≥", "Mới ≥") + str(terms.minimum_cards) + ":"
	return action + " " + ", ".join(labels)

static func promise_status(pending: Dictionary, deck: Array[CardData]) -> String:
	var terms: Dictionary = pending.accepted_terms
	if terms.get("condition", "") == "ordered_scoring":
		var cursor := mini(int(pending.get("sequence_cursor", 0)), terms.sequence.size())
		var progress := "%d/%d" % [cursor, terms.sequence.size()]
		if cursor >= terms.sequence.size(): return words("Phrase: ", "Câu nhạc: ") + progress
		return words("Next: ", "Tiếp: ") + (words("Meld", "Phỏm") if terms.sequence[cursor] == "new_meld" else words("Extend", "Nối")) + " · " + progress
	if terms.get("condition", "") == "recover_then_play":
		return words("Recovered + played", "Đã lấy lại + hạ") if pending.get("matched", false) else words("Recovered · play next", "Đã lấy lại · chờ hạ") if not pending.get("recovered_ids", []).is_empty() else words("Recover → play", "Lấy lại → hạ")
	if terms.get("condition", "") == "extension_cards":
		return words("Added cards: ", "Lá mới: ") + "%d / %d" % [mini(pending.get("extended_ids", []).size(), int(terms.card_count)), int(terms.card_count)]
	if terms.get("condition", "") == "opening_high_rank":
		var rank: int = pending.get("opening_rank", 0)
		var deadline := words("Before discard #1: ", "Trước bỏ #1: ") if terms.get("before_first_discard", true) else words("P1 high: ", "Cao H1: ")
		return deadline + (DeckManager.RANKS[rank - 1] if rank in range(1, 14) else "?")
	if terms.get("condition", "") == "same_turn_actions":
		var counts: Dictionary = pending.get("turn_actions", {})
		var count := maxi(int(counts.get("new_meld", 0)), int(counts.get("extension", 0))) if terms.get("same_action", true) else int(counts.get("new_meld", 0)) + int(counts.get("extension", 0))
		return (words("Same type: ", "Cùng loại: ") if terms.get("same_action", true) else words("This Turn: ", "Lượt này: ")) + "%d / %d" % [mini(count, int(terms.action_count)), int(terms.action_count)]
	if terms.get("condition", "") == "distinct_ranks":
		return words("Ranks: ", "Hạng: ") + "%d / %d" % [mini(pending.get("scored_ranks", []).size(), int(terms.rank_count)), int(terms.rank_count)]
	if terms.get("condition", "") == "scoring_income":
		return VndWallet.format_amount(mini(int(pending.get("earned_vnd", 0)), int(terms.resource_amount))) + " / " + VndWallet.format_vnd(int(terms.resource_amount))
	return promise(terms, deck)
