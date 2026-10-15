class_name CombatReport
extends Control

signal continue_requested

const METRICS: Array[Dictionary] = [
	{"id": &"damage_dealt", "title": "DANO CAUSADO", "color": Color("#e57b5f")},
	{"id": &"healing_done", "title": "CURA REALIZADA", "color": Color("#79c987")},
	{"id": &"damage_received", "title": "DANO RECEBIDO", "color": Color("#d9ac63")},
]

var _entries: Array[Dictionary] = []
var _selected_metric: StringName = &"damage_dealt"
var _list: VBoxContainer
var _panel: PanelContainer
var _tabs: Array[Button] = []
var _round_label: Label
var _result_label: Label
var _legend_label: Label

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	focus_mode = Control.FOCUS_ALL
	mouse_filter = Control.MOUSE_FILTER_STOP
	_build_interface()
	visible = false
	_fit_panel()

func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED and is_instance_valid(_panel):
		_fit_panel()

func show_report(round_number: int, player_won: bool, entries: Array[Dictionary], is_draw: bool = false) -> void:
	_entries = entries.duplicate(true)
	_selected_metric = &"damage_dealt"
	_round_label.text = "RELATÓRIO DE COMBATE · TURNO %d" % round_number
	_result_label.text = "EMPATE" if is_draw else ("VITÓRIA" if player_won else "DERROTA")
	var result_color := Color("#91c9d8") if is_draw else (Color("#e8cf83") if player_won else Color("#d98272"))
	_result_label.add_theme_color_override("font_color", result_color)
	_legend_label.text = "%d unidades · ambos os times" % _entries.size()
	visible = true
	_render_rows()
	_play_entrance()

func _build_interface() -> void:
	var dim := ColorRect.new()
	dim.name = "DimBackground"
	dim.color = Color(0.015, 0.025, 0.035, 0.68)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(dim)

	_panel = PanelContainer.new()
	var panel := _panel
	panel.name = "ReportPanel"
	panel.set_anchors_preset(Control.PRESET_TOP_LEFT)
	panel.size = Vector2(660, 700)
	panel.custom_minimum_size = Vector2(420, 440)
	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color("#172b30")
	panel_style.border_color = Color("#77b3ad")
	panel_style.set_border_width_all(3)
	panel_style.set_corner_radius_all(8)
	panel_style.content_margin_left = 19
	panel_style.content_margin_right = 19
	panel_style.content_margin_top = 16
	panel_style.content_margin_bottom = 16
	panel.add_theme_stylebox_override("panel", panel_style)
	add_child(panel)

	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 10)
	panel.add_child(content)

	_round_label = _make_label("RELATÓRIO DE COMBATE", 21, Color("#fff0cc"))
	_round_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	content.add_child(_round_label)

	_result_label = _make_label("VITÓRIA", 27, Color("#f2d77e"))
	_result_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	content.add_child(_result_label)

	_legend_label = _make_label("0 unidades · ambos os times", 12, Color("#aab9b8"))
	_legend_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	content.add_child(_legend_label)

	var divider := ColorRect.new()
	divider.custom_minimum_size = Vector2(0, 2)
	divider.color = Color("#3c696b")
	content.add_child(divider)

	var tabs := HBoxContainer.new()
	tabs.add_theme_constant_override("separation", 8)
	content.add_child(tabs)
	var tab_group := ButtonGroup.new()
	for metric in METRICS:
		var tab := Button.new()
		tab.text = metric.title
		tab.toggle_mode = true
		tab.button_group = tab_group
		tab.button_pressed = metric.id == _selected_metric
		tab.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		tab.custom_minimum_size = Vector2(0, 38)
		_style_button(tab, metric.id == _selected_metric)
		tab.pressed.connect(_on_metric_selected.bind(metric.id))
		tabs.add_child(tab)
		_tabs.append(tab)

	var scroll := ScrollContainer.new()
	scroll.name = "UnitListScroll"
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	content.add_child(scroll)
	_list = VBoxContainer.new()
	_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_list.add_theme_constant_override("separation", 7)
	scroll.add_child(_list)

	var footer := HBoxContainer.new()
	footer.alignment = BoxContainer.ALIGNMENT_CENTER
	content.add_child(footer)
	var continue_button := Button.new()
	continue_button.text = "CONTINUAR"
	continue_button.custom_minimum_size = Vector2(180, 42)
	_style_button(continue_button, true)
	continue_button.pressed.connect(_on_continue_pressed)
	footer.add_child(continue_button)

func _on_metric_selected(metric: StringName) -> void:
	_selected_metric = metric
	for i in _tabs.size():
		_style_button(_tabs[i], METRICS[i].id == metric)
	_render_rows()

func _render_rows() -> void:
	if not is_instance_valid(_list):
		return
	for child in _list.get_children():
		_list.remove_child(child)
		child.queue_free()

	var sorted_entries := _entries.duplicate()
	sorted_entries.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return float(a.get(_selected_metric, 0.0)) > float(b.get(_selected_metric, 0.0))
	)
	var maximum := 0.0
	for entry in sorted_entries:
		maximum = maxf(maximum, float(entry.get(_selected_metric, 0.0)))
	if maximum <= 0.0:
		maximum = 1.0

	for entry in sorted_entries:
		_list.add_child(_make_unit_row(entry, maximum))
	if sorted_entries.is_empty():
		var empty := _make_label("Nenhuma unidade participou deste turno.", 14, Color("#aab9b8"))
		empty.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_list.add_child(empty)

func _make_unit_row(entry: Dictionary, maximum: float) -> Control:
	var row := PanelContainer.new()
	row.custom_minimum_size = Vector2(0, 72)
	var row_style := StyleBoxFlat.new()
	row_style.bg_color = Color("#202e33")
	row_style.border_color = Color("#34494d")
	row_style.set_border_width_all(1)
	row_style.set_corner_radius_all(5)
	row_style.content_margin_left = 7
	row_style.content_margin_right = 8
	row_style.content_margin_top = 5
	row_style.content_margin_bottom = 5
	row.add_theme_stylebox_override("panel", row_style)
	var line := HBoxContainer.new()
	line.add_theme_constant_override("separation", 9)
	row.add_child(line)

	var portrait := TextureRect.new()
	portrait.custom_minimum_size = Vector2(54, 54)
	portrait.size = Vector2(54, 54)
	portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	portrait.texture = entry.get("icon") as Texture2D
	portrait.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	line.add_child(portrait)

	var info := VBoxContainer.new()
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	info.add_theme_constant_override("separation", 2)
	line.add_child(info)
	var title_line := HBoxContainer.new()
	info.add_child(title_line)
	var unit_name := _make_label(str(entry.get("name", "Unidade")), 14, Color("#f0e4c9"))
	unit_name.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_line.add_child(unit_name)
	var team_label := _make_label("ALIADO" if int(entry.get("team", 0)) == 0 else "INIMIGO", 10,
		Color("#70c8b2") if int(entry.get("team", 0)) == 0 else Color("#d78f84"))
	title_line.add_child(team_label)

	var progress := ProgressBar.new()
	progress.custom_minimum_size = Vector2(0, 11)
	progress.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	progress.show_percentage = false
	progress.max_value = maximum
	progress.value = float(entry.get(_selected_metric, 0.0))
	var bg := StyleBoxFlat.new()
	bg.bg_color = Color("#11191d")
	bg.set_corner_radius_all(2)
	var fill := StyleBoxFlat.new()
	fill.bg_color = _metric_color(_selected_metric)
	fill.set_corner_radius_all(2)
	progress.add_theme_stylebox_override("background", bg)
	progress.add_theme_stylebox_override("fill", fill)
	info.add_child(progress)

	var value := _make_label(_format_number(float(entry.get(_selected_metric, 0.0))), 17, _metric_color(_selected_metric))
	value.custom_minimum_size = Vector2(78, 0)
	value.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	line.add_child(value)
	return row

func _make_label(text: String, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_outline_color", Color("#101719"))
	label.add_theme_constant_override("outline_size", 2)
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	return label

func _style_button(button: Button, active: bool) -> void:
	button.add_theme_stylebox_override("normal", _button_style(Color("#396267") if active else Color("#26383d")))
	button.add_theme_stylebox_override("hover", _button_style(Color("#4b7f7e")))
	button.add_theme_stylebox_override("pressed", _button_style(Color("#31565b")))
	button.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	button.add_theme_color_override("font_color", Color("#e8e1d2"))
	button.add_theme_font_size_override("font_size", 11)

func _button_style(color: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.border_color = Color("#638f8c")
	style.set_border_width_all(1)
	style.set_corner_radius_all(4)
	style.content_margin_left = 7
	style.content_margin_right = 7
	style.content_margin_top = 5
	style.content_margin_bottom = 5
	return style

func _metric_color(metric: StringName) -> Color:
	for item in METRICS:
		if item.id == metric:
			return item.color
	return Color.WHITE

func _format_number(value: float) -> String:
	return str(int(round(value)))

func _play_entrance() -> void:
	if not is_instance_valid(_panel):
		return
	_panel.pivot_offset = _panel.size * 0.5
	_panel.scale = Vector2(0.96, 0.96)
	modulate.a = 0.0
	var tween := create_tween().set_parallel(true)
	tween.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "modulate:a", 1.0, 0.22)
	tween.tween_property(_panel, "scale", Vector2.ONE, 0.24)

func _fit_panel() -> void:
	if not is_instance_valid(_panel):
		return
	var viewport_size := get_viewport_rect().size
	_panel.size = Vector2(minf(660.0, viewport_size.x - 28.0), minf(700.0, viewport_size.y - 28.0))
	_panel.position = (viewport_size - _panel.size) * 0.5
	_panel.pivot_offset = _panel.size * 0.5

func _on_continue_pressed() -> void:
	continue_requested.emit()
