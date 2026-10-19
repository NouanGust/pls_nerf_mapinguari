class_name GameUI
extends CanvasLayer

signal hud_visibility_changed(is_visible: bool)

const GUI_ATLAS: Texture2D = preload("res://Assets/UI/GUI_4x.png")
const BUTTONS_ATLAS: Texture2D = preload("res://Assets/UI/buttons_4x.png")

@onready var hud: Control = $Control
@onready var top_bar: Control = $Control/TopBar
@onready var bottom_bar: Control = $Control/BottomBar
@onready var bench_panel: Control = $Control/BenchPanel
@onready var right_bar: Control = $Control/RightBar
@onready var toggle_button: Button = $HUDToggleButton

var hud_visible := true
var hud_tween: Tween
var visible_positions: Dictionary = {}
var sell_zone: PanelContainer
var synergy_button: Button
var synergy_panel: Control
var synergy_list: VBoxContainer
var synergy_row_active_template: PanelContainer
var synergy_row_inactive_template: PanelContainer
var spawned_synergy_rows: Array[Control] = []
var _responsive_ready: bool = false
var _compact_layout: bool = false
var _shop_controls: BoxContainer
var _inspector_tween: Tween

func _ready() -> void:
	_apply_panel_frames()
	_apply_button_skins()
	_build_sell_zone()
	_bind_synergy_panel()
	_prepare_responsive_controls()
	_responsive_ready = true
	if toggle_button:
		toggle_button.pressed.connect(toggle_hud)
	get_viewport().size_changed.connect(_layout_extra_panels)
	await get_tree().process_frame
	_layout_extra_panels()
	_cache_panel_positions()
	_play_hud_transition(true, true)

func toggle_hud() -> void:
	hud_visible = not hud_visible
	toggle_button.text = "HUD" if hud_visible else "+ UI"
	toggle_button.tooltip_text = "Ocultar interface (H)" if hud_visible else "Mostrar interface (H)"
	_play_hud_transition(hud_visible)
	hud_visibility_changed.emit(hud_visible)

func _cache_panel_positions() -> void:
	visible_positions[top_bar] = top_bar.position
	visible_positions[bottom_bar] = bottom_bar.position
	visible_positions[bench_panel] = bench_panel.position
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
	
	for panel in [top_bar, bottom_bar, bench_panel]:
		var destination: Vector2 = visible_positions[panel]
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
	for panel in [top_bar]:
		panel.position = _hidden_position(panel)
	for panel in [bottom_bar, bench_panel]:
		panel.position = _hidden_position(panel)
	if right_bar.visible:
		right_bar.position = _hidden_position(right_bar)

func _hidden_position(panel: Control) -> Vector2:
	var destination: Vector2 = visible_positions.get(panel, panel.position)
	if panel == top_bar:
		destination.y = - panel.size.y - 20.0
	elif panel == right_bar:
		destination.x = get_viewport().get_visible_rect().size.x + 20.0
	else:
		destination.y = get_viewport().get_visible_rect().size.y + 20.0
	return destination

func _apply_panel_frames() -> void:
	for panel in [top_bar, bottom_bar, bench_panel, right_bar]:
		panel.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		var frame := NinePatchRect.new()
		frame.name = "AtlasFrame"
		frame.texture = GUI_ATLAS
		frame.region_rect = Rect2(0, 352, 160, 48)
		frame.patch_margin_left = 24
		frame.patch_margin_top = 24
		frame.patch_margin_right = 24
		frame.patch_margin_bottom = 24
		frame.draw_center = false
		frame.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
		frame.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		panel.add_child(frame)
		panel.move_child(frame, 0)

func _apply_button_skins() -> void:
	for button in [
		$Control/BottomBar/ShopLabel,
		$Control/BottomBar/ControlsContainer/RerollButton,
		$Control/BottomBar/ControlsContainer/LockButton,
		$Control/BottomBar/ControlsContainer/BuyXPButton,
		$Control/SynergyToggleButton,
		toggle_button
	]:
		_style_button(button)

func _style_button(button: Button) -> void:
	button.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	var normal_region := Rect2(132, 4, 88, 56)
	var hover_region := Rect2(224, 0, 96, 64)
	var pressed_region := Rect2(228, 8.0, 88, 52)
	if button == toggle_button:
		normal_region = Rect2(0, 0, 64, 64)
		hover_region = Rect2(64, 0, 64, 64)
		pressed_region = Rect2(0, 0, 64, 64)
	var normal := _button_style(normal_region)
	var hover := _button_style(hover_region)
	var pressed := _button_style(pressed_region)
	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_stylebox_override("pressed", pressed)
	button.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	button.add_theme_color_override("font_color", Color("#302019"))
	button.add_theme_color_override("font_hover_color", Color("#1d1712"))
	button.add_theme_color_override("font_pressed_color", Color("#1d1712"))
	button.add_theme_font_size_override("font_size", 13)

func get_sell_zone() -> Control:
	return sell_zone

func set_sell_zone_visible(is_visible: bool) -> void:
	if is_instance_valid(sell_zone):
		sell_zone.visible = is_visible

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
		row.custom_minimum_size.y = 52
		row.get_node("Row/Icon").hide()
		row.name = "Synergy_%s_%s" % [str(synergy.category).replace(" ", ""), str(synergy.name).replace(" ", "_")]
		row.show()
		var title := row.get_node_or_null("Row/Content/Header/TagLabel") as Label
		var progress_text := row.get_node_or_null("Row/Content/Header/CountLabel") as Label
		var progress := row.get_node_or_null("Row/Content/Progress") as ProgressBar
		if title:
			title.text = str(synergy.name)
			title.add_theme_font_size_override("font_size", 18)
			title.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		if progress_text:
			progress_text.add_theme_font_size_override("font_size", 16)
			progress_text.text = "%s%d/%d" % ["✓ " if is_active else "", synergy.count, synergy.threshold]
		if progress:
			progress.max_value = maxi(int(synergy.threshold), 1)
			progress.value = mini(int(synergy.count), int(synergy.threshold))
		var status := "Ativa" if is_active else "Faltam %d" % maxi(int(synergy.threshold) - int(synergy.count), 0)
		row.tooltip_text = "%s · %s\n%s: %s" % [synergy.name, synergy.category, status, synergy.description]
		row.tooltip_text += "\nCada unidade diferente conta uma vez."
		row.tooltip_text += "\nUnidades: %s" % ", ".join(synergy.get("units", []))
		synergy_list.add_child(row)
		spawned_synergy_rows.append(row)
	_fit_synergy_height.call_deferred()

func _fit_synergy_height() -> void:
	if synergy_panel:
		var metrics := ResponsiveLayout.battle_metrics(get_viewport().get_visible_rect().size)
		var available := maxf(float(metrics["bench_top"]) - synergy_panel.position.y - 8.0, 68.0)
		synergy_panel.size.y = clampf(spawned_synergy_rows.size() * 58.0 + 16.0, 68.0, minf(420.0, available))

func _bind_synergy_panel() -> void:
	synergy_button = hud.get_node_or_null("SynergyToggleButton") as Button
	synergy_panel = hud.get_node_or_null("SynergyPanel") as Control
	synergy_list = hud.get_node_or_null("SynergyPanel/ScrollContainer/SynergyList") as VBoxContainer
	synergy_row_active_template = synergy_list.get_node_or_null("SynergyRowTemplateActive") as PanelContainer if synergy_list else null
	synergy_row_inactive_template = synergy_list.get_node_or_null("SynergyRowTemplateInactive") as PanelContainer if synergy_list else null
	if synergy_button and synergy_panel and not synergy_button.pressed.is_connected(_toggle_synergy_panel):
		synergy_button.pressed.connect(_toggle_synergy_panel)
	update_synergies([])

func _toggle_synergy_panel() -> void:
	if is_instance_valid(synergy_panel):
		synergy_panel.visible = not synergy_panel.visible

func _build_sell_zone() -> void:
	sell_zone = PanelContainer.new()
	sell_zone.name = "SellDropZone"
	sell_zone.mouse_filter = Control.MOUSE_FILTER_STOP
	sell_zone.custom_minimum_size = Vector2(250, 58)
	sell_zone.size = sell_zone.custom_minimum_size
	var style := StyleBoxFlat.new()
	style.bg_color = Color("#532c2b", 0.97)
	style.border_color = Color("#d7836e")
	style.set_border_width_all(2)
	style.set_corner_radius_all(5)
	sell_zone.add_theme_stylebox_override("panel", style)
	var label := _make_info_label("VENDER UNIDADE\nSolte aqui ou aperte S", 13, Color("#ffe6ca"))
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	sell_zone.add_child(label)
	hud.add_child(sell_zone)
	sell_zone.hide()
	_layout_extra_panels()

func _make_info_label(text: String, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_outline_color", Color("#101719"))
	label.add_theme_constant_override("outline_size", 2)
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
	var top_height: float = metrics["top_height"]
	var top_width := minf(580.0, viewport_size.x - 206.0)
	ResponsiveLayout.place(top_bar, Rect2(12, 12, top_width, top_height))
	var labels := ["GoldLabel", "HealthLabel", "LevelLabel", "RoundLabel"]
	for i in labels.size():
		var label := top_bar.get_node(labels[i]) as Label
		var columns := 2 if compact else 4
		var width := (top_width - 20.0) / columns
		ResponsiveLayout.place(label, Rect2(10.0 + (i % columns) * width, 8.0 + floori(float(i) / columns) * 32.0, width, 32.0 if compact else 44.0))
		label.clip_text = true
		label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	ResponsiveLayout.place(toggle_button, Rect2(viewport_size.x - 68.0, 12.0, 56.0, 44.0))
	var pause := get_node_or_null("PauseButton") as Button
	if pause:
		pause.custom_minimum_size.y = 44.0
		ResponsiveLayout.place(pause, Rect2(viewport_size.x - 194.0, 12.0, 118.0, 44.0))
	var warning := get_node_or_null("SaveWarning") as Label
	if warning:
		warning.add_theme_font_size_override("font_size", 14)
		ResponsiveLayout.place(warning, Rect2(12, top_height + 78.0, viewport_size.x - 24.0, 36))
	ResponsiveLayout.place($Control/BoardCountLabel, Rect2(viewport_size.x * 0.5 - 150.0, top_height + 18.0, 300, 28))
	ResponsiveLayout.place($Control/RegionLabel, Rect2(160, top_height + 46.0, viewport_size.x - 320, 28))
	$Control/RegionLabel.clip_text = true
	$Control/RegionLabel.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	ResponsiveLayout.place(synergy_button, Rect2(12, top_height + 20.0, 142, 34))
	ResponsiveLayout.place(synergy_panel, Rect2(12, top_height + 62.0, 250, 68))
	if compact != _compact_layout:
		synergy_panel.visible = not compact
	_compact_layout = compact
	_fit_synergy_height()
	var shop_height: float = metrics["shop_height"]
	ResponsiveLayout.place(bottom_bar, Rect2(12, metrics["shop_top"], viewport_size.x - 24.0, shop_height))
	_shop_controls.vertical = not compact
	var controls_width := 144.0 if not compact else bottom_bar.size.x - 112.0
	ResponsiveLayout.place(_shop_controls, Rect2(bottom_bar.size.x - controls_width - 12.0, 10.0 if compact else 28.0, controls_width, 36.0 if compact else 128.0))
	for button in _shop_controls.get_children():
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.clip_text = true
	ResponsiveLayout.place($Control/BottomBar/ShopLabel, Rect2(12, 10, 78, 36))
	var shop := $Control/BottomBar/ShopContainer as ShopUI
	var shop_left := 12.0 if compact else 102.0
	var shop_width := minf(880.0, bottom_bar.size.x - shop_left - (12.0 if compact else controls_width + 24.0))
	shop.fit_shop(Rect2(shop_left, 54.0 if compact else 12.0, shop_width, 166.0))
	var bench_width := minf(920.0, viewport_size.x - 24.0)
	var bench := $Control/BenchPanel/BenchContent/BenchSlots as BenchUI
	bench.fit_available_width(bench_width - 20.0)
	ResponsiveLayout.place(bench_panel, Rect2((viewport_size.x - bench_width) * 0.5, metrics["bench_top"], bench_width, metrics["bench_height"]))
	ResponsiveLayout.place(right_bar, Rect2(viewport_size.x - 292.0, top_height + 62.0, 280.0, maxf(float(metrics["bench_top"]) - top_height - 70.0, 100.0)))
	if is_instance_valid(sell_zone):
		ResponsiveLayout.place(sell_zone, Rect2((viewport_size.x - 250.0) * 0.5, metrics["bench_top"] - 66.0, 250, 58))
	_cache_panel_positions()
	if not hud_visible:
		_set_hidden_positions()
	hud.visible = hud_visible
	hud.modulate.a = 1.0 if hud_visible else 0.0

func _prepare_responsive_controls() -> void:
	var old_controls := $Control/BottomBar/ControlsContainer
	_shop_controls = BoxContainer.new()
	_shop_controls.name = "ControlsContainer"
	_shop_controls.add_theme_constant_override("separation", 8)
	bottom_bar.remove_child(old_controls)
	bottom_bar.add_child(_shop_controls)
	for button in old_controls.get_children():
		button.reparent(_shop_controls)
	old_controls.queue_free()
	var content := right_bar.get_node("VBoxContainer") as VBoxContainer
	var scroll := ScrollContainer.new()
	scroll.name = "InspectorScroll"
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	right_bar.add_child(scroll)
	scroll.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	scroll.offset_left = 16
	scroll.offset_right = -16
	scroll.offset_top = 16
	scroll.offset_bottom = -16
	content.reparent(scroll)
	content.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.alignment = BoxContainer.ALIGNMENT_BEGIN
	var portrait := content.get_node("Image_container") as TextureRect
	portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	portrait.custom_minimum_size = Vector2(0, 130)
	portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	var close := Button.new()
	close.text = "Fechar"
	close.pressed.connect(right_bar.hide)
	content.add_child(close)

func show_inspector() -> void:
	_layout_extra_panels()
	right_bar.show()
	var destination: Vector2 = visible_positions[right_bar]
	right_bar.position.x = get_viewport().get_visible_rect().size.x
	_inspector_tween = create_tween()
	_inspector_tween.tween_property(right_bar, "position", destination, 0.25)

func _button_style(region: Rect2) -> StyleBoxTexture:
	var atlas_texture := AtlasTexture.new()
	atlas_texture.atlas = BUTTONS_ATLAS
	atlas_texture.region = region
	var style := StyleBoxTexture.new()
	style.texture = atlas_texture
	style.texture_margin_left = 14
	style.texture_margin_top = 14
	style.texture_margin_right = 14
	style.texture_margin_bottom = 14
	style.content_margin_left = 10
	style.content_margin_top = 5
	style.content_margin_right = 10
	style.content_margin_bottom = 5
	return style
