extends SceneTree

const TIER_2_UNITS = [
	"aguape",
	"arara_azul_lear",
	"caranguejo_uca",
	"ipe_amarelo",
	"jararaca",
	"lobo_guara",
	"palmito_jucara",
	"papa_figo",
	"tamandua_bandeira",
	"vitoria_regia"
]

var _executed := false

func _process(delta: float) -> bool:
	if _executed:
		return false
	_executed = true
	
	print("\n==========================================")
	print("INICIANDO TESTES: UNIDADES DE CUSTO 2 E FEEDBACK VISUAL")
	print("==========================================\n")
	
	test_combat_feedback_enhancements()
	test_tier_2_units_loading_and_stats()
	test_tier_2_abilities_casting()
	test_specific_tier_2_mechanics()
	
	print("\n==========================================")
	print("TODOS OS TESTES DE TIER 2 PASSARAM COM SUCESSO!")
	print("==========================================\n")
	quit(0)
	return true

func test_combat_feedback_enhancements() -> void:
	print("--- Testando Melhorias do CombatFeedback ---")
	var dummy_unit := Node3D.new()
	root.add_child(dummy_unit)
	
	# Testar partículas de impacto com mesh aprimorado e glow
	CombatFeedback.create_hit_particles(Vector3.ZERO, Color("#38bdf8"))
	
	# Testar indicador de status animado e maior
	CombatFeedback.create_status_indicator(dummy_unit, "PINÇA E CARAPAÇA", 0.5)
	CombatFeedback.create_status_indicator(dummy_unit, "+100 HP", 0.5)
	CombatFeedback.create_status_indicator(dummy_unit, "+20 MANA", 0.5)
	CombatFeedback.create_status_indicator(dummy_unit, "TOQUE GÉLIDO", 0.5)
	
	var label = dummy_unit.get_node_or_null("StatusIndicator")
	assert(label != null, "Label3D de status deve ser instanciado no unit")
	assert(label.font_size >= 36, "Fonte do indicador deve ser grande e visível (>= 36)")
	assert(label.outline_size >= 12, "Contorno deve ser bem contrastado (>= 12)")
	
	dummy_unit.queue_free()
	print("  [OK] CombatFeedback: partículas e status indicators com alta visibilidade validados.")

func test_tier_2_units_loading_and_stats() -> void:
	print("--- Testando Recursos de Custo 2 ---")
	UnitSpawner.clear_cache()
	UnitSpawner.load_all_units()
	
	for unit_id in TIER_2_UNITS:
		var stats: UnitStats = UnitSpawner.load_unit_stats(unit_id)
		assert(stats != null, "UnitStats para %s não deve ser nulo" % unit_id)
		assert(stats.cost == 2, "Unidade %s deve ter custo 2 (tem %d)" % [unit_id, stats.cost])
		print("  [OK] Custo 2 verificado: %s | Habilidade: %s" % [stats.unit_name, stats.ability_name])

func test_tier_2_abilities_casting() -> void:
	print("--- Testando Execução Geral das Habilidades (1★ e 3★) ---")
	for unit_id in TIER_2_UNITS:
		# Instância 1 estrela
		var unit: BaseUnit3D = UnitSpawner.spawn_unit(unit_id, 1, 0)
		assert(unit != null, "BaseUnit3D para %s deve instanciar com sucesso" % unit_id)
		root.add_child(unit)
		unit.board_position = Vector2i(0, 0)
		unit.current_state = BaseUnit3D.State.ATTACKING
		unit.current_mana = unit.stats.max_mana
		unit.cast_ability()
		
		# Instância 3 estrelas para escalonamento
		var unit_3star: BaseUnit3D = UnitSpawner.spawn_unit(unit_id, 3, 0)
		assert(unit_3star != null, "BaseUnit3D 3★ para %s deve instanciar" % unit_id)
		root.add_child(unit_3star)
		unit_3star.board_position = Vector2i(1, 1)
		unit_3star.current_state = BaseUnit3D.State.ATTACKING
		unit_3star.current_mana = unit_3star.stats.max_mana
		unit_3star.cast_ability()
		
		unit.queue_free()
		unit_3star.queue_free()
		print("  [OK] Habilidade de %s executada com sucesso em 1★ e 3★." % unit_id)

func test_specific_tier_2_mechanics() -> void:
	print("--- Testando Mecânicas Específicas de Custo 2 ---")
	
	# 1. Lobo-guará deve curar aliados feridos (não agir como assassino)
	var lobo: BaseUnit3D = UnitSpawner.spawn_unit("lobo_guara", 1, 0)
	root.add_child(lobo)
	lobo.board_position = Vector2i(2, 2)
	var ally: BaseUnit3D = UnitSpawner.spawn_unit("capivara", 1, 0)
	root.add_child(ally)
	ally.board_position = Vector2i(2, 3)
	ally.current_health = ally.get_max_health() - 100.0
	
	var health_before := ally.current_health
	lobo.current_state = BaseUnit3D.State.ATTACKING
	lobo.current_mana = lobo.stats.max_mana
	lobo.cast_ability()
	assert(ally.current_health > health_before, "Lobo-guará deve curar aliado ferido com Rastro da Lobeira!")
	lobo.queue_free()
	ally.queue_free()
	print("  [OK] Lobo-guará cura aliados feridos com sucesso.")
	
	# 2. Arara-azul-de-lear prioriza inimigo com maior dano de ataque
	var arara: BaseUnit3D = UnitSpawner.spawn_unit("arara_azul_lear", 1, 0)
	root.add_child(arara)
	arara.board_position = Vector2i(3, 3)
	
	var enemy_weak: BaseUnit3D = UnitSpawner.spawn_unit("capivara", 1, 1) # time 1
	root.add_child(enemy_weak)
	enemy_weak.board_position = Vector2i(3, 2)
	
	var enemy_strong: BaseUnit3D = UnitSpawner.spawn_unit("onca_pintada", 1, 1) # time 1, alto dano
	root.add_child(enemy_strong)
	enemy_strong.board_position = Vector2i(3, 1)
	
	arara.current_state = BaseUnit3D.State.ATTACKING
	arara.current_mana = arara.stats.max_mana
	arara.cast_ability()
	assert(arara.current_target == enemy_strong, "Arara-azul-de-lear deve priorizar o inimigo com maior ataque!")
	arara.queue_free()
	enemy_weak.queue_free()
	enemy_strong.queue_free()
	print("  [OK] Arara-azul-de-lear prioriza inimigo de maior ataque.")
	
	# 3. Papa-Figo causa dano, fraqueza no ataque e cura aliado
	var papa: BaseUnit3D = UnitSpawner.spawn_unit("papa_figo", 1, 0)
	root.add_child(papa)
	papa.board_position = Vector2i(1, 1)
	
	var papa_target: BaseUnit3D = UnitSpawner.spawn_unit("capivara", 1, 1)
	root.add_child(papa_target)
	papa_target.board_position = Vector2i(1, 2)
	papa.current_target = papa_target
	
	var target_hp_before := papa_target.current_health
	papa.current_state = BaseUnit3D.State.ATTACKING
	papa.current_mana = papa.stats.max_mana
	papa.cast_ability()
	assert(papa_target.current_health < target_hp_before, "Papa-Figo deve causar dano com Toque Gélido")
	assert(papa_target.attack_damage_multiplier < 1.0, "Papa-Figo deve aplicar enfraquecimento de ataque")
	papa.queue_free()
	papa_target.queue_free()
	print("  [OK] Papa-Figo causa dano e enfraquecimento de ataque com sucesso.")
	
	# 4. Caranguejo-uçá ganha escudo e causa dano
	var caranguejo: BaseUnit3D = UnitSpawner.spawn_unit("caranguejo_uca", 1, 0)
	root.add_child(caranguejo)
	caranguejo.board_position = Vector2i(0, 0)
	var crab_target: BaseUnit3D = UnitSpawner.spawn_unit("capivara", 1, 1)
	root.add_child(crab_target)
	crab_target.board_position = Vector2i(0, 1)
	caranguejo.current_target = crab_target
	
	var crab_target_hp := crab_target.current_health
	caranguejo.current_state = BaseUnit3D.State.ATTACKING
	caranguejo.current_mana = caranguejo.stats.max_mana
	caranguejo.cast_ability()
	assert(caranguejo.has_active_shield(), "Caranguejo-uçá deve ativar escudo com Pinça e Carapaça")
	assert(crab_target.current_health < crab_target_hp, "Caranguejo-uçá deve causar dano físico")
	caranguejo.queue_free()
	crab_target.queue_free()
	print("  [OK] Caranguejo-uçá ativa escudo e causa dano físico.")
	
	# 5. Tamanduá-bandeira ganha escudo e causa dano
	var tamandua: BaseUnit3D = UnitSpawner.spawn_unit("tamandua_bandeira", 1, 0)
	root.add_child(tamandua)
	tamandua.board_position = Vector2i(0, 0)
	var anteater_target: BaseUnit3D = UnitSpawner.spawn_unit("capivara", 1, 1)
	root.add_child(anteater_target)
	anteater_target.board_position = Vector2i(0, 1)
	tamandua.current_target = anteater_target
	
	var anteater_target_hp := anteater_target.current_health
	tamandua.current_state = BaseUnit3D.State.ATTACKING
	tamandua.current_mana = tamandua.stats.max_mana
	tamandua.cast_ability()
	assert(tamandua.has_active_shield(), "Tamanduá-bandeira deve ativar escudo")
	assert(anteater_target.current_health < anteater_target_hp, "Tamanduá-bandeira deve causar dano")
	tamandua.queue_free()
	anteater_target.queue_free()
	print("  [OK] Tamanduá-bandeira ativa escudo e causa dano.")
	
	# 6. Ipê-amarelo ganha escudo
	var ipe: BaseUnit3D = UnitSpawner.spawn_unit("ipe_amarelo", 1, 0)
	root.add_child(ipe)
	ipe.board_position = Vector2i(0, 0)
	ipe.current_state = BaseUnit3D.State.ATTACKING
	ipe.current_mana = ipe.stats.max_mana
	ipe.cast_ability()
	assert(ipe.has_active_shield(), "Ipê-amarelo deve ativar escudo Casca Dourada")
	ipe.queue_free()
	print("  [OK] Ipê-amarelo ativa Casca Dourada.")
	
	# 7. Palmito-juçara cura e concede mana
	var palmito: BaseUnit3D = UnitSpawner.spawn_unit("palmito_jucara", 1, 0)
	root.add_child(palmito)
	palmito.board_position = Vector2i(1, 1)
	var wounded_ally: BaseUnit3D = UnitSpawner.spawn_unit("capivara", 1, 0)
	root.add_child(wounded_ally)
	wounded_ally.board_position = Vector2i(1, 2)
	wounded_ally.current_health = wounded_ally.get_max_health() - 100.0
	wounded_ally.current_state = BaseUnit3D.State.ATTACKING
	wounded_ally.current_mana = 0.0
	
	var ally_hp_before := wounded_ally.current_health
	var ally_mana_before := wounded_ally.current_mana
	palmito.current_state = BaseUnit3D.State.ATTACKING
	palmito.current_mana = palmito.stats.max_mana
	palmito.cast_ability()
	assert(wounded_ally.current_health > ally_hp_before, "Palmito-juçara deve curar aliado")
	assert(wounded_ally.current_mana > ally_mana_before, "Palmito-juçara deve conceder mana a aliado")
	palmito.queue_free()
	wounded_ally.queue_free()
	print("  [OK] Palmito-juçara cura e concede mana com Frutos da Floresta.")
