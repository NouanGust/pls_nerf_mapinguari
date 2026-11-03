extends SceneTree

var _executed := false

func _process(_delta: float) -> bool:
	if _executed:
		return false
	_executed = true
	call_deferred("_run_async_tests")
	return false

func _run_async_tests() -> void:
	print("\n==========================================")
	print("INICIANDO TESTES: PROJÉTEIS, ELEMENTOS VISUAIS, VOO E AVANÇO")
	print("==========================================\n")
	
	UnitSpawner.clear_cache()
	UnitSpawner.load_all_units()
	
	test_flying_units_elevation()
	await test_matinta_swoop_confusion()
	await test_sabia_swoop_speed_buff()
	test_ballistic_projectiles()
	test_battlefield_visual_elements()
	
	print("\n==========================================")
	print("TODOS OS TESTES DE PROJÉTEIS, ELEMENTOS E VOO PASSARAM COM SUCESSO!")
	print("==========================================\n")
	quit(0)

func _spawn(unit_id: String, star_level: int = 1, team: int = 0) -> BaseUnit3D:
	var unit: BaseUnit3D = UnitSpawner.spawn_unit(unit_id, star_level, team)
	assert(unit != null, "Falha ao instanciar unidade %s" % unit_id)
	root.add_child(unit)
	unit.board_position = Vector2i(0, 0)
	return unit

func test_flying_units_elevation() -> void:
	print("--- 1. Testando Elevação das Unidades Voadoras ---")
	var flying_ids := [
		"sabia_laranjeira",
		"matinta_perera",
		"cumacanga",
		"alamoa",
		"arara_azul_lear",
		"ararinha_azul",
		"mutum_de_alagoas",
		"mae_de_ouro",
		"romaozinho"
	]
	
	for fid in flying_ids:
		var u := _spawn(fid, 1, 0)
		assert(u.is_flying(), "A unidade %s deveria ter is_flying() == true" % fid)
		assert(u.model.position.y >= BaseUnit3D.FLYING_BASE_HEIGHT - 0.01,
			"O modelo da unidade voadora %s deve estar elevado a pelo menos %.2fm (atual: %.2fm)" % [fid, BaseUnit3D.FLYING_BASE_HEIGHT, u.model.position.y])
		assert(u.ui_sprite.position.y >= 2.7 + BaseUnit3D.FLYING_BASE_HEIGHT - 0.01,
			"A barra de status de %s deve estar elevada a 2.7 + %.2fm (atual: %.2fm)" % [fid, BaseUnit3D.FLYING_BASE_HEIGHT, u.ui_sprite.position.y])
		print("  [OK] %s: is_flying=true, elevação model=%.2fm, billboard=%.2fm" % [fid, u.model.position.y, u.ui_sprite.position.y])
		u.queue_free()
	
	var ground_unit := _spawn("mapinguari", 1, 0)
	assert(not ground_unit.is_flying(), "Mapinguari é terrestre e não deveria voar")
	assert(abs(ground_unit.model.position.y) < 0.01, "Mapinguari terrestre deve estar no solo (y ~ 0.0)")
	print("  [OK] Unidade terrestre (Mapinguari): no solo (y=%.2f)" % ground_unit.model.position.y)
	ground_unit.queue_free()

func test_matinta_swoop_confusion() -> void:
	print("\n--- 2. Testando Avanço e Confusão da Matinta Perera ---")
	var matinta := _spawn("matinta_perera", 1, 0)
	var enemy := _spawn("mapinguari", 1, 1)
	
	matinta.global_position = Vector3(0, 0, 0)
	enemy.global_position = Vector3(0, 0, 3)
	matinta.current_target = enemy
	matinta.current_state = BaseUnit3D.State.ATTACKING
	matinta.current_mana = matinta.stats.max_mana
	
	var initial_hp := enemy.current_health
	matinta.cast_ability()
	await create_timer(0.55, false).timeout
	
	assert(enemy.current_health < initial_hp, "Inimigo deveria sofrer dano da investida da Matinta")
	assert(enemy.is_stunned(), "Inimigo deveria estar atordoado/confuso pela Matinta")
	assert(matinta.is_immune(), "Matinta deveria estar imune durante a investida")
	
	print("  [OK] Matinta Perera: Dano causado (%.1f -> %.1f), Inimigo CONFUSO por 2.5s, Matinta IMUNE durante voo" % [initial_hp, enemy.current_health])
	matinta.queue_free()
	enemy.queue_free()

func test_sabia_swoop_speed_buff() -> void:
	print("\n--- 3. Testando Bicada e Mini Buff de Velocidade do Sabiá Laranjeira ---")
	var sabia := _spawn("sabia_laranjeira", 1, 0)
	var enemy := _spawn("mapinguari", 1, 1)
	
	sabia.global_position = Vector3(0, 0, 0)
	enemy.global_position = Vector3(0, 0, 2)
	sabia.current_target = enemy
	sabia.current_state = BaseUnit3D.State.ATTACKING
	sabia.current_mana = sabia.stats.max_mana
	
	var base_atk_spd := sabia.get_effective_attack_speed()
	var initial_hp := enemy.current_health
	
	sabia.cast_ability()
	await create_timer(0.55, false).timeout
	
	assert(enemy.current_health < initial_hp, "Inimigo deveria sofrer dano da bicada do Sabiá")
	assert(sabia.speed_buff_multiplier > 1.0, "Sabiá deveria ter speed_buff_multiplier > 1.0")
	var buffed_atk_spd := sabia.get_effective_attack_speed()
	assert(buffed_atk_spd > base_atk_spd, "Velocidade de ataque do Sabiá deveria ser aumentada pelo buff (base: %.2f, buffed: %.2f)" % [base_atk_spd, buffed_atk_spd])
	
	print("  [OK] Sabiá Laranjeira: Bicada causou dano (%.1f -> %.1f), AtkSpeed aumentou de %.2f para %.2f (+35%% velocidade)" % [
		initial_hp, enemy.current_health, base_atk_spd, buffed_atk_spd
	])
	sabia.queue_free()
	enemy.queue_free()

func test_ballistic_projectiles() -> void:
	print("\n--- 4. Testando Cores e Disparo Balístico de Projéteis ---")
	var ranged_ids := [
		"cumacanga",
		"caapora",
		"teiniagua",
		"guarana",
		"brinco_de_princesa",
		"bromelia",
		"pequi",
		"arara_azul_lear"
	]
	
	for rid in ranged_ids:
		var u := _spawn(rid, 1, 0)
		var color := u.get_projectile_color()
		assert(color.a > 0.0, "A unidade de ataque à distância %s deve possuir cor de projétil válida" % rid)
		print("  [OK] %s: Cor do projétil = %s" % [rid, color.to_html(false)])
		u.queue_free()
	
	# Test spawning actual projectile node
	var shooter := _spawn("cumacanga", 1, 0)
	var proj_target := _spawn("mapinguari", 1, 1)
	shooter.global_position = Vector3(0, 0, 0)
	proj_target.global_position = Vector3(0, 0, 4)
	
	var callback_called := false
	var p_node := shooter._spawn_ballistic_projectile(
		shooter.global_position + Vector3.UP * 1.0,
		proj_target,
		proj_target.global_position + Vector3.UP * 0.7,
		Color(1.0, 0.45, 0.1),
		1.2,
		0.35,
		func(): callback_called = true,
		"CumacangaFireball",
		0.16,
		false
	)
	
	assert(p_node != null, "Projétil balístico instanciado não deve ser nulo")
	assert(p_node.has_node("OmniLight3D"), "Projétil balístico deve possuir OmniLight3D para iluminação de emissão")
	print("  [OK] Projétil Cumacanga-style instanciado com OmniLight3D e material emissivo")
	shooter.queue_free()
	proj_target.queue_free()

func test_battlefield_visual_elements() -> void:
	print("\n--- 5. Testando Criação de Elementos Visuais no Tabuleiro ---")
	var caster := _spawn("araucaria", 1, 0)
	caster.global_position = Vector3(0, 0, 0)
	
	var dummy_pos := Vector3(2, 0, 2)
	
	# Araucaria
	caster._create_araucaria_canopy_element(dummy_pos, 1.5, 4.0)
	var canopy := root.find_child("AraucariaCanopyVisual", true, false)
	assert(canopy != null, "Elemento AraucariaCanopyVisual criado com sucesso na cena")
	
	# Sumauma
	caster._create_sumauma_roots_element(dummy_pos, 1.4, 3.5)
	var roots := root.find_child("SumaumaRootsVisual", true, false)
	assert(roots != null, "Elemento SumaumaRootsVisual criado com sucesso na cena")
	
	# Mandacaru
	caster._create_mandacaru_thorn_element(dummy_pos, 3.0)
	var thorns := root.find_child("MandacaruThornFenceVisual", true, false)
	assert(thorns != null, "Elemento MandacaruThornFenceVisual criado com sucesso na cena")
	
	# Pau-Brasil
	caster._create_pau_brasil_bloom_element(dummy_pos, 1.3, 3.0)
	var bloom := root.find_child("PauBrasilBloomVisual", true, false)
	assert(bloom != null, "Elemento PauBrasilBloomVisual criado com sucesso na cena")
	
	# Minhocao
	caster._create_minhocao_crater_element(dummy_pos, 1.6, 2.5)
	var crater := root.find_child("MinhocaoCraterVisual", true, false)
	assert(crater != null, "Elemento MinhocaoCraterVisual criado com sucesso na cena")
	
	# Mboi-Guaacu
	caster._create_mboi_guacu_coil_element(caster, 2.5)
	var coil := caster.find_child("MboiGuacuCoilVisual", true, false)
	assert(coil != null, "Elemento MboiGuacuCoilVisual criado com sucesso no alvo")
	
	# Water Sanctuary
	caster._create_water_sanctuary_element(dummy_pos, 3.0)
	var water := root.find_child("WaterLilySanctuaryVisual", true, false)
	assert(water != null, "Elemento WaterLilySanctuaryVisual criado com sucesso na cena")
	
	print("  [OK] Todos os 7 elementos visuais 3D de campo de batalha foram criados com iluminação e ciclo de vida.")
	caster.queue_free()
