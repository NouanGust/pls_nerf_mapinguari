extends SceneTree

func _init() -> void:
	print("Importing comadre_fulozinha.glb via GLTFDocument...")
	var doc := GLTFDocument.new()
	var state := GLTFState.new()
	var err := doc.append_from_file("res://models/comadre_fulozinha/comadre_fulozinha.glb", state)
	if err != OK:
		printerr("Failed to append GLTF: ", err)
		quit(1)
		return
	
	var node := doc.generate_scene(state)
	if node == null:
		printerr("Failed to generate scene from GLTF")
		quit(1)
		return
	
	var scene := PackedScene.new()
	var pack_err := scene.pack(node)
	if pack_err != OK:
		printerr("Failed to pack scene: ", pack_err)
		quit(1)
		return
	
	var imported_dir := "res://.godot/imported"
	var scn_path := imported_dir + "/comadre_fulozinha.glb-4da796d492675e8619c512a50beb5464.scn"
	var save_err := ResourceSaver.save(scene, scn_path)
	if save_err != OK:
		printerr("Failed to save imported .scn: ", save_err)
		quit(1)
		return
	
	print("Successfully saved: ", scn_path)
	
	# Generate UID
	var uid_val := ResourceUID.create_id()
	var uid_str := ResourceUID.id_to_text(uid_val)
	print("Generated UID: ", uid_str)
	ResourceUID.add_id(uid_val, scn_path)
	
	# Write .import file
	var import_content := """[remap]

importer="scene"
importer_version=1
type="PackedScene"
uid="%s"
path="%s"

[deps]

source_file="res://models/comadre_fulozinha/comadre_fulozinha.glb"
dest_files=["%s"]

[params]

nodes/root_type=""
nodes/root_name=""
nodes/root_script=null
nodes/apply_root_scale=true
nodes/root_scale=1.0
nodes/import_as_skeleton_bones=false
nodes/use_name_suffixes=true
nodes/use_node_type_suffixes=true
meshes/ensure_tangents=true
meshes/generate_lods=true
meshes/create_shadow_meshes=true
meshes/light_baking=1
meshes/lightmap_texel_size=0.2
meshes/force_disable_compression=false
skins/use_named_skins=true
animation/import=true
animation/fps=30
animation/trimming=false
animation/remove_immutable_tracks=true
animation/import_rest_as_RESET=false
import_script/path=""
materials/extract=0
materials/extract_format=0
materials/extract_path=""
_subresources={}
gltf/naming_version=2
gltf/embedded_image_handling=1
""" % [uid_str, scn_path, scn_path]

	var f := FileAccess.open("res://models/comadre_fulozinha/comadre_fulozinha.glb.import", FileAccess.WRITE)
	f.store_string(import_content)
	f.close()
	print("Successfully wrote .import file!")
	
	# Also update comadre_fulozinha.tres to use this UID
	var tres_path := "res://resources/units/comadre_fulozinha.tres"
	var tres_text := FileAccess.get_file_as_string(tres_path)
	var old_line := '[ext_resource type="PackedScene" path="res://models/comadre_fulozinha/comadre_fulozinha.glb" id="2_model"]'
	var new_line := '[ext_resource type="PackedScene" uid="%s" path="res://models/comadre_fulozinha/comadre_fulozinha.glb" id="2_model"]' % uid_str
	if old_line in tres_text:
		tres_text = tres_text.replace(old_line, new_line)
		var f_tres := FileAccess.open(tres_path, FileAccess.WRITE)
		f_tres.store_string(tres_text)
		f_tres.close()
		print("Updated comadre_fulozinha.tres with UID: ", uid_str)
	
	quit(0)

