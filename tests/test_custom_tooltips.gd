extends SceneTree

const UIStyle = preload("res://Scripts/UI/ui_style.gd")

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	print("==================================================")
	print("SUITE DE TESTES: TOOLTIPS ESTILIZADOS E REMOÇÃO DOS PADRÕES")
	print("==================================================")

	# [TESTE 1] Verificar remoção do tooltip padrão nos UnitCards da loja
	print("\n[TESTE 1] Verificando UnitCard da loja:")
	var unit_card_scene := load("res://Scenes/UI/unit_card.tscn") as PackedScene
	assert(unit_card_scene != null, "unit_card.tscn deve existir")
	var card = unit_card_scene.instantiate()
	root.add_child(card)
	await process_frame

	var capivara_stats := UnitSpawner.load_unit_stats("capivara")
	assert(capivara_stats != null, "stats da capivara devem carregar")
	card.set_unit(capivara_stats)

	print("  - tooltip_text após set_unit: '%s'" % card.tooltip_text)
	assert(card.tooltip_text == "", "UnitCard NÃO deve ter tooltip_text nativo do Godot")

	card.set_purchase_upgrade(2)
	print("  - tooltip_text após set_purchase_upgrade: '%s'" % card.tooltip_text)
	assert(card.tooltip_text == "", "UnitCard NÃO deve reativar tooltip_text nativo ao evoluir")
	print("  ✓ Tooltip nativo padrão removido com sucesso dos UnitCards!")

	# [TESTE 2] Verificar instanciação de GameUI e existência do SynergyTooltip
	print("\n[TESTE 2] Instanciando GameUI.tscn:")
	var game_ui_scene := load("res://Scenes/UI/GameUI.tscn") as PackedScene
	assert(game_ui_scene != null, "GameUI.tscn deve carregar")
	var game_ui = game_ui_scene.instantiate()
	root.add_child(game_ui)
	await process_frame
	print("  ✓ GameUI instanciado com sucesso")

	var syn_tooltip := game_ui.get_node_or_null("Control/SynergyTooltip") as PanelContainer
	assert(syn_tooltip != null, "Control/SynergyTooltip deve existir na cena")
	assert(syn_tooltip.z_index >= 10, "SynergyTooltip deve ter z_index elevado")
	assert(syn_tooltip.mouse_filter == Control.MOUSE_FILTER_IGNORE, "SynergyTooltip deve ignorar eventos do mouse para não piscar")
	print("  ✓ SynergyTooltip presente e configurado com z_index=%d" % syn_tooltip.z_index)

	# [TESTE 3] Atualizar Sinergias e verificar remoção de tooltip_text nas linhas
	print("\n[TESTE 3] Atualizando sinergias e verificando linhas da lista:")
	var test_synergies = [
		{
			"name": "Amazônico",
			"category": "Origem",
			"count": 3,
			"tier": 1,
			"threshold": 3,
			"thresholds": [3, 6],
			"active": true,
			"description": "+15% de velocidade de ataque para todos os aliados amazônicos.",
			"units": ["Capivara", "Boiúna", "Ararinha-azul"]
		},
		{
			"name": "Guerreiro",
			"category": "Classe",
			"count": 1,
			"tier": 0,
			"threshold": 2,
			"thresholds": [2, 4],
			"active": false,
			"description": "+200 de vida máxima para guerreiros.",
			"units": ["Capivara", "Mapinguari"]
		}
	]
	game_ui.update_synergies(test_synergies)
	await process_frame

	assert(game_ui.spawned_synergy_rows.size() == 2, "Devem ter sido geradas 2 linhas de sinergia")
	for r in game_ui.spawned_synergy_rows:
		print("  - Linha %s tooltip_text: '%s'" % [r.name, r.tooltip_text])
		assert(r.tooltip_text == "", "Linha de sinergia NÃO deve usar tooltip_text padrão do Godot")
		assert(r.mouse_filter == Control.MOUSE_FILTER_STOP, "Linha de sinergia deve capturar eventos de mouse para disparar hover")
	print("  ✓ Tooltip padrão removido de todas as linhas de sinergia!")

	# [TESTE 4] Simular hover na linha de sinergia ativa e validar SynergyTooltip estilizado
	print("\n[TESTE 4] Testando exibição do SynergyTooltip estilizado (Sinergia Ativa):")
	var row_active = game_ui.spawned_synergy_rows[0]
	game_ui._on_synergy_row_hover_started(test_synergies[0], row_active)

	assert(syn_tooltip.visible == true, "SynergyTooltip deve ficar visível ao passar o mouse")
	var title_lbl = syn_tooltip.get_node_or_null("VBoxContainer/Tooltip_title") as RichTextLabel
	var status_lbl = syn_tooltip.get_node_or_null("VBoxContainer/Tooltip_status") as RichTextLabel
	var desc_lbl = syn_tooltip.get_node_or_null("VBoxContainer/Tooltip_desc") as RichTextLabel
	var units_lbl = syn_tooltip.get_node_or_null("VBoxContainer/Tooltip_units") as RichTextLabel

	assert(title_lbl != null and status_lbl != null and desc_lbl != null and units_lbl != null, "Todos os 4 labels de detalhes devem existir")
	print("  - Título: '%s'" % title_lbl.text)
	print("  - Status: '%s'" % status_lbl.text)
	print("  - Efeito: '%s'" % desc_lbl.text)
	print("  - Integrantes: '%s'" % units_lbl.text)

	assert("Amazônico" in title_lbl.text, "Título deve conter 'Amazônico'")
	assert("Origem" in title_lbl.text, "Título deve conter categoria 'Origem'")
	assert("Ativa" in status_lbl.text, "Status deve indicar 'Ativa'")
	assert("3/3" in status_lbl.text, "Status deve indicar contagem '3/3'")
	assert("velocidade de ataque" in desc_lbl.text, "Descrição deve conter o efeito")
	assert("Boiúna" in units_lbl.text, "Lista de unidades deve conter integrantes")
	print("  ✓ SynergyTooltip ativo validado com sucesso!")

	# [TESTE 5] Simular hover na linha de sinergia inativa (faltam peças e marcos)
	print("\n[TESTE 5] Testando exibição do SynergyTooltip estilizado (Sinergia Inativa):")
	var row_inactive = game_ui.spawned_synergy_rows[1]
	game_ui._on_synergy_row_hover_started(test_synergies[1], row_inactive)

	assert("Guerreiro" in title_lbl.text, "Título deve conter 'Guerreiro'")
	assert("Inativa" in status_lbl.text, "Status deve indicar 'Inativa'")
	assert("faltam 1 peça" in status_lbl.text, "Status deve indicar que falta 1 peça")
	assert("Marcos" in status_lbl.text, "Status deve mostrar trilha de marcos")
	print("  ✓ SynergyTooltip inativo validado com sucesso!")

	# [TESTE 6] Fechar tooltip ao sair com o mouse
	print("\n[TESTE 6] Testando saída do mouse (mouse_exited):")
	game_ui._on_synergy_row_hover_ended()
	assert(syn_tooltip.visible == false, "SynergyTooltip deve ser ocultado em mouse_exited")
	print("  ✓ SynergyTooltip ocultado com sucesso!")

	# [TESTE 7] Validar StatsTooltip da loja
	print("\n[TESTE 7] Testando StatsTooltip estilizado da loja:")
	var shop_ui = game_ui.shop
	assert(shop_ui != null, "ShopUI deve existir em GameUI")
	shop_ui.update_tooltip_labels(capivara_stats)
	var stats_tooltip = shop_ui.stats_tooltip
	assert(stats_tooltip != null, "StatsTooltip deve existir")
	var shop_name_lbl = stats_tooltip.get_node_or_null("VBoxContainer/Tooltip_name") as RichTextLabel
	var shop_type_lbl = stats_tooltip.get_node_or_null("VBoxContainer/Tooltip_type") as RichTextLabel
	print("  - StatsTooltip Nome: '%s'" % shop_name_lbl.text)
	print("  - StatsTooltip Tipo/Origem/Classe: '%s'" % shop_type_lbl.text)
	assert("Capivara" in shop_name_lbl.text, "StatsTooltip deve conter o nome")
	assert("Origens" in shop_type_lbl.text or "Origem" in shop_type_lbl.text, "StatsTooltip deve listar origens")
	print("  ✓ StatsTooltip da loja validado com sucesso!")

	print("\n==================================================")
	print("TODOS OS TESTES DE TOOLTIPS PASSARAM COM SUCESSO!")
	print("==================================================")
	quit(0)
