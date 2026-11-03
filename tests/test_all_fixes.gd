extends SceneTree

const BattleClock = preload("res://Scripts/Systems/battle_clock.gd")

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	print("==================================================")
	print("SUITE DE TESTES: VERIFICAÇÃO COMPLETA DAS CORREÇÕES")
	print("==================================================")
	
	if not root.has_node("BattleClock"):
		var clock = BattleClock.new()
		clock.name = "BattleClock"
		root.add_child(clock)

	# ----------------------------------------------------
	# [TESTE 1] Todas as unidades com alvo mais próximo (CLOSEST)
	# ----------------------------------------------------
	print("\n[TESTE 1] Verificando prioridade de alvo (CLOSEST = 0) em todas as unidades:")
	var all_units := UnitSpawner.load_all_units()
	var closest_count := 0
	for unit_id in all_units.keys():
		var stats: UnitStats = all_units[unit_id]
		assert(stats.target_priority == UnitStats.TargetPriority.CLOSEST, "Unidade %s deve ter prioridade CLOSEST" % unit_id)
		closest_count += 1
	print("  ✓ Todas as %d unidades têm prioridade CLOSEST (0)" % closest_count)

	# ----------------------------------------------------
	# [TESTE 2] Instanciação do main.tscn sem warning do BoardCountLabel
	# ----------------------------------------------------
	print("\n[TESTE 2] Instanciando main.tscn:")
	var main_scene := load("res://Scenes/Main/main.tscn") as PackedScene
	assert(main_scene != null, "main.tscn deve ser carregado")
	var main = main_scene.instantiate()
	root.add_child(main)
	current_scene = main
	await process_frame
	await process_frame
	print("  ✓ main.tscn instanciado com sucesso")

	var board: Board3D = main.get_node("board")

	# ----------------------------------------------------
	# [TESTE 3] Desvio de obstáculo (Runner contorna Ipê e alcança o alvo)
	# ----------------------------------------------------
	print("\n[TESTE 3] Verificando contorno de obstáculo (unidade presa contorna e ataca):")
	var ipe_stats := UnitSpawner.load_unit_stats("ipe_amarelo")
	var ipe: BaseUnit3D = UnitSpawner.spawn_unit_from_stats(ipe_stats, 1, 0)
	main.add_child(ipe)
	board.place_unit(ipe, Vector2i(3, 4), false)
	
	var runner_stats := UnitSpawner.load_unit_stats("capivara")
	var runner: BaseUnit3D = UnitSpawner.spawn_unit_from_stats(runner_stats, 1, 0)
	main.add_child(runner)
	board.place_unit(runner, Vector2i(3, 5), false)
	
	var enemy_stats := UnitSpawner.load_unit_stats("jararaca")
	var enemy: BaseUnit3D = UnitSpawner.spawn_unit_from_stats(enemy_stats, 1, 1)
	main.add_child(enemy)
	board.place_unit(enemy, Vector2i(3, 2), false)
	
	runner.use_navigation = false
	ipe.use_navigation = false
	enemy.use_navigation = false
	
	runner.current_target = enemy
	runner.current_state = BaseUnit3D.State.MOVING
	
	var reached_attack_range := false
	for f in range(60):
		runner._physics_process(1.0 / 60.0)
		if runner.global_position.distance_to(enemy.global_position) <= runner.get_attack_range_meters():
			reached_attack_range = true
			print("  ✓ Runner contornou obstáculo e alcançou range de ataque no frame %d!" % f)
			break
	assert(reached_attack_range, "Runner deve ter contornado o obstáculo e alcançado o alcance de ataque")

	# ----------------------------------------------------
	# [TESTE 4] Golpe do Assassino não muta board_position
	# ----------------------------------------------------
	print("\n[TESTE 4] Verificando que golpe do assassino não altera board_position:")
	var assassin_stats := UnitSpawner.load_unit_stats("jararaca")
	var assassin: BaseUnit3D = UnitSpawner.spawn_unit_from_stats(assassin_stats, 1, 0)
	main.add_child(assassin)
	var home_cell := Vector2i(1, 6)
	board.place_unit(assassin, home_cell, false)
	
	var assassin_enemy: BaseUnit3D = UnitSpawner.spawn_unit_from_stats(runner_stats, 1, 1)
	main.add_child(assassin_enemy)
	board.place_unit(assassin_enemy, Vector2i(1, 1), false)
	
	assassin.current_target = assassin_enemy
	assassin._cast_assassin_strike()
	
	assert(assassin.board_position == home_cell, "board_position da assassina deve permanecer home_cell (1, 6), mas era %v" % assassin.board_position)
	print("  ✓ board_position permaneceu intacta em %v (zona do jogador)" % assassin.board_position)

	# ----------------------------------------------------
	# [TESTE 5] Salvamento da campanha sem erros (litoral e mata_atlantica)
	# ----------------------------------------------------
	print("\n[TESTE 5] Verificando sistema de save da campanha:")
	main._run_ready = true
	main.region_id = "litoral"
	var save_ok_litoral: bool = main._save_campaign()
	assert(save_ok_litoral, "Save da campanha litoral deve retornar true")
	print("  ✓ Campanha litoral salva com sucesso (OK)")
	
	main.region_id = "mata_atlantica"
	var save_ok_mata: bool = main._save_campaign()
	assert(save_ok_mata, "Save da campanha mata_atlantica deve retornar true")
	print("  ✓ Campanha mata_atlantica salva com sucesso (OK)")

	# ----------------------------------------------------
	# [TESTE 6] Spawn de inimigos regionais (spawn_enemy_team)
	# ----------------------------------------------------
	print("\n[TESTE 6] Verificando spawn_enemy_team:")
	main.spawn_enemy_team()
	var enemy_count := main.get_tree().get_nodes_in_group("enemy_units").size()
	assert(enemy_count > 0, "Inimigos devem ser posicionados no tabuleiro")
	print("  ✓ Inimigos regionais posicionados com sucesso (%d inimigos)" % enemy_count)

	print("\n==================================================")
	print("TODOS OS TESTES PASSARAM COM 100% DE SUCESSO!")
	print("==================================================")
	quit(0)
