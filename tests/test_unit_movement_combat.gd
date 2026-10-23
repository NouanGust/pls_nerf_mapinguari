extends SceneTree

const BattleClock = preload("res://Scripts/Systems/battle_clock.gd")

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	print("\n" + "=".repeat(60))
	print("TESTE DE MOVIMENTAÇÃO E COMBATE DAS UNIDADES")
	print("=".repeat(60) + "\n")
	
	if not root.has_node("BattleClock"):
		var clock = BattleClock.new()
		clock.name = "BattleClock"
		root.add_child(clock)

	UnitSpawner.load_all_units()
	
	var ally: BaseUnit3D = UnitSpawner.spawn_unit("lobo_guara", 1, 0)
	var enemy: BaseUnit3D = UnitSpawner.spawn_unit("capivara", 1, 1)
	assert(ally != null, "Lobo-guará deve ser instanciado")
	assert(enemy != null, "Capivara deve ser instanciada")
	
	# Indicar que ambas estão em células de tabuleiro (fora do banco)
	ally.board_position = Vector2i(2, 1)
	enemy.board_position = Vector2i(2, 5)
	
	root.add_child(ally)
	root.add_child(enemy)
	
	await process_frame
	await process_frame
	
	# Colocar distantes no plano X/Z
	ally.global_position = Vector3(0.0, 0.0, 4.0)
	enemy.global_position = Vector3(0.0, 0.0, -4.0)
	
	print("Ally inicial: pos=%v, state=%s, on_bench=%s" % [ally.global_position, ally.current_state, ally.is_on_bench()])
	print("Enemy inicial: pos=%v, state=%s, on_bench=%s" % [enemy.global_position, enemy.current_state, enemy.is_on_bench()])
	
	# Iniciar combate
	ally.start_combat()
	enemy.start_combat()
	
	assert(ally.current_target == enemy, "Ally deve ter mirado no enemy")
	assert(enemy.current_target == ally, "Enemy deve ter mirado no ally")
	assert(ally.current_state == BaseUnit3D.State.MOVING, "Ally deve estar no estado MOVING")
	assert(enemy.current_state == BaseUnit3D.State.MOVING, "Enemy deve estar no estado MOVING")
	
	var initial_distance := ally.global_position.distance_to(enemy.global_position)
	print("Distância inicial: %.2fm" % initial_distance)
	
	# Simular 60 quadros de física (1 segundo de movimento)
	for i in range(60):
		ally._physics_process(0.0166)
		enemy._physics_process(0.0166)
	
	var intermediate_distance := ally.global_position.distance_to(enemy.global_position)
	print("Distância após 60 ticks: %.2fm" % intermediate_distance)
	assert(intermediate_distance < initial_distance - 0.5, "Unidades DEVEM se mover uma em direção à outra! Dist: %.2f vs %.2f" % [intermediate_distance, initial_distance])
	print("  ✓ Unidades se moveram continuamente sem travar!")
	
	# Continuar simulando até que alcancem o alcance de ataque
	var reached_attack := false
	for i in range(240):
		ally._physics_process(0.0166)
		enemy._physics_process(0.0166)
		if ally.current_state == BaseUnit3D.State.ATTACKING or enemy.current_state == BaseUnit3D.State.ATTACKING:
			reached_attack = true
			break
	
	var final_distance := ally.global_position.distance_to(enemy.global_position)
	print("Distância final: %.2fm, Ally State: %s, Enemy State: %s" % [final_distance, ally.current_state, enemy.current_state])
	assert(reached_attack or final_distance <= ally.get_attack_range_meters(), "Unidade deve ter alcançado o range de ataque")
	print("  ✓ Transição de MOVING para ATTACKING concluída com sucesso!")
	
	ally.queue_free()
	enemy.queue_free()
	
	print("\n" + "=".repeat(60))
	print("✅ TESTE DE MOVIMENTAÇÃO CONCLUÍDO COM SUCESSO!")
	print("=".repeat(60) + "\n")
	quit(0)
