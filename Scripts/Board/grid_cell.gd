class_name GridCell3D
extends StaticBody3D


# Propriedades

var grid_position: Vector2i = Vector2i.ZERO
var is_player_zone: bool = false
var is_highlighted: bool = false
var is_ocuppied: bool = false
var occupied_unit: BaseUnit3D= null
var cell_mesh: MeshInstance3D
var highlight_material: StandardMaterial3D

# Componentes

var mesh_instance: MeshInstance3D
var collision_shape: CollisionShape3D
var area: Area3D
var base_material: StandardMaterial3D
var current_material: StandardMaterial3D

# Cores base

var base_color: Color = Color(0.3, 0.4, 0.5, 0.7)
var hover_color: Color = Color(0.9, 0.9, 0.3, 0.9)
var occupied_color: Color = Color(0.5, 0.5, 0.5, 0.6)


# Sinais

signal cell_clicked(grid_pos: Vector2i)
signal cell_hovered(grid_pos: Vector2i)

func _init() -> void:
	collision_layer = 2
	collision_mask = 0

func _ready() -> void:
	if not mesh_instance:
		setup(2.0)
	setup_area()
	
	input_ray_pickable = true
	


func setup(size: float) -> void:
	# Criar mesh da célula BASE (cinza)
	mesh_instance = MeshInstance3D.new()
	mesh_instance.name = "BaseMesh"
	var mesh := BoxMesh.new()
	mesh.size = Vector3(size, 0.1, size)
	mesh_instance.mesh = mesh
	
	# Material cinza neutro
	var base_mat := StandardMaterial3D.new()
	base_mat.albedo_color = Color(0.25, 0.28, 0.32, 1.0)  # Cinza escuro
	base_mat.metallic = 0.3
	base_mat.roughness = 0.7
	mesh_instance.material_override = base_mat
	add_child(mesh_instance)
	
	# INDICADOR DE ZONA (plano colorido no topo)
	var zone_indicator := MeshInstance3D.new()
	zone_indicator.name = "ZoneIndicator"
	var plane_mesh := PlaneMesh.new()
	plane_mesh.size = Vector2(size * 0.8, size * 0.8)  # 80% do tamanho da célula
	zone_indicator.mesh = plane_mesh
	zone_indicator.position = Vector3(0, 0.06, 0)  # Levemente acima
	zone_indicator.rotate_x(-PI / 2)  # Rotacionar para ficar horizontal
	
	# Material colorido do indicador
	base_material = StandardMaterial3D.new()
	base_material.albedo_color = base_color
	base_material.metallic = 0.2
	base_material.roughness = 0.5
	base_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	zone_indicator.material_override = base_material
	current_material = base_material
	
	mesh_instance.add_child(zone_indicator)
	
	# Collision shape
	collision_shape = CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(size, 0.1, size)
	collision_shape.shape = shape
	add_child(collision_shape)
	
	# Bordas opciais (pode comentar)
	create_border(size)



func create_border(size: float) -> void:
	var border_material := StandardMaterial3D.new()
	border_material.albedo_color = Color(0.9, 0.9, 0.9, 0.4)
	border_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	border_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	var border_thickness := 0.02
	var border_height := 0.08
	
	var sides := [
		Vector3(size/2, 0, 0), # Direita
		Vector3(-size/2, 0, 0), # Esquerda
		Vector3(0, 0, size/2), # Frente
		Vector3(0, 0, -size/2), # Trás
	]
	
	var sizes := [
		Vector3(border_thickness, border_height, size - 0.05),
		Vector3(border_thickness, border_height, size - 0.05),
		Vector3(size - 0.05, border_height, border_thickness),
		Vector3(size - 0.05, border_height, border_thickness)
	]

	for i in 4:
		var border := MeshInstance3D.new()
		var border_mesh := BoxMesh.new()
		border_mesh.size = sizes[i]
		border.mesh = border_mesh
		border.material_override = border_material
		border.position = sides[i]
		mesh_instance.add_child(border)

func setup_area() -> void:
	# Area3D para detectar o mouse
	
	area = Area3D.new()
	area.name = "MouseArea"
	area.collision_layer = 0
	area.collision_mask = 0
	area.monitorable = true
	area.monitoring = false
	area.input_ray_pickable = true
	
	var area_shape := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = collision_shape.shape.size
	area_shape.shape = shape
	area.add_child(area_shape)
	
	area.mouse_entered.connect(_on_mouse_entered)
	area.mouse_exited.connect(_on_mouse_exited)
	area.input_event.connect(_on_input_event)
	
	

func set_base_color(color: Color) -> void:
	base_color = color
	
	
	# Atualizar apenas o indicador de zona
	if mesh_instance and mesh_instance.has_node("ZoneIndicator"):
		var zone_indicator: MeshInstance3D = mesh_instance.get_node("ZoneIndicator")
		
		base_material = StandardMaterial3D.new()
		base_material.albedo_color = color
		base_material.metallic = 0.2
		base_material.roughness = 0.5
		base_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		
		zone_indicator.material_override = base_material
		current_material = base_material
		print("  -> Cor do indicador aplicada: %s" % color)
	else:
		print("ZoneIndicator não encontrado!")


func set_highlighted(highlighted: bool) -> void:
	is_highlighted = highlighted
	
	if not mesh_instance or not mesh_instance.has_node("ZoneIndicator"):
		return
	
	var zone_indicator: MeshInstance3D = mesh_instance.get_node("ZoneIndicator")
	
	if highlighted:
		# Material de hover (amarelo brilhante)
		var highlight_mat := StandardMaterial3D.new()
		highlight_mat.albedo_color = Color(1.0, 0.95, 0.3, 0.9)
		highlight_mat.metallic = 0.3
		highlight_mat.roughness = 0.4
		highlight_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		highlight_mat.emission_enabled = true
		highlight_mat.emission = Color(0.8, 0.8, 0.2)
		highlight_mat.emission_energy_multiplier = 1.5
		
		zone_indicator.material_override = highlight_mat
		
		# Animação de "pulso"
		var tween := create_tween()
		tween.set_loops()
		tween.tween_property(zone_indicator, "position:y", 0.08, 0.5)
		tween.tween_property(zone_indicator, "position:y", 0.06, 0.5)
	else:
		# Voltar ao material base
		zone_indicator.material_override = base_material
		zone_indicator.position.y = 0.06
		

func set_occupied(ocuppied: bool) -> void:
	is_ocuppied = ocuppied
	
	if ocuppied:
		var ocuppied_mat = StandardMaterial3D.new()
		ocuppied_mat.albedo_color =  occupied_color
		ocuppied_mat.metallic = 0.4
		ocuppied_mat.roughness = 0.8
		ocuppied_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		
		mesh_instance.material_override = ocuppied_mat
		

func _on_mouse_entered() -> void:
	if not is_highlighted:
		set_highlighted(true)
	cell_hovered.emit(grid_position)

func _on_mouse_exited() -> void:
	if is_highlighted and not is_ocuppied:
		set_highlighted(false)

func _on_input_event(_camera: Node, event: InputEvent, _position: Vector3, _normal: Vector3, _shape_idx: int) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			cell_clicked.emit(grid_position)
			print("Célula clicada: %v " %grid_position)
