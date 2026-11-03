class_name SabiaLaranjeiraAbility
extends "res://Scripts/Abilities/unit_ability.gd"

func execute(unit: BaseUnit3D, _scale_multiplier: float = 1.0) -> bool:
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

	CombatFeedback.create_status_indicator(unit, "BICADA", 1.2)
	CombatFeedback.create_hit_particles(unit.global_position, Color("#fb923c"))

	var damage := (unit.stats.ability_damage if unit.stats.ability_damage > 0.0 else 95.0) * unit.stats.get_star_multiplier(unit.star_level)
	var buff_dur := unit.stats.ability_duration if unit.stats.ability_duration > 0.0 else 4.0
	unit.apply_speed_buff(buff_dur, 1.35, "+VELOCIDADE")

	if is_instance_valid(target):
		var target_pos := target.global_position
		target.take_damage(damage, unit, UnitStats.DamageType.PHYSICAL)
		CombatFeedback.create_hit_particles(target_pos, Color("#fb923c"))
		CombatFeedback.create_hit_particles(target_pos + Vector3.UP * 0.5, Color("#ea580c"))
		unit._execute_swoop_advance_and_return(target_pos, Color("#fb923c"), "BICADA")

	return true
