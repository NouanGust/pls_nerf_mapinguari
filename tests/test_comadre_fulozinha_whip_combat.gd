extends SceneTree

const UnitSpawner = preload("res://Scripts/Systems/unit_spawner.gd")
const BaseUnit3D = preload("res://Scripts/Units/base_unit.gd")

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	print("==================================================")
	print("TESTE: ATAQUE DE CHICOTE DA COMADRE FULOZINHA")
	print("==================================================")

	# 1. Spawn Comadre Fulozinha (Player side, team 0)
	var stats_fulo: UnitStats = UnitSpawner.load_unit_stats("comadre_fulozinha")
	assert(stats_fulo != null, "Falha ao carregar stats da comadre_fulozinha")
	var fulo: BaseUnit3D = UnitSpawner.spawn_unit_from_stats(stats_fulo, 1, 0)
	assert(fulo != null, "Falha ao instanciar BaseUnit3D para comadre_fulozinha")
	root.add_child(fulo)
	fulo.board_position = Vector2i(2, 2)
	fulo.global_position = Vector3(0, 0, 0)

	# 2. Spawn Target Dummy (Enemy team 1)
	var stats_target: UnitStats = UnitSpawner.load_unit_stats("capivara")
	assert(stats_target != null, "Falha ao carregar unidade alvo capivara")
	var target_unit: BaseUnit3D = UnitSpawner.spawn_unit_from_stats(stats_target, 1, 1)
	assert(target_unit != null, "Falha ao instanciar target")
	root.add_child(target_unit)
	target_unit.board_position = Vector2i(2, 4)
	target_unit.global_position = Vector3(0, 0, -2.0) # Em alcance de ataque (range 3 hexes ~ 4.5m)

	await process_frame
	await process_frame

	fulo.current_target = target_unit
	fulo.in_combat = true
	var hp_before: float = target_unit.current_health
	print("Distância até o alvo: ", fulo.global_position.distance_to(target_unit.global_position))
	print("Alcance de ataque (m): ", fulo.get_attack_range_meters())
	print("HP do alvo antes do ataque: ", hp_before)

	# 3. Executar perform_attack via CombatActionComponent
	var combat_comp = fulo.combat_action_comp
	assert(combat_comp != null, "combat_action_comp deve existir")
	
	print("Executando ataque de chicote...")
	combat_comp.perform_attack()

	# Verificar se o efeito de chicote foi instanciado
	var whip_node: Node = null
	for child in root.get_children():
		if "WhipLash" in child.name:
			whip_node = child
			break
	if not whip_node:
		for child in fulo.get_children():
			if "WhipLash" in child.name:
				whip_node = child
				break
	print("Whip node encontrado: ", whip_node.name if whip_node else "Nenhum")
	assert(whip_node != null, "O chicote deve criar o nó ComadreFulozinhaWhipLash!")

	# Verificar que animação de ataque foi acionada
	var anim_player: AnimationPlayer = fulo.unit_visual.animation_player
	print("Animação ativa durante ataque: ", anim_player.current_animation)
	assert(anim_player.current_animation == "Attack", "Deveria estar tocando Attack")

	# Aguardar o chicote estalar e causar dano (duração 0.22s)
	for i in range(25):
		await process_frame

	var hp_after: float = target_unit.current_health
	print("HP do alvo após o estalo do chicote: ", hp_after)
	assert(hp_after < hp_before, "O ataque com o chicote deve causar dano físico ao alvo!")
	print("✓ Dano do chicote aplicado com sucesso! (Dano: %.1f)" % (hp_before - hp_after))

	print("\n==================================================")
	print("SUCESSO: Ataque de chicote da Comadre Fulozinha 100% funcional!")
	print("==================================================")
	quit(0)

