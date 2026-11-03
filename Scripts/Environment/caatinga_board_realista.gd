class_name CaatingaBoardRealista
extends Node3D

## Controlador de atmosfera, materiais e iluminação noturna do Tabuleiro da Caatinga (Versão Realista / Caatinga_Autochess).
## Mantém a versão anterior intacta como opção separada e entrega:
## - Refinamento de materiais em runtime (alta rugosidade, specular controlado, zero brilho plástico).
## - Atmosfera noturna árida do sertão (sem objeto de lua no céu), com luz fria prateada/azulada destacando a Floresta Branca.
## - Brisa seca realista nas copas caducifólias da Floresta Branca e poeira noturna tangencial sobre o barro.

var _time: float = 0.0
var _swaying_trees: Array[Node3D] = []
var _swaying_base_rots: Array[Vector3] = []
var _swaying_phases: Array[float] = []
var _breathing_nodes: Array[Node3D] = []
var _breathing_base_scales: Array[Vector3] = []
var _breathing_phases: Array[float] = []


func _ready() -> void:
	_remove_any_moon_nodes()
	_polish_imported_materials()
	_collect_natural_props()
	_build_realistic_sertao_lighting()
	_build_dry_dust_breeze()


func _process(delta: float) -> void:
	_time += delta

	# Brisa seca sutil balançando levemente as copas caducifólias da Floresta Branca
	for i in range(_swaying_trees.size()):
		var tree: Node3D = _swaying_trees[i]
		if not is_instance_valid(tree):
			continue
		var base_r: Vector3 = _swaying_base_rots[i]
		var phase: float = _swaying_phases[i]
		var wind_gust: float = sin(_time * 0.85 + phase) * 0.011 + cos(_time * 1.65 + phase) * 0.004
		tree.rotation = Vector3(base_r.x + wind_gust * 0.55, base_r.y, base_r.z + wind_gust)

	# Oscilação orgânica quase imperceptível nos detalhes de horror
	for i in range(_breathing_nodes.size()):
		var node: Node3D = _breathing_nodes[i]
		if not is_instance_valid(node):
			continue
		var base_s: Vector3 = _breathing_base_scales[i]
		var phase: float = _breathing_phases[i]
		var pulse: float = sin(_time * 0.90 + phase) * 0.015
		node.scale = base_s * (1.0 + pulse)


func _remove_any_moon_nodes() -> void:
	for moon_name in ["RealisticHorizonMoon", "FullMoonBackdrop"]:
		var existing := get_node_or_null(moon_name)
		if existing:
			existing.queue_free()


func _polish_imported_materials() -> void:
	## Garante que todos os materiais importados do GLB tenham rugosidade alta e especularidade baixa,
	## eliminando qualquer aspecto plástico no renderizador Forward+ do Godot.
	var stack: Array[Node] = [self]
	var polished_mats: Dictionary = {}
	while not stack.is_empty():
		var curr: Node = stack.pop_back()
		for child in curr.get_children():
			stack.append(child)
		if curr is MeshInstance3D:
			var mi := curr as MeshInstance3D
			if not mi.mesh:
				continue
			for s_idx in range(mi.mesh.get_surface_count()):
				var mat: Material = mi.get_active_material(s_idx)
				if mat is BaseMaterial3D and not polished_mats.has(mat):
					polished_mats[mat] = true
					var bmat := mat as BaseMaterial3D
					var mname := bmat.resource_name.to_lower()
					if not mname.contains("wire"):
						bmat.metallic = 0.0
						bmat.metallic_specular = 0.12
						bmat.roughness = maxf(bmat.roughness, 0.89)
					else:
						bmat.metallic_specular = 0.25
						bmat.roughness = maxf(bmat.roughness, 0.72)


func _collect_natural_props() -> void:
	_swaying_trees.clear()
	_swaying_base_rots.clear()
	_swaying_phases.clear()
	_breathing_nodes.clear()
	_breathing_base_scales.clear()
	_breathing_phases.clear()

	var stack: Array[Node] = [self]
	var idx: int = 0
	while not stack.is_empty():
		var curr: Node = stack.pop_back()
		for child in curr.get_children():
			stack.append(child)
			if child is Node3D:
				var n3d := child as Node3D
				var cname := n3d.name.to_lower()
				if (cname.begins_with("tree_pale_variant_") or cname.begins_with("mata_branca_")) and not cname.ends_with("_mesh") and cname != "mata_branca_trees":
					_swaying_trees.append(n3d)
					_swaying_base_rots.append(n3d.rotation)
					_swaying_phases.append(float(idx) * 0.85)
					idx += 1
				elif cname.begins_with("horror_knotted") or cname.begins_with("horror_looppath") or cname.begins_with("undergrowth_lajeiro_"):
					_breathing_nodes.append(n3d)
					_breathing_base_scales.append(n3d.scale)
					_breathing_phases.append(float(idx) * 0.75)
					idx += 1


func _build_realistic_sertao_lighting() -> void:
	if get_node_or_null("RealisticSertaoLights"):
		return
	var lights := Node3D.new()
	lights.name = "RealisticSertaoLights"
	add_child(lights)

	# 1. Luz lateral noturna fria realçando o relevo dos troncos pálidos, caveira bovina e rochas
	var night_key := OmniLight3D.new()
	night_key.name = "GrazingDuskWarmLight"
	night_key.position = Vector3(-13.5, 7.2, -3.0)
	night_key.light_color = Color("#8fb3db")
	night_key.light_energy = 0.74
	night_key.omni_range = 30.0
	night_key.omni_attenuation = 1.15
	lights.add_child(night_key)

	# 2. Preenchimento zenital noturno suave mantendo as 56 casas de barro e sulcos nítidos à noite
	var sky_fill := OmniLight3D.new()
	sky_fill.name = "OverheadSkyFill"
	sky_fill.position = Vector3(0.0, 14.0, 1.0)
	sky_fill.light_color = Color("#6b84a6")
	sky_fill.light_energy = 0.56
	sky_fill.omni_range = 34.0
	sky_fill.omni_attenuation = 1.25
	lights.add_child(sky_fill)

	# 3. Contraluz fria noturna ao fundo da Floresta Branca e trilha sinuosa
	var sky_rim := OmniLight3D.new()
	sky_rim.name = "NorthHorizonSkyRim"
	sky_rim.position = Vector3(-0.5, 7.5, -17.5)
	sky_rim.light_color = Color("#7ea3cc")
	sky_rim.light_energy = 0.66
	sky_rim.omni_range = 26.0
	lights.add_child(sky_rim)


func _build_dry_dust_breeze() -> void:
	if get_node_or_null("RealisticDryDustBreeze"):
		return
	var dust_root := Node3D.new()
	dust_root.name = "RealisticDryDustBreeze"
	add_child(dust_root)

	var zones := [
		{"name": "DustWestBank", "pos": Vector3(-10.5, 0.65, -0.5), "box": Vector3(2.8, 0.6, 14.0)},
		{"name": "DustEastBank", "pos": Vector3(10.5, 0.65, -0.5), "box": Vector3(2.8, 0.6, 14.0)},
		{"name": "DustNorthTrail", "pos": Vector3(0.0, 0.85, -12.5), "box": Vector3(12.0, 0.7, 3.5)},
	]

	for z in zones:
		var p := GPUParticles3D.new()
		p.name = z["name"]
		p.position = z["pos"]
		p.amount = 22
		p.lifetime = 4.8
		p.preprocess = 2.0

		var proc := ParticleProcessMaterial.new()
		proc.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
		proc.emission_box_extents = z["box"]
		proc.direction = Vector3(1.0, 0.02, 0.16).normalized()
		proc.spread = 14.0
		proc.initial_velocity_min = 0.8
		proc.initial_velocity_max = 1.6
		proc.gravity = Vector3(0.0, -0.02, 0.0)
		proc.scale_min = 0.06
		proc.scale_max = 0.13
		proc.color = Color(0.52, 0.57, 0.64, 0.14)
		p.process_material = proc

		var q := QuadMesh.new()
		q.size = Vector2(0.38, 0.12)
		var qmat := StandardMaterial3D.new()
		qmat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		qmat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		qmat.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
		qmat.albedo_color = Color(0.52, 0.57, 0.64, 0.13)
		q.material = qmat
		p.draw_pass_1 = q

		dust_root.add_child(p)
