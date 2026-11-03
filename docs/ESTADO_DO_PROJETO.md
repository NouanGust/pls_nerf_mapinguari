# Folchess — panorama do projeto

## Atualização de fluxo — 16/10/2026

A cena principal agora é `Scenes/UI/Menu.tscn`: Iniciar → escolha entre seis regiões → partida. As composições inimigas são definidas por região e crescem de uma a nove peças conforme o nível. Jogador e inimigo recebem 2 XP por round; o jogador compra 4 XP por 4 ouro. A capacidade do campo corresponde ao nível, com teto 9. O fim de jogo retorna ao menu. Detalhes e formações: [FLUXO_REGIOES_E_XP.md](FLUXO_REGIOES_E_XP.md).

O levantamento abaixo é histórico: suas referências à ausência de cena principal, ao início de teste e ao elenco antigo foram substituídas pelas alterações posteriores.

## Levantamento original

Atualizado em 15/10/2026 a partir de uma leitura estática do repositório. Este documento registra o estado observado no código e nos arquivos; não houve execução do jogo nem validação de exportação.

## Resumo

Folchess é um protótipo de auto chess 3D inspirado no folclore brasileiro, feito em Godot 4.6 com GDScript. A estrutura já contém uma fatia jogável de preparação e combate: tabuleiro dividido entre jogador e inimigo, loja de unidades, compra e posicionamento por arrastar, atributos e IA de combate, recompensas e progressão por rodadas. Também há um conjunto de 22 recursos de unidade, modelos, imagens, efeitos e cenas de interface.

Estado estimado: **protótipo/vertical slice em desenvolvimento, ainda distante de uma beta publicável**. A lógica está concentrada em poucos scripts grandes e há sinais explícitos de teste e depuração no fluxo inicial. O projeto não inclui README, plano de testes, configuração de exportação ou cena principal configurada no `project.godot`.

## Tecnologias e formato

- **Engine:** Godot 4.6, renderizador Forward Plus.
- **Linguagem:** GDScript; os arquivos `.gd.uid`, `.import` e recursos `.tres` fazem parte do formato normal do projeto Godot.
- **Projeto:** não há dependências externas ou gerenciador de pacotes identificado. Assets 3D incluem GLB/OBJ e texturas; dados de unidades são recursos Godot.
- **Git:** branch observada `main`, alinhada com `origin/main`; a árvore estava limpa durante a análise. Histórico recente contém commits de modelos/texturas e estado do jogo.
- **Execução:** `Scenes/Main/main.tscn` contém o nó raiz `Main` e o script principal, mas `project.godot` não define `run/main_scene`. Para abrir como jogo é preciso configurar a cena inicial ou selecionar a cena manualmente no editor.
- **Publicação:** não foi encontrado `export_presets.cfg`; não há evidência de builds ou pipeline de integração contínua.

## Estrutura e arquitetura observadas

| Caminho | Responsabilidade |
| --- | --- |
| `project.godot` | Configuração geral do projeto e versão da engine. |
| `Scenes/Main/main.tscn` | Cena de jogo; conecta tabuleiro, câmera, UI, navegação e ambiente. |
| `Scripts/main.gd` | Orquestra estado da partida, loja, compra, banco, rodadas, combate, recompensas e atualização da UI. É o maior ponto de acoplamento. |
| `Scripts/Board/board.gd` | `Board3D`: gera campo hexagonal espelhado de 8×7; cada equipe ocupa uma metade de 4×7, com colisão e geometria de navegação. Rastreia ocupação, posicionamento e movimento de unidades. |
| `Scripts/Board/board_drag_handler.gd` | Entrada de mouse/arraste, unidade fantasma e validação visual de células. |
| `Scripts/Board/grid_cell.gd`, `cell_3d.gd`, shaders | Células, feedback visual e representação da grade. |
| `Scripts/Units/unit_stats.gd` | Esquema dos dados de unidade (`Resource`): identidade, tier, custo, atributos, características e habilidade. |
| `resources/units/*.tres` | 22 definições de unidades carregadas por `UnitSpawner`. |
| `Scripts/Systems/unit_spawner.gd` | Cache, consulta e instanciação de unidades a partir dos recursos e da cena 3D base. |
| `Scripts/Units/base_unit.gd` | Unidade em runtime: estados, navegação/alvo, ataques, dano, mana, habilidade, morte e renascimento. |
| `Scripts/Systems/shop_system.gd` | Slots, probabilidades por nível, reroll, compra e bloqueio da loja. |
| `Scripts/UI/shop_ui.gd`, `unit_card.gd` | Cartas da loja, sinais de compra/arraste e tooltip. |
| `Scripts/UI/bench_ui.gd` | Faixa visual de nove espaços do banco; mostra ícones, nomes, tiers e inicia arraste para o tabuleiro. |
| `Scripts/UI/game_ui.gd` | Tema de molduras e botões baseado nos atlases de `Assets/UI`; anima entrada/saída dos painéis e mantém o controle de visibilidade do HUD. |
| `Scripts/Systems/combat_feedback.gd` | Efeitos visuais de combate/dano. |
| `Scripts/Camera/camera.gd` | Câmera de jogo e enquadramento do tabuleiro. |
| `Scenes/`, `Assets/`, `textures/`, `Themes/` | Cenas, modelos, arte, materiais e tema de UI. Há muitos assets de cenário que parecem vir de pacotes reutilizáveis. |
| `Scripts/tools/` | Scripts auxiliares de criação de recursos de unidades; não fazem parte do fluxo normal de partida. |

Há também `Scripts/Board/board_manager.gd`, com uma classe `BoardManager` e estrutura de contêineres ainda incompleta (`_process` vazio). O jogo principal usa `Board3D` em `board.gd`; convém decidir se o manager é legado/planejado ou se deve ser integrado.

## Fluxo atual da partida

1. `Scripts/main.gd::_ready()` carrega o cache de unidades, recria a grade, prepara câmera, loja e manipulador de arraste, atualiza a UI e cria o time inimigo.
2. O jogador compra cartas, paga ouro e arrasta unidades para o tabuleiro ou para o banco visual. Unidades do tabuleiro podem ser guardadas; unidades do banco podem voltar ao tabuleiro. Também existem limite de unidades por nível, reroll e compra de XP.
3. Espaço inicia combate. Unidades buscam adversários, navegam ou se movem diretamente, atacam e podem acumular mana para habilidades.
4. Quando um time é eliminado, o jogador recebe ouro ou perde vida. Unidades do jogador são revividas, a loja é atualizada e inimigos são gerados para a próxima rodada.

Controles documentados no próprio script: Espaço para combate; R para reroll; L para travar loja; Q para comprar XP; clique/arraste para comprar e posicionar; C para limpar o tabuleiro; H para esconder UI; botão direito para inspecionar unidade.

## Conteúdo e sistemas existentes

- 22 recursos em `resources/units/`, distribuídos aproximadamente entre tiers 1–5; apenas uma definição parece usar o tier padrão 1, enquanto as demais declaram tiers 2–5. Esse recurso também omite custo e vários campos, que herdam valores padrão do script.
- Loja com cinco espaços, reroll de 2 de ouro e XP por 4 de ouro; as chances de tier estão codificadas para níveis 1–9.
- Atributos de sinergia (`origins` e `classes`) existem nos dados e aparecem nas cartas, mas não foi encontrado um sistema de cálculo/ativação de sinergias.
- O sistema de habilidades contém estrutura de atributos e feedback, mas o efeito genérico em `base_unit.gd` está incompleto: `apply_ability_effect()` só muda a cor do rótulo. Efeitos individuais exigem implementação/validação.
- `Menu.tscn` é apenas uma cena básica de `Control`/`Panel`; não há fluxo de menu para iniciar partida visível nesta cena.
- Estado de ouro, vida, nível, XP e rodada permanece em variáveis do script principal; não foi identificada persistência de partida ou opções do jogador.

## Lacunas relevantes para beta

### Bloqueios de distribuição

1. Definir a cena inicial do projeto e testar a abertura a partir de uma cópia limpa/importação nova.
2. Criar e validar presets de exportação para as plataformas-alvo, incluindo nome/versão/build e ícone final.
3. Fazer uma rodada de validação em runtime e corrigir erros e avisos de Godot, referências inválidas e caminhos de assets antes de distribuir.

### Bloqueios de experiência básica

4. Substituir o spawn e as mensagens de depuração de protótipo por uma sequência clara de início de partida. O método chamado no início (`test_spawn_units`) usa `spawn_enemy_team`, apesar do texto dizer “Boss”; o método de chefe separado não é chamado nesse fluxo.
5. Concluir menu/entrada, explicação de controles, estados de vitória/derrota e retorno/reinício sem depender do console.
6. Fechar regras de partida: venda/reembolso, limite de equipe, seleção de alvos e transições entre preparação e combate. Validar caminho de banco cheio, compra direcionada ao banco e cancelamento de arraste.
7. Especificar e implementar os efeitos reais das habilidades; decidir se sinergias fazem parte da beta. Remover/ocultar o que ainda não tem comportamento para não prometer sistemas incompletos.

### Conteúdo, qualidade e acabamento

8. Revisar os 22 dados de unidades (tiers, custos, ícones, modelos e atributos) e balancear loja e escala de inimigos. No nível 1 só há uma unidade tier 1 aparente, então a loja tende a repetir essa opção.
9. Separar estado/economia/rodadas de `Scripts/main.gd` e revisar scripts duplicados ou não usados, especialmente `BoardManager` e `navigation_baker.gd`.
10. Ajustar layout para resoluções e proporções além de 1920×1080, revisar legibilidade, feedback de interação, áudio, créditos/licenças de assets e tela de opções.
11. Definir uma lista curta de smoke tests manuais para importação, início, compra, arraste, combate, fim de rodada, game over e exportação. Não há suíte automatizada visível no estado analisado.

## Próxima sequência recomendada

1. Configurar a cena de inicialização e confirmar que o projeto inicia sem erro em importação nova.
2. Corrigir e validar o loop principal (comprar → posicionar → lutar → recompensa → próxima rodada), incluindo as condições de borda de loja, banco e derrota.
3. Delimitar escopo da beta: quais unidades, habilidades e sinergias estarão realmente disponíveis.
4. Preparar UI de início/fim, instruções mínimas e opções essenciais.
5. Rodar smoke tests, corrigir regressões e preparar um preset de exportação para a plataforma beta escolhida.

## Limites desta avaliação

É uma leitura estática dos arquivos presentes em 15/10/2026. Não confirmei comportamento em execução, compatibilidade efetiva com o binário da Godot 4.6, importação completa dos assets, desempenho, licenças de terceiros nem geração de build. A prontidão de publicação foi estimada pelo conteúdo/configuração disponível, não por uma certificação ou plano de beta fornecido pelo projeto.

## Atualização de implementação — banco

Em 15/10/2026 foi adicionada uma faixa de banco com nove espaços à interface. Cada espaço exibe ícone, nome e cor do tier; o título informa a ocupação. Compras podem ser soltas no banco, unidades do tabuleiro podem ser guardadas e unidades do banco podem ser arrastadas de volta para uma posição válida do lado do jogador. A movimentação fica bloqueada durante o combate, o cancelamento devolve a unidade à origem e o fim de combate considera apenas unidades posicionadas no tabuleiro. A análise continua estática e esta alteração não foi executada na engine.

Na mesma data, a HUD foi compactada e recebeu molduras pixel art de `Assets/UI/GUI_4x.png` e botões de `Assets/UI/buttons_4x.png`. A loja, o banco e o painel superior ocupam menos espaço; o painel duplicado de controles foi removido. A interface entra e sai com tweens; o botão `HUD` e a tecla H alternam sua visibilidade. A loja também recolhe com animação e controles menores. Essa alteração ainda não foi executada na engine.

Na mesma data, a grade foi corrigida para a dimensão solicitada de 4 fileiras por 7 colunas (duas fileiras para cada equipe). A câmera agora ajusta o enquadramento ao tamanho do campo. A inicialização deixou de apagar e recriar os filhos do tabuleiro, o que removia a luz direcional da cena. A velocidade de movimento, cujos dados estavam em centímetros por segundo, foi convertida para metros por segundo nos controladores de navegação e movimento direto. A escala original dos modelos importados é preservada e as etiquetas 3D foram reduzidas para evitar sobreposição visual. Alterações revisadas estaticamente; falta validação em execução.

Em seguida, o tabuleiro passou a ter duas metades espelhadas de 4×7 (8 fileiras × 7 colunas); todas as unidades usam agora a cápsula de placeholder. Os nomes e indicadores de vida/mana foram reunidos em uma placa pequena com moldura do atlas `Assets/UI/GUI_4x.png` e barras compactas. Os modelos 3D foram removidos dos recursos de unidade que os referenciavam. Falta validação em execução.
