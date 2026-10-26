extends RefCounted

## Progressão própria da campanha: cada estrela corresponde a uma vaga do elenco.
## O último marco permanece estável até a vitória ou o fim da campanha.
const ENEMY_STAGES: Array[Dictionary] = [
	{"round": 1, "level": 1, "stars": [1]},
	{"round": 3, "level": 2, "stars": [1, 1]},
	{"round": 5, "level": 3, "stars": [2, 1, 1]},
	{"round": 7, "level": 4, "stars": [2, 2, 1, 1]},
	{"round": 9, "level": 5, "stars": [2, 2, 2, 1, 1]},
	{"round": 12, "level": 6, "stars": [2, 2, 2, 2, 2, 1]},
	{"round": 15, "level": 7, "stars": [3, 2, 2, 2, 2, 2, 1]},
	{"round": 18, "level": 8, "stars": [3, 3, 2, 2, 2, 2, 2, 1]},
	{"round": 21, "level": 9, "stars": [3, 3, 3, 2, 2, 2, 2, 2, 2]},
]

const FORMATION_NAMES: Array[String] = ["Centro", "Flanco esquerdo", "Flanco direito", "Dispersa"]
const COLUMN_ORDERS: Array = [
	[3, 2, 4, 1, 5, 0, 6],
	[1, 0, 2, 3, 4, 5, 6],
	[5, 6, 4, 3, 2, 1, 0],
	[0, 6, 2, 4, 1, 5, 3],
]

## Cada entrada acrescenta uma peça à composição no nível correspondente.
## Repetições são intencionais nas regiões com elenco pequeno; não geram sinergias extras.
const REGIONS: Dictionary = {
	"cerrado": {
		"name": "Cerrado", "color": Color("#d6ad57"),
		"description": "Raízes resistentes e guardiões da savana. Flora, proteção e caça.",
		"roster": ["pequi", "ipe_amarelo", "tamandua_bandeira", "pequi", "ipe_amarelo", "tamandua_bandeira", "ipe_amarelo", "tamandua_bandeira", "lobo_guara"],
	},
	"pantanal": {
		"name": "Pantanal", "color": Color("#70b8be"),
		"description": "Fauna das águas e lendas das cheias. Resistência, cura e magia.",
		"roster": ["capivara", "aguape", "minhocao", "teiniagua", "mae_de_ouro", "tamandua_bandeira", "pau_brasil", "mboi_guacu", "romaozinho"],
	},
	"amazonia": {
		"name": "Amazônia", "color": Color("#7cbb89"),
		"description": "A floresta ganha força com seus protetores e suas grandes lendas.",
		"roster": ["guarana", "vitoria_regia", "anhanga", "labatut", "caapora", "comadre_fulozinha", "sumauma", "mapinguari", "boiuna"],
	},
	"caatinga": {
		"name": "Caatinga", "color": Color("#d39168"),
		"description": "Defesas do sertão e aves raras. Uma formação persistente e protetora.",
		"roster": ["mandacaru", "tatu_bola", "arara_azul_lear", "mandacaru", "tatu_bola", "arara_azul_lear", "mandacaru", "arara_azul_lear", "ararinha_azul"],
	},
	"mata_atlantica": {
		"name": "Mata Atlântica", "color": Color("#8cae70"),
		"description": "Flores, aves e árvores ancestrais. Suporte para uma linha de frente sólida.",
		"roster": ["sabia_laranjeira", "brinco_de_princesa", "palmito_jucara", "jararaca", "pau_brasil", "sabia_laranjeira", "pau_brasil", "araucaria", "mutum_de_alagoas"],
	},
	"litoral": {
		"name": "Litoral", "color": Color("#85b5dd"),
		"description": "Mangues e encantos do mar. Criaturas aquáticas, flora e encantados.",
		"roster": ["bromelia", "caranguejo_uca", "palmito_jucara", "cabeca_de_cuia", "caranguejo_uca", "cabeca_de_cuia", "pau_brasil", "alamoa", "mae_dagua"],
	},
}

static func get_region(region_id: String) -> Dictionary:
	return REGIONS.get(region_id, REGIONS["cerrado"])

static func get_roster(region_id: String, level: int) -> Array:
	var roster: Array = get_region(region_id)["roster"]
	return roster.slice(0, clampi(level, 1, 9))

static func get_champion(region_id: String) -> UnitStats:
	# O retrato representa o maior custo da formação; vida desempata o custo.
	var champion: UnitStats = null
	for unit_id in get_roster(region_id, 9):
		var candidate := load("res://resources/units/%s.tres" % unit_id) as UnitStats
		if candidate and (not champion or candidate.tier > champion.tier or (candidate.tier == champion.tier and candidate.max_health > champion.max_health)):
			champion = candidate
	return champion

static func get_enemy_stage(round_number: int) -> Dictionary:
	var stage: Dictionary = ENEMY_STAGES[0]
	for candidate in ENEMY_STAGES:
		if round_number < int(candidate["round"]):
			break
		stage = candidate
	return stage

static func get_next_enemy_stage(round_number: int) -> Dictionary:
	for stage in ENEMY_STAGES:
		if int(stage["round"]) > round_number:
			return stage
	return {}

static func get_formation_index(region_id: String, round_number: int) -> int:
	var region_offset := maxi(REGIONS.keys().find(region_id), 0)
	return posmod(maxi(round_number, 1) - 1 + region_offset, COLUMN_ORDERS.size())

static func get_formation_for_round(region_id: String, round_number: int) -> Array[Dictionary]:
	var stage := get_enemy_stage(round_number)
	var columns: Array = COLUMN_ORDERS[get_formation_index(region_id, round_number)]
	# Reservas de casas separadas: nunca sobrepõe duas unidades, mesmo com 9
	# atacantes à distância. Plantas tanque também ocupam a linha de frente.
	var front: Array[Vector2i] = []
	var back: Array[Vector2i] = []
	for row in [3, 2]:
		for column in columns:
			front.append(Vector2i(int(column), row))
	for row in [0, 1]:
		for column in columns:
			back.append(Vector2i(int(column), row))
	var formation: Array[Dictionary] = []
	var roster := get_roster(region_id, int(stage["level"]))
	for index in roster.size():
		var unit_id := str(roster[index])
		var stats := load("res://resources/units/%s.tres" % unit_id) as UnitStats
		if not stats:
			push_error("Unidade regional não encontrada: %s" % unit_id)
			continue
		var position: Vector2i = front.pop_front() if stats.is_tank or not stats.is_ranged else back.pop_front()
		formation.append({"unit_id": unit_id, "position": position, "stars": int(stage["stars"][index])})
	return formation
