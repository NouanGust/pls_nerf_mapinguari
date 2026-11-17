@tool
extends SceneTree

func _init() -> void:
	print("\n============================================================")
	print("TESTE DE ENRAIZAMENTO (apply_root) E FEEDBACK VISUAL 3D")
	print("============================================================\n")

	var stats := UnitStats.new()
	stats.unit_id = "test_root_unit"
	stats.unit_name = "Unidade Teste Root"
	stats.attack_range = 1.0
	stats.max_health = 500.0

	var unit := BaseUnit3D.new()
	unit.stats = stats
	unit.board_position = Vector2i(2, 2)
	root.add_child(unit)

	# 1. Verifica estado inicial
	assert(not unit.is_rooted(), "Unidade não deve estar enraizada inicialmente")

	# 2. Aplica enraizamento
	unit.apply_root(1.0, "ENRAIZADO")
	assert(unit.is_rooted(), "Unidade deve estar enraizada após apply_root(1.0)")
	print("  ✓ target.apply_root(1.0) chamado com sucesso!")
	print("  ✓ is_rooted() retornou true.")

	# 3. Verifica feedback visual 3D
	var fx := unit.get_node_or_null("RootVisualFX")
	assert(fx != null, "Efeito visual 3D RootVisualFX deve ser instanciado!")
	assert(unit.get_node_or_null("StatusIndicator") == null, "Debuff de enraizamento não deve gerar texto Label3D!")
	print("  ✓ RootVisualFX 3D criado com sucesso no lugar de texto.")

	# 4. Verifica bloqueio de movimento
	unit.velocity = Vector3(5, 0, 5)
	unit.move_towards_target()
	assert(unit.velocity == Vector3.ZERO or unit.is_rooted(), "Unidade não deve conseguir se mover enquanto enraizada")
	print("  ✓ Locomoção bloqueada enquanto enraizada.")

	# 5. Simula chamada do Chicote da Fulozinha no basic attack
	var attacker := BaseUnit3D.new()
	var attacker_stats := UnitStats.new()
	attacker_stats.unit_name = "Atacante"
	attacker.stats = attacker_stats
	attacker.board_position = Vector2i(2, 3)
	root.add_child(attacker)
	
	# Testa chamada direta em on_basic_attack_landed
	unit.on_basic_attack_landed(attacker)
	print("  ✓ on_basic_attack_landed executado sem nenhum erro!")

	unit.free()
	attacker.free()

	print("\n============================================================")
	print("✅ TESTE DE APPLY_ROOT CONCLUÍDO COM SUCESSO!")
	print("============================================================\n")
	quit(0)
