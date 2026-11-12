class_name BenchManager
extends RefCounted

## Gerenciador do Banco de Reservas e Sistema de Fusão (Merges) 3 Estrelas

var bench_units: Array[BaseUnit3D] = []
var max_bench_size: int = 9

func add_unit(unit: BaseUnit3D, board: Board3D) -> bool:
	if not is_instance_valid(unit):
		return false
	if bench_units.size() >= max_bench_size:
		return false
	
	if board and board.get_unit_at(unit.board_position) == unit:
		board.remove_unit(unit.board_position)
		
	if not bench_units.has(unit):
		bench_units.append(unit)
	unit.visible = true
	unit.team = 0
	unit.debug_movement = false
	unit.use_navigation = false
	unit.rotation.y = 0.0
	unit.set_hovered(false)
	unit._update_status_visibility()
	realign_units(board)
	
	print("%s enviado para o banco (%d/%d)" % [unit.stats.unit_name, bench_units.size(), max_bench_size])
	return true

func realign_units(board: Board3D, animate: bool = true) -> void:
	if not board:
		return
	for i in bench_units.size():
		var u: BaseUnit3D = bench_units[i]
		if not is_instance_valid(u):
			continue
		u.visible = true
		u.team = 0
		u.board_position = Vector2i(i, -1)
		u.rotation.y = 0.0
		u._update_status_visibility()
		var target_pos := board.get_bench_slot_world_position(i)
		if animate and u.is_inside_tree():
			var tween := u.create_tween()
			tween.set_ease(Tween.EASE_OUT)
			tween.set_trans(Tween.TRANS_QUAD)
			tween.tween_property(u, "global_position", target_pos, 0.25)
		else:
			u.global_position = target_pos

func resolve_merges(board: Board3D) -> Array[BaseUnit3D]:
	"""Executa fusões de 3 cópias em 1 de nível superior. Retorna lista de unidades sobreviventes que evoluíram."""
	var evolved_units: Array[BaseUnit3D] = []
	if not board:
		return evolved_units

	while true:
		var copies_by_key: Dictionary = {}
		var owned_units: Array[BaseUnit3D] = []
		owned_units.append_array(bench_units)
		for unit in board.get_all_units():
			if unit is BaseUnit3D and unit not in owned_units:
				owned_units.append(unit)
		for unit in owned_units:
			if unit.team != 0 or unit.current_state == BaseUnit3D.State.DEAD or unit.star_level >= 4:
				continue
			var key := "%s:%d" % [unit.stats.unit_id, unit.star_level]
			if not copies_by_key.has(key):
				copies_by_key[key] = []
			copies_by_key[key].append(unit)

		var merge_copies: Array = []
		for key in copies_by_key:
			if copies_by_key[key].size() >= 3:
				merge_copies = copies_by_key[key]
				break
		if merge_copies.is_empty():
			break

		merge_copies.sort_custom(func(a: BaseUnit3D, b: BaseUnit3D) -> bool:
			return board.get_unit_at(a.board_position) == a and board.get_unit_at(b.board_position) != b
		)
		var consumed: Array = merge_copies.slice(0, 3)
		var old_star: int = consumed[0].star_level
		var survivor: BaseUnit3D = consumed[0]
		for candidate in consumed:
			if board.get_unit_at(candidate.board_position) == candidate:
				survivor = candidate
				break
		var total_invested := 0
		var extra_items: Array = []
		for unit in consumed:
			total_invested += unit.invested_gold
			if unit == survivor:
				continue
			if unit.has_method("unequip_all_items"):
				extra_items.append_array(unit.unequip_all_items())
			if bench_units.has(unit):
				bench_units.erase(unit)
			if board.get_unit_at(unit.board_position) == unit:
				board.remove_unit(unit.board_position)
			unit.queue_free()

		for extra_item in extra_items:
			if survivor.has_method("can_equip_more_items") and survivor.can_equip_more_items():
				survivor.equip_item(extra_item)
			else:
				var merged := false
				if extra_item.is_component() and survivor.has_method("get_equipped_items"):
					var eq: Array = survivor.get_equipped_items()
					for i in range(eq.size()):
						if eq[i].is_component():
							var combo: ItemData = ItemRegistry.find_combination(eq[i].id, extra_item.id)
							if combo:
								survivor.remove_equipped_item_at(i)
								survivor.equip_item(combo)
								merged = true
								break
				if not merged:
					var tree := survivor.get_tree()
					var main_node = tree.current_scene if tree else null
					if main_node and "item_manager" in main_node and main_node.item_manager:
						main_node.item_manager.add_item_to_inventory(extra_item)

		survivor.invested_gold = total_invested
		survivor.promote_to_star(old_star + 1)
		evolved_units.append(survivor)
		if survivor.star_level == 2:
			AudioManager.play_2_star_up()
		elif survivor.star_level >= 3:
			AudioManager.play_3_star_up()
		print("%s evoluiu para %d estrelas" % [survivor.stats.unit_name, survivor.star_level])

	realign_units(board)
	return evolved_units

func auto_deploy(board: Board3D, limit: int, current_count: int) -> void:
	if not board or bench_units.is_empty():
		return
	var free_slots: int = limit - current_count
	if free_slots <= 0:
		return
	
	var free_cells: Array[Vector2i] = []
	for row in range(board.rows - 1, board.rows - board.player_rows - 1, -1):
		for col in range(board.columns):
			var cell := Vector2i(col, row)
			if not board.is_cell_occupied(cell):
				free_cells.append(cell)
	
	var deployed_count := 0
	while deployed_count < free_slots and not bench_units.is_empty() and not free_cells.is_empty():
		var unit: BaseUnit3D = bench_units.pop_front()
		if not is_instance_valid(unit):
			continue
		var target_cell: Vector2i = free_cells.pop_front()
		unit.visible = true
		unit.team = 0
		unit.use_navigation = true
		if not unit.is_in_group("player_units"):
			unit.add_to_group("player_units")
		if board.place_unit(unit, target_cell, true):
			unit.board_position = target_cell
			deployed_count += 1
		else:
			bench_units.push_front(unit)
	
	realign_units(board)
