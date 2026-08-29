class_name ScoringPipeline
extends RefCounted

signal context_scored(context: ScoringContext)
signal new_phom_scored(context: ScoringContext)
signal extension_scored(context: ScoringContext)

var _modifiers: Array[Callable] = []


func add_modifier(modifier: Callable) -> void:
	if modifier.is_valid() and not _modifiers.has(modifier):
		_modifiers.append(modifier)


func remove_modifier(modifier: Callable) -> void:
	_modifiers.erase(modifier)


func score_new_meld(cards: Array[CardData], meld_type: String, phase: int, phase_new_phom_count: int = 0) -> ScoringContext:
	var context := preview_new_meld(cards, meld_type, phase, phase_new_phom_count)
	context_scored.emit(context)
	new_phom_scored.emit(context)
	return context


func preview_new_meld(cards: Array[CardData], meld_type: String, phase: int, phase_new_phom_count: int = 0) -> ScoringContext:
	var context := _build_context(cards, meld_type, phase)
	context.action_type = "new_meld"
	_apply_modifiers(context)
	context.theoretical_score = _calculate_theoretical(context)
	context.final_points = context.theoretical_score
	return context


func score_extension(
	all_cards: Array[CardData],
	meld_type: String,
	old_meld_score: int,
	phase: int,
	added_cards: Array[CardData] = []
) -> ScoringContext:
	var context := preview_extension(all_cards, meld_type, old_meld_score, phase, added_cards)
	context_scored.emit(context)
	extension_scored.emit(context)
	return context


func preview_extension(
	all_cards: Array[CardData],
	meld_type: String,
	old_meld_score: int,
	phase: int,
	added_cards: Array[CardData] = []
) -> ScoringContext:
	var context := _build_context(all_cards, meld_type, phase)
	context.action_type = "extension"
	context.old_meld_score = old_meld_score
	context.added_cards.append_array(added_cards)
	_apply_modifiers(context)
	context.theoretical_score = _calculate_theoretical(context)
	context.base_extension_score = maxi(context.theoretical_score - old_meld_score, 0)
	context.final_points = context.base_extension_score
	return context


static func deadwood_points(cards: Array[CardData]) -> int:
	var value_sum := 0
	for card in cards:
		value_sum += card.score_value()
	return value_sum


static func meld_value(cards: Array[CardData]) -> int:
	var value_sum := 0
	for card in cards:
		value_sum += card.score_value()
	return value_sum * cards.size()


func _build_context(cards: Array[CardData], meld_type: String, phase: int) -> ScoringContext:
	var context := ScoringContext.new()
	context.cards.append_array(cards)
	context.meld_type = meld_type
	context.phase = phase
	for card in cards:
		context.card_value_sum += card.score_value()
	context.base_score = context.card_value_sum
	context.local_mult = cards.size()
	return context


func _apply_modifiers(context: ScoringContext) -> void:
	for modifier in _modifiers:
		if modifier.is_valid():
			modifier.call(context)


func _calculate_theoretical(context: ScoringContext) -> int:
	return maxi(context.base_score * context.local_mult + context.flat_adjustment_points, 0)

