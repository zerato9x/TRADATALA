class_name MatchUI
extends Control

signal action_rejected()

const CARD_SIZE := PlayingCardView.CARD_SIZE
const MUSIC_BAND_COUNT := 4
const GAME_SETTINGS_SCRIPT := preload("res://scripts/settings/game_settings.gd")
const CARD_DRAG_PAYLOAD_SCRIPT := preload("res://scripts/ui/card_drag_payload.gd")
const EVENT_TABLE_CONTROLLER_SCRIPT := preload("res://scripts/ui/event_table_controller.gd")
const DRINK_CUE_STREAMS: Array[AudioStream] = [
	preload("res://assets/audio/sfx/glass_clink.mp3"),
	preload("res://assets/audio/sfx/glass_clink_2.mp3"),
	preload("res://assets/audio/sfx/glass_clink_3.mp3"),
]
const CARD_SFX_CHOOSE := &"choose"
const CARD_SFX_PLACE := &"place"
const CARD_SFX_DRAW := &"draw"
const CARD_SFX_SHUFFLE := &"shuffle"
const CARD_CHOOSE_STREAM := preload("res://assets/audio/sfx/card_choose.wav")
const CARD_DRAW_STREAM := preload("res://assets/audio/sfx/card_draw.wav")
const CARD_SHUFFLE_STREAM := preload("res://assets/audio/sfx/card_shuffle.wav")
const CARD_PLACE_STREAMS: Array[AudioStream] = [
	preload("res://assets/audio/sfx/card_place.mp3"),
	preload("res://assets/audio/sfx/card_place_2.mp3"),
	preload("res://assets/audio/sfx/card_place_3.mp3"),
]
const TIME_ATLAS := preload("res://assets/environment/time.png")
const TIME_PERIOD_REGIONS := {
	"morning": Rect2(0, 0, 48, 48),
	"noon": Rect2(48, 0, 48, 48),
	"afternoon": Rect2(96, 0, 48, 48),
	"evening": Rect2(0, 48, 48, 48),
}
const DRINK_FULL_TEXTURES := {
	DrinkCatalog.TRA_DA: preload("res://assets/drinks/tra_da_full.png"),
	DrinkCatalog.NUOC_VOI: preload("res://assets/drinks/nuoc_voi_full.png"),
	DrinkCatalog.NHAN_TRAN: preload("res://assets/drinks/nhan_tran_full.png"),
	DrinkCatalog.SAM_DUA: preload("res://assets/drinks/sam_dua_full.png"),
}
const DRINK_HALF_TEXTURES := {
	DrinkCatalog.TRA_DA: preload("res://assets/drinks/tra_da_half.png"),
	DrinkCatalog.NUOC_VOI: preload("res://assets/drinks/nuoc_voi_half.png"),
	DrinkCatalog.NHAN_TRAN: preload("res://assets/drinks/nhan_tran_half.png"),
	DrinkCatalog.SAM_DUA: preload("res://assets/drinks/sam_dua_half.png"),
}
const DRINK_TABLE_MORNING_POSITION := Vector2(1033, 398)
const DRINK_TABLE_NOON_POSITION := Vector2(1033, 398)

var session := preload("res://scripts/campaign/run_session_coordinator.gd").new()
const INTERACTION_SCRIPT := preload("res://scripts/ui/match_interaction.gd")
var interactions := INTERACTION_SCRIPT.new()
var money_playback := preload("res://scripts/ui/money_playback_queue.gd").new()
var money_feedback := preload("res://scripts/ui/money_feedback.gd").new()
var music := preload("res://scripts/audio/match_music.gd").new()

var deal := DealState.new()
var event_manager: EventManager
var drink_manager: DrinkManager
var campaign: CampaignManager
var zodiac_table: Control
var zodiac_boss_hud: Control
var deck_screen: DeckScreen
var deck_canvas_layer: CanvasLayer
var current_campaign_event: EventInstance
var card_table := preload("res://scripts/ui/card_table_presentation.gd").new()
var pile_archive := preload("res://scripts/ui/pile_archive.gd").new()
var sort_mode: int = 0
var modal_mode: String = ""
var game_started: bool = false
var menu_transitioning: bool = false
var settings

var game_layer: Control
var menu_layer: Control
var menu_button: Button
var _menu_interaction_was_locked := false
var _collection_departing := false
var relic_grid: GridContainer
var drink_name_label: Label
var drink_charge_outline: Control
var drink_table_button: Button
var drink_table_texture: TextureRect
var pending_drink_unlocks: Array[String] = []
var unlock_notice_playing := false
var drink_hover_active: bool = false
var drink_cue_player: AudioStreamPlayer
var drink_cue_active: bool = false
var drink_cue_signature: String = ""
var drink_cue_stream_index: int = -1
var drink_cue_play_count: int = 0
var card_sfx_players: Dictionary = {}
var card_place_stream_index: int = -1
var card_sfx_play_counts := {
	CARD_SFX_CHOOSE: 0,
	CARD_SFX_PLACE: 0,
	CARD_SFX_DRAW: 0,
	CARD_SFX_SHUFFLE: 0,
}

var earnings_value: Label
var vnd_per_point_value: Label
var _scoring_rate_override_vnd := 0
var wallet_value: Label
var wallet_pile_anchor: Control
var campaign_value: Label
var campaign_period_icon: TextureRect
var campaign_period_value: Label
var campaign_period_textures: Dictionary = {}
var header_caption_labels: Dictionary = {}
var draw_count: Label
var discard_count_label: Label
var pile_caption_labels: Dictionary = {}
var pile_archive_buttons: Dictionary = {}
var discard_texture: TextureRect
var status_label: Label
var table_surface: Control
var hand_layer: Control
var meld_scroll: ScrollContainer
var meld_row: HBoxContainer
var empty_meld_label: Label
var discard_history_row: HBoxContainer
var discard_history_title: Label
var draw_pile_visual: Control
var discard_pile_visual: Control
var ha_button: Button
var extend_button: Button
var discard_button: Button
var settle_button: Button
var hint_button: Button
var sort_button: Button
var relic_title_label: Label
var particle_layer: Control
var quick_drink_input: Node


var ui_feedback: UIFeedback
var _banner_tween: Tween
var money_presentation: MoneyPresentation
var score_overlay: Control
var score_panel: Control
var score_title: Label
var score_line_a: Label
var score_line_b: Label
var score_payout: Label

var modal_overlay: Control
var modal_title: Label
var modal_kicker: Label
var modal_body: Label
var modal_detail: Label
var modal_primary: Button
var modal_secondary: Button

var banner_panel: PanelContainer
var banner_label: Label

var boss_debug_toolbar: PanelContainer
var _boss_lab_hidden_modal := false
var _boss_lab_hidden_receipt := false
var run_seed_input := ""
var front_end: FrontEnd
var resolve_receipt: Control
var campaign_money_hud: CanvasLayer
var table_hud_presentation: Node
var strawy: StrawyController
var resolve_mode := ""
var event_services := preload("res://scripts/ui/event_table_services.gd").new()
var event_table: EventTableController
var pending_deal_presentation_unlock: bool = false
var wallet_spiral: Control
var wallet_click_times: Array[int] = []


func _ready() -> void:
	interactions.configure(deal)
	theme = PresentationTheme.create_game_theme()
	var text_reveal := preload("res://scripts/ui/text_reveal.gd").new()
	text_reveal.name = "TextReveal"
	add_child(text_reveal)
	_bind_editor_interface()
	add_child(card_table)
	card_table.configure(deal, interactions, {"hand_layer": hand_layer, "draw_pile_visual": draw_pile_visual,
		"meld_row": meld_row, "empty_meld_label": empty_meld_label, "draw_count": draw_count,
		"discard_count_label": discard_count_label, "discard_texture": discard_texture,
		"discard_history_row": discard_history_row, "discard_history_title": discard_history_title,
		"particle_layer": particle_layer, "table_surface": table_surface,
		"discard_pile_visual": discard_pile_visual, "drink_table_button": drink_table_button})
	card_table.card_pressed.connect(_on_card_pressed)
	card_table.card_drag_started.connect(_on_card_drag_started)
	card_table.meld_pressed.connect(select_meld)
	card_table.meld_card_pressed.connect(select_meld_card)
	card_table.discard_pressed.connect(target_drink_discard)
	add_child(pile_archive)
	pile_archive.configure(deal, interactions, game_layer.get_node("DiscardArchiveOverlay"))
	pile_archive.discard_selected.connect(target_drink_discard)
	for pile in [draw_pile_visual, discard_pile_visual]:
		for face in pile.find_children("*", "TextureRect", true, false):
			face.add_child(preload("res://scripts/ui/passive_card_sway.gd").new())
	if DemoBuild.enabled():
		relic_title_label.get_parent().hide()
	add_child(money_playback)
	money_playback.configure(money_presentation, _return_exhaustion_visual)
	money_playback.balance_presented.connect(func(_balance): _refresh_stats())
	money_presentation.configure(wallet_value, wallet_pile_anchor)
	add_child(money_feedback)
	money_feedback.configure(deal, money_playback, hand_layer, meld_scroll, wallet_pile_anchor,
		_scoring_card_control, _reveal_scoring_card, _pulse_relic, _show_scoring_rate, _present_scoring_suppression)
	money_presentation.major_event_started.connect(func(_reason: String): ui_feedback.play(&"jackpot"))
	money_presentation.major_event_finished.connect(func(): ui_feedback.stop(&"jackpot"))
	deal.relics.inventory_changed.connect(_refresh_relics)
	_refresh_relics()
	_setup_event_table_presentation()
	_connect_editor_interface_signals()
	interactions.locked = true
	settings = get_node_or_null("/root/GameSettings")
	if settings == null:
		settings = GAME_SETTINGS_SCRIPT.new()
		settings.name = "GameSettings"
		get_tree().root.add_child(settings)
	settings.locale_changed.connect(_on_locale_changed)
	_setup_drink_cue_audio()
	_setup_card_sfx_audio()
	ui_feedback = UIFeedback.new()
	ui_feedback.name = "UIFeedback"
	add_child(ui_feedback)
	quick_drink_input = preload("res://scripts/ui/quick_drink_input.gd").new()
	quick_drink_input.name = "QuickDrinkInput"
	add_child(quick_drink_input)
	money_presentation.impact_requested.connect(ui_feedback.money_impact)
	money_presentation.transfer_requested.connect(ui_feedback.play.bind(&"transition"))
	for action in [[ha_button, "meld"], [extend_button, "extend"], [discard_button, "discard"], [settle_button, "settle"]]:
		for style in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
			(action[0] as Button).add_theme_color_override(style, ActionVocabulary.color_for(action[1]))
	_refresh_localized_ui()
	get_viewport().size_changed.connect(_on_viewport_size_changed)
	var result := deal.start_deal(-1, true)
	money_playback.displayed_balance = deal.wallet.balance_vnd
	money_playback.queued_balance = money_playback.displayed_balance
	event_manager = EventManager.new()
	CampaignNpcCatalog.register_initial_npcs(event_manager)
	deal.relics.shop_wallet = deal.wallet
	drink_manager = DrinkManager.new(deal.wallet)
	drink_manager.progress = DrinkProgress.new()
	drink_manager.progress.drink_unlocked.connect(_on_drink_unlocked)
	deal.state_changed.connect(_on_demo_progress_action)
	campaign = CampaignManager.new(deal.wallet, event_manager, drink_manager)
	campaign.bind_deal(deal)
	interactions.selection_changed.connect(func():
		if not interactions.selected_ids.is_empty(): campaign.onboarding.mark("selection"))
	add_child(event_services)
	event_services.configure(event_table, campaign, deal, drink_manager)
	event_services.wallet_committed.connect(_on_event_wallet_committed)
	event_services.notice.connect(_show_banner)
	event_services.gieo_impact_requested.connect(_on_gieo_impact_requested)
	event_services.reels_stop_requested.connect(ui_feedback.stop.bind(&"reels"))
	event_services.commitment_changed.connect(_on_gieo_commitment_changed)
	event_services.card_pick_requested.connect(_open_gieo_card_picker)
	event_services.identity_pick_requested.connect(_open_identity_card_picker)
	event_services.identity_feedback_requested.connect(func(cue): ui_feedback.play(cue))
	event_services.removal_pick_requested.connect(_open_removal_card_picker)
	campaign.relic_shop.changed.connect(_on_shop_changed)
	event_services.drink_order_requested.connect(_on_campaign_drink_pressed)
	event_services.debt_briefing_seen.connect(_on_debt_briefing_seen)
	event_services.zodiac_requested.connect(func(): zodiac_table.open_conversation())
	event_services.handbook_requested.connect(open_handbook)
	add_child(music)
	music.configure(settings, $ReactiveMusic, campaign, deal, func(): return game_started)
	music.controller.band_pulse.connect(_on_music_band_pulse)
	music.notice.connect(func(en, vi): _show_banner(GameGlossary.words(en, vi)))
	session.save_files = MetaSaveFiles.new()
	session.save_files.attach(campaign)
	session.run_save = RunSave.new(session.save_files.run_path())
	_connect_signal_once(drink_manager.progress.drink_unlocked, _on_drink_unlocked)
	campaign.zodiac.bind(campaign, deal)
	campaign.zodiac.changed.connect(_sync_event_continue)
	deal.wallet.balance_changed.connect(_on_wallet_balance_changed)
	campaign.relic_shop.runtime = deal.relics
	_setup_run_saving()
	campaign.lottery.settled.connect(_on_lottery_settled)
	campaign.collection_requested.connect(_on_collection_requested)
	campaign.campaign_started.connect(_on_campaign_started)
	campaign.event_started.connect(_on_campaign_event_started)
	campaign.deal_requested.connect(_on_campaign_deal_requested)
	campaign.requirement_passed.connect(_on_campaign_requirement_passed)
	campaign.campaign_won.connect(_on_campaign_won)
	campaign.campaign_lost.connect(_on_campaign_lost)
	campaign.deal_finished.connect(_on_demo_deal_finished)
	campaign_money_hud = preload("res://scripts/ui/campaign_money_hud.gd").new()
	add_child(campaign_money_hud)
	campaign_money_hud.configure(self)
	table_hud_presentation = preload("res://scripts/ui/table_hud_presentation.gd").new()
	add_child(table_hud_presentation)
	table_hud_presentation.configure(self)
	event_table.menu_requested.connect(_on_menu_pressed)
	front_end = preload("res://scenes/ui/front_end.tscn").instantiate() as FrontEnd
	menu_layer.add_child(front_end)
	front_end.configure(self)
	front_end.start_requested.connect(_on_front_start_requested)
	front_end.resume_requested.connect(_on_front_resume_requested)
	front_end.return_requested.connect(_close_menu_to_game)
	front_end.handbook_requested.connect(open_handbook)
	zodiac_table = preload("res://scripts/ui/zodiac_table.gd").new()
	game_layer.add_child(zodiac_table)
	zodiac_table.configure(self)
	zodiac_boss_hud = preload("res://scripts/ui/zodiac_boss_hud.gd").new()
	game_layer.add_child(zodiac_boss_hud)
	zodiac_boss_hud.configure(self)
	boss_debug_toolbar = preload("res://scripts/ui/boss_debug_toolbar.gd").new()
	game_layer.add_child(boss_debug_toolbar)
	boss_debug_toolbar.configure(self)
	if not InputMap.has_action(&"boss_debug_lab"):
		InputMap.add_action(&"boss_debug_lab")
		var debug_key := InputEventKey.new()
		debug_key.physical_keycode = KEY_F9
		InputMap.action_add_event(&"boss_debug_lab", debug_key)
	campaign.zodiac_endgame_choice_requested.connect(_show_zodiac_endgame_choice)
	deck_canvas_layer = CanvasLayer.new()
	deck_canvas_layer.name = "DeckCanvasLayer"
	deck_canvas_layer.layer = 310
	add_child(deck_canvas_layer)
	deck_screen = preload("res://scripts/ui/deck_screen.gd").new()
	deck_canvas_layer.add_child(deck_screen)
	deck_screen.closed.connect(_on_deck_screen_closed)
	strawy = preload("res://scripts/ui/strawy.gd").new()
	add_child(strawy)
	strawy.configure(self)
	event_table.input_obstructed = func() -> bool:
		return interaction_snapshot().blocked or score_overlay.visible or strawy.box.visible
	_sync_all(result, true)
	card_table.set_hand_interaction_enabled(false)
	_park_game_layer()
	music.initialize_jukebox.call_deferred()


func _exit_tree() -> void:
	if drink_cue_player != null:
		drink_cue_player.stop()
		drink_cue_player.stream = null
	for card_sfx_player in card_sfx_players.values():
		if card_sfx_player is AudioStreamPlayer:
			var player := card_sfx_player as AudioStreamPlayer
			player.stop()
			player.stream = null
	card_sfx_players.clear()
	if campaign == null:
		return
	var connections := [
		[&"campaign_started", Callable(self, "_on_campaign_started")],
		[&"event_started", Callable(self, "_on_campaign_event_started")],
		[&"deal_requested", Callable(self, "_on_campaign_deal_requested")],
		[&"requirement_passed", Callable(self, "_on_campaign_requirement_passed")],
		[&"campaign_won", Callable(self, "_on_campaign_won")],
		[&"campaign_lost", Callable(self, "_on_campaign_lost")],
	]
	for connection in connections:
		if campaign.is_connected(connection[0], connection[1]):
			campaign.disconnect(connection[0], connection[1])


func _bind_editor_interface() -> void:
	var nodes := find_children("*", "", true, false)
	var array_entries: Dictionary = {}
	var dictionary_bindings: Dictionary = {}
	var node_key_dictionary_bindings: Dictionary = {}
	for node in nodes:
		if node.has_meta("match_array_binding"):
			array_entries[String(node.get_meta("match_array_binding"))] = true
		if node.has_meta("match_dictionary_binding"):
			dictionary_bindings[String(node.get_meta("match_dictionary_binding"))] = true
		if node.has_meta("match_node_key_dictionary_binding"):
			node_key_dictionary_bindings[String(node.get_meta("match_node_key_dictionary_binding"))] = true
	for property_name in array_entries:
		var values: Array = get(property_name)
		values.clear()
	for property_name in dictionary_bindings:
		var values: Dictionary = get(property_name)
		values.clear()
	for property_name in node_key_dictionary_bindings:
		var values: Dictionary = get(property_name)
		values.clear()
	var sorted_array_entries: Dictionary = {}
	for node in nodes:
		if node.has_meta("match_binding"):
			set(String(node.get_meta("match_binding")), node)
		if node.has_meta("match_array_binding"):
			var property_name := String(node.get_meta("match_array_binding"))
			if not sorted_array_entries.has(property_name):
				sorted_array_entries[property_name] = []
			(sorted_array_entries[property_name] as Array).append({
				"index": int(node.get_meta("match_array_index", 0)),
				"node": node,
			})
		if node.has_meta("match_dictionary_binding"):
			var property_name := String(node.get_meta("match_dictionary_binding"))
			var values: Dictionary = get(property_name)
			values[String(node.get_meta("match_dictionary_key"))] = node
		if node.has_meta("match_node_key_dictionary_binding"):
			var property_name := String(node.get_meta("match_node_key_dictionary_binding"))
			var values: Dictionary = get(property_name)
			values[node] = String(node.get_meta("match_node_key_dictionary_value"))
	for property_name in sorted_array_entries:
		var entries: Array = sorted_array_entries[property_name]
		entries.sort_custom(func(left: Dictionary, right: Dictionary) -> bool: return left["index"] < right["index"])
		var values: Array = get(property_name)
		for entry in entries:
			values.append(entry["node"])


func _setup_event_table_presentation() -> void:
	if event_table != null:
		event_table.visible = false
		event_table.mouse_filter = Control.MOUSE_FILTER_IGNORE
	event_table = EVENT_TABLE_CONTROLLER_SCRIPT.new()
	event_table.name = "EventTableController"
	game_layer.add_child(event_table)
	event_table.configure_deal_nodes([
		game_layer.get_node("Header") as Control,
		game_layer.get_node("TableSurface") as Control,
		game_layer.get_node("LooseHand") as Control,
		game_layer.get_node("UtilityRail") as Control,
		game_layer.get_node("ActionDock") as Control,
	])
	_connect_signal_once(event_table.npc_focused, func(id): event_services.present_npc(id, current_campaign_event))
	_connect_signal_once(event_table.deal_presentation_ready, _on_event_table_deal_ready)
	_connect_signal_once(event_table.deck_inspect_requested, _on_event_deck_inspect_requested)


func _connect_editor_interface_signals() -> void:
	_connect_signal_once(menu_button.pressed, _on_menu_pressed)
	_connect_signal_once(drink_table_button.pressed, activate_drink)
	_connect_signal_once(drink_table_button.mouse_entered, _on_drink_hover_started)
	_connect_signal_once(drink_table_button.mouse_exited, _on_drink_hover_ended)
	_connect_signal_once((pile_archive_buttons["draw"] as Button).pressed, _on_draw_archive_pressed)
	_connect_signal_once((pile_archive_buttons["discard"] as Button).pressed, _on_discard_archive_pressed)
	_connect_signal_once(hint_button.pressed, _on_hint_pressed)
	_connect_signal_once(sort_button.pressed, _on_sort_pressed)
	_connect_signal_once(ha_button.pressed, _on_ha_pressed)
	_connect_signal_once(extend_button.pressed, _on_extend_pressed)
	_connect_signal_once(discard_button.pressed, _on_discard_pressed)
	_connect_signal_once(settle_button.pressed, _on_settle_pressed)
	_connect_signal_once(deal.meld_exhaustion_triggered, _on_deal_meld_exhaustion_triggered)
	_connect_signal_once(deal.exhaustion_triggered, _on_deal_exhaustion_triggered)
	_connect_signal_once(modal_primary.pressed, _on_modal_primary_pressed)
	_connect_signal_once(modal_secondary.pressed, _on_modal_secondary_pressed)
	_connect_signal_once(event_table.continue_button.pressed, _on_campaign_continue_pressed)


func _connect_signal_once(signal_ref: Signal, callable: Callable) -> void:
	if not signal_ref.is_connected(callable):
		signal_ref.connect(callable)


func _setup_drink_cue_audio() -> void:
	drink_cue_player = AudioStreamPlayer.new()
	drink_cue_player.name = "DrinkCuePlayer"
	drink_cue_player.bus = GameSettings.SOUND_BUS
	add_child(drink_cue_player)


func _setup_card_sfx_audio() -> void:
	for kind in [CARD_SFX_CHOOSE, CARD_SFX_PLACE, CARD_SFX_DRAW, CARD_SFX_SHUFFLE]:
		var player := AudioStreamPlayer.new()
		player.name = "Card%sPlayer" % String(kind).capitalize()
		player.bus = GameSettings.SOUND_BUS
		add_child(player)
		card_sfx_players[kind] = player


func _play_card_sfx(kind: StringName) -> void:
	var player := card_sfx_players.get(kind) as AudioStreamPlayer
	if player == null:
		return
	match kind:
		CARD_SFX_CHOOSE:
			player.stream = CARD_CHOOSE_STREAM
		CARD_SFX_DRAW:
			player.stream = CARD_DRAW_STREAM
		CARD_SFX_SHUFFLE:
			player.stream = CARD_SHUFFLE_STREAM
		CARD_SFX_PLACE:
			card_place_stream_index = (card_place_stream_index + 1) % CARD_PLACE_STREAMS.size()
			player.stream = CARD_PLACE_STREAMS[card_place_stream_index]
		_:
			return
	player.play()
	card_sfx_play_counts[kind] = int(card_sfx_play_counts.get(kind, 0)) + 1


func _sync_card_action_sfx(result: Dictionary, animated_cards: Array[CardData]) -> void:
	if not game_started:
		return
	if bool(result.get("shuffled", false)):
		_play_card_sfx(CARD_SFX_SHUFFLE)
	if not animated_cards.is_empty():
		_play_card_sfx(CARD_SFX_DRAW)


func _sync_drink_reactive_cue() -> void:
	if drink_cue_player == null:
		return
	var cue := deal.drink_cue_trigger()
	var active := bool(cue.get("active", false))
	if not active:
		drink_cue_active = false
		drink_cue_signature = ""
		return
	var signature := "%s:%s" % [cue.get("drink_id", ""), cue.get("trigger_id", "")]
	if drink_cue_active and drink_cue_signature == signature:
		return
	drink_cue_active = true
	drink_cue_signature = signature
	drink_cue_stream_index = (drink_cue_stream_index + 1) % DRINK_CUE_STREAMS.size()
	drink_cue_player.stream = UIFeedback.CUES[StringName("drink_" + deal.current_drink_id)][0]
	drink_cue_player.volume_db = -23.0
	drink_cue_player.play()
	drink_cue_play_count += 1


func _on_locale_changed(_locale_code: String) -> void:
	_refresh_localized_ui()


func _refresh_localized_ui() -> void:
	if zodiac_table != null: zodiac_table.refresh()
	if zodiac_boss_hud != null: zodiac_boss_hud.refresh()
	menu_button.text = tr("HUD_MENU")
	menu_button.tooltip_text = tr("HUD_MENU_TOOLTIP")
	discard_history_title.text = ZodiacCatalog.words("TURN REGISTER", "SỔ LƯỢT")
	(header_caption_labels.get("IncomeStat") as Label).text = tr("HUD_INCOME")
	(header_caption_labels.get("VndPerPointStat") as Label).text = tr("HUD_VND_PER_POINT")
	(header_caption_labels.get("WalletStat") as Label).text = tr("HUD_WALLET")
	(header_caption_labels.get("CampaignStat") as Label).text = tr("HUD_CAMPAIGN")
	empty_meld_label.text = tr("TABLE_EMPTY_MELD")
	(pile_caption_labels.get("draw") as Label).text = tr("PILE_DRAW")
	(pile_caption_labels.get("discard") as Label).text = tr("PILE_DISCARD")
	(pile_archive_buttons.get("draw") as Button).tooltip_text = tr("PILE_DRAW_TOOLTIP")
	(pile_archive_buttons.get("discard") as Button).tooltip_text = tr("PILE_DISCARD_TOOLTIP")
	relic_title_label.text = tr("HUD_RELICS")
	_refresh_relics()
	hint_button.text = tr("ACTION_HINT")
	hint_button.tooltip_text = tr("ACTION_HINT_TOOLTIP")
	sort_button.text = tr("ACTION_SORT_RANK") if sort_mode == 0 else tr("ACTION_SORT_SUIT")
	sort_button.tooltip_text = tr("ACTION_SORT_TOOLTIP")
	ha_button.text = tr("ACTION_MELD")
	ha_button.tooltip_text = tr("ACTION_MELD_TOOLTIP")
	extend_button.text = tr("ACTION_EXTEND")
	extend_button.tooltip_text = tr("ACTION_EXTEND_TOOLTIP")
	discard_button.text = tr("ACTION_DISCARD")
	discard_button.tooltip_text = tr("ACTION_DISCARD_TOOLTIP")
	settle_button.text = tr("ACTION_SETTLE")
	settle_button.tooltip_text = tr("ACTION_SETTLE_TOOLTIP")
	pile_archive.refresh_localized_ui()
	if event_table != null:
		event_table.refresh_localized_ui()
	if event_table.visible and current_campaign_event != null:
		_show_campaign_event(current_campaign_event)
		if not event_table.focused_npc_id.is_empty():
			event_services.present_npc(event_table.focused_npc_id, current_campaign_event)
	_sync_all()


func _on_music_band_pulse(band_index: int, strength: float) -> void:
	if is_instance_valid(wallet_spiral):
		wallet_spiral.pulse(band_index, strength)
		return
	if band_index < 0 or band_index >= MUSIC_BAND_COUNT:
		return
	if menu_layer != null and menu_layer.visible:
		return
	if not game_started or interactions.locked or modal_overlay.visible or score_overlay.visible or pile_archive.overlay.visible:
		return
	card_table.play_beat_pulse(band_index, strength, drink_hover_active or interactions.drink_targeting)


func _park_game_layer() -> void:
	if game_layer == null or game_started or menu_transitioning:
		return
	game_layer.position = Vector2(get_viewport_rect().size.x + 80.0, 0)


func _on_play_pressed() -> void:
	if menu_transitioning:
		return
	if game_started:
		menu_transitioning = true
		menu_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var close_tween := create_tween()
		close_tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		close_tween.tween_property(menu_layer, "modulate", Color(1, 1, 1, 0), 0.22)
		await close_tween.finished
		menu_layer.visible = false
		menu_layer.position = Vector2.ZERO
		menu_layer.modulate = Color.WHITE
		menu_transitioning = false
		interactions.locked = false
		card_table.set_hand_interaction_enabled(true)
		_start_campaign()
		return
	menu_transitioning = true
	menu_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var viewport_width := get_viewport_rect().size.x
	var tween := create_tween().set_parallel(true)
	tween.set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_OUT)
	tween.tween_property(game_layer, "position:x", 0.0, 0.72)
	tween.tween_property(menu_layer, "position:x", -viewport_width * 0.34, 0.62)
	tween.tween_property(menu_layer, "modulate", Color(1, 1, 1, 0), 0.48)
	await tween.finished
	menu_layer.visible = false
	game_started = true
	menu_transitioning = false
	_start_campaign()


func open_handbook(section: String = "") -> void:
	GameGlossary.open(self, section)


func reset_transient_presentation() -> void:
	interactions.selected_ids.clear()
	interactions.selected_meld_id = -1
	drink_hover_active = false
	_cancel_drink_targeting()
	if quick_drink_input != null:
		quick_drink_input.cancel()
	drink_cue_active = false
	drink_cue_signature = ""
	if drink_cue_player != null:
		drink_cue_player.stop()
	cancel_card_drag()
	modal_mode = ""
	if modal_overlay != null:
		modal_overlay.visible = false
	if pile_archive.overlay != null and pile_archive.overlay.visible:
		pile_archive.close()
	pending_deal_presentation_unlock = false
	money_feedback.clear_pending()
	for snapshot in meld_row.get_children():
		if snapshot.get_meta("exhaustion_snapshot", false):
			snapshot.queue_free()
	money_playback.cancel()


func _on_menu_pressed() -> void:
	if _collection_departing: return
	if not game_started or menu_transitioning or (interactions.locked and current_campaign_event == null) or modal_overlay.visible or score_overlay.visible or pile_archive.overlay.visible:
		return
	session.flush()
	_menu_interaction_was_locked = interactions.locked
	event_table.collector_arrival.stop()
	interactions.locked = true
	card_table.set_hand_interaction_enabled(false)
	front_end.show_home()
	menu_layer.position = Vector2.ZERO
	menu_layer.modulate = Color(1, 1, 1, 0)
	menu_layer.visible = true
	menu_layer.mouse_filter = Control.MOUSE_FILTER_STOP
	var tween := create_tween()
	tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(menu_layer, "modulate", Color.WHITE, 0.18)


func _close_menu_to_game() -> void:
	if not game_started or menu_transitioning or not menu_layer.visible:
		return
	menu_transitioning = true
	menu_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var tween := create_tween()
	tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.tween_property(menu_layer, "modulate", Color(1, 1, 1, 0), 0.16)
	await tween.finished
	menu_layer.visible = false
	menu_layer.modulate = Color.WHITE
	menu_transitioning = false
	interactions.locked = _menu_interaction_was_locked
	if _boss_lab_hidden_modal:
		modal_overlay.show()
		_boss_lab_hidden_modal = false
	if _boss_lab_hidden_receipt and is_instance_valid(resolve_receipt):
		resolve_receipt.resume_presentation()
		_boss_lab_hidden_receipt = false
	card_table.set_hand_interaction_enabled(not interactions.locked)
	_refresh_actions()


func _on_draw_archive_pressed() -> void:
	_toggle_pile_archive("draw")


func _on_discard_archive_pressed() -> void:
	_toggle_pile_archive("discard")


func _toggle_pile_archive(mode: String) -> void:
	if pile_archive.overlay.visible and pile_archive.mode == mode:
		pile_archive.close()
	else:
		pile_archive.mode = mode
		open_discard_archive()


func open_discard_archive() -> void:
	if not game_started or interactions.locked or modal_overlay.visible or (score_overlay.visible and not money_presentation.presentation_active):
		return
	pile_archive.open()


func _on_event_deck_inspect_requested() -> void:
	if current_campaign_event == null or event_table == null or not event_table.visible:
		return
	deck_screen.open_deck(campaign.gieo_que.persistent_deck, GameGlossary.words("Your deck", "Bộ bài của bạn"),
		GameGlossary.words("Your physical campaign cards. Sort, search, and inspect permanent changes.", "Các lá bài thật của chiến dịch. Sắp xếp, tìm kiếm và xem biến đổi vĩnh viễn."))


func _on_deck_screen_closed() -> void:
	if event_table != null and event_table.deck_focused:
		event_table.unfocus_npc()


func _open_gieo_card_picker(cards: Array[CardData], reason: String, callback: Callable) -> void:
	var available: Array[CardData] = []
	for card in cards:
		if not card.transformation_locked: available.append(card)
	deck_screen.open_deck(campaign.gieo_que.persistent_deck, tr("GIEO_CHOOSE_TARGET"), reason, available, callback)


func _open_identity_card_picker(cards: Array[CardData], reason: String, callback: Callable) -> void:
	deck_screen.open_deck(campaign.gieo_que.persistent_deck, tr("SHOE_PICK_TITLE"), reason, cards, callback, tr("SHOE_PICK_CONFIRM"))

func _on_shop_changed() -> void:
	_sync_event_continue()
	_refresh_stats()

func _open_removal_card_picker(cards: Array[CardData], reason: String, callback: Callable) -> void:
	deck_screen.open_deck(campaign.gieo_que.persistent_deck, GameGlossary.words("CARD REMOVAL · PAID", "BỎ BÀI · ĐÃ TRẢ TIỀN"), reason, cards, callback, GameGlossary.words("SELECT FOR REMOVAL", "CHỌN LÁ ĐỂ BỎ"))

func _sync_event_continue(committed: bool = false) -> void:
	if current_campaign_event == null or event_table == null:
		return
	var reason := ""
	var required_npc := ""
	for interaction in current_campaign_event.mandatory_interactions():
		if interaction.completed:
			continue
		required_npc = interaction.participant_id
		reason = ZodiacCatalog.words("Buy a drink from Auntie to continue.", "Mua nước ở quán cô để tiếp tục.") if interaction.action_type == "choose_drink" else ZodiacCatalog.words("Finish the required visit to continue.", "Hoàn thành cuộc gặp bắt buộc để tiếp tục.")
		break
	if committed and reason.is_empty():
		reason = ZodiacCatalog.words("Finish this reading before continuing.", "Xong lượt gieo quẻ rồi hãy tiếp tục.")
	var zodiac_pending := current_campaign_event.slot == EventManager.EventSlot.NOON and campaign.zodiac.has_open_interaction()
	if zodiac_pending:
		reason = ZodiacCatalog.words("Finish the Zodiac negotiation to continue.", "Xong cuộc thương lượng với Con Giáp rồi hãy tiếp tục.")
		required_npc = EventTableController.NPC_ZODIAC
	if campaign.relic_shop.removal_pending:
		reason = GameGlossary.words("Finish your paid card removal at Hàng Rong.", "Xong lượt bỏ bài đã trả tiền ở Hàng Rong rồi hãy tiếp tục.")
		required_npc = EventTableController.NPC_HANG_RONG
	event_table.set_continue_enabled(current_campaign_event.can_exit and not committed and not zodiac_pending and not campaign.relic_shop.removal_pending, reason, required_npc)

func _show_campaign_event(event: EventInstance) -> void:
	current_campaign_event = event
	interactions.locked = true
	card_table.set_hand_interaction_enabled(false)
	modal_overlay.visible = false
	var day: Dictionary = event.context.get("day", campaign.current_day())
	event_table.set_zodiac_visitor(campaign.zodiac.active_id(), campaign.zodiac.visitor_available(event.slot))
	event_table.enter_event(
		event.slot,
		CampaignText.day_name(campaign),
		tr(EventManager.slot_name_key(event.slot)),
		_event_money_text(deal.wallet.balance_vnd),
		campaign.gieo_que.persistent_deck.size()
	)
	if not event_table.cash_clicked.is_connected(_on_event_cash_clicked):
		event_table.cash_clicked.connect(_on_event_cash_clicked)
	_sync_event_continue()
	_refresh_stats()
	if event.slot == EventManager.EventSlot.STARTER and not event.completed_interactions.has("debt_intro"):
		event_table.focus_npc(EventTableController.NPC_DOI_NO)


func _on_lottery_settled(receipt: Dictionary) -> void:
	# Lottery Uncle appears in the Afternoon receipt; the Zodiac owns the table slot.
	_present_afternoon_results.call_deferred(receipt)

func _present_afternoon_results(receipt: Dictionary) -> void:
	if current_campaign_event != null and current_campaign_event.slot == EventManager.EventSlot.AFTERNOON:
		LotteryReceipt.show_receipt(self, receipt)
		var result_view := get_tree().root.get_node_or_null("LotteryReceipt")
		if result_view != null:
			result_view.find_child("CloseReceipt", true, false).pressed.connect(func():
				campaign.onboarding.mark("lottery_result")
				session.queue_save()
			)


func _on_wallet_balance_changed(_before: int, _after: int, _delta: int, reason: String) -> void:
	if reason.begins_with("zodiac_request:"):
		_on_event_wallet_committed.call_deferred()


func _on_event_wallet_committed() -> void:
	session.queue_save()
	money_playback.displayed_balance = deal.wallet.balance_vnd
	money_playback.queued_balance = money_playback.displayed_balance
	event_table.event_money_feedback(_event_money_text(money_playback.displayed_balance))
	_refresh_stats()


func _on_gieo_impact_requested(kind: StringName) -> void:
	match kind:
		&"lever": ui_feedback.play(&"lever")
		&"lever_clunk":
			ui_feedback.play(&"reels")
		&"result_reveal":
			ui_feedback.stop(&"reels")
			ui_feedback.play(&"gain")
		&"reel_stop":
			ui_feedback.play(&"reel_stop")
		&"jackpot":
			ui_feedback.stop(&"reels")
			ui_feedback.play(&"jackpot")
		&"transform", &"transform_card":
			ui_feedback.play(&"transition")
			if kind == &"transform":
				_show_banner(tr("GIEO_TRANSFORM_BANNER"))
		&"upper_reveal", &"lower_reveal":
			ui_feedback.play(&"gain", 0.7)
		_:
			ui_feedback.play(&"press")


func _on_gieo_commitment_changed(committed: bool) -> void:
	event_table.back_button.disabled = committed
	event_table.conversation.show_responses(true, not committed)
	if current_campaign_event != null:
		_sync_event_continue(committed)


func _release_deal_input() -> void:
	if menu_layer.visible:
		_menu_interaction_was_locked = false
	else:
		interactions.locked = false
		card_table.set_hand_interaction_enabled(true)

func _on_event_table_deal_ready() -> void:
	if not pending_deal_presentation_unlock:
		return
	var presentation_generation := money_playback.generation
	pending_deal_presentation_unlock = false
	money_feedback.drain_exhaustion()
	await money_feedback.drain_u_khan()
	if presentation_generation != money_playback.generation: return
	if resolve_mode.is_empty() and not modal_overlay.visible:
		_release_deal_input()
	_refresh_actions()


func _sync_all(result: Dictionary = {}, animate_all_cards: bool = false) -> void:
	_sync_passive_drink_sound(result)
	if zodiac_boss_hud != null:
		zodiac_boss_hud.refresh()
		zodiac_boss_hud.present_action(result)
		zodiac_boss_hud.present_events(result.get("boss_events", []))
	var animated_cards := _cards_from_result(result)
	if animate_all_cards:
		animated_cards.clear()
		animated_cards.append_array(deal.hand)
	_sync_card_action_sfx(result, animated_cards)
	card_table.sync_hand(animated_cards)
	card_table.sync_probabilities()
	card_table.sync_discard_history()
	card_table.sync_action_outlines()
	card_table.sync_melds()
	card_table.sync_reactive_targets()
	card_table.sync_piles()
	if pile_archive.overlay.visible:
		pile_archive.sync()
	if drink_name_label != null:
		drink_name_label.text = tr(DrinkCatalog.display_name(deal.current_drink_id)).to_upper()
		drink_table_button.tooltip_text = drink_tooltip()
		drink_charge_outline.set_drink_cue(not interactions.drink_swap_opportunities().is_empty() if deal.current_drink_id in [DrinkCatalog.NHAN_TRAN, DrinkCatalog.DEN_DA] else deal.current_drink_has_charge() or bool(deal.drink_cue_trigger().get("active", false)))
		_sync_drink_table_visual()
	_sync_drink_reactive_cue()
	_refresh_stats()
	_refresh_actions()


func _drink_is_spent_in_current_window() -> bool:
	match deal.current_drink_id:
		DrinkCatalog.TRA_DA:
			return deal.tra_da_used_this_turn
		DrinkCatalog.NHAN_TRAN:
			return deal.nhan_tran_used_this_phase
		DrinkCatalog.DEN_DA:
			return deal.den_da_used_this_turn
		DrinkCatalog.NAU_DA:
			return deal.nau_da_used_phases.has(deal.current_phase)
		DrinkCatalog.STING:
			return deal.pair_used_phases.has(deal.current_phase)
		DrinkCatalog.BO_HUC:
			return deal.pair_used_this_turn
		DrinkCatalog.C2_ICED_TEA:
			return deal.c2_used
		DrinkCatalog.NUOC_VOI:
			return deal.nuoc_voi_used_phases.has(deal.current_phase)
		DrinkCatalog.SAM_DUA, DrinkCatalog.BAC_XIU:
			return deal.current_phase == 2
	return false


func _sync_drink_table_visual() -> void:
	if drink_table_button == null or drink_table_texture == null:
		return
	var has_previous_drink := drink_manager != null and drink_manager.morning_drink_id != DrinkCatalog.NONE and drink_manager.afternoon_drink_id != DrinkCatalog.NONE
	drink_table_button.position = DRINK_TABLE_NOON_POSITION if has_previous_drink else DRINK_TABLE_MORNING_POSITION
	var spent: bool = _drink_is_spent_in_current_window()
	var textures: Dictionary = DRINK_HALF_TEXTURES if spent else DRINK_FULL_TEXTURES
	# Testing Drinks share the shop's filled placeholder glass; an empty glass
	# incorrectly suggests an unused Drink is exhausted or unavailable.
	var texture := textures.get(deal.current_drink_id, textures[DrinkCatalog.TRA_DA] if deal.current_drink_id != DrinkCatalog.NONE else null) as Texture2D
	drink_table_button.visible = texture != null
	drink_table_texture.texture = texture
	var tint: Color = Color.WHITE if DrinkCatalog.basic_ids().has(deal.current_drink_id) else DrinkShop.COLORS.get(DrinkCatalog.category(deal.current_drink_id), Color.WHITE)
	drink_table_texture.modulate = tint * (Color(0.94, 0.94, 0.94, 0.92) if spent else Color.WHITE)
	drink_table_button.tooltip_text = drink_tooltip()


func _refresh_relics() -> void:
	if event_table != null and event_table.visible:
		_refresh_stats()
	for child in relic_grid.get_children():
		relic_grid.remove_child(child)
		child.queue_free()
	for index in deal.relics.equipped.size():
		var slot := RelicSlot.new()
		relic_grid.add_child(slot)
		slot.configure(deal.relics.equipped[index], index)


func _pulse_relic(id: String) -> void:
	for slot in relic_grid.get_children():
		if slot is RelicSlot and slot.relic_id == id:
			(relic_grid.get_parent() as ScrollContainer).ensure_control_visible(slot)
			slot.trigger()
			money_presentation.pulse_scoring_card(slot, Color("#f5bf42"), 0.65)


func _show_scoring_rate(rate_vnd: int) -> void:
	_scoring_rate_override_vnd = rate_vnd if rate_vnd != deal.vnd_per_point else 0
	vnd_per_point_value.text = VndWallet.format_vnd(rate_vnd)
	vnd_per_point_value.tooltip_text = tr("HUD_VND_PER_POINT") + " · " + VndWallet.format_vnd(deal.vnd_per_point)


func _refresh_stats() -> void:
	var relic_area: Control = get_node("GameLayer/UtilityRail/RelicsArea")
	relic_area.offset_bottom = -260.0 if deal.zodiac_boss.id == "dragon" else -78.0
	vnd_per_point_value.text = VndWallet.format_vnd(_scoring_rate_override_vnd if _scoring_rate_override_vnd != 0 else deal.vnd_per_point)
	earnings_value.text = VndWallet.format_amount(deal.current_deal_earnings_vnd(), true)
	wallet_value.text = VndWallet.format_amount(money_playback.displayed_balance)
	money_presentation.sync_wallet(money_playback.displayed_balance)
	if campaign_value != null:
		if campaign == null or campaign.current_day().is_empty():
			campaign_value.text = "—"
		else:
			campaign_value.text = "%s  •  %s" % [
				CampaignText.day_name(campaign),
				VndWallet.format_vnd(campaign.daily_requirement()),
			]
			campaign_value.tooltip_text = GameGlossary.words("Run seed: ", "Hạt giống: ") + campaign.run_seed
	_refresh_campaign_period()
	if table_hud_presentation != null: table_hud_presentation.refresh()
	if event_table != null and event_table.visible and event_table.current_event_slot >= 0:
		event_table.money_label.text = _event_money_text(deal.wallet.balance_vnd)
		event_table.set_event_deck_count(campaign.gieo_que.persistent_deck.size())
		event_table.overview.sync(money_presentation, deal.wallet.balance_vnd, deal.relics.equipped, campaign.current_day_index, event_table.current_event_slot, campaign.daily_requirement(), campaign.campaign_days)


func _refresh_campaign_period() -> void:
	if campaign_period_icon == null or campaign_period_value == null:
		return
	var period := _current_campaign_period()
	if period == "dragon":
		campaign_period_value.text = GameGlossary.words("DRAGON", "THÌN")
		campaign_period_icon.texture = _campaign_period_texture("evening")
		campaign_period_icon.visible = campaign_period_icon.texture != null
		campaign_period_icon.tooltip_text = GameGlossary.words("DRAGON ENDGAME", "THỬ THÁCH THÌN")
		campaign_period_value.tooltip_text = campaign_period_icon.tooltip_text
		return
	if period.is_empty() or not TIME_PERIOD_REGIONS.has(period):
		campaign_period_value.text = "—"
		campaign_period_icon.texture = null
		campaign_period_icon.visible = false
		return
	campaign_period_value.text = tr(CampaignText.period_key(period))
	campaign_period_icon.texture = _campaign_period_texture(period)
	campaign_period_icon.visible = campaign_period_icon.texture != null
	campaign_period_icon.tooltip_text = campaign_period_value.text
	campaign_period_value.tooltip_text = campaign_period_value.text


func _current_campaign_period() -> String:
	if campaign == null:
		return ""
	var current_phase: int = campaign.current_phase
	if CampaignManager.DEAL_PHASE_TO_PERIOD.has(current_phase):
		return String(CampaignManager.DEAL_PHASE_TO_PERIOD[current_phase])
	if current_phase in [
		CampaignManager.CampaignPhase.STARTER_EVENT,
		CampaignManager.CampaignPhase.MORNING_DEAL,
		CampaignManager.CampaignPhase.MORNING_EVENT,
	]:
		return "morning"
	if current_phase in [
		CampaignManager.CampaignPhase.NOON_DEAL,
		CampaignManager.CampaignPhase.NOON_EVENT,
	]:
		return "noon"
	if current_phase in [
		CampaignManager.CampaignPhase.AFTERNOON_DEAL,
		CampaignManager.CampaignPhase.AFTERNOON_EVENT,
	]:
		return "afternoon"
	return ""


func _campaign_period_texture(period: String) -> AtlasTexture:
	if not TIME_PERIOD_REGIONS.has(period):
		return null
	var cached := campaign_period_textures.get(period) as AtlasTexture
	if cached != null:
		return cached
	var texture := AtlasTexture.new()
	texture.atlas = TIME_ATLAS
	texture.region = TIME_PERIOD_REGIONS[period]
	campaign_period_textures[period] = texture
	return texture


func _refresh_actions() -> void:
	card_table.sync_discard_targets()
	card_table.sync_action_outlines()
	if drink_charge_outline != null and deal.current_drink_id in [DrinkCatalog.NHAN_TRAN, DrinkCatalog.DEN_DA]:
		drink_charge_outline.set_drink_cue(not interactions.drink_swap_opportunities().is_empty())
	var selected := interactions.selected_cards()
	var quick_drink_meld := not deal.can_create_meld(selected) and deal.can_create_meld(selected, true)
	ha_button.text = tr("ACTION_DRINK_CONFIRM") if interactions.drink_targeting or quick_drink_meld else tr("ACTION_MELD")
	ha_button.tooltip_text = _drink_target_status() if interactions.drink_targeting or quick_drink_meld else tr("ACTION_MELD_TOOLTIP")
	hint_button.visible = true
	hint_button.text = tr("ACTION_DRINK_CANCEL") if interactions.drink_targeting else tr("ACTION_HINT")
	hint_button.tooltip_text = tr("ACTION_DRINK_CANCEL") if interactions.drink_targeting else tr("ACTION_HINT_TOOLTIP")
	if drink_table_button != null:
		drink_table_button.disabled = interactions.locked or deal.current_drink_id == DrinkCatalog.NONE or (not interactions.drink_targeting and not deal.current_drink_has_charge())
	var card_window := deal.state in [DealState.STATE_ACTIVE, DealState.STATE_FINAL_COMMIT_WINDOW] and not interactions.locked
	var active_turn := deal.state == DealState.STATE_ACTIVE and not interactions.locked
	ha_button.disabled = not card_window or not (deal.can_create_meld(selected) or (deal.can_create_meld(selected, true)))
	extend_button.disabled = not card_window or interactions.selected_meld_id < 0 or not deal.can_extend_meld(interactions.selected_meld_id, selected)
	discard_button.disabled = not active_turn or (selected.size() != 1 and not deal.hand.is_empty())
	if selected.size() == 1 and deal.zodiac_boss.is_locked(selected[0]): discard_button.disabled = true
	discard_button.text = GameGlossary.words("END EMPTY TURN", "KẾT THÚC LƯỢT TRỐNG") if deal.hand.is_empty() else tr("ACTION_DISCARD")
	discard_button.tooltip_text = tr("ACTION_DISCARD_TOOLTIP")
	var can_skip_tra_da_extra := deal.state == DealState.STATE_ACTIVE and deal.tra_da_extra_discard_pending
	settle_button.text = tr("ACTION_END_TURN") if can_skip_tra_da_extra else tr("ACTION_SETTLE")
	settle_button.tooltip_text = tr("ACTION_END_TURN_TOOLTIP") if can_skip_tra_da_extra else tr("ACTION_SETTLE_TOOLTIP")
	if deal.state == DealState.STATE_FINAL_COMMIT_WINDOW:
		settle_button.tooltip_text = _end_action_detail("settle")
	settle_button.disabled = (deal.state != DealState.STATE_FINAL_COMMIT_WINDOW and not can_skip_tra_da_extra) or interactions.locked
	hint_button.disabled = not card_window or deal.hand.is_empty()
	sort_button.disabled = not card_window or deal.hand.size() < 2
	if interactions.drink_targeting:
		ha_button.disabled = interactions.locked or not _can_confirm_drink()
		extend_button.disabled = true
		discard_button.disabled = true
		settle_button.disabled = true
		hint_button.disabled = interactions.locked
		sort_button.disabled = true
	if interactions.locked:
		status_label.text = tr("STATUS_RESOLVING")
		status_label.add_theme_color_override("font_color", PresentationTheme.MUTED)
		return
	if interactions.drink_targeting:
		status_label.text = _drink_target_status()
		status_label.add_theme_color_override("font_color", CardActionOutline.DRINK_HIGHLIGHT)
		return
	if deal.state == DealState.STATE_PHASE_CHOICE:
		status_label.text = tr("STATUS_PHASE_CHOICE")
		return
	if deal.state == DealState.STATE_DEAL_OVER:
		status_label.text = tr("STATUS_DEAL_OVER")
		return
	if deal.state == DealState.STATE_FINAL_COMMIT_WINDOW and selected.is_empty():
		status_label.text = tr("STATUS_LAST_CALL")
		status_label.add_theme_color_override("font_color", PresentationTheme.WARNING)
		return
	if deal.tra_da_extra_discard_pending and selected.is_empty():
		status_label.text = tr("STATUS_TRA_DA_EXTRA_DISCARD")
		status_label.add_theme_color_override("font_color", CardActionOutline.DRINK_HIGHLIGHT)
		return
	if selected.is_empty():
		status_label.text = tr("STATUS_CHOOSE")
		status_label.add_theme_color_override("font_color", PresentationTheme.MUTED)
	elif deal.can_create_meld(selected) or quick_drink_meld:
		var kind: String = deal.meld_creation_rule(selected, quick_drink_meld)["type"]
		var preview := deal.preview_new_meld_payout(selected, kind, deal.state == DealState.STATE_FINAL_COMMIT_WINDOW)
		var points: int = preview.points
		status_label.text = tr("STATUS_VALID_MELD") % [
			tr("MELD_RUN") if kind == MeldRules.TYPE_RUN else tr("MELD_SET"),
			points,
			VndWallet.format_vnd(VndWallet.points_to_vnd(points, deal.vnd_per_point), true),
		]
		status_label.add_theme_color_override("font_color", PresentationTheme.MONEY_GAIN)
	elif interactions.selected_meld_id >= 0 and deal.can_extend_meld(interactions.selected_meld_id, selected):
		var meld := deal.get_meld(interactions.selected_meld_id)
		var combined: Array[CardData] = meld.cards.duplicate()
		combined.append_array(selected)
		var preview := deal.preview_extension_payout(meld, selected, deal.state == DealState.STATE_FINAL_COMMIT_WINDOW)
		var points: int = preview.points
		status_label.text = tr("STATUS_VALID_EXTEND") % [
			interactions.selected_meld_id,
			points,
			VndWallet.format_vnd(VndWallet.points_to_vnd(points, deal.vnd_per_point), true),
		]
		status_label.add_theme_color_override("font_color", PresentationTheme.WARNING)
		if points == 0 and not String(preview.reason).is_empty(): status_label.text = ZodiacCatalog.feedback(preview.reason) + " · 0 VNĐ"
	elif selected.size() == 1:
		status_label.text = tr("STATUS_ONE_SELECTED")
		status_label.add_theme_color_override("font_color", PresentationTheme.INK)
	else:
		status_label.text = tr("STATUS_INVALID_MELD")
		status_label.add_theme_color_override("font_color", PresentationTheme.DANGER)


func _drink_target_status() -> String:
	match deal.current_drink_id:
		DrinkCatalog.DEN_DA:
			return tr("DRINK_TARGET_ANY_DISCARD")
		DrinkCatalog.NAU_DA:
			return tr("DRINK_TARGET_WHOLE_MELD")
		DrinkCatalog.STING, DrinkCatalog.BO_HUC:
			return tr("DRINK_TARGET_PAIR")
		DrinkCatalog.C2_ICED_TEA:
			return tr("DRINK_TARGET_RUN")
		DrinkCatalog.BAC_XIU:
			return tr("DRINK_TARGET_PRESERVE_ANY") % interactions.drink_ids.size()
	match deal.current_drink_id:
		DrinkCatalog.NHAN_TRAN, DrinkCatalog.DEN_DA:
			if interactions.drink_ids.is_empty() and interactions.drink_discard_key.is_empty():
				return tr("STATUS_DRINK_TARGETING_NHAN_TRAN")
			if interactions.drink_ids.is_empty():
				return tr("STATUS_DRINK_TARGETING_NHAN_TRAN_HAND")
			if interactions.drink_discard_key.is_empty():
				return tr("STATUS_DRINK_TARGETING_NHAN_TRAN_DISCARD")
			return tr("STATUS_DRINK_TARGETING_NHAN_TRAN")
		DrinkCatalog.SAM_DUA, DrinkCatalog.BAC_XIU:
			return tr("STATUS_DRINK_TARGETING_SAM_DUA") % interactions.drink_ids.size()
		_:
			return tr("STATUS_DRINK_TARGETING_ONE")


func _on_event_cash_clicked() -> void:
	if event_table.focused_npc_id.is_empty() and not event_table.deck_focused and not money_playback.running and deal.wallet.balance_vnd > 0:
		_try_wallet_easter_egg(event_table.overview.cash_anchor)


func _try_wallet_easter_egg(source: Control = null) -> void:
	var now := Time.get_ticks_msec()
	wallet_click_times = wallet_click_times.filter(func(t: int) -> bool: return now - t <= 650)
	wallet_click_times.append(now)
	if wallet_click_times.size() < 3 or is_instance_valid(wallet_spiral):
		return
	wallet_click_times.clear()
	wallet_spiral = preload("res://scripts/ui/wallet_spiral.gd").new()
	add_child(wallet_spiral)
	wallet_spiral.begin(money_presentation, deal.wallet.balance_vnd, game_layer, source)


func _input(event: InputEvent) -> void:
	if event.is_action_pressed(&"boss_debug_lab") and BossDebugSession.available():
		open_boss_lab()
		get_viewport().set_input_as_handled()
		return
	if zodiac_table != null and zodiac_table.shade.visible: return
	if strawy != null and strawy.box.visible: return
	if strawy != null and strawy.surface.visible and (event is InputEventMouseButton or event is InputEventScreenTouch) and strawy.actor.get_global_rect().has_point(event.position): return
	if get_tree().root.has_node("GameGlossary"):
		return
	if _try_fast_forward_money(event):
		return
	if event.is_action_pressed("ui_cancel") and event_table != null and event_table.is_visible_in_tree() and event_table.overview.expanded:
		event_table.overview.collapse()
		get_viewport().set_input_as_handled()
		return
	if is_instance_valid(wallet_spiral):
		if (event is InputEventKey and event.is_action_pressed(&"ui_cancel")) or (event is InputEventMouseButton and event.pressed):
			wallet_spiral.dismiss()
		get_viewport().set_input_as_handled()
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		if game_started and not interactions.locked and not money_playback.running and not menu_layer.visible and not modal_overlay.visible and not score_overlay.visible and not pile_archive.overlay.visible and deal.wallet.balance_vnd > 0:
			var wallet_panel := wallet_pile_anchor.get_parent().get_parent().get_parent() as Control
			if Rect2(Vector2.ZERO, wallet_panel.size).has_point(wallet_panel.get_global_transform_with_canvas().affine_inverse() * event.position):
				_try_wallet_easter_egg()
				if is_instance_valid(wallet_spiral):
					get_viewport().set_input_as_handled()
					return
			else:
				wallet_click_times.clear()
	if interactions.drag_payload == null:
		return
	if event is InputEventKey and event.is_action_pressed(&"ui_cancel"):
		get_viewport().set_input_as_handled()
		cancel_card_drag()
	elif event is InputEventMouseMotion:
		card_table.update_drag(event.position)
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
		var drop_position: Vector2 = event.position
		get_viewport().set_input_as_handled()
		_finish_card_drag(drop_position)


func _on_card_drag_started(card: CardData, global_position: Vector2, source: PlayingCardView) -> void:
	if interactions.locked or deal.state not in [DealState.STATE_ACTIVE, DealState.STATE_FINAL_COMMIT_WINDOW]:
		source.finish_drag_interaction()
		return
	if deal.zodiac_boss.is_locked(card):
		if zodiac_boss_hud != null: zodiac_boss_hud.react_locked_card(card)
		source.play_reject()
		source.finish_drag_interaction()
		return
	var payload_cards: Array[CardData] = [card]
	if interactions.drink_targeting and interactions.drink_ids.has(card.unique_id):
		payload_cards = interactions.pending_drink_cards()
	elif interactions.selected_ids.has(card.unique_id):
		payload_cards = interactions.selected_cards()
	interactions.drag_payload = CARD_DRAG_PAYLOAD_SCRIPT.new(
		CARD_DRAG_PAYLOAD_SCRIPT.SOURCE_HAND,
		-1,
		card.unique_id,
		payload_cards
	)
	card_table.begin_drag(interactions.drag_payload, source)
	card_table.update_drag(global_position)


func _finish_card_drag(global_position: Vector2) -> void:
	var payload = interactions.drag_payload
	var target := card_table.drop_target_at(global_position, drink_record_at(global_position))
	var source := card_table.clear_drag_visuals()
	interactions.drag_payload = null
	_perform_card_drop(payload, target, global_position, source)


func _perform_card_drop(payload, target: Dictionary, global_position: Vector2, source: PlayingCardView) -> void:
	if payload == null or interactions.locked:
		card_table.layout_hand(true)
		return
	if try_drink_card_drop(payload.cards, target):
		return
	if interactions.drink_targeting and target.get("kind") != MatchInteraction.DROP_TARGET_HAND:
		ui_feedback.play(&"reject")
		card_table.layout_hand(true)
		return
	var target_kind: StringName = target.get("kind", MatchInteraction.DROP_TARGET_NONE)
	if target_kind == MatchInteraction.DROP_TARGET_NONE:
		card_table.layout_hand(true)
		return
	var action := interactions.card_drag_action(payload, target)
	var drop_cards := interactions.cards_for_drop_target(payload, target)
	if drop_cards.is_empty():
		ui_feedback.play(&"reject")
		if source != null:
			source.play_reject()
		card_table.layout_hand(true)
		return
	match action:
		MatchInteraction.DRAG_ACTION_REORDER:
			_reorder_hand_card(drop_cards[0], global_position.x)
		MatchInteraction.DRAG_ACTION_CREATE_MELD:
			_apply_drag_selection(drop_cards, -1)
			_on_ha_pressed()
		MatchInteraction.DRAG_ACTION_EXTEND_MELD:
			_apply_drag_selection(drop_cards, int(target.get("meld_id", -1)))
			_on_extend_pressed()
		MatchInteraction.DRAG_ACTION_DISCARD:
			_apply_drag_selection(drop_cards, -1)
			_on_discard_pressed()


func _apply_drag_selection(cards: Array[CardData], meld_id: int) -> void:
	if not interactions.select(cards, meld_id): return
	if not cards.is_empty():
		_play_card_sfx(CARD_SFX_CHOOSE)
	card_table.layout_hand(true)
	card_table.sync_melds()
	card_table.sync_reactive_targets()
	_refresh_actions()


func _reorder_hand_card(card: CardData, global_x: float) -> bool:
	if card == null or not deal.hand.has(card):
		return false
	var reordered: Array[CardData] = []
	var insertion_index := 0
	for existing_card in deal.hand:
		if existing_card == card:
			continue
		var existing_view := card_table.hand_views.get(existing_card.unique_id) as PlayingCardView
		if existing_view != null and global_x > existing_view.get_global_rect().get_center().x:
			insertion_index += 1
		reordered.append(existing_card)
	insertion_index = clampi(insertion_index, 0, reordered.size())
	reordered.insert(insertion_index, card)
	var changed := deal.reorder_hand(reordered)
	card_table.layout_hand(true)
	card_table.sync_reactive_targets()
	return changed


func cancel_card_drag() -> void:
	card_table.clear_drag_visuals()
	interactions.drag_payload = null
	card_table.layout_hand(true)


func _on_card_pressed(card: CardData) -> void:
	if interactions.locked or deal.state not in [DealState.STATE_ACTIVE, DealState.STATE_FINAL_COMMIT_WINDOW]:
		return
	if zodiac_boss_hud != null and deal.zodiac_boss.is_locked(card):
		zodiac_boss_hud.react_locked_card(card)
	if interactions.drink_targeting:
		target_drink_card(card)
		return
	var selecting := not interactions.selected_ids.has(card.unique_id)
	if not interactions.toggle(card): return
	if selecting: _play_card_sfx(CARD_SFX_CHOOSE)
	interactions.drink_meld_id = -1
	interactions.drink_meld_card_id = ""
	card_table.layout_hand(true)
	card_table.sync_melds()
	card_table.sync_reactive_targets()
	_refresh_stats()
	_refresh_actions()


func select_meld(meld_id: int) -> void:
	if not interactions.locked and interactions.drink_targeting and deal.can_use_nau_da(meld_id):
		present_drink_result(deal.use_nau_da(meld_id))
		return
	if interactions.locked or deal.state not in [DealState.STATE_ACTIVE, DealState.STATE_FINAL_COMMIT_WINDOW]:
		return
	if interactions.drink_targeting:
		return
	interactions.selected_meld_id = -1 if interactions.selected_meld_id == meld_id else meld_id
	interactions.drink_meld_id = -1
	interactions.drink_meld_card_id = ""
	card_table.sync_melds()
	card_table.sync_reactive_targets()
	_refresh_actions()
func select_meld_card(meld_id: int, card: CardData) -> void:
	if not interactions.locked and interactions.drink_targeting and deal.can_use_nau_da(meld_id):
		present_drink_result(deal.use_nau_da(meld_id))
		return
	if interactions.locked or not interactions.drink_targeting or deal.current_drink_id != DrinkCatalog.NUOC_VOI:
		return
	if deal.state not in [DealState.STATE_ACTIVE, DealState.STATE_FINAL_COMMIT_WINDOW]:
		return
	if not deal.can_use_nuoc_voi(meld_id, card):
		_show_banner(tr("DRINK_NUOC_VOI_CARD_INVALID"))
		return
	_play_card_sfx(CARD_SFX_CHOOSE)
	interactions.drink_meld_id = meld_id
	interactions.drink_meld_card_id = card.unique_id
	card_table.sync_melds()
	_refresh_actions()
	recover_drink_card(meld_id, card)


func _on_drink_hover_started() -> void:
	drink_hover_active = true
	card_table.sync_discard_history()
	card_table.sync_action_outlines()
	card_table.sync_melds()
	card_table.pulse_drink_targets(0.7)


func _on_drink_hover_ended() -> void:
	drink_hover_active = false
	card_table.sync_discard_history()
	card_table.sync_action_outlines()
	card_table.sync_melds()


func _can_confirm_drink() -> bool:
	if deal.current_drink_id in [DrinkCatalog.STING, DrinkCatalog.BO_HUC, DrinkCatalog.C2_ICED_TEA]:
		return deal.can_create_meld(interactions.pending_drink_cards(), true)
	return deal.has_preservation_drink()


func activate_drink() -> void:
	if not interactions.drink_targeting:
		if commit_selected_drink(interactions.selected_cards()):
			return
		if deal.can_use_nau_da(interactions.selected_meld_id):
			present_drink_result(deal.use_nau_da(interactions.selected_meld_id))
			return
	if interactions.drink_targeting:
		if deal.current_drink_id in [DrinkCatalog.STING, DrinkCatalog.BO_HUC, DrinkCatalog.C2_ICED_TEA]:
			var cards := interactions.pending_drink_cards()
			if not deal.can_create_meld(cards, true):
				_reject_action(DrinkCatalog.effect_text(deal.current_drink_id))
				return
			present_drink_result(interactions.execute_drink("create", cards))
		elif deal.has_preservation_drink():
			var preserved := interactions.pending_drink_cards()
			present_drink_result(deal.select_sam_dua_preserves(preserved))
		else:
			_cancel_drink_targeting()
		return
	if not deal.current_drink_has_charge():
		_reject_action(tr("DRINK_NO_CHARGE"))
		return
	match deal.current_drink_id:
		DrinkCatalog.STING, DrinkCatalog.BO_HUC, DrinkCatalog.C2_ICED_TEA:
			if deal.drink_creation_target_ids([]).is_empty():
				_reject_action(tr("DRINK_NO_LEGAL_TARGET"))
				return
		DrinkCatalog.NAU_DA:
			if not deal.melds.any(func(meld: MeldState) -> bool: return deal.can_use_nau_da(meld.meld_id)):
				_reject_action(tr("DRINK_NO_LEGAL_TARGET"))
				return
		DrinkCatalog.NHAN_TRAN, DrinkCatalog.DEN_DA:
			if deal.drink_mandatory_discard_targets().is_empty():
				_reject_action(tr("DRINK_NHAN_TRAN_NO_DISCARD"))
				return
		DrinkCatalog.NUOC_VOI:
			if not _has_nuoc_voi_target():
				_reject_action(tr("DRINK_NUOC_VOI_NO_TARGET"))
				return
		DrinkCatalog.SAM_DUA, DrinkCatalog.BAC_XIU:
			if not deal.current_drink_has_charge():
				_reject_action(tr("DRINK_SAM_DUA_WRONG_TIME"))
				return
		_:
			_reject_action(tr("DRINK_NO_BASIC_EFFECT"))
			return
	var previous_selection := interactions.selected_cards()
	if deal.has_preservation_drink() and previous_selection.is_empty(): previous_selection.assign(deal.sam_dua_preserved_cards)
	interactions.drink_targeting = true
	interactions.drink_ids.clear()
	for card in previous_selection:
		if not deal.zodiac_boss.is_locked(card) and (deal.drink_creation_target_ids(interactions.pending_drink_cards()).has(card.unique_id) or (deal.has_preservation_drink() and interactions.drink_ids.size() < deal.preservation_limit()) or deal.current_drink_id in [DrinkCatalog.NHAN_TRAN, DrinkCatalog.DEN_DA]):
			interactions.drink_ids[card.unique_id] = true
	interactions.selected_ids.clear()
	interactions.selected_meld_id = -1
	interactions.drink_meld_id = -1
	interactions.drink_meld_card_id = ""
	interactions.drink_discard_key = ""
	_sync_all()
	var banner_key: String = {
		DrinkCatalog.NHAN_TRAN: "BANNER_DRINK_TARGET_NHAN_TRAN",
		DrinkCatalog.NUOC_VOI: "BANNER_DRINK_TARGET_ONE",
		DrinkCatalog.SAM_DUA: "BANNER_DRINK_TARGET_SAM_DUA",
	}.get(deal.current_drink_id, "BANNER_DRINK_TARGET_ONE")
	_show_banner(tr(banner_key) if DrinkCatalog.basic_ids().has(deal.current_drink_id) else _drink_target_status())


func target_drink_card(card: CardData) -> void:
	if deal.current_drink_id in [DrinkCatalog.STING, DrinkCatalog.BO_HUC, DrinkCatalog.C2_ICED_TEA]:
		if interactions.drink_ids.has(card.unique_id):
			interactions.drink_ids.erase(card.unique_id)
		else:
			if not deal.drink_creation_target_ids(interactions.pending_drink_cards()).has(card.unique_id):
				_show_banner(_drink_target_status())
				return
			interactions.drink_ids[card.unique_id] = true
		if deal.current_drink_id in [DrinkCatalog.STING, DrinkCatalog.BO_HUC] and deal.can_create_meld(interactions.pending_drink_cards(), true):
			present_drink_result(deal.create_meld(interactions.pending_drink_cards(), true))
			return
		_sync_all()
		return
	if deal.has_preservation_drink():
		if interactions.drink_ids.has(card.unique_id):
			interactions.drink_ids.erase(card.unique_id)
		elif interactions.drink_ids.size() < deal.preservation_limit():
			interactions.drink_ids[card.unique_id] = true
			_play_card_sfx(CARD_SFX_CHOOSE)
		else:
			var rejected_view := card_table.hand_views.get(card.unique_id) as PlayingCardView
			if rejected_view != null:
				rejected_view.play_reject()
			_show_banner(tr("BANNER_DRINK_SAM_DUA_LIMIT"))
			return
		_sync_all()
		_refresh_actions()
		return
	if deal.current_drink_id not in [DrinkCatalog.NHAN_TRAN, DrinkCatalog.DEN_DA]:
		return
	if card == null or not deal.hand.has(card):
		return
	_play_card_sfx(CARD_SFX_CHOOSE)
	interactions.drink_ids.clear()
	interactions.drink_ids[card.unique_id] = true
	var record := _selected_drink_discard_record()
	if record == null:
		_sync_all()
		_show_banner(tr("STATUS_DRINK_TARGETING_NHAN_TRAN_DISCARD"))
		pile_archive.mode = "discard"
		open_discard_archive()
		return
	if not (deal.can_use_nhan_tran(card, record) or deal.can_use_den_da(card, record)):
		_reject_action(tr("DRINK_DISCARD_TARGET_INVALID"))
		return
	_sync_all()
	swap_drink_card(card, record)


func target_drink_discard(record: DiscardRecord) -> void:
	if interactions.locked or not interactions.drink_targeting or record == null:
		return
	pile_archive.close()
	var target_keys := {}
	for candidate in deal.drink_mandatory_discard_targets():
		target_keys[candidate.target_key()] = true
	var target_key := record.target_key()
	if not target_keys.has(target_key):
		_show_banner(tr("DRINK_DISCARD_TARGET_INVALID"))
		return
	interactions.drink_discard_key = target_key
	var pending := interactions.pending_drink_cards()
	if deal.current_drink_id in [DrinkCatalog.NHAN_TRAN, DrinkCatalog.DEN_DA]:
		if pending.is_empty():
			_sync_all()
			_show_banner(tr("STATUS_DRINK_TARGETING_NHAN_TRAN_HAND"))
		else:
			_sync_all()
			swap_drink_card(pending[0], record)


func _selected_drink_discard_record() -> DiscardRecord:
	if interactions.drink_discard_key.is_empty():
		return null
	for record in deal.drink_mandatory_discard_targets():
		if record.target_key() == interactions.drink_discard_key:
			return record
	return null


func _discard_history_target_center(record: DiscardRecord) -> Vector2:
	if record != null:
		var holder := card_table.discard_history_target_holders.get(record.target_key()) as Control
		if holder != null:
			return holder.get_global_rect().get_center()
	return discard_texture.get_global_rect().get_center()


func swap_drink_card(card: CardData, record: DiscardRecord) -> void:
	interactions.locked = true
	_refresh_actions()
	_fly_cards([card] as Array[CardData], _discard_history_target_center(record))
	var result: Dictionary = interactions.execute_drink("swap", [card] as Array[CardData], -1, record)
	present_drink_result(result)


func recover_drink_card(meld_id: int, card: CardData) -> void:
	var presentation_generation := money_playback.generation
	interactions.locked = true
	_refresh_actions()
	await get_tree().create_timer(0.16).timeout
	if presentation_generation != money_playback.generation: return
	present_drink_result(interactions.execute_drink("recover_card", [card] as Array[CardData], meld_id))


func present_drink_result(result: Dictionary) -> void:
	if not result.get("ok", false):
		_release_deal_input()
		_sync_all()
		_reject_action(result.get("message", tr("DRINK_USE_FAILED")))
		return
	ui_feedback.play_drink(deal.current_drink_id)
	interactions.drink_targeting = false
	interactions.drink_ids.clear()
	interactions.selected_ids.clear()
	interactions.drink_meld_id = -1
	interactions.drink_meld_card_id = ""
	interactions.drink_discard_key = ""
	_release_deal_input()
	_sync_all(result)
	if result.has("context") and result["context"] is ScoringContext:
		interactions.selected_meld_id = int(result.get("meld_id", -1))
		money_feedback.queue_scoring(result["context"] as ScoringContext, meld_scroll)
	else:
		money_feedback.queue_zodiac_entries(result.get("boss_wallet_entries", []))
	var banner_key: String = {
		DrinkCatalog.TRA_DA: "BANNER_DRINK_TRA_DA",
		DrinkCatalog.NHAN_TRAN: "BANNER_DRINK_NHAN_TRAN",
		DrinkCatalog.NUOC_VOI: "BANNER_DRINK_NUOC_VOI",
		DrinkCatalog.SAM_DUA: "BANNER_DRINK_SAM_DUA",
	}.get(deal.current_drink_id, "BANNER_DRINK_USED")
	if deal.has_preservation_drink():
		_show_banner((tr("BANNER_DRINK_SAM_DUA") % result.get("preserved", []).size()).replace("SÂM DỨA", DrinkCatalog.display_name(deal.current_drink_id).to_upper()))
	else:
		_show_banner(tr(banner_key))


func _cancel_drink_targeting() -> void:
	pile_archive.close()
	interactions.reset_drink_targets()
	_sync_all()


func _has_nuoc_voi_target() -> bool:
	return not deal.nuoc_voi_targets().is_empty()


func drink_tooltip() -> String:
	var status := QuickInfo.drink(deal.current_drink_id)
	if deal.has_preservation_drink() and deal.sam_dua_used:
		status = tr("DRINK_SAM_DUA_SELECTED") % deal.sam_dua_preserved_cards.size()
	return "%s\n%s" % [DrinkCatalog.display_name(deal.current_drink_id), status]



func _on_ha_pressed() -> void:
	if ha_button.disabled:
		return
	if interactions.drink_targeting:
		activate_drink()
		return
	var selected := interactions.selected_cards()
	interactions.locked = true
	_refresh_actions()
	_fly_cards(selected, meld_scroll.get_global_rect().get_center())
	var use_drink := not deal.can_create_meld(selected)
	var result := deal.create_meld(selected, use_drink)
	if not result.get("ok", false):
		_reject_action(result.get("message", "Hạ failed."))
		return
	if use_drink:
		ui_feedback.play_drink(deal.current_drink_id)
	_play_card_sfx(CARD_SFX_PLACE)
	interactions.selected_ids.clear()
	interactions.selected_meld_id = result["meld_id"]
	_sync_all(result)
	money_feedback.queue_scoring(result["context"], card_table.meld_views.get(interactions.selected_meld_id) as Control)
	interactions.locked = false
	_refresh_actions()


func _on_extend_pressed() -> void:
	if extend_button.disabled:
		return
	var selected := interactions.selected_cards()
	interactions.locked = true
	_refresh_actions()
	_fly_cards(selected, meld_scroll.get_global_rect().get_center())
	var result := deal.extend_meld(interactions.selected_meld_id, selected)
	if not result.get("ok", false):
		_reject_action(result.get("message", "Extension failed."))
		return
	_play_card_sfx(CARD_SFX_PLACE)
	interactions.selected_ids.clear()
	_sync_all(result)
	money_feedback.queue_scoring(result["context"], card_table.meld_views.get(interactions.selected_meld_id) as Control)
	interactions.locked = false
	_refresh_actions()


func end_action_copy(kind: String) -> String:
	if kind == "discard":
		var cards := interactions.selected_cards()
		var action := GameGlossary.words("End Turn?", "Kết lượt?") if cards.is_empty() else GameGlossary.words("Discard %s?", "Bỏ %s?") % cards[0].short_label()
		if deal.current_drink_id == DrinkCatalog.TRA_DA and not deal.tra_da_extra_discard_pending:
			return action + "\n" + GameGlossary.words("Trà Đá: +1 optional discard", "Trà Đá: +1 lần bỏ tùy chọn")
		return action + "\n" + (GameGlossary.words("Last Call · no refill", "Chốt Hạ · không bù bài") if deal.discard_count + (0 if deal.tra_da_extra_discard_pending else 1) >= deal.phase_discard_limit() else GameGlossary.words("Deadwood · refill → 10", "Phạt bài rời · bù → 10"))
	if deal.tra_da_extra_discard_pending: return GameGlossary.words("Skip extra discard?\nDeadwood · refill", "Bỏ qua lần bỏ thêm?\nPhạt bài rời · bù bài")
	var message := GameGlossary.words("Settle Phase %d?", "Chốt Hiệp %d?") % deal.current_phase
	if deal.current_phase == 1:
		var kept: Array[String] = []
		if deal.has_preservation_drink():
			for card in deal.sam_dua_preserved_cards:
				if deal.hand.has(card): kept.append(card.short_label())
		var carry := ", ".join(kept) if not kept.is_empty() and kept.size() <= 3 else str(kept.size())
		message += "\n" + (GameGlossary.words("Keep %s · Replace %d · Deadwood", "Giữ %s · Thay %d · Phạt bài rời") % [carry, deal.hand.size() - kept.size()])
	else: message += "\n" + GameGlossary.words("End Deal · Deadwood", "Kết Ván · Phạt bài rời")
	return message


func _end_action_detail(kind: String) -> String:
	if kind == "discard":
		var cards := interactions.selected_cards()
		var action := GameGlossary.words("End this empty turn.", "Kết thúc lượt trống này.") if cards.is_empty() else GameGlossary.words("Discard %s to end this turn.", "Bỏ %s để kết thúc lượt này.") % cards[0].short_label()
		if deal.current_drink_id == DrinkCatalog.TRA_DA and not deal.tra_da_extra_discard_pending:
			return action + "\n" + GameGlossary.words("Trà Đá then offers one extra discard before refill.", "Trà Đá cho chọn bỏ thêm một lá trước khi bù bài.")
		return action + "\n" + (GameGlossary.words("Last Call follows; no refill.", "Sau đó là Chốt Hạ; không bù bài.") if deal.discard_count + (0 if deal.tra_da_extra_discard_pending else 1) >= deal.phase_discard_limit() else GameGlossary.words("Loose cards count as turn deadwood, then refill toward 10.", "Bài rời tính phạt lượt, rồi bù lên 10."))
	if deal.tra_da_extra_discard_pending:
		return GameGlossary.words("Skip the extra discard. Count turn deadwood, then refill if another turn remains.", "Bỏ qua lần bỏ thêm. Tính phạt lượt rồi bù bài nếu còn lượt.")
	var message := GameGlossary.words("Settle this Phase. All loose cards count as deadwood before any refill.", "Chốt hiệp này. Toàn bộ bài rời tính phạt trước khi bù bài.")
	if deal.current_phase == 1:
		var kept: Array[String] = []
		if deal.has_preservation_drink():
			for card in deal.sam_dua_preserved_cards:
				if deal.hand.has(card): kept.append(card.short_label())
		message += "\n" + (GameGlossary.words("Carry %d card(s) into Phase 2: %s.", "Giữ %d lá sang Hiệp 2: %s.") % [kept.size(), ", ".join(kept)] if not kept.is_empty() else GameGlossary.words("No loose cards are marked to carry into Phase 2.", "Chưa đánh dấu bài rời nào để giữ sang Hiệp 2."))
		message += "\n" + GameGlossary.words("Replace the other %d cards and refill toward 10. Table Melds stay.", "Thay %d lá còn lại rồi bù lên 10. Phỏm trên bàn vẫn giữ.") % (deal.hand.size() - kept.size())
	else:
		message += "\n" + GameGlossary.words("This completes the Deal.", "Ván chơi sẽ kết thúc.")
	return message


func _on_discard_pressed() -> void:
	var presentation_generation := money_playback.generation
	if discard_button.disabled:
		return
	var selected := interactions.selected_cards()
	var card: CardData = selected[0] if not selected.is_empty() else null
	interactions.locked = true
	_refresh_actions()
	_fly_cards(selected, discard_texture.get_global_rect().get_center())
	var result: Dictionary = deal.end_empty_turn() if card == null else deal.discard_card(card)
	if not result.get("ok", false):
		_reject_action(result.get("message", "Discard failed."))
		return
	_play_card_sfx(CARD_SFX_PLACE)
	interactions.selected_ids.clear()
	_sync_all(result)
	await money_feedback.drain_u()
	if presentation_generation != money_playback.generation: return
	if result.has("turn_resolution"):
		money_feedback.show_turn_deadwood(result["turn_resolution"], result.get("boss_wallet_entries", []))
	else:
		money_feedback.queue_zodiac_entries(result.get("boss_wallet_entries", []))
	money_feedback.drain_exhaustion()
	await money_feedback.drain_u_khan()
	if presentation_generation != money_playback.generation: return
	if result.get("extra_discard_pending", false):
		_show_banner(tr("BANNER_TRA_DA_EXTRA_DISCARD"))
		_release_deal_input()
		_refresh_actions()
	elif result.get("final_commit_window", false):
		_show_banner(tr("BANNER_LAST_CALL"))
		_release_deal_input()
		_refresh_actions()
	else:
		var drawn: Array[CardData] = _cards_from_result(result)
		_show_banner(tr("BANNER_DRAW") % [drawn.size(), deal.discard_count, deal.phase_discard_limit()])
		_release_deal_input()
		_refresh_actions()
func _on_settle_pressed() -> void:
	var presentation_generation := money_playback.generation
	if settle_button.disabled:
		return
	if deal.state == DealState.STATE_ACTIVE and deal.tra_da_extra_discard_pending:
		interactions.locked = true
		_refresh_actions()
		var turn_result := deal.end_turn_without_tra_da_extra()
		if not turn_result.get("ok", false):
			_reject_action(turn_result.get("message", "Ending the turn failed."))
			return
		_sync_all(turn_result)
		if turn_result.has("turn_resolution"):
			money_feedback.show_turn_deadwood(turn_result["turn_resolution"], turn_result.get("boss_wallet_entries", []))
		money_feedback.drain_exhaustion()
		if turn_result.get("final_commit_window", false):
			_show_banner(tr("BANNER_LAST_CALL"))
		else:
			var turn_drawn: Array[CardData] = _cards_from_result(turn_result)
			_show_banner(tr("BANNER_DRAW") % [turn_drawn.size(), deal.discard_count, deal.phase_discard_limit()])
		interactions.locked = false
		_refresh_actions()
		return
	interactions.locked = true
	_refresh_actions()
	var result := deal.settle_phase()
	if not result.get("ok", false):
		_reject_action(result.get("message", "Settlement failed."))
		return
	interactions.selected_ids.clear()
	interactions.selected_meld_id = -1
	_sync_all(result)
	var resolution: Dictionary = result["phase_resolution"]
	if int(resolution.get("phase", 0)) == 2:
		music.conductor.on_deal_resolved()
	await money_feedback.show_phase_resolution(resolution, result.get("boss_wallet_entries", []))
	if presentation_generation != money_playback.generation: return
	if resolution["phase"] == 1:
		_show_phase_choice(resolution)
	else:
		_show_deal_over(resolution)


func _on_sort_pressed() -> void:
	if sort_button.disabled:
		return
	sort_mode = (sort_mode + 1) % 2
	var ordered: Array[CardData] = deal.hand.duplicate()
	if sort_mode == 0:
		ordered.sort_custom(func(left: CardData, right: CardData) -> bool:
			if left.rank_index == right.rank_index:
				return DeckManager.SUITS.find(left.suit) < DeckManager.SUITS.find(right.suit)
			return left.rank_index < right.rank_index
		)
		sort_button.text = tr("ACTION_SORT_RANK")
	else:
		ordered.sort_custom(func(left: CardData, right: CardData) -> bool:
			var left_suit := DeckManager.SUITS.find(left.suit)
			var right_suit := DeckManager.SUITS.find(right.suit)
			if left_suit == right_suit:
				return left.rank_index < right.rank_index
			return left_suit < right_suit
		)
		sort_button.text = tr("ACTION_SORT_SUIT")
	deal.reorder_hand(ordered)
	card_table.layout_hand(true)
	card_table.sync_reactive_targets()


func _on_hint_pressed() -> void:
	if hint_button.disabled: return
	if interactions.drink_targeting:
		_cancel_drink_targeting()
		return
	if strawy != null: strawy.close()
	interactions.selected_ids.clear()
	interactions.selected_meld_id = -1
	var recommendation := deal.queries.recommend_action()
	if recommendation["action"] == HandAdvisor.ACTION_NONE:
		_show_banner(tr("BANNER_NO_HINT"))
	else:
		interactions.select(recommendation["cards"], recommendation["meld_id"] if recommendation["action"] == HandAdvisor.ACTION_EXTENSION else -1)
		var verb := tr("MELD_ACTION") if recommendation["action"] == HandAdvisor.ACTION_NEW_MELD else tr("EXTEND_ACTION")
		_show_banner(tr("BANNER_HINT") % [verb, recommendation["estimated_points"]])
	card_table.layout_hand(true)
	card_table.sync_melds()
	card_table.sync_reactive_targets()
	_refresh_stats()
	_refresh_actions()


func _present_scoring_suppression(context: ScoringContext) -> void:
	if zodiac_boss_hud != null and zodiac_boss_hud.visible:
		zodiac_boss_hud.present_suppression(context)
	else:
		_show_banner(ZodiacCatalog.feedback(context.suppression_reason) + ZodiacCatalog.words(" · legal play, 0 VNĐ", " · bài hợp lệ, 0 VNĐ"))


func _scoring_card_control(card_id: String) -> Control:
	# Resolve at playback time; rapid input can rebuild meld views while queued.
	for view: MeldView in card_table.meld_views.values():
		if is_instance_valid(view):
			var face := view.get_scoring_card_control(card_id)
			if face != null:
				return face
	for snapshot in meld_row.get_children():
		if not snapshot.get_meta("exhaustion_snapshot", false):
			continue
		for child in snapshot.get_children():
			if child is Control and String(child.get_meta("scoring_card_id", "")) == card_id:
				return child as Control
	for child in particle_layer.get_children():
		if child is Control and String(child.get_meta("scoring_card_id", "")) == card_id:
			return child as Control
	return null

func _try_fast_forward_money(event: InputEvent) -> bool:
	if not money_playback.running or money_presentation.fast_forward_enabled or menu_layer.visible \
			or modal_overlay.visible or pile_archive.overlay.visible or is_instance_valid(wallet_spiral) \
			or (event_table != null and event_table.overview.expanded):
		return false
	var pressed := false
	if event is InputEventKey:
		pressed = event.pressed and not event.echo
	elif event is InputEventMouseButton:
		pressed = event.pressed and event.button_index in [MOUSE_BUTTON_LEFT, MOUSE_BUTTON_RIGHT, MOUSE_BUTTON_MIDDLE]
	elif event is InputEventJoypadButton or event is InputEventScreenTouch or event is InputEventAction:
		pressed = event.is_pressed()
	if not pressed:
		return false
	money_playback.request_fast_forward()
	# This press only speeds up committed feedback; it cannot activate a card or
	# the focused action button underneath. Later inputs keep their normal meaning.
	get_viewport().set_input_as_handled()
	return true


func _show_phase_choice(_resolution: Dictionary) -> void:
	interactions.locked = false
	_begin_phase_two()


func _show_deal_over(_resolution: Dictionary) -> void:
	interactions.locked = true
	card_table.set_hand_interaction_enabled(false)
	modal_overlay.visible = false
	if session.debug_active:
		campaign.debug_context.finished = true
		_show_banner(GameGlossary.words("DEBUG encounter complete · Replay or choose another boss.", "Đã xong thử nghiệm · Chơi lại hoặc chọn Con Giáp khác."))
		session.flush()
		return
	# Resolution feedback has already played. Archive once and return to the
	# event table without constructing an inspection screen for every deal.
	resolve_mode = ""
	if campaign != null and CampaignManager.DEAL_PHASE_TO_PERIOD.has(campaign.current_phase):
		var result := deal.last_phase_resolution.duplicate(true)
		result["details"] = deal.accounting_report()
		campaign.complete_deal(result)
	elif campaign == null:
		interactions.locked = false
		_start_new_deal()


func _show_modal() -> void:
	if pile_archive.overlay.visible:
		pile_archive.close()
	card_table.set_hand_interaction_enabled(false)
	modal_overlay.visible = true
	modal_overlay.modulate = Color(1, 1, 1, 0)
	var panel: Panel = modal_title.get_parent().get_parent()
	panel.scale = Vector2(0.95, 0.95)
	panel.pivot_offset = panel.size * 0.5
	var tween := create_tween().set_parallel(true)
	tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(modal_overlay, "modulate", Color.WHITE, 0.18)
	tween.tween_property(panel, "scale", Vector2.ONE, 0.22)


func _on_modal_primary_pressed() -> void:
	if modal_mode == "zodiac_endgame":
		_choose_zodiac_endgame(true)
	elif modal_mode == "campaign_deal_over":
		interactions.locked = true
		modal_overlay.visible = false
		campaign.complete_deal(deal.last_phase_resolution)
	elif modal_mode == "deal_over":
		_start_new_deal()


func _on_modal_secondary_pressed() -> void:
	if modal_mode == "zodiac_endgame":
		_choose_zodiac_endgame(false)


func _begin_phase_two() -> void:
	var presentation_generation := money_playback.generation
	if interactions.locked:
		return
	interactions.locked = true
	modal_overlay.visible = false
	card_table.set_hand_interaction_enabled(true)
	var cards_to_dump: Array[CardData] = []
	for card in deal.hand:
		if not deal.has_preservation_drink() or not deal.sam_dua_preserved_cards.has(card): cards_to_dump.append(card)
	await _fly_cards(cards_to_dump, discard_texture.get_global_rect().get_center())
	if presentation_generation != money_playback.generation: return
	var result := deal.choose_phase_two()
	if not result.get("ok", false):
		_reject_action(result.get("message", "Phase transition failed."))
		return
	interactions.selected_ids.clear()
	interactions.selected_meld_id = -1
	music.conductor.on_deal_phase_started(deal.current_phase)
	_sync_all(result)
	money_feedback.drain_exhaustion()
	if not result.get("preserved", []).is_empty():
		_show_banner(tr("BANNER_PHASE2_SAM_DUA") % result["preserved"].size())
	else:
		_show_banner(GameGlossary.words("PHASE 2 · HAND REFILLED", "HIỆP 2 · ĐÃ BÙ BÀI"))
	_release_deal_input()
	_refresh_actions()


func _start_campaign() -> void:
	_reset_session_view()
	event_table.table_state = EventTableController.TABLE_STATE_DEAL
	resolve_mode = ""
	if is_instance_valid(resolve_receipt):
		resolve_receipt.hide()
	interactions.locked = true
	modal_overlay.visible = false
	event_table.visible = false
	interactions.selected_ids.clear()
	interactions.selected_meld_id = -1
	money_playback.displayed_balance = 0
	money_feedback.clear_pending()
	for snapshot in meld_row.get_children():
		if snapshot.get_meta("exhaustion_snapshot", false):
			snapshot.queue_free()
	money_playback.queued_balance = money_playback.displayed_balance
	deal.relics.reset_run()
	campaign.onboarding.first_seed_enabled = settings.first_seed_enabled
	campaign.start_campaign(true, run_seed_input)
	run_seed_input = ""
	_refresh_stats()


func _on_campaign_event_started(event: EventInstance) -> void:
	if _collection_departing:
		current_campaign_event = event
		return
	if music.conductor != null:
		match event.slot:
			EventManager.EventSlot.NOON:
				music.conductor.on_event_started("noon")
			EventManager.EventSlot.AFTERNOON:
				music.conductor.on_event_started("afternoon")
	_show_campaign_event(event)


func _on_campaign_started() -> void:
	deal.set_campaign_deck(campaign.gieo_que.persistent_deck)


func _on_campaign_deal_requested(day: Dictionary, period: String, drink_id: String) -> void:
	if drink_manager.progress != null:
		drink_manager.progress.begin_deal()
	current_campaign_event = null
	interactions.locked = true
	modal_overlay.visible = false
	card_table.set_hand_interaction_enabled(false)
	interactions.selected_ids.clear()
	interactions.selected_meld_id = -1
	var drink_result := deal.set_current_drink(drink_id)
	if not drink_result.get("ok", false):
		deal.set_current_drink(DrinkCatalog.TRA_DA)
	var opening: Array[String] = []
	if campaign.current_day_index == 0 and campaign.onboarding.first_seed_enabled:
		opening = campaign.onboarding.opening_ids(period, campaign.gieo_que.persistent_deck, deal.relics.equipped)
	var shuffle_seed := CampaignOnboarding.SEED if campaign.current_day_index == 0 and campaign.onboarding.first_seed_enabled else campaign.seed_for("deal", campaign.current_day_index * 4 + ["morning", "noon", "afternoon", "evening", "dragon"].find(period))
	if period == "dragon": shuffle_seed = campaign.seed_for("dragon_deal", campaign.current_day_index)
	var result := deal.start_deal(shuffle_seed, false, opening)
	if result.get("ok", false):
		music.conductor.on_deal_started(period)
	money_playback.displayed_balance = deal.wallet.balance_vnd
	money_playback.queued_balance = money_playback.displayed_balance
	_sync_all(result, true)
	pending_deal_presentation_unlock = true
	event_table.enter_deal()
	_show_banner(tr("CAMPAIGN_DEAL_BANNER") % [
		CampaignText.day_name(campaign),
		GameGlossary.words("DRAGON ENDGAME", "THỬ THÁCH THÌN") if period == "dragon" else tr(CampaignText.period_key(period)),
	])

func _on_deal_meld_exhaustion_triggered(meld: MeldState, context: Dictionary) -> void:
	var view := card_table.meld_views.get(meld.meld_id) as MeldView
	var visual := _capture_exhaustion_visual(meld, view)
	money_feedback.buffer_exhaustion(context.get("scoring_context") as ScoringContext, visual)


func _capture_exhaustion_visual(meld: MeldState, view: MeldView) -> Dictionary:
	if view == null or particle_layer == null:
		return {}
	var anchor := Control.new()
	anchor.mouse_filter = Control.MOUSE_FILTER_IGNORE
	anchor.set_meta("exhaustion_snapshot", true)
	anchor.size = view.size
	anchor.custom_minimum_size = view.size
	anchor.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	anchor.position = view.position
	meld_row.add_child(anchor)
	meld_row.move_child(anchor, view.get_index())
	var ghosts: Array[Control] = []
	for card in meld.cards:
		var card_rect := view.card_global_rect(card.unique_id)
		if card_rect.size == Vector2.ZERO:
			continue
		var ghost := TextureRect.new()
		ghost.set_meta("scoring_card_id", card.unique_id)
		ghost.texture = load(card.texture_path()) as Texture2D
		GieoCardFX.attach_texture(ghost, card)
		ghost.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		ghost.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		ghost.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		ghost.mouse_filter = Control.MOUSE_FILTER_IGNORE
		ghost.position = card_rect.position - view.global_position
		ghost.size = card_rect.size
		ghost.pivot_offset = ghost.size * 0.5
		anchor.add_child(ghost)
		ghosts.append(ghost)
	view.modulate.a = 0.0
	return {"anchor": anchor, "cards": ghosts}


func _return_exhaustion_visual(visual: Dictionary) -> void:
	var target := draw_pile_visual.get_global_rect().get_center() - particle_layer.global_position
	var last_tween: Tween
	var cards: Array = visual.get("cards", [])
	var gap := minf(0.035, 0.35 / maxf(cards.size(), 1))
	for card_value in cards:
		var card := card_value as Control
		if card == null or not is_instance_valid(card):
			continue
		if not money_presentation.fast_forward_enabled:
			await _reveal_scoring_card(card)
		if not is_instance_valid(card):
			continue
		card.reparent(particle_layer, true)
		var tween := money_presentation.animation_tween(card).set_parallel(true)
		tween.tween_property(card, "position", target - card.size * 0.5, 0.18).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		tween.tween_property(card, "rotation", card.rotation + 0.12, 0.18)
		tween.tween_property(card, "scale", Vector2(0.72, 0.72), 0.18)
		tween.tween_property(card, "modulate:a", 0.0, 0.07).set_delay(0.12)
		tween.chain().tween_callback(card.queue_free)
		last_tween = tween
		await money_presentation.wait_animation(gap)
	if last_tween != null and last_tween.is_running():
		await last_tween.finished
	var anchor := visual.get("anchor") as Control
	if anchor != null and is_instance_valid(anchor):
		anchor.queue_free()

func _on_deal_exhaustion_triggered(_context: Dictionary) -> void:
	money_feedback.ensure_exhaustion()
	interactions.selected_meld_id = -1
	_show_banner(tr("BANNER_EXHAUSTION"))


func _on_campaign_drink_pressed(event_slot: int, interaction_id: String, drink_id: String) -> void:
	var result := drink_manager.select_for_event(event_slot, drink_id)
	if not result.get("ok", false):
		if String(result.get("reason", "")) == "already_selected":
			return
		_show_banner(tr("EVENT_NOT_ENOUGH_VND"))
		return
	ui_feedback.play_drink(drink_id)
	event_manager.complete_interaction(interaction_id)
	var target_wallet := deal.wallet.balance_vnd
	money_playback.synchronize(target_wallet)
	event_table.event_money_feedback(_event_money_text(target_wallet))
	if current_campaign_event != null:
		_sync_event_continue()
		event_services.present_npc(event_table.focused_npc_id, current_campaign_event)
	_refresh_stats()


func _on_campaign_continue_pressed() -> void:
	if campaign.current_phase in [CampaignManager.CampaignPhase.CAMPAIGN_VICTORY, CampaignManager.CampaignPhase.CAMPAIGN_FAILURE]:
		_start_campaign()
		return
	if current_campaign_event == null or not current_campaign_event.can_exit or campaign.relic_shop.removal_pending:
		return
	if campaign.gieo_que.state not in [GieoQueService.STATE_READY, GieoQueService.STATE_COMPLETE]:
		return
	event_table.continue_button.disabled = true
	current_campaign_event = null
	campaign.complete_current_event()

func _on_campaign_requirement_passed(day: Dictionary) -> void:
	_show_banner(tr("CAMPAIGN_REQUIREMENT_PASSED") % [
		tr(String(day.get("name_key", ""))),
		VndWallet.format_vnd(int(day.get("required_vnd", 0))),
	])


func _on_campaign_won() -> void:
	_show_campaign_outcome(true)


func _on_campaign_lost() -> void:
	_show_campaign_outcome(false)



func _show_campaign_outcome(won: bool) -> void:
	event_table.enter_resolution()
	current_campaign_event = null
	interactions.locked = true
	card_table.set_hand_interaction_enabled(false)
	modal_overlay.visible = false
	resolve_mode = "outcome"
	_ensure_resolve_receipt()
	var report := deal.wallet.report()
	report["counts"] = {"deals": campaign.deal_reports.size(), "days": campaign.day_reports.filter(func(day_report: Dictionary): return day_report.get("paid", false)).size()}
	for day_report in campaign.day_reports:
		for key in day_report.get("counts", {}):
			report.counts[key] = int(report.counts.get(key, 0)) + int(day_report.counts[key])
	report["actions"] = _resolve_card_history(false)
	report["won"] = won
	report["seed"] = campaign.run_seed
	report["days"] = campaign.day_reports.duplicate(true)
	report["activities"] = campaign.activities.duplicate(true)
	report["difficulty"] = campaign.difficulty
	report["next_difficulty"] = campaign.difficulty_progress.unlocked
	report["endless_debt"] = mini(4_000_000_000_000_000, int(ceil(float(campaign.daily_requirement()) * 1.5 / 500.0)) * 500)
	report["can_endless"] = won and campaign.campaign_complete
	resolve_receipt.show_report(report, "outcome", tr("CAMPAIGN_VICTORY" if won else "CAMPAIGN_FAILURE"), GameGlossary.words("EXIT TO MENU", "VỀ MENU"))
	_refresh_stats()


func _ensure_resolve_receipt() -> void:
	if is_instance_valid(resolve_receipt):
		return
	resolve_receipt = preload("res://scripts/ui/resolve_receipt.gd").new()
	var layer := CanvasLayer.new()
	layer.layer = 240
	add_child(layer)
	layer.add_child(resolve_receipt)
	resolve_receipt.continued.connect(_on_receipt_continue)
	resolve_receipt.endless_requested.connect(_on_endless_requested)


func _on_collection_requested(report: Dictionary) -> void:
	# A collection owns the stage even when restored from an event save.
	event_table.enter_resolution(true)
	money_playback.displayed_balance = deal.wallet.balance_vnd
	money_playback.queued_balance = money_playback.displayed_balance
	money_presentation.sync_wallet(money_playback.displayed_balance)
	current_campaign_event = null
	interactions.locked = true
	card_table.set_hand_interaction_enabled(false)
	modal_overlay.visible = false
	resolve_mode = "collection"
	_ensure_resolve_receipt()
	var caption: String = resolve_receipt.words("PAY & CONTINUE", "TRẢ NỢ & TIẾP TỤC")
	if int(report.shortfall_vnd) > 0:
		caption = resolve_receipt.words("CANNOT PAY · END RUN", "KHÔNG ĐỦ TIỀN · KẾT THÚC")
	# Full records remain in CampaignManager; collection needs only its totals.
	report = _collection_summary(report)
	resolve_receipt.show_report(report, "collection",
		resolve_receipt.words("ĐÒI NỢ · DAY'S ACCOUNTS", "ĐÒI NỢ · SỔ CUỐI NGÀY"), caption)


func _collection_summary(report: Dictionary) -> Dictionary:
	var summary := {}
	for key in ["opening_vnd", "closing_vnd", "income_vnd", "expense_vnd", "net_vnd", "categories", "counts", "due_vnd", "shortfall_vnd", "paid"]:
		if report.has(key):
			summary[key] = report[key]
	return summary


func _resolve_card_history(today_only: bool) -> Array:
	var actions: Array = []
	var deal_number := 0
	for result: Dictionary in campaign.deal_reports:
		deal_number += 1
		if today_only and result.get("day_id", "") != campaign.current_day().get("id", ""):
			continue
		for action: Dictionary in result.get("details", {}).get("actions", []):
			var snapshot := action.duplicate(true)
			snapshot["deal_number"] = deal_number
			actions.append(snapshot)
	return actions


func _on_receipt_continue() -> void:
	if _collection_departing: return
	var mode := resolve_mode
	resolve_mode = ""
	if mode == "collection" and deal.wallet.balance_vnd >= campaign.daily_requirement():
		_collection_departing = true
		# Keep the receiving character on screen while committed banknotes arrive.
		var departure := CanvasLayer.new()
		departure.layer = 244
		add_child(departure)
		var rider := TextureRect.new()
		rider.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		rider.texture = resolve_receipt.portrait.texture
		rider.position = resolve_receipt.portrait.global_position
		rider.size = resolve_receipt.portrait.size
		rider.mouse_filter = Control.MOUSE_FILTER_IGNORE
		departure.add_child(rider)
		var exit := rider.create_tween()
		exit.tween_interval(0.85)
		exit.tween_property(rider, "position:x", 1380.0, 0.4).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
		resolve_receipt.hide()
		# Commit through the campaign once. Its wallet signal starts the flight.
		campaign.collect_day_debt()
		await exit.finished
		departure.queue_free()
		_collection_departing = false
		if current_campaign_event != null:
			_on_campaign_event_started(current_campaign_event)
		money_playback.displayed_balance = deal.wallet.balance_vnd
		money_playback.queued_balance = money_playback.displayed_balance
		_refresh_stats()
		return
	resolve_receipt.hide()
	match mode:
		"deal":
			if campaign != null and CampaignManager.DEAL_PHASE_TO_PERIOD.has(campaign.current_phase):
				var result := deal.last_phase_resolution.duplicate(true)
				result["details"] = deal.accounting_report()
				campaign.complete_deal(result)
			else:
				interactions.locked = false
				_start_new_deal()
		"collection":
			campaign.collect_day_debt()
			money_playback.displayed_balance = deal.wallet.balance_vnd
			money_playback.queued_balance = money_playback.displayed_balance
			_refresh_stats()
		"outcome":
			_exit_completed_run()


func _event_money_text(amount_vnd: int) -> String:
	return VndWallet.format_amount(amount_vnd)


func _start_new_deal() -> void:
	if interactions.locked:
		return
	interactions.locked = true
	modal_overlay.visible = false
	card_table.set_hand_interaction_enabled(true)
	interactions.selected_ids.clear()
	interactions.selected_meld_id = -1
	var result := deal.start_deal(-1, false)
	money_playback.displayed_balance = deal.wallet.balance_vnd
	money_playback.queued_balance = money_playback.displayed_balance
	_sync_all(result, true)
	_show_banner(tr("BANNER_NEW_DEAL_WALLET"))
	interactions.locked = false
	_refresh_actions()


func _fly_cards(cards: Array[CardData], target_global: Vector2) -> void:
	if cards.is_empty():
		return
	var target_local := target_global - particle_layer.global_position
	var tween := create_tween().set_parallel(true)
	for index in range(cards.size()):
		var card := cards[index]
		if not card_table.hand_views.has(card.unique_id):
			continue
		var source: PlayingCardView = card_table.hand_views[card.unique_id]
		var ghost := TextureRect.new()
		ghost.set_meta("scoring_card_id", card.unique_id)
		ghost.texture = load(card.texture_path()) as Texture2D
		GieoCardFX.attach_texture(ghost, card)
		ghost.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		ghost.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		ghost.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		ghost.position = source.global_position - particle_layer.global_position
		ghost.size = CARD_SIZE
		ghost.pivot_offset = CARD_SIZE * 0.5
		ghost.rotation = source.rotation
		particle_layer.add_child(ghost)
		var delay := index * 0.035
		tween.tween_property(ghost, "position", target_local - CARD_SIZE * 0.36 + Vector2(index * 5, 0), 0.25).set_delay(delay).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		tween.tween_property(ghost, "scale", Vector2(0.72, 0.72), 0.25).set_delay(delay)
		tween.tween_property(ghost, "rotation", 0.02 * (index - cards.size() * 0.5), 0.25).set_delay(delay)
		tween.tween_property(ghost, "modulate", Color(1, 1, 1, 0), 0.09).set_delay(delay + 0.2)
		tween.tween_callback(ghost.queue_free).set_delay(delay + 0.3)
	await tween.finished


func _show_banner(message: String) -> void:
	if _banner_tween != null and _banner_tween.is_valid():
		_banner_tween.kill()
	banner_label.text = message
	var banner_y := 276 if zodiac_boss_hud != null and zodiac_boss_hud.visible else 126
	banner_panel.position.x = 12
	banner_panel.size = Vector2(148, 48)
	banner_panel.position.y = banner_y - 10
	banner_panel.modulate = Color(1, 1, 1, 0)
	var tween := create_tween()
	_banner_tween = tween
	tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(banner_panel, "modulate", Color.WHITE, 0.14)
	tween.parallel().tween_property(banner_panel, "position:y", banner_y, 0.2)
	tween.tween_interval(1.25)
	tween.set_ease(Tween.EASE_IN)
	tween.tween_property(banner_panel, "modulate", Color(1, 1, 1, 0), 0.22)


func _reject_action(message: String) -> void:
	action_rejected.emit()
	ui_feedback.play(&"reject")
	_release_deal_input()
	_show_banner(message)
	status_label.text = message.to_upper()
	status_label.add_theme_color_override("font_color", PresentationTheme.DANGER)
	for card in interactions.selected_cards():
		if card_table.hand_views.has(card.unique_id):
			card_table.hand_views[card.unique_id].play_reject()
	_refresh_actions()


func _cards_from_result(result: Dictionary) -> Array[CardData]:
	var cards: Array[CardData] = []
	for key in ["resting_cards", "drawn"]:
		if result.has(key):
			for value in result[key]:
				if value is CardData:
					cards.append(value)
	return cards


func _on_viewport_size_changed() -> void:
	_park_game_layer()
	card_table.layout_hand(false)


func _unhandled_key_input(event: InputEvent) -> void:
	if zodiac_table != null and zodiac_table.shade.visible:
		if event.is_action_pressed(&"ui_cancel"):
			zodiac_table.close_conversation()
		get_viewport().set_input_as_handled()
		return
	if get_tree().root.has_node("GameGlossary"):
		return
	if is_instance_valid(resolve_receipt) and resolve_receipt.visible and not menu_layer.visible:
		return
	if not event is InputEventKey or not event.pressed or event.echo:
		return
	if menu_layer.visible:
		if front_end != null and front_end.page != "home":
			return
		if event.is_action_pressed(&"ui_cancel") and front_end.page != "home":
			front_end.show_home()
		elif game_started and event.is_action_pressed(&"ui_cancel"):
			_close_menu_to_game()
		return
	if event_table != null and event_table.visible and not event_table.focused_npc_id.is_empty():
		if event.is_action_pressed(&"ui_cancel"):
			event_table.unfocus_npc()
		return
	if pile_archive.overlay.visible:
		if event.is_action_pressed(&"ui_cancel"):
			pile_archive.close()
		return
	if modal_overlay.visible:
		if modal_mode == "deal_over" and event.is_action_pressed(&"game_new_deal"):
			_start_new_deal()
		return
	if event.is_action_pressed(&"game_meld"):
		if not ha_button.disabled:
			_on_ha_pressed()
	elif event.is_action_pressed(&"game_extend"):
		if not extend_button.disabled:
			_on_extend_pressed()
	elif event.is_action_pressed(&"game_discard"):
		if not discard_button.disabled:
			_on_discard_pressed()
	elif event.is_action_pressed(&"game_settle"):
		if not settle_button.disabled:
			_on_settle_pressed()
	elif event.is_action_pressed(&"game_sort"):
		if not sort_button.disabled:
			_on_sort_pressed()
	elif event.is_action_pressed(&"game_hint"):
		if not hint_button.disabled:
			_on_hint_pressed()
	elif event.is_action_pressed(&"ui_cancel"):
		if interactions.drink_targeting:
			_cancel_drink_targeting()
		else:
			interactions.selected_ids.clear()
			interactions.selected_meld_id = -1
			_sync_all()


func _on_demo_progress_action(result: Dictionary) -> void:
	if campaign == null or drink_manager.progress == null:
		return
	if not CampaignManager.DEAL_PHASE_TO_PERIOD.has(campaign.current_phase):
		return
	drink_manager.progress.record_action(deal, result)


func _on_demo_deal_finished(result: Dictionary) -> void:
	if drink_manager.progress != null and result.get("period") == "morning":
		drink_manager.progress.add_progress("morning_deals")


func _on_drink_unlocked(drink_id: String) -> void:
	pending_drink_unlocks.append(drink_id)
	if unlock_notice_playing:
		return
	unlock_notice_playing = true
	# Let deal/day banners finish before displaying the unlock notices.
	await get_tree().create_timer(1.8).timeout
	while not pending_drink_unlocks.is_empty():
		_show_banner(tr("DRINK_UNLOCK_NOTICE") % DrinkCatalog.display_name(pending_drink_unlocks.pop_front()))
		await get_tree().create_timer(1.8).timeout
	unlock_notice_playing = false


func _reveal_scoring_card(card_control: Control) -> void:
	if not is_instance_valid(card_control) or not meld_scroll.is_ancestor_of(card_control):
		return
	var viewport_rect := meld_scroll.get_global_rect()
	var card_rect := card_control.get_global_rect()
	if viewport_rect.encloses(card_rect):
		return
	var offset := 0.0
	if card_rect.position.x < viewport_rect.position.x:
		offset = card_rect.position.x - viewport_rect.position.x - 18.0
	elif card_rect.end.x > viewport_rect.end.x:
		offset = card_rect.end.x - viewport_rect.end.x + 18.0
	var tween := money_presentation.animation_tween(self)
	tween.tween_property(meld_scroll, "scroll_horizontal", maxi(0, meld_scroll.scroll_horizontal + roundi(offset)), 0.18).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
	await tween.finished

func drink_record_at(point: Vector2) -> DiscardRecord:
	return pile_archive.record_at(point) if pile_archive.overlay.visible else card_table.drink_record_at(point)


func commit_selected_drink(cards: Array[CardData]) -> bool:
	if not interactions.drink_drop_is_valid(cards, {"kind": &"drink"}):
		return false
	if deal.has_preservation_drink():
		present_drink_result(interactions.execute_drink("preserve", cards))
	elif deal.current_drink_id in [DrinkCatalog.NHAN_TRAN, DrinkCatalog.DEN_DA]:
		interactions.drink_targeting = true
		interactions.drink_ids.clear()
		interactions.drink_ids[cards[0].unique_id] = true
		target_drink_card(cards[0])
	else:
		present_drink_result(interactions.execute_drink("create", cards))
	return true

func try_drink_card_drop(cards: Array[CardData], target: Dictionary) -> bool:
	if not interactions.drink_drop_is_valid(cards, target):
		return false
	if target.get("kind") == &"drink_discard":
		pile_archive.close()
		swap_drink_card(cards[0], target["record"] as DiscardRecord)
	else:
		commit_selected_drink(cards)
	return true

func _sync_passive_drink_sound(result: Dictionary) -> void:
	if ui_feedback == null or not result.get("ok", false):
		return
	if deal.current_drink_id == DrinkCatalog.TRA_DA and result.get("discard_kind", "") == DiscardRecord.KIND_DRINK_EXTRA:
		ui_feedback.play_drink(deal.current_drink_id)
	elif deal.current_drink_id in [DrinkCatalog.MIA_TAC, DrinkCatalog.MIA_SAU_RIENG] and result.get("action", "") in ["new_meld", "extension"]:
		var meld := deal.get_meld(int(result.get("meld_id", -1)))
		if meld != null and meld.meld_type == MeldRules.TYPE_RUN and MeldRules.classify(meld.cards) == MeldRules.TYPE_INVALID:
			ui_feedback.play_drink(deal.current_drink_id)

func _setup_run_saving() -> void:
	add_child(session)
	session.configure(campaign, deal, session.save_files, func(): return game_started, music.snapshot,
		_reset_session_view, _present_restored_run, _present_inactive_session,
		func(message): front_end.show_error(message), _show_banner)
	session.progress_rebound.connect(func(): _connect_signal_once(drink_manager.progress.drink_unlocked, _on_drink_unlocked))
	session.debug_options_changed.connect(func(options): front_end.boss_options = options)
	music.checkpoint_changed.connect(session.queue_save)
	get_tree().auto_accept_quit = false

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_WINDOW_FOCUS_OUT and is_node_ready():
		if interactions.drag_payload != null: cancel_card_drag()
		for view: PlayingCardView in card_table.hand_views.values(): view.clear_transient_interaction()
	elif what == NOTIFICATION_WM_CLOSE_REQUEST:
		session.flush()
		get_tree().quit()


func _on_front_start_requested(draft: RunSetupDraft) -> void:
	if not session.save_files.usable():
		front_end.start_failed(session.save_files.error)
		return
	if session.debug_active:
		front_end.start_failed(GameGlossary.words("Exit Boss Lab before starting a normal run.", "Thoát thử Con Giáp trước khi bắt đầu ván thường."))
		return
	if not campaign.select_difficulty(draft.difficulty):
		front_end.start_failed(GameGlossary.words("Difficulty is locked.", "Độ khó chưa được mở."))
		return
	if not draft.emblem_id.is_empty() and not campaign.zodiac.progress.owns(draft.emblem_id):
		front_end.start_failed(GameGlossary.words("Emblem is locked.", "Huy hiệu chưa được mở."))
		return
	if draft.music_system not in settings.SUPPORTED_MUSIC_SYSTEMS:
		front_end.start_failed(GameGlossary.words("Music choice is unavailable.", "Chế độ nhạc không khả dụng."))
		return
	campaign.zodiac.prefer_emblem(draft.emblem_id)
	if settings.music_system != draft.music_system:
		music.select_system(settings.SUPPORTED_MUSIC_SYSTEMS.find(draft.music_system))
	run_seed_input = draft.seed
	_on_play_pressed()


func _on_front_resume_requested() -> void:
	var saved := session.run_save.load_run()
	if saved.is_empty():
		front_end.show_error(session.run_save.error if not session.run_save.error.is_empty() else GameGlossary.words("Saved run is unavailable.", "Không tìm thấy ván đã lưu."))
		return
	if not session.resume(saved):
		front_end.show_error(GameGlossary.words("Could not resume this saved run.", "Không thể tiếp tục ván đã lưu."))

func _exit_completed_run() -> void:
	session.flush()
	game_started = false
	_park_game_layer()
	interactions.locked = true
	current_campaign_event = null
	event_table.hide()
	menu_layer.position = Vector2.ZERO
	menu_layer.modulate = Color.WHITE
	menu_layer.show()
	menu_layer.mouse_filter = Control.MOUSE_FILTER_STOP
	front_end.show_home()


func _reset_session_view() -> void:
	_boss_lab_hidden_modal = false
	_boss_lab_hidden_receipt = false
	_close_session_browsers()
	if is_instance_valid(resolve_receipt):
		resolve_receipt.resume_presentation()
		resolve_receipt.hide()
	reset_transient_presentation()
	money_presentation.hide_ceremony()

func _close_session_browsers() -> void:
	deck_screen.close()
	zodiac_table.close_conversation()
	get_node("ActionLegend/Shade").hide()
	for id in ["GameGlossary", "LotteryReceipt"]:
		var browser := get_tree().root.get_node_or_null(id)
		if browser != null:
			get_tree().root.remove_child(browser)
			browser.queue_free()
	if is_instance_valid(wallet_spiral):
		remove_child(wallet_spiral)
		wallet_spiral.queue_free()
		wallet_spiral = null

func _present_restored_run(saved: Dictionary) -> void:
	game_started = true
	menu_transitioning = false
	menu_layer.hide()
	menu_layer.position = Vector2.ZERO
	menu_layer.modulate = Color.WHITE
	game_layer.position = Vector2.ZERO
	if is_instance_valid(resolve_receipt):
		resolve_receipt.hide()
	resolve_mode = ""
	current_campaign_event = campaign.event_manager.current_event
	money_playback.displayed_balance = deal.wallet.balance_vnd
	money_playback.queued_balance = money_playback.displayed_balance
	_on_campaign_started()
	music.restore(saved.get("music", {}))
	_sync_all()
	_refresh_relics()
	event_table.table_state = EventTableController.TABLE_STATE_DEAL
	if campaign.current_phase == CampaignManager.CampaignPhase.ZODIAC_ENDGAME_CHOICE:
		current_campaign_event = null
		_show_zodiac_endgame_choice()
	elif current_campaign_event != null:
		_show_campaign_event(current_campaign_event)
		if campaign.gieo_que.state not in [GieoQueService.STATE_READY, GieoQueService.STATE_COMPLETE]:
			event_table.focus_npc(EventTableController.NPC_THAY_BOI)
	elif campaign.current_phase == CampaignManager.CampaignPhase.MONEY_REQUIREMENT_CHECK:
		_on_collection_requested(campaign.collection_report)
	elif campaign.campaign_complete or campaign.run_failed:
		_show_campaign_outcome(not campaign.run_failed)
	else:
		interactions.locked = true
		pending_deal_presentation_unlock = true
		event_table.enter_deal()
		if deal.state == DealState.STATE_DEAL_OVER:
			_show_deal_over(deal.last_phase_resolution)
		elif deal.state == DealState.STATE_PHASE_CHOICE:
			_show_phase_choice(deal.last_phase_resolution)

func _on_endless_requested() -> void:
	if not campaign.campaign_complete or campaign.run_failed:
		return
	resolve_mode = ""
	resolve_receipt.hide()
	campaign.continue_endless()
	session.queue_save()


func _show_zodiac_endgame_choice() -> void:
	current_campaign_event = null
	event_table.hide()
	interactions.locked = true
	card_table.set_hand_interaction_enabled(false)
	modal_mode = "zodiac_endgame"
	modal_kicker.text = GameGlossary.words("AFTER SNAKE", "SAU TỴ")
	modal_title.text = GameGlossary.words("PROVE IT.", "CHỨNG MINH ĐI.")
	modal_body.text = GameGlossary.words("Face Dragon using your most successful tactic, or keep playing the week.", "Đối mặt Thìn bằng chiến thuật thành công nhất, hoặc tiếp tục tuần chơi.")
	modal_detail.text = GameGlossary.words("The day's debt and Sunday's progression continue after either choice. Endless remains available after the week.", "Khoản nợ hôm nay và tiến trình Chủ nhật tiếp tục sau cả hai lựa chọn. Vô tận vẫn mở sau tuần chơi.")
	modal_primary.text = GameGlossary.words("FACE DRAGON", "ĐỐI MẶT THÌN")
	modal_secondary.text = GameGlossary.words("CONTINUE THE WEEK", "TIẾP TỤC TUẦN CHƠI")
	modal_primary.disabled = false
	modal_secondary.disabled = false
	modal_secondary.show()
	_show_modal()
	modal_primary.grab_focus()

func _choose_zodiac_endgame(face_dragon: bool) -> void:
	if campaign.current_phase != CampaignManager.CampaignPhase.ZODIAC_ENDGAME_CHOICE: return
	modal_overlay.hide()
	modal_mode = ""
	campaign.choose_zodiac_endgame(face_dragon)
	session.queue_save()

func select_save_file(slot: int) -> bool:
	return session.select_profile(slot)

func _present_inactive_session(show_home: bool) -> void:
	game_started = false
	current_campaign_event = null
	event_table.hide()
	_park_game_layer()
	interactions.locked = true
	if show_home:
		menu_layer.position = Vector2.ZERO
		menu_layer.modulate = Color.WHITE
		menu_layer.mouse_filter = Control.MOUSE_FILTER_STOP
		menu_layer.show()
		menu_transitioning = false
		front_end.show_home()

func open_boss_lab() -> void:
	if not BossDebugSession.available() or front_end == null: return
	if menu_transitioning or _collection_departing: return
	_close_session_browsers()
	cancel_card_drag()
	quick_drink_input.cancel()
	event_table.collector_arrival.stop()
	if not menu_layer.visible:
		session.flush()
		_menu_interaction_was_locked = interactions.locked
		_boss_lab_hidden_modal = modal_overlay.visible
		modal_overlay.hide()
		_boss_lab_hidden_receipt = is_instance_valid(resolve_receipt) and resolve_receipt.visible
		if _boss_lab_hidden_receipt:
			resolve_receipt.suspend_presentation()
		interactions.locked = true
		card_table.set_hand_interaction_enabled(false)
		menu_layer.position = Vector2.ZERO
		menu_layer.modulate = Color.WHITE
		menu_layer.mouse_filter = Control.MOUSE_FILTER_STOP
		menu_layer.show()
	front_end.show_boss_lab()

func start_boss_debug(options: Dictionary) -> bool:
	return session.start_debug(options)

func resume_boss_debug() -> bool:
	return session.resume_debug()

func replay_boss_debug() -> void:
	session.replay_debug()

func leave_boss_debug() -> void:
	_boss_lab_hidden_modal = false
	session.leave_debug()

func set_card_selection(cards: Array[CardData], meld_id: int = -1) -> bool:
	if not interactions.select(cards, meld_id): return false
	card_table.layout_hand(false)
	card_table.sync_melds()
	_refresh_actions()
	return true

func interaction_snapshot() -> Dictionary:
	var gesture_blocked: bool = menu_layer.visible or modal_overlay.visible or deck_screen.visible or zodiac_table.shade.visible or get_node("ActionLegend/Shade").visible or get_tree().root.has_node("GameGlossary") or get_tree().root.has_node("LotteryReceipt") or is_instance_valid(wallet_spiral) or (is_instance_valid(resolve_receipt) and resolve_receipt.visible)
	var blocked: bool = gesture_blocked or pile_archive.overlay.visible
	return {"blocked": blocked, "gesture_blocked": gesture_blocked, "locked": interactions.locked, "restoring": session.restoring,
		"started": game_started, "event": current_campaign_event != null,
		"dragging": interactions.drag_payload != null, "drink_targeting": interactions.drink_targeting,
		"selection": interactions.selected_ids.keys(), "meld_id": interactions.selected_meld_id,
		"can_play": game_started and not blocked and not interactions.locked and current_campaign_event == null and not interactions.drink_targeting and interactions.drag_payload == null and not (score_overlay.visible and not money_presentation.presentation_active)}

func request_card_action(kind: String) -> void:
	if not interaction_snapshot().can_play: return
	_refresh_actions()
	match kind:
		"meld": _on_ha_pressed()
		"extend": _on_extend_pressed()
		"discard": _on_discard_pressed()
		"settle": _on_settle_pressed()

func request_drink_recovery(meld_id: int, card: CardData = null) -> void:
	var state := interaction_snapshot()
	if not state.started or state.locked or state.gesture_blocked: return
	present_drink_result(interactions.execute_drink("recover_card", [card] as Array[CardData], meld_id) if card != null else interactions.execute_drink("recover", [], meld_id))

func refresh_interaction_view() -> void:
	_sync_all()

func begin_drink_target(cards: Array[CardData]) -> void:
	interactions.begin_drink(cards)

func _on_debt_briefing_seen() -> void:
	event_manager.complete_interaction("debt_intro")
	campaign.onboarding.mark("debt_intro")
	session.queue_save()
