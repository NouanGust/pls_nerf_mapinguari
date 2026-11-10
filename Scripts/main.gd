extends Node3D

const UnitInspectorPanel = preload("res://Scripts/UI/unit_inspector_panel.gd")

const Progression = preload("res://Scripts/Systems/level_progression.gd")
const Regions = preload("res://Scripts/Systems/region_rosters.gd")
const CampaignStore = preload("res://Scripts/Systems/campaign_store.gd")
const GameOverlay = preload("res://Scripts/UI/game_overlay.gd")
const BattleTransition = preload("res://Scripts/UI/battle_transition.gd")
const DebugConsole = preload("res://Scripts/UI/debug_console.gd")

@export var debug_console_enabled: bool = true
var debug_console: DebugConsole
var _combat_generation: int = 0

var entry_transition: BattleTransition
var _entry_in_progress: bool = false
const CampaignSession = preload("res://Scripts/Systems/campaign_session.gd")
var campaign_session: CampaignSession = CampaignSession.new()

var _overlay: GameOverlay:
	get: return campaign_session.overlay if campaign_session else null
	set(val):
		if campaign_session: campaign_session.overlay = val
var _run_ready: bool = false
var _save_pending: bool:
	get: return campaign_session.save_pending if campaign_session else false
	set(val):
		if campaign_session: campaign_session.save_pending = val
var _leaving: bool:
	get: return campaign_session.leaving if campaign_session else false
	set(val):
		if campaign_session: campaign_session.leaving = val
var _load_failed: bool:
	get: return campaign_session.load_failed if campaign_session else false
	set(val):
		if campaign_session: campaign_session.load_failed = val
var _campaign_state: String:
	get: return campaign_session.campaign_state if campaign_session else "active"
	set(val):
		if campaign_session: campaign_session.campaign_state = val
var _save_warning: Label:
	get: return campaign_session.save_warning if campaign_session else null
	set(val):
		if campaign_session: campaign_session.save_warning = val

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
var _player_gold_fallback: int = 3
var _win_streak_fallback: int = 0
var _loss_streak_fallback: int = 0
var _economy_cached: Node = null

var economy: Node:
	get:
		if not is_instance_valid(_economy_cached):
			_economy_cached = get_node_or_null("/root/EconomyManager")
		return _economy_cached

var player_gold: int:
	get:
		return economy.player_gold if is_instance_valid(economy) else _player_gold_fallback
	set(val):
		if is_instance_valid(economy):
			economy.set_gold(val)
		else:
			_player_gold_fallback = val

var win_streak: int:
	get:
		return economy.win_streak if is_instance_valid(economy) else _win_streak_fallback
	set(val):
		if is_instance_valid(economy):
			economy.win_streak = val
		else:
			_win_streak_fallback = val

var loss_streak: int:
	get:
		return economy.loss_streak if is_instance_valid(economy) else _loss_streak_fallback
	set(val):
		if is_instance_valid(economy):
			economy.loss_streak = val
		else:
			_loss_streak_fallback = val

var player_health: int = 100
var player_level: int = 1
var player_xp: int = 0
var current_round: int = 1
var combat_active: bool = false
var round_resolution_pending: bool = false

## Unidades do jogador
const BenchManager = preload("res://Scripts/Systems/bench_manager.gd")
var bench_manager: BenchManager = BenchManager.new()
var bench_units: Array[BaseUnit3D]:
	get: return bench_manager.bench_units
	set(val): bench_manager.bench_units = val
var max_bench_size: int:
	get: return bench_manager.max_bench_size
	set(val): bench_manager.max_bench_size = val
var dragging_unit: BaseUnit3D = null
const CombatCoordinator = preload("res://Scripts/Systems/combat_coordinator.gd")
var combat_coordinator: CombatCoordinator = CombatCoordinator.new()
var combat_report_entries: Dictionary:
	get: return combat_coordinator.combat_report_entries
	set(val): combat_coordinator.combat_report_entries = val
var active_synergies: Dictionary = {}
var battle_time_remaining: float = 0.0
var cutscene_in_progress: bool = false
var match_elapsed_seconds: float = 0.0
var _ability_floating_card: PanelContainer = null
var _inspected_unit: BaseUnit3D = null

func _process(delta: float) -> void:
	if not get_tree().paused and _run_ready:
		match_elapsed_seconds += delta
	if is_instance_valid(_inspected_unit) and ui:
		var panel := ui.get_node_or_null("Control/RightBar") as Control
		if panel and panel.visible:
			_update_inspector_live_data(panel, _inspected_unit)


@export var gold_on_win: int = 2
@export var gold_on_loss: int = 1
@export var gold_on_draw: int = 1
@export var round_transition_seconds: float = 2.5
@export var battle_duration_seconds: float = 60.0
@export_range(1.0, 10.0, 0.25) var stationary_stalemate_seconds: float = 3.0
@export var win_streak_bonus_step: int = 1
@export var max_win_streak_bonus: int = 3
@export var max_loss_streak_bonus: int = 3

func calculate_streak_bonus(streak: int) -> int:
	if is_instance_valid(economy):
		return economy.calculate_streak_bonus(streak)
	if streak >= 5: return 3
	elif streak >= 3: return 2
	elif streak >= 1: return 1
	return 0

func calculate_interest(gold: int = -1) -> int:
	if is_instance_valid(economy):
		return economy.calculate_interest(gold)
	var g := player_gold if gold < 0 else gold
	return clampi(int(g / 10), 0, 5)

var round_outcomes: Dictionary = {}

func _ready() -> void:
	campaign_session.setup(self)
	combat_coordinator.setup(self)
	get_tree().auto_accept_quit = false
	if is_instance_valid(entry_transition):
		_entry_in_progress = true
		ui.hide()
		camera.entry_active = true
	_bind_ui_signals()
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
		print("\nBoard hexagonal pronto: %d x %d\n" % [board.rows, board.columns])
	AudioManager.play_region_music(region_id)
	
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
	if debug_console_enabled:
		debug_console = DebugConsole.new()
		debug_console.game = self
		add_child(debug_console)
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
		if is_instance_valid(economy):
			economy.reset_game(economy.starting_gold)
		else:
			_player_gold_fallback = 3
			_win_streak_fallback = 0
			_loss_streak_fallback = 0
		player_gold = economy.starting_gold if is_instance_valid(economy) else 3
		win_streak = 0
		loss_streak = 0
		current_round = 1
		player_health = 100
		player_level = 1
		player_xp = 0
		spawn_enemy_team()
	_update_round_atmosphere(0.0)
	_run_ready = true
	var gs: Node = get_node_or_null("/root/GameSettings")
	if gs and gs.has_method("set_last_played_region"):
		gs.set_last_played_region(region_id)
	update_ui()
	_save_campaign()
	if _entry_in_progress:
		await _play_battle_entry(not slot.is_empty() or current_round > 1)
	if is_boss_round() and not _load_failed:
		_play_boss_cutscene()
	
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
	
	_bind_ui_signals()

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
	if not unit:
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
	if drag_handler and drag_handler.is_dragging:
		return
	# Durante a luta ou resolução de round toda compra ocupa uma vaga do banco.
	if combat_active or round_resolution_pending:
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
	AudioManager.stop_evol_hint_shop()
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

func _on_unit_placed_on_board(unit: BaseUnit3D, grid_pos: Vector2i, source: String, source_index: int, old_pos: Vector2i = Vector2i(-1, -1)) -> void:
	if combat_active or round_resolution_pending:
		if source == "bench":
			_realign_bench_units()
		elif source == "board":
			board.place_unit(unit, unit.board_position, true)
		elif source == "shop":
			if not add_unit_to_bench(unit):
				player_gold += unit.stats.cost
				unit.queue_free()
			else:
				_resolve_unit_merges()
		dragging_unit = null
		update_ui()
		return

	# Troca de unidades (Swap): soltar sobre outra unidade aliada no tabuleiro ou do banco para o tabuleiro
	var occupant := board.get_unit_at(grid_pos) as BaseUnit3D
	if occupant != null and occupant != unit and occupant.team == 0 and source in ["board", "bench"]:
		var origin_pos := old_pos if old_pos != Vector2i(-1, -1) else unit.board_position
		if source == "board" and origin_pos != Vector2i(-1, -1):
			board.remove_unit(grid_pos)
			board.place_unit(unit, grid_pos, true)
			board.place_unit(occupant, origin_pos, true)
			AudioManager.play_place_unit(unit.stats.tier if unit.stats else 1)
			unit.play_pending_star_upgrade_effect()
			dragging_unit = null
			_resolve_unit_merges()
			update_ui()
			return
		elif source == "bench":
			board.remove_unit(grid_pos)
			board.place_unit(unit, grid_pos, true)
			unit.visible = true
			bench_units.erase(unit)
			if source_index >= 0 and source_index <= bench_units.size():
				bench_units.insert(source_index, occupant)
			else:
				bench_units.append(occupant)
			occupant.board_position = Vector2i(-1, -1)
			_realign_bench_units(true)
			AudioManager.play_place_unit(unit.stats.tier if unit.stats else 1)
			unit.play_pending_star_upgrade_effect()
			dragging_unit = null
			_resolve_unit_merges()
			update_ui()
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
			elif source == "shop":
				if not add_unit_to_bench(unit):
					player_gold += unit.stats.cost
					unit.queue_free()
				else:
					_resolve_unit_merges()
		dragging_unit = null
		update_ui()
		return
		
	unit.visible = true
	
	var success: bool = board.place_unit(unit, grid_pos, true)
	
	if success:
		AudioManager.play_place_unit(unit.stats.tier if unit.stats else 1)
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
		elif source == "shop":
			if not add_unit_to_bench(unit):
				player_gold += unit.stats.cost
				unit.queue_free()
			else:
				_resolve_unit_merges()
		dragging_unit = null
		update_ui()
	

func _on_reroll_requested() -> void:
	if player_gold < shop_system.reroll_cost:
		AudioManager.play_fail()
		print("Gold insuficiente para reroll! Precisa: %d" % shop_system.reroll_cost)
		return
	
	player_gold -= shop_system.reroll_cost
	AudioManager.play_ui_click()
	AudioManager.stop_evol_hint_shop()
	_refresh_shop()
	update_ui()
	print("Loja rerolada! (-%dg)" % shop_system.reroll_cost)

func _on_reroll_button_pressed() -> void:
	_on_reroll_requested()

func _on_lock_toggled(is_locked: bool) -> void:
	shop_system.lock_shop(is_locked)
	_schedule_save()


func _on_unit_purchased(unit_stats: UnitStats, cost: int) -> void:
	print("%s comprado por %dg!" % [unit_stats.unit_name, cost])

func add_unit_to_bench(unit: BaseUnit3D) -> bool:
	return bench_manager.add_unit(unit, board)

func _realign_bench_units(animate: bool = true) -> void:
	bench_manager.realign_units(board, animate)

func _resolve_unit_merges() -> void:
	if combat_active or round_resolution_pending:
		return
	bench_manager.resolve_merges(board)
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
func _auto_deploy_bench_units() -> void:
	bench_manager.auto_deploy(board, get_board_unit_limit(), get_player_units_on_board_count())
	_resolve_unit_merges()
	update_ui()

func is_boss_round() -> bool:
	if current_round % 5 == 0:
		return true
	if not is_inside_tree() or not get_tree():
		return false
	for enemy in get_tree().get_nodes_in_group("enemy_units"):
		if enemy is BaseUnit3D and (enemy.star_level >= 3 or (enemy.stats and enemy.stats.tier >= 5)):
			return true
	return false

func _update_round_atmosphere(duration: float = 1.2) -> void:
	if not board:
		return
	var target_env: WorldEnvironment = board.get_node_or_null("WorldEnvironment")
	if not target_env and board.get_parent():
		target_env = board.get_parent().get_node_or_null("WorldEnvironment")
	if not target_env:
		target_env = board.find_child("WorldEnvironment", true, false)
	var target_sun: DirectionalLight3D = board.get_node_or_null("DirectionalLight3D")
	if not target_sun and board.get_parent():
		target_sun = board.get_parent().find_child("DirectionalLight3D", true, false)

	# Ciclo de 5 rounds: (round 1 = 0.0 mais claro -> escurece e aproxima do rubro/vermelho até round 5 = 1.0 boss -> reinicia no round 6)
	var cycle_step: int = posmod(current_round - 1, 5)
	var cycle_prog: float = float(cycle_step) / 4.0
	if is_boss_round():
		cycle_prog = 1.0

	if is_boss_round():
		RegionEnvironment.apply_boss_atmosphere(target_env, target_sun, region_id, duration)
	else:
		board.apply_region_environment(region_id, duration, cycle_prog)

func _find_strongest_enemy() -> BaseUnit3D:
	if not is_inside_tree() or not get_tree():
		return null
	var enemies: Array = get_tree().get_nodes_in_group("enemy_units")
	var enemy_units: Array[BaseUnit3D] = []
	for e in enemies:
		if e is BaseUnit3D and is_instance_valid(e) and not e.is_queued_for_deletion():
			enemy_units.append(e)
	if enemy_units.is_empty():
		return null
	enemy_units.sort_custom(func(a: BaseUnit3D, b: BaseUnit3D) -> bool:
		var tier_a := a.stats.tier if a.stats else 1
		var tier_b := b.stats.tier if b.stats else 1
		if tier_a != tier_b:
			return tier_a > tier_b
		if a.star_level != b.star_level:
			return a.star_level > b.star_level
		var hp_a := a.get_max_health()
		var hp_b := b.get_max_health()
		return hp_a > hp_b
	)
	return enemy_units[0]

func _play_boss_cutscene() -> void:
	var boss := _find_strongest_enemy()
	if not is_instance_valid(boss):
		_update_round_atmosphere(1.5)
		return
	
	cutscene_in_progress = true
	if drag_handler:
		drag_handler.interaction_enabled = false
		drag_handler.board_interaction_enabled = false
	if ui and ui.start_battle_button:
		ui.start_battle_button.disabled = true

	# Ocultar lacaios temporariamente
	var minions: Array[BaseUnit3D] = []
	for e in get_tree().get_nodes_in_group("enemy_units"):
		if e is BaseUnit3D and is_instance_valid(e) and e != boss:
			e.visible = false
			minions.append(e)

	# Posicionar o chefe no alto para o impacto
	boss.visible = true
	if boss.ui_sprite:
		boss.ui_sprite.visible = false
	if boss.model:
		boss.model.position.y = 4.5

	var on_boss_land := func() -> void:
		if not is_instance_valid(boss):
			return
		if boss.model:
			var fall_tw := create_tween()
			fall_tw.tween_property(boss.model, "position:y", 0.0, 0.26).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
			await fall_tw.finished
			if not is_instance_valid(boss):
				return
			var squash_tw := create_tween()
			squash_tw.tween_property(boss.model, "scale", boss.model_base_scale * Vector3(1.4, 0.45, 1.4), 0.1).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
			squash_tw.tween_property(boss.model, "scale", boss.model_base_scale * Vector3(0.9, 1.25, 0.9), 0.14).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
			squash_tw.tween_property(boss.model, "scale", boss.model_base_scale, 0.14).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
		
		if camera and camera.has_method("shake"):
			camera.shake(0.65, 0.75)
		AudioManager.play_3_star_up()
		AudioManager.play_melee_hit()
		CombatFeedback.create_hit_particles(boss.global_position, Color("#ef4444"))
		CombatFeedback.create_hit_particles(boss.global_position + Vector3(0.6, 0.0, 0.0), Color("#f59e0b"))
		CombatFeedback.create_hit_particles(boss.global_position + Vector3(-0.6, 0.0, 0.0), Color("#f59e0b"))
		var boss_name: String = boss.stats.unit_name if boss.stats else "CHEFE"
		CombatFeedback.create_status_indicator(boss, "CHEFE: %s" % boss_name.to_upper(), 1.6)
		if boss.ui_sprite:
			boss.ui_sprite.visible = true

	var on_minions_enter := func() -> void:
		_update_round_atmosphere(1.4)
		for i in minions.size():
			var minion := minions[i]
			if not is_instance_valid(minion):
				continue
			get_tree().create_timer(i * 0.09).timeout.connect(func() -> void:
				if not is_instance_valid(minion):
					return
				minion.visible = true
				if minion.model:
					minion.model.position.y = 1.6
					var m_tw := create_tween()
					m_tw.tween_property(minion.model, "position:y", 0.0, 0.22).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
				CombatFeedback.create_hit_particles(minion.global_position, Color("#a855f7"))
			)

	if camera and camera.has_method("play_boss_sequence"):
		await camera.play_boss_sequence(boss, on_boss_land, on_minions_enter)
	else:
		on_boss_land.call()
		on_minions_enter.call()
	
	cutscene_in_progress = false
	if drag_handler:
		drag_handler.interaction_enabled = true
		drag_handler.board_interaction_enabled = true
	if ui and ui.start_battle_button:
		ui.start_battle_button.disabled = false
	update_ui()

func start_combat() -> void:
	if not _run_ready or _entry_in_progress or combat_active or round_resolution_pending or cutscene_in_progress:
		print("Combate já está ativo ou cutscene em andamento!")
		return
	if drag_handler and drag_handler.is_dragging:
		drag_handler.cancel_drag()
		dragging_unit = null
		update_ui()
	AudioManager.stop_evol_hint_shop()
	_auto_deploy_bench_units()
	_refresh_synergies()
	
	combat_active = true
	_combat_generation += 1
	battle_time_remaining = maxf(battle_duration_seconds, 1.0)
	if drag_handler:
		drag_handler.board_interaction_enabled = false
	update_ui()
	print("\n" + "=".repeat(50))
	print("COMBATE INICIADO!")
	print("=".repeat(50) + "\n")
	
	if is_boss_round():
		if camera and camera.has_method("shake"):
			camera.shake(0.2, 0.3)

	var units: Array = board.get_all_units()
	_capture_combat_roster(units)
	for unit in units:
		if unit is BaseUnit3D:
			unit.start_combat()
	
	# Monitorar fim do combate
	check_combat_end()

func _capture_combat_roster(units: Array) -> void:
	combat_coordinator.capture_roster(units)

func _on_combat_metric_recorded(unit: BaseUnit3D, metric: StringName, amount: float) -> void:
	combat_coordinator.on_metric_recorded(unit, metric, amount)

func check_combat_end() -> void:
	combat_coordinator.monitor_combat_loop(battle_duration_seconds, stationary_stalemate_seconds)

func _is_stationary_stalemate(player_units: Array, enemy_units: Array) -> bool:
	return combat_coordinator.is_stationary_stalemate(player_units, enemy_units)

func end_combat(player_won: bool, is_draw: bool = false, draw_reason: String = "", skip_report: bool = false) -> void:
	if not combat_active:
		return
	combat_active = false
	_combat_generation += 1
	round_resolution_pending = true
	battle_time_remaining = 0.0
	var finished_round := current_round
	# A vitória precisa ocorrer contra o nível 9, antes do XP deste resultado.
	var region_completed := player_won and not is_draw and enemy_level >= Progression.MAX_LEVEL
	# Congela todos os sobreviventes no resultado para que ninguém continue
	# atacando durante a tela do relatório ou enquanto o próximo round é preparado.
	var all_units_to_freeze: Array = []
	for u in board.get_all_units():
		if is_instance_valid(u) and not all_units_to_freeze.has(u):
			all_units_to_freeze.append(u)
	if is_inside_tree():
		for u in get_tree().get_nodes_in_group("units"):
			if is_instance_valid(u) and not all_units_to_freeze.has(u):
				all_units_to_freeze.append(u)
	for unit in all_units_to_freeze:
		if not (unit is BaseUnit3D) or unit.current_state == BaseUnit3D.State.DEAD:
			continue
		if unit.attack_timer:
			unit.attack_timer.stop()
		unit.current_target = null
		unit.current_state = BaseUnit3D.State.IDLE
		unit.velocity = Vector3.ZERO
		unit.in_combat = false
		unit._was_stunned = false
		unit.stunned_until_msec = 0
		unit.clear_shield()
	for b_unit in bench_units:
		if b_unit is BaseUnit3D:
			b_unit.clear_shield()
	if drag_handler:
		drag_handler.cancel_drag()
		dragging_unit = null
		drag_handler.interaction_enabled = false
	
	var earned_gold: int = 0
	var round_gold: int = 0
	var streak_bonus: int = 0
	var interest: int = 0
	var outcome_name: String = ""

	if is_instance_valid(economy):
		var econ_result: Dictionary = economy.resolve_round_economy(player_won, is_draw)
		earned_gold = econ_result["earned_gold"]
		round_gold = econ_result["round_gold"]
		streak_bonus = econ_result["streak_bonus"]
		interest = econ_result["interest"]
		outcome_name = econ_result["outcome_name"]
		if is_draw:
			player_health -= 5
			round_outcomes[current_round] = false
		elif player_won:
			AudioManager.play_win_streak(win_streak)
			round_outcomes[current_round] = true
		else:
			AudioManager.play_loss_streak(loss_streak)
			player_health -= 10
			round_outcomes[current_round] = false
	else:
		if is_draw:
			win_streak = 0
			loss_streak = 0
			round_gold = gold_on_draw
			streak_bonus = 0
			interest = calculate_interest(player_gold)
			earned_gold = round_gold + streak_bonus + interest
			player_gold += earned_gold
			player_health -= 5
			round_outcomes[current_round] = false
			outcome_name = "Empate"
		elif player_won:
			win_streak += 1
			loss_streak = 0
			AudioManager.play_win_streak(win_streak)
			streak_bonus = calculate_streak_bonus(win_streak)
			round_gold = gold_on_win
			interest = calculate_interest(player_gold)
			earned_gold = round_gold + streak_bonus + interest
			player_gold += earned_gold
			round_outcomes[current_round] = true
			outcome_name = "Vitória"
		else:
			loss_streak += 1
			win_streak = 0
			AudioManager.play_loss_streak(loss_streak)
			streak_bonus = calculate_streak_bonus(loss_streak)
			round_gold = gold_on_loss
			interest = calculate_interest(player_gold)
			earned_gold = round_gold + streak_bonus + interest
			player_gold += earned_gold
			player_health -= 10
			round_outcomes[current_round] = false
			outcome_name = "Derrota"
	# Todo resultado encerra um round, inclusive derrota e empate.
	current_round += 1
	_grant_round_xp()
	revive_dead_player_units()
	update_ui()
	
	# Exibir notificação / banner de rendimento na interface
	if ui and ui.has_method("show_round_resolution_banner"):
		ui.show_round_resolution_banner(outcome_name, earned_gold, is_draw, player_won, round_gold, streak_bonus, interest)
	
	# Pequeno tempo entre o fim de um round e o próximo para o jogador ver as moedas ganhas
	if round_transition_seconds > 0.0 and not skip_report:
		await get_tree().create_timer(round_transition_seconds, false).timeout
	var is_game_over := player_health <= 0
	_campaign_state = "won" if region_completed else ("lost" if is_game_over else "active")
	_save_campaign()
	if skip_report:
		if is_game_over or region_completed:
			_leave_game(false)
		else:
			prepare_next_round()
		return
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
	return combat_coordinator.get_report_data()

func prepare_next_round() -> void:
	print("preparando round")
	if drag_handler:
		drag_handler.cancel_drag()
	dragging_unit = null
	
	var player_units: Array = get_tree().get_nodes_in_group("player_units")
	for unit in player_units:
		if unit is BaseUnit3D and unit not in bench_units:
			board.remove_unit(unit.board_position)
	for unit in player_units:
		if unit is BaseUnit3D and unit not in bench_units:
			var home_pos = board.get_cell_world_position(unit.board_position)
		
			if unit.current_state == BaseUnit3D.State.DEAD:
				unit.revive_at_position(home_pos)
			else:
				unit.current_health = unit.get_max_health()
				unit.current_mana = unit.stats.starting_mana
				unit.clear_shield()
				unit.current_state = BaseUnit3D.State.IDLE
				unit.current_target = null
				unit.global_position = home_pos
				if unit.attack_timer:
					unit.attack_timer.stop()
				unit.update_health_bar()
				unit.update_mana_bar()
			board.place_unit(unit, unit.board_position, false)
			unit.in_combat = false
			unit.velocity = Vector3.ZERO

	for node in get_tree().get_nodes_in_group("units"):
		if node is BaseUnit3D:
			node.clear_shield()
				
	# Os sobreviventes já voltaram às casas e os mortos já foram restaurados.
	# Resolve também evoluções em cadeia antes de sortear a próxima loja.
	round_resolution_pending = false
	_resolve_unit_merges()
	if drag_handler:
		drag_handler.interaction_enabled = true
		drag_handler.board_interaction_enabled = true
	_refresh_shop()
	spawn_enemy_team()
	if is_boss_round():
		_play_boss_cutscene()
	else:
		_update_round_atmosphere(1.5)
	update_ui()
	print("Novo round")

func update_ui() -> void:
	if not ui:
		return
	
	ui.update_player_stats(player_gold, player_health, player_level, player_xp, Progression.required_xp(player_level))
	ui.update_enemy_level(enemy_level)
	ui.update_board_capacity(get_player_units_on_board_count(), get_board_unit_limit())
	_update_round_label()
	if ui.has_method("update_streak"):
		ui.update_streak(win_streak, loss_streak)
	
	var region_label := ui.get_node_or_null("Control/RegionLabel") as Label
	if region_label:
		var shown_round := maxi(1, current_round - 1) if round_resolution_pending else current_round
		var next_stage := Regions.get_next_enemy_stage(shown_round)
		var progress_text := "DESAFIO FINAL" if next_stage.is_empty() else "Próximo marco R%d" % int(next_stage["round"])
		region_label.text = "%s · Inimigo nível %d · %s" % [Regions.get_region(region_id)["name"], enemy_level, progress_text]
		var stage := Regions.get_enemy_stage(shown_round)
		var stars_text: Array[String] = []
		for stars in stage["stars"]:
			stars_text.append("%d Estrelas" % int(stars))
		region_label.tooltip_text = "Estrelas por vaga: %s\nFormação: %s\nO inimigo evolui por marcos de round, sem XP." % [
			" · ".join(stars_text), Regions.FORMATION_NAMES[Regions.get_formation_index(region_id, shown_round)]]
	var xp_button := ui.get_node_or_null("Control/BottomBar/ControlsContainer/BuyXPButton") as Button
	if xp_button and shop_system:
		xp_button.disabled = player_level >= Progression.MAX_LEVEL or player_gold < shop_system.xp_cost
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
	if debug_console and debug_console.is_open:
		return
	if _entry_in_progress:
		get_viewport().set_input_as_handled()
		return
	if not _run_ready or _leaving or not shop_system or (_overlay and _overlay.is_open):
		return
	# Consome pressão, repetição e soltura antes de o botão focado receber
	# ui_accept. Enter continua disponível para navegação na interface.
	if event is InputEventKey and event.keycode == KEY_SPACE:
		get_viewport().set_input_as_handled()
		if event.pressed and not event.echo and not combat_active and not round_resolution_pending and not cutscene_in_progress:
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
	if not shop_system or player_level >= Progression.MAX_LEVEL:
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
	if player_level > previous_level:
		AudioManager.play_player_level_up()
	# A loja não é mais rerrolada ao subir de nível
	
	update_ui()

func _grant_round_xp() -> void:
	var prev_lvl := player_level
	var player_progress := Progression.gain_xp(player_level, player_xp, Progression.ROUND_XP)
	player_level = player_progress.x
	player_xp = player_progress.y
	if player_level > prev_lvl:
		AudioManager.play_player_level_up()

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
	var panel := ui.get_node_or_null("Control/RightBar") as Control
	if not panel:
		return
	_inspected_unit = unit
	UnitInspectorPanel.show_inspector(unit, panel, ui)

func _update_inspector_live_data(panel: Control, unit: BaseUnit3D) -> void:
	UnitInspectorPanel.update_live_data(panel, unit)

var _highlighted_synergy_units: Array[BaseUnit3D] = []
var _highlighted_synergy_cells: Array[Vector2i] = []

func _bind_ui_signals() -> void:
	if ui:
		if ui.has_signal("synergy_hover_started") and not ui.synergy_hover_started.is_connected(highlight_units_with_synergy):
			ui.synergy_hover_started.connect(highlight_units_with_synergy)
		if ui.has_signal("synergy_hover_ended") and not ui.synergy_hover_ended.is_connected(clear_synergy_unit_highlights):
			ui.synergy_hover_ended.connect(clear_synergy_unit_highlights)
		if ui.has_signal("start_battle_requested") and not ui.start_battle_requested.is_connected(start_combat):
			ui.start_battle_requested.connect(start_combat)

func highlight_units_with_synergy(synergy_name: String) -> void:
	clear_synergy_unit_highlights()
	if synergy_name.is_empty() or not board:
		return
	for unit in board.get_all_units():
		if not is_instance_valid(unit) or not (unit is BaseUnit3D):
			continue
		if unit.team != 0 or unit.current_state == BaseUnit3D.State.DEAD or not unit.stats:
			continue
		var matches = unit.stats.origins.has(synergy_name)
		if matches:
			_highlighted_synergy_units.append(unit)
			unit.set_synergy_highlighted(true)
			if not unit.is_on_bench() and board.get_cell(unit.board_position):
				board.highlight_cell(unit.board_position, true, Color("#f59e0b"))
				_highlighted_synergy_cells.append(unit.board_position)
	
	for unit in bench_units:
		if is_instance_valid(unit) and unit.stats:
			var matches := unit.stats.origins.has(synergy_name)
			if matches:
				_highlighted_synergy_units.append(unit)
				unit.set_synergy_highlighted(true)

func clear_synergy_unit_highlights() -> void:
	for pos in _highlighted_synergy_cells:
		if is_instance_valid(board):
			board.highlight_cell(pos, false)
	_highlighted_synergy_cells.clear()
	for unit in _highlighted_synergy_units:
		if is_instance_valid(unit):
			unit.set_synergy_highlighted(false)
	_highlighted_synergy_units.clear()

func hide_unit_inspector() -> void:
	_inspected_unit = null
	clear_synergy_unit_highlights()
	if ui:
		var panel = ui.get_node_or_null("Control/RightBar") as Control
		UnitInspectorPanel.hide_inspector(panel, ui)



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
			unit.in_combat = false
			if unit.attack_timer:
				unit.attack_timer.stop()
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

func _setup_pause_menu() -> void: campaign_session.setup_pause_menu()
func _open_pause() -> void: campaign_session.open_pause()
func _resume_game() -> void: campaign_session.resume_game()
func _leave_game(quit_application: bool) -> void: campaign_session.leave_game(quit_application)
func _return_to_menu() -> void: campaign_session.return_to_menu()
func _schedule_save() -> void: campaign_session.schedule_save()
func _flush_save() -> void: campaign_session.flush_save()
func _unit_save_data(unit: BaseUnit3D) -> Dictionary: return campaign_session.unit_save_data(unit)
func _capture_campaign() -> Dictionary: return campaign_session.capture_campaign()
func _save_campaign() -> bool: return campaign_session.save_campaign()
func _restore_campaign(run: Dictionary) -> bool: return campaign_session.restore_campaign(run)

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		_leave_game(true)
