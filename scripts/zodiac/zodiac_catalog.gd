class_name ZodiacCatalog
extends RefCounted
## One boss difficulty axis. NEUTRAL is accepted only as a legacy save alias.
const PLEASED := 1
const NORMAL := 2
const UNPLEASED := 3
const TUNING := {
	"rooster": {"discard_deadline": [3, 2, 1], "dragon_paid_actions": [3, 2, 1]},
	"cat": {"lock_count": [1, 2, 3]},
	"dog": {"other_payout_percent": [50, 0, 0]},
	"monkey": {"allowed_repeats": [2, 1, 0], "sequence_length": 3},
	"pig": {"baseline_target_vnd": 50_000, "target_percent": [80, 100, 120], "siphon_percent": [20, 30, 40], "bank_loss_percent": 50},
	"ox": {"grace_turns": [1, 0, 0], "near_add_points": 5, "near_multiplier": 2, "dragon_multiplier": [2, 2, 4]},
	"horse": {"matching_actions": 2, "incomplete_grace": [1, 0, 0], "phase_turn_limit": [4, 4, 2]},
	"goat": {"initial_rank": 0, "mistake_grace": [1, 0, 0]},
	"rat": {"borrow_limit": [2, 3, 4]},
	"dragon": {"target_percent": [80, 100, 120], "no_history_target_vnd": 50_000},
	"snake": {"command_count": [1, 2, 3], "dragon_command_count": 1},
	"tiger": {"near_weight": 10_000, "meld_weight": 100, "extension_weight": 10, "rank_weight": 10},
}
const PAIRS := [["rooster", "cat"], ["dog", "monkey"], ["pig", "ox"], ["horse", "goat"], ["rat", "tiger"], ["snake"]]
const DAY_PAIRS := [0, 1, 2, 3, 4, 5, -1]
## Daytime personalities are independent of the already authored evening rules.
## Missing profiles remain inert, so new bosses do not inherit invented demands.
const NEGOTIATION_PROFILES := {
	"rooster": {"demand_range": [2, 4], "thresholds": [1, 2], "refusal_pleasing": true,
		"preferred_verbs": ["RESET", "REMOVE_PROPERTY", "SEAL", "SET_RANK"],
		"preferred_targeting": ["HIGHEST_PROPERTY_COUNT", "SAME_SUIT_3", "TRANSFORMED_ANY"],
		"preferred_authority": "ZODIAC_CHOOSES", "haggle_tendencies": ["severity", "quantity", "authority", "money", "favorite_relic", "promise"],
		"demands": [
			{"verb": "RESET", "targeting": "HIGHEST_PROPERTY_COUNT", "authority": "ZODIAC_CHOOSES", "quantity": 1},
			{"verb": "REMOVE_PROPERTY", "targeting": "HAS_GOLD_PROPERTY", "authority": "OFFER_THREE_PLAYER_CHOOSES", "quantity": 1},
			{"verb": "SEAL", "targeting": "SAME_SUIT_3", "authority": "ZODIAC_CHOOSES", "quantity": 3},
			{"verb": "SET_RANK", "targeting": "ANY", "authority": "PLAYER_CHOOSES", "quantity": 1, "destination": "2"},
			{"verb": "PAY", "resource_amount": 5000}],
		"promises": [{"condition": "early_score"}, {"condition": "do_action", "action": "extension"}]},

}
## Read-only adapter for already-started pre-persuasion Cat saves.
const LEGACY_CAT_PROFILE := {"demand_range": [2, 3], "thresholds": [1, 2], "refusal_pleasing": true,
		"preferred_verbs": ["SEAL", "RESET", "SET_SUIT"],
		"preferred_targeting": ["ANY", "TRANSFORMED_SUIT", "CONSECUTIVE_2"],
		"preferred_authority": "PLAYER_CHOOSES", "haggle_tendencies": ["authority", "severity", "quantity", "offer_three", "money", "favorite_relic", "promise"],
		"demands": [
			{"verb": "SEAL", "targeting": "CHOOSE_ONE", "authority": "PLAYER_CHOOSES", "quantity": 1},
			{"verb": "RESET", "targeting": "TRANSFORMED_ANY", "authority": "ZODIAC_CHOOSES", "quantity": 1},
			{"verb": "SET_SUIT", "targeting": "CONSECUTIVE_2", "authority": "RANDOM", "quantity": 2, "destination": "Clubs"},
			{"verb": "REMOVE_PROPERTY", "targeting": "HAS_GIEO_PROPERTY", "authority": "OFFER_THREE_PLAYER_CHOOSES", "quantity": 1},
			{"verb": "PAY", "resource_amount": 5000}],
		"promises": [{"condition": "wallet_floor", "resource_amount": 5000}, {"condition": "dont_action", "action": "extension"}]}
const CAT_PERSUASION := preload("res://scripts/zodiac/content/cat_tier_1.gd")
const DEFINITIONS := {
	"rooster": {"thresholds": [1, 2], "deadlines": {"PLEASED": 3, "NORMAL": 2, "NEUTRAL": 2, "UNPLEASED": 1},
		"favorites": ["toothpicks", "sunflower_seeds"], "favorite_tags": ["practical"],
		"unlock": {"requests_resolved": 4, "requests_refused_successfully": 1, "pleased_victories": 1},
		"sprite": "res://assets/zodiacboss/rooster.png", "emblem": {"id": "rooster", "extensions": {}}},
	"cat": {"thresholds": [1, 2], "locks": {"PLEASED": 1, "NORMAL": 2, "NEUTRAL": 2, "UNPLEASED": 3},
		"favorites": ["hair_clip", "sunglasses"], "favorite_tags": ["adornment"],
		"unlock": {"requests_resolved": 4, "restraint_kept": 1, "pleased_victories": 1},
		"sprite": "res://assets/zodiacboss/cat.png", "emblem": {"id": "cat", "extensions": {}}},
	"dog": {"thresholds": [1, 2], "favorites": [], "favorite_tags": [], "unlock": {"requests_resolved": 4, "pleased_victories": 1}, "sprite": "res://assets/zodiacboss/dog.png", "emblem": {"id": "dog", "extensions": {}}},
	"monkey": {"thresholds": [1, 2], "favorites": [], "favorite_tags": [], "unlock": {"requests_resolved": 4, "pleased_victories": 1}, "sprite": "res://assets/zodiacboss/monkey.png", "emblem": {"id": "monkey", "extensions": {}}},
	"pig": {"thresholds": [1, 2], "favorites": [], "favorite_tags": [], "unlock": {"requests_resolved": 4, "pleased_victories": 1}, "sprite": "res://assets/zodiacboss/pig.png", "emblem": {"id": "pig", "extensions": {}}},
	"ox": {"thresholds": [1, 2], "favorites": [], "favorite_tags": [], "unlock": {"requests_resolved": 4, "pleased_victories": 1}, "sprite": "res://assets/zodiacboss/ox.png", "emblem": {"id": "ox", "extensions": {}}},
	"horse": {"thresholds": [1, 2], "favorites": [], "favorite_tags": [], "unlock": {"requests_resolved": 4, "pleased_victories": 1}, "sprite": "res://assets/zodiacboss/horse.png", "emblem": {"id": "horse", "extensions": {}}},
	"goat": {"thresholds": [1, 2], "favorites": [], "favorite_tags": [], "unlock": {"requests_resolved": 4, "pleased_victories": 1}, "sprite": "res://assets/zodiacboss/goat.png", "emblem": {"id": "goat", "extensions": {}}},
	"rat": {"thresholds": [1, 2], "favorites": [], "favorite_tags": [], "unlock": {"requests_resolved": 4, "pleased_victories": 1}, "sprite": "res://assets/zodiacboss/mouse.png", "emblem": {"id": "rat", "extensions": {}}},
	"tiger": {"thresholds": [1, 2], "favorites": [], "favorite_tags": [], "unlock": {"requests_resolved": 4, "pleased_victories": 1}, "sprite": "res://assets/zodiacboss/tiger.png", "emblem": {"id": "tiger", "extensions": {}}},
	"snake": {"thresholds": [1, 2], "favorites": [], "favorite_tags": [], "unlock": {"requests_resolved": 4, "pleased_victories": 1}, "sprite": "res://assets/zodiacboss/snake.png", "emblem": {"id": "snake", "extensions": {}}},
	"dragon": {"thresholds": [1, 2], "favorites": [], "favorite_tags": [], "unlock": {"requests_resolved": 4, "pleased_victories": 1}, "sprite": "res://assets/zodiacboss/dragon.png", "emblem": {"id": "dragon", "extensions": {}}},
}

static func words(en: String, vi: String) -> String:
	return vi if TranslationServer.get_locale().begins_with("vi") else en

static func negotiation_profile(id: String, legacy_cat: bool = false) -> Dictionary:
	if id == "cat" and legacy_cat: return LEGACY_CAT_PROFILE.duplicate(true)
	return NEGOTIATION_PROFILES.get(id, {}).duplicate(true)

static func persuasion_nodes(id: String) -> Array:
	return CAT_PERSUASION.NODES.duplicate(true) if id == "cat" else []

static func persuasion_content_rank(tier: Variant) -> int:
	var label := str(tier)
	return label.trim_suffix("+").to_int() * 2 + (1 if label.ends_with("+") else 0)

static func persuasion_config(id: String) -> Dictionary:
	return CAT_PERSUASION.CONFIG.duplicate(true) if id == "cat" else {}

static func persuasion_special(id: String, history: Dictionary) -> Dictionary:
	# Specials are authored overrides, never a random content bucket.
	for node: Dictionary in persuasion_config(id).get("special", []):
		var eligible := true
		for flag: String in node.get("requirements", {}).get("history", {}):
			if int(history.get(flag, 0)) < int(node.requirements.history[flag]): eligible = false
		if eligible: return node.duplicate(true)
	return {}

static func patience_disposition(patience: int) -> String:
	return "PLEASED" if patience >= 4 else "NORMAL" if patience >= 2 else "UNPLEASED"

static func relationship_label(tier: int) -> String:
	return words(["STRANGER", "FAMILIAR", "KINDRED", "CONFIDANT", "COMPANION"][clampi(tier, 1, 5) - 1],
		["KHÁCH LẠ", "QUEN MẶT", "HỢP CẠ", "TRI KỶ", "ĐỒNG HÀNH"][clampi(tier, 1, 5) - 1])

static func localized(line: Dictionary) -> String:
	return words(line.get("en", ""), line.get("vi", line.get("en", "")))

static func dialogue_text(sequence: Array, zodiac_id: String) -> String:
	var lines: Array[String] = []
	for line: Dictionary in sequence:
		var text := localized(line)
		if line.get("speaker", "") == "direction": lines.append(text)
		else:
			var speaker := words("PLAYER", "BẠN") if line.get("speaker", "") == "player" else display_name(zodiac_id)
			lines.append(speaker + ": “" + text + "”")
	return "\n".join(lines)

static func sprite_path(id: String, overlay: bool = false) -> String:
	var stem := "mouse" if id == "rat" else id
	# Dragon only appears in the evening/endgame and has no daytime overlay.
	return "res://assets/zodiacboss/%s%s.png" % [stem, "_overlay" if overlay and id != "dragon" else ""]

static func difficulty_value(value: Variant) -> int:
	if value is int: return clampi(value, PLEASED, UNPLEASED)
	return {"PLEASED": PLEASED, "NORMAL": NORMAL, "NEUTRAL": NORMAL, "UNPLEASED": UNPLEASED}.get(String(value), UNPLEASED)

static func difficulty_name(level: int) -> String:
	return ["PLEASED", "NORMAL", "UNPLEASED"][clampi(level, 1, 3) - 1]

static func tuning(id: String, key: String, level: int = NORMAL) -> Variant:
	var value: Variant = TUNING.get(id, {}).get(key, 0)
	return value[clampi(level, 1, 3) - 1] if value is Array else value

static func skill_name(id: String, level: int = NORMAL) -> String:
	if id == "monkey": return "DANCE BABY!" if level == UNPLEASED else "FRESH!"
	return words({"rooster": "CLOSE THE REGISTER!", "cat": "THE STALK", "dog": "LOYAL TO THE END", "pig": "MAKE A FORTUNE", "ox": "BURDEN", "horse": "LIKE THE WIND", "goat": "ON THE BEAT", "rat": "FINDERS KEEPERS!", "tiger": "PREDATOR", "snake": "A SAINT'S TONGUE, A SERPENT'S HEART", "dragon": "PROVE IT."}.get(id, ""),
		{"rooster": "CHỐT SỔ!", "cat": "RÌNH MỒI", "dog": "MỘT LÒNG MỘT DẠ", "pig": "ĂN NÊN LÀM RA", "ox": "GÁNH NẶNG", "horse": "PHI NHƯ GIÓ", "goat": "ĐÚNG NHỊP, ĐÚNG PHÁCH", "rat": "CỦA RƠI, CỦA TÔI!", "tiger": "MÃNH THÚ", "snake": "KHẨU PHẬT TÂM XÀ", "dragon": "CHỨNG MINH ĐI."}.get(id, ""))

static func display_name(id: String) -> String:
	return words({"rooster": "ROOSTER", "cat": "CAT", "dog": "DOG", "monkey": "MONKEY", "pig": "PIG", "ox": "OX", "horse": "HORSE", "goat": "GOAT", "rat": "MOUSE", "tiger": "TIGER", "snake": "SNAKE", "dragon": "DRAGON"}.get(id, id.to_upper()),
		{"rooster": "DẬU", "cat": "MÃO", "dog": "TUẤT", "monkey": "THÂN", "pig": "HỢI", "ox": "SỬU", "horse": "NGỌ", "goat": "MÙI", "rat": "TÝ", "tiger": "DẦN", "snake": "TỴ", "dragon": "THÌN"}.get(id, id))

static func pair_for_day(day: int) -> Array:
	var index: int = DAY_PAIRS[posmod(day, DAY_PAIRS.size())]
	return PAIRS[index] if index >= 0 else []

static func select(seed_value: int, day: int, forced: String = "") -> String:
	var pair := pair_for_day(day)
	if pair.is_empty(): return ""
	if forced in pair and DEFINITIONS.has(forced): return forced
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var selected: String = pair[rng.randi_range(0, pair.size() - 1)]
	return selected if DEFINITIONS.has(selected) else ""

static func disposition(id: String, successes: int) -> String:
	var thresholds: Array = DEFINITIONS[id].thresholds
	return "PLEASED" if successes >= int(thresholds[1]) else "NORMAL" if successes >= int(thresholds[0]) else "UNPLEASED"

static func disposition_label(value: String) -> String:
	return words(difficulty_name(difficulty_value(value)), {"PLEASED": "HÀI LÒNG", "NORMAL": "BÌNH THƯỜNG", "NEUTRAL": "BÌNH THƯỜNG", "UNPLEASED": "KHÔNG HÀI LÒNG"}.get(value, value))

static func rule_text(id: String, severity: Variant) -> String:
	var level := difficulty_value(severity)
	if id == "rooster":
		return words("Phase 1: register closes after mandatory discard #%d. Closed Melds/Extensions stay legal but pay nothing.", "Hiệp 1: đóng sổ sau lần bỏ bài bắt buộc #%d. Vẫn được tạo/nối Phỏm nhưng không trả thưởng.") % int(tuning(id, "discard_deadline", level)) + " " + (words("Phase 2: Extensions only.", "Hiệp 2: chỉ nối Phỏm.") if level == UNPLEASED else words("Phase 2 scores normally.", "Hiệp 2 tính điểm bình thường."))
	if id == "cat":
		return words("Phase 2: %d cards locked after each refill. Locked cards cannot be played, discarded or targeted; they still count as deadwood.", "Hiệp 2: khóa %d lá sau mỗi lần bốc. Không thể đánh, bỏ hay chọn lá bị khóa; vẫn tính điểm bài rác.") % int(tuning(id, "lock_count", level)) + " " + (words("Phase 1: new Melds only.", "Hiệp 1: chỉ tạo Phỏm mới.") if level == UNPLEASED else words("Phase 1: watching.", "Hiệp 1: quan sát."))
	match id:
		"dog": return words("The first new Meld in each Phase is LOYAL and pays 100%%. Other Melds pay %d%%. Keep discarding to dig for Extensions.", "Phỏm mới đầu mỗi Hiệp là TRUNG THÀNH, trả 100%%. Phỏm khác trả %d%%. Có thể bỏ bài để tìm lá nối.") % int(tuning(id, "other_payout_percent", level)) + (words(" No further new Melds this Phase.", " Không được tạo thêm Phỏm mới trong Hiệp.") if level == UNPLEASED else "")
		"monkey": return words("Match the displayed three-action sequence. Correct inputs advance; misses stay legal, pay zero, and keep the turn.", "Theo chuỗi ba hành động hiện trên bàn. Đúng thì tiến; sai vẫn hợp lệ, không trả thưởng, lượt vẫn tiếp tục.") if level == UNPLEASED else words("Repeat a paid scoring action at most %d time(s). Change between Meld and Extend. Misses pay zero; your turn continues.", "Lặp hành động ghi điểm tối đa %d lần. Đổi giữa Tạo và Nối Phỏm. Sai nhịp trả 0, vẫn tiếp tục lượt.") % int(tuning(id, "allowed_repeats", level))
		"pig": return words("Siphons %d%% of earnings until the visible gross earnings target is met; then returns the whole pool.", "Giữ %d%% thu nhập tới khi đạt mục tiêu tổng thu hiển thị; sau đó hoàn lại cả quỹ.") % int(tuning(id, "siphon_percent", level)) + (words(" Failure costs %d%% of a positive bank.", " Thất bại mất %d%% số tiền dương trong ví.") % int(tuning(id, "bank_loss_percent", level)) if level == UNPLEASED else "")
		"ox": return words("Each carried loose card's deadwood loss doubles per completed turn. Removing it ends its burden.", "Mỗi lá rác giữ lại bị phạt gấp đôi sau mỗi lượt hoàn tất. Hạ, nối hoặc bỏ lá đó để hết gánh nặng.") + (words(" One grace turn per card.", " Mỗi lá được một lượt ân hạn.") if level == PLEASED else words(" Near-Meld loss: (value + %d) × burden × %d.", "Lá gần Phỏm: (giá trị + %d) × gánh nặng × %d.") % [int(tuning(id, "near_add_points", level)), int(tuning(id, "near_multiplier", level))] if level == UNPLEASED else "")
		"horse": return words("Complete two matching Meld or Extend actions each turn. An incomplete pair forces a random legal mandatory discard.", "Mỗi lượt hoàn thành hai lần Tạo hoặc hai lần Nối Phỏm. Chưa đủ cặp thì bị chọn ngẫu nhiên lá bỏ bắt buộc.") + (words(" One grace per Phase.", " Một lần ân hạn mỗi Hiệp.") if level == PLEASED else words(" Two turns per Phase.", " Hai lượt mỗi Hiệp.") if level == UNPLEASED else "")
		"goat": return words("The first paid action sets the starting Rank. Use ascending consecutive committed ranks, wrapping K to A. Old Meld cards do not set the note.", "Lần ghi điểm đầu đặt hạng mở đầu. Theo hạng liên tiếp tăng dần của lá vừa đánh, K quay về A. Không xét lá cũ trong Phỏm.") + (words(" One mistake grace per Phase.", " Một lần sai nhịp được tha mỗi Hiệp.") if level == PLEASED else words(" First committed Rank must match odd/even turn parity.", " Hạng đầu vừa đánh phải khớp chẵn/lẻ của lượt.") if level == UNPLEASED else "")
		"rat": return words("After each discard, Mouse tries a real Meld or Extension using discards and up to %d borrowed stock cards. Its payout is your loss; unused loans return and reshuffle.", "Sau mỗi lần bỏ, Tý thử Tạo/Nối Phỏm từ bài bỏ và tối đa %d lá mượn từ chồng bốc. Tiền thưởng thành tiền bạn mất; lá mượn thừa được trả và xáo lại.") % int(tuning(id, "borrow_limit", level)) + (words(" Previous-Phase discards are eligible.", " Có thể dùng bài bỏ của Hiệp trước.") if level == UNPLEASED else "")
		"tiger": return words("Immediately after refill, Tiger snatches one highest-Rank card.", "Ngay sau bốc, Dần vồ một lá hạng cao nhất.") if level == PLEASED else words("Immediately after refill, Tiger snatches all highest-Rank copies.", "Ngay sau bốc, Dần vồ tất cả lá cùng hạng cao nhất.") if level == NORMAL else words("Immediately snatches the most strategically valuable Rank and all copies. Exhaustion still recycles, but pays no bonus.", "Vồ ngay hạng có giá trị chiến thuật cao nhất cùng mọi bản sao. Cạn bài vẫn xáo lại nhưng không có thưởng.")
		"snake": return words("Issues up to %d explicit commands each turn. Discard commands move cards immediately. Disobedience sabotages a commanded card where possible. Your turn continues; mandatory discards are unchanged.", "Ra tối đa %d lệnh mỗi lượt. Lệnh bỏ bài chuyển lá ngay. Không tuân lệnh thì phá lá được chỉ định nếu có thể. Lượt vẫn tiếp tục; lần bỏ bắt buộc giữ nguyên.") % int(tuning(id, "command_count", level))
		"dragon": return words("Reproduce your most-used successful tactic and reach its historical earnings target. One rotating Zodiac modifier each turn. Victory: RỒNG RẮN LÊN MÂY.", "Tái hiện chiến thuật thành công dùng nhiều nhất và đạt mục tiêu thu nhập lịch sử. Mỗi lượt có một luật nhỏ Con Giáp luân phiên. Thắng: RỒNG RẮN LÊN MÂY.")

	return ""

static func action_label(action: String) -> String:
	return words({"new_meld": "MELD", "extension": "EXTEND", "discard": "DISCARD", "drink": "DRINK"}.get(action, action.to_upper()), {"new_meld": "TẠO PHỎM", "extension": "NỐI PHỎM", "discard": "BỎ BÀI", "drink": "DÙNG NƯỚC"}.get(action, action.to_upper()))

static func tactic_label(tactic: String) -> String:
	return action_label(tactic.get_slice(":", 0)) + " · " + words(tactic.get_slice(":", 1).to_upper(), "BỘ" if tactic.get_slice(":", 1) == "set" else "DÂY")

static func feedback(reason: String) -> String:
	reason = reason.trim_prefix("dragon_") if reason != "dragon_tactic_required" else reason
	var names := {"rooster_register_closed": words("REGISTER CLOSED", "ĐÃ ĐÓNG SỔ"), "dog_non_loyal": words("NOT THE LOYAL MELD", "KHÔNG PHẢI PHỎM TRUNG THÀNH"), "monkey_rhythm_miss": words("RHYTHM MISS", "SAI NHỊP"), "goat_rank_miss": words("RANK RHYTHM MISS", "SAI HẠNG NHỊP"), "tiger_exhaustion_bonus_disabled": words("EXHAUSTION BONUS SUPPRESSED", "KHÓA THƯỞNG CẠN BÀI"), "dragon_tactic_required": words("DRAGON REQUIRES YOUR TACTIC", "THÌN YÊU CẦU ĐÚNG CHIẾN THUẬT")}
	return names.get(reason, words("ZODIAC RULE", "LUẬT CON GIÁP"))

static func state_text(state: Dictionary, deal = null) -> String:
	var id: String = state.get("id", "")
	match id:
		"rooster":
			if deal != null and deal.current_phase == 2: return words("PHASE 2 · EXTENSIONS ONLY", "HIỆP 2 · CHỈ NỐI PHỎM") if int(state.difficulty) == UNPLEASED else words("PHASE 2 · NORMAL SCORING", "HIỆP 2 · TÍNH ĐIỂM THƯỜNG")
			return words("REGISTER CLOSED · 0 VNĐ", "ĐÃ ĐÓNG SỔ · 0 VNĐ") if state.register_closed else words("REGISTER OPEN", "ĐANG MỞ SỔ")
		"cat": return words("WATCHING", "ĐANG QUAN SÁT") if state.locked_ids.is_empty() else words("%d LOCKED · until next turn", "KHÓA %d LÁ · tới lượt kế") % state.locked_ids.size()
		"dog": return words("LOYAL: Meld #%d", "TRUNG THÀNH: Phỏm #%d") % int(state.loyal_meld_id) if int(state.loyal_meld_id) >= 0 else words("Create your LOYAL Meld", "Tạo Phỏm TRUNG THÀNH")
		"monkey":
			if not state.sequence.is_empty():
				var labels: Array[String] = []
				for i in state.sequence.size(): labels.append(("▶ " if i == int(state.sequence_index) else "") + action_label(state.sequence[i]))
				return " → ".join(labels)
			return words("Last paid: %s · chain %d", "Vừa trả thưởng: %s · chuỗi %d") % [action_label(state.last_paid_action) if not String(state.last_paid_action).is_empty() else "—", int(state.repeat_count)]
		"pig": return words("TARGET %s\nEarned %s · held %s", "MỤC TIÊU %s\nĐã thu %s · đang giữ %s") % [VndWallet.format_vnd(state.target_vnd), VndWallet.format_vnd(state.progress_vnd), VndWallet.format_vnd(state.pool_vnd)]
		"ox":
			var labels: Array[String] = []
			if deal != null:
				for card: CardData in deal.hand:
					var age := int(state.burden_age.get(card.unique_id, 0))
					if age > 0: labels.append("%s ×%d" % [card.short_label(), 1 << maxi(age - int(tuning("ox", "grace_turns", state.difficulty)), 0)])
			return words("CARD BURDEN\n", "GÁNH NẶNG TỪNG LÁ\n") + (", ".join(labels) if not labels.is_empty() else words("No carried burden yet", "Chưa mang gánh nặng"))
		"horse": return "%s %d/%d" % [action_label(state.required_action) if not String(state.required_action).is_empty() else words("MATCHING ACTIONS", "HÀNH ĐỘNG CÙNG LOẠI"), int(state.pair_count), int(tuning("horse", "matching_actions", state.difficulty))] + (words(" · %d grace", " · %d ân hạn") % int(state.pair_grace) if int(state.pair_grace) > 0 else "")
		"goat": return words("NEXT RANK: %s", "HẠNG TIẾP: %s") % (DeckManager.RANKS[int(state.expected_rank) - 1] if int(state.expected_rank) > 0 else words("choose the first note", "chọn hạng mở đầu")) + (words(" · turn %d (%s)", " · lượt %d (%s)") % [state.turn_number, words("ODD", "LẺ") if int(state.turn_number) % 2 else words("EVEN", "CHẴN")] if int(state.difficulty) == UNPLEASED else "")
		"rat": return words("Own Melds: %d\nLast deduction: %s", "Phỏm của Tý: %d\nVừa trừ: %s") % [deal.boss_melds.size() if deal != null else 0, VndWallet.format_vnd(int(state.get("hostile_result", {}).get("amount_vnd", 0)))]
		"tiger": return words("SNATCHED %d · act now", "ĐÃ VỒ %d LÁ · đến lượt bạn") % state.get("removed_ids", []).size()
		"snake":
			var lines: Array[String] = []
			for command: Dictionary in state.get("commands", []):
				var mark := "✓" if command.status == "fulfilled" else "×" if command.status == "violated" else "▶"
				var target: String = command.get("label", "")
				if command.has("drink_id"): target = DrinkCatalog.display_name(command.drink_id) + " · " + target
				if command.has("discard_label"): target += words(" → recover ", " → lấy lại ") + command.discard_label
				if command.has("meld_id"): target += " · #%d" % int(command.meld_id)
				lines.append("%s %s %s" % [mark, action_label(command.action), target])
			return "\n".join(lines) + words("\nYour turn continues.", "\nLượt của bạn vẫn tiếp tục.")
		"dragon": return words("You average %s using %s.\nTARGET %s · earned %s\nThis turn: %s", "Trung bình %s với %s.\nMỤC TIÊU %s · đã thu %s\nLượt này: %s") % [VndWallet.format_vnd(state.average_vnd), tactic_label(state.tactic), VndWallet.format_vnd(state.target_vnd), VndWallet.format_vnd(state.progress_vnd), display_name(state.modifier_id) if not String(state.modifier_id).is_empty() else "—"]
	return ""

static func modifier_text(state: Dictionary, _deal = null) -> String:
	var mini: Dictionary = state.get("modifier", {})
	match String(state.get("modifier_id", "")):
		"rooster": return words("Paid actions: %d/%d", "Lần trả thưởng: %d/%d") % [mini.get("actions", 0), int(tuning("rooster", "dragon_paid_actions", state.difficulty))]
		"cat": return words("Locked: %d", "Khóa: %d") % state.locked_ids.size()
		"dog": return words("Loyal Meld: #%d", "Phỏm trung thành: #%d") % int(mini.get("loyal_meld_id", -1))
		"monkey": return words("Required: ", "Yêu cầu: ") + action_label(mini.get("required_action", ""))
		"pig": return words("Siphoned this turn: ", "Đã giữ lượt này: ") + VndWallet.format_vnd(int(mini.get("siphoned_vnd", 0)))
		"ox": return words("Deadwood ×%d", "Phạt bài rác ×%d") % int(mini.get("burden_multiplier", 1))
		"horse": return "%s %d/%d" % [action_label(mini.get("required_action", "")), int(mini.get("pair_count", 0)), int(tuning("horse", "matching_actions", state.difficulty))]
		"goat": return words("Required Rank: %s", "Yêu cầu hạng: %s") % (DeckManager.RANKS[int(mini.expected_rank) - 1] if int(mini.get("expected_rank", 0)) > 0 else "—")
		"rat": return words("Mouse may reuse this turn's discard.", "Tý có thể lấy bài bỏ của lượt này.")
		"tiger": return words("Snatched %d cards", "Đã vồ %d lá") % mini.get("removed_ids", []).size()
		"snake": return state_text({"id": "snake", "commands": mini.get("commands", [])})
	return ""
