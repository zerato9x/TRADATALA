class_name SemanticText
extends RefCounted
## Display-only tokens. Original card IDs, rank values and authored strings stay intact.
const SUITS := {"s": "Spades", "h": "Hearts", "d": "Diamonds", "c": "Clubs", "♠": "Spades", "♥": "Hearts", "♦": "Diamonds", "♣": "Clubs",
	"spades": "Spades", "hearts": "Hearts", "diamonds": "Diamonds", "clubs": "Clubs", "bích": "Spades", "cơ": "Hearts", "rô": "Diamonds", "tép": "Clubs", "chuồn": "Clubs"}
const ZODIAC_NAMES := {"rooster": "rooster", "dậu": "rooster", "cat": "cat", "mão": "cat", "dog": "dog", "tuất": "dog", "monkey": "monkey", "thân": "monkey",
	"pig": "pig", "hợi": "pig", "ox": "ox", "sửu": "ox", "horse": "horse", "ngọ": "horse", "goat": "goat", "mùi": "goat", "rat": "rat", "mouse": "rat", "tý": "rat",
	"tiger": "tiger", "dần": "tiger", "snake": "snake", "tỵ": "snake", "dragon": "dragon", "thìn": "dragon"}
const ACTION_WORDS := ["meld", "extend", "extension", "discard", "draw", "settle", "accept", "refuse", "haggle", "phỏm", "nối", "ghép", "bỏ", "rút", "chốt", "đồng ý", "từ chối", "mặc cả"]
const MECHANIC_WORDS := ["deadwood", "mỏm", "last call", "chốt hạ", "gieo quẻ", "relic", "di vật", "shiny", "liquid", "sáng bóng", "lưu quang", "promise", "cam kết", "patience", "kiên nhẫn"]
static var _tokens: RegEx
static var _tags: RegEx
static var _cards: RegEx
static var _actions: Dictionary = {}

static func _prepare() -> void:
	if _tokens != null: return
	_cards = RegEx.new()
	_cards.compile("(?<![\\p{L}\\p{N}_])(?<rank>A|10|[2-9]|J|Q|K)(?:\\s*(?<symbol>[SHDC♠♥♦♣])|(?:\\s+of)?[ ·]+(?<suit>Spades|Hearts|Diamonds|Clubs|Bích|Cơ|Rô|Tép|Chuồn))(?![\\p{L}\\p{N}_])")
	_tokens = RegEx.new()
	var words: Array[String] = []
	words.append_array(ACTION_WORDS)
	for word in ACTION_WORDS: _actions[word] = true
	for entry: Dictionary in ActionVocabulary.ENTRIES:
		for word: String in entry.words:
			if not _actions.has(word.to_lower()): words.append(word.to_lower())
			_actions[word.to_lower()] = true
	words.append_array(MECHANIC_WORDS)
	words.append_array(ZODIAC_NAMES.keys())
	words.append_array(["Spades", "Hearts", "Diamonds", "Clubs", "Bích", "Cơ", "Rô", "Tép", "Chuồn"])
	words.sort_custom(func(a: String, b: String): return a.length() > b.length())
	_tokens.compile(_cards.get_pattern() + "|(?<![\\p{L}\\p{N}_])[+−-]?[0-9][0-9.,]*(?:\\s*(?:VNĐ|VND|PTS|điểm|points?|%|×)|/[0-9]+)?(?![\\p{L}\\p{N}_])|(?<![\\p{L}\\p{N}_])(?i:" + "|".join(words) + ")(?![\\p{L}\\p{N}_])")
	_tags = RegEx.new()
	_tags.compile("\\[[^\\]]*\\]")

static func color_tag(text: String, color: Color) -> String:
	return "[color=#%s]%s[/color]" % [color.to_html(false), text]

static func format(copy: String, pixels: int = 18, role: StringName = &"body", bbcode: bool = false, paper: bool = false) -> String:
	_prepare()
	if not bbcode: return _surface_colors(_plain(copy, pixels, role), paper)
	var result := ""
	var cursor := 0
	var in_image := false
	for tag in _tags.search_all(copy):
		var between := copy.substr(cursor, tag.get_start() - cursor)
		result += between if in_image else _plain(between, pixels, role)
		var value := tag.get_string()
		if value.begins_with("[img"): in_image = true
		elif value == "[/img]": in_image = false
		# Older panel-specific color tags yield to the shared semantic rules.
		if not value.begins_with("[color=") and value != "[/color]": result += value
		cursor = tag.get_end()
	return _surface_colors(result + _plain(copy.substr(cursor), pixels, role), paper)

static func _surface_colors(copy: String, paper: bool) -> String:
	if not paper: return copy
	for role: StringName in PresentationTheme.SEMANTIC_COLORS:
		copy = copy.replace("#" + PresentationTheme.semantic_color(role).to_html(false), "#" + PresentationTheme.semantic_color(role, true).to_html(false))
	for color: Color in PresentationTheme.ZODIAC_COLORS.values() + PresentationTheme.SUIT_COLORS.values():
		copy = copy.replace("#" + color.to_html(false), "#" + color.darkened(0.45).to_html(false))
	return copy

static func _plain(copy: String, pixels: int, role: StringName) -> String:
	var result := ""
	var cursor := 0
	for found in _tokens.search_all(copy):
		result += copy.substr(cursor, found.get_start() - cursor).replace("[", "[lb]")
		var token := found.get_string()
		var lower := token.to_lower()
		var card := _cards.search(token)
		if card != null:
			var suit: String = SUITS.get((card.get_string("symbol") + card.get_string("suit")).to_lower(), "")
			result += card_reference(card.get_string("rank"), suit, pixels)
		elif ZODIAC_NAMES.has(lower): result += color_tag(token, PresentationTheme.zodiac_color(ZODIAC_NAMES[lower]))
		elif SUITS.has(lower): result += suit_icon(SUITS[lower], pixels)
		elif _actions.has(lower): result += color_tag(token, PresentationTheme.ACTION)
		elif lower in MECHANIC_WORDS: result += color_tag(token, PresentationTheme.SPEAKER)
		else:
			var number_role := role if role in [&"gain", &"cost", &"debt", &"danger", &"warning"] else &"number"
			if token.begins_with("+"): number_role = &"gain"
			elif token.begins_with("−") or token.begins_with("-"): number_role = &"cost"
			result += color_tag(token, PresentationTheme.semantic_color(number_role))
		cursor = found.get_end()
	return result + copy.substr(cursor).replace("[", "[lb]")

static func suit_icon(suit: String, pixels: int = 18) -> String:
	var texture := CardSymbolArt.texture_for_suit(suit)
	if texture == null: return ""
	var width := maxi(9, roundi(pixels * 0.65))
	return '[img width=%d height=%d alt="%s"]%s[/img]' % [width, width, suit, texture.resource_path]

static func card_reference(rank: String, suit: String, pixels: int = 18) -> String:
	return color_tag(rank, PresentationTheme.suit_color(suit)) + suit_icon(suit, pixels)

static func role_for(control: Control, copy: String) -> StringName:
	if control.has_meta("text_role"): return control.get_meta("text_role")
	if control is Button: return &"action"
	var existing := control.get_theme_color("default_color" if control is RichTextLabel else "font_color")
	for meaning: StringName in PresentationTheme.PAPER_SEMANTIC_COLORS:
		if existing == PresentationTheme.PAPER_SEMANTIC_COLORS[meaning]: return meaning
	if copy.strip_edges().is_valid_int() or copy.strip_edges().is_valid_float(): return &"number"
	for meaning: StringName in PresentationTheme.SEMANTIC_COLORS:
		if existing == PresentationTheme.SEMANTIC_COLORS[meaning]: return meaning
	if existing == PresentationTheme.GOLD: return &"heading"
	if existing == PresentationTheme.TEA: return &"success"
	if existing == PresentationTheme.RED: return &"danger"
	if existing.a == 0 and control.has_meta("semantic_role"): return control.get_meta("semantic_role")
	var node_name := String(control.name).to_lower()
	if "debt" in node_name: return &"debt"
	if "price" in node_name or "cost" in node_name or "penalty" in node_name: return &"cost"
	if "wallet" in node_name: return &"wallet"
	if "income" in node_name or "earnings" in node_name: return &"gain"
	if "speaker" in node_name or "nametag" in node_name: return &"speaker"
	if "hint" in node_name or "caption" in node_name: return &"muted"
	if "title" in node_name or "heading" in node_name: return &"heading"
	return &"body"
