class_name MatintaPereraAbility
extends "res://Scripts/Abilities/unit_ability.gd"

const BattleClock = preload("res://Scripts/Systems/battle_clock.gd")

func execute(unit: BaseUnit3D, _scale_multiplier: float = 1.0) -> bool:
	var duration := unit.stats.ability_duration if unit.stats.ability_duration > 0.0 else 3.0
	unit.immune_until_msec = BattleClock.now_msec() + int(duration * 1000.0)

	if not is_instance_valid(unit.current_target) or unit.current_target.current_state == BaseUnit3D.State.DEAD or unit.current_target.is_on_bench():
		unit.find_target()
	var target := unit.current_target
	if not is_instance_valid(target) or target.current_state == BaseUnit3D.State.DEAD or target.is_on_bench():
		var enemy_group := "enemy_units" if unit.team == 0 else "player_units"
		var candidates: Array = unit.get_tree().get_nodes_in_group(enemy_group).filter(func(u):
			return is_instance_valid(u) and u is BaseUnit3D and u.current_state != BaseUnit3D.State.DEAD and not u.is_on_bench()
		)
		if not candidates.is_empty():
			target = candidates[0]
			unit.current_target = target

	CombatFeedback.create_status_indicator(unit, "FORMA DE PÁSSARO", 1.2)
	CombatFeedback.create_hit_particles(unit.global_position, Color("#7c3aed"))
	CombatFeedback.create_hit_particles(unit.global_position + Vector3.UP * 0.8, Color("#1e1b4b"))

	var damage := (unit.stats.ability_damage if unit.stats.ability_damage > 0.0 else 140.0) * unit.stats.get_star_multiplier(unit.star_level)

	if is_instance_valid(target):
		var target_pos := target.global_position
		var on_apex_hit := func() -> void:
			if is_instance_valid(target) and target.current_state != BaseUnit3D.State.DEAD:
				target.take_damage(damage, unit if is_instance_valid(unit) else null, UnitStats.DamageType.MAGICAL)
				if is_instance_valid(target) and target.current_state != BaseUnit3D.State.DEAD:
					target.apply_stun(2.5, "CONFUSO")
				CombatFeedback.create_hit_particles(target.global_position, Color("#a855f7"))
				CombatFeedback.create_hit_particles(target.global_position + Vector3.UP * 0.6, Color("#3b0764"))

			var raw_range = unit.stats.get("ability_range") if (is_instance_valid(unit) and unit.stats) else null
			var radius: float = float(raw_range) if raw_range != null and float(raw_range) > 0.0 else 3.0
			var current_tree := unit.get_tree() if (is_instance_valid(unit) and unit.is_inside_tree()) else Engine.get_main_loop() as SceneTree
			if current_tree:
				var enemy_grp := "enemy_units" if (is_instance_valid(unit) and unit.team == 0) else "player_units"
				for enemy_node: Node in current_tree.get_nodes_in_group(enemy_grp):
					var enemy := enemy_node as BaseUnit3D
					if not is_instance_valid(enemy) or enemy == target or enemy.current_state == BaseUnit3D.State.DEAD or not enemy.visible or enemy.is_on_bench():
						continue
					var dist: float = Vector2(target_pos.x, target_pos.z).distance_to(Vector2(enemy.global_position.x, enemy.global_position.z))
					if dist <= radius:
						var e_pos := enemy.global_position
						enemy.take_damage(damage * 0.5, unit if is_instance_valid(unit) else null, UnitStats.DamageType.MAGICAL)
						CombatFeedback.create_hit_particles(e_pos, Color("#a855f7"))

		unit._execute_swoop_advance_and_return(target_pos, Color("#7c3aed"), "CONFUSO", on_apex_hit)

	return true
