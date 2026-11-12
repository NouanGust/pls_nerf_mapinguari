extends SceneTree

func _init() -> void:
	print("==================================================")
	print("TESTE: MODELO 3D E ANIMAÇÕES DO PEQUI NO GODOT")
	print("==================================================")
	
	var stats = load("res://resources/units/pequi.tres") as UnitStats
	if not stats:
		printerr("FALHA: Não foi possível carregar res://resources/units/pequi.tres")
		quit(1)
		return
		
	print("✓ Stats carregados com sucesso: ", stats.unit_name)
	print("  - Role: ", stats.combat_role)
	print("  - Model Scene configurada: ", stats.model_scene != null)
	
	if not stats.model_scene:
		printerr("FALHA: model_scene não está vinculada!")
		quit(1)
		return
		
	var instance = stats.model_scene.instantiate()
	if not instance:
		printerr("FALHA: Não foi possível instanciar a cena do modelo!")
		quit(1)
		return
		
	print("✓ Instância do modelo criada com sucesso: ", instance.name)
	
	# Procurar AnimationPlayer
	var anim_player: AnimationPlayer = null
	var stack = [instance]
	while not stack.is_empty():
		var node = stack.pop_back()
		if node is AnimationPlayer:
			anim_player = node
			break
		for child in node.get_children():
			stack.push_back(child)
			
	if not anim_player:
		printerr("FALHA: AnimationPlayer não encontrado no modelo!")
		quit(1)
		return
		
	var anim_list = anim_player.get_animation_list()
	print("✓ AnimationPlayer encontrado! Animações disponíveis: ", anim_list)
	
	var required = ["Idle", "Attack", "Ability", "Channel", "Stunned", "Death"]
	var missing = []
	for req in required:
		if not anim_player.has_animation(req):
			missing.append(req)
			
	if missing.size() > 0:
		printerr("FALHA: Animações ausentes: ", missing)
		quit(1)
		return
		
	print("✓ Todas as 6 animações exigidas pelo contrato de gameplay estão presentes!")
	
	for req in required:
		anim_player.play(req)
		print("  ✓ Animação executada: ", req, " (Duração: ", anim_player.current_animation_length, "s)")
		
	print("==================================================")
	print("SUCESSO: Modelo 3D e Rig do Pequi 100% validados!")
	print("==================================================")
	quit(0)

