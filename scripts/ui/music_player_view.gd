class_name MusicPlayerView
extends PanelContainer
## Player controls observe MatchMusic and send explicit playback intent.

var music: MatchMusic
var _syncing := false

@onready var cover: TextureRect = $Margin/Content/Cover
@onready var now_playing: Label = $Margin/Content/Details/NowPlaying
@onready var track_title: Label = $Margin/Content/Details/TrackTitle
@onready var variant: Label = $Margin/Content/Details/Variant
@onready var system_label: Label = $Margin/Content/Details/MusicSystemRow/Label
@onready var system_selector: OptionButton = $Margin/Content/Details/MusicSystemRow/Selector
@onready var track_list: OptionButton = $Margin/Content/Details/TrackList
@onready var progress: ProgressBar = $Margin/Content/Details/Progress
@onready var time_label: Label = $Margin/Content/Details/Time
@onready var play_pause: Button = $Margin/Content/Details/Footer/PlayPause
@onready var shuffle: Button = $Margin/Content/Details/Footer/Shuffle
@onready var repeat: Button = $Margin/Content/Details/Footer/Repeat
@onready var up_next: Label = $Margin/Content/Details/UpNext


func configure(owner: MatchMusic) -> void:
	music = owner
	for label: Label in find_children("*", "Label", true, false):
		label.add_theme_font_size_override("font_size", 14)
		label.add_theme_color_override("font_color", PresentationTheme.INK)
	track_title.add_theme_font_size_override("font_size", 24)
	track_title.add_theme_color_override("font_color", PresentationTheme.GOLD)
	for button: Button in find_children("*", "Button", true, false):
		PresentationTheme.configure_button(button)
		button.custom_minimum_size.y = 42
	play_pause.pressed.connect(music.controller.toggle_music_paused)
	shuffle.pressed.connect(music.controller.toggle_shuffle)
	repeat.pressed.connect(music.controller.cycle_repeat_mode)
	system_selector.item_selected.connect(func(index):
		if not _syncing: music.select_system(index))
	track_list.item_selected.connect(func(index):
		if not _syncing: music.select_track(index))
	music.changed.connect(refresh)
	music.settings.locale_changed.connect(func(_locale): refresh())
	refresh()


func _process(_delta: float) -> void:
	if music != null and is_visible_in_tree():
		refresh_progress()


func refresh() -> void:
	var settings = music.settings
	var controller := music.controller
	var conductor := music.conductor
	_syncing = true
	now_playing.text = tr("MUSIC_PLAYER_NOW")
	system_label.text = tr("MUSIC_PLAYER_SYSTEM")
	system_selector.clear()
	system_selector.add_item(tr("MUSIC_SYSTEM_PLAYING_TRACKS"))
	system_selector.add_item(tr("MUSIC_SYSTEM_AUTHORED_DJ"))
	system_selector.select(maxi(settings.SUPPORTED_MUSIC_SYSTEMS.find(settings.music_system), 0))
	var playing_tracks: bool = settings.music_system == settings.MUSIC_SYSTEM_PLAYING_TRACKS
	track_list.disabled = false
	shuffle.disabled = not playing_tracks
	repeat.disabled = not playing_tracks
	shuffle.visible = playing_tracks
	repeat.visible = playing_tracks
	track_list.clear()
	if playing_tracks:
		for index in controller.playlist.size():
			track_list.add_item(controller.track_label(index))
		track_list.select(controller.current_track_index)
		track_list.tooltip_text = tr("MUSIC_SYSTEM_PLAYING_TRACKS")
	else:
		for set_id in settings.SUPPORTED_AUTHORED_SETS:
			track_list.add_item(tr("MUSIC_AUTHORED_SET_%s" % set_id.to_upper()))
		var selected_set: String = conductor.active_set_id if conductor.active else settings.authored_music_set
		track_list.select(maxi(settings.SUPPORTED_AUTHORED_SETS.find(selected_set), 0))
		track_list.tooltip_text = tr("MUSIC_SYSTEM_AUTHORED_DJ")
	var theme_id := controller.current_theme_id
	cover.texture = load("res://assets/audio/covers/%s.png" % theme_id) as Texture2D
	track_title.text = ReactiveMusicController.display_title_for_theme(theme_id)
	variant.text = "%s  ·  %s" % [String(theme_id).to_upper(), tr("MUSIC_PLAYER_SIDE") % controller.current_variant]
	if not playing_tracks:
		var authored_set: String = conductor.active_set_id if conductor.active else settings.authored_music_set
		var status := "MUSIC_PLAYER_DJ_ACTIVE" if controller.dj_mode else "MUSIC_PLAYER_DJ_SELECT"
		up_next.text = "%s: %s" % [tr(status), tr("MUSIC_AUTHORED_SET_%s" % authored_set.to_upper())]
	else:
		var next_request := controller.next_mix_request()
		if next_request.is_empty():
			up_next.text = tr("MUSIC_PLAYER_UP_NEXT") + ": -"
		else:
			up_next.text = "%s: %s · %s" % [tr("MUSIC_PLAYER_UP_NEXT"), String(next_request["theme_id"]).to_upper(),
				tr("MUSIC_PLAYER_SIDE") % int(next_request["variant"])]
	play_pause.text = tr("MUSIC_PLAYER_PLAY") if controller.music_paused else tr("MUSIC_PLAYER_PAUSE")
	shuffle.text = tr("MUSIC_PLAYER_SHUFFLE_ON") if controller.shuffle_enabled else tr("MUSIC_PLAYER_SHUFFLE_OFF")
	match controller.repeat_mode:
		ReactiveMusicController.REPEAT_ALL: repeat.text = tr("MUSIC_PLAYER_REPEAT_ALL")
		ReactiveMusicController.REPEAT_ONE: repeat.text = tr("MUSIC_PLAYER_REPEAT_ONE")
		_: repeat.text = tr("MUSIC_PLAYER_REPEAT_OFF")
	_syncing = false
	refresh_progress()


func refresh_progress() -> void:
	var duration := music.controller.stream_length_seconds
	var elapsed := clampf(music.controller.playback_position_seconds, 0.0, duration)
	progress.value = elapsed / duration if duration > 0.0 else 0.0
	time_label.text = "%s / %s" % [_format_time(elapsed), _format_time(duration)]


static func _format_time(seconds: float) -> String:
	var whole_seconds := maxi(0, floori(seconds))
	return "%d:%02d" % [whole_seconds / 60, whole_seconds % 60]
