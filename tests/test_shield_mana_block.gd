extends SceneTree

const BattleClock = preload("res://Scripts/Systems/battle_clock.gd")

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	print("==================================================")
	print("TESTE: BLOQUEIO DE MANA COM ESCUDO ATIVO")
	print("==================================================")
	
	if not root.has_node("BattleClock"):
		var clock = BattleClock.new()
		clock.name = "BattleClock"
		root.add_child(clock)

	var catalog := UnitSpawner.load_all_units()
	var unit: BaseUnit3D = BaseUnit3D.new()
	unit.initialize(catalog["tatu_bola"], 1)
	unit.board_position = Vector2i(1, 1)
	unit.in_combat = true
	unit.current_state = BaseUnit3D.State.ATTACKING
	unit.current_mana = 10.0

	var dummy_enemy: BaseUnit3D = BaseUnit3D.new()
	dummy_enemy.initialize(catalog["capivara"], 1)
	dummy_enemy.board_position = Vector2i(1, 2)
	dummy_enemy.in_combat = true

	# 1. Conceder escudo ativo à unidade
	unit.set_shield_with_source(200.0, BaseUnit3D.ShieldSource.SELF)
	assert(unit.has_active_shield() == true, "Unidade deve ter escudo ativo")

	# 2. Tentar add_mana direto enquanto com escudo ativo
	var mana_before := unit.current_mana
	unit.add_mana(25.0)
	assert(unit.current_mana == mana_before, "add_mana não deve gerar mana enquanto o escudo estiver ativo")
	print("  ✓ add_mana bloqueado com escudo ativo")

	# 3. Sofrer dano parcial (não quebra o escudo) -> não deve gerar mana
	unit.take_damage(50.0, dummy_enemy, UnitStats.DamageType.PHYSICAL)
	assert(unit.has_active_shield() == true, "Escudo ainda deve estar ativo")
	assert(unit.current_mana == mana_before, "Golpe absorvido pelo escudo não deve gerar mana")
	print("  ✓ Golpe absorvido por escudo não gera mana")

	# 4. Golpe que QUEBRA o escudo -> este golpe também NÃO deve gerar mana
	unit.take_damage(300.0, dummy_enemy, UnitStats.DamageType.PHYSICAL)
	assert(unit.has_active_shield() == false, "Escudo deve ter quebrado")
	assert(unit.current_mana == mana_before, "O golpe que quebra o escudo também NÃO deve gerar mana")
	print("  ✓ Golpe que quebra o escudo não gera mana")

	# 5. Agora sem escudo: sofrer dano -> DEVE gerar mana
	unit.take_damage(30.0, dummy_enemy, UnitStats.DamageType.PHYSICAL)
	assert(unit.current_mana > mana_before, "Sem escudo, dano recebido deve gerar mana")
	print("  ✓ Dano sem escudo gera mana com sucesso")

	# 6. Atacar sem escudo -> DEVE gerar mana
	var mana_after_hit := unit.current_mana
	unit.add_mana(unit.stats.mana_per_attack)
	assert(unit.current_mana > mana_after_hit, "Sem escudo, ataque deve gerar mana")
	print("  ✓ Ataque sem escudo gera mana com sucesso")

	print("\n==================================================")
	print("TODOS OS TESTES DE BLOQUEIO DE MANA PASSARAM!")
	print("==================================================")
	quit(0)
