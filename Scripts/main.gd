extends Node3D

## Referências
@onready var board: Board3D = $board
@onready var camera: GameCamera = $Node3D
@onready var ui: CanvasLayer = $GameUi
@onready var nav_region: NavigationRegion3D = $NavigationRegion3D
var ui_visible: bool = true

## Sistemas
var shop_system: ShopSystem
var shop_ui: ShopUI
var drag_handler: BoardDragHandler


## Estado do jogador
var player_gold: int = 10
var player_health: int = 100
var player_level: int = 1
var player_xp: int = 0
var current_round: int = 1
var combat_active: bool = false

## Unidades do jogador
var bench_units: Array[BaseUnit3D] = []  # Reserva
var max_bench_size: int = 9
var dragging_unit: BaseUnit3D = null


@export var gold_on_win: int = 5
@export var gold_on_loss: int = 2
@export var win_streak_bonus_step: int = 1
@export var max_win_streak_bonus: int = 5

var win_streak: int = 0
var loss_streak: int = 0

func _ready() -> void:
	print("\n" + "=".repeat(50))
	print("FOLCHESS - PROTÓTIPO")
	print("=".repeat(50) + "\n")
	
	UnitSpawner.clear_cache()
	UnitSpawner.load_all_units()
	UnitSpawner.print_all_units()
	UnitSpawner.get_all_unit_info()
	
	await get_tree().process_frame
	
	# Configurar board
	if board:
		print("\nRecriando board...")
		for child in board.get_children():
			child.queue_free()
		
		await get_tree().process_frame
		board.generate_board()
		print("Board recriado\n")
	
	# Aguardar navigation
	if nav_region:
		await get_tree().process_frame
		await get_tree().process_frame
		print("Navigation pronto\n")
	
	# Configurar câmera
	if camera:
		camera.focus_on_board(board)
		print("Câmera configurada")
	
	# Configurar sistema de loja
	setup_shop_system()
	
	update_ui()
	
	print("\n" + "-".repeat(50))
	print("SPAWNING BOSS")
	print("-".repeat(50))
	test_spawn_units()
	
	print("\n" + "=".repeat(50))
	print("CONTROLES:")
	print("  [ESPAÇO] - Iniciar Combate")
	print("  [R] - Reroll Loja (2g)")
	print("  [L] - Lock/Unlock Loja")
	print("  [Q] - Comprar XP (4g)")
	print("  [Click] - Comprar Unidade")
	print("  [Drag] - Arrastar Unidade")
	print("=".repeat(50) + "\n")
	
	debug_initialization()

func spawn_enemy_team() -> void:
	var old_enemies = get_tree().get_nodes_in_group("enemy_units")
	for e in old_enemies: e.queue_free()
	var num_enemies = clampi(current_round, 1, 6)
	
	print("Gerando time inimigo com %d unidades" % num_enemies)
	
	for i in num_enemies:
		var tier = 1
		if current_round > 5: tier = [1,2,3].pick_random()
		elif current_round> 3: tier = [1,2].pick_random()
		
		var spawn_pos = Vector2i(randi() % board.columns, randi() % (board.rows  - board.player_rows))
		while board.is_cell_occupied(spawn_pos):
			spawn_pos = Vector2i(randi()% board.columns, randi() % (board.rows - board.player_rows))
		
		var enemy = UnitSpawner.spawn_random_unit_by_tier(tier, 1, 1)
		if enemy:
			add_child(enemy)
			board.place_unit(enemy, spawn_pos, true)

func setup_shop_system() -> void:
	shop_system = ShopSystem.new()
	shop_system.name = "ShopSystem"
	add_child(shop_system)
	
	shop_ui = ui.get_node_or_null("Control/BottomBar/ShopContainer") as ShopUI
	
	if shop_ui:
		shop_ui.set_shop_system(shop_system)
		shop_ui.unit_selected.connect(_on_unit_selected)
		shop_ui.reroll_requested.connect(_on_reroll_requested)
		shop_ui.lock_toggled.connect(_on_lock_toggled)
		print("ShopUI conectado")
	else:
		print("AVISO: ShopUI nao encontrado em Control/BottomBar/ShopContainer")
	
	shop_system.unit_purchased.connect(_on_unit_purchased)
	
	setup_drag_handler()
	
	shop_system.refresh_shop(player_level)
	
	print("Sistema de loja configurado")

func setup_drag_handler() -> void:
	drag_handler = BoardDragHandler.new()
	drag_handler.name = "DragHandler"
	add_child(drag_handler)
	
	var cam: Camera3D = camera.get_node("Camera3D") if camera else null
	
	if not cam:
		print("ERRO: Camera3D nao encontrada!")
		return
	
	drag_handler.setup(board, cam)
	drag_handler.unit_placed_on_board.connect(_on_unit_placed_on_board)
	
	drag_handler.unit_returned_to_shop.connect(_on_unit_returned_to_shop)
	print("Drag handler configurado")
	print("  Board: %s" % ("OK" if drag_handler.board else "NULL"))
	print("  Camera: %s" % ("OK" if drag_handler.camera else "NULL"))

func _on_unit_returned_to_shop(unit_stats: UnitStats) -> void:
	player_gold += unit_stats.cost
	print("Reembolso: +%dg (%s)" % [unit_stats.cost, unit_stats.unit_name])
	update_ui()

func _on_unit_selected(unit_stats: UnitStats, slot_index: int) -> void:
	if combat_active:
		print("Não pode comprar durante combate!")
		return
	
	print("Selecionado: %s (Tier %d) - Custo: %dg" % [
		unit_stats.unit_name,
		unit_stats.tier,
		unit_stats.cost
	])
	
	if player_gold < unit_stats.cost:
		print("Gold insuficiente! Precisa: %d, Tem: %d" % [unit_stats.cost, player_gold])
		return
	
	if bench_units.size() >= max_bench_size:
		print("Banco cheio! (%d/%d)" % [bench_units.size(), max_bench_size])
		return
	
	var purchased_unit: UnitStats = shop_system.purchase_unit(slot_index)
	
	if purchased_unit:
		player_gold -= purchased_unit.cost
		
		var unit_instance: BaseUnit3D = spawn_unit_for_drag(purchased_unit)
		
		if unit_instance:
			shop_ui.mark_slot_as_sold(slot_index)
			
			dragging_unit = unit_instance
			
			drag_handler.start_drag({
				"unit_stats": purchased_unit,
				"unit_instance": unit_instance,
				"slot_index": slot_index,
				"source": "shop"
			})
		
		update_ui()

func spawn_unit_for_drag(unit_stats: UnitStats) -> BaseUnit3D:
	var unit: BaseUnit3D = UnitSpawner.spawn_unit_from_stats(unit_stats, 1, 0)
	
	if unit:
		unit.use_navigation = false
		unit.debug_movement = false
		add_child(unit)
		
		unit.global_position = Vector3(-50, 10, 0)
		unit.visible = false
		
		return unit
	
	return null

func _on_unit_placed_on_board(unit: BaseUnit3D, grid_pos: Vector2i) -> void:
	if unit.team == 0 and get_player_units_on_board_count() >= get_board_unit_limit():
		print("Limite atingido")
		add_unit_to_bench(unit)
		dragging_unit = null
		update_ui()
		return
		
	unit.visible = true
	
	var success: bool = board.place_unit(unit, grid_pos, true)
	
	if success:
		dragging_unit = null
	else:
		unit.queue_free()
		dragging_unit = null
	

func _on_reroll_requested() -> void:
	if combat_active:
		print("Não pode rerollar durante combate!")
		return
	
	if player_gold < shop_system.reroll_cost:
		print("Gold insuficiente para reroll! Precisa: %d" % shop_system.reroll_cost)
		return
	
	player_gold -= shop_system.reroll_cost
	shop_system.refresh_shop(player_level)
	update_ui()
	print("Loja rerolada! (-%dg)" % shop_system.reroll_cost)

func _on_lock_toggled(is_locked: bool) -> void:
	shop_system.lock_shop(is_locked)

func _on_unit_purchased(unit_stats: UnitStats, cost: int) -> void:
	print("%s comprado por %dg!" % [unit_stats.unit_name, cost])

func add_unit_to_bench(unit: BaseUnit3D) -> void:
	if not unit: return
	
	if bench_units.size() >= max_bench_size:
		unit.queue_free()
		return
	
	if unit.board_position != Vector2i(-1,-1):
		board.remove_unit(unit.board_position)
		
	bench_units.append(unit)
	unit.visible = false
	unit.debug_movement = false
	unit.global_position = Vector3(-20 - bench_units.size(), 0, 0)
	
	print("%s enviado para o banco (%d/%d)" %[unit.stats.unit_name], bench_units.size(), max_bench_size)
	update_ui()

func test_spawn_units() -> void:
	# Spawnar apenas 1 BOSS inimigo (Tier 5)
	spawn_enemy_team()
	
	print("\nBoss inimigo spawnado!")
	print("Use a loja para comprar unidades!")

func spawn_boss_enemy() -> void:
	# Lista de bosses Tier 5
	var tier5_units: Array[UnitStats] = UnitSpawner.get_units_by_tier(5)
	
	if tier5_units.is_empty():
		print("Nenhuma unidade Tier 5 encontrada!")
		# Fallback para Tier 2
		spawn_and_place("mapinguari", Vector2i(3, 0), 1, 1)
		return
	
	# Escolher boss aleatório
	var boss_stats: UnitStats = tier5_units.pick_random()
	
	# Spawnar no centro da zona inimiga
	var boss_position: Vector2i = Vector2i(board.columns / 2, 0)
	
	var boss: BaseUnit3D = UnitSpawner.spawn_unit_from_stats(boss_stats, 2, 1)  # 2 estrelas
	if boss:
		boss.use_navigation = false
		boss.debug_movement = false
		add_child(boss)
		
		if board.place_unit(boss, boss_position, true):
			print("BOSS SPAWNED: %s em %v" % [boss_stats.unit_name, boss_position])
		else:
			boss.queue_free()

func spawn_and_place(unit_id: String, grid_pos: Vector2i, stars: int, team_id: int) -> BaseUnit3D:
	var unit: BaseUnit3D = UnitSpawner.spawn_unit(unit_id, stars, team_id)
	if unit:
		# FORÇAR MOVIMENTO DIRETO PARA TESTE
		unit.use_navigation = false
		unit.debug_movement = true
		
		add_child(unit)
		var success: bool = board.place_unit(unit, grid_pos, true)
		if success:
			print("Spawned: %s at %v (Team %d, %d)" % [unit_id, grid_pos, team_id, stars])
			return unit
		else:
			print("Failed to place: %s at %v" % [unit_id, grid_pos])
			unit.queue_free()
	else:
		print("Failed to spawn: %s" % unit_id)
	return null
func start_combat() -> void:
	if combat_active:
		print("Combate já está ativo!")
		return
	
	combat_active = true
	print("\n" + "=".repeat(50))
	print("COMBATE INICIADO!")
	print("=".repeat(50) + "\n")
	
	var units: Array = board.get_all_units()
	for unit in units:
		if unit is BaseUnit3D:
			unit.start_combat()
	
	# Monitorar fim do combate
	check_combat_end()

func check_combat_end() -> void:
	# Verificar a cada 0.5 segundos se o combate acabou
	while combat_active:
		await get_tree().create_timer(0.5).timeout
		
		var player_units: Array = get_tree().get_nodes_in_group("player_units")
		var enemy_units: Array = get_tree().get_nodes_in_group("enemy_units")
		
		# Filtrar mortos
		player_units = player_units.filter(func(u): return u.current_state != BaseUnit3D.State.DEAD)
		enemy_units = enemy_units.filter(func(u): return u.current_state != BaseUnit3D.State.DEAD)
		
		if player_units.is_empty() or enemy_units.is_empty():
			end_combat(player_units.size() > 0)
			break

func end_combat(player_won: bool) -> void:
	combat_active = false
	
	var result_label = Label.new()
	result_label.text = "VITÓRIA!" if player_won else "DERROTA..."
	result_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ui.add_child(result_label)
	result_label.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	
	var tween = create_tween()
	tween.tween_property(result_label, "modulate:a", 1.0, 0.5).from(0.0)
	tween.tween_interval(1.5)
	tween.tween_property(result_label, "modulate:a", 0.0, 0.5)
	tween.tween_callback(result_label.queue_free)
	
	if player_won:
		win_streak += 1
		loss_streak = 0
		
		var streak_bonus = min((win_streak - 1) * win_streak_bonus_step, max_win_streak_bonus)
		player_gold += gold_on_win + streak_bonus
		current_round += 1
	else:
		loss_streak += 1
		win_streak = 0
		
		player_gold += gold_on_loss
		player_health -= 10
	revive_dead_player_units()
	update_ui()
	
	if player_health <= 0:
		result_label.text = "GAME OVER!"
		await get_tree().create_timer(2.0).timeout
		get_tree().reload_current_scene()
		return
	print("=".repeat(50) + "\n")
	
	
	# Preparar próxima rodada
	await get_tree().create_timer(2.0).timeout
	prepare_next_round()

func prepare_next_round() -> void:
	print("preparando round")
	
	var player_units: Array = get_tree().get_nodes_in_group("player_units")
	for unit in player_units:
		if unit is BaseUnit3D:
			var home_pos = board.get_cell_world_position(unit.board_position)
		
			if unit.current_state == BaseUnit3D.State.DEAD:
				unit.revive_at_position(home_pos)
				board.place_unit(unit, unit.board_position, false)
			else:
				unit.current_health = unit.get_max_health()
				unit.current_mana = unit.stats.starting_mana
				unit.current_state = BaseUnit3D.State.IDLE
				unit.current_target = null
				unit.global_position = home_pos
				if unit.attack_timer:
					unit.attack_timer.stop()
				unit.update_health_bar()
				unit.update_mana_bar()
				
	shop_system.refresh_shop(player_level)
	spawn_enemy_team()
	update_ui()
	print("Novo round")

func update_ui() -> void:
	if not ui:
		return
	
	var gold_label: Label = ui.get_node_or_null("Control/TopBar/GoldLabel")
	var health_label: Label = ui.get_node_or_null("Control/TopBar/HealthLabel")
	var round_label: Label = ui.get_node_or_null("Control/TopBar/RoundLabel")
	var level_label: Label = ui.get_node_or_null("Control/TopBar/LevelLabel")
	var bench_label: Label = ui.get_node_or_null("Control/BottomBar/BenchLabel")
	
	if gold_label:
		gold_label.text = "Gold: %d" % player_gold
	if health_label:
		health_label.text = "HP: %d" % player_health
	if round_label:
		var combat_status: String = "COMBATE!" if combat_active else "PREPARACAO"
		round_label.text = "%s | Round: %d" % [combat_status, current_round]
	if level_label:
		var xp_needed: int = player_level * 2
		level_label.text = "Level: %d (XP: %d/%d)" % [player_level, player_xp, xp_needed]
	if bench_label:
		bench_label.text = "BANCO: %d/%d" % [bench_units.size(), max_bench_size]

func spawn_random_unit_at_position(tier: int, team: int) -> void:
	# Verificar se existem unidades desse tier
	var available_units: Array[UnitStats] = UnitSpawner.get_units_by_tier(tier)
	
	if available_units.is_empty():
		print("Nenhuma unidade Tier %d encontrada! Execute create_more_units.gd" % tier)
		return
	
	# Encontrar posição vazia
	var valid_positions: Array[Vector2i] = []
	
	var row_range: Array[int]
	if team == 0:
		row_range = [board.rows - board.player_rows, board.rows - 1]  # Ex: [2, 3]
	else:
		row_range = [0, board.rows - board.player_rows - 1]  # Ex: [0, 1]
	
	for row in range(row_range[0], row_range[1] + 1):
		for col in board.columns:
			var pos: Vector2i = Vector2i(col, row)
			if not board.is_cell_occupied(pos):
				valid_positions.append(pos)
	
	if valid_positions.is_empty():
		print("Sem espaço disponível!")
		return
	
	var random_pos: Vector2i = valid_positions.pick_random()
	var unit: BaseUnit3D = UnitSpawner.spawn_random_unit_by_tier(tier, 1, team)
	
	if unit:
		add_child(unit)
		if board.place_unit(unit, random_pos, true):
			print("%s (Tier %d) spawnado em %v" % [unit.stats.unit_name, tier, random_pos])
		else:
			unit.queue_free()
	else:
		print("Falha ao spawnar unidade Tier %d" % tier)
func clear_board() -> void:
	print("\nLimpando board...")
	board.clear_board()
	combat_active = false
	print("Board limpo!")


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept"):
		if not combat_active:
			start_combat()
	
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_R:
				if not combat_active:
					_on_reroll_requested()
			
			KEY_L:
				_on_lock_toggled(not shop_system.is_shop_locked)
			
			KEY_Q:
				if not combat_active:
					buy_xp()
			
			KEY_C:
				if not combat_active:
					clear_board()
			
			KEY_ESCAPE:
				if drag_handler and drag_handler.is_dragging:
					drag_handler.stop_drag()
					if dragging_unit:
						dragging_unit.queue_free()
						dragging_unit = null
			KEY_H:
				if ui:
					ui_visible = !ui_visible
					ui.visible = ui_visible
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_RIGHT:
			inspect_unit_at_mouse(event.position)

func buy_xp() -> void:
	if player_gold < shop_system.xp_cost:
		print("Gold insuficiente para XP!")
		return
	
	player_gold -= shop_system.xp_cost
	player_xp += 4
	
	var xp_needed: int = player_level * 2
	if player_xp >= xp_needed:
		player_level += 1
		player_xp -= xp_needed
		print("LEVEL UP! Agora level %d" % player_level)
		shop_system.refresh_shop(player_level)
	
	update_ui()

#func _process(_delta: float) -> void:
	## Atualizar debug info
	#var debug_label = ui.get_node_or_null("Control/DebugPanel/DebugLabel")
	#if debug_label:
		#var player_units: int = get_tree().get_nodes_in_group("player_units").size()
		#var enemy_units: int = get_tree().get_nodes_in_group("enemy_units").size()
		#var total_units: int = board.get_all_units().size()
		#
		#debug_label.text = "DEBUG INFO\n\n"
		#debug_label.text += "Player Units: %d\n" % player_units
		#debug_label.text += "Enemy Units: %d\n" % enemy_units
		#debug_label.text += "Total: %d\n\n" % total_units
		#debug_label.text += "Combat: %s\n" % ("YES" if combat_active else "NO")
		#debug_label.text += "FPS: %d" % Engine.get_frames_per_second()
		

func _on_reroll_button_pressed() -> void:
	_on_reroll_requested()

func _on_lock_button_pressed() -> void:
	_on_lock_toggled(not shop_system.is_shop_locked)

func _on_buy_xp_button_pressed() -> void:
	buy_xp()
	

# --- Painel de inspeção lateral ---

func inspect_unit_at_mouse(mouse_pos: Vector2) -> void:
	var from = camera.get_node("Camera3D").project_ray_origin(mouse_pos)
	var to = from + camera.get_node("Camera3D").project_ray_normal(mouse_pos) * 1000
	var query = PhysicsRayQueryParameters3D.create(from, to)
	query.collision_mask = 1
	
	var result = get_world_3d().direct_space_state.intersect_ray(query)
	
	if result and result.collider is BaseUnit3D:
		show_unit_inspector(result.collider)
	else:
		hide_unit_inspector()
	

func show_unit_inspector(unit: BaseUnit3D) -> void:
	var panel = ui.get_node("Control/RightBar")
	var stats = unit.stats
	
	panel.show()
	panel.get_node("NinePatchRect/VBoxContainer/Name_label").text = stats.unit_name
	panel.get_node("NinePatchRect/VBoxContainer/Image_container").texture = stats.icon
	panel.get_node("NinePatchRect/VBoxContainer/Hp_label").text = "Vida: %s" %[str(stats.max_health)]
	panel.get_node("NinePatchRect/VBoxContainer/Mana_label").text = "Mana: %s" %[str(stats.max_mana)]
	panel.get_node("NinePatchRect/VBoxContainer/Range_label").text = "Distância" if stats.is_ranged else "Corpo a Corpo"
	panel.get_node("NinePatchRect/VBoxContainer/Type_label").text = "Físico" if stats.attack_damage == 0  else "Mágico"
	
	var tween := create_tween()
	panel.position.x = get_viewport().size.x
	tween.tween_property(panel, "position:x", get_viewport().size.x -250, 0.3)
	
func hide_unit_inspector() -> void:
	ui.get_node("Control/RightBar").hide()


func get_board_unit_limit() -> int:
	return player_level + 2
	

func get_player_units_on_board_count() -> int:
	var count := 0
	for unit in board.get_all_units():
		if not is_instance_valid(unit):
			continue
			
		if unit is BaseUnit3D and unit.team == 0:
			count += 1
	return count

func revive_dead_player_units() -> void:
	var player_units = get_tree().get_nodes_in_group("player_units")
	
	for unit in player_units:
		if unit is BaseUnit3D and unit.current_state == BaseUnit3D.State.DEAD:
			var home_pos = board.get_cell_world_position(unit.board_position)
			unit.revive_at_position(home_pos)
			board.place_unit(unit, unit.board_position, false)
	

func debug_initialization() -> void:
	print("\n=== DEBUG INICIALIZACAO ===")
	print("Board: %s" % board)
	print("Camera: %s" % camera)
	print("UI: %s" % ui)
	print("ShopSystem: %s" % shop_system)
	print("ShopUI: %s" % shop_ui)
	print("DragHandler: %s" % drag_handler)
	
	if camera:
		print("Camera type: %s" % camera.get_class())
		var cam_3d: Camera3D = camera.get_node("Camera3D")
		print("Camera3D child: %s" % cam_3d)
	
	if drag_handler:
		print("DragHandler.board: %s" % drag_handler.board)
		print("DragHandler.camera: %s" % drag_handler.camera)
		print("DragHandler.is_dragging: %s" % drag_handler.is_dragging)
	else:
		print("ERRO CRITICO: DragHandler e NULL!")
	
	print("=== FIM DEBUG ===\n")
