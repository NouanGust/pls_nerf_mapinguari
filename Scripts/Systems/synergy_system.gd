class_name SynergySystem
extends Node

## Patamares por identidade: 9 novas origens temáticas.
## Cada unit_id conta uma única vez, independentemente das estrelas ou cópias.
## Cada unidade possui exatamente duas origens e uma função de combate.
## As origens beneficiam apenas os seus próprios integrantes.
const RULES: Array[Dictionary] = [
	{"field": "origins", "name": "Seiva", "thresholds": [3, 6, 9], "effects": [
		{"text": "A cada 4s, cura 2% da vida max e ganha +2% de dano/cura/escudos (max 3 acumulos: +6%)", "bonuses": {"seiva_heal_pct": 0.02, "seiva_growth_pct": 0.02}},
		{"text": "A cada 4s, cura 3% da vida max e ganha +4% de dano/cura/escudos (max 3 acumulos: +12%)", "bonuses": {"seiva_heal_pct": 0.03, "seiva_growth_pct": 0.04}},
		{"text": "A cada 4s, cura 5% da vida max e ganha +7% de dano/cura/escudos (max 3 acumulos: +21%)", "bonuses": {"seiva_heal_pct": 0.05, "seiva_growth_pct": 0.07}},
	]},
	{"field": "origins", "name": "Vigília", "thresholds": [2, 4, 6, 8], "effects": [
		{"text": "Abaixo de 50% vida, ganha escudo de 8% da vida max por 4s e 10% de resistencia a controle", "bonuses": {"vigilia_shield_pct": 0.08, "vigilia_control_resist": 0.10}},
		{"text": "Abaixo de 50% vida, ganha escudo de 14% da vida max por 4s e 15% de resistencia a controle", "bonuses": {"vigilia_shield_pct": 0.14, "vigilia_control_resist": 0.15}},
		{"text": "Abaixo de 50% vida, ganha escudo de 20% da vida max por 4s e 25% de resistencia a controle", "bonuses": {"vigilia_shield_pct": 0.20, "vigilia_control_resist": 0.25}},
		{"text": "Abaixo de 50% vida, ganha escudo de 28% da vida max por 4s e 35% de resistencia a controle", "bonuses": {"vigilia_shield_pct": 0.28, "vigilia_control_resist": 0.35}},
	]},
	{"field": "origins", "name": "Correnteza", "thresholds": [3, 6, 9], "effects": [
		{"text": "A cada 5s, ganha 6 de mana e escudo de 3% da vida max por 2s", "bonuses": {"correnteza_mana": 6.0, "correnteza_shield_pct": 0.03}},
		{"text": "A cada 5s, ganha 10 de mana e escudo de 5% da vida max por 2s", "bonuses": {"correnteza_mana": 10.0, "correnteza_shield_pct": 0.05}},
		{"text": "A cada 5s, ganha 16 de mana e escudo de 8% da vida max por 2s", "bonuses": {"correnteza_mana": 16.0, "correnteza_shield_pct": 0.08}},
	]},
	{"field": "origins", "name": "Vozes", "thresholds": [3, 6, 9], "effects": [
		{"text": "Ao concluir habilidade, envia Eco dando 4 de mana a ate 2 aliados de Vozes em 2 hexes", "bonuses": {"vozes_echo_mana": 4.0}},
		{"text": "Ao concluir habilidade, envia Eco dando 7 de mana a ate 2 aliados de Vozes em 2 hexes", "bonuses": {"vozes_echo_mana": 7.0}},
		{"text": "Ao concluir habilidade, envia Eco dando 11 de mana a ate 2 aliados de Vozes em 2 hexes", "bonuses": {"vozes_echo_mana": 11.0}},
	]},
	{"field": "origins", "name": "Ferocidade", "thresholds": [2, 4, 6, 8], "effects": [
		{"text": "Ataques dao acumulo de Impeto (+1.5% atq, max 8: +12%); a cada 3o ataque cura 1% vida max", "bonuses": {"feroc_per_stack": 0.015, "feroc_heal_pct": 0.01}},
		{"text": "Ataques dao acumulo de Impeto (+2.5% atq, max 8: +20%); a cada 3o ataque cura 1.5% vida max", "bonuses": {"feroc_per_stack": 0.025, "feroc_heal_pct": 0.015}},
		{"text": "Ataques dao acumulo de Impeto (+3.5% atq, max 8: +28%); a cada 3o ataque cura 2% vida max", "bonuses": {"feroc_per_stack": 0.035, "feroc_heal_pct": 0.02}},
		{"text": "Ataques dao acumulo de Impeto (+5.0% atq, max 8: +40%); a cada 3o ataque cura 3% vida max", "bonuses": {"feroc_per_stack": 0.050, "feroc_heal_pct": 0.03}},
	]},
	{"field": "origins", "name": "Travessia", "thresholds": [2, 4, 6, 8], "effects": [
		{"text": "Ao mudar de alvo: +12% vel. movimento por 2s e proximo golpe contra o alvo causa +10% de dano", "bonuses": {"travessia_speed_pct": 0.12, "travessia_strike_pct": 0.10}},
		{"text": "Ao mudar de alvo: +20% vel. movimento por 2s e proximo golpe contra o alvo causa +16% de dano", "bonuses": {"travessia_speed_pct": 0.20, "travessia_strike_pct": 0.16}},
		{"text": "Ao mudar de alvo: +30% vel. movimento por 2s e proximo golpe contra o alvo causa +24% de dano", "bonuses": {"travessia_speed_pct": 0.30, "travessia_strike_pct": 0.24}},
		{"text": "Ao mudar de alvo: +45% vel. movimento por 2s e proximo golpe contra o alvo causa +35% de dano", "bonuses": {"travessia_speed_pct": 0.45, "travessia_strike_pct": 0.35}},
	]},
	{"field": "origins", "name": "Assombro", "thresholds": [2, 4, 6, 8], "effects": [
		{"text": "Ataques ou dano marcam o alvo por 4s: reduz armadura e resist. magica em 6%", "bonuses": {"assombro_pct": 0.06}},
		{"text": "Ataques ou dano marcam o alvo por 4s: reduz armadura e resist. magica em 10%", "bonuses": {"assombro_pct": 0.10}},
		{"text": "Ataques ou dano marcam o alvo por 4s: reduz armadura e resist. magica em 15%", "bonuses": {"assombro_pct": 0.15}},
		{"text": "Ataques ou dano marcam o alvo por 4s: reduz armadura e resist. magica em 22%", "bonuses": {"assombro_pct": 0.22}},
	]},
	{"field": "origins", "name": "Encanto", "thresholds": [2, 4, 6, 8], "effects": [
		{"text": "Apos concluir habilidade, prepara proxima habilidade com +8% de dano, cura e escudos", "bonuses": {"encanto_pct": 0.08}},
		{"text": "Apos concluir habilidade, prepara proxima habilidade com +14% de dano, cura e escudos", "bonuses": {"encanto_pct": 0.14}},
		{"text": "Apos concluir habilidade, prepara proxima habilidade com +22% de dano, cura e escudos", "bonuses": {"encanto_pct": 0.22}},
		{"text": "Apos concluir habilidade, prepara proxima habilidade com +32% de dano, cura e escudos", "bonuses": {"encanto_pct": 0.32}},
	]},
	{"field": "origins", "name": "Fulgor", "thresholds": [1, 2, 3, 4], "effects": [
		{"text": "Inicio do combate: +5 de mana inicial e primeira habilidade com +8% de dano, cura e escudos", "bonuses": {"fulgor_mana": 5.0, "fulgor_pct": 0.08}},
		{"text": "Inicio do combate: +10 de mana inicial e primeira habilidade com +12% de dano, cura e escudos", "bonuses": {"fulgor_mana": 10.0, "fulgor_pct": 0.12}},
		{"text": "Inicio do combate: +18 de mana inicial e primeira habilidade com +18% de dano, cura e escudos", "bonuses": {"fulgor_mana": 18.0, "fulgor_pct": 0.18}},
		{"text": "Inicio do combate: +28 de mana inicial e primeira habilidade com +25% de dano, cura e escudos", "bonuses": {"fulgor_mana": 28.0, "fulgor_pct": 0.25}},
	]},
]

static func get_rule_for_tag(tag_name: String) -> Dictionary:
	for rule in RULES:
		if str(rule.get("name", "")) == tag_name:
			return rule
	return {}

func update_synergies(units: Array) -> Dictionary:
	var all_unit_stats: Array = UnitSpawner.load_all_units().values()
	var members_by_team := {0: [], 1: []}
	for candidate in units:
		if not (candidate is BaseUnit3D) or not candidate.visible or candidate.current_state == BaseUnit3D.State.DEAD:
			continue
		members_by_team[candidate.team].append(candidate)

	var results := {0: [], 1: []}
	for team_id in [0, 1]:
		var members: Array = members_by_team[team_id]
		var bonuses_by_unit: Dictionary = {}
		for unit in members:
			bonuses_by_unit[unit.get_instance_id()] = {}
		for rule in RULES:
			var field: String = rule.field
			var tag: String = rule.name
			# Cópias do mesmo campeão contam como uma única unidade para ativar sinergias.
			var unique_members: Dictionary = {}
			for unit in members:
				if unit.stats:
					var tags: Array = unit.stats.get(field)
					var has_tag: bool = tags.has(tag)
					if not has_tag and field == "origins" and unit.has_method("get_item_granted_origins"):
						has_tag = unit.get_item_granted_origins().has(tag)
					if has_tag:
						unique_members[unit.stats.unit_id] = unit.stats
			var count := unique_members.size()
			if count == 0:
				continue
			var tier_index := -1
			for i in rule.thresholds.size():
				if count >= int(rule.thresholds[i]):
					tier_index = i
			var display_tier := maxi(tier_index, 0)
			var effect: Dictionary = rule.effects[display_tier]
			var next_threshold := int(rule.thresholds.back())
			for threshold in rule.thresholds:
				if count < int(threshold):
					next_threshold = int(threshold)
					break
			var unit_names: Array[String] = []
			for unit_stats in all_unit_stats:
				var unit_tags: Array = unit_stats.get(field)
				if unit_tags.has(tag):
					unit_names.append(unit_stats.unit_name)
			var max_stacks := int(rule.get("max_stacks", 0))
			var current_stacks := 0

			results[team_id].append({
				"name": tag,
				"category": "Origem",
				"count": count,
				"tier": tier_index + 1,
				"threshold": next_threshold,
				"thresholds": rule.thresholds.duplicate(),
				"active": tier_index >= 0,
				"description": effect.text,
				"units": unit_names,
				"stacks": current_stacks,
				"max_stacks": max_stacks,
			})
			if tier_index < 0:
				continue
			var effect_bonuses: Dictionary = effect.bonuses
			for unit in members:
				var has_orig: bool = (unit.stats and unit.stats.origins.has(tag))
				if not has_orig and unit.has_method("get_item_granted_origins"):
					has_orig = unit.get_item_granted_origins().has(tag)
				if has_orig:
					var unit_bonuses: Dictionary = bonuses_by_unit[unit.get_instance_id()]
					for key in effect_bonuses:
						unit_bonuses[key] = float(unit_bonuses.get(key, 0.0)) + float(effect_bonuses[key])
					bonuses_by_unit[unit.get_instance_id()] = unit_bonuses
		for unit in members:
			unit.set_synergy_bonuses(bonuses_by_unit[unit.get_instance_id()])
	return results
