class_name UnitStats
extends Resource

## ============================================
## ENUMS (DEVEM VIR ANTES DE TUDO)
## ============================================
enum TargetPriority { 
	CLOSEST,
	LOWEST_HP,
	HIGHEST_HP,
	LOWEST_HP_PERCENT,
	BACKLINE,
	FRONTLINE,
	RANDOM,
	HIGHEST_ATTACK
}

enum DamageType { 
	PHYSICAL, 
	MAGICAL, 
	TRUE 
}

## ============================================
## INFORMAÇÕES BÁSICAS
## ============================================
@export_group("Basic Info")
@export var unit_name: String = ""
@export var unit_id: String = ""
@export_multiline var description: String = ""
@export var lore: String = ""
const ROLE_TANK: String = "Tank"
const ROLE_CONJURADOR: String = "Conjurador"
const ROLE_ATACANTE: String = "Atacante"
const ROLE_ASSASSINO: String = "Assassino"
const ROLE_SUPORTE: String = "Suporte"
const ROLE_PORRADEIRO: String = "Porradeiro"

@export var tier: int = 1
@export var cost: int = 1
## Função de combate: Tank, Conjurador, Atacante, Assassino, Suporte, Porradeiro
@export var combat_role: String = ""

## ============================================
## VISUAIS
## ============================================
@export_group("Visuals")
@export var icon: Texture2D

## ============================================
## STATS DE COMBATE
## ============================================
@export_group("Combat Stats")
@export var max_health: float = 500.0
@export var health_regen: float = 0.0

@export_subgroup("Attack")
@export var attack_damage: float = 50.0
@export var attack_speed: float = 1.0
@export var attack_range: int = 1
@export var critical_chance: float = 0.0
@export var critical_damage: float = 2.0

@export_subgroup("Defense")
@export var armor: float = 0.0
@export var magic_resist: float = 0.0

@export_subgroup("Movement")
@export var movement_speed: float = 200.0
@export var is_stationary: bool = false
@export var can_fly: bool = false

## ============================================
## SISTEMA DE MANA
## ============================================
@export_group("Mana System")
@export var max_mana: float = 100.0
@export var starting_mana: float = 0.0
@export var mana_per_attack: float = 10.0
@export var mana_per_second: float = 0.0
@export var mana_when_hit: float = 10.0

## ============================================
## SINERGIAS
## ============================================
@export_group("Synergies")
@export var origins: Array[String] = []
@export var classes: Array[String] = []
## Tipo descritivo (Fauna/Flora); não concede nem conta como sinergia.
@export var affinities: Array[String] = []

## Habitats informativos, separados de origens que podem ativar sinergias.
@export var biomes: Array[String] = []

## ============================================
## HABILIDADE
## ============================================
@export_group("Ability")
@export var ability_name: String = ""
@export_multiline var ability_description: String = ""

@export_subgroup("Ability Stats")
@export var ability_damage: float = 0.0
@export var ability_heal: float = 0.0
## Escudo próprio renovado pela habilidade, sem acumular escudos a cada conjuração.
@export var ability_shield: float = 0.0
## Mana concedida aos aliados próximos com menor proporção de mana.
@export var ability_mana: float = 0.0
@export var ability_targets: int = 1
@export var ability_duration: float = 0.0
@export var ability_cooldown: float = 0.0
@export var ability_range: float = 0.0
@export var ability_damage_type: DamageType = DamageType.MAGICAL

## ============================================
## COMPORTAMENTO DE IA
## ============================================
@export_group("AI Behavior")
@export var target_priority: TargetPriority = TargetPriority.CLOSEST
@export var is_tank: bool = false
@export var is_assassin: bool = false
@export var is_ranged: bool = false
@export var prefers_backline: bool = false

## ============================================
## EFEITOS ESPECIAIS
## ============================================
@export_group("Special Effects")
@export var on_death_effect: String = ""
@export var on_spawn_effect: String = ""
## Raio em passos entre hexes, não em metros. Zero desativa a área.
@export_range(0, 8, 1) var passive_aura_range: int = 0
@export var passive_aura_effect: String = ""
## Fração de dano de ataque adicional; auras iguais usam apenas o maior valor.
@export var passive_aura_power: float = 0.0
@export var stun_resist: float = 0.0
@export var slow_resist: float = 0.0
@export var silence_resist: float = 0.0

## ============================================
## HELPERS
## ============================================
func get_star_multiplier(stars: int) -> float:
	match stars:
		1: return 1.0
		2: return 1.8
		3: return 2.6
		4: return 3.4
		_: return 1.0

func get_tier_color() -> Color:
	match tier:
		1: return Color(0.6, 0.6, 0.6)
		2: return Color(0.3, 0.8, 0.3)
		3: return Color(0.3, 0.6, 1.0)
		4: return Color(0.7, 0.3, 0.9)
		5: return Color(1.0, 0.6, 0.2)
		_: return Color.WHITE

func is_valid() -> bool:
	if unit_name.is_empty() or unit_id.is_empty():
		return false
	if origins.size() != 1 or classes.is_empty() or classes.size() > 2:
		return false
	if origins[0].is_empty() or classes[0].is_empty():
		return false
	return classes.size() == 1 or (not classes[1].is_empty() and classes[0] != classes[1])

func has_origin(origin_name: String) -> bool:
	return origins.has(origin_name)

func has_class(class_label: String) -> bool:
	return classes.has(class_label)

func get_attack_range_hexes() -> int:
	# A classe também protege cadastros futuros com flag de IA inconsistente.
	return 1 if is_tank or has_class("Tank") else maxi(attack_range, 1)

func has_affinity(affinity_name: String) -> bool:
	return affinities.has(affinity_name)

func get_combat_role() -> String:
	if not combat_role.is_empty():
		return combat_role
	if is_tank or has_class("Tank"):
		return ROLE_TANK
	if is_assassin:
		return ROLE_ASSASSINO
	if has_class("Suporte"):
		return ROLE_SUPORTE
	if has_class("DPS") or has_class("Caçador"):
		return ROLE_ATACANTE
	if has_class("Místico"):
		return ROLE_CONJURADOR
	return ROLE_PORRADEIRO

func get_combat_role_description() -> String:
	match get_combat_role():
		ROLE_TANK:
			return "Dano baixo por ataque, alta defesa e vida. Amplifica defesa ou aplica controle de grupo."
		ROLE_CONJURADOR:
			return "Pouco dano por ataque, pouca defesa e vida. Causa alto dano por habilidades."
		ROLE_ATACANTE:
			return "Causa muito dano quanto mais ataca, pouca vida e defesa. Ganha amplificação de dano ou velocidade."
		ROLE_ASSASSINO:
			return "Dano explosivo, pouca defesa e vida. Habilidade traz explosão de dano e foca alvos mais fracos."
		ROLE_SUPORTE:
			return "Pouco dano de ataque, pouca defesa. Buffa aliados, enfraquece inimigos e cria aura nos hexágonos ao redor."
		ROLE_PORRADEIRO:
			return "Bastante dano de ataque, boa vida e defesa. Suas habilidades concedem auto-buffs."
		_:
			return ""

func is_tank_role() -> bool:
	return get_combat_role() == ROLE_TANK

func is_conjurador_role() -> bool:
	return get_combat_role() == ROLE_CONJURADOR

func is_atacante_role() -> bool:
	return get_combat_role() == ROLE_ATACANTE

func is_assassino_role() -> bool:
	return get_combat_role() == ROLE_ASSASSINO

func is_suporte_role() -> bool:
	return get_combat_role() == ROLE_SUPORTE

func is_porradeiro_role() -> bool:
	return get_combat_role() == ROLE_PORRADEIRO

func get_mechanics_description(current_star: int = 1) -> String:
	match unit_id:
		"aguape":
			return "Emana aguas purificadas e medicinais, curando todos os aliados adjacentes a cada conjuracao."
		"alamoa":
			return "Seduz e hipnotiza o alvo com seu fulgor insular, causando alto dano magico e atordoando o inimigo por 2.0s."
		"anhanga":
			return "Solta um rugido aterrorizante da floresta que atordoa todos os inimigos na vanguarda por 2.0s."
		"arara_azul_lear":
			return "Alca voo rapido e fustiga o alvo a distancia com penas perfurantes, causando dano fisico e acelerando seus proprios ataques."
		"ararinha_azul":
			return "Entoa um canto sagrado da Caatinga que restaura vida a todos os aliados vivos no campo de batalha."
		"araucaria":
			return "Ergue uma colossal copa protetora milenar, concedendo um escudo massivo a todos os aliados adjacentes."
		"boiuna":
			return "Invoca um diluvio flamejante que varre o campo adversario, causando dano magico a inimigos e curando a si mesma."
		"brinco_de_princesa":
			return "Desabrocha flores aromaticas suaves que revitalizam aliados proximos, restaurando vida a cada conjuracao."
		"bromelia":
			return "Libera o orvalho sagrado retido em sua roseta, curando aliados adjacentes e concedendo mana."
		"caapora":
			return "Dispara uma flecha perfurante de energia magica em linha reta, atravessando todos os inimigos no caminho."
		"cabeca_de_cuia":
			return "Lanca seu braco espectral arrastando o inimigo mais distante para a sua frente e desferindo um golpe de dano magico."
		"capivara":
			return "Mergulha na margem e renova um escudo de aguas calmas que absorve dano por 4.0s."
		"caranguejo_uca":
			return "Trava pincas e fecha a carapaca solida, causando dano fisico ao alvo e ganhando um escudo de protecao."
		"comadre_fulozinha":
			return "Chicoteia os inimigos com urtigas misticas da mata, causando dano magico em area e aplicando lentidao."
		"corpo_seco":
			return "Crava garras murchas no alvo, drenando vida continuamente e causando dano magico."
		"cumacanga":
			return "Salta em chamas pelos ceus e explode no alvo mais fragil, causando dano magico em area aos inimigos."
		"guarana":
			return "Concede infusao de vigor e cafeina pura, acelerando a velocidade de ataque e concedendo mana aos aliados adjacentes."
		"ipe_amarelo":
			return "Floresce em ouro sob a pressao do combate, erguendo uma couraca de escudo resistente por 4.0s."
		"jararaca":
			return "Da um bote furtivo pelas sombras da serapilheira sobre o inimigo mais vulneravel, desferindo dano fisico letal."
		"labatut":
			return "Entra em frenesi brutal desferindo golpes vorazes, curando-se e aumentando seu poder de ataque."
		"lobo_guara":
			return "Solta um uivo que ecoa pelo Cerrado, restaurando vida e inspirando velocidade e chance critica a alcateia."
		"mae_dagua":
			return "Entoa um canto irresistivel das mares, banhando todos os aliados em cura milagrosa e restaurando mana."
		"mae_de_ouro":
			return "Conjura relampagos dourados ancestrais que atingem inimigos causando dano magico e curando aliados."
		"mandacaru":
			return "Ergue uma barreira de espinhos defensivos, ganhando escudo proprio e refletindo dano a quem ataca-lo."
		"mapinguari":
			return "Entra em furia primordial estrondosa, ganhando velocidade de ataque extrema e desferindo golpes de dano magico em area."
		"matinta_perera":
			return "Transforma-se em passaro sombrio e mergulha na presa mais vulneravel com um assobio cortante, causando alto dano magico."
		"mboi_guacu":
			return "Envolve o alvo em constricao de fogo, prendendo o inimigo e causando dano magico continuo por queimadura."
		"minhocao":
			return "Gera um violento terremoto subterraneo que arremessa e atordoa os inimigos na vanguarda por 1.8s e causa dano magico."
		"mutum_de_alagoas":
			return "Abre suas asas sagradas protegendo o campo, curando aliados e concedendo escudo protetor."
		"onca_pintada":
			return "Executa uma emboscada letal pelas costas da presa com menor vida, causando dano fisico critico massivo."
		"palmito_jucara":
			return "Distribui frutos sagrados e seiva revigorante, curando aliados e acelerando sua barra de mana."
		"papa_figo":
			return "Aplica um toque gelido sinistro, drenando vida do alvo e transferindo cura aos aliados feridos."
		"pau_brasil":
			return "Desaba seu cerne rubro macico contra a vanguarda inimiga, causando dano fisico esmagador e atordoando alvos proximos."
		"pe_de_garrafa":
			return "Gira em um salto circular assobiando e desaba sobre o alvo mais fragil, causando dano fisico devastador."
		"pequi":
			return "Arremessa frutos espinhosos do Cerrado que explodem em estilhacos no impacto, perfurando a linha de frente inimiga."
		"pisadeira":
			return "Cai pesadamente sobre o peito da vitima mais fragil, paralisando-a por 2.5s e causando dano fisico esmagador."
		"quibungo":
			return "Abre a bocarra nas costas e morde violentamente o alvo atual, causando dano fisico e engolindo-o temporariamente."
		"romaozinho":
			return "Teletransporta-se pelas sombras em travessura caotica, causando dano magico a inimigos e restaurando grande quantidade de vida."
		"sabia_laranjeira":
			return "Desfere uma rajada rapida e implacavel de bicadas, causando dano fisico e aumentando sua velocidade de ataque."
		"sumauma":
			return "Finte raizes gigantescas no solo que retem inimigos por 2.0s, concedendo escudo e cura a aliados."
		"tamandua_bandeira":
			return "Desfere golpes brutais com suas garras curvadas, causando dano fisico e quebrando 40% da armadura do alvo."
		"tatu_bola":
			return "Enrola-se em uma esfera defensiva impenetravel, recebendo um escudo proprio que absorve dano por 4.0s."
		"teiniagua":
			return "Canaliza e arremessa uma esfera magica de fogo arcano que explode no alvo, causando dano magico concentrado."
		"tutu_maramba":
			return "Exibe sua carapaca sombria de bicho-papao amedrontando os inimigos ao redor, reduzindo dano recebido em 40% e absorvendo impactos."
		"vitoria_regia":
			return "Abre sua gigantesca folha circular emanando uma aura de aguas puras que restaura vida a aliados adjacentes."
		_:
			return ability_description if ability_description != "" else description
