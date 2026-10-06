class_name RunSnapshotFields
extends RefCounted
## Applies only owner-declared V3 fields; newly added internals never enter saves.
static func fields(object: Object, names: Array) -> Dictionary:
	var data := {}
	for field: String in names:
		data[field] = object.get(field)
	return data

static func apply_fields(object: Object, data: Dictionary, names: Array) -> void:
	for field: String in names:
		if not data.has(field):
			continue
		var existing: Variant = object.get(field)
		if existing is Array:
			existing.assign(data[field])
		else:
			object.set(field, data[field])
