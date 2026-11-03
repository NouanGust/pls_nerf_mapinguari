class_name AraucariaAbility
extends "res://Scripts/Abilities/unit_ability.gd"

## Habilidade Bespoke: Copa Protetora (Araucária)

func execute(unit: BaseUnit3D, _scale_multiplier: float = 1.0) -> bool:
	if unit.model:
		var tw := unit.create_tween()
		tw.tween_property(unit.model, "scale", unit.model_base_scale * Vector3(1.22, 1.3, 1.22), 0.16).set_trans(Tween.TRANS_QUAD)
		tw.tween_property(unit.model, "scale", unit.model_base_scale, 0.22).set_trans(Tween.TRANS_BOUNCE)

	CombatFeedback.create_status_indicator(unit, "COPA PROTETORA", 1.2)
	CombatFeedback.create_hit_particles(unit.global_position, Color("#15803d"))
	CombatFeedback.create_hit_particles(unit.global_position + Vector3.UP * 0.8, Color("#854d0e"))

	var shield_amount := (unit.stats.ability_shield if unit.stats.ability_shield > 0.0 else 260.0) * unit.stats.get_star_multiplier(unit.star_level)
	shield_amount *= 1.0 + float(unit.synergy_bonuses.get("shield_power_pct", 0.0))
	unit.set_shield_with_source(maxf(unit.current_shield, shield_amount), BaseUnit3D.ShieldSource.SELF)

	var radius: float = unit.stats.ability_range if unit.stats.ability_range > 0.0 else 3.0
	_create_canopy_element(unit, unit.global_position, radius, 4.0)

	var ally_group := "player_units" if unit.team == 0 else "enemy_units"
	for ally_node: Node in unit.get_tree().get_nodes_in_group(ally_group):
		var ally := ally_node as BaseUnit3D
		if not is_instance_valid(ally) or ally == unit or ally.current_state == BaseUnit3D.State.DEAD or not ally.visible or ally.is_on_bench():
			continue
		var dist: float = Vector2(unit.global_position.x, unit.global_position.z).distance_to(Vector2(ally.global_position.x, ally.global_position.z))
		if dist <= radius:
			var ally_shield := shield_amount * 0.85
			var source = BaseUnit3D.ShieldSource.PLAYER if unit.team == 0 else BaseUnit3D.ShieldSource.ENEMY
			ally.set_shield_with_source(maxf(ally.current_shield, ally_shield), source)
			CombatFeedback.create_hit_particles(ally.global_position, Color("#15803d"))
			CombatFeedback.create_status_indicator(ally, "COPA PROTETORA", 1.2)

	return true

func _create_canopy_element(unit: BaseUnit3D, center_pos: Vector3, radius: float, duration: float) -> void:
	var scene_root: Node = unit.get_tree().current_scene if unit.get_tree() else null
	if not scene_root:
		scene_root = unit.get_parent()
	if not scene_root:
		return

	var canopy := Node3D.new()
	canopy.name = "AraucariaCanopyVisual"
	scene_root.add_child(canopy)
	canopy.global_position = center_pos

	var root_mat := StandardMaterial3D.new()
	root_mat.albedo_color = Color("#78350f")
	root_mat.emission_enabled = true
	root_mat.emission = Color("#15803d")
	root_mat.emission_energy_multiplier = 0.8

	var leaf_mat := StandardMaterial3D.new()
	leaf_mat.albedo_color = Color("#16a34a")
	leaf_mat.emission_enabled = true
	leaf_mat.emission = Color("#22c55e")
	leaf_mat.emission_energy_multiplier = 1.2
	leaf_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED

	for i in 6:
		var angle := (TAU / 6.0) * float(i)
		var arch := MeshInstance3D.new()
		var cyl := CylinderMesh.new()
		cyl.top_radius = 0.08
		cyl.bottom_radius = 0.18
		cyl.height = 1.6
		arch.mesh = cyl
		arch.material_override = root_mat
		arch.position = Vector3(cos(angle) * (radius * 0.7), 0.7, sin(angle) * (radius * 0.7))
		arch.rotation = Vector3(sin(angle) * 0.35, angle, cos(angle) * 0.35)
		canopy.add_child(arch)

		var foliage := MeshInstance3D.new()
		var prism := PrismMesh.new()
		prism.size = Vector3(0.5, 0.6, 0.5)
		foliage.mesh = prism
		foliage.material_override = leaf_mat
		foliage.position = arch.position + Vector3.UP * 0.7
		foliage.rotation.y = angle
		canopy.add_child(foliage)

	var light := OmniLight3D.new()
	light.light_color = Color("#22c55e")
	light.light_energy = 1.4
	light.omni_range = maxf(radius * 1.5, 4.0)
	light.position = Vector3.UP * 1.2
	canopy.add_child(light)

	canopy.scale = Vector3(0.1, 0.1, 0.1)
	var tw := canopy.create_tween()
	tw.tween_property(canopy, "scale", Vector3.ONE, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_interval(maxf(duration - 0.5, 0.1))
	tw.tween_property(canopy, "scale", Vector3(0.01, 0.01, 0.01), 0.25).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tw.tween_callback(canopy.queue_free)
