class_name StatusEffectComponent
extends Node

## Componente de Efeitos de Status e Controle de Grupo (CC)

const BattleClock = preload("res://Scripts/Systems/battle_clock.gd")

signal stun_applied(duration: float, label: String)
signal stun_recovered()
signal status_applied(status_name: String, duration: float)

var stunned_until_msec: int = 0
var strong_control_immune_until_msec: int = 0
var slowed_until_msec: int = 0
var attack_weakened_until_msec: int = 0
var attack_damage_multiplier: float = 1.0
var armor_shred_until_msec: int = 0
var armor_shred_amount: float = 0.0
var mr_shred_until_msec: int = 0
var mr_shred_amount: float = 0.0
var burn_until_msec: int = 0

var _was_stunned: bool = false

func is_stunned() -> bool:
	return BattleClock.now_msec() < stunned_until_msec

func is_slowed() -> bool:
	return BattleClock.now_msec() < slowed_until_msec

func is_burning() -> bool:
	return BattleClock.now_msec() < burn_until_msec

func is_strong_control_immune() -> bool:
	return BattleClock.now_msec() < strong_control_immune_until_msec

func apply_stun(duration: float, base_resist: float = 0.0, label: String = "ATORDOADO") -> bool:
	if duration <= 0.0:
		return false
	var now := BattleClock.now_msec()
	if now < strong_control_immune_until_msec:
		return false

	var capped_dur := minf(duration, 1.0)
	var final_resist := clampf(base_resist, 0.0, 0.50)
	var final_duration := capped_dur * (1.0 - final_resist)

	if final_duration <= 0.0:
		return false

	stunned_until_msec = maxi(stunned_until_msec, now + int(final_duration * 1000.0))
	strong_control_immune_until_msec = now + int((final_duration + 0.75) * 1000.0)
	_was_stunned = true
	stun_applied.emit(final_duration, label)
	return true

func update_stun_state() -> void:
	if _was_stunned and not is_stunned():
		_was_stunned = false
		stun_recovered.emit()

func apply_slow(duration: float, resistance: float = 0.0) -> void:
	var final_res := clampf(resistance, 0.0, 0.90)
	var adjusted := duration * (1.0 - final_res)
	slowed_until_msec = maxi(slowed_until_msec, BattleClock.now_msec() + int(adjusted * 1000.0))
	status_applied.emit("LENTO", adjusted)

func apply_attack_weakness(duration: float, damage_mult: float = 0.7) -> void:
	if duration <= 0.0:
		return
	var now := BattleClock.now_msec()
	if now >= attack_weakened_until_msec:
		attack_damage_multiplier = 1.0
	attack_damage_multiplier = minf(attack_damage_multiplier, clampf(damage_mult, 0.0, 1.0))
	attack_weakened_until_msec = maxi(attack_weakened_until_msec, now + int(duration * 1000.0))
	status_applied.emit("ENFRAQUECIDO", duration)

func get_effective_damage_multiplier() -> float:
	if BattleClock.now_msec() >= attack_weakened_until_msec:
		attack_damage_multiplier = 1.0
	return attack_damage_multiplier

func apply_armor_shred(duration: float, amount: float) -> void:
	if duration <= 0.0:
		return
	armor_shred_amount = maxf(armor_shred_amount, amount)
	armor_shred_until_msec = maxi(armor_shred_until_msec, BattleClock.now_msec() + int(duration * 1000.0))
	status_applied.emit("ARMADURA REDUZIDA", duration)

func get_active_armor_shred() -> float:
	if BattleClock.now_msec() < armor_shred_until_msec:
		return armor_shred_amount
	return 0.0

func apply_magic_resist_shred(duration: float, amount: float) -> void:
	if duration <= 0.0:
		return
	mr_shred_amount = maxf(mr_shred_amount, amount)
	mr_shred_until_msec = maxi(mr_shred_until_msec, BattleClock.now_msec() + int(duration * 1000.0))
	status_applied.emit("RESISTÊNCIA REDUZIDA", duration)

func get_active_mr_shred() -> float:
	if BattleClock.now_msec() < mr_shred_until_msec:
		return mr_shred_amount
	return 0.0

func reset_all() -> void:
	stunned_until_msec = 0
	strong_control_immune_until_msec = 0
	slowed_until_msec = 0
	attack_weakened_until_msec = 0
	attack_damage_multiplier = 1.0
	armor_shred_until_msec = 0
	armor_shred_amount = 0.0
	mr_shred_until_msec = 0
	mr_shred_amount = 0.0
	burn_until_msec = 0
	_was_stunned = false
