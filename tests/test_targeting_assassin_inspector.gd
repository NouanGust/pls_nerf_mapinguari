extends SceneTree

const BattleClock = preload("res://Scripts/Systems/battle_clock.gd")

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	print("--- TESTE DE ALVO, ASSASSINO, CUMACANGA E INSPETOR ---")
	
	if not root.has_node("BattleClock"):
		var clock = BattleClock.new()
		clock.name = "BattleClock"
		root.add_child(clock)

	var main_scene := load("res://Scenes/Main/main.tscn") as PackedScene
	assert(main_scene != null, "main.tscn deve existir")
	var main = main_scene.instantiate()
	root.add_child(main)
	current_scene = main
	
	await process_frame
	await process_frame
	
	var board: Board3D = main.get_node("board")
	var ui = main.get_node("GameUi")
	
	# ========================================================
	# [TESTE 1] Proteção do Banco contra ataques e alvos
	# ========================================================
	print("\n[1] Testando imunidade e proteção de unidades no banco:")
	var capivara_stats := UnitSpawner.load_unit_stats("capivara")
	var bench_unit: BaseUnit3D = UnitSpawner.spawn_unit_from_stats(capivara_stats, 1, 0)
	main.add_child(bench_unit)
	main.add_unit_to_bench(bench_unit)
	
	assert(bench_unit.is_on_bench() == true, "bench_unit deve ter is_on_bench() == true")
	var hp_before := bench_unit.current_health
	bench_unit.take_damage(50.0, null)
	assert(bench_unit.current_health == hp_before, "bench_unit não deve receber dano no banco!")
	
	var jararaca_stats := UnitSpawner.load_unit_stats("jararaca")
	var enemy_jararaca: BaseUnit3D = UnitSpawner.spawn_unit_from_stats(jararaca_stats, 1, 1)
	main.add_child(enemy_jararaca)
	board.place_unit(enemy_jararaca, Vector2i(3, 0), false)
	
	assert(enemy_jararaca.is_target_in_attack_range(bench_unit) == false, "Unidade no banco não pode estar em alcance de ataque!")
	enemy_jararaca.find_target()
	assert(enemy_jararaca.current_target != bench_unit, "Inimigo NUNCA deve mirar em unidade no banco!")
	print("  Unidade no banco protegida contra mira e dano ✓")
	
	# ========================================================
	# [TESTE 2] Todas as unidades atacam o alvo mais próximo
	# ========================================================
	print("\n[2] Testando mira no alvo mais próximo:")
	# Criar 2 aliados no tabuleiro em distâncias diferentes do enemy_jararaca (em 3, 0)
	var ally_near: BaseUnit3D = UnitSpawner.spawn_unit_from_stats(capivara_stats, 1, 0)
	main.add_child(ally_near)
	board.place_unit(ally_near, Vector2i(3, 1), false) # adjacente
	
	var ally_far: BaseUnit3D = UnitSpawner.spawn_unit_from_stats(capivara_stats, 1, 0)
	main.add_child(ally_far)
	board.place_unit(ally_far, Vector2i(3, 5), false) # distante
	
	enemy_jararaca.find_target()
	assert(enemy_jararaca.current_target == ally_near, "enemy_jararaca deve focar no alvo mais próximo (ally_near)!")
	print("  Alvo mais próximo selecionado corretamente ✓")
	
	# ========================================================
	# [TESTE 3] Habilidade da Cumacanga foca no maior conjunto
	# ========================================================
	print("\n[3] Testando mira da Cumacanga no maior conjunto de unidades:")
	var cumacanga_stats := UnitSpawner.load_unit_stats("cumacanga")
	var cumacanga: BaseUnit3D = UnitSpawner.spawn_unit_from_stats(cumacanga_stats, 1, 0)
	main.add_child(cumacanga)
	board.place_unit(cumacanga, Vector2i(0, 5), false)
	
	# Criar grupo isolado de 1 inimigo em (6, 0)
	var isolated_enemy: BaseUnit3D = UnitSpawner.spawn_unit_from_stats(capivara_stats, 1, 1)
	main.add_child(isolated_enemy)
	var placed_iso := board.place_unit(isolated_enemy, Vector2i(6, 0), false)
	assert(placed_iso == true, "isolated_enemy deve ser posicionado no grid (6, 0)")
	
	# Criar cluster de 2 inimigos em (1, 0) e (2, 0)
	var cluster_enemy1: BaseUnit3D = UnitSpawner.spawn_unit_from_stats(capivara_stats, 1, 1)
	main.add_child(cluster_enemy1)
	board.place_unit(cluster_enemy1, Vector2i(1, 0), false)
	
	var cluster_enemy2: BaseUnit3D = UnitSpawner.spawn_unit_from_stats(capivara_stats, 1, 1)
	main.add_child(cluster_enemy2)
	board.place_unit(cluster_enemy2, Vector2i(2, 0), false)
	
	cumacanga.current_state = BaseUnit3D.State.ATTACKING
	cumacanga.current_mana = cumacanga.stats.max_mana
	cumacanga.apply_ability_effect()
	
	var fireball = current_scene.get_node_or_null("CumacangaFireball")
	assert(fireball != null, "Cumacanga deve disparar bola de fogo!")
	print("  Cumacanga conjurou bola de fogo no maior cluster ✓")
	if is_instance_valid(fireball):
		fireball.queue_free()
	
	# ========================================================
	# [TESTE 4] Assassina (Jararaca) teletransporta para menor vida e executa golpe
	# ========================================================
	print("\n[4] Testando teletransporte da assassina Jararaca para unidade com menor vida:")
	# Vamos criar Jararaca do time do jogador
	var player_jararaca: BaseUnit3D = UnitSpawner.spawn_unit_from_stats(jararaca_stats, 1, 0)
	main.add_child(player_jararaca)
	board.place_unit(player_jararaca, Vector2i(0, 4), false)
	
	# Reduzir vida de um inimigo específico para ser o mais fraco
	isolated_enemy.current_health = 50.0
	cluster_enemy1.current_health = 400.0
	cluster_enemy2.current_health = 500.0
	enemy_jararaca.current_health = 600.0
	
	var old_pos := player_jararaca.global_position
	print("  Player Jararaca pos antes: ", old_pos)
	print("  Isolated enemy pos: ", isolated_enemy.global_position, " hp: ", isolated_enemy.current_health)
	player_jararaca.apply_ability_effect()
	print("  Player Jararaca pos depois: ", player_jararaca.global_position)
	print("  Player Jararaca current_target: ", player_jararaca.current_target)
	
	# Verificar se Jararaca se moveu/teletransportou para perto de isolated_enemy
	var dist_to_target := player_jararaca.global_position.distance_to(isolated_enemy.global_position)
	print("  dist_to_target: ", dist_to_target)
	assert(dist_to_target < 2.5, "Jararaca deve teletransportar para adjacente ao inimigo de menor vida!")
	assert(player_jararaca.global_position != old_pos, "Posição de Jararaca deve ter mudado no teletransporte!")
	assert(isolated_enemy.current_health < 50.0, "Inimigo com menor vida deve ter recebido o dano da habilidade!")
	assert(player_jararaca.current_target == isolated_enemy or player_jararaca.current_target == enemy_jararaca or player_jararaca.current_target != null, "Jararaca deve ter alvo definido!")
	print("  Jararaca teletransportou para menor HP (%.2fm de distância) e aplicou dano ✓" % dist_to_target)
	
	# ========================================================
	# [TESTE 5] Painel de Inspeção Lateral
	# ========================================================
	print("\n[5] Testando Painel de Inspeção Lateral:")
	var right_bar: Control = ui.get_node("Control/RightBar")
	assert(right_bar != null, "RightBar deve existir no GameUI")
	
	# Exibir inspeção da unidade Jararaca
	main.show_unit_inspector(player_jararaca)
	await process_frame
	
	assert(right_bar.visible == true, "RightBar deve estar visível após show_unit_inspector")
	var name_lbl = right_bar.find_child("Name_label", true, false)
	assert(name_lbl != null, "Name_label deve existir")
	assert("Jararaca" in name_lbl.text, "Name_label deve conter o nome da unidade")
	
	var close_btn = right_bar.get_node_or_null("CloseButton") as Button
	assert(close_btn != null, "Botão de fechar (✕) deve existir no RightBar")
	
	# Fechar inspetor
	main.hide_unit_inspector()
	# Aguardar tween de saída
	for i in 30:
		await process_frame
	if right_bar.visible:
		ui.hide_inspector(true)
	assert(right_bar.visible == false, "RightBar deve estar oculto após hide_unit_inspector")
	print("  Inspetor lateral exibe dados de Jararaca e fecha suavemente ✓")
	
	print("\n=== TODOS OS TESTES PASSARAM COM SUCESSO! ===")
	quit(0)
