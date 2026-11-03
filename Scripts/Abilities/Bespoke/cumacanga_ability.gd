class_name CumacangaAbility
extends "res://Scripts/Abilities/unit_ability.gd"

## Habilidade Bespoke: Bola de Fogo & Hexágonos Flamejantes (Cumacanga)

func execute(unit: BaseUnit3D, _scale_multiplier: float = 1.0) -> bool:
	var enemy_group := "enemy_units" if unit.team == 0 else "player_units"
	var enemies: Array = unit.get_tree().get_nodes_in_group(enemy_group).filter(func(u):
		return is_instance_valid(u) and u is BaseUnit3D and u.current_state != BaseUnit3D.State.DEAD and u.visible and not u.is_on_bench()
	)
	if enemies.is_empty():
		return false

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

		var dist_to_caster := cand_pos.distance_to(Vector2(unit.global_position.x, unit.global_position.z))
		if cluster_count > max_cluster_size:
			max_cluster_size = cluster_count
			min_distance_to_caster = dist_to_caster
			best_target = candidate
		elif cluster_count == max_cluster_size and dist_to_caster < min_distance_to_caster:
			min_distance_to_caster = dist_to_caster
			best_target = candidate

	var target: BaseUnit3D = best_target
	var board := unit._get_combat_board()
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

	var glow := OmniLight3D.new()
	glow.light_color = Color(1.0, 0.23, 0.035)
	glow.light_energy = 1.6
	glow.omni_range = 3.0
	projectile.add_child(glow)

	var scene_root: Node = unit.get_tree().current_scene if unit.get_tree() else null
	if not scene_root:
		return false
	scene_root.add_child(projectile)

	var start_position := unit.global_position + Vector3.UP * 1.15
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
		_resolve_impact(unit, target, final_cell, final_position, board)
	)

	return true

func _resolve_impact(unit: BaseUnit3D, target: BaseUnit3D, impact_cell: Vector2i, impact_position: Vector3, board: Board3D) -> void:
	if not is_instance_valid(unit):
		return
	var damage: float = unit.stats.ability_damage * unit.stats.get_star_multiplier(unit.star_level)
	var burn_duration: float = unit.stats.ability_duration if unit.stats.ability_duration > 0.0 else 2.5
	var affected_cells: Array[Vector2i] = [impact_cell]
	if board:
		affected_cells.append_array(board.get_neighbors(impact_cell))
		for cell in affected_cells:
			_create_burning_hex(unit, board, cell, burn_duration)
		var enemy_group := "enemy_units" if unit.team == 0 else "player_units"
		for victim in unit.get_tree().get_nodes_in_group(enemy_group):
			if not is_instance_valid(victim) or victim.current_state == BaseUnit3D.State.DEAD or not victim.visible or victim.is_on_bench():
				continue
			var victim_cell := board.get_grid_position(board.to_local(victim.global_position))
			if victim_cell in affected_cells:
				victim.take_damage(damage, unit, unit.stats.ability_damage_type)
				victim.apply_burn(burn_duration, unit, damage * 0.15)
	else:
		if is_instance_valid(target) and target.current_state != BaseUnit3D.State.DEAD and not target.is_on_bench():
			target.take_damage(damage, unit, unit.stats.ability_damage_type)
			target.apply_burn(burn_duration, unit, damage * 0.15)

	CombatFeedback.create_hit_particles(impact_position, Color(1.0, 0.28, 0.035))

func _create_burning_hex(unit: BaseUnit3D, board: Board3D, cell: Vector2i, duration: float) -> void:
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

	if is_instance_valid(unit) and unit.get_tree():
		unit.get_tree().create_timer(duration, false).timeout.connect(fire_effect.queue_free)
	else:
		fire_effect.queue_free()
