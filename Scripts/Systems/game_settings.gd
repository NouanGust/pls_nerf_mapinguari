extends Node

signal settings_changed

const PATH := "user://settings.cfg"
var volume: float = 0.8
var music_volume: float = 0.8
var sfx_volume: float = 0.8
var fullscreen: bool = false
var auto_orbit: bool = false
var mouse_sensitivity: float = 0.25
var last_error: Error = OK

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	var config := ConfigFile.new()
	if config.load(PATH) == OK:
		volume = clampf(float(config.get_value("audio", "volume", volume)), 0.0, 1.0)
		music_volume = clampf(float(config.get_value("audio", "music_volume", music_volume)), 0.0, 1.0)
		sfx_volume = clampf(float(config.get_value("audio", "sfx_volume", sfx_volume)), 0.0, 1.0)
		fullscreen = bool(config.get_value("display", "fullscreen", fullscreen))
		auto_orbit = bool(config.get_value("camera", "auto_orbit", auto_orbit))
		mouse_sensitivity = clampf(float(config.get_value("camera", "sensitivity", mouse_sensitivity)), 0.05, 1.0)
	_apply()

func update_setting(key: String, value: Variant) -> void:
	match key:
		"volume": volume = clampf(float(value), 0.0, 1.0)
		"music_volume": music_volume = clampf(float(value), 0.0, 1.0)
		"sfx_volume": sfx_volume = clampf(float(value), 0.0, 1.0)
		"fullscreen": fullscreen = bool(value)
		"auto_orbit": auto_orbit = bool(value)
		"mouse_sensitivity": mouse_sensitivity = clampf(float(value), 0.05, 1.0)
		_: return
	_apply()
	var config := ConfigFile.new()
	config.set_value("audio", "volume", volume)
	config.set_value("audio", "music_volume", music_volume)
	config.set_value("audio", "sfx_volume", sfx_volume)
	config.set_value("display", "fullscreen", fullscreen)
	config.set_value("camera", "auto_orbit", auto_orbit)
	config.set_value("camera", "sensitivity", mouse_sensitivity)
	last_error = config.save(PATH)
	settings_changed.emit()

func _apply() -> void:
	var master_idx := AudioServer.get_bus_index("Master")
	if master_idx >= 0:
		AudioServer.set_bus_volume_db(master_idx, linear_to_db(maxf(volume, 0.0001)))
		AudioServer.set_bus_mute(master_idx, volume <= 0.0)
		
	var music_idx := AudioServer.get_bus_index("Music")
	if music_idx >= 0:
		AudioServer.set_bus_volume_db(music_idx, linear_to_db(maxf(music_volume, 0.0001)))
		AudioServer.set_bus_mute(music_idx, music_volume <= 0.0)
		
	var sfx_idx := AudioServer.get_bus_index("SFX")
	if sfx_idx >= 0:
		AudioServer.set_bus_volume_db(sfx_idx, linear_to_db(maxf(sfx_volume, 0.0001)))
		AudioServer.set_bus_mute(sfx_idx, sfx_volume <= 0.0)

	if not OS.has_feature("web"):
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN if fullscreen else DisplayServer.WINDOW_MODE_WINDOWED)
