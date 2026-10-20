extends SceneTree

func _initialize() -> void:
    call_deferred("_run")

func _run() -> void:
    var log_file := FileAccess.open("res://tests/test_board_model.log", FileAccess.WRITE)
    if log_file: log_file.store_line("--- INICIANDO TESTE ---")
    var path := "res://Assets/Models/Board/board_arena_blocking.gltf"
    var scene := load(path) as PackedScene
    if not scene:
        if log_file: log_file.store_line("ERRO: Falha ao carregar " + path)
        quit(1)
        return

    var instance := scene.instantiate()
    if not instance:
        if log_file: log_file.store_line("ERRO: Falha ao instanciar modelo")
        quit(1)
        return

    if log_file:
        log_file.store_line("SUCESSO: Modelo instanciado com sucesso!")
        log_file.store_line("Nome da raiz: " + instance.name)
        log_file.store_line("Contagem de filhos diretos: " + str(instance.get_child_count()))
        for child in instance.get_children():
            log_file.store_line(" -> " + child.name + " (" + child.get_class() + ") com " + str(child.get_child_count()) + " nos")
        log_file.store_line("--- TESTE FINALIZADO COM SUCESSO ---")
        log_file.close()
    
    instance.queue_free()
    quit(0)
