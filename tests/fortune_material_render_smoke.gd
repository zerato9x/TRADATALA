extends SceneTree
func _initialize() -> void:
	call_deferred("_run")
func _run() -> void:
	var parent := Node.new()
	root.add_child(parent)
	var report: Dictionary = await load("res://tools/gieo_material_render_check.gd").new().run(parent)
	print("FORTUNE_MATERIAL_RENDER: ",JSON.stringify(report))
	quit(0 if report.passed else 1)
