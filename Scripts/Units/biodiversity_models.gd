extends RefCounted
## Seleção explícita dentro do FBX, sem instanciar a biblioteca inteira por unidade.

const ANIMAL_PACK := "res://Assets/Models/EverythingLibrary_Animals_001.fbx"
const ANIMALS := {
	"capivara": "Animals/Marmot/base81",
	"tatu_bola": "Animals/Armadillo/base56",
	"tamandua_bandeira": "Animals/Anteater/base57",
	"lobo_guara": "Animals/RedFox/base51",
	"onca_pintada": "Animals/Cheetah/base60",
	"jararaca": "Reptiles/Rattlesnake/base124",
	"boiuna": "Reptiles/CoralSnake/base123",
	"mboi_guacu": "Reptiles/Rattlesnake/base124",
	"sabia_laranjeira": "BirdsUpright/GroundedCrow/base98",
	"arara_azul_lear": "Birds/Grackle/base116",
	"ararinha_azul": "Birds/Swallow/base106",
	"mutum_de_alagoas": "BirdsUpright/Turkey/base94",
	"caranguejo_uca": "Arachnids/EmperorScorpion/base3",
}
const PLANTS := {
	"aguape": "Lilypad", "vitoria_regia": "Lilypad",
	"bromelia": "Plant_3", "brinco_de_princesa": "Flowers",
	"guarana": "BushBerries_1", "mandacaru": "Cactus_3",
	"pequi": "CommonTree_2", "ipe_amarelo": "CommonTree_Autumn_3",
	"palmito_jucara": "PalmTree_1", "araucaria": "PineTree_3",
	"pau_brasil": "CommonTree_3", "sumauma": "Willow_3",
}
static var _animal_meshes: Dictionary = {}

static func create_model(stats: UnitStats) -> Node3D:
	var mesh: Mesh
	if ANIMALS.has(stats.unit_id):
		if _animal_meshes.is_empty():
			var library := (load(ANIMAL_PACK) as PackedScene).instantiate()
			for id in ANIMALS:
				var source := library.get_node("ANIMALS/" + ANIMALS[id]) as MeshInstance3D
				_animal_meshes[id] = source.mesh
			library.free()
		mesh = _animal_meshes[stats.unit_id]
	elif PLANTS.has(stats.unit_id):
		mesh = load("res://Assets/scenary/OBJ/%s.obj" % PLANTS[stats.unit_id]) as Mesh
	else:
		return null
	var body := Node3D.new()
	body.name = "SpeciesModel"
	var instance := MeshInstance3D.new()
	instance.name = "SpeciesMesh"
	instance.mesh = mesh
	for surface in mesh.get_surface_count():
		var original := mesh.surface_get_material(surface) as StandardMaterial3D
		if not original:
			continue
		var material := original.duplicate() as StandardMaterial3D
		if ANIMALS.has(stats.unit_id):
			# O FBX veio com Mat_Standard vermelho; as cores da espécie estão nos vértices.
			material.albedo_color = Color.WHITE
			material.vertex_color_use_as_albedo = true
			if stats.unit_id in ["arara_azul_lear", "ararinha_azul"]:
				material.albedo_color = Color("#71adff")
			elif stats.unit_id == "boiuna":
				material.albedo_color = Color("#30343c")
		else:
			# O OBJ armazena uma paleta muito escura; recupera a leitura no tabuleiro.
			material.albedo_color = original.albedo_color.linear_to_srgb()
			if stats.unit_id == "ipe_amarelo" and original.resource_name in ["Orange", "LightOrange"]:
				material.albedo_color = Color("#f4ca38")
			if stats.unit_id == "brinco_de_princesa" and original.resource_name == "Cyan":
				material.albedo_color = Color("#df579d")
		instance.set_surface_override_material(surface, material)
	var bounds := mesh.get_aabb()
	var width := maxf(bounds.size.x, bounds.size.z)
	var height_limit := 1.9 if PLANTS.has(stats.unit_id) else 1.45
	var factor := minf(1.65 / maxf(width, 0.01), height_limit / maxf(bounds.size.y, 0.01))
	instance.scale = Vector3.ONE * factor
	instance.position = -Vector3(bounds.get_center().x, bounds.position.y, bounds.get_center().z) * factor
	body.add_child(instance)
	# As malhas selecionadas olham para +Z, a mesma direção usada pelo combate.
	return body
