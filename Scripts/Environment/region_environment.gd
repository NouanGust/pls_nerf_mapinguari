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
		"sky_top": Color("#040812"),
		"sky_horizon": Color("#0e1726"),
		"ground_bottom": Color("#040303"),
		"ground_horizon": Color("#0d0908"),
		"ambient_color": Color("#283448"),
		"ambient_energy": 0.28,
		"ambient_sky_contribution": 0.30,
		"sun_color": Color("#b4cae6"),
		"sun_energy": 0.55,
		"sun_rotation": Vector3(-50.0, -24.0, 0.0),
		"fog_color": Color("#080d17"),
		"fog_density": 0.0045,
		"volumetric_fog": true,
		"volumetric_fog_density": 0.010,
		"volumetric_fog_albedo": Color("#1c273a"),
		"volumetric_fog_emission": Color("#04070e"),
		"glow_bloom": 0.12,
		"tonemap_exposure": 1.0,
		"adjustment_brightness": 0.98,
		"adjustment_contrast": 1.12,
		"adjustment_saturation": 0.90
	},
	"caatinga_realista": {
		"name": "Caatinga (Realista)",
		"sky_top": Color("#03060f"),
		"sky_horizon": Color("#0b1322"),
		"ground_bottom": Color("#020204"),
		"ground_horizon": Color("#070910"),
		"ambient_color": Color("#253347"),
		"ambient_energy": 0.27,
		"ambient_sky_contribution": 0.30,
		"sun_color": Color("#b8cde6"),
		"sun_energy": 0.56,
		"sun_rotation": Vector3(-48.0, -28.0, 0.0),
		"fog_color": Color("#060b14"),
		"fog_density": 0.004,
		"volumetric_fog": true,
		"volumetric_fog_density": 0.010,
		"volumetric_fog_albedo": Color("#1a2638"),
		"volumetric_fog_emission": Color("#03060c"),
		"glow_bloom": 0.10,
		"tonemap_exposure": 0.98,
		"adjustment_brightness": 0.98,
		"adjustment_contrast": 1.12,
		"adjustment_saturation": 0.88
	},
	"pantanal": {
		"name": "Pantanal",
		"sky_top": Color("#0a1c30"),
		"sky_horizon": Color("#18344e"),
		"ground_bottom": Color("#081420"),
		"ground_horizon": Color("#122536"),
		"ambient_color": Color("#28445e"),
		"ambient_energy": 0.68,
		"ambient_sky_contribution": 0.70,
		"sun_color": Color("#d6e8fa"),
		"sun_energy": 1.15,
		"sun_rotation": Vector3(-55.0, 175.0, 0.0),
		"fog_color": Color("#0e2030"),
		"fog_density": 0.0035,
		"volumetric_fog": true,
		"volumetric_fog_density": 0.006,
		"volumetric_fog_albedo": Color("#1c344a"),
		"volumetric_fog_emission": Color("#05121c"),
		"glow_bloom": 0.18,
		"tonemap_exposure": 1.06,
		"adjustment_brightness": 1.02,
		"adjustment_contrast": 1.14,
		"adjustment_saturation": 1.08
	},
	"mata_atlantica": {
		"name": "Mata Atlântica",
		"sky_top": Color("#040c10"),
		"sky_horizon": Color("#0e242e"),
		"ground_bottom": Color("#051014"),
		"ground_horizon": Color("#0c2229"),
		"ambient_color": Color("#28424d"),
		"ambient_energy": 0.36,
		"ambient_sky_contribution": 0.35,
		"sun_color": Color("#b5d4e8"),
		"sun_energy": 0.54,
		"sun_rotation": Vector3(-68.0, 0.0, 0.0),
		"fog_color": Color("#0c2028"),
		"fog_density": 0.011,
		"volumetric_fog": true,
		"volumetric_fog_density": 0.019,
		"volumetric_fog_albedo": Color("#20404a"),
		"volumetric_fog_emission": Color("#061217"),
		"glow_bloom": 0.13,
		"tonemap_exposure": 1.02,
		"adjustment_brightness": 1.00,
		"adjustment_contrast": 1.12,
		"adjustment_saturation": 0.96
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
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_sky_contribution = float(profile.get("ambient_sky_contribution", 0.55))
	env.tonemap_mode = Environment.TONE_MAPPER_ACES
	env.tonemap_exposure = float(profile.get("tonemap_exposure", 1.04))

	# Oclusão de Ambiente (SSAO) e Iluminação Indireta (SSIL) para profundidade 3D realista
	# (baseado nas boas práticas de iluminação 3D no Godot 4)
	env.ssao_enabled = true
	env.ssao_radius = 1.15
	env.ssao_intensity = 2.35
	env.ssao_power = 1.55
	env.ssao_detail = 0.5
	env.ssao_sharpness = 0.92
	env.ssao_light_affect = 0.35

	env.ssil_enabled = true
	env.ssil_radius = 3.5
	env.ssil_intensity = 0.85
	env.ssil_sharpness = 0.9

	# Reflexos de tela (SSR) para água espelhada e superfícies molhadas
	env.ssr_enabled = true
	env.ssr_max_steps = 64
	env.ssr_fade_in = 0.15
	env.ssr_fade_out = 1.8
	env.ssr_depth_tolerance = 0.35

	# Glow & Brilho sutil
	env.glow_enabled = true
	env.glow_normalized = true
	env.glow_intensity = 0.50
	env.glow_hdr_threshold = 0.95
	env.glow_bloom = float(profile["glow_bloom"])
	env.glow_blend_mode = Environment.GLOW_BLEND_MODE_SOFTLIGHT

	# Ajustes de cor, brilho e contraste
	env.adjustment_enabled = true
	env.adjustment_brightness = float(profile.get("adjustment_brightness", 1.0))
	env.adjustment_contrast = float(profile["adjustment_contrast"])
	env.adjustment_saturation = float(profile["adjustment_saturation"])

	# Neblina de profundidade + Neblina Volumétrica (para atmosfera sombria e feixes de luz)
	env.fog_enabled = true
	env.fog_aerial_perspective = 0.65
	env.fog_sky_affect = 0.45

	var use_vol_fog: bool = bool(profile.get("volumetric_fog", false))
	env.volumetric_fog_enabled = use_vol_fog
	if use_vol_fog:
		env.volumetric_fog_density = float(profile.get("volumetric_fog_density", 0.024))
		env.volumetric_fog_albedo = profile.get("volumetric_fog_albedo", Color("#141e2e"))
		env.volumetric_fog_emission = profile.get("volumetric_fog_emission", Color("#020408"))
		env.volumetric_fog_emission_energy = 0.25
		env.volumetric_fog_anisotropy = 0.62
		env.volumetric_fog_length = 56.0
		env.volumetric_fog_ambient_inject = 0.18

	if sun:
		sun.light_indirect_energy = 1.15
		sun.light_volumetric_fog_energy = 1.25 if use_vol_fog else 1.0
		sun.shadow_enabled = true
		sun.directional_shadow_mode = DirectionalLight3D.SHADOW_PARALLEL_4_SPLITS
		sun.directional_shadow_max_distance = 64.0
		sun.shadow_bias = 0.03
		sun.shadow_normal_bias = 1.2
		sun.shadow_blur = 0.85

	if duration <= 0.0 or not world_env.is_inside_tree():
		# Aplicação direta instantânea
		sky_mat.sky_top_color = profile["sky_top"]
		sky_mat.sky_horizon_color = profile["sky_horizon"]
		sky_mat.ground_bottom_color = profile["ground_bottom"]
		sky_mat.ground_horizon_color = profile["ground_horizon"]
		sky_mat.sun_angle_max = 18.0

		env.ambient_light_color = profile["ambient_color"]
		env.ambient_light_energy = float(profile["ambient_energy"])
		env.fog_light_color = profile["fog_color"]
		env.fog_density = float(profile["fog_density"])

		if sun:
			sun.light_color = profile["sun_color"]
			sun.light_energy = float(profile["sun_energy"])
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
