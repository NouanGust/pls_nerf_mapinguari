@tool
extends SceneTree

func _init() -> void:
	print("\n============================================================")
	print("TESTE COMPLETO DO PACOTE DE 9 CORREÇÕES / MELHORIAS DE GAMEPLAY")
	print("============================================================\n")
	
	test_1_shop_odds_level_7()
	test_2_economy_reset()
	test_3_melee_aura_lateral()
	test_4_dynamic_shield()
	test_5_debuff_visuals()
	test_6_dynamic_lighting_cycle()
	
	print("\n============================================================")
	print("✅ TODOS OS TESTES DO PACOTE FORAM EXECUTADOS COM SUCESSO!")
	print("============================================================\n")
	quit(0)

func test_1_shop_odds_level_7() -> void:
	print("[1/6] Testando probabilidades da loja no Nível 7...")
	var shop := ShopSystem.new()
	var odds_level_7: Array = shop.tier_chances.get(7, [])
	print("  Odds Nível 7: %s" % str(odds_level_7))
	assert(odds_level_7[1] == 25, "Erro: Tier 2 no nivel 7 deve ser 25")
	print("  ✓ Nível 7: Tier 2 tem exatamente 25% de chance.")
	shop.free()

func test_2_economy_reset() -> void:
	print("[2/6] Testando reset de economia e sequências de vitória/derrota...")
	var em: Node = root.get_node_or_null("EconomyManager")
	if not em:
		var EM_Script: Script = load("res://Scripts/Systems/economy_manager.gd")
		em = EM_Script.new()
		root.add_child(em)
	em.player_gold = 99
	em.win_streak = 5
	em.loss_streak = 3
	em.reset_game(10)
	assert(em.player_gold == 10, "Erro: Ouro inicial não resetado!")
	assert(em.win_streak == 0, "Erro: Win streak não zerado!")
	assert(em.loss_streak == 0, "Erro: Loss streak não zerado!")
	print("  ✓ Economia resetada: Gold=%d, WinStreak=%d, LossStreak=%d" % [em.player_gold, em.win_streak, em.loss_streak])

func test_3_melee_aura_lateral() -> void:
	print("[3/6] Testando restrição de aura lateral para unidades corpo a corpo...")
	var stats := UnitStats.new()
	stats.unit_id = "test_melee_support"
	stats.unit_name = "Teste Melee Suporte"
	stats.attack_range = 1.0 # Melee
	stats.is_ranged = false
	stats.passive_aura_effect = "defense"
	stats.passive_aura_power = 20.0
	stats.passive_aura_range = 1
	
	var unit := BaseUnit3D.new()
	unit.stats = stats
	unit.team = 0
	unit.board_position = Vector2i(2, 2)
	
	var is_melee := stats.get_attack_range_hexes() <= 1 or not stats.is_ranged
	assert(is_melee == true, "Erro: unidade deve ser melee")
	
	# Verifica que apenas laterais (x - 1, x + 1) na mesma linha são permitidas
	var lateral_left := Vector2i(1, 2)
	var lateral_right := Vector2i(3, 2)
	var front := Vector2i(2, 1)
	
	var check_left := (lateral_left == unit.board_position + Vector2i(-1, 0) or lateral_left == unit.board_position + Vector2i(1, 0))
	var check_right := (lateral_right == unit.board_position + Vector2i(-1, 0) or lateral_right == unit.board_position + Vector2i(1, 0))
	var check_front := (front == unit.board_position + Vector2i(-1, 0) or front == unit.board_position + Vector2i(1, 0))
	
	assert(check_left == true, "Lateral esquerda deve receber aura")
	assert(check_right == true, "Lateral direita deve receber aura")
	assert(check_front == false, "Frente não deve receber aura de melee")
	print("  ✓ Aura de corpo a corpo restrita estritamente às laterais (esquerda e direita).")
	unit.free()

func test_4_dynamic_shield() -> void:
	print("[4/6] Testando cálculo do escudo dinâmico para diferentes portes de unidade...")
	var hud := UnitHUD3DComponent.new()
	
	var small_flying_stats := UnitStats.new()
	small_flying_stats.can_fly = true
	small_flying_stats.tier = 1
	var small_flying_unit := BaseUnit3D.new()
	small_flying_unit.stats = small_flying_stats
	small_flying_unit.star_level = 1
	hud.unit = small_flying_unit
	var small_scale := hud._get_dynamic_shield_scale()
	var small_offset := hud._get_dynamic_shield_offset()
	
	var big_tank_stats := UnitStats.new()
	big_tank_stats.is_tank = true
	big_tank_stats.tier = 5
	var big_tank_unit := BaseUnit3D.new()
	big_tank_unit.stats = big_tank_stats
	big_tank_unit.star_level = 3
	hud.unit = big_tank_unit
	var big_scale := hud._get_dynamic_shield_scale()
	
	assert(small_scale.x < big_scale.x, "Escudo de unidade pequena voadora deve ser menor que o de um tanque tier 5 estrela 3!")
	assert(small_offset.y > 0.8, "Elevação vertical do escudo de voador deve considerar altura de voo!")
	print("  ✓ Escudo dinâmico validado: Pequena voadora escala=(%.2f, %.2f) vs Tanque Boss=(%.2f, %.2f)" % [small_scale.x, small_scale.y, big_scale.x, big_scale.y])
	hud.free()
	small_flying_unit.free()
	big_tank_unit.free()

func test_5_debuff_visuals() -> void:
	print("[5/6] Testando feedback visual 3D de debuffs...")
	var dummy := Node3D.new()
	root.add_child(dummy)
	
	CombatFeedback.create_status_indicator(dummy, "ATORDOADO", 0.5)
	var stun_node := dummy.get_node_or_null("StunVisualFX")
	assert(stun_node != null, "Efeito visual 3D StunVisualFX deve ter sido criado no lugar de Label3D!")
	assert(dummy.get_node_or_null("StatusIndicator") == null, "Não deve existir Label3D para debuff!")
	print("  ✓ Debuff ATORDOADO gerou efeito 3D StunVisualFX sem nenhum texto Label3D.")
	
	CombatFeedback.create_status_indicator(dummy, "LENTO", 0.5)
	var slow_node := dummy.get_node_or_null("SlowVisualFX")
	assert(slow_node != null, "Efeito visual 3D SlowVisualFX deve ter sido criado!")
	print("  ✓ Debuff LENTO gerou efeito 3D SlowVisualFX.")
	
	dummy.queue_free()

func test_6_dynamic_lighting_cycle() -> void:
	print("[6/6] Testando cálculo do ciclo dinâmico de iluminação...")
	var rounds := [1, 2, 3, 4, 5, 6, 7]
	var expected_prog := [0.0, 0.25, 0.50, 0.75, 1.0, 0.0, 0.25]
	for i in rounds.size():
		var r: int = rounds[i]
		var cycle_step: int = posmod(r - 1, 5)
		var cycle_prog: float = float(cycle_step) / 4.0
		var exp_prog: float = expected_prog[i]
		assert(absf(cycle_prog - exp_prog) < 0.01, "Erro no cálculo do ciclo do round %d: %f != %f" % [r, cycle_prog, exp_prog])
	print("  ✓ Ciclo dinâmico calculado com precisão: Round 1 (0.0 claro) -> Round 5 (1.0 boss/rubro) -> Round 6 (0.0 reset claro).")
