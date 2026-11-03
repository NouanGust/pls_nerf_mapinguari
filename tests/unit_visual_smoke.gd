extends SceneTree
## Executar: godot --headless --path . --script res://tests/unit_visual_smoke.gd

var _failures := 0


func _initialize() -> void:
	call_deferred("_run")


func _check(condition: bool, message: String) -> void:
	if not condition:
		_failures += 1
		push_error(message)


func _run() -> void:
	var world := Node3D.new()
	root.add_child(world)
	current_scene = world
	var stats := UnitSpawner.load_unit_stats("caapora").duplicate() as UnitStats
	stats.mana_per_second = 0.0
	stats.mana_per_attack = 0.0
	stats.mana_when_hit = 0.0
	stats.attack_range = 1
	var ally := UnitSpawner.spawn_unit_from_stats(stats, 1, 0)
	var enemy := UnitSpawner.spawn_unit_from_stats(stats, 1, 1)
	world.add_child(ally)
	world.add_child(enemy)
	enemy.position = Vector3(0, 0, 2)
	await physics_frame
	await process_frame
	_check(ally.animation_player.current_animation == "Idle", "Unidade deve iniciar em espera, sem T-pose.")
	var skeleton := ally.unit_visual.find_children("*", "Skeleton3D", true, false)[0] as Skeleton3D
	_check(skeleton != null and skeleton.find_bone("Hips") >= 0, "BoneMap humanoide deve ser aplicado na importação.")
	for clip in ["Idle", "Walk"]:
		_check(ally.animation_player.get_animation(clip).loop_mode == Animation.LOOP_LINEAR, clip + " deve repetir.")
	for clip in ["Punch_Jab", "Spell_Simple_Shoot", "Death01"]:
		_check(ally.animation_player.get_animation(clip).loop_mode == Animation.LOOP_NONE, clip + " não deve repetir.")
	var meshes := ally.unit_visual.find_children("*", "MeshInstance3D", true, false)
	_check(not meshes.is_empty(), "Modelo deve conter malha.")
	_check(not ally.unit_visual._body_materials.is_empty(), "Material principal deve receber a cor da unidade.")
	_check(ally.unit_visual._body_materials[0] != enemy.unit_visual._body_materials[0], "Materiais de unidades devem ser independentes.")
	var enemy_color := enemy.unit_visual._body_materials[0].albedo_color
	ally.flash_damage()
	ally.promote_to_star(2)
	_check(enemy.unit_visual._body_materials[0].albedo_color == enemy_color, "Dano/evolução não podem recolorir outra unidade.")
	await create_timer(1.0).timeout
	_check(meshes[0].material_overlay == null, "Evolução deve restaurar o material original.")
	_check(ally.unit_visual._body_materials[0].albedo_color.is_equal_approx(ally.get_team_display_color()), "Flash deve restaurar a cor da unidade.")

	ally.set_physics_process(false)
	ally.current_state = BaseUnit3D.State.MOVING
	await process_frame
	await process_frame
	_check(ally.animation_player.current_animation == "Walk", "Deslocamento deve tocar caminhada.")
	ally.current_state = BaseUnit3D.State.ATTACKING
	ally.current_target = enemy
	var health_before := enemy.current_health
	ally.perform_attack()
	_check(ally.animation_player.current_animation == "Punch_Jab", "Ataque corpo a corpo deve tocar soco.")
	_check(enemy.current_health < health_before, "Animação não pode impedir o dano.")
	_check(ally.global_basis.z.dot((enemy.global_position - ally.global_position).normalized()) > 0.99, "Ataque deve olhar para o alvo com +Z.")
	await create_timer(1.05).timeout
	_check(ally.animation_player.current_animation == "Idle", "Ataque deve retornar à espera.")
	stats.attack_range = 2
	ally.perform_attack()
	_check(ally.animation_player.current_animation == "Spell_Simple_Shoot", "Ataque à distância deve tocar o gesto de lançamento.")
	stats.ability_name = "Teste"
	ally.cast_ability()
	_check(ally.current_state == BaseUnit3D.State.CASTING, "Habilidade deve manter estado de conjuração.")
	_check(ally.animation_player.current_animation == "Spell_Simple_Shoot", "Conjuração deve tocar magia.")
	await create_timer(0.6).timeout
	ally.attack_timer.stop()
	ally.current_state = BaseUnit3D.State.IDLE
	await process_frame
	await process_frame
	_check(ally.animation_player.current_animation == "Idle", "Fim do combate deve interromper a ação.")

	ally.die()
	_check(ally.visible and ally.collision_layer == 0, "Morte deve exibir o corpo e remover colisões imediatamente.")
	_check(ally.animation_player.current_animation == "Death01", "Morte deve tocar Death01.")
	ally.revive_at_position(Vector3.ZERO)
	await create_timer(2.6).timeout
	_check(ally.visible and ally.current_state == BaseUnit3D.State.IDLE, "Morte pendente não pode esconder unidade já revivida.")
	_check(ally.ui_sprite.visible and ally.animation_player.current_animation == "Idle", "Reviver deve restaurar rótulo e pose.")
	ally.die()
	enemy.die()
	await create_timer(2.6).timeout
	_check(not ally.visible and ally.process_mode == Node.PROCESS_MODE_DISABLED, "Aliado morto deve ficar guardado para a próxima rodada.")
	_check(not is_instance_valid(enemy), "Inimigo deve ser removido após a animação de morte.")
	ally.revive_at_position(Vector3.ZERO)
	_check(ally.visible and ally.collision_layer == 1, "Reviver após morte completa deve restaurar a unidade.")
	world.queue_free()
	await process_frame
	print("UNIT VISUAL SMOKE: ", "PASS" if _failures == 0 else "FAIL (%d)" % _failures)
	quit(0 if _failures == 0 else 1)
