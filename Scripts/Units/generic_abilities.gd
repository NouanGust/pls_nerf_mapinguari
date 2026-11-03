class_name GenericAbilities
extends RefCounted

const BattleClock = preload("res://Scripts/Systems/battle_clock.gd")

## Implementação das habilidades por função de combate e kinds genéricos.

static func execute_ability(unit: BaseUnit3D, scale_multiplier: float = 1.0) -> bool:
	if not unit or not unit.stats:
		return false

	var kind := unit.stats.ability_kind
	if kind.is_empty():
		# Inferir kind a partir da função de combate se não estiver explicitado
		match unit.stats.get_combat_role():
			UnitStats.ROLE_TANK:
				kind = "tank_guard"
			UnitStats.ROLE_CONJURADOR:
				kind = "conjure_area"
			UnitStats.ROLE_ATACANTE:
				kind = "self_haste"
			UnitStats.ROLE_PORRADEIRO:
				kind = "brawler"
			UnitStats.ROLE_ASSASSINO:
				kind = "assassin"
			UnitStats.ROLE_SUPORTE:
				kind = "support"

	match kind:
		"tank_guard":
			return _execute_tank_guard(unit, scale_multiplier)
		"conjure_area":
			return _execute_conjure_area(unit, scale_multiplier)
		"conjure_line":
			return _execute_conjure_line(unit, scale_multiplier)
		"self_haste":
			return _execute_self_haste(unit, scale_multiplier)
		"brawler":
			return _execute_brawler(unit, scale_multiplier)
		"assassin":
			return _execute_assassin(unit, scale_multiplier)
		"support":
			return _execute_support(unit, scale_multiplier)
		_:
			return false

static func _execute_tank_guard(unit: BaseUnit3D, scale: float) -> bool:
	var base_shield := unit.stats.ability_shield
	if base_shield <= 0.0:
		base_shield = unit.get_max_health() * 0.22
	var final_shield := base_shield * unit.stats.get_star_multiplier(unit.star_level) * scale
	unit.set_shield_with_source(final_shield, BaseUnit3D.ShieldSource.SELF)

	# Buff temporário de defesa (4s)
	unit.active_buffs.append({
		"armor_flat": 25.0 * unit.stats.get_star_multiplier(unit.star_level),
		"magic_resist_flat": 20.0 * unit.stats.get_star_multiplier(unit.star_level),
		"expires_at_msec": BattleClock.now_msec() + 4000
	})

	# Interrupção / atordoamento curto (máx 1.0s) em inimigos adjacentes
	var board := unit._get_combat_board()
	if board:
		var my_cell := board.get_grid_position(board.to_local(unit.global_position))
		var enemy_group := "enemy_units" if unit.team == 0 else "player_units"
		for node in unit.get_tree().get_nodes_in_group(enemy_group):
			var enemy: BaseUnit3D = node as BaseUnit3D
			if is_instance_valid(enemy) and enemy.current_state != BaseUnit3D.State.DEAD and not enemy.is_on_bench():
				var cell := board.get_grid_position(board.to_local(enemy.global_position))
				if board.get_cell(cell) and board.get_hex_distance(my_cell, cell) <= 1:
					var enemy_pos := enemy.global_position
					enemy.apply_stun(0.8, "INTERROMPIDO")
					CombatFeedback.create_hit_particles(enemy_pos + Vector3.UP * 0.5, Color("#60a5fa"))

	CombatFeedback.create_status_indicator(unit, "GUARDA DEFENSIVA", 2.0)
	return true

static func _execute_conjure_area(unit: BaseUnit3D, scale: float) -> bool:
	var target := unit.current_target
	if not is_instance_valid(target) or target.current_state == BaseUnit3D.State.DEAD:
		return false

	var base_damage := unit.stats.ability_damage
	if base_damage <= 0.0:
		base_damage = 220.0
	var final_damage := base_damage * unit.stats.get_star_multiplier(unit.star_level) * scale

	var center_pos := target.global_position
	var enemy_group := "enemy_units" if unit.team == 0 else "player_units"
	var radius := 2.2 # em metros
	var start_pos := unit.global_position + Vector3.UP * (1.1 if unit.is_flying() else 0.8)
	var target_impact := center_pos + Vector3.UP * 0.7

	var on_impact := func() -> void:
		if not is_instance_valid(unit):
			return
		var impact_center := center_pos
		if is_instance_valid(target) and target.current_state != BaseUnit3D.State.DEAD:
			impact_center = target.global_position

		var tree := unit.get_tree() if unit.is_inside_tree() else Engine.get_main_loop() as SceneTree
		if tree:
			for node in tree.get_nodes_in_group(enemy_group):
				var enemy: BaseUnit3D = node as BaseUnit3D
				if is_instance_valid(enemy) and enemy.current_state != BaseUnit3D.State.DEAD and not enemy.is_on_bench():
					if enemy.global_position.distance_to(impact_center) <= radius:
						var enemy_pos := enemy.global_position
						enemy.take_damage(final_damage, unit, UnitStats.DamageType.MAGICAL)
						CombatFeedback.create_hit_particles(enemy_pos + Vector3.UP * 0.7, Color("#a855f7"))
						if is_instance_valid(enemy) and enemy.current_state != BaseUnit3D.State.DEAD:
							if unit.origin_runtime:
								unit.origin_runtime.apply_assombro_to_target(enemy)

		CombatFeedback.create_hit_particles(impact_center + Vector3.UP * 0.5, Color("#c084fc"))
		CombatFeedback.create_hit_particles(impact_center + Vector3.UP * 0.9, Color("#e9d5ff"))
		if is_instance_valid(unit):
			unit._trigger_camera_shake(0.25, 0.2)

	unit._spawn_ballistic_projectile(
		start_pos,
		target,
		target_impact,
		Color("#c084fc"),
		1.8,
		0.48,
		on_impact,
		"ConjureAreaOrb",
		0.28
	)

	return true

static func _execute_conjure_line(unit: BaseUnit3D, scale: float) -> bool:
	var target := unit.current_target
	if not is_instance_valid(target) or target.current_state == BaseUnit3D.State.DEAD:
		return false

	var base_damage := unit.stats.ability_damage
	if base_damage <= 0.0:
		base_damage = 360.0
	var final_damage := base_damage * unit.stats.get_star_multiplier(unit.star_level) * scale

	var start_pos := unit.global_position
	var dir := (target.global_position - start_pos).normalized()
	dir.y = 0.0
	if dir.length_squared() < 0.01:
		dir = Vector3.FORWARD
	var max_line_range := 12.0
	var wave_speed := 16.0 # metros por segundo (mais cadenciado e visível)

	# Visual da onda / projétil de fogo em linha reta
	var flame_wave := Node3D.new()
	flame_wave.name = "FlameWave"
	var wave_mesh := MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = 0.45
	sphere.height = 0.90
	wave_mesh.mesh = sphere
	var wave_mat := StandardMaterial3D.new()
	wave_mat.albedo_color = Color("#f97316")
	wave_mat.emission_enabled = true
	wave_mat.emission = Color("#ea580c")
	wave_mat.emission_energy_multiplier = 2.5
	wave_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	wave_mesh.material_override = wave_mat
	flame_wave.add_child(wave_mesh)

	var scene_root: Node = unit.get_tree().current_scene if (unit and unit.get_tree()) else null
	if not scene_root and unit:
		scene_root = unit.get_parent()
	if scene_root:
		scene_root.add_child(flame_wave)
		flame_wave.global_position = start_pos + Vector3.UP * 0.7
		var end_visual_pos := start_pos + dir * max_line_range + Vector3.UP * 0.7
		var total_flight := max_line_range / wave_speed
		var tw := flame_wave.create_tween()
		tw.tween_property(flame_wave, "global_position", end_visual_pos, total_flight).set_trans(Tween.TRANS_LINEAR)
		tw.tween_callback(flame_wave.queue_free)

	var enemy_group := "enemy_units" if unit.team == 0 else "player_units"
	var tree := unit.get_tree() if unit.is_inside_tree() else Engine.get_main_loop() as SceneTree
	if tree:
		for node in tree.get_nodes_in_group(enemy_group):
			var enemy: BaseUnit3D = node as BaseUnit3D
			if is_instance_valid(enemy) and enemy.current_state != BaseUnit3D.State.DEAD and not enemy.is_on_bench():
				var to_enemy := enemy.global_position - start_pos
				to_enemy.y = 0.0
				var proj := to_enemy.dot(dir)
				if proj > 0.0 and proj < max_line_range:
					var dist_to_line := (to_enemy - dir * proj).length()
					if dist_to_line <= 1.5:
						var hit_delay := proj / wave_speed
						_schedule_line_hit(unit, enemy, final_damage, hit_delay)

	CombatFeedback.create_status_indicator(unit, "FAIXA FLAMEJANTE", 2.0)
	return true

static func _schedule_line_hit(unit: BaseUnit3D, enemy: BaseUnit3D, damage: float, delay: float) -> void:
	if delay > 0.0 and is_instance_valid(unit):
		var tree := unit.get_tree() if unit.is_inside_tree() else Engine.get_main_loop() as SceneTree
		if tree:
			await tree.create_timer(delay, false).timeout

	if is_instance_valid(enemy) and enemy.current_state != BaseUnit3D.State.DEAD:
		var enemy_pos := enemy.global_position
		enemy.take_damage(damage, unit if is_instance_valid(unit) else null, UnitStats.DamageType.MAGICAL)
		if is_instance_valid(enemy) and enemy.current_state != BaseUnit3D.State.DEAD:
			enemy.apply_slow(2.5)
			if is_instance_valid(unit) and unit.origin_runtime:
				unit.origin_runtime.apply_assombro_to_target(enemy)
		CombatFeedback.create_hit_particles(enemy_pos + Vector3.UP * 0.6, Color("#f97316"))
		if is_instance_valid(unit):
			unit._trigger_camera_shake(0.2, 0.15)

static func _execute_self_haste(unit: BaseUnit3D, scale: float) -> bool:
	var duration := 4.0
	var as_mult := 1.40
	var ad_mult := 1.20 * scale

	unit.apply_speed_buff(duration, as_mult, "+CADÊNCIA")
	unit.active_buffs.append({
		"attack_multiplier": ad_mult,
		"expires_at_msec": BattleClock.now_msec() + int(duration * 1000.0)
	})
	CombatFeedback.create_status_indicator(unit, "FRENESI OFENSIVO", duration)
	return true

static func _execute_brawler(unit: BaseUnit3D, scale: float) -> bool:
	var duration := 4.5
	var star_mult := unit.stats.get_star_multiplier(unit.star_level)

	# Amplificação do próprio ataque e defesas
	unit.active_buffs.append({
		"attack_multiplier": 1.30 * scale,
		"armor_flat": 20.0 * star_mult,
		"magic_resist_flat": 15.0 * star_mult,
		"expires_at_msec": BattleClock.now_msec() + int(duration * 1000.0)
	})

	# Se a ficha tiver dano direto explícito, aplica no clímax do golpe com impacto
	if unit.stats.ability_damage > 0.0 and is_instance_valid(unit.current_target):
		var target := unit.current_target
		var dmg := unit.stats.ability_damage * star_mult * scale
		var apply_strike := func() -> void:
			if not is_instance_valid(unit) or not is_instance_valid(target) or target.current_state == BaseUnit3D.State.DEAD:
				return
			target.take_damage(dmg, unit, UnitStats.DamageType.PHYSICAL)
			CombatFeedback.create_hit_particles(target.global_position + Vector3.UP * 0.5, Color("#ef4444"))
			CombatFeedback.create_hit_particles(target.global_position + Vector3.UP * 0.8, Color("#dc2626"))
			unit._trigger_camera_shake(0.25, 0.2)

		if unit.model:
			var tw := unit.create_tween()
			tw.tween_property(unit.model, "scale", unit.model_base_scale * Vector3(1.2, 1.25, 1.2), 0.12).set_trans(Tween.TRANS_QUAD)
			tw.tween_property(unit.model, "scale", unit.model_base_scale, 0.18).set_trans(Tween.TRANS_BOUNCE)
			tw.tween_callback(apply_strike)
		else:
			apply_strike.call()

	CombatFeedback.create_status_indicator(unit, "BRIGÃO IMPLACÁVEL", duration)
	return true

static func _execute_assassin(unit: BaseUnit3D, scale: float) -> bool:
	# Seleciona o alvo vulnerável alcançável com menor percentual de vida
	var enemy_group := "enemy_units" if unit.team == 0 else "player_units"
	var enemies := unit.get_tree().get_nodes_in_group(enemy_group)
	var best_target: BaseUnit3D = null
	var min_pct := 2.0
	var min_abs_hp := INF
	var min_dist := INF

	var max_reach := 12.0 # alcance do salto/bote em metros

	for node in enemies:
		var enemy: BaseUnit3D = node as BaseUnit3D
		if is_instance_valid(enemy) and enemy.current_state != BaseUnit3D.State.DEAD and not enemy.is_on_bench() and enemy.visible:
			var d := unit.global_position.distance_to(enemy.global_position)
			if d <= max_reach:
				var pct := enemy.current_health / maxf(enemy.get_max_health(), 1.0)
				var abs_hp := enemy.current_health
				if pct < min_pct or (is_equal_approx(pct, min_pct) and (abs_hp < min_abs_hp or (is_equal_approx(abs_hp, min_abs_hp) and d < min_dist))):
					min_pct = pct
					min_abs_hp = abs_hp
					min_dist = d
					best_target = enemy

	if not best_target:
		best_target = unit.current_target

	if not is_instance_valid(best_target):
		return false

	unit.current_target = best_target
	var start_leap_pos := unit.global_position
	# Ponto de aterrissagem próximo ao alvo
	var to_target_vec := best_target.global_position - unit.global_position
	to_target_vec.y = 0.0
	var dir_to_target := to_target_vec.normalized() if to_target_vec.length_squared() > 0.01 else Vector3.FORWARD
	var landing := best_target.global_position - dir_to_target * 1.2
	landing.y = unit.combat_ground_height

	var base_dmg := unit.stats.ability_damage
	if base_dmg <= 0.0:
		base_dmg = 260.0
	var final_dmg := base_dmg * unit.stats.get_star_multiplier(unit.star_level) * scale

	var leap_tw := unit.create_tween()
	leap_tw.tween_method(func(prog: float) -> void:
		if is_instance_valid(unit) and unit.current_state != BaseUnit3D.State.DEAD:
			unit.global_position = start_leap_pos.lerp(landing, prog)
			if unit.model:
				unit.model.position.y = sin(prog * PI) * 0.6
	, 0.0, 1.0, 0.20).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

	leap_tw.tween_callback(func() -> void:
		if not is_instance_valid(unit) or unit.current_state == BaseUnit3D.State.DEAD:
			return
		unit.global_position = landing
		if unit.model:
			unit.model.position.y = 0.0
		unit._face_target()

		if is_instance_valid(best_target) and best_target.current_state != BaseUnit3D.State.DEAD:
			var target_pos := best_target.global_position
			best_target.take_damage(final_dmg, unit, unit.stats.ability_damage_type)
			CombatFeedback.create_hit_particles(target_pos + Vector3.UP * 0.7, Color("#ef4444"))

			if is_instance_valid(best_target) and best_target.current_state != BaseUnit3D.State.DEAD:
				if unit.origin_runtime:
					unit.origin_runtime.apply_assombro_to_target(best_target)

		# Cura própria se a ficha possuir (ex: Chupa-cabra)
		if unit.stats.ability_heal > 0.0 and is_instance_valid(unit) and unit.current_state != BaseUnit3D.State.DEAD:
			var heal_amt := unit.stats.ability_heal * unit.stats.get_star_multiplier(unit.star_level) * scale
			unit.heal(heal_amt)

		if is_instance_valid(unit):
			unit._trigger_camera_shake(0.28, 0.2)

		CombatFeedback.create_status_indicator(unit, "GOLPE LETAL", 1.5)
	)

	return true

static func _execute_support(unit: BaseUnit3D, scale: float) -> bool:
	var board := unit._get_combat_board()
	if not board:
		return false

	var my_cell := board.get_grid_position(board.to_local(unit.global_position))
	var ally_group := "player_units" if unit.team == 0 else "enemy_units"
	var star_mult := unit.stats.get_star_multiplier(unit.star_level)

	# Cura / escudo a aliados no raio de 1 hex
	var heal_amt := unit.stats.ability_heal * star_mult * scale
	var shield_amt := unit.stats.ability_shield * star_mult * scale

	for node in unit.get_tree().get_nodes_in_group(ally_group):
		var ally: BaseUnit3D = node as BaseUnit3D
		if is_instance_valid(ally) and ally.current_state != BaseUnit3D.State.DEAD and not ally.is_on_bench():
			var cell := board.get_grid_position(board.to_local(ally.global_position))
			if board.get_cell(cell) and board.get_hex_distance(my_cell, cell) <= 1:
				var ally_pos := ally.global_position
				if heal_amt > 0.0:
					ally.heal(heal_amt)
				if shield_amt > 0.0:
					ally.set_shield_with_source(shield_amt, BaseUnit3D.ShieldSource.CLASS)
				CombatFeedback.create_hit_particles(ally_pos + Vector3.UP * 0.6, Color("#34d399"))

	# Melhora a própria aura por 4 segundos
	unit.active_buffs.append({
		"support_aura_boost": 1.75,
		"expires_at_msec": BattleClock.now_msec() + 4000
	})

	CombatFeedback.create_status_indicator(unit, "BENÇÃO DE SUPORTE", 2.0)
	return true
