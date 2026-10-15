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
	var file := FileAccess.open("res://locale/ui.csv", FileAccess.READ)
	var expected := {}
	while not file.eof_reached():
		var row := file.get_csv_line()
		if row.size() == 3 and row[0] == "NPC_GREETING_THAY_BOI":
			expected = {"vi": row[1], "en": row[2]}
	assert_eq(expected.size(), 2)
	assert_true(expected.get("en", "") != expected.get("vi", ""))
	var previous := TranslationServer.get_locale()
	for locale: String in expected:
		TranslationServer.set_locale(locale)
		assert_eq(TranslationServer.translate("NPC_GREETING_THAY_BOI"), expected[locale], "Imported greeting matches its language source")
	TranslationServer.set_locale(previous)

func _copy_tokens(copy: String) -> Array[String]:
	var pattern := RegEx.new()
	pattern.compile("\\{[a-z_]+\\}|%(?:[0-9]*\\.?[0-9]*)[sdf]|%%")
	var tokens: Array[String] = []
	for found in pattern.search_all(copy): tokens.append(found.get_string())
	return tokens

func test_localized_copy_preserves_format_arguments() -> void:
	var file := FileAccess.open("res://locale/ui.csv", FileAccess.READ)
	var seen := {}
	file.get_csv_line()
	while not file.eof_reached():
		var row := file.get_csv_line()
		if row.size() != 3: continue
		assert_false(seen.has(row[0]), "Duplicate translation key: " + row[0])
		seen[row[0]] = true
		assert_false(row[1].is_empty() or row[2].is_empty(), "Empty translation: " + row[0])
		assert_eq(_copy_tokens(row[1]), _copy_tokens(row[2]), "Translation arguments: " + row[0])
		assert_false(row[1].contains(String.chr(7)) or row[2].contains(String.chr(7)), "No control glyphs in copy")

func _check_bilingual_tree(value: Variant, location: String) -> void:
	if value is Dictionary:
		if value.has("en"):
			assert_true(value.has("vi") and not String(value.en).is_empty() and not String(value.get("vi", "")).is_empty(), location + " has both languages")
			assert_eq(_copy_tokens(value.en), _copy_tokens(value.get("vi", "")), location + " keeps memory and format tokens")
		for key: Variant in value: _check_bilingual_tree(value[key], location + "/" + str(key))
	elif value is Array:
		for index in value.size(): _check_bilingual_tree(value[index], location + "/" + str(index))

func test_zodiac_copy_has_both_languages_and_bound_memory_tokens() -> void:
	for id: String in ZodiacCatalog.DEFINITIONS:
		assert_true(ZodiacCatalog.PORTRAITS.ENTRIES.has(id), "Public portrait: " + id)
		_check_bilingual_tree(ZodiacCatalog.PORTRAITS.ENTRIES[id], id + "/portrait")
		_check_bilingual_tree(ZodiacCatalog.persuasion_nodes(id), id + "/nodes")
		_check_bilingual_tree(ZodiacCatalog.persuasion_config(id), id + "/config")

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

func test_all_card_reference_formats_use_existing_suit_assets() -> void:
	for ranks in [["A", "S", "spade"], ["10", "H", "heart"], ["J", "D", "diamond"], ["Q", "C", "club"], ["K", "♣", "club"]]:
		var output := SemanticText.format(ranks[0] + ranks[1])
		assert_true(output.contains("symbol_" + ranks[2] + ".png"), "Existing icon: " + output)
		assert_true(output.contains("]" + ranks[0] + "[/color]"), "Conventional rank is preserved")
	assert_true(SemanticText.format("9 of Hearts").contains("symbol_heart.png"))
	assert_true(SemanticText.format("9 · Cơ").contains("symbol_heart.png"))
	assert_eq(SemanticText.format("standard_9_hearts"), "standard_9_hearts", "Physical IDs are never reformatted")

func test_semantic_tokens_preserve_copy_and_override_zodiac_names() -> void:
	var output := SemanticText.format("Cat · Discard 9H · +250.000 VNĐ / −50.000 VNĐ")
	assert_true(output.contains(PresentationTheme.zodiac_color("cat").to_html(false)))
	assert_true(output.contains(PresentationTheme.ACTION.to_html(false)))
	assert_true(output.contains(PresentationTheme.MONEY_GAIN.to_html(false)))
	assert_true(output.contains(PresentationTheme.MONEY_COST.to_html(false)))
	assert_true(SemanticText.format("[literal]").begins_with("[lb]literal]"))
	var rich := SemanticText.format("[center][b]Cat[/b] · [color=red]12 PTS[/color][/center]", 18, &"body", true)
	assert_true(rich.begins_with("[center][b]"))
	assert_true(rich.ends_with("[/center]"))
	assert_false(rich.contains("[color=red]"), "Panel color yields to meaning")

func test_quick_drink_copy_is_short_and_full_rules_are_retained() -> void:
	var previous := TranslationServer.get_locale()
	for locale in ["en", "vi"]:
		TranslationServer.set_locale(locale)
		for id in DrinkCatalog.all_ids():
			assert_true(QuickInfo.drink(id).length() <= 65, "Short main-screen copy: " + id)
			assert_true(not DrinkCatalog.effect_text(id).is_empty(), "Full catalog description retained")
	TranslationServer.set_locale(previous)

func test_brief_confirmation_keeps_thousands_in_currency_intact() -> void:
	assert_eq(QuickInfo.first_sentence("Pay 12.500 VNĐ. Full rules follow."), "Pay 12.500 VNĐ.")
