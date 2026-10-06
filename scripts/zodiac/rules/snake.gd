extends "res://scripts/zodiac/zodiac_mechanic.gd"
const Tactics := preload("res://scripts/zodiac/zodiac_tactics.gd")
const PLAYER_ACTIONS := ["new_meld", "extension", "discard", "nhan_tran_swap", "den_da_swap", "nau_da_return", "nuoc_voi_return", "sam_dua_selected"]

func configure(rule) -> void:
	rule.data["commands"] = []

func begin_phase(rule, _deal) -> void:
	rule.data.commands = []

func _command(action: String, card: CardData, extras: Dictionary = {}) -> Dictionary:
	var result := {"action": action, "card_id": card.unique_id if card != null else "", "label": card.short_label() if card != null else "", "status": "pending"}
	result.merge(extras)
	return result

func _play_command(deal, reserved: Dictionary) -> Dictionary:
	var best := {}
	var lowest := 9223372036854775807
	for cards: Array[CardData] in Tactics.meld_candidates(deal.hand):
		if cards.any(func(card: CardData): return reserved.has(card.unique_id)) or not deal.can_create_meld(cards): continue
		var score: int = deal.scoring.preview_new_meld(cards, MeldRules.classify(cards), deal.current_phase).final_points
		if score < lowest:
			lowest = score
			best = _command("new_meld", cards[0], {"suggested_ids": cards.map(func(card: CardData): return card.unique_id)})
	for card: CardData in deal.hand:
		if reserved.has(card.unique_id): continue
		var additions: Array[CardData] = [card]
		for meld: MeldState in deal.melds:
			if not deal.can_extend_meld(meld.meld_id, additions): continue
			var combined: Array[CardData] = meld.cards.duplicate()
			combined.append(card)
			var score: int = deal.scoring.preview_extension(combined, meld.meld_type, ScoringPipeline.meld_value(meld.cards), deal.current_phase, additions).final_points
			if score < lowest:
				lowest = score
				best = _command("extension", card, {"meld_id": meld.meld_id})
	return best

func _drink_command(deal) -> Dictionary:
	if not deal.current_drink_has_charge(): return {}
	var drink: String = deal.current_drink_id
	if drink in [DrinkCatalog.NHAN_TRAN, DrinkCatalog.DEN_DA]:
		var records: Array[DiscardRecord] = deal.live_discard_records()
		records.sort_custom(func(a: DiscardRecord, b: DiscardRecord): return a.card.score_value() < b.card.score_value())
		for card in Tactics.valuable_cards(deal):
			for record in records:
				var valid: bool = deal.can_use_nhan_tran(card, record) if drink == DrinkCatalog.NHAN_TRAN else deal.can_use_den_da(card, record)
				if valid: return _command("drink", card, {"drink_id": drink, "action_name": "nhan_tran_swap" if drink == DrinkCatalog.NHAN_TRAN else "den_da_swap", "discard_card_id": record.card.unique_id, "discard_label": record.card.short_label()})
	if drink == DrinkCatalog.NAU_DA:
		var ordered: Array[MeldState] = deal.melds.duplicate()
		ordered.sort_custom(func(a: MeldState, b: MeldState): return ScoringPipeline.meld_value(a.cards) < ScoringPipeline.meld_value(b.cards))
		for meld in ordered:
			if deal.can_use_nau_da(meld.meld_id): return _command("drink", meld.cards[0], {"drink_id": drink, "action_name": "nau_da_return", "meld_id": meld.meld_id})
	if drink == DrinkCatalog.NUOC_VOI:
		var targets: Array[Dictionary] = deal.nuoc_voi_targets()
		targets.sort_custom(func(a: Dictionary, b: Dictionary): return a.card.score_value() < b.card.score_value())
		if not targets.is_empty(): return _command("drink", targets[0].card, {"drink_id": drink, "action_name": "nuoc_voi_return", "meld_id": targets[0].meld_id})
	if drink in [DrinkCatalog.STING, DrinkCatalog.BO_HUC, DrinkCatalog.C2_ICED_TEA]:
		for cards: Array[CardData] in deal.queries.hand_combinations():
			if deal.can_create_meld(cards, true): return _command("new_meld", cards[0], {"drink_id": drink, "use_drink": true, "suggested_ids": cards.map(func(card: CardData): return card.unique_id)})
	return {}

func _generate(rule, deal, count: int) -> Array:
	var commands := []
	var reserved := {}
	for i in count:
		var command := {}
		if rule.difficulty == ZodiacCatalog.UNPLEASED and i == 0: command = _drink_command(deal)
		if command.is_empty() and rule.difficulty >= ZodiacCatalog.NORMAL and i % 2 == 1: command = _play_command(deal, reserved)
		if command.is_empty():
			for card in Tactics.valuable_cards(deal):
				if rule.is_locked(card) or reserved.has(card.unique_id) or deal.hand.size() <= 1: continue
				command = _command("discard", card)
				if deal.boss_discard_card(card, "snake").get("ok", false): command.status = "fulfilled"
				break
		if command.is_empty(): break
		commands.append(command)
		reserved[command.card_id] = true
		for card_id: String in command.get("suggested_ids", []): reserved[card_id] = true
	return commands

func begin_turn(rule, _phase: int, _hand: Array[CardData], deal) -> void:
	if deal != null: rule.data.commands = _generate(rule, deal, int(ZodiacCatalog.tuning("snake", "command_count", rule.difficulty)))

func _matches(command: Dictionary, result: Dictionary) -> bool:
	var action: String = result.get("action", "")
	if command.action == "drink":
		if action != command.action_name: return false
		if command.has("meld_id") and int(result.get("meld_id", -1)) != int(command.meld_id): return false
		var card: CardData = result.get("card", result.get("discarded"))
		if action in ["nuoc_voi_return", "nhan_tran_swap", "den_da_swap"] and (card == null or card.unique_id != command.card_id): return false
		if command.has("discard_card_id"):
			var recovered: CardData = result.get("recovered")
			if recovered == null or recovered.unique_id != command.discard_card_id: return false
		return true
	if action != command.action: return false
	if command.has("meld_id") and int(result.get("meld_id", -1)) != int(command.meld_id): return false
	if command.get("use_drink", false) and not result.get("used_drink", false): return false
	var context: ScoringContext = result.get("context")
	if context == null:
		var card: CardData = result.get("card")
		return card != null and card.unique_id == command.card_id
	var committed: Array[CardData] = context.added_cards if action == "extension" else context.cards
	return committed.any(func(card: CardData): return card.unique_id == command.card_id)

func _observe(rule, deal, result: Dictionary, commands: Array) -> void:
	if result.get("action", "") not in PLAYER_ACTIONS: return
	for command: Dictionary in commands:
		if command.status != "pending": continue
		if _matches(command, result):
			command.status = "fulfilled"
			rule.events.append({"action": "snake_obeyed", "command": command.duplicate(true)})
		else:
			command.status = "violated"
			var sabotage: Dictionary = deal.boss_discard_target(command.card_id, "snake")
			rule.events.append({"action": "snake_disobeyed", "command": command.duplicate(true), "sabotage": sabotage, "turn_continues": true})
		break

func after_action(rule, deal, result: Dictionary) -> void:
	_observe(rule, deal, result, rule.data.commands)

func dragon_begin(rule, deal, state: Dictionary) -> void:
	state["commands"] = _generate(rule, deal, int(ZodiacCatalog.tuning("snake", "dragon_command_count", rule.difficulty)))

func dragon_after(rule, deal, result: Dictionary, state: Dictionary) -> void:
	_observe(rule, deal, result, state.commands)
