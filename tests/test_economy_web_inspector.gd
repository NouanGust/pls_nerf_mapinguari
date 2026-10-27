extends SceneTree

const BattleClock = preload("res://Scripts/Systems/battle_clock.gd")
const BiodiversityModels = preload("res://Scripts/Units/biodiversity_models.gd")
const ResponsiveLayout = preload("res://Scripts/UI/responsive_layout.gd")

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	print("==================================================")
	print("SUITE DE TESTES: ECONOMIA, STREAKS, SHADER E UI")
	print("==================================================")
	
	if not root.has_node("BattleClock"):
		var clock = BattleClock.new()
		clock.name = "BattleClock"
		root.add_child(clock)
	if not root.has_node("ResponsiveLayout"):
		var rl = ResponsiveLayout.new()
		rl.name = "ResponsiveLayout"
		root.add_child(rl)

	# [TESTE 1] Ouro inicial = 3
	print("\n[TESTE 1] Verificando ouro inicial do jogador:")
	var main_scene := load("res://Scenes/Main/main.tscn") as PackedScene
	assert(main_scene != null, "main.tscn deve ser carregado")
	var main = main_scene.instantiate()
	root.add_child(main)
	current_scene = main
	await process_frame
	await process_frame
	
	assert(main.player_gold == 3, "Jogador deve começar com exatamente 3 de gold. Atual: %d" % main.player_gold)
	print("  ✓ Ouro inicial verificado: %d gold" % main.player_gold)

	# [TESTE 2] Fundo do painel de inspeção (RightBar)
	print("\n[TESTE 2] Verificando fundo e estilo do RightBar:")
	var right_bar: Control = main.ui.get_node("Control/RightBar")
	assert(right_bar != null, "RightBar deve existir no GameUI")
	var panel_style: StyleBox = right_bar.get_theme_stylebox("panel")
	assert(panel_style is StyleBoxFlat, "RightBar deve usar um StyleBoxFlat opaco e não um StyleBoxTexture vazio")
	var flat: StyleBoxFlat = panel_style as StyleBoxFlat
	assert(flat.bg_color.a >= 0.9, "O fundo do painel de inspeção deve ser opaco. Alpha: %f" % flat.bg_color.a)
	print("  ✓ Painel de inspeção possui fundo sólido e borda (bg_color: %s)" % str(flat.bg_color))

	# [TESTE 3] Lógica de streaks e recompensas de gold
	# [TESTE 3] Lógica de streaks (1..2: +1g, 3..4: +2g, 5+: +3g) e juros (1g a cada 10g)
	print("\n[TESTE 3] Verificando nova tabela de streaks (1..3g) e juros (+1g/10g):")
	main.win_streak = 0
	main.loss_streak = 0
	main.player_gold = 0
	
	# Teste de brackets de streak de vitória
	assert(main.calculate_streak_bonus(0) == 0, "Streak 0 deve dar 0 de bônus")
	assert(main.calculate_streak_bonus(1) == 1, "Streak 1 deve dar 1 de bônus")
	assert(main.calculate_streak_bonus(2) == 1, "Streak 2 deve dar 1 de bônus")
	assert(main.calculate_streak_bonus(3) == 2, "Streak 3 deve dar 2 de bônus")
	assert(main.calculate_streak_bonus(4) == 2, "Streak 4 deve dar 2 de bônus")
	assert(main.calculate_streak_bonus(5) == 3, "Streak 5 deve dar 3 de bônus")
	assert(main.calculate_streak_bonus(8) == 3, "Streak 8+ deve dar 3 de bônus (cap)")
	print("  ✓ Tabela de bônus de sequência (1-2: +1g, 3-4: +2g, 5+: +3g) verificada!")

	# Teste de cálculo de juros (+1 a cada 10 de gold, max 5)
	assert(main.calculate_interest(0) == 0, "0 gold deve gerar 0 juros")
	assert(main.calculate_interest(9) == 0, "9 gold deve gerar 0 juros")
	assert(main.calculate_interest(10) == 1, "10 gold deve gerar 1 de juros")
	assert(main.calculate_interest(19) == 1, "19 gold deve gerar 1 de juros")
	assert(main.calculate_interest(20) == 2, "20 gold deve gerar 2 de juros")
	assert(main.calculate_interest(35) == 3, "35 gold deve gerar 3 de juros")
	assert(main.calculate_interest(50) == 5, "50 gold deve gerar 5 de juros (cap)")
	assert(main.calculate_interest(80) == 5, "80 gold deve gerar 5 de juros (cap)")
	print("  ✓ Cálculo de juros (+1g a cada 10g no banco, máx +5g) verificado!")

	# Simular vitórias acumulando streak, ouro base e juros
	main.player_gold = 10
	var prev_g: int = main.player_gold
	main.combat_active = true
	main.end_combat(true, false, "", true)
	# Vitória com 10g: base=2, streak=1 (+1), juros=1 (+1), total ganho=4
	assert(main.player_gold == prev_g + 4, "Gold com juros e streak deve ser %d, atual %d" % [prev_g + 4, main.player_gold])
	assert(main.win_streak == 1, "Win streak deve ser 1")
	print("  ✓ Ganho de round com bônus base, sequência e juros verificado com sucesso!")

	print("\n[TESTE 4] Verificando que empate quebra a economia (reseta streaks e dá 0 gold):")
	main.win_streak = 4
	main.loss_streak = 0
	var gold_before_draw: int = main.player_gold
	main.combat_active = true
	main.end_combat(false, true, "Empate Forçado", true)
	assert(main.win_streak == 0, "Empate deve resetar win_streak para 0")
	assert(main.loss_streak == 0, "Empate deve manter loss_streak em 0")
	assert(main.player_gold == gold_before_draw, "Empate não deve render gold nem juros. Esperado %d, atual %d" % [gold_before_draw, main.player_gold])
	print("  ✓ Empate quebra a economia com sucesso (0 gold, 0 juros, streaks zeradas)!")

	# [TESTE 5] Shader de unidade possuída na loja
	for i in 10:
		if main.shop_ui:
			break
		await process_frame
	var shop_ui: ShopUI = main.shop_ui
	assert(shop_ui != null, "ShopUI deve existir")
	
	var test_card: UnitCard = shop_ui.unit_cards[0]
	var test_stats := UnitSpawner.load_unit_stats("capivara")
	test_card.set_unit(test_stats)
	
	# Caso A: Jogador não possui a unidade
	test_card.set_purchase_upgrade(0, false, false)
	assert(not test_card.upgrade_glow.visible, "Glow deve estar oculto quando não possui nem evolui")
	
	# Caso B: Jogador possui pelo menos uma (owned = true), sem completar upgrade
	test_card.set_purchase_upgrade(0, false, true)
	assert(test_card.upgrade_glow.visible, "Glow deve estar visível quando jogador já possui a unidade")
	assert(test_card.upgrade_glow.material == test_card.owned_material, "Deve usar o owned_material com shop_owned_hint shader")
	
	# Caso C: Jogador completa upgrade (stars >= 2)
	test_card.set_purchase_upgrade(2, false, true)
	assert(test_card.upgrade_glow.visible, "Glow deve estar visível para evolução")
	assert(test_card.upgrade_glow.material == test_card.upgrade_material, "Deve usar o upgrade_material para evolução")
	print("  ✓ Indicadores visuais de unidade possuída e evolução validados com sucesso")

	# [TESTE 6] Tooltip layout e sizing no primeiro hover
	print("\n[TESTE 6] Verificando tooltips no primeiro hover:")
	var stats_tooltip: PanelContainer = shop_ui.stats_tooltip
	assert(stats_tooltip != null, "StatsTooltip deve existir")
	shop_ui._on_card_hover_started(test_stats, Vector2(100, 500))
	assert(stats_tooltip.visible, "StatsTooltip deve ficar visível ao iniciar hover")
	assert(stats_tooltip.size.x >= 240.0, "StatsTooltip deve ter largura calculada imediatamente (atual: %f)" % stats_tooltip.size.x)
	assert(stats_tooltip.global_position.x >= 10.0, "StatsTooltip deve estar clamped na tela (x: %f)" % stats_tooltip.global_position.x)
	shop_ui._on_card_hover_ended()
	assert(not stats_tooltip.visible, "StatsTooltip deve esconder ao encerrar hover")

	var game_ui: GameUI = main.ui
	var dummy_synergy := {
		"id": "teste_sinergia",
		"name": "Pampa",
		"type": "Origem",
		"count": 2,
		"active": true,
		"threshold": 2,
		"tier": 1,
		"tier_count": 2,
		"effect": "+15% Velocidade de Ataque",
		"units": ["Capivara", "Tatu-bola"]
	}
	var dummy_control := Control.new()
	main.add_child(dummy_control)
	dummy_control.global_position = Vector2(50, 100)
	game_ui._on_synergy_row_hover_started(dummy_synergy, dummy_control)
	var syn_tooltip := game_ui.synergy_tooltip
	assert(syn_tooltip != null and syn_tooltip.visible, "SynergyTooltip deve estar visível no hover")
	assert(syn_tooltip.size.x >= 240.0, "SynergyTooltip deve ter tamanho calculado imediatamente (atual: %f)" % syn_tooltip.size.x)
	game_ui._on_synergy_row_hover_ended()
	assert(not syn_tooltip.visible, "SynergyTooltip deve esconder ao encerrar hover")
	print("  ✓ Tooltips de unidade e sinergia exibem layout consistente desde o primeiro acionamento")

	# [TESTE 7] Pré-aquecimento e modelos de biodiversidade
	print("\n[TESTE 7] Verificando pré-aquecimento de modelos de animais e plantas:")
	BiodiversityModels.preload_all_models()
	assert(not BiodiversityModels._animal_meshes.is_empty(), "Modelos de animais devem estar pré-carregados")
	assert(not BiodiversityModels._plant_meshes.is_empty(), "Modelos de plantas devem estar pré-carregados")
	print("  ✓ Modelos pré-carregados em memória: %d animais, %d plantas" % [
		BiodiversityModels._animal_meshes.size(),
		BiodiversityModels._plant_meshes.size()
	])

	print("\n==================================================")
	print("TODOS OS TESTES PASSARAM COM SUCESSO!")
	print("==================================================")
	quit(0)
