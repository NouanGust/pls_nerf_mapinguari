class_name OncaPintadaAbility
extends "res://Scripts/Abilities/unit_ability.gd"

## Habilidade Bespoke: Bote de Emboscada (Onça Pintada)

func execute(unit: BaseUnit3D, _scale_multiplier: float = 1.0) -> bool:
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

	CombatFeedback.create_hit_particles(unit.global_position, Color("#f59e0b"))
	CombatFeedback.create_hit_particles(unit.global_position + Vector3.UP * 0.5, Color("#b45309"))

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

	var start_leap_pos := unit.global_position
	var leap_tw := unit.create_tween()
	leap_tw.tween_method(func(prog: float) -> void:
		if is_instance_valid(unit) and unit.current_state != BaseUnit3D.State.DEAD:
			unit.global_position = start_leap_pos.lerp(landing_pos, prog)
			if unit.model:
				unit.model.position.y = sin(prog * PI) * 0.7
	, 0.0, 1.0, 0.22).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

	leap_tw.tween_callback(func() -> void:
		if not is_instance_valid(unit) or unit.current_state == BaseUnit3D.State.DEAD:
			return
		unit.global_position = landing_pos
		if unit.model:
			unit.model.position.y = 0.0
		unit._face_target()

		CombatFeedback.create_status_indicator(unit, "BOTE DE EMBOSCADA", 1.2)
		CombatFeedback.create_hit_particles(unit.global_position, Color("#f59e0b"))
		CombatFeedback.create_hit_particles(unit.global_position + Vector3.UP * 0.6, Color("#dc2626"))

		if is_instance_valid(target) and target.current_state != BaseUnit3D.State.DEAD:
			var damage: float = unit.stats.ability_damage * unit.stats.get_star_multiplier(unit.star_level)
			CombatFeedback.create_damage_number(target.global_position, damage, CombatFeedback.DamageType.CRITICAL)
			target.take_damage(damage, unit, UnitStats.DamageType.PHYSICAL)

			if is_instance_valid(target) and target.current_state != BaseUnit3D.State.DEAD:
				target.apply_burn(3.0, unit, damage * 0.12)
				target.apply_stun(1.0, "ATORDOADO")
				unit.current_target = target
			else:
				unit.current_target = null
				unit.find_target()
		else:
			unit.current_target = null
			unit.find_target()
	)

	return true
