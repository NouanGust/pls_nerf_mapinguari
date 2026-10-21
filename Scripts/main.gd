extends Node3D

const Progression = preload("res://Scripts/Systems/level_progression.gd")
const Regions = preload("res://Scripts/Systems/region_rosters.gd")
const CampaignStore = preload("res://Scripts/Systems/campaign_store.gd")
const GameOverlay = preload("res://Scripts/UI/game_overlay.gd")
const BattleTransition = preload("res://Scripts/UI/battle_transition.gd")

var entry_transition: BattleTransition
var _entry_in_progress: bool = false
var _overlay: GameOverlay
var _run_ready: bool = false
var _save_pending: bool = false
var _leaving: bool = false
var _load_failed: bool = false
var _campaign_state: String = "active"
var _save_warning: Label

@export_enum("cerrado", "pantanal", "amazonia", "caatinga", "mata_atlantica", "litoral") var region_id: String = "cerrado"
var enemy_level: int = 1

## Referências
@onready var board: Board3D = $board
@onready var camera: GameCamera = $Node3D
@onready var ui = $GameUi
@onready var nav_region: NavigationRegion3D = $NavigationRegion3D
@onready var bench_ui: BenchUI = $GameUi/Control/BenchPanel/BenchContent/BenchSlots
var ui_visible: bool = true

## Sistemas
var shop_system: ShopSystem
var shop_ui: ShopUI
var drag_handler: BoardDragHandler
var synergy_system: SynergySystem


## Estado do jogador
var player_gold: int = 3
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
@export_range(1.0, 10.0, 0.25) var stationary_stalemate_seconds: float = 3.0
@export var win_streak_bonus_step: int = 1
@export var max_win_streak_bonus: int = 5
@export var max_loss_streak_bonus: int = 5

var win_streak: int = 0
var loss_streak: int = 0
var round_outcomes: Dictionary = {}

func _ready() -> void:
	get_tree().auto_accept_quit = false
	if is_instance_valid(entry_transition):
		_entry_in_progress = true
		ui.hide()
		camera.entry_active = true
	print("\n" + "=".repeat(50))
	print("FOLCHESS - PROTÓTIPO")
	print("=".repeat(50) + "\n")
	
	UnitSpawner.clear_cache()
	UnitSpawner.load_all_units()
	UnitSpawner.print_all_units()
	UnitSpawner.get_all_unit_info()
	BiodiversityModels.preload_all_models()
	
	await get_tree().process_frame
	
	# Configurar board
	if board:
		board.apply_region_environment(region_id)
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
	if _entry_in_progress:
		drag_handler.set_process_input(false)
	_setup_pause_menu()
	var slot := CampaignStore.read_slot(region_id)
	if slot.has("error"):
		_load_failed = true
		_open_pause()
		_overlay.show_error(str(slot["error"]) + " Volte ao menu; o arquivo não será alterado.")
		await _dismiss_entry_on_error()
		return
	if slot.get("state", "") == "active":
		if not _restore_campaign(slot["run"]):
			_load_failed = true
			_open_pause()
			_overlay.show_error("Não foi possível restaurar as unidades. Volte ao menu; o arquivo foi preservado.")
			await _dismiss_entry_on_error()
			return
	else:
		spawn_enemy_team()
	_run_ready = true
	update_ui()
	_save_campaign()
	if _entry_in_progress:
		await _play_battle_entry(not slot.is_empty() or current_round > 1)
	
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

func _play_battle_entry(returning_to_region: bool) -> void:
	var focus_unit: Node3D = null
	if returning_to_region:
		var candidates: Array[Node3D] = []
		for unit in board.get_all_units():
			if unit is BaseUnit3D and not unit.is_queued_for_deletion() and unit.current_state != BaseUnit3D.State.DEAD:
				candidates.append(unit)
		if not candidates.is_empty():
			focus_unit = candidates.pick_random()
	await camera.play_entry(focus_unit, entry_transition.reveal)
	_finish_battle_entry()

func _dismiss_entry_on_error() -> void:
	if not is_instance_valid(entry_transition):
		return
	# Erros de carregamento precisam deixar o menu de recuperação acessível.
	await entry_transition.reveal()
	_finish_battle_entry()

func _finish_battle_entry() -> void:
	camera.entry_active = false
	_entry_in_progress = false
	ui.show()
	if is_instance_valid(drag_handler):
		drag_handler.set_process_input(true)
	if is_instance_valid(entry_transition):
		entry_transition.queue_free()
	entry_transition = null
	get_viewport().gui_release_focus()

func spawn_enemy_team() -> void:
	enemy_level = int(Regions.get_enemy_stage(current_round)["level"])
	for old_enemy in get_tree().get_nodes_in_group("enemy_units"):
		if old_enemy is BaseUnit3D and board.get_unit_at(old_enemy.board_position) == old_enemy:
			board.remove_unit(old_enemy.board_position)
		old_enemy.remove_from_group("enemy_units")
		old_enemy.queue_free()
	board.clear_enemy_zone()
	for slot in Regions.get_formation_for_round(region_id, current_round):
		var target_cell: Vector2i = slot["position"]
		if board.is_cell_occupied(target_cell):
			board.remove_unit(target_cell)
		var enemy := UnitSpawner.spawn_unit(str(slot["unit_id"]), int(slot["stars"]), 1)
		if enemy:
			enemy.use_navigation = false
			enemy.debug_movement = false
			add_child(enemy)
			if not board.place_unit(enemy, target_cell, false):
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
	drag_handler.drag_finished.connect(func() -> void: update_ui.call_deferred())
	
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
		AudioManager.play_move_unit()
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
		AudioManager.play_fail()
		print("Gold insuficiente! Precisa: %d, Tem: %d" % [unit_stats.cost, player_gold])
		return
	
	if not start_dragging and bench_units.size() >= max_bench_size:
		AudioManager.play_fail()
		print("Banco cheio! (%d/%d)" % [bench_units.size(), max_bench_size])
		return
	
	var purchased_unit: UnitStats = shop_system.purchase_unit(slot_index)
	if not purchased_unit:
		AudioManager.play_fail()
		return
	player_gold -= purchased_unit.cost
	AudioManager.play_buy()
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

func _on_unit_placed_on_board(unit: BaseUnit3D, grid_pos: Vector2i, source: String, _source_index: int) -> void:
	if combat_active or round_resolution_pending:
		if source == "bench":
			_realign_bench_units()
		elif source == "board":
			board.place_unit(unit, unit.board_position, true)
		else:
			player_gold += unit.stats.cost
			unit.queue_free()
		dragging_unit = null
		return

	if unit.team == 0 and get_player_units_on_board_count() >= get_board_unit_limit():
		AudioManager.play_fail()
		print("Limite atingido")
		if source == "bench":
			_realign_bench_units()
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
		AudioManager.play_move_unit()
		unit.play_pending_star_upgrade_effect()
		if source == "bench":
			bench_units.erase(unit)
			_realign_bench_units()
		dragging_unit = null
		_resolve_unit_merges()
		update_ui()
	else:
		AudioManager.play_ui_cancel()
		if source == "bench":
			_realign_bench_units()
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
		AudioManager.play_fail()
		print("Gold insuficiente para reroll! Precisa: %d" % shop_system.reroll_cost)
		return
	
	player_gold -= shop_system.reroll_cost
	AudioManager.play_ui_click()
	_refresh_shop()
	update_ui()
	print("Loja rerolada! (-%dg)" % shop_system.reroll_cost)

func _on_lock_toggled(is_locked: bool) -> void:
	shop_system.lock_shop(is_locked)
	_schedule_save()

func _on_unit_purchased(unit_stats: UnitStats, cost: int) -> void:
	print("%s comprado por %dg!" % [unit_stats.unit_name, cost])

func add_unit_to_bench(unit: BaseUnit3D) -> bool:
	if not unit: return false
	
	if bench_units.size() >= max_bench_size:
		return false
	
	if board.get_unit_at(unit.board_position) == unit:
		board.remove_unit(unit.board_position)
		
	if not bench_units.has(unit):
		bench_units.append(unit)
	unit.visible = true
	unit.team = 0
	unit.debug_movement = false
	unit.use_navigation = false
	unit.rotation.y = 0.0
	_realign_bench_units()
	
	print("%s enviado para o banco (%d/%d)" % [unit.stats.unit_name, bench_units.size(), max_bench_size])
	return true

func _realign_bench_units(animate: bool = true) -> void:
	for i in bench_units.size():
		var u: BaseUnit3D = bench_units[i]
		if not is_instance_valid(u):
			continue
		u.visible = true
		u.team = 0
		u.board_position = Vector2i(i, -1)
		u.rotation.y = 0.0
		var target_pos := board.get_bench_slot_world_position(i)
		if animate and is_inside_tree():
			var tween := create_tween()
			tween.set_ease(Tween.EASE_OUT)
			tween.set_trans(Tween.TRANS_QUAD)
			tween.tween_property(u, "global_position", target_pos, 0.25)
		else:
			u.global_position = target_pos

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
		if survivor.star_level == 2:
			AudioManager.play_2_star_up()
		elif survivor.star_level >= 3:
			AudioManager.play_3_star_up()
		print("%s evoluiu para %d estrelas" % [survivor.stats.unit_name, survivor.star_level])

	_realign_bench_units()
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
	if team_id == 0:
		AudioManager.play_sinergy_activated()
	var stat_field := ""
	match str(synergy.get("category", "")):
		"Origem":
			stat_field = "origins"
		"Classe":
			stat_field = "classes"
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
	if bench_ui and bench_ui.is_visible_in_tree():
		var bench_index := bench_ui.get_unit_index_at(mouse_position)
		if bench_index >= 0 and bench_index < bench_units.size():
			_sell_unit(bench_units[bench_index], "bench")
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
		var hit_unit: BaseUnit3D = hit.collider
		var source := "bench" if bench_units.has(hit_unit) else "board"
		_sell_unit(hit_unit, source)

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
		_realign_bench_units()
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
	if not _run_ready or _entry_in_progress or combat_active or round_resolution_pending:
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
	var deadline_msec := BattleClock.now_msec() + int(maxf(battle_duration_seconds, 1.0) * 1000.0)
	var stalemate_since_msec: int = -1
	while combat_active:
		await get_tree().create_timer(0.25, false).timeout
		if not combat_active:
			return
		battle_time_remaining = maxf(float(deadline_msec - BattleClock.now_msec()) / 1000.0, 0.0)
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
		if _is_stationary_stalemate(player_units, enemy_units):
			if stalemate_since_msec < 0:
				stalemate_since_msec = BattleClock.now_msec()
			elif BattleClock.now_msec() - stalemate_since_msec >= int(stationary_stalemate_seconds * 1000.0):
				end_combat(false, true, "Unidades imóveis sem alcance entre os times")
				return
		else:
			stalemate_since_msec = -1

func _is_stationary_stalemate(player_units: Array, enemy_units: Array) -> bool:
	if player_units.is_empty() or enemy_units.is_empty():
		return false
	# Espera efeitos em andamento e exclui qualquer sobrevivente móvel.
	# O banco não participa: estas listas vêm apenas das unidades do tabuleiro.
	for candidate in player_units + enemy_units:
		var unit := candidate as BaseUnit3D
		if not unit.stats.is_stationary or unit.has_pending_combat_effects():
			return false
	for player_candidate in player_units:
		var player := player_candidate as BaseUnit3D
		for enemy_candidate in enemy_units:
			var enemy := enemy_candidate as BaseUnit3D
			# Basta um lado alcançar o outro para a luta continuar normalmente.
			if player.is_target_in_attack_range(enemy) or enemy.is_target_in_attack_range(player):
				return false
	return true

func end_combat(player_won: bool, is_draw: bool = false, draw_reason: String = "") -> void:
	if not combat_active:
		return
	combat_active = false
	round_resolution_pending = true
	battle_time_remaining = 0.0
	var finished_round := current_round
	# A vitória precisa ocorrer contra o nível 9, antes do XP deste resultado.
	var region_completed := player_won and not is_draw and enemy_level >= Progression.MAX_LEVEL
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
		round_outcomes[current_round] = false
	elif player_won:
		win_streak = mini(win_streak + 1, 5)
		loss_streak = 0
		AudioManager.play_win_streak(win_streak)
		
		var streak_bonus: int = clampi(win_streak, 1, max_win_streak_bonus)
		player_gold += gold_on_win + streak_bonus
		round_outcomes[current_round] = true
	else:
		loss_streak = mini(loss_streak + 1, 5)
		win_streak = 0
		AudioManager.play_loss_streak(loss_streak)
		
		var streak_bonus: int = clampi(loss_streak, 1, max_loss_streak_bonus)
		player_gold += gold_on_loss + streak_bonus
		player_health -= 10
		round_outcomes[current_round] = false
	# Todo resultado encerra um round, inclusive derrota e empate.
	current_round += 1
	_grant_round_xp()
	revive_dead_player_units()
	update_ui()
	var is_game_over := player_health <= 0
	_campaign_state = "won" if region_completed else ("lost" if is_game_over else "active")
	_save_campaign()
	# Uma camada própria mantém inclusive cartas com z_index acima do HUD
	# atrás do relatório. O menu de pausa continua acima, na camada 100.
	var report_layer := CanvasLayer.new()
	report_layer.name = "CombatReportLayer"
	report_layer.layer = 50
	add_child(report_layer)
	var report := CombatReport.new()
	report_layer.add_child(report)
	report.show_report(finished_round, player_won, _get_combat_report_data(), is_draw, draw_reason)
	if is_game_over or region_completed:
		report.set_return_to_menu(region_completed)
	await report.continue_requested
	report_layer.queue_free()

	if is_game_over or region_completed:
		_leave_game(false)
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
				unit.current_shield = 0.0
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
	
	ui.update_player_stats(player_gold, player_health, player_level, player_xp, Progression.required_xp(player_level))
	ui.update_enemy_level(enemy_level)
	ui.update_board_capacity(get_player_units_on_board_count(), get_board_unit_limit())
	_update_round_label()
	
	var region_label := ui.get_node_or_null("Control/RegionLabel") as Label
	if region_label:
		var shown_round := maxi(1, current_round - 1) if round_resolution_pending else current_round
		var next_stage := Regions.get_next_enemy_stage(shown_round)
		var progress_text := "DESAFIO FINAL" if next_stage.is_empty() else "Próximo marco R%d" % int(next_stage["round"])
		region_label.text = "%s · Inimigo nível %d · %s" % [Regions.get_region(region_id)["name"], enemy_level, progress_text]
		var stage := Regions.get_enemy_stage(shown_round)
		var stars_text: Array[String] = []
		for stars in stage["stars"]:
			stars_text.append("%d★" % int(stars))
		region_label.tooltip_text = "Estrelas por vaga: %s\nFormação: %s\nO inimigo evolui por marcos de round, sem XP." % [
			" · ".join(stars_text), Regions.FORMATION_NAMES[Regions.get_formation_index(region_id, shown_round)]]
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
	_schedule_save()

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
	ui.update_round_display(current_round, combat_active, battle_time_remaining, round_resolution_pending, round_outcomes)

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
	if _entry_in_progress:
		get_viewport().set_input_as_handled()
		return
	if not _run_ready or _leaving or not shop_system or (_overlay and _overlay.is_open):
		return
	if round_resolution_pending:
		if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_ESCAPE:
			_open_pause()
			get_viewport().set_input_as_handled()
		return
	# Consome pressão, repetição e soltura antes de o botão focado receber
	# ui_accept. Enter continua disponível para navegação na interface.
	if event is InputEventKey and event.keycode == KEY_SPACE:
		get_viewport().set_input_as_handled()
		if event.pressed and not event.echo and not combat_active:
			start_combat()
		return
	
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
				else:
					_open_pause()
				get_viewport().set_input_as_handled()
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
		AudioManager.play_fail()
		print("Gold insuficiente para XP!")
		return
	
	player_gold -= shop_system.xp_cost
	AudioManager.play_ui_click()
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
	var camera_3d: Camera3D = null
	if camera:
		camera_3d = camera.get_node_or_null("Camera3D") as Camera3D
	if not camera_3d:
		camera_3d = get_viewport().get_camera_3d()
	if not camera_3d:
		return
	
	var from := camera_3d.project_ray_origin(mouse_pos)
	var to := from + camera_3d.project_ray_normal(mouse_pos) * 1000.0
	var query := PhysicsRayQueryParameters3D.create(from, to)
	query.collision_mask = 1
	
	var result := get_world_3d().direct_space_state.intersect_ray(query)
	
	if result and result.collider is BaseUnit3D:
		show_unit_inspector(result.collider)
	else:
		hide_unit_inspector()

func show_unit_inspector(unit: BaseUnit3D) -> void:
	if not is_instance_valid(unit) or not unit.stats or not ui:
		return
	var panel := ui.get_node_or_null("Control/RightBar")
	if not panel:
		return
	var stats := unit.stats
	
	var name_lbl = panel.find_child("Name_label", true, false)
	if name_lbl:
		name_lbl.text = "[b]%s[/b] %s (Tier %d)" % [stats.unit_name, "★".repeat(unit.star_level), stats.tier]
	
	var img = panel.find_child("Image_container", true, false) as TextureRect
	if img:
		img.texture = stats.icon
	
	var hp_lbl = panel.find_child("Hp_label", true, false)
	if hp_lbl:
		hp_lbl.text = "Vida: [color=#2ecc71]%d[/color] / %d" % [int(unit.current_health), int(unit.get_max_health())]
	
	var mana_lbl = panel.find_child("Mana_label", true, false)
	if mana_lbl:
		mana_lbl.text = "Mana: [color=#3498db]%d[/color] / %d" % [int(unit.current_mana), int(stats.max_mana)]
	
	var range_lbl = panel.find_child("Range_label", true, false)
	if range_lbl:
		range_lbl.text = "Alcance: %s (%d hexes)" % ["À Distância" if stats.is_ranged else "Corpo a Corpo", stats.get_attack_range_hexes()]
	
	var type_lbl = panel.find_child("Type_label", true, false)
	if type_lbl:
		type_lbl.text = "Ataque: [color=#e67e22]%d[/color] (%s)" % [int(unit.get_attack_damage()), "Físico" if stats.ability_damage_type == 0 else "Mágico"]
	
	var origins_lbl = panel.find_child("Origins_label", true, false)
	if origins_lbl:
		origins_lbl.text = "Origens: [color=#f1c40f]%s[/color]" % (" · ".join(stats.origins) if not stats.origins.is_empty() else "—")
	
	var classes_lbl = panel.find_child("Classes_label", true, false)
	if classes_lbl:
		classes_lbl.text = "Classes: [color=#9b59b6]%s[/color]" % (" · ".join(stats.classes) if not stats.classes.is_empty() else "—")
	
	var aff_lbl = panel.find_child("Affinities_label", true, false)
	if aff_lbl:
		aff_lbl.text = "Habilidade: [b]%s[/b]\n[color=#bdc3c7]%s[/color]" % [stats.ability_name, stats.ability_description]
	
	ui.show_inspector()

func hide_unit_inspector() -> void:
	if ui and ui.has_method("hide_inspector"):
		ui.hide_inspector()
	elif ui:
		var panel = ui.get_node_or_null("Control/RightBar")
		if panel:
			panel.hide()



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

# --- Pausa e campanhas independentes por região ---

func _setup_pause_menu() -> void:
	_overlay = GameOverlay.new()
	add_child(_overlay)
	_overlay.resume_requested.connect(_resume_game)
	_overlay.menu_requested.connect(_leave_game.bind(false))
	_overlay.quit_requested.connect(_leave_game.bind(true))
	var pause_button := GameOverlay.button("Pausa", _open_pause)
	pause_button.name = "PauseButton"
	pause_button.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	pause_button.offset_left = -210
	pause_button.offset_right = -80
	pause_button.offset_top = 16
	pause_button.offset_bottom = 68
	pause_button.tooltip_text = "Pausar (Esc)"
	pause_button.focus_mode = Control.FOCUS_NONE
	ui.add_child(pause_button)
	_save_warning = GameOverlay.label("", 18, Color("#ffbba0"))
	_save_warning.name = "SaveWarning"
	_save_warning.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	_save_warning.offset_top = 78
	_save_warning.offset_bottom = 110
	ui.add_child(_save_warning)
	ui._layout_extra_panels.call_deferred()

func _open_pause() -> void:
	if _leaving or not _overlay:
		return
	if drag_handler and drag_handler.is_dragging:
		drag_handler.cancel_drag()
		dragging_unit = null
	if camera:
		camera.cancel_manual_orbit()
	get_tree().paused = true
	_overlay.open("pause", true)

func _resume_game() -> void:
	if _load_failed:
		_overlay.open("pause", true)
		_overlay.show_error("Esta campanha não pôde ser carregada. Volte ao menu para preservar o arquivo.")
		return
	get_tree().paused = false
	get_viewport().gui_release_focus()

func _leave_game(quit_application: bool) -> void:
	if _leaving:
		return
	if drag_handler and drag_handler.is_dragging:
		drag_handler.cancel_drag()
		dragging_unit = null
	if _run_ready and not _save_campaign():
		_open_pause()
		_overlay.show_error("Não foi possível salvar. A partida continua aberta. Tente salvar novamente antes de sair.")
		return
	_leaving = true
	if quit_application:
		get_tree().quit()
	else:
		_return_to_menu.call_deferred()

func _return_to_menu() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file("res://Scenes/UI/Menu.tscn")

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		_leave_game(true)

func _schedule_save() -> void:
	if not _run_ready or _leaving or _save_pending:
		return
	_save_pending = true
	_flush_save.call_deferred()

func _flush_save() -> void:
	_save_pending = false
	if not is_inside_tree() or _leaving or not _run_ready:
		return
	if drag_handler and drag_handler.is_dragging:
		return
	_save_campaign()

func _unit_save_data(unit: BaseUnit3D) -> Dictionary:
	var pos := unit.board_position
	# Garantir que unidades de campo fiquem obrigatoriamente dentro da zona do jogador (linhas 4..7)
	if not unit.is_on_bench():
		if pos.y < 4 or pos.y >= 8 or pos.x < 0 or pos.x >= 7:
			for r in range(4, 8):
				for c in range(7):
					var candidate := Vector2i(c, r)
					if not board.is_cell_occupied(candidate):
						pos = candidate
						unit.board_position = pos
						break
				if pos.y >= 4:
					break
	return {
		"id": unit.stats.unit_id, "stars": unit.star_level,
		"invested": unit.invested_gold,
		"cell": [pos.x, pos.y],
	}

func _capture_campaign() -> Dictionary:
	var saved_bench: Array[Dictionary] = []
	var saved_field: Array[Dictionary] = []
	var saved_shop: Array[String] = []
	for unit in bench_units:
		if is_instance_valid(unit) and not unit.is_queued_for_deletion():
			saved_bench.append(_unit_save_data(unit))
	# Inclui combatentes mortos: continuam pertencendo ao jogador, com sua casa inicial.
	var field_positions: Array[Vector2i] = []
	for unit in get_tree().get_nodes_in_group("player_units"):
		if unit is BaseUnit3D and unit not in bench_units and not unit.is_queued_for_deletion():
			var data := _unit_save_data(unit)
			var cell := Vector2i(int(data["cell"][0]), int(data["cell"][1]))
			# Evitar posições duplicadas no save
			if cell in field_positions or cell.y < 4 or cell.y >= 8 or cell.x < 0 or cell.x >= 7:
				for r in range(4, 8):
					for c in range(7):
						var candidate := Vector2i(c, r)
						if candidate not in field_positions:
							cell = candidate
							data["cell"] = [cell.x, cell.y]
							unit.board_position = cell
							break
					if cell not in field_positions:
						break
			field_positions.append(cell)
			saved_field.append(data)
	if shop_system and shop_system.current_units:
		for stats in shop_system.current_units:
			saved_shop.append(stats.unit_id if stats else "")
	while saved_shop.size() < 5:
		saved_shop.append("")
	if saved_shop.size() > 5:
		saved_shop.resize(5)
	
	var effective_level: int = clampi(maxi(player_level, saved_field.size()), 1, 9)
	return {
		"gold": player_gold, "health": player_health, "level": effective_level,
		# Campos legados preservam a compatibilidade do formato do save.
		"xp": player_xp, "enemy_level": int(Regions.get_enemy_stage(current_round)["level"]), "enemy_xp": 0,
		"round": current_round, "win_streak": win_streak, "loss_streak": loss_streak,
		"phase": "combat" if combat_active else ("resolved" if round_resolution_pending else "prep"),
		"bench": saved_bench, "field": saved_field, "shop": saved_shop,
		"locked": shop_system.is_shop_locked if shop_system else false,
	}

func _save_campaign() -> bool:
	if not _run_ready or _load_failed:
		return false
	if drag_handler and drag_handler.is_dragging:
		return false
	var result := CampaignStore.write_slot(region_id, _capture_campaign(), _campaign_state)
	if _save_warning:
		_save_warning.text = "" if result == OK else "Não foi possível salvar a campanha. Use Pausa para tentar novamente antes de sair."
	if result != OK:
		push_warning("Falha ao salvar campanha %s: %s" % [region_id, error_string(result)])
	return result == OK

func _restore_campaign(run: Dictionary) -> bool:
	player_gold = int(run["gold"])
	player_health = int(run["health"])
	player_level = int(run["level"])
	player_xp = int(run["xp"])
	current_round = int(run["round"])
	# Saves antigos passam a usar o marco correspondente ao round salvo.
	enemy_level = int(Regions.get_enemy_stage(current_round)["level"])
	win_streak = int(run["win_streak"])
	loss_streak = int(run["loss_streak"])
	for zone in ["field", "bench"]:
		for entry in run[zone]:
			var unit := UnitSpawner.spawn_unit(str(entry["id"]), int(entry["stars"]), 0)
			if not unit:
				return false
			unit.use_navigation = false
			unit.debug_movement = false
			add_child(unit)
			unit.invested_gold = int(entry["invested"])
			if zone == "bench":
				if not add_unit_to_bench(unit):
					return false
			else:
				var cell := Vector2i(int(entry["cell"][0]), int(entry["cell"][1]))
				if not board.place_unit(unit, cell, false):
					return false
	shop_system.current_units.clear()
	for id in run["shop"]:
		shop_system.current_units.append(UnitSpawner.load_unit_stats(id) if id != "" else null)
	shop_system.lock_shop(bool(run["locked"]))
	shop_system.shop_refreshed.emit(shop_system.current_units)
	if run["phase"] == "resolved":
		# Recompensas e XP já foram gravados; só prepara o próximo round.
		prepare_next_round()
	else:
		# Uma luta interrompida volta à preparação, sem premiar nem penalizar.
		_resolve_unit_merges()
		spawn_enemy_team()
	_realign_bench_units(false)
	return true
