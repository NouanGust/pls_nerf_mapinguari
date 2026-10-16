class_name BaseUnit3D
extends CharacterBody3D

@export var use_navigation: bool = true  # false = movimento direto (debug)
@export var debug_movement: bool = false  # prints de debug

## Signals
signal died(unit: BaseUnit3D)
signal health_changed(current: float, maximum: float)
signal mana_changed(current: float, maximum: float)
signal ability_cast(ability_name: String)
signal combat_metric_recorded(unit: BaseUnit3D, metric: StringName, amount: float)

## Stats
var stats: UnitStats
var current_health: float
var current_mana: float
var star_level: int = 1

## Estado de Combate
enum State { IDLE, MOVING, ATTACKING, CASTING, DEAD }
var current_state: State = State.IDLE
var current_target: BaseUnit3D = null
var invested_gold: int = 0
var synergy_bonuses: Dictionary = {}
var current_shield: float = 0.0
var enemies_defeated: int = 0
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

## Posição no Board
var board_position: Vector2i = Vector2i.ZERO
var team: int = 0
var cell_reference: GridCell3D = null
var combat_ground_height: float = 0.0

## Componentes 3D
var model: Node3D
var model_base_scale: Vector3 = Vector3.ONE
var animation_player: AnimationPlayer
var attack_timer: Timer
var _star_upgrade_tween: Tween
var _star_upgrade_base_material: Material
var _star_upgrade_effect_pending: bool = false

## UI 3D
var health_bar_3d: ProgressBar
var mana_bar_3d: ProgressBar
var name_label: Label
var hp_label: Label
var mana_label: Label
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
const UNIT_LABEL_ATLAS: Texture2D = preload("res://Assets/UI/GUI_4x.png")
const STAR_EVOLUTION_SHADER: Shader = preload("res://Assets/Shaders/star_evolution.gdshader")

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
	"""Movimento planar para o alvo, mantendo a unidade na altura do tabuleiro."""
	if not is_instance_valid(current_target) or current_target.current_state == State.DEAD:
		current_target = null
		current_state = State.IDLE
		find_target()
		return
	
	if not current_target:
		return
	
	current_state = State.MOVING
	
	var target_pos: Vector3 = current_target.global_position
	var planar_offset := Vector3(target_pos.x - global_position.x, 0.0, target_pos.z - global_position.z)
	var direction := planar_offset.normalized()
	
	if debug_movement:
		print("%s movendo DIRETO para %s (dist: %.2f)" % [
			stats.unit_name,
			current_target.stats.unit_name,
			planar_offset.length()
		])
	
	# Movimento direto
	velocity = direction * get_movement_speed()
	velocity.y = 0.0
	move_and_slide()
	global_position.y = combat_ground_height
	
	# Rotação
	if direction.length() > 0:
		var target_rotation: float = atan2(direction.x, direction.z)
		rotation.y = lerp_angle(rotation.y, target_rotation, 0.15)
	
	# Verificar se chegou perto o suficiente para atacar
	if planar_offset.length() <= (stats.attack_range * 2.0 + 0.5):
		if debug_movement:
			print("%s chegou no range de ataque!" % stats.unit_name)
		current_state = State.IDLE
		check_attack_or_move()


func initialize(unit_stats: UnitStats, star: int = 1) -> void:
	stats = unit_stats
	star_level = clampi(star, 1, 4)
	invested_gold = stats.cost
	
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
		var star_text := ""
		for _star in star_level:
			star_text += "★"
		name_label.text = "%s %s" % [stats.unit_name, star_text]
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
	var capsule_mesh := CapsuleMesh.new()
	capsule_mesh.height = 2.0
	capsule_mesh.radius = 0.4
	var mesh_instance := MeshInstance3D.new()
	mesh_instance.name = "StandardCapsule"
	mesh_instance.mesh = capsule_mesh
	mesh_instance.position.y = 1.0
	var mat := StandardMaterial3D.new()
	mat.albedo_color = get_team_display_color()
	mat.metallic = 0.15
	mat.roughness = 0.48
	if team == 1:
		mat.emission_enabled = true
		mat.emission = mat.albedo_color
		mat.emission_energy_multiplier = 0.28
	mesh_instance.material_override = mat
	_star_upgrade_base_material = mat
	model.add_child(mesh_instance)

	model_base_scale = Vector3.ONE
	model.scale = model_base_scale
	model.rotation = Vector3.ZERO
	setup_team_indicator()

func get_team_display_color() -> Color:
	var tier_color := stats.get_tier_color()
	if team != 1:
		return tier_color
	var saturated := Color.from_hsv(tier_color.h, maxf(tier_color.s, 0.78), maxf(tier_color.v, 0.92))
	return saturated.lerp(Color("#ff4b5f"), 0.28)

func _play_star_upgrade_effect() -> void:
	var capsule := model.get_node_or_null("StandardCapsule") as MeshInstance3D if model else null
	if capsule:
		if _star_upgrade_tween and _star_upgrade_tween.is_running():
			_star_upgrade_tween.kill()
		var shader_material := ShaderMaterial.new()
		shader_material.shader = STAR_EVOLUTION_SHADER
		shader_material.set_shader_parameter("base_color", get_team_display_color())
		shader_material.set_shader_parameter("burst_color", Color("#ffe28a") if team == 0 else Color("#ff7588"))
		shader_material.set_shader_parameter("flash_strength", 0.0)
		capsule.material_override = shader_material
		_star_upgrade_tween = create_tween()
		_star_upgrade_tween.tween_property(shader_material, "shader_parameter/flash_strength", 1.0, 0.16)
		_star_upgrade_tween.tween_property(shader_material, "shader_parameter/flash_strength", 0.0, 0.72)
		_star_upgrade_tween.tween_callback(func():
			if is_instance_valid(capsule) and capsule.material_override == shader_material:
				capsule.material_override = _star_upgrade_base_material
		)

	var burst := GPUParticles3D.new()
	burst.name = "StarEvolutionBurst"
	burst.position = Vector3(0.0, 1.0, 0.0)
	burst.one_shot = true
	burst.amount = 54
	burst.lifetime = 0.9
	burst.explosiveness = 0.92
	burst.speed_scale = 1.2
	var particle_process := ParticleProcessMaterial.new()
	particle_process.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	particle_process.emission_sphere_radius = 0.48
	particle_process.direction = Vector3(0.0, 1.0, 0.0)
	particle_process.spread = 180.0
	particle_process.initial_velocity_min = 1.8
	particle_process.initial_velocity_max = 4.6
	particle_process.gravity = Vector3(0.0, -2.0, 0.0)
	particle_process.damping_min = 0.25
	particle_process.damping_max = 0.8
	particle_process.scale_min = 0.045
	particle_process.scale_max = 0.12
	particle_process.color = Color("#ffe28a") if team == 0 else Color("#ff7588")
	burst.process_material = particle_process
	var spark_mesh := SphereMesh.new()
	spark_mesh.radius = 0.055
	spark_mesh.height = 0.11
	var spark_material := StandardMaterial3D.new()
	spark_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	spark_material.albedo_color = particle_process.color
	spark_material.emission_enabled = true
	spark_material.emission = particle_process.color
	spark_material.emission_energy_multiplier = 2.2
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
		
		var mat =  StandardMaterial3D.new()
		mat.albedo_color = Color("#ff4b5f")
		mat.emission_enabled = true
		mat.emission = Color("#ff334f")
		mat.emission_energy_multiplier = 2.0
		mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		
		indicator.material_override = mat
		add_child(indicator)

func setup_stats_display() -> void:
	ui_viewport = SubViewport.new()
	ui_viewport.name = "UnitLabelViewport"
	ui_viewport.size = Vector2i(144, 64)
	ui_viewport.transparent_bg = true
	ui_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(ui_viewport)

	var root := Control.new()
	root.name = "UnitLabelRoot"
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	ui_viewport.add_child(root)

	var panel_fill := ColorRect.new()
	panel_fill.color = Color(0.07, 0.055, 0.075, 0.9)
	panel_fill.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	panel_fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(panel_fill)

	var frame := NinePatchRect.new()
	frame.name = "UnitLabelFrame"
	frame.texture = UNIT_LABEL_ATLAS
	frame.region_rect = Rect2(0, 224, 128, 96)
	frame.patch_margin_left = 18
	frame.patch_margin_top = 18
	frame.patch_margin_right = 18
	frame.patch_margin_bottom = 18
	frame.draw_center = false
	frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	frame.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_child(frame)

	name_label = _make_unit_label("NameLabel", Rect2(8, 3, 128, 17), 12, Color("#f4dfb3"))
	var star_text := ""
	for _star in star_level:
		star_text += "★"
	name_label.text = "%s %s" % [stats.unit_name, star_text]
	root.add_child(name_label)

	hp_label = _make_unit_label("HPLabel", Rect2(8, 21, 62, 14), 10, Color("#f1d8c5"))
	root.add_child(hp_label)
	mana_label = _make_unit_label("ManaLabel", Rect2(74, 21, 62, 14), 10, Color("#c5ddff"))
	root.add_child(mana_label)

	health_bar_3d = _make_unit_bar("HealthBar", Rect2(9, 38, 126, 8), Color("#65bf69"))
	root.add_child(health_bar_3d)
	mana_bar_3d = _make_unit_bar("ManaBar", Rect2(9, 50, 126, 6), stats.get_tier_color())
	root.add_child(mana_bar_3d)

	ui_sprite = Sprite3D.new()
	ui_sprite.name = "UnitLabelSprite"
	ui_sprite.texture = ui_viewport.get_texture()
	ui_sprite.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	ui_sprite.no_depth_test = true
	ui_sprite.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	ui_sprite.pixel_size = 0.011
	ui_sprite.position = Vector3(0, 2.65, 0)
	add_child(ui_sprite)

	health_bar_3d.max_value = get_max_health()
	mana_bar_3d.max_value = stats.max_mana
	update_stats_display()

func _make_unit_label(label_name: String, rect: Rect2, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.name = label_name
	label.position = rect.position
	label.size = rect.size
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_outline_color", Color("#211923"))
	label.add_theme_constant_override("outline_size", 2)
	label.clip_text = true
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return label

func _make_unit_bar(bar_name: String, rect: Rect2, fill_color: Color) -> ProgressBar:
	var bar := ProgressBar.new()
	bar.name = bar_name
	bar.position = rect.position
	bar.size = rect.size
	bar.show_percentage = false
	var background := StyleBoxFlat.new()
	background.bg_color = Color("#211c28")
	background.set_border_width_all(1)
	background.border_color = Color("#594653")
	var fill := StyleBoxFlat.new()
	fill.bg_color = fill_color
	fill.set_corner_radius_all(2)
	bar.add_theme_stylebox_override("background", background)
	bar.add_theme_stylebox_override("fill", fill)
	return bar

func update_stats_display() -> void:
	if not is_instance_valid(hp_label) or not is_instance_valid(mana_label) or not is_instance_valid(health_bar_3d) or not is_instance_valid(mana_bar_3d):
		return
	var mana_percent := current_mana / maxf(stats.max_mana, 1.0)
	var hp_percent := current_health / maxf(get_max_health(), 1.0)
	hp_label.text = "HP %d" % int(current_health)
	mana_label.text = "MP %.0f%%" % (mana_percent * 100.0)
	health_bar_3d.value = current_health
	mana_bar_3d.value = current_mana
	var health_fill := health_bar_3d.get_theme_stylebox("fill") as StyleBoxFlat
	if hp_percent > 0.7:
		health_fill.bg_color = Color("#65bf69")
	elif hp_percent > 0.3:
		health_fill.bg_color = Color("#e7b84d")
	else:
		health_fill.bg_color = Color("#d85852")

	mana_label.add_theme_color_override("font_color", Color("#f5da80") if mana_percent >= 1.0 else Color("#c5ddff"))



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
	navigation_agent.max_speed = get_movement_speed()
	
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
	
	attack_timer.wait_time = 1.0 / get_effective_attack_speed()
	attack_timer.timeout.connect(_on_attack_timer_timeout)
	
	if has_node("AnimationPlayer"):
		animation_player = get_node("AnimationPlayer")

func get_max_health() -> float:
	var star_multiplier: float = stats.get_star_multiplier(star_level)
	return stats.max_health * star_multiplier * (1.0 + float(synergy_bonuses.get("max_health_pct", 0.0)))

func get_attack_damage() -> float:
	var star_multiplier: float = stats.get_star_multiplier(star_level)
	var base_damage: float = stats.attack_damage * star_multiplier
	if Time.get_ticks_msec() < attack_weakened_until_msec:
		base_damage *= attack_damage_multiplier
	
	for buff in active_buffs:
		if buff.has("attack_multiplier"):
			base_damage *= buff.attack_multiplier
	
	var damage_multiplier := 1.0 + float(synergy_bonuses.get("damage_pct", 0.0))
	if is_instance_valid(current_target):
		if current_target.marked_team == team and Time.get_ticks_msec() < current_target.mark_expires_at_msec:
			damage_multiplier += float(synergy_bonuses.get("marked_target_damage_pct", 0.0))
		if _has_ally_focusing_target(current_target):
			damage_multiplier += float(synergy_bonuses.get("focus_fire_damage_pct", 0.0))
	return base_damage * damage_multiplier

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
	if Time.get_ticks_msec() < slowed_until_msec:
		speed *= 0.7
	return maxf(speed, 0.1)

func apply_slow(duration: float) -> void:
	var resistance := clampf(float(synergy_bonuses.get("control_resist_pct", 0.0)), 0.0, 0.9)
	var adjusted_duration := duration * (1.0 - resistance)
	slowed_until_msec = maxi(slowed_until_msec, Time.get_ticks_msec() + int(adjusted_duration * 1000.0))
	if attack_timer:
		attack_timer.wait_time = 1.0 / get_effective_attack_speed()

func apply_attack_weakness(duration: float, damage_multiplier: float = 0.7) -> void:
	if current_state == State.DEAD or duration <= 0.0:
		return
	var now := Time.get_ticks_msec()
	if now >= attack_weakened_until_msec:
		attack_damage_multiplier = 1.0
	attack_damage_multiplier = minf(attack_damage_multiplier, clampf(damage_multiplier, 0.0, 1.0))
	attack_weakened_until_msec = maxi(attack_weakened_until_msec, now + int(duration * 1000.0))
	CombatFeedback.create_status_indicator(self, "ENFRAQUECIDO", duration)

func on_enemy_defeated() -> void:
	enemies_defeated += 1

func start_combat() -> void:
	combat_ground_height = global_position.y
	var shield_multiplier := 1.0 + float(synergy_bonuses.get("shield_power_pct", 0.0))
	shield_multiplier *= 1.0 + float(synergy_bonuses.get("shield_received_pct", 0.0))
	current_shield = get_max_health() * float(synergy_bonuses.get("start_shield_pct", 0.0)) * shield_multiplier
	first_attack_used = false
	first_hit_checked = false
	enemies_defeated = 0
	current_state = State.IDLE
	print("%s iniciando combate (Team %d)" % [stats.unit_name, team])
	find_target()

func find_target() -> void:
	if current_state == State.DEAD or current_state == State.CASTING:
		return
	
	var enemy_group: String = "enemy_units" if team == 0 else "player_units"
	var enemies: Array = get_tree().get_nodes_in_group(enemy_group)
	
	# Filtrar inimigos mortos
	# Unidades no banco e unidades aguardando em uma posição temporária ficam
	# ocultas. Elas não fazem parte da batalha e não podem ser escolhidas como alvo.
	enemies = enemies.filter(func(e):
		return is_instance_valid(e) and e.current_state != State.DEAD and e.visible
	)
	
	print("  %s procurando alvo... encontrados %d inimigos" % [stats.unit_name, enemies.size()])
	
	if enemies.is_empty():
		if attack_timer:
			attack_timer.stop()
		current_target = null
		current_state = State.IDLE
		velocity = Vector3.ZERO
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
		if float(synergy_bonuses.get("marked_target_damage_pct", 0.0)) > 0.0:
			var weakest := enemies[0] as BaseUnit3D
			for enemy in enemies:
				if enemy.current_health / maxf(enemy.get_max_health(), 1.0) < weakest.current_health / maxf(weakest.get_max_health(), 1.0):
					weakest = enemy
			current_target = weakest
			current_target.marked_team = team
			current_target.mark_expires_at_msec = Time.get_ticks_msec() + 3000
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
		var distance := Vector2(global_position.x, global_position.z).distance_to(
			Vector2(enemy.global_position.x, enemy.global_position.z)
		)
		if distance < min_distance:
			min_distance = distance
			closest = enemy
	
	return closest

func check_attack_or_move() -> void:
	if current_state == State.DEAD or current_state == State.CASTING:
		return
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
	
	var distance := Vector2(global_position.x, global_position.z).distance_to(
		Vector2(current_target.global_position.x, current_target.global_position.z)
	)
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
		if attack_timer:
			attack_timer.stop()
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
		use_navigation = false
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
	
	if current_state != State.MOVING:
		return
	if not is_instance_valid(current_target) or current_target.current_state == State.DEAD:
		current_target = null
		current_state = State.IDLE
		find_target()
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
		if current_state == State.MOVING:
			if not is_instance_valid(current_target) or current_target.current_state == State.DEAD:
				current_target = null
				current_state = State.IDLE
				velocity = Vector3.ZERO
				find_target()
			else:
				move_direct_to_target()
		return
	
	# MOVIMENTO COM NAVIGATION
	if current_state != State.MOVING:
		return
	
	if not navigation_agent:
		use_navigation = false
		move_direct_to_target()
		return
	
	if not is_instance_valid(current_target) or current_target.current_state == State.DEAD:
		current_target = null
		current_state = State.IDLE
		velocity = Vector3.ZERO
		find_target()
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
	# Navigation pode devolver pontos com Y diferente do piso do campo. O combate
	# acontece num único plano, portanto usa apenas X/Z e preserva a altura inicial.
	var planar_next := Vector3(next_position.x, combat_ground_height, next_position.z)
	var direction := global_position.direction_to(planar_next)
	direction.y = 0.0
	direction = direction.normalized()
	
	if debug_movement and randf() < 0.01:  # Print ocasional para não poluir
		print("%s navegando... (dist: %.2f)" % [
			stats.unit_name,
			global_position.distance_to(next_position)
		])
	
	# Movimento
	var desired_velocity: Vector3 = direction * get_movement_speed()
	desired_velocity.y = 0.0
	
	if navigation_agent.avoidance_enabled:
		navigation_agent.velocity = desired_velocity
	else:
		velocity = desired_velocity
		move_and_slide()
		global_position.y = combat_ground_height
	
	# Rotação
	if direction.length() > 0.1:
		var target_rotation: float = atan2(direction.x, direction.z)
		rotation.y = lerp_angle(rotation.y, target_rotation, delta * 8.0)


func _on_velocity_computed(safe_velocity: Vector3) -> void:
	if current_state == State.MOVING:
		velocity = safe_velocity
		velocity.y = 0.0
		move_and_slide()
		global_position.y = combat_ground_height

func get_movement_speed() -> float:
	if not stats:
		return 2.0
	var speed := stats.movement_speed / 100.0 * (1.0 + float(synergy_bonuses.get("move_speed_pct", 0.0)))
	if Time.get_ticks_msec() < slowed_until_msec:
		speed *= 0.7
	return speed

func start_attacking() -> void:
	if current_state == State.DEAD or current_state == State.CASTING:
		return
	if not is_instance_valid(current_target) or current_target.current_state == State.DEAD:
		current_target = null
		current_state = State.IDLE
		find_target()
		return
	if current_state == State.ATTACKING:
		return
	
	current_state = State.ATTACKING
	velocity = Vector3.ZERO
	if attack_timer:
		attack_timer.start()

func _on_attack_timer_timeout() -> void:
	if current_state == State.DEAD:
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
	if not is_instance_valid(current_target) or current_target.current_state == State.DEAD:
		attack_timer.stop()
		current_target = null
		current_state = State.IDLE
		find_target()
		return
	
	perform_attack()

func perform_attack() -> void:
	# VALIDAÇÃO
	if not is_instance_valid(current_target):
		print("Alvo destruído durante ataque!")
		if attack_timer:
			attack_timer.stop()
		current_target = null
		current_state = State.IDLE
		find_target()
		return
	
	if not current_target or current_target.current_state == State.DEAD:
		current_target = null
		current_state = State.IDLE
		find_target()
		return
	var target_distance := Vector2(global_position.x, global_position.z).distance_to(
		Vector2(current_target.global_position.x, current_target.global_position.z)
	)
	if target_distance > float(stats.attack_range) * 2.0 + 0.5:
		check_attack_or_move()
		return
	
	look_at(current_target.global_position, Vector3.UP)
	
	if animation_player and animation_player.has_animation("attack"):
		animation_player.play("attack")
	else:
		animate_attack()
	
	var damage: float = get_attack_damage()
	if not first_attack_used:
		damage *= 1.0 + float(synergy_bonuses.get("first_attack_bonus_pct", 0.0))
		first_attack_used = true
	
	# Verificar crítico
	var crit_chance := stats.critical_chance + float(synergy_bonuses.get("crit_chance", 0.0))
	crit_chance += float(synergy_bonuses.get("crit_after_kill", 0.0)) * enemies_defeated
	var is_crit: bool = randf() < clampf(crit_chance, 0.0, 0.75)
	if is_crit:
		damage *= stats.critical_damage * (1.0 + float(synergy_bonuses.get("crit_damage_pct", 0.0)))
		CombatFeedback.create_damage_number(current_target.global_position, damage, CombatFeedback.DamageType.CRITICAL)
	
	current_target.take_damage(damage, self, UnitStats.DamageType.PHYSICAL)
	add_mana(stats.mana_per_attack)
	
	check_attack_or_move()

func animate_attack() -> void:
	if not model:
		return
	var tween: Tween = create_tween()
	var original_pos: Vector3 = model.position
	tween.tween_property(model, "position", original_pos + Vector3(0, 0.3, 0), 0.15)
	tween.tween_property(model, "position", original_pos, 0.15)

func take_damage(amount: float, attacker: BaseUnit3D, damage_type: UnitStats.DamageType = UnitStats.DamageType.PHYSICAL) -> void:
	if current_state == State.DEAD:
		return
	if not first_hit_checked:
		first_hit_checked = true
		var dodge_chance := float(synergy_bonuses.get("dodge_first_hit_chance", 0.0))
		if dodge_chance > 0.0 and randf() < dodge_chance:
			return

	var mitigation := 0.0
	if damage_type == UnitStats.DamageType.PHYSICAL:
		var armor := stats.armor + float(synergy_bonuses.get("armor_flat", 0.0))
		mitigation = armor / (100.0 + maxf(armor, 0.0))
	elif damage_type == UnitStats.DamageType.MAGICAL:
		var magic_resist := stats.magic_resist + float(synergy_bonuses.get("magic_resist_flat", 0.0))
		mitigation = magic_resist / (100.0 + maxf(magic_resist, 0.0))
	var extra_reduction := float(synergy_bonuses.get("damage_reduction_pct", 0.0))
	if current_health / maxf(get_max_health(), 1.0) <= 0.5:
		extra_reduction += float(synergy_bonuses.get("low_health_resistance_pct", 0.0))
	mitigation = clampf(mitigation, 0.0, 0.8)
	var actual_damage: float = amount * (1.0 - mitigation) * (1.0 - clampf(extra_reduction, 0.0, 0.8))
	if actual_damage <= 0.0:
		return
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
	if current_state == State.DEAD or amount <= 0.0:
		return 0.0

	var heal_multiplier := 1.0 + float(synergy_bonuses.get("healing_received_pct", 0.0))
	if is_instance_valid(healer):
		heal_multiplier *= 1.0 + float(healer.synergy_bonuses.get("healing_power_pct", 0.0))
	if Time.get_ticks_msec() < _burn_expires_at_msec:
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
	
	var adjusted_amount := amount * (1.0 + float(synergy_bonuses.get("mana_generation_pct", 0.0)))
	current_mana = min(current_mana + adjusted_amount, stats.max_mana)
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
	# O ataque pode ter retomado (ou a unidade pode ter morrido) enquanto a
	# habilidade aguardava. Só encerra o estado se ainda for esta conjuração.
	if current_state == State.CASTING:
		current_state = State.IDLE
		find_target()

func apply_ability_effect() -> void:
	if name_label:
		var tween: Tween = create_tween()
		tween.tween_property(name_label, "modulate", Color.YELLOW, 0.2)
		tween.tween_property(name_label, "modulate", Color.WHITE, 0.2)
	if stats.unit_id == "cumacanga":
		_cast_cumacanga_fireball()
		return
	match stats.unit_id:
		"anhanga":
			_cast_anhanga_roar()
			return
		"papa_figo":
			_cast_papa_figo()
			return
		"teiniagua":
			_cast_teiniagua_orb()
			return
	_apply_ability_healing()
	_apply_ability_shield()
	_apply_ability_energy()
	if stats.cost <= 2:
		_apply_ability_damage()

func _apply_ability_shield() -> void:
	if stats.ability_shield <= 0.0:
		return
	var shield := stats.ability_shield * stats.get_star_multiplier(star_level)
	shield *= 1.0 + float(synergy_bonuses.get("shield_power_pct", 0.0))
	shield *= 1.0 + float(synergy_bonuses.get("shield_received_pct", 0.0))
	current_shield = maxf(current_shield, shield)
	CombatFeedback.create_status_indicator(self, "ESCUDO", 1.0)

func _apply_ability_energy() -> void:
	if stats.ability_mana <= 0.0:
		return
	var ally_group := "player_units" if team == 0 else "enemy_units"
	var allies: Array = get_tree().get_nodes_in_group(ally_group).filter(func(ally):
		if not is_instance_valid(ally) or ally == self or not ally.visible:
			return false
		if ally.current_state not in [State.MOVING, State.ATTACKING] or ally.current_mana >= ally.stats.max_mana:
			return false
		var distance := Vector2(global_position.x, global_position.z).distance_to(Vector2(ally.global_position.x, ally.global_position.z))
		return distance <= maxf(stats.ability_range, stats.attack_range * 2.0)
	)
	allies.sort_custom(func(a: BaseUnit3D, b: BaseUnit3D) -> bool:
		return a.current_mana / maxf(a.stats.max_mana, 1.0) < b.current_mana / maxf(b.stats.max_mana, 1.0)
	)
	for i in mini(maxi(stats.ability_targets, 1), allies.size()):
		allies[i].add_mana(stats.ability_mana)
		CombatFeedback.create_hit_particles(allies[i].global_position, Color("#80d8ea"))

func _cast_anhanga_roar() -> void:
	var duration := stats.ability_duration if stats.ability_duration > 0.0 else 4.0
	var radius := stats.ability_range if stats.ability_range > 0.0 else 3.0
	var enemy_group := "enemy_units" if team == 0 else "player_units"
	for enemy in get_tree().get_nodes_in_group(enemy_group):
		if not is_instance_valid(enemy) or enemy.current_state == State.DEAD or not enemy.visible:
			continue
		var distance := Vector2(global_position.x, global_position.z).distance_to(Vector2(enemy.global_position.x, enemy.global_position.z))
		if distance <= radius:
			enemy.apply_attack_weakness(duration, 0.7)
			CombatFeedback.create_hit_particles(enemy.global_position, Color("#8ee58b"))

func _cast_papa_figo() -> void:
	if is_instance_valid(current_target) and current_target.current_state != State.DEAD:
		current_target.take_damage(stats.ability_damage, self, stats.ability_damage_type)
		current_target.apply_attack_weakness(stats.ability_duration if stats.ability_duration > 0.0 else 5.0, 0.75)
		CombatFeedback.create_hit_particles(current_target.global_position, Color("#b8e8ff"))
	_apply_ability_healing()

func _cast_teiniagua_orb() -> void:
	if not is_instance_valid(current_target) or current_target.current_state == State.DEAD:
		return
	var target := current_target
	var target_position := target.global_position
	var enemy_group := "enemy_units" if team == 0 else "player_units"
	var enemies: Array = get_tree().get_nodes_in_group(enemy_group)
	var board := _get_combat_board()
	if board:
		var target_cell := board.get_grid_position(board.to_local(target.global_position))
		var affected_cells: Array[Vector2i] = [target_cell]
		if target_cell != Vector2i(-1, -1):
			affected_cells.append_array(board.get_neighbors(target_cell))
		for enemy in enemies:
			if not is_instance_valid(enemy) or enemy.current_state == State.DEAD or not enemy.visible:
				continue
			var enemy_cell := board.get_grid_position(board.to_local(enemy.global_position))
			if enemy_cell in affected_cells:
				enemy.take_damage(stats.ability_damage, self, stats.ability_damage_type)
	else:
		for enemy in enemies:
			if not is_instance_valid(enemy) or enemy.current_state == State.DEAD or not enemy.visible:
				continue
			var distance := Vector2(target_position.x, target_position.z).distance_to(Vector2(enemy.global_position.x, enemy.global_position.z))
			if distance <= 2.0:
				enemy.take_damage(stats.ability_damage, self, stats.ability_damage_type)
	CombatFeedback.create_hit_particles(target_position, Color("#c994ff"))

func _apply_ability_damage() -> void:
	if stats.ability_damage <= 0.0 or not is_instance_valid(current_target) or current_target.current_state == State.DEAD:
		return
	current_target.take_damage(stats.ability_damage, self, stats.ability_damage_type)

func _cast_cumacanga_fireball() -> void:
	var enemy_group := "enemy_units" if team == 0 else "player_units"
	var enemies: Array = get_tree().get_nodes_in_group(enemy_group).filter(func(unit):
		return is_instance_valid(unit) and unit is BaseUnit3D and unit.current_state != State.DEAD and unit.visible
	)
	if enemies.is_empty():
		return

	# Foca no inimigo mais distante e acompanha a posição atual durante o lançamento.
	enemies.sort_custom(func(a: BaseUnit3D, b: BaseUnit3D) -> bool:
		return global_position.distance_squared_to(a.global_position) > global_position.distance_squared_to(b.global_position)
	)
	var target: BaseUnit3D = enemies[0]
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

func _get_combat_board() -> Board3D:
	var scene_root := get_tree().current_scene
	if scene_root:
		return scene_root.get_node_or_null("board") as Board3D
	return null

func _resolve_cumacanga_impact(target: BaseUnit3D, impact_cell: Vector2i, impact_position: Vector3, board: Board3D) -> void:
	var burn_duration := stats.ability_duration if stats.ability_duration > 0.0 else 2.0
	var affected_cells: Array[Vector2i] = [impact_cell]
	if board:
		for offset in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
			var adjacent_cell = impact_cell + offset
			if board.get_cell(adjacent_cell):
				affected_cells.append(adjacent_cell)
		for cell in affected_cells:
			_create_burning_hex(board, cell, burn_duration)
		var enemy_group := "enemy_units" if team == 0 else "player_units"
		for victim in get_tree().get_nodes_in_group(enemy_group):
			if not is_instance_valid(victim) or victim.current_state == State.DEAD or not victim.visible:
				continue
			var victim_cell := board.get_grid_position(board.to_local(victim.global_position))
			if victim_cell in affected_cells:
				victim.take_damage(stats.ability_damage, self, stats.ability_damage_type)
				victim.apply_burn(burn_duration, self, stats.ability_damage * 0.15)
	else:
		if is_instance_valid(target) and target.current_state != State.DEAD:
			target.take_damage(stats.ability_damage, self, stats.ability_damage_type)
			target.apply_burn(burn_duration, self, stats.ability_damage * 0.15)
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
	get_tree().create_timer(duration).timeout.connect(fire_effect.queue_free)

func apply_burn(duration: float, source: BaseUnit3D, damage_per_tick: float) -> void:
	if current_state == State.DEAD or duration <= 0.0 or damage_per_tick <= 0.0:
		return
	_burn_generation += 1
	var generation := _burn_generation
	_burn_expires_at_msec = Time.get_ticks_msec() + int(duration * 1000.0)
	CombatFeedback.create_status_indicator(self, "QUEIMADO", duration)
	_run_burn_ticks(generation, duration, source, damage_per_tick)

func _run_burn_ticks(generation: int, duration: float, source: BaseUnit3D, damage_per_tick: float) -> void:
	var elapsed := 0.0
	while elapsed < duration and current_state != State.DEAD:
		await get_tree().create_timer(0.5).timeout
		if generation != _burn_generation or current_state == State.DEAD:
			return
		elapsed += 0.5
		take_damage(damage_per_tick, source if is_instance_valid(source) else null, UnitStats.DamageType.MAGICAL)

func _apply_ability_healing() -> void:
	if stats.ability_heal <= 0.0:
		return

	var ally_group := "player_units" if team == 0 else "enemy_units"
	var allies: Array = get_tree().get_nodes_in_group(ally_group).filter(func(ally):
		if not is_instance_valid(ally) or ally.current_state == State.DEAD or not ally.visible:
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
	var target_count := mini(maxi(stats.ability_targets, 1), allies.size())
	for i in target_count:
		allies[i].heal(stats.ability_heal, self)

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
	combat_ground_height = world_pos.y
	
	if model:
		model.scale = model_base_scale
	
	update_health_bar()
	update_mana_bar()

func update_health_bar() -> void:
	update_stats_display()  # Atualizar labels ao invés de barras
	health_changed.emit(current_health, get_max_health())

func update_mana_bar() -> void:
	update_stats_display()  # Atualizar labels ao invés de barras
	mana_changed.emit(current_mana, stats.max_mana)

func _process(delta: float) -> void:
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
