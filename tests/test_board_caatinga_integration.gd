extends SceneTree

func _init() -> void:
	call_deferred("_run_tests")

func _run_tests() -> void:
	print("--- TEST BOARD CAATINGA INTEGRATION & HORROR + DEFEAT REVIVE FREEZE START ---")
	var board_scene := load("res://Scenes/Board/board.tscn") as PackedScene
	assert(board_scene != null, "board.tscn failed to load")

	var board := board_scene.instantiate() as Board3D
	assert(board != null, "Failed to instantiate Board3D")
	root.add_child(board)
	await process_frame

	print("1. Applying region caatinga (horror variant)...")
	board.caatinga_board_style = "horror"
	board.apply_region_environment("caatinga")
	await process_frame
	assert(board.environment_instance != null, "environment_instance is null after applying caatinga")
	assert(board.environment_instance is CaatingaBoardHorror, "Caatinga horror environment must attach CaatingaBoardHorror controller!")

	var horror := board.environment_instance as CaatingaBoardHorror
	assert(horror.get_node_or_null("FullMoonBackdrop") != null, "FullMoonBackdrop must exist in Caatinga horror scene")
	assert(horror.get_node_or_null("CanyonHorrorLights") != null, "CanyonHorrorLights must exist in Caatinga horror scene")
	assert(horror.get_node_or_null("AridSandWindBorders") != null, "AridSandWindBorders must exist in Caatinga horror scene")
	assert(horror.get_node_or_null("CrystallineGroundGlints") != null, "CrystallineGroundGlints must exist in Caatinga horror scene")
	assert(horror.get_node_or_null("MataBrancaWatchers") != null, "MataBrancaWatchers must exist in Caatinga horror scene")
	assert(horror._breathing_nodes.size() >= 6, "Must collect breathing ossuary/boulder formations from GLB (found %d)" % horror._breathing_nodes.size())
	assert(horror._swaying_trees.size() >= 10, "Must collect Mata Branca bone-trees from GLB (found %d)" % horror._swaying_trees.size())
	print("   Horror nodes verified: breathing=%d, trees=%d" % [horror._breathing_nodes.size(), horror._swaying_trees.size()])

	# Verify breathing animation updates scale over frames
	var sample_ossuary: Node3D = horror._breathing_nodes[0]
	var initial_scale: Vector3 = sample_ossuary.scale
	horror._process(0.8)
	assert(sample_ossuary.scale != initial_scale, "Breathing ossuary must subtly contract/expand over time")

	print("1b. Testing new Realistic Caatinga board option (without modifying existing horror option)...")
	board.caatinga_board_style = "realista"
	board.apply_region_environment("caatinga_realista")
	await process_frame
	assert(board.environment_instance != null, "environment_instance is null after applying caatinga_realista")
	assert(board.environment_instance is CaatingaBoardRealista, "caatinga_realista must instantiate CaatingaBoardRealista!")
	var realista := board.environment_instance as CaatingaBoardRealista
	assert(realista.get_node_or_null("RealisticHorizonMoon") == null, "RealisticHorizonMoon must NOT exist (moon removed as requested)")
	assert(realista.get_node_or_null("RealisticSertaoLights/ArenaTacticalMoonSpot") != null, "ArenaTacticalMoonSpot must exist in RealisticSertaoLights")
	assert(realista.get_node_or_null("RealisticSertaoLights/OverheadSkyFill") != null, "OverheadSkyFill must exist in RealisticSertaoLights")
	assert(realista.get_node_or_null("RealisticDryDustBreeze") != null, "RealisticDryDustBreeze must exist in realistic Caatinga scene")
	assert(realista._swaying_trees.size() >= 115, "Realistic Caatinga must contain dense amphitheater White Forest (>=115 trees, found %d)" % realista._swaying_trees.size())
	assert(realista._breathing_nodes.size() >= 15, "Realistic Caatinga must contain lajeiros and horror anomaly nodes (found %d)" % realista._breathing_nodes.size())
	assert(board.cell_base_colors[Vector2i(0, 0)].a <= 0.16, "Realistic Caatinga base cell overlay must remain subtle so chiseled clay hexes show cleanly")
	print("   Realistic Caatinga verified: trees=%d, lajeiros/anomalies=%d" % [realista._swaying_trees.size(), realista._breathing_nodes.size()])

	# Switch back to standard horror Caatinga to confirm both coexist cleanly
	board.caatinga_board_style = "horror"
	board.apply_region_environment("caatinga")
	await process_frame
	assert(board.environment_instance is CaatingaBoardHorror, "Switching back to horror Caatinga must restore CaatingaBoardHorror!")

	# Verify defeat revival freeze (units must NOT continue fighting after revive while report is open)
	print("2. Testing defeat revival freeze (no post-defeat fighting before report confirmation)...")
	var unit_scene := load("res://Scenes/Units/base_unit_3d.tscn") as PackedScene
	var stats_res := UnitStats.new()
	stats_res.unit_name = "CalangoTeste"
	stats_res.max_health = 500
	stats_res.attack_damage = 45
	stats_res.attack_speed = 1.0
	stats_res.attack_range = 1.5
	stats_res.max_mana = 100
	stats_res.starting_mana = 0

	var player_unit := unit_scene.instantiate() as BaseUnit3D
	player_unit.stats = stats_res
	player_unit.team = 0
	root.add_child(player_unit)
	board.place_unit(player_unit, Vector2i(3, 5), false)

	var enemy_unit := unit_scene.instantiate() as BaseUnit3D
	enemy_unit.stats = stats_res
	enemy_unit.team = 1
	root.add_child(enemy_unit)
	board.place_unit(enemy_unit, Vector2i(3, 4), false)

	await process_frame
	player_unit.start_combat()
	enemy_unit.start_combat()
	assert(player_unit.in_combat == true, "Player unit should be in combat initially")
	assert(enemy_unit.in_combat == true, "Enemy unit should be in combat initially")

	# Simulate player unit dying and combat ending in defeat
	player_unit.die()
	assert(player_unit.current_state == BaseUnit3D.State.DEAD, "Player unit must be DEAD")

	# Freeze surviving enemy as end_combat does
	enemy_unit.in_combat = false
	if enemy_unit.attack_timer:
		enemy_unit.attack_timer.stop()
	enemy_unit.current_target = null
	enemy_unit.current_state = BaseUnit3D.State.IDLE

	# Revive player unit at home position (as revive_dead_player_units does before CombatReport confirmation)
	var home_pos := board.get_cell_world_position(player_unit.board_position)
	player_unit.revive_at_position(home_pos)
	board.place_unit(player_unit, player_unit.board_position, false)

	assert(player_unit.in_combat == false, "Revived player unit MUST have in_combat == false so it does not fight during damage report!")
	assert(player_unit.current_state == BaseUnit3D.State.IDLE, "Revived player unit MUST remain IDLE")

	# Simulate several physics ticks while enemy is still on the board
	for i in range(15):
		player_unit._physics_process(0.1)
		enemy_unit._physics_process(0.1)

	assert(player_unit.current_target == null, "Revived player unit must NOT acquire a target while out of combat!")
	assert(player_unit.current_state == BaseUnit3D.State.IDLE, "Revived player unit must remain IDLE during report screen!")
	assert(enemy_unit.current_target == null, "Surviving enemy unit must NOT acquire a target while out of combat!")
	assert(enemy_unit.current_state == BaseUnit3D.State.IDLE, "Surviving enemy unit must remain IDLE during report screen!")

	print("--- ALL CAATINGA HORROR & DEFEAT FREEZE TESTS PASSED SUCCESSFULLY! ---")
	quit()
