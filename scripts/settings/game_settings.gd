extends Node

signal locale_changed(locale_code: String)
signal volume_changed(bus_name: StringName, percent: float)

const SETTINGS_PATH := "user://settings.cfg"
const MUSIC_BUS := &"Music"
const SOUND_BUS := &"Sound"
const SUPPORTED_LOCALES: Array[String] = ["vi", "en"]

var music_volume_percent: float = 100.0
var sound_volume_percent: float = 100.0
var locale_code: String = "vi"


func _ready() -> void:
	_ensure_bus(MUSIC_BUS)
	_ensure_bus(SOUND_BUS)
	_load_preferences()
	_apply_all()


func set_music_volume(percent: float) -> void:
	music_volume_percent = clampf(percent, 0.0, 100.0)
	_apply_bus_volume(MUSIC_BUS, music_volume_percent)
	_save_preferences()
	volume_changed.emit(MUSIC_BUS, music_volume_percent)


func set_sound_volume(percent: float) -> void:
	sound_volume_percent = clampf(percent, 0.0, 100.0)
	_apply_bus_volume(SOUND_BUS, sound_volume_percent)
	_save_preferences()
	volume_changed.emit(SOUND_BUS, sound_volume_percent)


func set_locale(locale: String) -> void:
	var normalized := locale.to_lower()
	if normalized not in SUPPORTED_LOCALES:
		normalized = "vi"
	if locale_code == normalized and TranslationServer.get_locale() == normalized:
		return
	locale_code = normalized
	TranslationServer.set_locale(locale_code)
	_save_preferences()
	locale_changed.emit(locale_code)


func locale_index() -> int:
	return maxi(SUPPORTED_LOCALES.find(locale_code), 0)


func _ensure_bus(bus_name: StringName) -> void:
	if AudioServer.get_bus_index(bus_name) >= 0:
		return
	AudioServer.add_bus()
	var bus_index := AudioServer.bus_count - 1
	AudioServer.set_bus_name(bus_index, bus_name)
	AudioServer.set_bus_send(bus_index, &"Master")


func _apply_all() -> void:
	TranslationServer.set_locale(locale_code)
	_apply_bus_volume(MUSIC_BUS, music_volume_percent)
	_apply_bus_volume(SOUND_BUS, sound_volume_percent)


func _apply_bus_volume(bus_name: StringName, percent: float) -> void:
	var bus_index := AudioServer.get_bus_index(bus_name)
	if bus_index < 0:
		return
	var normalized := clampf(percent / 100.0, 0.0, 1.0)
	AudioServer.set_bus_mute(bus_index, normalized <= 0.0001)
	AudioServer.set_bus_volume_db(bus_index, linear_to_db(maxf(normalized, 0.0001)))


func _load_preferences() -> void:
	var config := ConfigFile.new()
	if config.load(SETTINGS_PATH) != OK:
		return
	music_volume_percent = clampf(float(config.get_value("audio", "music_percent", music_volume_percent)), 0.0, 100.0)
	sound_volume_percent = clampf(float(config.get_value("audio", "sound_percent", sound_volume_percent)), 0.0, 100.0)
	var saved_locale := String(config.get_value("localization", "locale", locale_code)).to_lower()
	locale_code = saved_locale if saved_locale in SUPPORTED_LOCALES else "vi"


func _save_preferences() -> void:
	var config := ConfigFile.new()
	config.set_value("audio", "music_percent", music_volume_percent)
	config.set_value("audio", "sound_percent", sound_volume_percent)
	config.set_value("localization", "locale", locale_code)
	var error := config.save(SETTINGS_PATH)
	if error != OK:
		push_warning("Could not save player settings: %s" % error_string(error))
