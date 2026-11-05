class_name PantanalBoard
extends Node3D

## Controlador de atmosfera, materiais e iluminação noturna do Pantanal Lunar (`PANTANAL_ENV`).
## Direção artística inspirada em "Pântano Lunar com Tabuleiro Hexagonal":
## - Pântano noturno sereno e misterioso sob a luz do luar prateado.
## - Água onipresente envolvendo todo o tabuleiro (lagoa ampla ao norte, corixo calmo à esquerda com a canoa).
## - Árvore pantaneira retorcida detalhada à direita com copas orgânicas e raízes expostas.
## - Shader de água dinâmico (`pantanal_water.gdshader`) refletindo o luar prateado e o céu estrelado.
## - Leitura cristalina das 56 casas hexagonais e dos 9 slots da reserva sob iluminação lunar difusa.
## - Vaga-lumes pantaneiros suaves e sutis (sem partículas quadradas de neblina).

const PantanalWaterShader = preload("res://Assets/Shaders/pantanal_water.gdshader")

var _time: float = 0.0
var _swaying_nodes: Array[Node3D] = []
var _swaying_base_rots: Array[Vector3] = []
var _swaying_phases: Array[float] = []

var _firefly_nodes: Array[Node3D] = []
var _firefly_base_pos: Array[Vector3] = []
var _firefly_speeds: Array[float] = []

var _water_material: ShaderMaterial = null


func _ready() -> void:
	_setup_water_material()
	_polish_imported_materials()
	_collect_swaying_props()
	_build_nocturnal_pantanal_lighting()
	_build_subtle_fireflies()


func _setup_water_material() -> void:
	_water_material = ShaderMaterial.new()
	_water_material.shader = PantanalWaterShader
	_water_material.set_shader_parameter("deep_color", Color(0.045, 0.125, 0.165, 0.95))
	_water_material.set_shader_parameter("shallow_color", Color(0.085, 0.160, 0.155, 0.85))
	_water_material.set_shader_parameter("foam_color", Color(0.35, 0.48, 0.55, 0.35))
	_water_material.set_shader_parameter("metallic", 0.04)
	_water_material.set_shader_parameter("roughness", 0.06)
	_water_material.set_shader_parameter("specular", 0.98)
	_water_material.set_shader_parameter("flow_direction", Vector2(0.2, 0.95))
	_water_material.set_shader_parameter("flow_speed", 0.22)
	_water_material.set_shader_parameter("wave_height", 0.012)
	_water_material.set_shader_parameter("wave_frequency", 2.0)
	_water_material.set_shader_parameter("depth_distance", 0.85)
	_water_material.set_shader_parameter("foam_edge_distance", 0.05)
	_water_material.set_shader_parameter("fresnel_power", 3.2)
	_water_material.set_shader_parameter("moonlight_tint", Color("#7cb0d8"))
	_water_material.set_shader_parameter("moonlight_boost", 0.45)


func _process(delta: float) -> void:
	_time += delta

	# Brisa noturna suave nas árvores e vitória-régia
	for i in range(_swaying_nodes.size()):
		var node: Node3D = _swaying_nodes[i]
		if not is_instance_valid(node):
			continue
		var base_r: Vector3 = _swaying_base_rots[i]
		var phase: float = _swaying_phases[i]
		var sway: float = sin(_time * 0.75 + phase) * 0.007 + cos(_time * 1.35 + phase) * 0.003
		node.rotation = Vector3(base_r.x + sway * 0.35, base_r.y, base_r.z + sway)

	# Vaga-lumes pantaneiros flutuando suavemente sobre a água e juncos
	for i in range(_firefly_nodes.size()):
		var f: Node3D = _firefly_nodes[i]
		if not is_instance_valid(f):
			continue
		var b_pos: Vector3 = _firefly_base_pos[i]
		var spd: float = _firefly_speeds[i]
		var ox: float = sin(_time * spd + float(i) * 1.3) * 0.45
		var oy: float = sin(_time * (spd * 1.6) + float(i) * 0.7) * 0.22
		var oz: float = cos(_time * (spd * 0.9) + float(i) * 1.9) * 0.45
		f.position = Vector3(b_pos.x + ox, b_pos.y + oy, b_pos.z + oz)


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

			# Desativa projeção de sombras duras das copas para garantir leitura cristalina do tabuleiro
			if nname.contains("foliage") or nname.contains("canopy"):
				mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

			# Aplicar shader de água na malha do canal/lagoa
			if (nname.contains("water") or nname.contains("rio") or nname.contains("corixo")) and _water_material:
				mi.material_override = _water_material
				continue

			if not mi.mesh:
				continue

			for s_idx in range(mi.mesh.get_surface_count()):
				var mat: Material = mi.get_active_material(s_idx)
				var mat_name := mat.resource_name.to_lower() if mat else ""

				if mat_name.contains("water") or mat_name.contains("corixo"):
					if _water_material:
						mi.set_surface_override_material(s_idx, _water_material)
					continue

				if mat is BaseMaterial3D and not polished_mats.has(mat):
					polished_mats[mat] = true
					var bmat := mat as BaseMaterial3D
					var mname := bmat.resource_name.to_lower()

					if mname.contains("hex_player"):
						# Lajes de barro úmido aliado (leitura nítida sob luar)
						bmat.albedo_color = Color(0.42, 0.32, 0.23, 1.0)
						bmat.metallic = 0.0
						bmat.metallic_specular = 0.20
						bmat.roughness = 0.82
					elif mname.contains("hex_enemy"):
						# Lajes de barro úmido inimigo (mais escuro e distinto)
						bmat.albedo_color = Color(0.30, 0.22, 0.16, 1.0)
						bmat.metallic = 0.0
						bmat.metallic_specular = 0.16
						bmat.roughness = 0.86
					elif mname.contains("reserve"):
						bmat.albedo_color = Color(0.38, 0.28, 0.20, 1.0)
						bmat.metallic = 0.0
						bmat.metallic_specular = 0.20
						bmat.roughness = 0.82
					elif mname.contains("rim") or mname.contains("groove"):
						# Sulcos escuros bem definidos
						bmat.albedo_color = Color(0.03, 0.02, 0.015, 1.0)
						bmat.metallic = 0.0
						bmat.metallic_specular = 0.08
						bmat.roughness = 0.95
					elif mname.contains("canoe") or mname.contains("wood"):
						bmat.albedo_color = Color(0.26, 0.20, 0.14, 1.0)
						bmat.metallic = 0.02
						bmat.metallic_specular = 0.26
						bmat.roughness = 0.72
					elif mname.contains("victoria") or mname.contains("aquatic"):
						bmat.albedo_color = Color(0.14, 0.32, 0.16, 1.0)
						bmat.metallic = 0.0
						bmat.metallic_specular = 0.45
						bmat.roughness = 0.38
					elif mname.contains("grass") or mname.contains("reed"):
						bmat.albedo_color = Color(0.18, 0.28, 0.12, 1.0)
						bmat.metallic = 0.0
						bmat.metallic_specular = 0.22
						bmat.roughness = 0.65
					elif mname.contains("bark"):
						bmat.albedo_color = Color(0.20, 0.16, 0.12, 1.0)
						bmat.metallic = 0.0
						bmat.metallic_specular = 0.14
						bmat.roughness = 0.88
					elif mname.contains("foliage"):
						bmat.albedo_color = Color(0.12, 0.22, 0.10, 1.0)
						bmat.metallic = 0.0
						bmat.metallic_specular = 0.20
						bmat.roughness = 0.68
					elif mname.contains("eyes") or mname.contains("horror"):
						# Olhos misteriosos brilhando sob a água escura
						bmat.albedo_color = Color(0.96, 0.86, 0.36, 1.0)
						bmat.emission_enabled = true
						bmat.emission = Color(0.96, 0.86, 0.36)
						bmat.emission_energy_multiplier = 2.8
					else:
						bmat.metallic = 0.0
						bmat.metallic_specular = 0.16
						bmat.roughness = clampf(bmat.roughness, 0.68, 0.92)


func _collect_swaying_props() -> void:
	_swaying_nodes.clear()
	_swaying_base_rots.clear()
	_swaying_phases.clear()

	var stack: Array[Node] = [self]
	var idx: int = 0
	while not stack.is_empty():
		var curr: Node = stack.pop_back()
		for child in curr.get_children():
			stack.append(child)
			if child is Node3D:
				var n3d := child as Node3D
				var cname := n3d.name.to_lower()
				if cname.begins_with("tree_") or cname.begins_with("victoria_") or cname.begins_with("canoe_"):
					_swaying_nodes.append(n3d)
					_swaying_base_rots.append(n3d.rotation)
					_swaying_phases.append(float(idx) * 0.91)
					idx += 1


func _build_nocturnal_pantanal_lighting() -> void:
	if get_node_or_null("PantanalMoonLights"):
		return
	var lights := Node3D.new()
	lights.name = "PantanalMoonLights"
	add_child(lights)

	# 1. Luz do Luar Noturno Central (Prata/Azulado suave, mantendo 56 casas 100% legíveis)
	var arena_moon := SpotLight3D.new()
	arena_moon.name = "PantanalArenaMoonSpot"
	arena_moon.position = Vector3(0.0, 24.0, 0.5)
	arena_moon.rotation_degrees = Vector3(-85.0, 0.0, 0.0)
	arena_moon.light_color = Color("#d2e4f8")
	arena_moon.light_energy = 1.65
	arena_moon.light_volumetric_fog_energy = 0.25
	arena_moon.spot_range = 50.0
	arena_moon.spot_attenuation = 0.70
	arena_moon.spot_angle = 66.0
	arena_moon.spot_angle_attenuation = 1.9
	arena_moon.shadow_enabled = true
	arena_moon.shadow_bias = 0.04
	arena_moon.shadow_blur = 1.8
	lights.add_child(arena_moon)

	# 2. Preenchimento Noturno Azulado de Céu Estrelado (leitura uniforme sem escuridão opressiva)
	var sky_fill := OmniLight3D.new()
	sky_fill.name = "PantanalNightSkyFill"
	sky_fill.position = Vector3(0.0, 16.0, 0.0)
	sky_fill.light_color = Color("#96bddc")
	sky_fill.light_energy = 0.65
	sky_fill.light_volumetric_fog_energy = 0.0
	sky_fill.omni_range = 40.0
	sky_fill.omni_attenuation = 1.02
	lights.add_child(sky_fill)

	# 3. Preenchimento Acolhedor sobre os 9 Slots da Reserva Frontal
	var bench_fill := OmniLight3D.new()
	bench_fill.name = "PantanalBenchMoonFill"
	bench_fill.position = Vector3(0.0, 12.0, 7.8)
	bench_fill.light_color = Color("#b2d4f0")
	bench_fill.light_energy = 0.55
	bench_fill.light_volumetric_fog_energy = 0.0
	bench_fill.omni_range = 28.0
	bench_fill.omni_attenuation = 1.10
	lights.add_child(bench_fill)

	# 4. Acento Especular Lunar sobre o Canal Esquerdo e a Canoa
	var channel_rim := SpotLight3D.new()
	channel_rim.name = "WaterChannelMoonRim"
	channel_rim.position = Vector3(-6.2, 9.5, -1.0)
	channel_rim.rotation_degrees = Vector3(-65.0, 20.0, 0.0)
	channel_rim.light_color = Color("#9ac8ee")
	channel_rim.light_energy = 0.85
	channel_rim.light_volumetric_fog_energy = 0.40
	channel_rim.spot_range = 28.0
	channel_rim.spot_attenuation = 1.05
	channel_rim.spot_angle = 55.0
	channel_rim.spot_angle_attenuation = 1.6
	lights.add_child(channel_rim)

	# 5. Reflexo de Luar na Ampla Lagoa ao Fundo (Norte)
	var lagoon_rim := SpotLight3D.new()
	lagoon_rim.name = "NorthLagoonMoonRim"
	lagoon_rim.position = Vector3(0.0, 10.0, -13.0)
	lagoon_rim.rotation_degrees = Vector3(25.0, 180.0, 0.0)
	lagoon_rim.light_color = Color("#82b4dc")
	lagoon_rim.light_energy = 1.15
	lagoon_rim.light_volumetric_fog_energy = 1.60
	lagoon_rim.spot_range = 35.0
	lagoon_rim.spot_attenuation = 1.10
	lagoon_rim.spot_angle = 58.0
	lagoon_rim.spot_angle_attenuation = 1.5
	lagoon_rim.shadow_enabled = true
	lights.add_child(lagoon_rim)


func _build_subtle_fireflies() -> void:
	if get_node_or_null("PantanalFireflies"):
		return
	var ff_root := Node3D.new()
	ff_root.name = "PantanalFireflies"
	add_child(ff_root)

	var s_mesh := SphereMesh.new()
	s_mesh.radius = 0.022
	s_mesh.height = 0.044

	var ff_mat := StandardMaterial3D.new()
	ff_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	ff_mat.albedo_color = Color("#d8f448")
	ff_mat.emission_enabled = true
	ff_mat.emission = Color("#d8f448")
	ff_mat.emission_energy_multiplier = 3.5

	var firefly_spawn_points: Array[Vector3] = [
		Vector3(-8.2, 0.35, -2.5),
		Vector3(-7.8, 0.45, 1.5),
		Vector3(-8.6, 0.28, 4.2),
		Vector3(-4.5, 0.32, -8.2),
		Vector3(0.0, 0.38, -9.0),
		Vector3(4.8, 0.30, -8.5),
		Vector3(8.5, 0.48, -1.5),
		Vector3(8.8, 0.55, 2.2),
		Vector3(-3.2, 0.35, 7.8),
		Vector3(3.5, 0.32, 8.2),
	]

	for i in range(firefly_spawn_points.size()):
		var mi := MeshInstance3D.new()
		mi.name = "Firefly_%02d" % i
		mi.mesh = s_mesh
		mi.material_override = ff_mat
		mi.position = firefly_spawn_points[i]
		ff_root.add_child(mi)

		_firefly_nodes.append(mi)
		_firefly_base_pos.append(firefly_spawn_points[i])
		_firefly_speeds.append(0.85 + float(i % 3) * 0.3)
