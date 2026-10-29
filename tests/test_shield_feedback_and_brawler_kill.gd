extends SceneTree

const BattleClock = preload("res://Scripts/Systems/battle_clock.gd")
const GenericAbilities = preload("res://Scripts/Units/generic_abilities.gd")

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	print("==================================================")
	print("TESTE: FEEDBACK DE DANO EM ESCUDO E BRAWLER KILL")
	print("==================================================")
	
	if not root.has_node("BattleClock"):
		var clock = BattleClock.new()
		clock.name = "BattleClock"
		root.add_child(clock)

	var catalog := UnitSpawner.load_all_units()
	
	# [TESTE 1] Dano em escudo absorve e DamageType.SHIELD existe
	print("\n[TESTE 1] Testando dano absorvido por escudo e DamageType.SHIELD:")
	var victim: BaseUnit3D = BaseUnit3D.new()
	victim.initialize(catalog["capivara"], 1)
	victim.set_physics_process(false)
	victim.board_position = Vector2i(2, 2)
	root.add_child(victim)
	
	assert(CombatFeedback.DamageType.SHIELD != null, "DamageType.SHIELD deve existir no enum")
	victim.set_shield_with_source(150.0, BaseUnit3D.ShieldSource.SELF)
	var hp_before := victim.current_health
	victim.take_damage(60.0, null, UnitStats.DamageType.TRUE)
	assert(victim.current_shield == 90.0, "Escudo deve absorver exatamente 60 de True Damage. Atual: %f" % victim.current_shield)
	assert(victim.current_health == hp_before, "Vida da vítima não deve diminuir se totalmente absorvido pelo escudo")
	print("  ✓ Dano absorvido pelo escudo (150 -> 90) processado com sucesso!")

	# [TESTE 2] Brawler mata o alvo com dano direto da habilidade sem crashar
	print("\n[TESTE 2] Testando _execute_brawler quando o alvo morre no golpe:")
	var brawler: BaseUnit3D = BaseUnit3D.new()
	brawler.initialize(catalog["mapinguari"], 1)
	brawler.set_physics_process(false)
	brawler.board_position = Vector2i(3, 3)
	root.add_child(brawler)

	var low_hp_enemy: BaseUnit3D = BaseUnit3D.new()
	low_hp_enemy.initialize(catalog["saci_perere"], 1)
	low_hp_enemy.set_physics_process(false)
	low_hp_enemy.board_position = Vector2i(3, 4)
	low_hp_enemy.team = 1
	low_hp_enemy.current_health = 10.0 # Vida baixa para morrer no golpe
	root.add_child(low_hp_enemy)

	brawler.current_target = low_hp_enemy
	# Forçar dano de habilidade no brawler para testar linha 162-167 de generic_abilities
	brawler.stats.ability_damage = 500.0
	brawler.stats.ability_kind = "brawler"

	var executed := GenericAbilities.execute_ability(brawler, 1.0)
	assert(executed == true, "Habilidade brawler deve executar com sucesso")
	assert(low_hp_enemy.current_state == BaseUnit3D.State.DEAD, "Inimigo deve ter morrido pelo dano do brawler")
	assert(brawler.current_target == null, "current_target deve ser limpo na morte do alvo")
	print("  ✓ Brawler executado e abateu o alvo sem erro de 'Nil.global_position'!")

	# Limpar nós de teste
	victim.queue_free()
	brawler.queue_free()
	low_hp_enemy.queue_free()

	print("\nTODOS OS TESTES DE FEEDBACK E BRAWLER PASSARAM COM SUCESSO!")
	quit(0)
