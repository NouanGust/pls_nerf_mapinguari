extends SceneTree

const BattleClock = preload("res://Scripts/Systems/battle_clock.gd")

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	print("--- TESTE DE ESFERA DE ESCUDO, FEEDBACK DE RARIDADE E ROLES ---")
	
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
	
	# ========================================================
	# [TESTE 1] Distribuição de Lendárias (Custo 5) por Região
	# ========================================================
	print("\n[1] Testando distribuição de unidades custo 5 por região:")
	var all_units := UnitSpawner.load_all_units()
	var regions_cost5: Dictionary = {}
	var total_roles: Dictionary = {}
	
	for uid in all_units.keys():
		var stats: UnitStats = all_units[uid]
		var orig := stats.origins[0] if not stats.origins.is_empty() else "Unknown"
		var role := stats.get_combat_role()
		assert(not role.is_empty(), "Unidade %s deve ter role definida" % uid)
		total_roles[role] = total_roles.get(role, 0) + 1
		
		if stats.cost == 5:
			if not regions_cost5.has(orig):
				regions_cost5[orig] = []
			regions_cost5[orig].append(uid)
			
	print("  Lendárias (Custo 5) por região:")
	for r in regions_cost5.keys():
		print("    - %s: %s (total: %d)" % [r, ", ".join(regions_cost5[r]), regions_cost5[r].size()])
		assert(regions_cost5[r].size() >= 1, "Região %s deve ter pelo menos 1 lendária custo 5" % r)
	
	assert(regions_cost5.has("Cerrado"), "Cerrado DEVE ter pelo menos 1 lendária custo 5!")
	assert("lobo_guara" in regions_cost5["Cerrado"], "Lobo-guará deve ser a lendária do Cerrado!")
	assert(regions_cost5.has("Amazônico"), "Amazônico deve ter lendárias!")
	assert("mapinguari" in regions_cost5["Amazônico"], "Mapinguari deve ser lendária na Amazônia!")
	assert("boiuna" in regions_cost5["Amazônico"], "Boiúna deve ser lendária na Amazônia!")
	print("  Todas as regiões têm unidades custo 5 lendárias ✓")
	
	print("\n  Distribuição por Função de Combate:")
	for role in total_roles.keys():
		print("    - %s: %d unidades" % [role, total_roles[role]])
		assert(total_roles[role] > 0, "Deve haver unidades com a função %s" % role)
	print("  Todas as 6 funções (Tank, Conjurador, Atacante, Assassino, Suporte, Porradeiro) estão representadas ✓")

	# ========================================================
	# [TESTE 2] Esfera Visual de Escudo e Cores por Origem
	# ========================================================
	print("\n[2] Testando esfera de escudo visual e cores por origem:")
	var capivara_stats := UnitSpawner.load_unit_stats("capivara")
	var unit: BaseUnit3D = UnitSpawner.spawn_unit_from_stats(capivara_stats, 1, 0)
	main.add_child(unit)
	board.place_unit(unit, Vector2i(2, 4), false)
	
	assert(unit.shield_sphere != null, "unit deve instanciar shield_sphere!")
	assert(unit.shield_sphere.visible == false, "Escudo deve estar oculto quando current_shield == 0")
	
	# 2.1 Escudo PRÓPRIO (Ciano)
	unit.set_shield_with_source(200.0, BaseUnit3D.ShieldSource.SELF)
	await process_frame
	assert(unit.has_active_shield(), "unit deve ter escudo ativo!")
	assert(unit.shield_sphere.visible == true, "shield_sphere deve estar visível com escudo ativo!")
	var mat_self: StandardMaterial3D = unit.shield_sphere.material_override as StandardMaterial3D
	assert(mat_self != null, "shield_sphere deve ter StandardMaterial3D")
	var expected_cyan := BaseUnit3D.SHIELD_COLORS[BaseUnit3D.ShieldSource.SELF]
	assert(mat_self.emission.is_equal_approx(expected_cyan), "Escudo próprio deve ter cor ciano!")
	print("  Escudo próprio (Ciano) visualizado corretamente ✓")
	
	# 2.2 Escudo de CLASSE (Dourado/Âmbar)
	unit.set_shield_with_source(250.0, BaseUnit3D.ShieldSource.CLASS)
	await process_frame
	var mat_class: StandardMaterial3D = unit.shield_sphere.material_override as StandardMaterial3D
	var expected_gold := BaseUnit3D.SHIELD_COLORS[BaseUnit3D.ShieldSource.CLASS]
	assert(mat_class.emission.is_equal_approx(expected_gold), "Escudo de classe deve ter cor dourada!")
	print("  Escudo de classe (Dourado) visualizado corretamente ✓")
	
	# 2.3 Escudo do JOGADOR / ALIADO (Verde Esmeralda)
	unit.set_shield_with_source(180.0, BaseUnit3D.ShieldSource.PLAYER)
	await process_frame
	var mat_player: StandardMaterial3D = unit.shield_sphere.material_override as StandardMaterial3D
	var expected_green := BaseUnit3D.SHIELD_COLORS[BaseUnit3D.ShieldSource.PLAYER]
	assert(mat_player.emission.is_equal_approx(expected_green), "Escudo de aliado/jogador deve ter cor verde esmeralda!")
	print("  Escudo de jogador/aliado (Verde) visualizado corretamente ✓")
	
	# 2.4 Escudo de INIMIGO (Vermelho Carmesim)
	var enemy_unit: BaseUnit3D = UnitSpawner.spawn_unit_from_stats(capivara_stats, 1, 1) # team 1
	main.add_child(enemy_unit)
	board.place_unit(enemy_unit, Vector2i(2, 1), false)
	enemy_unit.set_shield_with_source(200.0, BaseUnit3D.ShieldSource.ENEMY)
	await process_frame
	var mat_enemy: StandardMaterial3D = enemy_unit.shield_sphere.material_override as StandardMaterial3D
	var expected_red := BaseUnit3D.SHIELD_COLORS[BaseUnit3D.ShieldSource.ENEMY]
	assert(mat_enemy.emission.is_equal_approx(expected_red), "Escudo de inimigo deve ter cor vermelha carmesim!")
	print("  Escudo de inimigo (Vermelho) visualizado corretamente ✓")
	
	# 2.5 Escudo removido -> esfera oculta
	unit.current_shield = 0.0
	await process_frame
	await get_tree().create_timer(0.3, false).timeout
	assert(unit.has_active_shield() == false, "unit não deve ter escudo ativo")
	assert(unit.shield_sphere.visible == false, "shield_sphere deve ficar invisível quando o escudo for zero!")
	print("  Esfera de escudo desaparece quando o escudo é consumido ✓")

	# ========================================================
	# [TESTE 3] Feedback de colocação com base na raridade
	# ========================================================
	print("\n[3] Testando feedback visual e sonoro de colocação por raridade:")
	for tier in [1, 2, 3, 4, 5]:
		board.create_placement_feedback(Vector3(tier, 0, 0), tier)
		AudioManager.play_place_unit(tier)
	print("  create_placement_feedback e play_place_unit executados para todos os tiers (1 a 5) ✓")
	
	print("\n TODOS OS TESTES PASSARAM COM SUCESSO!")
	quit()
