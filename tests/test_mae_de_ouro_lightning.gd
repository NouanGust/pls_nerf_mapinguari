extends SceneTree

const UnitCatalog = preload("res://Scripts/Systems/unit_catalog.gd")
const BaseUnit3D = preload("res://Scripts/Units/base_unit.gd")
const LightningEffect = preload("res://Scripts/Systems/lightning_effect.gd")
const CombatFeedback = preload("res://Scripts/Systems/combat_feedback.gd")
const MaeDeOuroAbility = preload("res://Scripts/Abilities/Bespoke/mae_de_ouro_ability.gd")
const BattleClock = preload("res://Scripts/Systems/battle_clock.gd")

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	print("--- INICIANDO TESTE: EFEITO DE RELAMPAGOS E HABILIDADE DA MAE D'OURO ---")

	if not root.has_node("BattleClock"):
		var clock := BattleClock.new()
		clock.name = "BattleClock"
		root.add_child(clock)

	var catalog = UnitCatalog.new()
	catalog.ensure_loaded()

	_test_lightning_strike_procedural_generation()
	_test_celestial_beam_generation()
	_test_mae_de_ouro_ability_execution(catalog)

	print("--- TODOS OS TESTES DE RELAMPAGO E MAE D'OURO PASSARAM COM SUCESSO! ---")
	quit(0)

func _test_lightning_strike_procedural_generation() -> void:
	print("Testando geracao procedural do relampago 3D via LightningEffect...")
	var target_pos := Vector3(2.0, 0.0, 3.0)
	var bolt := LightningEffect.create_strike(target_pos, Color("#fbbf24"), 8.0, 0.08)

	assert(bolt != null, "O nó de relâmpago deve ser criado e retornado")
	assert(bolt.is_inside_tree(), "O relâmpago deve ser adicionado à árvore de cena")

	# Verifica componentes visuais filhos do relâmpago
	var mesh_inst: MeshInstance3D = null
	var light: OmniLight3D = null
	var ring: MeshInstance3D = null
	var sparks: CPUParticles3D = null

	for child in bolt.get_children():
		if child is MeshInstance3D:
			if child.mesh is ArrayMesh:
				mesh_inst = child
			elif child.mesh is TorusMesh:
				ring = child
		elif child is OmniLight3D:
			light = child
		elif child is CPUParticles3D:
			sparks = child

	assert(mesh_inst != null, "Malha procedural 3D de relâmpago (ArrayMesh) deve existir")
	assert(light != null, "Clarão de luz OmniLight3D de impacto deve existir")
	assert(ring != null, "Anel de onda de choque no solo deve existir")
	assert(sparks != null, "Partículas de faíscas no solo devem existir")

	# Teste via CombatFeedback wrapper
	var wrapper_bolt := CombatFeedback.create_lightning_strike(Vector3(0, 0, 0))
	assert(wrapper_bolt != null, "CombatFeedback.create_lightning_strike deve delegar com sucesso")

	print("OK: Geracao procedural do relampago 3D validada com sucesso!")

func _test_celestial_beam_generation() -> void:
	print("Testando feixe celestial descendente via LightningEffect...")
	var ally_pos := Vector3(-1.0, 0.0, 1.0)
	var beam := LightningEffect.create_celestial_beam(ally_pos, Color("#facc15"), 6.0, 0.4, 0.3)

	assert(beam != null, "O feixe celestial deve ser criado")
	assert(beam.is_inside_tree(), "O feixe deve estar na árvore")

	var col_inst: MeshInstance3D = null
	for child in beam.get_children():
		if child is MeshInstance3D and child.mesh is CylinderMesh:
			col_inst = child
			break

	assert(col_inst != null, "Coluna cilíndrica de luz celestial deve existir")
	print("OK: Feixe celestial validado com sucesso!")

func _test_mae_de_ouro_ability_execution(catalog: UnitCatalog) -> void:
	print("Testando execucao completa da habilidade da Mae d'Ouro...")

	# 1. Caster: Mae de Ouro
	var caster := BaseUnit3D.new()
	caster.stats = catalog.get_unit("mae_de_ouro")
	caster.team = 0
	caster.board_position = Vector2i(0, 0)
	root.add_child(caster)
	caster.current_health = caster.get_max_health()
	caster.position = Vector3(0, 0, 0)

	# 2. Inimigo alvo
	var enemy := BaseUnit3D.new()
	enemy.stats = catalog.get_unit("capivara")
	enemy.team = 1
	enemy.board_position = Vector2i(1, 1)
	root.add_child(enemy)
	enemy.current_health = enemy.get_max_health()
	enemy.position = Vector3(2.5, 0, 0)

	# 3. Aliado ferido
	var ally := BaseUnit3D.new()
	ally.stats = catalog.get_unit("aguape")
	ally.team = 0
	ally.board_position = Vector2i(0, 1)
	root.add_child(ally)
	ally.current_health = ally.get_max_health() * 0.5 # ferido para receber cura
	ally.position = Vector3(-1.5, 0, 0)

	var hp_before := enemy.current_health
	var ally_hp_before := ally.current_health

	var ability := MaeDeOuroAbility.new()
	var success := ability.execute(caster)
	assert(success == true, "Habilidade da Mae d'Ouro deve executar com sucesso")

	# Verifica dano no primeiro inimigo (atingido pelo primeiro relâmpago)
	assert(enemy.current_health < hp_before, "Inimigo deve receber dano dos relampagos dourados")

	# Verifica cura no aliado
	assert(ally.current_health > ally_hp_before, "Aliado ferido deve ser curado pelo feixe celestial")

	# Teste de execução sem alvos (fallback sem crash)
	enemy.current_state = BaseUnit3D.State.DEAD
	var solo_success := ability.execute(caster)
	assert(solo_success == true, "Execucao sem alvos (fallback) deve funcionar perfeitamente")

	caster.queue_free()
	enemy.queue_free()
	ally.queue_free()
	print("OK: Habilidade da Mae d'Ouro e queda de relampagos 100% validadas!")
