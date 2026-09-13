class_name ActionVocabulary
extends RefCounted

# One visual vocabulary for dialogue, the legend, and the action buttons.
# Words remain visible: color is additional information, never the only cue.
const ENTRIES := [
	{"id": "meld", "color": "8cdd98", "words": ["HẠ", "MELD", "LAY", "HẠ PHỎM"]},
	{"id": "extend", "color": "ffd080", "words": ["GỬI", "GHÉP", "EXTEND", "EXTENSION", "EXTENSIONS"]},
	{"id": "discard", "color": "ffaaa0", "words": ["BỎ", "DISCARD", "DISCARDS"]},
	{"id": "dump", "color": "ffaaa0", "words": ["DUMP", "REDRAW", "ĐỔI BÀI"]},
	{"id": "keep", "color": "8fe7ff", "words": ["KEEP", "GIỮ", "PRESERVE", "PRESERVED", "PRESERVATION"]},
	{"id": "draw", "color": "b8dcff", "words": ["DRAW", "DRAWING", "REFILL", "REFILLS", "RÚT", "BÙ"]},
	{"id": "swap", "color": "8fe7ff", "words": ["SWAP", "SWAPPING", "ĐỔI LÁ", "ĐỔI MỘT LÁ"]},
	{"id": "recover", "color": "8fe7ff", "words": ["RECOVER", "RECLAIM", "RETURN", "LẤY LẠI"]},
	{"id": "settle", "color": "d9b6ff", "words": ["SETTLE", "SETTLING", "SETTLEMENT", "CHỐT", "KẾT HIỆP"]},
	{"id": "end_turn", "color": "d9b6ff", "words": ["END TURN", "KẾT LƯỢT"]},
	{"id": "order", "color": "ffe099", "words": ["ORDER", "BUY", "MUA"]},
]

static func color_for(id: String) -> Color:
	for entry in ENTRIES:
		if entry["id"] == id: return Color(entry["color"])
	return Color.WHITE

static func colorize(text: String) -> String:
	var words: Array[String] = []
	var colors := {}
	for entry in ENTRIES:
		for word: String in entry["words"]:
			words.append(word)
			colors[word] = entry["color"]
	words.sort_custom(func(a: String, b: String) -> bool: return a.length() > b.length())
	var pattern := RegEx.new()
	pattern.compile("(?i)(?<![\\p{L}\\p{N}_])(?:" + "|".join(words) + ")(?![\\p{L}\\p{N}_])")
	var result := ""
	var cursor := 0
	for found in pattern.search_all(text.to_upper()):
		result += text.substr(cursor, found.get_start() - cursor)
		var word := text.substr(found.get_start(), found.get_end() - found.get_start())
		result += "[color=#%s]%s[/color]" % [colors.get(word.to_upper(), "ffffff"), word]
		cursor = found.get_end()
	return result + text.substr(cursor)

static func legend() -> String:
	var lines: Array[String] = []
	for entry in ENTRIES:
		lines.append("[color=#%s][b]%s[/b][/color]  —  %s" % [entry["color"], TranslationServer.translate("VERB_" + String(entry["id"]).to_upper()), TranslationServer.translate("VERB_HELP_" + String(entry["id"]).to_upper())])
	return "\n\n".join(lines)
