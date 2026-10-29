class_name TargetingComponent
extends Node

## Componente de Busca e Seleção de Alvos para Combate Auto-Chess

const BattleClock = preload("res://Scripts/Systems/battle_clock.gd")

static func filter_valid_enemies(enemies: Array) -> Array[BaseUnit3D]:
	var valid: Array[BaseUnit3D] = []
	for e in enemies:
		if is_instance_valid(e) and not e.is_queued_for_deletion():
			var u := e as BaseUnit3D
			if u and u.current_state != BaseUnit3D.State.DEAD and u.visible and not u.is_on_bench():
				valid.append(u)
	return valid

static func get_closest_enemy(from_position: Vector3, enemies: Array) -> BaseUnit3D:
	var closest: BaseUnit3D = null
	var min_dist: float = INF
	var from_2d := Vector2(from_position.x, from_position.z)

	for e in enemies:
		var u := e as BaseUnit3D
		if not is_instance_valid(u):
			continue
		var dist := from_2d.distance_to(Vector2(u.global_position.x, u.global_position.z))
		if dist < min_dist:
			min_dist = dist
			closest = u

	return closest

static func get_lowest_hp_enemy(from_position: Vector3, enemies: Array) -> BaseUnit3D:
	var lowest: BaseUnit3D = null
	var min_hp: float = INF
	var closest_dist: float = INF
	var from_2d := Vector2(from_position.x, from_position.z)

	for e in enemies:
		var u := e as BaseUnit3D
		if not is_instance_valid(u):
			continue
		var hp: float = u.current_health
		var dist := from_2d.distance_to(Vector2(u.global_position.x, u.global_position.z))
		if hp < min_hp or (is_equal_approx(hp, min_hp) and dist < closest_dist):
			min_hp = hp
			closest_dist = dist
			lowest = u

	return lowest if lowest else get_closest_enemy(from_position, enemies)

static func get_frontline_enemy(from_position: Vector3, enemies: Array) -> BaseUnit3D:
	var closest: BaseUnit3D = null
	var min_distance: float = INF
	for enemy in enemies:
		var u := enemy as BaseUnit3D
		if not is_instance_valid(u):
			continue
		var z_distance: float = abs(u.global_position.z - from_position.z)
		if z_distance < min_distance:
			min_distance = z_distance
			closest = u
	if closest:
		return closest
	if not enemies.is_empty():
		return enemies[0] as BaseUnit3D
	return null

static func get_backline_enemy(from_position: Vector3, enemies: Array) -> BaseUnit3D:
	var farthest: BaseUnit3D = null
	var max_distance: float = 0.0
	for enemy in enemies:
		var u := enemy as BaseUnit3D
		if not is_instance_valid(u):
			continue
		var z_distance: float = abs(u.global_position.z - from_position.z)
		if z_distance > max_distance:
			max_distance = z_distance
			farthest = u
	if farthest:
		return farthest
	if not enemies.is_empty():
		return enemies[0] as BaseUnit3D
	return null

static func is_target_in_range(from_position: Vector3, target_position: Vector3, range_meters: float) -> bool:
	return Vector2(from_position.x, from_position.z).distance_to(
		Vector2(target_position.x, target_position.z)
	) <= range_meters

static func find_target_for(unit: BaseUnit3D) -> BaseUnit3D:
	if not unit or unit.current_state in [BaseUnit3D.State.DEAD, BaseUnit3D.State.CASTING] or unit.is_on_bench() or not unit.is_inside_tree():
		return null
	
	var enemy_group: String = "enemy_units" if unit.team == 0 else "player_units"
	var enemies: Array = filter_valid_enemies(unit.get_tree().get_nodes_in_group(enemy_group))
	
	if unit.stats.is_stationary and not enemies.is_empty():
		enemies = enemies.filter(func(e):
			return unit.is_target_in_attack_range(e)
		)
		if enemies.is_empty():
			unit.current_target = null
			unit._wait_rooted()
			return null
	
	print("  %s procurando alvo... encontrados %d inimigos" % [unit.stats.unit_name, enemies.size()])
	
	if enemies.is_empty():
		if unit.attack_timer:
			unit.attack_timer.stop()
		unit.current_target = null
		unit.current_state = BaseUnit3D.State.IDLE
		unit.velocity = Vector3.ZERO
		return null
	
	var chosen: BaseUnit3D = null
	if unit.stats.target_priority == UnitStats.TargetPriority.LOWEST_HP:
		chosen = get_lowest_hp_enemy(unit.global_position, enemies)
	else:
		chosen = get_closest_enemy(unit.global_position, enemies)
	
	if chosen:
		if unit.origin_runtime:
			unit.origin_runtime.on_target_acquired(chosen)
		if float(unit.synergy_bonuses.get("marked_target_damage_pct", 0.0)) > 0.0:
			var weakest := enemies[0] as BaseUnit3D
			for enemy in enemies:
				if enemy.current_health / maxf(enemy.get_max_health(), 1.0) < weakest.current_health / maxf(weakest.get_max_health(), 1.0):
					weakest = enemy
			weakest.marked_team = unit.team
			weakest.mark_expires_at_msec = BattleClock.now_msec() + 3000
		print("%s mirando em %s" % [unit.stats.unit_name, chosen.stats.unit_name])
	else:
		print("%s não conseguiu definir alvo!" % unit.stats.unit_name)
	
	return chosen
