@tool
extends SceneTree

func _init() -> void:
	print("Importing pequi.glb via GLTFDocument...")
	var gltf_doc = GLTFDocument.new()
	var gltf_state = GLTFState.new()
	var err = gltf_doc.append_from_file("res://models/pequi/pequi.glb", gltf_state)
	if err != OK:
		printerr("Falha ao ler pequi.glb: ", err)
		quit(1)
		return
	
	var scene_root = gltf_doc.generate_scene(gltf_state)
	if not scene_root:
		printerr("Falha ao gerar cena para pequi.glb")
		quit(1)
		return
		
	var packed = PackedScene.new()
	var pack_err = packed.pack(scene_root)
	if pack_err != OK:
		printerr("Falha ao empacotar cena: ", pack_err)
		quit(1)
		return
		
	var target_scn_path = "res://models/pequi/pequi.tscn"
	ResourceSaver.save(packed, target_scn_path)
	print("Successfully saved: ", target_scn_path)
	quit(0)

