class_name UnitSpawner
extends Node

## ============================================
## SISTEMA DE SPAWN DE UNIDADES 3D
## ============================================

const BASE_UNIT_3D_SCENE := preload("res://Scenes/Units/base_unit_3d.tscn")

## Cache de unidades carregadas
static var _units_cache: Dictionary = {}
static var _cache_loaded := false

## ============================================
## LOADING SYSTEM
## ============================================

## Carrega todas as unidades disponíveis do diretório
static func load_all_units() -> Dictionary:
	if _cache_loaded and not _units_cache.is_empty():
		return _units_cache
	
	_units_cache.clear()
	var units_path := "res://resources/units/"
	
	if not DirAccess.dir_exists_absolute(units_path):
		push_error("Units directory not found: " + units_path)
		return {}
	
	var dir := DirAccess.open(units_path)
	if not dir:
		push_error("Failed to open units directory")
		return {}
	
	dir.list_dir_begin()
	var file_name := dir.get_next()
	var loaded_count := 0
	
	while file_name != "":
		if file_name.ends_with(".tres"):
			var unit_stats: UnitStats = ResourceLoader.load(units_path + file_name, "", ResourceLoader.CACHE_MODE_REPLACE)
			if unit_stats and unit_stats.is_valid():
				_units_cache[unit_stats.unit_id] = unit_stats
				loaded_count += 1
			else:
				push_warning("Failed to load or invalid unit: " + file_name)
		
		file_name = dir.get_next()
	
	dir.list_dir_end()
	_cache_loaded = true
	
	print("UnitSpawner: Loaded %d units" % loaded_count)
	return _units_cache

## Carrega uma unidade específica
static func load_unit_stats(unit_id: String) -> UnitStats:
	# Tentar do cache primeiro
	if _units_cache.has(unit_id):
		return _units_cache[unit_id]
	
	# Tentar carregar do disco
	var path := "res://resources/units/%s.tres" % unit_id
	if ResourceLoader.exists(path):
		var unit_stats: UnitStats = ResourceLoader.load(path, "", ResourceLoader.CACHE_MODE_REPLACE)
		if unit_stats and unit_stats.is_valid():
			_units_cache[unit_id] = unit_stats
			return unit_stats
	
	push_error("Unit not found: " + unit_id)
	return null

## ============================================
## SPAWN FUNCTIONS
## ============================================

## Spawna uma unidade 3D por ID
static func spawn_unit(unit_id: String, star_level: int = 1, team: int = 0) -> BaseUnit3D:
	var unit_stats := load_unit_stats(unit_id)
	if not unit_stats:
		return null
	
	return spawn_unit_from_stats(unit_stats, star_level, team)

## Spawna uma unidade 3D a partir de UnitStats
static func spawn_unit_from_stats(unit_stats: UnitStats, star_level: int = 1, team: int = 0) -> BaseUnit3D:
	if not unit_stats or not unit_stats.is_valid():
		push_error("Invalid unit stats provided")
		return null
	
	# Validar star level
	star_level = clampi(star_level, 1, 3)
	
	# Instanciar cena base ou cena customizada
	var unit: BaseUnit3D
	
	if unit_stats.model_scene:
		# Usar modelo customizado se disponível
		unit = unit_stats.model_scene.instantiate() as BaseUnit3D
	else:
		# Usar modelo base
		unit = BASE_UNIT_3D_SCENE.instantiate() as BaseUnit3D
	
	if not unit:
		push_error("Failed to instantiate unit: " + unit_stats.unit_id)
		return null
	
	# Configurar unidade
	unit.team = team
	unit.name = "%s_%d★_Team%d" % [unit_stats.unit_id, star_level, team]
	unit.initialize(unit_stats, star_level)
	
	return unit

## ============================================
## BULK SPAWN
## ============================================

## Spawna múltiplas unidades de uma vez
static func spawn_multiple_units(unit_configs: Array[Dictionary]) -> Array[BaseUnit3D]:
	var units: Array[BaseUnit3D] = []
	
	for config in unit_configs:
		var unit_id: String = config.get("unit_id", "")
		var stars: int = config.get("stars", 1)
		var team: int = config.get("team", 0)
		
		var unit := spawn_unit(unit_id, stars, team)
		if unit:
			units.append(unit)
	
	return units

## ============================================
## QUERY FUNCTIONS
## ============================================

## Retorna todas as unidades de um tier específico
static func get_units_by_tier(tier: int) -> Array[UnitStats]:
	if not _cache_loaded:
		load_all_units()
	
	var result: Array[UnitStats] = []
	for unit_stats in _units_cache.values():
		if unit_stats.tier == tier:
			result.append(unit_stats)
	
	return result

## Retorna unidades que possuem uma origem específica
static func get_units_by_origin(origin_name: String) -> Array[UnitStats]:
	if not _cache_loaded:
		load_all_units()
	
	var result: Array[UnitStats] = []
	for unit_stats in _units_cache.values():
		if unit_stats.has_origin(origin_name):
			result.append(unit_stats)
	
	return result

## Retorna unidades que possuem uma classe específica
static func get_units_by_class(classes_name: String) -> Array[UnitStats]:
	if not _cache_loaded:
		load_all_units()
	
	var result: Array[UnitStats] = []
	for unit_stats in _units_cache.values():
		if unit_stats.has_class(classes_name):
			result.append(unit_stats)
	
	return result

## Retorna unidades dentro de um range de custo
static func get_units_by_cost_range(min_cost: int, max_cost: int) -> Array[UnitStats]:
	if not _cache_loaded:
		load_all_units()
	
	var result: Array[UnitStats] = []
	for unit_stats in _units_cache.values():
		if unit_stats.cost >= min_cost and unit_stats.cost <= max_cost:
			result.append(unit_stats)
	
	return result

## ============================================
## RANDOM SPAWNING
## ============================================

## Spawna uma unidade aleatória de um tier
static func spawn_random_unit_by_tier(tier: int, star_level: int = 1, team: int = 0) -> BaseUnit3D:
	var units := get_units_by_tier(tier)
	if units.is_empty():
		push_error("No units found for tier: %d" % tier)
		return null
	
	var random_stats = units.pick_random()
	return spawn_unit_from_stats(random_stats, star_level, team)

## Spawna uma unidade aleatória qualquer
static func spawn_random_unit(star_level: int = 1, team: int = 0) -> BaseUnit3D:
	if not _cache_loaded:
		load_all_units()
	
	if _units_cache.is_empty():
		push_error("No units loaded")
		return null
	
	var random_id = _units_cache.keys().pick_random()
	return spawn_unit(random_id, star_level, team)

## ============================================
## UTILITY FUNCTIONS
## ============================================

## Valida se uma unidade existe
static func unit_exists(unit_id: String) -> bool:
	if _units_cache.has(unit_id):
		return true
	
	return ResourceLoader.exists("res://resources/units/%s.tres" % unit_id)

## Retorna informações de todas as unidades
static func get_all_unit_info() -> Array[Dictionary]:
	if not _cache_loaded:
		load_all_units()
	
	var info: Array[Dictionary] = []
	for unit_stats in _units_cache.values():
		info.append({
			"id": unit_stats.unit_id,
			"name": unit_stats.unit_name,
			"tier": unit_stats.tier,
			"cost": unit_stats.cost,
			#"origins": unit_stats.get_all_origins(),
			#"classes": unit_stats.get_all_classes()
		})
	print(info)
	return info

## Limpa o cache (útil para hot-reload)
static func clear_cache() -> void:
	_units_cache.clear()
	_cache_loaded = false
	print("UnitSpawner: Cache cleared")

## ============================================
## DEBUG
## ============================================

static func print_all_units() -> void:
	if not _cache_loaded:
		load_all_units()
	
	print("\n========== AVAILABLE UNITS ==========")
	for unit_id in _units_cache.keys():
		var unit: UnitStats = _units_cache[unit_id]
		print("  [Tier %d] %s (%s) - %d gold" % [unit.tier, unit.unit_name, unit_id, unit.cost])
	print("=====================================\n")
