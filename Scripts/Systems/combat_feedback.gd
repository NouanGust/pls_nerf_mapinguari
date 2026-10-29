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

## Indicador de status
static func create_status_indicator(unit: Node3D, status: String, duration: float) -> void:
	if not is_instance_valid(unit):
		return
	var label := Label3D.new()
	label.name = "StatusIndicator"
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.no_depth_test = true
	label.position = Vector3(0, 3.8, 0)
	label.text = status
	label.font_size = 40
	label.outline_size = 14
	label.outline_modulate = Color.BLACK
	
	var upper_status := status.to_upper()
	# Cores por tipo de status com alta luminosidade e contraste
	if "HP" in upper_status or "CURA" in upper_status:
		label.modulate = Color("#4ade80") # Verde esmeralda brilhante
	elif "MANA" in upper_status:
		label.modulate = Color("#38bdf8") # Azul celeste
	elif "ESCUDO" in upper_status or "REFÚGIO" in upper_status or "CARAPAÇA" in upper_status or "CASCA" in upper_status:
		label.modulate = Color("#facc15") # Ouro brilhante
	elif "STUN" in upper_status or "PARALISIA" in upper_status:
		label.modulate = Color("#fef08a") # Amarelo vibrante
	elif "FEAR" in upper_status or "MEDO" in upper_status or "ENFRAQUECIDO" in upper_status:
		label.modulate = Color("#c084fc") # Púrpura
	elif "GÉLIDO" in upper_status or "FRIO" in upper_status or "ÁGUA" in upper_status or "FLUTUANTE" in upper_status:
		label.modulate = Color("#67e8f9") # Ciano gelo
	elif "BOTE" in upper_status or "VENENO" in upper_status:
		label.modulate = Color("#a3e635") # Verde veneno
	elif "CHEFE" in upper_status:
		label.modulate = Color("#f43f5e") # Vermelho chefe
	elif "QUEIMADO" in upper_status or "FOGO" in upper_status:
		label.modulate = Color("#fb923c") # Laranja fogo
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
