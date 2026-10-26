class_name Board3D
extends Node3D

const RegionEnvironment = preload("res://Scripts/Environment/region_environment.gd")

@export var rows: int = 8
@export var columns: int = 7
@export var cell_size: float = 2.0
@export var cell_spacing: float = 0.12
@export var board_height: float = 0.0
@export var player_rows: int = 4

@export var cell_material: StandardMaterial3D
@export var hover_material: StandardMaterial3D
@export var occupied_material: StandardMaterial3D
@export var show_default_floor_mesh: bool = false
@export var environment_scene: PackedScene = preload("res://Scenes/Board/board_environment.tscn")

var units_on_board: Dictionary = {}
var hovered_cell: Vector2i = Vector2i(-1, -1)
var cell_meshes: Dictionary = {}
var cell_base_colors: Dictionary = {}
var generated_board: Node3D
var environment_instance: Node3D = null

const BENCH_SLOTS_COUNT: int = 9
const BENCH_Z: float = 8.375
const BENCH_SLOT_SPACING: float = 1.55
const BENCH_Y: float = 0.22

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

	if environment_scene and (not environment_instance or not is_instance_valid(environment_instance)):
		environment_instance = environment_scene.instantiate()
		environment_instance.name = "BoardEnvironmentInstance"
		add_child(environment_instance)

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
	floor_mesh.visible = show_default_floor_mesh
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

	var bench_body := StaticBody3D.new()
	bench_body.name = "BenchCollision"
	bench_body.collision_layer = 2
	var bench_shape := CollisionShape3D.new()
	var bench_box := BoxShape3D.new()
	bench_box.size = Vector3(BENCH_SLOTS_COUNT * BENCH_SLOT_SPACING + 1.2, 0.4, 2.7)
	bench_shape.shape = bench_box
	bench_shape.position = Vector3(0.0, BENCH_Y, BENCH_Z)
	bench_body.add_child(bench_shape)
	generated_board.add_child(bench_body)

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


func is_valid_cell(grid_pos: Vector2i) -> bool:
	return get_cell(grid_pos)


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
	if not units_on_board.has(grid_pos):
		return false
	var u: Node3D = units_on_board[grid_pos]
	if not is_instance_valid(u) or u.is_queued_for_deletion():
		units_on_board.erase(grid_pos)
		return false
	return true


func clear_enemy_zone() -> void:
	for row in range(rows - player_rows):
		for col in range(columns):
			var pos := Vector2i(col, row)
			if units_on_board.has(pos):
				units_on_board.erase(pos)


func is_player_zone(grid_pos: Vector2i) -> bool:
	return grid_pos.y >= rows - player_rows


func place_unit(unit: Node3D, grid_pos: Vector2i, animate: bool = true) -> bool:
	if not get_cell(grid_pos) or is_cell_occupied(grid_pos):
		return false
	var target_pos := get_cell_world_position(grid_pos)
	if animate and unit is BaseUnit3D:
		var tier: int = unit.stats.tier if unit.stats else 1
		var tween := create_tween()
		tween.set_ease(Tween.EASE_OUT)
		tween.set_trans(Tween.TRANS_BOUNCE)
		var drop_height := 0.45 + 0.12 * tier
		unit.global_position = target_pos + Vector3(0, drop_height, 0)
		tween.tween_property(unit, "global_position", target_pos, 0.28 + 0.03 * tier)
		create_placement_feedback(target_pos, tier)
		if tier >= 5 and unit.has_method("_trigger_camera_shake"):
			unit._trigger_camera_shake(0.3, 0.25)
	else:
		unit.global_position = target_pos
	if unit is BaseUnit3D:
		unit.board_position = grid_pos
		unit.cell_reference = null
		unit._update_status_visibility()
	units_on_board[grid_pos] = unit
	if unit is BaseUnit3D and not unit.died.is_connected(_on_unit_died):
		unit.died.connect(_on_unit_died)
	unit_placed.emit(unit, grid_pos)
	return true


func create_placement_feedback(pos: Vector3, tier: int) -> void:
	var tier_colors := {
		1: Color(0.85, 0.88, 0.92),  # Comum: Prata / Branco
		2: Color(0.25, 0.92, 0.45),  # Incomum: Verde Esmeralda
		3: Color(0.28, 0.68, 1.0),   # Raro: Azul Safira
		4: Color(0.78, 0.35, 1.0),   # Épico: Roxo Ametista
		5: Color(1.0, 0.75, 0.18),   # Lendário: Dourado Radiante
	}
	var col: Color = tier_colors.get(tier, Color.WHITE)
	
	# 1. Anel / Shockwave no chão se expandindo
	var ring := MeshInstance3D.new()
	var torus := TorusMesh.new()
	torus.inner_radius = 0.35
	torus.outer_radius = 0.50
	torus.ring_segments = 24
	ring.mesh = torus
	ring.position = pos + Vector3(0, 0.04, 0)
	ring.scale = Vector3(0.3, 0.05, 0.3)
	
	var ring_mat := StandardMaterial3D.new()
	ring_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	ring_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	ring_mat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	ring_mat.albedo_color = Color(col.r, col.g, col.b, 0.85)
	ring_mat.emission_enabled = true
	ring_mat.emission = col
	ring_mat.emission_energy_multiplier = 1.8 + tier * 0.4
	ring.material_override = ring_mat
	add_child(ring)
	
	var max_scale := 1.8 + tier * 0.45
	var duration := 0.35 + tier * 0.05
	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(ring, "scale", Vector3(max_scale, 0.05, max_scale), duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_property(ring_mat, "albedo_color:a", 0.0, duration).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	tw.chain().tween_callback(ring.queue_free)
	
	# 2. Partículas de impacto
	var particles := GPUParticles3D.new()
	particles.position = pos + Vector3(0, 0.1, 0)
	particles.one_shot = true
	particles.explosiveness = 0.92
	particles.amount = 10 + tier * 12
	particles.lifetime = 0.5 + tier * 0.1
	
	var p_proc := ParticleProcessMaterial.new()
	p_proc.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_RING
	p_proc.emission_ring_radius = 0.45
	p_proc.emission_ring_inner_radius = 0.15
	p_proc.direction = Vector3(0, 1, 0)
	p_proc.spread = 70.0
	p_proc.initial_velocity_min = 1.2 + tier * 0.5
	p_proc.initial_velocity_max = 2.4 + tier * 1.0
	p_proc.gravity = Vector3(0, -5.0, 0)
	p_proc.scale_min = 0.04 + tier * 0.015
	p_proc.scale_max = 0.08 + tier * 0.025
	p_proc.color = col
	particles.process_material = p_proc
	
	var p_mesh := SphereMesh.new()
	p_mesh.radius = 0.05
	p_mesh.height = 0.1
	var p_mat := StandardMaterial3D.new()
	p_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	p_mat.albedo_color = col
	p_mat.emission_enabled = true
	p_mat.emission = col
	p_mat.emission_energy_multiplier = 2.0
	p_mesh.material = p_mat
	particles.draw_pass_1 = p_mesh
	
	add_child(particles)
	particles.emitting = true
	get_tree().create_timer(particles.lifetime + 0.2, false).timeout.connect(particles.queue_free)
	
	# 3. Feixe vertical radiante para Épico (Tier 4) e Lendário (Tier 5)
	if tier >= 4:
		var beam := MeshInstance3D.new()
		var cyl := CylinderMesh.new()
		cyl.top_radius = 0.25 if tier == 4 else 0.45
		cyl.bottom_radius = 0.45 if tier == 4 else 0.75
		cyl.height = 3.0 if tier == 4 else 4.5
		beam.mesh = cyl
		beam.position = pos + Vector3(0, cyl.height * 0.5, 0)
		var beam_mat := StandardMaterial3D.new()
		beam_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		beam_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		beam_mat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
		beam_mat.albedo_color = Color(col.r, col.g, col.b, 0.45 if tier == 4 else 0.7)
		beam.material_override = beam_mat
		add_child(beam)
		var btw := create_tween()
		btw.set_parallel(true)
		btw.tween_property(beam, "scale", Vector3(1.4, 1.0, 1.4), 0.35).set_trans(Tween.TRANS_QUAD)
		btw.tween_property(beam_mat, "albedo_color:a", 0.0, 0.35).set_trans(Tween.TRANS_QUAD)
		btw.chain().tween_callback(beam.queue_free)


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
	for pos in units_on_board.keys():
		if units_on_board[pos] == unit:
			units_on_board.erase(pos)


func get_distance_between_cells(from: Vector2i, to: Vector2i) -> float:
	return get_cell_world_position(from).distance_to(get_cell_world_position(to))

func get_hex_distance(from: Vector2i, to: Vector2i) -> int:
	# Converte linhas ímpares deslocadas para coordenadas axiais.
	var from_q := from.x - floori(float(from.y) * 0.5)
	var to_q := to.x - floori(float(to.y) * 0.5)
	var dq := to_q - from_q
	var dr := to.y - from.y
	return maxi(absi(dq), maxi(absi(dr), absi(dq + dr)))

func get_cells_in_hex_radius(center: Vector2i, radius: int) -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	if not get_cell(center) or radius < 0:
		return cells
	for row in rows:
		for col in columns:
			var candidate := Vector2i(col, row)
			if get_hex_distance(center, candidate) <= radius:
				cells.append(candidate)
	return cells


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


func get_bench_slot_world_position(slot_index: int) -> Vector3:
	var x := (slot_index - 4) * BENCH_SLOT_SPACING
	return global_position + Vector3(x, BENCH_Y, BENCH_Z)


func is_bench_position(world_pos: Vector3) -> bool:
	var local_pos := to_local(world_pos)
	var max_half_width := (float(BENCH_SLOTS_COUNT) * 0.5) * BENCH_SLOT_SPACING
	return absf(local_pos.z - BENCH_Z) <= 1.35 and absf(local_pos.x) <= max_half_width


func get_bench_slot_from_world_position(world_pos: Vector3) -> int:
	var local_pos := to_local(world_pos)
	if absf(local_pos.z - BENCH_Z) > 1.35:
		return -1
	var slot := clampi(roundi((local_pos.x / BENCH_SLOT_SPACING) + 4.0), 0, BENCH_SLOTS_COUNT - 1)
	return slot


func apply_region_environment(new_region_id: String, duration: float = 0.0) -> void:
	var target_env: WorldEnvironment = get_node_or_null("WorldEnvironment")
	if not target_env and get_parent():
		target_env = get_parent().get_node_or_null("WorldEnvironment")
	if not target_env:
		target_env = find_child("WorldEnvironment", true, false)
	var target_sun: DirectionalLight3D = get_node_or_null("DirectionalLight3D")
	if not target_sun and get_parent():
		target_sun = get_parent().find_child("DirectionalLight3D", true, false)
	
	RegionEnvironment.apply_to(target_env, target_sun, new_region_id, duration)
