class_name FrontEnd
extends Control

signal start_requested(draft: RunSetupDraft)
signal resume_requested()
signal return_requested()
signal handbook_requested()

const BG := Color("#101f37")
const CARD := Color("#203656")
const GOLD := Color("#f5bf42")
const CREAM := Color("#f8edcf")
const MUTED := Color("#c6b896")

var host: MatchUI
var draft: RunSetupDraft
var saved: Dictionary = {}
var save_message := ""
var transient_error := ""
var page := "home"
var active_page := ""
var collection_tab := "drinks"
var selected_collection := ""
var busy := false
var confirming := false
var customizing := false
var pages: Dictionary = {}
var logo_words: Array[Label] = []
var pulse_values := [0.0, 0.0, 0.0, 0.0]
var home_body: VBoxContainer
var setup_body: VBoxContainer
var collection_body: VBoxContainer
var footer: HBoxContainer
var title_label: Label
var music_page: VBoxContainer
var settings_page: VBoxContainer
var _previous_focus: Control

func words(en: String, vi: String) -> String:
	return vi if TranslationServer.get_locale().begins_with("vi") else en

func configure(owner: MatchUI) -> void:
	host = owner
	theme = PresentationTheme.create_game_theme()
	footer = $SafeArea/Frame/Footer
	title_label = $SafeArea/Frame/Header/PageTitle
	var logo: HBoxContainer = $SafeArea/Frame/Header/Logo
	logo.custom_minimum_size.x = 410
	for word in ["TRA", "DA", "TA", "LA"]:
		var label := _label(word, 38, GOLD)
		label.autowrap_mode = TextServer.AUTOWRAP_OFF
		label.custom_minimum_size.x = 96
		logo.add_child(label)
		logo_words.append(label)
	var stage: Control = $SafeArea/Frame/Main
	for id in ["home", "setup", "collections", "music", "settings"]:
		var panel := MarginContainer.new()
		panel.name = id.capitalize()
		panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		stage.add_child(panel)
		var scroll := ScrollContainer.new()
		scroll.name = "Scroll"
		scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
		scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
		panel.add_child(scroll)
		var body := VBoxContainer.new()
		body.name = "Body"
		body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		body.add_theme_constant_override("separation", 14)
		scroll.add_child(body)
		pages[id] = panel
		match id:
			"home": home_body = body
			"setup": setup_body = body
			"collections": collection_body = body
			"music": music_page = body
			"settings": settings_page = body
	# Keep the existing, wired jukebox and settings controls in the new navigation.
	host.music_player_panel.reparent(music_page)
	host.music_player_panel.custom_minimum_size = Vector2.ZERO
	_render_settings()
	host.menu_layer.get_node("MenuCenter").hide()
	host.return_to_game_button.hide()
	host.music_controller.band_pulse.connect(_on_beat)
	host.settings.locale_changed.connect(func(_locale: String): _render_settings.call_deferred(); refresh.call_deferred())
	get_viewport().size_changed.connect(_on_size_changed)
	_on_size_changed()
	show_home()

func _on_size_changed() -> void:
	var margin := 16 if size.x < 900 else 30
	for side in ["left", "right"]:
		$SafeArea.add_theme_constant_override("margin_" + side, margin)

func _on_beat(band: int, strength: float) -> void:
	if band >= 0 and band < 4:
		pulse_values[band] = maxf(pulse_values[band], strength)

func _process(delta: float) -> void:
	for index in 4:
		pulse_values[index] = move_toward(pulse_values[index], 0.0, delta * 3.5)
		logo_words[index].scale = Vector2.ONE * (1.0 + pulse_values[index] * 0.08)

func refresh() -> void:
	match page:
		"home": show_home()
		"setup": _render_setup()
		"collections": _render_collections()
		_: _show_page(page)

func show_home() -> void:
	page = "home"
	confirming = false
	customizing = false
	busy = false
	saved = host.run_save.load_run()
	save_message = words("Recovered the backup save.", "Đã khôi phục bản lưu dự phòng.") if host.run_save.recovered_backup else host.run_save.error
	if not transient_error.is_empty():
		save_message = transient_error
		transient_error = ""
	_clear(home_body)
	home_body.add_child(_label(words("THE TABLE IS READY", "BÀN BÀI ĐÃ SẴN SÀNG"), 30, CREAM))
	var cards := GridContainer.new()
	cards.columns = 1 if size.x < 860 else 2
	cards.add_theme_constant_override("h_separation", 18)
	cards.add_theme_constant_override("v_separation", 18)
	home_body.add_child(cards)
	var new_card := _card(cards)
	new_card.add_child(_label(words("NEW RUN", "VÁN MỚI"), 25, GOLD))
	new_card.add_child(_label(words("Choose your week's debt and take your seat.", "Chọn mức nợ trong tuần rồi vào bàn."), 17))
	new_card.add_child(_button(words("SET UP RUN", "CHUẨN BỊ VÁN"), show_setup, "gold"))
	var other := _card(cards)
	if host.game_started:
		other.add_child(_label(words("YOUR TABLE", "BÀN CỦA BẠN"), 25, GOLD))
		other.add_child(_label(words("Your current game is waiting.", "Ván đang chơi vẫn đang chờ."), 17))
		other.add_child(_button(words("BACK TO GAME", "TRỞ LẠI BÀN"), func(): return_requested.emit(), "tea"))
	elif not saved.is_empty():
		other.add_child(_label(words("CONTINUE", "TIẾP TỤC"), 25, GOLD))
		other.add_child(_label(_save_summary(), 17))
		other.add_child(_button(words("RESUME RUN", "TIẾP TỤC VÁN"), func(): resume_requested.emit(), "tea"))
	else:
		other.add_child(_label(words("FIRST VISIT", "LẦN ĐẦU ĐẾN BÀN"), 25, GOLD))
		other.add_child(_label(words("Start a new run or read the handbook.", "Bắt đầu ván mới hoặc xem sổ tay."), 17))
	if not save_message.is_empty(): home_body.add_child(_label(save_message, 15, GOLD))
	var nav := HFlowContainer.new()
	nav.add_theme_constant_override("h_separation", 12)
	nav.add_theme_constant_override("v_separation", 10)
	home_body.add_child(nav)
	nav.add_child(_button(words("COLLECTIONS", "BỘ SƯU TẬP"), show_collections))
	nav.add_child(_button(words("HANDBOOK", "SỔ TAY"), func(): handbook_requested.emit()))
	nav.add_child(_button(words("MUSIC", "ÂM NHẠC"), func(): _show_page("music")))
	nav.add_child(_button(words("SETTINGS", "TÙY CHỌN"), func(): _show_page("settings")))
	var now := host.music_track_title.text if host.music_track_title != null else ""
	home_body.add_child(_label(words("NOW PLAYING  ·  ", "ĐANG PHÁT  ·  ") + now, 15, MUTED))
	_show_page("home")
	var first := new_card.get_child(new_card.get_child_count() - 1) as Button
	if is_inside_tree(): first.grab_focus()

func _save_summary() -> String:
	if saved.is_empty(): return words("No saved run", "Chưa có ván đã lưu")
	var c: Dictionary = saved.get("campaign", {})
	var d: Dictionary = saved.get("deal", {})
	var day := int(c.get("current_day_index", 0)) + 1
	var status := words("Endless · Day %d", "Vô tận · Ngày %d") % day if bool(c.get("endless", false)) else words("Day %d of 7", "Ngày %d/7") % day
	return words("Difficulty %d  ·  %s\nWallet %s", "Độ khó %d  ·  %s\nVí %s") % [int(c.get("difficulty", 1)), status, VndWallet.format_vnd(int(d.get("wallet_balance_vnd", 0)))]

func show_error(message: String) -> void:
	transient_error = message
	show_home()

func show_setup() -> void:
	draft = RunSetupDraft.new()
	draft.difficulty = clampi(int(saved.get("campaign", {}).get("difficulty", 1)), 1, host.campaign.difficulty_progress.unlocked)
	draft.music_system = host.settings.music_system
	draft.emblem_id = String(host.campaign.zodiac.forced.get("pair:0", ""))
	confirming = false
	customizing = false
	_render_setup()

func _render_setup() -> void:
	page = "setup"
	_clear(setup_body)
	var columns := GridContainer.new()
	columns.columns = 1 if size.x < 900 else 2
	columns.add_theme_constant_override("h_separation", 18)
	columns.add_theme_constant_override("v_separation", 18)
	setup_body.add_child(columns)
	var challenge := _card(columns)
	challenge.add_child(_label(words("CHALLENGE", "THỬ THÁCH"), 21, GOLD))
	var stepper := HBoxContainer.new()
	challenge.add_child(stepper)
	var previous := _button("◀", func(): _change_difficulty(-1))
	previous.disabled = draft.difficulty <= 1
	stepper.add_child(previous)
	var level := _label("%02d" % draft.difficulty, 58, CREAM)
	level.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	level.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stepper.add_child(level)
	var next := _button("▶", func(): _change_difficulty(1))
	next.disabled = draft.difficulty >= host.campaign.difficulty_progress.unlocked
	stepper.add_child(next)
	challenge.add_child(_label(words("DIFFICULTY %d · UNLOCKED", "ĐỘ KHÓ %d · ĐÃ MỞ") % draft.difficulty, 16))
	challenge.add_child(_label(words("Starting wallet: ", "Ví ban đầu: ") + VndWallet.format_vnd(CampaignConfig.STARTING_WALLET_VND), 17, GOLD))
	challenge.add_child(_label(words("Earn enough to pay each day's debt. Clear Sunday to unlock the next difficulty.", "Kiếm đủ tiền trả nợ mỗi ngày. Trả xong Chủ nhật để mở độ khó tiếp theo."), 16))
	var unlocked: int = host.campaign.difficulty_progress.unlocked
	if unlocked < 28:
		var next_days := CampaignConfig.day_definitions(unlocked + 1)
		challenge.add_child(_label(words("NEXT LOCKED  ·  %d  ·  SUNDAY %s", "MỨC KẾ TIẾP  ·  %d  ·  CHỦ NHẬT %s") % [unlocked + 1, VndWallet.format_vnd(int(next_days[-1].required_vnd))], 15, MUTED))
	var week := _card(columns)
	week.add_child(_label(words("YOUR WEEK", "TUẦN CỦA BẠN"), 21, GOLD))
	var days := CampaignConfig.day_definitions(draft.difficulty)
	for i in days.size():
		var item: Dictionary = days[i]
		var row := HBoxContainer.new()
		week.add_child(row)
		var name := _label(tr(String(item.name_key)), 17, GOLD if i == 0 or i == 6 else CREAM)
		name.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(name)
		var amount := _label(VndWallet.format_vnd(int(item.required_vnd)), 17, GOLD if i == 6 else CREAM)
		amount.autowrap_mode = TextServer.AUTOWRAP_OFF
		amount.custom_minimum_size.x = 205
		amount.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		row.add_child(amount)
	if customizing:
		_render_customize()
	elif not confirming:
		setup_body.add_child(_button(words("CUSTOMIZE  ▾", "TÙY CHỈNH  ▾"), func(): customizing = true; _render_setup()))
	if confirming:
		var confirm := _card(setup_body)
		confirm.add_child(_label(words("REPLACE SAVED RUN?", "THAY VÁN ĐÃ LƯU?"), 23, GOLD))
		confirm.add_child(_label(_save_summary(), 17))
		confirm.add_child(_label(words("This starts a new run in the current save slot.", "Ván mới sẽ dùng ô lưu hiện tại."), 15))
	_show_page("setup")

func _render_customize() -> void:
	var custom := _card(setup_body)
	custom.add_child(_label(words("CUSTOMIZE RUN", "TÙY CHỈNH VÁN"), 22, GOLD))
	var seed := LineEdit.new()
	seed.name = "Seed"
	seed.max_length = 64
	seed.text = draft.seed
	seed.placeholder_text = words("Seed · blank for random", "Hạt giống · để trống để ngẫu nhiên")
	seed.text_changed.connect(func(value: String): draft.seed = value)
	custom.add_child(seed)
	custom.add_child(_label(words("MUSIC MODE", "CHẾ ĐỘ NHẠC"), 16))
	var modes := OptionButton.new()
	modes.name = "MusicMode"
	modes.add_item(words("Play individual tracks", "Phát từng bài"))
	modes.add_item(words("Authored DJ sets", "Bản phối DJ biên soạn"))
	modes.select(0 if draft.music_system == "playing_tracks" else 1)
	modes.item_selected.connect(func(index: int): draft.music_system = "playing_tracks" if index == 0 else "authored_dj")
	custom.add_child(modes)
	if not DemoBuild.enabled():
		custom.add_child(_label(words("PREFERRED ZODIAC EMBLEM", "HUY HIỆU CON GIÁP ƯU TIÊN"), 16))
		var emblem := OptionButton.new()
		emblem.name = "EmblemPreference"
		emblem.add_item(words("Seeded appearance", "Xuất hiện theo hạt giống"))
		emblem.set_item_metadata(0, "")
		for id: String in ZodiacCatalog.DEFINITIONS:
			if host.campaign.zodiac.progress.owns(id):
				emblem.add_item(ZodiacCatalog.display_name(id))
				emblem.set_item_metadata(emblem.item_count - 1, id)
				if draft.emblem_id == id: emblem.select(emblem.item_count - 1)
		emblem.item_selected.connect(func(index: int): draft.emblem_id = String(emblem.get_item_metadata(index)))
		custom.add_child(emblem)
	custom.add_child(_button(words("DONE  ▴", "XONG  ▴"), func(): customizing = false; _render_setup()))

func _change_difficulty(amount: int) -> void:
	draft.difficulty = clampi(draft.difficulty + amount, 1, host.campaign.difficulty_progress.unlocked)
	_render_setup()

func _start_pressed() -> void:
	if busy: return
	if not saved.is_empty() and not confirming:
		confirming = true
		customizing = false
		_render_setup()
		return
	busy = true
	start_requested.emit(draft.copy())

func start_failed(message: String) -> void:
	busy = false
	save_message = message
	_render_setup()

func show_collections() -> void:
	collection_tab = "drinks"
	selected_collection = ""
	_render_collections()

func _render_collections() -> void:
	page = "collections"
	_clear(collection_body)
	var tabs := HBoxContainer.new()
	collection_body.add_child(tabs)
	tabs.add_child(_button(words("DRINKS", "ĐỒ UỐNG") + ("  ◆" if collection_tab == "drinks" else ""), func(): collection_tab = "drinks"; selected_collection = ""; _render_collections()))
	if not DemoBuild.enabled(): tabs.add_child(_button(words("ZODIAC", "CON GIÁP") + ("  ◆" if collection_tab == "zodiac" else ""), func(): collection_tab = "zodiac"; selected_collection = ""; _render_collections()))
	var columns := GridContainer.new()
	columns.columns = 1 if size.x < 900 else 2
	collection_body.add_child(columns)
	var tiles := _card(columns)
	var detail := _card(columns)
	var ids: Array[String] = DrinkCatalog.basic_ids() if DemoBuild.enabled() else DrinkCatalog.all_ids()
	if collection_tab == "zodiac":
		ids.clear()
		for id: String in ZodiacCatalog.DEFINITIONS: ids.append(id)
	if selected_collection not in ids and not ids.is_empty(): selected_collection = ids[0]
	for id in ids:
		var status := ""
		if collection_tab == "drinks":
			status = words("UNLOCKED", "ĐÃ MỞ") if host.drink_manager.progress.is_unlocked(id) else words("LOCKED", "CHƯA MỞ")
		else:
			status = words("OWNED", "ĐÃ CÓ") if host.campaign.zodiac.progress.owns(id) else words("PROGRESS", "TIẾN ĐỘ")
		var name := DrinkCatalog.display_name(id) if collection_tab == "drinks" else ZodiacCatalog.display_name(id)
		var tile := _button(("◆  " if id == selected_collection else "◇  ") + name + "  ·  " + status, func(): selected_collection = id; _render_collections())
		tiles.add_child(tile)
	if collection_tab == "drinks":
		_render_drink_detail(detail)
	else:
		_render_zodiac_detail(detail)
	_show_page("collections")

func _render_drink_detail(detail: VBoxContainer) -> void:
	var id := selected_collection
	detail.add_child(_label(DrinkCatalog.display_name(id), 24, GOLD))
	detail.add_child(_label(host.drink_manager.progress.goal_text(id), 17))
	detail.add_child(_label(DrinkCatalog.effect_text(id), 17))
	detail.add_child(_label(words("Price: %d%% of today's debt", "Giá: %d%% nợ hôm nay") % int(DrinkManager.PRICE_PERCENT[id]), 16, MUTED))

func _render_zodiac_detail(detail: VBoxContainer) -> void:
	var id := selected_collection
	detail.add_child(_label(ZodiacCatalog.display_name(id), 24, GOLD))
	var definition: Dictionary = ZodiacCatalog.DEFINITIONS[id]
	var sprite := TextureRect.new()
	sprite.texture = load(String(definition.sprite))
	sprite.custom_minimum_size = Vector2(100, 100)
	sprite.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	sprite.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	detail.add_child(sprite)
	var progress := host.campaign.zodiac.progress
	var record := progress.record(id)
	for metric: String in definition.unlock:
		var required := int(definition.unlock[metric])
		var current := mini(int(record.get(metric, 0)), required)
		detail.add_child(_label("%s  ·  %d/%d" % [metric.replace("_", " ").capitalize(), current, required], 16))
	var state := words("EMBLEM OWNED", "ĐÃ CÓ HUY HIỆU") if progress.owns(id) else words("SPECIAL SCENE READY", "ĐÃ MỞ CẢNH ĐẶC BIỆT") if progress.eligible(id) else words("REQUIREMENTS IN PROGRESS", "ĐANG HOÀN THÀNH ĐIỀU KIỆN")
	detail.add_child(_label(state, 17, GOLD))

func _render_settings() -> void:
	_clear(settings_page)
	var panel := _card(settings_page)
	panel.add_child(_label(words("AUDIO & LANGUAGE", "ÂM THANH & NGÔN NGỮ"), 23, GOLD))
	for setting in [[words("MUSIC", "NHẠC"), host.settings.music_volume_percent, true], [words("SOUND", "ÂM THANH"), host.settings.sound_volume_percent, false]]:
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 16)
		panel.add_child(row)
		var caption := _label(String(setting[0]), 17)
		caption.custom_minimum_size.x = 170
		row.add_child(caption)
		var slider := HSlider.new()
		slider.min_value = 0
		slider.max_value = 100
		slider.step = 1
		slider.value = float(setting[1])
		slider.custom_minimum_size.x = 260
		slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(slider)
		var amount := _label("%d%%" % int(setting[1]), 16, GOLD)
		row.add_child(amount)
		if bool(setting[2]):
			slider.value_changed.connect(func(value: float): amount.text = "%d%%" % roundi(value); host._on_music_volume_changed(value))
		else:
			slider.value_changed.connect(func(value: float): amount.text = "%d%%" % roundi(value); host._on_sound_volume_changed(value))
	panel.add_child(_label(words("LANGUAGE", "NGÔN NGỮ"), 17))
	var languages := OptionButton.new()
	languages.name = "Language"
	languages.add_item(words("VIETNAMESE", "TIẾNG VIỆT"))
	languages.add_item(words("ENGLISH", "TIẾNG ANH"))
	languages.select(host.settings.locale_index())
	languages.item_selected.connect(func(index: int): host._on_language_selected(index))
	panel.add_child(languages)

func _show_page(id: String) -> void:
	var changed := active_page != id
	page = id
	active_page = id
	host.menu_page = StringName(id)
	for key in pages: (pages[key] as Control).visible = key == id
	title_label.text = {"home": "", "setup": words("NEW RUN", "VÁN MỚI"), "collections": words("COLLECTIONS", "BỘ SƯU TẬP"), "music": words("MUSIC", "ÂM NHẠC"), "settings": words("SETTINGS", "TÙY CHỌN")}.get(id, "")
	_clear(footer)
	if id != "home": footer.add_child(_button(words("BACK", "QUAY LẠI"), go_back))
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	footer.add_child(spacer)
	if id == "setup":
		if confirming:
			footer.add_child(_button(words("CANCEL", "HỦY"), func(): confirming = false; _render_setup()))
		footer.add_child(_button(words("REPLACE RUN", "THAY VÁN") if confirming else words("START RUN", "BẮT ĐẦU"), _start_pressed, "gold"))
	if changed:
		var panel: Control = pages[id]
		panel.modulate.a = 0.0
		create_tween().tween_property(panel, "modulate:a", 1.0, 0.18)
	_focus_page.call_deferred(id)

func _focus_page(id: String) -> void:
	if not is_inside_tree() or page != id: return
	var candidates := (pages[id] as Control).find_children("*", "Button", true, false)
	for control in candidates:
		if control is Button and control.is_visible_in_tree() and not control.disabled:
			control.grab_focus()
			return
	for control in footer.get_children():
		if control is Button and not control.disabled:
			control.grab_focus()
			return

func go_back() -> void:
	if page == "setup":
		if confirming:
			confirming = false
			_render_setup()
		elif customizing:
			customizing = false
			_render_setup()
		else:
			draft = null
			show_home()
	else: show_home()

func _unhandled_key_input(event: InputEvent) -> void:
	if not visible or host == null or not host.menu_layer.visible: return
	if event.is_action_pressed(&"ui_cancel") and page != "home":
		go_back()
		get_viewport().set_input_as_handled()

func _card(parent: Node) -> VBoxContainer:
	var panel := PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.add_theme_stylebox_override("panel", PresentationTheme.panel_style(CARD, Color("#55749d"), 1, 5, 3))
	parent.add_child(panel)
	var margin := MarginContainer.new()
	for side in ["left", "right"]: margin.add_theme_constant_override("margin_" + side, 18)
	for side in ["top", "bottom"]: margin.add_theme_constant_override("margin_" + side, 15)
	panel.add_child(margin)
	var body := VBoxContainer.new()
	body.add_theme_constant_override("separation", 10)
	margin.add_child(body)
	return body

func _button(caption: String, action: Callable, tone: String = "neutral") -> Button:
	var button := Button.new()
	button.text = caption
	button.custom_minimum_size = Vector2(145, 44)
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	PresentationTheme.configure_button(button, tone)
	button.pressed.connect(action)
	return button

func _label(caption: String, pixels: int, tint: Color = CREAM) -> Label:
	var label := Label.new()
	label.text = caption
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size", pixels)
	label.add_theme_color_override("font_color", tint)
	return label

func _clear(parent: Node) -> void:
	for child in parent.get_children():
		parent.remove_child(child)
		child.queue_free()
