class_name UnitInspectorPanel
extends RefCounted

## Gerenciador desacoplado do Painel Lateral de Inspeção de Unidades (Estilo TFT)

const UIAtlasCatalog = preload("res://Scripts/UI/ui_atlas_catalog.gd")

static var _ability_floating_card: PanelContainer = null
static var _inspected_unit: BaseUnit3D = null

static func get_inspected_unit() -> BaseUnit3D:
	return _inspected_unit

static func get_ability_info(stats: UnitStats, unit: BaseUnit3D = null, star: int = 1) -> Dictionary:
	var info := {
		"name": stats.ability_name if not stats.ability_name.is_empty() else "Habilidade Especial",
		"mana": int(stats.max_mana),
		"role": stats.get_combat_role(),
		"type_str": "Mágico",
		"type_color": "#c084fc",
		"desc": stats.get_mechanics_description(star),
		"lines": [] as Array[String]
	}

	match stats.ability_damage_type:
		UnitStats.DamageType.PHYSICAL:
			info["type_str"] = "Físico"
			info["type_color"] = "#fb923c"
		UnitStats.DamageType.MAGICAL:
			info["type_str"] = "Mágico"
			info["type_color"] = "#c084fc"
		UnitStats.DamageType.TRUE:
			info["type_str"] = "Verdadeiro"
			info["type_color"] = "#facc15"

	var star_mult_1 := stats.get_star_multiplier(1)
	var star_mult_2 := stats.get_star_multiplier(2)
	var star_mult_3 := stats.get_star_multiplier(3)
	var cur_star_mult := stats.get_star_multiplier(star)

	var ap_mult: float = 1.0
	if is_instance_valid(unit):
		ap_mult += float(unit.synergy_bonuses.get("ability_power_pct", 0.0))

	# 1. Dano
	var base_dmg := stats.ability_damage
	if base_dmg <= 0.0:
		if stats.is_conjurador_role() or stats.ability_kind == "conjure_area":
			base_dmg = 220.0
		elif stats.ability_kind == "conjure_line":
			base_dmg = 360.0
		elif stats.is_assassino_role() or stats.ability_kind == "assassin":
			base_dmg = 260.0

	if base_dmg > 0.0:
		var d1 := int(base_dmg * star_mult_1)
		var d2 := int(base_dmg * star_mult_2)
		var d3 := int(base_dmg * star_mult_3)
		var cur_d := int(base_dmg * cur_star_mult * ap_mult)
		info["lines"].append("[color=#fb923c]Dano:[/color] %d / %d / %d  [color=#fde047](Atual: %d)[/color]" % [d1, d2, d3, cur_d])

	# 2. Escudo
	var base_sh := stats.ability_shield
	if base_sh <= 0.0 and (stats.is_tank_role() or stats.ability_kind == "tank_guard"):
		var max_hp := unit.get_max_health() if is_instance_valid(unit) else stats.max_health
		base_sh = max_hp * 0.22

	if base_sh > 0.0:
		var s1 := int(base_sh * star_mult_1)
		var s2 := int(base_sh * star_mult_2)
		var s3 := int(base_sh * star_mult_3)
		var cur_s := int(base_sh * cur_star_mult * ap_mult)
		info["lines"].append("[color=#38bdf8]Escudo:[/color] %d / %d / %d  [color=#67e8f9](Atual: %d)[/color]" % [s1, s2, s3, cur_s])

	# 3. Cura
	var base_heal := stats.ability_heal
	if base_heal > 0.0:
		var h1 := int(base_heal * star_mult_1)
		var h2 := int(base_heal * star_mult_2)
		var h3 := int(base_heal * star_mult_3)
		var cur_h := int(base_heal * cur_star_mult * ap_mult)
		info["lines"].append("[color=#4ade80]Cura:[/color] %d / %d / %d  [color=#86efac](Atual: %d)[/color]" % [h1, h2, h3, cur_h])

	# 4. Parâmetros táticos
	var extras: Array[String] = []
	if stats.ability_targets > 1:
		extras.append("Alvos: %d" % stats.ability_targets)
	if stats.ability_duration > 0.0:
		extras.append("Duração: %.1fs" % stats.ability_duration)
	elif stats.ability_kind == "self_haste":
		extras.append("Duração: 4.0s · AS: +40% · AD: +20%")
	elif stats.ability_kind == "brawler":
		extras.append("Duração: 4.5s · AD: +30% · Def: +20")
	elif stats.ability_kind == "tank_guard":
		extras.append("Duração: 4.0s · Def: +25 Arm / +20 RM")

	if not extras.is_empty():
		info["lines"].append("[color=#94a3b8]%s[/color]" % (" · ".join(extras)))

	return info

static func show_inspector(unit: BaseUnit3D, panel: Control, ui: CanvasLayer) -> void:
	if not is_instance_valid(unit) or not unit.stats or not is_instance_valid(panel):
		return

	_inspected_unit = unit
	var stats := unit.stats
	var star := clampi(unit.star_level, 1, 4)

	var name_lbl = panel.find_child("Name_label", true, false) as RichTextLabel
	if name_lbl:
		var tier_hex := "#" + stats.get_tier_color().to_html(false)
		name_lbl.text = "[b]%s[/b] [color=%s](Tier %d · %dg)[/color]" % [
			stats.unit_name, tier_hex, stats.tier, stats.cost
		]
		var star_box = panel.find_child("InspectorStarBox", true, false) as HBoxContainer
		if not star_box:
			star_box = HBoxContainer.new()
			star_box.name = "InspectorStarBox"
			star_box.alignment = BoxContainer.ALIGNMENT_CENTER
			star_box.add_theme_constant_override("separation", 3)
			name_lbl.get_parent().add_child(star_box)
			name_lbl.get_parent().move_child(star_box, name_lbl.get_index() + 1)
		for child in star_box.get_children():
			child.queue_free()
		var stars_count: int = star
		for s in range(stars_count):
			var star_icon := UIAtlasCatalog.create_icon_rect("star", Vector2(16, 16))
			if stars_count >= 3:
				star_icon.modulate = Color("#fbbf24")
			elif stars_count == 2:
				star_icon.modulate = Color("#e2e8f0")
			else:
				star_icon.modulate = Color("#cd7f32")
			star_box.add_child(star_icon)

	var p_frame = panel.find_child("PortraitFrame", true, false)
	if p_frame:
		p_frame.modulate = stats.get_tier_color()
	var img = panel.find_child("Image_container", true, false) as TextureRect
	if img:
		img.texture = stats.icon

	var cur_hp := int(unit.current_health)
	var max_hp := int(unit.get_max_health())
	var cur_mana := int(unit.current_mana)
	var max_mana := int(stats.max_mana)
	var attack_dmg := int(unit.get_attack_damage())
	var attack_spd := unit.get_effective_attack_speed()
	var dps := int(attack_dmg * attack_spd)

	var total_armor := unit.get_effective_armor()
	var phys_reduct: int = int(round((total_armor / (100.0 + total_armor)) * 100.0))
	var total_mr := unit.get_effective_magic_resist()
	var mag_reduct: int = int(round((total_mr / (100.0 + total_mr)) * 100.0))

	# Ocultar labels legadas para dar lugar aos componentes visuais elegantes
	for legacy_name in ["Hp_label", "Mana_label", "Type_label", "Range_label", "Defense_label", "Role_label", "Star_scaling_label", "Affinities_label"]:
		var lbl = panel.find_child(legacy_name, true, false)
		if lbl:
			lbl.visible = false

	var origins_lbl = panel.find_child("Origins_label", true, false) as RichTextLabel
	if origins_lbl:
		var origin_parts: Array[String] = []
		for orig in stats.origins:
			origin_parts.append("[url=%s][u][color=#f5da80]%s[/color][/u][/url]" % [orig, orig])
		origins_lbl.text = "[color=#f1c40f]ORIGENS[/color]  %s" % (" · ".join(origin_parts) if not origin_parts.is_empty() else "—")

	var classes_lbl = panel.find_child("Classes_label", true, false) as RichTextLabel
	if classes_lbl:
		var role_name := stats.get_combat_role()
		classes_lbl.text = "[color=#9b59b6]FUNÇÃO[/color]  [u][color=#d8b4fe]%s[/color][/u]" % (role_name if not role_name.is_empty() else "—")

	_update_tft_inspector(panel, unit, cur_hp, max_hp, cur_mana, max_mana, attack_dmg, attack_spd, dps, total_armor, phys_reduct, total_mr, mag_reduct)
	update_live_data(panel, unit)

	if ui and ui.has_method("set_inspected_unit_data"):
		ui.set_inspected_unit_data(stats, unit.star_level)
	if ui and ui.has_method("show_inspector"):
		ui.show_inspector()
	else:
		panel.show()

static func hide_inspector(panel: Control, ui: CanvasLayer) -> void:
	_inspected_unit = null
	_hide_ability_floating_card()
	if ui and ui.has_method("hide_inspector"):
		ui.hide_inspector()
	elif is_instance_valid(panel):
		panel.hide()

static func update_live_data(panel: Control, unit: BaseUnit3D) -> void:
	if not is_instance_valid(unit) or not unit.stats or not is_instance_valid(panel):
		return
	var stats := unit.stats
	var star := clampi(unit.star_level, 1, 4)

	var cur_hp := maxi(int(unit.current_health), 0)
	var max_hp := maxi(int(unit.get_max_health()), 1)
	var cur_shield := maxi(int(unit.current_shield), 0)
	var cur_mana := maxi(int(unit.current_mana), 0)
	var max_mana := maxi(int(stats.max_mana), 1)

	var attack_dmg := maxi(int(unit.get_attack_damage()), 0)
	var attack_spd := unit.get_effective_attack_speed()
	var dps := maxi(int(attack_dmg * attack_spd), 0)

	var total_armor := unit.get_effective_armor()
	var total_mr := unit.get_effective_magic_resist()
	var phys_reduct: int = int(round((total_armor / (100.0 + total_armor)) * 100.0))
	var mag_reduct: int = int(round((total_mr / (100.0 + total_mr)) * 100.0))

	var ap_mult: float = 1.0 + float(unit.synergy_bonuses.get("ability_power_pct", 0.0))
	var ap_val: int = int(stats.ability_damage * stats.get_star_multiplier(star) * ap_mult)
	var crit_pct: int = int(round((stats.critical_chance + float(unit.synergy_bonuses.get("crit_chance", 0.0))) * 100.0))

	var hp_bar = panel.find_child("InspectorHpBar", true, false) as ProgressBar
	if hp_bar:
		hp_bar.max_value = max_hp
		hp_bar.value = cur_hp
		var hp_label = hp_bar.find_child("HpTextLabel", false, false) as Label
		if hp_label:
			var bonus_hp_text := ""
			if float(unit.synergy_bonuses.get("max_health_pct", 0.0)) > 0.0:
				bonus_hp_text = " (+%d%%)" % int(float(unit.synergy_bonuses.get("max_health_pct", 0.0)) * 100.0)
			if cur_shield > 0:
				hp_label.text = "%d (+%d) / %d%s" % [cur_hp, cur_shield, max_hp, bonus_hp_text]
			else:
				hp_label.text = "%d / %d%s" % [cur_hp, max_hp, bonus_hp_text]

	var shield_bar = panel.find_child("InspectorShieldBar", true, false) as ProgressBar
	if shield_bar:
		if cur_shield > 0:
			shield_bar.visible = true
			shield_bar.max_value = max_hp
			shield_bar.value = cur_shield
			var shield_label = shield_bar.find_child("ShieldTextLabel", false, false) as Label
			if shield_label:
				shield_label.text = "Escudo: %d" % cur_shield
		else:
			shield_bar.visible = false

	var mana_bar = panel.find_child("InspectorManaBar", true, false) as ProgressBar
	if mana_bar:
		mana_bar.max_value = max_mana
		mana_bar.value = cur_mana
		var mana_label = mana_bar.find_child("ManaTextLabel", false, false) as Label
		if mana_label:
			mana_label.text = "%d / %d" % [cur_mana, int(stats.max_mana)]

	var stats_grid = panel.find_child("TFT_StatsGrid", true, false) as GridContainer
	if stats_grid:
		var live_stats := {
			"ad": {"val": str(attack_dmg), "tip": "Dano de Ataque: %d\nDano físico atual por ataque (inclui itens, sinergias e bônus)." % attack_dmg},
			"ap": {"val": str(ap_val), "tip": "Poder de Habilidade: %d\nDano base escalonado por estrelas (x%.1f) e amplificadores." % [ap_val, stats.get_star_multiplier(star)]},
			"arm": {"val": str(int(total_armor)), "tip": "Armadura: %d\nReduz dano físico recebido em %d%%." % [int(total_armor), phys_reduct]},
			"mr": {"val": str(int(total_mr)), "tip": "Resistência Mágica: %d\nReduz dano mágico recebido em %d%%." % [int(total_mr), mag_reduct]},
			"as": {"val": "%.2f" % attack_spd, "tip": "Velocidade de Ataque: %.2f ataques por segundo." % attack_spd},
			"crit": {"val": "%d%%" % crit_pct, "tip": "Acerto Crítico: %d%%\nChance de ataques normais e magias causarem dano crítico amplificado." % crit_pct},
			"rng": {"val": "%d Hex" % stats.get_attack_range_hexes(), "tip": "Alcance de Ataque: %d hexágonos." % stats.get_attack_range_hexes()},
			"dps": {"val": str(dps), "tip": "DPS em Tempo Real: ~%d\nDano por segundo contínuo estimado (Ataque x Velocidade)." % dps}
		}
		for key in live_stats.keys():
			var slot = stats_grid.find_child("Slot_" + key, false, false) as Control
			if slot:
				var v_lbl = slot.find_child("ValLabel", true, false) as Label
				if v_lbl:
					v_lbl.text = live_stats[key]["val"]
				slot.tooltip_text = live_stats[key]["tip"]

	var ab_panel = panel.find_child("TFT_AbilityPanel", true, false) as PanelContainer
	if ab_panel:
		var ab_info := get_ability_info(stats, unit, star)
		var title_lbl = ab_panel.find_child("AbTitleLabel", true, false) as RichTextLabel
		if title_lbl:
			title_lbl.text = "[color=#f8fafc][b]%s[/b][/color]  [color=%s][b]%s[/b][/color] [color=#67e8f9](%d Mana)[/color]" % [
				ab_info["name"], ab_info["type_color"], ab_info["type_str"], ab_info["mana"]
			]
		var vals_lbl = ab_panel.find_child("AbValuesLabel", true, false) as RichTextLabel
		if vals_lbl:
			vals_lbl.text = "\n".join(ab_info["lines"]) if not ab_info["lines"].is_empty() else ""
		var desc_lbl = ab_panel.find_child("AbDescLabel", true, false) as RichTextLabel
		if desc_lbl:
			desc_lbl.text = "[color=#94a3b8][font_size=11]%s[/font_size][/color]" % ab_info["desc"]

static func _update_tft_inspector(
	panel: Control,
	unit: BaseUnit3D,
	cur_hp: int,
	max_hp: int,
	cur_mana: int,
	max_mana: int,
	attack_dmg: int,
	attack_spd: float,
	dps: int,
	total_armor: float,
	phys_reduct: int,
	total_mr: float,
	mag_reduct: int
) -> void:
	var vbox := panel.find_child("VBoxContainer", true, false) as VBoxContainer
	if not vbox:
		return
	var stats := unit.stats
	var star := clampi(unit.star_level, 1, 4)

	var bars_container = vbox.find_child("TFT_BarsContainer", false, false) as VBoxContainer
	if not bars_container:
		bars_container = VBoxContainer.new()
		bars_container.name = "TFT_BarsContainer"
		bars_container.add_theme_constant_override("separation", 4)
		vbox.add_child(bars_container)
		var p_frame = vbox.find_child("PortraitFrame", false, false)
		if p_frame:
			vbox.move_child(bars_container, p_frame.get_index() + 1)

	var hp_bar = bars_container.find_child("InspectorHpBar", false, false) as ProgressBar
	var hp_label: Label = null
	if not hp_bar:
		hp_bar = ProgressBar.new()
		hp_bar.name = "InspectorHpBar"
		hp_bar.custom_minimum_size = Vector2(0, 18)
		hp_bar.show_percentage = false
		var hp_bg := StyleBoxFlat.new()
		hp_bg.bg_color = Color("#052e16")
		hp_bg.corner_radius_top_left = 3
		hp_bg.corner_radius_top_right = 3
		hp_bg.corner_radius_bottom_left = 3
		hp_bg.corner_radius_bottom_right = 3
		hp_bar.add_theme_stylebox_override("background", hp_bg)
		var hp_fill := StyleBoxFlat.new()
		hp_fill.bg_color = Color("#22c55e")
		hp_fill.corner_radius_top_left = 3
		hp_fill.corner_radius_top_right = 3
		hp_fill.corner_radius_bottom_left = 3
		hp_fill.corner_radius_bottom_right = 3
		hp_bar.add_theme_stylebox_override("fill", hp_fill)

		hp_label = Label.new()
		hp_label.name = "HpTextLabel"
		hp_label.set_anchors_preset(Control.PRESET_FULL_RECT)
		hp_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		hp_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		hp_label.add_theme_font_size_override("font_size", 11)
		hp_label.add_theme_color_override("font_color", Color.WHITE)
		hp_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.8))
		hp_label.add_theme_constant_override("shadow_offset_x", 1)
		hp_label.add_theme_constant_override("shadow_offset_y", 1)
		hp_bar.add_child(hp_label)
		bars_container.add_child(hp_bar)

	var shield_bar = bars_container.find_child("InspectorShieldBar", false, false) as ProgressBar
	var shield_label: Label = null
	if not shield_bar:
		shield_bar = ProgressBar.new()
		shield_bar.name = "InspectorShieldBar"
		shield_bar.custom_minimum_size = Vector2(0, 14)
		shield_bar.show_percentage = false
		var sh_bg := StyleBoxFlat.new()
		sh_bg.bg_color = Color("#082f49")
		sh_bg.corner_radius_top_left = 3
		sh_bg.corner_radius_top_right = 3
		sh_bg.corner_radius_bottom_left = 3
		sh_bg.corner_radius_bottom_right = 3
		shield_bar.add_theme_stylebox_override("background", sh_bg)
		var sh_fill := StyleBoxFlat.new()
		sh_fill.bg_color = Color("#06b6d4")
		sh_fill.corner_radius_top_left = 3
		sh_fill.corner_radius_top_right = 3
		sh_fill.corner_radius_bottom_left = 3
		sh_fill.corner_radius_bottom_right = 3
		shield_bar.add_theme_stylebox_override("fill", sh_fill)

		shield_label = Label.new()
		shield_label.name = "ShieldTextLabel"
		shield_label.set_anchors_preset(Control.PRESET_FULL_RECT)
		shield_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		shield_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		shield_label.add_theme_font_size_override("font_size", 10)
		shield_label.add_theme_color_override("font_color", Color("#cffafe"))
		shield_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.8))
		shield_label.add_theme_constant_override("shadow_offset_x", 1)
		shield_label.add_theme_constant_override("shadow_offset_y", 1)
		shield_bar.add_child(shield_label)
		bars_container.add_child(shield_bar)
		bars_container.move_child(shield_bar, hp_bar.get_index() + 1)

	var mana_bar = bars_container.find_child("InspectorManaBar", false, false) as ProgressBar
	var mana_label: Label = null
	if not mana_bar:
		mana_bar = ProgressBar.new()
		mana_bar.name = "InspectorManaBar"
		mana_bar.custom_minimum_size = Vector2(0, 14)
		mana_bar.show_percentage = false
		var mp_bg := StyleBoxFlat.new()
		mp_bg.bg_color = Color("#082f49")
		mp_bg.corner_radius_top_left = 3
		mp_bg.corner_radius_top_right = 3
		mp_bg.corner_radius_bottom_left = 3
		mp_bg.corner_radius_bottom_right = 3
		mana_bar.add_theme_stylebox_override("background", mp_bg)
		var mp_fill := StyleBoxFlat.new()
		mp_fill.bg_color = Color("#0284c7")
		mp_fill.corner_radius_top_left = 3
		mp_fill.corner_radius_top_right = 3
		mp_fill.corner_radius_bottom_left = 3
		mp_fill.corner_radius_bottom_right = 3
		mana_bar.add_theme_stylebox_override("fill", mp_fill)

		mana_label = Label.new()
		mana_label.name = "ManaTextLabel"
		mana_label.set_anchors_preset(Control.PRESET_FULL_RECT)
		mana_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		mana_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		mana_label.add_theme_font_size_override("font_size", 10)
		mana_label.add_theme_color_override("font_color", Color.WHITE)
		mana_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.8))
		mana_label.add_theme_constant_override("shadow_offset_x", 1)
		mana_label.add_theme_constant_override("shadow_offset_y", 1)
		mana_bar.add_child(mana_label)
		bars_container.add_child(mana_bar)

	var tactical_row = vbox.find_child("TFT_TacticalRow", false, false) as HBoxContainer
	if not tactical_row:
		tactical_row = HBoxContainer.new()
		tactical_row.name = "TFT_TacticalRow"
		tactical_row.add_theme_constant_override("separation", 8)
		vbox.add_child(tactical_row)
		vbox.move_child(tactical_row, bars_container.get_index() + 1)

	var ability_btn = tactical_row.find_child("AbilityButton", false, false) as Button
	if not ability_btn:
		ability_btn = Button.new()
		ability_btn.name = "AbilityButton"
		ability_btn.custom_minimum_size = Vector2(44, 44)
		ability_btn.expand_icon = true
		ability_btn.icon = stats.icon
		var btn_style := StyleBoxFlat.new()
		btn_style.bg_color = Color("#1e1b4b")
		btn_style.border_color = Color("#a855f7")
		btn_style.border_width_left = 2
		btn_style.border_width_top = 2
		btn_style.border_width_right = 2
		btn_style.border_width_bottom = 2
		btn_style.corner_radius_top_left = 6
		btn_style.corner_radius_top_right = 6
		btn_style.corner_radius_bottom_left = 6
		btn_style.corner_radius_bottom_right = 6
		ability_btn.add_theme_stylebox_override("normal", btn_style)
		ability_btn.add_theme_stylebox_override("hover", btn_style)
		ability_btn.add_theme_stylebox_override("pressed", btn_style)
		tactical_row.add_child(ability_btn)
	else:
		ability_btn.icon = stats.icon

	ability_btn.tooltip_text = ""
	if not ability_btn.mouse_entered.is_connected(_on_ability_btn_entered):
		ability_btn.mouse_entered.connect(_on_ability_btn_entered.bind(panel))
	if not ability_btn.mouse_exited.is_connected(_hide_ability_floating_card):
		ability_btn.mouse_exited.connect(_hide_ability_floating_card)

	var badges_vbox = tactical_row.find_child("BadgesVBox", false, false) as VBoxContainer
	if not badges_vbox:
		badges_vbox = VBoxContainer.new()
		badges_vbox.name = "BadgesVBox"
		badges_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		badges_vbox.add_theme_constant_override("separation", 3)
		tactical_row.add_child(badges_vbox)

	var role_badge = badges_vbox.find_child("RoleBadge", false, false) as Label
	if not role_badge:
		role_badge = Label.new()
		role_badge.name = "RoleBadge"
		role_badge.add_theme_font_size_override("font_size", 11)
		role_badge.add_theme_color_override("font_color", Color("#38bdf8"))
		role_badge.mouse_filter = Control.MOUSE_FILTER_PASS
		badges_vbox.add_child(role_badge)
	role_badge.text = "[ %s ]" % stats.get_combat_role().to_upper()
	role_badge.tooltip_text = "Função de Combate:\n%s" % stats.get_combat_role_description()

	var range_badge = badges_vbox.find_child("RangeBadge", false, false) as Label
	if not range_badge:
		range_badge = Label.new()
		range_badge.name = "RangeBadge"
		range_badge.add_theme_font_size_override("font_size", 11)
		range_badge.add_theme_color_override("font_color", Color("#cbd5e1"))
		range_badge.mouse_filter = Control.MOUSE_FILTER_PASS
		badges_vbox.add_child(range_badge)
	var pos_str := "Recuada" if stats.is_ranged else "Linha de Frente"
	range_badge.text = "%s · %d Hex" % [pos_str, stats.get_attack_range_hexes()]
	range_badge.tooltip_text = "Posicionamento Tático:\nIdeal na %s. Alcance efetivo de %d hexágonos." % [pos_str, stats.get_attack_range_hexes()]

	# --- Linha de Itens Equipados (Máximo 2 itens) ---
	var items_row = vbox.find_child("TFT_ItemsRow", false, false) as HBoxContainer
	if not items_row:
		items_row = HBoxContainer.new()
		items_row.name = "TFT_ItemsRow"
		items_row.add_theme_constant_override("separation", 6)
		vbox.add_child(items_row)
		vbox.move_child(items_row, tactical_row.get_index() + 1)

		var items_label := Label.new()
		items_label.name = "ItemsTitleLabel"
		items_label.text = "Itens (2 máx):"
		items_label.add_theme_font_size_override("font_size", 11)
		items_label.add_theme_color_override("font_color", Color("#94a3b8"))
		items_row.add_child(items_label)

		for slot_idx in range(2):
			var slot_btn := Button.new()
			slot_btn.name = "ItemSlot_%d" % slot_idx
			slot_btn.custom_minimum_size = Vector2(32, 32)
			slot_btn.expand_icon = true
			slot_btn.add_theme_font_size_override("font_size", 10)
			items_row.add_child(slot_btn)

	var eq_items: Array = unit.get_equipped_items() if unit.has_method("get_equipped_items") else []
	for slot_idx in range(2):
		var slot_btn = items_row.find_child("ItemSlot_%d" % slot_idx, false, false) as Button
		if not slot_btn:
			continue
		if slot_idx < eq_items.size():
			var it: ItemData = eq_items[slot_idx]
			slot_btn.text = it.name.substr(0, 3).to_upper() if not it.icon else ""
			slot_btn.icon = it.icon
			var it_style := StyleBoxFlat.new()
			it_style.bg_color = Color("#1e293b")
			it_style.border_color = Color("#f59e0b") if not it.is_component() else Color("#06b6d4")
			it_style.border_width_left = 2
			it_style.border_width_top = 2
			it_style.border_width_right = 2
			it_style.border_width_bottom = 2
			it_style.corner_radius_top_left = 4
			it_style.corner_radius_top_right = 4
			it_style.corner_radius_bottom_left = 4
			it_style.corner_radius_bottom_right = 4
			slot_btn.add_theme_stylebox_override("normal", it_style)
			slot_btn.add_theme_stylebox_override("hover", it_style)
			slot_btn.add_theme_stylebox_override("pressed", it_style)
			var tt := "%s\n\n%s" % [it.name, it.description]
			var stats_t := it.get_formatted_stats_text()
			if not stats_t.is_empty():
				tt += "\n\n" + stats_t
			slot_btn.tooltip_text = tt
		else:
			slot_btn.text = "+"
			slot_btn.icon = null
			var empty_style := StyleBoxFlat.new()
			empty_style.bg_color = Color(0.06, 0.08, 0.12, 0.6)
			empty_style.border_color = Color("#334155")
			empty_style.border_width_left = 1
			empty_style.border_width_top = 1
			empty_style.border_width_right = 1
			empty_style.border_width_bottom = 1
			empty_style.corner_radius_top_left = 4
			empty_style.corner_radius_top_right = 4
			empty_style.corner_radius_bottom_left = 4
			empty_style.corner_radius_bottom_right = 4
			slot_btn.add_theme_stylebox_override("normal", empty_style)
			slot_btn.add_theme_stylebox_override("hover", empty_style)
			slot_btn.add_theme_stylebox_override("pressed", empty_style)
			slot_btn.tooltip_text = "Slot de Item Vazio (%d/2)\nEquipe um item arrastando-o da bandeja." % [slot_idx + 1]

	var ability_panel = vbox.find_child("TFT_AbilityPanel", false, false) as PanelContainer
	if not ability_panel:
		ability_panel = PanelContainer.new()
		ability_panel.name = "TFT_AbilityPanel"
		var ab_style := StyleBoxFlat.new()
		ab_style.bg_color = Color(0.06, 0.08, 0.14, 0.85)
		ab_style.border_color = Color("#334155")
		ab_style.border_width_left = 1
		ab_style.border_width_top = 1
		ab_style.border_width_right = 1
		ab_style.border_width_bottom = 1
		ab_style.corner_radius_top_left = 6
		ab_style.corner_radius_top_right = 6
		ab_style.corner_radius_bottom_left = 6
		ab_style.corner_radius_bottom_right = 6
		ab_style.content_margin_left = 8
		ab_style.content_margin_top = 5
		ab_style.content_margin_right = 8
		ab_style.content_margin_bottom = 5
		ability_panel.add_theme_stylebox_override("panel", ab_style)

		var ab_vbox := VBoxContainer.new()
		ab_vbox.name = "AbVBox"
		ab_vbox.add_theme_constant_override("separation", 2)

		var title_lbl := RichTextLabel.new()
		title_lbl.name = "AbTitleLabel"
		title_lbl.bbcode_enabled = true
		title_lbl.fit_content = true
		title_lbl.scroll_active = false
		title_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		ab_vbox.add_child(title_lbl)

		var vals_lbl := RichTextLabel.new()
		vals_lbl.name = "AbValuesLabel"
		vals_lbl.bbcode_enabled = true
		vals_lbl.fit_content = true
		vals_lbl.scroll_active = false
		vals_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		ab_vbox.add_child(vals_lbl)

		var desc_lbl := RichTextLabel.new()
		desc_lbl.name = "AbDescLabel"
		desc_lbl.bbcode_enabled = true
		desc_lbl.fit_content = true
		desc_lbl.scroll_active = false
		desc_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		ab_vbox.add_child(desc_lbl)

		ability_panel.add_child(ab_vbox)
		vbox.add_child(ability_panel)
		vbox.move_child(ability_panel, tactical_row.get_index() + 1)

	var stats_grid = vbox.find_child("TFT_StatsGrid", false, false) as GridContainer
	if not stats_grid:
		stats_grid = GridContainer.new()
		stats_grid.name = "TFT_StatsGrid"
		stats_grid.columns = 4
		stats_grid.add_theme_constant_override("h_separation", 4)
		stats_grid.add_theme_constant_override("v_separation", 4)
		vbox.add_child(stats_grid)
		vbox.move_child(stats_grid, ability_panel.get_index() + 1)

static func _on_ability_btn_entered(panel: Control) -> void:
	if is_instance_valid(_inspected_unit):
		_show_ability_floating_card(_inspected_unit, panel)

static func _get_or_create_ability_floating_card(control_parent: Control) -> PanelContainer:
	if is_instance_valid(_ability_floating_card):
		return _ability_floating_card

	var card := PanelContainer.new()
	card.name = "AbilityFloatingCard"
	card.top_level = true
	card.set_anchors_preset(Control.PRESET_TOP_LEFT)
	card.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	card.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	card.z_index = 35
	card.visible = false
	card.mouse_filter = Control.MOUSE_FILTER_PASS

	var card_style := StyleBoxFlat.new()
	card_style.bg_color = Color("#0f172a")
	card_style.border_color = Color("#8b5cf6")
	card_style.border_width_left = 2
	card_style.border_width_top = 2
	card_style.border_width_right = 2
	card_style.border_width_bottom = 2
	card_style.corner_radius_top_left = 8
	card_style.corner_radius_top_right = 8
	card_style.corner_radius_bottom_left = 8
	card_style.corner_radius_bottom_right = 8
	card_style.content_margin_left = 12
	card_style.content_margin_top = 10
	card_style.content_margin_right = 12
	card_style.content_margin_bottom = 10
	card_style.shadow_color = Color(0, 0, 0, 0.75)
	card_style.shadow_size = 12
	card.add_theme_stylebox_override("panel", card_style)

	var vbox := VBoxContainer.new()
	vbox.name = "CardVBox"
	vbox.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	vbox.add_theme_constant_override("separation", 6)
	card.add_child(vbox)

	control_parent.add_child(card)
	_ability_floating_card = card
	return card

static func _hide_ability_floating_card() -> void:
	if is_instance_valid(_ability_floating_card):
		_ability_floating_card.visible = false

static func _show_ability_floating_card(unit: BaseUnit3D, panel: Control) -> void:
	if not is_instance_valid(unit) or not unit.stats or not is_instance_valid(panel):
		return
	var card := _get_or_create_ability_floating_card(panel.get_parent() as Control)
	var vbox := card.get_node("CardVBox") as VBoxContainer
	for child in vbox.get_children():
		child.queue_free()

	var stats := unit.stats
	var star := clampi(unit.star_level, 1, 4)

	var header_hbox := HBoxContainer.new()
	header_hbox.add_theme_constant_override("separation", 10)

	var icon_rect := TextureRect.new()
	icon_rect.texture = stats.icon
	icon_rect.custom_minimum_size = Vector2(34, 34)
	icon_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon_rect.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	header_hbox.add_child(icon_rect)

	var title_vbox := VBoxContainer.new()
	title_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_vbox.add_theme_constant_override("separation", 2)

	var name_lbl := Label.new()
	name_lbl.text = stats.ability_name
	name_lbl.add_theme_font_size_override("font_size", 13)
	name_lbl.add_theme_color_override("font_color", Color("#f8fafc"))
	title_vbox.add_child(name_lbl)

	var badges_hbox := HBoxContainer.new()
	badges_hbox.add_theme_constant_override("separation", 6)

	var dmg_type_str := "Mágico"
	var dmg_color := Color("#c084fc")
	match stats.ability_damage_type:
		UnitStats.DamageType.PHYSICAL:
			dmg_type_str = "Físico"
			dmg_color = Color("#fb923c")
		UnitStats.DamageType.MAGICAL:
			dmg_type_str = "Mágico"
			dmg_color = Color("#c084fc")
		UnitStats.DamageType.TRUE:
			dmg_type_str = "Verdadeiro"
			dmg_color = Color("#facc15")

	var type_badge := Label.new()
	type_badge.text = "[ %s ]" % dmg_type_str
	type_badge.add_theme_font_size_override("font_size", 10)
	type_badge.add_theme_color_override("font_color", dmg_color)
	badges_hbox.add_child(type_badge)

	if stats.max_mana > 0:
		var mana_badge := Label.new()
		mana_badge.text = "%d Mana" % int(stats.max_mana)
		mana_badge.add_theme_font_size_override("font_size", 10)
		mana_badge.add_theme_color_override("font_color", Color("#67e8f9"))
		badges_hbox.add_child(mana_badge)

	title_vbox.add_child(badges_hbox)
	header_hbox.add_child(title_vbox)
	vbox.add_child(header_hbox)

	var ab_info := get_ability_info(stats, unit, star)

	var desc_lbl := RichTextLabel.new()
	desc_lbl.bbcode_enabled = true
	desc_lbl.fit_content = true
	desc_lbl.scroll_active = false
	desc_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	desc_lbl.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	desc_lbl.text = "[color=#cbd5e1]%s[/color]" % ab_info["desc"]
	desc_lbl.custom_minimum_size = Vector2(256, 0)
	vbox.add_child(desc_lbl)

	if not ab_info["lines"].is_empty():
		var vals_panel := PanelContainer.new()
		var vp_style := StyleBoxFlat.new()
		vp_style.bg_color = Color(0.04, 0.06, 0.12, 0.85)
		vp_style.border_color = Color("#1e293b")
		vp_style.border_width_left = 1
		vp_style.border_width_top = 1
		vp_style.border_width_right = 1
		vp_style.border_width_bottom = 1
		vp_style.corner_radius_top_left = 5
		vp_style.corner_radius_top_right = 5
		vp_style.corner_radius_bottom_left = 5
		vp_style.corner_radius_bottom_right = 5
		vp_style.content_margin_left = 8
		vp_style.content_margin_top = 6
		vp_style.content_margin_right = 8
		vp_style.content_margin_bottom = 6
		vals_panel.add_theme_stylebox_override("panel", vp_style)

		var vals_lbl := RichTextLabel.new()
		vals_lbl.bbcode_enabled = true
		vals_lbl.fit_content = true
		vals_lbl.scroll_active = false
		vals_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		vals_lbl.text = "\n".join(ab_info["lines"])
		vals_panel.add_child(vals_lbl)
		vbox.add_child(vals_panel)

	card.custom_minimum_size = Vector2(280, 0)
	card.reset_size()

	var panel_rect: Rect2 = panel.get_global_rect()
	var tactical_row: Control = panel.find_child("TFT_TacticalRow", true, false) as Control
	var anchor_y: float = tactical_row.global_position.y if tactical_row else panel_rect.position.y + 120.0
	var card_x: float = panel_rect.position.x - card.size.x - 12.0
	var viewport_h: float = panel.get_viewport().get_visible_rect().size.y
	var max_y: float = maxf(viewport_h - card.size.y - 12.0, 10.0)
	var card_y: float = clampf(anchor_y - 10.0, 10.0, max_y)
	card.global_position = Vector2(card_x, card_y)
	card.show()
	card.modulate.a = 0.0
	var tw := card.create_tween()
	tw.tween_property(card, "modulate:a", 1.0, 0.15)
