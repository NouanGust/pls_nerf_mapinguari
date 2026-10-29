class_name SynergySystem
extends Node

## As 9 origens temáticas da proposta (PROPOSTA_ORIGENS_SINERGIAS_E_EQUIPES.md):
## Cada unidade possui exatamente duas origens e cada unit_id conta uma única vez.
## Cada origem beneficia seus próprios integrantes vivos em combate.
const RULES: Array[Dictionary] = [
	{"field": "origins", "name": "Seiva", "thresholds": [3, 6, 9], "effects": [
		{"text": "A cada 4s, cura 2% da vida máx e ganha +2% de poder (máx. 3 acúmulos)", "bonuses": {"seiva_pulse_heal_pct": 0.02, "seiva_growth_pct": 0.02}},
		{"text": "A cada 4s, cura 3% da vida máx e ganha +4% de poder (máx. 3 acúmulos)", "bonuses": {"seiva_pulse_heal_pct": 0.03, "seiva_growth_pct": 0.04}},
		{"text": "A cada 4s, cura 5% da vida máx e ganha +7% de poder (máx. 3 acúmulos)", "bonuses": {"seiva_pulse_heal_pct": 0.05, "seiva_growth_pct": 0.07}},
	]},
	{"field": "origins", "name": "Vigília", "thresholds": [2, 4, 6, 8], "effects": [
		{"text": "Ao cair de 50% de vida, ganha escudo de 8% da vida máx e 10% de resist. a controle por 4s", "bonuses": {"vigilia_shield_pct": 0.08, "vigilia_cc_resist_pct": 0.10}},
		{"text": "Ao cair de 50% de vida, ganha escudo de 14% da vida máx e 15% de resist. a controle por 4s", "bonuses": {"vigilia_shield_pct": 0.14, "vigilia_cc_resist_pct": 0.15}},
		{"text": "Ao cair de 50% de vida, ganha escudo de 20% da vida máx e 25% de resist. a controle por 4s", "bonuses": {"vigilia_shield_pct": 0.20, "vigilia_cc_resist_pct": 0.25}},
		{"text": "Ao cair de 50% de vida, ganha escudo de 28% da vida máx e 35% de resist. a controle por 4s", "bonuses": {"vigilia_shield_pct": 0.28, "vigilia_cc_resist_pct": 0.35}},
	]},
	{"field": "origins", "name": "Correnteza", "thresholds": [3, 6, 9], "effects": [
		{"text": "A cada 5s, ganha 6 de mana e escudo de 3% da vida máx por 2s", "bonuses": {"correnteza_mana": 6.0, "correnteza_shield_pct": 0.03}},
		{"text": "A cada 5s, ganha 10 de mana e escudo de 5% da vida máx por 2s", "bonuses": {"correnteza_mana": 10.0, "correnteza_shield_pct": 0.05}},
		{"text": "A cada 5s, ganha 16 de mana e escudo de 8% da vida máx por 2s", "bonuses": {"correnteza_mana": 16.0, "correnteza_shield_pct": 0.08}},
	]},
	{"field": "origins", "name": "Vozes", "thresholds": [3, 6, 9], "effects": [
		{"text": "Ao conjurar, envia Eco dando 4 de mana a até 2 aliados de Vozes a 2 hexágonos", "bonuses": {"vozes_echo_mana": 4.0}},
		{"text": "Ao conjurar, envia Eco dando 7 de mana a até 2 aliados de Vozes a 2 hexágonos", "bonuses": {"vozes_echo_mana": 7.0}},
		{"text": "Ao conjurar, envia Eco dando 11 de mana a até 2 aliados de Vozes a 2 hexágonos", "bonuses": {"vozes_echo_mana": 11.0}},
	]},
	{"field": "origins", "name": "Ferocidade", "thresholds": [2, 4, 6, 8], "max_stacks": 8, "effects": [
		{"text": "Ataques concedem +1,5% de ataque (máx. 8 acúmulos); cura 1% da vida a cada 3º ataque", "bonuses": {"ferocidade_atk_pct": 0.015, "ferocidade_heal_pct": 0.01}},
		{"text": "Ataques concedem +2,5% de ataque (máx. 8 acúmulos); cura 1,5% da vida a cada 3º ataque", "bonuses": {"ferocidade_atk_pct": 0.025, "ferocidade_heal_pct": 0.015}},
		{"text": "Ataques concedem +3,5% de ataque (máx. 8 acúmulos); cura 2% da vida a cada 3º ataque", "bonuses": {"ferocidade_atk_pct": 0.035, "ferocidade_heal_pct": 0.02}},
		{"text": "Ataques concedem +5% de ataque (máx. 8 acúmulos); cura 3% da vida a cada 3º ataque", "bonuses": {"ferocidade_atk_pct": 0.05, "ferocidade_heal_pct": 0.03}},
	]},
	{"field": "origins", "name": "Travessia", "thresholds": [2, 4, 6, 8], "effects": [
		{"text": "Ao trocar de alvo, ganha +12% vel. movimento por 2s e +10% de dano no primeiro golpe", "bonuses": {"travessia_speed_pct": 0.12, "travessia_burst_pct": 0.10}},
		{"text": "Ao trocar de alvo, ganha +20% vel. movimento por 2s e +16% de dano no primeiro golpe", "bonuses": {"travessia_speed_pct": 0.20, "travessia_burst_pct": 0.16}},
		{"text": "Ao trocar de alvo, ganha +30% vel. movimento por 2s e +24% de dano no primeiro golpe", "bonuses": {"travessia_speed_pct": 0.30, "travessia_burst_pct": 0.24}},
		{"text": "Ao trocar de alvo, ganha +45% vel. movimento por 2s e +35% de dano no primeiro golpe", "bonuses": {"travessia_speed_pct": 0.45, "travessia_burst_pct": 0.35}},
	]},
	{"field": "origins", "name": "Assombro", "thresholds": [2, 4, 6, 8], "effects": [
		{"text": "Golpes aplicam marca por 4s, reduzindo armadura e resistência mágica em 6%", "bonuses": {"assombro_shred_pct": 0.06}},
		{"text": "Golpes aplicam marca por 4s, reduzindo armadura e resistência mágica em 10%", "bonuses": {"assombro_shred_pct": 0.10}},
		{"text": "Golpes aplicam marca por 4s, reduzindo armadura e resistência mágica em 15%", "bonuses": {"assombro_shred_pct": 0.15}},
		{"text": "Golpes aplicam marca por 4s, reduzindo armadura e resistência mágica em 22%", "bonuses": {"assombro_shred_pct": 0.22}},
	]},
	{"field": "origins", "name": "Encanto", "thresholds": [2, 4, 6, 8], "effects": [
		{"text": "Após conjurar, a próxima habilidade tem dano, cura e escudos aumentados em +8%", "bonuses": {"encanto_power_pct": 0.08}},
		{"text": "Após conjurar, a próxima habilidade tem dano, cura e escudos aumentados em +14%", "bonuses": {"encanto_power_pct": 0.14}},
		{"text": "Após conjurar, a próxima habilidade tem dano, cura e escudos aumentados em +22%", "bonuses": {"encanto_power_pct": 0.22}},
		{"text": "Após conjurar, a próxima habilidade tem dano, cura e escudos aumentados em +32%", "bonuses": {"encanto_power_pct": 0.32}},
	]},
	{"field": "origins", "name": "Fulgor", "thresholds": [1, 2, 3, 4], "effects": [
		{"text": "+5 de mana inicial e +8% de potência na primeira habilidade", "bonuses": {"fulgor_start_mana": 5.0, "fulgor_power_pct": 0.08}},
		{"text": "+10 de mana inicial e +12% de potência na primeira habilidade", "bonuses": {"fulgor_start_mana": 10.0, "fulgor_power_pct": 0.12}},
		{"text": "+18 de mana inicial e +18% de potência na primeira habilidade", "bonuses": {"fulgor_start_mana": 18.0, "fulgor_power_pct": 0.18}},
		{"text": "+28 de mana inicial e +25% de potência na primeira habilidade", "bonuses": {"fulgor_start_mana": 28.0, "fulgor_power_pct": 0.25}},
	]},
]

const LEGACY_RULES: Array[Dictionary] = [
	{"field": "origins", "name": "Cerrado", "thresholds": [2, 4], "max_stacks": 10, "effects": [
		{"text": "Ganha 6% de crítico por abate (máx. 10 acúmulos)", "bonuses": {"crit_after_kill": 0.06}},
		{"text": "Ganha 12% de crítico por abate (máx. 10 acúmulos)", "bonuses": {"crit_after_kill": 0.12}},
	]},
]

static func get_rule_for_tag(tag_name: String) -> Dictionary:
	for rule in RULES:
		if str(rule.get("name", "")) == tag_name:
			return rule
	for rule in LEGACY_RULES:
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
				var tags: Array = unit.stats.get(field)
				if tags.has(tag):
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
			if max_stacks > 0:
				for unit in members:
					if unit.stats and unit.stats.get(field).has(tag):
						var u_st: int = int(unit.ferocidade_stacks if "ferocidade_stacks" in unit else unit.enemies_defeated)
						current_stacks = maxi(current_stacks, u_st)
				current_stacks = mini(current_stacks, max_stacks)

			results[team_id].append({
				"name": tag,
				"category": "Origem" if field == "origins" else "Classe",
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
			# Regra central: Cada origem beneficia seus próprios integrantes!
			for unit in members:
				if unit.stats and unit.stats.get(field).has(tag):
					var unit_bonuses: Dictionary = bonuses_by_unit[unit.get_instance_id()]
					for key in effect_bonuses:
						unit_bonuses[key] = float(unit_bonuses.get(key, 0.0)) + float(effect_bonuses[key])
					bonuses_by_unit[unit.get_instance_id()] = unit_bonuses
		for unit in members:
			unit.set_synergy_bonuses(bonuses_by_unit[unit.get_instance_id()])
	return results
