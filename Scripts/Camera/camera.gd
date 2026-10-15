class_name GameCamera
extends Node3D

@export_group("Enquadramento inicial")
## 0 graus mantém o jogador na parte inferior da tela.
@export_range(-180.0, 180.0, 1.0) var initial_yaw_degrees: float = 0.0
@export_range(20.0, 80.0, 1.0) var initial_elevation_degrees: float = 55.0
## Zero calcula a distância usando o tamanho do tabuleiro e da janela.
@export_range(0.0, 80.0, 0.5) var initial_distance: float = 0.0
@export var focus_offset: Vector3 = Vector3.ZERO
@export_range(1.0, 2.0, 0.05) var framing_margin: float = 1.2
@export var look_at_position: Vector3 = Vector3.ZERO
@export_range(20.0, 90.0, 1.0) var fov: float = 50.0

@export_group("Órbita")
@export var auto_orbit_enabled: bool = false
@export_range(-60.0, 60.0, 0.5) var auto_orbit_speed: float = 10.0
## Graus por pixel ao arrastar com o botão do meio.
@export_range(0.05, 1.0, 0.05) var mouse_sensitivity: float = 0.25
@export_range(10.0, 45.0, 1.0) var min_elevation: float = 20.0
@export_range(45.0, 85.0, 1.0) var max_elevation: float = 80.0
@export var orbit_smoothing: float = 12.0

@export_group("Zoom")
@export var zoom_speed: float = 2.0
@export var min_zoom: float = 8.0
@export var max_zoom: float = 40.0
@export var zoom_smoothing: float = 10.0

@onready var camera: Camera3D = get_node_or_null("Camera3D") as Camera3D

var target_distance: float = 20.0
var current_distance: float = 20.0
var drag_handler: BoardDragHandler
var _board: Board3D
var _manual_orbit: bool = false
var _current_yaw: float = 0.0
var _target_yaw: float = 0.0
var _current_elevation: float = 0.0
var _target_elevation: float = 0.0

func _ready() -> void:
	if not camera:
		camera = Camera3D.new()
		camera.name = "Camera3D"
		add_child(camera)
	camera.fov = fov
	camera.current = true
	# O rig faz toda a órbita; a câmera permanece na origem dele.
	camera.transform = Transform3D.IDENTITY
	var start_automatically := auto_orbit_enabled
	reset_view(true)
	auto_orbit_enabled = start_automatically

func focus_on_board(board: Board3D) -> void:
	if not is_instance_valid(board):
		return
	_board = board
	look_at_position = board.global_position + Vector3(0.0, board.board_height, 0.0) + focus_offset
	var keep_auto_orbit := auto_orbit_enabled
	reset_view(true)
	auto_orbit_enabled = keep_auto_orbit

func reset_view(immediate: bool = false) -> void:
	auto_orbit_enabled = false
	_manual_orbit = false
	_target_yaw = deg_to_rad(initial_yaw_degrees)
	_target_elevation = deg_to_rad(clampf(initial_elevation_degrees, min_elevation, max_elevation))
	target_distance = clampf(initial_distance if initial_distance > 0.0 else _get_fitted_distance(), min_zoom, max_zoom)
	if immediate:
		_current_yaw = _target_yaw
		_current_elevation = _target_elevation
		current_distance = target_distance
		_update_transform()

func set_auto_orbit(enabled: bool) -> void:
	auto_orbit_enabled = enabled
	_manual_orbit = false

func _input(event: InputEvent) -> void:
	# A liberação precisa funcionar mesmo se o cursor terminar sobre a interface.
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_MIDDLE and not event.pressed:
		_manual_orbit = false
	if not _manual_orbit:
		return
	if _is_positioning_unit():
		_manual_orbit = false
		return
	if event is InputEventMouseMotion:
		_target_yaw -= deg_to_rad(event.relative.x * mouse_sensitivity)
		_target_elevation = clampf(
			_target_elevation + deg_to_rad(event.relative.y * mouse_sensitivity),
			deg_to_rad(min_elevation), deg_to_rad(max_elevation)
		)
		get_viewport().set_input_as_handled()

func _unhandled_input(event: InputEvent) -> void:
	if _is_positioning_unit():
		return
	if event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_O:
				set_auto_orbit(not auto_orbit_enabled)
				get_viewport().set_input_as_handled()
			KEY_HOME:
				reset_view()
				get_viewport().set_input_as_handled()
	elif event is InputEventMouseButton and event.pressed:
		# A UI recebe o evento antes da câmera: scroll na loja não muda o zoom.
		if get_viewport().gui_get_hovered_control() != null:
			return
		match event.button_index:
			MOUSE_BUTTON_MIDDLE:
				set_auto_orbit(false)
				_manual_orbit = true
				get_viewport().set_input_as_handled()
			MOUSE_BUTTON_WHEEL_UP:
				target_distance = clampf(target_distance - zoom_speed, min_zoom, max_zoom)
				get_viewport().set_input_as_handled()
			MOUSE_BUTTON_WHEEL_DOWN:
				target_distance = clampf(target_distance + zoom_speed, min_zoom, max_zoom)
				get_viewport().set_input_as_handled()

func _process(delta: float) -> void:
	if _is_positioning_unit():
		# Também elimina a inércia para manter o hex sob o cursor durante o arraste.
		_manual_orbit = false
		_target_yaw = _current_yaw
		_target_elevation = _current_elevation
		target_distance = current_distance
		return
	if _manual_orbit and not Input.is_mouse_button_pressed(MOUSE_BUTTON_MIDDLE):
		_manual_orbit = false
	if auto_orbit_enabled:
		_target_yaw = wrapf(_target_yaw + deg_to_rad(auto_orbit_speed) * delta, -PI, PI)
	var orbit_weight := 1.0 - exp(-maxf(orbit_smoothing, 0.1) * delta)
	_current_yaw = lerp_angle(_current_yaw, _target_yaw, orbit_weight)
	_current_elevation = lerpf(_current_elevation, _target_elevation, orbit_weight)
	current_distance = lerpf(current_distance, target_distance, 1.0 - exp(-maxf(zoom_smoothing, 0.1) * delta))
	_update_transform()

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT:
		_manual_orbit = false

func _is_positioning_unit() -> bool:
	return Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) or (is_instance_valid(drag_handler) and drag_handler.is_dragging)

func _update_transform() -> void:
	var direction := Vector3(
		sin(_current_yaw) * cos(_current_elevation),
		sin(_current_elevation),
		cos(_current_yaw) * cos(_current_elevation)
	)
	global_position = look_at_position + direction * current_distance
	look_at(look_at_position, Vector3.UP)

func _get_fitted_distance() -> float:
	if not is_instance_valid(_board):
		return 20.0
	var extents := _board.get_board_extents() + Vector2(0.8, 0.8)
	var viewport_size := get_viewport().get_visible_rect().size
	var aspect_ratio := viewport_size.x / maxf(viewport_size.y, 1.0)
	var tan_vertical := tan(deg_to_rad(fov * 0.5))
	var tan_horizontal := tan_vertical * maxf(aspect_ratio, 0.1)
	var backward := Vector3(sin(_target_yaw) * cos(_target_elevation), sin(_target_elevation), cos(_target_yaw) * cos(_target_elevation))
	var right := Vector3(cos(_target_yaw), 0.0, -sin(_target_yaw))
	var up := backward.cross(right)
	var fitted_distance := min_zoom
	# Inclui a altura das cápsulas/rótulos e a perspectiva nos cantos do campo.
	for x in [-extents.x * 0.5, extents.x * 0.5]:
		for z in [-extents.y * 0.5, extents.y * 0.5]:
			for y in [0.0, 3.0]:
				var offset := Vector3(x, y, z) - focus_offset
				var screen_distance := maxf(absf(offset.dot(right)) / tan_horizontal, absf(offset.dot(up)) / tan_vertical)
				fitted_distance = maxf(fitted_distance, offset.dot(backward) + screen_distance * framing_margin)
	return fitted_distance
