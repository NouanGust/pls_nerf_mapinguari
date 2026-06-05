class_name BoardManager
extends Node3D


# --- Signals ---
signal cell_hovered(grid_coord: Vector2i)
signal cell_unhovered(grid_cood: Vector2i)
signal cell_clicked(grid_coord: Vector2i)
signal board_generated()

@export var cell_scene: PackedScene

@export_group("Dimensões")
@export var columns: int = 7
@export var rows: int = 6
@export var cell_size: float = 2.0
@export var cell_spacing: float = 2.0
@export var board_height: float = 0.0
@export var player_rows: int = 3

@export_group("Cores")
@export var player_zone_color: Color = Color(0.2, 0.45, 0.9, 0.75)
@export var enemy_zone_color: Color = Color(0.9, 0.2, 0.2, 0.75)

@onready var _cells_container: Node3D
@onready var _units_container: Node3D
@onready var _fx_container: Node3D
@onready var _markers_container: Node3D

var _cell_map: Dictionary = {}

func _ready() -> void:
	assert(cell_scene != null, "BoardManager: cell_scene não está definida no editor!")


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
