extends SceneTree

const TestSuiteScript := preload("res://tests/test_core_deal.gd")


func _initialize() -> void:
	var runner := McpTestRunner.new()
	var result := runner.run_suites([TestSuiteScript.new()], "", "", {}, true)
	print("TRADATALA_TESTS total=%d passed=%d failed=%d skipped=%d" % [
		result["total"], result["passed"], result["failed"], result["skipped"]
	])
	if result["failed"] > 0:
		for failure in result.get("failures", []):
			print("TEST_FAIL %s.%s: %s" % [failure["suite"], failure["test"], failure["message"]])
		quit(1)
	else:
		quit(0)

