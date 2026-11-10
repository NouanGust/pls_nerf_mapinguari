# res://Scripts/Systems/combat_feedback.gd
class_name CombatFeedback
extends Node

## Sistema de feedback visual para combate

## Cena de texto flutuante (será criada dinamicamente)
static func create_damage_number(position: Vector3, amount: float, type: DamageType) -> void:
	var label := Label3D.new()
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.no_depth_test = true
	label.position = position + Vector3(randf_range(-0.3, 0.3), 1.5, randf_range(-0.3, 0.3))
	
	# Formato e cor baseado no tipo
	match type:
		DamageType.DAMAGE:
			label.text = "-%d" % int(amount)
			label.modulate = Color(1.0, 0.3, 0.3)  # Vermelho
			label.font_size = 48
		DamageType.HEAL:
			label.text = "+%d" % int(amount)
			label.modulate = Color(0.3, 1.0, 0.3)  # Verde
			label.font_size = 42
		DamageType.CRITICAL:
			label.text = "%d!" % int(amount)
			label.modulate = Color(1.0, 0.8, 0.0)  # Amarelo
			label.font_size = 64
		DamageType.ABILITY:
			label.text = "%d" % int(amount)
			label.modulate = Color(0.5, 0.5, 1.0)  # Azul
			label.font_size = 52
		DamageType.SHIELD:
			label.text = "-%d" % int(amount)
			label.modulate = Color(0.22, 0.74, 0.98)  # Azul ciano de escudo (#38bdf8)
			label.font_size = 46
	
	label.outline_size = 12
	label.outline_modulate = Color.BLACK
	
	# Adicionar à cena
	var scene_root := _get_scene_root()
	if not scene_root:
		label.queue_free()
		return
	scene_root.add_child(label)
	
	# Animação
	animate_damage_number(label)

static func animate_damage_number(label: Label3D) -> void:
	var tween := label.create_tween()
	tween.set_parallel(true)
	
	# Movimento para cima
	tween.tween_property(label, "position:y", label.position.y + 2.0, 1.2).set_ease(Tween.EASE_OUT)
	
	# Fade out
	tween.tween_property(label, "modulate:a", 0.0, 1.2).set_ease(Tween.EASE_IN)
	
	# Escala (bounce)
	tween.tween_property(label, "scale", Vector3(1.2, 1.2, 1.2), 0.15).set_ease(Tween.EASE_OUT)
	tween.chain().tween_property(label, "scale", Vector3(1.0, 1.0, 1.0), 0.1)
	
	# Destruir após animação
	tween.chain().tween_callback(label.queue_free)

enum DamageType {
	DAMAGE,
	HEAL,
	CRITICAL,
	ABILITY,
	SHIELD
}

## Criar efeito de habilidade
static func create_ability_effect(position: Vector3, ability_name: String, color: Color) -> void:
	var label := Label3D.new()
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.no_depth_test = true
	label.position = position + Vector3(0, 2.5, 0)
	label.text = ability_name
	label.modulate = color
	label.font_size = 36
	label.outline_size = 10
	label.outline_modulate = Color.BLACK
	
	var scene_root := _get_scene_root()
	if not scene_root:
		label.queue_free()
		return
	scene_root.add_child(label)
	
	# Animação
	var tween := label.create_tween()
	tween.set_parallel(true)
	tween.tween_property(label, "position:y", label.position.y + 1.5, 1.5)
	tween.tween_property(label, "modulate:a", 0.0, 1.5).set_delay(0.5)
	tween.tween_property(label, "scale", Vector3(1.5, 1.5, 1.5), 0.3).set_ease(Tween.EASE_OUT)
	tween.chain().tween_property(label, "scale", Vector3(1.0, 1.0, 1.0), 0.2)
	tween.chain().tween_callback(label.queue_free)

static var _shared_particle_mesh: SphereMesh = null
static var _particle_material: StandardMaterial3D = null

static func _get_particle_mesh() -> SphereMesh:
	if not _shared_particle_mesh:
		_shared_particle_mesh = SphereMesh.new()
		_shared_particle_mesh.radius = 0.16
		_shared_particle_mesh.height = 0.32
		_shared_particle_mesh.radial_segments = 8
		_shared_particle_mesh.rings = 4
		if not _particle_material:
			_particle_material = StandardMaterial3D.new()
			_particle_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
			_particle_material.vertex_color_use_as_albedo = true
		_shared_particle_mesh.material = _particle_material
	return _shared_particle_mesh

## Criar partículas de impacto
static func create_hit_particles(position: Vector3, color: Color) -> void:
	var particles := CPUParticles3D.new()
	particles.position = position + Vector3(0, 0.9, 0)
	particles.emitting = true
	particles.one_shot = true
	particles.amount = 18
	particles.lifetime = 0.65
	particles.explosiveness = 0.92
	particles.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
	particles.emission_sphere_radius = 0.25
	particles.initial_velocity_min = 3.0
	particles.initial_velocity_max = 5.8
	particles.gravity = Vector3(0, -6, 0)
	particles.scale_amount_min = 0.35
	particles.scale_amount_max = 0.75
	particles.color = color
	particles.mesh = _get_particle_mesh()
	
	var scene_root := _get_scene_root()
	if not scene_root:
		particles.queue_free()
		return
	scene_root.add_child(particles)
	
	# Auto-destruir
	var loop := Engine.get_main_loop() as SceneTree
	if loop:
		await loop.create_timer(particles.lifetime + 0.1, false).timeout
	if is_instance_valid(particles):
		particles.queue_free()

## Indicador de status (Efeitos Visuais para Debuffs; Textos apenas para números/habilidades positivas)
static func create_status_indicator(unit: Node3D, status: String, duration: float) -> void:
	if not is_instance_valid(unit):
		return
	
	var upper_status := status.to_upper()

	# 1. DEBUFFS: Exibir efeitos visuais 3D dedicados ao invés de textos
	if "STUN" in upper_status or "PARALISIA" in upper_status or "ATORDOADO" in upper_status or "HIPNOTIZADO" in upper_status:
		_create_stun_visual_effect(unit, duration)
		return
	elif "LENTO" in upper_status or "GÉLIDO" in upper_status or "FRIO" in upper_status or "CONGELADO" in upper_status or "SLOW" in upper_status:
		_create_slow_visual_effect(unit, duration)
		return
	elif "QUEIMADO" in upper_status or "FOGO" in upper_status or "QUEIMADURA" in upper_status or "BURN" in upper_status:
		_create_burn_visual_effect(unit, duration)
		return
	elif "ENFRAQUECIDO" in upper_status or "MEDO" in upper_status or "FEAR" in upper_status or "WEAK" in upper_status:
		_create_weakness_visual_effect(unit, duration)
		return
	elif "ARMADURA REDUZIDA" in upper_status or "RESISTÊNCIA REDUZIDA" in upper_status or "SHRED" in upper_status or "DEFESA REDUZIDA" in upper_status or "QUEBRA" in upper_status:
		_create_shred_visual_effect(unit, duration)
		return
	elif "VENENO" in upper_status or "BOTE" in upper_status or "POISON" in upper_status or "SANGRANDO" in upper_status or "BLEED" in upper_status:
		_create_poison_visual_effect(unit, duration)
		return

	# 2. FEEDBACK POSITIVO / CURA / MANA / TÍTULOS DE HABILIDADE: Exibir indicador de texto
	var label := Label3D.new()
	label.name = "StatusIndicator"
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.no_depth_test = true
	label.position = Vector3(0, 3.8, 0)
	label.text = status
	label.font_size = 40
	label.outline_size = 14
	label.outline_modulate = Color.BLACK
	
	# Cores por tipo de status com alta luminosidade e contraste
	if "HP" in upper_status or "CURA" in upper_status:
		label.modulate = Color("#4ade80") # Verde esmeralda brilhante
	elif "MANA" in upper_status:
		label.modulate = Color("#38bdf8") # Azul celeste
	elif "ESCUDO" in upper_status or "REFÚGIO" in upper_status or "CARAPAÇA" in upper_status or "CASCA" in upper_status:
		label.modulate = Color("#facc15") # Ouro brilhante
	elif "CHEFE" in upper_status:
		label.modulate = Color("#f43f5e") # Vermelho chefe
	elif "BUFF" in upper_status or "GARRAS" in upper_status or "VOO" in upper_status:
		label.modulate = Color("#60a5fa") # Azul forte
	else:
		label.modulate = Color("#f8fafc") # Branco puro
	
	unit.add_child(label)
	
	# Animação de pop, elevação suave e fade out
	label.scale = Vector3(1.35, 1.35, 1.35)
	var tween := label.create_tween()
	tween.set_parallel(true)
	tween.tween_property(label, "scale", Vector3(1.0, 1.0, 1.0), 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(label, "position:y", label.position.y + 0.85, maxf(duration, 0.6)).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	if duration > 0.4:
		tween.tween_property(label, "modulate:a", 0.0, 0.35).set_delay(duration - 0.35)
	
	var loop := Engine.get_main_loop() as SceneTree
	if loop:
		await loop.create_timer(duration, false).timeout
	if is_instance_valid(label):
		label.queue_free()

## Efeito visual 3D de atordoamento / paralisia (estrelas girando sobre a cabeça)
static func _create_stun_visual_effect(unit: Node3D, duration: float) -> void:
	var head_y := 1.75
	if unit.has_node("Model"):
		var m := unit.get_node("Model") as Node3D
		head_y = m.position.y + 1.75 * m.scale.y

	var stun_root := Node3D.new()
	stun_root.name = "StunVisualFX"
	stun_root.position = Vector3(0.0, head_y, 0.0)
	unit.add_child(stun_root)

	var star_mat := StandardMaterial3D.new()
	star_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	star_mat.albedo_color = Color("#fef08a")
	star_mat.emission_enabled = true
	star_mat.emission = Color("#facc15")
	star_mat.emission_energy_multiplier = 3.5

	var star_mesh := SphereMesh.new()
	star_mesh.radius = 0.09
	star_mesh.height = 0.18
	star_mesh.radial_segments = 8
	star_mesh.rings = 4

	for i in 3:
		var star := MeshInstance3D.new()
		star.mesh = star_mesh
		star.material_override = star_mat
		var angle := TAU * float(i) / 3.0
		star.position = Vector3(cos(angle) * 0.45, sin(float(i) * 1.5) * 0.08, sin(angle) * 0.45)
		stun_root.add_child(star)

	var tw := stun_root.create_tween()
	tw.set_parallel(true)
	tw.tween_property(stun_root, "rotation:y", TAU * 4.0, maxf(duration, 0.6))
	if duration > 0.3:
		tw.tween_property(stun_root, "scale", Vector3.ZERO, 0.25).set_delay(duration - 0.25)
	tw.chain().tween_callback(stun_root.queue_free)

## Efeito visual 3D de lentidão / gelo (anel de geada e névoa azulada nos pés)
static func _create_slow_visual_effect(unit: Node3D, duration: float) -> void:
	var frost := MeshInstance3D.new()
	frost.name = "SlowVisualFX"
	var torus := TorusMesh.new()
	torus.inner_radius = 0.55
	torus.outer_radius = 0.72
	torus.ring_segments = 16
	frost.mesh = torus
	frost.rotation_degrees.x = 90.0
	frost.position = Vector3(0.0, 0.08, 0.0)

	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = Color(0.4, 0.88, 1.0, 0.65)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.emission_enabled = true
	mat.emission = Color("#38bdf8")
	mat.emission_energy_multiplier = 2.5
	frost.material_override = mat

	unit.add_child(frost)

	var tw := frost.create_tween()
	tw.set_parallel(true)
	tw.tween_property(frost, "scale", Vector3(1.15, 1.15, 1.15), 0.3).set_trans(Tween.TRANS_QUAD)
	tw.tween_property(mat, "albedo_color:a", 0.0, 0.35).set_delay(maxf(duration - 0.35, 0.1))
	tw.chain().tween_callback(frost.queue_free)

## Efeito visual 3D de queimadura (fagulhas e chamas subindo da unidade)
static func _create_burn_visual_effect(unit: Node3D, duration: float) -> void:
	var particles := CPUParticles3D.new()
	particles.name = "BurnVisualFX"
	particles.position = Vector3(0.0, 0.5, 0.0)
	particles.amount = 16
	particles.lifetime = 0.45
	particles.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
	particles.emission_sphere_radius = 0.35
	particles.gravity = Vector3(0, 4.5, 0)
	particles.initial_velocity_min = 0.8
	particles.initial_velocity_max = 1.8
	particles.scale_amount_min = 0.25
	particles.scale_amount_max = 0.55
	particles.color = Color("#f97316")

	var p_mesh := SphereMesh.new()
	p_mesh.radius = 0.08
	p_mesh.height = 0.16
	var p_mat := StandardMaterial3D.new()
	p_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	p_mat.albedo_color = Color("#fdba74")
	p_mat.emission_enabled = true
	p_mat.emission = Color("#ea580c")
	p_mat.emission_energy_multiplier = 3.2
	p_mesh.material = p_mat
	particles.mesh = p_mesh

	unit.add_child(particles)

	var loop := Engine.get_main_loop() as SceneTree
	if loop:
		await loop.create_timer(duration, false).timeout
	if is_instance_valid(particles):
		particles.emitting = false
		particles.queue_free()

## Efeito visual 3D de enfraquecimento (anéis sombrios púrpuras descendentes)
static func _create_weakness_visual_effect(unit: Node3D, duration: float) -> void:
	var ring := MeshInstance3D.new()
	ring.name = "WeaknessVisualFX"
	var torus := TorusMesh.new()
	torus.inner_radius = 0.48
	torus.outer_radius = 0.64
	ring.mesh = torus
	ring.rotation_degrees.x = 90.0
	ring.position = Vector3(0.0, 1.4, 0.0)

	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = Color(0.75, 0.35, 0.95, 0.7)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.emission_enabled = true
	mat.emission = Color("#a855f7")
	mat.emission_energy_multiplier = 2.8
	ring.material_override = mat

	unit.add_child(ring)

	var tw := ring.create_tween()
	tw.set_parallel(true)
	tw.tween_property(ring, "position:y", 0.25, maxf(duration * 0.8, 0.5)).set_trans(Tween.TRANS_QUAD)
	tw.tween_property(mat, "albedo_color:a", 0.0, 0.35).set_delay(maxf(duration - 0.35, 0.1))
	tw.chain().tween_callback(ring.queue_free)

## Efeito visual 3D de quebra de armadura / resistência (fragmentos de escudo estilhaçados)
static func _create_shred_visual_effect(unit: Node3D, duration: float) -> void:
	var particles := CPUParticles3D.new()
	particles.name = "ShredVisualFX"
	particles.position = Vector3(0.0, 0.85, 0.0)
	particles.amount = 14
	particles.lifetime = 0.5
	particles.explosiveness = 0.85
	particles.one_shot = true
	particles.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
	particles.emission_sphere_radius = 0.2
	particles.gravity = Vector3(0, -5.0, 0)
	particles.initial_velocity_min = 2.5
	particles.initial_velocity_max = 4.5
	particles.color = Color("#f59e0b")

	var p_mesh := BoxMesh.new()
	p_mesh.size = Vector3(0.12, 0.12, 0.04)
	var p_mat := StandardMaterial3D.new()
	p_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	p_mat.albedo_color = Color("#fbbf24")
	p_mat.emission_enabled = true
	p_mat.emission = Color("#d97706")
	p_mat.emission_energy_multiplier = 2.5
	p_mesh.material = p_mat
	particles.mesh = p_mesh

	unit.add_child(particles)

	var loop := Engine.get_main_loop() as SceneTree
	if loop:
		await loop.create_timer(maxf(duration, 0.6), false).timeout
	if is_instance_valid(particles):
		particles.queue_free()

## Efeito visual 3D de veneno / sangramento (gotas ácidas borbulhantes)
static func _create_poison_visual_effect(unit: Node3D, duration: float) -> void:
	var particles := CPUParticles3D.new()
	particles.name = "PoisonVisualFX"
	particles.position = Vector3(0.0, 0.6, 0.0)
	particles.amount = 12
	particles.lifetime = 0.6
	particles.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
	particles.emission_sphere_radius = 0.35
	particles.gravity = Vector3(0, -3.0, 0)
	particles.initial_velocity_min = 0.5
	particles.initial_velocity_max = 1.5
	particles.color = Color("#84cc16")

	var p_mesh := SphereMesh.new()
	p_mesh.radius = 0.07
	p_mesh.height = 0.14
	var p_mat := StandardMaterial3D.new()
	p_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	p_mat.albedo_color = Color("#a3e635")
	p_mat.emission_enabled = true
	p_mat.emission = Color("#65a30d")
	p_mat.emission_energy_multiplier = 2.2
	p_mesh.material = p_mat
	particles.mesh = p_mesh

	unit.add_child(particles)

	var loop := Engine.get_main_loop() as SceneTree
	if loop:
		await loop.create_timer(duration, false).timeout
	if is_instance_valid(particles):
		particles.queue_free()

const LightningEffect = preload("res://Scripts/Systems/lightning_effect.gd")

## Cria uma queda de relâmpago procedural no ponto alvo
static func create_lightning_strike(target_position: Vector3, bolt_color: Color = Color("#fbbf24"), strike_height: float = 9.0) -> Node3D:
	return LightningEffect.create_strike(target_position, bolt_color, strike_height)

## Cria um feixe celestial vertical suave sobre o alvo
static func create_celestial_beam(target_position: Vector3, beam_color: Color = Color("#fbbf24"), duration: float = 0.55) -> Node3D:
	return LightningEffect.create_celestial_beam(target_position, beam_color, 8.0, 0.45, duration)

static func _get_scene_root() -> Node:
	var loop := Engine.get_main_loop() as SceneTree
	if not loop:
		return null
	if loop.current_scene:
		return loop.current_scene
	if loop.root:
		return loop.root.get_child(0) if loop.root.get_child_count() > 0 else loop.root
	return null
