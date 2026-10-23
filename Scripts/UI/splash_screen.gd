extends Control

## Cena de Splash Screen com arte oficial do jogo

@export var next_scene_path: String = "res://Scenes/UI/Menu.tscn"
@export var splash_texture: Texture2D = preload("res://Assets/Utils/splash_screen.jpg")

var _transitioned: bool = false
var _tween: Tween

func _ready() -> void:
	# Montar estrutura visual caso não venha de nós instanciados no editor
	_build_ui()
	_start_animation()

func _build_ui() -> void:
	# Fundo preto para letterboxing elegante
	var bg := ColorRect.new()
	bg.name = "Background"
	bg.color = Color.BLACK
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	# Imagem de Splash Screen
	var image_rect := TextureRect.new()
	image_rect.name = "SplashImage"
	image_rect.texture = splash_texture
	image_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	image_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	image_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	image_rect.modulate.a = 0.0
	add_child(image_rect)

	# Overlay para fade suave
	var overlay := ColorRect.new()
	overlay.name = "FadeOverlay"
	overlay.color = Color.BLACK
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.modulate.a = 1.0
	add_child(overlay)

func _start_animation() -> void:
	var image_rect := get_node_or_null("SplashImage") as TextureRect
	var overlay := get_node_or_null("FadeOverlay") as ColorRect
	if not image_rect or not overlay:
		_go_to_menu()
		return

	image_rect.modulate.a = 1.0
	_tween = create_tween()
	_tween.set_ease(Tween.EASE_IN_OUT)
	_tween.set_trans(Tween.TRANS_QUAD)

	# Fade in do preto
	_tween.tween_property(overlay, "modulate:a", 0.0, 0.9)
	# Espera com a imagem visível
	_tween.tween_interval(1.8)
	# Fade out para o preto
	_tween.tween_property(overlay, "modulate:a", 1.0, 0.8)
	_tween.tween_callback(_go_to_menu)

func _input(event: InputEvent) -> void:
	if _transitioned:
		return
	if (event is InputEventKey and event.pressed) or (event is InputEventMouseButton and event.pressed):
		get_viewport().set_input_as_handled()
		_go_to_menu()

func _go_to_menu() -> void:
	if _transitioned:
		return
	_transitioned = true
	if is_instance_valid(_tween) and _tween.is_running():
		_tween.kill()
	get_tree().change_scene_to_file(next_scene_path)
