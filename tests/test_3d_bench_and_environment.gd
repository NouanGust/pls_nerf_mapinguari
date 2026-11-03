extends SceneTree

const RegionEnvironment = preload("res://Scripts/Environment/region_environment.gd")

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	print("--- TESTE DE BANCO 3D E AMBIENTE DINAMICO ---")
	
	# 0. Inicializar Autoloads necessários
	if not root.has_node("BattleClock"):
		var clock = preload("res://Scripts/Systems/battle_clock.gd").new()
		clock.name = "BattleClock"
		root.add_child(clock)

	# 1. Carregar main.tscn
	var main_scene := load("res://Scenes/Main/main.tscn") as PackedScene
	assert(main_scene != null, "main.tscn deve existir")
	var main = main_scene.instantiate()
	root.add_child(main)
	current_scene = main
	
	await process_frame
	await process_frame
	
	var board: Board3D = main.get_node("board")
	assert(board != null, "board deve existir")
	
	# 2. Testar coordenadas dos 9 pedestais do banco 3D
	print("\n[1] Verificando coordenadas dos 9 pedestais 3D:")
	for slot in range(9):
		var pos: Vector3 = board.get_bench_slot_world_position(slot)
		var expected_x := (slot - 4) * board.BENCH_SLOT_SPACING
		assert(is_equal_approx(pos.x, expected_x), "Slot %d X incorreto" % slot)
		assert(is_equal_approx(pos.z, board.BENCH_Z), "Slot %d Z incorreto" % slot)
		assert(board.is_bench_position(pos), "Posicao do slot %d deve ser reconhecida como bench" % slot)
		var detected_slot := board.get_bench_slot_from_world_position(pos)
		assert(detected_slot == slot, "Slot detectado (%d) diferente do esperado (%d)" % [detected_slot, slot])
		print("  Slot %d: (%.2f, %.2f, %.2f) -> Detectado: %d ✓" % [slot, pos.x, pos.y, pos.z, detected_slot])
	
	# 3. Testar adicao de unidade ao banco 3D
	print("\n[2] Testando adicao de unidade na reserva 3D:")
	var capivara_stats := UnitSpawner.load_unit_stats("capivara")
	assert(capivara_stats != null, "Stats de capivara devem carregar")
	var unit := UnitSpawner.spawn_unit_from_stats(capivara_stats, 1, 0)
	assert(unit != null, "Unidade deve instanciar")
	main.add_child(unit)
	
	var added: bool = main.add_unit_to_bench(unit)
	assert(added == true, "Unidade deve ser adicionada ao banco")
	assert(main.bench_units.size() == 1, "Tamanho do banco deve ser 1")
	assert(unit.visible == true, "Unidade da reserva 3D deve estar VISIVEL!")
	assert(unit.board_position == Vector2i(0, -1), "board_position deve ser (0, -1)")
	print("  Unidade na reserva 3D colocada com sucesso no slot 0 ✓")
	
	# 4. Testar reposicionamento e alinhamento do banco 3D
	var lobo_stats := UnitSpawner.load_unit_stats("lobo_guara")
	var unit2 := UnitSpawner.spawn_unit_from_stats(lobo_stats, 1, 0)
	main.add_child(unit2)
	main.add_unit_to_bench(unit2)
	assert(main.bench_units.size() == 2, "Tamanho do banco deve ser 2")
	assert(unit2.board_position == Vector2i(1, -1), "Segunda unidade deve ocupar slot 1")
	print("  Segunda unidade colocada no slot 1 ✓")
	
	# 5. Testar remocao e realinhamento
	main._sell_unit(unit, "bench")
	assert(main.bench_units.size() == 1, "Apos vender slot 0, banco deve ter 1 unidade")
	assert(unit2.board_position == Vector2i(0, -1), "Unidade 2 deve ter deslizado para o slot 0")
	print("  Realinhamento automatico de pedestais validado com sucesso ✓")
	
	# 6. Testar perfis de iluminacao e atmosfera dinamica
	print("\n[3] Testando perfis de iluminacao e atmosfera dinamica por regiao:")
	var biomes := ["amazonia", "cerrado", "caatinga", "pantanal", "mata_atlantica", "litoral"]
	for biome in biomes:
		board.apply_region_environment(biome, 0.0)
		var profile := RegionEnvironment.get_profile(biome)
		print("  Bioma '%s' (%s) aplicado com sucesso ✓" % [biome, profile["name"]])
	
	# 7. Testar Layout do Botao de Travar e Barra da Loja
	print("\n[4] Testando botao de travar e interface da barra da loja:")
	var ui = main.get_node("GameUi")
	var bottom_bar: Control = ui.get_node("Control/BottomBar")
	var lock_button: Button = bottom_bar.get_node_or_null("LockButton")
	assert(lock_button != null, "LockButton deve existir como filho de BottomBar")
	
	var gold_container: Control = bottom_bar.get_node_or_null("GoldContainer")
	assert(gold_container != null, "GoldContainer deve existir")
	
	# Verificar que LockButton e GoldContainer estao na mesma linha de cabecalho sem colisao
	print("  GoldContainer pos: ", gold_container.position, " size: ", gold_container.size)
	print("  LockButton pos: ", lock_button.position, " size: ", lock_button.size)
	assert(lock_button.position.x >= gold_container.position.x + gold_container.size.x, "LockButton deve ficar a direita do GoldContainer")
	assert(lock_button.position.y >= 0 and lock_button.position.y < 45.0, "LockButton deve estar no cabecalho da barra")
	assert(lock_button.position.y + lock_button.size.y <= bottom_bar.size.y, "LockButton deve caber dentro da BottomBar sem vazar!")
	print("  Botao de travar perfeitamente encaixado dentro da barra inferior ✓")
	
	# 8. Verificar que BenchPanel 2D esta oculto
	var bench_panel: Control = ui.get_node("Control/BenchPanel")
	assert(bench_panel != null, "BenchPanel deve existir no grafo de cena")
	assert(bench_panel.visible == false, "BenchPanel 2D deve estar OCULTO da interface!")
	print("  Banco 2D da interface removido/ocultado da tela com sucesso ✓")
	
	print("\n=== TODOS OS TESTES PASSARAM COM 100% DE SUCESSO! ===")
	quit(0)
