extends SceneTree

const BattleClock = preload("res://Scripts/Systems/battle_clock.gd")

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	print("==================================================")
	print("SUITE COMPLETA DE TESTES: 9 SINERGIAS E 66 UNIDADES")
	print("==================================================")

	var valid_origins := [
		"Seiva", "Vigília", "Correnteza", "Vozes", "Ferocidade", 
		"Travessia", "Assombro", "Encanto", "Fulgor"
	]
	var valid_roles := [
		"Tank", "Conjurador", "Atacante", "Assassino", "Suporte", "Porradeiro"
	]

	# 1. Carregar todas as 66 unidades
	var all_stats := UnitSpawner.load_all_units()
	assert(all_stats.size() == 66, "Devem existir exatamente 66 unidades cadastradas! Encontradas: %d" % all_stats.size())

	var counts := {}
	for orig in valid_origins:
		counts[orig] = 0

	for unit_id in all_stats:
		var st: UnitStats = all_stats[unit_id]
		assert(st != null, "UnitStats não pode ser nulo para %s" % unit_id)
		assert(st.origins.size() == 2, "%s deve ter exatamente 2 origens! Tem: %s" % [unit_id, str(st.origins)])
		for orig in st.origins:
			assert(valid_origins.has(orig), "%s tem origem inválida: %s" % [unit_id, orig])
			counts[orig] += 1
		assert(valid_roles.has(st.combat_role), "%s tem combat_role inválido: %s" % [unit_id, st.combat_role])

	print("✓ Todas as 66 unidades possuem 2 origens válidas e 1 combat_role válido.")
	print("Contagem por Origem: ", counts)

	# 2. Verificar regras no SynergySystem
	assert(SynergySystem.RULES.size() == 9, "SynergySystem deve ter exatamente 9 regras de origens!")
	for orig in valid_origins:
		var rule := SynergySystem.get_rule_for_tag(orig)
		assert(not rule.is_empty(), "Regra para %s deve existir!" % orig)

	# 3. Testar tabuleiro e ativação das 9 sinergias
	if not root.has_node("BattleClock"):
		var clock = BattleClock.new()
		clock.name = "BattleClock"
		root.add_child(clock)

	var main_scene := load("res://Scenes/Main/main.tscn") as PackedScene
	assert(main_scene != null, "main.tscn deve carregar")
	var main = main_scene.instantiate()
	root.add_child(main)
	current_scene = main
	await process_frame
	await process_frame

	var board: Board3D = main.board
	var ui: GameUI = main.ui

	# Teste 3.1: Fulgor (1 integrante ativa patamar 1)
	var fulgor_units := []
	for id in all_stats:
		if all_stats[id].origins.has("Fulgor"):
			fulgor_units.append(id)
	assert(fulgor_units.size() >= 1, "Deve existir ao menos 1 unidade Fulgor")
	var boitata_stats: UnitStats = all_stats[fulgor_units[0]]
	var boitata: BaseUnit3D = UnitSpawner.spawn_unit_from_stats(boitata_stats, 1, 0)
	main.add_child(boitata)
	board.place_unit(boitata, Vector2i(0, 0), false)
	main._refresh_synergies()
	assert(boitata.synergy_bonuses.has("fulgor_mana_start"), "Fulgor deve ativar com 1 unidade!")
	assert(float(boitata.synergy_bonuses["fulgor_mana_start"]) == 5.0, "Fulgor nível 1 dá +5 de mana")
	print("✓ Sinergia Fulgor (1) ativada com sucesso (+5 mana).")

	# Teste 3.2: Ferocidade (2 integrantes ativam patamar 1)
	var fero_units := []
	for id in all_stats:
		if all_stats[id].origins.has("Ferocidade"):
			fero_units.append(id)
	var fero_u1: BaseUnit3D = UnitSpawner.spawn_unit_from_stats(all_stats[fero_units[0]], 1, 0)
	var fero_u2: BaseUnit3D = UnitSpawner.spawn_unit_from_stats(all_stats[fero_units[1]], 1, 0)
	main.add_child(fero_u1)
	main.add_child(fero_u2)
	board.place_unit(fero_u1, Vector2i(1, 0), false)
	board.place_unit(fero_u2, Vector2i(2, 0), false)
	main._refresh_synergies()
	assert(fero_u1.synergy_bonuses.has("ferocidade_atk_pct"), "Ferocidade deve ativar com 2 unidades!")
	assert(float(fero_u1.synergy_bonuses["ferocidade_atk_pct"]) == 0.015, "Ferocidade 2 dá +1.5% atk por acúmulo")
	print("✓ Sinergia Ferocidade (2) ativada com sucesso.")

	# Teste 3.3: Vigília (2 integrantes ativam patamar 1)
	var vig_units := []
	for id in all_stats:
		if all_stats[id].origins.has("Vigília"):
			vig_units.append(id)
	var vig_u1: BaseUnit3D = UnitSpawner.spawn_unit_from_stats(all_stats[vig_units[0]], 1, 0)
	var vig_u2: BaseUnit3D = UnitSpawner.spawn_unit_from_stats(all_stats[vig_units[1]], 1, 0)
	main.add_child(vig_u1)
	main.add_child(vig_u2)
	board.place_unit(vig_u1, Vector2i(3, 0), false)
	board.place_unit(vig_u2, Vector2i(4, 0), false)
	main._refresh_synergies()
	assert(vig_u1.synergy_bonuses.has("vigilia_shield_pct"), "Vigília deve ativar com 2 unidades!")
	assert(float(vig_u1.synergy_bonuses["vigilia_shield_pct"]) == 0.08, "Vigília 2 dá 8% escudo")
	print("✓ Sinergia Vigília (2) ativada com sucesso.")

	# Teste 3.4: Seiva (3 integrantes ativam patamar 1)
	var seiva_units := []
	for id in all_stats:
		if all_stats[id].origins.has("Seiva"):
			seiva_units.append(id)
	var s_u1: BaseUnit3D = UnitSpawner.spawn_unit_from_stats(all_stats[seiva_units[0]], 1, 0)
	var s_u2: BaseUnit3D = UnitSpawner.spawn_unit_from_stats(all_stats[seiva_units[1]], 1, 0)
	var s_u3: BaseUnit3D = UnitSpawner.spawn_unit_from_stats(all_stats[seiva_units[2]], 1, 0)
	main.add_child(s_u1)
	main.add_child(s_u2)
	main.add_child(s_u3)
	board.place_unit(s_u1, Vector2i(0, 1), false)
	board.place_unit(s_u2, Vector2i(1, 1), false)
	board.place_unit(s_u3, Vector2i(2, 1), false)
	main._refresh_synergies()
	assert(s_u1.synergy_bonuses.has("seiva_pulse_heal_pct"), "Seiva deve ativar com 3 unidades!")
	assert(float(s_u1.synergy_bonuses["seiva_pulse_heal_pct"]) == 0.02, "Seiva 3 dá 2% cura de pulso")
	print("✓ Sinergia Seiva (3) ativada com sucesso.")

	# Teste 3.5: Correnteza (3 integrantes ativam patamar 1)
	var corr_units := []
	for id in all_stats:
		if all_stats[id].origins.has("Correnteza"):
			corr_units.append(id)
	var c_u1: BaseUnit3D = UnitSpawner.spawn_unit_from_stats(all_stats[corr_units[0]], 1, 0)
	var c_u2: BaseUnit3D = UnitSpawner.spawn_unit_from_stats(all_stats[corr_units[1]], 1, 0)
	var c_u3: BaseUnit3D = UnitSpawner.spawn_unit_from_stats(all_stats[corr_units[2]], 1, 0)
	main.add_child(c_u1)
	main.add_child(c_u2)
	main.add_child(c_u3)
	board.place_unit(c_u1, Vector2i(3, 1), false)
	board.place_unit(c_u2, Vector2i(4, 1), false)
	board.place_unit(c_u3, Vector2i(0, 2), false)
	main._refresh_synergies()
	assert(c_u1.synergy_bonuses.has("correnteza_pulse_mana"), "Correnteza deve ativar com 3 unidades!")
	assert(float(c_u1.synergy_bonuses["correnteza_pulse_mana"]) == 6.0, "Correnteza 3 dá 6 de mana a cada 5s")
	print("✓ Sinergia Correnteza (3) ativada com sucesso.")

	# Teste 3.6: Vozes (3 integrantes ativam patamar 1)
	var voz_units := []
	for id in all_stats:
		if all_stats[id].origins.has("Vozes"):
			voz_units.append(id)
	var v_u1: BaseUnit3D = UnitSpawner.spawn_unit_from_stats(all_stats[voz_units[0]], 1, 0)
	var v_u2: BaseUnit3D = UnitSpawner.spawn_unit_from_stats(all_stats[voz_units[1]], 1, 0)
	var v_u3: BaseUnit3D = UnitSpawner.spawn_unit_from_stats(all_stats[voz_units[2]], 1, 0)
	main.add_child(v_u1)
	main.add_child(v_u2)
	main.add_child(v_u3)
	board.place_unit(v_u1, Vector2i(1, 2), false)
	board.place_unit(v_u2, Vector2i(2, 2), false)
	board.place_unit(v_u3, Vector2i(3, 2), false)
	main._refresh_synergies()
	assert(v_u1.synergy_bonuses.has("vozes_mana_share"), "Vozes deve ativar com 3 unidades!")
	assert(float(v_u1.synergy_bonuses["vozes_mana_share"]) == 4.0, "Vozes 3 compartilha 4 de mana com aliados")
	print("✓ Sinergia Vozes (3) ativada com sucesso.")

	# Teste 3.7: Travessia (2 integrantes ativam patamar 1)
	var trav_units := []
	for id in all_stats:
		if all_stats[id].origins.has("Travessia"):
			trav_units.append(id)
	var t_u1: BaseUnit3D = UnitSpawner.spawn_unit_from_stats(all_stats[trav_units[0]], 1, 0)
	var t_u2: BaseUnit3D = UnitSpawner.spawn_unit_from_stats(all_stats[trav_units[1]], 1, 0)
	main.add_child(t_u1)
	main.add_child(t_u2)
	board.place_unit(t_u1, Vector2i(4, 2), false)
	board.place_unit(t_u2, Vector2i(0, 3), false)
	main._refresh_synergies()
	assert(t_u1.synergy_bonuses.has("travessia_speed_pct"), "Travessia deve ativar com 2 unidades!")
	assert(float(t_u1.synergy_bonuses["travessia_speed_pct"]) == 0.12, "Travessia 2 dá +12% vel mov")
	print("✓ Sinergia Travessia (2) ativada com sucesso.")

	# Teste 3.8: Assombro (2 integrantes ativam patamar 1)
	var assombro_units := []
	for id in all_stats:
		if all_stats[id].origins.has("Assombro"):
			assombro_units.append(id)
	var a_u1: BaseUnit3D = UnitSpawner.spawn_unit_from_stats(all_stats[assombro_units[0]], 1, 0)
	var a_u2: BaseUnit3D = UnitSpawner.spawn_unit_from_stats(all_stats[assombro_units[1]], 1, 0)
	main.add_child(a_u1)
	main.add_child(a_u2)
	board.place_unit(a_u1, Vector2i(1, 3), false)
	board.place_unit(a_u2, Vector2i(2, 3), false)
	main._refresh_synergies()
	assert(a_u1.synergy_bonuses.has("assombro_shred_pct"), "Assombro deve ativar com 2 unidades!")
	assert(float(a_u1.synergy_bonuses["assombro_shred_pct"]) == 0.06, "Assombro 2 dá 6% shred de armadura e RM")
	print("✓ Sinergia Assombro (2) ativada com sucesso.")

	# Teste 3.9: Encanto (2 integrantes ativam patamar 1)
	var encanto_units := []
	for id in all_stats:
		if all_stats[id].origins.has("Encanto"):
			encanto_units.append(id)
	var e_u1: BaseUnit3D = UnitSpawner.spawn_unit_from_stats(all_stats[encanto_units[0]], 1, 0)
	var e_u2: BaseUnit3D = UnitSpawner.spawn_unit_from_stats(all_stats[encanto_units[1]], 1, 0)
	main.add_child(e_u1)
	main.add_child(e_u2)
	board.place_unit(e_u1, Vector2i(3, 3), false)
	board.place_unit(e_u2, Vector2i(4, 3), false)
	main._refresh_synergies()
	assert(e_u1.synergy_bonuses.has("encanto_power_pct"), "Encanto deve ativar com 2 unidades!")
	assert(float(e_u1.synergy_bonuses["encanto_power_pct"]) == 0.08, "Encanto 2 dá +8% poder de habilidade acumulada")
	print("✓ Sinergia Encanto (2) ativada com sucesso.")

	print("\n==================================================")
	print("PARABÉNS: TODAS AS 9 SINERGIAS ATIVAM E CONCEDEM OS BÔNUS ESPERADOS!")
	print("==================================================")
	quit(0)
