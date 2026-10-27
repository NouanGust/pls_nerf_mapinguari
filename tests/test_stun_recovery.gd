extends SceneTree

const BattleClock = preload("res://Scripts/Systems/battle_clock.gd")

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	print("\n" + "=".repeat(60))
	print("TESTE DE RECUPERAÇÃO DE ATORDOAMENTO (STUN)")
	print("=".repeat(60) + "\n")

	if not root.has_node("BattleClock"):
		var clock = BattleClock.new()
		clock.name = "BattleClock"
		root.add_child(clock)

	UnitSpawner.load_all_units()

	# -------------------------------------------------------------
	# Cenário 1: Inimigo atacando Minhocão é atordoado pelo Terremoto
	# e após o atordoamento deve voltar a atacar normalmente.
	# -------------------------------------------------------------
	print("--- Cenário 1: Atordoamento pelo Minhocão e retomada de ataque ---")
	var minhocao: BaseUnit3D = UnitSpawner.spawn_unit("minhocao", 1, 0)
	var enemy: BaseUnit3D = UnitSpawner.spawn_unit("capivara", 1, 1)
	assert(minhocao != null, "Minhocão deve ser instanciado")
	assert(enemy != null, "Inimigo (Capivara) deve ser instanciado")

	minhocao.board_position = Vector2i(2, 2)
	enemy.board_position = Vector2i(2, 3)

	root.add_child(minhocao)
	root.add_child(enemy)

	await process_frame
	await process_frame

	minhocao.global_position = Vector3(0.0, 0.0, 0.0)
	enemy.global_position = Vector3(0.0, 0.0, 1.2) # Dentro do alcance de ataque corpo a corpo

	minhocao.start_combat()
	enemy.start_combat()

	# Ambos devem estar no range de ataque e atacando
	assert(enemy.current_state == BaseUnit3D.State.ATTACKING, "Inimigo deve estar no estado ATTACKING")
	assert(not enemy.attack_timer.is_stopped(), "attack_timer do inimigo deve estar ativo")

	var initial_minhocao_hp := minhocao.current_health

	# Minhocão usa Terremoto (causa atordoamento nos alvos ao redor)
	minhocao.cast_ability()

	assert(enemy.is_stunned(), "Inimigo deve estar atordoado após o Terremoto")
	assert(enemy.attack_timer.is_stopped(), "attack_timer do inimigo deve parar durante o atordoamento")
	print("  ✓ Inimigo atordoado com sucesso e timer de ataque interrompido.")

	# Avançar o tempo simulando expiração do atordoamento
	# Duração base do Minhocão é 1.5s (ou 2.0s). Forçamos expiração no BattleClock ou diminuímos stunned_until_msec:
	enemy.stunned_until_msec = BattleClock.now_msec() - 10

	assert(not enemy.is_stunned(), "Atordoamento deve ter expirado")

	# Simular tick de física para processar recuperação
	enemy._physics_process(0.0166)

	assert(enemy.current_state == BaseUnit3D.State.ATTACKING, "Inimigo deve voltar para State.ATTACKING após recuperação")
	assert(not enemy.attack_timer.is_stopped(), "attack_timer do inimigo deve ter sido reiniciado após o atordoamento")
	print("  ✓ Inimigo recuperou reação e attack_timer voltou a funcionar!")

	# Simular disparo do timer de ataque
	var hp_before_attack := minhocao.current_health
	enemy._on_attack_timer_timeout()
	assert(minhocao.current_health < hp_before_attack, "Inimigo deve conseguir atacar o Minhocão após recuperar do atordoamento")
	print("  ✓ Inimigo desferiu ataque com sucesso após o fim do atordoamento!")

	minhocao.queue_free()
	enemy.queue_free()

	# -------------------------------------------------------------
	# Cenário 2: Alvo morre durante o atordoamento -> Inimigo deve achar novo alvo
	# -------------------------------------------------------------
	print("\n--- Cenário 2: Alvo morre durante atordoamento -> Retargeting ---")
	var target1: BaseUnit3D = UnitSpawner.spawn_unit("tatu_bola", 1, 0)
	var target2: BaseUnit3D = UnitSpawner.spawn_unit("lobo_guara", 1, 0)
	var enemy2: BaseUnit3D = UnitSpawner.spawn_unit("capivara", 1, 1)

	target1.board_position = Vector2i(1, 1)
	target2.board_position = Vector2i(1, 4)
	enemy2.board_position = Vector2i(1, 2)

	root.add_child(target1)
	root.add_child(target2)
	root.add_child(enemy2)

	await process_frame
	await process_frame

	target1.global_position = Vector3(0.0, 0.0, 0.0)
	target2.global_position = Vector3(0.0, 0.0, 3.0)
	enemy2.global_position = Vector3(0.0, 0.0, 1.0)

	enemy2.start_combat()
	target1.start_combat()
	target2.start_combat()

	enemy2.current_target = target1
	enemy2.current_state = BaseUnit3D.State.ATTACKING

	# Atordoa o inimigo2
	enemy2.apply_stun(2.0, "ATORDOADO")
	assert(enemy2.is_stunned(), "Enemy2 deve estar atordoado")

	# Target1 morre durante o atordoamento
	target1.die()

	# Stun expira
	enemy2.stunned_until_msec = BattleClock.now_msec() - 10
	enemy2._physics_process(0.0166)

	assert(enemy2.current_target == target2, "Inimigo deve focar no target2 sobrevivente após se recuperar do atordoamento")
	print("  ✓ Inimigo redirecionou mira para novo alvo vivo após recuperação!")

	target1.queue_free()
	target2.queue_free()
	enemy2.queue_free()

	# -------------------------------------------------------------
	# Cenário 3: Mana cheia durante o atordoamento -> Dispara habilidade ao recuperar
	# -------------------------------------------------------------
	print("\n--- Cenário 3: Conjurador com mana cheia ao recuperar do atordoamento ---")
	var caster: BaseUnit3D = UnitSpawner.spawn_unit("minhocao", 1, 1)
	var dummy: BaseUnit3D = UnitSpawner.spawn_unit("capivara", 1, 0)

	caster.board_position = Vector2i(0, 0)
	dummy.board_position = Vector2i(0, 1)

	root.add_child(caster)
	root.add_child(dummy)

	await process_frame
	await process_frame

	caster.global_position = Vector3(0.0, 0.0, 0.0)
	dummy.global_position = Vector3(0.0, 0.0, 1.2)

	caster.start_combat()
	dummy.start_combat()

	# Atordoa o conjurador e enche a mana
	caster.apply_stun(2.0, "ATORDOADO")
	caster.current_mana = caster.stats.max_mana

	# Stun expira
	caster.stunned_until_msec = BattleClock.now_msec() - 10
	var dummy_hp_before := dummy.current_health
	caster._physics_process(0.0166)

	assert(caster.current_mana < caster.stats.max_mana, "Conjurador deve gastar mana ao disparar habilidade acumulada pós-stun")
	assert(dummy.current_health < dummy_hp_before, "Dummy deve sofrer dano da habilidade disparada")
	print("  ✓ Conjurador disparou habilidade acumulada assim que recuperou do atordoamento!")

	caster.queue_free()
	dummy.queue_free()

	print("\n" + "=".repeat(60))
	print("✅ TODOS OS TESTES DE RECUPERAÇÃO DE ATORDOAMENTO PASSARAM!")
	print("=".repeat(60) + "\n")
	quit(0)
