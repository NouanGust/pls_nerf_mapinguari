class_name CaatingaBoardHorror
extends Node3D

## Controlador atmosférico e de horror vivo do Tabuleiro da Caatinga ("O Território Assombra").
## Implementa:
## 1. Lua Cheia pálida e halo noturno no horizonte da trilha sinuosa + luar azulado/frio contrastando com o barro rachado.
## 2. "Respiração" sutil e inquietante das formações rochosas-ossadas (breathing_ossuary_*) nas bordas externas.
## 3. Oscilação quase imperceptível dos galhos secos da Mata Branca ("floresta de ossos").
## 4. Vento árido arrastando areia fina nas bordas externas e brilhos cristalinos sutis no solo pedregoso,
##    preservando 100% da legibilidade tática no centro da arena e no banco.

var _time: float = 0.0
var _breathing_nodes: Array[Node3D] = []
var _breathing_base_scales: Array[Vector3] = []
var _breathing_phases: Array[float] = []

var _swaying_trees: Array[Node3D] = []
var _swaying_base_rots: Array[Vector3] = []
var _swaying_phases: Array[float] = []

var _watcher_eyes: Array[StandardMaterial3D] = []
var _moon_halo_mat: StandardMaterial3D = null
var _eerie_rim_light: OmniLight3D = null


func _ready() -> void:
	_collect_horror_props()
	_build_full_moon_backdrop()
	_build_canyon_horror_lighting()
	_build_arid_sand_wind_particles()
	_build_crystalline_ground_glints()
	_build_mata_branca_watcher_glints()


func _process(delta: float) -> void:
	_time += delta

	# 1. Respiração inquietante das ossadas/rochas (contração e expansão lenta de ~4.5% a 6%)
	for i in range(_breathing_nodes.size()):
		var node: Node3D = _breathing_nodes[i]
		if not is_instance_valid(node):
			continue
		var base_s: Vector3 = _breathing_base_scales[i]
		var phase: float = _breathing_phases[i]
		var breath: float = sin(_time * 1.15 + phase)
		var secondary: float = cos(_time * 0.55 + phase * 1.7) * 0.35
		var pulse: float = (breath + secondary) * 0.038
		node.scale = Vector3(
			base_s.x * (1.0 + pulse * 1.15),
			base_s.y * (1.0 + pulse * 0.85),
			base_s.z * (1.0 + pulse * 1.05)
		)

	# 2. Sussurro/oscilação sutil dos galhos esqueléticos da Mata Branca
	for i in range(_swaying_trees.size()):
		var tree: Node3D = _swaying_trees[i]
		if not is_instance_valid(tree):
			continue
		var base_r: Vector3 = _swaying_base_rots[i]
		var phase: float = _swaying_phases[i]
		var sway_z: float = sin(_time * 0.72 + phase) * 0.018
		var sway_x: float = cos(_time * 0.54 + phase * 1.3) * 0.014
		tree.rotation = Vector3(base_r.x + sway_x, base_r.y, base_r.z + sway_z)

	# 3. Pulsação fantasmagórica do halo lunar e da luz das órbitas/fendas
	if _moon_halo_mat:
		var halo_alpha: float = 0.22 + 0.05 * sin(_time * 0.85)
		_moon_halo_mat.albedo_color.a = halo_alpha

	if is_instance_valid(_eerie_rim_light):
		_eerie_rim_light.light_energy = 0.85 + 0.20 * sin(_time * 1.4)

	for idx in range(_watcher_eyes.size()):
		var mat: StandardMaterial3D = _watcher_eyes[idx]
		if mat:
			var blink: float = sin(_time * 0.9 + float(idx) * 2.1)
			var alpha: float = clampf((blink - 0.15) * 0.85, 0.0, 0.75)
			mat.albedo_color.a = alpha


func _collect_horror_props() -> void:
	_breathing_nodes.clear()
	_breathing_base_scales.clear()
	_breathing_phases.clear()
	_swaying_trees.clear()
	_swaying_base_rots.clear()
	_swaying_phases.clear()

	var stack: Array[Node] = [self]
	var phase_idx: int = 0
	while not stack.is_empty():
		var current: Node = stack.pop_back()
		for child in current.get_children():
			stack.append(child)
			if child is Node3D:
				var n3d := child as Node3D
				var cname := n3d.name.to_lower()
				if cname.begins_with("breathing_ossuary_") or cname.begins_with("boulder_"):
					_breathing_nodes.append(n3d)
					_breathing_base_scales.append(n3d.scale)
					_breathing_phases.append(float(phase_idx) * 0.95)
					phase_idx += 1
				elif cname.begins_with("mata_branca_") and not cname.ends_with("_mesh") and cname != "mata_branca_trees":
					_swaying_trees.append(n3d)
					_swaying_base_rots.append(n3d.rotation)
					_swaying_phases.append(float(phase_idx) * 1.1)
					phase_idx += 1


func _build_full_moon_backdrop() -> void:
	if get_node_or_null("FullMoonBackdrop"):
		return
	var moon_root := Node3D.new()
	moon_root.name = "FullMoonBackdrop"
	# Posicionada ao fundo da trilha sinuosa (Norte / -Z) enquadrada pelos galhos secos da Mata Branca
	moon_root.position = Vector3(0.0, 11.5, -28.0)
	add_child(moon_root)

	# Disco da Lua Cheia pálida
	var moon_disc := MeshInstance3D.new()
	moon_disc.name = "MoonDisc"
	var sphere := SphereMesh.new()
	sphere.radius = 3.8
	sphere.height = 7.6
	sphere.radial_segments = 32
	sphere.rings = 16
	moon_disc.mesh = sphere
	moon_disc.scale = Vector3(1.0, 1.0, 0.22)

	var moon_mat := StandardMaterial3D.new()
	moon_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	moon_mat.albedo_color = Color("#f4f1de")
	moon_mat.emission_enabled = true
	moon_mat.emission = Color("#dbeafe")
	moon_mat.emission_energy_multiplier = 1.65
	moon_disc.material_override = moon_mat
	moon_root.add_child(moon_disc)

	# Halo nebuloso ao redor da Lua Cheia
	var moon_halo := MeshInstance3D.new()
	moon_halo.name = "MoonHalo"
	var halo_sphere := SphereMesh.new()
	halo_sphere.radius = 7.4
	halo_sphere.height = 14.8
	halo_sphere.radial_segments = 24
	halo_sphere.rings = 12
	moon_halo.mesh = halo_sphere
	moon_halo.scale = Vector3(1.15, 1.0, 0.15)

	_moon_halo_mat = StandardMaterial3D.new()
	_moon_halo_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_moon_halo_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_moon_halo_mat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	_moon_halo_mat.albedo_color = Color(0.56, 0.72, 0.94, 0.22)
	moon_halo.material_override = _moon_halo_mat
	moon_root.add_child(moon_halo)


func _build_canyon_horror_lighting() -> void:
	if get_node_or_null("CanyonHorrorLights"):
		return
	var lights_root := Node3D.new()
	lights_root.name = "CanyonHorrorLights"
	add_child(lights_root)

	# Contraluz fria vinda da trilha da Lua Cheia ao fundo, destacando as silhuetas de ossos da Mata Branca
	var moon_rim := OmniLight3D.new()
	moon_rim.name = "MoonTrailBacklight"
	moon_rim.position = Vector3(0.0, 5.5, -16.5)
	moon_rim.light_color = Color("#93c5fd")
	moon_rim.light_energy = 1.25
	moon_rim.omni_range = 24.0
	moon_rim.omni_attenuation = 1.2
	lights_root.add_child(moon_rim)

	# Luz espectral pálida sobre o totem de crânio bovino frontal esquerdo (Sudoeste / -X, +Z)
	_eerie_rim_light = OmniLight3D.new()
	_eerie_rim_light.name = "SkullTotemWestLight"
	_eerie_rim_light.position = Vector3(-8.2, 2.3, 8.2)
	_eerie_rim_light.light_color = Color("#cbd5e1")
	_eerie_rim_light.light_energy = 0.85
	_eerie_rim_light.omni_range = 5.5
	lights_root.add_child(_eerie_rim_light)

	# Luz pálida secundária no totem de crânio direito (Sudeste / +X, +Z)
	var east_skull_light := OmniLight3D.new()
	east_skull_light.name = "SkullTotemEastLight"
	east_skull_light.position = Vector3(8.2, 2.3, 8.2)
	east_skull_light.light_color = Color("#cbd5e1")
	east_skull_light.light_energy = 0.75
	east_skull_light.omni_range = 5.2
	lights_root.add_child(east_skull_light)

	# Luz quente terrosa bem baixa sobre o centro do barro rachado (contraste xilogravura com o luar frio)
	var clay_warm_fill := OmniLight3D.new()
	clay_warm_fill.name = "CrackedClayWarmFill"
	clay_warm_fill.position = Vector3(0.0, 4.2, 0.5)
	clay_warm_fill.light_color = Color("#d97746")
	clay_warm_fill.light_energy = 0.42
	clay_warm_fill.omni_range = 14.5
	lights_root.add_child(clay_warm_fill)


func _build_arid_sand_wind_particles() -> void:
	if get_node_or_null("AridSandWindBorders"):
		return
	var wind_root := Node3D.new()
	wind_root.name = "AridSandWindBorders"
	add_child(wind_root)

	# Duas faixas periféricas de vento arrastando areia fina e névoa seca nas bordas (fora da malha central)
	var emitters_cfg := [
		{"name": "SandWindWest", "pos": Vector3(-10.5, 0.9, -1.0), "box": Vector3(2.8, 0.9, 14.0)},
		{"name": "SandWindEast", "pos": Vector3(10.5, 0.9, -1.0), "box": Vector3(2.8, 0.9, 14.0)},
		{"name": "SandWindTrailBack", "pos": Vector3(0.0, 1.1, -13.5), "box": Vector3(12.0, 1.0, 3.5)},
	]

	for cfg in emitters_cfg:
		var particles := GPUParticles3D.new()
		particles.name = cfg["name"]
		particles.position = cfg["pos"]
		particles.amount = 28
		particles.lifetime = 4.2
		particles.preprocess = 2.0
		particles.explosiveness = 0.0

		var proc := ParticleProcessMaterial.new()
		proc.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
		proc.emission_box_extents = cfg["box"]
		proc.direction = Vector3(1.0, 0.04, 0.25).normalized()
		proc.spread = 16.0
		proc.initial_velocity_min = 1.1
		proc.initial_velocity_max = 2.2
		proc.gravity = Vector3(0.0, -0.05, 0.0)
		proc.scale_min = 0.08
		proc.scale_max = 0.18
		proc.color = Color(0.82, 0.75, 0.66, 0.26)
		particles.process_material = proc

		var quad := QuadMesh.new()
		quad.size = Vector2(0.45, 0.16)
		var qmat := StandardMaterial3D.new()
		qmat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		qmat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		qmat.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
		qmat.albedo_color = Color(0.84, 0.78, 0.70, 0.24)
		quad.material = qmat
		particles.draw_pass_1 = quad

		wind_root.add_child(particles)


func _build_crystalline_ground_glints() -> void:
	if get_node_or_null("CrystallineGroundGlints"):
		return
	# Brilhos cristalinos sutis no solo pedregoso das bordas (mencionados no áudio de direção de arte)
	var glints := GPUParticles3D.new()
	glints.name = "CrystallineGroundGlints"
	glints.position = Vector3(0.0, 0.35, -1.5)
	glints.amount = 22
	glints.lifetime = 3.2
	glints.preprocess = 1.5

	var proc := ParticleProcessMaterial.new()
	proc.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_RING
	proc.emission_ring_axis = Vector3(0.0, 1.0, 0.0)
	proc.emission_ring_radius = 10.6
	proc.emission_ring_inner_radius = 8.4
	proc.emission_ring_height = 0.4
	proc.direction = Vector3(0.0, 1.0, 0.0)
	proc.initial_velocity_min = 0.01
	proc.initial_velocity_max = 0.04
	proc.gravity = Vector3.ZERO
	proc.scale_min = 0.04
	proc.scale_max = 0.08
	proc.color = Color(0.88, 0.94, 1.0, 0.65)
	glints.process_material = proc

	var sphere := SphereMesh.new()
	sphere.radius = 0.04
	sphere.height = 0.08
	var smat := StandardMaterial3D.new()
	smat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	smat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	smat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	smat.albedo_color = Color(0.85, 0.93, 1.0, 0.7)
	smat.emission_enabled = true
	smat.emission = Color("#bae6fd")
	smat.emission_energy_multiplier = 1.8
	sphere.material = smat
	glints.draw_pass_1 = sphere

	add_child(glints)


func _build_mata_branca_watcher_glints() -> void:
	if get_node_or_null("MataBrancaWatchers"):
		return
	var watchers_root := Node3D.new()
	watchers_root.name = "MataBrancaWatchers"
	add_child(watchers_root)
	_watcher_eyes.clear()

	# Pares de pontos luminosos inquietantes ocultos na escuridão da Mata Branca periférica ("o território observa")
	var watcher_positions: Array[Vector3] = [
		Vector3(-11.8, 2.1, -6.2),
		Vector3(11.9, 2.3, -5.4),
		Vector3(-6.8, 2.0, -14.8),
		Vector3(7.1, 2.2, -15.2),
	]

	for i in range(watcher_positions.size()):
		var base_pos: Vector3 = watcher_positions[i]
		var pair_node := Node3D.new()
		pair_node.name = "WatcherPair_%d" % i
		pair_node.position = base_pos
		pair_node.look_at_from_position(base_pos, Vector3.ZERO, Vector3.UP)
		watchers_root.add_child(pair_node)

		var eye_mat := StandardMaterial3D.new()
		eye_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		eye_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		eye_mat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
		eye_mat.albedo_color = Color(0.98, 0.86, 0.45, 0.55)
		eye_mat.emission_enabled = true
		eye_mat.emission = Color("#fde047")
		eye_mat.emission_energy_multiplier = 2.1
		_watcher_eyes.append(eye_mat)

		for side in [-1.0, 1.0]:
			var eye := MeshInstance3D.new()
			var esphere := SphereMesh.new()
			esphere.radius = 0.045
			esphere.height = 0.09
			eye.mesh = esphere
			eye.position = Vector3(side * 0.14, 0.0, 0.0)
			eye.material_override = eye_mat
			pair_node.add_child(eye)

