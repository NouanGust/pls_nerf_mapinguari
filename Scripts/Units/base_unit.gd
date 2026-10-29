class_name BaseUnit3D
extends CharacterBody3D

const BattleClock = preload("res://Scripts/Systems/battle_clock.gd")

@export var use_navigation: bool = false # false = movimento direto (robusto para auto-chess)
@export var debug_movement: bool = false # prints de debug

# Signals
signal died(unit: BaseUnit3D)
signal health_changed(current: float, maximum: float)
signal mana_changed(current: float, maximum: float)
signal ability_cast(ability_name: String)
signal combat_metric_recorded(unit: BaseUnit3D, metric: StringName, amount: float)

# Stats
var stats: UnitStats
var current_health: float
var current_mana: float
var star_level: int = 1
var stars: int:
	get: return star_level

# Estado de Combate
enum State {IDLE, MOVING, ATTACKING, CASTING, DEAD, ROOTED}
enum ShieldSource { CLASS, SELF, PLAYER, ENEMY }

var current_state: State = State.IDLE
var current_target: BaseUnit3D = null
var invested_gold: int = 0
var synergy_bonuses: Dictionary = {}
var current_shield_source: ShieldSource = ShieldSource.SELF
var shield_sphere: MeshInstance3D = null
var _shield_sphere_tween: Tween = null
var consecutive_attacks: int = 0
var current_shield: float = 0.0:
	set(value):
		current_shield = maxf(value, 0.0)
		update_stats_display()
		_update_shield_sphere_visual()
const MAX_CERRADO_STACKS: int = 10
var enemies_defeated: int = 0
var is_synergy_highlighted: bool = false
var first_attack_used: bool = false
var first_hit_checked: bool = false
var slowed_until_msec: int = 0
var attack_weakened_until_msec: int = 0
var attack_damage_multiplier: float = 1.0
var marked_team: int = -1
var mark_expires_at_msec: int = 0
var _health_regen_accumulator: float = 0.0
var _burn_generation: int = 0
var _burn_expires_at_msec: int = 0
var _rooted_target_timer := 0.0
var _aura_indicator: Node3D
var _aura_center := Vector2i(-1, -1)
var _aura_radius: int = -1
var stunned_until_msec: int = 0
var _was_stunned: bool = false
var in_combat: bool = false
# Sinergias Temáticas (9 Origens da Proposta)
var seiva_growth_stacks: int = 0
var _seiva_timer: float = 0.0
var vigilia_triggered: bool = false
var vigilia_cc_resist_until_msec: int = 0
var _correnteza_timer: float = 0.0
var _last_vozes_emit_msec: int = 0
var _last_vozes_receive_msec: int = 0
var ferocidade_stacks: int = 0
var ferocidade_hits: int = 0
var _last_target_id: int = 0
var _last_travessia_msec: int = 0
var has_travessia_burst: bool = false
var assombro_shred_until_msec: int = 0
var assombro_shred_pct: float = 0.0
var _assombro_emitters: Dictionary = {}
var encanto_charged: bool = false
var fulgor_first_ability: bool = false
var _idle_target_timer: float = 0.0
var immune_until_msec: int = 0
var reflect_until_msec: int = 0
var reflect_pct: float = 0.0
var armor_shred_until_msec: int = 0
var armor_shred_amount: float = 0.0
var speed_buff_until_msec: int = 0
var speed_buff_multiplier: float = 1.0
var _is_swooping: bool = false
const FLYING_BASE_HEIGHT: float = 0.55

## Posição no Board
var board_position: Vector2i = Vector2i(-1, -1)
var team: int = 0:
	set(value):
		team = value
		if not is_in_group("units"):
			add_to_group("units")
		if team == 0:
			remove_from_group("enemy_units")
			add_to_group("player_units")
		else:
			remove_from_group("player_units")
			add_to_group("enemy_units")
var cell_reference: GridCell3D = null
var combat_ground_height: float = 0.0

func is_on_bench() -> bool:
	return board_position.y < 0

func is_flying() -> bool:
	if not stats:
		return false
	if stats.can_fly:
		return true
	return stats.unit_id in [
		"sabia_laranjeira",
		"arara_azul_lear",
		"ararinha_azul",
		"mutum_de_alagoas",
		"cumacanga",
		"matinta_perera",
		"mae_de_ouro",
		"alamoa",
		"romaozinho"
	]


## Componentes 3D
var model: Node3D
var model_base_scale: Vector3 = Vector3.ONE
var animation_player: AnimationPlayer
var attack_timer: Timer
var unit_visual: UnitVisual
var _death_generation: int = 0
var _star_upgrade_effect_pending: bool = false

## UI 3D
var health_bar_3d: ProgressBar
var shield_bar_3d: ProgressBar
var mana_bar_3d: ProgressBar
var name_label: Label
var hp_label: Label
var mana_label: Label
var star_container: HBoxContainer
var nameplate_container: PanelContainer
var bars_container: Control
var tier_label: Label
var _hp_ticks: Control
var is_hovered: bool = false
var ui_sprite: Sprite3D
var ui_viewport: SubViewport

## VFX
var hit_particles: GPUParticles3D
var ability_particles: GPUParticles3D
var death_particles: GPUParticles3D

## Buffs/Debuffs
var active_buffs: Array[Dictionary] = []

## Navigation
var navigation_agent: NavigationAgent3D

@export var debug_navigation: bool = false

var _detour_dir: Vector3 = Vector3.ZERO
var _detour_timer: float = 0.0

const CombatFeedback = preload("res://Scripts/Systems/combat_feedback.gd")
const UNIT_LABEL_ATLAS: Texture2D = preload("res://Assets/UI/GUI_4x.png")
const UIAtlasCatalog = preload("res://Scripts/UI/ui_atlas_catalog.gd")
const UnitVisual = preload("res://Scripts/Units/unit_visual.gd")
const UNIT_VISUAL_SCENE: PackedScene = preload("res://Scenes/Units/unit_visual.tscn")

func _enter_tree() -> void:
	if not is_in_group("units"):
		add_to_group("units")
	if team == 0:
		if not is_in_group("player_units"):
			add_to_group("player_units")
	else:
		if not is_in_group("enemy_units"):
			add_to_group("enemy_units")

func _ready() -> void:
	if not is_in_group("units"):
		add_to_group("units")
	if team == 0:
		if not is_in_group("player_units"):
			add_to_group("player_units")
	else:
		if not is_in_group("enemy_units"):
			add_to_group("enemy_units")
		
	
	# IMPORTANTE: Configurar collision
	collision_layer = 1 # Layer 1 para unidades
	collision_mask = 1 # Detectar outras unidades
	input_ray_pickable = true
	mouse_entered.connect(func(): set_hovered(true))
	mouse_exited.connect(func(): set_hovered(false))
	
	setup_navigation()
	setup_timers()
	

func move_direct_to_target(delta: float = 0.0166) -> void:
	"""Movimento planar para o alvo com desvio dinâmico de obstáculos e separação entre aliados."""
	if stats.is_stationary:
		_wait_rooted()
		return
	if not is_instance_valid(current_target) or current_target.current_state == State.DEAD or current_target.is_on_bench():
		current_target = null
		current_state = State.IDLE
		velocity = Vector3.ZERO
		_detour_timer = 0.0
		_detour_dir = Vector3.ZERO
		find_target()
		return
	
	if not current_target:
		return
	
	var target_pos: Vector3 = current_target.global_position
	var planar_offset := Vector3(target_pos.x - global_position.x, 0.0, target_pos.z - global_position.z)
	
	# Verificar se já está no range de ataque antes de se mover
	if planar_offset.length() <= get_attack_range_meters():
		velocity = Vector3.ZERO
		current_state = State.IDLE
		_detour_timer = 0.0
		_detour_dir = Vector3.ZERO
		check_attack_or_move()
		return

	# Se há outro inimigo mais próximo ou já no alcance de ataque, focar nele
	if stats.target_priority == UnitStats.TargetPriority.CLOSEST:
		var enemy_group: String = "enemy_units" if team == 0 else "player_units"
		var enemies_list: Array = get_tree().get_nodes_in_group(enemy_group)
		var valid_enemies := enemies_list.filter(func(e):
			return is_instance_valid(e) and not e.is_queued_for_deletion() and e.current_state != State.DEAD and e.visible and not e.is_on_bench()
		)
		var closest_enemy := get_closest_enemy(valid_enemies)
		if closest_enemy and closest_enemy != current_target:
			var my_pos2d := Vector2(global_position.x, global_position.z)
			var current_dist := my_pos2d.distance_to(Vector2(target_pos.x, target_pos.z))
			var closest_dist := my_pos2d.distance_to(Vector2(closest_enemy.global_position.x, closest_enemy.global_position.z))
			var range_meters := get_attack_range_meters()
			if closest_dist <= range_meters or (current_dist > range_meters and closest_dist + 1.2 < current_dist):
				current_target = closest_enemy
				target_pos = current_target.global_position
				planar_offset = Vector3(target_pos.x - global_position.x, 0.0, target_pos.z - global_position.z)
				if planar_offset.length() <= range_meters:
					velocity = Vector3.ZERO
					current_state = State.IDLE
					_detour_timer = 0.0
					_detour_dir = Vector3.ZERO
					check_attack_or_move()
					return

	current_state = State.MOVING
	var direct_dir := planar_offset.normalized() if planar_offset.length_squared() > 0.0001 else Vector3.FORWARD
	
	# Verificar se o desvio ativo já pode ser encerrado porque o caminho direto está desobstruído
	if _detour_timer > 0.0:
		_detour_timer -= delta
		if _detour_timer <= 0.0 or not test_move(global_transform, direct_dir * 0.6):
			_detour_timer = 0.0
			_detour_dir = Vector3.ZERO

	# Força de separação leve entre aliados para evitar aglomerações e trancamentos mútuos
	var separation: Vector3 = Vector3.ZERO
	var ally_group: String = "player_units" if team == 0 else "enemy_units"
	for ally_node: Node in get_tree().get_nodes_in_group(ally_group):
		if ally_node == self or not is_instance_valid(ally_node) or not (ally_node is Node3D):
			continue
		var ally3d := ally_node as Node3D
		if ally3d is BaseUnit3D:
			var ally_unit := ally3d as BaseUnit3D
			if ally_unit.is_on_bench() or ally_unit.current_state == State.DEAD:
				continue
		var to_self: Vector3 = global_position - ally3d.global_position
		to_self.y = 0.0
		var dist: float = to_self.length()
		if dist < 0.85 and dist > 0.001:
			separation += (to_self / dist) * (1.0 - dist / 0.85)

	# Combinar direção direta com desvio ativo e separação
	var move_dir := direct_dir
	if _detour_timer > 0.0 and _detour_dir != Vector3.ZERO:
		move_dir = (direct_dir * 0.35 + _detour_dir * 0.85).normalized()
	elif separation.length_squared() > 0.01:
		move_dir = (direct_dir + separation * 0.45).normalized()

	if debug_movement:
		print("%s movendo DIRETO para %s (dist: %.2f)" % [
			stats.unit_name,
			current_target.stats.unit_name,
			planar_offset.length()
		])
	
	velocity = move_dir * get_movement_speed()
	velocity.y = 0.0
	move_and_slide()
	global_position.y = combat_ground_height
	
	# Detecção pós-colisão: se colidiu com uma unidade à frente, calcular vetor tangente de contorno
	var collision_count := get_slide_collision_count()
	if collision_count > 0:
		for i in range(collision_count):
			var col := get_slide_collision(i)
			var normal := col.get_normal()
			normal.y = 0.0
			if normal.length_squared() > 0.01:
				normal = normal.normalized()
				# Colisão frontal contra obstáculo
				if normal.dot(direct_dir) < -0.12:
					var perp_left := Vector3(-direct_dir.z, 0.0, direct_dir.x)
					var perp_right := Vector3(direct_dir.z, 0.0, -direct_dir.x)
					
					var left_blocked: bool = test_move(global_transform, perp_left * 0.45)
					var right_blocked: bool = test_move(global_transform, perp_right * 0.45)
					
					var chosen_dir: Vector3 = Vector3.ZERO
					if not left_blocked and right_blocked:
						chosen_dir = perp_left
					elif not right_blocked and left_blocked:
						chosen_dir = perp_right
					elif not left_blocked and not right_blocked:
						var cross_y: float = direct_dir.cross(normal).y
						chosen_dir = perp_left if cross_y > 0.0 else perp_right
					else:
						chosen_dir = perp_left if randf() < 0.5 else perp_right
					
					_detour_dir = chosen_dir
					_detour_timer = 0.4
					break

	# Rotação
	if move_dir.length() > 0:
		var target_rotation: float = atan2(move_dir.x, move_dir.z)
		rotation.y = lerp_angle(rotation.y, target_rotation, 0.15)
	
	# Verificar se chegou perto o suficiente para atacar após mover-se
	if not is_instance_valid(current_target) or current_target.current_state == State.DEAD:
		current_target = null
		current_state = State.IDLE
		velocity = Vector3.ZERO
		_detour_timer = 0.0
		_detour_dir = Vector3.ZERO
		find_target()
		return

	planar_offset = Vector3(current_target.global_position.x - global_position.x, 0.0, current_target.global_position.z - global_position.z)
	if planar_offset.length() <= get_attack_range_meters():
		if debug_movement:
			print("%s chegou no range de ataque!" % stats.unit_name)
		velocity = Vector3.ZERO
		current_state = State.IDLE
		_detour_timer = 0.0
		_detour_dir = Vector3.ZERO
		check_attack_or_move()


func initialize(unit_stats: UnitStats, star: int = 1) -> void:
	stats = unit_stats
	star_level = clampi(star, 1, 4)
	invested_gold = stats.cost
	
	if not is_in_group("units"):
		add_to_group("units")
	if team == 0:
		remove_from_group("enemy_units")
		add_to_group("player_units")
	else:
		remove_from_group("player_units")
		add_to_group("enemy_units")
	
	var star_multiplier: float = stats.get_star_multiplier(star_level)
	current_health = stats.max_health * star_multiplier
	current_mana = stats.starting_mana
	
	current_state = State.IDLE
	
	setup_model()
	setup_stats_display()
	update_stats_display()
	update_health_bar()
	update_mana_bar()

func promote_to_star(new_star_level: int) -> void:
	var previous_star_level := star_level
	star_level = clampi(new_star_level, 1, 4)
	if star_level <= previous_star_level:
		return
	current_health = get_max_health()
	if name_label:
		name_label.text = stats.unit_name
	_update_star_display()
	if health_bar_3d:
		health_bar_3d.max_value = get_max_health()
	update_health_bar()
	if visible:
		_play_star_upgrade_effect()
	else:
		_star_upgrade_effect_pending = true

func play_pending_star_upgrade_effect() -> void:
	if _star_upgrade_effect_pending and visible:
		_star_upgrade_effect_pending = false
		_play_star_upgrade_effect()

func setup_model() -> void:
	if has_node("Model"):
		model = get_node("Model")
		for child in model.get_children():
			model.remove_child(child)
			child.queue_free()
	else:
		model = Node3D.new()
		model.name = "Model"
		add_child(model)
	unit_visual = UNIT_VISUAL_SCENE.instantiate() as UnitVisual
	unit_visual.configure(get_team_display_color(), stats)
	model.add_child(unit_visual)
	animation_player = unit_visual.animation_player

	model_base_scale = Vector3.ONE
	model.scale = model_base_scale
	model.rotation = Vector3.ZERO
	if is_flying():
		model.position.y = FLYING_BASE_HEIGHT
	else:
		model.position.y = 0.0
	rotation.y = PI if team == 1 else 0.0
	setup_team_indicator()
	setup_aura_indicator()
	setup_shield_sphere()

func setup_aura_indicator() -> void:
	if is_instance_valid(_aura_indicator):
		_aura_indicator.queue_free()
		_aura_indicator = null
	_aura_center = Vector2i(-1, -1)
	_aura_radius = -1
	if stats.passive_aura_effect != "power" or stats.passive_aura_power <= 0.0 or stats.passive_aura_range <= 0:
		return
	_aura_indicator = Node3D.new()
	_aura_indicator.name = "HexPowerAura"
	_aura_indicator.top_level = true
	_aura_indicator.visible = false
	add_child(_aura_indicator)

func _update_aura_indicator() -> void:
	if not is_instance_valid(_aura_indicator):
		return
	# A área também orienta a preparação; o bônus continua exclusivo do combate.
	_aura_indicator.visible = visible and current_state != State.DEAD
	if not _aura_indicator.visible:
		return
	var board := _get_combat_board()
	if not board:
		_aura_indicator.hide()
		return
	var center := board.get_grid_position(board.to_local(global_position))
	if not board.get_cell(center):
		_aura_indicator.hide()
		return
	# Os hexes ficam no chão, sem acompanhar a rotação/animação da unidade.
	_aura_indicator.global_transform = Transform3D.IDENTITY
	if center == _aura_center and _aura_radius == stats.passive_aura_range:
		return
	_aura_center = center
	_aura_radius = stats.passive_aura_range
	for child in _aura_indicator.get_children():
		_aura_indicator.remove_child(child)
		child.queue_free()
	var outline := _make_aura_hex_outline(board.get_hex_radius() * 0.9)
	var material := StandardMaterial3D.new()
	material.albedo_color = Color(0.35, 0.9, 0.55, 0.5) if team == 0 else Color(1.0, 0.4, 0.45, 0.5)
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	for cell in board.get_cells_in_hex_radius(center, stats.passive_aura_range):
		var marker := MeshInstance3D.new()
		marker.mesh = outline
		marker.material_override = material
		marker.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		_aura_indicator.add_child(marker)
		marker.position = board.get_cell_world_position(cell) + Vector3.UP * 0.11

func _make_aura_hex_outline(radius: float) -> ImmediateMesh:
	var mesh := ImmediateMesh.new()
	mesh.surface_begin(Mesh.PRIMITIVE_TRIANGLES)
	var inner_radius := maxf(0.0, radius - 0.04)
	for side in 6:
		var a := TAU * float(side) / 6.0
		var b := TAU * float(side + 1) / 6.0
		var direction_a := Vector3(sin(a), 0.0, cos(a))
		var direction_b := Vector3(sin(b), 0.0, cos(b))
		for vertex in [direction_a * radius, direction_a * inner_radius, direction_b * radius,
				direction_b * radius, direction_a * inner_radius, direction_b * inner_radius]:
			mesh.surface_add_vertex(vertex)
	mesh.surface_end()
	return mesh

func get_team_display_color() -> Color:
	var tier_color := stats.get_tier_color()
	if team != 1:
		return tier_color
	var saturated := Color.from_hsv(tier_color.h, maxf(tier_color.s, 0.78), maxf(tier_color.v, 0.92))
	return saturated.lerp(Color("#ff4b5f"), 0.28)

func _trigger_camera_shake(intensity: float = 0.5, duration: float = 0.55) -> void:
	var cam_3d := get_viewport().get_camera_3d()
	if cam_3d and cam_3d.get_parent() is GameCamera:
		(cam_3d.get_parent() as GameCamera).shake(intensity, duration)
	else:
		var cam_node := get_tree().root.find_child("Node3D", true, false)
		if cam_node and cam_node.has_method("shake"):
			cam_node.shake(intensity, duration)

func _play_star_upgrade_effect() -> void:
	var is_tier_3_plus := star_level >= 3
	if unit_visual:
		unit_visual.flash_upgrade(Color("#ffe28a") if team == 0 else Color("#ff7588"))

	if is_tier_3_plus:
		_trigger_camera_shake(0.55, 0.65)
		if model:
			var hop := create_tween()
			hop.set_trans(Tween.TRANS_QUAD)
			hop.tween_property(model, "position:y", 0.72, 0.18).set_ease(Tween.EASE_OUT)
			hop.parallel().tween_property(model, "scale", model_base_scale * Vector3(0.88, 1.38, 0.88), 0.18).set_ease(Tween.EASE_OUT)
			hop.chain().tween_property(model, "position:y", 0.0, 0.22).set_ease(Tween.EASE_IN)
			hop.parallel().tween_property(model, "scale", model_base_scale * Vector3(1.28, 0.82, 1.28), 0.16).set_ease(Tween.EASE_IN)
			hop.chain().tween_property(model, "scale", model_base_scale, 0.18).set_ease(Tween.EASE_OUT)

	var burst := GPUParticles3D.new()
	burst.name = "StarEvolutionBurst"
	burst.position = Vector3(0.0, 1.0, 0.0)
	burst.one_shot = true
	burst.amount = 90 if is_tier_3_plus else 54
	burst.lifetime = 1.2 if is_tier_3_plus else 0.9
	burst.explosiveness = 0.95
	burst.speed_scale = 1.3
	var particle_process := ParticleProcessMaterial.new()
	particle_process.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	particle_process.emission_sphere_radius = 0.65 if is_tier_3_plus else 0.48
	particle_process.direction = Vector3(0.0, 1.0, 0.0)
	particle_process.spread = 180.0
	particle_process.initial_velocity_min = 2.4 if is_tier_3_plus else 1.8
	particle_process.initial_velocity_max = 5.8 if is_tier_3_plus else 4.6
	particle_process.gravity = Vector3(0.0, -2.5, 0.0)
	particle_process.damping_min = 0.25
	particle_process.damping_max = 0.8
	particle_process.scale_min = 0.06 if is_tier_3_plus else 0.045
	particle_process.scale_max = 0.18 if is_tier_3_plus else 0.12
	particle_process.color = (Color("#ffd700") if is_tier_3_plus else Color("#ffe28a")) if team == 0 else Color("#ff7588")
	burst.process_material = particle_process
	var spark_mesh := SphereMesh.new()
	spark_mesh.radius = 0.075 if is_tier_3_plus else 0.055
	spark_mesh.height = 0.15 if is_tier_3_plus else 0.11
	var spark_material := StandardMaterial3D.new()
	spark_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	spark_material.albedo_color = particle_process.color
	spark_material.emission_enabled = true
	spark_material.emission = particle_process.color
	spark_material.emission_energy_multiplier = 3.2 if is_tier_3_plus else 2.2
	spark_mesh.material = spark_material
	burst.draw_pass_1 = spark_mesh
	add_child(burst)
	burst.emitting = true
	var cleanup := create_tween()
	cleanup.tween_interval(burst.lifetime + 0.35)
	cleanup.tween_callback(burst.queue_free)


#func setup_ui() -> void:

func setup_team_indicator() -> void:
	if team == 1:
		var indicator = MeshInstance3D.new()
		var torus = TorusMesh.new()
		torus.inner_radius = 0.45
		torus.outer_radius = 0.5
		torus.ring_segments = 32
		
		indicator.mesh = torus
		indicator.position.y = 0.01
		indicator.scale = Vector3(1, 0.1, 1)
		
		var mat = StandardMaterial3D.new()
		mat.albedo_color = Color("#ff4b5f")
		mat.emission_enabled = true
		mat.emission = Color("#ff334f")
		mat.emission_energy_multiplier = 2.0
		mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		
		indicator.material_override = mat
		add_child(indicator)

const SHIELD_COLORS := {
	ShieldSource.CLASS: Color(1.0, 0.82, 0.22),    # Dourado / Âmbar (Sinergia/Classe)
	ShieldSource.SELF: Color(0.2, 0.82, 1.0),      # Ciano / Azul piscina (Próprio)
	ShieldSource.PLAYER: Color(0.25, 0.95, 0.55),  # Verde Esmeralda (Aliado/Jogador)
	ShieldSource.ENEMY: Color(0.95, 0.25, 0.35),   # Vermelho Carmesim (Inimigo)
}

func setup_shield_sphere() -> void:
	if is_instance_valid(shield_sphere):
		shield_sphere.queue_free()
		shield_sphere = null
	
	shield_sphere = MeshInstance3D.new()
	shield_sphere.name = "ShieldSphereVisual"
	
	var sphere := SphereMesh.new()
	sphere.radius = 0.85
	sphere.height = 1.7
	sphere.radial_segments = 24
	sphere.rings = 16
	shield_sphere.mesh = sphere
	shield_sphere.position = Vector3(0.0, 0.8, 0.0)
	
	var mat := StandardMaterial3D.new()
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	mat.roughness = 0.1
	mat.metallic = 0.05
	mat.rim_enabled = true
	mat.rim = 0.95
	mat.rim_tint = 0.8
	mat.emission_enabled = true
	mat.emission_energy_multiplier = 0.65
	
	var base_col: Color = SHIELD_COLORS.get(current_shield_source, SHIELD_COLORS[ShieldSource.SELF])
	mat.albedo_color = Color(base_col.r, base_col.g, base_col.b, 0.28)
	mat.emission = base_col
	shield_sphere.material_override = mat
	
	shield_sphere.visible = false
	shield_sphere.scale = Vector3.ZERO
	add_child(shield_sphere)

func set_shield_with_source(amount: float, source: ShieldSource = ShieldSource.SELF) -> void:
	current_shield_source = source
	current_shield = maxf(amount, 0.0)

func _update_shield_sphere_visual() -> void:
	if not is_instance_valid(shield_sphere):
		setup_shield_sphere()
	if not is_instance_valid(shield_sphere):
		return
	
	var has_shield := has_active_shield() and current_state != State.DEAD and visible
	
	if has_shield:
		var effective_source := current_shield_source
		if team == 1 and effective_source != ShieldSource.CLASS:
			effective_source = ShieldSource.ENEMY
		
		var col: Color = SHIELD_COLORS.get(effective_source, SHIELD_COLORS[ShieldSource.SELF])
		var mat: StandardMaterial3D = shield_sphere.material_override as StandardMaterial3D
		if mat:
			mat.albedo_color = Color(col.r, col.g, col.b, 0.28)
			mat.emission = col
		
		if not shield_sphere.visible or shield_sphere.scale.length_squared() < 0.1:
			shield_sphere.visible = true
			if _shield_sphere_tween and _shield_sphere_tween.is_running():
				_shield_sphere_tween.kill()
			_shield_sphere_tween = create_tween()
			_shield_sphere_tween.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
			_shield_sphere_tween.tween_property(shield_sphere, "scale", Vector3.ONE, 0.25)
	else:
		if shield_sphere.visible:
			if _shield_sphere_tween and _shield_sphere_tween.is_running():
				_shield_sphere_tween.kill()
			_shield_sphere_tween = create_tween()
			_shield_sphere_tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
			_shield_sphere_tween.tween_property(shield_sphere, "scale", Vector3.ZERO, 0.18)
			_shield_sphere_tween.tween_callback(func():
				if is_instance_valid(shield_sphere) and not has_active_shield():
					shield_sphere.visible = false
			)


class HealthBarTicks extends Control:
	var max_hp: float = 500.0

	func _draw() -> void:
		if max_hp <= 0.0 or size.x <= 0.0:
			return
		var interval := 250.0
		var count := int(max_hp / interval)
		if count <= 1 or count > 24:
			return
		for i in range(1, count):
			var x := (float(i) * interval / max_hp) * size.x
			draw_line(Vector2(x, 1.0), Vector2(x, size.y - 1.0), Color(0.04, 0.06, 0.08, 0.9), 2.0)

func setup_stats_display() -> void:
	if is_instance_valid(ui_viewport):
		ui_viewport.queue_free()
	if is_instance_valid(ui_sprite):
		ui_sprite.queue_free()

	ui_viewport = SubViewport.new()
	ui_viewport.name = "UnitLabelViewport"
	ui_viewport.size = Vector2i(960, 320)
	ui_viewport.transparent_bg = true
	ui_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(ui_viewport)

	var root := Control.new()
	root.name = "UnitLabelRoot"
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui_viewport.add_child(root)

	# --- 1. Top Container para Centralizar o Nameplate no Hover ---
	var nameplate_center := BoxContainer.new()
	nameplate_center.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	nameplate_center.alignment = BoxContainer.ALIGNMENT_CENTER
	nameplate_center.offset_top = 8
	nameplate_center.offset_bottom = 124
	nameplate_center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(nameplate_center)

	nameplate_container = PanelContainer.new()
	nameplate_container.name = "NameplateContainer"
	nameplate_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	nameplate_container.visible = false

	var nameplate_style := StyleBoxFlat.new()
	nameplate_style.bg_color = Color(0.04, 0.07, 0.12, 0.96)
	nameplate_style.border_color = Color("#f59e0b") if team == 0 else Color("#ef4444")
	nameplate_style.set_border_width_all(3)
	nameplate_style.set_corner_radius_all(14)
	nameplate_style.content_margin_left = 24.0
	nameplate_style.content_margin_right = 24.0
	nameplate_style.content_margin_top = 8.0
	nameplate_style.content_margin_bottom = 8.0
	nameplate_style.shadow_color = Color(0, 0, 0, 0.85)
	nameplate_style.shadow_size = 12
	nameplate_container.add_theme_stylebox_override("panel", nameplate_style)
	nameplate_center.add_child(nameplate_container)

	var nameplate_row := HBoxContainer.new()
	nameplate_row.name = "NameplateRow"
	nameplate_row.alignment = BoxContainer.ALIGNMENT_CENTER
	nameplate_row.add_theme_constant_override("separation", 16)
	nameplate_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	nameplate_container.add_child(nameplate_row)

	tier_label = Label.new()
	tier_label.name = "TierBadge"
	tier_label.text = "T%d" % stats.tier
	tier_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	tier_label.add_theme_font_size_override("font_size", 46)
	tier_label.add_theme_color_override("font_color", stats.get_tier_color())
	tier_label.add_theme_color_override("font_outline_color", Color("#05080c"))
	tier_label.add_theme_constant_override("outline_size", 8)
	tier_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	nameplate_row.add_child(tier_label)

	name_label = Label.new()
	name_label.name = "NameLabel"
	name_label.text = stats.unit_name
	name_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.add_theme_font_size_override("font_size", 54)
	name_label.add_theme_color_override("font_color", Color("#ffffff") if team == 0 else Color("#ffe4e0"))
	name_label.add_theme_color_override("font_outline_color", Color("#05080c"))
	name_label.add_theme_constant_override("outline_size", 9)
	name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	nameplate_row.add_child(name_label)

	hp_label = Label.new()
	hp_label.name = "HPLabel"
	hp_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	hp_label.add_theme_font_size_override("font_size", 44)
	hp_label.add_theme_color_override("font_color", Color("#a5f3fc") if team == 0 else Color("#fca5a5"))
	hp_label.add_theme_color_override("font_outline_color", Color("#05080c"))
	hp_label.add_theme_constant_override("outline_size", 7)
	hp_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	nameplate_row.add_child(hp_label)

	mana_label = Label.new()
	mana_label.name = "ManaLabel"
	mana_label.visible = false
	root.add_child(mana_label)

	# --- 2. Indicador de Estrelas (Visível no Campo Acima das Barras) ---
	var star_center := BoxContainer.new()
	star_center.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	star_center.alignment = BoxContainer.ALIGNMENT_CENTER
	star_center.offset_top = 132
	star_center.offset_bottom = 184
	star_center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(star_center)

	star_container = HBoxContainer.new()
	star_container.name = "StarContainer"
	star_container.alignment = BoxContainer.ALIGNMENT_CENTER
	star_container.add_theme_constant_override("separation", 8)
	star_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	star_center.add_child(star_container)
	_update_star_display()

	# --- 3. Container de Barras (Vida e Mana no Estilo TFT - Largas e com Ticks) ---
	var bars_center := BoxContainer.new()
	bars_center.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	bars_center.alignment = BoxContainer.ALIGNMENT_CENTER
	bars_center.offset_top = 192
	bars_center.offset_bottom = 276
	bars_center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(bars_center)

	bars_container = Control.new()
	bars_container.name = "BarsContainer"
	bars_container.custom_minimum_size = Vector2(380, 68)
	bars_container.size = Vector2(380, 68)
	bars_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bars_center.add_child(bars_container)

	# Barra de Vida (Verde TFT para aliados, Vermelho TFT para inimigos)
	health_bar_3d = ProgressBar.new()
	health_bar_3d.name = "HealthBar"
	health_bar_3d.position = Vector2(0, 0)
	health_bar_3d.size = Vector2(380, 30)
	health_bar_3d.show_percentage = false
	health_bar_3d.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var hp_bg := StyleBoxFlat.new()
	hp_bg.bg_color = Color("#070d14")
	hp_bg.set_border_width_all(3)
	hp_bg.border_color = Color("#000000")
	hp_bg.set_corner_radius_all(4)

	var hp_fill := StyleBoxFlat.new()
	hp_fill.bg_color = Color("#22c55e") if team == 0 else Color("#ef4444")
	hp_fill.set_corner_radius_all(4)

	health_bar_3d.add_theme_stylebox_override("background", hp_bg)
	health_bar_3d.add_theme_stylebox_override("fill", hp_fill)
	bars_container.add_child(health_bar_3d)

	# Ticks de Segmentação de HP estilo TFT
	_hp_ticks = HealthBarTicks.new()
	_hp_ticks.name = "HPTicks"
	_hp_ticks.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_hp_ticks.mouse_filter = Control.MOUSE_FILTER_IGNORE
	health_bar_3d.add_child(_hp_ticks)

	# Faixa de escudo ciano sobre a barra de vida
	shield_bar_3d = ProgressBar.new()
	shield_bar_3d.name = "ShieldBar"
	shield_bar_3d.position = Vector2(0, 0)
	shield_bar_3d.size = Vector2(380, 30)
	shield_bar_3d.show_percentage = false
	shield_bar_3d.mouse_filter = Control.MOUSE_FILTER_IGNORE
	shield_bar_3d.add_theme_stylebox_override("background", StyleBoxEmpty.new())
	var shield_fill := StyleBoxFlat.new()
	shield_fill.bg_color = Color(0.22, 0.74, 0.97, 0.85)
	shield_fill.set_corner_radius_all(4)
	shield_bar_3d.add_theme_stylebox_override("fill", shield_fill)
	shield_bar_3d.visible = false
	bars_container.add_child(shield_bar_3d)

	# Barra de Mana estilo TFT (abaixo da vida)
	mana_bar_3d = ProgressBar.new()
	mana_bar_3d.name = "ManaBar"
	mana_bar_3d.position = Vector2(0, 36)
	mana_bar_3d.size = Vector2(380, 16)
	mana_bar_3d.show_percentage = false
	mana_bar_3d.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var mp_bg := StyleBoxFlat.new()
	mp_bg.bg_color = Color("#050b12")
	mp_bg.set_border_width_all(2)
	mp_bg.border_color = Color("#000000")
	mp_bg.set_corner_radius_all(3)

	var mp_fill := StyleBoxFlat.new()
	mp_fill.bg_color = Color("#0ea5e9")
	mp_fill.set_corner_radius_all(3)

	mana_bar_3d.add_theme_stylebox_override("background", mp_bg)
	mana_bar_3d.add_theme_stylebox_override("fill", mp_fill)
	bars_container.add_child(mana_bar_3d)

	# Sprite 3D Billboard no topo da unidade
	ui_sprite = Sprite3D.new()
	ui_sprite.name = "UnitLabelSprite"
	ui_sprite.texture = ui_viewport.get_texture()
	ui_sprite.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	ui_sprite.no_depth_test = true
	ui_sprite.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	ui_sprite.pixel_size = 0.007
	var ui_height: float = 2.7
	if is_flying():
		ui_height += FLYING_BASE_HEIGHT
	ui_sprite.position = Vector3(0, ui_height, 0)
	add_child(ui_sprite)

	health_bar_3d.max_value = get_max_health()
	mana_bar_3d.max_value = stats.max_mana
	update_stats_display()

func _update_star_display() -> void:
	if not is_instance_valid(star_container):
		return
	for child in star_container.get_children():
		child.queue_free()
	var stars: int = clampi(star_level, 1, 4)
	var star_color: Color
	if stars >= 3:
		star_color = Color("#fbbf24") # Ouro brilhante
	elif stars == 2:
		star_color = Color("#e2e8f0") # Prata
	else:
		star_color = Color("#cd7f32") # Bronze
	for i in range(stars):
		var star_icon := UIAtlasCatalog.create_icon_rect("star", Vector2(40, 40))
		star_icon.modulate = star_color
		star_container.add_child(star_icon)

func set_hovered(hovered: bool) -> void:
	if is_hovered == hovered:
		return
	is_hovered = hovered
	_update_status_visibility()

func set_synergy_highlighted(highlighted: bool) -> void:
	if is_synergy_highlighted == highlighted:
		return
	is_synergy_highlighted = highlighted
	_update_status_visibility()
	if is_instance_valid(ui_sprite):
		if highlighted:
			ui_sprite.modulate = Color(1.3, 1.25, 0.85, 1.0)
		else:
			ui_sprite.modulate = Color.WHITE

func _update_status_visibility() -> void:
	if not is_instance_valid(ui_sprite):
		return
	if current_state == State.DEAD:
		ui_sprite.visible = false
		return

	var show_nameplate := is_hovered or is_synergy_highlighted
	var on_bench := is_on_bench()
	if on_bench:
		# No banco: NUNCA mostra barras de vida e mana
		if is_instance_valid(bars_container):
			bars_container.visible = false
		if is_instance_valid(star_container):
			star_container.visible = false
		# No banco: hover ou destaque de sinergia mostra o nameplate (nome, estrelas, tier)
		if is_instance_valid(nameplate_container):
			nameplate_container.visible = show_nameplate
		ui_sprite.visible = show_nameplate
	else:
		# No campo: barras de vida e mana sempre visíveis
		if is_instance_valid(bars_container):
			bars_container.visible = true
		if is_instance_valid(star_container):
			star_container.visible = true
		# No campo: nome da unidade visível no hover ou quando a sinergia for inspecionada!
		if is_instance_valid(nameplate_container):
			nameplate_container.visible = show_nameplate
		ui_sprite.visible = true

func update_stats_display() -> void:
	if not is_instance_valid(health_bar_3d) or not is_instance_valid(mana_bar_3d):
		return
	var max_hp := maxf(get_max_health(), 1.0)
	var hp_percent := current_health / max_hp
	var max_mp := maxf(stats.max_mana, 1.0)
	var mana_percent := current_mana / max_mp

	if is_instance_valid(hp_label):
		if has_active_shield():
			hp_label.text = "%d / %d (+%d ESC)" % [int(current_health), int(max_hp), ceili(current_shield)]
		else:
			hp_label.text = "%d / %d" % [int(current_health), int(max_hp)]
	if is_instance_valid(mana_label):
		if has_active_shield():
			mana_label.text = "ESC %d  |  MP %d%%" % [ceili(current_shield), int(mana_percent * 100.0)]
		else:
			mana_label.text = "%d / %d" % [int(current_mana), int(max_mp)]

	if is_instance_valid(shield_bar_3d):
		shield_bar_3d.visible = has_active_shield()
		shield_bar_3d.max_value = max_hp
		shield_bar_3d.value = current_shield

	health_bar_3d.max_value = max_hp
	health_bar_3d.value = current_health
	mana_bar_3d.max_value = max_mp
	mana_bar_3d.value = current_mana

	if is_instance_valid(_hp_ticks):
		_hp_ticks.max_hp = max_hp
		_hp_ticks.queue_redraw()

	var health_fill := health_bar_3d.get_theme_stylebox("fill") as StyleBoxFlat
	if is_instance_valid(health_fill):
		if team == 0:
			if hp_percent > 0.6:
				health_fill.bg_color = Color("#22c55e")
			elif hp_percent > 0.3:
				health_fill.bg_color = Color("#facc15")
			else:
				health_fill.bg_color = Color("#ef4444")
		else:
			health_fill.bg_color = Color("#ef4444")

	var mana_fill := mana_bar_3d.get_theme_stylebox("fill") as StyleBoxFlat
	if is_instance_valid(mana_fill):
		if mana_percent >= 1.0:
			mana_fill.bg_color = Color("#38e1ff")
		else:
			mana_fill.bg_color = Color("#0ea5e9")

	_update_status_visibility()


func setup_navigation() -> void:
	pass

func _setup_navigation_agent() -> void:
	pass

func setup_timers() -> void:
	if not has_node("AttackTimer"):
		attack_timer = Timer.new()
		attack_timer.name = "AttackTimer"
		add_child(attack_timer)
	else:
		attack_timer = get_node("AttackTimer")
	
	attack_timer.wait_time = 1.0 / get_effective_attack_speed()
	attack_timer.timeout.connect(_on_attack_timer_timeout)
	

func get_max_health() -> float:
	var star_multiplier: float = stats.get_star_multiplier(star_level)
	return stats.max_health * star_multiplier * (1.0 + float(synergy_bonuses.get("max_health_pct", 0.0)))

func get_attack_damage() -> float:
	var star_multiplier: float = stats.get_star_multiplier(star_level)
	var base_damage: float = stats.attack_damage * star_multiplier
	if BattleClock.now_msec() < attack_weakened_until_msec:
		base_damage *= attack_damage_multiplier
	
	for buff in active_buffs:
		if buff.has("attack_multiplier"):
			base_damage *= buff.attack_multiplier
	
	var damage_multiplier := 1.0 + float(synergy_bonuses.get("damage_pct", 0.0)) + get_power_aura_bonus()
	# Sinergia Ferocidade: Cada acúmulo de Ímpeto amplia o dano de ataque
	if ferocidade_stacks > 0 and float(synergy_bonuses.get("ferocidade_atk_pct", 0.0)) > 0.0:
		damage_multiplier += ferocidade_stacks * float(synergy_bonuses.get("ferocidade_atk_pct", 0.0))
	# Sinergia Seiva: Crescimento amplifica dano das próprias ações
	if seiva_growth_stacks > 0 and float(synergy_bonuses.get("seiva_growth_pct", 0.0)) > 0.0:
		damage_multiplier += seiva_growth_stacks * float(synergy_bonuses.get("seiva_growth_pct", 0.0))
	if stats and stats.is_atacante_role() and consecutive_attacks > 0:
		damage_multiplier += 0.05 * consecutive_attacks
	if is_instance_valid(current_target):
		if current_target.marked_team == team and BattleClock.now_msec() < current_target.mark_expires_at_msec:
			damage_multiplier += float(synergy_bonuses.get("marked_target_damage_pct", 0.0))
		if _has_ally_focusing_target(current_target):
			damage_multiplier += float(synergy_bonuses.get("focus_fire_damage_pct", 0.0))
	return base_damage * damage_multiplier

func get_power_aura_bonus() -> float:
	if not is_inside_tree() or not visible or current_state in [State.IDLE, State.DEAD]:
		return 0.0
	var board := _get_combat_board()
	if not board:
		return 0.0
	var target_cell := board.get_grid_position(board.to_local(global_position))
	if not board.get_cell(target_cell):
		return 0.0
	var bonus := 0.0
	var ally_group := "player_units" if team == 0 else "enemy_units"
	for source: BaseUnit3D in get_tree().get_nodes_in_group(ally_group):
		if source == self or not source.visible or source.current_state in [State.IDLE, State.DEAD]:
			continue
		if source.stats.passive_aura_effect != "power":
			continue
		var source_cell := board.get_grid_position(board.to_local(source.global_position))
		if source.stats.passive_aura_range > 0 and board.get_cell(source_cell) and board.get_hex_distance(source_cell, target_cell) <= source.stats.passive_aura_range:
			bonus = maxf(bonus, source.stats.passive_aura_power)
	return bonus

func set_synergy_bonuses(bonuses: Dictionary) -> void:
	var old_health_ratio := current_health / maxf(get_max_health(), 1.0) if stats else 1.0
	synergy_bonuses = bonuses.duplicate(true)
	if stats and current_health > 0.0:
		current_health = minf(get_max_health(), get_max_health() * old_health_ratio)
	if navigation_agent:
		navigation_agent.max_speed = get_movement_speed()
	if attack_timer and stats:
		attack_timer.wait_time = 1.0 / get_effective_attack_speed()
	if health_bar_3d:
		health_bar_3d.max_value = get_max_health()
	update_health_bar()

func _has_ally_focusing_target(target: BaseUnit3D) -> bool:
	if float(synergy_bonuses.get("focus_fire_damage_pct", 0.0)) <= 0.0:
		return false
	var ally_group := "player_units" if team == 0 else "enemy_units"
	for ally in get_tree().get_nodes_in_group(ally_group):
		if ally != self and ally.current_state != State.DEAD and ally.current_target == target:
			return true
	return false

func get_effective_attack_speed() -> float:
	var speed := stats.attack_speed * (1.0 + float(synergy_bonuses.get("attack_speed_pct", 0.0)))
	if BattleClock.now_msec() < slowed_until_msec:
		speed *= 0.7
	if BattleClock.now_msec() < speed_buff_until_msec:
		speed *= speed_buff_multiplier
	return maxf(speed, 0.1)

func get_effective_armor() -> float:
	var total := stats.armor if stats else 0.0
	total += float(synergy_bonuses.get("armor_flat", 0.0))
	total += float(synergy_bonuses.get("bonus_armor", 0.0))
	for buff in active_buffs:
		if buff.has("armor_flat"):
			total += float(buff.armor_flat)
		if buff.has("bonus_armor"):
			total += float(buff.bonus_armor)
	if BattleClock.now_msec() < assombro_shred_until_msec:
		total *= (1.0 - assombro_shred_pct)
	return maxf(total, 0.0)

func get_effective_magic_resist() -> float:
	var total := stats.magic_resist if stats else 0.0
	total += float(synergy_bonuses.get("magic_resist_flat", 0.0))
	total += float(synergy_bonuses.get("bonus_magic_resist", 0.0))
	for buff in active_buffs:
		if buff.has("magic_resist_flat"):
			total += float(buff.magic_resist_flat)
		if buff.has("bonus_magic_resist"):
			total += float(buff.bonus_magic_resist)
	if BattleClock.now_msec() < assombro_shred_until_msec:
		total *= (1.0 - assombro_shred_pct)
	return maxf(total, 0.0)

func apply_assombro_mark(pct: float, duration: float) -> void:
	assombro_shred_pct = maxf(assombro_shred_pct, pct)
	assombro_shred_until_msec = maxi(assombro_shred_until_msec, BattleClock.now_msec() + int(duration * 1000.0))
	CombatFeedback.create_status_indicator(self, "-DEFESA", 0.8)

func apply_speed_buff(duration: float, multiplier: float = 1.35, label: String = "+VELOCIDADE") -> void:
	speed_buff_multiplier = multiplier
	speed_buff_until_msec = maxi(speed_buff_until_msec, BattleClock.now_msec() + int(duration * 1000.0))
	if attack_timer:
		attack_timer.wait_time = 1.0 / get_effective_attack_speed()
	CombatFeedback.create_status_indicator(self, label, duration)

func apply_slow(duration: float) -> void:
	var resistance := clampf(float(synergy_bonuses.get("control_resist_pct", 0.0)), 0.0, 0.9)
	if BattleClock.now_msec() < vigilia_cc_resist_until_msec:
		resistance += float(synergy_bonuses.get("vigilia_cc_resist_pct", 0.0))
	var adjusted_duration := duration * (1.0 - clampf(resistance, 0.0, 0.9))
	slowed_until_msec = maxi(slowed_until_msec, BattleClock.now_msec() + int(adjusted_duration * 1000.0))
	if attack_timer:
		attack_timer.wait_time = 1.0 / get_effective_attack_speed()

func apply_attack_weakness(duration: float, damage_multiplier: float = 0.7) -> void:
	if current_state == State.DEAD or duration <= 0.0:
		return
	var now := BattleClock.now_msec()
	if now >= attack_weakened_until_msec:
		attack_damage_multiplier = 1.0
	attack_damage_multiplier = minf(attack_damage_multiplier, clampf(damage_multiplier, 0.0, 1.0))
	attack_weakened_until_msec = maxi(attack_weakened_until_msec, now + int(duration * 1000.0))
	CombatFeedback.create_status_indicator(self, "ENFRAQUECIDO", duration)

func is_stunned() -> bool:
	return BattleClock.now_msec() < stunned_until_msec

func is_immune() -> bool:
	return BattleClock.now_msec() < immune_until_msec

func apply_stun(duration: float, label: String = "ATORDOADO") -> void:
	if current_state == State.DEAD or duration <= 0.0 or is_on_bench():
		return
	var resist := clampf(float(synergy_bonuses.get("control_resist_pct", 0.0)) + (stats.stun_resist if stats else 0.0), 0.0, 0.9)
	if BattleClock.now_msec() < vigilia_cc_resist_until_msec:
		resist += float(synergy_bonuses.get("vigilia_cc_resist_pct", 0.0))
	var final_duration := duration * (1.0 - clampf(resist, 0.0, 0.9))
	if final_duration <= 0.0:
		return
	stunned_until_msec = maxi(stunned_until_msec, BattleClock.now_msec() + int(final_duration * 1000.0))
	_was_stunned = true
	velocity = Vector3.ZERO
	if attack_timer:
		attack_timer.stop()
	if navigation_agent:
		navigation_agent.velocity = Vector3.ZERO
	if unit_visual:
		unit_visual.update_locomotion(false, 0.0, true)
	if current_state in [State.ATTACKING, State.MOVING]:
		current_state = State.IDLE
	CombatFeedback.create_status_indicator(self, label, final_duration)
	CombatFeedback.create_hit_particles(global_position + Vector3.UP * 0.8, Color("#fde047"))

func _recover_from_stun() -> void:
	if current_state == State.DEAD or is_on_bench():
		return
	if stats and stats.is_stationary:
		_wait_rooted()
		_rooted_target_timer = 0.0
		find_target()
		return
	
	current_state = State.IDLE
	velocity = Vector3.ZERO
	if is_instance_valid(current_target) and not current_target.is_queued_for_deletion() and current_target.current_state != State.DEAD and not current_target.is_on_bench() and current_target.visible:
		check_attack_or_move()
	else:
		current_target = null
		find_target()
	
	if current_mana >= stats.max_mana and stats.ability_name and current_state != State.IDLE and not is_stunned():
		cast_ability()

func apply_armor_shred(duration: float, amount: float) -> void:
	if current_state == State.DEAD or duration <= 0.0:
		return
	armor_shred_amount = maxf(armor_shred_amount, amount)
	armor_shred_until_msec = maxi(armor_shred_until_msec, BattleClock.now_msec() + int(duration * 1000.0))
	CombatFeedback.create_status_indicator(self, "ARMADURA REDUZIDA", duration)

func on_enemy_defeated() -> void:
	enemies_defeated = mini(enemies_defeated + 1, MAX_CERRADO_STACKS)

func start_combat() -> void:
	if is_on_bench():
		return
	in_combat = true
	stunned_until_msec = 0
	_was_stunned = false
	_idle_target_timer = 0.0
	use_navigation = false
	_detour_dir = Vector3.ZERO
	_detour_timer = 0.0
	velocity = Vector3.ZERO
	combat_ground_height = global_position.y
	
	# Reset de sinergias da nova proposta
	seiva_growth_stacks = 0
	_seiva_timer = 0.0
	vigilia_triggered = false
	vigilia_cc_resist_until_msec = 0
	_correnteza_timer = 0.0
	_last_vozes_emit_msec = 0
	_last_vozes_receive_msec = 0
	ferocidade_stacks = 0
	ferocidade_hits = 0
	_last_target_id = 0
	_last_travessia_msec = 0
	has_travessia_burst = false
	assombro_shred_until_msec = 0
	assombro_shred_pct = 0.0
	_assombro_emitters.clear()
	encanto_charged = false
	fulgor_first_ability = false

	if float(synergy_bonuses.get("fulgor_start_mana", 0.0)) > 0.0:
		current_mana = minf(stats.max_mana, current_mana + float(synergy_bonuses.get("fulgor_start_mana", 0.0)))
		fulgor_first_ability = true
		update_mana_bar()

	var shield_multiplier := 1.0 + float(synergy_bonuses.get("shield_power_pct", 0.0))
	shield_multiplier *= 1.0 + float(synergy_bonuses.get("shield_received_pct", 0.0))
	var start_sh := get_max_health() * float(synergy_bonuses.get("start_shield_pct", 0.0)) * shield_multiplier
	if start_sh > 0.0:
		set_shield_with_source(start_sh, ShieldSource.CLASS)
	else:
		current_shield = 0.0
	first_attack_used = false
	first_hit_checked = false
	enemies_defeated = 0
	current_state = State.IDLE
	print("%s iniciando combate (Team %d)" % [stats.unit_name, team])
	find_target()

func find_target() -> void:
	if current_state == State.DEAD or current_state == State.CASTING or is_on_bench():
		return
	
	var enemy_group: String = "enemy_units" if team == 0 else "player_units"
	var enemies: Array = get_tree().get_nodes_in_group(enemy_group)
	
	# Filtrar inimigos mortos, ocultos ou que estejam no banco/reserva
	enemies = enemies.filter(func(e):
		return is_instance_valid(e) and not e.is_queued_for_deletion() and e.current_state != State.DEAD and e.visible and not e.is_on_bench()
	)
	# Uma planta escolhe entre alvos que consegue alcançar sem sair da casa.
	if stats.is_stationary and not enemies.is_empty():
		enemies = enemies.filter(func(e):
			return is_target_in_attack_range(e)
		)
		if enemies.is_empty():
			current_target = null
			_wait_rooted()
			return
	
	print("  %s procurando alvo... encontrados %d inimigos" % [stats.unit_name, enemies.size()])
	
	if enemies.is_empty():
		if attack_timer:
			attack_timer.stop()
		current_target = null
		current_state = State.IDLE
		velocity = Vector3.ZERO
		return
	
	# Prioridade de alvo: padrão é sempre a unidade mais próxima (CLOSEST)
	if stats.target_priority == UnitStats.TargetPriority.LOWEST_HP and not enemies.is_empty():
		var lowest_enemy: BaseUnit3D = null
		var min_hp := INF
		var closest_dist := INF
		for enemy in enemies:
			var hp: float = enemy.current_health
			var d: float = global_position.distance_to(enemy.global_position)
			if hp < min_hp or (is_equal_approx(hp, min_hp) and d < closest_dist):
				min_hp = hp
				closest_dist = d
				lowest_enemy = enemy
		current_target = lowest_enemy if lowest_enemy else get_closest_enemy(enemies)
	else:
		current_target = get_closest_enemy(enemies)
	
	# VERIFICAR SE TARGET FOI DEFINIDO
	if current_target:
		# Sinergia Travessia: Ao adquirir alvo ou trocar de identidade, ganha velocidade e golpe de aproximação
		var t_id := current_target.get_instance_id()
		if t_id != _last_target_id:
			_last_target_id = t_id
			var now := BattleClock.now_msec()
			if float(synergy_bonuses.get("travessia_speed_pct", 0.0)) > 0.0 and (now - _last_travessia_msec >= 4000):
				_last_travessia_msec = now
				apply_speed_buff(2.0, 1.0 + float(synergy_bonuses.get("travessia_speed_pct", 0.0)), "+TRAVESSIA")
				has_travessia_burst = true
		if float(synergy_bonuses.get("marked_target_damage_pct", 0.0)) > 0.0:
			var weakest := enemies[0] as BaseUnit3D
			for enemy in enemies:
				if enemy.current_health / maxf(enemy.get_max_health(), 1.0) < weakest.current_health / maxf(weakest.get_max_health(), 1.0):
					weakest = enemy
			weakest.marked_team = team
			weakest.mark_expires_at_msec = BattleClock.now_msec() + 3000
		print("%s mirando em %s" % [stats.unit_name, current_target.stats.unit_name])
		check_attack_or_move()
	else:
		print("%s não conseguiu definir alvo!" % stats.unit_name)
			
			
func get_frontline_enemy(enemies: Array) -> BaseUnit3D:
	# Pega o inimigo mais próximo da borda do nosso lado
	var our_side_z: float = global_position.z
	var closest: BaseUnit3D = null
	var min_distance := INF
	
	for enemy in enemies:
		# Distância no eixo Z (profundidade)
		var z_distance = abs(enemy.global_position.z - our_side_z)
		if z_distance < min_distance:
			min_distance = z_distance
			closest = enemy
	
	return closest if closest else enemies[0]

func get_backline_enemy(enemies: Array) -> BaseUnit3D:
	# Pega o inimigo mais distante
	var our_side_z: float = global_position.z
	var farthest: BaseUnit3D = null
	var max_distance := 0.0
	
	for enemy in enemies:
		var z_distance = abs(enemy.global_position.z - our_side_z)
		if z_distance > max_distance:
			max_distance = z_distance
			farthest = enemy
	
	return farthest if farthest else enemies[0]

func get_closest_enemy(enemies: Array) -> BaseUnit3D:
	var closest: BaseUnit3D = null
	var min_distance: float = INF
	
	for enemy in enemies:
		var distance := Vector2(global_position.x, global_position.z).distance_to(
			Vector2(enemy.global_position.x, enemy.global_position.z)
		)
		if distance < min_distance:
			min_distance = distance
			closest = enemy
	
	return closest

func get_attack_range_meters() -> float:
	return float(stats.get_attack_range_hexes()) * 2.0 + 0.5

func is_target_in_attack_range(target: BaseUnit3D) -> bool:
	if not is_instance_valid(target) or target.is_queued_for_deletion() or target.current_state == State.DEAD or not target.visible or target.is_on_bench():
		return false
	return Vector2(global_position.x, global_position.z).distance_to(
		Vector2(target.global_position.x, target.global_position.z)
	) <= get_attack_range_meters()

func has_pending_combat_effects() -> bool:
	return current_state == State.CASTING or BattleClock.now_msec() < _burn_expires_at_msec

func check_attack_or_move() -> void:
	if current_state == State.DEAD or current_state == State.CASTING or is_on_bench() or is_stunned():
		return
	if not is_instance_valid(current_target) or current_target.is_queued_for_deletion() or current_target.current_state == State.DEAD or current_target.is_on_bench():
		if debug_movement:
			print("%s: alvo invalidado" % stats.unit_name)
		current_target = null
		find_target()
		return
	
	var distance := Vector2(global_position.x, global_position.z).distance_to(
		Vector2(current_target.global_position.x, current_target.global_position.z)
	)
	var range_threshold := get_attack_range_meters()
	
	if debug_movement:
		print("%s: dist=%.2fm, range=%.2fm" % [
			stats.unit_name,
			distance,
			range_threshold
		])
	
	if distance <= range_threshold:
		if debug_movement:
			print("%s: ATACANDO!" % stats.unit_name)
		start_attacking()
	else:
		if attack_timer:
			attack_timer.stop()
		if debug_movement:
			print("%s: MOVENDO (modo: %s)" % [
				stats.unit_name,
				"Navigation" if use_navigation else "Direto"
			])
		move_towards_target()

func move_towards_target() -> void:
	if is_stunned():
		return
	if stats.is_stationary:
		_wait_rooted()
		return
	
	if not is_instance_valid(current_target) or current_target.is_queued_for_deletion() or current_target.current_state == State.DEAD or current_target.is_on_bench():
		if debug_movement:
			print("%s: alvo foi destruído ou no banco!" % stats.unit_name)
		current_target = null
		find_target()
		return
	
	if not current_target:
		if debug_movement:
			print("%s: sem alvo definido!" % stats.unit_name)
		find_target()
		return

	current_state = State.MOVING
	move_direct_to_target(0.0166)

func _physics_process(delta: float) -> void:
	if is_stunned():
		_was_stunned = true
		velocity = Vector3.ZERO
		return

	if _was_stunned:
		_was_stunned = false
		_recover_from_stun()
		return

	if stats and stats.is_stationary:
		velocity = Vector3.ZERO
		if current_state == State.ROOTED:
			_rooted_target_timer -= delta
			if _rooted_target_timer <= 0.0:
				_rooted_target_timer = 0.25
				find_target()
		return

	if current_state == State.MOVING:
		if not is_instance_valid(current_target) or current_target.current_state == State.DEAD or current_target.is_on_bench():
			current_target = null
			current_state = State.IDLE
			velocity = Vector3.ZERO
			_detour_timer = 0.0
			_detour_dir = Vector3.ZERO
			find_target()
		else:
			move_direct_to_target(delta)
	elif current_state == State.ATTACKING:
		if attack_timer and attack_timer.is_stopped():
			attack_timer.start()
	elif current_state == State.IDLE and in_combat:
		_idle_target_timer -= delta
		if _idle_target_timer <= 0.0:
			_idle_target_timer = 0.25
			find_target()

func _on_velocity_computed(_safe_velocity: Vector3) -> void:
	pass

func get_movement_speed() -> float:
	if not stats:
		return 2.0
	if stats.is_stationary:
		return 0.0
	var speed := stats.movement_speed / 100.0 * (1.0 + float(synergy_bonuses.get("move_speed_pct", 0.0)))
	if BattleClock.now_msec() < slowed_until_msec:
		speed *= 0.7
	if BattleClock.now_msec() < speed_buff_until_msec:
		speed *= speed_buff_multiplier
	return speed

func _wait_rooted() -> void:
	if current_state in [State.DEAD, State.CASTING]:
		return
	current_state = State.ROOTED
	velocity = Vector3.ZERO
	if attack_timer:
		attack_timer.stop()
	if navigation_agent:
		navigation_agent.velocity = Vector3.ZERO

func start_attacking() -> void:
	if current_state == State.DEAD or current_state == State.CASTING or is_on_bench() or is_stunned():
		return
	if not is_instance_valid(current_target) or current_target.current_state == State.DEAD or current_target.is_on_bench():
		current_target = null
		current_state = State.IDLE
		find_target()
		return
	if current_state == State.ATTACKING:
		if attack_timer and attack_timer.is_stopped():
			attack_timer.start()
		return
	
	current_state = State.ATTACKING
	velocity = Vector3.ZERO
	if attack_timer:
		attack_timer.start()

func _on_attack_timer_timeout() -> void:
	if current_state == State.DEAD or is_on_bench() or is_stunned():
		if attack_timer:
			attack_timer.stop()
		return
	if current_state == State.CASTING or current_state == State.MOVING:
		attack_timer.stop()
		return
	if current_state != State.ATTACKING:
		attack_timer.stop()
		if current_state == State.IDLE:
			find_target()
		return
	if not is_instance_valid(current_target) or current_target.current_state == State.DEAD or current_target.is_on_bench():
		attack_timer.stop()
		current_target = null
		current_state = State.IDLE
		find_target()
		return
	
	perform_attack()

func perform_attack() -> void:
	if is_stunned():
		return
	# VALIDAÇÃO
	if not is_instance_valid(current_target) or current_target.is_on_bench():
		if attack_timer:
			attack_timer.stop()
		current_target = null
		current_state = State.IDLE
		find_target()
		return
	
	if current_target.current_state == State.DEAD:
		current_target = null
		current_state = State.IDLE
		find_target()
		return
	var target_distance := Vector2(global_position.x, global_position.z).distance_to(
		Vector2(current_target.global_position.x, current_target.global_position.z)
	)
	if target_distance > get_attack_range_meters():
		check_attack_or_move()
		return
	
	_face_target()
	var ranged_attack := stats.get_attack_range_hexes() > 1
	unit_visual.play_attack(ranged_attack, 1.0 / get_effective_attack_speed())
	if ranged_attack:
		var p_color: Color = get_projectile_color()
		var is_dart: bool = stats.unit_id in ["caapora", "arara_azul_lear", "ararinha_azul", "mutum_de_alagoas", "mandacaru"]
		var start_p: Vector3 = global_position + Vector3.UP * (1.1 if is_flying() else 0.75)
		_spawn_ballistic_projectile(
			start_p,
			current_target,
			current_target.global_position + Vector3.UP * 0.7,
			p_color,
			0.55,
			0.20,
			Callable(),
			"%sAttackProj" % stats.unit_id,
			0.14,
			is_dart
		)
	
	var damage: float = get_attack_damage()
	if not first_attack_used:
		damage *= 1.0 + float(synergy_bonuses.get("first_attack_bonus_pct", 0.0))
		first_attack_used = true
	
	if has_travessia_burst:
		has_travessia_burst = false
		damage *= 1.0 + float(synergy_bonuses.get("travessia_burst_pct", 0.0))
		CombatFeedback.create_status_indicator(self, "GOLPE DE APROXIMAÇÃO", 0.8)
	
	# Verificar crítico
	var crit_chance := stats.critical_chance + float(synergy_bonuses.get("crit_chance", 0.0))
	crit_chance += float(synergy_bonuses.get("crit_after_kill", 0.0)) * mini(enemies_defeated, MAX_CERRADO_STACKS)
	var is_crit: bool = randf() < clampf(crit_chance, 0.0, 0.75)
	if is_crit:
		damage *= stats.critical_damage * (1.0 + float(synergy_bonuses.get("crit_damage_pct", 0.0)))
		CombatFeedback.create_damage_number(current_target.global_position, damage, CombatFeedback.DamageType.CRITICAL)
	
	current_target.take_damage(damage, self, UnitStats.DamageType.PHYSICAL)
	# Sinergia Ferocidade: Cada ataque básico que acerta concede Ímpeto (máx 8); a cada 3 acertos cura vida
	if float(synergy_bonuses.get("ferocidade_atk_pct", 0.0)) > 0.0:
		ferocidade_stacks = mini(ferocidade_stacks + 1, 8)
		ferocidade_hits += 1
		if ferocidade_hits % 3 == 0:
			var heal_val := get_max_health() * float(synergy_bonuses.get("ferocidade_heal_pct", 0.0))
			heal(heal_val, self)
			CombatFeedback.create_status_indicator(self, "+FEROCIDADE", 0.6)
	if stats and stats.is_atacante_role():
		consecutive_attacks = mini(consecutive_attacks + 1, 10)
	var am: Node = get_node_or_null("/root/AudioManager")
	if am and am.has_method("play_melee_hit"):
		am.play_melee_hit()
	add_mana(stats.mana_per_attack)
	
	check_attack_or_move()

func _face_target() -> void:
	if stats.is_stationary:
		return
	if not is_instance_valid(current_target):
		return
	var offset := current_target.global_position - global_position
	# O manequim olha para +Z, igual ao movimento; evita virar de costas ao atacar.
	if Vector2(offset.x, offset.z).length_squared() > 0.0001:
		rotation.y = atan2(offset.x, offset.z)

func _show_plant_projectile(target_position: Vector3) -> void:
	_spawn_ballistic_projectile(
		global_position + Vector3.UP * 0.75,
		null,
		target_position + Vector3.UP * 0.65,
		Color("#b5e66a"),
		0.5,
		0.18,
		Callable(),
		"PlantProjectile",
		0.12
	)

func get_projectile_color() -> Color:
	if not stats:
		return Color.WHITE
	match stats.unit_id:
		"cumacanga":
			return Color(1.0, 0.35, 0.05)
		"caapora":
			return Color(0.2, 0.9, 0.35)
		"arara_azul_lear":
			return Color(0.1, 0.75, 1.0)
		"ararinha_azul":
			return Color(0.25, 0.65, 1.0)
		"mutum_de_alagoas":
			return Color(0.65, 0.2, 0.9)
		"teiniagua":
			return Color(0.65, 0.35, 1.0)
		"mae_de_ouro":
			return Color(1.0, 0.85, 0.15)
		"alamoa":
			return Color(0.95, 0.9, 0.35)
		"papa_figo":
			return Color(0.45, 0.55, 0.15)
		"pequi":
			return Color(0.75, 0.85, 0.2)
		"guarana":
			return Color(0.95, 0.15, 0.2)
		"mandacaru":
			return Color(0.3, 0.85, 0.25)
		"vitoria_regia", "aguape":
			return Color(0.2, 0.85, 0.95)
		"brinco_de_princesa":
			return Color(0.95, 0.25, 0.65)
		"bromelia":
			return Color(1.0, 0.45, 0.15)
		"palmito_jucara":
			return Color(0.5, 0.75, 0.3)
		_:
			return stats.get_tier_color()

func _spawn_ballistic_projectile(
	start_pos: Vector3,
	target: BaseUnit3D,
	impact_pos: Vector3,
	color: Color,
	arc_height: float = 1.2,
	duration: float = 0.35,
	on_impact: Callable = Callable(),
	projectile_name: String = "UnitProjectile",
	radius: float = 0.16,
	is_arrow_or_dart: bool = false
) -> Node3D:
	var projectile := Node3D.new()
	projectile.name = projectile_name
	
	var mesh_inst := MeshInstance3D.new()
	if is_arrow_or_dart:
		var cyl := CylinderMesh.new()
		cyl.top_radius = radius * 0.3
		cyl.bottom_radius = radius * 0.6
		cyl.height = radius * 3.5
		mesh_inst.mesh = cyl
		mesh_inst.rotation.x = PI * 0.5
	else:
		var sphere := SphereMesh.new()
		sphere.radius = radius
		sphere.height = radius * 2.0
		mesh_inst.mesh = sphere
		
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.emission_enabled = true
	mat.emission = color
	mat.emission_energy_multiplier = 2.4
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mesh_inst.material_override = mat
	projectile.add_child(mesh_inst)
	
	var glow := OmniLight3D.new()
	glow.name = "OmniLight3D"
	glow.light_color = color
	glow.light_energy = 1.5
	glow.omni_range = 2.8
	projectile.add_child(glow)
	
	var scene_root: Node = get_tree().current_scene if get_tree() else null
	if not scene_root:
		scene_root = get_parent()
	if not scene_root:
		return projectile
	scene_root.add_child(projectile)
	
	projectile.global_position = start_pos
	
	var flight := projectile.create_tween()
	flight.tween_method(func(progress: float) -> void:
		if is_instance_valid(projectile):
			var current_target_pos := impact_pos
			if is_instance_valid(target) and target.current_state != State.DEAD:
				current_target_pos = target.global_position + Vector3.UP * 0.7
			var current_pos := start_pos.lerp(current_target_pos, progress) + Vector3.UP * sin(progress * PI) * arc_height
			if is_arrow_or_dart and progress < 0.98:
				var next_p := start_pos.lerp(current_target_pos, progress + 0.02) + Vector3.UP * sin((progress + 0.02) * PI) * arc_height
				var forward_dir := (next_p - current_pos).normalized()
				if forward_dir.length_squared() > 0.0001:
					var up_vec := Vector3.UP
					if abs(forward_dir.dot(Vector3.UP)) > 0.95:
						up_vec = Vector3.FORWARD
					projectile.look_at(current_pos + forward_dir, up_vec)
			projectile.global_position = current_pos
	, 0.0, 1.0, duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
	
	flight.tween_callback(func() -> void:
		if is_instance_valid(projectile):
			projectile.queue_free()
		CombatFeedback.create_hit_particles(impact_pos + Vector3.UP * 0.5, color)
		if on_impact.is_valid():
			on_impact.call()
	)
	return projectile

func take_damage(amount: float, attacker: BaseUnit3D, damage_type: UnitStats.DamageType = UnitStats.DamageType.PHYSICAL) -> void:
	if current_state == State.DEAD or is_on_bench():
		return
	if is_immune():
		CombatFeedback.create_status_indicator(self, "IMUNE", 0.5)
		return
	if not first_hit_checked:
		first_hit_checked = true
		var dodge_chance := float(synergy_bonuses.get("dodge_first_hit_chance", 0.0))
		if dodge_chance > 0.0 and randf() < dodge_chance:
			return

	var mitigation := 0.0
	if damage_type == UnitStats.DamageType.PHYSICAL:
		var armor := stats.armor + float(synergy_bonuses.get("armor_flat", 0.0))
		if BattleClock.now_msec() < armor_shred_until_msec:
			armor = maxf(armor - armor_shred_amount, 0.0)
		if BattleClock.now_msec() < assombro_shred_until_msec:
			armor *= (1.0 - assombro_shred_pct)
		mitigation = armor / (100.0 + maxf(armor, 0.0))
	elif damage_type == UnitStats.DamageType.MAGICAL:
		var magic_resist := stats.magic_resist + float(synergy_bonuses.get("magic_resist_flat", 0.0))
		if BattleClock.now_msec() < assombro_shred_until_msec:
			magic_resist *= (1.0 - assombro_shred_pct)
		mitigation = magic_resist / (100.0 + maxf(magic_resist, 0.0))
	var extra_reduction := 0.0
	if damage_type != UnitStats.DamageType.TRUE:
		extra_reduction = float(synergy_bonuses.get("damage_reduction_pct", 0.0))
		if current_health / maxf(get_max_health(), 1.0) <= 0.5:
			extra_reduction += float(synergy_bonuses.get("low_health_resistance_pct", 0.0))
	mitigation = clampf(mitigation, 0.0, 0.8)
	var actual_damage: float = amount * (1.0 - mitigation) * (1.0 - clampf(extra_reduction, 0.0, 0.8))
	if BattleClock.now_msec() < reflect_until_msec:
		actual_damage *= 0.6
		if is_instance_valid(attacker) and attacker != self and attacker.current_state != State.DEAD and not attacker.is_on_bench():
			var reflected := actual_damage * reflect_pct
			attacker.take_damage(reflected, self, UnitStats.DamageType.PHYSICAL)
			CombatFeedback.create_damage_number(attacker.global_position, reflected, CombatFeedback.DamageType.CRITICAL)
			CombatFeedback.create_hit_particles(attacker.global_position, Color("#94a3b8"))
	if actual_damage <= 0.0:
		return
	
	# Sinergia Vigília: Ao cair abaixo de 50% de vida, recebe escudo por 4s antes do dano
	if not vigilia_triggered and float(synergy_bonuses.get("vigilia_shield_pct", 0.0)) > 0.0:
		if (current_health - (actual_damage - minf(current_shield, actual_damage))) < (get_max_health() * 0.5):
			vigilia_triggered = true
			var v_sh := get_max_health() * float(synergy_bonuses.get("vigilia_shield_pct", 0.0))
			current_shield += v_sh
			vigilia_cc_resist_until_msec = BattleClock.now_msec() + 4000
			CombatFeedback.create_status_indicator(self, "+VIGÍLIA", 1.0)

	var was_shielded := has_active_shield()
	var shield_absorbed := minf(current_shield, actual_damage)
	current_shield -= shield_absorbed
	var health_damage := actual_damage - shield_absorbed
	current_health -= health_damage
	combat_metric_recorded.emit(self, &"damage_received", actual_damage)
	if is_instance_valid(attacker):
		attacker.combat_metric_recorded.emit(attacker, &"damage_dealt", actual_damage)
	update_health_bar()
	
	# FEEDBACK VISUAL DE DANO
	if health_damage > 0.0:
		CombatFeedback.create_damage_number(global_position, health_damage, CombatFeedback.DamageType.DAMAGE)
		CombatFeedback.create_hit_particles(global_position, Color.RED)
	
	flash_damage()
	# Sinergia Assombro: Ao acertar com dano, aplica marca por 4s reduzindo defesas do alvo
	if is_instance_valid(attacker) and float(attacker.synergy_bonuses.get("assombro_shred_pct", 0.0)) > 0.0:
		var now := BattleClock.now_msec()
		var a_id := attacker.get_instance_id()
		if now - int(_assombro_emitters.get(a_id, 0)) >= 6000:
			_assombro_emitters[a_id] = now
			apply_assombro_mark(float(attacker.synergy_bonuses.get("assombro_shred_pct", 0.0)), 4.0)
	# O golpe que quebra o escudo também não gera mana.
	if not was_shielded and current_health > 0.0:
		add_mana(stats.mana_when_hit)
	if float(synergy_bonuses.get("root_on_hit_chance", 0.0)) > 0.0 and is_instance_valid(attacker) and randf() < float(synergy_bonuses.get("root_on_hit_chance", 0.0)):
		attacker.apply_slow(1.0)
	
	if is_instance_valid(attacker) and float(attacker.synergy_bonuses.get("slow_on_hit_chance", 0.0)) > 0.0 and randf() < float(attacker.synergy_bonuses.get("slow_on_hit_chance", 0.0)):
		apply_slow(1.5)
	if current_health <= 0:
		if is_instance_valid(attacker):
			attacker.on_enemy_defeated()
		die()

func heal(amount: float, healer: BaseUnit3D = null) -> float:
	if current_state == State.DEAD or amount <= 0.0 or is_on_bench():
		return 0.0

	var heal_multiplier := 1.0 + float(synergy_bonuses.get("healing_received_pct", 0.0))
	if is_instance_valid(healer):
		heal_multiplier *= 1.0 + float(healer.synergy_bonuses.get("healing_power_pct", 0.0))
	if BattleClock.now_msec() < _burn_expires_at_msec:
		heal_multiplier *= 0.4
	var healed_amount := minf(amount * heal_multiplier, maxf(get_max_health() - current_health, 0.0))
	if healed_amount <= 0.0:
		return 0.0

	current_health += healed_amount
	update_health_bar()
	var source := healer if is_instance_valid(healer) else self
	source.combat_metric_recorded.emit(source, &"healing_done", healed_amount)
	return healed_amount

func flash_damage() -> void:
	if unit_visual:
		unit_visual.flash_damage()

func has_active_shield() -> bool:
	return current_shield > 0.0

func add_mana(amount: float) -> void:
	# Centraliza o bloqueio para ataques, golpes recebidos, regeneração e aliados.
	if current_state in [State.IDLE, State.DEAD, State.CASTING] or has_active_shield() or amount <= 0.0:
		return
	
	var adjusted_amount := amount * (1.0 + float(synergy_bonuses.get("mana_generation_pct", 0.0)))
	current_mana = min(current_mana + adjusted_amount, stats.max_mana)
	update_mana_bar()
	
	if current_mana >= stats.max_mana:
		cast_ability()

func cast_ability() -> void:
	if not stats.ability_name or current_state in [State.DEAD, State.CASTING] or has_active_shield() or is_stunned():
		return
	
	# IMPORTANTE: Não usar habilidade se não estiver em combate
	if current_state == State.IDLE:
		return
	
	current_state = State.CASTING
	_face_target()
	unit_visual.play_cast()
	current_mana = 0.0
	update_mana_bar()
	
	ability_cast.emit(stats.ability_name)
	
	# FEEDBACK VISUAL DE HABILIDADE
	CombatFeedback.create_ability_effect(global_position, stats.ability_name, stats.get_tier_color())
	CombatFeedback.create_hit_particles(global_position, stats.get_tier_color())
	
	print("%s usou %s!" % [stats.unit_name, stats.ability_name])
	
	# Guardar e consumir bônus temporários de Encanto e Fulgor no início do lançamento
	var had_encanto := encanto_charged
	var had_fulgor := fulgor_first_ability
	encanto_charged = false
	fulgor_first_ability = false

	apply_ability_effect()
	
	await get_tree().create_timer(0.5, false).timeout
	# O ataque pode ter retomado (ou a unidade pode ter morrido) enquanto a
	# habilidade aguardava. Só encerra o estado se ainda for esta conjuração.
	if current_state == State.CASTING:
		current_state = State.IDLE
		find_target()

	# Sinergia Encanto: Prepara a próxima habilidade com dano, cura e escudo ampliados
	if float(synergy_bonuses.get("encanto_power_pct", 0.0)) > 0.0:
		encanto_charged = true
		CombatFeedback.create_status_indicator(self, "+ENCANTO", 0.8)

	# Sinergia Vozes: Ao concluir habilidade, envia Eco dando mana a até 2 aliados de Vozes dentro de 2 hexágonos
	if float(synergy_bonuses.get("vozes_echo_mana", 0.0)) > 0.0:
		var now := BattleClock.now_msec()
		if now - _last_vozes_emit_msec >= 4000:
			_last_vozes_emit_msec = now
			_emit_vozes_echo(float(synergy_bonuses.get("vozes_echo_mana", 0.0)))

func get_ability_power_multiplier() -> float:
	var mult := 1.0
	# Sinergia Seiva: Crescimento amplifica dano, cura e escudos das próprias ações
	if seiva_growth_stacks > 0 and float(synergy_bonuses.get("seiva_growth_pct", 0.0)) > 0.0:
		mult += seiva_growth_stacks * float(synergy_bonuses.get("seiva_growth_pct", 0.0))
	# Sinergia Encanto: Prepara a própria próxima habilidade (+8%/14%/22%/32%)
	if encanto_charged and float(synergy_bonuses.get("encanto_power_pct", 0.0)) > 0.0:
		mult += float(synergy_bonuses.get("encanto_power_pct", 0.0))
	# Sinergia Fulgor: Primeira habilidade fortalecida (+8%/12%/18%/25%)
	if fulgor_first_ability and float(synergy_bonuses.get("fulgor_power_pct", 0.0)) > 0.0:
		mult += float(synergy_bonuses.get("fulgor_power_pct", 0.0))
	return mult

func _emit_vozes_echo(mana_amount: float) -> void:
	var board := _get_combat_board()
	if not board:
		return
	var my_cell := board.get_grid_position(board.to_local(global_position))
	var ally_group := "player_units" if team == 0 else "enemy_units"
	var vozes_allies: Array[BaseUnit3D] = []
	for ally: BaseUnit3D in get_tree().get_nodes_in_group(ally_group):
		if ally == self or not is_instance_valid(ally) or ally.current_state in [State.IDLE, State.DEAD] or ally.is_on_bench():
			continue
		if not ally.stats or not ally.stats.origins.has("Vozes"):
			continue
		var a_cell := board.get_grid_position(board.to_local(ally.global_position))
		if board.get_cell(a_cell) and board.get_hex_distance(my_cell, a_cell) <= 2:
			vozes_allies.append(ally)
	
	vozes_allies.sort_custom(func(a, b):
		return global_position.distance_to(a.global_position) < global_position.distance_to(b.global_position)
	)
	var count := mini(vozes_allies.size(), 2)
	var now := BattleClock.now_msec()
	for i in count:
		var ally := vozes_allies[i]
		if now - ally._last_vozes_receive_msec >= 2000:
			ally._last_vozes_receive_msec = now
			ally.add_mana(mana_amount)
			CombatFeedback.create_status_indicator(ally, "+ECO", 0.6)

func apply_ability_effect() -> void:
	if name_label:
		var tween: Tween = create_tween()
		tween.tween_property(name_label, "modulate", Color.YELLOW, 0.2)
		tween.tween_property(name_label, "modulate", Color.WHITE, 0.2)
	if stats.unit_id == "cumacanga":
		_cast_cumacanga_fireball()
		return
	match stats.unit_id:
		"alamoa":
			_cast_alamoa_charm()
			return
		"anhanga":
			_cast_anhanga_roar()
			return
		"cabeca_de_cuia":
			_cast_cabeca_de_cuia()
			return
		"mae_de_ouro":
			_cast_mae_de_ouro()
			return
		"mapinguari":
			_cast_mapinguari()
			return
		"matinta_perera":
			_cast_matinta_perera()
			return
		"minhocao":
			_cast_minhocao_earthquake()
			return
		"papa_figo":
			_cast_papa_figo()
			return
		"quibungo":
			_cast_quibungo_sack()
			return
		"teiniagua":
			_cast_teiniagua_orb()
			return
		"araucaria":
			_cast_araucaria_canopy()
			return
		"caapora":
			_cast_caapora_piercing_arrow()
			return
		"comadre_fulozinha":
			_cast_comadre_fulozinha()
			return
		"corpo_seco":
			_cast_corpo_seco_drain()
			return
		"mboi_guacu":
			_cast_mboi_guacu_constriction()
			return
		"onca_pintada":
			_cast_onca_ambush()
			return
		"pau_brasil":
			_cast_pau_brasil_bloom()
			return
		"pisadeira":
			_cast_pisadeira_terror()
			return
		"sumauma":
			_cast_sumauma_roots()
			return
		"sabia_laranjeira":
			_cast_sabia_laranjeira()
			return
	if (stats.is_assassin and stats.unit_id != "lobo_guara" and stats.unit_id != "matinta_perera" and stats.unit_id != "onca_pintada") or stats.unit_id == "jararaca":
		_cast_assassin_strike()
		return
	_apply_ability_healing()
	_apply_ability_shield()
	_apply_ability_energy()
	if stats.cost <= 3 or stats.is_stationary:
		_apply_ability_damage()

func _apply_ability_shield() -> void:
	if stats.ability_shield <= 0.0:
		return
	var shield := stats.ability_shield * stats.get_star_multiplier(star_level)
	shield *= 1.0 + float(synergy_bonuses.get("shield_power_pct", 0.0))
	shield *= 1.0 + float(synergy_bonuses.get("shield_received_pct", 0.0))
	set_shield_with_source(maxf(current_shield, shield), ShieldSource.SELF)
	
	if stats.unit_id == "tatu_bola":
		if model:
			var tw := create_tween()
			tw.tween_property(model, "scale", model_base_scale * Vector3(1.25, 0.65, 1.25), 0.15).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
			tw.tween_property(model, "scale", model_base_scale, 0.25).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
		CombatFeedback.create_hit_particles(global_position, Color("#facc15"))
		CombatFeedback.create_status_indicator(self, "CARAPAÇA", 1.2)
	elif stats.unit_id == "capivara":
		CombatFeedback.create_hit_particles(global_position, Color("#38bdf8"))
		CombatFeedback.create_status_indicator(self, "REFÚGIO", 1.2)
	elif stats.unit_id == "mandacaru":
		CombatFeedback.create_hit_particles(global_position, Color("#22c55e"))
		CombatFeedback.create_status_indicator(self, "CERCA DE ESPINHOS", 1.2)
		_create_mandacaru_thorn_element(global_position, 4.0)
	elif stats.unit_id == "caranguejo_uca":
		if model:
			var tw := create_tween()
			tw.tween_property(model, "scale", model_base_scale * Vector3(1.3, 0.7, 1.3), 0.12).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
			tw.tween_property(model, "scale", model_base_scale, 0.2).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
		CombatFeedback.create_hit_particles(global_position, Color("#0284c7"))
		CombatFeedback.create_status_indicator(self, "PINÇA E CARAPAÇA", 1.2)
	elif stats.unit_id == "ipe_amarelo":
		if model:
			var tw := create_tween()
			tw.tween_property(model, "scale", model_base_scale * Vector3(1.15, 1.25, 1.15), 0.15).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
			tw.tween_property(model, "scale", model_base_scale, 0.22).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
		CombatFeedback.create_hit_particles(global_position, Color("#facc15"))
		CombatFeedback.create_status_indicator(self, "CASCA DOURADA", 1.2)
	elif stats.unit_id == "tamandua_bandeira":
		if model:
			var tw := create_tween()
			tw.tween_property(model, "rotation:y", 0.35, 0.1).set_trans(Tween.TRANS_QUAD)
			tw.tween_property(model, "rotation:y", -0.35, 0.12).set_trans(Tween.TRANS_QUAD)
			tw.tween_property(model, "rotation:y", 0.0, 0.1).set_trans(Tween.TRANS_QUAD)
		CombatFeedback.create_hit_particles(global_position, Color("#d97706"))
		CombatFeedback.create_status_indicator(self, "GARRAS DE DEFESA", 1.2)
	else:
		CombatFeedback.create_status_indicator(self, "ESCUDO", 1.0)

func _apply_ability_energy() -> void:
	if stats.ability_mana <= 0.0:
		return
	var ally_group := "player_units" if team == 0 else "enemy_units"
	var allies: Array = get_tree().get_nodes_in_group(ally_group).filter(func(ally):
		if not is_instance_valid(ally) or ally == self or not ally.visible or ally.is_on_bench():
			return false
		if ally.current_state not in [State.MOVING, State.ATTACKING, State.ROOTED] or ally.has_active_shield() or ally.current_mana >= ally.stats.max_mana:
			return false
		var distance := Vector2(global_position.x, global_position.z).distance_to(Vector2(ally.global_position.x, ally.global_position.z))
		return distance <= maxf(stats.ability_range, stats.attack_range * 2.0)
	)
	allies.sort_custom(func(a: BaseUnit3D, b: BaseUnit3D) -> bool:
		return a.current_mana / maxf(a.stats.max_mana, 1.0) < b.current_mana / maxf(b.stats.max_mana, 1.0)
	)
	var mana_gain: float = stats.ability_mana * stats.get_star_multiplier(star_level)
	for i in mini(maxi(stats.ability_targets, 1), allies.size()):
		var target_ally := allies[i] as BaseUnit3D
		target_ally.add_mana(mana_gain)
		CombatFeedback.create_status_indicator(target_ally, "+%d MANA" % int(mana_gain), 1.0)
		CombatFeedback.create_hit_particles(target_ally.global_position, Color("#80d8ea"))
		_spawn_ballistic_projectile(
			global_position + Vector3.UP * 0.9,
			target_ally,
			target_ally.global_position + Vector3.UP * 0.6,
			Color("#80d8ea"),
			1.2,
			0.30,
			Callable(),
			"GuaranaEnergySeed",
			0.18
		)

func _cast_alamoa_charm() -> void:
	if model:
		var tw := create_tween()
		tw.tween_property(model, "scale", model_base_scale * Vector3(1.15, 1.25, 1.15), 0.15).set_trans(Tween.TRANS_QUAD)
		tw.tween_property(model, "scale", model_base_scale, 0.2).set_trans(Tween.TRANS_BOUNCE)
	CombatFeedback.create_status_indicator(self, "CANTO HIPNÓTICO", 1.2)
	CombatFeedback.create_hit_particles(global_position, Color("#f472b6"))
	
	var enemy_group := "enemy_units" if team == 0 else "player_units"
	var enemies: Array = get_tree().get_nodes_in_group(enemy_group).filter(func(unit):
		return is_instance_valid(unit) and unit is BaseUnit3D and unit.current_state != State.DEAD and unit.visible and not unit.is_on_bench()
	)
	if enemies.is_empty():
		return
	
	enemies.sort_custom(func(a: BaseUnit3D, b: BaseUnit3D) -> bool:
		var dist_a := Vector2(global_position.x, global_position.z).distance_to(Vector2(a.global_position.x, a.global_position.z))
		var dist_b := Vector2(global_position.x, global_position.z).distance_to(Vector2(b.global_position.x, b.global_position.z))
		return dist_a < dist_b
	)
	
	var duration := (stats.ability_duration if stats.ability_duration > 0.0 else 3.0) * (1.0 + float(star_level - 1) * 0.25)
	var damage := (stats.ability_damage if stats.ability_damage > 0.0 else 500.0) * stats.get_star_multiplier(star_level)
	var targets_count := mini(maxi(stats.ability_targets, 2), enemies.size())
	for i in targets_count:
		var enemy: BaseUnit3D = enemies[i]
		enemy.take_damage(damage, self, UnitStats.DamageType.MAGICAL)
		enemy.apply_stun(duration, "HIPNOTIZADO")
		CombatFeedback.create_hit_particles(enemy.global_position, Color("#ec4899"))

func _cast_anhanga_roar() -> void:
	if model:
		var tw := create_tween()
		tw.tween_property(model, "scale", model_base_scale * Vector3(1.3, 1.3, 1.3), 0.15).set_trans(Tween.TRANS_QUAD)
		tw.tween_property(model, "scale", model_base_scale, 0.22).set_trans(Tween.TRANS_BOUNCE)
	CombatFeedback.create_status_indicator(self, "RUGIDO DA FLORESTA", 1.2)
	CombatFeedback.create_hit_particles(global_position, Color("#22c55e"))
	
	var duration := stats.ability_duration if stats.ability_duration > 0.0 else 4.0
	var radius := stats.ability_range if stats.ability_range > 0.0 else 3.0
	var weakness_mult := clampf(0.70 - float(star_level - 1) * 0.10, 0.40, 0.70)
	var enemy_group := "enemy_units" if team == 0 else "player_units"
	for enemy in get_tree().get_nodes_in_group(enemy_group):
		if not is_instance_valid(enemy) or enemy.current_state == State.DEAD or not enemy.visible or enemy.is_on_bench():
			continue
		var distance := Vector2(global_position.x, global_position.z).distance_to(Vector2(enemy.global_position.x, enemy.global_position.z))
		if distance <= radius:
			enemy.apply_attack_weakness(duration, weakness_mult)
			CombatFeedback.create_hit_particles(enemy.global_position, Color("#8ee58b"))

func _cast_cabeca_de_cuia() -> void:
	if not is_instance_valid(current_target) or current_target.current_state == State.DEAD or current_target.is_on_bench():
		find_target()
	var target := current_target
	var enemy_group := "enemy_units" if team == 0 else "player_units"
	var enemies: Array = get_tree().get_nodes_in_group(enemy_group).filter(func(unit):
		return is_instance_valid(unit) and unit is BaseUnit3D and unit.current_state != State.DEAD and unit.visible and not unit.is_on_bench()
	)
	if not enemies.is_empty():
		enemies.sort_custom(func(a: BaseUnit3D, b: BaseUnit3D) -> bool:
			var da := Vector2(global_position.x, global_position.z).distance_to(Vector2(a.global_position.x, a.global_position.z))
			var db := Vector2(global_position.x, global_position.z).distance_to(Vector2(b.global_position.x, b.global_position.z))
			return da > db
		)
		target = enemies[0]
		current_target = target
	
	if not is_instance_valid(target) or target.current_state == State.DEAD or target.is_on_bench():
		return

	if model:
		var tw := create_tween()
		tw.tween_property(model, "position:y", 0.6, 0.15).set_trans(Tween.TRANS_QUAD)
		tw.tween_property(model, "position:y", 0.0, 0.2).set_trans(Tween.TRANS_BOUNCE)

	CombatFeedback.create_status_indicator(self, "ARRASTO AMALDIÇOADO", 1.2)
	CombatFeedback.create_hit_particles(global_position, Color("#0284c7"))
	
	var damage := stats.ability_damage * stats.get_star_multiplier(star_level)
	target.take_damage(damage, self, UnitStats.DamageType.MAGICAL)
	
	if is_instance_valid(target) and target.current_state != State.DEAD:
		var shred := 15.0 * stats.get_star_multiplier(star_level)
		target.apply_armor_shred(stats.ability_duration if stats.ability_duration > 0.0 else 4.0, shred)
		
		var pull_dir := (global_position - target.global_position)
		pull_dir.y = 0.0
		if pull_dir.length_squared() > 1.0:
			var pull_dest := global_position - pull_dir.normalized() * 1.3
			pull_dest.y = target.global_position.y
			var ptw := target.create_tween()
			ptw.tween_property(target, "global_position", pull_dest, 0.3).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

		CombatFeedback.create_hit_particles(target.global_position, Color("#0284c7"))
		CombatFeedback.create_hit_particles(target.global_position + Vector3.UP * 0.5, Color("#0f172a"))

func _cast_mae_de_ouro() -> void:
	if model:
		var tw := create_tween()
		tw.tween_property(model, "rotation:y", TAU, 0.4).from(0.0).set_trans(Tween.TRANS_QUAD)
		tw.tween_callback(func() -> void:
			if is_instance_valid(model):
				model.rotation.y = 0.0
			if is_instance_valid(current_target) and current_target.current_state != State.DEAD:
				var offset := current_target.global_position - global_position
				if offset.length_squared() > 0.001:
					rotation.y = atan2(offset.x, offset.z)
		)
	CombatFeedback.create_status_indicator(self, "CHAMAS DOURADAS", 1.2)
	CombatFeedback.create_hit_particles(global_position, Color("#f59e0b"))
	CombatFeedback.create_hit_particles(global_position + Vector3.UP * 0.6, Color("#fbbf24"))

	var damage := stats.ability_damage * stats.get_star_multiplier(star_level)
	var heal_val := stats.ability_heal * stats.get_star_multiplier(star_level)
	
	var enemy_group := "enemy_units" if team == 0 else "player_units"
	var enemies: Array = get_tree().get_nodes_in_group(enemy_group).filter(func(unit):
		return is_instance_valid(unit) and unit is BaseUnit3D and unit.current_state != State.DEAD and unit.visible and not unit.is_on_bench()
	)
	enemies.sort_custom(func(a: BaseUnit3D, b: BaseUnit3D) -> bool:
		var da := Vector2(global_position.x, global_position.z).distance_to(Vector2(a.global_position.x, a.global_position.z))
		var db := Vector2(global_position.x, global_position.z).distance_to(Vector2(b.global_position.x, b.global_position.z))
		return da < db
	)
	var enemy_count := mini(maxi(stats.ability_targets, 3), enemies.size())
	for i in enemy_count:
		var enemy: BaseUnit3D = enemies[i]
		enemy.take_damage(damage, self, UnitStats.DamageType.MAGICAL)
		enemy.apply_burn(2.0, self, damage * 0.1)
		CombatFeedback.create_hit_particles(enemy.global_position, Color("#f59e0b"))

	var ally_group := "player_units" if team == 0 else "enemy_units"
	var allies: Array = get_tree().get_nodes_in_group(ally_group).filter(func(ally):
		return is_instance_valid(ally) and ally is BaseUnit3D and ally.current_state != State.DEAD and ally.visible and not ally.is_on_bench() and ally.current_health < ally.get_max_health()
	)
	allies.sort_custom(func(a: BaseUnit3D, b: BaseUnit3D) -> bool:
		return (a.get_max_health() - a.current_health) > (b.get_max_health() - b.current_health)
	)
	var ally_count := mini(maxi(stats.ability_targets, 3), allies.size())
	for i in ally_count:
		var ally: BaseUnit3D = allies[i]
		var healed := ally.heal(heal_val, self)
		if healed > 0.0:
			CombatFeedback.create_status_indicator(ally, "+%d HP" % int(healed), 1.2)
			CombatFeedback.create_hit_particles(ally.global_position, Color("#fbbf24"))

func _cast_mapinguari() -> void:
	if model:
		var tw := create_tween()
		tw.tween_property(model, "scale", model_base_scale * Vector3(1.35, 0.7, 1.35), 0.14).set_trans(Tween.TRANS_QUAD)
		tw.tween_property(model, "scale", model_base_scale, 0.22).set_trans(Tween.TRANS_BOUNCE)
	CombatFeedback.create_status_indicator(self, "RUGIDO DA FÚRIA", 1.5)
	CombatFeedback.create_hit_particles(global_position, Color("#f97316"))
	CombatFeedback.create_hit_particles(global_position + Vector3.UP * 0.6, Color("#ef4444"))
	_trigger_camera_shake(0.35, 0.3)
	
	var duration := stats.ability_duration if stats.ability_duration > 0.0 else 5.0
	reflect_until_msec = BattleClock.now_msec() + int(duration * 1000.0)
	reflect_pct = 0.40 * (1.0 + float(star_level - 1) * 0.20)
	
	# Auto-buff lendário de Porradeiro (+45% ataque, +35% velocidade de ataque)
	apply_speed_buff(duration, 1.35, "+FÚRIA")
	active_buffs.append({
		"attack_multiplier": 1.45,
		"expires_at_msec": BattleClock.now_msec() + int(duration * 1000.0)
	})
	
	# Dano físico no alvo atual
	var damage := (stats.ability_damage if stats.ability_damage > 0.0 else 350.0) * stats.get_star_multiplier(star_level)
	if is_instance_valid(current_target) and current_target.current_state != State.DEAD and not current_target.is_on_bench():
		current_target.take_damage(damage, self, UnitStats.DamageType.PHYSICAL)
		CombatFeedback.create_hit_particles(current_target.global_position, Color("#ea580c"))

func _cast_matinta_perera() -> void:
	var duration := stats.ability_duration if stats.ability_duration > 0.0 else 3.0
	immune_until_msec = BattleClock.now_msec() + int(duration * 1000.0)
	
	if not is_instance_valid(current_target) or current_target.current_state == State.DEAD or current_target.is_on_bench():
		find_target()
	var target := current_target
	if not is_instance_valid(target) or target.current_state == State.DEAD or target.is_on_bench():
		var enemy_group := "enemy_units" if team == 0 else "player_units"
		var candidates: Array = get_tree().get_nodes_in_group(enemy_group).filter(func(u):
			return is_instance_valid(u) and u is BaseUnit3D and u.current_state != State.DEAD and not u.is_on_bench()
		)
		if not candidates.is_empty():
			target = candidates[0]
			current_target = target

	CombatFeedback.create_status_indicator(self, "FORMA DE PÁSSARO", 1.2)
	CombatFeedback.create_hit_particles(global_position, Color("#7c3aed"))
	CombatFeedback.create_hit_particles(global_position + Vector3.UP * 0.8, Color("#1e1b4b"))
	
	var damage := (stats.ability_damage if stats.ability_damage > 0.0 else 140.0) * stats.get_star_multiplier(star_level)
	
	if is_instance_valid(target):
		target.take_damage(damage, self, UnitStats.DamageType.MAGICAL)
		target.apply_stun(2.5, "CONFUSO")
		CombatFeedback.create_hit_particles(target.global_position, Color("#a855f7"))
		CombatFeedback.create_hit_particles(target.global_position + Vector3.UP * 0.6, Color("#3b0764"))
		_execute_swoop_advance_and_return(target.global_position, Color("#7c3aed"), "CONFUSO")
	
	var radius := stats.ability_range if stats.ability_range > 0.0 else 3.0
	var enemy_grp := "enemy_units" if team == 0 else "player_units"
	for enemy_node: Node in get_tree().get_nodes_in_group(enemy_grp):
		var enemy := enemy_node as BaseUnit3D
		if not is_instance_valid(enemy) or enemy == target or enemy.current_state == State.DEAD or not enemy.visible or enemy.is_on_bench():
			continue
		var dist: float = Vector2(global_position.x, global_position.z).distance_to(Vector2(enemy.global_position.x, enemy.global_position.z))
		if dist <= radius:
			enemy.take_damage(damage * 0.5, self, UnitStats.DamageType.MAGICAL)
			CombatFeedback.create_hit_particles(enemy.global_position, Color("#a855f7"))

func _cast_sabia_laranjeira() -> void:
	if not is_instance_valid(current_target) or current_target.current_state == State.DEAD or current_target.is_on_bench():
		find_target()
	var target := current_target
	if not is_instance_valid(target) or target.current_state == State.DEAD or target.is_on_bench():
		var enemy_group := "enemy_units" if team == 0 else "player_units"
		var candidates: Array = get_tree().get_nodes_in_group(enemy_group).filter(func(u):
			return is_instance_valid(u) and u is BaseUnit3D and u.current_state != State.DEAD and not u.is_on_bench()
		)
		if not candidates.is_empty():
			target = candidates[0]
			current_target = target

	CombatFeedback.create_status_indicator(self, "BICADA", 1.2)
	CombatFeedback.create_hit_particles(global_position, Color("#fb923c"))
	
	var damage := (stats.ability_damage if stats.ability_damage > 0.0 else 95.0) * stats.get_star_multiplier(star_level)
	
	var buff_dur := stats.ability_duration if stats.ability_duration > 0.0 else 4.0
	apply_speed_buff(buff_dur, 1.35, "+VELOCIDADE")
	
	if is_instance_valid(target):
		target.take_damage(damage, self, UnitStats.DamageType.PHYSICAL)
		CombatFeedback.create_hit_particles(target.global_position, Color("#fb923c"))
		CombatFeedback.create_hit_particles(target.global_position + Vector3.UP * 0.5, Color("#ea580c"))
		_execute_swoop_advance_and_return(target.global_position, Color("#fb923c"), "BICADA")

func _execute_swoop_advance_and_return(target_pos: Vector3, trail_color: Color, _action_label: String) -> void:
	if not model:
		return
	_is_swooping = true
	var origin_global: Vector3 = global_position
	var to_target: Vector3 = target_pos - origin_global
	to_target.y = 0.0
	var dist: float = to_target.length()
	var advance_dir: Vector3 = to_target.normalized() if dist > 0.001 else Vector3.FORWARD
	var attack_spot_global: Vector3 = origin_global + advance_dir * maxf(dist - 0.7, 0.0)
	
	if dist > 0.001:
		rotation.y = atan2(advance_dir.x, advance_dir.z)
	
	var tw: Tween = create_tween()
	tw.tween_method(func(prog: float) -> void:
		if is_instance_valid(self) and current_state != State.DEAD:
			global_position = origin_global.lerp(attack_spot_global, prog)
			if model:
				model.position.y = (FLYING_BASE_HEIGHT if is_flying() else 0.0) + sin(prog * PI) * 0.4
	, 0.0, 1.0, 0.20).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	
	tw.tween_callback(func() -> void:
		if is_instance_valid(self):
			CombatFeedback.create_hit_particles(attack_spot_global + Vector3.UP * 0.5, trail_color)
			if model:
				var strike_tw := create_tween()
				strike_tw.tween_property(model, "rotation:x", 0.4, 0.06)
				strike_tw.tween_property(model, "rotation:x", 0.0, 0.06)
	)
	tw.tween_interval(0.12)
	
	tw.tween_method(func(prog: float) -> void:
		if is_instance_valid(self) and current_state != State.DEAD:
			global_position = attack_spot_global.lerp(origin_global, prog)
			if model:
				model.position.y = (FLYING_BASE_HEIGHT if is_flying() else 0.0) + sin(prog * PI) * 0.35
	, 0.0, 1.0, 0.24).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
	
	tw.tween_callback(func() -> void:
		if is_instance_valid(self):
			global_position = origin_global
			_is_swooping = false
			if is_flying() and model:
				model.position.y = FLYING_BASE_HEIGHT
	)

func _cast_minhocao_earthquake() -> void:
	_trigger_camera_shake(0.55, 0.65)
	
	if model:
		var tw := create_tween()
		tw.tween_property(model, "position:y", -0.35, 0.12)
		tw.tween_property(model, "position:y", 0.5, 0.15)
		tw.tween_property(model, "position:y", 0.0, 0.15).set_trans(Tween.TRANS_BOUNCE)
	
	CombatFeedback.create_status_indicator(self, "TERREMOTO", 1.2)
	CombatFeedback.create_hit_particles(global_position, Color("#78350f"))
	CombatFeedback.create_hit_particles(global_position + Vector3.UP * 0.3, Color("#d97706"))
	
	var radius := stats.ability_range if stats.ability_range > 0.0 else 3.5
	var damage := stats.ability_damage * stats.get_star_multiplier(star_level)
	var stun_dur := stats.ability_duration if stats.ability_duration > 0.0 else 2.0
	_create_minhocao_crater_element(global_position, radius, stun_dur + 1.2)
	var enemy_group := "enemy_units" if team == 0 else "player_units"
	for enemy in get_tree().get_nodes_in_group(enemy_group):
		if not is_instance_valid(enemy) or enemy.current_state == State.DEAD or not enemy.visible or enemy.is_on_bench():
			continue
		var distance := Vector2(global_position.x, global_position.z).distance_to(Vector2(enemy.global_position.x, enemy.global_position.z))
		if distance <= radius:
			enemy.take_damage(damage, self, UnitStats.DamageType.PHYSICAL)
			enemy.apply_stun(stun_dur, "ATORDOADO")
			CombatFeedback.create_hit_particles(enemy.global_position, Color("#b45309"))

func _cast_quibungo_sack() -> void:
	if not is_instance_valid(current_target) or current_target.current_state == State.DEAD or current_target.is_on_bench():
		find_target()
	var target := current_target
	if not is_instance_valid(target) or target.current_state == State.DEAD or target.is_on_bench():
		return

	if model:
		var tw := create_tween()
		tw.tween_property(model, "scale", model_base_scale * Vector3(1.2, 1.25, 1.2), 0.15)
		tw.tween_property(model, "scale", model_base_scale, 0.2)

	CombatFeedback.create_status_indicator(self, "SACO DAS SOMBRAS", 1.2)
	CombatFeedback.create_hit_particles(target.global_position, Color("#581c87"))
	
	var duration := stats.ability_duration if stats.ability_duration > 0.0 else 3.0
	target.apply_stun(duration, "PRESO NO SACO")
	
	var tick_damage := stats.ability_damage * stats.get_star_multiplier(star_level)
	target.take_damage(tick_damage, self, UnitStats.DamageType.TRUE)
	CombatFeedback.create_hit_particles(target.global_position, Color("#3b0764"))
	
	_run_quibungo_sack_ticks(target, duration, tick_damage)

func _run_quibungo_sack_ticks(target: BaseUnit3D, duration: float, tick_damage: float) -> void:
	var elapsed := 1.0
	while elapsed < duration:
		await get_tree().create_timer(1.0, false).timeout
		elapsed += 1.0
		if not is_instance_valid(target) or target.current_state == State.DEAD:
			break
		target.take_damage(tick_damage, self, UnitStats.DamageType.TRUE)
		CombatFeedback.create_hit_particles(target.global_position, Color("#3b0764"))

func _cast_papa_figo() -> void:
	if not is_instance_valid(current_target) or current_target.current_state == State.DEAD or current_target.is_on_bench():
		find_target()
	var target := current_target
	if is_instance_valid(target) and not target.is_queued_for_deletion() and target.current_state != State.DEAD and not target.is_on_bench():
		var impact_position := target.global_position
		var damage := stats.ability_damage * stats.get_star_multiplier(star_level)
		target.take_damage(damage, self, stats.ability_damage_type)
		if is_instance_valid(target) and not target.is_queued_for_deletion() and target.current_state != State.DEAD:
			target.apply_attack_weakness(stats.ability_duration if stats.ability_duration > 0.0 else 5.0, 0.75)
		CombatFeedback.create_hit_particles(impact_position, Color("#67e8f9"))
		CombatFeedback.create_status_indicator(self, "TOQUE GÉLIDO", 1.2)
	_apply_ability_healing()

func _cast_teiniagua_orb() -> void:
	if not is_instance_valid(current_target) or current_target.current_state == State.DEAD or current_target.is_on_bench():
		find_target()
	var target := current_target
	if not is_instance_valid(target) or target.current_state == State.DEAD or target.is_on_bench():
		return
	
	if model:
		var tw := create_tween()
		tw.tween_property(model, "scale", model_base_scale * Vector3(1.2, 1.2, 1.2), 0.15).set_trans(Tween.TRANS_QUAD)
		tw.tween_property(model, "scale", model_base_scale, 0.2).set_trans(Tween.TRANS_BOUNCE)

	CombatFeedback.create_status_indicator(self, "ESFERA ARCANA", 1.2)
	
	var target_position := target.global_position
	var enemy_group := "enemy_units" if team == 0 else "player_units"
	var enemies: Array = get_tree().get_nodes_in_group(enemy_group)
	var damage := stats.ability_damage * stats.get_star_multiplier(star_level)
	var board := _get_combat_board()
	if board:
		var target_cell := board.get_grid_position(board.to_local(target.global_position))
		var affected_cells: Array[Vector2i] = [target_cell]
		if target_cell != Vector2i(-1, -1):
			affected_cells.append_array(board.get_neighbors(target_cell))
		for enemy in enemies:
			if not is_instance_valid(enemy) or enemy.current_state == State.DEAD or not enemy.visible or enemy.is_on_bench():
				continue
			var enemy_cell := board.get_grid_position(board.to_local(enemy.global_position))
			if enemy_cell in affected_cells:
				enemy.take_damage(damage, self, stats.ability_damage_type)
	else:
		for enemy in enemies:
			if not is_instance_valid(enemy) or enemy.current_state == State.DEAD or not enemy.visible or enemy.is_on_bench():
				continue
			var distance := Vector2(target_position.x, target_position.z).distance_to(Vector2(enemy.global_position.x, enemy.global_position.z))
			if distance <= 2.8:
				enemy.take_damage(damage, self, stats.ability_damage_type)
	
	var target_impact := target.global_position + Vector3.UP * 0.7
	_spawn_ballistic_projectile(
		global_position + Vector3.UP * 1.1,
		target,
		target_impact,
		Color("#c084fc"),
		1.8,
		0.40,
		Callable(),
		"TeiniaguaArcaneOrb",
		0.24
	)
	CombatFeedback.create_hit_particles(target_position, Color("#c994ff"))
	CombatFeedback.create_hit_particles(target_position + Vector3.UP * 0.5, Color("#f43f5e"))

# ==============================================================================
# HABILIDADES ESPECÍFICAS - CUSTO 4
# ==============================================================================

func _cast_araucaria_canopy() -> void:
	if model:
		var tw := create_tween()
		tw.tween_property(model, "scale", model_base_scale * Vector3(1.22, 1.3, 1.22), 0.16).set_trans(Tween.TRANS_QUAD)
		tw.tween_property(model, "scale", model_base_scale, 0.22).set_trans(Tween.TRANS_BOUNCE)
	CombatFeedback.create_status_indicator(self, "COPA PROTETORA", 1.2)
	CombatFeedback.create_hit_particles(global_position, Color("#15803d"))
	CombatFeedback.create_hit_particles(global_position + Vector3.UP * 0.8, Color("#854d0e"))
	
	var shield_amount := (stats.ability_shield if stats.ability_shield > 0.0 else 260.0) * stats.get_star_multiplier(star_level)
	shield_amount *= 1.0 + float(synergy_bonuses.get("shield_power_pct", 0.0))
	set_shield_with_source(maxf(current_shield, shield_amount), ShieldSource.SELF)
	
	var radius := stats.ability_range if stats.ability_range > 0.0 else 3.0
	_create_araucaria_canopy_element(global_position, radius, 4.0)
	var ally_group := "player_units" if team == 0 else "enemy_units"
	for ally_node: Node in get_tree().get_nodes_in_group(ally_group):
		var ally := ally_node as BaseUnit3D
		if not is_instance_valid(ally) or ally == self or ally.current_state == State.DEAD or not ally.visible or ally.is_on_bench():
			continue
		var dist: float = Vector2(global_position.x, global_position.z).distance_to(Vector2(ally.global_position.x, ally.global_position.z))
		if dist <= radius:
			var ally_shield := shield_amount * 0.85
			ally.set_shield_with_source(maxf(ally.current_shield, ally_shield), ShieldSource.PLAYER if team == 0 else ShieldSource.ENEMY)
			CombatFeedback.create_hit_particles(ally.global_position, Color("#15803d"))
			CombatFeedback.create_status_indicator(ally, "COPA PROTETORA", 1.2)

func _cast_caapora_piercing_arrow() -> void:
	if not is_instance_valid(current_target) or current_target.current_state == State.DEAD or current_target.is_on_bench():
		find_target()
	var target := current_target
	if not is_instance_valid(target) or target.current_state == State.DEAD or target.is_on_bench():
		return
	
	_face_target()
	CombatFeedback.create_status_indicator(self, "FLECHA PERFURANTE", 1.2)
	CombatFeedback.create_hit_particles(global_position, Color("#10b981"))
	
	var aim_dir := (target.global_position - global_position)
	aim_dir.y = 0.0
	if aim_dir.length_squared() < 0.01:
		aim_dir = Vector3.FORWARD
	else:
		aim_dir = aim_dir.normalized()
	
	var max_range := stats.ability_range if stats.ability_range > 0.0 else 6.0
	var damage := stats.ability_damage * stats.get_star_multiplier(star_level)
	var shred := 20.0 * stats.get_star_multiplier(star_level)
	var duration := stats.ability_duration if stats.ability_duration > 0.0 else 4.0
	
	_spawn_piercing_arrow_visual(global_position + Vector3.UP * 0.6, aim_dir, max_range)
	
	var enemy_group := "enemy_units" if team == 0 else "player_units"
	var enemies: Array = get_tree().get_nodes_in_group(enemy_group).filter(func(unit):
		return is_instance_valid(unit) and unit is BaseUnit3D and unit.current_state != State.DEAD and unit.visible and not unit.is_on_bench()
	)
	
	var hit_count := 0
	var max_targets := stats.ability_targets if stats.ability_targets > 0 else 5
	enemies.sort_custom(func(a: BaseUnit3D, b: BaseUnit3D) -> bool:
		var da := (a.global_position - global_position).dot(aim_dir)
		var db := (b.global_position - global_position).dot(aim_dir)
		return da < db
	)
	
	for enemy: BaseUnit3D in enemies:
		if hit_count >= max_targets:
			break
		var to_enemy: Vector3 = enemy.global_position - global_position
		to_enemy.y = 0.0
		var proj_dist: float = to_enemy.dot(aim_dir)
		if proj_dist >= 0.0 and proj_dist <= max_range:
			var lateral_offset: float = (to_enemy - aim_dir * proj_dist).length()
			if lateral_offset <= 1.35:
				enemy.take_damage(damage, self, stats.ability_damage_type)
				if hit_count == 0:
					enemy.apply_armor_shred(duration, shred)
				CombatFeedback.create_hit_particles(enemy.global_position, Color("#10b981"))
				CombatFeedback.create_hit_particles(enemy.global_position + Vector3.UP * 0.5, Color("#34d399"))
				hit_count += 1

func _spawn_piercing_arrow_visual(start_pos: Vector3, dir: Vector3, distance: float) -> void:
	var arrow := Node3D.new()
	arrow.name = "CaaporaArrow"
	var mesh_inst := MeshInstance3D.new()
	var cyl := CylinderMesh.new()
	cyl.top_radius = 0.04
	cyl.bottom_radius = 0.08
	cyl.height = 0.9
	mesh_inst.mesh = cyl
	mesh_inst.rotation.x = PI * 0.5
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color("#34d399")
	mat.emission_enabled = true
	mat.emission = Color("#10b981")
	mat.emission_energy_multiplier = 3.0
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mesh_inst.material_override = mat
	arrow.add_child(mesh_inst)
	
	var scene_root := get_tree().current_scene
	if scene_root:
		scene_root.add_child(arrow)
	else:
		get_parent().add_child(arrow)
	
	arrow.global_position = start_pos
	if dir.length_squared() > 0.01:
		arrow.look_at(start_pos + dir, Vector3.UP)
	var end_pos := start_pos + dir * distance
	var tw := arrow.create_tween()
	tw.tween_property(arrow, "global_position", end_pos, 0.28).set_trans(Tween.TRANS_LINEAR)
	tw.tween_callback(arrow.queue_free)

func _cast_comadre_fulozinha() -> void:
	if model:
		var tw := create_tween()
		tw.tween_property(model, "rotation:y", TAU, 0.4).from(0.0).set_trans(Tween.TRANS_QUAD)
		tw.tween_callback(func() -> void:
			if is_instance_valid(model):
				model.rotation.y = 0.0
			if is_instance_valid(current_target) and current_target.current_state != State.DEAD:
				var offset := current_target.global_position - global_position
				if offset.length_squared() > 0.001:
					rotation.y = atan2(offset.x, offset.z)
		)
	CombatFeedback.create_status_indicator(self, "INVOCAÇÃO DA FLORESTA", 1.2)
	CombatFeedback.create_hit_particles(global_position, Color("#22c55e"))
	CombatFeedback.create_hit_particles(global_position + Vector3.UP * 0.8, Color("#f472b6"))
	
	var duration := stats.ability_duration if stats.ability_duration > 0.0 else 10.0
	var damage := (stats.ability_damage if stats.ability_damage > 0.0 else 45.0) * stats.get_star_multiplier(star_level)
	var heal_val := (stats.ability_heal if stats.ability_heal > 0.0 else 35.0) * stats.get_star_multiplier(star_level)
	
	_spawn_forest_spirits(duration, damage, heal_val)

func _spawn_forest_spirits(duration: float, strike_damage: float, heal_val: float) -> void:
	var root_node := get_parent()
	if not root_node:
		root_node = self
	
	var spirits_container := Node3D.new()
	spirits_container.name = "ComadreSpirits"
	root_node.add_child(spirits_container)
	spirits_container.global_position = global_position
	
	var spirit_nodes: Array[Node3D] = []
	var colors := [Color("#22c55e"), Color("#facc15")]
	for i in range(2):
		var sp := MeshInstance3D.new()
		var s_mesh := SphereMesh.new()
		s_mesh.radius = 0.2
		s_mesh.height = 0.4
		sp.mesh = s_mesh
		var s_mat := StandardMaterial3D.new()
		s_mat.albedo_color = colors[i]
		s_mat.emission_enabled = true
		s_mat.emission = colors[i]
		s_mat.emission_energy_multiplier = 2.5
		s_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		sp.material_override = s_mat
		spirits_container.add_child(sp)
		sp.position = Vector3(cos(i * PI) * 1.2, 0.8, sin(i * PI) * 1.2)
		spirit_nodes.append(sp)
	
	_run_forest_spirits_behavior(spirits_container, spirit_nodes, duration, strike_damage, heal_val)

func _run_forest_spirits_behavior(container: Node3D, spirits: Array[Node3D], duration: float, damage: float, heal_amount: float) -> void:
	var elapsed := 0.0
	var tick_interval := 1.0
	while elapsed < duration and is_instance_valid(container) and current_state != State.DEAD:
		await get_tree().create_timer(tick_interval, false).timeout
		elapsed += tick_interval
		if not is_instance_valid(container) or current_state == State.DEAD:
			break
		
		container.global_position = global_position
		
		var enemy_group := "enemy_units" if team == 0 else "player_units"
		var enemies: Array = get_tree().get_nodes_in_group(enemy_group).filter(func(u):
			return is_instance_valid(u) and u is BaseUnit3D and u.current_state != State.DEAD and u.visible and not u.is_on_bench()
		)
		if not enemies.is_empty():
			enemies.sort_custom(func(a: BaseUnit3D, b: BaseUnit3D) -> bool:
				return global_position.distance_to(a.global_position) < global_position.distance_to(b.global_position)
			)
			var target_enemy: BaseUnit3D = enemies[0]
			target_enemy.take_damage(damage, self, UnitStats.DamageType.MAGICAL)
			CombatFeedback.create_hit_particles(target_enemy.global_position, Color("#22c55e"))
			if spirits.size() > 0 and is_instance_valid(spirits[0]):
				var tw := spirits[0].create_tween()
				tw.tween_property(spirits[0], "position:y", 1.4, 0.15)
				tw.tween_property(spirits[0], "position:y", 0.8, 0.2)
		
		var ally_group := "player_units" if team == 0 else "enemy_units"
		var wounded_allies: Array = get_tree().get_nodes_in_group(ally_group).filter(func(a):
			return is_instance_valid(a) and a is BaseUnit3D and a.current_state != State.DEAD and a.visible and not a.is_on_bench() and a.current_health < a.get_max_health()
		)
		if not wounded_allies.is_empty():
			wounded_allies.sort_custom(func(a: BaseUnit3D, b: BaseUnit3D) -> bool:
				return (a.get_max_health() - a.current_health) > (b.get_max_health() - b.current_health)
			)
			var ally_target: BaseUnit3D = wounded_allies[0]
			var healed := ally_target.heal(heal_amount, self)
			if healed > 0.0:
				CombatFeedback.create_status_indicator(ally_target, "+%d HP" % int(healed), 1.0)
				CombatFeedback.create_hit_particles(ally_target.global_position, Color("#facc15"))
		elif not enemies.is_empty():
			var second_enemy: BaseUnit3D = enemies[mini(1, enemies.size() - 1)]
			second_enemy.take_damage(damage, self, UnitStats.DamageType.MAGICAL)
			CombatFeedback.create_hit_particles(second_enemy.global_position, Color("#facc15"))
	
	if is_instance_valid(container):
		CombatFeedback.create_hit_particles(container.global_position + Vector3.UP * 0.8, Color("#f472b6"))
		container.queue_free()

func _cast_corpo_seco_drain() -> void:
	if model:
		var tw := create_tween()
		tw.tween_property(model, "scale", model_base_scale * Vector3(1.15, 1.25, 1.15), 0.15).set_trans(Tween.TRANS_QUAD)
		tw.tween_property(model, "scale", model_base_scale, 0.2).set_trans(Tween.TRANS_BOUNCE)
	CombatFeedback.create_status_indicator(self, "DRENAGEM VITAL", 1.2)
	CombatFeedback.create_hit_particles(global_position, Color("#15803d"))
	CombatFeedback.create_hit_particles(global_position + Vector3.UP * 0.6, Color("#581c87"))
	
	var duration := stats.ability_duration if stats.ability_duration > 0.0 else 4.0
	var total_damage := (stats.ability_damage if stats.ability_damage > 0.0 else 120.0) * stats.get_star_multiplier(star_level)
	var total_heal := (stats.ability_heal if stats.ability_heal > 0.0 else 80.0) * stats.get_star_multiplier(star_level)
	var radius := stats.ability_range if stats.ability_range > 0.0 else 2.5
	
	_run_corpo_seco_drain_pulses(duration, total_damage / 4.0, total_heal / 4.0, radius)

func _run_corpo_seco_drain_pulses(duration: float, tick_damage: float, tick_heal: float, radius: float) -> void:
	var pulses := int(duration)
	for p in range(pulses):
		await get_tree().create_timer(1.0, false).timeout
		if current_state == State.DEAD:
			break
		var enemy_group := "enemy_units" if team == 0 else "player_units"
		var drained_count := 0
		for enemy_node: Node in get_tree().get_nodes_in_group(enemy_group):
			var enemy := enemy_node as BaseUnit3D
			if not is_instance_valid(enemy) or enemy.current_state == State.DEAD or not enemy.visible or enemy.is_on_bench():
				continue
			var dist: float = Vector2(global_position.x, global_position.z).distance_to(Vector2(enemy.global_position.x, enemy.global_position.z))
			if dist <= radius:
				enemy.take_damage(tick_damage, self, UnitStats.DamageType.TRUE)
				enemy.apply_slow(1.5)
				CombatFeedback.create_hit_particles(enemy.global_position, Color("#581c87"))
				drained_count += 1
		
		if drained_count > 0:
			var healed: float = heal(tick_heal * float(drained_count), self)
			if healed > 0.0:
				CombatFeedback.create_status_indicator(self, "+%d HP" % int(healed), 0.8)
				CombatFeedback.create_hit_particles(global_position, Color("#22c55e"))

func _cast_mboi_guacu_constriction() -> void:
	if not is_instance_valid(current_target) or current_target.current_state == State.DEAD or current_target.is_on_bench():
		find_target()
	var target := current_target
	if not is_instance_valid(target) or target.current_state == State.DEAD or target.is_on_bench():
		return
	
	if model:
		var tw := create_tween()
		tw.tween_property(model, "scale", model_base_scale * Vector3(1.3, 0.75, 1.3), 0.15).set_trans(Tween.TRANS_QUAD)
		tw.tween_property(model, "scale", model_base_scale, 0.22).set_trans(Tween.TRANS_BOUNCE)
	CombatFeedback.create_status_indicator(self, "CONSTRIÇÃO MORTAL", 1.2)
	CombatFeedback.create_hit_particles(global_position, Color("#0284c7"))
	
	var duration := stats.ability_duration if stats.ability_duration > 0.0 else 4.0
	var tick_damage := (stats.ability_damage if stats.ability_damage > 0.0 else 40.0) * stats.get_star_multiplier(star_level)
	var shield_amount := (stats.ability_shield if stats.ability_shield > 0.0 else 160.0) * stats.get_star_multiplier(star_level)
	current_shield = maxf(current_shield, shield_amount)
	
	target.apply_stun(duration, "CONSTRITO")
	target.apply_armor_shred(duration, 25.0)
	_create_mboi_guacu_coil_element(target, duration)
	
	_run_mboi_guacu_constriction_ticks(target, duration, tick_damage)

func _run_mboi_guacu_constriction_ticks(target: BaseUnit3D, duration: float, tick_damage: float) -> void:
	var elapsed := 0.0
	while elapsed < duration and is_instance_valid(target) and target.current_state != State.DEAD and current_state != State.DEAD:
		target.take_damage(tick_damage, self, UnitStats.DamageType.PHYSICAL)
		CombatFeedback.create_hit_particles(target.global_position, Color("#0284c7"))
		CombatFeedback.create_hit_particles(target.global_position + Vector3.UP * 0.4, Color("#166534"))
		await get_tree().create_timer(1.0, false).timeout
		elapsed += 1.0

func _cast_onca_ambush() -> void:
	var enemy_group := "enemy_units" if team == 0 else "player_units"
	var enemies: Array = get_tree().get_nodes_in_group(enemy_group).filter(func(unit):
		return is_instance_valid(unit) and unit is BaseUnit3D and unit.current_state != State.DEAD and unit.visible and not unit.is_on_bench()
	)
	if enemies.is_empty():
		return
	
	enemies.sort_custom(func(a: BaseUnit3D, b: BaseUnit3D) -> bool:
		return a.current_health < b.current_health
	)
	var target: BaseUnit3D = enemies[0]
	
	CombatFeedback.create_hit_particles(global_position, Color("#f59e0b"))
	CombatFeedback.create_hit_particles(global_position + Vector3.UP * 0.5, Color("#b45309"))
	
	var board := _get_combat_board()
	var landing_pos: Vector3 = target.global_position
	var found_cell := false
	if board:
		var target_cell := board.get_grid_position(board.to_local(target.global_position))
		if target_cell != Vector2i(-1, -1):
			var neighbors := board.get_neighbors(target_cell)
			var empty_neighbors: Array[Vector2i] = []
			for n in neighbors:
				if not board.is_cell_occupied(n):
					empty_neighbors.append(n)
			var chosen_cell := Vector2i(-1, -1)
			if not empty_neighbors.is_empty():
				chosen_cell = empty_neighbors[0]
			elif not neighbors.is_empty():
				chosen_cell = neighbors[0]
			if chosen_cell != Vector2i(-1, -1):
				landing_pos = board.get_cell_world_position(chosen_cell)
				found_cell = true
	if not found_cell:
		var offset := (global_position - target.global_position)
		offset.y = 0.0
		if offset.length_squared() < 0.04:
			offset = Vector3.BACK
		landing_pos = target.global_position + offset.normalized() * 1.3
	
	landing_pos.y = combat_ground_height
	global_position = landing_pos
	
	_face_target()
	CombatFeedback.create_status_indicator(self, "BOTE DE EMBOSCADA", 1.2)
	CombatFeedback.create_hit_particles(global_position, Color("#f59e0b"))
	CombatFeedback.create_hit_particles(global_position + Vector3.UP * 0.6, Color("#dc2626"))
	
	var damage := stats.ability_damage * stats.get_star_multiplier(star_level)
	CombatFeedback.create_damage_number(target.global_position, damage, CombatFeedback.DamageType.CRITICAL)
	target.take_damage(damage, self, UnitStats.DamageType.PHYSICAL)
	
	if is_instance_valid(target) and target.current_state != State.DEAD:
		target.apply_burn(3.0, self, damage * 0.12)
		target.apply_stun(1.0, "ATORDOADO")
		current_target = target
	else:
		current_target = null
		find_target()

func _cast_pau_brasil_bloom() -> void:
	if model:
		var tw := create_tween()
		tw.tween_property(model, "scale", model_base_scale * Vector3(1.2, 1.25, 1.2), 0.15).set_trans(Tween.TRANS_QUAD)
		tw.tween_property(model, "scale", model_base_scale, 0.22).set_trans(Tween.TRANS_BOUNCE)
	CombatFeedback.create_status_indicator(self, "FLORADA DOURADA", 1.2)
	CombatFeedback.create_hit_particles(global_position, Color("#fbbf24"))
	CombatFeedback.create_hit_particles(global_position + Vector3.UP * 0.8, Color("#dc2626"))
	
	var radius := stats.ability_range if stats.ability_range > 0.0 else 3.0
	var duration := stats.ability_duration if stats.ability_duration > 0.0 else 4.0
	var damage := stats.ability_damage * stats.get_star_multiplier(star_level)
	var shield_val := (stats.ability_shield if stats.ability_shield > 0.0 else 170.0) * stats.get_star_multiplier(star_level)
	_create_pau_brasil_bloom_element(global_position, radius, duration)
	
	var enemy_group := "enemy_units" if team == 0 else "player_units"
	for enemy_node: Node in get_tree().get_nodes_in_group(enemy_group):
		var enemy := enemy_node as BaseUnit3D
		if not is_instance_valid(enemy) or enemy.current_state == State.DEAD or not enemy.visible or enemy.is_on_bench():
			continue
		var dist: float = Vector2(global_position.x, global_position.z).distance_to(Vector2(enemy.global_position.x, enemy.global_position.z))
		if dist <= radius:
			enemy.take_damage(damage, self, stats.ability_damage_type)
			enemy.apply_attack_weakness(duration, 0.70)
			CombatFeedback.create_hit_particles(enemy.global_position, Color("#fbbf24"))
	
	var ally_group := "player_units" if team == 0 else "enemy_units"
	for ally_node: Node in get_tree().get_nodes_in_group(ally_group):
		var ally := ally_node as BaseUnit3D
		if not is_instance_valid(ally) or ally.current_state == State.DEAD or not ally.visible or ally.is_on_bench():
			continue
		var dist: float = Vector2(global_position.x, global_position.z).distance_to(Vector2(ally.global_position.x, ally.global_position.z))
		if dist <= radius:
			ally.current_shield = maxf(ally.current_shield, shield_val)
			CombatFeedback.create_status_indicator(ally, "FLORADA", 1.2)
			CombatFeedback.create_hit_particles(ally.global_position, Color("#fbbf24"))

func _cast_pisadeira_terror() -> void:
	var enemy_group := "enemy_units" if team == 0 else "player_units"
	var enemies: Array = get_tree().get_nodes_in_group(enemy_group).filter(func(unit):
		return is_instance_valid(unit) and unit is BaseUnit3D and unit.current_state != State.DEAD and unit.visible and not unit.is_on_bench()
	)
	if enemies.is_empty():
		return

	enemies.sort_custom(func(a: BaseUnit3D, b: BaseUnit3D) -> bool:
		return a.current_health < b.current_health
	)
	var target: BaseUnit3D = enemies[0]
	current_target = target

	_trigger_camera_shake(0.4, 0.5)
	if model:
		var tw := create_tween()
		tw.tween_property(model, "position:y", 0.9, 0.12).set_trans(Tween.TRANS_QUAD)
		tw.tween_property(model, "position:y", 0.0, 0.18).set_trans(Tween.TRANS_BOUNCE)
	CombatFeedback.create_status_indicator(self, "PISADA FATAL", 1.2)
	CombatFeedback.create_hit_particles(global_position, Color("#7e22ce"))
	CombatFeedback.create_hit_particles(global_position + Vector3.UP * 0.7, Color("#0f172a"))
	
	var radius := stats.ability_range if stats.ability_range > 0.0 else 3.5
	var base_dur := stats.ability_duration if stats.ability_duration > 0.0 else 2.5
	var duration := base_dur * (1.0 + float(star_level - 1) * 0.20)
	var damage := (stats.ability_damage if stats.ability_damage > 0.0 else 520.0) * stats.get_star_multiplier(star_level)
	
	target.apply_stun(duration, "ESMAGADO")
	target.take_damage(damage, self, stats.ability_damage_type)
	CombatFeedback.create_hit_particles(target.global_position, Color("#7e22ce"))

	for enemy_node: Node in get_tree().get_nodes_in_group(enemy_group):
		var enemy := enemy_node as BaseUnit3D
		if not is_instance_valid(enemy) or enemy == target or enemy.current_state == State.DEAD or not enemy.visible or enemy.is_on_bench():
			continue
		var dist: float = Vector2(global_position.x, global_position.z).distance_to(Vector2(enemy.global_position.x, enemy.global_position.z))
		if dist <= radius:
			enemy.apply_stun(duration * 0.6, "PARALISADO")
			enemy.take_damage(damage * 0.35, self, stats.ability_damage_type)
			enemy.current_mana = maxf(enemy.current_mana - 25.0, 0.0)
			enemy.update_mana_bar()
			CombatFeedback.create_hit_particles(enemy.global_position, Color("#7e22ce"))
			CombatFeedback.create_hit_particles(enemy.global_position + Vector3.UP * 0.6, Color("#3b0764"))

func _cast_sumauma_roots() -> void:
	_trigger_camera_shake(0.45, 0.55)
	if model:
		var tw := create_tween()
		tw.tween_property(model, "scale", model_base_scale * Vector3(1.25, 0.75, 1.25), 0.15).set_trans(Tween.TRANS_QUAD)
		tw.tween_property(model, "scale", model_base_scale, 0.22).set_trans(Tween.TRANS_BOUNCE)
	CombatFeedback.create_status_indicator(self, "RAÍZES GUARDIÃS", 1.2)
	CombatFeedback.create_hit_particles(global_position, Color("#16a34a"))
	CombatFeedback.create_hit_particles(global_position + Vector3.UP * 0.8, Color("#78350f"))
	
	var radius := stats.ability_range if stats.ability_range > 0.0 else 4.0
	var duration := stats.ability_duration if stats.ability_duration > 0.0 else 3.0
	var damage := stats.ability_damage * stats.get_star_multiplier(star_level)
	var heal_val := stats.ability_heal * stats.get_star_multiplier(star_level)
	var shield_val := (stats.ability_shield if stats.ability_shield > 0.0 else 180.0) * stats.get_star_multiplier(star_level)
	_create_sumauma_roots_element(global_position, radius, duration)
	
	var enemy_group := "enemy_units" if team == 0 else "player_units"
	for enemy_node: Node in get_tree().get_nodes_in_group(enemy_group):
		var enemy := enemy_node as BaseUnit3D
		if not is_instance_valid(enemy) or enemy.current_state == State.DEAD or not enemy.visible or enemy.is_on_bench():
			continue
		var dist: float = Vector2(global_position.x, global_position.z).distance_to(Vector2(enemy.global_position.x, enemy.global_position.z))
		if dist <= radius:
			enemy.apply_stun(duration, "ENRAIZADO")
			enemy.take_damage(damage, self, UnitStats.DamageType.PHYSICAL)
			CombatFeedback.create_hit_particles(enemy.global_position, Color("#15803d"))
			CombatFeedback.create_hit_particles(enemy.global_position + Vector3.UP * 0.4, Color("#78350f"))
	
	var ally_group := "player_units" if team == 0 else "enemy_units"
	for ally_node: Node in get_tree().get_nodes_in_group(ally_group):
		var ally := ally_node as BaseUnit3D
		if not is_instance_valid(ally) or ally.current_state == State.DEAD or not ally.visible or ally.is_on_bench():
			continue
		var dist: float = Vector2(global_position.x, global_position.z).distance_to(Vector2(ally.global_position.x, ally.global_position.z))
		if dist <= radius:
			var healed: float = ally.heal(heal_val, self)
			ally.current_shield = maxf(ally.current_shield, shield_val)
			if healed > 0.0:
				CombatFeedback.create_status_indicator(ally, "+%d HP" % int(healed), 1.2)
			CombatFeedback.create_hit_particles(ally.global_position, Color("#22c55e"))

func _apply_ability_damage() -> void:
	if stats.ability_damage <= 0.0:
		return
	
	if stats.unit_id == "arara_azul_lear":
		var enemy_group := "enemy_units" if team == 0 else "player_units"
		var candidates: Array = get_tree().get_nodes_in_group(enemy_group).filter(func(unit):
			return is_instance_valid(unit) and unit is BaseUnit3D and unit.current_state != State.DEAD and unit.visible and not unit.is_on_bench()
		)
		if not candidates.is_empty():
			candidates.sort_custom(func(a: BaseUnit3D, b: BaseUnit3D) -> bool:
				return a.get_attack_damage() > b.get_attack_damage()
			)
			current_target = candidates[0]
	
	if not is_instance_valid(current_target) or current_target.current_state == State.DEAD or current_target.is_on_bench():
		find_target()
	if not is_instance_valid(current_target) or current_target.current_state == State.DEAD or current_target.is_on_bench():
		return
	
	var damage := stats.ability_damage * stats.get_star_multiplier(star_level) * get_ability_power_multiplier()
	
	if stats.unit_id == "pequi":
		var pequi_color := Color("#a3e635")
		_spawn_ballistic_projectile(
			global_position + Vector3.UP * 0.9,
			current_target,
			current_target.global_position + Vector3.UP * 0.7,
			pequi_color,
			1.4,
			0.30,
			Callable(),
			"PequiSeedBurst",
			0.20
		)
		CombatFeedback.create_hit_particles(current_target.global_position, pequi_color)
	elif stats.unit_id == "sabia_laranjeira":
		CombatFeedback.create_hit_particles(current_target.global_position, Color("#fb923c"))
	elif stats.unit_id == "mandacaru":
		CombatFeedback.create_hit_particles(current_target.global_position, Color("#84cc16"))
	elif stats.unit_id == "arara_azul_lear":
		if model:
			var tw := create_tween()
			tw.tween_property(model, "position:y", (FLYING_BASE_HEIGHT + 0.35 if is_flying() else 0.55), 0.14).set_trans(Tween.TRANS_QUAD)
			tw.tween_property(model, "position:y", (FLYING_BASE_HEIGHT if is_flying() else 0.0), 0.18).set_trans(Tween.TRANS_BOUNCE)
		var arara_color := Color("#0284c7")
		_spawn_ballistic_projectile(
			global_position + Vector3.UP * (1.1 if is_flying() else 0.8),
			current_target,
			current_target.global_position + Vector3.UP * 0.7,
			arara_color,
			0.8,
			0.24,
			Callable(),
			"AraraLearSonicFeather",
			0.18,
			true
		)
		CombatFeedback.create_hit_particles(current_target.global_position, arara_color)
		CombatFeedback.create_hit_particles(current_target.global_position + Vector3(0, 0.4, 0), Color("#38bdf8"))
		CombatFeedback.create_status_indicator(self, "VOO DE LEAR", 1.2)
	elif stats.unit_id == "caranguejo_uca":
		CombatFeedback.create_hit_particles(current_target.global_position, Color("#0284c7"))
	elif stats.unit_id == "tamandua_bandeira":
		CombatFeedback.create_hit_particles(current_target.global_position, Color("#d97706"))
	else:
		CombatFeedback.create_hit_particles(current_target.global_position, stats.get_tier_color())

	current_target.take_damage(damage, self, stats.ability_damage_type)

func _cast_cumacanga_fireball() -> void:
	var enemy_group := "enemy_units" if team == 0 else "player_units"
	var enemies: Array = get_tree().get_nodes_in_group(enemy_group).filter(func(unit):
		return is_instance_valid(unit) and unit is BaseUnit3D and unit.current_state != State.DEAD and unit.visible and not unit.is_on_bench()
	)
	if enemies.is_empty():
		return

	# Mira no maior conjunto de unidades inimigas
	var best_target: BaseUnit3D = enemies[0]
	var max_cluster_size: int = -1
	var min_distance_to_caster: float = INF
	
	for candidate in enemies:
		var cluster_count: int = 0
		var cand_pos := Vector2(candidate.global_position.x, candidate.global_position.z)
		for other in enemies:
			var other_pos := Vector2(other.global_position.x, other.global_position.z)
			if cand_pos.distance_to(other_pos) <= 2.8:
				cluster_count += 1
		
		var dist_to_caster := cand_pos.distance_to(Vector2(global_position.x, global_position.z))
		if cluster_count > max_cluster_size:
			max_cluster_size = cluster_count
			min_distance_to_caster = dist_to_caster
			best_target = candidate
		elif cluster_count == max_cluster_size and dist_to_caster < min_distance_to_caster:
			min_distance_to_caster = dist_to_caster
			best_target = candidate

	var target: BaseUnit3D = best_target
	var board := _get_combat_board()
	var impact_cell := target.board_position
	var impact_position := target.global_position
	if board:
		var target_local_position := board.to_local(target.global_position)
		var current_cell := board.get_grid_position(target_local_position)
		if current_cell != Vector2i(-1, -1):
			impact_cell = current_cell
		impact_position = target.global_position + Vector3.UP * 0.8
	else:
		impact_position += Vector3.UP * 0.8

	var projectile := Node3D.new()
	projectile.name = "CumacangaFireball"
	var fireball := MeshInstance3D.new()
	var fireball_mesh := SphereMesh.new()
	fireball_mesh.radius = 0.24
	fireball_mesh.height = 0.48
	fireball.mesh = fireball_mesh
	var fire_material := StandardMaterial3D.new()
	fire_material.albedo_color = Color(1.0, 0.28, 0.035)
	fire_material.emission_enabled = true
	fire_material.emission = Color(1.0, 0.12, 0.015)
	fire_material.emission_energy_multiplier = 2.4
	fire_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	fireball.material_override = fire_material
	projectile.add_child(fireball)
	var glow = OmniLight3D.new()
	glow.light_color = Color(1.0, 0.23, 0.035)
	glow.light_energy = 1.6
	glow.omni_range = 3.0
	projectile.add_child(glow)
	var scene_root := get_tree().current_scene
	if not scene_root:
		return
	scene_root.add_child(projectile)
	var start_position := global_position + Vector3.UP * 1.15
	projectile.global_position = start_position
	var flight := projectile.create_tween()
	flight.tween_method(func(progress: float) -> void:
		if is_instance_valid(projectile):
			var current_impact_position := impact_position
			if is_instance_valid(target):
				current_impact_position = target.global_position + Vector3.UP * 0.8
			projectile.global_position = start_position.lerp(current_impact_position, progress) + Vector3.UP * sin(progress * PI) * 2.0
	, 0.0, 1.0, 0.58).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
	flight.tween_callback(func() -> void:
		if is_instance_valid(projectile):
			projectile.queue_free()
		var final_cell := impact_cell
		var final_position := impact_position
		if board and is_instance_valid(target):
			var target_local_position := board.to_local(target.global_position)
			var current_cell := board.get_grid_position(target_local_position)
			if current_cell != Vector2i(-1, -1):
				final_cell = current_cell
				final_position = board.get_cell_world_position(final_cell) + Vector3.UP * 0.8
		_resolve_cumacanga_impact(target, final_cell, final_position, board)
	)

func _cast_assassin_strike() -> void:
	var enemy_group := "enemy_units" if team == 0 else "player_units"
	var enemies: Array = get_tree().get_nodes_in_group(enemy_group).filter(func(unit):
		return is_instance_valid(unit) and unit is BaseUnit3D and unit.current_state != State.DEAD and unit.visible and not unit.is_on_bench()
	)
	if enemies.is_empty():
		return

	# Inimigo com a vida mais baixa (valor absoluto de HP)
	enemies.sort_custom(func(a: BaseUnit3D, b: BaseUnit3D) -> bool:
		return a.current_health < b.current_health
	)
	var target: BaseUnit3D = enemies[0]
	
	# Efeito visual de partida
	CombatFeedback.create_hit_particles(global_position, Color("#4a154b"))
	CombatFeedback.create_hit_particles(global_position + Vector3.UP * 0.5, Color("#8e44ad"))
	
	# Calcular destino adjacente ao alvo
	var board := _get_combat_board()
	var landing_pos: Vector3 = target.global_position
	var found_cell := false
	
	if board:
		var target_cell := board.get_grid_position(board.to_local(target.global_position))
		if target_cell != Vector2i(-1, -1):
			var neighbors := board.get_neighbors(target_cell)
			var empty_neighbors: Array[Vector2i] = []
			for n in neighbors:
				if not board.is_cell_occupied(n):
					empty_neighbors.append(n)
			var chosen_cell := Vector2i(-1, -1)
			if not empty_neighbors.is_empty():
				chosen_cell = empty_neighbors[0]
			elif not neighbors.is_empty():
				chosen_cell = neighbors[0]
				
			if chosen_cell != Vector2i(-1, -1):
				landing_pos = board.get_cell_world_position(chosen_cell)
				found_cell = true
	
	if not found_cell:
		var offset := (global_position - target.global_position)
		offset.y = 0.0
		if offset.length_squared() < 0.04:
			offset = Vector3.BACK
		landing_pos = target.global_position + offset.normalized() * 1.3
	
	landing_pos.y = combat_ground_height
	global_position = landing_pos
	
	if navigation_agent:
		navigation_agent.velocity = Vector3.ZERO
	velocity = Vector3.ZERO
	
	# Virar em direção ao alvo
	var look_dir := target.global_position - global_position
	look_dir.y = 0.0
	if look_dir.length_squared() > 0.01:
		rotation.y = atan2(look_dir.x, look_dir.z)
	
	# Efeito de chegada no destino
	CombatFeedback.create_hit_particles(global_position, Color("#9b59b6"))
	CombatFeedback.create_hit_particles(global_position + Vector3.UP * 0.6, Color("#e74c3c"))
	
	# Executar habilidade e dano
	var damage := stats.ability_damage * stats.get_star_multiplier(star_level)
	if damage <= 0.0:
		damage = get_attack_damage() * 1.8
	
	CombatFeedback.create_damage_number(target.global_position, damage, CombatFeedback.DamageType.CRITICAL)
	CombatFeedback.create_hit_particles(target.global_position, Color("#e74c3c"))
	target.take_damage(damage, self, stats.ability_damage_type)
	
	if stats.unit_id == "jararaca":
		if is_instance_valid(target) and target.current_state != State.DEAD:
			target.apply_slow(1.5)
		CombatFeedback.create_hit_particles(target.global_position, Color("#22c55e"))
		CombatFeedback.create_status_indicator(self, "BOTE CERTEIRO", 1.2)
	
	# Seguir atacando o alvo se vivo, senão foca no mais próximo
	if is_instance_valid(target) and target.current_state != State.DEAD and not target.is_on_bench():
		current_target = target
	else:
		current_target = null
		find_target()

func _get_combat_board() -> Board3D:
	var scene_root := get_tree().current_scene
	if scene_root:
		return scene_root.get_node_or_null("board") as Board3D
	return null

func _resolve_cumacanga_impact(target: BaseUnit3D, impact_cell: Vector2i, impact_position: Vector3, board: Board3D) -> void:
	var damage: float = stats.ability_damage * stats.get_star_multiplier(star_level)
	var burn_duration := stats.ability_duration if stats.ability_duration > 0.0 else 2.5
	var affected_cells: Array[Vector2i] = [impact_cell]
	if board:
		affected_cells.append_array(board.get_neighbors(impact_cell))
		for cell in affected_cells:
			_create_burning_hex(board, cell, burn_duration)
		var enemy_group := "enemy_units" if team == 0 else "player_units"
		for victim in get_tree().get_nodes_in_group(enemy_group):
			if not is_instance_valid(victim) or victim.current_state == State.DEAD or not victim.visible or victim.is_on_bench():
				continue
			var victim_cell := board.get_grid_position(board.to_local(victim.global_position))
			if victim_cell in affected_cells:
				victim.take_damage(damage, self, stats.ability_damage_type)
				victim.apply_burn(burn_duration, self, damage * 0.15)
	else:
		if is_instance_valid(target) and target.current_state != State.DEAD and not target.is_on_bench():
			target.take_damage(damage, self, stats.ability_damage_type)
			target.apply_burn(burn_duration, self, damage * 0.15)
	CombatFeedback.create_hit_particles(impact_position, Color(1.0, 0.28, 0.035))

func _create_burning_hex(board: Board3D, cell: Vector2i, duration: float) -> void:
	var fire_effect := Node3D.new()
	fire_effect.name = "BurningHex"
	board.add_child(fire_effect)
	fire_effect.global_position = board.get_cell_world_position(cell) + Vector3.UP * 0.1
	var ground_fire := MeshInstance3D.new()
	var hex_mesh := CylinderMesh.new()
	hex_mesh.top_radius = board.get_hex_radius() * 0.86
	hex_mesh.bottom_radius = board.get_hex_radius() * 0.86
	hex_mesh.height = 0.035
	hex_mesh.radial_segments = 6
	ground_fire.mesh = hex_mesh
	var ground_material := StandardMaterial3D.new()
	ground_material.albedo_color = Color(1.0, 0.22, 0.025, 0.62)
	ground_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	ground_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	ground_material.emission_enabled = true
	ground_material.emission = Color(1.0, 0.16, 0.015)
	ground_material.emission_energy_multiplier = 1.2
	ground_fire.material_override = ground_material
	ground_fire.position.y = 0.015
	fire_effect.add_child(ground_fire)
	var flames := GPUParticles3D.new()
	flames.amount = 18
	flames.lifetime = 0.7
	flames.explosiveness = 0.35
	flames.emitting = true
	var particle_material := ParticleProcessMaterial.new()
	particle_material.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	particle_material.emission_sphere_radius = board.get_hex_radius() * 0.65
	particle_material.direction = Vector3.UP
	particle_material.spread = 24.0
	particle_material.initial_velocity_min = 0.55
	particle_material.initial_velocity_max = 1.5
	particle_material.gravity = Vector3(0.0, -1.2, 0.0)
	particle_material.scale_min = 0.09
	particle_material.scale_max = 0.18
	particle_material.color = Color(1.0, 0.32, 0.035, 0.9)
	flames.process_material = particle_material
	var spark_mesh := SphereMesh.new()
	spark_mesh.radius = 0.07
	spark_mesh.height = 0.14
	var spark_material := StandardMaterial3D.new()
	spark_material.albedo_color = Color(1.0, 0.3, 0.025)
	spark_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	spark_material.emission_enabled = true
	spark_material.emission = Color(1.0, 0.12, 0.01)
	spark_material.emission_energy_multiplier = 1.5
	spark_mesh.material = spark_material
	flames.draw_pass_1 = spark_mesh
	flames.position.y = 0.18
	fire_effect.add_child(flames)
	get_tree().create_timer(duration, false).timeout.connect(fire_effect.queue_free)

func apply_burn(duration: float, source: BaseUnit3D, damage_per_tick: float) -> void:
	if current_state == State.DEAD or duration <= 0.0 or damage_per_tick <= 0.0:
		return
	_burn_generation += 1
	var generation := _burn_generation
	_burn_expires_at_msec = BattleClock.now_msec() + int(duration * 1000.0)
	CombatFeedback.create_status_indicator(self, "QUEIMADO", duration)
	_run_burn_ticks(generation, duration, source, damage_per_tick)

func _run_burn_ticks(generation: int, duration: float, source: BaseUnit3D, damage_per_tick: float) -> void:
	var elapsed := 0.0
	while elapsed < duration and current_state != State.DEAD:
		await get_tree().create_timer(0.5, false).timeout
		if generation != _burn_generation or current_state == State.DEAD:
			return
		elapsed += 0.5
		take_damage(damage_per_tick, source if is_instance_valid(source) else null, UnitStats.DamageType.MAGICAL)

func _apply_ability_healing() -> void:
	if stats.ability_heal <= 0.0:
		return

	if stats.unit_id == "aguape":
		CombatFeedback.create_status_indicator(self, "MANTO FLUTUANTE", 1.2)
		CombatFeedback.create_hit_particles(global_position, Color("#38bdf8"))
		_create_water_sanctuary_element(global_position, 3.5)
	elif stats.unit_id == "lobo_guara":
		CombatFeedback.create_status_indicator(self, "RASTRO DA LOBEIRA", 1.2)
		CombatFeedback.create_hit_particles(global_position, Color("#f59e0b"))
		if model:
			var tw := create_tween()
			tw.tween_property(model, "position:y", 0.35, 0.12).set_trans(Tween.TRANS_QUAD)
			tw.tween_property(model, "position:y", 0.0, 0.15).set_trans(Tween.TRANS_BOUNCE)
	elif stats.unit_id == "palmito_jucara":
		CombatFeedback.create_status_indicator(self, "FRUTOS DA FLORESTA", 1.2)
		CombatFeedback.create_hit_particles(global_position, Color("#a855f7"))
	elif stats.unit_id == "vitoria_regia":
		CombatFeedback.create_status_indicator(self, "MANTO DAS ÁGUAS", 1.2)
		CombatFeedback.create_hit_particles(global_position, Color("#22d3ee"))
		_create_water_sanctuary_element(global_position, 3.5)
	elif stats.unit_id == "labatut":
		CombatFeedback.create_status_indicator(self, "CORRENTE CURATIVA", 1.2)
		CombatFeedback.create_hit_particles(global_position, Color("#38bdf8"))
		if model:
			var tw := create_tween()
			tw.tween_property(model, "scale", model_base_scale * Vector3(1.2, 0.8, 1.2), 0.12).set_trans(Tween.TRANS_QUAD)
			tw.tween_property(model, "scale", model_base_scale, 0.2).set_trans(Tween.TRANS_BOUNCE)

	var ally_group := "player_units" if team == 0 else "enemy_units"
	var allies: Array = get_tree().get_nodes_in_group(ally_group).filter(func(ally):
		if not is_instance_valid(ally) or ally.current_state == State.DEAD or not ally.visible or ally.is_on_bench():
			return false
		var distance := Vector2(global_position.x, global_position.z).distance_to(
			Vector2(ally.global_position.x, ally.global_position.z)
		)
		return distance <= maxf(stats.ability_range, stats.attack_range * 2.0) and ally.current_health < ally.get_max_health()
	)
	allies.sort_custom(func(a: BaseUnit3D, b: BaseUnit3D) -> bool:
		var missing_a := (a.get_max_health() - a.current_health) / maxf(a.get_max_health(), 1.0)
		var missing_b := (b.get_max_health() - b.current_health) / maxf(b.get_max_health(), 1.0)
		return missing_a > missing_b
	)
	var heal_val := stats.ability_heal * stats.get_star_multiplier(star_level)
	var target_count := mini(maxi(stats.ability_targets, 1), allies.size())
	for i in target_count:
		var ally: BaseUnit3D = allies[i]
		var healed := ally.heal(heal_val, self)
		if healed > 0.0:
			CombatFeedback.create_status_indicator(ally, "+%d HP" % int(healed), 1.2)
			CombatFeedback.create_hit_particles(ally.global_position, Color("#4ade80"))

func die() -> void:
	if current_state == State.DEAD:
		return
	in_combat = false
	_was_stunned = false
	stunned_until_msec = 0
	current_state = State.DEAD
	current_health = 0
	current_shield = 0.0
	consecutive_attacks = 0
	attack_timer.stop()
	velocity = Vector3.ZERO
	collision_layer = 0
	collision_mask = 0
	if navigation_agent:
		navigation_agent.set_velocity(Vector3.ZERO)
		navigation_agent.avoidance_enabled = false
	set_hovered(false)
	if ui_sprite:
		ui_sprite.hide()
	_death_generation += 1
	var generation := _death_generation
	var death_duration := unit_visual.play_death()
	current_target = null
	for unit in get_tree().get_nodes_in_group("units"):
		if unit is BaseUnit3D and unit.current_target == self:
			unit.current_target = null
	# A morte lógica é imediata; apenas o corpo espera a animação terminar.
	died.emit(self)
	await get_tree().create_timer(death_duration, false).timeout
	# O fim da rodada pode reviver a unidade antes de a animação terminar.
	if generation != _death_generation or current_state != State.DEAD:
		return
	if team == 0:
		visible = false
		process_mode = Node.PROCESS_MODE_DISABLED
	else:
		queue_free()


func revive_at_position(world_pos: Vector3) -> void:
	_death_generation += 1
	use_navigation = false
	_detour_dir = Vector3.ZERO
	_detour_timer = 0.0
	in_combat = true
	_was_stunned = false
	current_state = State.IDLE
	current_health = get_max_health()
	current_mana = stats.starting_mana
	current_shield = 0.0
	current_target = null
	velocity = Vector3.ZERO
	stunned_until_msec = 0
	immune_until_msec = 0
	reflect_until_msec = 0
	reflect_pct = 0.0
	armor_shred_until_msec = 0
	armor_shred_amount = 0.0
	
	visible = true
	is_hovered = false
	process_mode = Node.PROCESS_MODE_INHERIT
	collision_layer = 1
	collision_mask = 1
	global_position = world_pos
	combat_ground_height = world_pos.y
	if ui_sprite:
		ui_sprite.show()
	unit_visual.reset_pose()
	
	if model:
		model.scale = model_base_scale
		if is_flying():
			model.position.y = FLYING_BASE_HEIGHT
		else:
			model.position.y = 0.0
	
	update_health_bar()
	update_mana_bar()

func update_health_bar() -> void:
	update_stats_display() # Atualizar labels ao invés de barras
	health_changed.emit(current_health, get_max_health())

func update_mana_bar() -> void:
	update_stats_display() # Atualizar labels ao invés de barras
	mana_changed.emit(current_mana, stats.max_mana)

func _process(delta: float) -> void:
	_update_aura_indicator()
	if unit_visual:
		unit_visual.update_locomotion(current_state == State.MOVING, get_movement_speed(), current_state == State.IDLE)
	if is_flying() and model and current_state != State.DEAD and not _is_swooping:
		var hover: float = sin(float(Time.get_ticks_msec()) * 0.003 + float(get_instance_id() % 100)) * 0.07
		model.position.y = FLYING_BASE_HEIGHT + hover
	if current_state == State.DEAD or current_state == State.IDLE:
		_health_regen_accumulator = 0.0
		return
	if stats.mana_per_second > 0.0:
		add_mana(stats.mana_per_second * delta)
	var regen_per_second := stats.health_regen + float(synergy_bonuses.get("health_regen", 0.0))
	if regen_per_second > 0.0:
		_health_regen_accumulator += delta
		if _health_regen_accumulator >= 1.0:
			var elapsed_seconds := floorf(_health_regen_accumulator)
			_health_regen_accumulator -= elapsed_seconds
			heal(regen_per_second * elapsed_seconds, self)
	
	# Sinergia Seiva: A cada 4 segundos, cura e ganha acúmulo de Crescimento (máx 3)
	if float(synergy_bonuses.get("seiva_pulse_heal_pct", 0.0)) > 0.0:
		_seiva_timer += delta
		if _seiva_timer >= 4.0:
			_seiva_timer -= 4.0
			var h_amount := get_max_health() * float(synergy_bonuses.get("seiva_pulse_heal_pct", 0.0))
			heal(h_amount, self)
			seiva_growth_stacks = mini(seiva_growth_stacks + 1, 3)
			CombatFeedback.create_status_indicator(self, "+CRESCIMENTO (%d)" % seiva_growth_stacks, 0.7)

	# Sinergia Correnteza: A cada 5 segundos, todos os integrantes vivos recebem mana e escudo por 2s
	if float(synergy_bonuses.get("correnteza_mana", 0.0)) > 0.0:
		_correnteza_timer += delta
		if _correnteza_timer >= 5.0:
			_correnteza_timer -= 5.0
			add_mana(float(synergy_bonuses.get("correnteza_mana", 0.0)))
			var sh_val := get_max_health() * float(synergy_bonuses.get("correnteza_shield_pct", 0.0))
			set_shield_with_source(sh_val, ShieldSource.CLASS)
			CombatFeedback.create_status_indicator(self, "+CORRENTEZA", 0.6)

# ==============================================================================
# ELEMENTOS VISUAIS DE COMBATE NO TABULEIRO
# ==============================================================================

func _create_araucaria_canopy_element(center_pos: Vector3, radius: float, duration: float) -> void:
	var scene_root: Node = get_tree().current_scene if get_tree() else null
	if not scene_root:
		scene_root = get_parent()
	if not scene_root:
		return
	
	var canopy := Node3D.new()
	canopy.name = "AraucariaCanopyVisual"
	scene_root.add_child(canopy)
	canopy.global_position = center_pos
	
	var root_mat := StandardMaterial3D.new()
	root_mat.albedo_color = Color("#78350f")
	root_mat.emission_enabled = true
	root_mat.emission = Color("#15803d")
	root_mat.emission_energy_multiplier = 0.8
	
	var leaf_mat := StandardMaterial3D.new()
	leaf_mat.albedo_color = Color("#16a34a")
	leaf_mat.emission_enabled = true
	leaf_mat.emission = Color("#22c55e")
	leaf_mat.emission_energy_multiplier = 1.2
	leaf_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	
	for i in 6:
		var angle := (TAU / 6.0) * float(i)
		var arch := MeshInstance3D.new()
		var cyl := CylinderMesh.new()
		cyl.top_radius = 0.08
		cyl.bottom_radius = 0.18
		cyl.height = 1.6
		arch.mesh = cyl
		arch.material_override = root_mat
		arch.position = Vector3(cos(angle) * (radius * 0.7), 0.7, sin(angle) * (radius * 0.7))
		arch.rotation = Vector3(sin(angle) * 0.35, angle, cos(angle) * 0.35)
		canopy.add_child(arch)
		
		var foliage := MeshInstance3D.new()
		var prism := PrismMesh.new()
		prism.size = Vector3(0.5, 0.6, 0.5)
		foliage.mesh = prism
		foliage.material_override = leaf_mat
		foliage.position = arch.position + Vector3.UP * 0.7
		foliage.rotation.y = angle
		canopy.add_child(foliage)
		
	var light := OmniLight3D.new()
	light.light_color = Color("#22c55e")
	light.light_energy = 1.4
	light.omni_range = maxf(radius * 1.5, 4.0)
	light.position = Vector3.UP * 1.2
	canopy.add_child(light)
	
	canopy.scale = Vector3(0.1, 0.1, 0.1)
	var tw := canopy.create_tween()
	tw.tween_property(canopy, "scale", Vector3.ONE, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_interval(maxf(duration - 0.5, 0.1))
	tw.tween_property(canopy, "scale", Vector3(0.01, 0.01, 0.01), 0.25).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tw.tween_callback(canopy.queue_free)

func _create_sumauma_roots_element(center_pos: Vector3, radius: float, duration: float) -> void:
	var scene_root: Node = get_tree().current_scene if get_tree() else null
	if not scene_root:
		scene_root = get_parent()
	if not scene_root:
		return
	
	var roots_node := Node3D.new()
	roots_node.name = "SumaumaRootsVisual"
	scene_root.add_child(roots_node)
	roots_node.global_position = center_pos
	
	var bark_mat := StandardMaterial3D.new()
	bark_mat.albedo_color = Color("#3f2e18")
	bark_mat.emission_enabled = true
	bark_mat.emission = Color("#15803d")
	bark_mat.emission_energy_multiplier = 0.9
	
	for i in 6:
		var angle := (TAU / 6.0) * float(i) + 0.3
		var pillar := MeshInstance3D.new()
		var cyl := CylinderMesh.new()
		cyl.bottom_radius = 0.26
		cyl.top_radius = 0.10
		cyl.height = 1.6
		pillar.mesh = cyl
		pillar.material_override = bark_mat
		var local_x := cos(angle) * (radius * 0.65)
		var local_z := sin(angle) * (radius * 0.65)
		pillar.position = Vector3(local_x, -1.0, local_z)
		pillar.rotation = Vector3(sin(angle) * 0.25, angle, -cos(angle) * 0.25)
		roots_node.add_child(pillar)
		
		var tw_pillar := roots_node.create_tween()
		tw_pillar.tween_property(pillar, "position:y", 0.65, 0.3 + float(i) * 0.04).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tw_pillar.tween_interval(maxf(duration - 0.6, 0.1))
		tw_pillar.tween_property(pillar, "position:y", -1.2, 0.3).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	
	var light := OmniLight3D.new()
	light.light_color = Color("#16a34a")
	light.light_energy = 1.6
	light.omni_range = maxf(radius * 1.6, 5.0)
	light.position = Vector3.UP * 1.0
	roots_node.add_child(light)
	
	var lifetime := roots_node.create_tween()
	lifetime.tween_interval(duration + 0.4)
	lifetime.tween_callback(roots_node.queue_free)

func _create_mandacaru_thorn_element(center_pos: Vector3, duration: float) -> void:
	var scene_root: Node = get_tree().current_scene if get_tree() else null
	if not scene_root:
		scene_root = get_parent()
	if not scene_root:
		return
	
	var fence := Node3D.new()
	fence.name = "MandacaruThornFenceVisual"
	scene_root.add_child(fence)
	fence.global_position = center_pos
	
	var cactus_mat := StandardMaterial3D.new()
	cactus_mat.albedo_color = Color("#15803d")
	cactus_mat.emission_enabled = true
	cactus_mat.emission = Color("#22c55e")
	cactus_mat.emission_energy_multiplier = 0.8
	
	for i in 6:
		var angle := (TAU / 6.0) * float(i)
		var column := MeshInstance3D.new()
		var cyl := CylinderMesh.new()
		cyl.top_radius = 0.12
		cyl.bottom_radius = 0.14
		cyl.height = 0.95
		column.mesh = cyl
		column.material_override = cactus_mat
		column.position = Vector3(cos(angle) * 0.9, -0.6, sin(angle) * 0.9)
		fence.add_child(column)
		
		var tw_col := fence.create_tween()
		tw_col.tween_property(column, "position:y", 0.45, 0.22 + float(i) * 0.03).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tw_col.tween_interval(maxf(duration - 0.5, 0.1))
		tw_col.tween_property(column, "position:y", -0.7, 0.22).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	
	var lifetime := fence.create_tween()
	lifetime.tween_interval(duration + 0.3)
	lifetime.tween_callback(fence.queue_free)

func _create_pau_brasil_bloom_element(center_pos: Vector3, radius: float, duration: float) -> void:
	var scene_root: Node = get_tree().current_scene if get_tree() else null
	if not scene_root:
		scene_root = get_parent()
	if not scene_root:
		return
	
	var bloom := Node3D.new()
	bloom.name = "PauBrasilBloomVisual"
	scene_root.add_child(bloom)
	bloom.global_position = center_pos + Vector3.UP * 0.05
	
	var gold_mat := StandardMaterial3D.new()
	gold_mat.albedo_color = Color("#f59e0b")
	gold_mat.emission_enabled = true
	gold_mat.emission = Color("#fbbf24")
	gold_mat.emission_energy_multiplier = 1.8
	gold_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	
	var center_disk := MeshInstance3D.new()
	var cyl := CylinderMesh.new()
	cyl.top_radius = 0.4
	cyl.bottom_radius = 0.4
	cyl.height = 0.06
	center_disk.mesh = cyl
	center_disk.material_override = gold_mat
	bloom.add_child(center_disk)
	
	for i in 8:
		var angle := (TAU / 8.0) * float(i)
		var petal := MeshInstance3D.new()
		var p_mesh := BoxMesh.new()
		p_mesh.size = Vector3(0.35, 0.04, radius * 0.5)
		petal.mesh = p_mesh
		petal.material_override = gold_mat
		petal.position = Vector3(cos(angle) * (radius * 0.3), 0.02, sin(angle) * (radius * 0.3))
		petal.rotation.y = angle
		bloom.add_child(petal)
		
	var light := OmniLight3D.new()
	light.light_color = Color("#fbbf24")
	light.light_energy = 1.8
	light.omni_range = maxf(radius * 1.5, 4.5)
	light.position = Vector3.UP * 0.5
	bloom.add_child(light)
	
	bloom.scale = Vector3(0.01, 0.01, 0.01)
	var tw := bloom.create_tween()
	tw.set_parallel(true)
	tw.tween_property(bloom, "scale", Vector3.ONE, 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(bloom, "rotation:y", PI * 0.75, duration)
	
	var tw_seq := bloom.create_tween()
	tw_seq.tween_interval(maxf(duration - 0.4, 0.1))
	tw_seq.tween_property(bloom, "scale", Vector3(0.01, 0.01, 0.01), 0.35).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tw_seq.tween_callback(bloom.queue_free)

func _create_minhocao_crater_element(center_pos: Vector3, radius: float, duration: float) -> void:
	var scene_root: Node = get_tree().current_scene if get_tree() else null
	if not scene_root:
		scene_root = get_parent()
	if not scene_root:
		return
	
	var crater := Node3D.new()
	crater.name = "MinhocaoCraterVisual"
	scene_root.add_child(crater)
	crater.global_position = center_pos + Vector3.UP * 0.04
	
	var earth_mat := StandardMaterial3D.new()
	earth_mat.albedo_color = Color("#451a03")
	earth_mat.emission_enabled = true
	earth_mat.emission = Color("#d97706")
	earth_mat.emission_energy_multiplier = 1.1
	
	for i in 8:
		var angle := (TAU / 8.0) * float(i) + randf() * 0.2
		var slab := MeshInstance3D.new()
		var b := BoxMesh.new()
		b.size = Vector3(0.5, 0.15, 0.7)
		slab.mesh = b
		slab.material_override = earth_mat
		slab.position = Vector3(cos(angle) * (radius * 0.5), 0.05, sin(angle) * (radius * 0.5))
		slab.rotation = Vector3(0.2, angle, 0.15)
		crater.add_child(slab)
		
	var light := OmniLight3D.new()
	light.light_color = Color("#d97706")
	light.light_energy = 1.6
	light.omni_range = maxf(radius * 1.4, 4.0)
	crater.add_child(light)
	
	crater.scale = Vector3(0.1, 0.1, 0.1)
	var tw := crater.create_tween()
	tw.tween_property(crater, "scale", Vector3.ONE, 0.2).set_trans(Tween.TRANS_BOUNCE)
	tw.tween_interval(maxf(duration - 0.4, 0.1))
	tw.tween_property(crater, "scale", Vector3(0.01, 0.01, 0.01), 0.3).set_trans(Tween.TRANS_QUAD)
	tw.tween_callback(crater.queue_free)

func _create_mboi_guacu_coil_element(target: BaseUnit3D, duration: float) -> void:
	if not is_instance_valid(target):
		return
	var coil := Node3D.new()
	coil.name = "MboiGuacuCoilVisual"
	target.add_child(coil)
	coil.position = Vector3.ZERO
	
	var coil_mat := StandardMaterial3D.new()
	coil_mat.albedo_color = Color("#0284c7")
	coil_mat.emission_enabled = true
	coil_mat.emission = Color("#38bdf8")
	coil_mat.emission_energy_multiplier = 2.2
	coil_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	
	for i in 3:
		var ring := MeshInstance3D.new()
		var torus := TorusMesh.new()
		torus.inner_radius = 0.32
		torus.outer_radius = 0.44
		ring.mesh = torus
		ring.material_override = coil_mat
		ring.position = Vector3(0.0, 0.35 + float(i) * 0.35, 0.0)
		ring.rotation.x = 0.25 * (1.0 if i % 2 == 0 else -1.0)
		coil.add_child(ring)
		
	var tw := coil.create_tween()
	tw.set_parallel(true)
	tw.tween_property(coil, "rotation:y", TAU * 4.0, duration)
	
	var tw_seq := coil.create_tween()
	tw_seq.tween_interval(duration)
	tw_seq.tween_callback(func() -> void:
		if is_instance_valid(coil):
			coil.queue_free()
	)

func _create_water_sanctuary_element(center_pos: Vector3, duration: float) -> void:
	var scene_root: Node = get_tree().current_scene if get_tree() else null
	if not scene_root:
		scene_root = get_parent()
	if not scene_root:
		return
	
	var pad := Node3D.new()
	pad.name = "WaterLilySanctuaryVisual"
	scene_root.add_child(pad)
	pad.global_position = center_pos + Vector3.UP * 0.03
	
	var leaf_mat := StandardMaterial3D.new()
	leaf_mat.albedo_color = Color("#15803d")
	leaf_mat.emission_enabled = true
	leaf_mat.emission = Color("#22c55e")
	leaf_mat.emission_energy_multiplier = 0.6
	
	var water_mat := StandardMaterial3D.new()
	water_mat.albedo_color = Color(0.1, 0.6, 0.9, 0.7)
	water_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	water_mat.emission_enabled = true
	water_mat.emission = Color("#06b6d4")
	water_mat.emission_energy_multiplier = 1.2
	water_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	
	var leaf_mesh := MeshInstance3D.new()
	var cyl := CylinderMesh.new()
	cyl.top_radius = 0.85
	cyl.bottom_radius = 0.85
	cyl.height = 0.04
	leaf_mesh.mesh = cyl
	leaf_mesh.material_override = leaf_mat
	pad.add_child(leaf_mesh)
	
	var water_ring := MeshInstance3D.new()
	var torus := TorusMesh.new()
	torus.inner_radius = 0.95
	torus.outer_radius = 1.15
	water_ring.mesh = torus
	water_ring.material_override = water_mat
	pad.add_child(water_ring)
	
	pad.scale = Vector3(0.01, 0.01, 0.01)
	var tw := pad.create_tween()
	tw.tween_property(pad, "scale", Vector3.ONE, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_interval(maxf(duration - 0.4, 0.1))
	tw.tween_property(pad, "scale", Vector3(0.01, 0.01, 0.01), 0.25).set_trans(Tween.TRANS_QUAD)
	tw.tween_callback(pad.queue_free)
