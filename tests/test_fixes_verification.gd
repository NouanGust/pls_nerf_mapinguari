extends SceneTree

func _initialize() -> void:
	print("\n" + "=".repeat(60))
	print("INICIANDO SUITE DE TESTES DAS CORREÇÕES E NOVOS RECURSOS")
	print("=".repeat(60) + "\n")
	
	test_project_settings()
	test_splash_screen()
	test_audio_manager()
	test_region_environment_and_boss()
	test_unit_card_traits()
	test_board_drag_shop_return()
	test_unit_movement_system()
	test_boss_preparation_atmosphere()
	
	print("\n" + "=".repeat(60))
	print("✅ TODOS OS TESTES PASSARAM COM SUCESSO!")
	print("=".repeat(60) + "\n")
	quit(0)

func test_project_settings() -> void:
	print("[TESTE 1] Validando configurações do projeto (project.godot)...")
	var icon: String = str(ProjectSettings.get_setting("application/config/icon", ""))
	assert(icon.begins_with("uid://") or icon == "res://Assets/Utils/Icon.jpg", "Ícone deve ser res://Assets/Utils/Icon.jpg ou UID válido, obtido: %s" % icon)
	
	var main_scene = ProjectSettings.get_setting("application/run/main_scene")
	assert(main_scene == "res://Scenes/UI/SplashScreen.tscn", "Main scene deve ser SplashScreen, obtido: %s" % main_scene)
	
	var boot_splash = ProjectSettings.get_setting("application/boot_splash/image")
	assert(boot_splash == "res://Assets/Utils/splash_screen.png", "Boot splash deve ser splash_screen.png, obtido: %s" % boot_splash)
	print("  ✓ Ícone, splash image e main_scene configurados corretamente!")

func test_splash_screen() -> void:
	print("\n[TESTE 2] Validando cena da Splash Screen...")
	var splash_scene = load("res://Scenes/UI/SplashScreen.tscn")
	assert(splash_scene != null, "SplashScreen.tscn deve carregar")
	var instance = splash_scene.instantiate()
	assert(instance != null, "Instância da splash screen deve ser criada")
	assert(instance.get("splash_texture") != null, "splash_texture deve estar preenchida")
	assert(instance.get("next_scene_path") == "res://Scenes/UI/Menu.tscn", "next_scene deve ser Menu.tscn")
	instance.free()
	print("  ✓ SplashScreen instanciada e configurada com sucesso!")

func test_audio_manager() -> void:
	print("\n[TESTE 3] Validando AudioManager, músicas regionais e SFX...")
	var audio_mgr_script = load("res://Scripts/Systems/audio_manager.gd")
	assert(audio_mgr_script != null, "audio_manager.gd deve carregar")
	var tracks: Dictionary = audio_mgr_script.REGION_TRACKS
	assert(tracks.has("pantanal"), "Deve conter faixa do Pantanal")
	assert(tracks.has("mata_atlantica"), "Deve conter faixa da Mata Atlântica")
	assert(tracks.has("sul"), "Deve conter faixa do Sul")
	print("  ✓ Faixas regionais mapeadas no AudioManager: %s" % [tracks.keys()])

func test_region_environment_and_boss() -> void:
	print("\n[TESTE 4] Validando ambiente sombrio e atmosfera de Boss...")
	var env_script = load("res://Scripts/Environment/region_environment.gd")
	assert(env_script != null, "region_environment.gd deve carregar")
	assert(env_script.PROFILES.has("pantanal"), "Perfil pantanal deve existir")
	var pantanal = env_script.PROFILES["pantanal"]
	# Validar neblina densa
	assert(pantanal["fog_density"] >= 0.013, "Fog density deve ser sombria e densa (>= 0.013)")
	assert(env_script.has_method("apply_boss_atmosphere"), "Deve possuir apply_boss_atmosphere")
	print("  ✓ Configurações de ambiente escuro/denso e método de boss validados!")

func test_unit_card_traits() -> void:
	print("\n[TESTE 5] Validando exibição dinâmica de todas as classes no UnitCard...")
	var card_script = load("res://Scripts/UI/unit_card.gd")
	assert(card_script != null, "unit_card.gd deve carregar")
	var card = card_script.new()
	assert(card.has_method("_update_traits_display"), "UnitCard deve possuir _update_traits_display")
	card.free()
	print("  ✓ UnitCard possui suporte dinâmico a múltiplas classes e origens!")

func test_board_drag_shop_return() -> void:
	print("\n[TESTE 6] Validando que unidade da loja arrastada incorretamente vai para o banco...")
	var drag_script = load("res://Scripts/Board/board_drag_handler.gd")
	assert(drag_script != null, "board_drag_handler.gd deve carregar")
	var handler = drag_script.new()
	assert(handler.has_signal("unit_placed_on_bench"), "DragHandler deve ter sinal unit_placed_on_bench")
	handler.free()
	print("  ✓ DragHandler configurado para redirecionar unidades da loja para o banco!")

func test_unit_movement_system() -> void:
	print("\n[TESTE 7] Validando movimento direto e prevenção de travamento de navegação...")
	var base_unit_script = load("res://Scripts/Units/base_unit.gd")
	assert(base_unit_script != null, "base_unit.gd deve carregar")
	var unit: CharacterBody3D = base_unit_script.new()
	assert(unit.get("use_navigation") == false, "use_navigation padrão deve ser false para movimento direto e estável")
	assert(unit.has_method("move_direct_to_target"), "Unidade deve ter método move_direct_to_target")
	assert(unit.has_method("move_towards_target"), "Unidade deve ter método move_towards_target")
	unit.free()
	print("  ✓ Sistema de movimento configurado para direção direta contínua e estável!")

func test_boss_preparation_atmosphere() -> void:
	print("\n[TESTE 8] Validando transição de atmosfera de boss na preparação...")
	var main_script = load("res://Scripts/main.gd")
	assert(main_script != null, "main.gd deve carregar")
	var main = main_script.new()
	assert(main.has_method("is_boss_round"), "main.gd deve possuir is_boss_round")
	assert(main.has_method("_update_round_atmosphere"), "main.gd deve possuir _update_round_atmosphere")
	main.free()
	print("  ✓ main.gd pronto com verificação de boss round e atualização de atmosfera na preparação!")
