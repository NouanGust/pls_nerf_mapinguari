@tool
extends EditorScript

func _run() -> void:
	if not DirAccess.dir_exists_absolute("res://resources/units"):
		DirAccess.make_dir_absolute("res://resources/units")
	
	print("========================================")
	print("Criando Unidades Tier 3...")
	print("========================================")
	
	create_quibungo()
	create_matinta_perera()
	create_minhocao()
	create_alamoa()
	create_cabeca_de_cuia()
	
	print("\n========================================")
	print("Criando Unidades Tier 4...")
	print("========================================")
	
	create_corpo_seco()
	create_pisadeira()
	create_mboi_guacu()
	create_caapora()
	create_comadre_fulozinha()
	
	print("\n========================================")
	print("Criando Unidades Tier 5...")
	print("========================================")
	
	create_boiuna()
	create_mae_dagua()
	create_romãozinho()
	create_pe_de_garrafa()
	create_tutu_maramba()
	
	print("\n========================================")
	print("Todas as unidades criadas!")
	print("========================================")

## ============================================
## TIER 3 - RAROS
## ============================================

func create_quibungo() -> void:
	var unit := UnitStats.new()
	
	unit.unit_name = "Quibungo"
	unit.unit_id = "quibungo"
	unit.description = "Gigante corcunda com saco nas costas que sequestra crianças."
	unit.lore = "Criatura das florestas que carrega um saco para capturar os desobedientes."
	unit.tier = 3
	unit.cost = 3
	
	unit.max_health = 1400.0
	unit.attack_damage = 85.0
	unit.attack_speed = 0.75
	unit.attack_range = 1
	unit.armor = 50.0
	unit.magic_resist = 30.0
	unit.movement_speed = 160.0
	
	unit.max_mana = 100.0
	unit.mana_per_attack = 10.0
	unit.mana_when_hit = 15.0
	
	unit.origins = ["Amazônico"]
	unit.classes = ["Protetor da Mata", "Tank"]
	
	unit.ability_name = "Saco das Sombras"
	unit.ability_description = "Captura unidade inimiga por 3 segundos, causando dano contínuo."
	unit.ability_damage = 40.0
	unit.ability_duration = 3.0
	unit.ability_targets = 1
	unit.ability_damage_type = UnitStats.DamageType.TRUE
	
	unit.target_priority = UnitStats.TargetPriority.HIGHEST_ATTACK
	unit.is_tank = true
	
	save_unit(unit, "quibungo")

func create_matinta_perera() -> void:
	var unit := UnitStats.new()
	
	unit.unit_name = "Matinta Perera"
	unit.unit_id = "matinta_perera"
	unit.description = "Bruxa que se transforma em pássaro para assombrar."
	unit.lore = "De dia é velha, de noite vira ave que assobia tristemente."
	unit.tier = 3
	unit.cost = 3
	
	unit.max_health = 850.0
	unit.attack_damage = 75.0
	unit.attack_speed = 1.1
	unit.attack_range = 3
	unit.armor = 20.0
	unit.magic_resist = 40.0
	unit.movement_speed = 250.0
	unit.can_fly = true
	
	unit.max_mana = 80.0
	unit.starting_mana = 40.0
	unit.mana_per_attack = 10.0
	
	unit.origins = ["Amazônico"]
	unit.classes = ["Assombração", "Metamorfo"]
	
	unit.ability_name = "Forma de Pássaro"
	unit.ability_description = "Transforma-se, ficando imune e causando dano em área."
	unit.ability_damage = 120.0
	unit.ability_duration = 3.0
	unit.ability_range = 3.0
	unit.ability_damage_type = UnitStats.DamageType.MAGICAL
	
	unit.target_priority = UnitStats.TargetPriority.BACKLINE
	unit.is_assassin = true
	
	save_unit(unit, "matinta_perera")

func create_minhocao() -> void:
	var unit := UnitStats.new()
	
	unit.unit_name = "Minhocão"
	unit.unit_id = "minhocao"
	unit.description = "Serpente gigante subterrânea que causa terremotos."
	unit.lore = "Monstro que escava túneis profundos, fazendo a terra tremer."
	unit.tier = 3
	unit.cost = 3
	
	unit.max_health = 1600.0
	unit.attack_damage = 100.0
	unit.attack_speed = 0.6
	unit.attack_range = 1
	unit.armor = 70.0
	unit.magic_resist = 20.0
	unit.movement_speed = 140.0
	
	unit.max_mana = 120.0
	unit.mana_per_attack = 12.0
	unit.mana_when_hit = 20.0
	
	unit.origins = ["Pantaneiro"]
	unit.classes = ["Protetor da Mata", "Tank"]
	
	unit.ability_name = "Terremoto"
	unit.ability_description = "Emerge do chão, atordoando e causando dano em área."
	unit.ability_damage = 180.0
	unit.ability_duration = 2.0
	unit.ability_range = 3.5
	unit.ability_damage_type = UnitStats.DamageType.PHYSICAL
	
	unit.target_priority = UnitStats.TargetPriority.CLOSEST
	unit.is_tank = true
	unit.stun_resist = 0.5
	
	save_unit(unit, "minhocao")

func create_alamoa() -> void:
	var unit := UnitStats.new()
	
	unit.unit_name = "Alamoa"
	unit.unit_id = "alamoa"
	unit.description = "Sereia amazônica de beleza hipnotizante."
	unit.lore = "Encanta pescadores com seu canto, levando-os para as profundezas."
	unit.tier = 3
	unit.cost = 3
	
	unit.max_health = 900.0
	unit.attack_damage = 65.0
	unit.attack_speed = 1.2
	unit.attack_range = 3
	unit.armor = 25.0
	unit.magic_resist = 45.0
	unit.movement_speed = 210.0
	unit.health_regen = 5.0
	
	unit.max_mana = 90.0
	unit.starting_mana = 50.0
	unit.mana_per_attack = 8.0
	unit.mana_per_second = 6.0
	
	unit.origins = ["Amazônico", "Litorâneo"]
	unit.classes = ["Aquático", "Encantado", "Suporte"]
	
	unit.ability_name = "Canto Hipnótico"
	unit.ability_description = "Encanta inimigos, fazendo-os atacar aliados por 3 segundos."
	unit.ability_duration = 3.0
	unit.ability_targets = 2
	unit.ability_range = 4.0
	unit.ability_damage_type = UnitStats.DamageType.MAGICAL
	
	unit.target_priority = UnitStats.TargetPriority.HIGHEST_ATTACK
	unit.is_ranged = true
	
	save_unit(unit, "alamoa")

func create_cabeca_de_cuia() -> void:
	var unit := UnitStats.new()
	
	unit.unit_name = "Cabeça-de-Cuia"
	unit.unit_id = "cabeca_de_cuia"
	unit.description = "Cabeça flutuante que arrasta vítimas para o fundo do rio."
	unit.lore = "Condenado a vagar pelos rios em busca de sete Marias para se redimir."
	unit.tier = 3
	unit.cost = 3
	
	unit.max_health = 1000.0
	unit.attack_damage = 95.0
	unit.attack_speed = 1.0
	unit.attack_range = 2
	unit.armor = 30.0
	unit.magic_resist = 50.0
	unit.movement_speed = 230.0
	unit.can_fly = true
	
	unit.max_mana = 100.0
	unit.starting_mana = 30.0
	unit.mana_per_attack = 12.0
	
	unit.origins = ["Litorâneo"]
	unit.classes = ["Aquático", "Assombração", "DPS"]
	
	unit.ability_name = "Arrasto Amaldiçoado"
	unit.ability_description = "Puxa inimigo para perto, causando dano e reduzindo armadura."
	unit.ability_damage = 150.0
	unit.ability_duration = 4.0
	unit.ability_targets = 1
	unit.ability_damage_type = UnitStats.DamageType.MAGICAL
	
	unit.target_priority = UnitStats.TargetPriority.BACKLINE
	unit.is_ranged = true
	
	save_unit(unit, "cabeca_de_cuia")

## ============================================
## TIER 4 - ÉPICOS
## ============================================

func create_corpo_seco() -> void:
	var unit := UnitStats.new()
	
	unit.unit_name = "Corpo-Seco"
	unit.unit_id = "corpo_seco"
	unit.description = "Zumbi ressecado que drena vida dos vivos."
	unit.lore = "Cadáver ambulante de um homem tão ruim que nem a terra o quis."
	unit.tier = 4
	unit.cost = 4
	
	unit.max_health = 1300.0
	unit.attack_damage = 110.0
	unit.attack_speed = 0.9
	unit.attack_range = 1
	unit.armor = 40.0
	unit.magic_resist = 35.0
	unit.movement_speed = 170.0
	
	unit.max_mana = 80.0
	unit.mana_per_attack = 8.0
	unit.mana_when_hit = 10.0
	
	unit.origins = ["Urbano"]
	unit.classes = ["Assombração", "DPS"]
	
	unit.ability_name = "Drenagem Vital"
	unit.ability_description = "Suga vida de inimigos próximos, curando-se."
	unit.ability_damage = 100.0
	unit.ability_heal = 200.0
	unit.ability_duration = 4.0
	unit.ability_range = 2.5
	unit.ability_damage_type = UnitStats.DamageType.TRUE
	
	unit.target_priority = UnitStats.TargetPriority.LOWEST_HP_PERCENT
	
	save_unit(unit, "corpo_seco")

func create_pisadeira() -> void:
	var unit := UnitStats.new()
	
	unit.unit_name = "Pisadeira"
	unit.unit_id = "pisadeira"
	unit.description = "Velha bruxa que paralisa suas vítimas enquanto dormem."
	unit.lore = "Causa pesadelos terríveis, pisando no peito de quem dorme de barriga cheia."
	unit.tier = 4
	unit.cost = 4
	
	unit.max_health = 950.0
	unit.attack_damage = 80.0
	unit.attack_speed = 1.1
	unit.attack_range = 2
	unit.armor = 25.0
	unit.magic_resist = 60.0
	unit.movement_speed = 190.0
	
	unit.max_mana = 70.0
	unit.starting_mana = 35.0
	unit.mana_per_attack = 10.0
	
	unit.origins = ["Urbano"]
	unit.classes = ["Assombração", "Suporte"]
	
	unit.ability_name = "Paralisia do Terror"
	unit.ability_description = "Paralisa todos os inimigos em área por 2.5 segundos."
	unit.ability_duration = 2.5
	unit.ability_range = 3.5
	unit.ability_damage_type = UnitStats.DamageType.MAGICAL
	
	unit.target_priority = UnitStats.TargetPriority.CLOSEST
	unit.stun_resist = 0.7
	
	save_unit(unit, "pisadeira")

func create_mboi_guacu() -> void:
	var unit := UnitStats.new()
	
	unit.unit_name = "Mboi-Guaçu"
	unit.unit_id = "mboi_guacu"
	unit.description = "Serpente aquática colossal que domina os rios."
	unit.lore = "Grande cobra d'água que protege tesouros submersos."
	unit.tier = 4
	unit.cost = 4
	
	unit.max_health = 1700.0
	unit.attack_damage = 120.0
	unit.attack_speed = 0.8
	unit.attack_range = 2
	unit.armor = 55.0
	unit.magic_resist = 45.0
	unit.movement_speed = 180.0
	
	unit.max_mana = 100.0
	unit.mana_per_attack = 10.0
	unit.mana_when_hit = 15.0
	
	unit.origins = ["Pantaneiro", "Litorâneo"]
	unit.classes = ["Aquático", "Tank"]
	
	unit.ability_name = "Constrição Mortal"
	unit.ability_description = "Enrola-se no alvo, causando dano massivo ao longo do tempo."
	unit.ability_damage = 60.0
	unit.ability_duration = 5.0
	unit.ability_targets = 1
	unit.ability_damage_type = UnitStats.DamageType.PHYSICAL
	
	unit.target_priority = UnitStats.TargetPriority.HIGHEST_HP
	unit.is_tank = true
	
	save_unit(unit, "mboi_guacu")

func create_caapora() -> void:
	var unit := UnitStats.new()
	
	unit.unit_name = "Caapora"
	unit.unit_id = "caapora"
	unit.description = "Guardião jovem da floresta com arco e flecha."
	unit.lore = "Protetor ágil que pune caçadores gananciosos."
	unit.tier = 4
	unit.cost = 4
	
	unit.max_health = 1100.0
	unit.attack_damage = 130.0
	unit.attack_speed = 1.4
	unit.attack_range = 4
	unit.armor = 30.0
	unit.magic_resist = 30.0
	unit.movement_speed = 260.0
	unit.critical_chance = 0.25
	unit.critical_damage = 2.5
	
	unit.max_mana = 60.0
	unit.mana_per_attack = 6.0
	
	unit.origins = ["Amazônico"]
	unit.classes = ["Protetor da Mata", "Caçador", "DPS"]
	
	unit.ability_name = "Flecha Perfurante"
	unit.ability_description = "Dispara flecha que atravessa inimigos, causando dano em linha."
	unit.ability_damage = 200.0
	unit.ability_targets = 5
	unit.ability_range = 6.0
	unit.ability_damage_type = UnitStats.DamageType.PHYSICAL
	
	unit.target_priority = UnitStats.TargetPriority.LOWEST_HP
	unit.is_ranged = true
	unit.prefers_backline = true
	
	save_unit(unit, "caapora")

func create_comadre_fulozinha() -> void:
	var unit := UnitStats.new()
	
	unit.unit_name = "Comadre Fulozinha"
	unit.unit_id = "comadre_fulozinha"
	unit.description = "Protetora mística que invoca espíritos da natureza."
	unit.lore = "Mãe da mata que protege os animais e plantas."
	unit.tier = 4
	unit.cost = 4
	
	unit.max_health = 1000.0
	unit.attack_damage = 70.0
	unit.attack_speed = 1.0
	unit.attack_range = 3
	unit.armor = 35.0
	unit.magic_resist = 55.0
	unit.movement_speed = 200.0
	unit.health_regen = 8.0
	
	unit.max_mana = 120.0
	unit.starting_mana = 60.0
	unit.mana_per_attack = 15.0
	unit.mana_per_second = 8.0
	
	unit.origins = ["Amazônico"]
	unit.classes = ["Protetor da Mata", "Encantado", "Suporte"]
	
	unit.ability_name = "Invocação da Floresta"
	unit.ability_description = "Invoca 2 espíritos da mata para lutar ao seu lado."
	unit.ability_duration = 10.0
	unit.ability_damage_type = UnitStats.DamageType.MAGICAL
	
	unit.target_priority = UnitStats.TargetPriority.CLOSEST
	unit.is_ranged = true
	unit.prefers_backline = true
	unit.passive_aura_range = 3.0
	unit.passive_aura_effect = "Aliados próximos ganham +15% velocidade de ataque"
	
	save_unit(unit, "comadre_fulozinha")

## ============================================
## TIER 5 - LENDÁRIOS
## ============================================

func create_boiuna() -> void:
	var unit := UnitStats.new()
	
	unit.unit_name = "Boiúna"
	unit.unit_id = "boiuna"
	unit.description = "Cobra-grande mística suprema, mãe de todas as serpentes."
	unit.lore = "Serpente ancestral de poder inimaginável que dorme no fundo dos rios."
	unit.tier = 5
	unit.cost = 5
	
	unit.max_health = 2000.0
	unit.attack_damage = 140.0
	unit.attack_speed = 1.0
	unit.attack_range = 3
	unit.armor = 60.0
	unit.magic_resist = 70.0
	unit.movement_speed = 200.0
	
	unit.max_mana = 150.0
	unit.starting_mana = 50.0
	unit.mana_per_attack = 12.0
	unit.mana_per_second = 5.0
	
	unit.origins = ["Amazônico", "Aquático"]
	unit.classes = ["Místico", "Tank", "DPS"]
	
	unit.ability_name = "Dilúvio Ancestral"
	unit.ability_description = "Invoca tsunami que causa dano massivo e cura aliados."
	unit.ability_damage = 400.0
	unit.ability_heal = 300.0
	unit.ability_targets = 5
	unit.ability_range = 8.0
	unit.ability_damage_type = UnitStats.DamageType.MAGICAL
	
	unit.target_priority = UnitStats.TargetPriority.RANDOM
	unit.is_ranged = true
	unit.passive_aura_range = 4.0
	unit.passive_aura_effect = "Unidades Aquáticas ganham +50% resistência mágica"
	
	save_unit(unit, "boiuna")

func create_mae_dagua() -> void:
	var unit := UnitStats.new()
	
	unit.unit_name = "Mãe-D'Água"
	unit.unit_id = "mae_dagua"
	unit.description = "Entidade aquática primordial de beleza e poder supremos."
	unit.lore = "Rainha das águas, capaz de controlar mares e rios com um pensamento."
	unit.tier = 5
	unit.cost = 5
	
	unit.max_health = 1600.0
	unit.attack_damage = 120.0
	unit.attack_speed = 1.2
	unit.attack_range = 4
	unit.armor = 40.0
	unit.magic_resist = 80.0
	unit.movement_speed = 220.0
	unit.health_regen = 15.0
	
	unit.max_mana = 100.0
	unit.starting_mana = 50.0
	unit.mana_per_attack = 10.0
	unit.mana_per_second = 10.0
	
	unit.origins = ["Litorâneo", "Aquático"]
	unit.classes = ["Encantado", "Místico", "Suporte"]
	
	unit.ability_name = "Bênção das Águas"
	unit.ability_description = "Cura massivamente aliados e purifica debuffs."
	unit.ability_heal = 500.0
	unit.ability_targets = 5
	unit.ability_range = 10.0
	unit.ability_damage_type = UnitStats.DamageType.MAGICAL
	
	unit.target_priority = UnitStats.TargetPriority.LOWEST_HP
	unit.is_ranged = true
	unit.prefers_backline = true
	unit.passive_aura_range = 5.0
	unit.passive_aura_effect = "Aliados próximos regeneram 3% HP/segundo"
	
	save_unit(unit, "mae_dagua")

func create_romãozinho() -> void:
	var unit := UnitStats.new()
	
	unit.unit_name = "Romãozinho"
	unit.unit_id = "romaozinho"
	unit.description = "Duende travesso de poder imenso."
	unit.lore = "Pequeno mas poderoso, causa caos com sua magia imprevisível."
	unit.tier = 5
	unit.cost = 5
	
	unit.max_health = 1200.0
	unit.attack_damage = 100.0
	unit.attack_speed = 1.5
	unit.attack_range = 3
	unit.armor = 30.0
	unit.magic_resist = 60.0
	unit.movement_speed = 280.0
	unit.can_fly = true
	
	unit.max_mana = 80.0
	unit.starting_mana = 40.0
	unit.mana_per_attack = 8.0
	unit.mana_per_second = 8.0
	
	unit.origins = ["Pantaneiro"]
	unit.classes = ["Encantado", "Metamorfo", "Suporte"]
	
	unit.ability_name = "Travessura Caótica"
	unit.ability_description = "Lança feitiço aleatório: dano, cura, CC ou buff."
	unit.ability_damage = 300.0
	unit.ability_heal = 300.0
	unit.ability_targets = 3
	unit.ability_range = 6.0
	unit.ability_damage_type = UnitStats.DamageType.MAGICAL
	
	unit.target_priority = UnitStats.TargetPriority.RANDOM
	unit.is_ranged = true
	unit.stun_resist = 0.8
	
	save_unit(unit, "romaozinho")

func create_pe_de_garrafa() -> void:
	var unit := UnitStats.new()
	
	unit.unit_name = "Pé-de-Garrafa"
	unit.unit_id = "pe_de_garrafa"
	unit.description = "Caçador fantasma implacável que nunca erra."
	unit.lore = "Espectro de caçador amaldiçoado a vagar eternamente."
	unit.tier = 5
	unit.cost = 5
	
	unit.max_health = 1400.0
	unit.attack_damage = 200.0
	unit.attack_speed = 1.3
	unit.attack_range = 5
	unit.armor = 35.0
	unit.magic_resist = 35.0
	unit.movement_speed = 250.0
	unit.critical_chance = 0.5
	unit.critical_damage = 3.0
	
	unit.max_mana = 60.0
	unit.mana_per_attack = 5.0
	
	unit.origins = ["Sertanejo"]
	unit.classes = ["Caçador", "Assombração", "DPS"]
	
	unit.ability_name = "Tiro Certeiro"
	unit.ability_description = "Disparo garantido que causa dano massivo e executa alvos baixos."
	unit.ability_damage = 500.0
	unit.ability_targets = 1
	unit.ability_range = 8.0
	unit.ability_damage_type = UnitStats.DamageType.PHYSICAL
	
	unit.target_priority = UnitStats.TargetPriority.LOWEST_HP_PERCENT
	unit.is_ranged = true
	unit.prefers_backline = true
	unit.is_assassin = true
	
	save_unit(unit, "pe_de_garrafa")

func create_tutu_maramba() -> void:
	var unit := UnitStats.new()
	
	unit.unit_name = "Tutu-Marambá"
	unit.unit_id = "tutu_maramba"
	unit.description = "Bicho-papão supremo, terror absoluto das crianças."
	unit.lore = "Monstro das sombras que encarna todos os medos infantis."
	unit.tier = 5
	unit.cost = 5
	
	unit.max_health = 2200.0
	unit.attack_damage = 160.0
	unit.attack_speed = 0.85
	unit.attack_range = 1
	unit.armor = 80.0
	unit.magic_resist = 60.0
	unit.movement_speed = 190.0
	
	unit.max_mana = 100.0
	unit.mana_per_attack = 10.0
	unit.mana_when_hit = 20.0
	
	unit.origins = ["Urbano"]
	unit.classes = ["Assombração", "Tank"]
	
	unit.ability_name = "Presença Aterrorizante"
	unit.ability_description = "Libera aura que causa medo, reduzindo stats inimigos drasticamente."
	unit.ability_duration = 6.0
	unit.ability_range = 5.0
	unit.ability_damage_type = UnitStats.DamageType.MAGICAL
	
	unit.target_priority = UnitStats.TargetPriority.CLOSEST
	unit.is_tank = true
	unit.stun_resist = 1.0
	unit.passive_aura_range = 3.0
	unit.passive_aura_effect = "Inimigos próximos perdem 30% velocidade de ataque"
	
	save_unit(unit, "tutu_maramba")

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
