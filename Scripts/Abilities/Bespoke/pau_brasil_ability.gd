class_name PauBrasilAbility
extends "res://Scripts/Abilities/unit_ability.gd"

## Habilidade Bespoke: Florada Dourada (Pau-Brasil)

func execute(unit: BaseUnit3D, _scale_multiplier: float = 1.0) -> bool:
	var radius: float = unit.stats.ability_range if unit.stats.ability_range > 0.0 else 3.0
	var duration: float = unit.stats.ability_duration if unit.stats.ability_duration > 0.0 else 4.0
	var damage: float = unit.stats.ability_damage * unit.stats.get_star_multiplier(unit.star_level)
	var shield_val: float = (unit.stats.ability_shield if unit.stats.ability_shield > 0.0 else 170.0) * unit.stats.get_star_multiplier(unit.star_level)

	var apply_bloom_effects := func() -> void:
		if not is_instance_valid(unit):
			return
		_create_bloom_element(unit, unit.global_position, radius, duration)

		var tree := unit.get_tree() if unit.is_inside_tree() else Engine.get_main_loop() as SceneTree
		if not tree:
			return

		var enemy_group := "enemy_units" if unit.team == 0 else "player_units"
		for enemy_node: Node in tree.get_nodes_in_group(enemy_group):
			var enemy := enemy_node as BaseUnit3D
			if not is_instance_valid(enemy) or enemy.current_state == BaseUnit3D.State.DEAD or not enemy.visible or enemy.is_on_bench():
				continue
			var dist: float = Vector2(unit.global_position.x, unit.global_position.z).distance_to(Vector2(enemy.global_position.x, enemy.global_position.z))
			if dist <= radius:
				enemy.take_damage(damage, unit, unit.stats.ability_damage_type)
				enemy.apply_attack_weakness(duration, 0.70)
				CombatFeedback.create_hit_particles(enemy.global_position, Color("#fbbf24"))

		var ally_group := "player_units" if unit.team == 0 else "enemy_units"
		for ally_node: Node in tree.get_nodes_in_group(ally_group):
			var ally := ally_node as BaseUnit3D
			if not is_instance_valid(ally) or ally.current_state == BaseUnit3D.State.DEAD or not ally.visible or ally.is_on_bench():
				continue
			var dist: float = Vector2(unit.global_position.x, unit.global_position.z).distance_to(Vector2(ally.global_position.x, ally.global_position.z))
			if dist <= radius:
				ally.current_shield = maxf(ally.current_shield, shield_val)
				CombatFeedback.create_status_indicator(ally, "FLORADA", 1.2)
				CombatFeedback.create_hit_particles(ally.global_position, Color("#fbbf24"))

		if is_instance_valid(unit):
			unit._trigger_camera_shake(0.25, 0.2)

	if unit.model:
		var tw := unit.create_tween()
		tw.tween_property(unit.model, "scale", unit.model_base_scale * Vector3(1.2, 1.25, 1.2), 0.15).set_trans(Tween.TRANS_QUAD)
		tw.tween_callback(apply_bloom_effects)
		tw.tween_property(unit.model, "scale", unit.model_base_scale, 0.22).set_trans(Tween.TRANS_BOUNCE)
	else:
		apply_bloom_effects.call()

	CombatFeedback.create_status_indicator(unit, "FLORADA DOURADA", 1.2)
	CombatFeedback.create_hit_particles(unit.global_position, Color("#fbbf24"))
	CombatFeedback.create_hit_particles(unit.global_position + Vector3.UP * 0.8, Color("#dc2626"))

	return true

func _create_bloom_element(unit: BaseUnit3D, center_pos: Vector3, radius: float, duration: float) -> void:
	var scene_root: Node = unit.get_tree().current_scene if unit.get_tree() else null
	if not scene_root:
		scene_root = unit.get_parent()
	if not scene_root:
		return

	var bloom := Node3D.new()
	bloom.name = "PauBrasilBloomVisual"
	scene_root.add_child(bloom)
	bloom.global_position = center_pos + Vector3.UP * 0.05

	var gold_mat := StandardMaterial3D.new()
	gold_mat.albedo_color = Color("#f59e0b")
	gold_mat.emission_enabled = true
	gold_mat.emission = Color("#fbbf24")
	gold_mat.emission_energy_multiplier = 1.8
	gold_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED

	var center_disk := MeshInstance3D.new()
	var cyl := CylinderMesh.new()
	cyl.top_radius = 0.4
	cyl.bottom_radius = 0.4
	cyl.height = 0.06
	center_disk.mesh = cyl
	center_disk.material_override = gold_mat
	bloom.add_child(center_disk)

	for i in 8:
		var angle := (TAU / 8.0) * float(i)
		var petal := MeshInstance3D.new()
		var p_mesh := BoxMesh.new()
		p_mesh.size = Vector3(0.35, 0.04, radius * 0.5)
		petal.mesh = p_mesh
		petal.material_override = gold_mat
		petal.position = Vector3(cos(angle) * (radius * 0.3), 0.02, sin(angle) * (radius * 0.3))
		petal.rotation.y = angle
		bloom.add_child(petal)

	var light := OmniLight3D.new()
	light.light_color = Color("#fbbf24")
	light.light_energy = 1.8
	light.omni_range = maxf(radius * 1.5, 4.5)
	light.position = Vector3.UP * 0.5
	bloom.add_child(light)

	bloom.scale = Vector3(0.01, 0.01, 0.01)
	var tw := bloom.create_tween()
	tw.set_parallel(true)
	tw.tween_property(bloom, "scale", Vector3.ONE, 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(bloom, "rotation:y", PI * 0.75, duration)

	var tw_seq := bloom.create_tween()
	tw_seq.tween_interval(maxf(duration - 0.4, 0.1))
	tw_seq.tween_property(bloom, "scale", Vector3(0.01, 0.01, 0.01), 0.35).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tw_seq.tween_callback(bloom.queue_free)
