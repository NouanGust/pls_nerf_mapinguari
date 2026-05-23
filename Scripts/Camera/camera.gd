class_name GameCamera
extends Node3D

@export var target_position: Vector3 = Vector3(0, 15, 10)
@export var look_at_position: Vector3 = Vector3(0, 0, 0)
@export var fov: float = 50.0

@export_group("Zoom")
@export var zoom_speed: float = 2.0
@export var min_zoom: float = 8.0
@export var max_zoom: float = 25.0
@export var zoom_smoothing: float = 10.0

@onready var camera: Camera3D = $Camera3D

var target_distance: float = 15.0
var current_distance: float = 15.0

func _ready() -> void:
	if not camera:
		camera = Camera3D.new()
		add_child(camera)
	
	camera.fov = fov
	camera.current = true
	position = target_position
	look_at(look_at_position, Vector3.UP)
	
	current_distance = position.distance_to(look_at_position)
	target_distance = current_distance

func _input(event: InputEvent) -> void:
	# Zoom apenas com scroll
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			target_distance = clamp(target_distance - zoom_speed, min_zoom, max_zoom)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			target_distance = clamp(target_distance + zoom_speed, min_zoom, max_zoom)

func _process(delta: float) -> void:
	# Suavizar zoom
	current_distance = lerp(current_distance, target_distance, delta * zoom_smoothing)
	
	# Atualizar posição mantendo o ângulo
	var direction: Vector3 = (position - look_at_position).normalized()
	position = look_at_position + direction * current_distance

func focus_on_board(board: Board3D) -> void:
	#var center_cell: GridCell3D = board.get_cell(Vector2i(board.columns / 2, board.rows / 2))
	#if center_cell:
		#look_at_position = center_cell.global_position
	
		# Posicionar câmera em ângulo isométrico fixo
		var distance: float = 15.0
		var angle_vertical: float = deg_to_rad(45)  # 45 graus de cima
		var angle_horizontal: float = deg_to_rad(0)  # Centralizado
		
		position = look_at_position + Vector3(
			sin(angle_horizontal) * distance * cos(angle_vertical),
			distance * sin(angle_vertical),
			cos(angle_horizontal) * distance * cos(angle_vertical)
		)
		
		look_at(look_at_position, Vector3.UP)
		
		current_distance = distance
		target_distance = distance
		
		print("Câmera focada no board")
