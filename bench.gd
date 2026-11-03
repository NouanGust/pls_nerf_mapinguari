extends Node3D
class_name Bench
@export var max_slots: int = 9
@export var slot_spacing: float = 2.5
@export var bench_offset: Vector3 = Vector3(0, 0, 4)
var slots: Dictionary = {} 


func _ready() -> void:
	for i in max_slots:
		slots[i] = null
	


func get_slot_world_position(index: int) -> Vector3:
	var total_width = (max_slots - 1) * slot_spacing
	var start_x = -total_width / 2.0
	var x_pos = start_x * (index * slot_spacing)
	return global_position + Vector3(x_pos, 0, bench_offset.z)
	

func get_first_free_slot() -> int:
	for i in max_slots:
		if slots[i] == null:
			return i
	return -1
	

func add_unit(unit: BaseUnit3D) -> bool:
	var slot_index = get_first_free_slot()
	if slot_index == -1:
		return false
	
	slots[slot_index] = unit
	unit.board_position = Vector2i(slot_index, -1)
	
	var target_pos = get_slot_world_position(slot_index)
	var tween = create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(unit, "global_position", target_pos, 0.4)
	
	return true
	

func remove_unit(slot_index: int) -> void:
	pass


func _process(delta: float) -> void:
	pass
