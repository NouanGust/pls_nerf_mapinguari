extends SceneTree

const TIER_3_UNITS = [
	"alamoa",
	"anhanga",
	"cabeca_de_cuia",
	"labatut",
	"mae_de_ouro",
	"mapinguari",
	"matinta_perera",
	"minhocao",
	"quibungo",
	"teiniagua"
]

var _executed := false

func _process(_delta: float) -> bool:
	if _executed:
		return false
	_executed = true
	
	print("\n==========================================")
	print("INICIANDO TESTES: UNIDADES DE CUSTO 3 E HABILIDADES")
	print("==========================================\n")
	
	test_tier_3_units_loading_and_stats()
	test_tier_3_abilities_general_execution()
	test_specific_tier_3_mechanics()
	
	print("\n==========================================")
	print("TODOS OS TESTES DE TIER 3 PASSARAM COM SUCESSO!")
	print("==========================================\n")
	quit(0)
	return true

func test_tier_3_units_loading_and_stats() -> void:
	print("--- 1. Testando Recursos de Custo 3 (10 Unidades) ---")
	UnitSpawner.clear_cache()
	UnitSpawner.load_all_units()
	
	for unit_id in TIER_3_UNITS:
		var stats: UnitStats = UnitSpawner.load_unit_stats(unit_id)
		assert(stats != null, "UnitStats para %s não deve ser nulo" % unit_id)
		assert(stats.cost == 3, "Unidade %s deve ter custo 3 (tem %d)" % [unit_id, stats.cost])
		assert(stats.ability_name != "", "Unidade %s deve possuir ability_name definido" % unit_id)
		print("  [OK] %s: Custo 3 | Habilidade: '%s'" % [stats.unit_name, stats.ability_name])

func test_tier_3_abilities_general_execution() -> void:
	print("--- 2. Testando Execução Geral das Habilidades (1★ e 3★) ---")
	for unit_id in TIER_3_UNITS:
		# 1 Estrela
		var unit_1: BaseUnit3D = UnitSpawner.spawn_unit(unit_id, 1, 0)
		assert(unit_1 != null, "BaseUnit3D 1★ para %s deve ser instanciado" % unit_id)
		root.add_child(unit_1)
		unit_1.board_position = Vector2i(0, 0)
		unit_1.current_state = BaseUnit3D.State.ATTACKING
		unit_1.current_mana = unit_1.stats.max_mana
		unit_1.cast_ability()
		
		# 3 Estrelas (testar escalonamento)
		var unit_3: BaseUnit3D = UnitSpawner.spawn_unit(unit_id, 3, 0)
		assert(unit_3 != null, "BaseUnit3D 3★ para %s deve ser instanciado" % unit_id)
		root.add_child(unit_3)
		unit_3.board_position = Vector2i(1, 1)
		unit_3.current_state = BaseUnit3D.State.ATTACKING
		unit_3.current_mana = unit_3.stats.max_mana
		unit_3.cast_ability()
		
		unit_1.queue_free()
		unit_3.queue_free()
		print("  [OK] %s: Habilidade conjurada com sucesso em 1★ e 3★." % unit_id)

func test_specific_tier_3_mechanics() -> void:
	print("--- 3. Testando Mecânicas Específicas de Custo 3 ---")
	
	# ==========================================
	# 1. Alamoa: Canto Hipnótico (Stun / Hipnose em até 2 inimigos)
	# ==========================================
	var alamoa: BaseUnit3D = UnitSpawner.spawn_unit("alamoa", 1, 0)
	root.add_child(alamoa)
	alamoa.board_position = Vector2i(0, 0)
	alamoa.global_position = Vector3(0, 0, 0)
	alamoa.current_state = BaseUnit3D.State.ATTACKING
	
	var enemy1: BaseUnit3D = UnitSpawner.spawn_unit("tatu_bola", 1, 1)
	var enemy2: BaseUnit3D = UnitSpawner.spawn_unit("capivara", 1, 1)
	root.add_child(enemy1)
	root.add_child(enemy2)
	enemy1.board_position = Vector2i(1, 0)
	enemy2.board_position = Vector2i(2, 0)
	enemy1.global_position = Vector3(1.5, 0, 0)
	enemy2.global_position = Vector3(2.5, 0, 0)
	
	alamoa.cast_ability()
	assert(enemy1.is_stunned(), "Enemy 1 deve ficar atordoado/hipnotizado pelo Canto da Alamoa")
	assert(enemy2.is_stunned(), "Enemy 2 deve ficar atordoado/hipnotizado pelo Canto da Alamoa")
	print("  [OK] Alamoa: Canto Hipnótico atordoou 2 inimigos com sucesso.")
	
	alamoa.queue_free()
	enemy1.queue_free()
	enemy2.queue_free()
	
	# ==========================================
	# 2. Anhangá: Rugido da Floresta (Enfraquecimento de ataque em área)
	# ==========================================
	var anhanga: BaseUnit3D = UnitSpawner.spawn_unit("anhanga", 2, 0)
	root.add_child(anhanga)
	anhanga.board_position = Vector2i(0, 0)
	anhanga.global_position = Vector3(0, 0, 0)
	anhanga.current_state = BaseUnit3D.State.ATTACKING
	
	var anhanga_target: BaseUnit3D = UnitSpawner.spawn_unit("onca_pintada", 1, 1)
	root.add_child(anhanga_target)
	anhanga_target.board_position = Vector2i(1, 0)
	anhanga_target.global_position = Vector3(1.2, 0, 0)
	var orig_atk := anhanga_target.get_attack_damage()
	
	anhanga.cast_ability()
	var weakened_atk := anhanga_target.get_attack_damage()
	assert(weakened_atk < orig_atk, "Ataque do inimigo deve ser reduzido pelo Rugido do Anhangá")
	assert(anhanga_target.attack_damage_multiplier <= 0.61, "Anhangá 2★ deve reduzir o ataque em ~40%%")
	print("  [OK] Anhangá: Rugido reduziu o ataque de %.1f para %.1f." % [orig_atk, weakened_atk])
	
	anhanga.queue_free()
	anhanga_target.queue_free()
	
	# ==========================================
	# 3. Cabeça-de-Cuia: Arrasto Amaldiçoado (Puxão, Dano Mágico e Shred de Armadura)
	# ==========================================
	var cabeca: BaseUnit3D = UnitSpawner.spawn_unit("cabeca_de_cuia", 1, 0)
	root.add_child(cabeca)
	cabeca.board_position = Vector2i(0, 0)
	cabeca.global_position = Vector3(0, 0, 0)
	cabeca.current_state = BaseUnit3D.State.ATTACKING
	
	var distant_enemy: BaseUnit3D = UnitSpawner.spawn_unit("tatu_bola", 1, 1)
	root.add_child(distant_enemy)
	distant_enemy.board_position = Vector2i(5, 0)
	distant_enemy.global_position = Vector3(5.0, 0, 0)
	var hp_before := distant_enemy.current_health
	
	cabeca.cast_ability()
	assert(distant_enemy.current_health < hp_before, "Inimigo deve sofrer dano mágico do Arrasto Amaldiçoado")
	assert(distant_enemy.armor_shred_amount > 0.0, "Armadura do inimigo deve ser triturada pelo Arrasto")
	print("  [OK] Cabeça-de-Cuia: Dano e redução de armadura aplicados com sucesso.")
	
	cabeca.queue_free()
	distant_enemy.queue_free()
	
	# ==========================================
	# 4. Labatut: Corrente Curativa (Cura de aliados feridos)
	# ==========================================
	var labatut: BaseUnit3D = UnitSpawner.spawn_unit("labatut", 1, 0)
	root.add_child(labatut)
	labatut.board_position = Vector2i(0, 0)
	labatut.global_position = Vector3(0, 0, 0)
	labatut.current_state = BaseUnit3D.State.ATTACKING
	
	var injured_ally: BaseUnit3D = UnitSpawner.spawn_unit("capivara", 1, 0)
	root.add_child(injured_ally)
	injured_ally.board_position = Vector2i(1, 0)
	injured_ally.global_position = Vector3(1.0, 0, 0)
	injured_ally.current_health = injured_ally.get_max_health() * 0.4
	var ally_hp_before := injured_ally.current_health
	
	labatut.cast_ability()
	assert(injured_ally.current_health > ally_hp_before, "Aliado ferido deve ser curado pela Corrente Curativa")
	print("  [OK] Labatut: Corrente Curativa curou aliado ferido de %.1f para %.1f HP." % [ally_hp_before, injured_ally.current_health])
	
	labatut.queue_free()
	injured_ally.queue_free()
	
	# ==========================================
	# 5. Mãe-de-Ouro: Chamas Douradas (Explosão dupla: Dano + Cura)
	# ==========================================
	var mae: BaseUnit3D = UnitSpawner.spawn_unit("mae_de_ouro", 1, 0)
	root.add_child(mae)
	mae.board_position = Vector2i(0, 0)
	mae.global_position = Vector3(0, 0, 0)
	mae.current_state = BaseUnit3D.State.ATTACKING
	
	var mae_enemy: BaseUnit3D = UnitSpawner.spawn_unit("tatu_bola", 1, 1)
	root.add_child(mae_enemy)
	mae_enemy.board_position = Vector2i(1, 0)
	mae_enemy.global_position = Vector3(1.5, 0, 0)
	var mae_enemy_hp := mae_enemy.current_health
	
	var mae_ally: BaseUnit3D = UnitSpawner.spawn_unit("capivara", 1, 0)
	root.add_child(mae_ally)
	mae_ally.board_position = Vector2i(2, 0)
	mae_ally.global_position = Vector3(-1.5, 0, 0)
	mae_ally.current_health = mae_ally.get_max_health() * 0.5
	var mae_ally_hp := mae_ally.current_health
	
	mae.cast_ability()
	assert(mae_enemy.current_health < mae_enemy_hp, "Mãe-de-Ouro deve causar dano de chamas ao inimigo")
	assert(mae_ally.current_health > mae_ally_hp, "Mãe-de-Ouro deve curar o aliado com sua explosão dourada")
	print("  [OK] Mãe-de-Ouro: Explosão dupla causou dano (%.1f -> %.1f) e curou aliado (%.1f -> %.1f)." % [
		mae_enemy_hp, mae_enemy.current_health, mae_ally_hp, mae_ally.current_health
	])
	
	mae.queue_free()
	mae_enemy.queue_free()
	mae_ally.queue_free()
	
	# ==========================================
	# 6. Mapinguari: Couro de Ferro (Redução e Reflexão de Dano)
	# ==========================================
	var mapinguari: BaseUnit3D = UnitSpawner.spawn_unit("mapinguari", 1, 0)
	root.add_child(mapinguari)
	mapinguari.board_position = Vector2i(0, 0)
	mapinguari.global_position = Vector3(0, 0, 0)
	mapinguari.current_state = BaseUnit3D.State.ATTACKING
	
	var attacker: BaseUnit3D = UnitSpawner.spawn_unit("onca_pintada", 1, 1)
	root.add_child(attacker)
	attacker.board_position = Vector2i(1, 0)
	attacker.global_position = Vector3(1.0, 0, 0)
	var attacker_hp_before := attacker.current_health
	
	mapinguari.cast_ability()
	assert(mapinguari.reflect_until_msec > 0, "Couro de Ferro deve ativar reflect_until_msec")
	assert(mapinguari.reflect_pct >= 0.40, "Couro de Ferro deve ter reflexão ativa (>= 40%%)")
	
	# Atacante ataca Mapinguari enquanto o couro de ferro está ativo
	mapinguari.take_damage(200.0, attacker, UnitStats.DamageType.PHYSICAL)
	assert(attacker.current_health < attacker_hp_before, "Atacante deve receber dano refletido de Mapinguari")
	print("  [OK] Mapinguari: Couro de Ferro refletiu dano de volta para o atacante (HP: %.1f -> %.1f)." % [
		attacker_hp_before, attacker.current_health
	])
	
	mapinguari.queue_free()
	attacker.queue_free()
	
	# ==========================================
	# 7. Matinta Perera: Forma de Pássaro (Imunidade a Dano e Dano em Área)
	# ==========================================
	var matinta: BaseUnit3D = UnitSpawner.spawn_unit("matinta_perera", 1, 0)
	root.add_child(matinta)
	matinta.board_position = Vector2i(0, 0)
	matinta.global_position = Vector3(0, 0, 0)
	matinta.current_state = BaseUnit3D.State.ATTACKING
	
	var matinta_enemy: BaseUnit3D = UnitSpawner.spawn_unit("capivara", 1, 1)
	root.add_child(matinta_enemy)
	matinta_enemy.board_position = Vector2i(1, 0)
	matinta_enemy.global_position = Vector3(1.2, 0, 0)
	var menemy_hp_before := matinta_enemy.current_health
	
	matinta.cast_ability()
	assert(matinta.is_immune(), "Matinta Perera deve ficar imune em Forma de Pássaro")
	assert(matinta_enemy.current_health < menemy_hp_before, "Inimigos próximos devem sofrer dano em área da Matinta")
	
	# Tentar causar dano a Matinta enquanto imune
	var matinta_hp := matinta.current_health
	matinta.take_damage(500.0, matinta_enemy, UnitStats.DamageType.PHYSICAL)
	assert(matinta.current_health == matinta_hp, "Matinta não deve sofrer nenhum dano enquanto imune")
	print("  [OK] Matinta Perera: Forma de Pássaro garantiu imunidade total e causou dano em área.")
	
	matinta.queue_free()
	matinta_enemy.queue_free()
	
	# ==========================================
	# 8. Minhocão: Terremoto (Dano em Área e Atordoamento)
	# ==========================================
	var minhocao: BaseUnit3D = UnitSpawner.spawn_unit("minhocao", 1, 0)
	root.add_child(minhocao)
	minhocao.board_position = Vector2i(0, 0)
	minhocao.global_position = Vector3(0, 0, 0)
	minhocao.current_state = BaseUnit3D.State.ATTACKING
	
	var q_enemy: BaseUnit3D = UnitSpawner.spawn_unit("capivara", 1, 1)
	root.add_child(q_enemy)
	q_enemy.board_position = Vector2i(1, 0)
	q_enemy.global_position = Vector3(2.0, 0, 0)
	var q_hp_before := q_enemy.current_health
	
	minhocao.cast_ability()
	assert(q_enemy.current_health < q_hp_before, "Inimigo deve sofrer dano físico do Terremoto")
	assert(q_enemy.is_stunned(), "Inimigo atingido pelo Terremoto deve ficar atordoado")
	print("  [OK] Minhocão: Terremoto causou dano em área e atordoou os alvos.")
	
	minhocao.queue_free()
	q_enemy.queue_free()
	
	# ==========================================
	# 9. Quibungo: Saco das Sombras (Prisão e Dano Verdadeiro)
	# ==========================================
	var quibungo: BaseUnit3D = UnitSpawner.spawn_unit("quibungo", 1, 0)
	root.add_child(quibungo)
	quibungo.board_position = Vector2i(0, 0)
	quibungo.global_position = Vector3(0, 0, 0)
	quibungo.current_state = BaseUnit3D.State.ATTACKING
	
	var sack_victim: BaseUnit3D = UnitSpawner.spawn_unit("tatu_bola", 1, 1)
	root.add_child(sack_victim)
	sack_victim.board_position = Vector2i(1, 0)
	sack_victim.global_position = Vector3(1.0, 0, 0)
	quibungo.current_target = sack_victim
	var sack_hp_before := sack_victim.current_health
	
	quibungo.cast_ability()
	assert(sack_victim.is_stunned(), "Vítima do Quibungo deve ficar atordoada/presa no saco")
	assert(sack_victim.current_health < sack_hp_before, "Vítima deve receber dano verdadeiro do Saco das Sombras")
	print("  [OK] Quibungo: Vítima aprisionada no saco e sofreu dano verdadeiro imediato.")
	
	quibungo.queue_free()
	sack_victim.queue_free()
	
	# ==========================================
	# 10. Teiniaguá: Esfera Arcana (Grande dano mágico em área com escalonamento 1★ e 3★)
	# ==========================================
	var teiniagua_1: BaseUnit3D = UnitSpawner.spawn_unit("teiniagua", 1, 0)
	root.add_child(teiniagua_1)
	teiniagua_1.board_position = Vector2i(0, 0)
	teiniagua_1.global_position = Vector3(0, 0, 0)
	teiniagua_1.current_state = BaseUnit3D.State.ATTACKING
	
	var orb_target: BaseUnit3D = UnitSpawner.spawn_unit("tatu_bola", 1, 1)
	root.add_child(orb_target)
	orb_target.board_position = Vector2i(1, 0)
	orb_target.global_position = Vector3(1.5, 0, 0)
	teiniagua_1.current_target = orb_target
	var orb_hp_before := orb_target.current_health
	
	teiniagua_1.cast_ability()
	var dmg_1star := orb_hp_before - orb_target.current_health
	assert(dmg_1star > 0, "Alvo deve sofrer dano mágico da Esfera Arcana")
	
	teiniagua_1.queue_free()
	orb_target.queue_free()
	
	var teiniagua_3: BaseUnit3D = UnitSpawner.spawn_unit("teiniagua", 3, 0)
	root.add_child(teiniagua_3)
	teiniagua_3.board_position = Vector2i(0, 0)
	teiniagua_3.global_position = Vector3(0, 0, 0)
	teiniagua_3.current_state = BaseUnit3D.State.ATTACKING
	
	var orb_target_3: BaseUnit3D = UnitSpawner.spawn_unit("tatu_bola", 1, 1)
	root.add_child(orb_target_3)
	orb_target_3.board_position = Vector2i(1, 0)
	orb_target_3.global_position = Vector3(1.5, 0, 0)
	teiniagua_3.current_target = orb_target_3
	var orb_hp_before_3 := orb_target_3.current_health
	
	teiniagua_3.cast_ability()
	var dmg_3star := orb_hp_before_3 - orb_target_3.current_health
	assert(dmg_3star > dmg_1star, "Esfera Arcana 3★ deve causar significativamente mais dano que 1★")
	print("  [OK] Teiniaguá: Esfera Arcana escalonou dano com sucesso (1★: %.1f, 3★: %.1f)." % [dmg_1star, dmg_3star])
	
	teiniagua_3.queue_free()
	orb_target_3.queue_free()
