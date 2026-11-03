class_name PisadeiraAbility
extends "res://Scripts/Abilities/unit_ability.gd"

## Habilidade Bespoke: Pisada Fatal (Pisadeira)

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
	unit.current_target = target

	unit._trigger_camera_shake(0.4, 0.5)

	var radius: float = unit.stats.ability_range if unit.stats.ability_range > 0.0 else 3.5
	var base_dur: float = unit.stats.ability_duration if unit.stats.ability_duration > 0.0 else 2.5
	var duration: float = base_dur * (1.0 + float(unit.star_level - 1) * 0.20)
	var damage: float = (unit.stats.ability_damage if unit.stats.ability_damage > 0.0 else 520.0) * unit.stats.get_star_multiplier(unit.star_level)

	var apply_stomp := func() -> void:
		if not is_instance_valid(unit):
			return
		if is_instance_valid(target) and target.current_state != BaseUnit3D.State.DEAD:
			target.apply_stun(duration, "ESMAGADO")
			target.take_damage(damage, unit, unit.stats.ability_damage_type)
			target.current_mana = maxf(target.current_mana - 25.0, 0.0)
			target.update_mana_bar()
			CombatFeedback.create_hit_particles(target.global_position, Color("#7e22ce"))

		var current_tree := unit.get_tree() if unit.is_inside_tree() else Engine.get_main_loop() as SceneTree
		if current_tree:
			for enemy_node: Node in current_tree.get_nodes_in_group(enemy_group):
				var enemy := enemy_node as BaseUnit3D
				if not is_instance_valid(enemy) or enemy == target or enemy.current_state == BaseUnit3D.State.DEAD or not enemy.visible or enemy.is_on_bench():
					continue
				var dist: float = Vector2(unit.global_position.x, unit.global_position.z).distance_to(Vector2(enemy.global_position.x, enemy.global_position.z))
				if dist <= radius:
					enemy.apply_stun(duration * 0.6, "PARALISADO")
					enemy.take_damage(damage * 0.35, unit, unit.stats.ability_damage_type)
					enemy.current_mana = maxf(enemy.current_mana - 25.0, 0.0)
					enemy.update_mana_bar()
					CombatFeedback.create_hit_particles(enemy.global_position, Color("#7e22ce"))
					CombatFeedback.create_hit_particles(enemy.global_position + Vector3.UP * 0.6, Color("#3b0764"))

	if unit.model:
		var tw := unit.create_tween()
		tw.tween_property(unit.model, "position:y", 0.9, 0.12).set_trans(Tween.TRANS_QUAD)
		tw.tween_property(unit.model, "position:y", 0.0, 0.18).set_trans(Tween.TRANS_BOUNCE)
		tw.tween_callback(apply_stomp)
	else:
		apply_stomp.call()

	CombatFeedback.create_status_indicator(unit, "PISADA FATAL", 1.2)
	CombatFeedback.create_hit_particles(unit.global_position, Color("#7e22ce"))
	CombatFeedback.create_hit_particles(unit.global_position + Vector3.UP * 0.7, Color("#0f172a"))

	return true
