extends SceneTree

const ResponsiveLayout = preload("res://Scripts/UI/responsive_layout.gd")

var frame := 0
var game_ui: Node
var main_script: Node

func _process(_delta: float) -> bool:
	frame += 1
	if frame == 1:
		var game_ui_scene = load("res://Scenes/UI/GameUI.tscn")
		game_ui = game_ui_scene.instantiate()
		root.add_child(game_ui)
		return false
		
	if frame == 2:
		# Test helper formatting
		var main_scene = load("res://Scenes/Main/main.tscn")
		var main_instance = main_scene.instantiate()
		root.add_child(main_instance)
		
		# Test inspecting a unit (e.g. Caapora, Alamoa, Mapinguari, Lobo Guará)
		var spawner = load("res://Scripts/Systems/unit_spawner.gd").new()
		var caapora_unit = spawner.spawn_unit("caapora", 1) # 1 star
		root.add_child(caapora_unit)
		
		print("\n--- TESTANDO INSPEÇÃO DE UNIDADE (CAAPORA 1★) ---")
		main_instance.show_unit_inspector(caapora_unit)
		
		var panel: Control = main_instance.ui.get_node("Control/RightBar")
		assert(panel.visible, "RightBar deve estar visível")
		
		var name_lbl = panel.find_child("Name_label", true, false)
		var hp_lbl = panel.find_child("Hp_label", true, false)
		var type_lbl = panel.find_child("Type_label", true, false)
		var def_lbl = panel.find_child("Defense_label", true, false)
		var aff_lbl = panel.find_child("Affinities_label", true, false)
		var bestiary_btn = panel.find_child("BestiaryButton", true, false)
		
		print("Name: ", name_lbl.text)
		print("HP: ", hp_lbl.text)
		print("Type/Power: ", type_lbl.text)
		print("Defense: ", def_lbl.text if def_lbl else "NULL")
		print("Ability: ", aff_lbl.text)
		print("Bestiary Button: ", "OK" if bestiary_btn else "NULL")
		
		assert(name_lbl != null and "Caapora" in name_lbl.text, "Nome deve estar correto")
		assert(hp_lbl != null and "VIDA" in hp_lbl.text, "HP deve estar presente")
		assert(def_lbl != null and "DEFESA" in def_lbl.text, "Defesa deve estar presente")
		assert(aff_lbl != null and "HABILIDADE" in aff_lbl.text, "Habilidade deve estar presente")
		assert(bestiary_btn != null, "Botão do bestiário deve existir no inspetor")
		
		# Test opening the Bestiary Modal from the inspector
		main_instance.ui.open_bestiary_inspected()
		var bestiary = main_instance.ui.bestiary_modal
		assert(bestiary != null and bestiary.visible, "Bestiário deve estar visível após acionar o botão")
		assert("CAAPORA" in bestiary._title_label.text, "Título do bestiário deve conter CAAPORA")
		assert("ESCALONAMENTO POR ESTRELA" in bestiary._stats_lbl.text, "Bestiário deve conter escalonamento por estrela")
		assert("Valores (1★ / 2★ / 3★)" in bestiary._ability_lbl.text, "Bestiário deve conter valores da habilidade por estrela")
		bestiary.close()
		assert(not bestiary.visible, "Bestiário deve fechar ao chamar close()")
		
		# Test multiple units: Alamoa, Capivara, Mapinguari, Quibungo
		var units_to_test = ["alamoa", "capivara", "mapinguari", "quibungo", "cabeca_de_cuia"]
		for uid in units_to_test:
			var test_unit = spawner.spawn_unit(uid, 2)
			root.add_child(test_unit)
			main_instance.show_unit_inspector(test_unit)
			print("\n--- TESTANDO: %s (2★) ---" % uid.to_upper())
			print("Ability text (simplificada):\n", aff_lbl.text)
			print("Defense text:\n", def_lbl.text)
			
			# Test Bestiary details for this unit
			main_instance.ui.open_bestiary_inspected()
			assert(bestiary.visible, "Bestiário deve abrir para %s" % uid)
			assert("Valores (1★ / 2★ / 3★)" in bestiary._ability_lbl.text, "Bestiário de %s deve ter tabela por estrelas" % uid)
			bestiary.close()
		
		print("\nTODOS OS CASOS DE TESTE DO INSPETOR E BESTIÁRIO PASSARAM!")
		quit(0)
		return true
		
	return false
