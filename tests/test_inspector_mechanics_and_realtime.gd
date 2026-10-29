extends SceneTree

const BattleClock = preload("res://Scripts/Systems/battle_clock.gd")

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	print("\n==================================================")
	print("TESTE: INSPETOR REAL-TIME, HABILIDADES E TOOLTIPS")
	print("==================================================")

	if not root.has_node("BattleClock"):
		var clock = BattleClock.new()
		clock.name = "BattleClock"
		root.add_child(clock)

	# 1. Carregar e verificar descrições mecânicas de todas as 45 unidades
	print("\n[1] Verificando get_mechanics_description() para todas as unidades:")
	var all_units := UnitSpawner.load_all_units()
	assert(all_units.size() == 66, "Devem existir 66 unidades")
	
	for unit_id in all_units.keys():
		var stats: UnitStats = all_units[unit_id]
		var desc1 := stats.get_mechanics_description(1)
		var desc2 := stats.get_mechanics_description(2)
		var desc3 := stats.get_mechanics_description(3)
		assert(desc1.length() > 10, "Unidade %s deve ter descrição de habilidade válida nível 1" % unit_id)
		assert(desc2.length() > 10, "Unidade %s deve ter descrição de habilidade válida nível 2" % unit_id)
		assert(desc3.length() > 10, "Unidade %s deve ter descrição de habilidade válida nível 3" % unit_id)
		# Garantir que não contém emojis/símbolos não suportados na web
		for c in desc1:
			var code := c.unicode_at(0)
			assert(code < 0x2500 or code > 0x1F9FF, "Caractere emoji detectado na descrição mecânica de %s: %s" % [unit_id, c])
	print("  ✓ Todas as 45 unidades possuem descrições de habilidades puramente mecânicas e sem emojis!")

	# 2. Instanciar main.tscn e verificar inspetor
	print("\n[2] Instanciando cena principal para testar inspetor:")
	var main_scene := load("res://Scenes/Main/main.tscn") as PackedScene
	var main = main_scene.instantiate()
	root.add_child(main)
	current_scene = main
	await process_frame
	await process_frame

	var capivara_stats: UnitStats = all_units["capivara"]
	var test_unit: BaseUnit3D = UnitSpawner.spawn_unit_from_stats(capivara_stats, 1, 0)
	main.add_child(test_unit)
	test_unit.current_health = 300.0
	test_unit.current_shield = 150.0

	# Abrir inspetor
	main.show_unit_inspector(test_unit)
	var panel := main.ui.get_node_or_null("Control/RightBar") as Control
	assert(panel != null, "Painel RightBar deve existir")

	# 3. Verificar que tooltip nativo foi desativado no botão de habilidade
	print("\n[3] Verificando tooltip nativo desativado e floating card:")
	var ability_btn := panel.find_child("AbilityButton", true, false) as Button
	assert(ability_btn != null, "AbilityButton deve existir")
	assert(ability_btn.tooltip_text == "", "Tooltip nativo do Godot deve estar vazio para evitar sobreposição!")
	print("  ✓ Tooltip nativo do Godot está desativado (tooltip_text vazio)")

	# 4. Verificar barra de escudo
	print("\n[4] Verificando barra de escudo em tempo real:")
	var shield_bar := panel.find_child("InspectorShieldBar", true, false) as ProgressBar
	assert(shield_bar != null, "InspectorShieldBar deve existir")
	assert(shield_bar.visible == true, "InspectorShieldBar deve estar visível quando unit tem escudo")
	assert(shield_bar.value == 150.0, "Valor do escudo deve ser 150")
	var hp_lbl := panel.find_child("HpTextLabel", true, false) as Label
	assert(hp_lbl != null and hp_lbl.text.contains("(+150)"), "Label de vida deve indicar (+150) de escudo")
	print("  ✓ Barra de escudo e label 'HP (+escudo)' validados em tempo real!")

	# 5. Testar update em tempo real através do _process
	print("\n[5] Simulando alteração de atributos em tempo real (escudo zera, vida cai, ganha armadura):")
	test_unit.current_shield = 0.0
	test_unit.current_health = 180.0
	test_unit.synergy_bonuses["bonus_armor"] = 50.0
	main._process(0.016)

	assert(shield_bar.visible == false, "InspectorShieldBar deve ficar invisível quando escudo zera")
	assert(hp_lbl.text.begins_with("180 /"), "Label de vida deve refletir 180 / max")

	var stats_grid := panel.find_child("TFT_StatsGrid", true, false) as GridContainer
	assert(stats_grid != null, "TFT_StatsGrid deve existir")
	var slot_arm := stats_grid.find_child("Slot_arm", false, false) as Control
	var val_arm := slot_arm.find_child("ValLabel", true, false) as Label
	var expected_arm := int(capivara_stats.armor + 50.0)
	assert(val_arm.text == str(expected_arm), "Armadura em tempo real deve refletir bônus: %s != %s" % [val_arm.text, str(expected_arm)])
	print("  ✓ Atributos e escudo atualizados em tempo real perfeitamente!")

	print("\n==================================================")
	print("TODOS OS TESTES DE INSPETOR E MECÂNICAS PASSARAM!")
	print("==================================================\n")
	quit(0)
