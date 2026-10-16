extends RefCounted

## Cada entrada acrescenta uma peça à composição no nível correspondente.
## Repetições são intencionais nas regiões com elenco pequeno; não geram sinergias extras.
const REGIONS: Dictionary = {
	"cerrado": {
		"name": "Cerrado", "color": Color("#d6ad57"),
		"description": "Raízes resistentes e guardiões da savana. Flora, proteção e caça.",
		"roster": ["pequi", "ipe_amarelo", "tamandua_bandeira", "lobo_guara", "ipe_amarelo", "pequi", "tamandua_bandeira", "lobo_guara", "ipe_amarelo"],
	},
	"pantanal": {
		"name": "Pantanal", "color": Color("#70b8be"),
		"description": "Fauna das águas e lendas das cheias. Resistência, cura e magia.",
		"roster": ["capivara", "aguape", "tamandua_bandeira", "lobo_guara", "minhocao", "teiniagua", "mae_de_ouro", "mboi_guacu", "romaozinho"],
	},
	"amazonia": {
		"name": "Amazônia", "color": Color("#7cbb89"),
		"description": "A floresta ganha força com seus protetores e suas grandes lendas.",
		"roster": ["guarana", "vitoria_regia", "anhanga", "labatut", "mapinguari", "caapora", "comadre_fulozinha", "sumauma", "boiuna"],
	},
	"caatinga": {
		"name": "Caatinga", "color": Color("#d39168"),
		"description": "Defesas do sertão e aves raras. Uma formação persistente e protetora.",
		"roster": ["tatu_bola", "mandacaru", "arara_azul_lear", "tatu_bola", "mandacaru", "arara_azul_lear", "tatu_bola", "mandacaru", "ararinha_azul"],
	},
	"mata_atlantica": {
		"name": "Mata Atlântica", "color": Color("#8cae70"),
		"description": "Flores, aves e árvores ancestrais. Suporte para uma linha de frente sólida.",
		"roster": ["sabia_laranjeira", "bromelia", "jararaca", "brinco_de_princesa", "palmito_jucara", "araucaria", "pau_brasil", "araucaria", "mutum_de_alagoas"],
	},
	"litoral": {
		"name": "Litoral", "color": Color("#85b5dd"),
		"description": "Mangues e encantos do mar. Criaturas aquáticas, flora e encantados.",
		"roster": ["bromelia", "caranguejo_uca", "palmito_jucara", "cabeca_de_cuia", "alamoa", "mboi_guacu", "pau_brasil", "mutum_de_alagoas", "mae_dagua"],
	},
}

static func get_region(region_id: String) -> Dictionary:
	return REGIONS.get(region_id, REGIONS["cerrado"])

static func get_roster(region_id: String, level: int) -> Array:
	var roster: Array = get_region(region_id)["roster"]
	return roster.slice(0, clampi(level, 1, 9))

static func get_formation(region_id: String, level: int) -> Array[Dictionary]:
	# Prioriza a frente para tanques e o fundo para as demais peças.
	var front: Array[Vector2i] = [Vector2i(3, 3), Vector2i(2, 3), Vector2i(4, 3), Vector2i(1, 3), Vector2i(5, 3), Vector2i(0, 3), Vector2i(6, 3), Vector2i(2, 2), Vector2i(4, 2)]
	var back: Array[Vector2i] = [Vector2i(3, 0), Vector2i(2, 0), Vector2i(4, 0), Vector2i(1, 0), Vector2i(5, 0), Vector2i(0, 0), Vector2i(6, 0), Vector2i(2, 1), Vector2i(4, 1)]
	var formation: Array[Dictionary] = []
	for unit_id in get_roster(region_id, level):
		var stats := load("res://resources/units/%s.tres" % unit_id) as UnitStats
		if not stats:
			push_error("Unidade regional não encontrada: %s" % unit_id)
			continue
		var position: Vector2i = front.pop_front() if not stats.is_ranged else back.pop_front()
		formation.append({"unit_id": str(unit_id), "position": position})
	return formation
