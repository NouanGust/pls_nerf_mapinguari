extends SceneTree

const Models = preload("res://Scripts/Units/biodiversity_models.gd")
var failures := 0
var world: Node3D

func _initialize() -> void:
	call_deferred("_run")

func check(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		push_error(message)

func spawn(id: String, team: int = 0) -> BaseUnit3D:
	var stats := UnitSpawner.load_unit_stats(id).duplicate() as UnitStats
	stats.mana_per_attack = 0.0
	stats.mana_when_hit = 0.0
	var unit := UnitSpawner.spawn_unit_from_stats(stats, 1, team)
	world.add_child(unit)
	return unit

func _run() -> void:
	world = Node3D.new()
	root.add_child(world)
	current_scene = world
	for id in Models.ANIMALS.keys() + Models.PLANTS.keys():
		var unit := spawn(id)
		check(unit.unit_visual._species_model != null, id + ": modelo da espécie")
		check(unit.animation_player == null, id + ": sem humanoide oculto")
		check(unit.unit_visual._meshes.size() == 1, id + ": somente a malha selecionada")
		var mesh := unit.unit_visual._meshes[0]
		var material := mesh.get_active_material(0) as StandardMaterial3D
		check(material != null and material.albedo_color != Color.RED, id + ": material importado corrigido")
		var bounds: AABB = mesh.transform * mesh.mesh.get_aabb()
		check(bounds.size.x <= 1.66 and bounds.size.z <= 1.66 and bounds.size.y <= 1.91, id + ": cabe na casa")
		check(absf(bounds.position.y) < 0.01, id + ": base apoiada no chão")
		if Models.PLANTS.has(id):
			check(unit.stats.is_stationary and unit.stats.is_ranged and unit.stats.attack_range >= 4, id + ": planta imóvel à distância")
		unit.unit_visual.play_attack(true, 1.0)
		unit.unit_visual.play_cast()
		unit.unit_visual.play_death()
		unit.unit_visual.reset_pose()
		check(unit.unit_visual.scale == Vector3.ONE, id + ": restaura pose ao reviver")
		unit.queue_free()
		await process_frame
		await physics_frame

	var plant := spawn("guarana")
	var ally := spawn("lobo_guara")
	var enemy := spawn("capivara", 1)
	var second_plant := spawn("sumauma")
	plant.position = Vector3.ZERO
	ally.position = Vector3(2, 0, 0)
	enemy.position = Vector3(20, 0, 0)
	second_plant.position = Vector3(0, 0, 2)
	second_plant.current_state = BaseUnit3D.State.ROOTED
	second_plant.set_physics_process(false)
	ally.current_state = BaseUnit3D.State.ATTACKING
	ally.set_physics_process(false)
	enemy.set_physics_process(false)
	plant.start_combat()
	check(plant.current_state == BaseUnit3D.State.ROOTED, "Espera enraizada fora de alcance")
	var initial_mana := plant.current_mana
	await create_timer(0.35).timeout
	check(plant.current_mana > initial_mana, "Planta ganha mana sem alvo ao alcance")
	check(plant.position == Vector3.ZERO, "Planta não persegue inimigo distante")
	check(ally.get_movement_speed() > 0.0, "Lobo-guará continua móvel apesar da afinidade Flora")
	check(is_equal_approx(ally.get_power_aura_bonus(), 0.18), "Apenas a aura mais forte se aplica")
	second_plant.current_state = BaseUnit3D.State.IDLE
	check(is_equal_approx(ally.get_power_aura_bonus(), 0.10), "Aura termina ao encerrar combate")
	check(enemy.get_power_aura_bonus() == 0.0, "Aura não beneficia inimigos")
	ally.position.x = 5.0
	check(ally.get_power_aura_bonus() == 0.0, "Aura sai imediatamente ao sair do raio")
	ally.position.x = 2.0
	var base_damage := ally.stats.attack_damage
	check(is_equal_approx(ally.get_attack_damage(), base_damage * 1.1), "Aura aumenta o dano efetivo do aliado")
	plant.hide()
	check(ally.get_power_aura_bonus() == 0.0, "Planta no banco não concede aura")
	plant.show()
	var health_before := enemy.current_health
	enemy.position = Vector3(0, 0, 6)
	await create_timer(0.3).timeout
	check(plant.current_target == enemy and plant.current_state == BaseUnit3D.State.ATTACKING, "Adquire inimigo que entra no alcance")
	plant.perform_attack()
	check(enemy.current_health < health_before, "Ataque de planta causa dano à distância")
	enemy.position = Vector3(20, 0, 0)
	plant.perform_attack()
	check(plant.current_state == BaseUnit3D.State.ROOTED, "Alvo que sai do alcance não é perseguido")
	var close_enemy := spawn("tatu_bola", 1)
	close_enemy.position = Vector3(0, 0, 5)
	close_enemy.set_physics_process(false)
	plant.stats.target_priority = UnitStats.TargetPriority.LOWEST_HP
	enemy.current_health = 1.0
	plant.find_target()
	check(plant.current_target == close_enemy, "Prioridade não prende a planta a um alvo inalcançável")
	plant.attack_timer.stop()
	for direct in [true, false]:
		plant.use_navigation = not direct
		plant.move_towards_target()
		plant.move_direct_to_target()
		plant._on_velocity_computed(Vector3(10, 0, 0))
		check(plant.position == Vector3.ZERO and plant.velocity == Vector3.ZERO, "Nenhum caminho de movimento desloca plantas")
	plant.die()
	check(ally.get_power_aura_bonus() == 0.0, "Morte remove aura imediatamente")
	plant.revive_at_position(Vector3.ZERO)
	await create_timer(0.6).timeout
	check(plant.visible and plant.current_state == BaseUnit3D.State.IDLE, "Reviver invalida morte pendente")
	check(ally.get_power_aura_bonus() == 0.0, "Reviver em preparação não reativa aura")
	world.queue_free()
	await process_frame
	print("BIODIVERSITY SMOKE: ", "PASS" if failures == 0 else "FAIL (%d)" % failures)
	quit(0 if failures == 0 else 1)
