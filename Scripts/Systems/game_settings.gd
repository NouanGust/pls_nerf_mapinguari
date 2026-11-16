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
var show_fps: bool = false

# Configurações Gráficas e de Performance
var graphics_preset: String = "balanced" # "low", "balanced", "high", "custom"
var max_fps: int = 30 # 30, 60, 0 (ilimitado)
var render_scale: float = 0.85 # 0.5 a 1.0
var shadows_enabled: bool = true
var vsync: bool = true

var last_error: Error = OK

var fps_layer: CanvasLayer = null
var fps_label: Label = null
var _fps_update_timer: float = 0.0

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
		show_fps = bool(config.get_value("display", "show_fps", show_fps))
		
		graphics_preset = str(config.get_value("graphics", "preset", graphics_preset))
		max_fps = int(config.get_value("graphics", "max_fps", max_fps))
		render_scale = clampf(float(config.get_value("graphics", "render_scale", render_scale)), 0.5, 1.0)
		shadows_enabled = bool(config.get_value("graphics", "shadows_enabled", shadows_enabled))
		vsync = bool(config.get_value("graphics", "vsync", vsync))
	_setup_fps_counter()
	_apply()

func get_last_played_region() -> String:
	if last_played_region.is_empty():
		return "mata_atlantica"
	return last_played_region

func set_last_played_region(region_id: String) -> void:
	if region_id.is_empty():
		return
	last_played_region = region_id
	save_all_settings()

func apply_graphics_preset(preset_name: String) -> void:
	graphics_preset = preset_name
	match preset_name:
		"low":
			max_fps = 30
			render_scale = 0.65
			shadows_enabled = false
			vsync = true
		"balanced":
			max_fps = 30
			render_scale = 0.85
			shadows_enabled = true
			vsync = true
		"high":
			max_fps = 60
			render_scale = 1.0
			shadows_enabled = true
			vsync = true
	_apply()
	save_all_settings()
	settings_changed.emit()

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
		"graphics_preset":
			apply_graphics_preset(str(value))
			return
		"max_fps":
			max_fps = int(value)
			graphics_preset = "custom"
		"render_scale":
			render_scale = clampf(float(value), 0.5, 1.0)
			graphics_preset = "custom"
		"shadows_enabled":
			shadows_enabled = bool(value)
			graphics_preset = "custom"
		"vsync":
			vsync = bool(value)
			graphics_preset = "custom"
		"show_fps":
			show_fps = bool(value)
			if is_instance_valid(fps_layer):
				fps_layer.visible = show_fps
		_: return
	_apply()
	save_all_settings()
	settings_changed.emit()

func save_all_settings() -> void:
	var config := ConfigFile.new()
	config.set_value("audio", "volume", volume)
	config.set_value("audio", "music_volume", music_volume)
	config.set_value("audio", "sfx_volume", sfx_volume)
	config.set_value("display", "fullscreen", fullscreen)
	config.set_value("display", "show_fps", show_fps)
	config.set_value("camera", "auto_orbit", auto_orbit)
	config.set_value("camera", "sensitivity", mouse_sensitivity)
	config.set_value("gameplay", "last_played_region", last_played_region)
	config.set_value("gameplay", "caatinga_board_variant", caatinga_board_variant)
	config.set_value("gameplay", "caatinga_board_variant_v2", caatinga_board_variant)
	config.set_value("graphics", "preset", graphics_preset)
	config.set_value("graphics", "max_fps", max_fps)
	config.set_value("graphics", "render_scale", render_scale)
	config.set_value("graphics", "shadows_enabled", shadows_enabled)
	config.set_value("graphics", "vsync", vsync)
	last_error = config.save(PATH)

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
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED if vsync else DisplayServer.VSYNC_DISABLED)

	Engine.max_fps = max_fps
	var vp := get_viewport()
	if vp:
		vp.scaling_3d_mode = Viewport.SCALING_3D_MODE_FSR
		vp.scaling_3d_scale = render_scale

func _setup_fps_counter() -> void:
	fps_layer = CanvasLayer.new()
	fps_layer.name = "FPSCounterLayer"
	fps_layer.layer = 125
	add_child(fps_layer)

	var container := PanelContainer.new()
	container.name = "FPSContainer"
	container.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	container.offset_left = -465.0
	container.offset_right = -355.0
	container.offset_top = 21.0
	container.offset_bottom = 55.0
	container.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.04, 0.07, 0.12, 0.85)
	style.border_color = Color("#38bdf8")
	style.set_border_width_all(1)
	style.set_corner_radius_all(6)
	container.add_theme_stylebox_override("panel", style)

	fps_label = Label.new()
	fps_label.name = "FPSLabel"
	fps_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	fps_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	fps_label.add_theme_font_size_override("font_size", 12)
	fps_label.add_theme_color_override("font_color", Color("#4ade80"))
	fps_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fps_label.text = "30 FPS"
	container.add_child(fps_label)
	fps_layer.add_child(container)

	fps_layer.visible = show_fps

func _process(delta: float) -> void:
	if not show_fps or not is_instance_valid(fps_label):
		return
	_fps_update_timer += delta
	if _fps_update_timer >= 0.15:
		_fps_update_timer = 0.0
		var fps := Engine.get_frames_per_second()
		var msec := 1000.0 / maxf(float(fps), 1.0)
		fps_label.text = "%d FPS · %.1fms" % [fps, msec]
		if fps >= 28:
			fps_label.add_theme_color_override("font_color", Color("#4ade80"))
		elif fps >= 20:
			fps_label.add_theme_color_override("font_color", Color("#facc15"))
		else:
			fps_label.add_theme_color_override("font_color", Color("#f87171"))

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_F7:
			toggle_fps_counter()
			get_viewport().set_input_as_handled()

func toggle_fps_counter() -> void:
	show_fps = not show_fps
	if is_instance_valid(fps_layer):
		fps_layer.visible = show_fps
	var config := ConfigFile.new()
	if config.load(PATH) != OK:
		config = ConfigFile.new()
	config.set_value("display", "show_fps", show_fps)
	config.save(PATH)
