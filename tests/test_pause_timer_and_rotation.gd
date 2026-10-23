extends SceneTree

const GameOverlay = preload("res://Scripts/UI/game_overlay.gd")

var _executed := false

func _process(_delta: float) -> bool:
	if _executed:
		return false
	_executed = true
	
	print("\n==========================================")
	print("INICIANDO TESTES: ROTAÇÃO, CRONÔMETRO DE PAUSA E DESCRIÇÕES")
	print("==========================================\n")
	
	UnitSpawner.clear_cache()
	UnitSpawner.load_all_units()
	
	test_unit_rotations_after_cast()
	test_pause_menu_timer()
	test_ability_descriptions_completeness()
	
	print("\n==========================================")
	print("TODOS OS TESTES DE ROTAÇÃO E CRONÔMETRO PASSARAM COM SUCESSO!")
	print("==========================================\n")
	quit(0)
	return true

func _spawn(unit_id: String, star_level: int = 1, team: int = 0) -> BaseUnit3D:
	var unit: BaseUnit3D = UnitSpawner.spawn_unit(unit_id, star_level, team)
	assert(unit != null, "Falha ao instanciar unidade %s" % unit_id)
	root.add_child(unit)
	unit.board_position = Vector2i(0, 0)
	return unit

func test_unit_rotations_after_cast() -> void:
	print("--- 1. Testando Rotação de Mãe de Ouro e Comadre Fulozinha Pós-Habilidade ---")
	
	# Test Mãe de Ouro
	var mae := _spawn("mae_de_ouro", 1, 0)
	var enemy := _spawn("mapinguari", 1, 1)
	mae.global_position = Vector3(0, 0, 0)
	enemy.global_position = Vector3(0, 0, 4)
	mae.current_target = enemy
	mae.current_state = BaseUnit3D.State.ATTACKING
	mae.current_mana = mae.stats.max_mana
	
	mae.cast_ability()
	
	# Verifica que o modelo não ficou desalinhado/de costas
	assert(abs(mae.model.rotation.y) < 0.05, "O modelo da Mãe de Ouro não deve ficar rodado após a habilidade (atual: %.2f rad)" % mae.model.rotation.y)
	print("  [OK] Mãe de Ouro: model.rotation.y = %.2f rad (alinhado com o alvo)" % mae.model.rotation.y)
	mae.queue_free()
	
	# Test Comadre Fulozinha
	var comadre := _spawn("comadre_fulozinha", 1, 0)
	comadre.global_position = Vector3(0, 0, 0)
	comadre.current_target = enemy
	comadre.current_state = BaseUnit3D.State.ATTACKING
	comadre.current_mana = comadre.stats.max_mana
	
	comadre.cast_ability()
	assert(abs(comadre.model.rotation.y) < 0.05, "O modelo da Comadre Fulozinha não deve ficar rodado após a habilidade (atual: %.2f rad)" % comadre.model.rotation.y)
	print("  [OK] Comadre Fulozinha: model.rotation.y = %.2f rad (alinhado com o alvo)" % comadre.model.rotation.y)
	comadre.queue_free()
	enemy.queue_free()

func test_pause_menu_timer() -> void:
	print("\n--- 2. Testando Cronômetro no Menu de Pausa ---")
	
	# Testa formatação de tempo
	assert(GameOverlay.format_duration(0.0) == "00:00", "0 segundos deve formatar como 00:00")
	assert(GameOverlay.format_duration(65.0) == "01:05", "65 segundos deve formatar como 01:05")
	assert(GameOverlay.format_duration(725.0) == "12:05", "725 segundos deve formatar como 12:05")
	assert(GameOverlay.format_duration(3665.0) == "01:01:05", "3665 segundos deve formatar como 01:01:05")
	print("  [OK] GameOverlay.format_duration formatou minutos e horas corretamente.")
	
	# Testa renderização do cronômetro no overlay de pausa
	var overlay := GameOverlay.new()
	root.add_child(overlay)
	overlay.set_match_time(275.0) # 04:35
	overlay.open("pause", true)
	
	var label_found := false
	for child in overlay._content.get_children():
		if child is PanelContainer:
			for subchild in child.get_children():
				if subchild is Label and "TEMPO DE PARTIDA" in subchild.text:
					assert("04:35" in subchild.text, "Label do cronômetro deve exibir '04:35'")
					label_found = true
					print("  [OK] Label de cronômetro no menu de pausa: '%s'" % subchild.text)
	
	assert(label_found, "O painel do cronômetro deve estar presente no menu de pausa")
	overlay.close()
	overlay.queue_free()

func test_ability_descriptions_completeness() -> void:
	print("\n--- 3. Testando Qualidade e Detalhe das Descrições das 45 Unidades ---")
	var dir := DirAccess.open("res://resources/units/")
	dir.list_dir_begin()
	var file_name := dir.get_next()
	var checked := 0
	
	while file_name != "":
		if file_name.ends_with(".tres"):
			var stats: UnitStats = load("res://resources/units/" + file_name)
			if stats:
				assert(stats.ability_description != "", "Unidade %s deve ter ability_description preenchida" % stats.unit_name)
				assert(stats.ability_description != "Explosão dupla.", "Mãe de Ouro não deve ter descrição genérica 'Explosão dupla.'")
				assert(stats.ability_description != "Reflete dano.", "Mapinguari não deve ter descrição genérica 'Reflete dano.'")
				assert(stats.ability_description != "Dano em área.", "Teiniaguá não deve ter descrição genérica 'Dano em área.'")
				assert(stats.ability_description.length() >= 35,
					"A descrição da habilidade de %s deve ser detalhada e descritiva (tem apenas %d caracteres)" % [stats.unit_name, stats.ability_description.length()])
				checked += 1
		file_name = dir.get_next()
	
	assert(checked == 45, "Todas as 45 unidades devem ter sido verificadas (verificadas: %d)" % checked)
	print("  [OK] Todas as 45 unidades possuem descrições de habilidades ricas, completas e detalhadas.")
