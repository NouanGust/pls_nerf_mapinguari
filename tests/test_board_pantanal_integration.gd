extends SceneTree

func _init() -> void:
	print("--- TEST BOARD PANTANAL INTEGRATION START ---")
	var root_node := Node3D.new()
	get_root().add_child(root_node)

	var world_env := WorldEnvironment.new()
	world_env.name = "WorldEnvironment"
	world_env.environment = Environment.new()
	root_node.add_child(world_env)

	var sun := DirectionalLight3D.new()
	sun.name = "DirectionalLight3D"
	root_node.add_child(sun)

	var board_scene := load("res://Scenes/Board/board.tscn") as PackedScene
	assert(board_scene != null, "board.tscn must load successfully")
	var board: Node3D = board_scene.instantiate()
	root_node.add_child(board)

	# 1. Test applying Pantanal environment
	print("1. Applying region pantanal...")
	board.call("apply_region_environment", "pantanal", 0.0)

	# Process a frame so _ready() runs on children
	await process_frame

	var env_inst: Node3D = board.get("environment_instance")
	assert(env_inst != null, "Environment instance must exist after apply_region_environment('pantanal')")
	assert(env_inst is PantanalBoard, "Environment instance must be PantanalBoard")
	print("   PantanalBoard instance verified: ", env_inst.name)

	# 2. Verify sunset lights
	var lights: Node3D = env_inst.get_node_or_null("PantanalSunsetLights")
	assert(lights != null, "PantanalSunsetLights must be created")
	assert(lights.get_node_or_null("PantanalSunsetSpot") != null, "PantanalSunsetSpot must exist")
	assert(lights.get_node_or_null("PantanalSkyFill") != null, "PantanalSkyFill must exist")
	assert(lights.get_node_or_null("PantanalBenchFill") != null, "PantanalBenchFill must exist")
	assert(lights.get_node_or_null("WaterChannelRimLight") != null, "WaterChannelRimLight must exist")
	print("   PantanalSunsetLights verified (SunsetSpot, SkyFill, BenchFill, WaterRim)")

	# 3. Verify water material and shader
	var water_mat: ShaderMaterial = env_inst.get("_water_material")
	assert(water_mat != null, "_water_material must be created")
	assert(water_mat.shader != null, "_water_material must have a valid shader")
	print("   Water shader verified: ", water_mat.shader.resource_path)

	# 4. Verify 3D model meshes in board_pantanal
	var glb_node: Node = env_inst.get_node_or_null("board_pantanal")
	assert(glb_node != null, "board_pantanal node must exist inside BoardEnvironmentPantanal")
	var found_water := false
	var found_canoe := false
	var found_oar := false
	var found_tree := false
	var stack: Array[Node] = [glb_node]
	while not stack.is_empty():
		var curr: Node = stack.pop_back()
		for child in curr.get_children():
			stack.append(child)
		var cname := curr.name.to_lower()
		if cname.contains("water"):
			found_water = true
		if cname.contains("canoe"):
			found_canoe = true
		if cname.contains("oar"):
			found_oar = true
		if cname.contains("tree"):
			found_tree = true

	assert(found_water, "Water mesh must exist in board_pantanal")
	assert(found_canoe, "Canoe mesh must exist in board_pantanal")
	assert(found_oar, "Oar mesh must exist in board_pantanal")
	assert(found_tree, "Tree mesh must exist in board_pantanal")
	print("   Model meshes verified: water, canoe, oar, tree")

	# 5. Verify cell transparency for realistic 3D sculpted board
	var cell_meshes: Dictionary = board.get("cell_meshes")
	assert(cell_meshes.size() == 56, "Must have 56 hex cell meshes")
	var cell_pos := Vector2i(0, 0)
	var first_cell: MeshInstance3D = cell_meshes[cell_pos]
	assert(first_cell != null, "First cell mesh must exist")
	var c_mat := first_cell.material_override as StandardMaterial3D
	assert(c_mat != null, "Cell must have StandardMaterial3D override")
	assert(c_mat.albedo_color.a == 0.0, "Sculpted Pantanal tiles must have rest alpha = 0.0 to reveal 3D clay surface")
	print("   56 cells verified with transparent rest alpha for 3D sculpt visibility")

	print("--- ALL PANTANAL BOARD INTEGRATION TESTS PASSED SUCCESSFULLY! ---")
	quit(0)
