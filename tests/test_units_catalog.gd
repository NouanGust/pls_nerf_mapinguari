extends SceneTree

func _initialize():
	call_deferred("_run")

func _run():
	print("--- TESTING ALL 66 UNITS IN CATALOG ---")
	var units = UnitSpawner.load_all_units()
	print("Total loaded units: %d" % units.size())
	assert(units.size() == 66, "Expected 66 units loaded, got %d" % units.size())
	
	var origins_count = {}
	var roles_count = {}
	var costs_count = {}
	
	for unit_id in units:
		var u: UnitStats = units[unit_id]
		assert(u.is_valid(), "Unit %s is not valid!" % unit_id)
		assert(u.origins.size() == 2, "Unit %s does not have 2 origins!" % unit_id)
		
		for o in u.origins:
			origins_count[o] = origins_count.get(o, 0) + 1
			
		var r = u.get_combat_role()
		roles_count[r] = roles_count.get(r, 0) + 1
		costs_count[u.cost] = costs_count.get(u.cost, 0) + 1
		
	print("Origins counts: ", origins_count)
	print("Roles counts: ", roles_count)
	print("Costs counts: ", costs_count)
	
	assert(origins_count["Seiva"] == 14, "Seiva count != 14")
	assert(origins_count["Correnteza"] == 14, "Correnteza count != 14")
	assert(origins_count["Vozes"] == 12, "Vozes count != 12")
	assert(origins_count["Vigília"] == 20, "Vigilia count != 20")
	assert(origins_count["Travessia"] == 17, "Travessia count != 17")
	assert(origins_count["Ferocidade"] == 17, "Ferocidade count != 17")
	assert(origins_count["Assombro"] == 17, "Assombro count != 17")
	assert(origins_count["Encanto"] == 14, "Encanto count != 14")
	assert(origins_count["Fulgor"] == 7, "Fulgor count != 7")
	
	assert(roles_count["Tank"] == 13, "Tank count != 13")
	assert(roles_count["Conjurador"] == 12, "Conjurador count != 12")
	assert(roles_count["Atacante"] == 7, "Atacante count != 7")
	assert(roles_count["Assassino"] == 8, "Assassino count != 8")
	assert(roles_count["Suporte"] == 14, "Suporte count != 14")
	assert(roles_count["Porradeiro"] == 12, "Porradeiro count != 12")
	
	print("ALL 66 UNITS VALIDATED SUCCESSFULLY!")
	quit(0)
