extends SceneTree

const TIER_1_UNITS = [
	"brinco_de_princesa",
	"bromelia",
	"capivara",
	"cumacanga",
	"guarana",
	"mandacaru",
	"pequi",
	"sabia_laranjeira",
	"tatu_bola"
]

func _initialize() -> void:
	print("\n==========================================")
	print("INICIANDO TESTES: EFEITOS SONOROS, UNIDADES TIER 1 E CUTSCENE DO BOSS")
	print("==========================================\n")
	
	test_audio_manager()
	test_tier_1_units_and_abilities()
	test_boss_cutscene_components()
	
	print("\n==========================================")
	print("TODOS OS TESTES PASSARAM COM SUCESSO!")
	print("==========================================\n")
	quit(0)

func test_audio_manager() -> void:
	print("--- Testando AudioManager ---")
	var audio_script = load("res://Scripts/Systems/audio_manager.gd")
	assert(audio_script != null, "audio_manager.gd deve carregar")
	var audio_mgr = audio_script.new()
	audio_mgr.name = "AudioManager"
	root.add_child(audio_mgr)
	
	assert(audio_mgr.has_method("play_player_level_up"), "AudioManager deve ter play_player_level_up()")
	assert(audio_mgr.has_method("play_melee_hit"), "AudioManager deve ter play_melee_hit()")
	assert(audio_mgr.has_method("_ensure_stream_loop"), "AudioManager deve ter _ensure_stream_loop()")
	
	print("  [OK] AudioManager novos SFX e métodos de loop verificados.")

func test_tier_1_units_and_abilities() -> void:
	print("--- Testando Unidades de Custo 1 e suas Habilidades ---")
	UnitSpawner.clear_cache()
	UnitSpawner.load_all_units()
	
	# Verificar se cada unidade existe e possui custo 1
	for unit_id in TIER_1_UNITS:
		var stats: UnitStats = UnitSpawner.load_unit_stats(unit_id)
		assert(stats != null, "UnitStats para %s não deve ser nulo" % unit_id)
		assert(stats.cost == 1, "Unidade %s deve ter custo 1 (tem %d)" % [unit_id, stats.cost])
		print("  [OK] Unidade Custo 1 verificada: %s (Habilidade: %s)" % [stats.unit_name, stats.ability_name])
	
	# Criar instâncias e testar execução das habilidades
	for unit_id in TIER_1_UNITS:
		var unit: BaseUnit3D = UnitSpawner.spawn_unit(unit_id, 1, 0)
		assert(unit != null, "BaseUnit3D para %s deve ser instanciada com sucesso" % unit_id)
		root.add_child(unit)
		unit.board_position = Vector2i(0, 0)
		
		# Testar casting da habilidade
		unit.current_mana = unit.stats.max_mana
		unit.cast_ability()
		
		# Testar com 3 estrelas para validar escalonamento
		var unit_3star: BaseUnit3D = UnitSpawner.spawn_unit(unit_id, 3, 0)
		root.add_child(unit_3star)
		unit_3star.board_position = Vector2i(1, 1)
		unit_3star.current_mana = unit_3star.stats.max_mana
		unit_3star.cast_ability()
		
		unit.queue_free()
		unit_3star.queue_free()
		print("  [OK] Habilidade de %s executada com sucesso (1 estrela e 3 estrelas)." % unit_id)

func test_boss_cutscene_components() -> void:
	print("--- Testando Componentes da Cutscene do Boss ---")
	
	# Testar GameCamera
	var cam: GameCamera = GameCamera.new()
	root.add_child(cam)
	assert(cam.has_method("play_boss_sequence"), "GameCamera deve implementar play_boss_sequence()")
	assert(cam.has_method("_update_shake"), "GameCamera deve implementar _update_shake()")
	cam.shake(0.5, 0.5)
	assert(cam._shake_intensity >= 0.5, "Shake intensity deve ser definida")
	cam.queue_free()
	print("  [OK] GameCamera possui play_boss_sequence e shake contínuo.")
	
	# Testar lógica de Boss no Main
	var main_script = load("res://Scripts/main.gd")
	assert(main_script != null, "main.gd deve compilar sem erros")
	
	# Testar detecção de Boss Round
	var dummy_main = Node3D.new()
	dummy_main.set_script(main_script)
	root.add_child(dummy_main)
	assert(dummy_main.has_method("is_boss_round"), "main.gd deve ter is_boss_round()")
	assert(dummy_main.has_method("_find_strongest_enemy"), "main.gd deve ter _find_strongest_enemy()")
	assert(dummy_main.has_method("_play_boss_cutscene"), "main.gd deve ter _play_boss_cutscene()")
	
	dummy_main.set("current_round", 5)
	assert(dummy_main.is_boss_round() == true, "Round 5 deve ser considerado boss round")
	dummy_main.set("current_round", 4)
	assert(dummy_main.is_boss_round() == false, "Round 4 não deve ser boss round sem bosses")
	dummy_main.queue_free()
	print("  [OK] main.gd possui métodos de cutscene e detecção de boss round.")
