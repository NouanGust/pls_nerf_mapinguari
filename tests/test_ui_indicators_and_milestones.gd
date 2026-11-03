extends SceneTree

const UIStyle = preload("res://Scripts/UI/ui_style.gd")

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	print("==================================================")
	print("SUITE DE TESTES: MARCOS DE ROUND E INDICADORES DE UI")
	print("==================================================")

	# [TESTE 1] Verificar configurações de qualidade de texto no ProjectSettings
	print("\n[TESTE 1] Verificando configurações de renderização de fontes e texturas:")
	var font_filter = ProjectSettings.get_setting("rendering/textures/canvas_textures/default_texture_filter")
	print("  - default_texture_filter: %s (Linear = 1)" % str(font_filter))
	assert(font_filter == 1, "default_texture_filter deve ser 1 (Linear) para evitar distorção pixelada de fontes")

	var font_aa = ProjectSettings.get_setting("gui/theme/default_font_antialiasing")
	print("  - default_font_antialiasing: %s" % str(font_aa))
	assert(font_aa == 1, "default_font_antialiasing deve ser 1")

	var subpixel = ProjectSettings.get_setting("gui/theme/default_font_subpixel_positioning")
	print("  - default_font_subpixel_positioning: %s" % str(subpixel))
	assert(subpixel == 1, "default_font_subpixel_positioning deve ser 1")
	print("  ✓ Configurações de qualidade de texto verificadas com sucesso!")

	# [TESTE 2] Instanciar GameUI.tscn
	print("\n[TESTE 2] Instanciando GameUI.tscn:")
	var game_ui_scene := load("res://Scenes/UI/GameUI.tscn") as PackedScene
	assert(game_ui_scene != null, "GameUI.tscn deve carregar")
	var game_ui = game_ui_scene.instantiate()
	root.add_child(game_ui)
	await process_frame
	print("  ✓ GameUI instanciado com sucesso")

	# [TESTE 3] Indicador de Nível do Inimigo no TopBar
	print("\n[TESTE 3] Verificando indicador de nível do inimigo:")
	var enemy_label := game_ui.get_node_or_null("Control/TopBar/Content/EnemyBox/EnemyLevelLabel") as Label
	assert(enemy_label != null, "EnemyLevelLabel deve existir em Control/TopBar/Content/EnemyBox/")
	game_ui.update_enemy_level(4)
	print("  - Texto do nível do inimigo: '%s'" % enemy_label.text)
	assert(enemy_label.text == "INIMIGO NV. 4", "Texto deve ser 'INIMIGO NV. 4'")
	print("  ✓ Indicador de nível do inimigo validado!")

	# [TESTE 4] Indicador de Espaços Disponíveis no Tabuleiro
	print("\n[TESTE 4] Verificando indicador de capacidade/espaços no tabuleiro:")
	var board_space_label := game_ui.get_node_or_null("Control/BottomBar/ControlsContainer/LevelBox/VBox/BoardSpaceContainer/BoardSpaceLabel") as Label
	assert(board_space_label != null, "BoardSpaceLabel deve existir em ControlsContainer/LevelBox")
	
	# Caso 1: Com vagas livres
	game_ui.update_board_capacity(2, 5)
	print("  - Capacidade com vagas: '%s'" % board_space_label.text)
	assert(board_space_label.text == "CAMPO: 2/5 (3 livres)", "Deve exibir 'CAMPO: 2/5 (3 livres)'")

	# Caso 2: 1 vaga livre
	game_ui.update_board_capacity(4, 5)
	print("  - Capacidade com 1 vaga: '%s'" % board_space_label.text)
	assert(board_space_label.text == "CAMPO: 4/5 (1 livre)", "Deve exibir singular '1 livre'")

	# Caso 3: Tabuleiro cheio
	game_ui.update_board_capacity(5, 5)
	print("  - Capacidade lotada: '%s'" % board_space_label.text)
	assert(board_space_label.text == "CAMPO: 5/5 (Cheio)", "Deve exibir 'CAMPO: 5/5 (Cheio)'")
	print("  ✓ Indicador de vagas no tabuleiro validado!")

	# [TESTE 5] Marcos de Round com cores Vermelho (Derrota) e Verde (Vitória)
	print("\n[TESTE 5] Verificando cores dos marcos de round:")
	# Simular round 3 no estágio 1: round 1 foi vitória (true), round 2 foi derrota (false)
	var outcomes = {
		1: true,
		2: false
	}
	game_ui.update_round_display(3, false, 0.0, false, outcomes)
	var milestone_icons = game_ui._milestone_icons
	assert(milestone_icons.size() == 5, "Devem existir 5 marcos de round no estágio")

	# Marcador 0 (Round 1): Vitória -> Deve ter cor verde (#2ecc71)
	var marker_win = milestone_icons[0]
	var col_win = marker_win.get_theme_color("font_color")
	print("  - Marcador 1 (Vitória) cor: %s, tooltip: '%s'" % [col_win.to_html(), marker_win.tooltip_text])
	assert(col_win == Color("#2ecc71"), "Marcador de vitória deve ser verde #2ecc71")
	assert("Vitória" in marker_win.tooltip_text, "Tooltip deve mencionar Vitória")

	# Marcador 1 (Round 2): Derrota -> Deve ter cor vermelha (#e74c3c)
	var marker_loss = milestone_icons[1]
	var col_loss = marker_loss.get_theme_color("font_color")
	print("  - Marcador 2 (Derrota) cor: %s, tooltip: '%s'" % [col_loss.to_html(), marker_loss.tooltip_text])
	assert(col_win != col_loss, "Cores de vitória e derrota devem ser distintas")
	assert(col_loss == Color("#e74c3c"), "Marcador de derrota deve ser vermelho #e74c3c")
	assert("Derrota" in marker_loss.tooltip_text, "Tooltip deve mencionar Derrota")

	# Marcador 2 (Round 3): Em andamento
	var marker_current = milestone_icons[2]
	print("  - Marcador 3 (Atual) tooltip: '%s'" % marker_current.tooltip_text)
	assert("andamento" in marker_current.tooltip_text, "Marcador atual deve indicar andamento")

	# Marcador 3 e 4 (Futuro)
	var marker_future = milestone_icons[3]
	print("  - Marcador 4 (Futuro) tooltip: '%s'" % marker_future.tooltip_text)
	assert("Próximo Combate" in marker_future.tooltip_text, "Marcador futuro deve indicar próximo combate")

	print("  ✓ Marcos de round coloridos com sucesso!")

	print("\n==================================================")
	print("TODOS OS TESTES DE UI PASSARAM COM SUCESSO!")
	print("==================================================")
	quit(0)
