extends SceneTree

const UnitSpawner = preload("res://Scripts/Systems/unit_spawner.gd")
const BaseUnit3D = preload("res://Scripts/Units/base_unit.gd")

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	print("==================================================")
	print("TESTE: APLICAÇÃO DO MODELO 3D DA MÃE D'ÁGUA")
	print("==================================================")

	# 1. Carregar UnitStats da Mãe d'Água
	var stats: UnitStats = UnitSpawner.load_unit_stats("mae_dagua")
	assert(stats != null, "Falha ao carregar stats da unidade mae_dagua")
	print("✓ Stats carregados com sucesso: ", stats.unit_name)
	print("  - Tier: ", stats.tier, " | Custo: ", stats.cost)
	print("  - Role: ", stats.combat_role)
	print("  - Model Scene configurada: ", stats.model_scene != null)
	assert(stats.model_scene != null, "model_scene deve estar configurada no resource mae_dagua.tres")

	# 2. Spawn da unidade 3D
	var unit: BaseUnit3D = UnitSpawner.spawn_unit_from_stats(stats, 1, 0)
	assert(unit != null, "Falha ao instanciar BaseUnit3D para mae_dagua")
	root.add_child(unit)
	await process_frame
	await process_frame

	var visual := unit.unit_visual
	assert(visual != null, "UnitVisual deve existir na unidade")
	print("✓ UnitVisual inicializado")

	# 3. Validar hierarquia do modelo e malha
	var anim_player: AnimationPlayer = visual.animation_player
	assert(anim_player != null, "AnimationPlayer deve existir no modelo da Mãe d'Água")
	print("✓ AnimationPlayer localizado com sucesso")

	var anim_list := anim_player.get_animation_list()
	print("  - Animações disponíveis: ", anim_list)
	var required_anims := [&"Idle", &"Attack", &"Stunned", &"Channel", &"Death", &"Ability"]
	for req in required_anims:
		assert(anim_player.has_animation(req), "Animação obrigatória ausente: " + str(req))
	print("✓ Todos os 6 clipes de contrato folclórico estão presentes no AnimationPlayer!")

	# 4. Validar chamadas visuais de gameplay
	print("\nTestando reprodução dos estados de animação:")
	visual.reset_pose()
	assert(anim_player.current_animation == "Idle", "reset_pose deve tocar Idle")
	print("  ✓ Idle ativo")

	visual.play_attack(false, 1.0)
	assert(anim_player.current_animation == "Attack", "play_attack deve tocar Attack")
	print("  ✓ Attack ativo")

	visual.play_cast()
	assert(anim_player.current_animation == "Ability", "play_cast deve tocar Ability")
	print("  ✓ Ability ativo")

	visual.play_stun()
	assert(anim_player.current_animation == "Stunned", "play_stun deve tocar Stunned")
	print("  ✓ Stunned ativo")

	var death_dur: float = visual.play_death()
	assert(anim_player.current_animation == "Death", "play_death deve tocar Death")
	print("  ✓ Death ativo (duração: %.2fs)" % death_dur)

	print("\n==================================================")
	print("SUCESSO: Modelo 3D da Mãe d'Água integrado e validado!")
	print("==================================================")
	quit(0)

