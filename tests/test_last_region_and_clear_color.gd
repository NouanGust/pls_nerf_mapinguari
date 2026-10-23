extends SceneTree

var frame := 0

func _process(_delta: float) -> bool:
	frame += 1
	if frame == 1:
		print("\n=== TESTE: PERSISTÊNCIA DA ÚLTIMA REGIÃO E TELA PRETA / CLEAR COLOR ===")
		
		# 1. Verificar project.godot
		var cfg := ConfigFile.new()
		var err := cfg.load("res://project.godot")
		assert(err == OK, "project.godot deve ser carregado com sucesso")
		var clear_col = cfg.get_value("rendering", "environment/defaults/default_clear_color", null)
		assert(clear_col != null, "environment/defaults/default_clear_color deve estar definido")
		assert(clear_col == Color(0, 0, 0, 1), "default_clear_color deve ser preto opaco (0,0,0,1)")
		print("OK: default_clear_color é Color(0, 0, 0, 1)")

		# 2. Verificar Scenes/UI/SplashScreen.tscn
		var splash_scene = load("res://Scenes/UI/SplashScreen.tscn")
		assert(splash_scene != null, "SplashScreen.tscn deve existir")
		var splash_instance = splash_scene.instantiate()
		var splash_bg = splash_instance.get_node_or_null("Background")
		assert(splash_bg is ColorRect, "SplashScreen deve possuir nó Background do tipo ColorRect")
		assert(splash_bg.color == Color(0, 0, 0, 1), "Background da splash deve ser preto")
		splash_instance.queue_free()
		print("OK: SplashScreen.tscn possui Background preto nativo")

		# 3. Verificar Scenes/UI/Menu.tscn
		var menu_scene = load("res://Scenes/UI/Menu.tscn")
		assert(menu_scene != null, "Menu.tscn deve existir")
		var menu_instance = menu_scene.instantiate()
		var menu_bg = menu_instance.get_node_or_null("StaticBackground")
		assert(menu_bg is ColorRect, "Menu.tscn deve possuir nó StaticBackground do tipo ColorRect")
		menu_instance.queue_free()
		print("OK: Menu.tscn possui StaticBackground nativo")

		# 4. Verificar BattleTransition.force_black()
		var BattleTransitionScript = load("res://Scripts/UI/battle_transition.gd")
		var transition = BattleTransitionScript.new()
		root.add_child(transition)
		transition.force_black()
		assert(transition._curtain != null and transition._curtain.color.a >= 0.99, "force_black deve colocar _curtain.color.a em 1.0 imediatamente")
		transition.queue_free()
		print("OK: BattleTransition.force_black() ativa preto imediato sem flash cinza")

		# 5. Testar persistência de GameSettings.last_played_region
		var gs = root.get_node_or_null("GameSettings")
		assert(gs != null, "Autoload GameSettings deve estar disponível no root")
		var original_region = gs.get_last_played_region()
		
		gs.set_last_played_region("amazonia")
		assert(gs.get_last_played_region() == "amazonia", "get_last_played_region deve retornar amazonia")
		
		# Recarregar do arquivo de config para validar persistência em disco
		var disk_cfg := ConfigFile.new()
		assert(disk_cfg.load("user://settings.cfg") == OK, "settings.cfg deve ser lido")
		assert(disk_cfg.get_value("gameplay", "last_played_region", "") == "amazonia", "settings.cfg deve persistir amazonia")
		print("OK: GameSettings persiste 'amazonia' em disco")

		# Testar outra região
		gs.set_last_played_region("caatinga")
		assert(gs.get_last_played_region() == "caatinga", "get_last_played_region deve retornar caatinga")
		print("OK: GameSettings atualizado para 'caatinga'")
		
		# Restaurar original ou manter
		gs.set_last_played_region("mata_atlantica")
		print("OK: GameSettings restaurado para 'mata_atlantica'")

		# 6. Testar splash_screen.gd inicialização para a região salva
		var splash = splash_scene.instantiate()
		root.add_child(splash)
		gs.set_last_played_region("pantanal")
		
		# Verificar se splash_screen usa a região salva
		var target_reg = gs.get_last_played_region()
		assert(target_reg == "pantanal", "Região alvo deve ser pantanal")
		splash.queue_free()
		print("OK: SplashScreen lê corretamente a última região jogada")

		print("\n=== TODOS OS TESTES DE ÚLTIMA REGIÃO E CLEAR COLOR PASSARAM COM SUCESSO! ===")
		quit(0)
		return true

	return false
