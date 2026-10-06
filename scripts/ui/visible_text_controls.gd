class_name VisibleTextControls
extends Node
## Shared text registration lifecycle; each policy supplies its own state.
signal hidden(control: Control, state: Dictionary)
signal removed(control: Control, state: Dictionary)
signal form_found(reference: WeakRef)

var include_buttons := false
var include_forms := false
var state_factory: Callable
var _tracked: Dictionary = {}
var _visible: Dictionary = {}

func _ready() -> void:
	get_tree().node_added.connect(_discover)
	get_tree().node_removed.connect(_forget)
	_collect(get_tree().root)

func _collect(node: Node) -> void:
	_discover(node)
	for child in node.get_children(): _collect(child)

func _discover(node: Node) -> void:
	if node.has_meta("semantic_renderer"): return
	if include_forms and (node is LineEdit or node is TextEdit or node is PopupMenu):
		form_found.emit(weakref(node))
	if not (node is Label or node is RichTextLabel or (include_buttons and node is Button)): return
	var id := node.get_instance_id()
	if _tracked.has(id): return
	var control := node as Control
	var state: Dictionary = state_factory.call(control)
	state.ref = weakref(node)
	state.visibility_callback = _update_visibility.bind(id)
	_tracked[id] = state
	control.visibility_changed.connect(state.visibility_callback)
	_update_visibility(id)

func _update_visibility(id: int) -> void:
	if not _tracked.has(id): return
	var state: Dictionary = _tracked[id]
	var control: Control = state.ref.get_ref()
	if not is_instance_valid(control): return
	if control.is_visible_in_tree():
		_visible[id] = state
	else:
		_visible.erase(id)
		hidden.emit(control, state)

func _forget(node: Node) -> void:
	_unregister(node.get_instance_id())

func _unregister(id: int) -> void:
	if not _tracked.has(id): return
	var state: Dictionary = _tracked[id]
	_tracked.erase(id)
	_visible.erase(id)
	var control: Control = state.ref.get_ref()
	if not is_instance_valid(control): return
	if control.visibility_changed.is_connected(state.visibility_callback):
		control.visibility_changed.disconnect(state.visibility_callback)
	removed.emit(control, state)

func visible_states() -> Array:
	# Snapshot because a policy may create a semantic child while synchronizing.
	return _visible.values()

func tracked_count() -> int:
	return _tracked.size()

func visible_count() -> int:
	return _visible.size()

func _exit_tree() -> void:
	get_tree().node_added.disconnect(_discover)
	get_tree().node_removed.disconnect(_forget)
	for id in _tracked.keys(): _unregister(id)
