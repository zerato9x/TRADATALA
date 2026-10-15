class_name GameGlossary
extends CanvasLayer
## Read-only reference assembled from the current catalogs.
var _entries: Array[Dictionary] = []
var _list: VBoxContainer
var _body: RichTextLabel
var _search: LineEdit
var _section := "all"

static func words(en: String, vi: String) -> String:
	return vi if TranslationServer.get_locale().begins_with("vi") else en

static func open(parent: Node, section: String = "all") -> void:
	var existing := parent.get_tree().root.get_node_or_null("GameGlossary")
	if existing != null:
		existing._section = section
		existing._search.clear()
		existing._refresh()
		return
	var view := GameGlossary.new()
	view.name = "GameGlossary"
	view._section = section
	parent.get_tree().root.add_child(view)

static func open_zodiac(parent: Node, id: String) -> void:
	open(parent, "zodiac")
	var view := parent.get_tree().root.get_node("GameGlossary") as GameGlossary
	view._entries = view._entries.filter(func(entry: Dictionary): return not entry.get("live_context", false))
	for index in view._entries.size():
		var entry: Dictionary = view._entries[index]
		if entry.section == "zodiac" and entry.title == ZodiacCatalog.display_name(id):
			view._entries.remove_at(index)
			view._entries.push_front(entry)
			break
	view._refresh()

static func open_entry(parent: Node, title: String, detail: String, section: String = "core") -> void:
	open(parent, section)
	var view := parent.get_tree().root.get_node("GameGlossary") as GameGlossary
	view._entries = view._entries.filter(func(entry: Dictionary): return not entry.get("live_context", false))
	view._entries.push_front({"section": section, "title": title, "body": detail, "live_context": true})
	view._refresh()

func _ready() -> void:
	layer = 880
	var shade := ColorRect.new()
	shade.color = Color("101e30")
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(shade)
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 28)
	margin.add_theme_constant_override("margin_left", 164)
	margin.theme = PresentationTheme.create_game_theme()
	add_child(margin)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 14)
	margin.add_child(box)
	var header := HBoxContainer.new()
	box.add_child(header)
	var title := Label.new()
	title.text = words("HANDBOOK", "SỔ TAY")
	title.add_theme_font_size_override("font_size", 28)
	title.add_theme_color_override("font_color", PresentationTheme.GOLD)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title)
	var close := Button.new()
	close.name = "CloseHandbook"
	close.text = words("BACK TO TABLE", "VỀ BÀN")
	PresentationTheme.configure_button(close)
	close.pressed.connect(queue_free)
	header.add_child(close)
	_search = LineEdit.new()
	_search.name = "HandbookSearch"
	_search.placeholder_text = words("Search rules, cards, NPCs…", "Tìm luật, bài, nhân vật…")
	_search.text_changed.connect(func(_text): _refresh())
	box.add_child(_search)
	var tabs := HFlowContainer.new()
	box.add_child(tabs)
	for spec in [["all", "ALL", "TẤT CẢ"], ["core", "PLAY", "CHƠI"], ["scoring", "SCORING", "ĐIỂM"], ["campaign", "CAMPAIGN / ECONOMY", "HÀNH TRÌNH / TIỀN"], ["cards", "CARDS", "BÀI"], ["drinks", "DRINKS", "ĐỒ UỐNG"], ["gieo", "GIEO QUẺ", "GIEO QUẺ"], ["relics", "RELICS", "DI VẬT"], ["zodiac", "ZODIAC", "CON GIÁP"], ["npcs", "NPCs", "NHÂN VẬT"], ["lottery", "LOTTERY", "VÉ SỐ"], ["controls", "CONTROLS", "THAO TÁC"]]:
		var button := Button.new()
		button.text = words(spec[1], spec[2])
		PresentationTheme.configure_button(button)
		button.custom_minimum_size.y = 40
		button.pressed.connect(func(): _section = spec[0]; _refresh())
		tabs.add_child(button)
	var columns := HBoxContainer.new()
	columns.size_flags_vertical = Control.SIZE_EXPAND_FILL
	columns.add_theme_constant_override("separation", 24)
	box.add_child(columns)
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size.x = 310
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	columns.add_child(scroll)
	_list = VBoxContainer.new()
	_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(_list)
	_body = RichTextLabel.new()
	_body.bbcode_enabled = true
	_body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_body.add_theme_font_size_override("normal_font_size", 22)
	_body.add_theme_constant_override("line_separation", 10)
	columns.add_child(_body)
	_build_entries()
	_refresh()
	close.grab_focus()

func _input(event: InputEvent) -> void:
	if InputMap.has_action(&"boss_debug_lab") and event.is_action_pressed(&"boss_debug_lab") and BossDebugSession.available():
		return
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		queue_free()
	elif event is InputEventKey:
		# Preserve text entry but keep game hotkeys out of the underlying table.
		if not _search.has_focus():
			get_viewport().set_input_as_handled()

func _add(section: String, title: String, body: String) -> void:
	_entries.append({"section": section, "title": title, "body": body.replace("\\n", "\n")})

func _refresh() -> void:
	for child in _list.get_children():
		_list.remove_child(child)
		child.queue_free()
	var first := true
	_body.text = words("No matching entries.", "Không tìm thấy mục phù hợp.")
	for entry in _entries:
		if _section != "all" and entry.section != _section:
			continue
		if not _search.text.is_empty() and not (entry.title + " " + entry.body).to_lower().contains(_search.text.to_lower()):
			continue
		var button := Button.new()
		button.text = entry.title
		PresentationTheme.configure_button(button)
		if entry.has("relic_id"):
			button.icon = load(RelicCatalog.icon_path(entry.relic_id))
			button.expand_icon = true
			button.add_theme_constant_override("icon_max_width", 52)
		button.custom_minimum_size = Vector2(290, 42)
		button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		button.pressed.connect(_read.bind(entry))
		_list.add_child(button)
		if first:
			_read(entry)
			first = false

func _read(entry: Dictionary) -> void:
	_body.text = "[font_size=32]" + PresentationTheme.emphasis(entry.title, &"mechanic") + "[/font_size]\n\n" + PresentationTheme.emphasize_money(ActionVocabulary.colorize(entry.body))
	if entry.title in ["THUẦN DƯƠNG / THUẦN ÂM", "SET / BỘ"]:
		_body.text += "\n\n" + ("4C  5C  6C" if entry.section == "gieo" else "9S  9H  9D")
	if entry.has("relic_id"):
		_body.text += "\n\n[img width=160 height=160]%s[/img]" % RelicCatalog.icon_path(entry.relic_id)
	_body.scroll_to_line(0)

func _build_entries() -> void:
	_add("controls", words("Colors & card labels", "Màu chữ & ký hiệu bài"), words("Cyan marks actions; gold marks values and progress. Green shows gains, coral shows costs or danger, and violet highlights rules and speakers. Zodiac names use their own colors.\n\nCards use A, 2–10, J, Q, K and suit icons. Color helps you scan; the words and numbers still tell you what matters.", "Xanh lam chỉ hành động; vàng chỉ giá trị và tiến độ. Xanh lá là thu nhập, đỏ san hô là chi phí hoặc nguy hiểm, tím nhấn luật và người nói. Tên Con Giáp dùng màu riêng.\n\nBài dùng A, 2–10, J, Q, K cùng biểu tượng chất. Màu giúp nhìn nhanh; chữ và số vẫn cho biết thông tin cần thiết."))
	for topic in ["RUN", "EXTEND", "DISCARD", "TURN", "PHASE_END", "PHASE_CHOICE"]:
		_add("core", tr("HOW_" + topic + "_TITLE"), tr("HOW_" + topic + "_BODY"))
	_add("core", "SET / BỘ", words("A Set uses at least three cards of the same rank. Your changed or expanded deck can contain matching copies, so Sets may grow beyond four cards.\n\n9♠  9♥  9♦ → MELD\nAdd 9♣ → EXTEND.", "Bộ gồm ít nhất ba lá cùng hạng. Bộ bài đã đổi hoặc mở rộng có thể chứa lá trùng, nên Bộ có thể lớn hơn bốn lá.\n\n9♠  9♥  9♦ → HẠ\nThêm 9♣ → GHÉP."))
	_add("core", "HẠ / PHỎM", tr("HOW_INTRO") + "\n\n" + tr("HOW_SCORE_MELD_BODY"))
	_add("core", words("STRAWY / CARD ODDS", "STRAWY / TỶ LỆ BÀI"), words("Tap Strawy for help. During a Deal, double tap to preview a suggested move; tap again to confirm it. Changing the cards or selection cancels that preview. Ordinary Discard, End Turn, and Settle controls act immediately; Drink and carryover highlights don't add a confirmation step.\n\nChoose Show controls for a tour. Next and Done only advance the tour. Tap a speech bubble to reveal the rest of its text. Hover cards for completion odds or the ready-Meld symbol; choose Card info for discard details.\n\nKeep 0–100 compares cards within your current hand: lower means a better discard, not a lower probability. Odds describe the named target in the next refill. Strawy keeps ready Melds and Extensions when another discard is available. Locks still apply; Last Call has no refill.\n\nEach confirmed suggestion performs one action. Trà đá's extra discard or skip is a separate choice. Settings lets you hide Strawy, turn the tutorial on or off, and choose a Guided Opening for new runs. After Monday's tutorial, you can keep or hide him; change your mind in Settings at any time.", "Chạm Strawy để hỏi. Trong Ván, chạm hai lần để xem nước gợi ý; chạm thêm lần nữa để xác nhận. Đổi bài hoặc lựa chọn sẽ hủy xem trước. Các nút Bỏ bài, Kết Lượt, Chốt thực hiện ngay; viền Nước và bài giữ không thêm bước xác nhận.\n\nChọn Chỉ thao tác để xem hướng dẫn. Tiếp và Xong chỉ chuyển bước. Chạm bong bóng thoại để hiện hết chữ. Rê bài để xem tỷ lệ hoặc dấu Phỏm sẵn; chọn Xem lá bài để biết gợi ý bỏ.\n\nGiữ 0–100 so các lá trong tay hiện tại: thấp hơn là nên bỏ hơn, không phải xác suất thấp hơn. Tỷ lệ dành cho mục tiêu được nêu ở lần bù kế. Strawy giữ Phỏm và lá Ghép sẵn nếu còn lá khác để bỏ. Bài khóa vẫn bị khóa; Chốt Hạ không bù.\n\nMỗi gợi ý được xác nhận chỉ làm một thao tác. Bỏ thêm hay bỏ qua của Trà đá là lựa chọn riêng. Tùy chọn cho phép ẩn Strawy, bật tắt hướng dẫn và chọn Bài mở đầu hướng dẫn cho lượt mới. Sau hướng dẫn thứ Hai, bạn có thể giữ hoặc ẩn; đổi lại bất cứ lúc nào trong Tùy chọn."))
	_add("core", words("PHASE / LAST CALL / CARRYOVER", "GIAI ĐOẠN / CHỐT HẠ / BÀI GIỮ"), tr("HOW_PHASES_INTRO") + "\n\n" + tr("HOW_PHASE_END_BODY") + "\n\n" + tr("HOW_PHASE_CHOICE_BODY"))
	for topic in ["SCORE_MELD", "SCORE_EXTEND", "SCORE_PHASE", "MOM", "U", "U_KHAN"]:
		_add("scoring", tr("HOW_" + topic + "_TITLE"), tr("HOW_" + topic + "_BODY"))
	_add("scoring", words("Milestones & Exhaustion", "Mốc Phỏm & Cạn bài"), words("An Extension first pays the increase in its Meld's score. When a Set reaches 4, 8, 12… cards, or a Run completes A–K with 13 cards, it also pays one full-Meld score. Between Set milestones, Extensions pay only the increase; Liquid's full-Meld Echoes wait for the next milestone. Echoes never create more Echoes.\n\nWhen the draw pile runs out, Exhaustion scores and recycles eligible Meld cards. The animation shows those earnings; it does not pay them a second time.", "Nối Phỏm trả phần điểm tăng trước. Khi Bộ đạt 4, 8, 12… lá, hoặc Sảnh đủ 13 lá A–K, Phỏm được tính thêm một lượt đủ điểm. Giữa các mốc của Bộ, nối chỉ trả phần tăng; Dư Âm toàn Phỏm từ Lưu Quang chờ mốc tiếp. Dư Âm không sinh thêm Dư Âm.\n\nKhi chồng bốc cạn, Cạn bài tính điểm và tái chế bài Phỏm phù hợp. Hoạt ảnh hiển thị số tiền đó, không trả lần thứ hai."))
	_add("campaign", words("Daily debt & wallet", "Nợ ngày & Ví"), words("Starter → Morning Deal → Morning Event → Noon Deal → Noon Event → Afternoon Deal → Afternoon results → Evening Deal → Pay debt.\n\nĐòi Nợ introduces the day's debt in the morning and returns after the Evening Deal. Pay explicitly; insufficient funds end the run. The ledger shows the weekly targets.\n\nDrinks, relics and Gieo use today's debt target. Đánh Giày locks Rank/Suit prices to the day's target; each service doubles independently per visit. Lottery tickets use your current wallet and daily repeat counts. Payments and rewards travel to/from the same top money pile.", "Đầu ngày → Ván sáng → Sự kiện sáng → Ván trưa → Sự kiện trưa → Ván chiều → Dò vé số → Ván tối → Trả nợ.\n\nĐòi Nợ báo nợ vào sáng và trở lại sau ván tối. Chủ động trả; thiếu tiền kết thúc lượt chơi. Sổ nợ ghi mục tiêu cả tuần.\n\nĐồ uống, di vật và Gieo tính theo nợ ngày. Đánh Giày chốt giá đổi số/chất theo mục tiêu ngày; mỗi dịch vụ tăng gấp đôi riêng trong chuyến. Vé số tính theo ví hiện tại và số lần mua trong ngày. Tiền đi và về cùng chồng tiền phía trên."))
	_add("campaign", words("Difficulty & Endless", "Độ khó & Vô tận"), words("Choose a difficulty before a new run. Difficulty 1 uses the original weekly debts; each next difficulty doubles every daily debt. Paying Sunday unlocks the next difficulty permanently, even if you choose Endless. You can exit to the menu to start that difficulty, or keep this run's cards, relics and wallet in Endless. Endless debt grows 50% per day. Resuming keeps the saved run's difficulty.", "Chọn độ khó trước ván mới. Độ khó 1 dùng mức nợ gốc; mỗi mức kế tiếp nhân đôi nợ từng ngày. Trả nợ Chủ nhật mở vĩnh viễn độ khó tiếp theo, kể cả khi chọn Vô tận. Về menu để bắt đầu độ khó mới, hoặc giữ bài, di vật và ví của lượt này trong Vô tận. Nợ Vô tận tăng 50% mỗi ngày. Tiếp tục bản lưu giữ nguyên độ khó đã chọn."))
	_add("cards", words("Your deck & lasting changes", "Bộ bài và thay đổi lâu dài"), words("Your run begins with 52 cards. Bought cards join that deck; removed cards leave it. Two cards with the same rank and suit are still separate cards.\n\nGieo Quẻ changes Fortune and special properties. The Shoe Shiner changes a card's printed rank or suit while keeping its other properties. These changes follow that card between Deals for the rest of the run; temporary effects stay within their Deal.\n\nA=1, J=11, Q=12, K=13. Negative and Glitch offer more ways to form Melds without changing printed value. Negative uses the card's current rank and suit; Glitch can stand for any rank and suit.", "Lượt chơi bắt đầu với 52 lá. Bài mua thêm vào bộ; bài đã bỏ rời bộ. Hai lá cùng hạng và chất vẫn là hai lá riêng.\n\nGieo Quẻ đổi Vận và thuộc tính đặc biệt. Đánh Giày đổi hạng hoặc chất in trên lá, giữ các thuộc tính khác. Thay đổi đi theo đúng lá đó qua các Ván đến hết lượt chơi; hiệu ứng tạm chỉ ở trong Ván.\n\nA=1, J=11, Q=12, K=13. Âm Bản và Glitch cho thêm cách ghép Phỏm mà không đổi giá trị in. Âm Bản dựa vào hạng và chất hiện tại; Glitch đóng vai mọi hạng và chất."))
	for id: String in DrinkCatalog.DEFINITIONS:
		_add("drinks", DrinkCatalog.display_name(id), DrinkCatalog.effect_text(id))
	for id: String in ZodiacCatalog.DEFINITIONS:
		var rules := ZodiacCatalog.portrait_text(id)
		if ZodiacCatalog.boss_available(id):
			rules += "\n\n" + ZodiacCatalog.skill_name(id)
			for mood in ["PLEASED", "NORMAL", "UNPLEASED"]:
				rules += "\n\n" + ZodiacCatalog.disposition_label(mood) + "\n" + ZodiacCatalog.rule_text(id, mood)
		else:
			rules += "\n\n" + words("This encounter is not available yet.", "Hiện chưa thể gặp Con Giáp này.")
		_add("zodiac", ZodiacCatalog.display_name(id), rules)
	_add("drinks", words("Ordering & progression", "Gọi nước & Tiến trình"), words("One active Drink. Select a glass to inspect it, then Order to buy. The Starter choice serves Morning/Noon; Noon choice serves Afternoon/Evening. New drink tiers open through the campaign; late upgrades depend on the morning choice. Demo availability and unlock goals are shown on its glasses. Charges follow each Drink's own turn/phase/deal rule.", "Một đồ uống đang dùng. Chọn ly để xem, rồi GỌI MÓN để mua. Ly đầu ngày dùng sáng/trưa; ly buổi trưa dùng chiều/tối. Các tầng đồ uống mở theo hành trình; nâng cấp muộn phụ thuộc ly buổi sáng. Bản demo hiển thị điều kiện mở trên ly. Lượt dùng theo quy tắc lượt/giai đoạn/ván của từng ly."))
	_add("gieo", words("One signed Fortune", "Một chỉ số Vận"), words("Fortune belongs to a physical card: -6 to +6. Positive Fortune is Gold: +1 counts the card value once, +2 twice, up to +6 six times whenever scored. Gold Deadwood uses normal value. Negative Fortune is Black Ink: Meld scoring stays normal; Deadwood pays its value × the magnitude as profit. Crossing zero changes the side.\n\nActual rank and suit stay unchanged by Gieo. Expanded decks and duplicates retain distinct physical IDs.", "Vận thuộc về một lá bài thật: -6 đến +6. Vận dương là Vàng: +1 tính giá trị một lần, +2 hai lần, đến +6 sáu lần mỗi khi tính điểm. Bài Vàng còn rời tính phạt bình thường. Vận âm là Mực Đen: hạ Phỏm tính điểm thường; còn rời thì sinh lời bằng giá trị × độ lớn của Vận. Qua 0 thì đổi phía.\n\nGieo không đổi số và chất thật. Bộ bài mở rộng và lá trùng vẫn có định danh riêng."))
	_add("gieo", words("Reading the two trigrams", "Đọc hai quái"), words("P = Dương, one solid line. N = Âm, two broken halves. Read from top to bottom. The first trigram shifts Fortune; the second selects physical cards by actual rank/suit. Mixed target: one random card. PPP target: three consecutive ranks. NNN target: three cards of the same suit. Targets remain hidden until Accept.\n\nPull the slot machine lever to spin all six lines. Tap or Space during the roll to quicken it. Accept commits the reading; Reroll pays the next price; Refuse gives no refund. Finish an accepted reading before leaving.", "P = Dương, hào liền. N = Âm, hào đứt. Đọc từ trên xuống. Quái đầu đổi Vận; quái sau chọn lá bài theo số/chất thật. Quái hỗn hợp: một lá ngẫu nhiên. PPP: ba số liên tiếp. NNN: ba lá cùng chất. Chưa nhận quẻ thì mục tiêu vẫn ẩn.\n\nKéo cần máy quay để gieo sáu hào. Chạm hoặc Space trong lúc quay để đọc nhanh. Nhận chốt quẻ; Gieo lại trả giá tiếp theo; Từ chối không hoàn tiền. Đã nhận phải hoàn tất trước khi rời."))
	for trigram: String in GieoQueService.FIRST_TRIGRAM_FORTUNE:
		var delta: int = GieoQueService.FIRST_TRIGRAM_FORTUNE[trigram]
		var target: String = GieoQueService.SECOND_TRIGRAM_TARGETS[trigram]
		var lines: Array[String] = []
		for symbol in trigram: lines.append("━━━━━━" if symbol == "P" else "━━  ━━")
		_add("gieo", trigram+" · "+tr("CARD_FORTUNE")+" %+d" % delta, "\n".join(lines)+"\n\n"+words("FIRST → Fortune ","QUÁI ĐẦU → Vận ")+"%+d" % delta+"\n\n"+words("SECOND → ","QUÁI SAU → ")+tr(GieoQueService.TARGET_LABEL_KEYS[target]))
	for property: String in ["GOLD", "BLACK_INK", "LIQUID", "NEGATIVE", "GLITCH"]:
		var key := CardData.property_label_key(property)
		_add("gieo", tr(key), tr(key+"_DESC"))
	_add("gieo", "THUẦN DƯƠNG / THUẦN ÂM", words("PPP | PPP: choose exactly one physical card. +3 Fortune and permanent Liquid (+1 Echo).\nNNN | NNN: choose exactly one physical card. -3 Fortune and permanent Negative (rank ±1, either suit of its color).\n\nLiquid + Negative on the same card becomes Glitch: any rank, any suit, +1 Echo. Fortune remains independent.\n\nOne free reading per day. Paid readings use max(10.000 VNĐ, 4% of today's debt), rounded up to 500 VNĐ; each paid reading doubles the next price. Refusing does not restore a free reading.", "PPP | PPP: chọn đúng một lá thật. +3 Vận và Lưu Quang vĩnh viễn (+1 Dư âm).\nNNN | NNN: chọn đúng một lá thật. -3 Vận và Âm Bản vĩnh viễn (số ±1, hai chất cùng màu).\n\nLưu Quang + Âm Bản trên cùng lá thành Glitch: mọi số, mọi chất, +1 Dư âm. Vận vẫn độc lập.\n\nMỗi ngày một quẻ miễn phí. Quẻ trả phí dùng max(10.000 VNĐ, 4% nợ ngày), làm tròn lên 500 VNĐ; mỗi quẻ trả phí nhân đôi giá tiếp. Từ chối không hoàn lượt miễn phí."))
	_add("relics", words("Hàng Rong · Deckbuilding", "Hàng Rong · Xây bộ bài"), words("Pick an object on the table to hear Auntie's explanation. BUY confirms that exact item. Sold stock stays sold for the visit, including after saving and quitting. Every owned relic is active, with no equipment cap. Ordinary cards add a distinct physical card permanently; matching ranks and suits are legal, including Sets larger than four.\n\nRemoval: PAY, choose one owned card, then confirm permanent removal. Every property disappears with that card; nothing is transferred or refunded. A paid selection survives closing and saving, and must finish before leaving the event.\n\nPrices use today's debt: relics %d%%, cards %d%%, first removal %d%%. Removal grows ×%s for each completed removal across the run. Prices round up to 500 VND, minimum 500 VND. Normal refills need at least %d cards.", "Chọn món trên bàn để nghe cô giải thích. MUA xác nhận đúng món đó. Hàng đã bán không bày lại trong cùng chuyến, kể cả sau lưu và thoát. Mọi bảo vật đang sở hữu luôn có hiệu lực, không giới hạn số món. Bài bình thường thêm vĩnh viễn một lá thật riêng; được trùng hạng và chất, kể cả Set hơn bốn lá.\n\nBỏ bài: TRẢ TIỀN, chọn một lá đang sở hữu rồi xác nhận bỏ vĩnh viễn. Mọi thuộc tính mất cùng lá đó; không chuyển hay hoàn lại. Lựa chọn đã trả tiền giữ qua đóng và lưu; phải bỏ xong trước khi rời sự kiện.\n\nGiá theo nợ hôm nay: bảo vật %d%%, bài %d%%, lần bỏ đầu %d%%. Giá bỏ bài tăng ×%s theo mỗi lần bỏ xong trong lượt chơi. Làm tròn lên 500 VNĐ, tối thiểu 500 VNĐ. Cần ít nhất %d lá để bốc đủ trong ván.") % [int(RelicShop.PRICE_RULES.relic_percent), int(RelicShop.PRICE_RULES.card_percent), int(RelicShop.PRICE_RULES.removal_percent), str(RelicShop.PRICE_RULES.removal_growth), DealState.MIN_CAMPAIGN_CARDS])
	for id: String in RelicCatalog.DEFINITIONS:
		_add("relics", String(RelicCatalog.DEFINITIONS[id].name), RelicCatalog.effect(id) + "\n\n" + words("Every owned relic is always active, with no equipment limit. Inspect its icon on the right during a Deal or its object on the event table. A triggered relic boosts VNĐ per point for that committed action, including retrigger points. The boost is paid separately and ends after the action.", "Mọi bảo vật đang sở hữu luôn có hiệu lực, không giới hạn số món. Xem biểu tượng bên phải khi chơi hoặc vật trên bàn sự kiện. Bảo vật kích hoạt tăng VNĐ/PTS cho hành động đã chốt, gồm cả điểm kích hoạt lại. Tiền thưởng được trả riêng và mức tăng kết thúc sau hành động."))
		_entries[-1]["relic_id"] = id
	for npc in [["Đòi Nợ", "Starter debt briefing; evening collection.", "Báo nợ đầu ngày; thu nợ sau ván tối."], ["Cô Trà Đá", "Starter and Noon: inspect and order one Drink.", "Đầu ngày và trưa: xem rồi gọi một ly."], ["Thầy Bói", "Morning, Noon, Afternoon: persistent Gieo transformations.", "Sáng, trưa, chiều: Gieo biến đổi bài vĩnh viễn."], ["Hàng Rong", "Morning and Afternoon: buy individual relics and ordinary playing cards, or pay to remove an exact owned card. Stock stays sold for this visit. Relics activate immediately without a cap. Removal costs rise with completed removals across the run; every property disappears with the removed card.", "Sáng và chiều: mua riêng từng bảo vật và lá bài bình thường, hoặc trả tiền bỏ đúng một lá đang sở hữu. Hàng đã bán không bày lại trong cùng chuyến. Bảo vật có hiệu lực ngay, không giới hạn số món. Giá bỏ bài tăng theo số lần bỏ xong trong lượt chơi; mọi thuộc tính mất cùng lá bị bỏ."], ["Đánh Giày", "Starter, from Tuesday onward: commit exactly two physical cards before transforming. Each chosen slot stays locked through reopening and resume. Each purchase transforms BOTH cards, with an independent Rank or Suit result for each. Every result excludes that card's current identity. Properties stay attached. Rank starts at 10% of the day's debt target (minimum 25.000 VNĐ); Suit at 5% (minimum 15.000 VNĐ), rounded up to 500 VNĐ. Both cards share each service's price, which doubles separately after use. Prices never depend on wallet balance. No reroll limit.", "Đầu ngày, từ thứ Ba trở đi: chốt đủ hai lá thật trước khi đổi. Mỗi lá đã chốt được giữ khi mở lại hay tiếp tục bản lưu. Mỗi lượt trả tiền đổi CẢ HAI lá, mỗi lá có kết quả số/chất riêng. Kết quả luôn khác số/chất hiện tại của lá đó. Thuộc tính đi cùng lá. Đổi số bắt đầu từ 10% mục tiêu nợ ngày (tối thiểu 25.000 VNĐ); chất từ 5% (tối thiểu 15.000 VNĐ), làm tròn lên 500 VNĐ. Hai lá dùng chung giá từng dịch vụ; mỗi dịch vụ tăng gấp đôi riêng sau lượt đổi. Giá không phụ thuộc ví. Không giới hạn lượt."], ["Vé Số", "Morning: buy tickets. Afternoon: reveal results before the Evening Deal.", "Sáng: mua vé. Chiều: dò kết quả trước ván tối."]]:
		_add("npcs", npc[0], words(npc[1], npc[2]))
	var prizes: Array[String] = []
	for prize in MiscServiceConfig.PRIZES:
		prizes.append(tr(prize.label) + " · " + str(prize.count) + " · " + prize.multiplier)
	_add("lottery", words("Tickets & results", "Vé & Kết quả"), words("Tickets use numbers 00–99. Base stake: 1% of your current wallet, minimum 10.000 VNĐ, rounded up to 500 VNĐ. Daily ticket prices scale 1×, 2×, 3×…; winnings use the actual paid stake. Buy All purchases the affordable unowned offers in display order; quantity and total appear on the button. No borrowing. Results close purchasing for the day; settlement cannot pay twice.\n\n", "Vé có số 00–99. Giá gốc: 1% ví hiện tại, tối thiểu 10.000 VNĐ, làm tròn lên 500 VNĐ. Vé trong ngày tăng giá 1×, 2×, 3×…; thưởng tính trên giá vé thực trả. Mua tất cả lấy các vé chưa mua đủ tiền theo thứ tự hiển thị; nút ghi số lượng và tổng giá. Không vay tiền. Dò số đóng mua trong ngày; không trả thưởng hai lần.\n\n") + "\n".join(prizes))
	_add("controls", words("Hands, highlights & keys", "Tay bài, viền & Phím"), words("Click to select cards or drag them to a valid Meld or discard target. Green outlines mark new Melds, orange marks Extensions, and blue marks Drink targets. Select a table Meld before extending it.\n\nH: Meld · E: Extend · D: Discard · C: Settle · S: Sort · G: Hint · Esc: Clear or Back.\n\nTo use a Drink, select its cup and an eligible target. You can read the Handbook at any time without making a move.", "Bấm chọn bài hoặc kéo vào đích Phỏm hay bỏ bài hợp lệ. Viền xanh lá chỉ Phỏm mới, cam chỉ Nối Phỏm, xanh dương chỉ mục tiêu Nước. Chọn Phỏm trên bàn trước khi nối.\n\nH: Hạ · E: Ghép · D: Bỏ · C: Chốt · S: Xếp · G: Gợi ý · Esc: Bỏ chọn hoặc Quay lại.\n\nDùng Nước bằng cách chọn ly và mục tiêu phù hợp. Bạn có thể đọc Sổ tay bất cứ lúc nào mà không thực hiện nước đi."))
