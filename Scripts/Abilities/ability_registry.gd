class_name AbilityRegistry
extends RefCounted

## Registro e despachante do Padrão Strategy para habilidades

const UnitAbility = preload("res://Scripts/Abilities/unit_ability.gd")

static var _abilities: Dictionary = {}

static func _ensure_registered() -> void:
	if not _abilities.is_empty():
		return
	_abilities["alamoa"] = preload("res://Scripts/Abilities/Bespoke/alamoa_ability.gd").new()
	_abilities["anhanga"] = preload("res://Scripts/Abilities/Bespoke/anhanga_ability.gd").new()
	_abilities["araucaria"] = preload("res://Scripts/Abilities/Bespoke/araucaria_ability.gd").new()
	_abilities["caapora"] = preload("res://Scripts/Abilities/Bespoke/caapora_ability.gd").new()
	_abilities["cabeca_de_cuia"] = preload("res://Scripts/Abilities/Bespoke/cabeca_de_cuia_ability.gd").new()
	_abilities["comadre_fulozinha"] = preload("res://Scripts/Abilities/Bespoke/comadre_fulozinha_ability.gd").new()
	_abilities["corpo_seco"] = preload("res://Scripts/Abilities/Bespoke/corpo_seco_ability.gd").new()
	_abilities["cumacanga"] = preload("res://Scripts/Abilities/Bespoke/cumacanga_ability.gd").new()
	_abilities["jararaca"] = preload("res://Scripts/Abilities/Bespoke/jararaca_ability.gd").new()
	_abilities["mae_de_ouro"] = preload("res://Scripts/Abilities/Bespoke/mae_de_ouro_ability.gd").new()
	_abilities["mapinguari"] = preload("res://Scripts/Abilities/Bespoke/mapinguari_ability.gd").new()
	_abilities["matinta_perera"] = preload("res://Scripts/Abilities/Bespoke/matinta_perera_ability.gd").new()
	_abilities["mboi_guacu"] = preload("res://Scripts/Abilities/Bespoke/mboi_guacu_ability.gd").new()
	_abilities["minhocao"] = preload("res://Scripts/Abilities/Bespoke/minhocao_ability.gd").new()
	_abilities["onca_pintada"] = preload("res://Scripts/Abilities/Bespoke/onca_pintada_ability.gd").new()
	_abilities["papa_figo"] = preload("res://Scripts/Abilities/Bespoke/papa_figo_ability.gd").new()
	_abilities["pau_brasil"] = preload("res://Scripts/Abilities/Bespoke/pau_brasil_ability.gd").new()
	_abilities["pisadeira"] = preload("res://Scripts/Abilities/Bespoke/pisadeira_ability.gd").new()
	_abilities["quibungo"] = preload("res://Scripts/Abilities/Bespoke/quibungo_ability.gd").new()
	_abilities["sabia_laranjeira"] = preload("res://Scripts/Abilities/Bespoke/sabia_laranjeira_ability.gd").new()
	_abilities["sumauma"] = preload("res://Scripts/Abilities/Bespoke/sumauma_ability.gd").new()
	_abilities["teiniagua"] = preload("res://Scripts/Abilities/Bespoke/teiniagua_ability.gd").new()

static func execute_ability(unit: BaseUnit3D, scale_multiplier: float = 1.0) -> bool:
	if not is_instance_valid(unit) or not unit.stats:
		return false

	_ensure_registered()
	var unit_id := unit.stats.unit_id
	if _abilities.has(unit_id):
		return _abilities[unit_id].execute(unit, scale_multiplier)

	return false
