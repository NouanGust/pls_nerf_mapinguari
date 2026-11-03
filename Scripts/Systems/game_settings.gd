extends Node

signal settings_changed

const PATH := "user://settings.cfg"
var volume: float = 0.8
var music_volume: float = 0.8
var sfx_volume: float = 0.8
var fullscreen: bool = false
var auto_orbit: bool = false
var mouse_sensitivity: float = 0.25
var last_played_region: String = "mata_atlantica"
var caatinga_board_variant: String = "realista"
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
		last_played_region = str(config.get_value("gameplay", "last_played_region", "mata_atlantica"))
		caatinga_board_variant = str(config.get_value("gameplay", "caatinga_board_variant_v2", "realista"))
	_apply()

func get_last_played_region() -> String:
	if last_played_region.is_empty():
		return "mata_atlantica"
	return last_played_region

func set_last_played_region(region_id: String) -> void:
	if region_id.is_empty():
		return
	last_played_region = region_id
	var config := ConfigFile.new()
	if config.load(PATH) != OK:
		config = ConfigFile.new()
	config.set_value("audio", "volume", volume)
	config.set_value("audio", "music_volume", music_volume)
	config.set_value("audio", "sfx_volume", sfx_volume)
	config.set_value("display", "fullscreen", fullscreen)
	config.set_value("camera", "auto_orbit", auto_orbit)
	config.set_value("camera", "sensitivity", mouse_sensitivity)
	config.set_value("gameplay", "last_played_region", last_played_region)
	config.set_value("gameplay", "caatinga_board_variant", caatinga_board_variant)
	config.set_value("gameplay", "caatinga_board_variant_v2", caatinga_board_variant)
	last_error = config.save(PATH)

func update_setting(key: String, value: Variant) -> void:
	match key:
		"volume": volume = clampf(float(value), 0.0, 1.0)
		"music_volume": music_volume = clampf(float(value), 0.0, 1.0)
		"sfx_volume": sfx_volume = clampf(float(value), 0.0, 1.0)
		"fullscreen": fullscreen = bool(value)
		"auto_orbit": auto_orbit = bool(value)
		"mouse_sensitivity": mouse_sensitivity = clampf(float(value), 0.05, 1.0)
		"last_played_region": last_played_region = str(value)
		"caatinga_board_variant":
			var v := str(value).to_lower()
			caatinga_board_variant = "realista" if v in ["realista", "realistic", "true", "1"] else "horror"
		_: return
	_apply()
	var config := ConfigFile.new()
	config.set_value("audio", "volume", volume)
	config.set_value("audio", "music_volume", music_volume)
	config.set_value("audio", "sfx_volume", sfx_volume)
	config.set_value("display", "fullscreen", fullscreen)
	config.set_value("camera", "auto_orbit", auto_orbit)
	config.set_value("camera", "sensitivity", mouse_sensitivity)
	config.set_value("gameplay", "last_played_region", last_played_region)
	config.set_value("gameplay", "caatinga_board_variant", caatinga_board_variant)
	config.set_value("gameplay", "caatinga_board_variant_v2", caatinga_board_variant)
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
