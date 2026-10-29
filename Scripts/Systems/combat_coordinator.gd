class_name CombatCoordinator
extends RefCounted

## Coordenador de Combate, Monitoramento de Stalemate e Métricas de Dano/Cura

const BattleClock = preload("res://Scripts/Systems/battle_clock.gd")

var main: Node
var combat_report_entries: Dictionary = {}
var combat_generation: int = 0

func setup(p_main: Node) -> void:
	main = p_main

func capture_roster(units: Array) -> void:
	combat_report_entries.clear()
	for candidate in units:
		if not (candidate is BaseUnit3D):
			continue
		var unit: BaseUnit3D = candidate
		if not unit.visible or unit.current_state == BaseUnit3D.State.DEAD:
			continue
		var instance_id := unit.get_instance_id()
		combat_report_entries[instance_id] = {
			"name": unit.stats.unit_name,
			"team": unit.team,
			"icon": unit.stats.icon,
			"damage_dealt": 0.0,
			"healing_done": 0.0,
			"damage_received": 0.0,
		}
		if not unit.combat_metric_recorded.is_connected(on_metric_recorded):
			unit.combat_metric_recorded.connect(on_metric_recorded)

func on_metric_recorded(unit: BaseUnit3D, metric: StringName, amount: float) -> void:
	if not is_instance_valid(unit):
		return
	var instance_id := unit.get_instance_id()
	if not combat_report_entries.has(instance_id):
		return
	var entry: Dictionary = combat_report_entries[instance_id]
	entry[metric] = float(entry.get(metric, 0.0)) + amount
	combat_report_entries[instance_id] = entry

func get_report_data() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for entry in combat_report_entries.values():
		result.append(entry.duplicate())
	return result

func is_stationary_stalemate(player_units: Array, enemy_units: Array) -> bool:
	if player_units.is_empty() or enemy_units.is_empty():
		return false
	for candidate in player_units + enemy_units:
		var unit := candidate as BaseUnit3D
		if not is_instance_valid(unit) or not unit.stats.is_stationary or unit.has_pending_combat_effects():
			return false
	for player_candidate in player_units:
		var player := player_candidate as BaseUnit3D
		for enemy_candidate in enemy_units:
			var enemy := enemy_candidate as BaseUnit3D
			if player.is_target_in_attack_range(enemy) or enemy.is_target_in_attack_range(player):
				return false
	return true

func monitor_combat_loop(duration_seconds: float, stalemate_seconds: float) -> void:
	if not main:
		return
	combat_generation += 1
	var gen := combat_generation
	var deadline_msec := BattleClock.now_msec() + int(maxf(duration_seconds, 1.0) * 1000.0)
	var stalemate_since_msec: int = -1

	while main.combat_active:
		await main.get_tree().create_timer(0.25, false).timeout
		if not main.combat_active or gen != combat_generation:
			return

		main.battle_time_remaining = maxf(float(deadline_msec - BattleClock.now_msec()) / 1000.0, 0.0)
		main._update_round_label()

		var player_units: Array = []
		var enemy_units: Array = []
		for unit in main.board.get_all_units():
			if not (unit is BaseUnit3D) or unit.current_state == BaseUnit3D.State.DEAD:
				continue
			if unit.team == 0:
				player_units.append(unit)
			else:
				enemy_units.append(unit)

		if player_units.is_empty() and enemy_units.is_empty():
			main.end_combat(false, true)
			return
		if player_units.is_empty() or enemy_units.is_empty():
			main.end_combat(player_units.size() > 0)
			return
		if main.battle_time_remaining <= 0.0:
			main.end_combat(false, true)
			return
		if is_stationary_stalemate(player_units, enemy_units):
			if stalemate_since_msec < 0:
				stalemate_since_msec = BattleClock.now_msec()
			elif BattleClock.now_msec() - stalemate_since_msec >= int(stalemate_seconds * 1000.0):
				main.end_combat(false, true, "Unidades imóveis sem alcance entre os times")
				return
		else:
			stalemate_since_msec = -1
