class_name RegionEnvironment
extends RefCounted

## Perfis atmosféricos dinâmicos por região/bioma brasileiro para o tabuleiro 3D
const PROFILES: Dictionary = {
	"amazonia": {
		"name": "Amazônia",
		"sky_top": Color("#0a1f14"),
		"sky_horizon": Color("#1b3c28"),
		"ground_bottom": Color("#08120b"),
		"ground_horizon": Color("#132719"),
		"ambient_color": Color("#3d664b"),
		"ambient_energy": 0.62,
		"sun_color": Color("#fbe3a8"),
		"sun_energy": 0.95,
		"sun_rotation": Vector3(-55.0, 35.0, 0.0),
		"fog_color": Color("#162e20"),
		"fog_density": 0.016,
		"glow_bloom": 0.32,
		"adjustment_contrast": 1.14,
		"adjustment_saturation": 1.18
	},
	"cerrado": {
		"name": "Cerrado",
		"sky_top": Color("#18293d"),
		"sky_horizon": Color("#6a4b2a"),
		"ground_bottom": Color("#1c1208"),
		"ground_horizon": Color("#402b17"),
		"ambient_color": Color("#7d6041"),
		"ambient_energy": 0.65,
		"sun_color": Color("#fcd68a"),
		"sun_energy": 1.05,
		"sun_rotation": Vector3(-50.0, -40.0, 0.0),
		"fog_color": Color("#3d2b1a"),
		"fog_density": 0.014,
		"glow_bloom": 0.26,
		"adjustment_contrast": 1.15,
		"adjustment_saturation": 1.16
	},
	"caatinga": {
		"name": "Caatinga",
		"sky_top": Color("#0b1528"),
		"sky_horizon": Color("#2a3446"),
		"ground_bottom": Color("#140805"),
		"ground_horizon": Color("#381c14"),
		"ambient_color": Color("#635969"),
		"ambient_energy": 0.64,
		"sun_color": Color("#dce8fa"),
		"sun_energy": 1.04,
		"sun_rotation": Vector3(-56.0, -18.0, 0.0),
		"fog_color": Color("#232433"),
		"fog_density": 0.015,
		"glow_bloom": 0.30,
		"adjustment_contrast": 1.22,
		"adjustment_saturation": 1.08
	},
	"caatinga_realista": {
		"name": "Caatinga (Realista)",
		"sky_top": Color("#04070f"),
		"sky_horizon": Color("#0d1524"),
		"ground_bottom": Color("#050404"),
		"ground_horizon": Color("#0a090d"),
		"ambient_color": Color("#364860"),
		"ambient_energy": 0.52,
		"sun_color": Color("#8db4de"),
		"sun_energy": 0.82,
		"sun_rotation": Vector3(-48.0, -32.0, 0.0),
		"fog_color": Color("#090f1a"),
		"fog_density": 0.008,
		"glow_bloom": 0.15,
		"adjustment_contrast": 1.18,
		"adjustment_saturation": 0.95
	},
	"pantanal": {
		"name": "Pantanal",
		"sky_top": Color("#0e2433"),
		"sky_horizon": Color("#204d57"),
		"ground_bottom": Color("#0a1518"),
		"ground_horizon": Color("#173138"),
		"ambient_color": Color("#406c75"),
		"ambient_energy": 0.60,
		"sun_color": Color("#d8f1f5"),
		"sun_energy": 0.98,
		"sun_rotation": Vector3(-48.0, 50.0, 0.0),
		"fog_color": Color("#1c3d45"),
		"fog_density": 0.018,
		"glow_bloom": 0.30,
		"adjustment_contrast": 1.12,
		"adjustment_saturation": 1.20
	},
	"mata_atlantica": {
		"name": "Mata Atlântica",
		"sky_top": Color("#0c2024"),
		"sky_horizon": Color("#2b4d36"),
		"ground_bottom": Color("#0a130e"),
		"ground_horizon": Color("#1a2e21"),
		"ambient_color": Color("#466b53"),
		"ambient_energy": 0.62,
		"sun_color": Color("#fbf2be"),
		"sun_energy": 0.95,
		"sun_rotation": Vector3(-52.0, 25.0, 0.0),
		"fog_color": Color("#1c3626"),
		"fog_density": 0.017,
		"glow_bloom": 0.28,
		"adjustment_contrast": 1.14,
		"adjustment_saturation": 1.18
	},
	"litoral": {
		"name": "Litoral",
		"sky_top": Color("#0d2740"),
		"sky_horizon": Color("#315d78"),
		"ground_bottom": Color("#0a1822"),
		"ground_horizon": Color("#1a374a"),
		"ambient_color": Color("#4a748c"),
		"ambient_energy": 0.68,
		"sun_color": Color("#fef1ce"),
		"sun_energy": 1.05,
		"sun_rotation": Vector3(-45.0, -55.0, 0.0),
		"fog_color": Color("#203e52"),
		"fog_density": 0.015,
		"glow_bloom": 0.28,
		"adjustment_contrast": 1.16,
		"adjustment_saturation": 1.18
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


static func apply_boss_atmosphere(world_env: WorldEnvironment, sun: DirectionalLight3D, region_id: String, duration: float = 1.2) -> void:
	if not world_env:
		return
	var env: Environment = world_env.environment
	if not env or not env.sky:
		return
	var sky_mat := env.sky.sky_material as ProceduralSkyMaterial
	if not sky_mat:
		return
	
	# Cores equilibradas para a atmosfera de Boss: sombrias e marcantes, porém legíveis
	var boss_sky_top := Color("#14161f")
	var boss_sky_horizon := Color("#3c232a")
	var boss_ground_bottom := Color("#0e0d12")
	var boss_ground_horizon := Color("#24171c")
	var boss_ambient := Color("#69555a")
	var boss_ambient_energy := 0.65
	var boss_sun_color := Color("#ffe2d4")
	var boss_sun_energy := 0.95
	var boss_fog_color := Color("#2c1a21")
	var boss_fog_density := 0.015

	if duration <= 0.0 or not world_env.is_inside_tree():
		sky_mat.sky_top_color = boss_sky_top
		sky_mat.sky_horizon_color = boss_sky_horizon
		sky_mat.ground_bottom_color = boss_ground_bottom
		sky_mat.ground_horizon_color = boss_ground_horizon
		env.ambient_light_color = boss_ambient
		env.ambient_light_energy = boss_ambient_energy
		env.fog_light_color = boss_fog_color
		env.fog_density = boss_fog_density
		if sun:
			sun.light_color = boss_sun_color
			sun.light_energy = boss_sun_energy
	else:
		var tween := world_env.create_tween().set_parallel(true)
		tween.set_ease(Tween.EASE_OUT)
		tween.set_trans(Tween.TRANS_QUAD)
		tween.tween_property(sky_mat, "sky_top_color", boss_sky_top, duration)
		tween.tween_property(sky_mat, "sky_horizon_color", boss_sky_horizon, duration)
		tween.tween_property(sky_mat, "ground_bottom_color", boss_ground_bottom, duration)
		tween.tween_property(sky_mat, "ground_horizon_color", boss_ground_horizon, duration)
		tween.tween_property(env, "ambient_light_color", boss_ambient, duration)
		tween.tween_property(env, "ambient_light_energy", boss_ambient_energy, duration)
		tween.tween_property(env, "fog_light_color", boss_fog_color, duration)
		tween.tween_property(env, "fog_density", boss_fog_density, duration)
		if sun:
			tween.tween_property(sun, "light_color", boss_sun_color, duration)
			tween.tween_property(sun, "light_energy", boss_sun_energy, duration)
