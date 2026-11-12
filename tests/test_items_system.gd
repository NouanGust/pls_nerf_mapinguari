extends SceneTree

## Teste Automatizado do Sistema de Itens, Relíquias e Utilitários do Folchess

var log_lines: Array[String] = []

func log_msg(msg: String) -> void:
	print(msg)
	log_lines.append(msg)

func _initialize() -> void:
	_run_tests()

func _run_tests() -> void:
	log_msg("\n==================================================")
	log_msg("INICIANDO SUITE DE TESTES: SISTEMA DE ITENS")
	log_msg("==================================================")

	var success: bool = true
	success = success and _test_item_registry()
	success = success and _test_recipes()
	success = success and _test_unit_item_cap_and_equip()
	success = success and _test_component_fusion_on_unit()
	success = success and _test_stat_modifiers()
	success = success and _test_utilitaries()

	if success:
		log_msg("\n>> TODOS OS TESTES DE ITENS PASSARAM COM SUCESSO! <<\n")
		quit(0)
	else:
		log_msg("\n>> FALHA EM TESTES DO SISTEMA DE ITENS! <<\n")
		quit(1)

func _test_item_registry() -> bool:
	log_msg("\n[1] Testando ItemRegistry...")
	var comps: Array[ItemData] = ItemRegistry.get_basic_components()
	if comps.size() < 8:
		log_msg("Falha: Esperado pelo menos 8 componentes básicos, encontrado: " + str(comps.size()))
		return false
	log_msg("  ✓ 8 Componentes básicos registrados com sucesso.")

	var pequi_item: ItemData = ItemRegistry.get_item(&"caroco_pequi")
	if not pequi_item:
		log_msg("Falha: Item caroco_pequi não encontrado no registro!")
		return false
	if pequi_item.unique_effect_id != &"pequi_spikes":
		log_msg("Falha: Passiva única do pequi incorreta!")
		return false
	log_msg("  ✓ Item Caroço de Pequi Espinhoso registrado com efeito &pequi_spikes.")

	var coroa: ItemData = ItemRegistry.get_item(&"coroa_icamiabas")
	if not coroa or coroa.team_size_bonus != 1:
		log_msg("Falha: Coroa das Icamiabas deve conceder +1 de tamanho de equipe!")
		return false
	log_msg("  ✓ Coroa das Icamiabas registrada com +1 team_size_bonus.")
	return true

func _test_recipes() -> bool:
	log_msg("\n[2] Testando Receitas de Combinação de Itens...")
	# Braúna + Cipó -> Chicote da Fulozinha
	var fulozinha: ItemData = ItemRegistry.find_combination(&"lasca_brauna", &"cipo_titica")
	if not fulozinha or fulozinha.id != &"chicote_fulozinha":
		log_msg("Falha na receita: Braúna + Cipó deve criar chicote_fulozinha!")
		return false
	log_msg("  ✓ Lasca de Braúna + Cipó-Titica = Chicote da Comadre Fulozinha")

	# Jabuti + Mandioca -> Caroço de Pequi
	var pequi: ItemData = ItemRegistry.find_combination(&"casca_jabuti", &"raiz_mandioca")
	if not pequi or pequi.id != &"caroco_pequi":
		log_msg("Falha na receita: Casca de Jabuti + Mandioca deve criar caroco_pequi!")
		return false
	log_msg("  ✓ Casca de Jabuti + Raiz de Mandioca = Caroço de Pequi Espinhoso")

	# Cabaça + Cabaça -> Rapé de Piri-Piri
	var rape: ItemData = ItemRegistry.find_combination(&"cabaca_agua", &"cabaca_agua")
	if not rape or rape.id != &"rape_piripiri":
		log_msg("Falha na receita: Cabaça + Cabaça deve criar rape_piripiri!")
		return false
	log_msg("  ✓ Cabaça + Cabaça = Rapé Sagrado de Piri-Piri")

	# Muiraquitã + Pimenta -> Emblema Caatinga
	var emblema_caatinga: ItemData = ItemRegistry.find_combination(&"muiraquita_bruto", &"pimenta_cumari")
	if not emblema_caatinga or emblema_caatinga.origin_grant != "Caatinga":
		log_msg("Falha no emblema: Muiraquitã + Pimenta deve conceder Caatinga!")
		return false
	log_msg("  ✓ Muiraquitã Bruto + Pimenta Cumari = Emblema de Caatinga (Pedra do Sol)")
	return true

func _test_unit_item_cap_and_equip() -> bool:
	log_msg("\n[3] Testando Limite Estrito de 2 Itens por Unidade...")
	var unit := BaseUnit3D.new()
	var stats := UnitStats.new()
	stats.unit_name = "Mapinguari"
	stats.max_health = 1000.0
	stats.attack_damage = 80.0
	unit.stats = stats

	var mgr := ItemManager.new()

	var item1: ItemData = ItemRegistry.get_item(&"caroco_pequi")
	var item2: ItemData = ItemRegistry.get_item(&"chicote_fulozinha")
	var item3: ItemData = ItemRegistry.get_item(&"esporao_capelobo")

	mgr.add_item_to_inventory(item1)
	mgr.add_item_to_inventory(item2)
	mgr.add_item_to_inventory(item3)

	# 1. Equipar primeiro item
	var ok1 := mgr.equip_item_to_unit(item1, unit)
	if not ok1 or unit.get_equipped_items().size() != 1:
		log_msg("Falha ao equipar 1º item!")
		unit.queue_free()
		return false
	log_msg("  ✓ 1º Item equipado com sucesso (%d/2)." % unit.get_equipped_items().size())

	# 2. Equipar segundo item
	var ok2 := mgr.equip_item_to_unit(item2, unit)
	if not ok2 or unit.get_equipped_items().size() != 2:
		log_msg("Falha ao equipar 2º item!")
		unit.queue_free()
		return false
	log_msg("  ✓ 2º Item equipado com sucesso (%d/2)." % unit.get_equipped_items().size())

	# 3. Tentar equipar terceiro item (DEVE FALHAR por exceder o limite de 2!)
	var ok3 := mgr.equip_item_to_unit(item3, unit)
	if ok3 or unit.get_equipped_items().size() > 2:
		log_msg("Falha: Unidade não deveria permitir mais de 2 itens!")
		unit.queue_free()
		return false
	log_msg("  ✓ Bloqueio de 3º item validado com sucesso! A unidade manteve exatamente 2 itens.")

	unit.queue_free()
	return true

func _test_component_fusion_on_unit() -> bool:
	log_msg("\n[4] Testando Fusão Dinâmica de Componentes na Unidade...")
	var unit := BaseUnit3D.new()
	var stats := UnitStats.new()
	stats.unit_name = "Curupira"
	stats.max_health = 600.0
	stats.attack_damage = 60.0
	unit.stats = stats

	var mgr := ItemManager.new()
	var comp1: ItemData = ItemRegistry.get_item(&"lasca_brauna")
	var comp2: ItemData = ItemRegistry.get_item(&"cipo_titica")

	mgr.add_item_to_inventory(comp1)
	mgr.add_item_to_inventory(comp2)

	# Equipa Braúna
	mgr.equip_item_to_unit(comp1, unit)
	if unit.get_equipped_items().size() != 1 or unit.get_equipped_items()[0].id != &"lasca_brauna":
		log_msg("Falha: Braúna deveria estar equipada como componente.")
		unit.queue_free()
		return false

	# Equipa Cipó-Titica -> Deve fundir em Chicote da Fulozinha!
	mgr.equip_item_to_unit(comp2, unit)
	var eq: Array[ItemData] = unit.get_equipped_items()
	if eq.size() != 1 or eq[0].id != &"chicote_fulozinha":
		log_msg("Falha na fusão: Componentes deveriam ter fundido em chicote_fulozinha na unidade!")
		unit.queue_free()
		return false
	log_msg("  ✓ Fusão na unidade concluída com sucesso: Braúna + Cipó viraram Chicote da Fulozinha!")
	log_msg("  ✓ Slots ocupados após a fusão: %d/2 (slot 2 permaneceu livre para outro item)." % eq.size())

	unit.queue_free()
	return true

func _test_stat_modifiers() -> bool:
	log_msg("\n[5] Testando Bônus de Atributos Efetivos...")
	var unit := BaseUnit3D.new()
	var stats := UnitStats.new()
	stats.unit_name = "Capelobo"
	stats.max_health = 800.0
	stats.attack_damage = 70.0
	stats.armor = 20.0
	stats.magic_resist = 15.0
	stats.attack_speed = 1.0
	unit.stats = stats

	var initial_hp := unit.get_max_health()
	var initial_ad := unit.get_attack_damage()
	var initial_arm := unit.get_effective_armor()

	var pequi: ItemData = ItemRegistry.get_item(&"caroco_pequi") # +300 HP, +35 Armor
	unit.equip_item(pequi)

	if unit.get_max_health() != initial_hp + 300.0:
		log_msg("Falha: Max HP esperado %f, obtido %f" % [initial_hp + 300.0, unit.get_max_health()])
		unit.queue_free()
		return false
	if unit.get_effective_armor() != initial_arm + 35.0:
		log_msg("Falha: Armor esperado %f, obtido %f" % [initial_arm + 35.0, unit.get_effective_armor()])
		unit.queue_free()
		return false
	log_msg("  ✓ Caroço de Pequi aumentou Max HP (+300) e Armadura (+35) corretamente.")

	var fulozinha: ItemData = ItemRegistry.get_item(&"chicote_fulozinha") # +18 AD, +20% AS
	unit.equip_item(fulozinha)

	if unit.get_attack_damage() != initial_ad + 18.0:
		log_msg("Falha: AD esperado %f, obtido %f" % [initial_ad + 18.0, unit.get_attack_damage()])
		unit.queue_free()
		return false
	log_msg("  ✓ Chicote da Fulozinha aumentou Dano de Ataque (+18) corretamente.")

	unit.queue_free()
	return true

func _test_utilitaries() -> bool:
	log_msg("\n[6] Testando Utilitários Consumíveis (Peneira do Saci)...")
	var unit := BaseUnit3D.new()
	var stats := UnitStats.new()
	stats.unit_name = "Boitatá"
	unit.stats = stats

	var mgr := ItemManager.new()
	var pequi: ItemData = ItemRegistry.get_item(&"caroco_pequi")
	var lampiao: ItemData = ItemRegistry.get_item(&"lampiao_boitata")
	var remover: ItemData = ItemRegistry.get_item(&"peneira_saci")

	unit.equip_item(pequi)
	unit.equip_item(lampiao)
	mgr.add_item_to_inventory(remover)

	if unit.get_equipped_items().size() != 2:
		log_msg("Falha: Unidade deveria ter 2 itens equipados.")
		unit.queue_free()
		return false

	# Usa a Peneira do Saci
	var used := mgr.equip_item_to_unit(remover, unit)
	if not used or not unit.get_equipped_items().is_empty():
		log_msg("Falha: Peneira do Saci deveria ter desequipado todos os itens da unidade!")
		unit.queue_free()
		return false

	var inv: Array[ItemData] = mgr.get_inventory_items()
	if inv.size() != 2 or not inv.has(pequi) or not inv.has(lampiao):
		log_msg("Falha: Os itens desequipados deveriam retornar ao inventário!")
		unit.queue_free()
		return false

	log_msg("  ✓ Peneira do Saci recolheu os 2 itens da unidade de volta ao inventário perfeitamente!")
	unit.queue_free()
	return true
