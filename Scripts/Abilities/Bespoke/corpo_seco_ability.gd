class_name CorpoSecoAbility
extends "res://Scripts/Abilities/unit_ability.gd"

## Habilidade Bespoke: Drenagem Vital (Corpo Seco)

func execute(unit: BaseUnit3D, _scale_multiplier: float = 1.0) -> bool:
	if unit.model:
		var tw := unit.create_tween()
		tw.tween_property(unit.model, "scale", unit.model_base_scale * Vector3(1.15, 1.25, 1.15), 0.15).set_trans(Tween.TRANS_QUAD)
		tw.tween_property(unit.model, "scale", unit.model_base_scale, 0.2).set_trans(Tween.TRANS_BOUNCE)

	CombatFeedback.create_status_indicator(unit, "DRENAGEM VITAL", 1.2)
	CombatFeedback.create_hit_particles(unit.global_position, Color("#15803d"))
	CombatFeedback.create_hit_particles(unit.global_position + Vector3.UP * 0.6, Color("#581c87"))

	var duration: float = unit.stats.ability_duration if unit.stats.ability_duration > 0.0 else 4.0
	var total_damage: float = (unit.stats.ability_damage if unit.stats.ability_damage > 0.0 else 120.0) * unit.stats.get_star_multiplier(unit.star_level)
	var total_heal: float = (unit.stats.ability_heal if unit.stats.ability_heal > 0.0 else 80.0) * unit.stats.get_star_multiplier(unit.star_level)
	var radius: float = unit.stats.ability_range if unit.stats.ability_range > 0.0 else 2.5

	_run_corpo_seco_drain_pulses(unit, duration, total_damage / 4.0, total_heal / 4.0, radius)
	return true

func _run_corpo_seco_drain_pulses(unit: BaseUnit3D, duration: float, tick_damage: float, tick_heal: float, radius: float) -> void:
	var pulses := int(duration)
	for p in range(pulses):
		await unit.get_tree().create_timer(1.0, false).timeout
		if not is_instance_valid(unit) or unit.current_state == BaseUnit3D.State.DEAD:
			break
		var enemy_group := "enemy_units" if unit.team == 0 else "player_units"
		var drained_count := 0
		for enemy_node: Node in unit.get_tree().get_nodes_in_group(enemy_group):
			var enemy := enemy_node as BaseUnit3D
			if not is_instance_valid(enemy) or enemy.current_state == BaseUnit3D.State.DEAD or not enemy.visible or enemy.is_on_bench():
				continue
			var dist: float = Vector2(unit.global_position.x, unit.global_position.z).distance_to(Vector2(enemy.global_position.x, enemy.global_position.z))
			if dist <= radius:
				var enemy_pos := enemy.global_position
				enemy.take_damage(tick_damage, unit, UnitStats.DamageType.TRUE)
				if is_instance_valid(enemy) and enemy.current_state != BaseUnit3D.State.DEAD:
					enemy.apply_slow(1.5)
				CombatFeedback.create_hit_particles(enemy_pos, Color("#581c87"))
				drained_count += 1

		if drained_count > 0 and is_instance_valid(unit) and unit.current_state != BaseUnit3D.State.DEAD:
			var healed: float = unit.heal(tick_heal * float(drained_count), unit)
			if healed > 0.0:
				CombatFeedback.create_status_indicator(unit, "+%d HP" % int(healed), 0.8)
				CombatFeedback.create_hit_particles(unit.global_position, Color("#22c55e"))
