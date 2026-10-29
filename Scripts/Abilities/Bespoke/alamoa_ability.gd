class_name AlamoaAbility
extends "res://Scripts/Abilities/unit_ability.gd"

func execute(unit: BaseUnit3D, _scale_multiplier: float = 1.0) -> bool:
	if unit.model:
		var tw := unit.create_tween()
		tw.tween_property(unit.model, "scale", unit.model_base_scale * Vector3(1.15, 1.25, 1.15), 0.15).set_trans(Tween.TRANS_QUAD)
		tw.tween_property(unit.model, "scale", unit.model_base_scale, 0.2).set_trans(Tween.TRANS_BOUNCE)
	CombatFeedback.create_status_indicator(unit, "CANTO HIPNÓTICO", 1.2)
	CombatFeedback.create_hit_particles(unit.global_position, Color("#f472b6"))

	var enemy_group := "enemy_units" if unit.team == 0 else "player_units"
	var enemies: Array = unit.get_tree().get_nodes_in_group(enemy_group).filter(func(u):
		return is_instance_valid(u) and u is BaseUnit3D and u.current_state != BaseUnit3D.State.DEAD and u.visible and not u.is_on_bench()
	)
	if enemies.is_empty():
		return true

	enemies.sort_custom(func(a: BaseUnit3D, b: BaseUnit3D) -> bool:
		var dist_a := Vector2(unit.global_position.x, unit.global_position.z).distance_to(Vector2(a.global_position.x, a.global_position.z))
		var dist_b := Vector2(unit.global_position.x, unit.global_position.z).distance_to(Vector2(b.global_position.x, b.global_position.z))
		return dist_a < dist_b
	)

	var duration := (unit.stats.ability_duration if unit.stats.ability_duration > 0.0 else 3.0) * (1.0 + float(unit.star_level - 1) * 0.25)
	var damage := (unit.stats.ability_damage if unit.stats.ability_damage > 0.0 else 500.0) * unit.stats.get_star_multiplier(unit.star_level)
	var targets_count := mini(maxi(unit.stats.ability_targets, 2), enemies.size())
	for i in targets_count:
		var enemy: BaseUnit3D = enemies[i]
		var e_pos := enemy.global_position
		enemy.take_damage(damage, unit, UnitStats.DamageType.MAGICAL)
		if is_instance_valid(enemy) and enemy.current_state != BaseUnit3D.State.DEAD:
			enemy.apply_stun(duration, "HIPNOTIZADO")
		CombatFeedback.create_hit_particles(e_pos, Color("#ec4899"))

	return true
