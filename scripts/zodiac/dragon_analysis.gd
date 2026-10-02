extends RefCounted
## Additive action telemetry, classified by repeatable action + Meld type.
static func tactic_key(event: Dictionary) -> String:
	var action: String = event.get("action", "")
	var type: String = event.get("meld_type", "")
	if action not in ["new_meld", "extension"] or type not in [MeldRules.TYPE_SET, MeldRules.TYPE_RUN]: return ""
	return action + ":" + type

static func analyze(events: Array, difficulty: int) -> Dictionary:
	var groups := {}
	for event: Dictionary in events:
		var key := tactic_key(event)
		# Legacy rows without actual payout are retained, but cannot invent averages.
		var earned := int(event.get("earned_vnd", 0))
		if key.is_empty() or earned <= 0 or int(event.get("points", 0)) <= 0: continue
		if not groups.has(key): groups[key] = {"count": 0, "total_vnd": 0}
		groups[key].count += 1
		groups[key].total_vnd += earned
	var keys: Array = groups.keys()
	keys.sort_custom(func(a: String, b: String): return groups[a].count > groups[b].count if groups[a].count != groups[b].count else groups[a].total_vnd > groups[b].total_vnd if groups[a].total_vnd != groups[b].total_vnd else a < b)
	var chosen: String = keys[0] if not keys.is_empty() else "new_meld:set"
	var average := int(int(groups[chosen].total_vnd) / float(groups[chosen].count)) if groups.has(chosen) else 0
	var basis := average if average > 0 else int(ZodiacCatalog.tuning("dragon", "no_history_target_vnd", difficulty))
	var target := maxi(1, int(basis * int(ZodiacCatalog.tuning("dragon", "target_percent", difficulty)) / 100.0))
	return {"tactic": chosen, "action": chosen.get_slice(":", 0), "meld_type": chosen.get_slice(":", 1),
		"average_vnd": average, "target_vnd": target, "sample_count": int(groups.get(chosen, {}).get("count", 0)), "legacy_fallback": average == 0}
