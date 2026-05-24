# res://tools/create_units.gd
@tool
extends EditorScript

func _run() -> void:
	# Garantir que o diretório existe
	if not DirAccess.dir_exists_absolute("res://resources"):
		DirAccess.make_dir_absolute("res://resources")
	if not DirAccess.dir_exists_absolute("res://resources/units"):
		DirAccess.make_dir_absolute("res://resources/units")
	
	print("========================================")
	print("Criando Unidades Tier 1...")
	print("========================================")
	
	create_anhanga()
	create_labatut()
	create_teiniagua()
	create_cumacanga()
	create_papa_figo()
	
	print("\n========================================")
	print("Criando Unidades Tier 2...")
	print("========================================")
	
	create_mapinguari()
	create_mae_de_ouro()
	
	print("\n========================================")
	print("✅ Todas as unidades criadas!")
	print("========================================")

func create_anhanga() -> void:
	var unit := UnitStats.new()
	
	unit.unit_name = "Anhangá"
	unit.unit_id = "anhanga"
	unit.description = "Protetor místico da floresta."
	unit.lore = "Guardião espiritual da mata."
	unit.tier = 1
	unit.cost = 1
	
	unit.max_health = 650.0
	unit.attack_damage = 45.0
	unit.attack_speed = 0.8
	unit.attack_range = 1
	unit.armor = 30.0
	unit.magic_resist = 20.0
	unit.movement_speed = 180.0
	
	unit.max_mana = 80.0
	unit.starting_mana = 0.0
	unit.mana_per_attack = 12.0
	unit.mana_when_hit = 8.0
	
	unit.origins = ["Amazônico"]
	unit.classes = ["Protetor da Mata", "Tank"]
	
	unit.ability_name = "Rugido da Floresta"
	unit.ability_description = "Reduz ataque de inimigos próximos."
	unit.ability_duration = 4.0
	unit.ability_range = 3.0
	unit.ability_damage_type = UnitStats.DamageType.MAGICAL
	
	unit.target_priority = UnitStats.TargetPriority.CLOSEST
	unit.is_tank = true
	
	unit.on_spawn_effect = "forest_leaves"
	
	save_unit(unit, "anhanga")

func create_labatut() -> void:
	var unit := UnitStats.new()
	
	unit.unit_name = "Labatut"
	unit.unit_id = "labatut"
	unit.description = "Criatura aquática curadora."
	unit.lore = "Ser das águas turvas."
	unit.tier = 1
	unit.cost = 1
	
	unit.max_health = 500.0
	unit.attack_damage = 35.0
	unit.attack_speed = 1.0
	unit.attack_range = 2
	unit.armor = 15.0
	unit.magic_resist = 35.0
	unit.movement_speed = 200.0
	unit.health_regen = 3.0
	
	unit.max_mana = 100.0
	unit.starting_mana = 50.0
	unit.mana_per_attack = 10.0
	unit.mana_per_second = 5.0
	
	unit.origins = ["Amazônico"]
	unit.classes = ["Aquático", "Místico", "Suporte"]
	
	unit.ability_name = "Corrente Curativa"
	unit.ability_description = "Cura aliados feridos."
	unit.ability_heal = 200.0
	unit.ability_targets = 3
	unit.ability_range = 5.0
	unit.ability_damage_type = UnitStats.DamageType.MAGICAL
	
	unit.target_priority = UnitStats.TargetPriority.LOWEST_HP
	unit.is_ranged = true
	unit.prefers_backline = true
	
	save_unit(unit, "labatut")

func create_teiniagua() -> void:
	var unit := UnitStats.new()
	
	unit.unit_name = "Teiniaguá"
	unit.unit_id = "teiniagua"
	unit.description = "Lagarto mágico."
	unit.tier = 1
	unit.cost = 1
	
	unit.max_health = 450.0
	unit.attack_damage = 60.0
	unit.attack_speed = 1.3
	unit.attack_range = 3
	unit.armor = 10.0
	unit.magic_resist = 15.0
	unit.movement_speed = 220.0
	
	unit.max_mana = 60.0
	unit.mana_per_attack = 8.0
	
	unit.origins = ["Pantaneiro"]
	unit.classes = ["Místico", "DPS"]
	
	unit.ability_name = "Esfera Arcana"
	unit.ability_description = "Dano em área."
	unit.ability_damage = 180.0
	unit.ability_targets = 1
	unit.ability_damage_type = UnitStats.DamageType.MAGICAL
	
	unit.target_priority = UnitStats.TargetPriority.RANDOM
	unit.is_ranged = true
	
	save_unit(unit, "teiniagua")

func create_cumacanga() -> void:
	var unit := UnitStats.new()
	
	unit.unit_name = "Cumacanga"
	unit.unit_id = "cumacanga"
	unit.description = "Crânio flamejante."
	unit.tier = 1
	unit.cost = 1
	
	unit.max_health = 400.0
	unit.attack_damage = 50.0
	unit.attack_speed = 1.1
	unit.attack_range = 1
	unit.armor = 5.0
	unit.magic_resist = 25.0
	unit.movement_speed = 240.0
	unit.can_fly = true
	
	unit.max_mana = 70.0
	unit.starting_mana = 20.0
	unit.mana_per_attack = 15.0
	
	unit.origins = ["Urbano"]
	unit.classes = ["Assombração", "DPS"]
	
	unit.ability_name = "Chamas do Terror"
	unit.ability_description = "Queima inimigos."
	unit.ability_damage = 30.0
	unit.ability_duration = 4.0
	unit.ability_damage_type = UnitStats.DamageType.MAGICAL
	
	unit.target_priority = UnitStats.TargetPriority.LOWEST_HP_PERCENT
	
	save_unit(unit, "cumacanga")

func create_papa_figo() -> void:
	var unit := UnitStats.new()
	
	unit.unit_name = "Papa-Figo"
	unit.unit_id = "papa_figo"
	unit.description = "Figura sinistra."
	unit.tier = 1
	unit.cost = 1
	
	unit.max_health = 550.0
	unit.attack_damage = 40.0
	unit.attack_speed = 0.9
	unit.attack_range = 1
	unit.armor = 20.0
	unit.magic_resist = 20.0
	unit.movement_speed = 190.0
	
	unit.max_mana = 90.0
	unit.mana_per_attack = 13.0
	
	unit.origins = ["Urbano"]
	unit.classes = ["Assombração", "Suporte"]
	
	unit.ability_name = "Toque Gélido"
	unit.ability_description = "Enfraquece alvos."
	unit.ability_damage = 100.0
	unit.ability_heal = 100.0
	unit.ability_duration = 5.0
	unit.ability_damage_type = UnitStats.DamageType.MAGICAL
	
	unit.target_priority = UnitStats.TargetPriority.HIGHEST_ATTACK
	
	save_unit(unit, "papa_figo")

func create_mapinguari() -> void:
	var unit := UnitStats.new()
	
	unit.unit_name = "Mapinguari"
	unit.unit_id = "mapinguari"
	unit.description = "Besta gigante."
	unit.tier = 2
	unit.cost = 2
	
	unit.max_health = 1200.0
	unit.attack_damage = 80.0
	unit.attack_speed = 0.7
	unit.attack_range = 1
	unit.armor = 60.0
	unit.magic_resist = 30.0
	unit.movement_speed = 150.0
	
	unit.max_mana = 100.0
	unit.mana_per_attack = 10.0
	
	unit.origins = ["Amazônico"]
	unit.classes = ["Protetor da Mata", "Tank"]
	
	unit.ability_name = "Couro de Ferro"
	unit.ability_description = "Reflete dano."
	unit.ability_duration = 4.0
	unit.ability_damage_type = UnitStats.DamageType.PHYSICAL
	
	unit.target_priority = UnitStats.TargetPriority.CLOSEST
	unit.is_tank = true
	
	save_unit(unit, "mapinguari")

func create_mae_de_ouro() -> void:
	var unit := UnitStats.new()
	
	unit.unit_name = "Mãe-de-Ouro"
	unit.unit_id = "mae_de_ouro"
	unit.description = "Bola de fogo."
	unit.tier = 2
	unit.cost = 2
	
	unit.max_health = 700.0
	unit.attack_damage = 70.0
	unit.attack_speed = 1.2
	unit.attack_range = 3
	unit.armor = 20.0
	unit.magic_resist = 40.0
	unit.movement_speed = 280.0
	unit.can_fly = true
	
	unit.max_mana = 80.0
	unit.starting_mana = 30.0
	unit.mana_per_attack = 12.0
	
	unit.origins = ["Pantaneiro"]
	unit.classes = ["Místico", "DPS", "Suporte"]
	
	unit.ability_name = "Chamas Douradas"
	unit.ability_description = "Explosão dupla."
	unit.ability_damage = 150.0
	unit.ability_heal = 120.0
	unit.ability_targets = 3
	unit.ability_damage_type = UnitStats.DamageType.MAGICAL
	
	unit.target_priority = UnitStats.TargetPriority.RANDOM
	unit.is_ranged = true
	
	save_unit(unit, "mae_de_ouro")

func save_unit(unit: UnitStats, filename: String) -> void:
	if not unit.is_valid():
		print("Unit %s is invalid!" % filename)
		return
	
	var path: String = "res://resources/units/%s.tres" % filename
	var error: int = ResourceSaver.save(unit, path)
	
	if error == OK:
		print("Created: %s" % unit.unit_name)
	else:
		print("Failed: %s (Error %d)" % [filename, error])
