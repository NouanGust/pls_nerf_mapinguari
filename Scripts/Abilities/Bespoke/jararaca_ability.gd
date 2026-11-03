extends "res://Scripts/Abilities/unit_ability.gd"

## Habilidade da Jararaca (Bote Certeiro / Assassin Strike)

func execute(unit: BaseUnit3D, scale_multiplier: float = 1.0) -> bool:
	var enemy_group := "enemy_units" if unit.team == 0 else "player_units"
	var enemies: Array = unit.get_tree().get_nodes_in_group(enemy_group).filter(func(u):
		return is_instance_valid(u) and u is BaseUnit3D and u.current_state != BaseUnit3D.State.DEAD and u.visible and not u.is_on_bench()
	)
	if enemies.is_empty():
		return false

	enemies.sort_custom(func(a: BaseUnit3D, b: BaseUnit3D) -> bool:
		return a.current_health < b.current_health
	)
	var target: BaseUnit3D = enemies[0]
	
	CombatFeedback.create_hit_particles(unit.global_position, Color("#4a154b"))
	CombatFeedback.create_hit_particles(unit.global_position + Vector3.UP * 0.5, Color("#8e44ad"))
	
	var board := unit._get_combat_board()
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
		var offset := (unit.global_position - target.global_position)
		offset.y = 0.0
		if offset.length_squared() < 0.04:
			offset = Vector3.BACK
		landing_pos = target.global_position + offset.normalized() * 1.3
	
	landing_pos.y = unit.combat_ground_height
	var start_strike_pos := unit.global_position

	var strike_tw := unit.create_tween()
	strike_tw.tween_method(func(prog: float) -> void:
		if is_instance_valid(unit) and unit.current_state != BaseUnit3D.State.DEAD:
			unit.global_position = start_strike_pos.lerp(landing_pos, prog)
			if unit.model:
				unit.model.position.y = sin(prog * PI) * 0.4
	, 0.0, 1.0, 0.18).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

	strike_tw.tween_callback(func() -> void:
		if not is_instance_valid(unit) or unit.current_state == BaseUnit3D.State.DEAD:
			return
		unit.global_position = landing_pos
		if unit.model:
			unit.model.position.y = 0.0
		if unit.navigation_agent:
			unit.navigation_agent.velocity = Vector3.ZERO
		unit.velocity = Vector3.ZERO
		
		if is_instance_valid(target):
			var look_dir := target.global_position - unit.global_position
			look_dir.y = 0.0
			if look_dir.length_squared() > 0.01:
				unit.rotation.y = atan2(look_dir.x, look_dir.z)
		
		CombatFeedback.create_hit_particles(unit.global_position, Color("#9b59b6"))
		CombatFeedback.create_hit_particles(unit.global_position + Vector3.UP * 0.6, Color("#e74c3c"))
		
		var damage: float = unit.stats.ability_damage * unit.stats.get_star_multiplier(unit.star_level) * scale_multiplier
		if damage <= 0.0:
			damage = unit.get_attack_damage() * 1.8 * scale_multiplier
		
		if is_instance_valid(target) and target.current_state != BaseUnit3D.State.DEAD:
			CombatFeedback.create_damage_number(target.global_position, damage, CombatFeedback.DamageType.CRITICAL)
			CombatFeedback.create_hit_particles(target.global_position, Color("#e74c3c"))
			target.take_damage(damage, unit, unit.stats.ability_damage_type)
			if is_instance_valid(unit):
				unit._trigger_camera_shake(0.25, 0.2)
			
			if is_instance_valid(target) and target.current_state != BaseUnit3D.State.DEAD:
				target.apply_slow(1.5)
				CombatFeedback.create_hit_particles(target.global_position, Color("#22c55e"))
				unit.current_target = target
			else:
				unit.current_target = null
				unit.find_target()
		else:
			unit.current_target = null
			unit.find_target()

		CombatFeedback.create_status_indicator(unit, "BOTE CERTEIRO", 1.2)
	)

	return true
