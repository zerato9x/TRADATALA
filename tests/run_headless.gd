extends SceneTree

const TestSuiteScript := preload("res://tests/test_core_deal.gd")
const DrinkRosterSuiteScript := preload("res://tests/test_drink_roster.gd")
const CampaignTestSuiteScript := preload("res://tests/test_campaign.gd")
const MoneyPresentationTestSuiteScript := preload("res://tests/test_money_presentation.gd")
const GieoQueTestSuiteScript := preload("res://tests/test_gieo_que.gd")
const MusicAntiFatigueTestSuiteScript := preload("res://tests/test_music_anti_fatigue.gd")


func _initialize() -> void:
	var runner := McpTestRunner.new()
	var result := runner.run_suites([
		preload("res://tests/test_resolve_accounting.gd").new(),
		TestSuiteScript.new(),
		DrinkRosterSuiteScript.new(),
		CampaignTestSuiteScript.new(),
		MoneyPresentationTestSuiteScript.new(),
		GieoQueTestSuiteScript.new(),
		preload("res://tests/test_misc_npc.gd").new(),
		MusicAntiFatigueTestSuiteScript.new(),
		preload("res://tests/test_relics.gd").new(),
	], "", "", {}, true)
	print("TRADATALA_TESTS total=%d passed=%d failed=%d skipped=%d" % [
		result["total"], result["passed"], result["failed"], result["skipped"]
	])
	if result["failed"] > 0:
		for failure in result.get("failures", []):
			print("TEST_FAIL %s.%s: %s" % [failure["suite"], failure["test"], failure["message"]])
		quit(1)
	else:
		quit(0)
