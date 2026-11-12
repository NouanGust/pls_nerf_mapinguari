class_name ItemRegistry
extends RefCounted

## Registro e Gerenciador de Receitas de Itens do Folchess

static var _items: Dictionary = {}
static var _recipes: Dictionary = {} # Chave: "compA:compB" (ordenado alfabeticamente) -> item_id
static var _initialized: bool = false

static func _ensure_initialized() -> void:
	if _initialized:
		return
	_initialized = true
	_register_all_items()

static func get_item(item_id: StringName) -> ItemData:
	_ensure_initialized()
	return _items.get(item_id, null)

static func has_item(item_id: StringName) -> bool:
	_ensure_initialized()
	return _items.has(item_id)

static func get_all_items() -> Array[ItemData]:
	_ensure_initialized()
	var list: Array[ItemData] = []
	for it in _items.values():
		list.append(it)
	return list

static func get_basic_components() -> Array[ItemData]:
	_ensure_initialized()
	var list: Array[ItemData] = []
	for it: ItemData in _items.values():
		if it.category == ItemData.ItemCategory.COMPONENT:
			list.append(it)
	return list

static func get_consumables() -> Array[ItemData]:
	_ensure_initialized()
	var list: Array[ItemData] = []
	for it: ItemData in _items.values():
		if it.is_consumable():
			list.append(it)
	return list

static func find_combination(comp_a: StringName, comp_b: StringName) -> ItemData:
	_ensure_initialized()
	var key := _make_recipe_key(comp_a, comp_b)
	if _recipes.has(key):
		var res_id: StringName = _recipes[key]
		return get_item(res_id)
	return null

static func _make_recipe_key(a: StringName, b: StringName) -> String:
	var s_a := String(a)
	var s_b := String(b)
	if s_a <= s_b:
		return "%s:%s" % [s_a, s_b]
	return "%s:%s" % [s_b, s_a]

static func _register(it: ItemData) -> void:
	_items[it.id] = it
	if it.recipe.size() == 2:
		var key := _make_recipe_key(it.recipe[0], it.recipe[1])
		_recipes[key] = it.id

static func _register_all_items() -> void:
	_items.clear()
	_recipes.clear()

	# ========================================================
	# 1. OS 8 COMPONENTES BÁSICOS + MUIRAQUITÃ BRUTO
	# ========================================================
	var c_brauna := ItemData.new()
	c_brauna.id = &"lasca_brauna"
	c_brauna.name = "Lasca de Braúna"
	c_brauna.description = "Madeira de lei densa e indestrutível das matas brasileiras.\nConcede +12 de Dano de Ataque."
	c_brauna.category = ItemData.ItemCategory.COMPONENT
	c_brauna.stat_modifiers = {"attack_damage": 12.0}
	_register(c_brauna)

	var c_pimenta := ItemData.new()
	c_pimenta.id = &"pimenta_cumari"
	c_pimenta.name = "Pimenta Cumari"
	c_pimenta.description = "Pimentinha vermelha ardente de axé e calor.\nConcede +15% de Poder de Habilidade."
	c_pimenta.category = ItemData.ItemCategory.COMPONENT
	c_pimenta.stat_modifiers = {"ability_power_pct": 0.15}
	_register(c_pimenta)

	var c_jabuti := ItemData.new()
	c_jabuti.id = &"casca_jabuti"
	c_jabuti.name = "Casca de Jabuti"
	c_jabuti.description = "Carapaça milenar de paciência e defesa ancestral.\nConcede +25 de Armadura."
	c_jabuti.category = ItemData.ItemCategory.COMPONENT
	c_jabuti.stat_modifiers = {"armor": 25.0}
	_register(c_jabuti)

	var c_arruda := ItemData.new()
	c_arruda.id = &"ramo_arruda"
	c_arruda.name = "Ramo de Arruda"
	c_arruda.description = "Erva de benzedeira que afasta quebranto e feitiços.\nConcede +25 de Resistência Mágica."
	c_arruda.category = ItemData.ItemCategory.COMPONENT
	c_arruda.stat_modifiers = {"magic_resist": 25.0}
	_register(c_arruda)

	var c_cipo := ItemData.new()
	c_cipo.id = &"cipo_titica"
	c_cipo.name = "Cipó-Titica"
	c_cipo.description = "Fibra vegetal maleável e tenaz dos povos da floresta.\nConcede +15% de Velocidade de Ataque."
	c_cipo.category = ItemData.ItemCategory.COMPONENT
	c_cipo.stat_modifiers = {"attack_speed_pct": 0.15}
	_register(c_cipo)

	var c_cabaca := ItemData.new()
	c_cabaca.id = &"cabaca_agua"
	c_cabaca.name = "Cabaça d'Água do Rio"
	c_cabaca.description = "Recipiente de águas curativas e axé.\nConcede +20 de Mana Inicial."
	c_cabaca.category = ItemData.ItemCategory.COMPONENT
	c_cabaca.stat_modifiers = {"starting_mana": 20.0}
	_register(c_cabaca)

	var c_mandioca := ItemData.new()
	c_mandioca.id = &"raiz_mandioca"
	c_mandioca.name = "Raiz de Mandioca"
	c_mandioca.description = "A sagrada dádiva de Mani que nutre o corpo e o vigor.\nConcede +200 de Vida Máxima."
	c_mandioca.category = ItemData.ItemCategory.COMPONENT
	c_mandioca.stat_modifiers = {"max_health": 200.0}
	_register(c_mandioca)

	var c_guizo := ItemData.new()
	c_guizo.id = &"guizo_cascavel"
	c_guizo.name = "Guizo de Cascavel"
	c_guizo.description = "O aviso sonoro da caatinga que precede o bote letal.\nConcede +15% de Chance Crítica e +10% de Esquiva."
	c_guizo.category = ItemData.ItemCategory.COMPONENT
	c_guizo.stat_modifiers = {"critical_chance": 0.15, "dodge_chance": 0.10}
	_register(c_guizo)

	var c_muiraquita := ItemData.new()
	c_muiraquita.id = &"muiraquita_bruto"
	c_muiraquita.name = "Muiraquitã Bruto"
	c_muiraquita.description = "Pedra sagrada de jadeita das Icamiabas amazônicas.\nComponente Mítico para forjar Emblemas de Origem."
	c_muiraquita.category = ItemData.ItemCategory.MYTHIC_BASE
	c_muiraquita.stat_modifiers = {"max_health": 100.0}
	_register(c_muiraquita)

	# ========================================================
	# 2. ITENS COMPLETOS: OFENSIVOS & FÍSICOS
	# ========================================================
	var i_fulozinha := ItemData.new()
	i_fulozinha.id = &"chicote_fulozinha"
	i_fulozinha.name = "Chicote da Comadre Fulozinha"
	i_fulozinha.description = "Cipó trançado e embebido de seiva viva.\n+1 hex de alcance de ataque (ou +25% Vel. Ataque se já à distância). A cada 3 ataques, enraíza o alvo por 1s."
	i_fulozinha.category = ItemData.ItemCategory.COMPLETED
	i_fulozinha.recipe = [&"lasca_brauna", &"cipo_titica"]
	i_fulozinha.stat_modifiers = {"attack_damage": 18.0, "attack_speed_pct": 0.20}
	i_fulozinha.unique_effect_id = &"fulozinha_whip"
	_register(i_fulozinha)

	var i_capelobo := ItemData.new()
	i_capelobo.id = &"esporao_capelobo"
	i_capelobo.name = "Esporão de Capelobo"
	i_capelobo.description = "A garra afiada da fera comedora de miolos.\nConcede +30% de Dano Crítico. Ao eliminar uma unidade, uiva reduzindo a armadura dos inimigos adjacentes em 30% por 4s."
	i_capelobo.category = ItemData.ItemCategory.COMPLETED
	i_capelobo.recipe = [&"lasca_brauna", &"guizo_cascavel"]
	i_capelobo.stat_modifiers = {"attack_damage": 20.0, "critical_chance": 0.25}
	i_capelobo.unique_effect_id = &"capelobo_spur"
	_register(i_capelobo)

	var i_corpo_seco := ItemData.new()
	i_corpo_seco.id = &"foice_corpo_seco"
	i_corpo_seco.name = "Foice do Corpo-Seco"
	i_corpo_seco.description = "Lâmina gasta banhada em terra amaldiçoada.\nAtaques aplicam dessecação: causam 50 de dano verdadeiro em 3s e reduzem cura do alvo em 50%."
	i_corpo_seco.category = ItemData.ItemCategory.COMPLETED
	i_corpo_seco.recipe = [&"lasca_brauna", &"pimenta_cumari"]
	i_corpo_seco.stat_modifiers = {"attack_damage": 18.0, "ability_power_pct": 0.20}
	i_corpo_seco.unique_effect_id = &"corpo_seco_scythe"
	_register(i_corpo_seco)

	var i_bala_prata := ItemData.new()
	i_bala_prata.id = &"bala_prata"
	i_bala_prata.name = "Bala de Prata Benzida"
	i_bala_prata.description = "Munição de caçador de lobisomens gravada com orações.\nAtaques nunca erram (ignoram esquiva) e causam +25% de dano bônus a Metamorfos e Assombrações."
	i_bala_prata.category = ItemData.ItemCategory.COMPLETED
	i_bala_prata.recipe = [&"lasca_brauna", &"ramo_arruda"]
	i_bala_prata.stat_modifiers = {"attack_damage": 20.0, "magic_resist": 30.0}
	i_bala_prata.unique_effect_id = &"silver_bullet"
	_register(i_bala_prata)

	var i_espora := ItemData.new()
	i_espora.id = &"espora_vaqueiro"
	i_espora.name = "Espora de Prata de Vaqueiro"
	i_espora.description = "A destreza dos vaqueiros na caatinga fechada.\nCada ataque básico acumula +5% de Velocidade de Ataque até o fim da rodada (acumula até 20 vezes)."
	i_espora.category = ItemData.ItemCategory.COMPLETED
	i_espora.recipe = [&"cipo_titica", &"cipo_titica"]
	i_espora.stat_modifiers = {"attack_speed_pct": 0.25}
	i_espora.unique_effect_id = &"vaqueiro_spur"
	_register(i_espora)

	# ========================================================
	# 3. ITENS COMPLETOS: MÁGICOS & CONJURADORES
	# ========================================================
	var i_saci_pipe := ItemData.new()
	i_saci_pipe.id = &"cachimbo_saci"
	i_saci_pipe.name = "Cachimbo de Fumo do Saci"
	i_saci_pipe.description = "Pito de barro com fumo acre de travessuras.\nAtaques geram +4 de Mana adicional. Ao conjurar pela primeira vez, espalha fumaça em 1 hex que cega inimigos por 3.5s."
	i_saci_pipe.category = ItemData.ItemCategory.COMPLETED
	i_saci_pipe.recipe = [&"cabaca_agua", &"cipo_titica"]
	i_saci_pipe.stat_modifiers = {"starting_mana": 25.0, "attack_speed_pct": 0.15}
	i_saci_pipe.unique_effect_id = &"saci_pipe"
	_register(i_saci_pipe)

	var i_boitata := ItemData.new()
	i_boitata.id = &"lampiao_boitata"
	i_boitata.name = "Lampião de Fogo-Fátuo"
	i_boitata.description = "Chamas espectrais que não consomem a mata verdejante.\nHabilidades queimam o alvo causando 3% da sua vida máxima como dano mágico por segundo durante 5s."
	i_boitata.category = ItemData.ItemCategory.COMPLETED
	i_boitata.recipe = [&"pimenta_cumari", &"cabaca_agua"]
	i_boitata.stat_modifiers = {"ability_power_pct": 0.25, "starting_mana": 25.0}
	i_boitata.unique_effect_id = &"boitata_burn"
	_register(i_boitata)

	var i_loira := ItemData.new()
	i_loira.id = &"espelho_loira"
	i_loira.name = "Espelho Quebrado de Banheiro"
	i_loira.description = "Reflexo riscado do ritual escolar urbano.\nHabilidades podem causar acerto crítico. Ao conjurar, estilhaços acertam os 2 inimigos mais distantes com 150 de dano mágico."
	i_loira.category = ItemData.ItemCategory.COMPLETED
	i_loira.recipe = [&"pimenta_cumari", &"guizo_cascavel"]
	i_loira.stat_modifiers = {"ability_power_pct": 0.20, "critical_chance": 0.25}
	i_loira.unique_effect_id = &"loira_mirror"
	_register(i_loira)

	var i_galafuz := ItemData.new()
	i_galafuz.id = &"clarao_galafuz"
	i_galafuz.name = "Clarão de João Galafuz"
	i_galafuz.description = "Facho marítimo ofuscante das costas nordestinas.\nConcede +40% Poder Mágico. A cada 8s, dispara um clarão no inimigo com maior vida congelando seu ganho de mana por 2.5s."
	i_galafuz.category = ItemData.ItemCategory.COMPLETED
	i_galafuz.recipe = [&"pimenta_cumari", &"pimenta_cumari"]
	i_galafuz.stat_modifiers = {"ability_power_pct": 0.40}
	i_galafuz.unique_effect_id = &"galafuz_flash"
	_register(i_galafuz)

	var i_rape := ItemData.new()
	i_rape.id = &"rape_piripiri"
	i_rape.name = "Rapé Sagrado de Piri-Piri"
	i_rape.description = "Medicina ancestral de clareza mental e visão espiritual.\nInicia a luta com +45 de Mana adicional. Após a 1ª conjuração, doa 20 de mana aos 2 aliados mais próximos."
	i_rape.category = ItemData.ItemCategory.COMPLETED
	i_rape.recipe = [&"cabaca_agua", &"cabaca_agua"]
	i_rape.stat_modifiers = {"starting_mana": 45.0}
	i_rape.unique_effect_id = &"rape_piripiri"
	_register(i_rape)

	# ========================================================
	# 4. ITENS COMPLETOS: DEFENSIVOS & RETALIAÇÃO
	# ========================================================
	var i_pequi := ItemData.new()
	i_pequi.id = &"caroco_pequi"
	i_pequi.name = "Caroço de Pequi Espinhoso"
	i_pequi.description = "Endocarpo temido do Cerrado coberto de espinhos pontiagudos.\nAo sofrer ataque corpo a corpo, retalia devolvendo 20% do dano ao agressor como dano físico."
	i_pequi.category = ItemData.ItemCategory.COMPLETED
	i_pequi.recipe = [&"casca_jabuti", &"raiz_mandioca"]
	i_pequi.stat_modifiers = {"armor": 35.0, "max_health": 300.0}
	i_pequi.unique_effect_id = &"pequi_spikes"
	_register(i_pequi)

	var i_casco := ItemData.new()
	i_casco.id = &"casco_jabuti_ancestral"
	i_casco.name = "Casco Ancestral de Jabuti"
	i_casco.description = "A couraça inquebrável que suportou o peso da floresta.\nImunidade a acertos críticos recebidos. Reduz o dano de todos os ataques diretos recebidos em 20 pontos."
	i_casco.category = ItemData.ItemCategory.COMPLETED
	i_casco.recipe = [&"casca_jabuti", &"casca_jabuti"]
	i_casco.stat_modifiers = {"armor": 60.0}
	i_casco.unique_effect_id = &"jabuti_shell"
	_register(i_casco)

	var i_comigo := ItemData.new()
	i_comigo.id = &"folha_comigo_ninguem_pode"
	i_comigo.name = "Folha de Comigo-Ninguém-Pode"
	i_comigo.description = "Planta de proteção enérgica que afasta pragas.\nNo início do combate, concede escudo de 250 HP a si e aliados em 1 hex. Quem atacar este escudo tem Vel. Ataque reduzida em 30% por 3s."
	i_comigo.category = ItemData.ItemCategory.COMPLETED
	i_comigo.recipe = [&"ramo_arruda", &"ramo_arruda"]
	i_comigo.stat_modifiers = {"magic_resist": 60.0}
	i_comigo.unique_effect_id = &"comigo_ninguem_pode"
	_register(i_comigo)

	var i_sucuri := ItemData.new()
	i_sucuri.id = &"couro_sucuri"
	i_sucuri.name = "Couro Grossado de Sucuri"
	i_sucuri.description = "Escamas escorregadias e impenetráveis da Boiúna.\nA cada 2s queima inimigos em 1 hex com 30 de dano mágico e regenera 2% da própria vida máxima continuamente."
	i_sucuri.category = ItemData.ItemCategory.COMPLETED
	i_sucuri.recipe = [&"casca_jabuti", &"ramo_arruda"]
	i_sucuri.stat_modifiers = {"armor": 30.0, "magic_resist": 30.0}
	i_sucuri.unique_effect_id = &"sucuri_hide"
	_register(i_sucuri)

	var i_mandacaru := ItemData.new()
	i_mandacaru.id = &"cerca_mandacaru"
	i_mandacaru.name = "Cerca Viva de Mandacaru"
	i_mandacaru.description = "A sentinela cactácea que desafia o sol do sertão.\nConcede +450 de Vida. Se a unidade for Planta Estacionária, aumenta o raio da sua aura passiva de suporte em +1 hexágono."
	i_mandacaru.category = ItemData.ItemCategory.COMPLETED
	i_mandacaru.recipe = [&"raiz_mandioca", &"raiz_mandioca"]
	i_mandacaru.stat_modifiers = {"max_health": 450.0}
	i_mandacaru.unique_effect_id = &"mandacaru_fence"
	_register(i_mandacaru)

	# ========================================================
	# 5. ITENS COMPLETOS: SUPORTE & SALVAMENTO
	# ========================================================
	var i_muiraquita_salva := ItemData.new()
	i_muiraquita_salva.id = &"muiraquita_icamiabas"
	i_muiraquita_salva.name = "Muiraquitã das Icamiabas"
	i_muiraquita_salva.description = "Amuleto de rã verde das guerreiras do Amazonas.\nAo ficar com menos de 25% de Vida, fica imune a dano por 1.5s e recupera 30% da Vida Máxima em 3s (1x por combate)."
	i_muiraquita_salva.category = ItemData.ItemCategory.COMPLETED
	i_muiraquita_salva.recipe = [&"raiz_mandioca", &"ramo_arruda"]
	i_muiraquita_salva.stat_modifiers = {"max_health": 250.0, "magic_resist": 25.0}
	i_muiraquita_salva.unique_effect_id = &"muiraquita_lifesaver"
	_register(i_muiraquita_salva)

	var i_bonfim := ItemData.new()
	i_bonfim.id = &"fita_bonfim"
	i_bonfim.name = "Fita de Três Nós do Bonfim"
	i_bonfim.description = "Fitinha sagrada de promessas de Salvador.\nComeça com 3 nós. Cada vez que um aliado adjacente cai, um nó se desfaz concedendo +15% de Dano e um escudo de 160 HP."
	i_bonfim.category = ItemData.ItemCategory.COMPLETED
	i_bonfim.recipe = [&"guizo_cascavel", &"ramo_arruda"]
	i_bonfim.stat_modifiers = {"magic_resist": 25.0, "critical_chance": 0.15}
	i_bonfim.unique_effect_id = &"bonfim_ribbon"
	_register(i_bonfim)

	var i_oferenda := ItemData.new()
	i_oferenda.id = &"oferenda_cachaca"
	i_oferenda.name = "Oferenda de Cachaça e Mel"
	i_oferenda.description = "Agradecimento deixado na soleira da mata para a Caipora.\nNos primeiros 5s de combate o portador não pode ser alvejado por inimigos e concede +15 Armadura/MR aos vizinhos."
	i_oferenda.category = ItemData.ItemCategory.COMPLETED
	i_oferenda.recipe = [&"cabaca_agua", &"raiz_mandioca"]
	i_oferenda.stat_modifiers = {"max_health": 250.0, "starting_mana": 20.0}
	i_oferenda.unique_effect_id = &"cachaca_offering"
	_register(i_oferenda)

	var i_berrante := ItemData.new()
	i_berrante.id = &"berrante_sertanejo"
	i_berrante.name = "Berrante do Encanto Sertanejo"
	i_berrante.description = "O toque retumbante que guia a boiada.\nNo início do combate toca o berrante: concede +20% Velocidade de Ataque e +15 de Mana para aliados na mesma linha."
	i_berrante.category = ItemData.ItemCategory.COMPLETED
	i_berrante.recipe = [&"lasca_brauna", &"cabaca_agua"]
	i_berrante.stat_modifiers = {"attack_damage": 15.0, "starting_mana": 20.0}
	i_berrante.unique_effect_id = &"sertanejo_horn"
	_register(i_berrante)

	var i_carapuca := ItemData.new()
	i_carapuca.id = &"carapuca_saci"
	i_carapuca.name = "Carapuça Escarlate do Saci"
	i_carapuca.description = "O barrete vermelho encantado de peraltices.\n+25% Esquiva. Ao esquivar com sucesso, gira em redemoinho e devolve um golpe crítico imediato no atacante."
	i_carapuca.category = ItemData.ItemCategory.COMPLETED
	i_carapuca.recipe = [&"guizo_cascavel", &"cipo_titica"]
	i_carapuca.stat_modifiers = {"dodge_chance": 0.25, "attack_speed_pct": 0.20}
	i_carapuca.unique_effect_id = &"saci_cap"
	_register(i_carapuca)

	# ========================================================
	# 6. EMBLEMAS DE ORIGEM & FORÇA DA NATUREZA
	# ========================================================
	var e_amazonia := ItemData.new()
	e_amazonia.id = &"emblema_amazonia"
	e_amazonia.name = "Totem da Amazônia"
	e_amazonia.description = "Símbolo dos grandes rios e igarapés.\nConcede a Origem Amazônico e +200 de Vida."
	e_amazonia.category = ItemData.ItemCategory.EMBLEM
	e_amazonia.recipe = [&"muiraquita_bruto", &"raiz_mandioca"]
	e_amazonia.origin_grant = "Amazônico"
	e_amazonia.stat_modifiers = {"max_health": 200.0}
	_register(e_amazonia)

	var e_caatinga := ItemData.new()
	e_caatinga.id = &"emblema_caatinga"
	e_caatinga.name = "Pedra do Sol Ardente"
	e_caatinga.description = "Fragmento de rocha calcinada da mata branca.\nConcede a Origem Caatinga e +20% Poder Mágico."
	e_caatinga.category = ItemData.ItemCategory.EMBLEM
	e_caatinga.recipe = [&"muiraquita_bruto", &"pimenta_cumari"]
	e_caatinga.origin_grant = "Caatinga"
	e_caatinga.stat_modifiers = {"ability_power_pct": 0.20}
	_register(e_caatinga)

	var e_cerrado := ItemData.new()
	e_cerrado.id = &"emblema_cerrado"
	e_cerrado.name = "Coração do Cerrado"
	e_cerrado.description = "Nódulo de casca nodosa forjada no fogo.\nConcede a Origem Cerrado e +30 Armadura."
	e_cerrado.category = ItemData.ItemCategory.EMBLEM
	e_cerrado.recipe = [&"muiraquita_bruto", &"casca_jabuti"]
	e_cerrado.origin_grant = "Cerrado"
	e_cerrado.stat_modifiers = {"armor": 30.0}
	_register(e_cerrado)

	var e_pantanal := ItemData.new()
	e_pantanal.id = &"emblema_pantanal"
	e_pantanal.name = "Concha das Águas Doces"
	e_pantanal.description = "Relíquia das cheias e vazantes pantaneiras.\nConcede a Origem Pantaneiro e +25 Mana Inicial."
	e_pantanal.category = ItemData.ItemCategory.EMBLEM
	e_pantanal.recipe = [&"muiraquita_bruto", &"cabaca_agua"]
	e_pantanal.origin_grant = "Pantaneiro"
	e_pantanal.stat_modifiers = {"starting_mana": 25.0}
	_register(e_pantanal)

	var e_mata := ItemData.new()
	e_mata.id = &"emblema_mata_atlantica"
	e_mata.name = "Bálsamo da Mata Atlântica"
	e_mata.description = "Orvalho sagrado das escarpas litorâneas.\nConcede a Origem Mata Atlântica e +30 Resist. Mágica."
	e_mata.category = ItemData.ItemCategory.EMBLEM
	e_mata.recipe = [&"muiraquita_bruto", &"ramo_arruda"]
	e_mata.origin_grant = "Mata Atlântica"
	e_mata.stat_modifiers = {"magic_resist": 30.0}
	_register(e_mata)

	var e_litoral := ItemData.new()
	e_litoral.id = &"emblema_litoraneo"
	e_litoral.name = "Rede de Pesca Salgada"
	e_litoral.description = "Malha curtida nas marés e arrecifes costeiros.\nConcede a Origem Litorâneo e +20% Velocidade de Ataque."
	e_litoral.category = ItemData.ItemCategory.EMBLEM
	e_litoral.recipe = [&"muiraquita_bruto", &"cipo_titica"]
	e_litoral.origin_grant = "Litorâneo"
	e_litoral.stat_modifiers = {"attack_speed_pct": 0.20}
	_register(e_litoral)

	var e_sertanejo := ItemData.new()
	e_sertanejo.id = &"emblema_sertanejo"
	e_sertanejo.name = "Chibo de Couro de Vaqueiro"
	e_sertanejo.description = "Vestimenta de gibão e perneira do interior.\nConcede a Origem Sertanejo e +18 Dano de Ataque."
	e_sertanejo.category = ItemData.ItemCategory.EMBLEM
	e_sertanejo.recipe = [&"muiraquita_bruto", &"lasca_brauna"]
	e_sertanejo.origin_grant = "Sertanejo"
	e_sertanejo.stat_modifiers = {"attack_damage": 18.0}
	_register(e_sertanejo)

	var e_urbano := ItemData.new()
	e_urbano.id = &"emblema_urbano"
	e_urbano.name = "Asfalto Assombrado"
	e_urbano.description = "Relíquia de lampião e esquinas das lendas da cidade.\nConcede a Origem Urbano e +20% Chance Crítica."
	e_urbano.category = ItemData.ItemCategory.EMBLEM
	e_urbano.recipe = [&"muiraquita_bruto", &"guizo_cascavel"]
	e_urbano.origin_grant = "Urbano"
	e_urbano.stat_modifiers = {"critical_chance": 0.20}
	_register(e_urbano)

	var i_coroa := ItemData.new()
	i_coroa.id = &"coroa_icamiabas"
	i_coroa.name = "Coroa das Icamiabas"
	i_coroa.description = "Diadema supremo forjado com dois muiraquitãs sagrados.\nAumenta o limite máximo de unidades da sua equipe no tabuleiro em +1!"
	i_coroa.category = ItemData.ItemCategory.EMBLEM
	i_coroa.recipe = [&"muiraquita_bruto", &"muiraquita_bruto"]
	i_coroa.team_size_bonus = 1
	_register(i_coroa)

	# ========================================================
	# 7. UTILITÁRIOS CONSUMÍVEIS (BANCO / TABULEIRO)
	# ========================================================
	var u_remover := ItemData.new()
	u_remover.id = &"peneira_saci"
	u_remover.name = "Peneira do Saci (Removedor)"
	u_remover.description = "Arraste sobre uma unidade para desequipar todos os seus itens de volta para o inventário sem precisar vendê-la."
	u_remover.category = ItemData.ItemCategory.CONSUMABLE
	u_remover.consumable_action = &"remover"
	_register(u_remover)

	var u_reforger := ItemData.new()
	u_reforger.id = &"pena_mae_ouro"
	u_reforger.name = "Pena da Mãe-d'Ouro (Reforjador)"
	u_reforger.description = "Arraste sobre um item no inventário para transmutá-lo em outro item aleatório da mesma raridade."
	u_reforger.category = ItemData.ItemCategory.CONSUMABLE
	u_reforger.consumable_action = &"reforger"
	_register(u_reforger)

	var u_cloner := ItemData.new()
	u_cloner.id = &"muda_sumauma"
	u_cloner.name = "Muda de Sumaúma (Duplicador)"
	u_cloner.description = "Arraste sobre uma unidade para gerar instantaneamente uma cópia de 1 estrela dela no seu banco de reservas."
	u_cloner.category = ItemData.ItemCategory.CONSUMABLE
	u_cloner.consumable_action = &"cloner"
	_register(u_cloner)

	var u_coffee := ItemData.new()
	u_coffee.id = &"cafe_coador"
	u_coffee.name = "Café Fresco de Coador"
	u_coffee.description = "Dose de ânimo e energia popular brasileira.\nConsuma para conceder +4 de Experiência (XP) imediata."
	u_coffee.category = ItemData.ItemCategory.CONSUMABLE
	u_coffee.consumable_action = &"coffee"
	_register(u_coffee)
