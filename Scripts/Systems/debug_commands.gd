extends RefCounted

const HELP := """ajuda — mostra os comandos (help)
avancar / pular — conclui o round como vitória, sem relatório (next / skip)
round N — vai ao round N na preparação, sem conceder recompensas
acelerar N — velocidade de 0.25 a 4; acelerar 1 restaura (speed)
gold N — adiciona N de ouro (ouro)
streak N [win|loss] — define sequência de 0 a 5 (setrak)
unidades [filtro] — lista IDs e nomes disponíveis (units)
unidade ID [quantidade] [estrelas] — entrega no banco (unit / spawn)
xp N — adiciona experiência
vida N — define vida entre 1 e 100 (hp)
tabuleiro [horror|realista] — alterna estilo do tabuleiro da Caatinga (board)
status — mostra o estado atual
limpar — limpa o console (clear)
fechar — volta ao jogo (exit)
Exemplo: unidade mapinguari 1 3
As alterações de recursos e rounds são salvas na campanha."""

var game: Node

func execute(command_line: String) -> String:
	var args := command_line.strip_edges().to_lower().replace("\t", " ").split(" ", false)
	if args.is_empty():
		return ""
	var command := args[0]
	args.remove_at(0)
	if command in ["ajuda", "help", "?"]:
		return HELP
	if command in ["unidades", "units"]:
		return _list_units(" ".join(args))
	if not is_instance_valid(game) or not game._run_ready or game._leaving or game._load_failed:
		return "Erro: aguarde a partida terminar de carregar."
	if command == "status":
		return "Round %d | Ouro %d | Vida %d | Nível %d | XP %d | Streak %dV/%dD | %.2fx | %s" % [
			game.current_round, game.player_gold, game.player_health, game.player_level,
			game.player_xp, game.win_streak, game.loss_streak, Engine.time_scale,
			"combate" if game.combat_active else "preparação"]
	# As transições possuem rotinas assíncronas próprias. Não trocar o estado
	# enquanto elas ainda estiverem escrevendo nele.
	if game._entry_in_progress or game.cutscene_in_progress or game.round_resolution_pending or game._campaign_state != "active":
		return "Erro: feche o console e conclua a transição ou o relatório antes de alterar a partida."
	match command:
		"avancar", "avançar", "pular", "next", "skip":
			if not args.is_empty():
				return "Uso: avancar ou pular. Para escolher um destino: round N."
			# Usa a mesma resolução da batalha, inclusive XP, streak e fim de campanha.
			game.combat_active = true
			game.end_combat(true, false, "", true)
			return "Round concluído como vitória; recompensas concedidas."
		"round":
			if not _integer_arg(args, 1, 10000):
				return "Uso: round N (inteiro de 1 a 10000)."
			if game.combat_active:
				return "Erro: use pular para encerrar o combate antes de escolher um round."
			game.current_round = int(args[0])
			# Resultados do destino e dos rounds posteriores deixam de ser válidos.
			for key in game.round_outcomes.keys():
				if int(key) >= game.current_round:
					game.round_outcomes.erase(key)
			game.prepare_next_round()
			return "Preparando round %d, sem recompensas extras." % game.current_round
		"acelerar", "speed", "velocidade":
			if args.size() != 1 or not args[0].is_valid_float():
				return "Uso: acelerar N (0.25 a 4; 1 = normal)."
			var speed := float(args[0])
			if not is_finite(speed) or speed < 0.25 or speed > 4.0:
				return "Erro: velocidade deve estar entre 0.25 e 4."
			Engine.time_scale = speed
			return "Velocidade: %.2fx (aplicada ao fechar o console)." % speed
		"gold", "ouro":
			if not _integer_arg(args, 1, 1000000):
				return "Uso: gold N (inteiro de 1 a 1000000)."
			game.player_gold = mini(game.player_gold + int(args[0]), 1000000000)
			game.update_ui()
			return "Ouro: %d." % game.player_gold
		"streak", "setrak":
			if args.size() < 1 or args.size() > 2 or not _integer_arg(PackedStringArray([args[0]]), 0, 5):
				return "Uso: streak N [win|loss] (0 a 5; padrão: win)."
			var kind := args[1] if args.size() == 2 else "win"
			if kind not in ["win", "loss", "vitoria", "vitória", "derrota"]:
				return "Erro: use win (vitória) ou loss (derrota)."
			var wins := kind in ["win", "vitoria", "vitória"]
			game.win_streak = int(args[0]) if wins else 0
			game.loss_streak = 0 if wins else int(args[0])
			game.update_ui()
			return "Streak: %d vitórias / %d derrotas." % [game.win_streak, game.loss_streak]
		"unidade", "unit", "spawn":
			return _give_unit(args)
		"xp":
			if not _integer_arg(args, 1, 100000):
				return "Uso: xp N (inteiro de 1 a 100000)."
			var progress := game.Progression.gain_xp(game.player_level, game.player_xp, int(args[0])) as Vector2i
			game.player_level = progress.x
			game.player_xp = progress.y
			game.update_ui()
			return "Nível %d | XP %d." % [game.player_level, game.player_xp]
		"vida", "hp":
			if not _integer_arg(args, 1, 100):
				return "Uso: vida N (inteiro de 1 a 100)."
			game.player_health = int(args[0])
			game.update_ui()
			return "Vida: %d." % game.player_health
		"tabuleiro", "board":
			var gs: Node = game.get_node_or_null("/root/GameSettings")
			var target_style: String = args[0] if not args.is_empty() else ""
			if target_style.is_empty():
				var cur: String = str(gs.get("caatinga_board_variant")) if gs else "horror"
				target_style = "realista" if cur != "realista" else "horror"
			elif target_style in ["realista", "realistic", "real"]:
				target_style = "realista"
			elif target_style in ["horror", "padrao", "padrão", "default"]:
				target_style = "horror"
			else:
				return "Uso: tabuleiro [horror|realista]"
			if gs and gs.has_method("update_setting"):
				gs.update_setting("caatinga_board_variant", target_style)
			if is_instance_valid(game.board):
				game.board.caatinga_board_style = target_style
				game.board.apply_region_environment("caatinga_realista" if target_style == "realista" else "caatinga", 0.35)
			return "Tabuleiro da Caatinga alterado para: %s." % target_style
	return "Erro: comando desconhecido '%s'. Digite ajuda." % command

func _integer_arg(args: PackedStringArray, minimum: int, maximum: int) -> bool:
	return args.size() == 1 and args[0].length() <= 10 and args[0].is_valid_int() and int(args[0]) >= minimum and int(args[0]) <= maximum

func _list_units(filter_text: String) -> String:
	var units := UnitSpawner.load_all_units()
	var ids: Array = units.keys()
	ids.sort()
	var lines := PackedStringArray()
	for id in ids:
		var stats: UnitStats = units[id]
		if filter_text.is_empty() or filter_text in str(id) or filter_text in stats.unit_name.to_lower():
			lines.append("%s — %s (T%d)" % [id, stats.unit_name, stats.tier])
	return "Nenhuma unidade encontrada." if lines.is_empty() else "\n".join(lines)

func _give_unit(args: PackedStringArray) -> String:
	if args.is_empty() or args.size() > 3:
		return "Uso: unidade ID [quantidade 1..9] [estrelas 1..4]. Consulte unidades."
	var units := UnitSpawner.load_all_units()
	if not units.has(args[0]):
		return "Erro: ID desconhecido. Use unidades [filtro] para consultar."
	var count := 1
	var stars := 1
	if args.size() >= 2:
		if not _integer_arg(PackedStringArray([args[1]]), 1, 9):
			return "Erro: quantidade deve ser um inteiro de 1 a 9."
		count = int(args[1])
	if args.size() == 3:
		if not _integer_arg(PackedStringArray([args[2]]), 1, 4):
			return "Erro: estrelas devem ser um inteiro de 1 a 4."
		stars = int(args[2])
	# Valida toda a entrega antes de criar qualquer unidade.
	var free_slots: int = game.max_bench_size - game.bench_units.size()
	if count > free_slots:
		return "Erro: banco com %d vaga(s); libere espaço para receber %d unidade(s)." % [free_slots, count]
	for i in count:
		var unit := UnitSpawner.spawn_unit_from_stats(units[args[0]], stars, 0)
		if not unit:
			return "Erro: não foi possível criar a unidade."
		game.add_child(unit)
		if not game.add_unit_to_bench(unit):
			unit.queue_free()
			return "Erro: não foi possível colocar a unidade no banco."
	game._resolve_unit_merges()
	game.update_ui()
	return "Entregue: %d x %s (%d estrelas). Fusões normais aplicadas na preparação." % [count, args[0], stars]
