class_name ItemManager
extends RefCounted

## Gerenciador Central de Itens do Jogador, Fusão e Aplicação nas Unidades

const MAX_ITEMS_PER_UNIT: int = 2
const MAX_INVENTORY_SIZE: int = 10

signal inventory_changed
signal item_equipped(unit: BaseUnit3D, item: ItemData)
signal item_combined(unit: BaseUnit3D, result_item: ItemData)
signal notification_requested(text: String)

var player_items: Array[ItemData] = []

func get_inventory_items() -> Array[ItemData]:
	return player_items

func add_item_to_inventory(item: ItemData) -> bool:
	if not item:
		return false
	if player_items.size() >= MAX_INVENTORY_SIZE:
		emit_signal("notification_requested", "Inventário de itens cheio!")
		return false
	player_items.append(item)
	emit_signal("inventory_changed")
	return true

func add_item_by_id(item_id: StringName) -> bool:
	var it := ItemRegistry.get_item(item_id)
	if not it:
		push_warning("Item não encontrado no ItemRegistry: %s" % str(item_id))
		return false
	return add_item_to_inventory(it)

func remove_item_from_inventory(item: ItemData) -> bool:
	var idx := player_items.find(item)
	if idx >= 0:
		player_items.remove_at(idx)
		emit_signal("inventory_changed")
		return true
	return false

func remove_item_at_index(index: int) -> ItemData:
	if index >= 0 and index < player_items.size():
		var it := player_items[index]
		player_items.remove_at(index)
		emit_signal("inventory_changed")
		return it
	return null

## Verifica se uma unidade pode receber um item específico
func can_equip_item_to_unit(item: ItemData, unit: BaseUnit3D) -> bool:
	if not is_instance_valid(unit) or not item:
		return false

	# Se for consumível utilitário
	if item.is_consumable():
		match item.consumable_action:
			&"remover":
				return unit.has_method("get_equipped_items") and not unit.get_equipped_items().is_empty()
			&"cloner":
				return true
			&"coffee":
				return true
			&"reforger":
				return false # Reforjador é usado no inventário
			_:
				return false

	var equipped: Array = unit.get_equipped_items() if unit.has_method("get_equipped_items") else []

	# Se tiver menos que o máximo (2 itens), sempre pode receber
	if equipped.size() < MAX_ITEMS_PER_UNIT:
		return true

	# Se já tiver 2 itens, mas um deles for componente e o novo também for componente, pode fundir!
	if equipped.size() == MAX_ITEMS_PER_UNIT and item.is_component():
		for eq in equipped:
			if eq.is_component():
				var combo := ItemRegistry.find_combination(eq.id, item.id)
				if combo != null:
					return true

	return false

## Equipa ou usa um item em uma unidade
func equip_item_to_unit(item: ItemData, unit: BaseUnit3D, from_inventory: bool = true) -> bool:
	if not is_instance_valid(unit) or not item:
		return false

	# 1. Tratar Utilitários Consumíveis
	if item.is_consumable():
		return _use_consumable_on_unit(item, unit, from_inventory)

	if not unit.has_method("get_equipped_items") or not unit.has_method("equip_item"):
		emit_signal("notification_requested", "Esta unidade não suporta itens.")
		return false

	var equipped: Array = unit.get_equipped_items()

	# 2. Verificar fusão de componentes na unidade
	if item.is_component():
		# Procura se já existe um componente básico equipado para fundir
		var comp_idx := -1
		for i in range(equipped.size()):
			if equipped[i].is_component():
				comp_idx = i
				break

		if comp_idx >= 0:
			var existing_comp = equipped[comp_idx]
			var combo := ItemRegistry.find_combination(existing_comp.id, item.id)
			if combo != null:
				if from_inventory:
					remove_item_from_inventory(item)
				unit.remove_equipped_item_at(comp_idx)
				unit.equip_item(combo)
				emit_signal("item_combined", unit, combo)
				emit_signal("notification_requested", "%s forjado em %s!" % [combo.name, unit.stats.unit_name])
				return true

	# 3. Equipamento normal (respeitando o limite de 2 itens)
	if equipped.size() >= MAX_ITEMS_PER_UNIT:
		emit_signal("notification_requested", "%s já atingiu o limite de %d itens!" % [unit.stats.unit_name, MAX_ITEMS_PER_UNIT])
		return false

	if from_inventory:
		remove_item_from_inventory(item)

	var success: bool = unit.equip_item(item)
	if success:
		emit_signal("item_equipped", unit, item)
		emit_signal("notification_requested", "%s equipado em %s." % [item.name, unit.stats.unit_name])
	else:
		if from_inventory:
			add_item_to_inventory(item)
	return success

## Devolve todos os itens da unidade para o inventário do jogador
func unequip_all_from_unit(unit: BaseUnit3D) -> Array:
	var returned: Array = []
	if not is_instance_valid(unit) or not unit.has_method("unequip_all_items"):
		return returned
	var items: Array = unit.unequip_all_items()
	for it in items:
		if add_item_to_inventory(it):
			returned.append(it)
	return returned

## Executa ação de consumível utilitário
func _use_consumable_on_unit(item: ItemData, unit: BaseUnit3D, from_inventory: bool) -> bool:
	match item.consumable_action:
		&"remover":
			var removed := unequip_all_from_unit(unit)
			if removed.is_empty():
				emit_signal("notification_requested", "Unidade não possui itens para remover.")
				return false
			if from_inventory:
				remove_item_from_inventory(item)
			emit_signal("notification_requested", "Peneira do Saci recolheu os itens de %s!" % unit.stats.unit_name)
			return true

		&"cloner":
			# Duplica cópia 1-estrela no banco de reservas
			var tree := unit.get_tree()
			var main_node = tree.current_scene if tree else null
			if main_node and main_node.has_method("add_unit_to_bench") and main_node.has_method("spawn_unit_for_drag"):
				var clone: BaseUnit3D = main_node.spawn_unit_for_drag(unit.stats)
				if clone:
					clone.star_level = 1
					if main_node.add_unit_to_bench(clone):
						if from_inventory:
							remove_item_from_inventory(item)
						emit_signal("notification_requested", "Muda de Sumaúma gerou uma cópia de %s!" % unit.stats.unit_name)
						return true
					else:
						clone.queue_free()
						emit_signal("notification_requested", "Banco de reservas cheio para clonar.")
						return false
			return false

		&"coffee":
			var tree := unit.get_tree()
			var main_node = tree.current_scene if tree else null
			if main_node and "player_xp" in main_node:
				main_node.player_xp += 4
				if main_node.has_method("update_ui"):
					main_node.update_ui()
				if from_inventory:
					remove_item_from_inventory(item)
				emit_signal("notification_requested", "Café fresco de coador! +4 de XP.")
				return true
			return false

		_:
			return false

## Reforja um item do inventário em outro aleatório da mesma categoria
func reforge_inventory_item(item: ItemData) -> bool:
	if not item or not player_items.has(item):
		return false
	var candidates: Array[ItemData] = []
	if item.is_component():
		for comp in ItemRegistry.get_basic_components():
			if comp.id != item.id:
				candidates.append(comp)
	else:
		for comp in ItemRegistry.get_all_items():
			if not comp.is_component() and not comp.is_consumable() and comp.id != item.id:
				candidates.append(comp)

	if candidates.is_empty():
		return false

	var new_it := candidates[randi() % candidates.size()]
	var idx := player_items.find(item)
	player_items[idx] = new_it
	emit_signal("inventory_changed")
	emit_signal("notification_requested", "Pena da Mãe-d'Ouro transmutou %s em %s!" % [item.name, new_it.name])
	return true
