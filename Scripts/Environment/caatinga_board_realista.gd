class_name CaatingaBoardRealista
extends Node3D

## Controlador de atmosfera, materiais e iluminação noturna sombria do Tabuleiro da Caatinga (Versão Realista / Caatinga_Autochess).
## Aplicando as técnicas de direção visual 3D e atmosfera de horror no Godot 4:
## - Refinamento de materiais em runtime (alta rugosidade, specular controlado, zero brilho plástico).
## - Iluminação teatral em piscina de luz (`SpotLight3D` zenital com neblina volumétrica):
##   mantém as 56 casas hexagonais e os 9 slots da reserva extremamente nítidos e legíveis no centro,
##   enquanto a Floresta Branca ao redor mergulha na escuridão sombria com feixes volumétricos de contraluz.
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
	## eliminando qualquer aspecto plástico no renderizador Forward+ do Godot, e realça o contraste
	## dos ladrilhos e chanfros do tabuleiro contra o solo externo escuro.
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
					if mname.contains("rim"):
						bmat.albedo_color = Color(0.72, 0.58, 0.45, 1.0)
						bmat.metallic = 0.0
						bmat.metallic_specular = 0.18
						bmat.roughness = 0.84
						bmat.emission_enabled = true
						bmat.emission = Color(0.16, 0.13, 0.10)
						bmat.emission_energy_multiplier = 0.14
					elif mname.contains("hexclay_player"):
						bmat.albedo_color = Color(0.58, 0.38, 0.27, 1.0)
						bmat.metallic = 0.0
						bmat.metallic_specular = 0.12
						bmat.roughness = 0.90
					elif mname.contains("hexclay_enemy"):
						bmat.albedo_color = Color(0.47, 0.30, 0.21, 1.0)
						bmat.metallic = 0.0
						bmat.metallic_specular = 0.12
						bmat.roughness = 0.91
					elif mname.contains("reserve_earth"):
						bmat.albedo_color = Color(0.55, 0.36, 0.25, 1.0)
						bmat.metallic = 0.0
						bmat.metallic_specular = 0.12
						bmat.roughness = 0.90
					elif mname.contains("groove"):
						bmat.albedo_color = Color(0.06, 0.025, 0.018, 1.0)
						bmat.metallic = 0.0
						bmat.metallic_specular = 0.05
						bmat.roughness = 0.96
					elif mname.contains("whiteforest_bark"):
						bmat.albedo_color = Color(0.60, 0.59, 0.57, 1.0)
						bmat.metallic = 0.0
						bmat.metallic_specular = 0.08
						bmat.roughness = 0.94
					elif not mname.contains("wire"):
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

	# 1. Luz Difusa de Meia Lua (SpotLight3D amplo, alto e suave)
	# Sem foco concentrado/estourado: banha toda a clareira com luar prateado-azulado uniforme
	var arena_spot := SpotLight3D.new()
	arena_spot.name = "ArenaTacticalMoonSpot"
	arena_spot.position = Vector3(-2.0, 24.0, -2.5)
	arena_spot.rotation_degrees = Vector3(-76.0, -16.0, 0.0)
	arena_spot.light_color = Color("#d2e2f5")
	arena_spot.light_energy = 3.2
	arena_spot.light_volumetric_fog_energy = 0.15
	arena_spot.spot_range = 52.0
	arena_spot.spot_attenuation = 0.65
	arena_spot.spot_angle = 65.0
	arena_spot.spot_angle_attenuation = 2.2
	arena_spot.shadow_enabled = true
	arena_spot.shadow_bias = 0.03
	arena_spot.shadow_blur = 1.4
	lights.add_child(arena_spot)

	# 2. Preenchimento Atmosférico de Meia Lua (muito amplo e posicionado bem alto para iluminar por igual
	#    sem criar círculo de luz concentrado no chão)
	var sky_fill := OmniLight3D.new()
	sky_fill.name = "OverheadSkyFill"
	sky_fill.position = Vector3(0.0, 16.0, 1.5)
	sky_fill.light_color = Color("#c8daf0")
	sky_fill.light_energy = 1.15
	sky_fill.light_volumetric_fog_energy = 0.0
	sky_fill.omni_range = 32.0
	sky_fill.omni_attenuation = 1.05
	lights.add_child(sky_fill)

	# 3. Preenchimento Secundário Difuso sobre a Zona do Jogador e Banco de Reservas
	var bench_fill := OmniLight3D.new()
	bench_fill.name = "HalfMoonBenchSoftFill"
	bench_fill.position = Vector3(0.0, 13.5, 7.0)
	bench_fill.light_color = Color("#cdddf2")
	bench_fill.light_energy = 0.72
	bench_fill.light_volumetric_fog_energy = 0.0
	bench_fill.omni_range = 26.0
	bench_fill.omni_attenuation = 1.15
	lights.add_child(bench_fill)

	# 4. Contraluz de horizonte lunar suave vinda do norte através da Floresta Branca
	var sky_rim := SpotLight3D.new()
	sky_rim.name = "NorthHorizonSkyRim"
	sky_rim.position = Vector3(-0.4, 7.5, -21.0)
	sky_rim.rotation_degrees = Vector3(-24.0, 180.0, 0.0)
	sky_rim.light_color = Color("#6b8fbd")
	sky_rim.light_energy = 1.35
	sky_rim.light_volumetric_fog_energy = 1.65
	sky_rim.spot_range = 28.0
	sky_rim.spot_attenuation = 1.15
	sky_rim.spot_angle = 48.0
	sky_rim.spot_angle_attenuation = 1.8
	sky_rim.shadow_enabled = true
	lights.add_child(sky_rim)

	# 5. Toque sutil de luar rasante na Caveira Bovina
	var skull_accent := SpotLight3D.new()
	skull_accent.name = "GrazingDuskWarmLight"
	skull_accent.position = Vector3(-5.5, 4.2, 1.0)
	skull_accent.rotation_degrees = Vector3(-28.0, 52.0, 0.0)
	skull_accent.light_color = Color("#adc4e0")
	skull_accent.light_energy = 0.75
	skull_accent.light_volumetric_fog_energy = 0.8
	skull_accent.spot_range = 12.0
	skull_accent.spot_angle = 32.0
	skull_accent.spot_angle_attenuation = 1.8
	lights.add_child(skull_accent)


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
		p.amount = 20
		p.lifetime = 5.0
		p.preprocess = 2.0

		var proc := ParticleProcessMaterial.new()
		proc.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
		proc.emission_box_extents = z["box"]
		proc.direction = Vector3(1.0, 0.02, 0.16).normalized()
		proc.spread = 14.0
		proc.initial_velocity_min = 0.7
		proc.initial_velocity_max = 1.4
		proc.gravity = Vector3(0.0, -0.02, 0.0)
		proc.scale_min = 0.06
		proc.scale_max = 0.12
		proc.color = Color(0.45, 0.52, 0.60, 0.12)
		p.process_material = proc

		var q := QuadMesh.new()
		q.size = Vector2(0.36, 0.11)
		var qmat := StandardMaterial3D.new()
		qmat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		qmat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		qmat.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
		qmat.albedo_color = Color(0.45, 0.52, 0.60, 0.11)
		q.material = qmat
		p.draw_pass_1 = q

		dust_root.add_child(p)
