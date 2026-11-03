class_name ManaComponent
extends Node

## Componente de Mana para Unidades de Combate

signal mana_changed(current: float, max_val: float)
signal ability_ready()

@export var current_mana: float = 0.0
@export var max_mana: float = 100.0
@export var starting_mana: float = 0.0
@export var mana_per_attack: float = 10.0
@export var mana_when_hit: float = 5.0

func initialize(max_m: float, start_m: float = 0.0, per_atk: float = 10.0, when_hit: float = 5.0) -> void:
	max_mana = maxf(max_m, 1.0)
	starting_mana = clampf(start_m, 0.0, max_mana)
	current_mana = starting_mana
	mana_per_attack = per_atk
	mana_when_hit = when_hit
	mana_changed.emit(current_mana, max_mana)

func can_cast() -> bool:
	return current_mana >= max_mana

func add_mana(amount: float, has_shield: bool, is_busy_or_dead: bool, generation_multiplier: float = 1.0) -> bool:
	# Regra estrita: unidades com escudo ativo ou mortas/conjurando não geram nem recebem mana
	if has_shield or is_busy_or_dead or amount <= 0.0:
		return false

	var adjusted := amount * maxf(generation_multiplier, 0.0)
	var prev_mana := current_mana
	current_mana = minf(current_mana + adjusted, max_mana)

	if current_mana != prev_mana:
		mana_changed.emit(current_mana, max_mana)

	if current_mana >= max_mana and prev_mana < max_mana:
		ability_ready.emit()

	return true

func spend_mana() -> void:
	current_mana = 0.0
	mana_changed.emit(current_mana, max_mana)

func reset_to_starting() -> void:
	current_mana = starting_mana
	mana_changed.emit(current_mana, max_mana)
