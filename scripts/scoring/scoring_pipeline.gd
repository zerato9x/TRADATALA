class_name ScoringPipeline
extends RefCounted

signal context_scored(context: ScoringContext)
signal new_phom_scored(context: ScoringContext)
signal extension_scored(context: ScoringContext)

const ACTION_EXHAUSTION_MELD := "exhaustion_meld"
const TRIGGER_ORIGINATING := "originating"
const TRIGGER_NATIVE_RETRIGGER := "native_retrigger"
const TRIGGER_SET_MILESTONE := "set_milestone"
const TRIGGER_PERFECTED_RUN := "perfected_run"
const TRIGGER_GIEO_RETRIGGER := "gieo_retrigger"
const NATIVE_RETRIGGER_TOTAL_PASSES := 2

var _modifiers: Array[Callable] = []


func add_modifier(modifier: Callable) -> void:
	if modifier.is_valid() and not _modifiers.has(modifier):
		_modifiers.append(modifier)


func remove_modifier(modifier: Callable) -> void:
	_modifiers.erase(modifier)


func score_new_meld(cards: Array[CardData], meld_type: String, phase: int, phase_new_phom_count: int = 0) -> ScoringContext:
	var context := preview_new_meld(cards, meld_type, phase, phase_new_phom_count)
	_emit_scoring_passes(context)
	new_phom_scored.emit(context)
	return context


func preview_new_meld(cards: Array[CardData], meld_type: String, phase: int, phase_new_phom_count: int = 0) -> ScoringContext:
	var context := _build_context(cards, meld_type, phase)
	context.action_type = "new_meld"
	_apply_making_phom_retrigger(context)
	_apply_modifiers(context)
	context.theoretical_score = _calculate_theoretical(context)
	_resolve_full_meld_trigger(context)
	return context


func score_extension(
	all_cards: Array[CardData],
	meld_type: String,
	old_meld_score: int,
	phase: int,
	added_cards: Array[CardData] = []
) -> ScoringContext:
	var context := preview_extension(all_cards, meld_type, old_meld_score, phase, added_cards)
	_emit_scoring_passes(context)
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
	_apply_extend_retrigger(context)
	_apply_modifiers(context)
	context.theoretical_score = _calculate_theoretical(context)
	context.base_extension_score = maxi(context.theoretical_score - old_meld_score, 0)
	if is_set_milestone(meld_type, all_cards.size()):
		_resolve_full_meld_trigger(context)
	else:
		_resolve_origin_and_gieo_retriggers(context, context.base_extension_score)
	return context


func score_meld_trigger(cards: Array[CardData], meld_type: String, phase: int) -> ScoringContext:
	var context := _build_context(cards, meld_type, phase)
	context.action_type = ACTION_EXHAUSTION_MELD
	_apply_modifiers(context)
	context.theoretical_score = _calculate_theoretical(context)
	_resolve_full_meld_trigger(context)
	_emit_scoring_passes(context)
	return context


static func is_set_milestone(meld_type: String, card_count: int) -> bool:
	return meld_type == MeldRules.TYPE_SET and card_count >= 4 and card_count % 4 == 0


static func is_perfected_run(cards: Array[CardData], meld_type: String) -> bool:
	if meld_type != MeldRules.TYPE_RUN or cards.size() != 13 or not MeldRules.is_run(cards):
		return false
	var ranks: Array[int] = []
	for card in cards:
		ranks.append(card.rank_index)
	ranks.sort()
	return ranks[0] == 1 and ranks[-1] == 13


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


func _resolve_full_meld_trigger(context: ScoringContext) -> void:
	var total_passes := 1
	var reason := ""
	if is_set_milestone(context.meld_type, context.cards.size()):
		total_passes = NATIVE_RETRIGGER_TOTAL_PASSES
		reason = TRIGGER_SET_MILESTONE
	elif is_perfected_run(context.cards, context.meld_type):
		total_passes = NATIVE_RETRIGGER_TOTAL_PASSES
		reason = TRIGGER_PERFECTED_RUN
	var gieo_retriggers := _gieo_full_meld_retrigger_count(context)
	_resolve_passes(context, context.theoretical_score, total_passes + gieo_retriggers, reason, total_passes)


func _resolve_single_pass(context: ScoringContext, points: int) -> void:
	_resolve_passes(context, points, 1, "")


func _resolve_origin_and_gieo_retriggers(context: ScoringContext, originating_points: int) -> void:
	var gieo_retriggers := _gieo_full_meld_retrigger_count(context)
	context.retrigger_count = gieo_retriggers
	context.trigger_reason = TRIGGER_GIEO_RETRIGGER if gieo_retriggers > 0 else ""
	context.final_points = originating_points + context.theoretical_score * gieo_retriggers
	context.scoring_passes.clear()
	context.scoring_passes.append(_make_scoring_pass(context, 0, TRIGGER_ORIGINATING, originating_points))
	for pass_index in range(gieo_retriggers):
		context.scoring_passes.append(_make_scoring_pass(
			context,
			pass_index + 1,
			TRIGGER_GIEO_RETRIGGER,
			context.theoretical_score
		))


func _resolve_passes(
	context: ScoringContext,
	points_per_pass: int,
	total_passes: int,
	reason: String,
	native_passes: int = 1
) -> void:
	context.retrigger_count = maxi(total_passes - 1, 0)
	context.trigger_reason = TRIGGER_GIEO_RETRIGGER if total_passes > native_passes else reason
	context.final_points = points_per_pass * total_passes
	context.scoring_passes.clear()
	for pass_index in range(total_passes):
		var origin := TRIGGER_ORIGINATING
		if pass_index > 0:
			origin = TRIGGER_NATIVE_RETRIGGER if pass_index < native_passes else TRIGGER_GIEO_RETRIGGER
		context.scoring_passes.append(_make_scoring_pass(context, pass_index, origin, points_per_pass))


func _make_scoring_pass(context: ScoringContext, pass_index: int, origin: String, points: int) -> ScoringContext:
	var scoring_pass := _copy_context(context)
	scoring_pass.trigger_index = pass_index
	scoring_pass.trigger_origin = origin
	scoring_pass.retrigger_count = 0
	scoring_pass.final_points = points
	return scoring_pass


func _apply_making_phom_retrigger(context: ScoringContext) -> void:
	for card in context.cards:
		if card.has_gieo_property(GieoQueService.PROPERTY_MAKING_PHOM_RETRIGGER):
			context.card_value_sum += card.score_value()
	context.base_score = context.card_value_sum


func _apply_extend_retrigger(context: ScoringContext) -> void:
	for card in context.added_cards:
		if card.has_gieo_property(GieoQueService.PROPERTY_EXTEND_RETRIGGER):
			context.card_value_sum += card.score_value()
	context.base_score = context.card_value_sum


func _gieo_full_meld_retrigger_count(context: ScoringContext) -> int:
	var property_id := ""
	if context.meld_type == MeldRules.TYPE_SET:
		property_id = GieoQueService.PROPERTY_SET_RETRIGGER
	elif context.meld_type == MeldRules.TYPE_RUN:
		property_id = GieoQueService.PROPERTY_RUN_RETRIGGER
	if property_id.is_empty():
		return 0
	var count := 0
	for card in context.cards:
		if card.has_gieo_property(property_id):
			count += 1
	return count


func _copy_context(source: ScoringContext) -> ScoringContext:
	var copy := ScoringContext.new()
	copy.action_type = source.action_type
	copy.meld_type = source.meld_type
	copy.cards.append_array(source.cards)
	copy.added_cards.append_array(source.added_cards)
	copy.old_meld_score = source.old_meld_score
	copy.card_value_sum = source.card_value_sum
	copy.base_score = source.base_score
	copy.local_mult = source.local_mult
	copy.flat_adjustment_points = source.flat_adjustment_points
	copy.base_extension_score = source.base_extension_score
	copy.theoretical_score = source.theoretical_score
	copy.phase = source.phase
	copy.trigger_reason = source.trigger_reason
	return copy


func _emit_scoring_passes(context: ScoringContext) -> void:
	for scoring_pass: ScoringContext in context.scoring_passes:
		context_scored.emit(scoring_pass)
