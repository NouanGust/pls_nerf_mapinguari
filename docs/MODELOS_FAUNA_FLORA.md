# Modelos e combate de fauna e flora

Atualizado em 19/10/2026. Os 13 integrantes de Fauna usam malhas selecionadas de `Assets/Models/EverythingLibrary_Animals_001.fbx`. As 12 plantas usam `Assets/Scenary/OBJ`. Lobo-guará mantém seus dois tipos informativos, mas continua sendo um animal móvel. Fauna e Flora não concedem sinergias adicionais.

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

- Todas têm `is_stationary = true` e velocidade zero. Plantas que não são tanques mantêm alcance de ataque 4. A regeneração de mana depende do recurso da unidade e é bloqueada durante escudos e conjuração.
- Todos os 17 tanques, identificados pela classe Tank ou pelo papel `is_tank`, têm alcance de ataque 1 e `is_ranged = false`. Isso inclui Mandacaru, Ipê-amarelo, Araucária, Pau-brasil e Sumaúma. Essas plantas permanecem imóveis e atacam apenas inimigos próximos. A regra também é aplicada em tempo de execução e na prévia de alcance durante o arraste.
- Podem ser posicionadas normalmente na preparação. Em combate, não perseguem, não giram para mirar e ignoram o deslocamento calculado pela navegação.
- Sem inimigo ao alcance, aguardam em `ROOTED`, mantêm a regeneração de mana e procuram novos alvos a cada 0,25 segundo.
- Apenas plantas com ataque à distância lançam rastro de semente. Tanques usam ataque corpo a corpo, sem projétil. O dano continua imediato, conforme o sistema de ataques existente.
- Mandacaru é tanque corpo a corpo e Pequi é atacante à distância. As outras dez plantas também concedem aura de poder a outros aliados em até **2 hexes**.
- A aura aumenta dano de ataque em 10%; Araucária, Pau-brasil e Sumaúma concedem 18%. Apenas a maior aura se aplica, sem acumular cópias e sem bônus à própria fonte.
- O bônus depende do hex e do estado atuais, sem usar a posição inicial de preparação. Termina ao sair dos hexes abrangidos, morrer, ocultar a planta no banco ou encerrar o combate. Cada hex abrangido recebe um contorno verde/vermelho enquanto a unidade estiver viva e visível no tabuleiro, inclusive na preparação e entre rounds. O destaque fica alinhado ao tabuleiro e não gira com a unidade. Exibir a área fora do combate não ativa o bônus antecipadamente.
- A distância da aura é o número de passos entre vizinhos hexagonais. O alcance de 2 inclui a célula da fonte e duas camadas de vizinhos, recortadas nas bordas do tabuleiro. A própria fonte não recebe o bônus.
- `passive_aura_range` agora é um inteiro em hexes. As auras de poder de 4 metros foram migradas para 2 hexes, mantendo seus percentuais. Os outros cadastros legados de aura tiveram a unidade de medida convertida, mas seus efeitos ainda não implementados não foram ativados nesta mudança.
- O alcance das habilidades é separado do ataque básico. Sumaúma mantém os 8 metros de cura que antes recebia pelo cálculo de alcance mínimo baseado no ataque.
- A loja informa imobilidade, alcance e aura. Os valores são um ponto inicial de balanceamento; precisam de partidas para avaliar a força do conjunto.

## Verificação

Esta alteração foi revisada por leitura do código, sem executar testes ou partidas na engine. Os scripts abaixo são referências existentes; suas expectativas antigas sobre tanques à distância e auras em metros precisam ser atualizadas antes de uma nova rodada de testes.

- `tests/biodiversity_smoke.gd`: carrega todas as 25 associações, verifica escala, apoio no chão, poses, imobilidade, aquisição de alvos, dano à distância, mana, limites de aura e morte/revivificação.
- `tests/unit_visual_smoke.gd`: regressão das animações humanoides e do ciclo de combate.
- `tests/biodiversity_gallery.gd`: renderiza a galeria em `.godot/biodiversity-gallery.png` para inspeção visual. Executar com renderização habilitada.
