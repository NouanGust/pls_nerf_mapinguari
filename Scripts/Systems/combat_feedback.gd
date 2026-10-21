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
			label.text = "⚡%d" % int(amount)
			label.modulate = Color(0.5, 0.5, 1.0)  # Azul
			label.font_size = 52
	
	label.outline_size = 12
	label.outline_modulate = Color.BLACK
	
	# Adicionar à cena
	var scene_root = Engine.get_main_loop().root.get_child(0)
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
	ABILITY
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
	
	var scene_root = Engine.get_main_loop().root.get_child(0)
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

static func _get_particle_mesh() -> SphereMesh:
	if not _shared_particle_mesh:
		_shared_particle_mesh = SphereMesh.new()
		_shared_particle_mesh.radius = 0.08
		_shared_particle_mesh.height = 0.16
		_shared_particle_mesh.radial_segments = 6
		_shared_particle_mesh.rings = 3
	return _shared_particle_mesh

## Criar partículas de impacto
static func create_hit_particles(position: Vector3, color: Color) -> void:
	var particles := CPUParticles3D.new()
	particles.position = position + Vector3(0, 1.0, 0)
	particles.emitting = true
	particles.one_shot = true
	particles.amount = 12
	particles.lifetime = 0.5
	particles.explosiveness = 0.9
	particles.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
	particles.emission_sphere_radius = 0.25
	particles.initial_velocity_min = 2.0
	particles.initial_velocity_max = 3.5
	particles.gravity = Vector3(0, -5, 0)
	particles.scale_amount_min = 0.1
	particles.scale_amount_max = 0.2
	particles.color = color
	particles.mesh = _get_particle_mesh()
	
	var scene_root = Engine.get_main_loop().root.get_child(0)
	if not scene_root:
		particles.queue_free()
		return
	scene_root.add_child(particles)
	
	# Auto-destruir
	await Engine.get_main_loop().create_timer(particles.lifetime + 0.1, false).timeout
	if is_instance_valid(particles):
		particles.queue_free()

## Indicador de status
static func create_status_indicator(unit: Node3D, status: String, duration: float) -> void:
	var label := Label3D.new()
	label.name = "StatusIndicator"
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.no_depth_test = true
	label.position = Vector3(0, 3.6, 0)
	label.text = status
	label.font_size = 28
	label.outline_size = 8
	label.outline_modulate = Color.BLACK
	
	# Cores por tipo de status
	if "STUN" in status or "PARALISIA" in status:
		label.modulate = Color(0.8, 0.8, 0.2)
	elif "FEAR" in status or "MEDO" in status:
		label.modulate = Color(0.6, 0.2, 0.8)
	elif "BUFF" in status:
		label.modulate = Color(0.2, 0.8, 1.0)
	else:
		label.modulate = Color(1.0, 0.5, 0.2)
	
	unit.add_child(label)
	
	# Remover após duração
	await Engine.get_main_loop().create_timer(duration, false).timeout
	if is_instance_valid(label):
		label.queue_free()
