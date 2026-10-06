extends "res://scripts/zodiac/zodiac_mechanic.gd"

func configure(rule) -> void:
	rule.data.merge({"expected_rank": int(ZodiacCatalog.tuning("goat", "initial_rank", rule.difficulty)), "rhythm_grace": 0, "turn_number": 1})

func begin_phase(rule, _deal) -> void:
	rule.data.expected_rank = int(ZodiacCatalog.tuning("goat", "initial_rank", rule.difficulty))
	rule.data.rhythm_grace = int(ZodiacCatalog.tuning("goat", "mistake_grace", rule.difficulty))
	rule.data.turn_number = 1

func begin_turn(rule, _phase: int, _hand: Array[CardData], deal) -> void:
	if deal != null: rule.data.turn_number = deal.discard_count + 1

# A Set supplies one rank. A Run supplies the ascending committed ranks only.
# First paid action establishes the starting note; later notes must be consecutive.
func _grade(rule, context: ScoringContext, state: Dictionary, commit: bool) -> Dictionary:
	var committed: Array[CardData] = context.added_cards if context.action_type == "extension" else context.cards
	var ranks: Array[int] = []
	for card in committed:
		if not ranks.has(card.rank_index): ranks.append(card.rank_index)
	ranks.sort()
	if ranks.is_empty(): return {}
	var expected := int(state.get("expected_rank", 0))
	var correct := expected == 0 or ranks[0] == expected
	for i in range(1, ranks.size()):
		correct = correct and ranks[i] == ranks[i - 1] + 1
	if rule.difficulty == ZodiacCatalog.UNPLEASED and state.get("parity_required", true):
		correct = correct and ranks[0] % 2 == int(state.turn_number) % 2
	var grace := not correct and int(state.get("rhythm_grace", 0)) > 0
	if commit and (correct or grace) and context.final_points > 0:
		if grace: state.rhythm_grace -= 1
		state.expected_rank = ranks[-1] % 13 + 1
	return {} if correct or grace else {"percent": 0, "reason": "goat_rank_miss"}

func payout(rule, context: ScoringContext, _meld_id: int, commit: bool) -> Dictionary:
	if context.action_type not in ["new_meld", "extension"]: return {}
	return _grade(rule, context, rule.data, commit)

func dragon_begin(rule, deal, state: Dictionary) -> void:
	# Pick a note from a legal play of Dragon's required tactic. The curated
	# version relaxes parity if parity would exclude every available tactic.
	var tactic: Dictionary = rule.data.analysis
	var notes: Array[int] = []
	var parity_notes: Array[int] = []
	var turn: int = deal.discard_count + 1
	for cards: Array[CardData] in deal.queries.hand_combinations():
		var legal: bool = false
		if tactic.action == "new_meld":
			legal = deal.can_create_meld(cards) and deal.meld_creation_rule(cards).type == tactic.meld_type
		else:
			for meld: MeldState in deal.melds:
				if meld.meld_type == tactic.meld_type and deal.can_extend_meld(meld.meld_id, cards): legal = true; break
		if not legal: continue
		var first: int = cards.map(func(card: CardData): return card.rank_index).min()
		if not notes.has(first): notes.append(first)
		if first % 2 == turn % 2 and not parity_notes.has(first): parity_notes.append(first)
	state["parity_required"] = rule.difficulty == ZodiacCatalog.UNPLEASED and not parity_notes.is_empty()
	if state.parity_required: notes = parity_notes
	state["expected_rank"] = notes[rule.rng.randi_range(0, notes.size() - 1)] if not notes.is_empty() else 0
	state["turn_number"] = turn
	state["rhythm_grace"] = int(ZodiacCatalog.tuning("goat", "mistake_grace", rule.difficulty))

func dragon_payout(rule, context: ScoringContext, _meld_id: int, state: Dictionary, commit: bool) -> Dictionary:
	return _grade(rule, context, state, commit)
