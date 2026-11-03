extends SceneTree

func _init():
	print("--- TEST BOARD CAATINGA INTEGRATION START ---")
	var board_scene = load("res://Scenes/Board/board.tscn")
	assert(board_scene != null, "board.tscn failed to load")
	
	var board = board_scene.instantiate() as Board3D
	assert(board != null, "Failed to instantiate Board3D")
	root.add_child(board)
	
	print("1. Initial board generated, environment: ", board.environment_instance.name if board.environment_instance else "none")
	
	# Apply Caatinga
	print("2. Applying region caatinga...")
	board.apply_region_environment("caatinga")
	assert(board.environment_instance != null, "environment_instance is null after applying caatinga")
	print("   Environment instance: ", board.environment_instance.name)
	assert("caatinga" in board.environment_instance.scene_file_path.to_lower() or "caatinga" in board.environment_instance.name.to_lower(), "Caatinga scene not loaded!")
	print("   Environment scene path: ", board.environment_instance.scene_file_path)
	
	# Apply Cerrado (fallback)
	print("3. Applying region cerrado...")
	board.apply_region_environment("cerrado")
	assert(board.environment_instance != null, "environment_instance is null after applying cerrado")
	print("   Environment scene path: ", board.environment_instance.scene_file_path)
	
	# Switch back to Caatinga
	print("4. Switching back to caatinga...")
	board.apply_region_environment("caatinga")
	print("   Environment scene path: ", board.environment_instance.scene_file_path)
	
	print("--- ALL INTEGRATION TESTS PASSED SUCCESSFULLY! ---")
	quit()

