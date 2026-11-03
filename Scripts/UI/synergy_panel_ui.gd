class_name SynergyPanelUI
extends RefCounted

## Gerenciador da Lista de Sinergias Ativas e Tooltip Flutuante Lateral

signal synergy_hover_started(synergy_name: String)
signal synergy_hover_ended()

const UIStyle = preload("res://Scripts/UI/ui_style.gd")
const ResponsiveLayout = preload("res://Scripts/UI/responsive_layout.gd")

var ui: CanvasLayer
var hud: Control
var synergy_button: Button
var synergy_panel: Control
var synergy_list: VBoxContainer
var synergy_row_active_template: PanelContainer
var synergy_row_inactive_template: PanelContainer
var synergy_tooltip: PanelContainer
var spawned_synergy_rows: Array[Control] = []
var last_player_synergies: Array = []
var _synergy_tooltip_origin: Vector2 = Vector2.ZERO

func setup(p_ui: CanvasLayer, p_hud: Control) -> void:
	ui = p_ui
	hud = p_hud
	_bind_synergy_panel()

func _bind_synergy_panel() -> void:
	if not hud:
		return
	synergy_button = hud.get_node_or_null("SynergyToggleButton") as Button
	synergy_panel = hud.get_node_or_null("SynergyPanel") as Control
	synergy_list = hud.get_node_or_null("SynergyPanel/ScrollContainer/SynergyList") as VBoxContainer
	synergy_row_active_template = synergy_list.get_node_or_null("SynergyRowTemplateActive") as PanelContainer if synergy_list else null
	synergy_row_inactive_template = synergy_list.get_node_or_null("SynergyRowTemplateInactive") as PanelContainer if synergy_list else null
	_ensure_synergy_tooltip()
	if synergy_button and synergy_panel and not synergy_button.pressed.is_connected(toggle_panel):
		synergy_button.pressed.connect(toggle_panel)
	update_synergies([])

func toggle_panel() -> void:
	if is_instance_valid(synergy_tooltip):
		synergy_tooltip.hide()
	if is_instance_valid(synergy_panel):
		synergy_panel.visible = not synergy_panel.visible

func update_synergies(synergies: Array) -> void:
	last_player_synergies = synergies.duplicate()
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
			var stacks: int = int(synergy.get("stacks", 0))
			var max_stacks: int = int(synergy.get("max_stacks", 0))
			if max_stacks > 0:
				progress_text.text = "%d/%d [%d/%dst]" % [synergy.count, synergy.threshold, stacks, max_stacks]
			else:
				progress_text.text = "%d/%d" % [synergy.count, synergy.threshold]
		if progress:
			progress.max_value = maxi(int(synergy.threshold), 1)
			progress.value = mini(int(synergy.count), int(synergy.threshold))
		
		row.tooltip_text = ""
		row.mouse_filter = Control.MOUSE_FILTER_STOP
		row.mouse_entered.connect(_on_synergy_row_hover_started.bind(synergy, row))
		row.mouse_exited.connect(_on_synergy_row_hover_ended)
		
		synergy_list.add_child(row)
		spawned_synergy_rows.append(row)
	fit_height()

func fit_height() -> void:
	if synergy_panel and ui:
		var viewport_size: Vector2 = ui.get_viewport().get_visible_rect().size
		var metrics := ResponsiveLayout.battle_metrics(viewport_size)
		var available := maxf(float(metrics["bench_top"]) - synergy_panel.position.y - 8.0, 68.0)
		synergy_panel.size.y = clampf(spawned_synergy_rows.size() * 50.0 + 16.0, 68.0, minf(440.0, available))

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
		_prepare_synergy_tooltip_layout()
		synergy_tooltip.hide()

func _prepare_synergy_tooltip_layout(target_width: float = 300.0) -> void:
	if not is_instance_valid(synergy_tooltip) or not ui:
		return
	var viewport_size := ui.get_viewport().get_visible_rect().size
	var target_w := clampf(target_width, 240.0, maxf(viewport_size.x - 30.0, 240.0))
	var inner_w := maxf(target_w - 24.0, 100.0)
	synergy_tooltip.set_anchors_preset(Control.PRESET_TOP_LEFT)
	synergy_tooltip.custom_minimum_size = Vector2(target_w, 0.0)
	synergy_tooltip.size = Vector2(target_w, 0.0)
	var vbox := synergy_tooltip.get_node_or_null("VBoxContainer") as VBoxContainer
	if vbox:
		vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		vbox.custom_minimum_size = Vector2(inner_w, 0.0)
		vbox.size = Vector2(inner_w, 0.0)
		for child in vbox.get_children():
			if child is Control:
				child.size_flags_horizontal = Control.SIZE_EXPAND_FILL
				child.custom_minimum_size = Vector2(inner_w, 0.0)
				child.size = Vector2(inner_w, 0.0)
				if child is RichTextLabel:
					child.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
					child.fit_content = true
		vbox.reset_size()
	synergy_tooltip.reset_size()

func _on_synergy_row_hover_started(synergy: Dictionary, row: Control) -> void:
	_ensure_synergy_tooltip()
	if not is_instance_valid(synergy_tooltip):
		return
	_prepare_synergy_tooltip_layout()
	_update_synergy_tooltip_content(synergy)
	_prepare_synergy_tooltip_layout()
	var panel_global: Vector2 = synergy_panel.global_position if is_instance_valid(synergy_panel) else row.global_position
	var panel_width: float = synergy_panel.size.x if is_instance_valid(synergy_panel) else row.size.x
	_synergy_tooltip_origin = Vector2(panel_global.x + panel_width + 12.0, row.global_position.y)
	_fit_synergy_tooltip(true)
	synergy_tooltip.show()
	_fit_synergy_tooltip()
	synergy_hover_started.emit(str(synergy.get("name", "")))

func _on_synergy_row_hover_ended() -> void:
	hide_tooltip()

func hide_tooltip() -> void:
	if is_instance_valid(synergy_tooltip):
		synergy_tooltip.hide()
	synergy_hover_ended.emit()

func _fit_synergy_tooltip(force: bool = false) -> void:
	if not is_instance_valid(synergy_tooltip) or not ui:
		return
	if not force and not synergy_tooltip.visible:
		return
	var viewport_size := ui.get_viewport().get_visible_rect().size
	_prepare_synergy_tooltip_layout()
	ResponsiveLayout.clamp_popup(synergy_tooltip, _synergy_tooltip_origin, viewport_size)

func show_inspector_tooltip(tag_name: String, source_label: Control, right_bar: Control) -> void:
	var rule := SynergySystem.get_rule_for_tag(tag_name)
	if rule.is_empty():
		return
	_ensure_synergy_tooltip()
	if not is_instance_valid(synergy_tooltip):
		return
	var current_syn := find_player_synergy_by_name(tag_name)
	var count := int(current_syn.get("count", 0))
	var tier_index := -1
	for i in rule.thresholds.size():
		if count >= int(rule.thresholds[i]):
			tier_index = i
	var display_tier := maxi(tier_index, 0)
	var effect: Dictionary = rule.effects[display_tier] if display_tier < rule.effects.size() else rule.effects[0]
	var next_threshold := int(rule.thresholds.back())
	for threshold in rule.thresholds:
		if count < int(threshold):
			next_threshold = int(threshold)
			break
	
	var syn_data := {
		"name": tag_name,
		"category": "Origem" if str(rule.get("field", "")) == "origins" else "Classe",
		"count": count,
		"threshold": next_threshold,
		"thresholds": rule.thresholds.duplicate(),
		"active": tier_index >= 0,
		"description": effect.text,
		"units": current_syn.get("units", []),
		"stacks": current_syn.get("stacks", 0),
		"max_stacks": int(rule.get("max_stacks", 0)),
	}
	_prepare_synergy_tooltip_layout()
	_update_synergy_tooltip_content(syn_data)
	_prepare_synergy_tooltip_layout()
	
	var panel_global: Vector2 = right_bar.global_position if is_instance_valid(right_bar) else source_label.global_position
	_synergy_tooltip_origin = Vector2(panel_global.x - 315.0, source_label.global_position.y)
	_fit_synergy_tooltip(true)
	synergy_tooltip.show()
	_fit_synergy_tooltip()
	synergy_hover_started.emit(tag_name)

func find_player_synergy_by_name(tag_name: String) -> Dictionary:
	for syn in last_player_synergies:
		if str(syn.get("name", "")) == tag_name:
			return syn
	return {}

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
	var tag_name: String = str(synergy.get("name", "Sinergia"))

	if title_lbl:
		title_lbl.text = "[b][color=#f5da80]%s[/color][/b] [color=%s]· %s[/color]" % [
			tag_name,
			cat_color,
			str(synergy.get("category", "Sinergia"))
		]

	if status_lbl:
		var status_text: String
		if is_active:
			status_text = "[color=#2ecc71]Ativa[/color] [color=#c5ddff](%d/%d)[/color]" % [count, threshold]
		else:
			var needed := maxi(threshold - count, 0)
			status_text = "[color=#e74c3c]Inativa[/color] [color=#8fa3b0](faltam %d peça%s · %d/%d)[/color]" % [
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
			status_text += "  ·  [color=#8fa3b0]Marcos:[/color] %s" % " -> ".join(milestones_parts)
		status_lbl.text = status_text

	if desc_lbl:
		var rule := SynergySystem.get_rule_for_tag(tag_name)
		var text_lines: Array[String] = []
		if not rule.is_empty() and rule.has("effects"):
			var rule_thresholds: Array = rule.get("thresholds", [])
			var rule_effects: Array = rule.get("effects", [])
			for i in rule_thresholds.size():
				var t_val := int(rule_thresholds[i])
				var eff_text := str(rule_effects[i].get("text", "")) if i < rule_effects.size() else ""
				if count >= t_val:
					text_lines.append("[b][color=#2ecc71](%d) %s[/color][/b]" % [t_val, eff_text])
				else:
					text_lines.append("[color=#94a3b8](%d) %s[/color]" % [t_val, eff_text])
		else:
			var desc: String = str(synergy.get("description", ""))
			text_lines.append(desc if not desc.is_empty() else "Nenhum bônus adicional.")

		var stacks: int = int(synergy.get("stacks", 0))
		var max_stacks: int = int(synergy.get("max_stacks", 0))
		if max_stacks > 0:
			text_lines.append("[color=#ffd16b]Acúmulos Atuais:[/color] [b]%d / %d[/b] [color=#94a3b8](limite máximo)[/color]" % [stacks, max_stacks])

		desc_lbl.text = "[color=#ffd32a]Efeitos e Bônus:[/color]\n%s" % "\n".join(text_lines)

	if units_lbl:
		var units: Array = synergy.get("units", [])
		if not units.is_empty():
			units_lbl.text = "[color=#74e6f5]Integrantes (%d):[/color] %s\n[color=#5e7585][i]Cada campeão único no tabuleiro conta 1 vez.[/i][/color]" % [
				units.size(), ", ".join(units)
			]
		else:
			units_lbl.text = "[color=#5e7585][i]Cada campeão único no tabuleiro conta 1 vez.[/i][/color]"
