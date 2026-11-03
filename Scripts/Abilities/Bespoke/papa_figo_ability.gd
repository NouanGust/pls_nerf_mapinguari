class_name PapaFigoAbility
extends "res://Scripts/Abilities/unit_ability.gd"

func execute(unit: BaseUnit3D, _scale_multiplier: float = 1.0) -> bool:
	if not is_instance_valid(unit.current_target) or unit.current_target.current_state == BaseUnit3D.State.DEAD or unit.current_target.is_on_bench():
		unit.find_target()
	var target := unit.current_target
	if is_instance_valid(target) and not target.is_queued_for_deletion() and target.current_state != BaseUnit3D.State.DEAD and not target.is_on_bench():
		var damage := unit.stats.ability_damage * unit.stats.get_star_multiplier(unit.star_level)
		var target_impact := target.global_position + Vector3.UP * 0.75
		var start_pos := unit.global_position + Vector3.UP * 0.85
		var p_color := Color("#67e8f9")

		var on_impact := func() -> void:
			if not is_instance_valid(unit):
				return
			if is_instance_valid(target) and not target.is_queued_for_deletion() and target.current_state != BaseUnit3D.State.DEAD:
				target.take_damage(damage, unit, unit.stats.ability_damage_type)
				if is_instance_valid(target) and not target.is_queued_for_deletion() and target.current_state != BaseUnit3D.State.DEAD:
					target.apply_attack_weakness(unit.stats.ability_duration if unit.stats.ability_duration > 0.0 else 5.0, 0.75)
				CombatFeedback.create_hit_particles(target.global_position, p_color)
				CombatFeedback.create_hit_particles(target.global_position + Vector3.UP * 0.5, Color("#a5f3fc"))
				unit._trigger_camera_shake(0.25, 0.2)
			unit._apply_ability_healing()

		unit._spawn_ballistic_projectile(
			start_pos,
			target,
			target_impact,
			p_color,
			0.9,
			0.45,
			on_impact,
			"PapaFigoColdTouch",
			0.24
		)
		CombatFeedback.create_status_indicator(unit, "TOQUE GÉLIDO", 1.2)
	else:
		unit._apply_ability_healing()
	return true
