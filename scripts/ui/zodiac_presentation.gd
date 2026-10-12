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
			return {"kind": "ox", "caption": "−%d" % points, "detail": ZodiacCatalog.words("BUFFALO · next burden: %d points before the turn penalty multiplier. Play or discard this card to remove its burden.", "SỬU · gánh nặng lần tới: %d điểm trước hệ số phạt lượt. Hạ, nối hoặc bỏ lá này để hết gánh nặng.") % points,
				"strength": clampf(float(points) / maxf(card.score_value(), 1) / 8.0, 0.15, 1.0)}
		"goat":
			var rank := int(state.get("expected_rank", 0))
			var parity: bool = rule.difficulty == ZodiacCatalog.UNPLEASED and state.get("parity_required", true)
			var window: Array[int] = preload("res://scripts/zodiac/rules/goat.gd").accepted_ranks(rank)
			if (rank == 0 or card.rank_index in window) and (not parity or card.rank_index % 2 == int(state.get("turn_number", 1)) % 2):
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
		"rooster":
			if state.register_closed: return ZodiacCatalog.words("CLOSED · 0 VNĐ", "ĐÃ ĐÓNG · 0 VNĐ")
			if deal.current_phase == 2 and int(state.difficulty) == ZodiacCatalog.UNPLEASED: return ZodiacCatalog.words("EXTEND ONLY", "CHỈ NỐI PHỎM")
			return ZodiacCatalog.words("OPEN", "ĐANG MỞ")
		"cat": return ZodiacCatalog.words("Locked %d", "Khóa %d lá") % state.locked_ids.size()
		"dog": return ZodiacCatalog.words("LOYAL #%d", "TRUNG THÀNH #%d") % int(state.loyal_meld_id) if int(state.loyal_meld_id) >= 0 else ZodiacCatalog.words("LOYAL —", "TRUNG THÀNH —")
		"pig": return ZodiacCatalog.words("HELD ", "GIỮ ") + VndWallet.format_vnd(int(state.pool_vnd))
		"ox":
			var points := 0
			var near := MeldRules.near_meld_ids(deal.hand)
			for card: CardData in deal.hand:
				if card.fortune < 0: continue
				points += Ox.new().burden_points(card.intrinsic_value(), int(state.burden_age.get(card.unique_id, 0)) + 1, near.has(card.unique_id), state.difficulty)
			return ZodiacCatalog.words("Burden %d pts", "Gánh nặng %d điểm") % points
		"horse": return "%s %d/2" % [ZodiacCatalog.action_label(state.required_action) if not String(state.required_action).is_empty() else ZodiacCatalog.words("PAIR", "CẶP"), int(state.pair_count)]
		"goat": return ZodiacCatalog.words("RANKS: ", "HẠNG: ") + (ZodiacCatalog.rank_window_text(int(state.expected_rank)) if int(state.expected_rank) > 0 else ZodiacCatalog.words("first window", "nhóm đầu"))
		"rat": return ZodiacCatalog.words("RAT MELDS: %d", "PHỎM CỦA TÝ: %d") % deal.boss_melds.size()
		"tiger": return ZodiacCatalog.words("SNATCHED: %d", "ĐÃ VỒ: %d") % state.get("removed_ids", []).size()
		"snake":
			var commands: Array = state.get("commands", [])
			var limit := int(state.get("command_limit", ZodiacCatalog.tuning("snake", "command_count", state.difficulty)))
			var pending: bool = commands.any(func(command: Dictionary): return command.status == "pending")
			return ZodiacCatalog.words("CHARM %d/%d", "MÊ HOẶC %d/%d") % [commands.size(), limit] if pending else ZodiacCatalog.words("COMPLETE ✓", "ĐÃ XONG ✓")
		"dragon": return ZodiacCatalog.words("THIS TURN: ", "LƯỢT NÀY: ") + ZodiacCatalog.display_name(state.get("modifier_id", ""))
	return ZodiacCatalog.state_text(state, deal).replace("\n", " · ")

static func guidance(state: Dictionary, deal) -> String:
	match String(state.id):
		"rooster":
			if state.register_closed: return ZodiacCatalog.words("Legal plays pay 0 VNĐ until the next Phase.", "Bài hợp lệ trả 0 VNĐ tới Hiệp sau.")
			if deal.current_phase == 2 and int(state.difficulty) == ZodiacCatalog.UNPLEASED: return ZodiacCatalog.words("Extensions only this Phase.", "Hiệp này chỉ được nối Phỏm.")
			return ZodiacCatalog.words("Score before the discard deadline. Phase 2 reopens scoring.", "Ghi điểm trước hạn bỏ bài. Hiệp 2 mở lại trả thưởng.")
		"cat": return ZodiacCatalog.words("Phase 2: locked cards stay until the next refill.", "Hiệp 2: lá bị khóa phải ở lại tới lần bù bài sau.")
		"dog":
			if int(state.difficulty) == ZodiacCatalog.UNPLEASED: return ZodiacCatalog.words("One new Meld per Phase. Extend your LOYAL Meld for full pay.", "Mỗi Hiệp chỉ tạo một Phỏm. Nối Phỏm TRUNG THÀNH để nhận đủ.")
			return ZodiacCatalog.words("Extend your LOYAL Meld for full pay. Other Melds pay %d%%.", "Nối Phỏm TRUNG THÀNH để nhận đủ. Phỏm khác trả %d%%.") % int(ZodiacCatalog.tuning("dog", "other_payout_percent", state.difficulty))
	return ""

static func modifier_live(state: Dictionary, deal) -> String:
	var mini: Dictionary = state.get("modifier", {})
	match String(state.get("modifier_id", "")):
		"rat": return ZodiacCatalog.words("Melds %d", "Phỏm %d") % deal.boss_melds.size()
		"goat": return ZodiacCatalog.words("Ranks ", "Hạng ") + ZodiacCatalog.rank_window_text(int(mini.get("expected_rank", 0)))
		"snake":
			for command: Dictionary in mini.get("commands", []):
				if command.status == "pending": return command_text(command)
			return ZodiacCatalog.words("Complete ✓", "Đã xong ✓")
	return ZodiacCatalog.modifier_text(state, deal)
