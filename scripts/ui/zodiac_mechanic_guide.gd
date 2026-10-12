extends Control
## Actionable table guidance derived from the Deal-owned boss. No rule mutation.
const View := preload("res://scripts/ui/zodiac_presentation.gd")
const METERS := {"pig": preload("res://shaders/pig_held_pool.gdshader"), "horse": preload("res://shaders/horse_pair.gdshader"), "dragon": preload("res://shaders/dragon_target.gdshader")}
var host: Control
var caption: Label
var body: RichTextLabel
var commands: VBoxContainer
var meter: ColorRect
var faces: HBoxContainer
var active := false
var lane_height := 60.0
var _command_key := ""
var _face_key := ""
var _meter_kind := ""
var pig_vault: Control
var pig_terms: Label
var pig_footer: Label
var _pig_identity := ""
var _pig_progress := 0.0
var _pig_display_progress := 0.0
var _is_pig := false
var pair_art: Control
var goat_staff: Control
var pair_footer: Label
var _pair_kind := ""
var _pair_identity := ""
var _pair_footer_text := ""
var _pair_notice := 0.0
var _paused := false

func configure(owner: Control) -> void:
	host = owner
	name = "ZodiacMechanicGuide"
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	caption = Label.new()
	caption.name = "MechanicName"
	caption.add_theme_font_size_override("font_size", 12)
	caption.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(caption)
	body = RichTextLabel.new()
	body.name = "MechanicInstructions"
	body.bbcode_enabled = true
	body.fit_content = true
	body.scroll_active = false
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body.add_theme_font_size_override("normal_font_size", 15)
	body.add_theme_color_override("font_shadow_color", Color.BLACK)
	body.add_theme_constant_override("shadow_offset_y", 1)
	body.mouse_filter = Control.MOUSE_FILTER_IGNORE
	body.position.y = 18
	add_child(body)
	commands = VBoxContainer.new()
	commands.name = "SnakeCommands"
	commands.position.y = 17
	commands.add_theme_constant_override("separation", 1)
	commands.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(commands)
	faces = HBoxContainer.new()
	faces.name = "SnatchedCards"
	faces.position.y = 36
	faces.add_theme_constant_override("separation", 5)
	faces.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(faces)
	meter = ColorRect.new()
	meter.name = "MechanicProgress"
	meter.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(meter)
	pig_vault = preload("res://scripts/ui/pig_fortune_vault.gd").new()
	add_child(pig_vault)
	pig_vault.hide()
	pig_terms = Label.new()
	pig_terms.name = "PigSiphonTerms"
	pig_terms.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pig_terms.add_theme_font_size_override("font_size", 12)
	pig_terms.add_theme_color_override("font_color", PresentationTheme.MUTED)
	add_child(pig_terms)
	pig_terms.hide()
	pig_footer = Label.new()
	pig_footer.name = "PigReturnPromise"
	pig_footer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pig_footer.add_theme_font_size_override("font_size", 12)
	pig_footer.add_theme_color_override("font_color", PresentationTheme.MUTED)
	add_child(pig_footer)
	pig_footer.hide()
	pair_art = preload("res://scripts/ui/horse_goat_mechanic_art.gd").new()
	add_child(pair_art)
	pair_art.hide()
	goat_staff = preload("res://scripts/ui/goat_rank_staff.gd").new()
	add_child(goat_staff)
	goat_staff.hide()
	pair_footer = Label.new()
	pair_footer.name = "HorseGoatReaction"
	pair_footer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pair_footer.add_theme_font_size_override("font_size", 12)
	pair_footer.add_theme_color_override("font_color", PresentationTheme.MUTED)
	add_child(pair_footer)
	pair_footer.hide()
	hide()

func sync(state: Dictionary, identity: String = "") -> void:
	var id: String = state.get("id", "")
	_is_pig = id == "pig"
	_pair_kind = id if id in ["horse", "goat"] else ""
	var pair_key := identity + ":%d" % host.deal.current_phase
	if pair_key != _pair_identity or _pair_kind.is_empty():
		clear_pair_effects()
		_pair_identity = pair_key
	pair_art.visible = not _pair_kind.is_empty()
	goat_staff.visible = _pair_kind == "goat"
	pair_footer.visible = not _pair_kind.is_empty()
	pig_vault.visible = _is_pig
	pig_terms.visible = _is_pig
	pig_footer.visible = _is_pig
	caption.position.x = 86 if _is_pig or not _pair_kind.is_empty() else 0
	body.position.x = caption.position.x
	active = id in ["pig", "horse", "goat", "snake", "dragon"]
	visible = active
	if not active: return
	caption.text = String(state.skill)
	PresentationTheme.style_text(caption, &"mechanic", 14)
	var copy := ""
	var progress := 0.0
	match id:
		"pig":
			copy = ZodiacCatalog.words("TARGET MET · pool returned ✓", "ĐỦ MỤC TIÊU · đã hoàn quỹ ✓") if state.target_met else ZodiacCatalog.words("Gross %s / %s", "Tổng thu %s / %s") % [VndWallet.format_vnd(int(state.progress_vnd)), VndWallet.format_vnd(int(state.target_vnd))]
			progress = float(state.progress_vnd) / maxf(int(state.target_vnd), 1)
			pig_terms.text = ZodiacCatalog.words("Held %s", "Giữ %s") % VndWallet.format_vnd(int(state.pool_vnd))
			pig_footer.text = ZodiacCatalog.words("Reach target → entire pool returned", "Đủ mục tiêu → hoàn lại cả quỹ") if not state.target_met else ZodiacCatalog.words("Vault open · no more siphoning", "Quỹ đã mở · không giữ thêm tiền")
			if int(state.difficulty) == ZodiacCatalog.UNPLEASED and not state.target_met:
				pig_footer.text = ZodiacCatalog.words("Target → refund · Miss: −%d%% positive bank", "Đủ → hoàn quỹ · Trượt: −%d%% ví dương") % int(ZodiacCatalog.tuning("pig", "bank_loss_percent", state.difficulty))
			if state.get("settled", false) and not state.target_met:
				pig_footer.text = ZodiacCatalog.words("Collection complete", "Đã thu xong")
				copy = ZodiacCatalog.words("TARGET MISSED · held pool kept", "TRƯỢT MỤC TIÊU · Hợi giữ quỹ")
				if state.has("bank_loss_vnd"):
					pig_terms.text = ZodiacCatalog.words("Collected: −", "Đã thu: −") + VndWallet.format_vnd(int(state.bank_loss_vnd))
				else:
					pig_terms.text = "%s / %s" % [VndWallet.format_vnd(int(state.progress_vnd)), VndWallet.format_vnd(int(state.target_vnd))]
			var reset := identity != _pig_identity or progress < _pig_progress
			_pig_identity = identity
			_pig_progress = clampf(progress, 0, 1)
			if reset: _pig_display_progress = _pig_progress
			pig_vault.sync(state, reset)
			caption.add_theme_color_override("font_color", PresentationTheme.zodiac_color("pig"))
		"ox":
			copy = ZodiacCatalog.words("Next loss: on each card\nPlay or discard a card to clear its burden.", "Phạt tới: trên từng lá\nHạ, nối hoặc bỏ lá để hết gánh nặng.")
		"horse":
			var action := String(state.required_action)
			var target := int(ZodiacCatalog.tuning("horse", "matching_actions", state.difficulty))
			copy = "%s · %d/2" % [ZodiacCatalog.action_label(action) if not action.is_empty() else ZodiacCatalog.words("PAIR", "CẶP"), int(state.pair_count)]
			var limit: int = host.deal.phase_discard_limit()
			_pair_footer_text = ZodiacCatalog.words("Turn %d/%d", "Lượt %d/%d") % [mini(host.deal.discard_count + 1, limit), limit]
			_pair_footer_text += " · " + (ZodiacCatalog.words("Your discard", "Tự chọn lá bỏ") if int(state.pair_count) >= target else ZodiacCatalog.words("Grace %d", "Ân hạn %d") % int(state.pair_grace) if int(state.pair_grace) > 0 else ZodiacCatalog.words("Discard → random", "Bỏ → ngẫu nhiên"))
			if host.deal.state == DealState.STATE_FINAL_COMMIT_WINDOW:
				copy = ZodiacCatalog.words("FINAL COMMIT", "HẠ CUỐI")
				_pair_footer_text = ""
			progress = float(state.pair_count) / target
			pair_art.sync(state)
		"goat":
			copy = ZodiacCatalog.words("FIRST WINDOW", "NHÓM MỞ ĐẦU") if int(state.expected_rank) == 0 else ZodiacCatalog.words("ACCEPTS: ", "NHẬN: ") + ZodiacCatalog.rank_window_text(int(state.expected_rank))
			_pair_footer_text = ""
			if int(state.difficulty) == ZodiacCatalog.UNPLEASED:
				var parity := ZodiacCatalog.words("ODD", "LẺ") if int(state.turn_number) % 2 else ZodiacCatalog.words("EVEN", "CHẴN")
				_pair_footer_text = ZodiacCatalog.words("First %s", "Lá đầu %s") % parity
			elif int(state.rhythm_grace) > 0:
				_pair_footer_text = ZodiacCatalog.words("Grace %d", "Ân hạn %d") % int(state.rhythm_grace)
			if host.deal.state == DealState.STATE_FINAL_COMMIT_WINDOW:
				_pair_footer_text = ZodiacCatalog.words("FINAL COMMIT", "HẠ CUỐI")
			pair_art.sync(state)
			goat_staff.sync(state)
		"rat":
			copy = ZodiacCatalog.words("Rat · %d Meld(s) · %s", "Tý · %d Phỏm · %s") % [host.deal.boss_melds.size(), VndWallet.format_vnd(-absi(int(state.get("hostile_result", {}).get("amount_vnd", 0))))]
		"tiger":
			copy = ZodiacCatalog.words("Snatched %d", "Đã vồ %d lá") % state.get("removed_ids", []).size()
			if int(state.difficulty) == ZodiacCatalog.UNPLEASED: copy += " · " + ZodiacCatalog.words("Exhaustion: no bonus", "Cạn bài: không thưởng")
		"snake":
			copy = ""
			_sync_commands(state.get("commands", []))
		"dragon":
			copy = ZodiacCatalog.tactic_label(state.tactic) + " · " + ZodiacCatalog.words("%s / %s", "%s / %s") % [VndWallet.format_vnd(int(state.progress_vnd)), VndWallet.format_vnd(int(state.target_vnd))]
			var modifier: String = state.get("modifier_id", "")
			copy += "\n" + ZodiacCatalog.display_name(modifier) + " · " + View.modifier_live(state, host.deal)
			progress = float(state.progress_vnd) / maxf(int(state.target_vnd), 1)
	if body.text != copy: body.text = copy
	if not _pair_kind.is_empty():
		caption.add_theme_color_override("font_color", View.accent(_pair_kind))
		if _pair_notice <= 0: pair_footer.text = _pair_footer_text
	body.visible = id != "snake"
	commands.visible = id == "snake"
	faces.visible = id == "tiger"
	if id == "tiger": _sync_faces(state.get("removed_ids", []))
	meter.visible = METERS.has(id)
	if meter.visible:
		if _meter_kind != id:
			_meter_kind = id
			var ink := ShaderMaterial.new()
			ink.shader = METERS[id]
			meter.material = ink
		(meter.material as ShaderMaterial).set_shader_parameter("progress", clampf(progress, 0, 1))
		if _is_pig:
			(meter.material as ShaderMaterial).set_shader_parameter("display_progress", _pig_display_progress)
			(meter.material as ShaderMaterial).set_shader_parameter("unlocked", 1.0 if state.target_met else 0.0)
	tooltip_text = ZodiacCatalog.words("Handbook", "Sổ tay")

func _process(delta: float) -> void:
	if not is_visible_in_tree() or _paused: return
	if _is_pig:
		_pig_display_progress = move_toward(_pig_display_progress, _pig_progress, delta * 1.6)
		(meter.material as ShaderMaterial).set_shader_parameter("display_progress", _pig_display_progress)
	if _pair_notice > 0:
		_pair_notice = maxf(_pair_notice - delta, 0)
		if _pair_notice <= 0:
			pair_footer.text = _pair_footer_text
			pair_footer.add_theme_color_override("font_color", PresentationTheme.MUTED)

func pair_reaction(text: String, tint: Color) -> void:
	_pair_notice = 1.6
	pair_footer.text = text
	pair_footer.add_theme_color_override("font_color", tint)
	pair_art.react()

func clear_pair_effects() -> void:
	_pair_notice = 0
	if pair_footer != null:
		pair_footer.text = _pair_footer_text
		pair_footer.add_theme_color_override("font_color", PresentationTheme.MUTED)
	if pair_art != null: pair_art.clear_effects()
	if goat_staff != null: goat_staff.clear_effects()

func pause_effects(paused: bool) -> void:
	_paused = paused
	goat_staff.pause_effects(paused)

func fit_width(width: float) -> void:
	# Only live requirements earn table space. Rules are in the ? handbook.
	caption.hide()
	pig_footer.hide()
	var illustrated := _is_pig or not _pair_kind.is_empty()
	var left := 60.0 if illustrated else 0.0
	body.position = Vector2(left, 0)
	body.size = Vector2(maxf(width - left, 1), 22)
	var pixels := 14
	body.add_theme_font_size_override("normal_font_size", pixels)
	for art: Control in [pair_art, pig_vault]:
		art.position = Vector2(0, 0)
		art.scale = Vector2.ONE * 0.58
	lane_height = 50
	if not _pair_kind.is_empty():
		if _pair_kind == "horse":
			meter.position = Vector2(left, 44)
			meter.size = Vector2(body.size.x, 6)
			pair_footer.position = Vector2(left, 23)
		else:
			goat_staff.position = Vector2(left, maxf(22, body.get_content_height() + 3))
			goat_staff.fit_width(body.size.x)
			lane_height = goat_staff.position.y + goat_staff.size.y
			pair_footer.position = Vector2(left, lane_height)
			if not pair_footer.text.is_empty(): lane_height += 17
		pair_footer.visible = not pair_footer.text.is_empty()
		pair_footer.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		pair_footer.add_theme_font_size_override("font_size", 11)
		pair_footer.size = Vector2(body.size.x, 17)
	elif _is_pig:
		pig_terms.add_theme_font_size_override("font_size", 12)
		pig_terms.position = Vector2(left, 25)
		pig_terms.size = Vector2(body.size.x, 18)
		meter.position = Vector2(left, 44)
		meter.size = Vector2(body.size.x, 6)
	else:
		commands.position = Vector2.ZERO
		for button: Button in commands.get_children():
			var command_pixels := 14
			while command_pixels > 12 and button.get_theme_font("font").get_string_size(button.text, HORIZONTAL_ALIGNMENT_LEFT, -1, command_pixels).x > width:
				command_pixels -= 1
			button.add_theme_font_size_override("font_size", command_pixels)
		if commands.visible: lane_height = commands.get_combined_minimum_size().y
		commands.size = Vector2(width, lane_height)
		if meter.visible:
			body.size.y = maxf(38, body.get_content_height())
			meter.position = Vector2(0, body.size.y + 4)
			meter.size = Vector2(width, 6)
			lane_height = meter.position.y + 6
	size = Vector2(width, lane_height)

func _sync_commands(list: Array) -> void:
	var key := JSON.stringify(list) + TranslationServer.get_locale()
	if key == _command_key: return
	_command_key = key
	for child in commands.get_children():
		commands.remove_child(child)
		child.queue_free()
	for command: Dictionary in list:
		if command.status != "pending": continue
		var button := Button.new()
		button.name = "Command%d" % commands.get_child_count()
		button.text = View.command_text(command)
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		var pending: bool = command.status == "pending"
		button.disabled = not pending
		button.custom_minimum_size.y = 24 if pending else 20
		button.add_theme_font_size_override("font_size", 14)
		for state_name in ["normal", "hover", "pressed", "disabled"]: button.add_theme_stylebox_override(state_name, StyleBoxEmpty.new())
		button.add_theme_color_override("font_color", View.accent("snake"))
		button.add_theme_color_override("font_hover_color", Color.WHITE)
		button.add_theme_color_override("font_disabled_color", Color("93c49a") if command.status == "fulfilled" else PresentationTheme.DANGER if command.status == "violated" else PresentationTheme.MUTED)
		button.tooltip_text = button.text + "\n" + ZodiacCatalog.words("Select the suggested cards, then use the table action.", "Chọn các lá gợi ý, rồi dùng hành động trên bàn.")
		button.pressed.connect(_select_command.bind(command))
		commands.add_child(button)
	if commands.get_child_count() == 0:
		var empty := Button.new()
		empty.text = ZodiacCatalog.words("—", "—")
		empty.disabled = true
		empty.add_theme_stylebox_override("disabled", StyleBoxEmpty.new())
		commands.add_child(empty)

func _select_command(command: Dictionary) -> void:
	if not visible or host.interactions.locked or command.status != "pending": return
	# Selection is a convenience, never a second action/obedience path.
	var ids: Array = command.get("suggested_ids", [command.get("card_id", "")])
	var cards: Array[CardData] = []
	for card: CardData in host.deal.hand:
		if card.unique_id in ids: cards.append(card)
	if not host.set_card_selection(cards, int(command.get("meld_id", -1))): return
	(host.extend_button if command.action == "extension" else host.ha_button if command.action == "new_meld" else host.drink_table_button if command.action == "drink" else host.discard_button).grab_focus()

func _sync_faces(ids: Array) -> void:
	var cards: Array[CardData] = []
	for card: CardData in host.deal.deck.discard_pile:
		if card.unique_id in ids: cards.append(card)
	var key := str(cards.map(func(card: CardData): return card.unique_id))
	if key == _face_key: return
	_face_key = key
	for child in faces.get_children():
		faces.remove_child(child)
		child.queue_free()
	for card in cards:
		var face := TextureRect.new()
		face.texture = load(card.texture_path())
		face.custom_minimum_size = Vector2(26, 36)
		face.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		face.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		face.mouse_filter = Control.MOUSE_FILTER_IGNORE
		faces.add_child(face)
		var slash := ColorRect.new()
		slash.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		slash.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var ink := ShaderMaterial.new()
		ink.shader = preload("res://shaders/tiger_claws.gdshader")
		slash.material = ink
		face.add_child(slash)
