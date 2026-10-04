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
	hide()

func sync(state: Dictionary) -> void:
	var id: String = state.get("id", "")
	active = id in ["pig", "ox", "horse", "goat", "rat", "tiger", "snake", "dragon"]
	visible = active
	if not active: return
	caption.text = String(state.skill)
	caption.add_theme_color_override("font_color", View.accent(id))
	var copy := ""
	var progress := 0.0
	match id:
		"pig":
			copy = ZodiacCatalog.words("HELD %s · Gross %s / %s", "GIỮ %s · Tổng thu %s / %s") % [VndWallet.format_vnd(int(state.pool_vnd)), VndWallet.format_vnd(int(state.progress_vnd)), VndWallet.format_vnd(int(state.target_vnd))]
			copy += "\n" + (ZodiacCatalog.words("Target met · pool returned", "Đạt mục tiêu · đã hoàn quỹ") if state.target_met else ZodiacCatalog.words("%d%% held until the target", "Giữ %d%% tới mục tiêu") % int(ZodiacCatalog.tuning(id, "siphon_percent", state.difficulty)))
			progress = float(state.progress_vnd) / maxf(int(state.target_vnd), 1)
		"ox":
			copy = ZodiacCatalog.words("Next burden is shown on each loose card.\nPlay or discard a card to remove its burden.", "Gánh nặng lần tới hiện trên từng lá rác.\nHạ, nối hoặc bỏ lá để hết gánh nặng.")
		"horse":
			var action := String(state.required_action)
			copy = ZodiacCatalog.words("Meld twice or Extend twice", "Tạo hai Phỏm hoặc Nối hai lần") if action.is_empty() else "%s · %d/2" % [ZodiacCatalog.action_label(action), int(state.pair_count)]
			copy += "\n" + (ZodiacCatalog.words("Pair complete · choose your discard", "Đủ cặp · tự chọn lá bỏ") if int(state.pair_count) >= 2 else ZodiacCatalog.words("Grace available: %d", "Còn %d lần ân hạn") % int(state.pair_grace) if int(state.pair_grace) > 0 else ZodiacCatalog.words("Incomplete pair → random mandatory discard", "Chưa đủ cặp → bỏ bắt buộc ngẫu nhiên"))
			if int(state.difficulty) == ZodiacCatalog.UNPLEASED: copy += ZodiacCatalog.words(" · 2 turns / Phase", " · 2 lượt / Hiệp")
			progress = int(state.pair_count) / 2.0
		"goat":
			copy = ZodiacCatalog.words("NEXT RANK: ", "HẠNG TIẾP: ") + (DeckManager.RANKS[int(state.expected_rank) - 1] if int(state.expected_rank) > 0 else ZodiacCatalog.words("choose the first note", "chọn nhịp đầu"))
			copy += "\n" + (ZodiacCatalog.words("Start with an ODD Rank", "Mở bằng hạng LẺ") if int(state.turn_number) % 2 else ZodiacCatalog.words("Start with an EVEN Rank", "Mở bằng hạng CHẴN")) if int(state.difficulty) == ZodiacCatalog.UNPLEASED else "\n" + ZodiacCatalog.words("Ascending committed ranks · K → A", "Hạng vừa đánh tăng liên tiếp · K → A")
			if int(state.rhythm_grace) > 0: copy += ZodiacCatalog.words(" · %d grace", " · %d lần tha") % int(state.rhythm_grace)
		"rat":
			copy = ZodiacCatalog.words("Mouse owns %d Meld(s) · Last loss %s", "Tý giữ %d Phỏm · Vừa mất %s") % [host.deal.boss_melds.size(), VndWallet.format_vnd(absi(int(state.get("hostile_result", {}).get("amount_vnd", 0))))]
			copy += "\n" + ZodiacCatalog.words("Discarded cards can pay Mouse. See its Melds in ?.", "Bài bỏ có thể trả thưởng cho Tý. Xem Phỏm của Tý ở ?.")
		"tiger":
			copy = ZodiacCatalog.words("SNATCHED %d · your turn continues", "ĐÃ VỒ %d LÁ · lượt vẫn tiếp tục") % state.get("removed_ids", []).size()
			if int(state.difficulty) == ZodiacCatalog.UNPLEASED: copy += "\n" + ZodiacCatalog.words("Exhaustion recycles cards; no bonus.", "Cạn bài vẫn xáo lại; không có thưởng.")
		"snake":
			copy = ""
			_sync_commands(state.get("commands", []))
		"dragon":
			copy = ZodiacCatalog.tactic_label(state.tactic) + " · " + ZodiacCatalog.words("Earned %s / %s", "Đã thu %s / %s") % [VndWallet.format_vnd(int(state.progress_vnd)), VndWallet.format_vnd(int(state.target_vnd))]
			var modifier: String = state.get("modifier_id", "")
			copy += "\n[color=#%s]%s · %s[/color]" % [View.accent(modifier).to_html(false), ZodiacCatalog.display_name(modifier), ZodiacCatalog.modifier_text(state, host.deal)]
			progress = float(state.progress_vnd) / maxf(int(state.target_vnd), 1)
	if body.text != copy: body.text = copy
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
	tooltip_text = String(state.rule)

func fit_width(width: float) -> void:
	body.size.x = width
	commands.size.x = width
	var pixels := 15
	# Long Dragon modifiers get the full lane, rather than hiding the requirement.
	body.add_theme_font_size_override("normal_font_size", pixels)
	while pixels > 12 and body.get_content_height() > 64:
		pixels -= 1
		body.add_theme_font_size_override("normal_font_size", pixels)
	var text_height := maxf(body.get_content_height(), 36)
	if commands.visible:
		for button: Button in commands.get_children():
			button.add_theme_font_size_override("font_size", 14)
		lane_height = commands.get_combined_minimum_size().y + 20
	else:
		lane_height = minf(text_height + 22, 90)
		if faces.visible and faces.get_child_count() > 0:
			faces.position.y = text_height + 20
			lane_height = faces.position.y + 38
		if meter.visible:
			meter.position.y = text_height + 22
			meter.size = Vector2(width, 6)
			lane_height = meter.position.y + 8
	size = Vector2(width, lane_height)

func _sync_commands(list: Array) -> void:
	var key := JSON.stringify(list) + TranslationServer.get_locale()
	if key == _command_key: return
	_command_key = key
	for child in commands.get_children():
		commands.remove_child(child)
		child.queue_free()
	var first_pending := true
	for command: Dictionary in list:
		var button := Button.new()
		button.name = "Command%d" % commands.get_child_count()
		button.text = View.command_text(command)
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		var pending: bool = command.status == "pending"
		button.disabled = not pending or not first_pending
		if pending: first_pending = false
		button.custom_minimum_size.y = 32 if pending else 20
		button.add_theme_font_size_override("font_size", 14)
		for state_name in ["normal", "hover", "pressed", "disabled"]: button.add_theme_stylebox_override(state_name, StyleBoxEmpty.new())
		button.add_theme_color_override("font_color", View.accent("snake"))
		button.add_theme_color_override("font_hover_color", Color.WHITE)
		button.add_theme_color_override("font_disabled_color", Color("93c49a") if command.status == "fulfilled" else PresentationTheme.DANGER if command.status == "violated" else PresentationTheme.MUTED)
		button.tooltip_text = button.text + "\n" + ZodiacCatalog.words("Select the suggested cards, then use the table action.", "Chọn các lá gợi ý, rồi dùng hành động trên bàn.")
		button.pressed.connect(_select_command.bind(command))
		commands.add_child(button)
	if list.is_empty():
		var empty := Button.new()
		empty.text = ZodiacCatalog.words("No commands this turn", "Lượt này không có lệnh")
		empty.disabled = true
		empty.add_theme_stylebox_override("disabled", StyleBoxEmpty.new())
		commands.add_child(empty)

func _select_command(command: Dictionary) -> void:
	if not visible or host.interaction_locked or command.status != "pending": return
	# Selection is a convenience, never a second action/obedience path.
	host.selected_card_ids.clear()
	var ids: Array = command.get("suggested_ids", [command.get("card_id", "")])
	for card: CardData in host.deal.hand:
		if card.unique_id in ids: host.selected_card_ids[card.unique_id] = true
	host.selected_meld_id = int(command.get("meld_id", -1))
	host._sync_all()
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
