class_name CombatActionComponent
extends Node

## Componente de Execução de Ataques e Projéteis de Unidade

var unit: BaseUnit3D

func setup(p_unit: BaseUnit3D) -> void:
	unit = p_unit

func start_attacking() -> void:
	if not unit:
		return
	if unit.current_state == unit.State.DEAD or unit.current_state == unit.State.CASTING or unit.is_on_bench() or unit.is_stunned():
		return
	if not is_instance_valid(unit.current_target) or unit.current_target.current_state == unit.State.DEAD or unit.current_target.is_on_bench():
		unit.current_target = null
		unit.current_state = unit.State.IDLE
		unit.find_target()
		return
	if unit.current_state == unit.State.ATTACKING:
		if unit.attack_timer and unit.attack_timer.is_stopped():
			unit.attack_timer.start()
		return
	
	unit.current_state = unit.State.ATTACKING
	unit.velocity = Vector3.ZERO
	if unit.attack_timer:
		unit.attack_timer.start()

func on_attack_timer_timeout() -> void:
	if not unit:
		return
	if not unit.in_combat:
		if unit.attack_timer:
			unit.attack_timer.stop()
		unit.current_target = null
		if unit.current_state != unit.State.DEAD:
			unit.current_state = unit.State.IDLE
		return
	if unit.current_state == unit.State.DEAD or unit.is_on_bench() or unit.is_stunned():
		if unit.attack_timer:
			unit.attack_timer.stop()
		return
	if unit.current_state == unit.State.CASTING or unit.current_state == unit.State.MOVING:
		if unit.attack_timer:
			unit.attack_timer.stop()
		return
	if unit.current_state != unit.State.ATTACKING:
		if unit.attack_timer:
			unit.attack_timer.stop()
		if unit.current_state == unit.State.IDLE and unit.in_combat:
			unit.find_target()
		return
	if not is_instance_valid(unit.current_target) or unit.current_target.current_state == unit.State.DEAD or unit.current_target.is_on_bench():
		if unit.attack_timer:
			unit.attack_timer.stop()
		unit.current_target = null
		unit.current_state = unit.State.IDLE
		if unit.in_combat:
			unit.find_target()
		return
	
	perform_attack()

func perform_attack() -> void:
	if not unit or unit.is_stunned():
		return
	if not is_instance_valid(unit.current_target) or unit.current_target.is_on_bench():
		if unit.attack_timer:
			unit.attack_timer.stop()
		unit.current_target = null
		unit.current_state = unit.State.IDLE
		unit.find_target()
		return
	
	if unit.current_target.current_state == unit.State.DEAD:
		unit.current_target = null
		unit.current_state = unit.State.IDLE
		unit.find_target()
		return
	var target_distance := Vector2(unit.global_position.x, unit.global_position.z).distance_to(
		Vector2(unit.current_target.global_position.x, unit.current_target.global_position.z)
	)
	if target_distance > unit.get_attack_range_meters():
		unit.check_attack_or_move()
		return
	
	face_target()
	var ranged_attack := unit.stats.get_attack_range_hexes() > 1
	if unit.unit_visual:
		unit.unit_visual.play_attack(ranged_attack, 1.0 / unit.get_effective_attack_speed())

	var damage: float = unit.get_attack_damage()
	if not unit.first_attack_used:
		damage *= 1.0 + float(unit.synergy_bonuses.get("first_attack_bonus_pct", 0.0))
		unit.first_attack_used = true

	var crit_chance := unit.stats.critical_chance + float(unit.synergy_bonuses.get("crit_chance", 0.0))
	crit_chance += float(unit.synergy_bonuses.get("crit_after_kill", 0.0)) * mini(unit.enemies_defeated, unit.MAX_CERRADO_STACKS)
	var is_crit: bool = randf() < clampf(crit_chance, 0.0, 0.75)
	if is_crit:
		damage *= unit.stats.critical_damage * (1.0 + float(unit.synergy_bonuses.get("crit_damage_pct", 0.0)))

	var target := unit.current_target

	var apply_attack_damage := func() -> void:
		if not is_instance_valid(target) or target.current_state == target.State.DEAD or target.is_on_bench():
			return
		if is_crit:
			CombatFeedback.create_damage_number(target.global_position, damage, CombatFeedback.DamageType.CRITICAL)
		target.take_damage(damage, unit if is_instance_valid(unit) else null, UnitStats.DamageType.PHYSICAL)
		if is_instance_valid(unit) and unit.origin_runtime and is_instance_valid(target):
			unit.origin_runtime.on_basic_attack_hit(target)

	if ranged_attack:
		var p_color: Color = get_projectile_color()
		var is_dart: bool = unit.stats.unit_id in ["caapora", "arara_azul_lear", "ararinha_azul", "mutum_de_alagoas", "mandacaru"]
		var start_p: Vector3 = unit.global_position + Vector3.UP * (1.1 if unit.is_flying() else 0.75)
		var proj_speed: float = 0.32 if is_dart else 0.45
		var proj_radius: float = 0.16 if is_dart else 0.22
		var proj_arc: float = 0.45 if is_dart else 0.75
		spawn_ballistic_projectile(
			start_p,
			target,
			target.global_position + Vector3.UP * 0.7,
			p_color,
			proj_arc,
			proj_speed,
			apply_attack_damage,
			"%sAttackProj" % unit.stats.unit_id,
			proj_radius,
			is_dart
		)
	else:
		apply_attack_damage.call()

	if unit.stats and unit.stats.is_atacante_role():
		unit.consecutive_attacks = mini(unit.consecutive_attacks + 1, 10)
	var am: Node = unit.get_node_or_null("/root/AudioManager")
	if am and am.has_method("play_melee_hit"):
		am.play_melee_hit()
	unit.add_mana(unit.stats.mana_per_attack)
	
	unit.check_attack_or_move()

func face_target() -> void:
	if not unit or unit.stats.is_stationary or not is_instance_valid(unit.current_target):
		return
	var offset := unit.current_target.global_position - unit.global_position
	if Vector2(offset.x, offset.z).length_squared() > 0.0001:
		unit.rotation.y = atan2(offset.x, offset.z)

func show_plant_projectile(target_position: Vector3) -> void:
	if not unit:
		return
	spawn_ballistic_projectile(
		unit.global_position + Vector3.UP * 0.75,
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
	if not unit or not unit.stats:
		return Color.WHITE
	match unit.stats.unit_id:
		"cumacanga": return Color(1.0, 0.35, 0.05)
		"caapora": return Color(0.2, 0.9, 0.35)
		"arara_azul_lear": return Color(0.1, 0.75, 1.0)
		"ararinha_azul": return Color(0.25, 0.65, 1.0)
		"mutum_de_alagoas": return Color(0.65, 0.2, 0.9)
		"teiniagua": return Color(0.65, 0.35, 1.0)
		"mae_de_ouro": return Color(1.0, 0.85, 0.15)
		"alamoa": return Color(0.95, 0.9, 0.35)
		"papa_figo": return Color(0.45, 0.55, 0.15)
		"pequi": return Color(0.75, 0.85, 0.2)
		"guarana": return Color(0.95, 0.15, 0.2)
		"mandacaru": return Color(0.3, 0.85, 0.25)
		"vitoria_regia", "aguape": return Color(0.2, 0.85, 0.95)
		"brinco_de_princesa": return Color(0.95, 0.25, 0.65)
		"bromelia": return Color(1.0, 0.45, 0.15)
		"palmito_jucara": return Color(0.5, 0.75, 0.3)
		_: return unit.stats.get_tier_color()

func spawn_ballistic_projectile(
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
	glow.light_energy = 2.0
	glow.omni_range = 3.6
	projectile.add_child(glow)
	
	var scene_root: Node = unit.get_tree().current_scene if (unit and unit.get_tree()) else null
	if not scene_root and unit:
		scene_root = unit.get_parent()
	if not scene_root:
		return projectile
	scene_root.add_child(projectile)
	
	projectile.global_position = start_pos
	
	var flight := projectile.create_tween()
	flight.tween_method(func(progress: float) -> void:
		if is_instance_valid(projectile):
			var current_target_pos := impact_pos
			if is_instance_valid(target) and target.current_state != target.State.DEAD:
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
