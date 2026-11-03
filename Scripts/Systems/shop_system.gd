class_name ShopSystem
extends Node

## Sistema de loja para compra de unidades

signal shop_refreshed(units: Array[UnitStats])
signal unit_purchased(unit_stats: UnitStats, cost: int)
signal shop_locked_changed(is_locked: bool)

## Configurações da loja
@export var shop_slots: int = 5
@export var reroll_cost: int = 2
@export var xp_cost: int = 4

## Estado da loja
var current_units: Array[UnitStats] = []
var is_shop_locked: bool = false
var unavailable_unit_ids: Array[String] = []

## Pools de unidades por tier (chance de aparecer)
var tier_chances := {
	1: [100, 0, 0, 0, 0],      # Level 1: 100% T1
	2: [85, 15, 0, 0, 0],      # Level 2: 85% T1. 15% T2
	3: [75, 25, 0, 0, 0],      # Level 3: 75% T1, 25% T2
	4: [55, 30, 15, 0, 0],     # Level 4: 55% T1, 30% T2, 15% T3
	5: [45, 33, 20, 2, 0],     # Level 5: 45% T1, 33% T2, 20% T3, 2% T4
	6: [30, 40, 25, 5, 0],     # Level 6
	7: [19, 35, 35, 10, 1],    # Level 7
	8: [16, 25, 35, 20, 4],    # Level 8
	9: [9, 15, 30, 30, 16],    # Level 9: Muito Tier 4 e 5
}

func _ready() -> void:
	refresh_shop(1)  # Level inicial

func refresh_shop(player_level: int) -> void:
	if is_shop_locked:
		print("Loja travada!")
		return
	
	current_units.clear()
	current_units.resize(shop_slots)
	
	var chances: Array = tier_chances.get(player_level, [100, 0, 0, 0, 0])
	
	for i in shop_slots:
		var tier: int = roll_tier(chances)
		var unit: UnitStats = get_random_unit_by_tier(tier)
		current_units[i] = unit
	
	shop_refreshed.emit(current_units)
	print("Loja atualizada (Level %d)" % player_level)

func roll_tier(chances: Array) -> int:
	var total: int = 0
	for chance in chances:
		total += chance
	
	var roll: int = randi() % total
	var accumulated: int = 0
	
	for tier in range(chances.size()):
		accumulated += chances[tier]
		if roll < accumulated:
			return tier + 1  # Tier 1-5
	
	return 1  # Fallback

func get_random_unit_by_tier(tier: int) -> UnitStats:
	var units: Array[UnitStats] = []
	for unit in UnitSpawner.get_units_by_tier(tier):
		if not unavailable_unit_ids.has(unit.unit_id):
			units.append(unit)
	
	if units.is_empty():
		print("Nenhuma unidade Tier %d disponível" % tier)
		return null
	
	return units.pick_random()

func set_unavailable_unit_ids(unit_ids: Array[String]) -> void:
	unavailable_unit_ids = unit_ids.duplicate()
	var changed := false
	for i in current_units.size():
		var unit := current_units[i]
		if unit and unavailable_unit_ids.has(unit.unit_id):
			current_units[i] = null
			changed = true
	if changed:
		shop_refreshed.emit(current_units)

func purchase_unit(slot_index: int) -> UnitStats:
	if slot_index < 0 or slot_index >= current_units.size():
		return null
	
	var unit: UnitStats = current_units[slot_index]
	
	if not unit:
		return null
	
	# Remover da loja
	current_units[slot_index] = null
	
	unit_purchased.emit(unit, unit.cost)
	
	return unit

func lock_shop(locked: bool) -> void:
	is_shop_locked = locked
	shop_locked_changed.emit(is_shop_locked)
	print("Loja %s" % ("travada" if locked else "destravada"))

func get_shop_units() -> Array[UnitStats]:
	return current_units
