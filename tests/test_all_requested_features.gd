extends SceneTree

const BattleClock = preload("res://Scripts/Systems/battle_clock.gd")
const BiodiversityModels = preload("res://Scripts/Units/biodiversity_models.gd")
const ResponsiveLayout = preload("res://Scripts/UI/responsive_layout.gd")

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	print("==================================================")
	print("SUITE DE TESTES: TODAS AS NOVAS FUNCIONALIDADES")
	print("==================================================")

	if not root.has_node("BattleClock"):
		var clock = BattleClock.new()
		clock.name = "BattleClock"
		root.add_child(clock)
	if not root.has_node("ResponsiveLayout"):
		var rl = ResponsiveLayout.new()
		rl.name = "ResponsiveLayout"
		root.add_child(rl)

	var main_scene := load("res://Scenes/Main/main.tscn") as PackedScene
	assert(main_scene != null, "main.tscn deve carregar")
	var main = main_scene.instantiate()
	root.add_child(main)
	current_scene = main
	await process_frame
	await process_frame

	var board: Board3D = main.board
	var ui: GameUI = main.ui
	assert(board != null, "board deve existir")
	assert(ui != null, "ui deve existir")

	# ----------------------------------------------------
	# [1] ECONOMIA: JUROS, SEQUÊNCIAS (1..3) E EMPATE
	# ----------------------------------------------------
	print("\n[1] Verificando Economia (Juros, Sequências 1..3 e Empate):")
	# Juros (+1 a cada 10g)
	assert(main.calculate_interest(0) == 0, "0g -> 0 juros")
	assert(main.calculate_interest(9) == 0, "9g -> 0 juros")
	assert(main.calculate_interest(10) == 1, "10g -> 1 juros")
	assert(main.calculate_interest(25) == 2, "25g -> 2 juros")
	assert(main.calculate_interest(30) == 3, "30g -> 3 juros")
	assert(main.calculate_interest(50) == 5, "50g -> 5 juros (cap)")
	assert(main.calculate_interest(100) == 5, "100g -> 5 juros (cap)")
	print("  ✓ Cálculo de juros verificado (+1g a cada 10g no banco, máx 5g)")

	# Sequências (1..2: 1g, 3..4: 2g, 5+: 3g)
	assert(main.calculate_streak_bonus(0) == 0, "Streak 0 -> 0g")
	assert(main.calculate_streak_bonus(1) == 1, "Streak 1 -> 1g")
	assert(main.calculate_streak_bonus(2) == 1, "Streak 2 -> 1g")
	assert(main.calculate_streak_bonus(3) == 2, "Streak 3 -> 2g")
	assert(main.calculate_streak_bonus(4) == 2, "Streak 4 -> 2g")
	assert(main.calculate_streak_bonus(5) == 3, "Streak 5 -> 3g")
	assert(main.calculate_streak_bonus(9) == 3, "Streak 9 -> 3g")
	print("  ✓ Tabela de sequência de vitórias verificada (1-2: +1g, 3-4: +2g, 5+: +3g)")

	# Empate quebra a economia
	main.win_streak = 5
	main.player_gold = 20
	main.combat_active = true
	main.end_combat(false, true, "Empate", true)
	assert(main.win_streak == 0, "Empate deve zerar win_streak")
	assert(main.loss_streak == 0, "Empate deve manter loss_streak em 0")
	assert(main.player_gold == 20, "Empate quebra a economia: 0 de ouro e 0 de juros gerados")
	print("  ✓ Empate quebra a economia validado!")

	# ----------------------------------------------------
	# [2] ALVO MAIS PRÓXIMO (CLOSEST TARGETING)
	# ----------------------------------------------------
	print("\n[2] Verificando Foco nas Unidades Mais Próximas:")
	var all_units := UnitSpawner.load_all_units()
	for uid in all_units.keys():
		var ustats: UnitStats = all_units[uid]
		assert(ustats.target_priority == UnitStats.TargetPriority.CLOSEST, "Unidade %s deve ser CLOSEST" % uid)
	print("  ✓ Todas as 45 unidades possuem prioridade CLOSEST")

	# ----------------------------------------------------
	# [3] CABEÇA DE CUIA: PRESERVAÇÃO DE POSIÇÃO
	# ----------------------------------------------------
	print("\n[3] Verificando Cabeça de Cuia (não sobrescrever board_position):")
	var cuia_stats := UnitSpawner.load_unit_stats("cabeca_de_cuia")
	var cuia: BaseUnit3D = UnitSpawner.spawn_unit_from_stats(cuia_stats, 1, 0)
	main.add_child(cuia)
	board.place_unit(cuia, Vector2i(2, 4), false)

	var target_stats := UnitSpawner.load_unit_stats("pequi")
	var target_unit: BaseUnit3D = UnitSpawner.spawn_unit_from_stats(target_stats, 1, 1)
	main.add_child(target_unit)
	board.place_unit(target_unit, Vector2i(2, 1), false)
	target_unit.current_health = 10000.0

	var original_board_pos := target_unit.board_position
	assert(original_board_pos == Vector2i(2, 1), "Posição inicial do alvo deve ser (2, 1)")

	cuia.current_target = target_unit
	cuia._cast_cabeca_de_cuia()
	await process_frame
	await process_frame

	assert(target_unit.board_position == original_board_pos, "Puxão de Cabeça de Cuia NÃO deve alterar board_position da unidade!")
	print("  ✓ board_position permaneceu intacta após o puxão!")

	# ----------------------------------------------------
	# [4] TROCA DE UNIDADES (SWAP): TABULEIRO E BANCO
	# ----------------------------------------------------
	print("\n[4] Verificando Troca de Unidades (Swap):")
	var unit_a_stats := UnitSpawner.load_unit_stats("capivara")
	var unit_a: BaseUnit3D = UnitSpawner.spawn_unit_from_stats(unit_a_stats, 1, 0)
	main.add_child(unit_a)
	board.place_unit(unit_a, Vector2i(1, 4), false)

	var unit_b_stats := UnitSpawner.load_unit_stats("ipe_amarelo")
	var unit_b: BaseUnit3D = UnitSpawner.spawn_unit_from_stats(unit_b_stats, 1, 0)
	main.add_child(unit_b)
	board.place_unit(unit_b, Vector2i(1, 5), false)

	# Simular drop de Unit A sobre a célula de Unit B (Tabuleiro -> Tabuleiro)
	board.remove_unit(Vector2i(1, 4))
	main._on_unit_placed_on_board(unit_a, Vector2i(1, 5), "board", -1, Vector2i(1, 4))
	await process_frame

	assert(board.get_unit_at(Vector2i(1, 5)) == unit_a, "Unit A deve agora estar em (1, 5)")
	assert(board.get_unit_at(Vector2i(1, 4)) == unit_b, "Unit B deve agora estar em (1, 4)")
	print("  ✓ Troca Tabuleiro <-> Tabuleiro realizada com sucesso!")

	# Simular drop do Banco -> Tabuleiro sobre célula ocupada (Swap Banco <-> Tabuleiro)
	var unit_c_stats := UnitSpawner.load_unit_stats("guarana")
	var unit_c: BaseUnit3D = UnitSpawner.spawn_unit_from_stats(unit_c_stats, 1, 0)
	main.add_child(unit_c)
	main.bench_units.append(unit_c)
	var bench_idx: int = main.bench_units.find(unit_c)

	main._on_unit_placed_on_board(unit_c, Vector2i(1, 5), "bench", bench_idx, Vector2i(-1, -1))
	await process_frame

	assert(board.get_unit_at(Vector2i(1, 5)) == unit_c, "Unit C deve agora ocupar (1, 5) no tabuleiro")
	assert(unit_c not in main.bench_units, "Unit C não deve mais estar no banco")
	assert(unit_a in main.bench_units, "Unit A que foi substituída deve agora estar no banco")
	print("  ✓ Troca Banco <-> Tabuleiro realizada com sucesso!")

	# ----------------------------------------------------
	# [5] PAINEL DE INSPEÇÃO TFT (BARRAS, GRID, CARD DE HABILIDADE E SCALING)
	# ----------------------------------------------------
	print("\n[5] Verificando Painel de Inspeção TFT e Escalonamento:")
	main.show_unit_inspector(unit_c)
	var right_bar: Control = ui.get_node("Control/RightBar")
	assert(right_bar.visible, "RightBar deve estar visível")

	# Barras de Vida e Mana
	var hp_bar = right_bar.find_child("InspectorHpBar", true, false) as ProgressBar
	assert(hp_bar != null, "InspectorHpBar deve existir")
	var hp_lbl = hp_bar.find_child("HpTextLabel", true, false) as Label
	assert(hp_lbl != null and "/" in hp_lbl.text, "Label de vida no formato X / Y deve existir")

	var mana_bar = right_bar.find_child("InspectorManaBar", true, false) as ProgressBar
	assert(mana_bar != null, "InspectorManaBar deve existir")

	# Linha Tática e Botão de Habilidade
	var ability_btn = right_bar.find_child("AbilityButton", true, false) as Button
	assert(ability_btn != null, "AbilityButton deve existir")
	var role_badge = right_bar.find_child("RoleBadge", true, false) as Label
	assert(role_badge != null, "RoleBadge deve existir")
	var range_badge = right_bar.find_child("RangeBadge", true, false) as Label
	assert(range_badge != null, "RangeBadge deve existir")

	# Grid de Atributos 2x4
	var stats_grid = right_bar.find_child("TFT_StatsGrid", true, false) as GridContainer
	assert(stats_grid != null, "TFT_StatsGrid deve existir")
	assert(stats_grid.get_child_count() == 8, "Stats grid deve ter 8 atributos (AD, AP, Armor, MR, AS, Crit, Range, DPS)")

	# Barra de Escudo (InspectorShieldBar)
	var shield_bar = right_bar.find_child("InspectorShieldBar", true, false) as ProgressBar
	assert(shield_bar != null, "InspectorShieldBar deve existir")

	# Teste de Atualização em Tempo Real (Vida e Escudo)
	unit_c.current_shield = 150.0
	main._update_inspector_live_data(right_bar, unit_c)
	assert(shield_bar.visible == true, "ShieldBar deve estar visível quando unidade tem escudo")
	assert(shield_bar.value == 150.0, "ShieldBar deve exibir valor atualizado do escudo")
	var hp_label = hp_bar.find_child("HpTextLabel", false, false) as Label
	assert(hp_label != null and "(+150)" in hp_label.text, "HpTextLabel deve exibir o escudo adicional")

	# Desativação do tooltip nativo
	assert(ability_btn.tooltip_text == "", "Tooltip nativo da habilidade deve ser desativado para evitar sobreposição")

	# Card Flutuante de Habilidade e Escalonamento (Scaling)
	main._show_ability_floating_card(unit_c, right_bar)
	assert(main._ability_floating_card != null and main._ability_floating_card.visible, "Card flutuante de habilidade deve estar visível")
	assert(main._ability_floating_card.top_level == true, "Card flutuante deve ser top_level")
	var card_text = main._ability_floating_card.get_node("CardVBox").get_children()
	assert(card_text.size() >= 3, "Card de habilidade deve conter header, descrição e scaling")
	
	# Verificação da descrição mecânica
	var desc_label = card_text[1] as RichTextLabel
	assert(desc_label != null, "Descrição mecânica deve existir")
	assert(unit_c.stats.get_mechanics_description(1) in desc_label.text, "A descrição deve descrever mecanicamente a habilidade")

	print("  ✓ Painel de inspeção TFT, Card Flutuante Compacto, Escudo e Atualização em Tempo Real verificados com 100% de sucesso!")

	print("\n==================================================")
	print("TODOS OS TESTES FORAM APROVADOS COM SUCESSO!")
	print("==================================================")
	quit(0)
