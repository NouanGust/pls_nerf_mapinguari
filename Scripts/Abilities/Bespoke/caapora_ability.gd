class_name CaaporaAbility
extends "res://Scripts/Abilities/unit_ability.gd"

## Habilidade Bespoke: Flecha Perfurante (Caapora)

func execute(unit: BaseUnit3D, _scale_multiplier: float = 1.0) -> bool:
	if not is_instance_valid(unit.current_target) or unit.current_target.current_state == BaseUnit3D.State.DEAD or unit.current_target.is_on_bench():
		unit.find_target()
	var target := unit.current_target
	if not is_instance_valid(target) or target.current_state == BaseUnit3D.State.DEAD or target.is_on_bench():
		return false

	unit._face_target()
	CombatFeedback.create_status_indicator(unit, "FLECHA PERFURANTE", 1.2)
	CombatFeedback.create_hit_particles(unit.global_position, Color("#10b981"))

	var aim_dir := (target.global_position - unit.global_position)
	aim_dir.y = 0.0
	if aim_dir.length_squared() < 0.01:
		aim_dir = Vector3.FORWARD
	else:
		aim_dir = aim_dir.normalized()

	var max_range: float = unit.stats.ability_range if unit.stats.ability_range > 0.0 else 6.0
	var damage: float = unit.stats.ability_damage * unit.stats.get_star_multiplier(unit.star_level)
	var shred := 20.0 * unit.stats.get_star_multiplier(unit.star_level)
	var duration: float = unit.stats.ability_duration if unit.stats.ability_duration > 0.0 else 4.0

	_spawn_piercing_arrow_visual(unit, unit.global_position + Vector3.UP * 0.6, aim_dir, max_range)

	var enemy_group := "enemy_units" if unit.team == 0 else "player_units"
	var enemies: Array = unit.get_tree().get_nodes_in_group(enemy_group).filter(func(u):
		return is_instance_valid(u) and u is BaseUnit3D and u.current_state != BaseUnit3D.State.DEAD and u.visible and not u.is_on_bench()
	)

	var hit_count := 0
	var max_targets: int = unit.stats.ability_targets if unit.stats.ability_targets > 0 else 5
	enemies.sort_custom(func(a: BaseUnit3D, b: BaseUnit3D) -> bool:
		var da := (a.global_position - unit.global_position).dot(aim_dir)
		var db := (b.global_position - unit.global_position).dot(aim_dir)
		return da < db
	)

	for enemy: BaseUnit3D in enemies:
		if hit_count >= max_targets:
			break
		var to_enemy: Vector3 = enemy.global_position - unit.global_position
		to_enemy.y = 0.0
		var proj_dist: float = to_enemy.dot(aim_dir)
		if proj_dist >= 0.0 and proj_dist <= max_range:
			var lateral_offset: float = (to_enemy - aim_dir * proj_dist).length()
			if lateral_offset <= 1.35:
				enemy.take_damage(damage, unit, unit.stats.ability_damage_type)
				if hit_count == 0:
					enemy.apply_armor_shred(duration, shred)
				CombatFeedback.create_hit_particles(enemy.global_position, Color("#10b981"))
				CombatFeedback.create_hit_particles(enemy.global_position + Vector3.UP * 0.5, Color("#34d399"))
				hit_count += 1

	return true

func _spawn_piercing_arrow_visual(unit: BaseUnit3D, start_pos: Vector3, dir: Vector3, distance: float) -> void:
	var arrow := Node3D.new()
	arrow.name = "CaaporaArrow"
	var mesh_inst := MeshInstance3D.new()
	var cyl := CylinderMesh.new()
	cyl.top_radius = 0.04
	cyl.bottom_radius = 0.08
	cyl.height = 0.9
	mesh_inst.mesh = cyl
	mesh_inst.rotation.x = PI * 0.5
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color("#34d399")
	mat.emission_enabled = true
	mat.emission = Color("#10b981")
	mat.emission_energy_multiplier = 3.0
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mesh_inst.material_override = mat
	arrow.add_child(mesh_inst)

	var scene_root: Node = unit.get_tree().current_scene if unit.get_tree() else null
	if scene_root:
		scene_root.add_child(arrow)
	else:
		unit.get_parent().add_child(arrow)

	arrow.global_position = start_pos
	if dir.length_squared() > 0.01:
		arrow.look_at(start_pos + dir, Vector3.UP)
	var end_pos := start_pos + dir * distance
	var tw := arrow.create_tween()
	tw.tween_property(arrow, "global_position", end_pos, 0.28).set_trans(Tween.TRANS_LINEAR)
	tw.tween_callback(arrow.queue_free)
