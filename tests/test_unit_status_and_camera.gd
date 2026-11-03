extends SceneTree

const BattleClock = preload("res://Scripts/Systems/battle_clock.gd")
const ResponsiveLayout = preload("res://Scripts/UI/responsive_layout.gd")

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	print("==================================================")
	print("SUITE DE TESTES: INTERFACE DE STATUS E POSIÇÃO DA CÂMERA")
	print("==================================================")

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

	var board: Board3D = main.get_node("board")
	var camera: GameCamera = main.get_node("Node3D")
	assert(board != null, "board deve existir")
	assert(camera != null, "camera deve existir")

	# ----------------------------------------------------
	# [TESTE 1] Câmera: Enquadramento e perspectiva TFT
	# ----------------------------------------------------
	print("\n[TESTE 1] Validando parâmetros e posição da câmera:")
	print("  - initial_elevation_degrees: %.1f°" % camera.initial_elevation_degrees)
	assert(is_equal_approx(camera.initial_elevation_degrees, 46.0), "initial_elevation_degrees deve ser 46.0° para perspectiva TFT")
	print("  - focus_offset: ", camera.focus_offset)
	assert(camera.focus_offset.z > 0.5, "focus_offset.z deve ser positivo para equilibrar tabuleiro e banco")
	
	var viewport_size := root.get_viewport().get_visible_rect().size
	var metrics := ResponsiveLayout.battle_metrics(viewport_size)
	var board_rect: Rect2 = metrics["board_rect"]
	print("  - viewport_size: ", viewport_size)
	print("  - board_rect center x: ", board_rect.get_center().x)
	assert(is_equal_approx(board_rect.get_center().x, viewport_size.x * 0.5), "board_rect deve ser centralizado horizontalmente")
	
	var internal_cam := camera.get_node("Camera3D") as Camera3D
	assert(internal_cam != null, "Camera3D deve existir")
	print("  - camera.position.x: %.4f" % internal_cam.position.x)
	assert(is_equal_approx(internal_cam.position.x, 0.0), "Camera3D não deve ser deslocada horizontalmente para a direita")
	print("  ✓ Parâmetros e centralização da câmera validados com sucesso!")

	# ----------------------------------------------------
	# [TESTE 2] Unidade no campo: Barras sempre visíveis, nome APENAS no hover
	# ----------------------------------------------------
	print("\n[TESTE 2] Validando interface de unidade no campo:")
	var capivara_stats := UnitSpawner.load_unit_stats("capivara")
	assert(capivara_stats != null, "Stats de capivara devem carregar")
	var board_unit: BaseUnit3D = UnitSpawner.spawn_unit_from_stats(capivara_stats, 1, 0)
	main.add_child(board_unit)
	board.place_unit(board_unit, Vector2i(3, 4), false)
	await process_frame

	assert(not board_unit.is_on_bench(), "Unidade deve estar no campo")
	assert(board_unit.ui_sprite.visible, "ui_sprite deve estar visível no campo")
	assert(board_unit.bars_container.visible, "bars_container deve estar visível no campo")
	assert(board_unit.health_bar_3d.visible, "health_bar_3d deve estar visível no campo")
	assert(board_unit.mana_bar_3d.visible, "mana_bar_3d deve estar visível no campo")
	assert(not board_unit.nameplate_container.visible, "nameplate_container NÃO deve estar visível sem hover!")
	print("  - Sem hover: barras visíveis, nome oculto ✓")

	# Simular hover na unidade do campo
	board_unit.set_hovered(true)
	assert(board_unit.nameplate_container.visible, "nameplate_container DEVE estar visível com hover!")
	assert(board_unit.name_label.text == "Capivara", "Nome da unidade deve estar correto no nameplate")
	assert(board_unit.bars_container.visible, "bars_container continua visível com hover")
	print("  - Com hover: nome e tier exibidos no topo das barras ✓")

	# Retirar hover
	board_unit.set_hovered(false)
	assert(not board_unit.nameplate_container.visible, "nameplate_container deve ocultar ao sair o hover")
	assert(board_unit.bars_container.visible, "bars_container permanece visível")
	print("  - Saindo do hover: nome ocultado com sucesso ✓")

	# ----------------------------------------------------
	# [TESTE 3] Unidade no banco: Hover funciona, mas SEM barras de vida e mana
	# ----------------------------------------------------
	print("\n[TESTE 3] Validando unidade no banco:")
	var lobo_stats := UnitSpawner.load_unit_stats("lobo_guara")
	assert(lobo_stats != null, "Stats de lobo_guara devem carregar")
	var bench_unit: BaseUnit3D = UnitSpawner.spawn_unit_from_stats(lobo_stats, 2, 0)
	main.add_child(bench_unit)
	main.add_unit_to_bench(bench_unit)
	await process_frame

	assert(bench_unit.is_on_bench(), "Unidade deve estar no banco")
	assert(not bench_unit.bars_container.visible, "No banco: bars_container NUNCA deve estar visível!")
	assert(not bench_unit.ui_sprite.visible, "No banco sem hover: sprite deve estar oculto")
	assert(not bench_unit.nameplate_container.visible, "No banco sem hover: nameplate deve estar oculto")
	print("  - No banco sem hover: sem barras, sem rótulos (modelo limpo no pedestal) ✓")

	# Simular hover na unidade do banco
	bench_unit.set_hovered(true)
	assert(bench_unit.ui_sprite.visible, "No banco com hover: sprite deve estar visível")
	assert(bench_unit.nameplate_container.visible, "No banco com hover: nameplate DEVE estar visível")
	assert(bench_unit.name_label.text == "Lobo Guará", "Nome no banco deve ser Lobo Guará")
	assert(not bench_unit.bars_container.visible, "No banco com hover: barras de vida e mana continuam OCULTAS!")
	print("  - No banco com hover: nome/tier aparecem, barras de vida e mana continuam ocultas ✓")

	# Retirar hover no banco
	bench_unit.set_hovered(false)
	assert(not bench_unit.ui_sprite.visible, "No banco após sair do hover: sprite ocultado")
	assert(not bench_unit.nameplate_container.visible, "No banco após sair do hover: nameplate ocultado")
	assert(not bench_unit.bars_container.visible, "No banco: barras continuam ocultas")
	print("  - No banco saindo do hover: volta a ficar limpo ✓")

	# ----------------------------------------------------
	# [TESTE 4] Segmentação de vida estilo TFT (HealthBarTicks)
	# ----------------------------------------------------
	print("\n[TESTE 4] Validando ticks de segmentação de HP estilo TFT:")
	assert(board_unit._hp_ticks != null, "_hp_ticks deve existir como filho da health_bar_3d")
	assert(board_unit._hp_ticks.max_hp == board_unit.get_max_health(), "max_hp dos ticks deve corresponder ao max_health")
	print("  - Ticks de segmentação ativos com max_hp: %.0f ✓" % board_unit._hp_ticks.max_hp)

	print("\n==================================================")
	print("TODOS OS TESTES DE UI E CÂMERA PASSARAM COM 100% DE SUCESSO!")
	print("==================================================")
	quit(0)
