class_name ComadreFulozinhaAbility
extends "res://Scripts/Abilities/unit_ability.gd"

## Habilidade Bespoke: Invocação da Floresta (Comadre Fulozinha)

func execute(unit: BaseUnit3D, _scale_multiplier: float = 1.0) -> bool:
	if unit.model:
		var tw := unit.create_tween()
		tw.tween_property(unit.model, "rotation:y", TAU, 0.4).from(0.0).set_trans(Tween.TRANS_QUAD)
		tw.tween_callback(func() -> void:
			if is_instance_valid(unit) and is_instance_valid(unit.model):
				unit.model.rotation.y = 0.0
			if is_instance_valid(unit) and is_instance_valid(unit.current_target) and unit.current_target.current_state != BaseUnit3D.State.DEAD:
				var offset := unit.current_target.global_position - unit.global_position
				if offset.length_squared() > 0.001:
					unit.rotation.y = atan2(offset.x, offset.z)
		)

	CombatFeedback.create_status_indicator(unit, "INVOCAÇÃO DA FLORESTA", 1.2)
	CombatFeedback.create_hit_particles(unit.global_position, Color("#22c55e"))
	CombatFeedback.create_hit_particles(unit.global_position + Vector3.UP * 0.8, Color("#f472b6"))

	var duration: float = unit.stats.ability_duration if unit.stats.ability_duration > 0.0 else 10.0
	var damage: float = (unit.stats.ability_damage if unit.stats.ability_damage > 0.0 else 45.0) * unit.stats.get_star_multiplier(unit.star_level)
	var heal_val: float = (unit.stats.ability_heal if unit.stats.ability_heal > 0.0 else 35.0) * unit.stats.get_star_multiplier(unit.star_level)

	_spawn_forest_spirits(unit, duration, damage, heal_val)
	return true

func _spawn_forest_spirits(unit: BaseUnit3D, duration: float, strike_damage: float, heal_val: float) -> void:
	var root_node := unit.get_parent()
	if not root_node:
		root_node = unit

	var spirits_container := Node3D.new()
	spirits_container.name = "ComadreSpirits"
	root_node.add_child(spirits_container)
	spirits_container.global_position = unit.global_position

	var spirit_nodes: Array[Node3D] = []
	var colors := [Color("#22c55e"), Color("#facc15")]
	for i in range(2):
		var sp := MeshInstance3D.new()
		var s_mesh := SphereMesh.new()
		s_mesh.radius = 0.2
		s_mesh.height = 0.4
		sp.mesh = s_mesh
		var s_mat := StandardMaterial3D.new()
		s_mat.albedo_color = colors[i]
		s_mat.emission_enabled = true
		s_mat.emission = colors[i]
		s_mat.emission_energy_multiplier = 2.5
		s_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		sp.material_override = s_mat
		spirits_container.add_child(sp)
		sp.position = Vector3(cos(i * PI) * 1.2, 0.8, sin(i * PI) * 1.2)
		spirit_nodes.append(sp)

	_run_forest_spirits_behavior(unit, spirits_container, spirit_nodes, duration, strike_damage, heal_val)

func _run_forest_spirits_behavior(unit: BaseUnit3D, container: Node3D, spirits: Array[Node3D], duration: float, damage: float, heal_amount: float) -> void:
	var elapsed := 0.0
	var tick_interval := 1.0
	while elapsed < duration and is_instance_valid(container) and is_instance_valid(unit) and unit.current_state != BaseUnit3D.State.DEAD:
		await unit.get_tree().create_timer(tick_interval, false).timeout
		elapsed += tick_interval
		if not is_instance_valid(container) or not is_instance_valid(unit) or unit.current_state == BaseUnit3D.State.DEAD:
			break

		container.global_position = unit.global_position

		var enemy_group := "enemy_units" if unit.team == 0 else "player_units"
		var enemies: Array = unit.get_tree().get_nodes_in_group(enemy_group).filter(func(u):
			return is_instance_valid(u) and u is BaseUnit3D and u.current_state != BaseUnit3D.State.DEAD and u.visible and not u.is_on_bench()
		)
		if not enemies.is_empty():
			enemies.sort_custom(func(a: BaseUnit3D, b: BaseUnit3D) -> bool:
				return unit.global_position.distance_to(a.global_position) < unit.global_position.distance_to(b.global_position)
			)
			var target_enemy: BaseUnit3D = enemies[0]
			target_enemy.take_damage(damage, unit, UnitStats.DamageType.MAGICAL)
			CombatFeedback.create_hit_particles(target_enemy.global_position, Color("#22c55e"))
			if spirits.size() > 0 and is_instance_valid(spirits[0]):
				var tw := spirits[0].create_tween()
				tw.tween_property(spirits[0], "position:y", 1.4, 0.15)
				tw.tween_property(spirits[0], "position:y", 0.8, 0.2)

		var ally_group := "player_units" if unit.team == 0 else "enemy_units"
		var wounded_allies: Array = unit.get_tree().get_nodes_in_group(ally_group).filter(func(a):
			return is_instance_valid(a) and a is BaseUnit3D and a.current_state != BaseUnit3D.State.DEAD and a.visible and not a.is_on_bench() and a.current_health < a.get_max_health()
		)
		if not wounded_allies.is_empty():
			wounded_allies.sort_custom(func(a: BaseUnit3D, b: BaseUnit3D) -> bool:
				return (a.get_max_health() - a.current_health) > (b.get_max_health() - b.current_health)
			)
			var ally_target: BaseUnit3D = wounded_allies[0]
			var healed := ally_target.heal(heal_amount, unit)
			if healed > 0.0:
				CombatFeedback.create_status_indicator(ally_target, "+%d HP" % int(healed), 1.0)
				CombatFeedback.create_hit_particles(ally_target.global_position, Color("#facc15"))
		elif not enemies.is_empty():
			var second_enemy: BaseUnit3D = enemies[mini(1, enemies.size() - 1)]
			second_enemy.take_damage(damage, unit, UnitStats.DamageType.MAGICAL)
			CombatFeedback.create_hit_particles(second_enemy.global_position, Color("#facc15"))

	if is_instance_valid(container):
		CombatFeedback.create_hit_particles(container.global_position + Vector3.UP * 0.8, Color("#f472b6"))
		container.queue_free()
