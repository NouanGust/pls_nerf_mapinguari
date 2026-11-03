extends SceneTree

const TIER_4_UNITS = [
	"araucaria",
	"caapora",
	"comadre_fulozinha",
	"corpo_seco",
	"mboi_guacu",
	"onca_pintada",
	"pau_brasil",
	"pisadeira",
	"sumauma"
]

var _executed := false

func _process(_delta: float) -> bool:
	if _executed:
		return false
	_executed = true
	call_deferred("_run_async_tests")
	return false

func _run_async_tests() -> void:
	print("\n==========================================")
	print("INICIANDO TESTES: UNIDADES DE CUSTO 4 E HABILIDADES")
	print("==========================================\n")
	
	test_tier_4_units_loading_and_stats()
	test_tier_4_abilities_general_execution()
	await test_specific_tier_4_mechanics()
	
	print("\n==========================================")
	print("TODOS OS TESTES DE TIER 4 PASSARAM COM SUCESSO!")
	print("==========================================\n")
	quit(0)

func test_tier_4_units_loading_and_stats() -> void:
	print("--- 1. Testando Recursos de Custo 4 (9 Unidades) ---")
	UnitSpawner.clear_cache()
	UnitSpawner.load_all_units()
	
	for unit_id in TIER_4_UNITS:
		var stats: UnitStats = UnitSpawner.load_unit_stats(unit_id)
		assert(stats != null, "UnitStats para %s não deve ser nulo" % unit_id)
		assert(stats.cost in [4, 5], "Unidade %s deve ter custo 4 ou 5 (tem %d)" % [unit_id, stats.cost])
		assert(stats.tier in [4, 5], "Unidade %s deve ter tier 4 ou 5 (tem %d)" % [unit_id, stats.tier])
		assert(stats.ability_name != "", "Unidade %s deve possuir ability_name definido" % unit_id)
		assert(stats.ability_description != "", "Unidade %s deve possuir ability_description definido" % unit_id)
		print("  [OK] %s: Custo %d | Habilidade: '%s'" % [stats.unit_name, stats.cost, stats.ability_name])

func test_tier_4_abilities_general_execution() -> void:
	print("--- 2. Testando Execução Geral das Habilidades (1★ e 3★) ---")
	for unit_id in TIER_4_UNITS:
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

func test_specific_tier_4_mechanics() -> void:
	print("--- 3. Testando Mecânicas Específicas de Custo 4 ---")
	
	# ==========================================
	# 1. Araucária: Copa Protetora (Escudo para si e aliados próximos)
	# ==========================================
	var araucaria: BaseUnit3D = UnitSpawner.spawn_unit("araucaria", 1, 0)
	root.add_child(araucaria)
	araucaria.board_position = Vector2i(0, 0)
	araucaria.global_position = Vector3(0, 0, 0)
	araucaria.current_state = BaseUnit3D.State.ATTACKING
	
	var ally_tree: BaseUnit3D = UnitSpawner.spawn_unit("capivara", 1, 0)
	root.add_child(ally_tree)
	ally_tree.board_position = Vector2i(1, 0)
	ally_tree.global_position = Vector3(1.5, 0, 0)
	
	araucaria.cast_ability()
	await create_timer(0.50, false).timeout
	assert(araucaria.has_active_shield(), "Araucária deve ativar escudo em si mesma")
	assert(araucaria.current_shield >= 260.0, "Escudo da Araucária deve ser de pelo menos 260")
	assert(ally_tree.has_active_shield(), "Aliado próximo deve receber escudo da Copa Protetora")
	print("  [OK] Araucária: Copa Protetora concedeu escudo de %.1f à Araucária e %.1f ao aliado." % [araucaria.current_shield, ally_tree.current_shield])
	
	araucaria.queue_free()
	ally_tree.queue_free()
	
	# ==========================================
	# 2. Caapora: Flecha Perfurante (Dano em linha reta e Shred de Armadura)
	# ==========================================
	var caapora: BaseUnit3D = UnitSpawner.spawn_unit("caapora", 1, 0)
	root.add_child(caapora)
	caapora.board_position = Vector2i(0, 0)
	caapora.global_position = Vector3(0, 0, 0)
	caapora.current_state = BaseUnit3D.State.ATTACKING
	
	var enemy_front: BaseUnit3D = UnitSpawner.spawn_unit("tatu_bola", 1, 1)
	var enemy_back: BaseUnit3D = UnitSpawner.spawn_unit("capivara", 1, 1)
	root.add_child(enemy_front)
	root.add_child(enemy_back)
	enemy_front.board_position = Vector2i(0, 2)
	enemy_front.global_position = Vector3(0, 0, 2.0)
	enemy_back.board_position = Vector2i(0, 4)
	enemy_back.global_position = Vector3(0, 0, 4.0)
	
	caapora.current_target = enemy_front
	var front_hp_before := enemy_front.current_health
	var back_hp_before := enemy_back.current_health
	
	caapora.cast_ability()
	await create_timer(0.65, false).timeout
	assert(enemy_front.current_health < front_hp_before, "Inimigo frontal deve sofrer dano da Flecha Perfurante")
	assert(enemy_back.current_health < back_hp_before, "Inimigo de trás deve sofrer dano perfurante na mesma linha")
	assert(enemy_front.armor_shred_amount > 0.0, "Primeiro inimigo atingido deve ter armadura reduzida")
	print("  [OK] Caapora: Flecha atravessou ambos os alvos em linha e quebrou armadura do primeiro.")
	
	caapora.queue_free()
	enemy_front.queue_free()
	enemy_back.queue_free()
	
	# ==========================================
	# 3. Comadre Fulozinha: Invocação da Floresta (Espíritos da Mata)
	# ==========================================
	var comadre: BaseUnit3D = UnitSpawner.spawn_unit("comadre_fulozinha", 1, 0)
	root.add_child(comadre)
	comadre.board_position = Vector2i(0, 0)
	comadre.global_position = Vector3(0, 0, 0)
	comadre.current_state = BaseUnit3D.State.ATTACKING
	
	var injured_friend: BaseUnit3D = UnitSpawner.spawn_unit("capivara", 1, 0)
	root.add_child(injured_friend)
	injured_friend.board_position = Vector2i(1, 0)
	injured_friend.global_position = Vector3(1.0, 0, 0)
	injured_friend.current_health = injured_friend.get_max_health() * 0.5
	
	var comadre_foe: BaseUnit3D = UnitSpawner.spawn_unit("tatu_bola", 1, 1)
	root.add_child(comadre_foe)
	comadre_foe.board_position = Vector2i(2, 0)
	comadre_foe.global_position = Vector3(2.0, 0, 0)
	
	comadre.cast_ability()
	await create_timer(0.35, false).timeout
	var spirits = root.find_child("ComadreSpirits", true, false)
	assert(spirits != null, "Espíritos da Mata devem ser invocados na cena")
	print("  [OK] Comadre Fulozinha: Invocou espíritos da floresta com sucesso.")
	
	if is_instance_valid(spirits):
		spirits.queue_free()
	comadre.queue_free()
	injured_friend.queue_free()
	comadre_foe.queue_free()
	
	# ==========================================
	# 4. Corpo-Seco: Drenagem Vital (Dano Verdadeiro e Dreno de Vida)
	# ==========================================
	var corpo: BaseUnit3D = UnitSpawner.spawn_unit("corpo_seco", 1, 0)
	root.add_child(corpo)
	corpo.board_position = Vector2i(0, 0)
	corpo.global_position = Vector3(0, 0, 0)
	corpo.current_state = BaseUnit3D.State.ATTACKING
	corpo.current_health = corpo.get_max_health() * 0.5
	
	var drain_target: BaseUnit3D = UnitSpawner.spawn_unit("tatu_bola", 1, 1)
	root.add_child(drain_target)
	drain_target.board_position = Vector2i(1, 0)
	drain_target.global_position = Vector3(1.5, 0, 0)
	
	corpo.cast_ability()
	assert(corpo.stats.ability_damage_type == UnitStats.DamageType.TRUE, "Drenagem Vital de Corpo-Seco deve ser dano verdadeiro")
	assert(corpo.stats.ability_heal > 0.0, "Corpo-Seco deve ter atributo de cura definido")
	print("  [OK] Corpo-Seco: Drenagem Vital configurada com dano verdadeiro e dreno de vida.")
	
	corpo.queue_free()
	drain_target.queue_free()
	
	# ==========================================
	# 5. Mboi-Guaçu: Constrição Mortal (Stun, Dano ao longo do tempo e Escudo)
	# ==========================================
	var mboi: BaseUnit3D = UnitSpawner.spawn_unit("mboi_guacu", 1, 0)
	root.add_child(mboi)
	mboi.board_position = Vector2i(0, 0)
	mboi.global_position = Vector3(0, 0, 0)
	mboi.current_state = BaseUnit3D.State.ATTACKING
	
	var mboi_victim: BaseUnit3D = UnitSpawner.spawn_unit("tatu_bola", 1, 1)
	root.add_child(mboi_victim)
	mboi_victim.board_position = Vector2i(1, 0)
	mboi_victim.global_position = Vector3(1.2, 0, 0)
	mboi.current_target = mboi_victim
	
	mboi.cast_ability()
	await create_timer(0.35, false).timeout
	assert(mboi_victim.is_stunned(), "Alvo deve ficar constrito/imobilizado pelo Mboi-Guaçu")
	assert(mboi.has_active_shield(), "Mboi-Guaçu deve ativar escudo protetor de escamas")
	assert(mboi_victim.armor_shred_amount >= 25.0, "Armadura da vítima deve ser triturada na constrição")
	print("  [OK] Mboi-Guaçu: Alvo imobilizado, armadura reduzida e escudo ativado.")
	
	mboi.queue_free()
	mboi_victim.queue_free()
	
	# ==========================================
	# 6. Onça-pintada: Bote de Emboscada (Salto, Dano Crítico, Sangramento)
	# ==========================================
	var onca: BaseUnit3D = UnitSpawner.spawn_unit("onca_pintada", 1, 0)
	root.add_child(onca)
	onca.board_position = Vector2i(0, 0)
	onca.global_position = Vector3(0, 0, 0)
	onca.current_state = BaseUnit3D.State.ATTACKING
	
	var prey_low_hp: BaseUnit3D = UnitSpawner.spawn_unit("sabia_laranjeira", 1, 1)
	root.add_child(prey_low_hp)
	prey_low_hp.board_position = Vector2i(3, 0)
	prey_low_hp.global_position = Vector3(3.5, 0, 0)
	prey_low_hp.current_health = 150.0
	
	var prey_high_hp: BaseUnit3D = UnitSpawner.spawn_unit("tatu_bola", 1, 1)
	root.add_child(prey_high_hp)
	prey_high_hp.board_position = Vector2i(1, 0)
	prey_high_hp.global_position = Vector3(1.2, 0, 0)
	prey_high_hp.current_health = 800.0
	
	var hp_prey_before := prey_low_hp.current_health
	onca.cast_ability()
	await create_timer(0.65, false).timeout
	assert(onca.global_position.distance_to(prey_low_hp.global_position) < 2.0, "Onça deve saltar para o inimigo de menor vida")
	assert(prey_low_hp.current_health < hp_prey_before or prey_low_hp.current_state == BaseUnit3D.State.DEAD, "Vítima deve sofrer dano massivo do bote")
	print("  [OK] Onça-pintada: Saltou sobre o alvo mais fraco e desferiu dano elevado.")
	
	onca.queue_free()
	prey_low_hp.queue_free()
	prey_high_hp.queue_free()
	
	# ==========================================
	# 7. Pau Brasil: Florada Dourada (Dano, Enfraquecimento e Escudo)
	# ==========================================
	var pau_brasil: BaseUnit3D = UnitSpawner.spawn_unit("pau_brasil", 1, 0)
	root.add_child(pau_brasil)
	pau_brasil.board_position = Vector2i(0, 0)
	pau_brasil.global_position = Vector3(0, 0, 0)
	pau_brasil.current_state = BaseUnit3D.State.ATTACKING
	
	var bloom_ally: BaseUnit3D = UnitSpawner.spawn_unit("capivara", 1, 0)
	root.add_child(bloom_ally)
	bloom_ally.board_position = Vector2i(1, 0)
	bloom_ally.global_position = Vector3(1.5, 0, 0)
	
	var bloom_enemy: BaseUnit3D = UnitSpawner.spawn_unit("tatu_bola", 1, 1)
	root.add_child(bloom_enemy)
	bloom_enemy.board_position = Vector2i(2, 0)
	bloom_enemy.global_position = Vector3(2.0, 0, 0)
	var enemy_hp_before := bloom_enemy.current_health
	
	pau_brasil.cast_ability()
	await create_timer(0.50, false).timeout
	assert(bloom_enemy.current_health < enemy_hp_before, "Inimigo deve sofrer dano da Florada Dourada")
	assert(bloom_enemy.attack_damage_multiplier <= 0.75, "Inimigo deve ter ataque enfraquecido pelo pólen")
	assert(bloom_ally.has_active_shield(), "Aliado na área da florada deve receber escudo")
	print("  [OK] Pau Brasil: Dano e fraqueza no inimigo e escudo floral no aliado aplicados.")
	
	pau_brasil.queue_free()
	bloom_ally.queue_free()
	bloom_enemy.queue_free()
	
	# ==========================================
	# 8. Pisadeira: Paralisia do Terror (Stun em área, Dano Mágico e Dreno de Mana)
	# ==========================================
	var pisadeira: BaseUnit3D = UnitSpawner.spawn_unit("pisadeira", 1, 0)
	root.add_child(pisadeira)
	pisadeira.board_position = Vector2i(0, 0)
	pisadeira.global_position = Vector3(0, 0, 0)
	pisadeira.current_state = BaseUnit3D.State.ATTACKING
	
	var terror_enemy1: BaseUnit3D = UnitSpawner.spawn_unit("tatu_bola", 1, 1)
	var terror_enemy2: BaseUnit3D = UnitSpawner.spawn_unit("capivara", 1, 1)
	root.add_child(terror_enemy1)
	root.add_child(terror_enemy2)
	terror_enemy1.board_position = Vector2i(1, 0)
	terror_enemy1.global_position = Vector3(1.5, 0, 0)
	terror_enemy1.current_mana = 50.0
	terror_enemy2.board_position = Vector2i(2, 0)
	terror_enemy2.global_position = Vector3(2.5, 0, 0)
	terror_enemy2.current_mana = 50.0
	
	pisadeira.cast_ability()
	await create_timer(0.70, false).timeout
	assert(terror_enemy1.is_stunned(), "Inimigo 1 deve ficar paralisado de terror")
	assert(terror_enemy2.is_stunned(), "Inimigo 2 deve ficar paralisado de terror")
	assert(terror_enemy1.current_mana < 50.0, "Mana do inimigo 1 deve ser drenada pela Pisadeira")
	assert(terror_enemy2.current_mana < 50.0, "Mana do inimigo 2 deve ser drenada pela Pisadeira")
	print("  [OK] Pisadeira: Paralisou múltiplos inimigos e drenou mana com sucesso.")
	
	pisadeira.queue_free()
	terror_enemy1.queue_free()
	terror_enemy2.queue_free()
	
	# ==========================================
	# 9. Sumaúma: Raízes Guardiãs (Enraizamento em área, Dano e Cura/Escudo de Aliados)
	# ==========================================
	var sumauma: BaseUnit3D = UnitSpawner.spawn_unit("sumauma", 1, 0)
	root.add_child(sumauma)
	sumauma.board_position = Vector2i(0, 0)
	sumauma.global_position = Vector3(0, 0, 0)
	sumauma.current_state = BaseUnit3D.State.ATTACKING
	
	var sumauma_ally: BaseUnit3D = UnitSpawner.spawn_unit("capivara", 1, 0)
	root.add_child(sumauma_ally)
	sumauma_ally.board_position = Vector2i(1, 0)
	sumauma_ally.global_position = Vector3(1.5, 0, 0)
	sumauma_ally.current_health = sumauma_ally.get_max_health() * 0.4
	var ally_health_before := sumauma_ally.current_health
	
	var sumauma_enemy: BaseUnit3D = UnitSpawner.spawn_unit("tatu_bola", 1, 1)
	root.add_child(sumauma_enemy)
	sumauma_enemy.board_position = Vector2i(2, 0)
	sumauma_enemy.global_position = Vector3(2.5, 0, 0)
	var enemy_hp_init := sumauma_enemy.current_health
	
	sumauma.cast_ability()
	await create_timer(0.70, false).timeout
	assert(sumauma_enemy.is_stunned(), "Inimigo deve ficar enraizado pelas raízes da Sumaúma")
	assert(sumauma_enemy.current_health < enemy_hp_init, "Inimigo deve sofrer dano do impacto das raízes")
	assert(sumauma_ally.current_health > ally_health_before, "Aliado deve ser curado pelas raízes guardiãs")
	assert(sumauma_ally.has_active_shield(), "Aliado deve receber escudo protetor da Sumaúma")
	print("  [OK] Sumaúma: Enraizou inimigo, curou aliado ferido (%.1f -> %.1f) e concedeu escudo." % [ally_health_before, sumauma_ally.current_health])
	
	sumauma.queue_free()
	sumauma_ally.queue_free()
	sumauma_enemy.queue_free()
