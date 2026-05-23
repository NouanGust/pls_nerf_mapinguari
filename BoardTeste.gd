extends Node3D

@onready var mesh: MeshInstance3D = $Area3D/MeshInstance3D

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass
	


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_area_3d_mouse_entered() -> void:
	var material = mesh.get_active_material(0)
	material.albedo_color = Color(1, 0, 0)


func _on_area_3d_mouse_exited() -> void:
	var material = mesh.get_active_material(0)
	material.albedo_color = Color(0, 1, 1)
	
