extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var runner := McpTestRunner.new()
	for path in ["res://tests/test_core_deal.gd", "res://tests/test_campaign.gd", "res://tests/test_gieo_que.gd", "res://tests/test_gieo_card_fx.gd"]:
		var suite = load(path).new()
		runner.run_suite(suite)
	var result := runner.get_results(false)
	print("GIEO_FX_SMOKE ", JSON.stringify(result))
	quit(0 if int(result.get("failed", 0)) == 0 else 1)
