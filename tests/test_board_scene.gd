extends SceneTree

func _initialize() -> void:
    call_deferred("_run")

func _run() -> void:
    print("=== TESTE DO TABULEIRO COM CENARIO 3D ===")
    var board_scene := load("res://Scenes/Board/board.tscn") as PackedScene
    if not board_scene:
        push_error("ERRO: board.tscn nao encontrado")
        quit(1)
        return

    var board_instance := board_scene.instantiate() as Board3D
    root.add_child(board_instance)

    await process_frame
    await process_frame

    print("Tabuleiro instanciado com sucesso!")
    print("Filhos do tabuleiro:")
    for child in board_instance.get_children():
        print(" -> ", child.name, " (", child.get_class(), ")")

    assert(board_instance.environment_instance != null, "environment_instance deve existir!")
    print("✓ Cenario 3D instanciado: ", board_instance.environment_instance.name)

    var gen_board: Node3D = board_instance.get_node_or_null("GeneratedBoard")
    assert(gen_board != null, "GeneratedBoard deve existir!")
    print("✓ GeneratedBoard presente com ", gen_board.get_child_count(), " filhos")

    var collision: StaticBody3D = gen_board.get_node_or_null("BoardCollision")
    assert(collision != null, "BoardCollision deve existir!")
    print("✓ BoardCollision ativa na camada: ", collision.collision_layer)

    var floor_mesh: MeshInstance3D = gen_board.get_node_or_null("BoardMesh")
    assert(floor_mesh != null, "BoardMesh deve existir!")
    assert(floor_mesh.visible == false, "BoardMesh padrao deve estar oculto para exibir o cenario 3D!")
    print("✓ BoardMesh padrao ocultado com sucesso (cenario 3D ativo)")

    board_instance.queue_free()
    print("=== TESTE CONCLUIDO COM 100% DE SUCESSO! ===")
    quit(0)
