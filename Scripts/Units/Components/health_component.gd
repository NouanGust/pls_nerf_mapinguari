class_name HealthComponent
extends Node

## Componente de Vida e Escudo para Unidades de Combate

signal health_changed(current: float, max_val: float)
signal shield_changed(current: float, max_val: float)
signal damage_taken(absorbed_shield: float, damage_hp: float, damage_type: int)
signal healed(amount: float)
signal died(killer: Node)

@export var max_health: float = 1000.0
@export var current_health: float = 1000.0
@export var current_shield: float = 0.0
@export var current_shield_source: int = 0

## Decaimento suave de escudo por segundo (bem baixo)
@export var shield_decay_rate_pct: float = 0.05 # 5% do escudo por segundo
@export var shield_decay_flat: float = 8.0 # 8 pontos de escudo por segundo

const SHIELD_MAX_RATIO: float = 0.40

func initialize(base_max_health: float) -> void:
	max_health = maxf(base_max_health, 1.0)
	current_health = max_health
	current_shield = 0.0
	current_shield_source = 0
	health_changed.emit(current_health, max_health)
	shield_changed.emit(current_shield, max_health)

func has_active_shield() -> bool:
	return current_shield > 0.0

func set_shield(amount: float, source: int = 0) -> void:
	current_shield_source = source
	var cap := max_health * SHIELD_MAX_RATIO
	current_shield = clampf(amount, 0.0, cap)
	shield_changed.emit(current_shield, max_health)

func clear_shield() -> void:
	if current_shield > 0.0 or current_shield_source != 0:
		current_shield = 0.0
		current_shield_source = 0
		shield_changed.emit(0.0, max_health)

func decay_shield(delta: float) -> float:
	if current_shield <= 0.0 or delta <= 0.0:
		return 0.0
	var decay_amount := (current_shield * shield_decay_rate_pct + shield_decay_flat) * delta
	var actual_loss := minf(current_shield, decay_amount)
	current_shield = maxf(0.0, current_shield - actual_loss)
	if current_shield <= 0.0:
		current_shield_source = 0
	shield_changed.emit(current_shield, max_health)
	return actual_loss

func apply_damage(raw_mitigated_damage: float) -> Dictionary:
	var result := {
		"was_shielded": has_active_shield(),
		"absorbed_by_shield": 0.0,
		"damage_to_health": 0.0,
		"is_fatal": false
	}
	
	if raw_mitigated_damage <= 0.0 or current_health <= 0.0:
		return result

	var shield_absorbed := minf(current_shield, raw_mitigated_damage)
	current_shield -= shield_absorbed
	var health_damage := raw_mitigated_damage - shield_absorbed
	current_health -= health_damage

	result["absorbed_by_shield"] = shield_absorbed
	result["damage_to_health"] = health_damage

	if shield_absorbed > 0.0 or current_shield <= 0.0:
		shield_changed.emit(current_shield, max_health)
	
	health_changed.emit(current_health, max_health)
	damage_taken.emit(shield_absorbed, health_damage, 0)

	if current_health <= 0.0:
		result["is_fatal"] = true
		died.emit(null)

	return result

func apply_heal(amount: float, heal_received_multiplier: float = 1.0) -> float:
	if current_health <= 0.0 or amount <= 0.0:
		return 0.0

	var effective_heal := amount * maxf(heal_received_multiplier, 0.0)
	var missing_hp := maxf(max_health - current_health, 0.0)
	var final_healed := minf(effective_heal, missing_hp)

	if final_healed <= 0.0:
		return 0.0

	current_health += final_healed
	health_changed.emit(current_health, max_health)
	healed.emit(final_healed)
	return final_healed

func reset_state() -> void:
	current_health = max_health
	clear_shield()
	health_changed.emit(current_health, max_health)
