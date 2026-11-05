class_name PantanalBoard
extends Node3D

## Controlador de atmosfera, materiais e iluminação de pôr do sol pantaneiro (`PANTANAL_ENV`).
## Aplica a direção artística inspirada no Pantanal (lagoas calmas, corixos, canoa de madeira,
## vegetação anfíbia, árvores retorcidas e pôr do sol de fogo refletindo na água):
## - Refinamento de materiais PBR em runtime para o renderizador Forward+ da Godot 4.
## - Shader de água dinâmico (`pantanal_water.gdshader`) na superfície da baía/corixo com reflexos de pôr do sol acobreado.
## - Iluminação quente de fim de tarde (`PantanalSunsetLights`):
##   mantém os 56 hexágonos e os 9 slots da reserva frontal perfeitamente visíveis e legíveis,
##   com luz rasante dourada sobre a água e silhuetas bem demarcadas sem criar breu.
## - Animação suave e procedural da brisa pantaneira sobre a copa das árvores e vitória-régia.

const PantanalWaterShader = preload("res://Assets/Shaders/pantanal_water.gdshader")

var _time: float = 0.0
var _swaying_nodes: Array[Node3D] = []
var _swaying_base_rots: Array[Vector3] = []
var _swaying_phases: Array[float] = []

var _water_material: ShaderMaterial = null


func _ready() -> void:
	_setup_water_material()
	_polish_imported_materials()
	_collect_swaying_props()
	_build_sunset_pantanal_lighting()


func _setup_water_material() -> void:
	_water_material = ShaderMaterial.new()
	_water_material.shader = PantanalWaterShader
	_water_material.set_shader_parameter("deep_color", Color(0.014, 0.042, 0.040, 0.98))
	_water_material.set_shader_parameter("shallow_color", Color(0.065, 0.098, 0.075, 0.88))
	_water_material.set_shader_parameter("foam_color", Color(0.48, 0.42, 0.32, 0.55))
	_water_material.set_shader_parameter("metallic", 0.04)
	_water_material.set_shader_parameter("roughness", 0.08)
	_water_material.set_shader_parameter("specular", 0.92)
	_water_material.set_shader_parameter("flow_direction", Vector2(0.25, 0.95))
	_water_material.set_shader_parameter("flow_speed", 0.35)
	_water_material.set_shader_parameter("wave_height", 0.020)
	_water_material.set_shader_parameter("wave_frequency", 2.2)
	_water_material.set_shader_parameter("depth_distance", 0.70)
	_water_material.set_shader_parameter("foam_edge_distance", 0.10)
	_water_material.set_shader_parameter("fresnel_power", 3.6)
	_water_material.set_shader_parameter("sunset_tint", Color("#f58638"))
	_water_material.set_shader_parameter("sunset_boost", 0.14)


func _process(delta: float) -> void:
	_time += delta

	# Brisa pantaneira suave nas árvores e galhos
	for i in range(_swaying_nodes.size()):
		var node: Node3D = _swaying_nodes[i]
		if not is_instance_valid(node):
			continue
		var base_r: Vector3 = _swaying_base_rots[i]
		var phase: float = _swaying_phases[i]
		var sway: float = sin(_time * 0.85 + phase) * 0.008 + cos(_time * 1.5 + phase) * 0.003
		node.rotation = Vector3(base_r.x + sway * 0.4, base_r.y, base_r.z + sway)


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
			
			# Desativa projeção de sombras duras das copas das árvores periféricas para não manchar o tabuleiro
			if nname.contains("foliage") or nname.contains("canopy"):
				mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			
			# Aplicar shader de água na malha do canal
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
						bmat.albedo_color = Color(0.50, 0.36, 0.26, 1.0)
						bmat.metallic = 0.0
						bmat.metallic_specular = 0.18
						bmat.roughness = 0.85
					elif mname.contains("hex_enemy"):
						bmat.albedo_color = Color(0.38, 0.28, 0.20, 1.0)
						bmat.metallic = 0.0
						bmat.metallic_specular = 0.16
						bmat.roughness = 0.88
					elif mname.contains("reserve"):
						bmat.albedo_color = Color(0.46, 0.34, 0.24, 1.0)
						bmat.metallic = 0.0
						bmat.metallic_specular = 0.16
						bmat.roughness = 0.85
					elif mname.contains("rim") or mname.contains("groove"):
						bmat.albedo_color = Color(0.04, 0.03, 0.02, 1.0)
						bmat.metallic = 0.0
						bmat.metallic_specular = 0.10
						bmat.roughness = 0.94
					elif mname.contains("canoe") or mname.contains("wood"):
						bmat.albedo_color = Color(0.34, 0.24, 0.16, 1.0)
						bmat.metallic = 0.02
						bmat.metallic_specular = 0.28
						bmat.roughness = 0.72
					elif mname.contains("victoria"):
						bmat.albedo_color = Color(0.18, 0.45, 0.22, 1.0)
						bmat.metallic = 0.0
						bmat.metallic_specular = 0.38
						bmat.roughness = 0.48
					elif mname.contains("grass") or mname.contains("reed"):
						bmat.albedo_color = Color(0.32, 0.44, 0.20, 1.0)
						bmat.metallic = 0.0
						bmat.metallic_specular = 0.20
						bmat.roughness = 0.78
					elif mname.contains("bark"):
						bmat.albedo_color = Color(0.28, 0.22, 0.17, 1.0)
						bmat.metallic = 0.0
						bmat.metallic_specular = 0.12
						bmat.roughness = 0.90
					elif mname.contains("foliage"):
						bmat.albedo_color = Color(0.20, 0.38, 0.18, 1.0)
						bmat.metallic = 0.0
						bmat.metallic_specular = 0.20
						bmat.roughness = 0.76
					elif mname.contains("wake") or mname.contains("horror"):
						bmat.albedo_color = Color(0.02, 0.04, 0.04, 0.85)
						bmat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
						bmat.roughness = 0.15
						bmat.metallic_specular = 0.85
					else:
						bmat.metallic = 0.0
						bmat.metallic_specular = 0.16
						bmat.roughness = clampf(bmat.roughness, 0.70, 0.92)


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


func _build_sunset_pantanal_lighting() -> void:
	if get_node_or_null("PantanalSunsetLights"):
		return
	var lights := Node3D.new()
	lights.name = "PantanalSunsetLights"
	add_child(lights)

	# 1. Luz do Sol Poente (Âmbar/Dourado suave vindo da direção oeste/sudoeste)
	# Ilumina suavemente o tabuleiro com tons quentes de fim de tarde
	var sunset_spot := SpotLight3D.new()
	sunset_spot.name = "PantanalSunsetSpot"
	sunset_spot.position = Vector3(-12.0, 18.0, 6.0)
	sunset_spot.rotation_degrees = Vector3(-48.0, -45.0, 0.0)
	sunset_spot.light_color = Color("#ffa662")
	sunset_spot.light_energy = 2.10
	sunset_spot.light_volumetric_fog_energy = 0.50
	sunset_spot.spot_range = 52.0
	sunset_spot.spot_attenuation = 0.90
	sunset_spot.spot_angle = 70.0
	sunset_spot.spot_angle_attenuation = 1.8
	sunset_spot.shadow_enabled = true
	sunset_spot.shadow_bias = 0.06
	sunset_spot.shadow_blur = 2.6
	lights.add_child(sunset_spot)

	# 2. Preenchimento do Céu Crepuscular Superior (Indigo / Azul Noturno suave)
	# Garante que todo o tabuleiro (56 casas) mantenha perfeita leitura e visibilidade
	var sky_fill := OmniLight3D.new()
	sky_fill.name = "PantanalSkyFill"
	sky_fill.position = Vector3(0.0, 16.0, 0.0)
	sky_fill.light_color = Color("#8db3d8")
	sky_fill.light_energy = 1.35
	sky_fill.light_volumetric_fog_energy = 0.0
	sky_fill.omni_range = 42.0
	sky_fill.omni_attenuation = 1.02
	lights.add_child(sky_fill)

	# 3. Preenchimento Acolhedor sobre a Reserva Frontal
	var bench_fill := OmniLight3D.new()
	bench_fill.name = "PantanalBenchFill"
	bench_fill.position = Vector3(0.0, 12.0, 7.8)
	bench_fill.light_color = Color("#ffbe8a")
	bench_fill.light_energy = 1.05
	bench_fill.light_volumetric_fog_energy = 0.0
	bench_fill.omni_range = 28.0
	bench_fill.omni_attenuation = 1.12
	lights.add_child(bench_fill)

	# 4. Acento Especular Dourado sobre o Corixo e a Canoa (à esquerda)
	var channel_rim := SpotLight3D.new()
	channel_rim.name = "WaterChannelRimLight"
	channel_rim.position = Vector3(-9.5, 8.5, 0.0)
	channel_rim.rotation_degrees = Vector3(-62.0, 25.0, 0.0)
	channel_rim.light_color = Color("#ffaa68")
	channel_rim.light_energy = 1.65
	channel_rim.light_volumetric_fog_energy = 0.70
	channel_rim.spot_range = 28.0
	channel_rim.spot_attenuation = 1.05
	channel_rim.spot_angle = 55.0
	channel_rim.spot_angle_attenuation = 1.6
	lights.add_child(channel_rim)

	# 5. Contraluz de Profundidade no Capão ao Fundo (Norte)
	var capao_rim := SpotLight3D.new()
	capao_rim.name = "PantanalCapaoRim"
	capao_rim.position = Vector3(0.0, 8.0, -17.5)
	capao_rim.rotation_degrees = Vector3(20.0, 180.0, 0.0)
	capao_rim.light_color = Color("#e87038")
	capao_rim.light_energy = 1.95
	capao_rim.light_volumetric_fog_energy = 2.20
	capao_rim.spot_range = 34.0
	capao_rim.spot_attenuation = 1.1
	capao_rim.spot_angle = 58.0
	capao_rim.spot_angle_attenuation = 1.5
	capao_rim.shadow_enabled = true
	lights.add_child(capao_rim)
