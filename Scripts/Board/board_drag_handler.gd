class_name BoardDragHandler
extends Node

# --- Signals ---

signal unit_placed_on_board(unit: BaseUnit3D, grid_pos: Vector2i, source: String, source_index: int, old_pos: Vector2i)
signal unit_returned_to_shop(unit_stats: UnitStats)
signal unit_placed_on_bench(unit: BaseUnit3D, source: String, source_index: int)
signal unit_sold(unit: BaseUnit3D, source: String, source_index: int)
signal drag_finished

var board: Board3D
var camera: Camera3D
var bench_control: Control
var sell_zone_control: Control
var interaction_enabled: bool = true
var board_interaction_enabled: bool = true
var dragging_unit_data: Dictionary = {}
var is_dragging: bool = false

var highlight_cells: Array[Vector2i] = []
var attack_range_cells: Array[Vector2i] = []
var ghost_unit: Node3D = null
var current_hiver_cell: Vector2i = Vector2i(-1, -1)
var hovered_unit: BaseUnit3D = null


func _ready() -> void:
	set_process_input(true)

func setup(board_ref: Board3D, camera_ref: Camera3D) -> void:
	board = board_ref
	camera = camera_ref

func set_bench_control(control: Control) -> void:
	bench_control = control

func set_sell_zone_control(control: Control) -> void:
	sell_zone_control = control

#func _process(delta: float) -> void:
	#if is_dragging and ghost_unit:
		#update_ghost_position()

func _input(event: InputEvent) -> void:
	if not board or not camera or not interaction_enabled:
		return
	
	if event is InputEventMouseMotion:
		if is_dragging:
			update_hover_highlight(event.position)
			update_ghost_position(event.position)
		else:
			update_unit_hover(event.position)
	
	elif event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT: 
			if event.pressed and not is_dragging:
				if get_viewport().gui_get_hovered_control() != null:
					return
				try_pickup_unit(event.position)
			elif not event.pressed and is_dragging:
				try_place_unit(event.position)

func update_unit_hover(mouse_pos: Vector2) -> void:
	if not board or not camera or not is_instance_valid(board):
		_clear_hovered_unit()
		return
	if get_viewport().gui_get_hovered_control() != null:
		_clear_hovered_unit()
		return
	var from := camera.project_ray_origin(mouse_pos)
	var to := from + camera.project_ray_normal(mouse_pos) * 1000.0
	var query := PhysicsRayQueryParameters3D.create(from, to)
	query.collision_mask = 1
	var result := board.get_world_3d().direct_space_state.intersect_ray(query)
	if result and result.collider is BaseUnit3D:
		var unit: BaseUnit3D = result.collider
		if unit != hovered_unit:
			_clear_hovered_unit()
			hovered_unit = unit
			hovered_unit.set_hovered(true)
	else:
		_clear_hovered_unit()

func _clear_hovered_unit() -> void:
	if is_instance_valid(hovered_unit):
		hovered_unit.set_hovered(false)
	hovered_unit = null

func try_pickup_unit(mouse_pos: Vector2) -> void:
	if not board_interaction_enabled:
		return
	var from = camera.project_ray_origin(mouse_pos)
	var to = from + camera.project_ray_normal(mouse_pos) * 1000
	var query = PhysicsRayQueryParameters3D.create(from, to)
	query.collision_mask = 1
	
	var result = board.get_world_3d().direct_space_state.intersect_ray(query)
	
	if result and result.collider is BaseUnit3D:
		var unit: BaseUnit3D = result.collider
		if unit.team == 0 and unit.current_state != BaseUnit3D.State.DEAD:
			var tree := get_tree()
			var main_node = tree.current_scene if tree else null
			if main_node and "ui" in main_node and main_node.ui and "item_inventory_ui" in main_node.ui and main_node.ui.item_inventory_ui:
				if main_node.ui.item_inventory_ui.selected_item != null:
					main_node.ui.item_inventory_ui.try_equip_selected_to_unit(unit)
					if main_node.has_method("_refresh_synergies"):
						main_node._refresh_synergies()
					if main_node.has_method("update_ui"):
						main_node.update_ui()
					return

			var grid_pos = unit.board_position
			if grid_pos.y == -1 or board.is_bench_position(unit.global_position):
				start_drag({
					"unit_instance": unit,
					"unit_stats": unit.stats,
					"source": "bench",
					"bench_index": grid_pos.x,
					"old_pos": grid_pos,
				})
			else:
				board.remove_unit(grid_pos)
				start_drag({
					"unit_instance": unit,
					"unit_stats": unit.stats,
					"source": "board",
					"old_pos": grid_pos,
				})
			
func start_drag(unit_data: Dictionary) -> void:
	if not interaction_enabled or is_dragging:
		return
	if not board_interaction_enabled and unit_data.get("source", "") != "bench":
		return
	_clear_hovered_unit()
	dragging_unit_data = unit_data
	is_dragging = true
	
	create_ghost_unit()
	
	if unit_data.has("source"):
		if unit_data.source == "shop" or unit_data.source == "bench":
			highlight_valid_cells_for_player()
	if sell_zone_control and unit_data.get("source", "") in ["board", "bench"]:
		sell_zone_control.visible = true

func create_ghost_unit() -> void:
	if not dragging_unit_data.has("unit_instance"):
		print("ERRO: unit_instance nao encontrado")
		return
	
	var unit: BaseUnit3D = dragging_unit_data.unit_instance
	
	ghost_unit = Node3D.new()
	ghost_unit.name = "GhostUnit"
	board.add_child(ghost_unit)
	
	var mesh_copy := MeshInstance3D.new()
	
	if unit.model and unit.model is MeshInstance3D:
		mesh_copy.mesh = unit.model.mesh
	else:
		var capsule := CapsuleMesh.new()
		capsule.height = 2.0
		capsule.radius = 0.4
		mesh_copy.mesh = capsule
	
	var ghost_material := StandardMaterial3D.new()
	
	if unit.stats:
		ghost_material.albedo_color = unit.stats.get_tier_color()
	else:
		ghost_material.albedo_color = Color(0.5, 0.8, 1.0)
	
	ghost_material.albedo_color.a = 0.6
	ghost_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	ghost_material.emission_enabled = true
	ghost_material.emission = ghost_material.albedo_color
	ghost_material.emission_energy_multiplier = 1.5
	
	mesh_copy.material_override = ghost_material
	ghost_unit.add_child(mesh_copy)
	
	var label := Label3D.new()
	label.text = unit.stats.unit_name if unit.stats else "Unit"
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.no_depth_test = true
	label.fixed_size = true
	label.font_size = 14
	label.position = Vector3(0, 2.5, 0)
	label.modulate = Color(1, 1, 1, 0.8)
	label.outline_size = 8
	label.outline_modulate = Color.BLACK
	ghost_unit.add_child(label)
	
	print("Ghost unit criado")

func update_ghost_position(mouse_pos: Vector2) -> void:
	if not ghost_unit:
		return
	
	var grid_pos := get_grid_position_from_mouse(mouse_pos)
	
	if grid_pos.y == -1 and grid_pos.x >= 0:
		var bench_pos := board.get_bench_slot_world_position(grid_pos.x)
		ghost_unit.global_position = bench_pos + Vector3(0, 0.9, 0)
	elif grid_pos != Vector2i(-1, -1):
		var world_pos := board.get_cell_world_position(grid_pos)
		ghost_unit.global_position = world_pos + Vector3(0, 1.5, 0)
	else:
		var origin := camera.project_ray_origin(mouse_pos)
		var dir := camera.project_ray_normal(mouse_pos)
		ghost_unit.global_position = origin + dir * 8.0

func stop_drag() -> void:
	is_dragging = false
	_clear_hovered_unit()
	if sell_zone_control:
		sell_zone_control.visible = false
	dragging_unit_data.clear()
	clear_all_highlights()
	if ghost_unit:
		ghost_unit.queue_free()
		ghost_unit = null
		
	current_hiver_cell = Vector2i(-1, -1)
	drag_finished.emit()

func cancel_drag() -> void:
	if not is_dragging:
		return
	var audio = get_tree().root.get_node_or_null("AudioManager") if get_tree() and get_tree().root else null
	if audio and audio.has_method("play_ui_cancel"):
		audio.play_ui_cancel()
	return_unit_to_origin()
	stop_drag()
	

func highlight_valid_cells_for_player() -> void:
	print("Destacando celulas validas...")
	clear_all_highlights()
	if not board_interaction_enabled:
		return
	
	var highlighted_count: int = 0
	
	for row in range(board.rows - board.player_rows, board.rows):
		for col in board.columns:
			var grid_pos := Vector2i(col, row)
			if not board.is_cell_occupied(grid_pos):
				board.highlight_cell(grid_pos, true)
				highlight_cells.append(grid_pos)
				highlighted_count += 1
	
	print("  %d celulas destacadas" % highlighted_count)

func clear_all_highlights() -> void:
	for pos in highlight_cells:
		board.highlight_cell(pos, false)
	highlight_cells.clear()
	for pos in attack_range_cells:
		board.highlight_cell(pos, false)
	attack_range_cells.clear()

func update_hover_highlight(mouse_pos: Vector2) -> void:
	if not board_interaction_enabled:
		return
	var grid_pos: Vector2i = get_grid_position_from_mouse(mouse_pos)
	
	if grid_pos == current_hiver_cell:
		return
	
	current_hiver_cell = grid_pos
	
	highlight_valid_cells_for_player()
	if grid_pos != Vector2i(-1, -1):
		_highlight_attack_range(grid_pos)
	
	if grid_pos != Vector2i(-1, -1):
		var source: String = dragging_unit_data.get("source", "")
		var is_occupied := board.is_cell_occupied(grid_pos)
		var is_swap := (
			source in ["board", "bench"]
			and is_occupied
			and board.get_unit_at(grid_pos) != null
			and board.get_unit_at(grid_pos) is BaseUnit3D
			and (board.get_unit_at(grid_pos) as BaseUnit3D).team == 0
		)
		if board.is_player_zone(grid_pos) and (not is_occupied or is_swap):
			var hl_color := Color("#60a5fa") if is_swap else Color("#f2d477")
			board.highlight_cell(grid_pos, true, hl_color)
			if grid_pos not in highlight_cells:
				highlight_cells.append(grid_pos)

func _highlight_attack_range(center: Vector2i) -> void:
	var unit := dragging_unit_data.get("unit_instance") as BaseUnit3D
	if not is_instance_valid(unit) or not unit.stats:
		return
	var range_in_world := unit.get_attack_range_meters()
	for row in board.rows:
		for col in board.columns:
			var candidate := Vector2i(col, row)
			if board.get_distance_between_cells(center, candidate) <= range_in_world:
				board.highlight_cell(candidate, true, Color("#55cfe0"))
				attack_range_cells.append(candidate)

func try_place_unit(mouse_pos: Vector2) -> void:
	var source: String = dragging_unit_data.get("source", "")
	if source in ["board", "bench"] and sell_zone_control and sell_zone_control.is_visible_in_tree() and sell_zone_control.get_global_rect().has_point(mouse_pos):
		if dragging_unit_data.has("unit_instance"):
			unit_sold.emit(
				dragging_unit_data.unit_instance,
				source,
				int(dragging_unit_data.get("bench_index", -1))
			)
		stop_drag()
		return
	if not board_interaction_enabled:
		return_unit_to_origin()
		stop_drag()
		return

	if get_viewport().gui_get_hovered_control() != null:
		return_unit_to_origin()
		stop_drag()
		return

	var grid_pos: Vector2i = get_grid_position_from_mouse(mouse_pos)
	
	# Drop no Banco 3D
	if grid_pos.y == -1 and grid_pos.x >= 0:
		if dragging_unit_data.has("unit_instance"):
			unit_placed_on_bench.emit(
				dragging_unit_data.unit_instance,
				source,
				int(dragging_unit_data.get("bench_index", -1))
			)
		stop_drag()
		return

	var is_occupied := board.is_cell_occupied(grid_pos)
	var is_swap_candidate := (
		source in ["board", "bench"]
		and is_occupied
		and board.get_unit_at(grid_pos) != null
		and board.get_unit_at(grid_pos) is BaseUnit3D
		and (board.get_unit_at(grid_pos) as BaseUnit3D).team == 0
	)
	var drop_valid := (
		grid_pos != Vector2i(-1,-1)
		and board.is_player_zone(grid_pos)
		and (not is_occupied or is_swap_candidate)
	)
	
	if drop_valid:
		emit_place_unit_signal(grid_pos)
	else:
		return_unit_to_origin()
	stop_drag()

func return_unit_to_origin() -> void:
	if not dragging_unit_data.has("unit_instance"):
		return
	
	var unit: BaseUnit3D = dragging_unit_data.unit_instance
	
	if dragging_unit_data.get("source") == "board":
		var old_pos: Vector2i = dragging_unit_data.get("old_pos", Vector2i(-1,-1))
		if old_pos != Vector2i(-1,-1):
			board.place_unit(unit, old_pos, true)
	elif dragging_unit_data.get("source") == "shop":
		# Unidades compradas por arraste que não foram posicionadas devem ir SEMPRE para o banco
		unit_placed_on_bench.emit(unit, "shop", -1)
	elif dragging_unit_data.get("source") == "bench":
		unit.visible = true
		var idx: int = int(dragging_unit_data.get("bench_index", 0))
		unit.global_position = board.get_bench_slot_world_position(idx)
		unit.rotation.y = 0.0



func emit_place_unit_signal(grid_pos: Vector2i) -> void:
	if dragging_unit_data.has("unit_instance"):
		print("  Emitindo sinal unit_placed_on_board")
		unit_placed_on_board.emit(
			dragging_unit_data.unit_instance,
			grid_pos,
			dragging_unit_data.get("source", ""),
			int(dragging_unit_data.get("bench_index", -1)),
			dragging_unit_data.get("old_pos", Vector2i(-1, -1))
		)
	else:
		print("  ERRO: unit_instance nao encontrado em dragging_unit_data")

func get_grid_position_from_mouse(mouse_pos: Vector2) -> Vector2i:
	if not camera:
		return Vector2i(-1, -1)
	
	var from: Vector3 = camera.project_ray_origin(mouse_pos)
	var to: Vector3 = from + camera.project_ray_normal(mouse_pos) * 1000
	
	var query := PhysicsRayQueryParameters3D.create(from, to)
	query.collision_mask = 2
	
	var result := board.get_world_3d().direct_space_state.intersect_ray(query)
	
	if result:
		var hit_pos: Vector3 = result.position
		if board.is_bench_position(hit_pos):
			var slot := board.get_bench_slot_from_world_position(hit_pos)
			return Vector2i(slot, -1)
		
		var local_pos := board.to_local(hit_pos)
		return board.get_grid_position(local_pos)
	
	return Vector2i(-1, -1)
