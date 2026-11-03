extends SceneTree

const UnitCatalog = preload("res://Scripts/Systems/unit_catalog.gd")
const UnitInspectorPanel = preload("res://Scripts/UI/unit_inspector_panel.gd")
const BaseUnit3D = preload("res://Scripts/Units/base_unit.gd")
const HealthComponent = preload("res://Scripts/Units/Components/health_component.gd")

func _init() -> void:
	print("--- INICIANDO TESTE: DECAIMENTO DE ESCUDO E VALORES DE HABILIDADE NO INSTRUTOR ---")

	var catalog = UnitCatalog.new()
	catalog.ensure_loaded()

	_test_inspector_ability_info(catalog)
	_test_health_component_shield_decay()
	_test_base_unit_shield_lifecycle(catalog)
	_test_inspector_ui_panel_generation(catalog)

	print("--- TODOS OS TESTES PASSARAM COM SUCESSO! ---")
	quit(0)

func _test_inspector_ability_info(catalog: UnitCatalog) -> void:
	print("Testando extracao e formatacao de valores de habilidade...")

	# 1. Alamoa (Conjurador - Dano Magico)
	var alamoa_stats = catalog.get_unit("alamoa")
	assert(alamoa_stats != null, "Alamoa deve existir no catalogo")
	var alamoa_info = UnitInspectorPanel.get_ability_info(alamoa_stats, null, 1)
	assert(not alamoa_info["lines"].is_empty(), "Alamoa deve ter linhas de valores de habilidade")
	var has_dmg := false
	for line in alamoa_info["lines"]:
		if "Dano:" in line:
			has_dmg = true
			assert("520" in line, "Dano base de Alamoa deve ser 520")
			assert("936" in line, "Dano 2 estrelas deve ser 936")
			assert("1352" in line, "Dano 3 estrelas deve ser 1352")
			assert("(Atual: 520)" in line, "Dano atual em 1 estrela deve ser 520")
	assert(has_dmg, "Linha de dano de Alamoa deve estar presente")

	# 2. Capivara (Tank - Escudo)
	var capivara_stats = catalog.get_unit("capivara")
	assert(capivara_stats != null, "Capivara deve existir no catalogo")
	var capivara_info = UnitInspectorPanel.get_ability_info(capivara_stats, null, 2)
	var has_sh := false
	for line in capivara_info["lines"]:
		if "Escudo:" in line:
			has_sh = true
			assert("180" in line, "Escudo base 1 estrela deve ser 180")
			assert("324" in line, "Escudo 2 estrelas deve ser 324")
			assert("(Atual: 324)" in line, "Em 2 estrelas o atual deve ser 324")
	assert(has_sh, "Linha de escudo da Capivara deve estar presente")

	# 3. Aguape (Suporte - Cura)
	var aguape_stats = catalog.get_unit("aguape")
	assert(aguape_stats != null, "Aguape deve existir no catalogo")
	var aguape_info = UnitInspectorPanel.get_ability_info(aguape_stats, null, 1)
	var has_heal := false
	for line in aguape_info["lines"]:
		if "Cura:" in line:
			has_heal = true
			assert("160" in line, "Cura 1 estrela deve ser 160")
	assert(has_heal, "Linha de cura do Aguape deve estar presente")

	print("OK: Informacoes e escalonamento de habilidades validados!")

func _test_health_component_shield_decay() -> void:
	print("Testando decaimento suave de escudo em HealthComponent...")
	var health_comp = HealthComponent.new()
	health_comp.initialize(1000.0)
	health_comp.set_shield(200.0, 1)
	assert(health_comp.current_shield == 200.0, "Escudo inicial deve ser 200")
	assert(health_comp.has_active_shield() == true, "Deve ter escudo ativo")

	# Decaimento de 1 segundo: 5% de 200 (10) + 8 flat = 18 de perda
	var loss := health_comp.decay_shield(1.0)
	assert(is_equal_approx(loss, 18.0), "Perda em 1s deve ser 18 (5% de 200 + 8)")
	assert(is_equal_approx(health_comp.current_shield, 182.0), "Escudo restante deve ser 182")

	# Decaimento massivo (20 segundos) deve zerar sem ficar negativo
	health_comp.decay_shield(20.0)
	assert(health_comp.current_shield == 0.0, "Escudo deve zerar")
	assert(health_comp.current_shield_source == 0, "Fonte de escudo deve ser limpa")
	assert(health_comp.has_active_shield() == false, "Nao deve mais ter escudo ativo")

	# Limpeza direta
	health_comp.set_shield(150.0, 2)
	assert(health_comp.has_active_shield() == true, "Escudo ativo apos set")
	health_comp.clear_shield()
	assert(health_comp.current_shield == 0.0, "Escudo deve ser 0 apos clear_shield")
	assert(health_comp.has_active_shield() == false, "Nao deve ter escudo apos clear_shield")

	health_comp.free()
	print("OK: Decaimento suave e limpeza de escudo validados!")

func _test_base_unit_shield_lifecycle(catalog: UnitCatalog) -> void:
	print("Testando ciclo de vida de escudo e integracao em BaseUnit3D...")
	var unit = BaseUnit3D.new()
	unit.stats = catalog.get_unit("capivara")
	root.add_child(unit)

	unit.set_shield_with_source(200.0, BaseUnit3D.ShieldSource.SELF)
	assert(unit.current_shield == 200.0, "BaseUnit deve ter 200 de escudo")
	assert(unit.has_active_shield() == true, "BaseUnit deve reportar escudo ativo")

	# Decaimento em _physics_process quando in_combat = true
	unit.in_combat = true
	unit.board_position = Vector2i(0, 0) # fora do banco
	unit._physics_process(1.0)
	assert(unit.current_shield < 200.0, "Escudo deve decair no frame de combate")
	assert(unit.has_active_shield() == true, "Ainda deve restar escudo")

	# Limpeza via clear_shield()
	unit.clear_shield()
	assert(unit.current_shield == 0.0, "Escudo deve ser 0 apos clear_shield")
	assert(unit.has_active_shield() == false, "has_active_shield deve ser false apos clear_shield")

	# Sincronizacao do setter quando zerado externamente
	unit.set_shield_with_source(100.0)
	assert(unit.has_active_shield() == true, "Escudo reativado")
	unit.current_shield = 0.0
	assert(unit.health_comp.current_shield == 0.0, "health_comp deve ser zerado pelo setter")
	assert(unit.has_active_shield() == false, "has_active_shield deve ser false apos setter zerar")

	# Teste de morte limpando escudo
	unit.set_shield_with_source(150.0)
	unit.die()
	assert(unit.current_shield == 0.0, "Morte deve limpar escudo")
	assert(unit.has_active_shield() == false, "Morte deve zerar has_active_shield")

	unit.queue_free()
	print("OK: Ciclo de vida de escudo em BaseUnit3D validado!")

func _test_inspector_ui_panel_generation(catalog: UnitCatalog) -> void:
	print("Testando geracao dinamica de TFT_AbilityPanel no inspetor lateral...")
	var panel = Panel.new()
	var vbox = VBoxContainer.new()
	vbox.name = "VBoxContainer"
	panel.add_child(vbox)

	var name_lbl = RichTextLabel.new()
	name_lbl.name = "Name_label"
	vbox.add_child(name_lbl)

	var unit = BaseUnit3D.new()
	unit.stats = catalog.get_unit("alamoa")
	unit.star_level = 2
	root.add_child(unit)

	UnitInspectorPanel.show_inspector(unit, panel, null)

	var ability_panel = vbox.find_child("TFT_AbilityPanel", true, false) as PanelContainer
	assert(ability_panel != null, "TFT_AbilityPanel deve ser criado no painel do inspetor")

	var title_lbl = ability_panel.find_child("AbTitleLabel", true, false) as RichTextLabel
	assert(title_lbl != null, "AbTitleLabel deve existir")
	assert("Encanto de Noronha" in title_lbl.text, "Nome da habilidade deve constar no titulo")

	var vals_lbl = ability_panel.find_child("AbValuesLabel", true, false) as RichTextLabel
	assert(vals_lbl != null, "AbValuesLabel deve existir")
	assert("Dano:" in vals_lbl.text, "Linha de Dano deve existir nos valores")
	assert("Atual: 936" in vals_lbl.text, "Valor atual 2 estrelas (936) deve ser exibido")

	unit.queue_free()
	panel.free()
	print("OK: Interface do TFT_AbilityPanel validada com sucesso!")
