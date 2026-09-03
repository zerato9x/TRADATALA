@tool
extends McpTestSuite


func suite_name() -> String:
	return "money_presentation"


func test_denominations_cover_the_bill_atlas_once() -> void:
	assert_eq(MoneyPresentation.DENOMINATIONS.size(), 9)
	assert_eq(MoneyPresentation.DENOMINATION_CELLS.size(), 9)
	for denomination in MoneyPresentation.DENOMINATIONS:
		assert_true(MoneyPresentation.DENOMINATION_CELLS.has(denomination))


func test_greedy_breakdown_is_largest_first_and_exact() -> void:
	var breakdown := MoneyPresentation.denomination_breakdown(387_000)
	var expected := [200_000, 100_000, 50_000, 20_000, 10_000, 5_000, 2_000]
	assert_eq(breakdown.size(), expected.size())
	var reconstructed := 0
	for index in breakdown.size():
		assert_eq(int(breakdown[index]["denomination"]), expected[index])
		reconstructed += int(breakdown[index]["denomination"]) * int(breakdown[index]["count"])
	assert_eq(reconstructed, 387_000)


func test_repeated_notes_are_one_logical_bundle() -> void:
	var breakdown := MoneyPresentation.denomination_breakdown(2_500_000)
	assert_eq(breakdown.size(), 1)
	assert_eq(int(breakdown[0]["denomination"]), 500_000)
	assert_eq(int(breakdown[0]["count"]), 5)


func test_negative_and_zero_wallets_create_no_cash_objects() -> void:
	var presentation := MoneyPresentation.new()
	assert_eq(presentation.wallet_visual_object_count(0), 0)
	assert_eq(presentation.wallet_visual_object_count(-75_000), 0)
	assert_true(presentation.wallet_visual_object_count(987_654_000) <= MoneyPresentation.MAX_WALLET_OBJECTS)
	presentation.free()
