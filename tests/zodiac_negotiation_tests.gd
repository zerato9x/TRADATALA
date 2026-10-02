extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var runner := McpTestRunner.new()
	var result := runner.run_suites([preload("res://tests/test_zodiac.gd").new(), preload("res://tests/test_cat_persuasion.gd").new(), preload("res://tests/test_gieo_que.gd").new()], "", "", {}, true)
	print("ZODIAC_NEGOTIATION_TESTS total=%d passed=%d failed=%d" % [result.total, result.passed, result.failed])
	for failure in result.get("failures", []): print("TEST_FAIL %s.%s: %s" % [failure.suite, failure.test, failure.message])
	quit(0 if result.failed == 0 else 1)
