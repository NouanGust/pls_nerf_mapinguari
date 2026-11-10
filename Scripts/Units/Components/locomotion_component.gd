class_name LocomotionComponent
extends Node

## Componente de Locomoção Planar e Navegação Tática para Unidades Auto-Chess

const BattleClock = preload("res://Scripts/Systems/battle_clock.gd")

var unit: BaseUnit3D
var detour_timer: float = 0.0
var detour_dir: Vector3 = Vector3.ZERO
var rooted_target_timer: float = 0.0
var idle_target_timer: float = 0.0
var was_stunned: bool = false

func setup(p_unit: BaseUnit3D) -> void:
	unit = p_unit

func get_movement_speed() -> float:
	if not unit or not unit.stats:
		return 2.0
	if unit.stats.is_stationary:
		return 0.0
	var speed: float = unit.stats.movement_speed / 100.0 * (1.0 + float(unit.synergy_bonuses.get("move_speed_pct", 0.0)))
	if BattleClock.now_msec() < unit.slowed_until_msec:
		speed *= 0.7
	if BattleClock.now_msec() < unit.speed_buff_until_msec:
		speed *= unit.speed_buff_multiplier
	if unit.origin_runtime:
		speed *= unit.origin_runtime.get_speed_multiplier()
	var enemy_slow: float = clampf(unit.get_support_aura_value("enemy_slow", true), 0.0, 0.5)
	if enemy_slow > 0.0:
		speed *= (1.0 - enemy_slow)
	return speed

func wait_rooted() -> void:
	if not unit or unit.current_state in [BaseUnit3D.State.DEAD, BaseUnit3D.State.CASTING]:
		return
	unit.current_state = BaseUnit3D.State.ROOTED
	unit.velocity = Vector3.ZERO
	if unit.attack_timer:
		unit.attack_timer.stop()

func move_direct_to_target(delta: float = 0.0166) -> void:
	if not unit:
		return
	if unit.stats.is_stationary:
		wait_rooted()
		return
	if not is_instance_valid(unit.current_target) or unit.current_target.current_state == BaseUnit3D.State.DEAD or unit.current_target.is_on_bench():
		unit.current_target = null
		unit.current_state = BaseUnit3D.State.IDLE
		unit.velocity = Vector3.ZERO
		detour_timer = 0.0
		detour_dir = Vector3.ZERO
		unit.find_target()
		return
	
	var target_pos: Vector3 = unit.current_target.global_position
	var planar_offset := Vector3(target_pos.x - unit.global_position.x, 0.0, target_pos.z - unit.global_position.z)
	
	if planar_offset.length() <= unit.get_attack_range_meters():
		unit.velocity = Vector3.ZERO
		unit.current_state = BaseUnit3D.State.IDLE
		detour_timer = 0.0
		detour_dir = Vector3.ZERO
		unit.check_attack_or_move()
		return

	if unit.stats.target_priority == UnitStats.TargetPriority.CLOSEST:
		var enemy_group: String = "enemy_units" if unit.team == 0 else "player_units"
		var enemies_list: Array = unit.get_tree().get_nodes_in_group(enemy_group)
		var valid_enemies := enemies_list.filter(func(e):
			return is_instance_valid(e) and not e.is_queued_for_deletion() and e.current_state != BaseUnit3D.State.DEAD and e.visible and not e.is_on_bench()
		)
		var closest_enemy := unit.get_closest_enemy(valid_enemies)
		if closest_enemy and closest_enemy != unit.current_target:
			var my_pos2d := Vector2(unit.global_position.x, unit.global_position.z)
			var current_dist := my_pos2d.distance_to(Vector2(target_pos.x, target_pos.z))
			var closest_dist := my_pos2d.distance_to(Vector2(closest_enemy.global_position.x, closest_enemy.global_position.z))
			var range_meters := unit.get_attack_range_meters()
			if closest_dist <= range_meters or (current_dist > range_meters and closest_dist + 1.2 < current_dist):
				unit.current_target = closest_enemy
				target_pos = unit.current_target.global_position
				planar_offset = Vector3(target_pos.x - unit.global_position.x, 0.0, target_pos.z - unit.global_position.z)
				if planar_offset.length() <= range_meters:
					unit.velocity = Vector3.ZERO
					unit.current_state = BaseUnit3D.State.IDLE
					detour_timer = 0.0
					detour_dir = Vector3.ZERO
					unit.check_attack_or_move()
					return

	unit.current_state = BaseUnit3D.State.MOVING
	var direct_dir := planar_offset.normalized() if planar_offset.length_squared() > 0.0001 else Vector3.FORWARD
	
	if detour_timer > 0.0:
		detour_timer -= delta
		if detour_timer <= 0.0:
			detour_dir = Vector3.ZERO

	var separation: Vector3 = _calculate_separation()
	var obstacle_avoidance: Vector3 = _calculate_obstacle_avoidance(direct_dir)

	var move_dir := direct_dir
	if detour_timer > 0.0 and detour_dir != Vector3.ZERO:
		move_dir = (direct_dir * 0.35 + detour_dir * 0.85).normalized()
	else:
		var steer := separation * 0.5 + obstacle_avoidance * 0.8
		if steer.length_squared() > 0.01:
			move_dir = (direct_dir + steer).normalized()

	if unit.debug_movement:
		print("%s movendo DIRETO para %s (dist: %.2f)" % [
			unit.stats.unit_name,
			unit.current_target.stats.unit_name,
			planar_offset.length()
		])
	
	unit.velocity = move_dir * get_movement_speed()
	unit.velocity.y = 0.0
	unit.move_and_slide()
	unit.global_position.y = unit.combat_ground_height
	
	_handle_post_collision_detour(direct_dir)

	if move_dir.length() > 0:
		var target_rotation: float = atan2(move_dir.x, move_dir.z)
		unit.rotation.y = lerp_angle(unit.rotation.y, target_rotation, 0.15)
	
	if not is_instance_valid(unit.current_target) or unit.current_target.current_state == BaseUnit3D.State.DEAD:
		unit.current_target = null
		unit.current_state = BaseUnit3D.State.IDLE
		unit.velocity = Vector3.ZERO
		detour_timer = 0.0
		detour_dir = Vector3.ZERO
		unit.find_target()
		return

	planar_offset = Vector3(unit.current_target.global_position.x - unit.global_position.x, 0.0, unit.current_target.global_position.z - unit.global_position.z)
	if planar_offset.length() <= unit.get_attack_range_meters():
		if unit.debug_movement:
			print("%s chegou no range de ataque!" % unit.stats.unit_name)
		unit.velocity = Vector3.ZERO
		unit.current_state = BaseUnit3D.State.IDLE
		detour_timer = 0.0
		detour_dir = Vector3.ZERO
		unit.check_attack_or_move()

func _calculate_separation() -> Vector3:
	var separation := Vector3.ZERO
	if not unit.is_inside_tree():
		return separation
	for other_node in unit.get_tree().get_nodes_in_group("units"):
		if other_node == unit or not is_instance_valid(other_node) or not (other_node is BaseUnit3D):
			continue
		var other := other_node as BaseUnit3D
		if other.is_on_bench() or other.current_state == BaseUnit3D.State.DEAD or not other.visible:
			continue
		if other == unit.current_target:
			continue
		var to_self := unit.global_position - other.global_position
		to_self.y = 0.0
		var dist := to_self.length()
		if dist < 0.95 and dist > 0.001:
			separation += (to_self / dist) * (1.0 - dist / 0.95)
	return separation

func _calculate_obstacle_avoidance(direct_dir: Vector3) -> Vector3:
	var avoidance := Vector3.ZERO
	if direct_dir.length_squared() < 0.001 or not unit.is_inside_tree():
		return avoidance
	
	var perp_left := Vector3(-direct_dir.z, 0.0, direct_dir.x).normalized()
	var perp_right := Vector3(direct_dir.z, 0.0, -direct_dir.x).normalized()
	
	for other_node in unit.get_tree().get_nodes_in_group("units"):
		if other_node == unit or not is_instance_valid(other_node) or not (other_node is BaseUnit3D):
			continue
		var other := other_node as BaseUnit3D
		if other.is_on_bench() or other.current_state == BaseUnit3D.State.DEAD or not other.visible:
			continue
		if other == unit.current_target:
			continue
		
		var to_other := other.global_position - unit.global_position
		to_other.y = 0.0
		var forward_proj := to_other.dot(direct_dir)
		if forward_proj > 0.15 and forward_proj < 1.8:
			var lateral_vec := to_other - direct_dir * forward_proj
			var lateral_dist := lateral_vec.length()
			var clearance_needed := 0.95
			if lateral_dist < clearance_needed:
				var closeness := (1.8 - forward_proj) / 1.8
				var lateral_penetration := (clearance_needed - lateral_dist) / clearance_needed
				var weight := closeness * lateral_penetration
				var side_dot := to_other.dot(perp_left)
				var steer_side := perp_right if side_dot > 0.0 else perp_left
				avoidance += steer_side * (weight * 1.5)
	return avoidance

func _handle_post_collision_detour(direct_dir: Vector3) -> void:
	var collision_count := unit.get_slide_collision_count()
	if collision_count <= 0:
		return
	for i in range(collision_count):
		var col := unit.get_slide_collision(i)
		var normal := col.get_normal()
		normal.y = 0.0
		if normal.length_squared() > 0.01:
			normal = normal.normalized()
			if normal.dot(direct_dir) < -0.12:
				var perp_left := Vector3(-direct_dir.z, 0.0, direct_dir.x)
				var perp_right := Vector3(direct_dir.z, 0.0, -direct_dir.x)
				var left_blocked: bool = unit.test_move(unit.global_transform, perp_left * 0.45)
				var right_blocked: bool = unit.test_move(unit.global_transform, perp_right * 0.45)
				var chosen_dir := Vector3.ZERO
				if not left_blocked and right_blocked:
					chosen_dir = perp_left
				elif not right_blocked and left_blocked:
					chosen_dir = perp_right
				elif not left_blocked and not right_blocked:
					var cross_y: float = direct_dir.cross(normal).y
					chosen_dir = perp_left if cross_y > 0.0 else perp_right
				else:
					chosen_dir = perp_left if randf() < 0.5 else perp_right
				detour_dir = chosen_dir
				detour_timer = 0.45
				break

func move_towards_target() -> void:
	if not unit or unit.is_stunned():
		return
	if unit.stats.is_stationary:
		wait_rooted()
		return
	if not is_instance_valid(unit.current_target) or unit.current_target.is_queued_for_deletion() or unit.current_target.current_state == BaseUnit3D.State.DEAD or unit.current_target.is_on_bench():
		if unit.debug_movement:
			print("%s: alvo foi destruído ou no banco!" % unit.stats.unit_name)
		unit.current_target = null
		unit.find_target()
		return
	if not unit.current_target:
		if unit.debug_movement:
			print("%s: sem alvo definido!" % unit.stats.unit_name)
		unit.find_target()
		return
	unit.current_state = BaseUnit3D.State.MOVING
	move_direct_to_target(0.0166)
