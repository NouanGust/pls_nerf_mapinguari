class_name SynergySystem
extends Node

## Patamares por identidade: individuais, pares e composições de três ou mais.
## Cada unit_id conta uma única vez, independentemente das estrelas ou cópias.
const RULES: Array[Dictionary] = [
	{"field": "origins", "name": "Amazônico", "thresholds": [3, 6], "effects": [
		{"text": "Regenera 4 de vida por segundo", "bonuses": {"health_regen": 4.0}},
		{"text": "Regenera 8 de vida por segundo", "bonuses": {"health_regen": 8.0}},
	]},
	{"field": "origins", "name": "Aquático", "thresholds": [1], "effects": [
		{"text": "Começa o combate com escudo de 8% da vida", "bonuses": {"start_shield_pct": 0.08}},
	]},
	{"field": "origins", "name": "Caatinga", "thresholds": [2, 4], "effects": [
		{"text": "Recebe 8% menos dano", "bonuses": {"damage_reduction_pct": 0.08}},
		{"text": "Recebe 15% menos dano e resiste a controle", "bonuses": {"damage_reduction_pct": 0.15, "control_resist_pct": 0.20}},
	]},
	{"field": "origins", "name": "Cerrado", "thresholds": [2, 4], "effects": [
		{"text": "Ganha 6% de crítico por inimigo derrotado", "bonuses": {"crit_after_kill": 0.06}},
		{"text": "Ganha 12% de crítico por inimigo derrotado", "bonuses": {"crit_after_kill": 0.12}},
	]},
	{"field": "origins", "name": "Litorâneo", "thresholds": [2, 4], "effects": [
		{"text": "+10% de velocidade de ataque", "bonuses": {"attack_speed_pct": 0.10}},
		{"text": "+20% de velocidade de ataque e resistência a controle", "bonuses": {"attack_speed_pct": 0.20, "control_resist_pct": 0.20}},
	]},
	{"field": "origins", "name": "Mata Atlântica", "thresholds": [3, 5], "effects": [
		{"text": "Regenera 4 de vida por segundo", "bonuses": {"health_regen": 4.0}},
		{"text": "Regenera 8/s e cura de habilidades +15%", "bonuses": {"health_regen": 8.0, "healing_power_pct": 0.15}},
	]},
	{"field": "origins", "name": "Pantaneiro", "thresholds": [3, 5], "effects": [
		{"text": "+8% de vida máxima e cura recebida", "bonuses": {"max_health_pct": 0.08, "healing_received_pct": 0.15}},
		{"text": "+15% de vida máxima e cura recebida", "bonuses": {"max_health_pct": 0.15, "healing_received_pct": 0.30}},
	]},
	{"field": "origins", "name": "Sertanejo", "thresholds": [3, 5], "effects": [
		{"text": "Com pouca vida, recebe 10% menos dano", "bonuses": {"low_health_resistance_pct": 0.10}},
		{"text": "Com pouca vida, recebe 20% menos dano", "bonuses": {"low_health_resistance_pct": 0.20}},
	]},
	{"field": "origins", "name": "Urbano", "thresholds": [2, 4], "effects": [
		{"text": "+10% de velocidade de ataque; primeiro golpe +15%", "bonuses": {"attack_speed_pct": 0.10, "first_attack_bonus_pct": 0.15}},
		{"text": "+20% de velocidade de ataque; primeiro golpe +30%", "bonuses": {"attack_speed_pct": 0.20, "first_attack_bonus_pct": 0.30}},
	]},
	{"field": "classes", "name": "Aquático", "thresholds": [2, 4], "effects": [
		{"text": "+12 de resistência mágica", "bonuses": {"magic_resist_flat": 12.0}},
		{"text": "+24 de resistência mágica", "bonuses": {"magic_resist_flat": 24.0}},
	]},
	{"field": "classes", "name": "Assombração", "thresholds": [2, 4], "effects": [
		{"text": "Ataques têm 15% de chance de desacelerar", "bonuses": {"slow_on_hit_chance": 0.15}},
		{"text": "Ataques têm 30% de chance de desacelerar", "bonuses": {"slow_on_hit_chance": 0.30}},
	]},
	{"field": "classes", "name": "Caçador", "thresholds": [2, 4], "effects": [
		{"text": "Marca o alvo mais ferido; equipe causa +10% de dano", "bonuses": {"marked_target_damage_pct": 0.10}},
		{"text": "Marca o alvo mais ferido; equipe causa +20% de dano", "bonuses": {"marked_target_damage_pct": 0.20}},
	]},
	{"field": "classes", "name": "DPS", "thresholds": [2, 4], "effects": [
		{"text": "+8% de dano causado", "bonuses": {"damage_pct": 0.08}},
		{"text": "+16% de dano causado", "bonuses": {"damage_pct": 0.16}},
	]},
	{"field": "classes", "name": "Encantado", "thresholds": [2, 4], "effects": [
		{"text": "+15% de poder de habilidade e cura", "bonuses": {"healing_power_pct": 0.15}},
		{"text": "+30% de poder de habilidade e cura", "bonuses": {"healing_power_pct": 0.30}},
	]},
	{"field": "classes", "name": "Metamorfo", "thresholds": [1], "effects": [
		{"text": "20% de chance de esquivar do primeiro golpe", "bonuses": {"dodge_first_hit_chance": 0.20}},
	]},
	{"field": "classes", "name": "Místico", "thresholds": [2, 4], "effects": [
		{"text": "+12% de poder de habilidade e geração de mana", "bonuses": {"healing_power_pct": 0.12, "mana_generation_pct": 0.10}},
		{"text": "+24% de poder de habilidade e geração de mana", "bonuses": {"healing_power_pct": 0.24, "mana_generation_pct": 0.20}},
	]},
	{"field": "classes", "name": "Protetor da Mata", "thresholds": [2, 4], "effects": [
		{"text": "+12 de armadura", "bonuses": {"armor_flat": 12.0}},
		{"text": "+24 de armadura e regenera 3 de vida/s", "bonuses": {"armor_flat": 24.0, "health_regen": 3.0}},
	]},
	{"field": "classes", "name": "Suporte", "thresholds": [2, 4], "effects": [
		{"text": "+15% de cura e escudos concedidos", "bonuses": {"healing_power_pct": 0.15, "shield_power_pct": 0.15}},
		{"text": "+30% de cura e escudos concedidos", "bonuses": {"healing_power_pct": 0.30, "shield_power_pct": 0.30}},
	]},
	{"field": "classes", "name": "Tank", "thresholds": [3, 6], "effects": [
		{"text": "+10% de vida máxima e 10 de armadura", "bonuses": {"max_health_pct": 0.10, "armor_flat": 10.0}},
		{"text": "+20% de vida máxima e 20 de armadura", "bonuses": {"max_health_pct": 0.20, "armor_flat": 20.0}},
	]},
	{"field": "affinities", "name": "Fauna", "thresholds": [3, 6], "effects": [
		{"text": "+10% de velocidade de ataque e movimento", "bonuses": {"attack_speed_pct": 0.10, "move_speed_pct": 0.10}},
		{"text": "+20% de velocidade; aliados focados causam +10%", "bonuses": {"attack_speed_pct": 0.20, "move_speed_pct": 0.20, "focus_fire_damage_pct": 0.10}},
	]},
	{"field": "affinities", "name": "Flora", "thresholds": [3, 6], "effects": [
		{"text": "+15% de cura e escudos recebidos", "bonuses": {"healing_received_pct": 0.15, "shield_received_pct": 0.15}},
		{"text": "+30% de cura e escudos; 15% de chance de enraizar", "bonuses": {"healing_received_pct": 0.30, "shield_received_pct": 0.30, "root_on_hit_chance": 0.15}},
	]},
]

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
			results[team_id].append({
				"name": tag,
				"category": "Origem" if field == "origins" else ("Classe" if field == "classes" else "Afinidade"),
				"count": count,
				"tier": tier_index + 1,
				"threshold": next_threshold,
				"thresholds": rule.thresholds.duplicate(),
				"active": tier_index >= 0,
				"description": effect.text,
				"units": unit_names,
			})
			if tier_index < 0:
				continue
			var effect_bonuses: Dictionary = effect.bonuses
			for unit in members:
				var unit_bonuses: Dictionary = bonuses_by_unit[unit.get_instance_id()]
				for key in effect_bonuses:
					unit_bonuses[key] = float(unit_bonuses.get(key, 0.0)) + float(effect_bonuses[key])
				bonuses_by_unit[unit.get_instance_id()] = unit_bonuses
		for unit in members:
			unit.set_synergy_bonuses(bonuses_by_unit[unit.get_instance_id()])
	return results
