class_name CampaignConfig
extends RefCounted

## Balance lives here, outside campaign progression. These are intentionally
## conservative first-pass thresholds and can be tuned without changing flow.
const DAYS := [
	{"id": "monday", "name_key": "DAY_MONDAY", "required_vnd": 0},
	{"id": "tuesday", "name_key": "DAY_TUESDAY", "required_vnd": 100_000},
	{"id": "wednesday", "name_key": "DAY_WEDNESDAY", "required_vnd": 250_000},
	{"id": "thursday", "name_key": "DAY_THURSDAY", "required_vnd": 450_000},
	{"id": "friday", "name_key": "DAY_FRIDAY", "required_vnd": 700_000},
	{"id": "saturday", "name_key": "DAY_SATURDAY", "required_vnd": 1_000_000},
	{"id": "sunday", "name_key": "DAY_SUNDAY", "required_vnd": 1_400_000},
]


static func day_definitions() -> Array[Dictionary]:
	var definitions: Array[Dictionary] = []
	for day: Dictionary in DAYS:
		definitions.append(day.duplicate(true))
	return definitions


static func requirements_are_strictly_increasing(days: Array[Dictionary] = day_definitions()) -> bool:
	for index in range(1, days.size()):
		if int(days[index]["required_vnd"]) <= int(days[index - 1]["required_vnd"]):
			return false
	return true
