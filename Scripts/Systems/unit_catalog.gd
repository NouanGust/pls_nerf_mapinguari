extends Node

## Catálogo e cache global de fichas de unidades (UnitStats)

const UNITS_PATH := "res://resources/units/"

var _units_cache: Dictionary = {}
var _units_by_tier: Dictionary = {}
var _units_by_origin: Dictionary = {}
var _units_by_role: Dictionary = {}
var _is_loaded := false

func _ready() -> void:
	ensure_loaded()

func ensure_loaded() -> void:
	if _is_loaded and not _units_cache.is_empty():
		return

	_units_cache.clear()
	_units_by_tier.clear()
	_units_by_origin.clear()
	_units_by_role.clear()

	for t in range(1, 6):
		_units_by_tier[t] = []

	if not DirAccess.dir_exists_absolute(UNITS_PATH):
		push_error("UnitCatalog: Diretório de unidades não encontrado: " + UNITS_PATH)
		return

	var loaded_count := 0
	for file_name in ResourceLoader.list_directory(UNITS_PATH):
		if file_name.ends_with(".tres"):
			var stats: UnitStats = ResourceLoader.load(UNITS_PATH + file_name)
			if stats and stats.is_valid():
				register_unit(stats)
				loaded_count += 1
			else:
				push_warning("UnitCatalog: Recurso inválido ignorado: " + file_name)

	_is_loaded = true
	print("UnitCatalog: %d unidades registradas no catálogo" % loaded_count)

func register_unit(stats: UnitStats) -> void:
	_units_cache[stats.unit_id] = stats

	var tier := clampi(stats.cost, 1, 5)
	if not _units_by_tier.has(tier):
		_units_by_tier[tier] = []
	_units_by_tier[tier].append(stats)

	for orig in stats.origins:
		if not _units_by_origin.has(orig):
			_units_by_origin[orig] = []
		_units_by_origin[orig].append(stats)

	var role := stats.get_combat_role()
	if not role.is_empty():
		if not _units_by_role.has(role):
			_units_by_role[role] = []
		_units_by_role[role].append(stats)

func get_unit(unit_id: String) -> UnitStats:
	ensure_loaded()
	return _units_cache.get(unit_id, null)

func get_all_units() -> Dictionary:
	ensure_loaded()
	return _units_cache

func get_units_by_tier(tier: int) -> Array[UnitStats]:
	ensure_loaded()
	var arr: Array = _units_by_tier.get(tier, [])
	var res: Array[UnitStats] = []
	for item in arr:
		res.append(item as UnitStats)
	return res

func get_units_by_origin(origin: String) -> Array[UnitStats]:
	ensure_loaded()
	var arr: Array = _units_by_origin.get(origin, [])
	var res: Array[UnitStats] = []
	for item in arr:
		res.append(item as UnitStats)
	return res

func get_units_by_role(role: String) -> Array[UnitStats]:
	ensure_loaded()
	var arr: Array = _units_by_role.get(role, [])
	var res: Array[UnitStats] = []
	for item in arr:
		res.append(item as UnitStats)
	return res

func get_random_unit_by_tier(tier: int, unavailable_ids: Array = []) -> UnitStats:
	var pool := get_units_by_tier(tier)
	if pool.is_empty():
		return null

	if unavailable_ids.is_empty():
		return pool[randi() % pool.size()]

	var available: Array[UnitStats] = []
	for u in pool:
		if not (u.unit_id in unavailable_ids):
			available.append(u)

	if available.is_empty():
		return pool[randi() % pool.size()]

	return available[randi() % available.size()]
