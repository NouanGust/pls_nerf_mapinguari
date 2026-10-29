class_name HUDAnimator
extends RefCounted

## Gerenciador de Transições e Ocultamento da Interface (HUD)

var ui: CanvasLayer
var hud: Control
var top_bar: Control
var bottom_bar: Control
var bench_panel: Control
var health_widget: Control
var right_bar: Control
var toggle_button: Button

var hud_visible: bool = true
var hud_tween: Tween
var visible_positions: Dictionary = {}

func setup(p_ui: CanvasLayer, p_hud: Control, p_top: Control, p_bottom: Control, p_bench: Control, p_hp: Control, p_right: Control, p_toggle_btn: Button) -> void:
	ui = p_ui
	hud = p_hud
	top_bar = p_top
	bottom_bar = p_bottom
	bench_panel = p_bench
	health_widget = p_hp
	right_bar = p_right
	toggle_button = p_toggle_btn

func cache_panel_positions() -> void:
	if top_bar: visible_positions[top_bar] = top_bar.position
	if bottom_bar: visible_positions[bottom_bar] = bottom_bar.position
	if bench_panel: visible_positions[bench_panel] = bench_panel.position
	if health_widget: visible_positions[health_widget] = health_widget.position
	if right_bar: visible_positions[right_bar] = right_bar.position

func toggle_hud(on_hide_callback: Callable = Callable()) -> bool:
	hud_visible = not hud_visible
	if not hud_visible and on_hide_callback.is_valid():
		on_hide_callback.call()
	if toggle_button:
		toggle_button.text = "HUD" if hud_visible else "+ UI"
		toggle_button.tooltip_text = "Ocultar interface (H)" if hud_visible else "Mostrar interface (H)"
	play_hud_transition(hud_visible)
	return hud_visible

func play_hud_transition(show_hud: bool, initial: bool = false) -> void:
	if not hud or not ui or not ui.is_inside_tree():
		return
	if hud_tween and hud_tween.is_running():
		hud_tween.kill()

	if show_hud:
		hud.show()
		if initial:
			hud.modulate.a = 0.0
			set_hidden_positions()
	else:
		hud.show()

	hud_tween = ui.create_tween()
	hud_tween.set_parallel(true)
	hud_tween.set_trans(Tween.TRANS_CUBIC)
	hud_tween.set_ease(Tween.EASE_OUT if show_hud else Tween.EASE_IN)
	hud_tween.tween_property(hud, "modulate:a", 1.0 if show_hud else 0.0, 0.26)
	
	var animated_panels: Array[Control] = []
	if top_bar: animated_panels.append(top_bar)
	if bottom_bar: animated_panels.append(bottom_bar)
	if health_widget: animated_panels.append(health_widget)
	
	for panel in animated_panels:
		var destination: Vector2 = visible_positions.get(panel, panel.position)
		if not show_hud:
			destination = _hidden_position(panel)
		hud_tween.tween_property(panel, "position", destination, 0.3)

	if right_bar and right_bar.visible:
		var right_destination: Vector2 = visible_positions.get(right_bar, right_bar.position)
		if not show_hud:
			right_destination = _hidden_position(right_bar)
		hud_tween.tween_property(right_bar, "position", right_destination, 0.3)

	if not show_hud:
		hud_tween.set_parallel(false)
		hud_tween.tween_callback(hud.hide)

func set_hidden_positions() -> void:
	if top_bar: top_bar.position = _hidden_position(top_bar)
	if bottom_bar: bottom_bar.position = _hidden_position(bottom_bar)
	if health_widget: health_widget.position = _hidden_position(health_widget)
	if right_bar and right_bar.visible: right_bar.position = _hidden_position(right_bar)

func _hidden_position(panel: Control) -> Vector2:
	var destination: Vector2 = visible_positions.get(panel, panel.position)
	if not ui or not ui.is_inside_tree():
		return destination
	var vp_size := ui.get_viewport().get_visible_rect().size
	if panel == top_bar:
		destination.y = - panel.size.y - 20.0
	elif panel == right_bar or panel == health_widget:
		destination.x = vp_size.x + 20.0
	else:
		destination.y = vp_size.y + 20.0
	return destination
