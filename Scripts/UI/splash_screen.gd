extends Control

## Cena de Splash Screen com arte oficial do jogo

@export var next_scene_path: String = "res://Scenes/UI/Menu.tscn"
@export var splash_texture: Texture2D = preload("res://Assets/Utils/splash_screen.jpg")

const BATTLE_SCENE: PackedScene = preload("res://Scenes/Main/main.tscn")
const BattleTransition = preload("res://Scripts/UI/battle_transition.gd")

var _transitioned: bool = false
var _tween: Tween

func _ready() -> void:
	# Montar estrutura visual com fundo preto nativo para evitar qualquer tela cinza
	_build_ui()
	_start_animation()

func _build_ui() -> void:
	# Fundo preto para letterboxing elegante
	var bg := get_node_or_null("Background") as ColorRect
	if not bg:
		bg = ColorRect.new()
		bg.name = "Background"
		bg.color = Color.BLACK
		bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		add_child(bg)

	# Imagem de Splash Screen
	var image_rect := get_node_or_null("SplashImage") as TextureRect
	if not image_rect:
		image_rect = TextureRect.new()
		image_rect.name = "SplashImage"
		image_rect.texture = splash_texture
		image_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		image_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		image_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		image_rect.modulate.a = 0.0
		add_child(image_rect)

	# Overlay para fade suave
	var overlay := get_node_or_null("FadeOverlay") as ColorRect
	if not overlay:
		overlay = ColorRect.new()
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
		_start_next_screen()
		return

	image_rect.modulate.a = 1.0
	_tween = create_tween()
	_tween.set_ease(Tween.EASE_IN_OUT)
	_tween.set_trans(Tween.TRANS_QUAD)

	# Fade in do preto
	_tween.tween_property(overlay, "modulate:a", 0.0, 0.9)
	# Espera com a imagem visível
	_tween.tween_interval(1.8)
	# Fade out para o preto total
	_tween.tween_property(overlay, "modulate:a", 1.0, 0.8)
	_tween.tween_callback(_start_next_screen)

func _input(event: InputEvent) -> void:
	if _transitioned:
		return
	if (event is InputEventKey and event.pressed) or (event is InputEventMouseButton and event.pressed):
		get_viewport().set_input_as_handled()
		_start_next_screen()

func _start_next_screen() -> void:
	if _transitioned:
		return
	_transitioned = true
	if is_instance_valid(_tween) and _tween.is_running():
		_tween.kill()

	var overlay := get_node_or_null("FadeOverlay") as ColorRect
	if overlay and overlay.modulate.a < 0.98:
		var quick_fade := create_tween()
		quick_fade.tween_property(overlay, "modulate:a", 1.0, 0.22)
		await quick_fade.finished

	var gs: Node = get_node_or_null("/root/GameSettings")
	var target_region: String = str(gs.get_last_played_region()) if (gs and gs.has_method("get_last_played_region")) else "mata_atlantica"
	if target_region.is_empty():
		target_region = "mata_atlantica"

	var transition := BattleTransition.new()
	get_tree().root.add_child(transition)
	transition.force_black()

	var battle := BATTLE_SCENE.instantiate()
	battle.set("region_id", target_region)
	battle.set("entry_transition", transition)

	var tree := get_tree()
	tree.root.add_child(battle)
	transition.reparent(battle)
	tree.current_scene = battle
	queue_free()
