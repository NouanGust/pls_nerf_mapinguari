extends SceneTree

## Carrega todos os scripts do projeto e falha se algum não compilar.

func _initialize() -> void:
	call_deferred("_run")

func _collect(dir_path: String, out: Array) -> void:
	var dir := DirAccess.open(dir_path)
	if not dir:
		return
	dir.list_dir_begin()
	var entry := dir.get_next()
	while entry != "":
		var full := dir_path.path_join(entry)
		if dir.current_is_dir():
			if not entry.begins_with("."):
				_collect(full, out)
		elif entry.ends_with(".gd"):
			out.append(full)
		entry = dir.get_next()

func _run() -> void:
	var files: Array = []
	_collect("res://Scripts", files)
	var failed: Array = []
	for path in files:
		var script := load(path) as GDScript
		if not script or not script.can_instantiate():
			failed.append(path)
	print("Scripts verificados: %d" % files.size())
	if failed.is_empty():
		print("COMPILE OK")
		quit(0)
	else:
		print("FALHA NA COMPILACAO: ", failed)
		quit(1)
