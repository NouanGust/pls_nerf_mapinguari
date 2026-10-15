class_name Board3D
extends Node3D

@export var rows: int = 8
@export var columns: int = 7
@export var cell_size: float = 2.0
@export var cell_spacing: float = 0.12
@export var board_height: float = 0.0
@export var player_rows: int = 4

@export var cell_material: StandardMaterial3D
@export var hover_material: StandardMaterial3D
@export var occupied_material: StandardMaterial3D

var units_on_board: Dictionary = {}
var hovered_cell: Vector2i = Vector2i(-1, -1)
var cell_meshes: Dictionary = {}
var cell_base_colors: Dictionary = {}
var generated_board: Node3D

signal unit_placed(unit: Node3D, position: Vector2i)
signal unit_removed(unit: Node3D, position: Vector2i)
signal cell_hovered(position: Vector2i)
signal cell_clicked(position: Vector2i)


func _ready() -> void:
	generate_board()


func get_hex_radius() -> float:
	return cell_size * 0.5


func get_horizontal_pitch() -> float:
	return get_hex_radius() * sqrt(3.0) + cell_spacing


func get_vertical_pitch() -> float:
	return get_hex_radius() * 1.5 + cell_spacing


func get_board_extents() -> Vector2:
	var radius := get_hex_radius()
	var width := radius * 2.0 + maxf(columns - 1, 0) * get_horizontal_pitch()
	if rows > 1:
		width += get_horizontal_pitch() * 0.5
	var depth := radius * 2.0 + maxf(rows - 1, 0) * get_vertical_pitch()
	return Vector2(width, depth)


func generate_board() -> void:
	if generated_board and is_instance_valid(generated_board):
		generated_board.queue_free()
	generated_board = Node3D.new()
	generated_board.name = "GeneratedBoard"
	add_child(generated_board)
	cell_meshes.clear()
	cell_base_colors.clear()

	var extents := get_board_extents()
	var floor_mesh := MeshInstance3D.new()
	floor_mesh.name = "BoardMesh"
	var plane := PlaneMesh.new()
	plane.size = extents + Vector2(0.8, 0.8)
	floor_mesh.mesh = plane
	var floor_material := StandardMaterial3D.new()
	floor_material.albedo_color = Color("#463b34")
	floor_material.roughness = 0.94
	floor_mesh.material_override = floor_material
	generated_board.add_child(floor_mesh)

	var static_body := StaticBody3D.new()
	static_body.name = "BoardCollision"
	static_body.collision_layer = 2
	var collision := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(extents.x + 0.8, 0.1, extents.y + 0.8)
	collision.shape = box
	static_body.add_child(collision)
	generated_board.add_child(static_body)

	for row in rows:
		for col in columns:
			_create_hex_cell(Vector2i(col, row))

	create_navigation_geometry()


func _create_hex_cell(grid_pos: Vector2i) -> void:
	var cell := Node3D.new()
	cell.name = "Hex_%d_%d" % [grid_pos.x, grid_pos.y]
	cell.position = get_cell_world_position(grid_pos) - global_position
	generated_board.add_child(cell)

	var is_player := is_player_zone(grid_pos)
	var base_color := Color("#4b777b") if is_player else Color("#74614f")
	cell_base_colors[grid_pos] = base_color

	var outline := MeshInstance3D.new()
	var outline_mesh := CylinderMesh.new()
	outline_mesh.top_radius = get_hex_radius()
	outline_mesh.bottom_radius = get_hex_radius()
	outline_mesh.height = 0.055
	outline_mesh.radial_segments = 6
	outline.mesh = outline_mesh
	outline.position.y = 0.035
	var outline_material := StandardMaterial3D.new()
	outline_material.albedo_color = Color("#251f1c")
	outline_material.roughness = 0.86
	outline.material_override = outline_material
	cell.add_child(outline)

	var inset := MeshInstance3D.new()
	inset.name = "Surface"
	var inset_mesh := CylinderMesh.new()
	inset_mesh.top_radius = get_hex_radius() * 0.91
	inset_mesh.bottom_radius = get_hex_radius() * 0.91
	inset_mesh.height = 0.035
	inset_mesh.radial_segments = 6
	inset.mesh = inset_mesh
	inset.position.y = 0.075
	var material := StandardMaterial3D.new()
	material.albedo_color = base_color
	material.roughness = 0.78
	material.metallic = 0.08
	inset.material_override = material
	cell.add_child(inset)
	cell_meshes[grid_pos] = inset


func get_cell(grid_pos: Vector2i) -> bool:
	return grid_pos.x >= 0 and grid_pos.x < columns and grid_pos.y >= 0 and grid_pos.y < rows


func get_cell_world_position(grid_pos: Vector2i) -> Vector3:
	var extents := get_board_extents()
	var x := -extents.x * 0.5 + get_hex_radius() + grid_pos.x * get_horizontal_pitch()
	if grid_pos.y % 2 == 1:
		x += get_horizontal_pitch() * 0.5
	var z := -extents.y * 0.5 + get_hex_radius() + grid_pos.y * get_vertical_pitch()
	return global_position + Vector3(x, board_height, z)


func get_grid_position(local_position: Vector3) -> Vector2i:
	var closest := Vector2i(-1, -1)
	var closest_distance := INF
	for row in rows:
		for col in columns:
			var candidate := Vector2i(col, row)
			var center := to_local(get_cell_world_position(candidate))
			var distance := Vector2(local_position.x, local_position.z).distance_to(Vector2(center.x, center.z))
			if distance < closest_distance:
				closest_distance = distance
				closest = candidate
	if closest_distance <= get_hex_radius() * 1.08:
		return closest
	return Vector2i(-1, -1)


func is_cell_occupied(grid_pos: Vector2i) -> bool:
	return units_on_board.has(grid_pos)


func is_player_zone(grid_pos: Vector2i) -> bool:
	return grid_pos.y >= rows - player_rows


func place_unit(unit: Node3D, grid_pos: Vector2i, animate: bool = true) -> bool:
	if not get_cell(grid_pos) or is_cell_occupied(grid_pos):
		return false
	var target_pos := get_cell_world_position(grid_pos)
	if animate and unit is BaseUnit3D:
		var tween := create_tween()
		tween.set_ease(Tween.EASE_OUT)
		tween.set_trans(Tween.TRANS_BOUNCE)
		unit.global_position = target_pos + Vector3(0, 0.5, 0)
		tween.tween_property(unit, "global_position", target_pos, 0.35)
	else:
		unit.global_position = target_pos
	if unit is BaseUnit3D:
		unit.board_position = grid_pos
		unit.cell_reference = null
	units_on_board[grid_pos] = unit
	if unit is BaseUnit3D and not unit.died.is_connected(_on_unit_died):
		unit.died.connect(_on_unit_died)
	unit_placed.emit(unit, grid_pos)
	return true


func move_unit(from_pos: Vector2i, to_pos: Vector2i, animate: bool = true) -> bool:
	if not units_on_board.has(from_pos) or is_cell_occupied(to_pos):
		return false
	var unit: Node3D = units_on_board[from_pos]
	units_on_board.erase(from_pos)
	return place_unit(unit, to_pos, animate)


func remove_unit(grid_pos: Vector2i) -> Node3D:
	if not units_on_board.has(grid_pos):
		return null
	var unit: Node3D = units_on_board[grid_pos]
	units_on_board.erase(grid_pos)
	unit_removed.emit(unit, grid_pos)
	return unit


func get_unit_at(grid_pos: Vector2i) -> Node3D:
	return units_on_board.get(grid_pos, null)


func get_all_units() -> Array:
	var valid_units: Array = []
	for pos in units_on_board.keys():
		var unit = units_on_board[pos]
		if is_instance_valid(unit):
			valid_units.append(unit)
		else:
			units_on_board.erase(pos)
	return valid_units


func clear_board() -> void:
	for unit in units_on_board.values():
		if is_instance_valid(unit):
			unit.queue_free()
	units_on_board.clear()


func highlight_cell(grid_pos: Vector2i, highlight: bool = true, highlight_color: Color = Color(0.9, 0.78, 0.4)) -> void:
	var mesh: MeshInstance3D = cell_meshes.get(grid_pos)
	if not mesh:
		return
	var material := mesh.material_override as StandardMaterial3D
	if material:
		material.albedo_color = highlight_color if highlight else cell_base_colors[grid_pos]
		material.emission_enabled = highlight
		material.emission = highlight_color.darkened(0.45) if highlight else Color.BLACK
		material.emission_energy_multiplier = 0.55


func highlight_valid_placements(unit_team: int) -> void:
	for row in rows:
		for col in columns:
			var grid_pos := Vector2i(col, row)
			if not is_cell_occupied(grid_pos) and (unit_team != 0 or is_player_zone(grid_pos)):
				highlight_cell(grid_pos, true)


func _on_cell_clicked(grid_pos: Vector2i) -> void:
	cell_clicked.emit(grid_pos)


func _on_cell_hovered(grid_pos: Vector2i) -> void:
	if hovered_cell != grid_pos:
		hovered_cell = grid_pos
		cell_hovered.emit(grid_pos)


func _on_unit_died(unit: Node3D) -> void:
	if unit is BaseUnit3D:
		var pos: Vector2i = unit.board_position
		if units_on_board.get(pos) == unit:
			units_on_board.erase(pos)


func get_distance_between_cells(from: Vector2i, to: Vector2i) -> float:
	return get_cell_world_position(from).distance_to(get_cell_world_position(to))


func get_neighbors(grid_pos: Vector2i, diagonal: bool = false) -> Array[Vector2i]:
	var neighbors: Array[Vector2i] = []
	var parity := grid_pos.y % 2
	var offsets: Array[Vector2i]
	if parity == 0:
		offsets = [Vector2i(-1, -1), Vector2i(0, -1), Vector2i(-1, 0), Vector2i(1, 0), Vector2i(-1, 1), Vector2i(0, 1)]
	else:
		offsets = [Vector2i(0, -1), Vector2i(1, -1), Vector2i(-1, 0), Vector2i(1, 0), Vector2i(0, 1), Vector2i(1, 1)]
	for offset in offsets:
		var neighbor := grid_pos + offset
		if get_cell(neighbor):
			neighbors.append(neighbor)
	return neighbors


func create_navigation_geometry() -> void:
	var nav_plane := StaticBody3D.new()
	nav_plane.name = "NavigationGeometry"
	nav_plane.collision_layer = 4
	nav_plane.collision_mask = 0
	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	var extents := get_board_extents()
	shape.size = Vector3(extents.x, 0.05, extents.y)
	collision.shape = shape
	nav_plane.add_child(collision)
	nav_plane.position.y = -0.1
	generated_board.add_child(nav_plane)
