class_name QuibungoAbility
extends "res://Scripts/Abilities/unit_ability.gd"

func execute(unit: BaseUnit3D, _scale_multiplier: float = 1.0) -> bool:
	if not is_instance_valid(unit.current_target) or unit.current_target.current_state == BaseUnit3D.State.DEAD or unit.current_target.is_on_bench():
		unit.find_target()
	var target := unit.current_target
	if not is_instance_valid(target) or target.current_state == BaseUnit3D.State.DEAD or target.is_on_bench():
		return false

	CombatFeedback.create_status_indicator(unit, "SACO DAS SOMBRAS", 1.2)
	CombatFeedback.create_hit_particles(target.global_position, Color("#581c87"))

	var duration := unit.stats.ability_duration if unit.stats.ability_duration > 0.0 else 3.0
	var tick_damage := unit.stats.ability_damage * unit.stats.get_star_multiplier(unit.star_level)

	var apply_quibungo_snatch := func() -> void:
		if not is_instance_valid(unit) or not is_instance_valid(target) or target.current_state == BaseUnit3D.State.DEAD:
			return
		target.apply_stun(duration, "PRESO NO SACO")
		target.take_damage(tick_damage, unit, UnitStats.DamageType.TRUE)
		CombatFeedback.create_hit_particles(target.global_position, Color("#3b0764"))
		CombatFeedback.create_hit_particles(target.global_position + Vector3.UP * 0.5, Color("#581c87"))
		unit._trigger_camera_shake(0.25, 0.2)
		_run_ticks(unit, target, duration, tick_damage)

	if unit.model:
		var tw := unit.create_tween()
		tw.tween_property(unit.model, "scale", unit.model_base_scale * Vector3(1.2, 1.25, 1.2), 0.15).set_trans(Tween.TRANS_QUAD)
		tw.tween_callback(apply_quibungo_snatch)
		tw.tween_property(unit.model, "scale", unit.model_base_scale, 0.2).set_trans(Tween.TRANS_BOUNCE)
	else:
		apply_quibungo_snatch.call()

	return true

func _run_ticks(unit: BaseUnit3D, target: BaseUnit3D, duration: float, tick_damage: float) -> void:
	var elapsed := 1.0
	while elapsed < duration:
		await unit.get_tree().create_timer(1.0, false).timeout
		elapsed += 1.0
		if not is_instance_valid(target) or target.current_state == BaseUnit3D.State.DEAD:
			break
		var tick_pos := target.global_position
		target.take_damage(tick_damage, unit, UnitStats.DamageType.TRUE)
		CombatFeedback.create_hit_particles(tick_pos, Color("#3b0764"))
