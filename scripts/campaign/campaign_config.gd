class_name CampaignConfig
extends RefCounted

## The online-demo debt curve is the full campaign economy baseline.
const DAYS := [
	{"id": "monday", "name_key": "DAY_MONDAY", "required_vnd": 250_000},
	{"id": "tuesday", "name_key": "DAY_TUESDAY", "required_vnd": 500_000},
	{"id": "wednesday", "name_key": "DAY_WEDNESDAY", "required_vnd": 1_000_000},
	{"id": "thursday", "name_key": "DAY_THURSDAY", "required_vnd": 2_000_000},
	{"id": "friday", "name_key": "DAY_FRIDAY", "required_vnd": 4_000_000},
	{"id": "saturday", "name_key": "DAY_SATURDAY", "required_vnd": 8_000_000},
	{"id": "sunday", "name_key": "DAY_SUNDAY", "required_vnd": 16_000_000},
]


static func day_definitions() -> Array[Dictionary]:
	var definitions: Array[Dictionary] = []
	for index in range(DAYS.size()):
		var day: Dictionary = DAYS[index].duplicate(true)
		definitions.append(day)
	return definitions


static func requirements_are_strictly_increasing(days: Array[Dictionary] = day_definitions()) -> bool:
	for index in range(1, days.size()):
		if int(days[index]["required_vnd"]) <= int(days[index - 1]["required_vnd"]):
			return false
	return true
