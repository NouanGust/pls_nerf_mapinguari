extends SceneTree

func _init() -> void:
	var main_scene = load("res://Scenes/Main/main.tscn").instantiate()
	root.add_child(main_scene)
	var panel = main_scene.ui.get_node("Control/RightBar")
	var stats = UnitSpawner.load_unit_stats("tatu_bola")
	var unit: BaseUnit3D = UnitSpawner.spawn_unit_from_stats(stats, 1, 0)
	main_scene.show_unit_inspector(unit)
	main_scene._show_ability_floating_card(unit, panel)
	var card = main_scene._ability_floating_card
	print("CARD GLOBAL POS: ", card.global_position)
	print("CARD SIZE: ", card.size)
	print("CARD MIN SIZE: ", card.get_combined_minimum_size())
	print("CARD ANCHORS: ", card.anchor_left, ", ", card.anchor_top, ", ", card.anchor_right, ", ", card.anchor_bottom)
	print("CARD OFFSET: ", card.offset_left, ", ", card.offset_top, ", ", card.offset_right, ", ", card.offset_bottom)
	quit(0)
