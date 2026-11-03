class_name AnhangaAbility
extends "res://Scripts/Abilities/unit_ability.gd"

func execute(unit: BaseUnit3D, _scale_multiplier: float = 1.0) -> bool:
	var duration := unit.stats.ability_duration if unit.stats.ability_duration > 0.0 else 4.0
	var radius: float = unit.stats.ability_range if unit.stats.ability_range > 0.0 else 3.0
	var weakness_mult := clampf(0.70 - float(unit.star_level - 1) * 0.10, 0.40, 0.70)
	var enemy_group := "enemy_units" if unit.team == 0 else "player_units"

	var apply_roar := func() -> void:
		if not is_instance_valid(unit):
			return
		var tree := unit.get_tree() if unit.is_inside_tree() else Engine.get_main_loop() as SceneTree
		if not tree:
			return
		for node in tree.get_nodes_in_group(enemy_group):
			var enemy: BaseUnit3D = node as BaseUnit3D
			if not is_instance_valid(enemy) or enemy.current_state == BaseUnit3D.State.DEAD or not enemy.visible or enemy.is_on_bench():
				continue
			var distance := Vector2(unit.global_position.x, unit.global_position.z).distance_to(Vector2(enemy.global_position.x, enemy.global_position.z))
			if distance <= radius:
				enemy.apply_attack_weakness(duration, weakness_mult)
				CombatFeedback.create_hit_particles(enemy.global_position, Color("#8ee58b"))
		if is_instance_valid(unit):
			unit._trigger_camera_shake(0.25, 0.2)

	if unit.model:
		var tw := unit.create_tween()
		tw.tween_property(unit.model, "scale", unit.model_base_scale * Vector3(1.3, 1.3, 1.3), 0.15).set_trans(Tween.TRANS_QUAD)
		tw.tween_callback(apply_roar)
		tw.tween_property(unit.model, "scale", unit.model_base_scale, 0.22).set_trans(Tween.TRANS_BOUNCE)
	else:
		apply_roar.call()

	return true
