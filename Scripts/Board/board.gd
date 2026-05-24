class_name Board3D
extends Node3D

@export var rows: int = 4
@export var columns: int = 7
@export var cell_size: float = 2.0
@export var cell_spacing: float = 0.2
@export var board_height: float = 0.0
@export var player_rows: int = 2

@export var cell_material: StandardMaterial3D
@export var hover_material: StandardMaterial3D
@export var occupied_material: StandardMaterial3D
#@export var player_zone_color: Color = Color(0.3, 0.5, 0.8, 0.3)
#@export var enemy_zone_color: Color = Color(0.8, 0.3, 0.3, 0.3)


var units_on_board: Dictionary = {}
var hovered_cell: Vector2i = Vector2i(-1, -1)

signal unit_placed(unit: Node3D, position: Vector2i)
signal unit_removed(unit: Node3D, position: Vector2i)
signal cell_hovered(position: Vector2i)
signal cell_clicked(position: Vector2i)

func _ready() -> void:
	if not cell_material:
		pass
		#create_default_materials()
	generate_board()

#func create_default_materials() -> void:
	cell_material = StandardMaterial3D.new()
	cell_material.albedo_color = Color(0.2, 0.3, 0.4, 0.8)
	cell_material.metallic = 0.3
	cell_material.roughness = 0.7
	cell_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	
	hover_material = StandardMaterial3D.new()
	hover_material.albedo_color = Color(0.8, 0.8, 0.3, 0.9)
	hover_material.metallic = 0.2
	hover_material.roughness = 0.6
	hover_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	hover_material.emission_enabled = true
	hover_material.emission = Color(0.5, 0.5, 0.2)
	hover_material.emission_energy_multiplier = 2.0
	
	occupied_material = StandardMaterial3D.new()
	occupied_material.albedo_color = Color(0.5, 0.5, 0.5, 0.7)
	occupied_material.metallic = 0.4
	occupied_material.roughness = 0.8
	occupied_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA

#func _input(event: InputEvent) -> void:
	#if event is InputEventMouseButton and event.pressed:
		#print("mouse clicado na posição %v" %event.position)
		
	#var camera: Camera3D = get_viewport().get_camera_3d()
	#if camera:
		#var from: Vector3 = camera.project_ray_origin(event.position)
		#var to: Vector3 = from + camera.project_ray_normal(event.position) * 1000
		
		#var space_state: PhysicsDirectSpaceState3D = get_world_3d().direct_space_state
		#var query := PhysicsRayQueryParameters3D.create(from, to)
		#query.collision_mask = 2
		
		#var result: Dictionary = space_state.intersect_ray(query)
		#if result:
			#print("hit detectado: %s" %result.collider.name)
		#else:
			#print("nenhum hit detectado")


func generate_board() -> void:
	# Limpar board antigo
	for child in get_children():
		child.queue_free()
		
	
	# 1 - Criar a malha visual
	var mesh_instance := MeshInstance3D.new()
	mesh_instance.name = "BoardMesh"
	var plane_mesh := PlaneMesh.new()
	var board_w = columns * (cell_size + cell_spacing)
	var board_d = rows * (cell_size + cell_spacing)
	plane_mesh.size = Vector2(board_w, board_d)
	mesh_instance.mesh = plane_mesh
	
	
	# 2 - Material do Shader
	
	var shader_mat := ShaderMaterial.new()
	shader_mat.shader = load("res://Scripts/Board/grid.gdshader")
	shader_mat.set_shader_parameter("board_dimensions", Vector2(columns, rows))
	shader_mat.set_shader_parameter("grid_size", cell_size + cell_spacing)
	shader_mat.set_shader_parameter("player_rows", player_rows)
	mesh_instance.material_override = shader_mat
	add_child(mesh_instance)
	
	# 3 - Colisão para o MOUSE
	
	var static_body := StaticBody3D.new()
	static_body.collision_layer = 2
	var collision_shape := CollisionShape3D.new()
	var box_shape := BoxShape3D.new()
	box_shape.size = Vector3(board_w, 0.1, board_d)
	collision_shape.shape = box_shape
	static_body.add_child(collision_shape)
	add_child(static_body)
	
	# 4 - Geometria de navegação
	
	create_navigation_geometry()

func create_division_line() -> void:
	# Criar linha visual separando as zonas
	var line_mesh := MeshInstance3D.new()
	line_mesh.name = "DivisionLine"
	var box := BoxMesh.new()
	
	var line_width: float = columns * (cell_size + cell_spacing)
	box.size = Vector3(line_width, 0.2, 0.15)
	line_mesh.mesh = box
	
	# Material dourado/amarelo para a linha
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(1.0, 0.8, 0.0, 0.9)  # Dourado
	mat.metallic = 0.9
	mat.roughness = 0.1
	mat.emission_enabled = true
	mat.emission = Color(1.0, 0.8, 0.0)
	mat.emission_energy_multiplier = 1.5
	line_mesh.material_override = mat
	
	# Posicionar entre as zonas
	var start_z: float = -(rows * (cell_size + cell_spacing)) / 2.0
	var enemy_rows: int = rows - player_rows
	var player_zone_start_z: float = start_z + enemy_rows * (cell_size + cell_spacing)
	var division_z: float = player_zone_start_z - (cell_spacing / 2.0)
	line_mesh.position = Vector3(0, 0.15, division_z)
	
	add_child(line_mesh)
	print("\nLinha divisória criada:")
	print("   Rows totais: %d" % rows)
	print("   Enemy rows: %d (0-%d)" % [enemy_rows, enemy_rows - 1])
	print("   Player rows: %d (%d-%d)" % [player_rows, enemy_rows, rows - 1])
	print("   Start Z: %.2f" % start_z)
	print("   Division Z: %.2f" % division_z)

#func create_cell(row: int, col: int) -> bool:
	#
	#cell.name = "Cell_%d_%d" % [row, col]
	#cell.grid_position = Vector2i(col, row)
	#
	## Determinar se é zona do jogador (LINHAS 0 e 1) ou inimiga (LINHAS 2 e 3)
	#var is_player_zone: bool = row >=(rows - player_rows)
	#cell.is_player_zone = is_player_zone
	#
	## Aplicar cores VIBRANTES
	#var zone_color: Color
	#if is_player_zone:
		#zone_color = Color(0.2, 0.5, 0.9, 0.75)  
		#print("Célula [%d,%d] = AZUL (Jogador)" % [row, col])
	#else:
		#zone_color = Color(0.9, 0.2, 0.2, 0.75)  
		#print("Célula [%d,%d] = VERMELHO (Inimigo)" % [row, col])
	#
	#cell.set_base_color(zone_color)
	#
	#cell.cell_clicked.connect(_on_cell_clicked)
	#cell.cell_hovered.connect(_on_cell_hovered)
	#
	#return cell

func get_cell(grid_pos: Vector2i) -> bool:
	if grid_pos.y < 0 or grid_pos.y >= rows: return false
	if grid_pos.x < 0 or grid_pos.x >= columns: return false
	return true
	
	

func get_cell_world_position(grid_pos: Vector2i) -> Vector3:
	var total_cell_size = cell_size + cell_spacing
	
	var start_x: float = -(columns * total_cell_size) / 2.0 + (total_cell_size / 2.0)
	var start_z: float = -(rows * total_cell_size) / 2.0 + (total_cell_size / 2.0)
	
	var x_pos = start_x + (grid_pos.x * total_cell_size) 
	var z_pos = start_z + (grid_pos.y * total_cell_size)
	return global_position + Vector3(x_pos, board_height, z_pos)

func is_cell_occupied(grid_pos: Vector2i) -> bool:
	return units_on_board.has(grid_pos)

func is_player_zone(grid_pos: Vector2i) -> bool:
	return grid_pos.y >= (rows - player_rows)

func place_unit(unit: Node3D, grid_pos: Vector2i, animate: bool = true) -> bool:
	if is_cell_occupied(grid_pos):
		return false
	
	var target_pos: Vector3 = get_cell_world_position(grid_pos)
	
	if animate and unit is BaseUnit3D:
		unit.global_position = target_pos + Vector3(0, 0, 0)
		var tween: Tween = create_tween()
		tween.set_ease(Tween.EASE_OUT)
		tween.set_trans(Tween.TRANS_BOUNCE)
		tween.tween_property(unit, "global_position", target_pos, 0.5)
	else:
		unit.global_position = target_pos
	
	if unit is BaseUnit3D:
		unit.board_position = grid_pos
		unit.cell_reference = null
	
	units_on_board[grid_pos] = unit
	
	# Notificar o Shader para hover
	
	if unit is BaseUnit3D and not unit.died.is_connected(_on_unit_died):
		unit.died.connect(_on_unit_died)
	
	unit_placed.emit(unit, grid_pos)
	return true

func move_unit(from_pos: Vector2i, to_pos: Vector2i, animate: bool = true) -> bool:
	if not units_on_board.has(from_pos):
		return false
	
	if is_cell_occupied(to_pos):
		return false
	
	var unit: Node3D = units_on_board[from_pos]
	#var from_cell: GridCell3D = get_cell(from_pos)
	
	units_on_board.erase(from_pos)
	#if from_cell:
		#from_cell.set_occupied(false)
	
	return place_unit(unit, to_pos, animate)

func remove_unit(grid_pos: Vector2i) -> Node3D:
	if not units_on_board.has(grid_pos):
		return null
	
	var unit: Node3D = units_on_board[grid_pos]
	units_on_board.erase(grid_pos)
	
	#var cell: GridCell3D = get_cell(grid_pos)
	#if cell:
		#cell.set_occupied(false)
	
	unit_removed.emit(unit, grid_pos)
	return unit

func get_unit_at(grid_pos: Vector2i) -> Node3D:
	return units_on_board.get(grid_pos, null)

func get_all_units() -> Array:
	var valid_units: Array = []
	var invalid_positions: Array[Vector2i] = []
	
	for pos in units_on_board.keys():
		var unit = units_on_board[pos]
		
		if is_instance_valid(unit):
			valid_units.append(unit)
		else:
			invalid_positions.append(pos)
	for pos in invalid_positions:
		units_on_board.erase(pos)
		
	return valid_units

func clear_board() -> void:
	for unit in units_on_board.values():
		if is_instance_valid(unit):
			unit.queue_free()
	units_on_board.clear()
	
	#for row in cells:
		#for cell in row:
			#if cell:
				#cell.set_occupied(false)

func highlight_cell(grid_pos: Vector2i, highlight: bool = true) -> void:
	var mesh: MeshInstance3D = get_node_or_null("BoardMesh")
	if mesh and mesh.material_override is ShaderMaterial: 
		mesh.material_override.set_shader_parameter("hover_pos", Vector2(grid_pos.x, grid_pos.y))
	else:
		mesh.material_override.set_shader_parameter("hover_pos", Vector2(-1, -1))
		
		

func highlight_valid_placements(unit_team: int) -> void:
	#clear_all_highlights()
	
	for row in rows:
		for col in columns:
			var grid_pos: Vector2i = Vector2i(col, row)
			var is_valid: bool = not is_cell_occupied(grid_pos)
			
			if unit_team == 0:
				is_valid = is_valid and is_player_zone(grid_pos)
			
			if is_valid:
				highlight_cell(grid_pos, true)

#func clear_all_highlights() -> void:
	#for row in cells:
		#for cell in row:
			#if cell:
				#cell.set_highlighted(false)

func _on_cell_clicked(grid_pos: Vector2i) -> void:
	cell_clicked.emit(grid_pos)

func _on_cell_hovered(grid_pos: Vector2i) -> void:
	if hovered_cell != grid_pos:
		hovered_cell = grid_pos
		cell_hovered.emit(grid_pos)

func _on_unit_died(unit: Node3D) -> void:
	if unit is BaseUnit3D:
		var pos: Vector2i = unit.board_position
		if units_on_board.has(pos) and units_on_board[pos] == unit:
			units_on_board.erase(pos)
			#var cell: GridCell3D = get_cell(pos)
			#if cell:
				#cell.set_occupied(false)

func get_distance_between_cells(from: Vector2i, to: Vector2i) -> float:
	var from_pos: Vector3 = get_cell_world_position(from)
	var to_pos: Vector3 = get_cell_world_position(to)
	return from_pos.distance_to(to_pos)

func get_neighbors(grid_pos: Vector2i, diagonal: bool = false) -> Array[Vector2i]:
	var neighbors: Array[Vector2i] = []
	var directions: Array[Vector2i] = [
		Vector2i(0, 1), Vector2i(0, -1),
		Vector2i(1, 0), Vector2i(-1, 0)
	]
	
	if diagonal:
		directions.append_array([
			Vector2i(1, 1), Vector2i(1, -1),
			Vector2i(-1, 1), Vector2i(-1, -1)
		])
	
	for dir in directions:
		var neighbor: Vector2i = grid_pos + dir
		if get_cell(neighbor):
			neighbors.append(neighbor)
	
	return neighbors
	
func create_navigation_geometry() -> void:
	# Criar um plano sólido para navegação
	var nav_plane := StaticBody3D.new()
	nav_plane.name = "NavigationGeometry"
	nav_plane.collision_layer = 4  # Layer 3 (para não interferir com células)
	nav_plane.collision_mask = 0
	
	# Mesh visual (opcional, para debug)
	var mesh_instance := MeshInstance3D.new()
	var plane_mesh := BoxMesh.new()
	
	var board_width: float = columns * (cell_size + cell_spacing)
	var board_depth: float = rows * (cell_size + cell_spacing)
	
	plane_mesh.size = Vector3(board_width, 0.05, board_depth)
	mesh_instance.mesh = plane_mesh
	
	# Material semi-transparente
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.2, 0.2, 0.2, 0.3)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mesh_instance.material_override = mat
	
	nav_plane.add_child(mesh_instance)
	
	# Collision shape para navegação
	var collision_shape := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(board_width, 0.05, board_depth)
	collision_shape.shape = shape
	nav_plane.add_child(collision_shape)
	
	# Posicionar ligeiramente abaixo do board
	nav_plane.position = Vector3(0, -0.1, 0)
	
	add_child(nav_plane)
	
	print("Geometria de navegação criada")
