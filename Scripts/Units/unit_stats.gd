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
@export var ability_range: float = 0.0
@export var ability_cooldown: float = 0.0
@export var ability_damage_type: DamageType = DamageType.MAGICAL
@export var ability_kind: String = ""
@export var ability_params: Dictionary = {}

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
	if origins.size() != 2:
		return false
	if origins[0].is_empty() or origins[1].is_empty() or origins[0] == origins[1]:
		return false
	return not get_combat_role().is_empty()

func has_origin(origin_name: String) -> bool:
	return origins.has(origin_name)

func has_class(class_label: String) -> bool:
	return classes.has(class_label)

func get_attack_range_hexes() -> int:
	return 1 if is_tank or is_tank_role() or has_class("Tank") else maxi(attack_range, 1)

func has_affinity(affinity_name: String) -> bool:
	return affinities.has(affinity_name)

func get_combat_role() -> String:
	if not combat_role.is_empty():
		return combat_role
	if is_tank or has_class("Tank"):
		return ROLE_TANK
	if is_assassin:
		return ROLE_ASSASSINO
	if has_class("Suporte") or passive_aura_range > 0:
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
			return "Aura adjacente cura aliados continuamente; a habilidade potencializa a regeneracao por 4s."
		"alamoa":
			return "Concentra um clarao insular em area apos aviso breve, desferindo alto dano magico concentrado."
		"anhanga":
			return "Recebe escudo protetor e provoca inimigos proximos, atraindo a atencao para sua carapaca."
		"arara_azul_lear":
			return "Ataques consecutivos acumulam cadencia; a habilidade concede surto imediato de velocidade de ataque."
		"ararinha_azul":
			return "Aura adjacente concede resistencia a controle; a habilidade distribui escudos nos aliados da aura."
		"araucaria":
			return "Endurece o tronco anciao recebendo escudo e enraiza inimigos proximos, impedindo movimento."
		"boiuna":
			return "Invoca uma onda sombria que varre a linha inimiga causando grande dano magico."
		"brinco_de_princesa":
			return "Acumula essencia floral e detona petalas misticas em pequena area com dano magico."
		"bromelia":
			return "Aura adjacente melhora cura recebida; a habilidade distribui agua curativa e escudos na area."
		"caapora":
			return "Disparos sucessivos acumulam dano de ataque; a habilidade acelera sua sequencia ofensiva."
		"cabeca_de_cuia":
			return "Puxa o inimigo distante para a sua frente e desfere golpes com roubo de vida e resistencia temporaria."
		"capivara":
			return "Assume postura defensiva serena, recebendo escudo e interrompendo brevemente inimigos ao redor."
		"caranguejo_uca":
			return "Fecha a carapaca solida, prendendo um inimigo proximo e ganhando grande reforco de defesa."
		"comadre_fulozinha":
			return "Assobio cortante causa dano magico em area e desacelera os inimigos atingidos."
		"corpo_seco":
			return "Ataques acumulam vigor ofensivo; a habilidade potencializa o proprio ataque e velocidade."
		"cumacanga":
			return "Arremessa a cabeca em chamas numa area, causando explosao de dano magico concentrado."
		"guarana":
			return "Aura adjacente concede velocidade de ataque aos aliados; a habilidade dobra o beneficio por 4s."
		"ipe_amarelo":
			return "Explosao de flores douradas causa dano magico em area apos breve canalizacao."
		"jararaca":
			return "Salta furtivamente sobre o inimigo mais vulneravel, desferindo mordida venenosa de alto dano fisico."
		"labatut":
			return "Entra em combate cerrado brutal, aumentando seu proprio ataque e defesa enquanto golpeia."
		"lobo_guara":
			return "Acumula velocidade de ataque a cada disparo consecutivo; a habilidade acelera sua sequencia letal."
		"mae_dagua":
			return "Aura adjacente regenera vida continua; a habilidade protege os aliados na aura com escudo protetor."
		"mae_de_ouro":
			return "Concentra brilho mitico e detona relampagos dourados em area, causando alto dano magico."
		"mandacaru":
			return "Endurece a estrutura espinhosa, ganhando escudo proprio e reduzindo dano recebido."
		"mapinguari":
			return "Desfere golpes brutais continuos, aumentando o proprio ataque e recuperando vida por ataque."
		"matinta_perera":
			return "Mergulha em voo rasante sobre o alvo vulneravel com um assobio cortante de alto dano magico."
		"mboi_guacu":
			return "Fortalece o corpo imenso e desfere mordidas flamejantes que queimam o alvo."
		"minhocao":
			return "Abala o solo com tremor violento, arremessando e atordoando inimigos da vanguarda e ganhando defesa."
		"mutum_de_alagoas":
			return "Dispara projeteis de penas sucessivas acumulando cadencia; a habilidade amplifica ataque e velocidade."
		"onca_pintada":
			return "Emboscada pelas sombras sobre a presa mais fragil, desferindo dano fisico critico massivo."
		"palmito_jucara":
			return "Dispara sementes em cadencia constante; a habilidade acelera o ataque e velocidade dos disparos."
		"papa_figo":
			return "Aura adjacente reduz o poder de ataque dos inimigos; a habilidade intensifica o enfraquecimento."
		"pau_brasil":
			return "Golpes pesados de cerne rubro; a habilidade endurece o tronco e aumenta o proprio ataque."
		"pe_de_garrafa":
			return "Persegue o alvo vulneravel e desfere pisao circular devastador com dano fisico explosivo."
		"pequi":
			return "Aura adjacente concede armadura e resistencia aos aliados; a habilidade restaura vida aos aliados da aura."
		"pisadeira":
			return "Cai pesadamente sobre o alvo mais fragil, causando dano fisico esmagador e breve paralisia."
		"quibungo":
			return "Bocarra nas costas morde vorazmente o alvo, concedendo roubo de vida e aumento de ataque."
		"romaozinho":
			return "Marca o inimigo mais vulneravel pelas sombras e explode a marca com dano de habilidade."
		"sabia_laranjeira":
			return "Canto melodioso em aura adjacente aumenta ataque dos aliados; a habilidade intensifica o efeito."
		"sumauma":
			return "Fixa raizes ancestrais no chao, prendendo inimigos proximos e recebendo um escudo massivo."
		"tamandua_bandeira":
			return "Golpes pesados de garras curvadas; a habilidade fortalece o proprio ataque e defesa."
		"tatu_bola":
			return "Enrola-se em esfera blindada recebendo escudo e interrompendo o inimigo mais proximo."
		"teiniagua":
			return "Canaliza brilho mistico e arremessa esfera ardente causando dano magico concentrado."
		"tutu_maramba":
			return "Assusta e amedronta inimigos proximos, reduzindo dano sofrido e ampliando a propria carapaca."
		"vitoria_regia":
			return "Aura adjacente concede escudos periodicos a aliados; a habilidade renova e fortalece a protecao."
		"anta_bondosa":
			return "Aura adjacente regenera vida continua; a habilidade socorre aliados proximos com cura imediata."
		"bebe_diabo":
			return "Grito estridente de aparicao causa dano magico em pequena area aos adversarios."
		"boi_misterioso":
			return "Chifradas pesadas e avanco rustico; a habilidade amplia o proprio ataque e defesas na vanguarda."
		"boitata":
			return "Sinaliza uma faixa de fogo que percorre o campo adversario causando grande dano magico e queimadura."
		"boto_encantado":
			return "Aura adjacente reduz dano sofrido por aliados; a habilidade concede escudos protetores na area."
		"caboclo_dagua":
			return "Invoca uma onda curta que interrompe inimigos proximos e concede couraca de defesa propria."
		"cabra_cabriola":
			return "Cabecadas implacaveis; a habilidade amplia seu proprio ataque e resistencia em luta proxima."
		"capelobo":
			return "Garras vorazes e presenca imponente; a habilidade concede frenesi de ataque e tenacidade."
		"capeta_vilarinho":
			return "Aura de danca acelera velocidade de ataque de aliados; a habilidade amplia o bonus e atrasa inimigos."
		"chupa_cabra":
			return "Bote predatorio contra a presa vulneravel causando alto dano e recuperando vida propria."
		"curupira":
			return "Aura de pegadas invertidas causa lentidao a inimigos; a habilidade concede resistencia a controle aos aliados."
		"ipupiara":
			return "Golpes pesados das aguas; a habilidade amplia o dano de ataque e concede carapaca temporaria."
		"joao_galafuz":
			return "Clarao maritimo que explode apos breve aviso, causando dano magico em area."
		"lobisomem_sertao":
			return "Transformacao sob a lua sertaneja que aumenta ataque, defesas e recuperacao por golpes."
		"loira_banheiro":
			return "Espelho espectral que explode em estilhas magicos em area apos breve aviso."
		"loira_bonfim":
			return "Encontro subito contra alvo vulneravel, desferindo golpe rapido de alto dano concentrado."
		"maozao":
			return "Palmada espectral macica desorienta inimigos proximos com lentidao e concede armadura propria."
		"num_se_pode":
			return "Cresce em estatura sombria, aumentando vida efetiva com escudo e interrompendo inimigos ao redor."
		"pai_do_mato":
			return "Rugido da mata fechada que atrai e provoca inimigos proximos enquanto amplia defesas."
		"perna_cabeluda":
			return "Sequencia veloz de chutes sucessivos; a habilidade aumenta ainda mais a cadencia e dano de ataque."
		"saci_perere":
			return "Aura de redemoinho reduz velocidade de ataque adversaria; a habilidade fortalece a mobilidade da equipe."
		_:
			return ability_description if ability_description != "" else description
