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
## Duas origens temáticas da nova proposta (Seiva, Vigília, Correnteza, Vozes, Ferocidade, Travessia, Assombro, Encanto, Fulgor)
@export var thematic_origins: Array[String] = []
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
	if origins.is_empty() or origins.size() > 2:
		return false
	if origins[0].is_empty():
		return false
	if origins.size() == 2 and (origins[1].is_empty() or origins[0] == origins[1]):
		return false
	if classes.size() > 2:
		return false
	if classes.size() == 2 and (classes[1].is_empty() or classes[0] == classes[1]):
		return false
	return true

func has_origin(origin_name: String) -> bool:
	return origins.has(origin_name) or thematic_origins.has(origin_name)

func get_thematic_origins() -> Array[String]:
	return thematic_origins if not thematic_origins.is_empty() else origins

func has_thematic_origin(origin_name: String) -> bool:
	return get_thematic_origins().has(origin_name)

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
			return "Concentra um clarao solar devastador apos breve aviso, causando alto dano magico em area."
		"anhanga":
			return "Ergue um escudo proprio e solta rugido que atordoa e provoca inimigos proximos por 2.0s."
		"arara_azul_lear":
			return "Dispara penas velozes acumulando ritmo e acelerando os proprios ataques sucessivos."
		"ararinha_azul":
			return "Entoa um canto sagrado que amplia escudos e concede tenacidade aos aliados em sua aura."
		"araucaria":
			return "Endurece o proprio tronco milenar ganhando armadura e enraiza inimigos proximos por 2.0s."
		"boiuna":
			return "Invoca uma onda sombria que percorre o campo adversario causando grande dano magico."
		"brinco_de_princesa":
			return "Acumula energia floral e detona petalas aromaticas causando alto dano magico em area."
		"bromelia":
			return "Emana orvalho sagrado que amplia a cura recebida e distribui escudos na aura adjacente."
		"caapora":
			return "Dispara flechas velozes que acumulam forca de ataque e amplificam a sequencia ofensiva."
		"cabeca_de_cuia":
			return "Desfere golpes pesados ganhando roubo de vida em ataques e resistencia temporaria."
		"capivara":
			return "Assume postura defensiva enrijecida, recebendo escudo e interrompendo inimigos proximos."
		"caranguejo_uca":
			return "Fecha a guarda recebendo escudo e prende um inimigo proximo com suas tenazes."
		"comadre_fulozinha":
			return "Assobio mistico que concentra alto dano magico em area e aplica lentidao aos alvos."
		"corpo_seco":
			return "Cada golpe acumula furia ofensiva, amplificando os proprios ataques com vigor aterrorizante."
		"cumacanga":
			return "Lanca a chama ardente da cabeca decapitada, detonando em area com grande dano magico."
		"guarana":
			return "Aura revigorante que concede velocidade de ataque e acelera mana dos aliados vizinhos."
		"ipe_amarelo":
			return "Explosao de flores douradas que causa grande dano magico em area aos adversarios."
		"jararaca":
			return "Bote venenoso fulminante sobre o alvo mais vulneravel, desferindo dano fisico letal."
		"labatut":
			return "Entra em frenesi bestial na luta proxima, aumentando o proprio ataque e resistencia."
		"lobo_guara":
			return "Acumula velocidade a cada ataque desferido, acelerando sua sequencia e foco em alvos."
		"mae_dagua":
			return "Aura de mares que sustenta cura constante e protege aliados proximos com escudo."
		"mae_de_ouro":
			return "Concentra faiscas douradas e detona ouro ilusorio causando alto dano magico em area."
		"mandacaru":
			return "Endurece a carapaca de espinhos reduzindo dano recebido e retendo inimigos proximos."
		"mapinguari":
			return "Furia titânica primordial que amplia o proprio poder de ataque e regeneracao de vida."
		"matinta_perera":
			return "Assobia sobre a presa mais fraca desferindo uma explosao sombria de grande dano magico."
		"mboi_guacu":
			return "Fortalece o corpo escamoso e mandibulas, aumentando seu proprio ataque e resistencia."
		"minhocao":
			return "Abala o solo em terremoto violento que interrompe inimigos e concede defesa propria."
		"mutum_de_alagoas":
			return "Acumula ritmo e velocidade marciais a cada golpe, ampliando drasticamente seu ataque."
		"onca_pintada":
			return "Executa bote de emboscada letal nas costas do alvo mais fragil com explosao de dano."
		"palmito_jucara":
			return "Dispara rajadas de sementes velozes, aumentando seu proprio dano e cadencia de ataque."
		"papa_figo":
			return "Aura sinistra que enfraquece o ataque dos inimigos adjacentes e drena sua forca."
		"pau_brasil":
			return "Golpes pesados de cerne macico que aumentam o proprio ataque e endurecem o corpo."
		"pe_de_garrafa":
			return "Rastreia a presa vulneravel e desfere um pisao explosivo devastador com atordoamento."
		"pequi":
			return "Exala aroma protetor que concede defesa e restaura vida aos aliados na aura adjacente."
		"pisadeira":
			return "Cai pesadamente sobre a vitima mais fragil, paralisando-a e causando dano esmagador."
		"quibungo":
			return "Abre a bocarra nas costas aumentando o proprio ataque e recuperando vida por golpe."
		"romaozinho":
			return "Marca o alvo mais vulneravel e explode a marca com travessura sombria de alto impacto."
		"sabia_laranjeira":
			return "Entoa um canto sagrado nos hexagonos adjacentes amplificando o poder de ataque dos aliados."
		"sumauma":
			return "Finte raizes gigantescas ganhando grande escudo proprio e prendendo inimigos ao redor."
		"tamandua_bandeira":
			return "Desfere golpes pesados com garras em foice, aumentando o proprio ataque e resistencia."
		"tatu_bola":
			return "Enrola-se em esfera defensiva reduzindo dano recebido e interrompendo o inimigo proximo."
		"teiniagua":
			return "Condensa brilho encantado da pedra na cabeca disparando explosao magica de alto dano."
		"tutu_maramba":
			return "Amplifica a propria armadura e amedronta inimigos proximos reduzindo dano recebido."
		"vitoria_regia":
			return "Aura de aguas calmas que concede escudo periodico aos aliados nos hexagonos adjacentes."
		"anta_bondosa":
			return "Emite presenca compassiva que cura aliados na aura adjacente e purifica efeitos nocivos."
		"bebe_diabo":
			return "Emite um grito estridente pavoroso causando dano magico em cone e reduzindo ataque inimigo."
		"boi_misterioso":
			return "Fortalece cascos e chifres aumentando seu proprio ataque, armadura e concedendo roubo de vida."
		"boitata":
			return "Projeta uma faixa continua de fogo mistico em linha reta causando alto dano magico aos inimigos."
		"boto_encantado":
			return "Manifesta encanto fluvial concedendo escudo protetor e mana aos aliados em sua aura adjacente."
		"caboclo_dagua":
			return "Recebe escudo proprio e golpeia o solo com uma onda curta, atordoando inimigos adjacentes."
		"cabra_cabriola":
			return "Desfere uma cabecada brutal aumentando seu proprio poder de ataque e velocidade."
		"capelobo":
			return "Enrijece garras brutais aumentando seu proprio ataque e curando-se com cada golpe desferido."
		"capeta_vilarinho":
			return "Conduz uma valsa infernal que acelera aliados na aura e reduz velocidade dos inimigos."
		"chupa_cabra":
			return "Salta sobre o inimigo mais vulneravel causando dano fisico critico e restaurando vida propria."
		"curupira":
			return "Cria pegadas invertidas que desaceleram inimigos adjacentes e concedem defesa aos aliados."
		"ipupiara":
			return "Ganha armadura temporaria e amplifica seu ataque desferindo golpes pesados na vanguarda."
		"joao_galafuz":
			return "Conjura um clarao fosforescente concentrado que explode causando dano magico na area."
		"lobisomem_sertao":
			return "Assume a forma bestial completa aumentando seu proprio ataque e recuperando vida a cada golpe."
		"loira_banheiro":
			return "Invoca um espelho espectral marcado que se despedaca causando alto dano magico em area."
		"loira_bonfim":
			return "Surge pelas costas da presa com menor vida desferindo dano explosivo e breve atordoamento."
		"maozao":
			return "Desaba uma palmada colossal interrompendo inimigos proximos e recebendo grande escudo proprio."
		"num_se_pode":
			return "Agiganta-se no campo aumentando sua vida maxima, provocando adversarios e reduzindo dano."
		"pai_do_mato":
			return "Solta um rugido selvagem provocando inimigos proximos, ganhando escudo e bonus de armadura."
		"perna_cabeluda":
			return "Desfere uma sequencia frenetica de chutes aumentando sua cadencia e dano por ataque."
		"saci_perere":
			return "Gira em redemoinho desacelerando inimigos e impulsionando a velocidade de aliados na aura."
		_:
			return ability_description if ability_description != "" else description
