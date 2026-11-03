class_name TeiniaguaAbility
extends "res://Scripts/Abilities/unit_ability.gd"

func execute(unit: BaseUnit3D, _scale_multiplier: float = 1.0) -> bool:
	if not is_instance_valid(unit.current_target) or unit.current_target.current_state == BaseUnit3D.State.DEAD or unit.current_target.is_on_bench():
		unit.find_target()
	var target := unit.current_target
	if not is_instance_valid(target) or target.current_state == BaseUnit3D.State.DEAD or target.is_on_bench():
		return false

	if unit.model:
		var tw := unit.create_tween()
		tw.tween_property(unit.model, "scale", unit.model_base_scale * Vector3(1.2, 1.2, 1.2), 0.15).set_trans(Tween.TRANS_QUAD)
		tw.tween_property(unit.model, "scale", unit.model_base_scale, 0.2).set_trans(Tween.TRANS_BOUNCE)

	CombatFeedback.create_status_indicator(unit, "ESFERA ARCANA", 1.2)

	var target_position := target.global_position
	var enemy_group := "enemy_units" if unit.team == 0 else "player_units"
	var damage := unit.stats.ability_damage * unit.stats.get_star_multiplier(unit.star_level)
	var board := unit._get_combat_board()
	var target_impact := target.global_position + Vector3.UP * 0.7

	var on_projectile_hit := func() -> void:
		if not is_instance_valid(unit):
			return
		var current_target_pos := target_position
		if is_instance_valid(target) and target.current_state != BaseUnit3D.State.DEAD:
			current_target_pos = target.global_position

		var current_tree := unit.get_tree() if unit.is_inside_tree() else Engine.get_main_loop() as SceneTree
		var current_enemies: Array = current_tree.get_nodes_in_group(enemy_group) if current_tree else []

		if board and is_instance_valid(target):
			var target_cell := board.get_grid_position(board.to_local(current_target_pos))
			var affected_cells: Array[Vector2i] = [target_cell]
			if target_cell != Vector2i(-1, -1):
				affected_cells.append_array(board.get_neighbors(target_cell))
			for enemy_node in current_enemies:
				var enemy: BaseUnit3D = enemy_node as BaseUnit3D
				if not is_instance_valid(enemy) or enemy.current_state == BaseUnit3D.State.DEAD or not enemy.visible or enemy.is_on_bench():
					continue
				var enemy_cell := board.get_grid_position(board.to_local(enemy.global_position))
				if enemy_cell in affected_cells:
					enemy.take_damage(damage, unit, unit.stats.ability_damage_type)
		else:
			for enemy_node in current_enemies:
				var enemy: BaseUnit3D = enemy_node as BaseUnit3D
				if not is_instance_valid(enemy) or enemy.current_state == BaseUnit3D.State.DEAD or not enemy.visible or enemy.is_on_bench():
					continue
				var distance := Vector2(current_target_pos.x, current_target_pos.z).distance_to(Vector2(enemy.global_position.x, enemy.global_position.z))
				if distance <= 2.8:
					enemy.take_damage(damage, unit, unit.stats.ability_damage_type)

		CombatFeedback.create_hit_particles(current_target_pos, Color("#c994ff"))
		CombatFeedback.create_hit_particles(current_target_pos + Vector3.UP * 0.5, Color("#f43f5e"))
		unit._trigger_camera_shake(0.3, 0.2)

	var flight_duration: float = 0.55
	unit._spawn_ballistic_projectile(
		unit.global_position + Vector3.UP * 1.1,
		target,
		target_impact,
		Color("#c084fc"),
		2.0,
		flight_duration,
		on_projectile_hit,
		"TeiniaguaArcaneOrb",
		0.28
	)
	return true
