class_name BoardDragHandler
extends Node

# --- Signals ---

signal unit_placed_on_board(unit: BaseUnit3D, grid_pos: Vector2i)
signal unit_returned_to_shop(unit_stats: UnitStats)

var board: Board3D
var camera: Camera3D
var dragging_unit_data: Dictionary = {}
var is_dragging: bool = false

var highlight_cells: Array[Vector2i] = []
var ghost_unit: Node3D = null
var current_hiver_cell: Vector2i = Vector2i(-1, -1)


func _ready() -> void:
	set_process_input(true)

func setup(board_ref: Board3D, camera_ref: Camera3D) -> void:
	board = board_ref
	camera = camera_ref

#func _process(delta: float) -> void:
	#if is_dragging and ghost_unit:
		#update_ghost_position()

func _input(event: InputEvent) -> void:
	if not board or not camera:
		return
	
	if event is InputEventMouseMotion and is_dragging:
		update_hover_highlight(event.position)
		update_ghost_position(event.position)
	
	elif event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT: 
			if event.pressed and not is_dragging:
				try_pickup_unit(event.position)
			elif not event.pressed and is_dragging:
				try_place_unit(event.position)

func try_pickup_unit(mouse_pos: Vector2) -> void:
	var from = camera.project_ray_origin(mouse_pos)
	var to = from + camera.project_ray_normal(mouse_pos) * 1000
	var query = PhysicsRayQueryParameters3D.create(from, to)
	query.collision_mask = 1
	
	var result = board.get_world_3d().direct_space_state.intersect_ray(query)
	
	if result and result.collider is BaseUnit3D:
		var unit: BaseUnit3D = result.collider
		if unit.team == 0:
			var grid_pos = unit.board_position
			board.remove_unit(grid_pos)
			
			start_drag({
				"unit_instance": unit,
				"unit_stats": unit.stats,
				"source": "board",
				"old_pos": grid_pos,
			})
			
func start_drag(unit_data: Dictionary) -> void:
	dragging_unit_data = unit_data
	is_dragging = true
	
	create_ghost_unit()
	
	if unit_data.has("source"):
		if unit_data.source == "shop":
			highlight_valid_cells_for_player()

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
	ghost_material.emission_energy = 1.5
	
	mesh_copy.material_override = ghost_material
	ghost_unit.add_child(mesh_copy)
	
	var label := Label3D.new()
	label.text = unit.stats.unit_name if unit.stats else "Unit"
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.no_depth_test = true
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
	
	if grid_pos != Vector2i(-1, -1):
		var world_pos := board.get_cell_world_position(grid_pos)
		ghost_unit.global_position = world_pos + Vector3(0, 1.5, 0)
	else:
		var origin := camera.project_ray_origin(mouse_pos)
		var dir := camera.project_ray_normal(mouse_pos)
		ghost_unit.global_position = origin + dir * 8.0

func stop_drag() -> void:
	is_dragging = false
	dragging_unit_data.clear()
	clear_all_highlights()
	if ghost_unit:
		ghost_unit.queue_free()
		ghost_unit = null
		
	current_hiver_cell = Vector2i(-1, -1)
	

func highlight_valid_cells_for_player() -> void:
	print("Destacando celulas validas...")
	clear_all_highlights()
	
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

func update_hover_highlight(mouse_pos: Vector2) -> void:
	var grid_pos: Vector2i = get_grid_position_from_mouse(mouse_pos)
	
	if grid_pos == current_hiver_cell:
		return
	
	current_hiver_cell = grid_pos
	
	highlight_valid_cells_for_player()
	
	if grid_pos != Vector2i(-1, -1):
		if board.is_player_zone(grid_pos) and not board.is_cell_occupied(grid_pos):
			board.highlight_cell(grid_pos, true)
			if grid_pos not in highlight_cells:
				highlight_cells.append(grid_pos)

func try_place_unit(mouse_pos: Vector2) -> void:
	var grid_pos: Vector2i = get_grid_position_from_mouse(mouse_pos)
	
	var drop_valid := (
		grid_pos != Vector2i(-1,-1)
		and board.is_player_zone(grid_pos)
		and not board.is_cell_occupied(grid_pos)
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
	else:
		if dragging_unit_data.has("unit_stats"):
			unit_returned_to_shop.emit(dragging_unit_data.unit_stats)
		unit.queue_free()



func emit_place_unit_signal(grid_pos: Vector2i) -> void:
	if dragging_unit_data.has("unit_instance"):
		print("  Emitindo sinal unit_placed_on_board")
		unit_placed_on_board.emit(dragging_unit_data.unit_instance, grid_pos)
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
		var hit_pos = result.position
		var local_pos = board.to_local(hit_pos)
		
		var total_cell_size = board.cell_size + board.cell_spacing
		var col = floor((local_pos.x + (board.columns * total_cell_size / 2.0)) / total_cell_size)
		var row = floor((local_pos.z + (board.rows * total_cell_size / 2.0)) / total_cell_size)
		return Vector2i(int(col), int(row))
		
	
	return Vector2i(-1, -1)
