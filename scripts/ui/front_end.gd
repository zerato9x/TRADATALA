class_name FrontEnd
extends Control

signal start_requested(draft: RunSetupDraft)
signal resume_requested()
signal return_requested()
signal handbook_requested()

const CARD := Color("#121e2aee")
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
var music_player: MusicPlayerView
var music_page: VBoxContainer
var settings_page: VBoxContainer
var files_body: VBoxContainer
var boss_lab_body: VBoxContainer
var boss_options: Dictionary = BossDebugSession.normalize({})
var boss_rule_preview: Label
var _previous_focus: Control
var _now_playing: Label
var _layout_width := 0

func words(en: String, vi: String) -> String:
	return vi if TranslationServer.get_locale().begins_with("vi") else en

func configure(owner: MatchUI) -> void:
	host = owner
	theme = PresentationTheme.create_game_theme()
	footer = $SafeArea/Frame/Footer
	title_label = $SafeArea/Frame/Header/PageTitle
	var logo: HBoxContainer = $SafeArea/Frame/Header/Logo
	for label: Label in logo.get_children():
		label.add_theme_color_override("font_color", GOLD)
		label.add_theme_color_override("font_shadow_color", Color("#06101c"))
		label.add_theme_color_override("font_outline_color", Color("#17273b"))
		label.add_theme_constant_override("outline_size", 3)
		label.add_theme_constant_override("shadow_offset_x", 3)
		label.add_theme_constant_override("shadow_offset_y", 5)
		logo_words.append(label)
	var stage: Control = $SafeArea/Frame/Main
	for id in ["home", "setup", "collections", "music", "settings", "files", "boss_lab"]:
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
			"files": files_body = body
			"boss_lab": boss_lab_body = body
	music_player = preload("res://scenes/ui/music_player.tscn").instantiate() as MusicPlayerView
	music_page.add_child(music_player)
	music_player.configure(host.music)
	host.music.changed.connect(_update_now_playing)
	_render_settings()
	host.music.controller.band_pulse.connect(_on_beat)
	host.settings.locale_changed.connect(func(_locale: String): _render_settings.call_deferred(); refresh.call_deferred())
	get_viewport().size_changed.connect(_on_size_changed)
	_on_size_changed()
	show_home()

func _on_size_changed() -> void:
	var margin := 20 if size.x < 900 else 40
	for side in ["left", "right"]:
		$SafeArea.add_theme_constant_override("margin_" + side, margin)
	$SafeArea/Frame.custom_minimum_size.x = minf(1040, size.x - margin * 2)
	_apply_page_layout()
	var compact := 1 if size.x < 900 else 2
	if _layout_width != 0 and compact != _layout_width:
		refresh.call_deferred()
	_layout_width = compact
	for label in logo_words:
		label.pivot_offset = label.size * 0.5

func _apply_page_layout() -> void:
	var home := page == "home"
	$SafeArea/Frame/Header/Logo.visible = home
	title_label.visible = not home
	$SafeArea/Frame/Header.custom_minimum_size.y = (160 if size.y >= 650 else 100) if home else 60
	for label in logo_words:
		label.add_theme_font_size_override("font_size", 88 if size.y >= 650 else 66)
	$Shade.color.a = 0.3 if home else 0.55
	if pages.has("home"):
		var inset := maxi(0, roundi(($SafeArea/Frame.custom_minimum_size.x - 500) * 0.5))
		for side in ["left", "right"]:
			pages.home.add_theme_constant_override("margin_" + side, inset)

func _on_beat(band: int, strength: float) -> void:
	if band >= 0 and band < 4:
		pulse_values[band] = maxf(pulse_values[band], strength)

func _process(delta: float) -> void:
	for index in logo_words.size():
		pulse_values[index] = move_toward(pulse_values[index], 0.0, delta * 3.5)
		logo_words[index].pivot_offset = logo_words[index].size * 0.5
		logo_words[index].scale = Vector2.ONE * (1.0 + pulse_values[index] * 0.08)

func _update_now_playing() -> void:
	if is_instance_valid(_now_playing):
		_now_playing.text = "♫  " + ReactiveMusicController.display_title_for_theme(host.music.controller.current_theme_id)

func refresh() -> void:
	match page:
		"home": show_home()
		"setup": _render_setup()
		"collections": _render_collections()
		"files": show_save_files()
		"boss_lab": show_boss_lab()
		_: _show_page(page)

func show_home() -> void:
	page = "home"
	confirming = false
	customizing = false
	busy = false
	saved = host.session.run_save.load_run()
	save_message = words("Recovered the backup save.", "Đã khôi phục bản lưu dự phòng.") if host.session.run_save.recovered_backup else host.session.run_save.error
	if not transient_error.is_empty():
		save_message = transient_error
		transient_error = ""
	_clear(home_body)
	home_body.alignment = BoxContainer.ALIGNMENT_CENTER
	home_body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	home_body.add_theme_constant_override("separation", 14)
	if host.game_started:
		home_body.add_child(_button(words("BACK TO GAME", "TRỞ LẠI BÀN"), func(): return_requested.emit(), "tea"))
	elif not saved.is_empty():
		var resume := _button(words("CONTINUE", "TIẾP TỤC"), func(): resume_requested.emit(), "tea")
		resume.tooltip_text = _save_summary()
		resume.disabled = not host.session.save_files.usable()
		home_body.add_child(resume)
	var new_run := _button(words("EXIT DEBUG", "THOÁT THỬ NGHIỆM") if host.session.debug_active else words("NEW RUN", "VÁN MỚI"), host.leave_boss_debug if host.session.debug_active else show_setup, "gold")
	new_run.name = "NewRun"
	new_run.custom_minimum_size.y = 56
	new_run.disabled = not host.session.debug_active and not host.session.save_files.usable()
	home_body.add_child(new_run)
	if host.session.save_files != null:
		var file_name: String = host.session.save_files.data.get("name", "")
		var file_label := _label(words("SAVE FILE %d", "Ô LƯU %d") % host.session.save_files.active_slot + (" · " + file_name if not file_name.is_empty() else ""), 15, GOLD)
		file_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		home_body.add_child(file_label)
		if not host.session.save_files.error.is_empty(): save_message = host.session.save_files.error
	if not save_message.is_empty(): home_body.add_child(_label(save_message, 15, GOLD))
	var nav := GridContainer.new()
	nav.name = "HomeNavigation"
	nav.columns = 2
	nav.add_theme_constant_override("h_separation", 12)
	nav.add_theme_constant_override("v_separation", 12)
	home_body.add_child(nav)
	nav.add_child(_button(words("COLLECTIONS", "BỘ SƯU TẬP"), show_collections))
	var handbook := _button(words("HANDBOOK", "SỔ TAY"), func(): handbook_requested.emit())
	handbook.name = "Handbook"
	nav.add_child(handbook)
	var music_button := _button(words("MUSIC", "ÂM NHẠC"), show_music)
	music_button.name = "Music"
	nav.add_child(music_button)
	var settings_button := _button(words("SETTINGS", "TÙY CHỌN"), show_settings)
	settings_button.name = "Settings"
	nav.add_child(settings_button)
	var files := _button(words("SAVE FILES", "CÁC Ô LƯU"), show_save_files)
	files.name = "SaveFiles"
	nav.add_child(files)
	if BossDebugSession.available():
		var lab := _button(words("DEBUG BOSSES · F9", "THỬ CON GIÁP · F9"), show_boss_lab)
		lab.name = "BossLab"
		nav.add_child(lab)
	_now_playing = _label("", 15, CREAM)
	_now_playing.name = "NowPlaying"
	_now_playing.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_now_playing.add_theme_color_override("font_outline_color", Color("#081525"))
	_now_playing.add_theme_constant_override("outline_size", 3)
	home_body.add_child(_now_playing)
	_update_now_playing()
	_show_page("home")

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
	for preference: String in host.campaign.zodiac.forced.values():
		if not preference.is_empty(): draft.emblem_id = preference; break
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
	challenge.add_child(_label(words("DIFFICULTY", "ĐỘ KHÓ"), 21, GOLD))
	var stepper := HBoxContainer.new()
	challenge.add_child(stepper)
	var previous := _button("◀", func(): _change_difficulty(-1))
	previous.custom_minimum_size = Vector2(52, 52)
	previous.size_flags_horizontal = Control.SIZE_FILL
	previous.disabled = draft.difficulty <= 1
	stepper.add_child(previous)
	var level := _label("%02d" % draft.difficulty, 58, CREAM)
	level.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	level.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stepper.add_child(level)
	var next := _button("▶", func(): _change_difficulty(1))
	next.custom_minimum_size = Vector2(52, 52)
	next.size_flags_horizontal = Control.SIZE_FILL
	next.disabled = draft.difficulty >= host.campaign.difficulty_progress.unlocked
	stepper.add_child(next)
	challenge.add_child(_label(words("Starting wallet: ", "Ví ban đầu: ") + VndWallet.format_vnd(CampaignConfig.STARTING_WALLET_VND), 17, GOLD))
	challenge.add_child(_button(words("HANDBOOK", "SỔ TAY"), func(): GameGlossary.open(host, "campaign")))
	var unlocked: int = host.campaign.difficulty_progress.unlocked
	if unlocked < 28:
		var next_days := CampaignConfig.day_definitions(unlocked + 1)
		challenge.add_child(_label(words("NEXT LOCKED  ·  %d  ·  SUNDAY %s", "MỨC KẾ TIẾP  ·  %d  ·  CHỦ NHẬT %s") % [unlocked + 1, VndWallet.format_vnd(int(next_days[-1].required_vnd))], 15, MUTED))
	var week := _card(columns)
	week.add_child(_label(words("DAILY DEBT", "NỢ MỖI NGÀY"), 21, GOLD))
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
	columns.add_theme_constant_override("h_separation", 18)
	columns.add_theme_constant_override("v_separation", 18)
	collection_body.add_child(columns)
	var tiles := _card(columns)
	var detail := _card(columns)
	if columns.columns == 1:
		columns.move_child(detail.get_parent().get_parent(), 0)
	var tile_scroll := ScrollContainer.new()
	tile_scroll.name = "CollectionListScroll"
	tile_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	tile_scroll.follow_focus = true
	tile_scroll.custom_minimum_size.y = clampf(size.y - 300, 220, 480)
	tiles.add_child(tile_scroll)
	var tile_list := VBoxContainer.new()
	tile_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tile_list.add_theme_constant_override("separation", 10)
	tile_scroll.add_child(tile_list)
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
		var tile := _button(name + "  ·  " + status, func(): selected_collection = id; _render_collections(), "gold" if id == selected_collection else "neutral")
		tile.name = "Collection_" + id
		tile_list.add_child(tile)
	if collection_tab == "drinks":
		_render_drink_detail(detail)
	else:
		_render_zodiac_detail(detail)
	_show_page("collections")

func _render_drink_detail(detail: VBoxContainer) -> void:
	var id := selected_collection
	detail.add_child(_label(DrinkCatalog.display_name(id), 24, GOLD))
	var sprite := TextureRect.new()
	sprite.name = "DrinkCollectionSprite"
	sprite.texture = DrinkPresentation.texture(id)
	sprite.modulate = DrinkPresentation.tint(id)
	sprite.custom_minimum_size = Vector2(0, 100)
	sprite.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	sprite.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	detail.add_child(sprite)
	detail.add_child(_label(host.drink_manager.progress.goal_text(id), 17))
	detail.add_child(_label(QuickInfo.drink(id), 20))
	detail.add_child(_label(words("Price: %d%% of today's debt", "Giá: %d%% nợ hôm nay") % int(DrinkManager.PRICE_PERCENT[id]), 16, MUTED))
	detail.add_child(_button(words("HANDBOOK", "SỔ TAY"), func(): GameGlossary.open_entry(host, DrinkCatalog.display_name(id), DrinkCatalog.effect_text(id) + "\n\n" + host.drink_manager.progress.goal_text(id), "drinks")))

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
	var metric_labels := {"requests_resolved": words("Requests completed", "Yêu cầu hoàn thành"), "requests_refused_successfully": words("Respected refusals", "Từ chối được tôn trọng"), "pleased_victories": words("Pleased boss victories", "Thắng boss hài lòng"), "restraint_kept": words("Promises kept", "Cam kết đã giữ")}
	for metric: String in definition.unlock:
		var required := int(definition.unlock[metric])
		var current := mini(int(record.get(metric, 0)), required)
		detail.add_child(_label("%s  ·  %d/%d" % [metric_labels.get(metric, metric.replace("_", " ").capitalize()), current, required], 16))
	var state := words("EMBLEM OWNED", "ĐÃ CÓ HUY HIỆU") if progress.owns(id) else words("SPECIAL SCENE READY", "ĐÃ MỞ CẢNH ĐẶC BIỆT") if progress.eligible(id) else words("REQUIREMENTS IN PROGRESS", "ĐANG HOÀN THÀNH ĐIỀU KIỆN")
	detail.add_child(_label(state, 17, GOLD))

func show_music() -> void:
	_show_page("music")

func show_settings() -> void:
	_show_page("settings")

func _render_settings() -> void:
	_clear(settings_page)
	var panel := _card(settings_page)
	for setting in [[words("MUSIC", "NHẠC"), host.settings.music_volume_percent, true], [words("SOUND", "ÂM THANH"), host.settings.sound_volume_percent, false]]:
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 16)
		panel.add_child(row)
		var caption := _label(String(setting[0]), 17)
		caption.custom_minimum_size.x = 170
		row.add_child(caption)
		var slider := HSlider.new()
		slider.name = "MusicVolume" if bool(setting[2]) else "SoundVolume"
		slider.min_value = 0
		slider.max_value = 100
		slider.step = 1
		slider.value = float(setting[1])
		slider.custom_minimum_size.x = 260
		slider.custom_minimum_size.y = 40
		slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(slider)
		var amount := _label("%d%%" % int(setting[1]), 16, GOLD)
		amount.autowrap_mode = TextServer.AUTOWRAP_OFF
		amount.custom_minimum_size.x = 65
		amount.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		row.add_child(amount)
		if bool(setting[2]):
			slider.value_changed.connect(func(value: float): amount.text = "%d%%" % roundi(value); host.settings.set_music_volume(value))
		else:
			slider.value_changed.connect(func(value: float): amount.text = "%d%%" % roundi(value); host.settings.set_sound_volume(value))
	panel.add_child(_label(words("LANGUAGE", "NGÔN NGỮ"), 17))
	var languages := OptionButton.new()
	languages.name = "Language"
	languages.add_item(words("VIETNAMESE", "TIẾNG VIỆT"))
	languages.add_item(words("ENGLISH", "TIẾNG ANH"))
	languages.select(host.settings.locale_index())
	languages.item_selected.connect(func(index: int): host.settings.set_locale(host.settings.SUPPORTED_LOCALES[index]))
	panel.add_child(languages)
	for spec in [["ShowStrawy", words("SHOW STRAWY", "HIỆN STRAWY"), host.settings.strawy_enabled], ["Tutorial", words("TUTORIAL", "HƯỚNG DẪN"), host.settings.tutorial_enabled], ["FirstSeed", words("FIRST SEED", "BÀI KHỞI ĐẦU"), host.settings.first_seed_enabled]]:
		var toggle := CheckButton.new()
		toggle.name = spec[0]
		toggle.text = spec[1]
		toggle.button_pressed = spec[2]
		toggle.custom_minimum_size.y = 48
		if spec[0] == "ShowStrawy":
			toggle.toggled.connect(host.settings.set_strawy_enabled)
		elif spec[0] == "Tutorial":
			toggle.toggled.connect(host.settings.set_tutorial_enabled)
		else:
			toggle.toggled.connect(host.settings.set_first_seed_enabled)
		panel.add_child(toggle)
	panel.add_child(_label(words("Ask Strawy to teach during your real first day. First Seed curates Monday's cards for new runs; switch it off to use your run seed throughout.", "Hỏi Strawy để học trong ngày đầu thật. Bài khởi đầu sắp bài thứ Hai cho ván mới; tắt để dùng hạt giống của bạn xuyên suốt."), 15))

func _show_page(id: String) -> void:
	var changed := active_page != id
	page = id
	active_page = id
	for key in pages: (pages[key] as Control).visible = key == id
	title_label.text = {"home": "", "setup": words("NEW RUN", "VÁN MỚI"), "collections": words("COLLECTIONS", "BỘ SƯU TẬP"), "music": words("MUSIC", "ÂM NHẠC"), "settings": words("SETTINGS", "TÙY CHỌN"), "files": words("SAVE FILES", "CÁC Ô LƯU"), "boss_lab": words("BOSS LAB · DEBUG", "THỬ CON GIÁP")}.get(id, "")
	_apply_page_layout()
	_clear(footer)
	if id != "home":
		var back := _button(words("BACK", "QUAY LẠI"), go_back)
		back.name = "FrontBack"
		footer.add_child(back)
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	footer.add_child(spacer)
	if id == "setup":
		if confirming:
			footer.add_child(_button(words("CANCEL", "HỦY"), func(): confirming = false; _render_setup()))
		footer.add_child(_button(words("REPLACE RUN", "THAY VÁN") if confirming else words("START RUN", "BẮT ĐẦU"), _start_pressed, "gold"))
	if id == "boss_lab":
		if host.session.debug_active:
			footer.add_child(_button(words("EXIT SANDBOX", "THOÁT THỬ NGHIỆM"), host.leave_boss_debug))
		var resume := _button(words("RESUME TEST", "TIẾP TỤC THỬ"), _resume_debug)
		resume.name = "ResumeBossTest"
		resume.disabled = not FileAccess.file_exists(BossDebugSession.SAVE_PATH) and not FileAccess.file_exists(BossDebugSession.SAVE_PATH + ".bak")
		footer.add_child(resume)
		var start := _button(words("START TEST", "BẮT ĐẦU THỬ"), _start_debug, "gold")
		start.name = "StartBossTest"
		footer.add_child(start)
	if changed:
		var panel: Control = pages[id]
		panel.modulate.a = 0.0
		create_tween().tween_property(panel, "modulate:a", 1.0, 0.18)
	_focus_page.call_deferred(id)

func _focus_page(id: String) -> void:
	if not is_inside_tree() or page != id: return
	if id == "collections":
		var selected := (pages[id] as Control).find_child("Collection_" + selected_collection, true, false) as Button
		if selected != null:
			selected.grab_focus()
			return
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
	panel.add_theme_stylebox_override("panel", PresentationTheme.panel_style(CARD, Color("#8f7752"), 1, 3, 4))
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
	button.custom_minimum_size = Vector2(145, 48)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	PresentationTheme.configure_button(button, tone)
	button.add_theme_font_size_override("font_size", 18)
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


func show_save_files() -> void:
	_clear(files_body)
	files_body.add_child(_label(words("Each file keeps its own drink unlocks, difficulty levels, Zodiac emblems, and endings across New Run.", "Mỗi ô giữ riêng các món nước, độ khó, huy hiệu Con Giáp và kết thúc đã mở qua các ván mới."), 17))
	if not host.session.save_files.error.is_empty(): files_body.add_child(_label(host.session.save_files.error, 16, GOLD))
	if host.session.debug_active: files_body.add_child(_label(words("Exit the debug sandbox to change save files.", "Thoát thử nghiệm để đổi ô lưu."), 16, GOLD))
	var cards := GridContainer.new()
	cards.columns = 1 if size.x < 900 else 3
	cards.add_theme_constant_override("h_separation", 14)
	cards.add_theme_constant_override("v_separation", 14)
	files_body.add_child(cards)
	for info: Dictionary in host.session.save_files.summaries():
		var body := _card(cards)
		body.get_parent().get_parent().size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var name: String = info.name
		body.add_child(_label(words("FILE %d", "Ô LƯU %d") % int(info.slot), 24, GOLD))
		body.add_child(_label(name if not name.is_empty() else words("Player %d", "Người chơi %d") % int(info.slot), 18))
		var unlocked_drinks := 0
		for goal: Array in DrinkProgress.GOALS.values():
			if int(info.drink_counters.get(goal[0], 0)) >= int(goal[1]): unlocked_drinks += 1
		var emblems := 0
		var endings := 0
		for record: Dictionary in info.zodiac.records.values():
			if record.get("emblem_unlocked", false): emblems += 1
			if record.get("ending_rong_ran_len_may", false): endings += 1
		body.add_child(_label(words("Difficulty %d\nDrinks %d/12\nEmblems %d/12 · endings %d", "Độ khó %d\nNước %d/12\nHuy hiệu %d/12 · kết thúc %d") % [info.difficulty_unlocked, unlocked_drinks, emblems, endings], 16))
		var summary: Dictionary = info.run_summary
		body.add_child(_label(words("No run checkpoint", "Chưa có ván đã lưu") if not info.has_run else words("Run checkpoint available", "Có ván đã lưu") if summary.is_empty() else words("Day %d · %s", "Ngày %d · %s") % [summary.get("day", 1), VndWallet.format_vnd(summary.get("wallet_vnd", 0))], 15, MUTED))
		if info.backup: body.add_child(_label(words("Backup recovered", "Đã khôi phục dự phòng"), 15, GOLD))
		if info.damaged: body.add_child(_label(words("Damaged file · preserved", "Ô bị lỗi · được giữ nguyên"), 15, GOLD))
		var button := _button(words("ACTIVE FILE", "Ô ĐANG DÙNG") if info.active else words("LOAD FILE", "DÙNG Ô NÀY") if info.exists else words("CREATE FILE", "TẠO Ô LƯU"), _choose_file.bind(int(info.slot)), "tea" if info.active else "neutral")
		button.name = "SaveFile_%d" % int(info.slot)
		button.disabled = info.active or info.damaged or host.session.debug_active
		body.add_child(button)
	var rename := _card(files_body)
	rename.add_child(_label(words("NAME THE ACTIVE FILE", "ĐẶT TÊN Ô ĐANG DÙNG"), 17, GOLD))
	var row := HBoxContainer.new()
	rename.add_child(row)
	var entry := LineEdit.new()
	entry.name = "SaveFileName"
	entry.max_length = 40
	entry.text = host.session.save_files.data.get("name", "")
	entry.placeholder_text = words("Player name", "Tên người chơi")
	entry.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	entry.custom_minimum_size.y = 44
	row.add_child(entry)
	var save_name := _button(words("SAVE NAME", "LƯU TÊN"), func(): host.session.save_files.rename_file(entry.text); show_save_files())
	save_name.name = "SaveFileRename"
	save_name.disabled = host.session.debug_active
	row.add_child(save_name)
	_show_page("files")

func _choose_file(slot: int) -> void:
	if not host.select_save_file(slot):
		transient_error = host.session.save_files.error if not host.session.save_files.error.is_empty() else words("Could not change save file.", "Không thể đổi ô lưu.")
		show_error(transient_error)
		return
	show_home()

func show_boss_lab() -> void:
	if not BossDebugSession.available(): return
	_clear(boss_lab_body)
	boss_lab_body.add_child(_label(words("DEBUG SANDBOX · Test victories and unlocks stay separate from your save files. F9 opens this lab.", "THỬ NGHIỆM · Kết quả và vật phẩm thử không ghi vào ô lưu của bạn. F9 mở màn hình này."), 16, GOLD))
	var panel := _card(boss_lab_body)
	var grid := GridContainer.new()
	grid.columns = 1 if size.x < 900 else 2
	grid.add_theme_constant_override("h_separation", 20)
	grid.add_theme_constant_override("v_separation", 8)
	panel.add_child(grid)
	var bosses: Array = []
	for id: String in ZodiacBossRule.RULES: bosses.append([id, ZodiacCatalog.display_name(id), ZodiacCatalog.display_name(id)])
	_lab_choice(grid, "Boss", words("BOSS", "CON GIÁP"), bosses, boss_options.boss, func(value: String): boss_options.boss = value; show_boss_lab())
	_lab_choice(grid, "BossDifficulty", words("DIFFICULTY", "ĐỘ KHÓ"), [["1", "PLEASED", "HÀI LÒNG"], ["2", "NORMAL", "BÌNH THƯỜNG"], ["3", "UNPLEASED", "KHÔNG HÀI LÒNG"]], str(boss_options.difficulty), func(value: String): boss_options.difficulty = int(value); _refresh_boss_rule())
	_lab_choice(grid, "BossPhase", words("STARTING PHASE", "HIỆP BẮT ĐẦU"), [["1", "Phase 1", "Hiệp 1"], ["2", "Phase 2", "Hiệp 2"]], str(boss_options.phase), func(value: String): boss_options.phase = int(value))
	_lab_choice(grid, "BossOpening", words("OPENING HAND", "BÀI KHỞI ĐẦU"), [["curated", "Known Set + Run", "Bộ + Dây có sẵn"], ["seeded", "Seeded shuffle", "Xáo theo hạt giống"]], boss_options.opening, func(value: String): boss_options.opening = value)
	var seed_box := _lab_field(grid, words("SEED", "HẠT GIỐNG"))
	var seed := LineEdit.new()
	seed.name = "BossSeed"
	seed.max_length = 64
	seed.text = boss_options.seed
	seed.custom_minimum_size.y = 42
	seed.text_changed.connect(func(value: String): boss_options.seed = value)
	seed_box.add_child(seed)
	var drinks: Array = [[DrinkCatalog.NONE, "No drink", "Không dùng nước"]]
	for id: String in DrinkCatalog.all_ids(): drinks.append([id, DrinkCatalog.display_name(id), DrinkCatalog.display_name(id)])
	_lab_choice(grid, "BossDrink", words("ACTIVE DRINK", "MÓN NƯỚC"), drinks, boss_options.drink, func(value: String): boss_options.drink = value)
	_lab_amount(grid, "BossWallet", words("STARTING WALLET · VNĐ", "VÍ KHỞI ĐẦU · VNĐ"), boss_options.wallet_vnd, func(value: int): boss_options.wallet_vnd = value)
	if boss_options.boss == "dragon":
		_lab_choice(grid, "DragonTactic", words("DRAGON TACTIC", "CHIẾN THUẬT THÌN"), [["history", "Analyze my run history", "Phân tích lịch sử ván"], ["new_meld:set", "Meld · Set", "Tạo Phỏm · Bộ"], ["new_meld:run", "Meld · Run", "Tạo Phỏm · Dây"], ["extension:set", "Extend · Set", "Nối Phỏm · Bộ"], ["extension:run", "Extend · Run", "Nối Phỏm · Dây"]], boss_options.dragon_tactic, func(value: String): boss_options.dragon_tactic = value)
		_lab_amount(grid, "DragonAverage", words("OVERRIDE AVERAGE · VNĐ", "TRUNG BÌNH THỬ · VNĐ"), boss_options.dragon_average_vnd, func(value: int): boss_options.dragon_average_vnd = value)
		panel.add_child(_label(words("Average override applies only to a manually selected tactic. History uses actual saved earnings.", "Trung bình thử chỉ áp dụng khi chọn chiến thuật thủ công. Lịch sử dùng thu nhập thật đã lưu."), 14, MUTED))
	boss_rule_preview = _label("", 15)
	panel.add_child(boss_rule_preview)
	_refresh_boss_rule()
	_show_page("boss_lab")

func _lab_field(parent: Node, caption: String) -> VBoxContainer:
	var field := VBoxContainer.new()
	field.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	field.custom_minimum_size.x = 300 if size.x >= 900 else 0
	parent.add_child(field)
	field.add_child(_label(caption, 15, GOLD))
	return field

func _lab_choice(parent: Node, id: String, caption: String, options: Array, selected: String, changed: Callable) -> void:
	var field := _lab_field(parent, caption)
	var choice := OptionButton.new()
	choice.name = id
	choice.custom_minimum_size.y = 42
	for item: Array in options:
		choice.add_item(words(item[1], item[2]))
		choice.set_item_metadata(choice.item_count - 1, item[0])
		if item[0] == selected: choice.select(choice.item_count - 1)
	choice.item_selected.connect(func(index: int): changed.call(String(choice.get_item_metadata(index))))
	field.add_child(choice)

func _lab_amount(parent: Node, id: String, caption: String, amount: int, changed: Callable) -> void:
	var field := _lab_field(parent, caption)
	var value := SpinBox.new()
	value.name = id
	value.min_value = 0
	value.max_value = 1_000_000_000
	value.step = 1_000
	value.value = amount
	value.custom_minimum_size.y = 42
	value.value_changed.connect(func(number: float): changed.call(int(number)))
	field.add_child(value)

func _refresh_boss_rule() -> void:
	if is_instance_valid(boss_rule_preview): boss_rule_preview.text = ZodiacCatalog.rule_text(boss_options.boss, boss_options.difficulty)

func _start_debug() -> void:
	if not host.start_boss_debug(boss_options): show_error(words("Could not start the boss test.", "Không thể bắt đầu thử Con Giáp."))

func _resume_debug() -> void:
	if not host.resume_boss_debug(): show_error(words("No valid saved boss test is available.", "Chưa có bản thử Con Giáp hợp lệ."))
