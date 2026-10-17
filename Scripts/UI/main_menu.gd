extends Control

const Regions = preload("res://Scripts/Systems/region_rosters.gd")
const BATTLE_SCENE: PackedScene = preload("res://Scenes/Main/main.tscn")
const BUTTON_ATLAS: Texture2D = preload("res://Assets/UI/buttons_4x.png")

var _panel: PanelContainer
var _home: VBoxContainer
var _selection: VBoxContainer
var _grid: GridContainer
var _enter_button: Button
var _start_button: Button
var _region_buttons: Dictionary = {}
var _selected_region: String = "cerrado"
var _starting: bool = false

func _ready() -> void:
	_build_interface()
	get_viewport().size_changed.connect(_fit_layout)
	_fit_layout()
	_select_region(_selected_region)
	_start_button.grab_focus()
	_panel.modulate.a = 0.0
	create_tween().tween_property(_panel, "modulate:a", 1.0, 0.3)

func _build_interface() -> void:
	var background := ColorRect.new()
	background.color = Color("#101e24")
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(background)
	var scroll := ScrollContainer.new()
	scroll.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	add_child(scroll)
	var center := CenterContainer.new()
	center.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	center.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.add_child(center)
	var margin := MarginContainer.new()
	for side in ["left", "top", "right", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 20)
	center.add_child(margin)
	_panel = PanelContainer.new()
	var frame := StyleBoxFlat.new()
	frame.bg_color = Color("#192d30")
	frame.border_color = Color("#a58a59")
	frame.set_border_width_all(2)
	frame.set_corner_radius_all(12)
	for side in [SIDE_LEFT, SIDE_TOP, SIDE_RIGHT, SIDE_BOTTOM]:
		frame.set_content_margin(side, 24)
	_panel.add_theme_stylebox_override("panel", frame)
	margin.add_child(_panel)
	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 18)
	_panel.add_child(content)
	content.add_child(_label("FOLCHESS", 42, Color("#efd7a0")))
	_home = VBoxContainer.new()
	_home.add_theme_constant_override("separation", 14)
	content.add_child(_home)
	_start_button = _button("Jogar")
	_start_button.pressed.connect(_show_regions)
	_home.add_child(_start_button)
	var exit_button := _button("Sair")
	exit_button.pressed.connect(func() -> void: get_tree().quit())
	_home.add_child(exit_button)
	exit_button.visible = not OS.has_feature("web")
	_selection = VBoxContainer.new()
	_selection.add_theme_constant_override("separation", 14)
	_selection.hide()
	content.add_child(_selection)
	_selection.add_child(_label("Escolha a região", 22, Color("#efd7a0")))
	_grid = GridContainer.new()
	_grid.columns = 3
	_grid.add_theme_constant_override("h_separation", 12)
	_grid.add_theme_constant_override("v_separation", 12)
	_selection.add_child(_grid)
	var group := ButtonGroup.new()
	for region_id in Regions.REGIONS:
		var region: Dictionary = Regions.get_region(region_id)
		var button := _button(str(region["name"]))
		button.toggle_mode = true
		button.button_group = group
		button.tooltip_text = "Enfrentar " + str(region["name"])
		button.pressed.connect(_select_region.bind(str(region_id)))
		button.add_theme_color_override("font_pressed_color", Color("#162522"))
		var selected_style := StyleBoxFlat.new()
		selected_style.bg_color = region["color"]
		selected_style.set_corner_radius_all(6)
		button.add_theme_stylebox_override("pressed", selected_style)
		_grid.add_child(button)
		_region_buttons[region_id] = button
	_enter_button = _button("Jogar")
	_enter_button.pressed.connect(_start_selected_region)
	_selection.add_child(_enter_button)
	var back := _button("Voltar")
	back.pressed.connect(_show_home)
	_selection.add_child(back)

func _label(text: String, font_size: int, color: Color = Color("#d5dfd8")) -> Label:
	var label := Label.new()
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	return label

func _button(text: String) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size.y = 48
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.add_theme_font_size_override("font_size", 18)
	button.add_theme_color_override("font_color", Color("#302019"))
	button.add_theme_color_override("font_focus_color", Color("#302019"))
	button.add_theme_color_override("font_hover_color", Color("#302019"))
	button.add_theme_color_override("font_pressed_color", Color("#302019"))
	for state in ["normal", "hover", "pressed"]:
		var style := StyleBoxTexture.new()
		style.texture = BUTTON_ATLAS
		style.region_rect = Rect2(224 if state == "hover" else 128, 0, 96, 64)
		for side in [SIDE_LEFT, SIDE_TOP, SIDE_RIGHT, SIDE_BOTTOM]:
			style.set_texture_margin(side, 16)
			style.set_content_margin(side, 12)
		button.add_theme_stylebox_override(state, style)
	return button

func _fit_layout() -> void:
	var width: float = get_viewport_rect().size.x
	_panel.custom_minimum_size.x = maxf(minf(width - 40.0, 720.0 if _selection.visible else 420.0), 280.0)
	_grid.columns = 3 if width >= 800.0 else (2 if width >= 540.0 else 1)

func _show_regions() -> void:
	_home.hide()
	_selection.show()
	_fit_layout()
	_region_buttons[_selected_region].grab_focus()

func _show_home() -> void:
	_selection.hide()
	_home.show()
	_fit_layout()
	_start_button.grab_focus()

func _select_region(region_id: String) -> void:
	_selected_region = region_id
	for id in _region_buttons:
		_region_buttons[id].set_pressed_no_signal(id == region_id)
	var region: Dictionary = Regions.get_region(region_id)
	_enter_button.text = "Jogar · %s" % region["name"]

func _start_selected_region() -> void:
	if _starting:
		return
	_starting = true
	_enter_button.disabled = true
	_enter_button.text = "Carregando…"
	_enter_region.call_deferred(_selected_region)

func _enter_region(region_id: String) -> void:
	var battle := BATTLE_SCENE.instantiate()
	battle.set("region_id", region_id)
	var tree := get_tree()
	# Configura a região antes do _ready da partida. Cada partida tem estado novo.
	tree.root.add_child(battle)
	tree.current_scene = battle
	queue_free()
