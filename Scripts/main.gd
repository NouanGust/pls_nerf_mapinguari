extends Node3D

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
@export var gold_on_draw: int = 0
@export var round_transition_seconds: float = 2.5
@export var battle_duration_seconds: float = 60.0
@export_range(1.0, 10.0, 0.25) var stationary_stalemate_seconds: float = 3.0
@export var win_streak_bonus_step: int = 1
@export var max_win_streak_bonus: int = 3
@export var max_loss_streak_bonus: int = 3

func calculate_streak_bonus(streak: int) -> int:
	if streak >= 5:
		return 3
	elif streak >= 3:
		return 2
	elif streak >= 1:
		return 1
	return 0

func calculate_interest(gold: int) -> int:
	return clampi(int(gold / 10), 0, 5)

var win_streak: int = 0
var loss_streak: int = 0
var round_outcomes: Dictionary = {}

func _ready() -> void:
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
	unit.set_hovered(false)
	unit._update_status_visibility()
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
		u._update_status_visibility()
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
func _auto_deploy_bench_units() -> void:
	if not board or bench_units.is_empty():
		return
	var free_slots := get_board_unit_limit() - get_player_units_on_board_count()
	if free_slots <= 0:
		return
	
	var free_cells: Array[Vector2i] = []
	for row in range(board.rows - 1, board.rows - board.player_rows - 1, -1):
		for col in range(board.columns):
			var cell := Vector2i(col, row)
			if not board.is_cell_occupied(cell):
				free_cells.append(cell)
	
	var deployed_count := 0
	while deployed_count < free_slots and not bench_units.is_empty() and not free_cells.is_empty():
		var unit: BaseUnit3D = bench_units.pop_front()
		if not is_instance_valid(unit):
			continue
		var target_cell: Vector2i = free_cells.pop_front()
		unit.visible = true
		unit.team = 0
		unit.use_navigation = true
		if not unit.is_in_group("player_units"):
			unit.add_to_group("player_units")
		if board.place_unit(unit, target_cell, true):
			unit.board_position = target_cell
			deployed_count += 1
		else:
			bench_units.push_front(unit)
			break
	
	if deployed_count > 0:
		_realign_bench_units(false)
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

	if is_boss_round():
		RegionEnvironment.apply_boss_atmosphere(target_env, target_sun, region_id, duration)
	else:
		board.apply_region_environment(region_id, duration)

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
	var generation := _combat_generation
	var deadline_msec := BattleClock.now_msec() + int(maxf(battle_duration_seconds, 1.0) * 1000.0)
	var stalemate_since_msec: int = -1
	while combat_active:
		await get_tree().create_timer(0.25, false).timeout
		if not combat_active or generation != _combat_generation:
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
	for unit in board.get_all_units():
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
	if drag_handler:
		drag_handler.cancel_drag()
		dragging_unit = null
		drag_handler.interaction_enabled = false
	
	var earned_gold: int = 0
	var round_gold: int = 0
	var streak_bonus: int = 0
	var interest: int = 0
	var outcome_name: String = ""
	if is_draw:
		win_streak = 0
		loss_streak = 0
		round_gold = gold_on_draw # 0
		streak_bonus = 0
		interest = 0 # Empate quebra a economia: 0 de juros e 0 de ouro
		earned_gold = 0
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
			board.remove_unit(unit.board_position)
	for unit in player_units:
		if unit is BaseUnit3D and unit not in bench_units:
			var home_pos = board.get_cell_world_position(unit.board_position)
		
			if unit.current_state == BaseUnit3D.State.DEAD:
				unit.revive_at_position(home_pos)
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
			board.place_unit(unit, unit.board_position, false)
			unit.in_combat = false
			unit.velocity = Vector3.ZERO
				
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

func _format_star_trio(v1: Variant, v2: Variant, v3: Variant, active_star: int, suffix: String = "", prefix: String = "") -> String:
	var s1 := "%s%s%s" % [prefix, str(v1), suffix]
	var s2 := "%s%s%s" % [prefix, str(v2), suffix]
	var s3 := "%s%s%s" % [prefix, str(v3), suffix]
	match active_star:
		1:
			s1 = "[b][color=#ffd16b]%s[/color][/b]" % s1
		2:
			s2 = "[b][color=#ffd16b]%s[/color][/b]" % s2
		3, 4:
			s3 = "[b][color=#ffd16b]%s[/color][/b]" % s3
	return "%s / %s / %s" % [s1, s2, s3]

func _get_or_create_inspector_label(panel: Node, label_name: String, insert_before_name: String = "") -> RichTextLabel:
	var lbl = panel.find_child(label_name, true, false) as RichTextLabel
	if not lbl:
		var vbox = panel.find_child("VBoxContainer", true, false)
		if vbox:
			lbl = RichTextLabel.new()
			lbl.name = label_name
			lbl.bbcode_enabled = true
			lbl.fit_content = true
			lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
			lbl.scroll_active = false
			if not insert_before_name.is_empty():
				var target_child = vbox.find_child(insert_before_name, false, false)
				if target_child:
					vbox.add_child(lbl)
					vbox.move_child(lbl, target_child.get_index())
					return lbl
			vbox.add_child(lbl)
	return lbl

func _get_or_create_ability_floating_card(control_parent: Control) -> PanelContainer:
	if is_instance_valid(_ability_floating_card):
		return _ability_floating_card
	
	var card := PanelContainer.new()
	card.name = "AbilityFloatingCard"
	card.top_level = true
	card.set_anchors_preset(Control.PRESET_TOP_LEFT)
	card.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	card.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	card.z_index = 35
	card.visible = false
	card.mouse_filter = Control.MOUSE_FILTER_PASS
	
	var card_style := StyleBoxFlat.new()
	card_style.bg_color = Color("#0f172a")
	card_style.border_color = Color("#8b5cf6")
	card_style.border_width_left = 2
	card_style.border_width_top = 2
	card_style.border_width_right = 2
	card_style.border_width_bottom = 2
	card_style.corner_radius_top_left = 8
	card_style.corner_radius_top_right = 8
	card_style.corner_radius_bottom_left = 8
	card_style.corner_radius_bottom_right = 8
	card_style.content_margin_left = 12
	card_style.content_margin_top = 10
	card_style.content_margin_right = 12
	card_style.content_margin_bottom = 10
	card_style.shadow_color = Color(0, 0, 0, 0.75)
	card_style.shadow_size = 12
	card.add_theme_stylebox_override("panel", card_style)
	
	var vbox := VBoxContainer.new()
	vbox.name = "CardVBox"
	vbox.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	vbox.add_theme_constant_override("separation", 6)
	card.add_child(vbox)
	
	control_parent.add_child(card)
	_ability_floating_card = card
	return card

func _hide_ability_floating_card() -> void:
	if is_instance_valid(_ability_floating_card):
		_ability_floating_card.visible = false

func _show_ability_floating_card(unit: BaseUnit3D, panel: Control) -> void:
	if not is_instance_valid(unit) or not unit.stats or not is_instance_valid(panel):
		return
	var card := _get_or_create_ability_floating_card(panel.get_parent() as Control)
	var vbox := card.get_node("CardVBox") as VBoxContainer
	for child in vbox.get_children():
		child.queue_free()
	
	var stats := unit.stats
	var star := clampi(unit.star_level, 1, 4)
	
	# 1. Header (Ícone + Nome da Habilidade + Custo de Mana + Tipo de Dano)
	var header_hbox := HBoxContainer.new()
	header_hbox.add_theme_constant_override("separation", 10)
	
	var icon_rect := TextureRect.new()
	icon_rect.texture = stats.icon
	icon_rect.custom_minimum_size = Vector2(34, 34)
	icon_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon_rect.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	header_hbox.add_child(icon_rect)
	
	var title_vbox := VBoxContainer.new()
	title_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_vbox.add_theme_constant_override("separation", 2)
	
	var name_lbl := Label.new()
	name_lbl.text = stats.ability_name
	name_lbl.add_theme_font_size_override("font_size", 13)
	name_lbl.add_theme_color_override("font_color", Color("#f8fafc"))
	title_vbox.add_child(name_lbl)
	
	var badges_hbox := HBoxContainer.new()
	badges_hbox.add_theme_constant_override("separation", 6)
	
	var dmg_type_str := "Mágico"
	var dmg_color := Color("#c084fc")
	match stats.ability_damage_type:
		UnitStats.DamageType.PHYSICAL:
			dmg_type_str = "Físico"
			dmg_color = Color("#fb923c")
		UnitStats.DamageType.MAGICAL:
			dmg_type_str = "Mágico"
			dmg_color = Color("#c084fc")
		UnitStats.DamageType.TRUE:
			dmg_type_str = "Verdadeiro"
			dmg_color = Color("#facc15")
			
	var type_badge := Label.new()
	type_badge.text = "[ %s ]" % dmg_type_str
	type_badge.add_theme_font_size_override("font_size", 10)
	type_badge.add_theme_color_override("font_color", dmg_color)
	badges_hbox.add_child(type_badge)
	
	if stats.max_mana > 0:
		var mana_badge := Label.new()
		mana_badge.text = "%d Mana" % int(stats.max_mana)
		mana_badge.add_theme_font_size_override("font_size", 10)
		mana_badge.add_theme_color_override("font_color", Color("#67e8f9"))
		badges_hbox.add_child(mana_badge)
		
	title_vbox.add_child(badges_hbox)
	header_hbox.add_child(title_vbox)
	vbox.add_child(header_hbox)
	
	# 2. Descrição Mecânica Clara da Habilidade
	var desc_lbl := RichTextLabel.new()
	desc_lbl.bbcode_enabled = true
	desc_lbl.fit_content = true
	desc_lbl.scroll_active = false
	desc_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	desc_lbl.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	desc_lbl.text = "[color=#cbd5e1]%s[/color]" % stats.get_mechanics_description(star)
	desc_lbl.custom_minimum_size = Vector2(256, 0)
	vbox.add_child(desc_lbl)
	
	# 3. Tabela de Escalonamento por Estrela (Scaling)
	var scaling_box := PanelContainer.new()
	scaling_box.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	var sc_style := StyleBoxFlat.new()
	sc_style.bg_color = Color("#1e1b4b66")
	sc_style.border_color = Color("#6366f1")
	sc_style.border_width_left = 1
	sc_style.border_width_top = 1
	sc_style.border_width_right = 1
	sc_style.border_width_bottom = 1
	sc_style.corner_radius_top_left = 6
	sc_style.corner_radius_top_right = 6
	sc_style.corner_radius_bottom_left = 6
	sc_style.corner_radius_bottom_right = 6
	sc_style.content_margin_left = 8
	sc_style.content_margin_top = 6
	sc_style.content_margin_right = 8
	sc_style.content_margin_bottom = 6
	scaling_box.add_theme_stylebox_override("panel", sc_style)
	
	var sc_vbox := VBoxContainer.new()
	sc_vbox.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	sc_vbox.add_theme_constant_override("separation", 3)
	
	var sc_title := Label.new()
	sc_title.text = "Escalonamento por Estrela (Verificado):"
	sc_title.add_theme_font_size_override("font_size", 10)
	sc_title.add_theme_color_override("font_color", Color("#a5b4fc"))
	sc_vbox.add_child(sc_title)
	
	var sc_lines: Array[String] = []
	var m1: float = stats.get_star_multiplier(1)
	var m2: float = stats.get_star_multiplier(2)
	var m3: float = stats.get_star_multiplier(3)
	
	if stats.ability_damage > 0.0:
		var d1 := int(stats.ability_damage * m1)
		var d2 := int(stats.ability_damage * m2)
		var d3 := int(stats.ability_damage * m3)
		var trio := _format_star_trio(d1, d2, d3, star)
		sc_lines.append("[color=#94a3b8]Dano Base:[/color] [ %s ]" % trio)
		
	if stats.ability_shield > 0.0:
		var s1 := int(stats.ability_shield * m1)
		var s2 := int(stats.ability_shield * m2)
		var s3 := int(stats.ability_shield * m3)
		var trio := _format_star_trio(s1, s2, s3, star)
		sc_lines.append("[color=#94a3b8]Escudo:[/color] [ %s ]" % trio)
		
	if stats.ability_heal > 0.0:
		var h1 := int(stats.ability_heal * m1)
		var h2 := int(stats.ability_heal * m2)
		var h3 := int(stats.ability_heal * m3)
		var trio := _format_star_trio(h1, h2, h3, star)
		sc_lines.append("[color=#94a3b8]Cura:[/color] [ %s ]" % trio)
		
	sc_lines.append("[color=#64748b]Multiplicadores: Nivel 1 (x1.0) · Nivel 2 (x1.8) · Nivel 3 (x2.6)[/color]")
	sc_lines.append("[color=#22c55e][ Escalonamento Ativo ][/color]")
	
	var sc_rtl := RichTextLabel.new()
	sc_rtl.bbcode_enabled = true
	sc_rtl.fit_content = true
	sc_rtl.scroll_active = false
	sc_rtl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	sc_rtl.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	sc_rtl.text = "\n".join(sc_lines)
	sc_vbox.add_child(sc_rtl)
	
	scaling_box.add_child(sc_vbox)
	vbox.add_child(scaling_box)
	
	card.custom_minimum_size = Vector2(280, 0)
	card.reset_size()
	
	var panel_rect: Rect2 = panel.get_global_rect()
	var tactical_row: Control = panel.find_child("TFT_TacticalRow", true, false) as Control
	var anchor_y: float = tactical_row.global_position.y if tactical_row else panel_rect.position.y + 120.0
	var card_x: float = panel_rect.position.x - card.size.x - 12.0
	var viewport_h: float = get_viewport().get_visible_rect().size.y
	var max_y: float = maxf(viewport_h - card.size.y - 12.0, 10.0)
	var card_y: float = clampf(anchor_y - 10.0, 10.0, max_y)
	card.global_position = Vector2(card_x, card_y)
	card.show()
	card.modulate.a = 0.0
	var tw := card.create_tween()
	tw.tween_property(card, "modulate:a", 1.0, 0.15)

func _update_tft_inspector(
	panel: Control,
	unit: BaseUnit3D,
	cur_hp: int,
	max_hp: int,
	cur_mana: int,
	max_mana: int,
	attack_dmg: int,
	attack_spd: float,
	dps: int,
	total_armor: float,
	phys_reduct: int,
	total_mr: float,
	mag_reduct: int
) -> void:
	var vbox := panel.find_child("VBoxContainer", true, false) as VBoxContainer
	if not vbox:
		return
	var stats := unit.stats
	var star := clampi(unit.star_level, 1, 4)

	# 1. BARRAS DE VIDA E MANA (Estilo TFT)
	var bars_container = vbox.find_child("TFT_BarsContainer", false, false) as VBoxContainer
	if not bars_container:
		bars_container = VBoxContainer.new()
		bars_container.name = "TFT_BarsContainer"
		bars_container.add_theme_constant_override("separation", 4)
		vbox.add_child(bars_container)
		var p_frame = vbox.find_child("PortraitFrame", false, false)
		if p_frame:
			vbox.move_child(bars_container, p_frame.get_index() + 1)

	# Barra de Vida
	var hp_bar = bars_container.find_child("InspectorHpBar", false, false) as ProgressBar
	var hp_label: Label = null
	if not hp_bar:
		hp_bar = ProgressBar.new()
		hp_bar.name = "InspectorHpBar"
		hp_bar.custom_minimum_size = Vector2(0, 18)
		hp_bar.show_percentage = false
		var hp_bg := StyleBoxFlat.new()
		hp_bg.bg_color = Color("#052e16")
		hp_bg.corner_radius_top_left = 3
		hp_bg.corner_radius_top_right = 3
		hp_bg.corner_radius_bottom_left = 3
		hp_bg.corner_radius_bottom_right = 3
		hp_bar.add_theme_stylebox_override("background", hp_bg)
		var hp_fill := StyleBoxFlat.new()
		hp_fill.bg_color = Color("#22c55e")
		hp_fill.corner_radius_top_left = 3
		hp_fill.corner_radius_top_right = 3
		hp_fill.corner_radius_bottom_left = 3
		hp_fill.corner_radius_bottom_right = 3
		hp_bar.add_theme_stylebox_override("fill", hp_fill)

		hp_label = Label.new()
		hp_label.name = "HpTextLabel"
		hp_label.set_anchors_preset(Control.PRESET_FULL_RECT)
		hp_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		hp_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		hp_label.add_theme_font_size_override("font_size", 11)
		hp_label.add_theme_color_override("font_color", Color.WHITE)
		hp_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.8))
		hp_label.add_theme_constant_override("shadow_offset_x", 1)
		hp_label.add_theme_constant_override("shadow_offset_y", 1)
		hp_bar.add_child(hp_label)
		bars_container.add_child(hp_bar)
	else:
		hp_label = hp_bar.find_child("HpTextLabel", false, false) as Label

	# Barra de Escudo (Aparece sob a vida se houver escudo ativo)
	var shield_bar = bars_container.find_child("InspectorShieldBar", false, false) as ProgressBar
	var shield_label: Label = null
	if not shield_bar:
		shield_bar = ProgressBar.new()
		shield_bar.name = "InspectorShieldBar"
		shield_bar.custom_minimum_size = Vector2(0, 14)
		shield_bar.show_percentage = false
		var sh_bg := StyleBoxFlat.new()
		sh_bg.bg_color = Color("#082f49")
		sh_bg.corner_radius_top_left = 3
		sh_bg.corner_radius_top_right = 3
		sh_bg.corner_radius_bottom_left = 3
		sh_bg.corner_radius_bottom_right = 3
		shield_bar.add_theme_stylebox_override("background", sh_bg)
		var sh_fill := StyleBoxFlat.new()
		sh_fill.bg_color = Color("#06b6d4")
		sh_fill.corner_radius_top_left = 3
		sh_fill.corner_radius_top_right = 3
		sh_fill.corner_radius_bottom_left = 3
		sh_fill.corner_radius_bottom_right = 3
		shield_bar.add_theme_stylebox_override("fill", sh_fill)

		shield_label = Label.new()
		shield_label.name = "ShieldTextLabel"
		shield_label.set_anchors_preset(Control.PRESET_FULL_RECT)
		shield_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		shield_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		shield_label.add_theme_font_size_override("font_size", 10)
		shield_label.add_theme_color_override("font_color", Color("#cffafe"))
		shield_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.8))
		shield_label.add_theme_constant_override("shadow_offset_x", 1)
		shield_label.add_theme_constant_override("shadow_offset_y", 1)
		shield_bar.add_child(shield_label)
		bars_container.add_child(shield_bar)
		bars_container.move_child(shield_bar, hp_bar.get_index() + 1)
	else:
		shield_label = shield_bar.find_child("ShieldTextLabel", false, false) as Label

	var cur_shield := maxi(int(unit.current_shield), 0)
	hp_bar.max_value = maxf(max_hp, 1.0)
	hp_bar.value = cur_hp
	if hp_label:
		var bonus_hp_text := ""
		if float(unit.synergy_bonuses.get("max_health_pct", 0.0)) > 0.0:
			bonus_hp_text = " (+%d%%)" % int(float(unit.synergy_bonuses.get("max_health_pct", 0.0)) * 100.0)
		if cur_shield > 0:
			hp_label.text = "%d (+%d) / %d%s" % [cur_hp, cur_shield, max_hp, bonus_hp_text]
		else:
			hp_label.text = "%d / %d%s" % [cur_hp, max_hp, bonus_hp_text]

	if cur_shield > 0:
		shield_bar.visible = true
		shield_bar.max_value = maxf(max_hp, 1.0)
		shield_bar.value = cur_shield
		if shield_label:
			shield_label.text = "Escudo: %d" % cur_shield
	else:
		shield_bar.visible = false

	# Barra de Mana
	var mana_bar = bars_container.find_child("InspectorManaBar", false, false) as ProgressBar
	var mana_label: Label = null
	if not mana_bar:
		mana_bar = ProgressBar.new()
		mana_bar.name = "InspectorManaBar"
		mana_bar.custom_minimum_size = Vector2(0, 14)
		mana_bar.show_percentage = false
		var mp_bg := StyleBoxFlat.new()
		mp_bg.bg_color = Color("#082f49")
		mp_bg.corner_radius_top_left = 3
		mp_bg.corner_radius_top_right = 3
		mp_bg.corner_radius_bottom_left = 3
		mp_bg.corner_radius_bottom_right = 3
		mana_bar.add_theme_stylebox_override("background", mp_bg)
		var mp_fill := StyleBoxFlat.new()
		mp_fill.bg_color = Color("#0284c7")
		mp_fill.corner_radius_top_left = 3
		mp_fill.corner_radius_top_right = 3
		mp_fill.corner_radius_bottom_left = 3
		mp_fill.corner_radius_bottom_right = 3
		mana_bar.add_theme_stylebox_override("fill", mp_fill)

		mana_label = Label.new()
		mana_label.name = "ManaTextLabel"
		mana_label.set_anchors_preset(Control.PRESET_FULL_RECT)
		mana_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		mana_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		mana_label.add_theme_font_size_override("font_size", 10)
		mana_label.add_theme_color_override("font_color", Color.WHITE)
		mana_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.8))
		mana_label.add_theme_constant_override("shadow_offset_x", 1)
		mana_label.add_theme_constant_override("shadow_offset_y", 1)
		mana_bar.add_child(mana_label)
		bars_container.add_child(mana_bar)
	else:
		mana_label = mana_bar.find_child("ManaTextLabel", false, false) as Label

	mana_bar.max_value = maxf(stats.max_mana, 1.0)
	mana_bar.value = cur_mana
	if mana_label:
		mana_label.text = "%d / %d" % [cur_mana, int(stats.max_mana)]

	# 2. LINHA TÁTICA (Habilidade + Badges de Função e Alcance)
	var tactical_row = vbox.find_child("TFT_TacticalRow", false, false) as HBoxContainer
	if not tactical_row:
		tactical_row = HBoxContainer.new()
		tactical_row.name = "TFT_TacticalRow"
		tactical_row.add_theme_constant_override("separation", 8)
		vbox.add_child(tactical_row)
		vbox.move_child(tactical_row, bars_container.get_index() + 1)

	# Botão de Habilidade
	var ability_btn = tactical_row.find_child("AbilityButton", false, false) as Button
	if not ability_btn:
		ability_btn = Button.new()
		ability_btn.name = "AbilityButton"
		ability_btn.custom_minimum_size = Vector2(44, 44)
		ability_btn.expand_icon = true
		ability_btn.icon = stats.icon
		var btn_style := StyleBoxFlat.new()
		btn_style.bg_color = Color("#1e1b4b")
		btn_style.border_color = Color("#a855f7")
		btn_style.border_width_left = 2
		btn_style.border_width_top = 2
		btn_style.border_width_right = 2
		btn_style.border_width_bottom = 2
		btn_style.corner_radius_top_left = 6
		btn_style.corner_radius_top_right = 6
		btn_style.corner_radius_bottom_left = 6
		btn_style.corner_radius_bottom_right = 6
		ability_btn.add_theme_stylebox_override("normal", btn_style)
		ability_btn.add_theme_stylebox_override("hover", btn_style)
		ability_btn.add_theme_stylebox_override("pressed", btn_style)
		tactical_row.add_child(ability_btn)
	else:
		ability_btn.icon = stats.icon

	if ability_btn.mouse_entered.is_connected(_show_ability_floating_card):
		ability_btn.mouse_entered.disconnect(_show_ability_floating_card)
	ability_btn.mouse_entered.connect(_show_ability_floating_card.bind(unit, panel))
	if not ability_btn.mouse_exited.is_connected(_hide_ability_floating_card):
		ability_btn.mouse_exited.connect(_hide_ability_floating_card)
	# Desativar tooltip padrão nativo para evitar sobreposição feia com o card flutuante
	ability_btn.tooltip_text = ""

	# Coluna com Badges táticos
	var badges_vbox = tactical_row.find_child("BadgesVBox", false, false) as VBoxContainer
	if not badges_vbox:
		badges_vbox = VBoxContainer.new()
		badges_vbox.name = "BadgesVBox"
		badges_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		badges_vbox.add_theme_constant_override("separation", 3)
		tactical_row.add_child(badges_vbox)

	var role_badge = badges_vbox.find_child("RoleBadge", false, false) as Label
	if not role_badge:
		role_badge = Label.new()
		role_badge.name = "RoleBadge"
		role_badge.add_theme_font_size_override("font_size", 11)
		role_badge.add_theme_color_override("font_color", Color("#38bdf8"))
		role_badge.mouse_filter = Control.MOUSE_FILTER_PASS
		var p_style := StyleBoxFlat.new()
		p_style.bg_color = Color("#0f172a99")
		p_style.corner_radius_top_left = 4
		p_style.corner_radius_top_right = 4
		p_style.corner_radius_bottom_left = 4
		p_style.corner_radius_bottom_right = 4
		p_style.content_margin_left = 6
		p_style.content_margin_top = 2
		p_style.content_margin_right = 6
		p_style.content_margin_bottom = 2
		role_badge.add_theme_stylebox_override("panel", p_style)
		badges_vbox.add_child(role_badge)
	role_badge.text = "[ %s ]" % stats.get_combat_role().to_upper()
	role_badge.tooltip_text = "Função de Combate:\n%s" % stats.get_combat_role_description()

	var range_badge = badges_vbox.find_child("RangeBadge", false, false) as Label
	if not range_badge:
		range_badge = Label.new()
		range_badge.name = "RangeBadge"
		range_badge.add_theme_font_size_override("font_size", 11)
		range_badge.add_theme_color_override("font_color", Color("#cbd5e1"))
		range_badge.mouse_filter = Control.MOUSE_FILTER_PASS
		var r_style := StyleBoxFlat.new()
		r_style.bg_color = Color("#0f172a99")
		r_style.corner_radius_top_left = 4
		r_style.corner_radius_top_right = 4
		r_style.corner_radius_bottom_left = 4
		r_style.corner_radius_bottom_right = 4
		r_style.content_margin_left = 6
		r_style.content_margin_top = 2
		r_style.content_margin_right = 6
		r_style.content_margin_bottom = 2
		range_badge.add_theme_stylebox_override("panel", r_style)
		badges_vbox.add_child(range_badge)
	var pos_str := "Recuada" if stats.is_ranged else "Linha de Frente"
	range_badge.text = "%s · %d Hex" % [pos_str, stats.get_attack_range_hexes()]
	range_badge.tooltip_text = "Posicionamento Tático:\nIdeal na %s. Alcance efetivo de %d hexágonos." % [pos_str, stats.get_attack_range_hexes()]

	# 3. GRID DE ATRIBUTOS 2x4 (Estilo TFT)
	var stats_grid = vbox.find_child("TFT_StatsGrid", false, false) as GridContainer
	if not stats_grid:
		stats_grid = GridContainer.new()
		stats_grid.name = "TFT_StatsGrid"
		stats_grid.columns = 4
		stats_grid.add_theme_constant_override("h_separation", 4)
		stats_grid.add_theme_constant_override("v_separation", 4)
		vbox.add_child(stats_grid)
		vbox.move_child(stats_grid, tactical_row.get_index() + 1)

	var stat_items := [
		{"key": "ad", "icon": "sword", "val": str(attack_dmg), "color": "#fb923c", "tip": "Dano de Ataque: %d\nDano físico atual por ataque (inclui itens, sinergias e bônus)." % attack_dmg},
		{"key": "ap", "icon": "magic_wand", "val": str(int(stats.ability_damage * stats.get_star_multiplier(star))), "color": "#c084fc", "tip": "Poder de Habilidade: %d\nDano base escalonado por estrelas (x%.1f)." % [int(stats.ability_damage * stats.get_star_multiplier(star)), stats.get_star_multiplier(star)]},
		{"key": "arm", "icon": "armor_plate", "val": str(int(total_armor)), "color": "#60a5fa", "tip": "Armadura: %d\nReduz dano físico recebido em %d%%." % [int(total_armor), phys_reduct]},
		{"key": "mr", "icon": "ring_amulet", "val": str(int(total_mr)), "color": "#2dd4bf", "tip": "Resistência Mágica: %d\nReduz dano mágico recebido em %d%%." % [int(total_mr), mag_reduct]},
		{"key": "as", "icon": "lightning", "val": "%.2f" % attack_spd, "color": "#facc15", "tip": "Velocidade de Ataque: %.2f ataques por segundo." % attack_spd},
		{"key": "crit", "icon": "sparkle", "val": "25%", "color": "#f43f5e", "tip": "Acerto Crítico: 25%%\nChance de ataques normais e magias causarem dano crítico amplificado."},
		{"key": "rng", "icon": "arrows_double", "val": "%d Hex" % stats.get_attack_range_hexes(), "color": "#94a3b8", "tip": "Alcance de Ataque: %d hexágonos." % stats.get_attack_range_hexes()},
		{"key": "dps", "icon": "skull", "val": str(dps), "color": "#e2e8f0", "tip": "DPS em Tempo Real: ~%d\nDano por segundo contínuo estimado (Ataque x Velocidade)." % dps}
	]

	for item in stat_items:
		var slot_name = "Slot_" + item["key"]
		var slot = stats_grid.find_child(slot_name, false, false) as PanelContainer
		var val_lbl: Label = null
		if not slot:
			slot = PanelContainer.new()
			slot.name = slot_name
			slot.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			slot.mouse_filter = Control.MOUSE_FILTER_PASS
			var s_box := StyleBoxFlat.new()
			s_box.bg_color = Color("#1e293b66")
			s_box.border_color = Color("#33415566")
			s_box.border_width_left = 1
			s_box.border_width_top = 1
			s_box.border_width_right = 1
			s_box.border_width_bottom = 1
			s_box.corner_radius_top_left = 4
			s_box.corner_radius_top_right = 4
			s_box.corner_radius_bottom_left = 4
			s_box.corner_radius_bottom_right = 4
			s_box.content_margin_left = 4
			s_box.content_margin_top = 3
			s_box.content_margin_right = 4
			s_box.content_margin_bottom = 3
			slot.add_theme_stylebox_override("panel", s_box)

			var hbox := HBoxContainer.new()
			hbox.add_theme_constant_override("separation", 3)
			hbox.alignment = BoxContainer.ALIGNMENT_CENTER
			var icon_r := UIAtlasCatalog.create_icon_rect(item["icon"], Vector2(14, 14))
			icon_r.modulate = Color(item["color"])
			hbox.add_child(icon_r)

			val_lbl = Label.new()
			val_lbl.name = "ValLabel"
			val_lbl.add_theme_font_size_override("font_size", 10)
			val_lbl.add_theme_color_override("font_color", Color("#f8fafc"))
			hbox.add_child(val_lbl)

			slot.add_child(hbox)
			stats_grid.add_child(slot)
		else:
			val_lbl = slot.find_child("ValLabel", true, false) as Label

		slot.tooltip_text = item["tip"]
		if val_lbl:
			val_lbl.text = item["val"]

func _update_inspector_live_data(panel: Control, unit: BaseUnit3D) -> void:
	if not is_instance_valid(unit) or not unit.stats or not is_instance_valid(panel):
		return
	var stats := unit.stats
	var star := clampi(unit.star_level, 1, 4)

	var cur_hp := maxi(int(unit.current_health), 0)
	var max_hp := maxi(int(unit.get_max_health()), 1)
	var cur_shield := maxi(int(unit.current_shield), 0)
	var cur_mana := maxi(int(unit.current_mana), 0)
	var max_mana := maxi(int(stats.max_mana), 1)

	var attack_dmg := maxi(int(unit.get_attack_damage()), 0)
	var attack_spd := unit.get_effective_attack_speed()
	var dps := maxi(int(attack_dmg * attack_spd), 0)

	var total_armor := unit.get_effective_armor()
	var total_mr := unit.get_effective_magic_resist()
	var phys_reduct: int = int(round((total_armor / (100.0 + total_armor)) * 100.0))
	var mag_reduct: int = int(round((total_mr / (100.0 + total_mr)) * 100.0))

	var ap_mult: float = 1.0 + float(unit.synergy_bonuses.get("ability_power_pct", 0.0))
	var ap_val: int = int(stats.ability_damage * stats.get_star_multiplier(star) * ap_mult)
	var crit_pct: int = int(round((0.25 + (mini(unit.enemies_defeated, BaseUnit3D.MAX_CERRADO_STACKS) * 0.06 if "Cerrado" in stats.origins else 0.0)) * 100.0))

	# Barra de Vida
	var hp_bar = panel.find_child("InspectorHpBar", true, false) as ProgressBar
	if hp_bar:
		hp_bar.max_value = max_hp
		hp_bar.value = cur_hp
		var hp_label = hp_bar.find_child("HpTextLabel", false, false) as Label
		if hp_label:
			var bonus_hp_text := ""
			if float(unit.synergy_bonuses.get("max_health_pct", 0.0)) > 0.0:
				bonus_hp_text = " (+%d%%)" % int(float(unit.synergy_bonuses.get("max_health_pct", 0.0)) * 100.0)
			if cur_shield > 0:
				hp_label.text = "%d (+%d) / %d%s" % [cur_hp, cur_shield, max_hp, bonus_hp_text]
			else:
				hp_label.text = "%d / %d%s" % [cur_hp, max_hp, bonus_hp_text]

	# Barra de Escudo
	var shield_bar = panel.find_child("InspectorShieldBar", true, false) as ProgressBar
	if shield_bar:
		if cur_shield > 0:
			shield_bar.visible = true
			shield_bar.max_value = max_hp
			shield_bar.value = cur_shield
			var shield_label = shield_bar.find_child("ShieldTextLabel", false, false) as Label
			if shield_label:
				shield_label.text = "Escudo: %d" % cur_shield
		else:
			shield_bar.visible = false

	# Barra de Mana
	var mana_bar = panel.find_child("InspectorManaBar", true, false) as ProgressBar
	if mana_bar:
		mana_bar.max_value = max_mana
		mana_bar.value = cur_mana
		var mana_label = mana_bar.find_child("ManaTextLabel", false, false) as Label
		if mana_label:
			mana_label.text = "%d / %d" % [cur_mana, int(stats.max_mana)]

	# Grid de Atributos em Tempo Real
	var stats_grid = panel.find_child("TFT_StatsGrid", true, false) as GridContainer
	if stats_grid:
		var live_stats := {
			"ad": {"val": str(attack_dmg), "tip": "Dano de Ataque: %d\nDano físico atual por ataque (inclui itens, sinergias e bônus)." % attack_dmg},
			"ap": {"val": str(ap_val), "tip": "Poder de Habilidade: %d\nDano base escalonado por estrelas (x%.1f) e amplificadores." % [ap_val, stats.get_star_multiplier(star)]},
			"arm": {"val": str(int(total_armor)), "tip": "Armadura: %d\nReduz dano físico recebido em %d%%." % [int(total_armor), phys_reduct]},
			"mr": {"val": str(int(total_mr)), "tip": "Resistência Mágica: %d\nReduz dano mágico recebido em %d%%." % [int(total_mr), mag_reduct]},
			"as": {"val": "%.2f" % attack_spd, "tip": "Velocidade de Ataque: %.2f ataques por segundo." % attack_spd},
			"crit": {"val": "%d%%" % crit_pct, "tip": "Acerto Crítico: %d%%\nChance de ataques normais e magias causarem dano crítico amplificado." % crit_pct},
			"rng": {"val": "%d Hex" % stats.get_attack_range_hexes(), "tip": "Alcance de Ataque: %d hexágonos." % stats.get_attack_range_hexes()},
			"dps": {"val": str(dps), "tip": "DPS em Tempo Real: ~%d\nDano por segundo contínuo estimado (Ataque x Velocidade)." % dps}
		}
		for key in live_stats.keys():
			var slot = stats_grid.find_child("Slot_" + key, false, false) as Control
			if slot:
				var v_lbl = slot.find_child("ValLabel", true, false) as Label
				if v_lbl:
					v_lbl.text = live_stats[key]["val"]
				slot.tooltip_text = live_stats[key]["tip"]

	# Stacks de Cerrado em tempo real
	var origins_lbl = panel.find_child("Origins_label", true, false) as RichTextLabel
	if origins_lbl and "Cerrado" in stats.origins:
		var origin_parts: Array[String] = []
		for orig in stats.origins:
			var extra := ""
			if orig == "Cerrado":
				extra = " [color=#e67e22](%d/10 st)[/color]" % [mini(unit.enemies_defeated, BaseUnit3D.MAX_CERRADO_STACKS)]
			origin_parts.append("[url=%s][u][color=#f5da80]%s[/color][/u]%s[/url]" % [orig, orig, extra])
		origins_lbl.text = "[color=#f1c40f]ORIGENS[/color]  %s" % (" · ".join(origin_parts))

func show_unit_inspector(unit: BaseUnit3D) -> void:
	if not is_instance_valid(unit) or not unit.stats or not ui:
		return
	var panel := ui.get_node_or_null("Control/RightBar") as Control
	if not panel:
		return
	_inspected_unit = unit
	var stats := unit.stats
	
	var name_lbl = panel.find_child("Name_label", true, false) as RichTextLabel
	if name_lbl:
		var tier_hex := "#" + stats.get_tier_color().to_html(false)
		name_lbl.text = "[b]%s[/b] [color=%s](Tier %d · %dg)[/color]" % [
			stats.unit_name, tier_hex, stats.tier, stats.cost
		]
		var star_box = panel.find_child("InspectorStarBox", true, false) as HBoxContainer
		if not star_box:
			star_box = HBoxContainer.new()
			star_box.name = "InspectorStarBox"
			star_box.alignment = BoxContainer.ALIGNMENT_CENTER
			star_box.add_theme_constant_override("separation", 3)
			name_lbl.get_parent().add_child(star_box)
			name_lbl.get_parent().move_child(star_box, name_lbl.get_index() + 1)
		for child in star_box.get_children():
			child.queue_free()
		var stars_count: int = clampi(unit.star_level, 1, 4)
		for s in range(stars_count):
			var star_icon := UIAtlasCatalog.create_icon_rect("star", Vector2(16, 16))
			if stars_count >= 3:
				star_icon.modulate = Color("#fbbf24")
			elif stars_count == 2:
				star_icon.modulate = Color("#e2e8f0")
			else:
				star_icon.modulate = Color("#cd7f32")
			star_box.add_child(star_icon)
	
	var p_frame = panel.find_child("PortraitFrame", true, false)
	if p_frame:
		p_frame.modulate = stats.get_tier_color()
	var img = panel.find_child("Image_container", true, false) as TextureRect
	if img:
		img.texture = stats.icon
	
	# Calcular valores numéricos
	var cur_hp := int(unit.current_health)
	var max_hp := int(unit.get_max_health())
	var cur_mana := int(unit.current_mana)
	var max_mana := int(stats.max_mana)
	var attack_dmg := int(unit.get_attack_damage())
	var attack_spd := unit.get_effective_attack_speed()
	var dps := int(attack_dmg * attack_spd)
	
	var total_armor := unit.get_effective_armor()
	var phys_reduct: int = int(round((total_armor / (100.0 + total_armor)) * 100.0))
	var total_mr := unit.get_effective_magic_resist()
	var mag_reduct: int = int(round((total_mr / (100.0 + total_mr)) * 100.0))

	# Atualizar e ocultar labels legadas para dar lugar aos componentes visuais elegantes
	var hp_lbl = panel.find_child("Hp_label", true, false)
	if hp_lbl:
		hp_lbl.text = "[color=#2ecc71]VIDA[/color]  [b]%d[/b] / %d" % [cur_hp, max_hp]
		hp_lbl.visible = false
	var mana_lbl = panel.find_child("Mana_label", true, false)
	if mana_lbl:
		mana_lbl.text = "[color=#38bdf8]MANA[/color]  [b]%d[/b] / %d" % [cur_mana, max_mana]
		mana_lbl.visible = false
	var type_lbl = panel.find_child("Type_label", true, false)
	if type_lbl:
		type_lbl.visible = false
	var range_lbl = panel.find_child("Range_label", true, false)
	if range_lbl:
		range_lbl.visible = false
	var def_lbl = panel.find_child("Defense_label", true, false)
	if def_lbl:
		def_lbl.visible = false
	var role_lbl = panel.find_child("Role_label", true, false)
	if role_lbl:
		role_lbl.visible = false
	var sc_lbl = panel.find_child("Star_scaling_label", true, false)
	if sc_lbl:
		sc_lbl.visible = false
	var aff_lbl = panel.find_child("Affinities_label", true, false)
	if aff_lbl:
		aff_lbl.visible = false

	# 7. Origens (com links de sinergia)
	var origins_lbl = panel.find_child("Origins_label", true, false) as RichTextLabel
	if origins_lbl:
		var origin_parts: Array[String] = []
		for orig in stats.origins:
			var extra := ""
			if orig == "Cerrado":
				extra = " [color=#e67e22](%d/10 st)[/color]" % [mini(unit.enemies_defeated, BaseUnit3D.MAX_CERRADO_STACKS)]
			origin_parts.append("[url=%s][u][color=#f5da80]%s[/color][/u]%s[/url]" % [orig, orig, extra])
		origins_lbl.text = "[color=#f1c40f]ORIGENS[/color]  %s" % (" · ".join(origin_parts) if not origin_parts.is_empty() else "—")
	
	# 8. Classes (com links de sinergia)
	var classes_lbl = panel.find_child("Classes_label", true, false) as RichTextLabel
	if classes_lbl:
		var class_parts: Array[String] = []
		for cls in stats.classes:
			class_parts.append("[url=%s][u][color=#d8b4fe]%s[/color][/u][/url]" % [cls, cls])
		classes_lbl.text = "[color=#9b59b6]CLASSES[/color]  %s" % (" · ".join(class_parts) if not class_parts.is_empty() else "—")

	# 9. Atualizar layout e componentes TFT
	_update_tft_inspector(panel, unit, cur_hp, max_hp, cur_mana, max_mana, attack_dmg, attack_spd, dps, total_armor, phys_reduct, total_mr, mag_reduct)
	_update_inspector_live_data(panel, unit)
	
	if ui and ui.has_method("set_inspected_unit_data"):
		ui.set_inspected_unit_data(stats, unit.star_level)
	ui.show_inspector()

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
		var matches = unit.stats.origins.has(synergy_name) or unit.stats.classes.has(synergy_name)
		if matches:
			_highlighted_synergy_units.append(unit)
			unit.set_synergy_highlighted(true)
			if not unit.is_on_bench() and board.get_cell(unit.board_position):
				board.highlight_cell(unit.board_position, true, Color("#f59e0b"))
				_highlighted_synergy_cells.append(unit.board_position)
	
	for unit in bench_units:
		if is_instance_valid(unit) and unit.stats:
			var matches := unit.stats.origins.has(synergy_name) or unit.stats.classes.has(synergy_name)
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
	_hide_ability_floating_card()
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
	AudioManager.play_pause_music()
	get_tree().paused = true
	_overlay.set_match_time(match_elapsed_seconds)
	_overlay.open("pause", true)

func _resume_game() -> void:
	if _load_failed:
		_overlay.open("pause", true)
		_overlay.show_error("Esta campanha não pôde ser carregada. Volte ao menu para preservar o arquivo.")
		return
	AudioManager.resume_region_music()
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
	AudioManager.play_menu_music()
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
		"match_time": match_elapsed_seconds,
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
	match_elapsed_seconds = float(run.get("match_time", 0.0))
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
