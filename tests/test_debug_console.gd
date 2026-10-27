extends SceneTree

const Commands = preload("res://Scripts/Systems/debug_commands.gd")
var failures := 0

func _initialize() -> void:
	_run.call_deferred()

func check(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		push_error(message)

func _key(code: Key) -> void:
	var event := InputEventKey.new()
	event.keycode = code
	event.pressed = true
	Input.parse_input_event(event)
	Input.flush_buffered_events()
	event = InputEventKey.new()
	event.keycode = code
	Input.parse_input_event(event)
	Input.flush_buffered_events()

func _run() -> void:
	# Run with APPDATA redirected to a temporary folder: never edit a player's save.
	if "debug-console-test" not in OS.get_environment("APPDATA"):
		push_error("Execute com APPDATA apontando para uma pasta temporária debug-console-test.")
		quit(1)
		return
	var game = load("res://Scenes/Main/main.tscn").instantiate()
	print("TEST USER DATA: ", OS.get_user_data_dir())
	root.add_child(game)
	current_scene = game
	for i in 120:
		await process_frame
		if game._run_ready:
			break
	check(game._run_ready, "Partida deve carregar")
	if not game._run_ready:
		quit(1)
		return
	var console = game.debug_console
	check(console != null, "Console integrado à partida")
	var commands := Commands.new()
	commands.game = game
	var original_gold: int = game.player_gold
	check("Ouro" in commands.execute(" GOLD   100 "), "Comandos aceitam espaços e caixa alta")
	check(game.player_gold == original_gold + 100, "Gold adicionado")
	for invalid in ["gold -5", "gold abc", "gold 1 2", "gold 1.5", "gold 1000000000000000000000"]:
		commands.execute(invalid)
	check(game.player_gold == original_gold + 100, "Argumentos inválidos não alteram ouro")
	commands.execute("setrak 4")
	check(game.win_streak == 4 and game.loss_streak == 0, "Alias setrak concede streak")
	commands.execute("streak 3 loss")
	commands.execute("streak 8")
	commands.execute("streak 2 desconhecido")
	check(game.win_streak == 0 and game.loss_streak == 3, "Streak loss e validação")
	commands.execute("acelerar 2")
	check(Engine.time_scale == 2.0, "Velocidade alterada")
	for invalid in ["speed 0", "speed -1", "speed 100", "speed nan", "speed inf"]:
		commands.execute(invalid)
	check(Engine.time_scale == 2.0, "Velocidades inválidas rejeitadas")
	commands.execute("speed 1")
	check("mapinguari" in commands.execute("unidades mapinguari"), "Lista de IDs filtrável")
	commands.execute("unidade inexistente")
	commands.execute("unidade mapinguari 0")
	commands.execute("unidade mapinguari 1 5")
	check(game.bench_units.is_empty(), "Spawn inválido não cria unidades")
	commands.execute("unidade mapinguari 1 3")
	check(game.bench_units.size() == 1 and game.bench_units[0].star_level == 3, "Unidade entregue com estrelas")
	commands.execute("unidade saci 9")
	check(game.bench_units.size() == 1, "Banco cheio rejeita entrega completa")
	commands.execute("xp 8")
	check(game.player_level > 1, "XP sobe de nível")
	commands.execute("vida 75")
	check(game.player_health == 75, "Vida ajustada")
	check("desconhecido" in commands.execute("nao_existe"), "Comando desconhecido tem resposta")

	_key(KEY_F8)
	await process_frame
	check(console.is_open and paused, "F8 abre e pausa a partida")
	check(console.command_input.has_focus(), "Campo recebe foco")
	if "--capture" in OS.get_cmdline_user_args():
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://.godot/debug-console.png")
	original_gold = game.player_gold
	var original_orbit: bool = game.camera.auto_orbit_enabled
	for code in [KEY_R, KEY_Q, KEY_L, KEY_S, KEY_SPACE, KEY_O]:
		_key(code)
	check(game.player_gold == original_gold and not game.combat_active, "Digitar não compra nem inicia combate")
	check(game.camera.auto_orbit_enabled == original_orbit, "Digitar não movimenta câmera")
	console._submit("gold 7")
	check(game.player_gold == original_gold + 7, "Console executa comando durante pausa")
	console.command_input.text = "rascunho"
	_key(KEY_UP)
	check(console.command_input.text == "gold 7", "Seta cima recupera histórico")
	_key(KEY_DOWN)
	check(console.command_input.text == "rascunho", "Seta baixo restaura rascunho")
	_key(KEY_ESCAPE)
	check(not console.is_open and not paused and not game._overlay.is_open, "Esc fecha apenas console")
	game._open_pause()
	console.open()
	console.close()
	check(paused and game._overlay.is_open, "Fechar console preserva pausa anterior")
	game._overlay.close()
	game._resume_game()

	console.open()
	original_gold = game.player_gold
	commands.execute("round 2")
	check(game.current_round == 2 and game.player_gold == original_gold, "Salto direto não concede recompensas")
	commands.execute("streak 0")
	commands.execute("avancar")
	check(game.current_round == 3 and game.win_streak == 1, "Avanço concede vitória e streak")
	check(game.player_gold == original_gold + game.gold_on_win + 1, "Avanço concede ouro normal")
	check(not game.round_resolution_pending and not game.has_node("CombatReportLayer"), "Avanço pula relatório")
	check(game.get_player_units_on_board_count() == 0, "Avanço não move banco")
	game.start_combat()
	check(game.combat_active, "Combate iniciado para testar pulo")
	var generation: int = game._combat_generation
	commands.execute("round 9")
	check(game.current_round == 3, "Salto direto bloqueado durante combate")
	var player: BaseUnit3D = game.get_tree().get_nodes_in_group("player_units")[0]
	player.die()
	commands.execute("pular")
	check(game.current_round == 4 and not game.combat_active, "Pular encerra combate")
	check(game._combat_generation > generation, "Monitor antigo é invalidado")
	for unit in game.board.get_all_units():
		check(not unit.in_combat, "Preparação não mantém sobreviventes em combate")
	check(player.current_health == player.get_max_health() and player.visible, "Pular revive combatentes mortos")
	game.round_resolution_pending = true
	original_gold = game.player_gold
	commands.execute("gold 1")
	check(game.player_gold == original_gold, "Relatório bloqueia alteração de estado")
	game.round_resolution_pending = false
	console.close()
	await create_timer(0.4).timeout
	check(game.current_round == 4 and not game.round_resolution_pending, "Monitor antigo não encerra novo round")
	check(game._save_campaign(), "Campanha modificada pode ser salva")
	var saved: Dictionary = game.CampaignStore.read_slot(game.region_id)
	check(saved.get("run", {}).get("round", 0) == 4, "Round de debug persistido")
	check(saved.get("run", {}).get("gold", -1) == game.player_gold, "Ouro de debug persistido")
	commands.execute("speed 3")
	game._open_pause()
	console.open()
	game.enemy_level = 9
	commands.execute("pular")
	check(game._campaign_state == "won", "Pular desafio final encerra campanha")
	await process_frame
	await process_frame
	check(not paused and Engine.time_scale == 1.0, "Sair da cena restaura pausa e velocidade")
	check(current_scene != game, "Vitória final retorna ao menu mesmo com console sobre a pausa")
	current_scene.queue_free()
	await process_frame
	print("DEBUG CONSOLE: %d falhas" % failures)
	quit(1 if failures else 0)
