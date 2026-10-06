extends RefCounted
## Read-only projections. Formulae and transitions remain in the boss mechanics.
const Ox := preload("res://scripts/zodiac/rules/ox.gd")
const ACCENTS := PresentationTheme.ZODIAC_COLORS

static func accent(id: String) -> Color:
	return PresentationTheme.zodiac_color(id)

static func effective(rule: ZodiacBossRule) -> Dictionary:
	var state := rule.presentation()
	if rule.id != "dragon": return state
	var modifier: Dictionary = state.get("modifier", {}).duplicate(true)
	modifier.merge({"id": state.get("modifier_id", ""), "difficulty": rule.difficulty, "locked_ids": rule.locked_ids.duplicate()}, true)
	return modifier

static func hand_hint(rule: ZodiacBossRule, card: CardData, hand: Array[CardData]) -> Dictionary:
	var state := effective(rule)
	match String(state.get("id", "")):
		"ox":
			var points := 0
			if rule.id == "dragon": points = card.score_value() * int(state.get("burden_multiplier", 1))
			else:
				var near := MeldRules.near_meld_ids(hand).has(card.unique_id)
				points = Ox.new().burden_points(card.score_value(), int(state.get("burden_age", {}).get(card.unique_id, 0)) + 1, near, rule.difficulty)
			return {"kind": "ox", "caption": "−%d" % points, "detail": ZodiacCatalog.words("OX · next burden: %d points before the turn penalty multiplier. Play or discard this card to remove its burden.", "SỬU · gánh nặng lần tới: %d điểm trước hệ số phạt lượt. Hạ, nối hoặc bỏ lá này để hết gánh nặng.") % points,
				"strength": clampf(float(points) / maxf(card.score_value(), 1) / 8.0, 0.15, 1.0)}
		"goat":
			var rank := int(state.get("expected_rank", 0))
			var parity: bool = rule.difficulty == ZodiacCatalog.UNPLEASED and state.get("parity_required", true)
			if (rank == 0 or card.rank_index == rank) and (not parity or card.rank_index % 2 == int(state.get("turn_number", 1)) % 2):
				return {"kind": "goat", "caption": ZodiacCatalog.words("NOTE", "NHỊP"), "detail": ZodiacCatalog.words("GOAT · this Rank can start the next note. The whole committed play still has to follow the Rank sequence.", "MÙI · hạng này có thể mở nhịp tiếp. Toàn bộ lá vừa đánh vẫn phải theo chuỗi hạng."), "strength": 0.6}
		"snake":
			for command: Dictionary in state.get("commands", []):
				if command.status != "pending": continue
				if card.unique_id == command.card_id or card.unique_id in command.get("suggested_ids", []):
					return {"kind": "snake", "caption": ZodiacCatalog.action_label(command.action), "detail": command_text(command), "strength": 0.8}
				break
	return {}

static func command_text(command: Dictionary) -> String:
	var mark := "✓" if command.status == "fulfilled" else "×" if command.status == "violated" else "▶"
	var target: String = command.get("label", "")
	if command.has("drink_id"): target = DrinkCatalog.display_name(command.drink_id) + " · " + target
	if command.has("discard_label"): target += " → " + String(command.discard_label)
	if command.has("meld_id"): target += " · #%d" % int(command.meld_id)
	return "%s %s · %s" % [mark, ZodiacCatalog.action_label(command.action), target]

static func compact(state: Dictionary, deal) -> String:
	match String(state.id):
		"pig": return ZodiacCatalog.words("HELD ", "GIỮ ") + VndWallet.format_vnd(int(state.pool_vnd))
		"ox": return ZodiacCatalog.words("Next loss on each card", "Phạt tới trên từng lá")
		"horse": return "%s %d/2" % [ZodiacCatalog.action_label(state.required_action) if not String(state.required_action).is_empty() else ZodiacCatalog.words("PAIR", "CẶP"), int(state.pair_count)]
		"goat": return ZodiacCatalog.words("NEXT: ", "TIẾP: ") + (DeckManager.RANKS[int(state.expected_rank) - 1] if int(state.expected_rank) > 0 else ZodiacCatalog.words("first note", "nhịp đầu"))
		"rat": return ZodiacCatalog.words("MOUSE MELDS: %d", "PHỎM CỦA TÝ: %d") % deal.boss_melds.size()
		"tiger": return ZodiacCatalog.words("SNATCHED: %d", "ĐÃ VỒ: %d") % state.get("removed_ids", []).size()
		"snake":
			var pending := 0
			for command: Dictionary in state.get("commands", []):
				if command.status == "pending": pending += 1
			return ZodiacCatalog.words("COMMANDS LEFT: %d", "CÒN %d LỆNH") % pending
		"dragon": return ZodiacCatalog.words("THIS TURN: ", "LƯỢT NÀY: ") + ZodiacCatalog.display_name(state.get("modifier_id", ""))
	return ZodiacCatalog.state_text(state, deal).replace("\n", " · ")
