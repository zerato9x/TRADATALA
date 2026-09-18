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


func score_new_meld(cards: Array[CardData], meld_type: String, phase: int, phase_new_phom_count: int = 0, is_last_call: bool = false) -> ScoringContext:
	var context := preview_new_meld(cards, meld_type, phase, phase_new_phom_count, is_last_call)
	_emit_scoring_passes(context)
	new_phom_scored.emit(context)
	return context


func preview_new_meld(cards: Array[CardData], meld_type: String, phase: int, phase_new_phom_count: int = 0, is_last_call: bool = false) -> ScoringContext:
	var context := _build_context(cards, meld_type, phase)
	context.action_type = "new_meld"
	context.is_last_call = is_last_call
	_apply_gold(context)
	_apply_modifiers(context)
	context.theoretical_score = _calculate_theoretical(context)
	_resolve_full_meld_trigger(context)
	return context


func score_extension(
	all_cards: Array[CardData],
	meld_type: String,
	old_meld_score: int,
	phase: int,
	added_cards: Array[CardData] = [],
	is_last_call: bool = false
) -> ScoringContext:
	var context := preview_extension(all_cards, meld_type, old_meld_score, phase, added_cards, is_last_call)
	_emit_scoring_passes(context)
	extension_scored.emit(context)
	return context


func preview_extension(
	all_cards: Array[CardData],
	meld_type: String,
	old_meld_score: int,
	phase: int,
	added_cards: Array[CardData] = [],
	is_last_call: bool = false
) -> ScoringContext:
	var context := _build_context(all_cards, meld_type, phase)
	context.action_type = "extension"
	context.old_meld_score = old_meld_score
	context.added_cards.append_array(added_cards)
	context.is_last_call = is_last_call
	_apply_gold(context)
	_apply_modifiers(context)
	context.theoretical_score = _calculate_theoretical(context)
	context.base_extension_score = maxi(context.theoretical_score - old_meld_score, 0)
	_resolve_extension_passes(context)
	return context


func score_meld_trigger(cards: Array[CardData], meld_type: String, phase: int) -> ScoringContext:
	var context := _build_context(cards, meld_type, phase)
	context.action_type = ACTION_EXHAUSTION_MELD
	_apply_gold(context)
	_apply_modifiers(context)
	context.theoretical_score = _calculate_theoretical(context)
	_resolve_full_meld_trigger(context)
	_emit_scoring_passes(context)
	return context


static func is_set_milestone(meld_type: String, card_count: int) -> bool:
	# SET retriggers happen at every exact four-card milestone: 4, 8, 12, ...
	return meld_type == MeldRules.TYPE_SET and card_count >= 4 and card_count % 4 == 0


static func is_perfected_run(cards: Array[CardData], meld_type: String) -> bool:
	# DealState validates the meld's suit compatibility; legal drink Runs can mix suits.
	if meld_type != MeldRules.TYPE_RUN or cards.size() != 13 or not MeldRules.is_compatible_run(cards, "any"):
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


func _resolve_extension_passes(context: ScoringContext) -> void:
	# Every extension originates as the intrinsic increase. A native Ph?m
	# milestone may then append one complete-meld replay, followed by any
	# finite Gieo full-meld retriggers.
	var native_retrigger_count := 0
	var native_reason := ""
	if is_set_milestone(context.meld_type, context.cards.size()):
		native_retrigger_count = 1
		native_reason = TRIGGER_SET_MILESTONE
	elif is_perfected_run(context.cards, context.meld_type):
		native_retrigger_count = 1
		native_reason = TRIGGER_PERFECTED_RUN
	var gieo_retriggers := _gieo_full_meld_retrigger_count(context)
	context.retrigger_count = native_retrigger_count + gieo_retriggers
	context.trigger_reason = TRIGGER_GIEO_RETRIGGER if gieo_retriggers > 0 else native_reason
	context.final_points = context.base_extension_score + context.theoretical_score * context.retrigger_count
	context.scoring_passes.clear()
	context.scoring_passes.append(_make_scoring_pass(context, 0, TRIGGER_ORIGINATING, context.base_extension_score))
	for pass_index in range(native_retrigger_count):
		context.scoring_passes.append(_make_scoring_pass(
			context,
			pass_index + 1,
			TRIGGER_NATIVE_RETRIGGER,
			context.theoretical_score
		))
	for pass_index in range(gieo_retriggers):
		var trigger_index := native_retrigger_count + pass_index + 1
		context.scoring_passes.append(_make_scoring_pass(
			context,
			trigger_index,
			TRIGGER_GIEO_RETRIGGER,
			context.theoretical_score
		))

	_sum_pass_points(context)


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

	_sum_pass_points(context)


func _make_scoring_pass(context: ScoringContext, pass_index: int, origin: String, points: int) -> ScoringContext:
	var scoring_pass := _copy_context(context)
	scoring_pass.trigger_index = pass_index
	scoring_pass.trigger_origin = origin
	scoring_pass.retrigger_count = 0
	scoring_pass.final_points = points
	if origin == TRIGGER_GIEO_RETRIGGER:
		var property_id := GieoQueService.PROPERTY_MELD_RETRIGGER
		var source_index := 0
		for previous: ScoringContext in context.scoring_passes:
			if previous.trigger_origin == TRIGGER_GIEO_RETRIGGER:
				source_index += 1
		for card in context.cards:
			if card.has_gieo_property(property_id):
				if source_index == 0:
					scoring_pass.retrigger_source_id = card.unique_id
					scoring_pass.retrigger_property = property_id
					break
				source_index -= 1
	_apply_polish(scoring_pass)
	_build_presentation_hits(scoring_pass)
	return scoring_pass


func _polish_contribution(context: ScoringContext, card: CardData) -> int:
	var multiplier := context.local_mult
	if context.action_type == "extension" and context.trigger_index == 0 and not context.added_cards.has(card):
		multiplier -= context.cards.size() - context.added_cards.size()
	return card.score_value() * (multiplier + context.local_mult * context.qualifying_gold(card).size())


func _apply_polish(context: ScoringContext) -> void:
	# One bounded self-contribution per physical card per pass; never a meld pass.
	for card in context.cards:
		if card.shiny:
			context.final_points += _polish_contribution(context, card)


func _sum_pass_points(context: ScoringContext) -> void:
	context.final_points = 0
	for scoring_pass: ScoringContext in context.scoring_passes:
		context.final_points += scoring_pass.final_points


func _build_presentation_hits(context: ScoringContext) -> void:
	# Every extension starts with its delta. A later native/Gieo pass shows the
	# complete meld revaluation explicitly, rather than inventing card payouts.
	var delta_pass := context.action_type == "extension" and context.trigger_index == 0
	var shown_cards: Array[CardData] = context.added_cards if delta_pass else context.cards
	var accounted := 0
	for card in shown_cards:
		var points := card.score_value() * context.local_mult
		context.presentation_hits.append(_card_hit(card, points, ""))
		accounted += points
		for property_id in context.qualifying_gold(card):
			context.presentation_hits.append(_card_hit(card, points, property_id))
			accounted += points
	if delta_pass:
		# Composition Gold on older cards still contributes to this event's sum.
		# Show its actual card trigger, leaving intrinsic growth in meld_delta.
		for card in context.cards:
			if context.added_cards.has(card):
				continue
			for property_id in context.qualifying_gold(card):
				var points := card.score_value() * context.local_mult
				context.presentation_hits.append(_card_hit(card, points, property_id))
				accounted += points
	for card in context.cards:
		if card.shiny:
			var bonus := _polish_contribution(context, card)
			context.presentation_hits.append(_card_hit(card, bonus, "SHINY"))
			accounted += bonus
	var adjustment := context.final_points - accounted
	if adjustment != 0:
		context.presentation_hits.append({
			"card_id": "", "label": "", "texture_path": "", "properties": [],
			"property": "", "kind": "meld_delta" if delta_pass else "modifier",
			"points": adjustment,
		})


func _card_hit(card: CardData, points: int, property_id: String) -> Dictionary:
	return {
		"card_id": card.unique_id, "label": card.short_label(),
		"texture_path": card.texture_path(), "properties": card.gieo_properties.duplicate(), "shiny": card.shiny,
		"property": property_id, "kind": "card" if property_id.is_empty() else "card_retrigger",
		"points": points,
	}


func _apply_gold(context: ScoringContext) -> void:
	# Each condition contributes the current physical-card value once, before count.
	for card in context.cards:
		context.card_value_sum += card.score_value() * context.qualifying_gold(card).size()
	context.base_score = context.card_value_sum


func _gieo_full_meld_retrigger_count(context: ScoringContext) -> int:
	var count := 0
	for card in context.cards:
		if card.has_gieo_property(GieoQueService.PROPERTY_MELD_RETRIGGER):
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
	copy.is_last_call = source.is_last_call
	copy.trigger_reason = source.trigger_reason
	return copy


func _emit_scoring_passes(context: ScoringContext) -> void:
	for scoring_pass: ScoringContext in context.scoring_passes:
		context_scored.emit(scoring_pass)
