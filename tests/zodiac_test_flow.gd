extends RefCounted
## Test-only progression through both the authored and legacy engines.
static func finish_noon(service: ZodiacService) -> bool:
	for _step in 32:
		if not service.has_open_interaction(): return true
		if service.has_open_question():
			var answers: Array = service.persuasion.state().node.answers.duplicate()
			answers.sort_custom(func(a: Dictionary, b: Dictionary): return int(a.delta) > int(b.delta))
			if not service.answer_question(answers[0].id).get("ok", false): return false
		elif service.uses_persuasion() and service.persuasion.state().get("stage", "") == "reaction":
			if not service.continue_conversation(): return false
		elif not service.respond("REFUSE").get("ok", false): return false
	return false
