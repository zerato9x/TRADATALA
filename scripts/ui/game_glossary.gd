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

func _ready() -> void:
	layer = 280
	var shade := ColorRect.new()
	shade.color = Color("101e30f5")
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(shade)
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 28)
	margin.theme = PresentationTheme.create_game_theme()
	add_child(margin)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 14)
	margin.add_child(box)
	var header := HBoxContainer.new()
	box.add_child(header)
	var title := Label.new()
	title.text = words("THE TABLE HANDBOOK", "SỔ TAY BÀN TRÀ")
	title.add_theme_font_size_override("font_size", 28)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title)
	var close := Button.new()
	close.name = "CloseHandbook"
	close.text = words("BACK TO TABLE", "VỀ BÀN")
	close.pressed.connect(queue_free)
	header.add_child(close)
	_search = LineEdit.new()
	_search.placeholder_text = words("Search rules, cards, NPCs…", "Tìm luật, bài, nhân vật…")
	_search.text_changed.connect(func(_text): _refresh())
	box.add_child(_search)
	var tabs := HFlowContainer.new()
	box.add_child(tabs)
	for spec in [["all", "ALL", "TẤT CẢ"], ["core", "PLAY", "CHƠI"], ["scoring", "SCORING", "ĐIỂM"], ["campaign", "CAMPAIGN / ECONOMY", "HÀNH TRÌNH / TIỀN"], ["cards", "CARDS", "BÀI"], ["drinks", "DRINKS", "ĐỒ UỐNG"], ["gieo", "GIEO QUẺ", "GIEO QUẺ"], ["relics", "RELICS", "DI VẬT"], ["npcs", "NPCs", "NHÂN VẬT"], ["lottery", "LOTTERY", "VÉ SỐ"], ["controls", "CONTROLS", "THAO TÁC"]]:
		var button := Button.new()
		button.text = words(spec[1], spec[2])
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

func _input(event: InputEvent) -> void:
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
		_body.append_text("\n\n")
		var examples: Array[String] = ["four_of_clubs", "five_of_clubs", "six_of_clubs"] if entry.section == "gieo" else ["nine_of_spades", "nine_of_hearts", "nine_of_diamonds"]
		for example in examples:
			_body.add_image(load("res://cards/" + example + ".png"), 88, 124)
			_body.append_text("   ")
	if entry.has("relic_id"):
		_body.append_text("\n\n")
		_body.add_image(load(RelicCatalog.icon_path(entry.relic_id)), 160, 160)
	_body.scroll_to_line(0)

func _build_entries() -> void:
	for topic in ["RUN", "EXTEND", "DISCARD", "TURN", "PHASE_END", "PHASE_CHOICE"]:
		_add("core", tr("HOW_" + topic + "_TITLE"), tr("HOW_" + topic + "_BODY"))
	_add("core", "SET / BỘ", words("Three or more physical cards of the same rank. Persistent transformations can create Sets larger than four.\n\n9♠  9♥  9♦ → HẠ\nAdd 9♣ → EXTEND.", "Ít nhất ba lá thật cùng số. Biến đổi vĩnh viễn có thể tạo Bộ lớn hơn bốn lá.\n\n9♠  9♥  9♦ → HẠ\nThêm 9♣ → GHÉP."))
	_add("core", "HẠ / PHỎM", tr("HOW_INTRO") + "\n\n" + tr("HOW_SCORE_MELD_BODY"))
	_add("core", words("PHASE / LAST CALL / KEEP / DUMP", "GIAI ĐOẠN / CHỐT HẠ / GIỮ / ĐỔI"), tr("HOW_PHASES_INTRO") + "\n\n" + tr("HOW_PHASE_END_BODY") + "\n\n" + tr("HOW_PHASE_CHOICE_BODY"))
	for topic in ["SCORE_MELD", "SCORE_EXTEND", "SCORE_PHASE", "MOM", "U", "U_KHAN"]:
		_add("scoring", tr("HOW_" + topic + "_TITLE"), tr("HOW_" + topic + "_BODY"))
	_add("scoring", words("Milestones & Exhaustion", "Mốc Phỏm & Cạn bài"), words("Extend pays its delta first. A Set reaching 4, 8, 12… cards or a perfected 13-card A–K Run then triggers one full-meld pass. SET extensions between milestones pay only the delta; Liquid full-meld echoes wait for a milestone. Echoes never recurse.\n\nWhen the draw pile is empty, the normal Exhaustion system scores/recycles eligible meld cards. Its ceremony reports committed earnings; it does not pay again.", "Ghép trả phần chênh lệch trước. Bộ đạt 4, 8, 12… lá hoặc Sảnh hoàn hảo 13 lá A–K kích hoạt thêm một lượt đủ Phỏm. Ghép Bộ giữa các mốc chỉ trả chênh lệch; Lưu Quang cả Phỏm phải chờ mốc. Không đệ quy.\n\nKhi chồng rút cạn, hệ thống Cạn bài tính điểm và tái chế bài Phỏm hợp lệ. Nghi thức hiển thị tiền đã ghi nhận, không trả lần nữa."))
	_add("campaign", words("Daily debt & wallet", "Nợ ngày & Ví"), words("Starter → Morning Deal → Morning Event → Noon Deal → Noon Event → Afternoon Deal → Afternoon results → Evening Deal → Pay debt.\n\nĐòi Nợ introduces the day's debt in the morning and returns after the Evening Deal. Pay explicitly; insufficient funds end the run. The ledger shows the weekly targets.\n\nDrinks, relics and Gieo use today's debt target. Shoe polish, tips and lottery tickets use your current wallet and daily repeat counts. Payments and rewards travel to/from the same top money pile.", "Đầu ngày → Ván sáng → Sự kiện sáng → Ván trưa → Sự kiện trưa → Ván chiều → Dò vé số → Ván tối → Trả nợ.\n\nĐòi Nợ báo nợ vào sáng và trở lại sau ván tối. Chủ động trả; thiếu tiền kết thúc lượt chơi. Sổ nợ ghi mục tiêu cả tuần.\n\nĐồ uống, di vật và Gieo tính theo nợ ngày. Đánh bóng, boa và vé số tính theo ví hiện tại và số lần mua trong ngày. Tiền đi và về cùng chồng tiền phía trên."))
	_add("campaign", words("Difficulty & Endless", "Độ khó & Vô tận"), words("Choose a difficulty before a new run. Difficulty 1 uses the original weekly debts; each next difficulty doubles every daily debt. Paying Sunday unlocks the next difficulty permanently, even if you choose Endless. You can exit to the menu to start that difficulty, or keep this run's cards, relics and wallet in Endless. Endless debt grows 50% per day. Resuming keeps the saved run's difficulty.", "Chọn độ khó trước ván mới. Độ khó 1 dùng mức nợ gốc; mỗi mức kế tiếp nhân đôi nợ từng ngày. Trả nợ Chủ nhật mở vĩnh viễn độ khó tiếp theo, kể cả khi chọn Vô tận. Về menu để bắt đầu độ khó mới, hoặc giữ bài, di vật và ví của lượt này trong Vô tận. Nợ Vô tận tăng 50% mỗi ngày. Tiếp tục bản lưu giữ nguyên độ khó đã chọn."))
	_add("cards", words("Physical cards & persistence", "Lá bài thật & Biến đổi"), words("52 physical identities persist through the campaign. Gieo changes rank, suit or properties on those identities. Deals copy them; temporary deal modifiers do not rewrite the campaign deck. A=1, J=11, Q=12, K=13. Gold and Liquid change scoring, never card identity. Shoe polish lasts only for the current day.", "52 định danh bài thật đi suốt hành trình. Gieo đổi số, chất hoặc thuộc tính trên chính những lá đó. Mỗi ván dùng bản sao; hiệu ứng tạm không sửa bộ bài gốc. A=1, J=11, Q=12, K=13. Vàng và Lưu Quang đổi điểm, không đổi định danh. Đánh bóng chỉ kéo dài trong ngày."))
	for id: String in DrinkCatalog.DEFINITIONS:
		_add("drinks", DrinkCatalog.display_name(id), DrinkCatalog.effect_text(id))
	_add("drinks", words("Ordering & progression", "Gọi nước & Tiến trình"), words("One active Drink. Select a glass to inspect it, then Order to buy. The Starter choice serves Morning/Noon; Noon choice serves Afternoon/Evening. New drink tiers open through the campaign; late upgrades depend on the morning choice. Demo availability and unlock goals are shown on its glasses. Charges follow each Drink's own turn/phase/deal rule.", "Một đồ uống đang dùng. Chọn ly để xem, rồi GỌI MÓN để mua. Ly đầu ngày dùng sáng/trưa; ly buổi trưa dùng chiều/tối. Các tầng đồ uống mở theo hành trình; nâng cấp muộn phụ thuộc ly buổi sáng. Bản demo hiển thị điều kiện mở trên ly. Lượt dùng theo quy tắc lượt/giai đoạn/ván của từng ly."))
	_add("gieo", words("Reading six lines", "Đọc sáu hào"), words("D = Dương (solid ━━━); A = Âm (broken ━ ━). Read the first three lines for EFFECT, the second three for TARGET. Pull the lever, inspect both trigrams, then Accept, Reroll (paying the next cast price), or Refuse (no refund).\n\nTargets stay hidden before commitment. Choose Rank/Suit happens before random targets are revealed. Once accepted, finish the choice and transformation before leaving.\n\nRandom Rank / Random Suit are not current effects. The current mappings below are generated from the live rule tables.", "D = Dương (liền ━━━); A = Âm (đứt ━ ━). Ba hào đầu là HIỆU ỨNG, ba hào sau là MỤC TIÊU. Kéo cần, đọc hai quái rồi Nhận, Gieo lại (trả giá lượt kế), hoặc Từ chối (không hoàn tiền).\n\nMục tiêu ẩn trước khi nhận. Chọn Số/Chất trước khi lộ mục tiêu ngẫu nhiên. Đã nhận phải chọn và biến đổi xong mới rời.\n\nĐổi Số/Chất Ngẫu nhiên không còn là hiệu ứng hiện tại. Bảng dưới lấy trực tiếp từ luật đang dùng."))
	for trigram: String in GieoQueService.FIRST_TRIGRAM_EFFECTS:
		var effect: String = GieoQueService.FIRST_TRIGRAM_EFFECTS[trigram]
		var target: String = GieoQueService.SECOND_TRIGRAM_TARGETS[trigram]
		var lines: Array[String] = []
		for symbol in trigram:
			lines.append("━━━━━━" if symbol == "D" else "━━  ━━")
		_add("gieo", trigram + " · " + tr(GieoQueService.EFFECT_LABEL_KEYS[effect]), "\n".join(lines) + "\n\n" + words("FIRST TRIGRAM → ", "QUÁI ĐẦU → ") + tr(GieoQueService.EFFECT_LABEL_KEYS[effect]) + "\n\n" + words("SECOND TRIGRAM → ", "QUÁI SAU → ") + tr(GieoQueService.TARGET_LABEL_KEYS[target]))
	for property: String in GieoQueService.GOLD_PROPERTIES + [GieoQueService.PROPERTY_MELD_RETRIGGER]:
		var key := CardData.gieo_property_label_key(property)
		_add("gieo", tr(key), tr(key + "_DESC"))
	_add("gieo", "THUẦN DƯƠNG / THUẦN ÂM", words("DDDDDD: choose a rank, then exactly one physical card; change its rank and add Liquid.\nAAAAAA: choose a suit, then exactly one physical card; change its suit and add Liquid.\n\nOne free cast daily. Paid casts start at max(10.000 VNĐ. 4% of today's debt), rounded up to 500 VNĐ; each paid cast doubles the next price. Refusing does not restore the free cast.\n\nExample: a 4–5–6 Run scores 45. RUN GOLD on the 5 adds 5 to the sum before multiplying: 60. A Liquid card adds another full qualifying meld pass, without recursively triggering itself.", "DDDDDD: chọn số rồi chọn đúng một lá thật; đổi số và thêm Lưu Quang.\nAAAAAA: chọn chất rồi chọn đúng một lá thật; đổi chất và thêm Lưu Quang.\n\nMột lượt miễn phí mỗi ngày. Lượt trả tiền từ max(10.000 VNĐ. 4% nợ ngày), làm tròn lên 500 VNĐ; mỗi lượt trả tiền nhân đôi giá kế tiếp. Từ chối không hoàn lượt miễn phí.\n\nVí dụ: Sảnh 4–5–6 được 45 điểm. Vàng Sảnh trên lá 5 cộng 5 vào tổng trước khi nhân: 60. Lá Lưu Quang thêm một lượt đủ Phỏm hợp lệ, không tự kích hoạt đệ quy."))
	for id: String in RelicCatalog.DEFINITIONS:
		_add("relics", String(RelicCatalog.DEFINITIONS[id].name), RelicCatalog.effect(id) + "\n\n" + words("Equip in one of four slots. Bonuses resolve once after a committed normal action, separately from intrinsic scoring and retrigger passes. Purchased relics remain in your inventory; equipping is free.", "Trang bị vào một trong bốn ô. Thưởng áp dụng một lần sau hành động thường đã chốt, riêng với điểm gốc và lượt kích hoạt lại. Mua xong giữ trong bộ sưu tập; trang bị miễn phí."))
		_entries[-1]["relic_id"] = id
	for npc in [["Đòi Nợ", "Starter debt briefing; evening collection.", "Báo nợ đầu ngày; thu nợ sau ván tối."], ["Cô Trà Đá", "Starter and Noon: inspect and order one Drink.", "Đầu ngày và trưa: xem rồi gọi một ly."], ["Thầy Bói", "Morning, Noon, Afternoon: persistent Gieo transformations.", "Sáng, trưa, chiều: Gieo biến đổi bài vĩnh viễn."], ["Hàng Rong", "Morning and Afternoon: one relic purchase per visit; four equipped slots.", "Sáng và chiều: mua một món mỗi lần ghé; bốn ô trang bị."], ["Đánh Giày", "Starter: polish two random unpolished cards for today. Base price: 2% of your current wallet, minimum 10.000 VNĐ; tips: 1%, minimum 5.000 VNĐ. Each service scales 1×, 2×, 3×… per day, rounded up to 500 VNĐ. Tips build favor toward the Special-number hint.", "Đầu ngày: đánh bóng hai lá ngẫu nhiên chưa bóng trong ngày. Giá gốc: 2% ví hiện tại, tối thiểu 10.000 VNĐ; boa: 1%, tối thiểu 5.000 VNĐ. Mỗi dịch vụ tăng 1×, 2×, 3×… trong ngày, làm tròn lên 500 VNĐ. Boa tích lũy thiện cảm để hỏi số Đặc biệt."], ["Vé Số", "Morning: buy tickets. Afternoon: reveal results before the Evening Deal.", "Sáng: mua vé. Chiều: dò kết quả trước ván tối."]]:
		_add("npcs", npc[0], words(npc[1], npc[2]))
	var prizes: Array[String] = []
	for prize in MiscServiceConfig.PRIZES:
		prizes.append(tr(prize.label) + " · " + str(prize.count) + " · " + prize.multiplier)
	_add("lottery", words("Tickets, hints & results", "Vé, gợi ý & Kết quả"), words("Tickets use numbers 00–99. Base stake: 1% of your current wallet, minimum 10.000 VNĐ, rounded up to 500 VNĐ. Daily ticket prices scale 1×, 2×, 3×…; winnings use the actual paid stake. Buy All purchases the affordable unowned offers in display order; quantity and total appear on the button. No borrowing. Results close purchasing for the day; settlement cannot pay twice. A shoe-shine favor can reveal the Special number.\n\n", "Vé có số 00–99. Giá gốc: 1% ví hiện tại, tối thiểu 10.000 VNĐ, làm tròn lên 500 VNĐ. Vé trong ngày tăng giá 1×, 2×, 3×…; thưởng tính trên giá vé thực trả. Mua tất cả lấy các vé chưa mua đủ tiền theo thứ tự hiển thị; nút ghi số lượng và tổng giá. Không vay tiền. Dò số đóng mua trong ngày; không trả thưởng hai lần. Thiện cảm đánh giày có thể cho biết số Đặc biệt.\n\n") + "\n".join(prizes))
	_add("controls", words("Hands, highlights & keys", "Tay bài, viền & Phím"), words("Click to select cards; drag to valid table/discard targets. Green outlines: new meld. Orange: extension. Blue: Drink target. Click a meld to choose its extension target.\nH: HẠ · E: Extend · D: Discard · C: Settle · S: Sort · G: Suggest · Esc: Clear/Back.\nUse the charged Drink button then its real target. The glossary never changes your deal or gates an action.", "Bấm chọn bài; kéo vào vùng Hạ/Ghép/Bỏ hợp lệ. Viền xanh lá: Phỏm mới. Cam: Ghép. Xanh dương: mục tiêu đồ uống. Bấm Phỏm để chọn đích Ghép.\nH: Hạ · E: Ghép · D: Bỏ · C: Chốt · S: Xếp · G: Gợi ý · Esc: Bỏ chọn/Quay lại.\nBấm ly còn lượt rồi chọn mục tiêu thật. Sổ tay không đổi ván hoặc khóa hành động."))
