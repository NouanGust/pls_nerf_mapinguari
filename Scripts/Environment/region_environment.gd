class_name RegionEnvironment
extends RefCounted

## Perfis atmosféricos dinâmicos por região/bioma brasileiro para o tabuleiro 3D
const PROFILES: Dictionary = {
	"amazonia": {
		"name": "Amazônia",
		"sky_top": Color("#1b3e2b"),
		"sky_horizon": Color("#4d805c"),
		"ground_bottom": Color("#132317"),
		"ground_horizon": Color("#2b5236"),
		"ambient_color": Color("#8acc9b"),
		"ambient_energy": 0.95,
		"sun_color": Color("#fff3d1"),
		"sun_energy": 1.35,
		"sun_rotation": Vector3(-55.0, 35.0, 0.0),
		"fog_color": Color("#477556"),
		"fog_density": 0.0032,
		"glow_bloom": 0.28,
		"adjustment_contrast": 1.08,
		"adjustment_saturation": 1.15
	},
	"cerrado": {
		"name": "Cerrado",
		"sky_top": Color("#356794"),
		"sky_horizon": Color("#d6b070"),
		"ground_bottom": Color("#382917"),
		"ground_horizon": Color("#85653d"),
		"ambient_color": Color("#e8cba2"),
		"ambient_energy": 1.05,
		"sun_color": Color("#ffebae"),
		"sun_energy": 1.5,
		"sun_rotation": Vector3(-50.0, -40.0, 0.0),
		"fog_color": Color("#d1a770"),
		"fog_density": 0.0018,
		"glow_bloom": 0.22,
		"adjustment_contrast": 1.09,
		"adjustment_saturation": 1.12
	},
	"caatinga": {
		"name": "Caatinga",
		"sky_top": Color("#3b74a8"),
		"sky_horizon": Color("#e0996e"),
		"ground_bottom": Color("#422214"),
		"ground_horizon": Color("#965435"),
		"ambient_color": Color("#f2bc91"),
		"ambient_energy": 1.1,
		"sun_color": Color("#fff2df"),
		"sun_energy": 1.65,
		"sun_rotation": Vector3(-65.0, -20.0, 0.0),
		"fog_color": Color("#d99671"),
		"fog_density": 0.0015,
		"glow_bloom": 0.2,
		"adjustment_contrast": 1.12,
		"adjustment_saturation": 1.08
	},
	"pantanal": {
		"name": "Pantanal",
		"sky_top": Color("#276394"),
		"sky_horizon": Color("#68b8c4"),
		"ground_bottom": Color("#173138"),
		"ground_horizon": Color("#36727d"),
		"ambient_color": Color("#9ce3eb"),
		"ambient_energy": 1.0,
		"sun_color": Color("#f8fcff"),
		"sun_energy": 1.4,
		"sun_rotation": Vector3(-48.0, 50.0, 0.0),
		"fog_color": Color("#57aab5"),
		"fog_density": 0.0028,
		"glow_bloom": 0.26,
		"adjustment_contrast": 1.07,
		"adjustment_saturation": 1.16
	},
	"mata_atlantica": {
		"name": "Mata Atlântica",
		"sky_top": Color("#204950"),
		"sky_horizon": Color("#6ea37b"),
		"ground_bottom": Color("#1a2b20"),
		"ground_horizon": Color("#395e45"),
		"ambient_color": Color("#a6deb4"),
		"ambient_energy": 0.95,
		"sun_color": Color("#fef6db"),
		"sun_energy": 1.35,
		"sun_rotation": Vector3(-52.0, 25.0, 0.0),
		"fog_color": Color("#568a6b"),
		"fog_density": 0.003,
		"glow_bloom": 0.25,
		"adjustment_contrast": 1.08,
		"adjustment_saturation": 1.14
	},
	"litoral": {
		"name": "Litoral",
		"sky_top": Color("#226eb5"),
		"sky_horizon": Color("#8cd1f8"),
		"ground_bottom": Color("#163a52"),
		"ground_horizon": Color("#4183a6"),
		"ambient_color": Color("#b4e5fc"),
		"ambient_energy": 1.15,
		"sun_color": Color("#fffdf5"),
		"sun_energy": 1.55,
		"sun_rotation": Vector3(-45.0, -55.0, 0.0),
		"fog_color": Color("#7ac0e8"),
		"fog_density": 0.002,
		"glow_bloom": 0.24,
		"adjustment_contrast": 1.1,
		"adjustment_saturation": 1.15
	}
}

static func get_profile(region_id: String) -> Dictionary:
	return PROFILES.get(region_id.to_lower(), PROFILES["cerrado"])

static func apply_to(world_env: WorldEnvironment, sun: DirectionalLight3D, region_id: String, duration: float = 0.0) -> void:
	var profile: Dictionary = get_profile(region_id)
	
	if not world_env:
		return

	# Garantir Environment configurado
	var env: Environment = world_env.environment
	if not env:
		env = Environment.new()
		world_env.environment = env

	# Configuração de Céu Procedural
	var sky: Sky = env.sky
	var sky_mat: ProceduralSkyMaterial = null
	if not sky:
		sky = Sky.new()
		env.sky = sky
	if sky.sky_material is ProceduralSkyMaterial:
		sky_mat = sky.sky_material as ProceduralSkyMaterial
	else:
		sky_mat = ProceduralSkyMaterial.new()
		sky.sky_material = sky_mat

	env.background_mode = Environment.BG_SKY
	env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	env.tonemap_mode = Environment.TONE_MAPPER_ACES
	env.tonemap_exposure = 1.06
	
	# Glow & Brilho sutil
	env.glow_enabled = true
	env.glow_normalized = true
	env.glow_intensity = 0.45
	env.glow_bloom = float(profile["glow_bloom"])
	env.glow_blend_mode = Environment.GLOW_BLEND_MODE_SOFTLIGHT

	# Ajustes de cor e contraste
	env.adjustment_enabled = true
	env.adjustment_contrast = float(profile["adjustment_contrast"])
	env.adjustment_saturation = float(profile["adjustment_saturation"])

	# Neblina atmosférica
	env.fog_enabled = true
	env.fog_aerial_perspective = 0.5
	env.fog_sky_affect = 0.4

	if duration <= 0.0 or not world_env.is_inside_tree():
		# Aplicação direta instantânea
		sky_mat.sky_top_color = profile["sky_top"]
		sky_mat.sky_horizon_color = profile["sky_horizon"]
		sky_mat.ground_bottom_color = profile["ground_bottom"]
		sky_mat.ground_horizon_color = profile["ground_horizon"]
		sky_mat.sun_angle_max = 25.0

		env.ambient_light_color = profile["ambient_color"]
		env.ambient_light_energy = float(profile["ambient_energy"])
		env.fog_light_color = profile["fog_color"]
		env.fog_density = float(profile["fog_density"])

		if sun:
			sun.light_color = profile["sun_color"]
			sun.light_energy = float(profile["sun_energy"])
			sun.light_indirect_energy = 1.2
			sun.shadow_enabled = true
			sun.shadow_blur = 1.4
			var rot: Vector3 = profile["sun_rotation"]
			sun.rotation_degrees = rot
	else:
		# Transição suave via Tween
		var tween: Tween = world_env.create_tween().set_parallel(true)
		tween.set_ease(Tween.EASE_OUT)
		tween.set_trans(Tween.TRANS_QUAD)

		tween.tween_property(sky_mat, "sky_top_color", profile["sky_top"], duration)
		tween.tween_property(sky_mat, "sky_horizon_color", profile["sky_horizon"], duration)
		tween.tween_property(sky_mat, "ground_bottom_color", profile["ground_bottom"], duration)
		tween.tween_property(sky_mat, "ground_horizon_color", profile["ground_horizon"], duration)

		tween.tween_property(env, "ambient_light_color", profile["ambient_color"], duration)
		tween.tween_property(env, "ambient_light_energy", float(profile["ambient_energy"]), duration)
		tween.tween_property(env, "fog_light_color", profile["fog_color"], duration)
		tween.tween_property(env, "fog_density", float(profile["fog_density"]), duration)

		if sun:
			tween.tween_property(sun, "light_color", profile["sun_color"], duration)
			tween.tween_property(sun, "light_energy", float(profile["sun_energy"]), duration)
			var rot: Vector3 = profile["sun_rotation"]
			tween.tween_property(sun, "rotation_degrees", rot, duration)
