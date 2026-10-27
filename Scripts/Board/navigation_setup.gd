# res://Scripts/Board/navigation_baker.gd
extends NavigationRegion3D

@export var auto_bake_on_ready: bool = true
@export var rebake_on_change: bool = true

func _ready() -> void:
	if auto_bake_on_ready:
		call_deferred("bake_navigation_delayed")

func bake_navigation_delayed() -> void:
	await get_tree().create_timer(1.0).timeout
	
	if not navigation_mesh:
		push_error("[ERRO] NavigationMesh não configurado!")
		return
	
	print("\n[NAV] Iniciando bake do NavigationMesh...")
	
	var has_geometry := check_for_geometry()
	if not has_geometry:
		push_warning("[AVISO] Nenhuma geometria encontrada para navegação!")
		return
	
	bake_navigation_mesh()
	
	await get_tree().process_frame
	
	# VERIFICAR SE O NAVIGATION SERVER ESTÁ ATIVO
	var nav_map := get_navigation_map()
	if nav_map.is_valid():
		print("[OK] NavigationMesh baked com sucesso!")
		print("   Região: %s" % get_region_rid())
		print("   Mapa: %s" % nav_map)
		
		# Verificar se o mapa está ativo
		var is_active := NavigationServer3D.map_is_active(nav_map)
		print("   Mapa ativo: %s" % is_active)
	else:
		push_error("[ERRO] Navigation Map inválido!")

func check_for_geometry() -> bool:
	var root := get_tree().root
	var static_bodies := find_static_bodies(root)
	
	print("   Encontrados %d StaticBody3D na cena" % static_bodies.size())
	
	for body in static_bodies:
		if body.collision_layer & 4:  # Layer 3
			print("   [OK] Geometria navegável encontrada: %s" % body.name)
			return true
	
	print("   [AVISO] Nenhuma geometria no Layer 3 encontrada")
	return false

func find_static_bodies(node: Node) -> Array:
	var bodies := []
	
	if node is StaticBody3D:
		bodies.append(node)
	
	for child in node.get_children():
		bodies.append_array(find_static_bodies(child))
	
	return bodies

func force_rebake() -> void:
	print("Forçando rebake do NavigationMesh...")
	bake_navigation_mesh()
