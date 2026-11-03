extends SceneTree

const BattleClock = preload("res://Scripts/Systems/battle_clock.gd")
const RegionRosters = preload("res://Scripts/Systems/region_rosters.gd")

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	print("==================================================")
	print("SUITE DE TESTES: 9 ORIGENS, COMBATE E ROSTERS")
	print("==================================================")
	
	if not root.has_node("BattleClock"):
		var clock = BattleClock.new()
		clock.name = "BattleClock"
		root.add_child(clock)

	var catalog := UnitSpawner.load_all_units()
	assert(catalog.size() == 66, "Catalogo deve conter exatamente 66 unidades")

	# ----------------------------------------------------
	# [1] Verificação dos 6 Rosters Regionais (9 unidades únicas cada)
	# ----------------------------------------------------
	print("\n[1] Verificando Rosters Regionais (Seção 6 da proposta):")
	var regions := ["amazonia", "cerrado", "pantanal", "caatinga", "mata_atlantica", "litoral"]
	for reg_id in regions:
		var roster: Array = RegionRosters.get_roster(reg_id, 9)
		assert(roster.size() == 9, "Regiao %s deve ter exatamente 9 unidades, obteve %d" % [reg_id, roster.size()])
		var seen := {}
		for uid in roster:
			assert(catalog.has(uid), "Unidade %s do roster %s deve existir no catalogo" % [uid, reg_id])
			assert(not seen.has(uid), "Unidade duplicada %s no roster %s" % [uid, reg_id])
			seen[uid] = true
		print("  ✓ Região %s: 9 unidades únicas e válidas" % reg_id)

	# ----------------------------------------------------
	# [2] Verificação das Regras e Patamares do SynergySystem
	# ----------------------------------------------------
	print("\n[2] Verificando Patamares das 9 Novas Origens:")
	var expected_thresholds = {
		"Seiva": [3, 6, 9],
		"Vigília": [2, 4, 6, 8],
		"Correnteza": [3, 6, 9],
		"Vozes": [3, 6, 9],
		"Ferocidade": [2, 4, 6, 8],
		"Travessia": [2, 4, 6, 8],
		"Assombro": [2, 4, 6, 8],
		"Encanto": [2, 4, 6, 8],
		"Fulgor": [1, 2, 3, 4]
	}

	for orig in expected_thresholds.keys():
		var rule := SynergySystem.get_rule_for_tag(orig)
		assert(not rule.is_empty(), "Regra para %s deve existir no SynergySystem" % orig)
		assert(rule.field == "origins", "Campo da sinergia %s deve ser 'origins'" % orig)
		var th: Array = rule.thresholds
		assert(th == expected_thresholds[orig], "Patamares de %s incorretos: %s" % [orig, str(th)])
		assert(rule.effects.size() == th.size(), "Numero de efeitos deve bater com patamares para %s" % orig)
		# Checar ausencia de emojis nos textos dos efeitos
		for eff in rule.effects:
			var txt: String = eff.get("text", "")
			for c in txt:
				var code := c.unicode_at(0)
				assert(code < 0x2500 or code > 0x1F9FF, "Emoji detectado no texto de %s: %s" % [orig, c])
		print("  ✓ Origem %s: patamares %s validados sem emojis" % [orig, str(th)])

	# ----------------------------------------------------
	# [3] Cálculo de Sinergia e Aplicação Estrita aos Membros da Origem
	# ----------------------------------------------------
	print("\n[3] Testando Cálculo de Sinergia e Filtro por Origem:")
	var syn_system = SynergySystem.new()
	root.add_child(syn_system)

	var seiva_units := ["araucaria", "sumauma", "pau_brasil"] # 3 Seiva
	var fulgor_units := ["mae_de_ouro", "boitata"] # 2 Fulgor
	var test_team: Array = []

	for uid in seiva_units:
		var u = BaseUnit3D.new()
		u.initialize(catalog[uid], 1)
		u.team = 0
		test_team.append(u)

	for uid in fulgor_units:
		var u = BaseUnit3D.new()
		u.initialize(catalog[uid], 1)
		u.team = 0
		test_team.append(u)

	var syn_results: Dictionary = syn_system.update_synergies(test_team)
	var team_results: Array = syn_results.get(0, [])
	var active_names := []
	for syn in team_results:
		if syn.active:
			active_names.append(syn.name)
	
	assert(active_names.has("Seiva"), "Deve ativar sinergia Seiva (3)")
	assert(active_names.has("Fulgor"), "Deve ativar sinergia Fulgor (2)")

	# As unidades de Seiva devem ter bônus de Seiva mas NÃO de Fulgor
	for u in test_team.slice(0, 3):
		assert(float(u.synergy_bonuses.get("seiva_heal_pct", 0.0)) > 0.0, "Seiva deve ter cura da Seiva")
		assert(float(u.synergy_bonuses.get("fulgor_mana", 0.0)) == 0.0, "Unidade sem Fulgor nao deve receber mana de Fulgor")

	# As unidades de Fulgor devem ter bônus de Fulgor mas NÃO de Seiva
	for u in test_team.slice(3, 5):
		assert(float(u.synergy_bonuses.get("fulgor_mana", 0.0)) == 10.0, "Fulgor (2) deve conceder 10 de mana")
		assert(float(u.synergy_bonuses.get("fulgor_pct", 0.0)) == 0.12, "Fulgor (2) deve conceder 12% de amplificacao")
		assert(float(u.synergy_bonuses.get("seiva_heal_pct", 0.0)) == 0.0, "Unidade sem Seiva nao deve receber cura de Seiva")

	print("  ✓ Bônus de sinergia aplicados estritamente apenas a membros da respectiva origem!")

	# ----------------------------------------------------
	# [4] Teste de Runtime: Vigília (Escudo e Resistência a Controle)
	# ----------------------------------------------------
	print("\n[4] Testando Runtime de Vigília:")
	var u_vigilia = BaseUnit3D.new()
	u_vigilia.initialize(catalog["tatu_bola"], 1)
	u_vigilia.board_position = Vector2i(0, 0)
	u_vigilia.current_health = u_vigilia.get_max_health()
	u_vigilia.synergy_bonuses = {
		"vigilia_shield_pct": 0.28,
		"vigilia_control_resist": 0.35
	}
	u_vigilia.in_combat = true
	u_vigilia.origin_runtime.reset_for_combat()

	# Dano de 60% que deixa vida em 40% (abaixo de 50%)
	u_vigilia.origin_runtime.check_vigilia_trigger(u_vigilia.get_max_health() * 0.60)
	assert(u_vigilia.origin_runtime.vigilia_triggered == true, "Vigília deve engatilhar")
	assert(u_vigilia.current_shield > 0.0, "Vigília deve conceder escudo")
	assert(u_vigilia.origin_runtime.get_control_resist_bonus() == 0.35, "Vigília deve conceder 35% de resistencia a controle")
	print("  ✓ Vigília engatilhou escudo e resistência a controle com sucesso!")

	# ----------------------------------------------------
	# [5] Teste de Runtime: Ferocidade (Stacks de Furor e Cura no 3º Ataque)
	# ----------------------------------------------------
	print("\n[5] Testando Runtime de Ferocidade:")
	var u_feroz = BaseUnit3D.new()
	u_feroz.initialize(catalog["onca_pintada"], 1)
	u_feroz.board_position = Vector2i(1, 1)
	u_feroz.current_health = 500.0
	u_feroz.synergy_bonuses = {
		"feroc_per_stack": 0.035,
		"feroc_heal_pct": 0.02
	}
	u_feroz.in_combat = true
	u_feroz.origin_runtime.reset_for_combat()

	var dummy_enemy = BaseUnit3D.new()
	dummy_enemy.initialize(catalog["capivara"], 1)
	dummy_enemy.board_position = Vector2i(1, 2)

	# 1º ataque: 1 stack
	u_feroz.origin_runtime.on_basic_attack_hit(dummy_enemy)
	assert(u_feroz.origin_runtime.feroc_stacks == 1, "Deve ter 1 stack")
	# 2º ataque: 2 stacks
	u_feroz.origin_runtime.on_basic_attack_hit(dummy_enemy)
	assert(u_feroz.origin_runtime.feroc_stacks == 2, "Deve ter 2 stacks")
	# 3º ataque: cura ativada
	var hp_before: float = u_feroz.current_health
	u_feroz.origin_runtime.on_basic_attack_hit(dummy_enemy)
	assert(u_feroz.current_health > hp_before, "3º ataque deve curar vida")
	print("  ✓ Ferocidade: acúmulo de stacks e cura a cada 3 ataques validados!")

	# ----------------------------------------------------
	# [6] Teste de Runtime: Encanto e Fulgor (Escalonamento de Habilidade)
	# ----------------------------------------------------
	print("\n[6] Testando Runtime de Encanto e Fulgor:")
	var u_fulgor = BaseUnit3D.new()
	u_fulgor.initialize(catalog["boitata"], 1)
	u_fulgor.board_position = Vector2i(2, 1)
	u_fulgor.synergy_bonuses = {
		"fulgor_mana": 28.0,
		"fulgor_pct": 0.25
	}
	u_fulgor.in_combat = true
	u_fulgor.origin_runtime.reset_for_combat()

	# Verifica mana inicial de abertura
	assert(u_fulgor.current_mana >= 28.0, "Fulgor deve iniciar com mana bônus")

	# Primeira conjuração: amplificada
	var scale1: float = u_fulgor.origin_runtime.on_ability_start()
	assert(is_equal_approx(scale1, 1.25), "Primeira conjuracao com 25%% bonus deve ter scale 1.25, obteve %f" % scale1)
	u_fulgor.origin_runtime.on_ability_concluded()

	# Segunda conjuração: normal
	var scale2: float = u_fulgor.origin_runtime.on_ability_start()
	assert(is_equal_approx(scale2, 1.0), "Segunda conjuracao nao deve ter bonus do Fulgor")
	u_fulgor.origin_runtime.on_ability_concluded()
	print("  ✓ Fulgor: mana de abertura e amplificação da primeira conjuração validados!")

	# ----------------------------------------------------
	# [7] Teste de Runtime: Assombro (Marca e Redução de Defesa)
	# ----------------------------------------------------
	print("\n[7] Testando Runtime de Assombro:")
	var u_assombro = BaseUnit3D.new()
	u_assombro.initialize(catalog["cumacanga"], 1)
	u_assombro.board_position = Vector2i(2, 2)
	u_assombro.synergy_bonuses = {
		"assombro_pct": 0.22
	}
	u_assombro.in_combat = true
	u_assombro.origin_runtime.reset_for_combat()

	var victim = BaseUnit3D.new()
	victim.initialize(catalog["mapinguari"], 1)
	victim.board_position = Vector2i(2, 3)
	victim.in_combat = true
	victim.origin_runtime.reset_for_combat()

	var victim_initial_armor: float = victim.get_effective_armor()
	u_assombro.origin_runtime.apply_assombro_to_target(victim)
	assert(is_equal_approx(victim.origin_runtime.get_defense_reduction_multiplier(), 0.78), "Defesas da vitima devem ser reduzidas em 22%")
	assert(victim.get_effective_armor() < victim_initial_armor, "Armadura efetiva deve ser menor apos marca de Assombro")
	print("  ✓ Assombro: aplicação de marca e trituração de defesas validadas!")

	# ----------------------------------------------------
	# [8] Teste de Teto de Controle e Janela de Imunidade Pós-Stun
	# ----------------------------------------------------
	print("\n[8] Testando Teto de Atordoamento (máx 1.0s) e Imunidade de 0.75s:")
	var u_target = BaseUnit3D.new()
	u_target.initialize(catalog["capivara"], 1)
	u_target.board_position = Vector2i(3, 3)
	u_target.in_combat = true

	# Aplicar atordoamento longo de 3 segundos
	u_target.apply_stun(3.0, "STUN")
	assert(u_target.is_stunned() == true, "Alvo deve estar atordoado")
	var remaining_stun_sec: float = float(u_target.stunned_until_msec - BattleClock.now_msec()) / 1000.0
	assert(remaining_stun_sec <= 1.05, "Duracao do atordoamento forte nao pode exceder 1.0s (obteve %.2fs)" % remaining_stun_sec)

	# Simular fim do atordoamento
	u_target.stunned_until_msec = BattleClock.now_msec() - 10
	assert(u_target.is_stunned() == false, "Atordoamento deve ter expirado")

	# Tentativa imediata de atordoar novamente deve ser bloqueada pela janela pós-controle de 0.75s
	u_target.apply_stun(1.0, "STUN_2")
	assert(u_target.is_stunned() == false, "Novo atordoamento durante janela de imunidade pos-controle deve ser bloqueado")
	print("  ✓ Teto de 1.0s e janela de imunidade pós-controle de 0.75s validados com sucesso!")

	print("\n==================================================")
	print("TODOS OS TESTES DE NOVAS ORIGENS E COMBATE PASSARAM!")
	print("==================================================")
	quit(0)
