# Modelos e combate de fauna e flora

Atualizado em 17/10/2026. Os 13 integrantes de Fauna usam malhas selecionadas de `Assets/Models/EverythingLibrary_Animals_001.fbx`. As 12 plantas usam `Assets/Scenary/OBJ`. Lobo-guará mantém suas duas afinidades, mas continua sendo um animal móvel.

## Associações visuais

| Unidade | Modelo do pacote | Critério |
| --- | --- | --- |
| Capivara | Marmot | Roedor robusto; aproximação |
| Tatu-bola | Armadillo | Tatu |
| Tamanduá-bandeira | Anteater | Tamanduá |
| Lobo-guará | RedFox | Canídeo de pelagem avermelhada; aproximação |
| Onça-pintada | Cheetah | Felino pintado; aproximação |
| Jararaca | Rattlesnake | Serpente de padrão terroso; aproximação |
| Boiúna | CoralSnake | Serpente com material escurecido |
| Mboi-Guaçu | Rattlesnake | Serpente |
| Sabiá-laranjeira | GroundedCrow | Ave pousada; aproximação |
| Arara-azul-de-lear | Grackle | Ave de asas abertas com tonalidade azul; aproximação |
| Ararinha-azul | Swallow | Ave menor de asas abertas com tonalidade azul; aproximação |
| Mutum-de-alagoas | Turkey | Ave terrestre robusta; aproximação |
| Caranguejo-uçá | EmperorScorpion | Artrópode com pinças; provisório, o pacote não possui caranguejo |
| Aguapé / Vitória-régia | Lilypad | Folha aquática com flor |
| Bromélia | Plant_3 | Folhas em roseta |
| Brinco-de-princesa | Flowers | Flores tingidas de rosa |
| Guaraná | BushBerries_1 | Arbusto com frutos vermelhos |
| Mandacaru | Cactus_3 | Cacto ramificado |
| Pequi | CommonTree_2 | Árvore de copa arredondada |
| Ipê-amarelo | CommonTree_Autumn_3 | Copa recolorida de amarelo |
| Palmito-juçara | PalmTree_1 | Palmeira |
| Araucária | PineTree_3 | Conífera; aproximação |
| Pau-brasil | CommonTree_3 | Árvore frondosa |
| Sumaúma | Willow_3 | Árvore de copa volumosa; aproximação |

O catálogo em `Scripts/Units/biodiversity_models.gd` compartilha as malhas, centraliza a base no chão e limita o volume à casa do tabuleiro. As cores dos vértices substituem o vermelho do material padrão do FBX. Materiais de dano/evolução são independentes por unidade. Os modelos do pacote são estáticos e recebem movimentos procedurais simples; as lendas sem afinidade Fauna/Flora mantêm o humanoide animado.

## Plantas em combate

- Todas têm `is_stationary = true`, velocidade zero, alcance de ataque 4 (8 metros mais a tolerância de combate existente) e regeneração de 5 mana/s durante o combate.
- Podem ser posicionadas normalmente na preparação. Em combate, não perseguem, não giram para mirar e ignoram o deslocamento calculado pela navegação.
- Sem inimigo ao alcance, aguardam em `ROOTED`, mantêm a regeneração de mana e procuram novos alvos a cada 0,25 segundo.
- Ataques lançam um rastro de semente. O dano continua imediato, conforme o sistema de ataques existente; o rastro é visual.
- Mandacaru e Pequi se concentram em ataques à distância. As outras dez plantas também concedem aura de poder a outros aliados num raio de 4 metros.
- A aura aumenta dano de ataque em 10%; Araucária, Pau-brasil e Sumaúma concedem 18%. Apenas a maior aura se aplica, sem acumular cópias e sem bônus à própria fonte.
- O bônus depende da posição e do estado atuais: termina imediatamente ao sair do raio, morrer, ocultar a planta no banco ou encerrar o combate. A circunferência verde/vermelha indica o raio durante a batalha.
- A loja informa imobilidade, alcance e aura. Os valores são um ponto inicial de balanceamento; precisam de partidas para avaliar a força do conjunto.

## Verificação

- `tests/biodiversity_smoke.gd`: carrega todas as 25 associações, verifica escala, apoio no chão, poses, imobilidade, aquisição de alvos, dano à distância, mana, limites de aura e morte/revivificação.
- `tests/unit_visual_smoke.gd`: regressão das animações humanoides e do ciclo de combate.
- `tests/biodiversity_gallery.gd`: renderiza a galeria em `.godot/biodiversity-gallery.png` para inspeção visual. Executar com renderização habilitada.
