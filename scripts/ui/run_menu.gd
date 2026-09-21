extends Control
signal new_run(seed_text: String)
signal resume_run()
signal dismissed()
var seed_field: LineEdit
var resume_button: Button
var start_button: Button
var difficulty_selector: OptionButton
var music_choice: OptionButton
var selected_difficulty := 1
var selected_music := ""

func words(en: String, vi: String) -> String:
	return vi if TranslationServer.get_locale().begins_with("vi") else en

func configure(progress: DrinkProgress, saved: Dictionary, message: String = "", unlocked: int = 1) -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	theme = PresentationTheme.create_game_theme()
	var shade := ColorRect.new()
	shade.color = Color("122747fc")
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(shade)
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side in ["left", "right"]:
		margin.add_theme_constant_override("margin_" + side, 64)
	for side in ["top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 26)
	add_child(margin)
	var body := VBoxContainer.new()
	body.add_theme_constant_override("separation", 14)
	margin.add_child(body)
	body.add_child(_label(words("A WEEK AT THE TABLE", "MỘT TUẦN BÊN BÀN BÀI"), 30))
	body.add_child(_label(words("Pay Sunday to unlock the next difficulty. Each level doubles every debt. Then choose Endless or exit.", "Trả nợ Chủ nhật để mở độ khó tiếp theo. Mỗi mức nhân đôi mọi khoản nợ. Sau đó chọn Vô tận hoặc thoát."), 18))
	difficulty_selector = OptionButton.new()
	difficulty_selector.name = "Difficulty"
	for level in range(1, mini(unlocked + 1, 28) + 1):
		var days := CampaignConfig.day_definitions(level)
		difficulty_selector.add_item(words("DIFFICULTY %d · Sunday %s", "ĐỘ KHÓ %d · Chủ nhật %s") % [level, VndWallet.format_amount(days[-1].required_vnd) + " VNĐ"])
		difficulty_selector.set_item_disabled(level - 1, level > unlocked)
		if level > unlocked: difficulty_selector.set_item_text(level - 1, difficulty_selector.get_item_text(level - 1) + words(" · LOCKED", " · CHƯA MỞ"))
	difficulty_selector.item_selected.connect(func(index: int): selected_difficulty = index + 1)
	body.add_child(difficulty_selector)
	body.add_child(_label(words("CHOOSE YOUR MUSIC · You can change this later in Options.", "CHỌN NHẠC · Có thể đổi lại trong Tùy chọn."), 18))
	music_choice = OptionButton.new()
	music_choice.name = "MusicChoice"
	music_choice.add_item(words("Choose before starting…", "Chọn trước khi chơi…"))
	music_choice.set_item_disabled(0, true)
	music_choice.add_item(words("PLAYLIST · Individual tracks", "DANH SÁCH · Từng bản nhạc"))
	music_choice.add_item(words("AUTHORED DJ SETS · Continuous curated mixes", "DJ SET BIÊN SOẠN · Bản phối liên tục"))
	music_choice.select(0)
	music_choice.item_selected.connect(func(index: int):
		selected_music = "playing_tracks" if index == 1 else "authored_dj"
		start_button.disabled = false
		resume_button.disabled = saved.is_empty())
	body.add_child(music_choice)
	var actions := HBoxContainer.new()
	actions.add_theme_constant_override("separation", 14)
	body.add_child(actions)
	resume_button = Button.new()
	resume_button.text = words("CONTINUE SAVED RUN", "TIẾP TỤC VÁN ĐÃ LƯU")
	resume_button.disabled = true
	resume_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	resume_button.custom_minimum_size.y = 48
	PresentationTheme.configure_button(resume_button, "tea")
	resume_button.pressed.connect(func(): resume_run.emit())
	actions.add_child(resume_button)
	var saved_info := words("No saved run yet.", "Chưa có ván đã lưu.")
	if not saved.is_empty():
		var c: Dictionary = saved.campaign
		saved_info = words("Difficulty %d · Day %d · Seed %s · ", "Độ khó %d · Ngày %d · Hạt giống %s · ") % [int(c.get("difficulty", 1)), int(c.current_day_index) + 1, c.run_seed] + VndWallet.format_vnd(int(saved.deal.wallet_balance_vnd))
	body.add_child(_label(saved_info + ("\n" + message if not message.is_empty() else ""), 16))
	var seed_row := HBoxContainer.new()
	seed_row.add_theme_constant_override("separation", 14)
	body.add_child(seed_row)
	seed_field = LineEdit.new()
	seed_field.name = "Seed"
	seed_field.max_length = 64
	seed_field.placeholder_text = words("Seed · leave blank for a new random run", "Hạt giống · bỏ trống để tạo ngẫu nhiên")
	seed_field.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	seed_field.add_theme_font_size_override("font_size", 16)
	seed_row.add_child(seed_field)
	start_button = Button.new()
	start_button.disabled = true
	start_button.text = words("NEW RUN", "VÁN MỚI")
	start_button.custom_minimum_size = Vector2(220, 44)
	PresentationTheme.configure_button(start_button, "gold")
	start_button.pressed.connect(func(): new_run.emit(seed_field.text))
	seed_row.add_child(start_button)
	body.add_child(_label(words("New Run replaces the current run save. Drink and difficulty unlocks are kept. Autosaves follow every committed action.", "Ván mới thay bản lưu hiện tại. Mở khóa đồ uống và độ khó được giữ lại. Tự lưu sau mỗi hành động hoàn tất."), 14))
	body.add_child(_label(words("DRINK COLLECTION · PRICE AS % OF TODAY’S DEBT", "BỘ SƯU TẬP · GIÁ THEO % NỢ HÔM NAY"), 22))
	body.add_child(_label(words("Day 1: iced tea → basics. Day 2: basics → tier 2. Day 3+: Sting → Red Bull; C2 → sugarcane at noon.", "Ngày 1: Trà đá → cơ bản. Ngày 2: cơ bản → bậc 2. Từ ngày 3: Sting → Bò Húc; C2 → Nước mía vào trưa."), 15))
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	body.add_child(scroll)
	var collection := VBoxContainer.new()
	collection.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	collection.add_theme_constant_override("separation", 8)
	scroll.add_child(collection)
	for id in DrinkCatalog.all_ids():
		var row := HBoxContainer.new()
		collection.add_child(row)
		var label := _label(DrinkCatalog.display_name(id), 18)
		label.custom_minimum_size.x = 230
		row.add_child(label)
		var goal := _label(progress.goal_text(id), 15)
		goal.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		goal.modulate = PresentationTheme.TEA if progress.is_unlocked(id) else PresentationTheme.MUTED
		row.add_child(goal)
		var price_note := _label("%d%%" % int(DrinkManager.PRICE_PERCENT[id]), 16)
		price_note.autowrap_mode = TextServer.AUTOWRAP_OFF
		price_note.custom_minimum_size.x = 70
		price_note.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		row.add_child(price_note)
	var back := Button.new()
	back.text = words("BACK", "QUAY LẠI")
	back.custom_minimum_size.y = 38
	PresentationTheme.configure_button(back)
	back.pressed.connect(func(): dismissed.emit())
	body.add_child(back)

func _label(text: String, size: int) -> Label:
	var label := Label.new()
	label.text = text
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", PresentationTheme.INK)
	return label
