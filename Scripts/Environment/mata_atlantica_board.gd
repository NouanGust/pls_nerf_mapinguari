class_name MataAtlanticaBoard
extends Node3D

## Controlador de atmosfera, materiais úmidos e iluminação noturna de meia-lua do Tabuleiro da Mata Atlântica (`MATA_ATLANTICA_ENV`).
## Aplica a direção visual de horror folclórico na Serra do Mar noturna:
## - Refinamento de materiais PBR em runtime (terra úmida compactada legível com distinção sutil entre fileiras
##   aliadas e inimigas, reflexos especulares úmidos localizados nas folhas largas, samambaias e riacho, e casca
##   musgosa sem aspecto plástico).
## - Iluminação difusa de meia-lua (`MataAtlanticaMoonLights`) filtrada pela copa fechada:
##   mantém as 56 casas hexagonais e os 9 slots de reserva nítidos e legíveis no centro, com acento especular
##   frio sobre o riacho esquerdo e separação de profundidade no paredão de árvores e rochas ao fundo.
## - Comportamentos ambientais sutis inspirados no documento de áudio:
##   1. Tremor esporádico de samambaias e plantas de folhas largas nas margens (sem vento uniforme), sugerindo
##      uma presença invisível espreitando fora da área de jogo.
##   2. Oscilação lenta nas copas altas e cipós pendentes.
##   3. Neblina orográfica rasteira nas margens externas e sobre o riacho esquerdo.
##   4. Gotículas de orvalho subindo lentamente junto ao paredão rochoso do fundo.

const RiverWaterShader = preload("res://Assets/Shaders/river_water.gdshader")

var _time: float = 0.0
var _swaying_trees: Array[Node3D] = []
var _swaying_base_rots: Array[Vector3] = []
var _swaying_phases: Array[float] = []

var _trembling_plants: Array[Node3D] = []
var _trembling_base_rots: Array[Vector3] = []
var _trembling_phases: Array[float] = []
var _active_tremor_idx: int = -1
var _tremor_timer: float = 0.0
var _next_tremor_cooldown: float = 2.4

var _water_material: ShaderMaterial = null


func _ready() -> void:
	_setup_water_material()
	_polish_imported_materials()
	_collect_forest_props()
	_build_nocturnal_atlantic_lighting()
	_build_subtle_fireflies()


func _setup_water_material() -> void:
	_water_material = ShaderMaterial.new()
	_water_material.shader = RiverWaterShader
	_water_material.set_shader_parameter("deep_color", Color(0.012, 0.048, 0.060, 0.98))
	_water_material.set_shader_parameter("shallow_color", Color(0.04, 0.18, 0.22, 0.88))
	_water_material.set_shader_parameter("foam_color", Color(0.62, 0.84, 0.94, 0.78))
	_water_material.set_shader_parameter("metallic", 0.08)
	_water_material.set_shader_parameter("roughness", 0.08)
	_water_material.set_shader_parameter("specular", 0.95)
	_water_material.set_shader_parameter("flow_direction", Vector2(0.0, 1.0))
	_water_material.set_shader_parameter("flow_speed", 0.65)
	_water_material.set_shader_parameter("wave_height", 0.036)
	_water_material.set_shader_parameter("wave_frequency", 2.8)
	_water_material.set_shader_parameter("depth_distance", 0.65)
	_water_material.set_shader_parameter("foam_edge_distance", 0.15)
	_water_material.set_shader_parameter("fresnel_power", 3.0)
	_water_material.set_shader_parameter("moonlight_tint", Color("#c0e2f8"))
	_water_material.set_shader_parameter("moonlight_boost", 0.85)


func _process(delta: float) -> void:
	_time += delta

	# 1. Brisa úmida suave nas árvores e cipós altos
	for i in range(_swaying_trees.size()):
		var tree: Node3D = _swaying_trees[i]
		if not is_instance_valid(tree):
			continue
		var base_r: Vector3 = _swaying_base_rots[i]
		var phase: float = _swaying_phases[i]
		var sway: float = sin(_time * 0.72 + phase) * 0.009 + cos(_time * 1.35 + phase) * 0.003
		tree.rotation = Vector3(base_r.x + sway * 0.5, base_r.y, base_r.z + sway)

	# 2. Tremor esporádico localizado em samambaias/folhas largas (como descrito no áudio)
	if not _trembling_plants.is_empty():
		if _active_tremor_idx >= 0:
			_tremor_timer -= delta
			if _tremor_timer <= 0.0:
				var prev_plant: Node3D = _trembling_plants[_active_tremor_idx]
				if is_instance_valid(prev_plant):
					prev_plant.rotation = _trembling_base_rots[_active_tremor_idx]
				_active_tremor_idx = -1
				_next_tremor_cooldown = 2.2 + fmod(_time * 1.37, 2.8)
			else:
				var plant: Node3D = _trembling_plants[_active_tremor_idx]
				if is_instance_valid(plant):
					var base_pr: Vector3 = _trembling_base_rots[_active_tremor_idx]
					var env_amp: float = sin(clampf(_tremor_timer / 0.65, 0.0, 1.0) * PI)
					var rustle: float = sin(_time * 28.0) * 0.055 * env_amp
					plant.rotation = Vector3(base_pr.x + rustle * 0.7, base_pr.y + rustle * 0.4, base_pr.z + rustle)
		else:
			_next_tremor_cooldown -= delta
			if _next_tremor_cooldown <= 0.0:
				_active_tremor_idx = int(abs(sin(_time * 17.3) * 997.0)) % _trembling_plants.size()
				_tremor_timer = 0.65


func _polish_imported_materials() -> void:
	var stack: Array[Node] = [self]
	var polished_mats: Dictionary = {}
	while not stack.is_empty():
		var curr: Node = stack.pop_back()
		for child in curr.get_children():
			stack.append(child)
		if curr is MeshInstance3D:
			var mi := curr as MeshInstance3D
			var nname := mi.name.to_lower()
			if nname in ["rock_13", "rock_14", "rock_15", "rock_16"]:
				mi.scale = Vector3(mi.scale.x * 1.28, mi.scale.y * 0.46, mi.scale.z * 1.15)
				mi.position.y *= 0.45
			if nname.contains("stream_surface") and _water_material:
				mi.material_override = _water_material
				continue
			if not mi.mesh:
				continue
			for s_idx in range(mi.mesh.get_surface_count()):
				var mat: Material = mi.get_active_material(s_idx)
				var mat_name := mat.resource_name.to_lower() if mat else ""
				if mat_name.contains("stream_water") or mat_name.contains("darkwater"):
					if _water_material:
						mi.set_surface_override_material(s_idx, _water_material)
					continue
				if mat is BaseMaterial3D and not polished_mats.has(mat):
					polished_mats[mat] = true
					var bmat := mat as BaseMaterial3D
					var mname := bmat.resource_name.to_lower()
					if mname.contains("rim"):
						bmat.albedo_color = Color(0.58, 0.48, 0.38, 1.0)
						bmat.metallic = 0.0
						bmat.metallic_specular = 0.20
						bmat.roughness = 0.80
						bmat.emission_enabled = true
						bmat.emission = Color(0.11, 0.14, 0.15)
						bmat.emission_energy_multiplier = 0.14
					elif mname.contains("hex_player") or mname.contains("hexearth_player"):
						bmat.albedo_color = Color(0.46, 0.34, 0.25, 1.0)
						bmat.metallic = 0.0
						bmat.metallic_specular = 0.16
						bmat.roughness = 0.85
					elif mname.contains("hex_enemy") or mname.contains("hexearth_enemy"):
						bmat.albedo_color = Color(0.35, 0.26, 0.20, 1.0)
						bmat.metallic = 0.0
						bmat.metallic_specular = 0.15
						bmat.roughness = 0.87
					elif mname.contains("reserve"):
						bmat.albedo_color = Color(0.44, 0.33, 0.24, 1.0)
						bmat.metallic = 0.0
						bmat.metallic_specular = 0.16
						bmat.roughness = 0.85
					elif mname.contains("groove"):
						bmat.albedo_color = Color(0.03, 0.025, 0.018, 1.0)
						bmat.metallic = 0.0
						bmat.metallic_specular = 0.10
						bmat.roughness = 0.92
					elif mname.contains("terrain_humus"):
						bmat.albedo_color = Color(0.28, 0.34, 0.24, 1.0)
						bmat.metallic = 0.0
						bmat.metallic_specular = 0.12
						bmat.roughness = 0.92
					elif mname.contains("stream_water") or mname.contains("darkwater"):
						bmat.albedo_color = Color(0.07, 0.19, 0.23, 1.0)
						bmat.metallic = 0.12
						bmat.metallic_specular = 0.88
						bmat.roughness = 0.12
						bmat.emission_enabled = true
						bmat.emission = Color(0.06, 0.16, 0.21)
						bmat.emission_energy_multiplier = 0.26
					elif mname.contains("broadleaf") or mname.contains("fern"):
						bmat.albedo_color = Color(0.22, 0.42, 0.24, 1.0) if mname.contains("fern") else Color(0.18, 0.36, 0.22, 1.0)
						bmat.metallic = 0.0
						bmat.metallic_specular = 0.28
						bmat.roughness = 0.62
					elif mname.contains("tree_foliage"):
						bmat.albedo_color = Color(0.15, 0.30, 0.18, 1.0)
						bmat.metallic = 0.0
						bmat.metallic_specular = 0.18
						bmat.roughness = 0.78
					elif mname.contains("rock_mossy") or mname.contains("mossywetrock"):
						bmat.albedo_color = Color(0.24, 0.30, 0.22, 1.0)
						bmat.metallic = 0.0
						bmat.metallic_specular = 0.12
						bmat.roughness = 0.90
					elif mname.contains("bark_wet"):
						bmat.albedo_color = Color(0.32, 0.26, 0.20, 1.0)
						bmat.metallic = 0.0
						bmat.metallic_specular = 0.12
						bmat.roughness = 0.88
					else:
						bmat.metallic = 0.0
						bmat.metallic_specular = 0.16
						bmat.roughness = clampf(bmat.roughness, 0.72, 0.92)


func _collect_forest_props() -> void:
	_swaying_trees.clear()
	_swaying_base_rots.clear()
	_swaying_phases.clear()
	_trembling_plants.clear()
	_trembling_base_rots.clear()
	_trembling_phases.clear()

	var stack: Array[Node] = [self]
	var idx: int = 0
	while not stack.is_empty():
		var curr: Node = stack.pop_back()
		for child in curr.get_children():
			stack.append(child)
			if child is Node3D:
				var n3d := child as Node3D
				var cname := n3d.name.to_lower()
				if (cname.begins_with("tree_") or cname.begins_with("vine_")) and not cname.ends_with("_mesh"):
					_swaying_trees.append(n3d)
					_swaying_base_rots.append(n3d.rotation)
					_swaying_phases.append(float(idx) * 0.77)
					idx += 1
				elif (cname.begins_with("fern_") or cname.begins_with("broadleaf_")) and not cname.ends_with("_mesh"):
					_trembling_plants.append(n3d)
					_trembling_base_rots.append(n3d.rotation)
					_trembling_phases.append(float(idx) * 1.13)
					idx += 1


func _build_nocturnal_atlantic_lighting() -> void:
	if get_node_or_null("MataAtlanticaMoonLights"):
		return
	var lights := Node3D.new()
	lights.name = "MataAtlanticaMoonLights"
	add_child(lights)

	# 1. Luz Difusa de Meia-Lua Filtrada pela Abertura do Dossel (centralizada para não projetar sombras duras das copas sobre o grid)
	var arena_spot := SpotLight3D.new()
	arena_spot.name = "ArenaHalfMoonSpot"
	arena_spot.position = Vector3(0.0, 25.0, 0.2)
	arena_spot.rotation_degrees = Vector3(-86.0, 0.0, 0.0)
	arena_spot.light_color = Color("#cce2f2")
	arena_spot.light_energy = 3.25
	arena_spot.light_volumetric_fog_energy = 0.22
	arena_spot.spot_range = 52.0
	arena_spot.spot_attenuation = 0.65
	arena_spot.spot_angle = 65.0
	arena_spot.spot_angle_attenuation = 2.1
	arena_spot.shadow_enabled = true
	arena_spot.shadow_bias = 0.03
	arena_spot.shadow_blur = 1.65
	lights.add_child(arena_spot)

	# 2. Preenchimento Atmosférico Frio-Esverdeado de Mata Fechada (leitura uniforme das 56 casas)
	var canopy_fill := OmniLight3D.new()
	canopy_fill.name = "OverheadCanopyFill"
	canopy_fill.position = Vector3(0.0, 16.0, 1.0)
	canopy_fill.light_color = Color("#b8d8e8")
	canopy_fill.light_energy = 1.18
	canopy_fill.light_volumetric_fog_energy = 0.0
	canopy_fill.omni_range = 34.0
	canopy_fill.omni_attenuation = 1.02
	lights.add_child(canopy_fill)

	# 3. Preenchimento Suave sobre a Reserva Frontal
	var bench_fill := OmniLight3D.new()
	bench_fill.name = "BenchSoftMoonFill"
	bench_fill.position = Vector3(0.0, 13.5, 7.2)
	bench_fill.light_color = Color("#c2dced")
	bench_fill.light_energy = 0.76
	bench_fill.light_volumetric_fog_energy = 0.0
	bench_fill.omni_range = 26.0
	bench_fill.omni_attenuation = 1.15
	lights.add_child(bench_fill)

	# 4. Acento Especular Úmido sobre o Riacho Esquerdo e Samambaias
	var stream_rim := SpotLight3D.new()
	stream_rim.name = "StreamWetRimLight"
	stream_rim.position = Vector3(-7.8, 9.2, -0.5)
	stream_rim.rotation_degrees = Vector3(-68.0, 15.0, 0.0)
	stream_rim.light_color = Color("#98cde8")
	stream_rim.light_energy = 1.55
	stream_rim.light_volumetric_fog_energy = 0.65
	stream_rim.spot_range = 24.0
	stream_rim.spot_attenuation = 1.05
	stream_rim.spot_angle = 52.0
	stream_rim.spot_angle_attenuation = 1.7
	lights.add_child(stream_rim)

	# 5. Contraluz de Profundidade na Encosta da Serra do Mar ao Norte (+feixe lunar na passagem)
	var back_rim := SpotLight3D.new()
	back_rim.name = "SerraDoMarBackRim"
	back_rim.position = Vector3(0.0, 9.5, -18.5)
	back_rim.rotation_degrees = Vector3(24.0, 180.0, 0.0)
	back_rim.light_color = Color("#72b0cc")
	back_rim.light_energy = 2.10
	back_rim.light_volumetric_fog_energy = 2.80
	back_rim.spot_range = 32.0
	back_rim.spot_attenuation = 1.05
	back_rim.spot_angle = 54.0
	back_rim.spot_angle_attenuation = 1.6
	back_rim.shadow_enabled = true
	lights.add_child(back_rim)

	# 6. Brilho Volumétrico de Neblina da Serra entre os Troncos ao Fundo
	var mist_glow := OmniLight3D.new()
	mist_glow.name = "SerraDoMarMistGlow"
	mist_glow.position = Vector3(0.0, 4.8, -12.5)
	mist_glow.light_color = Color("#5896b0")
	mist_glow.light_energy = 1.35
	mist_glow.light_volumetric_fog_energy = 3.20
	mist_glow.omni_range = 22.0
	mist_glow.omni_attenuation = 1.15
	lights.add_child(mist_glow)


func _build_subtle_fireflies() -> void:
	# Remove quaisquer nós antigos de partículas ou neblina que causavam retângulos na tela
	var old_fx := get_node_or_null("MataAtlanticaAtmosphereFX")
	if old_fx:
		old_fx.queue_free()
	if get_node_or_null("MataAtlanticaFireflies"):
		return

	var fireflies_root := Node3D.new()
	fireflies_root.name = "MataAtlanticaFireflies"
	add_child(fireflies_root)

	# Vaga-lumes minúsculos e orgânicos voando suavemente entre os arbustos e copas laterais
	# (usa SphereMesh 3D esférico minúsculo, sem Quads, eliminando qualquer risco de retângulos/bordas na tela)
	var zones := [
		{"name": "FirefliesWestRiver", "pos": Vector3(-9.5, 1.8, -1.0), "box": Vector3(2.2, 1.2, 11.0)},
		{"name": "FirefliesEastForest", "pos": Vector3(9.5, 1.8, -1.0), "box": Vector3(2.2, 1.2, 11.0)},
	]

	for z in zones:
		var p := GPUParticles3D.new()
		p.name = z["name"]
		p.position = z["pos"]
		p.amount = 12
		p.lifetime = 5.5
		p.preprocess = 2.0

		var proc := ParticleProcessMaterial.new()
		proc.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
		proc.emission_box_extents = z["box"]
		proc.direction = Vector3(0.0, 1.0, 0.0)
		proc.spread = 45.0
		proc.initial_velocity_min = 0.08
		proc.initial_velocity_max = 0.22
		proc.gravity = Vector3(0.0, 0.02, 0.0)
		proc.scale_min = 0.8
		proc.scale_max = 1.3
		proc.color = Color(0.68, 0.96, 0.45, 0.75)
		p.process_material = proc

		# Mesh esférico 3D minúsculo com material emissivo não-sombreado
		var s := SphereMesh.new()
		s.radius = 0.022
		s.height = 0.044
		s.radial_segments = 6
		s.rings = 4

		var smat := StandardMaterial3D.new()
		smat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		smat.albedo_color = Color(0.72, 0.98, 0.52, 0.85)
		smat.emission_enabled = true
		smat.emission = Color(0.72, 0.98, 0.52)
		smat.emission_energy_multiplier = 2.2
		s.material = smat
		p.draw_pass_1 = s

		fireflies_root.add_child(p)
