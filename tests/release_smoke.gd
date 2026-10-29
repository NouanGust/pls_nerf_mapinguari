extends SceneTree
## Pode ser executado contra um PCK exportado usando --main-pack e o caminho absoluto deste script.

var failures := 0

func _initialize() -> void:
	call_deferred("_run")

func check(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		push_error(message)

func capture(file_name: String) -> void:
	if DisplayServer.get_name() == "headless":
		return
	await create_timer(0.4).timeout
	await RenderingServer.frame_post_draw
	var output_dir := OS.get_environment("FOLCHESS_CAPTURE_DIR")
	if not output_dir.is_empty():
		root.get_texture().get_image().save_png(output_dir.path_join(file_name))

func _run() -> void:
	check(not FileAccess.file_exists("res://project.godot"), "Executar o teste isolado da pasta fonte, contra o PCK")
	var all_units := UnitSpawner.load_all_units()
	check(all_units.size() == 66, "O pacote deve carregar as 66 unidades do catálogo")
	var models = load("res://Scripts/Units/biodiversity_models.gd")
	for id in models.ANIMALS.keys() + models.PLANTS.keys():
		var model: Node3D = models.create_model(all_units[id])
		check(model != null and model.get_child_count() > 0, "Modelo exportado: " + id)
		model.free()
	var menu := (load("res://Scenes/UI/Menu.tscn") as PackedScene).instantiate()
	root.add_child(menu)
	current_scene = menu
	await process_frame
	check(menu._home.visible and not menu._selection.visible, "Início com ações principais")
	await capture("inicio.png")
	menu._show_regions()
	check(menu._region_buttons.size() == 6, "Seis regiões disponíveis")
	for id in menu._region_buttons:
		menu._select_region(id)
		check(menu._region_buttons[id].button_pressed, "Seleção de " + id)
		var selected_count := 0
		for button: Button in menu._region_buttons.values():
			selected_count += int(button.button_pressed)
		check(selected_count == 1, "Somente uma região selecionada")
	menu._select_region("cerrado")
	await capture("regioes.png")
	menu._enter_region("cerrado")
	await create_timer(1.0).timeout
	var battle := current_scene
	check(battle.region_id == "cerrado" and battle.shop_system != null, "Partida inicia fora do editor")
	check(battle.shop_system.get_shop_units().size() > 0, "Loja populada no pacote")
	var ui: GameUI = battle.ui
	ui.update_synergies([
		{"name": "Flora", "category": "Afinidade", "count": 1, "threshold": 3, "active": false, "description": "+15% de cura e escudos recebidos"},
		{"name": "Caatinga", "category": "Origem", "count": 2, "threshold": 4, "active": true, "description": "Recebe 8% menos dano"},
	])
	check(ui.spawned_synergy_rows.size() == 2, "Sinergias renderizadas")
	check(ui.spawned_synergy_rows[0].get_node("Row/Content/Header/TagLabel").text == "Caatinga", "Sinergias ativas primeiro")
	ui.synergy_panel.show()
	await capture("sinergias.png")
	battle.queue_free()
	await process_frame
	print("RELEASE SMOKE: ", "PASS" if failures == 0 else "FAIL")
	quit(0 if failures == 0 else 1)
