class_name BaseUnit3D
extends CharacterBody3D

@export var use_navigation: bool = true  # false = movimento direto (debug)
@export var debug_movement: bool = true   # prints de debug

## Signals
signal died(unit: BaseUnit3D)
signal health_changed(current: float, maximum: float)
signal mana_changed(current: float, maximum: float)
signal ability_cast(ability_name: String)

## Stats
var stats: UnitStats
var current_health: float
var current_mana: float
var star_level: int = 1

## Estado de Combate
enum State { IDLE, MOVING, ATTACKING, CASTING, DEAD }
var current_state: State = State.IDLE
var current_target: BaseUnit3D = null

## Posição no Board
var board_position: Vector2i = Vector2i.ZERO
var team: int = 0
var cell_reference: GridCell3D = null

## Componentes 3D
var model: Node3D
var animation_player: AnimationPlayer
var attack_timer: Timer

## UI 3D
var health_bar_3d: ProgressBar
var mana_bar_3d: ProgressBar
var name_label: Label3D
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

## Flag para saber se UI já foi finalizada
var ui_ready: bool = false

@export var debug_navigation: bool = false

const CombatFeedback = preload("res://Scripts/Systems/combat_feedback.gd")

func _ready() -> void:
	add_to_group("units")
	if team == 0:
		add_to_group("player_units")
	else:
		add_to_group("enemy_units")
		
	
	# IMPORTANTE: Configurar collision
	collision_layer = 1  # Layer 1 para unidades
	collision_mask = 1   # Detectar outras unidades
	
	setup_navigation()
	setup_timers()
	

func move_direct_to_target() -> void:
	"""Movimento direto sem navigation (para debug)"""
	if not is_instance_valid(current_target):
		current_target = null
		find_target()
		return
	
	if not current_target:
		return
	
	current_state = State.MOVING
	
	var target_pos: Vector3 = current_target.global_position
	var direction: Vector3 = (target_pos - global_position).normalized()
	
	if debug_movement:
		print("%s movendo DIRETO para %s (dist: %.2f)" % [
			stats.unit_name,
			current_target.stats.unit_name,
			global_position.distance_to(target_pos)
		])
	
	# Movimento direto
	velocity = direction * stats.movement_speed * get_physics_process_delta_time()
	move_and_slide()
	
	# Rotação
	if direction.length() > 0:
		var target_rotation: float = atan2(direction.x, direction.z)
		rotation.y = lerp_angle(rotation.y, target_rotation, 0.15)
	
	# Verificar se chegou perto o suficiente para atacar
	if global_position.distance_to(target_pos) <= (stats.attack_range * 2.0 + 0.5):
		if debug_movement:
			print("%s chegou no range de ataque!" % stats.unit_name)
		current_state = State.IDLE
		check_attack_or_move()


func initialize(unit_stats: UnitStats, star: int = 1) -> void:
	stats = unit_stats
	star_level = star
	
	var star_multiplier: float = stats.get_star_multiplier(star_level)
	current_health = stats.max_health * star_multiplier
	current_mana = stats.starting_mana
	
	current_state = State.IDLE
	
	setup_model()
	setup_stats_display()
	update_stats_display()
	update_health_bar()
	update_mana_bar()

func setup_model() -> void:
	# Procurar ou criar Model node
	if has_node("Model"):
		model = get_node("Model")
		for child in model.get_children():
			if child is MeshInstance3D and child.mesh is CapsuleMesh:
				child.queue_free()
	
	else:
		model = Node3D.new()
		model.name = "Model"
		add_child(model)
		
		# Criar mesh placeholder
		var mesh_instance := MeshInstance3D.new()
		var capsule_mesh := CapsuleMesh.new()
		capsule_mesh.height = 2.0
		capsule_mesh.radius = 0.4
		mesh_instance.mesh = capsule_mesh
		mesh_instance.position.y = 1.0
		
		# Material baseado no tier
		var mat := StandardMaterial3D.new()
		mat.albedo_color = stats.get_tier_color()
		mat.metallic = 0.3
		mat.roughness = 0.4
		mesh_instance.material_override = mat
		
		model.add_child(mesh_instance)
	
	# Escalar baseado em estrelas
	model.scale = Vector3.ONE * (1.0 + (star_level - 1) * 0.15)
	
	# Criar ou configurar Label3D
	if not has_node("NameLabel"):
		name_label = Label3D.new()
		name_label.name = "NameLabel"
		name_label.position = Vector3(0, 3.0, 0)
		name_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		name_label.no_depth_test = true
		name_label.font_size = 32
		name_label.outline_size = 8
		name_label.outline_modulate = Color.BLACK
		add_child(name_label)
	else:
		name_label = get_node("NameLabel")
	
	# Texto com estrelas
	var star_text := ""
	for i in star_level:
		star_text += "★"
	name_label.text = "%s %s" % [stats.unit_name, star_text]
	setup_team_indicator()

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
		
		var mat =  StandardMaterial3D.new()
		mat.albedo_color = Color(1,0.1,0.4)
		mat.emission_enabled = true
		mat.emission = Color(1,0,0)
		mat.emission_energy_multiplier = 2.0
		mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		
		indicator.material_override = mat
		add_child(indicator)

func setup_stats_display() -> void:
	# Label de HP (acima do nome)
	var hp_label := Label3D.new()
	hp_label.name = "HPLabel"
	hp_label.position = Vector3(0, 2.2, 0)
	hp_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	hp_label.no_depth_test = true
	hp_label.font_size = 28
	hp_label.outline_size = 8
	hp_label.outline_modulate = Color.BLACK
	hp_label.modulate = Color(1, 0.2, 0.2)  # Vermelho para HP
	add_child(hp_label)
	
	# Label de Mana (abaixo do nome)
	var mana_label := Label3D.new()
	mana_label.name = "ManaLabel"
	mana_label.position = Vector3(0, 1.9, 0)
	mana_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	mana_label.no_depth_test = true
	mana_label.font_size = 24
	mana_label.outline_size = 6
	mana_label.outline_modulate = Color.BLACK
	mana_label.modulate = Color(0.3, 0.6, 1.0)  # Azul para Mana
	add_child(mana_label)
	
	print("✅ Stats display criado para %s" % stats.unit_name)

func update_stats_display() -> void:
	# Atualizar HP Label
	if has_node("HPLabel"):
		var hp_label: Label3D = get_node("HPLabel")
		var hp_percent: float = (current_health / get_max_health()) * 100.0
		hp_label.text = "HP: %d/%d" % [int(current_health), int(get_max_health())]
		
		# Mudar cor baseado no HP
		if hp_percent > 70:
			hp_label.modulate = Color(0.2, 1, 0.2)
		elif hp_percent > 30:
			hp_label.modulate = Color(1, 0.8, 0.2) 
		else:
			hp_label.modulate = Color(1, 0.2, 0.2) 
	
	# Atualizar Mana Label
	if has_node("ManaLabel"):
		var mana_label: Label3D = get_node("ManaLabel")
		var mana_percent: float = (current_mana / stats.max_mana) * 100.0
		mana_label.text = "MP: %d/%d (%.0f%%)" % [int(current_mana), int(stats.max_mana), mana_percent]
		
		# Brilhar quando mana cheia
		if current_mana >= stats.max_mana:
			mana_label.modulate = Color(1, 1, 0.2)  # Amarelo brilhante
		else:
			mana_label.modulate = stats.get_tier_color()
	# Criar SubViewport para UI 3D
	var viewport_container := SubViewportContainer.new()
	viewport_container.name = "UIContainer"
	viewport_container.visible = false
	add_child(viewport_container)
	
	ui_viewport = SubViewport.new()
	ui_viewport.name = "UIViewport"
	ui_viewport.transparent_bg = true
	ui_viewport.size = Vector2i(300, 80)
	ui_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	viewport_container.add_child(ui_viewport)
	
	# Health Bar
	health_bar_3d = ProgressBar.new()
	health_bar_3d.name = "HealthBar"
	health_bar_3d.custom_minimum_size = Vector2(280, 12)
	health_bar_3d.position = Vector2(10, 10)
	health_bar_3d.show_percentage = false
	
	# Estilo da health bar
	var health_style := StyleBoxFlat.new()
	health_style.bg_color = Color(0.8, 0.2, 0.2)
	health_style.corner_radius_top_left = 2
	health_style.corner_radius_top_right = 2
	health_style.corner_radius_bottom_left = 2
	health_style.corner_radius_bottom_right = 2
	health_bar_3d.add_theme_stylebox_override("fill", health_style)
	
	var bg_style := StyleBoxFlat.new()
	bg_style.bg_color = Color(0.2, 0.2, 0.2, 0.8)
	bg_style.corner_radius_top_left = 2
	bg_style.corner_radius_top_right = 2
	bg_style.corner_radius_bottom_left = 2
	bg_style.corner_radius_bottom_right = 2
	health_bar_3d.add_theme_stylebox_override("background", bg_style)
	
	ui_viewport.add_child(health_bar_3d)
	
	# Mana Bar
	mana_bar_3d = ProgressBar.new()
	mana_bar_3d.name = "ManaBar"
	mana_bar_3d.custom_minimum_size = Vector2(280, 8)
	mana_bar_3d.position = Vector2(10, 35)
	mana_bar_3d.show_percentage = false
	
	var mana_style := StyleBoxFlat.new()
	mana_style.bg_color = stats.get_tier_color()
	mana_style.corner_radius_top_left = 2
	mana_style.corner_radius_top_right = 2
	mana_style.corner_radius_bottom_left = 2
	mana_style.corner_radius_bottom_right = 2
	mana_bar_3d.add_theme_stylebox_override("fill", mana_style)
	
	var mana_bg_style := StyleBoxFlat.new()
	mana_bg_style.bg_color = Color(0.2, 0.2, 0.2, 0.8)
	mana_bg_style.corner_radius_top_left = 2
	mana_bg_style.corner_radius_top_right = 2
	mana_bg_style.corner_radius_bottom_left = 2
	mana_bg_style.corner_radius_bottom_right = 2
	mana_bar_3d.add_theme_stylebox_override("background", mana_bg_style)
	
	ui_viewport.add_child(mana_bar_3d)
	
	# Sprite3D para mostrar o viewport
	ui_sprite = Sprite3D.new()
	ui_sprite.name = "UISprite"
	ui_sprite.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	ui_sprite.no_depth_test = true
	ui_sprite.pixel_size = 0.01
	ui_sprite.position = Vector3(0, 2.8, 0)
	ui_sprite.modulate = Color(1, 1, 1, 1)
	add_child(ui_sprite)
	
	# Configurar valores iniciais
	health_bar_3d.max_value = get_max_health()
	health_bar_3d.value = current_health
	mana_bar_3d.max_value = stats.max_mana
	mana_bar_3d.value = current_mana



func setup_navigation() -> void:
	if has_node("NavigationAgent3D"):
		navigation_agent = get_node("NavigationAgent3D")
	else:
		navigation_agent = NavigationAgent3D.new()
		navigation_agent.name = "NavigationAgent3D"
		add_child(navigation_agent)
	
	# Aguardar NavigationServer estar pronto
	call_deferred("_setup_navigation_agent")

func _setup_navigation_agent() -> void:
	if not navigation_agent:
		return
	
	navigation_agent.debug_enabled = true
	# Aguardar physics frame
	await get_tree().physics_frame
	
	# Configurações básicas
	navigation_agent.path_desired_distance = 0.5
	navigation_agent.target_desired_distance = 1.5
	navigation_agent.path_max_distance = 50.0
	
	# Velocidade
	navigation_agent.max_speed = stats.movement_speed if stats else 200.0
	
	# Avoidance
	navigation_agent.avoidance_enabled = true
	navigation_agent.radius = 0.5
	navigation_agent.neighbor_distance = 5.0
	navigation_agent.max_neighbors = 10
	navigation_agent.time_horizon_agents = 0.5
	navigation_agent.time_horizon_obstacles = 0.5
	
	# Layers
	navigation_agent.navigation_layers = 1
	
	# Conectar callback
	if not navigation_agent.velocity_computed.is_connected(_on_velocity_computed):
		navigation_agent.velocity_computed.connect(_on_velocity_computed)
	
	# Debug (ative para ver os caminhos)
	navigation_agent.debug_enabled = false
	navigation_agent.debug_use_custom = true
	navigation_agent.debug_path_custom_color = Color.RED if team == 1 else Color.CYAN
	navigation_agent.debug_path_custom_point_size = 8.0
	
	print("NavigationAgent configurado para %s" % stats.unit_name if stats else "unit")

func setup_timers() -> void:
	if not has_node("AttackTimer"):
		attack_timer = Timer.new()
		attack_timer.name = "AttackTimer"
		add_child(attack_timer)
	else:
		attack_timer = get_node("AttackTimer")
	
	attack_timer.wait_time = 1.0 / stats.attack_speed
	attack_timer.timeout.connect(_on_attack_timer_timeout)
	
	if has_node("AnimationPlayer"):
		animation_player = get_node("AnimationPlayer")

func get_max_health() -> float:
	var star_multiplier: float = stats.get_star_multiplier(star_level)
	return stats.max_health * star_multiplier

func get_attack_damage() -> float:
	var star_multiplier: float = stats.get_star_multiplier(star_level)
	var base_damage: float = stats.attack_damage * star_multiplier
	
	for buff in active_buffs:
		if buff.has("attack_multiplier"):
			base_damage *= buff.attack_multiplier
	
	return base_damage

func start_combat() -> void:
	current_state = State.IDLE
	print("%s iniciando combate (Team %d)" % [stats.unit_name, team])
	find_target()

func find_target() -> void:
	if current_state == State.DEAD:
		return
	
	var enemy_group: String = "enemy_units" if team == 0 else "player_units"
	var enemies: Array = get_tree().get_nodes_in_group(enemy_group)
	
	# Filtrar inimigos mortos
	enemies = enemies.filter(func(e): return e.current_state != State.DEAD)
	
	print("  %s procurando alvo... encontrados %d inimigos" % [stats.unit_name, enemies.size()])
	
	if enemies.is_empty():
		current_target = null
		current_state = State.IDLE
		return
	
	# APLICAR PRIORIDADE DE TARGETING
	match stats.target_priority:
		UnitStats.TargetPriority.CLOSEST:
			current_target = get_closest_enemy(enemies)
		
		UnitStats.TargetPriority.LOWEST_HP:
			enemies.sort_custom(func(a, b): return a.current_health < b.current_health)
			current_target = enemies[0]
		
		UnitStats.TargetPriority.HIGHEST_HP:
			enemies.sort_custom(func(a, b): return a.current_health > b.current_health)
			current_target = enemies[0]
		
		UnitStats.TargetPriority.LOWEST_HP_PERCENT:
			enemies.sort_custom(func(a, b): 
				var percent_a = a.current_health / a.get_max_health()
				var percent_b = b.current_health / b.get_max_health()
				return percent_a < percent_b
			)
			current_target = enemies[0]
		
		UnitStats.TargetPriority.BACKLINE:
			current_target = get_backline_enemy(enemies)
		
		UnitStats.TargetPriority.FRONTLINE:
			current_target = get_frontline_enemy(enemies)
		
		UnitStats.TargetPriority.HIGHEST_ATTACK:
			enemies.sort_custom(func(a, b): return a.get_attack_damage() > b.get_attack_damage())
			current_target = enemies[0]
		
		_:  # RANDOM ou qualquer outro
			current_target = enemies.pick_random()
	
	# VERIFICAR SE TARGET FOI DEFINIDO
	if current_target:
		print("%s mirando em %s" % [stats.unit_name, current_target.stats.unit_name])
		check_attack_or_move()
	else:
		print("%s não conseguiu definir alvo!" % stats.unit_name)
		current_target = enemies.pick_random()  # Fallback
		if current_target:
			check_attack_or_move()
			
			
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
		var distance: float = global_position.distance_to(enemy.global_position)
		if distance < min_distance:
			min_distance = distance
			closest = enemy
	
	return closest

func check_attack_or_move() -> void:
	if not is_instance_valid(current_target):
		if debug_movement:
			print("%s: alvo invalidado" % stats.unit_name)
		current_target = null
		find_target()
		return
	
	if not current_target or current_target.current_state == State.DEAD:
		if debug_movement:
			print("%s: alvo morto/inválido" % stats.unit_name)
		current_target = null
		find_target()
		return
	
	var distance: float = global_position.distance_to(current_target.global_position)
	var attack_range_meters: float = stats.attack_range * 2.0
	var range_threshold: float = attack_range_meters + 0.5
	
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
		if debug_movement:
			print("%s: MOVENDO (modo: %s)" % [
				stats.unit_name,
				"Navigation" if use_navigation else "Direto"
			])
		move_towards_target()

func move_towards_target() -> void:
	# MODO DEBUG: Movimento direto
	if not use_navigation:
		move_direct_to_target()
		return
	
	# VALIDAÇÕES
	if not is_instance_valid(current_target):
		if debug_movement:
			print("%s: alvo foi destruído!" % stats.unit_name)
		current_target = null
		find_target()
		return
	
	if not current_target:
		if debug_movement:
			print("%s: sem alvo definido!" % stats.unit_name)
		find_target()
		return
	
	if not navigation_agent:
		if debug_movement:
			print("%s: sem NavigationAgent, usando movimento direto!" % stats.unit_name)
		move_direct_to_target()
		return
	
	if current_target.current_state == State.DEAD:
		if debug_movement:
			print("%s: alvo morreu!" % stats.unit_name)
		current_target = null
		find_target()
		return
	
	# Obter posição do alvo
	var target_pos: Vector3 = current_target.global_position
	
	if debug_movement:
		print("%s -> NavAgent target: %v" % [stats.unit_name, target_pos])
	
	current_state = State.MOVING
	navigation_agent.target_position = target_pos
	
	# Aguardar cálculo do caminho
	await get_tree().physics_frame
	
	if not is_instance_valid(current_target):
		return
	
	# Verificar alcançabilidade
	var is_reachable: bool = navigation_agent.is_target_reachable()
	
	if debug_movement:
		if is_reachable:
			print("Caminho OK para %s" % stats.unit_name)
		else:
			print("Caminho BLOQUEADO para %s - usando direto" % stats.unit_name)
	
	# Se não alcançável, usar movimento direto
	if not is_reachable:
		use_navigation = false
		move_direct_to_target()
		

func _physics_process(delta: float) -> void:
	# MOVIMENTO DIRETO (sem navigation)
	if not use_navigation:
		if current_state == State.MOVING and is_instance_valid(current_target):
			move_direct_to_target()
		return
	
	# MOVIMENTO COM NAVIGATION
	if current_state != State.MOVING:
		return
	
	if not navigation_agent:
		return
	
	if not is_instance_valid(current_target):
		current_state = State.IDLE
		velocity = Vector3.ZERO
		return
	
	# Verificar se chegou
	if navigation_agent.is_navigation_finished():
		velocity = Vector3.ZERO
		current_state = State.IDLE
		
		if debug_movement:
			print("%s chegou ao destino!" % stats.unit_name)
		
		check_attack_or_move()
		return
	
	# Obter próxima posição
	var next_position: Vector3 = navigation_agent.get_next_path_position()
	var direction: Vector3 = global_position.direction_to(next_position)
	
	if debug_movement and randf() < 0.01:  # Print ocasional para não poluir
		print("%s navegando... (dist: %.2f)" % [
			stats.unit_name,
			global_position.distance_to(next_position)
		])
	
	# Movimento
	var desired_velocity: Vector3 = direction * stats.movement_speed
	
	if navigation_agent.avoidance_enabled:
		navigation_agent.velocity = desired_velocity
	else:
		velocity = desired_velocity
		move_and_slide()
	
	# Rotação
	if direction.length() > 0.1:
		var target_rotation: float = atan2(direction.x, direction.z)
		rotation.y = lerp_angle(rotation.y, target_rotation, delta * 8.0)


func _on_velocity_computed(safe_velocity: Vector3) -> void:
	if current_state == State.MOVING:
		velocity = safe_velocity
		move_and_slide()

func start_attacking() -> void:
	if current_state == State.ATTACKING:
		return
	
	current_state = State.ATTACKING
	velocity = Vector3.ZERO
	attack_timer.start()

func _on_attack_timer_timeout() -> void:
	if current_state != State.ATTACKING or not current_target:
		attack_timer.stop()
		find_target()
		return
	
	perform_attack()

func perform_attack() -> void:
	# VALIDAÇÃO
	if not is_instance_valid(current_target):
		print("Alvo destruído durante ataque!")
		current_target = null
		find_target()
		return
	
	if not current_target or current_target.current_state == State.DEAD:
		find_target()
		return
	
	look_at(current_target.global_position, Vector3.UP)
	
	if animation_player and animation_player.has_animation("attack"):
		animation_player.play("attack")
	else:
		animate_attack()
	
	var damage: float = get_attack_damage()
	
	# Verificar crítico
	var is_crit: bool = randf() < stats.critical_chance
	if is_crit:
		damage *= stats.critical_damage
		CombatFeedback.create_damage_number(current_target.global_position, damage, CombatFeedback.DamageType.CRITICAL)
	
	current_target.take_damage(damage, self)
	add_mana(stats.mana_per_attack)
	
	check_attack_or_move()

func animate_attack() -> void:
	if not model:
		return
	var tween: Tween = create_tween()
	var original_pos: Vector3 = model.position
	tween.tween_property(model, "position", original_pos + Vector3(0, 0.3, 0), 0.15)
	tween.tween_property(model, "position", original_pos, 0.15)

func take_damage(amount: float, attacker: BaseUnit3D) -> void:
	if current_state == State.DEAD:
		return
	
	var damage_reduction: float = stats.armor / (100.0 + stats.armor)
	var actual_damage: float = amount * (1.0 - damage_reduction)
	
	current_health -= actual_damage
	update_health_bar()
	
	# FEEDBACK VISUAL DE DANO
	CombatFeedback.create_damage_number(global_position, actual_damage, CombatFeedback.DamageType.DAMAGE)
	CombatFeedback.create_hit_particles(global_position, Color.RED)
	
	flash_damage()
	add_mana(stats.mana_when_hit)
	
	if current_health <= 0:
		die()

func flash_damage() -> void:
	if not model:
		return
	
	var meshes: Array = get_all_mesh_instances(model)
	for mesh in meshes:
		if mesh.material_override:
			var mat: StandardMaterial3D = mesh.material_override as StandardMaterial3D
			var original_color: Color = mat.albedo_color
			mat.albedo_color = Color.RED
			await get_tree().create_timer(0.1).timeout
			if is_instance_valid(mat):
				mat.albedo_color = original_color

func get_all_mesh_instances(node: Node) -> Array:
	var meshes: Array = []
	if node is MeshInstance3D:
		meshes.append(node)
	for child in node.get_children():
		meshes.append_array(get_all_mesh_instances(child))
	return meshes

func add_mana(amount: float) -> void:
	# Não ganhar mana se não estiver em combate
	if current_state == State.IDLE:
		return
	
	current_mana = min(current_mana + amount, stats.max_mana)
	update_mana_bar()
	
	if current_mana >= stats.max_mana:
		cast_ability()

func cast_ability() -> void:
	if not stats.ability_name or current_state == State.DEAD:
		return
	
	# IMPORTANTE: Não usar habilidade se não estiver em combate
	if current_state == State.IDLE:
		return
	
	current_state = State.CASTING
	current_mana = 0.0
	update_mana_bar()
	
	ability_cast.emit(stats.ability_name)
	
	# FEEDBACK VISUAL DE HABILIDADE
	CombatFeedback.create_ability_effect(global_position, stats.ability_name, stats.get_tier_color())
	CombatFeedback.create_hit_particles(global_position, stats.get_tier_color())
	
	print("%s usou %s!" % [stats.unit_name, stats.ability_name])
	
	apply_ability_effect()
	
	await get_tree().create_timer(0.5).timeout
	if current_state != State.DEAD:
		current_state = State.IDLE
		find_target()

func apply_ability_effect() -> void:
	if name_label:
		var tween: Tween = create_tween()
		tween.tween_property(name_label, "modulate", Color.YELLOW, 0.2)
		tween.tween_property(name_label, "modulate", Color.WHITE, 0.2)

func die() -> void:
	current_state = State.DEAD
	current_health = 0
	attack_timer.stop()
	
	print("%s morreu!" % stats.unit_name)
	
	# Limpar referências
	current_target = null
	
	# Notificar todas as unidades que estavam mirando nesta
	var all_units: Array = get_tree().get_nodes_in_group("units")
	for unit in all_units:
		if unit is BaseUnit3D and unit.current_target == self:
			unit.current_target = null
	
	died.emit(self)
	
	if team == 0:
		visible = false
		process_mode = Node.PROCESS_MODE_DISABLED
		collision_layer = 0 
		collision_mask = 0
	else: 
		var tween: Tween = create_tween()
		tween.set_parallel(true)
		if model:
			tween.tween_property(model, "scale", Vector3.ZERO, 0.5)
		tween.tween_property(self, "position:y", position.y - 2, 0.5)
		tween.chain().tween_callback(queue_free)
	

func revive_at_position(world_pos: Vector3) -> void:
	current_state = State.IDLE
	current_health = get_max_health()
	current_mana = stats.starting_mana
	current_target = null
	velocity = Vector3.ZERO
	
	visible = true
	process_mode = Node.PROCESS_MODE_INHERIT
	collision_layer = 1
	collision_mask = 1
	global_position = world_pos
	
	if model:
		model.scale = Vector3.ONE * (1.0 + (star_level - 1) * 0.15)
	
	update_health_bar()
	update_mana_bar()

func update_health_bar() -> void:
	update_stats_display()  # Atualizar labels ao invés de barras
	health_changed.emit(current_health, get_max_health())

func update_mana_bar() -> void:
	update_stats_display()  # Atualizar labels ao invés de barras
	mana_changed.emit(current_mana, stats.max_mana)

func _process(delta: float) -> void:
	# Só regenerar mana durante combate
	if current_state != State.DEAD and current_state != State.IDLE and stats.mana_per_second > 0:
		add_mana(stats.mana_per_second * delta)
