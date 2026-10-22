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
@export var tier: int = 1
@export var cost: int = 1

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
