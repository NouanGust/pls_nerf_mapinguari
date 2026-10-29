class_name MinhocaoAbility
extends "res://Scripts/Abilities/unit_ability.gd"

func execute(unit: BaseUnit3D, _scale_multiplier: float = 1.0) -> bool:
	unit._trigger_camera_shake(0.55, 0.65)

	if unit.model:
		var tw := unit.create_tween()
		tw.tween_property(unit.model, "position:y", -0.35, 0.12)
		tw.tween_property(unit.model, "position:y", 0.5, 0.15)
		tw.tween_property(unit.model, "position:y", 0.0, 0.15).set_trans(Tween.TRANS_BOUNCE)

	CombatFeedback.create_status_indicator(unit, "TERREMOTO", 1.2)
	CombatFeedback.create_hit_particles(unit.global_position, Color("#78350f"))
	CombatFeedback.create_hit_particles(unit.global_position + Vector3.UP * 0.3, Color("#d97706"))

	var radius: float = unit.stats.ability_range if unit.stats.ability_range > 0.0 else 3.5
	var damage: float = unit.stats.ability_damage * unit.stats.get_star_multiplier(unit.star_level)
	var stun_dur: float = unit.stats.ability_duration if unit.stats.ability_duration > 0.0 else 2.0

	var enemy_group := "enemy_units" if unit.team == 0 else "player_units"
	for enemy_node in unit.get_tree().get_nodes_in_group(enemy_group):
		var enemy: BaseUnit3D = enemy_node as BaseUnit3D
		if not is_instance_valid(enemy) or enemy.current_state == BaseUnit3D.State.DEAD or not enemy.visible or enemy.is_on_bench():
			continue
		var dist := Vector2(unit.global_position.x, unit.global_position.z).distance_to(Vector2(enemy.global_position.x, enemy.global_position.z))
		if dist <= radius:
			var e_pos := enemy.global_position
			enemy.take_damage(damage, unit, UnitStats.DamageType.PHYSICAL)
			if is_instance_valid(enemy) and enemy.current_state != BaseUnit3D.State.DEAD:
				enemy.apply_stun(stun_dur, "ATORDOADO")
			CombatFeedback.create_hit_particles(e_pos, Color("#b45309"))

	return true
