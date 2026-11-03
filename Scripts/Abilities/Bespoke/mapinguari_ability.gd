class_name MapinguariAbility
extends "res://Scripts/Abilities/unit_ability.gd"

const BattleClock = preload("res://Scripts/Systems/battle_clock.gd")

func execute(unit: BaseUnit3D, _scale_multiplier: float = 1.0) -> bool:
	if unit.model:
		var tw := unit.create_tween()
		tw.tween_property(unit.model, "scale", unit.model_base_scale * Vector3(1.35, 0.7, 1.35), 0.14).set_trans(Tween.TRANS_QUAD)
		tw.tween_property(unit.model, "scale", unit.model_base_scale, 0.22).set_trans(Tween.TRANS_BOUNCE)

	CombatFeedback.create_status_indicator(unit, "RUGIDO DA FÚRIA", 1.5)
	CombatFeedback.create_hit_particles(unit.global_position, Color("#f97316"))
	CombatFeedback.create_hit_particles(unit.global_position + Vector3.UP * 0.6, Color("#ef4444"))
	unit._trigger_camera_shake(0.35, 0.3)

	var duration := unit.stats.ability_duration if unit.stats.ability_duration > 0.0 else 5.0
	unit.reflect_until_msec = BattleClock.now_msec() + int(duration * 1000.0)
	unit.reflect_pct = 0.40 * (1.0 + float(unit.star_level - 1) * 0.20)

	unit.apply_speed_buff(duration, 1.35, "+FÚRIA")
	unit.active_buffs.append({
		"attack_multiplier": 1.45,
		"expires_at_msec": BattleClock.now_msec() + int(duration * 1000.0)
	})

	var damage := (unit.stats.ability_damage if unit.stats.ability_damage > 0.0 else 350.0) * unit.stats.get_star_multiplier(unit.star_level)
	if is_instance_valid(unit.current_target) and unit.current_target.current_state != BaseUnit3D.State.DEAD and not unit.current_target.is_on_bench():
		var target := unit.current_target
		var target_pos := target.global_position
		target.take_damage(damage, unit, UnitStats.DamageType.PHYSICAL)
		CombatFeedback.create_hit_particles(target_pos, Color("#ea580c"))

	return true
