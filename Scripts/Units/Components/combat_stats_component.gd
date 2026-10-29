class_name CombatStatsComponent
extends Node

## Componente de Cálculo de Atributos e Mitigação de Dano

const BattleClock = preload("res://Scripts/Systems/battle_clock.gd")

var active_buffs: Array[Dictionary] = []

func add_buff(buff: Dictionary) -> void:
	active_buffs.append(buff)

func prune_expired_buffs() -> void:
	var now := BattleClock.now_msec()
	active_buffs = active_buffs.filter(func(buff):
		return not buff.has("expires_at_msec") or int(buff.expires_at_msec) > now
	)

func calculate_mitigated_damage(
	raw_amount: float,
	damage_type: int,
	effective_armor: float,
	effective_mr: float,
	extra_reduction_pct: float = 0.0
) -> float:
	if raw_amount <= 0.0:
		return 0.0
	
	# TRUE DAMAGE ignora mitigações
	if damage_type == UnitStats.DamageType.TRUE:
		return raw_amount

	var mitigation := 0.0
	if damage_type == UnitStats.DamageType.PHYSICAL:
		mitigation = effective_armor / (100.0 + maxf(effective_armor, 0.0))
	elif damage_type == UnitStats.DamageType.MAGICAL:
		mitigation = effective_mr / (100.0 + maxf(effective_mr, 0.0))

	mitigation = clampf(mitigation, 0.0, 0.80)
	var final_extra_red := clampf(extra_reduction_pct, 0.0, 0.80)
	var actual := raw_amount * (1.0 - mitigation) * (1.0 - final_extra_red)
	return maxf(actual, 0.0)

func reset_buffs() -> void:
	active_buffs.clear()
