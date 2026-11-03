class_name Cell3D
extends Area3D

signal hovered(grid_coord: Vector2i)
signal unhovered(grid_coord: Vector2i)
signal clicked(grid_coord: Vector2i)

var grid_coord: Vector2i = Vector2i.ZERO
var is_player_zone: bool = false

var _is_occupied: bool = false
var _is_highlited: bool = false
var _base_color: Color = Color.WHITE
var _highlight_tween: Tween = null

@onready var _mesh: MeshInstance3D = $MeshInstance3D
@onready var _zone_indicator: MeshInstance3D = $ZoneIndicator

@export var mat_base: StandardMaterial3D
@export var mat_hover: StandardMaterial3D
@export var mat_highlight: StandardMaterial3D
@export var mat_occupied: StandardMaterial3D

# --- Setup --- 

func setup(coord: Vector2i, player_zone: bool, base_color: Color) -> void:
	grid_coord = coord
	is_player_zone = player_zone
	_base_color = base_color
	_apply_zone_color(base_color)
	

# --- API ---

# Ativa/desativa o destaque de posicionamento (drag e drop)
func set_highlited(value: bool) -> void:
	if _is_highlited == value: return
	
	_is_highlited = value
	_stop_highligted_tween()
	
	if value:
		_zone_indicator.material_override = mat_highlight
		_start_pulse_tween()
	else:
		_zone_indicator.material_override = null
		_apply_zone_color(_base_color)

func set_occupied(value: bool) -> void:
	if _is_occupied == value: return
	
	_is_occupied = value
	
	if value:
		_zone_indicator.material_override = mat_occupied
	elif not _is_highlited:
		_zone_indicator.material_override = null
		_apply_zone_color(_base_color)
		
func reset_visual() -> void:
	_stop_highligted_tween()
	_is_highlited = false
	_is_occupied = false
	_zone_indicator.material_override = null
	_apply_zone_color(_base_color)

# --- Internos ---

func _apply_zone_color(color: Color) -> void:
	if _zone_indicator.get_surface_override_material_count() > 0:
		var mat := _zone_indicator.get_surface_override_material(0) as StandardMaterial3D
		if mat:
			mat.albedo_color = color
			return
			
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_zone_indicator.set_surface_override_material(0, mat)
	

func _start_pulse_tween() -> void:
	_highlight_tween = create_tween().set_loops()
	_highlight_tween.tween_property(_zone_indicator, "position:y", 0.10, 0.45).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
	_highlight_tween.tween_property(_zone_indicator, "position:y", 0.06, 0.45).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
	

func _stop_highligted_tween() -> void:
	if _highlight_tween and _highlight_tween.is_running():
		_highlight_tween.kill()
	_zone_indicator.position.y = 0.06


# --- Inputs ---

func _on_mouse_entered() -> void:
	if not _is_occupied and not _is_highlited:
		_mesh.material_override = null
	unhovered.emit(grid_coord)

func _on_input_event(_camera: Node, event: InputEvent, _pos: Vector3, _normal: Vector3, _shade_idx: int) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			clicked.emit(grid_coord) 
