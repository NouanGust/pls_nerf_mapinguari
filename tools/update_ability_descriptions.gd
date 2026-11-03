extends SceneTree

const DESCRIPTIONS: Dictionary = {
	# ==========================================================================
	# TIER 1
	# ==========================================================================
	"brinco_de_princesa": "Dispara dardos florais que recuperam 65 de vida dos 2 aliados feridos mais próximos e causam 55 de dano mágico ao inimigo alvo.",
	"bromelia": "Canaliza uma névoa de orvalho que restaura 65 de vida dos 2 aliados mais feridos dentro de seu alcance.",
	"capivara": "Cria uma barreira aquática protetora que concede 90 de escudo próprio até ser consumido (não gera mana enquanto protegida).",
	"cumacanga": "Lança uma bola de fogo balística na maior aglomeração de inimigos, causando 45 de dano mágico em área e queimando todos os alvos por 2.0s.",
	"guarana": "Dispara sementes revigorantes que concedem 15 de mana aos 2 aliados próximos com menor proporção de mana (sem escudo ativo).",
	"mandacaru": "Ergue espinhos de cacto no solo, causando 65 de dano mágico ao alvo atual e renovando 60 de escudo protetor a si mesmo.",
	"pequi": "Dispara uma semente pontiaguda explosiva que atinge o alvo atual causando 95 de dano mágico concentrado.",
	"sabia_laranjeira": "Voa em mergulho rasante até o alvo desferindo uma bicada certeira de 95 de dano físico e recebe +35% de velocidade de ataque e movimento por 4.0s.",
	"tatu_bola": "Encolhe-se em sua carapaça blindada, renovando um escudo defensivo de 110 até ser destruído (não gera mana enquanto protegido).",

	# ==========================================================================
	# TIER 2
	# ==========================================================================
	"aguape": "Invoca um santuário aquático purificante que restaura 110 de vida dos 2 aliados feridos mais próximos.",
	"arara_azul_lear": "Alça voo e dispara uma pena sônica cintilante no inimigo com maior poder de ataque, causando 150 de dano mágico.",
	"caranguejo_uca": "Desfere um golpe esmagador com suas pinças causando 90 de dano físico ao alvo e fortalece sua carapaça com 130 de escudo.",
	"ipe_amarelo": "Cristaliza uma densa camada de pétalas douradas que concede 150 de escudo protetor a si mesmo até ser consumido.",
	"jararaca": "Teletransporta-se em emboscada pelas sombras para trás do inimigo mais ferido, desferindo um bote letal de 170 de dano físico.",
	"lobo_guara": "Espalha frutos curativos da lobeira pelo campo, restaurando 70 de vida dos 2 aliados feridos mais próximos.",
	"palmito_jucara": "Lança frutos ancestrais que restauram 75 de vida a 2 aliados feridos e abastecem 10 de mana aos 2 aliados mais necessitados.",
	"papa_figo": "Desfere uma rajada congelante causando 115 de dano mágico, reduzindo o ataque do alvo em 25% por 5.0s e curando o aliado mais ferido em 80 de vida.",
	"tamandua_bandeira": "Golpea com garras frontais causando 100 de dano mágico ao alvo e assume postura protetora com 110 de escudo.",
	"vitoria_regia": "Cria um santuário de águas serenas que restaura 100 de vida dos 2 aliados feridos mais próximos.",

	# ==========================================================================
	# TIER 3
	# ==========================================================================
	"alamoa": "Entoa uma melodia hipnótica sedutora que atordoa e imobiliza os 2 inimigos mais próximos por 3.0 segundos.",
	"anhanga": "Ecoa um rugido espectral aterrorizante que intimida todos os inimigos em um raio de 3.0m, reduzindo seu dano de ataque em 30% por 4.0s.",
	"cabeca_de_cuia": "Estende gavinhas sombrias e puxa o inimigo mais distante para perto, causando 110 de dano mágico e quebrando 15 de sua armadura por 4.0s.",
	"labatut": "Canaliza energias medicinais da mata que restauram 100 de vida aos 2 aliados mais feridos na área.",
	"mae_de_ouro": "Gira em um vórtice dourado flamejante, atingindo até 2 inimigos próximos com 220 de dano mágico e queimadura por 2.0s, enquanto cura 120 de vida dos 2 aliados mais feridos.",
	"mapinguari": "Endurece seu couro impenetrável por 4.0s, refletindo 40% de todo o dano recebido de volta aos seus atacantes.",
	"matinta_perera": "Transforma-se em pássaro sombrio e mergulha imune sobre o alvo, causando 140 de dano mágico, atordoando-o com confusão por 2.5s e causando 70 de dano em área antes de retornar ao lugar.",
	"minhocao": "Rompe o solo em uma cratera violenta, causando 180 de dano físico e atordoando todos os inimigos em um raio de 3.5m por 2.0 segundos.",
	"quibungo": "Aprisiona o inimigo em seu saco escuro por 3.0s, atordoando-o e causando 40 de dano verdadeiro imediato mais 40 de dano verdadeiro a cada segundo.",
	"teiniagua": "Conjura e arremessa uma orbe mística concentrada que explode no alvo e hexágonos adjacentes, causando 240 de dano mágico em área.",

	# ==========================================================================
	# TIER 4
	# ==========================================================================
	"araucaria": "Ergue uma frondosa barreira de raízes que concede 260 de escudo a si mesma e 221 de escudo a todos os aliados próximos por 4.0s.",
	"caapora": "Dispara uma flecha encantada em linha reta que atravessa todos os inimigos no caminho causando 200 de dano físico e quebrando 18 de armadura do primeiro alvo por 4.0s.",
	"comadre_fulozinha": "Invoca 2 espíritos da floresta por 10.0s que orbitam o campo atacando inimigos com 45 de dano mágico ou restaurando 35 de vida de aliados feridos.",
	"corpo_seco": "Canaliza raízes espinhosas que drenam até 3 inimigos próximos, infligindo 120 de dano verdadeiro e curando a si mesmo em 80 de vida por alvo atingido por 4.0s.",
	"mboi_guacu": "Enrosca-se na presa, imobilizando-a e reduzindo sua armadura em 20 por 4.0s, enquanto ganha 160 de escudo e causa 40 de dano físico por segundo.",
	"onca_pintada": "Salta ferozmente pelas costas do inimigo com menor vida, desferindo um ataque devastador de 230 de dano físico imediato.",
	"pau_brasil": "Desperta uma florada dourada mística que causa 100 de dano mágico e reduz o ataque de inimigos próximos em 25%, concedendo 170 de escudo ao aliado mais ferido por 4.0s.",
	"pisadeira": "Esmaga o ânimo dos adversários em um raio de 3.5m, paralisando-os por 2.5s e drenando 25 de mana de cada inimigo afetado.",
	"sumauma": "Faz brotar raízes colossais que enraízam inimigos próximos por 3.0s causando 70 de dano, enquanto cura o aliado mais ferido em 100 de vida e lhe concede 180 de escudo.",

	# ==========================================================================
	# TIER 5
	# ==========================================================================
	"ararinha_azul": "Lidera um coro celestial sobre a caatinga que restaura 220 de vida a até 3 aliados feridos na área de alcance.",
	"boiuna": "Invoca uma onda colossal mística que devasta até 3 inimigos causando 400 de dano mágico e restaura 300 de vida a até 3 aliados feridos.",
	"mae_dagua": "Purifica o campo com águas místicas sagradas, restaurando 350 de vida aos 3 aliados mais feridos.",
	"mutum_de_alagoas": "Abre suas asas protetoras sobre a floresta, regenerando 90 de vida de até 3 aliados próximos continuamente por 3.5 segundos.",
	"pe_de_garrafa": "Mira infalivelmente no ponto fraco do inimigo mais distante, disparando um projétil devastador de 500 de dano físico.",
	"romaozinho": "Conjurando magia travessa imprevisível, atinge até 2 inimigos com 300 de dano mágico e cura 2 aliados em 300 de vida.",
	"tutu_maramba": "Solta um bramido aterrador que causa 180 de dano e amedronta todos os inimigos num raio de 4.0m, reduzindo seu poder de ataque por 4.0s."
}

func _init() -> void:
	print("\n==========================================")
	print("ATUALIZANDO DESCRIÇÕES COMPLETAS DE TODAS AS UNIDADES")
	print("==========================================\n")
	
	var dir_path := "res://resources/units/"
	var updated_count := 0
	
	for unit_id in DESCRIPTIONS:
		var file_path: String = dir_path + str(unit_id) + ".tres"
		if not FileAccess.file_exists(file_path):
			printerr("Arquivo não encontrado: ", file_path)
			continue
		
		var res: UnitStats = load(file_path)
		if not res:
			printerr("Erro ao carregar recurso: ", file_path)
			continue
		
		var new_desc: String = DESCRIPTIONS[unit_id]
		res.ability_description = new_desc
		var err := ResourceSaver.save(res, file_path)
		if err == OK:
			print("  [OK] %-20s: '%s'" % [res.unit_name, new_desc])
			updated_count += 1
		else:
			printerr("  [ERRO] Falha ao salvar %s: %s" % [file_path, error_string(err)])
	
	print("\n==========================================")
	print("SUCESSO: %d de %d unidades atualizadas com descrições ricas e completas!" % [updated_count, DESCRIPTIONS.size()])
	print("==========================================\n")
	quit(0)
