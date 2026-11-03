class_name CabecaDeCuiaAbility
extends "res://Scripts/Abilities/unit_ability.gd"

func execute(unit: BaseUnit3D, _scale_multiplier: float = 1.0) -> bool:
	if not is_instance_valid(unit.current_target) or unit.current_target.current_state == BaseUnit3D.State.DEAD or unit.current_target.is_on_bench():
		unit.find_target()
	var target := unit.current_target
	var enemy_group := "enemy_units" if unit.team == 0 else "player_units"
	var enemies: Array = unit.get_tree().get_nodes_in_group(enemy_group).filter(func(u):
		return is_instance_valid(u) and u is BaseUnit3D and u.current_state != BaseUnit3D.State.DEAD and u.visible and not u.is_on_bench()
	)
	if not enemies.is_empty():
		enemies.sort_custom(func(a: BaseUnit3D, b: BaseUnit3D) -> bool:
			var da := Vector2(unit.global_position.x, unit.global_position.z).distance_to(Vector2(a.global_position.x, a.global_position.z))
			var db := Vector2(unit.global_position.x, unit.global_position.z).distance_to(Vector2(b.global_position.x, b.global_position.z))
			return da > db
		)
		target = enemies[0]
		unit.current_target = target

	if not is_instance_valid(target) or target.current_state == BaseUnit3D.State.DEAD or target.is_on_bench():
		return false

	if unit.model:
		var tw := unit.create_tween()
		tw.tween_property(unit.model, "position:y", 0.6, 0.15).set_trans(Tween.TRANS_QUAD)
		tw.tween_property(unit.model, "position:y", 0.0, 0.2).set_trans(Tween.TRANS_BOUNCE)

	CombatFeedback.create_status_indicator(unit, "ARRASTO AMALDIÇOADO", 1.2)
	CombatFeedback.create_hit_particles(unit.global_position, Color("#0284c7"))

	var damage := unit.stats.ability_damage * unit.stats.get_star_multiplier(unit.star_level)
	target.take_damage(damage, unit, UnitStats.DamageType.MAGICAL)

	if is_instance_valid(target) and target.current_state != BaseUnit3D.State.DEAD:
		var shred := 15.0 * unit.stats.get_star_multiplier(unit.star_level)
		target.apply_armor_shred(unit.stats.ability_duration if unit.stats.ability_duration > 0.0 else 4.0, shred)

		var pull_dir := (unit.global_position - target.global_position)
		pull_dir.y = 0.0
		if pull_dir.length_squared() > 1.0:
			var pull_dest := unit.global_position - pull_dir.normalized() * 1.3
			pull_dest.y = target.global_position.y
			var ptw := target.create_tween()
			ptw.tween_property(target, "global_position", pull_dest, 0.3).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

		CombatFeedback.create_hit_particles(target.global_position, Color("#0284c7"))
		CombatFeedback.create_hit_particles(target.global_position + Vector3.UP * 0.5, Color("#0f172a"))

	return true
