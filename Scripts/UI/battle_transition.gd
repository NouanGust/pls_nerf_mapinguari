extends CanvasLayer

## Sobrevive à saída do menu e passa a pertencer à cena de batalha.
var _curtain: ColorRect
var _fade: Tween

func _ready() -> void:
	layer = 200
	process_mode = Node.PROCESS_MODE_ALWAYS
	_curtain = ColorRect.new()
	_curtain.name = "Curtain"
	_curtain.color = Color(0.0, 0.0, 0.0, 0.0)
	_curtain.mouse_filter = Control.MOUSE_FILTER_STOP
	_curtain.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(_curtain)
	get_viewport().gui_release_focus()

func _input(_event: InputEvent) -> void:
	# Continua bloqueando a interface depois do fade, até terminar a câmera.
	get_viewport().set_input_as_handled()

func force_black() -> void:
	if not is_instance_valid(_curtain):
		_curtain = ColorRect.new()
		_curtain.name = "Curtain"
		_curtain.color = Color(0.0, 0.0, 0.0, 1.0)
		_curtain.mouse_filter = Control.MOUSE_FILTER_STOP
		_curtain.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		add_child(_curtain)
	else:
		_curtain.color = Color(0.0, 0.0, 0.0, 1.0)

func fade_to_black() -> void:
	await _fade_to(1.0, 0.5)

func reveal() -> void:
	await _fade_to(0.0, 0.65)

func _fade_to(alpha: float, duration: float) -> void:
	if _fade and _fade.is_valid():
		_fade.kill()
	_fade = create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	_fade.tween_property(_curtain, "color:a", alpha, duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	await _fade.finished
