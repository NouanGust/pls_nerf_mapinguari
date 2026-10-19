extends RefCounted

const Regions = preload("res://Scripts/Systems/region_rosters.gd")
const DIRECTORY := "user://campaigns"
const VERSION := 1

static func _path(region_id: String) -> String:
	return DIRECTORY.path_join(region_id + ".json")

static func read_slot(region_id: String) -> Dictionary:
	if not Regions.REGIONS.has(region_id):
		return {"error": "Região desconhecida."}
	var path := _path(region_id)
	var found := false
	for candidate in [path, path + ".bak"]:
		if not FileAccess.file_exists(candidate):
			continue
		found = true
		var file := FileAccess.open(candidate, FileAccess.READ)
		if not file:
			continue
		var parsed: Variant = JSON.parse_string(file.get_as_text())
		if parsed is Dictionary and int(parsed.get("version", 0)) == VERSION and parsed.get("region", "") == region_id:
			if parsed.get("state", "") in ["active", "won", "lost"] and valid_run(parsed.get("run")):
				return parsed
	return {"error": "Não foi possível ler esta campanha. O arquivo foi preservado."} if found else {}

static func write_slot(region_id: String, run: Dictionary, state: String = "active") -> Error:
	if not Regions.REGIONS.has(region_id) or state not in ["active", "won", "lost"] or not valid_run(run):
		return ERR_INVALID_PARAMETER
	var previous := read_slot(region_id)
	if previous.has("error"):
		return ERR_FILE_CORRUPT
	var document := {
		"version": VERSION, "region": region_id, "state": state,
		"completed": bool(previous.get("completed", false)) or state == "won",
		"updated_at": Time.get_unix_time_from_system(), "run": run,
	}
	var directory_error := DirAccess.make_dir_recursive_absolute(DIRECTORY)
	if directory_error != OK:
		return directory_error
	var path := _path(region_id)
	var temporary := path + ".tmp"
	var file := FileAccess.open(temporary, FileAccess.WRITE)
	if not file:
		return FileAccess.get_open_error()
	file.store_string(JSON.stringify(document, "\t"))
	file.flush()
	var write_error := file.get_error()
	file.close()
	if write_error != OK:
		return write_error
	# Mantém a última versão legível antes de trocar o arquivo principal.
	if FileAccess.file_exists(path):
		var current: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
		if current is Dictionary and int(current.get("version", 0)) == VERSION and current.get("region", "") == region_id and current.get("state", "") in ["active", "won", "lost"] and valid_run(current.get("run")):
			var backup_error := DirAccess.copy_absolute(path, path + ".bak")
			if backup_error != OK:
				return backup_error
	var rename_error := DirAccess.rename_absolute(temporary, path)
	return rename_error

static func valid_run(value: Variant) -> bool:
	if not value is Dictionary:
		return false
	for key in ["gold", "health", "level", "xp", "enemy_level", "enemy_xp", "round", "win_streak", "loss_streak"]:
		if not value.get(key) is int and not value.get(key) is float:
			return false
		if not is_finite(float(value[key])) or float(value[key]) != floorf(float(value[key])):
			return false
	if int(value["level"]) < 1 or int(value["level"]) > 9 or int(value["enemy_level"]) < 1 or int(value["enemy_level"]) > 9:
		return false
	if int(value["round"]) < 1 or int(value["health"]) < -10 or int(value["health"]) > 100:
		return false
	for key in ["gold", "xp", "enemy_xp", "win_streak", "loss_streak"]:
		if int(value[key]) < 0:
			return false
	if value.get("phase", "") not in ["prep", "combat", "resolved"] or not value.get("locked") is bool:
		return false
	for key in ["bench", "field", "shop"]:
		if not value.get(key) is Array:
			return false
	if value["bench"].size() > 9 or value["field"].size() > int(value["level"]) or value["shop"].size() != 5:
		return false
	var positions: Array[Vector2i] = []
	for zone in ["bench", "field"]:
		for unit in value[zone]:
			if not unit is Dictionary or not _valid_unit_id(unit.get("id")):
				return false
			for key in ["stars", "invested"]:
				if not unit.get(key) is int and not unit.get(key) is float:
					return false
			if int(unit["stars"]) < 1 or int(unit["stars"]) > 4 or int(unit["invested"]) < 0:
				return false
			if zone == "field":
				if not unit.get("cell") is Array or unit["cell"].size() != 2:
					return false
				for coordinate in unit["cell"]:
					if not coordinate is int and not coordinate is float:
						return false
				var cell := Vector2i(int(unit["cell"][0]), int(unit["cell"][1]))
				if cell.x < 0 or cell.x >= 7 or cell.y < 4 or cell.y >= 8 or cell in positions:
					return false
				positions.append(cell)
	for id in value["shop"]:
		if not id is String or (id != "" and not _valid_unit_id(id)):
			return false
	return true

static func _valid_unit_id(value: Variant) -> bool:
	return value is String and value.is_valid_identifier() and ResourceLoader.exists("res://resources/units/%s.tres" % value)
