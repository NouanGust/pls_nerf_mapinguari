extends Node3D

const Progression = preload("res://Scripts/Systems/level_progression.gd")
const Regions = preload("res://Scripts/Systems/region_rosters.gd")

@export_enum("cerrado", "pantanal", "amazonia", "caatinga", "mata_atlantica", "litoral") var region_id: String = "cerrado"
var enemy_level: int = 1
var enemy_xp: int = 0

## Referências
@onready var board: Board3D = $board
@onready var camera: GameCamera = $Node3D
@onready var ui: GameUI = $GameUi
@onready var nav_region: NavigationRegion3D = $NavigationRegion3D
@onready var bench_ui: BenchUI = $GameUi/Control/BenchPanel/BenchContent/BenchSlots
var ui_visible: bool = true

## Sistemas
var shop_system: ShopSystem
var shop_ui: ShopUI
var drag_handler: BoardDragHandler
var synergy_system: SynergySystem


## Estado do jogador
var player_gold: int = 10
var player_health: int = 100
var player_level: int = 1
var player_xp: int = 0
var current_round: int = 1
var combat_active: bool = false
var round_resolution_pending: bool = false

## Unidades do jogador
var bench_units: Array[BaseUnit3D] = []  # Reserva
var max_bench_size: int = 9
var dragging_unit: BaseUnit3D = null
var combat_report_entries: Dictionary = {}
var active_synergies: Dictionary = {}
var battle_time_remaining: float = 0.0


@export var gold_on_win: int = 2
@export var gold_on_loss: int = 1
@export var battle_duration_seconds: float = 60.0
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
		print("\nBoard hexagonal pronto: %d × %d\n" % [board.rows, board.columns])
	
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
	
	spawn_enemy_team()
	
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
	for old_enemy in get_tree().get_nodes_in_group("enemy_units"):
		if old_enemy is BaseUnit3D and board.get_unit_at(old_enemy.board_position) == old_enemy:
			board.remove_unit(old_enemy.board_position)
		old_enemy.remove_from_group("enemy_units")
		old_enemy.queue_free()
	for slot in Regions.get_formation(region_id, enemy_level):
		var enemy := UnitSpawner.spawn_unit(str(slot["unit_id"]), 1, 1)
		if enemy:
			enemy.use_navigation = false
			enemy.debug_movement = false
			add_child(enemy)
			if not board.place_unit(enemy, slot["position"], false):
				push_error("Não foi possível posicionar a unidade regional %s" % slot["unit_id"])
				enemy.remove_from_group("enemy_units")
				enemy.queue_free()
	_refresh_synergies()

func setup_shop_system() -> void:
	shop_system = ShopSystem.new()
	shop_system.name = "ShopSystem"
	add_child(shop_system)
	synergy_system = SynergySystem.new()
	synergy_system.name = "SynergySystem"
	add_child(synergy_system)
	
	shop_ui = ui.get_node_or_null("Control/BottomBar/ShopContainer") as ShopUI
	
	if shop_ui:
		shop_ui.set_shop_system(shop_system)
		shop_ui.unit_selected.connect(_on_unit_selected)
		shop_ui.unit_drag_requested.connect(_on_shop_unit_drag_requested)
		shop_ui.reroll_requested.connect(_on_reroll_requested)
		shop_ui.lock_toggled.connect(_on_lock_toggled)
		print("ShopUI conectado")
	else:
		print("AVISO: ShopUI nao encontrado em Control/BottomBar/ShopContainer")
	if bench_ui:
		bench_ui.unit_drag_started.connect(_on_bench_unit_drag_started)
	
	shop_system.unit_purchased.connect(_on_unit_purchased)
	
	setup_drag_handler()
	
	_refresh_shop()
	
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
	camera.drag_handler = drag_handler
	drag_handler.set_bench_control(bench_ui)
	drag_handler.set_sell_zone_control(ui.get_sell_zone())
	drag_handler.unit_placed_on_board.connect(_on_unit_placed_on_board)
	drag_handler.unit_placed_on_bench.connect(_on_unit_placed_on_bench)
	drag_handler.unit_sold.connect(_on_drag_unit_sold)
	
	drag_handler.unit_returned_to_shop.connect(_on_unit_returned_to_shop)
	print("Drag handler configurado")
	print("  Board: %s" % ("OK" if drag_handler.board else "NULL"))
	print("  Camera: %s" % ("OK" if drag_handler.camera else "NULL"))

func _on_unit_returned_to_shop(unit_stats: UnitStats) -> void:
	player_gold += unit_stats.cost
	print("Reembolso: +%dg (%s)" % [unit_stats.cost, unit_stats.unit_name])
	# O arraste libera a unidade logo após emitir o reembolso.
	update_ui.call_deferred()

func _on_bench_unit_drag_started(slot_index: int) -> void:
	if round_resolution_pending or not drag_handler or drag_handler.is_dragging:
		return
	if slot_index < 0 or slot_index >= bench_units.size():
		return

	var unit: BaseUnit3D = bench_units[slot_index]
	dragging_unit = unit
	drag_handler.start_drag({
		"unit_stats": unit.stats,
		"unit_instance": unit,
		"source": "bench",
		"bench_index": slot_index
	})

func _on_unit_placed_on_bench(unit: BaseUnit3D, source: String, _source_index: int) -> void:
	if combat_active or round_resolution_pending or not unit:
		return
	if add_unit_to_bench(unit):
		dragging_unit = null
		_resolve_unit_merges()
		update_ui()
		return

	if source == "board":
		board.place_unit(unit, unit.board_position, true)
	elif source == "shop":
		player_gold += unit.stats.cost
		unit.queue_free()
	dragging_unit = null
	update_ui()

func _on_unit_selected(unit_stats: UnitStats, slot_index: int) -> void:
	_purchase_shop_unit(unit_stats, slot_index, false)


func _on_shop_unit_drag_requested(unit_stats: UnitStats, slot_index: int) -> void:
	_purchase_shop_unit(unit_stats, slot_index, true)


func _purchase_shop_unit(unit_stats: UnitStats, slot_index: int, start_dragging: bool) -> void:
	if round_resolution_pending or (drag_handler and drag_handler.is_dragging):
		return
	# Durante a luta toda compra ocupa uma vaga do banco, inclusive por arraste.
	if combat_active:
		start_dragging = false
	
	print("Selecionado: %s (Tier %d) - Custo: %dg" % [
		unit_stats.unit_name,
		unit_stats.tier,
		unit_stats.cost
	])
	
	if player_gold < unit_stats.cost:
		print("Gold insuficiente! Precisa: %d, Tem: %d" % [unit_stats.cost, player_gold])
		return
	
	if not start_dragging and bench_units.size() >= max_bench_size:
		print("Banco cheio! (%d/%d)" % [bench_units.size(), max_bench_size])
		return
	
	var purchased_unit: UnitStats = shop_system.purchase_unit(slot_index)
	if not purchased_unit:
		return
	player_gold -= purchased_unit.cost
	var unit_instance: BaseUnit3D = spawn_unit_for_drag(purchased_unit)
	if not unit_instance:
		player_gold += purchased_unit.cost
		return
	shop_ui.mark_slot_as_sold(slot_index)
	if start_dragging:
		dragging_unit = unit_instance
		drag_handler.start_drag({
			"unit_stats": purchased_unit,
			"unit_instance": unit_instance,
			"slot_index": slot_index,
			"source": "shop"
		})
	elif add_unit_to_bench(unit_instance):
		_resolve_unit_merges()
	else:
		player_gold += purchased_unit.cost
		unit_instance.queue_free()
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

func _on_unit_placed_on_board(unit: BaseUnit3D, grid_pos: Vector2i, source: String, source_index: int) -> void:
	if combat_active or round_resolution_pending:
		if source == "bench":
			unit.visible = false
		elif source == "board":
			board.place_unit(unit, unit.board_position, true)
		else:
			player_gold += unit.stats.cost
			unit.queue_free()
		dragging_unit = null
		return

	if unit.team == 0 and get_player_units_on_board_count() >= get_board_unit_limit():
		print("Limite atingido")
		if source == "bench":
			unit.visible = false
		elif add_unit_to_bench(unit):
			_resolve_unit_merges()
		else:
			if source == "board":
				board.place_unit(unit, unit.board_position, true)
			else:
				player_gold += unit.stats.cost
				unit.queue_free()
		dragging_unit = null
		update_ui()
		return
		
	unit.visible = true
	
	var success: bool = board.place_unit(unit, grid_pos, true)
	
	if success:
		unit.play_pending_star_upgrade_effect()
		if source == "bench" and source_index >= 0 and source_index < bench_units.size():
			bench_units.remove_at(source_index)
		dragging_unit = null
		_resolve_unit_merges()
		update_ui()
	else:
		if source == "bench":
			unit.visible = false
		elif source == "board":
			board.place_unit(unit, unit.board_position, true)
		else:
			player_gold += unit.stats.cost
			unit.queue_free()
		dragging_unit = null
		update_ui()
	

func _on_reroll_requested() -> void:
	if round_resolution_pending:
		return
	
	if player_gold < shop_system.reroll_cost:
		print("Gold insuficiente para reroll! Precisa: %d" % shop_system.reroll_cost)
		return
	
	player_gold -= shop_system.reroll_cost
	_refresh_shop()
	update_ui()
	print("Loja rerolada! (-%dg)" % shop_system.reroll_cost)

func _on_lock_toggled(is_locked: bool) -> void:
	shop_system.lock_shop(is_locked)

func _on_unit_purchased(unit_stats: UnitStats, cost: int) -> void:
	print("%s comprado por %dg!" % [unit_stats.unit_name, cost])

func add_unit_to_bench(unit: BaseUnit3D) -> bool:
	if not unit: return false
	
	if bench_units.size() >= max_bench_size:
		return false
	
	if board.get_unit_at(unit.board_position) == unit:
		board.remove_unit(unit.board_position)
		
	bench_units.append(unit)
	unit.visible = false
	unit.debug_movement = false
	unit.global_position = Vector3(-20 - bench_units.size(), -100, 0)
	
	print("%s enviado para o banco (%d/%d)" % [unit.stats.unit_name, bench_units.size(), max_bench_size])
	return true

func _resolve_unit_merges() -> void:
	# Recalcula as cópias na preparação: vender uma reserva pode desfazer o trio.
	if combat_active or round_resolution_pending:
		return
	while true:
		var copies_by_key: Dictionary = {}
		var owned_units: Array[BaseUnit3D] = []
		owned_units.append_array(bench_units)
		for unit in board.get_all_units():
			if unit is BaseUnit3D and unit not in owned_units:
				owned_units.append(unit)
		for unit in owned_units:
			if unit.team != 0 or unit.current_state == BaseUnit3D.State.DEAD or unit.star_level >= 4:
				continue
			var key := "%s:%d" % [unit.stats.unit_id, unit.star_level]
			if not copies_by_key.has(key):
				copies_by_key[key] = []
			copies_by_key[key].append(unit)

		var merge_copies: Array = []
		for key in copies_by_key:
			if copies_by_key[key].size() >= 3:
				merge_copies = copies_by_key[key]
				break
		if merge_copies.is_empty():
			break

		merge_copies.sort_custom(func(a: BaseUnit3D, b: BaseUnit3D) -> bool:
			return board.get_unit_at(a.board_position) == a and board.get_unit_at(b.board_position) != b
		)
		var consumed: Array = merge_copies.slice(0, 3)
		var old_star: int = consumed[0].star_level
		var survivor: BaseUnit3D = consumed[0]
		for candidate in consumed:
			if board.get_unit_at(candidate.board_position) == candidate:
				survivor = candidate
				break
		var total_invested := 0
		for unit in consumed:
			total_invested += unit.invested_gold
			if unit == survivor:
				continue
			if bench_units.has(unit):
				bench_units.erase(unit)
			if board.get_unit_at(unit.board_position) == unit:
				board.remove_unit(unit.board_position)
			unit.queue_free()
		survivor.invested_gold = total_invested
		survivor.promote_to_star(old_star + 1)
		print("%s evoluiu para %d estrelas" % [survivor.stats.unit_name, survivor.star_level])

	_update_shop_exclusions()
	_refresh_synergies()

func _update_shop_exclusions() -> void:
	if not shop_system:
		return
	var unavailable: Array[String] = []
	for unit in get_tree().get_nodes_in_group("player_units"):
		if unit is BaseUnit3D and unit.star_level >= 4 and not unavailable.has(unit.stats.unit_id):
			unavailable.append(unit.stats.unit_id)
	shop_system.set_unavailable_unit_ids(unavailable)

func _refresh_shop() -> void:
	if not shop_system:
		return
	_update_shop_exclusions()
	shop_system.refresh_shop(player_level)

func _refresh_synergies() -> void:
	if not synergy_system or not board:
		return
	var results: Dictionary = synergy_system.update_synergies(board.get_all_units())
	var player_synergies: Array = results.get(0, [])
	var current_active: Dictionary = {}
	for team_id in [0, 1]:
		for synergy in results.get(team_id, []):
			if not bool(synergy.get("active", false)):
				continue
			var key := "%d:%s:%s" % [team_id, synergy.get("category", ""), synergy.get("name", "")]
			var tier := int(synergy.get("tier", 1))
			current_active[key] = tier
			if tier > int(active_synergies.get(key, 0)):
				_play_synergy_activation(synergy, team_id)
	active_synergies = current_active
	if ui:
		ui.update_synergies(player_synergies)

func _play_synergy_activation(synergy: Dictionary, team_id: int) -> void:
	var stat_field := ""
	match str(synergy.get("category", "")):
		"Origem":
			stat_field = "origins"
		"Classe":
			stat_field = "classes"
		"Afinidade":
			stat_field = "affinities"
	if stat_field.is_empty():
		return
	var synergy_name := str(synergy.get("name", ""))
	var hue := float(posmod(hash("%s:%s" % [stat_field, synergy_name]), 360)) / 360.0
	var particle_color := Color.from_hsv(hue, 0.78, 1.0)
	for unit in board.get_all_units():
		if not (unit is BaseUnit3D) or unit.team != team_id or unit.current_state == BaseUnit3D.State.DEAD:
			continue
		var tags: Array = unit.stats.get(stat_field)
		if tags.has(synergy_name):
			CombatFeedback.create_hit_particles(unit.global_position, particle_color)

func _on_drag_unit_sold(unit: BaseUnit3D, source: String, _source_index: int) -> void:
	_sell_unit(unit, source)

func _sell_hovered_unit() -> void:
	if round_resolution_pending or (drag_handler and drag_handler.is_dragging):
		return
	var mouse_position := get_viewport().get_mouse_position()
	if bench_ui:
		var bench_index := bench_ui.get_unit_index_at(mouse_position)
		if bench_index >= 0 and bench_index < bench_units.size():
			_sell_unit(bench_units[bench_index], "bench")
			return
	if combat_active:
		return
	if get_viewport().gui_get_hovered_control() != null:
		return
	var camera_3d := camera.get_node_or_null("Camera3D") as Camera3D if camera else null
	if not camera_3d:
		return
	var origin := camera_3d.project_ray_origin(mouse_position)
	var query := PhysicsRayQueryParameters3D.create(origin, origin + camera_3d.project_ray_normal(mouse_position) * 1000.0)
	query.collision_mask = 1
	var hit := board.get_world_3d().direct_space_state.intersect_ray(query)
	if hit and hit.collider is BaseUnit3D:
		_sell_unit(hit.collider, "board")

func _sell_unit(unit: BaseUnit3D, source: String = "") -> void:
	if round_resolution_pending or not is_instance_valid(unit) or unit.is_queued_for_deletion() or unit.team != 0 or unit.current_state == BaseUnit3D.State.DEAD:
		return
	var on_board := board.get_unit_at(unit.board_position) == unit
	var in_bench := bench_units.has(unit)
	# A origem informada pelo arraste não pode autorizar vender um combatente.
	if combat_active and (on_board or not in_bench):
		return
	var was_dragged := dragging_unit == unit or source in ["board", "bench"]
	if not on_board and not in_bench and not was_dragged:
		return
	if on_board:
		board.remove_unit(unit.board_position)
	if in_bench:
		bench_units.erase(unit)
	player_gold += unit.invested_gold
	print("%s vendido por %d ouro" % [unit.stats.unit_name, unit.invested_gold])
	if dragging_unit == unit:
		dragging_unit = null
	unit.remove_from_group("player_units")
	unit.queue_free()
	_update_shop_exclusions()
	if not combat_active:
		_refresh_synergies()
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
	if combat_active or round_resolution_pending:
		print("Combate já está ativo!")
		return
	if drag_handler and drag_handler.is_dragging:
		drag_handler.cancel_drag()
		dragging_unit = null
		update_ui()
	_refresh_synergies()
	
	combat_active = true
	battle_time_remaining = maxf(battle_duration_seconds, 1.0)
	if drag_handler:
		drag_handler.board_interaction_enabled = false
	update_ui()
	print("\n" + "=".repeat(50))
	print("COMBATE INICIADO!")
	print("=".repeat(50) + "\n")
	
	var units: Array = board.get_all_units()
	_capture_combat_roster(units)
	for unit in units:
		if unit is BaseUnit3D:
			unit.start_combat()
	
	# Monitorar fim do combate
	check_combat_end()

func _capture_combat_roster(units: Array) -> void:
	combat_report_entries.clear()
	for candidate in units:
		if not (candidate is BaseUnit3D):
			continue
		var unit: BaseUnit3D = candidate
		if not unit.visible or unit.current_state == BaseUnit3D.State.DEAD:
			continue
		var instance_id := unit.get_instance_id()
		combat_report_entries[instance_id] = {
			"name": unit.stats.unit_name,
			"team": unit.team,
			"icon": unit.stats.icon,
			"damage_dealt": 0.0,
			"healing_done": 0.0,
			"damage_received": 0.0,
		}
		if not unit.combat_metric_recorded.is_connected(_on_combat_metric_recorded):
			unit.combat_metric_recorded.connect(_on_combat_metric_recorded)

func _on_combat_metric_recorded(unit: BaseUnit3D, metric: StringName, amount: float) -> void:
	if not is_instance_valid(unit):
		return
	var instance_id := unit.get_instance_id()
	if not combat_report_entries.has(instance_id):
		return
	var entry: Dictionary = combat_report_entries[instance_id]
	entry[metric] = float(entry.get(metric, 0.0)) + amount
	combat_report_entries[instance_id] = entry

func check_combat_end() -> void:
	var deadline_msec := Time.get_ticks_msec() + int(maxf(battle_duration_seconds, 1.0) * 1000.0)
	while combat_active:
		await get_tree().create_timer(0.25).timeout
		if not combat_active:
			return
		battle_time_remaining = maxf(float(deadline_msec - Time.get_ticks_msec()) / 1000.0, 0.0)
		_update_round_label()
		
		var player_units: Array = []
		var enemy_units: Array = []
		for unit in board.get_all_units():
			if not (unit is BaseUnit3D) or unit.current_state == BaseUnit3D.State.DEAD:
				continue
			if unit.team == 0:
				player_units.append(unit)
			else:
				enemy_units.append(unit)
		
		if player_units.is_empty() and enemy_units.is_empty():
			end_combat(false, true)
			return
		if player_units.is_empty() or enemy_units.is_empty():
			end_combat(player_units.size() > 0)
			return
		if battle_time_remaining <= 0.0:
			end_combat(false, true)
			return

func end_combat(player_won: bool, is_draw: bool = false) -> void:
	if not combat_active:
		return
	combat_active = false
	round_resolution_pending = true
	battle_time_remaining = 0.0
	var finished_round := current_round
	# Congela todos os sobreviventes no resultado para que ninguém continue
	# atacando durante a tela do relatório ou enquanto o próximo round é preparado.
	for unit in board.get_all_units():
		if not (unit is BaseUnit3D) or unit.current_state == BaseUnit3D.State.DEAD:
			continue
		if unit.attack_timer:
			unit.attack_timer.stop()
		unit.current_target = null
		unit.current_state = BaseUnit3D.State.IDLE
		unit.velocity = Vector3.ZERO
	if drag_handler:
		drag_handler.cancel_drag()
		dragging_unit = null
		drag_handler.interaction_enabled = false
	
	if is_draw:
		win_streak = 0
		loss_streak = 0
		player_gold += roundi(float(gold_on_win) * 0.5)
		player_health -= 5
	elif player_won:
		win_streak += 1
		loss_streak = 0
		
		var streak_bonus = min((win_streak - 1) * win_streak_bonus_step, max_win_streak_bonus)
		player_gold += gold_on_win + streak_bonus
	else:
		loss_streak += 1
		win_streak = 0
		
		player_gold += gold_on_loss
		player_health -= 10
	# Todo resultado encerra um round, inclusive derrota e empate.
	current_round += 1
	_grant_round_xp()
	revive_dead_player_units()
	update_ui()
	var is_game_over := player_health <= 0
	var report := CombatReport.new()
	ui.add_child(report)
	report.show_report(finished_round, player_won, _get_combat_report_data(), is_draw)
	if is_game_over:
		report.set_return_to_menu()
	await report.continue_requested
	report.queue_free()

	if is_game_over:
		get_tree().change_scene_to_file("res://Scenes/UI/Menu.tscn")
		return
	print("=".repeat(50) + "\n")
	prepare_next_round()

func _get_combat_report_data() -> Array[Dictionary]:
	var report_data: Array[Dictionary] = []
	for entry in combat_report_entries.values():
		report_data.append(entry.duplicate(true))
	return report_data

func prepare_next_round() -> void:
	print("preparando round")
	if drag_handler:
		drag_handler.cancel_drag()
	dragging_unit = null
	
	var player_units: Array = get_tree().get_nodes_in_group("player_units")
	for unit in player_units:
		if unit is BaseUnit3D and unit not in bench_units:
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
				
	# Os sobreviventes já voltaram às casas e os mortos já foram restaurados.
	# Resolve também evoluções em cadeia antes de sortear a próxima loja.
	round_resolution_pending = false
	_resolve_unit_merges()
	if drag_handler:
		drag_handler.interaction_enabled = true
		drag_handler.board_interaction_enabled = true
	_refresh_shop()
	spawn_enemy_team()
	update_ui()
	print("Novo round")

func update_ui() -> void:
	if not ui:
		return
	
	var gold_label: Label = ui.get_node_or_null("Control/TopBar/GoldLabel")
	var health_label: Label = ui.get_node_or_null("Control/TopBar/HealthLabel")
	var level_label: Label = ui.get_node_or_null("Control/TopBar/LevelLabel")
	
	if gold_label:
		gold_label.text = "Ouro: %d" % player_gold
	if health_label:
		health_label.text = "HP: %d" % player_health
	_update_round_label()
	if level_label:
		level_label.text = "Nível 9 · MÁX" if player_level >= Progression.MAX_LEVEL else "Nível %d · XP %d/%d" % [player_level, player_xp, Progression.required_xp(player_level)]
	var region_label := ui.get_node_or_null("Control/RegionLabel") as Label
	if region_label:
		var xp_text := "MÁX" if enemy_level >= Progression.MAX_LEVEL else "XP %d/%d" % [enemy_xp, Progression.required_xp(enemy_level)]
		region_label.text = "%s · Inimigo nível %d · %s" % [Regions.get_region(region_id)["name"], enemy_level, xp_text]
	var xp_button := ui.get_node_or_null("Control/BottomBar/ControlsContainer/BuyXPButton") as Button
	if xp_button and shop_system:
		xp_button.disabled = round_resolution_pending or player_level >= Progression.MAX_LEVEL or player_gold < shop_system.xp_cost
		xp_button.text = "Nível máximo" if player_level >= Progression.MAX_LEVEL else "+4 XP · 4g"
		xp_button.tooltip_text = "Limite de 9 peças alcançado" if player_level >= Progression.MAX_LEVEL else "Comprar 4 XP por 4 de ouro (Q). +2 XP gratuitos ao final de cada round."
	var board_count_label: Label = ui.get_node_or_null("Control/BoardCountLabel")
	if board_count_label:
		board_count_label.text = "NO CAMPO · %d / %d" % [get_player_units_on_board_count(), get_board_unit_limit()]
	if bench_ui:
		bench_ui.set_units(bench_units, combat_active)
	_update_shop_upgrade_hints()

func _update_shop_upgrade_hints() -> void:
	if not shop_ui:
		return
	var counts: Dictionary = {}
	# Inclui combatentes mortos: eles voltam na preparação e continuam sendo
	# propriedade do jogador. Exclui cópias vendidas/consumidas aguardando liberação.
	for unit in get_tree().get_nodes_in_group("player_units"):
		if not (unit is BaseUnit3D) or unit.is_queued_for_deletion() or not unit.stats:
			continue
		var unit_id: String = unit.stats.unit_id
		if not counts.has(unit_id):
			counts[unit_id] = [0, 0, 0, 0, 0]
		counts[unit_id][clampi(unit.star_level, 1, 4)] += 1
	shop_ui.set_owned_star_counts(counts, combat_active or round_resolution_pending)

func _update_round_label() -> void:
	if not ui:
		return
	var round_label := ui.get_node_or_null("Control/TopBar/RoundLabel") as Label
	if not round_label:
		return
	if combat_active:
		round_label.text = "LUTA · R%d · %02ds" % [current_round, ceili(battle_time_remaining)]
	elif round_resolution_pending:
		round_label.text = "RESULTADO · R%d" % (current_round - 1)
	else:
		round_label.text = "PREP · R%d" % current_round

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
	if not shop_system:
		return
	if event.is_action_pressed("ui_accept"):
		if not combat_active:
			start_combat()
	
	if event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_S:
				_sell_hovered_unit()

			KEY_R:
				_on_reroll_requested()
			
			KEY_L:
				_on_lock_toggled(not shop_system.is_shop_locked)
			
			KEY_Q:
				buy_xp()
			
			KEY_C:
				if OS.is_debug_build() and not combat_active and not round_resolution_pending:
					clear_board()
			
			KEY_ESCAPE:
				if drag_handler and drag_handler.is_dragging:
					drag_handler.cancel_drag()
					dragging_unit = null
					update_ui()
			KEY_H:
				if ui:
					ui.toggle_hud()
					ui_visible = ui.hud_visible
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_RIGHT:
			inspect_unit_at_mouse(event.position)

func buy_xp() -> void:
	if not shop_system or round_resolution_pending or player_level >= Progression.MAX_LEVEL:
		return
	if player_gold < shop_system.xp_cost:
		print("Gold insuficiente para XP!")
		return
	
	player_gold -= shop_system.xp_cost
	var previous_level := player_level
	var progress := Progression.gain_xp(player_level, player_xp, Progression.PURCHASE_XP)
	player_level = progress.x
	player_xp = progress.y
	if player_level != previous_level:
		_refresh_shop()
	
	update_ui()

func _grant_round_xp() -> void:
	var player_progress := Progression.gain_xp(player_level, player_xp, Progression.ROUND_XP)
	player_level = player_progress.x
	player_xp = player_progress.y
	var enemy_progress := Progression.gain_xp(enemy_level, enemy_xp, Progression.ROUND_XP)
	enemy_level = enemy_progress.x
	enemy_xp = enemy_progress.y

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
	panel.get_node("VBoxContainer/Name_label").text = stats.unit_name
	panel.get_node("VBoxContainer/Image_container").texture = stats.icon
	panel.get_node("VBoxContainer/Hp_label").text = "Vida: %s" %[str(stats.max_health)]
	panel.get_node("VBoxContainer/Mana_label").text = "Mana: %s" %[str(stats.max_mana)]
	panel.get_node("VBoxContainer/Range_label").text = "Distância" if stats.is_ranged else "Corpo a Corpo"
	panel.get_node("VBoxContainer/Type_label").text = "Físico" if stats.attack_damage == 0  else "Mágico"
	panel.get_node("VBoxContainer/Origins_label").text = "Origens: %s" % (" · ".join(stats.origins) if not stats.origins.is_empty() else "—")
	panel.get_node("VBoxContainer/Classes_label").text = "Classes: %s" % (" · ".join(stats.classes) if not stats.classes.is_empty() else "—")
	panel.get_node("VBoxContainer/Affinities_label").text = "Afinidades: %s" % (" · ".join(stats.affinities) if not stats.affinities.is_empty() else "—")
	var tween := create_tween()
	panel.position.x = get_viewport().get_visible_rect().size.x
	tween.tween_property(panel, "position:x", get_viewport().get_visible_rect().size.x - panel.size.x - 14.0, 0.3)

func hide_unit_inspector() -> void:
	ui.get_node("Control/RightBar").hide()


func get_board_unit_limit() -> int:
	return clampi(player_level, 1, Progression.MAX_LEVEL)
	

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
		if unit is BaseUnit3D and unit not in bench_units and unit.current_state == BaseUnit3D.State.DEAD:
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
