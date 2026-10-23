extends SceneTree

const Store = preload("res://Scripts/Systems/campaign_store.gd")
const Regions = preload("res://Scripts/Systems/region_rosters.gd")

var frame := 0
var main_menu_instance: Node
var main_game_instance: Node

func _process(_delta: float) -> bool:
	frame += 1
	if frame == 1:
		print("\n=== TESTE 1: BOTÃO DE REINICIAR REGIÃO NO MAIN MENU ===")
		var menu_scene = load("res://Scenes/UI/Menu.tscn")
		main_menu_instance = menu_scene.instantiate()
		root.add_child(main_menu_instance)
		return false
		
	if frame == 2:
		# 1. Simular uma campanha salva ativa na região 'cerrado'
		var test_region := "cerrado"
		var sample_run := {
			"gold": 10, "health": 85, "level": 3, "xp": 4, "enemy_level": 3, "enemy_xp": 2,
			"round": 4, "win_streak": 2, "loss_streak": 0, "phase": "prep", "locked": false,
			"bench": [], "field": [], "shop": ["capivara", "cumacanga", "guarana", "mandacaru", "pequi"]
		}
		var write_err := Store.write_slot(test_region, sample_run, "active")
		assert(write_err == OK, "Gravação do slot de teste deve ter sucesso")
		
		# Navega para a região
		main_menu_instance._show_regions()
		var idx = main_menu_instance.REGION_ORDER.find(test_region)
		assert(idx >= 0, "Região deve existir na lista")
		main_menu_instance._selected_index = idx
		main_menu_instance._select_region(0)
		
		var reset_btn: Button = main_menu_instance._reset_region_button
		var enter_btn: Button = main_menu_instance._enter_button
		assert(reset_btn != null, "Botão de reiniciar região deve existir")
		assert(not reset_btn.disabled, "Botão deve estar habilitado para região com campanha ativa")
		assert("Continuar" in enter_btn.text, "Botão de entrar deve mostrar Continuar para campanha ativa")
		print("Botão de reiniciar presente e ativo para '%s': %s" % [test_region, reset_btn.text])
		
		# Primeiro clique: deve pedir confirmação de segurança
		main_menu_instance._on_restart_region_pressed()
		assert(main_menu_instance._pending_restart_confirm, "Deve entrar em modo de confirmação")
		assert("Confirmar" in reset_btn.text, "Texto deve mudar para pedir confirmação")
		print("Primeiro clique solicitou confirmação: '%s'" % reset_btn.text)
		
		# Segundo clique: confirmação do reinício
		main_menu_instance._on_restart_region_pressed()
		assert(not main_menu_instance._pending_restart_confirm, "Modo de confirmação deve ser limpo")
		
		# Verifica se o slot foi apagado
		var slot_after := Store.read_slot(test_region)
		assert(slot_after.is_empty(), "O slot da região deve estar vazio após o reinício")
		assert("Iniciar campanha" in enter_btn.text, "Botão de entrar deve voltar para Iniciar campanha")
		assert(reset_btn.disabled, "Botão de reiniciar deve ficar desabilitado para região sem progresso")
		print("Segundo clique reiniciou o slot com sucesso! Estado atual: %s" % enter_btn.text)
		
		main_menu_instance.queue_free()
		return false

	if frame == 3:
		print("\n=== TESTE 2: NAMEPLATE 3D SEM CORTE DE TEXTO (HOVER) ===")
		var spawner = load("res://Scripts/Systems/unit_spawner.gd").new()
		var anhanga = spawner.spawn_unit("anhanga", 3) # Anhangá 3 estrelas (alto HP como no screenshot)
		root.add_child(anhanga)
		
		assert(anhanga.ui_viewport != null, "SubViewport da unidade deve existir")
		assert(anhanga.ui_viewport.size.x >= 900, "Largura do SubViewport deve ser >= 900 para evitar corte de texto")
		print("Tamanho do SubViewport 3D: ", anhanga.ui_viewport.size)
		
		# Simula HP alto e escudo
		anhanga.current_health = 1710.0
		anhanga.current_shield = 250.0
		anhanga.update_stats_display()
		
		print("Texto do HPLabel: ", anhanga.hp_label.text)
		assert("1710" in anhanga.hp_label.text, "HPLabel deve conter a vida atual")
		assert("ESC" in anhanga.hp_label.text or "250" in anhanga.hp_label.text, "HPLabel deve exibir o escudo ativo")
		
		# Test hover visibility
		anhanga.set_hovered(true)
		assert(anhanga.nameplate_container.visible, "Nameplate deve ficar visível no hover")
		anhanga.set_hovered(false)
		assert(not anhanga.nameplate_container.visible, "Nameplate deve ocultar ao sair do hover")
		print("Comportamento de hover e formatação do nameplate 3D OK!")
		
		anhanga.queue_free()
		return false

	if frame == 4:
		print("\n=== TESTE 3: TOOLTIP DA LOJA COM DEFESA E LARGURA EXPANDIDA ===")
		var main_scene = load("res://Scenes/Main/main.tscn")
		main_game_instance = main_scene.instantiate()
		root.add_child(main_game_instance)
		
		var shop_ui = main_game_instance.ui.shop
		assert(shop_ui != null, "ShopUI deve existir")
		var cumacanga_res = load("res://resources/units/cumacanga.tres")
		shop_ui.update_tooltip_labels(cumacanga_res)
		
		var v_box = shop_ui.stats_tooltip.get_node("VBoxContainer")
		var type_lbl = v_box.get_node("Tooltip_type")
		print("Texto da tooltip da loja:\n", type_lbl.text)
		assert("Defesa:" in type_lbl.text, "Tooltip da loja deve exibir informações de Defesa")
		assert("Arm" in type_lbl.text and "RM" in type_lbl.text, "Tooltip da loja deve exibir Armadura e RM")
		print("Tooltip da loja OK!")
		
		print("\n=== TODOS OS 3 TESTES PASSARAM COM TOTAL SUCESSO! ===")
		quit(0)
		return true

	return false
