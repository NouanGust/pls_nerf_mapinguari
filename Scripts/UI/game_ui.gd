class_name GameUI
extends CanvasLayer

const UIStyle = preload("res://Scripts/UI/ui_style.gd")

signal hud_visibility_changed(is_visible: bool)

@onready var hud: Control = $Control
@onready var top_bar: Control = $Control/TopBar
@onready var bottom_bar: Control = $Control/BottomBar
@onready var bench_panel: Control = $Control/BenchPanel
@onready var health_widget: Control = get_node_or_null("Control/HealthWidget")
@onready var right_bar: Control = $Control/RightBar
@onready var toggle_button: Button = $HUDToggleButton

# Elementos do TopBar (TFT)
@onready var round_label: Label = get_node_or_null("Control/TopBar/Content/RoundBox/RoundLabel")
@onready var phase_label: Label = get_node_or_null("Control/TopBar/Content/RoundBox/PhaseLabel")
@onready var timer_label: Label = get_node_or_null("Control/TopBar/Content/TimerBox/TimerLabel")
@onready var milestones_container: HBoxContainer = get_node_or_null("Control/TopBar/Content/MilestonesContainer")
@onready var enemy_level_label: Label = get_node_or_null("Control/TopBar/Content/EnemyBox/EnemyLevelLabel")

# Elementos de Status
@onready var board_count_label: Label = get_node_or_null("Control/BoardCountLabel")
@onready var region_label: Label = get_node_or_null("Control/RegionLabel")

# Elementos de Vida (HP - Canto Inferior Direito)
@onready var health_label: Label = get_node_or_null("Control/HealthWidget/Content/VBox/Header/HealthLabel")
@onready var health_bar: ProgressBar = get_node_or_null("Control/HealthWidget/Content/VBox/HealthProgressBar")

# Elementos de Loja e Banco
@onready var shop: ShopUI = get_node_or_null("Control/BottomBar/ShopContainer") as ShopUI
@onready var bench: BenchUI = get_node_or_null("Control/BenchPanel/BenchContent/BenchSlots") as BenchUI

var hud_visible := true
var hud_tween: Tween
var visible_positions: Dictionary = {}
var sell_zone: PanelContainer

# Sinergias
var synergy_button: Button
var synergy_panel: Control
var synergy_list: VBoxContainer
var synergy_row_active_template: PanelContainer
var synergy_row_inactive_template: PanelContainer
var spawned_synergy_rows: Array[Control] = []
var synergy_tooltip: PanelContainer
var _synergy_tooltip_origin: Vector2 = Vector2.ZERO

var _responsive_ready: bool = false
var _compact_layout: bool = false
var _inspector_tween: Tween
var _milestone_icons: Array[Label] = []

func _ready() -> void:
	_apply_button_skins()
	_build_sell_zone()
	_bind_synergy_panel()
	_setup_milestones()
	_setup_inspector()
	_responsive_ready = true
	
	if toggle_button:
		toggle_button.pressed.connect(toggle_hud)
		UIStyle.apply_button_skin(toggle_button, UIStyle.BORDER_SLATE)
	
	get_viewport().size_changed.connect(_layout_extra_panels)
	await get_tree().process_frame
	_layout_extra_panels()
	_cache_panel_positions()
	_play_hud_transition(true, true)

func _setup_milestones() -> void:
	if not milestones_container:
		return
	for child in milestones_container.get_children():
		child.queue_free()
	_milestone_icons.clear()
	
	for i in 5:
		var marker := Label.new()
		marker.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		marker.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		marker.add_theme_font_size_override("font_size", 14 if i < 4 else 16)
		marker.text = "◆" if i < 4 else "👑"
		marker.mouse_filter = Control.MOUSE_FILTER_IGNORE
		milestones_container.add_child(marker)
		_milestone_icons.append(marker)
	
	update_round_display(1, false, 0.0, false, {})

func update_enemy_level(level: int) -> void:
	if not enemy_level_label:
		enemy_level_label = get_node_or_null("Control/TopBar/Content/EnemyBox/EnemyLevelLabel")
	if enemy_level_label:
		enemy_level_label.text = "INIMIGO NV. %d" % level
		enemy_level_label.tooltip_text = "Nível da equipe inimiga: %d\nInimigos evoluem nos marcos regionais." % level

func update_board_capacity(units_on_board: int, board_limit: int) -> void:
	if shop:
		shop.update_board_capacity(units_on_board, board_limit)
	if board_count_label:
		var available := maxi(0, board_limit - units_on_board)
		board_count_label.text = "NO CAMPO · %d / %d (%d livres)" % [units_on_board, board_limit, available]

func update_round_display(current_round: int, in_combat: bool, time_remaining: float, is_pending: bool, round_outcomes: Dictionary = {}) -> void:
	# Cálculo de estágio no estilo TFT (1-1, 1-2, 1-3, 1-4, 1-5...)
	var stage_index := floori(float(current_round - 1) / 5.0) + 1
	var stage_sub := ((current_round - 1) % 5) + 1
	var stage_text := "%d-%d" % [stage_index, stage_sub]
	
	if round_label:
		round_label.text = stage_text
		round_label.tooltip_text = "Estágio %s · Round total: %d" % [stage_text, current_round]
	
	# Legado
	var legacy_round := get_node_or_null("Control/TopBar/LegacyNodes/RoundLabel") as Label
	if legacy_round:
		legacy_round.text = "Round: %d" % current_round
	
	# Fase
	if phase_label:
		if in_combat:
			phase_label.text = "COMBATE"
			phase_label.add_theme_color_override("font_color", Color("#ff6b6b"))
		elif is_pending:
			phase_label.text = "RESULTADO"
			phase_label.add_theme_color_override("font_color", UIStyle.TEXT_GOLD_BRIGHT)
		else:
			phase_label.text = "PREP"
			phase_label.add_theme_color_override("font_color", UIStyle.TEXT_CYAN)
	
	# Cronômetro
	if timer_label:
		if in_combat:
			timer_label.text = "%02ds" % ceili(time_remaining)
			timer_label.add_theme_color_override("font_color", UIStyle.TEXT_CYAN)
		elif is_pending:
			timer_label.text = "FIM"
			timer_label.add_theme_color_override("font_color", UIStyle.TEXT_GOLD_BRIGHT)
		else:
			timer_label.text = "PREP"
			timer_label.add_theme_color_override("font_color", UIStyle.TEXT_GOLD)
	
	# Marcos de Round (Milestones)
	if not _milestone_icons.is_empty():
		var active_step := ((current_round - 1) % 5)
		for i in _milestone_icons.size():
			var icon := _milestone_icons[i]
			var is_boss := (i == 4)
			var round_for_step := (stage_index - 1) * 5 + 1 + i
			if i < active_step:
				# Passado (concluído) - Verde para vitórias, vermelho para derrotas
				var won: bool = round_outcomes.get(round_for_step, true)
				icon.text = "●" if not is_boss else "★"
				if won:
					icon.add_theme_color_override("font_color", Color("#2ecc71"))  # Verde vitória vibrante
					icon.tooltip_text = "Round %d: Vitória ✓" % round_for_step
				else:
					icon.add_theme_color_override("font_color", Color("#e74c3c"))  # Vermelho derrota vibrante
					icon.tooltip_text = "Round %d: Derrota ✕" % round_for_step
			elif i == active_step:
				# Atual (ativo / em destaque)
				icon.text = "◆" if not is_boss else "👑"
				icon.add_theme_color_override("font_color", UIStyle.BORDER_CYAN if in_combat else UIStyle.TEXT_GOLD_BRIGHT)
				icon.tooltip_text = "Round %d: Em andamento (%s)" % [round_for_step, "Combate" if in_combat else "Preparação"]
			else:
				# Futuro
				icon.text = "○" if not is_boss else "☆"
				icon.add_theme_color_override("font_color", Color(0.35, 0.45, 0.52, 0.45))
				icon.tooltip_text = "Round %d: %s" % [round_for_step, "Chefe Regional" if is_boss else "Próximo Combate"]

func update_player_stats(gold: int, health: int, level: int, xp: int, required_xp: int) -> void:
	var is_max_level := level >= 9
	
	# Atualizar Loja (Ouro e Nível)
	if shop:
		shop.update_player_info(gold, level, xp, required_xp, is_max_level)
	
	# Atualizar Vida (Canto Inferior Direito)
	if health_label:
		health_label.text = "%d" % health
		if health >= 60:
			health_label.add_theme_color_override("font_color", UIStyle.TEXT_HEALTH)
		elif health >= 30:
			health_label.add_theme_color_override("font_color", Color("#f39c12"))
		else:
			health_label.add_theme_color_override("font_color", Color("#e74c3c"))
	
	if health_bar:
		health_bar.max_value = 100
		health_bar.value = clampi(health, 0, 100)
		var fill_style := health_bar.get_theme_stylebox("fill") as StyleBoxFlat
		if fill_style:
			if health >= 60:
				fill_style.bg_color = UIStyle.TEXT_HEALTH
			elif health >= 30:
				fill_style.bg_color = Color("#f39c12")
			else:
				fill_style.bg_color = Color("#e74c3c")
	
	# Compatibilidade com referências legadas
	var leg_gold := get_node_or_null("Control/TopBar/LegacyNodes/GoldLabel") as Label
	if leg_gold:
		leg_gold.text = "Ouro: %d" % gold
	var leg_hp := get_node_or_null("Control/TopBar/LegacyNodes/HealthLabel") as Label
	if leg_hp:
		leg_hp.text = "HP: %d" % health
	var leg_lvl := get_node_or_null("Control/TopBar/LegacyNodes/LevelLabel") as Label
	if leg_lvl:
		leg_lvl.text = "Nível %d" % level

func toggle_hud() -> void:
	hud_visible = not hud_visible
	if not hud_visible and is_instance_valid(synergy_tooltip):
		synergy_tooltip.hide()
	toggle_button.text = "HUD" if hud_visible else "+ UI"
	toggle_button.tooltip_text = "Ocultar interface (H)" if hud_visible else "Mostrar interface (H)"
	_play_hud_transition(hud_visible)
	hud_visibility_changed.emit(hud_visible)

func _cache_panel_positions() -> void:
	visible_positions[top_bar] = top_bar.position
	visible_positions[bottom_bar] = bottom_bar.position
	visible_positions[bench_panel] = bench_panel.position
	if health_widget:
		visible_positions[health_widget] = health_widget.position
	visible_positions[right_bar] = right_bar.position

func _play_hud_transition(show_hud: bool, initial: bool = false) -> void:
	if hud_tween and hud_tween.is_running():
		hud_tween.kill()

	if show_hud:
		hud.show()
		if initial:
			hud.modulate.a = 0.0
			_set_hidden_positions()
	else:
		hud.show()

	hud_tween = create_tween()
	hud_tween.set_parallel(true)
	hud_tween.set_trans(Tween.TRANS_CUBIC)
	hud_tween.set_ease(Tween.EASE_OUT if show_hud else Tween.EASE_IN)
	hud_tween.tween_property(hud, "modulate:a", 1.0 if show_hud else 0.0, 0.26)
	
	var animated_panels := [top_bar, bottom_bar]
	if health_widget:
		animated_panels.append(health_widget)
	
	for panel in animated_panels:
		var destination: Vector2 = visible_positions.get(panel, panel.position)
		if not show_hud:
			destination = _hidden_position(panel)
		hud_tween.tween_property(panel, "position", destination, 0.3)

	if right_bar.visible:
		var right_destination: Vector2 = visible_positions[right_bar]
		if not show_hud:
			right_destination = _hidden_position(right_bar)
		hud_tween.tween_property(right_bar, "position", right_destination, 0.3)

	if not show_hud:
		hud_tween.set_parallel(false)
		hud_tween.tween_callback(hud.hide)

func _set_hidden_positions() -> void:
	top_bar.position = _hidden_position(top_bar)
	for panel in [bottom_bar]:
		panel.position = _hidden_position(panel)
	if health_widget:
		health_widget.position = _hidden_position(health_widget)
	if right_bar.visible:
		right_bar.position = _hidden_position(right_bar)

func _hidden_position(panel: Control) -> Vector2:
	var destination: Vector2 = visible_positions.get(panel, panel.position)
	if panel == top_bar:
		destination.y = - panel.size.y - 20.0
	elif panel == right_bar or panel == health_widget:
		destination.x = get_viewport().get_visible_rect().size.x + 20.0
	else:
		destination.y = get_viewport().get_visible_rect().size.y + 20.0
	return destination

func _apply_button_skins() -> void:
	synergy_button = hud.get_node_or_null("SynergyToggleButton") as Button
	if synergy_button:
		UIStyle.apply_button_skin(synergy_button, UIStyle.BORDER_GOLD)

func get_sell_zone() -> Control:
	return sell_zone

func set_sell_zone_visible(p_visible: bool) -> void:
	if is_instance_valid(sell_zone):
		sell_zone.visible = p_visible

func update_synergies(synergies: Array) -> void:
	var active_count := 0
	var ordered := synergies.duplicate()
	ordered.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		if bool(a.get("active", false)) != bool(b.get("active", false)):
			return bool(a.get("active", false))
		var a_progress := float(a.count) / maxf(float(a.threshold), 1.0)
		var b_progress := float(b.count) / maxf(float(b.threshold), 1.0)
		if not is_equal_approx(a_progress, b_progress):
			return a_progress > b_progress
		return str(a.name) < str(b.name)
	)
	for synergy in ordered:
		if synergy.get("active", false):
			active_count += 1
	if is_instance_valid(synergy_button):
		synergy_button.text = "Sinergias · %d" % active_count
	if not is_instance_valid(synergy_list) or (not is_instance_valid(synergy_row_active_template) and not is_instance_valid(synergy_row_inactive_template)):
		return
	if is_instance_valid(synergy_tooltip):
		synergy_tooltip.hide()
	for row in spawned_synergy_rows:
		if is_instance_valid(row):
			row.queue_free()
	spawned_synergy_rows.clear()
	
	for synergy in ordered:
		var is_active: bool = synergy.get("active", false)
		var template := synergy_row_active_template if is_active else synergy_row_inactive_template
		if not is_instance_valid(template):
			template = synergy_row_inactive_template if is_active else synergy_row_active_template
		if not is_instance_valid(template):
			continue
		var row := template.duplicate() as PanelContainer
		row.custom_minimum_size.y = 44
		var icon_node := row.get_node_or_null("Row/Icon")
		if icon_node:
			icon_node.hide()
		row.name = "Synergy_%s_%s" % [str(synergy.category).replace(" ", ""), str(synergy.name).replace(" ", "_")]
		row.show()
		var title := row.get_node_or_null("Row/Content/Header/TagLabel") as Label
		var progress_text := row.get_node_or_null("Row/Content/Header/CountLabel") as Label
		var progress := row.get_node_or_null("Row/Content/Progress") as ProgressBar
		if title:
			title.text = str(synergy.name)
			title.add_theme_font_size_override("font_size", 14)
			title.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		if progress_text:
			progress_text.add_theme_font_size_override("font_size", 13)
			progress_text.text = "%s%d/%d" % ["✓ " if is_active else "", synergy.count, synergy.threshold]
		if progress:
			progress.max_value = maxi(int(synergy.threshold), 1)
			progress.value = mini(int(synergy.count), int(synergy.threshold))
		
		# Tooltip padrao desabilitado para usar exclusivamente o SynergyTooltip estilizado
		row.tooltip_text = ""
		row.mouse_filter = Control.MOUSE_FILTER_STOP
		row.mouse_entered.connect(_on_synergy_row_hover_started.bind(synergy, row))
		row.mouse_exited.connect(_on_synergy_row_hover_ended)
		
		synergy_list.add_child(row)
		spawned_synergy_rows.append(row)
	_fit_synergy_height.call_deferred()

func _fit_synergy_height() -> void:
	if synergy_panel:
		var metrics := ResponsiveLayout.battle_metrics(get_viewport().get_visible_rect().size)
		var available := maxf(float(metrics["bench_top"]) - synergy_panel.position.y - 8.0, 68.0)
		synergy_panel.size.y = clampf(spawned_synergy_rows.size() * 50.0 + 16.0, 68.0, minf(440.0, available))

func _bind_synergy_panel() -> void:
	synergy_button = hud.get_node_or_null("SynergyToggleButton") as Button
	synergy_panel = hud.get_node_or_null("SynergyPanel") as Control
	synergy_list = hud.get_node_or_null("SynergyPanel/ScrollContainer/SynergyList") as VBoxContainer
	synergy_row_active_template = synergy_list.get_node_or_null("SynergyRowTemplateActive") as PanelContainer if synergy_list else null
	synergy_row_inactive_template = synergy_list.get_node_or_null("SynergyRowTemplateInactive") as PanelContainer if synergy_list else null
	_ensure_synergy_tooltip()
	if synergy_button and synergy_panel and not synergy_button.pressed.is_connected(_toggle_synergy_panel):
		synergy_button.pressed.connect(_toggle_synergy_panel)
	update_synergies([])

func _toggle_synergy_panel() -> void:
	if is_instance_valid(synergy_tooltip):
		synergy_tooltip.hide()
	if is_instance_valid(synergy_panel):
		synergy_panel.visible = not synergy_panel.visible

func _ensure_synergy_tooltip() -> void:
	if not is_instance_valid(synergy_tooltip) and is_instance_valid(hud):
		synergy_tooltip = hud.get_node_or_null("SynergyTooltip") as PanelContainer
	if not is_instance_valid(synergy_tooltip) and is_instance_valid(hud):
		synergy_tooltip = PanelContainer.new()
		synergy_tooltip.name = "SynergyTooltip"
		synergy_tooltip.z_index = 10
		synergy_tooltip.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var style := UIStyle.make_panel_style(UIStyle.BORDER_GOLD)
		style.shadow_color = Color(0, 0, 0, 0.5)
		style.shadow_size = 8
		synergy_tooltip.add_theme_stylebox_override("panel", style)
		
		var vbox := VBoxContainer.new()
		vbox.name = "VBoxContainer"
		vbox.add_theme_constant_override("separation", 4)
		vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
		synergy_tooltip.add_child(vbox)
		
		var t_title := RichTextLabel.new()
		t_title.name = "Tooltip_title"
		t_title.bbcode_enabled = true
		t_title.fit_content = true
		t_title.mouse_filter = Control.MOUSE_FILTER_IGNORE
		t_title.add_theme_font_size_override("normal_font_size", 14)
		vbox.add_child(t_title)
		
		var t_status := RichTextLabel.new()
		t_status.name = "Tooltip_status"
		t_status.bbcode_enabled = true
		t_status.fit_content = true
		t_status.mouse_filter = Control.MOUSE_FILTER_IGNORE
		t_status.add_theme_font_size_override("normal_font_size", 12)
		vbox.add_child(t_status)
		
		var t_desc := RichTextLabel.new()
		t_desc.name = "Tooltip_desc"
		t_desc.bbcode_enabled = true
		t_desc.fit_content = true
		t_desc.mouse_filter = Control.MOUSE_FILTER_IGNORE
		t_desc.add_theme_font_size_override("normal_font_size", 12)
		vbox.add_child(t_desc)
		
		var t_units := RichTextLabel.new()
		t_units.name = "Tooltip_units"
		t_units.bbcode_enabled = true
		t_units.fit_content = true
		t_units.mouse_filter = Control.MOUSE_FILTER_IGNORE
		t_units.add_theme_font_size_override("normal_font_size", 11)
		vbox.add_child(t_units)
		
		hud.add_child(synergy_tooltip)
	if is_instance_valid(synergy_tooltip):
		synergy_tooltip.mouse_filter = Control.MOUSE_FILTER_IGNORE
		synergy_tooltip.hide()

func _on_synergy_row_hover_started(synergy: Dictionary, row: Control) -> void:
	_ensure_synergy_tooltip()
	if not is_instance_valid(synergy_tooltip):
		return
	_update_synergy_tooltip_content(synergy)
	var panel_global: Vector2 = synergy_panel.global_position if is_instance_valid(synergy_panel) else row.global_position
	var panel_width: float = synergy_panel.size.x if is_instance_valid(synergy_panel) else row.size.x
	_synergy_tooltip_origin = Vector2(panel_global.x + panel_width + 12.0, row.global_position.y)
	synergy_tooltip.show()
	_fit_synergy_tooltip.call_deferred()

func _on_synergy_row_hover_ended() -> void:
	if is_instance_valid(synergy_tooltip):
		synergy_tooltip.hide()

func _fit_synergy_tooltip() -> void:
	if not is_instance_valid(synergy_tooltip) or not synergy_tooltip.visible:
		return
	var viewport_size := get_viewport().get_visible_rect().size
	synergy_tooltip.set_anchors_preset(Control.PRESET_TOP_LEFT)
	synergy_tooltip.custom_minimum_size.x = clampf(300.0, 240.0, viewport_size.x - 30.0)
	var vbox := synergy_tooltip.get_node_or_null("VBoxContainer")
	if vbox:
		vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	synergy_tooltip.reset_size()
	ResponsiveLayout.clamp_popup(synergy_tooltip, _synergy_tooltip_origin, viewport_size)

func _update_synergy_tooltip_content(synergy: Dictionary) -> void:
	if not is_instance_valid(synergy_tooltip):
		return
	var vbox := synergy_tooltip.get_node_or_null("VBoxContainer")
	if not vbox:
		return
	var title_lbl := vbox.get_node_or_null("Tooltip_title") as RichTextLabel
	var status_lbl := vbox.get_node_or_null("Tooltip_status") as RichTextLabel
	var desc_lbl := vbox.get_node_or_null("Tooltip_desc") as RichTextLabel
	var units_lbl := vbox.get_node_or_null("Tooltip_units") as RichTextLabel

	var is_active: bool = synergy.get("active", false)
	var count: int = int(synergy.get("count", 0))
	var threshold: int = int(synergy.get("threshold", 1))
	var cat_color := "#74e6f5" if str(synergy.get("category", "")) == "Origem" else "#ffd16b"

	if title_lbl:
		title_lbl.text = "[b][color=#f5da80]%s[/color][/b] [color=%s]· %s[/color]" % [
			str(synergy.get("name", "Sinergia")),
			cat_color,
			str(synergy.get("category", "Sinergia"))
		]

	if status_lbl:
		var status_text: String
		if is_active:
			status_text = "[color=#2ecc71]● Ativa[/color] [color=#c5ddff](%d/%d)[/color]" % [count, threshold]
		else:
			var needed := maxi(threshold - count, 0)
			status_text = "[color=#e74c3c]○ Inativa[/color] [color=#8fa3b0](faltam %d peça%s · %d/%d)[/color]" % [
				needed, "s" if needed > 1 else "", count, threshold
			]
		var thresholds: Array = synergy.get("thresholds", [])
		if not thresholds.is_empty():
			var milestones_parts: Array[String] = []
			for t in thresholds:
				var t_val := int(t)
				if count >= t_val:
					milestones_parts.append("[b][color=#2ecc71](%d)[/color][/b]" % t_val)
				else:
					milestones_parts.append("[color=#5e7585]%d[/color]" % t_val)
			status_text += "  ·  [color=#8fa3b0]Marcos:[/color] %s" % " → ".join(milestones_parts)
		status_lbl.text = status_text

	if desc_lbl:
		var desc: String = str(synergy.get("description", ""))
		desc_lbl.text = "[color=#ffd32a]Efeito:[/color] %s" % (desc if not desc.is_empty() else "Nenhum bônus adicional.")

	if units_lbl:
		var units: Array = synergy.get("units", [])
		if not units.is_empty():
			units_lbl.text = "[color=#74e6f5]Integrantes (%d):[/color] %s\n[color=#5e7585][i]Cada campeão único no tabuleiro conta 1 vez.[/i][/color]" % [
				units.size(), ", ".join(units)
			]
		else:
			units_lbl.text = "[color=#5e7585][i]Cada campeão único no tabuleiro conta 1 vez.[/i][/color]"

func _build_sell_zone() -> void:
	sell_zone = PanelContainer.new()
	sell_zone.name = "SellDropZone"
	sell_zone.mouse_filter = Control.MOUSE_FILTER_STOP
	sell_zone.custom_minimum_size = Vector2(260, 56)
	sell_zone.size = sell_zone.custom_minimum_size
	var style := StyleBoxFlat.new()
	style.bg_color = Color("#4a1b1b", 0.96)
	style.border_color = Color("#e74c3c")
	style.set_border_width_all(2)
	style.set_corner_radius_all(5)
	style.shadow_color = Color(0, 0, 0, 0.4)
	style.shadow_size = 6
	sell_zone.add_theme_stylebox_override("panel", style)
	var label := _make_info_label("VENDER UNIDADE\nSolte aqui ou pressione S", 13, Color("#ffe6ca"))
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	sell_zone.add_child(label)
	hud.add_child(sell_zone)
	sell_zone.hide()

func _make_info_label(text: String, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_outline_color", Color("#0a0f14"))
	label.add_theme_constant_override("outline_size", 3)
	return label

func _layout_extra_panels() -> void:
	if not is_instance_valid(hud) or not _responsive_ready:
		return
	if hud_tween and hud_tween.is_running():
		hud_tween.kill()
	if _inspector_tween and _inspector_tween.is_running():
		_inspector_tween.kill()
	
	var viewport_size: Vector2 = get_viewport().get_visible_rect().size
	var metrics := ResponsiveLayout.battle_metrics(viewport_size)
	var compact: bool = metrics["compact"]
	
	# 1. TopBar Centralizado (TFT)
	var top_w := minf(520.0, viewport_size.x - 40.0)
	ResponsiveLayout.place(top_bar, Rect2((viewport_size.x - top_w) * 0.5, 12.0, top_w, 56.0))
	
	## 2. Informações sob o TopBar (No Campo & Região)
	#ResponsiveLayout.place(board_count_label, Rect2((viewport_size.x - 260.0) * 0.5, 72.0, 260.0, 22.0))
	#ResponsiveLayout.place(region_label, Rect2((viewport_size.x - 400.0) * 0.5, 94.0, 400.0, 20.0))
	#if region_label:
		#region_label.clip_text = true
		#region_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	
	# 3. Sinergias (Lateral Esquerda)
	ResponsiveLayout.place(synergy_button, Rect2(14.0, 12.0, 140.0, 36.0))
	var synergy_top := 54.0
	ResponsiveLayout.place(synergy_panel, Rect2(14.0, synergy_top, 240.0, 70.0))
	if compact != _compact_layout:
		synergy_panel.visible = not compact
	_compact_layout = compact
	_fit_synergy_height()
	
	# 4. HUD e Pausa (Topo Direito)
	ResponsiveLayout.place(toggle_button, Rect2(viewport_size.x - 68.0, 12.0, 54.0, 36.0))
	var pause := get_node_or_null("PauseButton") as Button
	if pause:
		pause.custom_minimum_size.y = 36.0
		ResponsiveLayout.place(pause, Rect2(viewport_size.x - 180.0, 12.0, 106.0, 36.0))
		UIStyle.apply_button_skin(pause, UIStyle.BORDER_SLATE)
	
	# 5. Banco de Unidades 2D oculto (usando agora o banco 3D no modelo)
	if bench_panel:
		bench_panel.visible = false
		bench_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	# 6. Loja (Barra Inferior) com respiro nas bordas
	var bar_margin_x := 18.0 if not compact else 8.0
	var bar_margin_bottom := 10.0
	var shop_h: float = metrics["shop_height"]
	var shop_top: float = viewport_size.y - shop_h - bar_margin_bottom
	var bar_w := viewport_size.x - (bar_margin_x * 2.0)
	ResponsiveLayout.place(bottom_bar, Rect2(bar_margin_x, shop_top, bar_w, shop_h))
	
	# Layout interno da barra inferior
	var controls := bottom_bar.get_node_or_null("ControlsContainer") as Control
	var gold_cont := bottom_bar.get_node_or_null("GoldContainer") as Control
	var shop_btn := bottom_bar.get_node_or_null("ShopLabel") as Control
	var lock_btn := bottom_bar.get_node_or_null("LockButton") as Button
	if not lock_btn and controls:
		lock_btn = controls.get_node_or_null("LockButton") as Button
	
	var controls_w := 216.0
	if controls:
		ResponsiveLayout.place(controls, Rect2(16.0, 46.0, controls_w, shop_h - 54.0))
	if gold_cont:
		ResponsiveLayout.place(gold_cont, Rect2(16.0, 10.0, 104.0, 32.0))
	if lock_btn:
		ResponsiveLayout.place(lock_btn, Rect2(126.0, 10.0, 106.0, 32.0))
	if shop_btn:
		ResponsiveLayout.place(shop_btn, Rect2(bar_w - 78.0, shop_h - 40.0, 68.0, 30.0))
	
	var shop_left := controls_w + 26.0 if not compact else 14.0
	var shop_right_margin := 88.0 if not compact else 14.0
	var shop_w := maxf(480.0, bar_w - shop_left - shop_right_margin)
	if shop:
		shop.fit_shop(Rect2(shop_left, 8.0, shop_w, shop_h - 16.0))
	
	# 7. Vida (HP - Canto Inferior Direito sobre a barra da loja)
	if health_widget:
		var hp_w := 160.0
		var hp_h := 54.0
		var hp_x := viewport_size.x - hp_w - 20.0
		var hp_y := shop_top - hp_h - 12.0
		ResponsiveLayout.place(health_widget, Rect2(hp_x, hp_y, hp_w, hp_h))
	
	# 8. Zona de Venda (Sobre a loja durante arraste)
	if is_instance_valid(sell_zone):
		ResponsiveLayout.place(sell_zone, Rect2((viewport_size.x - 280.0) * 0.5, shop_top - 68.0, 280.0, 56.0))
	
	# 9. Inspetor Lateral
	ResponsiveLayout.place(right_bar, Rect2(viewport_size.x - 290.0, 70.0, 280.0, maxf(shop_top - 80.0, 100.0)))
	var close_btn := right_bar.get_node_or_null("CloseButton") as Button
	if close_btn:
		close_btn.position = Vector2(right_bar.size.x - 34.0, 8.0)
	
	_cache_panel_positions()
	if not hud_visible:
		_set_hidden_positions()
	hud.visible = hud_visible
	hud.modulate.a = 1.0 if hud_visible else 0.0

func _setup_inspector() -> void:
	if not right_bar:
		return
	var close_btn := right_bar.get_node_or_null("CloseButton") as Button
	if not close_btn:
		close_btn = Button.new()
		close_btn.name = "CloseButton"
		close_btn.text = "✕"
		close_btn.custom_minimum_size = Vector2(26.0, 26.0)
		close_btn.size = Vector2(26.0, 26.0)
		close_btn.position = Vector2(right_bar.size.x - 34.0, 8.0)
		UIStyle.apply_button_skin(close_btn, UIStyle.BORDER_SLATE)
		close_btn.pressed.connect(hide_inspector)
		right_bar.add_child(close_btn)

func show_inspector() -> void:
	if not right_bar:
		return
	_layout_extra_panels()
	right_bar.show()
	var destination: Vector2 = visible_positions.get(right_bar, right_bar.position)
	right_bar.position.x = get_viewport().get_visible_rect().size.x
	if _inspector_tween and _inspector_tween.is_running():
		_inspector_tween.kill()
	_inspector_tween = create_tween()
	_inspector_tween.set_trans(Tween.TRANS_CUBIC)
	_inspector_tween.set_ease(Tween.EASE_OUT)
	_inspector_tween.tween_property(right_bar, "position", destination, 0.25)

func hide_inspector(immediate: bool = false) -> void:
	if not right_bar or not right_bar.visible:
		return
	if _inspector_tween and _inspector_tween.is_running():
		_inspector_tween.kill()
	if immediate:
		right_bar.hide()
		return
	var viewport_w := get_viewport().get_visible_rect().size.x
	_inspector_tween = create_tween()
	_inspector_tween.set_trans(Tween.TRANS_CUBIC)
	_inspector_tween.set_ease(Tween.EASE_IN)
	_inspector_tween.tween_property(right_bar, "position:x", viewport_w + 20.0, 0.2)
	_inspector_tween.tween_callback(right_bar.hide)
