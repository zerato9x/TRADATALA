extends SceneTree

const TestSuiteScript := preload("res://tests/test_core_deal.gd")
const DrinkRosterSuiteScript := preload("res://tests/test_drink_roster.gd")
const CampaignTestSuiteScript := preload("res://tests/test_campaign.gd")
const MoneyPresentationTestSuiteScript := preload("res://tests/test_money_presentation.gd")
const GieoQueTestSuiteScript := preload("res://tests/test_gieo_que.gd")
const MusicAntiFatigueTestSuiteScript := preload("res://tests/test_music_anti_fatigue.gd")


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var runner := McpTestRunner.new()
	var result := runner.run_suites([
		preload("res://tests/test_meta_save_files.gd").new(),
		preload("res://tests/test_boss_debug.gd").new(),
		preload("res://tests/test_hand_advice.gd").new(),
		preload("res://tests/test_zodiac.gd").new(), preload("res://tests/test_cat_persuasion.gd").new(),
		preload("res://tests/test_zodiac_runtime.gd").new(),
		preload("res://tests/test_zodiac_endgame.gd").new(),
		preload("res://tests/test_presentation_text.gd").new(),
		preload("res://tests/test_campaign_overhaul.gd").new(),
		preload("res://tests/test_run_progression.gd").new(),
		preload("res://tests/test_resolve_accounting.gd").new(),
		TestSuiteScript.new(),
		preload("res://tests/test_card_action_cache.gd").new(),
		DrinkRosterSuiteScript.new(),
		CampaignTestSuiteScript.new(),
		MoneyPresentationTestSuiteScript.new(),
		GieoQueTestSuiteScript.new(),
		preload("res://tests/test_gieo_card_fx.gd").new(),
		preload("res://tests/test_misc_npc.gd").new(),
		preload("res://tests/test_shoe_shine.gd").new(),
		MusicAntiFatigueTestSuiteScript.new(),
		preload("res://tests/test_relics.gd").new(),
		preload("res://tests/test_hang_rong_shop.gd").new(),
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
