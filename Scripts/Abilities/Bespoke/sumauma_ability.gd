class_name SumaumaAbility
extends "res://Scripts/Abilities/unit_ability.gd"

## Habilidade Bespoke: Raízes Guardiãs (Sumaúma)

func execute(unit: BaseUnit3D, _scale_multiplier: float = 1.0) -> bool:
	unit._trigger_camera_shake(0.45, 0.55)
	if unit.model:
		var tw := unit.create_tween()
		tw.tween_property(unit.model, "scale", unit.model_base_scale * Vector3(1.25, 0.75, 1.25), 0.15).set_trans(Tween.TRANS_QUAD)
		tw.tween_property(unit.model, "scale", unit.model_base_scale, 0.22).set_trans(Tween.TRANS_BOUNCE)

	CombatFeedback.create_status_indicator(unit, "RAÍZES GUARDIÃS", 1.2)
	CombatFeedback.create_hit_particles(unit.global_position, Color("#16a34a"))
	CombatFeedback.create_hit_particles(unit.global_position + Vector3.UP * 0.8, Color("#78350f"))

	var radius: float = unit.stats.ability_range if unit.stats.ability_range > 0.0 else 4.0
	var duration: float = unit.stats.ability_duration if unit.stats.ability_duration > 0.0 else 3.0
	var damage: float = unit.stats.ability_damage * unit.stats.get_star_multiplier(unit.star_level)
	var heal_val: float = unit.stats.ability_heal * unit.stats.get_star_multiplier(unit.star_level)
	var shield_val: float = (unit.stats.ability_shield if unit.stats.ability_shield > 0.0 else 180.0) * unit.stats.get_star_multiplier(unit.star_level)

	_create_roots_element(unit, unit.global_position, radius, duration)

	var enemy_group := "enemy_units" if unit.team == 0 else "player_units"
	for enemy_node: Node in unit.get_tree().get_nodes_in_group(enemy_group):
		var enemy := enemy_node as BaseUnit3D
		if not is_instance_valid(enemy) or enemy.current_state == BaseUnit3D.State.DEAD or not enemy.visible or enemy.is_on_bench():
			continue
		var dist: float = Vector2(unit.global_position.x, unit.global_position.z).distance_to(Vector2(enemy.global_position.x, enemy.global_position.z))
		if dist <= radius:
			enemy.apply_stun(duration, "ENRAIZADO")
			enemy.take_damage(damage, unit, UnitStats.DamageType.PHYSICAL)
			CombatFeedback.create_hit_particles(enemy.global_position, Color("#15803d"))
			CombatFeedback.create_hit_particles(enemy.global_position + Vector3.UP * 0.4, Color("#78350f"))

	var ally_group := "player_units" if unit.team == 0 else "enemy_units"
	for ally_node: Node in unit.get_tree().get_nodes_in_group(ally_group):
		var ally := ally_node as BaseUnit3D
		if not is_instance_valid(ally) or ally.current_state == BaseUnit3D.State.DEAD or not ally.visible or ally.is_on_bench():
			continue
		var dist: float = Vector2(unit.global_position.x, unit.global_position.z).distance_to(Vector2(ally.global_position.x, ally.global_position.z))
		if dist <= radius:
			var healed: float = ally.heal(heal_val, unit)
			ally.current_shield = maxf(ally.current_shield, shield_val)
			if healed > 0.0:
				CombatFeedback.create_status_indicator(ally, "+%d HP" % int(healed), 1.2)
			CombatFeedback.create_hit_particles(ally.global_position, Color("#22c55e"))

	return true

func _create_roots_element(unit: BaseUnit3D, center_pos: Vector3, radius: float, duration: float) -> void:
	var scene_root: Node = unit.get_tree().current_scene if unit.get_tree() else null
	if not scene_root:
		scene_root = unit.get_parent()
	if not scene_root:
		return

	var roots_node := Node3D.new()
	roots_node.name = "SumaumaRootsVisual"
	scene_root.add_child(roots_node)
	roots_node.global_position = center_pos

	var bark_mat := StandardMaterial3D.new()
	bark_mat.albedo_color = Color("#3f2e18")
	bark_mat.emission_enabled = true
	bark_mat.emission = Color("#15803d")
	bark_mat.emission_energy_multiplier = 0.9

	for i in 6:
		var angle := (TAU / 6.0) * float(i) + 0.3
		var pillar := MeshInstance3D.new()
		var cyl := CylinderMesh.new()
		cyl.bottom_radius = 0.26
		cyl.top_radius = 0.10
		cyl.height = 1.6
		pillar.mesh = cyl
		pillar.material_override = bark_mat
		var local_x := cos(angle) * (radius * 0.65)
		var local_z := sin(angle) * (radius * 0.65)
		pillar.position = Vector3(local_x, -1.0, local_z)
		pillar.rotation = Vector3(sin(angle) * 0.25, angle, -cos(angle) * 0.25)
		roots_node.add_child(pillar)

		var tw_pillar := roots_node.create_tween()
		tw_pillar.tween_property(pillar, "position:y", 0.65, 0.3 + float(i) * 0.04).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tw_pillar.tween_interval(maxf(duration - 0.6, 0.1))
		tw_pillar.tween_property(pillar, "position:y", -1.2, 0.3).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)

	var light := OmniLight3D.new()
	light.light_color = Color("#16a34a")
	light.light_energy = 1.6
	light.omni_range = maxf(radius * 1.6, 5.0)
	light.position = Vector3.UP * 1.0
	roots_node.add_child(light)

	var lifetime := roots_node.create_tween()
	lifetime.tween_interval(duration + 0.4)
	lifetime.tween_callback(roots_node.queue_free)
