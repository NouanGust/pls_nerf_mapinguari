extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	print("--- TESTE DE INTERFACE TFT INICIADO ---")
	var scene_res := load("res://Scenes/Main/main.tscn") as PackedScene
	if not scene_res:
		push_error("Falha ao carregar main.tscn")
		quit(1)
		return
	
	var main_node = scene_res.instantiate()
	root.add_child(main_node)
	current_scene = main_node
	
	await process_frame
	await process_frame
	await create_timer(0.5).timeout
	
	var ui = main_node.get_node_or_null("GameUi")
	if not ui:
		push_error("GameUi não encontrado em main.tscn!")
		quit(1)
		return
	
	print("GameUi carregado com sucesso!")
	
	# Verificar TopBar
	assert(ui.round_label != null, "round_label deve existir")
	assert(ui.timer_label != null, "timer_label deve existir")
	assert(ui.milestones_container != null, "milestones_container deve existir")
	print("TopBar OK: Round=%s, Timer=%s, Marcos=%d" % [
		ui.round_label.text,
		ui.timer_label.text,
		ui.milestones_container.get_child_count()
	])
	
	# Verificar Loja
	assert(ui.shop != null, "shop deve existir")
	assert(ui.shop.unit_cards.size() == 5, "Loja deve conter 5 cartas")
	print("Shop OK: 5 cartas instanciadas")
	
	# Verificar Banco
	assert(ui.bench != null, "bench deve existir")
	assert(ui.bench.slots.size() == 9, "Banco deve conter 9 pedestais")
	print("Bench OK: 9 pedestais instanciados")
	
	# Verificar HP
	assert(ui.health_widget != null, "health_widget deve existir")
	assert(ui.health_label != null, "health_label deve existir")
	print("HealthWidget OK: HP=%s" % ui.health_label.text)
	
	# Testar atualização de stats
	main_node.player_gold = 15
	main_node.player_health = 85
	main_node.player_level = 3
	main_node.player_xp = 4
	main_node.update_ui()
	
	print("Stats atualizados: Ouro=15, Vida=85, Nível=3 (XP 4/6)")
	print("HP após atualização: %s" % ui.health_label.text)
	assert(ui.health_label.text == "85", "HP deve ser 85")
	
	# Testar sinergias
	ui.update_synergies([
		{"name": "Amazônia", "category": "Origem", "count": 2, "threshold": 2, "active": true, "description": "Bônus amazônico"},
		{"name": "Lutador", "category": "Classe", "count": 1, "threshold": 2, "active": false, "description": "Bônus de lutador"}
	])
	assert(ui.spawned_synergy_rows.size() == 2, "2 sinergias devem ser renderizadas")
	print("Sinergias OK: 2 linhas renderizadas")
	
	# Capturar tela se diretório estiver configurado
	var img := root.get_texture().get_image()
	if img:
		img.save_png("res://tft_ui_screenshot.png")
		print("Screenshot salva em res://tft_ui_screenshot.png")
	
	print("--- TODOS OS TESTES PASSARAM COM SUCESSO ---")
	quit(0)
