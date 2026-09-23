@tool
extends McpTestSuite

func suite_name() -> String:
	return "presentation_text"

func test_bilingual_csv_has_exactly_three_columns() -> void:
	var file := FileAccess.open("res://locale/ui.csv", FileAccess.READ)
	assert_true(file != null)
	while not file.eof_reached():
		var row := file.get_csv_line()
		if row.size() == 1 and row[0].is_empty(): continue
		assert_eq(row.size(), 3, "Malformed localization row: " + row[0])

func test_fortune_teller_greeting_uses_selected_language() -> void:
	var previous := TranslationServer.get_locale()
	TranslationServer.set_locale("en")
	assert_true(TranslationServer.translate("NPC_GREETING_THAY_BOI").begins_with("Pull the lever"))
	TranslationServer.set_locale("vi")
	assert_true(TranslationServer.translate("NPC_GREETING_THAY_BOI").begins_with("Kéo cần trước,"))
	TranslationServer.set_locale(previous)

func test_money_emphasis_preserves_signs_and_prose() -> void:
	var copy := PresentationTheme.emphasize_money("Reward +250.000 VNĐ / Cost −50.000 VNĐ")
	assert_true(copy.begins_with("Reward "))
	assert_true(copy.contains("[b]+250.000 VNĐ[/b]"))
	assert_true(copy.contains(" / Cost "))
	assert_true(copy.contains("[b]−50.000 VNĐ[/b]"))
	assert_true(PresentationTheme.semantic_color(&"gain") != PresentationTheme.semantic_color(&"cost"))

func test_currency_and_farewell_regressions() -> void:
	assert_eq(VndWallet.format_vnd(0), "0 VNĐ")
	assert_eq(VndWallet.format_vnd(12000, true), "+12.000 VNĐ")
	assert_eq(VndWallet.format_amount(-12000), "−12.000")
	var previous := TranslationServer.get_locale()
	TranslationServer.set_locale("vi")
	assert_eq(TranslationServer.translate("NPC_LEAVE"), "Tạm biệt nhé.")
	TranslationServer.set_locale(previous)
	var file := FileAccess.open("res://locale/ui.csv", FileAccess.READ)
	assert_false(file.get_as_text().contains("₫"), "Localized copy uses literal VNĐ")
