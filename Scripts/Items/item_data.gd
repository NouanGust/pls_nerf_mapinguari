class_name ItemData
extends Resource

## Recurso de Definição de Itens, Relíquias e Utilitários no Folchess

enum ItemCategory {
	COMPONENT,      # Componente básico (8 elementos da terra)
	MYTHIC_BASE,    # Muiraquitã Bruto (Espátula folclórica)
	COMPLETED,      # Item completo gerado por fusão de 2 componentes
	EMBLEM,         # Concede Origem ou +1 espaço no tabuleiro
	CONSUMABLE      # Utilitário de tabuleiro/banco (Removedor, Reforjador, Clonador, Café)
}

@export var id: StringName = &""
@export var name: String = ""
@export_multiline var description: String = ""
@export var category: ItemCategory = ItemCategory.COMPONENT
@export var icon: Texture2D = null

## Se for item completo ou emblema, contém os 2 IDs de componentes necessários
@export var recipe: Array[StringName] = []

## Modificadores diretos de atributos:
## "attack_damage", "ability_power_pct", "armor", "magic_resist",
## "attack_speed_pct", "starting_mana", "max_health", "critical_chance", "dodge_chance"
@export var stat_modifiers: Dictionary = {}

## Identificador de passiva única de combate (ex: &"pequi_spikes", &"bonfim_ribbon", &"fulozinha_whip", etc.)
@export var unique_effect_id: StringName = &""

## Se for um Emblema de Sinergia, nome da Origem adicionada (ex: "Amazônico", "Caatinga", etc.)
@export var origin_grant: String = ""

## Se conceder espaço extra no tabuleiro (ex: Coroa das Icamiabas: +1)
@export var team_size_bonus: int = 0

## Se for consumível utilitário (ex: &"remover", &"reforger", &"cloner", &"coffee")
@export var consumable_action: StringName = &""

func is_component() -> bool:
	return category == ItemCategory.COMPONENT or category == ItemCategory.MYTHIC_BASE

func is_consumable() -> bool:
	return category == ItemCategory.CONSUMABLE

func is_emblem() -> bool:
	return category == ItemCategory.EMBLEM or not origin_grant.is_empty() or team_size_bonus > 0

func get_formatted_stats_text() -> String:
	var lines: Array[String] = []
	if stat_modifiers.has("attack_damage"):
		lines.append("+%d Dano de Ataque" % int(stat_modifiers["attack_damage"]))
	if stat_modifiers.has("ability_power_pct"):
		lines.append("+%d%% Poder de Habilidade" % int(stat_modifiers["ability_power_pct"] * 100.0))
	if stat_modifiers.has("armor"):
		lines.append("+%d Armadura" % int(stat_modifiers["armor"]))
	if stat_modifiers.has("magic_resist"):
		lines.append("+%d Resistência Mágica" % int(stat_modifiers["magic_resist"]))
	if stat_modifiers.has("attack_speed_pct"):
		lines.append("+%d%% Vel. de Ataque" % int(stat_modifiers["attack_speed_pct"] * 100.0))
	if stat_modifiers.has("starting_mana"):
		lines.append("+%d Mana Inicial" % int(stat_modifiers["starting_mana"]))
	if stat_modifiers.has("max_health"):
		lines.append("+%d Vida Máxima" % int(stat_modifiers["max_health"]))
	if stat_modifiers.has("critical_chance"):
		lines.append("+%d%% Chance Crítica" % int(stat_modifiers["critical_chance"] * 100.0))
	if stat_modifiers.has("dodge_chance"):
		lines.append("+%d%% Esquiva" % int(stat_modifiers["dodge_chance"] * 100.0))
	if not origin_grant.is_empty():
		lines.append("Concede a Origem: %s" % origin_grant)
	if team_size_bonus > 0:
		lines.append("+%d Limite da Equipe" % team_size_bonus)
	return "\n".join(lines)

