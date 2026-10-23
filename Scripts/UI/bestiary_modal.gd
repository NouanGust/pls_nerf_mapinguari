class_name BestiaryModal
extends Control

const UIStyle = preload("res://Scripts/UI/ui_style.gd")
const ResponsiveLayout = preload("res://Scripts/UI/responsive_layout.gd")
const UIAtlasCatalog = preload("res://Scripts/UI/ui_atlas_catalog.gd")

signal closed

var _backdrop: ColorRect
var _panel: PanelContainer
var _title_label: Label
var _close_btn: Button
var _scroll: ScrollContainer
var _content_box: VBoxContainer
var _portrait_rect: TextureRect
var _star_row: HBoxContainer
var _profile_lbl: RichTextLabel
var _stats_lbl: RichTextLabel
var _ability_lbl: RichTextLabel
var _synergies_lbl: RichTextLabel

var current_stats: UnitStats
var current_star_level: int = 1

func _init() -> void:
	name = "BestiaryModal"
	visible = false
	z_index = 30
	mouse_filter = Control.MOUSE_FILTER_STOP
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

func _ready() -> void:
	_build_ui()
	get_viewport().size_changed.connect(_fit_layout)

func _build_ui() -> void:
	# 1. Escurecimento de Fundo (Backdrop com clique para fechar)
	_backdrop = ColorRect.new()
	_backdrop.name = "Backdrop"
	_backdrop.color = Color(0.015, 0.025, 0.04, 0.82)
	_backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_backdrop.mouse_filter = Control.MOUSE_FILTER_STOP
	_backdrop.gui_input.connect(func(event: InputEvent) -> void:
		if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			close()
	)
	add_child(_backdrop)

	# 2. Painel Central Estilizado
	_panel = PanelContainer.new()
	_panel.name = "MainPanel"
	_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color(0.04, 0.07, 0.11, 0.98)
	panel_style.border_color = Color("#f59e0b")
	panel_style.set_border_width_all(2)
	panel_style.set_corner_radius_all(14)
	panel_style.shadow_color = Color(0, 0, 0, 0.85)
	panel_style.shadow_size = 18
	panel_style.content_margin_left = 22.0
	panel_style.content_margin_right = 22.0
	panel_style.content_margin_top = 18.0
	panel_style.content_margin_bottom = 20.0
	_panel.add_theme_stylebox_override("panel", panel_style)
	add_child(_panel)

	var main_vbox := VBoxContainer.new()
	main_vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	main_vbox.add_theme_constant_override("separation", 14)
	_panel.add_child(main_vbox)

	# --- Cabeçalho ---
	var header := HBoxContainer.new()
	header.mouse_filter = Control.MOUSE_FILTER_IGNORE
	header.add_theme_constant_override("separation", 10)
	main_vbox.add_child(header)

	var title_icon := UIAtlasCatalog.create_icon_rect("scroll_horn", Vector2(28, 28))
	header.add_child(title_icon)

	_title_label = Label.new()
	_title_label.name = "BestiaryTitle"
	_title_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_title_label.text = "BESTIÁRIO FOLCHESS"
	_title_label.add_theme_font_size_override("font_size", 20)
	_title_label.add_theme_color_override("font_color", Color("#fbbf24"))
	_title_label.add_theme_color_override("font_outline_color", Color("#060a0f"))
	_title_label.add_theme_constant_override("outline_size", 4)
	header.add_child(_title_label)

	_close_btn = Button.new()
	_close_btn.name = "CloseButton"
	_close_btn.icon = UIAtlasCatalog.get_button_texture("cross")
	_close_btn.expand_icon = true
	_close_btn.text = ""
	_close_btn.custom_minimum_size = Vector2(32, 32)
	_close_btn.tooltip_text = "Fechar Bestiário (Esc)"
	UIStyle.apply_button_skin(_close_btn, UIStyle.BORDER_SLATE)
	_close_btn.pressed.connect(close)
	header.add_child(_close_btn)

	var divider := ColorRect.new()
	divider.custom_minimum_size = Vector2(0, 2)
	divider.color = Color("#f59e0b", 0.4)
	main_vbox.add_child(divider)

	# --- Scroll Container para Conteúdo Rico ---
	_scroll = ScrollContainer.new()
	_scroll.name = "ScrollContainer"
	_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	main_vbox.add_child(_scroll)

	_content_box = VBoxContainer.new()
	_content_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_content_box.add_theme_constant_override("separation", 16)
	_scroll.add_child(_content_box)

	# Bloco 1: Perfil da Unidade (Retrato + Lore)
	var profile_row := HBoxContainer.new()
	profile_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	profile_row.add_theme_constant_override("separation", 18)
	_content_box.add_child(profile_row)

	var portrait_frame := PanelContainer.new()
	portrait_frame.custom_minimum_size = Vector2(100, 100)
	var p_style := StyleBoxFlat.new()
	p_style.bg_color = Color("#070d14")
	p_style.border_color = Color("#eab308")
	p_style.set_border_width_all(2)
	p_style.set_corner_radius_all(8)
	portrait_frame.add_theme_stylebox_override("panel", p_style)
	profile_row.add_child(portrait_frame)

	var portrait_box := VBoxContainer.new()
	portrait_box.alignment = BoxContainer.ALIGNMENT_CENTER
	portrait_box.add_theme_constant_override("separation", 6)
	portrait_frame.add_child(portrait_box)

	_portrait_rect = TextureRect.new()
	_portrait_rect.custom_minimum_size = Vector2(96, 96)
	_portrait_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_portrait_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	portrait_box.add_child(_portrait_rect)

	_star_row = HBoxContainer.new()
	_star_row.alignment = BoxContainer.ALIGNMENT_CENTER
	_star_row.add_theme_constant_override("separation", 3)
	portrait_box.add_child(_star_row)

	_profile_lbl = RichTextLabel.new()
	_profile_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_profile_lbl.bbcode_enabled = true
	_profile_lbl.fit_content = true
	_profile_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	profile_row.add_child(_profile_lbl)

	# Bloco 2: Escalonamento de Atributos por Estrela
	_stats_lbl = RichTextLabel.new()
	_stats_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_stats_lbl.bbcode_enabled = true
	_stats_lbl.fit_content = true
	_stats_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_content_box.add_child(_stats_lbl)

	# Bloco 3: Habilidade e Fórmulas por Estrela
	_ability_lbl = RichTextLabel.new()
	_ability_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_ability_lbl.bbcode_enabled = true
	_ability_lbl.fit_content = true
	_ability_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_content_box.add_child(_ability_lbl)

	# Bloco 4: Detalhamento de Sinergias
	_synergies_lbl = RichTextLabel.new()
	_synergies_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_synergies_lbl.bbcode_enabled = true
	_synergies_lbl.fit_content = true
	_synergies_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_content_box.add_child(_synergies_lbl)

func open_for_unit(stats: UnitStats, star_level: int = 1) -> void:
	if not stats:
		return
	current_stats = stats
	current_star_level = clampi(star_level, 1, 3)

	_title_label.text = "BESTIÁRIO · %s" % stats.unit_name.to_upper()
	if _portrait_rect:
		_portrait_rect.texture = stats.icon

	# 1. Perfil & Lore
	for child in _star_row.get_children():
		child.queue_free()
	for i in range(current_star_level):
		var star_icon := UIAtlasCatalog.create_icon_rect("star", Vector2(16, 16))
		if current_star_level >= 3:
			star_icon.modulate = Color("#fbbf24")
		elif current_star_level == 2:
			star_icon.modulate = Color("#e2e8f0")
		else:
			star_icon.modulate = Color("#cd7f32")
		_star_row.add_child(star_icon)

	var lore_desc := stats.lore if not stats.lore.is_empty() else stats.description
	if lore_desc.is_empty():
		lore_desc = "Criatura mística do folclore e da rica biodiversidade brasileira."
	
	var origins_str := ", ".join(stats.origins) if not stats.origins.is_empty() else "Nenhuma"
	var classes_str := ", ".join(stats.classes) if not stats.classes.is_empty() else "Nenhuma"
	
	_profile_lbl.text = "[b][size=20][color=#ffffff]%s[/color][/size][/b]  [color=#94a3b8](Tier %d · %d Ouro)[/color]\n" % [
		stats.unit_name, stats.tier, stats.cost
	]
	_profile_lbl.text += "[color=#cbd5e1][i]\"%s\"[/i][/color]\n\n" % lore_desc
	_profile_lbl.text += "[color=#74e6f5]Origens:[/color] [b]%s[/b]   ·   [color=#d8b4fe]Classes:[/color] [b]%s[/b]" % [
		origins_str, classes_str
	]

	# 2. Atributos Base & Escalonamento (1★ / 2★ / 3★)
	var hp_1 := int(stats.max_health * 1.0)
	var hp_2 := int(stats.max_health * 1.8)
	var hp_3 := int(stats.max_health * 2.6)
	var hp_str := _format_trio(hp_1, hp_2, hp_3, current_star_level)

	var atk_1 := int(stats.attack_damage * 1.0)
	var atk_2 := int(stats.attack_damage * 1.8)
	var atk_3 := int(stats.attack_damage * 2.6)
	var atk_str := _format_trio(atk_1, atk_2, atk_3, current_star_level)

	var dps_1 := int(atk_1 * stats.attack_speed)
	var dps_2 := int(atk_2 * stats.attack_speed)
	var dps_3 := int(atk_3 * stats.attack_speed)
	var dps_str := _format_trio(dps_1, dps_2, dps_3, current_star_level)

	var phys_red := int(round((stats.armor / (100.0 + stats.armor)) * 100.0))
	var mag_red := int(round((stats.magic_resist / (100.0 + stats.magic_resist)) * 100.0))
	var range_str := "À Distância (%d hex)" % stats.get_attack_range_hexes() if stats.is_ranged else "Corpo a Corpo (1 hex)"
	var dmg_type_str := "Físico" if stats.ability_damage_type == 0 else "Mágico"

	_stats_lbl.text = "[color=#facc15]ATRIBUTOS & ESCALONAMENTO POR ESTRELA (1★ / 2★ / 3★)[/color]\n"
	_stats_lbl.text += "• [color=#4ade80]Vida Base:[/color] %s\n" % hp_str
	_stats_lbl.text += "• [color=#fb923c]Ataque Base:[/color] %s  ·  [color=#cbd5e1]DPS Base:[/color] %s\n" % [atk_str, dps_str]
	_stats_lbl.text += "• [color=#cbd5e1]Velocidade de Ataque:[/color] %.2f/s  ·  [color=#cbd5e1]Alcance:[/color] %s  ·  [color=#cbd5e1]Dano Básico:[/color] %s\n" % [
		stats.attack_speed, range_str, dmg_type_str
	]
	_stats_lbl.text += "• [color=#60a5fa]Armadura:[/color] [b]%d[/b] [color=#94a3b8](-%d%% dano físico)[/color]  ·  [color=#a78bfa]Resistência Mágica:[/color] [b]%d[/b] [color=#94a3b8](-%d%% dano mágico)[/color]\n" % [
		int(stats.armor), phys_red, int(stats.magic_resist), mag_red
	]
	_stats_lbl.text += "• [color=#38bdf8]Mana:[/color] [b]%d / %d[/b] [color=#94a3b8](Inicia com %d · Ganha %d por ataque básico)[/color]" % [
		int(stats.starting_mana), int(stats.max_mana), int(stats.starting_mana), int(stats.mana_per_attack)
	]

	# 3. Habilidade & Fórmulas Completas
	var ab_type := "Mágico"
	match stats.ability_damage_type:
		UnitStats.DamageType.PHYSICAL: ab_type = "Físico"
		UnitStats.DamageType.MAGICAL: ab_type = "Mágico"
		UnitStats.DamageType.TRUE: ab_type = "Verdadeiro"

	var ab_details: Array[String] = []
	if stats.ability_damage > 0.0:
		var d1 := int(stats.ability_damage * 1.0)
		var d2 := int(stats.ability_damage * 1.8)
		var d3 := int(stats.ability_damage * 2.6)
		ab_details.append("• [color=#f87171]Dano Base:[/color] %s" % _format_trio(d1, d2, d3, current_star_level))
	
	if stats.ability_heal > 0.0:
		var h1 := int(stats.ability_heal * 1.0)
		var h2 := int(stats.ability_heal * 1.8)
		var h3 := int(stats.ability_heal * 2.6)
		ab_details.append("• [color=#4ade80]Cura Base:[/color] %s" % _format_trio(h1, h2, h3, current_star_level))

	if stats.ability_shield > 0.0:
		var s1 := int(stats.ability_shield * 1.0)
		var s2 := int(stats.ability_shield * 1.8)
		var s3 := int(stats.ability_shield * 2.6)
		ab_details.append("• [color=#38bdf8]Escudo Base:[/color] %s" % _format_trio(s1, s2, s3, current_star_level))

	if stats.ability_mana > 0.0:
		var m1 := int(stats.ability_mana * 1.0)
		var m2 := int(stats.ability_mana * 1.8)
		var m3 := int(stats.ability_mana * 2.6)
		ab_details.append("• [color=#80d8ea]Mana Concedida:[/color] %s" % _format_trio(m1, m2, m3, current_star_level))

	# Casos especiais folclóricos
	match stats.unit_id:
		"alamoa":
			ab_details.append("• [color=#f472b6]Atordoamento / Charme:[/color] %s" % _format_trio("3.0s", "3.75s", "4.5s", current_star_level))
		"anhanga":
			ab_details.append("• [color=#86efac]Enfraquecimento da Caça:[/color] %s de redução de dano inimigo" % _format_trio("-30%", "-40%", "-50%", current_star_level))
		"cabeca_de_cuia":
			var sh1 := int(15.0 * 1.0)
			var sh2 := int(15.0 * 1.8)
			var sh3 := int(15.0 * 2.6)
			ab_details.append("• [color=#38bdf8]Quebra de Armadura:[/color] %s" % _format_trio(sh1, sh2, sh3, current_star_level))
		"mapinguari":
			ab_details.append("• [color=#94a3b8]Dano Refletido (Couro de Ferro):[/color] %s" % _format_trio("40%", "48%", "56%", current_star_level))
		"quibungo":
			ab_details.append("• [color=#c084fc]Prisão Verdadeira:[/color] 3.0s contínuos (Dano verdadeiro)")
		"minhocao":
			ab_details.append("• [color=#d97706]Terremoto Sísmico:[/color] 2.0s de atordoamento em área hexagonal")
		"matinta_perera":
			ab_details.append("• [color=#c084fc]Forma Espectral:[/color] Avança velozmente, inflige forte dano e confusão por 2.5s com 3.0s de invulnerabilidade e retorna")
		"sabia_laranjeira":
			ab_details.append("• [color=#fb923c]Bicada Veloz:[/color] Voa até o inimigo, desfere bicada e recebe +35% de velocidade por 4.0s")
		"araucaria":
			ab_details.append("• [color=#22c55e]Copa Protetora:[/color] Barreira de raízes protege Araucária e aliados próximos com escudo")
		"caapora":
			var sh1 := int(20.0 * 1.0)
			var sh2 := int(20.0 * 1.8)
			var sh3 := int(20.0 * 2.6)
			ab_details.append("• [color=#10b981]Flecha Perfurante:[/color] Atravessa até 5 inimigos com quebra de armadura (%s)" % _format_trio(sh1, sh2, sh3, current_star_level))
		"comadre_fulozinha":
			ab_details.append("• [color=#f472b6]Espíritos da Floresta:[/color] Invoca 2 espíritos que golpeiam inimigos e curam aliados por 10.0s")
		"corpo_seco":
			ab_details.append("• [color=#a855f7]Dreno Vital:[/color] Dano verdadeiro e cura contínua ao longo de 4.0s em área")
		"mboi_guacu":
			ab_details.append("• [color=#0284c7]Constrição Mortal:[/color] Imobiliza o alvo por 4.0s causando dano físico contínuo e ganha escudo")
		"onca_pintada":
			ab_details.append("• [color=#f59e0b]Bote de Emboscada:[/color] Salto mortal nas costas do menor HP com sangramento e atordoamento")
		"pau_brasil":
			ab_details.append("• [color=#eab308]Florada Dourada:[/color] Causa dano mágico em área, enfraquece inimigos e concede escudo a aliados")
		"pisadeira":
			ab_details.append("• [color=#9333ea]Paralisia do Terror:[/color] Paralisa inimigos em área por %s e drena 25 de mana" % _format_trio("2.5s", "3.0s", "3.5s", current_star_level))
		"sumauma":
			ab_details.append("• [color=#16a34a]Raízes Guardiãs:[/color] Enraíza inimigos em raio de 4.0m e ampara aliados adjacentes com cura e escudo")

	if stats.ability_targets > 1:
		ab_details.append("• [color=#cbd5e1]Alvos Simultâneos:[/color] %d" % stats.ability_targets)
	if stats.ability_duration > 0.0 and not stats.unit_id in ["alamoa", "anhanga", "cabeca_de_cuia", "mapinguari", "quibungo", "minhocao", "matinta_perera", "sabia_laranjeira", "araucaria", "caapora", "comadre_fulozinha", "corpo_seco", "mboi_guacu", "onca_pintada", "pau_brasil", "pisadeira", "sumauma"]:
		ab_details.append("• [color=#cbd5e1]Duração do Efeito:[/color] %.1fs" % stats.ability_duration)

	_ability_lbl.text = "[color=#c084fc]HABILIDADE: %s[/color] [color=#94a3b8](%s)[/color]\n" % [stats.ability_name, ab_type]
	_ability_lbl.text += "[color=#ecf0f1]%s[/color]\n\n" % stats.ability_description
	if not ab_details.is_empty():
		_ability_lbl.text += "[color=#cbd5e1]Detalhamento de Valores (1★ / 2★ / 3★):[/color]\n" + "\n".join(ab_details)

	# 4. Sinergias e Efeitos de Patamar
	var syn_blocks: Array[String] = []
	for tag in stats.origins + stats.classes:
		var rule := SynergySystem.get_rule_for_tag(tag)
		if rule.is_empty():
			continue
		var cat_name: String = "Origem" if str(rule.get("field", "")) == "origins" else "Classe"
		var lines: Array[String] = []
		lines.append("[b][color=#f5da80]%s[/color][/b] [color=#94a3b8](%s)[/color]" % [tag, cat_name])
		var r_thresholds: Array = rule.get("thresholds", [])
		var r_effects: Array = rule.get("effects", [])
		for i in r_thresholds.size():
			var t_val := int(r_thresholds[i])
			var eff_text := str(r_effects[i].get("text", "")) if i < r_effects.size() else ""
			lines.append("  • [color=#2ecc71](%d)[/color] [color=#cbd5e1]%s[/color]" % [t_val, eff_text])
		syn_blocks.append("\n".join(lines))

	if not syn_blocks.is_empty():
		_synergies_lbl.text = "[color=#38bdf8]SINERGIAS DESTA UNIDADE[/color]\n" + "\n\n".join(syn_blocks)
	else:
		_synergies_lbl.text = ""

	_fit_layout()
	show()

func _format_trio(v1: Variant, v2: Variant, v3: Variant, current_star: int, suffix: String = "") -> String:
	var s1 := "%s%s" % [str(v1), suffix]
	var s2 := "%s%s" % [str(v2), suffix]
	var s3 := "%s%s" % [str(v3), suffix]
	if current_star == 1:
		s1 = "[b][color=#fde047]%s[/color][/b]" % s1
	elif current_star == 2:
		s2 = "[b][color=#fde047]%s[/color][/b]" % s2
	elif current_star >= 3:
		s3 = "[b][color=#fde047]%s[/color][/b]" % s3
	return "%s / %s / %s" % [s1, s2, s3]

func close() -> void:
	hide()
	closed.emit()

func _input(event: InputEvent) -> void:
	if not visible:
		return
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_ESCAPE:
			close()
			get_viewport().set_input_as_handled()

func _fit_layout() -> void:
	if not is_instance_valid(_panel):
		return
	var viewport_size: Vector2 = get_viewport().get_visible_rect().size
	var target_w := minf(720.0, viewport_size.x - 40.0)
	var target_h := minf(680.0, viewport_size.y - 60.0)
	_panel.size = Vector2(target_w, target_h)
	_panel.position = (viewport_size - _panel.size) * 0.5
