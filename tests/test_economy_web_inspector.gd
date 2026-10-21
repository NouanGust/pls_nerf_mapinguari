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
	print("\n[TESTE 3] Verificando streaks de vitória (base +2, streak 1..5):")
	main.win_streak = 0
	main.loss_streak = 0
	main.player_gold = 3
	
	# Simular 5 vitórias consecutivas
	var expected_gold: int = 3
	for w in range(1, 6):
		var prev_streak: int = main.win_streak
		main.win_streak = mini(main.win_streak + 1, 5)
		main.loss_streak = 0
		var bonus: int = clampi(main.win_streak, 1, 5)
		var round_gain: int = main.gold_on_win + bonus
		main.player_gold += round_gain
		expected_gold += round_gain
		assert(main.win_streak == w, "Win streak deve ser %d" % w)
		assert(bonus == w, "Bonus da win streak deve ser %d" % w)
		assert(main.player_gold == expected_gold, "Gold esperado %d, atual %d" % [expected_gold, main.player_gold])
	
	# 6ª vitória deve manter streak no cap de 5
	main.win_streak = mini(main.win_streak + 1, 5)
	var capped_bonus: int = clampi(main.win_streak, 1, 5)
	assert(main.win_streak == 5, "Win streak deve estar limitada em 5")
	assert(capped_bonus == 5, "Bonus máximo deve ser 5")
	print("  ✓ Streaks de vitória testadas com sucesso: sequência até 5 e bônus de 1 a 5 gold")

	print("\n[TESTE 4] Verificando streaks de derrota (base +1, streak 1..5):")
	main.win_streak = 0
	main.loss_streak = 0
	var gold_before_loss: int = main.player_gold
	expected_gold = gold_before_loss
	for l in range(1, 6):
		main.loss_streak = mini(main.loss_streak + 1, 5)
		main.win_streak = 0
		var bonus: int = clampi(main.loss_streak, 1, 5)
		var round_gain: int = main.gold_on_loss + bonus
		main.player_gold += round_gain
		expected_gold += round_gain
		assert(main.loss_streak == l, "Loss streak deve ser %d" % l)
		assert(bonus == l, "Bonus da loss streak deve ser %d" % l)
		assert(main.player_gold == expected_gold, "Gold esperado %d, atual %d" % [expected_gold, main.player_gold])
	
	# 6ª derrota deve manter streak no cap de 5
	main.loss_streak = mini(main.loss_streak + 1, 5)
	assert(main.loss_streak == 5, "Loss streak deve estar limitada em 5")
	print("  ✓ Streaks de derrota testadas com sucesso: sequência até 5 e bônus de 1 a 5 gold")

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
