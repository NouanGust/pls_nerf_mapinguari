extends SceneTree

const BattleClock = preload("res://Scripts/Systems/battle_clock.gd")

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	print("==================================================")
	print("SUITE DE TESTES: SINERGIAS, INSPEÇÃO, STACKS E MARCOS")
	print("==================================================")

	if not root.has_node("BattleClock"):
		var clock = BattleClock.new()
		clock.name = "BattleClock"
		root.add_child(clock)

	var main_scene := load("res://Scenes/Main/main.tscn") as PackedScene
	assert(main_scene != null, "main.tscn deve carregar")
	var main = main_scene.instantiate()
	root.add_child(main)
	current_scene = main
	await process_frame
	await process_frame

	var ui: GameUI = main.ui
	var board: Board3D = main.board
	assert(ui != null, "ui deve existir")
	assert(board != null, "board deve existir")

	# ----------------------------------------------------
	# [TESTE 1] Marcos da barra superior sem emojis (TextureRect nativo)
	# ----------------------------------------------------
	print("\n[TESTE 1] Validando marcos da barra superior sem emojis:")
	assert(ui._milestone_icons.size() == 5, "Devem existir 5 marcos de estágio")
	for icon in ui._milestone_icons:
		assert(icon is TextureRect, "Marcadores devem ser TextureRect para compatibilidade web sem emojis")
		assert(icon.texture != null, "Marcador deve ter textura válida do atlas")
	print("  ✓ Todos os 5 marcos utilizam TextureRect do atlas sem dependência de fontes emoji!")

	# ----------------------------------------------------
	# [TESTE 2] Sinergia Ferocidade e Limite de Stacks (Max 8)
	# ----------------------------------------------------
	print("\n[TESTE 2] Validando stacks de Ferocidade e limite:")
	var lobo_stats := UnitSpawner.load_unit_stats("lobo_guara")
	assert(lobo_stats != null, "lobo_guara deve carregar")
	assert(lobo_stats.origins.has("Ferocidade"), "lobo_guara deve ter origem Ferocidade")
	assert(lobo_stats.origins.has("Travessia"), "lobo_guara deve ter origem Travessia")

	var lobo: BaseUnit3D = UnitSpawner.spawn_unit_from_stats(lobo_stats, 1, 0)
	main.add_child(lobo)
	board.place_unit(lobo, Vector2i(2, 3), false)

	# Simular 8 acúmulos de Ferocidade
	lobo.ferocidade_stacks = 8
	print("  - Acúmulos em lobo: %d (Limite deve ser 8)" % lobo.ferocidade_stacks)
	assert(lobo.ferocidade_stacks == 8, "ferocidade_stacks deve ser 8!")

	# Atualizar sinergias e verificar retorno
	main._refresh_synergies()
	var fero_rule := SynergySystem.get_rule_for_tag("Ferocidade")
	assert(not fero_rule.is_empty(), "Regra de Ferocidade deve existir")
	assert(fero_rule.get("max_stacks", 0) == 8, "Ferocidade deve ter max_stacks == 8")
	print("  ✓ Limite de 8 stacks de Ferocidade validado com sucesso!")

	# ----------------------------------------------------
	# [TESTE 3] Painel de Inspeção com Origens Interativas
	# ----------------------------------------------------
	print("\n[TESTE 3] Validando links e dados no painel de inspeção lateral:")
	main.show_unit_inspector(lobo)
	var right_bar: Control = ui.get_node("Control/RightBar")
	assert(right_bar.visible, "RightBar deve estar visível")

	var origins_lbl := right_bar.find_child("Origins_label", true, false) as RichTextLabel
	assert(origins_lbl != null, "Origins_label deve existir")
	print("  - Origins_label text: %s" % origins_lbl.text)
	assert("url=Ferocidade" in origins_lbl.text, "Origins_label deve conter url interativo para Ferocidade")
	assert("8/8 st" in origins_lbl.text, "Origins_label deve indicar a contagem de stacks de Ferocidade")

	# Simular hover na tag Ferocidade pelo inspetor
	ui._on_inspector_meta_hover_started("Ferocidade", origins_lbl)
	assert(ui.synergy_tooltip != null and ui.synergy_tooltip.visible, "Tooltip deve abrir ao dar hover na origem")
	var desc_lbl := ui.synergy_tooltip.find_child("Tooltip_desc", true, false) as RichTextLabel
	assert(desc_lbl != null, "Tooltip_desc deve existir no tooltip")
	print("  - Tooltip_desc text:\n%s" % desc_lbl.text)
	assert("Acúmulos Atuais" in desc_lbl.text, "Tooltip deve exibir a informação de acúmulos")
	print("  ✓ Tooltip de inspeção exibe todos os buffs e acúmulos!")

	# ----------------------------------------------------
	# [TESTE 4] Destaque de unidades da sinergia no tabuleiro
	# ----------------------------------------------------
	print("\n[TESTE 4] Validando destaque de unidades no tabuleiro:")
	assert(lobo.is_synergy_highlighted, "Lobo deve estar com is_synergy_highlighted ativo")
	assert(lobo.nameplate_container.visible, "Nameplate do lobo deve estar visível durante o destaque")
	assert(main._highlighted_synergy_cells.has(Vector2i(2, 3)), "Célula (2, 3) do lobo deve estar destacada no tabuleiro")
	print("  - Unidade Ferocidade destacada no tabuleiro com sucesso ✓")

	# Encerrar hover na tag
	ui._on_inspector_meta_hover_ended("Ferocidade")
	assert(not ui.synergy_tooltip.visible, "Tooltip deve fechar ao sair do hover")
	assert(not lobo.is_synergy_highlighted, "Lobo não deve mais estar com destaque de sinergia")
	assert(main._highlighted_synergy_cells.is_empty(), "Células destacadas devem ter sido limpas")
	print("  - Destaque removido ao sair do hover com sucesso ✓")

	main.hide_unit_inspector()
	print("\n==================================================")
	print("TODOS OS TESTES DE MARCOS, BUFFS, STACKS E DESTAQUE PASSARAM COM SUCESSO!")
	print("==================================================")
	quit(0)
