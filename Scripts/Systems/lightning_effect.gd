class_name LightningEffect
extends Node3D

## Gerador procedural 3D de relâmpagos e descargas elétricas celestiais
## Desenvolvido com renderização em cruz (X-quads) via SurfaceTool para visualização
## volumétrica impecável em 360 graus, alta performance e compatibilidade com Web.

const DEFAULT_BOLT_COLOR := Color(0.98, 0.75, 0.14) # Ouro vibrante (#fbbf24)
const DEFAULT_CORE_COLOR := Color(1.0, 0.96, 0.85) # Núcleo branco-dourado de alta emissão

## Cria uma queda de relâmpago do céu até o ponto alvo
static func create_strike(
	target_position: Vector3,
	bolt_color: Color = DEFAULT_BOLT_COLOR,
	strike_height: float = 9.0,
	bolt_thickness: float = 0.08
) -> Node3D:
	var scene_root := _get_scene_root()
	if not scene_root:
		return null

	var container := Node3D.new()
	container.name = "LightningStrike"
	scene_root.add_child(container)

	# 1. Ponto de origem nas nuvens (com leve deslocamento estocástico)
	var sky_origin := target_position + Vector3(
		randf_range(-1.1, 1.1),
		strike_height,
		randf_range(-1.1, 1.1)
	)

	# 2. Gerar malha de relâmpago (tronco principal + ramificações)
	var mesh_instance := _generate_lightning_mesh(sky_origin, target_position, bolt_color, bolt_thickness)
	if mesh_instance:
		container.add_child(mesh_instance)

	# 3. Flash de luz instantâneo no ponto de impacto
	_create_impact_light(container, target_position, bolt_color)

	# 4. Anel de onda de choque no solo
	_create_ground_shockwave(container, target_position, bolt_color)

	# 5. Faíscas elétricas de impacto no chão
	_create_impact_sparks(container, target_position, bolt_color)

	# 6. Animação de cintilação elétrica realista (flicker) e auto-destruição
	_animate_flicker_and_cleanup(container, mesh_instance)

	return container

## Cria um feixe celestial suave descendente (usado para efeitos de cura e bênção)
static func create_celestial_beam(
	target_position: Vector3,
	beam_color: Color = Color(0.98, 0.84, 0.32),
	beam_height: float = 8.0,
	beam_radius: float = 0.45,
	duration: float = 0.55
) -> Node3D:
	var scene_root := _get_scene_root()
	if not scene_root:
		return null

	var container := Node3D.new()
	container.name = "CelestialBeam"
	scene_root.add_child(container)
	container.global_position = target_position

	# Coluna de luz cilíndrica vertical
	var col_instance := MeshInstance3D.new()
	var cyl := CylinderMesh.new()
	cyl.top_radius = beam_radius * 0.8
	cyl.bottom_radius = beam_radius
	cyl.height = beam_height
	cyl.radial_segments = 12
	col_instance.mesh = cyl
	col_instance.position = Vector3(0, beam_height * 0.5, 0)

	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = Color(beam_color.r, beam_color.g, beam_color.b, 0.38)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.emission_enabled = true
	mat.emission = beam_color
	mat.emission_energy_multiplier = 2.2
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	col_instance.material_override = mat
	container.add_child(col_instance)

	# Anel de cura no chão
	_create_ground_shockwave(container, target_position, beam_color, 1.4, duration)

	# Animação de fade out
	var tw := container.create_tween()
	tw.set_parallel(true)
	tw.tween_property(mat, "albedo_color:a", 0.0, duration).set_ease(Tween.EASE_IN)
	tw.tween_property(col_instance, "scale:x", 0.1, duration).set_ease(Tween.EASE_IN)
	tw.tween_property(col_instance, "scale:z", 0.1, duration).set_ease(Tween.EASE_IN)
	tw.chain().tween_callback(container.queue_free)

	return container

## Constrói os vértices da malha em cruz (X-quads) via SurfaceTool
static func _generate_lightning_mesh(
	p_start: Vector3,
	p_end: Vector3,
	color: Color,
	thickness: float
) -> MeshInstance3D:
	var segments := 10
	var points: Array[Vector3] = []
	points.append(p_start)

	# Gera zigue-zague com perturbações caóticas
	for i in range(1, segments):
		var t := float(i) / float(segments)
		var base_pos := p_start.lerp(p_end, t)
		var jitter_range := (1.0 - absf(t - 0.5) * 1.4) * 0.65
		var offset := Vector3(
			randf_range(-jitter_range, jitter_range),
			randf_range(-0.15, 0.15),
			randf_range(-jitter_range, jitter_range)
		)
		points.append(base_pos + offset)
	points.append(p_end)

	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)

	# Constrói tronco principal
	for i in range(points.size() - 1):
		var p0 := points[i]
		var p1 := points[i + 1]
		var t_ratio := 1.0 - (float(i) / float(points.size())) * 0.35
		var seg_rad := thickness * t_ratio
		_add_cross_segment(st, p0, p1, seg_rad, DEFAULT_CORE_COLOR)

	# Ramificações secundárias (branches)
	if points.size() > 5:
		var branch_idx := randi_range(3, mini(6, points.size() - 2))
		_add_branch(st, points[branch_idx], thickness * 0.55, DEFAULT_CORE_COLOR)

	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.vertex_color_use_as_albedo = true
	mat.albedo_color = Color.WHITE
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.emission_enabled = true
	mat.emission = color
	mat.emission_energy_multiplier = 3.8
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED

	var array_mesh := st.commit()
	var mesh_inst := MeshInstance3D.new()
	mesh_inst.mesh = array_mesh
	mesh_inst.material_override = mat
	return mesh_inst

## Cria ramificação secundária saindo de um nó do raio
static func _add_branch(st: SurfaceTool, start_pt: Vector3, branch_thickness: float, col: Color) -> void:
	var branch_steps := 4
	var curr := start_pt
	var dir := Vector3(randf_range(-0.9, 0.9), -0.7, randf_range(-0.9, 0.9)).normalized()
	var step_len := 0.65

	for s in branch_steps:
		var next_pt := curr + dir * step_len + Vector3(randf_range(-0.25, 0.25), randf_range(-0.1, 0.1), randf_range(-0.25, 0.25))
		_add_cross_segment(st, curr, next_pt, branch_thickness * (1.0 - float(s) / float(branch_steps)), col)
		curr = next_pt

## Cria segmento de volume em formato de cruz (+) conectando p0 e p1
static func _add_cross_segment(st: SurfaceTool, p0: Vector3, p1: Vector3, radius: float, col: Color) -> void:
	var delta := p1 - p0
	if delta.length_squared() < 0.0001:
		return
	var dir := delta.normalized()
	var up_ref := Vector3.UP if absf(dir.dot(Vector3.UP)) < 0.85 else Vector3.RIGHT
	var side1 := dir.cross(up_ref).normalized()
	var side2 := dir.cross(side1).normalized()

	# Plano 1
	_add_quad(st, p0 - side1 * radius, p0 + side1 * radius, p1 + side1 * (radius * 0.8), p1 - side1 * (radius * 0.8), col)
	# Plano 2 (ortogonal)
	_add_quad(st, p0 - side2 * radius, p0 + side2 * radius, p1 + side2 * (radius * 0.8), p1 - side2 * (radius * 0.8), col)

static func _add_quad(st: SurfaceTool, v0: Vector3, v1: Vector3, v2: Vector3, v3: Vector3, col: Color) -> void:
	st.set_color(col)
	st.add_vertex(v0)
	st.add_vertex(v1)
	st.add_vertex(v2)

	st.set_color(col)
	st.add_vertex(v0)
	st.add_vertex(v2)
	st.add_vertex(v3)

## Flash de iluminação no ponto de impacto
static func _create_impact_light(parent: Node, pos: Vector3, col: Color) -> void:
	var light := OmniLight3D.new()
	light.position = pos + Vector3(0, 0.7, 0)
	light.light_color = col
	light.light_energy = 4.2
	light.omni_range = 6.5
	parent.add_child(light)

	var tw := light.create_tween()
	tw.tween_property(light, "light_energy", 0.0, 0.18).set_ease(Tween.EASE_IN)
	tw.tween_callback(light.queue_free)

## Onda de choque em anel no solo
static func _create_ground_shockwave(
	parent: Node,
	pos: Vector3,
	col: Color,
	max_scale: float = 2.0,
	duration: float = 0.32
) -> void:
	var ring := MeshInstance3D.new()
	var torus := TorusMesh.new()
	torus.inner_radius = 0.35
	torus.outer_radius = 0.52
	torus.rings = 16
	torus.ring_segments = 6
	ring.mesh = torus
	ring.rotation_degrees.x = 90.0
	
	if parent is Node3D and parent.global_position != Vector3.ZERO:
		ring.position = Vector3(0.0, 0.05, 0.0)
	else:
		ring.position = Vector3(pos.x, 0.05, pos.z)
	ring.scale = Vector3(0.25, 0.25, 0.25)

	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = Color(col.r, col.g, col.b, 0.95)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.emission_enabled = true
	mat.emission = col
	mat.emission_energy_multiplier = 3.0
	ring.material_override = mat
	parent.add_child(ring)

	var tw := ring.create_tween()
	tw.set_parallel(true)
	tw.tween_property(ring, "scale", Vector3(max_scale, 0.3, max_scale), duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_property(mat, "albedo_color:a", 0.0, duration).set_ease(Tween.EASE_IN)
	tw.chain().tween_callback(ring.queue_free)

## Partículas elétricas / faíscas no solo
static func _create_impact_sparks(parent: Node, pos: Vector3, col: Color) -> void:
	var particles := CPUParticles3D.new()
	particles.position = pos + Vector3(0, 0.2, 0)
	particles.emitting = true
	particles.one_shot = true
	particles.amount = 22
	particles.lifetime = 0.42
	particles.explosiveness = 0.96
	particles.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
	particles.emission_sphere_radius = 0.25
	particles.initial_velocity_min = 4.0
	particles.initial_velocity_max = 8.5
	particles.gravity = Vector3(0, -9.8, 0)
	particles.scale_amount_min = 0.2
	particles.scale_amount_max = 0.5
	particles.color = col

	var p_mesh := SphereMesh.new()
	p_mesh.radius = 0.10
	p_mesh.height = 0.20
	var p_mat := StandardMaterial3D.new()
	p_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	p_mat.albedo_color = col
	p_mat.emission_enabled = true
	p_mat.emission = col
	p_mat.emission_energy_multiplier = 3.0
	p_mesh.material = p_mat
	particles.mesh = p_mesh

	parent.add_child(particles)

## Anima a cintilação do raio (flicker de alta tensão) e destrói o container
static func _animate_flicker_and_cleanup(container: Node3D, mesh_instance: MeshInstance3D) -> void:
	if not mesh_instance:
		container.queue_free()
		return

	var mat: StandardMaterial3D = mesh_instance.material_override as StandardMaterial3D
	var tw := container.create_tween()

	# Sequência de cintilação rápida: 1.0 -> 0.35 -> 1.0 -> 0.15 -> 0.85 -> 0.0
	tw.tween_property(mat, "albedo_color:a", 0.35, 0.04)
	tw.tween_property(mat, "albedo_color:a", 1.0, 0.03)
	tw.tween_property(mat, "albedo_color:a", 0.20, 0.04)
	tw.tween_property(mat, "albedo_color:a", 0.85, 0.03)
	tw.tween_property(mat, "albedo_color:a", 0.0, 0.08)
	tw.tween_callback(container.queue_free)

static func _get_scene_root() -> Node:
	var loop := Engine.get_main_loop() as SceneTree
	if not loop:
		return null
	if loop.current_scene:
		return loop.current_scene
	if loop.root:
		return loop.root.get_child(0) if loop.root.get_child_count() > 0 else loop.root
	return null
